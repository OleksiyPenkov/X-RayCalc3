unit TestMCPFit;

(* fit_xrr: the argument parser and one real fit.

   Two halves. The first drives ParseFitRequest and looks at the ranges it
   leaves on the structure, because that mapping is the whole contract of
   "free" and "bounds": a free parameter must come out with a real range and
   everything else with min = max = V, which is how the engine is told to hold
   it still. Getting that wrong does not crash - it silently fits the wrong
   thing, or nothing.

   The second runs a fit end to end through a job manager, on a curve the engine
   itself calculated from a known structure, and asserts the two properties a
   client depends on: the chi-squared comes out below the one the start model
   scored, and the same seed gives the same answer twice.

   The engine reads the GUI's Henke tables, so every test that needs a material
   skips with Assert.Pass when they are not installed, as the other MCP
   fixtures do. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  unit_Types, unit_MCPSandbox, unit_MCPJobs, unit_MCPStructure, unit_MCPFit;

type
  [TestFixture]
  TTestMCPFit = class
  private
    FTemp: string;
    FSavedWorkDir: TWorkDir;
    /// <summary>ParseFitRequest over a JSON literal. The caller owns nothing.</summary>
    function Parse(const JSONText: string): TFitRequest;
    /// <summary>The range one layer parameter came out with.</summary>
    procedure RangeOf(const Req: TFitRequest; GUIStack, GUILayer, P: Integer;
      out AMin, AMax: Double);
    /// <summary>The code of the EMCPError ParseFitRequest raises, or '' when it
    /// raises nothing.</summary>
    function ErrorCodeOf(const JSONText: string): string;
    /// <summary>[[theta, I], ...] of the reference structure, as fit_xrr takes
    /// it inline.</summary>
    function SyntheticCurveJSON: string;
    /// <summary>Submits one fit on an existing manager and returns the job.</summary>
    function SubmitOn(Mgr: TJobManager; Seed, Population, Iterations: Integer;
      const CurveJSON: string; const FreeJSON: string = '';
      const Extra: string = ''; const StructureJSON: string = ''): TJob;
    /// <summary>One complete fit through a manager of its own. The result is
    /// the caller's to free; nil when the job did not finish.</summary>
    function RunFit(Seed: Integer; const CurveJSON: string;
      const FreeJSON: string = ''; const Extra: string = '';
      Population: Integer = 0; Iterations: Integer = 0;
      const StructureJSON: string = ''): TJSONObject;
    /// <summary>Polls until the job reaches Wanted, ends in some other final
    /// state, or the timeout elapses.</summary>
    function WaitForState(Job: TJob; Wanted: TJobState; TimeoutMs: Integer): Boolean;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Free_NoBounds_GivesPlusMinusThirtyPercent;
    [Test] procedure Free_LeavesEveryOtherParameterFixed;
    [Test] procedure Bounds_Explicit_ReplaceTheDefault;
    [Test] procedure Bounds_NegativeMin_ClampedToZeroForSigmaAndDensity;
    [Test] procedure Bounds_BothNegative_Refused;
    [Test] procedure Bounds_NegativeMinAndZeroMax_Refused;
    [Test] procedure Bounds_ThicknessMinNotPositive_Refused;
    [Test] procedure Bounds_OfAParameterThatIsNotFree_Refused;
    [Test] procedure Free_ParameterStartingAtZero_NeedsExplicitBounds;
    [Test] procedure Free_Substrate_IsNotFittable;
    [Test] procedure Free_Scale_IsNotFittable;
    [Test] procedure Free_Background_IsNotFittable;
    [Test] procedure Free_Resolution_IsNotFittable;
    [Test] procedure Free_CapAndBuffer_AddressTheirOwnStacks;
    [Test] procedure Free_StackIndex_CountsFromTheSubstrateUp;
    [Test] procedure Free_UnknownStack_Refused;
    [Test] procedure Curve_NonPositiveIntensity_Refused;
    [Test] procedure ThetaRange_RestrictsTheCurve;
    [Test] procedure Resolution_TooCoarseAGrid_Refused;
    [Test] procedure Profile_WithoutARepeatingStack_Refused;
    [Test] procedure Free_OmittedDensity_StartsAtBulkInsideItsBounds;
    [Test] procedure Free_OmittedDensity_NoBounds_DefaultsAroundBulk;
    [Test] procedure Bounds_StartOutsideExplicitBounds_Refused;
    [Test] procedure ProfileFit_FreeOmittedDensity_Moves;
    [Test] procedure Period_Free_DefaultBoundsAroundStart;
    [Test] procedure Period_Bounds_Explicit;
    [Test] procedure Period_Free_OnCapOrBuffer_Refused;
    [Test] procedure Period_Free_WithAllThicknessesFixed_Refused;
    [Test] procedure Period_Free_InProfileMode_Refused;
    [Test] procedure Period_StartOutsideBounds_Refused;
    [Test] procedure Scale_MultipliesTheMeasuredCurve;
    [Test] procedure Scale_NotPositive_Refused;
    [Test] procedure Fit_FreePeriod_MovesThePeriod;
    [Test] procedure Fit_Scale_IsEchoed;

    [Test] procedure Fit_OnItsOwnCurve_BeatsTheStartModel;
    [Test] procedure Fit_SameSeedTwice_GivesTheSameAnswer;
    [Test] procedure Fit_Cancelled_StopsAndLeavesNoResult;
  end;

implementation

uses
  System.IOUtils, System.Classes, System.Diagnostics,
  unit_Config, unit_MCPErrors, unit_MCPCalc;

const
  { The reference sample: a 10-period Ru/C multilayer on Si, the same materials
    the design note's worked example uses. Layers are listed surface-first: layers[0]
    is nearest the surface, the last entry is nearest the substrate. }
  TRUE_STRUCTURE =
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":53.8,"sigma":3},' +
    '{"material":"Ru","thickness":14.7,"sigma":3}]}]}';

  { The same stack with the two thicknesses moved, keeping the period: the
    periodic engine holds the period of the start model, so a start that changes
    it could never reach the answer. }
  START_STRUCTURE =
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":55.5,"sigma":3},' +
    '{"material":"Ru","thickness":13.0,"sigma":3}]}]}';

  { The same stack with the wrong period: 60 A against the true 68.5 A. The
    periodic engine holds the period unless "period" is freed, so this start
    can only reach the answer when it is. }
  START_WRONG_PERIOD =
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":47.5,"sigma":3},' +
    '{"material":"Ru","thickness":12.5,"sigma":3}]}]}';

  { thicknesses of both layers plus the period of the stack }
  PERIOD_FREE =
    '[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]},' +
    '{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]},' +
    '{"target":"period","stack":0}]';

  { One stack, a cap and a buffer, for the addressing tests. }
  CAP_BUFFER_STRUCTURE =
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":50,"sigma":3},' +
    '{"material":"Ru","thickness":20,"sigma":3}]}],' +
    '"cap":{"material":"C","thickness":30,"sigma":2},' +
    '"buffer":{"material":"Ru","thickness":100,"sigma":4}}';

  { Two repeating stacks, substrate-first: stacks[0] is the one next to the
    substrate. }
  TWO_STACK_STRUCTURE =
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[' +
    '{"N":5,"layers":[{"material":"C","thickness":11,"sigma":3},' +
    '{"material":"Ru","thickness":12,"sigma":3}]},' +
    '{"N":7,"layers":[{"material":"C","thickness":21,"sigma":3},' +
    '{"material":"Ru","thickness":22,"sigma":3}]}]}';

  { A short curve that is never fitted - the parser tests only need it to be a
    valid, ordered, positive-intensity curve. Every request that uses it asks
    for "resolution": 0, because six points are far too few for the engine's
    +/-0.1 degree convolution window and the parser says so before it ever looks
    at "free" (which is what Resolution_TooCoarseAGrid_Refused pins down). }
  DUMMY_CURVE = '[[0.5,1],[0.6,0.9],[0.7,0.8],[0.8,0.7],[0.9,0.6],[1.0,0.5]]';

  FIT_TOLERANCE = 1E-9;      // low enough that the run never stops early
  FIT_POPULATION = 12;
  FIT_ITERATIONS = 8;
  { The polynomial engine perturbs every coefficient, so most of its early
    particles are worse than a uniform start; it needs a larger swarm than the
    periodic engine before anything beats the start model (probe of
    2026-09-10: 12 x 8 stays at chi2_start, 30 x 15 reaches a fifth of it). }
  PROFILE_POPULATION = 30;
  PROFILE_ITERATIONS = 15;
  { The cancel test's budget: big enough that the run cannot possibly finish
    while the test is watching, so that reaching "cancelled" can only be the
    cancel. It costs one iteration of wall clock, not five hundred. }
  CANCEL_POPULATION = 200;
  CANCEL_ITERATIONS = 500;
  CURVE_POINTS = 200;
  CURVE_THETA_MIN = 0.3;
  CURVE_THETA_MAX = 3.0;
  CU_K_ALPHA = 1.5406;

{ ----------------------------------------------------------------- helpers -- }

function HenkePath: string;
begin
  Result := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);
end;

/// The materials every test in this fixture uses. Without them the engine
/// cannot build a model and the test says so rather than failing.
function HenkeTablesPresent: Boolean;
const
  Needed: array [0 .. 2] of string = ('Ru', 'C', 'Si');
var
  i: Integer;
begin
  for i := Low(Needed) to High(Needed) do
    if not TFile.Exists(HenkePath + Needed[i] + '.bin') then
      Exit(False);
  Result := True;
end;

{ ----------------------------------------------------------------- fixture -- }

procedure TTestMCPFit.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Fit_' + TGUID.NewGuid.ToString);
  FSavedWorkDir := WorkDir;
  WorkDir := TWorkDir.Create(FTemp);
  WorkDir.EnsureLayout;
end;

procedure TTestMCPFit.TearDown;
begin
  WorkDir.Free;
  WorkDir := FSavedWorkDir;
  try
    if TDirectory.Exists(FTemp) then
      TDirectory.Delete(FTemp, True);
  except
    // a leftover temp folder must not turn into a test failure
  end;
end;

function TTestMCPFit.Parse(const JSONText: string): TFitRequest;
var
  J: TJSONObject;
begin
  J := TJSONObject.ParseJSONValue(JSONText) as TJSONObject;
  Assert.IsNotNull(J, 'the test arguments do not parse as JSON');
  try
    Result := ParseFitRequest(J);
  finally
    J.Free;
  end;
end;

function TTestMCPFit.ErrorCodeOf(const JSONText: string): string;
begin
  Result := '';
  try
    Parse(JSONText);
  except
    on E: EMCPError do
      Result := E.Code;
  end;
end;

procedure TTestMCPFit.RangeOf(const Req: TFitRequest; GUIStack, GUILayer, P: Integer;
  out AMin, AMax: Double);
begin
  AMin := Req.Structure.Stacks[GUIStack].Layers[GUILayer].P[P].min;
  AMax := Req.Structure.Stacks[GUIStack].Layers[GUILayer].P[P].max;
end;

function TTestMCPFit.SyntheticCurveJSON: string;
var
  Req: TCalcRequest;
  Used: TFitStructure;
  Curve: TDataArray;
  J: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
begin
  Req := Default(TCalcRequest);
  J := TJSONObject.ParseJSONValue(TRUE_STRUCTURE) as TJSONObject;
  try
    Req.Structure := StructureFromJSON(J, Req.Info);
  finally
    J.Free;
  end;
  Req.Lambda := CU_K_ALPHA;
  Req.ThetaMin := CURVE_THETA_MIN;
  Req.ThetaMax := CURVE_THETA_MAX;
  Req.Points := CURVE_POINTS;
  Req.Polarization := cmSP;
  Req.RMin := 1E-7;

  Curve := RunCalc(Req, Used);

  Arr := TJSONArray.Create;
  try
    for i := 0 to High(Curve) do
      Arr.AddElement(JSONArgs.NumArr(TArray<Double>.Create(Curve[i].t, Curve[i].r)));
    Result := Arr.ToJSON;
  finally
    Arr.Free;
  end;
end;

function TTestMCPFit.WaitForState(Job: TJob; Wanted: TJobState;
  TimeoutMs: Integer): Boolean;
var
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  while SW.ElapsedMilliseconds < TimeoutMs do
  begin
    if Job.State = Wanted then
      Exit(True);
    { A job that has ended in some other way is never going to reach Wanted, so
      say so at once: a broken fit should fail the suite in a second rather than
      hold it for the whole timeout. }
    if (Job.State in [jsFinished, jsFailed, jsCancelled]) and (Job.State <> Wanted) then
      Exit(False);
    Sleep(20);
  end;
  Result := Job.State = Wanted;
end;

/// Why a job ended the way it did, for an assertion message.
function JobErrorText(Job: TJob): string;
var
  E: TJSONObject;
begin
  E := Job.CloneError;
  try
    if E = nil then
      Result := '(no error recorded)'
    else
      Result := E.ToJSON;
  finally
    E.Free;
  end;
end;

function TTestMCPFit.SubmitOn(Mgr: TJobManager; Seed, Population,
  Iterations: Integer; const CurveJSON, FreeJSON, Extra, StructureJSON: string): TJob;
const
  DEFAULT_FREE =
    '[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]},' +
    '{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]';
var
  Args, FreeList, Start: string;
  Req: TFitRequest;
  Request: TJSONObject;
begin
  FreeList := FreeJSON;
  if FreeList = '' then
    FreeList := DEFAULT_FREE;
  Start := StructureJSON;
  if Start = '' then
    Start := START_STRUCTURE;

  { Extra is spliced in verbatim, so it starts with a comma: ',"profile":true' }
  Args := Format(
    '{"structure":%s,"curve":%s,"lambda":%.6f,"free":%s,' +
    '"optimizer":{"population":%d,"iterations":%d,"tolerance":%g},' +
    '"resolution":0,"points_inline_max":0%s}',
    [Start, CurveJSON, CU_K_ALPHA, FreeList, Population, Iterations,
     FIT_TOLERANCE, Extra], TFormatSettings.Invariant);

  Req := Parse(Args);

  Request := TJSONObject.Create;
  try
    Request.AddPair('seed', TJSONNumber.Create(Seed));
    Result := Mgr.Submit(jkFit, Seed,
      procedure(AJob: TJob)
      begin
        RunFitJob(AJob, Req);
      end,
      Request);
  finally
    Request.Free;
  end;
end;

function TTestMCPFit.RunFit(Seed: Integer; const CurveJSON, FreeJSON,
  Extra: string; Population, Iterations: Integer;
  const StructureJSON: string): TJSONObject;
var
  Mgr: TJobManager;
  Job: TJob;
begin
  if Population <= 0 then
    Population := FIT_POPULATION;
  if Iterations <= 0 then
    Iterations := FIT_ITERATIONS;
  Mgr := TJobManager.Create(WorkDir);
  try
    Job := SubmitOn(Mgr, Seed, Population, Iterations, CurveJSON, FreeJSON, Extra,
      StructureJSON);
    if not WaitForState(Job, jsFinished, 180000) then
      Assert.Fail(Format('the fit ended as "%s": %s',
        [JobStateName(Job.State), JobErrorText(Job)]));
    Result := Job.CloneResult;
  finally
    Mgr.Free;
  end;
end;

{ ------------------------------------------------------- free and bounds -- }

procedure TTestMCPFit.Free_NoBounds_GivesPlusMinusThirtyPercent;
var
  Req: TFitRequest;
  Lo, Hi: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  // stacks[0] is the only stack, so it is GUI stack 0; layer 1 is the Ru at 13 A
  RangeOf(Req, 0, 1, 1, Lo, Hi);
  Assert.AreEqual(13.0 * 0.7, Lo, 1E-4, 'lower bound');
  Assert.AreEqual(13.0 * 1.3, Hi, 1E-4, 'upper bound');
  Assert.AreEqual(1, Length(Req.FreeParams), 'one free parameter');
  Assert.AreEqual(1, Req.FreeParams[0].P, 'thickness is parameter 1');
end;

procedure TTestMCPFit.Free_LeavesEveryOtherParameterFixed;
var
  Req: TFitRequest;
  Lo, Hi: Double;
  i, j, p: Integer;
  Free_: Boolean;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  for i := 0 to High(Req.Structure.Stacks) do
    for j := 0 to High(Req.Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
      begin
        Free_ := (i = 0) and (j = 1) and (p = 1);
        RangeOf(Req, i, j, p, Lo, Hi);
        if Free_ then
          Assert.IsTrue(Hi > Lo,
            'the free parameter must have a range')
        else
          Assert.AreEqual(Hi - Lo, 0.0, 0.0,
            Format('stack %d layer %d parameter %d must be fixed (min = max)',
                   [i, j, p]));
      end;

  // the substrate is never in the particle vector; its range stays empty too
  Assert.AreEqual(Req.Structure.Subs.P[2].max - Req.Structure.Subs.P[2].min, 0.0, 0.0,
    'substrate sigma must be fixed');
end;

procedure TTestMCPFit.Bounds_Explicit_ReplaceTheDefault;
var
  Req: TFitRequest;
  Lo, Hi: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"thickness",' +
    '"min":10,"max":16}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  RangeOf(Req, 0, 1, 1, Lo, Hi);
  Assert.AreEqual(10.0, Lo, 1E-6, 'lower bound');
  Assert.AreEqual(16.0, Hi, 1E-6, 'upper bound');
  Assert.AreEqual(10.0, Req.FreeParams[0].Min, 1E-6, 'echoed lower bound');
  Assert.AreEqual(16.0, Req.FreeParams[0].Max, 1E-6, 'echoed upper bound');
end;

procedure TTestMCPFit.Bounds_NegativeMin_ClampedToZeroForSigmaAndDensity;
var
  Req: TFitRequest;
  Lo, Hi: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,' +
    '"parameters":["sigma","density"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"sigma",' +
    '"min":-2,"max":6},' +
    '{"target":"layer","stack":0,"layer":1,"parameter":"density",' +
    '"min":-1,"max":14}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  RangeOf(Req, 0, 1, 2, Lo, Hi);
  Assert.AreEqual(0.0, Lo, 0.0, 'sigma min is clamped at zero');
  Assert.AreEqual(6.0, Hi, 1E-6, 'sigma max');

  RangeOf(Req, 0, 1, 3, Lo, Hi);
  Assert.AreEqual(0.0, Lo, 0.0, 'density min is clamped at zero');
  Assert.AreEqual(14.0, Hi, 1E-6, 'density max');
end;

procedure TTestMCPFit.Bounds_BothNegative_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { min -5, max -1 satisfies "max greater than min" as written, and the clamp
    would then turn it into 0 .. -1 - an inverted range nobody asked for. }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["density"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"density",' +
    '"min":-5,"max":-1}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Bounds_NegativeMinAndZeroMax_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { min -5, max 0 clamps to 0 .. 0: an empty range, so a parameter the client
    believes is free that the engine holds still - and for a density 0 is the
    "use the Henke bulk value" sentinel, so it would not even look wrong. }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["density"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"density",' +
    '"min":-5,"max":0}]}',
    [START_STRUCTURE, DUMMY_CURVE])));

  { the same for sigma, where 0 is a legitimate value and the empty range is the
    only thing wrong with it }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["sigma"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"sigma",' +
    '"min":-2,"max":0}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Bounds_ThicknessMinNotPositive_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"thickness",' +
    '"min":0,"max":20}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Bounds_OfAParameterThatIsNotFree_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":0,"parameter":"sigma",' +
    '"min":1,"max":5}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Free_ParameterStartingAtZero_NeedsExplicitBounds;
var
  Zero: string;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { sigma 0: the default +/-30% range around it is empty, which would leave the
    client with a parameter it believes is free and the engine holding still. }
  Zero :=
    '{"substrate":{"material":"Si"},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":50},{"material":"Ru","thickness":20}]}]}';

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["sigma"]}]}',
    [Zero, DUMMY_CURVE])));

  { with an explicit bound the same request is fine }
  Assert.AreEqual('', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["sigma"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"sigma",' +
    '"min":0,"max":6}]}',
    [Zero, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Free_Substrate_IsNotFittable;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('not_fittable', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"substrate","parameters":["sigma","density"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Free_Scale_IsNotFittable;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('not_fittable', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"scale","parameters":["scale"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Free_Background_IsNotFittable;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('not_fittable', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"background","parameters":["background"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Free_Resolution_IsNotFittable;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('not_fittable', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"resolution","parameters":["resolution"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Free_CapAndBuffer_AddressTheirOwnStacks;
var
  Req: TFitRequest;
  Lo, Hi: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":"cap","parameters":["thickness"]},' +
    '{"target":"layer","stack":"buffer","parameters":["thickness"]}]}',
    [CAP_BUFFER_STRUCTURE, DUMMY_CURVE]));

  Assert.AreEqual(2, Length(Req.FreeParams), 'two free parameters');
  Assert.IsTrue(Req.Info.HasCap and Req.Info.HasBuffer, 'cap and buffer are present');

  RangeOf(Req, Req.Info.CapIndex, 0, 1, Lo, Hi);
  Assert.AreEqual(30.0 * 0.7, Lo, 1E-4, 'cap lower bound');
  Assert.AreEqual(30.0 * 1.3, Hi, 1E-4, 'cap upper bound');

  RangeOf(Req, Req.Info.BufferIndex, 0, 1, Lo, Hi);
  Assert.AreEqual(100.0 * 0.7, Lo, 1E-4, 'buffer lower bound');
  Assert.AreEqual(100.0 * 1.3, Hi, 1E-4, 'buffer upper bound');

  // the multilayer between them is untouched
  RangeOf(Req, Req.Info.PeriodicStackIndex, 0, 1, Lo, Hi);
  Assert.AreEqual(Hi - Lo, 0.0, 0.0, 'the stack layers stay fixed');
end;

procedure TTestMCPFit.Free_StackIndex_CountsFromTheSubstrateUp;
var
  Req: TFitRequest;
  Lo, Hi: Double;
  Idx: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { stacks[0] is the one next to the substrate - the N = 5 stack, whose Ru layer
    is 12 A. The GUI holds the stacks surface first, so this only works through
    Info.StackMap. }
  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]}',
    [TWO_STACK_STRUCTURE, DUMMY_CURVE]));

  Idx := Req.Info.StackMap[0];
  Assert.AreEqual(5, Req.Structure.Stacks[Idx].N, 'stacks[0] is the N = 5 stack');
  RangeOf(Req, Idx, 1, 1, Lo, Hi);
  Assert.AreEqual(12.0 * 0.7, Lo, 1E-4, 'lower bound of the 12 A layer');
  Assert.AreEqual(12.0 * 1.3, Hi, 1E-4, 'upper bound of the 12 A layer');

  // the other stack is untouched
  RangeOf(Req, Req.Info.StackMap[1], 1, 1, Lo, Hi);
  Assert.AreEqual(Hi - Lo, 0.0, 0.0, 'stacks[1] stays fixed');
end;

procedure TTestMCPFit.Free_UnknownStack_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":3,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])), 'a stack index past the end');

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":"cap","parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])), 'a cap the structure does not have');
end;

procedure TTestMCPFit.Curve_NonPositiveIntensity_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":[[0.5,1],[0.6,0],[0.7,0.8]],"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]}',
    [START_STRUCTURE])));
