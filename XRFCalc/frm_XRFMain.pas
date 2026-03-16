unit frm_XRFMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Grids,
  Vcl.CheckLst,
  VclTee.TeeGDIPlus, VclTee.TeEngine, VclTee.Series, VclTee.Chart,
  unit_universal_types;

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
    lblDensityMin: TLabel;
    lblDensityMax: TLabel;
    edDMin: TEdit;
    edDMax: TEdit;
    edGammaMin: TEdit;
    edGammaMax: TEdit;
    edNMin: TEdit;
    edNMax: TEdit;
    edSigma: TEdit;
    edDensityMin: TEdit;
    edDensityMax: TEdit;
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
  private
    procedure LoadConfigToUI(const Config: TUniversalConfig);
    function CollectConfigFromUI: TUniversalConfig;
  public
  end;

var
  frmXRFMain: TfrmXRFMain;

implementation

uses
  Vcl.FileCtrl,
  unit_universal_io, cmd_unit_types;

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

{ TfrmXRFMain }

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
  edDensityMin.Text := FormatFloat('0.###', Config.Structure.DensityFactorRange.Min);
  edDensityMax.Text := FormatFloat('0.###', Config.Structure.DensityFactorRange.Max);
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
  Result.Structure.DensityFactorRange.Min := StrToFloatDef(edDensityMin.Text, 0, FS);
  Result.Structure.DensityFactorRange.Max := StrToFloatDef(edDensityMax.Text, 0, FS);

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

end.
