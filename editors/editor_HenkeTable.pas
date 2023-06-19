unit editor_HenkeTable;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, unit_helpers, unit_settings,
  Vcl.StdCtrls, Vcl.Mask, RzEdit, RzBtnEdt, RzPanel, Vcl.ExtCtrls, Vcl.Grids,
  RzGrids, JvExMask, JvToolEdit, JvBaseEdits, math_globals, RzButton,
  VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs,
  VCLTee.Chart;

type
  TedtrHenkeTable = class(TForm)
    rzpnl1: TRzPanel;
    rzstsbr1: TRzStatusBar;
    rzpnl2: TRzPanel;
    edMaterial: TRzButtonEdit;
    Label1: TLabel;
    Label7: TLabel;
    Label6: TLabel;
    edRo: TJvCalcEdit;
    edN: TJvCalcEdit;
    FGrid: TRzStringGrid;
    btnSave: TRzBitBtn;
    Chart: TChart;
    SeriesF1: TLineSeries;
    SeriesF2: TLineSeries;
    procedure edMaterialButtonClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
    procedure FGridSetEditText(Sender: TObject; ACol, ARow: Integer;
      const Value: string);
  private
    { Private declarations }
    FTable: THenkeTable;
    FNa, FRho: single;
  public
    { Public declarations }
  end;

var
  edtrHenkeTable: TedtrHenkeTable;

implementation

uses
  frm_MaterialSelector;

{$R *.dfm}

procedure TedtrHenkeTable.btnSaveClick(Sender: TObject);
begin
  WriteHenkeTable(edMaterial.Text, edN.Value, edRo.Value, FTable);
end;

procedure TedtrHenkeTable.edMaterialButtonClick(Sender: TObject);
var
  S: string;
  i, Size: Integer;
begin
  frmMaterialSelector.SelectMaterial(S);
  edMaterial.Text := S;

  SetLength(FTable, 0);
  ReadHenkeTable(S, FNa, FRho, FTable);
  edN.Value := FNa;
  edRo.Value := FRho;

  Size := Length(FTable);
  FGrid.RowCount := Size + 1;

  SeriesF1.Clear;
  SeriesF2.Clear;

  for I := 0 to High(FTable) do
  begin
    FGrid.Cells[0, i + 1] := FloatToStrF(FTable[i].e, ffFixed, 6, 2);

    FGrid.Cells[1, i + 1] := FloatToStrF(H / FTable[i].e, ffFixed, 5, 1);

    if FTable[i].f1 <> -9999 then
      FGrid.Cells[2, i + 1] := FloatToStrF(FTable[i].f1, ffGeneral, 5, 2)
    else
      FGrid.Cells[2, i + 1] := 'N/A';

    FGrid.Cells[3, i + 1] := FloatToStrF(FTable[i].f2, ffGeneral, 5, 2);

    if FTable[i].f1 <> -9999 then
       SeriesF1.AddXY(H / FTable[i].e, FTable[i].f1);
    SeriesF2.AddXY(H / FTable[i].e, FTable[i].f2);
  end;

end;

procedure TedtrHenkeTable.FGridSetEditText(Sender: TObject; ACol, ARow: Integer;
  const Value: string);
var
  Val: single;
begin
  if TryStrToFloat(FGrid.Cells[ACol, ARow], Val) then
  begin
    case ACol of
      2: FTable[ARow - 1].f1 := Val;
      3: FTable[ARow - 1].f2 := Val;
    end;
  end;
end;


procedure TedtrHenkeTable.FormCreate(Sender: TObject);
begin
  FGrid.Cells[0, 0] := 'E (eV)';
  FGrid.Cells[1, 0] := 'λ (Å)';
  FGrid.Cells[2, 0] := 'f1';
  FGrid.Cells[3, 0] := 'f2';
end;

end.
