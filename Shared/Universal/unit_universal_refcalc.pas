(* *****************************************************************************
 *
 *   X-Ray Calc - Universal Reflectivity Calculation
 *
 *   Standalone RefCalc extracted from cmd_unit_calc.pas (TCalc.RefCalc).
 *   No dependency on TCalc or OmniThreadLibrary.
 *
 *   Copyright (C) 2001-2022 Oleksiy Penkov
 *   e-mail: oleksiy.penkov@gmail.com
 *
 ****************************************************************************** *)

unit unit_universal_refcalc;

interface

uses
  System.SysUtils, System.Math,
  math_complex, cmd_unit_types;

function RefCalcStandalone(t, Lambda: Single; ALayers: TLayers;
  Pol: TPolarisation; RF: TRoughnessFunction): Single;

implementation

function RefCalcStandalone(t, Lambda: Single; ALayers: TLayers;
  Pol: TPolarisation; RF: TRoughnessFunction): Single;
var
  c, Rs, Rp, Rsp, s1, sin_t, cos_t, sqr_sin_t: single;

  function TotalRecursiveRefraction: single;
  var
    i: integer;
    Im: TComplex;
    a1, a2, b1, b2: TComplex;
  begin
    Im := ToComplex(0, 1);
    for i := High(ALayers) - 1 downto 0 do
    begin
      a1 := MulRZ(ALayers[i + 1].H * 2, ALayers[i + 1].K);
      a1 := MulZZ(Im, a1);
      a1 := ExpZ(a1);
      a1 := MulZZ(ALayers[i + 1].R, a1);
      b1 := AddZZ(ALayers[i].RF, a1);
      a2 := MulZZ(ALayers[i].RF, a1);
      b2 := AddZR(a2, 1);
      ALayers[i].R := DivZZ(b1, b2);
    end;
    Result := sqr(AbsZ(ALayers[0].R));
  end;

  function Roughness(const RF: TRoughnessFunction; const sigma, s: single):Single;inline;
  const
    Sqrt3 = 1.7320508075688772;
    SinusK = 2.2976031174871970;   // pi / sqrt(pi^2 - 8)
  var
    a: Single;
  begin
      case RF of
        rfError:
          // The Nevot-Croce factor, exp(-2 k_z^2 sigma^2): s is 2 k_z here
          // (c = 4 Pi / Lambda), so the coefficient is one half. The literal is
          // unit_calc.pas's, which precomputes Sqr(sigma) * 0.50299 - its
          // sqr(1/1.41) for sqr(1/sqrt(2)), 0.6 % above an exact half. That
          // engine is the reference this one has to match, so its constant is
          // the constant, approximation included; an exact 0.5 here would put
          // the fitness 0.6 % away from every curve fit_xrr has ever fitted.
          // This was exp(-sigma^2 s^2) until 2026-09-12 - twice the exponent,
          // every interface behaving as if it were sqrt(2) times rougher.
          Result := exp(-0.50299 * sqr(sigma) * sqr(s));
        rfExp:
          Result := 1 / (1 + (sqr(s) * sqr(sigma)) / 2);
        rfLinear:
          // until 3.9.3 this damped only below sigma = 0.5 A (and 0/0 at 0)
          begin
            a := Sqrt3 * sigma * s;
            if Abs(a) < 1E-4 then
              Result := 1
            else
              Result := sin(a) / a;
          end;
        rfStep:
          Result := cos(sigma * s);
        rfSinus:
          // Stearns / IMD; the rms width is sigma. Undefined until 3.9.3.
          begin
            a := SinusK * sigma * s;
            Result := Pi / 4 * (sin(a - Pi / 2) / (a - Pi / 2) +
                                sin(a + Pi / 2) / (a + Pi / 2));
          end;
        else
          Result := 1;
      end;
  end;

  procedure LayerAmplitudeRefractionS;     { Коэффициент отражения Rs}
  var
    i: integer;
    b1, b2: TComplex;
    s: Single;
  begin
    for i := 0 to Length(ALayers) - 2 do
    begin
      b1 := SubZZ(ALayers[i].K, ALayers[i + 1].K);
      b2 := AddZZ(ALayers[i].K, ALayers[i + 1].K);
      ALayers[i].RF := DivZZ(b1, b2);
      s1 := Abs(1 - (AbsZ(DivZZ(ALayers[i].e, ALayers[i + 1].e)) * sqr_sin_t));
      s := c * sqrt(cos_t * sqrt(s1));

      ALayers[i].RF := MulRZ(Roughness(RF, ALayers[i + 1].s, s), ALayers[i].RF);
    end;
  end;

  procedure LayerAmplitudeRefractionP;     { Коэффициент отражения Rp }
  var
    i: integer;
    a1, a2, b1, b2: TComplex;
    s: Single;
  begin
    for i := 0 to Length(ALayers) - 2 do
    begin
      a1 := DivZZ(ALayers[i].K, ALayers[i].e);
      a2 := DivZZ(ALayers[i + 1].K, ALayers[i + 1].e);
      b1 := SubZZ(MulRZ(1, a1), MulRZ(1, a2));
      b2 := AddZZ(MulRZ(1, a1), MulRZ(1, a2));
      ALayers[i].RF := DivZZ(b1, b2);
      s1 := Abs(1 - (AbsZ(DivZZ(ALayers[i].e, ALayers[i + 1].e)) * sqr_sin_t));
      s := c * sqrt(cos_t * sqrt(s1));

      ALayers[i].RF := MulRZ(Roughness(RF, ALayers[i + 1].s, s), ALayers[i].RF);
    end;
  end;

  procedure FresnelCoefficients;   { Френелевские коэффициенты (p-p) }
  var
    i: Integer;
    c: Single;
    a1: TComplex;
  begin
    c := 2 * Pi / Lambda; {другое волновое число }
    for i := 0 to Length(ALayers) - 1 do
      begin
        a1 := SqrtZ(AddZR(ALayers[i].e, -sqr_sin_t));
        ALayers[i].K := MulRZ(c, a1);
      end;
  end;

begin
  c := 4 * Pi / Lambda; { волновое число }
  t := Pi / 2 - Pi * t / 180;

  sin_t := sin(t); cos_t := cos(t); sqr_sin_t := sqr(sin_t);

  FresnelCoefficients;
  LayerAmplitudeRefractionS;
  Rs := TotalRecursiveRefraction;

  if Pol = cmSP then
  begin
    LayerAmplitudeRefractionP;
    Rp := TotalRecursiveRefraction;
    Rsp := (Rs + Rp) / 2;
    Result := Rsp;
  end
  else
    Result := Rs;
end;

end.
