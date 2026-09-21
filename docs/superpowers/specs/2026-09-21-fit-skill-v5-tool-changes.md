# Two tool changes for fitting skill v5, then one pinned release

_From the XRR-Fitting-Skill paper session, 2026-09-21. Author's decisions the same day: square-root peak weighting
goes into skill v5, and **every result in the paper is recomputed from scratch on one pinned published release**; its number does
not matter. So these changes go in before that release is cut, and nothing is run for the paper until it is. Follows the 2026-09-18 spec (`2026-09-18-fit-skill-tool-changes.md`)._

## 1. Square-root peak weighting — WITHDRAWN

> **Withdrawn 2026-09-21.** The only square-root weighting in the code is theta weighting
> (`chi2.theta_weight = 3`, w ∝ √θ), already exposed by `fit_xrr`. The author confirmed that this is what
> "square-root weighting" meant, so no `point_weight_power` is built. The text below is kept for the record.

**Now.** `TCalc.CalcChiSquare` (`Shared/Math/unit_calc.pas` ~150) multiplies a point's residual by
`Ratio = I / movavg(I)` whenever `Ratio > 3`, otherwise by 1. Only this linear form is reachable
(`fit_xrr` `chi2.point_weight` true/false).

**Required.** A power on that weight: `w_point = Ratio^p` where `Ratio > 3`, 1 otherwise.
- `fit_xrr` `chi2.point_weight_power`, number, default **1** (today's behaviour to the last digit), `0.5` = square
  root. Accept `0 < p <= 2`; refuse anything else with `invalid_argument`. It is meaningful only with
  `point_weight: true`: refuse it with `point_weight: false` rather than ignore it.
- Plumbing: a field beside `TFitParams.ThetaWeight` (`XRayCalc3/Units/unit_Types.pas:106`) that reaches every
  worker's `Calc` (`unit_LFPSO_Base.pas:540`); `TCalc` keeps `p = 1` by default so the GUI and xrccmd are unchanged.
- Echo `point_weight_power` in the result beside `theta_weight`/`point_weight` (`unit_MCPFit.pas` ~1919), in
  `report.json`, and in `describe_server`'s chi2 definition (`FIT_CHI2_DEFINITION`: "w_point = (I/movavg(I))^p").
- `chi2_plain` is untouched (both weights dropped, as now).
- No GUI change, no `.xrcx` version change. If the fit settings written to `fit.xrcx` get the value, it is an
  optional key whose absence means 1.
- Assumption to confirm with the author: "square-root peak weighting" means the square root of this same
  peak-to-moving-average ratio, not a sqrt(I) (counting-statistics) weight on every point.

**Tests.** p = 1 gives bit-identical chi2 to today on a fixed model and curve; p = 0.5 on a hand-built 5-point case
matches a hand computation.

## 2. Per-period sigma and density from a profile fit

**Now.** A `profile: true` fit reports each layer's per-period thickness as `thickness_profile`
(`CollectThicknessProfiles`, `unit_MCPFit.pas` ~1845, read from the expanded model's `Layers[i].L`). A sigma or
density that is **not** paired also varies over the periods, but its per-period values are not reported, so the
fitted curve cannot be rebuilt from the result.

**Required.** The same collection for `Layers[i].s` and `Layers[i].ro`: `sigma_profile` and `density_profile`
beside `thickness_profile`, listed only where the values actually differ between periods (a paired parameter keeps
today's single value).

**Acceptance test (the important one).** Take a profile fit with sigma and density unpaired. Unroll
`fitted_structure` into N = 1 stacks using the three per-period arrays, in the order they are reported, and compute
it with `calc_reflectivity` on the fit's grid, wavelength, polarization and resolution. The chi2 of that curve against
`measured.dat` must equal the fit's chi2 (within single-precision noise). A pilot on 2026-09-21 got chi2 25.9
against 20.687 when it rebuilt a profile fit from outside, which is what this test pins down. State in the tool
description which end of the stack period 1 is (substrate or surface).

**Done 2026-09-21.** `CollectLayerProfiles` (`unit_MCPFit.pas`) reads thickness, sigma and density per period;
`sigma_profile` / `density_profile` are written only where the values differ between periods. Every array runs
from the **surface** end: entry 0 is period 1, next to the surface (`TLFPSO_Poly.FillModel` adds periods from the
ambient down). The JSON `stacks` run from the substrate up, so an N = 1 rebuild lists the periods from the last
array entry to the first; the `fit_xrr` `profile` description says so. Test
`ProfileFit_UnrolledIntoSinglePeriods_ReproducesTheFit`: the rebuilt structure gives chi2 1.96033 against the fit's
1.96044 (6e-5, from the six significant digits every reported number carries) and the fit's curve to a mean
0.07%; the same periods in array order miss the curve. Before the fix the same rebuild (single sigma and
density) missed the fit's curve by up to 63% at a point, the kind of gap behind the pilot's 25.9 against 20.687.

## 3. Before the release

- Full suite green, smoke `XRC_MCP/smoke/session.ps1` PASS, clean Win64 rebuild.
- No comparison with earlier builds is needed: everything is recomputed on the release.
- The author cuts the release, whatever it is numbered. Report its tag and `describe_server` `git_revision` to
  the paper session.

## Not in scope

Anything in the 2026-09-18 "not in scope" list, fitting resolution/scale/background.
