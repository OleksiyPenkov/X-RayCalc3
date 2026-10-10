unit TestGpuCalc;


interface

uses
  DUnitX.TestFramework,
  System.SysUtils,
  unit_Types,
  unit_materials,
  unit_calc,
  unit_gpu_calc,
  unit_parratt_ref;

type
  [TestFixture]
  TTestGpuInputs = class
  private
    FSavedHenkeDir: string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure FinishRawCurve_GivesTheCurveRunGives;
    [Test] procedure GpuInputs_RebuildCalcChiSquare_EveryWeighting;
  end;

  [TestFixture]
  TTestGpuCalc = class
  private
    FSavedHenkeDir: string;
    function Ready: Boolean;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure RawCurve_MatchesDoublePrecision_EveryRoughnessAndPolarisation;
    [Test] procedure CpuRawCurve_CloseToDoublePrecision;
    [Test] procedure GpuRawCurve_CloseToDoublePrecision;
    [Test] procedure Chi_MatchesTheCpuEngine_EveryWeighting;
    [Test] procedure Chi_MatchesTheCpuEngine_WithTheScaleSolved;
    [Test] procedure Chi_ScaleSolved_OnePointOutweighingTheRest_IsNotRoundingNoise;
    [Test] procedure SplitDispatches_GiveTheSameAnswer;
    [Test] procedure Fit_OnTheGpu_ImprovesAndNamesTheDevice;
    [Test] procedure Fit_WithoutUseGpu_StaysOnTheCpu;
    [Test] procedure Fit_GpuFailsMidRun_FinishesOnTheCpu;
    [Test] procedure Fit_ParticleBuildFails_OnTheGpu_FallsBackToTheCpu;
    [Test] procedure Fit_ParticleBuildFails_OnTheCpu_RaisesInsteadOfHanging;

    [Test] procedure LogLik_MatchesCurveLikelihood_OnTheGpuCurve;
    [Test] procedure LogLik_SplitDispatches_GiveTheSameAnswer;
    [Test] procedure LogLik_LeavesTheClassicChiUnchanged;
    [Test] procedure LogLik_BeforeSetupLikelihood_Raises;
    [Test] procedure PackModelLayers_MatchesPack;

    [Test] procedure SelfCheck_PassesWithPrecise;
    [Test] procedure SelfCheck_FallsBackToIeeeStrict;
    [Test] procedure SelfCheck_BothFail_GpuUnavailable;
    [Test] procedure DescribeServer_ReportsGpuShaderAndSelfCheck;
  end;

implementation

uses
  System.Math,
  System.IOUtils,
  System.Classes,
  System.SyncObjs,
  System.JSON,
  Winapi.Windows,
  unit_otl_drain,
  unit_Config,
  unit_LFPSO_Base,
  unit_LFPSO_Periodic,
  unit_Likelihood,
  unit_MCPTools,
  unit_ToolsReference;

const
  HENKE_DB_PATH = 'd:\SoftwareStorage\X-RayCalc3\Henke';
  CU_KA = 1.5406;
  LIMIT = 1E-7;
  N_PERIODS = 20;

function HenkeReady: Boolean;
begin
  Result := TFile.Exists(TPath.Combine(HENKE_DB_PATH, 'Si.bin')) and
            TFile.Exists(TPath.Combine(HENKE_DB_PATH, 'W.bin')) and
            TFile.Exists(TPath.Combine(HENKE_DB_PATH, 'Mo.bin'));
end;

procedure FillModel(Model: TLayeredModel; Jitter, Sigma: Single);
var
  Data, SubData: TLayersData;
  j: Integer;
begin
  Model.Reset;
  SetLength(Data, 2);
  Data[0].Material := 'Si';
  Data[0].P[1].New(25 * (1 + Jitter));
  Data[0].P[2].New(Sigma * (1 + 2 * Jitter));
  Data[0].P[3].New(2.33);
  Data[0].StackID := 0; Data[0].LayerID := 0;
  Data[1].Material := 'W';
  Data[1].P[1].New(12 * (1 - Jitter));
  Data[1].P[2].New(Sigma);
  Data[1].P[3].New(19.3 * (1 - Jitter));
  Data[1].StackID := 0; Data[1].LayerID := 1;
  for j := 1 to N_PERIODS do
    Model.AddLayers(-1, Data, 2);
  SetLength(SubData, 1);
  SubData[0].Material := 'Si';
  SubData[0].P[1].New(0);
  SubData[0].P[2].New(Sigma);
  SubData[0].P[3].New(2.33);
  Model.AddSubstrate(SubData);
end;

function CalcParams(DT: Single; Pol: TPolarisation; RF: TRoughnessFunction): TCalcThreadParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Mode   := cmTheta;
  Result.RF     := RF;
  Result.P      := Pol;
  Result.K      := 1;
  Result.N      := 1000;
  Result.StartT := 0.1;
  Result.EndT   := 4.0;
  Result.DT     := DT;
  Result.MVAWindow := 10;
  Result.Lambda := CU_KA;
end;

function MakeData(DT: Single; Pol: TPolarisation; RF: TRoughnessFunction;
  Sigma: Single): TDataArray;
var
  Calc: TCalc;
  Model: TLayeredModel;
begin
  Model := TLayeredModel.Create;
  Model.Init;
  Calc := TCalc.Create;
  try
    FillModel(Model, 0, Sigma);
    Calc.MaxThreads := 1;
    Calc.Params := CalcParams(DT, Pol, RF);
    Calc.Limit := LIMIT;
    Calc.Model := Model;
    Calc.Run;
    Result := Copy(Calc.Results);
  finally
    Calc.Model := nil;
    Calc.Free;
    Model.Free;
  end;
end;

{ A moving average under which every third point stands five times above its
  neighbours, so that the peak weight (ratio > 3) applies to a third of the
  points. }
function PeakyMovAvg(const Data: TDataArray): TDataArray;
var
  i: Integer;
begin
  Result := Copy(Data);
  for i := 0 to High(Result) do
    if i mod 3 = 0 then
      Result[i].r := Data[i].r / 5;
end;

function NewCalc(const Data, MovAvg: TDataArray; DT: Single; Pol: TPolarisation;
  RF: TRoughnessFunction): TCalc;
begin
  Result := TCalc.Create;
  Result.MaxThreads := 1;
  Result.Params := CalcParams(DT, Pol, RF);
  Result.ExpValues := Data;
  Result.MovAvg := MovAvg;
  Result.Limit := LIMIT;
end;

function RawOnCpu(Model: TLayeredModel; const Data: TDataArray; Pol: TPolarisation;
  RF: TRoughnessFunction): TArray<Single>;
var
  Calc: TCalc;
  i: Integer;
begin
  Calc := NewCalc(Data, nil, 0, Pol, RF);
  try
    Calc.Model := Model;
    Calc.Run;
    SetLength(Result, Length(Data));
    for i := 0 to High(Data) do
      Result[i] := Calc.Results[i].r;
  finally
    Calc.Model := nil;
    Calc.Free;
  end;
end;

procedure Pack(Model: TLayeredModel; var Buf: TArray<Single>; Particle: Integer);
var
  L: TCalcLayers;
  k, Base: Integer;
begin
  L := Model.LayersDirect;
  Base := 4 * Length(L) * Particle;
  for k := 0 to High(L) do
  begin
    Buf[Base + 4 * k]     := L[k].delta;
    Buf[Base + 4 * k + 1] := L[k].e.Im;
    Buf[Base + 4 * k + 2] := L[k].L;
    Buf[Base + 4 * k + 3] := L[k].s;
  end;
