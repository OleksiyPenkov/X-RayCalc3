# Four tool changes for the fitting skill (`job_wait`, `scale: "auto"`, paired profile, fit report)

_From the paper-2 orchestrator session, 2026-09-18. Design-spec decision 49 (the loop paused after P2-07; a fitting
skill is built before any further fit or design) lists as its part (4) "a tool change so the agent cannot misread its
own result". The skill text is `D:\MultilayerLab\Papers\LLM-XRay-Optics-Lab\experiments\brief\manual\xrr-fitting-skill.md`;
the gaps below were found while executing it with the tools on 2026-09-18 (five headless sessions). Follows `7f5b397`
(registered binary of paper 2 from segment 10 on). Priority order as listed; item 1 alone unblocks the agent's
qualification test on the exp-03 launcher (300 turns)._

## Observed

1. **No blocking wait.** `job_status` "reports the state of a submitted job without waiting for it" and returns at once.
   A fit with population 5000 runs 600–700 s; the session polls it once per turn, 200–355 polls per fit, and one
   session died at its turn limit with the job at iteration 65 (`experiments/skill-dev-2026-09-18/stream-run1-maxturns.jsonl`).
   The exp-03 agent launcher allows 300 turns per segment, so one fit consumes a whole segment in polling.
2. **Normalization by hand.** The laboratory's procedure (GUI Data – Normalize Auto, `unit_DataProcessing.pas`
   `NormalizeAuto`) sets the measured maximum in the critical range equal to the model's value at that angle. Over MCP the
   agent must call `get_measurement`, find the maximum, call `calc_reflectivity` over 0.15–0.6°, read R at that angle and
   divide. Every session did it right, at about four turns and one avoidable source of error. The `scale` schema text
   (`unit_ToolsJobs.pas` ~610–620) still tells the agent to compare at about 0.4° and "not to normalize to the
   total-reflection region", the opposite of the author's procedure; the skill overrides it in words.
3. **Profile mode varies everything.** `profile: true` gives every parameter of every layer a polynomial over the periods.
   The author's practice (17 of his multilayer projects, `experiments/skill-dev-2026-09-18/author-xrcx-survey.tsv`) is
   Polynomial order 3 with the **thicknesses unpaired and sigma and density paired** (the GUI's Paired boxes, `HP/SP/RP`
   in the project JSON; "stack locking" in the 2024 paper). The tool cannot express that; the test-B fit of P2-05 let
   sigma and density float per period and returned ρ_C 2.30 against the author's 2.06 with paired ρ.
4. **The session cannot judge its own fit.** With `points_inline_max` 0 the result has no curves and the session has no
   file access, so the checks the skill requires (every Bragg order calc/meas, the edge, the fringe contrast between orders
   1 and 2, the residual by band) are reconstructed by recomputing the fitted model with `calc_reflectivity` and reading
   peaks off two 2000-point lists in the model's context. It works, at about 60 k tokens per judgment, and the numbers
   were reproduced by the orchestrator from the job files (`skilltest_compare.py`); but it is the step three rounds of
   agent fits got wrong (decision 49), and it should be computed by the server, not read by eye.

5. **The Bragg-peak summary of `calc_reflectivity` picks Kiessig satellites.** The P2-05 skill-test session (2026-09-18 20:00,
   `experiments/skill-dev-2026-09-18/stream-T05.jsonl`) reports that "the coarse auto peak-finder locks onto a smaller Kiessig
   satellite near each order" and had to re-derive every order from fine local scans. The fit report of item 4 below must find the
   order at the maximum within ±0.06° of the Bragg angle of the fitted period, not by a generic peak search; and the existing
   peak summary should be checked against that rule on the P2-05 start model (C 32 / Co 18 × 20).

## Required

1. **`job_wait`** (or `job_status` with `"wait_s": <seconds>`): blocks up to the given time (cap at, say, 900 s; default
   300) and returns the same object as `job_status` as soon as the job finishes or the time is up, with `"waited_s"`.
   The MCP stdio loop must keep serving other calls or at least not time out the client: check the framework's
   per-call timeout (Claude Code's default MCP tool timeout is configurable by `MCP_TOOL_TIMEOUT`; state the limit in
   the tool description). Tests: returns early when the job finishes; returns at the cap when it does not; a finished
   job returns at once; cancel during a wait returns "cancelled".
