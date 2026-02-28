unit TestLFPSOBase;

interface

uses
  DUnitX.TestFramework,
  unit_Types,
  unit_materials,
  unit_LFPSO_Base;

type
  TTestableLFPSO = class(TLFPSO_BASE)
  public
    // Expose protected fields
    property Pub_FFitParams: TFitParams read FFitParams write FFitParams;
    property Pub_FStructure: TFitStructure read FStructure write FStructure;
    property Pub_FLayersCount: integer read FLayersCount write FLayersCount;
    property Pub_FPopulation: integer read FPopulation write FPopulation;
    property Pub_FTMax: integer read FTMax write FTMax;
    property Pub_FTerminated: Boolean read FTerminated write FTerminated;
    property Pub_CFactor: single read CFactor write CFactor;
    property Pub_FGlobalBestChiSqr: single read FGlobalBestChiSqr write FGlobalBestChiSqr;
    property Pub_FAbsoluteBestChiSqr: single read FAbsoluteBestChiSqr write FAbsoluteBestChiSqr;

    // Expose protected arrays
    function GetX: TPopulation;
    procedure SetX(const Value: TPopulation);
    function GetV: TPopulation;
    procedure SetV(const Value: TPopulation);
    function GetXmax: TPopulation;
    procedure SetXmax(const Value: TPopulation);
    function GetXmin: TPopulation;
    procedure SetXmin(const Value: TPopulation);
    function GetXrange: TPopulation;
    function GetVmax: TPopulation;
    procedure SetVmax(const Value: TPopulation);
    function GetVmin: TPopulation;
    procedure SetVmin(const Value: TPopulation);

    // Expose protected methods
    function TestOmega(const t, TMax: integer): single;
    function TestRand(const dx: single): single;
    function TestLevyWalk(const X, gBest: single): single;
    procedure TestCheckLimits(const i, j, k: integer);
    procedure TestSetParams(const Value: TFitParams);
    procedure TestSetDomain(const Count, Order: integer; var Pop: TPopulation);
    procedure TestInit_Domains(const Order: integer);
    procedure TestSet_Init_X(const LIndex, PIndex: integer; Val: TFitValue);
    procedure TestApplyCFactor(var c1, c2: single);
    procedure TestUpdateStructure(var Solution: TSolution);
    function TestFitModelToLayer(const Solution: TSolution): TLayeredModel;
  end;

  [TestFixture]
  TTestLFPSOFreeFunctions = class
  public
    [Test] procedure Test_Gamma_OfOne;
    [Test] procedure Test_Gamma_OfTwo;
    [Test] procedure Test_Gamma_OfHalf;
    [Test] procedure Test_Gamma_OfFive;

    [Test] procedure Test_MultiplyVector_ScaleByTwo;
    [Test] procedure Test_MultiplyVector_ScaleByZero;

    [Test] procedure Test_RS_ReturnsOnlyPlusOrMinusOne;

    [Test] procedure Test_SolutionToString_SingleLayer;
    [Test] procedure Test_SolutionToString_Empty;
  end;

  [TestFixture]
  TTestLFPSOBase = class
  private
    FPSO: TTestableLFPSO;
    function MakeSimpleFitParams: TFitParams;
    function MakeSimpleStructure(LayerCount: integer): TFitStructure;
    function MakeSimpleSolution(LayerCount: integer): TSolution;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { Omega — inertia weight }
    [Test] procedure Test_Omega_AtStart;
    [Test] procedure Test_Omega_AtEnd;
    [Test] procedure Test_Omega_AtMidpoint;

    { SetParams }
    [Test] procedure Test_SetParams_SetsFields;
    [Test] procedure Test_SetParams_AllocatesBoundaryArrays;

    { SetDomain }
    [Test] procedure Test_SetDomain_AllocatesCorrectDimensions;

    { Init_Domains }
    [Test] procedure Test_Init_Domains_AllocatesAllArrays;

    { Set_Init_X }
    [Test] procedure Test_Set_Init_X_SetsValues;

    { CheckLimits — velocity and position clamping }
    [Test] procedure Test_CheckLimits_ClampsVelocityHigh;
    [Test] procedure Test_CheckLimits_ClampsVelocityLow;
    [Test] procedure Test_CheckLimits_ClampsPositionHigh;
    [Test] procedure Test_CheckLimits_ClampsPositionLow;
    [Test] procedure Test_CheckLimits_NoClampNeeded;

    { ApplyCFactor }
    [Test] procedure Test_ApplyCFactor_AdaptVelTrue_Positive;
    [Test] procedure Test_ApplyCFactor_AdaptVelFalse;
    [Test] procedure Test_ApplyCFactor_AdaptVelTrue_ZeroCFactor;

    { Rand }
    [Test] procedure Test_Rand_StaysInRange;

    { LevyWalk }
    [Test] procedure Test_LevyWalk_ReturnsFinite;

    { UpdateStructure }
    [Test] procedure Test_UpdateStructure_WritesBackValues;

    { FitModelToLayer }
    [Test] procedure Test_FitModelToLayer_CreatesCorrectLayers;

    { Terminate }
    [Test] procedure Test_Terminate_SetsFlag;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TTestableLFPSO — accessor wrappers }

