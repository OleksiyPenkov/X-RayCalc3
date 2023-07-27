unit frm_Benchmark;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls,
  Vcl.Buttons, RzPanel;

type
  TfrmBenchmark = class(TForm)
    RzPanel1: TRzPanel;
    BitBtn1: TBitBtn;
    Grid: TStringGrid;
    procedure BitBtn1Click(Sender: TObject);
  private
    FLine: Integer;
    procedure AutoSizeCol(Grid: TStringGrid; Column: integer);
    procedure StringGrid2File(StringGrid: TStringGrid; FileName: String);
    { Private declarations }
  public
    { Public declarations }
    procedure Clear(const N: integer);
    procedure AddValue(const n: integer; Val: string);
    procedure AddFile(const Name: string);

    procedure CalcStats;
  end;

var
  frmBenchmark: TfrmBenchmark;

implementation

{$R *.dfm}

procedure TfrmBenchmark.StringGrid2File(StringGrid: TStringGrid; FileName: String);
var
  F: TextFile;
  x, y: Integer;
  S: string;
begin
  AssignFile(F, FileName);
  Rewrite(F);
  for y := 0 to StringGrid.RowCount-1 do
  begin
    S := StringGrid.Cells[0, y];
    for x := 1 to StringGrid.ColCount-1 do
      S := S + #9 + StringGrid.Cells[x, y];

    Writeln(F, S);
  end;
  CloseFile(F);
end;


procedure TfrmBenchmark.AutoSizeCol(Grid: TStringGrid;
Column: integer);
var
  i, W, WMax: integer;
begin
  WMax := 0;
  for i := 0 to (Grid.RowCount - 1) do begin
    W := Grid.Canvas.TextWidth(Grid.Cells[Column, i]);
    if W > WMax then
      WMax := W;
  end;
  Grid.ColWidths[Column] := WMax + 10;
end;

procedure TfrmBenchmark.AddFile(const Name: string);
begin
  Grid.RowCount := Grid.RowCount + 1;
  FLine := Grid.RowCount  - 1;
  Grid.Cells[0, FLine] := Name;
  AutoSizeCol(Grid, 0);
end;

procedure TfrmBenchmark.AddValue(const n: integer; Val: string);
begin
  Grid.Cells[n, FLine] := Val;
end;

procedure TfrmBenchmark.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmBenchmark.CalcStats;
begin
  StringGrid2File(Grid, 'benchmark.dat');
end;

procedure TfrmBenchmark.Clear;
var
  i: Integer;
begin
  Grid.RowCount := 0;
  Grid.RowCount := 1;
  Grid.ColCount := N + 1;


  Grid.Cells[0,0] := 'File';

  for I := 1 to N do
    Grid.Cells[i, 0] := 'Run ' + IntToStr(i);
end;

end.
