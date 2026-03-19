unit frame_RunConfig;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.CheckLst, Vcl.ComCtrls, Vcl.Samples.Spin,
  RzTabs,
  unit_universal_types, unit_universal_io, unit_xrf_lines,
  cmd_unit_types, Vcl.FileCtrl;

type
  TfrmRunConfig = class(TFrame)
    PageControl: TRzPageControl;
    tabTargets: TRzTabSheet;
    tabStructure: TRzTabSheet;
    tabOptimizer: TRzTabSheet;
    tabFitness: TRzTabSheet;
    // Targets tab
    grpLines: TGroupBox;
    lvLines: TListView;
    pnlLineWeight: TPanel;
    lblLineWeight: TLabel;
    edtLineWeight: TEdit;
    grpPool: TGroupBox;
    clbPool: TCheckListBox;
    grpExcludedPairs: TGroupBox;
    clbExcludedPairs: TCheckListBox;
    // Structure tab
    lblDMin: TLabel;
    lblDMax: TLabel;
    lblGammaMin: TLabel;
    lblGammaMax: TLabel;
    lblNMin: TLabel;
    lblNMax: TLabel;
    lblSigma: TLabel;
    lblDensityFactor: TLabel;
    lblSubstrate: TLabel;
    sedDMin: TSpinEdit;
    sedDMax: TSpinEdit;
    sedGammaMin: TSpinEdit;
    sedGammaMax: TSpinEdit;
    sedNMin: TSpinEdit;
    sedNMax: TSpinEdit;
    edtSigma: TEdit;
    edtDensityFactor: TEdit;
    edtSubstrate: TEdit;
    chkPureElements: TCheckBox;
    // Optimizer tab
    lblPopulation: TLabel;
    lblIterations: TLabel;
    lblStagnation: TLabel;
    lblW1: TLabel;
    lblW2: TLabel;
    lblTolerance: TLabel;
    lblJammingMax: TLabel;
    lblCheckpointEvery: TLabel;
    sedPopulation: TSpinEdit;
    sedIterations: TSpinEdit;
    sedStagnation: TSpinEdit;
    edtW1: TEdit;
    edtW2: TEdit;
    edtTolerance: TEdit;
    sedJammingMax: TSpinEdit;
    sedCheckpointEvery: TSpinEdit;
    // Fitness tab
    lblWR: TLabel;
    lblWFWHM: TLabel;
    lblWPurity: TLabel;
    lblRMinThreshold: TLabel;
    lblDeltaTheta: TLabel;
    lblThetaMin: TLabel;
    lblPolarization: TLabel;
    lblScanPoints: TLabel;
    lblScanHalfRange: TLabel;
    edtWR: TEdit;
    edtWFWHM: TEdit;
    edtWPurity: TEdit;
    edtRMinThreshold: TEdit;
    edtDeltaTheta: TEdit;
    edtThetaMin: TEdit;
    cmbPolarization: TComboBox;
    sedScanPoints: TSpinEdit;
    edtScanHalfRange: TEdit;
    grpHenke: TGroupBox;
    edtHenkePath: TEdit;
    btnBrowseHenke: TButton;
    procedure LinesSelectItem(Sender: TObject; Item: TListItem; Selected: Boolean);
    procedure LineWeightExit(Sender: TObject);
    procedure BrowseHenkeClick(Sender: TObject);
  private
    procedure PopulateTargetsData;
  public
    procedure AfterConstruction; override;
    procedure SetDefaults;
    procedure LoadFromConfig(const Config: TUniversalConfig);
    function  BuildConfig: TUniversalConfig;
  end;

implementation

{$R *.dfm}

uses
  System.Math;

procedure TfrmRunConfig.PopulateTargetsData;
var
  Elements: TArray<string>;
  Item: TListItem;
  i: Integer;
