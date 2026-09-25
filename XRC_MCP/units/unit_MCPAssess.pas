(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_MCPAssess;

(* Is this measured curve worth fitting?

   The fitting procedure's first section turned around and pointed at the
   measurement instead of at the model: before anyone fits, say whether the
   scan can carry a fit at all. The decisive checks are count RATES, and the
   counting time per step exists only in the raw .xrdml, which is why the
   assessment wants the parsed scan and not the two columns a chart holds. A
   two-column curve still works: every check that needs a fact the file does
   not carry answers "unknown".

   This unit is the assessment itself, shared by the MCP tool assess_xrr
   (unit_ToolsFiles) and the GUI's Data - Assess XRR quality (frm_XRRAssess):
   a TAssessInput in, one JSON object out, nothing read from disk and nothing
   written anywhere.

   Eight checks, each {value, threshold, verdict, why} plus the numbers it was
   made from, and a text block ready to paste into the specimen's record:

     counting                 peak count rate against the detector's linear limit
     plateau_vs_first_order   I(first Bragg order) / I(low-angle maximum)
     total_reflection         did the scan start below the critical angle
     orders_visible           orders above background against the design
     range_below_background   the part of the scan that bought nothing
     sampling                 points per Kiessig fringe (or per resolution width
                              when the fringes are finer than it) and per order
     footprint                the knee where the beam overfills the specimen
     zeros                    non-positive counts and where they start

   Two rules the whole unit keeps:

   - A verdict is "unknown" whenever the input it needs is missing: no
     detector limit, no design, no raw file. No threshold is ever invented in
     code to fill the gap. The only numbers this unit brings of its own are
     the ones physics or sampling theory fixes: a reflectivity above the
     plateau is impossible, fewer than two points per fringe cannot
     resolve the fringe, and a fringe finer than the resolution has lost
     all but 3 % of its contrast before any step samples it.
   - The engine returns numbers and verdicts. It never writes anything, not
     to the inbox, not to the specimen's record; the client formats and files
     the text block.

   Where a design is given, the checks that need a period, a total thickness
   or a critical angle read them from it, and the design's reflectivity on
   the measured range - convolved with the same resolution a fit would use,
   so that the two tools describe the same design - says what the measurement
   could have shown: an order the model puts below the background was never
   going to be seen, and a first order the model puts at half the plateau
   cannot measure 96 % of it. Without a design the same checks report the
   number and say "unknown".

   The counting check judges the rate the DETECTOR saw. A file with beam
   attenuation factors carries corrected counts on the plateau, up to a
   hundred times what the detector counted; unit_xrdml keeps both maxima and
   the check reads the raw one, reporting the corrected one beside it.

   Angles: every angle here is theta in degrees, the engine's own axis; the
   scan's own axis is reported beside it as two_theta_deg wherever a person
   would look the number up in the file. The curve is sorted ascending in
   theta before anything reads it, whichever way the file was scanned. *)

interface

uses
  System.JSON,
  unit_Types, unit_xrdml, unit_MCPStructure;

type
  /// <summary>Everything one assessment reads. Curve is theta in degrees,
  /// non-positive intensities already replaced, normalised to 1 at the
  /// maximum when it came from an .xrdml; it need not be sorted. The raw
  /// facts are known (HasRaw) for an .xrdml only. Zero means "not given"
  /// for every optional number.</summary>
  TAssessInput = record
    Curve: unit_Types.TDataArray;
    Lambda: Double;               // Angstrom; 0 when unknown
    LambdaSource: string;
    TwoThetaScan: Boolean;        // the file's axis was 2theta

    HasRaw: Boolean;
    IntensityUnit: string;        // 'counts', 'cps', '' ...
    CountingTime: Double;         // s per point; 0 when per-point or absent
    PeakRate: Double;             // counts per second at the curve's maximum (attenuation factors in)
    PeakCounts: Double;           // the number in the file there, factors in
    PeakIndex: Integer;           // index into Curve of that maximum; -1 when unknown
    RawPeakRate: Double;          // counts per second the detector saw at most (factors out)
    RawPeakCounts: Double;        // the number in the file at that point
    RawPeakIndex: Integer;        // index into Curve of that point; -1 when unknown
    AttenuationApplied: Boolean;
    Detector: string;
    ReadOutPeriod: Double;
    ZerosFloored: Integer;
    FirstNonPositive: Integer;    // index into Curve of the lowest-angle zero; -1 when none

    HasStructure: Boolean;
    Structure: TFitStructure;
    Info: TStructureInfo;         // may be Default: the assessment finds the periodic stack itself

    Resolution: Double;           // theta FWHM (deg) the design is convolved with; 0 = none
    DetectorMaxCps: Double;       // the detector's linear limit; 0 = not given
    SampleLengthMm: Double;       // 0 = not given
    BeamWidthMm: Double;          // 0 = not given
    VisibleFactor: Double;        // an order is visible this far above background
    MinPointsPerFringe: Double;   // below this the sampling check warns
  end;

const
  /// Below this many points per Kiessig fringe the check warns; it is the
  /// number the fitting procedure names, and the caller may change it.
  ASSESS_MIN_POINTS_PER_FRINGE = 3;
  /// Below two points per fringe the fringe cannot be resolved at all
  /// (sampling theorem); the check fails whatever the caller's number.
  ASSESS_NYQUIST_POINTS_PER_FRINGE = 2;

/// <summary>An input with the defaults filled in: VisibleFactor and
/// MinPointsPerFringe set, every index -1, everything else empty or zero.</summary>
function DefaultAssessInput: TAssessInput;

/// <summary>The input an .xrdml scan gives: the curve brought to theta (a
/// 2Theta scan halved, an Omega scan as it is), the wavelength the file
/// implies, and every raw fact. The design and the instrument numbers are
/// left for the caller.</summary>
function AssessInputFromScan(const Scan: TXRDMLScan): TAssessInput;

/// <summary>The assessment of one curve. Caller frees. Raises
/// EMCPError('invalid_argument') for a curve of fewer than three points, or
/// a design without a wavelength to place it at.</summary>
function AssessJSON(const Inp: TAssessInput): TJSONObject;

/// <summary>AssessJSON into an object the caller has already started (the
/// measurement's identity in front of the checks).</summary>
procedure AssessInto(const Inp: TAssessInput; Res: TJSONObject);

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  System.Generics.Defaults,
  unit_MCPErrors, unit_MCPCalc, unit_MCPFitReport;

const
  VERDICT_UNKNOWN = 'unknown';
  VERDICT_PASS    = 'pass';
  VERDICT_WARN    = 'warn';
  VERDICT_FAIL    = 'fail';

{ ------------------------------------------------------------- helpers -- }

function StrOrNull(const S: string): TJSONValue;
begin
  if S <> '' then
    Result := TJSONString.Create(S)
  else
    Result := TJSONNull.Create;
end;

/// One check in the shape every check has: value and threshold (null when
/// there is none), the verdict and one sentence saying why. The caller adds
/// the numbers the verdict was made from after these four.
function CheckJSON(Value, Threshold: TJSONValue; const Verdict, Why: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('value', Value);
  Result.AddPair('threshold', Threshold);
  Result.AddPair('verdict', Verdict);
  Result.AddPair('why', Why);
end;

function Rank(const Verdict: string): Integer;
begin
  if Verdict = VERDICT_FAIL then Exit(3);
  if Verdict = VERDICT_WARN then Exit(2);
  if Verdict = VERDICT_PASS then Exit(1);
  Result := 0;
end;

function Fmt(const S: string; const Args: array of const): string;
begin
  Result := Format(S, Args, TFormatSettings.Invariant);
end;

/// theta_deg and two_theta_deg of one angle, added to Obj under Prefix.
procedure AddAngle(Obj: TJSONObject; const Prefix: string; Theta: Double);
begin
  Obj.AddPair(Prefix + 'theta_deg', JSONArgs.Num(Theta));
  Obj.AddPair(Prefix + 'two_theta_deg', JSONArgs.Num(2 * Theta));
end;

/// The same two keys as null, where there is no angle to give.
procedure AddNoAngle(Obj: TJSONObject; const Prefix: string);
begin
  Obj.AddPair(Prefix + 'theta_deg', TJSONNull.Create);
  Obj.AddPair(Prefix + 'two_theta_deg', TJSONNull.Create);
end;

{ --------------------------------------------------------- curve reading -- }

type
  TExtremum = record
    Idx: Integer;
    IsMax: Boolean;
  end;

/// The turning points of C from StartIdx on, confirmed with a hysteresis: a
/// maximum counts once the curve has fallen back by REPORT_FRINGE_HYSTERESIS
/// from it, a minimum once it has risen by the same factor. On a measured
/// curve the extrema without that rule are its noise. The walk starts at
/// StartIdx rising (StartRising, from the first point: the plateau is the
/// first maximum it confirms, and a curve that only falls confirms its first
/// point at once) or falling (from a maximum the caller has found); a final
/// turn that is never confirmed is not reported.
function HysteresisExtrema(const C: unit_Types.TDataArray; StartIdx: Integer;
  StartRising: Boolean = False): TArray<TExtremum>;
var
  i, Ext, Count: Integer;
  Rising: Boolean;

  procedure Add(Idx: Integer; IsMax: Boolean);
  begin
    SetLength(Result, Count + 1);
    Result[Count].Idx := Idx;
    Result[Count].IsMax := IsMax;
    Inc(Count);
  end;

begin
  Result := nil;
  Count := 0;
  if (StartIdx < 0) or (StartIdx > High(C)) then
    Exit;
  Ext := StartIdx;
  Rising := StartRising;
  for i := StartIdx + 1 to High(C) do
  begin
    if Rising then
    begin
      if C[i].r > C[Ext].r then
        Ext := i
      else if (C[i].r > 0) and (C[Ext].r > REPORT_FRINGE_HYSTERESIS * C[i].r) then
      begin
        Add(Ext, True);
        Ext := i;
        Rising := False;
      end;
    end
    else
    begin
      if C[i].r < C[Ext].r then
        Ext := i
      else if (C[Ext].r > 0) and (C[i].r > REPORT_FRINGE_HYSTERESIS * C[Ext].r) then
      begin
        Add(Ext, False);
        Ext := i;
        Rising := True;
      end;
    end;
  end;
end;

function IndexOfMax(const C: unit_Types.TDataArray): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(C) do
    if (Result < 0) or (C[i].r > C[Result].r) then
      Result := i;
end;

/// The median spacing of the grid, in degrees of theta.
function MedianStep(const C: unit_Types.TDataArray): Double;
var
  D: TArray<Double>;
  i: Integer;
begin
  if Length(C) < 2 then
    Exit(0);
  SetLength(D, Length(C) - 1);
  for i := 0 to High(D) do
    D[i] := Abs(C[i + 1].t - C[i].t);
  Result := MedianOf(D);
end;

/// The curve ascending in theta, and the three indices that point into it
/// carried along. A scan written high-to-low, or a text file in any order,
/// reads the same as one written low-to-high.
procedure SortAscending(var Inp: TAssessInput);
var
  C, Sorted: unit_Types.TDataArray;
  Idx, Inverse: TArray<Integer>;
  i, n: Integer;
  InOrder: Boolean;
begin
  C := Inp.Curve;
  n := Length(C);
  InOrder := True;
  for i := 1 to n - 1 do
    if C[i].t < C[i - 1].t then
    begin
      InOrder := False;
      Break;
    end;
  if InOrder then
    Exit;

  SetLength(Idx, n);
  for i := 0 to n - 1 do
    Idx[i] := i;
  TArray.Sort<Integer>(Idx, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := CompareValue(C[A].t, C[B].t);
      if Result = 0 then
        Result := CompareValue(A, B);      // stable: equal angles keep their file order
    end));

  SetLength(Sorted, n);
  SetLength(Inverse, n);
  for i := 0 to n - 1 do
  begin
    Sorted[i] := C[Idx[i]];
    Inverse[Idx[i]] := i;
  end;
  Inp.Curve := Sorted;
  if Inp.PeakIndex >= 0 then
    Inp.PeakIndex := Inverse[Inp.PeakIndex];
  if Inp.RawPeakIndex >= 0 then
    Inp.RawPeakIndex := Inverse[Inp.RawPeakIndex];
  if Inp.FirstNonPositive >= 0 then
    Inp.FirstNonPositive := Inverse[Inp.FirstNonPositive];
end;

{ --------------------------------------------------------------- design -- }

/// The first stack with more than one period: the rule unit_MCPStructure
/// applies, repeated here so that a structure the GUI built (no
/// TStructureInfo) reads the same. -1 when there is none.
function PeriodicStackIndex(const S: TFitStructure): Integer;
var
  j: Integer;
begin
  for j := 0 to High(S.Stacks) do
    if S.Stacks[j].N > 1 then
      Exit(j);
  Result := -1;
end;

/// The period of the design's repeating stack, 0 when it has none.
function DesignPeriod(const S: TFitStructure): Double;
var
  j, k: Integer;
begin
  Result := 0;
  j := PeriodicStackIndex(S);
  if j < 0 then
    Exit;
  for k := 0 to High(S.Stacks[j].Layers) do
    Result := Result + S.Stacks[j].Layers[k].P[1].V;
end;

/// Every layer of every stack, N times over: the film's whole thickness, which
/// sets the Kiessig fringe spacing.
function DesignTotalThickness(const S: TFitStructure): Double;
var
  j, k: Integer;
  Period: Double;
begin
  Result := 0;
  for j := 0 to High(S.Stacks) do
  begin
    Period := 0;
    for k := 0 to High(S.Stacks[j].Layers) do
      Period := Period + S.Stacks[j].Layers[k].P[1].V;
    Result := Result + Max(1, S.Stacks[j].N) * Period;
  end;
end;

/// The design's reflectivity on the measured range, on a grid of as many
/// points as the measurement (capped at what one calculation may take),
/// convolved with the caller's resolution. The floor R is clamped to sits
/// under the measured background, so that the clamp itself can never pass
/// for an order the design predicts.
function DesignCurve(const Inp: TAssessInput; Background: Double): unit_Types.TDataArray;
var
  Req: TCalcRequest;
  Used: TFitStructure;
begin
  Req := Default(TCalcRequest);
  Req.Structure := Inp.Structure;
  Req.Info := Inp.Info;
  Req.Lambda := Inp.Lambda;
  Req.ThetaMin := Inp.Curve[0].t;
  Req.ThetaMax := Inp.Curve[High(Inp.Curve)].t;
  Req.DeltaTheta := Max(0, Inp.Resolution);
  Req.Points := Max(2, Min(Length(Inp.Curve), MAX_CALC_POINTS));
  Req.Polarization := cmSP;
  Req.RMin := Max(1E-12, Min(1E-7, Background / 10));
  Result := RunCalc(Req, Used);
end;

{ ----------------------------------------------------------- the checks -- }

type
  /// What the checks share once the curve has been read: the low-angle
  /// maximum, the first order, the background and the design's numbers.
  TAssessContext = record
    Inp: TAssessInput;
    Model: unit_Types.TDataArray;   // empty without a design
    Period, TotalThickness, ThetaC: Double;
    Background: Double;             // ReportBackground of the curve
    Step: Double;                   // median grid spacing, deg theta
    ILow: Integer;                  // the low-angle (plateau) maximum
    IFirst: Integer;                // the first Bragg order; -1 when not found
    FirstOrderHow: string;          // how IFirst was chosen
    Order1Lo, Order1Hi, Order1Theta: Double;
    HasOrder1Window: Boolean;
    Extrema: TArray<TExtremum>;     // the turning points after the plateau, walked once
  end;

procedure ReadCurve(var Ctx: TAssessContext);
var
  Ext: TArray<TExtremum>;
  n, FirstMin, Best: Integer;
begin
  with Ctx do
  begin
    Background := ReportBackground(Inp.Curve);
    Step := MedianStep(Inp.Curve);
    HasOrder1Window := False;
    IFirst := -1;
    Period := 0;
    TotalThickness := 0;
    ThetaC := 0;
    SetLength(Model, 0);

    if Inp.HasStructure then
    begin
      Period := DesignPeriod(Inp.Structure);
      TotalThickness := DesignTotalThickness(Inp.Structure);
      ThetaC := CriticalAngleDeg(Inp.Structure, Inp.Lambda);
      HasOrder1Window := (Period > 0) and
        BraggSearchWindow(1, Inp.Lambda, Period, ThetaC, Order1Lo, Order1Hi, Order1Theta);
      { the model is only ever read at Bragg orders; a bare substrate has
        none and its critical angle is all the design contributes }
      if TotalThickness > 0 then
        Model := DesignCurve(Inp, Background);
    end;

    { The plateau maximum: below the first order's window when the design
      places one; otherwise the first maximum the curve confirms walking up
      from its first point. Not the global maximum: on a specimen whose
      plateau is depressed the global maximum is the first Bragg order, and
      nothing in the curve says so except its order in angle. }
    ILow := -1;
    if HasOrder1Window then
      ILow := MaxIndexInRange(Inp.Curve, Inp.Curve[0].t, Order1Lo);
    if ILow < 0 then
    begin
      Ext := HysteresisExtrema(Inp.Curve, 0, True);
      for n := 0 to High(Ext) do
        if Ext[n].IsMax then
        begin
          ILow := Ext[n].Idx;
          Break;
        end;
    end;
    if ILow < 0 then
      ILow := IndexOfMax(Inp.Curve);

    { walked once from the plateau; the orders check reads it again }
    Extrema := HysteresisExtrema(Inp.Curve, ILow);

    { The first order: the largest point inside the design's window, or, with
      no design, the highest maximum after the plateau has fallen to its
      first minimum. }
    if HasOrder1Window then
    begin
      IFirst := MaxIndexInRange(Inp.Curve, Order1Lo, Order1Hi);
      FirstOrderHow := Fmt('largest point in the design''s order-1 window %.4f to %.4f deg theta',
                           [Order1Lo, Order1Hi]);
      if IFirst < 0 then
        FirstOrderHow := 'the design''s order-1 window holds no measured point';
    end
    else
    begin
      FirstMin := -1;
      Best := -1;
      for n := 0 to High(Extrema) do
      begin
        if (FirstMin < 0) and not Extrema[n].IsMax then
          FirstMin := n
        else if (FirstMin >= 0) and Extrema[n].IsMax then
          if (Best < 0) or (Inp.Curve[Extrema[n].Idx].r > Inp.Curve[Best].r) then
            Best := Extrema[n].Idx;
      end;
      IFirst := Best;
      if IFirst >= 0 then
        FirstOrderHow := 'highest maximum after the plateau''s first minimum (no design given: ' +
                         'on a single film or a bare substrate this is a Kiessig fringe or noise, ' +
                         'not a Bragg order)'
      else
        FirstOrderHow := 'no maximum found after the plateau''s first minimum (no design given)';
    end;
  end;
end;

function CountingCheck(const Ctx: TAssessContext): TJSONObject;
var
  Verdict, Why, Att: string;
begin
  with Ctx.Inp do
  begin
    if not HasRaw then
    begin
      Result := CheckJSON(TJSONNull.Create, NumOrNull(DetectorMaxCps, DetectorMaxCps > 0),
        VERDICT_UNKNOWN,
        'a two-column curve carries no counting time, so no count rate can be formed');
      Exit;
    end;
    if AttenuationApplied then
      Att := Fmt(' (attenuation factors in the file: the corrected curve peaks at %.4g counts/s)',
                 [PeakRate])
    else
      Att := '';
    if DetectorMaxCps <= 0 then
    begin
      Verdict := VERDICT_UNKNOWN;
      Why := Fmt('the detector saw at most %.4g counts/s%s; no detector_max_cps given to judge it against',
                 [RawPeakRate, Att]);
    end
    else if RawPeakRate > DetectorMaxCps then
    begin
      Verdict := VERDICT_FAIL;
      Why := Fmt('the detector saw %.4g counts/s%s, above its linear limit %.4g counts/s: ' +
                 'the plateau and any feature at that rate are clipped', [RawPeakRate, Att, DetectorMaxCps]);
    end
    else
    begin
      Verdict := VERDICT_PASS;
      Why := Fmt('the detector saw at most %.4g counts/s%s, within its linear limit %.4g counts/s',
                 [RawPeakRate, Att, DetectorMaxCps]);
    end;
    Result := CheckJSON(JSONArgs.Num(RawPeakRate), NumOrNull(DetectorMaxCps, DetectorMaxCps > 0),
                        Verdict, Why);
    Result.AddPair('unit', StrOrNull(IntensityUnit));
    Result.AddPair('counting_time_s', NumOrNull(CountingTime, CountingTime > 0));
    { the rate the detector saw, at the point where it saw it }
    Result.AddPair('peak_counts', JSONArgs.Num(RawPeakCounts));
    Result.AddPair('peak_rate_cps', JSONArgs.Num(RawPeakRate));
    if RawPeakIndex >= 0 then
      AddAngle(Result, 'peak_', Curve[RawPeakIndex].t)
    else
      AddNoAngle(Result, 'peak_');
    Result.AddPair('attenuation_factors', TJSONBool.Create(AttenuationApplied));
    { the curve's maximum as a fit sees it; the same point when no factors }
    Result.AddPair('corrected_peak_counts', JSONArgs.Num(PeakCounts));
    Result.AddPair('corrected_peak_rate_cps', JSONArgs.Num(PeakRate));
    if PeakIndex >= 0 then
      AddAngle(Result, 'corrected_peak_', Curve[PeakIndex].t)
    else
      AddNoAngle(Result, 'corrected_peak_');
    Result.AddPair('detector', StrOrNull(Detector));
    Result.AddPair('readout_period_s', NumOrNull(ReadOutPeriod, ReadOutPeriod > 0));
  end;
end;

function PlateauVsFirstOrderCheck(const Ctx: TAssessContext): TJSONObject;
var
  Ratio, ModelRatio: Double;
  IMLow, IMFirst: Integer;
  HaveModel: Boolean;
  Verdict, Why: string;
begin
  if (Ctx.IFirst < 0) or (Ctx.ILow < 0) or (Ctx.Inp.Curve[Ctx.ILow].r <= 0) then
  begin
    Result := CheckJSON(TJSONNull.Create, TJSONNull.Create, VERDICT_UNKNOWN,
      'no first order to compare: ' + Ctx.FirstOrderHow);
    Result.AddPair('first_order', TJSONNull.Create);
    Exit;
  end;

  Ratio := Ctx.Inp.Curve[Ctx.IFirst].r / Ctx.Inp.Curve[Ctx.ILow].r;

  { What the design says the ratio should be: its own first order over its
    own plateau, read in the same windows. }
  HaveModel := False;
  ModelRatio := 0;
  if (Length(Ctx.Model) > 0) and Ctx.HasOrder1Window then
  begin
    IMLow := MaxIndexInRange(Ctx.Model, Ctx.Model[0].t, Ctx.Order1Lo);
    IMFirst := MaxIndexInRange(Ctx.Model, Ctx.Order1Lo, Ctx.Order1Hi);
    if (IMLow >= 0) and (IMFirst >= 0) and (Ctx.Model[IMLow].r > 0) then
    begin
      ModelRatio := Ctx.Model[IMFirst].r / Ctx.Model[IMLow].r;
      HaveModel := True;
    end;
  end;

  if Ratio > 1 then
  begin
    Verdict := VERDICT_FAIL;
    Why := Fmt('the first order (%.4g) stands above the low-angle maximum (%.4g): a reflectivity ' +
               'above the total-reflection plateau is impossible, so one of the two is not what it ' +
               'seems - a depressed plateau (alignment, footprint) or a clipped detector',
               [Ctx.Inp.Curve[Ctx.IFirst].r, Ctx.Inp.Curve[Ctx.ILow].r]);
  end
  else if HaveModel then
  begin
    if Ratio > ModelRatio then
    begin
      Verdict := VERDICT_WARN;
      Why := Fmt('measured ratio %.3f exceeds the %.3f the design can give: the plateau is ' +
                 'depressed or the two features are against the same ceiling', [Ratio, ModelRatio]);
    end
    else
    begin
      Verdict := VERDICT_PASS;
      Why := Fmt('measured ratio %.3f is within the %.3f the design gives', [Ratio, ModelRatio]);
    end;
  end
  else
  begin
    Verdict := VERDICT_UNKNOWN;
    Why := Fmt('measured ratio %.3f; no design to say what the first order should be against ' +
               'the plateau', [Ratio]);
  end;

  Result := CheckJSON(JSONArgs.Num(Ratio), NumOrNull(ModelRatio, HaveModel), Verdict, Why);
  Result.AddPair('low_angle_max', JSONArgs.Num(Ctx.Inp.Curve[Ctx.ILow].r));
  AddAngle(Result, 'low_angle_max_', Ctx.Inp.Curve[Ctx.ILow].t);
  Result.AddPair('first_order', JSONArgs.Num(Ctx.Inp.Curve[Ctx.IFirst].r));
  AddAngle(Result, 'first_order_', Ctx.Inp.Curve[Ctx.IFirst].t);
  Result.AddPair('first_order_found_by', Ctx.FirstOrderHow);
  Result.AddPair('model_ratio', NumOrNull(ModelRatio, HaveModel));
end;

function TotalReflectionCheck(const Ctx: TAssessContext): TJSONObject;
var
  Verdict, Why: string;
  StartT: Double;
begin
  StartT := Ctx.Inp.Curve[0].t;
  if Ctx.ILow = 0 then
  begin
    Verdict := VERDICT_FAIL;
    Why := Fmt('the curve''s maximum is its first point (%.4f deg theta): the scan started ' +
               'already on the way down and never saw the plateau', [StartT]);
  end
  else if Ctx.Inp.HasStructure and (Ctx.ThetaC > 0) then
  begin
    if StartT < Ctx.ThetaC then
    begin
      Verdict := VERDICT_PASS;
      Why := Fmt('the scan starts at %.4f deg theta, below the design''s critical angle %.4f deg, ' +
                 'and rises to its maximum at %.4f deg',
                 [StartT, Ctx.ThetaC, Ctx.Inp.Curve[Ctx.ILow].t]);
    end
    else
    begin
      Verdict := VERDICT_FAIL;
      Why := Fmt('the scan starts at %.4f deg theta, at or above the design''s critical angle ' +
                 '%.4f deg: the total-reflection plateau is not in the data', [StartT, Ctx.ThetaC]);
    end;
  end
  else
  begin
    Verdict := VERDICT_UNKNOWN;
    Why := Fmt('the scan starts at %.4f deg theta and reaches its maximum at %.4f deg; no design ' +
               'to place the critical angle', [StartT, Ctx.Inp.Curve[Ctx.ILow].t]);
  end;

  Result := CheckJSON(JSONArgs.Num(StartT), NumOrNull(Ctx.ThetaC, Ctx.Inp.HasStructure and (Ctx.ThetaC > 0)),
                      Verdict, Why);
  AddAngle(Result, 'scan_start_', StartT);
  AddAngle(Result, 'max_', Ctx.Inp.Curve[Ctx.ILow].t);
  Result.AddPair('points_before_max', TJSONNumber.Create(Ctx.ILow));
  Result.AddPair('i_start_over_i_max', RatioOrNull(Ctx.Inp.Curve[0].r, Ctx.Inp.Curve[Ctx.ILow].r));
end;

{ The background is the level the floored zeros were raised to when the file
  has zero counts and the background is about one count: "above the
  background" then counts from a single count, not from a measured noise
  floor. '' otherwise. }
function FlooredBackgroundNote(const Ctx: TAssessContext): string;
var
  LevelCounts: Double;
begin
  Result := '';
  if not (Ctx.Inp.HasRaw and (Ctx.Inp.PeakCounts > 0) and (Ctx.Inp.ZerosFloored > 0)) then
    Exit;
  LevelCounts := Ctx.Background * Ctx.Inp.PeakCounts;
  if LevelCounts < 1.5 then
    Result := Fmt('. The background is the floor the %d zero counts were raised to ' +
                  '(%.3g counts), not a measured noise level, so an order is visible from ' +
                  'more than %.3g counts', [Ctx.Inp.ZerosFloored, LevelCounts,
                  Ctx.Inp.VisibleFactor * LevelCounts]);
end;

function OrdersVisibleCheck(const Ctx: TAssessContext): TJSONObject;
var
  Order, IM, IMod, IMLow, Predicted, Visible, Expected, Peaks: Integer;
  Lo, Hi, Theta, FirstT, LastT, Floor, ModelScale: Double;
  Arr: TJSONArray;
  Obj: TJSONObject;
  n: Integer;
  Verdict, Why: string;
  ModelVisible: Boolean;
begin
  Floor := Ctx.Inp.VisibleFactor * Ctx.Background;

  { Without a design: the maxima that stand above the background, orders and
    fringes alike, which is all that can be counted. }
  Peaks := 0;
  for n := 0 to High(Ctx.Extrema) do
    if Ctx.Extrema[n].IsMax and AboveFloor(Ctx.Inp.Curve[Ctx.Extrema[n].Idx].r, Floor) then
      Inc(Peaks);

  if not (Ctx.Inp.HasStructure and (Ctx.Period > 0)) then
  begin
    if Ctx.Inp.HasStructure then
      Why := Fmt('the design has no repeating stack, so it predicts no Bragg order; the %d maxima ' +
                 'more than %.3g times above the background are fringes or noise',
                 [Peaks, Ctx.Inp.VisibleFactor])
    else
      Why := Fmt('%d maxima stand more than %.3g times above the background; without a design ' +
                 'nothing says how many orders they are or how many there should be (on a single ' +
                 'film or a bare substrate they are fringes or noise)', [Peaks, Ctx.Inp.VisibleFactor]);
    Result := CheckJSON(TJSONNull.Create, TJSONNull.Create, VERDICT_UNKNOWN, Why);
    Result.AddPair('peaks_above_background', TJSONNumber.Create(Peaks));
    Result.AddPair('background', JSONArgs.Num(Ctx.Background));
    Result.AddPair('orders', TJSONNull.Create);
    Exit;
  end;

  { The design's orders inside the range: measured, and what the model of the
    design puts there once it is scaled to the measured plateau. }
  ModelScale := 0;
  if Length(Ctx.Model) > 0 then
  begin
    IMLow := MaxIndexInRange(Ctx.Model, Ctx.Model[0].t, Ctx.Order1Lo);
    if IMLow < 0 then
      IMLow := IndexOfMax(Ctx.Model);
    if (IMLow >= 0) and (Ctx.Model[IMLow].r > 0) then
      ModelScale := Ctx.Inp.Curve[Ctx.ILow].r / Ctx.Model[IMLow].r;
  end;

  FirstT := Ctx.Inp.Curve[0].t;
  LastT := Ctx.Inp.Curve[High(Ctx.Inp.Curve)].t;
  Predicted := 0;
  Visible := 0;
  Expected := 0;
  Arr := TJSONArray.Create;
  try
    Order := 1;
    while BraggSearchWindow(Order, Ctx.Inp.Lambda, Ctx.Period, Ctx.ThetaC, Lo, Hi, Theta) do
    begin
      if Theta > LastT then
        Break;
      if Theta >= FirstT then
      begin
        Inc(Predicted);
        IM := MaxIndexInRange(Ctx.Inp.Curve, Lo, Hi);
        Obj := TJSONObject.Create;
        Arr.AddElement(Obj);
        Obj.AddPair('n', TJSONNumber.Create(Order));
        AddAngle(Obj, 'theta_bragg_', Theta);
        if IM >= 0 then
        begin
          AddAngle(Obj, 'theta_meas_', Ctx.Inp.Curve[IM].t);
          Obj.AddPair('i_meas', JSONArgs.Num(Ctx.Inp.Curve[IM].r));
          Obj.AddPair('visible', TJSONBool.Create(AboveFloor(Ctx.Inp.Curve[IM].r, Floor)));
          if AboveFloor(Ctx.Inp.Curve[IM].r, Floor) then
            Inc(Visible);
        end
        else
        begin
          Obj.AddPair('i_meas', TJSONNull.Create);
          Obj.AddPair('visible', TJSONBool.Create(False));
        end;
        ModelVisible := False;
        if ModelScale > 0 then
        begin
          IMod := MaxIndexInRange(Ctx.Model, Lo, Hi);
          if IMod >= 0 then
          begin
            Obj.AddPair('i_model_scaled', JSONArgs.Num(Ctx.Model[IMod].r * ModelScale));
            ModelVisible := AboveFloor(Ctx.Model[IMod].r * ModelScale, Floor);
          end
          else
            Obj.AddPair('i_model_scaled', TJSONNull.Create);
        end
        else
          Obj.AddPair('i_model_scaled', TJSONNull.Create);
        Obj.AddPair('expected_visible', TJSONBool.Create(ModelVisible));
        if ModelVisible then
          Inc(Expected);
      end;
      Inc(Order);
    end;

    if ModelScale <= 0 then
    begin
      Verdict := VERDICT_UNKNOWN;
      Why := Fmt('%d of the %d orders the design puts in the range stand above the background; ' +
                 'the design''s model could not be scaled to the plateau', [Visible, Predicted]);
    end
    else if Visible >= Expected then
    begin
      Verdict := VERDICT_PASS;
      Why := Fmt('%d of the %d orders in the range are visible; the design scaled to the ' +
                 'measured plateau puts %d above the background', [Visible, Predicted, Expected]);
    end
    else
    begin
      Verdict := VERDICT_WARN;
      Why := Fmt('%d of the %d orders in the range are visible where the design scaled to the ' +
                 'measured plateau puts %d above the background: a measurement problem, not a ' +
                 'fitting one', [Visible, Predicted, Expected]);
    end;
    Why := Why + FlooredBackgroundNote(Ctx);

    Result := CheckJSON(TJSONNumber.Create(Visible), NumOrNull(Expected, ModelScale > 0), Verdict, Why);
    Result.AddPair('orders_predicted_in_range', TJSONNumber.Create(Predicted));
    Result.AddPair('orders_visible', TJSONNumber.Create(Visible));
    Result.AddPair('orders_expected_visible', NumOrNull(Expected, ModelScale > 0));
    Result.AddPair('peaks_above_background', TJSONNumber.Create(Peaks));
    Result.AddPair('background', JSONArgs.Num(Ctx.Background));
    Result.AddPair('visible_factor', JSONArgs.Num(Ctx.Inp.VisibleFactor));
    Result.AddPair('orders', Arr);
  except
    Arr.Free;
    raise;
  end;
end;

function RangeBelowBackgroundCheck(const Ctx: TAssessContext): TJSONObject;
var
  i, Count, FirstIdx, LastAbove: Integer;
  Fraction, Floor: Double;
begin
  Floor := Ctx.Inp.VisibleFactor * Ctx.Background;
  Count := 0;
  FirstIdx := -1;
  LastAbove := -1;
  for i := 0 to High(Ctx.Inp.Curve) do
  begin
    if Ctx.Inp.Curve[i].r <= Ctx.Background then
    begin
      Inc(Count);
      if FirstIdx < 0 then
        FirstIdx := i;
    end;
    if AboveFloor(Ctx.Inp.Curve[i].r, Floor) then
      LastAbove := i;
  end;
  Fraction := Count / Length(Ctx.Inp.Curve);

  Result := CheckJSON(JSONArgs.Num(Fraction), TJSONNull.Create, VERDICT_UNKNOWN,
    Fmt('%d of %d points (%.1f %%) sit at or below the background; no threshold says how much ' +
        'of a scan may be spent there', [Count, Length(Ctx.Inp.Curve), 100 * Fraction]));
  Result.AddPair('points_at_or_below_background', TJSONNumber.Create(Count));
  Result.AddPair('background', JSONArgs.Num(Ctx.Background));
  Result.AddPair('background_points', TJSONNumber.Create(REPORT_BACKGROUND_POINTS));
  if FirstIdx >= 0 then
    AddAngle(Result, 'first_at_background_', Ctx.Inp.Curve[FirstIdx].t)
  else
    AddNoAngle(Result, 'first_at_background_');
  if LastAbove >= 0 then
    AddAngle(Result, 'last_above_background_', Ctx.Inp.Curve[LastAbove].t)
  else
    AddNoAngle(Result, 'last_above_background_');
  AddAngle(Result, 'scan_end_', Ctx.Inp.Curve[High(Ctx.Inp.Curve)].t);
end;

{ Points per Kiessig fringe against the grid step - but only for fringes the
  instrument resolves. A Gaussian resolution of FWHM Res leaves
  exp(-Pi^2 Res^2 / (4 ln 2 P^2)) of the contrast of a fringe of period P,
  2.8 % at P = Res: finer fringes are gone before the step is reached, and a
  finer step would not bring them back. For those the step is judged against
  the resolution instead: coarser than Res / 2 undersamples what the
  instrument does resolve. With no resolution (0) the fringe rule applies. }
function SamplingCheck(const Ctx: TAssessContext): TJSONObject;
var
  FringeDeg, OrderDeg, PerFringe, PerOrder, Res, Contrast, PerRes: Double;
  HaveFringe, HaveOrder, Unresolved: Boolean;
  Verdict, Why, ContrastText: string;
begin
  HaveFringe := Ctx.Inp.HasStructure and (Ctx.TotalThickness > 0) and (Ctx.Inp.Lambda > 0) and (Ctx.Step > 0);
  HaveOrder := Ctx.Inp.HasStructure and (Ctx.Period > 0) and (Ctx.Inp.Lambda > 0) and (Ctx.Step > 0);
  FringeDeg := 0; OrderDeg := 0; PerFringe := 0; PerOrder := 0;
  Res := Max(0, Ctx.Inp.Resolution);
  Contrast := 1;
  PerRes := 0;
  if HaveFringe then
  begin
    FringeDeg := RadToDeg(Ctx.Inp.Lambda / (2 * Ctx.TotalThickness));
    PerFringe := FringeDeg / Ctx.Step;
    if Res > 0 then
      Contrast := Exp(-Sqr(Pi * Res / FringeDeg) / (4 * Ln(2)));
  end;
  if HaveOrder then
  begin
    OrderDeg := RadToDeg(Ctx.Inp.Lambda / (2 * Ctx.Period));
    PerOrder := OrderDeg / Ctx.Step;
  end;
  if (Res > 0) and (Ctx.Step > 0) then
    PerRes := Res / Ctx.Step;
  Unresolved := HaveFringe and (Res > 0) and (FringeDeg <= Res);
  if Contrast < 1E-3 then
    ContrastText := 'under 0.1 %'
  else
    ContrastText := Fmt('%.1f %%', [100 * Contrast]);

  if not HaveFringe then
  begin
    Verdict := VERDICT_UNKNOWN;
    Why := Fmt('the grid step is %.5f deg theta; no design gives the total thickness the fringe ' +
               'spacing follows from', [Ctx.Step]);
  end
  else if Unresolved and (PerRes < ASSESS_NYQUIST_POINTS_PER_FRINGE) then
  begin
    Verdict := VERDICT_WARN;
    Why := Fmt('the Kiessig fringes (%.5f deg) are finer than the resolution (%.5f deg FWHM), which ' +
               'leaves %s of their contrast: they are not measurable at any step. The step, %.5f deg, ' +
               'is coarser than half the resolution, so features the instrument does resolve are ' +
               'undersampled (%.2f points per resolution width)',
               [FringeDeg, Res, ContrastText, Ctx.Step, PerRes]);
  end
  else if Unresolved then
  begin
    Verdict := VERDICT_PASS;
    Why := Fmt('the Kiessig fringes (%.5f deg) are finer than the resolution (%.5f deg FWHM), which ' +
               'leaves %s of their contrast: they are not measurable at any step, and a finer step ' +
               'would not bring them back. The step, %.5f deg, gives %.2f points per resolution width',
               [FringeDeg, Res, ContrastText, Ctx.Step, PerRes]);
  end
  else if PerFringe < ASSESS_NYQUIST_POINTS_PER_FRINGE then
  begin
    Verdict := VERDICT_FAIL;
    Why := Fmt('%.2f points per Kiessig fringe (fringe %.5f deg, step %.5f deg): under two points ' +
               'per fringe the fringes are aliased and no fit will see them', [PerFringe, FringeDeg, Ctx.Step]);
  end
  else if PerFringe < Ctx.Inp.MinPointsPerFringe then
  begin
    Verdict := VERDICT_WARN;
    Why := Fmt('%.2f points per Kiessig fringe (fringe %.5f deg, step %.5f deg), fewer than the ' +
               '%.3g asked for', [PerFringe, FringeDeg, Ctx.Step, Ctx.Inp.MinPointsPerFringe]);
  end
  else
  begin
    Verdict := VERDICT_PASS;
    Why := Fmt('%.2f points per Kiessig fringe (fringe %.5f deg, step %.5f deg)',
               [PerFringe, FringeDeg, Ctx.Step]);
  end;

  Result := CheckJSON(NumOrNull(PerFringe, HaveFringe), JSONArgs.Num(Ctx.Inp.MinPointsPerFringe),
                      Verdict, Why);
  Result.AddPair('step_theta_deg', JSONArgs.Num(Ctx.Step));
  Result.AddPair('step_two_theta_deg', JSONArgs.Num(2 * Ctx.Step));
  Result.AddPair('fringe_period_theta_deg', NumOrNull(FringeDeg, HaveFringe));
  Result.AddPair('points_per_fringe', NumOrNull(PerFringe, HaveFringe));
  Result.AddPair('resolution_deg', JSONArgs.Num(Res));
  Result.AddPair('fringe_contrast', NumOrNull(Contrast, HaveFringe and (Res > 0)));
  Result.AddPair('fringes_resolved', TJSONBool.Create(not Unresolved));
  Result.AddPair('points_per_resolution', NumOrNull(PerRes, PerRes > 0));
  Result.AddPair('order_spacing_theta_deg', NumOrNull(OrderDeg, HaveOrder));
  Result.AddPair('points_per_order', NumOrNull(PerOrder, HaveOrder));
  Result.AddPair('total_thickness_A', NumOrNull(Ctx.TotalThickness, Ctx.Inp.HasStructure));
end;

function FootprintCheck(const Ctx: TAssessContext): TJSONObject;
var
  Knee, Fraction: Double;
  i, Below: Integer;
  Verdict, Why: string;
begin
  if (Ctx.Inp.SampleLengthMm <= 0) or (Ctx.Inp.BeamWidthMm <= 0) then
  begin
    Result := CheckJSON(TJSONNull.Create, TJSONNull.Create, VERDICT_UNKNOWN,
      'sample_length_mm and beam_width_mm are both needed for the footprint knee');
    Exit;
  end;

  if Ctx.Inp.BeamWidthMm >= Ctx.Inp.SampleLengthMm then
    Knee := 90
  else
    Knee := RadToDeg(ArcSin(Ctx.Inp.BeamWidthMm / Ctx.Inp.SampleLengthMm));
  Below := 0;
  for i := 0 to High(Ctx.Inp.Curve) do
    if Ctx.Inp.Curve[i].t < Knee then
      Inc(Below);
  Fraction := Below / Length(Ctx.Inp.Curve);

  if Ctx.Inp.Curve[Ctx.ILow].t < Knee then
  begin
    Verdict := VERDICT_WARN;
    Why := Fmt('the low-angle maximum at %.4f deg theta lies below the footprint knee %.4f deg ' +
               '(beam %.3g mm over %.3g mm): the beam overfills the specimen there, so the ' +
               'plateau is depressed and no scale should be read off it',
               [Ctx.Inp.Curve[Ctx.ILow].t, Knee, Ctx.Inp.BeamWidthMm, Ctx.Inp.SampleLengthMm]);
  end
  else
  begin
    Verdict := VERDICT_PASS;
    Why := Fmt('%d points (%.1f %%) lie below the footprint knee %.4f deg theta; the low-angle ' +
               'maximum at %.4f deg is above it',
               [Below, 100 * Fraction, Knee, Ctx.Inp.Curve[Ctx.ILow].t]);
  end;

  Result := CheckJSON(JSONArgs.Num(Knee), TJSONNull.Create, Verdict, Why);
  AddAngle(Result, 'knee_', Knee);
  Result.AddPair('points_below_knee', TJSONNumber.Create(Below));
  Result.AddPair('fraction_below_knee', JSONArgs.Num(Fraction));
  Result.AddPair('sample_length_mm', JSONArgs.Num(Ctx.Inp.SampleLengthMm));
  Result.AddPair('beam_width_mm', JSONArgs.Num(Ctx.Inp.BeamWidthMm));
end;

function ZerosCheck(const Ctx: TAssessContext): TJSONObject;
var
  Fraction: Double;
  Verdict, Why: string;
begin
  with Ctx.Inp do
  begin
    if not HasRaw then
    begin
      Result := CheckJSON(TJSONNull.Create, TJSONNull.Create, VERDICT_UNKNOWN,
        'the two-column parser replaces non-positive intensities before they can be counted');
      Exit;
    end;
    Fraction := ZerosFloored / Max(1, Length(Curve));
    if ZerosFloored = 0 then
    begin
      Verdict := VERDICT_PASS;
      Why := 'every point has a positive count';
    end
    else if FirstNonPositive >= 0 then
    begin
      Verdict := VERDICT_WARN;
      Why := Fmt('%d of %d points (%.1f %%) have a non-positive count, the first at %.4f deg ' +
                 'theta (%.4f deg 2theta); they were replaced by the smallest positive count ' +
                 'before them and any background taken there is a floor, not a measurement',
                 [ZerosFloored, Length(Curve), 100 * Fraction,
                  Curve[FirstNonPositive].t, 2 * Curve[FirstNonPositive].t]);
    end
    else
    begin
      Verdict := VERDICT_WARN;
      Why := Fmt('%d of %d points (%.1f %%) have a non-positive count; they were replaced by the ' +
                 'smallest positive count before them', [ZerosFloored, Length(Curve), 100 * Fraction]);
    end;
    Result := CheckJSON(TJSONNumber.Create(ZerosFloored), TJSONNull.Create, Verdict, Why);
    Result.AddPair('fraction', JSONArgs.Num(Fraction));
    if FirstNonPositive >= 0 then
      AddAngle(Result, 'first_', Curve[FirstNonPositive].t)
    else
      AddNoAngle(Result, 'first_');
  end;
end;

{ ------------------------------------------------------------ assembly -- }

function DefaultAssessInput: TAssessInput;
begin
  Result := Default(TAssessInput);
  Result.PeakIndex := -1;
  Result.RawPeakIndex := -1;
  Result.FirstNonPositive := -1;
  Result.VisibleFactor := REPORT_VISIBLE_FACTOR;
  Result.MinPointsPerFringe := ASSESS_MIN_POINTS_PER_FRINGE;
end;

function AssessInputFromScan(const Scan: TXRDMLScan): TAssessInput;
var
  i: Integer;
begin
  Result := DefaultAssessInput;
  Result.TwoThetaScan := SameText(Scan.XAxis, '2Theta');
  SetLength(Result.Curve, Length(Scan.Curve));
  for i := 0 to High(Scan.Curve) do
  begin
    Result.Curve[i].r := Scan.Curve[i].r;
    if Result.TwoThetaScan then
      Result.Curve[i].t := Scan.Curve[i].t / 2
    else
      Result.Curve[i].t := Scan.Curve[i].t;
  end;
  Result.Lambda := Scan.Lambda;
  if Scan.Lambda > 0 then
    Result.LambdaSource := 'file: ' + Scan.LambdaRule;
  Result.HasRaw := True;
  Result.IntensityUnit := Scan.IntensityUnit;
  Result.CountingTime := Scan.CountingTime;
  Result.PeakRate := Scan.PeakRate;
  Result.PeakCounts := Scan.PeakCounts;
  Result.PeakIndex := Scan.PeakIndex;
  Result.RawPeakRate := Scan.RawPeakRate;
  Result.RawPeakCounts := Scan.RawPeakCounts;
  Result.RawPeakIndex := Scan.RawPeakIndex;
  Result.AttenuationApplied := Scan.AttenuationApplied;
  Result.Detector := Scan.Detector;
  Result.ReadOutPeriod := Scan.ReadOutPeriod;
  Result.ZerosFloored := Scan.ZerosFloored;
  Result.FirstNonPositive := Scan.FirstNonPositive;
end;

procedure AssessInto(const Inp: TAssessInput; Res: TJSONObject);
var
  Ctx: TAssessContext;
  Checks, Design, Bg, Check: TJSONObject;
  Pair: TJSONPair;
  Worst: Integer;
  Verdict: string;
  SB: TStringBuilder;
begin
  if Length(Inp.Curve) < 3 then
    raise EMCPError.Create('invalid_argument',
      'the assessment needs a curve of at least three points', IntToStr(Length(Inp.Curve)));
  if Inp.HasStructure and (Inp.Lambda <= 0) then
    raise EMCPError.Create('invalid_argument',
      'a "structure" needs a wavelength to be placed at: the file carries none and no ' +
      '"lambda" was given');
  if Inp.VisibleFactor <= 0 then
    raise EMCPError.Create('invalid_argument', '"order_visible_factor" must be positive');
  if Inp.MinPointsPerFringe <= 0 then
    raise EMCPError.Create('invalid_argument', '"min_points_per_fringe" must be positive');

  Ctx := Default(TAssessContext);
  Ctx.Inp := Inp;
  SortAscending(Ctx.Inp);
  ReadCurve(Ctx);

  Res.AddPair('points', TJSONNumber.Create(Length(Ctx.Inp.Curve)));
  Res.AddPair('theta_range_deg', JSONArgs.NumArr(
    TArray<Double>.Create(Ctx.Inp.Curve[0].t, Ctx.Inp.Curve[High(Ctx.Inp.Curve)].t)));
  Res.AddPair('two_theta_range_deg', JSONArgs.NumArr(
    TArray<Double>.Create(2 * Ctx.Inp.Curve[0].t, 2 * Ctx.Inp.Curve[High(Ctx.Inp.Curve)].t)));
  Res.AddPair('two_theta_scan', TJSONBool.Create(Inp.TwoThetaScan));
  Res.AddPair('lambda', NumOrNull(Inp.Lambda, Inp.Lambda > 0));
  Res.AddPair('lambda_source', StrOrNull(Inp.LambdaSource));
  Res.AddPair('raw_facts', TJSONBool.Create(Inp.HasRaw));

  Bg := TJSONObject.Create;
  Res.AddPair('background', Bg);
  Bg.AddPair('level', JSONArgs.Num(Ctx.Background));
  Bg.AddPair('points', TJSONNumber.Create(REPORT_BACKGROUND_POINTS));
  Bg.AddPair('rule', 'median of the last points of the curve, as the fit report takes it');
  if Inp.HasRaw and (Inp.PeakCounts > 0) then
  begin
    { one count on the normalised scale: 1 = PeakCounts counts }
    Bg.AddPair('one_count', JSONArgs.Num(1 / Inp.PeakCounts));
    Bg.AddPair('level_counts', JSONArgs.Num(Ctx.Background * Inp.PeakCounts));
  end
  else
  begin
    Bg.AddPair('one_count', TJSONNull.Create);
    Bg.AddPair('level_counts', TJSONNull.Create);
  end;

  if Inp.HasStructure then
  begin
    Design := TJSONObject.Create;
    Res.AddPair('design', Design);
    Design.AddPair('period_A', NumOrNull(Ctx.Period, Ctx.Period > 0));
    Design.AddPair('total_thickness_A', JSONArgs.Num(Ctx.TotalThickness));
    Design.AddPair('theta_c_deg', JSONArgs.Num(Ctx.ThetaC));
    Design.AddPair('resolution_deg', JSONArgs.Num(Max(0, Inp.Resolution)));
    Design.AddPair('model_points', TJSONNumber.Create(Length(Ctx.Model)));
  end
  else
    Res.AddPair('design', TJSONNull.Create);

  Checks := TJSONObject.Create;
  Res.AddPair('checks', Checks);
  Checks.AddPair('counting', CountingCheck(Ctx));
  Checks.AddPair('plateau_vs_first_order', PlateauVsFirstOrderCheck(Ctx));
  Checks.AddPair('total_reflection', TotalReflectionCheck(Ctx));
  Checks.AddPair('orders_visible', OrdersVisibleCheck(Ctx));
  Checks.AddPair('range_below_background', RangeBelowBackgroundCheck(Ctx));
  Checks.AddPair('sampling', SamplingCheck(Ctx));
  Checks.AddPair('footprint', FootprintCheck(Ctx));
  Checks.AddPair('zeros', ZerosCheck(Ctx));

  { The overall verdict is the worst of the checks; unknown only when every
    check is. The text block is one line per check, in the order above. }
  Worst := 0;
  SB := TStringBuilder.Create;
  try
    for Pair in Checks do
    begin
      Check := Pair.JsonValue as TJSONObject;
      Verdict := Check.GetValue<string>('verdict');
      Worst := Max(Worst, Rank(Verdict));
      SB.Append(Pair.JsonString.Value).Append(': ').Append(Verdict).Append(' - ')
        .Append(Check.GetValue<string>('why')).Append(sLineBreak);
    end;
    case Worst of
      3: Verdict := VERDICT_FAIL;
      2: Verdict := VERDICT_WARN;
      1: Verdict := VERDICT_PASS;
    else
      Verdict := VERDICT_UNKNOWN;
    end;
    Res.AddPair('verdict', Verdict);
    Res.AddPair('summary_text', SB.ToString.TrimRight);
  finally
    SB.Free;
  end;
end;

function AssessJSON(const Inp: TAssessInput): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    AssessInto(Inp, Result);
  except
    Result.Free;
    raise;
  end;
end;

end.
