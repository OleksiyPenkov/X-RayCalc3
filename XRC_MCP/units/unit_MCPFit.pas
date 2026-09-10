unit unit_MCPFit;

(* The fit_xrr job: the GUI's LFPSO, driven headless.

   TCalcOrchestrator.PrepareLFPSO / RunFitting / FinalizeFitting do this in the
   GUI; everything here is the same sequence with the forms taken out. The
   engine is unmodified - the same TLFPSO_Periodic (or TLFPSO_Poly), the same
   TCalc, and therefore the same chi-squared as the number the GUI shows.

   What the client hands over is parsed and validated synchronously by
   ParseFitRequest, on the calling thread, so that a bad bound or an unreadable
   measurement is an error on the submitting call rather than a job that fails a
   minute later. RunFitJob then runs on the job worker and touches nothing but
   its own job folder.

   Three engine properties shape the contract and are worth knowing before
   reading the code:

   - The substrate is not in the particle vector. TLFPSO_BASE.FillModel copies
     FStructure.Subs.P verbatim, and Set_Init_X is called for stack layers only,
     so substrate sigma and density cannot be fitted. Nor can scale, background
     or resolution: the engine has no such parameters. Asking for any of them is
     refused with not_fittable. "scale" is instead a fixed multiplier the client
     applies to the measured intensities (ApplyScale), echoed and stored.
   - A parameter is "fixed" by giving it an empty range. Xrange = max - min = 0
     makes Rand(0) return 0 in XSeed and RangeSeed, and CheckLimits clamps to
     [Xmin, Xmax], so the value never moves. Free parameters get a real range,
     everything else keeps min = max = V as StructureFromJSON left it. Both
     engines seed the swarm AROUND the start value and clamp to the bounds, so
     a start outside its bounds would be fitted from the bound - and in a
     profile fit never beaten, because the reference particle keeps the start.
     Hence two rules: an omitted density (the 0 sentinel) is replaced by the
     bulk value before "free" and "bounds" are read (FillEngineDensities), and
     a start value outside its bounds is refused (CheckStartInsideBounds).
   - TLFPSO_Periodic.NormalizeD rescales the layers of every periodic stack after
     each move so that the period stays exactly what the start model had, unless
     SetPeriodRange opened that stack's period ("target":"period" in "free"):
     then the layers are rescaled only when their sum leaves the range. Fitting
     the thicknesses of a periodic stack without freeing its period therefore
     fits the ratio, not the period. TLFPSO_Poly never holds the period at all
     (it has no NormalizeD), so a profile fit lets it float within the thickness
     bounds and the result reports "floating".

   Cancellation is observed once per iteration, in the OnProgress callback: the
   engine offers no other point at which it can be stopped. A cancelled run
   leaves no result (the job manager then records it as cancelled) but keeps
   every file it had already written. *)

interface

uses
  System.JSON,
  unit_Types, unit_MCPStructure, unit_MCPJobs;

const
  { The chi-squared TCalc.CalcChiSquare computes, which is the number this job
    minimises and the number the GUI displays. describe_server aliases this
    constant rather than restating it, so the two can never drift apart. }
  FIT_CHI2_DEFINITION =
    '1000/(n-1) * sum(((log10 I_meas - log10 R_calc)/log10 R_calc)^2 * w_point * w_theta) ' +
    'over the points i = tail .. n-2-tail of the n measured points, skipping any ' +
    'with R_calc = 0; tail is the half-width in points of the resolution ' +
    'convolution (0 when resolution = 0); w_point = I/movavg(I) where that ratio ' +
    'exceeds 3 and 1 otherwise (point_weight=true); w_theta from theta_weight ' +
    '0..5 as in the GUI. This is TCalc.CalcChiSquare, the number X-Ray Calc 3 ' +
    'displays.';

  { Said in every result: the two parameters a client coming from another
    refinement program looks for first, and does not have here. }
  FIT_NO_SCALE_NOTE =
    'scale is a fixed multiplier the client chose ("scale" argument), applied ' +
    'to the measured intensities before the fit and stored with them in ' +
    'measured.dat and fit.xrcx; the GUI engine (v1) fits neither scale nor ' +
    'background';

  // Argument defaults, all of them the brief's.
  DEF_RESOLUTION   = 0.015;    // theta FWHM, degrees
  DEF_POPULATION   = 100;
  DEF_ITERATIONS   = 100;
  DEF_TOLERANCE    = 0.005;
  DEF_JAMMING_MAX  = 1;
  DEF_REINIT_MAX   = 3;
  DEF_K_CHI        = 1.41;
  DEF_K_VMAX       = 1.41;
  DEF_W1           = 0.3;
  DEF_W2           = 0.3;
  DEF_VMAX         = 0.3;
  DEF_KSXR         = 0.2;
  DEF_POLY_FACTOR  = 10;
  DEF_POLY_ORDER   = 1;
  DEF_MOVAVG       = 0.05;
  DEF_R_MIN        = 1E-7;
  DEF_INLINE_MAX   = 2000;

  { The range a free parameter gets when no explicit bound is given: the start
    value plus and minus this fraction of it. }
  DEF_FREE_DEVIATION = 0.30;

  /// Largest measured curve a fit will accept. Every particle of every
  /// iteration is evaluated at every point, so this is the single biggest lever
  /// on how long a run takes; it is the same ceiling calc_reflectivity uses.
  MAX_FIT_POINTS = 100000;
  /// The engine smooths the last MVAWindow points of a convolved curve.
  FIT_MVA_WINDOW = 10;

type
  /// <summary>One fitted parameter: where it is in the client's JSON, where it
  /// is in the GUI structure, and the range the engine searched.</summary>
  TFitParamRef = record
    StackLabel: string;     // 'cap' | 'buffer', '' when addressed by index
    StackJSON: Integer;     // index in the JSON "stacks" array, -1 for cap/buffer
    LayerJSON: Integer;     // index in that stack's "layers" array
    GUIStack: Integer;      // index in TFitStructure.Stacks
    GUILayer: Integer;
    P: Integer;             // 1 thickness, 2 sigma, 3 density
    Min, Max: Double;
  end;

  /// <summary>One repeating stack whose period is free: the engine lets the
  /// sum of its layer thicknesses move inside [Min, Max] instead of holding
  /// it at StartD.</summary>
  TPeriodRef = record
    StackJSON: Integer;     // index in the JSON "stacks" array
    GUIStack: Integer;      // index in TFitStructure.Stacks
    StartD: Double;         // the start model's period, Angstrom
    Min, Max: Double;
  end;

  /// <summary>Everything one fit_xrr call asks for, fully validated. The job
  /// body needs no JSON and no work directory lookups.</summary>
  TFitRequest = record
    MeasurementId: string;              // '' for an inline curve
    DataTitle: string;                  // the measurement id, or 'inline'
    Data: unit_Types.TDataArray;        // theta (deg), I - already range-restricted
    Lambda: Double;
    ThetaMin, ThetaMax: Double;         // the range of Data, after restriction
    Resolution: Double;                 // theta FWHM in degrees, 0 = no convolution
    RMin: Double;
    Polarization: unit_Types.TPolarisation;
    PolarizationName: string;           // as echoed: 's' or 'sp'
    Structure: TFitStructure;           // the start model, bounds applied
    Info: TStructureInfo;
    FreeParams: TArray<TFitParamRef>;        // the free parameters, in argument order
    Fit: TFitParams;
    PointWeight: Boolean;
    Profile: Boolean;                   // TLFPSO_Poly rather than TLFPSO_Periodic
    InlineMax: Integer;
    Scale: Double;                      // fixed multiplier already applied to Data
    PeriodRefs: TArray<TPeriodRef>;     // repeating stacks whose period is free
  end;

/// <summary>Parses and validates one fit_xrr argument object. Raises
/// EMCPError - invalid_argument, invalid_structure, unknown_material,
/// not_found or not_fittable - for anything it cannot run.</summary>
function ParseFitRequest(const Params: TJSONObject): TFitRequest;

/// <summary>The job body. Runs the LFPSO to completion on the worker thread,
/// writes measured.dat, calc.dat, residual.dat and fit.xrcx into the job
/// folder and leaves the result in Job.ResultObj. A cancelled run returns
/// without a result.</summary>
procedure RunFitJob(Job: TJob; const Req: TFitRequest);

implementation

uses
  System.SysUtils, System.Math, System.IOUtils,
  unit_materials, unit_calc, unit_DataProcessing,
  unit_LFPSO_Base, unit_LFPSO_Periodic, unit_LFPSO_Poly,
  unit_MCPCalc, unit_MCPErrors, unit_MCPInbox, unit_MCPProjectFile,
  unit_MCPSandbox, unit_MCPUnits;

const
  { The names section 3 of the requirements uses for the three per-layer
    parameters, indexed by TLayerData.P. }
  PARAM_NAMES: array [1 .. 3] of string = ('thickness', 'sigma', 'density');

  { free/bounds targets that name a parameter the GUI engine does not have. Each
    is refused with not_fittable rather than ignored. }
  NOT_FITTABLE_NOTE =
    'The GUI engine v1 fits layer thickness, sigma and density, and the '    +
    'period of a repeating stack. The substrate is not in the particle '     +
    'vector (TLFPSO_BASE.FillModel copies Subs.P verbatim) and the engine '  +
    'has no scale, background or resolution parameter - resolution is the '  +
    'fixed convolution width and "scale" a fixed multiplier of the data.';

  { How far chi2_recalc may sit from the chi-squared the engine finished on
    before the result says so. They are the same calculation on the same model,
    so anything above rounding is a real disagreement. }
  CHI2_CONSISTENCY_TOLERANCE = 1E-4;

