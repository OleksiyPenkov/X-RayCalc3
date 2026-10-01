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

initialization
  TDUnitX.RegisterTestFixture(TTestParamMapModes);

end.
