# Missing capability: `fit_xrr` cannot smooth the measured curve

_From the paper-2 orchestrator session, 2026-09-17. Author, asked whether the agent should get smoothing in
`fit_xrr`: "Of course he needs that". Follows `06035de` (registered binary of paper 2 from segment 9 on)._

## Observed

The brief's manual ("Working with experimental data", Data conditioning) tells the user to condition a measured
curve in three steps: **normalize** by comparing with the calculated curve at about 0.4°, **smooth**
(Main menu – Data – Smooth), **trim**. Over MCP the agent can do the first (`scale`) and the third
(`theta_range`), but not the second: `unit_MCPFit.pas` ~951–954 sets `Smooth := False; SmoothWindow := -1`
with the comment "The GUI's smoothing of the measured curve is a display aid, not part of the fit; the server
never turns it on." The agent session has no shell and no file access, so it has no other way to smooth.

That comment is wrong for the workflow the author uses: GUI Data – Smooth (`frm_Main.actDataSmoothExecute` →
`TfrmChartInfo.SmoothData`, `frame_ChartInfo.pas` ~396) replaces the active measured series by
`MovAvg(Data, 5)` (`unit_DataProcessing.pas` ~61) and saves it, and the fit then runs on the smoothed data.
The author's reference fit of paper-2 specimen P2-04 (2026-09-17) was made on a curve smoothed this way; the
agent's fit of the same curve (job `fit-20260917-134808-b160`) was made on raw counts × scale, and its
point-to-point scatter in the low-count region θ 2.6–3.1° is 4× the author's (0.56 vs 0.14 relative).

Second, smaller item: the `scale` property text in `unit_ToolsJobs.pas` ~594–598 describes the step as
'the wiki's "normalise to the total-reflection plateau" step'. The manual does not say that; it says to compare
the measured and the calculated intensity at about 0.4° and divide by the ratio. In paper 2 the agent set
every scale to 0.96–0.97 / max count, i.e. it followed the tool text, and the author rejects those
normalizations.

## Required

1. `fit_xrr` gets an optional data-conditioning argument that applies the **same operation as GUI
   Data – Smooth** to the measured curve: `MovAvg(Data, 5)` from `unit_DataProcessing.pas`, on the linear
   intensities, no re-implementation. Proposed shape: `"smooth": {"passes": 1}` (integer ≥ 0, default 0 =
   off; each pass is one click of Data – Smooth; cap it, e.g. at 10, with `invalid_argument` above). If the
   coding session sees a reason for a `window` parameter, it may add one with default 5, but `passes` alone
   must reproduce the GUI exactly.
2. Order of operations must equal the manual's: `scale` → smooth on the **whole** curve → `theta_range` trim.
   (Smoothing after the trim would change the points next to the trim edges; `MovAvg` also copies the first
   `Window div 2` points unchanged and flattens the last ones, which should fall outside a trimmed range, as
   in the GUI workflow.)
3. The job's `measured.dat` and the curve embedded in `fit.xrcx` hold the curve **as fitted** (scaled and
   smoothed), so the project opens in the GUI showing what was fitted. The result echoes the setting
   (e.g. `"smooth": {"passes": 1, "window": 5}`), and `save_project` with `curves.job_id` embeds that same
   conditioned curve (it already copies the job's curve; assert it).
4. `get_measurement` stays raw. No smoothing of the calculated curve is added or changed
   (`chi2.movavg_window` is a different thing; say so in its description to avoid confusion).
5. Reword the `scale` description to the manual's procedure: compare the measured and the calculated
   intensity at about θ 0.4° (past the critical angle, before the first Bragg peak) and choose `scale` so
   they agree there; not "the plateau", not 1/max. Do not add auto-normalization.
6. Default off: a request without `smooth` must give the same result as `06035de` for the same seed (assert
   with an existing regression case, chi² and parameters identical).
7. Tests (DUnitX): `passes: 1` on a known curve equals `MovAvg(Data, 5)` point for point; `passes: 2` equals
   two applications; order scale → smooth → trim (a case where trim-then-smooth would differ);
   `measured.dat` equals the fitted curve; echo in the result; `passes: 0` and absent are identical;
   out-of-range `passes` is `invalid_argument`.
8. Full suite green, smoke PASS, rebuild Win64 from a clean tree, report the new `describe_server`
   `git_revision` to the paper session (it becomes the registered binary from paper-2 segment 10 on,
   design-spec decision 46). Do not change fitness, chi², engines, optimizer defaults, or the `.xrcx` version.

## Not in scope

Optimizer defaults (`DEF_POPULATION` 100 / `DEF_ITERATIONS` 100): the author's lab practice is 100
iterations with population 500–1000 ("population wins iterations"); whether the server default changes is
the author's call and is **not** part of this spec unless he says so. *(Decided after this spec shipped:
`DEF_POPULATION` became 500 in `7f5b397`, 2026-09-17, and the result now echoes the effective optimizer in
`optimizer_used`. A request that omits `population` no longer reproduces a fit made by `f0168e0` or
earlier.)* The agent's choice of resolution
(ΔΘ) and its normalization values are handled in the paper session by an intervention.
