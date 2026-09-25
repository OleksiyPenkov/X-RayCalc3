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

unit unit_MCPCalc;

(* The reflectivity calculation, without the GUI.

   This is TCalcOrchestrator.PrepareCalc + RunCalc with the chart, the project
   panel and the settings frame taken out: the same TCalc, the same
   TLayeredModel, the same TCalcThreadParams, so acceptance 2 (the server's
   curve is the GUI's curve for the same structure) holds by construction.

   Three engine facts this unit depends on, all of them read out of
   Shared\Math\unit_calc.pas rather than assumed:

   1. TCalc.Destroy frees FLayeredModel (unit_calc.pas:324). The model handed
      to Calc.Model therefore belongs to Calc and must NOT be freed here.

   2. TCalc.PrepareWorkers (unit_calc.pas:166) has two branches. With no
      experimental data it slices [StartT, EndT] into NThreads equal blocks of
      FParams.N div NThreads points each and sizes the result array
      NThreads * (N div NThreads) - so the number of points, and the angular
      step, both depend on the number of cores of the machine, and asking for
      2000 points on a 24-core box silently returns 1992. With experimental
      data present it computes exactly one point per data point, at exactly the
      angles of the data (unit_calc.pas:199-223).

      RunCalc therefore hands the engine the angle grid it wants as
      Calc.ExpValues. The point count is then exactly Points and the grid is
      exactly ThetaMin..ThetaMax inclusive on every machine, which is what a
      tool result echoing "points" has to be able to promise. FData is read
      nowhere else in a plain calculation: only PrepareWorkers and
      CalcChiSquare (which this unit never calls) look at it.

   3. TCalc.Run for cmTheta is RunThetaThreads + Convolute(DT * K)
      (unit_calc.pas:359). With K = 1 the angles are theta, and Convolute
      returns immediately when the width is zero, so delta_theta = 0 means no
      convolution at all. CalcTet clamps every value below FLimit to FLimit
      (unit_calc.pas:304), which is what r_min sets.

   4. RunCalc sets Calc.MaxThreads := 1, so TCalc takes its single-threaded
      branch (unit_calc.pas:343) and never reaches Parallel.ForEach.

      This is a workaround, not a preference. OmniThreadLibrary before 3.08
      cast pointers to Cardinal in TOmniTaskExecutor.GetMethodAddrAndSignature
      (OtlTaskControl.pas), which truncates every address in a Win64 process
      to 32 bits. OTL's thread pool schedules work by sending its manager
      task a message naming a method (OtlThreadPool.pas,
      otpWorkerTask.Invoke(@TOTPWorker.Schedule, ...)), so the first
      Parallel.ForEach kills the pool manager with an access violation on a
      truncated address and the calling thread then waits on the task counter
      for ever. A thirty-line console program that only calls
      Parallel.ForEach reproduces it: it hangs built with dcc64 and completes
      built with dcc32.

      Status 2026-09-09: the shared clone at
      D:\DelphiProjects\_Libraries\OmniThreadLibrary is checked out at upstream
      tag release-3.08, which carries the fix (commit 220e9d03), so the hang
      is gone for optimize_mirror, fit_xrr, xrccmd -u, XRFCalc and the Win64
      GUI alike; the build requirement is OTL >= 3.08 (CLAUDE.md,
      Dependencies). RunCalc's MaxThreads := 1 is left in place even so,
      because TCalc.PrepareWorkers depends on the machine's core count (fact 2
      above) and a 2000-point scan over 262 layers takes about 80 ms single-
      threaded, so calc_reflectivity loses nothing measurable. Delete the
      assignment in RunCalc if reproducible thread counts stop mattering. *)

interface

uses
  System.JSON,
  unit_Types, unit_MCPStructure;

type
  TPeak = record
    Order: Integer;
    Theta, R, FWHM: Double;
  end;

  TCalcRequest = record
    Structure: TFitStructure;
    Info: TStructureInfo;
    Lambda, ThetaMin, ThetaMax, DeltaTheta: Double;
    Points: Integer;
    Polarization: unit_Types.TPolarisation;
    RMin: Double;                    // TCalc.Limit, the floor R is clamped to
  end;