function TTestableLFPSO.GetX: TPopulation; begin Result := X; end;
procedure TTestableLFPSO.SetX(const Value: TPopulation); begin X := Value; end;
function TTestableLFPSO.GetV: TPopulation; begin Result := V; end;
procedure TTestableLFPSO.SetV(const Value: TPopulation); begin V := Value; end;
function TTestableLFPSO.GetXmax: TPopulation; begin Result := Xmax; end;
procedure TTestableLFPSO.SetXmax(const Value: TPopulation); begin Xmax := Value; end;
function TTestableLFPSO.GetXmin: TPopulation; begin Result := Xmin; end;
procedure TTestableLFPSO.SetXmin(const Value: TPopulation); begin Xmin := Value; end;
function TTestableLFPSO.GetXrange: TPopulation; begin Result := Xrange; end;
function TTestableLFPSO.GetVmax: TPopulation; begin Result := Vmax; end;
procedure TTestableLFPSO.SetVmax(const Value: TPopulation); begin Vmax := Value; end;
function TTestableLFPSO.GetVmin: TPopulation; begin Result := Vmin; end;
procedure TTestableLFPSO.SetVmin(const Value: TPopulation); begin Vmin := Value; end;

function TTestableLFPSO.TestOmega(const t, TMax: integer): single;
begin Result := Omega(t, TMax); end;

function TTestableLFPSO.TestRand(const dx: single): single;
begin Result := Rand(dx); end;

function TTestableLFPSO.TestLevyWalk(const X, gBest: single): single;
begin Result := LevyWalk(X, gBest); end;

procedure TTestableLFPSO.TestCheckLimits(const i, j, k: integer);
begin CheckLimits(i, j, k); end;

procedure TTestableLFPSO.TestSetParams(const Value: TFitParams);
begin SetParams(Value); end;

procedure TTestableLFPSO.TestSetDomain(const Count, Order: integer; var Pop: TPopulation);
begin SetDomain(Count, Order, Pop); end;

procedure TTestableLFPSO.TestInit_Domains(const Order: integer);
begin Init_Domains(Order); end;

procedure TTestableLFPSO.TestSet_Init_X(const LIndex, PIndex: integer; Val: TFitValue);
begin Set_Init_X(LIndex, PIndex, Val); end;

procedure TTestableLFPSO.TestApplyCFactor(var c1, c2: single);
begin ApplyCFactor(c1, c2); end;

procedure TTestableLFPSO.TestUpdateStructure(var Solution: TSolution);
begin UpdateStructure(Solution); end;

function TTestableLFPSO.TestFitModelToLayer(const Solution: TSolution): TLayeredModel;
begin Result := FitModelToLayer(Solution); end;

{ TTestLFPSOFreeFunctions }

procedure TTestLFPSOFreeFunctions.Test_Gamma_OfOne;
begin
  // Gamma(1) = 0! = 1
  Assert.AreEqual(Single(1.0), Gamma(1.0), 1E-3, 'Gamma(1) should be 1');
end;

procedure TTestLFPSOFreeFunctions.Test_Gamma_OfTwo;
begin
  // Gamma(2) = 1! = 1
  Assert.AreEqual(Single(1.0), Gamma(2.0), 1E-3, 'Gamma(2) should be 1');
