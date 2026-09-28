unit TestCalcPhysics;

interface

uses
  DUnitX.TestFramework,
  Neslib.FastMath,
  unit_Types,
  unit_calc;

type
  TTestableCalc = class(TCalc)
  public
    function TestRefCalc(const ATheta, Lambda: single; ALayers: TCalcLayers): single;
    procedure TestCalcTet(const AParams: TCalcParams);
    procedure TestCalcLambda(StartL, EndL, Theta: single; N: integer);
    procedure AllocResult(N: integer);
  end;

  [TestFixture]
  TTestCalcPhysics = class
  private
    FSavedHenkeDir: string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { RefCalc — bare substrate physics }
    [Test] procedure Test_RefCalc_GrazingAngle_TotalReflection;
    [Test] procedure Test_RefCalc_MidAngle_PartialReflection;
    [Test] procedure Test_RefCalc_HighAngle_WeakReflection;
    [Test] procedure Test_RefCalc_Monotonic_AboveCritical;

    { CalcTet }
    [Test] procedure Test_CalcTet_UniformGrid;
    [Test] procedure Test_CalcTet_UseDataMode;

    { CalcLambda }
    [Test] procedure Test_CalcLambda_WavelengthScan;
    { A model regenerated at another wavelength - the Lambda scan - must read
      the optical constants at that wavelength, and a profile must count its
      periods from 1 again, whichever layer it sits on. }
    [Test] procedure Test_Generate_NewWavelength_ReadsItsOwnF;
    [Test] procedure Test_Generate_Twice_ProfileRestartsAtPeriodOne;
    { Every interface function is 1 at sigma = 0 and damps the reflectivity
      as sigma grows (rfLinear damped only below 0.5 A, rfSinus gave 0). }
    [Test] procedure Test_RoughnessFunctions_AllDampFromOne;

    { delta = 1 - eps, carried directly rather than recovered from a Single
      epsilon near 1 (unit_calc.EpsRatio, TCalcLayer.delta). }
    [Test] procedure Delta_ResolvesADensityChangeBelowTheSingleStepOfEps;
    [Test] procedure Delta_AmbientAndVacuumMatchTheOldForm;
  end;

const
  HENKE_DB_PATH = 'd:\SoftwareStorage\X-RayCalc3\Henke';
  CU_KA = 1.5406;  // Cu K-alpha wavelength in Angstroms

implementation

uses
  unit_Config, unit_materials, math_complex, System.SysUtils, System.Math,
  unit_parratt_ref;

{ TTestableCalc }

function TTestableCalc.TestRefCalc(const ATheta, Lambda: single; ALayers: TCalcLayers): single;
var
  c1, c2: single;
  Model: TCalcModelSoA;
  Scratch: TCalcScratchSoA;
begin
  c1 := 4 * Pi / Lambda;
  c2 := c1 * 0.5;
  Model.CopyFrom(ALayers);
  Scratch.SetCount(Model.Count);
  Result := RefCalc(ATheta, c1, c2, Model, Scratch);
end;

procedure TTestableCalc.TestCalcTet(const AParams: TCalcParams);
begin
  CalcTet(AParams);
end;

procedure TTestableCalc.TestCalcLambda(StartL, EndL, Theta: single; N: integer);
begin
  CalcLambda(StartL, EndL, Theta, N);
end;

procedure TTestableCalc.AllocResult(N: integer);
begin
  SetLength(FResult, N);
end;

{ Helpers }

procedure PrecomputeLayerConstants(var Layers: TCalcLayers);
var
  i: integer;
begin
  for i := 0 to Length(Layers) - 2 do
  begin
    Layers[i].eRatio := EpsRatio(Layers[i], Layers[i + 1], Layers[i].oneMinusRatio);
    Layers[i + 1].s2 := Sqr(Layers[i + 1].s) * 0.5;
  end;
end;

function BuildSubstrateModel(const Material: string; Sigma, Rho: single): TLayeredModel;
var
  SubLD: TLayersData;
begin
  Result := TLayeredModel.Create;
  Result.Init;
  SetLength(SubLD, 1);
  SubLD[0].Material := Material;
  SubLD[0].P[2].New(Sigma);
  SubLD[0].P[3].New(Rho);
  Result.AddSubstrate(SubLD);
end;

function MakeCalcParams(RF: TRoughnessFunction; P: TPolarisation;
  K: integer; Lambda: single): TCalcThreadParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Mode := cmTheta;
  Result.RF := RF;
  Result.P := P;
  Result.K := K;
  Result.Lambda := Lambda;
