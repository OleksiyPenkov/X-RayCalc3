unit TestLFPSOIrregular;

interface

uses
  DUnitX.TestFramework,
  unit_Types,
  unit_materials,
  unit_LFPSO_Base,
  unit_LFPSO_Irregular;

type
  TTestableIrregular = class(TLFPSO_Irregular)
  public
    property Pub_FStructure: TFitStructure read FStructure write FStructure;
    property Pub_FLayersCount: integer read FLayersCount write FLayersCount;
    property Pub_FPopulation: integer read FPopulation write FPopulation;
    property Pub_FFitParams: TFitParams read FFitParams write FFitParams;
    property Pub_FReInit: Boolean read FReInit write FReInit;

    function GetX: TPopulation;
    function GetV: TPopulation;
    function GetXmax: TPopulation;
    function GetXmin: TPopulation;
    function GetXrange: TPopulation;
    function GetVmax: TPopulation;
    function GetVmin: TPopulation;
    function GetLinks: TIndexes;
    function GetSmoothies: integer;

    procedure TestSetStructure(const Inp: TFitStructure);
    procedure TestInitVelocity;
    procedure TestXSeed;
    procedure TestRangeSeed;
    procedure TestSetParams(const Value: TFitParams);
  end;

  [TestFixture]
  TTestLFPSOIrregular = class
  private
    FPSO: TTestableIrregular;
    function MakeParams(ASmooth: Boolean = False): TFitParams;
    function MakeIrregularStructure_Simple: TFitStructure;
    function MakeIrregularStructure_Paired: TFitStructure;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { SetStructure — flattening }
    [Test] procedure Test_SetStructure_FlattenedLayerCount;
    [Test] procedure Test_SetStructure_InitializesX0;
    [Test] procedure Test_SetStructure_LinksAllMinusOne_NoPairing;

    { SetStructure — paired layers }
    [Test] procedure Test_SetStructure_Paired_LinksPointToFirst;
    [Test] procedure Test_SetStructure_Paired_FirstLayerUnlinked;

    { SetStructure — smoothies }
    [Test] procedure Test_SetStructure_Smooth_CreatesSmoothies;
    [Test] procedure Test_SetStructure_NoSmooth_NoSmoothies;

    { InitVelocity }
    [Test] procedure Test_InitVelocity_LinkedLayerVelocityZero;
    [Test] procedure Test_InitVelocity_UnlinkedLayerVelocityNonZero;

    { XSeed }
    [Test] procedure Test_XSeed_X0Unchanged;

    { RangeSeed }
    [Test] procedure Test_RangeSeed_LinkedLayersCopied;
    [Test] procedure Test_RangeSeed_UnlinkedWithinBounds;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TTestableIrregular }

function TTestableIrregular.GetX: TPopulation; begin Result := X; end;
function TTestableIrregular.GetV: TPopulation; begin Result := V; end;
function TTestableIrregular.GetXmax: TPopulation; begin Result := Xmax; end;
function TTestableIrregular.GetXmin: TPopulation; begin Result := Xmin; end;
function TTestableIrregular.GetXrange: TPopulation; begin Result := Xrange; end;
function TTestableIrregular.GetVmax: TPopulation; begin Result := Vmax; end;
function TTestableIrregular.GetVmin: TPopulation; begin Result := Vmin; end;
function TTestableIrregular.GetLinks: TIndexes; begin Result := FLinks; end;
function TTestableIrregular.GetSmoothies: integer; begin Result := Length(FSmoothies); end;

procedure TTestableIrregular.TestSetStructure(const Inp: TFitStructure);
begin SetStructure(Inp); end;

procedure TTestableIrregular.TestInitVelocity;
begin InitVelocity; end;

procedure TTestableIrregular.TestXSeed;
begin XSeed; end;

procedure TTestableIrregular.TestRangeSeed;
begin RangeSeed; end;

procedure TTestableIrregular.TestSetParams(const Value: TFitParams);
begin SetParams(Value); end;

{ TTestLFPSOIrregular — helpers }

