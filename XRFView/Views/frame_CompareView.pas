unit frame_CompareView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Grids,
  unit_xrfx_package;

type
  TframeCompareView = class(TFrame)
    grdCompare: TStringGrid;
  public
    procedure LoadComparison(const Manifests: TArray<TXRFXManifest>;
      const FileNames: TArray<string>);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeCompareView.LoadComparison(
  const Manifests: TArray<TXRFXManifest>;
  const FileNames: TArray<string>);
var
  Col, Row, j: Integer;
  BaseRows: Integer;
begin
  if Length(Manifests) = 0 then Exit;

  BaseRows := 6;
  grdCompare.ColCount := Length(Manifests) + 1;
  grdCompare.RowCount := BaseRows + Length(Manifests[0].PerElement) * 2 + 1;
  grdCompare.FixedCols := 1;
  grdCompare.FixedRows := 1;

  grdCompare.Cells[0, 0] := 'Parameter';
  for Col := 0 to High(Manifests) do
    grdCompare.Cells[Col + 1, 0] := ExtractFileName(FileNames[Col]);

  grdCompare.Cells[0, 1] := 'FoM';
  grdCompare.Cells[0, 2] := 'd (A)';
  grdCompare.Cells[0, 3] := 'gamma';
  grdCompare.Cells[0, 4] := 'N';
  grdCompare.Cells[0, 5] := 'sigma (A)';
  grdCompare.Cells[0, 6] := 'Substrate';

  Row := 7;
  for j := 0 to High(Manifests[0].PerElement) do
  begin
    grdCompare.Cells[0, Row] := Manifests[0].PerElement[j].Line + ' peak R';
    Inc(Row);
    grdCompare.Cells[0, Row] := Manifests[0].PerElement[j].Line + ' FWHM';
    Inc(Row);
  end;

  for Col := 0 to High(Manifests) do
  begin
    grdCompare.Cells[Col + 1, 1] := Format('%.6f', [Manifests[Col].FoM]);
    grdCompare.Cells[Col + 1, 2] := Format('%.2f', [Manifests[Col].Structure.D]);
    grdCompare.Cells[Col + 1, 3] := Format('%.3f', [Manifests[Col].Structure.Gamma]);
    grdCompare.Cells[Col + 1, 4] := IntToStr(Manifests[Col].Structure.N);
    grdCompare.Cells[Col + 1, 5] := Format('%.2f', [Manifests[Col].Structure.Sigma]);
    grdCompare.Cells[Col + 1, 6] := Manifests[Col].Substrate;

    Row := 7;
    for j := 0 to High(Manifests[Col].PerElement) do
    begin
      grdCompare.Cells[Col + 1, Row] := Format('%.4f', [Manifests[Col].PerElement[j].PeakR]);
      Inc(Row);
      grdCompare.Cells[Col + 1, Row] := Format('%.3f', [Manifests[Col].PerElement[j].FWHM]);
      Inc(Row);
    end;
  end;
end;

procedure TframeCompareView.Clear;
var
  c, r: Integer;
begin
  for c := 0 to grdCompare.ColCount - 1 do
    for r := 0 to grdCompare.RowCount - 1 do
      grdCompare.Cells[c, r] := '';
end;

end.