const
  /// Ceiling on Points, the same number describe_server reports as
  /// limits.max_points.
  MAX_CALC_POINTS = 100000;

  /// Depth over which CriticalAngleDeg averages delta, in Angstrom: about what
  /// the evanescent wave samples at the plateau edge.
  CRITICAL_ANGLE_DEPTH = 500;

  /// Half-width in degrees of the window an order is looked for in when the
  /// period is known (BraggSearchWindow, and the fit report's order table).
  BRAGG_WINDOW_DEG = 0.06;
  /// The engine convolves over a fixed +/-0.1 degree window and smooths the
  /// last MVAWindow points; see CheckConvolutionFits.
  CALC_MVA_WINDOW = 10;

/// <summary>Runs one theta scan. Result is ascending in theta and holds
/// exactly Req.Points points, the first at ThetaMin and the last at ThetaMax.
/// DensitiesUsed is a deep copy of Req.Structure with every omitted density
/// replaced by the Henke bulk value the engine actually used.</summary>
function RunCalc(const Req: TCalcRequest; out DensitiesUsed: TFitStructure): unit_Types.TDataArray;

/// <summary>The Bragg angle of one order in degrees: asin(n lambda / 2 d).
/// False when the order is past the horizon (n lambda / 2 d >= 1) or the
/// period is not positive.</summary>
function BraggAngleDeg(Order: Integer; Lambda, Period: Double;
  out Theta: Double): Boolean;

/// <summary>The angular window one order is looked for in, and the Bragg angle
/// it is centred on. Refraction moves a Bragg maximum to higher angles and
/// never to lower ones - sin^2(theta_n) = (n lambda / 2 d)^2 + sin^2(theta_c) -
/// so the window runs from BRAGG_WINDOW_DEG below the Bragg angle to
/// BRAGG_WINDOW_DEG above the refraction-corrected one. On a Ru/C or Co/C
/// mirror that shift is 0.02 to 0.05 degrees at the first order and can pass
/// 0.1 degrees on a dense, long-period stack, so a window of +/-BRAGG_WINDOW_DEG
/// around the uncorrected angle alone would miss the peak it is looking for.
/// False when the order is past the horizon.</summary>
function BraggSearchWindow(Order: Integer; Lambda, Period, ThetaC: Double;
  out Lo, Hi, Theta: Double): Boolean;

/// <summary>Index of the largest value of Curve with Lo &lt;= theta &lt;= Hi, the
/// first of them when several are equal; -1 when the window holds no point.
/// </summary>
function MaxIndexInRange(const Curve: unit_Types.TDataArray;
  Lo, Hi: Double): Integer;

/// <summary>Bragg maxima of a calculated curve.
///
/// With a period (Period &gt; 0) the orders are looked for where they must be:
/// for n = 1, 2, ... while the order is inside the curve, the maximum inside
/// BraggSearchWindow is the peak of that order, provided it is a local maximum,
/// sits more than 0.05 degrees above ThetaC, and stands more than three times
/// above the smallest value in the same window. There is no search for maxima
/// at large: a generic peak finder rejects a strong Bragg peak - which is
/// broader than the window it is measured against - and accepts the sharp
/// Kiessig satellite beside it, which is how the summary of a C/Co multilayer
/// came to report 0.855 degrees (R = 0.015) for a first order that is at 0.915
/// (R = 0.203).
///
/// Without a period every local maximum that rises to more than three times the
/// smallest value within +/-max(3, n div 200) points counts, numbered from 1 in
/// angle order.
///
/// FWHM is the distance between the linearly interpolated half-maximum
/// crossings on either side, 0 when the curve does not fall to half the peak on
/// both sides.</summary>
function FindBraggPeaks(const Curve: unit_Types.TDataArray;
  Lambda, Period: Double; ThetaC: Double): TArray<TPeak>;

/// <summary>The total-reflection critical angle in degrees, estimated as
/// sqrt(2 <delta>) with <delta> the thickness-weighted mean of delta over the
/// top CRITICAL_ANGLE_DEPTH Angstrom of the structure - every stack with all
/// its periods, the substrate filling whatever the film leaves of that depth.
/// The plateau edge of a multilayer is set by the film the beam penetrates,
/// not by its top layer: a thin low-density cap on a Ru/C mirror would
/// otherwise report a fraction of the real edge. Layers without a Henke table
/// or with delta &lt;= 0 carry no weight; 0 when nothing carries weight.
/// </summary>
function CriticalAngleDeg(const S: TFitStructure; Lambda: Double): Double;

