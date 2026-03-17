unit unit_universal_optimizer;

interface

uses
  System.SysUtils, System.Math, System.Classes,
  cmd_unit_types, unit_universal_types, unit_universal_io,
  unit_universal_fitness, unit_universal_pso, unit_materials_mix,
  unit_universal_templates;

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
    ElapsedSec: Double;
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
    FCancelled: Boolean;
    FTemplates: TTemplateLibrary;
    FWorkerFitness: array of TUniversalFitness;
    FOnIteration: TIterationEvent;
    FOnCompleted: TCompletionEvent;
    FOnError: TErrorEvent;
    procedure EvaluatePopulation;
    function BuildIterationData(Iteration: Integer;
      const BestResults: TTargetResults; ElapsedSec: Double): TIterationData;
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

uses
  System.Diagnostics, OtlParallel;

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
  Parallel.&For(0, FPSO.ParticleCount - 1)
    .NumTasks(TThread.ProcessorCount)
    .Execute(procedure(taskIndex, particleIndex: Integer)
    var
      P: PParticle;
    begin
      P := FPSO.GetParticle(particleIndex);
      P^.CurrentFoM := FWorkerFitness[taskIndex].Evaluate(P^.X, P^.TargetResults);
    end);
end;

function TUniversalOptimizer.BuildIterationData(Iteration: Integer;
  const BestResults: TTargetResults; ElapsedSec: Double): TIterationData;
var
  i: Integer;
begin
  Result.Iteration := Iteration;
  Result.MaxIterations := FConfig.Optimizer.Iterations;
  Result.FoM := -FPSO.ABestFoM;
  Result.Diversity := FPSO.Diversity;
  Result.JammingCount := FPSO.JammingCount;
  Result.BestGenome := FPSO.ABest;
  Result.ElapsedSec := ElapsedSec;

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
  SW: TStopwatch;
begin
  try
    SW := TStopwatch.StartNew;
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

    // Load templates
    FTemplates := LoadTemplates(FConfig.TemplatePath);

    // Collect interlayer materials and merge with element pool
    if Length(FTemplates) > 0 then
    begin
      var ExtraMats := CollectTemplateMaterials(FTemplates, ElementNames);
      for var m := 0 to High(ExtraMats) do
      begin
        var AlreadyInPool := False;
        for var e := 0 to High(ElementNames) do
          if SameText(ElementNames[e], ExtraMats[m]) then
          begin
            AlreadyInPool := True;
            Break;
          end;
        if not AlreadyInPool then
        begin
          SetLength(ElementNames, Length(ElementNames) + 1);
          ElementNames[High(ElementNames)] := ExtraMats[m];
        end;
      end;
    end;

    // Compute CapHRange and CapVariantCount from matching templates
    var CapMin: Single := MaxSingle;
    var CapMax: Single := 0;
    var HasAnyCap := False;
    var MaxCapVariants: Integer := 0;
    for var ti := 0 to High(FTemplates) do
    begin
      if Length(FTemplates[ti].Caps) = 0 then Continue;
      var SlashPos := Pos('/', FTemplates[ti].Key);
      if SlashPos <= 0 then Continue;
      var TMat1 := Copy(FTemplates[ti].Key, 1, SlashPos - 1);
      var TMat2 := Copy(FTemplates[ti].Key, SlashPos + 1, MaxInt);
      var M1InPool := False;
      var M2InPool := False;
      for var ei := 0 to High(FConfig.ElementPool) do
      begin
        if SameText(FConfig.ElementPool[ei], TMat1) then M1InPool := True;
        if SameText(FConfig.ElementPool[ei], TMat2) then M2InPool := True;
      end;
      if M1InPool and M2InPool then
      begin
        HasAnyCap := True;
        if Length(FTemplates[ti].Caps) > MaxCapVariants then
          MaxCapVariants := Length(FTemplates[ti].Caps);
        for var ci := 0 to High(FTemplates[ti].Caps) do
        begin
          if FTemplates[ti].Caps[ci].ThicknessRange.Min < CapMin then
            CapMin := FTemplates[ti].Caps[ci].ThicknessRange.Min;
          if FTemplates[ti].Caps[ci].ThicknessRange.Max > CapMax then
            CapMax := FTemplates[ti].Caps[ci].ThicknessRange.Max;
        end;
      end;
    end;
    if HasAnyCap then
    begin
      FConfig.Structure.CapHRange.Min := CapMin;
      FConfig.Structure.CapHRange.Max := CapMax;
      FConfig.Structure.CapVariantCount := MaxCapVariants;
    end
    else
    begin
      FConfig.Structure.CapHRange.Min := 0;
      FConfig.Structure.CapHRange.Max := 0;
      FConfig.Structure.CapVariantCount := 0;
    end;

    // Create engine objects
    FMixer := TMaterialMixer.Create;
    FPSO := TUniversalPSO.Create(FConfig);
    FFitness := TUniversalFitness.Create(FMixer, FConfig, FTemplates);
    SetLength(FWorkerFitness, TThread.ProcessorCount);
    for i := 0 to High(FWorkerFitness) do
      FWorkerFitness[i] := TUniversalFitness.Create(FMixer, FConfig, FTemplates);
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
        FPSO.Diversity, SW.Elapsed.TotalSeconds);

      IterData := BuildIterationData(0, BestResults, SW.Elapsed.TotalSeconds);
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
          FPSO.Diversity, SW.Elapsed.TotalSeconds);

        IterData := BuildIterationData(t + 1, BestResults, SW.Elapsed.TotalSeconds);
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
      FIO.SaveXRCStructure(FConfig, FPSO.ABest, FMixer, FTemplates, FConfig.OutputDir);

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
      SW.Stop;
      IterData := BuildIterationData(FConfig.Optimizer.Iterations, BestResults,
        SW.Elapsed.TotalSeconds);
      if Assigned(FOnCompleted) then
        FOnCompleted(IterData, Curves);

    finally
      for i := 0 to High(FWorkerFitness) do
        FWorkerFitness[i].Free;
      FWorkerFitness := nil;
      FMixer.Free;
      FPSO.Free;
      FFitness.Free;
      FIO.Free;
      FMixer := nil;
      FPSO := nil;
      FFitness := nil;
      FIO := nil;
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
