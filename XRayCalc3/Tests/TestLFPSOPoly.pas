unit TestLFPSOPoly;

{ TLFPSO_Poly.InitialPolynomes - seeding the fitted polynomial from the depth
  profile the model already carries.

  Set_Init_XPoly only ever wrote the constant term, and SetLength grew the rest
  of the coefficient array to zero. A free fit recovers from that, because XSeed
  scatters the higher orders over Xrange. A frozen one cannot: freezing pins
  min = max = V, Xrange[0] is then 0, every higher order derives from it
  (Xrange[p] := Xrange[0] / TP(p)), Rand(0) returns 0 - and the coefficients stay
  on whatever SetStructure left them. Left at zero, a graded stack is fitted as
  an ungraded one.

  Test_SeededGradient_SurvivesAFrozenFit is the invariant that matters: it needs
  the GUI's Henke tables and passes with a note when they are not installed, the
  way TestLFPSOProgress does. }

interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  unit_Types,
  unit_materials,
  unit_LFPSO_Base,
  unit_LFPSO_Poly;

type
  TTestablePoly = class(TLFPSO_Poly)
  public
    function GetX: TPopulation;
    function GetPoly: TProfileFunctions;
    function GetStructure: TFitStructure;

    procedure TestSetStructure(const Inp: TFitStructure);
    procedure TestSetParams(const Value: TFitParams);
  end;

  [TestFixture]
  TTestLFPSOPoly = class
  private
    FPSO: TTestablePoly;
    FSavedHenkeDir: string;

    function MakeParams(const AMaxPOrder: Integer;
      const ANMax: Integer = 5; const APop: Integer = 6): TFitParams;
    function MakeTwoStackStructure: TFitStructure;
    function MakeProfiles: TProfileFunctions;

    function HenkeAvailable(const Material: string): Boolean;
    function TablesReady: Boolean;
    function MakeCalcParams: TCalcThreadParams;
    function MakeGradedStructure: TFitStructure;
    function MakeGradedProfiles: TProfileFunctions;
    function MakeGradedExpData(const ACalcParams: TCalcThreadParams): TDataArray;
    function MakePartlyFrozenStructure: TFitStructure;
    function MakePartlyFrozenProfiles: TProfileFunctions;
    function MakePartlyFrozenExpData(const ACalcParams: TCalcThreadParams): TDataArray;
    function FindPoly(const APolynomes: TProfileFunctions;
      const AStackID, ALayerID: Word; const ASubj: TParameterType): TFuncProfileRec;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { 1 - the seeding itself }
    [Test] procedure Test_Seed_HigherOrdersComeFromTheProfile;
    [Test] procedure Test_Seed_ConstantTermStaysTheLiveValue;
    [Test] procedure Test_Seed_MatchesByIdentityNotPosition;
    [Test] procedure Test_Seed_NoMatchingProfileLeavesZeroes;
    [Test] procedure Test_Seed_NonPolyProfileIsIgnored;
    [Test] procedure Test_Seed_PairedAndSinglePeriodStayScalar;
    [Test] procedure Test_Seed_TooManyCoefficientsAreTruncated;

    { 2 - the invariant the user cares about }
    [Test] procedure Test_SeededGradient_SurvivesAFrozenFit;
    [Test] procedure Test_SeededGradient_SurvivesAPartlyFrozenFit;
  end;

implementation

uses
  System.IOUtils,
  unit_Config,
  unit_calc,
  unit_SmartLimits;

