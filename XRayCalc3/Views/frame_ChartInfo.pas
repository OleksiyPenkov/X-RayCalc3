unit frame_ChartInfo;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IniFiles,
  System.UITypes,
  Vcl.Controls, Vcl.Graphics, Vcl.Forms, Vcl.StdCtrls, Vcl.Dialogs,
  Vcl.ExtCtrls,
  RzStatus, RzButton, RzCmboBx, RzPanel,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.TeCanvas,
  VCLTee.Chart, VCLTee.Series,
  frame_CalcSettings, unit_Types;

type
  TGetFastSeriesEvent = function: TFastLineSeries of object;
  TLegendCheckEvent = procedure(Sender: TObject; Series: TChartSeries) of object;

  TLegendEntry = record
    Title: string;
    Color: TColor;
    Visible: Boolean;
    Linked: Boolean;
    Group: TProjectGroupType;
    CurveID: Integer;
    Series: TChartSeries;
  end;

  TfrmChartInfo = class(TFrame)
    pnlInfo: TRzPanel;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    StatusY: TRzStatusPane;
    StatusX: TRzStatusPane;
    RzStatusPane3: TRzStatusPane;
    RzStatusPane4: TRzStatusPane;
    StatusMaxX: TRzStatusPane;
    StatusRMax: TRzStatusPane;
    RzStatusPane5: TRzStatusPane;
    StatusD: TRzStatusPane;
    RzStatusPane6: TRzStatusPane;
    StatusRi: TRzStatusPane;
    spChiSqr: TRzStatusPane;
    RzStatusPane7: TRzStatusPane;
    spChiBest: TRzStatusPane;
    btnChartScale: TRzBitBtn;
    cbMinLimit: TRzComboBox;
    dlgSaveResult: TSaveDialog;
    dlgExport: TSaveDialog;
    dlgPrint: TPrintDialog;
    pnlLegend: TRzPanel;
    sbLegend: TScrollBox;
    Chart: TChart;
    btnStop: TRzBitBtn;
    procedure btnChartScaleClick(Sender: TObject);
    procedure cbMinLimitChange(Sender: TObject);
    procedure ChartMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ChartMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartResize(Sender: TObject);
    procedure ChartZoom(Sender: TObject);
  private
    FGetActiveModelSeries: TGetFastSeriesEvent;
    FGetActiveDataSeries: TGetFastSeriesEvent;
    FOnSaveActiveData: TNotifyEvent;
    FOnLegendCheckBoxClick: TLegendCheckEvent;
    FCalcSettings: TfrmCalcSettings;
    FLegendControls: TArray<TControl>;
    procedure LegendCheckBoxClick(Sender: TObject);
    function GetMinLimit: Single;
    function GetMinLimitText: string;
    procedure SetMinLimitText(const Value: string);
  public
    procedure SetCursorPos(const X, Y: Single);
    procedure SetPeakInfo(Series: TChartSeries; XMin, XMax: Single);
    procedure SetChiSquare(const Current, Best: Single);
    procedure ClearChiSquare;
    procedure SetPeriod(const D: Single);
    procedure SetScaleCaption(const Caption: string);
    procedure UpdateAxisFormat;

    property MinLimit: Single read GetMinLimit;
    property MinLimitText: string read GetMinLimitText write SetMinLimitText;

    procedure LoadFromINI(INF: TMemIniFile);
    procedure SaveToINI(INF: TMemIniFile);

    { Plot clipboard/file operations }
    procedure CopyPlotBitmap;
    procedure CopyPlotMetafile;
    procedure ExportPlotToFile;
    procedure PrintChart;

    { Result data operations }
    procedure SaveResultToFile;
    procedure CopyResultToClipboard;

    { Experimental data operations }
    procedure CopyDataToClipboard;
    procedure ExportDataToFile;
    procedure NormalizeData;
    procedure NormalizeDataAuto;
    procedure SmoothData;
    procedure TrimData;

    procedure RefreshLegend(const Items: TArray<TLegendEntry>);
    procedure ClearLegend;

    property CalcSettings: TfrmCalcSettings read FCalcSettings write FCalcSettings;
    property OnGetActiveModelSeries: TGetFastSeriesEvent read FGetActiveModelSeries write FGetActiveModelSeries;
    property OnGetActiveDataSeries: TGetFastSeriesEvent read FGetActiveDataSeries write FGetActiveDataSeries;
    property OnSaveActiveData: TNotifyEvent read FOnSaveActiveData write FOnSaveActiveData;
    property OnLegendCheckBoxClick: TLegendCheckEvent read FOnLegendCheckBoxClick write FOnLegendCheckBoxClick;
  end;

