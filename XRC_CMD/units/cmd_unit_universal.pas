unit cmd_unit_universal;

interface

uses
  System.SysUtils;

procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);

implementation

uses
  System.Math, Windows,
  cmd_unit_types, unit_universal_types, unit_universal_io,
  unit_universal_optimizer;

type
  TConsoleHandler = class
  private
    FConfig: TUniversalConfig;
    FVerbose: Boolean;
  public
    constructor Create(const AConfig: TUniversalConfig; AVerbose: Boolean);
    procedure HandleIteration(const Data: TIterationData);
    procedure HandleCompletion(const Data: TIterationData;
      const Curves: TArray<TCurveData>);
    procedure HandleError(const ErrorMsg: string);
  end;

var
  GOptimizer: TUniversalOptimizer;

function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  if Assigned(GOptimizer) then
    GOptimizer.Cancel;
  WriteLn('');
  WriteLn('Interrupt received. Saving checkpoint and exiting...');
  Result := True;
end;

{ TConsoleHandler }

constructor TConsoleHandler.Create(const AConfig: TUniversalConfig;
  AVerbose: Boolean);
begin
  inherited Create;
  FConfig := AConfig;
  FVerbose := AVerbose;
end;

procedure TConsoleHandler.HandleIteration(const Data: TIterationData);
begin
  // IO.LogIteration already writes progress to stdout and log file.
  // Here we only add verbose-specific messages.
  if FVerbose then
  begin
    if (Data.JammingCount > FConfig.Optimizer.JammingMax) and
       (Data.Diversity < 0.01) then
      WriteLn(Format('  [Shake at iteration %d]', [Data.Iteration]));

    if (Data.Iteration > 0) and
       ((Data.Iteration mod FConfig.Optimizer.CheckpointEvery) = 0) then
      WriteLn(Format('  [Checkpoint saved at iteration %d]', [Data.Iteration]));
  end;

  if Data.JammingCount > FConfig.Optimizer.StagnationLimit then
    WriteLn(Format('Converged at iteration %d (stagnation limit reached)',
      [Data.Iteration]));
end;

procedure TConsoleHandler.HandleCompletion(const Data: TIterationData;
  const Curves: TArray<TCurveData>);
var
  i, j: Integer;
begin
  WriteLn('---');
  WriteLn('Optimization complete.');
  WriteLn(Format('Best FoM: %.6f', [Data.FoM]));
  WriteLn(Format('Period d=%.2f A, gamma=%.3f, N=%d, sigma=%.2f A',
    [Data.BestGenome.d, Data.BestGenome.Gamma,
     NRound(Data.BestGenome.N), Data.BestGenome.Sigma]));

  // Print composition
  for i := 0 to LAYERS_PER_PERIOD - 1 do
  begin
    Write(Format('Layer %d: ', [i + 1]));
    for j := 0 to High(FConfig.ElementPool) do
      if Data.BestGenome.Composition[i][j] > 0.01 then
        Write(Format('%s=%.1f%% ', [FConfig.ElementPool[j],
          Data.BestGenome.Composition[i][j] * 100]));
    WriteLn;
  end;
end;

procedure TConsoleHandler.HandleError(const ErrorMsg: string);
begin
  WriteLn(ErrOutput, 'Error: ' + ErrorMsg);
end;

procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);
var
  Config: TUniversalConfig;
  Handler: TConsoleHandler;
  i: Integer;
begin
  Config := TUniversalIO.LoadConfig(ConfigFile);

  // Print banner
  WriteLn('Universal Mirror Optimizer v1.0');
  Write('Lines:');
  for i := 0 to High(Config.Lines) do
    Write(Format(' %s(%.1fA)', [Config.Lines[i].Name, Config.Lines[i].Lambda]));
  WriteLn;
  Write('Pool:');
  for i := 0 to High(Config.ElementPool) do
    Write(' ' + Config.ElementPool[i]);
  WriteLn;
  WriteLn(Format('Structure: %s, d=[%.0f..%.0f], N=[%.0f..%.0f]',
    [Config.Structure.StructureType,
     Config.Structure.dRange.Min, Config.Structure.dRange.Max,
     Config.Structure.NRange.Min, Config.Structure.NRange.Max]));
  if Config.Structure.PureElements then
    WriteLn('Mode: pure elements (no mixing)')
  else
    WriteLn('Mode: mixed compositions');
  WriteLn(Format('Population: %d, Max iterations: %d',
    [Config.Optimizer.Population, Config.Optimizer.Iterations]));
  if Config.Fitness.DeltaTheta > 0 then
    WriteLn(Format('Beam divergence: %.3f deg', [Config.Fitness.DeltaTheta]));
  if Config.Fitness.ThetaMin > 0 then
    WriteLn(Format('Theta min: %.1f deg', [Config.Fitness.ThetaMin]));
  WriteLn('---');

  // Print header
  Write(Format('%5s  %8s', ['Iter', 'FoM']));
  for i := 0 to High(Config.Lines) do
    Write(Format('  %5s', ['R_' + Config.Lines[i].Name]));
  WriteLn(Format('  %5s  %-18s  %8s', ['Div', 'Best', 'Time']));

  Handler := TConsoleHandler.Create(Config, Verbose);
  try
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
    GOptimizer := TUniversalOptimizer.Create(Config);
    try
      GOptimizer.OnIteration := Handler.HandleIteration;
      GOptimizer.OnCompleted := Handler.HandleCompletion;
      GOptimizer.OnError := Handler.HandleError;
      GOptimizer.Run;
    finally
      GOptimizer.Free;
      GOptimizer := nil;
      SetConsoleCtrlHandler(@ConsoleCtrlHandler, False);
    end;
  finally
    Handler.Free;
  end;
end;

end.
