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
    pnl1: TPanel;
    procedure FormCreate(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
  private
    FCanClose: TObject;
    { Private declarations }
  public
    { Public declarations }
    procedure Clear;
    procedure AddValue(const n: integer; Val: string);
    procedure CalcStats;
  end;

var
  frmBenchmark: TfrmBenchmark;

implementation

{$R *.dfm}

procedure TfrmBenchmark.AddValue(const n: integer; Val: string);
begin
  Grid.Cells[0,n] := IntToStr(n);
  Grid.Cells[1,n] := Val;
end;

procedure TfrmBenchmark.BitBtn1Click(Sender: TObject);
begin
  Close;
end;

procedure TfrmBenchmark.CalcStats;
begin

end;

procedure TfrmBenchmark.Clear;
begin

end;

procedure TfrmBenchmark.FormCreate(Sender: TObject);
begin
  Grid.Cells[0,0] := 'n';
  Grid.Cells[1,0] := 'ChiSqr';
end;

end.
