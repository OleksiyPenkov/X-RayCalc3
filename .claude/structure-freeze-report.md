# Stack-level freeze — implementation report

## 1. Message constants (`XRayCalc3/Components/unit_SMessages.pas`)

Added, immediately after the existing layer messages:

```pascal
WM_STR_STACK_FREEZE = WM_STR_BASE + 24;
WM_STR_STACK_THAW   = WM_STR_BASE + 25;
```

No new posting helper was added — `ArrangeLayer(const Msg: Cardinal; const StackID, ID: integer)`
is reused as instructed, called with `ID = 0`.

## 2. Menu (`XRayCalc3/Components/unit_XRCStackControl.pas`)

`TXRCStack` previously had no context menu. Added a private field `FMenu: TPopupMenu`
(placed with the other fields, before the private methods, per the fields-before-methods
rule), plus `CreateMenu` / `MenuOnClick`, mirroring `TXRCLayerControl`:

```pascal
const
  Captions : array [1..2] of string   = ('Freeze stack', 'Thaw stack');
  Tags     : array [1..2] of Cardinal = (WM_STR_STACK_FREEZE, WM_STR_STACK_THAW);
...
procedure TXRCStack.CreateMenu;
var
  Item: TMenuItem;
  i: Integer;
begin
  FMenu := TPopupMenu.Create(Self);
  Self.PopupMenu := FMenu;
  for I := 1 to 2 do
  begin
    Item := TMenuItem.Create(FMenu);
    Item.Tag     := Tags[i];
    Item.Caption := Captions[i];
    Item.OnClick := MenuOnClick;
    FMenu.Items.Add(Item);
  end;
end;

procedure TXRCStack.MenuOnClick(Sender: TObject);
begin
  ArrangeLayer((Sender as TMenuItem).Tag, FID, 0);
end;
```

`CreateMenu` is called from the constructor (right before the existing `UpdateInfo` call).

Deliberate deviation from the layer-control pattern: I did **not** wire up `Item.ImageIndex`
or `FMenu.Images`. `TXRCLayerControl.CreateMenu` uses a class-var `FMenuImages` (set once from
`frm_Main` to `vilModel`) and an `ImgIndices` const array pointing at existing icons
(layer_up/down/insert/delete). There is no freeze/thaw icon in `vilModel`, and inventing an
image-list wiring for icons that don't exist seemed worse than a plain text menu. `TXRCStack`
has no `MenuImages` class property at all — I left that out rather than half-building it.
A human can add icons later by adding entries to `vilModel` and following the same
`FMenuImages`/`ImgIndices` shape used by the layer control.

## 3. Marker (`XRayCalc3/Components/unit_XRCStackControl.pas`, `UpdateInfo`)

`UpdateInfo` now counts `Fixed` across all layers' `P[1..3]` (skipping the row entirely when
`FSubstrate` is set) and renders:

- 0 frozen → `Caption := FTitle` (unchanged)
- all frozen → `Caption := FTitle + ' [frozen]'`
- some frozen → `Caption := FTitle + Format(' [%d/%d frozen]', [Frozen, Total])`

`UpdateInfo` was moved from `private` to `public` (it previously had no external caller —
`FOnDoubleClick` calls it from inside the same class). It now needs to be callable from
`TXRCStructure.SetStackFrozen` in a different unit, so it had to become public. No other
behavior changed; the existing internal call site (`FOnDoubleClick`, after editing stack
name/N) is untouched.

## 4. Model change (`XRayCalc3/Components/unit_XRCStructure.pas`)

```pascal
procedure TXRCStructure.SetStackFrozen(const StackID: Integer; const Frozen: Boolean);
var
  j, p: integer;
  Data: TLayerData;
begin
  if (StackID < 0) or (StackID > High(FStacks)) then Exit;

  for j := 0 to High(FStacks[StackID].Layers) do
  begin
    Data := FStacks[StackID].Layers[j].Data;   // seed from the live layer (UpdateInterfaceP pattern)
    for p := 1 to 3 do
      Data.P[p].Fixed := Frozen;
    FStacks[StackID].UpdateLayer(j, Data);
  end;

  FStacks[StackID].UpdateInfo;    // refresh the header marker; property writes don't fire handlers
end;
```

Bounds-guards `StackID` before indexing `FStacks`, exactly like `Select`/`DeleteLayer` elsewhere
in the same unit. Follows the `UpdateInterfaceP` write-back shape: seeds `Data` from
`FStacks[StackID].Layers[j].Data` (never a fresh `TLayerData`) so the cached `StackID`/`LayerID`
survive, mutates only `P[1..3].Fixed`, then calls `UpdateLayer`. Explicitly calls
`FStacks[StackID].UpdateInfo` afterwards, since setting `FLayers[i].Data` via the `UpdateLayer`
property path does not fire any caption refresh on its own.

## 5. Wiring (`XRayCalc3/Forms/frm_Main.pas`)

Handler style discovered by inspecting the existing `WM_STR_LAYER_UP`/`DOWN`/`DELETE`/`INSERT`
handlers: each is declared as a `message`-mapped method in the `public` section

```pascal
procedure OnLayerUPMsg(var Msg: TMessage); message WM_STR_LAYER_UP;
```

and its body reads the two integers straight off `Msg.WParam`/`Msg.LParam` and calls into
`Structure` directly — no wrapping, no guard, one line. Added, in the same style, right after
the declaration block and right after the `OnMyMessage`/`WM_RECALC` handler body:

