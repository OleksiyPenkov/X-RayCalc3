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
    FOptimizerExtra: string;   // spliced into SubmitOn's "optimizer" object
    FDeviceOverride: string;   // replaces RunRequest's optimizer.device when set
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
    /// <summary>Copies Tests\Data\P2-02 (xrr.dat + meta.json) into the work
    /// directory's inbox, so a request can name "P2-02/xrr.dat".</summary>
    procedure StageP2Inbox;
    /// <summary>One string value out of fit_xrr's input schema, by its path
    /// under inputSchema.properties (for instance
    /// 'optimizer.properties.population.description'). Fails the test when
    /// fit_xrr is not registered.</summary>
    function FitXrrSchemaValue(const Path: string): string;
    /// <summary>One fit_xrr request exactly as a client sent it - a JSON
    /// literal with "measurement_id" and "seed" - through a manager of its
    /// own. The result is the caller's to free.</summary>
    function RunRequest(const RequestJSON: string): TJSONObject;
    /// <summary>The data of a parser-only request on CurveJSON; Extra is spliced
    /// in verbatim and starts with a comma.</summary>
    function DataOf(const CurveJSON: string; const Extra: string = ''): TDataArray;
    /// <summary>Every fitted value that lies outside the bound the same result
    /// echoes in bounds_used, one per line; '' when the result is clean.</summary>
    function BoundViolations(const Res: TJSONObject): string;
    /// <summary>[[theta, I], ...] of the START structure, every intensity
    /// multiplied by Multiplier, on the grid and with the settings a parse of
    /// it will use. "scale": "auto" must give back 1 / Multiplier.</summary>
    function StartCurveJSON(Multiplier: Double): string;
    /// <summary>Copies Tests\Data\&lt;Specimen&gt; into the work directory's
    /// inbox.</summary>
    procedure StageInbox(const Specimen: string);
    /// <summary>The "report" object of a result, with the test failing when
    /// there is none.</summary>
    function ReportOf(const Res: TJSONObject): TJSONObject;
    /// <summary>The file the result names under "files", read back as JSON.
    /// Caller frees.</summary>
    function ReadResultFile(const Res: TJSONObject; const Key: string): TJSONValue;
    /// <summary>The two-column curve file the result names under Key.</summary>
    function ReadResultCurve(const Res: TJSONObject; const Key: string): TDataArray;
    /// <summary>A profile fit with thickness, sigma and density free and
    /// unpaired in both layers. The result is the caller's to free.</summary>
    function RunUnpairedProfileFit: TJSONObject;
  public
    [Test] procedure Fit_SolvedScale_OnByDefault_ReportsTheMode;
    [Test] procedure Fit_SolvedScale_Off_IsAnchored;
    [Test] procedure Fit_SolvedScale_WindowNegative_Refused;
    [Test] procedure Schema_Has_ScaleSolve;
    [Test] procedure Fit_SolvedScale_ReportReadsTheMeasuredCurveAtIt;
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
    [Test] procedure Bounds_StartOnItsBound_Accepted;
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
    [Test] procedure Smooth_OnePass_EqualsMovAvgFive;
    [Test] procedure Smooth_TwoPasses_EqualTwoApplications;
    [Test] procedure Smooth_ComesAfterScaleAndBeforeTrim;
    [Test] procedure Smooth_ZeroPassesAndAbsent_LeaveTheCurveAlone;
    [Test] procedure Smooth_PassesOutOfRange_Refused;
    [Test] procedure Smooth_CurveShorterThanTheWindow_Refused;
    [Test] procedure Fit_Smooth_IsEchoedAndStoredAsFitted;
    [Test] procedure Fit_ZeroPasses_EqualsNoSmoothArgument;
    [Test] procedure Fit_NoSmooth_MatchesRevision06035de;
    [Test] procedure Schema_DescribesTheManualsDataConditioning;
    [Test] procedure Optimizer_Default_IsTheLabsPractice;

    [Test] procedure Fit_OnItsOwnCurve_BeatsTheStartModel;
    [Test] procedure Fit_PlainChiSquared_IsTheUnweightedSum;
    [Test] procedure Fit_SameSeedTwice_GivesTheSameAnswer;
    [Test] procedure Fit_Cancelled_StopsAndLeavesNoResult;
    [Test] procedure Fit_P2_02_FreePeriod_StaysInsideBounds;
    [Test] procedure SaveProject_FromFitJob_CarriesTheJobsFitSettings;

    [Test] procedure Scale_Auto_RecoversAKnownMultiplier;
    [Test] procedure Scale_Auto_ReportsTheAngleAndTheCounts;
    [Test] procedure Scale_Auto_TakesOnlyTheMaximumBelowAutoThetaMax;
    [Test] procedure Scale_Auto_NoPointBelowAutoThetaMax_Refused;
    [Test] procedure Scale_UnknownString_Refused;
    [Test] procedure ScaleAuto_Boolean_IsTheSameAsTheString;
    [Test] procedure ScaleAuto_True_IgnoresANumericScale;
    [Test] procedure ScaleAuto_False_LeavesTheNumberAlone;
    [Test] procedure Scale_Auto_P2_05_MatchesTheHandComputation;
    [Test] procedure Scale_Auto_IsEchoedInTheResult;

    [Test] procedure Paired_WithoutProfile_Refused;
    [Test] procedure Paired_Global_PairsEveryLayer;
    [Test] procedure Paired_PerLayer_PairsOnlyThatParameter;
    [Test] procedure Paired_NamedTwice_IsOnePairing;
    [Test] procedure Paired_UnknownParameter_Refused;
    [Test] procedure Paired_Absent_LeavesEveryParameterFree;
    [Test] procedure ProfileFit_SigmaAndDensityPaired_HaveNoPolynomial;
    [Test] procedure ProfileFit_UnpairedSigmaAndDensity_ReportTheirProfiles;
    [Test] procedure ProfileFit_UnrolledIntoSinglePeriods_ReproducesTheFit;

    [Test] procedure Device_Default_IsAuto;
    [Test] procedure Device_Unknown_Refused;
    [Test] procedure Device_Cpu_IsEchoedAndUsed;
    [Test] procedure Device_Auto_UsesTheGpuTheServerNames;

    [Test] procedure Report_IsInTheResultAndInTheJobFolder;
    [Test] procedure Report_OrdersAndStart_AreBothThere;
    [Test] procedure Report_WideBounds_LeaveNearBoundsEmpty;
    [Test] procedure Report_ValueDrivenOntoItsBound_IsNamedInNearBounds;

    [Test] procedure Schema_DescribesNormalizeAutoAndPairing;
    [Test] procedure JobWait_IsRegisteredAndNamesTheClientTimeout;
    [Test] procedure Irregular_Mode_IsParsed;
    [Test] procedure Irregular_UnknownMode_Refused;
    [Test] procedure Irregular_ModeAndProfileDisagree_Refused;
    [Test] procedure Irregular_WithoutARepeatingStack_Refused;
    [Test] procedure Irregular_FreePeriod_Refused;
    [Test] procedure Irregular_Paired_PerLayer_IsAccepted;
    [Test] procedure PeriodSmooth_OutsideIrregular_Refused;
    [Test] procedure PeriodSmooth_Window_DefaultAndRange;
    [Test] procedure PeriodSmooth_WindowWithoutSmooth_Refused;
    [Test] procedure StartProfiles_ArraysWithoutTheFlag_Refused;
    [Test] procedure StartProfiles_OutsideIrregular_Refused;
    [Test] procedure StartProfiles_WrongLength_Refused;
    [Test] procedure StartProfiles_OnAPairedParameter_Refused;
    [Test] procedure StartProfiles_PeriodOutsideBounds_Refused;
    [Test] procedure StartProfiles_FillTheTables;
    [Test] procedure Irregular_SameSeedTwice_GivesTheSameAnswer;
    [Test] procedure Irregular_ReportsEveryUnpairedParameterPerPeriod;
    [Test] procedure Irregular_Pairing_ReducesTheFreeValues;
    [Test] procedure Irregular_PairedValueNearItsBound_IsOneEntry;
    [Test] procedure Irregular_UnrolledIntoSinglePeriods_ReproducesTheFit;
    [Test] procedure Irregular_Xrcx_IsAnIrregularProjectWithItsTable;
    [Test] procedure Irregular_SmoothWithEveryParameterPaired_ChangesNothing;
    [Test] procedure Irregular_StartProfiles_ContinueFromAPreviousFit;
    [Test] procedure Schema_DescribesIrregularMode;
  end;

implementation

uses
  System.IOUtils, System.Classes, System.Diagnostics, System.Math,
  System.Zip, System.IniFiles, unit_MCPTools, unit_ToolsFiles,
  unit_Config, unit_MCPErrors, unit_MCPCalc, unit_MCPProjectFile,
  unit_DataProcessing, unit_ToolsJobs, unit_gpu_calc;

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

  { StartCurveJSON writes the curve with JSONArgs.NumArr's 6 significant
    digits, so a scale taken from it is good to half a unit in the sixth digit
    (5E-6 relative) and no better: 5E-9 on 0.001. }
  SCALE_TOL = 5E-9;

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

  { A curve whose largest point is at 1.0 deg and whose largest point below
    0.5 deg is at 0.4: what "scale": "auto" takes depends on auto_theta_max. }
  RISING_CURVE =
    '[[0.2,0.2],[0.3,0.3],[0.4,0.4],[0.5,0.35],[0.6,0.3],[0.7,0.5],' +
    '[0.8,0.6],[0.9,0.8],[1.0,1.0],[1.1,0.7],[1.2,0.4],[1.3,0.2]]';

  { The start model of the P2-05 fit of 2026-09-18 (job fit-20260918-170706-196b):
    a 20-period C/Co mirror on oxidised silicon, as the request.json of that job
    holds it. }
  P2_05_START =
    '{"substrate":{"material":"SiO2","sigma":3.8,"density":2.65},' +
    '"stacks":[{"N":20,"layers":[' +
    '{"material":"C","thickness":33,"sigma":5,"density":2},' +
    '{"material":"Co","thickness":17,"sigma":5,"density":8}]}]}';

  { Twelve points that zigzag, so that a moving average visibly changes every
    inner one. For the smoothing tests of the parser; never fitted. }
  NOISY_CURVE =
    '[[0.30,1.0],[0.35,0.5],[0.40,0.9],[0.45,0.2],[0.50,0.6],[0.55,0.1],' +
    '[0.60,0.4],[0.65,0.05],[0.70,0.3],[0.75,0.02],[0.80,0.2],[0.85,0.01]]';

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

  { The four fit_xrr requests of the paper-2 agent session of 2026-09-16 whose
    results carried values outside bounds_used (registered binary 02e7b63):
    docs\superpowers\specs\2026-09-16-fit-bounds-defect.md. A 20-period C/Co
    mirror on the P2-02 curve (Tests\Data\P2-02, 2theta 0.5..3.6 deg of the
    scan), the period free, every layer parameter free with tight bounds.
    Verbatim, seed included: the same seed reproduces the same swarm. }
  P2_FREE =
    '[{"target":"period","stack":0},' +
    '{"stack":0,"layer":0,"parameters":["thickness","sigma","density"]},' +
    '{"stack":0,"layer":1,"parameters":["thickness","sigma","density"]}]';
  P2_REQUEST_E49E =
    '{"measurement_id":"P2-02/xrr.dat","structure":{"substrate":{"material":"SiO2","sigma":5},' +
    '"stacks":[{"N":20,"layers":[{"material":"C","thickness":25,"sigma":6,"density":2.1},' +
    '{"material":"Co","thickness":2.5,"sigma":6,"density":5}]}]},"free":' + P2_FREE + ',' +
    '"bounds":[{"target":"period","stack":0,"min":26,"max":29.5},' +
    '{"stack":0,"layer":0,"parameter":"thickness","min":15,"max":28.5},' +
    '{"stack":0,"layer":0,"parameter":"sigma","min":1,"max":15},' +
    '{"stack":0,"layer":0,"parameter":"density","min":1.6,"max":3.2},' +
    '{"stack":0,"layer":1,"parameter":"thickness","min":0.2,"max":12},' +
    '{"stack":0,"layer":1,"parameter":"sigma","min":1,"max":15},' +
    '{"stack":0,"layer":1,"parameter":"density","min":2,"max":8.8}],' +
    '"theta_range":{"min":0.3,"max":1.72},"scale":5.5e-7,"resolution":0.015,' +
    '"chi2":{"theta_weight":1,"point_weight":true},' +
    '"optimizer":{"iterations":400,"population":250},"points_inline_max":0,"seed":910003}';
  P2_REQUEST_1763 =
    '{"measurement_id":"P2-02/xrr.dat","structure":{"substrate":{"material":"SiO2","sigma":5},' +
    '"stacks":[{"N":20,"layers":[{"material":"C","thickness":21.4,"sigma":9,"density":2.1},' +
    '{"material":"Co","thickness":6.2,"sigma":9,"density":8.4}]}]},"free":' + P2_FREE + ',' +
    '"bounds":[{"target":"period","stack":0,"min":26.8,"max":28.4},' +
    '{"stack":0,"layer":0,"parameter":"thickness","min":16,"max":25},' +
    '{"stack":0,"layer":0,"parameter":"sigma","min":4,"max":14},' +
    '{"stack":0,"layer":0,"parameter":"density","min":1.8,"max":2.6},' +
    '{"stack":0,"layer":1,"parameter":"thickness","min":3,"max":11},' +
    '{"stack":0,"layer":1,"parameter":"sigma","min":4,"max":14},' +
    '{"stack":0,"layer":1,"parameter":"density","min":6,"max":8.8}],' +
    '"theta_range":{"min":1.35,"max":1.72},"scale":5.5e-7,"resolution":0.015,' +
    '"chi2":{"theta_weight":0,"point_weight":true},' +
    '"optimizer":{"iterations":400,"population":250},"points_inline_max":0,"seed":930002}';
  P2_REQUEST_F2D6 =
    '{"measurement_id":"P2-02/xrr.dat","structure":{"substrate":{"material":"SiO2","sigma":5},' +
    '"stacks":[{"N":20,"layers":[{"material":"C","thickness":25.97,"sigma":3.8,"density":2.35},' +
    '{"material":"Co","thickness":1.66,"sigma":4.6,"density":5.8}]}]},"free":' + P2_FREE + ',' +
    '"bounds":[{"target":"period","stack":0,"min":27,"max":28.2},' +
    '{"stack":0,"layer":0,"parameter":"thickness","min":18,"max":27},' +
    '{"stack":0,"layer":0,"parameter":"sigma","min":1,"max":12},' +
    '{"stack":0,"layer":0,"parameter":"density","min":1.8,"max":2.8},' +
    '{"stack":0,"layer":1,"parameter":"thickness","min":0.5,"max":8},' +
    '{"stack":0,"layer":1,"parameter":"sigma","min":1,"max":12},' +
    '{"stack":0,"layer":1,"parameter":"density","min":3,"max":8.8}],' +
    '"theta_range":{"min":0.3,"max":1.72},"scale":5.5e-7,"resolution":0.015,' +
    '"chi2":{"theta_weight":1,"point_weight":true},' +
    '"optimizer":{"iterations":300,"population":150,"range_seed":false,"ksxr":0.15},' +
    '"points_inline_max":0,"seed":940001}';
  P2_REQUEST_C3D5 =
    '{"scale_solve":false,"measurement_id":"P2-02/xrr.dat","structure":{"substrate":{"material":"SiO2","sigma":5},' +
    '"stacks":[{"N":20,"layers":[{"material":"C","thickness":24.78,"sigma":10.3,"density":2.6},' +
    '{"material":"Co","thickness":3,"sigma":8.2,"density":8.8}]}]},"free":' + P2_FREE + ',' +
    '"bounds":[{"target":"period","stack":0,"min":27.5,"max":28.1},' +
    '{"stack":0,"layer":0,"parameter":"thickness","min":24,"max":25.6},' +
    '{"stack":0,"layer":0,"parameter":"sigma","min":9.2,"max":11.4},' +
    '{"stack":0,"layer":0,"parameter":"density","min":2.4,"max":2.75},' +
    '{"stack":0,"layer":1,"parameter":"thickness","min":2.4,"max":3.6},' +
    '{"stack":0,"layer":1,"parameter":"sigma","min":7.6,"max":8.8},' +
    '{"stack":0,"layer":1,"parameter":"density","min":8.2,"max":8.9}],' +
    '"theta_range":{"min":0.3,"max":1.72},"scale":5.5e-7,"resolution":0.015,' +
    '"chi2":{"theta_weight":1,"point_weight":true},' +
    '"optimizer":{"iterations":150,"population":100,"range_seed":false,"ksxr":0.1},' +
    '"points_inline_max":0,"seed":950002}';
  P2_JOBS: array [0 .. 3] of string = ('e49e', '1763', 'f2d6', 'c3d5');

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
    '"optimizer":{"population":%d,"iterations":%d,"tolerance":%g%s},' +
    '"resolution":0,"points_inline_max":0%s}',
    [Start, CurveJSON, CU_K_ALPHA, FreeList, Population, Iterations,
     FIT_TOLERANCE, FOptimizerExtra, Extra], TFormatSettings.Invariant);

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

