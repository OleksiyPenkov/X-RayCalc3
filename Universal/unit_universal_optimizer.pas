unit unit_universal_optimizer;

interface

uses
  System.SysUtils, System.Math, System.Classes, System.Threading,
  cmd_unit_types, unit_universal_types, unit_universal_io,
  unit_universal_fitness, unit_universal_pso, unit_materials_mix;

type
  TElementResult = record
    Element: string;
    RPeak: Double;
    FWHM: Double;
  end;

  TIterationData = record
    Iteration: Integer;
    MaxIterations: Integer;
    FoM: Double;
    PerElement: TArray<TElementResult>;
    Diversity: Double;
    JammingCount: Integer;
    BestGenome: TGenome;
  end;

  TCurveData = record
    Element: string;
    Theta: TArray<Double>;
    Refl: TArray<Double>;
  end;

  TIterationEvent = procedure(const Data: TIterationData) of object;
  TCompletionEvent = procedure(const Data: TIterationData;
    const Curves: TArray<TCurveData>) of object;
  TErrorEvent = procedure(const ErrorMsg: string) of object;

  TUniversalOptimizer = class
  private
    FConfig: TUniversalConfig;
    FPSO: TUniversalPSO;
    FFitness: TUniversalFitness;
    FIO: TUniversalIO;
    FMixer: TMaterialMixer;
    FPool: TThreadPool;
    FCancelled: Boolean;
    FOnIteration: TIterationEvent;
    FOnCompleted: TCompletionEvent;
    FOnError: TErrorEvent;
    procedure EvaluatePopulation;
    function BuildIterationData(Iteration: Integer;
      const BestResults: TTargetResults): TIterationData;
  public
    constructor Create(const AConfig: TUniversalConfig);
    destructor Destroy; override;
    procedure Run;
    procedure Cancel;
    property OnIteration: TIterationEvent read FOnIteration write FOnIteration;
    property OnCompleted: TCompletionEvent read FOnCompleted write FOnCompleted;
    property OnError: TErrorEvent read FOnError write FOnError;
  end;

implementation

{ TUniversalOptimizer }