/// <summary>Writes the curve as two tab-separated columns under one header
/// line. Angles use 7 significant digits (ffGeneral, 7, 0, the same style
/// unit_MCPProjectFile.WriteCurveText uses), reflectivities %.8e, both with
/// the invariant decimal point.</summary>
procedure WriteCurveFile(const Path: string; const Curve: unit_Types.TDataArray;
  const XLabel, YLabel: string);

/// <summary>[[theta, R], ...] for a curve of at most MaxPoints points, nil for
/// a longer one - the caller then returns JSON null and the file path instead.
/// The caller owns the result.</summary>
function CurveToJSON(const Curve: unit_Types.TDataArray; MaxPoints: Integer): TJSONArray;

implementation

uses
  System.SysUtils, System.Math, System.Classes, System.IOUtils,
  unit_materials, unit_calc,
  unit_MCPErrors, unit_MCPMaterials;

{ Both ends of the convolution have to fit, and TCalc.Convolute (unit_calc.pas:
  548-602) checks neither.

  It derives its half-window from the grid it was handed:

      delta := (FResult[Size-1].t - FResult[0].t) / Size;   // Size, not Size-1
      N     := Round(0.1 / delta);
      if frac(N / 2) = 0 then N := N - 1;                   // force N odd
      SetLength(FConvWeights, 2*N + 1);

  ThetaGrid puts the first point at ThetaMin and the last at ThetaMax, so that
  delta is exactly (ThetaMax - ThetaMin) / Points and N is reproduced here
  exactly.

  Too coarse a grid. Round(0.1/delta) is 0 for delta > 0.2 degree, and the
  "make it odd" line then turns that 0 into -1, so the engine reaches
  SetLength(FConvWeights, -1) and dies with an ERangeError that the tool layer
  can only report as an internal error. N = 0 cannot survive that line either,
  so the smallest usable half-window is 1: reject anything below it.

  Too fine a grid, or too few points. The convolved region is
  [N, Size-N-1]; Restore(0, N-1) fills the head and
  MVA(Size-N, Size-1, MVAWindow) the tail, and MVA reads MVAWindow points back
  from its first index, so it walks off the front of FResult unless
  N + MVAWindow <= Size. The bound used here, 2*N + MVAWindow + 2 < Points, is
  stricter than that: it also keeps the convolved region non-empty, so the
  answer is a convolution rather than a head and a tail glued together.

  Both cases are argument errors, and both are fixed the same way - more points,
  or a narrower range, either of which shrinks delta and raises N. }
procedure CheckConvolutionFits(const Req: TCalcRequest);
const
  TOO_FEW =
    'Too few points for a convolved scan: the beam-divergence convolution ' +
    'needs a window of +/-0.1 degree, which does not fit this grid. ' +
    'Increase "points" or narrow the theta range.';
var
  Delta: Double;
  N: Integer;
begin
  if Req.DeltaTheta <= 0 then
    Exit;
  Delta := (Req.ThetaMax - Req.ThetaMin) / Req.Points;
  if Delta <= 0 then
    Exit;
  N := Round(0.1 / Delta);
  if Frac(N / 2) = 0 then
    Dec(N);                        // the engine forces an odd half-window
  if N < 1 then
    raise EMCPError.Create('invalid_argument', TOO_FEW,
      Format('points=%d, theta range=%.4g deg, step=%.4g deg: the engine would ' +
        'build a convolution window of %d points',
        [Req.Points, Req.ThetaMax - Req.ThetaMin, Delta, 2 * N + 1]));
  if 2 * N + CALC_MVA_WINDOW + 2 >= Req.Points then
    raise EMCPError.Create('invalid_argument', TOO_FEW,
      Format('points=%d, theta range=%.4g deg, step=%.4g deg: the convolution ' +
        'window is %d of the %d points',
        [Req.Points, Req.ThetaMax - Req.ThetaMin, Delta, 2 * N + 1, Req.Points]));
end;

{ The angle grid the engine is asked to compute on: Points values from ThetaMin
  to ThetaMax inclusive. Handed to TCalc as ExpValues; see the unit header. }
function ThetaGrid(const Req: TCalcRequest): unit_Types.TDataArray;
var
  i: Integer;
  Step: Double;