{ ------------------------------------------------------------- small helpers -- }

function FitFmt: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

/// 's' -> cmS; 'p' and 'sp' -> cmSP, as calc_reflectivity does. The engine has
/// no pure-p path, so a client asking for 'p' reads back 'sp'.
function ParseFitPolarization(const S: string; out Effective: string): unit_Types.TPolarisation;
begin
  if SameText(S, 's') then
  begin
    Effective := 's';
    Exit(cmS);
  end;
  if SameText(S, 'p') or SameText(S, 'sp') then
  begin
    Effective := 'sp';
    Exit(cmSP);
  end;
  raise EMCPError.Create('invalid_argument',
    '"polarization" must be "s", "p" or "sp"', S);
end;

function ParameterIndex(const Name: string; const Path: string): Integer;
var
  p: Integer;
begin
  for p := 1 to 3 do
    if SameText(Name, PARAM_NAMES[p]) then
      Exit(p);
  raise EMCPError.Create('invalid_argument',
    Format('%s must be one of "thickness", "sigma", "density"', [Path]), Name);
end;

/// The address of a GUI stack index as the client wrote it: "cap", "buffer" or
/// the index in the JSON "stacks" array. Caller owns the value.
function StackAddress(const Info: TStructureInfo; GUIStack: Integer): TJSONValue;
var
  k: Integer;
begin
  if (Info.CapIndex >= 0) and (GUIStack = Info.CapIndex) then
    Exit(TJSONString.Create('cap'));
  if (Info.BufferIndex >= 0) and (GUIStack = Info.BufferIndex) then
    Exit(TJSONString.Create('buffer'));
  for k := 0 to High(Info.StackMap) do
    if Info.StackMap[k] = GUIStack then
      Exit(TJSONNumber.Create(k));
  Result := TJSONNumber.Create(GUIStack);
end;

{ --------------------------------------------------------------- the data -- }

/// [[theta, I], ...] as the client wrote it. Intensities must be positive: the
/// chi-squared takes their base-10 logarithm.
function CurveFromJSON(const A: TJSONArray): unit_Types.TDataArray;
var
  i: Integer;
  Row: TJSONArray;
begin
  SetLength(Result, A.Count);
  for i := 0 to A.Count - 1 do
  begin
    if not (A.Items[i] is TJSONArray) then
      raise EMCPError.Create('invalid_argument',
        Format('curve[%d] must be a [theta, intensity] pair', [i]));
    Row := TJSONArray(A.Items[i]);
    if (Row.Count < 2) or not (Row.Items[0] is TJSONNumber)
                       or not (Row.Items[1] is TJSONNumber) then
      raise EMCPError.Create('invalid_argument',
        Format('curve[%d] must be a [theta, intensity] pair of numbers', [i]));
    Result[i].t := TJSONNumber(Row.Items[0]).AsDouble;
    Result[i].r := TJSONNumber(Row.Items[1]).AsDouble;
    if not (Result[i].r > 0) then
      raise EMCPError.Create('invalid_argument',
        Format('curve[%d]: the intensity must be greater than zero - the ' +
               'chi-squared is computed on log10(I)', [i]),
        FloatToStr(Result[i].r, FitFmt));
  end;
end;

/// The points of C inside [AMin, AMax]. The bounds are inclusive; a range that
/// keeps nothing is an argument error, not an empty fit.
function RestrictToRange(const C: unit_Types.TDataArray;
  AMin, AMax: Double): unit_Types.TDataArray;
var
  i, n: Integer;
begin
  SetLength(Result, Length(C));
  n := 0;
  for i := 0 to High(C) do
    if (C[i].t >= AMin) and (C[i].t <= AMax) then
    begin
      Result[n] := C[i];
      Inc(n);
    end;
  SetLength(Result, n);
end;

/// The engine convolves over a fixed +/- 0.1 degree window and smooths the last
/// FIT_MVA_WINDOW points; a grid too coarse or too short for that would make it
/// index outside its own result array. Mirrors unit_MCPCalc.CheckConvolutionFits
/// for a grid that comes from the data rather than from a point count.
procedure CheckResolutionFits(const Data: unit_Types.TDataArray; Resolution: Double);
const
  TOO_FEW =
    'Too few points for the requested resolution: the convolution needs a ' +
    'window of +/-0.1 degree, which does not fit this measured grid. Widen ' +
    'theta_range, use a finer measurement, or set "resolution": 0.';
var
  Delta: Double;
  N: Integer;
begin
  if Resolution <= 0 then
    Exit;
  Delta := (Data[High(Data)].t - Data[0].t) / Length(Data);
  if Delta <= 0 then
    Exit;
  N := Round(0.1 / Delta);
  if Frac(N / 2) = 0 then
    Dec(N);                          // the engine forces an odd half-window
  if (N < 1) or (2 * N + FIT_MVA_WINDOW + 2 >= Length(Data)) then
    raise EMCPError.Create('invalid_argument', TOO_FEW,
      Format('%d points, theta range %.4g deg, step %.4g deg: the convolution ' +
             'window is %d points',
             [Length(Data), Data[High(Data)].t - Data[0].t, Delta, 2 * N + 1],
             FitFmt));
end;

/// The measured curve and the wavelength that goes with it. Fills
/// MeasurementId, DataTitle, Data and Lambda; the range restriction is applied
/// by the caller, which knows theta_range.
procedure FillEngineDensities(var S: TFitStructure; Lambda: Double); forward;

procedure ReadMeasuredCurve(const Params: TJSONObject; var Req: TFitRequest);
var
  M: TMeasurement;
  HasId, HasCurve: Boolean;
begin
  HasId := JSONArgs.Has(Params, 'measurement_id');
  HasCurve := JSONArgs.Has(Params, 'curve');

  if HasId and HasCurve then
    raise EMCPError.Create('invalid_argument',
      'Give either "measurement_id" or "curve", not both');
  if not (HasId or HasCurve) then
    raise EMCPError.Create('invalid_argument',
      'Give either "measurement_id" (a curve in the inbox) or "curve" ' +
      '([[theta, intensity], ...])');

  if HasId then
  begin
    // MaxPoints 0: a fit reads the whole curve, never a decimated one.
    M := LoadMeasurement(JSONArgs.ReqStr(Params, 'measurement_id'), 0);
    try
      Req.MeasurementId := M.Id;
      Req.DataTitle := M.Id;
      Req.Data := M.Curve;
      Req.Lambda := GetLambdaArg(Params, 'lambda', 'energy', True, M.Meta.Lambda);
      if Req.Lambda <= 0 then
        raise EMCPError.Create('invalid_argument',
          Format('"%s" has no wavelength: give "lambda" or "energy", or put ' +
                 '"lambda" in the specimen''s meta.json', [M.Id]));
    finally
      M.Meta.Raw.Free;
    end;
  end
  else
  begin
    Req.MeasurementId := '';
    Req.DataTitle := 'inline';
    Req.Data := CurveFromJSON(JSONArgs.ReqArr(Params, 'curve'));
    Req.Lambda := GetLambdaArg(Params);      // required with an inline curve
  end;
end;

/// "scale": a fixed multiplier the client applies to the measured intensities
/// before the fit - the wiki's "normalise to the total-reflection plateau" -
/// default 1. It is not fitted; the scaled curve is what the chi-squared, the
/// files and the .xrcx see, so the GUI shows the same data.
procedure ApplyScale(const Params: TJSONObject; var Req: TFitRequest);
var
  i: Integer;
begin
  Req.Scale := JSONArgs.OptFloat(Params, 'scale', 1.0);
  if Req.Scale <= 0 then
    raise EMCPError.Create('invalid_argument',
      '"scale" must be greater than zero: it multiplies the measured intensities',
      FloatToStr(Req.Scale, TFormatSettings.Invariant));
  if Req.Scale <> 1.0 then
    for i := 0 to High(Req.Data) do
      Req.Data[i].r := Req.Data[i].r * Req.Scale;
end;

/// theta_range {min, max}, defaulting to the range of the data, applied to the
/// curve. Leaves Req.Data restricted and Req.ThetaMin / ThetaMax on the range
/// the restricted curve actually spans.
procedure ApplyThetaRange(const Params: TJSONObject; var Req: TFitRequest);
var
  JRange: TJSONObject;
  Lo, Hi: Double;
  i: Integer;
