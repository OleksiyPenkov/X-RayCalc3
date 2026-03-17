unit frame_StructureView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Grids, Vcl.StdCtrls, Vcl.ExtCtrls,
  unit_xrfx_package;

type
  TframeStructureView = class(TFrame)
    grdLayers: TStringGrid;
    pnlSummary: TPanel;
    lblPeriod: TLabel;
    lblGamma: TLabel;
    lblN: TLabel;
    lblType: TLabel;
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
  i, Row: Integer;
begin
  grdLayers.ColCount := 5;
  grdLayers.RowCount := Length(Structure.Layers) + 2;
  grdLayers.FixedRows := 1;

  grdLayers.Cells[0, 0] := '#';
  grdLayers.Cells[1, 0] := 'Material';
  grdLayers.Cells[2, 0] := 'Thickness (A)';
  grdLayers.Cells[3, 0] := 'Roughness (A)';
  grdLayers.Cells[4, 0] := 'Density (g/cm3)';

  for i := 0 to High(Structure.Layers) do
  begin
    Row := i + 1;
    grdLayers.Cells[0, Row] := IntToStr(i + 1);
    grdLayers.Cells[1, Row] := Structure.Layers[i].Material;
    grdLayers.Cells[2, Row] := Format('%.2f', [Structure.Layers[i].Thickness]);
    grdLayers.Cells[3, Row] := Format('%.2f', [Structure.Layers[i].Roughness]);
    grdLayers.Cells[4, Row] := Format('%.2f', [Structure.Layers[i].Density]);
  end;

  Row := Length(Structure.Layers) + 1;
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