end;

procedure TTestMCPFit.ThetaRange_RestrictsTheCurve;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"theta_range":{"min":0.65,"max":0.85},' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  { 0.65 to 0.85 keeps 0.7 and 0.8 of the six-point curve, and the reported
    range is the one the kept points span, not the one that was asked for. }
  Assert.AreEqual(2, Length(Req.Data), 'the points inside the range');
  Assert.AreEqual(0.7, Req.ThetaMin, 1E-6, 'reported range start');
  Assert.AreEqual(0.8, Req.ThetaMax, 1E-6, 'reported range end');
end;

procedure TTestMCPFit.Resolution_TooCoarseAGrid_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { The same request as the others but without "resolution": 0. Six points over
    half a degree cannot carry the engine's +/-0.1 degree convolution window,
    and TCalc.Convolute would index outside its own result array, so the parser
    refuses it rather than letting the job crash. }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Profile_WithoutARepeatingStack_Refused;
var
  Flat: string;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Flat :=
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":1,"layers":[{"material":"Ru","thickness":200,"sigma":3}]}]}';

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"profile":true,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [Flat, DUMMY_CURVE])));
end;

{ ------------------------------------------------------------- the fit -- }

procedure TTestMCPFit.Free_OmittedDensity_StartsAtBulkInsideItsBounds;
var
  Req: TFitRequest;
  V, AMin, AMax: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { START_STRUCTURE gives no densities, which means "the bulk value" to the
    engine. A free density must then START at that bulk value, inside its
    bounds - not at the 0 the JSON left behind. TLFPSO_Poly seeds the swarm
    around the start value and clamps it to the bounds, so a start of 0 under
    a lower bound of 8 pins every particle at 8 while particle 0 keeps bulk,
    and the fit never moves (paper-2 session, jobs fit-20260910-08*). }
  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["density"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"density",' +
    '"min":8,"max":12.5}]}', [START_STRUCTURE, DUMMY_CURVE]));

  V := Req.Structure.Stacks[0].Layers[1].P[3].V;       // Ru
  RangeOf(Req, 0, 1, 3, AMin, AMax);
  Assert.IsTrue(V > 8,
    Format('the start density must be the Ru bulk value, not %.3g', [V]));
  Assert.IsTrue((V >= AMin) and (V <= AMax),
    Format('start density %.3g must lie inside [%.3g, %.3g]', [V, AMin, AMax]));
  Assert.AreEqual(Double(8), AMin, 1E-9, 'explicit lower bound kept');
  Assert.AreEqual(Double(12.5), AMax, 1E-9, 'explicit upper bound kept');

  { the layer that was not freed carries its bulk density too, held fixed }
  Assert.IsTrue(Req.Structure.Stacks[0].Layers[0].P[3].V > 0,
    'C gets its bulk density as well');
  Assert.AreEqual(Req.Structure.Stacks[0].Layers[0].P[3].V,
    Req.Structure.Stacks[0].Layers[0].P[3].min, 1E-9, 'a fixed density has min = V');
  Assert.AreEqual(Req.Structure.Stacks[0].Layers[0].P[3].V,
    Req.Structure.Stacks[0].Layers[0].P[3].max, 1E-9, 'a fixed density has max = V');