begin
  if Length(Req.Data) < 2 then
    raise EMCPError.Create('invalid_argument',
      'The measured curve must hold at least two points',
      IntToStr(Length(Req.Data)));

  for i := 1 to High(Req.Data) do
    if Req.Data[i].t < Req.Data[i - 1].t then
      raise EMCPError.Create('invalid_argument',
        'The measured curve must be ordered by increasing theta',
        Format('point %d: theta %.6g after %.6g',
               [i, Req.Data[i].t, Req.Data[i - 1].t], FitFmt));

  Lo := Req.Data[0].t;
  Hi := Req.Data[High(Req.Data)].t;

  JRange := JSONArgs.OptObj(Params, 'theta_range');
  if JRange <> nil then
  begin
    Lo := JSONArgs.OptFloat(JRange, 'min', Lo);
    Hi := JSONArgs.OptFloat(JRange, 'max', Hi);
    if Hi <= Lo then
      raise EMCPError.Create('invalid_argument',
        '"theta_range.max" must be greater than "theta_range.min"');
    Req.Data := RestrictToRange(Req.Data, Lo, Hi);
  end;

  if Length(Req.Data) < 2 then
    raise EMCPError.Create('invalid_argument',
      '"theta_range" keeps fewer than two measured points',
      Format('%.6g to %.6g deg', [Lo, Hi], FitFmt));
  if Length(Req.Data) > MAX_FIT_POINTS then
    raise EMCPError.Create('invalid_argument',
      Format('A fit reads at most %d points; narrow "theta_range"', [MAX_FIT_POINTS]),
      IntToStr(Length(Req.Data)));

  Req.ThetaMin := Req.Data[0].t;
  Req.ThetaMax := Req.Data[High(Req.Data)].t;
end;

{ ------------------------------------------------------- free and bounds -- }

/// One "stack" value - an index into the JSON stacks array, or "cap"/"buffer" -
/// resolved against the structure that was just parsed.
procedure ResolveStack(const JEntry: TJSONObject; const Info: TStructureInfo;
  const Path: string; var Ref: TFitParamRef);
var
  V: TJSONValue;
  S: string;
  k: Integer;
begin
  V := JEntry.FindValue('stack');
  if (V = nil) or (V is TJSONNull) then
    raise EMCPError.Create('invalid_argument',
      Format('%s needs a "stack": an index into "stacks", or "cap" or "buffer"',
             [Path]));

  Ref.StackLabel := '';
  Ref.StackJSON := -1;

  if V is TJSONString then
  begin
    S := Trim(V.Value);
    if SameText(S, 'cap') then
    begin
      if not Info.HasCap then
        raise EMCPError.Create('invalid_argument',
          Format('%s addresses "cap" but the structure has none', [Path]));
      Ref.StackLabel := 'cap';
      Ref.GUIStack := Info.CapIndex;
      Exit;
    end;
    if SameText(S, 'buffer') then
    begin
      if not Info.HasBuffer then
        raise EMCPError.Create('invalid_argument',
          Format('%s addresses "buffer" but the structure has none', [Path]));
      Ref.StackLabel := 'buffer';
      Ref.GUIStack := Info.BufferIndex;
      Exit;
    end;
    raise EMCPError.Create('invalid_argument',
      Format('%s: "stack" must be an index, "cap" or "buffer"', [Path]), S);
  end;

  if not (V is TJSONNumber) then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "stack" must be an index, "cap" or "buffer"', [Path]));

  k := TJSONNumber(V).AsInt;
  if (k < 0) or (k > High(Info.StackMap)) then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "stack" must be between 0 and %d (stacks are numbered from ' +
             'the substrate up)', [Path, High(Info.StackMap)]), IntToStr(k));
  Ref.StackJSON := k;
  Ref.GUIStack := Info.StackMap[k];
end;

procedure ResolveLayer(const JEntry: TJSONObject; const S: TFitStructure;
  const Path: string; var Ref: TFitParamRef);
var
  j, Count: Integer;
begin
  Count := Length(S.Stacks[Ref.GUIStack].Layers);
  if Ref.StackLabel <> '' then
    j := JSONArgs.OptInt(JEntry, 'layer', 0)      // cap and buffer are one layer
  else
  begin
    if not JSONArgs.Has(JEntry, 'layer') then
      raise EMCPError.Create('invalid_argument',
        Format('%s needs a "layer": the index of the layer inside the stack', [Path]));
    j := JSONArgs.OptInt(JEntry, 'layer', 0);
  end;
  if (j < 0) or (j >= Count) then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "layer" must be between 0 and %d', [Path, Count - 1]), IntToStr(j));
  Ref.LayerJSON := j;
  Ref.GUILayer := j;
end;

/// A target the GUI engine has no parameter for. Everything the design note
/// lists under "not fittable" ends here.
procedure RefuseTarget(const Target, Path: string);
begin
  raise EMCPError.Create('not_fittable',
    Format('%s: "%s" cannot be fitted. %s', [Path, Target, NOT_FITTABLE_NOTE]),
    Target);
end;

/// The "free" array: which layer parameters take part in the fit. Order is
/// preserved so that bounds_used reads back in the order it was written.
/// One "period" entry of "free": the stack must be addressed by index and
/// repeat (N > 1). Profile fits are refused because TLFPSO_Poly never holds
/// the period - it floats within the thickness bounds - so there is nothing
/// for the target to act on. The default range is the start period +/-30%.
procedure ParsePeriodTarget(const JEntry: TJSONObject; const S: TFitStructure;
  const Info: TStructureInfo; Profile: Boolean; const Path: string;
  var Refs: TArray<TPeriodRef>);
var
  Probe: TFitParamRef;
  Ref: TPeriodRef;
  j, n: Integer;
begin
  if Profile then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "period" cannot be freed in a profile fit. TLFPSO_Poly does ' +
             'not hold the period at all - it floats within the thickness ' +
             'bounds - so bound the thicknesses instead', [Path]));

  Probe := Default(TFitParamRef);
  ResolveStack(JEntry, Info, Path, Probe);
  if Probe.StackLabel <> '' then
    raise EMCPError.Create('invalid_argument',
      Format('%s: the %s has no period; "period" needs a repeating stack ' +
             'addressed by its index', [Path, Probe.StackLabel]));
  if S.Stacks[Probe.GUIStack].N <= 1 then
    raise EMCPError.Create('invalid_argument',
      Format('%s: stack %d has N = 1 and therefore no period to fit',
             [Path, Probe.StackJSON]));
  for n := 0 to High(Refs) do
    if Refs[n].GUIStack = Probe.GUIStack then
      raise EMCPError.Create('invalid_argument',
        Format('%s: the period of stack %d is already free', [Path, Probe.StackJSON]));

  Ref := Default(TPeriodRef);
  Ref.StackJSON := Probe.StackJSON;
  Ref.GUIStack := Probe.GUIStack;
  Ref.StartD := 0;
  for j := 0 to High(S.Stacks[Probe.GUIStack].Layers) do
    Ref.StartD := Ref.StartD + S.Stacks[Probe.GUIStack].Layers[j].P[1].V;
  if Ref.StartD <= 0 then
    raise EMCPError.Create('invalid_argument',
      Format('%s: stack %d has no thickness to scale', [Path, Probe.StackJSON]));
  Ref.Min := Ref.StartD * (1 - DEF_FREE_DEVIATION);
  Ref.Max := Ref.StartD * (1 + DEF_FREE_DEVIATION);
  Refs := Refs + [Ref];
end;

function ParseFree(const Params: TJSONObject; const S: TFitStructure;
  const Info: TStructureInfo; Profile: Boolean;
  out PeriodRefs: TArray<TPeriodRef>): TArray<TFitParamRef>;
var
  A, JParams: TJSONArray;
  JEntry: TJSONObject;
  i, k, p, n: Integer;
  Target, Path: string;
  Ref: TFitParamRef;
  HasThickness: Boolean;
begin
  SetLength(Result, 0);
  SetLength(PeriodRefs, 0);
  A := JSONArgs.OptArr(Params, 'free');
  if A = nil then
    raise EMCPError.Create('invalid_argument',
      '"free" must list at least one parameter to fit');

  for i := 0 to A.Count - 1 do
  begin
    Path := Format('free[%d]', [i]);
    if not (A.Items[i] is TJSONObject) then
      raise EMCPError.Create('invalid_argument', Path + ' must be an object');
    JEntry := TJSONObject(A.Items[i]);

    Target := LowerCase(Trim(JSONArgs.OptStr(JEntry, 'target', 'layer')));
    if (Target = 'substrate') or (Target = 'scale') or (Target = 'background') or
       (Target = 'resolution') then
      RefuseTarget(Target, Path);
    if Target = 'period' then
    begin
      ParsePeriodTarget(JEntry, S, Info, Profile, Path, PeriodRefs);
      Continue;
    end;
    if Target <> 'layer' then
      raise EMCPError.Create('invalid_argument',
        Format('%s: "target" must be "layer" or "period"', [Path]), Target);

    Ref := Default(TFitParamRef);
    ResolveStack(JEntry, Info, Path, Ref);
    ResolveLayer(JEntry, S, Path, Ref);

    JParams := JSONArgs.OptArr(JEntry, 'parameters');
    if (JParams = nil) or (JParams.Count = 0) then
      raise EMCPError.Create('invalid_argument',
        Format('%s needs "parameters": any of "thickness", "sigma", "density"', [Path]));

    for k := 0 to JParams.Count - 1 do
    begin
      if not (JParams.Items[k] is TJSONString) then
        raise EMCPError.Create('invalid_argument',
          Format('%s.parameters[%d] must be a parameter name', [Path, k]));
      p := ParameterIndex(JParams.Items[k].Value,
                          Format('%s.parameters[%d]', [Path, k]));

      for n := 0 to High(Result) do
        if (Result[n].GUIStack = Ref.GUIStack) and (Result[n].GUILayer = Ref.GUILayer)
           and (Result[n].P = p) then
          raise EMCPError.Create('invalid_argument',
            Format('%s.parameters[%d]: this parameter is already free', [Path, k]),
            PARAM_NAMES[p]);

      Ref.P := p;
      Ref.Min := 0;
      Ref.Max := 0;
      Result := Result + [Ref];
    end;
  end;

  if Length(Result) = 0 then
    raise EMCPError.Create('invalid_argument',
      '"free" must list at least one layer parameter to fit');

  { The period is the sum of the stack's layer thicknesses: the engine moves
    it by moving them, so a stack with every thickness held could not follow. }
  for n := 0 to High(PeriodRefs) do
  begin
    HasThickness := False;
    for i := 0 to High(Result) do
      if (Result[i].GUIStack = PeriodRefs[n].GUIStack) and (Result[i].P = 1) then
        HasThickness := True;
    if not HasThickness then
      raise EMCPError.Create('invalid_argument',
        Format('"period" of stack %d is free but none of its layer thicknesses ' +
               'is: free at least one "thickness" in that stack, or the period ' +
               'could not move', [PeriodRefs[n].StackJSON]));
  end;
