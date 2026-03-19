# XRFCalc UI Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace XRFCalc's shell file browser with an embedded Run Configuration panel, and open files via standard Open dialog.

**Architecture:** Convert `frm_RunConfig` from a modal TForm to a TFrame embedded in the main form's left splitter pane. Remove all JamShell file browser components. Add Open File via toolbar button and File menu. Remove multi-file Compare feature (no longer needed without file browser selection).

**Tech Stack:** Delphi Object Pascal, RAD Studio 37.0, VCL, RaizeComponents (TRzSplitter, TRzPageControl, TRzBitBtn), JamShell (removed)

**Spec:** `docs/superpowers/specs/2026-03-19-xrfcalc-ui-redesign-design.md`

**Build command:**
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

---

### Task 1: Convert frm_RunConfig from TForm to TFrame

**Files:**
- Modify: `XRFCalc/Forms/frm_RunConfig.pas`
- Modify: `XRFCalc/Forms/frm_RunConfig.dfm`

This task converts the dialog to a frame in-place. Task 6 will move the files to Views/.

- [ ] **Step 1: Update the DFM**

Replace the entire DFM content. Change `object frmRunConfig: TfrmRunConfig` to `object frmRunConfig: TfrmRunConfig` (same name, but frame properties). Remove form-specific properties (`BorderStyle`, `Caption`, `Position`, `PixelsPerInch`, `OnCreate`). Remove the `pnlButtons` panel and all its children (`btnRun`, `btnSaveConfig`, `btnCancel`). Keep `PageControl` with `Align = alClient`.

New DFM content:
```
object frmRunConfig: TfrmRunConfig
  Left = 0
  Top = 0
  Width = 300
  Height = 500
  Align = alClient
  TabOrder = 0
  object PageControl: TRzPageControl
    Left = 0
    Top = 0
    Width = 300
    Height = 500
    ActivePage = tabTargets
    Align = alClient
    TabOrder = 0
    FixedDimension = 21
    object tabTargets: TRzTabSheet
      Caption = 'Targets'
    end
    object tabStructure: TRzTabSheet
      Caption = 'Structure'
    end
    object tabOptimizer: TRzTabSheet
      Caption = 'Optimizer'
    end
    object tabFitness: TRzTabSheet
      Caption = 'Fitness'
    end
  end
end
```

- [ ] **Step 2: Update the PAS — class declaration**

In `frm_RunConfig.pas`, change the class declaration:

Replace:
```pascal
  TfrmRunConfig = class(TForm)
    pnlButtons: TRzPanel;
    btnRun: TRzBitBtn;
    btnSaveConfig: TRzBitBtn;
    btnCancel: TRzBitBtn;
    PageControl: TRzPageControl;
    tabTargets: TRzTabSheet;
    tabStructure: TRzTabSheet;
    tabOptimizer: TRzTabSheet;
    tabFitness: TRzTabSheet;
    procedure FormCreate(Sender: TObject);
    procedure btnSaveConfigClick(Sender: TObject);
```

With:
```pascal
  TfrmRunConfig = class(TFrame)
    PageControl: TRzPageControl;
    tabTargets: TRzTabSheet;
    tabStructure: TRzTabSheet;
    tabOptimizer: TRzTabSheet;
    tabFitness: TRzTabSheet;
```

- [ ] **Step 3: Update the PAS — initialization**

Replace the `FormCreate` procedure with `AfterConstruction` override. Add to the `public` section:

```pascal
  public
    procedure AfterConstruction; override;
    procedure SetDefaults;
    procedure LoadFromConfig(const Config: TUniversalConfig);
    function  BuildConfig: TUniversalConfig;
```

In the implementation, rename `FormCreate`:
```pascal
procedure TfrmRunConfig.AfterConstruction;
begin
  inherited;
  CreateTargetsTab;
  CreateStructureTab;
  CreateOptimizerTab;
  CreateFitnessTab;
end;
```

- [ ] **Step 4: Remove btnSaveConfigClick**

Delete the `btnSaveConfigClick` procedure declaration from the class and its implementation body. This functionality moves to the main form's menu (Task 5).

- [ ] **Step 5: Update uses clause**

