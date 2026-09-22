unit TestMCPAssess;

(* assess_xrr: is this curve worth fitting?

   The fixture is the worked example of the fitting skill's measurement-quality
   section: Tests\Data\xrdml\W-B4C_260201B_0293.xrdml, a W/B4C multilayer
   scanned on the lab's Empyrean on 2026-02-02 with a PIXcel3D detector. The
   acceptance numbers were read off the raw file by the paper session, not by
   this code: 3182 points, 2theta 0.0935 to 15.9985 in 0.0050 steps, 0.176 s
   per point, a peak of 1400062 counts at 2theta 0.4785 (7.955e6 counts/s), the
   first Bragg order 1352479 counts at 2theta 1.6735 (0.966 of the plateau -
   the two features that should differ by an order of magnitude are within 4 %
   of each other, both near 8e6 counts/s, which is what a clipped detector
   looks like), and 998 non-positive counts from 2theta 5.213 on.

   Everything the checks are fed is TAssessInput, so most tests run on the
   parsed scan without the sandbox; the one that goes through the tool proper
   puts the file in a throwaway inbox the way TestMCPInbox does. The design
   test needs the W, B4C and Si Henke tables and passes with a note without
   them, the way TestMCPFit does. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.JSON, System.Math,
  unit_Types, unit_xrdml, unit_MCPAssess, unit_MCPStructure, unit_MCPSandbox,
  unit_MCPErrors;

type
  [TestFixture]
  TTestMCPAssess = class
  private
    FScan: TXRDMLScan;
    FTemp: string;
    FSavedWorkDir: TWorkDir;
    function ExamplePath: string;
    /// <summary>The scan as the inbox hands it to the tool: theta, normalised,
    /// with the raw facts copied over.</summary>
    function InputFromScan(const Scan: TXRDMLScan): TAssessInput;
    function CheckOf(Res: TJSONObject; const Name: string): TJSONObject;
    /// <summary>A plateau rising to 1 at 0.3 deg, a theta^-4 fall, and one
    /// Gaussian "order" at 1.0 deg of the given height; or, with MaxAtStart, a
    /// curve that only falls from its first point.</summary>
    function Synthetic(FirstOrderHeight: Double; MaxAtStart: Boolean): TAssessInput;
    function DesignJSON: TJSONObject;
    function HenkePresent: Boolean;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Parser_WorkedExample_MatchesThePeerSessionsNumbers;
    [Test] procedure Counting_UnknownWithoutALimit_FailAboveIt_PassBelowIt;
    [Test] procedure PlateauVsFirstOrder_NoDesign_FindsTheOrderAndSaysUnknown;
    [Test] procedure Zeros_CountFractionAndFirstAngle;
    [Test] procedure Sampling_NoDesign_ReportsTheStepOnly;
    [Test] procedure Footprint_KneeAboveThePlateauMaximum_Warns;
    [Test] procedure TotalReflection_NoDesign_Unknown_ButMaximumAtFirstPointFails;
    [Test] procedure RangeBelowBackground_CountsTheEmptyTail;
    [Test] procedure Synthetic_FirstOrderAboveThePlateau_Fails;
    [Test] procedure TextInput_RateChecksAreUnknown;
    [Test] procedure Verdict_IsTheWorstCheck_AndSummaryHasOneLinePerCheck;
    [Test] procedure Design_OrdersSamplingCriticalAngleAndModelRatio;
    [Test] procedure Tool_ReadsTheInboxFile_RawAndText;
    [Test] procedure Tool_UnknownMeasurement_RaisesNotFound;
  end;

implementation

uses
  unit_Config;

const
  { the peer session's numbers, read off the raw file }
  EX_POINTS         = 3182;
  EX_2THETA_FIRST   = 0.0935;
  EX_2THETA_LAST    = 15.9985;
  EX_2THETA_STEP    = 0.0050;
  EX_COUNTING_TIME  = 0.176;
  EX_PEAK_COUNTS    = 1400062.0;
  EX_PEAK_2THETA    = 0.4785;
  EX_PEAK_RATE      = 7954897.7;      // 1400062 / 0.176
  { The paper session read 1348865 counts at 2theta 1.6785; the raw list has
    1352479 one step earlier, at 1.6735, and that is the maximum. }
  EX_FIRST_ORDER_2T = 1.6735;
  EX_FIRST_ORDER_R  = 0.9660;         // 1352479 / 1400062
  EX_ZEROS          = 998;
  EX_FIRST_ZERO_2T  = 5.2135;         // 0.0935 + 1024 * 0.0050
  EX_KALPHA1        = 1.5405980;
  EX_KALPHA2        = 1.5444260;
  EX_RATIO          = 0.5;
  EX_LAMBDA         = 1.541874;       // (kAlpha1 + r kAlpha2) / (1 + r)

{ ------------------------------------------------------------- fixture -- }

procedure TTestMCPAssess.Setup;
begin
  FScan := ReadXRDMLFile(ExamplePath);
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Assess_' + TGUID.NewGuid.ToString);
  FSavedWorkDir := WorkDir;
  WorkDir := TWorkDir.Create(FTemp);
  WorkDir.EnsureLayout;
end;

procedure TTestMCPAssess.TearDown;
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

function TTestMCPAssess.ExamplePath: string;
begin
  Result := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    '..\..\Data\xrdml\W-B4C_260201B_0293.xrdml'));
  Assert.IsTrue(TFile.Exists(Result), 'missing test asset: ' + Result);
