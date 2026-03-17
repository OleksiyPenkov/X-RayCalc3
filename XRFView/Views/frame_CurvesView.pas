unit frame_CurvesView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.CheckLst,
  unit_xrfx_package;

type
  TframeCurvesView = class(TFrame)
    chrtCurves: TChart;
    pnlLegend: TPanel;
    clbElements: TCheckListBox;
    procedure clbElementsClickCheck(Sender: TObject);
  public
    procedure LoadCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string = '');
    procedure AddCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeCurvesView.LoadCurves(const Curves: TArray<TXRFXCurveData>;
  const FileLabel: string);
begin
  Clear;
  AddCurves(Curves, FileLabel);
end;

procedure TframeCurvesView.AddCurves(const Curves: TArray<TXRFXCurveData>;
  const FileLabel: string);
var
  i, j: Integer;
  Series: TLineSeries;
  Title: string;
begin
  for i := 0 to High(Curves) do
  begin
    Series := TLineSeries.Create(chrtCurves);
    if FileLabel <> '' then
      Title := FileLabel + ' / ' + Curves[i].Element
    else
      Title := Curves[i].Element;
    Series.Title := Title;

    for j := 0 to High(Curves[i].Theta) do
      Series.AddXY(Curves[i].Theta[j], Curves[i].Refl[j]);

    chrtCurves.AddSeries(Series);
    clbElements.Items.Add(Title);
    clbElements.Checked[clbElements.Count - 1] := True;
  end;

  chrtCurves.LeftAxis.Logarithmic := True;
  chrtCurves.BottomAxis.Title.Caption := 'Theta (degrees)';
  chrtCurves.LeftAxis.Title.Caption := 'Reflectivity';
end;

procedure TframeCurvesView.Clear;
begin
  chrtCurves.FreeAllSeries;
  clbElements.Clear;
end;

procedure TframeCurvesView.clbElementsClickCheck(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbElements.Count - 1 do
    if i < chrtCurves.SeriesCount then
      chrtCurves.Series[i].Active := clbElements.Checked[i];
end;

end.
