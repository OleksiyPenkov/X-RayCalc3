unit unit_ChartManager;

interface

uses
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine,
  unit_Types;

type
  TFastSeriesList = array of TFastLineSeries;

  TChartManager = class
  private
    FChart: TChart;
    FSeriesList: TFastSeriesList;
    FLineWidth: Integer;
  public
    constructor Create(AChart: TChart; ALineWidth: Integer);

    function AddSeries(Data: PProjectData): Integer;
    procedure DeleteSeries(CurveID: Integer);
    procedure ClearAll;

    procedure PlotResults(CurveID: Integer; const Data: TDataArray);
    procedure RescaleAxis(AMin, AMax, AMinLimit: Single);

    procedure ScaleFonts(ABaseSize, ATargetDPI: Integer);

    property Series: TFastSeriesList read FSeriesList;
    property Chart: TChart read FChart;
    property LineWidth: Integer read FLineWidth write FLineWidth;
  end;

implementation

uses
  System.SysUtils;

{ TChartManager }

constructor TChartManager.Create(AChart: TChart; ALineWidth: Integer);
begin
  inherited Create;
  FChart := AChart;
  FLineWidth := ALineWidth;
end;

function TChartManager.AddSeries(Data: PProjectData): Integer;
var
  Count: Integer;
begin
  Count := Length(FSeriesList);
  SetLength(FSeriesList, Count + 1);
  FSeriesList[Count] := TFastLineSeries.Create(FChart);
  FSeriesList[Count].ParentChart := FChart;

  FSeriesList[Count].Title := Data.Title;
  if Data.Color <> 0 then
    FSeriesList[Count].Color := Data.Color
  else
    Data.Color := FSeriesList[Count].Color;

  FSeriesList[Count].LinePen.Width := FLineWidth;
  Data.Visible := True;
  FSeriesList[Count].Visible := Data.Visible;
  Data.CurveID := Count;
  Result := Count;
end;

procedure TChartManager.DeleteSeries(CurveID: Integer);
begin
  FreeAndNil(FSeriesList[CurveID]);
end;

procedure TChartManager.ClearAll;
begin
  FChart.SeriesList.Clear;
  SetLength(FSeriesList, 0);
end;

procedure TChartManager.PlotResults(CurveID: Integer; const Data: TDataArray);
var
  j: Integer;
  S: TFastLineSeries;
begin
  S := FSeriesList[CurveID];
  S.BeginUpdate;
  S.Clear;
  for j := 0 to High(Data) do
    S.AddXY(Data[j].t, Data[j].R);
  S.EndUpdate;
end;

procedure TChartManager.RescaleAxis(AMin, AMax, AMinLimit: Single);
begin
  FChart.BottomAxis.Minimum := 0;
  FChart.BottomAxis.Minimum := AMin;
  FChart.BottomAxis.Maximum := AMax;
  FChart.LeftAxis.Minimum := AMinLimit;
end;

procedure TChartManager.ScaleFonts(ABaseSize, ATargetDPI: Integer);
var
  I: Integer;
  ScaledBaseSize: Integer;
  ScaledLargeSize: Integer;
begin
  ScaledBaseSize := MulDiv(ABaseSize, ATargetDPI, 96);
  ScaledLargeSize := Round(ScaledBaseSize * 1.2);

  FChart.DefaultFont.Size := ScaledBaseSize;

  FChart.Title.Font.Size := ScaledLargeSize;
  FChart.SubTitle.Font.Size := ScaledLargeSize;
  FChart.Foot.Font.Size := ScaledLargeSize;
  FChart.SubFoot.Font.Size := ScaledLargeSize;

  FChart.Legend.Font.Size := ScaledLargeSize;
  FChart.Legend.Title.Font.Size := ScaledLargeSize;

  for I := 0 to FChart.Axes.Count - 1 do
  begin
    FChart.Axes[I].LabelsFont.Size := ScaledBaseSize;
    FChart.Axes[I].Title.Font.Size := ScaledLargeSize;
  end;

  for I := 0 to FChart.SeriesCount - 1 do
    FChart.Series[I].Marks.Font.Size := ScaledBaseSize;
end;

end.
