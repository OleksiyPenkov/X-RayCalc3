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

unit unit_GpuPosterior;

(* A TLogPosterior on the GPU (phase B2). The GPU computes each vector's curve
   (TGpuEvaluator's Reflect kernel) and its likelihood cost (LogLik); the CPU
   maps the vector to a structure, decides feasibility, adds the prior term
   and expands the model into layers. PosteriorGpuInputs hands the kernel
   exactly the points unit_Likelihood.CurveLikelihood sums.
   TGpuPosteriorScorer scores a batch of vectors this way: the CPU maps and
   packs every vector in parallel (one model per worker), the GPU computes
   the curve and the likelihood cost, and the CPU adds the prior term.

   TGpuJointScorer does the same for a TJointPosterior: one member scorer, and one
   evaluator, per member - member 0 on the caller's evaluator, whose Reflect
   output TLFPSO_BASE.FindTheBest reads back for member 0's curve - combined
   as TJointPosterior.Evaluate combines the members on the CPU. *)

interface

uses
  unit_Types, unit_materials, unit_calc, unit_gpu_calc, unit_LogPosterior, unit_JointPosterior;

/// <summary>The evaluator's inputs for Post: the angles, the convolution and
/// the summed range exactly as TLogPosterior uses them, and the likelihood's
/// per-point ln D and 1/N (-1 where PointUsed leaves the point out). A
/// non-positive intensity is left out, never refused (TCalc.GpuInputs would
/// raise). CostOffset is LikelihoodCostOffset: Minus2LnL = Cost + CostOffset.
/// </summary>
function PosteriorGpuInputs(Post: TLogPosterior; out Lik: TGpuLikInputs;
  out CostOffset: Double): TGpuEvalInputs;

type
  /// <summary>One vector's score on the GPU, in TPosteriorTerms' terms.</summary>
  TGpuPosteriorScore = record
    Feasible: Boolean;   // TParamMap.Apply's answer, as TLogPosterior decides it
    Cost: Double;        // likelihood cost + prior term; INFEASIBLE_COST when not Feasible
    Minus2LnL: Double;   // the data term (TLikelihoodTerms.Minus2LnL)
    PriorTerm: Double;   // TParamMap.PriorTerm, computed on the CPU
    LikCost: Double;     // the likelihood cost alone (TLikelihoodTerms.Cost); 0 when not Feasible
  end;

  /// <summary>Scores batches of a TLogPosterior's vectors on a
  /// TGpuEvaluator. The CPU maps, checks and expands every vector (in
  /// parallel, one model per worker) and adds the prior term; the GPU
  /// computes the curve and the likelihood cost. It draws no random numbers,
  /// owns neither the posterior nor the evaluator, and calls the evaluator
  /// from the calling thread only.</summary>
  TGpuPosteriorScorer = class
  private
    FPosterior: TLogPosterior;
    FInputs: TGpuEvalInputs;
    FLik: TGpuLikInputs;
    FCostOffset: Double;
    FPrepared: TGpuEvaluator;     // the evaluator Prepare last sized
    FCapacity, FNLay: Integer;
    FLayers, FNuis, FCost: TArray<Single>;
    procedure Prepare(Gpu: TGpuEvaluator; Model: TLayeredModel; Count: Integer);
  public
    constructor Create(APosterior: TLogPosterior);
    /// <summary>Scores[i] for Thetas[i]. Models: one per worker, at least
    /// one. Raises on any GPU or packing failure.</summary>
    procedure Score(Gpu: TGpuEvaluator; const Models: TArray<TLayeredModel>;
      const Thetas: TArray<TArray<Double>>; out Scores: TArray<TGpuPosteriorScore>);
    /// <summary>Minus2LnL - likelihood cost, the same for every vector.</summary>
    property CostOffset: Double read FCostOffset;
  end;

  /// <summary>Scores batches of a TJointPosterior's vectors on the GPU. Member
  /// m is scored by a TGpuPosteriorScorer of its own on member m's models of
  /// every worker; member 0 on the caller's evaluator, every other member on
  /// an evaluator this scorer creates on its first Score. The members' scores
  /// combine as TJointPosterior.Evaluate combines them, so a one-member joint
  /// scores exactly as its member's scorer. It draws no random numbers, owns
  /// neither the joint nor the caller's evaluator, and uses the evaluators
  /// from the calling thread only. Raises on any GPU or packing failure.</summary>
  TGpuJointScorer = class
  private
    FJoint: TJointPosterior;
    FScorers: TArray<TGpuPosteriorScorer>;
    FExtra: TArray<TGpuEvaluator>;      // [member]; [0] stays nil, the others on first use
  public
    constructor Create(AJoint: TJointPosterior);
    destructor Destroy; override;
    procedure Score(Gpu: TGpuEvaluator; const Work: TArray<TJointWorkspace>;
      const Thetas: TArray<TArray<Double>>; out Scores: TArray<TGpuPosteriorScore>);
  end;

implementation

uses
  System.SysUtils, System.Math, Winapi.Windows, Winapi.Messages, OtlParallel, unit_otl_drain,
  unit_Likelihood, unit_ParamMap, unit_LFPSO_Base;

function PosteriorGpuInputs(Post: TLogPosterior; out Lik: TGpuLikInputs;
  out CostOffset: Double): TGpuEvalInputs;
var
  i, N, ConvN: Integer;
  Width: Single;
  Data: TDataArray;
  Counts: TArray<Double>;
begin
  Data := Post.Data;
  Counts := Post.Counts;
  N := Length(Data);
  Result := Default(TGpuEvalInputs);
  SetLength(Result.Theta, N);
  SetLength(Result.LogData, N);        // ChiSquare's input; LogLik does not read it
  SetLength(Result.PointWeight, N);
  SetLength(Lik.LnData, N);
  SetLength(Lik.InvN, N);
  for i := 0 to N - 1 do
  begin
    Result.Theta[i] := Data[i].t;
    Result.PointWeight[i] := 1;
    if PointUsed(Data, Counts, i, Post.NMin) then
    begin
      Lik.LnData[i] := Ln(Data[i].r);
      if Length(Counts) > 0 then
        Lik.InvN[i] := 1 / Counts[i]
      else
        Lik.InvN[i] := 0;
    end
    else
    begin
      Lik.LnData[i] := 0;
      Lik.InvN[i] := -1;
    end;
  end;
  Lik.FMin2 := Sqr(Post.Map.FMin);

  { The convolution as TCalc.GpuInputs builds it; TLogPosterior's First is
    this same half-window, so the kernel sums exactly its points. }
  Width := Post.CalcParams.DT * Post.CalcParams.K;
  if Width = 0 then
  begin
    Result.ConvWeights := [1];
    ConvN := 0;
  end
  else
    Result.ConvWeights := ConvolutionWeights(Data[0].t, Data[N - 1].t, N, Width, ConvN);
  if ConvN <> Post.First then
    raise EGpuError.CreateFmt('The GPU convolution half-window %d is not the ' +
      'likelihood''s %d', [ConvN, Post.First]);
  Result.ConvN := ConvN;
  Result.ChiFirst := Post.First;
  Result.ChiLast := Post.Last;
  Result.ChiNorm := 1;
  Result.SolveScale := False;
  Result.ScaleWindow := 0;
  CostOffset := LikelihoodCostOffset(Data, Counts, Post.First, Post.Last, Post.NMin,
    Post.Map.FMin);
end;

constructor TGpuPosteriorScorer.Create(APosterior: TLogPosterior);
begin
  inherited Create;
  FPosterior := APosterior;
  FInputs := PosteriorGpuInputs(APosterior, FLik, FCostOffset);
end;

{ Sizes Gpu for Count vectors. Every slot starts as the template's model with
  a neutral nuisance (scale 1, no background, f = 1), a real finite model
  whose score nobody reads. A slot that a smaller batch or an infeasible
  vector leaves unwritten keeps the last valid model it held. Its score is
  discarded, and it never touches another slot's: each GPU group reads only
  its own particle. }
procedure TGpuPosteriorScorer.Prepare(Gpu: TGpuEvaluator; Model: TLayeredModel;
  Count: Integer);
var
  P: TCalcThreadParams;
  S: TFitStructure;
  i: Integer;
begin
  P := FPosterior.CalcParams;
  FPosterior.Map.Template.CopyContent(S);
  Model.Reset;
  FillLayeredModel(Model, S);
  Model.Generate(P.Lambda);
  FNLay := Length(Model.LayersDirect);
  Gpu.Setup(FInputs, FNLay, Count, P.P, P.RF, P.Lambda, P.K, FPosterior.RMin);
  Gpu.SetupLikelihood(FLik);
  SetLength(FLayers, 4 * FNLay * Count);
  SetLength(FNuis, 4 * Count);
  for i := 0 to Count - 1 do
  begin
    PackModelLayers(Model.LayersDirect, FLayers, i);
    FNuis[4 * i] := 1;
    FNuis[4 * i + 1] := 0;
    FNuis[4 * i + 2] := 1;
    FNuis[4 * i + 3] := 0;
  end;
  FCapacity := Count;
  FPrepared := Gpu;
end;

procedure TGpuPosteriorScorer.Score(Gpu: TGpuEvaluator; const Models: TArray<TLayeredModel>;
  const Thetas: TArray<TArray<Double>>; out Scores: TArray<TGpuPosteriorScore>);
var
  n, Workers, i: Integer;
  Err: Pointer;
  LScores: TArray<TGpuPosteriorScore>;   // an out parameter cannot be captured
begin
  n := Length(Thetas);
  SetLength(LScores, n);
  if n > 0 then
  begin
    if Length(Models) = 0 then
      raise EGpuError.Create('TGpuPosteriorScorer.Score: no worker models');
    if (Gpu <> FPrepared) or (n > FCapacity) then
      Prepare(Gpu, Models[0], n);
    Workers := EnsureRange(Length(Models), 1, n);
    Err := nil;
    Parallel.&For(0, n - 1)
      .NumTasks(Workers)
      .Execute(procedure(taskIndex, i: Integer)
      var
        S: TFitStructure;
        Nuis: TNuisance;
        M: TLayeredModel;
        L: TCalcLayers;
      begin
        if Err <> nil then
          Exit;
        try
          FPosterior.Map.Template.CopyContent(S);
          if not FPosterior.Map.Apply(Thetas[i], S, Nuis) then
            Exit;                  // Feasible stays False; the slot keeps a valid model
          M := Models[taskIndex];
          M.Reset;
          FillLayeredModel(M, S);
          M.Generate(FPosterior.CalcParams.Lambda);
          L := M.LayersDirect;
          if Length(L) <> FNLay then
            raise EGpuError.CreateFmt('vector %d expands to %d layers, not %d',
              [i, Length(L), FNLay]);
          PackModelLayers(L, FLayers, i);
          FNuis[4 * i]     := Power(10, Nuis.LogScale);
          FNuis[4 * i + 1] := Nuis.Background;
          FNuis[4 * i + 2] := Sqr(Nuis.F);
          FNuis[4 * i + 3] := 0;
          LScores[i].PriorTerm := FPosterior.Map.PriorTerm(Thetas[i], S);
          LScores[i].Feasible := True;
        except
          KeepFirstError(Err);
        end;
      end);

    DrainThreadMessages;
    RaiseKept(Err);

    Gpu.EvaluateLikelihood(FLayers, FNuis, FCost);
    for i := 0 to n - 1 do
      if LScores[i].Feasible then
      begin
        LScores[i].LikCost := FCost[i];
        LScores[i].Minus2LnL := FCost[i] + FCostOffset;
        LScores[i].Cost := FCost[i] + LScores[i].PriorTerm;
      end
      else
        LScores[i].Cost := INFEASIBLE_COST;
  end;
  Scores := LScores;
end;

constructor TGpuJointScorer.Create(AJoint: TJointPosterior);
var
  m: Integer;
begin
  inherited Create;
  FJoint := AJoint;
  SetLength(FExtra, AJoint.MemberCount);
  SetLength(FScorers, AJoint.MemberCount);
  for m := 0 to AJoint.MemberCount - 1 do
    FScorers[m] := TGpuPosteriorScorer.Create(AJoint.Members[m]);
end;

destructor TGpuJointScorer.Destroy;
var
  m: Integer;
begin
  for m := 0 to High(FScorers) do
    FScorers[m].Free;
  for m := 0 to High(FExtra) do
    FExtra[m].Free;
  inherited;
end;

{ The sums start at 0 and add in member order: one member of weight 1 gives
  Cost = 0 + 1 * LikCost + (0 + PriorTerm), its scorer's own FCost + PriorTerm
  to the last bit. }
procedure TGpuJointScorer.Score(Gpu: TGpuEvaluator; const Work: TArray<TJointWorkspace>;
  const Thetas: TArray<TArray<Double>>; out Scores: TArray<TGpuPosteriorScore>);
var
  m, w, i, n: Integer;
  Eval: TGpuEvaluator;
  Models: TArray<TLayeredModel>;
  MThetas: TArray<TArray<Double>>;
  S, LScores: TArray<TGpuPosteriorScore>;
  LikCost, Prior, M2: TArray<Double>;
  Feasible: TArray<Boolean>;
begin
  n := Length(Thetas);
  SetLength(LikCost, n);
  SetLength(Prior, n);
  SetLength(M2, n);
  SetLength(Feasible, n);
  for i := 0 to n - 1 do
    Feasible[i] := True;
  SetLength(Models, Length(Work));
  SetLength(MThetas, n);
  for m := 0 to FJoint.MemberCount - 1 do
  begin
    if m = 0 then
      Eval := Gpu
    else
    begin
      if FExtra[m] = nil then
        FExtra[m] := TGpuEvaluator.Create;
      Eval := FExtra[m];
    end;
    for w := 0 to High(Work) do
      Models[w] := Work[w].Models[m];
    for i := 0 to n - 1 do
      MThetas[i] := FJoint.MemberTheta(m, Thetas[i]);
    FScorers[m].Score(Eval, Models, MThetas, S);
    for i := 0 to n - 1 do
      if not S[i].Feasible then
        Feasible[i] := False
      else
      begin
        LikCost[i] := LikCost[i] + FJoint.Weights[m] * S[i].LikCost;
        Prior[i] := Prior[i] + S[i].PriorTerm;
        M2[i] := M2[i] + FJoint.Weights[m] * S[i].Minus2LnL;
      end;
  end;
  SetLength(LScores, n);
  for i := 0 to n - 1 do
    if Feasible[i] then
    begin
      LScores[i].Feasible := True;
      LScores[i].LikCost := LikCost[i];
      LScores[i].PriorTerm := Prior[i];
      LScores[i].Minus2LnL := M2[i];
      LScores[i].Cost := LikCost[i] + Prior[i];
    end
    else
      LScores[i].Cost := INFEASIBLE_COST;
  Scores := LScores;
end;

end.
