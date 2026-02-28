unit TestProfileCalc;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestProfileCalc = class
  private
    function MakeStacks(N: Integer; LayerH, LayerS, LayerR: Single): TStacksData;
  public
    [Test] procedure Test_Erf_ZeroSigma_ReturnsZero;
    [Test] procedure Test_Erf_Midpoint_ReturnsHalf;
    [Test] procedure Test_Erf_LargePositive_ApproachesOne;
    [Test] procedure Test_Erf_LargeNegative_ApproachesZero;
    [Test] procedure Test_Erf_Symmetry;
    [Test] procedure Test_GetLayerVal_ReturnsP_WhenPPEmpty;
    [Test] procedure Test_GetLayerVal_ReturnsPP_WhenPPHasData;
    [Test] procedure Test_GetLayerVal_ReturnsP_WhenPPSingleElement;
  end;

implementation

uses
  unit_ProfileCalc, unit_Types, System.Math;

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

function TTestProfileCalc.MakeStacks(N: Integer; LayerH, LayerS, LayerR: Single): TStacksData;
begin
  SetLength(Result, 1);
  Result[0].N := N;
  SetLength(Result[0].Layers, 1);
  Result[0].Layers[0].P[1].V := LayerH;
  Result[0].Layers[0].P[2].V := LayerS;
  Result[0].Layers[0].P[3].V := LayerR;
end;

procedure TTestProfileCalc.Test_GetLayerVal_ReturnsP_WhenPPEmpty;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  Assert.AreEqual(Single(10.0), GetLayerVal(S, 0, 0, 1, 1), 'H from P');
  Assert.AreEqual(Single(2.0),  GetLayerVal(S, 0, 0, 1, 2), 'S from P');
  Assert.AreEqual(Single(5.0),  GetLayerVal(S, 0, 0, 1, 3), 'R from P');
end;

procedure TTestProfileCalc.Test_GetLayerVal_ReturnsPP_WhenPPHasData;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0, 13.0);
  Assert.AreEqual(Single(11.0), GetLayerVal(S, 0, 0, 1, 1), 'Period 1');
  Assert.AreEqual(Single(12.0), GetLayerVal(S, 0, 0, 2, 1), 'Period 2');
  Assert.AreEqual(Single(13.0), GetLayerVal(S, 0, 0, 3, 1), 'Period 3');
end;

procedure TTestProfileCalc.Test_GetLayerVal_ReturnsP_WhenPPSingleElement;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(99.0);
  Assert.AreEqual(Single(10.0), GetLayerVal(S, 0, 0, 1, 1), 'Single PP falls back to P');
end;

end.