implementation

uses
  System.Math,
  unit_SeriesIO, unit_DataProcessing;

{$R *.dfm}

{ TfrmChartInfo }

procedure TfrmChartInfo.btnChartScaleClick(Sender: TObject);
begin
  Chart.LeftAxis.Logarithmic := not Chart.LeftAxis.Logarithmic;
  UpdateAxisFormat;
end;

procedure TfrmChartInfo.UpdateAxisFormat;
begin
  if Chart.LeftAxis.Logarithmic then
  begin
    SetScaleCaption('Linear');
    Chart.LeftAxis.AxisValuesFormat := '0e-0';
  end
  else
  begin
    SetScaleCaption('Log');
    Chart.LeftAxis.AxisValuesFormat := '0.###';
  end;
end;

procedure TfrmChartInfo.cbMinLimitChange(Sender: TObject);
begin
  Chart.LeftAxis.Minimum := MinLimit;
end;

function TfrmChartInfo.GetMinLimit: Single;
begin
  Result := StrToFloat(cbMinLimit.Text);
end;

function TfrmChartInfo.GetMinLimitText: string;
begin
  Result := cbMinLimit.Text;
end;

procedure TfrmChartInfo.SetMinLimitText(const Value: string);
begin
  cbMinLimit.Text := Value;
end;

procedure TfrmChartInfo.SetCursorPos(const X, Y: Single);
begin
  StatusX.Caption := FloatToStrF(X, ffFixed, 4, 3);
  if Y < 0.01 then
    StatusY.Caption := FloatToStrF(Y, ffExponent, 3, 2)
  else
    StatusY.Caption := FloatToStrF(Y, ffFixed, 4, 3);
end;

procedure TfrmChartInfo.SetPeakInfo(Series: TChartSeries; XMin, XMax: Single);
var
  XVal, YVal, mx, my, RI, OldX: Single;
  i: Integer;
begin
  if Series.Count = 0 then
    Exit;

  my := 0;
  mx := 0;
  RI := 0;
  OldX := Series.XValue[1];
  for i := 2 to Series.Count - 2 do
  begin
    XVal := Series.XValue[i];
    YVal := Series.YValue[i];
    if (XVal > XMin) and (XVal < XMax) then
    begin
      RI := RI + YVal * Abs(OldX - XVal);
      if YVal > my then
      begin
        my := YVal;
        mx := XVal;
      end;
    end;
    OldX := XVal;
  end;

  if my < 0.01 then
    StatusRMax.Caption := FloatToStrF(my, ffExponent, 3, 2)
  else
    StatusRMax.Caption := FloatToStrF(my, ffFixed, 4, 3);

  StatusMaxX.Caption := FloatToStrF(mx, ffFixed, 5, 4);
  StatusRi.Caption := FloatToStrF(RI, ffFixed, 7, 4);
end;

procedure TfrmChartInfo.SetChiSquare(const Current, Best: Single);
begin
  spChiSqr.Caption := FloatToStrF(Current, ffFixed, 8, 4);
  spChiBest.Caption := FloatToStrF(Best, ffFixed, 8, 4);
end;

procedure TfrmChartInfo.ClearChiSquare;
begin
  spChiSqr.Caption := '';
end;