end;

{ TTestCalcPhysics }

procedure TTestCalcPhysics.Setup;
begin
  FSavedHenkeDir := TConfig.Section<TPathOptions>.HenkeDir;
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;
end;

procedure TTestCalcPhysics.TearDown;
begin
  TConfig.Section<TPathOptions>.HenkeDir := FSavedHenkeDir;
end;

{ --- RefCalc --- }

procedure TTestCalcPhysics.Test_RefCalc_GrazingAngle_TotalReflection;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Layers: TCalcLayers;
  R: single;
begin
  // Si substrate, no roughness, at 0.1 deg (below critical angle ~0.22 deg)
  // Expect total external reflection: R ~ 1
  Calc := TTestableCalc.Create;
  Model := BuildSubstrateModel('Si', 0, 2.33);
  try
    Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
    Model.Generate(CU_KA);
    Layers := Model.Layers;
    PrecomputeLayerConstants(Layers);

    R := Calc.TestRefCalc(0.1, CU_KA, Layers);

    Assert.IsTrue(R > 0.95, Format('R=%.6f should be near 1 at grazing angle', [R]));
  finally
    Model.Free;
    Calc.Free;
  end;
end;

procedure TTestCalcPhysics.Test_RefCalc_MidAngle_PartialReflection;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Layers: TCalcLayers;
  R: single;
begin
  // Si substrate at 1 deg — above critical angle
  Calc := TTestableCalc.Create;
  Model := BuildSubstrateModel('Si', 3, 2.33);
  try
    Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
    Model.Generate(CU_KA);
    Layers := Model.Layers;
    PrecomputeLayerConstants(Layers);

    R := Calc.TestRefCalc(1.0, CU_KA, Layers);

    Assert.IsTrue((R > 0) and (R < 1),
      Format('R=%.6e should be between 0 and 1', [R]));
  finally
    Model.Free;
    Calc.Free;
  end;
end;

procedure TTestCalcPhysics.Test_RefCalc_HighAngle_WeakReflection;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Layers: TCalcLayers;
  R: single;
begin
  // Si substrate at 10 deg — well above critical angle, very weak
  Calc := TTestableCalc.Create;
  Model := BuildSubstrateModel('Si', 3, 2.33);
  try
    Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
    Model.Generate(CU_KA);
    Layers := Model.Layers;
    PrecomputeLayerConstants(Layers);

    R := Calc.TestRefCalc(10.0, CU_KA, Layers);

    Assert.IsTrue(R < 1E-4,
      Format('R=%.6e should be very small at high angle', [R]));
  finally
    Model.Free;
    Calc.Free;
  end;
end;

procedure TTestCalcPhysics.Test_RefCalc_Monotonic_AboveCritical;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Layers: TCalcLayers;
  R: array[0..4] of single;
  Angles: array[0..4] of single;
  i: integer;
begin
  // Bare substrate (no roughness): reflectivity must decrease monotonically
  Calc := TTestableCalc.Create;
  Model := BuildSubstrateModel('Si', 0, 2.33);
  try
    Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
    Model.Generate(CU_KA);
    Layers := Model.Layers;
    PrecomputeLayerConstants(Layers);

    Angles[0] := 0.3;
    Angles[1] := 0.5;
    Angles[2] := 1.0;
    Angles[3] := 2.0;
    Angles[4] := 5.0;

    for i := 0 to 4 do
      R[i] := Calc.TestRefCalc(Angles[i], CU_KA, Layers);

    for i := 1 to 4 do
      Assert.IsTrue(R[i] < R[i-1],
        Format('R(%.1f)=%.4e should be < R(%.1f)=%.4e',
          [Angles[i], R[i], Angles[i-1], R[i-1]]));
  finally
    Model.Free;
    Calc.Free;
  end;
end;

{ --- CalcTet --- }

procedure TTestCalcPhysics.Test_CalcTet_UniformGrid;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  CP: TCalcParams;
  i: integer;
  ExpTheta, Step: single;
const
  N = 100;
