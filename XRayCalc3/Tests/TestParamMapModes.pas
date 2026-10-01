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

unit TestParamMapModes;

(* TParamMap beyond the periodic cell: table slots, profile slots and the
   per-stack summary numbers. No Henke tables needed: nothing is calculated. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

type
  [TestFixture]
  TTestParamMapModes = class
  public
    [Test] procedure AddTable_OneSlotPerPeriod;
    [Test] procedure AddTable_ShortTable_StartsFromTheValue;
    [Test] procedure AddTable_StartClampedIntoLimits;
    [Test] procedure Apply_TableSlots_WriteTheirPeriod;
    [Test] procedure Apply_TableOutsideLimits_Infeasible;
    [Test] procedure Apply_TableNaN_Infeasible;
    [Test] procedure AddTable_PairedOrSinglePeriod_Raises;
    [Test] procedure AddProfile_SlotsAndBounds;
    [Test] procedure Apply_Profile_FillsEveryPeriod;
    [Test] procedure Apply_ProfileLeavesLimits_Infeasible;
    [Test] procedure Apply_ProfileStartOutsideLimits_Infeasible;
    [Test] procedure Apply_ProfileNaN_Infeasible;
    [Test] procedure AddProfile_BadInput_Raises;
    [Test] procedure Reported_ProfilePeriods;
    [Test] procedure SetDerived_AfterAProfile_KeepsItsSlots;
    [Test] procedure Summary_PeriodicCell;
    [Test] procedure Summary_FollowsATable;
    [Test] procedure Summary_Prior_AddsToThePriorTerm;
    [Test] procedure Summary_SinglePeriodStack_Raises;
  end;

function Cell5: TFitStructure;

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

{ Two layers, five periods: layer 0 is 10 A [8, 12], layer 1 is 20 A, held. }
function Cell5: TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 5;
  Result.Stacks[0].D := 30;
  SetLength(Result.Stacks[0].Layers, 2);
  Result.Stacks[0].Layers[0] := Layer('W', 10, 8, 12);
  Result.Stacks[0].Layers[1] := Layer('B4C', 20, 20, 20);
  Result.Subs := Layer('Si', 0, 0, 0);
end;

procedure TTestParamMapModes.AddTable_OneSlotPerPeriod;
var
  S: TFitStructure;
  M: TParamMap;
  k: Integer;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].PP[1] := [9, 9.5, 10, 10.5, 11];
  M := TParamMap.Create(S);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    Assert.AreEqual(5, M.Count);
    for k := 1 to 5 do
    begin
      Assert.AreEqual(Format('s0.l0.thickness[%d]', [k]), M.Slots[k - 1].Name);
      Assert.AreEqual(8.5 + 0.5 * k, M.Slots[k - 1].Start, 1E-6);
      Assert.AreEqual(8.0, M.Slots[k - 1].Lower, 1E-6);
      Assert.AreEqual(12.0, M.Slots[k - 1].Upper, 1E-6);
    end;
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddTable_ShortTable_StartsFromTheValue;
var
  S: TFitStructure;
  M: TParamMap;
  k: Integer;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].PP[1] := [9, 9.5];        // left over from N = 2
  M := TParamMap.Create(S);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    for k := 0 to 4 do
      Assert.AreEqual(10.0, M.Slots[k].Start, 1E-6, 'a table shorter than N is ignored as a whole');
    Assert.AreEqual(5, Length(M.Template.Stacks[0].Layers[0].PP[1]), 'the template carries a full table');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddTable_StartClampedIntoLimits;
var
  S: TFitStructure;
  M: TParamMap;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].PP[1] := [7, 10, 10, 10, 13];
  M := TParamMap.Create(S);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    Assert.AreEqual(8.0, M.Slots[0].Start, 1E-6);
    Assert.AreEqual(12.0, M.Slots[4].Start, 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_TableSlots_WriteTheirPeriod;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
  k: Integer;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([8.5, 9, 10, 11, 11.5], S, N));
    for k := 1 to 5 do
      Assert.AreEqual(Double(S.Stacks[0].Layers[0].PP[1][k - 1]),
        Double(S.Stacks[0].Layers[0].PeriodValue(1, k, 5, True)), 0.0);
    Assert.AreEqual(8.5, Double(S.Stacks[0].Layers[0].PP[1][0]), 1E-6);
    Assert.AreEqual(11.5, Double(S.Stacks[0].Layers[0].PP[1][4]), 1E-6);
    Assert.AreEqual(10.0, Double(M.Template.Stacks[0].Layers[0].PP[1][0]), 1E-6,
      'Apply writes the copy, never the template');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_TableOutsideLimits_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([10, 10, 12.5, 10, 10], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_TableNaN_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([10, NaN, 10, 10, 10], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddTable_PairedOrSinglePeriod_Raises;
var
  S: TFitStructure;
  M: TParamMap;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].P[1].Paired := True;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddTable('s0.l0.thickness', 0, 0, 1); end, EParamMap,
      'a paired parameter has one value');
  finally
    M.Free;
  end;
  S := Cell5;
  S.Stacks[0].N := 1;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddTable('s0.l0.thickness', 0, 0, 1); end, EParamMap,
      'a single period has no table');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddProfile_SlotsAndBounds;
