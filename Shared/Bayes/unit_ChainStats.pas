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

unit unit_ChainStats;

(* What the sampler reports about a chain (spec section 5): percentiles with
   numpy's linear interpolation, the mean, the correlation matrix, and the
   integrated autocorrelation time of emcee's integrated_time (Goodman & Weare
   2010; Sokal's automatic window, c = 5). Non-finite values - a derived
   expression that divided by zero - are skipped and counted, never averaged.

   An autocorrelation time τ is reliable when three conditions hold:
   1. The Sokal window was reached: M ≥ C·τ(M) at some lag M.
   2. τ > 0.
   3. The series is long enough: N ≥ TAU_TOLERANCE·τ, per emcee's standard. *)

interface

const
  TAU_TOLERANCE = 50;

type
  TSummary = record
    Mean, P2_5, P16, P50, P84, P97_5: Double;
    Finite, NonFinite: Integer;
  end;

function Percentile(const Sorted: TArray<Double>; P: Double): Double;
function Summarize(const Values: TArray<Double>): TSummary;
function Correlation(const Columns: TArray<TArray<Double>>): TArray<TArray<Double>>;
function AutocorrTime(const Walkers: TArray<TArray<Double>>; out Reliable: Boolean;
  C: Double = 5): Double;
/// <summary>Gelman-Rubin R-hat over the walkers' series of one value: the
/// pooled standard deviation over the within-walker one. Near 1 when the
/// walkers sample one distribution; well above it when some sit elsewhere
/// (walkers left behind in a second optimum). 1 for a value that never moves
/// in any walker. NaN with fewer than two walkers or two steps. With four
/// steps or more it is the split R-hat - each walker's two halves are two
/// series - so walkers that are all still moving the same way read well
/// above 1 as well. An ensemble's walkers are not independent chains, so
/// this detects a split or a moving chain, not fine mixing.</summary>
function RHat(const Walkers: TArray<TArray<Double>>): Double;

implementation

uses
  System.Math, System.Generics.Collections;

function RHatOf(const Walkers: TArray<TArray<Double>>; Split: Boolean): Double;
var
  M, N, w, i: Integer;
  Mean, Grand, W2, B, S: Double;
  Means: TArray<Double>;
  Halves: TArray<TArray<Double>>;
  Same: Boolean;
begin
  M := Length(Walkers);
  if M < 2 then
    Exit(NaN);
  N := MaxInt;
  for w := 0 to M - 1 do
    N := Min(N, Length(Walkers[w]));
  if N < 2 then
    Exit(NaN);
  { Split R-hat: each walker's first and second half are two series. An
    ensemble still on its way moves as one - every walker's mean is the same
    and the unsplit ratio is 1 - but its halves sit in different places. }
  if Split and (N >= 4) then
  begin
    SetLength(Halves, 2 * M);
    for w := 0 to M - 1 do
    begin
      Halves[2 * w] := Copy(Walkers[w], 0, N div 2);
      Halves[2 * w + 1] := Copy(Walkers[w], N - N div 2, N div 2);
    end;
    Exit(RHatOf(Halves, False));
  end;
  { A value that never moves - a held slot - is the same number everywhere.
    Decided by comparing the samples, not from the variances: the mean of N
    equal numbers need not equal them to the last bit, and the ratio of two
    rounding errors is anything (1.42 for 1E-7 before this check). }
  Same := True;
  for w := 0 to M - 1 do
  begin
    for i := 0 to N - 1 do
      if Walkers[w][i] <> Walkers[0][0] then
      begin
        Same := False;
        Break;
      end;
    if not Same then
      Break;
  end;
  if Same then
    Exit(1);
  SetLength(Means, M);
  W2 := 0;
  Grand := 0;
  for w := 0 to M - 1 do
  begin
    Mean := 0;
    for i := 0 to N - 1 do
      Mean := Mean + Walkers[w][i];
    Mean := Mean / N;
    S := 0;
    for i := 0 to N - 1 do
      S := S + Sqr(Walkers[w][i] - Mean);
    W2 := W2 + S / (N - 1);
    Means[w] := Mean;
    Grand := Grand + Mean;
  end;
  W2 := W2 / M;                       // the mean within-walker variance
  Grand := Grand / M;
  B := 0;
  for w := 0 to M - 1 do
    B := B + Sqr(Means[w] - Grand);
  B := B / (M - 1);                   // the variance of the walker means
  if W2 <= 0 then
    Exit(Infinity);                   // each walker stands still, at different places
  Result := Sqrt(((N - 1) / N * W2 + B) / W2);
end;

function RHat(const Walkers: TArray<TArray<Double>>): Double;
begin
  Result := RHatOf(Walkers, True);
end;

function IsFiniteValue(X: Double): Boolean; inline;
begin
  Result := not (IsNan(X) or IsInfinite(X));
end;

function Percentile(const Sorted: TArray<Double>; P: Double): Double;
var
  Pos: Double;
  Lo: Integer;
begin
  if Length(Sorted) = 0 then
    Exit(NaN);
  Pos := P / 100 * High(Sorted);
  Lo := Trunc(Pos);
  if Lo >= High(Sorted) then
    Exit(Sorted[High(Sorted)]);
  Result := Sorted[Lo] + (Pos - Lo) * (Sorted[Lo + 1] - Sorted[Lo]);
end;

function Summarize(const Values: TArray<Double>): TSummary;
var
  V: TArray<Double>;
  i, n: Integer;
  Sum: Double;
begin
  Result := Default(TSummary);
  SetLength(V, Length(Values));
  n := 0;
  Sum := 0;
  for i := 0 to High(Values) do
    if IsFiniteValue(Values[i]) then
    begin
      V[n] := Values[i];
      Sum := Sum + Values[i];
      Inc(n);
    end;
  SetLength(V, n);
  Result.Finite := n;
  Result.NonFinite := Length(Values) - n;
  if n = 0 then
  begin
    Result.Mean := NaN; Result.P2_5 := NaN; Result.P16 := NaN;
    Result.P50 := NaN; Result.P84 := NaN; Result.P97_5 := NaN;
    Exit;
  end;
  TArray.Sort<Double>(V);
  Result.Mean := Sum / n;
  Result.P2_5 := Percentile(V, 2.5);
  Result.P16 := Percentile(V, 16);
  Result.P50 := Percentile(V, 50);
  Result.P84 := Percentile(V, 84);
  Result.P97_5 := Percentile(V, 97.5);
end;

function Correlation(const Columns: TArray<TArray<Double>>): TArray<TArray<Double>>;
var
  K, N, i, j, t: Integer;
  Mean, SD: TArray<Double>;
  S: Double;
begin
  K := Length(Columns);
  SetLength(Result, K, K);
  if K = 0 then
    Exit;
  N := Length(Columns[0]);
  SetLength(Mean, K);
  SetLength(SD, K);
  for i := 0 to K - 1 do
  begin
    S := 0;
    for t := 0 to N - 1 do
      S := S + Columns[i][t];
    Mean[i] := S / Max(N, 1);
    S := 0;
    for t := 0 to N - 1 do
      S := S + Sqr(Columns[i][t] - Mean[i]);
    SD[i] := Sqrt(S / Max(N, 1));
  end;
  for i := 0 to K - 1 do
    for j := i to K - 1 do
    begin
      if (SD[i] = 0) or (SD[j] = 0) then
        S := NaN
      else
      begin
        S := 0;
        for t := 0 to N - 1 do
          S := S + (Columns[i][t] - Mean[i]) * (Columns[j][t] - Mean[j]);
        S := S / Max(N, 1) / (SD[i] * SD[j]);
      end;
      Result[i][j] := S;
      Result[j][i] := S;
    end;
end;

function AutocorrTime(const Walkers: TArray<TArray<Double>>; out Reliable: Boolean;
  C: Double = 5): Double;
(* Integrated autocorrelation time following emcee's algorithm. Reliable is True
   when three conditions hold: (1) the Sokal window was reached (Lag ≥ C·τ(Lag)),
   (2) τ > 0, and (3) the series is long enough: N ≥ TAU_TOLERANCE·τ. *)
var
  NumWalkers, N, Walker, t, Lag: Integer;
  Mean, Var0: TArray<Double>;
  Rho, Tau, Acc: Double;
begin
  Reliable := False;
  NumWalkers := Length(Walkers);
  if NumWalkers = 0 then
    Exit(1);
  N := Length(Walkers[0]);
  if N < 2 then
    Exit(1);
  SetLength(Mean, NumWalkers);
  SetLength(Var0, NumWalkers);
  for Walker := 0 to NumWalkers - 1 do
  begin
    Acc := 0;
    for t := 0 to N - 1 do
      Acc := Acc + Walkers[Walker][t];
    Mean[Walker] := Acc / N;
    Acc := 0;
    for t := 0 to N - 1 do
      Acc := Acc + Sqr(Walkers[Walker][t] - Mean[Walker]);
    Var0[Walker] := Acc / N;
  end;

  Tau := 1;
  for Lag := 1 to N - 1 do
  begin
    { rho(Lag), averaged over walkers, each normalised by its own variance }
    Rho := 0;
    for Walker := 0 to NumWalkers - 1 do
    begin
      if Var0[Walker] = 0 then
        Continue;
      Acc := 0;
      for t := 0 to N - 1 - Lag do
        Acc := Acc + (Walkers[Walker][t] - Mean[Walker]) * (Walkers[Walker][t + Lag] - Mean[Walker]);
      Rho := Rho + Acc / N / Var0[Walker];
    end;
    Rho := Rho / NumWalkers;
    Tau := Tau + 2 * Rho;
    { Check all three reliability conditions }
    if Lag >= C * Tau then
    begin
      if (Tau > 0) and (N >= TAU_TOLERANCE * Tau) then
        Reliable := True;
      Exit(Tau);
    end;
  end;
  Result := Tau;
end;

end.
