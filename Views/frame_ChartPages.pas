unit frame_ChartPages;

interface

uses
  Winapi.Windows, System.Classes,
  Vcl.Controls, Vcl.Forms,
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
    chThickness: TChart;
    chRoughness: TChart;
    chDensity: TChart;
    chProfile: TChart;
    chFittingProgress: TChart;
    lsrConvergence: TLineSeries;
    btnCopyConvergence: TRzButton;
    btnProfileCopy: TRzButton;
    DensityProfile: TLineSeries;
    procedure btnCopyConvergenceClick(Sender: TObject);
    procedure btnProfileCopyClick(Sender: TObject);
  public
    property ThicknessChart: TChart read chThickness;
    property RoughnessChart: TChart read chRoughness;
    property DensityChart: TChart read chDensity;
    property ProfileSeries: TLineSeries read DensityProfile;

    function IsProfileActive: Boolean;
    procedure ShowFittingProgress;
    procedure ResetToFirstPage;

    procedure AddConvergencePoint(Step: Integer; BestChi: Double);
    procedure ClearConvergence;
    procedure PrepareConvergence(NMax: Integer);

    procedure SetCopyEnabled(Value: Boolean);

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

procedure TfrmChartPages.AddConvergencePoint(Step: Integer; BestChi: Double);
begin
  lsrConvergence.AddXY(Step, BestChi);
end;

procedure TfrmChartPages.ClearConvergence;
begin
  lsrConvergence.Clear;
end;

procedure TfrmChartPages.PrepareConvergence(NMax: Integer);
begin
  lsrConvergence.Clear;
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
end;

end.