const
  HENKE_DB_PATH = 'd:\SoftwareStorage\X-RayCalc3\Henke';
  CU_KA         = 1.5406;

  { Test 1 - the two-stack structure. Stack 0 is periodic (N > 1), stack 1 is
    a single layer with N = 1. }
  S0_L0_H = 40.0;  S0_L0_S = 3.0;  S0_L0_R = 2.33;
  S0_L1_H = 20.0;  S0_L1_S = 3.0;  S0_L1_R = 10.20;
  S1_L0_H = 55.0;  S1_L0_S = 4.0;  S1_L0_R = 2.00;

  { Distinctive coefficients - nothing a zero-filled array could produce. }
  C_S0L1_H1 =  0.75;   C_S0L1_H2 = -0.0125;
  C_S0L0_S1 =  0.25;
  C_S1L0_H1 =  3.5;    // stack 1 has N = 1: must never be written
  C_S0L1_R1 =  9.0;    // rho of layer 1 is Paired: must never be written
  C_S0L0_R1 =  7.0;    // authored as ffExp: not in this basis, must be ignored
  C_LONG_1  =  0.4;    C_LONG_2 = 0.03;  C_LONG_3 = 0.002;

  { Test 2 - the graded Si/Mo stack. }
  G_PERIODS = 8;
  G_H1      = 40.0;    // Si thickness of the first period
  G_GRAD    = -0.8;    // ... and how much it loses per period
  G_S1      = 3.0;     G_R1 = 2.33;
  G_H2      = 20.0;    G_S2 = 3.0;  G_R2 = 10.20;
  G_SUB_S   = 3.0;     G_SUB_R = 2.33;
  G_SEED    = 11;

  { Test 2b - the same stack, frozen, under a free capping layer that starts
    well off the truth, so the swarm has real work to do on a free parameter
    while the gradient is pinned. }
  P_GRAD      = -0.8;   // A per period, against 40 A layers
  P_CAP_TRUE  = 30.0;   // what the measurement really has
  P_CAP_START = 45.0;   // ... and where the fit is told to start
  P_CAP_S     = 3.0;    P_CAP_R = 2.20;
  P_NMAX      = 12;
  P_POP       = 8;
  P_SEED      = 5;

{ TTestablePoly }

function TTestablePoly.GetX: TPopulation;
begin
  Result := X;
end;

function TTestablePoly.GetPoly: TProfileFunctions;
begin
  Result := GetPolynomes;
end;

function TTestablePoly.GetStructure: TFitStructure;
begin
  Result := FStructure;
end;

procedure TTestablePoly.TestSetStructure(const Inp: TFitStructure);
begin
  SetStructure(Inp);
end;

procedure TTestablePoly.TestSetParams(const Value: TFitParams);
begin
  SetParams(Value);
end;

{ ---------------- fixture ---------------- }

procedure TTestLFPSOPoly.Setup;
begin
  FPSO := TTestablePoly.Create;
  FSavedHenkeDir := TConfig.Section<TPathOptions>.HenkeDir;
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;
end;

procedure TTestLFPSOPoly.TearDown;
begin
  TConfig.Section<TPathOptions>.HenkeDir := FSavedHenkeDir;
  FreeAndNil(FPSO);
end;

function TTestLFPSOPoly.HenkeAvailable(const Material: string): Boolean;
begin
  Result := TFile.Exists(IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke])
    + Material + '.bin');
end;

function TTestLFPSOPoly.TablesReady: Boolean;
begin
  Result := HenkeAvailable('Si') and HenkeAvailable('Mo');
end;

function TTestLFPSOPoly.MakeParams(const AMaxPOrder: Integer;
  const ANMax: Integer; const APop: Integer): TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax       := ANMax;
  Result.Pop        := APop;
  Result.Tolerance  := 0;
  Result.Vmax       := 0.3;
  Result.JammingMax := 100;
  Result.ReInitMax  := 3;
  Result.KChiSqr    := 1.5;
  Result.KVmax      := 1.2;
  Result.w1         := 0.4;
  Result.w2         := 0.5;
  Result.Ksxr       := 0.1;
  Result.Shake      := False;
  Result.AdaptVel   := False;
  Result.RangeSeed  := False;
  Result.MaxPOrder  := AMaxPOrder;
  Result.PolyFactor := 10;
end;

{ Stack 0: N = 5, two layers. Stack 1: N = 1, one layer.
  Flat Index runs 0, 1 over stack 0 and 2 over stack 1. }
function TTestLFPSOPoly.MakeTwoStackStructure: TFitStructure;
var
  p: Integer;