end;

procedure TTestLFPSOFreeFunctions.Test_Gamma_OfHalf;
begin
  // Gamma(0.5) = sqrt(pi)
  Assert.AreEqual(Single(Sqrt(Pi)), Gamma(0.5), 1E-3, 'Gamma(0.5) should be sqrt(pi)');
end;

procedure TTestLFPSOFreeFunctions.Test_Gamma_OfFive;
begin
  // Gamma(5) = 4! = 24
  Assert.AreEqual(Single(24.0), Gamma(5.0), 1E-2, 'Gamma(5) should be 24');
end;

procedure TTestLFPSOFreeFunctions.Test_MultiplyVector_ScaleByTwo;
var
  Pop, Res: TPopulation;
begin
  // 1 member, 1 layer, param index 1, order 0 (1 element)
  SetLength(Pop, 1);
  SetLength(Pop[0], 1);
  SetLength(Pop[0][0][1], 1);
  SetLength(Pop[0][0][2], 1);
  SetLength(Pop[0][0][3], 1);
  Pop[0][0][1][0] := 3.0;
  Pop[0][0][2][0] := 5.0;
  Pop[0][0][3][0] := 7.0;

  // Allocate result with same shape
  SetLength(Res, 1);
  SetLength(Res[0], 1);
  SetLength(Res[0][0][1], 1);
  SetLength(Res[0][0][2], 1);
  SetLength(Res[0][0][3], 1);

  MultiplyVector(Pop, 2.0, Res);

  Assert.AreEqual(Single(6.0), Res[0][0][1][0], 1E-5, 'H*2');
  Assert.AreEqual(Single(10.0), Res[0][0][2][0], 1E-5, 's*2');
  Assert.AreEqual(Single(14.0), Res[0][0][3][0], 1E-5, 'rho*2');
end;

procedure TTestLFPSOFreeFunctions.Test_MultiplyVector_ScaleByZero;
var
  Pop, Res: TPopulation;
begin
  SetLength(Pop, 1);
  SetLength(Pop[0], 1);
  SetLength(Pop[0][0][1], 1);
  SetLength(Pop[0][0][2], 1);
  SetLength(Pop[0][0][3], 1);
  Pop[0][0][1][0] := 42.0;
  Pop[0][0][2][0] := 99.0;
  Pop[0][0][3][0] := 7.5;

  SetLength(Res, 1);
  SetLength(Res[0], 1);
  SetLength(Res[0][0][1], 1);
  SetLength(Res[0][0][2], 1);
  SetLength(Res[0][0][3], 1);

  MultiplyVector(Pop, 0.0, Res);

  Assert.AreEqual(Single(0.0), Res[0][0][1][0], 1E-5, 'H*0');
  Assert.AreEqual(Single(0.0), Res[0][0][2][0], 1E-5, 's*0');
  Assert.AreEqual(Single(0.0), Res[0][0][3][0], 1E-5, 'rho*0');
end;

procedure TTestLFPSOFreeFunctions.Test_RS_ReturnsOnlyPlusOrMinusOne;
var
  i, v: integer;
begin
  RandSeed := 42;
  for i := 1 to 100 do
  begin
    v := RS;
    Assert.IsTrue((v = 1) or (v = -1), Format('RS returned %d, expected +1 or -1', [v]));
  end;
end;

procedure TTestLFPSOFreeFunctions.Test_SolutionToString_SingleLayer;
var
  Sol: TSolution;
  S: string;
begin
  SetLength(Sol, 1);
  SetLength(Sol[0][1], 1);
  SetLength(Sol[0][2], 1);
  SetLength(Sol[0][3], 1);
  Sol[0][1][0] := 10.0;
  Sol[0][2][0] := 2.5;
  Sol[0][3][0] := 5.0;

  S := SolutionToString(Sol);
  Assert.IsTrue(S.Contains('10.00'), 'Should contain H value');
  Assert.IsTrue(S.Contains('2.50'), 'Should contain sigma value');
  Assert.IsTrue(S.Contains('5.00'), 'Should contain rho value');
end;

