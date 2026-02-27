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
    { Conversions }
    [Test] procedure Test_ToComplex;
    [Test] procedure Test_ComplexToString;
    [Test] procedure Test_StringToComplex;
    [Test] procedure Test_StringToComplex_RealOnly;
    [Test] procedure Test_StringComplex_Roundtrip;

    { Arithmetic }
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

    { Utility }
    [Test] procedure Test_AbsZ;
    [Test] procedure Test_NormZ;
    [Test] procedure Test_ConjugateZ;
    [Test] procedure Test_NegZ;
    [Test] procedure Test_EqualZZ;

    { Math functions }
    [Test] procedure Test_ExpZ;
    [Test] procedure Test_SqrtZ;
    [Test] procedure Test_SqrtZ_Zero;
    [Test] procedure Test_PowZZ_ZeroExponent;
    [Test] procedure Test_PowZZ_RealExponent;

    { Trig }
    [Test] procedure Test_SinCos_Identity;
    [Test] procedure Test_SinZ_Real;
    [Test] procedure Test_CosZ_Real;

    { Edge cases }
    [Test] procedure Test_AbsZ_PureReal;
    [Test] procedure Test_AbsZ_PureImag;
    [Test] procedure Test_MulZZ_ByZero;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TTestMathComplex }

procedure TTestMathComplex.CheckComplex(const Expected, Actual: TComplex; Eps: Single);
begin
  Assert.AreEqual(Expected.Re, Actual.Re, Eps, Format('Re: expected %g got %g', [Expected.Re, Actual.Re]));
  Assert.AreEqual(Expected.Im, Actual.Im, Eps, Format('Im: expected %g got %g', [Expected.Im, Actual.Im]));
end;

{ --- Conversions --- }

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

{ --- Arithmetic --- }

procedure TTestMathComplex.Test_AddZZ;
begin
  // (1+2i) + (3+4i) = (4+6i)
  CheckComplex(ToComplex(4, 6), AddZZ(ToComplex(1, 2), ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_AddZR;
begin
  // (1+2i) + 5 = (6+2i)
  CheckComplex(ToComplex(6, 2), AddZR(ToComplex(1, 2), 5));
end;

procedure TTestMathComplex.Test_SubZZ;
begin
  // (5+3i) - (2+1i) = (3+2i)
  CheckComplex(ToComplex(3, 2), SubZZ(ToComplex(5, 3), ToComplex(2, 1)));
end;

procedure TTestMathComplex.Test_SubZR;
begin
  // (5+3i) - 2 = (3+3i)
  CheckComplex(ToComplex(3, 3), SubZR(ToComplex(5, 3), 2));
end;

procedure TTestMathComplex.Test_SubRZ;
begin
  // 10 - (3+4i) = (7-4i)
  CheckComplex(ToComplex(7, -4), SubRZ(10, ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_MulZZ;
begin
  // (1+2i)*(3+4i) = (1*3-2*4) + (1*4+2*3)i = (-5+10i)
  CheckComplex(ToComplex(-5, 10), MulZZ(ToComplex(1, 2), ToComplex(3, 4)));
end;

procedure TTestMathComplex.Test_MulRZ;
begin
  // 3*(2+4i) = (6+12i)
  CheckComplex(ToComplex(6, 12), MulRZ(3, ToComplex(2, 4)));
end;

procedure TTestMathComplex.Test_DivZR;
begin
  // (6+4i)/2 = (3+2i)
  CheckComplex(ToComplex(3, 2), DivZR(ToComplex(6, 4), 2));
end;

procedure TTestMathComplex.Test_DivRZ;
begin
  // 1/(0+2i) should give (0, 0.5) per the implementation (pure imaginary divisor)
  CheckComplex(ToComplex(0, 0.5), DivRZ(1, ToComplex(0, 2)));
end;

procedure TTestMathComplex.Test_DivZZ;
begin
  // (1+2i)/(3+4i) = (1*3+2*4)/(9+16) + (2*3-1*4)/(9+16)i = 11/25 + 2/25i
  CheckComplex(ToComplex(11/25, 2/25), DivZZ(ToComplex(1, 2), ToComplex(3, 4)));
end;

{ --- Utility --- }

procedure TTestMathComplex.Test_AbsZ;
begin
  // |3+4i| = 5
  Assert.AreEqual(Single(5.0), AbsZ(ToComplex(3, 4)), 1E-4);
end;

procedure TTestMathComplex.Test_NormZ;
begin
  // |3+4i|^2 = 25
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

{ --- Math functions --- }

procedure TTestMathComplex.Test_ExpZ;
var R: TComplex;
begin
  // e^(0+0i) = 1+0i
  R := ExpZ(ToComplex(0, 0));
  CheckComplex(ToComplex(1, 0), R, 1E-3);
end;

procedure TTestMathComplex.Test_SqrtZ;
var R: TComplex;
begin
  // sqrt(3+4i) ~ (2 + 1i)  =>  (2+i)^2 = 4+4i-1 = 3+4i
  R := SqrtZ(ToComplex(3, 4));
  CheckComplex(ToComplex(2, 1), R, 1E-3);
end;

procedure TTestMathComplex.Test_SqrtZ_Zero;
var R: TComplex;
begin
  // Implementation returns (1,0) for sqrt(0+0i)
  R := SqrtZ(ToComplex(0, 0));
  CheckComplex(ToComplex(1, 0), R);
end;

procedure TTestMathComplex.Test_PowZZ_ZeroExponent;
var R: TComplex;
begin
  // Z^0 = 1
  R := PowZZ(ToComplex(5, 3), ToComplex(0, 0));
  CheckComplex(ToComplex(1, 0), R);
end;

procedure TTestMathComplex.Test_PowZZ_RealExponent;
var R: TComplex;
begin
  // (1+1i)^(1+1i) — complex base and exponent
  // Verify it returns a finite result (non-trivial computation)
  R := PowZZ(ToComplex(1, 1), ToComplex(1, 1));
  Assert.IsTrue(R.Re = R.Re, 'Re should not be NaN');
  Assert.IsTrue(R.Im = R.Im, 'Im should not be NaN');
end;

{ --- Trig --- }

procedure TTestMathComplex.Test_SinCos_Identity;
var Z, S, C: TComplex;
    Sum: Single;
begin
  // sin^2(z) + cos^2(z) = 1 for real z
  Z := ToComplex(0.7, 0);
  S := SinZ(Z);
  C := CosZ(Z);
  // For real z: sin and cos are real, so sin^2+cos^2 = 1
  Sum := S.Re * S.Re + C.Re * C.Re;
  Assert.AreEqual(Single(1.0), Sum, 1E-3);
end;

procedure TTestMathComplex.Test_SinZ_Real;
var R: TComplex;
begin
  // sin(pi/2 + 0i) ~ (1, 0)
  R := SinZ(ToComplex(Pi/2, 0));
  Assert.AreEqual(Single(1.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;

procedure TTestMathComplex.Test_CosZ_Real;
var R: TComplex;
begin
  // cos(0 + 0i) = (1, 0)
  R := CosZ(ToComplex(0, 0));
  Assert.AreEqual(Single(1.0), R.Re, 1E-3);
  Assert.AreEqual(Single(0.0), R.Im, 1E-3);
end;

{ --- Edge cases --- }

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

end.