begin
  Calc := TTestableCalc.Create;
  try
    Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);

    Model := BuildSubstrateModel('Si', 3, 2.33);
    Model.Generate(CU_KA);
    Calc.Model := Model;  // TCalc takes ownership

    Calc.AllocResult(N);

    FillChar(CP, SizeOf(CP), 0);
    Step := (5.0 - 0.5) / N;
    CP.StartTeta := 0.5;
    CP.EndTeta := 5.0;
    CP.Step := Step;
    CP.N := N;
    CP.N0 := 0;
    CP.UseData := False;

    Calc.TestCalcTet(CP);

    // Verify theta grid
    for i := 0 to N - 1 do
    begin
      ExpTheta := 0.5 + i * Step;
      Assert.AreEqual(ExpTheta, Calc.Results[i].t, 1E-4,
        Format('Theta[%d]', [i]));
    end;

    // Verify reflectivity in valid range
    for i := 0 to N - 1 do
      Assert.IsTrue((Calc.Results[i].r >= Calc.Limit) and (Calc.Results[i].r <= 1.0),
        Format('R[%d]=%.4e out of range', [i, Calc.Results[i].r]));
  finally
    Calc.Free;
  end;
end;

procedure TTestCalcPhysics.Test_CalcTet_UseDataMode;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  CP: TCalcParams;
begin
  // CalcTet with UseData=True reads theta from Points array
  Calc := TTestableCalc.Create;
  try
    Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);

    Model := BuildSubstrateModel('Si', 3, 2.33);
    Model.Generate(CU_KA);
    Calc.Model := Model;

    Calc.AllocResult(3);

    FillChar(CP, SizeOf(CP), 0);
    CP.N := 3;
    CP.N0 := 0;
    CP.UseData := True;
    SetLength(CP.Points, 3);
    CP.Points[0] := 0.5;
    CP.Points[1] := 1.0;
    CP.Points[2] := 2.0;

    Calc.TestCalcTet(CP);

    // Theta values come from Points
    Assert.AreEqual(Single(0.5), Calc.Results[0].t, 1E-5, 'Point 0');
    Assert.AreEqual(Single(1.0), Calc.Results[1].t, 1E-5, 'Point 1');
    Assert.AreEqual(Single(2.0), Calc.Results[2].t, 1E-5, 'Point 2');

    // Bare substrate: reflectivity must decrease with angle
    Assert.IsTrue(Calc.Results[0].r > Calc.Results[1].r, 'R(0.5) > R(1.0)');
    Assert.IsTrue(Calc.Results[1].r > Calc.Results[2].r, 'R(1.0) > R(2.0)');
  finally
    Calc.Free;
  end;
end;

{ --- CalcLambda --- }

procedure TTestCalcPhysics.Test_Generate_NewWavelength_ReadsItsOwnF;
const
  L1 = 1.54;
  L2 = 7.0;   // beyond the Si K edge (6.74 A): f1, f2 differ from those at L1
var
  Scanned, Fresh: TLayeredModel;
  A, B: TCalcLayers;
begin
  Scanned := BuildSubstrateModel('Si', 3, 0);
  Fresh := BuildSubstrateModel('Si', 3, 0);
  try
    Scanned.Generate(L1);
    Scanned.Generate(L2);
    Fresh.Generate(L2);
    A := Scanned.Layers;
    B := Fresh.Layers;
    Assert.AreEqual(Double(B[High(B)].e.re), Double(A[High(A)].e.re), 0, 'delta at the new wavelength');
    Assert.AreEqual(Double(B[High(B)].e.im), Double(A[High(A)].e.im), 0, 'beta at the new wavelength');
    Assert.AreEqual(Double(B[High(B)].delta), Double(A[High(A)].delta), 0,
      'TCalcLayer.delta at the new wavelength');
  finally
    Fresh.Free;
    Scanned.Free;
  end;
end;

procedure TTestCalcPhysics.Test_Generate_Twice_ProfileRestartsAtPeriodOne;
var
  Model: TLayeredModel;
  Cap, Per, Sub: TLayersData;
  Prof: TProfileFunctions;
  L: TCalcLayers;
  n, Pass: Integer;