begin
  SetLength(Result.Stacks, 2);

  Result.Stacks[0].ID := 0;
  Result.Stacks[0].N  := 5;
  SetLength(Result.Stacks[0].Layers, 2);

  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID  := 0;
  Result.Stacks[0].Layers[0].LayerID  := 0;
  Result.Stacks[0].Layers[0].P[1].V   := S0_L0_H;
  Result.Stacks[0].Layers[0].P[2].V   := S0_L0_S;
  Result.Stacks[0].Layers[0].P[3].V   := S0_L0_R;

  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID  := 0;
  Result.Stacks[0].Layers[1].LayerID  := 1;
  Result.Stacks[0].Layers[1].P[1].V   := S0_L1_H;
  Result.Stacks[0].Layers[1].P[2].V   := S0_L1_S;
  Result.Stacks[0].Layers[1].P[3].V   := S0_L1_R;

  Result.Stacks[1].ID := 1;
  Result.Stacks[1].N  := 1;
  SetLength(Result.Stacks[1].Layers, 1);
  Result.Stacks[1].Layers[0].Material := 'C';
  Result.Stacks[1].Layers[0].StackID  := 1;
  Result.Stacks[1].Layers[0].LayerID  := 0;
  Result.Stacks[1].Layers[0].P[1].V   := S1_L0_H;
  Result.Stacks[1].Layers[0].P[2].V   := S1_L0_S;
  Result.Stacks[1].Layers[0].P[3].V   := S1_L0_R;

  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[0].P[p].min := 0.5;
    Result.Stacks[0].Layers[0].P[p].max := 60.0;
    Result.Stacks[0].Layers[1].P[p].min := 0.5;
    Result.Stacks[0].Layers[1].P[p].max := 60.0;
    Result.Stacks[1].Layers[0].P[p].min := 0.5;
    Result.Stacks[1].Layers[0].P[p].max := 60.0;
  end;

  { Rho of stack 0 / layer 1 is paired: Set_Init_XPoly leaves it scalar. }
  Result.Stacks[0].Layers[1].P[3].Paired := True;

  Result.Subs.Material := 'Si';
  for p := 1 to 3 do
    Result.Subs.P[p].New(3.0);
end;

{ Deliberately in an order that has nothing to do with the flat Index: the
  first record belongs to the SECOND layer. Matching by position would put its
  coefficients on layer 0. }
function TTestLFPSOPoly.MakeProfiles: TProfileFunctions;
begin
  SetLength(Result, 5);

  Result[0].Func    := ffPoly;                 // stack 0, layer 1, H
  Result[0].Subj    := ptH;
  Result[0].StackID := 0;
  Result[0].LayerID := 1;
  Result[0].C       := [S0_L1_H, C_S0L1_H1, C_S0L1_H2];

  Result[1].Func    := ffPoly;                 // stack 0, layer 0, sigma
  Result[1].Subj    := ptS;
  Result[1].StackID := 0;
  Result[1].LayerID := 0;
  Result[1].C       := [S0_L0_S, C_S0L0_S1];

  Result[2].Func    := ffExp;                  // not this basis - ignore
  Result[2].Subj    := ptRho;
  Result[2].StackID := 0;
  Result[2].LayerID := 0;
  Result[2].C       := [S0_L0_R, C_S0L0_R1];

  Result[3].Func    := ffPoly;                 // stack 1 has N = 1 - no orders
  Result[3].Subj    := ptH;
  Result[3].StackID := 1;
  Result[3].LayerID := 0;
  Result[3].C       := [S1_L0_H, C_S1L0_H1];

  Result[4].Func    := ffPoly;                 // stack 0, layer 1, rho: Paired
  Result[4].Subj    := ptRho;
  Result[4].StackID := 0;
  Result[4].LayerID := 1;
  Result[4].C       := [S0_L1_R, C_S0L1_R1];
end;

{ ---------------- 1: the seeding ---------------- }

