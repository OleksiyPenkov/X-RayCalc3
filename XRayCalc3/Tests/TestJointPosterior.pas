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

unit TestJointPosterior;

(* TJointPosterior: a one-member joint is its member, bit for bit; a link
   makes one shared slot, with the members' bounds intersected and their
   priors multiplied; the cost is the weighted sum of the members' likelihood
   costs plus every prior term; members of different layer counts never
   share a model. TJointFixture is the two-period W/B4C series the joint tests
   of Tasks 2 to 4 share. *)

interface

uses
  DUnitX.TestFramework, unit_Types, unit_ParamMap, unit_LogPosterior, unit_JointPosterior;

type
  TJointFixture = record
    /// <summary>TWB4CFixture's cell with period D and N periods: B4C-on-W 3 A,
    /// W 10 A, W-on-B4C H2 (free, [3, 9]), B4C D - 13 - H2 (derived,
    /// [D - 22, D - 16]).</summary>
    class function Structure(D, H2: Single; N: Integer): TFitStructure; static;
    /// <summary>s0.l2.thickness free, s0.l3.thickness derived, the nuisance
    /// slots of TestLogPosterior's MakeMap.</summary>
    class function Map(const S: TFitStructure): TParamMap; static;
    /// <summary>A member on data made by Structure(D, 6, N) itself, as counts
    /// N_i = round(R_i x 1e6) (intensity N_i / 1e6), whose map is Map(Start).
    /// The caller frees the result, then Map.</summary>
    class function MemberOn(const Start: TFitStructure; D: Single; N: Integer;
      out AMap: TParamMap): TLogPosterior; static;
    class function Member(D: Single; N: Integer; StartH2: Single;
      out AMap: TParamMap): TLogPosterior; static;
    /// <summary>Member(34, 20, StartH2) and Member(44, 10, StartH2), weights
    /// 1 and WeightB, s0.l2.thickness linked as "h". Owns its members.</summary>
    class function Pair(StartH2: Single; WeightB: Double = 1): TJointPosterior; static;
  end;

/// <summary>Eight joint vectors around the start: h from 5.3 to 6.7 (both
/// members' derived B4C in bounds), member 0's scale and member 1's
/// background and f varied.</summary>
function JointAround(J: TJointPosterior): TArray<TArray<Double>>;

type
  [TestFixture]
  TTestJointPosterior = class
  public
    [Test] procedure Single_IsTheMemberBitForBit;
    [Test] procedure Pair_NamesAndOrder;
    [Test] procedure Pair_CostIsWeightedSumPlusPriors;
    [Test] procedure SharedSlot_BoundsIntersect_PriorsMultiply;
    [Test] procedure MemberInfeasible_JointInfeasible;
    [Test] procedure DifferentLayerCounts_OneWorkspace_SameAsSeparate;
    [Test] procedure ReportedValues_AliasesAndDerivedPerMember;
    [Test] procedure Link_Errors;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Likelihood, TestLogPosterior, TestPosteriorBatch;

const
  I0 = 1E6;

function L(const M: string; H, HMin, HMax, Sigma, Rho: Single): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := Sigma; Result.P[2].min := Sigma; Result.P[2].max := Sigma;
  Result.P[3].V := Rho; Result.P[3].min := Rho; Result.P[3].max := Rho;
end;

class function TJointFixture.Structure(D, H2: Single; N: Integer): TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := N;
  SetLength(Result.Stacks[0].Layers, 4);
  Result.Stacks[0].Layers[0] := L('W', 3, 3, 3, 2, 11);
  Result.Stacks[0].Layers[1] := L('W', 10, 10, 10, 2, 19.3);
  Result.Stacks[0].Layers[2] := L('W', H2, 3, 9, 2, 11);
  Result.Stacks[0].Layers[3] := L('B4C', D - 13 - H2, D - 22, D - 16, 2, 2.52);
  Result.Stacks[0].D := D;
  Result.Subs := L('Si', 0, 0, 0, 3, 2.33);
end;

class function TJointFixture.Map(const S: TFitStructure): TParamMap;
begin
  Result := TParamMap.Create(S);
  Result.AddParam('s0.l2.thickness', 0, 2, 1);
  Result.SetDerived('s0.l3.thickness', 0, 3);
  Result.AddNuisance(System.Math.Log10(1.2), 0, 1E-7, 0.001, 1);
end;

class function TJointFixture.MemberOn(const Start: TFitStructure; D: Single; N: Integer;
  out AMap: TParamMap): TLogPosterior;
