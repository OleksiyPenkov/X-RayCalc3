# Stale Fit-Generated Extensions Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** When the user presses Run Fitting on a model that still carries extensions created by a previous fitting run, ask whether to clear them, keep them, or cancel the run.

**Architecture:** A runtime-only `FromFit` flag on the `prExtension` branch of `TProjectData` marks extensions the fitter created. `TfrmProjectPanel` gains `HasFitExtensions` / `ClearFitExtensions` over that flag. `TCalcOrchestrator.RunFitting` consults a `TTaskDialog` before starting, and the "Keep" answer sets `FFirstUpdate := False` so the result updates the existing gradient nodes instead of appending duplicates.

**Tech Stack:** Delphi VCL, RAD Studio 37.0, VirtualTrees, DUnitX.

## Global Constraints

- Spec: `docs/superpowers/specs/2026-08-11-stale-fit-extensions-design.md`
- The `FromFit` flag is **runtime only**. Do not add it to `ReadNode` or `WriteNode` in `unit_XRCProjectTree.pas`, and do **not** bump `CURRENT_PROJECT_VERSION` (stays 7).
- Hand-added extensions must never be touched. Only nodes with `FromFit = True` are eligible for clearing.
- No dialogs in `FBenchmarkMode` — headless runs must not block on UI.
- Delphi gotcha: in a record with a variant part, the variant `case` must stay last; method declarations go before it.
- Git commit prefixes: `+` new feature, `*` modification/fix.
- Build target for verification is **Win64 Release** for the app, **Win32 Debug** for the test project (per `CLAUDE.md`).
- Never mark a task complete on a successful build alone; app behaviour is confirmed by the user in the running app.

**Build commands** (PowerShell, from the repo root `D:\DelphiProjects\X-RayCalc\X-RayCalc3`):

```powershell
# App, Win64 Release
$env:BDS='C:\Program Files (x86)\Embarcadero\Studio\37.0'
$env:BDSCOMMONDIR='C:\Users\Public\Documents\Embarcadero\Studio\37.0'
& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal
```

```powershell
# Tests, build then run
$env:BDS='C:\Program Files (x86)\Embarcadero\Studio\37.0'
$env:BDSCOMMONDIR='C:\Users\Public\Documents\Embarcadero\Studio\37.0'
& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal
$env:PATH='C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;' + $env:PATH
& XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue
```

`/t:Make` does not work on this machine — always `/t:Build`.

---

### Task 1: `FromFit` flag and `IsFitExtension` predicate

**Files:**
- Modify: `XRayCalc3/Units/unit_Types.pas:42-73` (record declaration), `:234-237` (implementation)
- Test: `XRayCalc3/Tests/TestUnitTypes.pas:45-53` (fixture declaration), `:251-311` (implementation)

**Interfaces:**
- Consumes: nothing.
- Produces: `TProjectData.FromFit: Boolean` (field, `prExtension` branch) and `TProjectData.IsFitExtension: Boolean` (method). Tasks 3 and 4 depend on both.

- [ ] **Step 1: Write the failing tests**

In `XRayCalc3/Tests/TestUnitTypes.pas`, add three test method declarations to the existing `TTestProjectData` fixture (after `Test_SetPoly_StoresOrder` on line 52):

```pascal
    [Test] procedure Test_IsFitExtension_True;
    [Test] procedure Test_IsFitExtension_False_NotFromFit;
    [Test] procedure Test_IsFitExtension_False_WrongRowType;
```

And add their implementations at the end of the `{ TTestProjectData }` implementation block, immediately after `Test_SetPoly_StoresOrder`:

```pascal
procedure TTestProjectData.Test_IsFitExtension_True;
var PD: TProjectData;
begin
  PD.RowType := prExtension;
  PD.FromFit := True;
  Assert.IsTrue(PD.IsFitExtension);
end;

procedure TTestProjectData.Test_IsFitExtension_False_NotFromFit;
var PD: TProjectData;
begin
  // A hand-added extension must never be reported as fit-generated
  PD.RowType := prExtension;
  PD.FromFit := False;
  Assert.IsFalse(PD.IsFitExtension);
end;

procedure TTestProjectData.Test_IsFitExtension_False_WrongRowType;
var PD: TProjectData;
begin
  // FromFit shares storage with the prItem branch of the variant record,
  // so the RowType guard is what makes the predicate safe
  PD.RowType := prItem;
  PD.FromFit := True;
  Assert.IsFalse(PD.IsFitExtension);
end;
```

- [ ] **Step 2: Run the tests to verify they fail**

Run the test build command from Global Constraints.
Expected: compile FAILS with `E2003 Undeclared identifier: 'FromFit'`.

