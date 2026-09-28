(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_parratt_ref;

(* The reference Parratt recursion in double precision: TCalc.RefCalc's
   algorithm, redone in Double so the tests can measure both the CPU's
   (Single) and the GPU's own precision against it. No engine calls this at
   run time yet (Task 4 wires the GPU's self-check to it); the DUnitX suite
   is its only caller for now, in place of TestGpuCalc's own copy. *)

interface

uses
  unit_Types;

/// The roughness factor TCalc.RefCalc's Roughness computes, in Double.
function RoughnessRef(RF: TRoughnessFunction; Sigma, s: Double): Double;

/// TCalc.RefCalc in Double on the layers TLayeredModel.Generate leaves,
/// ambient first; ThetaDeg is the grazing angle. No Limit clamp.
function ParrattRef(const L: TCalcLayers; ThetaDeg, Lambda: Double; SP: Boolean;
  RF: TRoughnessFunction): Double;

implementation

uses
  System.Math;

type
  TZ = record Re, Im: Double; end;

function Z(a, b: Double): TZ; inline; begin Result.Re := a; Result.Im := b; end;
function ZAdd(const a, b: TZ): TZ; inline; begin Result := Z(a.Re + b.Re, a.Im + b.Im); end;
function ZSub(const a, b: TZ): TZ; inline; begin Result := Z(a.Re - b.Re, a.Im - b.Im); end;
function ZMul(const a, b: TZ): TZ; inline;
begin
  Result := Z(a.Re * b.Re - a.Im * b.Im, a.Re * b.Im + a.Im * b.Re);
end;
function ZDiv(const a, b: TZ): TZ; inline;
var
  d: Double;
begin
  d := b.Re * b.Re + b.Im * b.Im;
  Result := Z((a.Re * b.Re + a.Im * b.Im) / d, (a.Im * b.Re - a.Re * b.Im) / d);
end;
function ZScale(k: Double; const a: TZ): TZ; inline; begin Result := Z(k * a.Re, k * a.Im); end;
function ZAbs(const a: TZ): Double; inline; begin Result := Sqrt(a.Re * a.Re + a.Im * a.Im); end;
function ZSqrt(const a: TZ): TZ;
var
  m: Double;
begin
  if (a.Re = 0) and (a.Im = 0) then
    Exit(Z(0, 0));
  m := ZAbs(a);
  if a.Re > 0 then
  begin
    m := m + a.Re;
    Result := Z(Sqrt(m / 2), a.Im / Sqrt(m * 2));
  end
  else
  begin
    m := m - a.Re;
    if a.Im < 0 then
      Result := Z(Abs(a.Im) / Sqrt(m * 2), -Sqrt(m / 2))
    else
      Result := Z(Abs(a.Im) / Sqrt(m * 2), Sqrt(m / 2));
  end;
end;

{ TCalc.RefCalc's Roughness (Shared/Math/unit_calc.pas), in Double: the 3.9.3
  forms (rfLinear damps at every sigma, not only below 0.5 A; rfSinus is the
  Stearns form, not 0). }
function RoughnessRef(RF: TRoughnessFunction; Sigma, s: Double): Double;
const
  Sqrt3 = 1.7320508075688772;
  SinusK = 2.2976031174871970;   // pi / sqrt(pi^2 - 8): rms width sigma
var
  a: Double;
begin
  case RF of
    rfError:  Result := Exp(-(Sigma * Sigma * 0.5) * s * s);
    rfExp:    Result := 1 / (1 + (s * s * Sigma * Sigma) / 2);
    rfLinear:
      begin
        a := Sqrt3 * Sigma * s;
        if Abs(a) < 1E-4 then Result := 1 else Result := Sin(a) / a;
      end;
    rfStep:   Result := Cos(Sigma * s);
    rfSinus:
      begin
        a := SinusK * Sigma * s;
        Result := Pi / 4 * (Sin(a - Pi / 2) / (a - Pi / 2) + Sin(a + Pi / 2) / (a + Pi / 2));
      end;
  else
    Result := 1;
  end;
end;

{ TCalc.RefCalc in Double from the model TLayeredModel.Generate left, with the
  angle taken as the grazing angle so nothing cancels. delta = 1 - Re epsilon
  (TCalcLayer.delta, carried directly from the materials, not recovered from
  e.Re's own Single step near 1) feeds the Fresnel term as sin^2(t) - delta,
  and the epsilon ratio's "1 minus" as unit_calc.EpsRatio does, in Double
  here too: 1 - |e_u/e_l| = (d_u - d_l)(2 - d_u - d_l) + b_l^2 - b_u^2, over
  |e_l| (|e_l| + |e_u|). }
function ParrattRef(const L: TCalcLayers; ThetaDeg, Lambda: Double; SP: Boolean;
  RF: TRoughnessFunction): Double;
var
  c1, c2, cs, cos2, ratio, oneMinus, au, al, s1, rough, L2, ex, ph: Double;
  i, n: Integer;
  eB, ei, KB, Ki, R, Rp, RFs, RFp, a1, Ph1, k1, k2: TZ;
  sB, LB, dB, bB, di, bi: Double;
begin
  c1 := 4 * Pi / Lambda;
  c2 := c1 / 2;
  cs := Sin(DegToRad(ThetaDeg));
  cos2 := cs * cs;
  n := Length(L);
  dB := L[n - 1].delta;
  bB := L[n - 1].e.Im;
  eB := Z(1 - dB, bB);
  sB := L[n - 1].s;
  LB := L[n - 1].L;
  KB := ZScale(c2, ZSqrt(Z(cos2 - dB, bB)));
  R := Z(0, 0);
  Rp := Z(0, 0);
  for i := n - 2 downto 0 do
  begin
    di := L[i].delta;
    bi := L[i].e.Im;
    ei := Z(1 - di, bi);
    Ki := ZScale(c2, ZSqrt(Z(cos2 - di, bi)));
    au := Sqrt(Sqr(1 - di) + Sqr(bi));
    al := Sqrt(Sqr(1 - dB) + Sqr(bB));
    ratio := au / al;
    oneMinus := ((di - dB) * (2 - di - dB) + (Sqr(bB) - Sqr(bi))) / (al * (al + au));
    s1 := Abs(oneMinus + ratio * cos2);
    rough := RoughnessRef(RF, sB, c1 * Sqrt(cs * Sqrt(s1)));
    L2 := LB * 2;
    ex := Exp(-L2 * KB.Im);
    ph := L2 * KB.Re;
    Ph1 := Z(ex * Cos(ph), ex * Sin(ph));
    RFs := ZScale(rough, ZDiv(ZSub(Ki, KB), ZAdd(Ki, KB)));
    a1 := ZMul(R, Ph1);
    R := ZDiv(ZAdd(RFs, a1), ZAdd(Z(1, 0), ZMul(RFs, a1)));
    if SP then
    begin
      k1 := ZDiv(Ki, ei);
      k2 := ZDiv(KB, eB);
      RFp := ZScale(rough, ZDiv(ZSub(k1, k2), ZAdd(k1, k2)));
      a1 := ZMul(Rp, Ph1);
      Rp := ZDiv(ZAdd(RFp, a1), ZAdd(Z(1, 0), ZMul(RFp, a1)));
    end;
    eB := ei; KB := Ki; sB := L[i].s; LB := L[i].L;
    dB := di; bB := bi;
  end;
  Result := R.Re * R.Re + R.Im * R.Im;
  if SP then
    Result := (Result + Rp.Re * Rp.Re + Rp.Im * Rp.Im) / 2;
end;

end.