procedure TfrmChartInfo.SetPeriod(const D: Single);
begin
  StatusD.Caption := FloatToStrF(D, ffFixed, 7, 2);
end;

procedure TfrmChartInfo.SetScaleCaption(const Caption: string);
begin
  btnChartScale.Caption := Caption;
end;

procedure TfrmChartInfo.LoadFromINI(INF: TMemIniFile);
begin
  cbMinLimit.Text := INF.ReadString('PARAMS', 'MinLimit', '1E-7');
end;

procedure TfrmChartInfo.SaveToINI(INF: TMemIniFile);
begin
  INF.WriteString('PARAMS', 'MinLimit', cbMinLimit.Text);
end;

procedure TfrmChartInfo.ChartMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    Screen.Cursor := crSizeAll;
end;

procedure TfrmChartInfo.ChartMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  Series: TFastLineSeries;
  xv, yv: Single;
begin
  if not Assigned(FGetActiveModelSeries) then Exit;
  Series := FGetActiveModelSeries;
  if Series = nil then Exit;

  xv := Series.XScreenToValue(X);
  yv := Series.YScreenToValue(Y);
  SetCursorPos(xv, yv);
end;

procedure TfrmChartInfo.ChartMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    Screen.Cursor := crDefault;
end;

procedure TfrmChartInfo.ChartResize(Sender: TObject);
begin
  btnStop.Left := Chart.ClientWidth div 2 - 40;
  pnlLegend.Left := Chart.ClientWidth - pnlLegend.Width - Chart.ClientWidth * 2 div 100;
  pnlLegend.Top := Chart.ClientHeight * 4 div 100;
end;

procedure TfrmChartInfo.ChartZoom(Sender: TObject);
var
  Series: TFastLineSeries;
begin
  if not Assigned(FGetActiveModelSeries) then Exit;
  Series := FGetActiveModelSeries;
  if Series = nil then Exit;

  SetPeakInfo(Series, Chart.BottomAxis.Minimum, Chart.BottomAxis.Maximum);
end;

{ Plot clipboard/file operations }

procedure TfrmChartInfo.CopyPlotBitmap;
begin
  Chart.CopyToClipboardBitmap;
end;

procedure TfrmChartInfo.CopyPlotMetafile;
begin
  Chart.CopyToClipboardMetafile(True);
end;

procedure TfrmChartInfo.ExportPlotToFile;
begin
  if dlgExport.Execute then
    Case dlgExport.FilterIndex of
      1:
        Chart.SaveToBitmapFile(dlgExport.FileName + '.bmp');
      2:
        Chart.SaveToMetafileEnh(dlgExport.FileName + '.emf');
      3:
        Chart.SaveToMetafile(dlgExport.FileName + '.wmf');
    end;
end;

procedure TfrmChartInfo.PrintChart;
begin
  if dlgPrint.Execute then
  begin
    Chart.Title.Visible := True;
    Chart.PrintLandscape;
    Chart.Title.Visible := False;
  end;
end;

{ Result data operations }

procedure TfrmChartInfo.SaveResultToFile;
var
  Series: TFastLineSeries;
begin
  Series := FGetActiveModelSeries;
  if Series = nil then Exit;
  if dlgSaveResult.Execute then
    SeriesToFile(Series, dlgSaveResult.FileName);
end;

procedure TfrmChartInfo.CopyResultToClipboard;
var
  Series: TFastLineSeries;
begin
  Series := FGetActiveModelSeries;
  if Series = nil then Exit;
  SeriesToClipboard(Series, FCalcSettings.CalcMode);
end;

{ Experimental data operations }

procedure TfrmChartInfo.CopyDataToClipboard;
var
  Series: TFastLineSeries;
begin
  Series := FGetActiveDataSeries;
  if Series = nil then Exit;
  SeriesToClipboard(Series, FCalcSettings.CalcMode);
end;

procedure TfrmChartInfo.ExportDataToFile;
var
  Series: TFastLineSeries;
