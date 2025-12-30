unit frame_Chart;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, VCLTee.TeEngine,
  VCLTee.Series, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart;

type

  TSeriesList = array of TLineSeries;

  TfrmChart = class(TFrame)
    Chart: TChart;
  private
    { Private declarations }
    FSeriesList: TSeriesList ;

    procedure AddCurve(var Stream: TStream);
    procedure SeriesFromFile(Series: TLineSeries; var Stream: TStream);
    procedure LoadProjectParams(var Stream: TStream);
  public
    { Public declarations }
    procedure Clear;
    procedure LoadCurves(const FileName: string);
  end;

implementation

uses
  System.Zip,
  System.IniFiles,
  System.Character;

const
  TabSeparator = #9;

procedure SeriesFromText(var MyStringList: TStringList; var Series:TLineSeries);
var
  i, p: integer;
  s1, s2: string;
  x, y: single;
  min: Double;
  Separator: string;

  procedure FixDecimaPoint(var s: string); inline;
  var
    p: Integer;
  begin
    p := pos(',', s);
    if p > 0 then s[p] := '.';
  end;

begin
  Separator := TabSeparator;
  min := 1000;
  Series.Clear;
  for i := 0 to MyStringList.Count - 1 do
  begin
    s2 := MyStringList.Strings[i];
    if s2 = '' then Continue;

    p := Pos(Separator, s2);
    if p = 0 then
    begin
      Separator := ' ';
      p := Pos(Separator, s2);
    end;

    if p = 0 then Continue;

    s1 := Copy(s2, 1, p - 1);
    delete(s2, 1, p);
    if (s1 <> '') and (s2 <> '') and s1[1].IsNumber and s2[1].IsNumber then
    try
      FixDecimaPoint(s1);
      FixDecimaPoint(s2);
      x := StrToFloat(s1);
      y := StrToFloat(s2);
      if (y < min) and (y > 0) then min := y;
      if y = 0 then y := min;
      Series.AddXY(x, y);
    except
      on EConvertError do;
    end;
    end;
end;

{$R *.dfm}

{ TfrmChart }

procedure TfrmChart.AddCurve;
var
  Count: integer;
begin
  Count := Length(FSeriesList);
  SetLength(FSeriesList, Count + 1);
  FSeriesList[Count] := TLineSeries.Create(Chart);
  FSeriesList[Count].ParentChart := Chart;

  FSeriesList[Count].LinePen.Width := 3;
  FSeriesList[Count].Visible := True;
  SeriesFromFile(FSeriesList[Count], Stream);
end;

procedure TfrmChart.Clear;
var
  i: integer;
begin
  for I := 0 to Chart.SeriesList.Count - 1 do
    Chart.SeriesList[i].Clear;
end;

procedure TfrmChart.LoadCurves;
var
  ZipFile: TZipFile;
  DecompressionStream: TStream;
  LocalHeader: TZipHeader;
  FileNames: TArray<String>;
  FN, ext: string;
begin
  ZipFile := TZipFile.Create;
  ZipFile.Open(FileName, zmRead);
  FileNames := ZipFile.FileNames;

  for FN in FileNames do
  begin
    ext := ExtractFileExt(FN);
    if ext = '.dat' then
    begin
      ZipFile.Read(FN, DecompressionStream, LocalHeader);
      AddCurve(DecompressionStream);
    end;
    if FN = 'params.dsc' then
    begin
      ZipFile.Read(FN, DecompressionStream, LocalHeader);
      LoadProjectParams(DecompressionStream);
    end;
  end;
end;

procedure TfrmChart.SeriesFromFile(Series: TLineSeries; var Stream: TStream);
var
  MyStringList: TStringList;
  S: string;
  i: Integer;
begin
  MyStringList := TStringList.Create;
  try
    MyStringList.LoadFromStream(Stream);
    S :=  MyStringList[0];
    if Pos('Sample', S) > 0 then
    begin
      for i := 1 to 21 do
        MyStringList.Delete(0);
    end;
    SeriesFromText(MyStringList, Series);
  finally
    MyStringList.Free;
  end;
end;

procedure TfrmChart.LoadProjectParams(var Stream: TStream);
var
  INF: TMemIniFile;
  MinLimit: string;
begin
  INF := TMemIniFile.Create(Stream);
  try
    MinLimit := INF.ReadString('PARAMS', 'MinLimit', '1E-7');
    Chart.LeftAxis.Logarithmic := INF.ReadBool('STATE', 'LogScale', True);

    Chart.LeftAxis.Maximum := 1;

    if not Chart.LeftAxis.Logarithmic then
    begin
      if Chart.LeftAxis.Maximum > 0.01 then
        Chart.LeftAxis.AxisValuesFormat := '0.000'
      else
        Chart.LeftAxis.AxisValuesFormat := '0x10E-0';
      Chart.LeftAxis.Minimum := 0;
    end
    else
    begin
      Chart.LeftAxis.AxisValuesFormat := '0x10E-0';
      Chart.LeftAxis.Minimum := StrToFloat(MinLimit);
    end;
  finally
    INF.Free;
  end;
end;

end.
