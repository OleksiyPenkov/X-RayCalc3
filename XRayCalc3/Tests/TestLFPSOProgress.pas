unit TestLFPSOProgress;


interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  unit_Types,
  unit_materials,
  unit_LFPSO_Base,
  unit_LFPSO_Periodic;

type
  ETestProgressAbort = class(Exception);

  { Stops the fit at the last moment before FindTheBest can assign abest.
    InitVelocity is the final virtual hook inside Init(0), so terminating
    here reproduces a stop that lands between Run resetting FTerminated and
    the first solution being recorded - the state that used to crash the
    post-loop update. }
  TTerminateBeforeBestPSO = class(TLFPSO_Periodic)
  protected
    procedure InitVelocity; override;
  end;

  [TestFixture]
  TTestLFPSOProgress = class
  private
    FSavedHenkeDir: string;
    FRaiseOnProgress: Boolean;
    FFullCount: Integer;
    FStepCount: Integer;
    FFullWithModel: Integer;
    FStepWithModel: Integer;

    procedure HandleProgress(const Msg: TUpdateFitProgressMsg);
    function HenkeAvailable(const Material: string): Boolean;
    function TablesReady: Boolean;
    function MakeCalcParams: TCalcThreadParams;
    function MakeFitParams: TFitParams;
    function MakeStructure: TFitStructure;
    function MakeExpData(const ACalcParams: TCalcThreadParams): TDataArray;
    procedure RunFit(const ASeed: Integer; const AUseProgress: Boolean;
      out ABestChi: Single; out ABestCurve: TDataArray);
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Test_Seed_DefaultIsMinusOne;
    [Test] procedure Test_OnProgress_IsCalledWithAFullModel;
    [Test] procedure Test_Seed_SameSeedGivesSameBestChiSquare;
    [Test] procedure Test_Seed_DifferentSeedsGiveDifferentAnswers;
    [Test] procedure Test_Seed_PinnedBestChiSquare;
    [Test] procedure Test_OnProgress_ThatRaises_LeaksNothing;
    [Test] procedure Test_BestCurve_IsNotEmptyAfterARun;
    [Test] procedure Test_StopBeforeFirstBest_DoesNotRaise;
    [Test] procedure Test_Run_InvertedRange_RaisesBeforeFitting;
  end;

implementation

uses
  System.IOUtils,
  unit_Config,
  unit_calc;

const
  HENKE_DB_PATH = 'd:\SoftwareStorage\X-RayCalc3\Henke';
  CU_KA         = 1.5406;   // Cu K-alpha, Angstrom

  N_PERIODS = 10;
  TRUE_H1 = 40.0;  TRUE_S1 = 3.0;  TRUE_R1 = 2.33;
  TRUE_H2 = 20.0;  TRUE_S2 = 3.0;  TRUE_R2 = 10.20;
  SUB_S   = 3.0;   SUB_R   = 2.33;
  // the starting guess - off the truth, but with the same period, because the
  // periodic engine holds the stack period constant
  INIT_H1 = 38.0;  INIT_S1 = 2.5;  INIT_R1 = 2.60;
  INIT_H2 = 22.0;  INIT_S2 = 2.5;  INIT_R2 = 9.50;

  TEST_SEED  = 7;
  OTHER_SEED = 99;


function BuildTrueModel: TLayeredModel;
var
  Data, SubData: TLayersData;
  j: Integer;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  SetLength(Data, 2);
  Data[0].Material := 'Si';
  Data[0].P[1].New(TRUE_H1);
  Data[0].P[2].New(TRUE_S1);
  Data[0].P[3].New(TRUE_R1);
  Data[0].StackID := 0;
  Data[0].LayerID := 0;
  Data[1].Material := 'Mo';
  Data[1].P[1].New(TRUE_H2);
  Data[1].P[2].New(TRUE_S2);
  Data[1].P[3].New(TRUE_R2);
  Data[1].StackID := 0;
  Data[1].LayerID := 1;

  for j := 1 to N_PERIODS do
    Result.AddLayers(-1, Data, 2);

  SetLength(SubData, 1);
  SubData[0].Material := 'Si';
  SubData[0].P[1].New(0);
  SubData[0].P[2].New(SUB_S);
  SubData[0].P[3].New(SUB_R);
  Result.AddSubstrate(SubData);
