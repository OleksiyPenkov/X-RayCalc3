unit frame_ProgressView;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.ExtCtrls, Vcl.StdCtrls,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  unit_xrfx_package, xrfview_unit_runner;

type
  TframeProgressView = class(TFrame)
    pnlChart: TPanel;
    chrtProgress: TChart;
    Splitter1: TSplitter;
    MemoLog: TMemo;
  private
    FLiveSeries: TLineSeries;
    FLiveMode: Boolean;
  public
    procedure LoadProgress(const Entries: TArray<TProgressEntry>);
    procedure LoadProgressLog(const LogText: string);
    procedure Clear;
    procedure SetLiveMode;
    procedure SetStaticMode;
    procedure AddIteration(const Data: TRunnerIterationData);
    procedure AppendLog(const Line: string);
  end;

implementation

{$R *.dfm}

procedure TframeProgressView.LoadProgress(const Entries: TArray<TProgressEntry>);
var
  Series: TLineSeries;
  i: Integer;
begin
  Clear;
  FLiveMode := False;
  Series := TLineSeries.Create(chrtProgress);
  Series.Title := 'FoM';

  for i := 0 to High(Entries) do
    Series.AddXY(Entries[i].Iteration, Entries[i].FoM);

  chrtProgress.AddSeries(Series);
  chrtProgress.LeftAxis.Logarithmic := True;
  chrtProgress.BottomAxis.Title.Caption := 'Iteration';
  chrtProgress.LeftAxis.Title.Caption := 'Figure of Merit';
end;

procedure TframeProgressView.LoadProgressLog(const LogText: string);
begin
  MemoLog.Lines.Text := LogText;
end;

procedure TframeProgressView.Clear;
begin
  chrtProgress.FreeAllSeries;
  FLiveSeries := nil;
  MemoLog.Lines.Clear;
end;

procedure TframeProgressView.SetLiveMode;
begin
  Clear;
  FLiveMode := True;
  FLiveSeries := TLineSeries.Create(chrtProgress);
  FLiveSeries.Title := 'FoM';
  chrtProgress.AddSeries(FLiveSeries);
  chrtProgress.LeftAxis.Logarithmic := False;
  chrtProgress.BottomAxis.Title.Caption := 'Iteration';
  chrtProgress.LeftAxis.Title.Caption := 'Figure of Merit';
end;

procedure TframeProgressView.SetStaticMode;
begin
  FLiveMode := False;
  FLiveSeries := nil;
end;

procedure TframeProgressView.AddIteration(const Data: TRunnerIterationData);
begin
  if not FLiveMode or (FLiveSeries = nil) then Exit;
  FLiveSeries.AddXY(Data.Iteration, Data.FoM);
end;

procedure TframeProgressView.AppendLog(const Line: string);
begin
  MemoLog.Lines.Add(Line);
  // Auto-scroll to bottom
  SendMessage(MemoLog.Handle, WM_VSCROLL, SB_BOTTOM, 0);
end;

end.
