# Defect: `save_project` writes default fit settings instead of the job's

_From the paper-2 orchestrator session, 2026-09-16 16:50. Author: "fix now". Follows the bounds fix at `2643c4c`._

## Observed

`save_project` with `curves.job_id` (or `curves.measurement_id`) writes `params.dsc` with the server's
defaults: `[FIT] Namx=100 Pop=1000 Mode=0 PolyOrder=1 PWChi=1 TWChi=0 Window=0.05 Tol=0.005`
(`XRC_MCP\units\unit_MCPProjectFile.pas` ~line 361, `FitMode := 0` etc.). The job's own `fit.xrcx`, written
by `fit_xrr` (`unit_MCPFit.pas` ~line 1562–1572), carries the settings that ran: `Mode=1` (periodic) or `2`
(poly), the real iterations and population, `TWChi` from the request's `chi2.theta_weight`.

Effect: a project the agent saved from a finished fit opens in the X-Ray Calc 3 GUI in **Irregular** fit
mode with 100 iterations and population 1000, so the author read the agent's fits as "not periodic". Example:
paper-2 `experiments\runs\exp-03\workdir\projects\fit-P2-02.xrcx` (Mode=0) versus
`experiments\runs\exp-03\workdir\jobs\fit-20260916-142326-7a33\fit.xrcx` (Mode=1, Namx=200, Pop=150, TWChi=1),
both from the same job. The model, curves, chi² settings and calculation range are otherwise the same.

## Required

1. When `save_project` embeds a job's curve (`curves.job_id`), the written `params.dsc` `[FIT]`, `[PARAMS]`
   and `[ANGLE]` sections must equal those of that job's `fit.xrcx` (mode, iterations, population, poly
   order, point/theta weighting, window, tolerance, resolution width, range), unless the client passes an
   explicit calculation range or points, which keep precedence as now.
2. When `save_project` embeds an inbox curve (`curves.measurement_id`) with no job, keep the defaults but
   make the periodic/irregular choice follow the structure: a structure with any stack `N > 1` writes
   `Mode=1`, otherwise `0`.
3. Tests (DUnitX): save a project from a finished periodic fit job and assert the `[FIT]` values of the
   written file equal the job's; save from an inbox curve with a 20-period stack and assert `Mode=1`.
4. Full suite green, smoke PASS, rebuild Win64 from a clean tree, report the new `describe_server`
   `git_revision` to the paper session (decision 45 registration is updated to it). Do not change fitness,
   chi², defaults of `fit_xrr`, or the `.xrcx` version.

## Not in scope

The agent's period range choices; anything in the engines.
