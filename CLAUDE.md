# X-RayCalc3

Delphi VCL application for X-ray reflectivity calculations. RAD Studio 37.0 (Embarcadero).

## Build

Always use `/t:Build` — `/t:Make` does NOT work. "Build all" = Win64 Release only.

The common prefix for all MSBuild commands:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe
```

| Target | Command (append to prefix) |
|--------|---------------------------|
| XRayCalc3 Win64 | `XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRC_CMD Win64 | `XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRFCalc Win64 | `XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRC_MCP Win64 | `XRC_MCP\XRC_MCP.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| Tests (build) | `XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1` |

**Run tests** (after building):
```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

**Group project** (`XRC3.groupproj`) build order: XRayCalc3 → XRayCalcVisualControls → XRCPreviewHandlerLib → xrccmd → XRFCalc → XRC_MCP

## Architecture

```
XRayCalc3/          Main GUI application
  Forms/            Main application windows (frm_Main, frm_settings, frm_about, etc.)
  Views/            Reusable UI frames (frame_ChartInfo, frame_ProjectPanel, etc.)
  Units/            Business logic (config, types, helpers, TCalcOrchestrator)
  LFPSO/            Particle swarm optimization for curve fitting
  Components/       Custom VCL components + package (tree, grid, layer/stack editors)
  Editors/          Data editor dialogs (profile, Henke table, JSON, normalisation)
  Assets/           Icons, help docs, development plans
  Tests/            DUnitX test suite — 14 test units, Win32 Debug only
XRC_CMD/            Command-line interface variant
XRFCalc/            XRF calculation GUI app
XRCXPreview/        Windows shell preview handler
XRC_MCP/            MCP server for LLM agents; spec in docs/superpowers/specs/2026-09-09-xrc-mcp-design.md
                    smoke/session.ps1 drives all 16 tools end to end (exit 0 = pass)
Shared/
  Math/             Calculation engine, complex math, materials database
  Universal/        Universal mirror types, IO, templates, XRF lines
_Out/               Shared build output (BIN/, DCU/, DCU64/)
_Installer/         InnoSetup script (XRayCalc3Setup.iss) + deploy.sh
```

**Output:** `_Out/BIN/` (executables), `_Out/DCU/` + `_Out/DCU64/` (compiled units), `XRayCalc3/Tests/_Out/BIN/` (test runner). The Win64 GUI is `XRayCalc3.x64.exe` (`OutputExt`); `XRayCalc3.exe` is the Win32 build.

**Register the MCP server** with Claude Code (one experiment directory per registration):
```
claude mcp add -s user xraca -- "D:\DelphiProjects\X-RayCalc\X-RayCalc3_Working\_Out\BIN\XRC_MCP.exe" --workdir "<experiment directory>"
```

## Key Files & Types

- `unit_consts.pas` — App constants: `CURRENT_PROJECT_VERSION = 7`, file extensions (`.xrcx` project, `.dsc` params), `WM_RECALC`/`WM_STARTEDITING` custom messages
- `unit_Types.pas` — Core types: `TFloatArray`, `TSolution = array of TLayer`, `TPopulation = array of TSolution`, `TProjectData` (variant record)
- `unit_calc.pas` — Main calculation engine
- `frm_Main.pas` — Primary window; logic being extracted into orchestrators and frames

## Dependencies

- **FastMath**: `D:\DelphiProjects\X-RayCalc\FastMath\FastMath\`
- **DUnitX**: `$(BDS)\source\DunitX`
- **OmniThreadLibrary**: `D:\DelphiProjects\_Libraries\OmniThreadLibrary` (on the IDE library
  path for Win32 and Win64), a git clone of gabr42/OmniThreadLibrary checked out at the tag
  **`release-3.08`** (April 2026). **3.08 or later is required for Win64.** Older checkouts cast
  code pointers to `Cardinal` in `TOmniTaskExecutor.GetMethodAddrAndSignature` (`OtlTaskControl.pas`),
  which truncates a 64-bit pointer: the task pool never answers and `Parallel.&For`/`Parallel.ForEach`
  hang for ever, so every Win64 build that runs the universal optimizer or the LFPSO fit —
  `optimize_mirror`, `fit_xrr`, `xrccmd -u`, XRFCalc, and the Win64 GUI's own fitting — stops at
  iteration 0 and cannot shut down. Win32 is unaffected, so the test suite passes either way.
  Upstream fixed it in commit 220e9d03 ("fixed bad 64-bit pointer casts"), included in 3.08.
  The IDE packages for Studio 37.0 are built from `packages\Delphi 13 Florence`.
- **Third-party**: RaizeComponents, VirtualTrees, Abbrevia, SynEdit

## Code Conventions

- Git commit prefixes: `+` new feature, `*` modification/fix
- Single `master` branch, remote is internal Gitea
- MVC-inspired: Forms/Views for UI, Units/Math for logic
- Ongoing refactoring: extracting logic from frm_Main into TCalcOrchestrator, frame_ChartInfo, frame_ProjectPanel

## Delphi Gotchas

- In class declarations, fields must come before methods/properties in each visibility section (`private`, `public`, etc.) — otherwise `E2169`
- Setting VCL control properties (e.g. `ItemIndex`, `Checked`) in code does NOT fire event handlers (`OnClick`, `OnChanging`, etc.) — call update logic explicitly after programmatic changes
- Raize `TRzRadioGroup.OnChanging` fires BEFORE `ItemIndex` updates; use `OnClick` when you need the new value

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

## Required Skills

Always invoke the `delphi-development` skill before writing or modifying any code.
