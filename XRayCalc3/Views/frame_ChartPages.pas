unit frame_ChartPages;

interface

uses
  Winapi.Windows, System.Classes, System.Math,
  Vcl.Controls, Vcl.Forms, Vcl.Graphics, Vcl.StdCtrls,
  RzTabs, RzButton,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeCanvas, Vcl.ExtCtrls;

type
  TfrmChartPages = class(TFrame)
    Pages: TRzPageControl;
    tsThickness: TRzTabSheet;
    tsRoughness: TRzTabSheet;
    tsDensity: TRzTabSheet;
    tsProfile: TRzTabSheet;
    tsFittingProgress: TRzTabSheet;
    tsDiagnostics: TRzTabSheet;
    chThickness: TChart;
    chRoughness: TChart;
    chDensity: TChart;
    chProfile: TChart;
    chFittingProgress: TChart;
    chDiagnostics: TChart;
    lsrConvergence: TLineSeries;
    btnCopyConvergence: TRzButton;
    btnProfileCopy: TRzButton;
    btnCopyDiagnostics: TRzButton;
    DensityProfile: TLineSeries;
    procedure btnCopyConvergenceClick(Sender: TObject);
    procedure btnProfileCopyClick(Sender: TObject);
    procedure btnCopyDiagnosticsClick(Sender: TObject);
  private
    lsrWorstChi: TLineSeries;
    lsrShake: TPointSeries;
    chkWorstChi: TCheckBox;
    lsrDiversity: TLineSeries;
    lsrMeanVelocity: TLineSeries;
    lsrJamming: TLineSeries;
    lsrLevyScale: TLineSeries;
    lsrCFactor: TLineSeries;
    procedure chkWorstChiClick(Sender: TObject);
  public
    property ThicknessChart: TChart read chThickness;
    property RoughnessChart: TChart read chRoughness;
    property DensityChart: TChart read chDensity;
    property ProfileSeries: TLineSeries read DensityProfile;

    function IsProfileActive: Boolean;
    procedure ShowFittingProgress;
    procedure ResetToFirstPage;

    procedure AddConvergencePoint(Step: Integer; BestChi, WorstChi: Double; WasShaken: Boolean);
    procedure ClearConvergence;
    procedure PrepareConvergence(NMax: Integer);

    procedure SetCopyEnabled(Value: Boolean);

    procedure PrepareDiagnostics(NMax: Integer);
    procedure AddDiagnosticPoint(Step: Integer; Diversity, MeanVelocity: Single;
      JammingCount: Integer; LevyScale, CFact: Single; JammingMax: Integer);
    procedure ClearDiagnostics;

    procedure ScaleSubChartFonts(ABaseSize, ATargetDPI: Integer);
  end;

implementation

uses
  unit_SeriesIO;

{$R *.dfm}

{ TfrmChartPages }

procedure TfrmChartPages.btnCopyConvergenceClick(Sender: TObject);
begin
  SeriesToClipboard('N', 'ChiSqr', '', '', lsrConvergence);
end;

procedure TfrmChartPages.btnProfileCopyClick(Sender: TObject);
begin
  SeriesToClipboard('A', 'g/cm3', '', '', DensityProfile);
end;

procedure TfrmChartPages.btnCopyDiagnosticsClick(Sender: TObject);
begin
  if lsrDiversity <> nil then
    SeriesToClipboard('N', 'Diversity', '', '', lsrDiversity);
end;

function TfrmChartPages.IsProfileActive: Boolean;
begin
  Result := Pages.ActivePage = tsProfile;
end;

procedure TfrmChartPages.ShowFittingProgress;
begin
  Pages.ActivePage := tsFittingProgress;
end;

procedure TfrmChartPages.ResetToFirstPage;
begin
  Pages.ActivePageIndex := 0;
end;

procedure TfrmChartPages.AddConvergencePoint(Step: Integer; BestChi, WorstChi: Double; WasShaken: Boolean);
begin
  lsrConvergence.AddXY(Step, BestChi);
  if lsrWorstChi <> nil then
    lsrWorstChi.AddXY(Step, WorstChi);
  if WasShaken and (lsrShake <> nil) then
    lsrShake.AddXY(Step, BestChi);
end;

procedure TfrmChartPages.ClearConvergence;
begin
  lsrConvergence.Clear;
  if lsrWorstChi <> nil then lsrWorstChi.Clear;
  if lsrShake <> nil then lsrShake.Clear;
  ClearDiagnostics;
end;

procedure TfrmChartPages.chkWorstChiClick(Sender: TObject);
begin
  if lsrWorstChi <> nil then
    lsrWorstChi.Active := chkWorstChi.Checked;
end;