begin
  Series := FGetActiveModelSeries;
  if Series = nil then Exit;
  if dlgSaveResult.Execute then
    SeriesToFile(Series, dlgSaveResult.FileName);
end;

procedure TfrmChartInfo.NormalizeData;
var
  s: string;
  DataSeries: TFastLineSeries;
begin
  s := InputBox('Data normalization', 'Coefficient', '');
  if s <> '' then
  begin
    DataSeries := FGetActiveDataSeries;
    Normalize(StrToFloat(s), DataSeries);
    if Assigned(FOnSaveActiveData) then
      FOnSaveActiveData(Self);
  end;
end;

procedure TfrmChartInfo.NormalizeDataAuto;
var
  ModelSeries, DataSeries: TFastLineSeries;
begin
  ModelSeries := FGetActiveModelSeries;
  DataSeries := FGetActiveDataSeries;
  NormalizeAuto(ModelSeries, DataSeries);
  if Assigned(FOnSaveActiveData) then
    FOnSaveActiveData(Self);
end;

procedure TfrmChartInfo.SmoothData;
var
  Data: TDataArray;
  DataSeries: TFastLineSeries;
begin
  DataSeries := FGetActiveDataSeries;
  Data := SeriesToData(DataSeries);
  Data := MovAvg(Data, 5);
  DataToSeries(Data, DataSeries);
  if Assigned(FOnSaveActiveData) then
    FOnSaveActiveData(Self);
end;

{ Legend panel }

procedure TfrmChartInfo.ClearLegend;
var
  I: Integer;
begin
  for I := High(FLegendControls) downto 0 do
    FLegendControls[I].Free;
  SetLength(FLegendControls, 0);
  pnlLegend.Visible := False;
end;

procedure TfrmChartInfo.RefreshLegend(const Items: TArray<TLegendEntry>);
const
  MAX_LEGEND_HEIGHT = 300;
var
  I, Y, Len, TotalH, MaxH, RowH, HeaderH: Integer;
  Lbl: TLabel;
  Row: TPanel;
  Shp: TShape;
  CB: TCheckBox;
  LastGroup: TProjectGroupType;

  procedure AddControl(C: TControl);
  begin
    Len := Length(FLegendControls);
    SetLength(FLegendControls, Len + 1);
    FLegendControls[Len] := C;
  end;

