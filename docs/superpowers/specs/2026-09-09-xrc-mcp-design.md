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
