# X-RayCalc3

Delphi VCL application for X-ray reflectivity calculations. RAD Studio 37.0 (Embarcadero).

## Build

Always use `/t:Build` — `/t:Make` does NOT work.

**Win32 (x86) is the primary target** for the GUI and CLI. "Build all" = Win32 Release for
XRayCalc3 / xrccmd / XRFCalc / XRCUncert, plus Win64 Release for the same four; XRC_MCP is **Win64 only**
(it needs OmniThreadLibrary 3.08 — see Dependencies).

The common prefix for all MSBuild commands:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe
```

| Target | Command (append to prefix) |
|--------|---------------------------|
| XRayCalc3 **Win32** | `XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1` |
| XRayCalc3 Win64 | `XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRC_CMD **Win32** | `XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1` |
| XRC_CMD Win64 | `XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRFCalc **Win32** | `XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1` |
| XRFCalc Win64 | `XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRCUncert **Win32** | `XRCUncert\XRCUncert.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1` |
| XRCUncert Win64 | `XRCUncert\XRCUncert.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| XRC_MCP Win64 (only) | `XRC_MCP\XRC_MCP.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1` |
| Tests (build) | `XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1` |

**Run tests** (after building):
```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

**Group project** (`XRC3.groupproj`) build order: XRayCalc3 → XRayCalcVisualControls → xrccmd → XRFCalc → XRCUncert → XRC_MCP

**If a Win32 build fails with `F2613: Unit '<third-party>' not found`**, the culprit is the Delphi
library path, not the project. Command-line msbuild reads it from
`%APPDATA%\Embarcadero\BDS\37.0\EnvOptions.proj`, **not** from the registry — the IDE regenerates
that file from `HKCU\Software\Embarcadero\BDS\37.0\Library\<Platform>\Search Path` when it exits, so
fix both. Win64 has survived stale entries that Win32 does not, because its path includes
`$(BDSCOMMONDIR)\Dcp\$(Platform)` (which holds prebuilt DCUs); the Win32 equivalent is
`$(BDSCOMMONDIR)\Dcp`, which has only `.dcp`/`.bpi`/`.lib`.

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
XRCUncert/          Parameter-uncertainty tool (separate GUI app; Tools - Parameter uncertainties starts it)
XRC_MCP/            MCP server for LLM agents; spec in docs/superpowers/specs/2026-09-09-xrc-mcp-design.md
                    smoke/session.ps1 drives all 18 tools end to end (exit 0 = pass)
Shared/
  Math/             Calculation engine, complex math, materials database
  Bayes/            Sampler core and the uncertainty tool's VCL-free units (unit_Uncert*)
  Universal/        Universal mirror types, IO, templates, XRF lines
