# Resume Fit With Frozen Model Parts — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Let a multilayer be fitted in stages — freeze the part that has settled, change the fit parameters, and resume on what is left.

**Architecture:** A `Fixed` flag is added to every fitted parameter and collapsed to an empty range (`min = max = V`) at the moment the structure is handed to the optimizer. The PSO already pins an empty range, so it is not modified at all. A new Resume command re-centres the free parameters on the values the last fit reached. All UI work is additive inside the existing limits dialog.

**Tech Stack:** Delphi Object Pascal, RAD Studio 37.0 (Embarcadero), VCL, Raize/KSVC components, DUnitX test framework.

**Spec:** `docs/superpowers/specs/2026-09-20-resume-fit-with-frozen-parts-design.md`

## Global Constraints

- **Invoke the `delphi-development` skill before writing or modifying any code.** Required by `CLAUDE.md`.
- **Win32 is the primary target.** Build with `/t:Build` — `/t:Make` does not work.
- Build command prefix for every MSBuild invocation in this plan:
  `$env:BDS = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'; $env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0'; & 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe'`
- **Define VCL controls in the DFM. Never create them at runtime.** Standing user instruction.
- **Never launch the applications to verify work** — no keystroke injection, no screenshots, no killing processes. GUI behaviour is verified by the user. Build success plus the headless test suite is the automated gate.
- In Delphi class declarations, **fields must precede methods and properties** in each visibility section, or `E2169`.
- Setting a VCL control property in code does **not** fire its event handler — call update logic explicitly.
- `CURRENT_PROJECT_VERSION` stays at **7**. The new keys are optional and default to `False`.
- Git commit prefixes: `+` new feature, `*` modification/fix. End every commit message with
  `Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>`.
- `.dfm` files here are at `PixelsPerInch = 96`. Do not scale `ImageList` sizes or `TChart` properties.
- **Adding a test unit requires editing two files**: the `uses` clause of `XRayCalc3/Tests/XRayCalc3Tests.dpr` **and** a `<DCCReference>` in `XRayCalc3/Tests/XRayCalc3Tests.dproj`. Tasks in this plan add tests to *existing* units, so neither file changes.
- DUnitX fixtures are discovered by RTTI (`runner.UseRTTI := True`). No registration call is needed; a `[Test]` method must be declared in the fixture's `type` block and implemented below.

**Build the tests:**
```powershell
$env:BDS = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'; $env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0'; & 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' 'XRayCalc3\Tests\XRayCalc3Tests.dproj' /t:Build /p:Config=Debug /nologo /v:minimal
```

**Run the tests:**
```powershell
$env:PATH = 'C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;' + $env:PATH; & '.\XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe' --exitbehavior:Continue
```

**Baseline at `ed78b77`: 625 tests found, 625 passed, 0 failed, 0 leaked.** Every task must end with that number or higher and zero failures.

## File Structure

| File | Responsibility | Tasks |
|---|---|---|
| `XRayCalc3/Units/unit_Types.pas` | `TFitValue.Fixed` | 1 |
| `XRayCalc3/Units/unit_SmartLimits.pas` | `CollapseFixed`, `RecentreOnValue`, frozen-aware limit ops | 1, 3, 4 |
| `XRayCalc3/Tests/TestSmartLimits.pas` | tests for all of the above | 1, 3, 4 |
| `XRayCalc3/Tests/TestLFPSOIrregular.pas` | proof that an empty range pins a parameter | 2 |
| `XRC_MCP/units/unit_MCPStructure.pas` | carry `HF`/`SF`/`RF` through MCP's own reader/writer | 5 |
| `XRayCalc3/Tests/TestMCPStructure.pas` | MCP round-trip tests | 5 |
| `XRayCalc3/Components/unit_XRCStructure.pas` | GUI persistence; `ValuesOnly` write-back | 6, 7 |
| `XRayCalc3/Units/unit_CalcOrchestrator.pas` | collapse at hand-off; values-only write-back; `ResumeFitting` | 7, 10 |
| `XRayCalc3/Forms/frm_Main.pas` + `.dfm` | `actResumeFitting`; Cancel bug in `OnSetFitLimits` | 7, 10 |
| `XRayCalc3/Forms/frm_Limits.pas` + `.dfm` | freeze columns, gestures, group captions | 8, 9 |
| `XRayCalc3/Views/frame_ChartPages.pas` | convergence chart appends on resume | 10 |

---

### Task 1: The `Fixed` flag and `CollapseFixed`

**Files:**
- Modify: `XRayCalc3/Units/unit_Types.pas:213` (`TFitValue`), and `TFitValue.New` in the implementation
- Modify: `XRayCalc3/Units/unit_SmartLimits.pas` (interface list + new procedure)
- Test: `XRayCalc3/Tests/TestSmartLimits.pas`

**Interfaces:**
- Consumes: nothing.
- Produces: `TFitValue.Fixed: Boolean`; `procedure CollapseFixed(var Structure: TFitStructure);` in `unit_SmartLimits`.

- [ ] **Step 1: Write the failing tests**

In `XRayCalc3/Tests/TestSmartLimits.pas`, add to the `TTestValidateLimits` `type` block, after the last `[Test]` declaration:

```pascal
    [Test] procedure Test_CollapseFixed_PinsFrozenParam;
    [Test] procedure Test_CollapseFixed_LeavesFreeParam;
    [Test] procedure Test_CollapseFixed_HandlesSubstrate;
```

And at the end of the implementation section, before `end.`:

```pascal
procedure TTestValidateLimits.Test_CollapseFixed_PinsFrozenParam;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(2);
  FS.Stacks[0].Layers[0].P[1].V := 12.5;
  FS.Stacks[0].Layers[0].P[1].Fixed := True;

  CollapseFixed(FS);

  Assert.AreEqual(12.5, FS.Stacks[0].Layers[0].P[1].min, 1e-6, 'min pinned to V');
  Assert.AreEqual(12.5, FS.Stacks[0].Layers[0].P[1].max, 1e-6, 'max pinned to V');
end;

procedure TTestValidateLimits.Test_CollapseFixed_LeavesFreeParam;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(2);
  FS.Stacks[0].Layers[1].P[2].Fixed := False;

  CollapseFixed(FS);

  Assert.AreEqual(5.0, FS.Stacks[0].Layers[1].P[2].min, 1e-6, 'free min untouched');
  Assert.AreEqual(15.0, FS.Stacks[0].Layers[1].P[2].max, 1e-6, 'free max untouched');
end;

procedure TTestValidateLimits.Test_CollapseFixed_HandlesSubstrate;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Subs.Material := 'Si';
  FS.Subs.P[2].V := 3.0;
  FS.Subs.P[2].min := 1.0;
  FS.Subs.P[2].max := 6.0;
  FS.Subs.P[2].Fixed := True;

  CollapseFixed(FS);

  Assert.AreEqual(3.0, FS.Subs.P[2].min, 1e-6, 'substrate min pinned');
  Assert.AreEqual(3.0, FS.Subs.P[2].max, 1e-6, 'substrate max pinned');
end;
```

- [ ] **Step 2: Run the tests to verify they fail**

