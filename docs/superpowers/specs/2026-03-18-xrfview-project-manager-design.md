# XRFView Project Manager — Design Spec

## Summary

Convert XRFView from a passive `.xrfx` result viewer into an active project manager for universal mirror optimization. Users configure runs via a dialog, launch `xrccmd` from within the app with live stdout monitoring, and view results — all without leaving XRFView.

## Current State

- **XRFView**: Standalone Win64 Delphi VCL app (~985 lines). Browses `.xrfx` files via shell browser, displays results in 5 tabs (Structure, Curves, Info, Progress, Compare).
- **xrccmd**: Console app (`{$APPTYPE CONSOLE}`) with `-u config.json` mode for universal mirror optimization. Writes per-iteration lines to stdout (gated on `IsConsole`, which is a compile-time constant — always `True` for console apps regardless of pipe redirection). Produces `.xrfx` output at `ChangeFileExt(ConfigFile, '.xrfx')`. Errors go to stderr.
- **Workflow gap**: Users must hand-edit JSON configs, run xrccmd from a terminal, then open XRFView separately.

## Design Goals

1. **Configure** — GUI dialog for all optimization parameters (no hand-editing JSON)
2. **Launch** — Spawn xrccmd as a child process from within XRFView
3. **Monitor** — Live stdout capture with real-time Progress chart updates
4. **View** — Auto-load results when complete (existing tabs)
5. **Iterate** — Edit config from an existing `.xrfx`, re-run, overwrite results

## User Workflows

### New Run

```
User clicks "New Run" toolbar button
  -> TfrmRunConfig dialog opens with defaults
  -> User configures parameters, clicks "Run"
  -> Dialog writes config JSON to: <current_folder>/<timestamp>.json
  -> Config sets output_dir to a temp subfolder for intermediate files
  -> Dialog closes
  -> Main form spawns: xrccmd.exe -u <config.json>  (no -v flag)
  -> Progress tab goes live (chart + stdout log)
  -> On completion:
     - xrccmd produces <current_folder>/<timestamp>.xrfx
     - Temp .json config and output_dir subfolder deleted
     - Shell list refreshes, auto-selects new .xrfx
     - All tabs reload with new results
```

### Edit Run

```
User selects existing .xrfx, clicks "Edit Run"
  -> Loader extracts config.json from .xrfx to temp dir
  -> TfrmRunConfig dialog opens, populated from extracted config
  -> User modifies parameters, clicks "Run"
  -> Dialog writes config JSON to: <original_folder>/<original_basename>.json
  -> Config sets output_dir to a temp subfolder for intermediate files
  -> Dialog closes
  -> Main form spawns: xrccmd.exe -u <config.json>  (no -v flag)
  -> Progress tab goes live
  -> On completion:
     - xrccmd produces .xrfx overwriting the original
     - Temp .json config and output_dir subfolder deleted
     - All tabs reload with updated results
```

### Save Config Only

From the config dialog, "Save Config" writes the JSON without launching a run. For preparing configs to run later or on another machine.

## Architecture

### New Files

| File | Purpose |
|------|---------|
| `XRFView/Forms/frm_RunConfig.pas + .dfm` | Configuration dialog (modal) |
| `XRFView/Units/xrfview_unit_runner.pas` | Process management: CreateProcess, pipe reading, stdout parsing |

### Modified Files

| File | Change |
|------|--------|
| `XRFView/Forms/frm_XRFViewMain.pas + .dfm` | 3 toolbar buttons (New Run, Edit Run, Stop), run state, auto-reload |
| `XRFView/Views/frame_ProgressView.pas + .dfm` | Add TMemo log below chart, dual-mode (static/live) |
| `XRFView/XRFView.dpr` | Add new units to uses clause |
| `XRFView/XRFView.dproj` | Add new files to project |
| `XRFView/XRFViewIcons.rc` | Add icons for New Run, Edit Run, Stop |

### No Changes to xrccmd

The `.xrfx` output path is determined by `ChangeFileExt(ConfigFile, '.xrfx')`, so XRFView controls the output location by choosing where to write the config file. No xrccmd modifications needed.

**Why no `-v` flag:** The `-v` (verbose) flag triggers a `Readln` prompt at program exit ("Press Enter to close") which would hang indefinitely when xrccmd is spawned as a child process with piped I/O. All iteration data flows to stdout without `-v` — the `LogIteration` method gates on `IsConsole` (compile-time `True` for console apps), not on verbose mode. The only output lost without `-v` is shake/checkpoint informational messages, which are non-essential.

## Component Design

### TfrmRunConfig (Config Dialog)

Modal dialog, approximately 550x500 px.