end;

function TTestMCPAssess.InputFromScan(const Scan: TXRDMLScan): TAssessInput;
var
  i: Integer;
begin
  Result := DefaultAssessInput;
  SetLength(Result.Curve, Length(Scan.Curve));
  for i := 0 to High(Scan.Curve) do
  begin
    Result.Curve[i].r := Scan.Curve[i].r;
    if SameText(Scan.XAxis, '2Theta') then
      Result.Curve[i].t := Scan.Curve[i].t / 2
    else
      Result.Curve[i].t := Scan.Curve[i].t;
  end;
  Result.TwoThetaScan := SameText(Scan.XAxis, '2Theta');
  Result.Lambda := Scan.Lambda;
  Result.LambdaSource := 'file: ' + Scan.LambdaRule;
  Result.HasRaw := True;
  Result.IntensityUnit := Scan.IntensityUnit;
  Result.CountingTime := Scan.CountingTime;
  Result.PeakRate := Scan.PeakRate;
  Result.PeakCounts := Scan.PeakCounts;
  Result.AttenuationApplied := Scan.AttenuationApplied;
  Result.Detector := Scan.Detector;
  Result.ReadOutPeriod := Scan.ReadOutPeriod;
  Result.ZerosFloored := Scan.ZerosFloored;
  Result.FirstNonPositive := Scan.FirstNonPositive;
end;

function TTestMCPAssess.CheckOf(Res: TJSONObject; const Name: string): TJSONObject;
begin
  Result := (Res.GetValue('checks') as TJSONObject).GetValue(Name) as TJSONObject;
  Assert.IsNotNull(Result, 'check ' + Name + ' is in the result');
end;

function TTestMCPAssess.Synthetic(FirstOrderHeight: Double; MaxAtStart: Boolean): TAssessInput;
var
  i, n: Integer;
  t: Double;
begin
  Result := DefaultAssessInput;
  n := 591;                                    // 0.05 .. 3.0 in 0.005
  SetLength(Result.Curve, n);
  for i := 0 to n - 1 do
  begin
    t := 0.05 + 0.005 * i;
    Result.Curve[i].t := t;
    if MaxAtStart then
      Result.Curve[i].r := Power(0.05 / t, 4)
    else if t < 0.3 then
      Result.Curve[i].r := 0.5 + 0.5 * t / 0.3
    else
      Result.Curve[i].r := Power(0.3 / t, 4) +
        FirstOrderHeight * Exp(-Sqr((t - 1.0) / 0.01));
  end;
  Result.Lambda := 1.5406;
  Result.LambdaSource := 'test';
end;

function TTestMCPAssess.DesignJSON: TJSONObject;
begin
  { W 18 / B4C 35: a 53 A period whose first order lands where the worked
    example has it (2theta 1.68 at 1.5419 A); ten periods, 530 A in all }
  Result := TJSONObject.ParseJSONValue(
    '{"substrate":{"material":"Si","sigma":3},' +
    '"stacks":[{"N":10,"layers":[{"material":"W","thickness":18},' +
    '{"material":"B4C","thickness":35}]}]}') as TJSONObject;