function TTestMCPFit.FitXrrSchemaValue(const Path: string): string;
var
  Reg: TToolRegistry;
  Tools: TJSONArray;
  Props: TJSONObject;
  i: Integer;
begin
  Props := nil;
  Reg := TToolRegistry.Create;
  try
    RegisterJobTools(Reg);
    Tools := Reg.GetToolsList;
    try
      for i := 0 to Tools.Count - 1 do
        if Tools.Items[i].GetValue<string>('name') = 'fit_xrr' then
          Props := Tools.Items[i].GetValue<TJSONObject>('inputSchema.properties');
      Assert.IsNotNull(Props, 'fit_xrr is registered');
      Result := Props.GetValue<string>(Path);
    finally
      Tools.Free;
    end;
  finally
    Reg.Free;
  end;
end;

procedure TTestMCPFit.StageInbox(const Specimen: string);
var
  Src, Dst: string;
begin
  Src := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    '..\..\Data\' + Specimen));
  Assert.IsTrue(TDirectory.Exists(Src), 'missing test asset: ' + Src);
  Dst := TPath.Combine(TPath.Combine(FTemp, 'inbox'), Specimen);
  TDirectory.CreateDirectory(Dst);
  TFile.Copy(TPath.Combine(Src, 'xrr.dat'), TPath.Combine(Dst, 'xrr.dat'));
  TFile.Copy(TPath.Combine(Src, 'meta.json'), TPath.Combine(Dst, 'meta.json'));
end;

procedure TTestMCPFit.StageP2Inbox;
begin
  StageInbox('P2-02');
end;

function TTestMCPFit.StartCurveJSON(Multiplier: Double): string;
var
  Req: TCalcRequest;
  Used: TFitStructure;
  Curve: TDataArray;
  J: TJSONObject;
  Arr: TJSONArray;
  i: Integer;
begin
  Req := Default(TCalcRequest);
  J := TJSONObject.ParseJSONValue(START_STRUCTURE) as TJSONObject;
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
      Arr.AddElement(JSONArgs.NumArr(
        TArray<Double>.Create(Curve[i].t, Curve[i].r * Multiplier)));
    Result := Arr.ToJSON;
  finally
    Arr.Free;
  end;
end;

function TTestMCPFit.ReportOf(const Res: TJSONObject): TJSONObject;
begin
  Assert.IsTrue(Res.GetValue('report') is TJSONObject,
    'every fit result carries a "report" object');
  Result := Res.GetValue('report') as TJSONObject;
end;

function TTestMCPFit.ReadResultFile(const Res: TJSONObject;
  const Key: string): TJSONValue;
var
  Rel, Full: string;
begin
  Rel := (Res.GetValue('files') as TJSONObject).GetValue<string>(Key);
  Full := TPath.Combine(FTemp, Rel);
  Assert.IsTrue(TFile.Exists(Full), 'the job folder holds ' + Rel);
  Result := TJSONObject.ParseJSONValue(TFile.ReadAllText(Full));
  Assert.IsNotNull(Result, Rel + ' is JSON');
end;

function TTestMCPFit.ReadResultCurve(const Res: TJSONObject;
  const Key: string): TDataArray;
var
  Lines, Cols: TArray<string>;
  i, n: Integer;
  Full: string;
begin
  Full := TPath.Combine(FTemp,
    (Res.GetValue('files') as TJSONObject).GetValue<string>(Key));
  Assert.IsTrue(TFile.Exists(Full), 'the job folder holds ' + Full);
  Lines := TFile.ReadAllLines(Full);
  SetLength(Result, Length(Lines));
  n := 0;
  for i := 1 to High(Lines) do           // line 0 is the column header
  begin
    Cols := Lines[i].Split([#9]);
    if Length(Cols) < 2 then
      Continue;
    Result[n].t := StrToFloat(Cols[0], TFormatSettings.Invariant);
    Result[n].r := StrToFloat(Cols[1], TFormatSettings.Invariant);
    Inc(n);
  end;
  SetLength(Result, n);
end;

function TTestMCPFit.RunRequest(const RequestJSON: string): TJSONObject;
var
  J: TJSONObject;
  Req: TFitRequest;
  Seed: Integer;
  Mgr: TJobManager;
  Job: TJob;
begin
  J := TJSONObject.ParseJSONValue(RequestJSON) as TJSONObject;
  Assert.IsNotNull(J, 'the request does not parse as JSON');
  try
    Seed := J.GetValue<Integer>('seed');
    Req := ParseFitRequest(J);
    if FDeviceOverride <> '' then
      Req.Device := FDeviceOverride;
    Mgr := TJobManager.Create(WorkDir);
    try
      Job := Mgr.Submit(jkFit, Seed,
        procedure(AJob: TJob)
        begin
          RunFitJob(AJob, Req);
        end,
        J);
      if not WaitForState(Job, jsFinished, 600000) then
        Assert.Fail(Format('the fit ended as "%s": %s',
          [JobStateName(Job.State), JobErrorText(Job)]));
      Result := Job.CloneResult;
    finally
      Mgr.Free;
    end;
  finally
    J.Free;
  end;
end;

function TTestMCPFit.BoundViolations(const Res: TJSONObject): string;
var
  Bounds, Modes: TJSONArray;
  B, M: TJSONObject;
  i, k, Stack: Integer;
  Lo, Hi, V, Tol: Double;
  Target, Param, Where: string;
begin
  Result := '';
  Bounds := Res.GetValue('bounds_used') as TJSONArray;
  Modes := Res.GetValue('period_mode') as TJSONArray;
  for i := 0 to Bounds.Count - 1 do
  begin
    B := Bounds.Items[i] as TJSONObject;
    Target := B.GetValue<string>('target');
    Param := B.GetValue<string>('parameter');
    Stack := B.GetValue<Integer>('stack');
    Lo := B.GetValue<Double>('min');
    Hi := B.GetValue<Double>('max');
    if Target = 'period' then
    begin
      V := 0;
      Where := Format('period of stack %d', [Stack]);
      for k := 0 to Modes.Count - 1 do
      begin
        M := Modes.Items[k] as TJSONObject;
        if M.GetValue<Integer>('stack') = Stack then
          V := M.GetValue<Double>('fitted_A');
      end;
    end
    else
    begin
      Where := Format('stack %d layer %d %s', [Stack, B.GetValue<Integer>('layer'), Param]);
      V := Res.GetValue<Double>(Format('fitted_structure.stacks[%d].layers[%d].%s',
        [Stack, B.GetValue<Integer>('layer'), Param]));
    end;
    { the engine works in single precision and the result prints 6 digits }
    Tol := 1E-5 * Max(1.0, Max(Abs(Lo), Abs(Hi)));
    if (V < Lo - Tol) or (V > Hi + Tol) then
      Result := Result + Format('%s = %.6g outside [%.6g, %.6g]'#13#10,
        [Where, V, Lo, Hi], TFormatSettings.Invariant);
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

{ ------------------------------------------------------------------ smooth -- }

function TTestMCPFit.DataOf(const CurveJSON, Extra: string): TDataArray;
begin
  Result := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]%s}',
    [START_STRUCTURE, CurveJSON, Extra])).Data;
end;

procedure AssertSameCurve(const Expected, Actual: TDataArray; const What: string);
var
  i: Integer;
begin
  Assert.AreEqual(Length(Expected), Length(Actual), What + ': number of points');
  for i := 0 to High(Expected) do
  begin
    Assert.IsTrue(Expected[i].t = Actual[i].t, What + Format(': theta of point %d', [i]));
    Assert.IsTrue(Expected[i].r = Actual[i].r,
      What + Format(': intensity of point %d is %g, expected %g',
                    [i, Actual[i].r, Expected[i].r]));
  end;
end;

{ One pass is one click of the GUI's Data - Smooth, which is MovAvg(Data, 5)
  (TfrmChartInfo.SmoothData): the same function, so the same numbers. }
procedure TTestMCPFit.Smooth_OnePass_EqualsMovAvgFive;
var
  Raw, Smoothed, Data: TDataArray;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Raw := DataOf(NOISY_CURVE);
  Smoothed := DataOf(NOISY_CURVE, ',"smooth":{"passes":1}');
  AssertSameCurve(MovAvg(Raw, 5), Smoothed, 'one pass');

  { The GUI writes the call as Data := MovAvg(Data, 5), input and result in one
    local. Should a compiler ever hand MovAvg that local as its Result, the
    filter would run in place over values it has already replaced and the GUI
    would no longer do what the server does. Checked on dcc32 and dcc64 of
    Studio 37.0, optimization on and off, 2026-09-17: it does not. }
  Data := Copy(Raw);
  Data := MovAvg(Data, 5);
  AssertSameCurve(Data, Smoothed, 'the call form of TfrmChartInfo.SmoothData');
  Assert.IsTrue(Raw[5].r <> Smoothed[5].r, 'an inner point really moved');
end;

procedure TTestMCPFit.Smooth_TwoPasses_EqualTwoApplications;
var
  Raw: TDataArray;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Raw := DataOf(NOISY_CURVE);
  AssertSameCurve(MovAvg(MovAvg(Raw, 5), 5),
    DataOf(NOISY_CURVE, ',"smooth":{"passes":2}'), 'two passes');
end;

{ The manual's order: normalize, smooth the whole curve, trim. Trimming first
  would hand MovAvg a curve whose first three points it copies unchanged, so the
  first kept point tells the two orders apart. }