```pascal
procedure OnStackFreezeMsg(var Msg: TMessage); message WM_STR_STACK_FREEZE;
procedure OnStackThawMsg(var Msg: TMessage); message WM_STR_STACK_THAW;
```
```pascal
procedure TfrmMain.OnStackFreezeMsg(var Msg: TMessage);
begin
  Structure.SetStackFrozen(Msg.WParam, True);
end;

procedure TfrmMain.OnStackThawMsg(var Msg: TMessage);
begin
  Structure.SetStackFrozen(Msg.WParam, False);
end;
```

`ArrangeLayer(Tag, FID, 0)` posts `WParam = StackID`, `LParam = 0`, matching "reads the stack id
from the message's `WParam`".

### Recalculation / undo decision

**Neither** an undo (`OperationsStack`) entry nor a recalculation (`WM_RECALC`/
`FOrchestrator.RecalcFromStructure`) is triggered. Reasoning:

- Freezing/thawing changes no physical value (`V`), only `Fixed`, which only constrains what the
  *next* fit is allowed to move. There is nothing for a recalculation to recompute — the model's
  reflectivity curve is identical before and after.
- This is a second entry point onto the exact same flag the fit-limits dialog already edits.
  That existing entry point, `TfrmMain.OnSetFitLimits`, calls `Structure.UpdateInterfaceP(FitStructure)`
  directly with no `FProjectPanel.SaveHistory` call and no recalculation. Freeze/thaw should behave
  identically to stay consistent with the mechanism it duplicates.
- The sibling handlers this brief told me to match stylistically — `OnLayerUPMsg`, `OnLayerDownMsg`,
  `OnLayerDeleteMsg`, `OnLayerInsertMsg` — also call neither `SaveHistory` nor a recalc themselves
  inside the message handler (undo pushes in this codebase happen explicitly at menu/action level,
  e.g. `PeriodDeleteExecute`, `actLayerCopyExecute`, `DoAddStack`, which call `FProjectPanel.SaveHistory`
  before invoking the structure change — not from the posted-message handlers). Since freeze/thaw
  has no dedicated menu/action call site of that kind (it only exists as this context-menu message),
  and since undo for a flag with no visual/geometric effect on the current model would be surprising
  (undoing would silently re-enable fit parameters with no visible change to the chart), I chose to
  leave it out of the undo history as well.

## Build and test

- Win32 Release GUI build (`XRayCalc3\XRayCalc3.dproj`, `/t:Build /p:Config=Release /p:Platform=Win32`):
  **succeeded**. Only pre-existing baseline noise present (`H2443` in `frame_ChartInfo.pas`, `W1024`
  in `unit_ProfilesManager.pas`) — no new warnings in any file touched by this change.
- Tests build (`XRayCalc3\Tests\XRayCalc3Tests.dproj`, Debug): succeeded; only pre-existing
  baseline hints/warnings in unrelated files.
- Tests run (`XRayCalc3Tests.exe --exitbehavior:Continue`, output redirected to a file and read,
  as required): **643 found / 642 passed / 0 failed / 0 leaked / 1 errored**, run three times with
  the same result each time. The one error is `TestSeriesIO.TTestSeriesIO.Test_Clipboard_Roundtrip`
  ("Cannot open clipboard: Access is denied") — this is the documented pre-existing clipboard flake
  (project memory: `clipboard_test_flake.md`), unrelated to this change; no test in the suite touches
  `TXRCStack`, `TXRCStructure`, `TfrmMain`'s new handlers, or `unit_SMessages` (these are VCL
  component/form units, none of which are exercised by the console test runner, matching the brief's
  expectation that this change adds no tests and the suite is otherwise unchanged).
- `suite*.log` files were deleted after inspection, as instructed.

## Hard rules compliance

- `delphi-development` skill invoked before any edit.
- No GUI launch, no clicks, no screenshots.
- Fields precede methods in `TXRCStack`'s `private` section (`FMenu` added among the fields, above
  the method declarations).
- `CURRENT_PROJECT_VERSION` untouched (stays 7); no version bump.
- `XRayCalc3/LFPSO/` untouched.
- `XRayCalc3/Forms/frm_Limits.pas` untouched — this is a second entry point, not a replacement.

## Files changed

- `XRayCalc3/Components/unit_SMessages.pas`
- `XRayCalc3/Components/unit_XRCStackControl.pas`
- `XRayCalc3/Components/unit_XRCStructure.pas`
- `XRayCalc3/Forms/frm_Main.pas`

## Things a human should confirm at the GUI

- Right-clicking a stack's header/label area (not on an individual layer row) shows the
  "Freeze stack" / "Thaw stack" popup menu, and that it does not interfere with the existing
  left-click (`StackClick`) / double-click (`FOnDoubleClick`, opens the stack editor) behavior on
  the same area.
- After choosing Freeze/Thaw, the stack header caption updates immediately to show
  `[frozen]` / `[N/M frozen]` / plain title, and that this stays in sync with what the fit-limits
  dialog shows for the same stack (open the dialog after freezing to cross-check).
- Visual placement/styling of the two menu items (no icons were added — see section 2) is
  acceptable without icons, or whether icons should be added later.
- Freezing a stack, then opening the limits dialog, confirms `Fixed` really propagated to all
  three parameters of every layer in that stack (H, sigma, rho), and that the substrate row is
  correctly excluded from both the freeze action's reach (it's never included, since
  `SetStackFrozen` iterates a stack's own `Layers`, and the substrate is not part of any
  `FStacks[i]`) and the header count.
