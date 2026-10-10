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

unit TestTruthGate;

(* The truth gate of the uncertainty core (plan A, task 7). Classic fit, then
   the sampler, on calculated curves with known truth and counting noise, for
   a periodic structure, a profile and a table. Opt-in: set XRC_TRUTH_GATE=1.
   Every run appends its numbers to TruthGate.txt next to the test runner. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

const
  FREE_L = 2;                 // the W-on-B4C interlayer of TWB4CFixture's cell

type
  TMode = (gmPeriodic, gmProfile, gmTable);

  [TestFixture]
  TTestTruthGate = class
  public
    [Test] procedure Periodic_TruthInsideRange;
    [Test] procedure Profile_TruthInsideRange;
    [Test] procedure Table_TruthInsideRange;
    [Test] procedure LargeTable_Report;
    [Test] procedure LongRun_Report;
  end;

{ Shared with TestUncertEndToEnd: the same truths, noise and classic fits. }

/// TWB4CFixture's cell with N periods; every value paired and held, except the
/// interlayer thickness, free in [3, 9].
function Cell(N: Integer; H2: Single): TFitStructure;
/// The truth's interlayer thickness in period k (from 1, at the surface).
function TruthH(Mode: TMode; k: Integer): Double;
function TruthStructure(Mode: TMode; N: Integer): TFitStructure;
/// Counting noise at I0 = 1E7 on the clean curve R.
procedure Noisy(const R: TDataArray; Seed: UInt64; out Data: TDataArray; out Counts: TArray<Double>);
/// The classic fit from the design (interlayer 4.5 A everywhere).
procedure ClassicFit(Mode: TMode; N: Integer; const Data: TDataArray;
  const CP: TCalcThreadParams; Seed: Integer; out Fitted: TFitStructure; out C: TArray<Double>);

implementation

uses
  System.SysUtils, System.Math, System.IOUtils, System.Diagnostics,
  unit_Xoshiro, unit_Likelihood, unit_ParamMap, unit_LogPosterior,
  unit_JointPosterior, unit_SampleRun, unit_LFPSO_Base, unit_LFPSO_Periodic,
  unit_LFPSO_Poly, unit_LFPSO_Irregular, TestLogPosterior, TestPosteriorModes;

const
  I0     = 1E7;
  SEEDS  = 6;
  SETTLE = 1000;              // steps before the chain is restarted around its best walker
  STEPS  = 3000;
  BURN   = 1000;
  THIN   = 10;

type
  TTally = record
    Trials, In68, In95: Integer;
    WorstRHat: Double;
    procedure Add(Run: TSampleRun; const R: TSampleResult; const Name: string; Truth: Double;
      var Log: string);
    function F68: Double;
    function F95: Double;
  end;

function Enabled: Boolean;
begin
  Result := GetEnvironmentVariable('XRC_TRUTH_GATE') = '1';
end;

procedure Report(const Line: string);
begin
  TFile.AppendAllText(TPath.Combine(ExtractFilePath(ParamStr(0)), 'TruthGate.txt'),
    Line + sLineBreak);
end;

procedure TTally.Add(Run: TSampleRun; const R: TSampleResult; const Name: string; Truth: Double;
  var Log: string);
var
  k: Integer;
  RH: Double;
begin
  for k := 0 to High(R.Params) do
    if SameText(R.Params[k].Name, Name) then
    begin
      RH := R.Params[k].RHat;
      if not (RH <= WorstRHat) then      // NaN counts as the worst
        WorstRHat := RH;
      Log := Log + Format('  R-hat %.3f', [RH]);
      Inc(Trials);
      if (Truth >= R.Params[k].Summary.P16) and (Truth <= R.Params[k].Summary.P84) then
        Inc(In68);
      if (Truth >= R.Params[k].Summary.P2_5) and (Truth <= R.Params[k].Summary.P97_5) then
        Inc(In95);
      Log := Log + Format('  %s truth %.5g  p16 %.5g  p50 %.5g  p84 %.5g' + sLineBreak,
        [Name, Truth, R.Params[k].Summary.P16, R.Params[k].Summary.P50, R.Params[k].Summary.P84]);
      Exit;
    end;
  Assert.Fail('no reported value named ' + Name);
end;

function TTally.F68: Double;
begin
  Result := In68 / Max(1, Trials);
end;

function TTally.F95: Double;
begin
  Result := In95 / Max(1, Trials);
end;

{ TWB4CFixture's cell with N periods; every value paired (one value for the
  whole stack) and held, except the interlayer thickness, free in [3, 9]. }