procedure TTestMCPFit.Smooth_ComesAfterScaleAndBeforeTrim;
var
  Whole, Kept, Got: TDataArray;
  i, n: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Whole := DataOf(NOISY_CURVE);
  for i := 0 to High(Whole) do
    Whole[i].r := Whole[i].r * 2.0;
  Whole := MovAvg(Whole, 5);

  { 0.44 .. 0.71 keeps the six points 0.45 .. 0.70, indices 3 .. 8 }
  SetLength(Kept, 6);
  for n := 0 to 5 do
    Kept[n] := Whole[n + 3];

  Got := DataOf(NOISY_CURVE,
    ',"scale":2,"smooth":{"passes":1},"theta_range":{"min":0.44,"max":0.71}');
  AssertSameCurve(Kept, Got, 'scale, smooth, trim');
  Assert.IsTrue(Abs(Got[0].r - 0.4) > 1E-3,
    'the first kept point is smoothed, not copied as a curve edge would be');
end;

procedure TTestMCPFit.Smooth_ZeroPassesAndAbsent_LeaveTheCurveAlone;
var
  Raw: TDataArray;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Raw := DataOf(NOISY_CURVE);
  Assert.AreEqual(Double(0.1), Double(Raw[5].r), 1E-7, 'no "smooth": the curve as given');
  AssertSameCurve(Raw, DataOf(NOISY_CURVE, ',"smooth":{"passes":0}'), 'passes 0');
  AssertSameCurve(Raw, DataOf(NOISY_CURVE, ',"smooth":{}'), 'empty smooth');
end;

procedure TTestMCPFit.Smooth_PassesOutOfRange_Refused;
const
  FMT = '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"smooth":%s,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}';
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument',
    ErrorCodeOf(Format(FMT, [START_STRUCTURE, NOISY_CURVE, '{"passes":-1}'])), 'negative');
  Assert.AreEqual('invalid_argument',
    ErrorCodeOf(Format(FMT, [START_STRUCTURE, NOISY_CURVE, '{"passes":11}'])), 'above the cap');
  Assert.AreEqual('invalid_argument',
    ErrorCodeOf(Format(FMT, [START_STRUCTURE, NOISY_CURVE, '{"passes":1.5}'])), 'not a whole number');
  Assert.AreEqual('',
    ErrorCodeOf(Format(FMT, [START_STRUCTURE, NOISY_CURVE, '{"passes":10}'])), 'the cap itself');
end;

{ MovAvg(Data, 5) averages six points and writes zeros over the tail of a curve
  that has no six, which the log10 of the chi-squared cannot take. }
procedure TTestMCPFit.Smooth_CurveShorterThanTheWindow_Refused;
const
  FIVE = '[[0.5,1],[0.6,0.9],[0.7,0.8],[0.8,0.7],[0.9,0.6]]';
  FMT = '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0%s,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}';
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument',
    ErrorCodeOf(Format(FMT, [START_STRUCTURE, FIVE, ',"smooth":{"passes":1}'])));
  Assert.AreEqual('', ErrorCodeOf(Format(FMT, [START_STRUCTURE, FIVE, ''])),
    'the same curve is fine without smoothing');
  Assert.AreEqual('',
    ErrorCodeOf(Format(FMT, [START_STRUCTURE, DUMMY_CURVE, ',"smooth":{"passes":1}'])),
    'six points are enough');
end;

{ What was fitted is what is stored: measured.dat, the data node of fit.xrcx and
  the project save_project builds from the job all hold the smoothed curve. }
procedure TTestMCPFit.Fit_Smooth_IsEchoedAndStoredAsFitted;

  procedure SameAsFitted(const Expected, Stored: TDataArray; const What: string);
  var
    i: Integer;
  begin
    Assert.AreEqual(Length(Expected), Length(Stored), What + ': number of points');
    for i := 0 to High(Expected) do
      Assert.AreEqual(Double(Expected[i].r), Double(Stored[i].r),
        Abs(Expected[i].r) * 1E-6, What + Format(': intensity of point %d', [i]));
  end;

var
  Curve, JobId, ProjectFile: string;
  Expected: TDataArray;
  Res, Args, Saved: TJSONObject;
  Reg: TToolRegistry;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Curve := SyntheticCurveJSON;
  Expected := MovAvg(DataOf(Curve), 5);

  Res := RunFit(7, Curve, '', ',"smooth":{"passes":1}');
  try
    Assert.AreEqual(1, Res.GetValue<Integer>('smooth.passes'), 'passes echoed');
    Assert.AreEqual(5, Res.GetValue<Integer>('smooth.window'), 'window echoed');
    JobId := Res.GetValue<string>('job_id');
    SameAsFitted(Expected, ReadCurveText(TPath.Combine(WorkDir.Root,
      Res.GetValue<string>('files.measured'))), 'measured.dat');
    SameAsFitted(Expected, ReadXRCX(TPath.Combine(WorkDir.Root,
      Res.GetValue<string>('files.xrcx'))).DataCurve, 'fit.xrcx');
  finally
    Res.Free;
  end;

  Args := TJSONObject.ParseJSONValue(Format(
    '{"structure":%s,"name":"saved_smooth","curves":{"job_id":"%s"}}',
    [START_STRUCTURE, JobId])) as TJSONObject;
  try
    Reg := TToolRegistry.Create;
    try
      RegisterFileTools(Reg);
      Saved := Reg.Execute('save_project', Args);
      try
        ProjectFile := TPath.Combine(WorkDir.Root, Saved.GetValue<string>('file'));
      finally
        Saved.Free;
      end;
    finally
      Reg.Free;
    end;
  finally
    Args.Free;
  end;
  SameAsFitted(Expected, ReadXRCX(ProjectFile).DataCurve, 'save_project');
end;

procedure TTestMCPFit.Fit_ZeroPasses_EqualsNoSmoothArgument;
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
    B := RunFit(7, Curve, '', ',"smooth":{"passes":0}');
    try
      Assert.AreEqual(A.GetValue('chi2').ToJSON, B.GetValue('chi2').ToJSON, 'chi2');
      Assert.AreEqual(A.GetValue('fitted_structure').ToJSON,
                      B.GetValue('fitted_structure').ToJSON, 'fitted structure');
      Assert.AreEqual(0, B.GetValue<Integer>('smooth.passes'), 'echoed as off');
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
end;

{ Smoothing is off by default, and off means the fit of revision 06035de: the
  numbers below are what that revision answers (captured 2026-09-17, before
  "smooth" existed) to the synthetic fit with seed 7, 12 x 8, and to the
  paper-2 request c3d5 on the measured P2-02 curve, which is scaled, trimmed,
  noisy and does not end on a round answer. Those are the CPU engine's
  answers, so both fits run with optimizer.device "cpu": the GPU (3.9.0)
  minimises the same chi-squared to single precision and takes a different
  path through the swarm.

  The P2-02 numbers were recaptured for 3.9.4: the chi-squared now sums the
  last measured point as well (it was dropped whether or not there was a
  convolution) and the resolution kernel is normalised, which moved that
  fit's chi2 from 2.16926 to 2.17153 and its layers in the fourth digit.
  The synthetic fit, which has no resolution and whose last point carries no
  residual, is unchanged. 3.9.4 also sets the roughness exponent to exactly
  sigma^2 s^2 / 2 (it was 0.50299): the synthetic chi2 went from 0.000413109
  to 0.000413763 on the same structure, and P2-02 from 2.17153 to 2.16063,
  its sigmas up by 0.14 and 0.18 %. A number published before 3.9.4 reproduces on the
  binary it was made with (D:\SoftwareStorage\X-RayCalc3\Releases), not on
  this source. }
procedure TTestMCPFit.Fit_NoSmooth_MatchesRevision06035de;
const
  CHI2_06035DE = '0.000413763';
  FITTED_06035DE =
    '{"substrate":{"material":"Si","sigma":3,"density":2.332},"stacks":[{"N":10,' +
    '"layers":[{"material":"C","thickness":53.8002,"sigma":3,"density":2.266},' +
    '{"material":"Ru","thickness":14.6998,"sigma":3,"density":12.437}]}]}';
  P2_CHI2_06035DE = '2.16063';
  P2_FITTED_06035DE =
    '{"substrate":{"material":"SiO2","sigma":5,"density":2.65},"stacks":[{"N":20,' +
    '"layers":[{"material":"C","thickness":25.3859,"sigma":9.88615,"density":2.74231},' +
    '{"material":"Co","thickness":2.40004,"sigma":7.81322,"density":8.89935}]}]}';
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  FOptimizerExtra := ',"device":"cpu"';
  try
    Res := RunFit(7, SyntheticCurveJSON, '', ',"scale_solve":false');
  finally
    FOptimizerExtra := '';
  end;
  try
    Assert.AreEqual(CHI2_06035DE, Res.GetValue('chi2').ToJSON, 'chi2');
    Assert.AreEqual(FITTED_06035DE, Res.GetValue('fitted_structure').ToJSON,
      'fitted structure');
  finally
    Res.Free;
  end;

  if not TFile.Exists(HenkePath + 'Co.bin') or
     not TFile.Exists(HenkePath + 'SiO2.bin') then
    Exit;
  StageP2Inbox;
  FDeviceOverride := 'cpu';
  try
    Res := RunRequest(P2_REQUEST_C3D5);
  finally
    FDeviceOverride := '';
  end;
  try
    Assert.AreEqual(P2_CHI2_06035DE, Res.GetValue('chi2').ToJSON, 'P2-02 chi2');
    Assert.AreEqual(P2_FITTED_06035DE, Res.GetValue('fitted_structure').ToJSON,
      'P2-02 fitted structure');
  finally
    Res.Free;
  end;
end;

{ The tool text is what an agent follows. The manual normalizes by comparing
  the measured with the calculated curve at about 0.4 degrees, not to the
  total-reflection plateau: the paper-2 agent read "plateau" here and set every
  scale to 0.96 / max count, which the author rejected (2026-09-17). }
procedure TTestMCPFit.Schema_DescribesTheManualsDataConditioning;
var
  Scale: string;
begin
  { Until 2026-09-18 this said the opposite: compare the two curves at about
    theta 0.4 deg and do not normalise to the total-reflection region. That is
    not what the laboratory does - Data - Normalize Auto sets the measured
    maximum of the plateau equal to the model there - and the skill had to talk
    the agent out of the tool's own description. }
  Scale := FitXrrSchemaValue('scale.description');
  Assert.IsTrue(Scale.Contains('normalize'), 'scale: the step of the manual');
  Assert.IsTrue(Scale.Contains('scale_auto'),
    'scale: where to go to have the server choose the number');
  Assert.IsTrue(
    FitXrrSchemaValue('scale_auto.description').Contains('start model'),
    'scale_auto: what the measured maximum is set equal to');
  Assert.IsFalse(Scale.Contains('0.4 '), 'scale: not "at about 0.4 deg"');

  Assert.AreEqual('integer', FitXrrSchemaValue('smooth.properties.passes.type'),
    'smooth.passes');
  Assert.IsTrue(FitXrrSchemaValue('smooth.description').Contains('Data - Smooth'),
    'smooth names the GUI command it repeats');

  Assert.IsTrue(
    FitXrrSchemaValue('chi2.properties.movavg_window.description').Contains('"smooth"'),
    'movavg_window says it is not the smoothing of the fitted curve');
end;

{ The lab fits with 100 iterations and 500 to 1000 particles - "population
  wins iterations" (author, 2026-09-17) - so that is what a request that says
  nothing gets, and what the schema tells an agent that wants to choose. The
  schema half needs no Henke tables, so it runs on every machine; only the
  parse half is behind the guard. }
procedure TTestMCPFit.Optimizer_Default_IsTheLabsPractice;
var
  Req: TFitRequest;
  Population, Optimizer: string;
begin
  Population := FitXrrSchemaValue('optimizer.properties.population.description');
  Assert.IsTrue(Population.Contains('500'), 'population: the default');
  Assert.IsTrue(Population.Contains('1000'), 'population: the practice reaches 1000');
  Assert.IsFalse(Population.Contains(' s per iteration'),
    'population: no machine-specific timing baked into the schema');
  Assert.IsTrue(Population.Contains('elapsed_s'),
    'population: the cost is read off the result');
  Assert.IsTrue(
    FitXrrSchemaValue('optimizer.properties.iterations.description').Contains('population'),
    'iterations: raise the population first');

  { The GUI's own default population is 1000 (frame_CalcSettings), so the
    schema must not send an agent there for the defaults. }
  Optimizer := FitXrrSchemaValue('optimizer.description');
  Assert.IsTrue(Optimizer.Contains('not the GUI''s'),
    'optimizer: says the defaults are not the GUI''s');
  Assert.IsTrue(Optimizer.Contains('optimizer_used'),
    'optimizer: says where the effective values are echoed');

  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));
  Assert.AreEqual(500, Req.Fit.Pop, 'default population');
  Assert.AreEqual(100, Req.Fit.NMax, 'default iterations');
end;

