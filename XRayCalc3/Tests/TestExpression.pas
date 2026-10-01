unit TestExpression;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestExpression = class
  public
    [Test] procedure Precedence;
    [Test] procedure UnaryMinusAndPower;
    [Test] procedure Functions;
    [Test] procedure DottedNames;
    [Test] procedure Numbers;
    [Test] procedure DivisionByZero_IsInfinite_NotRaised;
    [Test] procedure LnOfNegative_IsNaN_NotRaised;
    [Test] procedure UnknownName_RaisesWithPosition;
    [Test] procedure SyntaxErrors_Raise;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Expression;

function Eval(const Text: string; const Names: array of string;
  const Values: array of Double): Double;
var
  E: TExpression;
begin
  E := TExpression.Create(Text, Names);
  try
    Result := E.Evaluate(Values);
  finally
    E.Free;
  end;
end;

procedure TTestExpression.Precedence;
begin
  Assert.AreEqual(7.0, Eval('1 + 2 * 3', [], []), 1E-12);
  Assert.AreEqual(9.0, Eval('(1 + 2) * 3', [], []), 1E-12);
  Assert.AreEqual(2.0, Eval('8 / 2 / 2', [], []), 1E-12, 'left-associative');
  Assert.AreEqual(512.0, Eval('2 ^ 3 ^ 2', [], []), 1E-9, 'right-associative');
end;

procedure TTestExpression.UnaryMinusAndPower;
begin
  Assert.AreEqual(-4.0, Eval('-2^2', [], []), 1E-12);
  Assert.AreEqual(0.25, Eval('2^-2', [], []), 1E-12);
  Assert.AreEqual(5.0, Eval('--5', [], []), 1E-12);
  Assert.AreEqual(-1.0, Eval('3 - -2 * -2', [], []), 1E-12);
end;

procedure TTestExpression.Functions;
begin
  Assert.AreEqual(3.0, Eval('sqrt(9)', [], []), 1E-12);
  Assert.AreEqual(2.5, Eval('ABS(-2.5)', [], []), 1E-12);
  Assert.AreEqual(1.0, Eval('ln(exp(1))', [], []), 1E-12);
end;

procedure TTestExpression.DottedNames;
begin
  Assert.AreEqual(2.5, Eval('s0.l1.thickness - s0.l3.thickness',
    ['s0.l1.thickness', 's0.l3.thickness'], [6.0, 3.5]), 1E-12);
  Assert.AreEqual(6 / 3.5, Eval('s0.l1.thickness / s0.l3.thickness',
    ['s0.l1.thickness', 's0.l3.thickness'], [6.0, 3.5]), 1E-12);
  Assert.AreEqual(0.1, Eval('c0.f', ['c0.f'], [0.1]), 1E-12);
end;

procedure TTestExpression.Numbers;
begin
  Assert.AreEqual(1500.0, Eval('1.5e3', [], []), 1E-9);
  Assert.AreEqual(0.02, Eval('2E-2', [], []), 1E-15);
  Assert.AreEqual(0.5, Eval('.5', [], []), 1E-15);
end;

procedure TTestExpression.DivisionByZero_IsInfinite_NotRaised;
var
  V: Double;
begin
  V := Eval('1 / x', ['x'], [0.0]);
  Assert.IsTrue(IsInfinite(V));
end;

procedure TTestExpression.LnOfNegative_IsNaN_NotRaised;
begin
  Assert.IsTrue(IsNan(Eval('ln(x)', ['x'], [-1.0])));
end;

procedure TTestExpression.UnknownName_RaisesWithPosition;
var
  Raised: Boolean;
begin
  Raised := False;
  try
    TExpression.Create('a + bb', ['a']).Free;
  except
    on E: EExpression do
    begin
      Raised := True;
      Assert.AreEqual(5, E.Position);
      Assert.Contains(E.Message, 'bb');
    end;
  end;
  Assert.IsTrue(Raised);
end;

procedure TTestExpression.SyntaxErrors_Raise;
const
  Bad: array [0 .. 6] of string = ('', '1 +', '(1 + 2', '1 2', 'sqrt 4', '2 ** 3', 'foo(1)');
var
  S: string;
begin
  for S in Bad do
    Assert.WillRaise(procedure begin TExpression.Create(S, []).Free end, EExpression, S);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestExpression);

end.
