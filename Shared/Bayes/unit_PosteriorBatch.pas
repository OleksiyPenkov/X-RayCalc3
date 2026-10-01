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

unit unit_PosteriorBatch;

(* Parallel batch evaluation of a TJointPosterior (phase B1's TStretchSampler
   feeds it through TLogProbBatch; phase C made it joint). One TJointWorkspace
   per worker - a TCalc and a TLayeredModel per member - so every thread scores
   its share of the batch on its own copies: results land in per-index output
   arrays, so no locks are needed and the answer never depends on how many
   workers evaluated the batch.

   Created from a TLogPosterior, the batch wraps it in a one-member joint of
   its own (TJointPosterior.CreateSingle), whose numbers are the posterior's,
   bit for bit. It owns that wrapper, never the posterior or a joint it is
   given: the caller frees those, after this batch.

   It draws no random numbers - the sampler is the only source of randomness,
   always on the job thread.

   With UseGPU, LogProb scores each batch on the GPU through TGpuJointScorer
   (FGpu is member 0's evaluator); a GPU that fails hands that batch and
   every later one to the CPU. ModelCurves always runs on the CPU. *)

interface

uses
  unit_Types, unit_materials, unit_calc, unit_gpu_calc, unit_LogPosterior,
  unit_JointPosterior, unit_GpuPosterior, unit_StretchSampler;

type
  TPosteriorBatch = class
  private
    FJoint: TJointPosterior;
    FOwnedJoint: TJointPosterior;       // the wrapper of Create(TLogPosterior); nil otherwise
    FWork: TArray<TJointWorkspace>;     // one per worker
    FGpu: TGpuEvaluator;                // nil when the CPU evaluates
    FScorer: TGpuJointScorer;
    FDeviceUsed, FGpuError: string;
    FGpuUsed: Boolean;
    function GetAsBatchFunc: TLogProbBatch;
    procedure Init(AJoint: TJointPosterior; Workers: Integer; UseGPU: Boolean);
    procedure StopGpu(const Why: string);
    function LogProbOnGpu(const Batch: TArray<TVector>; out LnP: TArray<Double>;
      out Blobs: TArray<TVector>): Boolean;
  public
    constructor Create(APosterior: TLogPosterior; Workers: Integer;
      UseGPU: Boolean = False); overload;
    constructor Create(AJoint: TJointPosterior; Workers: Integer;
      UseGPU: Boolean = False); overload;
    destructor Destroy; override;
    procedure LogProb(const Batch: TArray<TVector>; out LnP: TArray<Double>;
      out Blobs: TArray<TVector>);
    { Always the CPU. }
    procedure LogProbOnCpu(const Batch: TArray<TVector>; out LnP: TArray<Double>;
      out Blobs: TArray<TVector>);
    { Member's scaled model curve (ScaledModel of its curve and nuisance) for
      every vector of Batch; nil for a vector the joint finds infeasible. }
    procedure ModelCurves(const Batch: TArray<TVector>; out Curves: TArray<TDataArray>;
      Member: Integer = 0);
    { A property, not a function: a niladic function whose own result type is
      itself a procedural type is ambiguous when referenced bare (as
      TStretchSampler.Create(..., B.AsBatchFunc) does) - the compiler reads it
      as the method's own address ('Procedure of object'), not a call, and
      rejects it against TLogProbBatch (E2010). A property's getter is always
      called, so the same bare "B.AsBatchFunc" resolves as intended. }
    property AsBatchFunc: TLogProbBatch read GetAsBatchFunc;
    property Joint: TJointPosterior read FJoint;
    { 'CPU', or the adapter that evaluated the last batch. }
    property DeviceUsed: string read FDeviceUsed;
    { Why the GPU is not in use; '' when it is, or was not asked for. }
    property GpuError: string read FGpuError;
    { At least one batch ran on the GPU. }
    property GpuUsed: Boolean read FGpuUsed;
  end;

implementation

uses
  System.SysUtils, System.Math, Winapi.Windows,
  Winapi.Messages, OtlParallel, unit_otl_drain, unit_Likelihood, unit_LFPSO_Base;

{ KeepFirstError / RaiseKept: unit_LFPSO_Base. }

procedure TPosteriorBatch.Init(AJoint: TJointPosterior; Workers: Integer; UseGPU: Boolean);
var
  i: Integer;
begin
  FJoint := AJoint;
  if Workers < 1 then
    Workers := 1;
  SetLength(FWork, Workers);
  for i := 0 to Workers - 1 do
    FWork[i] := FJoint.NewWorkspace;
  FDeviceUsed := 'CPU';
  if UseGPU then
  try
    FGpu := TGpuEvaluator.Create;
    FScorer := TGpuJointScorer.Create(FJoint);
    FDeviceUsed := FGpu.AdapterName;
  except
    on E: Exception do
      StopGpu(E.Message);
  end;
end;

constructor TPosteriorBatch.Create(APosterior: TLogPosterior; Workers: Integer;
  UseGPU: Boolean);
begin
  inherited Create;
  FOwnedJoint := TJointPosterior.CreateSingle(APosterior);
  Init(FOwnedJoint, Workers, UseGPU);
end;

constructor TPosteriorBatch.Create(AJoint: TJointPosterior; Workers: Integer;
  UseGPU: Boolean);
begin
  inherited Create;
  Init(AJoint, Workers, UseGPU);
end;

destructor TPosteriorBatch.Destroy;
var
  i: Integer;
begin
  FScorer.Free;
  FGpu.Free;
  for i := 0 to High(FWork) do
    TJointPosterior.FreeWorkspace(FWork[i]);
  FOwnedJoint.Free;
  inherited;
end;

procedure TPosteriorBatch.StopGpu(const Why: string);
begin
  FreeAndNil(FScorer);
  FreeAndNil(FGpu);
  FDeviceUsed := 'CPU';
  FGpuError := Why;
end;

procedure TPosteriorBatch.LogProb(const Batch: TArray<TVector>; out LnP: TArray<Double>;
  out Blobs: TArray<TVector>);
begin
  if (FGpu <> nil) and LogProbOnGpu(Batch, LnP, Blobs) then
    Exit;
  LogProbOnCpu(Batch, LnP, Blobs);
end;

{ The batch on the GPU, in LogProbOnCpu's terms: ln p = -Cost / 2 and the
  blob [minus2lnL, prior term], with -infinity decided from Feasible. False
  when the GPU failed: it has then been shut down, and LogProb scores this
  batch and every later one on the CPU. }
function TPosteriorBatch.LogProbOnGpu(const Batch: TArray<TVector>;
  out LnP: TArray<Double>; out Blobs: TArray<TVector>): Boolean;
var
  Scores: TArray<TGpuPosteriorScore>;
  i: Integer;
begin
  Result := False;
  try
    FScorer.Score(FGpu, FWork, Batch, Scores);
  except
    on E: Exception do
    begin
      StopGpu(E.Message);
      Exit;
    end;
  end;
  SetLength(LnP, Length(Batch));
  SetLength(Blobs, Length(Batch));
  for i := 0 to High(Batch) do
    if Scores[i].Feasible then
    begin
      LnP[i] := -0.5 * Scores[i].Cost;
      Blobs[i] := [Scores[i].Minus2LnL, Scores[i].PriorTerm];
    end
    else
    begin
      LnP[i] := NegInfinity;
      Blobs[i] := nil;
    end;
  FGpuUsed := True;
  Result := True;
end;

procedure TPosteriorBatch.LogProbOnCpu(const Batch: TArray<TVector>; out LnP: TArray<Double>;
  out Blobs: TArray<TVector>);
var
  n, Workers: Integer;
  Err: Pointer;
  { An anonymous method cannot capture an out/var parameter of the enclosing
    routine, only a local variable, hence these locals - copied to LnP/Blobs
    only after the parallel loop (and any exception it raised) is done. }
  LLnP: TArray<Double>;
  LBlobs: TArray<TVector>;
begin
  n := Length(Batch);
  SetLength(LLnP, n);
  SetLength(LBlobs, n);
  if n = 0 then
  begin
    LnP := LLnP;
    Blobs := LBlobs;
    Exit;
  end;
  Workers := EnsureRange(Length(FWork), 1, n);

  Err := nil;
  Parallel.&For(0, n - 1)
    .NumTasks(Workers)
    .Execute(procedure(taskIndex, i: Integer)
    var
      T: TJointTerms;
      Curves: TArray<TDataArray>;
    begin
      if Err <> nil then
        Exit;                     // a sibling failed; the loop is lost anyway
      try
        T := FJoint.Evaluate(FWork[taskIndex], Batch[i], Curves);
        if T.Feasible then
        begin
          LLnP[i] := -0.5 * T.Cost;
          LBlobs[i] := [T.Minus2LnL, T.PriorTerm];
        end
        else
        begin
          LLnP[i] := NegInfinity;
          LBlobs[i] := nil;
        end;
      except
        KeepFirstError(Err);
      end;
    end);

  DrainThreadMessages;
  RaiseKept(Err);
  LnP := LLnP;
  Blobs := LBlobs;
end;

function TPosteriorBatch.GetAsBatchFunc: TLogProbBatch;
begin
  Result := procedure(const Batch: TArray<TVector>; out LnP: TArray<Double>;
    out Blobs: TArray<TVector>)
  begin
    LogProb(Batch, LnP, Blobs);
  end;
end;

procedure TPosteriorBatch.ModelCurves(const Batch: TArray<TVector>; out Curves: TArray<TDataArray>;
  Member: Integer);
var
  n, Workers: Integer;
  Err: Pointer;
  LCurves: TArray<TDataArray>;   // see LogProb: an out parameter cannot be captured
begin
  if (Member < 0) or (Member >= FJoint.MemberCount) then
    raise EArgumentOutOfRangeException.CreateFmt('ModelCurves: there is no member %d', [Member]);
  n := Length(Batch);
  SetLength(LCurves, n);
  if n = 0 then
  begin
    Curves := LCurves;
    Exit;
  end;
  Workers := EnsureRange(Length(FWork), 1, n);

  Err := nil;
  Parallel.&For(0, n - 1)
    .NumTasks(Workers)
    .Execute(procedure(taskIndex, i: Integer)
    var
      T: TJointTerms;
      C: TArray<TDataArray>;
    begin
      if Err <> nil then
        Exit;
      try
        T := FJoint.Evaluate(FWork[taskIndex], Batch[i], C);
        if T.Feasible then
          LCurves[i] := ScaledModel(C[Member], T.Members[Member].Nuisance)
        else
          LCurves[i] := nil;
      except
        KeepFirstError(Err);
      end;
    end);

  DrainThreadMessages;
  RaiseKept(Err);
  Curves := LCurves;
end;

end.
