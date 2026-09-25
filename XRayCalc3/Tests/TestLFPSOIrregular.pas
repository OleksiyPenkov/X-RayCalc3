unit TestLFPSOIrregular;

interface

uses
  DUnitX.TestFramework,
  unit_Types,
  unit_materials,
  unit_LFPSO_Base,
  unit_LFPSO_Irregular,
  unit_SmartLimits;

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

    function TestXMin(const LIndex, PIndex: Integer): Single;
    function TestXMax(const LIndex, PIndex: Integer): Single;
    function TestXRange(const LIndex, PIndex: Integer): Single;
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
    [Test] procedure Test_XSeed_LinkedLayersCopied;

    { Re-initialisation (Shake) }
    [Test] procedure Test_ReInit_KeepsTheLinks;

    { Smooth with nothing to smooth }
    [Test] procedure Test_Smooth_EveryParameterPaired_DoesNothing;
    [Test] procedure Test_Smooth_SkipsHeldParameters;
    [Test] procedure Test_SetStructure_EmptyStack_IsSkipped;

    { StartFromTables: the GUI's Resume and fit_xrr's start_profiles }
    [Test] procedure Test_StartFromTables_EachPeriodFromItsTable;
    [Test] procedure Test_StartFromTables_Off_IgnoresTheTables;
    [Test] procedure Test_StartFromTables_SurviveAShake;

    { RangeSeed }
    [Test] procedure Test_RangeSeed_LinkedLayersCopied;
    [Test] procedure Test_RangeSeed_UnlinkedWithinBounds;

    { Fixed parameters - Task 2: CollapseFixed pins an empty range }
    [Test] procedure Test_FrozenParam_HasEmptyDomain;
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

function TTestableIrregular.TestXMin(const LIndex, PIndex: Integer): Single;
begin
  Result := Xmin[0][LIndex][PIndex][0];
end;

function TTestableIrregular.TestXMax(const LIndex, PIndex: Integer): Single;
begin
  Result := Xmax[0][LIndex][PIndex][0];
end;

function TTestableIrregular.TestXRange(const LIndex, PIndex: Integer): Single;
begin
  Result := Xrange[0][LIndex][PIndex][0];
end;

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

{ A paired parameter is one value in every period, from the first evaluation
  on: XSeed is what seeds the swarm after every shake (and at the start when
  range_seed is off), and a particle scored with its paired values apart could
  become the global best and be reported as the fit. }
procedure TTestLFPSOIrregular.Test_XSeed_LinkedLayersCopied;
var
  i: integer;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  FPSO.TestXSeed;
  for i := 1 to High(FPSO.GetX) do
    Assert.AreEqual(FPSO.GetX[i][0][1][0], FPSO.GetX[i][2][1][0], 0.0,
      Format('Linked H: layer 2 copies layer 0 for particle %d', [i]));
end;

{ Re-initialisation

  Shake hands SetStructure the engine's own flattened structure with FReInit
  set. That structure is one stack of N = 1, so the pairing cannot be read off
  it again: the links built on the first call must survive. They used to be
  zeroed, which linked every parameter of every layer to layer 0 - after the
  first shake no parameter moved but by being copied from layer 0 and clamped
  to its own bounds. }
procedure TTestLFPSOIrregular.Test_ReInit_KeepsTheLinks;
var
  Before: TIndexes;
  Flat: TFitStructure;
  j, k: integer;
begin
  FPSO.TestSetParams(MakeParams(True));
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  Before := Copy(FPSO.GetLinks);
  FPSO.Pub_FStructure.CopyContent(Flat);
  FPSO.Pub_FReInit := True;
  FPSO.TestSetStructure(Flat);

  Assert.AreEqual(Length(Before), Length(FPSO.GetLinks), 'one link row per layer');
  for j := 0 to High(Before) do
    for k := 1 to 3 do
      Assert.AreEqual(Before[j][k], FPSO.GetLinks[j][k],
        Format('Links[%d][%d] survives the re-initialisation', [j, k]));
  Assert.IsTrue(FPSO.GetSmoothies > 0, 'and so do the smoothing groups');
end;

{ Smooth on with every parameter paired leaves no smoothing group. The loops
  over the groups counted in Word, so an empty list ran from 0 to 65535 and
  the fit died of an access violation in SetStructure or in the first XSeed. }
