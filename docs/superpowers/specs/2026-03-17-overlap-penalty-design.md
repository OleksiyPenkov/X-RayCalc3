# Overlap Penalty: Purity-Weighted Reflectivity for XRF Fitness

**Date:** 2026-03-17
**Status:** Draft
**Affects:** `unit_universal_fitness.pas`, `unit_universal_types.pas`, `unit_universal_io.pas`, `frm_XRFMain.pas`, `frm_XRFMain.dfm`

## Problem

The XRF universal mirror optimizer evaluates each target element independently. For each target, it computes `R_peak` — the first-order Bragg peak reflectivity at that target's wavelength. However, a multilayer mirror at a given angle reflects not just the intended wavelength but also other wavelengths at higher Bragg orders:

```
m * lambda = 2d * sin(theta)
```

When a higher-order reflection of one element's fluorescence line coincides with the first-order measurement angle of another element, spectral contamination occurs. The optimizer currently has no visibility into this and can converge on solutions with severe overlap.

### Example: B/Cr at d=79.66 A, gamma=0.6

The O Ka channel (theta=8.5 deg) also reflects Na Ka at 2nd order because lambda_O / 2 = 11.8 A, which nearly matches lambda_Na = 11.9 A (99.2% match). With gamma=0.6, the 2nd-order Fourier coefficient |sin(2*pi*gamma)| = 0.59 — the 2nd order is strong. The reported R_O=0.138 is misleading because the mirror has poor spectral selectivity between O and Na at this d-spacing.

Other significant overlaps at this d-spacing:
- B channel contaminated by O Ka at 3rd order (lambda_B/3 = 22.5 vs 23.6 A)
- C channel contaminated by O Ka at 2nd order (lambda_C/2 = 22.4 vs 23.6 A)
- N channel contaminated by Mg Ka at 3rd order (lambda_N/3 = 10.5 vs 9.89 A)

Higher orders (m > 4-5) are naturally suppressed by interfacial roughness via the Debye-Waller factor and are not a practical concern.

## Solution

Replace `R_peak` in the FoM with a purity-weighted effective reflectivity that accounts for contamination from other target elements' fluorescence lines reflected at higher orders.

### Purity Formula

For each target j:

```
ContaminationSum_j = SUM( CrossR[j, i] ) for all i != j
Purity_j = R_peak_j / (R_peak_j + ContaminationSum_j)
R_effective_j = R_peak_j * lerp(1.0, Purity_j, w_purity)
```

Where:
- `CrossR[j, i]` = reflectivity of contaminant i's wavelength at target j's Bragg angle, using the layer stack built with optical constants for wavelength lambda_i
- `Purity_j` is bounded [0, 1]: 1.0 means no contamination, 0.0 means target signal equals contamination
- `w_purity` is a user-configurable weight in [0, 1], default 1.0
- `lerp(a, b, t) = a + t * (b - a) = a * (1 - t) + b * t`

At `w_purity = 0`: `R_effective = R_peak` (backward compatible, no penalty).
At `w_purity = 1`: `R_effective = R_peak * Purity = R_peak^2 / (R_peak + ContaminationSum)`.

### Modified FoM

```
FoM_j = weight_j * (wR * R_effective_j - wFWHM * FWHM_j / FWHM_ref_j)
```

Only the R term changes. FWHM term is unaffected.

## Algorithm

### Restructured Evaluate() — Three Phases

**Phase 1: Evaluate each target and compute cross-reflectivities**

```
// Pre-compute all Bragg angles
For each target i:
  SinArg = lambda_i / (2 * d)
  if SinArg >= 1.0 then ThetaBragg[i] = -1 (invalid)
  else ThetaBragg[i] = arcsin(SinArg) in degrees

// Main loop
For each target i:
  if ThetaBragg[i] < 0 or < ThetaMin then skip (existing logic)

  BuildLayers(Genome, i)
  ScanReflectivity(lambda_i, ThetaBragg[i], SCAN_HALF_RANGE, SCAN_POINTS)
  Convolute(DeltaTheta)
  R_peak[i] = ExtractRPeak
  FWHM[i] = ExtractFWHM(R_peak[i])

  // NEW: while layer stack is built for lambda_i, evaluate at other targets' angles
  For each target j != i:
    if ThetaBragg[j] < 0 then continue
    CrossR[j, i] = RefCalcStandalone(ThetaBragg[j], lambda_i, FLayersBuf, Polarization, rfError)
```

Key insight: after `BuildLayers(Genome, i)`, the layer stack (`FLayersBuf`) contains epsilon values computed for wavelength `lambda_i`. The `RefCalcStandalone` function uses its `Lambda` parameter only for the wave vector `k = 2*pi/Lambda`, so `lambda_i` must be passed here (not `lambda_j`) to be consistent with the epsilon values in the layer stack. Evaluating at angle `ThetaBragg[j]` gives the reflectivity of `lambda_i` light at target j's measurement position — exactly the contamination we want to quantify.