procedure TTestLFPSOPoly.Test_Seed_HigherOrdersComeFromTheProfile;
begin
  FPSO.TestSetParams(MakeParams(2));            // MO = 3
  FPSO.InitialPolynomes := MakeProfiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  Assert.AreEqual(3, Length(FPSO.GetX[0][1][1]),
    'a periodic, unpaired parameter carries MO coefficients');
  Assert.AreEqual(Single(C_S0L1_H1), FPSO.GetX[0][1][1][1], 1E-6,
    'order 1 of H comes from the profile');
  Assert.AreEqual(Single(C_S0L1_H2), FPSO.GetX[0][1][1][2], 1E-6,
    'order 2 of H comes from the profile');
  Assert.AreEqual(Single(C_S0L0_S1), FPSO.GetX[0][0][2][1], 1E-6,
    'order 1 of sigma comes from the profile');
end;

procedure TTestLFPSOPoly.Test_Seed_ConstantTermStaysTheLiveValue;
var
  Profiles: TProfileFunctions;
begin
  Profiles := MakeProfiles;
  { The stored constant is stale - the structure has been edited since. }
  Profiles[0].C[0] := 999.0;
  Profiles[1].C[0] := 999.0;

  FPSO.TestSetParams(MakeParams(2));
  FPSO.InitialPolynomes := Profiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  Assert.AreEqual(Single(S0_L1_H), FPSO.GetX[0][1][1][0], 1E-6,
    'the constant term is the live V, not the stored C[0]');
  Assert.AreEqual(Single(S0_L0_S), FPSO.GetX[0][0][2][0], 1E-6,
    'the constant term is the live V for sigma too');
end;

procedure TTestLFPSOPoly.Test_Seed_MatchesByIdentityNotPosition;
begin
  FPSO.TestSetParams(MakeParams(2));
  FPSO.InitialPolynomes := MakeProfiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  { Profile 0 is the first record handed over but belongs to Index 1.
    Positional matching would land it on Index 0. }
  Assert.AreEqual(Single(0.0), FPSO.GetX[0][0][1][1], 1E-6,
    'layer 0 H has no profile of its own and must stay flat');
  Assert.AreEqual(Single(C_S0L1_H1), FPSO.GetX[0][1][1][1], 1E-6,
    'layer 1 H got the coefficients addressed to it');
end;

procedure TTestLFPSOPoly.Test_Seed_NoMatchingProfileLeavesZeroes;
var
  k: Integer;
begin
  FPSO.TestSetParams(MakeParams(2));
  FPSO.InitialPolynomes := MakeProfiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  { Stack 0 / layer 1 sigma: nothing was supplied for it. }
  Assert.AreEqual(Single(S0_L1_S), FPSO.GetX[0][1][2][0], 1E-6,
    'its constant term is still the live value');
  for k := 1 to High(FPSO.GetX[0][1][2]) do
    Assert.AreEqual(Single(0.0), FPSO.GetX[0][1][2][k], 1E-6,
      Format('unmatched parameter keeps order %d at zero', [k]));
end;

procedure TTestLFPSOPoly.Test_Seed_NonPolyProfileIsIgnored;
var
  k: Integer;
begin
  FPSO.TestSetParams(MakeParams(2));
  FPSO.InitialPolynomes := MakeProfiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  { Stack 0 / layer 0 rho was authored as an exponential. }
  for k := 1 to High(FPSO.GetX[0][0][3]) do
    Assert.AreEqual(Single(0.0), FPSO.GetX[0][0][3][k], 1E-6,
      Format('an ffExp profile must not seed order %d', [k]));
end;

procedure TTestLFPSOPoly.Test_Seed_PairedAndSinglePeriodStayScalar;
begin
  FPSO.TestSetParams(MakeParams(2));
  FPSO.InitialPolynomes := MakeProfiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  Assert.AreEqual(1, Length(FPSO.GetX[0][1][3]),
    'a paired parameter keeps a single coefficient');
  Assert.AreEqual(Single(S0_L1_R), FPSO.GetX[0][1][3][0], 1E-6,
    'and that coefficient is still the live value');

  Assert.AreEqual(1, Length(FPSO.GetX[0][2][1]),
    'a stack with N = 1 keeps a single coefficient');
  Assert.AreEqual(Single(S1_L0_H), FPSO.GetX[0][2][1][0], 1E-6,
    'and that coefficient is still the live value');
end;

procedure TTestLFPSOPoly.Test_Seed_TooManyCoefficientsAreTruncated;
var
  Profiles: TProfileFunctions;