end;

/// The default range of a free parameter: the start value plus and minus
/// DEF_FREE_DEVIATION of it, with sigma and density held at or above zero. A
/// start value of zero has no such range - a sigma of 0; an omitted density
/// has already been replaced by the bulk value by the time this runs - so it
/// is refused rather than turned into a fixed parameter the client believes
/// is free.
procedure DefaultBounds(const V: Single; P: Integer; const Where: string;
  out AMin, AMax: Double);
begin
  if V = 0 then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "%s" starts at 0, so the default +/-%d%% range is empty. ' +
             'Give explicit bounds for it.',
             [Where, PARAM_NAMES[P], Round(DEF_FREE_DEVIATION * 100)]));
  AMin := V * (1 - DEF_FREE_DEVIATION);
  AMax := V * (1 + DEF_FREE_DEVIATION);
  if (P <> 1) and (AMin < 0) then
    AMin := 0;
end;

/// Checks one explicit bound pair and stores it. Thickness must stay positive
/// (the engine builds a layer from it); sigma and density are clamped at zero.
///
/// The clamp happens first and the range is checked afterwards, on the values
/// that will actually be used. The other order lets a negative pair through:
/// min -5, max -1 passes "max greater than min" and then clamps to 0 .. -1,
/// and min -5, max 0 clamps to an empty 0 .. 0 - a parameter the client
/// believes is free that the engine holds still, which for a density is the
/// "use the Henke bulk value" sentinel and so does not even show up as an
/// obviously wrong number.
procedure SetExplicitBounds(var Ref: TFitParamRef; AMin, AMax: Double;
  const Path: string);
var
  Clamped: Boolean;
  AsGiven: Double;
begin
  AsGiven := AMin;
  Clamped := False;
  if Ref.P = 1 then
  begin
    if AMin <= 0 then
      raise EMCPError.Create('invalid_argument',
        Format('%s: a thickness bound must be greater than zero', [Path]),
        FloatToStr(AMin, FitFmt));
  end
  else if AMin < 0 then
  begin
    AMin := 0;
    Clamped := True;
  end;

  if AMax <= AMin then
    if Clamped then
      raise EMCPError.Create('invalid_argument',
        Format('%s: "%s" cannot be negative, so the range is empty once "min" ' +
               'is clamped to zero', [Path, PARAM_NAMES[Ref.P]]),
        Format('min %.6g (clamped to 0), max %.6g', [AsGiven, AMax], FitFmt))
    else
      raise EMCPError.Create('invalid_argument',
        Format('%s: "max" must be greater than "min"', [Path]),
        Format('min %.6g, max %.6g', [AMin, AMax], FitFmt));

  Ref.Min := AMin;
  Ref.Max := AMax;
end;

/// The "bounds" array, matched against the free parameters. A bound that names
/// a parameter which is not free would silently do nothing, so it is an error.
/// A period bound: {"target":"period","stack":k,"min":..,"max":..}, with an
/// optional "parameter":"period". The stack's period must be free.
procedure ParsePeriodBound(const JEntry: TJSONObject; const Info: TStructureInfo;
  const Path: string; var PeriodRefs: TArray<TPeriodRef>);
var
  Probe: TFitParamRef;
  n, Hit: Integer;
  AMin, AMax: Double;
  ParamName: string;
begin
  ParamName := LowerCase(Trim(JSONArgs.OptStr(JEntry, 'parameter', 'period')));
  if ParamName <> 'period' then
    raise EMCPError.Create('invalid_argument',
      Format('%s: a "period" bound takes no "parameter" other than "period"',
             [Path]), ParamName);

  Probe := Default(TFitParamRef);
  ResolveStack(JEntry, Info, Path, Probe);
  if Probe.StackLabel <> '' then
    raise EMCPError.Create('invalid_argument',
      Format('%s: the %s has no period', [Path, Probe.StackLabel]));

  Hit := -1;
  for n := 0 to High(PeriodRefs) do
    if PeriodRefs[n].GUIStack = Probe.GUIStack then
      Hit := n;
  if Hit < 0 then
    raise EMCPError.Create('invalid_argument',
      Format('%s bounds the period of stack %d, which is not in "free"; a ' +
             'bound on a held period would have no effect',
             [Path, Probe.StackJSON]));

  AMin := JSONArgs.ReqFloat(JEntry, 'min');
  AMax := JSONArgs.ReqFloat(JEntry, 'max');
  if AMin <= 0 then
    raise EMCPError.Create('invalid_argument',
      Format('%s: a period bound must be greater than zero', [Path]));
  if AMax <= AMin then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "max" must be greater than "min"', [Path]));
  PeriodRefs[Hit].Min := AMin;
  PeriodRefs[Hit].Max := AMax;
end;

procedure ParseBounds(const Params: TJSONObject; const S: TFitStructure;
  const Info: TStructureInfo; var Refs: TArray<TFitParamRef>;
  var PeriodRefs: TArray<TPeriodRef>);
var
  A: TJSONArray;
  JEntry: TJSONObject;
  i, n, Hit: Integer;
  Target, Path: string;
  Probe: TFitParamRef;
  Given: TArray<Boolean>;
begin
  SetLength(Given, Length(Refs));

  A := JSONArgs.OptArr(Params, 'bounds');
  if A <> nil then
    for i := 0 to A.Count - 1 do
    begin
      Path := Format('bounds[%d]', [i]);
      if not (A.Items[i] is TJSONObject) then
        raise EMCPError.Create('invalid_argument', Path + ' must be an object');
      JEntry := TJSONObject(A.Items[i]);

      Target := LowerCase(Trim(JSONArgs.OptStr(JEntry, 'target', 'layer')));
      if (Target = 'substrate') or (Target = 'scale') or (Target = 'background') or
         (Target = 'resolution') then
        RefuseTarget(Target, Path);
      if Target = 'period' then
      begin
        ParsePeriodBound(JEntry, Info, Path, PeriodRefs);
        Continue;
      end;
      if Target <> 'layer' then
        raise EMCPError.Create('invalid_argument',
          Format('%s: "target" must be "layer" or "period"', [Path]), Target);

      Probe := Default(TFitParamRef);
      ResolveStack(JEntry, Info, Path, Probe);
      ResolveLayer(JEntry, S, Path, Probe);
      Probe.P := ParameterIndex(JSONArgs.ReqStr(JEntry, 'parameter'),
                                Path + '.parameter');

      Hit := -1;
      for n := 0 to High(Refs) do
        if (Refs[n].GUIStack = Probe.GUIStack) and (Refs[n].GUILayer = Probe.GUILayer)
           and (Refs[n].P = Probe.P) then
          Hit := n;
      if Hit < 0 then
        raise EMCPError.Create('invalid_argument',
          Format('%s bounds "%s" of a layer that is not in "free"; a bound on a ' +
                 'fixed parameter would have no effect',
                 [Path, PARAM_NAMES[Probe.P]]));

      SetExplicitBounds(Refs[Hit],
        JSONArgs.ReqFloat(JEntry, 'min'), JSONArgs.ReqFloat(JEntry, 'max'), Path);
      Given[Hit] := True;
    end;

  for n := 0 to High(Refs) do
    if not Given[n] then
      DefaultBounds(S.Stacks[Refs[n].GUIStack].Layers[Refs[n].GUILayer].P[Refs[n].P].V,
        Refs[n].P, Format('free parameter "%s"', [PARAM_NAMES[Refs[n].P]]),
        Refs[n].Min, Refs[n].Max);
end;

/// A free parameter must start inside its range. Both engines seed the swarm
/// around the start value and clamp to the bounds (TLFPSO_Periodic.XSeed,
/// TLFPSO_Poly.CheckLimitsP), so a start outside them would be fitted from
/// the nearest bound, not from the model the client gave - and in a profile
/// fit the reference particle keeps the out-of-range start, so nothing ever
/// beats it. Refuse it instead.
procedure CheckStartInsideBounds(const S: TFitStructure;
  const Refs: TArray<TFitParamRef>; const PeriodRefs: TArray<TPeriodRef>);
