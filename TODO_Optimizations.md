# Fitting Speed Optimizations

## Architecture Overview

```
LFPSO.Run (main loop, T iterations)
  └─ FindTheBest (per iteration)
       └─ CalcSolution × Population (per particle)
            ├─ FitModelToLayer → TLayeredModel.Create (NEW OBJECT!)
            ├─ TCalc.Run
            │    ├─ Model.Generate (material lookup)
            │    ├─ PrepareWorkers (OTL thread setup)
            │    ├─ CalcTet × NThreads (parallel)
            │    │    └─ RefCalc × DataPoints/NThreads
            │    │         ├─ FresnelCoefficients
            │    │         ├─ LayerAmplitudeRefraction
            │    │         └─ TotalRecursiveRefraction
            │    └─ Convolute (Gaussian)
            ├─ CalcChiSquare
            └─ Application.ProcessMessages
```

**Total inner-loop calls per fit**: `TMax × Population` evaluations, each creating/destroying objects and running physics.

---

## Optimizations

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Cache `Layers` in `CalcTet` — stop copying array per data point | 🟢 S | ✅ Done |
| 2 | Reuse `TCalc` across iterations — stop create/destroy per FindTheBest | 🟡 M | ✅ Done |
| 3 | Reuse `TLayeredModel` — add Reset + pre-allocate FLayers | 🟡 M | ✅ Done |
| 4 | Throttle `Application.ProcessMessages` — once per iteration, not per particle | 🟢 S | ⏸️ Deferred — no measurable gain |
| 5 | Cache thread partitioning in `PrepareWorkers` — partition once, reuse | 🟡 M | ⏸️ Deferred — FResult/FTemp swap breaks caching |
| 6 | Pre-allocate `FLayers` in `FitModelToLayer` to total known size | 🟢 S | ✅ Done |
| 7 | Pre-compute Gaussian weights for convolution | 🟢 S | ✅ Done |

---

## Detailed Descriptions

### 1. Cache `Layers` in `CalcTet` — CATASTROPHIC bottleneck

**File**: `math/unit_calc.pas:240`, `math/unit_materials.pas:133-136`

**Problem**: `CalcTet` calls `FLayeredModel.Layers` inside the per-point loop. The property getter `GetLayers` does `Copy(FLayers, 0, Length(FLayers))` — a full array copy per data point. For 500 points × 20 layers × Population × TMax iterations = millions of unnecessary array copies.

```delphi
// Current — copies entire layer array PER POINT:
for i := 0 to Params.N - 1 do
  R := RefCalc(..., FLayeredModel.Layers);  // GetLayers → Copy!

// Fix — cache once:
procedure TCalc.CalcTet;
var
  Layers: TCalcLayers;
begin
  Layers := FLayeredModel.Layers;  // one copy
  for i := 0 to Params.N - 1 do
    R := RefCalc(..., Layers);     // reuse
end;
```

**Alternative**: Change `GetLayers` to return `FLayers` directly (no copy). The copy was likely added to prevent external mutation, but in the fitting hot path it's pure waste since `RefCalc` only reads the array.

**Expected speedup**: 2-5x depending on layer count and data size.

---

### 2. Reuse `TCalc` across iterations

**File**: `LFPSO/unit_LFPSO_Base.pas:423,461`

**Problem**: `FindTheBest` creates a new `TCalc` every iteration and destroys it at the end. Each `TCalc.Create` leads to `PrepareWorkers` which allocates thread task arrays, `CalcParams` arrays, `FResult` arrays. OTL `Parallel.ForEach` also has per-invocation overhead.

```delphi
// Current — create/destroy every iteration:
function TLFPSO_BASE.FindTheBest: boolean;
begin
  FCalc := TCalc.Create;
  try
    FCalc.Params := FCalcParams;
    FCalc.ExpValues := FData;
    ...
    for i := 0 to High(X) do
      CalcSolution(X[i]);
  finally
    FreeAndNil(FCalc);
  end;
end;

// Fix — create once in Run, reuse:
procedure TLFPSO_BASE.Run;
begin
  FCalc := TCalc.Create;
  FCalc.Params := FCalcParams;
  FCalc.ExpValues := FData;
  FCalc.MovAvg := FMovAvg;
  FCalc.Limit := FLimit;
  try
    ...
    for t := 1 to FTMax do
      FindTheBest;  // reuses FCalc
    ...
  finally
    FreeAndNil(FCalc);
  end;
end;
```

**Expected speedup**: 1.3-2x (eliminates per-iteration allocation overhead).

---

### 3. Reuse `TLayeredModel` — add Reset + pre-allocate FLayers

**File**: `LFPSO/unit_LFPSO_Base.pas:392-393`, `math/unit_materials.pas`

**Problem**: `CalcSolution` creates a new `TLayeredModel` for every particle evaluation via `FitModelToLayer`. Each `TLayeredModel.Create` allocates a `TDictionary<string,Integer>`, then `AddLayers` grows `FLayers` incrementally with multiple `SetLength` calls.