procedure TTestMCPFit.Fit_OnItsOwnCurve_BeatsTheStartModel;
var
  Res: TJSONObject;
  Chi2, Chi2Start, Chi2Recalc: Double;
  Chi2Plain, Chi2StartPlain: Double;
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
    Assert.AreEqual(FIT_CHI2_PLAIN_DEFINITION,
      Res.GetValue<string>('chi2_plain_definition'));

    { The unweighted sum beside each weighted one. The defaults leave the peak
      weight on and the angle weight off, and the peak weight only ever
      multiplies a point by more than 1, so the plain sum cannot be the larger
      of the two. }
    Chi2Plain := Res.GetValue<Double>('chi2_plain');
    Chi2StartPlain := Res.GetValue<Double>('chi2_start_plain');
    Assert.IsTrue(Chi2Plain > 0, 'chi2_plain must be a real sum');
    Assert.IsTrue(Chi2StartPlain > 0, 'chi2_start_plain must be a real sum');
    Assert.IsTrue(Chi2Plain <= Chi2Recalc * (1 + 1E-6),
      Format('chi2_plain %.6g cannot exceed the peak-weighted %.6g',
             [Chi2Plain, Chi2Recalc]));
    Assert.AreEqual(Chi2Plain, Res.GetValue<Double>('report.chi2_plain'), 1E-12,
      'the report repeats chi2_plain');
    Assert.AreEqual(Chi2StartPlain,
      Res.GetValue<Double>('report.chi2_start_plain'), 1E-12,
      'the report repeats chi2_start_plain');
    { the optimizer that ran, defaults filled in, so a job that named no
      population is reproducible from its result alone }
    Assert.AreEqual(FIT_POPULATION, Res.GetValue<Integer>('optimizer_used.population'),
      'optimizer_used.population');
    Assert.AreEqual(FIT_ITERATIONS, Res.GetValue<Integer>('optimizer_used.iterations'),
      'optimizer_used.iterations');
    Assert.AreEqual(Double(FIT_TOLERANCE),
      Res.GetValue<Double>('optimizer_used.tolerance'), FIT_TOLERANCE * 1E-3,
      'optimizer_used.tolerance is the one the request sent (through a Single)');
    Assert.IsTrue(Res.GetValue<Boolean>('optimizer_used.use_constriction'),
      'optimizer_used.use_constriction is the default the request left alone');
    Assert.AreEqual(Double(DEF_K_CHI), Res.GetValue<Double>('optimizer_used.k_chi'), 1E-9,
      'optimizer_used.k_chi is the default the request left alone');
    Assert.AreEqual(2, (Res.GetValue('bounds_used') as TJSONArray).Count,
      'both free parameters are reported');
    Assert.IsTrue(Res.GetValue('out_of_bounds') is TJSONArray,
      'out_of_bounds is always present');
    Assert.AreEqual(0, (Res.GetValue('out_of_bounds') as TJSONArray).Count,
      'a fit inside its bounds lists no violation');

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


{ With no weight asked for, the weighted sum and the plain one are the same
  arithmetic, so fit_xrr must report the same number twice. That is the check
  that chi2_plain really is chi2 with the weights removed, and not some other
  residual. }
procedure TTestMCPFit.Fit_PlainChiSquared_IsTheUnweightedSum;
var
  Res: TJSONObject;
  Chi2Recalc, Chi2Plain, Chi2Start, Chi2StartPlain: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(7, SyntheticCurveJSON, '',
                ',"chi2":{"theta_weight":0,"point_weight":false}');
  try
    Assert.IsNotNull(Res, 'the job produced no result');
    Chi2Recalc := Res.GetValue<Double>('chi2_recalc');
    Chi2Plain := Res.GetValue<Double>('chi2_plain');
    Chi2Start := Res.GetValue<Double>('chi2_start');
    Chi2StartPlain := Res.GetValue<Double>('chi2_start_plain');

    Assert.AreEqual(Chi2Recalc, Chi2Plain, Abs(Chi2Recalc) * 1E-6 + 1E-12,
      Format('unweighted, chi2_recalc %.9g and chi2_plain %.9g are one sum',
             [Chi2Recalc, Chi2Plain]));
    Assert.AreEqual(Chi2Start, Chi2StartPlain, Abs(Chi2Start) * 1E-6 + 1E-12,
      Format('unweighted, chi2_start %.9g and chi2_start_plain %.9g are one sum',
             [Chi2Start, Chi2StartPlain]));
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

procedure TTestMCPFit.Fit_P2_02_FreePeriod_StaysInsideBounds;
const
  Requests: array [0 .. 3] of string =
    (P2_REQUEST_E49E, P2_REQUEST_1763, P2_REQUEST_F2D6, P2_REQUEST_C3D5);
var
  n: Integer;
  Res: TJSONObject;
  Violations, Report: string;
  Listed: TJSONArray;
begin
  if not HenkeTablesPresent or
     not TFile.Exists(HenkePath + 'Co.bin') or
     not TFile.Exists(HenkePath + 'SiO2.bin') then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  StageP2Inbox;
  Report := '';
  for n := 0 to High(Requests) do
  begin
    Res := RunRequest(Requests[n]);
    try
      Assert.AreEqual(Res.GetValue<Double>('chi2'), Res.GetValue<Double>('chi2_recalc'),
        Abs(Res.GetValue<Double>('chi2')) * 1E-4 + 1E-12,
        'job ' + P2_JOBS[n] + ': chi2_recalc must equal chi2');
      Violations := BoundViolations(Res);
      if Violations <> '' then
        Report := Report + 'job ' + P2_JOBS[n] + ':'#13#10 + Violations;
      Listed := Res.GetValue('out_of_bounds') as TJSONArray;
      if Listed = nil then
        Report := Report + 'job ' + P2_JOBS[n] + ': no out_of_bounds list'#13#10
      else if Listed.Count > 0 then
        Report := Report + 'job ' + P2_JOBS[n] + ': out_of_bounds = ' + Listed.ToJSON + #13#10;
    finally
      Res.Free;
    end;
  end;
  Assert.AreEqual('', Report, 'fitted values outside bounds_used:'#13#10 + Report);
end;

{ A project saved from a finished periodic fit must open in the GUI as that fit:
  the same [FIT], [LFPSO], [PARAMS] and [ANGLE] the job's own fit.xrcx carries,
  not the server's defaults (Mode 0 irregular, 100 x 1000), which is how the
  paper-2 fits were read as "not periodic" on 2026-09-16. }
procedure TTestMCPFit.SaveProject_FromFitJob_CarriesTheJobsFitSettings;

  function ParamsOf(const XRCXPath: string): TMemIniFile;
  var
    Dir: string;
  begin
    Dir := TPath.Combine(FTemp, 'x_' + Copy(TGUID.NewGuid.ToString, 2, 8));
    TDirectory.CreateDirectory(Dir);
    TZipFile.ExtractZipFile(XRCXPath, Dir);
    Result := TMemIniFile.Create(TPath.Combine(Dir, 'params.dsc'));
  end;

  procedure SameSection(Saved, JobFile: TMemIniFile; const Section: string);
  var
    Keys: TStringList;
    i: Integer;
  begin
    Keys := TStringList.Create;
    try
      JobFile.ReadSection(Section, Keys);
      Assert.IsTrue(Keys.Count > 0, '[' + Section + '] is in the job''s fit.xrcx');
      for i := 0 to Keys.Count - 1 do
        Assert.AreEqual(JobFile.ReadString(Section, Keys[i], '<absent>'),
                        Saved.ReadString(Section, Keys[i], '<absent>'),
          Format('[%s] %s of the saved project must equal the job''s', [Section, Keys[i]]));
    finally
      Keys.Free;
    end;
  end;

var
  Res, Args, Saved: TJSONObject;
  JobId, JobXRCX, ProjectFile: string;
  Reg: TToolRegistry;
  A, B: TMemIniFile;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(7, SyntheticCurveJSON, '', ',"chi2":{"theta_weight":2}');
  try
    JobId := Res.GetValue<string>('job_id');
    JobXRCX := TPath.Combine(WorkDir.Root, Res.GetValue<string>('files.xrcx'));
  finally
    Res.Free;
  end;

  Args := TJSONObject.ParseJSONValue(Format(
    '{"structure":%s,"name":"saved_fit","curves":{"job_id":"%s"}}',
    [START_STRUCTURE, JobId])) as TJSONObject;
  try
    Reg := TToolRegistry.Create;
    try
      RegisterFileTools(Reg);
      Saved := Reg.Execute('save_project', Args);
      try
        ProjectFile := TPath.Combine(WorkDir.Root, Saved.GetValue<string>('file'));
      finally
        Saved.Free;
      end;
    finally
      Reg.Free;
    end;
  finally
    Args.Free;
  end;

  A := ParamsOf(ProjectFile);
  try
    B := ParamsOf(JobXRCX);
    try
      Assert.AreEqual(1, B.ReadInteger('FIT', 'Mode', -1), 'the job ran the periodic engine');
      SameSection(A, B, 'FIT');
      SameSection(A, B, 'LFPSO');
      SameSection(A, B, 'PARAMS');
      SameSection(A, B, 'ANGLE');
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
end;

{ ------------------------------------------------- "scale": "auto" -- }

{ The curve is the start model's own reflectivity times a known number, so the
  normalisation the server computes must be exactly its reciprocal. Nothing
  about the measurement enters: this is the arithmetic of NormalizeAuto. }
procedure TTestMCPFit.Scale_Auto_RecoversAKnownMultiplier;
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
    '"scale":"auto",' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, StartCurveJSON(1000)]));

  Assert.AreEqual('auto', Req.ScaleMode);
  Assert.AreEqual(Double(0.001), Req.Scale, SCALE_TOL,
    'a curve a thousand times the model is scaled back by a thousand');
end;

procedure TTestMCPFit.Scale_Auto_ReportsTheAngleAndTheCounts;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { The curve starts at 0.3 deg on the total-reflection plateau and only falls,
    so its maximum below 0.5 deg is its first point. }
  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale":"auto",' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, StartCurveJSON(1000)]));

  Assert.AreEqual(Double(CURVE_THETA_MIN), Req.ScaleTheta, 1E-6,
    'the maximum of this curve is its first point');
  Assert.AreEqual(Double(0.5), Req.AutoThetaMax, 1E-12, 'the default range');
  Assert.AreEqual(Req.ScaleCounts * Req.Scale, Double(Req.Data[0].r), 1E-9,
    'the scaled curve holds the maximum times the scale');
end;

procedure TTestMCPFit.Scale_Auto_TakesOnlyTheMaximumBelowAutoThetaMax;
var
  Low_, High_: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { A curve that rises to a peak at 1.0 deg: with auto_theta_max at 0.5 the
    peak is ignored, with auto_theta_max at 2 it is the maximum. }
  Low_ := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale":"auto",' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, RISING_CURVE]));
  High_ := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale":"auto","auto_theta_max":2,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, RISING_CURVE]));

  Assert.AreEqual(Double(0.4), Low_.ScaleTheta, 1E-6,
    'below 0.5 deg the largest point is the one at 0.4');
  Assert.AreEqual(Double(1.0), High_.ScaleTheta, 1E-6,
    'over the whole curve it is the peak at 1.0');
end;

procedure TTestMCPFit.Scale_Auto_NoPointBelowAutoThetaMax_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale":"auto","auto_theta_max":0.1,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, RISING_CURVE])));
end;

procedure TTestMCPFit.Scale_UnknownString_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale":"plateau",' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

{ Two spellings, one normalisation. The boolean exists because "scale" takes a
  number or a string, and on the exp-03 run of 2026-09-18 an agent wrote
  "scale": auto unquoted fifteen times running - malformed JSON its own client
  refused before the server saw any of it. A boolean cannot be got wrong. }
procedure TTestMCPFit.ScaleAuto_Boolean_IsTheSameAsTheString;
var
  ByString, ByBoolean: TFitRequest;
  Curve: string;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Curve := StartCurveJSON(1000);
  ByString := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale":"auto",' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, Curve]));
  ByBoolean := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"scale_auto":true,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, Curve]));

  Assert.AreEqual('auto', ByBoolean.ScaleMode);
  Assert.AreEqual(ByString.Scale, ByBoolean.Scale, 1E-12,
    'the boolean and the string give the same number');
  Assert.AreEqual(ByString.ScaleTheta, ByBoolean.ScaleTheta, 1E-12);
  Assert.AreEqual(ByString.ScaleCounts, ByBoolean.ScaleCounts, 1E-12);
end;

procedure TTestMCPFit.ScaleAuto_True_IgnoresANumericScale;
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
    '"scale_auto":true,"scale":123.5,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, StartCurveJSON(1000)]));

  Assert.AreEqual('auto', Req.ScaleMode);
  Assert.AreEqual(Double(0.001), Req.Scale, SCALE_TOL,
    'the number beside "scale_auto": true is ignored, not multiplied in');
end;

procedure TTestMCPFit.ScaleAuto_False_LeavesTheNumberAlone;
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
    '"scale_auto":false,"scale":2.5,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  Assert.AreEqual('fixed', Req.ScaleMode);
  Assert.AreEqual(Double(2.5), Req.Scale, 1E-12);
end;

{ The number test A of the 2026-09-18 skill run computed by hand from
  get_measurement and calc_reflectivity, on the same specimen, the same start
  model and the same instrument settings: the server must reach it on its own. }
procedure TTestMCPFit.Scale_Auto_P2_05_MatchesTheHandComputation;
var
  Req: TFitRequest;
begin
  if not (HenkeTablesPresent and TFile.Exists(HenkePath + 'Co.bin') and
          TFile.Exists(HenkePath + 'SiO2.bin')) then
  begin
    Assert.Pass('the C/Co/SiO2 Henke tables are not installed on this machine');
    Exit;
  end;
  StageInbox('P2-05');

  Req := Parse(
    '{"structure":' + P2_05_START + ',' +
    '"measurement_id":"P2-05/xrr.dat","lambda":1.5406,"polarization":"s",' +
    '"resolution":0.009,"r_min":1e-6,"scale":"auto",' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}');

  Assert.AreEqual('auto', Req.ScaleMode);

  { The maximum of the raw scan, which is what Data - Normalize Auto takes and
    what the procedure of the skill describes: get_measurement, find the
    maximum, read the model there. Test A, by hand, instead took the value at
    theta 0.20975 - the angle it had chosen as the start of the fitting range,
    not the maximum - and got 7.798e-7 from 1064515 counts. The maximum is
    1074961 counts at 0.20075, and the model is higher there too, so the scale
    the server computes is 2.3 % above the one test A wrote down. Both are
    arithmetically right; only one of them is the procedure. }
  Assert.AreEqual(Double(0.20075), Req.ScaleTheta, 1E-6,
    'the largest measured intensity below 0.5 deg is at theta 0.20075');
  Assert.AreEqual(Double(1074961), Req.ScaleCounts, 0.5,
    'and holds 1074961 counts (2theta 0.4015 of the raw file)');
  Assert.AreEqual(Double(7.9794E-7), Req.Scale, 1E-10,
    'R_calc(0.20075) / 1074961, the normalisation of the raw maximum');
