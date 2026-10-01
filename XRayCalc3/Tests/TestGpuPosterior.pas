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

unit TestGpuPosterior;

(* The posterior on the GPU (phase B2). PosteriorGpuInputs hands the kernel
   exactly the points CurveLikelihood sums; TGpuPosteriorScorer (task 3) scores
   a batch as the CPU would score it on the GPU's own curve. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestGpuPosterior = class
  public
    [Test] procedure Inputs_MirrorTheLikelihood;
    [Test] procedure Inputs_ZeroIntensity_IsExcludedNotRefused;
    [Test] procedure Score_MatchesTheCpuOnTheGpuCurve;
    [Test] procedure Score_InfeasibleAmongFeasible;
    [Test] procedure Score_BatchSizesChange_SameValues;
    [Test] procedure Score_SameAnyWorkerCount;
    [Test] procedure JointScorer_Single_IsTheMemberScorer;
    [Test] procedure JointScorer_Pair_IsTheWeightedSumOfItsMembers;
    [Test] procedure JointScorer_InfeasibleInOneMember_AsTheCpuDecides;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Types, unit_materials, unit_calc, unit_gpu_calc,
  unit_Likelihood, unit_ParamMap, unit_LogPosterior, unit_GpuPosterior, TestLogPosterior,
  TestPosteriorBatch, unit_JointPosterior, TestJointPosterior;

{ The W/B4C map: the W-on-B4C interlayer free with a prior, B4C derived. }
function NewMap: TParamMap;
begin
  Result := TParamMap.Create(TWB4CFixture.Structure(6));
  Result.AddParam('s0.l2.thickness', 0, 2, 1);
  Result.SetDerived('s0.l3.thickness', 0, 3);
  Result.AddNuisance(System.Math.Log10(1.2), 0, 1E-7, 0.001, 1);
  Result.SetPrior('s0.l2.thickness', 6.2, 0.3);
end;

{ The posterior of NewMap on data made by its own curve at the start vector,
  as counts at a peak rate of 1e6, so that the high-angle points fall below
  NMin = 10. A 0.01 deg resolution leaves the convolution edges out. The caller
  frees the result, then Map. }
function MakeCountedPosterior(out Map: TParamMap): TLogPosterior;
var
  Data, R: TDataArray;
  Counts: TArray<Double>;
  P: TCalcThreadParams;
  i: Integer;
begin
  Map := NewMap;
  Data := TWB4CFixture.Angles;
  P := TWB4CFixture.CalcParams(Data, 0.01);
  Result := TLogPosterior.Create(Map, Data, nil, P, 1E-9, 10);
  try
    Result.EvaluateOnce(Map.StartVector, R);
  finally
    Result.Free;
  end;
  SetLength(Counts, Length(Data));
  for i := 0 to High(Data) do
  begin
    Counts[i] := Round(R[i].r * 1E6);
    Data[i].r := Max(Counts[i], 1) / 1E6;
  end;
  Result := TLogPosterior.Create(Map, Data, Counts, P, 1E-9, 10);
end;

procedure TTestGpuPosterior.Inputs_MirrorTheLikelihood;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Inputs: TGpuEvalInputs;
  Lik: TGpuLikInputs;
  Offset: Double;
  i, N, Excluded: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Post := MakeCountedPosterior(Map);
  try
    Inputs := PosteriorGpuInputs(Post, Lik, Offset);
    N := Length(Post.Data);
    Assert.AreEqual(N, Integer(Length(Inputs.Theta)));
    Assert.AreEqual(N, Integer(Length(Lik.LnData)));
    Assert.AreEqual(N, Integer(Length(Lik.InvN)));
    Assert.IsTrue(Post.First > 0, 'the resolution leaves the edges out');
    Assert.AreEqual(Post.First, Inputs.ConvN, 'the first point summed has a whole window');
    Assert.AreEqual(Post.First, Inputs.ChiFirst, 'the kernel sums the points CurveLikelihood sums');
    Assert.AreEqual(Post.Last, Inputs.ChiLast);
    Excluded := 0;
    for i := 0 to N - 1 do
    begin
      Assert.AreEqual(Single(Post.Data[i].t), Inputs.Theta[i], 'angle ' + IntToStr(i));
      if PointUsed(Post.Data, Post.Counts, i, Post.NMin) then
      begin
        Assert.AreEqual(Single(1 / Post.Counts[i]), Lik.InvN[i], '1/N at ' + IntToStr(i));
        Assert.AreEqual(Single(Ln(Post.Data[i].r)), Lik.LnData[i], 'ln D at ' + IntToStr(i));
      end
      else
      begin
        Assert.AreEqual(Single(-1), Lik.InvN[i], 'left out: ' + IntToStr(i));
        Inc(Excluded);
      end;
    end;
    Assert.IsTrue(Excluded > 0, 'some high-angle points fall below NMin');
    Assert.AreEqual(Single(Sqr(Map.FMin)), Lik.FMin2);
    Assert.AreEqual(LikelihoodCostOffset(Post.Data, Post.Counts, Post.First, Post.Last,
      Post.NMin, Map.FMin), Offset, 0.0, 'the cost offset');
  finally
    Post.Free;
    Map.Free;
  end;
end;

{ TCalc.GpuInputs raises on a non-positive intensity (the classic chi2 takes
  its log); the likelihood leaves such a point out instead. }
procedure TTestGpuPosterior.Inputs_ZeroIntensity_IsExcludedNotRefused;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Data: TDataArray;
  Inputs: TGpuEvalInputs;
  Lik: TGpuLikInputs;
  Offset: Double;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Map := NewMap;
  try
    Data := TWB4CFixture.Angles;                     // r = 1 everywhere
    Data[20].r := 0;
    Data[150].r := 0;
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Inputs := PosteriorGpuInputs(Post, Lik, Offset);
      for i := 0 to High(Data) do
        if (i = 20) or (i = 150) then
          Assert.AreEqual(Single(-1), Lik.InvN[i], 'zero intensity left out: ' + IntToStr(i))
        else
        begin
          Assert.AreEqual(Single(0), Lik.InvN[i], 'no counts: 1/N = 0 at ' + IntToStr(i));
          Assert.AreEqual(Single(0), Lik.LnData[i], 'ln 1 at ' + IntToStr(i));
        end;
      Assert.AreEqual((Length(Data) - 2) * Ln(Sqr(Map.FMin)), Offset,
        1E-9 * Abs(Offset), 'ln fmin^2 per kept point');
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

function GpuReady: Boolean;
var
  Name, Err: string;
begin
  Result := False;
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed')
  else if not TGpuEvaluator.Available(Name, Err) then
    Assert.Pass('No usable GPU on this machine: ' + Err)
  else
    Result := True;
end;

function NewModels(Count: Integer): TArray<TLayeredModel>;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
  begin
    Result[i] := TLayeredModel.Create;
    Result[i].Init;
  end;
end;

procedure FreeModels(const Models: TArray<TLayeredModel>);
var
  i: Integer;
begin
  for i := 0 to High(Models) do
    Models[i].Free;
end;

{ What the kernel must reproduce, to single precision, for vector i of the
  last Score: the CPU's likelihood on the GPU's own raw curve, plus the CPU's
  prior term. }
function CpuOnGpuCurve(Post: TLogPosterior; G: TGpuEvaluator; i: Integer;
  const Theta: TArray<Double>; out Minus2LnL: Double): Double;
var
  Calc: TCalc;
  S: TFitStructure;
  Nuis: TNuisance;
  T: TLikelihoodTerms;
begin
  Post.Map.Template.CopyContent(S);
  Assert.IsTrue(Post.Map.Apply(Theta, S, Nuis), 'vector ' + IntToStr(i) + ' is feasible');
  Calc := Post.NewCalc;
  try
    Calc.FinishRawCurve(G.RawCurve(i));
    T := CurveLikelihood(Post.Data, Calc.Results, Post.Counts, Post.First, Post.Last,
      Post.NMin, Nuis, Post.Map.FMin);
  finally
    Calc.Free;
  end;
  Minus2LnL := T.Minus2LnL;
  Result := T.Cost + Post.Map.PriorTerm(Theta, S);
end;

procedure TTestGpuPosterior.Score_MatchesTheCpuOnTheGpuCurve;
var
  Map: TParamMap;
  Post: TLogPosterior;
  G: TGpuEvaluator;
  Sc: TGpuPosteriorScorer;
  Models: TArray<TLayeredModel>;
  X: TArray<TArray<Double>>;
  Scores: TArray<TGpuPosteriorScore>;
  R: TDataArray;
  i: Integer;
  Want, WantM2: Double;
begin
  if not GpuReady then Exit;
  Post := MakeCountedPosterior(Map);
  Models := NewModels(4);
  G := TGpuEvaluator.Create;
  Sc := TGpuPosteriorScorer.Create(Post);
  try
    X := Around(Map);
    Sc.Score(G, Models, X, Scores);
    Assert.AreEqual(Length(X), Length(Scores));
    for i := 0 to High(X) do
    begin
      Assert.IsTrue(Scores[i].Feasible, 'vector ' + IntToStr(i));
      Assert.AreEqual(Post.EvaluateOnce(X[i], R).PriorTerm, Scores[i].PriorTerm, 0.0,
        'the prior term is the CPU''s: ' + IntToStr(i));
      Want := CpuOnGpuCurve(Post, G, i, X[i], WantM2);
      Assert.AreEqual(Want, Scores[i].Cost, 2E-4 * Max(1, Abs(Want)), 'cost ' + IntToStr(i));
      Assert.AreEqual(WantM2, Scores[i].Minus2LnL, 2E-4 * Max(1, Abs(WantM2)),
        'minus2lnL ' + IntToStr(i));
    end;
  finally
    Sc.Free;
    G.Free;
    FreeModels(Models);
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestGpuPosterior.Score_InfeasibleAmongFeasible;
var
  Map: TParamMap;
  Post: TLogPosterior;
  G: TGpuEvaluator;
  Sc: TGpuPosteriorScorer;
  Models: TArray<TLayeredModel>;
  X, Y: TArray<TArray<Double>>;
  A, B: TArray<TGpuPosteriorScore>;
  i: Integer;
begin
  if not GpuReady then Exit;
  Post := MakeCountedPosterior(Map);
  Models := NewModels(4);
  G := TGpuEvaluator.Create;
  Sc := TGpuPosteriorScorer.Create(Post);
  try
    X := Around(Map);
    Sc.Score(G, Models, X, A);
    SetLength(Y, Length(X));
    for i := 0 to High(X) do
      Y[i] := Copy(X[i]);
    Y[3][Map.IndexOf('s0.l2.thickness')] := 9.5;         // above its bound of 9
    Sc.Score(G, Models, Y, B);
    Assert.IsFalse(B[3].Feasible);
    Assert.AreEqual(INFEASIBLE_COST, B[3].Cost, 0.0);
    for i := 0 to High(X) do
      if i <> 3 then
      begin
        Assert.IsTrue(B[i].Feasible);
        Assert.AreEqual(A[i].Cost, B[i].Cost, 0.0, 'neighbour ' + IntToStr(i) + ' unchanged');
        Assert.AreEqual(A[i].Minus2LnL, B[i].Minus2LnL, 0.0);
      end;
  finally
    Sc.Free;
    G.Free;
    FreeModels(Models);
    Post.Free;
    Map.Free;
  end;
end;

{ A sampler scores W vectors, then W/2 per half-step, and redraws come in any
  size: a vector's score must not depend on the batch it came in. }
procedure TTestGpuPosterior.Score_BatchSizesChange_SameValues;
var
  Map: TParamMap;
  Post: TLogPosterior;
  G: TGpuEvaluator;
  Sc: TGpuPosteriorScorer;
  Models: TArray<TLayeredModel>;
  X, Small, Big: TArray<TArray<Double>>;
  A, B, C: TArray<TGpuPosteriorScore>;
  i: Integer;
begin
  if not GpuReady then Exit;
  Post := MakeCountedPosterior(Map);
  Models := NewModels(4);
  G := TGpuEvaluator.Create;
  Sc := TGpuPosteriorScorer.Create(Post);
  try
    X := Around(Map);                                   // 12
    Sc.Score(G, Models, X, A);
    Small := Copy(X, 0, 5);
    Sc.Score(G, Models, Small, B);                      // smaller: the sizing stays
    Big := X + Copy(X, 0, 8);                           // 20: the evaluator is sized again
    Sc.Score(G, Models, Big, C);
    for i := 0 to High(Small) do
      Assert.AreEqual(A[i].Cost, B[i].Cost, 0.0, 'small batch, vector ' + IntToStr(i));
    for i := 0 to High(Big) do
      Assert.AreEqual(A[i mod 12].Cost, C[i].Cost, 0.0, 'big batch, vector ' + IntToStr(i));
  finally
    Sc.Free;
    G.Free;
    FreeModels(Models);
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestGpuPosterior.Score_SameAnyWorkerCount;
var
  Map: TParamMap;
  Post: TLogPosterior;
  G: TGpuEvaluator;
  Sc1, Sc6: TGpuPosteriorScorer;
  M1, M6: TArray<TLayeredModel>;
  X: TArray<TArray<Double>>;
  A, B: TArray<TGpuPosteriorScore>;
  i: Integer;
begin
  if not GpuReady then Exit;
  Post := MakeCountedPosterior(Map);
  M1 := NewModels(1);
  M6 := NewModels(6);
  G := TGpuEvaluator.Create;
  Sc1 := TGpuPosteriorScorer.Create(Post);
  Sc6 := TGpuPosteriorScorer.Create(Post);
  try
    X := Around(Map);
    Sc1.Score(G, M1, X, A);
    Sc6.Score(G, M6, X, B);            // a second scorer on the same evaluator sizes it again
    for i := 0 to High(X) do
      Assert.AreEqual(A[i].Cost, B[i].Cost, 0.0, 'vector ' + IntToStr(i));
  finally
    Sc6.Free;
    Sc1.Free;
    G.Free;
    FreeModels(M6);
    FreeModels(M1);
    Post.Free;
    Map.Free;
  end;
end;

function Workspaces(J: TJointPosterior; Count: Integer): TArray<TJointWorkspace>;
var
  i: Integer;
begin
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := J.NewWorkspace;
end;

procedure FreeWorkspaces(var W: TArray<TJointWorkspace>);
var
  i: Integer;
begin
  for i := 0 to High(W) do
    TJointPosterior.FreeWorkspace(W[i]);
end;

{ A one-member joint scores exactly as its member's own scorer on the same
  evaluator: the combination adds nothing to one member of weight 1. }
procedure TTestGpuPosterior.JointScorer_Single_IsTheMemberScorer;
var
  Map: TParamMap;
  Post: TLogPosterior;
  J: TJointPosterior;
  G: TGpuEvaluator;
  Sc: TGpuPosteriorScorer;
  JS: TGpuJointScorer;
  Models: TArray<TLayeredModel>;
  W: TArray<TJointWorkspace>;
  X: TArray<TArray<Double>>;
  A, B: TArray<TGpuPosteriorScore>;
  i: Integer;
begin
  if not GpuReady then Exit;
  Post := MakeCountedPosterior(Map);
  J := TJointPosterior.CreateSingle(Post);
  Models := NewModels(4);
  W := Workspaces(J, 4);
  G := TGpuEvaluator.Create;
  Sc := TGpuPosteriorScorer.Create(Post);
  JS := TGpuJointScorer.Create(J);
  try
    X := Around(Map);
    X[3][Map.IndexOf('s0.l2.thickness')] := 9.5;       // one infeasible vector
    Sc.Score(G, Models, X, A);
    JS.Score(G, W, X, B);
    Assert.AreEqual(Integer(Length(A)), Integer(Length(B)));
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(A[i].Feasible, B[i].Feasible, 'feasible ' + IntToStr(i));
      Assert.AreEqual(A[i].Cost, B[i].Cost, 0.0, 'cost ' + IntToStr(i));
      Assert.AreEqual(A[i].Minus2LnL, B[i].Minus2LnL, 0.0, 'minus2lnL ' + IntToStr(i));
      Assert.AreEqual(A[i].PriorTerm, B[i].PriorTerm, 0.0, 'prior ' + IntToStr(i));
      Assert.AreEqual(A[i].LikCost, B[i].LikCost, 0.0, 'likelihood cost ' + IntToStr(i));
    end;
    Assert.AreEqual(INFEASIBLE_COST, B[3].Cost, 0.0);
  finally
    JS.Free;
    Sc.Free;
    G.Free;
    FreeWorkspaces(W);
    FreeModels(Models);
    J.Free;
    Post.Free;
    Map.Free;
  end;
end;

{ Two members of 20 and 10 periods, the second of weight 2: every joint score
  is the weighted sum of what each member's own scorer gives on an evaluator
  of its own. }
procedure TTestGpuPosterior.JointScorer_Pair_IsTheWeightedSumOfItsMembers;
var
  J: TJointPosterior;
  G, G1: TGpuEvaluator;
  JS: TGpuJointScorer;
  S0, S1: TGpuPosteriorScorer;
  W: TArray<TJointWorkspace>;
  M0, M1: TArray<TLayeredModel>;
  X, X0, X1: TArray<TArray<Double>>;
  B, A0, A1: TArray<TGpuPosteriorScore>;
  i: Integer;
  Want: Double;
begin
  if not GpuReady then Exit;
  J := TJointFixture.Pair(7.5, 2);
  W := Workspaces(J, 4);
  M0 := NewModels(4);
  M1 := NewModels(4);
  G := TGpuEvaluator.Create;
  G1 := TGpuEvaluator.Create;
  JS := TGpuJointScorer.Create(J);
  S0 := TGpuPosteriorScorer.Create(J.Members[0]);
  S1 := TGpuPosteriorScorer.Create(J.Members[1]);
  try
    X := JointAround(J);
    JS.Score(G, W, X, B);
    SetLength(X0, Length(X));
    SetLength(X1, Length(X));
    for i := 0 to High(X) do
    begin
      X0[i] := J.MemberTheta(0, X[i]);
      X1[i] := J.MemberTheta(1, X[i]);
    end;
    S0.Score(G, M0, X0, A0);
    S1.Score(G1, M1, X1, A1);
    for i := 0 to High(X) do
    begin
      Assert.IsTrue(B[i].Feasible and A0[i].Feasible and A1[i].Feasible, 'vector ' + IntToStr(i));
      Want := (A0[i].LikCost + 2 * A1[i].LikCost) + (A0[i].PriorTerm + A1[i].PriorTerm);
      Assert.AreEqual(Want, B[i].Cost, 1E-9 * Max(1, Abs(Want)), 'cost ' + IntToStr(i));
      Want := A0[i].Minus2LnL + 2 * A1[i].Minus2LnL;
      Assert.AreEqual(Want, B[i].Minus2LnL, 1E-9 * Max(1, Abs(Want)), 'minus2lnL ' + IntToStr(i));
    end;
  finally
    S1.Free;
    S0.Free;
    JS.Free;
    G1.Free;
    G.Free;
    FreeModels(M1);
    FreeModels(M0);
    FreeWorkspaces(W);
    J.Free;
  end;
end;

{ Member 1's derived B4C only fits for h in [5.5, 6.5]: every vector outside
  it is infeasible for the joint - on the GPU exactly where the CPU says so -
  and its neighbours still score. }
procedure TTestGpuPosterior.JointScorer_InfeasibleInOneMember_AsTheCpuDecides;
var
  M0, M1: TParamMap;
  P0, P1: TLogPosterior;
  S1: TFitStructure;
  J: TJointPosterior;
  G: TGpuEvaluator;
  JS: TGpuJointScorer;
  W: TArray<TJointWorkspace>;
  X: TArray<TArray<Double>>;
  B: TArray<TGpuPosteriorScore>;
  i, Who: Integer;
begin
  if not GpuReady then Exit;
  P0 := TJointFixture.Member(34, 20, 6, M0);
  S1 := TJointFixture.Structure(44, 6, 10);
  S1.Stacks[0].Layers[3].P[1].min := 24.5;
  S1.Stacks[0].Layers[3].P[1].max := 25.5;
  P1 := TJointFixture.MemberOn(S1, 44, 10, M1);
  J := TJointPosterior.Create([P0, P1], [1, 1], [JointLink('h', 's0.l2.thickness', [0, 1])], True);
  W := Workspaces(J, 4);
  G := TGpuEvaluator.Create;
  JS := TGpuJointScorer.Create(J);
  try
    X := JointAround(J);                               // h from 5.3 to 6.7
    JS.Score(G, W, X, B);
    for i := 0 to High(X) do
    begin
      Assert.AreEqual(J.Feasible(X[i], Who), B[i].Feasible, 'vector ' + IntToStr(i));
      if B[i].Feasible then
        Assert.IsTrue(B[i].Cost < INFEASIBLE_COST)
      else
        Assert.AreEqual(INFEASIBLE_COST, B[i].Cost, 0.0);
    end;
    Assert.IsFalse(B[0].Feasible, 'h 5.3 leaves member 1''s support');
    Assert.IsTrue(B[3].Feasible, 'h 5.9 is inside it');
  finally
    JS.Free;
    G.Free;
    FreeWorkspaces(W);
    J.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestGpuPosterior);

end.
