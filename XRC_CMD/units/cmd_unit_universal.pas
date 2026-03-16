unit cmd_unit_universal;

interface

uses
  System.SysUtils;

procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);

implementation

uses
  System.Math, System.Classes, Windows,
  OtlParallel, OtlTaskControl,
  cmd_unit_types, cmd_unit_universal_types, cmd_unit_universal_io,
  cmd_unit_universal_fitness, cmd_unit_universal_pso,
  unit_materials_mix;

var
  GTerminated: Boolean = False;

function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  GTerminated := True;
  WriteLn('');
  WriteLn('Interrupt received. Saving checkpoint and exiting...');
  Result := True;
end;

procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);
var
  Config: TUniversalConfig;
  Mixer: TMaterialMixer;
  PSO: TUniversalPSO;
  Fitness: TUniversalFitness;
  IO: TUniversalIO;
  i, t: Integer;
  LevyProb, LevyBoost: Single;
  TargetLambdas: array of Single;
  ElementNames: array of string;
  TargetNames: array of string;
  StartIter: Integer;
  State: TOptState;
  BestResults: TTargetResults;
  Curve: TDataArray;
begin
  SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
  try
    Config := TUniversalIO.LoadConfig(ConfigFile);

    // Print banner
    WriteLn('Universal Mirror Optimizer v1.0');
    Write('Targets:');
    for i := 0 to High(Config.Targets) do
      Write(Format(' %s(%.1fA)', [Config.Targets[i].Name, Config.Targets[i].Lambda]));
    WriteLn;
    Write('Pool:');
    for i := 0 to High(Config.ElementPool) do
      Write(' ' + Config.ElementPool[i]);
    WriteLn;
    WriteLn(Format('Structure: %s, d=[%.0f..%.0f], N=[%.0f..%.0f]',
      [Config.Structure.StructureType,
       Config.Structure.dRange.Min, Config.Structure.dRange.Max,
       Config.Structure.NRange.Min, Config.Structure.NRange.Max]));
    WriteLn(Format('Population: %d, Max iterations: %d',
      [Config.Optimizer.Population, Config.Optimizer.Iterations]));
    WriteLn('---');

    // Print header
    Write(Format('%5s  %8s', ['Iter', 'FoM']));
    for i := 0 to High(Config.Targets) do
      Write(Format('  %5s', ['R_' + Config.Targets[i].Name]));
    WriteLn(Format('  %5s', ['Div']));

    // Initialize material mixer with Henke caching
    SetLength(TargetLambdas, Length(Config.Targets));
    SetLength(TargetNames, Length(Config.Targets));
    for i := 0 to High(Config.Targets) do
    begin
      TargetLambdas[i] := Config.Targets[i].Lambda;
      TargetNames[i] := Config.Targets[i].Name;
    end;

    SetLength(ElementNames, Length(Config.ElementPool));
    for i := 0 to High(Config.ElementPool) do
      ElementNames[i] := Config.ElementPool[i];

    Mixer := TMaterialMixer.Create;
    PSO := TUniversalPSO.Create(Config);
    Fitness := TUniversalFitness.Create(Mixer, Config);
    IO := TUniversalIO.Create;
    try
      Mixer.Initialize(ElementNames, TargetLambdas,
        Config.Substrate, Config.HenkePath);

      IO.OpenLog(Config.OutputDir, TargetNames);

      // Initialize or resume
      if Config.ResumeFrom <> '' then
      begin
        State := IO.LoadCheckpoint(Config.ResumeFrom, Config);
        PSO.SetState(State);
        StartIter := State.Iteration + 1;
        WriteLn(Format('Resumed from iteration %d (FoM: %.6f)',
          [State.Iteration, -State.ABestFoM]));
      end
      else
      begin
        PSO.InitializePopulation;
        StartIter := 0;
      end;

      // Initial evaluation (parallel)
      SetLength(BestResults, Length(Config.Targets));
      Parallel.ForEach(0, PSO.ParticleCount - 1, 1).Execute(
        procedure(const Index: Integer)
        var
          LP: PParticle;
        begin
          LP := PSO.GetParticle(Index);
          LP^.CurrentFoM := Fitness.Evaluate(LP^.X, LP^.TargetResults);
        end);
      PSO.UpdateBests;

      Fitness.Evaluate(PSO.ABest, BestResults);
      IO.LogIteration(0, -PSO.ABestFoM, BestResults, TargetNames,
        PSO.Diversity);

      // Main optimization loop
      for t := StartIter to Config.Optimizer.Iterations - 1 do
      begin
        if GTerminated then Break;

        // Adaptive Levy/PSO switching
        LevyProb := 0.3 + 0.4 * (1 - t / Config.Optimizer.Iterations);
        LevyBoost := Min(0.2, PSO.JammingCount * 0.05);
        LevyProb := Min(0.9, LevyProb + LevyBoost);

        if Random > LevyProb then
          PSO.UpdatePSO(t, Config.Optimizer.Iterations)
        else
          PSO.UpdateLFPSO(t, Config.Optimizer.Iterations);

        // Parallel fitness evaluation
        Parallel.&For(0, PSO.ParticleCount - 1).Execute(
          procedure(Index: Integer)
          var
            LP: PParticle;
          begin
            LP := PSO.GetParticle(Index);
            LP^.CurrentFoM := Fitness.Evaluate(LP^.X, LP^.TargetResults);
          end
        );

        PSO.UpdateBests;

        Fitness.Evaluate(PSO.ABest, BestResults);

        IO.LogIteration(t + 1, -PSO.ABestFoM, BestResults, TargetNames,
          PSO.Diversity);

        // Stagnation handling
        if PSO.JammingCount > Config.Optimizer.JammingMax then
        begin
          if PSO.Diversity < 0.01 then
          begin
            PSO.Shake;
            if Verbose then
              WriteLn(Format('  [Shake at iteration %d]', [t + 1]));
          end;
        end;

        // Convergence check
        if (PSO.JammingCount > Config.Optimizer.StagnationLimit) then
        begin
          WriteLn(Format('Converged at iteration %d (stagnation limit reached)', [t + 1]));
          Break;
        end;

        // Checkpoint
        if ((t + 1) mod Config.Optimizer.CheckpointEvery = 0) then
        begin
          State := PSO.GetState;
          State.Iteration := t + 1;
          IO.SaveCheckpoint(State, Config, Config.OutputDir);
          if Verbose then
            WriteLn(Format('  [Checkpoint saved at iteration %d]', [t + 1]));
        end;
      end;

      // Final output
      WriteLn('---');
      WriteLn('Optimization complete.');
      WriteLn(Format('Best FoM: %.6f', [-PSO.ABestFoM]));
      WriteLn(Format('Period d=%.2f A, gamma=%.3f, N=%d, sigma=%.2f A',
        [PSO.ABest.d, PSO.ABest.Gamma, NRound(PSO.ABest.N), PSO.ABest.Sigma]));

      // Print composition
      for i := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        Write(Format('Layer %d: ', [i + 1]));
        for var j := 0 to High(Config.ElementPool) do
          if PSO.ABest.Composition[i][j] > 0.01 then
            Write(Format('%s=%.1f%% ', [Config.ElementPool[j],
              PSO.ABest.Composition[i][j] * 100]));
        WriteLn;
      end;

      // Save results
      Fitness.Evaluate(PSO.ABest, BestResults);
      IO.SaveBestStructure(Config, PSO.ABest, -PSO.ABestFoM, BestResults,
        Config.OutputDir);

      for i := 0 to High(Config.Targets) do
      begin
        Curve := Fitness.GetCurve(PSO.ABest, i);
        if Length(Curve) > 0 then
          IO.SaveCurve(Config.Targets[i].Name, Curve, Config.OutputDir);
      end;

      IO.SavePopulation(Config, PSO.GetState.Particles, 10, Config.OutputDir);

      State := PSO.GetState;
      State.Iteration := Config.Optimizer.Iterations;
      IO.SaveCheckpoint(State, Config, Config.OutputDir);

      IO.CloseLog;
    finally
      Mixer.Free;
      PSO.Free;
      Fitness.Free;
      IO.Free;
    end;
  finally
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, False);
  end;
end;

end.