end;

procedure TTestMCPFit.Free_OmittedDensity_NoBounds_DefaultsAroundBulk;
var
  Req: TFitRequest;
  V, AMin, AMax: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { With the bulk value as the start, the usual +/-30% default applies; an
    omitted density is not "a parameter starting at zero". }
  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["density"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  V := Req.Structure.Stacks[0].Layers[1].P[3].V;
  RangeOf(Req, 0, 1, 3, AMin, AMax);
  Assert.IsTrue(V > 0, 'the start density is the bulk value');
  Assert.AreEqual(V * 0.7, AMin, V * 1E-6, 'default lower bound is 70% of bulk');
  Assert.AreEqual(V * 1.3, AMax, V * 1E-6, 'default upper bound is 130% of bulk');
end;

procedure TTestMCPFit.Bounds_StartOutsideExplicitBounds_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { Ru starts at 13.0 A; bounds of 30..40 exclude it. The engines seed the
    swarm around the start value and clamp to the bounds, so such a request
    would fit from the bound, not from the model the client gave - refuse it. }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}],' +
    '"bounds":[{"target":"layer","stack":0,"layer":1,"parameter":"thickness",' +
    '"min":30,"max":40}]}', [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.ProfileFit_FreeOmittedDensity_Moves;
var
  Res: TJSONObject;
  Chi2, Chi2Start, Rho: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { The paper-2 session's case: profile fit, the Ru density free with explicit
    bounds and no start density in the structure. Before the fix chi2 stayed
    at chi2_start for any population, order or seed. }
  Res := RunFit(7, SyntheticCurveJSON,
    '[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]},' +
    '{"target":"layer","stack":0,"layer":1,"parameters":["thickness","density"]}]',
    ',"profile":true,"bounds":[{"target":"layer","stack":0,"layer":1,' +
    '"parameter":"density","min":8,"max":12.5}]',
    PROFILE_POPULATION, PROFILE_ITERATIONS);
  try
    Assert.IsNotNull(Res, 'the job produced no result');
    Assert.AreEqual('TLFPSO_Poly', Res.GetValue<string>('engine'));
    Chi2 := Res.GetValue<Double>('chi2');
    Chi2Start := Res.GetValue<Double>('chi2_start');
    Assert.IsTrue(Chi2 < Chi2Start,
      Format('a profile fit with a free, omitted density must move: chi2 %.6g ' +
             'against chi2_start %.6g', [Chi2, Chi2Start]));

    Rho := Res.GetValue<Double>('fitted_structure.stacks[0].layers[1].density');
    Assert.IsTrue((Rho >= 8) and (Rho <= 12.5),
      Format('the fitted Ru density %.4g must lie inside its bounds', [Rho]));
    Assert.IsTrue(Res.GetValue<Double>('start_structure.stacks[0].layers[1].density') > 8,
      'the start structure reports the bulk density the fit started from');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Period_Free_DefaultBoundsAroundStart;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"free":%s}',
    [START_STRUCTURE, DUMMY_CURVE, PERIOD_FREE]));
  Assert.AreEqual(1, Length(Req.PeriodRefs), 'one period freed');
  Assert.AreEqual(0, Req.PeriodRefs[0].StackJSON);
  Assert.AreEqual(Double(68.5), Req.PeriodRefs[0].StartD, 1E-6, 'start period = C + Ru');
  Assert.AreEqual(Double(68.5 * 0.7), Req.PeriodRefs[0].Min, 1E-6, 'default -30%');
  Assert.AreEqual(Double(68.5 * 1.3), Req.PeriodRefs[0].Max, 1E-6, 'default +30%');
  Assert.AreEqual(2, Length(Req.FreeParams), 'the period is not a layer parameter');