- [ ] **Step 3: Add the field and the predicate**

In `XRayCalc3/Units/unit_Types.pas`, add the declaration after `procedure SetPoly(var PolyD: TPolyArray);` (line 49) — before the `case RowType` on line 50:

```pascal
    function IsFitExtension: Boolean;
```

Then add `FromFit` as the second field of the `prExtension` branch:

```pascal
      prExtension:
         (Enabled: boolean;
          FromFit: Boolean;    // runtime only - never streamed to the project file
          case ExtType: TExtentionType of
```

And add the implementation immediately after `TProjectData.IsModel` (line 237):

```pascal
function TProjectData.IsFitExtension: Boolean;
begin
  Result := (RowType = prExtension) and FromFit;
end;
```

- [ ] **Step 4: Run the tests to verify they pass**

Run the test build and run commands from Global Constraints.
Expected: build succeeds, suite runs, the three new tests PASS and no previously passing test regresses.

- [ ] **Step 5: Verify the project file format is untouched**

Confirm by inspection that `XRayCalc3/Components/unit_XRCProjectTree.pas` `ReadNode` and `WriteNode` were **not** modified and that `CURRENT_PROJECT_VERSION` in `unit_consts.pas` is still `7`. Streaming there is field-by-field, so an unwritten field changes nothing on disk.

- [ ] **Step 6: Commit**

```powershell
git add XRayCalc3/Units/unit_Types.pas XRayCalc3/Tests/TestUnitTypes.pas
git commit -m "+ Add runtime FromFit flag and IsFitExtension predicate to TProjectData"
```

---

### Task 2: The confirmation dialog

**Files:**
- Create: `XRayCalc3/Units/unit_StaleExtDialog.pas`
- Modify: `XRayCalc3/XRayCalc3.dproj:293` (add a `DCCReference`)

**Interfaces:**
- Consumes: nothing.
- Produces: `TStaleExtAction = (seaClear, seaKeep, seaCancel)` and `function ConfirmStaleExtensions: TStaleExtAction`. Task 4 consumes both.

This unit has no form of its own — it builds a `TTaskDialog` at runtime, following the `SelectExtensionTypeAction` pattern in `XRayCalc3/Forms/frm_ExtensionType.pas:62-129`. There is no `.dfm` and no `{$R *.dfm}`.

- [ ] **Step 1: Create the unit**

Create `XRayCalc3/Units/unit_StaleExtDialog.pas`:

```pascal
(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_StaleExtDialog;

interface

type
  TStaleExtAction = (seaClear, seaKeep, seaCancel);

function ConfirmStaleExtensions: TStaleExtAction;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

resourcestring
  rstrStaleCaption = 'Extensions from the previous fitting';
  rstrStaleTitle   = 'This model still carries extensions created by an earlier fitting run.';
  rstrStaleText    = 'They will be applied to the model unless you remove them.';
  rstrClearCaption = 'Clear them';
  rstrClearHint    = 'Delete the extensions from the previous fit and start from the bare structure';
  rstrKeepCaption  = 'Keep them';
  rstrKeepHint     = 'Use them as the starting point; the new result will update them in place';

function ConfirmStaleExtensions: TStaleExtAction;
const
  mrClearExt = 100;
  mrKeepExt  = 101;
var
  Dlg: TTaskDialog;
  Btn: TTaskDialogBaseButtonItem;
begin
  Result := seaCancel;

  Dlg := TTaskDialog.Create(Application);
  try
    Dlg.Caption := rstrStaleCaption;
    Dlg.Title := rstrStaleTitle;
    Dlg.Text := rstrStaleText;
    Dlg.CommonButtons := [tcbCancel];
    Dlg.Flags := [tfAllowDialogCancellation, tfUseCommandLinks];
    Dlg.MainIcon := tdiWarning;

    Btn := Dlg.Buttons.Add;
    Btn.Caption := rstrClearCaption;
    (Btn as TTaskDialogButtonItem).CommandLinkHint := rstrClearHint;
    Btn.Default := True;
    Btn.ModalResult := mrClearExt;

    Btn := Dlg.Buttons.Add;
    Btn.Caption := rstrKeepCaption;
    (Btn as TTaskDialogButtonItem).CommandLinkHint := rstrKeepHint;
    Btn.ModalResult := mrKeepExt;

    if Dlg.Execute then
    begin
      case Dlg.ModalResult of
        mrClearExt: Result := seaClear;
        mrKeepExt:  Result := seaKeep;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
```

Cancelling, or dismissing the dialog with Esc, leaves `Result` at its initial `seaCancel`.

- [ ] **Step 2: Register the unit in the project**

