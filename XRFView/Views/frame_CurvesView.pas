unit frame_CurvesView;

interface

uses
  Winapi.Windows,
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.CheckLst, Vcl.Grids,
  unit_xrfx_package;

type
  TframeCurvesView = class(TFrame)
    chrtCurves: TChart;
    pnlLegend: TPanel;
    chkLogScale: TCheckBox;
    chkTotal: TCheckBox;
    clbElements: TCheckListBox;
    pnlStructure: TPanel;
    lblStructureHeader: TLabel;
    grdStructure: TStringGrid;
    procedure clbElementsClickCheck(Sender: TObject);
    procedure chkLogScaleClick(Sender: TObject);
    procedure chkTotalClick(Sender: TObject);
    procedure grdStructureDrawCell(Sender: TObject; ACol, ARow: Integer;
      Rect: TRect; State: TGridDrawState);
  private
    FTotalSeries: TLineSeries;
    FSubstrateRow: Integer;
    procedure UpdateTotalCurve;
    procedure PositionStructurePanel;
  public
    procedure LoadCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string = '');
    procedure AddCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string);
    procedure LoadStructure(const Structure: TXRFXStructure;
      const Summary: TXRFXStructureSummary);
    procedure Clear;
  end;

implementation

{$R *.dfm}

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
    if FileLabel <> '' then
      Title := FileLabel + ' / ' + Curves[i].Element
    else
      Title := Curves[i].Element;
    Series.Title := Title;

    for j := 0 to High(Curves[i].Theta) do
      Series.AddXY(Curves[i].Theta[j], Curves[i].Refl[j]);

    chrtCurves.AddSeries(Series);
    clbElements.Items.Add(Title);
    clbElements.Checked[clbElements.Count - 1] := True;
  end;

  chrtCurves.LeftAxis.Logarithmic := chkLogScale.Checked;
  chrtCurves.BottomAxis.Title.Caption := 'Theta (degrees)';
  chrtCurves.LeftAxis.Title.Caption := 'Reflectivity';

  UpdateTotalCurve;
end;

procedure TframeCurvesView.Clear;
begin
  FTotalSeries := nil;
  chrtCurves.FreeAllSeries;
  clbElements.Clear;
  pnlStructure.Visible := False;
end;

procedure TframeCurvesView.UpdateTotalCurve;
var
  i, j, MaxPts: Integer;
  Sum: Double;
begin
  if FTotalSeries <> nil then
  begin
    chrtCurves.RemoveSeries(FTotalSeries);
    FreeAndNil(FTotalSeries);
  end;

  if not chkTotal.Checked then Exit;
  if chrtCurves.SeriesCount = 0 then Exit;

  MaxPts := chrtCurves.Series[0].Count;
  if MaxPts = 0 then Exit;

  FTotalSeries := TLineSeries.Create(chrtCurves);
  FTotalSeries.Title := 'Total';
  FTotalSeries.LinePen.Width := 2;
  FTotalSeries.LinePen.Color := clBlack;

  for j := 0 to MaxPts - 1 do
  begin
    Sum := 0;
    for i := 0 to chrtCurves.SeriesCount - 1 do
    begin
      if (chrtCurves.Series[i] <> FTotalSeries) and
         (j < chrtCurves.Series[i].Count) then
        Sum := Sum + chrtCurves.Series[i].YValue[j];
    end;
    FTotalSeries.AddXY(chrtCurves.Series[0].XValue[j], Sum);
  end;

  chrtCurves.AddSeries(FTotalSeries);
end;

procedure TframeCurvesView.clbElementsClickCheck(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbElements.Count - 1 do
    if i < chrtCurves.SeriesCount then
      chrtCurves.Series[i].Active := clbElements.Checked[i];
end;

procedure TframeCurvesView.chkLogScaleClick(Sender: TObject);
begin
  chrtCurves.LeftAxis.Logarithmic := chkLogScale.Checked;
end;

procedure TframeCurvesView.chkTotalClick(Sender: TObject);
begin
  UpdateTotalCurve;
end;

{ Structure overlay }

procedure TframeCurvesView.LoadStructure(const Structure: TXRFXStructure;
  const Summary: TXRFXStructureSummary);
var
  i, Row, TotalRows, W: Integer;
  HeaderText: string;
begin
  // Header: "d=XX  gamma=XX  N=XX"
  HeaderText := Format('d=%.1f  '#947'=%.3f  N=%d',
    [Summary.D, Summary.Gamma, Summary.N]);
  lblStructureHeader.Caption := HeaderText;

  // Rows: 1 fixed header + layers + substrate
  TotalRows := 1 + Length(Structure.Layers) + 1;
  grdStructure.RowCount := TotalRows;
  grdStructure.ColCount := 4;
  FSubstrateRow := TotalRows - 1;

  // Column widths
  W := grdStructure.ClientWidth;
  if W < 100 then W := 254;
  grdStructure.ColWidths[0] := W * 28 div 100;
  grdStructure.ColWidths[1] := W * 24 div 100;
  grdStructure.ColWidths[2] := W * 24 div 100;
  grdStructure.ColWidths[3] := W - grdStructure.ColWidths[0]
    - grdStructure.ColWidths[1] - grdStructure.ColWidths[2] - 4;

  // Header row
  grdStructure.Cells[0, 0] := 'Material';
  grdStructure.Cells[1, 0] := 'H (' + #197 + ')';
  grdStructure.Cells[2, 0] := #963 + ' (' + #197 + ')';
  grdStructure.Cells[3, 0] := #961 + ' (g/cm' + #179 + ')';

  // Layers
  for i := 0 to High(Structure.Layers) do
  begin
    Row := i + 1;
    grdStructure.Cells[0, Row] := Structure.Layers[i].Material;
    grdStructure.Cells[1, Row] := Format('%.2f', [Structure.Layers[i].Thickness]);
    grdStructure.Cells[2, Row] := Format('%.2f', [Structure.Layers[i].Roughness]);
    grdStructure.Cells[3, Row] := Format('%.2f', [Structure.Layers[i].Density]);
  end;

  // Substrate
  Row := FSubstrateRow;
  grdStructure.Cells[0, Row] := Structure.Substrate.Material + ' (sub)';
  grdStructure.Cells[1, Row] := #8212;
  grdStructure.Cells[2, Row] := Format('%.2f', [Structure.Substrate.Roughness]);
  grdStructure.Cells[3, Row] := Format('%.2f', [Structure.Substrate.Density]);

  // Size panel to fit
  pnlStructure.Height := lblStructureHeader.Height + lblStructureHeader.Margins.Top
    + lblStructureHeader.Margins.Bottom + grdStructure.Margins.Top
    + grdStructure.Margins.Bottom
    + TotalRows * (grdStructure.DefaultRowHeight + 1) + 2;

  PositionStructurePanel;
  pnlStructure.Visible := True;
  pnlStructure.BringToFront;
end;

procedure TframeCurvesView.PositionStructurePanel;
begin
  pnlStructure.Parent := chrtCurves;
  pnlStructure.Left := chrtCurves.ClientWidth - pnlStructure.Width - 10;
  pnlStructure.Top := 10;
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

end.
