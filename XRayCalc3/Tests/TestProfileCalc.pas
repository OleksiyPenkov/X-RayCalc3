unit TestProfileCalc;

interface

uses
  DUnitX.TestFramework, unit_Types, unit_ProfileCalc;

type
  [TestFixture]
  TTestProfileCalc = class
  private
    function MakeStacks(N: Integer; LayerH, LayerS, LayerR: Single): TStacksData;
    function MakeProfile(StackID, LayerID: Word; Subj: TParameterType;
      const C: array of Single): TFuncProfileRec;
  public
    [Test] procedure Test_Erf_ZeroSigma_ReturnsZero;
    [Test] procedure Test_Erf_Midpoint_ReturnsHalf;
    [Test] procedure Test_Erf_LargePositive_ApproachesOne;
    [Test] procedure Test_Erf_LargeNegative_ApproachesZero;
    [Test] procedure Test_Erf_Symmetry;
    [Test] procedure Test_ModelValue_ReturnsP_WhenPPEmpty;
    [Test] procedure Test_ModelValue_ReturnsPP_WhenExpanded;
    [Test] procedure Test_ModelValue_ReturnsP_WhenTablesNotExpanded;
    [Test] procedure Test_ModelValue_ReturnsP_WhenPaired;
    [Test] procedure Test_ModelValue_ReturnsP_WhenTableShorterThanN;
    [Test] procedure Test_ModelValue_ReturnsP_ForSinglePeriodStack;
    [Test] procedure Test_ModelValue_LastGradientWins;
    [Test] procedure Test_BuildLayers_SingleStackSingleLayer;
    [Test] procedure Test_BuildLayers_MultiPeriod;
    [Test] procedure Test_BuildLayers_MultiStack;
    [Test] procedure Test_BuildLayers_PPValues;
    [Test] procedure Test_BuildLayers_PPIgnoredWhenNotExpanded;
    [Test] procedure Test_BuildLayers_Gradient_ThicknessPerPeriod;
    [Test] procedure Test_BuildLayers_Gradient_CountsPeriodsInItsOwnStack;
    [Test] procedure Test_BuildLayers_Gradient_OverridesTable;
    [Test] procedure Test_CalcDensity_EmptyInput;
    [Test] procedure Test_CalcDensity_SingleLayer_MonotonicDepth;
    [Test] procedure Test_CalcDensity_ZeroRoughness_StepFunction;
    [Test] procedure Test_CalcDensity_WithRoughness_SmoothTransition;
    [Test] procedure Test_CalcDensity_RoughnessClamped;
    [Test] procedure Test_CalcDensity_SurfaceStartsNegative;
  end;

implementation

uses
  System.SysUtils, System.Math;

procedure TTestProfileCalc.Test_Erf_ZeroSigma_ReturnsZero;
begin
  // sigma~0 is degenerate; with small sigma the integration step dx=0.05
  // is large relative to sigma, so a small residual accumulates.
  // Test that result is close to zero (within integration error).
  Assert.AreEqual(Single(0), Erf(0.001, 0), 0.05, 'Near-zero sigma at x=0');
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

procedure TTestProfileCalc.Test_ModelValue_ReturnsP_WhenPPEmpty;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  Assert.AreEqual(Single(10.0), ModelValue(S, nil, 0, 0, 1, 1, True), 'H from P');
  Assert.AreEqual(Single(2.0),  ModelValue(S, nil, 0, 0, 1, 2, True), 'S from P');
  Assert.AreEqual(Single(5.0),  ModelValue(S, nil, 0, 0, 1, 3, True), 'R from P');
end;

procedure TTestProfileCalc.Test_ModelValue_ReturnsPP_WhenExpanded;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0, 13.0);
  Assert.AreEqual(Single(11.0), ModelValue(S, nil, 0, 0, 1, 1, True), 'Period 1');
  Assert.AreEqual(Single(12.0), ModelValue(S, nil, 0, 0, 2, 1, True), 'Period 2');
  Assert.AreEqual(Single(13.0), ModelValue(S, nil, 0, 0, 3, 1, True), 'Period 3');
end;

// A table left from an earlier irregular fit while the table extension is
// disabled or the fit is periodic: TXRCStructure.Model(False) calculates with
// P.V, so the plots must too.
procedure TTestProfileCalc.Test_ModelValue_ReturnsP_WhenTablesNotExpanded;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0, 13.0);
  Assert.AreEqual(Single(10.0), ModelValue(S, nil, 0, 0, 2, 1, False));
end;

// Model(True) keeps a paired parameter at P.V.
procedure TTestProfileCalc.Test_ModelValue_ReturnsP_WhenPaired;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0, 13.0);
  S[0].Layers[0].P[1].Paired := True;
  Assert.AreEqual(Single(10.0), ModelValue(S, nil, 0, 0, 2, 1, True));
end;

