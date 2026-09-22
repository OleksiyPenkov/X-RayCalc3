# XRC_MCP

`XRC_MCP.exe` is a console MCP (Model Context Protocol) server that exposes the X-Ray Calc 3
calculation engine to LLM agents over a JSON-RPC 2.0 stdio loop. It is started with a mandatory
`--workdir <absolute path>`, which is the sandbox every tool is confined to.

Build it with the `XRC_MCP Win64` command in the repository's `CLAUDE.md` build table. Design and
requirements live in `docs/superpowers/specs/2026-09-09-xrc-mcp-design.md` and
`docs/superpowers/specs/2026-09-08-xrc-mcp-server-requirements.md`.

**Win64 build dependency:** `optimize_mirror` runs the universal optimizer through
OmniThreadLibrary's `Parallel.For`, and `fit_xrr` runs the LFPSO fit through the same
library's `Parallel.&For` (`unit_LFPSO_Base.pas`). Both need **OmniThreadLibrary 3.08 or later**
(the clone at `D:\DelphiProjects\_Libraries\OmniThreadLibrary` is checked out at `release-3.08`).
Older versions cast code pointers to `Cardinal` in `TOmniTaskExecutor.GetMethodAddrAndSignature`
and hang for ever under dcc64 (see `CLAUDE.md`, Dependencies). The same dependency applies to
`xrccmd -u`, XRFCalc, and the Win64 GUI's own fitting. The symptom of an old library is a job
stuck at iteration 0 with an empty `results\progress.log`, and a server that will not exit.

`units\gitrev.inc` is **not** in version control: the project's pre-build event regenerates it from
`git rev-parse --short HEAD` on every build, so `git` must be on `PATH`. Its value is what
`describe_server` reports as `git_revision`.

**`fit_xrr` since 2026-09-10:** `"free"` accepts `{"target":"period","stack":k}` to fit the
period of repeating stack `k` (index in `stacks`, substrate-first) inside a bound
`{"target":"period","stack":k,"min":..,"max":..}` (Angstrom; default the start period +/-30 %; at
least one thickness of that stack must be free too). Without it the periodic engine holds the
period of the start model; a profile fit never holds it. The result's `period_mode` lists every
repeating stack as `held`, `free` or `floating` with `start_A`/`fitted_A`, and `bounds_used` carries
the period bound. `"scale"` (default 1, > 0) is a fixed multiplier applied to the measured
intensities before the fit - the wiki's "normalise to the plateau" - echoed in the result and stored
in `measured.dat` and `fit.xrcx`; it is not fitted. An omitted density starts at the Henke bulk
value (so it gets the +/-30 % default like any other parameter), and a start value outside its
bounds is refused with `invalid_argument`. `calc_reflectivity` reports `critical_angle_deg` as
sqrt(2<delta>) with <delta> thickness-weighted over the top 500 A of the structure, and its Bragg
peaks exclude maxima whose 2d sin(theta)/lambda sits more than 0.25 from an integer (Kiessig fringes,
the plateau edge).

**`fit_xrr` since 2026-09-17:** `"smooth": {"passes": n}` (whole number 0..10, default 0 = off)
smooths the measured curve before the fit with the GUI's Data - Smooth, `MovAvg(Data, 5)` on the
linear intensities, once per pass. The order is the manual's: `scale`, then `smooth` over the whole
curve, then the `theta_range` trim. The result echoes `"smooth": {"passes": n, "window": 5}`, and
`measured.dat`, `fit.xrcx` and a `save_project` with `curves.job_id` hold the curve as fitted;
`get_measurement` stays raw. Without `smooth` a fit is identical to the one `06035de` ran.
`scale` is the manual's normalize step - make the measured and the calculated curve agree at about
theta 0.4 deg - not "normalise to the plateau" as the text above and the tool description used to
say. `chi2.movavg_window` only sets the point weights and smooths neither curve.