begin
  { A cap (stack 1, one layer) over a stack 2 of three periods whose layer 1
    has H(n) = 10 + (n - 1): the profiled layer is not model layer 1. }
  Model := TLayeredModel.Create;
  try
    Model.Init;
    SetLength(Cap, 1);
    Cap[0].Material := 'C';  Cap[0].LayerID := 1;
    Cap[0].P[1].New(20); Cap[0].P[2].New(3); Cap[0].P[3].New(0);
    Model.AddLayers(1, Cap);
    SetLength(Per, 1);
    Per[0].Material := 'Si'; Per[0].LayerID := 1;
    Per[0].P[1].New(10); Per[0].P[2].New(3); Per[0].P[3].New(0);
    for n := 1 to 3 do
      Model.AddLayers(2, Per);
    SetLength(Sub, 1);
    Sub[0].Material := 'Si';
    Sub[0].P[2].New(3); Sub[0].P[3].New(0);
    Model.AddSubstrate(Sub);

    SetLength(Prof, 1);
    Prof[0].Func := ffPoly;
    Prof[0].Subj := ptH;
    Prof[0].StackID := 2;
    Prof[0].LayerID := 1;
    Prof[0].C := [10, 1];
    Model.Profiles := Prof;

    for Pass := 1 to 3 do
    begin
      Model.Generate(1.54 + Pass);   // as CalcLambda does, once per wavelength
      L := Model.Layers;
      for n := 1 to 3 do
        Assert.AreEqual(Double(10 + (n - 1)), Double(L[1 + n].L), 1E-5,
          Format('pass %d, period %d', [Pass, n]));
    end;
  finally
    Model.Free;
  end;
end;

function SubstrateR(RF: TRoughnessFunction; Sigma, Theta: Single): Single;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Layers: TCalcLayers;
begin
  Calc := TTestableCalc.Create;
  Model := BuildSubstrateModel('Si', Sigma, 2.33);
  try
    Calc.Params := MakeCalcParams(RF, cmS, 1, CU_KA);
    Model.Generate(CU_KA);
    Layers := Model.Layers;
    PrecomputeLayerConstants(Layers);
    Result := Calc.TestRefCalc(Theta, CU_KA, Layers);
  finally
    Model.Free;
    Calc.Free;
  end;
end;

procedure TTestCalcPhysics.Test_RoughnessFunctions_AllDampFromOne;
const
  Names: array[TRoughnessFunction] of string = ('Error', 'Exp', 'Linear', 'Step', 'Sinus');
var
  RF: TRoughnessFunction;
  R0, RTiny, R3, R3Error: Single;
begin
  R0 := SubstrateR(rfError, 0, 1.0);
  R3Error := SubstrateR(rfError, 3, 1.0);
  for RF := Low(TRoughnessFunction) to High(TRoughnessFunction) do
  begin
    Assert.AreEqual(Double(R0), Double(SubstrateR(RF, 0, 1.0)), Double(R0) * 1E-4,
      Names[RF] + ': sigma = 0 is a sharp interface');
    RTiny := SubstrateR(RF, 0.01, 1.0);
    Assert.AreEqual(Double(R0), Double(RTiny), Double(R0) * 1E-3,
      Names[RF] + ': sigma = 0.01 A is almost sharp');
    R3 := SubstrateR(RF, 3, 1.0);
    Assert.IsTrue((R3 < 0.99 * R0) and (R3 > 0.3 * R0),
      Format('%s: sigma = 3 A must damp R moderately (R0 %.4e, R %.4e)', [Names[RF], R0, R3]));
    { the same rms width: every form agrees with the Gaussian to second
      order in sigma*q, so at q*sigma ~ 0.4 they stay close to it }
    Assert.AreEqual(Double(R3Error), Double(R3), 0.1 * R3Error,
      Names[RF] + ': sigma is the rms width, as for the error function');
  end;
end;

procedure TTestCalcPhysics.Test_CalcLambda_WavelengthScan;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Params: TCalcThreadParams;
  i: integer;
  ExpL, Step: single;
const
  N = 50;
begin
  // Wavelength scan from 1.0 to 2.0 A at theta = 1 deg
  Calc := TTestableCalc.Create;
  try
    FillChar(Params, SizeOf(Params), 0);
    Params.RF := rfError;
    Params.P := cmS;
    Params.K := 1;
    Calc.Params := Params;

    Model := BuildSubstrateModel('Si', 3, 2.33);
    Calc.Model := Model;  // CalcLambda calls Generate internally

    Calc.TestCalcLambda(1.0, 2.0, 1.0, N);

    Assert.AreEqual(N, Length(Calc.Results), 'Result count');

    // Verify lambda grid
    Step := (2.0 - 1.0) / N;
    for i := 0 to N - 1 do
    begin
      ExpL := 1.0 + i * Step;
      Assert.AreEqual(ExpL, Calc.Results[i].t, 1E-4,
        Format('Lambda[%d]', [i]));
    end;

    // Verify reflectivity in valid range
    for i := 0 to N - 1 do
      Assert.IsTrue((Calc.Results[i].r >= Calc.Limit) and (Calc.Results[i].r <= 1.0),
        Format('R[%d]=%.4e out of range', [i, Calc.Results[i].r]));
  finally
    Calc.Free;
  end;
end;