procedure TTestLFPSOFreeFunctions.Test_SolutionToString_Empty;
var
  Sol: TSolution;
  S: string;
begin
  SetLength(Sol, 0);
  S := SolutionToString(Sol);
  Assert.AreEqual('', S, 'Empty solution -> empty string');
end;

{ TTestLFPSOBase — helpers }

function TTestLFPSOBase.MakeSimpleFitParams: TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax := 100;
  Result.Pop := 10;
  Result.Tolerance := 0.001;
  Result.Vmax := 0.5;
  Result.JammingMax := 5;
  Result.ReInitMax := 3;
  Result.KChiSqr := 1.5;
  Result.KVmax := 1.2;
  Result.w1 := 0.4;
  Result.w2 := 0.5;
  Result.Shake := True;
  Result.ThetaWeight := 0;
  Result.AdaptVel := False;
  Result.RangeSeed := False;
  Result.Ksxr := 0.1;
end;

function TTestLFPSOBase.MakeSimpleStructure(LayerCount: integer): TFitStructure;
var
  i, p: integer;
begin
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 1;
  SetLength(Result.Stacks[0].Layers, LayerCount);
  for i := 0 to LayerCount - 1 do
  begin
    Result.Stacks[0].Layers[i].Material := 'Si';
    Result.Stacks[0].Layers[i].StackID := 0;
    Result.Stacks[0].Layers[i].LayerID := i;
    for p := 1 to 3 do
    begin
      Result.Stacks[0].Layers[i].P[p].V := 10.0 * p;
      Result.Stacks[0].Layers[i].P[p].min := 1.0;
      Result.Stacks[0].Layers[i].P[p].max := 100.0;
    end;
  end;
  Result.Subs.Material := 'Si';
  for p := 1 to 3 do
    Result.Subs.P[p].V := 5.0;
end;

function TTestLFPSOBase.MakeSimpleSolution(LayerCount: integer): TSolution;
var
  i, k: integer;
begin
  SetLength(Result, LayerCount);
  for i := 0 to LayerCount - 1 do
    for k := 1 to 3 do
    begin
      SetLength(Result[i][k], 1);
      Result[i][k][0] := (i + 1) * k * 1.0;
    end;
end;

{ TTestLFPSOBase — Setup / TearDown }

procedure TTestLFPSOBase.Setup;
begin
  FPSO := TTestableLFPSO.Create;
end;

procedure TTestLFPSOBase.TearDown;
begin
  FPSO.Free;
end;

{ Omega }

procedure TTestLFPSOBase.Test_Omega_AtStart;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  // w1=0.4, w2=0.5
  FPSO.TestSetParams(Params);
  // Omega(0, 100) = w1 + w2 * (1 - 0/100) = 0.4 + 0.5 = 0.9
  Assert.AreEqual(Single(0.9), FPSO.TestOmega(0, 100), 1E-5, 'Omega at t=0');
end;

procedure TTestLFPSOBase.Test_Omega_AtEnd;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  FPSO.TestSetParams(Params);
  // Omega(100, 100) = w1 + w2 * (1 - 1) = 0.4
  Assert.AreEqual(Single(0.4), FPSO.TestOmega(100, 100), 1E-5, 'Omega at t=TMax');
end;

procedure TTestLFPSOBase.Test_Omega_AtMidpoint;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  FPSO.TestSetParams(Params);
  // Omega(50, 100) = 0.4 + 0.5 * 0.5 = 0.65
  Assert.AreEqual(Single(0.65), FPSO.TestOmega(50, 100), 1E-5, 'Omega at midpoint');
end;

{ SetParams }

procedure TTestLFPSOBase.Test_SetParams_SetsFields;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  FPSO.TestSetParams(Params);
  Assert.AreEqual(100, FPSO.Pub_FTMax, 'TMax from NMax');
  Assert.AreEqual(10, FPSO.Pub_FPopulation, 'Population from Pop');
end;

procedure TTestLFPSOBase.Test_SetParams_AllocatesBoundaryArrays;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  FPSO.TestSetParams(Params);
  Assert.AreEqual(1, Length(FPSO.GetXmax), 'Xmax allocated with length 1');
  Assert.AreEqual(1, Length(FPSO.GetXmin), 'Xmin allocated with length 1');
  Assert.AreEqual(1, Length(FPSO.GetVmax), 'Vmax allocated with length 1');
  Assert.AreEqual(1, Length(FPSO.GetVmin), 'Vmin allocated with length 1');
