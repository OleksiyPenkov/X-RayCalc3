unit frame_CurvesView;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, System.Math,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  VclTee.TeeGDIPlus,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.Grids,
  RzPanel, RzStatus, RzButton, RzCmboBx, RzRadChk, RzLabel,
  unit_xrfx_package;

type
  TframeCurvesView = class(TFrame)
    pnlInfo: TRzPanel;
    spThetaLabel: TRzStatusPane;
    spTheta: TRzStatusPane;
    spRLabel: TRzStatusPane;
    spR: TRzStatusPane;
    chkTotal: TRzCheckBox;
    btnScale: TRzBitBtn;
    cbMinLimit: TRzComboBox;
    pnlMetrics: TRzPanel;
    chrtPeakPos: TChart;
    chrtR: TChart;
    chrtFWHM: TChart;
    chrtSNR: TChart;
    splMetrics: TSplitter;
    chrtCurves: TChart;
    pnlStructure: TRzPanel;
    lblStructureHeader: TRzLabel;
    grdStructure: TStringGrid;
    pnlLegend: TRzPanel;
    sbLegend: TScrollBox;
    procedure chkTotalClick(Sender: TObject);
    procedure btnScaleClick(Sender: TObject);
    procedure cbMinLimitChange(Sender: TObject);
    procedure ChartMouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure ChartResize(Sender: TObject);
    procedure grdStructureDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
    procedure pnlMetricsResize(Sender: TObject);
  private
    FTotalSeries: TLineSeries;
    FSubstrateRow: Integer;
    FLegendControls: TArray<TControl>;
    procedure UpdateTotalCurve;
    procedure PositionStructurePanel;
    procedure PositionLegendPanel;
    procedure LegendCheckBoxClick(Sender: TObject);
  public
    procedure LoadCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string = '');
    procedure AddCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string);
    procedure LoadStructure(const Structure: TXRFXStructure;
      const Summary: TXRFXStructureSummary);
    procedure LoadMetrics(const M: TXRFXManifest;
      const Curves: TArray<TXRFXCurveData>);
    procedure RefreshLegend;
    procedure Clear;
  end;

implementation

{$R *.dfm}

{ Curves }

procedure TframeCurvesView.LoadCurves(const Curves: TArray<TXRFXCurveData>;
  const FileLabel: string);
begin
  Clear;
  AddCurves(Curves, FileLabel);
end;

procedure TframeCurvesView.AddCurves(const Curves: TArray<TXRFXCurveData>;
  const FileLabel: string);
var
  i, j: Integer;
  Series: TLineSeries;
  Title: string;
begin
  for i := 0 to High(Curves) do
  begin
    Series := TLineSeries.Create(chrtCurves);
    Series.LinePen.Width := 2;
    if FileLabel <> '' then
      Title := FileLabel + ' / ' + Curves[i].Element
    else
      Title := Curves[i].Element;
    Series.Title := Title;

    for j := 0 to High(Curves[i].Theta) do
      Series.AddXY(Curves[i].Theta[j], Curves[i].Refl[j]);

    chrtCurves.AddSeries(Series);
  end;

  if SameText(btnScale.Caption, 'Linear') then
  begin
    // Log mode
    chrtCurves.LeftAxis.Logarithmic := True;
    chrtCurves.LeftAxis.Automatic := False;
    chrtCurves.LeftAxis.AutomaticMaximum := False;
    chrtCurves.LeftAxis.AutomaticMinimum := False;
    chrtCurves.LeftAxis.Maximum := 1;
    chrtCurves.LeftAxis.Minimum := StrToFloat(cbMinLimit.Text);
  end
  else
  begin
    // Linear mode
    chrtCurves.LeftAxis.Logarithmic := False;
    chrtCurves.LeftAxis.Automatic := True;
  end;
  UpdateTotalCurve;
  RefreshLegend;
end;

procedure TframeCurvesView.Clear;
var
  I: Integer;
begin
  FTotalSeries := nil;
  chrtCurves.FreeAllSeries;
  pnlStructure.Visible := False;

  // Clear legend
  for I := High(FLegendControls) downto 0 do
    FLegendControls[I].Free;
  SetLength(FLegendControls, 0);
  pnlLegend.Visible := False;
end;