begin
  Elements := TArray<string>.Create(
    'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne', 'Na', 'Mg', 'Al', 'Si');
  for i := 0 to High(Elements) do
  begin
    Item := lvLines.Items.Add;
    Item.Caption := Elements[i];
    Item.SubItems.Add('1.0');
  end;

  Elements := TArray<string>.Create('W', 'Mo', 'Cr', 'Si', 'B', 'B4C',
    'Sc', 'C', 'Ni', 'Co', 'La', 'Pt', 'Ru', 'V', 'Ti', 'Nb');
  for i := 0 to High(Elements) do
    clbPool.Items.Add(Elements[i]);
end;

procedure TfrmRunConfig.LinesSelectItem(Sender: TObject; Item: TListItem;
  Selected: Boolean);
begin
  if Selected and (Item <> nil) and (Item.SubItems.Count > 0) then
    edtLineWeight.Text := Item.SubItems[0];
end;

procedure TfrmRunConfig.LineWeightExit(Sender: TObject);
begin
  if (lvLines.Selected <> nil) and (lvLines.Selected.SubItems.Count > 0) then
    lvLines.Selected.SubItems[0] := edtLineWeight.Text;
end;

procedure TfrmRunConfig.AfterConstruction;
begin
  inherited;
  PopulateTargetsData;
end;

procedure TfrmRunConfig.BrowseHenkeClick(Sender: TObject);
var
  Dir: string;
begin
  Dir := edtHenkePath.Text;
  if SelectDirectory('Select Henke Database Folder', '', Dir) then
    edtHenkePath.Text := Dir;
end;

procedure TfrmRunConfig.SetDefaults;
var
  i: Integer;
  DefaultLines: TArray<string>;
  DefaultPool: TArray<string>;
  S: string;
begin
  DefaultLines := TArray<string>.Create('Be', 'B', 'C', 'N', 'O', 'F', 'Na', 'Mg', 'Al', 'Si');
  for i := 0 to lvLines.Items.Count - 1 do
  begin
    lvLines.Items[i].Checked := False;
    lvLines.Items[i].SubItems[0] := '1.0';
  end;
  for i := 0 to lvLines.Items.Count - 1 do
  begin
    for S in DefaultLines do
      if SameText(lvLines.Items[i].Caption, S) then
      begin
        lvLines.Items[i].Checked := True;
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
end;

procedure TfrmRunConfig.LoadFromConfig(const Config: TUniversalConfig);
var
  i, j: Integer;
  PairStr: string;
begin
  // Lines
  for i := 0 to lvLines.Items.Count - 1 do
  begin
    lvLines.Items[i].Checked := False;
    lvLines.Items[i].SubItems[0] := '1.0';
    for j := 0 to High(Config.Lines) do
      if SameText(lvLines.Items[i].Caption, Config.Lines[j].Name) then
      begin
        lvLines.Items[i].Checked := True;
        lvLines.Items[i].SubItems[0] := FormatFloat('0.###', Config.Lines[j].Weight);
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

  // Fitness
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

  sedScanPoints.Value := Config.Fitness.ScanPoints;
  edtScanHalfRange.Text := FormatFloat('0.#', Config.Fitness.ScanHalfRange);

  // Structure advanced
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

  // Optimizer advanced
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
  for i := 0 to lvLines.Items.Count - 1 do
    if lvLines.Items[i].Checked then Inc(Count);
  SetLength(Result.Lines, Count);
  Count := 0;
  for i := 0 to lvLines.Items.Count - 1 do
    if lvLines.Items[i].Checked then
    begin
      Result.Lines[Count].Name := lvLines.Items[i].Caption;
      Result.Lines[Count].Lambda := GetXRFLambda(lvLines.Items[i].Caption);
      Result.Lines[Count].Weight := StrToFloatDef(lvLines.Items[i].SubItems[0], 1.0);
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
  Result.Fitness.ScanPoints := sedScanPoints.Value;
  Result.Fitness.ScanHalfRange := StrToFloatDef(edtScanHalfRange.Text, 0);

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
end;

end.
