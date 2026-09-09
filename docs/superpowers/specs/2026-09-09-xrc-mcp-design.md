# XRC_MCP — design decisions

_Implements `2026-09-08-xraca-mcp-server-requirements.md` (the "requirements"). This note records
the choices the requirements leave to the implementer, and the reasons. The plan is
`docs/superpowers/plans/2026-09-09-xrc-mcp-server.md`._

## 1. Engine choice (requirements §2.3)

| Tool | Engine units | Why |
|---|---|---|
| `calc_reflectivity` | `Shared/Math/unit_calc.pas` (`TCalc`), `unit_materials.pas` (`TLayeredModel`), `math_globals.pas` (`ReadHenke`) | This is the GUI's calculation. Acceptance 2 (same curve as the GUI for the same `.xrcx`) holds by construction. |
| `fit_xrr` | `XRayCalc3/LFPSO/unit_LFPSO_Periodic.pas`, `unit_LFPSO_Poly.pas` (over `unit_LFPSO_Base.pas`) + the same `TCalc` | Requirements §4.4: "the GUI's LFPSO, with the same χ² definition". χ² is `TCalc.CalcChiSquare`. |
| `evaluate_lines`, `optimize_mirror`, `list_templates` | `Shared/Universal/*` (`TUniversalFitness`, `TUniversalOptimizer`, `TUniversalPSO`, `unit_universal_templates`, `unit_xrfx_package`) | This is what `xrccmd -u` runs and what XRFCalc drives. Acceptance 3 compares against XRFCalc. |
| `list_materials`, `optical_constants` | `math_globals.ReadHenkeTable` over the GUI's Henke directory | Same tables as the GUI. |

The `cmd_unit_calc` / `cmd_unit_fitting` variants are **not** used for calc/fit. `xrccmd -a` is a
different, cruder PSO with a different χ²; the requirements' acceptance 4 mentions it, but §2.3
and §4.4 both require the GUI engine, so the GUI engine wins. This is listed as an open question
for the author (§8 below).

Name clashes: `cmd_unit_types` and `unit_Types` both declare `TDataArray`, `TLayer`,
`TPolarisation`. Server units that touch both qualify the names (`unit_Types.TDataArray`,
`cmd_unit_types.TDataArray`). The test project already links both.

## 2. Henke tables

Both engines read `<name>.bin` files. The GUI's `ReadHenke` resolves the directory through
`TConfig.SystemDir[sdHenke]` (from `%APPDATA%\X-RayCalc3\xrc3.ini`, currently
`D:\SoftwareStorage\X-RayCalc3\Henke`). The universal engine's `TMaterialMixer.Initialize`
takes an explicit path. The server:

- uses `TConfig.SystemDir[sdHenke]` for both, so the tables are exactly the GUI's;
- never writes `xrc3.ini` (setting `TConfig.SystemDir` writes the ini, so it is only read);
- reports the resolved path, the number of `.bin` files and the newest file time in `describe_server`.

`TMaterialMixer.Initialize` changes the process working directory while it reads. Jobs run one at a
time (§5), so no other thread is affected; the server itself never depends on the CWD.

## 3. Structure JSON mapping

The requirements' structure JSON (substrate, stacks from substrate to surface, cap, buffer) maps to
the GUI's `TFitStructure` / `TXRCStructure` order, which is **surface first**:

```
XRC stack 0        := cap        (N=1, one layer)            — if present
XRC stacks 1..k    := stacks reversed (surface-most first)   — each with its N
XRC stack k+1      := buffer     (N=1, one layer)            — if present
Subs               := substrate
```

The GUI data string (`{"Stacks":[{"T":..,"N":..,"Layers":[{"M","H","HP","Hmin","Hmax","ProfileH",
"s","SP","Smin","Smax","ProfileS","r","RP","Rmin","Rmax","ProfileR"}]}],"Subs":{"M","s","r"}}`) is
what `TXRCStructure.ToString` writes and `FromString` reads; the server writes and reads exactly that
(see `unit_universal_io.SaveXRCStructure` for the field set).

`density` omitted → `r = 0`, which makes `TLayeredModel.PrepareLayers` use the Henke bulk density
(`FLayers[i].ro = 0` branch). The value used is echoed by reading `Nro` from the table.