**Tier 1 — Always visible:**

| Control | Type | JSON field |
|---------|------|------------|
| Target Lines | TRzCheckListBox | `lines` |
| Element Pool | TRzCheckListBox | `element_pool` |
| d min / d max | TSpinEdit pair | `structure.d.min`, `structure.d.max` |
| Gamma min / Gamma max | TSpinEdit pair | `structure.gamma.min`, `structure.gamma.max` |
| N min / N max | TSpinEdit pair | `structure.N.min`, `structure.N.max` |
| Population | TSpinEdit | `optimizer.population` |
| Iterations | TSpinEdit | `optimizer.iterations` |
| Stagnation limit | TSpinEdit | `optimizer.stagnation_limit` |
| Template file | TEdit + TButton (browse) | `template_file` |

**Tier 2/3 — Collapsible "Advanced" TRzGroupBar or TGroupBox:**

| Control | Type | JSON field |
|---------|------|------------|
| w_R | TEdit (float) | `fitness.w_R` |
| w_FWHM | TEdit (float) | `fitness.w_FWHM` |
| w_purity | TEdit (float) | `fitness.w_purity` |
| R_min threshold | TEdit (float) | `fitness.R_min_threshold` |
| Delta theta | TEdit (float) | `fitness.delta_theta` |
| Theta min | TEdit (float) | `fitness.theta_min` |
| Polarization | TComboBox (s, sp) | `fitness.polarization` |
| Sigma | TEdit (float) | `structure.sigma` |
| Substrate | TEdit | `substrate` |
| Pure elements | TCheckBox | `structure.pure_elements` |
| Density factor | TEdit (float, single value) | `structure.density_factor` |
| Excluded pairs | TRzCheckListBox (auto-populated from pool) | `excluded_pairs` |
| PSO w1 | TEdit (float) | `optimizer.w1` |
| PSO w2 | TEdit (float) | `optimizer.w2` |
| Tolerance | TEdit (float) | `optimizer.tolerance` |
| Jamming max | TSpinEdit | `optimizer.jamming_max` |
| Checkpoint every | TSpinEdit | `optimizer.checkpoint_every` |
| Henke path | TEdit + TButton | `henke_path` |

**Hardcoded (not in dialog):** `structure.type` = "bilayer", `structure.layers_per_period` = 2, `resume_from` = null. The `output_dir` is set automatically to a temp subfolder at runtime.

**Bottom buttons:** `Run` | `Save Config` | `Cancel`

**Methods:**
- `LoadFromConfig(const Config: TUniversalConfig)` — populate controls from parsed config
- `BuildConfig: TUniversalConfig` — read controls into config record
- `SetDefaults` — hardcoded default values for New Run

Config I/O uses the existing `TUniversalIO.LoadConfig` and `TUniversalIO.SaveConfig` methods from `unit_universal_io.pas`. The dialog works with `TUniversalConfig` records, not raw JSON.

### TXRCRunner (Process Runner)

Lives in `xrfview_unit_runner.pas`. Manages the xrccmd child process.

```
TRunnerState = (rsIdle, rsRunning, rsCompleted, rsFailed, rsCancelled);

TIterationData = record
  Iteration: Integer;
  FoM: Double;
  ElementR: TArray<Double>;
  Diversity: Double;
  BestInfo: string;
  ElapsedSec: Double;
end;

TXRCRunner = class
private
  FState: TRunnerState;
  FProcessHandle: THandle;
  FReadPipe: THandle;
  FConfigPath: string;
  FOutputPath: string;        // expected .xrfx path
  FBuffer: string;            // partial line buffer
  FOnIteration: TProc<TIterationData>;
  FOnCompleted: TProc<string>;  // .xrfx path
  FOnError: TProc<string>;      // error message
  FOnRawLine: TProc<string>;    // raw stdout line
  procedure ParseLine(const Line: string);
  procedure ReadPipeData;
public
  constructor Create;
  destructor Destroy; override;
  procedure Start(const ConfigPath: string);
  procedure Cancel;
  procedure Poll;  // called by TTimer, reads pipe + checks process status
  property State: TRunnerState read FState;
  property OutputPath: string read FOutputPath;
end;
```