end;


procedure TTestLFPSOProgress.Setup;
begin
  FSavedHenkeDir := TConfig.Section<TPathOptions>.HenkeDir;
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;
  FFullCount := 0;
  FStepCount := 0;
  FFullWithModel := 0;
  FStepWithModel := 0;
  FRaiseOnProgress := False;
end;

procedure TTestLFPSOProgress.TearDown;
begin
  TConfig.Section<TPathOptions>.HenkeDir := FSavedHenkeDir;
end;

function TTestLFPSOProgress.HenkeAvailable(const Material: string): Boolean;
begin
  Result := TFile.Exists(IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke])
    + Material + '.bin');
end;

function TTestLFPSOProgress.TablesReady: Boolean;
begin
  Result := HenkeAvailable('Si') and HenkeAvailable('Mo');
end;

procedure TTestLFPSOProgress.HandleProgress(const Msg: TUpdateFitProgressMsg);
begin
  if Msg.Full then
  begin
    Inc(FFullCount);
    if Msg.LayeredModel <> nil then
      Inc(FFullWithModel);
  end
  else
  begin
    Inc(FStepCount);
    if Msg.LayeredModel <> nil then
      Inc(FStepWithModel);
  end;
  Msg.LayeredModel.Free;   // the callee owns it

  if FRaiseOnProgress then
    raise ETestProgressAbort.Create('the callee blew up after freeing the model');
end;

function TTestLFPSOProgress.MakeCalcParams: TCalcThreadParams;
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

function TTestLFPSOProgress.MakeFitParams: TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax        := 15;
  Result.Pop         := 8;
  Result.Tolerance   := 0;      // never stop early
  Result.Vmax        := 0.3;
  Result.JammingMax  := 100;    // out of reach in fifteen iterations
  Result.ReInitMax   := 3;
  Result.KChiSqr     := 1.5;
  Result.KVmax       := 1.2;
  Result.w1          := 0.4;
  Result.w2          := 0.5;
  Result.Ksxr        := 0.1;
  Result.ThetaWeight := 0;
  Result.Shake       := False;
  Result.AdaptVel    := False;
  Result.RangeSeed   := False;
end;

function TTestLFPSOProgress.MakeStructure: TFitStructure;
begin
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].ID := 0;
  Result.Stacks[0].N  := N_PERIODS;
  SetLength(Result.Stacks[0].Layers, 2);

  Result.Stacks[0].Layers[0].Material := 'Si';
  Result.Stacks[0].Layers[0].StackID  := 0;
  Result.Stacks[0].Layers[0].LayerID  := 0;
  Result.Stacks[0].Layers[0].P[1].V   := INIT_H1;
  Result.Stacks[0].Layers[0].P[1].min := 20.0;
  Result.Stacks[0].Layers[0].P[1].max := 55.0;
  Result.Stacks[0].Layers[0].P[2].V   := INIT_S1;
  Result.Stacks[0].Layers[0].P[2].min := 0.5;
  Result.Stacks[0].Layers[0].P[2].max := 6.0;
  Result.Stacks[0].Layers[0].P[3].V   := INIT_R1;
  Result.Stacks[0].Layers[0].P[3].min := 1.5;
  Result.Stacks[0].Layers[0].P[3].max := 3.5;

  Result.Stacks[0].Layers[1].Material := 'Mo';
  Result.Stacks[0].Layers[1].StackID  := 0;
  Result.Stacks[0].Layers[1].LayerID  := 1;
  Result.Stacks[0].Layers[1].P[1].V   := INIT_H2;
  Result.Stacks[0].Layers[1].P[1].min := 5.0;
  Result.Stacks[0].Layers[1].P[1].max := 40.0;
  Result.Stacks[0].Layers[1].P[2].V   := INIT_S2;
  Result.Stacks[0].Layers[1].P[2].min := 0.5;
  Result.Stacks[0].Layers[1].P[2].max := 6.0;
  Result.Stacks[0].Layers[1].P[3].V   := INIT_R2;
  Result.Stacks[0].Layers[1].P[3].min := 8.0;
  Result.Stacks[0].Layers[1].P[3].max := 12.0;

  Result.Subs.Material := 'Si';
  Result.Subs.P[1].New(0);
  Result.Subs.P[2].New(SUB_S);
  Result.Subs.P[3].New(SUB_R);
