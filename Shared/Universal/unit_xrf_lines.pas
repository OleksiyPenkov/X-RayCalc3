unit unit_xrf_lines;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TXRFLineRec = record
    Symbol: string;
    Z: Byte;
    Lambda: Double;  // Angstroms
  end;

function GetXRFLambda(const Element: string): Double;
function ExpandElementRange(const RangeStr: string): TArray<string>;
function GetAllElements: TArray<string>;

implementation

const
  XRF_LINE_COUNT = 90;
  XRFLines: array[0..XRF_LINE_COUNT-1] of TXRFLineRec = (
    // Ka lines: Z=3 (Li) through Z=55 (Cs)
    // lambda = 12398.419 / E(eV), using weighted-average Ka
    (Symbol: 'Li'; Z: 3;  Lambda: 228.0),
    (Symbol: 'Be'; Z: 4;  Lambda: 114.0),
    (Symbol: 'B';  Z: 5;  Lambda: 67.6),
    (Symbol: 'C';  Z: 6;  Lambda: 44.7),
    (Symbol: 'N';  Z: 7;  Lambda: 31.6),
    (Symbol: 'O';  Z: 8;  Lambda: 23.62),
    (Symbol: 'F';  Z: 9;  Lambda: 18.32),
    (Symbol: 'Ne'; Z: 10; Lambda: 14.61),
    (Symbol: 'Na'; Z: 11; Lambda: 11.91),
    (Symbol: 'Mg'; Z: 12; Lambda: 9.890),
    (Symbol: 'Al'; Z: 13; Lambda: 8.339),
    (Symbol: 'Si'; Z: 14; Lambda: 7.126),
    (Symbol: 'P';  Z: 15; Lambda: 6.158),
    (Symbol: 'S';  Z: 16; Lambda: 5.373),
    (Symbol: 'Cl'; Z: 17; Lambda: 4.729),
    (Symbol: 'Ar'; Z: 18; Lambda: 4.194),
    (Symbol: 'K';  Z: 19; Lambda: 3.742),
    (Symbol: 'Ca'; Z: 20; Lambda: 3.359),
    (Symbol: 'Sc'; Z: 21; Lambda: 3.032),
    (Symbol: 'Ti'; Z: 22; Lambda: 2.749),
    (Symbol: 'V';  Z: 23; Lambda: 2.504),
    (Symbol: 'Cr'; Z: 24; Lambda: 2.291),
    (Symbol: 'Mn'; Z: 25; Lambda: 2.103),
    (Symbol: 'Fe'; Z: 26; Lambda: 1.937),
    (Symbol: 'Co'; Z: 27; Lambda: 1.790),
    (Symbol: 'Ni'; Z: 28; Lambda: 1.659),
    (Symbol: 'Cu'; Z: 29; Lambda: 1.542),
    (Symbol: 'Zn'; Z: 30; Lambda: 1.436),
    (Symbol: 'Ga'; Z: 31; Lambda: 1.340),
    (Symbol: 'Ge'; Z: 32; Lambda: 1.254),
    (Symbol: 'As'; Z: 33; Lambda: 1.177),
    (Symbol: 'Se'; Z: 34; Lambda: 1.106),
    (Symbol: 'Br'; Z: 35; Lambda: 1.041),
    (Symbol: 'Kr'; Z: 36; Lambda: 0.9801),
    (Symbol: 'Rb'; Z: 37; Lambda: 0.9256),
    (Symbol: 'Sr'; Z: 38; Lambda: 0.8753),
    (Symbol: 'Y';  Z: 39; Lambda: 0.8288),
    (Symbol: 'Zr'; Z: 40; Lambda: 0.7859),
    (Symbol: 'Nb'; Z: 41; Lambda: 0.7462),
    (Symbol: 'Mo'; Z: 42; Lambda: 0.7093),
    (Symbol: 'Tc'; Z: 43; Lambda: 0.6749),
    (Symbol: 'Ru'; Z: 44; Lambda: 0.6428),
    (Symbol: 'Rh'; Z: 45; Lambda: 0.6132),
    (Symbol: 'Pd'; Z: 46; Lambda: 0.5854),
    (Symbol: 'Ag'; Z: 47; Lambda: 0.5594),
    (Symbol: 'Cd'; Z: 48; Lambda: 0.5348),
    (Symbol: 'In'; Z: 49; Lambda: 0.5118),
    (Symbol: 'Sn'; Z: 50; Lambda: 0.4900),
    (Symbol: 'Sb'; Z: 51; Lambda: 0.4695),
    (Symbol: 'Te'; Z: 52; Lambda: 0.4500),
    (Symbol: 'I';  Z: 53; Lambda: 0.4314),
    (Symbol: 'Xe'; Z: 54; Lambda: 0.4138),
    (Symbol: 'Cs'; Z: 55; Lambda: 0.3972),
    // La lines: Z=56 (Ba) through Z=92 (U)
    (Symbol: 'Ba'; Z: 56; Lambda: 2.776),
    (Symbol: 'La'; Z: 57; Lambda: 2.666),
    (Symbol: 'Ce'; Z: 58; Lambda: 2.562),
    (Symbol: 'Pr'; Z: 59; Lambda: 2.463),
    (Symbol: 'Nd'; Z: 60; Lambda: 2.370),
    (Symbol: 'Pm'; Z: 61; Lambda: 2.282),
    (Symbol: 'Sm'; Z: 62; Lambda: 2.200),
    (Symbol: 'Eu'; Z: 63; Lambda: 2.121),
    (Symbol: 'Gd'; Z: 64; Lambda: 2.047),
    (Symbol: 'Tb'; Z: 65; Lambda: 1.977),
    (Symbol: 'Dy'; Z: 66; Lambda: 1.909),
    (Symbol: 'Ho'; Z: 67; Lambda: 1.845),
    (Symbol: 'Er'; Z: 68; Lambda: 1.784),
    (Symbol: 'Tm'; Z: 69; Lambda: 1.727),
    (Symbol: 'Yb'; Z: 70; Lambda: 1.672),
    (Symbol: 'Lu'; Z: 71; Lambda: 1.620),
    (Symbol: 'Hf'; Z: 72; Lambda: 1.570),
    (Symbol: 'Ta'; Z: 73; Lambda: 1.522),
    (Symbol: 'W';  Z: 74; Lambda: 1.476),
    (Symbol: 'Re'; Z: 75; Lambda: 1.433),
    (Symbol: 'Os'; Z: 76; Lambda: 1.391),
    (Symbol: 'Ir'; Z: 77; Lambda: 1.351),
    (Symbol: 'Pt'; Z: 78; Lambda: 1.313),
    (Symbol: 'Au'; Z: 79; Lambda: 1.277),
    (Symbol: 'Hg'; Z: 80; Lambda: 1.241),
    (Symbol: 'Tl'; Z: 81; Lambda: 1.207),
    (Symbol: 'Pb'; Z: 82; Lambda: 1.175),
    (Symbol: 'Bi'; Z: 83; Lambda: 1.144),
    (Symbol: 'Po'; Z: 84; Lambda: 1.114),
    (Symbol: 'At'; Z: 85; Lambda: 1.085),
    (Symbol: 'Rn'; Z: 86; Lambda: 1.057),
    (Symbol: 'Fr'; Z: 87; Lambda: 1.031),
    (Symbol: 'Ra'; Z: 88; Lambda: 1.005),
    (Symbol: 'Ac'; Z: 89; Lambda: 0.9808),
    (Symbol: 'Th'; Z: 90; Lambda: 0.9573),
    (Symbol: 'Pa'; Z: 91; Lambda: 0.9348),
    (Symbol: 'U';  Z: 92; Lambda: 0.9131)
  );