In the `uses` clause, replace `Vcl.Forms` with `Vcl.Controls` (TFrame is in Controls, not Forms). Keep `Vcl.Forms` only if needed by other code in the unit — check if `TOpenDialog` or `SelectDirectory` need it. `SelectDirectory` is in `Vcl.FileCtrl` (already listed). `TOpenDialog` is in `Vcl.Dialogs` (already listed). So `Vcl.Forms` can be removed from the interface uses.

- [ ] **Step 6: Commit**

```
git add XRFCalc/Forms/frm_RunConfig.pas XRFCalc/Forms/frm_RunConfig.dfm
git commit -m "* Convert frm_RunConfig from TForm to TFrame"
```

---

### Task 2: Adjust frame_RunConfig layout for narrow width

**Files:**
- Modify: `XRFCalc/Forms/frm_RunConfig.pas`

- [ ] **Step 1: Update layout constants**

Replace:
```pascal
const
  LBL_WIDTH = 130;
  COL2_LEFT = 250;
  COL2_LBL  = 250;
  COL2_EDIT = 360;
  ROW_HEIGHT = 28;
```

With:
```pascal
const
  LBL_WIDTH = 100;
  EDIT_LEFT = 108;
  EDIT_WIDTH = 70;
  ROW_HEIGHT = 26;
```

- [ ] **Step 2: Update CreateLabeledEdit**

Change `Result.Left := LBL_WIDTH;` to `Result.Left := EDIT_LEFT;` and set `Result.Width := EDIT_WIDTH;` (previously used the `AWidth` param which defaulted to 80). Keep the `AWidth` parameter for cases that need a different width.

- [ ] **Step 3: Update CreateLabeledSpin**

Change `Result.Left := LBL_WIDTH;` to `Result.Left := EDIT_LEFT;` and `Result.Width := 80;` to `Result.Width := EDIT_WIDTH;`.

- [ ] **Step 4: Replace CreateRangeSpin with stacked calls**

Delete the `CreateRangeSpin` method entirely (declaration and implementation).

Update `CreateStructureTab` to use two `CreateLabeledSpin` calls per range:
```pascal
procedure TfrmRunConfig.CreateStructureTab;
var
  Row: Integer;
  grp: TGroupBox;
begin
  Row := 10;
  sedDMin := CreateLabeledSpin(tabStructure, Row, 'd min (A)', 10, 500, 30);
  Inc(Row, ROW_HEIGHT);
  sedDMax := CreateLabeledSpin(tabStructure, Row, 'd max (A)', 10, 500, 80);
  Inc(Row, ROW_HEIGHT + 4);
  sedGammaMin := CreateLabeledSpin(tabStructure, Row, 'Gamma min (x100)', 1, 99, 15);
  Inc(Row, ROW_HEIGHT);
  sedGammaMax := CreateLabeledSpin(tabStructure, Row, 'Gamma max (x100)', 1, 99, 70);
  Inc(Row, ROW_HEIGHT + 4);
  sedNMin := CreateLabeledSpin(tabStructure, Row, 'N min', 1, 1000, 40);
  Inc(Row, ROW_HEIGHT);
  sedNMax := CreateLabeledSpin(tabStructure, Row, 'N max', 1, 1000, 200);
  Inc(Row, ROW_HEIGHT + 8);

  edtSigma := CreateLabeledEdit(tabStructure, Row, 'Sigma (A)');
  edtSigma.Text := '3.5';
  Inc(Row, ROW_HEIGHT);

  edtDensityFactor := CreateLabeledEdit(tabStructure, Row, 'Density factor');
  edtDensityFactor.Text := '0.95';
  Inc(Row, ROW_HEIGHT);

  edtSubstrate := CreateLabeledEdit(tabStructure, Row, 'Substrate');
  edtSubstrate.Text := 'SiO2';
  Inc(Row, ROW_HEIGHT);

  chkPureElements := TCheckBox.Create(Self);
  chkPureElements.Parent := tabStructure;
  chkPureElements.Left := 8; chkPureElements.Top := Row;
  chkPureElements.Width := 200;
  chkPureElements.Caption := 'Pure elements (no mixing)';
  chkPureElements.Checked := True;
  Inc(Row, ROW_HEIGHT + 8);

  // Template
  grp := TGroupBox.Create(Self);
  grp.Parent := tabStructure;
  grp.Left := 8; grp.Top := Row; grp.Width := 270; grp.Height := 50;
  grp.Caption := 'Template File';

  edtTemplate := TEdit.Create(Self);
  edtTemplate.Parent := grp;
  edtTemplate.Left := 8; edtTemplate.Top := 20;
  edtTemplate.Width := 210;

  btnBrowseTemplate := TButton.Create(Self);
  btnBrowseTemplate.Parent := grp;
  btnBrowseTemplate.Left := 225; btnBrowseTemplate.Top := 18;
  btnBrowseTemplate.Width := 35; btnBrowseTemplate.Height := 25;
  btnBrowseTemplate.Caption := '...';
  btnBrowseTemplate.OnClick := BrowseTemplateClick;
end;
```