end;

function TTestLFPSOProgress.MakeExpData(const ACalcParams: TCalcThreadParams): TDataArray;
var
  Calc: TCalc;
  Model: TLayeredModel;
begin
  Model := BuildTrueModel;
  Calc := TCalc.Create;
  try
    Calc.MaxThreads := 1;         // N div NThreads must come out exact
    Calc.Params := ACalcParams;
    Calc.Limit  := 1E-7;
    Calc.Model  := Model;
    Calc.Run;
    Result := Copy(Calc.Results);
  finally
    Calc.Model := nil;            // the model is ours to free
    Calc.Free;
    Model.Free;
  end;
end;

procedure TTestLFPSOProgress.RunFit(const ASeed: Integer;
  const AUseProgress: Boolean; out ABestChi: Single; out ABestCurve: TDataArray);
var
  PSO: TLFPSO_Periodic;
  CalcParams: TCalcThreadParams;
  S: TFitStructure;
begin
  CalcParams := MakeCalcParams;
  PSO := TLFPSO_Periodic.Create;
  try
    PSO.Params    := MakeFitParams;
    PSO.Limit     := 1E-7;
    PSO.ExpValues := MakeExpData(CalcParams);
    PSO.Seed      := ASeed;
    if AUseProgress then
      PSO.OnProgress := HandleProgress;
    S := MakeStructure;
    PSO.Structure := S;
    PSO.Run(CalcParams);
    ABestChi   := PSO.BestChiSquare;
    ABestCurve := Copy(PSO.BestCurve);
  finally
    PSO.Free;
  end;
end;


procedure TTestLFPSOProgress.Test_Seed_DefaultIsMinusOne;
var
  PSO: TLFPSO_Periodic;
begin
  PSO := TLFPSO_Periodic.Create;
  try
    Assert.AreEqual(-1, PSO.Seed,
      'a fresh engine must keep the GUI behaviour: Randomize, not a fixed seed');
  finally
    PSO.Free;
  end;
end;

procedure TTestLFPSOProgress.Test_OnProgress_IsCalledWithAFullModel;
var
  BestChi: Single;
  BestCurve: TDataArray;
begin
  if not TablesReady then
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);

  RunFit(TEST_SEED, True, BestChi, BestCurve);

  Assert.IsTrue(FFullCount > 0,
    'OnProgress must be called at least once with Full = True');
  Assert.AreEqual(FFullCount, FFullWithModel,
    'every Full update must carry a TLayeredModel for the callee to free');
  Assert.AreEqual(0, FStepWithModel,
    'a step update must carry no model');
  Assert.IsTrue(BestChi < 1E11,
    Format('the run must produce a real chi square, got %g', [BestChi]));
end;

procedure TTestLFPSOProgress.Test_Seed_SameSeedGivesSameBestChiSquare;
var
  Chi1, Chi2: Single;
  Curve1, Curve2: TDataArray;
begin
  if not TablesReady then
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);

  RunFit(TEST_SEED, False, Chi1, Curve1);
  RunFit(TEST_SEED, False, Chi2, Curve2);

  Assert.AreEqual(Single(Chi1), Single(Chi2), Single(0),
    Format('the same seed must give the same answer: %.10g vs %.10g', [Chi1, Chi2]));
end;

procedure TTestLFPSOProgress.Test_Seed_DifferentSeedsGiveDifferentAnswers;
var
  Chi1, Chi2: Single;
  Curve1, Curve2: TDataArray;
begin
  if not TablesReady then
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);

  RunFit(TEST_SEED, False, Chi1, Curve1);
  RunFit(OTHER_SEED, False, Chi2, Curve2);

  Assert.AreNotEqual(Single(Chi1), Single(Chi2), Single(0),
    Format('two seeds must not give the same answer: %.10g vs %.10g', [Chi1, Chi2]));
end;

procedure TTestLFPSOProgress.Test_Seed_PinnedBestChiSquare;
const
  PINNED_CHI: Single = 2.91917348;
var
  Chi: Single;
  Curve: TDataArray;
