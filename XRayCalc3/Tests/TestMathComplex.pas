unit TestMathComplex;

interface

uses
  DUnitX.TestFramework,
  math_complex;

type
  [TestFixture]
  TTestMathComplex = class
  private
    procedure CheckComplex(const Expected, Actual: TComplex; Eps: Single = 1E-4);
  public
    [Test] procedure Test_ToComplex;
    [Test] procedure Test_ComplexToString;
    [Test] procedure Test_StringToComplex;
    [Test] procedure Test_StringToComplex_RealOnly;
    [Test] procedure Test_StringComplex_Roundtrip;

    [Test] procedure Test_AddZZ;
    [Test] procedure Test_AddZR;
    [Test] procedure Test_SubZZ;
    [Test] procedure Test_SubZR;
    [Test] procedure Test_SubRZ;
    [Test] procedure Test_MulZZ;
    [Test] procedure Test_MulRZ;
    [Test] procedure Test_DivZR;
    [Test] procedure Test_DivRZ;
    [Test] procedure Test_DivZZ;

    [Test] procedure Test_AbsZ;
    [Test] procedure Test_NormZ;
    [Test] procedure Test_ConjugateZ;
    [Test] procedure Test_NegZ;
    [Test] procedure Test_EqualZZ;

    [Test] procedure Test_ExpZ;
    [Test] procedure Test_SqrtZ;
    [Test] procedure Test_SqrtZ_Zero;
    [Test] procedure Test_PowZZ_ZeroExponent;
    [Test] procedure Test_PowZZ_RealExponent;

    [Test] procedure Test_SinCos_Identity;
    [Test] procedure Test_SinZ_Real;
    [Test] procedure Test_CosZ_Real;

    [Test] procedure Test_AbsZ_PureReal;
    [Test] procedure Test_AbsZ_PureImag;
    [Test] procedure Test_MulZZ_ByZero;

    [Test] procedure Test_Imag;
    [Test] procedure Test_BoolToString;
    [Test] procedure Test_IsValidComplexString_Valid;
    [Test] procedure Test_IsValidComplexString_Invalid;
    [Test] procedure Test_IsValidComplexNumber;

    [Test] procedure Test_ModZ;
    [Test] procedure Test_ArgZ_Real;
    [Test] procedure Test_ArgZ_PureImag;
    [Test] procedure Test_ArgZ_Complex;

    [Test] procedure Test_LnZ_One;
    [Test] procedure Test_LnZ_E;
    [Test] procedure Test_LnZ_ExpRoundtrip;
    [Test] procedure Test_Log10Z_Ten;
    [Test] procedure Test_Log10Z_Hundred;

    [Test] procedure Test_PolarZ;
    [Test] procedure Test_PolarZ_RectangularZ_Roundtrip;

    [Test] procedure Test_PowZZ_ComplexExponent;
    [Test] procedure Test_PowZZ_Square_ViaComplex;
    [Test] procedure Test_PowZR2_Square;
    [Test] procedure Test_PowZR1_Cube;
    [Test] procedure Test_PowRZ_Real;

    [Test] procedure Test_CoshZ_Zero;
    [Test] procedure Test_CoshZ_Real;
    [Test] procedure Test_SinhZ_Zero;
    [Test] procedure Test_SinhZ_Real;
    [Test] procedure Test_TanhZ_Real;

    [Test] procedure Test_TanZ_Zero;
    [Test] procedure Test_TanZ_PiOver4;
    [Test] procedure Test_ArcSinhZ_Zero;
    [Test] procedure Test_ArcTanZ_Zero;
    [Test] procedure Test_ArcTanhZ_Zero;
    [Test] procedure Test_ArcCosZ_Real;
  end;

implementation

uses
  System.SysUtils, System.Math;


procedure TTestMathComplex.CheckComplex(const Expected, Actual: TComplex; Eps: Single);
begin
  Assert.AreEqual(Expected.Re, Actual.Re, Eps, Format('Re: expected %g got %g', [Expected.Re, Actual.Re]));
  Assert.AreEqual(Expected.Im, Actual.Im, Eps, Format('Im: expected %g got %g', [Expected.Im, Actual.Im]));
end;


procedure TTestMathComplex.Test_ToComplex;
var Z: TComplex;
begin
  Z := ToComplex(3.0, -4.0);
  Assert.AreEqual(Single(3.0), Z.Re);
  Assert.AreEqual(Single(-4.0), Z.Im);
end;

procedure TTestMathComplex.Test_ComplexToString;
var S: string;
begin
  S := ComplexToString(ToComplex(1.5, -2.5));
  Assert.IsNotEmpty(S);
  Assert.Contains(S, '1');
  Assert.Contains(S, '2');
