(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

unit unit_MCPFit;

(* The fit_xrr job: the GUI's LFPSO, driven headless.

   TCalcOrchestrator.PrepareLFPSO / RunFitting / FinalizeFitting do this in the
   GUI; everything here is the same sequence with the forms taken out. The
   engine is unmodified - the same TLFPSO_Periodic, TLFPSO_Poly or
   TLFPSO_Irregular (the GUI's three fitting modes, "mode" here), the same TCalc,
   and therefore the same chi-squared as the number the GUI shows. The one
   addition is TLFPSO_IrregularFromTable, which lets an irregular fit start from
   per-period values instead of the stack's single value ("start_profiles").

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
     "smooth" is the GUI's Data - Smooth on that curve (ApplySmooth). The order
     is the manual's: scale, smooth the whole curve, then trim to theta_range.
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
     bounds and the result reports "floating". TLFPSO_Irregular has no
     NormalizeD either: it expands every repeating stack into its periods and
     fits each period's layers on their own, so its periods float too. Since
     2026-09-16 NormalizeD
     spreads its correction only over layers with room inside their own
     thickness bounds, and XSeed clamps every seed, so no value the engine
     returns can lie outside the bounds given; the result's "out_of_bounds"
     list (OutOfBoundsJSON) is the check on that promise, and is empty.

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
    'displays. With "scale_solve" true (the default) log10 I_meas carries the ' +
    'solved offset a of chi2_scale_definition; with "scale_solve": false a = 0 ' +
    'and this is the sum of every earlier version.';

  { The measured scale as a nuisance parameter solved inside the sum above:
    what a, scale_ratio and chi2_scale mean on a result. Reported beside every
    chi2 so that a solved number is never read as an anchored one. }
  FIT_CHI2_SOLVED_DEFINITION =
    'With "scale_solve" (default true) log10 I_meas is replaced by log10 I_meas + a ' +
    'in chi2 and chi2_plain, a being the value that minimises chi2 for the ' +
    'candidate structure, found in closed form and held within +/- log10(1 + ' +
    'scale_solve_window) of 0; every candidate is scored at its own a, so the ' +
    'scale is profiled out rather than fitted. chi2, chi2_recalc and chi2_plain ' +
    'are at the a of the fitted structure (scale_ratio = 10^a), chi2_start and ' +
    'chi2_start_plain at the a of the start model (scale_start_ratio). r_min, ' +
    'the files and the .xrcx stay at the anchored scale; residual.dat is at the ' +
    'solved one. With "scale_solve": false a = 0 and the numbers are those of ' +
    'every earlier version.';

  { The same sum with both weights dropped: what the fit is worth as a bare
    data-to-fit disagreement, on the same scale as chi2, so the two can be read
    side by side. It is reported, never minimised. }
  FIT_CHI2_PLAIN_DEFINITION =
    'chi2_plain and chi2_start_plain are the same sum as chi2 with w_point = ' +
    'w_theta = 1: 1000/(n-1) * sum(((log10 I_meas - log10 R_calc)/log10 ' +
    'R_calc)^2) over the same points. It is the bare disagreement between the ' +
    'measured and the calculated curve, reported beside chi2 so that the ' +
    'weighting the fit applies can be read off the difference. Nothing ' +
    'optimises it.';

  { Said in every result: the two parameters a client coming from another
    refinement program looks for first, and what became of them here. }
  FIT_NO_SCALE_NOTE =
    'scale is the anchored multiplier the client chose ("scale" argument), ' +
    'applied to the measured intensities before the fit and stored with them ' +
    'in measured.dat and fit.xrcx. With "scale_solve" (default true) the ' +
    'chi-squared profiles a further factor out of the anchored curve ' +
    '(scale_ratio, chi2_scale = "solved"); the files and the .xrcx keep the ' +
    'anchored scale. Background is never fitted.';

  // Argument defaults, all of them the brief's - but for the population, which
  // was 100 until 2026-09-17. The lab fits with 100 iterations and 500 to 1000
  // particles ("population wins iterations"), so a request that names no
  // optimizer now gets the lower end of that.
  DEF_RESOLUTION   = 0.015;    // theta FWHM, degrees
  DEF_POPULATION   = 500;
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
  /// "scale": "auto" looks for the measured maximum below this angle.
  DEF_AUTO_THETA_MAX = 0.5;
  DEF_SCALE_SOLVE_WINDOW = 0.2;   // the solved scale stays within x1.2 of the anchor

  { The range a free parameter gets when no explicit bound is given: the start
    value plus and minus this fraction of it. }
  DEF_FREE_DEVIATION = 0.30;

  /// Largest measured curve a fit will accept. Every particle of every
  /// iteration is evaluated at every point, so this is the single biggest lever
  /// on how long a run takes; it is the same ceiling calc_reflectivity uses.
  MAX_FIT_POINTS = 100000;
  /// The engine smooths the last MVAWindow points of a convolved curve.
  FIT_MVA_WINDOW = 10;
  /// "smooth": the window of the GUI's Data - Smooth, which is
  /// MovAvg(Data, 5) in TfrmChartInfo.SmoothData, and the most passes taken.
  FIT_SMOOTH_WINDOW = 5;
  MAX_SMOOTH_PASSES = 10;
  /// optimizer.period_smooth_window: -1 lets TLFPSO_Irregular choose (a tenth
  /// of the periods, at least 1), which is also the GUI's default.
  DEF_PERIOD_SMOOTH_WINDOW = -1;

  /// "mode": the GUI's three fitting modes, by the names the result echoes.
  FIT_MODE_PERIODIC  = 'periodic';
  FIT_MODE_PROFILE   = 'profile';
  FIT_MODE_IRREGULAR = 'irregular';

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
    Mode: string;                       // FIT_MODE_PERIODIC, _PROFILE or _IRREGULAR
    Profile: Boolean;                   // TLFPSO_Poly ("mode": "profile")
    Irregular: Boolean;                 // TLFPSO_Irregular ("mode": "irregular")
    StartProfiles: Boolean;             // the start model's per-period values are
                                        // in Structure's TLayerData.PP tables
    InlineMax: Integer;
    Scale: Double;                      // multiplier already applied to Data
    ScaleMode: string;                  // 'fixed' (the client's number) or 'auto'
    ScaleTheta: Double;                 // angle the auto scale was taken at
    ScaleCounts: Double;                // raw measured maximum there
    AutoThetaMax: Double;               // the range that maximum was sought in
    SmoothPasses: Integer;              // Data - Smooth passes already applied to Data
    PeriodRefs: TArray<TPeriodRef>;     // repeating stacks whose period is free
    PairedParams: TArray<TFitParamRef>; // layer parameters held constant over
                                        // the periods of a profile or irregular fit
    Device: string;                     // 'auto', 'cpu' or 'gpu' (optimizer.device)
    ScaleSolveWindow: Double;           // "scale_solve_window" as given (Fit holds its log10)
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
  unit_materials, unit_calc, unit_gpu_calc, unit_DataProcessing,
  unit_LFPSO_Base, unit_LFPSO_Periodic, unit_LFPSO_Poly, unit_LFPSO_Irregular,
  unit_MCPCalc, unit_MCPErrors, unit_MCPFitReport, unit_MCPInbox,
  unit_MCPProjectFile, unit_MCPSandbox, unit_MCPUnits;

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
function ScanOnData(const Req: TFitRequest; Model: TLayeredModel;
  const MovAvgCurve: unit_Types.TDataArray;
  out Chi2, Chi2Plain: Double): unit_Types.TDataArray; overload; forward;
function ScanOnData(const Req: TFitRequest; Model: TLayeredModel;
  const MovAvgCurve: unit_Types.TDataArray;
  out Chi2, Chi2Plain, ScaleLog: Double; out ScaleClamped: Boolean): unit_Types.TDataArray; overload; forward;

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

/// The laboratory's Data - Normalize Auto (unit_DataProcessing.NormalizeAuto)
/// over the arguments of one fit: the largest measured intensity below
/// Req.AutoThetaMax is set equal to the start model's reflectivity at that same
/// angle, so scale = R_calc(theta_max) / I_max. The model is computed on the
/// measured grid with the wavelength, polarization and resolution the fit will
/// use, on the raw curve - before the smoothing and the trim, as in the GUI,
/// where the operator normalises what the file holds.
procedure ComputeAutoScale(var Req: TFitRequest);
var
  i, IMax: Integer;
  Calc: unit_Types.TDataArray;
  Chi2, Chi2Plain: Double;
begin
  if Length(Req.Data) > MAX_FIT_POINTS then
    raise EMCPError.Create('invalid_argument',
      Format('"scale": "auto" computes the start model on all %d measured ' +
             'points; at most %d are allowed. Give a number instead, or a ' +
             'shorter curve.', [Length(Req.Data), MAX_FIT_POINTS]));

  IMax := -1;
  for i := 0 to High(Req.Data) do
    if Req.Data[i].t < Req.AutoThetaMax then
      if (IMax < 0) or (Req.Data[i].r > Req.Data[IMax].r) then
        IMax := i;

  if IMax < 0 then
    raise EMCPError.Create('invalid_argument',
      Format('"scale": "auto" needs a measured point below "auto_theta_max" ' +
             '(%.4g deg); the curve starts at %.4g deg',
             [Req.AutoThetaMax, Req.Data[0].t], FitFmt));
  if Req.Data[IMax].r <= 0 then
    raise EMCPError.Create('invalid_argument',
      '"scale": "auto" needs a positive measured maximum');

  { ThetaMin / ThetaMax are informational for a scan with ExpValues set, but
    the .xrcx and the range checks read them later, so they are put on the raw
    range here and ApplyThetaRange replaces them with the trimmed one. }
  Req.ThetaMin := Req.Data[0].t;
  Req.ThetaMax := Req.Data[High(Req.Data)].t;
  Calc := ScanOnData(Req, BuildLayeredModel(Req.Structure, Req.StartProfiles),
                     nil, Chi2, Chi2Plain);

  if (IMax > High(Calc)) or (Calc[IMax].r <= 0) then
    raise EMCPError.Create('invalid_argument',
      Format('"scale": "auto" found no reflectivity of the start model at ' +
             '%.5g deg to normalise to', [Req.Data[IMax].t], FitFmt));

  Req.ScaleTheta := Req.Data[IMax].t;
  Req.ScaleCounts := Req.Data[IMax].r;
  Req.Scale := Calc[IMax].r / Req.Data[IMax].r;
end;

/// The multiplier applied to the measured intensities before the fit - the
/// manual's "normalize" step - default 1. It is asked for in one of two ways:
/// "scale_auto": true, or the string "auto" in "scale". Both run
/// ComputeAutoScale; a number in "scale" is used as it stands, and is ignored
/// when "scale_auto" is true. It is never fitted as a parameter; the scaled
/// curve is what the files and the .xrcx hold, so the GUI shows the same data.
/// The chi-squared sees it too, but with "scale_solve" (the default) at a
/// further factor solved in closed form per candidate - scale_ratio on the
/// result - so a chi2 cross-checked against the .xrcx is off by that factor
/// unless "scale_solve" is false. See FIT_CHI2_SOLVED_DEFINITION.
///
/// There are two spellings because one of them is hard for a client to write.
/// An agent on the exp-03 run of 2026-09-18 sent "scale": auto unquoted fifteen
/// times running, and its own client refused every call as malformed JSON
/// before the server ever saw it: a key whose type is number-or-string invites
/// that. The boolean cannot be got wrong, so it is the one the schema names
/// first.
procedure ApplyScale(const Params: TJSONObject; var Req: TFitRequest);
var
  i: Integer;
  JScale: TJSONValue;
  Mode: string;
  Auto: Boolean;
begin
  Req.AutoThetaMax := JSONArgs.OptFloat(Params, 'auto_theta_max',
                                        DEF_AUTO_THETA_MAX);
  if Req.AutoThetaMax <= 0 then
    raise EMCPError.Create('invalid_argument',
      '"auto_theta_max" must be greater than zero');

  Req.ScaleMode := 'fixed';
  Req.Scale := 1.0;

  Auto := JSONArgs.OptBool(Params, 'scale_auto', False);

  JScale := Params.FindValue('scale');
  if JScale is TJSONString then
  begin
    Mode := LowerCase(TJSONString(JScale).Value);
    if Mode <> 'auto' then
      raise EMCPError.Create('invalid_argument',
        '"scale" is a positive number or the string "auto"; to normalise ' +
        'automatically you can also send "scale_auto": true',
        TJSONString(JScale).Value);
    Auto := True;
  end;

  if Auto then
  begin
    Req.ScaleMode := 'auto';
    ComputeAutoScale(Req);
  end
  else
  begin
    Req.Scale := JSONArgs.OptFloat(Params, 'scale', 1.0);
    if Req.Scale <= 0 then
      raise EMCPError.Create('invalid_argument',
        '"scale" must be greater than zero: it multiplies the measured intensities',
        FloatToStr(Req.Scale, TFormatSettings.Invariant));
  end;

  if Req.Scale <> 1.0 then
    for i := 0 to High(Req.Data) do
      Req.Data[i].r := Req.Data[i].r * Req.Scale;
end;

/// "smooth": {"passes": n} runs the GUI's Data - Smooth n times over the whole
/// measured curve - MovAvg(Data, 5), the call TfrmChartInfo.SmoothData makes, on
/// the linear intensities. Default 0, off. It comes after the scale and before
/// the trim, as in the manual: MovAvg copies the first points and flattens the
/// last ones, which a trimmed range then leaves out. Like the scale, the
/// smoothed curve is what the chi-squared, the files and the .xrcx see.
procedure ApplySmooth(const Params: TJSONObject; var Req: TFitRequest);
var
  JSmooth: TJSONObject;
  Passes: Double;
  i: Integer;
begin
  Req.SmoothPasses := 0;
  JSmooth := JSONArgs.OptObj(Params, 'smooth');
  if JSmooth = nil then
    Exit;

  Passes := JSONArgs.OptFloat(JSmooth, 'passes', 0);
  if (Frac(Passes) <> 0) or (Passes < 0) or (Passes > MAX_SMOOTH_PASSES) then
    raise EMCPError.Create('invalid_argument',
      Format('"smooth.passes" must be a whole number from 0 to %d',
             [MAX_SMOOTH_PASSES]),
      FloatToStr(Passes, FitFmt));
  Req.SmoothPasses := Round(Passes);
  if Req.SmoothPasses = 0 then
    Exit;

  { MovAvg averages Window + 1 points; on a shorter curve it writes zeros over
    the tail, and the chi-squared takes the logarithm of the intensities. }
  if Length(Req.Data) <= FIT_SMOOTH_WINDOW then
    raise EMCPError.Create('invalid_argument',
      Format('"smooth" needs a measured curve of more than %d points',
             [FIT_SMOOTH_WINDOW]),
      IntToStr(Length(Req.Data)));

  for i := 1 to Req.SmoothPasses do
    Req.Data := MovAvg(Req.Data, FIT_SMOOTH_WINDOW);
end;

/// A curve a fit can read: at least two points, ordered by increasing theta.
procedure CheckMeasuredCurve(const Req: TFitRequest);
var
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
end;

/// theta_range {min, max}, defaulting to the range of the data, applied to the
/// curve. Leaves Req.Data restricted and Req.ThetaMin / ThetaMax on the range
/// the restricted curve actually spans.
procedure ApplyThetaRange(const Params: TJSONObject; var Req: TFitRequest);
var
  JRange: TJSONObject;
  Lo, Hi: Double;
begin
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
/// repeat (N > 1). Profile and irregular fits are refused because neither
/// TLFPSO_Poly nor TLFPSO_Irregular holds the period - it floats within the
/// thickness bounds - so there is nothing for the target to act on. The
/// default range is the start period +/-30%.
procedure ParsePeriodTarget(const JEntry: TJSONObject; const S: TFitStructure;
  const Info: TStructureInfo; const Mode: string; const Path: string;
  var Refs: TArray<TPeriodRef>);
var
  Probe: TFitParamRef;
  Ref: TPeriodRef;
  j, n: Integer;
begin
  if Mode = FIT_MODE_PROFILE then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "period" cannot be freed in a profile fit. TLFPSO_Poly does ' +
             'not hold the period at all - it floats within the thickness ' +
             'bounds - so bound the thicknesses instead', [Path]));
  if Mode = FIT_MODE_IRREGULAR then
    raise EMCPError.Create('invalid_argument',
      Format('%s: "period" cannot be freed in an irregular fit. ' +
             'TLFPSO_Irregular fits every period''s layers on their own and ' +
             'never holds the period - it floats within the thickness bounds - ' +
             'so bound the thicknesses instead', [Path]));

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
  const Info: TStructureInfo; const Mode: string;
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
      ParsePeriodTarget(JEntry, S, Info, Mode, Path, PeriodRefs);
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
/// beats it. Refuse it instead. The start value is a Single, and so is the
/// bound the engine clamps to (TFitValue.min/max), so they are compared as
/// Singles: a start of 7.7 on a bound of 7.7 is on the bound, not 2E-7 below
/// it, which is how the double 7.7 would have it.
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
    if (V < Single(Refs[n].Min)) or (V > Single(Refs[n].Max)) then
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

/// ScaleSolveWindow is "scale_solve_window" as given, the value the result
/// echoes; Result.ScaleWindowLog holds its log10(1 + w) for the engine.
function ParseFitParams(const Params: TJSONObject;
  out ScaleSolveWindow: Double): TFitParams;
var
  Win: Double;
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

  { The measured scale as a nuisance parameter solved inside the objective;
    see FIT_CHI2_SOLVED_DEFINITION. On by default, on the author's decision. }
  Result.SolveScale := JSONArgs.OptBool(Params, 'scale_solve', True);
  Win := JSONArgs.OptFloat(Params, 'scale_solve_window', DEF_SCALE_SOLVE_WINDOW);
  if Win < 0 then
    raise EMCPError.Create('invalid_argument',
      '"scale_solve_window" cannot be negative: it is the fraction the solved ' +
      'scale may differ from the anchored one', FloatToStr(Win, FitFmt));
  Result.ScaleWindowLog := Log10(1 + Win);
  ScaleSolveWindow := Win;

  { TFitParams.Smooth makes the irregular engine smooth each parameter over
    the periods (TLFPSO_Irregular.Smooth); ParsePeriodSmooth sets it from
    optimizer.period_smooth once the mode and the structure are known. It is
    not the GUI's Data - Smooth of the measured curve - that one is the
    "smooth" argument, ApplySmooth. }
  Result.Smooth       := False;
  Result.SmoothWindow := DEF_PERIOD_SMOOTH_WINDOW;

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

/// optimizer.device: where the population is evaluated. "gpu" is refused
/// here, not discovered in the job, when this machine has no usable GPU.
function ParseDevice(const Params: TJSONObject): string;
var
  Name, Err: string;
begin
  Result := LowerCase(JSONArgs.OptStr(JSONArgs.OptObj(Params, 'optimizer'),
    'device', 'auto'));
  if (Result <> 'auto') and (Result <> 'cpu') and (Result <> 'gpu') then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.device" must be "auto", "cpu" or "gpu"', Result);
  if (Result = 'gpu') and not TGpuEvaluator.Available(Name, Err) then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.device" is "gpu" but this machine has no usable GPU', Err);
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

/// "mode": "periodic" (default), "profile" or "irregular" - the GUI's three
/// fitting modes. "profile": true is the older spelling of "mode": "profile"
/// and is still accepted; the two may not disagree.
function ParseMode(const Params: TJSONObject): string;
var
  HasProfile: Boolean;
begin
  HasProfile := JSONArgs.Has(Params, 'profile');
  Result := LowerCase(Trim(JSONArgs.OptStr(Params, 'mode', '')));
  if Result = '' then
  begin
    if HasProfile and JSONArgs.OptBool(Params, 'profile', False) then
      Exit(FIT_MODE_PROFILE);
    Exit(FIT_MODE_PERIODIC);
  end;

  if (Result <> FIT_MODE_PERIODIC) and (Result <> FIT_MODE_PROFILE) and
     (Result <> FIT_MODE_IRREGULAR) then
    raise EMCPError.Create('invalid_argument',
      '"mode" must be "periodic", "profile" or "irregular"', Result);
  if HasProfile and (JSONArgs.OptBool(Params, 'profile', False) <>
                     (Result = FIT_MODE_PROFILE)) then
    raise EMCPError.Create('invalid_argument',
      '"profile" disagrees with "mode": "profile": true is the older spelling ' +
      'of "mode": "profile"; send "mode" alone', Result);
end;

/// TLFPSO_Irregular expands every repeating stack into its periods. On a
/// structure with none it is a periodic fit under another name, which is
/// refused rather than run, so that "mode": "irregular" always means that
/// the periods were fitted one by one.
procedure CheckIrregularIsPossible(const S: TFitStructure);
var
  i: Integer;
begin
  for i := 0 to High(S.Stacks) do
    if S.Stacks[i].N > 1 then
      Exit;
  raise EMCPError.Create('invalid_argument',
    '"mode": "irregular" needs a repeating stack (N > 1) to expand into its ' +
    'periods; this structure has none');
end;

/// optimizer.period_smooth and optimizer.period_smooth_window: the GUI's
/// Smooth box and Smoothing window, TFitParams.Smooth / SmoothWindow. After
/// every move TLFPSO_Irregular replaces each unpaired parameter's values over
/// the periods of its stack by their moving average over window + 1 periods
/// (unit_DataProcessing.Smooth; -1 = a tenth of the periods, at least 1). No
/// other engine reads it, so asking for it in another mode is refused. Held
/// parameters are not smoothed. The window may be at most half the periods of
/// the shortest repeating stack: Smooth averages the last W periods over the W
/// before each, and for W > N/2 that reaches before period 1.
procedure ParsePeriodSmooth(const Params: TJSONObject; var Req: TFitRequest);
var
  JOpt: TJSONObject;
  i, NMin: Integer;
  W: Double;
begin
  JOpt := JSONArgs.OptObj(Params, 'optimizer');
  Req.Fit.Smooth := JSONArgs.OptBool(JOpt, 'period_smooth', False);
  Req.Fit.SmoothWindow := DEF_PERIOD_SMOOTH_WINDOW;

  if Req.Fit.Smooth and not Req.Irregular then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.period_smooth" smooths each parameter over the periods of an ' +
      'irregular fit and needs "mode": "irregular"; the periodic and profile ' +
      'engines never read it', Req.Mode);

  if not JSONArgs.Has(JOpt, 'period_smooth_window') then
    Exit;
  if not Req.Fit.Smooth then
    raise EMCPError.Create('invalid_argument',
      '"optimizer.period_smooth_window" is the window of "period_smooth", ' +
      'which is off: set "period_smooth": true or leave the window out');

  NMin := MaxInt;
  for i := 0 to High(Req.Structure.Stacks) do
    if (Req.Structure.Stacks[i].N > 1) and (Req.Structure.Stacks[i].N < NMin) then
      NMin := Req.Structure.Stacks[i].N;

  W := JSONArgs.OptFloat(JOpt, 'period_smooth_window', DEF_PERIOD_SMOOTH_WINDOW);
  if (Frac(W) <> 0) or
     ((W <> -1) and ((W < 1) or (W > NMin div 2) or (W > High(ShortInt)))) then
    raise EMCPError.Create('invalid_argument',
      Format('"optimizer.period_smooth_window" must be -1 (automatic: a tenth ' +
             'of the periods) or a whole number from 1 to %d, half the ' +
             'periods of the shortest repeating stack',
             [Min(NMin div 2, Integer(High(ShortInt)))]),
      FloatToStr(W, FitFmt));
  Req.Fit.SmoothWindow := Round(W);
end;

const
  PROFILE_KEYS: array [1 .. 3] of string =
    ('thickness_profile', 'sigma_profile', 'density_profile');

/// True when any layer of "structure" carries a per-period array - which a
/// fitted_structure of a profile or irregular fit does.
function StructureHasProfiles(const JStructure: TJSONObject): Boolean;
var
  JStacks, JLayers: TJSONArray;
  k, i, p: Integer;
  JLayer: TJSONObject;
begin
  Result := False;
  JStacks := JSONArgs.OptArr(JStructure, 'stacks');
  if JStacks = nil then
    Exit;
  for k := 0 to JStacks.Count - 1 do
  begin
    if not (JStacks.Items[k] is TJSONObject) then
      Continue;
    JLayers := JSONArgs.OptArr(TJSONObject(JStacks.Items[k]), 'layers');
    if JLayers = nil then
      Continue;
    for i := 0 to JLayers.Count - 1 do
      if JLayers.Items[i] is TJSONObject then
      begin
        JLayer := TJSONObject(JLayers.Items[i]);
        for p := 1 to 3 do
          if JLayer.GetValue(PROFILE_KEYS[p]) <> nil then
            Exit(True);
      end;
  end;
end;

/// "start_profiles": true starts an irregular fit from per-period values - the
/// thickness_profile, sigma_profile and density_profile arrays on the layers
/// of "structure", which is how a previous profile or irregular fit reports
/// them - instead of starting every period from the layer's single value, as
/// the GUI's Run and Resume do. Each array runs from the surface end (entry 0
/// is period 1) and holds N values; a parameter without one starts every
/// period from its single value. The tables go into TLayerData.PP, where
/// BuildLayeredModel and TLFPSO_IrregularFromTable read them.
///
/// Without the flag the arrays are ignored, as they always have been. In
/// irregular mode that would start the fit from period 1's values and quietly
/// throw the rest of the table away, so there the client has to say which it
/// wants whenever the structure carries a table.
procedure ParseStartProfiles(const Params: TJSONObject; var Req: TFitRequest);
const
  MUST_BE: array [Boolean] of string = ('greater than zero', 'zero or more');
var
  JStructure, JLayer: TJSONObject;
  JStacks, JLayers, Arr: TJSONArray;
  k, i, p, c, GUIStack, N: Integer;
  V: Double;
  Path: string;
  Any: Boolean;
begin
  JStructure := JSONArgs.ReqObj(Params, 'structure');
  Req.StartProfiles := JSONArgs.OptBool(Params, 'start_profiles', False);

  if Req.StartProfiles and not Req.Irregular then
    raise EMCPError.Create('invalid_argument',
      '"start_profiles" starts an irregular fit from per-period values and ' +
      'needs "mode": "irregular"', Req.Mode);

  if not Req.Irregular then
    Exit;

  if not JSONArgs.Has(Params, 'start_profiles') then
  begin
    if StructureHasProfiles(JStructure) then
      raise EMCPError.Create('invalid_argument',
        'The structure carries per-period arrays (thickness_profile, ' +
        'sigma_profile or density_profile). Say what an irregular fit should ' +
        'do with them: "start_profiles": true starts each period from its own ' +
        'value, false starts every period from the layer''s single value and ' +
        'ignores the arrays');
    Exit;
  end;
  if not Req.StartProfiles then
    Exit;

  Any := False;
  JStacks := JSONArgs.ReqArr(JStructure, 'stacks');
  for k := 0 to JStacks.Count - 1 do
  begin
    GUIStack := Req.Info.StackMap[k];
    N := Req.Structure.Stacks[GUIStack].N;
    JLayers := JSONArgs.ReqArr(TJSONObject(JStacks.Items[k]), 'layers');
    for i := 0 to JLayers.Count - 1 do
    begin
      JLayer := TJSONObject(JLayers.Items[i]);
      for p := 1 to 3 do
      begin
        Path := Format('structure.stacks[%d].layers[%d].%s', [k, i, PROFILE_KEYS[p]]);
        if JLayer.GetValue(PROFILE_KEYS[p]) = nil then
          Continue;
        if not (JLayer.GetValue(PROFILE_KEYS[p]) is TJSONArray) then
          raise EMCPError.Create('invalid_argument',
            Path + ' must be an array of numbers, one per period');
        if N <= 1 then
          raise EMCPError.Create('invalid_argument',
            Format('%s: stack %d has N = 1, one period, and no per-period ' +
                   'values; give the value itself', [Path, k]));
        Arr := TJSONArray(JLayer.GetValue(PROFILE_KEYS[p]));
        if Arr.Count <> N then
          raise EMCPError.Create('invalid_argument',
            Format('%s must hold one value per period, %d, surface end first',
                   [Path, N]), IntToStr(Arr.Count));

        Req.Structure.Stacks[GUIStack].Layers[i].ClearProfiles(p);
        for c := 0 to Arr.Count - 1 do
        begin
          if not (Arr.Items[c] is TJSONNumber) then
            raise EMCPError.Create('invalid_argument',
              Format('%s[%d] must be a number', [Path, c]));
          V := TJSONNumber(Arr.Items[c]).AsDouble;
          if ((p <> 2) and not (V > 0)) or ((p = 2) and (V < 0)) then
            raise EMCPError.Create('invalid_argument',
              Format('%s[%d]: a %s must be %s',
                     [Path, c, PARAM_NAMES[p], MUST_BE[p = 2]]),
              FloatToStr(V, FitFmt));
          Req.Structure.Stacks[GUIStack].Layers[i].AddProfilePoint(V, p);
        end;
        Any := True;
      end;
    end;
  end;

  if not Any then
    raise EMCPError.Create('invalid_argument',
      '"start_profiles" is true but no layer of a repeating stack in ' +
      '"structure" carries a thickness_profile, sigma_profile or ' +
      'density_profile to start from');
end;

/// The per-period start values against the rest of the request, once "free",
/// "bounds" and "paired" are known. A paired parameter is one value in every
/// period, so a table for it contradicts the pairing. A free parameter must
/// start inside its bounds in every period, for the reason
/// CheckStartInsideBounds gives. A held one keeps the value its table gives
/// each period: TLFPSO_IrregularFromTable pins each period there.
procedure CheckStartProfiles(const Req: TFitRequest);
var
  i, j, p, c, n: Integer;
  L: TLayerData;
  V: Double;
  Where: string;
begin
  if not Req.StartProfiles then
    Exit;
  for i := 0 to High(Req.Structure.Stacks) do
    for j := 0 to High(Req.Structure.Stacks[i].Layers) do
    begin
      L := Req.Structure.Stacks[i].Layers[j];
      Where := '';
      for n := 0 to High(Req.Info.StackMap) do
        if Req.Info.StackMap[n] = i then
          Where := Format('stack %d, layer %d', [n, j]);
      for p := 1 to 3 do
      begin
        if Length(L.PP[p]) = 0 then
          Continue;
        if L.P[p].Paired then
          raise EMCPError.Create('invalid_argument',
            Format('%s: %s is paired - one value in every period - but the ' +
                   'structure gives it a %s. Drop the array or unpair it',
                   [Where, PARAM_NAMES[p], PROFILE_KEYS[p]]), PARAM_NAMES[p]);
        if L.P[p].min = L.P[p].max then
          Continue;                        // held: pinned to each period's value
        for c := 0 to High(L.PP[p]) do
        begin
          V := L.PP[p][c];
          if (V < L.P[p].min) or (V > L.P[p].max) then
            raise EMCPError.Create('invalid_argument',
              Format('the start value %.6g of "%s" in period %d (%s, %s[%d]) ' +
                     'lies outside its bounds [%.6g, %.6g]. The engine seeds ' +
                     'the swarm around the start value and clamps it to the ' +
                     'bounds: move the start value or widen the bounds',
                     [V, PARAM_NAMES[p], c + 1, Where, PROFILE_KEYS[p], c,
                      L.P[p].min, L.P[p].max]), PARAM_NAMES[p]);
        end;
      end;
    end;
end;

/// "paired": which layer parameters are held to one value over all the periods
/// instead of getting a polynomial (profile mode) or a value of their own in
/// each period (irregular mode). It is the GUI's Paired box - TFitValue.Paired,
/// the HP / SP / RP flags of the project file, which TLFPSO_Poly.Set_Init_XPoly
/// and TLFPSO_Irregular.SetStructure already honour - and the author's own
/// practice is to pair sigma and density and leave the thicknesses free.
///
/// An item is either a bare parameter name, which pairs that parameter in every
/// layer, or {"stack", "layer", "parameters"} addressed exactly as "free" is.
procedure ParsePaired(const Params: TJSONObject; var S: TFitStructure;
  const Info: TStructureInfo; const Mode: string;
  out Refs: TArray<TFitParamRef>);
var
  Arr, Names: TJSONArray;
  JEntry: TJSONObject;
  Item: TJSONValue;
  i, k, p, Count: Integer;
  Ref: TFitParamRef;
  Path: string;

  procedure Add(GUIStack, GUILayer, StackJSON, LayerJSON, Param: Integer;
    const StackLabel: string);
  var
    n: Integer;
  begin
    { The same parameter named twice, by a global entry and a per-layer one, is
      one pairing and one line in the result. }
    for n := 0 to Count - 1 do
      if (Refs[n].GUIStack = GUIStack) and (Refs[n].GUILayer = GUILayer) and
         (Refs[n].P = Param) then
        Exit;
    SetLength(Refs, Count + 1);
    Refs[Count] := Default(TFitParamRef);
    Refs[Count].GUIStack := GUIStack;
    Refs[Count].GUILayer := GUILayer;
    Refs[Count].StackJSON := StackJSON;
    Refs[Count].LayerJSON := LayerJSON;
    Refs[Count].StackLabel := StackLabel;
    Refs[Count].P := Param;
    Inc(Count);
    S.Stacks[GUIStack].Layers[GUILayer].P[Param].Paired := True;
  end;

  /// A bare parameter name pairs that parameter in every layer of every stack,
  /// which is what the GUI's Paired column does when it is ticked down the page.
  procedure AddEverywhere(Param: Integer);
  var
    gs, gl, js, j: Integer;
    Lbl: string;
  begin
    for gs := 0 to High(S.Stacks) do
    begin
      Lbl := '';
      js := -1;
      if gs = Info.CapIndex then
        Lbl := 'cap'
      else if gs = Info.BufferIndex then
        Lbl := 'buffer'
      else
        for j := 0 to High(Info.StackMap) do
          if Info.StackMap[j] = gs then
            js := j;
      for gl := 0 to High(S.Stacks[gs].Layers) do
        Add(gs, gl, js, gl, Param, Lbl);
    end;
  end;

begin
  Refs := nil;
  Count := 0;

  Arr := JSONArgs.OptArr(Params, 'paired');
  if (Arr = nil) or (Arr.Count = 0) then
    Exit;

  if Mode = FIT_MODE_PERIODIC then
    raise EMCPError.Create('invalid_argument',
      '"paired" only means something with "mode": "profile" or "irregular" - ' +
      'it says which parameters keep one value over the periods instead of ' +
      'getting a polynomial or a value per period of their own. A periodic ' +
      'fit has one value per layer already.');

  for i := 0 to Arr.Count - 1 do
  begin
    Path := Format('paired[%d]', [i]);
    Item := Arr.Items[i];

    if Item is TJSONString then
    begin
      AddEverywhere(ParameterIndex(TJSONString(Item).Value, Path));
      Continue;
    end;

    if not (Item is TJSONObject) then
      raise EMCPError.Create('invalid_argument',
        'Every item of "paired" is a parameter name or an object with ' +
        '"stack", "layer" and "parameters"', Path);

    JEntry := TJSONObject(Item);
    Ref := Default(TFitParamRef);
    ResolveStack(JEntry, Info, Path, Ref);
    ResolveLayer(JEntry, S, Path, Ref);

    Names := JSONArgs.OptArr(JEntry, 'parameters');
    if (Names = nil) or (Names.Count = 0) then
      raise EMCPError.Create('invalid_argument',
        '"parameters" lists which of "thickness", "sigma" and "density" of ' +
        'that layer are paired', Path);

    for k := 0 to Names.Count - 1 do
    begin
      p := ParameterIndex(Names.Items[k].Value,
                          Format('%s.parameters[%d]', [Path, k]));
      Add(Ref.GUIStack, Ref.GUILayer, Ref.StackJSON, Ref.LayerJSON, p,
          Ref.StackLabel);
    end;
  end;
end;

/// The parameters "paired" held constant, in the address shape of bounds_used.
function PairedJSON(const Refs: TArray<TFitParamRef>;
  const Info: TStructureInfo): TJSONArray;
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
      Obj.AddPair('stack', StackAddress(Info, Refs[n].GUIStack));
      Obj.AddPair('layer', TJSONNumber.Create(Refs[n].LayerJSON));
      Obj.AddPair('parameter', PARAM_NAMES[Refs[n].P]);
    end;
  except
    Result.Free;
    raise;
  end;
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

  { The engine, and the per-period start values an irregular fit may begin
    from, before anything computes the start model: "scale": "auto" does. }
  Result.Mode := ParseMode(Params);
  Result.Profile := Result.Mode = FIT_MODE_PROFILE;
  Result.Irregular := Result.Mode = FIT_MODE_IRREGULAR;
  if Result.Profile then
    CheckProfileIsPossible(Result.Structure);
  if Result.Irregular then
    CheckIrregularIsPossible(Result.Structure);
  ParseStartProfiles(Params, Result);

  ReadMeasuredCurve(Params, Result);
  CheckMeasuredCurve(Result);

  { The calculation settings are read before the data are conditioned because
    "scale": "auto" computes the start model on the measured grid and needs
    them. CheckResolutionFits still runs on the trimmed curve, below, where it
    always has. }
  Result.Resolution := JSONArgs.OptFloat(Params, 'resolution', DEF_RESOLUTION);
  if Result.Resolution < 0 then
    raise EMCPError.Create('invalid_argument', '"resolution" must not be negative');

  Result.RMin := JSONArgs.OptFloat(Params, 'r_min', DEF_R_MIN);
  if Result.RMin <= 0 then
    raise EMCPError.Create('invalid_argument', '"r_min" must be greater than zero');

  PolStr := JSONArgs.OptStr(Params, 'polarization', 'sp');
  Result.Polarization := ParseFitPolarization(PolStr, Result.PolarizationName);

  { The manual's data conditioning, in its order: normalize, smooth, trim. }
  ApplyScale(Params, Result);
  ApplySmooth(Params, Result);
  ApplyThetaRange(Params, Result);
  CheckResolutionFits(Result.Data, Result.Resolution);

  { Every omitted density becomes the bulk value the engine would use for it,
    before "free" and "bounds" are read: the engines seed the swarm around the
    start value and clamp it to the bounds, so a free density that started at
    the 0 sentinel under a lower bound of, say, 8 would pin every particle at
    8 while particle 0 kept the bulk value - a fit that never moves. With the
    bulk value in place a free density gets its +/-30% default like any other
    parameter, and start_structure reports what the fit started from. }
  FillEngineDensities(Result.Structure, Result.Lambda);

  Result.InlineMax := JSONArgs.OptInt(Params, 'points_inline_max', DEF_INLINE_MAX);
  if Result.InlineMax < 0 then
    raise EMCPError.Create('invalid_argument',
      '"points_inline_max" must not be negative');

  Result.FreeParams := ParseFree(Params, Result.Structure, Result.Info,
                                 Result.Mode, Result.PeriodRefs);
  ParseBounds(Params, Result.Structure, Result.Info, Result.FreeParams,
              Result.PeriodRefs);
  CheckStartInsideBounds(Result.Structure, Result.FreeParams, Result.PeriodRefs);
  ApplyBounds(Result.Structure, Result.FreeParams);
  ParsePaired(Params, Result.Structure, Result.Info, Result.Mode,
              Result.PairedParams);
  CheckStartProfiles(Result);

  Result.Fit := ParseFitParams(Params, Result.ScaleSolveWindow);
  ParsePeriodSmooth(Params, Result);
  Result.PointWeight := JSONArgs.OptBool(JSONArgs.OptObj(Params, 'chi2'),
                                         'point_weight', True);
  Result.Device := ParseDevice(Params);
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

type
  /// <summary>TLFPSO_Irregular started from per-period values
  /// ("start_profiles"). Once the engine has expanded the repeating stacks,
  /// each period's start value is its entry of the layer's table
  /// (TLayerData.PP, read through PeriodValue exactly as the GUI's model reads
  /// it) instead of the layer's single value. A free parameter keeps the
  /// layer's bounds in every period; a held one (min = max) is pinned to its
  /// own period's value. Both go into the engine's flattened structure as well
  /// as into particle 0, because a shake re-seeds the swarm from that
  /// structure.</summary>
  TLFPSO_IrregularFromTable = class(TLFPSO_Irregular)
  protected
    procedure SetStructure(const Inp: TFitStructure); override;
  end;

procedure TLFPSO_IrregularFromTable.SetStructure(const Inp: TFitStructure);
var
  i, j, k, p, Index: Integer;
  Val: TFitValue;
begin
  inherited;
  { A shake hands back the engine's own flattened structure, which carries
    the table's values and the pinned bounds already. }
  if FReInit then
    Exit;

  { The order TLFPSO_Irregular.SetStructure expands in: stack by stack,
    period 1 (the surface end) first, the layers of each period in turn. }
  Index := 0;
  for i := 0 to High(Inp.Stacks) do
    for k := 1 to Inp.Stacks[i].N do
      for j := 0 to High(Inp.Stacks[i].Layers) do
      begin
        for p := 1 to 3 do
        begin
          Val := Inp.Stacks[i].Layers[j].P[p];
          Val.V := Inp.Stacks[i].Layers[j].PeriodValue(p, k, Inp.Stacks[i].N, True);
          if Val.min = Val.max then
          begin
            Val.min := Val.V;
            Val.max := Val.V;
          end;
          Set_Init_X(Index, p, Val);
          FStructure.Stacks[0].Layers[Index].P[p] := Val;
        end;
        Inc(Index);
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

/// One scan of Model on the measured angles, with the two chi-squareds that go
/// with it: the weighted one the fit minimises and the unweighted one beside
/// it. Model is handed to TCalc, which frees it.
function ScanOnData(const Req: TFitRequest; Model: TLayeredModel;
  const MovAvgCurve: unit_Types.TDataArray;
  out Chi2, Chi2Plain: Double): unit_Types.TDataArray;
var
  ScaleLog: Double;
  Clamped: Boolean;
begin
  Result := ScanOnData(Req, Model, MovAvgCurve, Chi2, Chi2Plain, ScaleLog, Clamped);
end;

function ScanOnData(const Req: TFitRequest; Model: TLayeredModel;
  const MovAvgCurve: unit_Types.TDataArray;
  out Chi2, Chi2Plain, ScaleLog: Double; out ScaleClamped: Boolean): unit_Types.TDataArray;
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
    Calc.SolveScale     := Req.Fit.SolveScale;
    Calc.ScaleWindowLog := Req.Fit.ScaleWindowLog;
    Calc.Model     := Model;          // TCalc.Destroy frees it from here on
    Calc.Run;
    Chi2 := Calc.CalcChiSquare(Req.Fit.ThetaWeight);
    Chi2Plain := Calc.ChiSQRPlain;
    ScaleLog := Calc.ScaleLog;
    ScaleClamped := Calc.ScaleClamped;
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

/// log10 I - log10 R per point, with the solved log10 scale added to the
/// measured side when there is one, so the residual is the disagreement the
/// fit minimised.
function ResidualCurve(const Data, Calc: unit_Types.TDataArray;
  const ScaleLog: Double = 0): unit_Types.TDataArray;
var
  i, n: Integer;
begin
  n := Min(Length(Data), Length(Calc));
  SetLength(Result, n);
  for i := 0 to n - 1 do
  begin
    Result[i].t := Data[i].t;
    if (Data[i].r > 0) and (Calc[i].r > 0) then
      Result[i].r := Log10(Data[i].r) + ScaleLog - Log10(Calc[i].r)
    else
      Result[i].r := 0;
  end;
end;

/// The measured curve at the scale a chi2 was taken at: every intensity
/// times 10^ScaleLog, which is what ResidualCurve adds in log space. The fit
/// report reads orders, edge and bands off this curve, so its ratios are on
/// the same footing as chi2, residual.dat and the GUI chart.
function ScaledCurve(const Data: unit_Types.TDataArray;
  const ScaleLog: Double): unit_Types.TDataArray;
var
  i: Integer;
  K: Double;
begin
  Result := Copy(Data);
  if ScaleLog = 0 then
    Exit;
  K := Power(10, ScaleLog);
  for i := 0 to High(Result) do
    Result[i].r := Result[i].r * K;
end;

{ ------------------------------------------------------- result assembly -- }

type
  /// <summary>One layer of a repeating stack and its thickness, sigma and
  /// density in each period, surface end first, which is what a gradient fit
  /// produces and a plain fit does not.</summary>
  TLayerProfile = record
    GUIStack, GUILayer: Integer;
    Thickness, Sigma, Density: TArray<Single>;
  end;

/// A free parameter's values in each period of an irregular fit, surface end
/// first; nil when it is one value - an N = 1 layer, a paired parameter, or
/// any other mode - and the fitted structure's single value is the answer.
function PerPeriodValues(const Req: TFitRequest; const Ref: TFitParamRef;
  const Profiles: TArray<TLayerProfile>): TArray<Single>; forward;

/// One parameter's per-period values out of a TLayerProfile; nil when the
/// layer has none.
function ProfileValues(const Profiles: TArray<TLayerProfile>;
  GUIStack, GUILayer, P: Integer): TArray<Single>;
var
  n: Integer;
begin
  Result := nil;
  for n := 0 to High(Profiles) do
    if (Profiles[n].GUIStack = GUIStack) and (Profiles[n].GUILayer = GUILayer) then
      case P of
        1: Exit(Profiles[n].Thickness);
        2: Exit(Profiles[n].Sigma);
        3: Exit(Profiles[n].Density);
      end;
end;

function PerPeriodValues(const Req: TFitRequest; const Ref: TFitParamRef;
  const Profiles: TArray<TLayerProfile>): TArray<Single>;
begin
  Result := nil;
  if Req.Irregular and
     not Req.Structure.Stacks[Ref.GUIStack].Layers[Ref.GUILayer].P[Ref.P].Paired then
    Result := ProfileValues(Profiles, Ref.GUIStack, Ref.GUILayer, Ref.P);
end;

/// How many independent values an irregular fit searched: a free parameter of
/// a repeating layer is a value in each of its stack's N periods, or one value
/// for all of them when it is paired; a free parameter of an N = 1 stack is one.
function FreeValueCount(const Req: TFitRequest): Integer;
var
  n, GS, GL: Integer;
begin
  Result := 0;
  for n := 0 to High(Req.FreeParams) do
  begin
    GS := Req.FreeParams[n].GUIStack;
    GL := Req.FreeParams[n].GUILayer;
    if Req.Structure.Stacks[GS].Layers[GL].P[Req.FreeParams[n].P].Paired then
      Inc(Result)
    else
      Inc(Result, Req.Structure.Stacks[GS].N);
  end;
end;

/// The period of each repetition of one stack, surface end first: the sum of
/// its layers' thicknesses in that period. Empty when the profiles do not
/// cover the stack.
function PeriodsOf(const Profiles: TArray<TLayerProfile>;
  GUIStack: Integer): TArray<Double>;
var
  n, c: Integer;
begin
  Result := nil;
  for n := 0 to High(Profiles) do
    if Profiles[n].GUIStack = GUIStack then
    begin
      if Result = nil then
        SetLength(Result, Length(Profiles[n].Thickness));
      for c := 0 to Min(High(Result), High(Profiles[n].Thickness)) do
        Result[c] := Result[c] + Profiles[n].Thickness[c];
    end;
end;

function MeanOf(const V: TArray<Double>): Double;
var
  c: Integer;
begin
  Result := 0;
  for c := 0 to High(V) do
    Result := Result + V[c];
  if Length(V) > 0 then
    Result := Result / Length(V);
end;

/// The per-period values a structure's tables describe, in the shape
/// CollectLayerProfiles gives a fitted model: every layer of every repeating
/// stack, each parameter from its table where it has one and from its single
/// value otherwise (TLayerData.PeriodValue, as the model is built).
function TableProfiles(const S: TFitStructure): TArray<TLayerProfile>;
var
  i, j, k, n: Integer;
begin
  Result := nil;
  for i := 0 to High(S.Stacks) do
  begin
    if S.Stacks[i].N <= 1 then
      Continue;
    for j := 0 to High(S.Stacks[i].Layers) do
    begin
      n := Length(Result);
      SetLength(Result, n + 1);
      Result[n].GUIStack := i;
      Result[n].GUILayer := j;
      SetLength(Result[n].Thickness, S.Stacks[i].N);
      SetLength(Result[n].Sigma, S.Stacks[i].N);
      SetLength(Result[n].Density, S.Stacks[i].N);
      for k := 1 to S.Stacks[i].N do
      begin
        Result[n].Thickness[k - 1] := S.Stacks[i].Layers[j].PeriodValue(1, k, S.Stacks[i].N, True);
        Result[n].Sigma[k - 1]     := S.Stacks[i].Layers[j].PeriodValue(2, k, S.Stacks[i].N, True);
        Result[n].Density[k - 1]   := S.Stacks[i].Layers[j].PeriodValue(3, k, S.Stacks[i].N, True);
      end;
    end;
  end;
end;

/// TLFPSO_Irregular's result in the shape of the start model. Each layer takes
/// the values of its first period - the surface end - which is what the GUI's
/// TXRCStructure.UpdateInterfaceNP writes back into the layer; the periods
/// themselves go into its tables (SetFittedTables). Bounds, pairing and
/// materials are the start model's.
function UnflattenIrregular(const Start, Flat: TFitStructure): TFitStructure;
var
  i, j, p, Count: Integer;
begin
  Start.CopyContent(Result);
  Count := 0;
  for i := 0 to High(Result.Stacks) do
  begin
    for j := 0 to High(Result.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
      begin
        Result.Stacks[i].Layers[j].P[p].V := Flat.Stacks[0].Layers[Count].P[p].V;
        Result.Stacks[i].Layers[j].ClearProfiles(p);
      end;
      Inc(Count);
    end;
    Inc(Count, (Result.Stacks[i].N - 1) * Length(Result.Stacks[i].Layers));
  end;
end;

/// The fitted periods as the layers' tables, which the .xrcx stores and the
/// GUI's Table extension expands: what TXRCStructure.UpdateProfiles writes
/// after an irregular fit, every unpaired parameter of every repeating layer.
procedure SetFittedTables(var S: TFitStructure; const Profiles: TArray<TLayerProfile>);
var
  n, k, c, GS, GL: Integer;
  V: TArray<Single>;
begin
  for n := 0 to High(Profiles) do
  begin
    GS := Profiles[n].GUIStack;
    GL := Profiles[n].GUILayer;
    for k := 1 to 3 do
    begin
      S.Stacks[GS].Layers[GL].ClearProfiles(k);
      if S.Stacks[GS].Layers[GL].P[k].Paired then
        Continue;
      V := ProfileValues(Profiles, GS, GL, k);
      for c := 0 to High(V) do
        S.Stacks[GS].Layers[GL].AddProfilePoint(V[c], k);
    end;
  end;
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

/// How close to a bound a fitted value has to sit, as a fraction of the range,
/// before the report names it. A parameter that stops on its own bound has not
/// been fitted: the answer is wherever the client allowed it to stop.
const
  NEAR_BOUND_FRACTION = 0.05;

/// The period the report counts its orders on: the first repeating stack of the
/// structure, which is the one calc_reflectivity reports peaks for. 0 when the
/// structure has no repeating stack.
function ReportPeriod(const S: TFitStructure; const Info: TStructureInfo): Double;
begin
  if Info.PeriodicStackIndex < 0 then
    Result := 0
  else
    Result := StackPeriod(S, Info.PeriodicStackIndex);
end;

/// Every fitted value within NEAR_BOUND_FRACTION of its own range of either end
/// of it, in the shape of bounds_used plus the value, which end it is near and
/// how far away it is as a fraction of the range. In an irregular fit a free
/// parameter of a repeating layer is a value in every period, and each period
/// is considered on its own: its entry carries "period_index", the index into
/// that layer's *_profile array (0 = period 1, the surface end).
function NearBoundsJSON(const Req: TFitRequest; const Fitted: TFitStructure;
  const Profiles: TArray<TLayerProfile>): TJSONArray;
var
  n, c: Integer;
  V, Lo, Hi, Range, DLo, DHi: Double;
  Obj: TJSONObject;
  PerPeriod: TArray<Single>;

  procedure Consider(const Target: string; StackJSON, LayerJSON: Integer;
    const Param: string; PeriodIndex: Integer = -1);
  begin
    Range := Hi - Lo;
    if Range <= 0 then
      Exit;
    DLo := (V - Lo) / Range;
    DHi := (Hi - V) / Range;
    if (DLo > NEAR_BOUND_FRACTION) and (DHi > NEAR_BOUND_FRACTION) then
      Exit;

    Obj := TJSONObject.Create;
    Result.AddElement(Obj);
    Obj.AddPair('target', Target);
    if Target = 'period' then
      Obj.AddPair('stack', TJSONNumber.Create(StackJSON))
    else
      Obj.AddPair('stack', StackAddress(Req.Info, StackJSON));
    if Target <> 'period' then
      Obj.AddPair('layer', TJSONNumber.Create(LayerJSON));
    Obj.AddPair('parameter', Param);
    if PeriodIndex >= 0 then
      Obj.AddPair('period_index', TJSONNumber.Create(PeriodIndex));
    Obj.AddPair('value', JSONArgs.Num(V));
    Obj.AddPair('min', JSONArgs.Num(Lo));
    Obj.AddPair('max', JSONArgs.Num(Hi));
    if DLo <= DHi then
      Obj.AddPair('bound', 'min')
    else
      Obj.AddPair('bound', 'max');
    Obj.AddPair('margin_fraction', JSONArgs.Num(Min(DLo, DHi)));
  end;

begin
  Result := TJSONArray.Create;
  try
    for n := 0 to High(Req.FreeParams) do
    begin
      Lo := Req.FreeParams[n].Min;
      Hi := Req.FreeParams[n].Max;
      PerPeriod := PerPeriodValues(Req, Req.FreeParams[n], Profiles);
      if Length(PerPeriod) > 0 then
      begin
        for c := 0 to High(PerPeriod) do
        begin
          V := PerPeriod[c];
          Consider('layer', Req.FreeParams[n].GUIStack, Req.FreeParams[n].LayerJSON,
                   PARAM_NAMES[Req.FreeParams[n].P], c);
        end;
        Continue;
      end;
      V := Fitted.Stacks[Req.FreeParams[n].GUIStack]
                 .Layers[Req.FreeParams[n].GUILayer].P[Req.FreeParams[n].P].V;
      Consider('layer', Req.FreeParams[n].GUIStack, Req.FreeParams[n].LayerJSON,
               PARAM_NAMES[Req.FreeParams[n].P]);
    end;

    for n := 0 to High(Req.PeriodRefs) do
    begin
      V := StackPeriod(Fitted, Req.PeriodRefs[n].GUIStack);
      Lo := Req.PeriodRefs[n].Min;
      Hi := Req.PeriodRefs[n].Max;
      Consider('period', Req.PeriodRefs[n].StackJSON, 0, 'period');
    end;
  except
    Result.Free;
    raise;
  end;
end;

/// Every fitted value that lies outside the bound the client gave, in the shape
/// of bounds_used plus "value": a safety net behind the engine's own clamping
/// (CheckLimits, XSeed and NormalizeD all keep a particle inside its bounds
/// since 2026-09-16), so that a client is never handed a silent violation.
/// The comparison is against the bounds as the engine holds them - single
/// precision, TFitValue.min/max - so a value clamped exactly to a bound is
/// inside it. In an irregular fit every period of a free repeating parameter
/// is checked, with "period_index" as in near_bounds, and one part in 1e6 of
/// slack: period_smooth averages values in single precision after the clamp.
function OutOfBoundsJSON(const Req: TFitRequest; const Fitted: TFitStructure;
  const Profiles: TArray<TLayerProfile>): TJSONArray;

  procedure Add(const Target: string; StackJSON, LayerJSON: Integer;
    const Param: string; Value, AMin, AMax: Double; PeriodIndex: Integer = -1);
  var
    Obj: TJSONObject;
  begin
    Obj := TJSONObject.Create;
    Result.AddElement(Obj);
    Obj.AddPair('target', Target);
    Obj.AddPair('stack', TJSONNumber.Create(StackJSON));
    if Target = 'layer' then
      Obj.AddPair('layer', TJSONNumber.Create(LayerJSON));
    Obj.AddPair('parameter', Param);
    if PeriodIndex >= 0 then
      Obj.AddPair('period_index', TJSONNumber.Create(PeriodIndex));
    Obj.AddPair('value', JSONArgs.Num(Value));
    Obj.AddPair('min', JSONArgs.Num(AMin));
    Obj.AddPair('max', JSONArgs.Num(AMax));
  end;

var
  n, c: Integer;
  V: Single;
  D, Slack: Double;
  PerPeriod: TArray<Single>;
begin
  Result := TJSONArray.Create;
  try
    for n := 0 to High(Req.FreeParams) do
      with Req.FreeParams[n] do
      begin
        PerPeriod := PerPeriodValues(Req, Req.FreeParams[n], Profiles);
        if Length(PerPeriod) > 0 then
        begin
          Slack := 1E-6 * System.Math.Max(Abs(Min), Abs(Max));
          for c := 0 to High(PerPeriod) do
            if (PerPeriod[c] < Single(Min) - Slack) or (PerPeriod[c] > Single(Max) + Slack) then
              Add('layer', StackJSON, LayerJSON, PARAM_NAMES[P], PerPeriod[c], Min, Max, c);
          Continue;
        end;
        V := Fitted.Stacks[GUIStack].Layers[GUILayer].P[P].V;
        if (V < Single(Min)) or (V > Single(Max)) then
          Add('layer', StackJSON, LayerJSON, PARAM_NAMES[P], V, Min, Max);
      end;
    for n := 0 to High(Req.PeriodRefs) do
      with Req.PeriodRefs[n] do
      begin
        { the sum of single-precision thicknesses against a single-precision
          bound, with one ulp per layer of slack for the summation }
        D := StackPeriod(Fitted, GUIStack);
        if (D < Single(Min) * (1 - 1E-6)) or (D > Single(Max) * (1 + 1E-6)) then
          Add('period', StackJSON, -1, 'period', D, Min, Max);
      end;
  except
    Result.Free;
    raise;
  end;
end;

/// One entry per repeating stack, in JSON order: how its period was treated -
/// "held" at the start value (the periodic engine's default), "free" inside
/// the bounds given, or "floating" (a profile or irregular fit, where neither
/// TLFPSO_Poly nor TLFPSO_Irregular constrains it) - with the start and fitted
/// periods in Angstrom. In an irregular fit every period is fitted on its own:
/// start_A and fitted_A are then the mean over the periods, and fitted_A_min
/// and fitted_A_max the shortest and the longest.
function PeriodModeJSON(const Req: TFitRequest; const Fitted: TFitStructure;
  const StartProfiles, FittedProfiles: TArray<TLayerProfile>): TJSONArray;
var
  k, n, c, GUIStack: Integer;
  Obj: TJSONObject;
  Mode: string;
  Ref: TPeriodRef;
  IsFree: Boolean;
  Periods: TArray<Double>;
  PMin, PMax: Double;
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

      if Req.Profile or Req.Irregular then
        Mode := 'floating'
      else if IsFree then
        Mode := 'free'
      else
        Mode := 'held';

      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('stack', TJSONNumber.Create(k));
      Obj.AddPair('mode', Mode);
      if Req.Irregular then
      begin
        Periods := PeriodsOf(StartProfiles, GUIStack);
        if Length(Periods) > 0 then
          Obj.AddPair('start_A', JSONArgs.Num(MeanOf(Periods)))
        else
          Obj.AddPair('start_A', JSONArgs.Num(StackPeriod(Req.Structure, GUIStack)));
        Periods := PeriodsOf(FittedProfiles, GUIStack);
        if Length(Periods) = 0 then
          Periods := [StackPeriod(Fitted, GUIStack)];
        PMin := Periods[0];
        PMax := Periods[0];
        for c := 1 to High(Periods) do
        begin
          PMin := System.Math.Min(PMin, Periods[c]);
          PMax := System.Math.Max(PMax, Periods[c]);
        end;
        Obj.AddPair('fitted_A', JSONArgs.Num(MeanOf(Periods)));
        Obj.AddPair('fitted_A_min', JSONArgs.Num(PMin));
        Obj.AddPair('fitted_A_max', JSONArgs.Num(PMax));
      end
      else
      begin
        Obj.AddPair('start_A', JSONArgs.Num(StackPeriod(Req.Structure, GUIStack)));
        Obj.AddPair('fitted_A', JSONArgs.Num(StackPeriod(Fitted, GUIStack)));
      end;
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

/// One layer's thickness, sigma and density in each of the periods it occurs
/// in, lifted out of the expanded model before that model is handed to a TCalc
/// that will free it. TLFPSO_Poly.FillModel writes every period's value into
/// the model itself (Poly(j, ...) for period j = 1..N, added from the ambient
/// down), so the arrays run from the surface end of the stack to the substrate
/// end. Model layer 0 is the ambient and the last one is the substrate; the
/// rest carry the stack and layer index FillModel copied from the structure.
/// Layers that occur once have no profile and are not listed.
function CollectLayerProfiles(Model: TLayeredModel): TArray<TLayerProfile>;
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
    Result[Found].Sigma     := Result[Found].Sigma + [Layers[i].s];
    Result[Found].Density   := Result[Found].Density + [Layers[i].ro];
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

/// True when not every period holds the same value: a paired parameter is one
/// value copied into each period and has no profile worth reporting.
function VariesOverPeriods(const V: TArray<Single>): Boolean;
var
  c: Integer;
begin
  Result := False;
  for c := 1 to High(V) do
    if V[c] <> V[0] then
      Exit(True);
end;

procedure AddProfile(JLayer: TJSONObject; const Key: string; const V: TArray<Single>);
var
  Prof: TJSONArray;
  c: Integer;
begin
  Prof := TJSONArray.Create;
  JLayer.AddPair(Key, Prof);
  for c := 0 to High(V) do
    Prof.AddElement(JSONArgs.Num(V[c]));
end;

/// The fitted structure in the requirements' section 3 shape, with each layer's
/// per-period values added when the fit produced them. A profile fit adds the
/// thickness always, and sigma and density where they vary (not paired). An
/// irregular fit adds every parameter that is not paired, whether it varies or
/// not: each unpaired parameter is a value of its own in every period there,
/// and the layer's single value is period 1's.
function FittedStructureJSON(const S: TFitStructure; const Info: TStructureInfo;
  const Profiles: TArray<TLayerProfile>; Irregular: Boolean = False): TJSONObject;
var
  JStacks, JLayers: TJSONArray;
  JLayer: TJSONObject;
  k, i, n, Idx: Integer;
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
            JLayer := JLayers.Items[i] as TJSONObject;
            if Irregular then
            begin
              if not S.Stacks[Idx].Layers[i].P[1].Paired then
                AddProfile(JLayer, 'thickness_profile', Profiles[n].Thickness);
              if not S.Stacks[Idx].Layers[i].P[2].Paired then
                AddProfile(JLayer, 'sigma_profile', Profiles[n].Sigma);
              if not S.Stacks[Idx].Layers[i].P[3].Paired then
                AddProfile(JLayer, 'density_profile', Profiles[n].Density);
              Continue;
            end;
            AddProfile(JLayer, 'thickness_profile', Profiles[n].Thickness);
            if VariesOverPeriods(Profiles[n].Sigma) then
              AddProfile(JLayer, 'sigma_profile', Profiles[n].Sigma);
            if VariesOverPeriods(Profiles[n].Density) then
              AddProfile(JLayer, 'density_profile', Profiles[n].Density);
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

/// The optimizer the run used, every key of the "optimizer" argument with the
/// defaults filled in. request.json stores the arguments as sent, so without
/// this a job that named no population cannot be told apart from one that
/// did, and a change of a default (500 particles since 2026-09-17) would be
/// invisible in job_result.
function OptimizerUsedJSON(const Req: TFitRequest): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('population', TJSONNumber.Create(Req.Fit.Pop));
    Result.AddPair('iterations', TJSONNumber.Create(Req.Fit.NMax));
    Result.AddPair('tolerance', JSONArgs.Num(FromSingle(Req.Fit.Tolerance)));
    Result.AddPair('shake', TJSONBool.Create(Req.Fit.Shake));
    Result.AddPair('range_seed', TJSONBool.Create(Req.Fit.RangeSeed));
    Result.AddPair('jamming_max', TJSONNumber.Create(Req.Fit.JammingMax));
    Result.AddPair('reinit_max', TJSONNumber.Create(Req.Fit.ReInitMax));
    Result.AddPair('k_chi', JSONArgs.Num(FromSingle(Req.Fit.KChiSqr)));
    Result.AddPair('k_vmax', JSONArgs.Num(FromSingle(Req.Fit.KVmax)));
    Result.AddPair('w1', JSONArgs.Num(FromSingle(Req.Fit.w1)));
    Result.AddPair('w2', JSONArgs.Num(FromSingle(Req.Fit.w2)));
    Result.AddPair('vmax', JSONArgs.Num(FromSingle(Req.Fit.Vmax)));
    Result.AddPair('adapt_velocity', TJSONBool.Create(Req.Fit.AdaptVel));
    Result.AddPair('use_constriction', TJSONBool.Create(Req.Fit.UseConstriction));
    Result.AddPair('ksxr', JSONArgs.Num(FromSingle(Req.Fit.Ksxr)));
    Result.AddPair('poly_factor', TJSONNumber.Create(Req.Fit.PolyFactor));
    Result.AddPair('poly_order', TJSONNumber.Create(Req.Fit.MaxPOrder));
    Result.AddPair('period_smooth', TJSONBool.Create(Req.Fit.Smooth));
    Result.AddPair('period_smooth_window', TJSONNumber.Create(Req.Fit.SmoothWindow));
    Result.AddPair('device', Req.Device);
  except
    Result.Free;
    raise;
  end;
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
  if Req.Irregular then
    Result.FitMode := 0
  else if Req.Profile then
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
  if Req.SmoothPasses > 0 then
    P.Note := P.Note + Format(', Data - Smooth x %d', [Req.SmoothPasses]);
  { An irregular fit's periods are the layers' tables, which the GUI expands
    only while the model has a Table extension: the one it attaches after an
    irregular fit (TfrmProjectPanel.CreateProfileExtension). }
  P.XRCData    := StructureToXRCData(Fitted, Req.Info);
  P.Extensions := FitExtensions(Poly);
  P.TableExtension := Req.Irregular;
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
  Profiles, StartProfiles: TArray<TLayerProfile>;
  MovAvgCurve, CalcCurve, StartCalcCurve, Residual: unit_Types.TDataArray;
  Chi2, Chi2Recalc, Chi2Start, Scale: Double;
  Chi2Plain, Chi2StartPlain: Double;
  IterationsRun: Integer;
  DeviceUsed, GpuError: string;
  ScaleLogStart, ScaleLogFit: Double;
  ClampedStart, ClampedFit: Boolean;
  MeasuredPath, CalcPath, ResidualPath, XRCXPath, ReportPath: string;
  Res, JFiles, JSmooth, Report: TJSONObject;
  RepInp: TFitReportInput;
  EngineName: string;
begin
  if Job = nil then
    raise EMCPError.Create('internal', 'The fit job body was called without a job');

  Job.MaxIterations := Req.Fit.NMax;

  MeasuredPath := TPath.Combine(Job.Dir, 'measured.dat');
  CalcPath     := TPath.Combine(Job.Dir, 'calc.dat');
  ResidualPath := TPath.Combine(Job.Dir, 'residual.dat');
  XRCXPath     := TPath.Combine(Job.Dir, 'fit.xrcx');
  ReportPath   := TPath.Combine(Job.Dir, 'report.json');
  WriteCurveFile(MeasuredPath, Req.Data, 'theta_deg', 'I');

  if Req.PointWeight then
    MovAvgCurve := MovAvg(Req.Data, Req.Fit.MovAvgWindow)
  else
    SetLength(MovAvgCurve, 0);

  { What the model the client started from was worth, so that the fit can be
    read as an improvement rather than as a bare number. The curve is kept as
    well: the report says of the start model everything it says of the fit, and
    computing it twice would be a second pass over every point.
    BuildLayeredModel makes the same expanded model TLFPSO_BASE.FillModel does,
    and ScanOnData hands it to a TCalc, which frees it. }
  StartCalcCurve := ScanOnData(Req, BuildLayeredModel(Req.Structure, Req.StartProfiles),
                               MovAvgCurve, Chi2Start, Chi2StartPlain,
                               ScaleLogStart, ClampedStart);

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
  else if Req.Irregular then
  begin
    if Req.StartProfiles then
      L := TLFPSO_IrregularFromTable.Create
    else
      L := TLFPSO_Irregular.Create;
    EngineName := 'TLFPSO_Irregular';
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
      L.UseGPU     := Req.Device <> 'cpu';
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

      { The irregular engine hands back its own flattened structure, one stack
        of every physical layer; the result reports the start model's shape. }
      if Req.Irregular then
        Fitted := UnflattenIrregular(Req.Structure, L.Structure)
      else
        Fitted := L.Structure;
      Poly := L.Polynomes;
      Chi2 := L.BestChiSquare;
      Model := L.Result;                // a fresh model; ScanOnData frees it
      IterationsRun := Runner.LastIteration;
      DeviceUsed := L.DeviceUsed;
      GpuError := L.GpuError;
    finally
      Runner.Free;
    end;

    { Model is ours until ScanOnData hands it to a TCalc. }
    try
      { Read off the expanded model while it is still ours: a gradient or an
        irregular fit puts the per-period values nowhere else. A plain periodic
        fit repeats one thickness per period and has no profile to report. }
      if Req.Profile or Req.Irregular then
        Profiles := CollectLayerProfiles(Model);
    except
      Model.Free;
      raise;
    end;

    { The curve on the measured angles for the model the fit ended on. It is
      recomputed rather than taken from BestCurve so that the chi-squared beside
      it comes from the structure the result reports. ScanOnData takes the
      model, raise or not, so Model must not be touched afterwards. }
    CalcCurve := ScanOnData(Req, Model, MovAvgCurve, Chi2Recalc, Chi2Plain,
                            ScaleLogFit, ClampedFit);
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
  if Req.Irregular then
    SetFittedTables(Fitted, Profiles);
  if Req.StartProfiles then
    StartProfiles := TableProfiles(StartFS);

  Residual := ResidualCurve(Req.Data, CalcCurve, ScaleLogFit);
  WriteCurveFile(CalcPath, CalcCurve, 'theta_deg', 'R');
  { The residual is at the solved scale while measured.dat and calc.dat are at
    the anchored one, so its column says which factor was added: a reader who
    recomputes it from the two siblings must add log10(scale_ratio). }
  if ScaleLogFit = 0 then
    WriteCurveFile(ResidualPath, Residual, 'theta_deg', 'log10_I_minus_log10_R')
  else
    WriteCurveFile(ResidualPath, Residual, 'theta_deg',
      Format('log10_I_plus_log10_scale_ratio_minus_log10_R(scale_ratio=%.8g)',
             [Power(10, ScaleLogFit)], FitFmt));
  WriteFitProject(XRCXPath, Req, Fitted, Poly, CalcCurve, Job.Id);

  Res := TJSONObject.Create;
  try
    Res.AddPair('job_id', Job.Id);
    Res.AddPair('seed', TJSONNumber.Create(Job.Seed));
    Res.AddPair('chi2', JSONArgs.Num(Chi2));
    Res.AddPair('chi2_recalc', JSONArgs.Num(Chi2Recalc));
    Res.AddPair('chi2_start', JSONArgs.Num(Chi2Start));
    Res.AddPair('chi2_plain', JSONArgs.Num(Chi2Plain));
    Res.AddPair('chi2_start_plain', JSONArgs.Num(Chi2StartPlain));
    Res.AddPair('chi2_definition', FIT_CHI2_DEFINITION);
    Res.AddPair('chi2_plain_definition', FIT_CHI2_PLAIN_DEFINITION);
    Res.AddPair('chi2_settings', Chi2SettingsJSON(Req));
    Res.AddPair('optimizer_used', OptimizerUsedJSON(Req));
    Res.AddPair('iterations_run', TJSONNumber.Create(IterationsRun));
    Res.AddPair('elapsed_s', JSONArgs.Num(Job.ElapsedMs / 1000));
    Res.AddPair('lambda_used', JSONArgs.Num(Req.Lambda));
    Res.AddPair('theta_range',
      JSONArgs.NumArr(TArray<Double>.Create(Req.ThetaMin, Req.ThetaMax)));
    Res.AddPair('resolution_deg', JSONArgs.Num(Req.Resolution));
    Res.AddPair('polarization', Req.PolarizationName);
    Res.AddPair('mode', Req.Mode);
    Res.AddPair('engine', EngineName);
    if Req.Irregular then
    begin
      Res.AddPair('start_profiles', TJSONBool.Create(Req.StartProfiles));
      Res.AddPair('free_values', TJSONNumber.Create(FreeValueCount(Req)));
    end;
    Res.AddPair('device_used', DeviceUsed);
    if GpuError <> '' then
      Res.AddPair('gpu_error', GpuError);
    Res.AddPair('start_structure',
      FittedStructureJSON(StartFS, Req.Info, StartProfiles, True));
    Res.AddPair('fitted_structure',
      FittedStructureJSON(Fitted, Req.Info, Profiles, Req.Irregular));
    Res.AddPair('bounds_used', BoundsUsedJSON(Req.FreeParams, Req.PeriodRefs, Req.Info));
    Res.AddPair('out_of_bounds', OutOfBoundsJSON(Req, Fitted, Profiles));
    Res.AddPair('period_mode', PeriodModeJSON(Req, Fitted, StartProfiles, Profiles));
    Res.AddPair('profiles', ProfilesJSON(Poly, Req.Info, Req.FreeParams));

    JFiles := TJSONObject.Create;
    Res.AddPair('files', JFiles);
    JFiles.AddPair('xrcx', WorkDir.RelativePath(XRCXPath));
    JFiles.AddPair('measured', WorkDir.RelativePath(MeasuredPath));
    JFiles.AddPair('calculated', WorkDir.RelativePath(CalcPath));
    JFiles.AddPair('residual', WorkDir.RelativePath(ResidualPath));
    JFiles.AddPair('report', WorkDir.RelativePath(ReportPath));

    Res.AddPair('measured', CurveOrNull(Req.Data, Req.InlineMax));
    Res.AddPair('calculated', CurveOrNull(CalcCurve, Req.InlineMax));
    Res.AddPair('residual', CurveOrNull(Residual, Req.InlineMax));

    Res.AddPair('scale', JSONArgs.Num(Req.Scale));
    Res.AddPair('scale_mode', Req.ScaleMode);
    { The solved scale, on every result, so that a number from before and one
      from after this feature can never be compared without noticing. }
    Res.AddPair('scale_solve', TJSONBool.Create(Req.Fit.SolveScale));
    if Req.Fit.SolveScale then
      Res.AddPair('chi2_scale', 'solved')
    else
      Res.AddPair('chi2_scale', 'anchored');
    Res.AddPair('scale_solve_window', JSONArgs.Num(Req.ScaleSolveWindow));
    Res.AddPair('scale_ratio', JSONArgs.Num(Power(10, ScaleLogFit)));
    Res.AddPair('scale_solved', JSONArgs.Num(Req.Scale * Power(10, ScaleLogFit)));
    Res.AddPair('scale_clamped', TJSONBool.Create(ClampedFit));
    Res.AddPair('scale_start_ratio', JSONArgs.Num(Power(10, ScaleLogStart)));
    Res.AddPair('chi2_scale_definition', FIT_CHI2_SOLVED_DEFINITION);
    if Req.ScaleMode = 'auto' then
    begin
      Res.AddPair('scale_theta', JSONArgs.Num(Req.ScaleTheta));
      Res.AddPair('scale_counts', JSONArgs.Num(Req.ScaleCounts));
      Res.AddPair('auto_theta_max', JSONArgs.Num(Req.AutoThetaMax));
    end
    else
    begin
      Res.AddPair('scale_theta', TJSONNull.Create);
      Res.AddPair('scale_counts', TJSONNull.Create);
    end;
    Res.AddPair('paired', PairedJSON(Req.PairedParams, Req.Info));
    JSmooth := TJSONObject.Create;
    Res.AddPair('smooth', JSmooth);
    JSmooth.AddPair('passes', TJSONNumber.Create(Req.SmoothPasses));
    JSmooth.AddPair('window', TJSONNumber.Create(FIT_SMOOTH_WINDOW));
    Res.AddPair('background', JSONArgs.Num(0.0));
    Res.AddPair('note', FIT_NO_SCALE_NOTE);

    { The report is the same numbers for the fit and for the model the client
      started from, so that what the fit changed can be read off one object.
      Each side counts its orders on its own period: the start model's orders
      are where the start model puts them. Each side also reads the measured
      curve at its own solved scale (scale_ratio, scale_start_ratio), the one
      its chi2 was taken at: until 3.9.4 both read it at the anchored scale,
      and every ratio in the report was off from chi2 and the chart by the
      scale ratio. }
    RepInp := Default(TFitReportInput);
    RepInp.Measured := ScaledCurve(Req.Data, ScaleLogFit);
    RepInp.Calculated := CalcCurve;
    RepInp.Lambda := Req.Lambda;
    RepInp.Period := ReportPeriod(Fitted, Req.Info);
    { An irregular fit has a period per repetition; the orders sit at the
      mean one. }
    if Req.Irregular and (Req.Info.PeriodicStackIndex >= 0) then
      RepInp.Period := MeanOf(PeriodsOf(Profiles, Req.Info.PeriodicStackIndex));
    RepInp.ThetaC := CriticalAngleDeg(Fitted, Req.Lambda);
    Report := FitReportJSON(RepInp);
    Res.AddPair('report', Report);        // Res owns it from here on
    Report.AddPair('chi2', JSONArgs.Num(Chi2));
    Report.AddPair('chi2_start', JSONArgs.Num(Chi2Start));
    Report.AddPair('chi2_plain', JSONArgs.Num(Chi2Plain));
    Report.AddPair('chi2_start_plain', JSONArgs.Num(Chi2StartPlain));
    { The scale mode beside every chi2 the file holds, so that report.json
      read on its own, years later, still says what its numbers are. }
    Report.AddPair('scale_solve', TJSONBool.Create(Req.Fit.SolveScale));
    Report.AddPair('chi2_scale', Res.GetValue<string>('chi2_scale'));
    Report.AddPair('scale_solve_window', JSONArgs.Num(Req.ScaleSolveWindow));
    Report.AddPair('scale_ratio', JSONArgs.Num(Power(10, ScaleLogFit)));
    Report.AddPair('scale_solved', JSONArgs.Num(Req.Scale * Power(10, ScaleLogFit)));
    Report.AddPair('scale_clamped', TJSONBool.Create(ClampedFit));
    Report.AddPair('scale_start_ratio', JSONArgs.Num(Power(10, ScaleLogStart)));
    Report.AddPair('near_bounds', NearBoundsJSON(Req, Fitted, Profiles));

    RepInp.Measured := ScaledCurve(Req.Data, ScaleLogStart);
    RepInp.Calculated := StartCalcCurve;
    RepInp.Period := ReportPeriod(StartFS, Req.Info);
    if Req.StartProfiles and (Req.Info.PeriodicStackIndex >= 0) then
      RepInp.Period := MeanOf(PeriodsOf(StartProfiles, Req.Info.PeriodicStackIndex));
    RepInp.ThetaC := CriticalAngleDeg(StartFS, Req.Lambda);
    Report.AddPair('start', FitReportJSON(RepInp));

    WriteJSONFile(ReportPath, Report);

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