begin
  Profiles := MakeProfiles;
  Profiles[0].C := [S0_L1_H, C_LONG_1, C_LONG_2, C_LONG_3];

  FPSO.TestSetParams(MakeParams(1));            // MO = 2: orders 0 and 1 only
  FPSO.InitialPolynomes := Profiles;
  FPSO.TestSetStructure(MakeTwoStackStructure);

  Assert.AreEqual(2, Length(FPSO.GetX[0][1][1]),
    'MaxPOrder = 1 gives two coefficients');
  Assert.AreEqual(Single(C_LONG_1), FPSO.GetX[0][1][1][1], 1E-6,
    'order 1 is copied');
end;

{ ---------------- 2: the frozen graded fit ---------------- }

function TTestLFPSOPoly.MakeCalcParams: TCalcThreadParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Mode   := cmTheta;
  Result.RF     := rfError;
  Result.P      := cmS;
  Result.K      := 1;
  Result.N      := 200;
  Result.StartT := 0.3;
  Result.EndT   := 3.0;
  Result.DT     := 0;
  Result.Lambda := CU_KA;
end;

{ A Si/Mo stack whose Si thickness follows H(j) = G_H1 + G_GRAD * (j - 1),
  which is exactly Poly(j, [G_H1, G_GRAD]). Every parameter is frozen, so the
  only thing that can hold the gradient is the seed. }
function TTestLFPSOPoly.MakeGradedStructure: TFitStructure;
var
  p: Integer;
begin
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].ID := 0;
  Result.Stacks[0].N  := G_PERIODS;
  SetLength(Result.Stacks[0].Layers, 2);

  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID  := 0;
  Result.Stacks[0].Layers[0].LayerID  := 0;
  Result.Stacks[0].Layers[0].P[1].V   := G_H1;
  Result.Stacks[0].Layers[0].P[2].V   := G_S1;
  Result.Stacks[0].Layers[0].P[3].V   := G_R1;

  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID  := 0;
  Result.Stacks[0].Layers[1].LayerID  := 1;
  Result.Stacks[0].Layers[1].P[1].V   := G_H2;
  Result.Stacks[0].Layers[1].P[2].V   := G_S2;
  Result.Stacks[0].Layers[1].P[3].V   := G_R2;

  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[0].P[p].min   := 0.5;
    Result.Stacks[0].Layers[0].P[p].max   := 60.0;
    Result.Stacks[0].Layers[0].P[p].Fixed := True;
    Result.Stacks[0].Layers[1].P[p].min   := 0.5;
    Result.Stacks[0].Layers[1].P[p].max   := 60.0;
    Result.Stacks[0].Layers[1].P[p].Fixed := True;
  end;

  Result.Subs.Material := 'Si';
  Result.Subs.P[1].New(0);
  Result.Subs.P[2].New(G_SUB_S);
  Result.Subs.P[3].New(G_SUB_R);
end;

function TTestLFPSOPoly.MakeGradedProfiles: TProfileFunctions;
begin
  SetLength(Result, 1);
  Result[0].Func    := ffPoly;
  Result[0].Subj    := ptH;
  Result[0].StackID := 0;
  Result[0].LayerID := 0;
  Result[0].C       := [G_H1, G_GRAD];
end;

{ The measurement: the graded model run through the engine on the grid the fit
  will use. }
function TTestLFPSOPoly.MakeGradedExpData(const ACalcParams: TCalcThreadParams): TDataArray;
var
  Calc: TCalc;
  Model: TLayeredModel;
  Data, SubData: TLayersData;
  j: Integer;