end;

function TTestMCPAssess.HenkePresent: Boolean;
var
  Dir: string;
begin
  Dir := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);
  Result := TFile.Exists(Dir + 'W.bin') and TFile.Exists(Dir + 'B4C.bin') and
            TFile.Exists(Dir + 'Si.bin');
end;

{ ---------------------------------------------------------- the parser -- }

procedure TTestMCPAssess.Parser_WorkedExample_MatchesThePeerSessionsNumbers;
var
  IMax, i: Integer;
begin
  Assert.AreEqual(EX_POINTS, FScan.Points);
  Assert.AreEqual(EX_POINTS, Length(FScan.Curve));
  Assert.AreEqual('2Theta', FScan.XAxis);
  Assert.AreEqual(EX_2THETA_FIRST, FScan.Curve[0].t, 1E-6);
  Assert.AreEqual(EX_2THETA_LAST, FScan.Curve[High(FScan.Curve)].t, 1E-4);
  Assert.AreEqual(EX_2THETA_STEP, FScan.Curve[1].t - FScan.Curve[0].t, 1E-6);

  Assert.AreEqual('counts', FScan.IntensityUnit);
  Assert.IsFalse(FScan.AttenuationApplied, 'no beamAttenuationFactors in the file');
  Assert.IsTrue(FScan.Corrected, 'the element is named "intensities" (unit counts, no factors)');
  Assert.AreEqual(EX_COUNTING_TIME, FScan.CountingTime, 1E-9);
  Assert.AreEqual(EX_PEAK_COUNTS, FScan.PeakCounts, 0.5);
  Assert.AreEqual(EX_PEAK_RATE, FScan.PeakRate, 1);
  Assert.IsTrue(Pos('PIXcel3D', FScan.Detector) > 0, 'detector: ' + FScan.Detector);

  IMax := 0;
  for i := 1 to High(FScan.Curve) do
    if FScan.Curve[i].r > FScan.Curve[IMax].r then
      IMax := i;
  Assert.AreEqual(EX_PEAK_2THETA, FScan.Curve[IMax].t, 1E-4, 'the peak sits at 2theta 0.4785');
  Assert.AreEqual(1.0, FScan.Curve[IMax].r, 1E-9, 'normalised to 1 at the maximum');

  Assert.AreEqual(EX_ZEROS, FScan.ZerosFloored);
  Assert.IsTrue(FScan.FirstNonPositive >= 0);
  Assert.AreEqual(EX_FIRST_ZERO_2T, FScan.Curve[FScan.FirstNonPositive].t, 3E-3,
    'the zeros start at 2theta 5.213');

  Assert.AreEqual(EX_KALPHA1, FScan.KAlpha1, 1E-7);
  Assert.AreEqual(EX_KALPHA2, FScan.KAlpha2, 1E-7);
  Assert.AreEqual(EX_RATIO, FScan.Ratio, 1E-6);
  Assert.AreEqual(EX_LAMBDA, FScan.Lambda, 1E-5, 'K-Alpha through a non-hybrid mirror: the doublet');
end;

{ ---------------------------------------------------------- the checks -- }

procedure TTestMCPAssess.Counting_UnknownWithoutALimit_FailAboveIt_PassBelowIt;
var
  Inp: TAssessInput;
  Res, C: TJSONObject;
