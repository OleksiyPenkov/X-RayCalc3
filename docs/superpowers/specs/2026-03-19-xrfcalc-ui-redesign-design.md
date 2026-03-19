# XRFCalc UI Redesign: Embed Run Configuration, Remove File Browser

## Summary

Replace the shell file browser in XRFCalc's left panel with the Run Configuration controls (currently in a separate modal dialog). File opening moves to a standard Open File dialog via toolbar button and File menu.

## Motivation

The shell file browser (breadcrumb bar, folder tree, file list) occupies the entire left panel but provides limited value — users can open files via the standard OS Open dialog. Meanwhile, the Run Configuration lives in a separate modal dialog that must be opened each time. Embedding the config directly in the left panel keeps it always visible and editable, reducing clicks and improving workflow.

## Current State

### Left Panel (MainSplitter upper-left, 30%)
- `ShellSplitter` (TRzSplitter, vertical) containing:
  - `JamShellBreadCrumbBar1` — path navigation
  - `ShellTree` (TJamShellTree) — folder hierarchy
  - `ShellList` (TJamShellList) — file list filtered to `*.xrfx`
- Connected via `JamShellLink1` (TJamShellLink)

### Run Configuration Dialog (frm_RunConfig)
- Modal TForm (480x420), shown by "New Run" / "Edit Run" toolbar buttons
- 4-tab TRzPageControl: Targets, Structure, Optimizer, Fitness
- Bottom button panel: Run, Save Config, Cancel
- All controls created at runtime in `FormCreate` via helper methods
- Public API: `SetDefaults`, `LoadFromConfig(Config)`, `BuildConfig: TUniversalConfig`

### Toolbar
- Refresh | Export Structure | Copy Data | Save Image | New Run | Edit Run | Stop

## Proposed Changes

### 1. Remove from Main Form

**Components to delete from DFM:**
- `ShellSplitter` (TRzSplitter) and all children
- `JamShellBreadCrumbBar1` (TJamShellBreadCrumbBar)
- `ShellTree` (TJamShellTree)
- `ShellList` (TJamShellList)
- `JamShellLink1` (TJamShellLink)

**Toolbar buttons to remove:**
- `btnRefresh` — no file browser to refresh
- `btnEditRun` — config is always visible, no separate edit action needed

**Uses to remove from frm_XRFCalcMain.pas:**
- `JamShellBreadCrumbBar, ShellControls, ShellLink`
- `Jam.Shell.Types, Jam.Shell.Controls.Types, Jam.Shell.Controls.BaseShellListView`

### 2. Convert frm_RunConfig to frame_RunConfig

**New file:** `XRFCalc/Views/frame_RunConfig.pas` + `.dfm`

- Change `TfrmRunConfig = class(TForm)` to `TfrmRunConfig = class(TFrame)`
- Remove `pnlButtons` panel (Run/Save/Cancel buttons) — actions handled via toolbar/menu
- Remove `BorderStyle`, `Caption`, `Position`, `PixelsPerInch` form properties
- Keep `PageControl` (TRzPageControl) with `Align = alClient`
- Keep all 4 tab sheets: `tabTargets`, `tabStructure`, `tabOptimizer`, `tabFitness`
- Keep all runtime control creation methods unchanged
- Keep public API: `SetDefaults`, `LoadFromConfig`, `BuildConfig`

**Layout adjustments for ~300px width:**

The current dialog uses these layout constants:
```pascal
LBL_WIDTH = 130;
COL2_LEFT = 250;
COL2_LBL  = 250;
COL2_EDIT = 360;
ROW_HEIGHT = 28;
```

New constants for narrow layout:
```pascal
LBL_WIDTH = 100;
EDIT_LEFT = 108;
EDIT_WIDTH = 70;
ROW_HEIGHT = 26;
```

Specific adjustments:
- **Range spins** (d min/max, Gamma min/max, N min/max): stack vertically (two rows per range) instead of side-by-side. Remove `CreateRangeSpin`; use two `CreateLabeledSpin` calls.
- **CheckListBoxes** (clbLines, clbPool, clbExcludedPairs): reduce `Columns` from 5/4 to 3
- **GroupBoxes** (Template, Henke): use `Align = alBottom` or compute width dynamically. Edit width reduced, browse button stays at right edge.
- **Fitness tab** two-column fields (DeltaTheta/ThetaMin, ScanPoints/ScanHalfRange): stack vertically
- **Structure tab** Sigma/DensityFactor: stack vertically

### 3. Embed frame_RunConfig in Main Form

**MainSplitter.UpperLeftControls:** Replace `ShellSplitter` with `FRunConfig` (TfrmRunConfig frame)

In `FormCreate`:
```pascal
FRunConfig := TfrmRunConfig.Create(Self);
FRunConfig.Parent := MainSplitter.Panes[0];  // UpperLeft pane
FRunConfig.Align := alClient;
FRunConfig.SetDefaults;
```

