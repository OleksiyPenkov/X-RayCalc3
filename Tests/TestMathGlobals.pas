unit TestMathGlobals;

interface

uses
  DUnitX.TestFramework,
  unit_types;

type
  [TestFixture]
  TTestMathGlobals = class
  public
    { Poly(x, C) - basic overload }
    [Test] procedure Test_Poly_Constant;
    [Test] procedure Test_Poly_Linear;
    [Test] procedure Test_Poly_Quadratic;

    { Poly(x, Min, Max, C) - clamped overload }
    [Test] procedure Test_PolyBounds_WithinRange;
    [Test] procedure Test_PolyBounds_ExceedsMax;
    [Test] procedure Test_PolyBounds_BelowMin;

    { Poly edge cases }
    [Test] procedure Test_Poly_AtX1;
    [Test] procedure Test_Poly_HighOrder;
  end;

implementation

uses
  math_globals;

{ TTestMathGlobals }

procedure TTestMathGlobals.Test_Poly_Constant;
var C: TPolyArray;
begin
  // P(x) = 5  (constant polynomial)
  SetLength(C, 1);
  C[0] := 5;
  Assert.AreEqual(Single(5), Poly(1, C), 1E-5);
  Assert.AreEqual(Single(5), Poly(10, C), 1E-5);
end;

procedure TTestMathGlobals.Test_Poly_Linear;
var C: TPolyArray;
begin
  // P(x) = 2 + 3*(x-1)
  // P(1) = 2, P(2) = 5, P(3) = 8
  SetLength(C, 2);
  C[0] := 2;
  C[1] := 3;
  Assert.AreEqual(Single(2), Poly(1, C), 1E-5);
  Assert.AreEqual(Single(5), Poly(2, C), 1E-5);
  Assert.AreEqual(Single(8), Poly(3, C), 1E-5);
end;

procedure TTestMathGlobals.Test_Poly_Quadratic;
var C: TPolyArray;
begin
  // P(x) = 1 + 0*(x-1) + 1*(x-1)^2
  // P(1) = 1, P(2) = 1+1 = 2, P(3) = 1+4 = 5
  SetLength(C, 3);
  C[0] := 1;
  C[1] := 0;
  C[2] := 1;
  Assert.AreEqual(Single(1), Poly(1, C), 1E-5);
  Assert.AreEqual(Single(2), Poly(2, C), 1E-5);
  Assert.AreEqual(Single(5), Poly(3, C), 1E-5);
end;

procedure TTestMathGlobals.Test_PolyBounds_WithinRange;
var C: TPolyArray;
begin
  // P(x) = 2 + 3*(x-1), within bounds
  SetLength(C, 2);
  C[0] := 2;
  C[1] := 3;
  // P(2) = 5, which is between 0 and 100
  Assert.AreEqual(Single(5), Poly(2, 0, 100, C), 1E-5);
end;

procedure TTestMathGlobals.Test_PolyBounds_ExceedsMax;
var
  C: TPolyArray;
  R: Single;
begin
  // P(x) = 10 + 100*(x-1): at x=2, P = 110 which exceeds Max=50
  // The function breaks early when result exceeds bounds
  SetLength(C, 2);
  C[0] := 10;
  C[1] := 100;
  R := Poly(2, 0, 50, C);
  // Function breaks when Result > Max, so it returns the out-of-bounds value
  // This tests that the bounds check fires (Result = 110 after computing)
  Assert.IsTrue(R >= 50);
end;

procedure TTestMathGlobals.Test_PolyBounds_BelowMin;
var
  C: TPolyArray;
  R: Single;
begin
  // P(x) = 10 + (-100)*(x-1): at x=2, P = -90 which is below Min=0
  SetLength(C, 2);
  C[0] := 10;
  C[1] := -100;
  R := Poly(2, 0, 50, C);
  Assert.IsTrue(R <= 0);
end;

procedure TTestMathGlobals.Test_Poly_AtX1;
var C: TPolyArray;
begin
  // At x=1, (x-1) = 0, so all higher terms vanish. P(1) = C[0]
  SetLength(C, 3);
  C[0] := 7;
  C[1] := 99;
  C[2] := 42;
  Assert.AreEqual(Single(7), Poly(1, C), 1E-5);
end;

procedure TTestMathGlobals.Test_Poly_HighOrder;
var C: TPolyArray;
begin
  // P(x) = 0 + 0 + 0 + 1*(x-1)^3
  // P(3) = 1 * (2)^3 = 8
  SetLength(C, 4);
  C[0] := 0;
  C[1] := 0;
  C[2] := 0;
  C[3] := 1;
  Assert.AreEqual(Single(8), Poly(3, C), 1E-4);
end;

end.
