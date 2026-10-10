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

unit unit_StretchSampler;

(* The Goodman-Weare (2010) affine-invariant "stretch move" over a split
   ensemble, the move emcee's default sampler uses.

   The Walkers walkers are split into two halves by parity: h = 0 is walkers
   0, 2, 4, ...; h = 1 is walkers 1, 3, 5, ... For each half in turn, every
   walker k of that half (the "moving set" S) is proposed a new position
   using a partner j drawn from the OTHER half (the "complement" C), which
   never moves during this half-step:

    1. draw z = Sqr((A-1)*u + 1) / A, u ~ U(0, 1) - this is emcee's own
       inverse-CDF sampler for g(z) ~ 1/sqrt(z) on [1/A, A];
    2. draw a partner j := C[NextIndex(|C|)];
    3. draw lnU := Ln(1 - NextDouble) - the log of a Uniform(0, 1) variate,
       written so Ln never sees exactly 0.
    Only once every moving walker has all three of its draws does the move
    propose Y_k := X_j + z*(X_k - X_j) and hand the whole batch to LogProb in
    one call. The result is then always Accept if LnP_new > -Infinity and
    lnU < (Dim - 1)*Ln(z) + LnP_new - LnP_k.

   Doing every draw before the batch call - and always in the fixed order
   "for every k in S: z, then partner, then lnU" - is what makes the chain
   independent of how (or how many threads) LogProb evaluates the batch: the
   RNG stream consumed for a given step never depends on the batch's answers,
   only on the walkers' order, so the same seed always reproduces the same
   chain bit for bit, and a saved-and-reloaded state continues it exactly.
   Never draw from FRng inside or after a LogProb call.

   Rescore (see below) recomputes every walker's stored LnP and Blobs from
   its current X through the same batch function, without drawing or moving
   anything - a caller uses it when the batch function's answers may have
   changed since the walkers were last scored (a resume, or a mid-step
   fallback to another device), so that the next MoveHalf compares every
   walker against a score from the function it now calls, not a stale one.

   State stream layout (SaveState / LoadState), all fields written with
   Stream.WriteBuffer / read with Stream.ReadBuffer, in this order:
    - magic: 11 raw bytes, 'XRCSTRETCH1' (no length prefix, no trailing NUL);
    - Walkers, Dim, Step: Int32;
    - the RNG state: FRng.S, 4 x UInt64;
    - A: Double;
    - then, for each walker in order:
        X: Dim x Double, LnP: Double, Accepted: Int64,
        the blob length: Int32, then that many Doubles.
   LoadState checks the magic and that the stream's Walkers and Dim match the
   values this instance was constructed with, raising ESampler otherwise; it
   never resizes the sampler to fit the stream. *)

interface

uses
  System.SysUtils, System.Classes, unit_Xoshiro;

type
  TVector = TArray<Double>;

  TLogProbBatch = reference to procedure(const Batch: TArray<TVector>;
    out LnP: TArray<Double>; out Blobs: TArray<TVector>);
    // LnP[i] = NegInfinity where Batch[i] is outside the support; Blobs[i] = per-point extra values (may be empty)

  ESampler = class(Exception);

  TStretchSampler = class
  private
    const
      STATE_MAGIC: array [0 .. 10] of AnsiChar = 'XRCSTRETCH1';
    var
      FWalkers, FDim, FStep: Integer;
      FA: Double;
      FLogProb: TLogProbBatch;
      FRng: TXoshiro256;
      FX: TArray<TVector>;
      FLnP: TArray<Double>;
      FBlobs: TArray<TVector>;
      FAccepted: TArray<Int64>;
    procedure MoveHalf(Half: Integer);
    function GetX: TArray<TVector>;
    function GetLnP: TArray<Double>;
    function GetBlobs: TArray<TVector>;
    function GetAccepted: TArray<Int64>;
  public
    constructor Create(Walkers, Dim: Integer; const LogProb: TLogProbBatch; A: Double = 2.0);
    procedure Start(const X0: TArray<TVector>; Seed: UInt64);
    procedure DoStep;
    /// <summary>Re-evaluates every walker's current position through the
    /// sampler's own batch function and replaces the stored LnP and Blobs
    /// with the results. Draws NO random numbers and changes neither Step
    /// nor the RNG state - a rescore is not a move, only a recomputation of
    /// what a move already accepted. On an unchanged device (and an
    /// unchanged batch function) it returns identical values, since a score
    /// never depends on batch size or worker count. Needed after a resume
    /// (the loaded state may hold scores from a different device) and after
    /// a mid-step GPU fallback (the walkers keep the failed device's
    /// scores).</summary>
    procedure Rescore;
    procedure SaveState(Stream: TStream);
    procedure LoadState(Stream: TStream);
    function AcceptanceFraction(w: Integer): Double;
    property Walkers: Integer read FWalkers;
    property Dim: Integer read FDim;
    property Step: Integer read FStep;
    property X: TArray<TVector> read GetX;
    property LnP: TArray<Double> read GetLnP;
    property Blobs: TArray<TVector> read GetBlobs;
    property Accepted: TArray<Int64> read GetAccepted;
  end;