Remove `CreateRangeSpin` from the private declaration as well.

- [ ] **Step 5: Update CreateTargetsTab for narrower width**

Change CheckListBox columns and GroupBox widths:
```pascal
procedure TfrmRunConfig.CreateTargetsTab;
var
  grp: TGroupBox;
  Elements: TArray<string>;
  i: Integer;
  Lbl: TLabel;
begin
  // XRF Lines
  grp := TGroupBox.Create(Self);
  grp.Parent := tabTargets;
  grp.Left := 4; grp.Top := 4; grp.Width := 270; grp.Height := 110;
  grp.Caption := 'Target XRF Lines';

  clbLines := TCheckListBox.Create(Self);
  clbLines.Parent := grp;
  clbLines.Align := alClient;
  clbLines.AlignWithMargins := True;
  clbLines.Columns := 3;
  Elements := TArray<string>.Create(
    'Li', 'Be', 'B', 'C', 'N', 'O', 'F', 'Ne', 'Na', 'Mg', 'Al', 'Si');
  for i := 0 to High(Elements) do
    clbLines.Items.Add(Elements[i]);

  // Element Pool
  grp := TGroupBox.Create(Self);
  grp.Parent := tabTargets;
  grp.Left := 4; grp.Top := 120; grp.Width := 270; grp.Height := 110;
  grp.Caption := 'Element Pool';

  clbPool := TCheckListBox.Create(Self);
  clbPool.Parent := grp;
  clbPool.Align := alClient;
  clbPool.AlignWithMargins := True;
  clbPool.Columns := 3;
  Elements := TArray<string>.Create('W', 'Mo', 'Cr', 'Si', 'B', 'B4C',
    'Sc', 'C', 'Ni', 'Co', 'La', 'Pt', 'Ru', 'V', 'Ti', 'Nb');
  for i := 0 to High(Elements) do
    clbPool.Items.Add(Elements[i]);

  // Excluded Pairs
  Lbl := TLabel.Create(Self);
  Lbl.Parent := tabTargets;
  Lbl.Left := 4; Lbl.Top := 238;
  Lbl.Caption := 'Excluded pairs:';

  clbExcludedPairs := TCheckListBox.Create(Self);
  clbExcludedPairs.Parent := tabTargets;
  clbExcludedPairs.Left := 4; clbExcludedPairs.Top := 256;
  clbExcludedPairs.Width := 270; clbExcludedPairs.Height := 88;
  clbExcludedPairs.Columns := 3;
end;
```

- [ ] **Step 6: Update CreateOptimizerTab — stack two-column fields**

