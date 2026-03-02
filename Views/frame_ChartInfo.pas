unit frame_ChartInfo;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IniFiles,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls,
  RzStatus, RzButton, RzCmboBx, RzPanel,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.TeCanvas,
  VCLTee.Chart, VCLTee.Series;

type
  TGetSeriesEvent = function: TChartSeries of object;

  TfrmChartInfo = class(TFrame)
    Chart: TChart;
    btnStop: TRzBitBtn;
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
    FOnScaleToggle: TNotifyEvent;
    FOnMinLimitChange: TNotifyEvent;
    FGetActiveSeries: TGetSeriesEvent;
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

    property MinLimit: Single read GetMinLimit;
    property MinLimitText: string read GetMinLimitText write SetMinLimitText;

    procedure LoadFromINI(INF: TMemIniFile);
    procedure SaveToINI(INF: TMemIniFile);

    property OnScaleToggle: TNotifyEvent read FOnScaleToggle write FOnScaleToggle;
    property OnMinLimitChange: TNotifyEvent read FOnMinLimitChange write FOnMinLimitChange;
    property OnGetActiveSeries: TGetSeriesEvent read FGetActiveSeries write FGetActiveSeries;
  end;

implementation

{$R *.dfm}

{ TfrmChartInfo }

procedure TfrmChartInfo.btnChartScaleClick(Sender: TObject);
begin
  if Assigned(FOnScaleToggle) then
    FOnScaleToggle(Self);
end;

procedure TfrmChartInfo.cbMinLimitChange(Sender: TObject);
begin
  if Assigned(FOnMinLimitChange) then
    FOnMinLimitChange(Self);
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
  Series: TChartSeries;
  xv, yv: Single;
  R: TRect;
begin
  if not Assigned(FGetActiveSeries) then Exit;
  Series := FGetActiveSeries;
  if Series = nil then Exit;

  xv := Series.XScreenToValue(X);
  yv := Series.YScreenToValue(Y);
  SetCursorPos(xv, yv);

  R := Chart.Legend.RectLegend;

  if (X > R.Left) and (X < R.Right) and (Y > R.Top) and (Y < R.Bottom) then
    Chart.Cursor := crArrow
  else
    Chart.Cursor := crCross;
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
end;

procedure TfrmChartInfo.ChartZoom(Sender: TObject);
var
  Series: TChartSeries;
begin
  if not Assigned(FGetActiveSeries) then Exit;
  Series := FGetActiveSeries;
  if Series = nil then Exit;

  SetPeakInfo(Series, Chart.BottomAxis.Minimum, Chart.BottomAxis.Maximum);
end;

end.
