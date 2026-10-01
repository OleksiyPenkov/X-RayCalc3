unit TestStretchSampler;

(* The stretch move on distributions with known answers: a 2D and a
   correlated 5D Gaussian (mean and covariance recovered), a half-plane
   support (never accepts -inf), and exact reproducibility - the same seed
   gives the same chain, and a saved state continues it bit for bit. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestStretchSampler = class
  public
    [Test] procedure Gaussian2D_RecoversMeanAndCovariance;
    [Test] procedure Gaussian5D_Correlated_RecoversCovariance;
    [Test] procedure InfeasibleRegion_NeverAccepted;
    [Test] procedure SameSeed_SameChain;
    [Test] procedure SaveLoad_ContinuesBitIdentically;
    [Test] procedure Start_InfeasibleWalker_Raises;
    [Test] procedure OddWalkers_Raise;
    [Test] procedure Blobs_FollowAcceptedPositions;
    [Test] procedure Rescore_NoDrawsStepUnchanged_OnlyScoresReplaced;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.Math, unit_Xoshiro, unit_StretchSampler;

{ ln p of N(Mu, Sigma) with Sigma^-1 given, up to a constant }
function GaussLogProb(const Mu: TVector; const Prec: TArray<TVector>): TLogProbBatch;
begin
  Result :=
    procedure(const Batch: TArray<TVector>; out LnP: TArray<Double>; out Blobs: TArray<TVector>)
    var
      i, a, b, D: Integer;
      Q: Double;
    begin
      D := Length(Mu);
      SetLength(LnP, Length(Batch));
      SetLength(Blobs, Length(Batch));
      for i := 0 to High(Batch) do
      begin
        Q := 0;
        for a := 0 to D - 1 do
          for b := 0 to D - 1 do
            Q := Q + (Batch[i][a] - Mu[a]) * Prec[a][b] * (Batch[i][b] - Mu[b]);
        LnP[i] := -0.5 * Q;
        Blobs[i] := [Batch[i][0] * 10];
      end;
    end;
end;

function Ball(Walkers, Dim: Integer; const Center: TVector; Seed: UInt64): TArray<TVector>;
var
  R: TXoshiro256;
  w, d: Integer;
begin
  R.Seed(Seed);
  SetLength(Result, Walkers);
  for w := 0 to Walkers - 1 do
  begin
    SetLength(Result[w], Dim);
    for d := 0 to Dim - 1 do
      Result[w][d] := Center[d] + 0.1 * R.NextGaussian;
  end;
end;

{ runs Steps, drops Burn, returns per-dimension mean and the covariance }
procedure RunAndMoments(S: TStretchSampler; Steps, Burn: Integer;
  out Mean: TVector; out Cov: TArray<TVector>);
var
  st, w, a, b, D, N: Integer;
  Sum: TVector;
  Sum2: TArray<TVector>;
begin
  D := S.Dim;
  SetLength(Sum, D);
  SetLength(Sum2, D, D);
  N := 0;
  for st := 1 to Steps do
  begin
    S.DoStep;
    if st <= Burn then
      Continue;
    for w := 0 to S.Walkers - 1 do
    begin
      for a := 0 to D - 1 do
      begin
        Sum[a] := Sum[a] + S.X[w][a];
        for b := 0 to D - 1 do
          Sum2[a][b] := Sum2[a][b] + S.X[w][a] * S.X[w][b];
      end;
      Inc(N);
    end;
  end;
  SetLength(Mean, D);
  SetLength(Cov, D, D);
  for a := 0 to D - 1 do
    Mean[a] := Sum[a] / N;
  for a := 0 to D - 1 do
    for b := 0 to D - 1 do
      Cov[a][b] := Sum2[a][b] / N - Mean[a] * Mean[b];
end;

procedure TTestStretchSampler.Gaussian2D_RecoversMeanAndCovariance;
var
  S: TStretchSampler;
  Mean: TVector;
  Cov: TArray<TVector>;
begin
  { Sigma = [[1, 0.5], [0.5, 2]]; Sigma^-1 = [[8/7, -2/7], [-2/7, 4/7]] }
  S := TStretchSampler.Create(32, 2, GaussLogProb([1, -2], [[8 / 7, -2 / 7], [-2 / 7, 4 / 7]]));
  try
    S.Start(Ball(32, 2, [1, -2], 1), 42);
    RunAndMoments(S, 3000, 500, Mean, Cov);
    Assert.AreEqual(1.0, Mean[0], 0.1);
    Assert.AreEqual(-2.0, Mean[1], 0.1);
    Assert.AreEqual(1.0, Cov[0][0], 0.1);
    Assert.AreEqual(2.0, Cov[1][1], 0.2);
    Assert.AreEqual(0.5, Cov[0][1], 0.1);
    Assert.IsTrue((S.AcceptanceFraction(0) > 0.2) and (S.AcceptanceFraction(0) < 0.9));
  finally
    S.Free;
  end;
end;

procedure TTestStretchSampler.Gaussian5D_Correlated_RecoversCovariance;
var
  S: TStretchSampler;
  Mean: TVector;
  Cov: TArray<TVector>;
  Prec: TArray<TVector>;
  a, b: Integer;
begin
  { Sigma = 0.1*I + 0.9*ones (unit variances, correlation 0.9 everywhere);
    Sigma^-1 = (1/0.1)(I - 0.9/(0.1 + 5*0.9) * ones) (Sherman-Morrison) }
  SetLength(Prec, 5, 5);
  for a := 0 to 4 do
    for b := 0 to 4 do
      Prec[a][b] := 10 * (Ord(a = b) - 0.9 / 4.6);
  S := TStretchSampler.Create(40, 5, GaussLogProb([0, 0, 0, 0, 0], Prec));
  try
    S.Start(Ball(40, 5, [0, 0, 0, 0, 0], 2), 7);
    RunAndMoments(S, 6000, 1000, Mean, Cov);
    for a := 0 to 4 do
    begin
      Assert.AreEqual(0.0, Mean[a], 0.15, Format('mean %d', [a]));
      Assert.AreEqual(1.0, Cov[a][a], 0.15, Format('var %d', [a]));
    end;
    Assert.AreEqual(0.9, Cov[0][4] / Sqrt(Cov[0][0] * Cov[4][4]), 0.05, 'correlation');
  finally
    S.Free;
  end;
end;

procedure TTestStretchSampler.InfeasibleRegion_NeverAccepted;
var
  S: TStretchSampler;
  st, w: Integer;
begin
  { standard normal truncated to x > 0 }
  S := TStretchSampler.Create(16, 1,
    procedure(const Batch: TArray<TVector>; out LnP: TArray<Double>; out Blobs: TArray<TVector>)
    var
      i: Integer;
    begin
      SetLength(LnP, Length(Batch));
      SetLength(Blobs, Length(Batch));
      for i := 0 to High(Batch) do
        if Batch[i][0] > 0 then
          LnP[i] := -0.5 * Sqr(Batch[i][0])
        else
          LnP[i] := NegInfinity;
    end);
  try
    S.Start(Ball(16, 1, [1], 3), 9);
    for st := 1 to 2000 do
    begin
      S.DoStep;
      for w := 0 to 15 do
      begin
        Assert.IsTrue(S.X[w][0] > 0, 'a walker entered the zero-probability region');
        Assert.IsFalse(IsNan(S.LnP[w]));
      end;
    end;
  finally
    S.Free;
  end;
end;

function ChainOf(Seed: UInt64; Steps: Integer): TArray<Double>;
var
  S: TStretchSampler;
  st, w: Integer;
begin
  S := TStretchSampler.Create(8, 2, GaussLogProb([0, 0], [[1, 0], [0, 1]]));
  try
    S.Start(Ball(8, 2, [0, 0], 4), Seed);
    Result := nil;
    for st := 1 to Steps do
    begin
      S.DoStep;
      for w := 0 to 7 do
        Result := Result + [S.X[w][0], S.X[w][1], S.LnP[w]];
    end;
  finally
    S.Free;
  end;
end;

procedure TTestStretchSampler.SameSeed_SameChain;
var
  A, B: TArray<Double>;
  i: Integer;
begin
  A := ChainOf(123, 200);
  B := ChainOf(123, 200);
  Assert.AreEqual(Length(A), Length(B));
  for i := 0 to High(A) do
    Assert.AreEqual(A[i], B[i], 0.0);
  Assert.AreNotEqual(A[High(A)], ChainOf(124, 200)[High(A)], 0.0, 'another seed, another chain');
end;

procedure TTestStretchSampler.SaveLoad_ContinuesBitIdentically;
var
  Full, Half: TStretchSampler;
  LP: TLogProbBatch;
  M: TMemoryStream;
  st, w: Integer;
begin
  LP := GaussLogProb([0, 0], [[1, 0], [0, 1]]);
  Full := TStretchSampler.Create(8, 2, LP);
  Half := TStretchSampler.Create(8, 2, LP);
  M := TMemoryStream.Create;
  try
    Full.Start(Ball(8, 2, [0, 0], 4), 55);
    for st := 1 to 300 do
      Full.DoStep;

    Half.Start(Ball(8, 2, [0, 0], 4), 55);
    for st := 1 to 150 do
      Half.DoStep;
    Half.SaveState(M);
    Half.Free;
    Half := TStretchSampler.Create(8, 2, LP);
    M.Position := 0;
    Half.LoadState(M);
    for st := 151 to 300 do
      Half.DoStep;

    Assert.AreEqual(Full.Step, Half.Step);
    for w := 0 to 7 do
    begin
      Assert.AreEqual(Full.X[w][0], Half.X[w][0], 0.0);
      Assert.AreEqual(Full.X[w][1], Half.X[w][1], 0.0);
      Assert.AreEqual(Full.LnP[w], Half.LnP[w], 0.0);
      Assert.AreEqual(Full.Accepted[w], Half.Accepted[w]);
    end;
  finally
    M.Free;
    Full.Free;
    Half.Free;
  end;
end;

procedure TTestStretchSampler.Start_InfeasibleWalker_Raises;
var
  S: TStretchSampler;
begin
  S := TStretchSampler.Create(4, 1,
    procedure(const Batch: TArray<TVector>; out LnP: TArray<Double>; out Blobs: TArray<TVector>)
    var
      i: Integer;
    begin
      SetLength(LnP, Length(Batch));
      SetLength(Blobs, Length(Batch));
      for i := 0 to High(Batch) do
        LnP[i] := IfThen(Batch[i][0] > 0, 0, NegInfinity);
    end);
  try
    Assert.WillRaise(procedure begin S.Start([[1], [1], [-1], [1]], 1) end, ESampler);
  finally
    S.Free;
  end;
end;

procedure TTestStretchSampler.OddWalkers_Raise;
begin
  Assert.WillRaise(procedure begin
    TStretchSampler.Create(7, 2, GaussLogProb([0, 0], [[1, 0], [0, 1]])).Free end, ESampler);
  Assert.WillRaise(procedure begin
    TStretchSampler.Create(4, 3, GaussLogProb([0, 0, 0], [[1, 0, 0], [0, 1, 0], [0, 0, 1]])).Free end,
    ESampler, 'fewer than 2 x dim walkers');
end;

procedure TTestStretchSampler.Blobs_FollowAcceptedPositions;
var
  S: TStretchSampler;
  st, w: Integer;
begin
  S := TStretchSampler.Create(8, 2, GaussLogProb([0, 0], [[1, 0], [0, 1]]));
  try
    S.Start(Ball(8, 2, [0, 0], 4), 77);
    for st := 1 to 100 do
    begin
      S.DoStep;
      for w := 0 to 7 do
        Assert.AreEqual(S.X[w][0] * 10, S.Blobs[w][0], 1E-12);
    end;
  finally
    S.Free;
  end;
end;

procedure TTestStretchSampler.Rescore_NoDrawsStepUnchanged_OnlyScoresReplaced;
const
  RESCORE_AT = 50;
  TOTAL      = 150;
var
  A, B: TStretchSampler;
  LPA, LPB: TLogProbBatch;
  OffsetA, OffsetB: Double;
  st, w: Integer;
  StepBefore: Integer;
  XBefore: TArray<TVector>;
begin
  OffsetA := 0;
  LPA := procedure(const Batch: TArray<TVector>; out LnP: TArray<Double>; out Blobs: TArray<TVector>)
    var i: Integer;
    begin
      SetLength(LnP, Length(Batch));
      SetLength(Blobs, Length(Batch));
      for i := 0 to High(Batch) do
      begin
        LnP[i] := -0.5 * (Sqr(Batch[i][0]) + Sqr(Batch[i][1])) + OffsetA;
        Blobs[i] := [Batch[i][0] * 10 + OffsetA];
      end;
    end;
  OffsetB := 0;
  LPB := procedure(const Batch: TArray<TVector>; out LnP: TArray<Double>; out Blobs: TArray<TVector>)
    var i: Integer;
    begin
      SetLength(LnP, Length(Batch));
      SetLength(Blobs, Length(Batch));
      for i := 0 to High(Batch) do
      begin
        LnP[i] := -0.5 * (Sqr(Batch[i][0]) + Sqr(Batch[i][1])) + OffsetB;
        Blobs[i] := [Batch[i][0] * 10 + OffsetB];
      end;
    end;

  A := TStretchSampler.Create(8, 2, LPA);
  B := TStretchSampler.Create(8, 2, LPB);
  try
    A.Start(Ball(8, 2, [0, 0], 4), 55);
    B.Start(Ball(8, 2, [0, 0], 4), 55);
    for st := 1 to RESCORE_AT do
    begin
      A.DoStep;
      B.DoStep;
    end;

    { Sanity: with both offsets at 0, the two chains agree exactly so far. }
    for w := 0 to 7 do
    begin
      Assert.AreEqual(A.X[w][0], B.X[w][0], 0.0);
      Assert.AreEqual(A.X[w][1], B.X[w][1], 0.0);
      Assert.AreEqual(A.LnP[w], B.LnP[w], 0.0);
    end;

    StepBefore := B.Step;
    SetLength(XBefore, 8);
    for w := 0 to 7 do
      XBefore[w] := Copy(B.X[w]);

    { "a batch function that returns a different constant offset" }
    OffsetB := 7;
    B.Rescore;

    Assert.AreEqual(StepBefore, B.Step, 'Rescore must not advance Step');
    for w := 0 to 7 do
    begin
      Assert.AreEqual(XBefore[w][0], B.X[w][0], 0.0, 'Rescore must not move a walker');
      Assert.AreEqual(XBefore[w][1], B.X[w][1], 0.0, 'Rescore must not move a walker');
      Assert.AreEqual(A.LnP[w] + 7, B.LnP[w], 1E-12, 'LnP is replaced under the new function');
      Assert.AreEqual(A.Blobs[w][0] + 7, B.Blobs[w][0], 1E-12, 'Blobs are replaced too');
    end;

    { A constant offset cancels in every acceptance ratio, so continuing under
      the new offset must decide every later move exactly as continuing under
      the old one would: this is only true if Rescore drew no random numbers
      and left the RNG stream untouched. Chain A (offset 0 throughout) is
      "a chain started fresh from those positions under the new function"
      up to that constant. }
    for st := RESCORE_AT + 1 to TOTAL do
    begin
      A.DoStep;
      B.DoStep;
    end;
    for w := 0 to 7 do
    begin
      Assert.AreEqual(A.X[w][0], B.X[w][0], 0.0,
        'a rescored constant offset must not change any later accept/reject decision');
      Assert.AreEqual(A.X[w][1], B.X[w][1], 0.0,
        'a rescored constant offset must not change any later accept/reject decision');
      Assert.AreEqual(A.LnP[w] + 7, B.LnP[w], 1E-9);
      Assert.AreEqual(A.Accepted[w], B.Accepted[w],
        'Rescore drew no random numbers: the RNG stream, and so every later accept/reject, is unaffected');
    end;
  finally
    A.Free;
    B.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStretchSampler);

end.