constructor TUniversalOptimizer.Create(const AConfig: TUniversalConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FCancelled := False;
end;

destructor TUniversalOptimizer.Destroy;
begin
  // Objects created in Run are freed in Run's finally block
  inherited;
end;

procedure TUniversalOptimizer.EvaluatePopulation;
begin
  TParallel.&For(0, FPSO.ParticleCount - 1,
    procedure(Index: Integer)
    var
      P: PParticle;
    begin
      P := FPSO.GetParticle(Index);
      P^.CurrentFoM := FFitness.Evaluate(P^.X, P^.TargetResults);
    end,
    FPool);
end;

function TUniversalOptimizer.BuildIterationData(Iteration: Integer;
  const BestResults: TTargetResults): TIterationData;
var
  i: Integer;
begin
  Result.Iteration := Iteration;
  Result.MaxIterations := FConfig.Optimizer.Iterations;
  Result.FoM := -FPSO.ABestFoM;
  Result.Diversity := FPSO.Diversity;
  Result.JammingCount := FPSO.JammingCount;
  Result.BestGenome := FPSO.ABest;

  SetLength(Result.PerElement, Length(FConfig.Targets));
  for i := 0 to High(FConfig.Targets) do
  begin
    Result.PerElement[i].Element := FConfig.Targets[i].Name;
    Result.PerElement[i].RPeak := BestResults[i].RPeak;
    Result.PerElement[i].FWHM := BestResults[i].FWHM;
  end;
end;

procedure TUniversalOptimizer.Run;
var
  i, j, t: Integer;
  LevyProb, LevyBoost: Single;
  TargetLambdas: array of Single;
  ElementNames: array of string;
  TargetNames: array of string;
  StartIter: Integer;
  State: TOptState;
  BestResults: TTargetResults;
  Curve: TDataArray;
  Curves: TArray<TCurveData>;
  IterData: TIterationData;
begin
  try
    // Build arrays from config
    SetLength(TargetLambdas, Length(FConfig.Targets));
    SetLength(TargetNames, Length(FConfig.Targets));
    for i := 0 to High(FConfig.Targets) do
    begin
      TargetLambdas[i] := FConfig.Targets[i].Lambda;
      TargetNames[i] := FConfig.Targets[i].Name;
    end;

    SetLength(ElementNames, Length(FConfig.ElementPool));
    for i := 0 to High(FConfig.ElementPool) do
      ElementNames[i] := FConfig.ElementPool[i];

    // Create engine objects
    FPool := TThreadPool.Create;
    FPool.SetMinWorkerThreads(TThread.ProcessorCount);
    FPool.SetMaxWorkerThreads(TThread.ProcessorCount);
    FMixer := TMaterialMixer.Create;
    FPSO := TUniversalPSO.Create(FConfig);
    FFitness := TUniversalFitness.Create(FMixer, FConfig);
    FIO := TUniversalIO.Create;
    try
      FMixer.Initialize(ElementNames, TargetLambdas,
        FConfig.Substrate, FConfig.HenkePath);

      FIO.OpenLog(FConfig.OutputDir, TargetNames);

      // Initialize or resume
      if FConfig.ResumeFrom <> '' then
      begin
        State := FIO.LoadCheckpoint(FConfig.ResumeFrom, FConfig);
        FPSO.SetState(State);
        StartIter := State.Iteration + 1;
      end
      else
      begin
        FPSO.InitializePopulation;
        StartIter := 0;
      end;

      // Initial evaluation
      SetLength(BestResults, Length(FConfig.Targets));
      EvaluatePopulation;
      FPSO.UpdateBests;

      FFitness.Evaluate(FPSO.ABest, BestResults);
      FIO.LogIteration(0, -FPSO.ABestFoM, BestResults, TargetNames,
        FPSO.Diversity);

      IterData := BuildIterationData(0, BestResults);
      if Assigned(FOnIteration) then
        FOnIteration(IterData);

      // Main optimization loop
      for t := StartIter to FConfig.Optimizer.Iterations - 1 do
      begin
        if FCancelled then Break;

        // Adaptive Levy/PSO switching
        LevyProb := 0.3 + 0.4 * (1 - t / FConfig.Optimizer.Iterations);
        LevyBoost := Min(0.2, FPSO.JammingCount * 0.05);
        LevyProb := Min(0.9, LevyProb + LevyBoost);

        if Random > LevyProb then
          FPSO.UpdatePSO(t, FConfig.Optimizer.Iterations)
        else
          FPSO.UpdateLFPSO(t, FConfig.Optimizer.Iterations);

        // Fitness evaluation
        EvaluatePopulation;
        FPSO.UpdateBests;

        FFitness.Evaluate(FPSO.ABest, BestResults);
        FIO.LogIteration(t + 1, -FPSO.ABestFoM, BestResults, TargetNames,
          FPSO.Diversity);

        IterData := BuildIterationData(t + 1, BestResults);
        if Assigned(FOnIteration) then
          FOnIteration(IterData);

        // Stagnation handling
        if FPSO.JammingCount > FConfig.Optimizer.JammingMax then
        begin
          if FPSO.Diversity < 0.01 then
            FPSO.Shake;
        end;

        // Convergence check
        if FPSO.JammingCount > FConfig.Optimizer.StagnationLimit then
          Break;

        // Checkpoint
        if ((t + 1) mod FConfig.Optimizer.CheckpointEvery = 0) then
        begin
          State := FPSO.GetState;
          State.Iteration := t + 1;
          FIO.SaveCheckpoint(State, FConfig, FConfig.OutputDir);
        end;
      end;

      // Save results
      FFitness.Evaluate(FPSO.ABest, BestResults);
      FIO.SaveBestStructure(FConfig, FPSO.ABest, -FPSO.ABestFoM, BestResults,
        FConfig.OutputDir);
      FIO.SaveXRCStructure(FConfig, FPSO.ABest, FMixer, FConfig.OutputDir);

      // Compute curves once, use for both file saving and completion event
      SetLength(Curves, Length(FConfig.Targets));
      for i := 0 to High(FConfig.Targets) do
      begin
        Curve := FFitness.GetCurve(FPSO.ABest, i);
        if Length(Curve) > 0 then
          FIO.SaveCurve(FConfig.Targets[i].Name, Curve, FConfig.OutputDir);
        Curves[i].Element := FConfig.Targets[i].Name;
        SetLength(Curves[i].Theta, Length(Curve));
        SetLength(Curves[i].Refl, Length(Curve));
        for j := 0 to High(Curve) do
        begin
          Curves[i].Theta[j] := Curve[j].t;
          Curves[i].Refl[j] := Curve[j].r;
        end;
      end;

      FIO.SavePopulation(FConfig, FPSO.GetState.Particles, 10, FConfig.OutputDir);

      State := FPSO.GetState;
      State.Iteration := FConfig.Optimizer.Iterations;
      FIO.SaveCheckpoint(State, FConfig, FConfig.OutputDir);

      FIO.CloseLog;

      // Fire completion event with cached curves
      IterData := BuildIterationData(FConfig.Optimizer.Iterations, BestResults);
      if Assigned(FOnCompleted) then
        FOnCompleted(IterData, Curves);

    finally
      FMixer.Free;
      FPSO.Free;
      FFitness.Free;
      FIO.Free;
      FPool.Free;
      FMixer := nil;
      FPSO := nil;
      FFitness := nil;
      FIO := nil;
      FPool := nil;
    end;
  except
    on E: Exception do
      if Assigned(FOnError) then
        FOnError(E.Message)
      else
        raise;
  end;
end;

procedure TUniversalOptimizer.Cancel;
begin
  FCancelled := True;
end;

end.
