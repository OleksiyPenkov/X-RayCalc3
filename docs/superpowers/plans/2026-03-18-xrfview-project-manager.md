# XRFView Project Manager Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert XRFView from a passive .xrfx viewer into a project manager that configures, launches, monitors, and displays universal mirror optimization runs.

**Architecture:** New config dialog (TfrmRunConfig) and process runner (TXRCRunner) unit. Config dialog reads/writes TUniversalConfig via existing TUniversalIO. Runner spawns xrccmd.exe as a child process with piped stdout, parsed by TTimer in the main form. Progress tab upgraded to dual-mode (static/live).

**Tech Stack:** Delphi VCL (RAD Studio 37.0), WinAPI CreateProcess, TUniversalIO from Universal/, TeeChart for live progress.

**Spec:** `docs/superpowers/specs/2026-03-18-xrfview-project-manager-design.md`

---

## File Map

| File | Action | Responsibility |
|------|--------|---------------|
| `XRFView/Units/xrfview_unit_runner.pas` | Create | TXRCRunner: process spawn, pipe read, stdout parse |
| `XRFView/Forms/frm_RunConfig.pas + .dfm` | Create | Config dialog: Tier 1/2/3 controls, LoadFromConfig, BuildConfig |
| `XRFView/Views/frame_ProgressView.pas + .dfm` | Modify | Add TMemo log, dual-mode (static/live), AddIteration, AppendLog |
| `XRFView/Forms/frm_XRFViewMain.pas + .dfm` | Modify | 3 toolbar buttons, FRunner, FRunTimer, run state, auto-reload |
| `XRFView/XRFView.dpr` | Modify | Add new units to uses clause |
| `XRFView/XRFView.dproj` | Modify | Add new files to project |
| `XRFView/XRFViewIcons.rc` | Modify | Add 3 new icon resources |
| `Assets/ToolIcons/XRFView/` | Create 3 PNGs | Icons for New Run, Edit Run, Stop |

---

## Chunk 1: Process Runner (TXRCRunner)

### Task 1: Create xrfview_unit_runner.pas — types and skeleton

**Files:**
- Create: `XRFView/Units/xrfview_unit_runner.pas`

- [ ] **Step 1: Create the runner unit with types and class skeleton**

```pascal
unit xrfview_unit_runner;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes;

type
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

end.
```

- [ ] **Step 2: Verify it compiles**

Temporarily add `xrfview_unit_runner` to `XRFView.dpr` uses clause and build:

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add XRFView/Units/xrfview_unit_runner.pas
git commit -m "+ Add TXRCRunner skeleton for xrccmd process management"
```

---

### Task 2: Implement FindXRCCmd

**Files:**
- Modify: `XRFView/Units/xrfview_unit_runner.pas`

- [ ] **Step 1: Implement FindXRCCmd**

Add implementation for `FindXRCCmd`. It looks in the exe's own directory first (production), then falls back to the development path.

```pascal
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
```

- [ ] **Step 2: Build to verify**

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add XRFView/Units/xrfview_unit_runner.pas
git commit -m "+ Add xrccmd executable lookup (production + dev paths)"
```

---

### Task 3: Implement Start (CreateProcess with pipe)

**Files:**
- Modify: `XRFView/Units/xrfview_unit_runner.pas`

- [ ] **Step 1: Implement Start method**

```pascal
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
    SI.hStdInput := 0;  // GUI app has no stdin — use null handle
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
    // Close write end in parent — child has its own handle
    CloseHandle(WritePipe);
  end;
end;
```

- [ ] **Step 2: Build to verify**

Expected: Build succeeds.

- [ ] **Step 3: Commit**

```bash
git add XRFView/Units/xrfview_unit_runner.pas
git commit -m "+ Implement TXRCRunner.Start with CreateProcess and piped stdout"
```

---

### Task 4: Implement Poll, ReadPipeData, ParseLine

**Files:**
- Modify: `XRFView/Units/xrfview_unit_runner.pas`

- [ ] **Step 1: Implement ReadPipeData**

```pascal
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

  // Last element is incomplete (no trailing newline) — keep in buffer
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
```

- [ ] **Step 2: Implement ParseLine**

Parses iteration data lines and special markers from xrccmd stdout. The iteration line format is: `%5d  %8.4f  %5.3f  ...  %5.3f  %-18s  %4d:%02d`

```pascal
procedure TXRCRunner.ParseLine(const Line: string);
var
  Trimmed: string;
  Data: TRunnerIterationData;
  i: Integer;
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
  // Header format: " Iter       FoM  R_Na  R_Mg  ...    Div  Best                  Time"
  if Trimmed.StartsWith('Iter') then
  begin
    FRColumnCount := 0;
    var Parts := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
    for i := 0 to High(Parts) do
      if Parts[i].StartsWith('R_') then
        Inc(FRColumnCount);
    Exit;
  end;

  // Try to parse as iteration data line: starts with digits
  if (Length(Trimmed) = 0) or not (Trimmed[1] in ['0'..'9']) then
    Exit;

  // Use fixed-width positional parsing based on the known format strings:
  // Format('%5d  %8.4f', [Iter, FoM])  = columns 1-5, 7-14
  // Per-element: Format('  %5.3f', [RPeak])  = 2+5 = 7 chars each
  // Final: Format('  %5.3f  %-18s  %4d:%02d', [Div, Best, Min, Sec])
  //
  // But it's simpler to parse from the front using known column count:
  // Columns: [Iter] [FoM] [R1] [R2] ... [Rn] [Div] [Best...] [Time]
  // where n = FRColumnCount, and Best may contain spaces (%-18s)

  if FRColumnCount = 0 then Exit; // haven't seen header yet

  var Parts := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
  // Expected: Iter(0), FoM(1), R_1..R_n(2..1+n), Div(2+n), Best(3+n..), Time(last)
  var MinParts := 2 + FRColumnCount + 1 + 1 + 1; // Iter,FoM,Rs,Div,>=1 Best part,Time
  if Length(Parts) < MinParts then Exit;

  if not TryStrToInt(Parts[0], Data.Iteration) then Exit;
  if not TryStrToFloat(Parts[1], Data.FoM) then Exit;

  // R values: indices 2 through 1+FRColumnCount
  SetLength(Data.ElementR, FRColumnCount);
  for i := 0 to FRColumnCount - 1 do
  begin
    var RVal: Double;
    if TryStrToFloat(Parts[2 + i], RVal) then
      Data.ElementR[i] := RVal;
  end;

  // Diversity: index 2+FRColumnCount
  var DivIdx := 2 + FRColumnCount;
  TryStrToFloat(Parts[DivIdx], Data.Diversity);

  // Time: last part (format "M:SS")
  var TimeStr := Parts[High(Parts)];
  var ColonPos := Pos(':', TimeStr);
  if ColonPos > 0 then
  begin
    var Min, Sec: Integer;
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
```

- [ ] **Step 3: Implement CheckProcessExit and Poll**

```pascal
procedure TXRCRunner.CheckProcessExit;
var
  ExitCode: DWORD;
begin
  if FProcessHandle = INVALID_HANDLE_VALUE then Exit;
  if WaitForSingleObject(FProcessHandle, 0) <> WAIT_OBJECT_0 then Exit;

  // Process has exited — drain remaining pipe data
  ReadPipeData;

  // Flush any remaining buffer
  if FBuffer <> '' then
  begin
    var LastLine := string(FBuffer);
    FBuffer := '';
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
```

