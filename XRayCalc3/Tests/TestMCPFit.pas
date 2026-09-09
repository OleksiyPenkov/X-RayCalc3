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
    /// <summary>One complete fit through a manager of its own. The result is
    /// the caller's to free; nil when the job did not finish.</summary>
    function RunFit(Seed: Integer; const CurveJSON: string): TJSONObject;
    function WaitForState(Job: TJob; Wanted: TJobState; TimeoutMs: Integer): Boolean;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Free_NoBounds_GivesPlusMinusThirtyPercent;
    [Test] procedure Free_LeavesEveryOtherParameterFixed;
    [Test] procedure Bounds_Explicit_ReplaceTheDefault;
    [Test] procedure Bounds_NegativeMin_ClampedToZeroForSigmaAndDensity;
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

    [Test] procedure Fit_OnItsOwnCurve_BeatsTheStartModel;
    [Test] procedure Fit_SameSeedTwice_GivesTheSameAnswer;
  end;

implementation

uses
  System.IOUtils, System.Classes, System.Diagnostics,
  unit_Config, unit_MCPErrors, unit_MCPCalc;

const
  { The reference sample: a 10-period Ru/C multilayer on Si, the same materials
    the design note's worked example uses. Layers are listed substrate-first. }
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
    Sleep(20);
  end;
  Result := Job.State = Wanted;
end;

function TTestMCPFit.RunFit(Seed: Integer; const CurveJSON: string): TJSONObject;
var
  Args: string;
  Req: TFitRequest;
  Mgr: TJobManager;
  Job: TJob;
  Request: TJSONObject;
begin
  Args := Format(
    '{"structure":%s,"curve":%s,"lambda":%.6f,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]},' +
    '{"target":"layer","stack":0,"layer":1,"parameters":["thickness"]}],' +
    '"optimizer":{"population":%d,"iterations":%d,"tolerance":%g},' +
    '"resolution":0,"points_inline_max":0}',
    [START_STRUCTURE, CurveJSON, CU_K_ALPHA,
     FIT_POPULATION, FIT_ITERATIONS, FIT_TOLERANCE], TFormatSettings.Invariant);

  Req := Parse(Args);

  Mgr := TJobManager.Create(WorkDir);
  try
    Request := TJSONObject.Create;
    try
      Request.AddPair('seed', TJSONNumber.Create(Seed));
      Job := Mgr.Submit(jkFit, Seed,
        procedure(AJob: TJob)
        begin
          RunFitJob(AJob, Req);
        end,
        Request);
    finally
      Request.Free;
    end;

    Assert.IsTrue(WaitForState(Job, jsFinished, 180000),
      'the fit did not finish: ' + JobStateName(Job.State));
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

initialization
  TDUnitX.RegisterTestFixture(TTestMCPFit);

end.
