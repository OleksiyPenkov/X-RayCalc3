# XRFCalc - Universal Mirror GUI Application

## Overview

XRFCalc is a standalone Delphi VCL application for multi-target X-ray multilayer mirror optimization. It shares the calculation engine with XRayCalc3 and xrccmd, but has its own focused GUI for configuring, running, monitoring, and analyzing universal mirror optimizations.

**Project location:** `XRFCalc/` at the repo root, added to `XRC3.groupproj`.

## Architecture

- **In-process optimization** — the PSO/fitness engine runs in a background thread within the app, giving direct access to population state for live chart updates
- **Shared engine** — universal mirror engine units extracted from `XRC_CMD/units/` into a shared `Universal/` directory so both xrccmd and XRFCalc compile against the same code
- **JSON config interop** — reads/writes the same JSON format as xrccmd, so configs are interchangeable between GUI and CLI
- **Single main form** with left sidebar (config) and right chart area (3 live charts)

## Main Form Layout

### Left Sidebar (~280px)

Scrollable config panel with sections:

1. **Targets** — checkbox grid of elements (B, C, N, O, F, Ne, Na, Mg, Al, Si) with K-alpha wavelengths auto-filled. Each checked element gets an editable weight column (default 1.0).

2. **Element Pool** — checkbox list of available materials for the optimizer: W, Mo, V, Si, C, B, Ni, Ti, B4C, SiC, SiN, etc.

3. **Structure** — labeled edits for: d range (min/max), gamma range (min/max), N range (min/max), sigma (fixed value), density factor range (min/max). Structure type selector (bilayer only — hardcoded `LAYERS_PER_PERIOD = 2`, no need for runtime selector). "Pure elements" checkbox.

4. **Fitness** — edits for: w_R, w_FWHM, R_min_threshold, theta_min, delta_theta. Polarization selector (s, sp) — matches existing `TPolarisation` enum values `cmS` and `cmSP`. No standalone p-only mode exists in the engine. **Note:** The existing `TFitnessConfig` has no `Polarization` field and the engine hardcodes `cmSP`. During extraction, add `Polarization: TPolarisation` to `TFitnessConfig`, parse it from the JSON config's existing `"polarization"` field (currently ignored by `LoadConfig`), and use it in the fitness evaluation instead of the hardcoded value.

5. **Optimizer** — edits for: population, iterations, tolerance, stagnation_limit, w1, w2, jamming_max, checkpoint_every.

6. **Substrate** — combo/edit for substrate material name.

7. **Paths** — Henke database path (defaults to `ExtractFilePath(Application.ExeName) + 'Henke'`, editable with folder browser). Output directory (defaults to `results/` next to config file, editable).

8. **Control buttons** — Start, Stop, Load Config, Save Config. Progress indicator (iteration X of Y).

### Right Area — Three Chart Panels

- **Top:** FoM convergence line chart (iteration vs FoM)
- **Bottom-left:** Per-element R_peak bar chart
- **Bottom-right:** Reflectivity curves (angle vs reflectivity, one series per target element, log Y scale, toggleable)

### Post-Run Results

The sidebar shows a results summary below the control buttons (config sections remain visible/editable above):
- Best materials (e.g., "Ni / C"), d, gamma, N, sigma values
- Per-element table: Element | R_peak | FWHM

## Engine Refactoring

### Units to Extract

Move from `XRC_CMD/units/` to new `Universal/` directory:

| Current | New | Contents |
|---------|-----|----------|
| `cmd_unit_universal_types.pas` | `unit_universal_types.pas` | TGenome, TUniversalConfig, TFitnessConfig, etc. |
| `cmd_unit_universal_pso.pas` | `unit_universal_pso.pas` | TUniversalPSO |
| `cmd_unit_universal_fitness.pas` | `unit_universal_fitness.pas` | TUniversalFitness, TMaterialMixer |
| `cmd_unit_universal_io.pas` | `unit_universal_io.pas` | Checkpoint/population save/load, best_structure export |
| `cmd_unit_universal.pas` | `unit_universal_optimizer.pas` | TUniversalOptimizer (refactored from cmdUniversalMirror procedure) |

### Dependency Chain

