(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_UncertRun;

(* The uncertainty run, from a request to value and range per reported name.

   The recipe is the one the truth gate proved (plan A's Outcome): the walkers
   start in a ball around the fitted values and settle; the chain starts again
   around its best walker; then it samples. When the walkers still disagree
   (R-hat above RHAT_AGREE) the whole thing runs once more, longer, from the
   best walker so far. If they disagree after that there is no range to give,
   and the result says so in plain words instead of showing numbers.

   No VCL. Call it from a worker thread: the CPU evaluation pumps the calling
   thread's messages, and that thread must end with
   DrainParallelTasksBeforeExit (unit_otl_drain). *)

interface

uses
  System.SysUtils, unit_Types, unit_UncertRequest;

type
  TUncertRecipe = record
    Settle: Integer;         // steps before the restart around the best walker
    Steps: Integer;          // steps after it
    BurnIn: Integer;         // of those, not recorded
    Thin: Integer;           // every Thin-th step after the burn-in is recorded
    Predictive: Integer;     // curves drawn for the band
    LongerFactor: Integer;   // the second attempt's lengths are this many times longer
    AgreeBelow: Double;      // the walkers agree when the worst R-hat is at most this
    /// 1000 / 3000 / 1000 / 10, 200 curves, three times longer, RHAT_AGREE.
    class function Standard: TUncertRecipe; static;
  end;

  TUncertValue = record
    Name: string;
    Best: Double;                               // the fitted value the run started from
    P2_5, P16, P50, P84, P97_5: Double;         // NaN when the run did not settle
    Minus, Plus: Double;                        // P50 - P16, P84 - P50
    RHat: Double;
    AtLimit: Boolean;                           // the range reaches the value's limit
  end;

  /// <summary>The model curve's range on the measured angles.</summary>
  TUncertBand = record
    Theta, Measured, P16, P50, P84: TArray<Double>;
  end;

  TUncertResult = record
    Settled: Boolean;                           // False: there are no ranges to show
    Stopped: Boolean;                           // the user stopped it
    Message: string;                            // why there are no ranges, in plain words
    Values: TArray<TUncertValue>;               // in Req.Names' order
    Band: TUncertBand;
    Warnings: TArray<string>;                   // plain sentences
    Device: string;                             // 'CPU' or the graphics card's name
    Correlation: TArray<TArray<Double>>;        // over Values, for Details
    Seconds: Double;
    Repeated: Boolean;                          // the longer second attempt was needed
    Walkers, StepsRun: Integer;                 // for Details
  end;

  TUncertProgress = reference to procedure(Step, Total: Integer; SecondsLeft: Double);
  TUncertStop = reference to function: Boolean;

const
  PROGRESS_EVERY = 50;        // steps between progress reports
  NEAR_LIMIT = 0.02;          // a range ending within this fraction of the limits' span reaches the limit
  PRIOR_REPEATED = 0.8;       // half the range at least this fraction of the entered +-: the entry decided
  MSG_NOT_SETTLED = 'The fit has not settled: the uncertainties cannot be given. ' +
    'Refit the model and try again.';

function RunUncertainty(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
  const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64;
  const OnProgress: TUncertProgress; const ShouldStop: TUncertStop): TUncertResult; overload;
function RunUncertainty(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
  const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64;
  const OnProgress: TUncertProgress; const ShouldStop: TUncertStop;
  const Recipe: TUncertRecipe): TUncertResult; overload;

implementation

uses
  System.Math, System.Diagnostics, unit_ParamMap, unit_LogPosterior, unit_JointPosterior,
  unit_SampleRun;

class function TUncertRecipe.Standard: TUncertRecipe;
begin
  Result.Settle := 1000;
  Result.Steps := 3000;
  Result.BurnIn := 1000;
  Result.Thin := 10;
  Result.Predictive := 200;
  Result.LongerFactor := 3;
  Result.AgreeBelow := RHAT_AGREE;
end;

function RunUncertainty(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
  const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64;
  const OnProgress: TUncertProgress; const ShouldStop: TUncertStop): TUncertResult;
begin
  Result := RunUncertainty(Req, Priors, Counts, UseGPU, Seed, OnProgress, ShouldStop,
    TUncertRecipe.Standard);
end;

type
  TStage = record
    Watch: TStopwatch;
    LastStep: Integer;
    LastSeconds: Double;
    Total: Integer;
  end;

{ One report: the time left from the rate since the last report. }
procedure Report(var St: TStage; Step: Integer; const OnProgress: TUncertProgress);
var
  Now_, Left: Double;
begin
  if not Assigned(OnProgress) then
    Exit;
  Now_ := St.Watch.Elapsed.TotalSeconds;
  if Step > St.LastStep then
    Left := (St.Total - Step) * (Now_ - St.LastSeconds) / (Step - St.LastStep)
  else
    Left := NaN;
  St.LastStep := Step;
  St.LastSeconds := Now_;
  OnProgress(Step, St.Total, Left);
end;

procedure FillValues(var Res: TUncertResult; const Req: TUncertRequest; Map: TParamMap;
  const R: TSampleResult; Ranges: Boolean);
var
  Best: TArray<Double>;
  k, j, Slot: Integer;
  Span: Double;
begin
  Map.ReportedValues(Map.StartVector, Best);
  SetLength(Res.Values, Length(Req.Names));
  for k := 0 to High(Req.Names) do
  begin
    Res.Values[k] := Default(TUncertValue);
    Res.Values[k].Name := Req.Names[k].Name;
    if k <= High(Best) then
      Res.Values[k].Best := Best[k]
    else
      Res.Values[k].Best := NaN;
    Res.Values[k].P2_5 := NaN;
    Res.Values[k].P16 := NaN;
    Res.Values[k].P50 := NaN;
    Res.Values[k].P84 := NaN;
    Res.Values[k].P97_5 := NaN;
    Res.Values[k].Minus := NaN;
    Res.Values[k].Plus := NaN;
    Res.Values[k].RHat := NaN;
    for j := 0 to High(R.Params) do
      if R.Params[j].Name = Req.Names[k].Name then
      begin
        Res.Values[k].RHat := R.Params[j].RHat;
        if not Ranges then
          Break;
        Res.Values[k].P2_5 := R.Params[j].Summary.P2_5;
        Res.Values[k].P16 := R.Params[j].Summary.P16;
        Res.Values[k].P50 := R.Params[j].Summary.P50;
        Res.Values[k].P84 := R.Params[j].Summary.P84;
        Res.Values[k].P97_5 := R.Params[j].Summary.P97_5;
        Res.Values[k].Minus := Res.Values[k].P50 - Res.Values[k].P16;
        Res.Values[k].Plus := Res.Values[k].P84 - Res.Values[k].P50;
        Slot := Map.IndexOf(Req.Names[k].Name);
        if (Slot >= 0) and (Req.Names[k].Kind <> unMeasurement) then
        begin
          Span := Map.Slots[Slot].Upper - Map.Slots[Slot].Lower;
          Res.Values[k].AtLimit := (Span > 0) and
            ((Res.Values[k].P16 - Map.Slots[Slot].Lower < NEAR_LIMIT * Span) or
             (Map.Slots[Slot].Upper - Res.Values[k].P84 < NEAR_LIMIT * Span));
        end;
        Break;
      end;
  end;
end;

procedure FillWarnings(var Res: TUncertResult; const Req: TUncertRequest;
  const Priors: TArray<TUncertPrior>; const Counts: TArray<Double>; const R: TSampleResult);
var
  k, j: Integer;
begin
  if Length(Counts) = 0 then
    Res.Warnings := Res.Warnings + ['No raw counts: the errors rely on the estimated noise only.'];
  if R.GpuError <> '' then
    Res.Warnings := Res.Warnings + ['The graphics card stopped; the run finished on the processor.'];
  for k := 0 to High(Res.Values) do
    if Res.Values[k].AtLimit and (Req.Names[k].Kind in [unValue, unPeriod]) then
      Res.Warnings := Res.Warnings + [Format('%s sits at its limit: its error is cut off there.',
        [Req.Names[k].Caption])];
  for j := 0 to High(Priors) do
    for k := 0 to High(Res.Values) do
      if (Res.Values[k].Name = Priors[j].Name) and
         ((Res.Values[k].P84 - Res.Values[k].P16) / 2 >= PRIOR_REPEATED * Priors[j].SD) then
        Res.Warnings := Res.Warnings + [Format('%s: the result repeats what was entered as known.',
          [Req.Names[k].Caption])];
end;

function RunUncertainty(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
  const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64;
  const OnProgress: TUncertProgress; const ShouldStop: TUncertStop;
  const Recipe: TUncertRecipe): TUncertResult;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Joint: TJointPosterior;
  Run: TSampleRun;
  R: TSampleResult;
  Total: TStopwatch;
  St: TStage;
  Attempt, F, st_, Settle, Steps: Integer;
  Why: string;

  function Stop: Boolean;
  begin
    Result := Assigned(ShouldStop) and ShouldStop();
  end;

begin
  Result := Default(TUncertResult);
  Total := TStopwatch.StartNew;
  if (Length(Counts) > 0) and (Length(Counts) <> Length(Req.Data)) then
  begin
    Result.Message := Format('The stored counts do not belong to this curve (%d counts for %d ' +
      'points). Read the counts again from the measurement file.', [Length(Counts), Length(Req.Data)]);
    Exit;
  end;
  Map := nil;
  Post := nil;
  Joint := nil;
  Run := nil;
  try
   try
    Map := BuildMap(Req, Priors);
    Why := StartProblem(Map, Req);
    if Why <> '' then
    begin
      Result.Message := Why;
      R := Default(TSampleResult);
      FillValues(Result, Req, Map, R, False);
      Exit;
    end;

    Post := TLogPosterior.Create(Map, Req.Data, Counts, Req.CalcParams, Req.RMin, COUNTS_MIN);
    Joint := TJointPosterior.CreateSingle(Post, False);
    Result.Walkers := Max(32, 2 * Joint.Count + 2);
    Run := TSampleRun.Create(Joint, Result.Walkers, CPUCount, UseGPU, nil);

    for Attempt := 1 to 2 do
    begin
      if Attempt = 1 then
        F := 1
      else
        F := Max(1, Recipe.LongerFactor);
      Settle := Recipe.Settle * F;
      Steps := Recipe.Steps * F;
      St := Default(TStage);
      St.Watch := TStopwatch.StartNew;
      St.Total := Settle + Steps;

      if Attempt = 1 then
        Run.Start('fit', Joint.StartVector, Seed)
      else
        Run.Recentre(Seed + 1000);          // from the best walker the first attempt found

      for st_ := 1 to Settle do
      begin
        if Stop then
        begin
          Result.Stopped := True;
          Exit;
        end;
        Run.Advance(MaxInt, 1);              // nothing is recorded while it settles
        if st_ mod PROGRESS_EVERY = 0 then
          Report(St, st_, OnProgress);
      end;
      Run.Recentre(Seed + UInt64(Attempt) * 7777);

      for st_ := 1 to Steps do
      begin
        if Stop then
        begin
          Result.Stopped := True;
          Exit;
        end;
        Run.Advance(Recipe.BurnIn * F, Recipe.Thin * F);
        if (st_ mod PROGRESS_EVERY = 0) or (st_ = Steps) then
          Report(St, Settle + st_, OnProgress);
      end;

      Inc(Result.StepsRun, Settle + Steps);
      R := Run.Finish([Req.Data], Recipe.Predictive, Seed);
      Result.Repeated := Attempt = 2;
      { positive form: a NaN R-hat (nothing recorded) is not agreement }
      Result.Settled := R.RHatWorst <= Recipe.AgreeBelow;
      if Result.Settled then
        Break;
    end;

    Result.Device := R.DeviceUsed;
    FillValues(Result, Req, Map, R, Result.Settled);
    if not Result.Settled then
    begin
      Result.Message := MSG_NOT_SETTLED;
      Exit;
    end;
    if (Length(R.Bands) > 0) and R.Bands[0].Present then
    begin
      Result.Band.Theta := R.Bands[0].Theta;
      Result.Band.Measured := R.Bands[0].Measured;
      Result.Band.P16 := R.Bands[0].P16;
      Result.Band.P50 := R.Bands[0].P50;
      Result.Band.P84 := R.Bands[0].P84;
    end;
    Result.Correlation := R.Correlation;
    FillWarnings(Result, Req, Priors, Counts, R);
   except
     { Whatever the engine raises - no feasible start near a limit, a material
       table that is missing - is told as a sentence: the caller shows
       Message and has nothing to catch. }
     on E: Exception do
     begin
       Result.Settled := False;
       Result.Stopped := False;
       Result.Message := 'The uncertainties could not be computed: ' + E.Message;
     end;
   end;
  finally
    Run.Free;
    Joint.Free;
    Post.Free;
    Map.Free;
    Result.Seconds := Total.Elapsed.TotalSeconds;
  end;
end;

end.
