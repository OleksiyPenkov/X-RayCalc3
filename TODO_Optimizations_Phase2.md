# Fitting Speed Optimizations — Phase 2

## Architecture Overview

```
LFPSO.Run (main loop, T iterations)
  └─ FindTheBest (per iteration)
       └─ CalcSolution × Population (per particle)
            ├─ FillModel → TLayeredModel.Reset (reused object)
            ├─ TCalc.Run
            │    ├─ Model.Generate (material lookup, cached)
            │    ├─ PrepareWorkers ← STILL CALLED EVERY TIME
            │    ├─ CalcTet × NThreads (parallel)
            │    │    └─ RefCalc × DataPoints/NThreads
            │    └─ Convolute (Gaussian, pre-computed weights)
            ├─ CalcChiSquare
            └─ Application.ProcessMessages
```

---

## Optimizations

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Cache `PrepareWorkers` + fix `Convolute` array swap | 🟡 M | 🔴 Open |
| 2 | Pre-allocate `FTemp` and `Weights` in `Convolute` | 🟢 S | ✅ Done |
| 3 | Parallel particle evaluation in `FindTheBest` | 🔴 XL | 🔴 Open |
| 4 | Avoid redundant `CalcSolution(gbest)` in `FindTheBest` | 🟢 S | 🔴 Open |

---

## Detailed Descriptions

### 1. Cache `PrepareWorkers` + fix `Convolute` array swap — ~10-20%

**Files**: `math/unit_calc.pas:148-202` (PrepareWorkers), `math/unit_calc.pas:467-513` (Convolute)

**Problem**: `PrepareWorkers` is called on every `TCalc.Run` invocation (Pop × TMax times). It recalculates thread count, repartitions data points, allocates `CalcParams` arrays, and copies theta values into per-thread `Points` arrays. The partitioning is identical across all calls because `FData` never changes during fitting.

This was deferred in Phase 1 because `Convolute` ends with `FResult := FTemp`, which replaces the `FResult` array reference. The next `PrepareWorkers` call then does `SetLength(FResult, 0); SetLength(FResult, Length(FData))`, re-allocating from scratch.

**Root cause**: The `FResult := FTemp` swap breaks any caching because `FResult` becomes a different array object each time.

**Fix** (two parts):

1. In `Convolute`, replace the array swap with an in-place copy so `FResult` keeps its allocation:

```delphi
// Current — swaps array reference:
FResult := FTemp;

// Fix — copy data back into FResult:
Move(FTemp[0], FResult[0], Length(FResult) * SizeOf(TDataPoint));
```

2. Cache `PrepareWorkers` with a flag:

```delphi
procedure TCalc.PrepareWorkers;
begin
  if FWorkersReady then Exit;  // skip if already partitioned

  ...existing partitioning code...

  FWorkersReady := True;
end;
```

Reset `FWorkersReady := False` when `ExpValues` is assigned (setter needed).

**Expected speedup**: ~10-20% (eliminates per-run partitioning, per-thread `Points` array allocation, and `FResult`/`FTemp` reallocation for every particle evaluation).

---

### 2. Pre-allocate `FTemp` and `Weights` in `Convolute` — ~5%

**File**: `math/unit_calc.pas:467-513`

**Problem**: `Convolute` calls `SetLength(FTemp, Size)` and `SetLength(Weights, WinSize)` on every invocation. During fitting, `Size` (= `Length(FResult)`) and `WinSize` (= `2*N+1`, derived from the data range) are constant across all calls.

Currently called Pop × TMax times (e.g., 30 × 200 = 6,000 allocations each).

**Fix**: Promote `Weights` to a field (`FConvWeights`) and pre-compute once. `FTemp` is already a field but gets re-allocated every call — skip `SetLength` if already the right size.

```delphi
// In TCalc fields:
FConvWeights: array of Single;
FConvN: Integer;            // half-window size
FConvReady: Boolean;

procedure TCalc.Convolute(Width: single);
begin
  if Width = 0 then begin FTail := 0; Exit; end;

  Size := Length(FResult);

  if not FConvReady then
  begin
    // Compute weights once
    Width := Width * FWHMToGaussianWidth;
    ...compute delta, N, Weights...
    FConvN := N;
    FConvWeights := Weights;
    SetLength(FTemp, Size);
    FConvReady := True;
  end;

  N := FConvN;
  // Use FConvWeights and FTemp directly
  ...convolution loop (unchanged)...

  // Copy back instead of swap (see #1)
  Move(FTemp[0], FResult[0], Size * SizeOf(TDataPoint));
  FTail := N;
end;
```

