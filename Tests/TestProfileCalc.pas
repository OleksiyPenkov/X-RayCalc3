unit TestProfileCalc;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestProfileCalc = class
  public
    [Test] procedure Test_Erf_ZeroSigma_ReturnsZero;
    [Test] procedure Test_Erf_Midpoint_ReturnsHalf;
    [Test] procedure Test_Erf_LargePositive_ApproachesOne;
    [Test] procedure Test_Erf_LargeNegative_ApproachesZero;
    [Test] procedure Test_Erf_Symmetry;
  end;

implementation

uses
  unit_ProfileCalc, System.Math;

procedure TTestProfileCalc.Test_Erf_ZeroSigma_ReturnsZero;
begin
  // sigma~0 is degenerate; test with very small sigma at x=0
  Assert.AreEqual(Single(0), Erf(0.001, 0), 0.01, 'Near-zero sigma at x=0');
end;

procedure TTestProfileCalc.Test_Erf_Midpoint_ReturnsHalf;
begin
  Assert.AreEqual(Single(0.5), Erf(3.0, 0), 0.05, 'Midpoint ~0.5');
end;

procedure TTestProfileCalc.Test_Erf_LargePositive_ApproachesOne;
begin
  Assert.IsTrue(Erf(3.0, 20.0) > 0.95, 'Large positive xmax approaches 1.0');
end;

procedure TTestProfileCalc.Test_Erf_LargeNegative_ApproachesZero;
begin
  Assert.IsTrue(Erf(3.0, -20.0) < 0.05, 'Large negative xmax approaches 0.0');
end;

procedure TTestProfileCalc.Test_Erf_Symmetry;
var
  a, b: Single;
begin
  a := Erf(3.0, 5.0);
  b := Erf(3.0, -5.0);
  Assert.AreEqual(Single(1.0), a + b, 0.05, 'Symmetry: Erf(s,x) + Erf(s,-x) ~ 1');
end;

end.
