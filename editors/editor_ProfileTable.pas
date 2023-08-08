(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_ProfileTable;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VclTee.TeeGDIPlus, RzButton,
  VCLTee.TeEngine, VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart, Vcl.Grids,
  RzGrids, Vcl.StdCtrls, Vcl.ExtCtrls, RzPanel, unit_types, unit_XRCStructure,
  RzTabs, unit_XRCGrid;

type

  TSeriesList = array of TLineSeries;

  TedtrProfileTable = class(TForm)
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    RzPanel1: TRzPanel;
    Pages: TRzPageControl;
    tsThickness: TRzTabSheet;
    chrtThickness: TChart;
    tsRoughness: TRzTabSheet;
    tsDensity: TRzTabSheet;
    chrtRougness: TChart;
    chrtDensity: TChart;
    grdThickness: TXRCGrid;
    grdDensity: TXRCGrid;
    grdRoughness: TXRCGrid;
    btnSave: TRzBitBtn;
    btnCopy: TRzBitBtn;
    dlgSaveResult: TSaveDialog;
    procedure FormShow(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnSaveClick(Sender: TObject);
  private
    FStructure: TXRCStructure;
    FData: PProjectData;

    Charts: array [1..3] of TChart;
    Grids : array [1..3] of TXRCGrid;
    Series: array [1..3] of TSeriesList;

    LastCol: array [1..3] of Integer;

    { Private declarations }
    procedure PlotProfiles;
    procedure PlotProfile(const Data: TFloatArray; ChartIndex: integer);
    procedure AddCurve(const Title: string; ChartIndex: integer);
    procedure PrepareGrids;
    procedure FillGrids(const Data: TFloatArray; GridIndex: integer);
    procedure ClearCharts;

  public
    { Public declarations }
    property Data: PProjectData read FData write FData;
    property Structure: TXRCStructure write FStructure;
  end;

var
  edtrProfileTable: TedtrProfileTable;

implementation

uses
  Vcl.Clipbrd;

{$R *.dfm}

procedure TedtrProfileTable.FormCreate(Sender: TObject);
begin
  Charts[1] := chrtThickness;
  Charts[2] := chrtRougness;
  Charts[3] := chrtDensity;

  Grids[1] := grdThickness;
  Grids[2] := grdRoughness;
  Grids[3] := grdDensity;
end;

procedure TedtrProfileTable.PrepareGrids;
begin
  Grids[1].ColCount := 2;
  Grids[1].RowCount := 1;

  Grids[2].ColCount := 2;
  Grids[2].RowCount := 1;


  Grids[3].ColCount := 2;
  Grids[3].RowCount := 1;

  Grids[1].Cells[0, 0] := 'N';
  Grids[1].Cells[0, 0] := 'N';

  Grids[2].Cells[0, 0] := 'N';

  Grids[3].Cells[0, 0] := 'N';

  LastCol[1] := 1;
  LastCol[2] := 1;
  LastCol[3] := 1;
end;

procedure TedtrProfileTable.FormShow(Sender: TObject);
begin
  ClearCharts;
  PrepareGrids;
  PlotProfiles;
end;


procedure TedtrProfileTable.FillGrids(const Data: TFloatArray; GridIndex: integer);
var
  n: Integer;
begin
  Grids[GridIndex].ColCount := LastCol[GridIndex] + 1;
  Grids[GridIndex].RowCount := Length(Data) + 1;
  Grids[GridIndex].Cells[LastCol[GridIndex], 0] := Series[GridIndex][High(Series[GridIndex])].Title;

  for n := 0 to High(Data) do
  begin
    Grids[GridIndex].Cells[0, n + 1] := IntToStr(n + 1);
    Grids[GridIndex].Cells[LastCol[GridIndex], n + 1] := Format('%*.*f',[5, 4, Data[n]])
  end;
  Inc(LastCol[GridIndex]);
  Grids[GridIndex].Update;
end;


procedure TedtrProfileTable.PlotProfile(const Data: TFloatArray; ChartIndex: integer);
var
  n, SeriesIndex: Integer;
begin
  SeriesIndex := High(Series[ChartIndex]);
  Series[ChartIndex][SeriesIndex].Clear;

  for n := 0 to High(Data) do
    Series[ChartIndex][SeriesIndex].AddXY(n + 1, Data[n]);
end;

procedure TedtrProfileTable.btnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := Grids[Pages.ActivePageIndex + 1].Text;
end;

procedure TedtrProfileTable.btnSaveClick(Sender: TObject);
begin
  if dlgSaveResult.Execute then
    Grids[Pages.ActivePageIndex + 1].SaveToFile(dlgSaveResult.FileName);
end;

procedure TedtrProfileTable.ClearCharts;
begin
  Charts[1].SeriesList.Clear;
  SetLength(Series[1], 0);

  Charts[2].SeriesList.Clear;
  SetLength(Series[2], 0);

  Charts[3].SeriesList.Clear;
  SetLength(Series[3], 0);
end;

procedure TedtrProfileTable.PlotProfiles;
var
  i, j, p: Integer;
begin


  for I := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
        for p := 1 to 3 do
          if (FStructure.Stacks[i].N > 1) and not FStructure.Stacks[i].Layers[j].Data.P[p].Paired then
          begin
            AddCurve(FStructure.Stacks[i].Layers[j].Data.Material, p);
            PlotProfile(FStructure.Stacks[i].Layers[j].Data.PP[p], p);
            FillGrids(FStructure.Stacks[i].Layers[j].Data.PP[p], p);
          end;

  Charts[1].Update;
  Charts[2].Update;
  Charts[3].Update;
end;

procedure TedtrProfileTable.AddCurve;
var
  Count: integer;
begin
  Count := Length(Series[ChartIndex]);
  SetLength(Series[ChartIndex], Count + 1);
  Series[ChartIndex][Count] := TLineSeries.Create(Charts[ChartIndex]);
  Series[ChartIndex][Count].ParentChart := Charts[ChartIndex];
  Series[ChartIndex][Count].Title := Title;
  Series[ChartIndex][Count] .LinePen.Width := 3;
  Series[ChartIndex][Count] .Stairs := True;
  Series[ChartIndex][Count] .Pointer.Visible := True;
  Series[ChartIndex][Count] .Pointer.Size := 4;
end;

end.
