# Resume fit with frozen model parts

_2026-09-20_

## Goal

Fit a multilayer in stages. Run one fit, decide part of the model is settled,
freeze it, change the fit parameters — weight type above all — and run again on
what is left. Today this is possible only by hand-typing `min = max` into the
limits dialog for every parameter of every layer you want held, and those typed
values go stale the moment the next fit moves anything.

Two things are added: a **freeze flag** on every fitted parameter, at stack,
layer and parameter granularity, and a **Resume** command that re-centres the
free parameters on the values the last fit reached.

## Background: what already exists

- Limits are per layer parameter, `TFitValue.min` / `.max` in `unit_Types.pas:213`.
- They are edited in the modal limits dialog, shown on every Run
  (`unit_CalcOrchestrator.pas:243`), and already persisted in the `.xrcx`
  (`unit_XRCStructure.pas:733`).
- **The engine already pins an empty range.** `Xrange = max - min = 0` makes
  `Rand(0)` return 0 in `XSeed` and `RangeSeed`, and `CheckLimits` clamps to
  `[Xmin, Xmax]`, so the value never moves. XRC_MCP depends on exactly this and
  documents it (`unit_MCPFit.pas:49`). In Poly mode every higher-order
  coefficient derives from `Xrange[0]` (`TLFPSO_Poly.Set_Init_XPoly`), so an
  empty range freezes the whole polynomial. In Periodic mode the period is held
  unless `SetPeriodRange` opens it, which the GUI never calls.
- After a fit, values are written back into the live structure, so pressing Run
  again already continues from them.

The engine therefore needs **no change at all**. The work is state, UI and one
new command.

## 1. The freeze flag

`TFitValue` (`unit_Types.pas:213`) gains `Fixed: Boolean` beside the existing
`Paired`. `TFitValue.New` clears it. Everything downstream — `TLayerData.P[1..3]`,
`TFitStack.Layers`, `TFitStructure.Subs`, `TFitStructure.CopyContent` — carries it
with no further change, so the substrate's σ and ρ freeze by the same mechanism
as any layer.

**Meaning.** `Fixed` means *this parameter does not move in the next fit*.
`min` and `max` keep the range they had, untouched, so thawing returns exactly
the window that was set. The frozen **value** is always the live `V`, so it
follows every refit and every manual edit in the structure panel.

This is why a flag is needed rather than hand-typed `min = max`: a typed pin
captures a value at a moment, and Resume needs a pin that tracks.

### Hand-off to the engine

`unit_SmartLimits` gains one procedure:

```pascal
procedure CollapseFixed(var Structure: TFitStructure);
// for each layer, for p := 1 to 3: if P[p].Fixed then begin P[p].min := P[p].V; P[p].max := P[p].V; end;
// same for Structure.Subs
```

`TCalcOrchestrator.PrepareLFPSO` calls it on `FFitStructure` immediately before
`FLFPSO.Structure := FFitStructure` (`unit_CalcOrchestrator.pas:284`). The PSO is
not modified.

### The write-back split

`UpdateInterfaceP` / `UpdateInterfaceNP` (`unit_XRCStructure.pas:593,616`)
currently copy the whole `TFitValue`: `Data.P := Inp.Stacks[i].Layers[j].P`. They
serve **two different jobs**, and only one of them may be changed:

| Call site | Job | Behaviour |
|---|---|---|
| `frm_Main.pas:575` — `OnSetFitLimits` | carry **edited min/max** out of the dialog | unchanged |
| `unit_CalcOrchestrator.pas:244` — after the dialog's Run | same | unchanged |
| `unit_CalcOrchestrator.pas:307,311,319,327` — inside `UpdateInterface` | carry **fitted V** back | values only |

Both procedures gain `ValuesOnly: Boolean = False`. When `True` they take `V`
from the fit result and leave `min`, `max`, `Paired` and `Fixed` alone.
`TCalcOrchestrator.UpdateInterface` is the single funnel for all fit write-back —
including the live-update path in `HandleFitUpdate` (`unit_CalcOrchestrator.pas:456`),
which fires on every progress message when **Live update** is on — so `True` is
passed in exactly that one procedure and the manual limits route never sees it.