In `XRayCalc3/XRayCalc3.dproj`, add a line immediately after the `unit_CalcOrchestrator.pas` reference on line 293:

```xml
        <DCCReference Include="Units\unit_StaleExtDialog.pas"/>
```

No `<Form>` / `<FormType>` child elements — this unit has no form.

- [ ] **Step 3: Build to verify it compiles**

Run the app build command from Global Constraints.
Expected: build succeeds. The unit is not referenced by anything yet, so this only proves it compiles and is wired into the project.

- [ ] **Step 4: Commit**

```powershell
git add XRayCalc3/Units/unit_StaleExtDialog.pas XRayCalc3/XRayCalc3.dproj
git commit -m "+ Add ConfirmStaleExtensions task dialog unit"
```

---

### Task 3: Mark, detect and clear fit-generated extensions

**Files:**
- Modify: `XRayCalc3/Views/frame_ProjectPanel.pas` — declarations at `:184-192`, `CreateProfileExtension` at `:869-894`, `CreateFitGradientExtensions` at `:1629-1656`, new methods after `IsProfileEnabled` at `:1627`

**Interfaces:**
- Consumes: `TProjectData.FromFit`, `TProjectData.IsFitExtension` (Task 1).
- Produces:
  - `TfrmProjectPanel.HasFitExtensions: Boolean`
  - `TfrmProjectPanel.ClearFitExtensions`
  - `TfrmProjectPanel.CreateProfileExtension(const AFromFit: Boolean = False)` — signature change; the existing no-argument call in `AddExtension` (line 1343) keeps working unchanged.

  Task 4 consumes the first two and passes `True` to the third.

`System.Generics.Collections` is already in this unit's `uses` (line 6), so `TList<PVirtualNode>` needs no new dependency.

- [ ] **Step 1: Mark fit-generated gradients**

In `CreateFitGradientExtensions`, add one line after `Data.Enabled := True;` (line 1641):

```pascal
    Data.FromFit := True;
```

- [ ] **Step 2: Mark the fit-generated profile table**

Change the `CreateProfileExtension` declaration on line 192 to:

```pascal
    procedure CreateProfileExtension(const AFromFit: Boolean = False);
```

Change its implementation header on line 869 to match:

```pascal
procedure TfrmProjectPanel.CreateProfileExtension(const AFromFit: Boolean);
```

and add one line after `Data.Enabled := True;` (line 883):

```pascal
    Data.FromFit := AFromFit;
```

Leave the `AddExtension` call site (line 1343) alone — it takes the `False` default, which is exactly right for a hand-added table.

- [ ] **Step 3: Declare the two new methods**

In the `{ Fit/profile support }` public block, add after `function IsProfileEnabled: Boolean;` (line 186):

```pascal
    function  HasFitExtensions: Boolean;
    procedure ClearFitExtensions;
```

- [ ] **Step 4: Implement the two new methods**

Insert after the end of `IsProfileEnabled` (line 1627), before `CreateFitGradientExtensions`:

```pascal
function TfrmProjectPanel.HasFitExtensions: Boolean;
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  Result := False;
  if FLastModel = nil then Exit;

  Node := FProject.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if Data.IsFitExtension then
    begin
      Result := True;
      Break;
    end;
    Node := FProject.GetNextSibling(Node);
  end;
end;

procedure TfrmProjectPanel.ClearFitExtensions;
var
  Node: PVirtualNode;
  Data: PProjectData;
  Doomed: TList<PVirtualNode>;
  i: Integer;
begin
  if FLastModel = nil then Exit;

  Doomed := TList<PVirtualNode>.Create;
  try
    Node := FProject.GetFirstChild(FLastModel);
    while Node <> nil do
    begin
      Data := FProject.GetNodeData(Node);
      if Data.IsFitExtension then
        Doomed.Add(Node);
      Node := FProject.GetNextSibling(Node);
    end;

    if Doomed.Count = 0 then Exit;

    for i := 0 to Doomed.Count - 1 do
      FProject.DeleteNode(Doomed[i]);
  finally
    Doomed.Free;
  end;

  FProject.Refresh;
  MatchToStructure;
end;
```

The two-pass collect-then-delete is deliberate: `GetNextSibling` on a node that `DeleteNode` has already freed is undefined behaviour. `FLastModel` is nil until a model node is focused (`frame_ProjectPanel.pas:749`, `:1545`), hence the guard in both methods.

- [ ] **Step 5: Build to verify it compiles**

Run the app build command from Global Constraints.
Expected: build succeeds with no warnings about the changed `CreateProfileExtension` signature.

- [ ] **Step 6: Commit**