**`fit_xrr` optimizer default since 2026-09-17:** `optimizer.population` defaults to 500 (it was
100); `iterations` stays 100. This is the lab's practice - 100 iterations with 500 to 1000
particles, "population wins iterations" - at about 25 s per fit of a 1000-point curve. A request that
names no `population` therefore no longer reproduces a fit made by `f0168e0` or earlier; one that
names it is unaffected. The result now carries `optimizer_used`, every optimizer key with the
defaults filled in, so a job's own `job_result` says what ran; `request.json` still stores the
arguments as sent. To replay a job from before `optimizer_used` existed that omitted `population`,
add `"population": 100`.

**`fit_xrr` since 2026-09-16:** every fitted value lies inside the bounds the request gave. The
periodic engine's `NormalizeD` (which holds or pulls back the period) now spreads its correction only
over layers with room inside their own thickness bounds, and its `XSeed` clamps every seed (a seed
outside its bounds, after a shake or with `range_seed: false`, used to be evaluated as it stood and
could end the fit on a value the client never allowed). The result carries `out_of_bounds`, a list in
the shape of `bounds_used` plus `value` of every fitted value outside its bound; it is empty, and a
client may treat a non-empty one as a server defect.

**`save_project` since 2026-09-16:** a project saved with `curves.job_id` takes the `[FIT]`, `[LFPSO]`,
`[PARAMS]` and `[ANGLE]` blocks of that job's own `fit.xrcx`, so it opens in the GUI as the fit that ran
(periodic or profile mode, the real iterations and population, the chi-squared weighting, the resolution
width and the range); explicit `theta_min`, `theta_max`, `points`, `delta_theta` and `lambda` still win.
Without a job the defaults stay, except that `[FIT] Mode` is 1 (periodic) when the structure has a
repeating stack and 0 (irregular) otherwise. Before, every saved project carried Mode 0 with 100
iterations and a population of 1000, whatever fit had produced it.

**`job_wait` since 2026-09-18:** `job_wait` blocks until a job reaches a final state or
`wait_s` seconds have passed (default 300, at most 900) and returns the `job_status` object plus
`waited_s`. One call replaces a poll per turn: a fit of several hundred seconds used to cost two
to three hundred `job_status` calls, which is a whole segment of an agent's turn budget. The stdio
loop serves one request at a time, so while a wait is in progress the server answers nothing else -
including a `cancel_job` for the job being waited on; a cancel from another client, or the server
shutting down, does end the wait, because the job then reaches `cancelled`. Keep `wait_s` under the
client's own MCP tool timeout (`MCP_TOOL_TIMEOUT`, milliseconds, in Claude Code) or the client
abandons the call while the server is still inside it - the job itself is unaffected and
`job_status` still reports it.

**`fit_xrr` since 2026-09-18:** three arguments and one new block in the result.

- `"scale_auto": true` (or `"scale": "auto"`) is the GUI's Data - Normalize Auto
  (`unit_DataProcessing.NormalizeAuto`): the
  server takes the largest measured intensity below `auto_theta_max` (degrees theta, default 0.5)
  and sets it equal to the reflectivity of the start model at that same angle, so
  `scale = R_calc(theta_max) / I_max`. It is computed on the raw curve, before `smooth` and before
  the `theta_range` trim, with the wavelength, polarization and resolution of the fit. The result
  carries `scale_mode` (`"fixed"` or `"auto"`), `scale_theta`, `scale_counts` and, for `auto`,
  `auto_theta_max`; with `scale_auto` true a number in `scale` is ignored. The boolean exists
  because a key typed number-or-string is easy for a client to get wrong: on the exp-03 run of
  2026-09-18 an agent sent `"scale": auto` unquoted fifteen times running and its own client refused
  every call as malformed JSON before the server saw it. A numeric `scale` behaves exactly as
  before. The `scale` description no longer
  says to compare the curves at about theta 0.4 degrees and not to normalise to the total-reflection
  region: that was the opposite of the laboratory's procedure.