end;

procedure TTestMCPFit.Period_Bounds_Explicit;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { "parameter":"period" is accepted (and optional) on a period bound }
  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"free":%s,' +
    '"bounds":[{"target":"period","stack":0,"parameter":"period","min":60,"max":75}]}',
    [START_STRUCTURE, DUMMY_CURVE, PERIOD_FREE]));
  Assert.AreEqual(Double(60), Req.PeriodRefs[0].Min, 1E-9);
  Assert.AreEqual(Double(75), Req.PeriodRefs[0].Max, 1E-9);

  { a period bound on a stack whose period is not free is an error }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}],' +
    '"bounds":[{"target":"period","stack":0,"min":60,"max":75}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Period_Free_OnCapOrBuffer_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { a cap has no period; neither has a stack with N = 1 }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":"cap","parameters":["thickness"]},' +
    '{"target":"period","stack":"cap"}]}', [CAP_BUFFER_STRUCTURE, DUMMY_CURVE])));
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]},' +
    '{"target":"period","stack":0}]}',
    ['{"substrate":{"material":"Si"},"stacks":[{"N":1,"layers":[' +
     '{"material":"C","thickness":50},{"material":"Ru","thickness":20}]}]}',
     DUMMY_CURVE])));
end;

procedure TTestMCPFit.Period_Free_WithAllThicknessesFixed_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { the period is the sum of the layer thicknesses: with every thickness of
    the stack held, nothing could move it }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":1,"parameters":["sigma"]},' +
    '{"target":"period","stack":0}]}', [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Period_Free_InProfileMode_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { TLFPSO_Poly never holds the period - it floats within the thickness
    bounds - so a period target has nothing to act on there }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"profile":true,' +
    '"free":%s}', [START_STRUCTURE, DUMMY_CURVE, PERIOD_FREE])));