procedure TTestLFPSOIrregular.Test_Smooth_EveryParameterPaired_DoesNothing;
var
  Inp: TFitStructure;
  j, p: integer;
begin
  RandSeed := 42;
  Inp := MakeIrregularStructure_Paired;
  for j := 0 to High(Inp.Stacks[0].Layers) do
    for p := 1 to 3 do
      Inp.Stacks[0].Layers[j].P[p].Paired := True;

  FPSO.TestSetParams(MakeParams(True));
  FPSO.TestSetStructure(Inp);
  Assert.AreEqual(0, FPSO.GetSmoothies, 'nothing unpaired, nothing to smooth');
  FPSO.TestXSeed;
  Assert.AreEqual(FPSO.GetX[1][0][2][0], FPSO.GetX[1][2][2][0], 0.0,
    'and the pairing still holds after the seed');
end;

{ A held parameter has an empty range and keeps the value it was given in each
  period; averaging it over the periods would move it off that value. }
procedure TTestLFPSOIrregular.Test_Smooth_SkipsHeldParameters;
var
  Inp: TFitStructure;
begin
  Inp := MakeIrregularStructure_Simple;
  Inp.Stacks[0].Layers[0].P[1].min := Inp.Stacks[0].Layers[0].P[1].V;
  Inp.Stacks[0].Layers[0].P[1].max := Inp.Stacks[0].Layers[0].P[1].V;
  FPSO.TestSetParams(MakeParams(True));
  FPSO.TestSetStructure(Inp);
  Assert.AreEqual(5, FPSO.GetSmoothies,
    'two layers times three parameters, less the held thickness');
end;

{ A stack without layers next to a real one: the layer loop counted in Word
  and ran from 0 to 65535 over it, writing past the flattened structure. }
procedure TTestLFPSOIrregular.Test_SetStructure_EmptyStack_IsSkipped;
var
  Inp: TFitStructure;
begin
  Inp := MakeIrregularStructure_Simple;
  SetLength(Inp.Stacks, 2);
  Inp.Stacks[1].N := 3;
  SetLength(Inp.Stacks[1].Layers, 0);
  FPSO.TestSetParams(MakeParams(True));
  FPSO.TestSetStructure(Inp);
  Assert.AreEqual(4, FPSO.Pub_FLayersCount, 'only the real stack''s layers');
  Assert.AreEqual(4, Integer(Length(FPSO.Pub_FStructure.Stacks[0].Layers)));
end;

{ Flattened order: [0 Si p1, 1 Mo p1, 2 Si p2, 3 Mo p2]. Each period starts
  from its entry of the table; a held parameter is pinned to its own period's
  value; a start outside the bounds is clamped into them; a paired parameter
  keeps one value whatever its (stale) table says. }
function TableStructure: TFitStructure;
var
  L0, L1: TLayerData;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 2;
  SetLength(Result.Stacks[0].Layers, 2);
  L0 := Default(TLayerData);
  L0.Material := 'Si';
  L0.LayerID := 0;
  L0.P[1].V := 10; L0.P[1].min := 1; L0.P[1].max := 100;
  L0.P[2].V := 3;  L0.P[2].min := 1; L0.P[2].max := 100;
  L0.P[3].V := 2;  L0.P[3].min := 1; L0.P[3].max := 5;
  L0.P[3].Paired := True;
  L0.AddProfilePoint(12, 1); L0.AddProfilePoint(18, 1);    // free thickness
  L0.AddProfilePoint(200, 2); L0.AddProfilePoint(30, 2);   // sigma: 200 is out of range
  L0.AddProfilePoint(4, 3); L0.AddProfilePoint(4.5, 3);    // paired density: ignored
  L1 := Default(TLayerData);
  L1.Material := 'Mo';
  L1.LayerID := 1;
  L1.P[1].V := 5; L1.P[1].min := 5; L1.P[1].max := 5;      // held thickness
  L1.P[2].V := 3; L1.P[2].min := 1; L1.P[2].max := 50;
  L1.P[3].V := 10; L1.P[3].min := 1; L1.P[3].max := 50;
  L1.AddProfilePoint(5, 1); L1.AddProfilePoint(7, 1);
  Result.Stacks[0].Layers[0] := L0;
  Result.Stacks[0].Layers[1] := L1;
  Result.Subs.Material := 'Si';
end;

