# Folder Restructure Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Reorganize the project root so shared code lives in `Shared/` and each app (XRayCalc3, XRC_CMD, XRFCalc, XRCXPreview) has its own top-level folder.

**Architecture:** All `git mv` operations happen first in one batch, then each project's paths are updated and verified with a build. This avoids a half-moved state where some files are in old locations and some in new.

**Tech Stack:** Delphi Object Pascal, MSBuild, git, bash

**Spec:** `docs/superpowers/specs/2026-03-18-folder-restructure-design.md`

---

## Chunk 1: Cleanup and File Moves

### Task 1: Delete junk files and directories

Remove empty directories, IDE debris, and temp files that don't need to be moved.

**Files:**
- Delete: `Manuscript/` (empty), `setup-claude-memory.sh`
- Delete: all `__history/` and `__recovery/` directories
- Delete: `.superpowers/` contents

- [ ] **Step 1: Delete __history and __recovery directories**

```bash
cd D:/DelphiProjects/X-RayCalc/X-RayCalc3_Working
find . -type d -name "__history" -exec rm -rf {} + 2>/dev/null
find . -type d -name "__recovery" -exec rm -rf {} + 2>/dev/null
```

- [ ] **Step 2: Delete empty and obsolete directories/files**

```bash
rm -rf Manuscript
rm -rf .superpowers
rm -f setup-claude-memory.sh
```