- [ ] **Step 4: Implement Cancel**

```pascal
procedure TXRCRunner.Cancel;
begin
  if (FState <> rsRunning) or (FProcessHandle = INVALID_HANDLE_VALUE) then Exit;
  FState := rsCancelled;
  TerminateProcess(FProcessHandle, 1);
  // Cleanup will happen in next Poll -> CheckProcessExit
end;
```

- [ ] **Step 5: Build to verify**

Expected: Build succeeds.

- [ ] **Step 6: Commit**

```bash
git add XRFView/Units/xrfview_unit_runner.pas
git commit -m "+ Implement TXRCRunner pipe reading, stdout parsing, and polling"
```

---

## Chunk 2: Progress Tab Upgrade

### Task 5: Add TMemo log to frame_ProgressView

**Files:**
- Modify: `XRFView/Views/frame_ProgressView.pas`
- Modify: `XRFView/Views/frame_ProgressView.dfm`

- [ ] **Step 1: Update DFM — add splitter pane and memo**

Replace the entire DFM with a layout that has the chart on top and a memo below, separated by a splitter. Use TPanel as containers since TRzSplitter expects child panels.

Note: DFM alignment order matters — `alBottom` controls must be declared BEFORE `alClient` controls so VCL processes them first. Otherwise the client control fills the entire area.

```dfm
object frameProgressView: TframeProgressView
  Left = 0
  Top = 0
  Width = 600
  Height = 400
  TabOrder = 0
  object MemoLog: TMemo
    Left = 0
    Top = 264
    Width = 600
    Height = 136
    Align = alBottom
    AlignWithMargins = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 260
    Width = 600
    Height = 4
    Cursor = crVSplit
    Align = alBottom
  end
  object pnlChart: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 260
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    object chrtProgress: TChart
      Left = 0
      Top = 0
      Width = 600
      Height = 260
      Align = alClient
      AlignWithMargins = True
      View3D = False
      TabOrder = 0
    end
  end
end
```

- [ ] **Step 2: Update the Pascal unit — add new fields, uses, and methods**

```pascal
unit frame_ProgressView;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  unit_xrfx_package, xrfview_unit_runner;

type
  TframeProgressView = class(TFrame)
    pnlChart: TPanel;
    chrtProgress: TChart;
    Splitter1: TSplitter;
    MemoLog: TMemo;
  private
    FLiveSeries: TLineSeries;
    FLiveMode: Boolean;
  public
    procedure LoadProgress(const Entries: TArray<TProgressEntry>);
    procedure LoadProgressLog(const LogText: string);
    procedure Clear;
    procedure SetLiveMode;
    procedure SetStaticMode;
    procedure AddIteration(const Data: TRunnerIterationData);
    procedure AppendLog(const Line: string);
  end;

implementation

{$R *.dfm}

procedure TframeProgressView.LoadProgress(const Entries: TArray<TProgressEntry>);
var
  Series: TLineSeries;
  i: Integer;
begin
  Clear;
  FLiveMode := False;
  Series := TLineSeries.Create(chrtProgress);
  Series.Title := 'FoM';

  for i := 0 to High(Entries) do
    Series.AddXY(Entries[i].Iteration, Entries[i].FoM);

  chrtProgress.AddSeries(Series);
  chrtProgress.LeftAxis.Logarithmic := True;
  chrtProgress.BottomAxis.Title.Caption := 'Iteration';
  chrtProgress.LeftAxis.Title.Caption := 'Figure of Merit';
end;

procedure TframeProgressView.LoadProgressLog(const LogText: string);
begin
  MemoLog.Lines.Text := LogText;
end;

procedure TframeProgressView.Clear;
begin
  chrtProgress.FreeAllSeries;
  FLiveSeries := nil;
  MemoLog.Lines.Clear;
end;

procedure TframeProgressView.SetLiveMode;
begin
  Clear;
  FLiveMode := True;
  FLiveSeries := TLineSeries.Create(chrtProgress);
  FLiveSeries.Title := 'FoM';
  chrtProgress.AddSeries(FLiveSeries);
  chrtProgress.LeftAxis.Logarithmic := False;
  chrtProgress.BottomAxis.Title.Caption := 'Iteration';
  chrtProgress.LeftAxis.Title.Caption := 'Figure of Merit';
end;

procedure TframeProgressView.SetStaticMode;
begin
  FLiveMode := False;
  FLiveSeries := nil;
end;

procedure TframeProgressView.AddIteration(const Data: TRunnerIterationData);
begin
  if not FLiveMode or (FLiveSeries = nil) then Exit;
  FLiveSeries.AddXY(Data.Iteration, Data.FoM);
end;

procedure TframeProgressView.AppendLog(const Line: string);
begin
  MemoLog.Lines.Add(Line);
  // Auto-scroll to bottom
  SendMessage(MemoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

end.
```

- [ ] **Step 3: Build to verify**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeds.

- [ ] **Step 4: Commit**

```bash
git add XRFView/Views/frame_ProgressView.pas XRFView/Views/frame_ProgressView.dfm
git commit -m "+ Upgrade Progress tab with log memo and live/static dual mode"
```

---

## Chunk 3: Config Dialog

### Task 6: Create frm_RunConfig dialog — form and DFM

**Files:**
- Create: `XRFView/Forms/frm_RunConfig.pas`
- Create: `XRFView/Forms/frm_RunConfig.dfm`

The dialog has two panels: Tier 1 (always visible) and an Advanced group (collapsible). Bottom buttons: Run, Save Config, Cancel.

Note: The DFM below defines the non-visual structure. The IDE will manage exact pixel positions. Focus on getting the component hierarchy and properties right.

- [ ] **Step 1: Create the DFM**

Create `XRFView/Forms/frm_RunConfig.dfm`. Define all controls. Use TScrollBox for the main content area so the dialog can handle smaller screens.

Key layout (top to bottom):
- **pnlContent** (TScrollBox, alClient) containing:
  - **grpTargets** (TGroupBox): TCheckListBox for XRF target lines
  - **grpPool** (TGroupBox): TCheckListBox for element pool
  - **grpStructure** (TGroupBox): 3 pairs of TSpinEdit for d/gamma/N ranges
  - **grpOptimizer** (TGroupBox): Population, Iterations, Stagnation limit TSpinEdits
  - **grpTemplate** (TGroupBox): TEdit + browse TButton for template path
  - **grpAdvanced** (TGroupBox): all Tier 2/3 controls, Visible=False initially, toggled by a "Show Advanced" checkbox
- **pnlButtons** (TPanel, alBottom): btnRun, btnSaveConfig, btnCancel, chkAdvanced

Due to the large number of controls, create the DFM programmatically — define only the outer structure in the DFM file and create inner controls in `FormCreate`. This avoids a 300-line DFM and makes maintenance easier.

```dfm
object frmRunConfig: TfrmRunConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Universal Mirror - Run Configuration'
  ClientHeight = 580
  ClientWidth = 520
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  object pnlButtons: TPanel
    Left = 0
    Top = 540
    Width = 520
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnRun: TButton
      Left = 250
      Top = 8
      Width = 80
      Height = 25
      Caption = 'Run'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnSaveConfig: TButton
      Left = 340
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Save Config...'
      TabOrder = 1
    end
    object btnCancel: TButton
      Left = 440
      Top = 8
      Width = 70
      Height = 25
      Caption = 'Cancel'
      Cancel = True
      ModalResult = 2
      TabOrder = 2
    end
    object chkAdvanced: TCheckBox
      Left = 8
      Top = 12
      Width = 120
      Height = 17
      Caption = 'Show Advanced'
      TabOrder = 3
    end
  end
  object ScrollBox: TScrollBox
    Left = 0
    Top = 0
    Width = 520
    Height = 540
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 1
  end
end
```