The existing CLI units have cross-cutting dependencies that must be resolved:

- `cmd_unit_universal_fitness.pas` depends on `cmd_unit_calc.TCalc` (in `XRC_CMD/units/`, not `Math/unit_calc`)
- `cmd_unit_universal_fitness.pas` depends on `cmd_unit_types` and `cmd_math_globals` (CLI-specific units)
- `cmd_unit_calc.pas` depends on OmniThreadLibrary (`OtlParallel`, `OtlCollections`, etc.) and `cmd_unit_materials.pas` (`TLayeredModel`)
- `Math/unit_materials_mix.pas` depends on `cmd_math_globals`
- `math_complex` unit is used by `cmd_unit_types`, `cmd_unit_calc`, `cmd_unit_universal_fitness`, and `cmd_math_globals` — already lives in `Math/` (shared)

**Key insight:** The fitness engine only uses `TCalc.RefCalc(theta, lambda, layers)` — a single static-like method for Fresnel/Parratt reflectivity calculation. The full `cmd_unit_calc` unit brings in OmniThreadLibrary and `TLayeredModel` which are not needed.

**Resolution:** Extract a minimal `unit_universal_refcalc.pas` containing only the `RefCalc` function (Fresnel matrix method) with no OmniThreadLibrary dependency. This eliminates the heaviest transitive dependency. The remaining CLI units (`cmd_unit_types` for layer record types, `cmd_math_globals` for Henke data globals) must also be extracted to `Universal/`. The `cmd_unit_materials.pas` dependency is avoided entirely since `RefCalc` takes raw layer arrays, not `TLayeredModel`.

### TUniversalOptimizer Interface

```pascal
type
  TIterationData = record
    Iteration: Integer;
    MaxIterations: Integer;
    FoM: Double;
    PerElement: array of record
      Element: string;
      RPeak: Double;
      FWHM: Double;
    end;
    Diversity: Double;
    BestGenome: TGenome;
  end;

  TCurveData = record
    Element: string;
    Theta: TArray<Double>;    // angle array
    Refl: TArray<Double>;     // reflectivity array
  end;

  TIterationEvent = procedure(const Data: TIterationData) of object;
  TCompletionEvent = procedure(const Data: TIterationData;
    const Curves: TArray<TCurveData>) of object;
  TErrorEvent = procedure(const ErrorMsg: string) of object;

  TUniversalOptimizer = class
  private
    FConfig: TUniversalConfig;
    FPSO: TUniversalPSO;
    FFitness: TUniversalFitness;
    FCancelled: Boolean;
    FOnIteration: TIterationEvent;
    FOnCompleted: TCompletionEvent;
    FOnError: TErrorEvent;
  public
    constructor Create(const AConfig: TUniversalConfig);
    destructor Destroy; override;
    procedure Run;           // blocking — call from thread
    procedure Cancel;        // thread-safe, sets FCancelled
    property OnIteration: TIterationEvent read FOnIteration write FOnIteration;
    property OnCompleted: TCompletionEvent read FOnCompleted write FOnCompleted;
    property OnError: TErrorEvent read FOnError write FOnError;
  end;
```

