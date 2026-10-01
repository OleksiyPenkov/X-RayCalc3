(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the Bayes core shared by XRC_MCP and the GUI
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_SampleRun;

(* The ensemble sampler's run, shared by XRC_MCP's sample_posterior job and the
   GUI's parameter uncertainties (phase D0, moved out of unit_MCPSampleJob).

   TSampleRun owns the batch evaluator, the sampler, the compiled derived
   expressions and the recorded rows. It never touches a file, JSON or a job:
   the caller advances it one step at a time and decides what to do with each
   recorded step, with progress and with cancellation. Finish returns plain
   records; the server formats them into summary.json and its messages, the GUI
   into its Uncertainties tab.

   Randomness comes from three separate xoshiro256** generators, all drawn on
   the calling thread: the chain's own (inside TStretchSampler, seeded with
   Seed), the start draw's (Seed xor START_SEED_XOR) and the predictive band's
   (Seed xor PREDICTIVE_SEED_XOR).

   Drive the run from a worker thread, never the VCL main thread: TPosteriorBatch's
   CPU evaluation (LogProbOnCpu, ModelCurves) pumps the calling thread's messages. *)

interface

uses
  System.Generics.Collections,
  unit_Types, unit_ParamMap, unit_StretchSampler, unit_JointPosterior,
  unit_PosteriorBatch, unit_Expression, unit_ChainStats;

const
  SAMPLE_PROGRESS_EVERY = 100;    // steps between progress reports (and the server's state.bin saves)
  START_REDRAWS         = 100;    // redraw rounds for walkers that start infeasible
  STUCK_ACCEPTANCE      = 0.05;   // a walker below this acceptance is reported stuck
  /// sd of ln p (GPU minus CPU) across the final walkers ~= how many posterior
  /// standard deviations the GPU's posterior is shifted from the CPU engine's,
  /// along the worst direction; 0.25 ~= a quarter sigma.
  GPU_CHECK_SD = 0.25;
  { The progress tau (TSampleRun.Progress) uses at most this many recorded
    steps per walker - the tail of Rows - so a report every
    SAMPLE_PROGRESS_EVERY steps stays cheap however long the chain has run;
    Finish's final tau still covers every recorded row. }
  PROGRESS_TAU_WINDOW = 2000;
  START_SEED_XOR      = UInt64($5DEECE66D);
  PREDICTIVE_SEED_XOR = UInt64($A5A5A5A5);
  { sample_posterior's defaults, shared with the GUI's dialog. }
  DEF_SAMPLE_STEPS = 5000;
  DEF_SAMPLE_BURN  = 1000;
  DEF_PREDICTIVE   = 200;
  MAX_PREDICTIVE   = 1000;
  { A derived quantity's name becomes a samples.csv column header verbatim
    (SamplesHeader): a comma, a quote or a CR/LF in it would shift every later
    header cell with no error. \z, not $: with PCRE's default options $ also
    matches just before a trailing line break. }
  DERIVED_NAME_PATTERN = '^[A-Za-z_][A-Za-z0-9_.]*\z';

type
  /// <summary>A derived quantity: a name and an expression over the reported names.</summary>
  TDerivedSpec = record
    Name: string;
    Expr: string;
  end;

  /// <summary>One recorded row: which walker, at which step, its ln p, the two
  /// terms of its blob (NaN when the blob is short) and its reported values
  /// (TJointPosterior.ReportedValues: the slots first, then the aliases).</summary>
  TSampleRow = record
    Walker, Step: Integer;
    LnP, Minus2LnL, PriorTerm: Double;
    Values: TArray<Double>;
  end;

  /// <summary>What a progress report shows. Tau is the slowest slot's, over the
  /// last PROGRESS_TAU_WINDOW recorded steps.</summary>
  TSampleProgress = record
    Step, Total: Integer;
    BestLnP, Acceptance, Tau: Double;
    Recorded, AllReliable: Boolean;
    Device, GpuError: string;      // the batch's device now ('CPU' or the adapter) and why the GPU stopped ('' = it did not)
  end;

  TParamStat = record
    Name: string;
    Summary: TSummary;
    HasTau: Boolean;               // a slot; aliases have no tau
    Tau: Double;
    TauReliable: Boolean;
  end;

  TDerivedStat = record
    Name, Expr: string;
    Summary: TSummary;             // Summary.NonFinite counts the non-finite samples
  end;

  /// <summary>Pointwise 16/50/84 % of the model s·R + b over the drawn samples.
  /// Present is False when there was nothing to draw from.</summary>
  TPredictiveBand = record
    Present: Boolean;
    Theta, Measured, P16, P50, P84: TArray<Double>;
  end;

  /// <summary>ln p as the chain holds it (GPU) minus ln p rescored on the CPU,
  /// at the final walkers. Ran is False when no batch ran on the GPU.</summary>
  TGpuCheck = record
    Ran: Boolean;
    Walkers: Integer;
    Mean, Sd, Spread: Double;
  end;

  TSampleResult = record
    StepsTotal, Recorded, PerWalker: Integer;
    DeviceUsed, GpuError: string;  // read after the band, as the job always did
    GpuUsed: Boolean;              // read after the GPU check
    Acceptance: TArray<Double>;    // per walker
    AcceptanceMean, AcceptanceMin: Double;
    Stuck: TArray<Integer>;        // walkers below STUCK_ACCEPTANCE
    Params: TArray<TParamStat>;    // one per reported name
    Derived: TArray<TDerivedStat>;
    Correlation: TArray<TArray<Double>>;   // over Params, in their order
    TauDoubtful: TArray<string>;   // slots whose tau is unreliable or above PerWalker / TAU_TOLERANCE
    TauSlowest: Integer;           // index into Params of the largest tau; 0 when nothing was recorded
    Bands: TArray<TPredictiveBand>;// one per member
    GpuCheck: TGpuCheck;
  end;

  TSampleRun = class
  private
    FJoint: TJointPosterior;
    FBatch: TPosteriorBatch;
    FSampler: TStretchSampler;
    FDerived: TArray<TDerivedSpec>;
    FExprs: TArray<TExpression>;
    FNames: TArray<string>;
    FRows: TList<TSampleRow>;
    procedure RecordStep;
    function PredictiveBand(const Data: unit_Types.TDataArray; Wanted: Integer;
      Seed: UInt64; Member: Integer): TPredictiveBand;
    function GpuCheck: TGpuCheck;
  public
    /// <summary>Joint stays the caller's and must outlive the run. Raises
    /// ETExpression-family errors for a derived expression that does not
    /// compile against Joint's reported names.</summary>
    constructor Create(Joint: TJointPosterior; Walkers, Threads: Integer; UseGPU: Boolean;
      const Derived: TArray<TDerivedSpec>);
    destructor Destroy; override;
    /// <summary>Draws the start (DrawStart) and starts the chain, both from Seed.</summary>
    procedure Start(const StartMode: string; const StartTheta: TArray<Double>; Seed: UInt64);
    /// <summary>One stretch-move step; rescoring after a mid-step GPU fallback.
    /// Records the step (Walkers rows) and returns True when it is past BurnIn
    /// and on the Thin grid.</summary>
    function Advance(BurnIn, Thin: Integer): Boolean;
    function Progress(Total: Integer): TSampleProgress;
    /// <summary>Rows First .. First + Count - 1 (at most to the last row) as
    /// samples.csv lines (17 significant digits, derived columns last, each
    /// line ending in sLineBreak). A caller writing a long run takes it in
    /// chunks: a default GUI run as one string is ~50 MB.</summary>
    function CsvLines(First: Integer; Count: Integer = MaxInt): string;
    /// <summary>The band (one per Data entry, member k = Data[k]), then the
    /// statistics, then the GPU check - the order the job always ran them in.</summary>
    function Finish(const Data: TArray<unit_Types.TDataArray>; PredictiveSamples: Integer;
      Seed: UInt64): TSampleResult;
    /// <summary>After Finish: frees the sampler and the batch (with any GPU
    /// evaluator) and forgets Joint, which the caller may then free. Names,
    /// Rows and CsvLines stay usable; nothing else may be called.</summary>
    procedure ReleaseEngine;
    property Joint: TJointPosterior read FJoint;
    property Batch: TPosteriorBatch read FBatch;
    property Sampler: TStretchSampler read FSampler;
    property Names: TArray<string> read FNames;
    property Exprs: TArray<TExpression> read FExprs;
    property Rows: TList<TSampleRow> read FRows;
  end;

/// <summary>The walkers' start positions. StartMode 'fit': a Gaussian ball of
/// 1e-3 x (Upper - Lower) around StartTheta, clamped into the bounds;
/// 'bounds': uniform in the bounds, or PriorMean + PriorSD x Gaussian clamped
/// into them for a slot with a prior. Its own generator, seeded with
/// Seed xor $5DEECE66D. Each round's draws are one LogProb batch; a walker
/// whose ln p is not finite is redrawn, up to START_REDRAWS times, after which
/// EMCPError('invalid_argument') is raised.</summary>
function DrawStart(const Slots: TArray<TParamSlot>; const LogProb: TLogProbBatch;
  const StartMode: string; const StartTheta: TArray<Double>; Walkers: Integer;
  Seed: UInt64): TArray<TVector>; overload;
/// <summary>Map's slots, in slot order.</summary>
function DrawStart(Map: TParamMap; const LogProb: TLogProbBatch; const StartMode: string;
  const StartTheta: TArray<Double>; Walkers: Integer; Seed: UInt64): TArray<TVector>; overload;

/// <summary>samples.csv's header: walker,step,lnp,minus2lnL,prior_term, the
/// names, the derived names.</summary>
function SamplesHeader(const Names: TArray<string>; const Derived: TArray<TDerivedSpec>): string;
/// <summary>A samples.csv cell: 17 significant digits, 'nan', 'inf', '-inf'.</summary>
function CsvNum(V: Double): string;

implementation

uses
  System.SysUtils, System.Math, unit_Xoshiro, unit_MCPErrors;

const
  { Digits that make a Double survive a text round trip; FloatToStr's 15 do not. }
  CSV_DIGITS = 17;

{ ------------------------------------------------------------------ start -- }

function DrawSlot(var Rng: TXoshiro256; const Slot: TParamSlot; const StartMode: string;
  Center: Double): Double;
begin
  if StartMode = 'fit' then
    Result := EnsureRange(Center + 1E-3 * (Slot.Upper - Slot.Lower) * Rng.NextGaussian,
      Slot.Lower, Slot.Upper)
  else if Slot.HasPrior then
    Result := EnsureRange(Slot.PriorMean + Slot.PriorSD * Rng.NextGaussian,
      Slot.Lower, Slot.Upper)
  else
    Result := Slot.Lower + (Slot.Upper - Slot.Lower) * Rng.NextDouble;
end;

function DrawStart(const Slots: TArray<TParamSlot>; const LogProb: TLogProbBatch;
  const StartMode: string; const StartTheta: TArray<Double>; Walkers: Integer;
  Seed: UInt64): TArray<TVector>;
var
  Rng: TXoshiro256;
  Pending, Still: TArray<Integer>;
  Batch, Blobs: TArray<TVector>;
  LnP: TArray<Double>;
  Round, k, i: Integer;
  V: TVector;
begin
  if (StartMode = 'fit') and (Length(StartTheta) <> Length(Slots)) then
    raise EMCPError.Create('invalid_argument', Format(
      'start "fit" needs the fit''s %d slot values, got %d', [Length(Slots), Length(StartTheta)]));

  Rng.Seed(Seed xor START_SEED_XOR);
  SetLength(Result, Walkers);
  SetLength(Pending, Walkers);
  for k := 0 to Walkers - 1 do
    Pending[k] := k;

  { Round 0 is the first draw, rounds 1..START_REDRAWS redraw what is still
    infeasible; every round's candidates, in walker order, are one batch. }
  for Round := 0 to START_REDRAWS do
  begin
    SetLength(Batch, Length(Pending));
    for k := 0 to High(Pending) do
    begin
      SetLength(V, Length(Slots));
      for i := 0 to High(Slots) do
        if StartMode = 'fit' then
          V[i] := DrawSlot(Rng, Slots[i], StartMode, StartTheta[i])
        else
          V[i] := DrawSlot(Rng, Slots[i], StartMode, 0);
      Result[Pending[k]] := V;
      Batch[k] := V;
      V := nil;               // the next walker gets an array of its own
    end;
    LogProb(Batch, LnP, Blobs);
    Still := nil;
    for k := 0 to High(Pending) do
      if not (LnP[k] > NegInfinity) then   // -infinity, or NaN
        Still := Still + [Pending[k]];
    Pending := Still;
    if Pending = nil then
      Exit;
  end;
  raise EMCPError.Create('invalid_argument', Format('no feasible start after 100 draws for ' +
    'walker %d: the bounds or priors exclude the posterior''s support', [Pending[0]]));
end;

function DrawStart(Map: TParamMap; const LogProb: TLogProbBatch; const StartMode: string;
  const StartTheta: TArray<Double>; Walkers: Integer; Seed: UInt64): TArray<TVector>;
var
  Slots: TArray<TParamSlot>;
  i: Integer;
begin
  SetLength(Slots, Map.Count);
  for i := 0 to Map.Count - 1 do
    Slots[i] := Map.Slots[i];
  Result := DrawStart(Slots, LogProb, StartMode, StartTheta, Walkers, Seed);
end;

{ ---------------------------------------------------------------- samples -- }

function CsvNum(V: Double): string;
begin
  if IsNan(V) then
    Result := 'nan'
  else if IsInfinite(V) then
  begin
    if V > 0 then
      Result := 'inf'
    else
      Result := '-inf';
  end
  else
    Result := FloatToStrF(V, ffGeneral, CSV_DIGITS, 0, TFormatSettings.Invariant);
end;

function SamplesHeader(const Names: TArray<string>; const Derived: TArray<TDerivedSpec>): string;
var
  i: Integer;
begin
  Result := 'walker,step,lnp,minus2lnL,prior_term';
  for i := 0 to High(Names) do
    Result := Result + ',' + Names[i];
  for i := 0 to High(Derived) do
    Result := Result + ',' + Derived[i].Name;
end;

{ ------------------------------------------------------------- statistics -- }

function Column(Rows: TList<TSampleRow>; k: Integer): TArray<Double>;
var
  i: Integer;
begin
  SetLength(Result, Rows.Count);
  for i := 0 to Rows.Count - 1 do
    Result[i] := Rows[i].Values[k];
end;

function DerivedColumn(Rows: TList<TSampleRow>; E: TExpression): TArray<Double>;
var
  i: Integer;
begin
  SetLength(Result, Rows.Count);
  for i := 0 to Rows.Count - 1 do
    Result[i] := E.Evaluate(Rows[i].Values);
end;

/// Value k of every recorded row, one series per walker in step order, all
/// cut to the shortest (they are equal for whole recorded steps).
function WalkerSeries(Rows: TList<TSampleRow>; Walkers, k: Integer): TArray<TArray<Double>>;
var
  Count: TArray<Integer>;
  i, w, N: Integer;
begin
  SetLength(Result, Walkers);
  SetLength(Count, Walkers);
  for i := 0 to Rows.Count - 1 do
    Inc(Count[Rows[i].Walker]);
  N := MaxInt;
  for w := 0 to Walkers - 1 do
  begin
    SetLength(Result[w], Count[w]);
    N := Min(N, Count[w]);
    Count[w] := 0;
  end;
  for i := 0 to Rows.Count - 1 do
  begin
    w := Rows[i].Walker;
    Result[w][Count[w]] := Rows[i].Values[k];
    Inc(Count[w]);
  end;
  for w := 0 to Walkers - 1 do
    SetLength(Result[w], N);
end;

/// Tau and its reliability per slot (raw slot coordinates).
procedure SlotTaus(Rows: TList<TSampleRow>; Walkers, NSlots: Integer;
  out Taus: TArray<Double>; out Reliable: TArray<Boolean>);
var
  i: Integer;
begin
  SetLength(Taus, NSlots);
  SetLength(Reliable, NSlots);
  for i := 0 to NSlots - 1 do
    Taus[i] := AutocorrTime(WalkerSeries(Rows, Walkers, i), Reliable[i]);
end;

/// SlotTaus over at most Window recorded steps per walker - the tail of
/// Rows, which RecordStep always appends Walkers rows at a time, in step
/// order, so the last Window x Walkers rows are exactly the last Window
/// steps. Cheap for a progress report on a long or resumed chain; the exact
/// tau Finish reports still covers every row.
procedure SlotTausRecent(Rows: TList<TSampleRow>; Walkers, NSlots, Window: Integer;
  out Taus: TArray<Double>; out Reliable: TArray<Boolean>);
var
  PerWalker, Skip, i: Integer;
  Recent: TList<TSampleRow>;
begin
  PerWalker := Rows.Count div Max(1, Walkers);
  if PerWalker <= Window then
  begin
    SlotTaus(Rows, Walkers, NSlots, Taus, Reliable);
    Exit;
  end;
  Skip := (PerWalker - Window) * Walkers;
  Recent := TList<TSampleRow>.Create;
  try
    for i := Skip to Rows.Count - 1 do
      Recent.Add(Rows[i]);
    SlotTaus(Recent, Walkers, NSlots, Taus, Reliable);
  finally
    Recent.Free;
  end;
end;

function MeanAcceptance(S: TStretchSampler): Double;
var
  w: Integer;
begin
  Result := 0;
  for w := 0 to S.Walkers - 1 do
    Result := Result + S.AcceptanceFraction(w);
  Result := Result / S.Walkers;
end;

function SlotsOf(Joint: TJointPosterior): TArray<TParamSlot>;
var
  i: Integer;
begin
  SetLength(Result, Joint.Count);
  for i := 0 to Joint.Count - 1 do
    Result[i] := Joint.Slots[i];
end;

constructor TSampleRun.Create(Joint: TJointPosterior; Walkers, Threads: Integer;
  UseGPU: Boolean; const Derived: TArray<TDerivedSpec>);
var
  k: Integer;
begin
  inherited Create;
  FJoint := Joint;
  FDerived := Derived;
  FBatch := TPosteriorBatch.Create(Joint, Threads, UseGPU);
  FSampler := TStretchSampler.Create(Walkers, Joint.Count, FBatch.AsBatchFunc);
  FNames := Joint.ReportedNames;
  FRows := TList<TSampleRow>.Create;
  SetLength(FExprs, Length(Derived));
  for k := 0 to High(Derived) do
    FExprs[k] := TExpression.Create(Derived[k].Expr, FNames);
end;

destructor TSampleRun.Destroy;
var
  k: Integer;
begin
  FRows.Free;
  for k := 0 to High(FExprs) do
    FExprs[k].Free;
  FSampler.Free;          // before the batch: its LogProb closure captures it
  FBatch.Free;
  inherited;
end;

procedure TSampleRun.ReleaseEngine;
begin
  FreeAndNil(FSampler);   // before the batch: its LogProb closure captures it
  FreeAndNil(FBatch);
  FJoint := nil;
end;

procedure TSampleRun.Start(const StartMode: string; const StartTheta: TArray<Double>;
  Seed: UInt64);
begin
  FSampler.Start(DrawStart(SlotsOf(FJoint), FBatch.AsBatchFunc, StartMode, StartTheta,
    FSampler.Walkers, Seed), Seed);
end;

procedure TSampleRun.RecordStep;
var
  w: Integer;
  Row: TSampleRow;
  Blob: TVector;
begin
  for w := 0 to FSampler.Walkers - 1 do
  begin
    if not FJoint.ReportedValues(FSampler.X[w], Row.Values) then
      raise EMCPError.Create('internal', Format('walker %d sits outside the support at ' +
        'step %d although the sampler accepted it; this should be unreachable', [w, FSampler.Step]));
    Row.Walker := w;
    Row.Step := FSampler.Step;
    Row.LnP := FSampler.LnP[w];
    Blob := FSampler.Blobs[w];
    if Length(Blob) >= 2 then
    begin
      Row.Minus2LnL := Blob[0];
      Row.PriorTerm := Blob[1];
    end
    else
    begin
      Row.Minus2LnL := NaN;       // CsvNum writes 'nan', as the job always did
      Row.PriorTerm := NaN;
    end;
    FRows.Add(Row);
    Row.Values := nil;            // the next walker gets an array of its own
  end;
end;

function TSampleRun.Advance(BurnIn, Thin: Integer): Boolean;
var
  DeviceBefore: string;
begin
  DeviceBefore := FBatch.DeviceUsed;
  FSampler.DoStep;
  if FBatch.DeviceUsed <> DeviceBefore then
    { A fallback happened inside this step (at most one half-step's Accept
      decisions compared a proposal on the new device against a walker
      score still from the old one); rescore before recording or saving
      so every walker's stored ln p comes from the device now in use. }
    FSampler.Rescore;
  Result := (FSampler.Step > BurnIn) and ((FSampler.Step - BurnIn) mod Thin = 0);
  if Result then
    RecordStep;
end;

function TSampleRun.Progress(Total: Integer): TSampleProgress;
var
  Taus: TArray<Double>;
  Reliable: TArray<Boolean>;
  i, Slowest, NSlots: Integer;
begin
  NSlots := FJoint.Count;
  SlotTausRecent(FRows, FSampler.Walkers, NSlots, PROGRESS_TAU_WINDOW, Taus, Reliable);
  Slowest := 0;
  Result.AllReliable := True;
  for i := 0 to NSlots - 1 do
  begin
    if Taus[i] > Taus[Slowest] then
      Slowest := i;
    Result.AllReliable := Result.AllReliable and Reliable[i];
  end;
  Result.Recorded := FRows.Count > 0;
  if NSlots > 0 then
    Result.Tau := Taus[Slowest]
  else
    Result.Tau := 0;
  Result.BestLnP := NegInfinity;
  for i := 0 to FSampler.Walkers - 1 do
    Result.BestLnP := Max(Result.BestLnP, FSampler.LnP[i]);
  Result.Step := FSampler.Step;
  Result.Total := Total;
  Result.Acceptance := MeanAcceptance(FSampler);
  Result.Device := FBatch.DeviceUsed;
  Result.GpuError := FBatch.GpuError;
end;

function TSampleRun.CsvLines(First: Integer; Count: Integer): string;
var
  SB: TStringBuilder;
  i, k, Last: Integer;
  Row: TSampleRow;
begin
  Last := FRows.Count - 1;
  if Count < FRows.Count - First then     // not First + Count: Count may be MaxInt
    Last := First + Count - 1;
  SB := TStringBuilder.Create;
  try
    for i := First to Last do
    begin
      Row := FRows[i];
      SB.Append(Row.Walker).Append(',').Append(Row.Step).Append(',').Append(CsvNum(Row.LnP))
        .Append(',').Append(CsvNum(Row.Minus2LnL)).Append(',').Append(CsvNum(Row.PriorTerm));
      for k := 0 to High(Row.Values) do
        SB.Append(',').Append(CsvNum(Row.Values[k]));
      for k := 0 to High(FExprs) do
        SB.Append(',').Append(CsvNum(FExprs[k].Evaluate(Row.Values)));
      SB.Append(sLineBreak);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

{ WritePredictive's draw and percentiles, without the file. }
function TSampleRun.PredictiveBand(const Data: unit_Types.TDataArray; Wanted: Integer;
  Seed: UInt64; Member: Integer): TPredictiveBand;
var
  Rng: TXoshiro256;
  Idx: TArray<Integer>;
  Thetas: TArray<TVector>;
  Curves: TArray<unit_Types.TDataArray>;
  Count, k, j, T, i: Integer;
  Col: TArray<Double>;
begin
  Result := Default(TPredictiveBand);
  Count := Min(Wanted, FRows.Count);
  if Count <= 0 then
    Exit;
  Rng.Seed(Seed xor PREDICTIVE_SEED_XOR);
  SetLength(Idx, FRows.Count);
  for k := 0 to High(Idx) do
    Idx[k] := k;
  SetLength(Thetas, Count);
  for k := 0 to Count - 1 do
  begin
    j := k + Rng.NextIndex(FRows.Count - k);       // partial Fisher-Yates
    T := Idx[k];
    Idx[k] := Idx[j];
    Idx[j] := T;
    Thetas[k] := Copy(FRows[Idx[k]].Values, 0, FJoint.Count);
  end;
  FBatch.ModelCurves(Thetas, Curves, Member);

  Result.Present := True;
  SetLength(Result.Theta, Length(Data));
  SetLength(Result.Measured, Length(Data));
  SetLength(Result.P16, Length(Data));
  SetLength(Result.P50, Length(Data));
  SetLength(Result.P84, Length(Data));
  for i := 0 to High(Data) do
  begin
    Col := nil;
    for k := 0 to High(Curves) do
      if Length(Curves[k]) > i then      // nil for an infeasible vector
        Col := Col + [Curves[k][i].r];
    TArray.Sort<Double>(Col);
    Result.Theta[i] := Data[i].t;
    Result.Measured[i] := Data[i].r;
    Result.P16[i] := Percentile(Col, 16);
    Result.P50[i] := Percentile(Col, 50);
    Result.P84[i] := Percentile(Col, 84);
  end;
end;

{ GpuCheckJSON's numbers, without the JSON. }
function TSampleRun.GpuCheck: TGpuCheck;
var
  X, Blobs: TArray<TVector>;
  CpuLnP, D: TArray<Double>;
  w: Integer;
begin
  Result := Default(TGpuCheck);
  if not FBatch.GpuUsed then
    Exit;
  SetLength(X, FSampler.Walkers);
  SetLength(D, FSampler.Walkers);
  for w := 0 to FSampler.Walkers - 1 do
  begin
    X[w] := Copy(FSampler.X[w]);   // the sampler's arrays are live; the rescore must not alias them
    D[w] := FSampler.LnP[w];
  end;
  FBatch.LogProbOnCpu(X, CpuLnP, Blobs);
  for w := 0 to FSampler.Walkers - 1 do
    D[w] := D[w] - CpuLnP[w];
  Result.Ran := True;
  Result.Walkers := FSampler.Walkers;
  Result.Mean := Mean(D);
  Result.Sd := StdDev(D);
  Result.Spread := MaxValue(D) - MinValue(D);
end;

function TSampleRun.Finish(const Data: TArray<unit_Types.TDataArray>;
  PredictiveSamples: Integer; Seed: UInt64): TSampleResult;
var
  Taus: TArray<Double>;
  Reliable: TArray<Boolean>;
  Columns: TArray<TArray<Double>>;
  NSlots, k, w, Slowest: Integer;
  A: Double;
begin
  Result := Default(TSampleResult);
  NSlots := FJoint.Count;
  Result.StepsTotal := FSampler.Step;
  Result.Recorded := FRows.Count;

  SetLength(Result.Bands, Length(Data));
  for k := 0 to High(Data) do
    Result.Bands[k] := PredictiveBand(Data[k], PredictiveSamples, Seed, k);
  Result.DeviceUsed := FBatch.DeviceUsed;
  Result.GpuError := FBatch.GpuError;

  SetLength(Result.Acceptance, FSampler.Walkers);
  Result.AcceptanceMin := Infinity;
  for w := 0 to FSampler.Walkers - 1 do
  begin
    A := FSampler.AcceptanceFraction(w);
    Result.Acceptance[w] := A;
    Result.AcceptanceMin := Min(Result.AcceptanceMin, A);
    if A < STUCK_ACCEPTANCE then
      Result.Stuck := Result.Stuck + [w];
  end;
  Result.AcceptanceMean := MeanAcceptance(FSampler);

  SlotTaus(FRows, FSampler.Walkers, NSlots, Taus, Reliable);
  SetLength(Result.Params, Length(FNames));
  SetLength(Columns, Length(FNames));
  for k := 0 to High(FNames) do
  begin
    Columns[k] := Column(FRows, k);
    Result.Params[k].Name := FNames[k];
    Result.Params[k].Summary := Summarize(Columns[k]);
    Result.Params[k].HasTau := k < NSlots;
    if k < NSlots then
    begin
      Result.Params[k].Tau := Taus[k];
      Result.Params[k].TauReliable := Reliable[k];
    end;
  end;
  SetLength(Result.Derived, Length(FExprs));
  for k := 0 to High(FExprs) do
  begin
    Result.Derived[k].Name := FDerived[k].Name;
    Result.Derived[k].Expr := FDerived[k].Expr;
    Result.Derived[k].Summary := Summarize(DerivedColumn(FRows, FExprs[k]));
  end;
  Result.Correlation := Correlation(Columns);

  { AutocorrTime's Reliable already demands N >= 50 tau; both are checked. }
  if FRows.Count > 0 then
  begin
    Result.PerWalker := FRows.Count div FSampler.Walkers;
    Slowest := 0;
    for k := 0 to NSlots - 1 do
    begin
      if Taus[k] > Taus[Slowest] then
        Slowest := k;
      if not Reliable[k] or (Result.PerWalker < TAU_TOLERANCE * Taus[k]) then
        Result.TauDoubtful := Result.TauDoubtful + [FNames[k]];
    end;
    Result.TauSlowest := Slowest;
  end;

  Result.GpuCheck := GpuCheck;
  Result.GpuUsed := FBatch.GpuUsed;
end;

end.