- [ ] **Step 2: Create the Pascal unit**

```pascal
unit frm_RunConfig;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.Samples.Spin,
  unit_universal_types, unit_universal_io, unit_xrf_lines,
  Vcl.FileCtrl;

type
  TfrmRunConfig = class(TForm)
    pnlButtons: TPanel;
    btnRun: TButton;
    btnSaveConfig: TButton;
    btnCancel: TButton;
    chkAdvanced: TCheckBox;
    ScrollBox: TScrollBox;
    procedure FormCreate(Sender: TObject);
    procedure chkAdvancedClick(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
  private
    // Tier 1
    clbLines: TCheckListBox;
    clbPool: TCheckListBox;
    sedDMin, sedDMax: TSpinEdit;
    sedGammaMin, sedGammaMax: TSpinEdit;
    sedNMin, sedNMax: TSpinEdit;
    sedPopulation, sedIterations, sedStagnation: TSpinEdit;
    edtTemplate: TEdit;
    btnBrowseTemplate: TButton;
    // Tier 2/3 (Advanced)
    grpAdvanced: TGroupBox;
    edtWR, edtWFWHM, edtWPurity: TEdit;
    edtRMinThreshold: TEdit;
    edtDeltaTheta, edtThetaMin: TEdit;
    cmbPolarization: TComboBox;
    edtSigma: TEdit;
    edtSubstrate: TEdit;
    chkPureElements: TCheckBox;
    edtDensityFactor: TEdit;
    edtW1, edtW2, edtTolerance: TEdit;
    sedJammingMax, sedCheckpointEvery: TSpinEdit;
    edtHenkePath: TEdit;
    btnBrowseHenke: TButton;
    clbExcludedPairs: TCheckListBox;
    // Helpers
    procedure CreateTier1Controls;
    procedure CreateAdvancedControls;
    function CreateLabeledEdit(AParent: TWinControl; ATop: Integer;
      const ACaption: string; AWidth: Integer = 80): TEdit;
    function CreateLabeledSpin(AParent: TWinControl; ATop: Integer;
      const ACaption: string; AMin, AMax, AValue: Integer): TSpinEdit;
    procedure BrowseTemplateClick(Sender: TObject);
    procedure BrowseHenkeClick(Sender: TObject);
  public
    procedure SetDefaults;
    procedure LoadFromConfig(const Config: TUniversalConfig);
    function  BuildConfig: TUniversalConfig;
  end;

implementation

{$R *.dfm}

uses
  System.Math;

const
  LBL_WIDTH = 120;
  ROW_HEIGHT = 28;

{ Helper: create a TLabel + TEdit pair }
function TfrmRunConfig.CreateLabeledEdit(AParent: TWinControl; ATop: Integer;
  const ACaption: string; AWidth: Integer): TEdit;
var
  Lbl: TLabel;
begin
  Lbl := TLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.Left := 8;
  Lbl.Top := ATop + 4;
  Lbl.Caption := ACaption;

  Result := TEdit.Create(Self);
  Result.Parent := AParent;
  Result.Left := LBL_WIDTH;
  Result.Top := ATop;
  Result.Width := AWidth;
end;

{ Helper: create a TLabel + TSpinEdit pair }
function TfrmRunConfig.CreateLabeledSpin(AParent: TWinControl; ATop: Integer;
  const ACaption: string; AMin, AMax, AValue: Integer): TSpinEdit;
var
  Lbl: TLabel;
begin
  Lbl := TLabel.Create(Self);
  Lbl.Parent := AParent;
  Lbl.Left := 8;
  Lbl.Top := ATop + 4;
  Lbl.Caption := ACaption;

  Result := TSpinEdit.Create(Self);
  Result.Parent := AParent;
  Result.Left := LBL_WIDTH;
  Result.Top := ATop;
  Result.Width := 80;
  Result.MinValue := AMin;
  Result.MaxValue := AMax;
  Result.Value := AValue;
end;

procedure TfrmRunConfig.CreateTier1Controls;
var
  grp: TGroupBox;
  Row: Integer;
  Elements: TArray<string>;
  i: Integer;
  Lbl: TLabel;
begin
  // Target Lines
  grp := TGroupBox.Create(Self);
  grp.Parent := ScrollBox;
  grp.Left := 8; grp.Top := 4; grp.Width := 490; grp.Height := 110;
  grp.Caption := 'Target XRF Lines';

  clbLines := TCheckListBox.Create(Self);
  clbLines.Parent := grp;
  clbLines.Align := alClient;
  clbLines.AlignWithMargins := True;
  clbLines.Columns := 5;
  // Populate with light elements relevant for universal mirror (Li through Si)
  // Note: XRFLines array is in the implementation section of unit_xrf_lines,
  // so we hardcode the relevant subset here.
  Elements := TArray<string>.Create(
    'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne', 'Na', 'Mg', 'Al', 'Si');
  for i := 0 to High(Elements) do
    clbLines.Items.Add(Elements[i]);

  // Element Pool
  grp := TGroupBox.Create(Self);
  grp.Parent := ScrollBox;
  grp.Left := 8; grp.Top := 120; grp.Width := 490; grp.Height := 90;
  grp.Caption := 'Element Pool';

  clbPool := TCheckListBox.Create(Self);
  clbPool.Parent := grp;
  clbPool.Align := alClient;
  clbPool.AlignWithMargins := True;
  clbPool.Columns := 5;
  // Common mirror materials
  Elements := TArray<string>.Create('W', 'Mo', 'Cr', 'Si', 'B', 'B4C',
    'Sc', 'C', 'Ni', 'Co', 'La', 'Pt', 'Ru', 'V', 'Ti', 'Nb');
  for i := 0 to High(Elements) do
    clbPool.Items.Add(Elements[i]);

  // Structure Parameters
  grp := TGroupBox.Create(Self);
  grp.Parent := ScrollBox;
  grp.Left := 8; grp.Top := 216; grp.Width := 490; grp.Height := 100;
  grp.Caption := 'Structure';

  Row := 18;
  sedDMin := CreateLabeledSpin(grp, Row, 'd min (A)', 10, 500, 30);
  Lbl := TLabel.Create(Self); Lbl.Parent := grp;
  Lbl.Left := 220; Lbl.Top := Row + 4; Lbl.Caption := 'd max (A)';
  sedDMax := TSpinEdit.Create(Self); sedDMax.Parent := grp;
  sedDMax.Left := 310; sedDMax.Top := Row; sedDMax.Width := 80;
  sedDMax.MinValue := 10; sedDMax.MaxValue := 500; sedDMax.Value := 80;

  Inc(Row, ROW_HEIGHT);
  sedGammaMin := CreateLabeledSpin(grp, Row, 'Gamma min (x100)', 1, 99, 15);
  Lbl := TLabel.Create(Self); Lbl.Parent := grp;
  Lbl.Left := 220; Lbl.Top := Row + 4; Lbl.Caption := 'Gamma max (x100)';
  sedGammaMax := TSpinEdit.Create(Self); sedGammaMax.Parent := grp;
  sedGammaMax.Left := 310; sedGammaMax.Top := Row; sedGammaMax.Width := 80;
  sedGammaMax.MinValue := 1; sedGammaMax.MaxValue := 99; sedGammaMax.Value := 70;

  Inc(Row, ROW_HEIGHT);
  sedNMin := CreateLabeledSpin(grp, Row, 'N min', 1, 1000, 40);
  Lbl := TLabel.Create(Self); Lbl.Parent := grp;
  Lbl.Left := 220; Lbl.Top := Row + 4; Lbl.Caption := 'N max';
  sedNMax := TSpinEdit.Create(Self); sedNMax.Parent := grp;
  sedNMax.Left := 310; sedNMax.Top := Row; sedNMax.Width := 80;
  sedNMax.MinValue := 1; sedNMax.MaxValue := 1000; sedNMax.Value := 200;

  // Optimizer Parameters
  grp := TGroupBox.Create(Self);
  grp.Parent := ScrollBox;
  grp.Left := 8; grp.Top := 322; grp.Width := 490; grp.Height := 100;
  grp.Caption := 'Optimizer';

  Row := 18;
  sedPopulation := CreateLabeledSpin(grp, Row, 'Population', 10, 10000, 1000);
  Inc(Row, ROW_HEIGHT);
  sedIterations := CreateLabeledSpin(grp, Row, 'Iterations', 1, 10000, 100);
  Inc(Row, ROW_HEIGHT);
  sedStagnation := CreateLabeledSpin(grp, Row, 'Stagnation limit', 1, 10000, 200);

  // Template File
  grp := TGroupBox.Create(Self);
  grp.Parent := ScrollBox;
  grp.Left := 8; grp.Top := 428; grp.Width := 490; grp.Height := 50;
  grp.Caption := 'Template File';

  edtTemplate := TEdit.Create(Self);
  edtTemplate.Parent := grp;
  edtTemplate.Left := 8; edtTemplate.Top := 20;
  edtTemplate.Width := 430;

  btnBrowseTemplate := TButton.Create(Self);
  btnBrowseTemplate.Parent := grp;
  btnBrowseTemplate.Left := 445; btnBrowseTemplate.Top := 18;
  btnBrowseTemplate.Width := 35; btnBrowseTemplate.Height := 25;
  btnBrowseTemplate.Caption := '...';
  btnBrowseTemplate.OnClick := BrowseTemplateClick;
end;

procedure TfrmRunConfig.CreateAdvancedControls;
var
  Row: Integer;
  Lbl: TLabel;
begin
  grpAdvanced := TGroupBox.Create(Self);
  grpAdvanced.Parent := ScrollBox;
  grpAdvanced.Left := 8; grpAdvanced.Top := 484;
  grpAdvanced.Width := 490; grpAdvanced.Height := 320;
  grpAdvanced.Caption := 'Advanced';
  grpAdvanced.Visible := False;

  Row := 18;
  edtWR := CreateLabeledEdit(grpAdvanced, Row, 'w_R'); edtWR.Text := '1.0';
  Inc(Row, ROW_HEIGHT);
  edtWFWHM := CreateLabeledEdit(grpAdvanced, Row, 'w_FWHM'); edtWFWHM.Text := '0.1';
  Inc(Row, ROW_HEIGHT);
  edtWPurity := CreateLabeledEdit(grpAdvanced, Row, 'w_purity'); edtWPurity.Text := '1.0';
  Inc(Row, ROW_HEIGHT);
  edtRMinThreshold := CreateLabeledEdit(grpAdvanced, Row, 'R_min threshold'); edtRMinThreshold.Text := '0.001';
  Inc(Row, ROW_HEIGHT);
  edtDeltaTheta := CreateLabeledEdit(grpAdvanced, Row, 'Delta theta (deg)'); edtDeltaTheta.Text := '0';
  Inc(Row, ROW_HEIGHT);
  edtThetaMin := CreateLabeledEdit(grpAdvanced, Row, 'Theta min (deg)'); edtThetaMin.Text := '0';
  Inc(Row, ROW_HEIGHT);

  Lbl := TLabel.Create(Self); Lbl.Parent := grpAdvanced;
  Lbl.Left := 8; Lbl.Top := Row + 4; Lbl.Caption := 'Polarization';
  cmbPolarization := TComboBox.Create(Self);
  cmbPolarization.Parent := grpAdvanced;
  cmbPolarization.Left := LBL_WIDTH; cmbPolarization.Top := Row;
  cmbPolarization.Width := 80; cmbPolarization.Style := csDropDownList;
  cmbPolarization.Items.Add('sp'); cmbPolarization.Items.Add('s');
  cmbPolarization.ItemIndex := 0;
  Inc(Row, ROW_HEIGHT);

  edtSigma := CreateLabeledEdit(grpAdvanced, Row, 'Sigma (A)'); edtSigma.Text := '3.5';
  Inc(Row, ROW_HEIGHT);
  edtSubstrate := CreateLabeledEdit(grpAdvanced, Row, 'Substrate'); edtSubstrate.Text := 'SiO2';
  Inc(Row, ROW_HEIGHT);

  chkPureElements := TCheckBox.Create(Self);
  chkPureElements.Parent := grpAdvanced;
  chkPureElements.Left := 8; chkPureElements.Top := Row;
  chkPureElements.Width := 200;
  chkPureElements.Caption := 'Pure elements (no mixing)';
  chkPureElements.Checked := True;
  Inc(Row, ROW_HEIGHT);

  edtDensityFactor := CreateLabeledEdit(grpAdvanced, Row, 'Density factor'); edtDensityFactor.Text := '0.95';
  Inc(Row, ROW_HEIGHT);
  edtW1 := CreateLabeledEdit(grpAdvanced, Row, 'PSO w1'); edtW1.Text := '0.4';

  Lbl := TLabel.Create(Self); Lbl.Parent := grpAdvanced;
  Lbl.Left := 220; Lbl.Top := Row + 4; Lbl.Caption := 'PSO w2';
  edtW2 := TEdit.Create(Self); edtW2.Parent := grpAdvanced;
  edtW2.Left := 310; edtW2.Top := Row; edtW2.Width := 80; edtW2.Text := '0.5';
  Inc(Row, ROW_HEIGHT);

  edtTolerance := CreateLabeledEdit(grpAdvanced, Row, 'Tolerance'); edtTolerance.Text := '1e-5';
  Inc(Row, ROW_HEIGHT);
  sedJammingMax := CreateLabeledSpin(grpAdvanced, Row, 'Jamming max', 1, 100, 5);
  Inc(Row, ROW_HEIGHT);
  sedCheckpointEvery := CreateLabeledSpin(grpAdvanced, Row, 'Checkpoint every', 1, 10000, 100);
  Inc(Row, ROW_HEIGHT);

  edtHenkePath := CreateLabeledEdit(grpAdvanced, Row, 'Henke path', 300);
  edtHenkePath.Text := 'D:\DelphiProjects\X-RayCalc\Henke';
  btnBrowseHenke := TButton.Create(Self);
  btnBrowseHenke.Parent := grpAdvanced;
  btnBrowseHenke.Left := 445; btnBrowseHenke.Top := Row;
  btnBrowseHenke.Width := 35; btnBrowseHenke.Height := 25;
  btnBrowseHenke.Caption := '...';
  btnBrowseHenke.OnClick := BrowseHenkeClick;
  Inc(Row, ROW_HEIGHT + 4);

  // Excluded pairs (populated dynamically based on element pool)
  Lbl := TLabel.Create(Self); Lbl.Parent := grpAdvanced;
  Lbl.Left := 8; Lbl.Top := Row; Lbl.Caption := 'Excluded pairs:';
  Inc(Row, 18);

  clbExcludedPairs := TCheckListBox.Create(Self);
  clbExcludedPairs.Parent := grpAdvanced;
  clbExcludedPairs.Left := 8; clbExcludedPairs.Top := Row;
  clbExcludedPairs.Width := 470; clbExcludedPairs.Height := 80;
  clbExcludedPairs.Columns := 3;
  Inc(Row, 84);

  // Update group height to fit all controls
  grpAdvanced.Height := Row + 8;
end;

procedure TfrmRunConfig.FormCreate(Sender: TObject);
begin
  CreateTier1Controls;
  CreateAdvancedControls;
end;

procedure TfrmRunConfig.chkAdvancedClick(Sender: TObject);
begin
  grpAdvanced.Visible := chkAdvanced.Checked;
end;

procedure TfrmRunConfig.BrowseTemplateClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(Self);
  try
    Dlg.Filter := 'JSON files|*.json';
    Dlg.DefaultExt := 'json';
    if edtTemplate.Text <> '' then
      Dlg.InitialDir := ExtractFilePath(edtTemplate.Text);
    if Dlg.Execute then
      edtTemplate.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmRunConfig.BrowseHenkeClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtHenkePath.Text;
  if SelectDirectory('Select Henke Database Folder', '', Dir) then
    edtHenkePath.Text := Dir;
end;

procedure TfrmRunConfig.btnSaveConfigClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Config: TUniversalConfig;
begin
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Filter := 'JSON config|*.json';
    Dlg.DefaultExt := 'json';
    if Dlg.Execute then
    begin
      Config := BuildConfig;
      TUniversalIO.SaveConfig(Config, Dlg.FileName);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmRunConfig.SetDefaults;
var
  i: Integer;
  DefaultLines: TArray<string>;
  DefaultPool: TArray<string>;
begin
  // Lines: check Be through Si (Z=4..14)
  DefaultLines := TArray<string>.Create('Be', 'B', 'C', 'N', 'O', 'F', 'Na', 'Mg', 'Al', 'Si');
  for i := 0 to clbLines.Count - 1 do
    clbLines.Checked[i] := False;
  for i := 0 to clbLines.Count - 1 do
  begin
    for var S in DefaultLines do
      if SameText(clbLines.Items[i], S) then
      begin
        clbLines.Checked[i] := True;
        Break;
      end;
  end;

  // Pool: check default materials
  DefaultPool := TArray<string>.Create('W', 'Mo', 'Cr', 'Si', 'B', 'B4C', 'Sc', 'C');
  for i := 0 to clbPool.Count - 1 do
    clbPool.Checked[i] := False;
  for i := 0 to clbPool.Count - 1 do
  begin
    for var S in DefaultPool do
      if SameText(clbPool.Items[i], S) then
      begin
        clbPool.Checked[i] := True;
        Break;
      end;
  end;

  // Structure
  sedDMin.Value := 30; sedDMax.Value := 80;
  sedGammaMin.Value := 15; sedGammaMax.Value := 70;
  sedNMin.Value := 40; sedNMax.Value := 200;

  // Optimizer
  sedPopulation.Value := 1000;
  sedIterations.Value := 100;
  sedStagnation.Value := 200;

  // Template
  edtTemplate.Text := '';

  // Advanced defaults are set in CreateAdvancedControls
end;

procedure TfrmRunConfig.LoadFromConfig(const Config: TUniversalConfig);
var
  i, j: Integer;
begin
  // Lines
  for i := 0 to clbLines.Count - 1 do
  begin
    clbLines.Checked[i] := False;
    for j := 0 to High(Config.Lines) do
      if SameText(clbLines.Items[i], Config.Lines[j].Name) then
      begin
        clbLines.Checked[i] := True;
        Break;
      end;
  end;

  // Pool
  for i := 0 to clbPool.Count - 1 do
  begin
    clbPool.Checked[i] := False;
    for j := 0 to High(Config.ElementPool) do
      if SameText(clbPool.Items[i], Config.ElementPool[j]) then
      begin
        clbPool.Checked[i] := True;
        Break;
      end;
  end;

  // Structure
  sedDMin.Value := Round(Config.Structure.dRange.Min);
  sedDMax.Value := Round(Config.Structure.dRange.Max);
  sedGammaMin.Value := Round(Config.Structure.GammaRange.Min * 100);
  sedGammaMax.Value := Round(Config.Structure.GammaRange.Max * 100);
  sedNMin.Value := Round(Config.Structure.NRange.Min);
  sedNMax.Value := Round(Config.Structure.NRange.Max);

  // Optimizer
  sedPopulation.Value := Config.Optimizer.Population;
  sedIterations.Value := Config.Optimizer.Iterations;
  sedStagnation.Value := Config.Optimizer.StagnationLimit;

  // Template
  edtTemplate.Text := Config.TemplatePath;

  // Advanced
  edtWR.Text := FormatFloat('0.###', Config.Fitness.wR);
  edtWFWHM.Text := FormatFloat('0.###', Config.Fitness.wFWHM);
  edtWPurity.Text := FormatFloat('0.###', Config.Fitness.wPurity);
  edtRMinThreshold.Text := FormatFloat('0.######', Config.Fitness.RMinThreshold);
  edtDeltaTheta.Text := FormatFloat('0.###', Config.Fitness.DeltaTheta);
  edtThetaMin.Text := FormatFloat('0.#', Config.Fitness.ThetaMin);
  if Config.Fitness.Polarization = cmS then
    cmbPolarization.ItemIndex := 1
  else
    cmbPolarization.ItemIndex := 0;

  if Config.Structure.SigmaFixed >= 0 then
    edtSigma.Text := FormatFloat('0.#', Config.Structure.SigmaFixed)
  else
    edtSigma.Text := FormatFloat('0.#', Config.Structure.SigmaRange.Min);

  edtSubstrate.Text := Config.Substrate;
  chkPureElements.Checked := Config.Structure.PureElements;

  if Config.Structure.DensityFactorFixed >= 0 then
    edtDensityFactor.Text := FormatFloat('0.##', Config.Structure.DensityFactorFixed)
  else
    edtDensityFactor.Text := FormatFloat('0.##', Config.Structure.DensityFactorRange.Min);

  edtW1.Text := FormatFloat('0.###', Config.Optimizer.w1);
  edtW2.Text := FormatFloat('0.###', Config.Optimizer.w2);
  edtTolerance.Text := FormatFloat('0.#####E+00', Config.Optimizer.Tolerance);
  sedJammingMax.Value := Config.Optimizer.JammingMax;
  sedCheckpointEvery.Value := Config.Optimizer.CheckpointEvery;
  edtHenkePath.Text := Config.HenkePath;

  // Rebuild excluded pairs list based on current pool
  clbExcludedPairs.Items.Clear;
  for i := 0 to High(Config.ElementPool) - 1 do
    for j := i + 1 to High(Config.ElementPool) do
      clbExcludedPairs.Items.Add(Config.ElementPool[i] + '/' + Config.ElementPool[j]);

  // Check items that match existing exclusions
  for i := 0 to clbExcludedPairs.Count - 1 do
  begin
    clbExcludedPairs.Checked[i] := False;
    for j := 0 to High(Config.ExcludedPairs) do
    begin
      var PairStr := Config.ElementPool[Config.ExcludedPairs[j].Idx1] + '/' +
                     Config.ElementPool[Config.ExcludedPairs[j].Idx2];
      if SameText(clbExcludedPairs.Items[i], PairStr) then
      begin
        clbExcludedPairs.Checked[i] := True;
        Break;
      end;
    end;
  end;
end;

function TfrmRunConfig.BuildConfig: TUniversalConfig;
var
  i, Count: Integer;
begin
  Result := Default(TUniversalConfig);

  // Lines
  Count := 0;
  for i := 0 to clbLines.Count - 1 do
    if clbLines.Checked[i] then Inc(Count);
  SetLength(Result.Lines, Count);
  Count := 0;
  for i := 0 to clbLines.Count - 1 do
    if clbLines.Checked[i] then
    begin
      Result.Lines[Count].Name := clbLines.Items[i];
      Result.Lines[Count].Lambda := GetXRFLambda(clbLines.Items[i]);
      Result.Lines[Count].Weight := 1.0;
      Inc(Count);
    end;

  // Pool
  Count := 0;
  for i := 0 to clbPool.Count - 1 do
    if clbPool.Checked[i] then Inc(Count);
  SetLength(Result.ElementPool, Count);
  Count := 0;
  for i := 0 to clbPool.Count - 1 do
    if clbPool.Checked[i] then
    begin
      Result.ElementPool[Count] := clbPool.Items[i];
      Inc(Count);
    end;

  // Excluded pairs: parse "Mat1/Mat2" items from checklist
  SetLength(Result.ExcludedPairs, 0);
  for i := 0 to clbExcludedPairs.Count - 1 do
    if clbExcludedPairs.Checked[i] then
    begin
      var PairStr := clbExcludedPairs.Items[i];
      var SlashPos := Pos('/', PairStr);
      if SlashPos > 0 then
      begin
        var Mat1 := Copy(PairStr, 1, SlashPos - 1);
        var Mat2 := Copy(PairStr, SlashPos + 1, MaxInt);
        var Idx1 := -1; var Idx2 := -1;
        for var k := 0 to High(Result.ElementPool) do
        begin
          if SameText(Result.ElementPool[k], Mat1) then Idx1 := k;
          if SameText(Result.ElementPool[k], Mat2) then Idx2 := k;
        end;
        if (Idx1 >= 0) and (Idx2 >= 0) then
        begin
          SetLength(Result.ExcludedPairs, Length(Result.ExcludedPairs) + 1);
          Result.ExcludedPairs[High(Result.ExcludedPairs)].Idx1 := Idx1;
          Result.ExcludedPairs[High(Result.ExcludedPairs)].Idx2 := Idx2;
        end;
      end;
    end;

  // Structure
  Result.Structure.StructureType := 'bilayer';
  Result.Structure.LayersPerPeriod := 2;
  Result.Structure.PureElements := chkPureElements.Checked;
  Result.Structure.dRange.Min := sedDMin.Value;
  Result.Structure.dRange.Max := sedDMax.Value;
  Result.Structure.GammaRange.Min := sedGammaMin.Value / 100.0;
  Result.Structure.GammaRange.Max := sedGammaMax.Value / 100.0;
  Result.Structure.NRange.Min := sedNMin.Value;
  Result.Structure.NRange.Max := sedNMax.Value;

  var SigmaVal := StrToFloatDef(edtSigma.Text, 3.5);
  Result.Structure.SigmaFixed := SigmaVal;
  Result.Structure.SigmaRange.Min := SigmaVal;
  Result.Structure.SigmaRange.Max := SigmaVal;

  var DFVal := StrToFloatDef(edtDensityFactor.Text, 0.95);
  Result.Structure.DensityFactorFixed := DFVal;
  Result.Structure.DensityFactorRange.Min := DFVal;
  Result.Structure.DensityFactorRange.Max := DFVal;

  // Fitness
  Result.Fitness.wR := StrToFloatDef(edtWR.Text, 1.0);
  Result.Fitness.wFWHM := StrToFloatDef(edtWFWHM.Text, 0.1);
  Result.Fitness.wPurity := StrToFloatDef(edtWPurity.Text, 1.0);
  Result.Fitness.RMinThreshold := StrToFloatDef(edtRMinThreshold.Text, 0.001);
  Result.Fitness.DeltaTheta := StrToFloatDef(edtDeltaTheta.Text, 0);
  Result.Fitness.ThetaMin := StrToFloatDef(edtThetaMin.Text, 0);
  if cmbPolarization.ItemIndex = 1 then
    Result.Fitness.Polarization := cmS
  else
    Result.Fitness.Polarization := cmSP;

  // Optimizer
  Result.Optimizer.Population := sedPopulation.Value;
  Result.Optimizer.Iterations := sedIterations.Value;
  Result.Optimizer.StagnationLimit := sedStagnation.Value;
  Result.Optimizer.w1 := StrToFloatDef(edtW1.Text, 0.4);
  Result.Optimizer.w2 := StrToFloatDef(edtW2.Text, 0.5);
  Result.Optimizer.Tolerance := StrToFloatDef(edtTolerance.Text, 1e-5);
  Result.Optimizer.JammingMax := sedJammingMax.Value;
  Result.Optimizer.CheckpointEvery := sedCheckpointEvery.Value;

  // Top-level
  Result.Substrate := edtSubstrate.Text;
  Result.HenkePath := edtHenkePath.Text;
  Result.TemplatePath := edtTemplate.Text;
  // OutputDir and ResumeFrom are set by the caller
end;

end.
```

