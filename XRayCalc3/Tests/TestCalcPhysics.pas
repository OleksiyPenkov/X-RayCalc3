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
  end;

const
  HENKE_DB_PATH = 'd:\SoftwareStorage\X-RayCalc3\Henke';
  CU_KA = 1.5406;  // Cu K-alpha wavelength in Angstroms

implementation

uses
  unit_Config, unit_materials, math_complex, System.SysUtils;

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
    Layers[i].eRatio := AbsZ(DivZZ(Layers[i].e, Layers[i + 1].e));
    Layers[i + 1].s2 := Sqr(Layers[i + 1].s) * 0.50299;
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

end.