function TTestLFPSOIrregular.MakeParams(ASmooth: Boolean): TFitParams;
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
  Result.Smooth := ASmooth;
  Result.SmoothWindow := 3;
end;

function TTestLFPSOIrregular.MakeIrregularStructure_Simple: TFitStructure;
var
  p: integer;
begin
  // 1 stack with N=2 repeats, 2 layers — no pairing
  // TotalNP = 2 * 2 = 4 flattened layers
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 2;
  SetLength(Result.Stacks[0].Layers, 2);

  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID := 0;
  Result.Stacks[0].Layers[0].LayerID := 0;
  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[0].P[p].V := 10.0 * p;
    Result.Stacks[0].Layers[0].P[p].min := 1.0;
    Result.Stacks[0].Layers[0].P[p].max := 100.0;
    Result.Stacks[0].Layers[0].P[p].Paired := False;
  end;

  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID := 0;
  Result.Stacks[0].Layers[1].LayerID := 1;
  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[1].P[p].V := 5.0 * p;
    Result.Stacks[0].Layers[1].P[p].min := 1.0;
    Result.Stacks[0].Layers[1].P[p].max := 50.0;
    Result.Stacks[0].Layers[1].P[p].Paired := False;
  end;

  Result.Subs.Material := 'Si';
  for p := 1 to 3 do
    Result.Subs.P[p].V := 5.0;
end;

function TTestLFPSOIrregular.MakeIrregularStructure_Paired: TFitStructure;
var
  p: integer;
begin
  // 1 stack with N=2, 2 layers — H (P[1]) is paired, s and rho are not
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 2;
  SetLength(Result.Stacks[0].Layers, 2);

  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID := 0;
  Result.Stacks[0].Layers[0].LayerID := 0;
  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[0].P[p].V := 10.0 * p;
    Result.Stacks[0].Layers[0].P[p].min := 1.0;
    Result.Stacks[0].Layers[0].P[p].max := 100.0;
  end;
  Result.Stacks[0].Layers[0].P[1].Paired := True;   // H paired
  Result.Stacks[0].Layers[0].P[2].Paired := False;
  Result.Stacks[0].Layers[0].P[3].Paired := False;

  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID := 0;
  Result.Stacks[0].Layers[1].LayerID := 1;
  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[1].P[p].V := 5.0 * p;
    Result.Stacks[0].Layers[1].P[p].min := 1.0;
    Result.Stacks[0].Layers[1].P[p].max := 50.0;
    Result.Stacks[0].Layers[1].P[p].Paired := False;
  end;

  Result.Subs.Material := 'Si';
  for p := 1 to 3 do
    Result.Subs.P[p].V := 5.0;
end;

{ Setup / TearDown }

procedure TTestLFPSOIrregular.Setup;
begin
  FPSO := TTestableIrregular.Create;
end;

procedure TTestLFPSOIrregular.TearDown;
begin
  FPSO.Free;
end;

{ SetStructure — flattening }

procedure TTestLFPSOIrregular.Test_SetStructure_FlattenedLayerCount;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  // 2 layers * N=2 = 4 flattened layers
  Assert.AreEqual(4, FPSO.Pub_FLayersCount, 'FLayersCount = TotalNP = 4');
  Assert.AreEqual(4, Length(FPSO.Pub_FStructure.Stacks[0].Layers),
    'Flattened structure has 4 layers');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_InitializesX0;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  // Flattened: [Si, Mo, Si, Mo] — layer 0 H=10, layer 1 H=5
  Assert.AreEqual(Single(10.0), FPSO.GetX[0][0][1][0], 1E-5, 'Flat[0] H=10');
  Assert.AreEqual(Single(5.0),  FPSO.GetX[0][1][1][0], 1E-5, 'Flat[1] H=5');
  Assert.AreEqual(Single(10.0), FPSO.GetX[0][2][1][0], 1E-5, 'Flat[2] H=10 (repeat)');
  Assert.AreEqual(Single(5.0),  FPSO.GetX[0][3][1][0], 1E-5, 'Flat[3] H=5 (repeat)');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_LinksAllMinusOne_NoPairing;