procedure TTestLFPSOIrregular.Test_StartFromTables_EachPeriodFromItsTable;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.StartFromTables := True;
  FPSO.TestSetStructure(TableStructure);

  Assert.AreEqual(Single(12), FPSO.GetX[0][0][1][0], 1E-5, 'Si thickness, period 1');
  Assert.AreEqual(Single(18), FPSO.GetX[0][2][1][0], 1E-5, 'Si thickness, period 2');
  Assert.AreEqual(Single(1), FPSO.TestXMin(2, 1), 1E-5, 'free: the layer''s bounds');
  Assert.AreEqual(Single(100), FPSO.TestXMax(2, 1), 1E-5);

  Assert.AreEqual(Single(100), FPSO.GetX[0][0][2][0], 1E-5, 'sigma 200 clamped to its max');
  Assert.AreEqual(Single(30), FPSO.GetX[0][2][2][0], 1E-5);

  Assert.AreEqual(Single(2), FPSO.GetX[0][0][3][0], 1E-5, 'paired: the single value');
  Assert.AreEqual(Single(2), FPSO.GetX[0][2][3][0], 1E-5, 'in every period');

  Assert.AreEqual(Single(5), FPSO.GetX[0][1][1][0], 1E-5, 'held, period 1');
  Assert.AreEqual(Single(7), FPSO.GetX[0][3][1][0], 1E-5, 'held, period 2');
  Assert.AreEqual(Single(7), FPSO.TestXMin(3, 1), 1E-5, 'pinned to its own value');
  Assert.AreEqual(Single(7), FPSO.TestXMax(3, 1), 1E-5);
  Assert.AreEqual(Single(7), FPSO.Pub_FStructure.Stacks[0].Layers[3].P[1].V, 1E-5,
    'and in the flattened structure a shake re-seeds from');
  Assert.AreEqual(1, FPSO.ClampedStarts, 'the one sigma outside its limits is counted');
end;

{ A shake hands SetStructure the flattened structure with FReInit set: the
  pinned periods and their pinned bounds must come through unchanged. }
procedure TTestLFPSOIrregular.Test_StartFromTables_SurviveAShake;
var
  Flat: TFitStructure;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.StartFromTables := True;
  FPSO.TestSetStructure(TableStructure);
  FPSO.Pub_FStructure.CopyContent(Flat);
  FPSO.Pub_FReInit := True;
  FPSO.TestSetStructure(Flat);

  Assert.AreEqual(Single(18), FPSO.GetX[0][2][1][0], 1E-5, 'Si thickness, period 2');
  Assert.AreEqual(Single(7), FPSO.GetX[0][3][1][0], 1E-5, 'held, period 2');
  Assert.AreEqual(Single(7), FPSO.TestXMin(3, 1), 1E-5, 'still pinned');
  Assert.AreEqual(Single(7), FPSO.TestXMax(3, 1), 1E-5);
end;

procedure TTestLFPSOIrregular.Test_StartFromTables_Off_IgnoresTheTables;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(TableStructure);
  Assert.AreEqual(Single(10), FPSO.GetX[0][0][1][0], 1E-5);
  Assert.AreEqual(Single(10), FPSO.GetX[0][2][1][0], 1E-5, 'every period from the single value');
  Assert.AreEqual(Single(5), FPSO.GetX[0][3][1][0], 1E-5);
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

{ Fixed parameters - Task 2 }

procedure TTestLFPSOIrregular.Test_FrozenParam_HasEmptyDomain;
var
  Inp: TFitStructure;
begin
  Inp := MakeIrregularStructure_Simple;
  Inp.Stacks[0].Layers[0].P[1].V := 13.0;
  Inp.Stacks[0].Layers[0].P[1].min := 10.0;
  Inp.Stacks[0].Layers[0].P[1].max := 16.0;
  Inp.Stacks[0].Layers[0].P[1].Fixed := True;

  CollapseFixed(Inp);
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(Inp);

  Assert.AreEqual(Single(13.0), FPSO.TestXMin(0, 1), 1E-6, 'lower bound pinned to V');
  Assert.AreEqual(Single(13.0), FPSO.TestXMax(0, 1), 1E-6, 'upper bound pinned to V');
  Assert.AreEqual(Single(0.0), FPSO.TestXRange(0, 1), 1E-6, 'empty range');
end;

end.