implementation

uses
  System.Math;

{ TStretchSampler }

constructor TStretchSampler.Create(Walkers, Dim: Integer; const LogProb: TLogProbBatch;
  A: Double = 2.0);
begin
  inherited Create;
  if Odd(Walkers) then
    raise ESampler.CreateFmt('%d walkers: the ensemble must be split into two even halves',
      [Walkers]);
  if Walkers < 2 * Dim then
    raise ESampler.CreateFmt('%d walkers is fewer than 2 x dim (%d) for a %d-dimensional fit',
      [Walkers, 2 * Dim, Dim]);
  FWalkers := Walkers;
  FDim := Dim;
  FLogProb := LogProb;
  FA := A;
  FStep := 0;
end;

function TStretchSampler.GetX: TArray<TVector>;
begin
  Result := FX;
end;

function TStretchSampler.GetLnP: TArray<Double>;
begin
  Result := FLnP;
end;

function TStretchSampler.GetBlobs: TArray<TVector>;
begin
  Result := FBlobs;
end;

function TStretchSampler.GetAccepted: TArray<Int64>;
begin
  Result := FAccepted;
end;

procedure TStretchSampler.Start(const X0: TArray<TVector>; Seed: UInt64);
var
  w: Integer;
begin
  if Length(X0) <> FWalkers then
    raise ESampler.CreateFmt('Start: %d starting positions for %d walkers',
      [Length(X0), FWalkers]);
  FRng.Seed(Seed);
  SetLength(FX, FWalkers);
  for w := 0 to FWalkers - 1 do
    FX[w] := Copy(X0[w]);
  SetLength(FAccepted, FWalkers);
  for w := 0 to FWalkers - 1 do
    FAccepted[w] := 0;
  FStep := 0;
  FLogProb(FX, FLnP, FBlobs);
  for w := 0 to FWalkers - 1 do
    if not (FLnP[w] > NegInfinity) then
      raise ESampler.CreateFmt('walker %d starts where the probability is zero', [w]);
end;

procedure TStretchSampler.MoveHalf(Half: Integer);
var
  S, C: TArray<Integer>;
  Zs, LnUs: TArray<Double>;
  Partners: TArray<Integer>;
  i, w, k, j: Integer;
  Batch: TArray<TVector>;
  NewLnP: TArray<Double>;
  NewBlobs: TArray<TVector>;
  u, z, lnU, LnAlpha: Double;
begin
  { Split by parity: half 0 is walkers 0, 2, 4, ...; half 1 is 1, 3, 5, ... }
  S := nil;
  C := nil;
  for w := 0 to FWalkers - 1 do
    if (w mod 2) = Half then
      S := S + [w]
    else
      C := C + [w];

  SetLength(Zs, Length(S));
  SetLength(Partners, Length(S));
  SetLength(LnUs, Length(S));
  { Every draw for every moving walker, in walker order, before any LogProb call. }
  for i := 0 to High(S) do
  begin
    u := FRng.NextDouble;
    Zs[i] := Sqr((FA - 1) * u + 1) / FA;
    Partners[i] := C[FRng.NextIndex(Length(C))];
    LnUs[i] := Ln(1 - FRng.NextDouble);
  end;

  SetLength(Batch, Length(S));
  for i := 0 to High(S) do
  begin
    k := S[i];
    j := Partners[i];
    z := Zs[i];
    SetLength(Batch[i], FDim);
    for w := 0 to FDim - 1 do
      Batch[i][w] := FX[j][w] + z * (FX[k][w] - FX[j][w]);
  end;

  FLogProb(Batch, NewLnP, NewBlobs);

  for i := 0 to High(S) do
  begin
    k := S[i];
    z := Zs[i];
    lnU := LnUs[i];
    if not (NewLnP[i] > NegInfinity) then
      Continue;              // LnP = -infinity, or NaN: always a rejection, never an accept
    LnAlpha := (FDim - 1) * Ln(z) + NewLnP[i] - FLnP[k];
    if lnU < LnAlpha then
    begin
      FX[k] := Batch[i];
      FLnP[k] := NewLnP[i];
      FBlobs[k] := NewBlobs[i];
      Inc(FAccepted[k]);
    end;
  end;