- [ ] **Step 3: Add to XRFView.dpr uses clause**

Add to the uses clause in `XRFView.dpr`:
```pascal
  frm_RunConfig in 'Forms\frm_RunConfig.pas' {frmRunConfig},
  unit_universal_io in '..\Universal\unit_universal_io.pas',
  unit_xrf_lines in '..\Universal\unit_xrf_lines.pas',
```

Do NOT add `Application.CreateForm(TfrmRunConfig, ...)` — the dialog is created on demand, not at startup.

- [ ] **Step 4: Add to XRFView.dproj**

Add the new files to the project's `<DCCReference>` section in `XRFView.dproj`. Also ensure the search path includes `../Universal` (it already does for `unit_xrfx_package` and `unit_universal_types`).

Additionally add to the search path: `../Math` (needed for `unit_materials_mix.pas` which is used by `unit_universal_io.pas`), and `../XRC_CMD/units` (needed for `cmd_unit_types.pas` used by `unit_universal_types.pas`).

Check current search path in XRFView.dproj and add any missing paths.

- [ ] **Step 5: Build to verify**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeds. Resolve any missing unit references by adding search paths to the dproj.

- [ ] **Step 6: Commit**

```bash
git add XRFView/Forms/frm_RunConfig.pas XRFView/Forms/frm_RunConfig.dfm XRFView/XRFView.dpr XRFView/XRFView.dproj
git commit -m "+ Add run configuration dialog with Tier 1/2/3 controls"
```