end;

function Jitter(p: Integer): Single;
begin
  Result := 0.04 * ((p mod 9) / 8 - 0.5);
end;

const
  LIK_NMIN = 10;
  LIK_FMIN = 0.01;

{ Counts for Data at a peak rate of 1e6, so that the high-angle points fall
  below LIK_NMIN; point 5 has no count and point 7 has three. }
function LikCounts(const Data: TDataArray): TArray<Double>;
var
  i: Integer;
begin
  SetLength(Result, Length(Data));
  for i := 0 to High(Data) do
    Result[i] := Round(Data[i].r * 1E6);
  Result[5] := 0;
  Result[7] := 3;
end;

function LikNuisance(p: Integer): TNuisance;
begin
  Result.LogScale := 0.02 * (p - 4);
  Result.Background := 1E-8 * p;
  Result.F := LIK_FMIN + 0.01 * p;
end;

function NuisanceBuffer(Count: Integer): TArray<Single>;
var
  p: Integer;
  N: TNuisance;
begin
  SetLength(Result, 4 * Count);
  for p := 0 to Count - 1 do
  begin
    N := LikNuisance(p);
    Result[4 * p]     := Power(10, N.LogScale);
    Result[4 * p + 1] := N.Background;
    Result[4 * p + 2] := Sqr(N.F);
    Result[4 * p + 3] := 0;
  end;
end;

{ The kernel's per-point inputs, written by hand from CurveLikelihood's rule.
  An excluded point carries a NaN ln D: if the kernel ever read one, that
  particle's cost would come back NaN. }
function LikInputs(const Data: TDataArray; const Counts: TArray<Double>): TGpuLikInputs;
var
  i: Integer;
  Used: Boolean;
begin
  SetLength(Result.LnData, Length(Data));
  SetLength(Result.InvN, Length(Data));
  for i := 0 to High(Data) do
  begin
    if Length(Counts) > 0 then
      Used := (Counts[i] > 0) and (Counts[i] >= LIK_NMIN) and (Data[i].r > 0)
    else
      Used := Data[i].r > 0;
    if Used then
    begin
      Result.LnData[i] := Ln(Data[i].r);
      if Length(Counts) > 0 then
        Result.InvN[i] := 1 / Counts[i]
      else
        Result.InvN[i] := 0;
    end
    else
    begin
      Result.LnData[i] := NaN;
      Result.InvN[i] := -1;
    end;
  end;
  Result.FMin2 := Sqr(LIK_FMIN);
end;


function ParrattDouble(const L: TCalcLayers; ThetaDeg: Double; SP: Boolean;
  RF: TRoughnessFunction): Double;
begin
  Result := Max(ParrattRef(L, ThetaDeg, CU_KA, SP, RF), LIMIT);
end;


procedure TTestGpuInputs.Setup;
begin
  FSavedHenkeDir := TConfig.Section<TPathOptions>.HenkeDir;
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;
end;

procedure TTestGpuInputs.TearDown;
begin
  TConfig.Section<TPathOptions>.HenkeDir := FSavedHenkeDir;
end;

procedure TTestGpuInputs.FinishRawCurve_GivesTheCurveRunGives;
var
  Data: TDataArray;
  Model: TLayeredModel;
  Ran, Finished: TCalc;
  Raw: TArray<Single>;
  i: Integer;
begin
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH);

  Data := MakeData(0.01, cmS, rfError, 3);
  Model := TLayeredModel.Create;
  Model.Init;
  Ran := NewCalc(Data, nil, 0.01, cmS, rfError);
  Finished := NewCalc(Data, nil, 0.01, cmS, rfError);
  try
    FillModel(Model, 0.01, 3);
    Ran.Model := Model;
    Ran.Run;
    Raw := RawOnCpu(Model, Data, cmS, rfError);
    Finished.FinishRawCurve(Raw);
    Assert.AreEqual(Length(Ran.Results), Length(Finished.Results));
    for i := 0 to High(Data) do
    begin
      Assert.AreEqual(Ran.Results[i].t, Finished.Results[i].t, 'angle ' + IntToStr(i));
      Assert.AreEqual(Ran.Results[i].r, Finished.Results[i].r, 'R at point ' + IntToStr(i));
    end;
    Assert.AreEqual(Ran.CalcChiSquare(0), Finished.CalcChiSquare(0), 'the same chi2');
  finally
    Ran.Model := nil;
    Ran.Free;
    Finished.Free;
    Model.Free;
  end;
end;

procedure TTestGpuInputs.GpuInputs_RebuildCalcChiSquare_EveryWeighting;
var
  Data, Avg: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  In_: TGpuEvalInputs;
  tw, i, k, Case_: Integer;
  DT: Single;
  UsePeak: Boolean;
  Sum, r, lr, d, Chi: Double;
begin
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH);

  Model := TLayeredModel.Create;
  Model.Init;
  try
    for Case_ := 0 to 3 do
    begin
      if Case_ and 1 = 1 then DT := 0.01 else DT := 0;
      UsePeak := Case_ and 2 = 2;
      Data := MakeData(DT, cmS, rfError, 3);
      if UsePeak then Avg := PeakyMovAvg(Data) else Avg := nil;
      for tw := 0 to 5 do
      begin
        Calc := NewCalc(Data, Avg, DT, cmS, rfError);
        try
          FillModel(Model, 0.015, 3);
          Calc.Model := Model;
          Calc.Run;
          Chi := Calc.CalcChiSquare(tw);

          In_ := Calc.GpuInputs(tw);
          Sum := 0;
          for i := In_.ChiFirst to In_.ChiLast do
          begin
            r := Calc.Results[i].r;
            lr := Log10(r);
            d := (In_.LogData[i] - lr) / lr;
            Sum := Sum + d * d * In_.PointWeight[i];
          end;
          Assert.AreEqual(Chi, Sum * In_.ChiNorm, 1E-4 * Chi,
            Format('DT %g, peak weight %s, theta weight %d', [DT, BoolToStr(UsePeak, True), tw]));

          if DT = 0 then
            Assert.AreEqual(0, In_.ConvN, 'no resolution, no window')
          else
          begin
            Assert.IsTrue(In_.ConvN > 0, 'a resolution has a window');
            Assert.AreEqual(2 * In_.ConvN + 1, Length(In_.ConvWeights));
            r := 0;
            for k := 0 to High(In_.ConvWeights) do
              r := r + In_.ConvWeights[k];
            Assert.AreEqual(1.0, r, 0.02, 'the window integrates to about 1');
          end;
        finally
          Calc.Model := nil;
          Calc.Free;
        end;
      end;
    end;
  finally
    Model.Free;
  end;
end;


procedure TTestGpuCalc.Setup;
begin
  FSavedHenkeDir := TConfig.Section<TPathOptions>.HenkeDir;
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;
end;

procedure TTestGpuCalc.TearDown;
begin
  TConfig.Section<TPathOptions>.HenkeDir := FSavedHenkeDir;
end;

function TTestGpuCalc.Ready: Boolean;
var
  Name, Err: string;
begin
  Result := False;
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH)
  else if not TGpuEvaluator.Available(Name, Err) then
    Assert.Pass('No usable GPU on this machine: ' + Err)
  else
    Result := True;
