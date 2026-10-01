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

unit TestChainStats;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestChainStats = class
  public
    [Test] procedure Percentile_LinearInterpolation;
    [Test] procedure Summarize_KnownSample;
    [Test] procedure Summarize_SkipsNonFinite;
    [Test] procedure Correlation_PerfectAndAnti;
    [Test] procedure Tau_WhiteNoise_IsOne;
    [Test] procedure Tau_AR1_MatchesAnalytic;
    [Test] procedure Tau_ShortChain_NoCrash;
    [Test] procedure RHat_WalkersOfOneDistribution_NearOne;
    [Test] procedure RHat_OneWalkerElsewhere_Large;
    [Test] procedure RHat_TooShort_NaN;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_ChainStats, unit_Xoshiro;

procedure TTestChainStats.Percentile_LinearInterpolation;
var
  S: TArray<Double>;
begin
  S := [1, 2, 3, 4, 5];                         // numpy.percentile(..., 'linear')
  Assert.AreEqual(1.0, Percentile(S, 0), 1E-12);
  Assert.AreEqual(3.0, Percentile(S, 50), 1E-12);
  Assert.AreEqual(5.0, Percentile(S, 100), 1E-12);
  Assert.AreEqual(1.64, Percentile(S, 16), 1E-12);   // 0.16*4 = 0.64 -> 1 + 0.64
  Assert.AreEqual(4.36, Percentile(S, 84), 1E-12);
end;

procedure TTestChainStats.Summarize_KnownSample;
var
  T: TSummary;
begin
  T := Summarize([5, 1, 4, 2, 3]);              // unsorted on purpose
  Assert.AreEqual(3.0, T.Mean, 1E-12);
  Assert.AreEqual(3.0, T.P50, 1E-12);
  Assert.AreEqual(1.1, T.P2_5, 1E-12);          // 0.025*4 = 0.1
  Assert.AreEqual(5, T.Finite);
  Assert.AreEqual(0, T.NonFinite);
end;

procedure TTestChainStats.Summarize_SkipsNonFinite;
var
  T: TSummary;
begin
  T := Summarize([1, NaN, 3, Infinity, 2, NegInfinity]);
  Assert.AreEqual(3, T.Finite);
  Assert.AreEqual(3, T.NonFinite);
  Assert.AreEqual(2.0, T.Mean, 1E-12);
  Assert.AreEqual(2.0, T.P50, 1E-12);
end;

procedure TTestChainStats.Correlation_PerfectAndAnti;
var
  C: TArray<TArray<Double>>;
begin
  C := Correlation([[1, 2, 3, 4], [2, 4, 6, 8], [4, 3, 2, 1]]);
  Assert.AreEqual(1.0, C[0][0], 1E-12);
  Assert.AreEqual(1.0, C[0][1], 1E-12);
  Assert.AreEqual(-1.0, C[0][2], 1E-12);
  Assert.AreEqual(C[1][2], C[2][1], 1E-15, 'symmetric');
end;

function AR1(Walkers, N: Integer; Phi: Double; Seed: UInt64): TArray<TArray<Double>>;
var
  R: TXoshiro256;
  w, t: Integer;
begin
  R.Seed(Seed);
  SetLength(Result, Walkers);
  for w := 0 to Walkers - 1 do
  begin
    SetLength(Result[w], N);
    Result[w][0] := R.NextGaussian / Sqrt(1 - Phi * Phi);   // stationary start
    for t := 1 to N - 1 do
      Result[w][t] := Phi * Result[w][t - 1] + R.NextGaussian;
  end;
end;

procedure TTestChainStats.Tau_WhiteNoise_IsOne;
var
  Reliable: Boolean;
begin
  Assert.AreEqual(1.0, AutocorrTime(AR1(16, 5000, 0, 1), Reliable), 0.1);
  Assert.IsTrue(Reliable);
end;

procedure TTestChainStats.Tau_AR1_MatchesAnalytic;
var
  Reliable: Boolean;
  Tau: Double;
begin
  { tau = (1 + phi) / (1 - phi) = 19 for phi = 0.9 }
  Tau := AutocorrTime(AR1(32, 20000, 0.9, 2), Reliable);
  Assert.IsTrue(Reliable);
  Assert.AreEqual(19.0, Tau, 19 * 0.15, Format('tau %g', [Tau]));
end;

procedure TTestChainStats.Tau_ShortChain_NoCrash;
var
  Reliable: Boolean;
  Tau: Double;
begin
  Tau := AutocorrTime(AR1(4, 10, 0.99, 3), Reliable);
  Assert.IsFalse(Reliable, 'ten points cannot hold a window of five tau');
  Assert.IsFalse(IsNan(Tau) or IsInfinite(Tau));
  Tau := AutocorrTime(AR1(4, 1, 0.5, 3), Reliable);    // a single point
  Assert.IsFalse(Reliable);
  Assert.AreEqual(1.0, Tau, 0.0);
end;

function GaussianWalkers(Walkers, Steps: Integer; Seed: UInt64): TArray<TArray<Double>>;
var
  Rng: TXoshiro256;
  w, i: Integer;
begin
  Rng.Seed(Seed);
  SetLength(Result, Walkers);
  for w := 0 to Walkers - 1 do
  begin
    SetLength(Result[w], Steps);
    for i := 0 to Steps - 1 do
      Result[w][i] := Rng.NextGaussian;
  end;
end;

procedure TTestChainStats.RHat_WalkersOfOneDistribution_NearOne;
var
  R: Double;
begin
  R := RHat(GaussianWalkers(8, 500, 11));
  Assert.IsTrue((R > 0.98) and (R < 1.05), Format('R-hat %g', [R]));
end;

procedure TTestChainStats.RHat_OneWalkerElsewhere_Large;
var
  W: TArray<TArray<Double>>;
  i: Integer;
begin
  W := GaussianWalkers(8, 500, 11);
  for i := 0 to High(W[3]) do
    W[3][i] := W[3][i] + 10;                    // a walker left behind in another optimum
  Assert.IsTrue(RHat(W) > 2, Format('R-hat %g', [RHat(W)]));
end;

procedure TTestChainStats.RHat_TooShort_NaN;
begin
  Assert.IsTrue(IsNaN(RHat([[1.0], [2.0]])), 'one step per walker has no within-walker variance');
  Assert.IsTrue(IsNaN(RHat([[1.0, 2.0, 3.0]])), 'one walker has no between-walker variance');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestChainStats);

end.
