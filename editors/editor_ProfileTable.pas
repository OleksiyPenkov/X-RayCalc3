unit editor_ProfileTable;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VclTee.TeeGDIPlus, RzButton,
  VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart, Vcl.Grids,
  RzGrids, Vcl.StdCtrls, Vcl.ExtCtrls, RzPanel, unit_types, unit_XRCStructure;

type

  TSeriesList = array of TLineSeries;

  TedtrProfileTable = class(TForm)
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    RzPanel1: TRzPanel;
    Label1: TLabel;
    edTitle: TEdit;
    Grid: TRzStringGrid;
    Chart: TChart;
    Series1: TLineSeries;
    procedure FormShow(Sender: TObject);
  private
    FStructure: TXRCStructure;
    FData: PProjectData;
    FSeriesList: TSeriesList ;

    { Private declarations }
    procedure PlotProfiles;
    procedure PlotProfile(const Data: TFloatArray);
    procedure AddCurve(const Title: string; Index: integer);

  public
    { Public declarations }
    property Data: PProjectData read FData write FData;
    property Structure: TXRCStructure write FStructure;
  end;

var
  edtrProfileTable: TedtrProfileTable;

implementation

{$R *.dfm}

procedure TedtrProfileTable.FormShow(Sender: TObject);
begin
  edTitle.Text := string(FData.Title);
  PlotProfiles;
end;


procedure TedtrProfileTable.PlotProfile(const Data: TFloatArray);
var
  n, Index: Integer;
begin
  Index := High(FSeriesList);
  FSeriesList[Index].Clear;

  for n := 0 to High(Data) do
    FSeriesList[Index].AddXY(n + 1, Data[n]);
end;

procedure TedtrProfileTable.PlotProfiles;
var
  i, j, p: Integer;
begin
  for I := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
        for p := 1 to 3 do
          if not FStructure.Stacks[i].Layers[j].Data.P[p].Paired then
          begin
            AddCurve(FStructure.Stacks[i].Layers[j].Data.Material, p);
            PlotProfile(FStructure.Stacks[i].Layers[j].Data.PP[p]);
          end;

  Chart.Update;
end;

procedure TedtrProfileTable.AddCurve;
var
  Count: integer;
begin
  Count := Length(FSeriesList);
  SetLength(FSeriesList, Count + 1);
  FSeriesList[Count] := TLineSeries.Create(Chart);
  FSeriesList[Count].ParentChart := Chart;
  FSeriesList[Count].Title := Title;
  FSeriesList[Count] .LinePen.Width := 2;
  FSeriesList[Count] .Stairs := True;
  FSeriesList[Count] .Pointer.Visible := True;
  FSeriesList[Count] .Pointer.Size := 2;
end;

end.