end;

procedure TTestMCPFit.Scale_Auto_IsEchoedInTheResult;
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(7, StartCurveJSON(1000), '', ',"scale":"auto"');
  try
    Assert.AreEqual('auto', Res.GetValue<string>('scale_mode'));
    Assert.AreEqual(Double(0.001), Res.GetValue<Double>('scale'), SCALE_TOL);
    Assert.AreEqual(Double(CURVE_THETA_MIN), Res.GetValue<Double>('scale_theta'),
      1E-6);
    Assert.IsTrue(Res.GetValue<Double>('scale_counts') > 0,
      'the raw counts the scale was taken from');
  finally
    Res.Free;
  end;
end;

{ --------------------------------------------------------- "paired" -- }

procedure TTestMCPFit.Paired_WithoutProfile_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"paired":["sigma"],' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Paired_Global_PairsEveryLayer;
var
  Req: TFitRequest;
  i: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"profile":true,"paired":["sigma","density"],' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  Assert.AreEqual(4, Length(Req.PairedParams),
    'two layers, sigma and density in each');
  for i := 0 to High(Req.Structure.Stacks[0].Layers) do
  begin
    Assert.IsFalse(Req.Structure.Stacks[0].Layers[i].P[1].Paired,
      'the thicknesses keep their polynomial');
    Assert.IsTrue(Req.Structure.Stacks[0].Layers[i].P[2].Paired, 'sigma');
    Assert.IsTrue(Req.Structure.Stacks[0].Layers[i].P[3].Paired, 'density');
  end;
end;

procedure TTestMCPFit.Paired_PerLayer_PairsOnlyThatParameter;
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
    '"profile":true,"paired":[{"stack":0,"layer":1,"parameters":["sigma"]}],' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  Assert.AreEqual(1, Length(Req.PairedParams));
  Assert.AreEqual(1, Req.PairedParams[0].LayerJSON, 'the layer that was named');
  Assert.AreEqual(2, Req.PairedParams[0].P, 'sigma');
  Assert.IsTrue(
    Req.Structure.Stacks[Req.PairedParams[0].GUIStack]
       .Layers[Req.PairedParams[0].GUILayer].P[2].Paired);
end;

procedure TTestMCPFit.Paired_NamedTwice_IsOnePairing;
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
    '"profile":true,' +
    '"paired":["sigma",{"stack":0,"layer":1,"parameters":["sigma"]}],' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  Assert.AreEqual(2, Length(Req.PairedParams),
    'the sigma of layer 1 is named twice and paired once');
end;

procedure TTestMCPFit.Paired_UnknownParameter_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"profile":true,"paired":["roughness"],' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Paired_Absent_LeavesEveryParameterFree;
var
  Req: TFitRequest;
  i, p: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"profile":true,' +
    '"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));

  Assert.AreEqual(0, Length(Req.PairedParams));
  for i := 0 to High(Req.Structure.Stacks[0].Layers) do
    for p := 1 to 3 do
      Assert.IsFalse(Req.Structure.Stacks[0].Layers[i].P[p].Paired,
        'without "paired" every parameter gets its own polynomial');
end;

{ A paired parameter has no polynomial, and TLFPSO_Poly.GetPolynomes leaves it
  out of the profiles it reports: what comes back is one curve per unpaired
  parameter and nothing for the paired ones. }
procedure TTestMCPFit.ProfileFit_SigmaAndDensityPaired_HaveNoPolynomial;
var
  Res: TJSONObject;
  Profiles, Paired, Layers: TJSONArray;
  i: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(11, SyntheticCurveJSON,
    '[{"target":"layer","stack":0,"layer":0,"parameters":["thickness","sigma"]},' +
    '{"target":"layer","stack":0,"layer":1,"parameters":["thickness","sigma"]}]',
    ',"profile":true,"paired":["sigma","density"]');
  try
    Paired := Res.GetValue('paired') as TJSONArray;
    Assert.AreEqual(4, Paired.Count, 'the result lists what was paired');

    Profiles := Res.GetValue('profiles') as TJSONArray;
    Assert.IsTrue(Profiles.Count > 0, 'the thicknesses still have profiles');
    for i := 0 to Profiles.Count - 1 do
      Assert.AreEqual('thickness',
        (Profiles.Items[i] as TJSONObject).GetValue<string>('parameter'),
        'no paired parameter has a polynomial');

    Layers := Res.GetValue<TJSONArray>('fitted_structure.stacks[0].layers');
    for i := 0 to Layers.Count - 1 do
    begin
      Assert.IsNotNull((Layers.Items[i] as TJSONObject).GetValue('thickness_profile'),
        'the thicknesses still vary over the periods');
      Assert.IsNull((Layers.Items[i] as TJSONObject).GetValue('sigma_profile'),
        'a paired sigma is one value, not a profile');
      Assert.IsNull((Layers.Items[i] as TJSONObject).GetValue('density_profile'),
        'a paired density is one value, not a profile');
    end;
  finally
    Res.Free;
  end;
end;

{ Rewrites a fitted_structure with per-period profiles as the same multilayer
  written out period by period: every repeating stack becomes N stacks of
  N = 1 whose layers take the i-th value of thickness_profile, sigma_profile
  and density_profile where the layer has one, and its single value otherwise.
  The profiles run from the surface end (period 1) down, the JSON stacks from
  the substrate up, so the periods are emitted last profile entry first;
  WrongWay emits them in array order, the mistake the rebuild must not make. }
function UnrollProfiles(const Fitted: TJSONObject; WrongWay: Boolean): string;

  function Pick(const L: TJSONObject; const ProfileKey, Key: string;
    j: Integer): Double;
  var
    Arr: TJSONArray;
  begin
    Arr := L.GetValue(ProfileKey) as TJSONArray;
    if Arr <> nil then
      Result := (Arr.Items[j] as TJSONNumber).AsDouble
    else
      Result := L.GetValue<Double>(Key);
  end;

var
  Out, JStack, JL, NewL: TJSONObject;
  Stacks, OutStacks, Layers, NewLayers: TJSONArray;
  k, step, j, i, N: Integer;
begin
  Out := TJSONObject.Create;
  try
    Out.AddPair('substrate', Fitted.GetValue('substrate').Clone as TJSONValue);
    if Fitted.GetValue('cap') <> nil then
      Out.AddPair('cap', Fitted.GetValue('cap').Clone as TJSONValue);
    if Fitted.GetValue('buffer') <> nil then
      Out.AddPair('buffer', Fitted.GetValue('buffer').Clone as TJSONValue);

    OutStacks := TJSONArray.Create;
    Out.AddPair('stacks', OutStacks);
    Stacks := Fitted.GetValue('stacks') as TJSONArray;
    for k := 0 to Stacks.Count - 1 do
    begin
      JStack := Stacks.Items[k] as TJSONObject;
      N := JStack.GetValue<Integer>('N');
      if N = 1 then
      begin
        OutStacks.AddElement(JStack.Clone as TJSONValue);
        Continue;
      end;
      Layers := JStack.GetValue('layers') as TJSONArray;
      for step := 0 to N - 1 do
      begin
        if WrongWay then
          j := step
        else
          j := N - 1 - step;           // substrate end first
        NewLayers := TJSONArray.Create;
        for i := 0 to Layers.Count - 1 do
        begin
          JL := Layers.Items[i] as TJSONObject;
          NewL := TJSONObject.Create;
          NewLayers.AddElement(NewL);
          NewL.AddPair('material', JL.GetValue<string>('material'));
          NewL.AddPair('thickness', TJSONNumber.Create(Pick(JL, 'thickness_profile', 'thickness', j)));
          NewL.AddPair('sigma', TJSONNumber.Create(Pick(JL, 'sigma_profile', 'sigma', j)));
          NewL.AddPair('density', TJSONNumber.Create(Pick(JL, 'density_profile', 'density', j)));
        end;
        OutStacks.AddElement(TJSONObject.Create
          .AddPair('N', TJSONNumber.Create(1))
          .AddPair('layers', NewLayers));
      end;
    end;
    Result := Out.ToJSON;
  finally
    Out.Free;
  end;
end;

function TTestMCPFit.RunUnpairedProfileFit: TJSONObject;
const
  { START_STRUCTURE with the densities written out, so that a free density has
    a start value to take its default bounds from. }
  START_WITH_DENSITIES =
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":55.5,"sigma":3,"density":2.2},' +
    '{"material":"Ru","thickness":13.0,"sigma":3,"density":12.0}]}]}';
begin
  Result := RunFit(5, SyntheticCurveJSON,
    '[{"target":"layer","stack":0,"layer":0,"parameters":["thickness","sigma","density"]},' +
    '{"target":"layer","stack":0,"layer":1,"parameters":["thickness","sigma","density"]}]',
    ',"profile":true', PROFILE_POPULATION, PROFILE_ITERATIONS, START_WITH_DENSITIES);
end;

{ A sigma or density with a polynomial of its own varies over the periods, so
  the result must carry its per-period values the way it carries the
  thicknesses; otherwise the fitted curve cannot be rebuilt from the result. }
procedure TTestMCPFit.ProfileFit_UnpairedSigmaAndDensity_ReportTheirProfiles;
const
  KEYS: array [0..2] of string = ('thickness_profile', 'sigma_profile', 'density_profile');
var
  Res: TJSONObject;
  Layers, Arr: TJSONArray;
  i, k, c: Integer;
  Varies: Boolean;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunUnpairedProfileFit;
  try
    Layers := Res.GetValue<TJSONArray>('fitted_structure.stacks[0].layers');
    for i := 0 to Layers.Count - 1 do
      for k := 0 to High(KEYS) do
      begin
        Arr := (Layers.Items[i] as TJSONObject).GetValue(KEYS[k]) as TJSONArray;
        Assert.IsNotNull(Arr, Format('layer %d reports %s', [i, KEYS[k]]));
        Assert.AreEqual(10, Arr.Count, Format('layer %d: one %s value per period', [i, KEYS[k]]));
        Varies := False;
        for c := 1 to Arr.Count - 1 do
          Varies := Varies or ((Arr.Items[c] as TJSONNumber).AsDouble <>
                               (Arr.Items[0] as TJSONNumber).AsDouble);
        Assert.IsTrue(Varies, Format('layer %d: %s varies over the periods', [i, KEYS[k]]));
      end;
  finally
    Res.Free;
  end;
end;

{ The acceptance test of the 2026-09-21 spec: a profile fit written out period
  by period from the reported arrays gives back the fit's own curve (through
  the calc_reflectivity engine path) and the fit's own chi2 (as the chi2_start
  of a second fit that starts from it). Emitting the periods in array order
  instead turns the gradient upside down, and the curve must then differ. }
procedure TTestMCPFit.ProfileFit_UnrolledIntoSinglePeriods_ReproducesTheFit;

  function CalcOn(const StructureJSON: string; const Grid: TDataArray): TDataArray;
  var
    Req: TCalcRequest;
    Used: TFitStructure;
    J: TJSONObject;
  begin
    Req := Default(TCalcRequest);
    J := TJSONObject.ParseJSONValue(StructureJSON) as TJSONObject;
    try
      Req.Structure := StructureFromJSON(J, Req.Info);
    finally
      J.Free;
    end;
    Req.Lambda := CU_K_ALPHA;
    Req.ThetaMin := Grid[0].t;
    Req.ThetaMax := Grid[High(Grid)].t;
    Req.Points := Length(Grid);
    Req.Polarization := cmSP;          // fit_xrr's default, which the fit ran with
    Req.RMin := 1E-7;
    Result := RunCalc(Req, Used);
  end;

  { Mean rather than maximum: the result reports every number to six
    significant digits, and at the deepest minimum of this curve that alone
    moves R by a few percent while chi2 moves by about 1e-4 of itself. }
  function MeanRelDiff(const A, B: TDataArray): Double;
  var
    i: Integer;
  begin
    Result := 0;
    for i := 0 to High(A) do
      Result := Result + Abs(A[i].r - B[i].r) / B[i].r;
    Result := Result / Length(A);
  end;

