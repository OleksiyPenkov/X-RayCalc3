# X-RayCalc3

Delphi VCL application for X-ray reflectivity calculations. RAD Studio 37.0 (Embarcadero).

## Build

Always use `/t:Build` — `/t:Make` does NOT work. "Build all" = Win32 + Win64 Release.

The common prefix for all MSBuild commands:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe
```

| Target | Command (append to prefix) |
|--------|---------------------------|
| Win32 Release | `XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1` |
| Win64 Release | `XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| Tests (build) | `Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1` |

**Run tests** (after building):
```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

**Group project** (`XRC3.groupproj`) build order: XRayCalc3 → XRayCalcVisualControls → XRCPreviewHandlerLib → xrccmd

## Architecture

```
Forms/          Main application windows (frm_Main, frm_settings, frm_about, etc.)
Views/          Reusable UI frames (frame_ChartInfo, frame_ProjectPanel, etc.)
Units/          Business logic (config, types, helpers, TCalcOrchestrator)
Math/           Calculation engine, complex math, materials database
LFPSO/          Particle swarm optimization for curve fitting
Components/     Custom VCL components + package (tree, grid, layer/stack editors)
Editors/        Data editor dialogs (profile, Henke table, JSON, normalisation)
Tests/          DUnitX test suite — 14 test units, Win32 Debug only
XRC_CMD/        Command-line interface variant
XRCXPreview/    Windows shell preview handler
Assets/         Icons, help docs, development plans
_Installer/     InnoSetup script (XRayCalc3Setup.iss) + deploy.sh
```

**Output:** `_Out/BIN/` (executables), `_Out/DCU/` + `_Out/DCU64/` (compiled units), `Tests/_Out/BIN/` (test runner)

## Key Files & Types

- `unit_consts.pas` — App constants: `CURRENT_PROJECT_VERSION = 7`, file extensions (`.xrcx` project, `.dsc` params), `WM_RECALC`/`WM_STARTEDITING` custom messages
- `unit_Types.pas` — Core types: `TFloatArray`, `TSolution = array of TLayer`, `TPopulation = array of TSolution`, `TProjectData` (variant record)
- `unit_calc.pas` — Main calculation engine
- `frm_Main.pas` — Primary window; logic being extracted into orchestrators and frames

## Dependencies

- **FastMath**: `D:\DelphiProjects\X-RayCalc\FastMath\FastMath\`
- **DUnitX**: `$(BDS)\source\DunitX`
- **Third-party**: RaizeComponents, VirtualTrees, Abbrevia, SynEdit

## Code Conventions

- Git commit prefixes: `+` new feature, `*` modification/fix
- Single `master` branch, remote is internal Gitea
- MVC-inspired: Forms/Views for UI, Units/Math for logic
- Ongoing refactoring: extracting logic from frm_Main into TCalcOrchestrator, frame_ChartInfo, frame_ProjectPanel

## DFM DPI Scaling

When scaling .dfm from HiDPI (192) to standard (96), halve all pixel-based properties:
- Left, Top, Width, Height, ClientWidth, ClientHeight, ExplicitLeft/Top/Width/Height, TextHeight
- Margins.Left/Top/Right/Bottom, Padding.Left/Top/Right/Bottom
- Font.Height (including nested: Foot.Font.Height, BottomAxis.Title.Font.Height)
- ButtonWidth, ButtonHeight, RowHeight, ItemHeight, ItemWidth, Indent, TabWidth, BorderWidth, Spacing, Constraints.*
- Frames (`Views/*.dfm`) lack PixelsPerInch but inherit 2x values — scale them too

**Do NOT scale:**
- ImageList Width/Height (icon bitmap dimensions, not layout)
- TChart properties (Foot.Font.Height, Legend.*, Axis.*, Ticks.Width) — runtime DPI-aware