Called `Pop × TMax` times (e.g., 30 × 200 = 6,000 times).

```delphi
// Current:
procedure TLFPSO_BASE.CalcSolution;
begin
  FCalc.Model.Free;
  FCalc.Model := FitModelToLayer(X);  // new TLayeredModel!
  ...
end;

// Fix — add Reset method to TLayeredModel:
procedure TLayeredModel.Reset(TotalLayers: Integer);
begin
  SetLength(FLayers, TotalLayers + 2);  // pre-allocate (air + layers + substrate)
  FLayers[0].L := 1E10;
  FLayers[0].e.Re := 1;
  FLayers[0].e.Im := 0;
  CurrentLayer := 1;
  // Keep FMaterials and FMaterialIndex — they cache across calls!
end;
```

Key insight: `FMaterials` and `FMaterialIndex` can persist across resets since the same materials are used every evaluation. This also eliminates redundant Henke file reads.

**Expected speedup**: 1.5-2x (eliminates dictionary + array allocation per particle).

---

### 4. Throttle `Application.ProcessMessages`

**File**: `LFPSO/unit_LFPSO_Base.pas:433`

**Problem**: `Application.ProcessMessages` is called after every particle evaluation inside `FindTheBest`. This processes the entire Windows message queue (paint, mouse, timers) 30 times per iteration. It's only needed to keep the UI responsive and check for termination.

```delphi
// Current — per particle:
for i := 0 to High(X) do
begin
  CalcSolution(X[i]);
  Application.ProcessMessages;  // 30× per iteration!
  if FTerminated then Break;
end;

// Fix — once per iteration:
for i := 0 to High(X) do
begin
  CalcSolution(X[i]);
  if FTerminated then Break;
end;
Application.ProcessMessages;  // 1× per iteration
```

**Expected speedup**: 1.1-1.3x (message pumping overhead depends on UI complexity).

---

### 5. Cache thread partitioning in `PrepareWorkers`

**File**: `math/unit_calc.pas:148-202`

**Problem**: Every `TCalc.Run` calls `PrepareWorkers` which recalculates thread count, repartitions data points, allocates `CalcParams` arrays, and copies data point theta values into per-thread `Points` arrays. The partitioning is identical across all calls when the data doesn't change (which it never does during fitting).

```delphi
// Fix — partition once, add a flag:
procedure TCalc.PrepareWorkers;
begin
  if FWorkersReady then Exit;  // skip if already partitioned
  ...existing code...
  FWorkersReady := True;
end;
```

Reset `FWorkersReady` when `ExpValues` changes.

**Expected speedup**: 1.1-1.2x (eliminates per-run partitioning and array allocation).

---

### 6. Pre-allocate `FLayers` in `FitModelToLayer`

**File**: `LFPSO/unit_LFPSO_Base.pas:292-326`, `math/unit_materials.pas:68-92`

**Problem**: `FitModelToLayer` calls `AddLayers` multiple times, each growing `FLayers` with `SetLength(FLayers, Length(FLayers) + Length(Data))`. For a 5-stack structure, this is 5+ reallocations (copy + extend). The total size is known upfront.

```delphi
// Fix — pre-allocate in FitModelToLayer:
function TLFPSO_BASE.FitModelToLayer(const Solution: TSolution): TLayeredModel;
var
  TotalLayers: Integer;
begin
  // Count total layers first
  TotalLayers := 0;
  for i := 0 to High(FStructure.Stacks) do
    TotalLayers := TotalLayers + Length(FStructure.Stacks[i].Layers) * FStructure.Stacks[i].N;
  Inc(TotalLayers, 2);  // air + substrate

  Result := TLayeredModel.Create;
  Result.InitWithCapacity(TotalLayers);  // allocate once
  ...
end;
```

**Expected speedup**: 1.05-1.1x (small per-call saving, but called thousands of times).

---

### 7. Pre-compute Gaussian weights for convolution

**File**: `math/unit_calc.pas:465-504`

**Problem**: `Convolute` computes `Gauss(c, t1, sqr_Width)` for every (i, k) pair. The Gaussian weights depend only on `t1` relative to center, which is the same for every output point. Computing `FastExp` per weight per point is wasteful.

```delphi
// Fix — pre-compute weight array:
procedure TCalc.Convolute(Width: single);
var
  Weights: array of Single;
begin
  ...
  SetLength(Weights, 2 * N + 1);
  t1 := -0.1;
  for k := 0 to 2 * N do
  begin
    Weights[k] := Gauss(c, t1, sqr_Width) * delta;
    t1 := t1 + delta;
  end;

  for i := N to Size - N - 1 do
  begin
    Sum := 0;
    for k := 0 to 2 * N do
      Sum := Sum + FResult[i - N + k].r * Weights[k];
    FTemp[i].t := FResult[i].t;
    FTemp[i].R := Sum;
  end;
end;
```

**Expected speedup**: 1.05-1.1x (eliminates `FastExp` calls in inner convolution loop).