2. **`scale: "auto"`** in `fit_xrr`: the server computes the start model on the measured grid (same lambda,
   polarization, resolution as the fit), finds the measured maximum in θ < 0.5° (parameter `"auto_theta_max"`, default
   0.5), and sets scale = R_calc(θ_max) / I_max — exactly `NormalizeAuto`, on the raw curve before smoothing and
   trimming. The result echoes the number used (`"scale": 7.798e-7, "scale_mode": "auto", "scale_theta": 0.20975,
   "scale_counts": 1064515`). Reword the `scale` description to the procedure: the measured maximum in the critical range
   equals the model there; drop the 0.4° text and the "do not normalize to the total-reflection region" sentence. A numeric
   `scale` keeps working unchanged. Test: auto on P2-05 equals the hand computation of test A (7.798e-7 ± 1e-10).
3. **Pairing in profile mode:** `fit_xrr` gets `"paired": ["sigma", "density"]` (per layer or global; default `[]` =
   today's behaviour), mapping to the layer flags `SP`/`RP`/`HP` that `TLFPSO_Poly.Set_Init_XPoly` already honours
   (profile unless Paired or N = 1). The result reports which parameters were paired. Test: profile fit with all three
   paired equals the periodic fit for the same seed and start (or state why it cannot, e.g. the floating period).
4. **Fit report in the result** (`"report"` object, always present; also written as `report.json` in the job folder):
   - `orders`: for n = 1… while nλ/2d < 1 and θ_n inside the range, the measured and calculated maximum within ±0.06° of
     the Bragg angle of the fitted period (θ measured, θ calc, I_meas × scale, R_calc, ratio calc/meas, `visible` =
     I_meas × scale > 3 × background where background = median of the last 100 fitted points);
   - `edge`: measured × scale and calculated at three angles evenly spaced between the range start and the first
     fringe minimum, with the ratios;
   - `fringes`: contrast (max/min) of the secondary maxima between orders 1 and 2, measured and calculated, and the
     count of fringes;
   - `bands`: the fitting range in eight equal θ bands, mean and rms of log10(R_calc / (I × scale)) per band;
   - `near_bounds`: every fitted value within 5 % of its range from a bound, with the bound;
   - `chi2`, `chi2_start`, and the same `report` for the start model under `"start"` so the agent sees what the fit
     changed.
   No verdict, no threshold: the skill states the pass criteria; the tool gives the numbers. Tests: on job
   `fit-20260918-170706-196b` (workdir-A) the orders are 0.98 / 1.22 / 1.09 / 0.72 at θ 0.9163 / 1.7772 / 2.6578 / 3.5322
   (orchestrator's numbers from the job files, `skilltest_compare.py`).
5. Full suite green, smoke PASS, rebuild Win64 from a clean tree, report the new `describe_server` `git_revision` to the
   paper session. Do not change fitness, chi², engines, optimizer defaults, or the `.xrcx` version; a request without the
   new keys gives the same answer as `7f5b397` for the same seed.

## Not in scope

Auto-trim, automatic Δθ, freeing the substrate (the author varies it by hand and the skill holds it fixed), any change to
the GUI.

## Registered binaries

- `dbee34c` — registered 2026-09-18 for exp-03 segments 16–19 (the loop) and the 12 Ru/C transfer sessions ran on `2021a9e`.
- `a413b7b` — registered 2026-09-20 for exp-03 segment 21 on (rebuilt 09:16 from a tree whose only uncommitted files were untracked; `describe_server` reports `a413b7b-dirty`, exe 3.8.1.890). Since dbee34c: 2021a9e `scale_auto`, 7a590aa fit write-back keeps stack/layer index, 16a9135 `chi2_plain` beside the weighted chi2 in result and report, e04902c gradient from a fit marked, a413b7b project loader FLastModel.
- `beb40c8` (3.9.1.950) — registered 2026-09-21 for exp-03 segment 23 on: the launcher path `_Out\BIN\XRC_MCP.exe` was rebuilt 12:25 by the X-Ray Calc session (a413b7b no longer exists on disk). Since a413b7b: 52034b7 GPU evaluation of the LFPSO population (3.9.0; CPU rescoring of the final chi2), beb40c8 substrate density honoured (<= 3.9.0 ignored a given value; projects of version <= 7 load with it reset to bulk, written as version 8), dfcea44 sigma/density profiles in profile-fit results, freeze/thaw and resume-fitting series (3.8.2), 39bb1a0 installer ships xrf_lines.json. The loop agent was told of the rebuild and the substrate-density change in intervention 15; its v4 models use SiO2 2.65 = bulk, so they compute unchanged.
