(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_SeriesIO;

interface

uses
  VCLTee.TeEngine,
  unit_types;

procedure SeriesToClipboard(Series: TChartSeries; const Mode: byte); overload;
procedure SeriesToClipboard(const cX, cY, uX, uY: string; Series: TChartSeries); overload;

procedure SeriesToFile(Series: TChartSeries; const FileName: string);
function SeriesToString(Series: TChartSeries): string;

procedure SeriesFromClipboard(Series: TChartSeries);
procedure SeriesFromFile(Series: TChartSeries; const FileName: string; out Descr: string); forward;
procedure DataToFile(const FileName: string; Data: TDataArray);

function SeriesToData(Series: TChartSeries): TDataArray;
procedure DataToSeries(const Data: TDataArray; Series: TChartSeries);

implementation

uses
  SysUtils,
  ClipBrd,
  Classes,
  System.Character;

const
  TabSeparator = #9;

procedure DataToSeries(const Data: TDataArray; Series: TChartSeries);
var
  i: integer;
begin
  Series.Clear;
  for I := 0 to High(Data) do
   Series.AddXY(Data[i].t, Data[i].r);
end;

function SeriesToData( Series: TChartSeries): TDataArray;
var
  i: integer;
begin
  SetLength(Result, 0);
  SetLength(Result, Series.Count);
  for I := 0 to Series.Count - 1 do
  begin
    Result[i].t := Series.XValue[i];
    Result[i].R := Series.YValue[i];
  end;
end;

procedure SeriesToText(const cX, cY, uX, uY: string; var MyStringList: TStringList; Series: TChartSeries); overload;
var
  i, N: integer;
  s: string;
  x, y: single;
begin
  MyStringList.Add(cX + TabSeparator + Cy);
  MyStringList.Add(uX + TabSeparator + uY);
  MyStringList.Add('');
  N := Series.Count;
  for i := 0 to N - 1 do
  begin
    x := Series.XValues[i];
    y := Series.YValues[i];
    s := FloatToStrF(x, ffFixed, 5, 3) + TabSeparator;
    s := s + FloatToStrF(y, ffExponent, 5, 4);
    MyStringList.Add(s);
  end;
end;

procedure SeriesToText(var MyStringList: TStringList; Series: TChartSeries); overload;
begin
  SeriesToText('2Theta', 'Reflectivity', 'deg', '', MyStringList, Series);
end;

procedure SeriesFromText(var MyStringList: TStringList; Series: TChartSeries);
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

procedure SeriesToClipboard(const cX, cY, uX, uY: string; Series: TChartSeries);
var
  MyStringList: TStringList;
begin
  MyStringList := TStringList.Create;
  try
    SeriesToText(cX, cY, uX, uY, MyStringList, Series);
    Clipboard.AsText := MyStringList.Text;
  finally
    MyStringList.Free;
  end;
end;

procedure SeriesToClipboard(Series: TChartSeries; const Mode: byte);
begin
  case Mode of
    0: SeriesToClipboard('2Theta', 'Reflectivity', 'deg', '', Series);
    1: SeriesToClipboard('Wavelength', 'Reflectivity', 'A', '', Series);
  end;
end;

function SeriesToString(Series: TChartSeries): string;
var
  MyStringList: TStringList;
begin
  MyStringList := TStringList.Create;
  try
    SeriesToText(MyStringList, Series);
    Result := MyStringList.Text;
  finally
    MyStringList.Free;
  end;
end;

procedure SeriesToFile(Series: TChartSeries; const FileName: string);
var
  MyStringList: TStringList;
begin
  MyStringList := TStringList.Create;
  try
    SeriesToText(MyStringList, Series);
    MyStringList.SaveToFile(FileName);
  finally
    MyStringList.Free;
  end;
end;

procedure DataToFile(const FileName: string; Data: TDataArray);
var
  SL: TStringList;
  i: integer;
begin
  SL := TStringList.Create;
  try
    for I := 0 to High(Data) do
      SL.Add(Format('%g'#9'%g', [Data[i].t, Data[i].r]));
    SL.SaveToFile(FileName);
  finally
    SL.Free;
  end;
end;

procedure SeriesFromClipboard(Series: TChartSeries);
var
  MyStringList: TStringList;
begin
  MyStringList := TStringList.Create;
  try
    MyStringList.Text := Clipboard.AsText;
    SeriesFromText(MyStringList, Series);
  finally
    MyStringList.Free;
  end;
end;

procedure SeriesFromFile(Series: TChartSeries; const FileName: string; out Descr: string);
var
  MyStringList: TStringList;
  S: string;
  i: Integer;
begin
  MyStringList := TStringList.Create;
  try
    MyStringList.LoadFromFile(FileName);
    S :=  MyStringList[0];
    if Pos('Sample', S) > 0 then
    begin
      for i := 1 to 21 do
        MyStringList.Delete(0);
    end;
    while (MyStringList.Count > 0) and (MyStringList[0] <> '') and (MyStringList[0][1] = '*') do
    begin
      S := MyStringList[0];
      Descr := Descr + S + #13#10;
      MyStringList.Delete(0);
    end;
    SeriesFromText(MyStringList, Series);
  finally
    MyStringList.Free;
  end;
end;

end.