---

## Chunk 4: Main Form Integration

### Task 7: Create toolbar icons

**Files:**
- Create: `Assets/ToolIcons/XRFView/04_NewRun.png`
- Create: `Assets/ToolIcons/XRFView/05_EditRun.png`
- Create: `Assets/ToolIcons/XRFView/06_Stop.png`
- Modify: `XRFView/XRFViewIcons.rc`

- [ ] **Step 1: Generate icon PNGs**

Use Python/Pillow to create 24x24 PNG icons matching the existing style. See `@icon-creation` skill if available. The icons should be:
- **04_NewRun.png** — green "play" triangle or a "+" symbol
- **05_EditRun.png** — pencil/edit icon or a gear
- **06_Stop.png** — red square (stop)

```python
from PIL import Image, ImageDraw
import os

out = r'D:\DelphiProjects\X-RayCalc\X-RayCalc3_Working\Assets\ToolIcons\XRFView'

# NewRun: green play triangle
img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(6, 4), (6, 20), (20, 12)], fill=(34, 139, 34, 255))
img.save(os.path.join(out, '04_NewRun.png'))

# EditRun: blue gear/pencil
img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.polygon([(4, 20), (16, 4), (20, 8), (8, 24)], fill=(65, 105, 225, 255))
d.rectangle([(4, 18), (10, 22)], fill=(65, 105, 225, 255))
img.save(os.path.join(out, '05_EditRun.png'))

# Stop: red square
img = Image.new('RGBA', (24, 24), (0, 0, 0, 0))
d = ImageDraw.Draw(img)
d.rectangle([(5, 5), (19, 19)], fill=(220, 20, 20, 255))
img.save(os.path.join(out, '06_Stop.png'))
```