var
  n: Integer;
  V: Double;
  Where: string;
begin
  for n := 0 to High(PeriodRefs) do
    if (PeriodRefs[n].StartD < PeriodRefs[n].Min) or
       (PeriodRefs[n].StartD > PeriodRefs[n].Max) then
      raise EMCPError.Create('invalid_argument',
        Format('the start period %.6g A of stack %d lies outside its bounds ' +
               '[%.6g, %.6g]: move the start model or widen the bounds',
               [PeriodRefs[n].StartD, PeriodRefs[n].StackJSON,
                PeriodRefs[n].Min, PeriodRefs[n].Max]), 'period');

  for n := 0 to High(Refs) do
  begin
    V := S.Stacks[Refs[n].GUIStack].Layers[Refs[n].GUILayer].P[Refs[n].P].V;
    if (V < Refs[n].Min) or (V > Refs[n].Max) then
    begin
      if Refs[n].StackLabel <> '' then
        Where := Refs[n].StackLabel
      else
        Where := Format('stack %d, layer %d', [Refs[n].StackJSON, Refs[n].LayerJSON]);
      raise EMCPError.Create('invalid_argument',
        Format('the start value %.6g of "%s" (%s) lies outside its bounds ' +
               '[%.6g, %.6g]. The engine seeds the swarm around the start ' +
               'value and clamps it to the bounds, so it would fit from the ' +
               'bound and not from the model given: move the start value or ' +
               'widen the bounds',
               [V, PARAM_NAMES[Refs[n].P], Where, Refs[n].Min, Refs[n].Max]),
        PARAM_NAMES[Refs[n].P]);
    end;
  end;
end;

/// Opens the range of every free parameter. Everything else keeps the
/// min = max = V that StructureFromJSON left it with, which is how the engine
/// is told to hold it fixed.
procedure ApplyBounds(var S: TFitStructure; const Refs: TArray<TFitParamRef>);
var
  n: Integer;
begin
  for n := 0 to High(Refs) do
  begin
    S.Stacks[Refs[n].GUIStack].Layers[Refs[n].GUILayer].P[Refs[n].P].min := Refs[n].Min;
    S.Stacks[Refs[n].GUIStack].Layers[Refs[n].GUILayer].P[Refs[n].P].max := Refs[n].Max;
  end;
end;

{ ---------------------------------------------------------- the optimizer -- }

function ParseFitParams(const Params: TJSONObject): TFitParams;
var
  JOpt, JChi: TJSONObject;
begin
  JOpt := JSONArgs.OptObj(Params, 'optimizer');
  JChi := JSONArgs.OptObj(Params, 'chi2');

  Result := Default(TFitParams);
  Result.Pop             := JSONArgs.OptInt(JOpt, 'population', DEF_POPULATION);
  Result.NMax            := JSONArgs.OptInt(JOpt, 'iterations', DEF_ITERATIONS);
  Result.Tolerance       := JSONArgs.OptFloat(JOpt, 'tolerance', DEF_TOLERANCE);
  Result.Shake           := JSONArgs.OptBool(JOpt, 'shake', True);
  Result.RangeSeed       := JSONArgs.OptBool(JOpt, 'range_seed', True);
  Result.JammingMax      := JSONArgs.OptInt(JOpt, 'jamming_max', DEF_JAMMING_MAX);
  Result.ReInitMax       := JSONArgs.OptInt(JOpt, 'reinit_max', DEF_REINIT_MAX);
  Result.KChiSqr         := JSONArgs.OptFloat(JOpt, 'k_chi', DEF_K_CHI);
  Result.KVmax           := JSONArgs.OptFloat(JOpt, 'k_vmax', DEF_K_VMAX);
  Result.w1              := JSONArgs.OptFloat(JOpt, 'w1', DEF_W1);
  Result.w2              := JSONArgs.OptFloat(JOpt, 'w2', DEF_W2);
  Result.Vmax            := JSONArgs.OptFloat(JOpt, 'vmax', DEF_VMAX);
  Result.AdaptVel        := JSONArgs.OptBool(JOpt, 'adapt_velocity', False);
  Result.UseConstriction := JSONArgs.OptBool(JOpt, 'use_constriction', True);
  Result.Ksxr            := JSONArgs.OptFloat(JOpt, 'ksxr', DEF_KSXR);
  Result.PolyFactor      := JSONArgs.OptInt(JOpt, 'poly_factor', DEF_POLY_FACTOR);
  Result.MaxPOrder       := JSONArgs.OptInt(JOpt, 'poly_order', DEF_POLY_ORDER);

  Result.ThetaWeight     := JSONArgs.OptInt(JChi, 'theta_weight', 0);
  Result.MovAvgWindow    := JSONArgs.OptFloat(JChi, 'movavg_window', DEF_MOVAVG);

  { The GUI's smoothing of the measured curve is a display aid, not part of the
    fit; the server never turns it on. }
  Result.Smooth       := False;
  Result.SmoothWindow := -1;

  if Result.Pop < 2 then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.population" must be at least 2', IntToStr(Result.Pop));
  if Result.NMax < 1 then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.iterations" must be at least 1', IntToStr(Result.NMax));
  if (Result.ThetaWeight < 0) or (Result.ThetaWeight > 5) then
    raise EMCPError.Create('invalid_argument',
      '"chi2.theta_weight" must be between 0 and 5', IntToStr(Result.ThetaWeight));
  if Result.MovAvgWindow <= 0 then
    raise EMCPError.Create('invalid_argument',
      '"chi2.movavg_window" must be greater than zero',
      FloatToStr(Result.MovAvgWindow, FitFmt));
  if Result.MaxPOrder < 1 then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.poly_order" must be at least 1', IntToStr(Result.MaxPOrder));
  if Result.PolyFactor < 1 then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.poly_factor" must be at least 1', IntToStr(Result.PolyFactor));
end;

{ ------------------------------------------------------------ the request -- }

/// TLFPSO_Poly gives every non-paired parameter of a repeating stack a
/// polynomial over the periods. Its GetPolynomes walks the stacks with a stride
/// that only lands correctly while exactly one of them repeats, so a structure
/// with none or with several is refused here rather than answered with profiles
/// that belong to the wrong layers.
procedure CheckProfileIsPossible(const S: TFitStructure);
var
  i, Periodic: Integer;
begin
  Periodic := 0;
  for i := 0 to High(S.Stacks) do
    if S.Stacks[i].N > 1 then
      Inc(Periodic);
  if Periodic <> 1 then
    raise EMCPError.Create('invalid_argument',
      Format('"profile": true needs exactly one repeating stack (N > 1); this ' +
             'structure has %d', [Periodic]));
end;

function ParseFitRequest(const Params: TJSONObject): TFitRequest;
var
  Bad, PolStr: string;
begin
  Result := Default(TFitRequest);

  Result.Structure := StructureFromJSON(JSONArgs.ReqObj(Params, 'structure'),
                                        Result.Info);
  Bad := ValidateMaterials(Result.Structure);
  if Bad <> '' then
    raise EMCPError.Create('unknown_material',
      Format('No Henke table for material "%s"', [Bad]),
      'list_materials enumerates the names this server knows');

  ReadMeasuredCurve(Params, Result);
  ApplyThetaRange(Params, Result);
  ApplyScale(Params, Result);

  { Every omitted density becomes the bulk value the engine would use for it,
    before "free" and "bounds" are read: the engines seed the swarm around the
    start value and clamp it to the bounds, so a free density that started at
    the 0 sentinel under a lower bound of, say, 8 would pin every particle at
    8 while particle 0 kept the bulk value - a fit that never moves. With the
    bulk value in place a free density gets its +/-30% default like any other
    parameter, and start_structure reports what the fit started from. }
  FillEngineDensities(Result.Structure, Result.Lambda);


  Result.Resolution := JSONArgs.OptFloat(Params, 'resolution', DEF_RESOLUTION);
  if Result.Resolution < 0 then
    raise EMCPError.Create('invalid_argument', '"resolution" must not be negative');
  CheckResolutionFits(Result.Data, Result.Resolution);

  Result.RMin := JSONArgs.OptFloat(Params, 'r_min', DEF_R_MIN);
  if Result.RMin <= 0 then
    raise EMCPError.Create('invalid_argument', '"r_min" must be greater than zero');

  PolStr := JSONArgs.OptStr(Params, 'polarization', 'sp');
  Result.Polarization := ParseFitPolarization(PolStr, Result.PolarizationName);

  Result.InlineMax := JSONArgs.OptInt(Params, 'points_inline_max', DEF_INLINE_MAX);
  if Result.InlineMax < 0 then
    raise EMCPError.Create('invalid_argument',
      '"points_inline_max" must not be negative');

  Result.Profile := JSONArgs.OptBool(Params, 'profile', False);
  if Result.Profile then
    CheckProfileIsPossible(Result.Structure);

  Result.FreeParams := ParseFree(Params, Result.Structure, Result.Info,
                                 Result.Profile, Result.PeriodRefs);
  ParseBounds(Params, Result.Structure, Result.Info, Result.FreeParams,
              Result.PeriodRefs);
  CheckStartInsideBounds(Result.Structure, Result.FreeParams, Result.PeriodRefs);
  ApplyBounds(Result.Structure, Result.FreeParams);

  Result.Fit := ParseFitParams(Params);
  Result.PointWeight := JSONArgs.OptBool(JSONArgs.OptObj(Params, 'chi2'),
                                         'point_weight', True);