**Key design points:**
- `Run` is blocking — the caller (thread) calls it and it returns when done, cancelled, or errored
- `Cancel` is the only method called cross-thread; sets a Boolean checked each iteration
- `OnIteration` fires every iteration with summary stats (lightweight — no curve data)
- `OnCompleted` fires once at the end with full curve data for all targets
- `OnError` fires if an exception occurs during optimization
- The existing `TParallel.For` for population evaluation continues to work from the background thread (nested parallelism is supported by Delphi's thread pool)

### xrccmd Impact

The CLI keeps working — it `uses` the units from `Universal/` instead of its own `units/` directory. The `cmdUniversalMirror` procedure becomes a thin console wrapper:

```pascal
procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);
var
  Optimizer: TUniversalOptimizer;
begin
  Optimizer := TUniversalOptimizer.Create(LoadConfig(ConfigFile));
  try
    Optimizer.OnIteration := ConsoleIterationHandler;  // WriteLn per iteration
    Optimizer.OnCompleted := ConsoleCompletionHandler;  // final summary
    Optimizer.Run;
  finally
    Optimizer.Free;
  end;
end;
```

## Threading & Live Updates

### Background Thread

- Optimization runs in a `TThread` descendant (`TOptimizationThread`)
- The thread creates and owns `TUniversalOptimizer`, calls `Run`
- Event handlers are wired before `Run` is called

### Data Transfer to GUI

- `OnIteration` fires in the worker thread context. The handler captures iteration data into a local copy and posts it to the main thread via `TThread.Queue`.
- `TIterationData` contains summary stats only (FoM, per-element R_peak/FWHM, diversity) — lightweight, safe to copy.
- Full reflectivity curve data (`TCurveData` arrays) is only computed and transferred on `OnCompleted` — computing curves for all targets every iteration would be expensive.
- Charts update at most every ~200ms — a timestamp check in the queued handler skips redundant redraws.

### Start/Stop Flow

1. **Start** — validate config, create thread, disable config edits, show progress
2. **Running** — charts update live, Stop button enabled
3. **Stop** (user-initiated) — calls `Optimizer.Cancel`, thread finishes current iteration and exits cleanly
4. **Completed** (natural convergence or max iterations) — `OnCompleted` fires, GUI switches to results view with full curve data
5. **Error** — `OnError` fires, GUI shows error message, re-enables config editing
6. **Resume** — if checkpoint exists in output directory, Start offers to resume from it (same as CLI's `resume_from`)

### Chart Components

TChart (TeeChart) — already used in XRayCalc3. Three TChart instances:
- Line series for FoM convergence (appends one point per iteration)
- Bar series for per-element R_peak (redrawn each update)
- Multiple line series for reflectivity curves (populated only on completion, then interactive — zoom, pan, toggle elements)

## Results & Export

### Export Options

- **Save Structure JSON** — writes `best_structure.json` in same format as xrccmd
- **Save Curves** — writes per-element `.dat` files (angle, reflectivity)
- **Export to XRayCalc3** — writes `best_structure_xrc.json` and optionally launches XRayCalc3 with it via ImportStructure mechanism
- **Save Config** — saves current config as JSON

### File Handling

- Load/Save Config use standard open/save dialogs filtered to `*.json`
- Output directory configurable in Paths section, defaults to `results/` subfolder next to the config file
- Checkpoints written automatically during runs per `checkpoint_every` setting
- If a run is stopped, "Start" detects existing checkpoint and offers to resume

### Error Handling

- **Invalid config:** Validated before starting — missing targets, empty element pool, invalid ranges shown as message dialog, run not started
- **Missing Henke data:** Checked at startup of optimization, reported via `OnError` → message dialog
- **Runtime exceptions** (NaN, math errors): Caught in `TUniversalOptimizer.Run`, reported via `OnError` → message dialog, config re-enabled for editing

## Dependencies

### Actual Dependency Chain

- **XRC_CMD CLI units used by engine:** `cmd_unit_calc` (only `RefCalc` method needed), `cmd_unit_types` (layer record types), `cmd_math_globals` (Henke data globals)
- **Heavy transitive deps (to avoid):** `cmd_unit_calc` → OmniThreadLibrary, `cmd_unit_materials` (`TLayeredModel`) — not needed by universal mirror
- **Math/ units (shared, already accessible):** `math_complex` (complex number types, used throughout), `unit_materials_mix.pas` (TMaterialMixer — depends on `cmd_math_globals`)

### Summary

- **Extracted to Universal/:** unit_universal_types, unit_universal_pso, unit_universal_fitness, unit_universal_io, unit_universal_optimizer, unit_universal_refcalc (minimal RefCalc extraction from cmd_unit_calc), plus layer types and Henke globals from cmd_unit_types/cmd_math_globals
- **Shared from Math/ (no changes needed):** math_complex, unit_materials_mix (after its dependency on cmd_math_globals is redirected to the extracted globals unit)
- **VCL:** TChart (TeeChart), standard VCL controls
- **Third-party:** FastMath
- **NOT required:** OmniThreadLibrary (avoided by extracting only RefCalc)

## UI Style

Expert-friendly — all parameters visible in organized sidebar sections. No wizard or hidden settings. Target audience is physicists who understand the parameters.