procedure TframeCurvesView.UpdateTotalCurve;

  function InterpY(S: TChartSeries; X: Double): Double;
  var
    Lo, Hi, Mid: Integer;
    X0, X1, Y0, Y1: Double;
  begin
    Result := 0;
    if S.Count = 0 then Exit;
    if X <= S.XValue[0] then begin Result := S.YValue[0]; Exit; end;
    if X >= S.XValue[S.Count - 1] then begin Result := S.YValue[S.Count - 1]; Exit; end;
    Lo := 0;
    Hi := S.Count - 1;
    while Hi - Lo > 1 do
    begin
      Mid := (Lo + Hi) div 2;
      if S.XValue[Mid] <= X then Lo := Mid else Hi := Mid;
    end;
    X0 := S.XValue[Lo]; X1 := S.XValue[Hi];
    Y0 := S.YValue[Lo]; Y1 := S.YValue[Hi];
    if Abs(X1 - X0) < 1e-15 then
      Result := Y0
    else
      Result := Y0 + (Y1 - Y0) * (X - X0) / (X1 - X0);
  end;

var
  i, j, TotalPts: Integer;
  XMin, XMax, X, Sum: Double;
  S: TChartSeries;
begin
  if FTotalSeries <> nil then
  begin
    chrtCurves.RemoveSeries(FTotalSeries);
    FreeAndNil(FTotalSeries);
  end;

  if not chkTotal.Checked then Exit;
  if chrtCurves.SeriesCount = 0 then Exit;

  // Find full theta range and max resolution across all series
  XMin := MaxDouble;
  XMax := -MaxDouble;
  TotalPts := 0;
  for i := 0 to chrtCurves.SeriesCount - 1 do
  begin
    S := chrtCurves.Series[i];
    if S.Count = 0 then Continue;
    if S.XValue[0] < XMin then XMin := S.XValue[0];
    if S.XValue[S.Count - 1] > XMax then XMax := S.XValue[S.Count - 1];
    if S.Count > TotalPts then TotalPts := S.Count;
  end;
  if (TotalPts = 0) or (XMax <= XMin) then Exit;

  FTotalSeries := TLineSeries.Create(chrtCurves);
  FTotalSeries.Title := 'Total';
  FTotalSeries.LinePen.Width := 3;
  FTotalSeries.LinePen.Color := clBlack;

  for j := 0 to TotalPts - 1 do
  begin
    X := XMin + (XMax - XMin) * j / (TotalPts - 1);
    Sum := 0;
    for i := 0 to chrtCurves.SeriesCount - 1 do
      Sum := Sum + InterpY(chrtCurves.Series[i], X);
    FTotalSeries.AddXY(X, Sum);
  end;

  chrtCurves.AddSeries(FTotalSeries);
end;

procedure TframeCurvesView.chkTotalClick(Sender: TObject);
begin
  UpdateTotalCurve;
  RefreshLegend;
end;

{ Scale & limits }

procedure TframeCurvesView.btnScaleClick(Sender: TObject);
begin
  if chrtCurves.LeftAxis.Logarithmic then
  begin
    chrtCurves.LeftAxis.Logarithmic := False;
    btnScale.Caption := 'Log';
    chrtCurves.LeftAxis.Automatic := True;
    if chrtCurves.LeftAxis.Maximum > 0.01 then
      chrtCurves.LeftAxis.AxisValuesFormat := '0.000'
    else
      chrtCurves.LeftAxis.AxisValuesFormat := '0x10E-0';
  end
  else
  begin
    chrtCurves.LeftAxis.Logarithmic := True;
    btnScale.Caption := 'Linear';
    chrtCurves.LeftAxis.AxisValuesFormat := '0x10E-0';
    chrtCurves.LeftAxis.Maximum := 1;
    chrtCurves.LeftAxis.Minimum := StrToFloat(cbMinLimit.Text);
    chrtCurves.LeftAxis.Automatic := False;
    chrtCurves.LeftAxis.AutomaticMaximum := False;
    chrtCurves.LeftAxis.AutomaticMinimum := False;
  end;
end;

procedure TframeCurvesView.cbMinLimitChange(Sender: TObject);
begin
  if chrtCurves.LeftAxis.Logarithmic then
    chrtCurves.LeftAxis.Minimum := StrToFloat(cbMinLimit.Text);
end;

{ Mouse tracking }

procedure TframeCurvesView.ChartMouseMove(Sender: TObject;
  Shift: TShiftState; X, Y: Integer);
var
  xv, yv: Double;
