# Fitting Speed Optimizations — Phase 4

## Focus: RefCalc inner loop

Targeted the Parratt recursion and Fresnel coefficient computation inside `RefCalc` — the innermost hot path called ~3M times per fit (iterations × particles × data points).

**Measured result: ~9% fitting speedup (59s vs 1m08s)**

---

## Optimizations

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Fuse phase computation in `TotalRecursiveRefraction` — inline MulRZ + MulZZ(Im) + ExpZ + MulZZ(R) with FastSinCos | 🟡 M | ✅ Done |
| 2 | Replace `sqr(AbsZ(R))` with `NormZ(R)` — skip unnecessary sqrt | 🟢 S | ✅ Done |
| 3 | Use `FastSinCos` in `ExpZ` instead of separate `FastSin` + `FastCos` | 🟢 S | ✅ Done |
| 4 | Precompute roughness `sqr(sigma/1.41)` per layer; simplify `Roughness(rfError)` | 🟡 M | ✅ Done |
| 5 | Hoist `c1`/`c2` wave constants from `RefCalc` to `CalcTet`/`CalcLambda` | 🟡 M | ✅ Done |
| 6 | Cache roughness damping factor in S-pass, reuse in P-pass (cmSP mode) | 🟡 M | ✅ Done |

---

## Detailed Descriptions

### 1. Fuse phase computation in `TotalRecursiveRefraction` (~5-10%)

**File**: `unit_calc.pas` — `TotalRecursiveRefraction`

**Problem**: Four sequential function calls per layer per angle, including a multiply-by-`i` that is really just a swap+negate:

```delphi
// Before — 4 calls, redundant intermediate results:
a1 := MulRZ(ALayers[i+1].L * 2, ALayers[i+1].K);   // (2L*K.Re, 2L*K.Im)
a1 := MulZZ(Im, a1);                                 // just (-a1.Im, a1.Re)
a1 := ExpZ(a1);                                      // FastExp + FastCos + FastSin
a1 := MulZZ(ALayers[i+1].R, a1);                     // 4 muls + 2 adds
```

**Fix**: Inline the entire computation using FastSinCos:

```delphi
L2 := ALayers[i+1].L * 2;
expVal := FastExp(-L2 * ALayers[i+1].K.Im);
FastSinCos(L2 * ALayers[i+1].K.Re, sinP, cosP);
Rn := ALayers[i+1].R;
a1.Re := expVal * (Rn.Re * cosP - Rn.Im * sinP);
a1.Im := expVal * (Rn.Re * sinP + Rn.Im * cosP);
```

Eliminates: `ToComplex(0,1)`, MulZZ-by-i (4 muls → 0), separate sin/cos → single FastSinCos, ExpZ function call overhead.

---

### 2. Replace `sqr(AbsZ(R))` with `NormZ(R)` (~3-8%)

**File**: `unit_calc.pas` — `TotalRecursiveRefraction` final line

**Problem**: `sqr(AbsZ(R))` computes `sqrt(Re²+Im²)` then squares it — the sqrt is wasted.

**Fix**: `NormZ(R)` = `Re² + Im²` directly. Saves one `sqrt` per `RefCalc` call (~3M per fit).

---

### 3. Use `FastSinCos` in `ExpZ` (~2-5%)

**File**: `math_complex.pas` — `ExpZ`

**Problem**: `ExpZ` computes `FastCos(Z.Im)` and `FastSin(Z.Im)` as separate calls. `FastSinCos` computes both in one pass (shared angle reduction).

**Fix**: Replace two calls with one `FastSinCos(Z.Im, s, c)`.

---

### 4. Precompute roughness sigma² factor per layer (~1-3%)

**Files**: `unit_Types.pas` (new `s2` field), `unit_calc.pas` — `CalcTet`/`CalcLambda`, `Roughness`

**Problem**: `Roughness(rfError)` computed `sqr(sigma / 1.41) * sqr(s)` per interface per angle. The `sqr(sigma / 1.41)` part depends only on the layer, not the angle.

**Fix**: Added `s2: single` field to `TCalcLayer`. Precomputed as `Sqr(sigma) * 0.50299` alongside `eRatio` in `CalcTet`/`CalcLambda`. Roughness rfError simplified to `FastExp(-s2 * sqr(s))`.

---

### 5. Hoist c1/c2 wave constants out of RefCalc (~1-2%)

**File**: `unit_calc.pas` — `RefCalc`, `CalcTet`, `CalcLambda`

**Problem**: `c1 = 4π/λ` and `c2 = 2π/λ` were computed inside `RefCalc`, which is called per angle. In theta-scan mode, λ is constant.

**Fix**: Changed `RefCalc` signature from `(ATheta, Lambda, Layers)` to `(ATheta, c1, c2, Layers)`. Wave constants computed once in `CalcTet` (per model) or per-lambda in `CalcLambda`.

---

### 6. Cache roughness damping factor for cmSP reuse (~1-2%)

**Files**: `unit_Types.pas` (new `RoughFactor` field), `unit_calc.pas` — `LayerAmplitudeRefractionS/P`

**Problem**: In cmSP mode (both polarizations), the roughness `s` value and damping factor are computed identically in both `LayerAmplitudeRefractionS` and `LayerAmplitudeRefractionP` — same sigma, same angle-dependent `s`.

**Fix**: Added `RoughFactor: single` field to `TCalcLayer`. S-pass computes and caches the factor; P-pass reuses it directly, skipping Abs + 2×sqrt + Roughness call per interface.
