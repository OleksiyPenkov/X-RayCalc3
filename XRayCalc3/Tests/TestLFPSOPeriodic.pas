unit TestLFPSOPeriodic;

interface

uses
  DUnitX.TestFramework,
  unit_Types,
  unit_materials,
  unit_LFPSO_Base,
  unit_LFPSO_Periodic;

type
  TTestablePeriodic = class(TLFPSO_Periodic)
  public
    property Pub_FStructure: TFitStructure read FStructure write FStructure;
    property Pub_FLayersCount: integer read FLayersCount write FLayersCount;
    property Pub_FPopulation: integer read FPopulation write FPopulation;
    property Pub_FTMax: integer read FTMax write FTMax;
    property Pub_FFitParams: TFitParams read FFitParams write FFitParams;

    function GetX: TPopulation;
    function GetV: TPopulation;
    function GetXmax: TPopulation;
    function GetXmin: TPopulation;
    function GetXrange: TPopulation;
    function GetVmax: TPopulation;
    function GetVmin: TPopulation;

    procedure TestSetStructure(const Inp: TFitStructure);
    procedure TestNormalizeD(const ParticleIndex: integer);
    procedure TestInitVelocity;
    procedure TestXSeed;
    procedure TestRangeSeed;
    procedure TestSetParams(const Value: TFitParams);
  end;

  [TestFixture]
  TTestLFPSOPeriodic = class
  private
    FPSO: TTestablePeriodic;
    function MakeParams: TFitParams;
    function MakePeriodicStructure: TFitStructure;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { SetStructure }
    [Test] procedure Test_SetStructure_SetsLayerCount;
    [Test] procedure Test_SetStructure_ComputesPeriodD;
    [Test] procedure Test_SetStructure_InitializesX0;
    [Test] procedure Test_SetStructure_InitializesXminXmax;

    { NormalizeD }
    [Test] procedure Test_NormalizeD_PreservesPeriod;
    [Test] procedure Test_NormalizeD_SkipsNonPeriodicStack;

    { InitVelocity }
    [Test] procedure Test_InitVelocity_SetsVmaxFromXrange;
    [Test] procedure Test_InitVelocity_VminIsNegativeVmax;
    [Test] procedure Test_InitVelocity_VWithinBounds;

    { XSeed }
    [Test] procedure Test_XSeed_X0Unchanged;
    [Test] procedure Test_XSeed_OtherParticlesPerturbed;

    { RangeSeed }
    [Test] procedure Test_RangeSeed_AllWithinBounds;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TTestablePeriodic }

function TTestablePeriodic.GetX: TPopulation; begin Result := X; end;
function TTestablePeriodic.GetV: TPopulation; begin Result := V; end;
function TTestablePeriodic.GetXmax: TPopulation; begin Result := Xmax; end;
function TTestablePeriodic.GetXmin: TPopulation; begin Result := Xmin; end;
function TTestablePeriodic.GetXrange: TPopulation; begin Result := Xrange; end;
function TTestablePeriodic.GetVmax: TPopulation; begin Result := Vmax; end;
function TTestablePeriodic.GetVmin: TPopulation; begin Result := Vmin; end;

procedure TTestablePeriodic.TestSetStructure(const Inp: TFitStructure);
begin SetStructure(Inp); end;

procedure TTestablePeriodic.TestNormalizeD(const ParticleIndex: integer);
begin NormalizeD(ParticleIndex); end;

procedure TTestablePeriodic.TestInitVelocity;
begin InitVelocity; end;

procedure TTestablePeriodic.TestXSeed;
begin XSeed; end;

procedure TTestablePeriodic.TestRangeSeed;
begin RangeSeed; end;

procedure TTestablePeriodic.TestSetParams(const Value: TFitParams);
begin SetParams(Value); end;

{ TTestLFPSOPeriodic — helpers }

function TTestLFPSOPeriodic.MakeParams: TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax := 50;
  Result.Pop := 5;
  Result.Tolerance := 0.001;
  Result.Vmax := 0.3;
  Result.JammingMax := 5;
  Result.ReInitMax := 3;
  Result.KChiSqr := 1.5;
  Result.KVmax := 1.2;
  Result.w1 := 0.4;
  Result.w2 := 0.5;
  Result.Shake := False;
  Result.AdaptVel := False;
  Result.RangeSeed := False;
  Result.Ksxr := 0.1;
end;

function TTestLFPSOPeriodic.MakePeriodicStructure: TFitStructure;
var
  p: integer;