var
  Res, Res2: TJSONObject;
  Unrolled, WrongWay: string;
  FitCurve: TDataArray;
  Chi2, Chi2Rebuilt, Right, Wrong: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunUnpairedProfileFit;
  try
    Chi2 := Res.GetValue<Double>('chi2');
    Unrolled := UnrollProfiles(Res.GetValue('fitted_structure') as TJSONObject, False);
    WrongWay := UnrollProfiles(Res.GetValue('fitted_structure') as TJSONObject, True);
    FitCurve := ReadResultCurve(Res, 'calculated');
  finally
    Res.Free;
  end;

  Right := MeanRelDiff(CalcOn(Unrolled, FitCurve), FitCurve);
  Wrong := MeanRelDiff(CalcOn(WrongWay, FitCurve), FitCurve);
  Assert.IsTrue(Right < 1E-3,
    Format('the unrolled structure gives the fit''s curve: mean relative ' +
      'difference %.3g', [Right]));
  Assert.IsTrue(Wrong > 1E-2,
    Format('periods emitted surface end first must not give the same curve: ' +
      'mean relative difference %.3g', [Wrong]));

  Res2 := RunFit(1, SyntheticCurveJSON, '', '', FIT_POPULATION, 1, Unrolled);
  try
    Chi2Rebuilt := Res2.GetValue<Double>('chi2_start');
  finally
    Res2.Free;
  end;
  Assert.AreEqual(Chi2, Chi2Rebuilt, 1E-3 * Chi2,
    Format('the unrolled structure has the fit''s chi2: %.6g against %.6g',
      [Chi2Rebuilt, Chi2]));
end;

{ ------------------------------------------------------ optimizer.device -- }

procedure TTestMCPFit.Device_Default_IsAuto;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('auto', Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])).Device);
end;

procedure TTestMCPFit.Device_Unknown_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}],' +
    '"optimizer":{"device":"tpu"}}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Device_Cpu_IsEchoedAndUsed;
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  FOptimizerExtra := ',"device":"cpu"';
  try
    Res := RunFit(3, SyntheticCurveJSON, '', '', FIT_POPULATION, 2);
  finally
    FOptimizerExtra := '';
  end;
  try
    Assert.AreEqual('cpu', Res.GetValue<string>('optimizer_used.device'));
    Assert.AreEqual('CPU', Res.GetValue<string>('device_used'));
    Assert.IsNull(Res.GetValue('gpu_error'), 'no GPU was asked for');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Device_Auto_UsesTheGpuTheServerNames;
var
  Res: TJSONObject;
  Name, Err: string;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Res := RunFit(3, SyntheticCurveJSON);
  try
    Assert.AreEqual('auto', Res.GetValue<string>('optimizer_used.device'));
    if TGpuEvaluator.Available(Name, Err) then
      Assert.AreEqual(Name, Res.GetValue<string>('device_used'))
    else
      Assert.AreEqual('CPU', Res.GetValue<string>('device_used'));
  finally
    Res.Free;
  end;
end;

{ ---------------------------------------------------------- the report -- }

procedure TTestMCPFit.Report_IsInTheResultAndInTheJobFolder;
var
  Res: TJSONObject;
  FromFile: TJSONValue;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(3, SyntheticCurveJSON);
  try
    FromFile := ReadResultFile(Res, 'report');
    try
      Assert.AreEqual(ReportOf(Res).ToJSON, FromFile.ToJSON,
        'report.json holds exactly what the result holds');
    finally
      FromFile.Free;
    end;
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Report_OrdersAndStart_AreBothThere;
var
  Res, Rep, Start, Order: TJSONObject;
  Orders: TJSONArray;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(3, SyntheticCurveJSON);
  try
    Rep := ReportOf(Res);
    Assert.AreEqual(Res.GetValue<Double>('chi2'), Rep.GetValue<Double>('chi2'),
      1E-12, 'the report repeats the chi-squared of the fit');
    Assert.AreEqual(Res.GetValue<Double>('chi2_start'),
      Rep.GetValue<Double>('chi2_start'), 1E-12);
    Assert.AreEqual(Double(68.5), Rep.GetValue<Double>('period_A'), 0.001,
      'the periodic engine holds the period of the start model');

    Orders := Rep.GetValue('orders') as TJSONArray;
    Assert.IsTrue(Orders.Count >= 3,
      'a 68.5 A period shows at least three orders between 0.3 and 3 degrees');
    Order := Orders.Items[0] as TJSONObject;
    Assert.AreEqual(1, Order.GetValue<Integer>('n'));
    Assert.IsTrue(Order.GetValue<Double>('ratio') > 0, 'calculated over measured');

    Assert.IsTrue(Rep.GetValue('start') is TJSONObject,
      'the same numbers for the model the fit started from');
    Start := Rep.GetValue('start') as TJSONObject;
    Assert.IsTrue((Start.GetValue('orders') as TJSONArray).Count >= 3);
    Assert.IsTrue(Rep.GetValue('bands') is TJSONArray);
    Assert.IsTrue(Rep.GetValue('near_bounds') is TJSONArray);
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Report_WideBounds_LeaveNearBoundsEmpty;
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(3, SyntheticCurveJSON,
    '[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}]',
    ',"bounds":[{"stack":0,"layer":0,"parameter":"thickness","min":20,"max":65}]');
  try
    Assert.AreEqual(0, (ReportOf(Res).GetValue('near_bounds') as TJSONArray).Count,
      'a thickness of about 54 A is nowhere near 20 or 65');
  finally
    Res.Free;
  end;
end;

{ The true thickness is 53.8 A and the bound stops the fit at 55.4, so the best
  value the engine may reach is the bound itself - which is exactly the case the
  report has to name, because the answer is then the client's limit and not the
  data's. }
procedure TTestMCPFit.Report_ValueDrivenOntoItsBound_IsNamedInNearBounds;
var
  Res: TJSONObject;
  Near: TJSONArray;
  Entry: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  { Both thicknesses are free: with only the C layer free the engine's own
    NormalizeD would hold it at 55.5 A to keep the period, and there would be
    nothing for the bound to stop. }
  Res := RunFit(5, SyntheticCurveJSON, '',
    ',"bounds":[{"stack":0,"layer":0,"parameter":"thickness","min":55.4,"max":55.6}]',
    40, 30);
  try
    Near := ReportOf(Res).GetValue('near_bounds') as TJSONArray;
    Assert.AreEqual(1, Near.Count, 'one value stopped on a bound');
    Entry := Near.Items[0] as TJSONObject;
    Assert.AreEqual('thickness', Entry.GetValue<string>('parameter'));
    Assert.AreEqual('min', Entry.GetValue<string>('bound'),
      'the true thickness is below the range, so the fit runs into the floor');
    Assert.IsTrue(Entry.GetValue<Double>('margin_fraction') <= 0.05);
  finally
    Res.Free;
  end;
end;

{ ---------------------------------------------------------- the schema -- }

procedure TTestMCPFit.Schema_DescribesNormalizeAutoAndPairing;
var
  Scale, Paired: string;
begin
  Scale := FitXrrSchemaValue('scale.description');
  Assert.IsTrue(Scale.Contains('"auto"'),
    'scale: the string it still accepts');
  Assert.IsFalse(Scale.Contains('0.4 '),
    'scale: the old "compare at about 0.4 deg" rule is gone');

  Assert.IsTrue(FitXrrSchemaValue('auto_theta_max.description').Contains('auto'),
    'auto_theta_max belongs to the automatic scale');

  Assert.AreEqual('boolean', FitXrrSchemaValue('scale_auto.type'),
    'scale_auto is a plain boolean: a union type is what a client gets wrong');
  Assert.IsTrue(FitXrrSchemaValue('scale_auto.description').Contains('Normalize Auto'),
    'scale_auto names the GUI command it repeats');
  Assert.IsTrue(Scale.Contains('scale_auto'),
    'the scale description sends the reader to the boolean first');

  Paired := FitXrrSchemaValue('paired.description');
  Assert.IsTrue(Paired.Contains('profile'), 'paired: only in a profile fit');
  Assert.IsTrue(Paired.Contains('sigma'), 'paired: the laboratory practice');
end;

procedure TTestMCPFit.JobWait_IsRegisteredAndNamesTheClientTimeout;
var
  Reg: TToolRegistry;
  Tools: TJSONArray;
  T: TJSONObject;
  i: Integer;
  Found: Boolean;
begin
  Found := False;
  Reg := TToolRegistry.Create;
  try
    RegisterJobTools(Reg);
    Tools := Reg.GetToolsList;
    try
      for i := 0 to Tools.Count - 1 do
      begin
        T := Tools.Items[i] as TJSONObject;
        if T.GetValue<string>('name') <> 'job_wait' then
          Continue;
        Found := True;
        Assert.IsTrue(T.GetValue<string>('description').Contains('MCP_TOOL_TIMEOUT'),
          'job_wait names the client setting that limits it');
        Assert.IsTrue(((T.GetValue('inputSchema') as TJSONObject)
          .GetValue('properties') as TJSONObject).GetValue('wait_s') <> nil,
          'job_wait takes wait_s');
      end;
    finally
      Tools.Free;
    end;
  finally
    Reg.Free;
  end;
  Assert.IsTrue(Found, 'job_wait is registered');
end;

{ ------------------------------------------------------- solved scale -- }

procedure TTestMCPFit.Fit_SolvedScale_OnByDefault_ReportsTheMode;
var
  Res, ResOff: TJSONObject;
  Ratio: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  FOptimizerExtra := ',"device":"cpu"';
  try
    Res := RunFit(7, SyntheticCurveJSON);
    try
      ResOff := RunFit(7, SyntheticCurveJSON, '', ',"scale_solve":false');
      try
        Assert.IsTrue(Res.GetValue<Boolean>('scale_solve'), 'on by default');
        Assert.AreEqual('solved', Res.GetValue<string>('chi2_scale'));
        Assert.AreEqual(Double(0.2), Res.GetValue<Double>('scale_solve_window'), 1E-9, 'the default window');
        Ratio := Res.GetValue<Double>('scale_ratio');
        Assert.IsTrue((Ratio >= 1 / 1.2) and (Ratio <= 1.2), Format('scale_ratio %.5f inside the window', [Ratio]));
        Assert.IsTrue(Abs(Ratio - 1) < 0.05,
          Format('a synthetic curve at its true scale solves near 1: %.5f', [Ratio]));
        Assert.AreEqual(Res.GetValue<Double>('scale') * Ratio, Res.GetValue<Double>('scale_solved'),
          1E-6 * Ratio, 'scale_solved = scale x ratio');
        Assert.IsFalse(Res.GetValue<Boolean>('scale_clamped'));
        Assert.IsTrue(Res.GetValue<Double>('scale_start_ratio') > 0);
        Assert.AreEqual(Res.GetValue<Double>('chi2'), Res.GetValue<Double>('chi2_recalc'),
          1E-6 * Res.GetValue<Double>('chi2'), 'the CPU rescore and the recalculation agree at the solved scale');
        { the same start structure can only score better with its scale solved }
        Assert.IsTrue(Res.GetValue<Double>('chi2_start') <= ResOff.GetValue<Double>('chi2_start') * (1 + 1E-9),
          Format('chi2_start solved %.9g against anchored %.9g',
            [Res.GetValue<Double>('chi2_start'), ResOff.GetValue<Double>('chi2_start')]));
        Assert.IsTrue(Res.GetValue<string>('chi2_scale_definition') <> '');
      finally
        ResOff.Free;
      end;
    finally
      Res.Free;
    end;
  finally
    FOptimizerExtra := '';
  end;
end;

procedure TTestMCPFit.Fit_SolvedScale_Off_IsAnchored;
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  FOptimizerExtra := ',"device":"cpu"';
  try
    Res := RunFit(7, SyntheticCurveJSON, '', ',"scale_solve":false,"scale_solve_window":0.5');
  finally
    FOptimizerExtra := '';
  end;
  try
    Assert.IsFalse(Res.GetValue<Boolean>('scale_solve'));
    Assert.AreEqual('anchored', Res.GetValue<string>('chi2_scale'));
    Assert.AreEqual(Double(1), Res.GetValue<Double>('scale_ratio'), 1E-12, 'anchored: the ratio is 1');
    Assert.AreEqual(Double(1), Res.GetValue<Double>('scale_start_ratio'), 1E-12);
    Assert.AreEqual(Res.GetValue<Double>('scale'), Res.GetValue<Double>('scale_solved'), 1E-12);
    Assert.AreEqual(Double(0.5), Res.GetValue<Double>('scale_solve_window'), 1E-9, 'echoed as given');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Fit_SolvedScale_WindowNegative_Refused;
begin
  try
    Parse('{"structure":' + START_STRUCTURE + ',"curve":' + SyntheticCurveJSON +
      ',"lambda":1.5406,"free":[{"target":"layer","stack":0,"layer":0,"parameters":["thickness"]}],' +
      '"scale_solve_window":-0.1}');
    Assert.Fail('a negative window must be refused');
  except
    on E: EMCPError do
      Assert.AreEqual('invalid_argument', E.Code);
  end;
end;

procedure TTestMCPFit.Schema_Has_ScaleSolve;
begin
  Assert.IsTrue(FitXrrSchemaValue('scale_solve.description').Contains('default true'),
    'scale_solve is documented as on by default');
  Assert.IsTrue(FitXrrSchemaValue('scale_solve_window.description').Contains('0.2'),
    'the window default is documented');
end;


{ The report reads the measured curve at the scale chi2 was taken at. A curve
  at 0.9 of the model solves to scale_ratio ~ 1/0.9; the first order's i_meas
  must then be scale_ratio times the anchored run's, at the same point - until
  3.9.4 the report stayed at the anchored scale and disagreed with chi2 and the
  chart by that factor. }
procedure TTestMCPFit.Fit_SolvedScale_ReportReadsTheMeasuredCurveAtIt;
var
  ResOn, ResOff: TJSONObject;
  OOn, OOff: TJSONObject;
  Ratio: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  FOptimizerExtra := ',"device":"cpu"';
  try
    ResOn := RunFit(7, StartCurveJSON(0.9));
    try
      ResOff := RunFit(7, StartCurveJSON(0.9), '', ',"scale_solve":false');
      try
        Ratio := ResOn.GetValue<Double>('scale_ratio');
        Assert.IsTrue(Ratio > 1.05, Format('a curve at 0.9 solves above 1: %.5f', [Ratio]));
        OOn := (ReportOf(ResOn).GetValue('orders') as TJSONArray).Items[0] as TJSONObject;
        OOff := (ReportOf(ResOff).GetValue('orders') as TJSONArray).Items[0] as TJSONObject;
        Assert.AreEqual(OOff.GetValue<Double>('theta_meas_deg'), OOn.GetValue<Double>('theta_meas_deg'),
          1E-9, 'the same measured point');
        Assert.AreEqual(OOff.GetValue<Double>('i_meas') * Ratio, OOn.GetValue<Double>('i_meas'),
          1E-4 * OOn.GetValue<Double>('i_meas'), 'i_meas at the solved scale');
      finally
        ResOff.Free;
      end;
    finally
      ResOn.Free;
    end;
  finally
    FOptimizerExtra := '';
  end;
end;

{ A GUI project stores a value that stopped on its bound as the same number
  twice: the author's Sb/B4C fit has a sigma of 7.7 on a floor of 7.7. The
  start is a Single and 7.7 is not one, so the start used to be refused as
  2E-7 under its own bound. }
procedure TTestMCPFit.Bounds_StartOnItsBound_Accepted;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('', ErrorCodeOf(Format(
    '{"structure":{"substrate":{"material":"Si","sigma":3},"stacks":[{"N":10,' +
    '"layers":[{"material":"C","thickness":55.5,"sigma":7.7},' +
    '{"material":"Ru","thickness":13.0,"sigma":3}]}]},' +
    '"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"stack":0,"layer":0,"parameters":["sigma"]}],' +
    '"bounds":[{"stack":0,"layer":0,"parameter":"sigma","min":7.7,"max":12.83}]}',
    [DUMMY_CURVE])), 'on the floor');
  Assert.AreEqual('', ErrorCodeOf(Format(
    '{"structure":{"substrate":{"material":"Si","sigma":3},"stacks":[{"N":10,' +
    '"layers":[{"material":"C","thickness":55.5,"sigma":12.83},' +
    '{"material":"Ru","thickness":13.0,"sigma":3}]}]},' +
    '"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"stack":0,"layer":0,"parameters":["sigma"]}],' +
    '"bounds":[{"stack":0,"layer":0,"parameter":"sigma","min":7.7,"max":12.83}]}',
    [DUMMY_CURVE])), 'on the ceiling');
end;

{ ------------------------------------------------------- "mode": "irregular" -- }

const
  { The swarm of the irregular fits below starts around the start model. }
  IRREGULAR_NEAR_START = ',"range_seed":false';
  { Thickness and sigma of both layers free: forty values over ten periods. }
  IRREGULAR_FREE =
    '[{"stack":0,"layer":0,"parameters":["thickness","sigma"]},' +
    '{"stack":0,"layer":1,"parameters":["thickness","sigma"]}]';
  { Tight bounds around START_STRUCTURE that hold the answer. With the default
    +/-30% every period of every seeded particle is a different multilayer,
    and a test-sized swarm never beats the start (probe of 2026-09-25: 8.12
    to 8.12 at 30 x 15, 8.03 at 200 x 40; the GUI's own fits of such a mirror
    run 5000 x 200). A fit that returns its start would test nothing. The same
    bounds serve a continuation, which must start inside them in every
    period. }
  IRREGULAR_BOUNDS =
    ',"bounds":[{"stack":0,"layer":0,"parameter":"thickness","min":53,"max":56.5},' +
    '{"stack":0,"layer":1,"parameter":"thickness","min":12.5,"max":15.5},' +
    '{"stack":0,"layer":0,"parameter":"sigma","min":2.5,"max":3.5},' +
    '{"stack":0,"layer":1,"parameter":"sigma","min":2.5,"max":3.5}]';
  { Ten per-period C thicknesses for START_STRUCTURE, surface end first. }
  C_TABLE = '[55.5,55.4,55.3,55.2,55.1,55.0,54.9,54.8,54.7,54.6]';

/// START_STRUCTURE with a thickness_profile on its C layer.
function StartWithCTable(const Table: string): string;
begin
  Result :=
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[' +
    '{"material":"C","thickness":55.5,"sigma":3,"thickness_profile":' + Table + '},' +
    '{"material":"Ru","thickness":13.0,"sigma":3}]}]}';
end;

/// The curve of StructureJSON on the angles of Grid, as calc_reflectivity
/// computes it with fit_xrr's defaults.
function CalcOnGrid(const StructureJSON: string; const Grid: TDataArray): TDataArray;
var
  Req: TCalcRequest;
  Used: TFitStructure;
  J: TJSONObject;
begin
  Req := Default(TCalcRequest);
  J := TJSONObject.ParseJSONValue(StructureJSON) as TJSONObject;
  try
    Req.Structure := StructureFromJSON(J, Req.Info);
  finally
    J.Free;
  end;
  Req.Lambda := CU_K_ALPHA;
  Req.ThetaMin := Grid[0].t;
  Req.ThetaMax := Grid[High(Grid)].t;
  Req.Points := Length(Grid);
  Req.Polarization := cmSP;
  Req.RMin := 1E-7;
  Result := RunCalc(Req, Used);
end;

function MeanRelativeDifference(const A, B: TDataArray): Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(A) do
    Result := Result + Abs(A[i].r - B[i].r) / B[i].r;
  Result := Result / Length(A);
end;

function ArrayOfLayer(const Res: TJSONObject; const Structure: string;
  Layer: Integer; const Key: string): TJSONArray;
begin
  Result := Res.GetValue<TJSONObject>(
    Format('%s.stacks[0].layers[%d]', [Structure, Layer])).GetValue(Key) as TJSONArray;
end;

procedure TTestMCPFit.Irregular_Mode_IsParsed;
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
    '"mode":"irregular","free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));
  Assert.AreEqual('irregular', Req.Mode);
  Assert.IsTrue(Req.Irregular);
  Assert.IsFalse(Req.Profile);
  Assert.IsFalse(Req.StartProfiles);
  Assert.IsFalse(Req.Fit.Smooth, 'period_smooth is off unless asked for');
  Assert.AreEqual(-1, Integer(Req.Fit.SmoothWindow), 'the automatic window');

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"profile":true,' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));
  Assert.AreEqual('profile', Req.Mode, '"profile": true is "mode": "profile"');
  Assert.IsTrue(Req.Profile);
end;

procedure TTestMCPFit.Irregular_UnknownMode_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"graded",' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Irregular_ModeAndProfileDisagree_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"mode":"irregular","profile":true,' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.Irregular_WithoutARepeatingStack_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":{"substrate":{"material":"Si"},"stacks":[{"N":1,"layers":' +
    '[{"material":"Ru","thickness":50,"sigma":3}]}]},' +
    '"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [DUMMY_CURVE])));
end;

procedure TTestMCPFit.Irregular_FreePeriod_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"mode":"irregular","free":%s}',
    [START_STRUCTURE, DUMMY_CURVE, PERIOD_FREE])));
