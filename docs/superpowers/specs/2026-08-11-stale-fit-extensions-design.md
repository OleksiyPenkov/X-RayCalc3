# Stale fit-generated extensions — design

**Date:** 2026-08-11
**Status:** Approved, ready for planning

## Problem

Extensions (gradients and profile tables) live as `prExtension` child nodes of a model node
in the project tree. A fitting run creates them automatically: `TCalcOrchestrator.UpdateInterface`
calls `CreateFitGradientExtensions` in `fmPoly` mode and `CreateProfileExtension` in the
non-periodic branch.

Users forget to remove those extensions before starting the next fitting. Two things go wrong:

1. **Leftovers distort the new run.** `PrepareCalc` feeds every enabled `etFunction` extension
   into `FCalc.Model.Profiles` via `GetProfileFunctions`, and `IsProfileEnabled` drives the
   non-periodic profile path. The previous fit's modulation is silently applied on top of the
   new one. This bites even in `fmPeriodic`, which ignores extensions while fitting but still
   applies them when the result is replotted — so the displayed curve diverges from the model
   the fit actually optimised.

2. **Nodes duplicate.** `RunFitting` unconditionally sets `FFirstUpdate := True`, so the second
   poly fit calls `CreateFitGradientExtensions` again and appends a second set of gradient nodes
   instead of updating the existing ones through `UpdateFitGradientExtensions`.

## Solution overview

Detect fit-generated extensions when the user presses Run Fitting, and ask what to do with them:
clear, keep, or cancel the run. "Keep" also routes the result through the update path, which
fixes the duplication bug.

## Design decisions

| Decision | Choice | Rationale |
|---|---|---|
| Scope | Only fit-generated extensions | Hand-added extensions are the user's deliberate model definition and must never be touched |
| Trigger | Every Run Fitting press | Predictable; the "Keep" option covers iterative refinement without nagging becoming harmful |
| Actions | Clear / Keep / Cancel | Keep is needed for legitimate refinement runs and is the hook that fixes duplication |
| Clear semantics | Delete the nodes | The structure retains base values — `GetProfileFunctions` reads the constant term `C[0]` from the layer's own parameter — so no parameter restoration is needed |
| Origin flag persistence | Runtime only | No project format change, no `CURRENT_PROJECT_VERSION` bump. Accepted limitation below |

### Accepted limitation

The origin flag is not streamed. After a project is saved and reopened — including the
`<name>-fitted.xrcx` autosaves — its extensions load as `FromFit = False` and the dialog will
not fire for them. Detection is session-scoped. This was chosen deliberately over a v7 → v8
format bump.

## Detection

Add a runtime-only field to the `prExtension` branch of `TProjectData` in `unit_Types.pas`:

```pascal
prExtension:
   (Enabled: boolean;
    FromFit: Boolean;        // set by fit-generated extensions; never streamed
    case ExtType: TExtentionType of ...
```

Streaming in `unit_XRCProjectTree.pas` (`ReadNode` / `WriteNode`) is field-by-field, so an
unwritten field changes nothing on disk. VirtualTrees zeroes node data on allocation, so the
field defaults to `False` for both new and loaded nodes.

Marking:

- `CreateFitGradientExtensions` sets `Data.FromFit := True` on each node it creates.
- `CreateProfileExtension` gains a `FromFit: Boolean = False` parameter. The manual
  `AddExtension` path keeps the default; the `UpdateInterface` call passes `True`.

Two new public methods on `TfrmProjectPanel`, both walking the same model node that
`GetProfileFunctions` uses (`FLastModel`):

- `function HasFitExtensions: Boolean` — true if any child has `RowType = prExtension`
  and `FromFit`.
- `procedure ClearFitExtensions` — collect matching nodes into a local list **first**, then
  `FProject.DeleteNode` each one (deleting while walking siblings invalidates the cursor),
  then call `MatchToStructure` to refresh the profile charts and `ActiveModel.Data`.

## Dialog

A `ConfirmStaleExtensions` function in its own unit, mirroring the existing
`SelectExtensionTypeAction` pattern in `frm_ExtensionType.pas`: a `TTaskDialog` with
`tfUseCommandLinks` and `tfAllowDialogCancellation`, three command links plus Cancel.

```pascal
type
  TStaleExtAction = (seaClear, seaKeep, seaCancel);

function ConfirmStaleExtensions: TStaleExtAction;
```

| Command link | Hint |
|---|---|
| Clear them | Delete the extensions from the previous fit and start from the bare structure |
| Keep them | Use them as the starting point; the new result will update them in place |

Cancel, or dismissing the dialog, returns `seaCancel`.

## Wiring

In `TCalcOrchestrator`, add a private `FKeepExtensions: Boolean`. In `RunFitting`, before
`GetFitParams`:

```pascal
FKeepExtensions := False;
if (not FBenchmarkMode) and FProjectPanel.HasFitExtensions then
  case ConfirmStaleExtensions of
    seaCancel: Exit;
    seaClear:  FProjectPanel.ClearFitExtensions;
    seaKeep:   FKeepExtensions := True;
  end;
```

and replace the unconditional `FFirstUpdate := True` further down with:

```pascal
FFirstUpdate := not FKeepExtensions;
```

`FBenchmarkMode` suppresses the dialog entirely — headless runs must not block on UI.

`FinalizeFitting` and `HandleFitUpdate` already pass `FFirstUpdate` to `UpdateInterface` as
its `CreateExtension` argument, so `seaKeep` routes gradients through
`UpdateFitGradientExtensions` and leaves the existing nodes in place. For the `etTable` case
`CreateProfileExtension` is already idempotent — it guards on `FProject.ProfileAttached` —
so no extra handling is needed there.

## Testing

`HasFitExtensions` and `ClearFitExtensions` are tree-walking logic with no dialog dependency
and belong in the DUnitX suite. Cases:

- Model with no extensions → `HasFitExtensions` is False.
- Model with only hand-added extensions → False; `ClearFitExtensions` leaves them intact.
- Model with a mix → True; `ClearFitExtensions` removes only the marked nodes.
- Model with several marked gradients → all removed in one pass (guards the
  delete-while-iterating trap).

The orchestrator branch is three lines of control flow and is verified by hand in the running
app: run a poly fit, run it again, confirm the dialog appears and that Keep updates the
existing gradient nodes rather than duplicating them.