- [ ] **Step 2: Update XRFViewIcons.rc**

Append to `XRFView/XRFViewIcons.rc`:

```
ICON_NEWRUN RCDATA "..\\Assets\\ToolIcons\\XRFView\\04_NewRun.png"
ICON_EDITRUN RCDATA "..\\Assets\\ToolIcons\\XRFView\\05_EditRun.png"
ICON_STOP RCDATA "..\\Assets\\ToolIcons\\XRFView\\06_Stop.png"
```

- [ ] **Step 3: Recompile RC to RES**

The `.dpr` references `{$R XRFViewIcons.RES}` so the `.rc` must be compiled into `.RES`. Check if the build system auto-compiles it (MSBuild RC task in `.dproj`). If not, run manually:

```bash
cmd.exe //c "\"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\brcc64.exe\" XRFView\XRFViewIcons.rc -foXRFView\XRFViewIcons.RES" 2>&1
```

Verify the RES file is updated (file timestamp should be current).

- [ ] **Step 4: Commit**

```bash
git add Assets/ToolIcons/XRFView/04_NewRun.png Assets/ToolIcons/XRFView/05_EditRun.png Assets/ToolIcons/XRFView/06_Stop.png XRFView/XRFViewIcons.rc XRFView/XRFViewIcons.RES
git commit -m "+ Add toolbar icons for New Run, Edit Run, Stop"
```