**Phase 2: Compute purity for each target**

```
For each target j where Valid[j]:
  ContaminationSum = SUM(CrossR[j, i]) for all valid i != j
  Purity[j] = R_peak[j] / (R_peak[j] + ContaminationSum)
  R_effective[j] = R_peak[j] * (1.0 + w_purity * (Purity[j] - 1.0))
```

**Phase 3: Accumulate FoM (existing logic, using R_effective)**

```
For each target j where Valid[j]:
  FoM += weight_j * (wR * R_effective[j] - wFWHM * FWHM[j] / FWHM_ref[j])
```

### Edge Cases

- `R_peak[j] = 0` and `ContaminationSum = 0`: Purity = 0 (by convention, 0/0 = 0). R_effective = 0. Dark element stays dark.
- `R_peak[j] = 0` and `ContaminationSum > 0`: Purity = 0. R_effective = 0. Correct.
- `R_peak[j] > 0` and `ContaminationSum = 0`: Purity = 1.0. R_effective = R_peak. No penalty.
- Invalid target (sin >= 1 or below ThetaMin): excluded from both main evaluation and cross-checks.
- Single target (`FTargetCount = 1`): no contaminants exist, inner loop is empty, `ContaminationSum = 0`, `Purity = 1.0`, `R_effective = R_peak`. No overhead.
- `w_purity = 0`: R_effective = R_peak for all targets. Fully backward compatible.

## Data Structures

### New Fields

In `TFitnessConfig` (unit_universal_types.pas):
```pascal
wPurity: Single;  // [0..1], default 1.0 — weight for spectral purity penalty
```

### Local Variables in Evaluate()

```pascal
var
  CrossR: array[0..MAX_TARGETS-1, 0..MAX_TARGETS-1] of Single;  // CrossR[j, i] = R(lambda_i) at theta_j
  ThetaBragg: array[0..MAX_TARGETS-1] of Single;     // cached Bragg angles
  RPeakArr: array[0..MAX_TARGETS-1] of Single;       // cached R_peak values
  Purity: Single;                         // per-target purity
  ContamSum: Single;                      // per-target contamination sum
  REffective: Single;                     // purity-weighted R
```

Stack-allocated arrays sized to `MAX_TARGETS` (currently 16, defined in `unit_universal_types.pas`). Use the constant, not a literal. No heap allocation.

## Performance

- Extra computation: N*(N-1) single-point `RefCalcStandalone` calls per `Evaluate()`.
- For 8 targets: 56 calls. Current scan: 200 points * 8 targets = 1600 calls.
- Overhead: 56/1600 = 3.5%. Negligible.
- No extra `BuildLayers` calls — layer stacks are reused from the main loop.
- No heap allocations.

## Config Serialization

In `unit_universal_io.pas`, add `w_purity` to the fitness JSON block:

```json
"fitness": {
    "w_R": 1.0,
    "w_FWHM": 0.5,
    "w_purity": 1.0,
    "R_min_threshold": 0.001,
    ...
}
```

Default to 1.0 when absent in JSON. This means existing config files without `w_purity` will produce different FoM values if overlaps exist — this is an intentional behavior change since the whole point of this feature is to penalize overlaps by default.

Note: Delphi record fields zero-initialize (`wPurity = 0.0`) when constructed without explicit assignment. This means existing test code or programmatic configs that don't set `wPurity` will get `wPurity = 0` (no penalty) — backward compatible. Only JSON-loaded configs get the 1.0 default.

## GUI Changes

In `frm_XRFMain.pas` / `frm_XRFMain.dfm`, add to the Fitness group box:
- `lblWPurity: TLabel` — caption "w_purity"
- `edWPurity: TEdit` — default text "1.0"

Wire into `CollectConfigFromUI` and `LoadConfigToUI`.

## Files Modified

| File | Change |
|------|--------|
| `Universal/unit_universal_types.pas` | Add `wPurity: Single` to `TFitnessConfig` |
| `Universal/unit_universal_fitness.pas` | Restructure `Evaluate()` into 3 phases with CrossR matrix and purity calculation |
| `Universal/unit_universal_io.pas` | Serialize/deserialize `w_purity` field |
| `XRFCalc/frm_XRFMain.pas` | Add UI field, wire to config |
| `XRFCalc/frm_XRFMain.dfm` | Layout for new label + edit |

## Testing

- Existing tests should pass unchanged when `wPurity = 0` (backward compatible).
- Manual verification: run optimizer with same config, compare FoM with `wPurity=0` vs `wPurity=1`. Solutions with known O/Na overlap should show lower FoM with purity enabled.
- Unit test: construct a known bilayer where 2nd-order overlap is analytically predictable, verify CrossR matrix values.
