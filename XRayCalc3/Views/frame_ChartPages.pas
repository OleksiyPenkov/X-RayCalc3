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
    chkWorstChi: TCheckBox;
    procedure btnCopyConvergenceClick(Sender: TObject);
    procedure btnProfileCopyClick(Sender: TObject);
    procedure btnCopyDiagnosticsClick(Sender: TObject);
    procedure chkWorstChiClick(Sender: TObject);
  private
    lsrWorstChi: TLineSeries;
    lsrShake: TPointSeries;
    lsrDiversity: TLineSeries;
    lsrMeanVelocity: TLineSeries;
    lsrJamming: TLineSeries;
    lsrLevyScale: TLineSeries;
    lsrCFactor: TLineSeries;
    { The optimizer's step counter restarts at zero on every Run, so an
      appended segment has to be pushed past the points already plotted.
      Without it the series - all loAscending - interleave the two runs'
      identical X values and the plot zig-zags between their chi-squared
      levels. Set by PrepareConvergence, which runs before PrepareDiagnostics. }
    FStepOffset: Integer;
    procedure FitConvergenceAxis;
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
    procedure PrepareConvergence(NMax: Integer; const Append: Boolean = False);

    procedure SetCopyEnabled(Value: Boolean);

    procedure PrepareDiagnostics(NMax: Integer; const Append: Boolean = False);
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
var
  X: Integer;
begin
  X := Step + FStepOffset;
  lsrConvergence.AddXY(X, BestChi);
  if lsrWorstChi <> nil then
    lsrWorstChi.AddXY(X, WorstChi);
  if WasShaken and (lsrShake <> nil) then
    lsrShake.AddXY(X, BestChi);
  FitConvergenceAxis;
end;

{ Pins the log chi-squared axis to whole decades around the visible series.
  Left automatic, the axis could end just under a decade, and the 9.0x10^11
  and 1.0x10^12 labels were drawn on top of each other at the top of the
  short chart. }
procedure TfrmChartPages.FitConvergenceAxis;
var
  Lo, Hi: Double;
begin
  if lsrConvergence.Count = 0 then
  begin
    chFittingProgress.LeftAxis.Automatic := True;
    Exit;
  end;

  Lo := lsrConvergence.MinYValue;
  Hi := lsrConvergence.MaxYValue;
  if (lsrWorstChi <> nil) and lsrWorstChi.Active and (lsrWorstChi.Count > 0) then
  begin
    Lo := Min(Lo, lsrWorstChi.MinYValue);
    Hi := Max(Hi, lsrWorstChi.MaxYValue);
  end;

  if (Lo <= 0) or IsNan(Lo) or IsNan(Hi) or IsInfinite(Hi) then
  begin
    chFittingProgress.LeftAxis.Automatic := True;
    Exit;
  end;

  Lo := Power(10, Floor(Log10(Lo)));
  Hi := Power(10, Ceil(Log10(Hi)));
  if Hi <= Lo then
    Hi := Lo * 10;
  chFittingProgress.LeftAxis.SetMinMax(Lo, Hi);
end;

procedure TfrmChartPages.ClearConvergence;
begin
  FStepOffset := 0;
  lsrConvergence.Clear;
  if lsrWorstChi <> nil then lsrWorstChi.Clear;
  if lsrShake <> nil then lsrShake.Clear;
  FitConvergenceAxis;
  ClearDiagnostics;
end;

procedure TfrmChartPages.chkWorstChiClick(Sender: TObject);
begin
  if lsrWorstChi <> nil then
    lsrWorstChi.Active := chkWorstChi.Checked;
  FitConvergenceAxis;
end;

procedure TfrmChartPages.PrepareConvergence(NMax: Integer; const Append: Boolean);
begin
  if not Append then
    lsrConvergence.Clear;

  { One past the last step already plotted, so the resumed segment continues
    the axis instead of overwriting it. Taken from the series rather than
    counted up by NMax: a run can stop early on tolerance, and NMax may itself
    have been changed between the two runs. }
  if Append and (lsrConvergence.Count > 0) then
    FStepOffset := Round(lsrConvergence.XValue[lsrConvergence.Count - 1]) + 1
  else
    FStepOffset := 0;

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
  else if not Append then
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
  else if not Append then
    lsrShake.Clear;

  { In the DFM beside the Copy button, so that it scales with it: created
    here at a fixed 55 px it ran under the button on a high-DPI display. }
  chkWorstChi.Visible := True;

  Pages.ActivePage := tsFittingProgress;
  chFittingProgress.BottomAxis.Minimum := 0;
  chFittingProgress.BottomAxis.Maximum := FStepOffset + NMax;
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

procedure TfrmChartPages.PrepareDiagnostics(NMax: Integer; const Append: Boolean);

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
  else if not Append then
    ClearDiagnostics;

  { PrepareConvergence has already set FStepOffset for this run. }
  chDiagnostics.BottomAxis.Minimum := 0;
  chDiagnostics.BottomAxis.Maximum := FStepOffset + NMax;
end;

procedure TfrmChartPages.AddDiagnosticPoint(Step: Integer;
  Diversity, MeanVelocity: Single; JammingCount: Integer;
  LevyScale, CFact: Single; JammingMax: Integer);
var
  normJam, normLevy, normCF: Double;
  X: Integer;
begin
  if lsrDiversity = nil then Exit;

  X := Step + FStepOffset;

  // Diversity: already 0-1
  lsrDiversity.AddXY(X, Diversity);

  // MeanVelocity: already normalized by Vmax, cap at 1.0
  lsrMeanVelocity.AddXY(X, Min(MeanVelocity, 1.0));

  // Jamming: normalized by JammingMax
  if JammingMax > 0 then
    normJam := Min(JammingCount / JammingMax, 1.0)
  else
    normJam := 0;
  lsrJamming.AddXY(X, normJam);

  // LevyScale: map [0.01, 0.1] -> [0, 1]
  normLevy := Min(Max((LevyScale - 0.01) / 0.09, 0), 1.0);
  lsrLevyScale.AddXY(X, normLevy);

  // CFactor: divide by 2.0, cap at 1.0
  normCF := Min(CFact / 2.0, 1.0);
  lsrCFactor.AddXY(X, normCF);
end;

end.