end;

{ ------------------------------------------------------- running the fit -- }

type
  /// <summary>Sinks TLFPSO_BASE.OnProgress into the job: reports the iteration,
  /// frees the model the engine hands over, and stops the run when a cancel has
  /// been asked for. It runs on the fitting thread.</summary>
  TFitRunner = class
  private
    FJob: TJob;
    FEngine: TLFPSO_BASE;
    FMaxIter: Integer;
    FLastIteration: Integer;
    FCancelSeen: Boolean;
  public
    constructor Create(AJob: TJob; AMaxIter: Integer);
    procedure HandleProgress(const Msg: TUpdateFitProgressMsg);
    property Engine: TLFPSO_BASE read FEngine write FEngine;
    property LastIteration: Integer read FLastIteration;
    property CancelSeen: Boolean read FCancelSeen;
  end;

constructor TFitRunner.Create(AJob: TJob; AMaxIter: Integer);
begin
  inherited Create;
  FJob := AJob;
  FMaxIter := AMaxIter;
  FLastIteration := 0;
end;

procedure TFitRunner.HandleProgress(const Msg: TUpdateFitProgressMsg);
var
  Step: Integer;
begin
  try
    { TLFPSO_BASE.Run reports once more after its loop, with the loop variable
      past the end; the iteration a client sees never exceeds the budget. }
    Step := Msg.Step;
    if Step < 0 then
      Step := 0;
    if Step > FMaxIter then
      Step := FMaxIter;
    if Step > FLastIteration then
      FLastIteration := Step;

    FJob.Progress(Step, Msg.BestChi,
      Format('chi2 %.4g, diversity %.3f', [Msg.BestChi, Msg.Diversity], FitFmt));

    if FJob.CancelRequested then
    begin
      FCancelSeen := True;
      if FEngine <> nil then
        FEngine.Terminate;
    end;
  finally
    { The callee owns Msg.LayeredModel, raise or not. It is nil on a step
      update, and Free is nil-safe. }
    Msg.LayeredModel.Free;
  end;
end;

{ The scan the engine and every check run afterwards share. With ExpValues set,
  TCalc.PrepareWorkers computes one point per measured angle and StartT / EndT
  are informational only; DT is the convolution FWHM. }
function FitCalcParams(const Req: TFitRequest): TCalcThreadParams;
begin
  Result := Default(TCalcThreadParams);
  Result.Mode      := cmTheta;
  Result.Lambda    := Req.Lambda;
  Result.StartT    := Req.ThetaMin;
  Result.EndT      := Req.ThetaMax;
  Result.DT        := Req.Resolution;
  Result.N         := Length(Req.Data);
  Result.K         := 1;
  Result.P         := Req.Polarization;
  Result.RF        := rfError;
  Result.MVAWindow := FIT_MVA_WINDOW;
end;

/// One scan of Model on the measured angles, with the chi-squared that goes
/// with it. Model is handed to TCalc, which frees it.
function ScanOnData(const Req: TFitRequest; Model: TLayeredModel;
  const MovAvgCurve: unit_Types.TDataArray;
  out Chi2: Double): unit_Types.TDataArray;
var
  Calc: TCalc;
begin
  { Model is ours until TCalc owns it, and TCalc.Create can raise. }
  try
    Calc := TCalc.Create;
  except
    Model.Free;
    raise;
  end;
  try
    Calc.Params    := FitCalcParams(Req);
    Calc.ExpValues := Req.Data;
    Calc.MovAvg    := MovAvgCurve;
    Calc.Limit     := Req.RMin;
    { One thread, as unit_MCPCalc.RunCalc and the LFPSO's own workers do. This
      scan is a single pass over the measured points - the fit does the same
      work once per particle per iteration - so there is nothing to gain, and
      TCalc's multi-threaded branch goes through Parallel.ForEach, which needs
      the Win64 OmniThreadLibrary fix documented in CLAUDE.md and in the header
      of unit_MCPCalc. Without it the chi-squared of the start model would be
      the first thing a fit does and the first thing to hang. }
    Calc.MaxThreads := 1;
    Calc.Model     := Model;          // TCalc.Destroy frees it from here on
    Calc.Run;
    Chi2 := Calc.CalcChiSquare(Req.Fit.ThetaWeight);
    Result := Copy(Calc.Results);
  finally
    Calc.Free;
  end;
end;

/// Replaces every "use the Henke bulk value" density (0) with the value the
/// engine read from the table, and closes the range of every parameter that was
/// held fixed around its new value. Both are what save_project reports: a
/// structure the client can hand straight back and get the same curve from.
procedure FillEngineDensities(var S: TFitStructure; Lambda: Double);
var
  Model: TLayeredModel;
  i, j, p: Integer;
begin
  Model := BuildLayeredModel(S);
  try
    Model.Generate(Lambda);
    FillDefaultDensities(S, Model);
  finally
    Model.Free;
  end;

  { A fixed parameter is one with an empty range, and the density of a layer
    that asked for the bulk value has just moved off min = max = 0. Put the
    range back around the value, so that the .xrcx the GUI opens does not show
    a density of 12.4 with limits of 0 to 0. Free parameters keep the bounds
    the fit searched. }
  for i := 0 to High(S.Stacks) do
    for j := 0 to High(S.Stacks[i].Layers) do
      for p := 1 to 3 do
        with S.Stacks[i].Layers[j].P[p] do
          if min = max then
          begin
            min := V;
            max := V;
          end;
end;

/// The chi-squared one structure scores on the data, with the curve thrown
/// away: what the start model was worth before the fit touched it.
function ChiSquareOf(const Req: TFitRequest; const S: TFitStructure;
  const MovAvgCurve: unit_Types.TDataArray): Double;
begin
  { BuildLayeredModel makes the same expanded model TLFPSO_BASE.FillModel does,
    and ScanOnData hands it to a TCalc, which frees it. }
  ScanOnData(Req, BuildLayeredModel(S), MovAvgCurve, Result);
end;

function ResidualCurve(const Data, Calc: unit_Types.TDataArray): unit_Types.TDataArray;
var
  i, n: Integer;
begin
  n := Min(Length(Data), Length(Calc));
  SetLength(Result, n);
  for i := 0 to n - 1 do
  begin
    Result[i].t := Data[i].t;
    if (Data[i].r > 0) and (Calc[i].r > 0) then
      Result[i].r := Log10(Data[i].r) - Log10(Calc[i].r)
    else
      Result[i].r := 0;
  end;
end;

{ ------------------------------------------------------- result assembly -- }

type
  /// <summary>One layer of a repeating stack and its thickness in each period,
  /// which is what a gradient fit produces and a plain fit does not.</summary>
  TLayerThickness = record
    GUIStack, GUILayer: Integer;
    Thickness: TArray<Single>;
  end;

function BoundsUsedJSON(const Refs: TArray<TFitParamRef>;
  const PeriodRefs: TArray<TPeriodRef>; const Info: TStructureInfo): TJSONArray;
var
  n: Integer;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    for n := 0 to High(Refs) do
    begin
      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('target', 'layer');
      Obj.AddPair('stack', StackAddress(Info, Refs[n].GUIStack));
      Obj.AddPair('layer', TJSONNumber.Create(Refs[n].LayerJSON));
      Obj.AddPair('parameter', PARAM_NAMES[Refs[n].P]);
      Obj.AddPair('min', JSONArgs.Num(Refs[n].Min));
      Obj.AddPair('max', JSONArgs.Num(Refs[n].Max));
    end;
    for n := 0 to High(PeriodRefs) do
    begin
      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('target', 'period');
      Obj.AddPair('stack', TJSONNumber.Create(PeriodRefs[n].StackJSON));
      Obj.AddPair('parameter', 'period');
      Obj.AddPair('min', JSONArgs.Num(PeriodRefs[n].Min));
      Obj.AddPair('max', JSONArgs.Num(PeriodRefs[n].Max));
    end;
  except
    Result.Free;
    raise;
  end;
end;

/// The sum of the layer thicknesses of one stack.
function StackPeriod(const S: TFitStructure; GUIStack: Integer): Double;
var
  j: Integer;
begin
  Result := 0;
  for j := 0 to High(S.Stacks[GUIStack].Layers) do
    Result := Result + S.Stacks[GUIStack].Layers[j].P[1].V;
end;

/// One entry per repeating stack, in JSON order: how its period was treated -
/// "held" at the start value (the periodic engine's default), "free" inside
/// the bounds given, or "floating" (a profile fit, where TLFPSO_Poly never
/// constrains it) - with the start and fitted periods in Angstrom.
function PeriodModeJSON(const Req: TFitRequest; const Fitted: TFitStructure): TJSONArray;
var
  k, n, GUIStack: Integer;
  Obj: TJSONObject;
  Mode: string;
  Ref: TPeriodRef;
  IsFree: Boolean;