- `"paired": ["sigma", "density"]` sets the GUI's Paired boxes - `TFitValue.Paired`, the `HP`/`SP`/`RP`
  flags of the project file, which `TLFPSO_Poly.Set_Init_XPoly` already honours - so that those
  parameters keep one value over the periods of a `profile` fit instead of getting a polynomial of
  their own. This is the author's practice on a multilayer: the thicknesses carry the gradient, the
  roughness and the density are one number per layer. An item is a bare parameter name, which pairs
  it in every layer, or `{"stack", "layer", "parameters"}` addressed as in `"free"`. It is refused
  with `invalid_argument` without `"profile": true`. The result echoes what was paired in `paired`,
  and a paired parameter has no entry in `profiles`.
- `"report"` is in every result, and the same object is written as `report.json` in the job folder
  (`files.report`). It holds `orders` (every Bragg order of the fitted period inside the fitting
  range: the measured and the calculated maximum located independently inside the same window, the
  ratio calculated over measured, and `visible`, which is `I_meas > 3 x background` with the
  background the median of the last hundred fitted points), `edge` (three points evenly spaced
  between the start of the range and the first minimum of the calculated curve), `fringes` (the
  Kiessig fringes between orders 1 and 2, each secondary maximum paired with the minimum that
  follows it down the falling curve, with `contrast = i_max / i_min` per pair, `mean_contrast` and
  the count; the pairs are located on the measured curve and both curves are read at those same two
  angles, so `measured` and `calculated` are the same measurement made twice - which is the number
  the resolution of the calculation is chosen by. The contrast is deliberately local: between two
  orders the curve falls by decades, and the largest maximum of the stretch over its smallest
  minimum would measure that fall and not the fringes), `bands` (the
  range in eight equal bands of theta, each with the mean and the rms of
  `log10(R_calc / I_meas)`), `near_bounds` (every fitted value within 5 % of its range of one of its
  bounds), `chi2`, `chi2_start`, and `start`, the same numbers for the model the fit began with.
  There is no verdict and no threshold anywhere in it: the skill states the pass criteria, the tool
  states the numbers.

A request that uses none of the new keys gives the same answer as `7f5b397` for the same seed: every
key that revision reports is byte-equal (checked by running one fit through both binaries).

**Bragg peaks since 2026-09-18:** `calc_reflectivity`'s peak summary no longer searches for maxima at
large when the structure has a repeating stack. For n = 1, 2, ... the order is the largest point
inside `BraggSearchWindow` - from 0.06 degrees below the Bragg angle to 0.06 degrees above the
refraction-corrected one, `sin^2(theta_n) = (n lambda / 2 d)^2 + sin^2(theta_c)`, because refraction
moves a maximum up and never down - provided it is a local maximum, sits more than 0.05 degrees above
the critical angle, and stands more than three times above the smallest point of the same window.
The old rule asked a maximum to stand three times above the smallest value within a fixed number of
points; a Bragg peak is broader than that window and failed the test while the sharp Kiessig
satellite beside it passed, which is how the summary of the C/Co mirror P2-05 came to report a first
order at 0.855 degrees with R = 0.015 instead of the real one at 0.915 with R = 0.203. Without a
period (no repeating stack) the old running-index search is unchanged.