begin
  Inp := InputFromScan(FScan);
  Res := AssessJSON(Inp);
  try
    C := CheckOf(Res, 'counting');
    Assert.AreEqual('unknown', C.GetValue<string>('verdict'), 'no detector limit given');
    Assert.AreEqual(EX_PEAK_RATE, C.GetValue<Double>('value'), 10);
    Assert.AreEqual(EX_PEAK_RATE, C.GetValue<Double>('peak_rate_cps'), 10);
    Assert.AreEqual(EX_PEAK_COUNTS, C.GetValue<Double>('peak_counts'), 0.5);
    Assert.AreEqual(EX_COUNTING_TIME, C.GetValue<Double>('counting_time_s'), 1E-9);
    Assert.AreEqual(EX_PEAK_2THETA, C.GetValue<Double>('peak_two_theta_deg'), 1E-4);
    Assert.AreEqual('counts', C.GetValue<string>('unit'));
    Assert.IsFalse(C.GetValue<Boolean>('attenuation_factors'));
    Assert.IsTrue(C.GetValue('threshold') is TJSONNull, 'no threshold when none was given');
  finally
    Res.Free;
  end;

  Inp.DetectorMaxCps := 5E6;
  Res := AssessJSON(Inp);
  try
    C := CheckOf(Res, 'counting');
    Assert.AreEqual('fail', C.GetValue<string>('verdict'), '7.96e6 counts/s against a 5e6 limit');
    Assert.AreEqual(5E6, C.GetValue<Double>('threshold'), 1);
    Assert.AreEqual('fail', Res.GetValue<string>('verdict'), 'the overall verdict is the worst check');
  finally
    Res.Free;
  end;

  Inp.DetectorMaxCps := 1E7;
  Res := AssessJSON(Inp);
  try
    Assert.AreEqual('pass', CheckOf(Res, 'counting').GetValue<string>('verdict'),
      '7.96e6 counts/s against a 1e7 limit');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.PlateauVsFirstOrder_NoDesign_FindsTheOrderAndSaysUnknown;
var
  Res, C: TJSONObject;
begin
  Res := AssessJSON(InputFromScan(FScan));
  try
    C := CheckOf(Res, 'plateau_vs_first_order');
    Assert.AreEqual(EX_FIRST_ORDER_R, C.GetValue<Double>('value'), 5E-3,
      'first order over the plateau: 1348865 / 1400062');
    Assert.AreEqual(EX_FIRST_ORDER_2T, C.GetValue<Double>('first_order_two_theta_deg'), 3E-3,
      'the first order is the highest maximum after the plateau');
    Assert.AreEqual(EX_PEAK_2THETA, C.GetValue<Double>('low_angle_max_two_theta_deg'), 1E-4);
    Assert.AreEqual('unknown', C.GetValue<string>('verdict'),
      'below 1 and no design to say what it should be');
    Assert.IsTrue(C.GetValue('model_ratio') is TJSONNull);
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.Zeros_CountFractionAndFirstAngle;
var
  Res, C: TJSONObject;
begin
  Res := AssessJSON(InputFromScan(FScan));
  try
    C := CheckOf(Res, 'zeros');
    Assert.AreEqual('warn', C.GetValue<string>('verdict'));
    Assert.AreEqual(EX_ZEROS, C.GetValue<Integer>('value'));
    Assert.AreEqual(EX_ZEROS / EX_POINTS, C.GetValue<Double>('fraction'), 1E-4, '31.4 % of the scan');
    Assert.AreEqual(EX_FIRST_ZERO_2T, C.GetValue<Double>('first_two_theta_deg'), 3E-3);
    Assert.AreEqual(EX_FIRST_ZERO_2T / 2, C.GetValue<Double>('first_theta_deg'), 2E-3);
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.Sampling_NoDesign_ReportsTheStepOnly;
var
  Res, C: TJSONObject;
begin
  Res := AssessJSON(InputFromScan(FScan));
  try
    C := CheckOf(Res, 'sampling');
    Assert.AreEqual('unknown', C.GetValue<string>('verdict'));
    Assert.AreEqual(EX_2THETA_STEP / 2, C.GetValue<Double>('step_theta_deg'), 1E-6);
    Assert.AreEqual(EX_2THETA_STEP, C.GetValue<Double>('step_two_theta_deg'), 1E-6);
    Assert.IsTrue(C.GetValue('points_per_fringe') is TJSONNull, 'no thickness, no fringe');
    Assert.AreEqual(3.0, C.GetValue<Double>('threshold'), 1E-9, 'the default minimum');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.Footprint_KneeAboveThePlateauMaximum_Warns;
var
  Inp: TAssessInput;
  Res, C: TJSONObject;