begin
  Result := TJSONArray.Create;
  try
    for k := 0 to High(Req.Info.StackMap) do
    begin
      GUIStack := Req.Info.StackMap[k];
      if Req.Structure.Stacks[GUIStack].N <= 1 then
        Continue;

      IsFree := False;
      Ref := Default(TPeriodRef);
      for n := 0 to High(Req.PeriodRefs) do
        if Req.PeriodRefs[n].GUIStack = GUIStack then
        begin
          IsFree := True;
          Ref := Req.PeriodRefs[n];
        end;

      if Req.Profile then
        Mode := 'floating'
      else if IsFree then
        Mode := 'free'
      else
        Mode := 'held';

      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('stack', TJSONNumber.Create(k));
      Obj.AddPair('mode', Mode);
      Obj.AddPair('start_A', JSONArgs.Num(StackPeriod(Req.Structure, GUIStack)));
      Obj.AddPair('fitted_A', JSONArgs.Num(StackPeriod(Fitted, GUIStack)));
      if IsFree then
      begin
        Obj.AddPair('min', JSONArgs.Num(Ref.Min));
        Obj.AddPair('max', JSONArgs.Num(Ref.Max));
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

/// The polynomial profiles of the parameters that were actually fitted.
///
/// TLFPSO_Poly gives *every* non-paired parameter of the repeating stack a
/// polynomial, whether the client froze it or not; a frozen one comes back as
/// its constant with zeroes after it, because Set_Init_XPoly derives every
/// coefficient's range from the parameter's own (empty) one. Reporting those
/// would say nothing and would print a density of 0 - the "use the Henke bulk
/// value" sentinel - next to a fitted_structure that names the value. The
/// .xrcx keeps the engine's full set, which is what the GUI writes.
function ProfilesJSON(const Poly: TProfileFunctions; const Info: TStructureInfo;
  const FreeParams: TArray<TFitParamRef>): TJSONArray;
var
  i, c, n: Integer;
  Obj: TJSONObject;
  Coeffs: TJSONArray;
  Wanted: Boolean;
begin
  Result := TJSONArray.Create;
  try
    for i := 0 to High(Poly) do
    begin
      Wanted := False;
      for n := 0 to High(FreeParams) do
        Wanted := Wanted or ((FreeParams[n].GUIStack = Poly[i].StackID) and
                             (FreeParams[n].GUILayer = Poly[i].LayerID) and
                             (FreeParams[n].P = Ord(Poly[i].Subj) + 1));
      if not Wanted then
        Continue;

      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('stack', StackAddress(Info, Poly[i].StackID));
      Obj.AddPair('layer', TJSONNumber.Create(Poly[i].LayerID));
      Obj.AddPair('parameter', PARAM_NAMES[Ord(Poly[i].Subj) + 1]);
      Coeffs := TJSONArray.Create;
      Obj.AddPair('coefficients', Coeffs);
      for c := 0 to High(Poly[i].C) do
        Coeffs.AddElement(JSONArgs.Num(Poly[i].C[c]));
    end;
  except
    Result.Free;
    raise;
  end;
end;

/// One layer's thickness in each of the periods it occurs in, lifted out of the
/// expanded model before that model is handed to a TCalc that will free it.
/// Model layer 0 is the ambient and the last one is the substrate; the rest
/// carry the stack and layer index FillModel copied from the structure. Layers
/// that occur once have no profile and are not listed.
function CollectThicknessProfiles(Model: TLayeredModel): TArray<TLayerThickness>;
var
  i, n, Found: Integer;
  Layers: TCalcLayers;
begin
  SetLength(Result, 0);
  if Model = nil then
    Exit;
  Layers := Model.LayersDirect;
  for i := 1 to High(Layers) - 1 do
  begin
    Found := -1;
    for n := 0 to High(Result) do
      if (Result[n].GUIStack = Model.StackIDs[i]) and
         (Result[n].GUILayer = Model.LayerIDs[i]) then
        Found := n;
    if Found < 0 then
    begin
      SetLength(Result, Length(Result) + 1);
      Found := High(Result);
      Result[Found].GUIStack := Model.StackIDs[i];
      Result[Found].GUILayer := Model.LayerIDs[i];
    end;
    Result[Found].Thickness := Result[Found].Thickness + [Layers[i].L];
  end;

  n := 0;
  for i := 0 to High(Result) do
    if Length(Result[i].Thickness) > 1 then
    begin
      Result[n] := Result[i];
      Inc(n);
    end;
  SetLength(Result, n);
end;

/// The fitted structure in the requirements' section 3 shape, with each layer's
/// per-period thickness added when the fit produced a gradient.
function FittedStructureJSON(const S: TFitStructure; const Info: TStructureInfo;
  const Profiles: TArray<TLayerThickness>): TJSONObject;
var
  JStacks, JLayers, Prof: TJSONArray;
  k, i, c, n, Idx: Integer;
begin
  Result := StructureToJSON(S, Info);
  if Length(Profiles) = 0 then
    Exit;
  try
    JStacks := Result.GetValue('stacks') as TJSONArray;
    for k := 0 to JStacks.Count - 1 do
    begin
      if k > High(Info.StackMap) then
        Break;
      Idx := Info.StackMap[k];
      JLayers := (JStacks.Items[k] as TJSONObject).GetValue('layers') as TJSONArray;
      for i := 0 to JLayers.Count - 1 do
        for n := 0 to High(Profiles) do
          if (Profiles[n].GUIStack = Idx) and (Profiles[n].GUILayer = i) then
          begin
            Prof := TJSONArray.Create;
            (JLayers.Items[i] as TJSONObject).AddPair('thickness_profile', Prof);
            for c := 0 to High(Profiles[n].Thickness) do
              Prof.AddElement(JSONArgs.Num(Profiles[n].Thickness[c]));
          end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function Chi2SettingsJSON(const Req: TFitRequest): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('theta_weight', TJSONNumber.Create(Req.Fit.ThetaWeight));
  Result.AddPair('point_weight', TJSONBool.Create(Req.PointWeight));
  Result.AddPair('movavg_window', JSONArgs.Num(Req.Fit.MovAvgWindow));
end;

function CurveOrNull(const C: unit_Types.TDataArray; MaxPoints: Integer): TJSONValue;
var
  Arr: TJSONArray;
begin
  Arr := CurveToJSON(C, MaxPoints);
  if Arr = nil then
    Result := TJSONNull.Create
  else
    Result := Arr;
end;

{ --------------------------------------------------------- .xrcx packaging -- }

/// A value that reached us through a Single and is about to be written into a
/// Double field of params.dsc. 0.2 read back out of a Single is
/// 0.200000002980232, and the GUI shows these in edit boxes; seven significant
/// digits is all a Single carries anyway. The same rounding the [LFPSO] block
/// of params.dsc already applies.
function FromSingle(const V: Single): Double;
begin
  Result := StrToFloat(FloatToStrF(V, ffGeneral, 7, 0, FitFmt), FitFmt);
end;

function FitXRCXParams(const Req: TFitRequest): TXRCXCalcParams;
begin
  Result := DefaultCalcParams;

  Result.Lambda     := Req.Lambda;
  { The theta range is the range of the measured points, and TDataPoint.t is a
    Single. }
  Result.ThetaStart := FromSingle(Req.ThetaMin);
  Result.ThetaEnd   := FromSingle(Req.ThetaMax);
  Result.Width      := Req.Resolution;
  Result.Points     := Length(Req.Data);
  if Req.Polarization = cmS then
    Result.Polarisation := 0
  else
    Result.Polarisation := 1;
  Result.MinLimit := Req.RMin;

  // [FIT] Mode: 0 irregular, 1 periodic, 2 poly - the engine that ran.
  if Req.Profile then
    Result.FitMode := 2
  else
    Result.FitMode := 1;

  Result.FitIter   := Req.Fit.NMax;
  Result.FitPop    := Req.Fit.Pop;
  Result.PolyOrder := Req.Fit.MaxPOrder;
  Result.PWChi     := Req.PointWeight;
  Result.TWChi     := Req.Fit.ThetaWeight;
  Result.Tol       := FromSingle(Req.Fit.Tolerance);
  Result.Window    := FromSingle(Req.Fit.MovAvgWindow);
  Result.LFPSO     := Req.Fit;
end;

function FitExtensions(const Poly: TProfileFunctions): TArray<TXRCXProfileExt>;
var
  i, c: Integer;
begin
  SetLength(Result, Length(Poly));
  for i := 0 to High(Poly) do
  begin
    Result[i].StackID := Poly[i].StackID;
    Result[i].LayerID := Poly[i].LayerID;
    Result[i].Subj := Poly[i].Subj;
    SetLength(Result[i].Coeffs, Length(Poly[i].C));
    for c := 0 to High(Poly[i].C) do
      Result[i].Coeffs[c] := Poly[i].C[c];
  end;
end;

procedure WriteFitProject(const Path: string; const Req: TFitRequest;
  const Fitted: TFitStructure; const Poly: TProfileFunctions;
  const CalcCurve: unit_Types.TDataArray; const Title: string);
var
  P: TXRCXProject;
begin
  P := Default(TXRCXProject);
  P.Params     := FitXRCXParams(Req);
  P.ModelTitle := Title;
  if Req.Scale = 1.0 then
    P.Note := Format('fit_xrr on %s', [Req.DataTitle])
  else
    P.Note := Format('fit_xrr on %s, intensities x %g', [Req.DataTitle, Req.Scale]);
  P.XRCData    := StructureToXRCData(Fitted, Req.Info);
  P.Extensions := FitExtensions(Poly);
  P.CalcCurve  := CalcCurve;
  P.DataTitle  := Req.DataTitle;
  P.DataCurve  := Req.Data;
  WriteXRCX(Path, P);
