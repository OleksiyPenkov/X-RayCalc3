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

unit TestSampleRun;

(* TSampleRun driven directly, as the uncertainty tool drives it: no job, no
   files, no JSON. The model is TestLogPosterior's W/B4C cell; the data is its
   own curve at the true vector, as counts. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestSampleRun = class
  public
    [Test] procedure Runs_RowsStatsAndBand;
    [Test] procedure NothingRecorded_NoBand;
    [Test] procedure SameSeed_SameRows;
    [Test] procedure WithoutCounts_Runs;
    [Test] procedure Finish_ReportsRHat;
    [Test] procedure Recentre_RestartsAroundTheBestWalker;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Types, unit_Likelihood, unit_ParamMap,
  unit_LogPosterior, unit_JointPosterior, unit_SampleRun, TestLogPosterior;

const
  WALKERS = 16;
  I0 = 1E6;

type
  { Everything one run owns, freed in the reverse order of creation. }
  TRig = record
    Map: TParamMap;
    Post: TLogPosterior;
    Joint: TJointPosterior;
    Run: TSampleRun;
    Data: TDataArray;
    procedure Build(WithCounts: Boolean);
    procedure Chain(Steps, BurnIn: Integer; Seed: UInt64);
    procedure Free;
  end;

function MakeMap: TParamMap;
begin
  Result := TParamMap.Create(TWB4CFixture.Structure(6));
  Result.AddParam('s0.l2.thickness', 0, 2, 1);
  Result.SetDerived('s0.l3.thickness', 0, 3);
  Result.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
end;

procedure TRig.Build(WithCounts: Boolean);
var
  R: TDataArray;
  Counts: TArray<Double>;
  Truth: TLogPosterior;
  i: Integer;
begin
  Self := Default(TRig);
  Map := MakeMap;
  Data := TWB4CFixture.Angles;
  Truth := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
  try
    Truth.EvaluateOnce(Map.StartVector, R);
  finally
    Truth.Free;
  end;
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Counts[i] := Round(R[i].r * I0);
    Data[i].r := Max(Counts[i], 1) / I0;
  end;
  if not WithCounts then
    Counts := nil;
  Post := TLogPosterior.Create(Map, Data, Counts, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
  Joint := TJointPosterior.CreateSingle(Post, False);
  Run := TSampleRun.Create(Joint, WALKERS, 1, False, nil);
end;

procedure TRig.Chain(Steps, BurnIn: Integer; Seed: UInt64);
var
  st: Integer;
begin
  Run.Start('fit', Joint.StartVector, Seed);
  for st := 1 to Steps do
    Run.Advance(BurnIn, 1);
end;

procedure TRig.Free;
begin
  Run.Free;
  Joint.Free;
  Post.Free;
  Map.Free;
end;

procedure TTestSampleRun.Runs_RowsStatsAndBand;
var
  Rig: TRig;
  R: TSampleResult;
  k: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(True);
  try
    Rig.Chain(60, 20, 7);
    Assert.AreEqual(WALKERS * 40, Rig.Run.Rows.Count, '40 recorded steps of 16 walkers');
    R := Rig.Run.Finish([Rig.Data], 10, 7);
    Assert.AreEqual(60, R.StepsTotal);
    Assert.AreEqual(40, R.PerWalker);
    Assert.AreEqual(Length(Rig.Run.Names), Length(R.Params));
    for k := 0 to High(R.Params) do
      Assert.AreEqual(Rig.Run.Names[k], R.Params[k].Name);
    Assert.AreEqual('s0.l2.thickness', R.Params[0].Name);
    Assert.IsTrue((R.Params[0].Summary.P50 > 5.5) and (R.Params[0].Summary.P50 < 6.5),
      Format('the chain stays at the true 6 A, median %g', [R.Params[0].Summary.P50]));
    Assert.AreEqual(1, Length(R.Bands));
    Assert.IsTrue(R.Bands[0].Present);
    Assert.AreEqual(Length(Rig.Data), Length(R.Bands[0].Theta), 'one band point per measured point');
    Assert.AreEqual('CPU', R.DeviceUsed);
  finally
    Rig.Free;
  end;
end;

procedure TTestSampleRun.NothingRecorded_NoBand;
var
  Rig: TRig;
  R: TSampleResult;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(True);
  try
    Rig.Chain(5, 10, 7);            // every step is burn-in
    R := Rig.Run.Finish([Rig.Data], 10, 7);
    Assert.AreEqual(0, R.Recorded);
    Assert.IsFalse(R.Bands[0].Present, 'nothing to draw a band from');
  finally
    Rig.Free;
  end;
end;

procedure TTestSampleRun.SameSeed_SameRows;
var
  A, B: TRig;
  i, k: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  A.Build(True);
  B.Build(True);
  try
    A.Chain(20, 5, 42);
    B.Chain(20, 5, 42);
    Assert.AreEqual(A.Run.Rows.Count, B.Run.Rows.Count);
    for i := 0 to A.Run.Rows.Count - 1 do
      for k := 0 to High(A.Run.Rows[i].Values) do
        Assert.AreEqual(A.Run.Rows[i].Values[k], B.Run.Rows[i].Values[k], 0.0,
          Format('row %d value %d', [i, k]));
  finally
    B.Free;
    A.Free;
  end;
end;

procedure TTestSampleRun.WithoutCounts_Runs;
var
  Rig: TRig;
  R: TSampleResult;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(False);
  try
    Rig.Chain(30, 10, 3);
    R := Rig.Run.Finish([Rig.Data], 10, 3);
    Assert.AreEqual(WALKERS * 20, R.Recorded, 'a curve without counts is sampled with f alone');
    Assert.IsTrue(R.Bands[0].Present);
  finally
    Rig.Free;
  end;
end;

procedure TTestSampleRun.Finish_ReportsRHat;
var
  Rig: TRig;
  R: TSampleResult;
  k: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(True);
  try
    Rig.Chain(60, 20, 7);
    R := Rig.Run.Finish([Rig.Data], 10, 7);
    for k := 0 to High(R.Params) do
      Assert.IsTrue(R.Params[k].RHat > 0.9,
        Format('%s: every reported value carries an R-hat, got %g', [R.Params[k].Name, R.Params[k].RHat]));
    Assert.IsTrue(R.RHatWorst >= R.Params[0].RHat, 'the worst is the largest');
  finally
    Rig.Free;
  end;
end;

procedure TTestSampleRun.Recentre_RestartsAroundTheBestWalker;
var
  Rig: TRig;
  Centre: TArray<Double>;
  w, Best: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(True);
  try
    Rig.Chain(30, 10, 7);
    Assert.IsTrue(Rig.Run.Rows.Count > 0);
    Best := 0;
    for w := 1 to WALKERS - 1 do
      if Rig.Run.Sampler.LnP[w] > Rig.Run.Sampler.LnP[Best] then
        Best := w;
    Centre := Copy(Rig.Run.Sampler.X[Best]);
    Rig.Run.Recentre(99);
    Assert.AreEqual(0, Rig.Run.Rows.Count, 'what was recorded before belongs to the old chain');
    Assert.AreEqual(0, Rig.Run.Sampler.Step, 'the chain starts again');
    for w := 0 to WALKERS - 1 do
      { slot 0 is the thickness, range 3 .. 9: the 'fit' ball is 1e-3 of the range wide }
      Assert.IsTrue(Abs(Rig.Run.Sampler.X[w][0] - Centre[0]) < 0.05,
        Format('walker %d at %g, the best was at %g', [w, Rig.Run.Sampler.X[w][0], Centre[0]]));
  finally
    Rig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSampleRun);

end.
