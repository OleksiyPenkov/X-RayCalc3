unit frame_StructureView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Grids,
  RzPanel, RzLabel,
  unit_xrfx_package;

type
  TframeStructureView = class(TFrame)
    grdLayers: TStringGrid;
    pnlSummary: TRzPanel;
    lblPeriod: TRzLabel;
    lblGamma: TRzLabel;
    lblN: TRzLabel;
    lblType: TRzLabel;
  public
    procedure LoadStructure(const Structure: TXRFXStructure;
      const Summary: TXRFXStructureSummary);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeStructureView.LoadStructure(const Structure: TXRFXStructure;
  const Summary: TXRFXStructureSummary);
var
  i, j, Row, TotalRows, TotalLayers: Integer;
begin
  TotalLayers := 0;
  for i := 0 to High(Structure.Stacks) do
    Inc(TotalLayers, Length(Structure.Stacks[i].Layers));
  TotalRows := 1 + Length(Structure.Stacks) + TotalLayers + 1;

  grdLayers.ColCount := 5;
  grdLayers.RowCount := TotalRows;
  grdLayers.FixedRows := 1;

  grdLayers.Cells[0, 0] := '#';
  grdLayers.Cells[1, 0] := 'Material';
  grdLayers.Cells[2, 0] := 'Thickness (A)';
  grdLayers.Cells[3, 0] := 'Roughness (A)';
  grdLayers.Cells[4, 0] := 'Density (g/cm3)';

  Row := 1;
  for i := 0 to High(Structure.Stacks) do
  begin
    grdLayers.Cells[0, Row] := Structure.Stacks[i].StackType;
    grdLayers.Cells[1, Row] := Format('x %d', [Structure.Stacks[i].N]);
    grdLayers.Cells[2, Row] := '';
    grdLayers.Cells[3, Row] := '';
    grdLayers.Cells[4, Row] := '';
    Inc(Row);
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      grdLayers.Cells[0, Row] := IntToStr(j + 1);
      grdLayers.Cells[1, Row] := Structure.Stacks[i].Layers[j].Material;
      grdLayers.Cells[2, Row] := Format('%.2f', [Structure.Stacks[i].Layers[j].Thickness]);
      grdLayers.Cells[3, Row] := Format('%.2f', [Structure.Stacks[i].Layers[j].Roughness]);
      grdLayers.Cells[4, Row] := Format('%.2f', [Structure.Stacks[i].Layers[j].Density]);
      Inc(Row);
    end;
  end;

  grdLayers.Cells[0, Row] := 'Sub';
  grdLayers.Cells[1, Row] := Structure.Substrate.Material;
  grdLayers.Cells[2, Row] := '--';
  grdLayers.Cells[3, Row] := Format('%.2f', [Structure.Substrate.Roughness]);
  grdLayers.Cells[4, Row] := Format('%.2f', [Structure.Substrate.Density]);

  lblType.Caption := 'Type: ' + Summary.StructureType;
  lblPeriod.Caption := Format('d = %.2f A', [Summary.D]);
  lblGamma.Caption := Format('gamma = %.3f', [Summary.Gamma]);
  lblN.Caption := Format('N = %d', [Summary.N]);
end;

procedure TframeStructureView.Clear;
var
  c, r: Integer;
begin
  for c := 0 to grdLayers.ColCount - 1 do
    for r := 0 to grdLayers.RowCount - 1 do
      grdLayers.Cells[c, r] := '';
  lblType.Caption := '';
  lblPeriod.Caption := '';
  lblGamma.Caption := '';
  lblN.Caption := '';
end;

end.