**Inbox since 2026-09-21:** a `.xrdml` file (PANalytical, schema 1.0 to 2.x) in a specimen folder is
a measurement. `get_measurement` reads it raw (`Shared/Universal/unit_xrdml.pas`, shared with the
GUI's Data - Load): the 2Theta axis is brought to theta, counts (x attenuation factors when present)
are divided by the counting time and normalised to 1 at the maximum, a zero count is floored as the
text parser floors it, and the wavelength the file implies (the K-alpha doublet weighted by the file's
ratio unless a monochromator or a hybrid mirror selects K-alpha1) overrides `meta.json`;
`lambda_source` says `file: <rule>`. The header carries the raw peak rate, the counting time, the
detector, its readOutPeriod and the zero count.

**`fit_xrr` since 2026-09-22 (`scale_solve`):** the measured scale is a nuisance parameter solved in
closed form inside the objective for every candidate, held within +/- `scale_solve_window` (default
0.2) of the anchored scale; default on. The result carries `chi2_scale` (`solved` / `anchored`),
`scale_ratio`, `scale_solved`, `scale_clamped`, `scale_start_ratio` and `chi2_scale_definition`, and
`report.json` carries the same scale fields beside every chi2 it holds. `measured.dat`, `calc.dat`
and `fit.xrcx` stay at the anchored scale; `residual.dat` is at the solved one and its header says so.
`"scale_solve": false` gives the anchored chi2 of every earlier version, bit-identical. The request now
carries `scale_solve`, so a request hash differs from one made before 2f92b9b even when the fit does
not. Spec: `docs/superpowers/specs/2026-09-22-solved-scale-design.md`.

**`assess_xrr` since 2026-09-22 (tool 18):** is this measured curve worth fitting? Eight checks on
the raw `.xrdml` (counting rate against `detector_max_cps`, first order against the plateau, total
reflection reached, orders visible against the design, range below background, points per fringe
and per order, footprint knee, zero counts), each `{value, threshold, verdict, why}` plus the numbers
behind it, `verdict` the worst of them, `summary_text` one line per check. `unknown` whenever an
input is missing; no threshold is invented in code (only ratio > 1 and < 2 points per fringe fail).
Accepts a bare substrate, `"stacks": []`, as the design. The checks live in
`units/unit_MCPAssess.pas` and are the GUI's Data - Assess XRR quality as well.

**Release 3.9.2.970 (2026-09-22, e9ad011 engine):** the frozen public release the XRR fitting
skill's campaign 3 runs on. Gate on the release candidate: identity, the 158-fit replay (158 of 158;
the two Ru/C profile fits that fail on 3.9.1.950 now succeed), the 30-fit control against the study
(chi2-identical), substrate density, glass tooling, presets and the Henke hash all pass. RECORDED, not
waved through: with `"scale_solve": false` and `"smooth": {"passes": 1}`, two of the 156 campaign 1-2
replays differ from 3.9.1.950 - `workdir-RuC-260910B-a fit-20260919-082647-b913` (single Ru film,
chi2 2.61707 -> 2.61723, structure unchanged to 1e-3 A) and `workdir-T05c fit-20260918-222443-960a`
(Co/C, theta_weight 1: a different, lower minimum). The drift is deterministic, present since the
solved-scale commit 2f92b9b, and confined to the smoothing path: the same requests with
`"smooth": {"passes": 0}` are bit-identical across builds. Procedure v5 (smoothing off) and the
recovery benchmark are unaffected. "No silent numeric drift against 3.9.1.950" is therefore NOT
claimed for smoothed fits on this release. Also found: with the solve on, a substrate-density scan
on a glass edge has a flat chi2 profile (the solve absorbs the density-dependent edge amplitude);
glass work needs `"scale_solve": false` or an anchored edge. `[FIT] Mode=1` stays as `fit_xrr` writes
it - the engine that ran; the GUI's fit write-back was fixed the same day to follow the engine rather
than the model's shape.

**Smoke test:** `pwsh -File XRC_MCP\smoke\session.ps1` drives one live stdio session against
`_Out\BIN\XRC_MCP.exe` in a throwaway work directory, calls every one of the 18 tools (jobs are
submitted, polled through `job_status`, waited for with `job_wait` and read with `job_result`; one is
stopped with `cancel_job`) and checks the Ru/C Bragg-peak angle, seed determinism of `optimize_mirror` and
`fit_xrr`, the `path_outside_workdir` refusal, that the inbox is byte-identical afterwards, and
that `log\calls.jsonl` holds exactly one tool line per `tools/call` sent. Exit code 0 means every
check passed; `-KeepWorkdir` leaves the work directories behind for inspection. It takes a few
seconds.
