unit xrfview_unit_runner;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

const
  TEMP_OUTPUT_DIR = 'xrfview_temp_output';

type
  TRunnerState = (rsIdle, rsRunning, rsCompleted, rsFailed, rsCancelled);

  TRunnerIterationData = record
    Iteration: Integer;
    FoM: Double;
    ElementR: TArray<Double>;
    Diversity: Double;
    BestInfo: string;
    ElapsedSec: Double;
  end;

  TIterationEvent = procedure(const Data: TRunnerIterationData) of object;
  TCompletedEvent = procedure(const XRFXPath: string) of object;
  TErrorEvent = procedure(const ErrorMsg: string) of object;
  TRawLineEvent = procedure(const Line: string) of object;

  TXRCRunner = class
  private
    FState: TRunnerState;
    FProcessHandle: THandle;
    FThreadHandle: THandle;
    FReadPipe: THandle;
    FConfigPath: string;
    FOutputPath: string;
    FBuffer: TBytes;
    FRColumnCount: Integer;
    FOnIteration: TIterationEvent;
    FOnCompleted: TCompletedEvent;
    FOnError: TErrorEvent;
    FOnRawLine: TRawLineEvent;
    function FindXRCCmd: string;
    procedure ParseLine(const Line: string);
    procedure ReadPipeData;
    procedure CheckProcessExit;
    procedure Cleanup;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Start(const ConfigPath: string);
    procedure Cancel;
    procedure Poll;
    property State: TRunnerState read FState;
    property OutputPath: string read FOutputPath;
    property ConfigPath: string read FConfigPath;
    property OnIteration: TIterationEvent read FOnIteration write FOnIteration;
    property OnCompleted: TCompletedEvent read FOnCompleted write FOnCompleted;
    property OnError: TErrorEvent read FOnError write FOnError;
    property OnRawLine: TRawLineEvent read FOnRawLine write FOnRawLine;
  end;

implementation

uses
  System.IOUtils, Vcl.Forms;

constructor TXRCRunner.Create;
begin
  inherited;
  FState := rsIdle;
  FProcessHandle := INVALID_HANDLE_VALUE;
  FThreadHandle := INVALID_HANDLE_VALUE;
  FReadPipe := INVALID_HANDLE_VALUE;
end;

destructor TXRCRunner.Destroy;
begin
  if FState = rsRunning then
    Cancel;
  Cleanup;
  inherited;
end;

procedure TXRCRunner.Cleanup;
begin
  if FReadPipe <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FReadPipe);
    FReadPipe := INVALID_HANDLE_VALUE;
  end;
  if FThreadHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FThreadHandle);
    FThreadHandle := INVALID_HANDLE_VALUE;
  end;
  if FProcessHandle <> INVALID_HANDLE_VALUE then
  begin
    CloseHandle(FProcessHandle);
    FProcessHandle := INVALID_HANDLE_VALUE;
  end;
  FBuffer := nil;
end;

function TXRCRunner.FindXRCCmd: string;
var
  ExeDir, DevPath: string;
begin
  ExeDir := ExtractFilePath(Application.ExeName);

  // Production: same directory as XRFView.exe
  Result := TPath.Combine(ExeDir, 'xrccmd.exe');
  if TFile.Exists(Result) then Exit;

  // Development: XRFView/_Out/BIN/ -> XRC_CMD/Out/CMDBin/
  DevPath := TPath.GetFullPath(TPath.Combine(ExeDir, '..\..\XRC_CMD\Out\CMDBin\xrccmd.exe'));
  if TFile.Exists(DevPath) then
  begin
    Result := DevPath;
    Exit;
  end;

  Result := '';
end;

procedure TXRCRunner.Start(const ConfigPath: string);
var
  XRCCmdPath, CmdLine: string;
  SA: TSecurityAttributes;
  WritePipe: THandle;
  SI: TStartupInfo;
  PI: TProcessInformation;
