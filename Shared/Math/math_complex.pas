(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit math_complex;

interface

uses
  Neslib.FastMath,
  System.Math,
  SysUtils;

type
  TComplex = record
    Re, Im: single;
  end;


function ToComplex(R, I: single): TComplex;
function Imag(Z: TComplex): single;


function IsValidComplexString(const S: string): boolean;
function IsValidComplexNumber(Z: TComplex): boolean;
function BoolToString(B: boolean): string;
function ComplexToString(Z: TComplex): string;
function StringToComplex(const S: String): TComplex;


function AddZZ(const Z, Z2: TComplex): TComplex; inline;
function AddZR(const Z: TComplex; R: single): TComplex; inline;
function SubZZ(const Z, Z2: TComplex): TComplex; inline;
function SubZR(const Z: TComplex;const R: single): TComplex; inline;
function SubRZ(const R: single;const Z: TComplex): TComplex; inline;
function MulZZ(const Z, Z2: TComplex): TComplex; inline;
function MulRZ(const R: single;const Z: TComplex): TComplex; inline;
function DivZR(const Z: TComplex;const R: single): TComplex; inline;
function DivRZ(const R: single;const Z: TComplex): TComplex; inline;
function DivZZ(const Z1, Z2: TComplex): TComplex; inline;


function AbsZ(const Z: TComplex): single; inline;
function ModZ(const Z: TComplex): single; inline;
{ return the argument of Z in radians }
function ArgZ(Z: TComplex): single;
function ConjugateZ(Z: TComplex): TComplex;
function NormZ(Z: TComplex): single;
function NegZ(Z: TComplex): TComplex;
function EqualZZ(Z, Z2: TComplex): boolean;


function CosZ(Z: TComplex): TComplex;
function CoshZ(Z: TComplex): TComplex;
function SinZ(Z: TComplex): TComplex;
function ArcSinZ(Z: TComplex): TComplex;
function SinhZ(Z: TComplex): TComplex;
function ArcSinhZ(Z: TComplex): TComplex;
function TanZ(Z: TComplex): TComplex;
function ArcTanZ(Z: TComplex): TComplex;
function ArcCosZ(Z: TComplex): TComplex;
function TanhZ(Z: TComplex): TComplex;
function ArcTanhZ(Z: TComplex): TComplex;


function ExpZ(const Z: TComplex): TComplex; inline;
function LnZ(Z: TComplex): TComplex;
function Log10Z(Z: TComplex): TComplex;
function PolarZ(Range, Angle: single): TComplex;
procedure RectangularZ(Z: TComplex; var Range, Angle: single);
function SqrtZ(Z: TComplex): TComplex;
function PowZZ(Z, Z2: TComplex): TComplex;
function PowZR1(Z: TComplex; R: integer): TComplex;
function PowZR2(Z: TComplex; R: single): TComplex;
function PowRZ(R: single; Z: TComplex): TComplex;

implementation

const
  InvTwoLn10 = 0.2171472409516259;  // 1/(2*ln(10)), for ln-to-log10 conversion


function ToComplex(R, I: single): TComplex;
begin
  Result.Re := R;
  Result.Im := I;
end;

function IsValidComplexString(const S: string): boolean;
begin
  Result := True;
  try
    StringToComplex(S);
  except
    on EConvertError do
      Result := False;
  end;
end;

function IsValidComplexNumber(Z: TComplex): boolean;
begin
  Result := True;
  try
    ComplexToString(Z);
  except
    on EConvertError do
      Result := False;
  end;
end;

function BoolToString(B: boolean): string;
const
  Bool: array [False .. True] of string = ('False', 'True');
begin
  Result := Bool[B];
end;


function ComplexToString(Z: TComplex): string;
begin
  Result := Format('(%s ,%si)', [FloatToStr(Z.Re), FloatToStr(Z.Im)]);
end;


function StringToComplex(const S: string): TComplex;
var
  p: Integer;
  s1, s2: string;
begin
  s1 := Trim(S);
  if (Length(s1) > 0) and (s1[1] = '(') then
    s1 := Copy(s1, 2, Length(s1) - 2);

  p := Pos(',', s1);
  if p > 0 then
  begin
    s2 := Trim(Copy(s1, p + 1, MaxInt));
    s1 := Trim(Copy(s1, 1, p - 1));
    if (Length(s2) > 0) and (s2[Length(s2)] = 'i') then
      s2 := Trim(Copy(s2, 1, Length(s2) - 1));
    Result.Re := StrToFloat(s1);
    Result.Im := StrToFloat(s2);
  end
  else begin
    Result.Re := StrToFloat(s1);
    Result.Im := 0;
  end;
end;

function Real(Z: TComplex): single;
begin
  Result := Z.Re;
end;

function Imag(Z: TComplex): single;
begin
  Result := Z.Im;
end;


function AddZZ(const Z, Z2: TComplex): TComplex;
begin
  Result.Re := Z.Re + Z2.Re;
  Result.Im := Z.Im + Z2.Im;
end;

function AddZR(const Z: TComplex; R: single): TComplex;
begin
  Result.Re := R + Z.Re;
  Result.Im := Z.Im;
end;

function SubZZ(const Z, Z2: TComplex): TComplex;
begin
  Result.Re := Z.Re - Z2.Re;
  Result.Im := Z.Im - Z2.Im;
end;

function SubZR(const Z: TComplex; const R: single): TComplex;
begin
  Result.Re := Z.Re - R;
  Result.Im := Z.Im;
end;

function SubRZ(const R: single;const Z: TComplex): TComplex;
begin
  Result := SubZZ(ToComplex(R, 0), Z);
end;

function MulZZ(const Z, Z2: TComplex): TComplex;
begin
  Result.Re := Z.Re * Z2.Re - Z.Im * Z2.Im;
  Result.Im := Z.Re * Z2.Im + Z.Im * Z2.Re;
end;

function MulRZ(const R: single;const Z: TComplex): TComplex;
begin
  Result.Re := R * Z.Re;
  Result.Im := R * Z.Im;
end;

function DivZR(const Z: TComplex;const  R: single): TComplex;
begin
  Result.Re := Z.Re / R;
  Result.Im := Z.Im / R;
end;

function DivRZ(const R: single;const Z: TComplex): TComplex;
var
  d: single;
begin
  d := Z.Re * Z.Re + Z.Im * Z.Im;
  Result := ToComplex(R * Z.Re / d, -R * Z.Im / d);
end;

function DivZZ(const Z1, Z2: TComplex): TComplex;
var
  d: single;
begin
  d := Z2.Re * Z2.Re + Z2.Im * Z2.Im;
  Result.Re := (Z1.Re * Z2.Re + Z1.Im * Z2.Im) / d;
  Result.Im := (Z1.Im * Z2.Re - Z1.Re * Z2.Im) / d;
end;

function AbsZ(const Z: TComplex): single;
begin
  Result := Sqrt(Z.Re * Z.Re + Z.Im * Z.Im);
end;

function ModZ(const Z: TComplex): single;
begin
  Result := AbsZ(Z);
end;

function ArgZ(Z: TComplex): single;
begin
  Result := FastArcTan2(Z.Im, Z.Re);
end;

function ConjugateZ(Z: TComplex): TComplex;
begin
  Result.Re := Z.Re;
  Result.Im := -Z.Im;
end;

function NormZ(Z: TComplex): single;
begin
  Result := Z.Re * Z.Re + Z.Im * Z.Im;
end;

function NegZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(-Z.Re, -Z.Im);
end;

function EqualZZ(Z, Z2: TComplex): boolean;
begin
  Result := ((Z.Re = Z2.Re) and (Z.Im = Z2.Im));
end;


function CosZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(FastCos(Z.Re) * Neslib.FastMath.Cosh(Z.Im), -(FastSin(Z.Re) * Neslib.FastMath.Sinh(Z.Im)));
end;

{ return the arccosine of Z. Input value must be between -1..1 and -i..i }
function ArcCosZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(Neslib.FastMath.ArcCos(Z.Re) * Neslib.FastMath.ArcCosh(Z.Im),
                      Neslib.FastMath.ArcSin(Z.Re) * Neslib.FastMath.ArcSinh(Z.Im));
end;

function CoshZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(Neslib.FastMath.Cosh(Z.Re) * FastCos(Z.Im), Neslib.FastMath.Sinh(Z.Re) * FastSin(Z.Im));
end;

function SinZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(FastSin(Z.Re) * Neslib.FastMath.Cosh(Z.Im), FastCos(Z.Re) * Neslib.FastMath.Sinh(Z.Im));
end;

{ return the arcsine of Z. Input value must be between -1..1 and -i..i }
function ArcSinZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(Neslib.FastMath.ArcSin(Z.Re) * Neslib.FastMath.ArcCosh(Z.Im),
                      Neslib.FastMath.ArcCos(Z.Re) * Neslib.FastMath.ArcSinh(Z.Im));
end;

function SinhZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(Neslib.FastMath.Sinh(Z.Re) * FastCos(Z.Im), Neslib.FastMath.Cosh(Z.Re) * FastSin(Z.Im));
end;

function ArcSinhZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(-Z.Im, Z.Re);
  Result := ArcSinZ(Result);
  Result := ToComplex(Result.Im, -Result.Re);
end;

function TanZ(Z: TComplex): TComplex;
var
  x, y, t: single;
begin
  x := 2 * Z.Re;
  y := 2 * Z.Im;
  t := 1.0 / (FastCos(x) + Neslib.FastMath.Cosh(y));
  Result := ToComplex(t * FastSin(x), t * Neslib.FastMath.Sinh(y));
end;

function ArcTanZ(Z: TComplex): TComplex;
var
  x, y, t: single;
begin
  x := 2 * Z.Re;
  y := 2 * Z.Im;
  t := 1.0 / (FastCos(x) + Neslib.FastMath.Cosh(y));
  Result := ToComplex(t * Neslib.FastMath.ArcSin(x), t * Neslib.FastMath.ArcSinh(y));
end;

function TanhZ(Z: TComplex): TComplex;
var
  x, y, t: single;
begin
  x := 2 * Z.Re;
  y := 2 * Z.Im;
  t := 1.0 / (Neslib.FastMath.Cosh(x) + FastCos(y));
  Result := ToComplex(t * Neslib.FastMath.Sinh(x), t * FastSin(y));
end;

{ return the hyperbolic arctan of Z. Input value must be between -1..1 and -i..i }
function ArcTanhZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(-Z.Im, Z.Re);
  Result := ArcTanZ(Result);
  Result := ToComplex(Result.Im, -Result.Re);
end;


function ExpZ(const Z: TComplex): TComplex;
var
  x, s, c: single;
begin
  {$IFDEF  WIN32}
    x := FastExp(Z.Re);
  {$ELSE}
    if (Z.Re > -1023) and (Z.Re < 1023) then
       x := FastExp(Z.Re)
    else
       x := Exp(Z.Re);
  {$ENDIF}

  FastSinCos(Z.Im, s, c);
  Result.Re := x * c;
  Result.Im := x * s;
end;

function LnZ(Z: TComplex): TComplex;
begin
  Result := ToComplex(FastLn(AbsZ(Z)), ArgZ(Z));
end;

function Log10Z(Z: TComplex): TComplex;
begin
  Result := ToComplex(InvTwoLn10 * FastLn(NormZ(Z)), ArgZ(Z));
end;

{ Angle is in radians between the real axis and the point x,yi. }
function PolarZ(Range, Angle: single): TComplex;
begin
  Result := ToComplex(Range * FastCos(Angle), Range * FastSin(Angle));
end;

procedure RectangularZ(Z: TComplex; var Range, Angle: single);
begin
  Angle := ArgZ(Z);
  Range := AbsZ(Z);
end;

{ SqrtZ's small component carries the evanescent reflectivity below the
  critical angle. SSE rsqrtss has only ~12 bits and no Newton refinement;
  its approximation noise can exceed a small physical signal. The exact
  reciprocal square root is deliberate, despite the CPU-fit speed cost. }
function ExactInverseSqrt(const X: Single): Single; inline;
begin
  Result := 1 / System.Sqrt(X);
end;

function SqrtZ(Z: TComplex): TComplex;
var
  LValue: Single;
begin
  if (Z.Re = 0) and (Z.Im = 0) then
    Result := ToComplex(0, 0)
  else begin
    LValue := AbsZ(Z);
    if Z.Re > 0 then
    begin
      LValue := LValue + Z.Re;
      Result := ToComplex(Sqrt(LValue / 2), Z.Im * ExactInverseSqrt(LValue * 2));
    end
    else
    begin
      LValue := LValue - Z.Re;
      if Z.Im < 0 then
        Result := ToComplex(Abs(Z.Im) * ExactInverseSqrt(LValue * 2), -Sqrt(LValue / 2))
      else
        Result := ToComplex(Abs(Z.Im) * ExactInverseSqrt(LValue * 2), Sqrt(LValue / 2));
    end;
  end;
end;

function PowZZ(Z, Z2: TComplex): TComplex;
var
  LogF, Phase: TComplex;
begin
  if (Z2.Re = 0) and (Z2.Im = 0) then
    Result := ToComplex(1, 0)
  else if Z2.Im = 0 then
    Result := PowZR2(Z, Z2.Re)
  else
  begin
    LogF.Re := FastLn(AbsZ(Z));
    LogF.Im := FastArcTan2(Z.Im, Z.Re);
    Phase.Re := FastExp(LogF.Re * Z2.Re - LogF.Im * Z2.Im);
    Phase.Im := LogF.Re * Z2.Im + LogF.Im * Z2.Re;
    Result := ToComplex(Phase.Re * FastCos(Phase.Im), Phase.Re * FastSin(Phase.Im));
  end;
end;

function PowZR1(Z: TComplex; R: integer): TComplex;
begin
  Result := PowZZ(Z, ToComplex(Trunc(R), 0));
end;

function PowZR2(Z: TComplex; R: single): TComplex;
var
  lnAbs, arg, mag: single;
begin
  if R = 0 then
    Result := ToComplex(1, 0)
  else begin
    lnAbs := FastLn(AbsZ(Z));
    arg := FastArcTan2(Z.Im, Z.Re) * R;
    mag := FastExp(lnAbs * R);
    Result := ToComplex(mag * FastCos(arg), mag * FastSin(arg));
  end;
end;

function PowRZ(R: single; Z: TComplex): TComplex;
begin
  Result := PowZZ(ToComplex(R, 0), Z);
end;

end.
