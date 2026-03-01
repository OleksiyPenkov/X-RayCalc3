# Fitting Speed Optimizations — Phase 3

## Architecture Overview

```
LFPSO.Run (main loop, T iterations)
  └─ FindTheBest (per iteration) — PARALLELIZED via OTL Parallel.For
       └─ Per worker (NWorkers tasks):
            ├─ TLayeredModel.Reset + FillModel (reused objects)
            ├─ TCalc.Run (NThreads=1 per worker)
            │    ├─ Model.Generate → PrepareLayers (material cache hit)
            │    ├─ PrepareWorkers (cached, skipped)
            │    ├─ CalcTet (single thread per worker)
            │    │    └─ RefCalc × DataPoints
            │    │         ├─ FresnelCoefficients  ← AbsZ called here
            │    │         ├─ LayerAmplitudeRefraction  ← AbsZ, DivZZ, Roughness here
            │    │         └─ TotalRecursiveRefraction  ← try/except here
            │    └─ Convolute (pre-computed weights)
            └─ CalcChiSquare  ← Log10(FData) repeated here
```

---

## Optimizations

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Simplify `AbsZ` — replace overflow-safe branching with `Sqrt(Re²+Im²)` | 🟢 S | ✅ Done |
| 2 | Remove `try/except` from `TotalRecursiveRefraction` | 🟢 S | ✅ Done |
| 3 | Pre-compute `Log10(FData[i].r)` once for `CalcChiSquare` | 🟢 S | ✅ Done |
| 4 | Eliminate `GetLayers` copy when `NThreads=1` | 🟢 S | ✅ Done |
| 5 | Pre-allocate `TLayersData` in `FillModel` — single alloc to max size + count-based `AddLayers` | 🟡 M | ✅ Done |
| 6 | Resolve roughness function once per fit — eliminate per-point `case` branch | 🟡 M | ⏸️ Deferred — branch predictor handles constant RF perfectly; function pointer would prevent inlining |
| 7 | Precompute epsilon ratios in `LayerAmplitudeRefraction` | 🟡 M | ✅ Done |
| 8 | Avoid redundant curve copies in `WorkerBests` | 🟢 S | ⏸️ Deferred — requires shared-state read from parallel threads for marginal gain |

---

## Detailed Descriptions

### 1. Simplify `AbsZ` — the most-called function in the hot path (~5-15%)

**File**: `math_complex.pas:336-353`

**Problem**: `AbsZ` is called inside `FresnelCoefficients` (via `SqrtZ`), `LayerAmplitudeRefractionS/P` (directly + via `DivZZ`), and `TotalRecursiveRefraction`. That's 4+ calls per layer per data point.

The current implementation uses an overflow-safe algorithm with branching and division:

```delphi
// Current — overflow-safe but slow:
if x > y then
  Result := x * Sqrt(1 + FastPower(y / x, 2))
else
  Result := y * Sqrt(1 + FastPower(x / y, 2));
```

For X-ray reflectivity, `Re` and `Im` are always within `[0, ~1]` (dielectric constants near 1). No risk of overflow. Replace with:

```delphi
function AbsZ(const Z: TComplex): single; inline;
begin
  Result := Sqrt(Z.Re * Z.Re + Z.Im * Z.Im);
end;
```

Eliminates 2 branches, 1 division, and the `FastPower` call. Compounds significantly in the innermost loop.

---

### 2. Remove `try/except` from `TotalRecursiveRefraction` (~3-8%)

**File**: `unit_calc.pas:326-348`

**Problem**: The `try/except on Exception` wraps the entire recursion loop. Structured exception handling has setup/teardown cost even when no exception fires. Called `datapoints × population × iterations` times.

The exception would be division-by-zero in `DivZZ(b1, b2)` where `b2 := AddZR(a2, 1)`. Since `b2.Re >= 1` always, division by zero is impossible. The try/except is dead code in practice.

**Fix**: Remove the try/except entirely.

---

### 3. Pre-compute `Log10(FData[i].r)` once for `CalcChiSquare` (~3-5%)

**File**: `unit_calc.pas:112-150`

**Problem**: `Log10(FData[i].r)` calls `FastLn` on the same experimental data values every particle evaluation. Since `FData` never changes during a fit, this is pure waste.

**Fix**: Add a `FLogData: array of Single` field. Compute once when `ExpValues` is set. Replace `Log10(FData[i].r)` with `FLogData[i]` in `CalcChiSquare`.

---

### 4. Eliminate `GetLayers` copy when `NThreads=1` (~2-5%)

**Files**: `unit_materials.pas:137-140`, `unit_calc.pas:245`

**Problem**: `GetLayers` does `Copy(FLayers, 0, Length(FLayers))` to prevent `RefCalc` from corrupting the model (RefCalc writes `.K`, `.RF`, `.R` fields). But in parallel `FindTheBest`, each worker has its own `TLayeredModel` and `NThreads=1`, so there's only one consumer — the copy is unnecessary.

**Key insight**: `PrepareLayers` writes `.e` fields; `RefCalc` writes `.K`, `.RF`, `.R` fields — non-overlapping. Mutating in place doesn't corrupt the model for the next `Generate` call.

**Fix**: Add `LayersDirect` property returning `FLayers` without copy. Use in `CalcTet` when `NThreads = 1`.

---

### 5. Pre-allocate `TLayersData` in `FillModel` (~2-3%)

**File**: `unit_LFPSO_Base.pas:311-341`

**Problem**: Inside the per-stack loop: `SetLength(Data, 0); SetLength(Data, Length(...))` allocates/frees a dynamic array of records (containing strings) per stack per particle. Called Pop × TMax times.

**Fix**: Promote `Data` to a field or pre-allocate to max stack size once.

---

### 6. Resolve roughness function once per fit (~1-3%)

**File**: `unit_calc.pas:351-373`

**Problem**: The `Roughness` case statement evaluates `FParams.RF` for every layer at every data point. `FParams.RF` is constant during a fit.

**Fix**: Store a function pointer at fit start, eliminating per-point branching.

---

### 7. Precompute epsilon ratios in `LayerAmplitudeRefraction` (~1-2%)

**File**: `unit_calc.pas:386`

**Problem**: `AbsZ(DivZZ(ALayers[i].e, ALayers[i + 1].e))` — epsilon values don't depend on theta. This ratio could be precomputed once per model in a separate array.

---

### 8. Avoid redundant curve copies in `WorkerBests` (~1%)

**File**: `unit_LFPSO_Base.pas:480`

**Problem**: Copies the full result array every time a per-worker local best is found. Only the overall best curve is ultimately used.

**Fix**: Only copy when the worker-local best is also better than the current global best (`FGlobalBestChiSqr`), avoiding copies for improvements that won't survive reduction.