_Out/               Shared build output (BIN/, DCU/, DCU64/)
_Installer/         InnoSetup script (XRayCalc3Setup.iss) + deploy.sh
```

**Output:** `_Out/BIN/` (executables), `_Out/DCU/` + `_Out/DCU64/` (compiled units), `XRayCalc3/Tests/_Out/BIN/` (test runner). The Win64 GUI is `XRayCalc3.x64.exe` (`OutputExt`); `XRayCalc3.exe` is the Win32 build.

Exception: `XRFCalc.dproj` only redirects output to the shared `_Out/BIN` in its **Win64** property
groups, so a Win32 build lands in `XRFCalc/_Out/BIN/XRFCalc.exe` with DCUs in the misnamed
`XRFCalc/_Out/DCU64`. Post-build events copy the help next to the executable on both platforms:
`XRayCalc3.dproj` copies `XRayCalc3/Assets/Docs/Help/` to `<exe dir>/Help/`, and `XRFCalc.dproj` copies
`XRFCalc/Help/` to `<exe dir>/Help/XRFCalc/` (its own subfolder, because both Win64 builds share `_Out/BIN`).
`XRCUncert.dproj` puts both platforms into `_Out/BIN` (`XRCUncert.exe`, `XRCUncert.x64.exe`), DCUs into
`_Out/DCU/XRCUncert/<Platform>`, and copies `XRCUncert/Help/` to `<exe dir>/Help/XRCUncert/`.

## Release / installer

Version lives in `XRayCalc3/XRayCalc3.dproj` (`VerInfo_MajorVer`/`MinorVer`/`Release`/`Build` **and**
the `VerInfo_Keys` strings, in all four platform/config groups) and in `_Installer/XRayCalc3Setup.iss`
(`MyAppVersion`, three components). Build the GUI for both platforms first — the installer ships
`XRayCalc3.exe` and `XRayCalc3.x64.exe` — then:

```
bash _Installer/deploy.sh                                   # stages _Installer/deploy/
"C:\Users\Admin\AppData\Local\Programs\Inno Setup 6\ISCC.exe" _Installer/XRayCalc3Setup.iss
```

Inno Setup is a **per-user** install — not in Program Files, not on PATH. Output lands in
`_Installer/SetupOutput/XRayCalc3_Setup_<version>.exe`. `deploy.sh` also needs
`D:\SoftwareStorage\X-RayCalc3\{Henke,Jobs}` for the Henke tables and example projects.
The installer no longer ships a preview handler (`XRCXPreview` was removed in a3f8a5b).

**Publish** to the lab server (`Z:` = `\\csmic\web`): copy the setup to `Z:\files\Software\`
(`Z:\files\index.php` auto-lists the directory), then update the XRayCalc3 download card in
`Z:\index.html` — both its `href` and the `(vX.Y.Z)` caption.

**Register the MCP server** with Claude Code (one experiment directory per registration):
```
claude mcp add -s user xrc -- "D:\DelphiProjects\X-RayCalc\X-RayCalc3_Working\_Out\BIN\XRC_MCP.exe" --workdir "<experiment directory>"
```

## Key Files & Types

- `unit_consts.pas` — App constants: `CURRENT_PROJECT_VERSION = 8`, file extensions (`.xrcx` project, `.dsc` params), `WM_RECALC`/`WM_STARTEDITING` custom messages
- `unit_Types.pas` — Core types: `TFloatArray`, `TSolution = array of TLayer`, `TPopulation = array of TSolution`, `TProjectData` (variant record)
- `unit_calc.pas` — Main calculation engine
- `unit_gpu_calc.pas` — `TGpuEvaluator`: the LFPSO population's Parratt + convolution + χ² as D3D11 compute
  shaders (HLSL embedded, Win32 and Win64, no extra runtime). `TLFPSO_BASE.UseGPU` opts in; the GUI's
  `TCalcOptions.UseGPU` and `fit_xrr` `optimizer.device` set it. The GPU searches, the CPU rescores the
  answer (`RescoreBestOnCpu`), so reported χ² equals `TCalc`'s. Since 2026-09-28 both engines carry
  1 − Re ε (`TCalcLayer.delta`, computed directly from the materials as f₁·c, not recovered from a
  Single ε near 1) — only the GPU packs it into a layer buffer (its first float); the CPU model carries
  the same field in `TCalcModelSoA` arrays. The Fresnel term is the cancellation-free `sin²θ − (1 − Re ε)`
  in both the shader and `TCalc.RefCalc` (the epsilon ratio likewise from δ and β, `unit_calc.EpsRatio`),
  with the grazing sine in Double on the host (both engines); the universal engine and xrccmd use the
  same form. The shader's cancellation-free sums are also `precise`: the compiler/driver otherwise
  reassociates them back into a cancelling form. `TCalc.RefCalc`'s phase term (`System.Exp`/
  `System.Math.SinCos` in place of `Neslib.FastMath`'s approximations) and `math_complex.SqrtZ`'s square
  root (`1/System.Sqrt`, exact, in place of `InverseSqrt`) are exact by deliberate choice too — the
  author accepted CPU fits running ~12 % slower for the accuracy; don't revert either to FastMath.
  The first `Create` per process self-checks the compiled shaders against the double-precision
  reference Parratt (`unit_parratt_ref.ParrattRef`) on a fixed W/B4C multilayer, falls back to
  compiling with `D3DCOMPILE_IEEE_STRICTNESS` if the mean or worst `|log10 R/R_ref|` exceeds
  `TGpuEvaluator.SelfCheckBound`/`SelfCheckWorstBound` (3E-4, 4E-3) and raises (CPU fallback) if that
  also fails; `describe_server` reports `gpu_shader`, `gpu_self_check` and `gpu_self_check_worst`.
- `frm_Main.pas` — Primary window; logic being extracted into orchestrators and frames
- `XRC_MCP/units/unit_MCPAssess.pas` — the XRR measurement-quality checks, shared by the MCP tool
  `assess_xrr` (handler in `unit_ToolsFiles`) and the GUI's Data - Assess XRR quality (`frm_XRRAssess`).
  The GUI links it and the MCP helpers it needs from `..\XRC_MCP\units` and `..\XRC_CMD\Units` on its
  unit search path; keep those units free of the inbox, the sandbox and the server.
- `Shared/Bayes/unit_UncertSession.pas` and `unit_UncertView.pas` — where XRCUncert's behaviour lives and is
  tested: the session opens a project (request or plain refusal, counts, known values, stored result,
  out-of-date check) and writes back only `uncert_<model id>.json` / `counts_<data id>.dat`; the view turns
  a result into rows, error text, table, CSV and Details. `XRCUncert/Forms/frm_UncertMain` only draws
  them and runs `unit_UncertRun.RunUncertainty` on `unit_UncertThread`. The main app's part is two
  places: `actCalcUncertainty` (saves, then starts the tool of its own bitness from its own folder) and
  `unit_UncertKeep.KeepToolEntries` in `TfrmProjectPanel.SaveProject`, which takes the tool's entries
  from the file on disk before the project is re-zipped. `unit_UncertKeep` links no part of the sampler;
  keep it that way.

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
  **Local patch required:** the clone is on branch `xrc-unregisterwaitex` (release-3.08 + three commits,
  0cc7a66f, f3627653 and 60b128c5). 60b128c5 (`OtlComm.pas`): `ReceiveWait` could dequeue a message and
  still return False after a spurious wake-up, so a pool worker dropped `MSG_RUN` and a `Parallel.For`
  waited for ever (a rare full-suite hang, job thread in `TOmniParallelSimpleLoop.InternalExecute`).
  Stock 3.08 (and upstream master as of 2026-09-30) has two races in `TWaitFor`
  (`OtlSync.pas`) on its 64+ handle path, which the thread-pool manager takes once it has 60+ workers
  (back-to-back fits on a 30+-core machine): `UnregisterWaitHandles` uses `UnregisterWait`, which does not
  wait for a callback in flight, and `RegisterWaitHandles` fills the list a registered callback already
  reads. Either one kills the process with 0x0EEDFADE (exit 222) or an access violation (139) — in the
  tests, the GUI and XRC_MCP alike. The patches use `UnregisterWaitEx(h, INVALID_HANDLE_VALUE)` and hold
  `FAwaitedLock` while registering. Keep them when moving to a newer OTL unless upstream has fixed it;
  after changing the clone, rebuild the IDE packages and every project.
  Any thread that runs `Parallel.For` and pumps no messages must call `DrainThreadMessages`
  (`Shared/Math/unit_otl_drain.pas`) after every loop: OTL frees a task's control only from the
  creating thread's messages, ~12 MB per loop otherwise. And such a thread must end its `Execute` with
  `DrainParallelTasksBeforeExit` (in a `finally`), as `TJobWorker` and `TFittingThread`
  do: tasks post after the loop returns, and a message that reaches a thread already gone kills the pool
  worker (EOSError) and leaks the control. It pumps until the thread owns no OTL `DSiUtilWindow` (its
  task monitor, freed with the last task control; OTL 3.08 internals, re-check on upgrade), at most 10 s.
- **Third-party**: RaizeComponents, VirtualTrees, Abbrevia, SynEdit

## Code Conventions

- Git commit prefixes: `+` new feature, `*` modification/fix
- Single `master` branch, remote is the lab GitLab (plus GitHub)
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
