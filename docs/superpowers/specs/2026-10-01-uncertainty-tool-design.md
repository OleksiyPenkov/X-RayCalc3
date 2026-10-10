# XRCUncert: parameter uncertainties as a separate tool

_2026-10-01. Designed with the author, section by section. Replaces the GUI part of the dropped
3.10 line (`archive/3.10-bayes`, f521c5b); its headless core is reused._

## Why

The 3.10 line put Bayesian parameter uncertainties into the main app. The sampler worked; the GUI
around it did not: a Likelihood objective as a prerequisite, raw counts as a prerequisite, priors in
the Limits dialog, a workflow panel, joint-fit dialogs and a version 9 project format. The author
dropped it ("adding it to the main app was a bad idea") but still needs the error bars. 3.10 also
handled periodic structures only and ignored tables and profiles.

## Goal

An XRR user opens a fitted project in a small separate tool, presses Run, and reads
`value ± error` for the fitted parameters, with plain warnings only when something is wrong.

**Success:** on a calculated curve with known truth and counting noise, for each of the three fit
modes, the truth falls inside the reported range at about the expected rate; and the author has
run the tool on a real project and accepted its GUI.

## Decisions (agreed; do not reopen)

| # | Decision |
|---|----------|
| 1 | A separate VCL application (working name **XRCUncert**), built like XRFCalc and added to `XRC3.groupproj`. The engine stays shared source; no BPL. |
| 2 | Scope: one model, one curve, optional priors. **Joint fits are out**: a separate later project, in the main app. |
| 3 | All three fit modes: periodic, profile (poly), table (irregular). |
| 4 | Profiles and tables report a band on a depth chart plus summary numbers, not a row per table entry. A structure with more than 20 sampled table entries is refused before the run, with one line saying why. (Changed 2026-10-01 after the truth gate: at 40 and 80 entries neither the ranges nor the summary numbers were right, at any run length tried.) |
| 4a | Every run settles, restarts around its best walker, then samples. When the walkers still disagree (R-hat above 1.2) the tool repeats once at a longer length; if they still disagree it shows no ranges and says the fit has not settled. |
| 5 | Everything lives in the single `.xrcx` (it goes to the ELN): priors, results and counts are extra archive entries. No sidecar file. The project version stays 8. |
| 6 | No settings dialog and no separate likelihood-fit step. Steps, walkers and burn-in are the tool's defaults. |
| 7 | Default output is `value ± error` and plain warnings. Correlations, device and sampler numbers are behind Details. User-facing text says "uncertainty", never "posterior". |
| 8 | The main app changes in two places only: a menu item that launches the tool, and a save step that keeps the tool's entries. |
| 9 | Work happens in the worktree `.claude/worktrees/uncertainty-tool` (branch `worktree-uncertainty-tool`). Nothing is merged or pushed to master until the whole project is complete and approved. Test builds go to `Z:\files\Software\`; the download cards in `Z:\index.html` are not touched. |

## 1. Architecture and data flow

1. **Open.** The tool reads the `.xrcx` with the existing project reader
   (`XRC_MCP/units/unit_MCPProjectFile.pas`, already free of server code) and lists the models
   that have a linked curve. A project with one such model skips the choice. A project newer than
   `CURRENT_PROJECT_VERSION` is refused as the main app refuses it (`unit_ProjectVersion`).
2. **Parameters.** The fit mode and the fit settings come from the project as the main app saved
   them. The free parameters and their limits are taken as they stand; limits are not edited in
   the tool.
   - Periodic: free layer values and periods (as 3.10).
   - Profile: the polynomial coefficients of each profiled layer value.
   - Table: every free table entry.
3. **Counts.** Raw counts are read from the curve's `.xrdml` source (the `* Source file:`
   description line, as Data - Assess XRR quality finds it) when the file exists and its angle
   grid matches the curve's, and are stored in the project as `counts_<curve id>.dat`. Without
   counts the tool runs with the estimated noise alone and says so in one line.
4. **Run.** The walkers start in a tight cluster around the fitted solution in the project; the
   burn-in moves them to the likelihood optimum. GPU when available, CPU otherwise, on a worker
   thread that ends with `DrainParallelTasksBeforeExit`. Stop keeps what has been recorded.
5. **Result.** Per-parameter summary, summary numbers, the curve band and the depth band, stored
   in the project as `uncert_<model id>.json` together with the priors and a fingerprint of the
   model, the curve, its counts and the priors. A fingerprint mismatch shows the stored result as
   out of date. Raw samples are not stored.

**Risk (settled by the truth gate, section 5).** The classic fit often minimises a log-weighted
χ², whose optimum differs from the likelihood optimum. If burn-in alone does not bridge that for
profiles or tables, the tool runs a short automatic refinement before sampling (the archived
`TLFPSO_Posterior`, extended to the mode in question). It is never a user step.

## 2. The window

One form; every control is defined in the DFM.

```
┌ XRCUncert — W_B4C_260201A.xrcx ───────────────────────────────────────┐
│ Model [ Model 1 ▼]  Curve: 260201A      [ Run ]  [ Stop ]             │
│ ~1 min 10 s left                                                      │
├──────────────────────────────────────────┬────────────────────────────┤
│ Parameter       Value    ±    Known   ±  │  [ Curve ] [ Depth ]       │
│ ▸ Summary                                │                            │
│   Period, Å     55.7    0.1              │   measured curve + band    │
│   Total, Å      2785    4     2790   10  │   or value vs period       │
│ ▸ Stack 1                                │   number + band            │
│   W  H, Å       18.2    0.3              │                            │
│   W  σ, Å        3.1    0.2              │                            │
│   B4C ρ          2.31   0.05             │                            │
│ ▸ Substrate                              │                            │
├──────────────────────────────────────────┴────────────────────────────┤
│ ⚠ No raw counts found: errors rely on the estimated noise only.       │
│                                [ Details… ] [ Copy table ] [ Export ] │
└───────────────────────────────────────────────────────────────────────┘
```

- **Parameter list.** A flat grouped ListView, as `frm_Limits`. "Known" and its "±" are the prior;
  they are the only editable cells, with a Note. A layer value that is profiled or tabulated has
  no row of its own; it appears on the Depth chart and through the summary numbers.
- **The ± value.** Half the 16-84 % range. When the two halves differ by more than a factor
  of 1.5 the cell shows `+0.3 / −0.1`.
- **Charts.** Curve: the measured data and the 16-84 % band of the model. Depth: thickness, sigma
  or density against period number with its band; shown only for profiles and tables.
- **Progress.** One line: time left. Nothing else while running.
- **Warnings**, plain sentences, only when they apply: no counts; a parameter at its limit; a
  table too large to sample reliably; the run stopped early; the result is out of date; the GPU
  failed and the CPU took over.
- **Details.** Correlations, the device, acceptance, the chain's reliability numbers, the
  settings used.
- **Copy table / Export.** The parameter table as text to the clipboard, or as CSV.

## 3. Launch and the save conflict

- **Standalone:** File - Open, drag and drop, or a project path on the command line
  (optionally a model ID).
- **From the main app:** Calc - Parameter uncertainties… saves the project (asking first when it
  is modified) and starts `XRCUncert.exe` with the project path and the active model's ID.
- **The tool never rewrites the project.** It adds or replaces only its own entries
  (`uncert_*.json`, `counts_*.dat`) in the archive.
- **The main app's save** (`frame_ProjectPanel`, before `Zip.AddFiles`) copies those entries from
  the project file on disk into its temp folder when they are missing there or newer on disk, so a
  result written while the project was open survives the next save. The main app extracts and
  re-zips every entry (`ExtractFiles('*.*')` / `AddFiles('*.*')`), so entries it does not know
  survive an open-save cycle already.
- A model edited after a run no longer matches the fingerprint; the tool shows the result as out
  of date.

## 4. The core

**Restored from `archive/3.10-bayes` into `Shared/Bayes/`**, with their tests:
`unit_StretchSampler`, `unit_Xoshiro`, `unit_ChainStats`, `unit_Likelihood`, `unit_ParamMap`,
`unit_LogPosterior`, `unit_JointPosterior` (the batch evaluator runs a single curve through its
one-member form; it is also the base for the later joint-fit project), `unit_PosteriorBatch`,
`unit_GpuPosterior`, `unit_Expression`, `unit_SampleRun`.

**Not restored:** the MCP request layer and the `sample_posterior` tool, the GUI units
(`unit_GuiUncertainty`, `unit_GuiJoint`, `unit_GuiBayesRequest`, `frm_Uncertainty`, the workflow
panel), the orchestrator changes, the v9 project format. `unit_LFPSO_Posterior` only if the truth
gate asks for the refinement.

**One change to shared engine code.** The GPU likelihood kernel goes back into
`Shared/Math/unit_gpu_calc.pas`. The classic fit path does not call it; the existing GPU and fit
tests must pass unchanged.

**Profiles and tables.** `TLayerData.PP` already carries a per-period table for each layer value.
The extension is confined to `TParamMap` and to the step that expands a structure into layers:

- Table: one slot per free table entry; `Apply` writes it into `PP`.
- Profile: one slot per polynomial coefficient; `Apply` evaluates the polynomial into `PP`, as
  `TLFPSO_Poly.FillModel` does. `C[0]` follows the GUI's rule (it is the layer's current value,
  not stored in the project).
- Limits are checked on the resulting table values, as the classic engines check them.
- The sampler, the likelihood and the GPU scorer are unchanged. Whether the archived posterior's
  expansion reads `PP` is checked first in plan A; if not, that expansion is changed to do so.

**Summary numbers.** Mean period, total thickness and first-to-last drift per stack are evaluated
for every recorded sample by the parameter map itself (so a prior on one is part of the map's
prior term on the CPU and the GPU path alike), and each has its own range. A prior on a summary
number is one Gaussian term on that value; a prior on a plain parameter is the map's own, as 3.10.

**Large tables.** More than 20 sampled table entries are refused (decision 4). The truth gate found
10 entries sound and 40 not; nothing between was tested, and the R-hat check (decision 4a), not this
limit, is what keeps a wrong range from being shown.

## 5. Testing

DUnitX, Win32 Debug, in the existing suite.

1. **Restored units:** their archived tests pass on the branch.
2. **Parameter map:** profile and table slots - vector to structure and back, limits respected,
   `C[0]` rule, summary numbers and their priors.
3. **Truth gate (headless, before any GUI work).** For each of periodic, profile and table: a
   calculated curve with known truth and added counting noise, started from a classic-fit result,
   not from the truth, over several seeds. The truth must fall inside the 16-84 % range at about
   the expected rate, for plain parameters and for summary numbers. The gate also decides whether
   burn-in alone is enough and where the large-table threshold sits.
4. **Project entries:** the tool's entries survive a main-app open-save; a result written while
   the project is open survives the next save; a changed model marks the result out of date.
5. **The tool's GUI** is checked by the author on a test build from Z:. Nothing reaches master or
   a release before that.

## 6. Build order

- **Plan A:** restore the core, profile and table support, the truth gate.
- **Plan B:** the tool, the main app's menu item and save step, installer entry
  (`XRCUncert.exe`, Win32 and Win64) and one help page. Starts only when the gate in plan A passes.

## Out of scope

Joint fits; editing limits or the model in the tool; a likelihood objective in the main app;
showing uncertainties inside the main app; MCP or `xrccmd` access to the sampler (it can be added
later over the same core); storing raw samples; a project format change.