Replace the method:
```pascal
procedure TfrmRunConfig.CreateOptimizerTab;
var
  Row: Integer;
begin
  Row := 10;
  sedPopulation := CreateLabeledSpin(tabOptimizer, Row, 'Population', 10, 10000, 1000);
  Inc(Row, ROW_HEIGHT);
  sedIterations := CreateLabeledSpin(tabOptimizer, Row, 'Iterations', 1, 10000, 100);
  Inc(Row, ROW_HEIGHT);
  sedStagnation := CreateLabeledSpin(tabOptimizer, Row, 'Stagnation limit', 1, 10000, 200);
  Inc(Row, ROW_HEIGHT + 8);

  edtW1 := CreateLabeledEdit(tabOptimizer, Row, 'PSO w1');
  edtW1.Text := '0.4';
  Inc(Row, ROW_HEIGHT);
  edtW2 := CreateLabeledEdit(tabOptimizer, Row, 'PSO w2');
  edtW2.Text := '0.5';
  Inc(Row, ROW_HEIGHT);

  edtTolerance := CreateLabeledEdit(tabOptimizer, Row, 'Tolerance');
  edtTolerance.Text := '1e-5';
  Inc(Row, ROW_HEIGHT + 4);

  sedJammingMax := CreateLabeledSpin(tabOptimizer, Row, 'Jamming max', 1, 100, 5);
  Inc(Row, ROW_HEIGHT);
  sedCheckpointEvery := CreateLabeledSpin(tabOptimizer, Row, 'Checkpoint every', 1, 10000, 100);
end;
```

- [ ] **Step 7: Update CreateFitnessTab — stack two-column fields**

Replace the method:
```pascal
procedure TfrmRunConfig.CreateFitnessTab;
var
  Row: Integer;
  Lbl: TLabel;
  grp: TGroupBox;
begin
  Row := 10;
  edtWR := CreateLabeledEdit(tabFitness, Row, 'w_R'); edtWR.Text := '1.0';
  Inc(Row, ROW_HEIGHT);
  edtWFWHM := CreateLabeledEdit(tabFitness, Row, 'w_FWHM'); edtWFWHM.Text := '0.1';
  Inc(Row, ROW_HEIGHT);
  edtWPurity := CreateLabeledEdit(tabFitness, Row, 'w_purity'); edtWPurity.Text := '1.0';
  Inc(Row, ROW_HEIGHT);
  edtRMinThreshold := CreateLabeledEdit(tabFitness, Row, 'R_min threshold');
  edtRMinThreshold.Text := '0.001';
  Inc(Row, ROW_HEIGHT + 8);

  edtDeltaTheta := CreateLabeledEdit(tabFitness, Row, 'Delta theta (deg)');
  edtDeltaTheta.Text := '0';
  Inc(Row, ROW_HEIGHT);
  edtThetaMin := CreateLabeledEdit(tabFitness, Row, 'Theta min (deg)');
  edtThetaMin.Text := '0';
  Inc(Row, ROW_HEIGHT);

  Lbl := TLabel.Create(Self);
  Lbl.Parent := tabFitness;
  Lbl.Left := 8; Lbl.Top := Row + 4;
  Lbl.Caption := 'Polarization';
  cmbPolarization := TComboBox.Create(Self);
  cmbPolarization.Parent := tabFitness;
  cmbPolarization.Left := EDIT_LEFT; cmbPolarization.Top := Row;
  cmbPolarization.Width := EDIT_WIDTH; cmbPolarization.Style := csDropDownList;
  cmbPolarization.Items.Add('sp'); cmbPolarization.Items.Add('s');
  cmbPolarization.ItemIndex := 0;
  Inc(Row, ROW_HEIGHT + 8);

  sedScanPoints := CreateLabeledSpin(tabFitness, Row, 'Scan points', 0, 10000, 0);
  Inc(Row, ROW_HEIGHT);
  edtScanHalfRange := CreateLabeledEdit(tabFitness, Row, 'Scan half-range');
  edtScanHalfRange.Text := '0';
  Inc(Row, ROW_HEIGHT + 8);

  // Henke path
  grp := TGroupBox.Create(Self);
  grp.Parent := tabFitness;
  grp.Left := 4; grp.Top := Row; grp.Width := 270; grp.Height := 50;
  grp.Caption := 'Henke Database Path';

  edtHenkePath := TEdit.Create(Self);
  edtHenkePath.Parent := grp;
  edtHenkePath.Left := 8; edtHenkePath.Top := 20;
  edtHenkePath.Width := 210;
  edtHenkePath.Text := 'D:\DelphiProjects\X-RayCalc\Henke';

  btnBrowseHenke := TButton.Create(Self);
  btnBrowseHenke.Parent := grp;
  btnBrowseHenke.Left := 225; btnBrowseHenke.Top := 18;
  btnBrowseHenke.Width := 35; btnBrowseHenke.Height := 25;
  btnBrowseHenke.Caption := '...';
  btnBrowseHenke.OnClick := BrowseHenkeClick;
end;
```

