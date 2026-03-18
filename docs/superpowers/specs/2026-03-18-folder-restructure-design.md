# Folder Restructure Design

## Problem

XRayCalc3's source folders (Units/, Forms/, Views/, etc.) occupy the project root, making 3 other apps (XRC_CMD, XRFCalc, XRCXPreview) look like subprojects. The root should clearly separate shared code from per-app code.

## Target Structure

```
Root/
├── Shared/
│   ├── Math/                 (7 .pas — used by XRayCalc3 + XRC_CMD + Tests)
│   └── Universal/            (9 .pas + 1 .json — used by XRC_CMD + XRFCalc + Tests)
│
├── XRayCalc3/
│   ├── Assets/
│   │   ├── Docs/             (Help/, plans/)
│   │   ├── ToolIcons/        (Calc/, Menu/, Model/, Projects/, _NewIcons/)
│   │   ├── Resources/        (Buttons/ merged from old root Resources/)
│   │   ├── XRayCalc3_Icon.ico
│   │   └── XRayCalc3_x64_Icon.ico
│   ├── Components/           (includes XRayCalcVisualControls.dpk/.dproj)
│   ├── Editors/
│   ├── Forms/
│   ├── LFPSO/
│   ├── Tests/
│   ├── Units/
│   ├── Views/
│   ├── XRayCalc3.dpr
│   ├── XRayCalc3.dproj
│   └── XRayCalc3.res
│
├── XRC_CMD/                  (internal structure unchanged)
│   ├── Units/
│   ├── xrccmd.dpr
│   └── xrccmd.dproj
│
├── XRFCalc/
│   ├── Assets/               (XRFCalc icons moved from ToolIcons/XRFCalc/)
│   ├── Forms/
│   ├── Help/
│   ├── Units/
│   ├── Views/
│   └── XRFCalc.dproj
│
├── XRCXPreview/              (internal structure unchanged)
│
├── _Out/                     (shared build output: BIN/, DCU/, DCU64/, DCP/, DCP64/)
├── _Installer/
├── XRC3.groupproj
├── CLAUDE.md
└── TODO.md
```

## Moves

### New directories to create
- `Shared/`
- `XRayCalc3/`
- `XRayCalc3/Assets/`
- `XRayCalc3/Assets/Resources/`
- `XRFCalc/Assets/`

### Folder moves (git mv)
| Source | Destination |
|--------|------------|
| `Math/` | `Shared/Math/` |
| `Universal/` | `Shared/Universal/` |
| `Components/` | `XRayCalc3/Components/` |
| `Editors/` | `XRayCalc3/Editors/` |
| `Forms/` | `XRayCalc3/Forms/` |
| `LFPSO/` | `XRayCalc3/LFPSO/` |
| `Units/` | `XRayCalc3/Units/` |
| `Views/` | `XRayCalc3/Views/` |
| `Tests/` | `XRayCalc3/Tests/` |
| `Assets/Docs/` | `XRayCalc3/Assets/Docs/` |
| `Assets/ToolIcons/Calc/` | `XRayCalc3/Assets/ToolIcons/Calc/` |
| `Assets/ToolIcons/Menu/` | `XRayCalc3/Assets/ToolIcons/Menu/` |
| `Assets/ToolIcons/Model/` | `XRayCalc3/Assets/ToolIcons/Model/` |
| `Assets/ToolIcons/Projects/` | `XRayCalc3/Assets/ToolIcons/Projects/` |
| `Assets/ToolIcons/_NewIcons/` | `XRayCalc3/Assets/ToolIcons/_NewIcons/` |
| `Assets/XRayCalc3_Icon.ico` | `XRayCalc3/Assets/XRayCalc3_Icon.ico` |
| `Assets/XRayCalc3_x64_Icon.ico` | `XRayCalc3/Assets/XRayCalc3_x64_Icon.ico` |
| `Assets/LFPSO_Improvements.md` | `XRayCalc3/Assets/LFPSO_Improvements.md` |
| `Assets/ToolIcons/XRFCalc/` | `XRFCalc/Assets/` |
| `Resources/Buttons/` | `XRayCalc3/Assets/Resources/Buttons/` |

