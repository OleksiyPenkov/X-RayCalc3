unit unit_ChartManager;

interface

uses
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeCanvas,
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
  Winapi.Windows, System.SysUtils;

{ TChartManager }

constructor TChartManager.Create(AChart: TChart; ALineWidth: Integer);
begin
  inherited Create;
  FChart := AChart;
  FLineWidth := ALineWidth;
end;

function TChartManager.AddSeries(Data: PProjectData): Integer;
var
  Index: Integer;
begin
  Index := Length(FSeriesList);
  SetLength(FSeriesList, Index + 1);
  FSeriesList[Index] := TFastLineSeries.Create(FChart);
  FSeriesList[Index].ParentChart := FChart;

  FSeriesList[Index].Title := Data.Title;
  if Data.Color <> 0 then
    FSeriesList[Index].Color := Data.Color
  else
    Data.Color := FSeriesList[Index].Color;

  FSeriesList[Index].LinePen.Width := FLineWidth;
  Data.Visible := True;
  FSeriesList[Index].Visible := Data.Visible;
  Data.CurveID := Index;
  Result := Index;
end;

procedure TChartManager.DeleteSeries(CurveID: Integer);
begin
  FreeAndNil(FSeriesList[CurveID]);
end;

procedure TChartManager.ClearAll;
begin
  while FChart.SeriesCount > 0 do
    FChart.Series[0].Free;
  SetLength(FSeriesList, 0);
end;

procedure TChartManager.PlotResults(CurveID: Integer; const Data: TDataArray);
var
  j, Count: Integer;
  S: TFastLineSeries;
begin
  Count := Length(Data);
  S := FSeriesList[CurveID];
  S.BeginUpdate;
  S.Clear;

  SetLength(S.XValues.Value, Count);
  SetLength(S.YValues.Value, Count);
  for j := 0 to Count - 1 do
  begin
    S.XValues.Value[j] := Data[j].t;
    S.YValues.Value[j] := Data[j].R;
  end;
  S.XValues.Count := Count;
  S.YValues.Count := Count;

  S.EndUpdate;
end;

procedure TChartManager.RescaleAxis(AMin, AMax, AMinLimit: Single);
begin
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

  for I := 0 to FChart.Axes.Count - 1 do
  begin
    FChart.Axes[I].LabelsFont.Size := ScaledBaseSize;
    FChart.Axes[I].Title.Font.Size := ScaledLargeSize;
  end;

  for I := 0 to FChart.SeriesCount - 1 do
    FChart.Series[I].Marks.Font.Size := ScaledBaseSize;
end;

end.