Build and run with the commands in Global Constraints.
Expected: **build fails** with `E2003 Undeclared identifier: 'CollapseFixed'` and `E2003 Undeclared identifier: 'Fixed'`.

- [ ] **Step 3: Add the field**

In `XRayCalc3/Units/unit_Types.pas`, change `TFitValue` (line 213) to:

```pascal
  TFitValue = record
    Paired: Boolean;
    Fixed: Boolean;   // does not move in the next fit; min/max keep their range
    V, min, max: single;
    procedure New(const Val: single);
    procedure Init(const dev: single); overload;
    procedure Init(const AMin, AMax: single); overload;
    procedure Init; overload;
    procedure Seed;
  end;
```

In the same file's implementation, `TFitValue.New` becomes:

```pascal
procedure TFitValue.New(const Val: single);
begin
  V := Val;
  min := 0;
  max := 0;
  Paired := False;
  Fixed := False;
end;
```

- [ ] **Step 4: Add `CollapseFixed`**

In `XRayCalc3/Units/unit_SmartLimits.pas`, add to the interface after `procedure AutoFixErrors(...)`:

```pascal
{ Pins every parameter marked Fixed to its current value by giving it an empty
  range. The optimizer needs no concept of freezing: Xrange = max - min = 0
  makes Rand(0) return 0 in XSeed and RangeSeed, and CheckLimits clamps to
  [Xmin, Xmax], so the value cannot move. Call this on the copy handed to the
  engine, never on a structure that is written back to the interface. }
procedure CollapseFixed(var Structure: TFitStructure);
```

And in the implementation, before the final `end.`:

```pascal
procedure CollapseFixed(var Structure: TFitStructure);
var
  i, j, p: Integer;

  procedure Pin(var Value: TFitValue);
  begin
    if Value.Fixed then
    begin
      Value.min := Value.V;
      Value.max := Value.V;
    end;
  end;

begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
        Pin(Structure.Stacks[i].Layers[j].P[p]);

  for p := 1 to 3 do
    Pin(Structure.Subs.P[p]);
end;
```

- [ ] **Step 5: Run the tests to verify they pass**

Expected: **628 tests, 0 failures.**

- [ ] **Step 6: Commit**

```bash
git add XRayCalc3/Units/unit_Types.pas XRayCalc3/Units/unit_SmartLimits.pas XRayCalc3/Tests/TestSmartLimits.pas
git commit -m "+ Fit parameters carry a Fixed flag, collapsed to an empty range at hand-off

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 2: Prove the optimizer pins an empty range

The whole design rests on the claim that the PSO needs no change. This task adds no production code — it pins the premise down with a test, so a later change to `CheckLimits` or `XSeed` cannot break freezing silently.

**Files:**
- Test: `XRayCalc3/Tests/TestLFPSOIrregular.pas`

**Interfaces:**
- Consumes: `CollapseFixed`, `TFitValue.Fixed` from Task 1.
- Produces: nothing.

- [ ] **Step 1: Read the existing fixture**

Read `XRayCalc3/Tests/TestLFPSOIrregular.pas` in full. Note `MakeIrregularStructure`, the `TestSetStructure` accessor on the testable subclass, and how existing tests reach `X`/`Xmin`/`Xmax`. Reuse those accessors — do not add new ones unless nothing exposes `Xrange`.

- [ ] **Step 2: Write the failing test**

Add to the fixture's `type` block:

```pascal
    [Test] procedure Test_FrozenParam_HasEmptyDomain;
```

And in the implementation:

```pascal
procedure TTestLFPSOIrregular.Test_FrozenParam_HasEmptyDomain;
var
  Inp: TFitStructure;
begin
  Inp := MakeIrregularStructure;
  Inp.Stacks[0].Layers[0].P[1].V := 13.0;
  Inp.Stacks[0].Layers[0].P[1].min := 10.0;
  Inp.Stacks[0].Layers[0].P[1].max := 16.0;
  Inp.Stacks[0].Layers[0].P[1].Fixed := True;

  CollapseFixed(Inp);
  FPSO.TestSetStructure(Inp);

  Assert.AreEqual(13.0, FPSO.TestXMin(0, 1), 1e-6, 'lower bound pinned to V');
  Assert.AreEqual(13.0, FPSO.TestXMax(0, 1), 1e-6, 'upper bound pinned to V');
  Assert.AreEqual(0.0, FPSO.TestXRange(0, 1), 1e-6, 'empty range');
end;
```

If the testable subclass does not already expose `TestXMin` / `TestXMax` / `TestXRange`, add them next to the existing accessors, following their exact style, e.g.:

```pascal
      function TestXRange(const LIndex, PIndex: Integer): Single;
...
function TTestableLFPSOIrregular.TestXRange(const LIndex, PIndex: Integer): Single;
begin
  Result := Xrange[0][LIndex][PIndex][0];
end;
```

Add `unit_SmartLimits` to the unit's `uses` clause.

- [ ] **Step 3: Run the test to verify it fails**

Expected: build error for the missing accessors, or an assertion failure — not a pass.

- [ ] **Step 4: Make it pass**

Only by adding the accessors. **No change to any `unit_LFPSO_*.pas` file is permitted in this task.** If the test cannot pass without one, stop and report — the spec's central premise is wrong and the design needs revisiting.

- [ ] **Step 5: Run the tests**

Expected: **629 tests, 0 failures.**

- [ ] **Step 6: Commit**

```bash
git add XRayCalc3/Tests/TestLFPSOIrregular.pas
git commit -m "* Test: an empty range pins a parameter in the optimizer

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 3: Limit operations respect the freeze

Frozen parameters keep their real `min`/`max` so that thawing restores them. Every limit-manipulating helper must therefore leave them alone, and validation must not report on them — a frozen ρ with a stale range must not block a Run.

**Files:**
- Modify: `XRayCalc3/Units/unit_SmartLimits.pas` — `ValidateLimits`, `ClampToPhysics`, `ApplyMaterialDensity`, `ApplyGeometryCoupling`, `NarrowLimits`, `WidenAtLimit`, `AutoFixErrors`
- Test: `XRayCalc3/Tests/TestSmartLimits.pas`

**Interfaces:**
- Consumes: `TFitValue.Fixed` from Task 1.
- Produces: no new symbols; behaviour change only.

- [ ] **Step 1: Write the failing tests**

Add to the `TTestValidateLimits` `type` block:

```pascal
    [Test] procedure Test_Frozen_NotValidated;
    [Test] procedure Test_Frozen_NotNarrowed;
    [Test] procedure Test_Frozen_NotWidened;
    [Test] procedure Test_Frozen_NotClamped;
```

And in the implementation:

```pascal
procedure TTestValidateLimits.Test_Frozen_NotValidated;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
begin
  FS := MakeStructure(1);
  // A range that would certainly be reported if it were free.
  FS.Stacks[0].Layers[0].P[1].min := 20.0;
  FS.Stacks[0].Layers[0].P[1].max := 5.0;
  FS.Stacks[0].Layers[0].P[1].Fixed := True;

  Issues := ValidateLimits(FS);

  Assert.AreEqual(0, Length(Issues), 'a frozen parameter is not validated');
end;

procedure TTestValidateLimits.Test_Frozen_NotNarrowed;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].Fixed := True;

  NarrowLimits(FS, 0.5);

  Assert.AreEqual(5.0, FS.Stacks[0].Layers[0].P[1].min, 1e-6, 'min untouched');
  Assert.AreEqual(15.0, FS.Stacks[0].Layers[0].P[1].max, 1e-6, 'max untouched');
end;

procedure TTestValidateLimits.Test_Frozen_NotWidened;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 15.0;   // hard against max, would widen
  FS.Stacks[0].Layers[0].P[1].Fixed := True;

  WidenAtLimit(FS, 0.5);

  Assert.AreEqual(15.0, FS.Stacks[0].Layers[0].P[1].max, 1e-6, 'max untouched');
end;

procedure TTestValidateLimits.Test_Frozen_NotClamped;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[2].min := -3.0;  // would be clamped to 0 if free
  FS.Stacks[0].Layers[0].P[2].Fixed := True;

  ClampToPhysics(FS);

  Assert.AreEqual(-3.0, FS.Stacks[0].Layers[0].P[2].min, 1e-6, 'min untouched');
end;
```

- [ ] **Step 2: Run the tests to verify they fail**

Expected: all four **FAIL** on the assertions (the flag exists but nothing reads it).

- [ ] **Step 3: Add the guard to every operation**

In each of `ValidateLimits`, `ClampToPhysics`, `ApplyMaterialDensity`, `ApplyGeometryCoupling`, `NarrowLimits`, `WidenAtLimit` and `AutoFixErrors`, inside the innermost `for p := 1 to 3 do` loop, add as the **first** statement:

```pascal
        if Structure.Stacks[i].Layers[j].P[p].Fixed then
          Continue;
```

Match each procedure's own loop-variable names and indexing — several use `with ... do` blocks, and `ApplyMaterialDensity` walks a flat `Index` alongside `i`/`j`. Where a procedure also visits `Structure.Subs`, guard that the same way. `ApplyGeometryCoupling` couples a layer's σ to its own and its neighbour's H: skip only when the **parameter being written** is frozen, not when a parameter it reads is.

Note `NarrowLimits` and `WidenAtLimit` already `Continue` on `min = max`; the new guard is in addition to that, because a frozen parameter still holds a real range.

- [ ] **Step 4: Run the tests to verify they pass**

Expected: **633 tests, 0 failures.** All pre-existing `TestSmartLimits` tests must still pass — they never set `Fixed`, which defaults to `False`.

- [ ] **Step 5: Commit**

```bash
git add XRayCalc3/Units/unit_SmartLimits.pas XRayCalc3/Tests/TestSmartLimits.pas
git commit -m "* Limit operations and validation leave frozen parameters alone

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 4: `RecentreOnValue` — the arithmetic behind Resume

**Files:**
- Modify: `XRayCalc3/Units/unit_SmartLimits.pas`
- Test: `XRayCalc3/Tests/TestSmartLimits.pas`

**Interfaces:**
- Consumes: `TFitValue.Fixed` from Task 1.
- Produces: `procedure RecentreOnValue(var Structure: TFitStructure);` in `unit_SmartLimits`.

- [ ] **Step 1: Write the failing tests**

Add to the `TTestValidateLimits` `type` block:

```pascal
    [Test] procedure Test_Recentre_KeepsWidth;
    [Test] procedure Test_Recentre_MovesValueOffTheWall;
    [Test] procedure Test_Recentre_SkipsFrozen;
    [Test] procedure Test_Recentre_ZeroWidthStaysPinned;
```

And in the implementation:

```pascal
procedure TTestValidateLimits.Test_Recentre_KeepsWidth;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 12.0;   // min 5, max 15, width 10

  RecentreOnValue(FS);

  Assert.AreEqual(7.0, FS.Stacks[0].Layers[0].P[1].min, 1e-6);
  Assert.AreEqual(17.0, FS.Stacks[0].Layers[0].P[1].max, 1e-6);
end;

procedure TTestValidateLimits.Test_Recentre_MovesValueOffTheWall;
var
  FS: TFitStructure;
  Rec: TFitValue;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 15.0;   // pinned against max

  RecentreOnValue(FS);

  Rec := FS.Stacks[0].Layers[0].P[1];
  Assert.IsTrue(Rec.max > Rec.V, 'the value is no longer at the wall');
  Assert.IsTrue(Rec.min < Rec.V, 'and not at the other one either');
end;

procedure TTestValidateLimits.Test_Recentre_SkipsFrozen;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 12.0;
  FS.Stacks[0].Layers[0].P[1].Fixed := True;

  RecentreOnValue(FS);

  Assert.AreEqual(5.0, FS.Stacks[0].Layers[0].P[1].min, 1e-6, 'frozen window kept');
  Assert.AreEqual(15.0, FS.Stacks[0].Layers[0].P[1].max, 1e-6);
end;

procedure TTestValidateLimits.Test_Recentre_ZeroWidthStaysPinned;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 9.0;
  FS.Stacks[0].Layers[0].P[1].min := 9.0;
  FS.Stacks[0].Layers[0].P[1].max := 9.0;

  RecentreOnValue(FS);

  Assert.AreEqual(9.0, FS.Stacks[0].Layers[0].P[1].min, 1e-6);
  Assert.AreEqual(9.0, FS.Stacks[0].Layers[0].P[1].max, 1e-6);
end;
```

- [ ] **Step 2: Run the tests to verify they fail**

Expected: build fails, `E2003 Undeclared identifier: 'RecentreOnValue'`.

- [ ] **Step 3: Implement**

Interface, after `CollapseFixed`:

```pascal
{ Slides every free parameter's window so its current value sits at the centre,
  keeping the width it had. A value that ended hard against a boundary can then
  keep exploring past it. Frozen parameters keep their stored window - they are
  pinned by CollapseFixed at hand-off instead. A window that is already zero
  width re-centres to zero width and so stays pinned; only Fixed thaws.
  Apply ClampToPhysics afterwards. }
procedure RecentreOnValue(var Structure: TFitStructure);
```

Implementation:

```pascal
procedure RecentreOnValue(var Structure: TFitStructure);
var
  i, j, p: Integer;

  procedure Recentre(var Value: TFitValue);
  var
    Half: Single;
  begin
    if Value.Fixed then
      Exit;
    Half := (Value.max - Value.min) / 2;
    if Half <= 0 then
      Exit;
    Value.min := Value.V - Half;
    Value.max := Value.V + Half;
  end;

begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
        Recentre(Structure.Stacks[i].Layers[j].P[p]);

  for p := 1 to 3 do
    Recentre(Structure.Subs.P[p]);
end;
```

- [ ] **Step 4: Run the tests to verify they pass**

Expected: **637 tests, 0 failures.**

- [ ] **Step 5: Commit**

```bash
git add XRayCalc3/Units/unit_SmartLimits.pas XRayCalc3/Tests/TestSmartLimits.pas
git commit -m "+ RecentreOnValue: slide a free parameter's window onto its fitted value

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 5: XRC_MCP carries the flag instead of eating it

XRC_MCP has its own reader and writer for the same project JSON, and the writer **rebuilds** each layer object from its own model — so a key it does not know is dropped. Without this task, a project frozen in the GUI comes back thawed after any MCP tool writes it.