### 4. Add Open File Support

**New components on main form:**
- `dlgOpen: TOpenDialog` — Filter: `'XRFX package|*.xrfx'`, DefaultExt: `'xrfx'`

**New toolbar button:**
- `btnOpen: TToolButton` — Caption: 'Open', positioned first in toolbar
- New icon resource: `ICON_OPEN`

**New menu item:**
- `mnuOpen: TMenuItem` under `mnuFile`, before `mnuSave` — Caption: '&Open...', ShortCut: Ctrl+O

**Handler (`btnOpenClick` / `mnuOpenClick`):**
```pascal
procedure TfrmXRFCalcMain.btnOpenClick(Sender: TObject);
begin
  if not CheckUnsaved then Exit;
  if dlgOpen.Execute then
  begin
    ProcessFile(dlgOpen.FileName);
    // Also load config into the embedded frame if config.json exists
    LoadConfigFromXRFX(dlgOpen.FileName);
  end;
end;
```

### 5. Update Run Logic

**btnNewRunClick changes:**
```pascal
procedure TfrmXRFCalcMain.btnNewRunClick(Sender: TObject);
var
  Config: TUniversalConfig;
  ConfigPath, RunTempDir: string;
begin
  // Read config directly from embedded frame (no dialog)
  Config := FRunConfig.BuildConfig;

  RunTempDir := TPath.Combine(TPath.GetTempPath, 'XRFCalc\run_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(RunTempDir);
  Config.OutputDir := TPath.Combine(RunTempDir, TEMP_OUTPUT_DIR);

  ConfigPath := TPath.Combine(RunTempDir,
    'xrfcalc_' + FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '.json');
  TUniversalIO.SaveConfig(Config, ConfigPath);

  FSavePath := '';
  StartRun(ConfigPath, Config.Optimizer.Iterations);
end;
```

**Remove btnEditRunClick** — no longer needed. When a file is opened, its config is loaded into the frame automatically.

**New helper — LoadConfigFromXRFX:**
```pascal
procedure TfrmXRFCalcMain.LoadConfigFromXRFX(const FileName: string);
var
  TempDir, ConfigJsonPath: string;
  Config: TUniversalConfig;
begin
  TempDir := FLoader.GetResult(0).TempDir;
  ConfigJsonPath := TPath.Combine(TempDir, 'config.json');
  if TFile.Exists(ConfigJsonPath) then
  begin
    Config := TUniversalIO.LoadConfig(ConfigJsonPath);
    FRunConfig.LoadFromConfig(Config);
  end;
end;
```

### 6. Update SaveSettings / LoadSettings

Remove ShellSplitter percent persistence. Remove `ShellList.Path` persistence. Keep MainSplitter percent.

Replace `ShellList.Path` references in `mnuSaveClick` with `ExtractFilePath(FSavePath)`.

### 7. Save Config Menu Item

Add `mnuSaveConfig` under File menu (or Tools menu) to replace the dialog's "Save Config..." button:
```pascal
procedure TfrmXRFCalcMain.mnuSaveConfigClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Config: TUniversalConfig;
begin
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Filter := 'JSON config|*.json';
    Dlg.DefaultExt := 'json';
    if Dlg.Execute then
    begin
      Config := FRunConfig.BuildConfig;
      TUniversalIO.SaveConfig(Config, Dlg.FileName);
    end;
  finally
    Dlg.Free;
  end;
end;
```

## Files Changed

| File | Action |
|------|--------|
| `XRFCalc/Forms/frm_XRFCalcMain.pas` | Remove shell components, add Open/Run logic, embed frame |
| `XRFCalc/Forms/frm_XRFCalcMain.dfm` | Remove shell controls, add dlgOpen, update toolbar/menu |
| `XRFCalc/Forms/frm_RunConfig.pas` | Convert TForm to TFrame, remove buttons, adjust layout |
| `XRFCalc/Forms/frm_RunConfig.dfm` | Convert to frame DFM, remove button panel |
| `XRFCalc/XRFCalc.dproj` | Update file references (move frm_RunConfig to Views/) |
| `XRFCalc/XRFCalc.dpr` | Update uses clause |

The file `frm_RunConfig.*` will be moved to `XRFCalc/Views/frame_RunConfig.*` to follow the project's convention of frames in Views/.

## Dependencies Removed

- JamShell components (`JamShellBreadCrumbBar`, `ShellControls`, `ShellLink`, `Jam.Shell.*` units) — no longer needed by XRFCalc main form

## Testing

- Open .xrfx file via toolbar Open button and File > Open menu
- Open .xrfx file via command-line argument (double-click in Explorer)
- Verify config loads into left panel when opening a file with config.json
- New Run: verify config is read from embedded frame
- Save Config: verify JSON output matches the frame state
- Verify all 4 config tabs display correctly at ~300px width
- Verify splitter resizing works
- Verify Save/SaveAs still work without ShellList references
