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

      This is a workaround, not a preference. The OmniThreadLibrary this tree
      compiles against (D:\DelphiProjects\_Libraries\OmniThreadLibrary, version
      1.43b of OtlTaskControl) casts pointers to Cardinal in
      TOmniTaskExecutor.GetMethodAddrAndSignature - OtlTaskControl.pas lines
      2621, 2622, 2624 and 2628 - which truncates every address in a Win64
      process to 32 bits. OTL's thread pool schedules work by sending its
      manager task a message naming a method (OtlThreadPool.pas:1878,
      otpWorkerTask.Invoke(@TOTPWorker.Schedule, ...)), so the first
      Parallel.ForEach kills the pool manager with an access violation on a
      truncated address and the calling thread then waits on the task counter
      for ever. A thirty-line console program that only calls
      Parallel.ForEach reproduces it: it hangs built with dcc64 and completes
      built with dcc32.

      Everything the server does on one thread is unaffected, and a 2000-point
      scan over 262 layers takes about 80 ms, so calc_reflectivity loses
      nothing measurable. Fitting will care. The fix belongs in OTL (Cardinal
      -> NativeUInt on those four lines) and is reported to the author rather
      than made here: that library is outside this repository and is shared
      with XRayCalc3, xrccmd and XRFCalc, whose Win64 builds have the same
      defect. When OTL is fixed, delete the MaxThreads assignment in RunCalc
      and TCalc will use every core again. *)

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
  /// The engine convolves over a fixed +/-0.1 degree window and smooths the
  /// last MVAWindow points; see CheckConvolutionFits.
  CALC_MVA_WINDOW = 10;

/// <summary>Runs one theta scan. Result is ascending in theta and holds
/// exactly Req.Points points, the first at ThetaMin and the last at ThetaMax.
/// DensitiesUsed is a deep copy of Req.Structure with every omitted density
/// replaced by the Henke bulk value the engine actually used.</summary>
function RunCalc(const Req: TCalcRequest; out DensitiesUsed: TFitStructure): unit_Types.TDataArray;

/// <summary>Bragg maxima of a calculated curve. A local maximum counts when it
/// sits more than 0.05 degrees above ThetaC and rises to more than three times
/// the smallest value within +/-max(3, n div 200) points. FWHM is the distance
/// between the linearly interpolated half-maximum crossings on either side, 0
/// when the curve does not fall to half the peak on both sides. Order is
/// round(2 d sin(theta) / lambda) when Period > 0 and the running index from 1
/// otherwise; orders below 1 are dropped and a repeated order keeps the
/// stronger peak.</summary>
function FindBraggPeaks(const Curve: unit_Types.TDataArray;
  Lambda, Period: Double; ThetaC: Double): TArray<TPeak>;

/// <summary>The total-reflection critical angle sqrt(2 delta) in degrees, taken
/// from the topmost layer of the structure - the substrate when no stack holds
/// a layer. 0 when the material has no Henke table or delta is not positive.
/// </summary>
function CriticalAngleDeg(const S: TFitStructure; Lambda: Double): Double;

/// <summary>Writes the curve as two tab-separated columns under one header
/// line. Angles use %.6g, reflectivities %.8e, both with the invariant decimal
/// point.</summary>
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

{ The engine's convolution needs room: Convolute builds a window of 2N+1 points
  spanning +/-0.1 degree, copies the untouched head with Restore(0, N-1) and
  smooths the tail with MVA(Size-N, Size-1, MVAWindow), which reads back
  MVAWindow points. Too few points over too wide a range makes those ranges
  overlap or run off the front of the array. Refuse that up front with an
  argument error naming the fix, rather than letting the engine index out of
  bounds. }