end;

{ SetDomain }

procedure TTestLFPSOBase.Test_SetDomain_AllocatesCorrectDimensions;
var
  Pop: TPopulation;
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 5;
  FPSO.TestSetParams(Params);

  FPSO.TestSetDomain(3, 2, Pop);  // 3 layers, order 2 (3 coefficients)

  Assert.AreEqual(5, Length(Pop), 'Population size = 5');
  Assert.AreEqual(3, Length(Pop[0]), 'Layers per member = 3');
  Assert.AreEqual(3, Length(Pop[0][0][1]), 'H poly order+1 = 3');
  Assert.AreEqual(3, Length(Pop[0][0][2]), 'sigma poly order+1 = 3');
  Assert.AreEqual(3, Length(Pop[0][0][3]), 'rho poly order+1 = 3');
end;

{ Init_Domains }

procedure TTestLFPSOBase.Test_Init_Domains_AllocatesAllArrays;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 3;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 2;

  FPSO.TestInit_Domains(0);  // order 0 -> 1 coefficient

  Assert.AreEqual(3, Length(FPSO.GetX), 'X population = 3');
  Assert.AreEqual(3, Length(FPSO.GetV), 'V population = 3');
  Assert.AreEqual(2, Length(FPSO.GetX[0]), 'X layers = 2');
  Assert.AreEqual(1, Length(FPSO.GetX[0][0][1]), 'X[0][0][1] has 1 element');
end;

{ Set_Init_X }

procedure TTestLFPSOBase.Test_Set_Init_X_SetsValues;
var
  Params: TFitParams;
  FV: TFitValue;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 2;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 1;
  FPSO.TestInit_Domains(0);

  FV.V := 50.0;
  FV.min := 10.0;
  FV.max := 90.0;
  FPSO.TestSet_Init_X(0, 1, FV);

  Assert.AreEqual(Single(50.0), FPSO.GetX[0][0][1][0], 1E-5, 'X value');
  Assert.AreEqual(Single(90.0), FPSO.GetXmax[0][0][1][0], 1E-5, 'Xmax value');
  Assert.AreEqual(Single(10.0), FPSO.GetXmin[0][0][1][0], 1E-5, 'Xmin value');
  Assert.AreEqual(Single(80.0), FPSO.GetXrange[0][0][1][0], 1E-5, 'Xrange = max - min');
end;

{ CheckLimits }

procedure TTestLFPSOBase.Test_CheckLimits_ClampsVelocityHigh;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 2;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 1;
  FPSO.TestInit_Domains(0);

  FPSO.GetX[0][0][1][0] := 50.0;
  FPSO.GetV[0][0][1][0] := 999.0;   // way above Vmax
  FPSO.GetVmax[0][0][1][0] := 10.0;
  FPSO.GetVmin[0][0][1][0] := -10.0;
  FPSO.GetXmax[0][0][1][0] := 100.0;
  FPSO.GetXmin[0][0][1][0] := 0.0;

  FPSO.TestCheckLimits(0, 0, 1);

  Assert.AreEqual(Single(60.0), FPSO.GetX[0][0][1][0], 1E-5,
    'X = 50 + clamped V(10) = 60');
end;

procedure TTestLFPSOBase.Test_CheckLimits_ClampsVelocityLow;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 2;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 1;
  FPSO.TestInit_Domains(0);

  FPSO.GetX[0][0][1][0] := 50.0;
  FPSO.GetV[0][0][1][0] := -999.0;
  FPSO.GetVmax[0][0][1][0] := 10.0;
  FPSO.GetVmin[0][0][1][0] := -10.0;
  FPSO.GetXmax[0][0][1][0] := 100.0;
  FPSO.GetXmin[0][0][1][0] := 0.0;

  FPSO.TestCheckLimits(0, 0, 1);

  Assert.AreEqual(Single(40.0), FPSO.GetX[0][0][1][0], 1E-5,
    'X = 50 + clamped V(-10) = 40');
end;