end;

procedure TTestMCPFit.Period_StartOutsideBounds_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"free":%s,' +
    '"bounds":[{"target":"period","stack":0,"min":70,"max":80}]}',
    [START_STRUCTURE, DUMMY_CURVE, PERIOD_FREE])));
end;

procedure TTestMCPFit.Scale_MultipliesTheMeasuredCurve;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"scale":2.5,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));
  Assert.AreEqual(Double(2.5), Req.Scale, 1E-12, 'scale is kept');
  Assert.AreEqual(Double(2.5), Double(Req.Data[0].r), 1E-6, 'first intensity 1 x 2.5');
  Assert.AreEqual(Double(2.25), Double(Req.Data[1].r), 1E-6, 'second intensity 0.9 x 2.5');
  Assert.AreEqual(Double(0.5), Double(Req.Data[0].t), 1E-9, 'angles untouched');

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));
  Assert.AreEqual(Double(1), Req.Scale, 1E-12, 'default scale is 1');
end;

procedure TTestMCPFit.Scale_NotPositive_Refused;
const
  FMT = '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"scale":%s,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}';
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(FMT, [START_STRUCTURE, DUMMY_CURVE, '0'])));
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(FMT, [START_STRUCTURE, DUMMY_CURVE, '-1'])));
end;