procedure CheckConvolutionFits(const Req: TCalcRequest);
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
  if 2 * N + CALC_MVA_WINDOW + 2 >= Req.Points then
    raise EMCPError.Create('invalid_argument',
      'Too few points for a convolved scan: the beam-divergence convolution ' +
      'needs a window of +/-0.1 degree, which is wider than half the scan. ' +
      'Increase "points" or narrow the theta range.',
      Format('points=%d, theta range=%.4g deg', [Req.Points, Req.ThetaMax - Req.ThetaMin]));
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

    // Single thread on purpose. See note 4 in the unit header: TCalc's parallel
    // branch deadlocks in a Win64 build with the OmniThreadLibrary this tree
    // compiles against. 2000 points over 262 layers take ~80 ms this way.
    Calc.MaxThreads := 1;
    Calc.Run;
    Result := Copy(Calc.Results);

    Req.Structure.CopyContent(DensitiesUsed);
    FillDefaultDensities(DensitiesUsed, Calc.Model);
  finally
    Calc.Free;
  end;
end;

function FindBraggPeaks(const Curve: unit_Types.TDataArray;
  Lambda, Period: Double; ThetaC: Double): TArray<TPeak>;
var
  N, W, i, j, Lo, Hi, Count, Running, Ord_, K, Dup: Integer;
  MinLocal, Half, TL, TR: Double;
  HasL, HasR: Boolean;
  Pk: TPeak;
begin
  Result := nil;
  N := Length(Curve);
  if N < 3 then
    Exit;

  W := Max(3, N div 200);
  Count := 0;
  Running := 0;
  SetLength(Result, 0);

  for i := 1 to N - 2 do
  begin
    if not ((Curve[i].r > Curve[i - 1].r) and (Curve[i].r >= Curve[i + 1].r)) then
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

    if Period > 0 then
      Ord_ := Round(2 * Period * Sin(DegToRad(Curve[i].t)) / Lambda)
    else
    begin
      Inc(Running);
      Ord_ := Running;
    end;
    if Ord_ < 1 then
      Continue;

    { FWHM: walk out to the first point at or below half the peak on each side
      and interpolate the crossing linearly between it and its inner neighbour. }
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
    for j := i + 1 to N - 1 do
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

    Pk.Order := Ord_;
    Pk.Theta := Curve[i].t;
    Pk.R := Curve[i].r;
    if HasL and HasR then
      Pk.FWHM := TR - TL
    else
      Pk.FWHM := 0;

    { One order, one peak: a shoulder that rounds to an order already taken
      only replaces it when it is the stronger of the two. }
    Dup := -1;
    for K := 0 to Count - 1 do
      if Result[K].Order = Ord_ then
      begin
        Dup := K;
        Break;
      end;
    if Dup >= 0 then
    begin
      if Pk.R > Result[Dup].R then
        Result[Dup] := Pk;
      Continue;
    end;

    SetLength(Result, Count + 1);
    Result[Count] := Pk;
    Inc(Count);
  end;
end;

function CriticalAngleDeg(const S: TFitStructure; Lambda: Double): Double;
var
  i: Integer;
  Material: string;
  Density, DensityUsed, Delta, Beta: Double;
begin
  Result := 0;
  if Lambda <= 0 then
    Exit;

  { The topmost physical layer is the first layer of the first stack:
    BuildLayeredModel appends stack 0 directly under the vacuum. }
  Material := '';
  Density := 0;
  for i := 0 to High(S.Stacks) do
    if Length(S.Stacks[i].Layers) > 0 then
    begin
      Material := S.Stacks[i].Layers[0].Material;
      Density := S.Stacks[i].Layers[0].P[3].V;
      Break;
    end;
  if Material = '' then
  begin
    Material := S.Subs.Material;
    Density := S.Subs.P[3].V;
  end;

  if not OpticalConstants(Material, Lambda, Density, DensityUsed, Delta, Beta) then
    Exit;
  if Delta <= 0 then
    Exit;
  Result := RadToDeg(Sqrt(2 * Delta));
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
      SB.Append(Format('%.6g'#9'%.8e', [Curve[i].t, Curve[i].r], FS)).Append(sLineBreak);
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