// A table made for N = 2 after N was raised to 3 is never read past its end;
// it is ignored as a whole, in every period.
procedure TTestProfileCalc.Test_ModelValue_ReturnsP_WhenTableShorterThanN;
var
  S: TStacksData;
  Period: Integer;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0);
  for Period := 1 to 3 do
    Assert.AreEqual(Single(10.0), ModelValue(S, nil, 0, 0, Period, 1, True),
      'period ' + Period.ToString);
end;

// Model expands tables for periodic stacks only.
procedure TTestProfileCalc.Test_ModelValue_ReturnsP_ForSinglePeriodStack;
var
  S: TStacksData;
begin
  S := MakeStacks(1, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(99.0);
  Assert.AreEqual(Single(10.0), ModelValue(S, nil, 0, 0, 1, 1, True));
end;

// PrepareLayers applies every gradient aimed at the parameter in turn, so two
// on one layer give the last one's values - on every plot as in the curve.
procedure TTestProfileCalc.Test_ModelValue_LastGradientWins;
var
  S: TStacksData;
  P: TProfileFunctions;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  P := [MakeProfile(0, 0, ptH, [20.0, 1.0]), MakeProfile(0, 0, ptH, [30.0, 2.0])];
  Assert.AreEqual(Single(30.0), ModelValue(S, P, 0, 0, 1, 1, False), 1E-5, 'period 1');
  Assert.AreEqual(Single(34.0), ModelValue(S, P, 0, 0, 3, 1, False), 1E-5, 'period 3');
end;

procedure TTestProfileCalc.Test_BuildLayers_SingleStackSingleLayer;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(1, 10.0, 2.0, 5.0);
  L := BuildLayers(S, True);
  Assert.AreEqual(1, Length(L));
  Assert.AreEqual(Single(10.0), L[0].h, 'h');
  Assert.AreEqual(Single(2.0),  L[0].s, 's');
  Assert.AreEqual(Single(5.0),  L[0].r, 'r');
end;

procedure TTestProfileCalc.Test_BuildLayers_MultiPeriod;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  L := BuildLayers(S, True);
  Assert.AreEqual(3, Length(L), 'N=3 -> 3 layers');
end;

procedure TTestProfileCalc.Test_BuildLayers_MultiStack;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  SetLength(S, 2);
  S[0].N := 2;
  SetLength(S[0].Layers, 1);
  S[0].Layers[0].P[1].V := 10; S[0].Layers[0].P[2].V := 1; S[0].Layers[0].P[3].V := 3;
  S[1].N := 1;
  SetLength(S[1].Layers, 2);
  S[1].Layers[0].P[1].V := 20; S[1].Layers[0].P[2].V := 2; S[1].Layers[0].P[3].V := 4;
  S[1].Layers[1].P[1].V := 30; S[1].Layers[1].P[2].V := 3; S[1].Layers[1].P[3].V := 5;
  L := BuildLayers(S, True);
  Assert.AreEqual(4, Length(L));
end;

procedure TTestProfileCalc.Test_BuildLayers_PPValues;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(2, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0);
  L := BuildLayers(S, True);
  Assert.AreEqual(2, Length(L));
  Assert.AreEqual(Single(11.0), L[0].h, 'Period 1 from PP');
  Assert.AreEqual(Single(12.0), L[1].h, 'Period 2 from PP');
  Assert.AreEqual(Single(2.0),  L[0].s, 'S from P (no PP)');
end;

procedure TTestProfileCalc.Test_BuildLayers_PPIgnoredWhenNotExpanded;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(2, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0);
  L := BuildLayers(S, False);
  Assert.AreEqual(Single(10.0), L[0].h, 'period 1 from P');
  Assert.AreEqual(Single(10.0), L[1].h, 'period 2 from P');
end;

function TTestProfileCalc.MakeProfile(StackID, LayerID: Word;
  Subj: TParameterType; const C: array of Single): TFuncProfileRec;
var
  i: Integer;
begin
  Result.Func := ffPoly;
  Result.Subj := Subj;
  Result.StackID := StackID;
  Result.LayerID := LayerID;
  SetLength(Result.C, Length(C));
  for i := 0 to High(C) do
    Result.C[i] := C[i];
end;

// The demo ML(30x2)P3 "Target": Si thickness graded through 30 periods. The
// depth profile must carry the per-period values the calculation uses.
procedure TTestProfileCalc.Test_BuildLayers_Gradient_ThicknessPerPeriod;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(30, 25.0, 3.0, 2.33);
  L := BuildLayers(S, False, [MakeProfile(0, 0, ptH, [25.0, 0.14, 0.012, -0.0005])]);
  Assert.AreEqual(30, Length(L));
  Assert.AreEqual(Single(25.0), L[0].h, 1E-4, 'period 1 is C0');
  Assert.AreEqual(Single(28.601), L[21].h, 1E-3, 'period 22');
  Assert.AreEqual(Single(26.9575), L[29].h, 1E-3, 'period 30');
  Assert.AreEqual(Single(3.0), L[29].s, 'sigma has no gradient');
  Assert.AreEqual(Single(2.33), L[29].r, 'density has no gradient');
end;

// PrepareLayers counts a gradient's periods from 1 in the stack it belongs to,
// and applies it only to its own (stack, layer, parameter).
procedure TTestProfileCalc.Test_BuildLayers_Gradient_CountsPeriodsInItsOwnStack;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  SetLength(S, 2);
  S[0].N := 2;
  SetLength(S[0].Layers, 1);
  S[0].Layers[0].P[1].V := 10; S[0].Layers[0].P[2].V := 1; S[0].Layers[0].P[3].V := 3;
  S[1].N := 3;
  SetLength(S[1].Layers, 2);
  S[1].Layers[0].P[1].V := 25; S[1].Layers[0].P[2].V := 3; S[1].Layers[0].P[3].V := 2.33;
  S[1].Layers[1].P[1].V := 15; S[1].Layers[1].P[2].V := 3; S[1].Layers[1].P[3].V := 10;

  L := BuildLayers(S, False, [MakeProfile(1, 1, ptRho, [10.0, 0.5])]);

  Assert.AreEqual(8, Length(L));
  Assert.AreEqual(Single(3.0),  L[0].r, 'stack 0 untouched');
  Assert.AreEqual(Single(3.0),  L[1].r, 'stack 0 untouched');
  Assert.AreEqual(Single(2.33), L[2].r, 'Si untouched');
  Assert.AreEqual(Single(10.0), L[3].r, 1E-5, 'Mo period 1');
  Assert.AreEqual(Single(10.5), L[5].r, 1E-5, 'Mo period 2');
  Assert.AreEqual(Single(11.0), L[7].r, 1E-5, 'Mo period 3');
  Assert.AreEqual(Single(15.0), L[7].h, 'Mo thickness untouched');
end;

// The calculation expands the table first and PrepareLayers then replaces the
// profiled parameter, so a gradient wins over a table profile.
procedure TTestProfileCalc.Test_BuildLayers_Gradient_OverridesTable;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(2, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0);
  L := BuildLayers(S, True, [MakeProfile(0, 0, ptH, [20.0, 1.0])]);
  Assert.AreEqual(Single(20.0), L[0].h, 1E-5, 'period 1 from the gradient');
  Assert.AreEqual(Single(21.0), L[1].h, 1E-5, 'period 2 from the gradient');
end;

procedure TTestProfileCalc.Test_CalcDensity_EmptyInput;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
begin
  L := nil;
  D := CalcDensityProfile(L);
  Assert.AreEqual(0, Length(D));
end;

procedure TTestProfileCalc.Test_CalcDensity_SingleLayer_MonotonicDepth;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
  i: Integer;
begin
  SetLength(L, 1);
  L[0].h := 10; L[0].s := 1; L[0].r := 5;
  D := CalcDensityProfile(L);
  Assert.IsTrue(Length(D) > 0, 'Should produce points');
  for i := 1 to High(D) do
    Assert.IsTrue(D[i].Depth > D[i-1].Depth, 'Depth must be monotonically increasing');
end;

procedure TTestProfileCalc.Test_CalcDensity_ZeroRoughness_StepFunction;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
  i: Integer;
  AllEqual: Boolean;
begin
  SetLength(L, 2);
  L[0].h := 10; L[0].s := 0; L[0].r := 3;
  L[1].h := 10; L[1].s := 0; L[1].r := 7;
  D := CalcDensityProfile(L);
  Assert.IsTrue(Length(D) > 10, 'Should produce many points');

  AllEqual := True;
  for i := 1 to High(D) do
    if Abs(D[i].Value - D[i-1].Value) > 0.01 then
    begin
      AllEqual := False;
      Break;
    end;
  Assert.IsFalse(AllEqual, 'Should have step between layers');
end;

procedure TTestProfileCalc.Test_CalcDensity_WithRoughness_SmoothTransition;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
  HasIntermediate: Boolean;
  i: Integer;
begin
  SetLength(L, 2);
  L[0].h := 20; L[0].s := 3; L[0].r := 0;
  L[1].h := 20; L[1].s := 3; L[1].r := 10;
  D := CalcDensityProfile(L);

  HasIntermediate := False;
  for i := 0 to High(D) do
    if (D[i].Value > 1) and (D[i].Value < 9) then
    begin
      HasIntermediate := True;
      Break;
    end;
  Assert.IsTrue(HasIntermediate, 'Roughness should produce intermediate values');
end;

procedure TTestProfileCalc.Test_CalcDensity_RoughnessClamped;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
begin
  SetLength(L, 2);
  L[0].h := 20; L[0].s := 1; L[0].r := 5;
  L[1].h := 4;  L[1].s := 10; L[1].r := 8;
  D := CalcDensityProfile(L);
  Assert.IsTrue(Length(D) > 0, 'Should not crash with clamped roughness');
end;

procedure TTestProfileCalc.Test_CalcDensity_SurfaceStartsNegative;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
begin
  SetLength(L, 1);
  L[0].h := 10; L[0].s := 3; L[0].r := 5;
  D := CalcDensityProfile(L);
  Assert.IsTrue(D[0].Depth < 0, 'Surface layer starts at negative depth');
end;

end.
