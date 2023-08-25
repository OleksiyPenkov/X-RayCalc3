(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_Benchmark;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls,
  Vcl.Buttons, RzPanel, RzGrids, unit_XRCGrid;

type
  TfrmBenchmark = class(TForm)
    RzPanel1: TRzPanel;
    BitBtn1: TBitBtn;
    Grid: TXRCGrid;
    procedure BitBtn1Click(Sender: TObject);
  private
    FLine: Integer;
    FFileName: string;
    { Private declarations }
  public
    { Public declarations }
    procedure Clear(const N: integer);
    procedure AddValue(const n: integer; Val: string);
    procedure AddFile(const Name: string);

    procedure CalcStats(const Full: Boolean);
    procedure Init(const OutputDir: string);

  end;

var
  frmBenchmark: TfrmBenchmark;

implementation

{$R *.dfm}


procedure TfrmBenchmark.AddFile(const Name: string);
begin
  Grid.RowCount := Grid.RowCount + 1;
  FLine := Grid.RowCount  - 1;
  Grid.Cells[0, FLine] := Name;
  Grid.AutoSizeCol(0);
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
  if Full then Grid.CalcStat;
  Grid.SaveToFile(FFileName);
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

  Grid.EnableStat := True;
end;

procedure TfrmBenchmark.Init;
var
  FileName, Date: string;
begin
  DateTimeToString(Date, 'yymmdd-hh-mm', Now);
  FileName := Format('%s-%s.dat',['benchmark', Date]);

  FFileName := OutputDir + FileName;
end;

end.