begin
  SetLength(Result, Req.Points);
  if Req.Points = 1 then
  begin
    Result[0].t := Req.ThetaMin;
    Result[0].r := 0;
    Exit;
  end;
  Step := (Req.ThetaMax - Req.ThetaMin) / (Req.Points - 1);
  for i := 0 to Req.Points - 1 do
  begin
    Result[i].t := Req.ThetaMin + i * Step;
    Result[i].r := 0;
  end;
  Result[Req.Points - 1].t := Req.ThetaMax;   // exact, not ThetaMin + (n-1)*step
end;

function RunCalc(const Req: TCalcRequest; out DensitiesUsed: TFitStructure): unit_Types.TDataArray;
var
  Calc: TCalc;
  P: TCalcThreadParams;
begin
  if Req.Points < 2 then
    raise EMCPError.Create('invalid_argument', '"points" must be at least 2');
  if Req.ThetaMax <= Req.ThetaMin then
    raise EMCPError.Create('invalid_argument', '"theta_max" must be greater than "theta_min"');
  if Req.Lambda <= 0 then
    raise EMCPError.Create('invalid_argument', 'The wavelength must be greater than zero');
  CheckConvolutionFits(Req);

  DensitiesUsed := Default(TFitStructure);

  Calc := TCalc.Create;
  try
    Calc.Limit := Req.RMin;

    P := Default(TCalcThreadParams);
    P.Mode := cmTheta;
    P.Lambda := Req.Lambda;
    P.StartT := Req.ThetaMin;
    P.EndT := Req.ThetaMax;
    P.DT := Req.DeltaTheta;
    P.N := Req.Points;
    P.K := 1;                       // theta, not 2theta: CalcTet divides by K
    P.P := Req.Polarization;
    P.RF := rfError;
    P.MVAWindow := CALC_MVA_WINDOW;
    Calc.Params := P;

    Calc.ExpValues := ThetaGrid(Req);
    // TCalc.Destroy frees this (unit_calc.pas:324) - do not free it here.
    Calc.Model := BuildLayeredModel(Req.Structure);

    // Single thread on purpose. See note 4 in the unit header: reproducible
    // worker layout regardless of core count, and OTL < 3.08 deadlocked here on
    // Win64. 2000 points over 262 layers take ~80 ms this way.
    Calc.MaxThreads := 1;
    Calc.Run;
    Result := Copy(Calc.Results);

    Req.Structure.CopyContent(DensitiesUsed);
    FillDefaultDensities(DensitiesUsed, Calc.Model);
  finally
    Calc.Free;
  end;
end;

function BraggAngleDeg(Order: Integer; Lambda, Period: Double;
  out Theta: Double): Boolean;
var
  S: Double;
begin
  Theta := 0;
  Result := False;
  if (Order < 1) or (Period <= 0) or (Lambda <= 0) then
    Exit;
  S := Order * Lambda / (2 * Period);
  if S >= 1 then
    Exit;
  Theta := RadToDeg(ArcSin(S));
  Result := True;
end;

function BraggSearchWindow(Order: Integer; Lambda, Period, ThetaC: Double;
  out Lo, Hi, Theta: Double): Boolean;
var
  S, SC, SR: Double;
begin
  Lo := 0;
  Hi := 0;
  Result := BraggAngleDeg(Order, Lambda, Period, Theta);
  if not Result then
    Exit;

  Lo := Theta - BRAGG_WINDOW_DEG;

  { sin^2(theta_n) = (n lambda / 2 d)^2 + sin^2(theta_c): the refracted Bragg
    law. The correction is always positive, so the window is not symmetric. }
  S := Order * Lambda / (2 * Period);
  SC := 0;
  if ThetaC > 0 then
    SC := Sin(DegToRad(ThetaC));
  SR := Sqrt(S * S + SC * SC);
  if SR >= 1 then
    Hi := 90
  else
    Hi := RadToDeg(ArcSin(SR)) + BRAGG_WINDOW_DEG;
end;

function MaxIndexInRange(const Curve: unit_Types.TDataArray;
  Lo, Hi: Double): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(Curve) do
    if (Curve[i].t >= Lo) and (Curve[i].t <= Hi) then
      if (Result < 0) or (Curve[i].r > Curve[Result].r) then
        Result := i;
end;

/// The smallest value inside the same window, which is what the maximum has to
/// stand above to be a peak rather than a point on a slope.
function MinInRange(const Curve: unit_Types.TDataArray; Lo, Hi: Double): Double;
var
  i: Integer;
  Seen: Boolean;
