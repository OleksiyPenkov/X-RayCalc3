# Solved measurement scale in the fit objective

_2026-09-22. Requested by the author through the XRR fitting skill session; confirmed by the author
in the development session: build it, optional, enabled by default in `fit_xrr`._

## What

The measured curve's scale is a nuisance parameter of the reflectivity fit. Instead of anchoring it
once (`scale`, `scale_auto`) and fitting the structure against that anchor, every candidate structure
is scored at its own best scale, found in closed form inside the objective.

## Why the closed form exists

`TCalc.CalcChiSquare` is

    chi2 = 1000/(n-1) * sum_i  w_i * tw_i * ((log10 D_i - log10 R_i) / log10 R_i)^2

A scale `s` on the measured curve adds `a = log10 s` to every `log10 D_i`. Nothing else in the sum
depends on `a`: `log10 R_i` is the model, `w_i = D_i / movavg(D)_i` is scale-invariant, `tw_i` is a
function of theta, and the skipped points (`R_i = 0`) and the tail cut do not look at `D`. So with
`W_i = w_i tw_i / (log10 R_i)^2` and `d_i = log10 D_i - log10 R_i`,

    chi2(a) = S2 + 2 a S1 + a^2 S0,   S2 = sum W d^2,  S1 = sum W d,  S0 = sum W
    a* = -S1 / S0

One accumulation pass over the same points, no swarm dimension. `chi2_plain` (all weights 1) is
evaluated at the same `a*`, so the two stay comparable.

## Rules

- **Bounded.** `a*` is clamped to `[-L, +L]`, `L = log10(1 + scale_solve_window)`, default window
  0.2. A clamp is reported (`scale_clamped`), like a parameter that ended on a bound.
- **Fallback.** No summed point or `S0 = 0`: `a = 0`, the anchored scale stands.
- **`r_min` does not follow `a*`.** The low-intensity cutoff is applied at the anchored scale, so
  the objective stays a function of the structure alone.
- **Smoothing** is linear, so scale-then-smooth equals smooth-then-scale; the closed form holds.
- **GPU.** The HLSL population scorer accumulates the same three sums and applies the same clamp, so
  the swarm searches the objective the report quotes. The CPU rescore of the winner still defines the
  reported number.
- **Off = unchanged.** With `scale_solve: false` the legacy loop runs verbatim, so every stored
  chi-squared reproduces bit for bit. That is what the pinned regression tests check.
- **The GUI and xrccmd are untouched**: the engine default is off; only `fit_xrr` turns it on.

## `fit_xrr` API

Request, top level beside `scale` / `scale_auto`:

| key | default | meaning |
|---|---|---|
| `scale_solve` | `true` | score every candidate at its own best scale |
| `scale_solve_window` | `0.2` | the solved scale stays within a factor `1 + window` of the anchor, either way |

Result additions (every fit, so no two results can be confused):

| key | meaning |
|---|---|
| `scale_solve` | the mode that produced `chi2` |
| `chi2_scale` | `"solved"` or `"anchored"` |
| `scale_solve_window` | as used |
| `scale_ratio` | `10^a*` of the fitted structure: solved scale / anchored scale (the specimen's alignment or normalisation loss) |
| `scale_solved` | `scale * scale_ratio`, the multiplier that would make a fixed-scale fit score the same |
| `scale_clamped` | `a*` sat on the window bound |
| `scale_start_ratio` | the same ratio for the start model (`chi2_start` is at it) |

`chi2`, `chi2_start`, `chi2_recalc` and `chi2_plain` are all at the solved scale of their model.
`measured.dat` and the `.xrcx` keep the anchored curve; `residual.dat` is
`log10 I + a* - log10 R`, i.e. at the solved scale, because that is the disagreement the fit
minimised. The `report` (orders, calc/meas) is at the anchored scale on purpose: its calc/meas
ratio at the first order is then the same loss `scale_ratio` measures.

## Tests

- closed form equals a fine grid over `a` (`TestCalcEngine`)
- `chi2(a*) <= chi2(any fixed a)`, on the same curve
- invariance: `D * c` with the anchor divided by `c` gives the same chi2 and `a* - log10 c`
- the clamp fires and is reported
- `chi2_plain` at `a*` matches a hand sum
- GPU population scoring matches the CPU with the solved scale on (`TestGpuCalc`)
- `scale_solve: false` reproduces the pinned chi-squareds of two stored fits (`TestMCPFit`)
- the default-on fit reports the new fields and a `chi2` no larger than the anchored one

## Known result to expect

The skill's stage E (fixed-scale scan, synthetic curves with a known scale) found the chi-squared
minimum in scale sharp and biased on one target (at the anchor while the truth is 3.4 % lower, the
whole Co density bias). Solving in-loop changes the search landscape, so they will re-run stage E
against this implementation. If the bias reproduces, the scale has to be measured (direct beam), not
fitted, and the default should be revisited.