end;

{ The author's Sb/B4C project pairs a different set on each layer: all three
  on one, the density alone on the next, sigma and density on the third. }
procedure TTestMCPFit.Irregular_Paired_PerLayer_IsAccepted;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"paired":[{"stack":0,"layer":0,"parameters":["density"]},' +
    '{"stack":0,"layer":1,"parameters":["sigma","density"]}],' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE]));
  Assert.AreEqual(3, Length(Req.PairedParams));
  with Req.Structure.Stacks[0] do
  begin
    Assert.IsFalse(Layers[0].P[1].Paired);
    Assert.IsFalse(Layers[0].P[2].Paired);
    Assert.IsTrue(Layers[0].P[3].Paired);
    Assert.IsFalse(Layers[1].P[1].Paired);
    Assert.IsTrue(Layers[1].P[2].Paired);
    Assert.IsTrue(Layers[1].P[3].Paired);
  end;
end;

procedure TTestMCPFit.PeriodSmooth_OutsideIrregular_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"optimizer":{"period_smooth":true},' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])), 'periodic');
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"profile",' +
    '"optimizer":{"period_smooth":true},' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])), 'profile');
end;

{ Ten periods: the window runs from 1 to 5 - beyond half the periods the
  engine's moving average reaches before period 1 - and -1 is automatic. }
procedure TTestMCPFit.PeriodSmooth_Window_DefaultAndRange;

  function WithWindow(const W: string): string;
  begin
    Result := Format(
      '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
      '"optimizer":{"period_smooth":true%s},' +
      '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
      [START_STRUCTURE, DUMMY_CURVE, W]);
  end;

var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(WithWindow(''));
  Assert.IsTrue(Req.Fit.Smooth);
  Assert.AreEqual(-1, Integer(Req.Fit.SmoothWindow));
  Assert.AreEqual(5, Integer(Parse(WithWindow(',"period_smooth_window":5')).Fit.SmoothWindow));
  Assert.AreEqual('invalid_argument', ErrorCodeOf(WithWindow(',"period_smooth_window":6')),
    'more than half the periods');
  Assert.AreEqual(-1, Integer(Parse(WithWindow(',"period_smooth_window":-1')).Fit.SmoothWindow));
  Assert.AreEqual('invalid_argument', ErrorCodeOf(WithWindow(',"period_smooth_window":10')),
    'as many as the periods');
  Assert.AreEqual('invalid_argument', ErrorCodeOf(WithWindow(',"period_smooth_window":0')));
  Assert.AreEqual('invalid_argument', ErrorCodeOf(WithWindow(',"period_smooth_window":2.5')));
end;

procedure TTestMCPFit.PeriodSmooth_WindowWithoutSmooth_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"optimizer":{"period_smooth_window":3},' +
    '"free":[{"stack":0,"layer":0,"parameters":["thickness"]}]}',
    [START_STRUCTURE, DUMMY_CURVE])));
end;