**Files:**
- Modify: `XRC_MCP/units/unit_MCPStructure.pas:524` (writer), `:646` (reader), `:95` (doc comment)
- Test: `XRayCalc3/Tests/TestMCPStructure.pas:300` (`XRCData_HasAllSixteenLayerKeys`) and new tests

**Interfaces:**
- Consumes: `TFitValue.Fixed` from Task 1.
- Produces: the `HF` / `SF` / `RF` JSON keys. `fit_xrr` behaviour is unchanged — nothing in XRC_MCP calls `CollapseFixed`.

- [ ] **Step 1: Write the failing tests**

In `XRayCalc3/Tests/TestMCPStructure.pas`, rename the existing test and widen it. Change the declaration in the fixture's `type` block from `XRCData_HasAllSixteenLayerKeys` to:

```pascal
    [Test] procedure XRCData_HasAllNineteenLayerKeys;
```

and replace the implementation's `const` block and the two count-bearing lines:

```pascal
procedure TTestMCPStructure.XRCData_HasAllNineteenLayerKeys;
const
  KEYS: array [0..18] of string = ('M',
    'H', 'HP', 'HF', 'Hmin', 'Hmax', 'ProfileH',
    's', 'SP', 'SF', 'Smin', 'Smax', 'ProfileS',
    'r', 'RP', 'RF', 'Rmin', 'Rmax', 'ProfileR');
```

and later in the same procedure:

```pascal
    Assert.AreEqual(19, JLayer.Count, 'exactly the 19 GUI layer keys');
```

Leave the rest of that procedure as it is. Then add two new tests — declarations:

```pascal
    [Test] procedure XRCData_RoundTripsFixed;
    [Test] procedure XRCData_MissingFixedKeyIsThawed;
```

and implementations, following the style of the existing `XRCData_RoundTrip` (read it first and mirror its parse/serialize helpers exactly):

```pascal
procedure TTestMCPStructure.XRCData_RoundTripsFixed;
var
  J, JRoot: TJSONObject;
  S, Back: TFitStructure;
  Info: TStructureInfo;
  Data: string;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;

  S.Stacks[1].Layers[0].P[1].Fixed := True;
  S.Stacks[1].Layers[0].P[3].Fixed := True;

  Data := StructureToXRCData(S, Info);
  JRoot := TJSONObject.ParseJSONValue(Data) as TJSONObject;
  try
    Back := StructureFromXRCData(JRoot);
  finally
    JRoot.Free;
  end;

  Assert.IsTrue(Back.Stacks[1].Layers[0].P[1].Fixed, 'H stays frozen');
  Assert.IsFalse(Back.Stacks[1].Layers[0].P[2].Fixed, 'sigma stays free');
  Assert.IsTrue(Back.Stacks[1].Layers[0].P[3].Fixed, 'rho stays frozen');
end;

procedure TTestMCPStructure.XRCData_MissingFixedKeyIsThawed;
var
  JRoot: TJSONObject;
  Back: TFitStructure;
begin
  // A project written before the flag existed: no HF/SF/RF anywhere.
  JRoot := TJSONObject.ParseJSONValue(LEGACY_XRCDATA_JSON) as TJSONObject;
  Assert.IsNotNull(JRoot);
  try
    Back := StructureFromXRCData(JRoot);
  finally
    JRoot.Free;
  end;

  Assert.IsFalse(Back.Stacks[0].Layers[0].P[1].Fixed, 'absent key means thawed');
  Assert.IsFalse(Back.Stacks[0].Layers[0].P[2].Fixed);
  Assert.IsFalse(Back.Stacks[0].Layers[0].P[3].Fixed);
end;
```

**Before writing these:** read the fixture to find the real names of its parse helper, its XRC-data reader (the function around `unit_MCPStructure.pas:646`) and any existing legacy-JSON constant. Use those names; if there is no legacy constant, add one as a `const` in the fixture holding a minimal `{"Stacks":[...],"Subs":{...}}` document with `H`/`Hmin`/`Hmax` but no `HF`, modelled on the existing `RUC_JSON`.

- [ ] **Step 2: Run the tests to verify they fail**

Expected: `XRCData_HasAllNineteenLayerKeys` fails on the missing `HF` key; the round-trip test fails on `Fixed` coming back `False`.

- [ ] **Step 3: Implement the writer**

In `XRC_MCP/units/unit_MCPStructure.pas`, in the layer-writing loop at `:523-527`, add one line after the `'P'` pair:

```pascal
          JLayer.AddPair(PAlias[p], Data.P[p].V);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'P', Data.P[p].Paired);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'F', Data.P[p].Fixed);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'min', Data.P[p].min);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'max', Data.P[p].max);
```

- [ ] **Step 4: Implement the reader**

In the layer-reading loop at `:645-650`, add one line after the `'P'` read:

```pascal
          Result.Stacks[i].Layers[j].P[p].Paired := DataBool(JLayer, UpperCase(PAlias[p]) + 'P');
          Result.Stacks[i].Layers[j].P[p].Fixed := DataBool(JLayer, UpperCase(PAlias[p]) + 'F');
```

`DataBool` (`:561`) already returns `False` for an absent key, which is exactly the legacy behaviour the second test asserts.

- [ ] **Step 5: Update the doc comment**

At `:95`, change `16 H, HP, Hmin, ... keys per layer` to `19 H, HP, HF, Hmin, ... keys per layer`.

- [ ] **Step 6: Run the tests to verify they pass**

Expected: **639 tests, 0 failures** (637 from Task 4, plus the two new ones; the renamed test is not a new one).

- [ ] **Step 7: Commit**

```bash
git add XRC_MCP/units/unit_MCPStructure.pas XRayCalc3/Tests/TestMCPStructure.pas
git commit -m "* XRC_MCP round-trips the Fixed flag instead of dropping it on rewrite

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 6: GUI persistence

`unit_XRCStructure` is a VCL/Raize component unit and is not compiled into the console test runner, so this change is symmetric to Task 5 by inspection and is covered by that task's automated round-trip plus the user's check in the app.

**Files:**
- Modify: `XRayCalc3/Components/unit_XRCStructure.pas:732` (`ToString`), `:853` (`FromString`)

**Interfaces:**
- Consumes: `TFitValue.Fixed` from Task 1.
- Produces: `HF`/`SF`/`RF` in the `.xrcx` model string, matching Task 5 exactly.

- [ ] **Step 1: Write the key**

In the layer-writing loop at `:729-737`, add one line after the `'P'` pair:

```pascal
          JLayer.AddPair(PAlias[p], Data.P[p].V);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'P', Data.P[p].Paired);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'F', Data.P[p].Fixed);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'min', Data.P[p].min);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'max', Data.P[p].max);
```

- [ ] **Step 2: Read the key**

In the layer-reading loop at `:850-855`, add one line after the `'P'` read:

```pascal
          Data.P[p].Paired := FindBoolValue(UpperCase(PAlias[p]) + 'P');
          Data.P[p].Fixed := FindBoolValue(UpperCase(PAlias[p]) + 'F');
