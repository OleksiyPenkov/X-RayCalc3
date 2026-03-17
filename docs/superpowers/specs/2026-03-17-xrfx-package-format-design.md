# .xrfx Package Format and XRFView Application

**Date:** 2026-03-17
**Status:** Draft

## Overview

Bundle universal mirror optimization results into a single `.xrfx` archive file (ZIP-based), and provide a standalone Delphi VCL viewer application (XRFView) for browsing, inspecting, and comparing results.

## Goals

- **Portability:** Single file instead of a results folder — easy to share and archive
- **Inspection:** Dedicated viewer with structure table, reflectivity curves, metadata, and progress charts
- **Comparison:** Open multiple .xrfx files side-by-side to compare optimization runs
- **Export:** Extract individual files (e.g., `best_structure_xrc.json` for use in XRayCalc3)

## .xrfx File Format

ZIP archive with the following internal layout:

```
manifest.json
config.json
best_structure.json
best_structure_xrc.json
population.json
progress.log
best_curves/
  <Element>.dat              (e.g., C.dat, Na.dat, Al.dat)
```

Note: the `best_curves/` directory name and `<Element>.dat` file naming matches the existing output convention in `unit_universal_io.pas:SaveCurve`. `checkpoint.json` is excluded — it is only useful for resuming optimization, not for viewing results.

### manifest.json

Index file read first by consumers. Contains metadata, summary, per-element peak data, and a file map.

```json
{
  "version": 1,
  "created": "2026-03-17T14:30:00",
  "generator": "xrccmd 3.x.x",
  "fom": 0.00342,
  "target_lines": ["C-Ka", "Na-Ka", "Al-Ka"],
  "element_pool": ["W", "Mo", "Si"],
  "substrate": "SiO2",
  "structure_summary": {
    "type": "bilayer",
    "d": 45.2,
    "gamma": 0.35,
    "N": 120,
    "sigma": 3.5
  },
  "optimizer": {
    "population": 500,
    "iterations": 1000,
    "stagnation_limit": 200
  },
  "per_element": [
    { "line": "C-Ka", "peak_R": 0.12, "fwhm": 0.45 },
    { "line": "Na-Ka", "peak_R": 0.08, "fwhm": 0.38 },
    { "line": "Al-Ka", "peak_R": 0.15, "fwhm": 0.52 }
  ],
  "files": {
    "config": "config.json",
    "best_structure": "best_structure.json",
    "best_structure_xrc": "best_structure_xrc.json",
    "population": "population.json",
    "progress": "progress.log",
    "curves": ["best_curves/C.dat", "best_curves/Na.dat", "best_curves/Al.dat"]
  }
}
```

The `files` map allows the viewer to discover archive contents without scanning, and gracefully handle archives where some files are absent (viewer should check for key existence before loading).

**Forward compatibility:** viewers should ignore unknown JSON fields. If `manifest.version` exceeds what the viewer supports, show a warning but attempt to load anyway.

### config.json

Copy of the original universal mirror config JSON that produced this result. Enables full reproducibility — a user can re-run the exact same optimization from the archived config.

### Existing files (unchanged)