function Cell(N: Integer; H2: Single): TFitStructure;
var
  j, p: Integer;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := N;
  SetLength(Result.Stacks[0].Layers, 4);
  Result.Stacks[0].Layers[0] := Lay('W', 3, 3, 3, 2, 11, 0);
  Result.Stacks[0].Layers[1] := Lay('W', 10, 10, 10, 2, 19.3, 1);
  Result.Stacks[0].Layers[2] := Lay('W', H2, 3, 9, 2, 11, 2);
  Result.Stacks[0].Layers[3] := Lay('B4C', 15, 15, 15, 2, 2.52, 3);
  for j := 0 to 3 do
    for p := 1 to 3 do
      Result.Stacks[0].Layers[j].P[p].Paired := not ((j = FREE_L) and (p = 1));
  Result.Subs := Lay('Si', 0, 0, 0, 3, 2.33, 0);
end;

{ The truth's interlayer thickness in period k (from 1, at the surface). }
function TruthH(Mode: TMode; k: Integer): Double;
begin
  case Mode of
    gmProfile: Result := 5.5 + 0.05 * (k - 1);
    gmTable:   Result := 6 + 0.4 * Sin(1.3 * k);
  else
    Result := 6;
  end;
end;

function TruthStructure(Mode: TMode; N: Integer): TFitStructure;
var
  k: Integer;
begin
  Result := Cell(N, 6);
  if Mode = gmPeriodic then
    Exit;
  SetLength(Result.Stacks[0].Layers[FREE_L].PP[1], N);
  for k := 1 to N do
    Result.Stacks[0].Layers[FREE_L].PP[1][k - 1] := TruthH(Mode, k);
end;

procedure Noisy(const R: TDataArray; Seed: UInt64; out Data: TDataArray; out Counts: TArray<Double>);
var
  Rng: TXoshiro256;
  i: Integer;
  Lam: Double;
begin
  Rng.Seed(Seed);
  Data := Copy(R);
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Lam := I0 * R[i].r;
    Counts[i] := Max(0, Round(Lam + Sqrt(Lam) * Rng.NextGaussian));
    Data[i].r := Max(Counts[i], 1) / I0;
  end;
end;

function ClassicParams(Order: Integer): TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax       := 300;
  Result.Pop        := 60;
  Result.Tolerance  := 0;
  Result.Vmax       := 0.3;
  Result.JammingMax := 100;
  Result.ReInitMax  := 3;
  Result.KChiSqr    := 1.5;
  Result.KVmax      := 1.2;
  Result.w1         := 0.4;
  Result.w2         := 0.5;
  Result.Ksxr       := 0.1;
  Result.MaxPOrder  := Order;
  Result.PolyFactor := 10;
end;

{ The classic fit from the design (interlayer 4.5 A everywhere), and the
  structure and profile coefficients the map is then built from. }
procedure ClassicFit(Mode: TMode; N: Integer; const Data: TDataArray;
  const CP: TCalcThreadParams; Seed: Integer; out Fitted: TFitStructure; out C: TArray<Double>);
var
  Engine: TLFPSO_BASE;
  Flat: TFitStructure;
  Polys: TProfileFunctions;
  i, k: Integer;
begin
  C := nil;
  Fitted := Cell(N, 4.5);
  case Mode of
    gmProfile: Engine := TLFPSO_Poly.Create;
    gmTable:   Engine := TLFPSO_Irregular.Create;
  else
    Engine := TLFPSO_Periodic.Create;
  end;
  try
    Engine.Params := ClassicParams(Ord(Mode = gmProfile));
    Engine.Limit := 1E-9;
    Engine.ExpValues := Data;
    Engine.Seed := Seed;
    Engine.Structure := Fitted;
    { The periodic engine holds each stack at its start period (32.5 A here)
      unless told otherwise, and then the one free thickness cannot move. }
    if Mode = gmPeriodic then
      TLFPSO_Periodic(Engine).SetPeriodRange(0, 30, 38);
    Engine.Run(CP);
    case Mode of
      gmPeriodic:
        Fitted.Stacks[0].Layers[FREE_L].P[1].V := Engine.Structure.Stacks[0].Layers[FREE_L].P[1].V;
      gmProfile:
        begin
          Polys := Engine.Polynomes;
          for i := 0 to High(Polys) do
            if (Polys[i].LayerID = FREE_L) and (Polys[i].Subj = ptH) then
            begin
              SetLength(C, Length(Polys[i].C));
              for k := 0 to High(C) do
                C[k] := Polys[i].C[k];
            end;
          Assert.IsTrue(Length(C) >= 2, 'the classic profile fit reports a gradient');
          Fitted.Stacks[0].Layers[FREE_L].P[1].V := C[0];
        end;
      gmTable:
        begin
          { The irregular engine's structure is one stack of N x 4 layers,
            period 1 first, the layers of each period in turn. }
          Flat := Engine.Structure;
          SetLength(Fitted.Stacks[0].Layers[FREE_L].PP[1], N);
          for k := 1 to N do
            Fitted.Stacks[0].Layers[FREE_L].PP[1][k - 1] :=
              Flat.Stacks[0].Layers[(k - 1) * 4 + FREE_L].P[1].V;
        end;
    end;
  finally
    Engine.Free;
  end;
end;

function BuildMap(Mode: TMode; const Fitted: TFitStructure; const C: TArray<Double>): TParamMap;
begin
  Result := TParamMap.Create(Fitted, Mode = gmTable);
  case Mode of
    gmPeriodic: Result.AddParam('s0.l2.thickness', 0, FREE_L, 1);
    gmProfile:  Result.AddProfile('s0.l2.thickness', 0, FREE_L, 1, C);
    gmTable:    Result.AddTable('s0.l2.thickness', 0, FREE_L, 1);
  end;
  Result.AddSummary('s0', 0);
  Result.AddNuisance(Log10(1.2), 0, 1E-6, 0.001, 1);
end;

{ One seed of one case: noise, classic fit, sampler; the truth tallied. }
procedure RunCase(Mode: TMode; N: Integer; Seed: Integer; var Params, Sums: TTally;
  const Title: string; Longer: Integer = 1);
var
  Truth, Fitted: TFitStructure;
  Clean, Data: TDataArray;
  Counts: TArray<Double>;
  C: TArray<Double>;
  CP: TCalcThreadParams;
  Map: TParamMap;
  Post: TLogPosterior;
  Joint: TJointPosterior;
  Run: TSampleRun;
  R: TSampleResult;
  Walkers, st, k: Integer;
  SumD, D1, DN: Double;
  Log: string;
  Watch: TStopwatch;
begin
  Watch := TStopwatch.StartNew;
  Truth := TruthStructure(Mode, N);
  Clean := CurveOf(Truth);
  Noisy(Clean, UInt64(1000 + Seed), Data, Counts);
  CP := TWB4CFixture.CalcParams(Data, 0);
  ClassicFit(Mode, N, Data, CP, Seed, Fitted, C);

  Map := BuildMap(Mode, Fitted, C);
  Post := nil; Joint := nil; Run := nil;
  try
    Post := TLogPosterior.Create(Map, Data, Counts, CP, 1E-9, 10);
    Joint := TJointPosterior.CreateSingle(Post, False);
    Walkers := Max(32, 2 * Joint.Count + 2);
    Run := TSampleRun.Create(Joint, Walkers, CPUCount, False, nil);
    Run.Start('fit', Joint.StartVector, UInt64(Seed));
    { Settle, then start again around the best walker: a classic fit that
      ended off the optimum otherwise leaves walkers behind for good. }
    for st := 1 to SETTLE * Longer do
      Run.Advance(MaxInt, 1);
    Run.Recentre(UInt64(Seed) + 7777);
    { Longer stretches the whole run - steps, burn-in and thinning alike - so
      the number of recorded rows stays what it was. }
    for st := 1 to STEPS * Longer do
      Run.Advance(BURN * Longer, THIN * Longer);
    R := Run.Finish([Data], 50, UInt64(Seed));

    Log := Format('%s seed %d: %d slots, %d walkers, acceptance %.3f, slowest tau %s, %d doubtful, %.0f s' +
      sLineBreak, [Title, Seed, Joint.Count, Walkers, R.AcceptanceMean,
      R.Params[R.TauSlowest].Name, Length(R.TauDoubtful), Watch.Elapsed.TotalSeconds]);
    Log := Log + '  classic fit ended at:';
    for k := 0 to Min(3, Map.Count - 4) do
      Log := Log + Format(' %s = %.5g', [Map.Slots[k].Name, Map.Slots[k].Start]);
    Log := Log + sLineBreak;
    case Mode of
      gmPeriodic:
        Params.Add(Run, R, 's0.l2.thickness', 6, Log);
      gmProfile:
        begin
          Params.Add(Run, R, 's0.l2.thickness.c0', 5.5, Log);
          Params.Add(Run, R, 's0.l2.thickness.c1', 0.05, Log);
        end;
      gmTable:
        for k := 1 to N do
          Params.Add(Run, R, Format('s0.l2.thickness[%d]', [k]), TruthH(Mode, k), Log);
    end;
    SumD := 0;
    for k := 1 to N do
      SumD := SumD + 28 + TruthH(Mode, k);
    D1 := 28 + TruthH(Mode, 1);
    DN := 28 + TruthH(Mode, N);
    Sums.Add(Run, R, 's0.period_mean', SumD / N, Log);
    Sums.Add(Run, R, 's0.total', SumD, Log);
    if Mode <> gmPeriodic then
      Sums.Add(Run, R, 's0.drift', DN - D1, Log);
    Report(Log);
  finally
    Run.Free;
    Joint.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure RunMode(Mode: TMode; N: Integer; const Title: string; MustHold: Boolean);
var
  Params, Sums: TTally;
  Seed: Integer;
begin
  Params := Default(TTally);
  Sums := Default(TTally);
  for Seed := 1 to SEEDS do
    RunCase(Mode, N, Seed, Params, Sums, Title);
  Report(Format('%s: parameters %d/%d in 16-84, %d/%d in 2.5-97.5, worst R-hat %.3f; ' +
    'summaries %d/%d and %d/%d, worst R-hat %.3f' + sLineBreak,
    [Title, Params.In68, Params.Trials, Params.In95, Params.Trials, Params.WorstRHat,
     Sums.In68, Sums.Trials, Sums.In95, Sums.Trials, Sums.WorstRHat]));
  if not MustHold then
    Exit;
  { A chain whose walkers sit in different places has no one range to report,
    whatever the coverage count says: the first periodic run of this gate
    passed the coverage bounds with half its walkers 0.8 A from the truth. }
  Assert.IsTrue(Params.WorstRHat < 1.2,
    Format('%s parameters: the walkers disagree, worst R-hat %.3f', [Title, Params.WorstRHat]));
  Assert.IsTrue(Sums.WorstRHat < 1.2,
    Format('%s summaries: the walkers disagree, worst R-hat %.3f', [Title, Sums.WorstRHat]));
  { 68 % and 95 % are the expected rates; the bounds allow for the few trials. }
  Assert.IsTrue((Params.F68 >= 0.35) and (Params.F68 <= 0.95),
    Format('%s parameters: %.2f of the truths inside 16-84 %%', [Title, Params.F68]));
  Assert.IsTrue(Params.F95 >= 0.75,
    Format('%s parameters: %.2f of the truths inside 2.5-97.5 %%', [Title, Params.F95]));
  Assert.IsTrue((Sums.F68 >= 0.35) and (Sums.F68 <= 0.95),
    Format('%s summaries: %.2f of the truths inside 16-84 %%', [Title, Sums.F68]));
  Assert.IsTrue(Sums.F95 >= 0.75,
    Format('%s summaries: %.2f of the truths inside 2.5-97.5 %%', [Title, Sums.F95]));
end;

procedure Guard;
begin
  if not Enabled then
    Assert.Pass('set XRC_TRUTH_GATE=1 to run the truth gate');
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
end;

procedure TTestTruthGate.Periodic_TruthInsideRange;
begin
  Guard;
  RunMode(gmPeriodic, 20, 'periodic', True);
end;

procedure TTestTruthGate.Profile_TruthInsideRange;
begin
  Guard;
  RunMode(gmProfile, 20, 'profile', True);
end;

procedure TTestTruthGate.Table_TruthInsideRange;
begin
  Guard;
  RunMode(gmTable, 10, 'table (10 entries)', True);
end;

procedure TTestTruthGate.LargeTable_Report;
begin
  Guard;
  { No assertion: the numbers decide where the tool's "indicative" warning starts. }
  RunMode(gmTable, 40, 'table (40 entries)', False);
  RunMode(gmTable, 80, 'table (80 entries)', False);
end;

{ Run length or method? The 10-entry seed whose classic fit ended off the
  optimum, and one 40-entry case, at ten times the steps. No assertion. }
procedure TTestTruthGate.LongRun_Report;
var
  Params, Sums: TTally;
begin
  Guard;
  Params := Default(TTally);
  Sums := Default(TTally);
  RunCase(gmTable, 10, 2, Params, Sums, 'table (10 entries) x10 steps', 10);
  Report(Format('table (10 entries) x10 steps: parameters %d/%d in 16-84, %d/%d in 2.5-97.5, ' +
    'worst R-hat %.3f; summaries worst R-hat %.3f' + sLineBreak,
    [Params.In68, Params.Trials, Params.In95, Params.Trials, Params.WorstRHat, Sums.WorstRHat]));
  Params := Default(TTally);
  Sums := Default(TTally);
  RunCase(gmTable, 40, 1, Params, Sums, 'table (40 entries) x10 steps', 10);
  Report(Format('table (40 entries) x10 steps: parameters %d/%d in 16-84, %d/%d in 2.5-97.5, ' +
    'worst R-hat %.3f; summaries %d/%d and %d/%d, worst R-hat %.3f' + sLineBreak,
    [Params.In68, Params.Trials, Params.In95, Params.Trials, Params.WorstRHat,
     Sums.In68, Sums.Trials, Sums.In95, Sums.Trials, Sums.WorstRHat]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTruthGate);

end.
