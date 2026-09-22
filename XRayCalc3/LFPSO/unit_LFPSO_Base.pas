 (* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_LFPSO_Base;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_gpu_calc, unit_SMessages, Windows;

const
  WM_CHI_UPDATE = WM_STR_BASE + 100;
  WM_FIT_COMPLETE = WM_STR_BASE + 101;

type

  PUpdateFitProgressMsg = ^TUpdateFitProgressMsg ;
  TUpdateFitProgressMsg  = record
         Full : Boolean;
    LastChi   : single;
    BestChi   : single;
    WorstChi  : single;
    WasShaken : Boolean;
    Step      : integer;
    Curve     : TDataArray;
    Structure : TFitStructure;
         Poly : TProfileFunctions;
         LayeredModel  : TLayeredModel;
    Diversity     : single;
    MeanVelocity  : single;
    JammingCount  : integer;
    LevyScale     : single;
    CFact         : single;
  end;

  { Called on the fitting thread instead of posting WM_CHI_UPDATE, when
    TLFPSO_BASE.OnProgress is assigned. The callee owns Msg.LayeredModel and
    must free it; it is nil for a step (Full = False) update. The engine cannot
    tell whether the callee freed it, so the callee must free it even when it
    raises - the engine only disposes the message record itself. }
  TFitProgressEvent = procedure(const Msg: TUpdateFitProgressMsg) of object;

  TLayerIndexes = array [1..3] of SmallInt;
  TIndexes  = array of TLayerIndexes;

  TCalcWorker = record
    Calc: TCalc;
    Model: TLayeredModel;
  end;

  TWorkerBest = record
    Chi: Single;
    WorstChi: Single;
    ParticleIdx: Integer;
    Curve: TDataArray;
  end;

  TLFPSO_BASE = class
    protected
      FCalc: TCalc;
      FCalcModel: TLayeredModel;

      FReInit : Boolean;
      FWasShaken : Boolean;
      FFitParams: TFitParams;
      FCalcParams: TCalcThreadParams;
      FStructure: TFitStructure;  // initial (input) structure

      FLayersCount: integer;
      FMaterials: TMaterials;

      X, V : TPopulation;  // solutions and velocityes
      Xmax : TPopulation; // 1 column for upper boundary
      Xmin : TPopulation; // 1 column for lower boundary
      Xrange : TPopulation;   // 1 column for delta X

      Vmax, VMin: TPopulation; // 1 column for min/max velocity

      pbest: TSolution; // best local solution
      gbest: TSolution; // best global solution
      abest: TSolution;

      abest_val: single;
      gbest_val: single;

      FLastBestChiSqr  : single;
      FLastWorseChiSQR : single;
      FGlobalBestChiSqr: single;
      FAbsoluteBestChiSqr: single;
      FJammingCount    : integer;

      FTMax: integer;
      FPopulation: integer;
      FData, FResultingCurve: TDataArray;
      FBestCurve: TDataArray;   // curve of the absolute best solution
      FLimit: single;
      FTerminated: Integer;  // 0 = running, 1 = terminated (interlocked for thread safety)
      FMovAvg: TDataArray;
      CFactor: single;
      FLevySigmaU: single;  // precomputed Levy walk constant
      FLevyScale: single;   // adaptive Levy scale factor (0.01..0.1)
      FConstrictionChi: single;  // Clerc-Kennedy constriction coefficient
      FDiversity: single;        // current population diversity
      FMeanVelocity: single;     // current mean velocity (normalized)

      FWorkers: array of TCalcWorker;
      FNWorkers: Integer;

      { GPU evaluation of the population (UseGPU): nil when the CPU evaluates }
      FUseGPU: Boolean;
      FGpu: TGpuEvaluator;
      FGpuReady: Boolean;          // Setup done for this run's sizes
      FGpuLayers: TArray<Single>;  // every particle's packed model
      FGpuChi: TArray<Single>;
      FGpuBestIdx: Integer;        // best particle of the last GPU evaluation, -1 if none
      FGpuUsed: Boolean;           // at least one iteration of this run was on the GPU
      FTolCheckedChi: Single;      // the GPU chi2 whose incumbent the CPU last checked
      FDeviceUsed: string;
      FGpuError: string;

      function FindTheBest: Boolean;
      procedure EvaluateOnCpu(out BestIdx: Integer);
      function EvaluateOnGpu(out BestIdx: Integer): Boolean;
      procedure StartGpu;
      procedure StopGpu(const Why: string);
      procedure RescoreBestOnCpu;
      function CpuCurveOf(const Solution: TSolution; out Chi: Single): TDataArray;
      function ToleranceMetOnCpu: Boolean;
      function GetResult: TLayeredModel; virtual;

      function LevyWalk(const X, gBest: single): single;
      procedure SendUpdateMessage(const Step: integer);
      procedure CheckLimits(const i, j, k: integer); virtual;
      procedure SetParams(const Value: TFitParams); virtual;
      procedure Init(const Step: integer); //inline;
      function Omega(const t, TMax: integer): single; inline;
      procedure SetDomain(const Count, Order: integer; var X: TPopulation);

      procedure InitVelocity; virtual;
      procedure UpdatePSO(const t: integer); virtual;
      procedure UpdateLFPSO(const t: integer); virtual;
      procedure RangeSeed;virtual;
      procedure XSeed;virtual;
      procedure SetStructure(const Inp: TFitStructure); virtual;
      procedure UpdateStructure(var Solution:TSolution); virtual;
      procedure FillModel(Model: TLayeredModel; const Solution: TSolution); virtual;
      function FitModelToLayer(const Solution: TSolution): TLayeredModel; virtual;
      procedure Set_Init_X(const LIndex, PIndex: Integer; Val: TFitValue);
      procedure Init_Domains(const Order: Integer);
      procedure ApplyCFactor(var c1, c2: single);// inline;
      function CalcDiversity: single;
      function CalcMeanVelocity: single;
      function Rand(const dx: Single): single;
      function GetPolynomes: TProfileFunctions; virtual;
    private
     FOnProgress: TFitProgressEvent;
     FSeed: Integer;              // -1 = Randomize (GUI default)

     procedure Shake(const t: integer; var  SuccessCount, ReInitCount: integer; Vmax0, Ksxr0: single);
     procedure SendUpdateStep(const Step: integer);
    public
      constructor Create;
      destructor Destroy; override;

      property Materials: TMaterials read FMaterials write FMaterials;
      property Structure: TFitStructure read FStructure write SetStructure;
      property Result : TLayeredModel read GetResult;
      property ExpValues: TDataArray read FData write FData;
      property Limit: single write FLimit;
      property Params: TFitParams write SetParams;
      property MovAvg: TDataArray read FMovAvg write FMovAvg;
      property Polynomes:TProfileFunctions read GetPolynomes;
      { Assigned: called on the fitting thread in place of PostMessage. The
        callee owns Msg.LayeredModel and must free it, raise or not. }
      property OnProgress: TFitProgressEvent read FOnProgress write FOnProgress;
      property Seed: Integer read FSeed write FSeed;
      { Plain fields written by the fitting thread with no interlocking: read
        them only after Run has returned. }
      property BestChiSquare: single read FAbsoluteBestChiSqr;
      property BestCurve: TDataArray read FBestCurve;
      { Evaluate the population on the GPU when one is usable (theta scans
        only). Off by default: the GUI and the MCP server opt in. A GPU that
        cannot start or fails mid-run hands the work back to the CPU. }
      property UseGPU: Boolean read FUseGPU write FUseGPU;
      { After Run: 'CPU', or the name of the GPU that evaluated the last
        iteration. GpuError says why the GPU was not used, '' when it was or
        was not asked for. }
      property DeviceUsed: string read FDeviceUsed;
      property GpuError: string read FGpuError;

      procedure Run(CalcConditions: TCalcThreadParams); virtual;
      procedure Terminate;

  end;

  function Gamma( x : single) : single;
  procedure MultiplyVector(const X: TPopulation; v: single; var Result: TPopulation);
  function CopySolution(const Src: TSolution): TSolution;
  function RS: integer;
  { Data.Material := Name, skipped when it already is that very string: the
    names come from the one structure every worker thread shares, and
    reassigning bumps a reference count all of them write to. }
  procedure SetMaterial(var Data: TLayerData; const Name: string); inline;
implementation

uses
  Forms,
  System.SysUtils,
  System.SyncObjs,
  Neslib.FastMath,
  OtlParallel,
  unit_Config,
  unit_sys_helpers;

{ Supplementary}

function Gamma( x : single) : single;
const COF : array [0..14] of single =
                (  0.999999999999997092, // may as well include this in the array
                  57.1562356658629235,
                 -59.5979603554754912,
                  14.1360979747417471,
                 -0.491913816097620199,
                  0.339946499848118887e-4,
                  0.465236289270485756e-4,
                 -0.983744753048795646e-4,
                  0.158088703224912494e-3,
                 -0.210264441724104883e-3,
                  0.217439618115212643e-3,
                 -0.164318106536763890e-3,
                  0.844182239838527433e-4,
                 -0.261908384015814087e-4,
                  0.368991826595316234e-5);
const
  K = 2.5066282746310005;
  PI_OVER_K = PI / K;
var
  j : integer;
  tmp, w, ser : single;
  reflect : boolean;
begin
  reflect := (x < 0.5);
  if reflect then w := 1.0 - x else w := x;
  tmp := w + 5.2421875;
  tmp := (w + 0.5) * FastLn(tmp) - tmp;
  ser := COF[0];
  for j := 1 to 14 do ser := ser + COF[j]/(w + j);
  try
    if reflect then
      result := PI_OVER_K * w * FastExp(-tmp) / (FastSin(PI*x) * ser)
    else
      result := K * FastExp(tmp) * ser / w;
  except
    raise Exception.CreateFmt(
        'Gamma(%g) is undefined or out of floating-point range', [x]);
  end;
end;


procedure MultiplyVector(const X: TPopulation; v: single; var Result: TPopulation);
var
  i, j, k, p: integer;
begin
  for I := 0 to High(X) do                  // for every member of the population
    for j := 0 to High(X[i]) do             // for every layer
      for k := 1 to 3 do                    // for H, s, rho
        for p := 0 to High(X[i][j][k]) do
          Result[i][j][k][p] := X[i][j][k][p] * v;
end;

function RS: integer;
begin
  Result := 1 - Random(2);
  if Result = 0 then
       Result := 1;
end;

{ TLFPSO }

function TLFPSO_BASE.Rand(const dx: Single):single;
begin
  Result := (-1 + 2 * Random) * dx;
end;

procedure TLFPSO_BASE.XSeed;
begin

end;

function TLFPSO_BASE.Omega(const t, TMax: integer): single;
begin
  if FFitParams.UseConstriction then
    Result := FConstrictionChi
  else
    Result := FFitParams.w1 + FFitParams.w2 * (1 - t / Tmax);
end;

constructor TLFPSO_BASE.Create;
begin
  inherited ;
  FSeed := -1;
  FDeviceUsed := 'CPU';
end;

procedure ClearArray(var A: TPopulation); inline;
begin
  Finalize(A);
end;

procedure ClearSolution(var A: TSolution); inline;
begin
//  SetLength(A, 0);
  Finalize(A);
end;

{ OmniThreadLibrary's Parallel.For does not hand an exception raised in the
  loop body back to the caller: the worker never signals completion and the
  caller waits for ever (OtlParallel.pas, WaitForSingleObject(..., INFINITE)).
  Every loop body therefore catches, keeps the first exception here, and the
  caller raises it once the loop is over. }
procedure KeepFirstError(var Slot: Pointer);
var
  E: Pointer;
begin
  E := AcquireExceptionObject;
  if TInterlocked.CompareExchange(Slot, E, nil) <> nil then
    TObject(E).Free;
end;

procedure RaiseKept(var Slot: Pointer);
var
  E: Pointer;
begin
  E := Slot;
  Slot := nil;
  if E <> nil then
    raise TObject(E);
end;

procedure SetMaterial(var Data: TLayerData; const Name: string);
begin
  if Pointer(Data.Material) <> Pointer(Name) then
    Data.Material := Name;
end;

function CopySolution(const Src: TSolution): TSolution;
var
  i, p: Integer;
begin
  SetLength(Result, Length(Src));
  for i := 0 to High(Src) do
    for p := 1 to 3 do
      Result[i][p] := Copy(Src[i][p]);
end;

destructor TLFPSO_BASE.Destroy;
begin
  ClearArray(X);
  ClearArray(V);
  ClearArray(Xmax);
  ClearArray(Xmin);
  ClearArray(Vmax);
  ClearArray(Vmin);
  ClearArray(XRange);

  ClearSolution(pbest);
  ClearSolution(abest);
  ClearSolution(gbest);
  inherited;
end;

procedure TLFPSO_BASE.FillModel(Model: TLayeredModel; const Solution: TSolution);
var
  i, k, j, p, LayerIndex, StackLen, MaxStackLen: Integer;
  Data: TLayersData;
begin
  // Find max stack layer count — the model's scratch holds the longest stack
  MaxStackLen := 1;  // at least 1 for substrate
  for I := 0 to High(FStructure.Stacks) do
    if Length(FStructure.Stacks[i].Layers) > MaxStackLen then
      MaxStackLen := Length(FStructure.Stacks[i].Layers);
  if Length(Model.FillScratch) < MaxStackLen then
    SetLength(Model.FillScratch, MaxStackLen);
  Data := Model.FillScratch;

  LayerIndex := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    StackLen := Length(FStructure.Stacks[i].Layers);
    for k := 0 to StackLen - 1 do
    begin
      SetMaterial(Data[k], FStructure.Stacks[i].Layers[k].Material);
      for p := 1 to 3 do
        Data[k].P[p].V := Solution[LayerIndex][p][0];

      Data[k].StackID := FStructure.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := FStructure.Stacks[i].Layers[k].LayerID;
      Inc(LayerIndex);
    end;

    for j := 1  to FStructure.Stacks[i].N do
      Model.AddLayers(-1, Data, StackLen);
  end;

  SetMaterial(Data[0], FStructure.Subs.Material);
  Data[0].P :=FStructure.Subs.P;

  Model.AddSubstrate(Data);    // reads Data[0] only
end;

function TLFPSO_BASE.FitModelToLayer(const Solution: TSolution): TLayeredModel;
begin
  Result := TLayeredModel.Create;
  Result.Init;
  FillModel(Result, Solution);
end;

function TLFPSO_BASE.GetPolynomes: TProfileFunctions;
begin

end;

function TLFPSO_BASE.GetResult: TLayeredModel;
begin
  Result := FitModelToLayer(abest);
end;

procedure TLFPSO_BASE.InitVelocity;
begin

end;

procedure TLFPSO_BASE.ApplyCFactor(var c1, c2: single);
const
  PHI_HALF = 2.05;  // Clerc-Kennedy standard per-component phi
begin
  if FFitParams.UseConstriction then
  begin
    c1 := FConstrictionChi * PHI_HALF;
    c2 := FConstrictionChi * PHI_HALF;
  end
  else if FFitParams.AdaptVel and (CFactor > 0) then
  begin
    c1 := CFactor;
    c2 := CFactor;
  end else
  begin
    c1 := 1;
    c2 := 1;
  end;
end;

function TLFPSO_BASE.CalcDiversity: single;
var
  i, j, k, nParams, nPop: integer;
  mean, variance, sumVar: double;
begin
  Result := 0;
  nPop := Length(X);
  if nPop < 2 then Exit;

  sumVar := 0;
  nParams := 0;

  for j := 0 to High(X[0]) do
    for k := 1 to 3 do
    begin
      if Xrange[0][j][k][0] < 1e-10 then Continue;

      mean := 0;
      for i := 0 to High(X) do
        mean := mean + X[i][j][k][0];
      mean := mean / nPop;

      variance := 0;
      for i := 0 to High(X) do
        variance := variance + Sqr(X[i][j][k][0] - mean);
      variance := variance / (nPop - 1);

      // Normalize by range squared to get relative diversity
      sumVar := sumVar + variance / Sqr(Xrange[0][j][k][0]);
      Inc(nParams);
    end;

  if nParams > 0 then
    Result := Sqrt(sumVar / nParams);
end;

function TLFPSO_BASE.CalcMeanVelocity: single;
var
  i, j, k, nParams, nPop: integer;
  sumNorm: double;
  vAbs, vmaxVal: single;
begin
  Result := 0;
  nPop := Length(V);
  if nPop = 0 then Exit;

  sumNorm := 0;
  nParams := 0;

  for j := 0 to High(V[0]) do
    for k := 1 to 3 do
    begin
      vmaxVal := Abs(Vmax[0][j][k][0]);
      if vmaxVal < 1e-10 then Continue;

      for i := 0 to High(V) do
      begin
        vAbs := Abs(V[i][j][k][0]);
        sumNorm := sumNorm + vAbs / vmaxVal;
      end;
      Inc(nParams);
    end;

  if nParams > 0 then
    Result := sumNorm / (nPop * nParams);
end;

procedure TLFPSO_BASE.CheckLimits(const i, j, k: integer);
var
  XNew: single;
begin
  if V[i][j][k][0] > Vmax[0][j][k][0] then
             V[i][j][k][0] := Vmax[0][j][k][0];

  if V[i][j][k][0] < Vmin[0][j][k][0] then
             V[i][j][k][0] := Vmin[0][j][k][0];

  XNew := X[i][j][k][0] + V[i][j][k][0];

  // Reflective boundary handling: bounce off walls with damped velocity
  if XNew > Xmax[0][j][k][0] then
  begin
    XNew := 2 * Xmax[0][j][k][0] - XNew;
    V[i][j][k][0] := -V[i][j][k][0] * 0.5;
    if XNew < Xmin[0][j][k][0] then
      XNew := Xmin[0][j][k][0];
  end
  else if XNew < Xmin[0][j][k][0] then
  begin
    XNew := 2 * Xmin[0][j][k][0] - XNew;
    V[i][j][k][0] := -V[i][j][k][0] * 0.5;
    if XNew > Xmax[0][j][k][0] then
      XNew := Xmax[0][j][k][0];
  end;

  X[i][j][k][0] := XNew;
end;

function TLFPSO_BASE.LevyWalk(const X, gBest: single): single;
const
  inv_beta = 1 / 1.5;  // 1/beta
var
  dX, S: double;
  u, v, z: double;
begin
  u := Random * FLevySigmaU;
  v := Random;
  z := u / abs(FastPower(v, inv_beta));

  S := FLevyScale * z * (X - gBest);
  dX := X * S;
  Result := dX * Random;
end;


procedure TLFPSO_BASE.EvaluateOnCpu(out BestIdx: Integer);
var
  i: integer;
  WorkerBests: array of TWorkerBest;
  ThreadMsg: TMsg;
  Err: Pointer;
begin
  Err := nil;
  // Initialize per-worker tracking
  SetLength(WorkerBests, FNWorkers);
  for i := 0 to FNWorkers - 1 do
  begin
    WorkerBests[i].Chi := 1e12;
    WorkerBests[i].WorstChi := 0;
    WorkerBests[i].ParticleIdx := -1;
  end;

  // Parallel particle evaluation
  Parallel.&For(0, High(X))
    .NumTasks(FNWorkers)
    .Execute(procedure(taskIndex, particleIndex: integer)
    var
      W: TCalcWorker;
      Chi: Single;
    begin
      if Err <> nil then Exit;          // a sibling failed; the loop is lost anyway
      try
        W := FWorkers[taskIndex];
        W.Model.Reset;
        FillModel(W.Model, X[particleIndex]);
        W.Calc.Model := W.Model;

        W.Calc.Run;

        Chi := W.Calc.CalcChiSquare(FFitParams.ThetaWeight);

        // Track per-worker best (no synchronization needed)
        if Chi < WorkerBests[taskIndex].Chi then
        begin
          WorkerBests[taskIndex].Chi := Chi;
          WorkerBests[taskIndex].ParticleIdx := particleIndex;
          WorkerBests[taskIndex].Curve := Copy(W.Calc.Results);
        end;
        if Chi > WorkerBests[taskIndex].WorstChi then
          WorkerBests[taskIndex].WorstChi := Chi;
      except
        KeepFirstError(Err);
      end;
    end);

  // Drain OTL task-completion messages from this thread's queue
  while PeekMessage(ThreadMsg, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(ThreadMsg);
    DispatchMessage(ThreadMsg);
  end;
  RaiseKept(Err);

  // Sequential reduction — merge per-worker results
  FLastBestChiSqr  := 1e12;
  FLastWorseChiSQR := 0;
  BestIdx := -1;

  for i := 0 to FNWorkers - 1 do
  begin
    if WorkerBests[i].Chi < FLastBestChiSqr then
    begin
      FLastBestChiSqr := WorkerBests[i].Chi;
      FResultingCurve := WorkerBests[i].Curve;
      BestIdx := WorkerBests[i].ParticleIdx;
    end;
    if WorkerBests[i].WorstChi > FLastWorseChiSQR then
      FLastWorseChiSQR := WorkerBests[i].WorstChi;
  end;
end;

{ The GPU evaluation of the whole population: every particle's model is built
  on the CPU workers in parallel (Reset, FillModel, Generate - what TCalc.Run
  does before CalcTet) and packed side by side, then one GPU call returns every
  chi-squared. The best particle's curve is not fetched here: FindTheBest asks
  for it only when that particle improves on the global best. False when the
  GPU failed; it has then been shut down and the CPU takes over. }
function TLFPSO_BASE.EvaluateOnGpu(out BestIdx: Integer): Boolean;
var
  i, NLay: Integer;
  ThreadMsg: TMsg;
  Err: Pointer;
begin
  Result := False;
  BestIdx := -1;
  Err := nil;
  try
    { The layer count comes from the first particle; every particle of a fit
      expands to the same count, and the packing below checks that it does. }
    if not FGpuReady then
    begin
      FWorkers[0].Model.Reset;
      FillModel(FWorkers[0].Model, X[0]);
      NLay := Length(FWorkers[0].Model.LayersDirect);
      FGpu.Setup(FCalc.GpuInputs(FFitParams.ThetaWeight), NLay, Length(X),
        FCalcParams.P, FCalcParams.RF, FCalcParams.Lambda, FCalcParams.K, FLimit);
      SetLength(FGpuLayers, 4 * NLay * Length(X));
      FGpuReady := True;
    end;
    NLay := FGpu.LayerCount;

    Parallel.&For(0, High(X))
      .NumTasks(FNWorkers)
      .Execute(procedure(taskIndex, particleIndex: integer)
      var
        M: TLayeredModel;
        L: TCalcLayers;
        k, Base: Integer;
      begin
        if Err <> nil then Exit;
        try
          M := FWorkers[taskIndex].Model;
          M.Reset;
          FillModel(M, X[particleIndex]);
          M.Generate(FCalcParams.Lambda);
          { The model's arrays only ever grow (Reset keeps them), so this
            catches a particle that needs more layers than the first did;
            TCalc.CalcTet reads the same LayersDirect length. }
          L := M.LayersDirect;
          if Length(L) <> NLay then
            raise EGpuError.CreateFmt('particle %d expands to %d layers, not %d',
              [particleIndex, Length(L), NLay]);
          Base := 4 * NLay * particleIndex;
          for k := 0 to NLay - 1 do
          begin
            FGpuLayers[Base + 4 * k]     := L[k].e.Re;
            FGpuLayers[Base + 4 * k + 1] := L[k].e.Im;
            FGpuLayers[Base + 4 * k + 2] := L[k].L;
            FGpuLayers[Base + 4 * k + 3] := L[k].s;
          end;
        except
          KeepFirstError(Err);
        end;
      end);

    while PeekMessage(ThreadMsg, 0, 0, 0, PM_REMOVE) do
    begin
      TranslateMessage(ThreadMsg);
      DispatchMessage(ThreadMsg);
    end;
    RaiseKept(Err);

    FGpu.Evaluate(FGpuLayers, FGpuChi);
  except
    on E: Exception do
    begin
      StopGpu(E.Message);
      Exit;
    end;
  end;

  FLastBestChiSqr  := 1e12;
  FLastWorseChiSQR := 0;
  for i := 0 to High(FGpuChi) do
  begin
    if FGpuChi[i] < FLastBestChiSqr then
    begin
      FLastBestChiSqr := FGpuChi[i];
      BestIdx := i;
    end;
    if FGpuChi[i] > FLastWorseChiSQR then
      FLastWorseChiSQR := FGpuChi[i];
  end;
  SetLength(FResultingCurve, 0);   // fetched by FindTheBest when it is needed
  FGpuBestIdx := BestIdx;
  FGpuUsed := True;
  Result := True;
end;

{ The GPU searches, the CPU reports. The GPU's chi-squared agrees with the CPU
  engine's to single precision (well under 1% on a real fit), which is all
  the search needs; but the number a fit reports, and the curve beside it,
  are the ones every other part of the program recomputes with TCalc. So the
  answer is scored once more on the CPU. }
procedure TLFPSO_BASE.RescoreBestOnCpu;
var
  Chi: Single;
  Curve: TDataArray;
begin
  { The CPU engine can refuse a model the GPU scored (rfLinear with a zero
    sigma divides 0 by 0 in TCalc). The GPU's own answer then stands. }
  try
    Curve := CpuCurveOf(abest, Chi);
  except
    on E: Exception do
    begin
      FGpuError := 'The CPU could not rescore the GPU''s answer: ' + E.Message;
      Exit;
    end;
  end;
  FAbsoluteBestChiSqr := Chi;
  FGlobalBestChiSqr := Chi;
  abest_val := Chi;
  FBestCurve := Curve;
  FResultingCurve := Copy(Curve);
end;

function TLFPSO_BASE.ToleranceMetOnCpu: Boolean;
var
  Chi: Single;
begin
  Result := False;
  { once per incumbent: gbest only changes when the GPU chi2 does }
  if (Length(gbest) = 0) or (FTolCheckedChi = FGlobalBestChiSqr) then
    Exit;
  FTolCheckedChi := FGlobalBestChiSqr;
  try
    CpuCurveOf(gbest, Chi);
    Result := Chi < FFitParams.Tolerance;
  except
    // the CPU refused the model; keep searching on the GPU's numbers
  end;
end;

{ Solution's curve and chi-squared from the CPU engine, one thread, as the MCP
  server's chi2_recalc scores a model. }
function TLFPSO_BASE.CpuCurveOf(const Solution: TSolution; out Chi: Single): TDataArray;
begin
  FCalcModel.Reset;
  FillModel(FCalcModel, Solution);
  FCalc.Model := FCalcModel;
  FCalc.MaxThreads := 1;
  FCalc.Run;
  Chi := FCalc.CalcChiSquare(FFitParams.ThetaWeight);
  Result := Copy(FCalc.Results);
end;

procedure TLFPSO_BASE.StartGpu;
begin
  FGpuReady := False;
  FGpuBestIdx := -1;
  if not FUseGPU then
    Exit;
  if FCalcParams.Mode <> cmTheta then
  begin
    FGpuError := 'Only theta scans are evaluated on the GPU';
    Exit;
  end;
  try
    FGpu := TGpuEvaluator.Create;
    FDeviceUsed := FGpu.AdapterName;
  except
    on E: Exception do
      StopGpu(E.Message);
  end;
end;

procedure TLFPSO_BASE.StopGpu(const Why: string);
begin
  FreeAndNil(FGpu);
  FGpuReady := False;
  FDeviceUsed := 'CPU';
  if Why <> '' then
    FGpuError := Why;
end;

function TLFPSO_BASE.FindTheBest: boolean;
var
  i, bestIdx: integer;
  UnusedChi: Single;
begin
  Result := False;

  if (FGpu = nil) or not EvaluateOnGpu(bestIdx) then
  begin
    FGpuBestIdx := -1;
    EvaluateOnCpu(bestIdx);
  end;

  if bestIdx >= 0 then
    pbest := CopySolution(X[bestIdx]);

  // Handle first-iteration materials
  if Length(FMaterials) = 0 then
  begin
    FMaterials := Copy(FWorkers[0].Model.Materials);
    for i := 0 to FNWorkers - 1 do
      FWorkers[i].Model.Materials := Copy(FMaterials);
  end;

  if FTerminated <> 0 then Exit;

  if FLastBestChiSqr <  FGlobalBestChiSqr then
  begin
    { The GPU returns only chi-squareds; the one curve anybody looks at is
      read back and convolved now, as Run would have left it. }
    if (FGpuBestIdx >= 0) and (FGpu <> nil) then
    try
      FCalc.FinishRawCurve(FGpu.RawCurve(FGpuBestIdx));
      FResultingCurve := Copy(FCalc.Results);
    except
      on E: Exception do
      begin
        StopGpu(E.Message);
        FResultingCurve := CpuCurveOf(pbest, UnusedChi);
      end;
    end;

    FGlobalBestChiSqr := FLastBestChiSqr;
    gbest := CopySolution(pbest);
    gbest_val := FLastBestChiSqr;
    if FGlobalBestChiSqr < FAbsoluteBestChiSqr  then
    begin
      FAbsoluteBestChiSqr := FGlobalBestChiSqr;
      FBestCurve := Copy(FResultingCurve);
      abest := CopySolution(gbest);
      abest_val := FGlobalBestChiSqr;
      UpdateStructure(gbest);
      Result := True;
    end ;
  end
  else begin
    SetLength(FResultingCurve, 0);
    Inc(FJammingCount);
  end;
end;

procedure TLFPSO_BASE.Init(const Step: integer);
begin
  FJammingCount := 0;

  if (Step = 0) and FFitParams.RangeSeed then
    RangeSeed
  else
    XSeed;

  InitVelocity;
  FindTheBest;

  if Step = 0 then
    SendUpdateMessage(Step);
end;

procedure TLFPSO_BASE.Shake(const t: integer; var  SuccessCount, ReInitCount: integer; Vmax0, Ksxr0: single);
var
  TmpStructure: TFitStructure;
begin
  FReInit := True;
  if ReInitCount > FFitParams.ReInitMax then
  begin
    ReInitCount := 0;
    gbest := CopySolution(abest);   // recover to absolute best solution
    FGlobalBestChiSqr := FAbsoluteBestChiSqr;
    FFitParams.Vmax := Vmax0;
    FFitParams.Ksxr := Ksxr0;
  end
  else
  begin
    FGlobalBestChiSqr := FGlobalBestChiSqr  * FFitParams.KChiSqr;
    FFitParams.Vmax := FFitParams.Vmax * FFitParams.KVmax;
    FFitParams.Ksxr := FFitParams.Ksxr * FFitParams.KVmax;
    Inc(ReInitCount);
    dec(SuccessCount);
  end;
  UpdateStructure(gbest);        // re-init based on current global best solution
  FStructure.CopyContent(TmpStructure);
  SetStructure(TmpStructure);    // Don't use X[0] = abest! The full re-set is requred

  Init(t);
  FJammingCount := 0;
end;

procedure TLFPSO_BASE.Run(CalcConditions: TCalcThreadParams);
const
  levy_beta = 1.5;
  CONSTR_PHI = 4.1;  // Clerc-Kennedy total phi (2.05 + 2.05)
  GPU_CHI_FLOOR = 0.01;
var
  i, t: integer;
  switch, LevyProb: double;
  ReInitCount: integer;
  Vmax0, Ksxr0: single;
  SuccessCount: integer;
  num, den: double;
  Inverted: TArray<TInvertedRange>;
begin
  { An inverted range (min > max) has no inside: CheckLimits reflects a
    particle off one wall straight past the other and pins it there, so the
    parameter comes out of the fit as whichever bound it hit last, and the
    rest of the fit is scored against that. Refuse the run before anything is
    allocated, naming the layer, so that the GUI (FatalException), xrccmd and
    the MCP all report it. }
  Inverted := InvertedRanges(FStructure);
  if Length(Inverted) > 0 then
    raise EInvertedRange.Create(InvertedRangeText(FStructure, Inverted[0]) +
      '. Correct the range before fitting.');

  if FSeed < 0 then
    Randomize
  else
    RandSeed := FSeed;

  // Precompute Levy walk sigma_u (constant for beta=1.5)
  num := gamma(1 + levy_beta) * FastSin(pi * levy_beta / 2);
  den := gamma((1 + levy_beta) / 2) * levy_beta * FastPower(2, (levy_beta - 1) / 2);
  FLevySigmaU := FastPower(num / den, 1 / levy_beta);

  // Precompute constriction coefficient if enabled
  if FFitParams.UseConstriction then
    FConstrictionChi := 2.0 / Abs(2.0 - CONSTR_PHI - Sqrt(CONSTR_PHI * CONSTR_PHI - 4 * CONSTR_PHI))
  else
    FConstrictionChi := 1.0;

  FLevyScale := 0.01;  // initial scale (will be updated adaptively)

  FReInit := False;
  FWasShaken := False;
  InterlockedExchange(FTerminated, 0);
  Vmax0 := FFitParams.Vmax ;
  Ksxr0 := FFitParams.Ksxr ;
  ReInitCount := 0;
  SuccessCount := 0;
  FGlobalBestChiSqr:= 1e12;
  FAbsoluteBestChiSqr := 1e12;
  SetLength(FBestCurve, 0);
  FCalcParams := CalcConditions;
  SetLength(FMaterials, 0);

  FCalc := TCalc.Create;
  FCalcModel := TLayeredModel.Create;
  FCalcModel.Init;
  try
    FCalc.Params    := FCalcParams;
    FCalc.ExpValues := FData;
    FCalc.MovAvg    := FMovAvg;
    FCalc.Limit     := FLimit;
    FCalc.SolveScale     := FFitParams.SolveScale;
    FCalc.ScaleWindowLog := FFitParams.ScaleWindowLog;

    FNWorkers := GetNThreads;
    SetLength(FWorkers, FNWorkers);
    for i := 0 to FNWorkers - 1 do
    begin
      FWorkers[i].Model := TLayeredModel.Create;
      FWorkers[i].Model.Init;
      FWorkers[i].Calc := TCalc.Create;
      FWorkers[i].Calc.MaxThreads := 1;
      FWorkers[i].Calc.Params    := FCalcParams;
      FWorkers[i].Calc.ExpValues := FData;
      FWorkers[i].Calc.MovAvg    := FMovAvg;
      FWorkers[i].Calc.Limit     := FLimit;
      FWorkers[i].Calc.SolveScale     := FFitParams.SolveScale;
      FWorkers[i].Calc.ScaleWindowLog := FFitParams.ScaleWindowLog;
    end;

    FGpuError := '';
    FDeviceUsed := 'CPU';
    FGpuUsed := False;
    FTolCheckedChi := -1;
    StartGpu;

    Init(0);

    for t := 1 to FTMax do
    begin
      if FTerminated <> 0 then Break;

      // Adaptive Levy scale: larger steps early (exploration), smaller late (fine-tuning)
      FLevyScale := 0.01 + 0.09 * (1 - t / FTMax);

      // Adaptive velocity: linearly decrease c1,c2 from (w1+w2) to w1
      if FFitParams.AdaptVel then
        CFactor := FFitParams.w1 + FFitParams.w2 * (1 - t / FTMax)
      else
        CFactor := 1;

      // Adaptive PSO/Levy switching:
      // Base: more Levy early (exploration), more PSO late (exploitation)
      LevyProb := 0.3 + 0.4 * (1 - t / FTMax);
      // Stagnation boost: increase Levy probability when stuck
      if FJammingCount > 0 then
        LevyProb := LevyProb + 0.05 * FJammingCount;
      if LevyProb > 0.9 then LevyProb := 0.9;

      switch := Random;
      if switch > LevyProb then
        UpdatePSO(SuccessCount)
      else
        UpdateLFPSO(SuccessCount);

      FDiversity := CalcDiversity;
      FMeanVelocity := CalcMeanVelocity;

      if FindTheBest then
         SendUpdateMessage(t)
      else
        SendUpdateStep(t);

      if FGlobalBestChiSqr < FFitParams.Tolerance then Break;
      { The GPU's chi-squared has a floor of a few 1e-3 where the CPU's reaches
        0 (a curve the CPU engine generated itself). Near it, ask the CPU
        whether the tolerance is met; the search keeps using GPU numbers. }
      if (FGpu <> nil) and (FGlobalBestChiSqr < FFitParams.Tolerance + GPU_CHI_FLOOR) and
         ToleranceMetOnCpu then Break;

      if FFitParams.Shake and (FJammingCount > FFitParams.JammingMax) then
      begin
        // Diversity-aware shake: delay shake while population is still diverse
        if (FDiversity < 0.01) or (FJammingCount > FFitParams.JammingMax + 3) then
        begin
          FWasShaken := True;
          Shake(t, SuccessCount, ReInitCount, Vmax0, Ksxr0);
        end
        else begin
          FWasShaken := False;
          FFitParams.Vmax := Vmax0;
          FFitParams.Ksxr := Ksxr0;
          inc(SuccessCount);
        end;
      end
      else begin
        FWasShaken := False;
        FFitParams.Vmax := Vmax0;
        FFitParams.Ksxr := Ksxr0;
        inc(SuccessCount);
      end;
    end;
    { Stopping before the first improvement leaves abest empty: FindTheBest
      returns at its own FTerminated check, above the only line that assigns
      it. There is no solution to report, and both calls below index abest
      unconditionally - GetPolynomes reads abest[n][p] and faults. }
    if Length(abest) > 0 then
    begin
      if FGpuUsed then
        RescoreBestOnCpu;
      UpdateStructure(abest);
      SendUpdateMessage(t);
    end;
  finally
    FreeAndNil(FGpu);
    FGpuReady := False;
    for i := 0 to High(FWorkers) do
    begin
      FWorkers[i].Calc.Model := nil;
      FreeAndNil(FWorkers[i].Calc);
      FreeAndNil(FWorkers[i].Model);
    end;
    FCalc.Model := nil;         // prevent TCalc from freeing our reusable model
    FreeAndNil(FCalc);
    FreeAndNil(FCalcModel);
  end;
end;

procedure TLFPSO_BASE.RangeSeed;
begin

end;

procedure TLFPSO_BASE.SendUpdateMessage(const Step: integer);
var
  msg_prm: PUpdateFitProgressMsg;
begin
  { A stop can land before FindTheBest has assigned abest - it returns at its
    own FTerminated check, which sits above the only line that assigns it.
    Everything below indexes abest: FitModelToLayer walks it per layer, and
    TLFPSO_Poly.GetPolynomes reads abest[n][p]. There is no solution to
    report yet, so report nothing. }
  if Length(abest) = 0 then
    Exit;

  New(msg_prm);
  msg_prm.Full         := True;
  msg_prm.LastChi      := FGlobalBestChiSqr;
  msg_prm.BestChi      := FAbsoluteBestChiSqr;
  msg_prm.WorstChi     := FLastWorseChiSQR;
  msg_prm.WasShaken    := FWasShaken;
  msg_prm.Step         := Step;
  msg_prm.Curve        := Copy(FResultingCurve);
  FStructure.CopyContent(msg_prm.Structure);
  msg_prm.Poly         := GetPolynomes;
  msg_prm.LayeredModel := FitModelToLayer(abest);
  msg_prm.Diversity    := FDiversity;
  msg_prm.MeanVelocity := FMeanVelocity;
  msg_prm.JammingCount := FJammingCount;
  msg_prm.LevyScale    := FLevyScale;
  msg_prm.CFact        := CFactor;

  if Assigned(FOnProgress) then
  begin
    try
      FOnProgress(msg_prm^);    // the callee owns msg_prm.LayeredModel
    finally
      Dispose(msg_prm);         // the record is ours even if the callee raises
    end;
  end
  else
    PostMessage(
      Application.MainFormHandle,
      WM_CHI_UPDATE,
      LPARAM(msg_prm),
      0
    );
end;

procedure TLFPSO_BASE.SendUpdateStep(const Step: integer);
var
  msg_prm: PUpdateFitProgressMsg;
begin
  New(msg_prm);
  msg_prm.Full := False;
  msg_prm.LastChi := FGlobalBestChiSqr;
  msg_prm.BestChi := FAbsoluteBestChiSqr;
  msg_prm.WorstChi := FLastWorseChiSQR;
  msg_prm.WasShaken := FWasShaken;
  msg_prm.Step := Step;
  msg_prm.Curve := nil;
  msg_prm.LayeredModel := nil;  // New() leaves unmanaged fields undefined
  msg_prm.Diversity    := FDiversity;
  msg_prm.MeanVelocity := FMeanVelocity;
  msg_prm.JammingCount := FJammingCount;
  msg_prm.LevyScale    := FLevyScale;
  msg_prm.CFact        := CFactor;

  if Assigned(FOnProgress) then
  begin
    try
      FOnProgress(msg_prm^);
    finally
      Dispose(msg_prm);
    end;
  end
  else
    PostMessage(
      Application.MainFormHandle,
      WM_CHI_UPDATE,
      LPARAM(msg_prm),
      0
    );
end;

procedure TLFPSO_BASE.SetDomain(const Count, Order: integer; var X: TPopulation);
var
  i, j, k: integer;
begin
  SetLength(X, FPopulation);
  for I := 0 to High(X) do
  begin
    SetLength(X[i], Count);
    for j := 0 to Count - 1 do
      for k := 1 to 3 do
      SetLength(X[i][j][k], Order + 1);
  end;
end;

procedure TLFPSO_BASE.SetParams(const Value: TFitParams);
begin
  FFitParams := Value;

  FTMax := FFitParams.NMax;
  FPopulation := FFitParams.Pop;

  SetLength(Xmax, 1);
  SetLength(Xmin, 1);
  SetLength(Vmax, 1);
  SetLength(Vmin, 1);
  SetLength(Xrange, 1);
end;

procedure TLFPSO_BASE.SetStructure(const Inp: TFitStructure);
begin

end;

procedure TLFPSO_BASE.Terminate;
begin
  InterlockedExchange(FTerminated, 1);
end;

procedure TLFPSO_BASE.UpdateLFPSO(const t: integer);
begin

end;

procedure TLFPSO_BASE.UpdatePSO(const t: integer);
begin

end;


procedure TLFPSO_BASE.UpdateStructure(var Solution: TSolution);
var
  i, j, p, LayerIndex: integer;
begin
  LayerIndex := 0;
  for i := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
        FStructure.Stacks[i].Layers[j].P[p].V := Solution[LayerIndex][p][0];
      Inc(LayerIndex);
    end;
  end;
end;

procedure TLFPSO_BASE.Set_Init_X(const LIndex, PIndex: Integer; Val: TFitValue);
begin
       X[0][LIndex][PIndex][0] := Val.V;
    Xmax[0][LIndex][PIndex][0] := Val.max;
    Xmin[0][LIndex][PIndex][0] := Val.min;
  Xrange[0][LIndex][PIndex][0] := Xmax[0][LIndex][PIndex][0] - Xmin[0][LIndex][PIndex][0];
end;

procedure TLFPSO_BASE.Init_Domains;
begin
  SetDomain(FLayersCount, Order, X);
  SetDomain(FLayersCount, Order, Xmax);
  SetDomain(FLayersCount, Order, Xmin);
  SetDomain(FLayersCount, Order, Xrange);
  SetDomain(FLayersCount, Order, Vmin);
  SetDomain(FLayersCount, Order, Vmax);
  SetDomain(FLayersCount, Order, V);
end;

end.