**Expected speedup**: ~5% (eliminates 2 allocations + Gaussian weight computation per particle evaluation).

---

### 3. Parallel particle evaluation in `FindTheBest` — ~2-4x

**File**: `LFPSO/unit_LFPSO_Base.pas:422-460`

**Problem**: Particles are evaluated sequentially in `FindTheBest`:

```delphi
for i := 0 to High(X) do
begin
  CalcSolution(X[i]);          // sequential!
  Application.ProcessMessages;
  if FTerminated then Break;
end;
```

Each `CalcSolution` already uses OTL to parallelize the inner `RefCalc` across data points. But the outer particle loop is serial. With Population=30 and modern CPUs having 8-16 cores, there's room for outer-level parallelism.

**Challenge**: Each particle evaluation needs its own `TCalc` + `TLayeredModel` instances because they hold mutable state (`FResult`, `FLayers`, etc.). Also, `pbest`/`FLastBestChiSqr` are shared state that needs synchronization.

**Approach**: Create a pool of `TCalc`+`TLayeredModel` pairs (one per hardware thread). Disable inner parallelism (`NThreads=1` per TCalc) and instead parallelize the outer particle loop. This avoids nested OTL overhead and gives better scaling.

```delphi
// Sketch:
type
  TCalcWorker = record
    Calc: TCalc;
    Model: TLayeredModel;
  end;

// In Run:
SetLength(FWorkers, GetNThreads);
for i := 0 to High(FWorkers) do
begin
  FWorkers[i].Calc := TCalc.Create;
  FWorkers[i].Calc.Params := FCalcParams;
  FWorkers[i].Calc.ExpValues := FData;
  // ...
  FWorkers[i].Model := TLayeredModel.Create;
  FWorkers[i].Model.Init;
end;

// In FindTheBest:
Parallel.ForEach(0, High(X))
  .Execute(procedure(const idx: Integer)
  var
    WorkerIdx: Integer;
    Chi: Single;
  begin
    WorkerIdx := idx mod Length(FWorkers);
    // ... evaluate particle idx with FWorkers[WorkerIdx] ...
  end);
```

**Risk**: Requires careful synchronization for `pbest`/`gbest` updates. `Application.ProcessMessages` cannot be called from worker threads. Material cache (`FMaterials`) would need to be pre-populated or thread-safe.

**Expected speedup**: ~2-4x depending on core count and population size.

---

### 4. Avoid redundant `CalcSolution(gbest)` in `FindTheBest` — ~3%

**File**: `LFPSO/unit_LFPSO_Base.pas:450

**Problem**: When a new absolute best is found, `FindTheBest` calls `CalcSolution(gbest)` again:

```delphi
if FGlobalBestChiSqr < FAbsoluteBestChiSqr then
begin
  FAbsoluteBestChiSqr := FGlobalBestChiSqr;
  abest := Copy(gbest, 0, MaxInt);
  abest_val := FGlobalBestChiSqr;
  CalcSolution(gbest);       // ← redundant! Already computed in the loop
  UpdateStructure(gbest);
  Result := True;
end;
```

The `gbest` solution was already evaluated in the main particle loop (it's the one that produced `FLastBestChiSqr`). The second `CalcSolution(gbest)` re-runs the full physics calculation unnecessarily.

**Likely purpose**: The second call might be needed to repopulate `FCalc`'s state (e.g., `FResultingCurve`) so that `SendUpdateMessage` can read the curve. If so, the curve was already saved at line 414: `FResultingCurve := FCalc.Results`.

**Fix**: Remove the redundant call. Verify that `FResultingCurve` and `FCalcModel` state are sufficient for `SendUpdateMessage` and `UpdateStructure`.

```delphi
if FGlobalBestChiSqr < FAbsoluteBestChiSqr then
begin
  FAbsoluteBestChiSqr := FGlobalBestChiSqr;
  abest := Copy(gbest, 0, MaxInt);
  abest_val := FGlobalBestChiSqr;
  // CalcSolution(gbest);    // removed — already evaluated in loop
  UpdateStructure(gbest);
  Result := True;
end;
```

**Caveat**: If `CalcSolution` has side effects needed by `UpdateStructure` beyond what `pbest` captures, this needs careful testing. `UpdateStructure` only reads `Solution` values to update `FStructure`, so it doesn't need `FCalc` state.

**Expected speedup**: ~3% (saves 1 full physics evaluation per improvement, which happens frequently early in the run).