{ --- delta = 1 - eps --- }

{ delta_Si is about 1.5e-5; 2e-4 of it is about 3e-9, below the ~6e-8 step of
  a Single stored near 1. A Single Re epsilon therefore moves by zero or one
  ULP for this density change, giving the old engine a ratio of 0 or about
  0.4%, never the reference's — delta, computed directly as f1 * c, resolves
  it instead.

  History (2026-09-28-precision-followups): the angle window originally sat
  just above Si's critical angle (~0.22 deg), not straddling it, because
  below critical, math_complex.SqrtZ's small ("interference") component came
  from Neslib.FastMath.InverseSqrt (SSE rsqrtss, no Newton refinement, ~3.7e-4
  relative error) rather than a division, and right at grazing incidence that
  term's contribution to R is leveraged enough (K0 and Im(K_substrate) are
  comparable there) that its approximation noise could exceed this test's
  2e-4 density signal - measured, not assumed (Task 2's per-angle scan from
  0.10 to 0.40 deg showed sub-1% agreement failing intermittently below
  ~0.205 deg, some points quantized to exactly 0, consistent 3-4 significant
  digit agreement from ~0.22 deg up). Task 3 measured fixing it (a Newton
  step, or the exact 1 / System.Sqrt) under the author's <= 10% CPU-fit-speed
  rule: alone it cost only ~1.6-2.8%, but combined with Task 3's exact
  TotalRecursiveRefraction phase functions (~9.3% alone) the fit measured
  11.7-12.3% slower - over budget together at first, so Task 3's first
  commit left SqrtZ unchanged and kept this window at 0.22-0.40 deg.

  Fix round 2: the author decided to adopt both changes, accepting the
  combined ~12% CPU fit cost for the accuracy. math_complex.SqrtZ now uses
  the exact 1 / System.Sqrt (ExactInverseSqrt) in place of InverseSqrt; the
  rsqrtss floor that limited this window is gone, and this test now passes
  at the brief's originally-proposed 0.15-0.25 deg window with the tolerance
  formula unchanged - restored below. Against the double-precision reference,
  CpuRawCurve_CloseToDoublePrecision's combined-set mean is 3.79E-6..5.93E-6,
  worst 4.45E-5..7.80E-5 (30 cases, down from the phase-only fix's
  7.4E-6..1.02E-5 / 8.7E-5..9.98E-5, and from the original baseline's
  2.537E-5..3.093E-5 / 5.440E-4..7.040E-4); its bounds are re-set to
  MEAN_BOUND = 1.2E-5, WORST_BOUND = 2.0E-4, the geometric mean of the
  pre-Task-3 baseline minimum and the combined set's maximum. }
procedure TTestCalcPhysics.Delta_ResolvesADensityChangeBelowTheSingleStepOfEps;
const
  RHO1 = 2.33;
  RHO2 = RHO1 * (1 + 2E-4);
  N = 41;
  THETA0 = 0.15;
  THETA1 = 0.25;
var
  Calc1, Calc2: TTestableCalc;
  Model1, Model2: TLayeredModel;
  CP: TCalcParams;
  Points: TArray<Single>;
  Step: Single;
  i: Integer;
  R1, R2, Ref1, Ref2, RatioEng, RatioRef, Diff, MaxRefDev: Double;
begin
  Step := (THETA1 - THETA0) / (N - 1);
  SetLength(Points, N);
  for i := 0 to N - 1 do
    Points[i] := THETA0 + i * Step;

  Calc1 := TTestableCalc.Create;
  Calc2 := TTestableCalc.Create;
  Model1 := BuildSubstrateModel('Si', 0, RHO1);
  Model2 := BuildSubstrateModel('Si', 0, RHO2);

  Calc1.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
  Calc2.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
  Model1.Generate(CU_KA);
  Model2.Generate(CU_KA);
  Calc1.Model := Model1;  // TCalc takes ownership
  Calc2.Model := Model2;

  Calc1.AllocResult(N);
  Calc2.AllocResult(N);

  FillChar(CP, SizeOf(CP), 0);
  CP.N := N;
  CP.N0 := 0;
  CP.UseData := True;
  CP.Points := Copy(Points);
  Calc1.TestCalcTet(CP);
  CP.Points := Copy(Points);
  Calc2.TestCalcTet(CP);

  try
    MaxRefDev := 0;
    for i := 0 to N - 1 do
    begin
      R1 := Calc1.Results[i].r;
      R2 := Calc2.Results[i].r;
      Ref1 := ParrattRef(Model1.LayersDirect, Points[i], CU_KA, False, rfError);
      Ref2 := ParrattRef(Model2.LayersDirect, Points[i], CU_KA, False, rfError);
      RatioEng := R2 / R1 - 1;
      RatioRef := Ref2 / Ref1 - 1;
      MaxRefDev := Max(MaxRefDev, Abs(RatioRef));
      Diff := Abs(RatioEng - RatioRef);
      Assert.IsTrue(Diff <= 0.1 * Abs(RatioRef) + 1E-6,
        Format('theta=%.4f: engine ratio %.6e, ref ratio %.6e, diff %.3e',
          [Points[i], RatioEng, RatioRef, Diff]));
    end;
    Assert.IsTrue(MaxRefDev > 1E-4,
      Format('max |Ref2/Ref1-1| = %.3e should exceed 1E-4 so the test is not vacuous', [MaxRefDev]));
  finally
    Calc1.Free;
    Calc2.Free;
  end;
