unit frm_XRFMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.CheckLst,
  VclTee.TeeGDIPlus, VclTee.TeEngine, VclTee.Series, VclTee.Chart,
  unit_universal_types, unit_universal_optimizer, unit_xrf_thread,
  VCLTee.TeeProcs;

type
  TfrmXRFMain = class(TForm)
    pnlSidebar: TPanel;
    sbConfig: TScrollBox;
    pnlButtons: TPanel;
    splMain: TSplitter;
    pnlCharts: TPanel;
    // Targets
    grpTargets: TGroupBox;
    clbTargets: TCheckListBox;
    sgWeights: TStringGrid;
    // Element Pool
    grpElements: TGroupBox;
    clbElements: TCheckListBox;
    // Structure
    grpStructure: TGroupBox;
    lblDMin: TLabel;
    lblDMax: TLabel;
    lblGammaMin: TLabel;
    lblGammaMax: TLabel;
    lblNMin: TLabel;
    lblNMax: TLabel;
    lblSigma: TLabel;
    edDMin: TEdit;
    edDMax: TEdit;
    edGammaMin: TEdit;
    edGammaMax: TEdit;
    edNMin: TEdit;
    edNMax: TEdit;
    edSigma: TEdit;
    cbPureElements: TCheckBox;
    // Fitness
    grpFitness: TGroupBox;
    lblWR: TLabel;
    lblWFWHM: TLabel;
    lblRMinThreshold: TLabel;
    lblThetaMin: TLabel;
    lblDeltaTheta: TLabel;
    lblPolarization: TLabel;
    edWR: TEdit;
    edWFWHM: TEdit;
    edRMinThreshold: TEdit;
    edThetaMin: TEdit;
    edDeltaTheta: TEdit;
    cmbPolarization: TComboBox;
    // Optimizer
    grpOptimizer: TGroupBox;
    lblPopulation: TLabel;
    lblIterations: TLabel;
    lblTolerance: TLabel;
    lblStagnationLimit: TLabel;
    lblW1: TLabel;
    lblW2: TLabel;
    lblJammingMax: TLabel;
    lblCheckpointEvery: TLabel;
    edPopulation: TEdit;
    edIterations: TEdit;
    edTolerance: TEdit;
    edStagnationLimit: TEdit;
    edW1: TEdit;
    edW2: TEdit;
    edJammingMax: TEdit;
    edCheckpointEvery: TEdit;
    // Substrate
    grpSubstrate: TGroupBox;
    lblSubstrate: TLabel;
    edSubstrate: TEdit;
    // Paths
    grpPaths: TGroupBox;
    lblHenkePath: TLabel;
    lblOutputDir: TLabel;
    edHenkePath: TEdit;
    edOutputDir: TEdit;
    btnBrowseHenke: TButton;
    btnBrowseOutput: TButton;
    lblTemplatePath: TLabel;
    edTemplatePath: TEdit;
    btnBrowseTemplate: TButton;
    lblXrccmdPath: TLabel;
    edXrccmdPath: TEdit;
    btnBrowseXrccmd: TButton;
    // Results (hidden by default)
    grpResults: TGroupBox;
    sgResults: TStringGrid;
    btnSaveStructure: TButton;
    btnSaveCurves: TButton;
    btnExportXRC: TButton;
    // Control buttons
    btnStart: TButton;
    btnStop: TButton;
    btnRunXrccmd: TButton;
    btnLoadConfig: TButton;
    btnSaveConfig: TButton;
    btnLoadResults: TButton;
    lblProgress: TLabel;
    // Dialogs
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    dlgSaveStructure: TSaveDialog;
    dlgOpenXrccmd: TOpenDialog;
    // Timer
    tmrProgress: TTimer;
    // Charts
    chartConvergence: TChart;
    serFoM: TLineSeries;
    splCharts: TSplitter;
    pnlBottomCharts: TPanel;
    chartRPeak: TChart;
    serRPeak: TBarSeries;
    splBottom: TSplitter;
    chartCurves: TChart;
    procedure btnLoadConfigClick(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
    procedure btnBrowseHenkeClick(Sender: TObject);
    procedure btnBrowseOutputClick(Sender: TObject);
    procedure btnBrowseTemplateClick(Sender: TObject);
    procedure btnBrowseXrccmdClick(Sender: TObject);
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnRunXrccmdClick(Sender: TObject);
    procedure btnLoadResultsClick(Sender: TObject);
    procedure btnSaveStructureClick(Sender: TObject);
    procedure btnSaveCurvesClick(Sender: TObject);
    procedure btnExportXRCClick(Sender: TObject);
    procedure tmrProgressTimer(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FThread: TOptimizationThread;
    FLastIterationData: TIterationData;
    FLastCurves: TArray<TCurveData>;
    FXrccmdProcess: THandle;
    FLogLineCount: Integer;
    FXrccmdOutputDir: string;
    FXrccmdTargetNames: TArray<string>;
    procedure HandleIteration(const Data: TIterationData);
    procedure HandleCompletion(const Data: TIterationData;
      const Curves: TArray<TCurveData>);
    procedure HandleError(const ErrorMsg: string);
    procedure SetRunningState(Running: Boolean);
    procedure ShowResultsSummary(const Data: TIterationData);
    procedure LoadConfigToUI(const Config: TUniversalConfig);
    function CollectConfigFromUI: TUniversalConfig;
    function FindXrccmdPath: string;
    procedure LoadResultsFromDir(const Dir: string);
    procedure XrccmdFinished;
  public
  end;

var
  frmXRFMain: TfrmXRFMain;

implementation

uses
  System.IniFiles, System.IOUtils, System.JSON, Vcl.FileCtrl,
  unit_universal_io, cmd_unit_types, unit_materials_mix;

{$R *.dfm}

const
  TARGET_COUNT = 10;
  KAlphaData: array[0..TARGET_COUNT-1] of record
    Element: string;
    Lambda: Double;
  end = (
    (Element: 'B';  Lambda: 67.6),
    (Element: 'C';  Lambda: 44.7),
    (Element: 'N';  Lambda: 31.6),
    (Element: 'O';  Lambda: 23.6),
    (Element: 'F';  Lambda: 18.3),
    (Element: 'Ne'; Lambda: 14.6),
    (Element: 'Na'; Lambda: 11.9),
    (Element: 'Mg'; Lambda: 9.89),
    (Element: 'Al'; Lambda: 8.338),
    (Element: 'Si'; Lambda: 7.126)
  );

function ValidateConfig(const Config: TUniversalConfig; out Error: string): Boolean;
begin
  Result := False;
  if Length(Config.Targets) = 0 then begin Error := 'No target elements selected.'; Exit; end;
  if Length(Config.ElementPool) = 0 then begin Error := 'No elements in pool.'; Exit; end;
  if Config.OutputDir = '' then begin Error := 'Output directory not set.'; Exit; end;
  Result := True;
end;

function GetSettingsPath: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

{ TfrmXRFMain }

procedure TfrmXRFMain.FormCreate(Sender: TObject);
var
  Ini: TIniFile;
begin
  FXrccmdProcess := 0;
  Ini := TIniFile.Create(GetSettingsPath);
  try
    edHenkePath.Text := Ini.ReadString('Paths', 'HenkePath', '');
    edOutputDir.Text := Ini.ReadString('Paths', 'OutputDir', '');
    edTemplatePath.Text := Ini.ReadString('Paths', 'TemplatePath', '');
    edXrccmdPath.Text := Ini.ReadString('Paths', 'XrccmdPath', '');
  finally
    Ini.Free;
  end;

  if edXrccmdPath.Text = '' then
    edXrccmdPath.Text := FindXrccmdPath;
end;

procedure TfrmXRFMain.FormDestroy(Sender: TObject);
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetSettingsPath);
  try
    Ini.WriteString('Paths', 'HenkePath', edHenkePath.Text);
    Ini.WriteString('Paths', 'OutputDir', edOutputDir.Text);
    Ini.WriteString('Paths', 'TemplatePath', edTemplatePath.Text);
    Ini.WriteString('Paths', 'XrccmdPath', edXrccmdPath.Text);
  finally
    Ini.Free;
  end;
end;

function TfrmXRFMain.FindXrccmdPath: string;
var
  Dir, Candidate: string;
begin
  Result := '';
  Dir := ExtractFilePath(Application.ExeName);

  // Same directory as XRFCalc.exe
  Candidate := Dir + 'xrccmd.exe';
  if FileExists(Candidate) then
  begin
    Result := Candidate;
    Exit;
  end;

  // Sibling XRC_CMD output
  Candidate := ExpandFileName(Dir + '..\XRC_CMD\Out\BIN\xrccmd.exe');
  if FileExists(Candidate) then
    Result := Candidate;
end;

procedure TfrmXRFMain.LoadConfigToUI(const Config: TUniversalConfig);
var
  i, j: Integer;
begin
  // Targets: uncheck all, then check matching ones
  for i := 0 to clbTargets.Count - 1 do
    clbTargets.Checked[i] := False;

  // Initialize weights grid header row
  sgWeights.Cells[0, 0] := 'Target';
  sgWeights.Cells[1, 0] := 'Weight';
  for i := 0 to clbTargets.Count - 1 do
  begin
    sgWeights.Cells[0, i + 1] := clbTargets.Items[i];
    sgWeights.Cells[1, i + 1] := '1.0';
  end;

  for i := 0 to High(Config.Targets) do
  begin
    for j := 0 to clbTargets.Count - 1 do
    begin
      if SameText(clbTargets.Items[j], Config.Targets[i].Name) then
      begin
        clbTargets.Checked[j] := True;
        sgWeights.Cells[1, j + 1] := FormatFloat('0.###', Config.Targets[i].Weight);
        Break;
      end;
    end;
  end;

  // Element pool: uncheck all, then check matching ones
  for i := 0 to clbElements.Count - 1 do
    clbElements.Checked[i] := False;

  for i := 0 to High(Config.ElementPool) do
  begin
    for j := 0 to clbElements.Count - 1 do
    begin
      if SameText(clbElements.Items[j], Config.ElementPool[i]) then
      begin
        clbElements.Checked[j] := True;
        Break;
      end;
    end;
  end;

  // Structure
  edDMin.Text := FormatFloat('0.###', Config.Structure.dRange.Min);
  edDMax.Text := FormatFloat('0.###', Config.Structure.dRange.Max);
  edGammaMin.Text := FormatFloat('0.###', Config.Structure.GammaRange.Min);
  edGammaMax.Text := FormatFloat('0.###', Config.Structure.GammaRange.Max);
  edNMin.Text := FormatFloat('0', Config.Structure.NRange.Min);
  edNMax.Text := FormatFloat('0', Config.Structure.NRange.Max);
  edSigma.Text := FormatFloat('0.###', Config.Structure.SigmaFixed);
  cbPureElements.Checked := Config.Structure.PureElements;

  // Fitness
  edWR.Text := FormatFloat('0.###', Config.Fitness.wR);
  edWFWHM.Text := FormatFloat('0.###', Config.Fitness.wFWHM);
  edRMinThreshold.Text := FormatFloat('0.###', Config.Fitness.RMinThreshold);
  edThetaMin.Text := FormatFloat('0.###', Config.Fitness.ThetaMin);
  edDeltaTheta.Text := FormatFloat('0.###', Config.Fitness.DeltaTheta);

  if Config.Fitness.Polarization = cmS then
    cmbPolarization.ItemIndex := 0
  else
    cmbPolarization.ItemIndex := 1;

  // Optimizer
  edPopulation.Text := IntToStr(Config.Optimizer.Population);
  edIterations.Text := IntToStr(Config.Optimizer.Iterations);
  edTolerance.Text := FormatFloat('0.######', Config.Optimizer.Tolerance);
  edStagnationLimit.Text := IntToStr(Config.Optimizer.StagnationLimit);
  edW1.Text := FormatFloat('0.###', Config.Optimizer.w1);
  edW2.Text := FormatFloat('0.###', Config.Optimizer.w2);
  edJammingMax.Text := IntToStr(Config.Optimizer.JammingMax);
  edCheckpointEvery.Text := IntToStr(Config.Optimizer.CheckpointEvery);

  // Substrate
  edSubstrate.Text := Config.Substrate;

  // Paths
  edHenkePath.Text := Config.HenkePath;
  edOutputDir.Text := Config.OutputDir;
  edTemplatePath.Text := Config.TemplatePath;
end;

function TfrmXRFMain.CollectConfigFromUI: TUniversalConfig;
var
  i, TargetIdx: Integer;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  // Targets: collect checked items with lambda and weight
  TargetIdx := 0;
  SetLength(Result.Targets, clbTargets.Count);
  for i := 0 to clbTargets.Count - 1 do
  begin
    if clbTargets.Checked[i] then
    begin
      Result.Targets[TargetIdx].Name := clbTargets.Items[i];
      // Find matching lambda from KAlphaData
      if i < TARGET_COUNT then
        Result.Targets[TargetIdx].Lambda := KAlphaData[i].Lambda
      else
        Result.Targets[TargetIdx].Lambda := 0;
      // Read weight from grid
      Result.Targets[TargetIdx].Weight := StrToFloatDef(sgWeights.Cells[1, i + 1], 1.0, FS);
      Inc(TargetIdx);
    end;
  end;
  SetLength(Result.Targets, TargetIdx);

  // Element pool: collect checked items
  TargetIdx := 0;
  SetLength(Result.ElementPool, clbElements.Count);
  for i := 0 to clbElements.Count - 1 do
  begin
    if clbElements.Checked[i] then
    begin
      Result.ElementPool[TargetIdx] := clbElements.Items[i];
      Inc(TargetIdx);
    end;
  end;
  SetLength(Result.ElementPool, TargetIdx);

  // Structure
  Result.Structure.StructureType := 'bilayer';
  Result.Structure.LayersPerPeriod := 2;
  Result.Structure.PureElements := cbPureElements.Checked;
  Result.Structure.dRange.Min := StrToFloatDef(edDMin.Text, 0, FS);
  Result.Structure.dRange.Max := StrToFloatDef(edDMax.Text, 0, FS);
  Result.Structure.GammaRange.Min := StrToFloatDef(edGammaMin.Text, 0, FS);
  Result.Structure.GammaRange.Max := StrToFloatDef(edGammaMax.Text, 0, FS);
  Result.Structure.NRange.Min := StrToFloatDef(edNMin.Text, 0, FS);
  Result.Structure.NRange.Max := StrToFloatDef(edNMax.Text, 0, FS);
  Result.Structure.SigmaFixed := StrToFloatDef(edSigma.Text, 0, FS);
  Result.Structure.DensityFactorRange.Min := 1.0;
  Result.Structure.DensityFactorRange.Max := 1.0;

  // Fitness
  Result.Fitness.wR := StrToFloatDef(edWR.Text, 1.0, FS);
  Result.Fitness.wFWHM := StrToFloatDef(edWFWHM.Text, 0, FS);
  Result.Fitness.RMinThreshold := StrToFloatDef(edRMinThreshold.Text, 0, FS);
  Result.Fitness.ThetaMin := StrToFloatDef(edThetaMin.Text, 0, FS);
  Result.Fitness.DeltaTheta := StrToFloatDef(edDeltaTheta.Text, 0, FS);

  if cmbPolarization.ItemIndex = 0 then
    Result.Fitness.Polarization := cmS
  else
    Result.Fitness.Polarization := cmSP;

  // Optimizer
  Result.Optimizer.Population := StrToIntDef(edPopulation.Text, 50);
  Result.Optimizer.Iterations := StrToIntDef(edIterations.Text, 500);
  Result.Optimizer.Tolerance := StrToFloatDef(edTolerance.Text, 1E-6, FS);
  Result.Optimizer.StagnationLimit := StrToIntDef(edStagnationLimit.Text, 50);
  Result.Optimizer.w1 := StrToFloatDef(edW1.Text, 0.9, FS);
  Result.Optimizer.w2 := StrToFloatDef(edW2.Text, 0.4, FS);
  Result.Optimizer.JammingMax := StrToIntDef(edJammingMax.Text, 3);
  Result.Optimizer.CheckpointEvery := StrToIntDef(edCheckpointEvery.Text, 50);

  // Substrate
  Result.Substrate := edSubstrate.Text;

  // Paths
  Result.HenkePath := edHenkePath.Text;
  Result.OutputDir := edOutputDir.Text;
  Result.TemplatePath := edTemplatePath.Text;

  // ResumeFrom not set from UI
  Result.ResumeFrom := '';
end;

procedure TfrmXRFMain.btnLoadConfigClick(Sender: TObject);
var
  Config: TUniversalConfig;
  ConfigDir: string;
begin
  if dlgOpen.Execute then
  begin
    try
      Config := TUniversalIO.LoadConfig(dlgOpen.FileName);

      // Resolve relative paths against the config file's directory
      ConfigDir := ExtractFilePath(ExpandFileName(dlgOpen.FileName));
      if (Config.OutputDir <> '') and not TPath.IsPathRooted(Config.OutputDir) then
        Config.OutputDir := ExpandFileName(ConfigDir + Config.OutputDir);
      if (Config.HenkePath <> '') and not TPath.IsPathRooted(Config.HenkePath) then
        Config.HenkePath := ExpandFileName(ConfigDir + Config.HenkePath);
      if (Config.TemplatePath <> '') and not TPath.IsPathRooted(Config.TemplatePath) then
        Config.TemplatePath := ExpandFileName(ConfigDir + Config.TemplatePath);

      LoadConfigToUI(Config);
    except
      on E: Exception do
        MessageDlg('Error loading config: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmXRFMain.btnSaveConfigClick(Sender: TObject);
var
  Config: TUniversalConfig;
begin
  if dlgSave.Execute then
  begin
    try
      Config := CollectConfigFromUI;
      TUniversalIO.SaveConfig(Config, dlgSave.FileName);
    except
      on E: Exception do
        MessageDlg('Error saving config: ' + E.Message, mtError, [mbOK], 0);
    end;
  end;
end;

procedure TfrmXRFMain.btnBrowseHenkeClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edHenkePath.Text;
  if SelectDirectory('Select Henke data directory', '', Dir) then
    edHenkePath.Text := Dir;
end;

procedure TfrmXRFMain.btnBrowseOutputClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edOutputDir.Text;
  if SelectDirectory('Select output directory', '', Dir) then
    edOutputDir.Text := Dir;
end;

procedure TfrmXRFMain.btnBrowseTemplateClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dlg.Title := 'Select template file';
    if edTemplatePath.Text <> '' then
      Dlg.InitialDir := ExtractFilePath(edTemplatePath.Text);
    if Dlg.Execute then
      edTemplatePath.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmXRFMain.btnBrowseXrccmdClick(Sender: TObject);
begin
  if edXrccmdPath.Text <> '' then
    dlgOpenXrccmd.InitialDir := ExtractFilePath(edXrccmdPath.Text);
  if dlgOpenXrccmd.Execute then
    edXrccmdPath.Text := dlgOpenXrccmd.FileName;
end;

procedure TfrmXRFMain.SetRunningState(Running: Boolean);
begin
  sbConfig.Enabled := not Running;
  btnStart.Enabled := not Running;
  btnRunXrccmd.Enabled := not Running;
  btnStop.Enabled := Running;
  btnLoadConfig.Enabled := not Running;
  btnSaveConfig.Enabled := not Running;
  btnLoadResults.Enabled := not Running;
  if not Running then
    lblProgress.Caption := 'Ready';
end;

procedure TfrmXRFMain.btnStartClick(Sender: TObject);
var
  Config: TUniversalConfig;
  Error: string;
  CheckpointPath: string;
begin
  Config := CollectConfigFromUI;
  if not ValidateConfig(Config, Error) then
  begin
    MessageDlg(Error, mtError, [mbOK], 0);
    Exit;
  end;

  CheckpointPath := IncludeTrailingPathDelimiter(Config.OutputDir) + 'checkpoint.json';
  if FileExists(CheckpointPath) then
  begin
    if MessageDlg('Checkpoint found. Resume?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
      Config.ResumeFrom := CheckpointPath;
  end;

  SetRunningState(True);
  grpResults.Visible := False;

  serFoM.Clear;
  serRPeak.Clear;
  chartCurves.RemoveAllSeries;

  FThread := TOptimizationThread.Create(Config);
  FThread.OnIteration := HandleIteration;
  FThread.OnCompleted := HandleCompletion;
  FThread.OnError := HandleError;
  FThread.Start;
end;

procedure TfrmXRFMain.btnStopClick(Sender: TObject);
begin
  if Assigned(FThread) then
    FThread.CancelOptimization;

  // Stop xrccmd process if running
  if FXrccmdProcess <> 0 then
  begin
    TerminateProcess(FXrccmdProcess, 1);
    CloseHandle(FXrccmdProcess);
    FXrccmdProcess := 0;
    tmrProgress.Enabled := False;
    SetRunningState(False);
    lblProgress.Caption := 'xrccmd stopped';
  end;
end;

procedure TfrmXRFMain.btnRunXrccmdClick(Sender: TObject);
var
  Config: TUniversalConfig;
  Error: string;
  XrccmdExe, ConfigPath, CmdLine, LogPath: string;
  SI: TStartupInfo;
  PI: TProcessInformation;
  i: Integer;
begin
  XrccmdExe := edXrccmdPath.Text;
  if (XrccmdExe = '') or not FileExists(XrccmdExe) then
  begin
    MessageDlg('xrccmd.exe not found. Set the path in Paths group.', mtError, [mbOK], 0);
    Exit;
  end;

  Config := CollectConfigFromUI;
  if not ValidateConfig(Config, Error) then
  begin
    MessageDlg(Error, mtError, [mbOK], 0);
    Exit;
  end;

  // Ensure output dir is absolute
  Config.OutputDir := ExpandFileName(Config.OutputDir);
  if not System.SysUtils.ForceDirectories(Config.OutputDir) then
  begin
    MessageDlg('Cannot create output directory: ' + Config.OutputDir, mtError, [mbOK], 0);
    Exit;
  end;

  // Save config to output dir
  ConfigPath := IncludeTrailingPathDelimiter(Config.OutputDir) + '_xrccmd_config.json';
  TUniversalIO.SaveConfig(Config, ConfigPath);

  // Delete old progress.log so we start tailing fresh
  LogPath := IncludeTrailingPathDelimiter(Config.OutputDir) + 'progress.log';
  if FileExists(LogPath) then
    DeleteFile(LogPath);

  // Remember output dir and target names for log parsing
  FXrccmdOutputDir := Config.OutputDir;
  SetLength(FXrccmdTargetNames, Length(Config.Targets));
  for i := 0 to High(Config.Targets) do
    FXrccmdTargetNames[i] := Config.Targets[i].Name;

  // Launch xrccmd
  CmdLine := '"' + XrccmdExe + '" -u "' + ConfigPath + '"';

  FillChar(SI, SizeOf(SI), 0);
  SI.cb := SizeOf(SI);
  SI.dwFlags := STARTF_USESHOWWINDOW;
  SI.wShowWindow := SW_MINIMIZE;

  FillChar(PI, SizeOf(PI), 0);

  if not CreateProcess(nil, PChar(CmdLine), nil, nil, False,
    CREATE_NEW_CONSOLE, nil, PChar(Config.OutputDir), SI, PI) then
  begin
    MessageDlg('Failed to launch xrccmd: ' + SysErrorMessage(GetLastError),
      mtError, [mbOK], 0);
    Exit;
  end;

  CloseHandle(PI.hThread);
  FXrccmdProcess := PI.hProcess;

  // Prepare UI
  SetRunningState(True);
  grpResults.Visible := False;
  serFoM.Clear;
  serRPeak.Clear;
  chartCurves.RemoveAllSeries;
  FLogLineCount := 0;
  lblProgress.Caption := 'xrccmd running...';

  tmrProgress.Enabled := True;
end;

procedure TfrmXRFMain.tmrProgressTimer(Sender: TObject);
var
  LogPath, Line: string;
  SL: TStringList;
  i, j: Integer;
  Parts: TArray<string>;
  Iter: Integer;
  FoM: Double;
  RPeakValues: TArray<Double>;
  ExitCode: DWORD;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  // Tail progress.log for new lines
  LogPath := IncludeTrailingPathDelimiter(FXrccmdOutputDir) + 'progress.log';
  if FileExists(LogPath) then
  begin
    SL := TStringList.Create;
    try
      try
        SL.LoadFromFile(LogPath);
      except
        // File may be locked by xrccmd writing — skip this tick
        Exit;
      end;

      for i := FLogLineCount to SL.Count - 1 do
      begin
        Line := Trim(SL[i]);
        if (Line = '') or (i = 0) then  // skip header
          Continue;

        // Parse: "  Iter    FoM  R_1  R_2 ... Div  MM:SS"
        // Split by whitespace
        Parts := Line.Split([' '], TStringSplitOptions.ExcludeEmpty);
        if Length(Parts) < 3 then
          Continue;

        Iter := StrToIntDef(Parts[0], -1);
        if Iter < 0 then
          Continue;
        FoM := StrToFloatDef(Parts[1], 0, FS);

        // R_peak values: Parts[2..2+NTargets-1]
        SetLength(RPeakValues, Length(FXrccmdTargetNames));
        for j := 0 to High(FXrccmdTargetNames) do
        begin
          if j + 2 < Length(Parts) then
            RPeakValues[j] := StrToFloatDef(Parts[j + 2], 0, FS)
          else
            RPeakValues[j] := 0;
        end;

        // Update FoM chart
        serFoM.AddXY(Iter, FoM);

        // Update R_peak bar chart
        serRPeak.Clear;
        for j := 0 to High(FXrccmdTargetNames) do
          serRPeak.Add(RPeakValues[j], FXrccmdTargetNames[j]);

        // Update progress label — use last two parts for time
        if Length(Parts) >= 2 then
          lblProgress.Caption := Format('xrccmd: Iter %d  FoM: %.4f  [%s]',
            [Iter, FoM, Parts[High(Parts)]]);
      end;

      FLogLineCount := SL.Count;
    finally
      SL.Free;
    end;
  end;

  // Check if process has exited
  if FXrccmdProcess <> 0 then
  begin
    if GetExitCodeProcess(FXrccmdProcess, ExitCode) then
    begin
      if ExitCode <> STILL_ACTIVE then
      begin
        CloseHandle(FXrccmdProcess);
        FXrccmdProcess := 0;
        tmrProgress.Enabled := False;
        XrccmdFinished;
      end;
    end;
  end;
end;

procedure TfrmXRFMain.XrccmdFinished;
begin
  SetRunningState(False);
  lblProgress.Caption := 'xrccmd complete — loading results...';
  Application.ProcessMessages;

  LoadResultsFromDir(FXrccmdOutputDir);
end;

procedure TfrmXRFMain.btnLoadResultsClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edOutputDir.Text;
  if SelectDirectory('Select results directory', '', Dir) then
    LoadResultsFromDir(Dir);
end;

procedure TfrmXRFMain.LoadResultsFromDir(const Dir: string);
var
  StructPath, CurvesDir, Line: string;
  JSON: TJSONObject;
  JPerElem, JElem: TJSONObject;
  Pair: TJSONPair;
  SL: TStringList;
  i, j, Row: Integer;
  Series: TLineSeries;
  Parts: TArray<string>;
  FoM: Double;
  FS: TFormatSettings;
  CurveFiles: TArray<string>;
  ElemName: string;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  StructPath := IncludeTrailingPathDelimiter(Dir) + 'best_structure.json';
  if not FileExists(StructPath) then
  begin
    MessageDlg('best_structure.json not found in ' + Dir, mtError, [mbOK], 0);
    Exit;
  end;

  // Parse best_structure.json
  SL := TStringList.Create;
  try
    SL.LoadFromFile(StructPath);
    JSON := TJSONObject.ParseJSONValue(SL.Text) as TJSONObject;
  finally
    SL.Free;
  end;

  if JSON = nil then
  begin
    MessageDlg('Failed to parse best_structure.json', mtError, [mbOK], 0);
    Exit;
  end;

  try
    // Extract per_element results
    FoM := 0;
    if JSON.GetValue('optimizer_result') is TJSONObject then
    begin
      var JResult := JSON.GetValue('optimizer_result') as TJSONObject;
      if JResult.GetValue('FoM') <> nil then
        FoM := (JResult.GetValue('FoM') as TJSONNumber).AsDouble;

      if JResult.GetValue('per_element') is TJSONObject then
      begin
        JPerElem := JResult.GetValue('per_element') as TJSONObject;

        // Populate results grid
        grpResults.Visible := True;
        sgResults.RowCount := JPerElem.Count + 1;
        sgResults.Cells[0, 0] := 'Element';
        sgResults.Cells[1, 0] := 'R_peak';
        sgResults.Cells[2, 0] := 'FWHM';

        Row := 1;
        // Also build PerElement data for FLastIterationData
        SetLength(FLastIterationData.PerElement, JPerElem.Count);
        for i := 0 to JPerElem.Count - 1 do
        begin
          Pair := JPerElem.Pairs[i];
          ElemName := Pair.JsonString.Value;
          JElem := Pair.JsonValue as TJSONObject;

          sgResults.Cells[0, Row] := ElemName;
          if JElem.GetValue('R_peak') <> nil then
            sgResults.Cells[1, Row] := Format('%.4f',
              [(JElem.GetValue('R_peak') as TJSONNumber).AsDouble])
          else
            sgResults.Cells[1, Row] := '';
          if JElem.GetValue('FWHM') <> nil then
            sgResults.Cells[2, Row] := Format('%.3f',
              [(JElem.GetValue('FWHM') as TJSONNumber).AsDouble])
          else
            sgResults.Cells[2, Row] := '';

          FLastIterationData.PerElement[i].Element := ElemName;
          if JElem.GetValue('R_peak') <> nil then
            FLastIterationData.PerElement[i].RPeak :=
              (JElem.GetValue('R_peak') as TJSONNumber).AsDouble;
          if JElem.GetValue('FWHM') <> nil then
            FLastIterationData.PerElement[i].FWHM :=
              (JElem.GetValue('FWHM') as TJSONNumber).AsDouble;

          Inc(Row);
        end;

        FLastIterationData.FoM := FoM;

        // Update R_peak bar chart
        serRPeak.Clear;
        for i := 0 to High(FLastIterationData.PerElement) do
          serRPeak.Add(FLastIterationData.PerElement[i].RPeak,
            FLastIterationData.PerElement[i].Element);
      end;
    end;
  finally
    JSON.Free;
  end;

  // Load curves from best_curves/*.dat
  CurvesDir := IncludeTrailingPathDelimiter(Dir) + 'best_curves';
  chartCurves.RemoveAllSeries;
  SetLength(FLastCurves, 0);

  if TDirectory.Exists(CurvesDir) then
  begin
    CurveFiles := TDirectory.GetFiles(CurvesDir, '*.dat');
    SetLength(FLastCurves, Length(CurveFiles));

    for i := 0 to High(CurveFiles) do
    begin
      ElemName := TPath.GetFileNameWithoutExtension(CurveFiles[i]);
      FLastCurves[i].Element := ElemName;

      SL := TStringList.Create;
      try
        SL.LoadFromFile(CurveFiles[i]);

        SetLength(FLastCurves[i].Theta, 0);
        SetLength(FLastCurves[i].Refl, 0);

        Series := TLineSeries.Create(chartCurves);
        Series.Title := ElemName;
        Series.LinePen.Width := 2;
        chartCurves.AddSeries(Series);

        for j := 1 to SL.Count - 1 do  // skip header
        begin
          Line := Trim(SL[j]);
          if Line = '' then Continue;
          Parts := Line.Split([#9]);
          if Length(Parts) >= 2 then
          begin
            var Theta := StrToFloatDef(Parts[0], 0, FS);
            var Refl := StrToFloatDef(Parts[1], 0, FS);
            Series.AddXY(Theta, Refl);

            SetLength(FLastCurves[i].Theta, Length(FLastCurves[i].Theta) + 1);
            FLastCurves[i].Theta[High(FLastCurves[i].Theta)] := Theta;
            SetLength(FLastCurves[i].Refl, Length(FLastCurves[i].Refl) + 1);
            FLastCurves[i].Refl[High(FLastCurves[i].Refl)] := Refl;
          end;
        end;
      finally
        SL.Free;
      end;
    end;
  end;

  lblProgress.Caption := Format('Results loaded from %s  FoM: %.4f', [Dir, FoM]);
end;

procedure TfrmXRFMain.HandleIteration(const Data: TIterationData);
var
  i: Integer;
begin
  FLastIterationData := Data;

  serFoM.AddXY(Data.Iteration, Data.FoM);

  serRPeak.Clear;
  for i := 0 to High(Data.PerElement) do
    serRPeak.Add(Data.PerElement[i].RPeak, Data.PerElement[i].Element);

  lblProgress.Caption := Format('Iteration %d / %d  FoM: %.4f  [%d:%02d]',
    [Data.Iteration, Data.MaxIterations, Data.FoM,
     Trunc(Data.ElapsedSec) div 60, Trunc(Data.ElapsedSec) mod 60]);
end;

procedure TfrmXRFMain.HandleCompletion(const Data: TIterationData;
  const Curves: TArray<TCurveData>);
var
  i, j: Integer;
  Series: TLineSeries;
begin
  FLastIterationData := Data;
  FLastCurves := Curves;

  SetRunningState(False);
  FThread.WaitFor;
  FThread.Free;
  FThread := nil;

  chartCurves.RemoveAllSeries;
  for i := 0 to High(Curves) do
  begin
    Series := TLineSeries.Create(chartCurves);
    Series.Title := Curves[i].Element;
    Series.LinePen.Width := 2;
    chartCurves.AddSeries(Series);
    for j := 0 to High(Curves[i].Theta) do
      Series.AddXY(Curves[i].Theta[j], Curves[i].Refl[j]);
  end;

  ShowResultsSummary(Data);
  lblProgress.Caption := Format('Complete - FoM: %.4f  [%d:%02d]',
    [Data.FoM, Trunc(Data.ElapsedSec) div 60, Trunc(Data.ElapsedSec) mod 60]);
end;

procedure TfrmXRFMain.HandleError(const ErrorMsg: string);
begin
  SetRunningState(False);
  if Assigned(FThread) then
  begin
    FThread.Free;
    FThread := nil;
  end;
  MessageDlg('Optimization error: ' + ErrorMsg, mtError, [mbOK], 0);
end;

procedure TfrmXRFMain.ShowResultsSummary(const Data: TIterationData);
var
  i: Integer;
begin
  grpResults.Visible := True;

  sgResults.RowCount := Length(Data.PerElement) + 1;
  sgResults.Cells[0, 0] := 'Element';
  sgResults.Cells[1, 0] := 'R_peak';
  sgResults.Cells[2, 0] := 'FWHM';
  for i := 0 to High(Data.PerElement) do
  begin
    sgResults.Cells[0, i + 1] := Data.PerElement[i].Element;
    sgResults.Cells[1, i + 1] := Format('%.4f', [Data.PerElement[i].RPeak]);
    sgResults.Cells[2, i + 1] := Format('%.3f', [Data.PerElement[i].FWHM]);
  end;
end;

procedure TfrmXRFMain.btnSaveStructureClick(Sender: TObject);
var
  IO: TUniversalIO;
  Config: TUniversalConfig;
  Results: TTargetResults;
  i: Integer;
  Dir: string;
begin
  Config := CollectConfigFromUI;
  Dir := Config.OutputDir;
  if Dir = '' then
    Dir := ExtractFilePath(Application.ExeName);

  SetLength(Results, Length(FLastIterationData.PerElement));
  for i := 0 to High(Results) do
  begin
    Results[i].RPeak := FLastIterationData.PerElement[i].RPeak;
    Results[i].FWHM := FLastIterationData.PerElement[i].FWHM;
  end;

  IO := TUniversalIO.Create;
  try
    IO.SaveBestStructure(Config, FLastIterationData.BestGenome,
      FLastIterationData.FoM, Results, Dir);
  finally
    IO.Free;
  end;

  MessageDlg('Structure saved to ' + Dir, mtInformation, [mbOK], 0);
end;

procedure TfrmXRFMain.btnSaveCurvesClick(Sender: TObject);
var
  i, j: Integer;
  Dir, FileName: string;
  SL: TStringList;
begin
  Dir := edOutputDir.Text;
  if Dir = '' then
    Dir := ExtractFilePath(Application.ExeName);
  Dir := IncludeTrailingPathDelimiter(Dir) + 'best_curves';
  System.SysUtils.ForceDirectories(Dir);

  for i := 0 to High(FLastCurves) do
  begin
    FileName := IncludeTrailingPathDelimiter(Dir) + FLastCurves[i].Element + '.dat';
    SL := TStringList.Create;
    try
      SL.Add('Theta(deg)'#9'Reflectivity');
      for j := 0 to High(FLastCurves[i].Theta) do
        SL.Add(Format('%.4f'#9'%.6e', [FLastCurves[i].Theta[j], FLastCurves[i].Refl[j]]));
      SL.SaveToFile(FileName);
    finally
      SL.Free;
    end;
  end;

  MessageDlg(Format('Saved %d curve files to %s', [Length(FLastCurves), Dir]),
    mtInformation, [mbOK], 0);
end;

procedure TfrmXRFMain.btnExportXRCClick(Sender: TObject);
var
  IO: TUniversalIO;
  Mixer: TMaterialMixer;
  Config: TUniversalConfig;
  ElementNames: array of string;
  TargetLambdas: array of Single;
  Dir: string;
  i: Integer;
begin
  if not dlgSaveStructure.Execute then
    Exit;

  Config := CollectConfigFromUI;
  Dir := ExtractFilePath(dlgSaveStructure.FileName);

  SetLength(ElementNames, Length(Config.ElementPool));
  for i := 0 to High(Config.ElementPool) do
    ElementNames[i] := Config.ElementPool[i];

  SetLength(TargetLambdas, Length(Config.Targets));
  for i := 0 to High(Config.Targets) do
    TargetLambdas[i] := Config.Targets[i].Lambda;

  Mixer := TMaterialMixer.Create;
  IO := TUniversalIO.Create;
  try
    Mixer.Initialize(ElementNames, TargetLambdas, Config.Substrate, Config.HenkePath);
    IO.SaveXRCStructure(Config, FLastIterationData.BestGenome, Mixer, nil, Dir);
  finally
    IO.Free;
    Mixer.Free;
  end;

  MessageDlg('XRC structure exported to ' + Dir, mtInformation, [mbOK], 0);
end;

end.
