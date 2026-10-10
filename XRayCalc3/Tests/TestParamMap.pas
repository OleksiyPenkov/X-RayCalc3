(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit TestParamMap;

(* TParamMap on a hand-built four-layer periodic cell:
     layer 0: 10 A [8, 12]   layer 1: 6 A [3, 9]
     layer 2: 12 A [10, 14]  layer 3: 4 A [2, 6]      period 32 A, N = 20
   Layer 2 is the derived layer: its thickness is D minus the others. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

type
  [TestFixture]
  TTestParamMap = class
  private
    function Cell: TFitStructure;
    function StandardMap: TObject;   // TParamMap; typed as TObject to keep the interface uses short
  public
    [Test] procedure Start_IsFeasible_AndKeepsTemplate;
    [Test] procedure Apply_SetsSlots_AndDerivesThickness;
    [Test] procedure Apply_PeriodSlot_UsesSampledPeriod;
    [Test] procedure Apply_SlotOutsideBounds_Infeasible;
    [Test] procedure Apply_NaNComponent_Infeasible;
    [Test] procedure Apply_DerivedOutsideItsBounds_Infeasible;
    [Test] procedure SetDerived_RemovesItsThicknessSlot;
    [Test] procedure Nuisance_LnFAndLog10Scale;
    [Test] procedure PriorTerm_CoversSlotsAndDerivedLayer;
    [Test] procedure SetPrior_UnknownName_Raises;
    [Test] procedure SetPrior_NonPositiveSD_Raises;
    [Test] procedure AddNuisance_BadRanges_Raise;
    [Test] procedure ReportedNamesAndValues;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Likelihood, unit_ParamMap;

function Layer(const M: string; H, HMin, HMax: Single): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := 3; Result.P[2].min := 3; Result.P[2].max := 3;
  Result.P[3].V := 5; Result.P[3].min := 5; Result.P[3].max := 5;
end;

function TTestParamMap.Cell: TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 20;
  Result.Stacks[0].D := 32;
  SetLength(Result.Stacks[0].Layers, 4);
  Result.Stacks[0].Layers[0] := Layer('W', 10, 8, 12);
  Result.Stacks[0].Layers[1] := Layer('W', 6, 3, 9);
  Result.Stacks[0].Layers[2] := Layer('B4C', 12, 10, 14);
  Result.Stacks[0].Layers[3] := Layer('W', 4, 2, 6);
  Result.Subs := Layer('Si', 0, 0, 0);
end;

{ Slots: l0.H, l1.H, l3.H, then the three nuisance slots; layer 2 derived. }
function TTestParamMap.StandardMap: TObject;
var
  M: TParamMap;
begin
  M := TParamMap.Create(Cell);
  M.AddParam('s0.l0.thickness', 0, 0, 1);
  M.AddParam('s0.l1.thickness', 0, 1, 1);
  M.AddParam('s0.l2.thickness', 0, 2, 1);
  M.AddParam('s0.l3.thickness', 0, 3, 1);
  M.SetDerived('s0.l2.thickness', 0, 2);
  M.AddNuisance(Log10(1.2), 0, 1E-6, 0.001, 1);
  Result := M;
end;

procedure TTestParamMap.Start_IsFeasible_AndKeepsTemplate;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
  Start: TArray<Double>;
begin
  M := TParamMap(StandardMap);
  try
    Assert.AreEqual(6, M.Count, 'three thicknesses and three nuisance slots');
    Start := M.StartVector;
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply(Start, S, N), 'the start is feasible');
    Assert.AreEqual(12.0, Double(S.Stacks[0].Layers[2].P[1].V), 1E-5, 'derived keeps its start');
    Assert.AreEqual(0.0, N.LogScale, 1E-12);
    Assert.AreEqual(0.0, N.Background, 1E-12);
    Assert.AreEqual(0.05, N.F, 1E-9, 'f starts at 0.05 when the range allows it');
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.Apply_SetsSlots_AndDerivesThickness;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap(StandardMap);
  try
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([11, 5, 3.5, 0, 0, Ln(0.1)], S, N));
    Assert.AreEqual(11.0, Double(S.Stacks[0].Layers[0].P[1].V), 1E-5);
    Assert.AreEqual(5.0, Double(S.Stacks[0].Layers[1].P[1].V), 1E-5);
    Assert.AreEqual(3.5, Double(S.Stacks[0].Layers[3].P[1].V), 1E-5);
    Assert.AreEqual(32 - 19.5, Double(S.Stacks[0].Layers[2].P[1].V), 1E-5, 'D minus the others');
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.Apply_PeriodSlot_UsesSampledPeriod;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell);
  try
    M.AddParam('s0.l0.thickness', 0, 0, 1);
    M.AddParam('s0.l1.thickness', 0, 1, 1);
    M.AddParam('s0.l3.thickness', 0, 3, 1);
    M.AddPeriod('s0.period', 0, 30, 34);
    M.SetDerived('s0.l2.thickness', 0, 2);
    M.AddNuisance(Log10(1.2), 0, 1E-6, 0.001, 1);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([11, 5, 3.5, 33, 0, 0, Ln(0.1)], S, N));
    Assert.AreEqual(33 - 19.5, Double(S.Stacks[0].Layers[2].P[1].V), 1E-5);
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.Apply_SlotOutsideBounds_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap(StandardMap);
  try
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([12.5, 5, 3.5, 0, 0, Ln(0.1)], S, N), 'l0 above 12');
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.Apply_DerivedOutsideItsBounds_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap(StandardMap);
  try
    M.Template.CopyContent(S);
    // 32 - (12 + 9 + 6) = 5 < 10
    Assert.IsFalse(M.Apply([12, 9, 6, 0, 0, Ln(0.1)], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.Apply_NaNComponent_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap(StandardMap);
  try
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([NaN, 5, 3.5, 0, 0, Ln(0.1)], S, N),
      'a NaN component must be infeasible, not fall through as inside range');
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.SetDerived_RemovesItsThicknessSlot;
var
  M: TParamMap;
begin
  M := TParamMap(StandardMap);
  try
    Assert.AreEqual(-1, M.IndexOf('s0.l2.thickness'), 'a derived thickness is no slot');
    Assert.AreEqual(1, Length(M.Derived));
    Assert.AreEqual('s0.l2.thickness', M.Derived[0].Name);
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.Nuisance_LnFAndLog10Scale;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap(StandardMap);
  try
    Assert.AreEqual('c0.log10_scale', M.Slots[3].Name);
    Assert.AreEqual('c0.background', M.Slots[4].Name);
    Assert.AreEqual('c0.ln_f', M.Slots[5].Name);
    Assert.AreEqual(-Log10(1.2), M.Slots[3].Lower, 1E-12);
    Assert.AreEqual(Ln(0.001), M.Slots[5].Lower, 1E-12);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([10, 6, 4, 0.05, 5E-7, Ln(0.2)], S, N));
    Assert.AreEqual(0.05, N.LogScale, 1E-12);
    Assert.AreEqual(5E-7, N.Background, 1E-18);
    Assert.AreEqual(0.2, N.F, 1E-12);
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.PriorTerm_CoversSlotsAndDerivedLayer;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
  Theta: TArray<Double>;