**Process spawning:**
- Uses `CreateProcess` WinAPI with `STARTUPINFO` redirecting both stdout and stderr to the same anonymous pipe (so error messages are captured alongside normal output)
- xrccmd path: looks in `ExtractFilePath(Application.ExeName)` first (production deployment), then falls back to `..\..\XRC_CMD\Out\CMDBin\` (development layout). Configurable as a last resort.
- Command: `xrccmd.exe -u "<ConfigPath>"` (no `-v` flag — see rationale above)

**Pipe reading (Poll method):**
- Called every 100ms by a TTimer on the main form
- Reads available bytes from pipe into FBuffer
- Splits on line endings, calls ParseLine for each complete line
- Fires FOnRawLine for every line (feeds TMemo)
- ParseLine detects iteration data lines (starts with digits after whitespace) and fires FOnIteration

**Stdout format from xrccmd (for parsing):**

Format strings from source (`unit_universal_io.pas` and `cmd_unit_universal.pas`):
- Header: `Format('%5s  %8s', ['Iter', 'FoM'])` + per-line `Format('  %5s', ['R_' + Name])` + `Format('  %5s  %-18s  %8s', ['Div', 'Best', 'Time'])`
- Iteration: `Format('%5d  %8.4f', [Iter, FoM])` + per-line `Format('  %5.3f', [RPeak])` + `Format('  %5.3f  %-18s  %4d:%02d', [Div, BestInfo, Min, Sec])`

```
Universal Mirror Optimizer v1.0
Lines: Na(11.9A) Mg(9.9A) Al(8.3A) Si(7.1A)
Pool: W Mo Cr Si B B4C
Structure: bilayer, d=[30..80], N=[40..200]
Mode: pure elements (no mixing)
Population: 1000, Max iterations: 100
---
 Iter       FoM  R_Na  R_Mg  R_Al  R_Si    Div  Best                  Time
    0    0.9746  0.325  0.373  0.394  0.300  0.290  W/B d=49.8            0:02
    1    1.0231  0.380  0.410  0.420  0.340  0.260  W/B d=52.3            0:04
Converged at iteration 50 (stagnation limit reached)
---
Optimization complete.
Best FoM: 1.1449
Period d=67.61 A, gamma=0.202, N=40, sigma=3.50 A
Layer 1: W=100.0%
Layer 2: B=100.0%
Package saved: /path/to/output.xrfx
Done.
```

Note: Iterations start at 0. The "Best" column is 18 chars wide and may contain extra info like "d=49.8". The "Done." line comes from `xrccmd.dpr` after the universal mirror procedure returns.

**Parsing rules:**
- Lines matching `^\s*\d+\s+[\d.]+` → iteration data, split by whitespace. Column count is variable (depends on number of target lines). FoM is always column 2.
- Lines matching `Package saved:` → extract .xrfx path, set state to rsCompleted
- Lines matching `^Error:` or containing exception messages (from stderr, merged into same pipe) → capture message, set state to rsFailed
- Lines matching `Converged at iteration` → extract iteration number, pass to log
- All other lines (banner, "---", "Done.", completion summary) → raw log only

**Cancellation:**
- `TerminateProcess(FProcessHandle, 1)` — kills xrccmd
- Sets state to rsCancelled
- Cleanup: close pipe handles

**Completion detection:**
- Poll checks `WaitForSingleObject(FProcessHandle, 0)` for process exit
- On exit code 0 + "Package saved" seen → rsCompleted, fire OnCompleted with .xrfx path
- On exit code != 0 → rsFailed

### Main Form Changes (frm_XRFViewMain)

**New fields:**
```pascal
FRunner: TXRCRunner;
FRunTimer: TTimer;
FRunStartTime: TDateTime;
btnNewRun: TToolButton;
btnEditRun: TToolButton;
btnStop: TToolButton;
```

**Toolbar:**
- 3 new buttons added after existing 4: New Run, Edit Run, separator, Stop
- Stop is only visible when FRunner.State = rsRunning
- Edit Run is only enabled when a single .xrfx is selected in shell list

**Run state management:**
- `FRunTimer.OnTimer` calls `FRunner.Poll`
- While running: disable New Run, Edit Run; show Stop; status bar shows "Running... Iteration X/N | FoM: X.XXXX | MM:SS elapsed"
- FRunner.OnIteration → update Progress tab chart + status bar
- FRunner.OnRawLine → append to Progress tab memo
- FRunner.OnCompleted → stop timer, refresh shell list, select output .xrfx, load into all tabs, status bar shows FoM + filename
- FRunner.OnError → stop timer, show error in status bar, keep log visible

**Auto-reload on completion:**
```
FRunner.OnCompleted fires
  -> FRunTimer.Enabled := False
  -> Delete temp config .json
  -> ShellList.Refresh
  -> Select FRunner.OutputPath in shell list
  -> ProcessFile(FRunner.OutputPath)  // existing method, loads all tabs
  -> StatusBar shows "Complete: FoM X.XXXX | filename.xrfx"
