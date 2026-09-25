unit TestResidualStrip;

(* TResidualStrip: the residual axis in the bottom quarter of the main chart -
   its layout shown and hidden, the series it draws, the range it holds after
   a zoom, and that the chart manager clearing every series cannot trip it. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.UITypes,
  VCLTee.Chart, VCLTee.TeEngine, VCLTee.Series,
  unit_Types, unit_MCPFitReport, unit_Residuals, unit_ResidualStrip, unit_ChartManager;

type
  [TestFixture]
  TTestResidualStrip = class
  private
    FChart: TChart;
    FStrip: TResidualStrip;
    function Curve(FlooredAt: Integer = -1): TResidualCurve;
    function OnePlot(FlooredAt: Integer = -1): TArray<TResidualPlot>;
    function ResidualLine: TFastLineSeries;
    function BandSteps: TFastLineSeries;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Hidden_ByDefault_DrawsNothing;
    [Test] procedure Shown_TakesTheBottomOfThePlot;
    [Test] procedure Hidden_GivesThePlotBack;
    [Test] procedure Plot_AllOptions_ReferenceLinesCurveFlooredAndBands;
    [Test] procedure Plot_NoOptions_ZeroLineAndCurve;
    [Test] procedure FlooredPoint_BreaksTheLine;
    [Test] procedure HoldRange_UndoesAZoom;
    [Test] procedure ValueOffTheStrip_IsDrawnAtItsEdge;
    [Test] procedure EmptyBand_LeavesTheOtherBandsDrawn;
    [Test] procedure ChartManagerClearAll_LeavesTheStripWorking;
  end;

implementation

const
  MODEL_COLOR = TColors.Red;

procedure TTestResidualStrip.Setup;
begin
  FChart := TChart.Create(nil);
  FChart.Width := 400;
  FChart.Height := 300;
  FStrip := TResidualStrip.Create(FChart);
end;

procedure TTestResidualStrip.TearDown;
begin
  FStrip.Free;
  FChart.Free;
end;

function TTestResidualStrip.Curve(FlooredAt: Integer): TResidualCurve;
var
  i: Integer;
begin
  SetLength(Result.Points, 20);
  for i := 0 to High(Result.Points) do
  begin
    Result.Points[i].X := 0.1 * (i + 1);
    Result.Points[i].D := 0.05 * Sin(i);
    Result.Points[i].Floored := i = FlooredAt;
  end;
  SetLength(Result.Bands, 2);
  Result.Bands[0].Theta0 := 0.1;
  Result.Bands[0].Theta1 := 1.05;
  Result.Bands[0].Count := 10;
  Result.Bands[0].Mean := 0.02;
  Result.Bands[1].Theta0 := 1.05;
  Result.Bands[1].Theta1 := 2.0;
  Result.Bands[1].Count := 10;
  Result.Bands[1].Mean := -0.03;
end;

function TTestResidualStrip.OnePlot(FlooredAt: Integer): TArray<TResidualPlot>;
begin
  SetLength(Result, 1);
  Result[0].Color := MODEL_COLOR;
  Result[0].Curve := Curve(FlooredAt);
end;

function TTestResidualStrip.ResidualLine: TFastLineSeries;
var
  i: Integer;
begin
  for i := 0 to FChart.SeriesCount - 1 do
    if (FChart.Series[i].Tag = RESIDUAL_SERIES_TAG) and (FChart.Series[i] is TFastLineSeries) and
       (FChart.Series[i].SeriesColor = MODEL_COLOR) and (TFastLineSeries(FChart.Series[i]).LinePen.Width = 1) then
      Exit(TFastLineSeries(FChart.Series[i]));
  Result := nil;
end;

function TTestResidualStrip.BandSteps: TFastLineSeries;
var
  i: Integer;
begin
  for i := 0 to FChart.SeriesCount - 1 do
    if (FChart.Series[i].Tag = RESIDUAL_SERIES_TAG) and (FChart.Series[i] is TFastLineSeries) and
       (FChart.Series[i].SeriesColor = MODEL_COLOR) and (TFastLineSeries(FChart.Series[i]).LinePen.Width = 2) then
      Exit(TFastLineSeries(FChart.Series[i]));
  Result := nil;
end;

procedure TTestResidualStrip.Hidden_ByDefault_DrawsNothing;
begin
  FStrip.Plot(OnePlot);
  Assert.IsFalse(FStrip.Axis.Visible, 'axis hidden');
  Assert.AreEqual(100.0, Double(FChart.LeftAxis.EndPosition), 1E-9, 'reflectivity axis at full height');
  Assert.AreEqual(0, FStrip.SeriesCount, 'no series');
end;

procedure TTestResidualStrip.Shown_TakesTheBottomOfThePlot;
begin
  FStrip.Visible := True;
  Assert.IsTrue(FStrip.Axis.Visible, 'axis shown');
  Assert.AreEqual(Double(MAIN_END), Double(FChart.LeftAxis.EndPosition), 'reflectivity axis above');
  Assert.AreEqual(Double(STRIP_START), Double(FStrip.Axis.StartPosition), 'strip starts below it');
  Assert.AreEqual(100.0, Double(FStrip.Axis.EndPosition), 1E-9, 'strip reaches the bottom');
  Assert.AreEqual(Double(-STRIP_RANGE), Double(FStrip.Axis.Minimum), 1E-9, 'minimum');
  Assert.AreEqual(Double(STRIP_RANGE), Double(FStrip.Axis.Maximum), 1E-9, 'maximum');
end;

procedure TTestResidualStrip.Hidden_GivesThePlotBack;
begin
  FStrip.Visible := True;
  FStrip.Plot(OnePlot);
  FStrip.Visible := False;
  Assert.AreEqual(100.0, Double(FChart.LeftAxis.EndPosition), 1E-9, 'reflectivity axis at full height');
  Assert.AreEqual(0, FStrip.SeriesCount, 'series removed');
end;

procedure TTestResidualStrip.Plot_AllOptions_ReferenceLinesCurveFlooredAndBands;
begin
  FStrip.Visible := True;
  FStrip.Plot(OnePlot);
  { zero, +0.1, -0.1, the residual, its floored points, its band steps }
  Assert.AreEqual(6, FStrip.SeriesCount);
end;

procedure TTestResidualStrip.Plot_NoOptions_ZeroLineAndCurve;
begin
  FStrip.Visible := True;
  FStrip.SetOptions(False, False, False);
  FStrip.Plot(OnePlot);
  Assert.AreEqual(2, FStrip.SeriesCount);
end;

procedure TTestResidualStrip.FlooredPoint_BreaksTheLine;
var
  Line: TFastLineSeries;
begin
  FStrip.Visible := True;
  FStrip.Plot(OnePlot(7));
  Line := ResidualLine;
  Assert.IsNotNull(Line, 'residual line');
  Assert.AreEqual(20, Line.Count, 'every point, floored ones as nulls');
  Assert.IsTrue(Line.IsNull(7), 'floored point is a gap');
  Assert.IsFalse(Line.IsNull(6), 'its neighbour is drawn');
  Assert.IsFalse(Line.IgnoreNulls, 'the line breaks at a null');
end;

procedure TTestResidualStrip.HoldRange_UndoesAZoom;
begin
  FStrip.Visible := True;
  FStrip.Axis.SetMinMax(-0.3, 0.2);
  FStrip.HoldRange;
  Assert.AreEqual(Double(-STRIP_RANGE), Double(FStrip.Axis.Minimum), 1E-9, 'minimum');
  Assert.AreEqual(Double(STRIP_RANGE), Double(FStrip.Axis.Maximum), 1E-9, 'maximum');
end;

procedure TTestResidualStrip.ValueOffTheStrip_IsDrawnAtItsEdge;
var
  Plots: TArray<TResidualPlot>;
  Line: TFastLineSeries;
begin
  Plots := OnePlot;
  Plots[0].Curve.Points[3].D := 2.5;
  Plots[0].Curve.Points[4].D := -4;
  FStrip.Visible := True;
  FStrip.Plot(Plots);
  Line := ResidualLine;
  Assert.AreEqual(Double(STRIP_RANGE), Line.YValues[3], 1E-9, 'above');
  Assert.AreEqual(Double(-STRIP_RANGE), Line.YValues[4], 1E-9, 'below');
  Assert.AreEqual(0.05 * Sin(5), Line.YValues[5], 1E-6, 'inside, as it is');
end;

procedure TTestResidualStrip.EmptyBand_LeavesTheOtherBandsDrawn;
var
  Plots: TArray<TResidualPlot>;
  Steps: TFastLineSeries;
begin
  Plots := OnePlot;
  Plots[0].Curve.Bands[1].Count := 0;
  FStrip.Visible := True;
  FStrip.Plot(Plots);
  Steps := BandSteps;
  Assert.IsNotNull(Steps, 'band steps');
  Assert.AreEqual(3, Steps.Count, 'band 0: its start, its end, a break');
  Assert.AreEqual(0.02, Steps.YValues[0], 1E-9, 'band 0 level at its start');
  Assert.AreEqual(0.02, Steps.YValues[1], 1E-9, 'band 0 level at its end');
  Assert.AreEqual(1.05, Steps.XValues[1], 1E-9, 'band 0 ends at its edge');
  Assert.IsTrue(Steps.IsNull(2), 'then a break');
end;

procedure TTestResidualStrip.ChartManagerClearAll_LeavesTheStripWorking;
var
  Mgr: TChartManager;
begin
  Mgr := TChartManager.Create(FChart, 2);
  try
    FStrip.Visible := True;
    FStrip.Plot(OnePlot);
    Mgr.ClearAll;
    Assert.AreEqual(0, FStrip.SeriesCount, 'cleared with the rest');
    FStrip.Plot(OnePlot);
    Assert.AreEqual(6, FStrip.SeriesCount, 'drawn again');
  finally
    Mgr.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestResidualStrip);

end.
