unit TestPosteriorBatch;

(* TPosteriorBatch against TLogPosterior itself: a batch scores every vector
   exactly as one EvaluateOnce does, on any number of workers, and a stretch
   sampler driven by it walks the same chain whatever the worker count. *)

interface

uses
  DUnitX.TestFramework, unit_ParamMap;

type
  [TestFixture]
  TTestPosteriorBatch = class
  public
    [Test] procedure LogProb_EqualsEvaluateOnce;
    [Test] procedure LogProb_Infeasible_IsNegInfinity;
    [Test] procedure LogProb_SameResultAnyWorkerCount;
    [Test] procedure ModelCurves_AreScaledModel;
    [Test] procedure Chain_SameAnyWorkerCount;
    [Test] procedure Gpu_LogProb_FeasibilityAndPriorAsTheCpu;
    [Test] procedure Gpu_Chain_SameAnyWorkerCount;
    [Test] procedure Gpu_FailsMidChain_ContinuesOnTheCpu;
    [Test] procedure Gpu_NotAskedFor_StaysOnTheCpu;
    [Test] procedure Joint_LogProb_EqualsJointEvaluateOnce;
    [Test] procedure Joint_SameResultAnyWorkerCount;
    [Test] procedure Joint_ModelCurves_PerMember;
    [Test] procedure Joint_Gpu_LnPIsMinusHalfTheJointCost;
    [Test] procedure Joint_Gpu_FailsInSecondMember_ContinuesOnTheCpu;
  end;

{ 12 feasible vectors spread in all four slots around the start. }
function Around(Map: TParamMap): TArray<TArray<Double>>;

implementation

uses
  System.SysUtils, System.Math, unit_Types, unit_Likelihood, unit_gpu_calc,
  unit_LogPosterior, unit_JointPosterior, unit_StretchSampler, unit_PosteriorBatch,
  TestLogPosterior, TestJointPosterior;

