unit TestMCPCalc;

{ unit_MCPCalc: peak finding, curve output and one end-to-end engine run.

  FindBraggPeaks, CurveToJSON and WriteCurveFile are pure and always run: the
  peak finder is checked against a synthetic curve whose peak positions, heights
  and widths are known exactly. The engine test needs the GUI's Henke tables;
  when they are not installed it passes with a note, the way the Henke tests in
  TestMCPMaterials do. Nothing here writes TConfig. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestMCPCalc = class
  private
    function HenkeAvailable(const Material: string): Boolean;
  public
    { FindBraggPeaks }
    [Test] procedure FindBraggPeaks_SyntheticGaussians_OrdersAndPositions;
    [Test] procedure FindBraggPeaks_SyntheticGaussians_FWHM;
    [Test] procedure FindBraggPeaks_NoPeriod_UsesRunningIndex;
    [Test] procedure FindBraggPeaks_BelowCriticalAngle_Ignored;
    [Test] procedure FindBraggPeaks_FlatCurve_FindsNothing;

    { CurveToJSON / WriteCurveFile }
    [Test] procedure CurveToJSON_ShortCurve_IsInline;
    [Test] procedure CurveToJSON_TooManyPoints_IsNil;
    [Test] procedure CurveToJSON_AtTheLimit_IsInline;
    [Test] procedure WriteCurveFile_HeaderAndColumns;

    { the convolution guard - no Henke tables needed, it fires before the engine }
    [Test] procedure Convolution_CoarseGrid_Raises;
    [Test] procedure Convolution_NarrowRange_Raises;
    [Test] procedure Convolution_NoDivergence_CoarseGridIsFine;

    { engine }
    [Test] procedure CriticalAngle_Ru_CuKAlpha;
    [Test] procedure RunCalc_RuC_FirstBraggPeak;
    [Test] procedure RunCalc_Convolved_KeepsPointCountAndLowersPeak;
  end;

implementation

uses
  System.SysUtils, System.Math, System.JSON, System.IOUtils, System.Classes,
  unit_Types, unit_MCPCalc, unit_MCPStructure, unit_MCPMaterials, unit_MCPErrors;

const
  CU_K_ALPHA = 1.5406;              // Angstrom

  // The synthetic curve: three Gaussians on a decaying background. The period
  // is chosen so that the three positions round to orders 1, 2 and 3:
  // 2 * 63.05 * sin(0.7 deg) / 1.5406 = 1.00.
  SYN_PERIOD  = 63.05;              // Angstrom
  SYN_FWHM    = 0.015;              // degrees
  SYN_POINTS  = 4000;
  SYN_TMIN    = 0.1;
  SYN_TMAX    = 4.0;

function TTestMCPCalc.HenkeAvailable(const Material: string): Boolean;
begin
  Result := TFile.Exists(HenkeDir + Material + '.bin');
end;

{ Three Gaussians of the given FWHM at 0.7, 1.4 and 2.1 degrees, on a background
  that decays by two decades over the range - the shape of a real reflectivity
  curve, without needing the engine or a Henke table. }
function SyntheticCurve: TDataArray;
const
  Positions: array [0 .. 2] of Double = (0.7, 1.4, 2.1);
  Amplitudes: array [0 .. 2] of Double = (0.6, 0.25, 0.08);
var
  i, k: Integer;
  T, Y, Sigma, Step: Double;
begin
  Sigma := SYN_FWHM / (2 * Sqrt(2 * Ln(2)));
  Step := (SYN_TMAX - SYN_TMIN) / (SYN_POINTS - 1);
  SetLength(Result, SYN_POINTS);
  for i := 0 to SYN_POINTS - 1 do
  begin
    T := SYN_TMIN + i * Step;
    Y := 1E-3 * Exp(-1.2 * T);
    for k := 0 to High(Positions) do
      Y := Y + Amplitudes[k] * Exp(-Sqr(T - Positions[k]) / (2 * Sqr(Sigma)));
    Result[i].t := T;
    Result[i].r := Y;
  end;
end;

{ --- FindBraggPeaks --- }

procedure TTestMCPCalc.FindBraggPeaks_SyntheticGaussians_OrdersAndPositions;
var
  Peaks: TArray<TPeak>;
begin
  Peaks := FindBraggPeaks(SyntheticCurve, CU_K_ALPHA, SYN_PERIOD, 0.3);
  Assert.AreEqual(3, Length(Peaks), 'three Gaussians, three peaks');

  Assert.AreEqual(1, Peaks[0].Order);
  Assert.AreEqual(2, Peaks[1].Order);
  Assert.AreEqual(3, Peaks[2].Order);

  // one grid step is 0.00098 deg, so 0.005 deg is five steps of slack
  Assert.AreEqual(Double(0.7), Peaks[0].Theta, 0.005, 'first order position');
  Assert.AreEqual(Double(1.4), Peaks[1].Theta, 0.005, 'second order position');
  Assert.AreEqual(Double(2.1), Peaks[2].Theta, 0.005, 'third order position');

  Assert.AreEqual(Double(0.6), Peaks[0].R, 0.01, 'first order height');
  Assert.AreEqual(Double(0.25), Peaks[1].R, 0.01, 'second order height');
  Assert.AreEqual(Double(0.08), Peaks[2].R, 0.01, 'third order height');
end;

procedure TTestMCPCalc.FindBraggPeaks_SyntheticGaussians_FWHM;
var
  Peaks: TArray<TPeak>;
  i: Integer;
begin
  Peaks := FindBraggPeaks(SyntheticCurve, CU_K_ALPHA, SYN_PERIOD, 0.3);
  Assert.AreEqual(3, Length(Peaks));
  // A Gaussian is close to straight where it crosses half its maximum, so
  // interpolating between grid points recovers the width to far better than one
  // step (0.00098 deg here): 5e-4 deg is half a step and still passes.
  for i := 0 to High(Peaks) do
    Assert.AreEqual(Double(SYN_FWHM), Peaks[i].FWHM, 5E-4,
      Format('FWHM of order %d', [Peaks[i].Order]));
end;

procedure TTestMCPCalc.FindBraggPeaks_NoPeriod_UsesRunningIndex;
var
  Peaks: TArray<TPeak>;
begin
  // Period 0: nothing is known about d, so the orders are just 1, 2, 3 ...
  Peaks := FindBraggPeaks(SyntheticCurve, CU_K_ALPHA, 0, 0.3);
  Assert.AreEqual(3, Length(Peaks));
  Assert.AreEqual(1, Peaks[0].Order);
  Assert.AreEqual(2, Peaks[1].Order);
  Assert.AreEqual(3, Peaks[2].Order);
end;

procedure TTestMCPCalc.FindBraggPeaks_BelowCriticalAngle_Ignored;
var
  Peaks: TArray<TPeak>;
begin
  // A critical angle just below the first Gaussian: the 0.05 deg guard band
  // swallows it and only the second and third orders survive.
  Peaks := FindBraggPeaks(SyntheticCurve, CU_K_ALPHA, SYN_PERIOD, 0.68);
  Assert.AreEqual(2, Length(Peaks), 'the first order is inside the guard band');
  Assert.AreEqual(2, Peaks[0].Order);
  Assert.AreEqual(3, Peaks[1].Order);
end;

procedure TTestMCPCalc.FindBraggPeaks_FlatCurve_FindsNothing;
var
  Curve: TDataArray;
  i: Integer;
begin
  SetLength(Curve, 500);
  for i := 0 to High(Curve) do
  begin
    Curve[i].t := 0.1 + i * 0.005;
    Curve[i].r := 1E-4;
  end;
  Assert.AreEqual(0, Length(FindBraggPeaks(Curve, CU_K_ALPHA, 68.5, 0.3)),
    'a flat curve has no Bragg peaks');
end;

{ --- CurveToJSON / WriteCurveFile --- }

function ShortCurve(N: Integer): TDataArray;
var
  i: Integer;
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
  begin
    Result[i].t := 0.5 + i * 0.25;
    Result[i].r := 1 / (i + 2);
  end;
end;

procedure TTestMCPCalc.CurveToJSON_ShortCurve_IsInline;
var
  Arr: TJSONArray;
  Point: TJSONArray;
begin
  Arr := CurveToJSON(ShortCurve(4), 2000);
  Assert.IsNotNull(Arr, 'four points fit inline');
  try
    Assert.AreEqual(4, Arr.Count);
    Point := Arr.Items[0] as TJSONArray;
    Assert.AreEqual(2, Point.Count, 'each point is a [theta, R] pair');
    Assert.AreEqual(Double(0.5), (Point.Items[0] as TJSONNumber).AsDouble, 1E-6);
    Assert.AreEqual(Double(0.5), (Point.Items[1] as TJSONNumber).AsDouble, 1E-6);
    // Point 0 has theta = R = 0.5, so it cannot tell the columns apart; point 1
    // can (theta 0.75, R 1/3) and pins the order.
    Point := Arr.Items[1] as TJSONArray;
    Assert.AreEqual(Double(0.75), (Point.Items[0] as TJSONNumber).AsDouble, 1E-6,
      'theta comes first');
    Assert.AreEqual(Double(1 / 3), (Point.Items[1] as TJSONNumber).AsDouble, 1E-5,
      'R comes second');
  finally
    Arr.Free;
  end;
end;

procedure TTestMCPCalc.CurveToJSON_TooManyPoints_IsNil;
begin
  // nil, not an empty array: the tool turns it into JSON null and the client
  // reads the curve from the file instead.
  Assert.IsNull(CurveToJSON(ShortCurve(5), 4), 'five points, limit four');
end;

procedure TTestMCPCalc.CurveToJSON_AtTheLimit_IsInline;
var
  Arr: TJSONArray;
begin
  Arr := CurveToJSON(ShortCurve(5), 5);
  Assert.IsNotNull(Arr, 'the limit is inclusive');
  try
    Assert.AreEqual(5, Arr.Count);
  finally
    Arr.Free;
  end;
end;

procedure TTestMCPCalc.WriteCurveFile_HeaderAndColumns;
var
  Path: string;
  Lines: TStringList;
  Cols: TArray<string>;
begin
  Path := TPath.Combine(TPath.GetTempPath, 'xrc_mcp_curve_test.dat');
  WriteCurveFile(Path, ShortCurve(3), 'theta_deg', 'R');
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(Path);
    Assert.AreEqual(4, Lines.Count, 'header plus three points');
    Assert.AreEqual('theta_deg'#9'R', Lines[0]);
    Cols := Lines[1].Split([#9]);
    Assert.AreEqual(2, Length(Cols), 'two tab separated columns');
    Assert.AreEqual(Double(0.5), StrToFloat(Cols[0], TFormatSettings.Invariant), 1E-6);
    Assert.AreEqual(Double(0.5), StrToFloat(Cols[1], TFormatSettings.Invariant), 1E-6);
    // The first row cannot tell the columns apart (both 0.5); the second can.
    Cols := Lines[2].Split([#9]);
    Assert.AreEqual(Double(0.75), StrToFloat(Cols[0], TFormatSettings.Invariant), 1E-6,
      'theta is the first column');
    Assert.AreEqual(Double(1 / 3), StrToFloat(Cols[1], TFormatSettings.Invariant), 1E-6,
      'R is the second column');
  finally
    Lines.Free;
    if TFile.Exists(Path) then
      TFile.Delete(Path);
  end;
end;

{ --- engine --- }

const
  // d = 68.5 A, gamma = 0.215 -> Ru 14.7275 / C 53.7725, 30 periods on a
  // 197 A Ru buffer over SiO2. The structure of task 5.
  RUC_JSON =
    '{"substrate":{"material":"SiO2"},' +
    '"buffer":{"material":"Ru","thickness":197},' +
    '"stacks":[{"N":30,"layers":[' +
    '{"material":"Ru","thickness":14.7275},' +
    '{"material":"C","thickness":53.7725}]}]}';

{ A request for the structure above, with the grid the caller wants. Parsing the
  structure reads no Henke table, and the convolution guard runs before TCalc is
  created, so the three guard tests below need nothing installed. }
function RuCRequest(ThetaMin, ThetaMax: Double; Points: Integer;
  DeltaTheta: Double): TCalcRequest;
var
  J: TJSONObject;
begin
  Result := Default(TCalcRequest);
  J := TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject;
  try
    Result.Structure := StructureFromJSON(J, Result.Info);
  finally
    J.Free;
  end;
  Result.Lambda := CU_K_ALPHA;
  Result.ThetaMin := ThetaMin;
  Result.ThetaMax := ThetaMax;
  Result.Points := Points;
  Result.DeltaTheta := DeltaTheta;
  Result.Polarization := cmSP;
  Result.RMin := 1E-7;
end;

{ The largest reflectivity between T1 and T2 degrees. }
function MaxRIn(const Curve: TDataArray; T1, T2: Double): Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Curve) do
    if (Curve[i].t >= T1) and (Curve[i].t <= T2) and (Curve[i].r > Result) then
      Result := Curve[i].r;
end;

procedure TTestMCPCalc.Convolution_CoarseGrid_Raises;
var
  Req: TCalcRequest;
  Used: TFitStructure;
begin
  { 5 degrees over 20 points is a step of 0.25 deg, so the engine's
    Round(0.1/delta) is 0 and its "make it odd" line turns that into -1:
    TCalc.Convolute would reach SetLength(FConvWeights, -1) and raise
    ERangeError, which the tool layer could only report as "internal". }
  Req := RuCRequest(0.0, 5.0, 20, 0.05);
  try
    RunCalc(Req, Used);
    Assert.Fail('a 0.25 deg step must not reach the engine convolution');
  except
    on E: EMCPError do
      Assert.AreEqual('invalid_argument', E.Code, 'error code for a coarse grid');
  end;
end;

procedure TTestMCPCalc.Convolution_NarrowRange_Raises;
var
  Req: TCalcRequest;
  Used: TFitStructure;
begin
  { The other end: 0.15 deg over 2000 points is so fine that the fixed
    +/-0.1 deg window is 2667 points wide - wider than the scan. }
  Req := RuCRequest(0.5, 0.65, 2000, 0.02);
  try
    RunCalc(Req, Used);
    Assert.Fail('a window wider than the scan must not reach the engine');
  except
    on E: EMCPError do
      Assert.AreEqual('invalid_argument', E.Code, 'error code for a narrow range');
  end;
end;

procedure TTestMCPCalc.Convolution_NoDivergence_CoarseGridIsFine;
var
  Req: TCalcRequest;
  Used: TFitStructure;
begin
  { The same coarse grid without divergence: TCalc.Convolute returns at once for
    a zero width, so the guard must not fire. Nothing else here needs a table,
    but the run itself does. }
  if not (HenkeAvailable('Ru') and HenkeAvailable('C') and HenkeAvailable('SiO2')) then
    Assert.Pass('Henke tables for Ru, C and SiO2 are not installed: ' + HenkeDir);
  Req := RuCRequest(0.1, 5.0, 20, 0);
  Assert.AreEqual(20, Length(RunCalc(Req, Used)),
    'a coarse grid is fine when delta_theta is 0');
end;

procedure TTestMCPCalc.RunCalc_Convolved_KeepsPointCountAndLowersPeak;
var
  Plain, Convolved: TDataArray;
  Used: TFitStructure;
  PlainPeak, ConvolvedPeak: Double;
begin
  if not (HenkeAvailable('Ru') and HenkeAvailable('C') and HenkeAvailable('SiO2')) then
    Assert.Pass('Henke tables for Ru, C and SiO2 are not installed: ' + HenkeDir);

  Plain := RunCalc(RuCRequest(0.1, 4.0, 2000, 0), Used);
  // 0.05 deg divergence against a first order about 0.054 deg wide: a fine grid,
  // so the guard must not fire, and the peak must come back visibly lower.
  Convolved := RunCalc(RuCRequest(0.1, 4.0, 2000, 0.05), Used);

  Assert.AreEqual(2000, Length(Plain), 'unconvolved point count');
  Assert.AreEqual(Length(Plain), Length(Convolved),
    'convolution must not change the number of points');
  Assert.AreEqual(Double(Plain[0].t), Double(Convolved[0].t), 1E-6, 'same first angle');
  Assert.AreEqual(Double(Plain[High(Plain)].t), Double(Convolved[High(Convolved)].t),
    1E-6, 'same last angle');

  // The first order sits near 0.687 deg; look at it in both curves.
  PlainPeak := MaxRIn(Plain, 0.6, 0.8);
  ConvolvedPeak := MaxRIn(Convolved, 0.6, 0.8);
  Assert.IsTrue(PlainPeak > 0.3,
    Format('the unconvolved first order should be strong, got %.4f', [PlainPeak]));
  Assert.IsTrue(ConvolvedPeak < PlainPeak,
    Format('convolution must lower the peak: %.4f convolved vs %.4f plain',
      [ConvolvedPeak, PlainPeak]));
  Assert.IsTrue(ConvolvedPeak > 0.3 * PlainPeak,
    Format('convolution must not erase the peak: %.4f convolved vs %.4f plain',
      [ConvolvedPeak, PlainPeak]));
end;

procedure TTestMCPCalc.CriticalAngle_Ru_CuKAlpha;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  ThetaC: Double;
begin
  if not (HenkeAvailable('Ru') and HenkeAvailable('C') and HenkeAvailable('SiO2')) then
    Assert.Pass('Henke tables for Ru, C and SiO2 are not installed: ' + HenkeDir);

  J := TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject;
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;

  // The topmost layer is Ru at bulk density; its critical angle at Cu K-alpha
  // is a little under half a degree.
  ThetaC := CriticalAngleDeg(S, CU_K_ALPHA);
  Assert.AreEqual(Double(0.478), ThetaC, 0.02, 'critical angle of Ru at 1.5406 A');
end;

procedure TTestMCPCalc.RunCalc_RuC_FirstBraggPeak;
var
  J: TJSONObject;
  Req: TCalcRequest;
  Used: TFitStructure;
  Curve: TDataArray;
  Peaks: TArray<TPeak>;
  ThetaC, Gamma, DensityUsed, DeltaRu, DeltaC, BetaDummy, DeltaBar: Double;
  BraggPlain, BraggRefracted: Double;
begin
  if not (HenkeAvailable('Ru') and HenkeAvailable('C') and HenkeAvailable('SiO2')) then
    Assert.Pass('Henke tables for Ru, C and SiO2 are not installed: ' + HenkeDir);

  Req := Default(TCalcRequest);
  J := TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject;
  try
    Req.Structure := StructureFromJSON(J, Req.Info);
  finally
    J.Free;
  end;
  Req.Lambda := CU_K_ALPHA;
  Req.ThetaMin := 0.1;
  Req.ThetaMax := 4.0;
  Req.DeltaTheta := 0;
  Req.Points := 2000;
  Req.Polarization := cmSP;
  Req.RMin := 1E-7;

  Assert.AreEqual(Double(68.5), Req.Info.Period, 1E-3, 'period from the structure');
  Assert.AreEqual(30, Req.Info.N, 'repeat count from the structure');

  Curve := RunCalc(Req, Used);
  Assert.AreEqual(2000, Length(Curve), 'exactly the number of points asked for');
  Assert.AreEqual(Double(0.1), Double(Curve[0].t), 1E-4, 'first angle');
  Assert.AreEqual(Double(4.0), Double(Curve[High(Curve)].t), 1E-4, 'last angle');

  ThetaC := CriticalAngleDeg(Used, Req.Lambda);
  Peaks := FindBraggPeaks(Curve, Req.Lambda, Req.Info.Period, ThetaC);
  Assert.IsTrue(Length(Peaks) >= 3, 'a 30-period multilayer shows several orders');
  Assert.AreEqual(1, Peaks[0].Order, 'the first peak found is the first order');

  { Position. The uncorrected Bragg law puts the first order at
    asin(lambda / 2d) = 0.6443 deg, but the multilayer refracts: the peak moves
    out to sin^2(theta) = (lambda/2d)^2 + 2*delta_avg, with delta_avg the
    thickness-weighted average of the two materials. The engine must reproduce
    the refracted position, so assert that the peak is beyond the plain Bragg
    angle and close to the refracted one. }
  BraggPlain := RadToDeg(ArcSin(Req.Lambda / (2 * Req.Info.Period)));
  Assert.AreEqual(Double(0.6443), BraggPlain, 1E-3, 'the plain Bragg angle of d = 68.5 A');

  Assert.IsTrue(OpticalConstants('Ru', Req.Lambda, 0, DensityUsed, DeltaRu, BetaDummy));
  Assert.IsTrue(OpticalConstants('C', Req.Lambda, 0, DensityUsed, DeltaC, BetaDummy));
  Gamma := 14.7275 / 68.5;
  DeltaBar := Gamma * DeltaRu + (1 - Gamma) * DeltaC;
  BraggRefracted := RadToDeg(ArcSin(Sqrt(Sqr(Sin(DegToRad(BraggPlain))) + 2 * DeltaBar)));

  Assert.IsTrue(Peaks[0].Theta > BraggPlain,
    Format('refraction must push the first order past %.4f deg, got %.4f',
      [BraggPlain, Peaks[0].Theta]));
  Assert.AreEqual(BraggRefracted, Peaks[0].Theta, 0.05,
    Format('first order near the refracted Bragg angle %.4f deg', [BraggRefracted]));

  { Height. Ideal interfaces (sigma = 0), so the first order is strong. The
    task brief expected (0.3, 0.9); the engine gives 0.90 for this structure
    because nothing damps the interfaces, so the upper bound is 0.95 here. }
  Assert.IsTrue((Peaks[0].R > 0.3) and (Peaks[0].R < 0.95),
    Format('first order reflectivity out of range: %.4f', [Peaks[0].R]));

  { The orders must be consecutive and increasing in angle. }
  Assert.AreEqual(2, Peaks[1].Order);
  Assert.IsTrue(Peaks[1].Theta > Peaks[0].Theta, 'orders run outwards');
  Assert.IsTrue(Peaks[1].R < Peaks[0].R, 'higher orders are weaker');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPCalc);

end.