procedure TTestMCPFit.Fit_FreePeriod_MovesThePeriod;
var
  Res: TJSONObject;
  Chi2, Chi2Start, Fitted: Double;
  Modes: TJSONArray;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { with the period held, a start of 60 A stays at 60 A exactly }
  Res := RunFit(7, SyntheticCurveJSON, '', '', 0, 0, START_WRONG_PERIOD);
  try
    Fitted := Res.GetValue<Double>('fitted_structure.stacks[0].layers[0].thickness') +
              Res.GetValue<Double>('fitted_structure.stacks[0].layers[1].thickness');
    Assert.AreEqual(Double(60), Fitted, 1E-3, 'the held period does not move');
    Modes := Res.GetValue('period_mode') as TJSONArray;
    Assert.AreEqual(1, Modes.Count, 'one repeating stack');
    Assert.AreEqual('held', Res.GetValue<string>('period_mode[0].mode'));
    Assert.AreEqual(0, Res.GetValue<Integer>('period_mode[0].stack'));
    Assert.AreEqual(Double(60), Res.GetValue<Double>('period_mode[0].start_A'), 1E-3);
    Assert.AreEqual(Double(60), Res.GetValue<Double>('period_mode[0].fitted_A'), 1E-3);
  finally
    Res.Free;
  end;

  { with the period free it moves towards the true 68.5 A }
  Res := RunFit(7, SyntheticCurveJSON, PERIOD_FREE,
    ',"bounds":[{"target":"period","stack":0,"min":50,"max":80}]',
    PROFILE_POPULATION, PROFILE_ITERATIONS, START_WRONG_PERIOD);
  try
    Chi2 := Res.GetValue<Double>('chi2');
    Chi2Start := Res.GetValue<Double>('chi2_start');
    Assert.IsTrue(Chi2 < Chi2Start, 'the fit improves on the start');
    Fitted := Res.GetValue<Double>('fitted_structure.stacks[0].layers[0].thickness') +
              Res.GetValue<Double>('fitted_structure.stacks[0].layers[1].thickness');
    Assert.IsTrue(Abs(Fitted - 60) > 0.5,
      Format('the period moved away from 60 A (fitted %.3f)', [Fitted]));
    Assert.IsTrue(Abs(Fitted - 68.5) < Abs(60 - 68.5),
      Format('the period moved towards 68.5 A (fitted %.3f)', [Fitted]));
    Assert.IsTrue((Fitted >= 50) and (Fitted <= 80), 'inside its bounds');

    Assert.AreEqual('free', Res.GetValue<string>('period_mode[0].mode'));
    Assert.AreEqual(Double(60), Res.GetValue<Double>('period_mode[0].start_A'), 1E-3);
    Assert.AreEqual(Fitted, Res.GetValue<Double>('period_mode[0].fitted_A'), 1E-3);
    Assert.AreEqual(Double(50), Res.GetValue<Double>('period_mode[0].min'), 1E-9);
    Assert.AreEqual(Double(80), Res.GetValue<Double>('period_mode[0].max'), 1E-9);
    Assert.AreEqual(3, (Res.GetValue('bounds_used') as TJSONArray).Count,
      'two thicknesses and the period are reported');
    Assert.AreEqual('period', Res.GetValue<string>('bounds_used[2].target'));
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Fit_Scale_IsEchoed;
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(7, SyntheticCurveJSON, '', ',"scale":2');
  try
    Assert.AreEqual(Double(2), Res.GetValue<Double>('scale'), 1E-9, 'scale echoed');
    Assert.IsTrue(Res.GetValue<string>('note') <> '', 'the note explains the fixed factor');
    Assert.IsTrue(TFile.Exists(TPath.Combine(FTemp,
      Res.GetValue<string>('files.measured'))), 'measured.dat written');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Fit_OnItsOwnCurve_BeatsTheStartModel;