end;

procedure TStretchSampler.DoStep;
begin
  MoveHalf(0);
  MoveHalf(1);
  Inc(FStep);
end;

procedure TStretchSampler.Rescore;
begin
  FLogProb(FX, FLnP, FBlobs);
end;

function TStretchSampler.AcceptanceFraction(w: Integer): Double;
begin
  if FStep = 0 then
    Exit(0);
  Result := FAccepted[w] / FStep;
end;

procedure TStretchSampler.SaveState(Stream: TStream);
var
  w, BlobLen: Integer;
begin
  Stream.WriteBuffer(STATE_MAGIC, SizeOf(STATE_MAGIC));
  Stream.WriteBuffer(FWalkers, SizeOf(FWalkers));
  Stream.WriteBuffer(FDim, SizeOf(FDim));
  Stream.WriteBuffer(FStep, SizeOf(FStep));
  Stream.WriteBuffer(FRng.S, SizeOf(FRng.S));
  Stream.WriteBuffer(FA, SizeOf(FA));
  for w := 0 to FWalkers - 1 do
  begin
    Stream.WriteBuffer(FX[w][0], FDim * SizeOf(Double));
    Stream.WriteBuffer(FLnP[w], SizeOf(Double));
    Stream.WriteBuffer(FAccepted[w], SizeOf(Int64));
    BlobLen := Length(FBlobs[w]);
    Stream.WriteBuffer(BlobLen, SizeOf(BlobLen));
    if BlobLen > 0 then
      Stream.WriteBuffer(FBlobs[w][0], BlobLen * SizeOf(Double));
  end;
end;

procedure TStretchSampler.LoadState(Stream: TStream);
var
  Magic: array [0 .. 10] of AnsiChar;
  FileWalkers, FileDim, FileStep: Integer;
  w, BlobLen: Integer;
begin
  Stream.ReadBuffer(Magic, SizeOf(Magic));
  if not CompareMem(@Magic, @STATE_MAGIC, SizeOf(STATE_MAGIC)) then
    raise ESampler.Create('LoadState: not a stretch-sampler state stream (bad magic)');
  Stream.ReadBuffer(FileWalkers, SizeOf(FileWalkers));
  Stream.ReadBuffer(FileDim, SizeOf(FileDim));
  Stream.ReadBuffer(FileStep, SizeOf(FileStep));
  if (FileWalkers <> FWalkers) or (FileDim <> FDim) then
    raise ESampler.CreateFmt('LoadState: state has %d walkers x %d dim, this sampler has %d x %d',
      [FileWalkers, FileDim, FWalkers, FDim]);
  FStep := FileStep;
  Stream.ReadBuffer(FRng.S, SizeOf(FRng.S));
  Stream.ReadBuffer(FA, SizeOf(FA));
  SetLength(FX, FWalkers);
  SetLength(FLnP, FWalkers);
  SetLength(FBlobs, FWalkers);
  SetLength(FAccepted, FWalkers);
  for w := 0 to FWalkers - 1 do
  begin
    SetLength(FX[w], FDim);
    Stream.ReadBuffer(FX[w][0], FDim * SizeOf(Double));
    Stream.ReadBuffer(FLnP[w], SizeOf(Double));
    Stream.ReadBuffer(FAccepted[w], SizeOf(Int64));
    Stream.ReadBuffer(BlobLen, SizeOf(BlobLen));
    SetLength(FBlobs[w], BlobLen);
    if BlobLen > 0 then
      Stream.ReadBuffer(FBlobs[w][0], BlobLen * SizeOf(Double));
  end;
end;

end.