begin
  if chrtCurves.SeriesCount = 0 then Exit;

  xv := chrtCurves.Series[0].XScreenToValue(X);
  yv := chrtCurves.Series[0].YScreenToValue(Y);

  spTheta.Caption := FloatToStrF(xv, ffFixed, 4, 3);
  if yv < 0.01 then
    spR.Caption := FloatToStrF(yv, ffExponent, 3, 2)
  else
    spR.Caption := FloatToStrF(yv, ffFixed, 4, 3);
end;

procedure TframeCurvesView.ChartResize(Sender: TObject);
begin
  if pnlStructure.Visible then
    PositionStructurePanel;
  if pnlLegend.Visible then
    PositionLegendPanel;
end;

{ Floating legend }

procedure TframeCurvesView.RefreshLegend;
const
  MAX_LEGEND_HEIGHT = 300;
var
  I, Y, Len, TotalH: Integer;
  Row: TPanel;
  Shp: TShape;
  CB: TCheckBox;

  procedure AddControl(C: TControl);
  begin
    Len := Length(FLegendControls);
    SetLength(FLegendControls, Len + 1);
    FLegendControls[Len] := C;
  end;

begin
  // Clear existing
  for I := High(FLegendControls) downto 0 do
    FLegendControls[I].Free;
  SetLength(FLegendControls, 0);

  if chrtCurves.SeriesCount = 0 then
  begin
    pnlLegend.Visible := False;
    Exit;
  end;

  Y := 4;
  for I := 0 to chrtCurves.SeriesCount - 1 do
  begin
    Row := TPanel.Create(sbLegend);
    Row.Parent := sbLegend;
    Row.BevelOuter := bvNone;
    Row.Left := 0;
    Row.Top := Y;
    Row.Width := sbLegend.ClientWidth;
    Row.Height := 20;
    Row.Anchors := [akLeft, akTop, akRight];
    Row.Color := clWhite;
    AddControl(Row);

    Shp := TShape.Create(Row);
    Shp.Parent := Row;
    Shp.Left := 4;
    Shp.Top := 2;
    Shp.Width := 14;
    Shp.Height := 14;
    Shp.Brush.Color := chrtCurves.Series[I].Color;
    Shp.Pen.Color := chrtCurves.Series[I].Color;

    CB := TCheckBox.Create(Row);
    CB.Parent := Row;
    CB.Left := 22;
    CB.Top := 1;
    CB.Width := Row.Width - 26;
    CB.Caption := chrtCurves.Series[I].Title;
    CB.Checked := chrtCurves.Series[I].Active;
    CB.Tag := NativeInt(chrtCurves.Series[I]);
    CB.OnClick := LegendCheckBoxClick;

    Inc(Y, 20);
  end;

  TotalH := Y + 6;
  if TotalH > MAX_LEGEND_HEIGHT then
    TotalH := MAX_LEGEND_HEIGHT;
  pnlLegend.Height := TotalH;

  PositionLegendPanel;
  pnlLegend.Visible := True;
end;

procedure TframeCurvesView.LegendCheckBoxClick(Sender: TObject);
var
  CB: TCheckBox;
  S: TChartSeries;
begin
  CB := Sender as TCheckBox;
  S := TChartSeries(CB.Tag);
  S.Active := CB.Checked;
  S.Visible := CB.Checked;
end;

{ Structure overlay }

procedure TframeCurvesView.LoadStructure(const Structure: TXRFXStructure;
  const Summary: TXRFXStructureSummary);
var
  i, Row, TotalRows, W: Integer;
  HeaderText: string;
