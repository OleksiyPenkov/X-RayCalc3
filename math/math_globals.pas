(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit math_globals;

interface

uses
  math_complex,
  VclTee.Series,
  unit_types,
  Classes,
  Vcl.Grids,
  RzGrids;

const
   H = 12398.6;

type
  THenkeRecord = record
                   e, f1, f2: Single;
                 end;
  THenkeTable = array of THenkeRecord;

  procedure ReadHenke(const N: string; E, L: single; var f: TComplex;
  var Na, Nro: single);

  procedure Sort(var Series: TLineSeries);
  procedure CopyData(const Input: TDataArray; var Output: TDataArray);

  procedure ReadHenkeTable(const N: string; var Na, Nro: single; var Table: THenkeTable);
  procedure WriteHenkeTable(const N: string; Na, Nro: single; Table: THenkeTable);
  function Poly(const x: Integer; const C: TPolyArray): Single; overload;
  function Poly(const x: Integer; Polynome: TFuncProfileRec): Single; overload;
  function FuncProfile(const x: integer; FuncProfile: TFuncProfileRec): single;

implementation

uses
  unit_settings,
  SysUtils,
  VCLTee.TeEngine;

function Poly(const x: Integer; const C: TPolyArray): Single;
var
  i, Last: Integer;
begin
  Result := C[0]; Last := 1;
  for I := 1 to Trunc(C[10]) do
  begin
    Last := Last * (x - 1);
    Result := Result + C[i] * Last;
  end;
end;

function Poly(const x: Integer; Polynome: TFuncProfileRec): Single; overload;
var
  i, Last: LongInt;
begin
  Result := Polynome.C[0]; Last := 1;
  for I := 1 to Trunc(Polynome.C[10]) do
  begin
    Last := Last * (x - 1);
    Result := Result + Polynome.C[i] * Last
  end;
end;

function FuncProfile(const x: integer; FuncProfile: TFuncProfileRec): single;
begin
  case FuncProfile.Func of
    ffPoly : Result := Poly(x, FuncProfile);
  end;
end;

procedure CopyData(const Input: TDataArray; var Output: TDataArray);
begin
   Output := Input;
end;


procedure Sort;
var
  i,j: Integer;
begin
  for i := 0 to Series.Count - 2 do
    for j := i + 1 to Series.Count - 1 do
      if Series.XValues[i] > Series.XValues[j] then
      begin
        Series.XValues.Exchange(i, j);
        Series.YValues.Exchange(i, j);
      end;
end;


procedure Convolute_new(Width: single; var Series: TLineSeries);
var
  Sum, delta, t1, A: single;
  i, N, m, p, Size: integer;

  Temp: TDataArray;

  function Gauss(x: single): single;
  var
    c: single;
  begin
    c := A/(Width * sqrt(Pi / 2));
    Result := c * exp(- sqr(x) / (2 * sqr(Width)));
  end;


  function Box(width, x: single): single;
  begin
    if (x < -width / 2) or (x > width /2 ) then Result := 0
      else  Result := 30;
  end;


begin
  if Width = 0 then Exit;
  Size := Series.Count;
  Width := Width * 0.849;
  delta := Series.XValues[11] - Series.XValues[10];
  N := Round(0.1 / delta);
  if frac(N / 2) = 0 then
    N := N - 1;
  SetLength(Temp, Size - 2*N);
  p := 0;
  for i := N to Size - N - 1 do
  begin
    A := 0;
    for m := i - N to i + N do
    begin
      if Series.YValues[m] > A then A := Series.YValues[m]
    end;


    t1 := -0.1;
    Sum := 0;
    for m := i - N to i + N do
    begin
      Sum := Sum + Series.YValues[m] * Gauss(t1) * delta;
      //Sum := Sum + Series.YValues[k] * Box(width, t1) * delta;
      t1 := t1 + delta;
    end;
    Temp[p].t := Series.XValues[i + 1];
    Temp[p].R := Sum;
    inc(p);
  end;
  Series.Clear;
  for i := 0 to High(Temp) - 1 do
    Series.AddXY(Temp[i].t, Temp[i].r)
end;


function Interp(e1, e2, f1, f2, x: single): single;
var
    a, b: single;
begin
  if (e1 - e2) <> 0 then
  begin
    a := (f1 - f2) / (e1 - e2);
    b := f2 - a * e2;
    Result := a * x + b;
  end
   else
     Result := f1;
end;

procedure ReadHenkeTXT(const N: string; E, L: single; var f: TComplex;
  var Na, Nro: single);
var
  fl: TextFile;
  fn, s, Msg: string;
  e1, e2: single;
  f1, f2: TComplex;



begin
  if E = 0 then
    E := H / L;
  fn := Settings.HenkePath + '\' + N + '.txt';
  if not FileExists(fn) then
  begin
    Msg := Format('Error! Material %s not found in the database!', [N]);
    raise EInOutError.Create(Msg);
  end;
  try
    AssignFile(fl, fn);
    try
      FileMode := 0;
      reset(fl);
      readln(fl, s);
      readln(fl, Na);
      readln(fl, Nro);
      readln(fl);
      e1 := 0;
      e2 := 0;
      while (e2 <= E) and (not Eof(fl)) do
      begin
        e1 := e2;
        f1 := f2;
        readln(fl, e2, f2.re, f2.im);
      end;
    finally
      CloseFile(fl);
    end;
  except
    on E: EInOutError do
    begin
      Msg := Format('Error reading file %S.txt ', [N]);
      raise EInOutError.Create(Msg);
    end;
  end;
  f.re := Interp(e1, e2, f1.re, f2.re, E);
  f.im := Interp(e1, e2, f1.im, f2.im, E);
end;

procedure ReadHenke(const N: string; E, L: single; var f: TComplex; var Na, Nro: single);
var
  fn, s, Msg: string;
  e1, e2: single;
  f1, f2: TComplex;
  size: integer;
  Stream : TMemoryStream;
  StrBuffer: PChar;

  function GetString: string;
  begin
    Stream.Read(size, SizeOf(size));
    StrBuffer := AllocMem(size);
    Stream.Read(StrBuffer^, size);
    Result := (StrBuffer);
    FreeMem(StrBuffer);
  end;


begin
  f.Re  := 0;  f.Im  := 0;
  f1.Re := 0; f1.Im := 0;
  f2.Re := 0; f2.Im := 0;

  if E = 0 then
    E := H / L;

  fn := Settings.HenkePath + N + '.bin';
  if not FileExists(fn) then
  begin
    Msg := Format('Error! Material %s not found in the database!', [N]);
    raise EInOutError.Create(Msg);
  end;
  try
    Stream := TMemoryStream.Create;
    try
      Stream.LoadFromFile(fn);

      s := GetString;
      Size := SizeOf(Na);

      Stream.Read(Na, Size);
      Stream.Read(Nro, Size);

      e1 := 0;
      e2 := 0;
      while (e2 <= E) and (Stream.Position < Stream.Size) do
      begin
        e1 := e2;
        f1 := f2;
        Stream.Read(e2, Size);
        Stream.Read(f2.re, Size);
        Stream.Read(f2.im, Size);
      end;
      finally
        Stream.Free;
      end;
  except
    on E: EInOutError do
    begin
      Msg := Format('Error! File %s.bin corrupted or has wrong format', [N]);
      raise EInOutError.Create(Msg);
    end;
  end;
  f.re := Interp(e1, e2, f1.re, f2.re, E);
  f.im := Interp(e1, e2, f1.im, f2.im, E);
end;

procedure ReadHenkeTable(const N: string; var Na, Nro: single; var Table: THenkeTable);
var
  fn, s, Msg: string;
  Val: THenkeRecord;
  size: integer;
  Stream : TMemoryStream;
  StrBuffer: PChar;

  function GetString: string;
  begin
    Stream.Read(size, SizeOf(size));
    StrBuffer := AllocMem(size);
    Stream.Read(StrBuffer^, size);
    Result := (StrBuffer);
    FreeMem(StrBuffer);
  end;


begin
  fn := Settings.HenkePath + N + '.bin';
  if not FileExists(fn) then
  begin
    Msg := Format('Error! Material %s not found in the database!', [N]);
    raise EInOutError.Create(Msg);
  end;
  try
    Stream := TMemoryStream.Create;
    try
      Stream.LoadFromFile(fn);

      S := GetString;
      Size := SizeOf(Na);

      Stream.Read(Na, Size);
      Stream.Read(Nro, Size);

      while (Stream.Position < Stream.Size) do
      begin
        Stream.Read(Val.e, Size);
        Stream.Read(Val.f1, Size);
        Stream.Read(Val.f2, Size);

        if Val.e > 0 then
          Insert(Val, Table, MaxInt);
      end;
      finally
        Stream.Free;
      end;
  except
    on E: EInOutError do
    begin
      Msg := Format('Error! File %s.bin corrupted or has wrong format', [N]);
      raise EInOutError.Create(Msg);
    end;
  end;
end;

procedure WriteHenkeTable(const N: string; Na, Nro: single; Table: THenkeTable);
var
  fn: string;
  Stream: TMemoryStream;
  size, i: Integer;

  procedure WriteString(const s: string);
  begin
    size := ByteLength(s) + 1;
    Stream.Write(size, SizeOf(size));
    Stream.Write(PChar(s)^, size);
  end;

begin
  fn := Settings.HenkePath + N + '.bin';

  try
    Stream := TMemoryStream.Create;
    try
      WriteString(N);

      size := SizeOf(Na);

      Stream.Write(Na, size);
      Stream.Write(Nro, size);


      for I := 0 to High(Table) do
      begin
        Stream.Write(Table[i].e, size);
        Stream.Write(Table[i].f1, size);
        Stream.Write(Table[i].f2, size);
      end;
      Stream.SaveToFile(fn);
    finally
      Stream.Free;
    end;
  except
    on e: EInOutError do
    begin
      Writeln(Format('Error writing file!', [N]));
    end;
  end;
end;

end.
