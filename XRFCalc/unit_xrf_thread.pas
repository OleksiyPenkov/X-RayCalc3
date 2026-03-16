unit unit_xrf_thread;

interface

uses
  System.SysUtils, System.Classes,
  unit_universal_types, unit_universal_optimizer;

type
  TOptimizationThread = class(TThread)
  private
    FConfig: TUniversalConfig;
    FOptimizer: TUniversalOptimizer;
    FOnIteration: TIterationEvent;
    FOnCompleted: TCompletionEvent;
    FOnError: TErrorEvent;
    FLastUpdateTick: Cardinal;
    procedure DoIteration(const Data: TIterationData);
    procedure DoCompleted(const Data: TIterationData;
      const Curves: TArray<TCurveData>);
    procedure DoError(const ErrorMsg: string);
  protected
    procedure Execute; override;
  public
    constructor Create(const AConfig: TUniversalConfig);
    procedure CancelOptimization;
    property OnIteration: TIterationEvent read FOnIteration write FOnIteration;
    property OnCompleted: TCompletionEvent read FOnCompleted write FOnCompleted;
    property OnError: TErrorEvent read FOnError write FOnError;
  end;

implementation

uses
  Winapi.Windows;

constructor TOptimizationThread.Create(const AConfig: TUniversalConfig);
begin
  inherited Create(True); // create suspended
  FreeOnTerminate := False;
  FConfig := AConfig;
  FLastUpdateTick := 0;
end;

procedure TOptimizationThread.CancelOptimization;
begin
  if Assigned(FOptimizer) then
    FOptimizer.Cancel;
end;

procedure TOptimizationThread.DoIteration(const Data: TIterationData);
var
  Tick: Cardinal;
  DataCopy: TIterationData;
begin
  // Throttle UI updates to ~200ms
  Tick := GetTickCount;
  if (Tick - FLastUpdateTick) < 200 then
    Exit;
  FLastUpdateTick := Tick;

  DataCopy := Data;
  if Assigned(FOnIteration) then
    TThread.Queue(nil,
      procedure
      begin
        FOnIteration(DataCopy);
      end);
end;

procedure TOptimizationThread.DoCompleted(const Data: TIterationData;
  const Curves: TArray<TCurveData>);
var
  DataCopy: TIterationData;
  CurvesCopy: TArray<TCurveData>;
begin
  DataCopy := Data;
  CurvesCopy := Curves;
  if Assigned(FOnCompleted) then
    TThread.Queue(nil,
      procedure
      begin
        FOnCompleted(DataCopy, CurvesCopy);
      end);
end;

procedure TOptimizationThread.DoError(const ErrorMsg: string);
var
  Msg: string;
begin
  Msg := ErrorMsg;
  if Assigned(FOnError) then
    TThread.Queue(nil,
      procedure
      begin
        FOnError(Msg);
      end);
end;

procedure TOptimizationThread.Execute;
begin
  FOptimizer := TUniversalOptimizer.Create(FConfig);
  try
    FOptimizer.OnIteration := DoIteration;
    FOptimizer.OnCompleted := DoCompleted;
    FOptimizer.OnError := DoError;
    FOptimizer.Run;
  finally
    FOptimizer.Free;
    FOptimizer := nil;
  end;
end;

end.