procedure TfrmChartPages.PrepareConvergence(NMax: Integer);
begin
  lsrConvergence.Clear;

  if lsrWorstChi = nil then
  begin
    lsrWorstChi := TLineSeries.Create(chFittingProgress);
    lsrWorstChi.ParentChart := chFittingProgress;
    lsrWorstChi.Title := 'Worst';
    lsrWorstChi.LinePen.Color := clGray;
    lsrWorstChi.LinePen.Style := psDash;
    lsrWorstChi.Stairs := True;
    lsrWorstChi.Active := False;
    lsrWorstChi.ShowInLegend := False;
  end
  else
    lsrWorstChi.Clear;

  if lsrShake = nil then
  begin
    lsrShake := TPointSeries.Create(chFittingProgress);
    lsrShake.ParentChart := chFittingProgress;
    lsrShake.Title := 'Shake';
    lsrShake.Pointer.Style := psTriangle;
    lsrShake.Pointer.Size := 5;
    lsrShake.SeriesColor := $000080FF;
    lsrShake.Pointer.Pen.Color := $000040C0;
    lsrShake.ShowInLegend := False;
  end
  else
    lsrShake.Clear;

  if chkWorstChi = nil then
  begin
    chkWorstChi := TCheckBox.Create(chFittingProgress);
    chkWorstChi.Parent := chFittingProgress;
    chkWorstChi.Caption := 'Worst';
    chkWorstChi.Width := 55;
    chkWorstChi.Anchors := [akTop, akRight];
    chkWorstChi.Left := btnCopyConvergence.Left - chkWorstChi.Width - 4;
    chkWorstChi.Top := btnCopyConvergence.Top + 2;
    chkWorstChi.OnClick := chkWorstChiClick;
  end;

  Pages.ActivePage := tsFittingProgress;
  chFittingProgress.BottomAxis.Minimum := 0;
  chFittingProgress.BottomAxis.Maximum := NMax;
end;

procedure TfrmChartPages.SetCopyEnabled(Value: Boolean);
begin
  btnCopyConvergence.Enabled := Value;
end;

procedure TfrmChartPages.ScaleSubChartFonts(ABaseSize, ATargetDPI: Integer);

  procedure DoScale(AChart: TCustomChart);
  var
    I: Integer;
    ScaledBaseSize: Integer;
    ScaledLargeSize: Integer;
  begin
    if not Assigned(AChart) then Exit;

    ScaledBaseSize := MulDiv(ABaseSize, ATargetDPI, 96);
    ScaledLargeSize := Round(ScaledBaseSize * 1.2);

    AChart.DefaultFont.Size := ScaledBaseSize;
    AChart.Title.Font.Size := ScaledLargeSize;
    AChart.SubTitle.Font.Size := ScaledLargeSize;
    AChart.Foot.Font.Size := ScaledLargeSize;
    AChart.SubFoot.Font.Size := ScaledLargeSize;

    AChart.Legend.Font.Size := ScaledLargeSize;
    AChart.Legend.Title.Font.Size := ScaledLargeSize;

    for I := 0 to AChart.Axes.Count - 1 do
    begin
      AChart.Axes[I].LabelsFont.Size := ScaledBaseSize;
      AChart.Axes[I].Title.Font.Size := ScaledLargeSize;
    end;

    for I := 0 to AChart.SeriesCount - 1 do
      AChart.Series[I].Marks.Font.Size := ScaledBaseSize;
  end;

begin
  DoScale(chThickness);
  DoScale(chRoughness);
  DoScale(chDensity);
  DoScale(chFittingProgress);
  DoScale(chProfile);
  DoScale(chDiagnostics);
end;

{ Diagnostics }

procedure TfrmChartPages.ClearDiagnostics;
begin
  if lsrDiversity <> nil then lsrDiversity.Clear;
  if lsrMeanVelocity <> nil then lsrMeanVelocity.Clear;
  if lsrJamming <> nil then lsrJamming.Clear;
  if lsrLevyScale <> nil then lsrLevyScale.Clear;
  if lsrCFactor <> nil then lsrCFactor.Clear;
end;

procedure TfrmChartPages.PrepareDiagnostics(NMax: Integer);

  function CreateSeries(const ATitle: string; AColor: TColor; ADash: Boolean = False): TLineSeries;
  begin
    Result := TLineSeries.Create(chDiagnostics);
    Result.ParentChart := chDiagnostics;
    Result.Title := ATitle;
    Result.LinePen.Color := AColor;
    Result.LinePen.Width := 2;
    if ADash then
      Result.LinePen.Style := psDash;
  end;

begin
  if lsrDiversity = nil then
  begin
    lsrDiversity    := CreateSeries('Diversity',  clBlue);
    lsrMeanVelocity := CreateSeries('Velocity',   clGreen);
    lsrJamming      := CreateSeries('Jamming',     $000080FF, True);  // Orange, dashed
    lsrLevyScale    := CreateSeries('Levy Scale',  clPurple);
    lsrCFactor      := CreateSeries('CFactor',     clTeal);
  end
  else
    ClearDiagnostics;

  chDiagnostics.BottomAxis.Minimum := 0;
  chDiagnostics.BottomAxis.Maximum := NMax;
end;

procedure TfrmChartPages.AddDiagnosticPoint(Step: Integer;
  Diversity, MeanVelocity: Single; JammingCount: Integer;
  LevyScale, CFact: Single; JammingMax: Integer);
var
  normJam, normLevy, normCF: Double;
begin
  if lsrDiversity = nil then Exit;

  // Diversity: already 0-1
  lsrDiversity.AddXY(Step, Diversity);

  // MeanVelocity: already normalized by Vmax, cap at 1.0
  lsrMeanVelocity.AddXY(Step, Min(MeanVelocity, 1.0));

  // Jamming: normalized by JammingMax
  if JammingMax > 0 then
    normJam := Min(JammingCount / JammingMax, 1.0)
  else
    normJam := 0;
  lsrJamming.AddXY(Step, normJam);

  // LevyScale: map [0.01, 0.1] -> [0, 1]
  normLevy := Min(Max((LevyScale - 0.01) / 0.09, 0), 1.0);
  lsrLevyScale.AddXY(Step, normLevy);

  // CFactor: divide by 2.0, cap at 1.0
  normCF := Min(CFact / 2.0, 1.0);
  lsrCFactor.AddXY(Step, normCF);
end;

end.