- [ ] **Step 3: Delete duplicate icon from Resources/**

```bash
rm -f Resources/XRayCalc3_x64_Icon.ico
```

---

### Task 2: Execute all git mv operations

All folder moves happen in one batch. The project won't build until path updates are done in subsequent tasks, but git history is preserved.

**Important:** Must invoke the `delphi-development` skill before modifying any Delphi files in later tasks.

- [ ] **Step 1: Create target directories**

```bash
cd D:/DelphiProjects/X-RayCalc/X-RayCalc3_Working
mkdir -p Shared
mkdir -p XRayCalc3/Assets/ToolIcons
mkdir -p XRayCalc3/Assets/Resources
mkdir -p XRFCalc/Assets
```

- [ ] **Step 2: Move shared code into Shared/**

```bash
git mv Math Shared/Math
git mv Universal Shared/Universal
```

- [ ] **Step 3: Move XRayCalc3 source folders**

```bash
git mv Components XRayCalc3/Components
git mv Editors XRayCalc3/Editors
git mv Forms XRayCalc3/Forms
git mv LFPSO XRayCalc3/LFPSO
git mv Units XRayCalc3/Units
git mv Views XRayCalc3/Views
git mv Tests XRayCalc3/Tests
```

- [ ] **Step 4: Move XRayCalc3 project files**

```bash
git mv XRayCalc3.dpr XRayCalc3/XRayCalc3.dpr
git mv XRayCalc3.dproj XRayCalc3/XRayCalc3.dproj
git mv XRayCalc3.res XRayCalc3/XRayCalc3.res
```

- [ ] **Step 5: Move Assets into XRayCalc3/Assets/**

```bash
git mv Assets/Docs XRayCalc3/Assets/Docs
git mv Assets/ToolIcons/Calc XRayCalc3/Assets/ToolIcons/Calc
git mv Assets/ToolIcons/Menu XRayCalc3/Assets/ToolIcons/Menu
git mv Assets/ToolIcons/Model XRayCalc3/Assets/ToolIcons/Model
git mv Assets/ToolIcons/Projects XRayCalc3/Assets/ToolIcons/Projects
git mv Assets/ToolIcons/_NewIcons XRayCalc3/Assets/ToolIcons/_NewIcons
git mv Assets/XRayCalc3_Icon.ico XRayCalc3/Assets/XRayCalc3_Icon.ico
git mv Assets/XRayCalc3_x64_Icon.ico XRayCalc3/Assets/XRayCalc3_x64_Icon.ico
git mv Assets/LFPSO_Improvements.md XRayCalc3/Assets/LFPSO_Improvements.md
```

- [ ] **Step 6: Move XRFCalc icons and Resources**

```bash
git mv Assets/ToolIcons/XRFCalc/* XRFCalc/Assets/
git mv Resources/Buttons XRayCalc3/Assets/Resources/Buttons
```

- [ ] **Step 7: Remove now-empty directories**

```bash
rm -rf Assets
rm -rf Resources
```

- [ ] **Step 8: Verify git status shows renames**

```bash
git status
```

Expected: All moves shown as renames. No untracked source files left at root.

- [ ] **Step 9: Commit the file moves**

```bash
git add -A
git commit -m "* Restructure folders: Shared/, XRayCalc3/, per-app Assets

Move shared code (Math, Universal) into Shared/.
Move XRayCalc3 source folders into XRayCalc3/.
Move Assets per app. Delete Manuscript, __history, __recovery.

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 2: XRayCalc3 Path Updates

### Task 3: Update XRayCalc3.dpr

**Files:**
- Modify: `XRayCalc3/XRayCalc3.dpr`

The .dpr moved from root to `XRayCalc3/`. Units/Forms/Views/etc. moved alongside it so their `in` clauses stay the same. Only `Math\` references change because Math moved to `Shared/Math/`.

- [ ] **Step 1: Update Math `in` clauses**

In `XRayCalc3/XRayCalc3.dpr`, replace each `'Math\` with `'..\Shared\Math\`:

| Line | Old | New |
|------|-----|-----|
| 15 | `math_complex in 'Math\math_complex.pas'` | `math_complex in '..\Shared\Math\math_complex.pas'` |
| 26 | `unit_calc in 'Math\unit_calc.pas'` | `unit_calc in '..\Shared\Math\unit_calc.pas'` |
| 27 | `unit_materials in 'Math\unit_materials.pas'` | `unit_materials in '..\Shared\Math\unit_materials.pas'` |
| 28 | `math_globals in 'Math\math_globals.pas'` | `math_globals in '..\Shared\Math\math_globals.pas'` |
| 45 | `unit_SavitzkyGolay in 'Math\unit_SavitzkyGolay.pas'` | `unit_SavitzkyGolay in '..\Shared\Math\unit_SavitzkyGolay.pas'` |
| 46 | `unit_ProfileCalc in 'Math\unit_ProfileCalc.pas'` | `unit_ProfileCalc in '..\Shared\Math\unit_ProfileCalc.pas'` |

Use `replace_all` with `'Math\` → `'..\Shared\Math\` in the Edit tool.

---

### Task 4: Update XRayCalc3.dproj

**Files:**
- Modify: `XRayCalc3/XRayCalc3.dproj`

- [ ] **Step 1: Update search path**

Replace the `DCC_UnitSearchPath` value in the `'$(Base)'` PropertyGroup:

```
Old: math;units;LFPSO;components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
New: ..\Shared\Math;Units;LFPSO;Components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
```

- [ ] **Step 2: Update output paths — Base**

```xml
<!-- Old -->
<DCC_DcuOutput>.\_Out\DCU</DCC_DcuOutput>
<DCC_ExeOutput>.\_Out\BIN</DCC_ExeOutput>
<DCC_DcpOutput>.\_Out\DCP</DCC_DcpOutput>

<!-- New -->
<DCC_DcuOutput>..\_Out\DCU</DCC_DcuOutput>
<DCC_ExeOutput>..\_Out\BIN</DCC_ExeOutput>
<DCC_DcpOutput>..\_Out\DCP</DCC_DcpOutput>
```

- [ ] **Step 3: Update output paths — Cfg_1_Win32**

```xml
<!-- Old -->
<DCC_ExeOutput>.\_Out\BIN</DCC_ExeOutput>
<!-- New -->
<DCC_ExeOutput>..\_Out\BIN</DCC_ExeOutput>
```

Note: This is in the `Cfg_1_Win32` condition block (~line 119). Use surrounding context to ensure the correct occurrence is changed.

- [ ] **Step 4: Update output paths — Cfg_2_Win64**

```xml
<!-- Old -->
<DCC_DcpOutput>.\_Out\DCP64</DCC_DcpOutput>
<DCC_DcuOutput>.\_Out\DCU64</DCC_DcuOutput>
<!-- New -->
<DCC_DcpOutput>..\_Out\DCP64</DCC_DcpOutput>
<DCC_DcuOutput>..\_Out\DCU64</DCC_DcuOutput>
```

- [ ] **Step 5: Update DCCReference Math paths**

Replace all 6 `Math\` DCCReference entries with `..\Shared\Math\`:

```
Math\math_complex.pas        → ..\Shared\Math\math_complex.pas
Math\unit_calc.pas            → ..\Shared\Math\unit_calc.pas
Math\unit_materials.pas       → ..\Shared\Math\unit_materials.pas
Math\math_globals.pas         → ..\Shared\Math\math_globals.pas
Math\unit_SavitzkyGolay.pas   → ..\Shared\Math\unit_SavitzkyGolay.pas
Math\unit_ProfileCalc.pas     → ..\Shared\Math\unit_ProfileCalc.pas
```

Use `replace_all` in the Edit tool: `Include="Math\` → `Include="..\Shared\Math\`

- [ ] **Step 6: Update Deployment section**

Replace `LocalName="_Out\BIN\XRayCalc3.exe"` with `LocalName="..\_Out\BIN\XRayCalc3.exe"` (2 occurrences).

- [ ] **Step 7: Build XRayCalc3 to verify**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeded.

- [ ] **Step 8: Commit**

```bash
git add XRayCalc3/XRayCalc3.dpr XRayCalc3/XRayCalc3.dproj
git commit -m "* Update XRayCalc3 paths for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 3: XRC_CMD and XRFCalc Path Updates

### Task 5: Update XRC_CMD project files

**Files:**
- Modify: `XRC_CMD/xrccmd.dpr`
- Modify: `XRC_CMD/xrccmd.dproj`

- [ ] **Step 1: Update xrccmd.dpr `in` clauses**

Replace all `'..\Universal\` with `'..\Shared\Universal\` and `'..\Math\` with `'..\Shared\Math\`:

```
'..\Universal\unit_universal_types.pas'     → '..\Shared\Universal\unit_universal_types.pas'
'..\Universal\unit_universal_fitness.pas'   → '..\Shared\Universal\unit_universal_fitness.pas'
'..\Universal\unit_universal_pso.pas'       → '..\Shared\Universal\unit_universal_pso.pas'
'..\Universal\unit_universal_io.pas'        → '..\Shared\Universal\unit_universal_io.pas'
'..\Universal\unit_universal_optimizer.pas' → '..\Shared\Universal\unit_universal_optimizer.pas'
'..\Universal\unit_universal_templates.pas' → '..\Shared\Universal\unit_universal_templates.pas'
'..\Universal\unit_xrfx_package.pas'        → '..\Shared\Universal\unit_xrfx_package.pas'
'..\Math\unit_materials_mix.pas'            → '..\Shared\Math\unit_materials_mix.pas'
```

Use two `replace_all` calls: `..\Universal\` → `..\Shared\Universal\` and `..\Math\` → `..\Shared\Math\`

- [ ] **Step 2: Update xrccmd.dproj search path**

In the `'$(Base)'` PropertyGroup:

```
Old: ..\math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;..\Universal;$(DCC_UnitSearchPath)
New: ..\Shared\Math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;..\Shared\Universal;$(DCC_UnitSearchPath)
```

- [ ] **Step 3: Update xrccmd.dproj DCCReference paths**

Replace all `..\Universal\` with `..\Shared\Universal\` and `..\Math\` with `..\Shared\Math\` in DCCReference Include attributes (7 Universal + 1 Math entries).

Use two `replace_all` calls.

- [ ] **Step 4: Build XRC_CMD to verify**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeded.

- [ ] **Step 5: Commit**

```bash
git add XRC_CMD/xrccmd.dpr XRC_CMD/xrccmd.dproj
git commit -m "* Update XRC_CMD paths for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 6: Update XRFCalc project files

**Files:**
- Modify: `XRFCalc/XRFCalc.dpr`
- Modify: `XRFCalc/XRFCalc.dproj`
- Modify: `XRFCalc/XRFCalcIcons.rc`

- [ ] **Step 1: Update XRFCalc.dpr `in` clauses**

Replace all `'..\Universal\` with `'..\Shared\Universal\` (4 entries):

```
'..\Universal\unit_universal_io.pas'       → '..\Shared\Universal\unit_universal_io.pas'
'..\Universal\unit_xrf_lines.pas'          → '..\Shared\Universal\unit_xrf_lines.pas'
'..\Universal\unit_xrfx_package.pas'       → '..\Shared\Universal\unit_xrfx_package.pas'
'..\Universal\unit_universal_types.pas'    → '..\Shared\Universal\unit_universal_types.pas'
```

- [ ] **Step 2: Update XRFCalc.dproj search path**

```
Old: ..\Universal;..\XRC_CMD\units;..\math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
New: ..\Shared\Universal;..\XRC_CMD\units;..\Shared\Math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
```

- [ ] **Step 3: Update XRFCalc.dproj DCCReference paths**

Replace `..\Universal\` with `..\Shared\Universal\` in all 4 DCCReference Include attributes.

- [ ] **Step 4: Update XRFCalcIcons.rc**

Replace all 7 icon paths. The pattern is:
```
Old: "..\\Assets\\ToolIcons\\XRFCalc\\<filename>.png"
New: "Assets\\<filename>.png"
```

Use `replace_all`: `..\\Assets\\ToolIcons\\XRFCalc\\` → `Assets\\`

- [ ] **Step 5: Build XRFCalc to verify**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeded. (The build process will regenerate XRFCalcIcons.RES from the .rc file.)

- [ ] **Step 6: Commit**

```bash
git add XRFCalc/XRFCalc.dpr XRFCalc/XRFCalc.dproj XRFCalc/XRFCalcIcons.rc
git commit -m "* Update XRFCalc paths for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 4: Tests and Supporting Files

### Task 7: Update Tests project files

**Files:**
- Modify: `XRayCalc3/Tests/XRayCalc3Tests.dpr`
- Modify: `XRayCalc3/Tests/XRayCalc3Tests.dproj`

Tests moved from `root/Tests/` to `XRayCalc3/Tests/`. Three categories of path changes:
- `Math\` → needs `..\..\Shared\Math\` (was `..\Math\`, now 2 levels up + Shared)
- `Units\`, `Components\`, `LFPSO\` → stay as `..\X\` (same relative depth under XRayCalc3)
- `Universal\` → needs `..\..\Shared\Universal\` (was `..\Universal\`, now 2 levels up + Shared)
- `XRC_CMD\` → needs `..\..\XRC_CMD\` (was `..\XRC_CMD\`, now 2 levels up)

- [ ] **Step 1: Update XRayCalc3Tests.dpr `in` clauses — Math**

Replace all `'..\Math\` with `'..\..\Shared\Math\` (7 entries: math_complex, math_globals, unit_SavitzkyGolay, unit_materials, unit_calc, unit_ProfileCalc, unit_materials_mix).

Use `replace_all`: `'..\Math\` → `'..\..\Shared\Math\`

- [ ] **Step 2: Update XRayCalc3Tests.dpr `in` clauses — Universal**

Replace all `'..\Universal\` with `'..\..\Shared\Universal\` (5 entries).

Use `replace_all`: `'..\Universal\` → `'..\..\Shared\Universal\`

- [ ] **Step 3: Update XRayCalc3Tests.dpr `in` clauses — XRC_CMD**

Replace all `'..\XRC_CMD\` with `'..\..\XRC_CMD\` (2 entries: cmd_unit_types, cmd_math_globals).

Use `replace_all`: `'..\XRC_CMD\` → `'..\..\XRC_CMD\`

- [ ] **Step 4: Verify no `..\Units\`, `..\LFPSO\`, `..\Components\` changes needed**

These paths stay as `..\Units\`, `..\LFPSO\`, `..\Components\` because Tests is now a sibling of these under XRayCalc3/. Read the file to confirm the paths look correct.

- [ ] **Step 5: Update XRayCalc3Tests.dproj search path**

```
Old: ..\math;..\units;..\LFPSO;..\components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(BDS)\source\DunitX;$(DCC_UnitSearchPath)
New: ..\..\Shared\Math;..\Units;..\LFPSO;..\Components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;..\..\Shared\Universal;$(BDS)\source\DunitX;$(DCC_UnitSearchPath)
```

- [ ] **Step 6: Update XRayCalc3Tests.dproj DCCReference paths — Math**

Replace `..\math\` with `..\..\Shared\Math\` in DCCReference Include attributes (3 entries: math_complex, math_globals, unit_ProfileCalc).

Use `replace_all`: `Include="..\math\` → `Include="..\..\Shared\Math\`

- [ ] **Step 7: Update XRayCalc3Tests.dproj DCCReference paths — Units**

Replace `..\units\` with `..\Units\` in DCCReference Include attributes (7 entries). This changes the case but not the path depth.

Use `replace_all`: `Include="..\units\` → `Include="..\Units\`

- [ ] **Step 8: Build Tests to verify**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

Expected: Build succeeded.

- [ ] **Step 9: Run Tests**

```bash
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All 266 tests pass.

- [ ] **Step 10: Commit**

```bash
git add XRayCalc3/Tests/XRayCalc3Tests.dpr XRayCalc3/Tests/XRayCalc3Tests.dproj
git commit -m "* Update Tests paths for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 8: Update XRC3.groupproj

**Files:**
- Modify: `XRC3.groupproj`

- [ ] **Step 1: Update all project references**

Two sets of replacements:

1. XRayCalc3 references (in `<Projects Include>` and 3 `<MSBuild Projects>` targets):
   - `XRayCalc3.dproj` → `XRayCalc3\XRayCalc3.dproj`

2. VisualControls references (in `<Projects Include>` and 3 `<MSBuild Projects>` targets):
   - `components\XRayCalcVisualControls.dproj` → `XRayCalc3\Components\XRayCalcVisualControls.dproj`

Use two `replace_all` calls:
- `"XRayCalc3.dproj"` → `"XRayCalc3\XRayCalc3.dproj"` (careful: only bare references, not ones already prefixed)
- `"components\XRayCalcVisualControls.dproj"` → `"XRayCalc3\Components\XRayCalcVisualControls.dproj"`

- [ ] **Step 2: Commit**

```bash
git add XRC3.groupproj
git commit -m "* Update groupproj references for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 9: Update deploy.sh and .gitignore

**Files:**
- Modify: `_Installer/deploy.sh`
- Modify: `.gitignore`

- [ ] **Step 1: Update deploy.sh Asset paths**

Replace all `Assets/` with `XRayCalc3/Assets/` in `_Installer/deploy.sh`.

Use `replace_all`: `$PROJECT_DIR/Assets/` → `$PROJECT_DIR/XRayCalc3/Assets/`

- [ ] **Step 2: Update .gitignore**

Remove stale path-specific entries and add new patterns:

Remove these lines:
```
/forms/__recovery/frm_Main.dfm
/forms/__recovery/frm_Main.pas
```

Add these lines (after the existing `__history` line):
```
__recovery
.superpowers/
```

Also update the `Resources` entry — it was gitignoring the old `Resources/` folder. Now that Resources is gone and merged into XRayCalc3/Assets/Resources, this line can be removed. However, `Resources` as a pattern might match other things, so check context. The line `Resources` on line 14 was specifically for the old root `Resources/` dir — remove it.

Also update `/components/*.RES` to `/XRayCalc3/Components/*.RES`.

- [ ] **Step 3: Commit**

```bash
git add _Installer/deploy.sh .gitignore
git commit -m "* Update deploy.sh and .gitignore for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

### Task 10: Update CLAUDE.md

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1: Update build commands**

In the build command table, update:
- `XRayCalc3.dproj` → `XRayCalc3\XRayCalc3.dproj` (Win32 and Win64 rows)
- `Tests\XRayCalc3Tests.dproj` → `XRayCalc3\Tests\XRayCalc3Tests.dproj`

Update the test runner path:
- `Tests\_Out\BIN\XRayCalc3Tests.exe` → `XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe`

- [ ] **Step 2: Update Architecture section**

Replace the folder tree with:

```
Shared/Math/    Calculation engine, complex math, materials database
Shared/Universal/ Universal mirror types, IO, fitness, PSO, templates
XRayCalc3/      Main application
  Forms/        Main windows (frm_Main, frm_settings, frm_about, etc.)
  Views/        Reusable UI frames (frame_ChartInfo, frame_ProjectPanel, etc.)
  Units/        Business logic (config, types, helpers, TCalcOrchestrator)
  LFPSO/        Particle swarm optimization for curve fitting
  Components/   Custom VCL components + package (tree, grid, layer/stack editors)
  Editors/      Data editor dialogs (profile, Henke table, JSON, normalisation)
  Tests/        DUnitX test suite — 14 test units, Win32 Debug only
  Assets/       Icons, help docs, development plans
XRC_CMD/        Command-line interface variant
XRFCalc/        XRF calculator GUI wrapper
XRCXPreview/    Windows shell preview handler
_Installer/     InnoSetup script (XRayCalc3Setup.iss) + deploy.sh
```

Update the output description:
```
**Output:** `_Out/BIN/` (executables), `_Out/DCU/` + `_Out/DCU64/` (compiled units), `XRayCalc3/Tests/_Out/BIN/` (test runner)
```

- [ ] **Step 3: Commit**

```bash
git add CLAUDE.md
git commit -m "* Update CLAUDE.md for new folder structure

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>"
```

---

## Chunk 5: Final Verification

### Task 11: Full build verification

- [ ] **Step 1: Clean build outputs**

```bash
rm -rf _Out/DCU _Out/DCU64 _Out/DCP _Out/DCP64
```

- [ ] **Step 2: Build XRayCalc3 Win64 Release**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeded.

- [ ] **Step 3: Build XRC_CMD Win64 Release**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeded.

- [ ] **Step 4: Build XRFCalc Win64 Release**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeded.

- [ ] **Step 5: Build and run Tests**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

```bash
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All 266 tests pass.

- [ ] **Step 6: Verify root is clean**

```bash
ls -1 D:/DelphiProjects/X-RayCalc/X-RayCalc3_Working/
```

Expected top-level contents:
```
.claude/
.git/
.gitignore
CLAUDE.md
Shared/
TODO.md
XRC3.groupproj
XRCXPreview/
XRC_CMD/
XRFCalc/
XRayCalc3/
_Installer/
_Out/
docs/
```

No stray source folders (Math/, Units/, Forms/, Views/, Components/, Editors/, LFPSO/, Tests/, Assets/, Resources/, Manuscript/).