Material names are Henke table base names (case-insensitive, e.g. `Ru`, `C`, `B4C`, `SiO2`,
`RuB2`). **No composition-mixing string syntax exists in the code base** (nothing parses
`"W0.7Si0.3"`); the server documents this in `describe_server.material_syntax` and refuses unknown
names with a structured error. Open question for the author.

## 4. Fit parameters that the GUI engine does not have

The GUI's LFPSO fits per-layer thickness, σ and density of the stack layers only. The substrate is
not part of the particle vector (`TLFPSO_BASE.FillModel` copies `FStructure.Subs.P` verbatim;
`Set_Init_X` is called for stack layers only), and there are no scale, background or resolution
parameters (resolution is the fixed convolution width `TCalcThreadParams.DT`; data are normalised by
hand in the GUI). `fit_xrr` therefore:

- accepts `free` entries `{"target":"layer","stack":k,"layer":j,"parameters":[thickness|sigma|density]}`;
- accepts a fixed `resolution` (θ FWHM, degrees) and echoes it;
- rejects `target=substrate`, `scale`, `background` and `resolution` inside `free` with error code
  `not_fittable`, message naming the reason (v1 uses the GUI's parameter set). Open question for the author.

χ² is exactly `TCalc.CalcChiSquare(ThetaWeight)` with the GUI defaults (`PWChi = true`,
`MovAvgWindow = 0.05`, `TWChi = 0`); both knobs are exposed (`chi2.theta_weight` 0..5,
`chi2.point_weight` bool) and echoed with the residual definition string.

## 5. Jobs, threads, determinism

- One background worker thread (`TThread`), one job running at a time, FIFO queue of at most 16.
  Reasons: `System.RandSeed` is process-global, so two seeded jobs at once would not be
  reproducible; both engines already use every core through OmniThreadLibrary `Parallel.For`;
  `TMaterialMixer.Initialize` changes the CWD.
- `seed`: `RandSeed := seed` immediately before `Run`. `TLFPSO_BASE.Run` calls `Randomize`; it gets a
  `Seed` property (`-1` = keep `Randomize`, the GUI behaviour). `TUniversalOptimizer.Run` does not
  call `Randomize`. When `seed` is omitted the server draws one from `Random(MaxInt)` after
  `Randomize` and echoes it.
- Progress: `TLFPSO_BASE` posts `WM_CHI_UPDATE` to `Application.MainFormHandle`, which is 0 in a
  console; each post would leak a `TLayeredModel`. It gets an optional `OnProgress` callback
  (`procedure(const Msg: TUpdateFitProgressMsg) of object`); when assigned it is called on the
  fitting thread instead of posting, and the callee owns `Msg.LayeredModel`. GUI behaviour is
  unchanged when the callback is nil.
- `TUniversalOptimizer` frees its PSO inside `Run`; it gets a `FinalState: TOptState` property
  captured before that, so the server can rank the population for `top_k`.
- Job folders `jobs\<job_id>\` (ids `fit-YYYYMMDD-HHMMSS-<4 hex>`, `opt-…`, `calc-…`); `job.json`
  is rewritten on every progress event. The job registry is in memory: after a restart every id is
  `unknown`, as required.

## 6. `.xrcx` writing

`.xrcx` is a zip (the GUI uses Abbrevia; the server uses `System.Zip`, which Abbrevia reads) with
`params.dsc` (INI, keys as `TfrmCalcSettings.SaveToINI`/`SaveAdvancedParams` and
`TfrmChartInfo.SaveToINI`, `[INFO] Version=7`), `project.dsc` (VirtualTreeView stream written by
`TXRCProjectTree`), `calc.dat` and `data_<id>.dat` (tab-separated, header lines as `SeriesToText`).

`project.dsc` is written by instantiating `TXRCProjectTree` **headless** (`Create(nil, 96)`,
`NodeDataSize := SizeOf(TProjectData)`, `AddChild`, `SaveToFile`) — the same class and the same
`ProjectSaveNode` as the GUI, so the bytes are the GUI's bytes. Reading uses `LoadFromFile` on the
same class. If headless construction turns out to be impossible in a console process, the fallback
is the byte layout documented in the plan (Appendix A), verified against
`D:\APS\ELN\ELN3Plugins\TestFiles\Hard.xrcx`.

Angles in `params.dsc` are written as θ (`[ANGLE] 2teta=0`), so the GUI shows the same axis the
server used.

## 7. Sandbox and journal

- `--workdir <abs path>` is mandatory; the directory is created with `projects\ jobs\ inbox\ log\`.
- Every path argument is relative; `ResolvePath` rejects rooted paths, drive letters, UNC, `..`
  segments, and anything whose expanded form is not under the work directory. Error code
  `path_outside_workdir`.
- `inbox\` is read-only by construction: no tool has a write path into it, and `ResolvePath` is
  called with a `write` flag that refuses `inbox\`.
- `log\calls.jsonl`: one line per `tools/call`, `{ts, tool, args, result | error, ms}`. Any JSON
  array with more than 64 numeric elements (or nested such) is replaced by
  `{"_len": n, "_sha256": "<hex of the file the tool wrote>"}` (or `_len` only when there is no
  file). Opened in append mode for each write, never truncated.

## 8. Open questions for the author (do not guess — sent back)

1. Acceptance 4 references `xrccmd -a`, but §2.3/§4.4 require the GUI LFPSO and χ². The server
   implements the GUI engine; the comparison target for acceptance 4 should be a GUI fit.
2. No composition-mixing material syntax exists (`"W0.7Si0.3"`); v1 accepts Henke table names only.
3. `scale`, `background`, free `resolution` and the substrate σ/ρ are not parameters of the GUI's
   LFPSO; v1 rejects them in `free`.
4. Henke "source and date": the tables are `.bin` conversions with no embedded provenance; the
   server reports path, count and newest file time. Please supply the source statement to embed.
5. Energy conversion: the server converts `energy` with 12398.42 (§2.4); the engines interpolate
   Henke tables at `E = 12398.6/λ` internally (`math_globals.H`). Both constants are reported in
   `describe_server.units`; nothing in the engines is changed.
6. OmniThreadLibrary in the shared library path (`D:\DelphiProjects\_Libraries\OmniThreadLibrary\OtlTaskControl.pas`
   lines 2621–2628) casts code pointers to `Cardinal`; under dcc64 `Parallel.ForEach` (used by
   `TCalc.RunThetaThreads`) crashes the pool manager with an access violation and the caller waits
   forever. The server therefore runs `TCalc` single-threaded (`MaxThreads := 1`, ~74 ms per
   2000-point scan). The fix is `Cardinal` → `NativeUInt` on those four lines (upstream OTL has it);
   it is the author's call because the file is outside this repository and shared by the GUI,
   xrccmd and XRFCalc. **Status 2026-09-09:** the Task 11 implementer applied exactly this fix to the
   library (backup `OtlTaskControl.pas.xrcmcp-backup`) because `TUniversalOptimizer.Run`
   (`Parallel.For`) hangs forever on Win64 without it, `xrccmd -u` included. `optimize_mirror`
   therefore depends on the patched library; keep or revert is the author's decision (recorded in
   `CLAUDE.md` Dependencies). On the GUI binary: Task 14 reported that its Win64 regression build
   had replaced `_Out\BIN\XRayCalc3.exe` with a Win64 one, but that is not what happened — the
   Win64 Release configuration of `XRayCalc3.dproj` sets `OutputExt = x64.exe`, so the Win64 GUI
   is `_Out\BIN\XRayCalc3.x64.exe` and `_Out\BIN\XRayCalc3.exe` is untouched and still the Win32
   build. Both GUI platforms, xrccmd and XRFCalc reach the same `Parallel.ForEach` in
   `unit_calc`/`cmd_unit_calc`, so the OTL question above applies to every Win64 binary.

7. **The substrate, the scale, the background and the resolution cannot be fitted.** None of them is
   in the LFPSO particle vector: `TLFPSO_BASE.FillModel` copies `Subs.P` verbatim into the model,
   and the engine has no scale or background term at all. `fit_xrr` therefore refuses those four
   `target` values with `not_fittable` rather than accepting them and quietly holding them still.
   Every fit result carries `scale 1.0`, `background 0.0` and a note saying so. If the author wants
   them fitted, the engine has to change, not the server.

8. **`.xrcx` is written through the real `TXRCProjectTree`, and that costs a `MainThreadID` swap.**
   The tree is a VCL control; building it headless reaches `CheckSynchronize`, which raises on any
   thread other than the one `System.MainThreadID` names. `unit_MCPProjectFile.TTreeScope` takes a
   process-wide lock and sets `MainThreadID` to the writing thread for the length of
   Create/SaveToFile/Free. It is safe only because this process has no message loop and never calls
   `TThread.Synchronize` or `Queue`, so the queue it drains is always empty; the day either becomes
   untrue the swap turns into a live deadlock. Please bless this, or ask for the Appendix A byte
   writer instead. Related GUI fix made along the way:
   `unit_XRCProjectTree.ProjectLoadNode` did not zero-terminate its string buffer (commit `6a9bf8c`,
   behaviour-preserving).

9. **Curve files inside `.xrcx` now carry 7 significant digits.** The GUI's own `SeriesToText`
   writes θ with 3 decimals; on a 0.0025° grid that is 40 % of a step, and a fit reloaded into the
   GUI re-scored at χ² 6.5e-3 where the job had reported 6e-5, because the intensities belong to
   the unrounded angles. Both columns are now written at 7 significant digits — everything a
   `Single` holds — and the GUI reads them without complaint. Not changed, and pre-existing: the
   GUI's `SeriesFromText` parses with the thread locale, so on a comma-decimal machine it drops
   points from any file written with a '.' decimal mark.

10. **`TLFPSO_Poly.GetPolynomes` mis-indexes multi-stack profiles.** It advances its base index by
    `Stacks[i].N` instead of by the layer count of the stack, so the coefficients it hands back are
    only correct when exactly one stack repeats. Rather than patch the shared engine, `fit_xrr`
    enforces the condition: `profile: true` requires exactly one stack with `N > 1` and is refused
    otherwise. The engine bug is still there for the GUI.

11. **Cancellation granularity.** `optimize_mirror` and `fit_xrr` observe a cancel once per
    iteration, inside the optimizer's progress callback; the prologue (Henke tables, model build)
    and the packaging tail are not interruptible, so a cancel costs up to one iteration plus the
    tail. The smoke session sees a cancelled `optimize_mirror` settle within about a second.
    `evaluate_lines` is synchronous and there is one job worker, so an `evaluate_lines` call issued
    while a job is running waits for its turn.

12. **Three v1 restrictions worth confirming.** (a) `optimize_mirror` refuses
    `structure.pure_elements = false`: the §3 structure JSON has no mixing syntax, so a mixed genome
    could not be written back as a structure that reproduces its own FoM. (b) `calc_reflectivity`
    runs its `TCalc` with `MaxThreads = 1` (see item 6). (c) `save_project` and `fit_xrr` store the
    densities the engine actually used, which for the substrate is always the Henke bulk value —
    the engine ignores a user-supplied substrate density.

13. **XRFCalc seed comparison: not done, and not doable as things stand.** Task 11 verified
    determinism server-side only — two `optimize_mirror` runs of the same configuration with the
    same seed agree in every reported digit, and the reported FoM matches what `evaluate_lines`
    computes for the reported structure. It did **not** compare against XRFCalc. Its report states
    why: XRFCalc and `xrccmd` have no seed switch, so they cannot be asked to reproduce a server
    run. The server's number for the Task 11 configuration with seed 12345 is
    `fom = -1.32790446281433` (Sc/B4C, d = 33.9807167053223 Å, γ = 0.397049427032471, N = 56); to
    compare, XRFCalc/xrccmd need `RandSeed := <seed>` immediately before `TUniversalOptimizer.Run`.

14. **`_Installer\XRayCalc3Setup.iss` was not modified.** Shipping `XRC_MCP.exe` in the installer is
    out of scope for this plan; the server is registered from wherever it is built (see the
    `claude mcp add` line in `CLAUDE.md`). Say the word and the InnoSetup script gets a Files entry.
