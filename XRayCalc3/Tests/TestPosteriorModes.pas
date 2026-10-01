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

unit TestPosteriorModes;

(* The posterior on structures that are not periodic: a per-period table and
   a polynomial profile must give the curve of the same layers written out
   one by one. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

type
  [TestFixture]
  TTestPosteriorModes = class
  public
    [Test] procedure Table_CurveEqualsExplicitStacks;
    [Test] procedure Table_UnderASinglePeriodCap;
    [Test] procedure Periodic_CurveUnchangedByAnEmptyTable;
  end;

function Lay(const M: string; H, HMin, HMax, Sigma, Rho: Single; LayerID: Word): TLayerData;
function CurveOf(const S: TFitStructure): TDataArray;

implementation

uses
  System.SysUtils, System.Math, unit_Likelihood, unit_ParamMap, unit_LogPosterior,
  TestLogPosterior;

function Lay(const M: string; H, HMin, HMax, Sigma, Rho: Single; LayerID: Word): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.LayerID := LayerID;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := Sigma; Result.P[2].min := Sigma; Result.P[2].max := Sigma;
  Result.P[3].V := Rho; Result.P[3].min := Rho; Result.P[3].max := Rho;
end;

function CurveOf(const S: TFitStructure): TDataArray;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Data: TDataArray;
begin
  Data := TWB4CFixture.Angles;
  Map := TParamMap.Create(S);
  try
    Map.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Assert.IsTrue(Post.EvaluateOnce(Map.StartVector, Result).Feasible);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

{ W / B4C, three periods, W thickness 9, 10, 11 A from the surface down. }
function Tabled: TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 3;
  SetLength(Result.Stacks[0].Layers, 2);
  Result.Stacks[0].Layers[0] := Lay('W', 10, 5, 15, 2, 19.3, 0);
  Result.Stacks[0].Layers[0].PP[1] := [9, 10, 11];
  Result.Stacks[0].Layers[1] := Lay('B4C', 15, 15, 15, 2, 2.52, 1);
  Result.Subs := Lay('Si', 0, 0, 0, 3, 2.33, 0);
end;

{ The same six layers as three stacks of one period each. }
function Explicit: TFitStructure;
var
  k: Integer;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 3);
  for k := 0 to 2 do
  begin
    Result.Stacks[k].N := 1;
    SetLength(Result.Stacks[k].Layers, 2);
    Result.Stacks[k].Layers[0] := Lay('W', 9 + k, 5, 15, 2, 19.3, 0);
    Result.Stacks[k].Layers[1] := Lay('B4C', 15, 15, 15, 2, 2.52, 1);
  end;
  Result.Subs := Lay('Si', 0, 0, 0, 3, 2.33, 0);
end;

procedure AssertSameCurve(const A, B: TDataArray; const Msg: string);
var
  i: Integer;
begin
  Assert.AreEqual(Length(A), Length(B), Msg);
  for i := 0 to High(A) do
    Assert.AreEqual(Double(A[i].r), Double(B[i].r), 1E-6 * Abs(A[i].r), Format('%s, point %d', [Msg, i]));
end;

procedure TTestPosteriorModes.Table_CurveEqualsExplicitStacks;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  AssertSameCurve(CurveOf(Explicit), CurveOf(Tabled), 'a table is its layers written out');
end;

procedure TTestPosteriorModes.Table_UnderASinglePeriodCap;
var
  T, E: TFitStructure;
  Cap: TFitStack;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Cap := Default(TFitStack);
  Cap.N := 1;
  SetLength(Cap.Layers, 1);
  Cap.Layers[0] := Lay('B4C', 20, 20, 20, 2, 2.52, 0);
  { a stale table on a single-period layer is not read }
  Cap.Layers[0].PP[1] := [99];
  T := Tabled;
  Insert(Cap, T.Stacks, 0);
  E := Explicit;
  Insert(Cap, E.Stacks, 0);
  AssertSameCurve(CurveOf(E), CurveOf(T), 'the cap keeps its own value');
end;

procedure TTestPosteriorModes.Periodic_CurveUnchangedByAnEmptyTable;
var
  P, Q: TFitStructure;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := TWB4CFixture.Structure(6);
  Q := TWB4CFixture.Structure(6);
  Q.Stacks[0].Layers[2].PP[1] := [1, 2, 3];      // shorter than N = 20: ignored as a whole
  AssertSameCurve(CurveOf(P), CurveOf(Q), 'a table shorter than N is not a table');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPosteriorModes);

end.