var
  Res: TJSONObject;
  Chi2, Chi2Start, Chi2Recalc: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(7, SyntheticCurveJSON);
  try
    Assert.IsNotNull(Res, 'the job produced no result');
    Chi2 := Res.GetValue<Double>('chi2');
    Chi2Start := Res.GetValue<Double>('chi2_start');
    Chi2Recalc := Res.GetValue<Double>('chi2_recalc');

    Assert.IsTrue(Chi2 < Chi2Start,
      Format('chi2 %.6g must be below the start model''s %.6g', [Chi2, Chi2Start]));
    Assert.IsTrue(Chi2Start > 0, 'the start model must not already fit');
    Assert.AreEqual(Chi2, Chi2Recalc, Abs(Chi2) * 1E-4 + 1E-12,
      'the fitted structure must re-score as the chi-squared the engine reported');
    Assert.IsNull(Res.FindValue('consistency_warning'),
      'no consistency warning expected');

    Assert.AreEqual(7, Res.GetValue<Integer>('seed'), 'the seed is echoed');
    Assert.AreEqual('TLFPSO_Periodic', Res.GetValue<string>('engine'));
    Assert.AreEqual(FIT_CHI2_DEFINITION, Res.GetValue<string>('chi2_definition'));
    Assert.AreEqual(2, (Res.GetValue('bounds_used') as TJSONArray).Count,
      'both free parameters are reported');

    { the files the result names must be there }
    Assert.IsTrue(TFile.Exists(TPath.Combine(WorkDir.Root,
      Res.GetValue<string>('files.xrcx'))), 'fit.xrcx');
    Assert.IsTrue(TFile.Exists(TPath.Combine(WorkDir.Root,
      Res.GetValue<string>('files.measured'))), 'measured.dat');
    Assert.IsTrue(TFile.Exists(TPath.Combine(WorkDir.Root,
      Res.GetValue<string>('files.calculated'))), 'calc.dat');
    Assert.IsTrue(TFile.Exists(TPath.Combine(WorkDir.Root,
      Res.GetValue<string>('files.residual'))), 'residual.dat');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Fit_SameSeedTwice_GivesTheSameAnswer;