begin
  Inp := InputFromScan(FScan);
  Res := AssessJSON(Inp);
  try
    Assert.AreEqual('unknown', CheckOf(Res, 'footprint').GetValue<string>('verdict'),
      'neither length nor width given');
  finally
    Res.Free;
  end;

  { a 0.1 mm beam over a 10 mm specimen: knee at asin(0.01) = 0.573 deg, above
    the plateau maximum at 0.239 deg theta }
  Inp.SampleLengthMm := 10;
  Inp.BeamWidthMm := 0.1;
  Res := AssessJSON(Inp);
  try
    C := CheckOf(Res, 'footprint');
    Assert.AreEqual('warn', C.GetValue<string>('verdict'));
    Assert.AreEqual(0.5730, C.GetValue<Double>('knee_theta_deg'), 1E-3);
    Assert.IsTrue(Abs(C.GetValue<Integer>('points_below_knee') - 211) <= 1,
      'theta = 0.04675 + 0.0025 i < 0.573 for i = 0 .. 210: ' + C.GetValue<string>('points_below_knee'));
  finally
    Res.Free;
  end;

  { a 0.1 mm beam over a 100 mm specimen: knee at 0.057 deg, below the maximum }
  Inp.SampleLengthMm := 100;
  Res := AssessJSON(Inp);
  try
    Assert.AreEqual('pass', CheckOf(Res, 'footprint').GetValue<string>('verdict'));
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.TotalReflection_NoDesign_Unknown_ButMaximumAtFirstPointFails;
var
  Res, C: TJSONObject;
begin
  Res := AssessJSON(InputFromScan(FScan));
  try
    C := CheckOf(Res, 'total_reflection');
    Assert.AreEqual('unknown', C.GetValue<string>('verdict'), 'no design places the critical angle');
    Assert.AreEqual(77, C.GetValue<Integer>('points_before_max'), '(0.4785 - 0.0935) / 0.005');
    Assert.AreEqual(EX_2THETA_FIRST, C.GetValue<Double>('scan_start_two_theta_deg'), 1E-6);
  finally
    Res.Free;
  end;

  Res := AssessJSON(Synthetic(0.5, True));
  try
    C := CheckOf(Res, 'total_reflection');
    Assert.AreEqual('fail', C.GetValue<string>('verdict'), 'the maximum is the first point');
    Assert.AreEqual(0, C.GetValue<Integer>('points_before_max'));
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.RangeBelowBackground_CountsTheEmptyTail;
var
  Res, C, Bg: TJSONObject;
begin
  Res := AssessJSON(InputFromScan(FScan));
  try
    C := CheckOf(Res, 'range_below_background');
    Assert.AreEqual('unknown', C.GetValue<string>('verdict'), 'no threshold for this one');
    Assert.IsTrue(C.GetValue<Integer>('points_at_or_below_background') >= EX_ZEROS,
      'every floored zero sits at the background floor');
    Assert.IsTrue(C.GetValue<Double>('value') >= EX_ZEROS / EX_POINTS);
    { with a one-count background, a four-count point anywhere in the tail is
      "above" it: the last such point is a fact of the scan, not a threshold }
    Assert.IsTrue(InRange(C.GetValue<Double>('last_above_background_two_theta_deg'),
      EX_FIRST_ZERO_2T, EX_2THETA_LAST));
    Assert.AreEqual(EX_2THETA_LAST, C.GetValue<Double>('scan_end_two_theta_deg'), 1E-4);

    Bg := Res.GetValue('background') as TJSONObject;
    Assert.AreEqual(1 / EX_PEAK_COUNTS, Bg.GetValue<Double>('one_count'), 1E-12,
      'one count on the normalised scale');
    Assert.IsTrue(Bg.GetValue<Double>('level_counts') >= 1 - 1E-6,
      'the background floors at one count, never at zero');
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.Synthetic_FirstOrderAboveThePlateau_Fails;
var
  Res, C: TJSONObject;
begin
  Res := AssessJSON(Synthetic(2.0, False));
  try
    C := CheckOf(Res, 'plateau_vs_first_order');
    Assert.AreEqual('fail', C.GetValue<string>('verdict'), 'a reflectivity above the plateau');
    Assert.AreEqual(2.0, C.GetValue<Double>('value'), 0.02);
    Assert.AreEqual(1.0, C.GetValue<Double>('first_order_theta_deg'), 0.006);
    Assert.AreEqual(0.3, C.GetValue<Double>('low_angle_max_theta_deg'), 0.006);
    Assert.AreEqual('fail', Res.GetValue<string>('verdict'));
  finally
    Res.Free;
  end;

  Res := AssessJSON(Synthetic(0.005, False));
  try
    C := CheckOf(Res, 'plateau_vs_first_order');
    Assert.AreEqual('unknown', C.GetValue<string>('verdict'), 'below 1, nothing to judge it against');
    Assert.IsTrue(C.GetValue<Double>('value') < 0.02);
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.TextInput_RateChecksAreUnknown;
var
  Res: TJSONObject;