begin
  if not TablesReady then
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);
  RunFit(TEST_SEED, False, Chi, Curve);
  Assert.AreEqual(PINNED_CHI, Chi, Single(0),
    Format('the classic engine''s answer for seed %d moved: %.10g', [TEST_SEED, Chi]));
end;

{ The engine disposes the message record in a finally, so an exception out of
  the callee unwinds Run without stranding it. The callee frees the model before
  it raises, as the contract demands, so the suite must still end at 0 leaked. }
procedure TTestLFPSOProgress.Test_OnProgress_ThatRaises_LeaksNothing;
var
  BestChi: Single;
  BestCurve: TDataArray;
  Raised: Boolean;
begin
  if not TablesReady then
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);

  FRaiseOnProgress := True;
  Raised := False;
  try
    RunFit(TEST_SEED, True, BestChi, BestCurve);
  except
    on ETestProgressAbort do
      Raised := True;
  end;

  Assert.IsTrue(Raised, 'the exception must come out of Run, not be swallowed');
  Assert.AreEqual(1, FFullCount,
    'the very first update is a Full one, and it must have aborted the run');
  Assert.AreEqual(1, FFullWithModel, 'that update carried a model to free');
end;

procedure TTestLFPSOProgress.Test_BestCurve_IsNotEmptyAfterARun;
var
  BestChi: Single;
  BestCurve: TDataArray;
begin
  if not TablesReady then
    Assert.Pass('Henke tables for Si and Mo are not installed: ' + HENKE_DB_PATH);

  RunFit(TEST_SEED, False, BestChi, BestCurve);

  Assert.IsTrue(Length(BestCurve) > 0,
    'BestCurve must survive the iterations that do not improve');
  Assert.AreEqual(200, Length(BestCurve),
    'BestCurve must cover the whole measured grid');
end;


procedure TTerminateBeforeBestPSO.InitVelocity;
begin
  inherited;
  Terminate;
end;

procedure TTestLFPSOProgress.Test_StopBeforeFirstBest_DoesNotRaise;
var
  PSO: TTerminateBeforeBestPSO;
  CalcParams: TCalcThreadParams;
  S: TFitStructure;
begin
  if not TablesReady then
  begin
    Assert.Pass('Henke tables for Si/Mo are not installed');
    Exit;
  end;

  CalcParams := MakeCalcParams;
  PSO := TTerminateBeforeBestPSO.Create;
  try
    PSO.Params    := MakeFitParams;
    PSO.Limit     := 1E-7;
    PSO.ExpValues := MakeExpData(CalcParams);
    PSO.Seed      := 1;
    S := MakeStructure;
    PSO.Structure := S;

    PSO.Run(CalcParams);

    Assert.Pass('Run returned without raising');
  finally
    PSO.Free;
  end;
end;

procedure TTestLFPSOProgress.Test_Run_InvertedRange_RaisesBeforeFitting;
var
  PSO: TLFPSO_Periodic;
  CalcParams: TCalcThreadParams;
  S: TFitStructure;
  Data: TDataArray;
  Msg: string;
begin
  CalcParams := MakeCalcParams;
  SetLength(Data, 3);
  Data[0].t := 0.5; Data[0].r := 1;
  Data[1].t := 1.0; Data[1].r := 0.1;
  Data[2].t := 1.5; Data[2].r := 0.01;
  S := MakeStructure;
  S.Stacks[0].Layers[1].P[3].min := 12.0;
  S.Stacks[0].Layers[1].P[3].max := 8.0;
  PSO := TLFPSO_Periodic.Create;
  try
    PSO.Params    := MakeFitParams;
    PSO.Limit     := 1E-7;
    PSO.ExpValues := Data;
    PSO.Seed      := 1;
    PSO.Structure := S;
    Msg := '';
    try
      PSO.Run(CalcParams);
      Assert.Fail('Run accepted an inverted density range');
    except
      on E: EInvertedRange do
        Msg := E.Message;
    end;
    Assert.IsTrue(Pos('Mo', Msg) > 0, 'the message names the layer: ' + Msg);
    Assert.IsTrue(Pos('density', Msg) > 0, 'the message names the parameter: ' + Msg);
    Assert.IsTrue(Pos('12', Msg) > 0, 'the message quotes the bounds: ' + Msg);
  finally
    PSO.Free;
  end;
end;

end.