begin
  // One periodic stack with N=3 repeats, 2 layers per stack
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 3;
  SetLength(Result.Stacks[0].Layers, 2);

  // Layer 0: H=20, s=2, rho=5
  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID := 0;
  Result.Stacks[0].Layers[0].LayerID := 0;
  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[0].P[p].min := 1.0;
    Result.Stacks[0].Layers[0].P[p].max := 100.0;
  end;
  Result.Stacks[0].Layers[0].P[1].V := 20.0;  // H
  Result.Stacks[0].Layers[0].P[2].V := 2.0;   // s
  Result.Stacks[0].Layers[0].P[3].V := 5.0;   // rho

  // Layer 1: H=30, s=3, rho=7
  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID := 0;
  Result.Stacks[0].Layers[1].LayerID := 1;
  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[1].P[p].min := 1.0;
    Result.Stacks[0].Layers[1].P[p].max := 100.0;
  end;
  Result.Stacks[0].Layers[1].P[1].V := 30.0;  // H
  Result.Stacks[0].Layers[1].P[2].V := 3.0;   // s
  Result.Stacks[0].Layers[1].P[3].V := 7.0;   // rho

  // Substrate
  Result.Subs.Material := 'Si';
  for p := 1 to 3 do
    Result.Subs.P[p].V := 5.0;
end;

{ Setup / TearDown }

procedure TTestLFPSOPeriodic.Setup;
begin
  FPSO := TTestablePeriodic.Create;
end;

procedure TTestLFPSOPeriodic.TearDown;
begin
  FPSO.Free;
end;

{ SetStructure }

procedure TTestLFPSOPeriodic.Test_SetStructure_SetsLayerCount;
var
  S: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  // 2 layers per stack, Total counts unique layers = 2
  Assert.AreEqual(2, FPSO.Pub_FLayersCount, 'LayersCount = Total unique layers');
end;

procedure TTestLFPSOPeriodic.Test_SetStructure_ComputesPeriodD;
var
  S: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  // D = H[0] + H[1] = 20 + 30 = 50
  Assert.AreEqual(Double(50.0), FPSO.Pub_FStructure.Stacks[0].D, 1E-5, 'Period D = sum of H');
end;

procedure TTestLFPSOPeriodic.Test_SetStructure_InitializesX0;
var
  S: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  // X[0] should hold initial values
  Assert.AreEqual(Single(20.0), FPSO.GetX[0][0][1][0], 1E-5, 'X[0] layer0 H=20');
  Assert.AreEqual(Single(2.0),  FPSO.GetX[0][0][2][0], 1E-5, 'X[0] layer0 s=2');
  Assert.AreEqual(Single(30.0), FPSO.GetX[0][1][1][0], 1E-5, 'X[0] layer1 H=30');
end;

procedure TTestLFPSOPeriodic.Test_SetStructure_InitializesXminXmax;
var
  S: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  Assert.AreEqual(Single(1.0),   FPSO.GetXmin[0][0][1][0], 1E-5, 'Xmin layer0 H');
  Assert.AreEqual(Single(100.0), FPSO.GetXmax[0][0][1][0], 1E-5, 'Xmax layer0 H');
end;

{ NormalizeD }

procedure TTestLFPSOPeriodic.Test_NormalizeD_PreservesPeriod;
var
  S: TFitStructure;
  D_before, D_after: double;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  D_before := FPSO.Pub_FStructure.Stacks[0].D;  // 50

  // Perturb thicknesses of particle 1
  FPSO.GetX[1][0][1][0] := 25.0;  // was 20
  FPSO.GetX[1][1][1][0] := 35.0;  // was 30 -> sum = 60, not 50

  FPSO.TestNormalizeD(1);

  // After normalization, sum should equal D_before = 50
  D_after := FPSO.GetX[1][0][1][0] + FPSO.GetX[1][1][1][0];
  Assert.AreEqual(D_before, D_after, 1E-3, 'Sum of H should equal period D');
end;

procedure TTestLFPSOPeriodic.Test_NormalizeD_SkipsNonPeriodicStack;
var
  S: TFitStructure;
  H_before: single;
  p: integer;