end;

procedure TTestGpuCalc.RawCurve_MatchesDoublePrecision_EveryRoughnessAndPolarisation;
const
  PARTICLES = 3;
var
  RF: TRoughnessFunction;
  Pol: TPolarisation;
  Sigma: Single;
  Data: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Layers, Chi, Raw: TArray<Single>;
  Lay: TCalcLayers;
  p, i, NLay: Integer;
  Ref, d, Mean, Worst: Double;
  What: string;
begin
  if not Ready then Exit;

  Model := TLayeredModel.Create;
  Model.Init;
  try
    for RF := rfError to rfSinus do
      for Pol := cmS to cmSP do
      begin
        Sigma := 3;
        What := Format('roughness %d, polarisation %d', [Ord(RF), Ord(Pol)]);
        Data := MakeData(0, Pol, RF, Sigma);
        Calc := NewCalc(Data, nil, 0, Pol, RF);
        G := TGpuEvaluator.Create;
        try
          FillModel(Model, 0, Sigma);
          Model.Generate(CU_KA);
          NLay := Length(Model.LayersDirect);
          G.Setup(Calc.GpuInputs(0), NLay, PARTICLES, Pol, RF, CU_KA, 1, LIMIT);
          SetLength(Layers, 4 * NLay * PARTICLES);
          for p := 0 to PARTICLES - 1 do
          begin
            FillModel(Model, Jitter(p), Sigma);
            Model.Generate(CU_KA);
            Pack(Model, Layers, p);
          end;
          G.Evaluate(Layers, Chi);

          for p := 0 to PARTICLES - 1 do
          begin
            FillModel(Model, Jitter(p), Sigma);
            Model.Generate(CU_KA);
            Lay := Copy(Model.LayersDirect);
            Raw := G.RawCurve(p);
            Mean := 0;
            Worst := 0;
            for i := 0 to High(Data) do
            begin
              Ref := ParrattDouble(Lay, Data[i].t, Pol = cmSP, RF);
              d := Abs(Log10(Raw[i] / Ref));
              Mean := Mean + d;
              Worst := Max(Worst, d);
            end;
            Mean := Mean / Length(Data);
            Assert.IsTrue(Mean < 3E-3, Format('%s, particle %d: mean |log10 R/R_ref| %.2e',
              [What, p, Mean]));
            Assert.IsTrue(Worst < 0.1, Format('%s, particle %d: worst |log10 R/R_ref| %.2e',
              [What, p, Worst]));
          end;
        finally
          G.Free;
          Calc.Free;
        end;
      end;
  finally
    Model.Free;
  end;
end;

{ MeanBound = Sqrt(2.537E-5 x 5.927E-6) = 1.226E-5, rounded to 1.2E-5;
  WorstBound = Sqrt(5.440E-4 x 7.802E-5) = 2.060E-4, rounded to 2.0E-4.
  Each sits between the baseline and exact-math results, so it catches a
  regression to either the phase-only or the fully-unrefined form. }
procedure TTestGpuCalc.CpuRawCurve_CloseToDoublePrecision;
const
  PARTICLES = 3;
var
  RF: TRoughnessFunction;
  Pol: TPolarisation;
  Sigma: Single;
  Data: TDataArray;
  Model: TLayeredModel;
  Cpu: TArray<Single>;
  Lay: TCalcLayers;
  p, i: Integer;
  Ref, MeanCpu, WorstCpu: Double;
  What: string;
begin
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH);

  Model := TLayeredModel.Create;
  Model.Init;
  try
    for RF := rfError to rfSinus do
      for Pol := cmS to cmSP do
      begin
        Sigma := 3;
        What := Format('roughness %d, polarisation %d', [Ord(RF), Ord(Pol)]);
        Data := MakeData(0, Pol, RF, Sigma);
        for p := 0 to PARTICLES - 1 do
        begin
          FillModel(Model, Jitter(p), Sigma);
          Model.Generate(CU_KA);
          Lay := Copy(Model.LayersDirect);
          Cpu := RawOnCpu(Model, Data, Pol, RF);
          MeanCpu := 0;
          WorstCpu := 0;
          for i := 0 to High(Data) do
          begin
            Ref := ParrattDouble(Lay, Data[i].t, Pol = cmSP, RF);
            MeanCpu := MeanCpu + Abs(System.Math.Log10(Cpu[i] / Ref));
            WorstCpu := Max(WorstCpu, Abs(System.Math.Log10(Cpu[i] / Ref)));
          end;
          MeanCpu := MeanCpu / Length(Data);
          Assert.IsTrue(MeanCpu < 1.2E-5, Format('%s, particle %d: CPU mean %.2e',
            [What, p, MeanCpu]));
          Assert.IsTrue(WorstCpu < 2.0E-4, Format('%s, particle %d: CPU worst %.2e',
            [What, p, WorstCpu]));
        end;
      end;
  finally
    Model.Free;
  end;
end;

procedure TTestGpuCalc.GpuRawCurve_CloseToDoublePrecision;
const
  PARTICLES = 3;
  MEAN_BOUND = 1.2E-5;
  WORST_BOUND = 2.7E-4;
  AGREE_MEAN_BOUND = 1.9E-5;
  AGREE_WORST_BOUND = 3.0E-4;
var
  RF: TRoughnessFunction;
  Pol: TPolarisation;
  Sigma: Single;
  Data: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Layers, Chi, Raw, Cpu: TArray<Single>;
  Lay: TCalcLayers;
  p, i, NLay: Integer;
  Ref, d, Mean, Worst, AgreeMean, AgreeWorst: Double;
  What: string;
begin
  if not Ready then Exit;

  Model := TLayeredModel.Create;
  Model.Init;
  try
    for RF := rfError to rfSinus do
      for Pol := cmS to cmSP do
      begin
        Sigma := 3;
        What := Format('roughness %d, polarisation %d', [Ord(RF), Ord(Pol)]);
        Data := MakeData(0, Pol, RF, Sigma);
        Calc := NewCalc(Data, nil, 0, Pol, RF);
        G := TGpuEvaluator.Create;
        try
          FillModel(Model, 0, Sigma);
          Model.Generate(CU_KA);
          NLay := Length(Model.LayersDirect);
          G.Setup(Calc.GpuInputs(0), NLay, PARTICLES, Pol, RF, CU_KA, 1, LIMIT);
          SetLength(Layers, 4 * NLay * PARTICLES);
          for p := 0 to PARTICLES - 1 do
          begin
            FillModel(Model, Jitter(p), Sigma);
            Model.Generate(CU_KA);
            Pack(Model, Layers, p);
          end;
          G.Evaluate(Layers, Chi);

          for p := 0 to PARTICLES - 1 do
          begin
            FillModel(Model, Jitter(p), Sigma);
            Model.Generate(CU_KA);
            Lay := Copy(Model.LayersDirect);
            Raw := G.RawCurve(p);
            Cpu := RawOnCpu(Model, Data, Pol, RF);
            Mean := 0;
            Worst := 0;
            AgreeMean := 0;
            AgreeWorst := 0;
            for i := 0 to High(Data) do
            begin
              Ref := ParrattDouble(Lay, Data[i].t, Pol = cmSP, RF);
              d := Abs(System.Math.Log10(Raw[i] / Ref));
              Mean := Mean + d;
              Worst := Max(Worst, d);
              d := Abs(System.Math.Log10(Raw[i] / Cpu[i]));
              AgreeMean := AgreeMean + d;
              AgreeWorst := Max(AgreeWorst, d);
            end;
            Mean := Mean / Length(Data);
            AgreeMean := AgreeMean / Length(Data);
            Assert.IsTrue(Mean < MEAN_BOUND, Format('%s, particle %d: GPU mean |log10 R/R_ref| %.2e',
              [What, p, Mean]));
            Assert.IsTrue(Worst < WORST_BOUND, Format('%s, particle %d: GPU worst |log10 R/R_ref| %.2e',
              [What, p, Worst]));
            Assert.IsTrue(AgreeMean < AGREE_MEAN_BOUND, Format('%s, particle %d: GPU/CPU mean ' +
              'disagreement %.2e', [What, p, AgreeMean]));
            Assert.IsTrue(AgreeWorst < AGREE_WORST_BOUND, Format('%s, particle %d: GPU/CPU worst ' +
              'disagreement %.2e', [What, p, AgreeWorst]));
          end;
        finally
          G.Free;
          Calc.Free;
        end;
      end;
  finally
    Model.Free;
  end;
