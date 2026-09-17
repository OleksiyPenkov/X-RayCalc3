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

**Smoke test:** `pwsh -File XRC_MCP\smoke\session.ps1` drives one live stdio session against
`_Out\BIN\XRC_MCP.exe` in a throwaway work directory, calls every one of the 16 tools (jobs are
submitted, polled through `job_status` and read with `job_result`; one is stopped with
`cancel_job`) and checks the Ru/C Bragg-peak angle, seed determinism of `optimize_mirror` and
`fit_xrr`, the `path_outside_workdir` refusal, that the inbox is byte-identical afterwards, and
that `log\calls.jsonl` holds exactly one tool line per `tools/call` sent. Exit code 0 means every
check passed; `-KeepWorkdir` leaves the work directories behind for inspection. It takes a few
seconds.