begin
  Model := TLayeredModel.Create;
  Model.Init;

  SetLength(Data, 2);
  Data[0].Material := 'Si';
  Data[0].StackID  := 0;
  Data[0].LayerID  := 0;
  Data[1].Material := 'Mo';
  Data[1].StackID  := 0;
  Data[1].LayerID  := 1;
  Data[1].P[1].New(G_H2);
  Data[1].P[2].New(G_S2);
  Data[1].P[3].New(G_R2);

  for j := 1 to G_PERIODS do
  begin
    Data[0].P[1].New(G_H1 + G_GRAD * (j - 1));
    Data[0].P[2].New(G_S1);
    Data[0].P[3].New(G_R1);
    Model.AddLayers(-1, Data);
  end;

  SetLength(SubData, 1);
  SubData[0].Material := 'Si';
  SubData[0].P[1].New(0);
  SubData[0].P[2].New(G_SUB_S);
  SubData[0].P[3].New(G_SUB_R);
  Model.AddSubstrate(SubData);

  Calc := TCalc.Create;
  try
    Calc.MaxThreads := 1;
    Calc.Params := ACalcParams;
    Calc.Limit  := 1E-7;
    Calc.Model  := Model;
    Calc.Run;
    Result := Copy(Calc.Results);
  finally
    Calc.Model := nil;
    Calc.Free;
    Model.Free;
  end;
end;

function TTestLFPSOPoly.FindPoly(const APolynomes: TProfileFunctions;
  const AStackID, ALayerID: Word; const ASubj: TParameterType): TFuncProfileRec;
var
  i: Integer;
begin
  FillChar(Result, SizeOf(Result), 0);
  for i := 0 to High(APolynomes) do
    if (APolynomes[i].StackID = AStackID) and (APolynomes[i].LayerID = ALayerID)
      and (APolynomes[i].Subj = ASubj) then
      Exit(APolynomes[i]);
  Assert.Fail(Format('no polynomial reported for stack %d layer %d parameter %d',
    [AStackID, ALayerID, Ord(ASubj) + 1]));
end;

{ Freeze every parameter of a graded stack, seed the gradient, run a short fit
  and read the gradient back. An empty range cannot move a coefficient off the
  value SetStructure gave it, so whatever comes back is the seed - zero before
  this fix, the supplied gradient after it. }
procedure TTestLFPSOPoly.Test_SeededGradient_SurvivesAFrozenFit;
var
  PSO: TTestablePoly;
  CalcParams: TCalcThreadParams;
  S: TFitStructure;
  Reported: TFuncProfileRec;
begin
  if not TablesReady then
  begin
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);
    Exit;
  end;

  CalcParams := MakeCalcParams;
  S := MakeGradedStructure;
  CollapseFixed(S);           // freezing, exactly as the orchestrator does it

  PSO := TTestablePoly.Create;
  try
    PSO.Params           := MakeParams(1);     // MO = 2: constant + gradient
    PSO.Limit            := 1E-7;
    PSO.ExpValues        := MakeGradedExpData(CalcParams);
    PSO.Seed             := G_SEED;
    PSO.InitialPolynomes := MakeGradedProfiles;
    PSO.Structure        := S;

    PSO.Run(CalcParams);

    Reported := FindPoly(PSO.GetPoly, 0, 0, ptH);

    Assert.IsTrue(Length(Reported.C) >= 2,
      Format('the fit must report a polynomial, got %d coefficients',
        [Length(Reported.C)]));
    Assert.AreEqual(Single(G_H1), Reported.C[0], 1E-4,
      'the frozen constant term comes back untouched');
    Assert.AreEqual(Single(G_GRAD), Reported.C[1], 1E-4,
      Format('the frozen gradient must survive the fit, got %g instead of %g',
        [Reported.C[1], G_GRAD]));
  finally
    PSO.Free;
  end;
end;

