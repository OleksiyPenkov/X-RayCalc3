unit TestResidualStrip;

(* TResidualStrip: the residual axis in the bottom quarter of the main chart -
   its layout shown and hidden, the series it draws, the range it holds after
   a zoom, and that the chart manager clearing every series cannot trip it. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.UITypes, System.Types,
  Winapi.Windows, Vcl.Graphics,
  VCLTee.Chart, VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeGDIPlus,
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
    [Test] procedure Rendered_TheResidualLineIsInTheStrip;
    [Test] procedure Rendered_TheStripIsASeparatePlot;
    [Test] procedure Legend_ModelsThenTheSymbolsInUse;
    [Test] procedure Legend_NoFlooredPoint_NoFlooredKey;
    [Test] procedure Legend_OptionsOff_ModelsOnly;
    [Test] procedure Legend_Hidden_Nothing;
    [Test] procedure Rendered_TheLegendIsAtTheTopOfTheStrip;
    [Test] procedure Shown_WithNothingToPlot_KeepsItsAxis;
    [Test] procedure Rendered_FramesAreAsWideAsTheAxisLine;
    [Test] procedure Rendered_ZoomedCurveStaysInItsPlot;
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
  Result[0].Title := 'Model 3';
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

{ What the window would show: the chart drawn off screen through its GDI+
  canvas, a red residual at +0.5 over the whole range. Its pixels must be
  red, in the strip, below the reflectivity axis. }
procedure TTestResidualStrip.Rendered_TheResidualLineIsInTheStrip;
var
  Plots: TArray<TResidualPlot>;
  i, X, Y, Y0, Y1, Found: Integer;
  Bmp: TBitmap;
  P: TColor;
  Msg: string;
begin
  FChart.Canvas := TGDIPlusCanvas.Create;
  FChart.View3D := False;
  FChart.Legend.Visible := False;
  FChart.Color := clWhite;
  FChart.Gradient.Visible := False;
  FChart.BottomAxis.Automatic := False;
  FChart.BottomAxis.SetMinMax(0, 3);
  FChart.LeftAxis.Automatic := False;
  FChart.LeftAxis.SetMinMax(0, 1);

  Plots := OnePlot;
  for i := 0 to High(Plots[0].Curve.Points) do
    Plots[0].Curve.Points[i].D := 0.5;
  FStrip.SetOptions(False, False, False);
  FStrip.Visible := True;
  FStrip.Plot(Plots);

  Bmp := FChart.TeeCreateBitmap(clWhite, Rect(0, 0, FChart.Width, FChart.Height));
  try
    X := FChart.BottomAxis.CalcXPosValue(1.0);
    Y := FStrip.Axis.CalcYPosValue(0.5);
    Y0 := FStrip.Axis.IStartPos;
    Y1 := FStrip.Axis.IEndPos;
    Assert.IsTrue((Y > Y0) and (Y < Y1), Format('0.5 is inside the strip: %d in %d..%d', [Y, Y0, Y1]));
    Assert.IsTrue(Y0 > FChart.LeftAxis.IEndPos, Format('the strip is below the curves: %d > %d',
      [Y0, FChart.LeftAxis.IEndPos]));
    Found := 0;
    for i := Y - 2 to Y + 2 do
    begin
      P := Bmp.Canvas.Pixels[X, i];
      { clearly red: a 1-pixel line comes out anti-aliased, e.g. (240, 104, 104) }
      if (GetRValue(P) > 180) and (GetRValue(P) - GetGValue(P) > 80) and
         (GetRValue(P) - GetBValue(P) > 80) then
        Inc(Found);
    end;
    if Found = 0 then
    begin
      Msg := '';
      for i := Y - 6 to Y + 6 do
        Msg := Msg + Format(' %d:%.6x', [i, Integer(Bmp.Canvas.Pixels[X, i])]);
      for i := 0 to FChart.SeriesCount - 1 do
        Msg := Msg + Format(' | %s n=%d act=%s vis=%s vax=%d col=%.6x pen=%.6x w=%d',
          [FChart.Series[i].ClassName, FChart.Series[i].Count, BoolToStr(FChart.Series[i].Active, True),
           BoolToStr(FChart.Series[i].Visible, True), Ord(FChart.Series[i].VertAxis),
           Integer(FChart.Series[i].SeriesColor), Integer(TFastLineSeries(FChart.Series[i]).LinePen.Color),
           TFastLineSeries(FChart.Series[i]).LinePen.Width]);
      Assert.Fail(Format('no red at x=%d around y=%d:', [X, Y]) + Msg);
    end;
  finally
    Bmp.Free;
  end;
end;

{ Two plots, not one: the gap between them in the panel's color, not the
  plot's, and a frame line along the top of the strip. }
procedure TTestResidualStrip.Rendered_TheStripIsASeparatePlot;
var
  Bmp: TBitmap;
  X, YGap, YTop: Integer;
  P: TColor;
begin
  FChart.Canvas := TGDIPlusCanvas.Create;
  FChart.View3D := False;
  FChart.Legend.Visible := False;
  FChart.Color := clWhite;
  FChart.Gradient.Visible := False;
  FChart.BackWall.Color := $00E0E0E0;
  FChart.BackWall.Transparent := False;
  FChart.BottomAxis.Automatic := False;
  FChart.BottomAxis.SetMinMax(0, 3);
  FChart.LeftAxis.Automatic := False;
  FChart.LeftAxis.SetMinMax(0, 1);
  FStrip.Visible := True;
  FStrip.Plot(OnePlot);

  Bmp := FChart.TeeCreateBitmap(clWhite, Rect(0, 0, FChart.Width, FChart.Height));
  try
    X := (FChart.ChartRect.Left + FChart.ChartRect.Right) div 2;
    YGap := (FChart.LeftAxis.IEndPos + FStrip.Axis.IStartPos) div 2;
    YTop := FStrip.Axis.IStartPos;
    Assert.IsTrue(FStrip.Axis.IStartPos - FChart.LeftAxis.IEndPos >= 10,
      Format('a gap between the plots: %d..%d', [FChart.LeftAxis.IEndPos, FStrip.Axis.IStartPos]));

    P := Bmp.Canvas.Pixels[X, YGap];
    Assert.AreEqual(Integer(clWhite), Integer(P and $FFFFFF), Format('the gap is the panel at y=%d', [YGap]));

    P := Bmp.Canvas.Pixels[X, YTop];
    Assert.IsTrue((GetRValue(P) < 128) and (GetGValue(P) < 128) and (GetBValue(P) < 128),
      Format('a frame along the top of the strip at y=%d: $%.6x', [YTop, Integer(P)]));
  finally
    Bmp.Free;
  end;
end;

procedure TTestResidualStrip.Legend_ModelsThenTheSymbolsInUse;
var
  Plots: TArray<TResidualPlot>;
  Keys: TArray<TLegendKey>;
begin
  Plots := OnePlot(4) + OnePlot;
  Plots[1].Color := TColors.Blue;
  Plots[1].Title := 'Model 5';
  FStrip.Visible := True;
  FStrip.Plot(Plots);
  Keys := FStrip.LegendKeys;
  Assert.AreEqual(5, Integer(Length(Keys)), 'two models, band mean, floored, +-0.1');
  Assert.AreEqual('Model 3', Keys[0].Text);
  Assert.AreEqual(Integer(MODEL_COLOR), Integer(Keys[0].Color));
  Assert.AreEqual('Model 5', Keys[1].Text);
  Assert.IsTrue(Keys[2].Kind = lkBands, 'band mean');
  Assert.IsTrue(Keys[3].Kind = lkFloored, 'floored');
  Assert.IsTrue(Keys[4].Kind = lkTolerance, '+-0.1');
end;

procedure TTestResidualStrip.Legend_NoFlooredPoint_NoFlooredKey;
var
  Key: TLegendKey;
begin
  FStrip.Visible := True;
  FStrip.Plot(OnePlot);
  for Key in FStrip.LegendKeys do
    Assert.IsFalse(Key.Kind = lkFloored, 'nothing is floored');
end;

procedure TTestResidualStrip.Legend_OptionsOff_ModelsOnly;
begin
  FStrip.Visible := True;
  FStrip.SetOptions(False, False, False);
  FStrip.Plot(OnePlot(4));
  Assert.AreEqual(1, Integer(Length(FStrip.LegendKeys)));
end;

procedure TTestResidualStrip.Legend_Hidden_Nothing;
begin
  FStrip.Plot(OnePlot);
  Assert.AreEqual(0, Integer(Length(FStrip.LegendKeys)));
end;

{ The model's key, a short red line, is drawn in the top left of the strip;
  the residual itself runs at -0.6, well below it. }
procedure TTestResidualStrip.Rendered_TheLegendIsAtTheTopOfTheStrip;
var
  Plots: TArray<TResidualPlot>;
  Bmp: TBitmap;
  i, X, Y, Found: Integer;
  P: TColor;
begin
  FChart.Canvas := TGDIPlusCanvas.Create;
  FChart.View3D := False;
  FChart.Legend.Visible := False;
  FChart.Color := clWhite;
  FChart.Gradient.Visible := False;
  FChart.BottomAxis.Automatic := False;
  FChart.BottomAxis.SetMinMax(0, 3);
  FChart.LeftAxis.Automatic := False;
  FChart.LeftAxis.SetMinMax(0, 1);
  Plots := OnePlot;
  for i := 0 to High(Plots[0].Curve.Points) do
    Plots[0].Curve.Points[i].D := -0.6;
  FStrip.SetOptions(False, False, False);
  FStrip.Visible := True;
  FStrip.Plot(Plots);

  Bmp := FChart.TeeCreateBitmap(clWhite, Rect(0, 0, FChart.Width, FChart.Height));
  try
    Found := 0;
    for Y := FStrip.Axis.IStartPos + 1 to FStrip.Axis.CalcYPosValue(0.5) do
      for X := FChart.ChartRect.Left to (FChart.ChartRect.Left + FChart.ChartRect.Right) div 2 do
      begin
        P := Bmp.Canvas.Pixels[X, Y];
        if (GetRValue(P) > 180) and (GetRValue(P) - GetGValue(P) > 80) and
           (GetRValue(P) - GetBValue(P) > 80) then
          Inc(Found);
      end;
    Assert.IsTrue(Found > 0, 'the red key in the top left of the strip');
  finally
    Bmp.Free;
  end;
end;

{ A new project has nothing to plot yet; the strip's axis, with its labels,
  shows all the same - the chart draws an axis only for a series on it. }
procedure TTestResidualStrip.Shown_WithNothingToPlot_KeepsItsAxis;
var
  i, OnAxis: Integer;
begin
  FStrip.Visible := True;
  FStrip.Plot([]);
  OnAxis := 0;
  for i := 0 to FChart.SeriesCount - 1 do
    if FChart.Series[i].CustomVertAxis = FStrip.Axis then
      Inc(OnAxis);
  Assert.IsTrue(OnAxis > 0, 'a series on the strip''s axis');
end;

{ The frame edges drawn around the plots match the axis lines the chart draws
  on the other edges: a 4-pixel axis gives a frame at least 3 pixels deep. }
procedure TTestResidualStrip.Rendered_FramesAreAsWideAsTheAxisLine;
var
  Bmp: TBitmap;
  X, Y, YTop, Rows: Integer;

  function Dark(P: TColor): Boolean;
  begin
    Result := (GetRValue(P) < 128) and (GetGValue(P) < 128) and (GetBValue(P) < 128);
  end;

begin
  FChart.Canvas := TGDIPlusCanvas.Create;
  FChart.View3D := False;
  FChart.Legend.Visible := False;
  FChart.Color := clWhite;
  FChart.Gradient.Visible := False;
  FChart.LeftAxis.Axis.Width := 4;
  FChart.BottomAxis.Automatic := False;
  FChart.BottomAxis.SetMinMax(0, 3);
  FChart.LeftAxis.Automatic := False;
  FChart.LeftAxis.SetMinMax(0, 1);
  FStrip.SetOptions(False, False, False);
  FStrip.Visible := True;
  FStrip.Plot([]);

  Bmp := FChart.TeeCreateBitmap(clWhite, Rect(0, 0, FChart.Width, FChart.Height));
  try
    X := (FChart.ChartRect.Left + FChart.ChartRect.Right) div 2;
    YTop := FStrip.Axis.IStartPos;
    Rows := 0;
    for Y := YTop - 4 to YTop + 4 do
      if Dark(Bmp.Canvas.Pixels[X, Y]) then
        Inc(Rows);
    Assert.IsTrue(Rows >= 3, Format('%d dark rows at the top of the strip, y=%d', [Rows, YTop]));
  finally
    Bmp.Free;
  end;
end;

{ A mouse-wheel zoom leaves the reflectivity curves running below their axis.
  The chart clips a series to the whole plot, so they ran on through the gap
  and over the strip. A blue curve from 0.5 down to -5 on a 0..1 axis: blue
  above the bottom of its axis, none in the gap or in the strip. }
procedure TTestResidualStrip.Rendered_ZoomedCurveStaysInItsPlot;
var
  Bmp: TBitmap;
  Main: TFastLineSeries;
  X, Y, Found, Leaked: Integer;
  P: TColor;

  function IsBlue(C: TColor): Boolean;
  begin
    Result := (GetBValue(C) > 150) and (GetBValue(C) - GetRValue(C) > 80) and
      (GetBValue(C) - GetGValue(C) > 80);
  end;

begin
  FChart.Canvas := TGDIPlusCanvas.Create;
  FChart.View3D := False;
  FChart.Legend.Visible := False;
  FChart.Color := clWhite;
  FChart.Gradient.Visible := False;
  FChart.BottomAxis.Automatic := False;
  FChart.BottomAxis.SetMinMax(0, 3);
  FChart.LeftAxis.Automatic := False;
  FChart.LeftAxis.SetMinMax(0, 1);

  Main := TFastLineSeries.Create(FChart);
  Main.ParentChart := FChart;
  Main.SeriesColor := TColors.Blue;
  Main.LinePen.Width := 3;
  Main.AddXY(1.5, 0.5);
  Main.AddXY(1.5, -5);

  FStrip.SetOptions(False, False, False);
  FStrip.Visible := True;
  FStrip.Plot(OnePlot);

  Bmp := FChart.TeeCreateBitmap(clWhite, Rect(0, 0, FChart.Width, FChart.Height));
  try
    X := FChart.BottomAxis.CalcXPosValue(1.5);
    Found := 0;
    for Y := FChart.LeftAxis.CalcYPosValue(0.4) to FChart.LeftAxis.IEndPos - 2 do
      for P in [Bmp.Canvas.Pixels[X - 1, Y], Bmp.Canvas.Pixels[X, Y], Bmp.Canvas.Pixels[X + 1, Y]] do
        if IsBlue(P) then
          Inc(Found);
    Assert.IsTrue(Found > 0, 'the curve is drawn in its own plot');

    Leaked := 0;
    for Y := FChart.LeftAxis.IEndPos + 2 to FStrip.Axis.IEndPos - 1 do
      for P in [Bmp.Canvas.Pixels[X - 1, Y], Bmp.Canvas.Pixels[X, Y], Bmp.Canvas.Pixels[X + 1, Y]] do
        if IsBlue(P) then
          Inc(Leaked);
    Assert.AreEqual(0, Leaked, Format('blue pixels below the reflectivity axis (%d..%d)',
      [FChart.LeftAxis.IEndPos + 2, FStrip.Axis.IEndPos - 1]));
  finally
    Bmp.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestResidualStrip);

end.
