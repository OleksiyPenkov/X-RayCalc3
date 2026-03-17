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
    // Results (hidden by default)
    grpResults: TGroupBox;
    sgResults: TStringGrid;
    btnSaveStructure: TButton;
    btnSaveCurves: TButton;
    btnExportXRC: TButton;
    // Control buttons
    btnStart: TButton;
    btnStop: TButton;
    btnLoadConfig: TButton;
    btnSaveConfig: TButton;
    lblProgress: TLabel;
    // Dialogs
    dlgOpen: TOpenDialog;
    dlgSave: TSaveDialog;
    dlgSaveStructure: TSaveDialog;
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
    procedure btnStartClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnSaveStructureClick(Sender: TObject);
    procedure btnSaveCurvesClick(Sender: TObject);
    procedure btnExportXRCClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
  private
    FThread: TOptimizationThread;
    FLastIterationData: TIterationData;
    FLastCurves: TArray<TCurveData>;
    procedure HandleIteration(const Data: TIterationData);
    procedure HandleCompletion(const Data: TIterationData;
      const Curves: TArray<TCurveData>);
    procedure HandleError(const ErrorMsg: string);
    procedure SetRunningState(Running: Boolean);
    procedure ShowResultsSummary(const Data: TIterationData);
    procedure LoadConfigToUI(const Config: TUniversalConfig);
    function CollectConfigFromUI: TUniversalConfig;
  public
  end;

var
  frmXRFMain: TfrmXRFMain;

implementation

uses
  System.IniFiles, Vcl.FileCtrl,
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
  Ini := TIniFile.Create(GetSettingsPath);
  try
    edHenkePath.Text := Ini.ReadString('Paths', 'HenkePath', '');
    edOutputDir.Text := Ini.ReadString('Paths', 'OutputDir', '');
    edTemplatePath.Text := Ini.ReadString('Paths', 'TemplatePath', '');
  finally
    Ini.Free;
  end;
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
  finally
    Ini.Free;
  end;
end;

procedure TfrmXRFMain.LoadConfigToUI(const Config: TUniversalConfig);
var
  i, j: Integer;
  Found: Boolean;
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
begin
  if dlgOpen.Execute then
  begin
    try
      Config := TUniversalIO.LoadConfig(dlgOpen.FileName);
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

procedure TfrmXRFMain.SetRunningState(Running: Boolean);
begin
  sbConfig.Enabled := not Running;
  btnStart.Enabled := not Running;
  btnStop.Enabled := Running;
  btnLoadConfig.Enabled := not Running;
  btnSaveConfig.Enabled := not Running;
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

  lblProgress.Caption := Format('Iteration %d / %d  FoM: %.4f',
    [Data.Iteration, Data.MaxIterations, Data.FoM]);
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
  lblProgress.Caption := Format('Complete - FoM: %.4f', [Data.FoM]);
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
    IO.SaveXRCStructure(Config, FLastIterationData.BestGenome, Mixer, Dir);
  finally
    IO.Free;
    Mixer.Free;
  end;

  MessageDlg('XRC structure exported to ' + Dir, mtInformation, [mbOK], 0);
end;

end.