**This is load-bearing.** Without the split, collapsed `min = max` ranges flow
back into the live structure and destroy the user's limits — at the end of a
fit, and repeatedly *during* one when Live update is on.

Unrelated bug fixed in passing, three lines away: `OnSetFitLimits`
(`frm_Main.pas:573`) ignores the modal result and writes back whether the user
presses Save **or Cancel**. It gets an `if frmLimits.ShowLimits(...) then`.

### Persistence

`ToString` writes `HF` / `SF` / `RF` beside the existing `Hmin` / `Hmax`
(`unit_XRCStructure.pas:733`); `FromString` reads them with `FindBoolValue`,
which already returns `False` for an absent key (`:853`). Old projects therefore
load as "nothing frozen". **`CURRENT_PROJECT_VERSION` stays at 7.**

**XRC_MCP needs four lines, or it eats the flag.** It does not share
`unit_XRCStructure`; it has its own reader and writer for the same JSON in
`unit_MCPStructure.pas`, and the writer **reconstructs** each layer object from
its own model (`:520-532`) rather than editing the original — so any key it does
not know is dropped. Left alone, a project frozen in the GUI and then written
back by any MCP tool would come back thawed, silently.

So the MCP reader gains `...P[p].Fixed := DataBool(JLayer, UpperCase(PAlias[p]) + 'F')`
beside the existing `'P'` read (`:646`), and the writer gains the matching
`AddPair` beside `'P'` (`:524`). The flag is then carried but never acted on:
`CollapseFixed` is called only from `TCalcOrchestrator`, so `fit_xrr` behaviour
is unchanged. Teaching `fit_xrr` to *honour* the flag stays out of scope — it has
its own per-parameter freedom list and already defaults everything to frozen.

`xrccmd` neither reads nor writes `.xrcx` project files, so it needs nothing.

### Limit operations respect the freeze

`NarrowLimits`, `WidenAtLimit`, `AutoFixErrors`, `ApplyMaterialDensity`,
`ApplyGeometryCoupling` and `ClampToPhysics` skip parameters with `Fixed = True`.
`ValidateLimits` emits no issue for them: a frozen ρ with a stale stored range
must not block a Run.

## 2. Freezing in the limits dialog

**The dialog stays a flat grouped `TRzListView`.** One row per layer, stack
groups, as today. No tree — a tree either triples the row count or hides min/max
behind expanders, and the dialog exists to be scanned.

### Three columns

Placed beside the pair they govern:

```
Layer      Fix  Hmin   Hmax    Fix  Smin  Smax    Fix  Rmin   Rmax
──────────────────────────────────────────────────────────────────
Ru          ☑   12.00  16.00    ☑   2.00  4.00     ☑   10.00  14.00
C           ☑    8.00  11.00    ☑   2.00  4.00     ☑    1.80   2.40
```

Both halves reuse plumbing already in the file:

- `ListViewCustomDrawSubItem` draws the validation tint today; it gains the
  checkbox glyph and greys the numbers of frozen parameters.
- `ListViewClick` already hit-tests the clicked subitem to place the inline
  editor; it gains one branch — a freeze column toggles, a numeric column edits
  as before.

`Fixed` is toggled directly on `FStructure`, which `StructureFromView` never
touches (it parses only min/max), so view and model stay consistent.
`StructureToView` renders the glyphs from `FStructure`.

### Prerequisite fix

`GetColumns` (`frm_Limits.pas:206`) locates the clicked column with
`(X - Columns[0].Width) div Columns[1].Width + 1`, which assumes every column is
as wide as the second. That is already wrong today — the last column is 84, not
70 — and unusable once three narrow checkbox columns exist. It is replaced with a
cumulative-width scan. This also makes the existing inline editor land on the
correct cell.

### Stack and multi-row gestures

Groups in a `TListView` cannot hold a checkbox, so group-level freezing is
selection- and menu-driven:

- `MultiSelect` on. **Freeze** / **Thaw** buttons beside `Init` / `Narrow` /
  `Widen`, acting on the selected rows (all three parameters of each).
