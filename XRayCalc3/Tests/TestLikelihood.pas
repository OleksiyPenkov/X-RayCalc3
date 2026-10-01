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

unit TestLikelihood;

(* CurveLikelihood against numbers worked out by hand. The model is flat
   (R = 1) so that each residual is chosen directly through the data:
   D_i = exp(r_i). *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestLikelihood = class
  public
    [Test] procedure Counts_HandComputed;
    [Test] procedure NoCounts_VarianceIsFSquared;
    [Test] procedure ZeroCountWithNMinZero_Excluded;
    [Test] procedure NaNCount_ExcludedAndCounted;
    [Test] procedure ScaleIsLog10_NotHalfLog;
    [Test] procedure ResidualIsNaturalLog;
    [Test] procedure Background_AddsToScaledModel;
    [Test] procedure Cost_IsMinus2LnL_MinusConstant_AndNonNegative;
    [Test] procedure RangeFirstLast_Respected;
    [Test] procedure PointUsed_FollowsCurveLikelihood;
    [Test] procedure CostOffset_IsMinus2LnLMinusCost;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Types, unit_Likelihood;

function Curve(const R: array of Double): TDataArray;
var
  i: Integer;
begin
  SetLength(Result, Length(R));
  for i := 0 to High(R) do
  begin
    Result[i].t := 0.1 * (i + 1);
    Result[i].r := R[i];
  end;
end;

function Nuis(LogScale, Background, F: Double): TNuisance;
begin
  Result.LogScale := LogScale;
  Result.Background := Background;
  Result.F := F;
end;

procedure TTestLikelihood.Counts_HandComputed;
var
  T: TLikelihoodTerms;
  Chi2, LnV: Double;
begin
  // residuals 0.1, -0.2, (excluded: 5 counts < n_min 10), 0.3, 0.05; f = 0.1
  T := CurveLikelihood(
    Curve([Exp(0.1), Exp(-0.2), Exp(0.7), Exp(0.3), Exp(0.05)]),
    Curve([1, 1, 1, 1, 1]),
    TArray<Double>.Create(100, 400, 5, 10000, 2500),
    0, 4, 10, Nuis(0, 0, 0.1), 0.001);
  // V = 1/N + f^2 = 0.02, 0.0125, 0.0101, 0.0104
  Chi2 := 0.01 / 0.02 + 0.04 / 0.0125 + 0.09 / 0.0101 + 0.0025 / 0.0104;
  LnV := Ln(0.02) + Ln(0.0125) + Ln(0.0101) + Ln(0.0104);
  Assert.AreEqual(4, T.PointsUsed, 'points used');
  Assert.AreEqual(1, T.PointsExcluded, 'points below n_min');
  // TDataPoint.r is single, so a value from Exp() loses its low bits going in;
  // the tolerance covers that round-trip, not the formula (see deviation note).
  Assert.AreEqual(Chi2, T.Chi2Data, 1E-5, 'chi2_data');
  Assert.AreEqual(Chi2 + LnV, T.Minus2LnL, 1E-5, '-2 ln L');
end;

procedure TTestLikelihood.NoCounts_VarianceIsFSquared;
var
  T: TLikelihoodTerms;
begin
  T := CurveLikelihood(
    Curve([Exp(0.1), Exp(-0.2), Exp(0), Exp(0.3), Exp(0.05)]),
    Curve([1, 1, 1, 1, 1]), nil, 0, 4, 10, Nuis(0, 0, 0.1), 0.001);
  Assert.AreEqual(5, T.PointsUsed);
  Assert.AreEqual(0, T.PointsExcluded);
  Assert.AreEqual((0.01 + 0.04 + 0 + 0.09 + 0.0025) / 0.01, T.Chi2Data, 1E-5);
  Assert.AreEqual(T.Chi2Data + 5 * Ln(0.01), T.Minus2LnL, 1E-9);
end;

procedure TTestLikelihood.ZeroCountWithNMinZero_Excluded;
var
  T: TLikelihoodTerms;
begin
  T := CurveLikelihood(Curve([1, 1]), Curve([1, 1]),
    TArray<Double>.Create(0, 100), 0, 1, 0, Nuis(0, 0, 0.1), 0.001);
  Assert.AreEqual(1, T.PointsUsed, 'a zero count can never be used');
  Assert.AreEqual(1, T.PointsExcluded);
  Assert.IsFalse(IsNan(T.Minus2LnL) or IsInfinite(T.Minus2LnL), 'finite');
end;

procedure TTestLikelihood.NaNCount_ExcludedAndCounted;
var
  T: TLikelihoodTerms;
begin
  T := CurveLikelihood(Curve([1, 1]), Curve([1, 1]),
    TArray<Double>.Create(NaN, 100), 0, 1, 10, Nuis(0, 0, 0.1), 0.001);
  Assert.AreEqual(1, T.PointsUsed, 'a NaN count must be excluded, not used');
  Assert.AreEqual(1, T.PointsExcluded);
  Assert.IsFalse(IsNan(T.Minus2LnL) or IsInfinite(T.Minus2LnL), 'finite');
end;

procedure TTestLikelihood.ScaleIsLog10_NotHalfLog;
var
  T: TLikelihoodTerms;
begin
  // M = 10^log10(2) * 1 = 2 = D: a zero residual. unit_calc's half-log would give M = 4.
  T := CurveLikelihood(Curve([2]), Curve([1]), nil, 0, 0, 0,
    Nuis(Log10(2), 0, 1), 0.001);
  Assert.AreEqual(0.0, T.Chi2Data, 1E-12);
end;

procedure TTestLikelihood.ResidualIsNaturalLog;
var
  T: TLikelihoodTerms;
begin
  // D = e, M = 1: r = ln e = 1; f = 1 so chi2 = 1 (log10 would give 0.1886)
  T := CurveLikelihood(Curve([Exp(1)]), Curve([1]), nil, 0, 0, 0, Nuis(0, 0, 1), 0.001);
  // Exp(1) round-trips through the single-precision TDataPoint.r first.
  Assert.AreEqual(1.0, T.Chi2Data, 1E-6);
end;

procedure TTestLikelihood.Background_AddsToScaledModel;
var
  T: TLikelihoodTerms;
  M: TDataArray;
begin
  T := CurveLikelihood(Curve([1]), Curve([0.5]), nil, 0, 0, 0, Nuis(0, 0.5, 0.1), 0.001);
  Assert.AreEqual(0.0, T.Chi2Data, 1E-12, 'M = 1 * 0.5 + 0.5 = D');
  M := ScaledModel(Curve([0.5, 1]), Nuis(Log10(2), 0.25, 0.1));
  Assert.AreEqual(1.25, Double(M[0].r), 1E-6);
  Assert.AreEqual(2.25, Double(M[1].r), 1E-6);
  Assert.AreEqual(0.2, Double(M[1].t), 1E-6, 'angles are kept');
end;

procedure TTestLikelihood.Cost_IsMinus2LnL_MinusConstant_AndNonNegative;
var
  A, B: TLikelihoodTerms;
  D, R: TDataArray;
  N: TArray<Double>;
begin
  D := Curve([Exp(0.1), Exp(-0.2), Exp(0.3)]);
  R := Curve([1, 1, 1]);
  N := TArray<Double>.Create(100, 400, 10000);
  A := CurveLikelihood(D, R, N, 0, 2, 10, Nuis(0, 0, 0.1), 0.001);
  B := CurveLikelihood(D, R, N, 0, 2, 10, Nuis(0, 0, 0.3), 0.001);
  Assert.IsTrue(A.Cost >= 0, 'cost is never negative');
  Assert.IsTrue(B.Cost >= 0, 'cost is never negative');
  // Cost and -2 ln L differ by a constant that does not depend on the nuisance
  Assert.AreEqual(A.Minus2LnL - A.Cost, B.Minus2LnL - B.Cost, 1E-9);
end;

procedure TTestLikelihood.RangeFirstLast_Respected;
var
  T: TLikelihoodTerms;
begin
  T := CurveLikelihood(Curve([100, Exp(0.1), 100]), Curve([1, 1, 1]), nil, 1, 1, 0,
    Nuis(0, 0, 0.1), 0.001);
  Assert.AreEqual(1, T.PointsUsed);
  Assert.AreEqual(1.0, T.Chi2Data, 1E-6, 'only the middle point: 0.01 / 0.01');
end;

procedure TTestLikelihood.PointUsed_FollowsCurveLikelihood;
var
  Data: TDataArray;
  Counts: TArray<Double>;
  i: Integer;
begin
  SetLength(Data, 6);
  for i := 0 to 5 do
  begin
    Data[i].t := 0.5 + 0.1 * i;
    Data[i].r := 1E-3;
  end;
  Data[4].r := 0;                                     // no intensity
  Counts := [100, 5, 0, NaN, 1000, 10];
  Assert.IsTrue(PointUsed(Data, Counts, 0, 10));
  Assert.IsFalse(PointUsed(Data, Counts, 1, 10), 'below NMin');
  Assert.IsFalse(PointUsed(Data, Counts, 2, 10), 'no count');
  Assert.IsFalse(PointUsed(Data, Counts, 3, 10), 'a NaN count');
  Assert.IsFalse(PointUsed(Data, Counts, 4, 10), 'no intensity');
  Assert.IsTrue(PointUsed(Data, Counts, 5, 10), 'NMin itself is kept');
  Assert.IsTrue(PointUsed(Data, nil, 3, 10), 'without counts only the intensity matters');
  Assert.IsFalse(PointUsed(Data, nil, 4, 10));
end;

procedure TTestLikelihood.CostOffset_IsMinus2LnLMinusCost;
const
  FMIN = 0.02;
var
  Data, Model: TDataArray;
  Counts: TArray<Double>;
  Nuis: TNuisance;
  T: TLikelihoodTerms;
  i, k: Integer;
  Offset: Double;
begin
  SetLength(Data, 6);
  SetLength(Model, 6);
  for i := 0 to 5 do
  begin
    Data[i].t := 0.5 + 0.1 * i;
    Data[i].r := 1E-3 * (1 + 0.1 * i);
    Model[i].t := Data[i].t;
    Model[i].r := 1.1E-3 * (1 + 0.05 * i);
  end;
  Data[4].r := 0;
  Counts := [100, 5, 0, 400, 1000, 10];               // kept: 0, 3, 5
  for k := 0 to 2 do
  begin
    Nuis.LogScale := 0.01 * k;
    Nuis.Background := 1E-6 * k;
    Nuis.F := FMIN + 0.05 * k;
    T := CurveLikelihood(Data, Model, Counts, 0, 5, 10, Nuis, FMIN);
    Offset := LikelihoodCostOffset(Data, Counts, 0, 5, 10, FMIN);
    Assert.AreEqual(T.Minus2LnL - T.Cost, Offset, 1E-10 * Max(1, Abs(Offset)),
      Format('with counts, nuisance %d', [k]));
    T := CurveLikelihood(Data, Model, nil, 1, 4, 10, Nuis, FMIN);
    Offset := LikelihoodCostOffset(Data, nil, 1, 4, 10, FMIN);
    Assert.AreEqual(T.Minus2LnL - T.Cost, Offset, 1E-10 * Max(1, Abs(Offset)),
      Format('without counts, points 1..4, nuisance %d', [k]));
  end;
  Assert.AreEqual(Ln(1 / 100 + Sqr(FMIN)) + Ln(1 / 400 + Sqr(FMIN)) + Ln(1 / 10 + Sqr(FMIN)),
    LikelihoodCostOffset(Data, Counts, 0, 5, 10, FMIN), 1E-12,
    'by hand, over the three kept points');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLikelihood);

end.
