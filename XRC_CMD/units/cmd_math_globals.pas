(* *****************************************************************************
  *
  *   Copyright (C) 2001-2020 Oleksiy Penkov
  *   e-mail: oleksiy.penkov@gmail.com
  *
  ****************************************************************************** *)

unit cmd_math_globals;

interface

uses
  math_complex,
  cmd_unit_types,
  Classes;

procedure ReadHenke(const Name: string; E, L: single; var f: TComplex;
  var Na, Nro: single);

procedure CopyData(const Input: TDataArray; var Output: TDataArray);

implementation

uses
  SysUtils;

const
  H = 12398.6;

procedure CopyData(const Input: TDataArray; var Output: TDataArray);
begin
  Output := Input;
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

procedure ReadHenke(const Name: string; E, L: single; var f: TComplex; var Na, Nro: single);
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

  fn := '.\Henke\' + Name + '.bin';
  if not FileExists(fn) then
  begin
    Msg := Format('Error! Material %s not found in the database!', [Name]);
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
      Msg := Format('Error! File %s.bin corrupted or has wrong format', [Name]);
      raise EInOutError.Create(Msg);
    end;
  end;
  f.re := Interp(e1, e2, f1.re, f2.re, E);
  f.im := Interp(e1, e2, f1.im, f2.im, E);
end;



end.
