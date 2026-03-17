unit frame_ProgressView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  unit_xrfx_package;

type
  TframeProgressView = class(TFrame)
    chrtProgress: TChart;
  public
    procedure LoadProgress(const Entries: TArray<TProgressEntry>);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeProgressView.LoadProgress(const Entries: TArray<TProgressEntry>);
var
  Series: TLineSeries;
  i: Integer;
begin
  Clear;
  Series := TLineSeries.Create(chrtProgress);
  Series.Title := 'FoM';

  for i := 0 to High(Entries) do
    Series.AddXY(Entries[i].Iteration, Entries[i].FoM);

  chrtProgress.AddSeries(Series);
  chrtProgress.LeftAxis.Logarithmic := True;
  chrtProgress.BottomAxis.Title.Caption := 'Iteration';
  chrtProgress.LeftAxis.Title.Caption := 'Figure of Merit';
end;

procedure TframeProgressView.Clear;
begin
  chrtProgress.FreeAllSeries;
end;

end.