```

### Progress Tab Changes (frame_ProgressView)

**Current layout:** TChart only.

**New layout:**
```
+-----------------------------------+
|  TChart (FoM vs Iteration)        |
|  - Static mode: loaded from .xrfx |
|  - Live mode: updated per iter    |
+-----------------------------------+  <- TRzSplitter (horizontal)
|  TMemo (stdout log, read-only)    |
|  - Static: shows progress.log     |
|  - Live: appended per stdout line  |
+-----------------------------------+
```

**New fields:**
```pascal
Splitter: TRzSplitter;
MemoLog: TMemo;
```

**New methods:**
```pascal
procedure SetLiveMode;     // clear chart + memo, prepare for live updates
procedure SetStaticMode;   // restore from loaded data
procedure AddIteration(const Data: TIterationData);  // live: add point to chart
procedure AppendLog(const Line: string);              // live: add line to memo
```

**Static mode** (viewing a completed .xrfx):
- Chart loaded from progress data (existing behavior)
- Memo loaded from progress.log text inside the .xrfx package

**Live mode** (during a run):
- Chart starts empty, points added via AddIteration
- Memo starts empty, lines appended via AppendLog, auto-scrolls to bottom
- Chart auto-scales X axis as iterations come in

## Config JSON Handling

XRFView reads/writes the same `universal_mirror.json` format that xrccmd expects. No new format.

**Default values for New Run (hardcoded in TfrmRunConfig.SetDefaults):**
```json
{
  "lines": ["Na-Si"],
  "element_pool": ["W", "Mo", "Cr", "Si", "B", "B4C", "Sc", "C"],
  "excluded_pairs": [],
  "structure": {
    "type": "bilayer",
    "layers_per_period": 2,
    "pure_elements": true,
    "d": {"min": 30, "max": 80},
    "gamma": {"min": 0.15, "max": 0.7},
    "N": {"min": 40, "max": 200},
    "sigma": 3.5,
    "density_factor": 0.95
  },
  "fitness": {
    "w_R": 1.0,
    "w_FWHM": 0.1,
    "w_purity": 1.0,
    "R_min_threshold": 0.001,
    "delta_theta": 0,
    "theta_min": 0,
    "polarization": "sp"
  },
  "optimizer": {
    "population": 1000,
    "iterations": 100,
    "tolerance": 1e-5,
    "stagnation_limit": 200,
    "w1": 0.4,
    "w2": 0.5,
    "jamming_max": 5,
    "checkpoint_every": 100
  },
  "substrate": "SiO2",
  "henke_path": "D:\\DelphiProjects\\X-RayCalc\\Henke",
  "output_dir": "",
  "resume_from": null,
  "template_file": null
}
```

All fields shown above are required by `TUniversalIO.LoadConfig` (fields like `w1`, `w2`, `tolerance`, `checkpoint_every` are read unconditionally without null guards). The `output_dir` is set at runtime to a temp subfolder. The `template_file` and `henke_path` are set from dialog selections. The `henke_path` default can be read from `xrccmd.ini` if it exists alongside the executable.

## xrccmd Executable Location

**Development:** XRFView builds to `XRFView/_Out/BIN/`, xrccmd builds to `XRC_CMD/Out/CMDBin/` — different directories. The runner looks in its own directory first, then falls back to `..\..\XRC_CMD\Out\CMDBin\` relative to the exe.

**Production:** Both executables are deployed to the same directory (installer copies them together). The same-directory lookup works directly.

If xrccmd.exe is not found in either location, show an error dialog on New/Edit Run click.

## Temp File Cleanup

- Config `.json` files written for runs are deleted after completion (success or failure)
- xrccmd's `output_dir` intermediate files (curves, logs, checkpoint) are cleaned up by xrccmd itself — they get packaged into the `.xrfx`
- If XRFView is closed while a run is in progress, `TerminateProcess` is called in `FormDestroy`, and any temp files are cleaned up

## Error Handling

| Scenario | Behavior |
|----------|----------|
| xrccmd.exe not found | Error dialog on New/Edit Run click |
| xrccmd exits with error | Status bar shows error, log preserved in Progress memo |
| User closes XRFView during run | TerminateProcess, cleanup temp files |
| Invalid config values | Validation in dialog before enabling Run button |
| .xrfx has no config.json inside | Edit Run button stays disabled, show message |

## Scope Exclusions

- No batch/queue system — one run at a time
- No xrccmd source modifications — we avoid `-v` flag to sidestep the `Readln` hang
- No new file formats — uses existing `.xrfx` and `universal_mirror.json`
- No changes to other tabs (Structure, Curves, Info, Compare)
- No changes to the shell browser behavior