begin
  Result := 0;
  Seen := False;
  for i := 0 to High(Curve) do
    if (Curve[i].t >= Lo) and (Curve[i].t <= Hi) then
      if (not Seen) or (Curve[i].r < Result) then
      begin
        Result := Curve[i].r;
        Seen := True;
      end;
end;

/// A maximum of the sampled curve: strictly above the point on its left and at
/// least as high as the one on its right, which is the rule the generic search
/// has always used. The ends of the curve are not maxima.
function IsLocalMax(const Curve: unit_Types.TDataArray; i: Integer): Boolean;
begin
  Result := (i > 0) and (i < High(Curve)) and
            (Curve[i].r > Curve[i - 1].r) and (Curve[i].r >= Curve[i + 1].r);
end;

/// Distance between the linearly interpolated half-maximum crossings either
/// side of Curve[i]; 0 when the curve does not fall to half the peak on both
/// sides inside the curve.
function PeakFWHM(const Curve: unit_Types.TDataArray; i: Integer): Double;
var
  j: Integer;
  Half, TL, TR: Double;
  HasL, HasR: Boolean;
begin
  Result := 0;
  Half := Curve[i].r / 2;

  HasL := False;
  TL := 0;
  for j := i - 1 downto 0 do
    if Curve[j].r <= Half then
    begin
      if Curve[j + 1].r <> Curve[j].r then
        TL := Curve[j].t + (Half - Curve[j].r) *
          (Curve[j + 1].t - Curve[j].t) / (Curve[j + 1].r - Curve[j].r)
      else
        TL := Curve[j].t;
      HasL := True;
      Break;
    end;

  HasR := False;
  TR := 0;
  for j := i + 1 to High(Curve) do
    if Curve[j].r <= Half then
    begin
      if Curve[j - 1].r <> Curve[j].r then
        TR := Curve[j].t + (Half - Curve[j].r) *
          (Curve[j - 1].t - Curve[j].t) / (Curve[j - 1].r - Curve[j].r)
      else
        TR := Curve[j].t;
      HasR := True;
      Break;
    end;

  if HasL and HasR then
    Result := TR - TL;
end;

/// The orders of a known period, each looked for in its own window. See the
/// summary of FindBraggPeaks for why this is not a search for maxima at large.
function BraggPeaksByOrder(const Curve: unit_Types.TDataArray;
  Lambda, Period, ThetaC: Double): TArray<TPeak>;
var
  Order, Idx, Count: Integer;
  Lo, Hi, Theta, LastT: Double;
  Pk: TPeak;
begin
  Result := nil;
  Count := 0;
  LastT := Curve[High(Curve)].t;

  Order := 1;
  while BraggSearchWindow(Order, Lambda, Period, ThetaC, Lo, Hi, Theta) do
  begin
    { The Bragg angle itself has to be inside the curve: an order whose window
      only overlaps the last points of the scan is not measured, it is clipped. }
    if Theta > LastT then
      Break;

    Idx := MaxIndexInRange(Curve, Lo, Hi);
    if (Idx >= 0) and IsLocalMax(Curve, Idx) and
       (Curve[Idx].t > ThetaC + 0.05) and
       (Curve[Idx].r > 3 * MinInRange(Curve, Lo, Hi)) then
    begin
      Pk.Order := Order;
      Pk.Theta := Curve[Idx].t;
      Pk.R := Curve[Idx].r;
      Pk.FWHM := PeakFWHM(Curve, Idx);
      SetLength(Result, Count + 1);
      Result[Count] := Pk;
      Inc(Count);
    end;

    Inc(Order);
  end;
end;

/// Every local maximum that stands out from its neighbourhood, numbered from 1
/// in angle order: what is left when the period is not known.
function BraggPeaksGeneric(const Curve: unit_Types.TDataArray;
  ThetaC: Double): TArray<TPeak>;
var
  N, W, i, j, Lo, Hi, Count, Running: Integer;
  MinLocal: Double;
  Pk: TPeak;