### XRayCalc3 project files to move
| Source | Destination |
|--------|------------|
| `XRayCalc3.dpr` | `XRayCalc3/XRayCalc3.dpr` |
| `XRayCalc3.dproj` | `XRayCalc3/XRayCalc3.dproj` |
| `XRayCalc3.res` | `XRayCalc3/XRayCalc3.res` |

### Delete
- `Manuscript/` (contains only empty subdirectories)
- `Resources/` (after merging contents; `Resources/XRayCalc3_x64_Icon.ico` is a duplicate — delete)
- `Assets/` (after moving all contents)
- All `__history/` and `__recovery/` dirs (IDE recreates them)
- `.superpowers/` contents (untracked temp files)
- Root IDE temp files: `XRC3.~dsk`, `XRayCalc3.identcache`, `XRayCalc3.dsv`
- `setup-claude-memory.sh` (one-off script, no longer needed)

---

## Path Updates — XRayCalc3.dpr

The .dpr moves from root to `XRayCalc3/`. Subfolders (Units/, Forms/, Views/, etc.) move alongside it, so their relative `in` clauses stay the same. Only `Math\` references change because Math moves to `Shared/Math/`.

| Old `in` clause | New `in` clause |
|-----------------|----------------|
| `'Math\math_complex.pas'` | `'..\Shared\Math\math_complex.pas'` |
| `'Math\unit_calc.pas'` | `'..\Shared\Math\unit_calc.pas'` |
| `'Math\unit_materials.pas'` | `'..\Shared\Math\unit_materials.pas'` |
| `'Math\math_globals.pas'` | `'..\Shared\Math\math_globals.pas'` |
| `'Math\unit_SavitzkyGolay.pas'` | `'..\Shared\Math\unit_SavitzkyGolay.pas'` |
| `'Math\unit_ProfileCalc.pas'` | `'..\Shared\Math\unit_ProfileCalc.pas'` |

All other `in` clauses (`'Units\...'`, `'Forms\...'`, `'Views\...'`, `'Components\...'`, `'Editors\...'`, `'LFPSO\...'`) remain unchanged.

## Path Updates — XRayCalc3.dproj

### Search path (Base)
```
Before: math;units;LFPSO;components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
After:  ..\Shared\Math;Units;LFPSO;Components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
```

### Output paths
The .dproj moves from root to `XRayCalc3/`. `_Out/` stays at root, so all output paths gain a `..\` prefix.

| Property | Condition | Old | New |
|----------|-----------|-----|-----|
| `DCC_DcuOutput` | Base | `.\_Out\DCU` | `..\_Out\DCU` |
| `DCC_ExeOutput` | Base | `.\_Out\BIN` | `..\_Out\BIN` |
| `DCC_DcpOutput` | Base | `.\_Out\DCP` | `..\_Out\DCP` |
| `DCC_ExeOutput` | Cfg_1_Win32 | `.\_Out\BIN` | `..\_Out\BIN` |
| `DCC_DcpOutput` | Cfg_2_Win64 | `.\_Out\DCP64` | `..\_Out\DCP64` |
| `DCC_DcuOutput` | Cfg_2_Win64 | `.\_Out\DCU64` | `..\_Out\DCU64` |

### Icon paths
Icon paths are `Assets\XRayCalc3_Icon.ico` and `Assets\XRayCalc3_x64_Icon.ico`. Since Assets moves into XRayCalc3/ alongside the .dproj, these paths remain unchanged. (5 occurrences across Win32/Win64/Debug/Release configs — all stay as-is.)

### DCCReference paths
All `Math\*` entries must gain `..\Shared\` prefix. Other paths (Units\, Forms\, Views\, etc.) remain unchanged.

| Old DCCReference | New DCCReference |
|-----------------|-----------------|
| `Math\math_complex.pas` | `..\Shared\Math\math_complex.pas` |
| `Math\unit_calc.pas` | `..\Shared\Math\unit_calc.pas` |
| `Math\unit_materials.pas` | `..\Shared\Math\unit_materials.pas` |
| `Math\math_globals.pas` | `..\Shared\Math\math_globals.pas` |
| `Math\unit_SavitzkyGolay.pas` | `..\Shared\Math\unit_SavitzkyGolay.pas` |
| `Math\unit_ProfileCalc.pas` | `..\Shared\Math\unit_ProfileCalc.pas` |

### Deployment section
`LocalName="_Out\BIN\XRayCalc3.exe"` → `LocalName="..\_Out\BIN\XRayCalc3.exe"` (2 entries).

---

## Path Updates — XRC_CMD/xrccmd.dpr

| Old `in` clause | New `in` clause |
|-----------------|----------------|
| `'..\Universal\unit_universal_types.pas'` | `'..\Shared\Universal\unit_universal_types.pas'` |
| `'..\Universal\unit_universal_fitness.pas'` | `'..\Shared\Universal\unit_universal_fitness.pas'` |
| `'..\Universal\unit_universal_pso.pas'` | `'..\Shared\Universal\unit_universal_pso.pas'` |
| `'..\Universal\unit_universal_io.pas'` | `'..\Shared\Universal\unit_universal_io.pas'` |
| `'..\Universal\unit_universal_optimizer.pas'` | `'..\Shared\Universal\unit_universal_optimizer.pas'` |
| `'..\Universal\unit_universal_templates.pas'` | `'..\Shared\Universal\unit_universal_templates.pas'` |
| `'..\Universal\unit_xrfx_package.pas'` | `'..\Shared\Universal\unit_xrfx_package.pas'` |
| `'..\Math\unit_materials_mix.pas'` | `'..\Shared\Math\unit_materials_mix.pas'` |

## Path Updates — XRC_CMD/xrccmd.dproj

### Search path (Base)
```
Before: ..\math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;..\Universal;$(DCC_UnitSearchPath)
After:  ..\Shared\Math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;..\Shared\Universal;$(DCC_UnitSearchPath)
```

### DCCReference paths
| Old | New |
|-----|-----|
| `..\Universal\unit_universal_types.pas` | `..\Shared\Universal\unit_universal_types.pas` |
| `..\Universal\unit_universal_fitness.pas` | `..\Shared\Universal\unit_universal_fitness.pas` |
| `..\Universal\unit_universal_pso.pas` | `..\Shared\Universal\unit_universal_pso.pas` |
| `..\Universal\unit_universal_io.pas` | `..\Shared\Universal\unit_universal_io.pas` |
| `..\Universal\unit_universal_optimizer.pas` | `..\Shared\Universal\unit_universal_optimizer.pas` |
| `..\Universal\unit_universal_templates.pas` | `..\Shared\Universal\unit_universal_templates.pas` |
| `..\Math\unit_materials_mix.pas` | `..\Shared\Math\unit_materials_mix.pas` |

### Output path — intentionally unchanged
`DCC_ExeOutput=..\XRFCalc\_Out\BIN` deliberately outputs xrccmd.exe to XRFCalc's output. XRC_CMD stays at same depth relative to XRFCalc, so no change needed.

---

## Path Updates — XRFCalc/XRFCalc.dpr

| Old `in` clause | New `in` clause |
|-----------------|----------------|
| `'..\Universal\unit_universal_io.pas'` | `'..\Shared\Universal\unit_universal_io.pas'` |
| `'..\Universal\unit_xrf_lines.pas'` | `'..\Shared\Universal\unit_xrf_lines.pas'` |
| `'..\Universal\unit_xrfx_package.pas'` | `'..\Shared\Universal\unit_xrfx_package.pas'` |
| `'..\Universal\unit_universal_types.pas'` | `'..\Shared\Universal\unit_universal_types.pas'` |

## Path Updates — XRFCalc/XRFCalc.dproj

### Search path (Base)
```
Before: ..\Universal;..\XRC_CMD\units;..\math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
After:  ..\Shared\Universal;..\XRC_CMD\units;..\Shared\Math;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)
```

### DCCReference paths
| Old | New |
|-----|-----|
| `..\Universal\unit_universal_io.pas` | `..\Shared\Universal\unit_universal_io.pas` |
| `..\Universal\unit_xrf_lines.pas` | `..\Shared\Universal\unit_xrf_lines.pas` |
| `..\Universal\unit_xrfx_package.pas` | `..\Shared\Universal\unit_xrfx_package.pas` |
| `..\Universal\unit_universal_types.pas` | `..\Shared\Universal\unit_universal_types.pas` |

## Path Updates — XRFCalc/XRFCalcIcons.rc

Icons move from `Assets/ToolIcons/XRFCalc/` to `XRFCalc/Assets/`. The .rc file is in `XRFCalc/`, so paths shorten:

```
Before: "..\\Assets\\ToolIcons\\XRFCalc\\00_Refresh.png"
After:  "Assets\\00_Refresh.png"
```

All 7 RCDATA entries must be updated. After editing, recompile with:
```
brcc32 XRFCalcIcons.rc
```
(or let the Delphi build regenerate the .RES)

---

## Path Updates — XRayCalc3Tests.dpr

Tests moves from `root/Tests/` to `XRayCalc3/Tests/`. The `in` clause paths change as follows:

| Old `in` clause | New `in` clause | Reason |
|-----------------|----------------|--------|
| `'..\Math\math_complex.pas'` | `'..\..\Shared\Math\math_complex.pas'` | Math moved to Shared/ |
| `'..\Math\math_globals.pas'` | `'..\..\Shared\Math\math_globals.pas'` | " |
| `'..\Math\unit_SavitzkyGolay.pas'` | `'..\..\Shared\Math\unit_SavitzkyGolay.pas'` | " |
| `'..\Math\unit_materials.pas'` | `'..\..\Shared\Math\unit_materials.pas'` | " |
| `'..\Math\unit_calc.pas'` | `'..\..\Shared\Math\unit_calc.pas'` | " |
| `'..\Math\unit_ProfileCalc.pas'` | `'..\..\Shared\Math\unit_ProfileCalc.pas'` | " |
| `'..\Math\unit_materials_mix.pas'` | `'..\..\Shared\Math\unit_materials_mix.pas'` | " |
| `'..\Units\unit_Types.pas'` | `..\Units\unit_Types.pas` | Tests now sibling of Units under XRayCalc3/ |
| `'..\Units\unit_helpers.pas'` | `..\Units\unit_helpers.pas` | " |
| `'..\Units\unit_Config.pas'` | `..\Units\unit_Config.pas` | " |
| `'..\Units\unit_consts.pas'` | `..\Units\unit_consts.pas` | " |
| `'..\Units\unit_SmartLimits.pas'` | `..\Units\unit_SmartLimits.pas` | " |
| `'..\Components\unit_SMessages.pas'` | `..\Components\unit_SMessages.pas` | " |
| `'..\LFPSO\unit_LFPSO_Base.pas'` | `..\LFPSO\unit_LFPSO_Base.pas` | " |
| `'..\LFPSO\unit_LFPSO_Periodic.pas'` | `..\LFPSO\unit_LFPSO_Periodic.pas` | " |
| `'..\LFPSO\unit_LFPSO_Irregular.pas'` | `..\LFPSO\unit_LFPSO_Irregular.pas` | " |
| `'..\XRC_CMD\Units\cmd_unit_types.pas'` | `'..\..\XRC_CMD\Units\cmd_unit_types.pas'` | Extra `..` to reach root |
| `'..\XRC_CMD\Units\cmd_math_globals.pas'` | `'..\..\XRC_CMD\Units\cmd_math_globals.pas'` | " |
| `'..\Universal\unit_universal_types.pas'` | `'..\..\Shared\Universal\unit_universal_types.pas'` | Universal moved to Shared/ |
| `'..\Universal\unit_universal_templates.pas'` | `'..\..\Shared\Universal\unit_universal_templates.pas'` | " |
| `'..\Universal\unit_universal_io.pas'` | `'..\..\Shared\Universal\unit_universal_io.pas'` | " |
| `'..\Universal\unit_xrf_lines.pas'` | `'..\..\Shared\Universal\unit_xrf_lines.pas'` | " |
| `'..\Universal\unit_xrfx_package.pas'` | `'..\..\Shared\Universal\unit_xrfx_package.pas'` | " |

Note: `'..\Units\...'` and `'..\Components\...'` and `'..\LFPSO\...'` clauses already have the correct relative path because Tests is now a sibling under XRayCalc3/. The path changes from `root→root/X` (old: `'..\X\...'`) to `XRayCalc3/Tests→XRayCalc3/X` (new: still `'..\X\...'`). So these remain unchanged.

## Path Updates — XRayCalc3Tests.dproj

### Search path (Base)
```
Before: ..\math;..\units;..\LFPSO;..\components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(BDS)\source\DunitX;$(DCC_UnitSearchPath)
After:  ..\..\Shared\Math;..\Units;..\LFPSO;..\Components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;..\..\Shared\Universal;$(BDS)\source\DunitX;$(DCC_UnitSearchPath)
```

### DCCReference paths
| Old | New |
|-----|-----|
| `..\math\math_complex.pas` | `..\..\Shared\Math\math_complex.pas` |
| `..\math\math_globals.pas` | `..\..\Shared\Math\math_globals.pas` |
| `..\units\unit_Types.pas` | `..\Units\unit_Types.pas` |
| `..\units\unit_SeriesIO.pas` | `..\Units\unit_SeriesIO.pas` |
| `..\units\unit_DataProcessing.pas` | `..\Units\unit_DataProcessing.pas` |
| `..\units\unit_FileUtils.pas` | `..\Units\unit_FileUtils.pas` |
| `..\units\unit_helpers.pas` | `..\Units\unit_helpers.pas` |
| `..\units\unit_Config.pas` | `..\Units\unit_Config.pas` |
| `..\units\unit_consts.pas` | `..\Units\unit_consts.pas` |
| `..\math\unit_ProfileCalc.pas` | `..\..\Shared\Math\unit_ProfileCalc.pas` |
| `..\units\unit_SmartLimits.pas` | `..\Units\unit_SmartLimits.pas` |

---

## Path Updates — XRC3.groupproj

| Old path | New path |
|----------|----------|
| `XRayCalc3.dproj` | `XRayCalc3\XRayCalc3.dproj` |
| `components\XRayCalcVisualControls.dproj` | `XRayCalc3\Components\XRayCalcVisualControls.dproj` |

Both in `<Projects Include="...">` and in `<MSBuild Projects="..."/>` target entries.

---

## Path Updates — _Installer/deploy.sh

All `Assets/` references must become `XRayCalc3/Assets/`:

| Old path | New path |
|----------|----------|
| `$PROJECT_DIR/Assets/Docs/Help/UserManual.html` | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/UserManual.html` |
| `$PROJECT_DIR/Assets/Docs/Help/style.css` | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/style.css` |
| `$PROJECT_DIR/Assets/Docs/Help/script.js` | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/script.js` |
| `$PROJECT_DIR/Assets/Docs/Help/images` | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/images` |
| `$PROJECT_DIR/Assets/XRayCalc3_Icon.ico` | `$PROJECT_DIR/XRayCalc3/Assets/XRayCalc3_Icon.ico` |
| `$PROJECT_DIR/Assets/XRayCalc3_x64_Icon.ico` | `$PROJECT_DIR/XRayCalc3/Assets/XRayCalc3_x64_Icon.ico` |
| `$PROJECT_DIR/Assets/Docs/Help/UserManual.html` (copy) | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/UserManual.html` |
| `$PROJECT_DIR/Assets/Docs/Help/style.css` (copy) | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/style.css` |
| `$PROJECT_DIR/Assets/Docs/Help/script.js` (copy) | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/script.js` |
| `$PROJECT_DIR/Assets/Docs/Help/*.html` (copy) | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/*.html` |
| `$PROJECT_DIR/Assets/Docs/Help/images/*` (copy) | `$PROJECT_DIR/XRayCalc3/Assets/Docs/Help/images/*` |

The `_Installer/XRayCalc3Setup.iss` references only `deploy/` staging directory — no changes needed.

---

## .gitignore Updates

The existing `.gitignore` already has `__history` (line 25). Changes:
- Add `__recovery` (without trailing slash, matching existing `__history` style)
- Add `.superpowers/`
- Remove stale path-specific entries: `/forms/__recovery/frm_Main.dfm` and `/forms/__recovery/frm_Main.pas`

---

## CLAUDE.md Updates

- Update Architecture section to reflect new folder structure
- Update build commands: `XRayCalc3.dproj` → `XRayCalc3\XRayCalc3.dproj`
- Update test build: `Tests\XRayCalc3Tests.dproj` → `XRayCalc3\Tests\XRayCalc3Tests.dproj`
- Update test runner path: `Tests\_Out\BIN\XRayCalc3Tests.exe` → `XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe`
- Update output directory description

---

## Verification

After all moves and path updates:
1. Build XRayCalc3 Win64 Release
2. Build XRC_CMD Win64 Release
3. Build XRFCalc Win64 Release
4. Build XRCXPreview (via group project)
5. Build and run Tests (Win32 Debug)
6. Verify all 266 tests pass