begin
  M := TParamMap(StandardMap);
  try
    M.SetPrior('s0.l0.thickness', 10, 0.5);
    M.SetPrior('s0.l2.thickness', 12, 0.25);    // the derived layer
    Theta := [11, 5, 3.5, 0, 0, Ln(0.1)];       // derived = 12.5
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply(Theta, S, N));
    Assert.AreEqual(4 + 4, M.PriorTerm(Theta, S), 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.SetPrior_UnknownName_Raises;
var
  M: TParamMap;
begin
  M := TParamMap(StandardMap);
  try
    Assert.WillRaise(procedure begin M.SetPrior('s0.l9.thickness', 1, 1) end, EParamMap);
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.SetPrior_NonPositiveSD_Raises;
var
  M: TParamMap;
begin
  M := TParamMap(StandardMap);
  try
    Assert.WillRaise(procedure begin M.SetPrior('s0.l0.thickness', 10, 0) end, EParamMap);
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.AddNuisance_BadRanges_Raise;
var
  M: TParamMap;
begin
  M := TParamMap.Create(Cell);
  try
    Assert.WillRaise(procedure begin M.AddNuisance(0.1, -1, 1, 0.001, 1) end, EParamMap, 'background below 0');
    Assert.WillRaise(procedure begin M.AddNuisance(0.1, 0, 1, 0, 1) end, EParamMap, 'f min 0');
    Assert.WillRaise(procedure begin M.AddNuisance(0.1, 0, 1, 0.5, 0.1) end, EParamMap, 'f min > f max');
  finally
    M.Free;
  end;
end;

procedure TTestParamMap.ReportedNamesAndValues;
var
  M: TParamMap;
  Names: TArray<string>;
  V: TArray<Double>;
begin
  M := TParamMap(StandardMap);
  try
    Names := M.ReportedNames;
    Assert.AreEqual('s0.l0.thickness,s0.l1.thickness,s0.l3.thickness,c0.log10_scale,' +
      'c0.background,c0.ln_f,c0.scale,c0.f,s0.l2.thickness', string.Join(',', Names));
    { log10 scale must stay inside the window [-log10(1.2), log10(1.2)] }
    Assert.IsTrue(M.ReportedValues([11, 5, 3.5, System.Math.Log10(1.1), 0, Ln(0.1)], V));
    Assert.AreEqual(1.1, V[6], 1E-12, 'c0.scale');
    Assert.AreEqual(0.1, V[7], 1E-12, 'c0.f');
    Assert.AreEqual(12.5, V[8], 1E-5, 'the derived thickness');
    Assert.IsFalse(M.ReportedValues([12.5, 5, 3.5, 0, 0, Ln(0.1)], V), 'infeasible');
  finally
    M.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestParamMap);

end.