begin
  if FState = rsRunning then
    raise Exception.Create('A run is already in progress');

  Cleanup;

  XRCCmdPath := FindXRCCmd;
  if XRCCmdPath = '' then
    raise Exception.Create('xrccmd.exe not found. Ensure it is built or deployed alongside XRFView.');

  FConfigPath := ConfigPath;
  FOutputPath := ChangeFileExt(ConfigPath, '.xrfx');

  // Create anonymous pipe for stdout+stderr capture
  SA := Default(TSecurityAttributes);
  SA.nLength := SizeOf(SA);
  SA.bInheritHandle := True;
  SA.lpSecurityDescriptor := nil;

  if not CreatePipe(FReadPipe, WritePipe, @SA, 0) then
    RaiseLastOSError;

  // Ensure read handle is not inherited by child
  SetHandleInformation(FReadPipe, HANDLE_FLAG_INHERIT, 0);

  try
    SI := Default(TStartupInfo);
    SI.cb := SizeOf(SI);
    SI.dwFlags := STARTF_USESTDHANDLES or STARTF_USESHOWWINDOW;
    SI.hStdOutput := WritePipe;
    SI.hStdError := WritePipe;  // merge stderr into same pipe
    SI.hStdInput := 0;  // GUI app has no stdin -- use null handle
    SI.wShowWindow := SW_HIDE;

    CmdLine := Format('"%s" -u "%s"', [XRCCmdPath, ConfigPath]);

    if not CreateProcess(nil, PChar(CmdLine), nil, nil, True,
      CREATE_NO_WINDOW, nil, PChar(ExtractFilePath(ConfigPath)), SI, PI) then
      RaiseLastOSError;

    FProcessHandle := PI.hProcess;
    FThreadHandle := PI.hThread;
    FState := rsRunning;
    FBuffer := nil;
    FRColumnCount := 0;
  finally
    // Close write end in parent -- child has its own handle
    CloseHandle(WritePipe);
  end;
end;

procedure TXRCRunner.ReadPipeData;
var
  BytesAvail: DWORD;
  BytesRead: DWORD;
  Buf: array[0..4095] of Byte;
  Text: string;
  Lines: TArray<string>;
  OldLen: Integer;
  i: Integer;