procedure TTestLFPSOBase.Test_CheckLimits_ClampsPositionHigh;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 2;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 1;
  FPSO.TestInit_Domains(0);

  FPSO.GetX[0][0][1][0] := 95.0;
  FPSO.GetV[0][0][1][0] := 8.0;
  FPSO.GetVmax[0][0][1][0] := 10.0;
  FPSO.GetVmin[0][0][1][0] := -10.0;
  FPSO.GetXmax[0][0][1][0] := 100.0;
  FPSO.GetXmin[0][0][1][0] := 0.0;

  FPSO.TestCheckLimits(0, 0, 1);

  Assert.AreEqual(Single(100.0), FPSO.GetX[0][0][1][0], 1E-5,
    'X clamped to Xmax=100');
end;

procedure TTestLFPSOBase.Test_CheckLimits_ClampsPositionLow;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 2;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 1;
  FPSO.TestInit_Domains(0);

  FPSO.GetX[0][0][1][0] := 3.0;
  FPSO.GetV[0][0][1][0] := -8.0;
  FPSO.GetVmax[0][0][1][0] := 10.0;
  FPSO.GetVmin[0][0][1][0] := -10.0;
  FPSO.GetXmax[0][0][1][0] := 100.0;
  FPSO.GetXmin[0][0][1][0] := 0.0;

  FPSO.TestCheckLimits(0, 0, 1);

  Assert.AreEqual(Single(0.0), FPSO.GetX[0][0][1][0], 1E-5,
    'X clamped to Xmin=0');
end;

procedure TTestLFPSOBase.Test_CheckLimits_NoClampNeeded;
var
  Params: TFitParams;
begin
  Params := MakeSimpleFitParams;
  Params.Pop := 2;
  FPSO.TestSetParams(Params);
  FPSO.Pub_FLayersCount := 1;
  FPSO.TestInit_Domains(0);

  FPSO.GetX[0][0][1][0] := 50.0;
  FPSO.GetV[0][0][1][0] := 5.0;
  FPSO.GetVmax[0][0][1][0] := 10.0;
  FPSO.GetVmin[0][0][1][0] := -10.0;
  FPSO.GetXmax[0][0][1][0] := 100.0;
  FPSO.GetXmin[0][0][1][0] := 0.0;

  FPSO.TestCheckLimits(0, 0, 1);

  Assert.AreEqual(Single(55.0), FPSO.GetX[0][0][1][0], 1E-5,
    'X = 50 + 5 = 55, no clamping');
end;

{ ApplyCFactor }

procedure TTestLFPSOBase.Test_ApplyCFactor_AdaptVelTrue_Positive;
var
  Params: TFitParams;
  c1, c2: single;
begin
  Params := MakeSimpleFitParams;
  Params.AdaptVel := True;
  FPSO.TestSetParams(Params);
  FPSO.Pub_CFactor := 2.5;

  c1 := 0; c2 := 0;
  FPSO.TestApplyCFactor(c1, c2);

  Assert.AreEqual(Single(2.5), c1, 1E-5, 'c1 = CFactor');
  Assert.AreEqual(Single(2.5), c2, 1E-5, 'c2 = CFactor');
end;

procedure TTestLFPSOBase.Test_ApplyCFactor_AdaptVelFalse;
var
  Params: TFitParams;
  c1, c2: single;
begin
  Params := MakeSimpleFitParams;
  Params.AdaptVel := False;
  FPSO.TestSetParams(Params);
  FPSO.Pub_CFactor := 2.5;

  c1 := 0; c2 := 0;
  FPSO.TestApplyCFactor(c1, c2);

  Assert.AreEqual(Single(1.0), c1, 1E-5, 'c1 = 1 when AdaptVel=False');
  Assert.AreEqual(Single(1.0), c2, 1E-5, 'c2 = 1 when AdaptVel=False');
end;

procedure TTestLFPSOBase.Test_ApplyCFactor_AdaptVelTrue_ZeroCFactor;
var
  Params: TFitParams;
  c1, c2: single;