var
  FIndex: TDictionary<string, Integer>;

procedure EnsureIndex;
var
  i: Integer;
begin
  if FIndex <> nil then Exit;
  FIndex := TDictionary<string, Integer>.Create(XRF_LINE_COUNT);
  for i := 0 to XRF_LINE_COUNT - 1 do
    FIndex.Add(UpperCase(XRFLines[i].Symbol), i);
end;

function GetXRFLambda(const Element: string): Double;
var
  Idx: Integer;
begin
  EnsureIndex;
  if not FIndex.TryGetValue(UpperCase(Trim(Element)), Idx) then
    raise EArgumentException.CreateFmt('Unknown element: "%s"', [Element]);
  Result := XRFLines[Idx].Lambda;
end;

function FindElementIndex(const Element: string): Integer;
begin
  EnsureIndex;
  if not FIndex.TryGetValue(UpperCase(Trim(Element)), Result) then
    raise EArgumentException.CreateFmt('Unknown element: "%s"', [Element]);
end;

function ExpandElementRange(const RangeStr: string): TArray<string>;
var
  Parts: TArray<string>;
  IdxFrom, IdxTo, Temp, i, Count: Integer;
begin
  Parts := RangeStr.Split(['-']);
  if Length(Parts) <> 2 then
    raise EArgumentException.CreateFmt('Invalid range format: "%s"', [RangeStr]);

  IdxFrom := FindElementIndex(Trim(Parts[0]));
  IdxTo := FindElementIndex(Trim(Parts[1]));

  // Silently reverse if needed
  if IdxFrom > IdxTo then
  begin
    Temp := IdxFrom;
    IdxFrom := IdxTo;
    IdxTo := Temp;
  end;

  Count := IdxTo - IdxFrom + 1;
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := XRFLines[IdxFrom + i].Symbol;
end;

function GetAllElements: TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, XRF_LINE_COUNT);
  for i := 0 to XRF_LINE_COUNT - 1 do
    Result[i] := XRFLines[i].Symbol;
end;

initialization

finalization
  FIndex.Free;

end.