begin
  Result := nil;
  N := Length(Curve);
  W := Max(3, N div 200);
  Count := 0;
  Running := 0;

  for i := 1 to N - 2 do
  begin
    if not IsLocalMax(Curve, i) then
      Continue;
    if Curve[i].t <= ThetaC + 0.05 then
      Continue;

    Lo := Max(0, i - W);
    Hi := Min(N - 1, i + W);
    MinLocal := Curve[Lo].r;
    for j := Lo + 1 to Hi do
      if Curve[j].r < MinLocal then
        MinLocal := Curve[j].r;
    if not (Curve[i].r > 3 * MinLocal) then
      Continue;

    Inc(Running);
    Pk.Order := Running;
    Pk.Theta := Curve[i].t;
    Pk.R := Curve[i].r;
    Pk.FWHM := PeakFWHM(Curve, i);

    SetLength(Result, Count + 1);
    Result[Count] := Pk;
    Inc(Count);
  end;
end;

function FindBraggPeaks(const Curve: unit_Types.TDataArray;
  Lambda, Period: Double; ThetaC: Double): TArray<TPeak>;
begin
  Result := nil;
  if Length(Curve) < 3 then
    Exit;
  if Period > 0 then
    Result := BraggPeaksByOrder(Curve, Lambda, Period, ThetaC)
  else
    Result := BraggPeaksGeneric(Curve, ThetaC);
end;

function CriticalAngleDeg(const S: TFitStructure; Lambda: Double): Double;
var
  i, j, Rep: Integer;
  Remaining, Weight, Sum: Double;

  procedure Add(const Material: string; Density, Thickness: Double);
  var
    DensityUsed, Delta, Beta: Double;
  begin
    if (Remaining <= 0) or (Thickness <= 0) then
      Exit;
    if Thickness > Remaining then
      Thickness := Remaining;
    if OpticalConstants(Material, Lambda, Density, DensityUsed, Delta, Beta)
       and (Delta > 0) then
    begin
      Sum := Sum + Delta * Thickness;
      Weight := Weight + Thickness;
    end;
    Remaining := Remaining - Thickness;
  end;

begin
  Result := 0;
  if Lambda <= 0 then
    Exit;

  Remaining := CRITICAL_ANGLE_DEPTH;
  Sum := 0;
  Weight := 0;

  { TFitStructure is surface-first: Stacks[0] sits directly under the vacuum,
    and BuildLayeredModel lays every stack down N times in this order. }
  for i := 0 to High(S.Stacks) do
    for Rep := 1 to Max(1, S.Stacks[i].N) do
    begin
      if Remaining <= 0 then
        Break;
      for j := 0 to High(S.Stacks[i].Layers) do
        Add(S.Stacks[i].Layers[j].Material, S.Stacks[i].Layers[j].P[3].V,
            S.Stacks[i].Layers[j].P[1].V);
    end;

  if Remaining > 0 then
    Add(S.Subs.Material, S.Subs.P[3].V, Remaining);

  if Weight <= 0 then
    Exit;
  Result := RadToDeg(Sqrt(2 * Sum / Weight));
end;

procedure WriteCurveFile(const Path: string; const Curve: unit_Types.TDataArray;
  const XLabel, YLabel: string);
var
  SB: TStringBuilder;
  FS: TFormatSettings;
  i: Integer;
begin
  FS := TFormatSettings.Invariant;
  SB := TStringBuilder.Create;
  try
    SB.Append(XLabel).Append(#9).Append(YLabel).Append(sLineBreak);
    for i := 0 to High(Curve) do
      SB.Append(FloatToStrF(Curve[i].t, ffGeneral, 7, 0, FS)).Append(#9)
        .Append(Format('%.8e', [Curve[i].r], FS)).Append(sLineBreak);
    // GetBytes, not WriteAllText: the shared TEncoding.UTF8 writes a byte order
    // mark, and a data file that starts with one confuses every plain two-column
    // reader that opens it, the GUI's included.
    TFile.WriteAllBytes(Path, TEncoding.UTF8.GetBytes(SB.ToString));
  finally
    SB.Free;
  end;
end;

function CurveToJSON(const Curve: unit_Types.TDataArray; MaxPoints: Integer): TJSONArray;
var
  i: Integer;
  PointPair: TJSONArray;
begin
  if Length(Curve) > MaxPoints then
    Exit(nil);
  Result := TJSONArray.Create;
  try
    for i := 0 to High(Curve) do
    begin
      PointPair := TJSONArray.Create;
      PointPair.AddElement(JSONArgs.Num(Curve[i].t));
      PointPair.AddElement(JSONArgs.Num(Curve[i].r));
      Result.AddElement(PointPair);
    end;
  except
    Result.Free;
    raise;
  end;
end;

end.