begin
  Res := AssessJSON(Synthetic(0.5, False));
  try
    Assert.IsFalse(Res.GetValue<Boolean>('raw_facts'));
    Assert.AreEqual('unknown', CheckOf(Res, 'counting').GetValue<string>('verdict'));
    Assert.AreEqual('unknown', CheckOf(Res, 'zeros').GetValue<string>('verdict'));
    Assert.IsTrue((Res.GetValue('background') as TJSONObject).GetValue('one_count') is TJSONNull);
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.Verdict_IsTheWorstCheck_AndSummaryHasOneLinePerCheck;
var
  Res: TJSONObject;
  Lines: TArray<string>;
  Names: TArray<string>;
  i: Integer;
begin
  Res := AssessJSON(InputFromScan(FScan));
  try
    Assert.AreEqual('warn', Res.GetValue<string>('verdict'), 'the zeros warn; nothing fails');
    Lines := Res.GetValue<string>('summary_text').Split([sLineBreak]);
    Names := TArray<string>.Create('counting', 'plateau_vs_first_order', 'total_reflection',
      'orders_visible', 'range_below_background', 'sampling', 'footprint', 'zeros');
    Assert.AreEqual(Length(Names), Length(Lines));
    for i := 0 to High(Names) do
      Assert.IsTrue(Lines[i].StartsWith(Names[i] + ': '), Lines[i]);
  finally
    Res.Free;
  end;
end;

procedure TTestMCPAssess.Design_OrdersSamplingCriticalAngleAndModelRatio;
var
  Inp: TAssessInput;
  J: TJSONObject;
  Res, C, D: TJSONObject;
begin
  if not HenkePresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;

  Inp := InputFromScan(FScan);
  J := DesignJSON;
  try
    Inp.Structure := StructureFromJSON(J, Inp.Info);
  finally
    J.Free;
  end;
  Inp.HasStructure := True;

  Res := AssessJSON(Inp);
  try
    D := Res.GetValue('design') as TJSONObject;
    Assert.AreEqual(53.0, D.GetValue<Double>('period_A'), 1E-6);
    Assert.AreEqual(530.0, D.GetValue<Double>('total_thickness_A'), 1E-6);
    Assert.IsTrue(InRange(D.GetValue<Double>('theta_c_deg'), 0.2, 0.6),
      'W/B4C critical angle at Cu K-alpha: ' + D.GetValue<string>('theta_c_deg'));

    C := CheckOf(Res, 'total_reflection');
    Assert.AreEqual('pass', C.GetValue<string>('verdict'), 'the scan starts at 0.047 deg theta');

    C := CheckOf(Res, 'sampling');
    Assert.AreEqual('pass', C.GetValue<string>('verdict'));
    Assert.AreEqual(RadToDeg(EX_LAMBDA / 1060) / 0.0025, C.GetValue<Double>('points_per_fringe'), 0.2,
      'a 530 A film: 0.083 deg per fringe over a 0.0025 deg step');
    Assert.AreEqual(RadToDeg(EX_LAMBDA / 106) / 0.0025, C.GetValue<Double>('points_per_order'), 2);

    C := CheckOf(Res, 'orders_visible');
    Assert.AreEqual(9, C.GetValue<Integer>('orders_predicted_in_range'),
      'sin(8 deg) * 2 * 53 / 1.5419 = 9.6');
    Assert.IsTrue(InRange(C.GetValue<Integer>('orders_visible'), 2, 9),
      'orders visible: ' + C.GetValue<string>('orders_visible'));
    Assert.IsTrue((C.GetValue('orders') as TJSONArray).Count = 9);
    Assert.IsTrue(C.GetValue<string>('verdict') <> 'unknown', 'a design and a scaled model give a verdict');

    { the design's own first order over its plateau is well under the 0.963
      the file shows: that is the point of the check }
    C := CheckOf(Res, 'plateau_vs_first_order');
    Assert.IsTrue(C.GetValue<Double>('model_ratio') < EX_FIRST_ORDER_R,
      'model ratio: ' + C.GetValue<string>('model_ratio'));
    Assert.AreEqual('warn', C.GetValue<string>('verdict'), 'measured above what the design can give');
  finally
    Res.Free;
  end;