{ As TestLogPosterior's MakeMap: the W-on-B4C interlayer free, B4C derived. }
function MakeMap: TParamMap;
begin
  Result := TParamMap.Create(TWB4CFixture.Structure(6));
  Result.AddParam('s0.l2.thickness', 0, 2, 1);
  Result.SetDerived('s0.l3.thickness', 0, 3);
  Result.AddNuisance(System.Math.Log10(1.2), 0, 1E-7, 0.001, 1);
end;

{ The posterior of data made by its own curve at the start vector, without
  counts. The caller frees the result, then Map. }
function MakePosterior(out Map: TParamMap): TLogPosterior;
var
  Data, R: TDataArray;
  i: Integer;
begin
  Map := MakeMap;
  Data := TWB4CFixture.Angles;
  Result := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
  try
    Result.EvaluateOnce(Map.StartVector, R);
  finally
    Result.Free;
  end;
  for i := 0 to High(Data) do
    Data[i].r := Max(R[i].r, 1E-9);
  Result := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
end;

function Around(Map: TParamMap): TArray<TArray<Double>>;
var
  i: Integer;
begin
  SetLength(Result, 12);
  for i := 0 to 11 do
  begin
    Result[i] := Map.StartVector;
    Result[i][Map.IndexOf('s0.l2.thickness')] := 5.4 + 0.1 * i;      // [3, 9]; B4C stays in [10, 20]
    Result[i][Map.IndexOf('c0.log10_scale')] := 0.005 * (i - 6);      // inside +-log10(1.2)
    Result[i][Map.IndexOf('c0.background')] := 1E-9 * i;              // inside [0, 1e-7]
    Result[i][Map.IndexOf('c0.ln_f')] := Ln(0.01 + 0.005 * i);        // inside [0.001, 1]
  end;
end;

procedure TTestPosteriorBatch.LogProb_EqualsEvaluateOnce;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B: TPosteriorBatch;
  X, Blobs: TArray<TVector>;
  LnP: TArray<Double>;
  T: TPosteriorTerms;
  R: TDataArray;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakePosterior(Map);
  B := TPosteriorBatch.Create(Post, 4);
  try
    X := Around(Map);
    B.LogProb(X, LnP, Blobs);
    for i := 0 to High(X) do
    begin
      T := Post.EvaluateOnce(X[i], R);
      Assert.IsTrue(T.Feasible, Format('vector %d is feasible', [i]));
      Assert.AreEqual(-0.5 * T.Cost, LnP[i], 0.0, Format('ln p of vector %d', [i]));
      Assert.AreEqual(2, Integer(Length(Blobs[i])));
      Assert.AreEqual(T.Likelihood.Minus2LnL, Blobs[i][0], 0.0, 'blob: minus2lnL');
      Assert.AreEqual(T.PriorTerm, Blobs[i][1], 0.0, 'blob: prior term');
    end;
  finally
    B.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.LogProb_Infeasible_IsNegInfinity;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B: TPosteriorBatch;
  X, Blobs: TArray<TVector>;
  LnP: TArray<Double>;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakePosterior(Map);
  B := TPosteriorBatch.Create(Post, 4);
  try
    X := Around(Map);
    X[3][Map.IndexOf('s0.l2.thickness')] := 9.5;                     // above its bound of 9
    B.LogProb(X, LnP, Blobs);
    Assert.IsTrue(IsInfinite(LnP[3]) and (LnP[3] < 0), 'ln p = -inf');
    Assert.AreEqual(0, Integer(Length(Blobs[3])), 'no blob for an infeasible vector');
    Assert.IsFalse(IsInfinite(LnP[2]) or IsNan(LnP[2]), 'its neighbours are unaffected');
  finally
    B.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.LogProb_SameResultAnyWorkerCount;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B1, B6: TPosteriorBatch;
  X, Blobs1, Blobs6: TArray<TVector>;
  LnP1, LnP6: TArray<Double>;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakePosterior(Map);
  B1 := TPosteriorBatch.Create(Post, 1);
  B6 := TPosteriorBatch.Create(Post, 6);
  try
    X := Around(Map);
    B1.LogProb(X, LnP1, Blobs1);
    B6.LogProb(X, LnP6, Blobs6);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(LnP1[i], LnP6[i], 0.0, Format('ln p %d', [i]));
      Assert.AreEqual(Blobs1[i][0], Blobs6[i][0], 0.0);
      Assert.AreEqual(Blobs1[i][1], Blobs6[i][1], 0.0);
    end;
  finally
    B6.Free;
    B1.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.ModelCurves_AreScaledModel;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B: TPosteriorBatch;
  X: TArray<TVector>;
  Curves: TArray<TDataArray>;
  T: TPosteriorTerms;
  R, M: TDataArray;
  i, k: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakePosterior(Map);
  B := TPosteriorBatch.Create(Post, 4);
  try
    X := Around(Map);
    X[5][Map.IndexOf('s0.l2.thickness')] := 9.5;                     // one infeasible vector
    B.ModelCurves(X, Curves);
    Assert.IsNull(Pointer(Curves[5]), 'no curve for an infeasible vector');
    for i := 0 to High(X) do
    begin
      if i = 5 then
        Continue;
      T := Post.EvaluateOnce(X[i], R);
      M := ScaledModel(R, T.Nuisance);
      Assert.AreEqual(Integer(Length(M)), Integer(Length(Curves[i])));
      for k := 0 to High(M) do
      begin
        Assert.AreEqual(Double(M[k].t), Double(Curves[i][k].t), 0.0);
        Assert.AreEqual(Double(M[k].r), Double(Curves[i][k].r), 0.0,
          Format('vector %d, point %d', [i, k]));
      end;
    end;
  finally
    B.Free;
    Post.Free;
    Map.Free;
  end;
end;

{ Minus2LnL - the likelihood cost: the constant CurveLikelihood adds on top of
  its per-point sum, computed once from the posterior's own values. }
function CostOffsetOf(Post: TLogPosterior): Double;
begin
  Result := LikelihoodCostOffset(Post.Data, Post.Counts, Post.First, Post.Last, Post.NMin,
    Post.Map.FMin);
end;

{ True when this machine has both the Henke tables and a usable GPU; Assert.Pass
  (skip) otherwise. }
function GpuReady(out Name: string): Boolean;
var
  Err: string;
begin
  Result := False;
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed')
  else if not TGpuEvaluator.Available(Name, Err) then
    Assert.Pass('No usable GPU on this machine: ' + Err)
  else
    Result := True;
end;

{ 10 steps of 8 walkers; every position and ln p, flattened. }
function RunChain(Post: TLogPosterior; Map: TParamMap; Workers: Integer;
  UseGPU: Boolean = False): TArray<Double>;
var
  B: TPosteriorBatch;
  S: TStretchSampler;
  st, w: Integer;
begin
  B := TPosteriorBatch.Create(Post, Workers, UseGPU);
  S := TStretchSampler.Create(8, Map.Count, B.AsBatchFunc);   // 8 = 2 x dim 4
  try
    S.Start(Copy(Around(Map), 0, 8), 21);
    Result := nil;
    for st := 1 to 10 do
    begin
      S.DoStep;
      for w := 0 to 7 do
        Result := Result + S.X[w] + [S.LnP[w]];
    end;
  finally
    S.Free;                          // before B: S holds B's batch function
    B.Free;
  end;
end;

procedure TTestPosteriorBatch.Chain_SameAnyWorkerCount;
var
  Map: TParamMap;
  Post: TLogPosterior;
  A, C: TArray<Double>;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakePosterior(Map);
  try
    A := RunChain(Post, Map, 1);
    C := RunChain(Post, Map, 4);
    Assert.AreEqual(Integer(Length(A)), Integer(Length(C)));
    for i := 0 to High(A) do
      Assert.AreEqual(A[i], C[i], 0.0, Format('chain value %d', [i]));
  finally
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.Gpu_LogProb_FeasibilityAndPriorAsTheCpu;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B, C: TPosteriorBatch;
  X, Blobs, CBlobs: TArray<TVector>;
  LnP, CLnP: TArray<Double>;
  Name: string;
  i: Integer;
begin
  if not GpuReady(Name) then Exit;
  Post := MakePosterior(Map);
  B := TPosteriorBatch.Create(Post, 4, True);
  C := TPosteriorBatch.Create(Post, 4);
  try
    Assert.AreEqual(Name, B.DeviceUsed);
    Assert.AreEqual('', B.GpuError);
    X := Around(Map);
    X[3][Map.IndexOf('s0.l2.thickness')] := 9.5;
    B.LogProb(X, LnP, Blobs);
    C.LogProb(X, CLnP, CBlobs);
    Assert.IsTrue(B.GpuUsed);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(IsInfinite(CLnP[i]), IsInfinite(LnP[i]),
        'feasibility is decided as on the CPU: ' + IntToStr(i));
      if IsInfinite(CLnP[i]) then
        Assert.AreEqual(0, Integer(Length(Blobs[i])), 'no blob for an infeasible vector')
      else
      begin
        Assert.IsFalse(IsNan(LnP[i]));
        Assert.AreEqual(2, Integer(Length(Blobs[i])));
        Assert.AreEqual(CBlobs[i][1], Blobs[i][1], 0.0, 'the prior term is the CPU''s');
        Assert.AreEqual(-0.5 * (Blobs[i][0] - CostOffsetOf(Post) + Blobs[i][1]), LnP[i],
          1E-9 * Abs(LnP[i]), 'ln p = -(minus2lnL - offset + prior) / 2');
      end;
    end;
  finally
    C.Free;
    B.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.Gpu_Chain_SameAnyWorkerCount;
var
  Map: TParamMap;
  Post: TLogPosterior;
  A, C: TArray<Double>;
  Name: string;
  i: Integer;
begin
  if not GpuReady(Name) then Exit;
  Post := MakePosterior(Map);
  try
    A := RunChain(Post, Map, 1, True);
    C := RunChain(Post, Map, 4, True);
    Assert.AreEqual(Integer(Length(A)), Integer(Length(C)));
    for i := 0 to High(A) do
      Assert.AreEqual(A[i], C[i], 0.0, Format('chain value %d', [i]));
  finally
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.Gpu_FailsMidChain_ContinuesOnTheCpu;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B: TPosteriorBatch;
  X, B1, B2, B3, B4: TArray<TVector>;
  L1, L2, L3, L4: TArray<Double>;
  Name: string;
  i: Integer;
begin
  if not GpuReady(Name) then Exit;
  Post := MakePosterior(Map);
  B := TPosteriorBatch.Create(Post, 4, True);
  try
    X := Around(Map);
    TGpuEvaluator.FailAfter := 2;                     // the second batch fails on the GPU
    try
      B.LogProb(X, L1, B1);
      B.LogProb(X, L2, B2);
      B.LogProb(X, L3, B3);
    finally
      TGpuEvaluator.FailAfter := 0;
    end;
    Assert.IsTrue(B.GpuUsed, 'the first batch ran on the GPU');
    Assert.AreEqual('CPU', B.DeviceUsed);
    Assert.Contains(B.GpuError, 'injected');
    B.LogProbOnCpu(X, L4, B4);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(L4[i], L2[i], 0.0, 'the failed batch was scored on the CPU: ' + IntToStr(i));
      Assert.AreEqual(L4[i], L3[i], 0.0, 'and so is every batch after it: ' + IntToStr(i));
    end;
  finally
    B.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.Gpu_NotAskedFor_StaysOnTheCpu;
var
  Map: TParamMap;
  Post: TLogPosterior;
  B: TPosteriorBatch;
  Blobs: TArray<TVector>;
  LnP: TArray<Double>;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakePosterior(Map);
  B := TPosteriorBatch.Create(Post, 4);
  try
    B.LogProb(Around(Map), LnP, Blobs);
    Assert.AreEqual('CPU', B.DeviceUsed);
    Assert.AreEqual('', B.GpuError);
    Assert.IsFalse(B.GpuUsed);
  finally
    B.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestPosteriorBatch.Joint_LogProb_EqualsJointEvaluateOnce;
var
  J: TJointPosterior;
  B: TPosteriorBatch;
  X, Blobs: TArray<TVector>;
  LnP: TArray<Double>;
  C: TArray<TDataArray>;
  T: TJointTerms;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  J := TJointFixture.Pair(7.5, 2);
  B := TPosteriorBatch.Create(J, 4);
  try
    X := JointAround(J);
    B.LogProb(X, LnP, Blobs);
    for i := 0 to High(X) do
    begin
      T := J.EvaluateOnce(X[i], C);
      Assert.IsTrue(T.Feasible, 'vector ' + IntToStr(i));
      Assert.AreEqual(-0.5 * T.Cost, LnP[i], 0.0, 'ln p ' + IntToStr(i));
      Assert.AreEqual(2, Integer(Length(Blobs[i])));
      Assert.AreEqual(T.Minus2LnL, Blobs[i][0], 0.0, 'blob: the joint minus2lnL');
      Assert.AreEqual(T.PriorTerm, Blobs[i][1], 0.0, 'blob: the joint prior term');
    end;
  finally
    B.Free;
    J.Free;
  end;
end;

procedure TTestPosteriorBatch.Joint_SameResultAnyWorkerCount;
var
  J: TJointPosterior;
  B1, B6: TPosteriorBatch;
  X, Blobs1, Blobs6: TArray<TVector>;
  LnP1, LnP6: TArray<Double>;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  J := TJointFixture.Pair(7.5);
  B1 := TPosteriorBatch.Create(J, 1);
  B6 := TPosteriorBatch.Create(J, 6);
  try
    X := JointAround(J);
    B1.LogProb(X, LnP1, Blobs1);
    B6.LogProb(X, LnP6, Blobs6);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(LnP1[i], LnP6[i], 0.0, 'ln p ' + IntToStr(i));
      Assert.AreEqual(Blobs1[i][0], Blobs6[i][0], 0.0);
      Assert.AreEqual(Blobs1[i][1], Blobs6[i][1], 0.0);
    end;
  finally
    B6.Free;
    B1.Free;
    J.Free;
  end;
end;

procedure TTestPosteriorBatch.Joint_ModelCurves_PerMember;
var
  J: TJointPosterior;
  B: TPosteriorBatch;
  X: TArray<TVector>;
  Curves: TArray<TDataArray>;
  C: TArray<TDataArray>;
  T: TJointTerms;
  MC: TDataArray;
  i, k, m: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  J := TJointFixture.Pair(7.5);
  B := TPosteriorBatch.Create(J, 4);
  try
    X := JointAround(J);
    for m := 0 to 1 do
    begin
      B.ModelCurves(X, Curves, m);
      for i := 0 to High(X) do
      begin
        T := J.EvaluateOnce(X[i], C);
        MC := ScaledModel(C[m], T.Members[m].Nuisance);
        Assert.AreEqual(Integer(Length(MC)), Integer(Length(Curves[i])));
        for k := 0 to High(MC) do
          Assert.AreEqual(Double(MC[k].r), Double(Curves[i][k].r), 0.0,
            Format('member %d, vector %d, point %d', [m, i, k]));
      end;
    end;
  finally
    B.Free;
    J.Free;
  end;
end;

{ ln p = -(joint minus2lnL - sum_m w_m * offset_m + prior) / 2: the GPU's
  numbers hang together exactly as the CPU's do, and the prior term and
  feasibility are the CPU's own. }
procedure TTestPosteriorBatch.Joint_Gpu_LnPIsMinusHalfTheJointCost;
var
  J: TJointPosterior;
  B, C: TPosteriorBatch;
  X, Blobs, CBlobs: TArray<TVector>;
  LnP, CLnP: TArray<Double>;
  Name: string;
  Offset: Double;
  i, m: Integer;
begin
  if not GpuReady(Name) then Exit;
  J := TJointFixture.Pair(7.5, 2);
  B := TPosteriorBatch.Create(J, 4, True);
  C := TPosteriorBatch.Create(J, 4);
  try
    Assert.AreEqual(Name, B.DeviceUsed);
    X := JointAround(J);
    B.LogProb(X, LnP, Blobs);
    C.LogProb(X, CLnP, CBlobs);
    Assert.IsTrue(B.GpuUsed);
    Offset := 0;
    for m := 0 to J.MemberCount - 1 do
      Offset := Offset + J.Weights[m] * CostOffsetOf(J.Members[m]);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(IsInfinite(CLnP[i]), IsInfinite(LnP[i]), 'feasibility ' + IntToStr(i));
      Assert.AreEqual(CBlobs[i][1], Blobs[i][1], 0.0, 'the prior term is the CPU''s');
      Assert.AreEqual(-0.5 * (Blobs[i][0] - Offset + Blobs[i][1]), LnP[i],
        1E-9 * Abs(LnP[i]), 'ln p = -(minus2lnL - offset + prior) / 2');
    end;
  finally
    C.Free;
    B.Free;
    J.Free;
  end;
end;

{ FailAfter counts GPU evaluations, two per batch here (one per member):
  the fourth is member 1's in the second batch. That batch and every later
  one are scored on the CPU. }
procedure TTestPosteriorBatch.Joint_Gpu_FailsInSecondMember_ContinuesOnTheCpu;
var
  J: TJointPosterior;
  B: TPosteriorBatch;
  X, B1, B2, B3, B4: TArray<TVector>;
  L1, L2, L3, L4: TArray<Double>;
  Name: string;
  i: Integer;
begin
  if not GpuReady(Name) then Exit;
  J := TJointFixture.Pair(7.5);
  B := TPosteriorBatch.Create(J, 4, True);
  try
    X := JointAround(J);
    TGpuEvaluator.FailAfter := 4;
    try
      B.LogProb(X, L1, B1);
      B.LogProb(X, L2, B2);
      B.LogProb(X, L3, B3);
    finally
      TGpuEvaluator.FailAfter := 0;
    end;
    Assert.IsTrue(B.GpuUsed, 'the first batch ran on the GPU');
    Assert.AreEqual('CPU', B.DeviceUsed);
    Assert.Contains(B.GpuError, 'injected');
    B.LogProbOnCpu(X, L4, B4);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(L4[i], L2[i], 0.0, 'the failed batch was scored on the CPU: ' + IntToStr(i));
      Assert.AreEqual(L4[i], L3[i], 0.0, 'and every batch after it: ' + IntToStr(i));
    end;
  finally
    B.Free;
    J.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPosteriorBatch);

end.