---

### Task 8: Add toolbar buttons and runner integration to main form

**Files:**
- Modify: `XRFView/Forms/frm_XRFViewMain.pas`
- Modify: `XRFView/Forms/frm_XRFViewMain.dfm`

- [ ] **Step 1: Add toolbar buttons to DFM**

In `frm_XRFViewMain.dfm`, inside the `ToolBar1` object, add after `btnSaveImage`:

```dfm
    object tbSep1: TToolButton
      Left = 92
      Width = 8
      Style = tbsSeparator
    end
    object btnNewRun: TToolButton
      Left = 100
      Caption = 'New Run'
      ImageIndex = 4
      OnClick = btnNewRunClick
    end
    object btnEditRun: TToolButton
      Left = 123
      Caption = 'Edit Run'
      ImageIndex = 5
      OnClick = btnEditRunClick
    end
    object tbSep2: TToolButton
      Left = 146
      Width = 8
      Style = tbsSeparator
    end
    object btnStop: TToolButton
      Left = 154
      Caption = 'Stop'
      ImageIndex = 6
      Visible = False
      OnClick = btnStopClick
    end
```

Note: Exact Left values don't matter — the toolbar auto-positions its buttons. The IDE will fix these on first open.

- [ ] **Step 2: Update the Pascal form class declaration**

In `frm_XRFViewMain.pas`, add to the `TfrmXRFViewMain` class in the published/DFM section (before `private`):

```pascal
    tbSep1: TToolButton;
    btnNewRun: TToolButton;
    btnEditRun: TToolButton;
    tbSep2: TToolButton;
    btnStop: TToolButton;
    procedure btnNewRunClick(Sender: TObject);
    procedure btnEditRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
```

Add to the `private` section:

```pascal
    FRunner: TXRCRunner;
    FRunTimer: TTimer;
    FRunStartTime: TDateTime;
    procedure HandleIteration(const Data: TRunnerIterationData);
    procedure HandleCompleted(const XRFXPath: string);
    procedure HandleError(const ErrorMsg: string);
    procedure HandleRawLine(const Line: string);
    procedure RunTimerTick(Sender: TObject);
    procedure UpdateRunState;
    procedure StartRun(const ConfigPath: string);
```

Add to the `uses` clause in the `interface` section: `xrfview_unit_runner` (if not already there from frame_ProgressView).

Add to the `uses` clause in the `implementation` section: `frm_RunConfig, unit_universal_io, unit_universal_types`.

- [ ] **Step 3: Update LoadToolBarIcons to load 7 icons**

Change the `ResNames` array:

```pascal
procedure TfrmXRFViewMain.LoadToolBarIcons;
const
  ResNames: array[0..6] of string = (
    'ICON_REFRESH', 'ICON_EXPORT', 'ICON_COPY', 'ICON_SAVEIMG',
    'ICON_NEWRUN', 'ICON_EDITRUN', 'ICON_STOP');
```

- [ ] **Step 4: Implement FormCreate additions**

At the end of `FormCreate`, add:

```pascal
  FRunner := TXRCRunner.Create;
  FRunner.OnIteration := HandleIteration;
  FRunner.OnCompleted := HandleCompleted;
  FRunner.OnError := HandleError;
  FRunner.OnRawLine := HandleRawLine;

  FRunTimer := TTimer.Create(Self);
  FRunTimer.Interval := 100;
  FRunTimer.Enabled := False;
  FRunTimer.OnTimer := RunTimerTick;
```

- [ ] **Step 5: Implement FormDestroy addition**

Before `FreeAndNil(FLoader)`, add:

```pascal
  if FRunner.State = rsRunning then
    FRunner.Cancel;
  FreeAndNil(FRunner);
```

- [ ] **Step 6: Implement the runner event handlers and button clicks**

