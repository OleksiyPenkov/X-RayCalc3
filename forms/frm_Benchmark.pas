(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_Benchmark;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, Vcl.Grids, Vcl.StdCtrls,
  Vcl.Buttons, RzPanel, RzGrids, unit_XRCGrid;

const
  WM_STR_BASE = WM_APP + $0900;

  WM_BENCH_CANCEL = WM_STR_BASE + 0;


type
  TfrmBenchmark = class(TForm)
    RzPanel1: TRzPanel;
    btnCancel: TBitBtn;
    Grid: TXRCGrid;
    procedure btnCancelClick(Sender: TObject);
  private
    FLine: Integer;
    FFileName: string;
    FOnProgress: Boolean;
    { Private declarations }

  procedure SendCancelMessage;
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

procedure TfrmBenchmark.btnCancelClick(Sender: TObject);
begin
  if FOnProgress then SendCancelMessage;
  Close;
end;

procedure TfrmBenchmark.CalcStats;
begin
  if Full then
  begin
    Grid.CalcStat;
    btnCancel.Caption := 'Close';
  end
  else
    btnCancel.Caption := 'Abort';

  Grid.SaveToFile(FFileName);
  FOnProgress := not Full;

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

  FOnProgress := True;
  btnCancel.Caption := 'Cancel';
end;

procedure TfrmBenchmark.SendCancelMessage;
begin
  PostMessage(
    Application.MainFormHandle,
    WM_BENCH_CANCEL,
    0,
    0
  );
end;

end.