end;

procedure TTestGpuCalc.Chi_MatchesTheCpuEngine_EveryWeighting;
const
  PARTICLES = 9;
var
  Data, Avg: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Layers, Chi: TArray<Single>;
  p, tw, NLay, Case_: Integer;
  DT, CpuChi: Single;
  Pol: TPolarisation;
begin
  if not Ready then Exit;

  Model := TLayeredModel.Create;
  Model.Init;
  try
    for Case_ := 0 to 3 do
    begin
      if Case_ and 1 = 1 then DT := 0.01 else DT := 0;
      if Case_ and 2 = 2 then Pol := cmSP else Pol := cmS;
      Data := MakeData(DT, Pol, rfError, 3);
      Avg := PeakyMovAvg(Data);
      for tw := 0 to 5 do
      begin
        Calc := NewCalc(Data, Avg, DT, Pol, rfError);
        G := TGpuEvaluator.Create;
        try
          FillModel(Model, 0, 3);
          Model.Generate(CU_KA);
          NLay := Length(Model.LayersDirect);
          G.Setup(Calc.GpuInputs(tw), NLay, PARTICLES, Pol, rfError, CU_KA, 1, LIMIT);
          SetLength(Layers, 4 * NLay * PARTICLES);
          for p := 0 to PARTICLES - 1 do
          begin
            FillModel(Model, Jitter(p), 3);
            Model.Generate(CU_KA);
            Pack(Model, Layers, p);
          end;
          G.Evaluate(Layers, Chi);

          Calc.Model := Model;
          for p := 0 to PARTICLES - 1 do
          begin
            FillModel(Model, Jitter(p), 3);
            Calc.Run;
            CpuChi := Calc.CalcChiSquare(tw);
            { Particle 4 is the measurement itself: the CPU scores 0 against
              its own rounding, the GPU a small positive number. }
            if p = 4 then
              Assert.IsTrue(Chi[p] < 0.02 * Chi[0],
                Format('the true model scores near zero: %g (particle 0: %g)', [Chi[p], Chi[0]]))
            else
              Assert.AreEqual(CpuChi, Chi[p], 0.03 * CpuChi,
                Format('DT %g, pol %d, theta weight %d, particle %d', [DT, Ord(Pol), tw, p]));
          end;
          Calc.Model := nil;
        finally
          G.Free;
          Calc.Model := nil;
          Calc.Free;
        end;
      end;
    end;
  finally
    Model.Free;
  end;
end;

procedure TTestGpuCalc.SplitDispatches_GiveTheSameAnswer;
const
  PARTICLES = 50;
var
  Data: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  Whole, Split: TGpuEvaluator;
  Layers, ChiWhole, ChiSplit, RawWhole, RawSplit: TArray<Single>;
  p, NLay, i: Integer;