```pascal
procedure TfrmXRFViewMain.RunTimerTick(Sender: TObject);
begin
  FRunner.Poll;
end;

procedure TfrmXRFViewMain.HandleIteration(const Data: TRunnerIterationData);
var
  Elapsed: TDateTime;
  Min, Sec: Integer;
begin
  FProgressView.AddIteration(Data);
  Elapsed := Now - FRunStartTime;
  Min := Trunc(Elapsed * 24 * 60);
  Sec := Trunc(Elapsed * 24 * 3600) mod 60;
  spStatus.Caption := Format('Running... Iteration %d | FoM: %.4f | %d:%02d',
    [Data.Iteration, Data.FoM, Min, Sec]);
end;

procedure TfrmXRFViewMain.HandleCompleted(const XRFXPath: string);
begin
  FRunTimer.Enabled := False;

  // Delete temp config JSON
  if TFile.Exists(FRunner.ConfigPath) then
    TFile.Delete(FRunner.ConfigPath);

  // Clean up temp output_dir
  var TempOutputDir := ExtractFilePath(FRunner.ConfigPath) + TEMP_OUTPUT_DIR;
  if TDirectory.Exists(TempOutputDir) then
    TDirectory.Delete(TempOutputDir, True);

  FProgressView.SetStaticMode;
  UpdateRunState;

  // Reload the new/updated .xrfx
  if TFile.Exists(XRFXPath) then
  begin
    ShellList.FullRefresh;
    ProcessFile(XRFXPath);
  end;
end;

procedure TfrmXRFViewMain.HandleError(const ErrorMsg: string);
begin
  FRunTimer.Enabled := False;
  FProgressView.SetStaticMode;
  UpdateRunState;
  spStatus.Caption := 'Error: ' + ErrorMsg;
end;

procedure TfrmXRFViewMain.HandleRawLine(const Line: string);
begin
  FProgressView.AppendLog(Line);
end;

procedure TfrmXRFViewMain.UpdateRunState;
var
  Running: Boolean;
begin
  Running := FRunner.State = rsRunning;
  btnNewRun.Enabled := not Running;
  btnEditRun.Enabled := not Running;
  btnStop.Visible := Running;
end;

procedure TfrmXRFViewMain.StartRun(const ConfigPath: string);
begin
  PageControl1.ActivePage := tabProgress;
  FProgressView.SetLiveMode;
  FRunStartTime := Now;

  try
    FRunner.Start(ConfigPath);
    FRunTimer.Enabled := True;
    UpdateRunState;
    spStatus.Caption := 'Starting optimization...';
  except
    on E: Exception do
    begin
      FProgressView.SetStaticMode;
      UpdateRunState;
      spStatus.Caption := 'Error: ' + E.Message;
    end;
  end;
end;

procedure TfrmXRFViewMain.btnNewRunClick(Sender: TObject);
var
  Dlg: TfrmRunConfig;
  Config: TUniversalConfig;
  ConfigPath, TempOutputDir: string;
begin
  Dlg := TfrmRunConfig.Create(Self);
  try
    Dlg.SetDefaults;
    if Dlg.ShowModal = mrOk then
    begin
      Config := Dlg.BuildConfig;

      // Set output_dir to a temp subfolder
      TempOutputDir := TPath.Combine(ShellList.Path, TEMP_OUTPUT_DIR);
      Config.OutputDir := TempOutputDir;

      // Write config JSON with timestamp name in current folder
      ConfigPath := TPath.Combine(ShellList.Path,
        'xrfview_' + FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '.json');
      TUniversalIO.SaveConfig(Config, ConfigPath);

      StartRun(ConfigPath);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmXRFViewMain.btnEditRunClick(Sender: TObject);
var
  SelectedFile, ConfigJsonPath, TempDir: string;
  Config: TUniversalConfig;
  Dlg: TfrmRunConfig;
  ConfigPath, TempOutputDir: string;
begin
  if not FLoader.IsLoaded then
  begin
    spStatus.Caption := 'Select an .xrfx file first';
    Exit;
  end;

  SelectedFile := FLoader.GetResult(0).FileName;
  TempDir := FLoader.GetResult(0).TempDir;
  ConfigJsonPath := TPath.Combine(TempDir, 'config.json');

  if not TFile.Exists(ConfigJsonPath) then
  begin
    spStatus.Caption := 'No config.json found in this .xrfx package';
    Exit;
  end;

  Config := TUniversalIO.LoadConfig(ConfigJsonPath);

  Dlg := TfrmRunConfig.Create(Self);
  try
    Dlg.LoadFromConfig(Config);
    if Dlg.ShowModal = mrOk then
    begin
      Config := Dlg.BuildConfig;

      // Set output_dir to a temp subfolder
      TempOutputDir := TPath.Combine(ExtractFilePath(SelectedFile), TEMP_OUTPUT_DIR);
      Config.OutputDir := TempOutputDir;

      // Write config JSON with same basename so .xrfx overwrites
      ConfigPath := ChangeFileExt(SelectedFile, '.json');
      TUniversalIO.SaveConfig(Config, ConfigPath);

      StartRun(ConfigPath);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmXRFViewMain.btnStopClick(Sender: TObject);
begin
  FRunner.Cancel;
  FRunTimer.Enabled := False;
  FProgressView.SetStaticMode;
  UpdateRunState;
  spStatus.Caption := 'Run cancelled';
end;
```

- [ ] **Step 7: Build to verify**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeds.

- [ ] **Step 8: Commit**

```bash
git add XRFView/Forms/frm_XRFViewMain.pas XRFView/Forms/frm_XRFViewMain.dfm
git commit -m "+ Integrate runner into main form: toolbar buttons, live monitoring, auto-reload"
```

---

## Chunk 5: End-to-End Testing and Polish

### Task 9: Manual integration test

- [ ] **Step 1: Build both xrccmd and XRFView**

```bash
# Build xrccmd first
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1

# Build XRFView
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

- [ ] **Step 2: Test New Run workflow**

1. Launch XRFView.exe
2. Navigate to `UniversalMirror/` folder in shell browser
3. Click "New Run" → config dialog opens with defaults
4. Reduce population to 50 and iterations to 10 (for quick test)
5. Click "Run"
6. Verify: Progress tab shows live chart updating, memo shows stdout lines
7. Verify: Status bar shows iteration count and FoM
8. Verify: On completion, shell list refreshes, new .xrfx appears, all tabs load

- [ ] **Step 3: Test Edit Run workflow**

1. Select the .xrfx from Step 2
2. Click "Edit Run" → config dialog opens populated from the run's config
3. Change population to 100
4. Click "Run"
5. Verify: Original .xrfx is overwritten with new results
6. Verify: All tabs reload with updated data

- [ ] **Step 4: Test cancellation**

1. Start a New Run with population=1000, iterations=100
2. While running, click "Stop"
3. Verify: Run stops, status shows "Run cancelled", no .xrfx produced
4. Verify: New Run button re-enables

- [ ] **Step 5: Test Save Config**

1. Click "New Run", configure parameters
2. Click "Save Config..." instead of Run
3. Verify: JSON file saved, can be opened by `xrccmd -u` from command line

- [ ] **Step 6: Fix any issues found during testing**

Address any bugs discovered. Common issues to watch for:
- Pipe buffer overflow on fast iterations — ensure ReadPipeData drains fully
- DFM component name mismatches — ensure .pas and .dfm fields match
- Missing search paths for transitive dependencies (e.g., `cmd_unit_types` needed by `unit_universal_types`)

- [ ] **Step 7: Final commit**

```bash
git add -A
git commit -m "* Fix integration issues from XRFView project manager testing"
```

---

### Task 10: Load progress.log into memo for static mode

Currently the Progress tab loads only the chart from `TProgressEntry` data. Add loading of the raw progress.log text into the memo when viewing a completed .xrfx.

**Files:**
- Modify: `XRFView/Forms/frm_XRFViewMain.pas`

- [ ] **Step 1: Update ProcessFile to load progress log text**

In `ProcessFile`, after loading progress entries, also load the raw log text:

```pascal
// After: FProgressView.LoadProgress(FLoader.GetResult(0).Progress);
var ProgressLogPath := TPath.Combine(FLoader.GetResult(0).TempDir, 'progress.log');
if TFile.Exists(ProgressLogPath) then
  FProgressView.LoadProgressLog(TFile.ReadAllText(ProgressLogPath))
else
  FProgressView.LoadProgressLog('');
```

- [ ] **Step 2: Build and verify**

Expected: When clicking an .xrfx file, the Progress tab shows both the chart and the raw log text in the memo.

- [ ] **Step 3: Commit**

```bash
git add XRFView/Forms/frm_XRFViewMain.pas
git commit -m "+ Load progress.log text into Progress tab memo for completed runs"
```
