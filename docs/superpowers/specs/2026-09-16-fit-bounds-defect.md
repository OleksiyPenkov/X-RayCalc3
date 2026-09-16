# Defect: `fit_xrr` returns fitted parameters outside the client's bounds

_From the paper-2 orchestrator session, 2026-09-16. Author's instruction: fix it now. Decision 45 of the
paper's design spec (`D:\MultilayerLab\Papers\LLM-XRay-Optics-Lab\docs\specs\2026-09-08-llm-xray-optics-lab-design.md`)._

## Observed

Binary `XRC_MCP.exe` at `02e7b63`, engine `TLFPSO_Periodic`. In one agent session 4 of 11 `fit_xrr`
results hold fitted values outside the `bounds_used` echoed in the same result. Full evidence, one
`result.json` and one `request.json` per job, plus a table, in
`D:\MultilayerLab\Papers\LLM-XRay-Optics-Lab\experiments\fit-bounds-defect-2026-09-16\`.

| Job (seed) | Outside `bounds_used` |
|---|---|
| fit-20260916-141539-e49e (910003) | C density 3.259 (1.6–3.2); Co density 0.437 (2–8.8) |
| fit-20260916-141845-1763 (930002) | C thickness 25.97 (16–25); C σ 3.76 (4–14); Co thickness 1.66 (3–11); Co density 5.77 (6–8.8) |
| fit-20260916-142030-f2d6 (940001) | C thickness 28.53 (18–27); Co thickness −0.743 (0.5–8); Co σ 12.49 (1–12) |
| fit-20260916-142234-c3d5 (950002) | C thickness 25.79 (24–25.6); C density 2.847 (2.4–2.75); Co thickness 1.99 (2.4–3.6); Co σ 7.55 (7.6–8.8); Co density 9.31 (8.2–8.9) |

All four requests free the period (`"free": [{"target":"period","stack":0}, …]` with a period range).
Seven other results of the same session, five of them also with a free period, are inside their bounds.
Every request is reproducible: `measurement_id`, structure, free, bounds, theta_range, scale, resolution,
chi2 settings, optimizer settings and seed are in the request files; the measured curve is
`experiments\runs\exp-03\workdir\inbox\P2-02\xrr.dat` (+ `meta.json`) of the paper-2 repository.

## What the source shows (orchestrator's reading; verify)

- `TLFPSO_BASE.CheckLimits` (`XRayCalc3\LFPSO\unit_LFPSO_Base.pas`, ~line 460) clamps each moved
  coordinate into `[Xmin, Xmax]` with a reflective bounce. A moved value cannot leave its bounds there.
- `TLFPSO_Periodic.UpdateLFPSO` / `UpdatePSO` call `NormalizeD(i)` after the per-coordinate
  `CheckLimits`. `NormalizeD` (`unit_LFPSO_Periodic.pas`, ~line 122) multiplies every layer thickness of a
  periodic stack by one factor `(1 + f)` to hold the period, or to pull it back to the period range when the
  period is free. That rescaling ignores the per-layer thickness bounds, and a factor below −1 gives a
  negative thickness. This explains the thickness excursions only.
- σ and density outside their bounds cannot come from `NormalizeD`. Look at how `unit_MCPFit.pas`
  (XRC_MCP) maps `bounds` into the engine's `Xmin`/`Xmax` when `"target":"period"` is present
  (`SetPeriodRange`, layer indexing), and at how the result is read back (is it the clamped particle, or a
  copy taken before the clamp / from `gbest` at a different point?).

## Required

1. No `fit_xrr` result may carry a value outside the bounds the client gave. Either the engine keeps
   every value inside (NormalizeD must respect thickness bounds: re-clamp and re-normalize, or distribute
   the correction only over layers with room), or the server rejects such a particle as a result and says so.
   Until the engine is fixed, the server must at least add an `out_of_bounds` list to the result naming
   every violating value, so a client is never handed a silent violation.
2. Find and fix the σ / density path (item 3 above).
3. Tests (DUnitX, `XRayCalc3\Tests`): a 20-period C/Co stack fitted against the P2-02 curve with the
   four requests above (same seeds) asserts every fitted value inside `bounds_used`; a unit test of
   `NormalizeD` with a thickness at its lower bound and a period pull-back that would cross it.
4. Smoke (`XRC_MCP\smoke\session.ps1`) PASS; report the new `git_revision` from `describe_server` to the
   paper session so it can be registered (design spec decision 45). Do not change fitness, chi² or any
   default; `chi2_recalc` must still equal `chi2`.

## Not in scope

The agent's own choice of bounds and its discarding of the affected solutions; the paper session handles
that. Nothing here touches `evaluate_lines` / `optimize_mirror`.
