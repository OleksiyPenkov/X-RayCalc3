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

    [Test] procedure Test_SetStructure_FlattenedLayerCount;
    [Test] procedure Test_SetStructure_InitializesX0;
    [Test] procedure Test_SetStructure_LinksAllMinusOne_NoPairing;

    [Test] procedure Test_SetStructure_Paired_LinksPointToFirst;
    [Test] procedure Test_SetStructure_Paired_FirstLayerUnlinked;

    [Test] procedure Test_SetStructure_Smooth_CreatesSmoothies;
    [Test] procedure Test_SetStructure_NoSmooth_NoSmoothies;

    [Test] procedure Test_InitVelocity_LinkedLayerVelocityZero;
    [Test] procedure Test_InitVelocity_UnlinkedLayerVelocityNonZero;

    [Test] procedure Test_XSeed_X0Unchanged;
    [Test] procedure Test_XSeed_LinkedLayersCopied;

    [Test] procedure Test_ReInit_KeepsTheLinks;

    [Test] procedure Test_Smooth_EveryParameterPaired_DoesNothing;
    [Test] procedure Test_Smooth_SkipsHeldParameters;
    [Test] procedure Test_SetStructure_EmptyStack_IsSkipped;

    [Test] procedure Test_StartFromTables_EachPeriodFromItsTable;
    [Test] procedure Test_StartFromTables_Off_IgnoresTheTables;
    [Test] procedure Test_StartFromTables_SurviveAShake;

    [Test] procedure Test_RangeSeed_LinkedLayersCopied;
    [Test] procedure Test_RangeSeed_UnlinkedWithinBounds;

    [Test] procedure Test_FrozenParam_HasEmptyDomain;
  end;

implementation

uses
  System.SysUtils, System.Math;


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
  Result.Stacks[0].Layers[0].P[1].Paired := True;
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


procedure TTestLFPSOIrregular.Setup;
begin
  FPSO := TTestableIrregular.Create;
end;

procedure TTestLFPSOIrregular.TearDown;
begin
  FPSO.Free;
end;


procedure TTestLFPSOIrregular.Test_SetStructure_FlattenedLayerCount;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  Assert.AreEqual(4, FPSO.Pub_FLayersCount, 'FLayersCount = TotalNP = 4');
  Assert.AreEqual(4, Length(FPSO.Pub_FStructure.Stacks[0].Layers),
    'Flattened structure has 4 layers');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_InitializesX0;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
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
  for j := 0 to 1 do
    for k := 1 to 3 do
      Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[j][k],
        Format('Links[%d][%d] = -1 (first period, no pairing)', [j, k]));
end;


procedure TTestLFPSOIrregular.Test_SetStructure_Paired_LinksPointToFirst;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  Assert.AreEqual(SmallInt(0), FPSO.GetLinks[2][1],
    'Layer 2 H linked to layer 0');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_Paired_FirstLayerUnlinked;
begin
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[0][1],
    'Layer 0 H not linked (first in period)');
  Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[0][2],
    'Layer 0 s not linked');
  Assert.AreEqual(SmallInt(-1), FPSO.GetLinks[0][3],
    'Layer 0 rho not linked');
end;


procedure TTestLFPSOIrregular.Test_SetStructure_Smooth_CreatesSmoothies;
begin
  FPSO.TestSetParams(MakeParams(True));
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  Assert.IsTrue(FPSO.GetSmoothies > 0, 'Smoothies created when Smooth=True');
end;

procedure TTestLFPSOIrregular.Test_SetStructure_NoSmooth_NoSmoothies;
begin
  FPSO.TestSetParams(MakeParams(False));
  FPSO.TestSetStructure(MakeIrregularStructure_Simple);
  Assert.AreEqual(0, FPSO.GetSmoothies, 'No smoothies when Smooth=False');
end;


procedure TTestLFPSOIrregular.Test_InitVelocity_LinkedLayerVelocityZero;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  FPSO.TestInitVelocity;
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
  anyNonZero := False;
  for i := 0 to High(FPSO.GetV) do
    if Abs(FPSO.GetV[i][0][2][0]) > 1E-6 then
    begin
      anyNonZero := True;
      Break;
    end;
  Assert.IsTrue(anyNonZero, 'Unlinked layer s should have non-zero velocity');
end;


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

{ Shake hands SetStructure the engine's own flattened structure with FReInit
  set. That structure is one stack of N = 1, so the pairing cannot be read off
  it again: the links built on the first call must survive. }
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
  L0.AddProfilePoint(12, 1); L0.AddProfilePoint(18, 1);
  L0.AddProfilePoint(200, 2); L0.AddProfilePoint(30, 2);
  L0.AddProfilePoint(4, 3); L0.AddProfilePoint(4.5, 3);
  L1 := Default(TLayerData);
  L1.Material := 'Mo';
  L1.LayerID := 1;
  L1.P[1].V := 5; L1.P[1].min := 5; L1.P[1].max := 5;
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


procedure TTestLFPSOIrregular.Test_RangeSeed_LinkedLayersCopied;
begin
  RandSeed := 42;
  FPSO.TestSetParams(MakeParams);
  FPSO.TestSetStructure(MakeIrregularStructure_Paired);
  FPSO.TestRangeSeed;
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