```

Confirm by reading it that `FindBoolValue` returns `False` for an absent key, as `DataBool` does. If it raises instead, wrap it the way the neighbouring `FindValue` calls supply their defaults — old projects have no `HF` and must load as thawed. **`CURRENT_PROJECT_VERSION` stays at 7.**

- [ ] **Step 3: Build the GUI for Win32**

```powershell
$env:BDS = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'; $env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0'; & 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' 'XRayCalc3\XRayCalc3.dproj' /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal
```

Expected: builds, hints and warnings only.

- [ ] **Step 4: Run the test suite**

Expected: **639 tests, 0 failures** — unchanged, this unit is not in the runner.

- [ ] **Step 5: Commit**

```bash
git add XRayCalc3/Components/unit_XRCStructure.pas
git commit -m "* Projects store the Fixed flag per parameter; absent means thawed

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 7: Split the write-back, then collapse at hand-off

The load-bearing task. `UpdateInterfaceP`/`NP` serve two jobs — carrying **edited limits** out of the dialog, and carrying **fitted values** back from the engine. Only the second may see collapsed ranges. Do the split **before** wiring in `CollapseFixed`, or the collapse destroys the user's limits.

**Files:**
- Modify: `XRayCalc3/Components/unit_XRCStructure.pas:95-96` (declarations), `:593` (`UpdateInterfaceNP`), `:616` (`UpdateInterfaceP`)
- Modify: `XRayCalc3/Units/unit_CalcOrchestrator.pas:300` (`UpdateInterface`), `:284` (`PrepareLFPSO`)
- Modify: `XRayCalc3/Forms/frm_Main.pas:569` (`OnSetFitLimits`)

**Interfaces:**
- Consumes: `CollapseFixed` from Task 1.
- Produces: `procedure UpdateInterfaceP(const Inp: TFitStructure; const ValuesOnly: Boolean = False);` and the matching `UpdateInterfaceNP` overload signature.

- [ ] **Step 1: Change the declarations**

In `XRayCalc3/Components/unit_XRCStructure.pas`, lines 95-96:

```pascal
      { ValuesOnly = True takes only V (and Material) from Inp and leaves min,
        max, Paired and Fixed as the live layer holds them. That is what the fit
        write-back needs: the structure handed to the engine has its frozen
        parameters collapsed to min = max = V, and those collapsed ranges must
        never flow back into the interface. ValuesOnly = False is the authoring
        route - the limits dialog writing the user's edits back. }
      procedure UpdateInterfaceP(const Inp: TFitStructure; const ValuesOnly: Boolean = False);
      procedure UpdateInterfaceNP(const Inp: TFitStructure; const ValuesOnly: Boolean = False);
```

- [ ] **Step 2: Implement in `UpdateInterfaceP`**

Replace the body at `:616`:

```pascal
procedure TXRCStructure.UpdateInterfaceP(const Inp: TFitStructure;
  const ValuesOnly: Boolean);
var
  i, j, p: integer;
  Data: TLayerData;
begin
  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].Layers) do
    begin
      // Start from the layer as it stands: a fresh TLayerData only has its
      // managed fields zeroed, so StackID/LayerID would arrive as stack
      // garbage and the layer would post that garbage back on the next click.
      Data := FStacks[i].Layers[j].Data;
      Data.Material := Inp.Stacks[i].Layers[j].Material;
      if ValuesOnly then
      begin
        for p := 1 to 3 do
          Data.P[p].V := Inp.Stacks[i].Layers[j].P[p].V;
      end
      else
        Data.P := Inp.Stacks[i].Layers[j].P;
      FStacks[i].UpdateLayer(j, Data);
    end;
  end;
end;
```

- [ ] **Step 3: Implement in `UpdateInterfaceNP`**

Replace the body at `:593`, keeping its `Count` walk exactly as it is:

```pascal
procedure TXRCStructure.UpdateInterfaceNP(const Inp: TFitStructure;
  const ValuesOnly: Boolean);
var
  i, j, p: integer;
  Count: integer;
  Data: TLayerData;
begin
  Count := 0;
  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].Layers) do
    begin
      // See UpdateInterfaceP: seed from the live layer so its cached
      // StackID/LayerID survive the write-back.
      Data := FStacks[i].Layers[j].Data;
      Data.Material := Inp.Stacks[0].Layers[Count].Material;
      if ValuesOnly then
      begin
        for p := 1 to 3 do
          Data.P[p].V := Inp.Stacks[0].Layers[Count].P[p].V;
      end
      else
        Data.P := Inp.Stacks[0].Layers[Count].P;
      FStacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (FStacks[i].N - 1) * (High(FStacks[i].Layers) + 1));
  end;
end;
```

- [ ] **Step 4: Pass `True` from the fit write-back funnel only**

In `XRayCalc3/Units/unit_CalcOrchestrator.pas`, in `TCalcOrchestrator.UpdateInterface` (`:300`), add `, True` to **all four** calls — at `:307`, `:311`, `:319` and `:327`. For example:

```pascal
    if FCalcSettings.FittingMode = fmPeriodic then
       Structure.UpdateInterfaceP(FitStructure, True)
```

**Do not touch** `unit_CalcOrchestrator.pas:244` or `frm_Main.pas:575`. Those are the authoring route and must keep the default `False`.

This one procedure covers the live-update path too: `HandleFitUpdate` (`:456`) calls it on every progress message when Live update is on.

- [ ] **Step 5: Collapse at hand-off**

In `PrepareLFPSO`, immediately before `FLFPSO.Structure := FFitStructure;` (`:284`):

```pascal
  { Frozen parameters become an empty range here and nowhere else. The engine
    has no concept of freezing; an empty range is what pins a value. }
  CollapseFixed(FFitStructure);
  FLFPSO.Structure := FFitStructure;
```

Add `unit_SmartLimits` to the unit's `uses` clause if it is not already there.

- [ ] **Step 6: Fix the Cancel bug in the same three lines**

In `XRayCalc3/Forms/frm_Main.pas:569`, `OnSetFitLimits` currently writes back whether the user presses Save or Cancel:

```pascal
procedure TfrmMain.OnSetFitLimits(Sender: TObject);
var
  FitStructure: TFitStructure;
begin
  FitStructure := Structure.ToFitStructure;
  if frmLimits.ShowLimits('Save', FitStructure) then
    Structure.UpdateInterfaceP(FitStructure);
end;
```

- [ ] **Step 7: Build Win32 and run the suite**

Build the GUI (Task 6, Step 3 command) and run the tests.
Expected: GUI builds; **639 tests, 0 failures.**

- [ ] **Step 8: Commit**