var
  Curve: string;
  A, B: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Curve := SyntheticCurveJSON;
  A := RunFit(7, Curve);
  try
    B := RunFit(7, Curve);
    try
      Assert.AreEqual(A.GetValue<Double>('chi2'), B.GetValue<Double>('chi2'), 0.0,
        'the same seed must give the same chi-squared');
      Assert.AreEqual(A.GetValue<TJSONObject>('fitted_structure').ToJSON,
                      B.GetValue<TJSONObject>('fitted_structure').ToJSON,
        'the same seed must give the same structure');
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
end;

procedure TTestMCPFit.Fit_Cancelled_StopsAndLeavesNoResult;
var
  Mgr: TJobManager;
  Job: TJob;
  Status: TJSONObject;
  SW: TStopwatch;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Mgr := TJobManager.Create(WorkDir);
  try
    { A budget far larger than the test is willing to wait for, so that the run
      can only end because it was asked to. }
    Job := SubmitOn(Mgr, 7, CANCEL_POPULATION, CANCEL_ITERATIONS,
                    SyntheticCurveJSON);

    { Cancel once the engine is really inside Run - the first progress report
      comes after the whole population has been evaluated - so that this
      exercises the callback path rather than the queue. }
    SW := TStopwatch.StartNew;
    while (SW.ElapsedMilliseconds < 60000) and
          not ((Job.State = jsRunning) and (Job.LastMessage <> '')) do
    begin
      if Job.State in [jsFinished, jsFailed, jsCancelled] then
        Break;
      Sleep(20);
    end;
    Assert.AreEqual(JobStateName(jsRunning), JobStateName(Job.State),
      'the fit should still be running when it is cancelled: ' + JobErrorText(Job));

    Status := Mgr.Cancel(Job.Id);
    try
      Assert.IsNotNull(Status, 'cancel_job answers with a status');
    finally
      Status.Free;
    end;

    Assert.IsTrue(WaitForState(Job, jsCancelled, 60000),
      Format('the fit did not stop; it is "%s"', [JobStateName(Job.State)]));
    Assert.IsFalse(Job.HasResult, 'a cancelled fit must leave no result');
    Assert.IsTrue(Job.Iteration < CANCEL_ITERATIONS,
      'the run was cut short, not finished');
  finally
    Mgr.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPFit);

end.