var
  TrueMap: TParamMap;
  TruePost: TLogPosterior;
  Data, R: TDataArray;
  Counts: TArray<Double>;
  i: Integer;
begin
  Data := TWB4CFixture.Angles;
  TrueMap := Map(Structure(D, 6, N));
  try
    TruePost := TLogPosterior.Create(TrueMap, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      TruePost.EvaluateOnce(TrueMap.StartVector, R);
    finally
      TruePost.Free;
    end;
  finally
    TrueMap.Free;
  end;
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Counts[i] := Max(Round(R[i].r * I0), 1);
    Data[i].r := Counts[i] / I0;
  end;
  AMap := Map(Start);
  Result := TLogPosterior.Create(AMap, Data, Counts, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
end;

class function TJointFixture.Member(D: Single; N: Integer; StartH2: Single;
  out AMap: TParamMap): TLogPosterior;
begin
  Result := MemberOn(Structure(D, StartH2, N), D, N, AMap);
end;

class function TJointFixture.Pair(StartH2: Single; WeightB: Double): TJointPosterior;
var
  M0, M1: TParamMap;
begin
  Result := TJointPosterior.Create(
    [Member(34, 20, StartH2, M0), Member(44, 10, StartH2, M1)], [1.0, WeightB],
    [JointLink('h', 's0.l2.thickness', [0, 1])], True);
end;

function JointAround(J: TJointPosterior): TArray<TArray<Double>>;
var
  i: Integer;
begin
  SetLength(Result, 8);
  for i := 0 to 7 do
  begin
    Result[i] := J.StartVector;
    Result[i][J.IndexOf('h')] := 5.3 + 0.2 * i;
    Result[i][J.IndexOf('m0.c0.log10_scale')] := 0.004 * (i - 4);
    Result[i][J.IndexOf('m1.c0.background')] := 1E-9 * i;
    Result[i][J.IndexOf('m1.c0.ln_f')] := Ln(0.01 + 0.004 * i);
  end;
end;

procedure SkipWithoutTables;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
end;

procedure TTestJointPosterior.Single_IsTheMemberBitForBit;
var
  Map: TParamMap;
  Post: TLogPosterior;
  J: TJointPosterior;
  X: TArray<TArray<Double>>;
  C: TArray<TDataArray>;
  R: TDataArray;
  T: TJointTerms;
  P: TPosteriorTerms;
  N1, N2: TArray<string>;
  V1, V2: TArray<Double>;
  i, k: Integer;
begin
  SkipWithoutTables;
  Post := TJointFixture.Member(34, 20, 6, Map);
  J := TJointPosterior.CreateSingle(Post);
  try
    Assert.AreEqual(Map.Count, J.Count);
    N1 := J.ReportedNames;
    N2 := Map.ReportedNames;
    Assert.AreEqual(Integer(Length(N2)), Integer(Length(N1)), 'reported names');
    for i := 0 to High(N1) do
      Assert.AreEqual(N2[i], N1[i]);
    X := Around(Map);
    for i := 0 to High(X) do
    begin
      T := J.EvaluateOnce(X[i], C);
      P := Post.EvaluateOnce(X[i], R);
      Assert.IsTrue(T.Feasible);
      Assert.AreEqual(P.Cost, T.Cost, 0.0, 'cost ' + IntToStr(i));
      Assert.AreEqual(P.Likelihood.Minus2LnL, T.Minus2LnL, 0.0, 'minus2lnL ' + IntToStr(i));
      Assert.AreEqual(P.PriorTerm, T.PriorTerm, 0.0, 'prior ' + IntToStr(i));
      Assert.AreEqual(Integer(Length(R)), Integer(Length(C[0])));
      for k := 0 to High(R) do
        Assert.AreEqual(Double(R[k].r), Double(C[0][k].r), 0.0);
      Assert.IsTrue(J.ReportedValues(X[i], V1));
      Assert.IsTrue(Map.ReportedValues(X[i], V2));
      Assert.AreEqual(Integer(Length(V2)), Integer(Length(V1)));
      for k := 0 to High(V1) do
        Assert.AreEqual(V2[k], V1[k], 0.0, 'reported value ' + IntToStr(k));
    end;
  finally
    J.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure TTestJointPosterior.Pair_NamesAndOrder;
const
  Slots: array [0 .. 6] of string = ('h', 'm0.c0.log10_scale', 'm0.c0.background',
    'm0.c0.ln_f', 'm1.c0.log10_scale', 'm1.c0.background', 'm1.c0.ln_f');
  Tail: array [0 .. 5] of string = ('m0.c0.scale', 'm0.c0.f', 'm0.s0.l3.thickness',
    'm1.c0.scale', 'm1.c0.f', 'm1.s0.l3.thickness');
var
  J: TJointPosterior;
  Names: TArray<string>;
  i: Integer;
begin
  SkipWithoutTables;
  J := TJointFixture.Pair(7.5);
  try
    Assert.AreEqual(7, J.Count);
    Assert.AreEqual(2, J.MemberCount);
    Names := J.ReportedNames;
    Assert.AreEqual(13, Integer(Length(Names)));
    for i := 0 to 6 do
    begin
      Assert.AreEqual(Slots[i], J.Slots[i].Name);
      Assert.AreEqual(Slots[i], Names[i]);
    end;
    for i := 0 to 5 do
      Assert.AreEqual(Tail[i], Names[7 + i]);
    Assert.AreEqual(0, J.IndexOf('H'), 'IndexOf ignores case, as TParamMap''s does');
    Assert.AreEqual('m1.', J.Prefixes[1]);
    Assert.IsFalse(J.Tempered);
  finally
    J.Free;
  end;
end;

procedure TTestJointPosterior.Pair_CostIsWeightedSumPlusPriors;
var
  M0, M1: TParamMap;
  P0, P1: TLogPosterior;
  J: TJointPosterior;
  Theta: TArray<Double>;
  C: TArray<TDataArray>;
  R: TDataArray;
  T: TJointTerms;
  A, B: TPosteriorTerms;
  Want: Double;
begin
  SkipWithoutTables;
  P0 := TJointFixture.Member(34, 20, 7.5, M0);
  M0.SetPrior('s0.l2.thickness', 5, 1);
  P1 := TJointFixture.Member(44, 10, 7.5, M1);
  M1.SetPrior('s0.l2.thickness', 7, 1);
  J := TJointPosterior.Create([P0, P1], [1.0, 2.0], [JointLink('h', 's0.l2.thickness', [0, 1])], True);
  try
    Assert.IsTrue(J.Tempered, 'a weight of 2 tempers');
    Theta := J.StartVector;
    Theta[0] := 6.2;
    T := J.EvaluateOnce(Theta, C);
    A := P0.EvaluateOnce(J.MemberTheta(0, Theta), R);
    B := P1.EvaluateOnce(J.MemberTheta(1, Theta), R);
    Assert.IsTrue(T.Feasible and A.Feasible and B.Feasible);
    Want := (A.Likelihood.Cost + 2 * B.Likelihood.Cost) + (A.PriorTerm + B.PriorTerm);
    Assert.AreEqual(Want, T.Cost, 1E-12 * Abs(Want), 'cost');
    Assert.AreEqual(Sqr(6.2 - 5) + Sqr(6.2 - 7), T.PriorTerm, 1E-9, 'both members'' priors');
    Assert.AreEqual(A.Likelihood.Minus2LnL + 2 * B.Likelihood.Minus2LnL, T.Minus2LnL,
      1E-12 * Abs(T.Minus2LnL), 'minus2lnL');
    Assert.AreEqual(2, Integer(Length(C)), 'one curve per member');
  finally
    J.Free;                       // owns P0, P1, M0 and M1
  end;
end;

procedure TTestJointPosterior.SharedSlot_BoundsIntersect_PriorsMultiply;
var
  M0, M1: TParamMap;
  P0, P1: TLogPosterior;
  S1: TFitStructure;
  J: TJointPosterior;
  H: TParamSlot;
begin
  SkipWithoutTables;
  P0 := TJointFixture.Member(34, 20, 7.5, M0);
  M0.SetPrior('s0.l2.thickness', 5, 1);
  S1 := TJointFixture.Structure(44, 7.5, 10);
  S1.Stacks[0].Layers[2].P[1].min := 4;
  S1.Stacks[0].Layers[2].P[1].max := 10;
  S1.Stacks[0].Layers[3].P[1].min := 21;      // B4C = 31 - h for h in [4, 10]
  S1.Stacks[0].Layers[3].P[1].max := 27;
  P1 := TJointFixture.MemberOn(S1, 44, 10, M1);
  M1.SetPrior('s0.l2.thickness', 7, 2);
  J := TJointPosterior.Create([P0, P1], [1.0, 1.0], [JointLink('h', 's0.l2.thickness', [0, 1])], True);
  try
    H := J.Slots[0];
    Assert.AreEqual(4.0, H.Lower, 1E-6, 'the larger lower bound');
    Assert.AreEqual(9.0, H.Upper, 1E-6, 'the smaller upper bound');
    Assert.AreEqual(7.5, H.Start, 1E-6, 'member 0''s start, inside the intersection');
    Assert.IsTrue(H.HasPrior);
    { precision 1 + 1/4 = 1.25; mean (5/1 + 7/4) / 1.25 = 5.4; sd 1/sqrt(1.25) }
    Assert.AreEqual(5.4, H.PriorMean, 1E-12);
    Assert.AreEqual(1 / Sqrt(1.25), H.PriorSD, 1E-12);
  finally
    J.Free;
  end;
end;

procedure TTestJointPosterior.MemberInfeasible_JointInfeasible;
var
  M0, M1: TParamMap;
  P0, P1: TLogPosterior;
  S1: TFitStructure;
  J: TJointPosterior;
  Theta: TArray<Double>;
  C: TArray<TDataArray>;
  T: TJointTerms;
  Who: Integer;
begin
  SkipWithoutTables;
  P0 := TJointFixture.Member(34, 20, 6, M0);
  S1 := TJointFixture.Structure(44, 6, 10);
  S1.Stacks[0].Layers[3].P[1].min := 24.5;    // B4C = 31 - h: feasible for h in [5.5, 6.5]
  S1.Stacks[0].Layers[3].P[1].max := 25.5;
  P1 := TJointFixture.MemberOn(S1, 44, 10, M1);
  J := TJointPosterior.Create([P0, P1], [1.0, 1.0], [JointLink('h', 's0.l2.thickness', [0, 1])], True);
  try
    Theta := J.StartVector;
    Theta[0] := 7;
    Assert.IsFalse(J.Feasible(Theta, Who));
    Assert.AreEqual(1, Who, 'member 1 is the one out of its support');
    T := J.EvaluateOnce(Theta, C);
    Assert.IsFalse(T.Feasible);
    Assert.AreEqual(INFEASIBLE_COST, T.Cost, 0.0);
    Theta[0] := 6;
    Assert.IsTrue(J.Feasible(Theta, Who));
    Assert.AreEqual(-1, Who);
    Assert.IsTrue(J.EvaluateOnce(Theta, C).Feasible);
  finally
    J.Free;
  end;
end;

{ Members of 20 and 10 periods, in both orders, on one workspace: every
  evaluation equals a fresh EvaluateOnce. A model shared between the members
  would keep the 20-period member's layers when the 10-period one is filled
  (TLayeredModel's arrays only grow), and the second curve would differ. }
procedure TTestJointPosterior.DifferentLayerCounts_OneWorkspace_SameAsSeparate;

  procedure Check(J: TJointPosterior);
  var
    W: TJointWorkspace;
    Theta: TArray<Double>;
    C1, C2: TArray<TDataArray>;
    T1, T2: TJointTerms;
    i, m, k: Integer;
  begin
    W := J.NewWorkspace;
    try
      for i := 0 to 3 do
      begin
        Theta := J.StartVector;
        Theta[0] := 5.5 + 0.3 * i;
        T1 := J.Evaluate(W, Theta, C1);
        T2 := J.EvaluateOnce(Theta, C2);
        Assert.AreEqual(T2.Cost, T1.Cost, 0.0, 'cost ' + IntToStr(i));
        for m := 0 to J.MemberCount - 1 do
          for k := 0 to High(C2[m]) do
            Assert.AreEqual(Double(C2[m][k].r), Double(C1[m][k].r), 0.0,
              Format('member %d point %d', [m, k]));
      end;
    finally
      TJointPosterior.FreeWorkspace(W);
    end;
  end;

var
  M0, M1: TParamMap;
  J: TJointPosterior;
begin
  SkipWithoutTables;
  J := TJointFixture.Pair(7.5);                       // 20 periods, then 10
  try
    Check(J);
  finally
    J.Free;
  end;
  J := TJointPosterior.Create(
    [TJointFixture.Member(44, 10, 7.5, M1), TJointFixture.Member(34, 20, 7.5, M0)], [1.0, 1.0],
    [JointLink('h', 's0.l2.thickness', [0, 1])], True); // 10 periods, then 20
  try
    Check(J);
  finally
    J.Free;
  end;
end;

procedure TTestJointPosterior.ReportedValues_AliasesAndDerivedPerMember;
var
  J: TJointPosterior;
  Theta, V: TArray<Double>;
  i: Integer;
begin
  SkipWithoutTables;
  J := TJointFixture.Pair(7.5);
  try
    Theta := J.StartVector;
    Theta[0] := 6;
    Theta[1] := 0.01;           // m0.c0.log10_scale
    Theta[3] := Ln(0.02);       // m0.c0.ln_f
    Assert.IsTrue(J.ReportedValues(Theta, V));
    Assert.AreEqual(13, Integer(Length(V)));
    for i := 0 to 6 do
      Assert.AreEqual(Theta[i], V[i], 0.0);
    Assert.AreEqual(Power(10, 0.01), V[7], 1E-12, 'm0.c0.scale');
    Assert.AreEqual(0.02, V[8], 1E-12, 'm0.c0.f');
    Assert.AreEqual(15.0, V[9], 1E-5, 'm0.s0.l3.thickness = 34 - 13 - 6');
    Assert.AreEqual(25.0, V[12], 1E-5, 'm1.s0.l3.thickness = 44 - 13 - 6');
  finally
    J.Free;
  end;
end;

{ True when the joint refuses these members, weights and links. A plain
  function, not Assert.WillRaise: an anonymous method in a nested routine
  cannot capture the outer routine's locals (E2555). }
function RaisesJoint(const Members: TArray<TLogPosterior>; const Weights: TArray<Double>;
  const Links: TArray<TJointLink>): Boolean;
begin
  try
    TJointPosterior.Create(Members, Weights, Links, False).Free;
    Result := False;
  except
    on EJointPosterior do
      Result := True;
  end;
end;

procedure TTestJointPosterior.Link_Errors;
var
  M0, M1, M2: TParamMap;
  P0, P1, P2: TLogPosterior;
  S2: TFitStructure;
  Bad: TJointLink;

  procedure Refused(const Links: TArray<TJointLink>; const Weights: TArray<Double>;
    const Why: string);
  begin
    Assert.IsTrue(RaisesJoint([P0, P1, P2], Weights, Links), 'refused: ' + Why);
  end;

begin
  SkipWithoutTables;
  P0 := TJointFixture.Member(34, 20, 7.5, M0);
  P1 := TJointFixture.Member(44, 10, 7.5, M1);
  S2 := TJointFixture.Structure(44, 10, 10);
  S2.Stacks[0].Layers[2].P[1].min := 9.5;             // no overlap with [3, 9]
  S2.Stacks[0].Layers[2].P[1].max := 12;
  S2.Stacks[0].Layers[3].P[1].min := 19;
  S2.Stacks[0].Layers[3].P[1].max := 22;
  P2 := TJointFixture.MemberOn(S2, 44, 10, M2);
  try
    Refused([JointLink('h', 's0.l1.thickness', [0, 1])], [1.0, 1.0, 1.0], 'not a free slot');
    Refused([JointLink('h', 's0.l3.thickness', [0, 1])], [1.0, 1.0, 1.0], 'a derived layer');
    Refused([JointLink('h', 's0.l2.thickness', [0])], [1.0, 1.0, 1.0], 'one member');
    Refused([JointLink('h', 's0.l2.thickness', [0, 0])], [1.0, 1.0, 1.0], 'a member twice');
    Refused([JointLink('h', 's0.l2.thickness', [0, 3])], [1.0, 1.0, 1.0], 'no member 3');
    Refused([JointLink('h', 's0.l2.thickness', [0, 2])], [1.0, 1.0, 1.0], 'empty intersection');
    Refused([JointLink('h', 's0.l2.thickness', [0, 1]), JointLink('h', 'c0.ln_f', [0, 1])],
      [1.0, 1.0, 1.0], 'two links named h');
    Refused([JointLink('h', 's0.l2.thickness', [0, 1]), JointLink('g', 's0.l2.thickness', [1, 2])],
      [1.0, 1.0, 1.0], 'member 1''s slot in two links');
    Refused([JointLink('m0.c0.background', 's0.l2.thickness', [0, 1])], [1.0, 1.0, 1.0],
      'a link name that is also a member''s prefixed name');
    Refused([JointLink('h', 's0.l2.thickness', [0, 1])], [1.0, 0.0, 1.0], 'a zero weight');
    Refused([JointLink('h', 's0.l2.thickness', [0, 1])], [1.0, 1.0], 'two weights for three members');
    Bad := JointLink('h', 's0.l2.thickness', [0, 1]);
    Bad.A := 2;
    Refused([Bad], [1.0, 1.0, 1.0], 'an affine tie');
  finally
    P2.Free; M2.Free;
    P1.Free; M1.Free;
    P0.Free; M0.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestJointPosterior);

end.