begin
  if not Ready then Exit;

  Data := MakeData(0.01, cmS, rfError, 3);
  Model := TLayeredModel.Create;
  Model.Init;
  Calc := NewCalc(Data, nil, 0.01, cmS, rfError);
  Whole := TGpuEvaluator.Create;
  Split := TGpuEvaluator.Create;
  try
    FillModel(Model, 0, 3);
    Model.Generate(CU_KA);
    NLay := Length(Model.LayersDirect);
    Whole.Setup(Calc.GpuInputs(0), NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
    Split.StepsPerDispatch := Int64(7) * NLay * Length(Data);
    Split.Setup(Calc.GpuInputs(0), NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
    Assert.AreEqual(7, Split.ParticlesPerDispatch);

    SetLength(Layers, 4 * NLay * PARTICLES);
    for p := 0 to PARTICLES - 1 do
    begin
      FillModel(Model, Jitter(p), 3);
      Model.Generate(CU_KA);
      Pack(Model, Layers, p);
    end;
    Whole.Evaluate(Layers, ChiWhole);
    Split.Evaluate(Layers, ChiSplit);
    for p := 0 to PARTICLES - 1 do
      Assert.AreEqual(ChiWhole[p], ChiSplit[p], 'chi2 of particle ' + IntToStr(p));
    RawWhole := Whole.RawCurve(PARTICLES - 1);
    RawSplit := Split.RawCurve(PARTICLES - 1);
    for i := 0 to High(RawWhole) do
      Assert.AreEqual(RawWhole[i], RawSplit[i], 'last particle, point ' + IntToStr(i));
  finally
    Split.Free;
    Whole.Free;
    Calc.Free;
    Model.Free;
  end;
end;

function FitParams(Pop, NMax: Integer): TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax := NMax;         Result.Pop := Pop;
  Result.Tolerance := 0;       Result.Vmax := 0.3;
  Result.JammingMax := 100;    Result.ReInitMax := 3;
  Result.KChiSqr := 1.5;       Result.KVmax := 1.2;
  Result.w1 := 0.4;            Result.w2 := 0.5;
  Result.Ksxr := 0.1;
end;

function FitStructure: TFitStructure;

  procedure SetP(var P: TFitValue; V, AMin, AMax: Single);
  begin
    P.V := V; P.min := AMin; P.max := AMax;
  end;

begin
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].ID := 0;
  Result.Stacks[0].N  := N_PERIODS;
  SetLength(Result.Stacks[0].Layers, 2);
  with Result.Stacks[0].Layers[0] do
  begin
    Material := 'Si'; StackID := 0; LayerID := 0;
    SetP(P[1], 26.5, 20, 30);
    SetP(P[2], 2.5, 0.5, 6);
    SetP(P[3], 2.33, 2.33, 2.33);
  end;
  with Result.Stacks[0].Layers[1] do
  begin
    Material := 'W'; StackID := 0; LayerID := 1;
    SetP(P[1], 10.5, 8, 15);
    SetP(P[2], 2.5, 0.5, 6);
    SetP(P[3], 19.3, 19.3, 19.3);
  end;
  Result.Subs.Material := 'Si';
  Result.Subs.P[1].New(0);
  Result.Subs.P[2].New(3);
  Result.Subs.P[3].New(2.33);
end;

function RunFit(UseGPU: Boolean; out Device, GpuError: string;
  out BestChi: Single; out BestCurve: TDataArray; out Data: TDataArray): TLayeredModel;
var
  PSO: TLFPSO_Periodic;
begin
  Data := MakeData(0.01, cmS, rfError, 3);
  PSO := TLFPSO_Periodic.Create;
  try
    PSO.Params := FitParams(40, 15);
    PSO.Limit := LIMIT;
    PSO.ExpValues := Data;
    PSO.Seed := 7;
    PSO.UseGPU := UseGPU;
    PSO.Structure := FitStructure;
    PSO.Run(CalcParams(0.01, cmS, rfError));
    Device := PSO.DeviceUsed;
    GpuError := PSO.GpuError;
    BestChi := PSO.BestChiSquare;
    BestCurve := Copy(PSO.BestCurve);
    Result := PSO.Result;
  finally
    PSO.Free;
  end;
end;

procedure TTestGpuCalc.Fit_OnTheGpu_ImprovesAndNamesTheDevice;
var
  Device, Err, Name, ProbeErr: string;
  BestChi: Single;
  BestCurve, Data: TDataArray;
  Best, Start: TLayeredModel;
  Calc: TCalc;
  StartChi, CpuChiOfBest: Single;
  S: TFitStructure;
  j: Integer;
  Lay: TLayersData;
begin
  if not Ready then Exit;
  TGpuEvaluator.Available(Name, ProbeErr);

  Best := RunFit(True, Device, Err, BestChi, BestCurve, Data);
  Calc := NewCalc(Data, nil, 0.01, cmS, rfError);
  Start := TLayeredModel.Create;
  Start.Init;
  try
    Assert.AreEqual(Name, Device, 'the fit reports the GPU it ran on');
    Assert.AreEqual('', Err, 'and no GPU error');
    Assert.AreEqual(Length(Data), Length(BestCurve), 'the best curve is on the data''s angles');

    S := FitStructure;
    SetLength(Lay, 2);
    for j := 0 to 1 do
    begin
      Lay[j].Material := S.Stacks[0].Layers[j].Material;
      Lay[j].P := S.Stacks[0].Layers[j].P;
      Lay[j].StackID := 0;
      Lay[j].LayerID := j;
    end;
    Start.Reset;
    for j := 1 to N_PERIODS do
      Start.AddLayers(-1, Lay, 2);
    SetLength(Lay, 1);
    Lay[0].Material := S.Subs.Material;
    Lay[0].P := S.Subs.P;
    Start.AddSubstrate(Lay);
    Calc.Model := Start;
    Calc.Run;
    StartChi := Calc.CalcChiSquare(0);

    Calc.Model := Best;
    Calc.Run;
    CpuChiOfBest := Calc.CalcChiSquare(0);
    Assert.IsTrue(BestChi < 0.5 * StartChi,
      Format('the GPU fit improves on the start: %g against %g', [BestChi, StartChi]));
    Assert.AreEqual(CpuChiOfBest, BestChi, 0.05 * CpuChiOfBest + 1E-3,
      'the CPU engine agrees with the chi2 the GPU fit reports');
  finally
    Calc.Model := nil;
    Calc.Free;
    Start.Free;
    Best.Free;
  end;
end;

type
  { Raises from FillModel once, on its FailOn-th call, from whichever worker
    thread gets there - the failure OmniThreadLibrary's Parallel.For would
    otherwise swallow while the caller waits for ever. }
  TFailingPeriodic = class(TLFPSO_Periodic)
  private
    FCalls: Integer;
  protected
    procedure FillModel(Model: TLayeredModel; const Solution: TSolution); override;
  public
    FailOn: Integer;
  end;

  { Runs a fit on a thread of its own so that a hang fails the test instead of
    stopping the suite. }
  TFitThread = class(TThread)
  private
    FPSO: TLFPSO_BASE;
    FParams: TCalcThreadParams;
    FError: string;
  protected
    procedure Execute; override;
  end;

procedure TFailingPeriodic.FillModel(Model: TLayeredModel; const Solution: TSolution);
begin
  if TInterlocked.Increment(FCalls) = FailOn then
    raise EInvalidOp.Create('injected failure while building a particle');
  inherited;
end;

procedure TFitThread.Execute;
begin
  try
    FPSO.Run(FParams);
  except
    on E: Exception do
      FError := E.ClassName + ': ' + E.Message;
  end;
  DrainParallelTasksBeforeExit;
end;

{ Runs PSO on a thread; False when it has not finished within TimeoutMs (the
  thread is then left behind - the test has failed either way). }
function RunGuarded(PSO: TLFPSO_BASE; const P: TCalcThreadParams; TimeoutMs: Cardinal;
  out Error: string): Boolean;
var
  T: TFitThread;
begin
  T := TFitThread.Create(True);
  T.FPSO := PSO;
  T.FParams := P;
  T.Start;
  Result := WaitForSingleObject(T.Handle, TimeoutMs) = WAIT_OBJECT_0;
  if Result then
  begin
    Error := T.FError;
    T.Free;
  end
  else
    Error := 'timed out';
end;

function NewFailingFit(UseGPU: Boolean; FailOn: Integer; out Data: TDataArray): TFailingPeriodic;
begin
  Data := MakeData(0.01, cmS, rfError, 3);
  Result := TFailingPeriodic.Create;
  Result.Params := FitParams(40, 8);
  Result.Limit := LIMIT;
  Result.ExpValues := Data;
  Result.Seed := 7;
  Result.UseGPU := UseGPU;
  Result.Structure := FitStructure;
  Result.FailOn := FailOn;
end;

procedure TTestGpuCalc.Fit_GpuFailsMidRun_FinishesOnTheCpu;
var
  PSO: TLFPSO_Periodic;
  Data: TDataArray;
  Err: string;
begin
  if not Ready then Exit;
  Data := MakeData(0.01, cmS, rfError, 3);
  PSO := TLFPSO_Periodic.Create;
  TGpuEvaluator.FailAfter := 4;
  try
    PSO.Params := FitParams(40, 8);
    PSO.Limit := LIMIT;
    PSO.ExpValues := Data;
    PSO.Seed := 7;
    PSO.UseGPU := True;
    PSO.Structure := FitStructure;
    Assert.IsTrue(RunGuarded(PSO, CalcParams(0.01, cmS, rfError), 120000, Err),
      'the fit must finish');
    Assert.AreEqual('', Err, 'and without an exception');
    Assert.AreEqual('CPU', PSO.DeviceUsed, 'the last iterations ran on the CPU');
    Assert.Contains(PSO.GpuError, 'injected', 'the GPU''s failure is reported');
    Assert.AreEqual(Length(Data), Length(PSO.BestCurve), 'a best curve is there');
    Assert.IsTrue(PSO.BestChiSquare < 1E6, 'and a finite chi2');
  finally
    TGpuEvaluator.FailAfter := 0;
    PSO.Free;
  end;
end;

procedure TTestGpuCalc.Fit_ParticleBuildFails_OnTheGpu_FallsBackToTheCpu;
var
  PSO: TFailingPeriodic;
  Data: TDataArray;
  Err: string;
begin
  if not Ready then Exit;
  PSO := NewFailingFit(True, 100, Data);    // fails in the third iteration's build
  try
    Assert.IsTrue(RunGuarded(PSO, CalcParams(0.01, cmS, rfError), 120000, Err),
      'a particle that raises must not hang the fit');
    Assert.AreEqual('', Err, 'the GPU path falls back instead of failing the fit');
    Assert.AreEqual('CPU', PSO.DeviceUsed);
    Assert.Contains(PSO.GpuError, 'injected failure while building a particle');
    Assert.AreEqual(Length(Data), Length(PSO.BestCurve));
  finally
    PSO.Free;
  end;
end;

procedure TTestGpuCalc.Fit_ParticleBuildFails_OnTheCpu_RaisesInsteadOfHanging;
var
  PSO: TFailingPeriodic;
  Data: TDataArray;
  Err: string;
begin
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH);
  PSO := NewFailingFit(False, 100, Data);
  try
    Assert.IsTrue(RunGuarded(PSO, CalcParams(0.01, cmS, rfError), 120000, Err),
      'a particle that raises must not hang the fit');
    Assert.Contains(Err, 'injected failure while building a particle',
      'the CPU path reports the failure');
  finally
    PSO.Free;
  end;