- [ ] **Step 8: Commit**

```
git add XRFCalc/Forms/frm_RunConfig.pas
git commit -m "* Adjust frame_RunConfig layout for narrow left panel"
```

---

### Task 3: Move frame_RunConfig to Views/

**Files:**
- Move: `XRFCalc/Forms/frm_RunConfig.pas` -> `XRFCalc/Views/frame_RunConfig.pas`
- Move: `XRFCalc/Forms/frm_RunConfig.dfm` -> `XRFCalc/Views/frame_RunConfig.dfm`
- Modify: `XRFCalc/XRFCalc.dpr`

- [ ] **Step 1: Rename and move files**

```bash
git mv XRFCalc/Forms/frm_RunConfig.pas XRFCalc/Views/frame_RunConfig.pas
git mv XRFCalc/Forms/frm_RunConfig.dfm XRFCalc/Views/frame_RunConfig.dfm
```

- [ ] **Step 2: Update unit name**

In `frame_RunConfig.pas`, change `unit frm_RunConfig;` to `unit frame_RunConfig;`.

- [ ] **Step 3: Update XRFCalc.dpr**

Change the uses clause entry:
```pascal
  frm_RunConfig in 'Forms\frm_RunConfig.pas' {frmRunConfig},
```
To:
```pascal
  frame_RunConfig in 'Views\frame_RunConfig.pas' {frmRunConfig: TFrame},
```

- [ ] **Step 4: Commit**

```
git add XRFCalc/Views/frame_RunConfig.pas XRFCalc/Views/frame_RunConfig.dfm XRFCalc/XRFCalc.dpr
git commit -m "* Move frame_RunConfig to Views/ directory"
```

---

### Task 4: Update icon resources

**Files:**
- Modify: `XRFCalc/XRFCalcIcons.rc`

An Open icon asset is needed. Since we don't have a graphic design tool, we'll reuse an existing approach or create a placeholder.

- [ ] **Step 1: Update the .rc file**

Remove `ICON_REFRESH` and `ICON_EDITRUN`, add `ICON_OPEN`. Renumber assets:

```
ICON_OPEN RCDATA "Assets\\00_Open.png"
ICON_EXPORT RCDATA "Assets\\01_ExportStructure.png"
ICON_COPY RCDATA "Assets\\02_CopyData.png"
ICON_SAVEIMG RCDATA "Assets\\03_SaveImage.png"
ICON_NEWRUN RCDATA "Assets\\04_NewRun.png"
ICON_STOP RCDATA "Assets\\06_Stop.png"
```

- [ ] **Step 2: Create placeholder Open icon**

Create a simple 32x32 PNG for the Open button. Use Python to generate it:
```bash
python -c "
from PIL import Image, ImageDraw
img = Image.new('RGBA', (32, 32), (0,0,0,0))
d = ImageDraw.Draw(img)
# Simple folder-open icon shape
d.rectangle([4,10,28,28], fill=(100,160,220), outline=(60,120,180), width=2)
d.polygon([(4,10),(10,4),(22,4),(28,10)], fill=(120,180,240), outline=(60,120,180))
img.save('XRFCalc/Assets/00_Open.png')
"
```

If PIL is not available, copy an existing icon as placeholder:
```bash
cp XRFCalc/Assets/01_ExportStructure.png XRFCalc/Assets/00_Open.png
```

- [ ] **Step 3: Delete unused icon files**

```bash
rm XRFCalc/Assets/00_Refresh.png XRFCalc/Assets/05_EditRun.png
```

- [ ] **Step 4: Rebuild .RES from .rc**

```bash
cmd.exe //c "\"C:\Program Files (x86)\Embarcadero\Studio\37.0\bin\brcc32.exe\" XRFCalc\XRFCalcIcons.rc" 2>&1
```

If brcc32 is not on PATH, the build will regenerate from the .rc file automatically.

- [ ] **Step 5: Commit**