procedure TTestMCPFit.StartProfiles_ArraysWithoutTheFlag_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])),
    'an irregular fit must be told what to do with a table');
  Assert.AreEqual('', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"start_profiles":false,"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])), 'false ignores it');
  Assert.AreEqual('', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,' +
    '"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])),
    'a periodic fit ignores it, as it always has');
end;

procedure TTestMCPFit.StartProfiles_OutsideIrregular_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"start_profiles":true,' +
    '"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])));
  Assert.AreEqual('', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"start_profiles":false,' +
    '"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])), 'false asks for nothing');
end;

procedure TTestMCPFit.StartProfiles_WrongLength_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"start_profiles":true,"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable('[55.5,55.4,55.3]'), DUMMY_CURVE])));
end;

procedure TTestMCPFit.StartProfiles_OnAPairedParameter_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"start_profiles":true,"paired":["thickness"],' +
    '"free":[{"stack":0,"layer":1,"parameters":["thickness"]}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])));
end;

procedure TTestMCPFit.StartProfiles_PeriodOutsideBounds_Refused;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  { 54.6, the last period, lies under a floor of 55 }
  Assert.AreEqual('invalid_argument', ErrorCodeOf(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"start_profiles":true,"free":[{"stack":0,"layer":0,"parameters":["thickness"]}],' +
    '"bounds":[{"stack":0,"layer":0,"parameter":"thickness","min":55,"max":60}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE])));
end;

procedure TTestMCPFit.StartProfiles_FillTheTables;
var
  Req: TFitRequest;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Req := Parse(Format(
    '{"structure":%s,"curve":%s,"lambda":1.5406,"resolution":0,"mode":"irregular",' +
    '"start_profiles":true,"free":[{"stack":0,"layer":0,"parameters":["thickness"]}],' +
    '"bounds":[{"stack":0,"layer":0,"parameter":"thickness","min":50,"max":60}]}',
    [StartWithCTable(C_TABLE), DUMMY_CURVE]));
  Assert.IsTrue(Req.StartProfiles);
  Assert.AreEqual(10, Integer(Length(Req.Structure.Stacks[0].Layers[0].PP[1])));
  Assert.AreEqual(Single(55.5), Req.Structure.Stacks[0].Layers[0].PP[1][0], 1E-5,
    'entry 0 is period 1, the surface end');
  Assert.AreEqual(Single(54.6), Req.Structure.Stacks[0].Layers[0].PP[1][9], 1E-5);
  Assert.AreEqual(0, Integer(Length(Req.Structure.Stacks[0].Layers[1].PP[1])),
    'a layer without an array has no table');
end;

procedure TTestMCPFit.Irregular_SameSeedTwice_GivesTheSameAnswer;
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
  A := RunFit(7, Curve, IRREGULAR_FREE, ',"mode":"irregular","paired":["density"]');
  try
    B := RunFit(7, Curve, IRREGULAR_FREE, ',"mode":"irregular","paired":["density"]');
    try
      Assert.AreEqual(A.GetValue<Double>('chi2'), B.GetValue<Double>('chi2'), 0.0,
        'the same seed must give the same chi-squared');
      Assert.AreEqual(A.GetValue<TJSONObject>('fitted_structure').ToJSON,
                      B.GetValue<TJSONObject>('fitted_structure').ToJSON,
        'the same seed must give the same per-period structure');
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
end;

procedure TTestMCPFit.Irregular_ReportsEveryUnpairedParameterPerPeriod;
const
  KEYS: array [0..2] of string = ('thickness_profile', 'sigma_profile', 'density_profile');
var
  Res: TJSONObject;
  Arr, Near: TJSONArray;
  Mode: TJSONObject;
  i, k: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(3, SyntheticCurveJSON, '', ',"mode":"irregular"');
  try
    Assert.AreEqual('irregular', Res.GetValue<string>('mode'));
    Assert.AreEqual('TLFPSO_Irregular', Res.GetValue<string>('engine'));
    for i := 0 to 1 do
      for k := 0 to High(KEYS) do
      begin
        Arr := ArrayOfLayer(Res, 'fitted_structure', i, KEYS[k]);
        Assert.IsNotNull(Arr, Format('layer %d reports %s: nothing is paired', [i, KEYS[k]]));
        Assert.AreEqual(10, Arr.Count, 'one value per period');
      end;
    Assert.AreEqual((ArrayOfLayer(Res, 'fitted_structure', 0, 'thickness_profile')
                      .Items[0] as TJSONNumber).AsDouble,
                    Res.GetValue<Double>('fitted_structure.stacks[0].layers[0].thickness'),
                    0.0, 'the layer''s plain value is period 1''s');

    Mode := (Res.GetValue('period_mode') as TJSONArray).Items[0] as TJSONObject;
    Assert.AreEqual('floating', Mode.GetValue<string>('mode'));
    Assert.IsTrue(Mode.GetValue<Double>('fitted_A_min') <= Mode.GetValue<Double>('fitted_A'));
    Assert.IsTrue(Mode.GetValue<Double>('fitted_A') <= Mode.GetValue<Double>('fitted_A_max'));

    Assert.AreEqual(0, (Res.GetValue('out_of_bounds') as TJSONArray).Count,
      (Res.GetValue('out_of_bounds') as TJSONArray).ToJSON);
    Near := ReportOf(Res).GetValue('near_bounds') as TJSONArray;
    for i := 0 to Near.Count - 1 do
      Assert.IsNotNull((Near.Items[i] as TJSONObject).GetValue('period_index'),
        'a repeating layer''s value near a bound names its period');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPFit.Irregular_Pairing_ReducesTheFreeValues;
var
  Res: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(3, SyntheticCurveJSON, IRREGULAR_FREE, ',"mode":"irregular"', 4, 1);
  try
    Assert.AreEqual(40, Res.GetValue<Integer>('free_values'),
      'two parameters of two layers in each of ten periods');
  finally
    Res.Free;
  end;

  Res := RunFit(3, SyntheticCurveJSON, IRREGULAR_FREE,
    ',"mode":"irregular","paired":["sigma"]', 4, 1);
  try
    Assert.AreEqual(22, Res.GetValue<Integer>('free_values'),
      'the thicknesses in each period, and one sigma per layer');
    Assert.IsNull(ArrayOfLayer(Res, 'fitted_structure', 0, 'sigma_profile'),
      'a paired sigma is one value');
    Assert.IsNotNull(ArrayOfLayer(Res, 'fitted_structure', 0, 'thickness_profile'));
  finally
    Res.Free;
  end;
end;

{ A paired parameter is one value, so a paired value on its bound is one entry
  of near_bounds, without a period_index - not N copies of it. The true sigma
  is 3, on the floor given here, where the fit leaves it. }
procedure TTestMCPFit.Irregular_PairedValueNearItsBound_IsOneEntry;
var
  Res: TJSONObject;
  Near: TJSONArray;
  Entry: TJSONObject;
  i, Sigmas: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Res := RunFit(3, SyntheticCurveJSON, IRREGULAR_FREE,
    ',"mode":"irregular","paired":["sigma"],"bounds":[' +
    '{"stack":0,"layer":0,"parameter":"thickness","min":53,"max":56.5},' +
    '{"stack":0,"layer":1,"parameter":"thickness","min":12.5,"max":15.5},' +
    '{"stack":0,"layer":0,"parameter":"sigma","min":2.999,"max":3.3},' +
    '{"stack":0,"layer":1,"parameter":"sigma","min":2.999,"max":3.3}]');
  try
    Near := ReportOf(Res).GetValue('near_bounds') as TJSONArray;
    Sigmas := 0;
    for i := 0 to Near.Count - 1 do
    begin
      Entry := Near.Items[i] as TJSONObject;
      if Entry.GetValue<string>('parameter') <> 'sigma' then
        Continue;
      Inc(Sigmas);
      Assert.IsNull(Entry.GetValue('period_index'), 'a paired value has no period');
    end;
    Assert.IsTrue((Sigmas >= 1) and (Sigmas <= 2),
      Format('one entry per paired sigma on its floor, not one per period: %d', [Sigmas]));
  finally
    Res.Free;
  end;
end;

{ The per-period structure the result reports is the structure the fit scored:
  written out period by period it gives back the fit's curve and chi2. The
  sigma of the Ru layer is paired, so this also holds the engine to one value
  in every period for it - UnrollProfiles uses the layer's single value where
  there is no array. }
procedure TTestMCPFit.Irregular_UnrolledIntoSinglePeriods_ReproducesTheFit;
var
  Res, Res2: TJSONObject;
  Unrolled: string;
  FitCurve: TDataArray;
  Chi2, Chi2Rebuilt, Diff: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  FOptimizerExtra := IRREGULAR_NEAR_START;
  try
    Res := RunFit(5, SyntheticCurveJSON, IRREGULAR_FREE,
      ',"mode":"irregular","paired":[{"stack":0,"layer":1,"parameters":["sigma"]}]' +
      IRREGULAR_BOUNDS, PROFILE_POPULATION, PROFILE_ITERATIONS);
  finally
    FOptimizerExtra := '';
  end;
  try
    Chi2 := Res.GetValue<Double>('chi2');
    Assert.IsTrue(Chi2 < Res.GetValue<Double>('chi2_start'), 'the fit improved on the start');
    Assert.IsNull(ArrayOfLayer(Res, 'fitted_structure', 1, 'sigma_profile'));
    Assert.IsNotNull(ArrayOfLayer(Res, 'fitted_structure', 0, 'sigma_profile'));
    Unrolled := UnrollProfiles(Res.GetValue('fitted_structure') as TJSONObject, False);
    FitCurve := ReadResultCurve(Res, 'calculated');
  finally
    Res.Free;
  end;

  Diff := MeanRelativeDifference(CalcOnGrid(Unrolled, FitCurve), FitCurve);
  Assert.IsTrue(Diff < 1E-3,
    Format('the unrolled structure gives the fit''s curve: mean relative ' +
      'difference %.3g', [Diff]));

  Res2 := RunFit(1, SyntheticCurveJSON, '', '', FIT_POPULATION, 1, Unrolled);
  try
    Chi2Rebuilt := Res2.GetValue<Double>('chi2_start');
  finally
    Res2.Free;
  end;
  Assert.AreEqual(Chi2, Chi2Rebuilt, 1E-3 * Chi2,
    Format('the unrolled structure has the fit''s chi2: %.6g against %.6g',
      [Chi2Rebuilt, Chi2]));
end;

{ fit.xrcx is what the GUI opens: Irregular mode, the Smooth settings, the
  pairing flags, and the periods in the layers' tables with a Table
  extension to expand them - the state the GUI leaves after its own fit. }
procedure TTestMCPFit.Irregular_Xrcx_IsAnIrregularProjectWithItsTable;
var
  Res: TJSONObject;
  Proj: TXRCXProject;
  S: TFitStructure;
  Info: TStructureInfo;
  Arr: TJSONArray;
  c: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  FOptimizerExtra := ',"period_smooth":true,"period_smooth_window":2';
  try
    Res := RunFit(3, SyntheticCurveJSON, IRREGULAR_FREE,
      ',"mode":"irregular","paired":["density"]');
  finally
    FOptimizerExtra := '';
  end;
  try
    Assert.IsTrue(Res.GetValue<Boolean>('optimizer_used.period_smooth'));
    Assert.AreEqual(2, Res.GetValue<Integer>('optimizer_used.period_smooth_window'));

    Proj := ReadXRCX(TPath.Combine(FTemp,
      (Res.GetValue('files') as TJSONObject).GetValue<string>('xrcx')));
    Assert.AreEqual(0, Proj.Params.FitMode, '[FIT] Mode 0 is Irregular');
    Assert.IsTrue(Proj.Params.LFPSO.Smooth, '[LFPSO] Smooth');
    Assert.AreEqual(2, Integer(Proj.Params.LFPSO.SmoothWindow), '[LFPSO] SmoothWindow');
    Assert.IsTrue(Proj.TableExtension, 'the model carries a Table extension');

    S := StructureFromXRCData(Proj.XRCData, Info);
    Assert.IsTrue(S.Stacks[0].Layers[0].P[3].Paired, 'the pairing is in the file');
    Assert.AreEqual(0, Integer(Length(S.Stacks[0].Layers[0].PP[3])),
      'a paired parameter has no table');
    Arr := ArrayOfLayer(Res, 'fitted_structure', 0, 'thickness_profile');
    Assert.AreEqual(10, Integer(Length(S.Stacks[0].Layers[0].PP[1])));
    { the GUI's table format keeps four decimals }
    for c := 0 to 9 do
      Assert.AreEqual((Arr.Items[c] as TJSONNumber).AsDouble, Double(S.Stacks[0].Layers[0].PP[1][c]),
        6E-5, Format('period %d', [c + 1]));
  finally
    Res.Free;
  end;
end;

{ period_smooth averages each parameter over the periods; a paired parameter is
  one value in every period already, so with everything paired the smoothing
  has nothing to do, and the same seed gives the same fit with it and without
  it. With nothing paired it does change the fit - otherwise the first half of
  the test would prove nothing. }
procedure TTestMCPFit.Irregular_SmoothWithEveryParameterPaired_ChangesNothing;

  function Run(const Paired: string; Smooth: Boolean): TJSONObject;
  begin
    if Smooth then
      FOptimizerExtra := IRREGULAR_NEAR_START + ',"period_smooth":true'
    else
      FOptimizerExtra := IRREGULAR_NEAR_START;
    try
      Result := RunFit(9, SyntheticCurveJSON, IRREGULAR_FREE,
        ',"mode":"irregular"' + Paired + IRREGULAR_BOUNDS);
    finally
      FOptimizerExtra := '';
    end;
  end;

var
  A, B: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  A := Run(',"paired":["thickness","sigma","density"]', False);
  try
    B := Run(',"paired":["thickness","sigma","density"]', True);
    try
      Assert.AreEqual(A.GetValue<Double>('chi2'), B.GetValue<Double>('chi2'), 0.0);
      Assert.AreEqual(A.GetValue<TJSONObject>('fitted_structure').ToJSON,
                      B.GetValue<TJSONObject>('fitted_structure').ToJSON);
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;

  A := Run('', False);
  try
    B := Run('', True);
    try
      Assert.AreNotEqual(A.GetValue<TJSONObject>('fitted_structure').ToJSON,
                         B.GetValue<TJSONObject>('fitted_structure').ToJSON,
        'with nothing paired the smoothing changes the fit');
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
end;

{ A continuation: the fitted_structure of one irregular fit, sent back with
  "start_profiles", starts the next fit from every period's own value, so its
  chi2_start is the first fit's chi2. Without the flag the GUI's Run would
  start every period from period 1's value instead. }
procedure TTestMCPFit.Irregular_StartProfiles_ContinueFromAPreviousFit;
var
  Res, Res2: TJSONObject;
  Fitted: string;
  Chi2: Double;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  FOptimizerExtra := IRREGULAR_NEAR_START;
  try
    Res := RunFit(5, SyntheticCurveJSON, IRREGULAR_FREE,
      ',"mode":"irregular","paired":["density"]' + IRREGULAR_BOUNDS,
      PROFILE_POPULATION, PROFILE_ITERATIONS);
  finally
    FOptimizerExtra := '';
  end;
  try
    Chi2 := Res.GetValue<Double>('chi2');
    Assert.IsTrue(Chi2 < Res.GetValue<Double>('chi2_start'),
      'the first fit moved, so the periods differ');
    Fitted := Res.GetValue('fitted_structure').ToJSON;
  finally
    Res.Free;
  end;

  Res2 := RunFit(1, SyntheticCurveJSON, IRREGULAR_FREE,
    ',"mode":"irregular","paired":["density"],"start_profiles":true' + IRREGULAR_BOUNDS,
    FIT_POPULATION, 1, Fitted);
  try
    Assert.IsTrue(Res2.GetValue<Boolean>('start_profiles'));
    Assert.AreEqual(Chi2, Res2.GetValue<Double>('chi2_start'), 1E-3 * Chi2,
      'the continuation starts where the first fit ended');
    Assert.IsTrue(Res2.GetValue<Double>('chi2') <= Res2.GetValue<Double>('chi2_start'),
      'and does not end worse than it started');
    Assert.AreEqual(10, ArrayOfLayer(Res2, 'start_structure', 0, 'thickness_profile').Count,
      'start_structure reports the table it started from');
  finally
    Res2.Free;
  end;
end;

procedure TTestMCPFit.Schema_DescribesIrregularMode;
begin
  Assert.IsTrue(FitXrrSchemaValue('mode.description').Contains('TLFPSO_Irregular'));
  Assert.IsTrue(FitXrrSchemaValue('paired.description').Contains('irregular'));
  Assert.IsTrue(FitXrrSchemaValue('start_profiles.description').Contains('thickness_profile'));
  Assert.IsTrue(FitXrrSchemaValue('optimizer.properties.period_smooth.description')
    .Contains('irregular'));
  Assert.IsTrue(FitXrrSchemaValue('optimizer.properties.period_smooth_window.description')
    .Contains('automatic'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPFit);

end.
