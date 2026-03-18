unit frm_RunConfig;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.Samples.Spin,
  unit_universal_types, unit_universal_io, unit_xrf_lines,
  cmd_unit_types, Vcl.FileCtrl;

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

  Lbl := TLabel.Create(Self); Lbl.Parent := grpAdvanced;
  Lbl.Left := 8; Lbl.Top := Row; Lbl.Caption := 'Excluded pairs:';
  Inc(Row, 18);

  clbExcludedPairs := TCheckListBox.Create(Self);
  clbExcludedPairs.Parent := grpAdvanced;
  clbExcludedPairs.Left := 8; clbExcludedPairs.Top := Row;
  clbExcludedPairs.Width := 470; clbExcludedPairs.Height := 80;
  clbExcludedPairs.Columns := 3;
  Inc(Row, 84);

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
  S: string;
begin
  DefaultLines := TArray<string>.Create('Be', 'B', 'C', 'N', 'O', 'F', 'Na', 'Mg', 'Al', 'Si');
  for i := 0 to clbLines.Count - 1 do
    clbLines.Checked[i] := False;
  for i := 0 to clbLines.Count - 1 do
  begin
    for S in DefaultLines do
      if SameText(clbLines.Items[i], S) then
      begin
        clbLines.Checked[i] := True;
        Break;
      end;
  end;

  DefaultPool := TArray<string>.Create('W', 'Mo', 'Cr', 'Si', 'B', 'B4C', 'Sc', 'C');
  for i := 0 to clbPool.Count - 1 do
    clbPool.Checked[i] := False;
  for i := 0 to clbPool.Count - 1 do
  begin
    for S in DefaultPool do
      if SameText(clbPool.Items[i], S) then
      begin
        clbPool.Checked[i] := True;
        Break;
      end;
  end;

  sedDMin.Value := 30; sedDMax.Value := 80;
  sedGammaMin.Value := 15; sedGammaMax.Value := 70;
  sedNMin.Value := 40; sedNMax.Value := 200;

  sedPopulation.Value := 1000;
  sedIterations.Value := 100;
  sedStagnation.Value := 200;

  edtTemplate.Text := '';
end;

procedure TfrmRunConfig.LoadFromConfig(const Config: TUniversalConfig);
var
  i, j: Integer;
  PairStr: string;
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
      PairStr := Config.ElementPool[Config.ExcludedPairs[j].Idx1] + '/' +
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
  i, k, Count: Integer;
  SigmaVal, DFVal: Single;
  PairStr, Mat1, Mat2: string;
  SlashPos, Idx1, Idx2: Integer;
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

  // Excluded pairs
  SetLength(Result.ExcludedPairs, 0);
  for i := 0 to clbExcludedPairs.Count - 1 do
    if clbExcludedPairs.Checked[i] then
    begin
      PairStr := clbExcludedPairs.Items[i];
      SlashPos := Pos('/', PairStr);
      if SlashPos > 0 then
      begin
        Mat1 := Copy(PairStr, 1, SlashPos - 1);
        Mat2 := Copy(PairStr, SlashPos + 1, MaxInt);
        Idx1 := -1;
        Idx2 := -1;
        for k := 0 to High(Result.ElementPool) do
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

  SigmaVal := StrToFloatDef(edtSigma.Text, 3.5);
  Result.Structure.SigmaFixed := SigmaVal;
  Result.Structure.SigmaRange.Min := SigmaVal;
  Result.Structure.SigmaRange.Max := SigmaVal;

  DFVal := StrToFloatDef(edtDensityFactor.Text, 0.95);
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
end;

end.