begin
  ClearLegend;
  if Length(Items) = 0 then
  begin
    pnlLegend.Visible := False;
    Exit;
  end;

  // Rows are built at runtime, so VCL does not scale them the way it scales
  // design-time controls - but they do inherit the already-scaled parent font.
  // Every layout constant below is therefore a 96 DPI value run through
  // ScaleValue, otherwise the captions get clipped on HiDPI displays.
  RowH := ScaleValue(22);
  HeaderH := ScaleValue(18);

  Y := ScaleValue(4);
  LastGroup := gtData; // force first header

  for I := 0 to High(Items) do
  begin
    // Group header
    if (I = 0) or (Items[I].Group <> LastGroup) then
    begin
      Lbl := TLabel.Create(sbLegend);
      Lbl.Parent := sbLegend;
      Lbl.Left := ScaleValue(4);
      Lbl.Top := Y;
      Lbl.Font.Style := [fsBold];
      Lbl.Font.Size := 8;
      if Items[I].Group = gtModel then
        Lbl.Caption := 'Models'
      else
        Lbl.Caption := 'Data';
      AddControl(Lbl);
      // AutoSize'd label may still outgrow the nominal slot at odd scalings
      Inc(Y, Max(HeaderH, Lbl.Height + ScaleValue(2)));
      LastGroup := Items[I].Group;
    end;

    // Row panel
    Row := TPanel.Create(sbLegend);
    Row.Parent := sbLegend;
    Row.BevelOuter := bvNone;
    Row.Left := 0;
    Row.Top := Y;
    Row.Width := sbLegend.ClientWidth;
    Row.Height := RowH;
    Row.Anchors := [akLeft, akTop, akRight];
    Row.Color := clWhite;
    AddControl(Row);

    // Color swatch
    Shp := TShape.Create(Row);
    Shp.Parent := Row;
    Shp.Left := ScaleValue(4);
    Shp.Top := ScaleValue(3);
    Shp.Width := ScaleValue(16);
    Shp.Height := ScaleValue(16);
    Shp.Brush.Color := Items[I].Color;
    Shp.Pen.Color := Items[I].Color;

    // Checkbox
    CB := TCheckBox.Create(Row);
    CB.Parent := Row;
    CB.Left := ScaleValue(24);
    CB.Top := ScaleValue(2);
    CB.Width := Row.Width - ScaleValue(28);
    CB.Height := RowH - ScaleValue(4);
    CB.Caption := Items[I].Title;
    CB.Checked := Items[I].Visible;
    if Items[I].Linked then
      CB.Font.Style := [fsUnderline];
    CB.Tag := NativeInt(Items[I].Series);
    CB.OnClick := LegendCheckBoxClick;

    Inc(Y, RowH);
  end;

  // Auto-size panel height to content, capped at max
  TotalH := Y + ScaleValue(6); // 4px top padding + 2px bottom
  MaxH := ScaleValue(MAX_LEGEND_HEIGHT);
  if TotalH > MaxH then
    TotalH := MaxH;
  pnlLegend.Height := TotalH;

  // Position at 2% from top-right corner of chart
  pnlLegend.Left := Chart.ClientWidth - pnlLegend.Width - Chart.ClientWidth * 2 div 100;
  pnlLegend.Top := Chart.ClientHeight * 4 div 100;
  pnlLegend.Visible := True;
end;

procedure TfrmChartInfo.LegendCheckBoxClick(Sender: TObject);
var
  CB: TCheckBox;
  S: TChartSeries;
begin
  CB := Sender as TCheckBox;
  S := TChartSeries(CB.Tag);
  S.Active := CB.Checked;
  S.Visible := CB.Checked;
  if Assigned(FOnLegendCheckBoxClick) then
    FOnLegendCheckBoxClick(Self, S);
end;

{ Data operations }

procedure TfrmChartInfo.TrimData;
var
  t1, t2: single;
  iFirst, iLast, LastIndex: integer;
  DataSeries: TFastLineSeries;

  // First point with X >= val, or Count when every point is below val.
  function FirstAtOrAbove(const val: single): integer;
  var
    i: integer;
  begin
    Result := DataSeries.XValues.Count;
    for i := 0 to DataSeries.XValues.Count - 1 do
      if DataSeries.XValues[i] >= val then
        Exit(i);
  end;

  // Last point with X <= val, or -1 when every point is above val.
  function LastAtOrBelow(const val: single): integer;
  var
    i: integer;
  begin
    Result := -1;
    for i := DataSeries.XValues.Count - 1 downto 0 do
      if DataSeries.XValues[i] <= val then
        Exit(i);
  end;

begin
  DataSeries := FGetActiveDataSeries;
  if not Assigned(DataSeries) or (DataSeries.XValues.Count = 0) then
    Exit;

  FCalcSettings.GetAxisRange(t1, t2);

  iFirst := FirstAtOrAbove(t1);
  iLast := LastAtOrBelow(t2);
  // No point falls inside [t1, t2] - leave the data alone rather than wipe it.
  if iFirst > iLast then
    Exit;

  LastIndex := DataSeries.XValues.Count - 1;

  DataSeries.BeginUpdate;
  try
    // Trim the right tail first so that iFirst/iLast stay valid.
    if iLast < LastIndex then
      DataSeries.Delete(iLast + 1, LastIndex - iLast);
    if iFirst > 0 then
      DataSeries.Delete(0, iFirst);
  finally
    DataSeries.EndUpdate;
  end;

  if Assigned(FOnSaveActiveData) then
    FOnSaveActiveData(Self);
end;

end.
