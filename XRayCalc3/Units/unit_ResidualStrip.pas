(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_ResidualStrip;

(* The residual strip: a linear vertical axis in the bottom quarter of the main
   chart, under the reflectivity axis, with log10(R_calc / (I_meas K)) of each
   visible model on it. Being part of the same chart, it shares the angle axis,
   so zoom, pan, undo-zoom, copy, export and print take it along. A zoom or a
   pan would also rescale its vertical axis; HoldRange puts it back.

   It is drawn as a plot of its own: before the series the gap between the
   two axes is painted in the panel's color, over the plot background, the
   frame and the grid, and after them each plot gets its own frame. For that
   the strip takes the chart's OnBeforeDrawSeries and OnAfterDraw, calling
   whatever handlers were there before.

   The strip keeps no reference to its series: it finds them by their Tag. So
   whatever frees the chart's series (TChartManager.ClearAll, the chart itself)
   cannot leave it holding a dangling one. *)

interface

uses
  System.Classes, System.UITypes, VCLTee.Chart, VCLTee.TeEngine, VCLTee.Series,
  unit_Residuals;

const
  RESIDUAL_SERIES_TAG = $52455344;   // 'RESD'
  STRIP_START = 78;                  // percent of the plot height, from the top
  MAIN_END = 72;                     // where the reflectivity axis ends while the strip shows
  STRIP_RANGE = 1;                   // decades either side of zero
  STRIP_TOLERANCE = 0.1;             // a tenth of a decade: 26 % high, 21 % low

type
  TResidualPlot = record
    Color: TColor;
    Curve: TResidualCurve;
  end;

  TResidualStrip = class
  private
    FChart: TChart;
    FAxis: TChartAxis;
    FVisible: Boolean;
    FShowTolerance: Boolean;
    FShowBands: Boolean;
    FShowFloored: Boolean;
    FPlots: TArray<TResidualPlot>;
    FPrevBeforeDrawSeries: TNotifyEvent;
    FPrevAfterDraw: TNotifyEvent;
    procedure SetVisible(Value: Boolean);
    procedure ChartBeforeDrawSeries(Sender: TObject);
    procedure ChartAfterDraw(Sender: TObject);
    procedure ClearSeries;
    procedure Redraw;
    function AddLine(AColor: TColor; AWidth: Integer): TFastLineSeries;
    function AddPoints(AColor: TColor): TPointSeries;
  public
    constructor Create(AChart: TChart);
    destructor Destroy; override;

    { Replaces what the strip shows. Drawn only while Visible. }
    procedure Plot(const Plots: array of TResidualPlot);
    procedure Clear;
    { The strip's vertical range back to +-STRIP_RANGE, after a zoom or a pan. }
    procedure HoldRange;
    procedure SetOptions(ShowTolerance, ShowBands, ShowFloored: Boolean);
    { The strip's series now on the chart, for the tests. }
    function SeriesCount: Integer;

    property Visible: Boolean read FVisible write SetVisible;
    property Axis: TChartAxis read FAxis;
  end;

implementation

uses
  System.Types, System.Math, Vcl.Graphics;

constructor TResidualStrip.Create(AChart: TChart);
begin
  inherited Create;
  FChart := AChart;
  FShowTolerance := True;
  FShowBands := True;
  FShowFloored := True;

  FAxis := FChart.CustomAxes.Add;
  FAxis.Horizontal := False;
  FAxis.OtherSide := False;
  FAxis.PositionPercent := 0;
  FAxis.StartPosition := STRIP_START;
  FAxis.EndPosition := 100;
  FAxis.Automatic := False;
  FAxis.AxisValuesFormat := '0.0#';
  FAxis.Increment := 0.5;
  FAxis.Title.Caption := 'log(calc/meas)';
  FAxis.Title.Angle := 90;
  FAxis.Grid.Visible := False;
  HoldRange;
  FAxis.Visible := False;

  FPrevBeforeDrawSeries := FChart.OnBeforeDrawSeries;
  FPrevAfterDraw := FChart.OnAfterDraw;
  FChart.OnBeforeDrawSeries := ChartBeforeDrawSeries;
  FChart.OnAfterDraw := ChartAfterDraw;
end;

destructor TResidualStrip.Destroy;
begin
  FChart.OnBeforeDrawSeries := FPrevBeforeDrawSeries;
  FChart.OnAfterDraw := FPrevAfterDraw;
  inherited;
end;

procedure TResidualStrip.ChartBeforeDrawSeries(Sender: TObject);
begin
  if Assigned(FPrevBeforeDrawSeries) then
    FPrevBeforeDrawSeries(Sender);
  if not FVisible then
    Exit;
  { The gap, frame lines and grid included; one pixel wider than the plot
    either side, where the chart's frame runs. }
  FChart.Canvas.Brush.Style := bsSolid;
  FChart.Canvas.Brush.Color := FChart.Color;
  FChart.Canvas.FillRect(Rect(FChart.ChartRect.Left - 1, FChart.LeftAxis.IEndPos + 1,
    FChart.ChartRect.Right + 2, FAxis.IStartPos));
end;

procedure TResidualStrip.ChartAfterDraw(Sender: TObject);
begin
  if Assigned(FPrevAfterDraw) then
    FPrevAfterDraw(Sender);
  if not FVisible then
    Exit;
  FChart.Canvas.Brush.Style := bsClear;
  FChart.Canvas.Pen.Style := psSolid;
  FChart.Canvas.Pen.Width := 1;
  FChart.Canvas.Pen.Color := FChart.LeftAxis.Axis.Color;
  FChart.Canvas.Rectangle(FChart.ChartRect.Left, FChart.LeftAxis.IStartPos,
    FChart.ChartRect.Right + 1, FChart.LeftAxis.IEndPos + 1);
  FChart.Canvas.Rectangle(FChart.ChartRect.Left, FAxis.IStartPos,
    FChart.ChartRect.Right + 1, FAxis.IEndPos + 1);
end;

procedure TResidualStrip.HoldRange;
begin
  FAxis.SetMinMax(-STRIP_RANGE, STRIP_RANGE);
end;

procedure TResidualStrip.SetVisible(Value: Boolean);
begin
  FVisible := Value;
  FAxis.Visible := Value;
  if Value then
    FChart.LeftAxis.EndPosition := MAIN_END
  else
    FChart.LeftAxis.EndPosition := 100;
  Redraw;
end;

procedure TResidualStrip.SetOptions(ShowTolerance, ShowBands, ShowFloored: Boolean);
begin
  FShowTolerance := ShowTolerance;
  FShowBands := ShowBands;
  FShowFloored := ShowFloored;
  Redraw;
end;

procedure TResidualStrip.Plot(const Plots: array of TResidualPlot);
var
  i: Integer;
begin
  SetLength(FPlots, Length(Plots));
  for i := 0 to High(Plots) do
    FPlots[i] := Plots[i];
  Redraw;
end;

procedure TResidualStrip.Clear;
begin
  FPlots := nil;
  ClearSeries;
end;

function TResidualStrip.SeriesCount: Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FChart.SeriesCount - 1 do
    if FChart.Series[i].Tag = RESIDUAL_SERIES_TAG then
      Inc(Result);
end;

procedure TResidualStrip.ClearSeries;
var
  i: Integer;
begin
  for i := FChart.SeriesCount - 1 downto 0 do
    if FChart.Series[i].Tag = RESIDUAL_SERIES_TAG then
      FChart.Series[i].Free;
end;

function TResidualStrip.AddLine(AColor: TColor; AWidth: Integer): TFastLineSeries;
begin
  Result := TFastLineSeries.Create(FChart);
  Result.Tag := RESIDUAL_SERIES_TAG;
  Result.ParentChart := FChart;
  Result.VertAxis := aCustomVertAxis;
  Result.CustomVertAxis := FAxis;
  Result.ShowInLegend := False;
  Result.SeriesColor := AColor;
  Result.LinePen.Width := AWidth;
  Result.IgnoreNulls := False;          // a floored point breaks the line
  Result.TreatNulls := tnDontPaint;
end;

function TResidualStrip.AddPoints(AColor: TColor): TPointSeries;
begin
  Result := TPointSeries.Create(FChart);
  Result.Tag := RESIDUAL_SERIES_TAG;
  Result.ParentChart := FChart;
  Result.VertAxis := aCustomVertAxis;
  Result.CustomVertAxis := FAxis;
  Result.ShowInLegend := False;
  Result.SeriesColor := AColor;
  Result.Pointer.Style := psCircle;
  Result.Pointer.HorizSize := 2;
  Result.Pointer.VertSize := 2;
  Result.Pointer.Pen.Visible := False;
end;

procedure TResidualStrip.Redraw;
var
  Item: TResidualPlot;
  P: TResidualPoint;
  Line, Steps, Ref: TFastLineSeries;
  Gray: TPointSeries;
  X0, X1: Double;
  b: Integer;

  { A value off the strip is drawn at its edge: the chart clips a series to
    the whole plot, not to its axis, so it would run up into the curves. }
  function Held(D: Double): Double;
  begin
    Result := EnsureRange(D, -STRIP_RANGE, STRIP_RANGE);
  end;

  procedure RefLine(Y: Double; Style: TPenStyle);
  begin
    Ref := AddLine(clGray, 1);
    Ref.LinePen.Style := Style;
    Ref.AddXY(X0, Y);
    Ref.AddXY(X1, Y);
  end;

begin
  ClearSeries;
  if not FVisible then
    Exit;

  X0 := Infinity;
  X1 := NegInfinity;
  for Item in FPlots do
    if Length(Item.Curve.Points) > 0 then
    begin
      X0 := Min(X0, Item.Curve.Points[0].X);
      X1 := Max(X1, Item.Curve.Points[High(Item.Curve.Points)].X);
    end;
  if X1 < X0 then
    Exit;

  { The reference lines first, so the residuals are drawn over them. }
  RefLine(0, psSolid);
  if FShowTolerance then
  begin
    RefLine(STRIP_TOLERANCE, psDot);
    RefLine(-STRIP_TOLERANCE, psDot);
  end;

  for Item in FPlots do
  begin
    if Length(Item.Curve.Points) = 0 then
      Continue;

    Line := AddLine(Item.Color, 1);
    Gray := nil;
    if FShowFloored then
      Gray := AddPoints(clGray);
    for P in Item.Curve.Points do
      if P.Floored then
      begin
        Line.AddNullXY(P.X, 0);
        if Gray <> nil then
          Gray.AddXY(P.X, Held(P.D));
      end
      else
        Line.AddXY(P.X, Held(P.D));

    { Each band its own level, from its start to its end, then a break: an
      empty band leaves a gap and takes nothing else with it. }
    if FShowBands and (Length(Item.Curve.Bands) > 0) then
    begin
      Steps := AddLine(Item.Color, 2);
      for b := 0 to High(Item.Curve.Bands) do
        with Item.Curve.Bands[b] do
          if Count > 0 then
          begin
            Steps.AddXY(Theta0, Held(Mean));
            Steps.AddXY(Theta1, Held(Mean));
            Steps.AddNullXY(Theta1, 0);
          end;
    end;
  end;
end;

end.
