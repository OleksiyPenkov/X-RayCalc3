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

    { CopyData }
    [Test] procedure Test_CopyData_Empty;
    [Test] procedure Test_CopyData_Values;

    { FuncProfile }
    [Test] procedure Test_FuncProfile_Poly;
    [Test] procedure Test_FuncProfile_None;

    { Poly with TFuncProfileRec overload }
    [Test] procedure Test_Poly_FuncProfileRec;
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

{ --- CopyData --- }

procedure TTestMathGlobals.Test_CopyData_Empty;
var
  Src, Dst: TDataArray;
begin
  SetLength(Src, 0);
  CopyData(Src, Dst);
  Assert.AreEqual(0, Length(Dst));
end;

procedure TTestMathGlobals.Test_CopyData_Values;
var
  Src, Dst: TDataArray;
begin
  SetLength(Src, 2);
  Src[0].t := 1.5; Src[0].r := 2.5;
  Src[1].t := 3.0; Src[1].r := 4.0;
  CopyData(Src, Dst);
  Assert.AreEqual(2, Length(Dst));
  Assert.AreEqual(Single(1.5), Dst[0].t, 1E-5);
  Assert.AreEqual(Single(2.5), Dst[0].r, 1E-5);
  Assert.AreEqual(Single(3.0), Dst[1].t, 1E-5);
  Assert.AreEqual(Single(4.0), Dst[1].r, 1E-5);
end;

{ --- FuncProfile --- }

procedure TTestMathGlobals.Test_FuncProfile_Poly;
var
  FP: TFuncProfileRec;
begin
  // FuncProfile with ffPoly dispatches to Poly(x, FP)
  // P(x) = 5 + 2*(x-1) -> P(3) = 5 + 2*2 = 9
  FP.Func := ffPoly;
  SetLength(FP.C, 2);
  FP.C[0] := 5;
  FP.C[1] := 2;
  Assert.AreEqual(Single(9), FuncProfile(3, FP), 1E-5);
end;

procedure TTestMathGlobals.Test_FuncProfile_None;
var
  FP: TFuncProfileRec;
begin
  // Non-poly function forms return 0
  FP.Func := ffNone;
  SetLength(FP.C, 1);
  FP.C[0] := 99;
  Assert.AreEqual(Single(0), FuncProfile(1, FP), 1E-5);
end;

{ --- Poly(x, FuncProfileRec) overload --- }

procedure TTestMathGlobals.Test_Poly_FuncProfileRec;
var
  FP: TFuncProfileRec;
begin
  // P(x) = 3 + 1*(x-1) -> P(4) = 3 + 3 = 6
  FP.Func := ffPoly;
  SetLength(FP.C, 2);
  FP.C[0] := 3;
  FP.C[1] := 1;
  Assert.AreEqual(Single(6), Poly(4, FP), 1E-5);
end;

end.