```
git add XRFCalc/XRFCalcIcons.rc XRFCalc/XRFCalcIcons.RES XRFCalc/Assets/
git commit -m "* Update toolbar icon resources: add Open, remove Refresh/EditRun"
```

---

### Task 5: Update main form DFM — remove shell, add Open dialog

**Files:**
- Modify: `XRFCalc/Forms/frm_XRFCalcMain.dfm`

- [ ] **Step 1: Remove shell components from DFM**

Delete these entire blocks from the DFM:
- The `ShellSplitter` object and all its children (`JamShellBreadCrumbBar1`, `ShellTree`, `ShellList`)
- The `JamShellLink1` object

- [ ] **Step 2: Remove toolbar buttons from DFM**

Delete these objects from inside `ToolBar1`:
- `btnRefresh` (the TToolButton for Refresh)
- `btnEditRun` (the TToolButton for Edit Run)

- [ ] **Step 3: Add btnOpen to toolbar**

Add as first button in `ToolBar1`, before `btnExportStructure`:
```
    object btnOpen: TToolButton
      Left = 0
      Top = 0
      Hint = 'Open .xrfx file'
      Caption = 'Open'
      ImageIndex = 0
      OnClick = btnOpenClick
    end
    object tbSep0: TToolButton
      Left = 91
      Top = 0
      Width = 8
      Style = tbsSeparator
    end
```

- [ ] **Step 4: Update ImageIndex values on remaining toolbar buttons**

After removing Refresh (was index 0) and EditRun (was index 5), the new icon order is:
- 0: ICON_OPEN (btnOpen)
- 1: ICON_EXPORT (btnExportStructure)
- 2: ICON_COPY (btnCopyData)
- 3: ICON_SAVEIMG (btnSaveImage)
- 4: ICON_NEWRUN (btnNewRun)
- 5: ICON_STOP (btnStop)

Update `ImageIndex` on each remaining button:
- `btnOpen`: ImageIndex = 0
- `btnExportStructure`: ImageIndex = 1
- `btnCopyData`: ImageIndex = 2
- `btnSaveImage`: ImageIndex = 3
- `btnNewRun`: ImageIndex = 4
- `btnStop`: ImageIndex = 5

- [ ] **Step 5: Update MainSplitter UpperLeftControls**

Change:
```
    UpperLeftControls = (
      ShellSplitter)
```
To an empty list (frame will be parented at runtime):
```
    UpperLeftControls = ()
```

- [ ] **Step 6: Add dlgOpen and mnuOpen to DFM**

Add the open dialog component:
```
  object dlgOpen: TOpenDialog
    DefaultExt = 'xrfx'
    Filter = 'XRFX package|*.xrfx'
    Title = 'Open XRF Results'
    Left = 552
    Top = 328
  end
```

Add `mnuOpen` menu item under `mnuFile`, before `mnuSave`:
```
      object mnuOpen: TMenuItem
        Caption = '&Open...'
        ShortCut = 16463
        OnClick = mnuOpenClick
      end
```

Also add `mnuSaveConfig` after `mnuSaveAs`:
```
      object mnuSaveConfig: TMenuItem
        Caption = 'Save Config...'
        OnClick = mnuSaveConfigClick
      end
```

- [ ] **Step 7: Remove tabCompare from DFM**

Delete:
```
      object tabCompare: TRzTabSheet
        Color = 15987699
        TabVisible = False
        Caption = 'Compare'
      end
```

- [ ] **Step 8: Commit**

```
git add XRFCalc/Forms/frm_XRFCalcMain.dfm
git commit -m "* Update main form DFM: remove shell, add Open dialog and menu"
```

---

### Task 6: Update main form PAS — remove shell, add Open/Config logic

**Files:**
- Modify: `XRFCalc/Forms/frm_XRFCalcMain.pas`

- [ ] **Step 1: Update uses clause**

In the `interface` uses, remove:
```pascal
  JamShellBreadCrumbBar, ShellControls, ShellLink,
  Jam.Shell.Types, Jam.Shell.Controls.Types,
  Jam.Shell.Controls.BaseShellListView,
```

Remove `frame_CompareView` from the interface uses clause (line 18).