- **best_structure.json** — generic optimizer result (FoM, d, gamma, N, sigma, per-layer composition, per-element reflectivity peaks and FWHM)
- **best_structure_xrc.json** — XRC GUI-compatible structure format (stacks, layers with M/H/s/r, fit parameters, substrate)
- **population.json** — top N particles from final population
- **progress.log** — iteration-by-iteration FoM progress. Space-delimited with a header line; column count varies with the number of target elements. See `LogIteration` in `unit_universal_io.pas` for format details.
- **best_curves/*.dat** — per-element reflectivity curves (2-column text: angle, reflectivity)

## xrccmd Changes

After the existing `SaveResults` call in universal mirror mode (`-u`):

1. Copy the input config JSON into the results directory as `config.json`
2. Generate `manifest.json` from `TUniversalConfig` + best genome data, write to results directory
3. ZIP the entire results directory (excluding `checkpoint.json`) into `<name>.xrfx`, placed next to the config file (or at a path given by `-o`)
4. The loose results folder is still produced (backward compatibility)

Uses `System.Zip` (built into Delphi RTL).

## Shared Unit: unit_xrfx_package.pas

Located in `Universal/`. Used by both xrccmd and XRFView.

### Types

```pascal
TXRFXStructureSummary = record
  StructureType: string;
  D, Gamma, Sigma: Double;
  N: Integer;
end;

TXRFXOptimizerInfo = record
  Population, Iterations, StagnationLimit: Integer;
end;

TXRFXElementResult = record
  Line: string;        // e.g. "C-Ka"
  PeakR: Double;
  FWHM: Double;
end;

TXRFXManifest = record
  Version: Integer;
  Created: string;
  Generator: string;
  FoM: Double;
  TargetLines: TArray<string>;
  ElementPool: TArray<string>;
  Substrate: string;
  Structure: TXRFXStructureSummary;
  Optimizer: TXRFXOptimizerInfo;
  PerElement: TArray<TXRFXElementResult>;
  CurveFiles: TArray<string>;
end;

TXRFXLayer = record
  Material: string;
  Thickness: Double;   // Angstroms
  Roughness: Double;   // Angstroms
  Density: Double;     // g/cm3
end;

TXRFXStructure = record
  Layers: TArray<TXRFXLayer>;
  Substrate: TXRFXLayer;
  StackN: Integer;     // number of periods
end;
```

Note: the existing `TCurveData` in `unit_universal_optimizer.pas` (Element, Theta, Refl fields) is reused for curve data — no new curve type is defined here.

### Procedures

```pascal
// xrccmd calls this after SaveResults
procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, OutputPath: string);

// XRFView calls these to load
procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
function  LoadManifest(const ManifestPath: string): TXRFXManifest;
function  LoadXRCStructure(const JsonPath: string): TXRFXStructure;
function  LoadCurveFiles(const CurvesDir: string): TArray<TCurveData>;
function  LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;
```

`CreateXRFXPackage` receives the config and best result data to build `manifest.json`, copies the config JSON as `config.json`, then ZIPs the directory contents (excluding `checkpoint.json`) into the output .xrfx file.

`LoadXRCStructure` parses `best_structure_xrc.json` (Stacks/Layers with M/H/s/r fields) into `TXRFXStructure` for the Structure tab.

## XRFView Application

Standalone Delphi VCL application for browsing and comparing .xrfx files.

### Project Structure

```
XRFView/
  XRFView.dpr
  XRFView.dproj
  Forms/
    frm_XRFViewMain.pas/.dfm      -- main window
  Views/
    frame_StructureView.pas/.dfm  -- layer grid
    frame_CurvesView.pas/.dfm    -- TChart reflectivity curves
    frame_InfoView.pas/.dfm      -- metadata display
    frame_ProgressView.pas/.dfm  -- FoM vs iteration chart
    frame_CompareView.pas/.dfm   -- side-by-side comparison grid (TStringGrid)
  Units/
    xrfview_unit_loader.pas       -- orchestrates loading .xrfx into views
```

### Dependencies

- Jam Shell Controls (TJamShellTree, TJamShellList, TJamShellLink, TJamShellBreadCrumbBar)
- RaizeComponents (TRzSplitter, TRzStatusBar)
- TeeChart (TChart for curves and progress)
- Universal/unit_xrfx_package.pas (shared)
- Universal/unit_universal_types.pas (shared types)

### Layout

```
+-- Toolbar --------------------------------------------------+
| [Refresh] [Export Structure] [Copy Data] [Save Image]       |
+---------------------+---------------------------------------+
| BreadCrumbBar       |                                       |
|---------------------|  Detail area (TPageControl)            |
| ShellTree           |                                       |
| (folder navigation) |  [Structure] [Curves] [Info] [Progress]|
|---------------------|                                       |
| ShellList           |  Active tab content:                  |
| (*.xrfx filter)     |  - Structure: layer grid              |
|                     |  - Curves: TChart per-element         |
|                     |  - Info: manifest metadata            |
|                     |  - Progress: FoM vs iteration chart   |
+---------------------+---------------------------------------+
| Status bar (FoM, filename)                                  |
+-------------------------------------------------------------+
```

**Left panel:** TJamShellTree (top) + TJamShellList (bottom) inside a TRzSplitter, linked via TJamShellLink. ShellList filtered to `*.xrfx`. Breadcrumb bar above the tree.

**Right panel:** TPageControl with four tab sheets. Content loaded when a .xrfx file is selected in the ShellList.

**Main splitter:** TRzSplitter separating left (shell navigation) from right (detail area).

### xrfview_unit_loader.pas — Loader Orchestrator

Manages the lifecycle of loading .xrfx files into the viewer.

**Responsibilities:**
- Receives a file path from `ShellList.OnSelectItem`
- Extracts the .xrfx to a temp directory via `ExtractXRFXPackage`
- Loads `manifest.json` via `LoadManifest`
- Populates each frame: structure grid, curves chart, info panel, progress chart
- Manages multi-file state for comparison mode (list of loaded manifests + curve data)
- Cleans up previous temp directory before extracting the next file

**Temp directory strategy:**
- Created under `System.IOUtils.TPath.GetTempPath` + `XRFView\` subfolder
- Each extraction goes to a GUID-named subdirectory
- Previous extraction cleaned up when a new file is selected
- All remaining temp directories cleaned up on application close
- Stale temp directories (from crashes) cleaned up on next launch if older than 24 hours

### Tab Details

#### Structure Tab (frame_StructureView)

Displays the layer table from `best_structure_xrc.json` parsed via `LoadXRCStructure`:

| # | Material | Thickness (A) | Roughness (A) | Density (g/cm3) |
|---|----------|---------------|----------------|-----------------|
| 1 | W        | 15.2          | 3.5            | 19.3            |
| 2 | Si       | 30.0          | 3.5            | 2.33            |
| Sub | SiO2   | --            | 1.0            | 2.65            |

Plus summary: period d, gamma, N, structure type.

#### Curves Tab (frame_CurvesView)

TChart with one series per element. Checkboxes or legend clicks to toggle visibility. X-axis: angle (degrees), Y-axis: reflectivity (log scale).

#### Info Tab (frame_InfoView)

Read-only display of manifest.json fields:
- FoM, creation date, generator version
- Target lines, element pool, substrate
- Optimizer settings (population, iterations, stagnation limit)

#### Progress Tab (frame_ProgressView)

TChart: X-axis = iteration number, Y-axis = FoM (log scale). Parsed from `progress.log` via `LoadProgressLog`.

### Comparison Mode

When multiple .xrfx files are selected in ShellList (Ctrl+click), up to 8 files:

- **Curves tab** overlays reflectivity curves from all selected files. Legend shows `filename / element`.
- **Compare tab** appears (frame_CompareView) with a TStringGrid:

| Parameter      | run_01.xrfx | run_02.xrfx | run_03.xrfx |
|----------------|-------------|-------------|-------------|
| FoM            | 0.00342     | 0.00289     | 0.00401     |
| d (A)          | 45.2        | 42.8        | 47.1        |
| gamma          | 0.35        | 0.38        | 0.33        |
| N              | 120         | 150         | 100         |
| sigma (A)      | 3.5         | 3.5         | 3.5         |
| C-Ka peak R    | 0.12        | 0.15        | 0.09        |
| Na-Ka peak R   | 0.08        | 0.07        | 0.10        |

Per-element peak R and FWHM values come from the `per_element` array in `manifest.json`.

When in comparison mode, the single-file tabs (Structure, Info, Progress) show the first selected file.

### File Extension Registration

Same pattern as TriboViewer: registry-based `.xrfx` association via `RegisterFileType('xrfx', Application.ExeName)`. Supports opening .xrfx by double-click and command-line parameter.

### Export Capabilities

- **Extract structure** — save `best_structure_xrc.json` to disk for opening in XRayCalc3
- **Copy chart data** — copy visible curve data to clipboard as text
- **Save chart image** — export TChart as PNG/BMP/EMF
- **Extract all** — unzip entire .xrfx to a chosen folder

### Error Handling

- **Missing manifest.json:** show error message, refuse to load
- **Missing files referenced in manifest:** load what's available, disable corresponding tabs, show warning in status bar
- **Malformed JSON:** show parse error with filename, skip that file

## Build

XRFView added to `XRC3.groupproj`. Output to `XRFView/_Out/BIN/`.

Build command (Win64 Release):
```
XRFView/XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal
```