```powershell
git add XRayCalc3/Views/frame_ProjectPanel.pas
git commit -m "+ Mark fit-generated extensions; add HasFitExtensions/ClearFitExtensions"
```

---

### Task 4: Wire the check into the fitting run

**Files:**
- Modify: `XRayCalc3/Units/unit_CalcOrchestrator.pas` — `uses` at `:14-19`, private fields at `:35`, `RunFitting` at `:328-356`, `UpdateInterface` call site for the profile table at `:319`

**Interfaces:**
- Consumes: `ConfirmStaleExtensions`, `TStaleExtAction` (Task 2); `HasFitExtensions`, `ClearFitExtensions`, `CreateProfileExtension(True)` (Task 3).
- Produces: nothing consumed by later tasks — this is the last task.

- [ ] **Step 1: Add the unit to `uses`**

On line 19, append `unit_StaleExtDialog` to the last `uses` line:

```pascal
  frame_CalcSettings, frame_ChartInfo, frame_ChartPages, frame_ProjectPanel,
  unit_StaleExtDialog;
```

- [ ] **Step 2: Add the state field**

On line 35, extend the existing boolean field declaration:

```pascal
    FBenchmarkMode, FFirstUpdate, FKeepExtensions: Boolean;
```

- [ ] **Step 3: Mark the fit-created profile table**

In `UpdateInterface`, change line 319 so the table the fitter creates is marked as fit-generated:

```pascal
           FProjectPanel.CreateProfileExtension(True);
```

- [ ] **Step 4: Add the check to `RunFitting`**

In `RunFitting`, insert the block after the re-entry guard (`if FFitThread <> nil then Exit;`, line 332) and before `if not GetFitParams then Exit;`:

```pascal
  FKeepExtensions := False;
  if (not FBenchmarkMode) and FProjectPanel.HasFitExtensions then
    case ConfirmStaleExtensions of
      seaCancel: Exit;
      seaClear:  FProjectPanel.ClearFitExtensions;
      seaKeep:   FKeepExtensions := True;
    end;
```

- [ ] **Step 5: Route "Keep" through the update path**

Replace the unconditional assignment on line 342:

```pascal
  FFirstUpdate := True;
```

with:

```pascal
  FFirstUpdate := not FKeepExtensions;
```

`FinalizeFitting` (line 366) and `HandleFitUpdate` (line 441) already pass `FFirstUpdate` to `UpdateInterface` as its `CreateExtension` argument, so `seaKeep` now reaches `UpdateFitGradientExtensions` instead of `CreateFitGradientExtensions`. This also fixes the standing duplication bug: previously every run reset the flag to `True` and appended a second set of gradient nodes. `CreateProfileExtension` is idempotent — it guards on `FProject.ProfileAttached` — so the `etTable` path needs no further handling.

- [ ] **Step 6: Build to verify it compiles**

Run the app build command from Global Constraints.
Expected: build succeeds.

- [ ] **Step 7: Commit**

```powershell
git add XRayCalc3/Units/unit_CalcOrchestrator.pas
git commit -m "+ Ask to clear stale fit extensions before a new fitting run"
```

- [ ] **Step 8: Hand verification in the running app**

Do not mark this task done on a green build. Ask the user to confirm each of these in the running application:

1. Load a periodic model with linked data, set fitting mode to Poly, run a fit → gradient extensions appear, **no dialog** (there were none to begin with).
2. Press Run Fitting again → the dialog appears with Clear / Keep / Cancel.
3. Choose **Cancel** → no fit starts, the tree is unchanged.
4. Choose **Clear** → the gradient nodes disappear, the profile charts refresh, the fit runs from the bare structure.
5. Run a fit to recreate the gradients, press Run Fitting and choose **Keep** → the fit runs and the existing gradient nodes are updated in place; the count of gradient nodes does not grow.
6. Add an extension by hand (Add Extension → Function), then run a fit and choose **Clear** → the hand-added extension survives; only fit-generated ones are removed.
7. Save the project, reopen it, press Run Fitting → **no dialog**. This is the accepted limitation of the runtime-only flag, not a bug.

---

## Notes for the implementer

- The `FromFit` field lives in the `prExtension` branch of a variant record, so it shares storage with `prItem` fields (`CurveID`, `Color`, …). That is why `IsFitExtension` guards on `RowType` rather than reading `FromFit` alone — never read `FromFit` directly outside that method.
- `MatchToStructure` writes `Structure.ToString` into `ActiveModel.Data` and repaints the profile charts; it is the standard "the tree changed, resync everything" call in this frame.
- If a build fails with `E2169`, a field was declared after a method in the same visibility section — move it up.