end;

{ ------------------------------------------------------------ the tool -- }

procedure TTestMCPAssess.Tool_ReadsTheInboxFile_RawAndText;
var
  Dir: string;
  Params, Res, C: TJSONObject;
  SB: TStringBuilder;
  i: Integer;
  FS: TFormatSettings;
begin
  Dir := TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1');
  TDirectory.CreateDirectory(Dir);
  TFile.Copy(ExamplePath, TPath.Combine(Dir, 'w.xrdml'));

  Params := TJSONObject.Create;
  try
    Params.AddPair('measurement_id', 'S1/w.xrdml');
    Params.AddPair('detector_max_cps', TJSONNumber.Create(1E7));
    Res := AssessMeasurementJSON(Params);
    try
      Assert.AreEqual('S1/w.xrdml', Res.GetValue<string>('measurement_id'));
      Assert.AreEqual('xrdml', Res.GetValue<string>('format'));
      Assert.IsTrue(Res.GetValue<Boolean>('raw_facts'));
      Assert.IsTrue(Res.GetValue<Boolean>('two_theta_scan'));
      Assert.AreEqual(EX_POINTS, Res.GetValue<Integer>('points'));
      Assert.AreEqual(EX_LAMBDA, Res.GetValue<Double>('lambda'), 1E-5);
      Assert.IsTrue(Res.GetValue<string>('lambda_source').StartsWith('file:'));
      C := CheckOf(Res, 'counting');
      Assert.AreEqual('pass', C.GetValue<string>('verdict'));
      Assert.AreEqual(EX_PEAK_RATE, C.GetValue<Double>('peak_rate_cps'), 10);
      Assert.AreEqual(EX_ZEROS, CheckOf(Res, 'zeros').GetValue<Integer>('value'));
    finally
      Res.Free;
    end;
  finally
    Params.Free;
  end;

  { the same curve as two columns: the rate checks have nothing to read }
  FS := TFormatSettings.Invariant;
  SB := TStringBuilder.Create;
  try
    for i := 0 to High(FScan.Curve) do
      SB.Append(FloatToStr(FScan.Curve[i].t / 2, FS)).Append(#9)
        .Append(FloatToStr(FScan.Curve[i].r, FS)).AppendLine;
    TFile.WriteAllText(TPath.Combine(Dir, 'w.dat'), SB.ToString, TEncoding.ASCII);
  finally
    SB.Free;
  end;
  Params := TJSONObject.Create;
  try
    Params.AddPair('measurement_id', 'S1/w.dat');
    Params.AddPair('detector_max_cps', TJSONNumber.Create(1E7));
    Res := AssessMeasurementJSON(Params);
    try
      Assert.AreEqual('text', Res.GetValue<string>('format'));
      Assert.IsFalse(Res.GetValue<Boolean>('raw_facts'));
      Assert.AreEqual('unknown', CheckOf(Res, 'counting').GetValue<string>('verdict'),
        'a limit was given but there is no rate to hold against it');
      Assert.AreEqual('unknown', CheckOf(Res, 'zeros').GetValue<string>('verdict'));
      Assert.AreEqual(EX_FIRST_ORDER_R,
        CheckOf(Res, 'plateau_vs_first_order').GetValue<Double>('value'), 5E-3,
        'the curve itself reads the same');
    finally
      Res.Free;
    end;
  finally
    Params.Free;
  end;
end;

procedure TTestMCPAssess.Tool_UnknownMeasurement_RaisesNotFound;
var
  Params: TJSONObject;
  Code: string;
begin
  Params := TJSONObject.Create;
  try
    Params.AddPair('measurement_id', 'S9/none.xrdml');
    Code := '';
    try
      AssessMeasurementJSON(Params).Free;
    except
      on E: EMCPError do
        Code := E.Code;
    end;
    Assert.AreEqual('not_found', Code);
  finally
    Params.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPAssess);

end.