end;

procedure TTestGpuCalc.Fit_WithoutUseGpu_StaysOnTheCpu;
var
  Device, Err: string;
  BestChi: Single;
  BestCurve, Data: TDataArray;
  Best: TLayeredModel;
begin
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH);
  Best := RunFit(False, Device, Err, BestChi, BestCurve, Data);
  try
    Assert.AreEqual('CPU', Device);
    Assert.AreEqual('', Err);
    Assert.AreEqual(Length(Data), Length(BestCurve));
  finally
    Best.Free;
  end;
end;

procedure TTestGpuCalc.Chi_MatchesTheCpuEngine_WithTheScaleSolved;
const
  PARTICLES = 9;
var
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Data, Avg: TDataArray;
  Layers, Chi: TArray<Single>;
  p, tw, NLay, i: Integer;
  CpuChi: Single;
begin
  if not Ready then Exit;

  Model := TLayeredModel.Create;
  Model.Init;
  try
    Data := MakeData(0, cmS, rfError, 3);
    for i := 0 to High(Data) do
      Data[i].r := Data[i].r * 1.3;
    Avg := PeakyMovAvg(Data);
    for tw := 0 to 1 do
    begin
      Calc := NewCalc(Data, Avg, 0, cmS, rfError);
      G := TGpuEvaluator.Create;
      try
        Calc.SolveScale := True;
        Calc.ScaleWindowLog := Log10(1.5);
        FillModel(Model, 0, 3);
        Model.Generate(CU_KA);
        NLay := Length(Model.LayersDirect);
        G.Setup(Calc.GpuInputs(tw), NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
        SetLength(Layers, 4 * NLay * PARTICLES);
        for p := 0 to PARTICLES - 1 do
        begin
          FillModel(Model, Jitter(p), 3);
          Model.Generate(CU_KA);
          Pack(Model, Layers, p);
        end;
        G.Evaluate(Layers, Chi);

        Calc.Model := Model;
        for p := 0 to PARTICLES - 1 do
        begin
          FillModel(Model, Jitter(p), 3);
          Calc.Run;
          CpuChi := Calc.CalcChiSquare(tw);
          if p = 4 then
          begin
            Assert.IsTrue(Chi[p] < 0.02 * Chi[0],
              Format('the true model scores near zero once the scale is solved: %g (particle 0: %g)', [Chi[p], Chi[0]]));
            Assert.AreEqual(-Log10(1.3), Double(Calc.ScaleLog), 0.01, 'the CPU solved the factor 1.3 away');
          end
          else
            Assert.AreEqual(CpuChi, Chi[p], 0.03 * CpuChi,
              Format('theta weight %d, particle %d', [tw, p]));
        end;
        Calc.Model := nil;
      finally
        G.Free;
        Calc.Model := nil;
        Calc.Free;
      end;
    end;
  finally
    Model.Free;
  end;
end;

{ A weight near 1E10 makes the solved-scale sum subtract terms near 1E9
  to obtain a result near 1E2, below Single precision. The heavy point is
  made here by its weight; the reference uses Double on the GPU's own curve. }
procedure TTestGpuCalc.Chi_ScaleSolved_OnePointOutweighingTheRest_IsNotRoundingNoise;
const
  HEAVY = 500;
var
  Data: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  In_: TGpuEvalInputs;
  Layers, Chi: TArray<Single>;
  NLay, i: Integer;
  S0, S1, S2, W, D, LR, A, Expected: Double;
begin
  if not Ready then Exit;

  Model := TLayeredModel.Create;
  Model.Init;
  Data := MakeData(0, cmS, rfError, 3);
  for i := 0 to High(Data) do
    Data[i].r := Data[i].r * 1.3;
  Calc := NewCalc(Data, nil, 0, cmS, rfError);
  G := TGpuEvaluator.Create;
  try
    Calc.SolveScale := True;
    Calc.ScaleWindowLog := Log10(1.5);
    FillModel(Model, 0.001, 3);
    Model.Generate(CU_KA);
    NLay := Length(Model.LayersDirect);
    In_ := Calc.GpuInputs(0);
    In_.PointWeight[HEAVY] := In_.PointWeight[HEAVY] * 1E14;
    G.Setup(In_, NLay, 1, cmS, rfError, CU_KA, 1, LIMIT);
    SetLength(Layers, 4 * NLay);
    Pack(Model, Layers, 0);
    G.Evaluate(Layers, Chi);

    Calc.FinishRawCurve(G.RawCurve(0));
    S0 := 0; S1 := 0; S2 := 0;
    for i := In_.ChiFirst to In_.ChiLast do
      if Calc.Results[i].r <> 0 then
      begin
        LR := Ln(Calc.Results[i].r) / Ln(10);
        W := In_.PointWeight[i] / Sqr(LR);
        D := In_.LogData[i] - LR;
        S2 := S2 + W * D * D;
        S1 := S1 + W * D;
        S0 := S0 + W;
      end;
    A := EnsureRange(-S1 / S0, -In_.ScaleWindow, In_.ScaleWindow);
    Expected := (S2 + 2 * A * S1 + A * A * S0) * In_.ChiNorm;
    Assert.IsTrue(S0 > 1E12, Format('the heavy point dominates: S0 = %g', [S0]));
    Assert.IsTrue(Expected > 0.01, Format('and the rest still disagrees: %g', [Expected]));
    Assert.AreEqual(Expected, Double(Chi[0]), 0.03 * Expected,
      Format('the GPU against the sum in Double (S0 = %g)', [S0]));
  finally
    G.Free;
    Calc.Model := nil;
    Calc.Free;
    Model.Free;
  end;
end;

{ Use the GPU's own curve as the Double reference to isolate likelihood
  convolution, exclusions and summation from Parratt's Single precision. }
procedure TTestGpuCalc.LogLik_MatchesCurveLikelihood_OnTheGpuCurve;
const
  PARTICLES = 9;
var
  Data, Curve: TDataArray;
  Counts: TArray<Double>;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Inputs: TGpuEvalInputs;
  Layers, Cost: TArray<Single>;
  p, NLay, Case_: Integer;
  DT: Single;
  Expected: Double;
begin
  if not Ready then Exit;

  Model := TLayeredModel.Create;
  Model.Init;
  try
    for Case_ := 0 to 3 do
    begin
      if Case_ and 1 = 1 then DT := 0.01 else DT := 0;
      Data := MakeData(DT, cmS, rfError, 3);
      if Case_ and 2 = 2 then
        Counts := LikCounts(Data)
      else
        Counts := nil;
      Calc := NewCalc(Data, nil, DT, cmS, rfError);
      G := TGpuEvaluator.Create;
      try
        FillModel(Model, 0, 3);
        Model.Generate(CU_KA);
        NLay := Length(Model.LayersDirect);
        Inputs := Calc.GpuInputs(0);
        G.Setup(Inputs, NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
        G.SetupLikelihood(LikInputs(Data, Counts));
        SetLength(Layers, 4 * NLay * PARTICLES);
        for p := 0 to PARTICLES - 1 do
        begin
          FillModel(Model, Jitter(p), 3);
          Model.Generate(CU_KA);
          PackModelLayers(Model.LayersDirect, Layers, p);
        end;
        G.EvaluateLikelihood(Layers, NuisanceBuffer(PARTICLES), Cost);
        Assert.AreEqual(PARTICLES, Integer(Length(Cost)));
        for p := 0 to PARTICLES - 1 do
        begin
          Calc.FinishRawCurve(G.RawCurve(p));
          Curve := Copy(Calc.Results);
          Expected := CurveLikelihood(Data, Curve, Counts, Inputs.ChiFirst, Inputs.ChiLast,
            LIK_NMIN, LikNuisance(p), LIK_FMIN).Cost;
          Assert.IsFalse(IsNan(Cost[p]),
            Format('case %d, particle %d: NaN - an excluded point was read', [Case_, p]));
          Assert.AreEqual(Expected, Double(Cost[p]), 2E-4 * Max(1, Abs(Expected)),
            Format('case %d (DT %g, counts %s), particle %d',
              [Case_, DT, BoolToStr(Length(Counts) > 0, True), p]));
        end;
      finally
        G.Free;
        Calc.Free;
      end;
    end;
  finally
    Model.Free;
  end;
end;

procedure TTestGpuCalc.LogLik_SplitDispatches_GiveTheSameAnswer;
const
  PARTICLES = 50;
var
  Data: TDataArray;
  Counts: TArray<Double>;
  Model: TLayeredModel;
  Calc: TCalc;
  Whole, Split: TGpuEvaluator;
  Layers, Nuis, CostWhole, CostSplit: TArray<Single>;
  p, NLay: Integer;
begin
  if not Ready then Exit;

  Data := MakeData(0.01, cmS, rfError, 3);
  Counts := LikCounts(Data);
  Model := TLayeredModel.Create;
  Model.Init;
  Calc := NewCalc(Data, nil, 0.01, cmS, rfError);
  Whole := TGpuEvaluator.Create;
  Split := TGpuEvaluator.Create;
  try
    FillModel(Model, 0, 3);
    Model.Generate(CU_KA);
    NLay := Length(Model.LayersDirect);
    Whole.Setup(Calc.GpuInputs(0), NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
    Whole.SetupLikelihood(LikInputs(Data, Counts));
    Split.StepsPerDispatch := Int64(7) * NLay * Length(Data);
    Split.Setup(Calc.GpuInputs(0), NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
    Split.SetupLikelihood(LikInputs(Data, Counts));
    Assert.AreEqual(7, Split.ParticlesPerDispatch);

    SetLength(Layers, 4 * NLay * PARTICLES);
    for p := 0 to PARTICLES - 1 do
    begin
      FillModel(Model, Jitter(p), 3);
      Model.Generate(CU_KA);
      PackModelLayers(Model.LayersDirect, Layers, p);
    end;
    Nuis := NuisanceBuffer(PARTICLES);
    Whole.EvaluateLikelihood(Layers, Nuis, CostWhole);
    Split.EvaluateLikelihood(Layers, Nuis, CostSplit);
    for p := 0 to PARTICLES - 1 do
      Assert.AreEqual(CostWhole[p], CostSplit[p], 'cost of particle ' + IntToStr(p));
  finally
    Split.Free;
    Whole.Free;
    Calc.Free;
    Model.Free;
  end;
end;

procedure TTestGpuCalc.LogLik_LeavesTheClassicChiUnchanged;
const
  PARTICLES = 9;
var
  Data: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Layers, Before, After, Cost: TArray<Single>;
  p, NLay: Integer;
begin
  if not Ready then Exit;

  Data := MakeData(0.01, cmS, rfError, 3);
  Model := TLayeredModel.Create;
  Model.Init;
  Calc := NewCalc(Data, PeakyMovAvg(Data), 0.01, cmS, rfError);
  G := TGpuEvaluator.Create;
  try
    FillModel(Model, 0, 3);
    Model.Generate(CU_KA);
    NLay := Length(Model.LayersDirect);
    G.Setup(Calc.GpuInputs(1), NLay, PARTICLES, cmS, rfError, CU_KA, 1, LIMIT);
    SetLength(Layers, 4 * NLay * PARTICLES);
    for p := 0 to PARTICLES - 1 do
    begin
      FillModel(Model, Jitter(p), 3);
      Model.Generate(CU_KA);
      PackModelLayers(Model.LayersDirect, Layers, p);
    end;
    G.Evaluate(Layers, Before);
    G.SetupLikelihood(LikInputs(Data, LikCounts(Data)));
    G.EvaluateLikelihood(Layers, NuisanceBuffer(PARTICLES), Cost);
    G.Evaluate(Layers, After);
    for p := 0 to PARTICLES - 1 do
      Assert.AreEqual(Before[p], After[p], 'chi2 of particle ' + IntToStr(p));
  finally
    G.Free;
    Calc.Free;
    Model.Free;
  end;
end;

procedure TTestGpuCalc.LogLik_BeforeSetupLikelihood_Raises;
var
  Data: TDataArray;
  Model: TLayeredModel;
  Calc: TCalc;
  G: TGpuEvaluator;
  Layers, Cost: TArray<Single>;
  NLay: Integer;
begin
  if not Ready then Exit;

  Data := MakeData(0, cmS, rfError, 3);
  Model := TLayeredModel.Create;
  Model.Init;
  Calc := NewCalc(Data, nil, 0, cmS, rfError);
  G := TGpuEvaluator.Create;
  try
    FillModel(Model, 0, 3);
    Model.Generate(CU_KA);
    NLay := Length(Model.LayersDirect);
    G.Setup(Calc.GpuInputs(0), NLay, 2, cmS, rfError, CU_KA, 1, LIMIT);
    SetLength(Layers, 4 * NLay * 2);
    PackModelLayers(Model.LayersDirect, Layers, 0);
    PackModelLayers(Model.LayersDirect, Layers, 1);
    Assert.WillRaise(
      procedure begin G.EvaluateLikelihood(Layers, NuisanceBuffer(2), Cost); end,
      EGpuError, 'no SetupLikelihood yet');
    G.SetupLikelihood(LikInputs(Data, nil));
    G.EvaluateLikelihood(Layers, NuisanceBuffer(2), Cost);
    G.Setup(Calc.GpuInputs(0), NLay, 2, cmS, rfError, CU_KA, 1, LIMIT);
    Assert.WillRaise(
      procedure begin G.EvaluateLikelihood(Layers, NuisanceBuffer(2), Cost); end,
      EGpuError, 'a new Setup needs a new SetupLikelihood');
  finally
    G.Free;
    Calc.Free;
    Model.Free;
  end;
end;

procedure TTestGpuCalc.PackModelLayers_MatchesPack;
var
  Model: TLayeredModel;
  A, B: TArray<Single>;
  NLay, i: Integer;
begin
  if not HenkeReady then
    Assert.Pass('Henke tables not installed: ' + HENKE_DB_PATH);
  Model := TLayeredModel.Create;
  Model.Init;
  try
    FillModel(Model, Jitter(3), 3);
    Model.Generate(CU_KA);
    NLay := Length(Model.LayersDirect);
    SetLength(A, 4 * NLay * 3);
    SetLength(B, 4 * NLay * 3);
    Pack(Model, A, 2);
    PackModelLayers(Model.LayersDirect, B, 2);
    for i := 0 to High(A) do
      Assert.AreEqual(A[i], B[i], 'value ' + IntToStr(i));
  finally
    Model.Free;
  end;
end;


{ ShaderMode = 'precise' holds specifically for this machine/driver
  (RTX 5080); a GPU whose self-check correctly fell back to 'ieee_strict'
  would fail this exact assertion. }
procedure TTestGpuCalc.SelfCheck_PassesWithPrecise;
var
  Name, Err: string;
begin
  if not Ready then Exit;
  TGpuEvaluator.ResetShaders;
  try
    Assert.IsTrue(TGpuEvaluator.Available(Name, Err), 'a working GPU must be available: ' + Err);
    Assert.AreEqual('precise', TGpuEvaluator.ShaderMode, 'shaders compile precise on the first pass');
    Assert.IsTrue(TGpuEvaluator.SelfCheckError < 1E-4,
      Format('self-check mean |log10 R/R_ref| %.2e should be under 1E-4 with precise shaders',
        [TGpuEvaluator.SelfCheckError]));
  finally
    TGpuEvaluator.ResetShaders;
  end;
end;

procedure TTestGpuCalc.SelfCheck_FallsBackToIeeeStrict;
var
  Name, Err: string;
  Model: TLayeredModel;
  Data: TDataArray;
  Calc: TCalc;
  G: TGpuEvaluator;
  Layers, Chi, Raw, Cpu: TArray<Single>;
  Lay: TCalcLayers;
  NLay, i: Integer;
  Ref, d, Mean, AgreeMean: Double;
begin
  if not Ready then Exit;
  TGpuEvaluator.ResetShaders;
  try
    TGpuEvaluator.FailSelfChecks := 1;
    try
      Assert.IsTrue(TGpuEvaluator.Available(Name, Err),
        'the IEEE-strict fallback must still give a usable GPU: ' + Err);
      Assert.AreEqual('ieee_strict', TGpuEvaluator.ShaderMode,
        'the first (precise) self-check was forced to fail');
    finally
      TGpuEvaluator.FailSelfChecks := 0;
    end;

    Model := TLayeredModel.Create;
    Model.Init;
    try
      Data := MakeData(0, cmS, rfError, 3);
      Calc := NewCalc(Data, nil, 0, cmS, rfError);
      G := TGpuEvaluator.Create;
      try
        FillModel(Model, 0, 3);
        Model.Generate(CU_KA);
        NLay := Length(Model.LayersDirect);
        G.Setup(Calc.GpuInputs(0), NLay, 1, cmS, rfError, CU_KA, 1, LIMIT);
        SetLength(Layers, 4 * NLay);
        Pack(Model, Layers, 0);
        G.Evaluate(Layers, Chi);
        Lay := Copy(Model.LayersDirect);
        Raw := G.RawCurve(0);
        Cpu := RawOnCpu(Model, Data, cmS, rfError);
        Mean := 0;
        AgreeMean := 0;
        for i := 0 to High(Data) do
        begin
          Ref := ParrattDouble(Lay, Data[i].t, False, rfError);
          d := Abs(System.Math.Log10(Raw[i] / Ref));
          Mean := Mean + d;
          AgreeMean := AgreeMean + Abs(System.Math.Log10(Raw[i] / Cpu[i]));
        end;
        Mean := Mean / Length(Data);
        AgreeMean := AgreeMean / Length(Data);
        Assert.IsTrue(Mean < 1E-4, Format('IEEE-strict GPU mean |log10 R/R_ref| %.2e ' +
          'should stay close to double precision', [Mean]));
        Assert.IsTrue(AgreeMean < 2E-4, Format('IEEE-strict GPU/CPU mean disagreement %.2e ' +
          'should stay small too', [AgreeMean]));
      finally
        G.Free;
        Calc.Free;
      end;
    finally
      Model.Free;
    end;
  finally
    TGpuEvaluator.FailSelfChecks := 0;
    TGpuEvaluator.ResetShaders;
  end;
end;

procedure TTestGpuCalc.SelfCheck_BothFail_GpuUnavailable;
var
  Name, Err, SecondErr: string;
  G: TGpuEvaluator;
begin
  if not Ready then Exit;
  TGpuEvaluator.ResetShaders;
  try
    TGpuEvaluator.FailSelfChecks := 2;
    Assert.IsFalse(TGpuEvaluator.Available(Name, Err), 'both self-checks fail: no usable GPU');
    Assert.Contains(Err, 'self-check', 'the error names the self-check');

    { The double failure is cached for 60 s (FSelfCheckFailMsg/FSelfCheckFailTick,
      unit_gpu_calc.pas's Create): a second, direct Create within that window
      must raise at once, with the same message, and must not run the
      self-check again - FailSelfChecks, already back to 0 after the two
      consumed above, must stay 0, not go negative from a third decrement. }
    Assert.AreEqual(0, TGpuEvaluator.FailSelfChecks, 'both self-checks already consumed above');
    SecondErr := '';
    try
      G := TGpuEvaluator.Create;
      G.Free;
      Assert.Fail('a second Create within the 60-second cache window should still raise');
    except
      on E: Exception do
        SecondErr := E.Message;
    end;
    Assert.AreEqual(Err, SecondErr, 'the cached Create raises the same message as Available''s probe');
    Assert.AreEqual(0, TGpuEvaluator.FailSelfChecks, 'the cached raise did not run the self-check again');
  finally
    TGpuEvaluator.FailSelfChecks := 0;
    TGpuEvaluator.ResetShaders;
  end;
end;

procedure TTestGpuCalc.DescribeServer_ReportsGpuShaderAndSelfCheck;
var
  Name, Err: string;
  Reg: TToolRegistry;
  Args, D, Server: TJSONObject;
  Mode: string;
  ChkVal, ChkWorst: Double;
begin
  if not Ready then Exit;
  TGpuEvaluator.ResetShaders;
  try
    Assert.IsTrue(TGpuEvaluator.Available(Name, Err), 'a working GPU must be available: ' + Err);
    Reg := TToolRegistry.Create;
    try
      RegisterReferenceTools(Reg);
      Args := TJSONObject.Create;
      try
        D := Reg.Execute('describe_server', Args);
      finally
        Args.Free;
      end;
      try
        Server := D.GetValue<TJSONObject>('server');
        Assert.IsNotNull(Server, 'describe_server has "server"');
        Mode := Server.GetValue<string>('gpu_shader');
        Assert.IsTrue((Mode = 'precise') or (Mode = 'ieee_strict'),
          'gpu_shader should be precise or ieee_strict, got ' + Mode);
        ChkVal := Server.GetValue<Double>('gpu_self_check');
        Assert.IsTrue(ChkVal >= 0, 'gpu_self_check should be a non-negative number');
        ChkWorst := Server.GetValue<Double>('gpu_self_check_worst');
        Assert.IsTrue(ChkWorst >= ChkVal, 'gpu_self_check_worst should be a non-negative number, >= the mean');
      finally
        D.Free;
      end;
    finally
      Reg.Free;
    end;
  finally
    TGpuEvaluator.ResetShaders;
  end;
end;

end.