begin
  FPSO.TestSetParams(MakeParams);
  // Make a non-periodic structure (N=1)
  SetLength(S.Stacks, 1);
  S.Stacks[0].N := 1;
  SetLength(S.Stacks[0].Layers, 1);
  S.Stacks[0].Layers[0].Material := 'Si';
  S.Stacks[0].Layers[0].StackID := 0;
  S.Stacks[0].Layers[0].LayerID := 0;
  for p := 1 to 3 do
  begin
    S.Stacks[0].Layers[0].P[p].V := 10.0;
    S.Stacks[0].Layers[0].P[p].min := 1.0;
    S.Stacks[0].Layers[0].P[p].max := 100.0;
  end;
  S.Subs.Material := 'Si';
  for p := 1 to 3 do
    S.Subs.P[p].V := 5.0;

  FPSO.TestSetStructure(S);

  // Perturb thickness
  FPSO.GetX[1][0][1][0] := 42.0;
  H_before := FPSO.GetX[1][0][1][0];

  FPSO.TestNormalizeD(1);

  // Should be unchanged — N=1 means non-periodic, NormalizeD skips it
  Assert.AreEqual(H_before, FPSO.GetX[1][0][1][0], 1E-5, 'Non-periodic H unchanged');
end;

{ InitVelocity }

procedure TTestLFPSOPeriodic.Test_InitVelocity_SetsVmaxFromXrange;
var
  S: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  FPSO.TestInitVelocity;
  // Vmax = Xrange * FitParams.Vmax(0.3)
  // Xrange[0][0][1] = 100-1 = 99 -> Vmax = 99*0.3 = 29.7
  Assert.AreEqual(Single(99.0 * 0.3), FPSO.GetVmax[0][0][1][0], 1E-3, 'Vmax = Xrange * params.Vmax');
end;

procedure TTestLFPSOPeriodic.Test_InitVelocity_VminIsNegativeVmax;
var
  S: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  FPSO.TestInitVelocity;
  Assert.AreEqual(-FPSO.GetVmax[0][0][1][0], FPSO.GetVmin[0][0][1][0], 1E-5,
    'Vmin = -Vmax');
end;

procedure TTestLFPSOPeriodic.Test_InitVelocity_VWithinBounds;
var
  S: TFitStructure;
  i, j, k: integer;
  lo, hi, v: single;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  FPSO.TestInitVelocity;

  for i := 0 to High(FPSO.GetV) do
    for j := 0 to High(FPSO.GetV[i]) do
      for k := 1 to 3 do
      begin
        v := FPSO.GetV[i][j][k][0];
        lo := FPSO.GetVmin[0][j][k][0];
        hi := FPSO.GetVmax[0][j][k][0];
        Assert.IsTrue((v >= lo - 1E-3) and (v <= hi + 1E-3),
          Format('V[%d][%d][%d] = %g not in [%g..%g]', [i, j, k, v, lo, hi]));
      end;
end;

{ XSeed }

procedure TTestLFPSOPeriodic.Test_XSeed_X0Unchanged;
var
  S: TFitStructure;
  H0_before: single;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);

  H0_before := FPSO.GetX[0][0][1][0];
  FPSO.TestXSeed;
  Assert.AreEqual(H0_before, FPSO.GetX[0][0][1][0], 1E-5,
    'X[0] (reference particle) should not change');
end;

procedure TTestLFPSOPeriodic.Test_XSeed_OtherParticlesPerturbed;
var
  S: TFitStructure;
  i: integer;
  allSame: Boolean;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  FPSO.TestXSeed;

  // At least one particle should differ from X[0]
  allSame := True;
  for i := 1 to High(FPSO.GetX) do
    if Abs(FPSO.GetX[i][0][1][0] - FPSO.GetX[0][0][1][0]) > 1E-5 then
    begin
      allSame := False;
      Break;
    end;
  Assert.IsFalse(allSame, 'Other particles should be perturbed from X[0]');
end;

{ RangeSeed }

procedure TTestLFPSOPeriodic.Test_RangeSeed_AllWithinBounds;
var
  S: TFitStructure;
  i, j, k: integer;
  v, lo, hi: single;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  S := MakePeriodicStructure;
  FPSO.TestSetStructure(S);
  FPSO.TestRangeSeed;

  for i := 0 to High(FPSO.GetX) do
    for j := 0 to High(FPSO.GetX[i]) do
      for k := 1 to 3 do
      begin
        v := FPSO.GetX[i][j][k][0];
        lo := FPSO.GetXmin[0][j][k][0];
        hi := FPSO.GetXmax[0][j][k][0];
        Assert.IsTrue((v >= lo - 1E-3) and (v <= hi + 1E-3),
          Format('X[%d][%d][%d] = %g not in [%g..%g]', [i, j, k, v, lo, hi]));
      end;
end;

end.