Add `frame_RunConfig` to the interface uses (since we need the type for the `FRunConfig` field).

In the `implementation` uses, remove `frm_RunConfig` (it's now `frame_RunConfig` in the interface uses).

- [ ] **Step 2: Update class declaration — remove shell fields**

Remove these from the published/DFM section:
```pascal
    ShellSplitter: TRzSplitter;
    ShellTree: TJamShellTree;
    ShellList: TJamShellList;
    JamShellLink1: TJamShellLink;
    JamShellBreadCrumbBar1: TJamShellBreadCrumbBar;
    btnRefresh: TToolButton;
    btnEditRun: TToolButton;
    tabCompare: TRzTabSheet;
```

Remove event handler declarations:
```pascal
    procedure ShellListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnEditRunClick(Sender: TObject);
```

Add new declarations:
```pascal
    btnOpen: TToolButton;
    tbSep0: TToolButton;
    dlgOpen: TOpenDialog;
    mnuOpen: TMenuItem;
    mnuSaveConfig: TMenuItem;
    procedure btnOpenClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuSaveConfigClick(Sender: TObject);
```

- [ ] **Step 3: Update private fields**

Remove:
```pascal
    FCompareView: TframeCompareView;
```

Add:
```pascal
    FRunConfig: TfrmRunConfig;
    procedure LoadConfigFromXRFX(const FileName: string);
```

- [ ] **Step 4: Update FormCreate — embed frame, remove shell**

Remove these lines:
```pascal
  FCompareView := TframeCompareView.Create(Self);
  FCompareView.Parent := tabCompare;
  FCompareView.Align := alClient;

  tabCompare.TabVisible := False;
```

Add after the existing frame creation block:
```pascal
  FRunConfig := TfrmRunConfig.Create(Self);
  FRunConfig.Parent := MainSplitter.Panes[0];
  FRunConfig.Align := alClient;
  FRunConfig.SetDefaults;
```

Update `PostMessage` condition — change from checking `FInitialPath` to `FInitialFile`:
```pascal
  if FInitialFile <> '' then
    PostMessage(Handle, WM_USER + 100, 0, 0);
```

- [ ] **Step 5: Update LoadToolBarIcons**

Change `ResNames` array:
```pascal
const
  ResNames: array[0..5] of string = (
    'ICON_OPEN', 'ICON_EXPORT', 'ICON_COPY', 'ICON_SAVEIMG',
    'ICON_NEWRUN', 'ICON_STOP');
```

- [ ] **Step 6: Add btnOpenClick / mnuOpenClick handlers**

```pascal
procedure TfrmXRFCalcMain.btnOpenClick(Sender: TObject);
begin
  if not CheckUnsaved then Exit;
  if FInitialPath <> '' then
    dlgOpen.InitialDir := FInitialPath;
  if dlgOpen.Execute then
  begin
    ProcessFile(dlgOpen.FileName);
    LoadConfigFromXRFX(dlgOpen.FileName);
    FInitialPath := ExtractFilePath(dlgOpen.FileName);
  end;
end;

procedure TfrmXRFCalcMain.mnuOpenClick(Sender: TObject);
begin
  btnOpenClick(Sender);
end;
```

- [ ] **Step 7: Add LoadConfigFromXRFX**

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
  end
  else
    FRunConfig.SetDefaults;
end;
```

- [ ] **Step 8: Add mnuSaveConfigClick**

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

- [ ] **Step 9: Update btnNewRunClick — read from embedded frame**

Replace entire method:
```pascal
procedure TfrmXRFCalcMain.btnNewRunClick(Sender: TObject);
var
  Config: TUniversalConfig;
  ConfigPath, RunTempDir: string;
begin
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

- [ ] **Step 10: Delete removed methods**

Delete these entire method implementations:
- `ShellListSelectItem`
- `btnRefreshClick`
- `btnEditRunClick`
- `ProcessMultipleFiles`

- [ ] **Step 11: Update UpdateRunState**

Remove `btnEditRun.Enabled` line:
```pascal
procedure TfrmXRFCalcMain.UpdateRunState;
var
  Running: Boolean;
begin
  Running := FRunner.State = rsRunning;
  btnNewRun.Enabled := not Running;
  btnStop.Visible := Running;
end;
```

- [ ] **Step 12: Update WMDeferredNavigate**

Replace:
```pascal
procedure TfrmXRFCalcMain.WMDeferredNavigate(var Msg: TMessage);
begin
  if (FInitialPath <> '') and TDirectory.Exists(FInitialPath) then
    ShellList.Path := FInitialPath;
  if (FInitialFile <> '') and TFile.Exists(FInitialFile) then
    ProcessFile(FInitialFile);
end;
```

With:
```pascal
procedure TfrmXRFCalcMain.WMDeferredNavigate(var Msg: TMessage);
begin
  if (FInitialFile <> '') and TFile.Exists(FInitialFile) then
  begin
    ProcessFile(FInitialFile);
    LoadConfigFromXRFX(FInitialFile);
  end;
end;
```

- [ ] **Step 13: Update SaveSettings**

Replace:
```pascal
    Ini.WriteString('General', 'LastFolder', ShellList.Path);
    Ini.WriteInteger('Splitters', 'MainPct', MainSplitter.Percent);
    Ini.WriteInteger('Splitters', 'ShellPct', ShellSplitter.Percent);
```

With:
```pascal
    if FSavePath <> '' then
      Ini.WriteString('General', 'LastFolder', ExtractFilePath(FSavePath))
    else if FInitialPath <> '' then
      Ini.WriteString('General', 'LastFolder', FInitialPath);
    Ini.WriteInteger('Splitters', 'MainPct', MainSplitter.Percent);
```

- [ ] **Step 14: Update LoadSettings**

Remove the ShellSplitter line:
```pascal
    V := Ini.ReadInteger('Splitters', 'ShellPct', 0);
    if V > 0 then ShellSplitter.Percent := V;
```

- [ ] **Step 15: Update mnuSaveClick — remove ShellList references**

In `mnuSaveClick`, the fallback when `FSavePath` is empty should force Save As instead of silently doing nothing. Replace the entire else branch:
```pascal
  if FSavePath <> '' then
    DestPath := FSavePath
  else
  begin
    mnuSaveAsClick(Sender);
    Exit;
  end;
```

Remove:
```pascal
  ShellList.FullRefresh;
```

- [ ] **Step 16: Update mnuSaveAsClick — remove ShellList references**

Replace:
```pascal
  dlgSave.InitialDir := ShellList.Path;
```
With:
```pascal
  dlgSave.InitialDir := ExtractFilePath(FSavePath);
```

Remove:
```pascal
    ShellList.FullRefresh;
```

- [ ] **Step 17: Remove Compare references from ProcessFile and HandleCompleted**

In `ProcessFile`, remove:
```pascal
    tabCompare.TabVisible := False;
```

In `HandleCompleted`, remove:
```pascal
      tabCompare.TabVisible := False;
```

- [ ] **Step 18: Commit**

```
git add XRFCalc/Forms/frm_XRFCalcMain.pas
git commit -m "* Update main form: embed RunConfig frame, remove shell browser"
```

---

### Task 7: Update XRFCalc.dpr — remove CompareView

**Files:**
- Modify: `XRFCalc/XRFCalc.dpr`

- [ ] **Step 1: Remove CompareView from uses**

Remove:
```pascal
  frame_CompareView in 'Views\frame_CompareView.pas' {frameCompareView: TFrame},
```

The `frame_RunConfig` line was already updated in Task 3.

- [ ] **Step 2: Commit**

```
git add XRFCalc/XRFCalc.dpr
git commit -m "* Remove CompareView from XRFCalc.dpr"
```

---

### Task 8: Build and verify

- [ ] **Step 1: Build XRFCalc Win64 Release**

```bash
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: Build succeeds with 0 errors.

- [ ] **Step 2: Fix any compile errors**

If errors occur, they will likely be:
- Missing unit references (fix uses clauses)
- Undeclared identifiers from removed components (ensure all shell references deleted)
- DFM/PAS mismatch (ensure published fields match DFM exactly)

- [ ] **Step 3: Commit any fixes**

```
git add -A
git commit -m "* Fix build errors from UI redesign"
```