```bash
git add XRayCalc3/Components/unit_XRCStructure.pas XRayCalc3/Units/unit_CalcOrchestrator.pas XRayCalc3/Forms/frm_Main.pas
git commit -m "* Fit write-back takes values only, so frozen ranges never reach the interface

The limits dialog's own write-back keeps copying the whole TFitValue - that is
how edited limits reach the structure. Only TCalcOrchestrator.UpdateInterface,
the single funnel for fit results and live updates, asks for values only.
Frozen parameters are collapsed to an empty range in PrepareLFPSO.

Also: cancelling the limits dialog no longer commits the edits.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

---

### Task 8: Freeze columns in the limits dialog

**Files:**
- Modify: `XRayCalc3/Forms/frm_Limits.dfm` (columns, form and panel widths)
- Modify: `XRayCalc3/Forms/frm_Limits.pas` — `GetColumns` (`:206`), `StructureToView` (`:246`), `StructureFromView` (`:276`), `ListViewClick` (`:204`), `ListViewEditorExit` (`:230`), `ListViewCustomDrawSubItem` (`:363`)

**Interfaces:**
- Consumes: `TFitValue.Fixed` from Task 1.
- Produces: nothing other tasks call. Task 9 extends the same form.

**Column layout after this task** — `SubItems` is 0-based, the `SubItem` argument of `OnCustomDrawSubItem` is 1-based and equals `SubItems` index + 1:

| Column | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 | 9 |
|---|---|---|---|---|---|---|---|---|---|---|
| Caption | Layer | Fix | Hmin | Hmax | Fix | Smin | Smax | Fix | Rmin | Rmax |
| `SubItems` index | (caption) | 0 | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |

- [ ] **Step 1: Widen the form and add the columns**

In `XRayCalc3/Forms/frm_Limits.dfm`:
- `frmLimits.ClientWidth`: `569` → `666`
- `RzPanel1.Width`: `563` → `660`
- `RzPanel2.Width`: `563` → `660`
- `ListView.Width`: `553` → `650`
- `btnSet.Left`: `473` → `570`

Replace the `ListView.Columns` block with:

```
      Columns = <
        item
          Caption = 'Layer'
          Width = 100
        end
        item
          Alignment = taCenter
          Caption = 'Fix'
          Width = 30
        end
        item
          Alignment = taCenter
          Caption = 'Hmin'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Hmax'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Fix'
          Width = 30
        end
        item
          Alignment = taCenter
          Caption = 'Smin'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Smax'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Fix'
          Width = 30
        end
        item
          Alignment = taCenter
          Caption = 'RMin'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'RMax'
          Width = 84
        end>
```

Shift the four existing buttons right so they stay right-aligned in the wider panel, leaving `176` and `256` free for the two buttons Task 9 adds:

| Button | `Left` before | `Left` after |
|---|---|---|
| `btnInit` | 216 | 336 |
| `btnNarrow` | 296 | 416 |
| `btnWiden` | 376 | 496 |
| `btnFix` | 456 | 576 |

- [ ] **Step 2: Add the column-mapping helpers**

In `frm_Limits.pas`, add to the `private` section of `TfrmLimits`, **after** the existing fields and before the existing methods (fields before methods, or `E2169`):

```pascal
    function FreezeParamOf(const Column: Integer): Integer;
    function LimitCellOf(const Column: Integer): Integer;
```

And in the implementation:

```pascal
{ Columns run Layer, then (Fix, min, max) per parameter. Returns 1..3 for a
  freeze column, 0 for anything else. Column is 1-based, as OnCustomDrawSubItem
  and the hit test both report it. }
function TfrmLimits.FreezeParamOf(const Column: Integer): Integer;
begin
  if (Column >= 1) and ((Column - 1) mod 3 = 0) then
    Result := (Column - 1) div 3 + 1
  else
    Result := 0;
end;

{ The index CellState expects: 0..5 over (Hmin, Hmax, Smin, Smax, Rmin, Rmax),
  or -1 for a freeze column, which carries no limit and is never validated. }
function TfrmLimits.LimitCellOf(const Column: Integer): Integer;
var
  Group, Pos: Integer;
begin
  Group := (Column - 1) div 3;
  Pos := (Column - 1) mod 3;
  if Pos = 0 then
    Result := -1
  else
    Result := Group * 2 + (Pos - 1);
end;
```

- [ ] **Step 3: Replace `GetColumns` with a cumulative-width scan**

`ListViewClick`'s nested `GetColumns` assumes every column is as wide as the second — already wrong today (the last is 84, not 70) and unusable with 30-pixel checkbox columns. Replace the nested function inside `ListViewClick`:

```pascal
  function GetColumns(const X: integer): integer;
  var
    i, Edge: integer;
  begin
    Edge := 0;
    for i := 0 to ListView.Columns.Count - 1 do
    begin
      Inc(Edge, ListView.Columns[i].Width);
      if X < Edge then
        Exit(i);
    end;
    Result := -1;
  end;
```

- [ ] **Step 4: Branch the click**

In `ListViewClick`, after `EDIT_COLUMN := GetColumns(LPoint.X);`, insert:

```pascal
  P := FreezeParamOf(EDIT_COLUMN);
  if P > 0 then
  begin
    ListViewEditor.Visible := False;
    ToggleFreezeAt(ListView.GetItemAt(LPoint.X, LPoint.Y), P);
    Exit;
  end;
```

Declare `P: Integer;` in the procedure's `var` block. Add to the `private` section (with the other method declarations):

```pascal
    procedure ToggleFreezeAt(Item: TListItem; const ParamIndex: Integer);
```

Implementation:

```pascal
procedure TfrmLimits.ToggleFreezeAt(Item: TListItem; const ParamIndex: Integer);
var
  i, j, Index: Integer;
begin
  if Item = nil then
    Exit;

  Index := 0;
  for i := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      if Index = Item.Index then
      begin
        with FStructure.Stacks[i].Layers[j].P[ParamIndex] do
          Fixed := not Fixed;
        StructureToView;
        Exit;
      end;
      Inc(Index);
    end;
end;
```

`StructureToView` rebuilds the list and re-runs validation, so the greying and the group captions stay in step. Note it also discards any half-typed edit in the inline editor — that is why the editor is hidden first.

- [ ] **Step 5: Teach the view round-trip about the new columns**

In `StructureToView`, replace the inner `for p := 1 to 3 do` body so each parameter contributes three subitems:

```pascal
      for p := 1 to 3 do
      begin
        if FStructure.Stacks[i].Layers[j].P[p].Fixed then
          ListItem.SubItems.Add('X')
        else
          ListItem.SubItems.Add('');
        ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].P[p].min, ffFixed, 5, 2));
        ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].P[p].max, ffFixed, 5, 2));
      end;
```

In `StructureFromView`, the stride becomes 3 and the freeze cell is skipped — `Fixed` lives on `FStructure`, never parsed back out of the view:

```pascal
      Count := 1;
      for p := 1 to 3 do
      begin
        FStructure.Stacks[i].Layers[j].P[p].min := StrToFloat(ListView.Items[Index].SubItems[Count]);
        FStructure.Stacks[i].Layers[j].P[p].max := StrToFloat(ListView.Items[Index].SubItems[Count + 1]);
        Inc(Count, 3);
      end;
```

- [ ] **Step 6: Guard the inline editor and fix the validation tint**

In `ListViewEditorExit`, do not write a freeze column:

```pascal
procedure TfrmLimits.ListViewEditorExit(Sender: TObject);
begin
  If Assigned(LItem) and (FreezeParamOf(EDIT_COLUMN) = 0) Then
  Begin
    //assign the vslue of the TEdit to the Subitem
    LItem.SubItems[ EDIT_COLUMN-1 ] := ListViewEditor.Text;
    LItem := nil;
  End;
  RunValidation;
