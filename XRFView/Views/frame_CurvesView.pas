unit frame_CurvesView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.CheckLst,
  unit_xrfx_package;

type
  TframeCurvesView = class(TFrame)
    chrtCurves: TChart;
    pnlLegend: TPanel;
    chkLogScale: TCheckBox;
    chkTotal: TCheckBox;
    clbElements: TCheckListBox;
    procedure clbElementsClickCheck(Sender: TObject);
    procedure chkLogScaleClick(Sender: TObject);
    procedure chkTotalClick(Sender: TObject);
  private
    FTotalSeries: TLineSeries;
    procedure UpdateTotalCurve;
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

  chrtCurves.LeftAxis.Logarithmic := chkLogScale.Checked;
  chrtCurves.BottomAxis.Title.Caption := 'Theta (degrees)';
  chrtCurves.LeftAxis.Title.Caption := 'Reflectivity';

  UpdateTotalCurve;
end;

procedure TframeCurvesView.Clear;
begin
  FTotalSeries := nil;
  chrtCurves.FreeAllSeries;
  clbElements.Clear;
end;

procedure TframeCurvesView.UpdateTotalCurve;
var
  i, j, MaxPts: Integer;
  Sum: Double;
begin
  if FTotalSeries <> nil then
  begin
    chrtCurves.RemoveSeries(FTotalSeries);
    FreeAndNil(FTotalSeries);
  end;

  if not chkTotal.Checked then Exit;
  if chrtCurves.SeriesCount = 0 then Exit;

  MaxPts := chrtCurves.Series[0].Count;
  if MaxPts = 0 then Exit;

  FTotalSeries := TLineSeries.Create(chrtCurves);
  FTotalSeries.Title := 'Total';
  FTotalSeries.LinePen.Width := 2;
  FTotalSeries.LinePen.Color := clBlack;

  for j := 0 to MaxPts - 1 do
  begin
    Sum := 0;
    for i := 0 to chrtCurves.SeriesCount - 1 do
    begin
      if (chrtCurves.Series[i] <> FTotalSeries) and
         (j < chrtCurves.Series[i].Count) then
        Sum := Sum + chrtCurves.Series[i].YValue[j];
    end;
    FTotalSeries.AddXY(chrtCurves.Series[0].XValue[j], Sum);
  end;

  chrtCurves.AddSeries(FTotalSeries);
end;

procedure TframeCurvesView.clbElementsClickCheck(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbElements.Count - 1 do
    if i < chrtCurves.SeriesCount then
      chrtCurves.Series[i].Active := clbElements.Checked[i];
end;

procedure TframeCurvesView.chkLogScaleClick(Sender: TObject);
begin
  chrtCurves.LeftAxis.Logarithmic := chkLogScale.Checked;
end;

procedure TframeCurvesView.chkTotalClick(Sender: TObject);
begin
  UpdateTotalCurve;
end;

end.