{ The same graded, fully frozen Si/Mo stack, but with a free capping layer on
  top of it. This is the workflow the freeze feature exists for: pin the part
  of the structure you already trust and let the rest move. Because the cap is
  free, a particle other than the seeded leader X[0] wins FindTheBest, and
  abest then carries THAT particle's copy of the frozen gradient. }
function TTestLFPSOPoly.MakePartlyFrozenStructure: TFitStructure;
var
  p: Integer;
begin
  SetLength(Result.Stacks, 2);

  { Stack 0 - the graded multilayer, every parameter frozen. }
  Result.Stacks[0].ID := 0;
  Result.Stacks[0].N  := G_PERIODS;
  SetLength(Result.Stacks[0].Layers, 2);

  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID  := 0;
  Result.Stacks[0].Layers[0].LayerID  := 0;
  Result.Stacks[0].Layers[0].P[1].V   := G_H1;
  Result.Stacks[0].Layers[0].P[2].V   := G_S1;
  Result.Stacks[0].Layers[0].P[3].V   := G_R1;

  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID  := 0;
  Result.Stacks[0].Layers[1].LayerID  := 1;
  Result.Stacks[0].Layers[1].P[1].V   := G_H2;
  Result.Stacks[0].Layers[1].P[2].V   := G_S2;
  Result.Stacks[0].Layers[1].P[3].V   := G_R2;

  for p := 1 to 3 do
  begin
    Result.Stacks[0].Layers[0].P[p].min   := 0.5;
    Result.Stacks[0].Layers[0].P[p].max   := 60.0;
    Result.Stacks[0].Layers[0].P[p].Fixed := True;
    Result.Stacks[0].Layers[1].P[p].min   := 0.5;
    Result.Stacks[0].Layers[1].P[p].max   := 60.0;
    Result.Stacks[0].Layers[1].P[p].Fixed := True;
  end;

  { Stack 1 - the cap, free, and deliberately started well off the truth so
    the swarm has somewhere to go. N = 1, so it comes after the periodic stack
    and never reaches GetPolynomes' indexing branch. }
  Result.Stacks[1].ID := 1;
  Result.Stacks[1].N  := 1;
  SetLength(Result.Stacks[1].Layers, 1);
  Result.Stacks[1].Layers[0].Material := 'C';
  Result.Stacks[1].Layers[0].StackID  := 1;
  Result.Stacks[1].Layers[0].LayerID  := 0;

  Result.Stacks[1].Layers[0].P[1].V   := P_CAP_START;
  Result.Stacks[1].Layers[0].P[1].min := 10.0;
  Result.Stacks[1].Layers[0].P[1].max := 60.0;
  Result.Stacks[1].Layers[0].P[2].V   := P_CAP_S;
  Result.Stacks[1].Layers[0].P[2].min := 1.0;
  Result.Stacks[1].Layers[0].P[2].max := 6.0;
  Result.Stacks[1].Layers[0].P[3].V   := P_CAP_R;
  Result.Stacks[1].Layers[0].P[3].min := 1.5;
  Result.Stacks[1].Layers[0].P[3].max := 3.0;

  Result.Subs.Material := 'Si';
  Result.Subs.P[1].New(0);
  Result.Subs.P[2].New(G_SUB_S);
  Result.Subs.P[3].New(G_SUB_R);
end;

function TTestLFPSOPoly.MakePartlyFrozenProfiles: TProfileFunctions;
begin
  SetLength(Result, 1);
  Result[0].Func    := ffPoly;
  Result[0].Subj    := ptH;
  Result[0].StackID := 0;
  Result[0].LayerID := 0;
  Result[0].C       := [G_H1, P_GRAD];
end;

{ The measurement for the partly frozen fit: the graded stack exactly as it is
  frozen, under a cap of the thickness the fit has to find. }
function TTestLFPSOPoly.MakePartlyFrozenExpData(const ACalcParams: TCalcThreadParams): TDataArray;
var
  Calc: TCalc;
  Model: TLayeredModel;
  Data, CapData, SubData: TLayersData;
  j: Integer;
begin
  Model := TLayeredModel.Create;
  Model.Init;

  SetLength(Data, 2);
  Data[0].Material := 'Si';
  Data[0].StackID  := 0;
  Data[0].LayerID  := 0;
  Data[1].Material := 'Mo';
  Data[1].StackID  := 0;
  Data[1].LayerID  := 1;
  Data[1].P[1].New(G_H2);
  Data[1].P[2].New(G_S2);
  Data[1].P[3].New(G_R2);

  for j := 1 to G_PERIODS do
  begin
    Data[0].P[1].New(G_H1 + P_GRAD * (j - 1));
    Data[0].P[2].New(G_S1);
    Data[0].P[3].New(G_R1);
    Model.AddLayers(-1, Data);
  end;

  SetLength(CapData, 1);
  CapData[0].Material := 'C';
  CapData[0].StackID  := 1;
  CapData[0].LayerID  := 0;
  CapData[0].P[1].New(P_CAP_TRUE);
  CapData[0].P[2].New(P_CAP_S);
  CapData[0].P[3].New(P_CAP_R);
  Model.AddLayers(-1, CapData);

  SetLength(SubData, 1);
  SubData[0].Material := 'Si';
  SubData[0].P[1].New(0);
  SubData[0].P[2].New(G_SUB_S);
  SubData[0].P[3].New(G_SUB_R);
  Model.AddSubstrate(SubData);

  Calc := TCalc.Create;
  try
    Calc.MaxThreads := 1;
    Calc.Params := ACalcParams;
    Calc.Limit  := 1E-7;
    Calc.Model  := Model;
    Calc.Run;
    Result := Copy(Calc.Results);
  finally
    Calc.Model := nil;
    Calc.Free;
    Model.Free;
  end;
end;

{ Freeze a graded stack but leave a cap free, and the leader no longer protects
  the gradient: a free particle wins FindTheBest and abest is ITS solution. The
  gradient therefore has to survive inside every particle, not just X[0] - which
  is what CheckLimitsP's empty-range guard is for. Without that guard the range
  walk zeroes the higher orders of every particle it touches, so abest comes
  back flat and, worse, every chi square from iteration 1 on is computed against
  a flattened model. }
procedure TTestLFPSOPoly.Test_SeededGradient_SurvivesAPartlyFrozenFit;
var
  PSO: TTestablePoly;
  CalcParams: TCalcThreadParams;
  S: TFitStructure;
  Final: TFitStructure;
  Reported: TFuncProfileRec;
begin
  if not TablesReady then
  begin
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);
    Exit;
  end;

  CalcParams := MakeCalcParams;
  S := MakePartlyFrozenStructure;
  CollapseFixed(S);

  PSO := TTestablePoly.Create;
  try
    PSO.Params           := MakeParams(1, P_NMAX, P_POP);
    PSO.Limit            := 1E-7;
    PSO.ExpValues        := MakePartlyFrozenExpData(CalcParams);
    PSO.Seed             := P_SEED;
    PSO.InitialPolynomes := MakePartlyFrozenProfiles;
    PSO.Structure        := S;

    PSO.Run(CalcParams);

    Final := PSO.GetStructure;

    { The precondition, asserted rather than assumed: a particle other than the
      seeded leader won, and won by improving the free parameter. X[0] holds
      the cap at P_CAP_START and, being the leader, never moves off it, so a
      cap nearer the truth can only have come from another particle's solution.
      Without the empty-range guard this is exactly what cannot happen: the
      leader is the only particle that still carries the gradient, nothing can
      out-score it, pbest and gbest stay pinned to it, and the swarm converges
      back onto the starting cap instead of the right one. }
    Assert.IsTrue(Abs(Final.Stacks[1].Layers[0].P[1].V - P_CAP_START) > 1E-3,
      Format('a free particle must have won the fit: the cap is still at its ' +
        'starting %g, so abest is the leader''s own solution',
        [Final.Stacks[1].Layers[0].P[1].V]));

    { The frozen constants are untouched, as an empty range demands. }
    Assert.AreEqual(Single(G_H1), Final.Stacks[0].Layers[0].P[1].V, 1E-4,
      'the frozen Si thickness stayed put');
    Assert.AreEqual(Single(G_H2), Final.Stacks[0].Layers[1].P[1].V, 1E-4,
      'the frozen Mo thickness stayed put');

    { And so is the gradient. }
    Reported := FindPoly(PSO.GetPoly, 0, 0, ptH);
    Assert.IsTrue(Length(Reported.C) >= 2,
      Format('the fit must report a polynomial, got %d coefficients',
        [Length(Reported.C)]));
    Assert.AreEqual(Single(G_H1), Reported.C[0], 1E-4,
      'the frozen constant term comes back untouched');
    Assert.AreEqual(Single(P_GRAD), Reported.C[1], 1E-4,
      Format('the frozen gradient must survive a fit won by another particle, ' +
        'got %g instead of %g', [Reported.C[1], P_GRAD]));
  finally
    PSO.Free;
  end;
end;

end.
