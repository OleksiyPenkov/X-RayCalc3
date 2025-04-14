﻿(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_helpers;

interface

uses
  VCLTee.Series,
  unit_types,
  StdCtrls,
  Windows,
  Messages,
  Dialogs;

function ClearDir(const DirectoryName: string; Full: boolean = False): boolean;

procedure SeriesToClipboard(Series: TLineSeries; const Mode: byte); overload;
procedure SeriesToClipboard(const cX, cY, uX, uY: string; Series: TLineSeries); overload;

procedure SeriesToFile(Series: TLineSeries; const FileName: string);
function SeriesToString(Series: TLineSeries): string;

procedure SeriesFromClipboard(Series: TLineSeries);
procedure SeriesFromFile(Series: TLineSeries; const FileName: string; out Descr: string); forward;
procedure DataToFile(const FileName: string; Data: TDataArray);
//procedure DataToClipboard(const Data: TDataArray);

function SeriesToData(Series: TLineSeries): TDataArray;
procedure DataToSeries(const Data: TDataArray; var Series: TLineSeries);
procedure AutoMerge( var Series: TLineSeries);
procedure ManualMerge( X, K: single; var Series: TLineSeries);
procedure Normalize(K: single;  var Series: TLineSeries);
procedure NormalizeAuto(const Calc: TLineSeries; var Exp: TLineSeries);

function MovAvg(const Inp: TDataArray; W: single): TDataArray;
function Smooth(const Inp: TDataArray; W: ShortInt): TDataArray;

procedure FillElementsList(const Path: string; var List: TListBox);
procedure OpenHelpFile(const FileName: string);
function GetSpecialPath(CSIDL: word): string;
function c_GetTempPath: String;
function CreateFolders(const Root: string; const Path: string): Boolean;

function SimpleShellExecute(
  hWnd: HWND;
  const FileName: string;
  const Parameters: string = '';
  const Operation: string = 'open';
  ShowCmd: Integer = SW_SHOWNORMAL;
  const Directory: string = ''
  ): Cardinal;

implementation

uses
  StrUtils,
  SysUtils,
  IOUtils,
  ClipBrd,
  Classes,
  ShellApi,
  ShlObj,
  System.Character,
  Vcl.Forms,
  VCLTee.TeEngine;

const
  TabSeparator = #9;

function CreateFolders(const Root: string; const Path: string): Boolean;
var
  FullPath: string;
begin
  if Path = '\' then
    FullPath := Root + Path
  else
    FullPath := TPath.Combine(Root, Path);

  Result := SysUtils.ForceDirectories(FullPath);
end;

function c_GetTempPath: String;
var
  Buffer: array[0..65536] of Char;
begin
  SetString(Result, Buffer, GetTempPath(Sizeof(Buffer)-1,Buffer));
end;

function GetSpecialPath(CSIDL: word): string;
var
  S: string;
begin
  SetLength(S, MAX_PATH);
  if not SHGetSpecialFolderPath(0, PChar(S), CSIDL, True) then
    S := '';
  Result := IncludeTrailingPathDelimiter(PChar(S));
end;


function Smooth(const Inp: TDataArray; W: ShortInt): TDataArray;
var
  i, j, Max: word;
  s: single;
begin
  Max := Length(Inp) - 1;
  SetLength(Result, Max + 1);

  if W = -1 then
  begin
    W := Round(Max / 10);
    if W < 1 then W := 1;
  end;

  for I := 0 to Max - W do
  begin
    S := 0;
    for j := i to i + W do
      S := S + Inp[j].r;
    Result[i].r := S/(W + 1);
  end;

  for I := Max - W + 1 to Max do
  begin
    S := 0;
    for j := i - W to i - 1 do
      S := S + Inp[j].r;
    Result[i].r := S/W;
  end;


end;

function MovAvg(const Inp: TDataArray; W: single): TDataArray;
var
  i, j: integer;
  V: single;
  Offset, Window: integer;
begin
  SetLength(Result, Length(Inp));
  if W > 1 then
    Window := Trunc(W)
  else
    Window := Round(Length(Inp) * W);

  Offset := Window div 2;

  V := 0;
  for I := Window to High(Inp) do
  begin
    V := 0;
    for j := i - Window to i do
      V := V + Inp[j].r;

    V := V / (Window + 1);
    Result[i - offset].t := Inp[i - offset].t;
    Result[i - offset].r := V;
  end;

  for I := 0 to offset do
  begin
    Result[i].t := Inp[i].t;
    Result[i].r := Inp[i].r;
  end;

  for I := High(Inp) - Offset to High(Inp) do
  begin
    Result[i].t := Inp[i].t;
    Result[i].r := V;
  end;
end;

procedure OpenHelpFile(const FileName: string);
//var
//  FullPath: string;
begin
//  FullPath := Settings.AppPath + 'docs\' + FileName;
//  if FileExists(FullPath) then
//     SimpleShellExecute(frmMain.Handle, FullPath)
//  else
//    MessageDlg('Can''t find help files! Check "docs/" folder!', mtError, [mbOk], 0);
end;



function SimpleQuoteString(const Value: string): string;
const
  QUOTECHAR = '"';
begin
  if (Value = '') or (Value[1] = QUOTECHAR) then
    Result := Value
  else
    Result := QUOTECHAR + Value + QUOTECHAR;
end;


function SimpleShellExecute(
  hWnd: HWND;
  const FileName: string;
  const Parameters: string = '';
  const Operation: string = 'open';
  ShowCmd: Integer = SW_SHOWNORMAL;
  const Directory: string = ''
  ): Cardinal;
var
  AFileName: string;
  AParameters: string;
  ADirectory: string;
begin
  AFileName := SimpleQuoteString(FileName);
  AParameters := SimpleQuoteString(Parameters);
  ADirectory := Directory;
  Result := ShellAPI.ShellExecute(
    hWnd,
    PChar(Operation),
    PChar(AFileName),
    PChar(AParameters),
    PChar(Directory),
    ShowCmd
  );
end;

procedure FillElementsList(const Path: string; var List: TListBox);
const
  Mask = '*.bin';
var
  F: TSearchRec;

  function ShortName(s: string):string;
  begin
    Result := copy(s, 1, Length(s) - 4 );
  end;

begin
  List.Items.Clear;

  if FindFirst(Path + Mask, faAnyFile, F) = 0 then
  repeat
    List.Items.Add(ShortName(F.Name));
  until FindNext(F) <> 0;
end;

function Cmpr(V1, V2: single; Threshold: single = 0.00001): boolean;
begin
  Result := abs( V1 - V2) < Threshold;
end;

function GetDevider(D: single): single;
const
  DV : array [0..1] of single = (9.3, 73);
var
  i : integer;
begin
  Result := 0;
  for I := 0 to 1 do
    if (D > DV[i] * 0.5) and (D < DV[i] * 1.5) then
    begin
      Result := DV[i];
      Break;
    end;
end;

procedure Normalize(K: single;  var Series: TLineSeries);
var
  i: integer;
begin
  for I := 0 to Series.Count - 1 do
      Series.YValue[i] := Series.YValue[i] / K;
end;

procedure NormalizeAuto(const Calc: TLineSeries; var Exp: TLineSeries);
var
  i: integer;
  Max, MaxX, Min: single;
begin
  Max := Exp.YValues.MaxValue;
  i := Exp.YValues.Locate(Max);
  MaxX := Exp.XValue[i];

  i := 0;
  while (Calc.XValues[i] < MaxX) and (i < Calc.XValues.Count)  do inc(i);

  Min := Calc.YValues[i];
  Max := Max/Min;

  for I := 0 to Exp.Count - 1 do
    Exp.YValue[i] := Exp.YValue[i] / Max;
end;

procedure AutoMerge( var Series: TLineSeries);
var
  i, Pos: integer;
  Max: single;
begin
  Max := 0; Pos := 0;
  //AutoNormalisation(Series);

  for I := 0 to Series.Count - 2 do
  begin
    Max := Series.YValue[i + 1] / Series.YValue[i];
    if Max > 8 then
    begin
      Pos := i + 1;
      Max := GetDevider(Max);
      Break;
    end;
  end;

  for I := Pos to Series.Count - 1 do
    Series.YValue[i] := Series.YValue[i] / Max;
end;

procedure ManualMerge( X, K: single; var Series: TLineSeries);
var
  i, pos: integer;
begin
  //AutoNormalisation(Series);
  Pos := Series.XValues.Locate(X);
  for I := Pos to Series.Count - 1 do
    Series.YValue[i] := Series.YValue[i] / K;
end;

procedure DataToSeries(const Data: TDataArray; var Series: TLineSeries);
var
  i: integer;
begin
  Series.Clear;
  for I := 0 to High(Data) do
   Series.AddXY(Data[i].t, Data[i].r);
end;


function SeriesToData( Series: TLineSeries): TDataArray;
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

procedure SeriesToText(const cX, cY, uX, uY: string; var MyStringList: TStringList; var Series:TLineSeries); overload;
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

procedure SeriesToText(var MyStringList: TStringList; var Series:TLineSeries); overload;
begin
  SeriesToText('2Theta', 'Reflectivity', 'deg', '', MyStringList, Series);
end;



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

procedure SeriesToClipboard(const cX, cY, uX, uY: string; Series: TLineSeries);
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

procedure SeriesToClipboard(Series: TLineSeries; const Mode: byte);
begin
  case Mode of
    0: SeriesToClipboard('2Theta', 'Reflectivity', 'deg', '', Series);
    1: SeriesToClipboard('Wavelength', 'Reflectivity', 'A', '', Series);
  end;
end;

function SeriesToString(Series: TLineSeries): string;
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

procedure SeriesToFile(Series: TLineSeries; const FileName: string);
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
  OutFile: Text;
  i: integer;
begin
  Assign(OutFile, FileName);
  Rewrite(OutFile);
  for I := 0 to High(Data) do
  begin
    writeln(OutFile, Data[i].t, #9 ,Data[i].r);
  end;


  Close(OutFile);
end;

procedure SeriesFromClipboard(Series: TLineSeries);
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

procedure SeriesFromFile(Series: TLineSeries; const FileName: string; out Descr: string);
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
    while S[1] = '*' do
    begin
      Descr := Descr + S + #13#10;
      MyStringList.Delete(0);
    end;
    SeriesFromText(MyStringList, Series);
  finally
    MyStringList.Free;
  end;
end;

{$WARNINGS OFF}

function ClearDir(const DirectoryName: string; Full: boolean): boolean;
var
  SearchRec: TSearchRec;
  ACurrentDir: string;
begin
  Result := False;
  ACurrentDir := IncludeTrailingPathDelimiter(DirectoryName);

  try
    if FindFirst(ACurrentDir + '*.*', faAnyFile, SearchRec) = 0 then
      try
        repeat
          if (SearchRec.Name <> '.') and (SearchRec.Name <> '..') then
            SysUtils.DeleteFile(ACurrentDir + SearchRec.Name) until FindNext
              (SearchRec) <> 0;
          finally
            SysUtils.FindClose(SearchRec);
          end;
          if Full then
            RemoveDirectory(PChar(DirectoryName));
          except
            Result := False;
          end;
end;
{$WARNINGS ON}

function RemoveAppPath(const Path: string; AppPath: string): string;
var
  p: Integer;
begin
  Result := Path;
  p := Pos(AppPath, Result);
  if p > 0 then
    Delete(Result, 1, Length(AppPath));
end;

end.