end;

{ --------------------------------------------------------------- the body -- }

procedure RunFitJob(Job: TJob; const Req: TFitRequest);
var
  PIdx: Integer;
  Runner: TFitRunner;
  L: TLFPSO_BASE;
  FS, StartFS, Fitted: TFitStructure;
  Poly: TProfileFunctions;
  Model: TLayeredModel;
  Profiles: TArray<TLayerThickness>;
  MovAvgCurve, CalcCurve, Residual: unit_Types.TDataArray;
  Chi2, Chi2Recalc, Chi2Start, Scale: Double;
  IterationsRun: Integer;
  MeasuredPath, CalcPath, ResidualPath, XRCXPath: string;
  Res, JFiles: TJSONObject;
  EngineName: string;
begin
  if Job = nil then
    raise EMCPError.Create('internal', 'The fit job body was called without a job');

  Job.MaxIterations := Req.Fit.NMax;

  MeasuredPath := TPath.Combine(Job.Dir, 'measured.dat');
  CalcPath     := TPath.Combine(Job.Dir, 'calc.dat');
  ResidualPath := TPath.Combine(Job.Dir, 'residual.dat');
  XRCXPath     := TPath.Combine(Job.Dir, 'fit.xrcx');
  WriteCurveFile(MeasuredPath, Req.Data, 'theta_deg', 'I');

  if Req.PointWeight then
    MovAvgCurve := MovAvg(Req.Data, Req.Fit.MovAvgWindow)
  else
    SetLength(MovAvgCurve, 0);

  { What the model the client started from was worth, so that the fit can be
    read as an improvement rather than as a bare number. }
  Chi2Start := ChiSquareOf(Req, Req.Structure, MovAvgCurve);

  if Job.CancelRequested then
    Exit;

  { The engine mutates the structure it is given - TLFPSO_BASE.UpdateStructure
    writes the fitted values straight back into it - so it gets a deep copy and
    Req.Structure stays the start model the result reports. }
  Req.Structure.CopyContent(FS);

  if Req.Profile then
  begin
    L := TLFPSO_Poly.Create;
    EngineName := 'TLFPSO_Poly';
  end
  else
  begin
    L := TLFPSO_Periodic.Create;
    EngineName := 'TLFPSO_Periodic';
  end;
  try
    Runner := TFitRunner.Create(Job, Req.Fit.NMax);
    try
      Runner.Engine := L;
      L.Seed       := Job.Seed;
      L.Params     := Req.Fit;          // before Structure: it sizes the swarm
      L.Limit      := Req.RMin;
      L.ExpValues  := Req.Data;
      L.MovAvg     := MovAvgCurve;
      L.Structure  := FS;
      { A free period: the periodic engine rescales the stack's layers only
        when their sum leaves the range instead of after every move. }
      if L is TLFPSO_Periodic then
        for PIdx := 0 to High(Req.PeriodRefs) do
          TLFPSO_Periodic(L).SetPeriodRange(Req.PeriodRefs[PIdx].GUIStack,
            Req.PeriodRefs[PIdx].Min, Req.PeriodRefs[PIdx].Max);
      L.OnProgress := Runner.HandleProgress;

      { Synchronously on this worker thread. Run drives its own Parallel.For and
        drains the resulting thread messages itself, exactly as the GUI's
        TFittingThread lets it. }
      L.Run(FitCalcParams(Req));

      { A run that was asked to stop leaves no result: the job manager records a
        body that returns without one as cancelled, and everything already
        written stays in the job folder. }
      if Runner.CancelSeen then
        Exit;

      Fitted := L.Structure;
      Poly := L.Polynomes;
      Chi2 := L.BestChiSquare;
      Model := L.Result;                // a fresh model; ScanOnData frees it
      IterationsRun := Runner.LastIteration;
    finally
      Runner.Free;
    end;

    { Model is ours until ScanOnData hands it to a TCalc. }
    try
      { Read off the expanded model while it is still ours: a gradient fit puts
        the per-period thicknesses nowhere else. A plain periodic fit repeats
        one thickness per period and has no profile to report. }
      if Req.Profile then
        Profiles := CollectThicknessProfiles(Model);
    except
      Model.Free;
      raise;
    end;

    { The curve on the measured angles for the model the fit ended on. It is
      recomputed rather than taken from BestCurve so that the chi-squared beside
      it comes from the structure the result reports. ScanOnData takes the
      model, raise or not, so Model must not be touched afterwards. }
    CalcCurve := ScanOnData(Req, Model, MovAvgCurve, Chi2Recalc);
  finally
    L.Free;
  end;

  { A cancel that arrived after the engine's last progress report was never
    offered to the callback, so Runner.CancelSeen is False and the run above
    finished on its own. The job manager records a body that left a result as
    finished, so look again before writing one: a cancel seen only here still
    throws the freshly built answer away and lets the job end cancelled,
    consistent with RunOptimizeJob. The .xrcx and curve files have not been
    written yet at this point, so nothing is left behind to clean up. }
  if Job.CancelRequested then
    Exit;

  { The densities the engine used, in both structures the result reports and in
    the .xrcx: a layer that asked for the Henke bulk value is stored with the
    value, exactly as save_project stores it. }
  FillEngineDensities(Fitted, Req.Lambda);
  Req.Structure.CopyContent(StartFS);
  FillEngineDensities(StartFS, Req.Lambda);

  Residual := ResidualCurve(Req.Data, CalcCurve);
  WriteCurveFile(CalcPath, CalcCurve, 'theta_deg', 'R');
  WriteCurveFile(ResidualPath, Residual, 'theta_deg', 'log10_I_minus_log10_R');
  WriteFitProject(XRCXPath, Req, Fitted, Poly, CalcCurve, Job.Id);

  Res := TJSONObject.Create;
  try
    Res.AddPair('job_id', Job.Id);
    Res.AddPair('seed', TJSONNumber.Create(Job.Seed));
    Res.AddPair('chi2', JSONArgs.Num(Chi2));
    Res.AddPair('chi2_recalc', JSONArgs.Num(Chi2Recalc));
    Res.AddPair('chi2_start', JSONArgs.Num(Chi2Start));
    Res.AddPair('chi2_definition', FIT_CHI2_DEFINITION);
    Res.AddPair('chi2_settings', Chi2SettingsJSON(Req));
    Res.AddPair('iterations_run', TJSONNumber.Create(IterationsRun));
    Res.AddPair('elapsed_s', JSONArgs.Num(Job.ElapsedMs / 1000));
    Res.AddPair('lambda_used', JSONArgs.Num(Req.Lambda));
    Res.AddPair('theta_range',
      JSONArgs.NumArr(TArray<Double>.Create(Req.ThetaMin, Req.ThetaMax)));
    Res.AddPair('resolution_deg', JSONArgs.Num(Req.Resolution));
    Res.AddPair('polarization', Req.PolarizationName);
    Res.AddPair('engine', EngineName);
    Res.AddPair('start_structure', StructureToJSON(StartFS, Req.Info));
    Res.AddPair('fitted_structure',
      FittedStructureJSON(Fitted, Req.Info, Profiles));
    Res.AddPair('bounds_used', BoundsUsedJSON(Req.FreeParams, Req.PeriodRefs, Req.Info));
    Res.AddPair('period_mode', PeriodModeJSON(Req, Fitted));
    Res.AddPair('profiles', ProfilesJSON(Poly, Req.Info, Req.FreeParams));

    JFiles := TJSONObject.Create;
    Res.AddPair('files', JFiles);
    JFiles.AddPair('xrcx', WorkDir.RelativePath(XRCXPath));
    JFiles.AddPair('measured', WorkDir.RelativePath(MeasuredPath));
    JFiles.AddPair('calculated', WorkDir.RelativePath(CalcPath));
    JFiles.AddPair('residual', WorkDir.RelativePath(ResidualPath));

    Res.AddPair('measured', CurveOrNull(Req.Data, Req.InlineMax));
    Res.AddPair('calculated', CurveOrNull(CalcCurve, Req.InlineMax));
    Res.AddPair('residual', CurveOrNull(Residual, Req.InlineMax));

    Res.AddPair('scale', JSONArgs.Num(Req.Scale));
    Res.AddPair('background', JSONArgs.Num(0.0));
    Res.AddPair('note', FIT_NO_SCALE_NOTE);

    { The two numbers are the same calculation on the same model, so they must
      agree; if they ever do not, the curve beside the result was produced by
      something other than the structure the result reports. }
    Scale := Abs(Chi2);
    if Scale < 1E-12 then
      Scale := 1;
    if Abs(Chi2 - Chi2Recalc) / Scale > CHI2_CONSISTENCY_TOLERANCE then
      Res.AddPair('consistency_warning', Format(
        'The engine finished on chi2 %.9g but the fitted structure re-scores ' +
        'as %.9g. The reported curve and the reported structure may not be the ' +
        'same model; treat both with suspicion.', [Chi2, Chi2Recalc], FitFmt));
  except
    Res.Free;
    raise;
  end;

  Job.ResultObj := Res;
end;

end.