begin
  HeaderText := Format('d=%.1f  '#947'=%.3f  N=%d',
    [Summary.D, Summary.Gamma, Summary.N]);
  lblStructureHeader.Caption := HeaderText;

  TotalRows := 1 + Length(Structure.Layers) + 1;
  grdStructure.RowCount := TotalRows;
  grdStructure.ColCount := 4;
  FSubstrateRow := TotalRows - 1;

  W := grdStructure.ClientWidth;
  if W < 100 then W := 294;
  grdStructure.ColWidths[0] := W * 28 div 100;
  grdStructure.ColWidths[1] := W * 24 div 100;
  grdStructure.ColWidths[2] := W * 24 div 100;
  grdStructure.ColWidths[3] := W - grdStructure.ColWidths[0]
    - grdStructure.ColWidths[1] - grdStructure.ColWidths[2] - 4;

  grdStructure.Cells[0, 0] := 'Material';
  grdStructure.Cells[1, 0] := 'H (' + #197 + ')';
  grdStructure.Cells[2, 0] := #963 + ' (' + #197 + ')';
  grdStructure.Cells[3, 0] := #961 + ' (g/cm' + #179 + ')';

  for i := 0 to High(Structure.Layers) do
  begin
    Row := i + 1;
    grdStructure.Cells[0, Row] := Structure.Layers[i].Material;
    grdStructure.Cells[1, Row] := Format('%.2f', [Structure.Layers[i].Thickness]);
    grdStructure.Cells[2, Row] := Format('%.2f', [Structure.Layers[i].Roughness]);
    grdStructure.Cells[3, Row] := Format('%.2f', [Structure.Layers[i].Density]);
  end;

  Row := FSubstrateRow;
  grdStructure.Cells[0, Row] := Structure.Substrate.Material + ' (sub)';
  grdStructure.Cells[1, Row] := #8212;
  grdStructure.Cells[2, Row] := Format('%.2f', [Structure.Substrate.Roughness]);
  grdStructure.Cells[3, Row] := Format('%.2f', [Structure.Substrate.Density]);

  pnlStructure.Height := lblStructureHeader.Height + lblStructureHeader.Margins.Top
    + lblStructureHeader.Margins.Bottom + grdStructure.Margins.Top
    + grdStructure.Margins.Bottom
    + TotalRows * (grdStructure.DefaultRowHeight + 1) + 2;

  PositionStructurePanel;
  pnlStructure.Visible := True;
  pnlStructure.BringToFront;
  if pnlLegend.Visible then
    PositionLegendPanel;
end;

procedure TframeCurvesView.PositionStructurePanel;
begin
  pnlStructure.Parent := chrtCurves;
  pnlStructure.Left := chrtCurves.ClientWidth - pnlStructure.Width
    - chrtCurves.ClientWidth * 4 div 100;
  pnlStructure.Top := chrtCurves.ClientHeight * 4 div 100;
end;

procedure TframeCurvesView.PositionLegendPanel;
begin
  pnlLegend.Parent := chrtCurves;
  if pnlStructure.Visible then
    pnlLegend.Left := pnlStructure.Left - pnlLegend.Width - 4
  else
    pnlLegend.Left := chrtCurves.ClientWidth - pnlLegend.Width
      - chrtCurves.ClientWidth * 4 div 100;
  pnlLegend.Top := chrtCurves.ClientHeight * 4 div 100;
end;

procedure TframeCurvesView.grdStructureDrawCell(Sender: TObject; ACol,
  ARow: Integer; Rect: TRect; State: TGridDrawState);
var
  Grid: TStringGrid;
  S: string;
  TextRect: TRect;
  Flags: Cardinal;
begin
  Grid := TStringGrid(Sender);
  Grid.Canvas.Font.Assign(Grid.Font);

  if ARow = 0 then
  begin
    Grid.Canvas.Brush.Color := $E0E0E0;
    Grid.Canvas.Font.Style := [fsBold];
  end
  else if ARow = FSubstrateRow then
  begin
    Grid.Canvas.Brush.Color := $F0F0FF;
    Grid.Canvas.Font.Style := [];
  end
  else
  begin
    Grid.Canvas.Brush.Color := clWhite;
    Grid.Canvas.Font.Style := [];
  end;

  Grid.Canvas.FillRect(Rect);

  S := Grid.Cells[ACol, ARow];
  if S = '' then Exit;

  TextRect := Rect;
  InflateRect(TextRect, -3, -1);

  Flags := DT_VCENTER or DT_SINGLELINE or DT_END_ELLIPSIS;
  if (ACol > 0) and (ARow > 0) then
    Flags := Flags or DT_RIGHT
  else
    Flags := Flags or DT_LEFT;

  DrawText(Grid.Canvas.Handle, PChar(S), Length(S), TextRect, Flags);
end;

{ Metrics charts }

function FindPeakPosition(const Curve: TXRFXCurveData): Double;
var
  i, MaxIdx: Integer;
  MaxR: Double;
begin
  Result := 0;
  if Length(Curve.Refl) = 0 then Exit;
  MaxIdx := 0;
  MaxR := Curve.Refl[0];
  for i := 1 to High(Curve.Refl) do
    if Curve.Refl[i] > MaxR then
    begin
      MaxR := Curve.Refl[i];
      MaxIdx := i;
    end;
  if MaxIdx <= High(Curve.Theta) then
    Result := Curve.Theta[MaxIdx];