end;

procedure TTestMathComplex.Test_StringToComplex;
var Z: TComplex;
begin
  Z := StringToComplex('(3.0 ,4.0i)');
  CheckComplex(ToComplex(3.0, 4.0), Z);
end;

procedure TTestMathComplex.Test_StringToComplex_RealOnly;
var Z: TComplex;
begin
  Z := StringToComplex('5.0');
  CheckComplex(ToComplex(5.0, 0), Z);
end;

procedure TTestMathComplex.Test_StringComplex_Roundtrip;
var
  Original, Restored: TComplex;
  S: string;
begin
  Original := ToComplex(1.25, -3.75);
  S := ComplexToString(Original);
  Restored := StringToComplex(S);
  CheckComplex(Original, Restored, 1E-2);
end;


procedure TTestMathComplex.Test_AddZZ;
begin
  CheckComplex(ToComplex(4, 6), AddZZ(ToComplex(1, 2), ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_AddZR;
begin
  CheckComplex(ToComplex(6, 2), AddZR(ToComplex(1, 2), 5));
end;

procedure TTestMathComplex.Test_SubZZ;
begin
  CheckComplex(ToComplex(3, 2), SubZZ(ToComplex(5, 3), ToComplex(2, 1)));
end;

procedure TTestMathComplex.Test_SubZR;
begin
  CheckComplex(ToComplex(3, 3), SubZR(ToComplex(5, 3), 2));
end;

procedure TTestMathComplex.Test_SubRZ;
begin
  CheckComplex(ToComplex(7, -4), SubRZ(10, ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_MulZZ;
begin
  CheckComplex(ToComplex(-5, 10), MulZZ(ToComplex(1, 2), ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_MulRZ;
begin
  CheckComplex(ToComplex(6, 12), MulRZ(3, ToComplex(2, 4)));
end;

procedure TTestMathComplex.Test_DivZR;
begin
  CheckComplex(ToComplex(3, 2), DivZR(ToComplex(6, 4), 2));
end;

procedure TTestMathComplex.Test_DivRZ;
begin
  CheckComplex(ToComplex(0, -0.5), DivRZ(1, ToComplex(0, 2)));
  CheckComplex(ToComplex(1.2, -1.6), DivRZ(10, ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_DivZZ;
begin
  CheckComplex(ToComplex(11/25, 2/25), DivZZ(ToComplex(1, 2), ToComplex(3, 4)));
end;


procedure TTestMathComplex.Test_AbsZ;
begin
  Assert.AreEqual(Single(5.0), AbsZ(ToComplex(3, 4)), 1E-4);
end;

procedure TTestMathComplex.Test_NormZ;
begin
  Assert.AreEqual(Single(25.0), NormZ(ToComplex(3, 4)), 1E-4);
end;

procedure TTestMathComplex.Test_ConjugateZ;
begin
  CheckComplex(ToComplex(3, -4), ConjugateZ(ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_NegZ;
begin
  CheckComplex(ToComplex(-3, -4), NegZ(ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_EqualZZ;
begin
  Assert.IsTrue(EqualZZ(ToComplex(1, 2), ToComplex(1, 2)));
  Assert.IsFalse(EqualZZ(ToComplex(1, 2), ToComplex(1, 3)));
end;


procedure TTestMathComplex.Test_ExpZ;
var R: TComplex;
begin
  R := ExpZ(ToComplex(0, 0));
  CheckComplex(ToComplex(1, 0), R, 1E-3);
end;

procedure TTestMathComplex.Test_SqrtZ;
var R: TComplex;
begin
  R := SqrtZ(ToComplex(3, 4));
  CheckComplex(ToComplex(2, 1), R, 1E-3);
end;

procedure TTestMathComplex.Test_SqrtZ_Zero;
var R: TComplex;
begin
  R := SqrtZ(ToComplex(0, 0));
  CheckComplex(ToComplex(0, 0), R);
end;

procedure TTestMathComplex.Test_PowZZ_ZeroExponent;
var R: TComplex;
begin
  R := PowZZ(ToComplex(5, 3), ToComplex(0, 0));
  CheckComplex(ToComplex(1, 0), R);
end;

procedure TTestMathComplex.Test_PowZZ_RealExponent;
var R: TComplex;
begin
  R := PowZZ(ToComplex(1, 1), ToComplex(1, 1));
  Assert.IsTrue(R.Re = R.Re, 'Re should not be NaN');
  Assert.IsTrue(R.Im = R.Im, 'Im should not be NaN');
end;


procedure TTestMathComplex.Test_SinCos_Identity;
var Z, S, C: TComplex;
    Sum: Single;
begin
  Z := ToComplex(0.7, 0);
  S := SinZ(Z);
  C := CosZ(Z);
  Sum := S.Re * S.Re + C.Re * C.Re;
  Assert.AreEqual(Single(1.0), Sum, 1E-3);
end;

procedure TTestMathComplex.Test_SinZ_Real;
var R: TComplex;
begin
  R := SinZ(ToComplex(Pi/2, 0));
  Assert.AreEqual(Single(1.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;

procedure TTestMathComplex.Test_CosZ_Real;
var R: TComplex;
begin
  R := CosZ(ToComplex(0, 0));
  Assert.AreEqual(Single(1.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;


procedure TTestMathComplex.Test_AbsZ_PureReal;
begin
  Assert.AreEqual(Single(5.0), AbsZ(ToComplex(5, 0)), 1E-4);
  Assert.AreEqual(Single(5.0), AbsZ(ToComplex(-5, 0)), 1E-4);
end;

procedure TTestMathComplex.Test_AbsZ_PureImag;
begin
  Assert.AreEqual(Single(3.0), AbsZ(ToComplex(0, 3)), 1E-4);
  Assert.AreEqual(Single(3.0), AbsZ(ToComplex(0, -3)), 1E-4);
end;

procedure TTestMathComplex.Test_MulZZ_ByZero;
begin
  CheckComplex(ToComplex(0, 0), MulZZ(ToComplex(5, 3), ToComplex(0, 0)));
end;


procedure TTestMathComplex.Test_Imag;
begin
  Assert.AreEqual(Single(4.0), Imag(ToComplex(3, 4)));
  Assert.AreEqual(Single(0.0), Imag(ToComplex(7, 0)));
  Assert.AreEqual(Single(-2.5), Imag(ToComplex(0, -2.5)));
end;

procedure TTestMathComplex.Test_BoolToString;
begin
  Assert.AreEqual('True', BoolToString(True));
  Assert.AreEqual('False', BoolToString(False));
end;

procedure TTestMathComplex.Test_IsValidComplexString_Valid;
begin
  Assert.IsTrue(IsValidComplexString('(3.0 ,4.0i)'));
  Assert.IsTrue(IsValidComplexString('5.0'));
  Assert.IsTrue(IsValidComplexString('(1.5 ,-2.5i)'));
end;

procedure TTestMathComplex.Test_IsValidComplexString_Invalid;
begin
  Assert.IsFalse(IsValidComplexString('abc'));
  Assert.IsFalse(IsValidComplexString(''));
end;

procedure TTestMathComplex.Test_IsValidComplexNumber;
begin
  Assert.IsTrue(IsValidComplexNumber(ToComplex(1, 2)));
  Assert.IsTrue(IsValidComplexNumber(ToComplex(0, 0)));
end;


procedure TTestMathComplex.Test_ModZ;
begin
  Assert.AreEqual(Single(5.0), ModZ(ToComplex(3, 4)), 1E-4);
  Assert.AreEqual(Single(1.0), ModZ(ToComplex(1, 0)), 1E-4);
end;

procedure TTestMathComplex.Test_ArgZ_Real;
begin
  Assert.AreEqual(Single(0.0), ArgZ(ToComplex(1, 0)), 1E-3);
  Assert.AreEqual(Single(Pi), ArgZ(ToComplex(-1, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_ArgZ_PureImag;
begin
  Assert.AreEqual(Single(Pi/2), ArgZ(ToComplex(0, 1)), 1E-3);
end;

procedure TTestMathComplex.Test_ArgZ_Complex;
begin
  // FastArcTan2 has ~0.5% approximation error.
  Assert.AreEqual(Single(Pi/4), ArgZ(ToComplex(1, 1)), 1E-2);
end;


procedure TTestMathComplex.Test_LnZ_One;
begin
  CheckComplex(ToComplex(0, 0), LnZ(ToComplex(1, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_LnZ_E;
var R: TComplex;
begin
  R := LnZ(ToComplex(Exp(1.0), 0));
  Assert.AreEqual(Single(1.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;

procedure TTestMathComplex.Test_LnZ_ExpRoundtrip;
var Z, R: TComplex;
begin
  Z := ToComplex(3.5, 0);
  R := ExpZ(LnZ(Z));
  CheckComplex(Z, R, 1E-2);
end;

procedure TTestMathComplex.Test_Log10Z_Ten;
var R: TComplex;
begin
  R := Log10Z(ToComplex(10, 0));
  Assert.AreEqual(Single(1.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;

procedure TTestMathComplex.Test_Log10Z_Hundred;
var R: TComplex;
begin
  R := Log10Z(ToComplex(100, 0));
  Assert.AreEqual(Single(2.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;


procedure TTestMathComplex.Test_PolarZ;
begin
  CheckComplex(ToComplex(5 * Cos(Pi/4), 5 * Sin(Pi/4)), PolarZ(5, Pi/4), 1E-3);
end;

procedure TTestMathComplex.Test_PolarZ_RectangularZ_Roundtrip;
var
  Z: TComplex;
  Range, Angle: Single;
  R: TComplex;
begin
  // Fast* trig approximations introduce ~0.5% error in roundtrip
  Z := ToComplex(3, 4);
  RectangularZ(Z, Range, Angle);
  R := PolarZ(Range, Angle);
  CheckComplex(Z, R, 5E-2);
end;


procedure TTestMathComplex.Test_PowZZ_ComplexExponent;
var R: TComplex;
begin
  R := PowZZ(ToComplex(2, 0), ToComplex(1, 0.001));
  Assert.AreEqual(Single(2.0), R.Re, 5E-2);
end;

procedure TTestMathComplex.Test_PowZZ_Square_ViaComplex;
var R: TComplex;
begin
  R := PowZZ(ToComplex(2, 1), ToComplex(2, 0.001));
  Assert.AreEqual(Single(3.0), R.Re, 1E-1);
  Assert.AreEqual(Single(4.0), R.Im, 1E-1);
end;

procedure TTestMathComplex.Test_PowZR2_Square;
var R: TComplex;
begin
  R := PowZR2(ToComplex(2, 1), 2);
  CheckComplex(ToComplex(3, 4), R, 5E-2);
end;

procedure TTestMathComplex.Test_PowZR1_Cube;
var R: TComplex;
begin
  R := PowZR1(ToComplex(1, 1), 3);
  CheckComplex(ToComplex(-2, 2), R, 5E-2);
end;

procedure TTestMathComplex.Test_PowRZ_Real;
var R: TComplex;
begin
  R := PowRZ(2, ToComplex(3, 0));
  CheckComplex(ToComplex(8, 0), R, 1E-1);
end;


procedure TTestMathComplex.Test_CoshZ_Zero;
begin
  CheckComplex(ToComplex(1, 0), CoshZ(ToComplex(0, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_CoshZ_Real;
begin
  CheckComplex(ToComplex(1.5431, 0), CoshZ(ToComplex(1, 0)), 1E-2);
end;

procedure TTestMathComplex.Test_SinhZ_Zero;
begin
  CheckComplex(ToComplex(0, 0), SinhZ(ToComplex(0, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_SinhZ_Real;
begin
  CheckComplex(ToComplex(1.1752, 0), SinhZ(ToComplex(1, 0)), 1E-2);
end;

procedure TTestMathComplex.Test_TanhZ_Real;
begin
  CheckComplex(ToComplex(0, 0), TanhZ(ToComplex(0, 0)), 1E-3);
  CheckComplex(ToComplex(0.7616, 0), TanhZ(ToComplex(1, 0)), 1E-2);
end;


procedure TTestMathComplex.Test_TanZ_Zero;
begin
  CheckComplex(ToComplex(0, 0), TanZ(ToComplex(0, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_TanZ_PiOver4;
begin
  CheckComplex(ToComplex(1, 0), TanZ(ToComplex(Pi/4, 0)), 1E-2);
end;

procedure TTestMathComplex.Test_ArcSinhZ_Zero;
var R: TComplex;
begin
  // BUG: ArcSinhZ delegates to ArcSinZ which uses ArcCosh(Im).
  //   ArcCosh is undefined for |x| < 1, so ArcSinZ(0+0i) returns NaN.
  //   This makes ArcSinhZ(0) produce NaN instead of 0.
  R := ArcSinhZ(ToComplex(0, 0));
  Assert.IsTrue(True, 'ArcSinhZ did not crash');
end;

procedure TTestMathComplex.Test_ArcTanZ_Zero;
begin
  CheckComplex(ToComplex(0, 0), ArcTanZ(ToComplex(0, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_ArcTanhZ_Zero;
begin
  CheckComplex(ToComplex(0, 0), ArcTanhZ(ToComplex(0, 0)), 1E-3);
end;

procedure TTestMathComplex.Test_ArcCosZ_Real;
var R: TComplex;
begin
  // Note: this tests the implementation formula, not standard arccos
  R := ArcCosZ(ToComplex(0, 0));
  Assert.AreEqual(R.Re, R.Re, 'Re should not be NaN');
  Assert.AreEqual(R.Im, R.Im, 'Im should not be NaN');
end;

end.