end;
```

In `ListViewCustomDrawSubItem`, map through `LimitCellOf` instead of `SubItem - 1`, and grey a frozen parameter's numbers:

```pascal
procedure TfrmLimits.ListViewCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
var
  Kind: TLimitIssueKind;
  Cell: Integer;
begin
  if SubItem < 1 then
    Exit;

  if Item.SubItems[((SubItem - 1) div 3) * 3] = 'X' then
    Sender.Canvas.Font.Color := clGrayText
  else
    Sender.Canvas.Font.Color := clWindowText;

  Cell := LimitCellOf(SubItem);
  if Cell < 0 then
    Exit;

  Kind := CellState(FIssues, Item.Index, Cell);

  case Kind of
    likError:
      Sender.Canvas.Brush.Color := $CCCCFF;  // light red
    likWarning:
      Sender.Canvas.Brush.Color := $CCFFFF;  // light yellow
  end;
end;
```

The `'X'` marker is drawn by the ListView itself as ordinary centred text — no owner-drawn checkbox is needed, and it reads clearly at any DPI.

- [ ] **Step 7: Build Win32**

Expected: builds, hints and warnings only.

- [ ] **Step 8: Run the suite**

Expected: **639 tests, 0 failures.**

- [ ] **Step 9: Commit and hand to the user**

```bash
git add XRayCalc3/Forms/frm_Limits.pas XRayCalc3/Forms/frm_Limits.dfm
git commit -m "+ Limits dialog: a Fix column per parameter, click to freeze

Also replaces GetColumns' uniform-width assumption with a cumulative scan, so
the inline editor lands on the right cell too.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

Then **ask the user to open the limits dialog and confirm** the columns line up, the `X` toggles, frozen rows grey out, and the inline editor still opens on the numeric cells. Do not launch the application.

---

### Task 9: Stack and multi-row gestures

**Files:**
- Modify: `XRayCalc3/Forms/frm_Limits.dfm` — `MultiSelect`, two `TBitBtn`, one `TPopupMenu` with four items
- Modify: `XRayCalc3/Forms/frm_Limits.pas` — handlers, group captions

**Interfaces:**
- Consumes: Task 8's `FStructure`-backed freeze state and `StructureToView`.
- Produces: nothing other tasks call.

- [ ] **Step 1: Add the controls to the DFM**

**Controls go in the DFM, never created at runtime.** In `RzPanel1`, beside the existing buttons:

```
    object btnFreeze: TBitBtn
      Left = 176
      Top = 391
      Width = 75
      Height = 25
      Caption = 'Freeze'
      TabOrder = 8
      Hint = 'Freeze every parameter of the selected layers'
      ShowHint = True
      OnClick = btnFreezeClick
    end
    object btnThaw: TBitBtn
      Left = 256
      Top = 391
      Width = 75
      Height = 25
      Caption = 'Thaw'
      TabOrder = 9
      Hint = 'Release every parameter of the selected layers'
      ShowHint = True
      OnClick = btnThawClick
    end
```

Set `ListView.MultiSelect = True` and `ListView.PopupMenu = pmFreeze`. Add at form level:

```
  object pmFreeze: TPopupMenu
    Left = 24
    Top = 440
    object miFreezeStack: TMenuItem
      Caption = 'Freeze this stack'
      OnClick = miFreezeStackClick
    end
    object miFreezeLayer: TMenuItem
      Caption = 'Freeze this layer'
      OnClick = miFreezeLayerClick
    end
    object miFreezeAll: TMenuItem
      Caption = 'Freeze all'
      OnClick = miFreezeAllClick
    end
    object miThawAll: TMenuItem
      Caption = 'Thaw all'
      OnClick = miThawAllClick
    end
  end
```

Declare all of them in the form class's published control list alongside `btnFix`, and the five handlers in the `published`/`private` section following the file's existing convention. `TPopupMenu` and `TMenuItem` need `Vcl.Menus` in the `uses` clause.

- [ ] **Step 2: Implement one worker and five thin handlers**

```pascal
{ Frozen: True freezes, False thaws. StackOnly limits the sweep to the stack the
  focused row belongs to; AllRows ignores the selection entirely. }
procedure TfrmLimits.SetFreeze(const Frozen, AllRows, StackOnly: Boolean);
var
  i, j, p, Index, FocusStack: Integer;
  Touch: Boolean;
begin
  FocusStack := -1;
  if StackOnly then
  begin
    if ListView.ItemFocused = nil then
      Exit;
    Index := 0;
    for i := 0 to High(FStructure.Stacks) do
      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        if Index = ListView.ItemFocused.Index then
          FocusStack := i;
        Inc(Index);
      end;
  end;

  Index := 0;
  for i := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      if AllRows then
        Touch := True
      else if StackOnly then
        Touch := (i = FocusStack)
      else
        Touch := ListView.Items[Index].Selected;

      if Touch then
        for p := 1 to 3 do
          FStructure.Stacks[i].Layers[j].P[p].Fixed := Frozen;

      Inc(Index);
    end;

  StructureToView;
end;

procedure TfrmLimits.btnFreezeClick(Sender: TObject);
begin
  SetFreeze(True, False, False);
end;

procedure TfrmLimits.btnThawClick(Sender: TObject);
begin
  SetFreeze(False, False, False);
end;

procedure TfrmLimits.miFreezeStackClick(Sender: TObject);
begin
  SetFreeze(True, False, True);
end;

procedure TfrmLimits.miFreezeLayerClick(Sender: TObject);
begin
  SetFreeze(True, False, False);
end;

procedure TfrmLimits.miFreezeAllClick(Sender: TObject);
begin
  SetFreeze(True, True, False);
end;

procedure TfrmLimits.miThawAllClick(Sender: TObject);
begin
  SetFreeze(False, True, False);
end;
```

Declare `procedure SetFreeze(const Frozen, AllRows, StackOnly: Boolean);` in the `private` section, after the fields.

Note `miFreezeLayer` and `btnFreeze` share a body: both act on the selection, and a right-click focuses and selects the row under the cursor.

- [ ] **Step 3: Put the roll-up in the group captions**

In `StructureToView`, replace the group header assignment:

```pascal
    Group := ListView.Groups.Add;
    Group.Header := StackCaption(i);
```

and add the helper, declared in the `private` section:

```pascal
function TfrmLimits.StackCaption(const StackIndex: Integer): string;
var
  j, p, Frozen, Total: Integer;
begin
  Frozen := 0;
  Total := 0;
  for j := 0 to High(FStructure.Stacks[StackIndex].Layers) do
    for p := 1 to 3 do
    begin
      Inc(Total);
      if FStructure.Stacks[StackIndex].Layers[j].P[p].Fixed then
        Inc(Frozen);
    end;

  Result := FStructure.Stacks[StackIndex].Header;
  if Frozen = 0 then
    Exit;
  if Frozen = Total then
    Result := Format('%s — all %d frozen', [Result, Total])
  else
    Result := Format('%s — %d of %d frozen', [Result, Frozen, Total]);
end;
```

- [ ] **Step 4: Build Win32**

Expected: builds, hints and warnings only.

- [ ] **Step 5: Run the suite**

Expected: **639 tests, 0 failures.**

- [ ] **Step 6: Commit and hand to the user**