var
  M: TParamMap;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    Assert.AreEqual(2, M.Count);
    Assert.AreEqual('s0.l0.thickness.c0', M.Slots[0].Name);
    Assert.AreEqual('s0.l0.thickness.c1', M.Slots[1].Name);
    Assert.AreEqual(8.0, M.Slots[0].Lower, 1E-6);
    Assert.AreEqual(12.0, M.Slots[0].Upper, 1E-6);
    Assert.AreEqual(10.0, M.Slots[0].Start, 1E-6);
    Assert.AreEqual(0.25, M.Slots[1].Start, 1E-6);
    { the gradient may take the whole range across the N - 1 = 4 steps, twice over }
    Assert.AreEqual(-2.0, M.Slots[1].Lower, 1E-6);
    Assert.AreEqual(2.0, M.Slots[1].Upper, 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_Profile_FillsEveryPeriod;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
  k: Integer;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([9, 0.5], S, N));
    for k := 1 to 5 do
      Assert.AreEqual(9 + 0.5 * (k - 1), Double(S.Stacks[0].Layers[0].PeriodValue(1, k, 5, True)), 1E-5);
    Assert.AreEqual(9.0, Double(S.Stacks[0].Layers[0].P[1].V), 1E-6, 'the layer''s own value is c0');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_ProfileLeavesLimits_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([11, 0.5], S, N), 'period 5 would be 13 A, above 12');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_ProfileStartOutsideLimits_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [11, 0.5]);    // a fit that ended outside
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply(M.StartVector, S, N), 'not clamped: the caller must hear of it');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_ProfileNaN_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([10, NaN], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddProfile_BadInput_Raises;
var
  S: TFitStructure;
  M: TParamMap;
begin
  M := TParamMap.Create(Cell5);
  try
    Assert.WillRaise(procedure begin M.AddProfile('s0.l0.thickness', 0, 0, 1, [10]); end,
      EParamMap, 'a profile needs a gradient');
    Assert.WillRaise(procedure begin M.AddProfile('s0.l1.thickness', 0, 1, 1, [20, 0]); end,
      EParamMap, 'a held value is not sampled');
  finally
    M.Free;
  end;
  S := Cell5;
  S.Stacks[0].Layers[0].P[1].Paired := True;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0]); end,
      EParamMap, 'a paired parameter has one value');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Reported_ProfilePeriods;
var
  M: TParamMap;
  Names: TArray<string>;
  Values: TArray<Double>;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    Names := M.ReportedNames;
    Assert.AreEqual(7, Length(Names), 'two coefficients and five periods');
    Assert.AreEqual('s0.l0.thickness[1]', Names[2]);
    Assert.AreEqual('s0.l0.thickness[5]', Names[6]);
    Assert.IsTrue(M.ReportedValues([9, 0.5], Values));
    Assert.AreEqual(9.0, Values[2], 1E-5);
    Assert.AreEqual(11.0, Values[6], 1E-5);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.SetDerived_AfterAProfile_KeepsItsSlots;
var
  S, A: TFitStructure;
  M: TParamMap;
  N: TNuisance;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].P[2].min := 1;                         // Cell5 holds sigma; a profile needs a range
  S.Stacks[0].Layers[0].P[2].max := 5;
  S.Stacks[0].Layers[1].P[1].min := 15;
  S.Stacks[0].Layers[1].P[1].max := 25;
  M := TParamMap.Create(S);
  try
    M.AddParam('s0.l1.thickness', 0, 1, 1);                    // slot 0, removed below
    M.AddProfile('s0.l0.sigma', 0, 0, 2, [3, 0]);              // slots 1, 2 -> 0, 1
    M.SetDerived('s0.l1.thickness', 0, 1);
    Assert.AreEqual(2, M.Count);
    M.Template.CopyContent(A);
    Assert.IsTrue(M.Apply(M.StartVector, A, N), 'the profile still reads its own two slots');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_PeriodicCell;
var
  M: TParamMap;
  Names: TArray<string>;
  Values: TArray<Double>;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddParam('s0.l0.thickness', 0, 0, 1);
    M.AddSummary('s0', 0);
    Names := M.ReportedNames;
    Assert.AreEqual(4, Length(Names));
    Assert.AreEqual('s0.period_mean', Names[1]);
    Assert.AreEqual('s0.total', Names[2]);
    Assert.AreEqual('s0.drift', Names[3]);
    Assert.IsTrue(M.ReportedValues([11], Values));
    Assert.AreEqual(31.0, Values[1], 1E-5);
    Assert.AreEqual(155.0, Values[2], 1E-4);
    Assert.AreEqual(0.0, Values[3], 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_FollowsATable;
var
  M: TParamMap;
  Values: TArray<Double>;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.AddSummary('s0', 0);
    Assert.IsTrue(M.ReportedValues([9, 9.5, 10, 10.5, 11], Values));
    Assert.AreEqual(30.0, Values[5], 1E-5, 'mean period');
    Assert.AreEqual(150.0, Values[6], 1E-4, 'total');
    Assert.AreEqual(2.0, Values[7], 1E-5, 'last period minus the first');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_Prior_AddsToThePriorTerm;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.AddSummary('s0', 0);
    M.SetPrior('s0.total', 152, 2);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([9, 9.5, 10, 10.5, 11], S, N));
    Assert.AreEqual(1.0, M.PriorTerm([9, 9.5, 10, 10.5, 11], S), 1E-6, '((150 - 152) / 2)^2');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_SinglePeriodStack_Raises;
var
  S: TFitStructure;
  M: TParamMap;
begin
  S := Cell5;
  S.Stacks[0].N := 1;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddSummary('s0', 0); end, EParamMap);
  finally
    M.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestParamMapModes);

end.