- Context menu: *Freeze this stack* / *Freeze layer* / *Freeze all* / *Thaw all*.
  "This stack" uses the focused row's group, so freezing the period stack is one
  right-click.

### Roll-up without a tree

Group header captions are plain strings rebuilt by `StructureToView`, so they
carry the summary a tri-state checkbox would have:
`Period stack — all 6 frozen`, `Top stack — 1 of 6 frozen`.

## 3. The Resume command

A new action `actResumeFitting` beside `actAutoFitting` (`frm_Main.pas:737`),
calling `TCalcOrchestrator.ResumeFitting`. Enabled only when a fit has completed
in this session (`FHasFitResults`).

### What it does

1. `FFitStructure := Structure.ToFitStructure` — picks up the values the last fit
   wrote back, and the freeze flags as they now stand.
2. **Re-centre every free parameter**, keeping its width: `half := (max - min) / 2;
   min := V - half; max := V + half`. A parameter that ended pinned against a wall
   can therefore keep exploring past it. A range that is already zero width — a
   `min = max` typed by hand — re-centres to zero width and so stays pinned;
   `Init` is the way to open it. Only `Fixed` freezes and thaws reversibly.
3. `ClampToPhysics` — so a re-centred ρ or σ cannot slide negative.
4. Frozen parameters are not re-centred; they are pinned to their current `V` by
   `CollapseFixed` at hand-off, as in any run.
5. Show the same limits dialog, pre-filled, with `ShowLimits('Resume', ...)`.
   It is a review step, not a detour — this is where freezing is edited.
6. From there on, identical to `RunFitting`.

Fit parameters are read fresh from Calc Settings on every run
(`GetFitParams` → `FCalcSettings.ReadFitParams`), so changing the weight type
between runs already works and needs nothing new.

### The convergence chart, and one honest caveat

`PrepareConvergence` clears the series today. Resume instead **appends**, with a
vertical marker at the boundary labelled with each segment's weight type.

The χ² **best value does not carry over**: it is reset for the resumed run.
Changing the weight type changes the objective, so the two segments' χ² are not
on the same scale and carrying a "best" across the boundary would assert a
comparison that is not true. The chart shows both segments and labels them; the
numeric best belongs to the current objective. The marker makes the
discontinuity visible rather than hiding it.

## Testing

DUnitX, in the existing suite (625 tests, all passing at `ed78b77`). Everything
below is testable headlessly; the GUI work in section 2 is verified by the user
in the running application.

| Area | Test |
|---|---|
| `CollapseFixed` | frozen parameter gets `min = max = V`; free parameter untouched; substrate included |
| Engine pinning | a structure with one frozen parameter, run through `TLFPSO_Irregular` for a few iterations, leaves that parameter at `V` in every particle |
| Poly mode | a frozen parameter's higher-order coefficients all get zero range |
| Write-back split | `UpdateInterfaceP(ValuesOnly := True)` changes `V` and preserves `min`, `max`, `Paired`, `Fixed`; with `False` it copies all of them |
| Persistence | `unit_MCPStructure`'s reader/writer round-trip `Fixed`; a JSON without `HF`/`SF`/`RF` loads as all-thawed. `unit_XRCStructure` is not in the test project — a VCL/Raize component unit in a console runner — so the GUI's own symmetric `ToString`/`FromString` change is covered by inspection and by the user's check in the app |
| Re-centring | width preserved, `V` centred; a value at a wall moves off it; `ClampToPhysics` applied afterwards |
| Limit ops | `NarrowLimits`, `WidenAtLimit`, `AutoFixErrors`, `ApplyMaterialDensity`, `ApplyGeometryCoupling`, `ClampToPhysics` leave frozen parameters alone; `ValidateLimits` reports nothing for them |

## Out of scope

- `fit_xrr` honouring the stored flag, and any `xrccmd` freeze switch. Both
  front-ends round-trip the flag and are otherwise untouched.
- Named, persisted fit stages. Resume is a command, not a saved sequence.
- Showing `V` beside its window in the dialog, and marking after a fit which
  parameters moved and which ended against a wall. Both are read-only columns in
  the same list and would serve this workflow well, but neither is agreed yet.
