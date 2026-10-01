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

unit TestLogPosterior;

(* TLogPosterior on a synthetic W/B4C multilayer: data made by the posterior's
   own curve at the true vector, counts = R * 1e6 rounded. At the true vector
   every residual is zero; anywhere else the cost is higher. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

type
  [TestFixture]
  TTestLogPosterior = class
  public
    [Test] procedure TrueVector_ZeroResidual_CostAtFloor;
    [Test] procedure OtherVector_CostsMore;
    [Test] procedure InfeasibleVector_NotEvaluated;
    [Test] procedure Range_ExcludesConvolutionEdges;
    [Test] procedure Create_ModeNotTheta_Raises;
  end;

  /// Shared with TestLFPSOPosterior: the W/B4C cell, its map and synthetic data.
  TWB4CFixture = record
    class function TablesPresent: Boolean; static;
    class function Structure(H2: Single): unit_Types.TFitStructure; static;
    class function CalcParams(const Data: unit_Types.TDataArray; Resolution: Single): unit_Types.TCalcThreadParams; static;
    class function Angles: unit_Types.TDataArray; static;
  end;

implementation

uses
  System.SysUtils, System.Math, System.IOUtils, unit_Config,
  unit_calc, unit_materials, unit_Likelihood, unit_ParamMap, unit_LogPosterior;

const
  LAMBDA = 1.5406;
  I0 = 1E6;

class function TWB4CFixture.TablesPresent: Boolean;
const
  Needed: array [0 .. 2] of string = ('W', 'B4C', 'Si');
var
  i: Integer;
begin
  for i := Low(Needed) to High(Needed) do
    if not TFile.Exists(IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]) +
      Needed[i] + '.bin') then
      Exit(False);
  Result := True;
end;

function L(const M: string; H, HMin, HMax, Sigma, Rho: Single): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := Sigma; Result.P[2].min := Sigma; Result.P[2].max := Sigma;
  Result.P[3].V := Rho; Result.P[3].min := Rho; Result.P[3].max := Rho;
end;

{ Surface-first cell of 20 periods (34 A): B4C-on-W interlayer 3 A, W 10 A,
  W-on-B4C interlayer H2 (6 A true, free in [3, 9]), B4C 15 A (derived,
  [10, 20]). Interlayers are W at reduced density. }
class function TWB4CFixture.Structure(H2: Single): TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 20;
  SetLength(Result.Stacks[0].Layers, 4);
  Result.Stacks[0].Layers[0] := L('W', 3, 3, 3, 2, 11);
  Result.Stacks[0].Layers[1] := L('W', 10, 10, 10, 2, 19.3);
  Result.Stacks[0].Layers[2] := L('W', H2, 3, 9, 2, 11);
  Result.Stacks[0].Layers[3] := L('B4C', 34 - 13 - H2, 10, 20, 2, 2.52);
  Result.Stacks[0].D := 34;
  Result.Subs := L('Si', 0, 0, 0, 3, 2.33);
end;

class function TWB4CFixture.Angles: TDataArray;
var
  i: Integer;
begin
  SetLength(Result, 200);
  for i := 0 to High(Result) do
  begin
    Result[i].t := 0.3 + i * (3.0 - 0.3) / 199;
    Result[i].r := 1;
  end;
end;

class function TWB4CFixture.CalcParams(const Data: TDataArray; Resolution: Single): TCalcThreadParams;
begin
  Result := Default(TCalcThreadParams);
  Result.Mode := cmTheta;
  Result.Lambda := LAMBDA;
  Result.StartT := Data[0].t;
  Result.EndT := Data[High(Data)].t;
  Result.DT := Resolution;
  Result.N := Length(Data);
  Result.K := 1;
  Result.P := cmSP;
  Result.RF := rfError;
  Result.MVAWindow := 5;
end;

function MakeMap(const S: TFitStructure): TParamMap;
begin
  Result := TParamMap.Create(S);
  Result.AddParam('s0.l2.thickness', 0, 2, 1);   // layer 2 = the W-on-B4C interlayer
  Result.SetDerived('s0.l3.thickness', 0, 3);    // layer 3 = B4C
  Result.AddNuisance(System.Math.Log10(1.2), 0, 1E-7, 0.001, 1);
end;