begin
  Params := MakeSimpleFitParams;
  Params.AdaptVel := True;
  FPSO.TestSetParams(Params);
  FPSO.Pub_CFactor := 0.0;  // not > 0 -> fallback to 1

  c1 := 0; c2 := 0;
  FPSO.TestApplyCFactor(c1, c2);

  Assert.AreEqual(Single(1.0), c1, 1E-5, 'c1 = 1 when CFactor=0');
  Assert.AreEqual(Single(1.0), c2, 1E-5, 'c2 = 1 when CFactor=0');
end;

{ Rand }

procedure TTestLFPSOBase.Test_Rand_StaysInRange;
var
  i: integer;
  v: single;
begin
  RandSeed := 42;
  for i := 1 to 200 do
  begin
    v := FPSO.TestRand(5.0);
    Assert.IsTrue((v >= -5.0) and (v <= 5.0),
      Format('Rand(5) returned %f, expected [-5..5]', [v]));
  end;
end;

{ LevyWalk }

procedure TTestLFPSOBase.Test_LevyWalk_ReturnsFinite;
var
  i: integer;
  v: single;
begin
  RandSeed := 42;
  for i := 1 to 100 do
  begin
    v := FPSO.TestLevyWalk(50.0, 30.0);
    Assert.IsFalse(IsNan(v) or IsInfinite(v), Format('LevyWalk returned non-finite: %g', [v]));
  end;
end;

{ UpdateStructure }

procedure TTestLFPSOBase.Test_UpdateStructure_WritesBackValues;
var
  Sol: TSolution;
  Struct: TFitStructure;
begin
  Struct := MakeSimpleStructure(2);
  FPSO.Pub_FStructure := Struct;

  Sol := MakeSimpleSolution(2);
  // Sol[0][1][0]=1, Sol[0][2][0]=2, Sol[0][3][0]=3
  // Sol[1][1][0]=2, Sol[1][2][0]=4, Sol[1][3][0]=6

  FPSO.TestUpdateStructure(Sol);

  Assert.AreEqual(Single(1.0), FPSO.Pub_FStructure.Stacks[0].Layers[0].P[1].V, 1E-5, 'Layer0 H');
  Assert.AreEqual(Single(2.0), FPSO.Pub_FStructure.Stacks[0].Layers[0].P[2].V, 1E-5, 'Layer0 s');
  Assert.AreEqual(Single(3.0), FPSO.Pub_FStructure.Stacks[0].Layers[0].P[3].V, 1E-5, 'Layer0 rho');
  Assert.AreEqual(Single(2.0), FPSO.Pub_FStructure.Stacks[0].Layers[1].P[1].V, 1E-5, 'Layer1 H');
  Assert.AreEqual(Single(4.0), FPSO.Pub_FStructure.Stacks[0].Layers[1].P[2].V, 1E-5, 'Layer1 s');
  Assert.AreEqual(Single(6.0), FPSO.Pub_FStructure.Stacks[0].Layers[1].P[3].V, 1E-5, 'Layer1 rho');
end;

{ FitModelToLayer }

procedure TTestLFPSOBase.Test_FitModelToLayer_CreatesCorrectLayers;
var
  Sol: TSolution;
  Model: TLayeredModel;
  Layers: TCalcLayers;
begin
  FPSO.Pub_FStructure := MakeSimpleStructure(2);
  Sol := MakeSimpleSolution(2);

  Model := FPSO.TestFitModelToLayer(Sol);
  try
    Layers := Model.Layers;
    // Vacuum (1) + 2 structure layers + 1 substrate = 4
    Assert.AreEqual(4, Length(Layers), 'Total layers = vacuum + 2 + substrate');

    // First structure layer: H = Sol[0][1][0] = 1.0
    Assert.AreEqual(Single(1.0), Layers[1].L, 1E-5, 'Layer 1 thickness from solution');

    // Second structure layer: H = Sol[1][1][0] = 2.0
    Assert.AreEqual(Single(2.0), Layers[2].L, 1E-5, 'Layer 2 thickness from solution');
  finally
    Model.Free;
  end;
end;

{ Terminate }

procedure TTestLFPSOBase.Test_Terminate_SetsFlag;
begin
  Assert.IsFalse(FPSO.Pub_FTerminated, 'Not terminated initially');
  FPSO.Terminate;
  Assert.IsTrue(FPSO.Pub_FTerminated, 'Terminated after call');
end;

end.