```bash
git add XRayCalc3/Forms/frm_Limits.pas XRayCalc3/Forms/frm_Limits.dfm
git commit -m "+ Limits dialog: freeze by selection or stack, with a count in each group header

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

Then **ask the user to confirm** that Freeze/Thaw act on a multi-row selection, that "Freeze this stack" catches the right stack, and that the group captions count correctly.

---

### Task 10: The Resume command

**Files:**
- Modify: `XRayCalc3/Units/unit_CalcOrchestrator.pas` — `ResumeFitting`, plus a `Resume` flag through `GetFitParams`
- Modify: `XRayCalc3/Forms/frm_Main.pas` + `.dfm` — `actResumeFitting`
- Modify: `XRayCalc3/Views/frame_ChartPages.pas` — `PrepareConvergence` gains an append mode

**Interfaces:**
- Consumes: `RecentreOnValue` (Task 4), `ClampToPhysics`, `CollapseFixed` (Task 1), the values-only write-back (Task 7).
- Produces: `procedure TCalcOrchestrator.ResumeFitting;` and `property HasFitResults: Boolean` if the orchestrator does not already expose `FHasFitResults`.

- [ ] **Step 1: Let the chart append**

In `XRayCalc3/Views/frame_ChartPages.pas`, change the declaration to
`procedure PrepareConvergence(NMax: Integer; const Append: Boolean = False);`
and guard the clear at the top of the implementation:

```pascal
procedure TfrmChartPages.PrepareConvergence(NMax: Integer; const Append: Boolean);
begin
  if not Append then
    lsrConvergence.Clear;
```

Leave the rest of the body as it is.

Do the same for `PrepareDiagnostics`: declaration becomes
`procedure PrepareDiagnostics(NMax: Integer; const Append: Boolean = False);`,
and whatever it clears at the top of its body is guarded by `if not Append then`.
Read the procedure first — if it clears several series, guard them all together.

- [ ] **Step 2: Thread a `Resume` flag through the fit setup**

In `unit_CalcOrchestrator.pas`, change `GetFitParams` to `function GetFitParams(const Resume: Boolean): Boolean;` and, in the non-benchmark branch, re-centre before showing the dialog:

```pascal
    FFitStructure := Structure.ToFitStructure;
    if Resume then
    begin
      RecentreOnValue(FFitStructure);
      ClampToPhysics(FFitStructure);
    end;
    if frmLimits.ShowLimits(Caption, FFitStructure) then
          Structure.UpdateInterfaceP(FFitStructure)
```

where `Caption` is a local `string` set just above the dialog call:

```pascal
  if Resume then
    Caption := 'Resume'
  else
    Caption := 'Run';
```

Declare `Caption: string;` in the procedure's `var` block. Update the existing `RunFitting` call site to `GetFitParams(False)`.

Also give `PrepareLFPSO` a `Resume` parameter — `function PrepareLFPSO(const Resume: Boolean): Boolean;` in both the declaration and the implementation — and pass it to the two chart calls:

```pascal
  FChartPages.PrepareConvergence(FProjectPanel.FitParams.NMax, Resume);
  FChartPages.PrepareDiagnostics(FProjectPanel.FitParams.NMax, Resume);
```

- [ ] **Step 3: Extract the run body and add `ResumeFitting`**

`RunFitting` and `ResumeFitting` differ only in the flag. Rename the existing body to
`procedure TCalcOrchestrator.StartFitting(const Resume: Boolean);`, replacing its
`if not GetFitParams then Exit;` / `if not PrepareLFPSO then Exit;` with the
parameterised calls, and add:

```pascal
procedure TCalcOrchestrator.RunFitting;
begin
  StartFitting(False);
end;

{ Continue from where the last fit stopped: free parameters get their window
  slid onto the value they reached, frozen ones stay pinned to theirs. The best
  chi-squared is not carried across - changing the weight type changes the
  objective, so the two runs' numbers are not on the same scale. }
procedure TCalcOrchestrator.ResumeFitting;
begin
  if not FHasFitResults then
    Exit;
  StartFitting(True);
end;
```

Declare `StartFitting` in the `private` section and `ResumeFitting` in the `public` one, fields first in each. Leave `FABestChiSquare := 1e32;` where it is — the reset is deliberate.

- [ ] **Step 4: Add the action**

In `frm_Main.dfm`, beside `actAutoFitting` in the same `TActionList`:

```
    object actResumeFitting: TAction
      Category = 'Calc'
      Caption = 'Resume Fitting'
      Hint = 'Continue fitting from the last result, keeping frozen parameters pinned'
      Enabled = False
      OnExecute = actResumeFittingExecute
    end
```

Match `Category` to whatever `actAutoFitting` uses — read it first. Declare `actResumeFitting: TAction;` in the form class beside `actAutoFitting` (`frm_Main.pas:89`), and add:

```pascal
procedure TfrmMain.actResumeFittingExecute(Sender: TObject);
begin
  FOrchestrator.ResumeFitting;
end;
```

- [ ] **Step 5: Enable it once a fit has finished**

`Enabled = False` in the DFM, and set it to `True` where the orchestrator reports a finished fit. Find where `FOnEnableControls` is handled in `frm_Main.pas` and set `actResumeFitting.Enabled := FOrchestrator.HasFitResults;` alongside the other controls. Expose `HasFitResults` as a read-only property on `TCalcOrchestrator` over the existing `FHasFitResults` field if it is not already public.

Remember: setting `Enabled` in code does not fire any handler — nothing else needs calling.

- [ ] **Step 6: Add the toolbar or menu entry**

Put `actResumeFitting` next to the existing fitting entry in whichever menu and toolbar host `actAutoFitting`. Read the DFM to find them; add a `TMenuItem` with `Action = actResumeFitting` and a toolbar button the same way the neighbouring one is declared. **DFM only.**

- [ ] **Step 7: Build Win32**

Expected: builds, hints and warnings only.

- [ ] **Step 8: Run the suite**

Expected: **639 tests, 0 failures.**

- [ ] **Step 9: Commit and hand to the user**

```bash
git add XRayCalc3/Units/unit_CalcOrchestrator.pas XRayCalc3/Forms/frm_Main.pas XRayCalc3/Forms/frm_Main.dfm XRayCalc3/Views/frame_ChartPages.pas
git commit -m "+ Resume Fitting: continue from the last result with frozen parts pinned

Free parameters get their window slid onto the value the last fit reached,
keeping its width; frozen ones stay pinned. The convergence chart appends
rather than clearing, and the best chi-squared is not carried across, because
changing the weight type changes the objective.

Co-Authored-By: Claude Opus 5 <noreply@anthropic.com>"
```

Then **ask the user to run the full workflow**: fit, freeze the period stack, change the weight type, Resume, and confirm the frozen layers do not move while the others do.

---

## Final verification

- [ ] Build **XRayCalc3 Win32 Release** and **Win64 Release**; build **XRC_MCP Win64 Release** (it shares `unit_MCPStructure`, changed in Task 5).
- [ ] Run the suite: **639 tests, 0 failures, 0 leaked.**
- [ ] Confirm `CURRENT_PROJECT_VERSION` is still `7` and no version numbers were touched.
- [ ] Open a pre-existing `.xrcx` and confirm it loads with nothing frozen.