var
  j, k: integer;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  // No pairing -> all links = -1 for first period, but second period links back
  // First period (layers 0,1): all -1
  for j := 0 to 1 do
    for k := 1 to 3 do
      Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[j][k],
        Format('Links[%d][%d] = -1 (first period, no pairing)', [j, k]));
end;

{ SetStructure — paired layers }

procedure TTestLFPSOIrregular.Test_SetStructure_Paired_LinksPointToFirst;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  // Layer 0 has P[1].Paired=True
  // Flattened: [0:Si, 1:Mo, 2:Si, 3:Mo]
  // Layer 2 (second Si) should link H back to layer 0
  Assert.AreEqual(SmallInt(0), FPSO.GetLinks[2][1],
    'Layer 2 H linked to layer 0');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_Paired_FirstLayerUnlinked;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  // First period layers have all links = -1
  Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[0][1],
    'Layer 0 H not linked (first in period)');
  Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[0][2],
    'Layer 0 s not linked');
  Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[0][3],
    'Layer 0 rho not linked');
end;

{ SetStructure — smoothies }

procedure TTestLFPSOIrregular.Test_SetStructure_Smooth_CreatesSmoothies;
begin
  FPSO.TestSetParams(MakeParams(True));  // Smooth = True
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  // No paired params, N>1, Smooth=True -> should create smoothies
  // 2 layers * 3 params = 6 smoothie entries
  Assert.IsTrue(FPSO.GetSmoothies > 0, 'Smoothies created when Smooth=True');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_NoSmooth_NoSmoothies;
begin
  FPSO.TestSetParams(MakeParams(False));  // Smooth = False
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  Assert.AreEqual(0, FPSO.GetSmoothies, 'No smoothies when Smooth=False');
end;

{ InitVelocity }

procedure TTestLFPSOIrregular.Test_InitVelocity_LinkedLayerVelocityZero;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  FPSO.TestInitVelocity;
  // Layer 2, param 1 (H) is linked -> velocity must be 0
  Assert.AreEqual(Single(0.0), FPSO.GetV[1][2][1][0], 1E-5,
    'Linked layer H velocity = 0');
end;

procedure TTestLFPSOIrregular.Test_InitVelocity_UnlinkedLayerVelocityNonZero;
var
  i: integer;
  anyNonZero: Boolean;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  FPSO.TestInitVelocity;
  // Layer 0, param 2 (s) is unlinked -> should have non-zero velocity
  anyNonZero := False;
  for i := 0 to High(FPSO.GetV) do
    if Abs(FPSO.GetV[i][0][2][0]) > 1E-6 then
    begin
      anyNonZero := True;
      Break;
    end;
  Assert.IsTrue(anyNonZero, 'Unlinked layer s should have non-zero velocity');
end;

{ XSeed }

procedure TTestLFPSOIrregular.Test_XSeed_X0Unchanged;
var
  H0_before: single;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);

  H0_before := FPSO.GetX[0][0][1][0];
  FPSO.TestXSeed;
  Assert.AreEqual(H0_before, FPSO.GetX[0][0][1][0], 1E-5,
    'X[0] should remain unchanged');
end;

{ RangeSeed }

procedure TTestLFPSOIrregular.Test_RangeSeed_LinkedLayersCopied;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  FPSO.TestRangeSeed;
  // Layer 2 H is linked to layer 0 -> should be equal for each particle
  Assert.AreEqual(FPSO.GetX[1][0][1][0], FPSO.GetX[1][2][1][0], 1E-5,
    'Linked H: layer 2 copies layer 0 for particle 1');
  Assert.AreEqual(FPSO.GetX[2][0][1][0], FPSO.GetX[2][2][1][0], 1E-5,
    'Linked H: layer 2 copies layer 0 for particle 2');
end;

procedure TTestLFPSOIrregular.Test_RangeSeed_UnlinkedWithinBounds;
var
  i, j, k: integer;
  v, lo, hi: single;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  FPSO.TestRangeSeed;

  for i := 1 to High(FPSO.GetX) do
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