begin
  if FReadPipe = INVALID_HANDLE_VALUE then Exit;

  while True do
  begin
    if not PeekNamedPipe(FReadPipe, nil, 0, nil, @BytesAvail, nil) then
      Break;
    if BytesAvail = 0 then
      Break;

    if BytesAvail > SizeOf(Buf) then
      BytesAvail := SizeOf(Buf);

    if not ReadFile(FReadPipe, Buf[0], BytesAvail, BytesRead, nil) then
      Break;
    if BytesRead = 0 then
      Break;

    OldLen := Length(FBuffer);
    SetLength(FBuffer, OldLen + Integer(BytesRead));
    Move(Buf[0], FBuffer[OldLen], BytesRead);
  end;

  if Length(FBuffer) = 0 then Exit;

  // Convert buffer to string (xrccmd outputs ANSI/UTF-8)
  Text := TEncoding.Default.GetString(FBuffer);

  // Split on line endings
  Lines := Text.Split([#13#10, #10], TStringSplitOptions.None);

  // Last element is incomplete (no trailing newline) -- keep in buffer
  if Length(Lines) > 1 then
  begin
    FBuffer := TEncoding.Default.GetBytes(Lines[High(Lines)]);
    for i := 0 to High(Lines) - 1 do
    begin
      if Lines[i] <> '' then
      begin
        if Assigned(FOnRawLine) then
          FOnRawLine(Lines[i]);
        ParseLine(Lines[i]);
      end;
    end;
  end;
end;

procedure TXRCRunner.ParseLine(const Line: string);
var
  Trimmed: string;
  Data: TRunnerIterationData;
  Parts: TArray<string>;
  i, MinParts, DivIdx, ColonPos: Integer;
  RValD: Double;
  Min, Sec: Integer;
  TimeStr: string;
begin
  Trimmed := Trim(Line);

  // Check for "Package saved:" -> completion
  if Trimmed.StartsWith('Package saved:') then
  begin
    FOutputPath := Trim(Copy(Trimmed, 16, MaxInt));
    Exit;
  end;

  // Check for error (stderr merged into pipe)
  if Trimmed.StartsWith('Error:') or Trimmed.Contains('Exception') then
  begin
    FState := rsFailed;
    if Assigned(FOnError) then
      FOnError(Trimmed);
    Exit;
  end;

  // Detect header line to learn R-column count
  if Trimmed.StartsWith('Iter') then
  begin
    FRColumnCount := 0;
    Parts := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
    for i := 0 to High(Parts) do
      if Parts[i].StartsWith('R_') then
        Inc(FRColumnCount);
    Exit;
  end;

  // Try to parse as iteration data line: starts with digits
  if (Length(Trimmed) = 0) or not CharInSet(Trimmed[1], ['0'..'9']) then
    Exit;

  if FRColumnCount = 0 then Exit; // haven't seen header yet

  Parts := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
  MinParts := 2 + FRColumnCount + 1 + 1 + 1; // Iter,FoM,Rs,Div,>=1 Best part,Time
  if Length(Parts) < MinParts then Exit;

  if not TryStrToInt(Parts[0], Data.Iteration) then Exit;
  if not TryStrToFloat(Parts[1], Data.FoM) then Exit;

  // R values: indices 2 through 1+FRColumnCount
  SetLength(Data.ElementR, FRColumnCount);
  for i := 0 to FRColumnCount - 1 do
  begin
    if TryStrToFloat(Parts[2 + i], RValD) then
      Data.ElementR[i] := RValD;
  end;

  // Diversity: index 2+FRColumnCount
  DivIdx := 2 + FRColumnCount;
  TryStrToFloat(Parts[DivIdx], Data.Diversity);

  // Time: last part (format "M:SS")
  TimeStr := Parts[High(Parts)];
  ColonPos := Pos(':', TimeStr);
  if ColonPos > 0 then
  begin
    if TryStrToInt(Trim(Copy(TimeStr, 1, ColonPos - 1)), Min) and
       TryStrToInt(Trim(Copy(TimeStr, ColonPos + 1, MaxInt)), Sec) then
      Data.ElapsedSec := Min * 60.0 + Sec;
  end;

  // BestInfo: parts between Div and Time
  Data.BestInfo := '';
  for i := DivIdx + 1 to High(Parts) - 1 do
  begin
    if Data.BestInfo <> '' then
      Data.BestInfo := Data.BestInfo + ' ';
    Data.BestInfo := Data.BestInfo + Parts[i];
  end;

  if Assigned(FOnIteration) then
    FOnIteration(Data);
end;

procedure TXRCRunner.CheckProcessExit;
var
  ExitCode: DWORD;
  LastLine: string;
begin
  if FProcessHandle = INVALID_HANDLE_VALUE then Exit;
  if WaitForSingleObject(FProcessHandle, 0) <> WAIT_OBJECT_0 then Exit;

  // Process has exited -- drain remaining pipe data
  ReadPipeData;

  // Flush any remaining buffer (FBuffer is TBytes)
  if Length(FBuffer) > 0 then
  begin
    LastLine := TEncoding.Default.GetString(FBuffer);
    FBuffer := nil;
    if Assigned(FOnRawLine) then
      FOnRawLine(LastLine);
    ParseLine(LastLine);
  end;

  GetExitCodeProcess(FProcessHandle, ExitCode);

  if (FState = rsRunning) then
  begin
    if (ExitCode = 0) and TFile.Exists(FOutputPath) then
    begin
      FState := rsCompleted;
      if Assigned(FOnCompleted) then
        FOnCompleted(FOutputPath);
    end
    else if FState <> rsCancelled then
    begin
      FState := rsFailed;
      if Assigned(FOnError) then
        FOnError(Format('xrccmd exited with code %d', [ExitCode]));
    end;
  end;

  Cleanup;
end;

procedure TXRCRunner.Poll;
begin
  if FState <> rsRunning then Exit;
  ReadPipeData;
  CheckProcessExit;
end;

procedure TXRCRunner.Cancel;
begin
  if (FState <> rsRunning) or (FProcessHandle = INVALID_HANDLE_VALUE) then Exit;
  FState := rsCancelled;
  TerminateProcess(FProcessHandle, 1);
end;

end.