end;

function CalcSNR(const Curve: TXRFXCurveData): Double;
var
  i, TailStart, PeakIdx: Integer;
  MaxR, TailSum: Double;
  TailCount: Integer;
begin
  Result := 0;
  if Length(Curve.Refl) < 10 then Exit;

  PeakIdx := 0;
  MaxR := Curve.Refl[0];
  for i := 1 to High(Curve.Refl) do
    if Curve.Refl[i] > MaxR then
    begin
      MaxR := Curve.Refl[i];
      PeakIdx := i;
    end;

  TailStart := Length(Curve.Refl) - Length(Curve.Refl) div 5;
  if TailStart <= PeakIdx then
    TailStart := PeakIdx + (Length(Curve.Refl) - PeakIdx) div 2;
  if TailStart >= Length(Curve.Refl) then
    TailStart := Length(Curve.Refl) - 1;

  TailSum := 0;
  TailCount := 0;
  for i := TailStart to High(Curve.Refl) do
  begin
    TailSum := TailSum + Curve.Refl[i];
    Inc(TailCount);
  end;

  if (TailCount > 0) and (TailSum / TailCount > 1e-15) then
    Result := MaxR / (TailSum / TailCount);
end;

function FindCurveForElement(const Curves: TArray<TXRFXCurveData>;
  const ElementName: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Curves) do
    if SameText(Curves[i].Element, ElementName) then
      Exit(i);
  Result := -1;
end;

procedure AddBarToChart(AChart: TChart; AValue: Double;
  const ALabel, AFormat: string; AColor: TColor);
var
  S: TBarSeries;
begin
  if AChart.SeriesCount = 0 then
  begin
    S := TBarSeries.Create(AChart);
    S.Marks.Visible := True;
    S.Marks.Style := smsValue;
    S.Marks.Font.Height := -11;
    S.ColorEachPoint := True;
    AChart.AddSeries(S);
  end
  else
    S := AChart.Series[0] as TBarSeries;

  S.Add(AValue, ALabel, AColor);
  S.ValueFormat := AFormat;
end;

procedure TframeCurvesView.LoadMetrics(const M: TXRFXManifest;
  const Curves: TArray<TXRFXCurveData>);
const
  BarColors: array[0..7] of TColor = (
    $CC6633, $3399CC, $33CC66, $CC3366,
    $9966CC, $66CCCC, $CCCC33, $CC9933);
var
  i, CurveIdx: Integer;
  PeakPos, SNR: Double;
  C: TColor;
begin
  chrtPeakPos.FreeAllSeries;
  chrtR.FreeAllSeries;
  chrtFWHM.FreeAllSeries;
  chrtSNR.FreeAllSeries;

  if Length(M.PerElement) = 0 then
  begin
    pnlMetrics.Visible := False;
    splMetrics.Visible := False;
    Exit;
  end;

  for i := 0 to High(M.PerElement) do
  begin
    PeakPos := 0;
    SNR := 0;
    CurveIdx := FindCurveForElement(Curves, M.PerElement[i].Line);
    if CurveIdx >= 0 then
    begin
      PeakPos := FindPeakPosition(Curves[CurveIdx]);
      SNR := CalcSNR(Curves[CurveIdx]);
    end;

    C := BarColors[i mod Length(BarColors)];

    AddBarToChart(chrtPeakPos, PeakPos, M.PerElement[i].Line, '##0.0#', C);
    AddBarToChart(chrtR, M.PerElement[i].PeakR, M.PerElement[i].Line, '#0.0000', C);
    AddBarToChart(chrtFWHM, M.PerElement[i].FWHM, M.PerElement[i].Line, '#0.000', C);
    AddBarToChart(chrtSNR, SNR, M.PerElement[i].Line, '#0.0', C);
  end;

  chrtPeakPos.BottomAxis.Inverted := False;
  chrtR.BottomAxis.Inverted := False;
  chrtFWHM.BottomAxis.Inverted := False;
  chrtSNR.BottomAxis.Inverted := False;

  pnlMetrics.Visible := True;
  splMetrics.Visible := True;
end;

procedure TframeCurvesView.pnlMetricsResize(Sender: TObject);
var
  W: Integer;
begin
  W := pnlMetrics.ClientWidth div 4;
  chrtPeakPos.Width := W;
  chrtR.Width := W;
  chrtFWHM.Width := W;
end;

end.