end;

{ Ruling (controller, precision-followups Task 2): the vacuum inner layer is
  built by setting LayersDirect fields after Generate, not by a layer density
  of 0 — PrepareLayers treats a 0 density as "use the Henke bulk density",
  not vacuum. }
procedure TTestCalcPhysics.Delta_AmbientAndVacuumMatchTheOldForm;
const
  N = 41;
  THETA0 = 0.15;
  THETA1 = 0.25;
  { The CPU bound of TestGpuCalc.CpuRawCurve_CloseToDoublePrecision, re-tightened
    2026-09-28 (Task 3 fix round 2, exact math_complex.SqrtZ alongside the exact
    phase term): measured here mean=2.275E-6 (5.3x margin), worst=3.254E-6
    (61.5x margin) - comfortably under the tighter bound, so it moved too. }
  MEAN_BOUND = 1.2E-5;
  WORST_BOUND = 2.0E-4;
var
  Calc: TTestableCalc;
  Model: TLayeredModel;
  Cap, Sub: TLayersData;
  CP: TCalcParams;
  L: TCalcLayers;
  Ratio, OneMinus: Single;
  Points: TArray<Single>;
  i: Integer;
  Eng, Ref, Mean, Worst, d: Double;
begin
  Model := TLayeredModel.Create;
  Model.Init;
  SetLength(Cap, 1);
  Cap[0].Material := 'C';
  Cap[0].P[1].New(200);
  Cap[0].P[2].New(0);
  Cap[0].P[3].New(2.2);
  Model.AddLayers(1, Cap);
  SetLength(Sub, 1);
  Sub[0].Material := 'Si';
  Sub[0].P[2].New(0);
  Sub[0].P[3].New(2.33);
  Model.AddSubstrate(Sub);
  Model.Generate(CU_KA);

  L := Model.LayersDirect;
  L[1].e.re := 1;
  L[1].e.im := 0;
  L[1].delta := 0;

  Ratio := EpsRatio(L[0], L[1], OneMinus);
  Assert.AreEqual(Single(1), Ratio, 0, 'EpsRatio of two vacuum layers');
  Assert.AreEqual(Single(0), OneMinus, 0, 'OneMinus of two vacuum layers');

  SetLength(Points, N);
  for i := 0 to N - 1 do
    Points[i] := THETA0 + i * (THETA1 - THETA0) / (N - 1);

  Calc := TTestableCalc.Create;
  Calc.Params := MakeCalcParams(rfError, cmS, 1, CU_KA);
  Calc.Model := Model;  // TCalc takes ownership
  Calc.AllocResult(N);
  FillChar(CP, SizeOf(CP), 0);
  CP.N := N;
  CP.N0 := 0;
  CP.UseData := True;
  CP.Points := Copy(Points);

  try
    Calc.TestCalcTet(CP);

    Mean := 0;
    Worst := 0;
    for i := 0 to N - 1 do
    begin
      Eng := Calc.Results[i].r;
      Ref := ParrattRef(L, Points[i], CU_KA, False, rfError);
      d := Abs(System.Math.Log10(Eng / Ref));
      Mean := Mean + d;
      Worst := Max(Worst, d);
    end;
    Mean := Mean / N;
    Assert.IsTrue(Mean < MEAN_BOUND, Format('mean |log10 R/R_ref| %.3e', [Mean]));
    Assert.IsTrue(Worst < WORST_BOUND, Format('worst |log10 R/R_ref| %.3e', [Worst]));
  finally
    Calc.Free;
  end;
end;

end.
