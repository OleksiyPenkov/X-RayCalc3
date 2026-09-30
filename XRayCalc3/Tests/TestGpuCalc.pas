unit TestGpuCalc;

{ The GPU evaluation of an LFPSO population (unit_gpu_calc) and the two TCalc
  methods it rests on.

  TTestGpuInputs runs on the CPU only: the chi-squared rebuilt from
  TCalc.GpuInputs and TCalc.FinishRawCurve must be the chi-squared
  CalcChiSquare computes, for every theta weight, with and without the peak
  weight and the resolution. That is the whole contract the GPU kernels
  implement.

  TTestGpuCalc needs a Direct3D 11 GPU and passes with a note where there is
  none. Its references are a double-precision Parratt recursion written out
  here (the GPU's accuracy) and the CPU engine (its agreement).

  Both need the Henke tables for Si, Mo and W and pass with a note without
  them, the way TestLFPSOProgress does. }

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
    [Test] procedure SplitDispatches_GiveTheSameAnswer;
    [Test] procedure Fit_OnTheGpu_ImprovesAndNamesTheDevice;
    [Test] procedure Fit_WithoutUseGpu_StaysOnTheCpu;
    [Test] procedure Fit_GpuFailsMidRun_FinishesOnTheCpu;
    [Test] procedure Fit_ParticleBuildFails_OnTheGpu_FallsBackToTheCpu;
    [Test] procedure Fit_ParticleBuildFails_OnTheCpu_RaisesInsteadOfHanging;

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

{ A W/Si multilayer on Si; Jitter moves the thicknesses, sigma and density of
  every layer by up to a few percent, so that particles differ. }
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

{ The measurement: the unjittered model through the CPU engine. }
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

{ The raw curve of Model on Data's angles, as CalcTet leaves it. }
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
  Result := 0.04 * ((p mod 9) / 8 - 0.5);    // -2% .. +2%
end;

{ ------------------------------------------------ double-precision Parratt -- }

{ A thin wrapper over unit_parratt_ref.ParrattRef (the reference Parratt now
  lives there, shared with production code from Task 4 on), with the Limit
  clamp the tests here expect. }
function ParrattDouble(const L: TCalcLayers; ThetaDeg: Double; SP: Boolean;
  RF: TRoughnessFunction): Double;
begin
  Result := Max(ParrattRef(L, ThetaDeg, CU_KA, SP, RF), LIMIT);
end;

{ ============================================================ TTestGpuInputs }

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

{ The GPU sums ((log D - log R) / log R)^2 x PointWeight over ChiFirst..ChiLast
  of the convolved curve and scales by ChiNorm. Done here in Double on the CPU
  engine's own curve, it must give CalcChiSquare's number. }
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
          { Results is already convolved; the sum below is the GPU's }
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

{ ============================================================== TTestGpuCalc }

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
        // rfLinear damps at every sigma since 3.9.3; rfSinus is the Stearns form
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

{ TCalc against the double-precision Parratt, every roughness function and
  polarisation, on the same particles RawCurve_MatchesDoublePrecision_* and
  GpuRawCurve_CloseToDoublePrecision use for the GPU.

  Task 3 (2026-09-28-precision-followups), first commit: TotalRecursiveRefraction's
  FastExp/FastSinCos replaced with System.Exp/System.Math.SinCos (the author's
  <= 10% rule on a representative CPU fit: measured about 9.3%
  slower, n=11 vs n=15 baseline trials). Measured here (30 cases: 5 roughness
  functions x 2 polarisations x 3 particles): mean moved from 2.54E-5..3.09E-5
  to 7.4E-6..1.02E-5, worst from 5.44E-4..7.04E-4 to 8.7E-5..9.98E-5.

  A second candidate, refining math_complex.SqrtZ's InverseSqrt (a Newton
  step, or the exact 1 / System.Sqrt), was measured alongside it: alone it
  cost only ~1.6-2.8% on the same fit and fixed the sub-critical density test
  (see TestCalcPhysics.Delta_ResolvesADensityChangeBelowTheSingleStepOfEps),
  but combined with the phase change the fit measured 11.7-12.3% slower
  (n=14 vs n=15) - over the <= 10% budget for the first commit, which left
  SqrtZ unchanged.

  Fix round 2: the author decided to accept the combined ~12% CPU fit cost.
  math_complex.SqrtZ now uses the exact 1 / System.Sqrt (ExactInverseSqrt).
  Measured here with both changes: mean 3.79E-6..5.93E-6, worst
  4.45E-5..7.80E-5 (30 cases). The bounds below are the geometric mean of the
  ORIGINAL baseline's minimum (before either change: mean 2.537E-5, worst
  5.440E-4) and this combined set's maximum (mean 5.927E-6, worst 7.802E-5):
  MeanBound = Sqrt(2.537E-5 x 5.927E-6) = 1.226E-5, rounded to 1.2E-5;
  WorstBound = Sqrt(5.440E-4 x 7.802E-5) = 2.060E-4, rounded to 2.0E-4 - each
  sits strictly between the two states, so it passes the combined form and
  catches a regression to either the phase-only or the fully-unrefined form.
  Engine agreement between the CPU and the GPU is asserted by
  GpuRawCurve_CloseToDoublePrecision, not here: this test needs only the
  Henke tables, not a GPU. }
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

{ The GPU raw curve against the double-precision Parratt, on the same
  particles RawCurve_MatchesDoublePrecision_* uses, with the grazing sine
  computed on the host in Double (2026-09-28) and the Reflect kernel's
  cancellation-sensitive sums marked `precise` (2026-09-28, and again after
  delta-carrying below).

  Originally (before delta was carried end to end): the Fresnel term was
  `(eps.re - 1) + sin_g^2`, a genuine near-1 cancellation, and fxc/the
  driver - compiled without D3DCOMPILE_IEEE_STRICTNESS - could reassociate
  it (and `(1 - eRatio) + eRatio * sin_g^2`) back into a cancelling form;
  measured then, mean stayed ~1.2E-3..1.4E-3 without `precise`, falling to
  7.9E-6..3.2E-5 (worst 7.6E-5..6.1E-4) with it - roughly 40x/20x better.

  Since delta is carried directly into the kernel (2026-09-28-precision-
  followups, Task 2, commit cd5ea6f): the Fresnel term is `sin_g2 - delta`
  (Layers.x, never recovered from a near-1 epsilon), which is already a
  well-conditioned subtraction - delta itself is small (~1E-5 for these
  materials) - regardless of reassociation. Re-measured with `precise`
  removed entirely (2026-09-28-precision-followups, Task 4, fix round 1):
  this test still passes its bounds below on this GPU (RTX 5080), and
  TGpuEvaluator's own self-check reference multilayer (TestGpuCalc's
  SelfCheck_* tests) measures mean 7.61E-6 without `precise` vs 7.27E-6 with
  it - `precise` no longer visibly changes the result on this machine, and
  is kept as defence in depth (see unit_gpu_calc's header comment and
  TGpuEvaluator.SelfCheck).

  Bounds re-tightened (2026-09-28-precision-followups, final review): the
  bounds above (mean 1E-4, worst 2E-3, agree-mean 2E-4, agree-worst 2.5E-3)
  had 14-26x slack once delta was carried (and, for the agree bounds, once
  Task 3 also made the CPU exact). Re-set to the geometric mean of a "before
  delta" figure and the current maximum, the same rule TestCalcPhysics used
  for the CPU bounds: mean and worst against `before` = Task 2's own
  pre-delta measurement of this test (mean-of-means 1.960E-5, worst-of-worst
  6.054E-4); agree-mean and agree-worst against `before` = Task 2's pre-delta
  agreement with the CPU (mean-of-means 4.063E-5, worst-of-worst 7.189E-4,
  itself pre-Task-3's exact CPU). `current` = this test's own measurement
  today (30 cases: 5 roughness functions x 2 polarisations x 3 particles):
  mean-of-means 5.991E-6, max-of-means 7.119E-6, worst-of-worst 1.199E-4;
  agree-mean-of-means 7.546E-6, max-of-agree-means 8.848E-6, agree-worst-of-
  worst 1.227E-4 (measured with temporary instrumentation, reverted before
  commit). MEAN_BOUND = Sqrt(1.960E-5 x 7.119E-6) = 1.181E-5, rounded to
  1.2E-5 (1.7x the current max). WORST_BOUND = Sqrt(6.054E-4 x 1.199E-4) =
  2.695E-4, rounded to 2.7E-4 (2.25x). AGREE_MEAN_BOUND =
  Sqrt(4.063E-5 x 8.848E-6) = 1.896E-5, rounded to 1.9E-5 (2.1x).
  AGREE_WORST_BOUND = Sqrt(7.189E-4 x 1.227E-4) = 2.969E-4, rounded to 3.0E-4
  (2.4x). No case exceeded any bound; RED not re-proven here (would need the
  pre-delta packing/kernel restored, which is not cheap) - the separation
  factors above (2.25-26x before this tightening) stand in its place. }
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
    Split.StepsPerDispatch := Int64(7) * NLay * Length(Data);   // 7 particles a dispatch
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

    { The start model, as the structure states it }
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
  TGpuEvaluator.FailAfter := 4;         // the fourth Evaluate fails
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

{ The same population scored both ways with TCalc.SolveScale on: the
  measured curve is 1.3 times the true one, so every particle's solved log10
  scale is about -0.114, and the true model (particle 4) scores near zero
  again because the solved scale takes the factor out. }
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

{ Needs no GPU: the shared packing is the test's own Pack, value for value. }
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

{ ---------------------------------------------------- the GPU self-check -- }

{ ResetShaders forces the whole compile-and-check sequence to run again: the
  next Available (and this test's own Available call) creates a throwaway
  evaluator whose Create runs the self-check fresh. On this machine (RTX
  5080) that must pass with the targeted `precise` qualifiers - asserting
  ShaderMode = 'precise' holds specifically for this machine/driver; a GPU
  whose self-check correctly fell back to 'ieee_strict' would fail this
  exact assertion (see SelfCheck_FallsBackToIeeeStrict for that path,
  exercised deterministically via FailSelfChecks rather than by relying on
  a real GPU/driver difference). }
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

{ FailSelfChecks := 1 forces only the first (precise) self-check to fail,
  whatever it actually measures: Create must then fall back to compiling
  with D3DCOMPILE_IEEE_STRICTNESS, check again for real, and this time
  succeed. Runs GpuRawCurve_CloseToDoublePrecision's first case (roughness
  rfError, polarisation cmS, particle 0) through the now IEEE-strict shaders,
  to show they still work and not just that Available reports True. }
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

{ FailSelfChecks := 2 forces both the precise and the IEEE-strict self-checks
  to fail: Create must raise, Available must report False, and the message
  must name the self-check so a client (and describe_server's gpu_error) can
  tell this apart from every other reason a GPU is unavailable. }
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

{ describe_server's server section, through the registered tool: when a GPU is
  available, gpu_shader and gpu_self_check must be there alongside gpu. }
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
