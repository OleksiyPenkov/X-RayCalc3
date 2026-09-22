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
  unit_gpu_calc;

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
    [Test] procedure Chi_MatchesTheCpuEngine_EveryWeighting;
    [Test] procedure Chi_MatchesTheCpuEngine_WithTheScaleSolved;
    [Test] procedure SplitDispatches_GiveTheSameAnswer;
    [Test] procedure Fit_OnTheGpu_ImprovesAndNamesTheDevice;
    [Test] procedure Fit_WithoutUseGpu_StaysOnTheCpu;
    [Test] procedure Fit_GpuFailsMidRun_FinishesOnTheCpu;
    [Test] procedure Fit_ParticleBuildFails_OnTheGpu_FallsBackToTheCpu;
    [Test] procedure Fit_ParticleBuildFails_OnTheCpu_RaisesInsteadOfHanging;
  end;

implementation

uses
  System.Math,
  System.IOUtils,
  System.Classes,
  System.SyncObjs,
  Winapi.Windows,
  unit_Config,
  unit_LFPSO_Base,
  unit_LFPSO_Periodic;

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
    Buf[Base + 4 * k]     := L[k].e.Re;
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

type
  TZ = record Re, Im: Double; end;

function Z(a, b: Double): TZ; inline; begin Result.Re := a; Result.Im := b; end;
function ZAdd(const a, b: TZ): TZ; inline; begin Result := Z(a.Re + b.Re, a.Im + b.Im); end;
function ZSub(const a, b: TZ): TZ; inline; begin Result := Z(a.Re - b.Re, a.Im - b.Im); end;
function ZMul(const a, b: TZ): TZ; inline;
begin
  Result := Z(a.Re * b.Re - a.Im * b.Im, a.Re * b.Im + a.Im * b.Re);
end;
function ZDiv(const a, b: TZ): TZ; inline;
var
  d: Double;
begin
  d := b.Re * b.Re + b.Im * b.Im;
  Result := Z((a.Re * b.Re + a.Im * b.Im) / d, (a.Im * b.Re - a.Re * b.Im) / d);
end;
function ZScale(k: Double; const a: TZ): TZ; inline; begin Result := Z(k * a.Re, k * a.Im); end;
function ZAbs(const a: TZ): Double; inline; begin Result := Sqrt(a.Re * a.Re + a.Im * a.Im); end;
function ZSqrt(const a: TZ): TZ;
var
  m: Double;
begin
  if (a.Re = 0) and (a.Im = 0) then
    Exit(Z(0, 0));
  m := ZAbs(a);
  if a.Re > 0 then
  begin
    m := m + a.Re;
    Result := Z(Sqrt(m / 2), a.Im / Sqrt(m * 2));
  end
  else
  begin
    m := m - a.Re;
    if a.Im < 0 then
      Result := Z(Abs(a.Im) / Sqrt(m * 2), -Sqrt(m / 2))
    else
      Result := Z(Abs(a.Im) / Sqrt(m * 2), Sqrt(m / 2));
  end;
end;

function RoughnessD(RF: TRoughnessFunction; Sigma, s: Double): Double;
var
  x: Double;
begin
  case RF of
    rfError:  Result := Exp(-(Sigma * Sigma * 0.50299) * s * s);
    rfExp:    Result := 1 / (1 + (s * s * Sigma * Sigma) / 2);
    rfLinear:
      if Sigma < 0.5 then
      begin
        x := Sqrt(3) * Sigma * s;
        if x = 0 then Result := 1 else Result := Sin(x) / x;
      end
      else
        Result := 1;
    rfStep:   Result := Cos(Sigma * s);
  else
    Result := 0;
  end;
end;

{ TCalc.RefCalc in Double from the model TLayeredModel.Generate left, with the
  angle taken as the grazing angle so nothing cancels. }
function ParrattDouble(const L: TCalcLayers; ThetaDeg: Double; SP: Boolean;
  RF: TRoughnessFunction): Double;
var
  c1, c2, cs, cos2, eRatio, s1, rough, L2, ex, ph: Double;
  i, n: Integer;
  eB, ei, KB, Ki, R, Rp, RFs, RFp, a1, Ph1, k1, k2: TZ;
  sB, LB: Double;
begin
  c1 := 4 * Pi / CU_KA;
  c2 := c1 / 2;
  cs := Sin(DegToRad(ThetaDeg));
  cos2 := cs * cs;
  n := Length(L);
  eB := Z(L[n - 1].e.Re, L[n - 1].e.Im);
  sB := L[n - 1].s;
  LB := L[n - 1].L;
  KB := ZScale(c2, ZSqrt(Z((eB.Re - 1) + cos2, eB.Im)));
  R := Z(0, 0);
  Rp := Z(0, 0);
  for i := n - 2 downto 0 do
  begin
    ei := Z(L[i].e.Re, L[i].e.Im);
    Ki := ZScale(c2, ZSqrt(Z((ei.Re - 1) + cos2, ei.Im)));
    eRatio := ZAbs(ZDiv(ei, eB));
    s1 := Abs((1 - eRatio) + eRatio * cos2);
    rough := RoughnessD(RF, sB, c1 * Sqrt(cs * Sqrt(s1)));
    L2 := LB * 2;
    ex := Exp(-L2 * KB.Im);
    ph := L2 * KB.Re;
    Ph1 := Z(ex * Cos(ph), ex * Sin(ph));
    RFs := ZScale(rough, ZDiv(ZSub(Ki, KB), ZAdd(Ki, KB)));
    a1 := ZMul(R, Ph1);
    R := ZDiv(ZAdd(RFs, a1), ZAdd(Z(1, 0), ZMul(RFs, a1)));
    if SP then
    begin
      k1 := ZDiv(Ki, ei);
      k2 := ZDiv(KB, eB);
      RFp := ZScale(rough, ZDiv(ZSub(k1, k2), ZAdd(k1, k2)));
      a1 := ZMul(Rp, Ph1);
      Rp := ZDiv(ZAdd(RFp, a1), ZAdd(Z(1, 0), ZMul(RFp, a1)));
    end;
    eB := ei; KB := Ki; sB := L[i].s; LB := L[i].L;
  end;
  Result := R.Re * R.Re + R.Im * R.Im;
  if SP then
    Result := (Result + Rp.Re * Rp.Re + Rp.Im * Rp.Im) / 2;
  if Result < LIMIT then
    Result := LIMIT;
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
    for RF := rfError to rfStep do
      for Pol := cmS to cmSP do
      begin
        // rfLinear only departs from 1 below 0.5 A
        if RF = rfLinear then Sigma := 0.3 else Sigma := 3;
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

end.