{ The data: the posterior's own curve at the true vector, as counts. }
procedure MakeData(out Data: TDataArray; out Counts: TArray<Double>);
var
  Map: TParamMap;
  Post: TLogPosterior;
  R: TDataArray;
  i: Integer;
begin
  Map := MakeMap(TWB4CFixture.Structure(6));
  try
    Data := TWB4CFixture.Angles;
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Post.EvaluateOnce(Map.StartVector, R);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Counts[i] := Round(R[i].r * I0);
    Data[i].r := Counts[i] / I0;
    if Counts[i] = 0 then
      Data[i].r := 1 / I0;          // a positive stand-in; excluded by n_min anyway
  end;
end;

procedure TTestLogPosterior.TrueVector_ZeroResidual_CostAtFloor;
var
  Data, R: TDataArray;
  Counts: TArray<Double>;
  Map: TParamMap;
  Post: TLogPosterior;
  T: TPosteriorTerms;
  Theta: TArray<Double>;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  MakeData(Data, Counts);
  Map := MakeMap(TWB4CFixture.Structure(6));
  try
    Post := TLogPosterior.Create(Map, Data, Counts, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Theta := Map.StartVector;
      Theta[Map.IndexOf('c0.ln_f')] := Ln(0.001);
      T := Post.EvaluateOnce(Theta, R);
      Assert.IsTrue(T.Feasible);
      Assert.IsTrue(T.Likelihood.Chi2Data < 1E-3 * T.Likelihood.PointsUsed,
        Format('residuals are only the rounding of the counts: chi2 %g on %d points',
          [T.Likelihood.Chi2Data, T.Likelihood.PointsUsed]));
      Assert.AreEqual(0.0, T.PriorTerm, 0.0);
      Assert.AreEqual(T.Likelihood.Cost, T.Cost, 1E-12);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

procedure TTestLogPosterior.OtherVector_CostsMore;
var
  Data, R: TDataArray;
  Counts: TArray<Double>;
  Map: TParamMap;
  Post: TLogPosterior;
  AtTrue, Off: TPosteriorTerms;
  Theta: TArray<Double>;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  MakeData(Data, Counts);
  Map := MakeMap(TWB4CFixture.Structure(6));
  try
    Post := TLogPosterior.Create(Map, Data, Counts, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Theta := Map.StartVector;
      AtTrue := Post.EvaluateOnce(Theta, R);
      Theta[Map.IndexOf('s0.l2.thickness')] := 7;
      Off := Post.EvaluateOnce(Theta, R);
      Assert.IsTrue(Off.Feasible);
      Assert.IsTrue(Off.Cost > AtTrue.Cost + 10,
        Format('7 A must cost more than 6 A: %g vs %g', [Off.Cost, AtTrue.Cost]));
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

procedure TTestLogPosterior.InfeasibleVector_NotEvaluated;
var
  Data, R: TDataArray;
  Map: TParamMap;
  Post: TLogPosterior;
  T: TPosteriorTerms;
  Theta: TArray<Double>;
begin
  Data := TWB4CFixture.Angles;
  Map := MakeMap(TWB4CFixture.Structure(6));
  try
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Theta := Map.StartVector;
      Theta[Map.IndexOf('s0.l2.thickness')] := 9.5;     // above 9
      T := Post.EvaluateOnce(Theta, R);
      Assert.IsFalse(T.Feasible);
      Assert.AreEqual(Double(INFEASIBLE_COST), T.Cost, 0.0);
      Assert.AreEqual(0, Length(R), 'no curve for an infeasible vector');
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

procedure TTestLogPosterior.Range_ExcludesConvolutionEdges;
var
  Data: TDataArray;
  Map: TParamMap;
  Post: TLogPosterior;
  N: Integer;
begin
  Data := TWB4CFixture.Angles;
  ConvolutionWeights(Data[0].t, Data[High(Data)].t, Length(Data), 0.015, N);
  Map := MakeMap(TWB4CFixture.Structure(6));
  try
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0.015), 1E-9, 10);
    try
      Assert.IsTrue(N > 0, 'the fixture must convolve');
      Assert.AreEqual(N, Post.First);
      Assert.AreEqual(High(Data) - N, Post.Last);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

procedure TTestLogPosterior.Create_ModeNotTheta_Raises;
var
  Data: TDataArray;
  Map: TParamMap;
  Params: TCalcThreadParams;
begin
  Data := TWB4CFixture.Angles;
  Map := MakeMap(TWB4CFixture.Structure(6));
  try
    Params := TWB4CFixture.CalcParams(Data, 0);
    Params.Mode := cmLambda;
    Assert.WillRaise(
      procedure
      var
        Post: TLogPosterior;
      begin
        Post := TLogPosterior.Create(Map, Data, nil, Params, 1E-9, 10);
        Post.Free;
      end, Exception, 'cmLambda convolves with DW, which TLogPosterior does not compute');
  finally
    Map.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLogPosterior);

end.
