# Extract Profile Calculation Logic — Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Extract pure math/physics logic from `unit_ProfilesManager.pas` into a new `math/unit_ProfileCalc.pas` with zero VCL dependencies, then add comprehensive unit tests.

**Architecture:** New unit provides standalone functions (`Erf`, `GetLayerVal`, `BuildLayers`, `CalcDensityProfile`) that operate on lightweight data records. `TProfileManager` becomes a thin wrapper that converts `TXRCStructure` to `TStacksData`, calls the pure functions, and plots the results.

**Tech Stack:** Delphi, DUnitX, no VCL dependencies in new unit.

---

### Task 1: Create `math/unit_ProfileCalc.pas` with types and `Erf`

**Files:**
- Create: `math/unit_ProfileCalc.pas`

**Step 1: Create the unit with types and Erf function**

```delphi
unit unit_ProfileCalc;

interface

uses
  unit_Types;

type
  TPLayer = record
    h, s, r: Single;
  end;

  TStackData = record
    N: Integer;
    Layers: TLayersData;
  end;
  TStacksData = array of TStackData;

  TDensityPoint = record
    Depth, Value: Single;
  end;

function Erf(const sigma, xmax: Single): Single;

implementation

uses
  System.Math;

function Erf(const sigma, xmax: Single): Single;
const
  dx = 0.05;
var
  x, i, pow: Single;
begin
  x := -sigma;
  i := 0;
  while x < xmax / (sigma / 1.77) do
  begin
    Pow := -1 * Sqr(x);
    i := i + dx * Exp(Pow);
    x := x + dx;
  end;
  Result := 1 / Sqrt(Pi) * i;
end;

end.
```

**Step 2: Commit**

Message: `Add unit_ProfileCalc with types and Erf function`

---

### Task 2: Write Erf tests

**Files:**
- Create: `Tests/TestProfileCalc.pas`

**Step 1: Write tests for Erf**

```delphi
unit TestProfileCalc;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestProfileCalc = class
  public
    [Test] procedure Test_Erf_ZeroSigma_ReturnsZero;
    [Test] procedure Test_Erf_Midpoint_ReturnsHalf;
    [Test] procedure Test_Erf_LargePositive_ApproachesOne;
    [Test] procedure Test_Erf_LargeNegative_ApproachesZero;
    [Test] procedure Test_Erf_Symmetry;
  end;

implementation

uses
  unit_ProfileCalc, System.Math;

procedure TTestProfileCalc.Test_Erf_ZeroSigma_ReturnsZero;
begin
  // sigma=0 means division by zero in xmax/(sigma/1.77) — the while
  // condition is never true (x=0 < +Inf is True but sigma=0 makes
  // the scaling degenerate). Actually when sigma=0, x starts at 0
  // and the limit is xmax/0 = +Inf, so loop runs forever.
  // Real usage always has sigma>0. Test with very small sigma instead.
  Assert.AreEqual(Single(0), Erf(0.001, 0), 0.01, 'Near-zero sigma at x=0');
end;

procedure TTestProfileCalc.Test_Erf_Midpoint_ReturnsHalf;
begin
  // At the midpoint (xmax=0), Erf integrates from -sigma to 0
  // which should be approximately 0.5 of the total integral
  Assert.AreEqual(Single(0.5), Erf(3.0, 0), 0.05, 'Midpoint ~0.5');
end;

procedure TTestProfileCalc.Test_Erf_LargePositive_ApproachesOne;
begin
  Assert.IsTrue(Erf(3.0, 20.0) > 0.95, 'Large positive xmax approaches 1.0');
end;

procedure TTestProfileCalc.Test_Erf_LargeNegative_ApproachesZero;
begin
  Assert.IsTrue(Erf(3.0, -20.0) < 0.05, 'Large negative xmax approaches 0.0');
end;

procedure TTestProfileCalc.Test_Erf_Symmetry;
var
  a, b: Single;
begin
  // Erf(s, x) + Erf(s, -x) should be approximately 1.0
  a := Erf(3.0, 5.0);
  b := Erf(3.0, -5.0);
  Assert.AreEqual(Single(1.0), a + b, 0.05, 'Symmetry: Erf(s,x) + Erf(s,-x) ~ 1');
end;

end.
```

**Step 2: Register in test project**

Add to `Tests/XRayCalc3Tests.dpr` uses clause:
```
  unit_ProfileCalc in '..\math\unit_ProfileCalc.pas',
  TestProfileCalc in 'TestProfileCalc.pas',
```

Add to `Tests/XRayCalc3Tests.dproj` ItemGroup:
```xml
  <DCCReference Include="..\math\unit_ProfileCalc.pas"/>
  <DCCReference Include="TestProfileCalc.pas"/>
```

**Step 3: Build and run tests — all 5 Erf tests should pass**

**Step 4: Commit**

Message: `Add Erf tests for unit_ProfileCalc — 5 tests`

---

### Task 3: Add `GetLayerVal` and tests

**Files:**
- Modify: `math/unit_ProfileCalc.pas`
- Modify: `Tests/TestProfileCalc.pas`

**Step 1: Add GetLayerVal to unit_ProfileCalc.pas interface + implementation**

```delphi
// interface
function GetLayerVal(const Stacks: TStacksData;
  StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer): Single;

// implementation
function GetLayerVal(const Stacks: TStacksData;
  StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer): Single;
begin
  if Length(Stacks[StackIdx].Layers[LayerIdx].PP[ValIdx]) > 1 then
    Result := Stacks[StackIdx].Layers[LayerIdx].PP[ValIdx][PeriodIdx - 1]
  else
    Result := Stacks[StackIdx].Layers[LayerIdx].P[ValIdx].V;
end;
```

**Step 2: Add tests**

```delphi
// Add to TTestProfileCalc:
[Test] procedure Test_GetLayerVal_ReturnsP_WhenPPEmpty;
[Test] procedure Test_GetLayerVal_ReturnsPP_WhenPPHasData;
[Test] procedure Test_GetLayerVal_ReturnsP_WhenPPSingleElement;

// Helper:
function MakeStacks(N: Integer; LayerH, LayerS, LayerR: Single): TStacksData;
```

Helper builds a single-stack, single-layer TStacksData for testing:

```delphi
function TTestProfileCalc.MakeStacks(N: Integer; LayerH, LayerS, LayerR: Single): TStacksData;
begin
  SetLength(Result, 1);
  Result[0].N := N;
  SetLength(Result[0].Layers, 1);
  Result[0].Layers[0].P[1].V := LayerH;
  Result[0].Layers[0].P[2].V := LayerS;
  Result[0].Layers[0].P[3].V := LayerR;
end;

procedure TTestProfileCalc.Test_GetLayerVal_ReturnsP_WhenPPEmpty;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  // PP is empty, should return P[Val].V
  Assert.AreEqual(Single(10.0), GetLayerVal(S, 0, 0, 1, 1), 'H from P');
  Assert.AreEqual(Single(2.0),  GetLayerVal(S, 0, 0, 1, 2), 'S from P');
  Assert.AreEqual(Single(5.0),  GetLayerVal(S, 0, 0, 1, 3), 'R from P');
end;

procedure TTestProfileCalc.Test_GetLayerVal_ReturnsPP_WhenPPHasData;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0, 13.0);
  Assert.AreEqual(Single(11.0), GetLayerVal(S, 0, 0, 1, 1), 'Period 1');
  Assert.AreEqual(Single(12.0), GetLayerVal(S, 0, 0, 2, 1), 'Period 2');
  Assert.AreEqual(Single(13.0), GetLayerVal(S, 0, 0, 3, 1), 'Period 3');
end;

procedure TTestProfileCalc.Test_GetLayerVal_ReturnsP_WhenPPSingleElement;
var
  S: TStacksData;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(99.0);
  // Length=1, should fall back to P[Val].V
  Assert.AreEqual(Single(10.0), GetLayerVal(S, 0, 0, 1, 1), 'Single PP falls back to P');
end;
```

**Step 3: Build and run — 3 new tests pass**

**Step 4: Commit**

Message: `Add GetLayerVal + 3 tests`

---

### Task 4: Add `BuildLayers` and tests

**Files:**
- Modify: `math/unit_ProfileCalc.pas`
- Modify: `Tests/TestProfileCalc.pas`

**Step 1: Add BuildLayers to unit_ProfileCalc.pas**

```delphi
// interface
function BuildLayers(const Stacks: TStacksData): TArray<TPLayer>;

// implementation
function BuildLayers(const Stacks: TStacksData): TArray<TPLayer>;
var
  StackIdx, LayerIdx, PeriodIdx: Integer;
  Layer: TPLayer;
begin
  Result := nil;
  for StackIdx := 0 to High(Stacks) do
    for PeriodIdx := 1 to Stacks[StackIdx].N do
      for LayerIdx := 0 to High(Stacks[StackIdx].Layers) do
      begin
        Layer.h := GetLayerVal(Stacks, StackIdx, LayerIdx, PeriodIdx, 1);
        Layer.s := GetLayerVal(Stacks, StackIdx, LayerIdx, PeriodIdx, 2);
        Layer.r := GetLayerVal(Stacks, StackIdx, LayerIdx, PeriodIdx, 3);
        Result := Result + [Layer];
      end;
end;
```

**Step 2: Add tests**

```delphi
[Test] procedure Test_BuildLayers_SingleStackSingleLayer;
[Test] procedure Test_BuildLayers_MultiPeriod;
[Test] procedure Test_BuildLayers_MultiStack;
[Test] procedure Test_BuildLayers_PPValues;

procedure TTestProfileCalc.Test_BuildLayers_SingleStackSingleLayer;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(1, 10.0, 2.0, 5.0);
  L := BuildLayers(S);
  Assert.AreEqual(1, Length(L));
  Assert.AreEqual(Single(10.0), L[0].h, 'h');
  Assert.AreEqual(Single(2.0),  L[0].s, 's');
  Assert.AreEqual(Single(5.0),  L[0].r, 'r');
end;

procedure TTestProfileCalc.Test_BuildLayers_MultiPeriod;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(3, 10.0, 2.0, 5.0);
  L := BuildLayers(S);
  Assert.AreEqual(3, Length(L), 'N=3 -> 3 layers');
end;

procedure TTestProfileCalc.Test_BuildLayers_MultiStack;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  SetLength(S, 2);
  S[0].N := 2;
  SetLength(S[0].Layers, 1);
  S[0].Layers[0].P[1].V := 10; S[0].Layers[0].P[2].V := 1; S[0].Layers[0].P[3].V := 3;
  S[1].N := 1;
  SetLength(S[1].Layers, 2);
  S[1].Layers[0].P[1].V := 20; S[1].Layers[0].P[2].V := 2; S[1].Layers[0].P[3].V := 4;
  S[1].Layers[1].P[1].V := 30; S[1].Layers[1].P[2].V := 3; S[1].Layers[1].P[3].V := 5;
  L := BuildLayers(S);
  // Stack 0: 2 periods * 1 layer = 2; Stack 1: 1 period * 2 layers = 2 -> total 4
  Assert.AreEqual(4, Length(L));
end;

procedure TTestProfileCalc.Test_BuildLayers_PPValues;
var
  S: TStacksData;
  L: TArray<TPLayer>;
begin
  S := MakeStacks(2, 10.0, 2.0, 5.0);
  S[0].Layers[0].PP[1] := TFloatArray.Create(11.0, 12.0);
  L := BuildLayers(S);
  Assert.AreEqual(2, Length(L));
  Assert.AreEqual(Single(11.0), L[0].h, 'Period 1 from PP');
  Assert.AreEqual(Single(12.0), L[1].h, 'Period 2 from PP');
  Assert.AreEqual(Single(2.0),  L[0].s, 'S from P (no PP)');
end;
```

**Step 3: Build and run — 4 new tests pass**

**Step 4: Commit**

Message: `Add BuildLayers + 4 tests`

---

### Task 5: Add `CalcDensityProfile` and tests

**Files:**
- Modify: `math/unit_ProfileCalc.pas`
- Modify: `Tests/TestProfileCalc.pas`

**Step 1: Add CalcDensityProfile to unit_ProfileCalc.pas**

```delphi
// interface
function CalcDensityProfile(const Layers: TArray<TPLayer>): TArray<TDensityPoint>;

// implementation
function CalcDensityProfile(const Layers: TArray<TPLayer>): TArray<TDensityPoint>;
var
  InLayerDepth, Depth, Val, s, rho, scale, EndDepth: Single;
  i: Integer;
  Pt: TDensityPoint;
begin
  Result := nil;
  if Length(Layers) = 0 then Exit;

  Depth := 0;
  for i := 0 to High(Layers) do
  begin
    s := Layers[i].s;
    if i = 0 then
    begin
      Depth := -s;
      rho := 0;
      scale := -Layers[i].r;
      if Length(Layers) > 1 then
        EndDepth := Layers[0].h - Layers[1].s
      else
        EndDepth := Layers[0].h;
    end
    else begin
      if Layers[i].s > Layers[i].h / 2 then
        s := Layers[i].h / 2;
      rho := Layers[i - 1].r;
      scale := rho - Layers[i].r;
      if i < High(Layers) then
        EndDepth := Layers[i].h - Layers[i + 1].s
      else
        EndDepth := Layers[i].h;
    end;

    InLayerDepth := -s;
    while InLayerDepth < EndDepth do
    begin
      InLayerDepth := InLayerDepth + 0.1;
      Depth := Depth + 0.1;
      if s > 0 then
        Val := rho - scale * Erf(s, InLayerDepth)
      else
        Val := rho;

      Pt.Depth := Depth;
      Pt.Value := Val;
      Result := Result + [Pt];
    end;
  end;
end;
```

**Step 2: Add tests**

```delphi
[Test] procedure Test_CalcDensity_EmptyInput;
[Test] procedure Test_CalcDensity_SingleLayer_MonotonicDepth;
[Test] procedure Test_CalcDensity_ZeroRoughness_StepFunction;
[Test] procedure Test_CalcDensity_WithRoughness_SmoothTransition;
[Test] procedure Test_CalcDensity_RoughnessClamped;
[Test] procedure Test_CalcDensity_SurfaceStartsNegative;

procedure TTestProfileCalc.Test_CalcDensity_EmptyInput;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
begin
  L := nil;
  D := CalcDensityProfile(L);
  Assert.AreEqual(0, Length(D));
end;

procedure TTestProfileCalc.Test_CalcDensity_SingleLayer_MonotonicDepth;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
  i: Integer;
begin
  SetLength(L, 1);
  L[0].h := 10; L[0].s := 1; L[0].r := 5;
  D := CalcDensityProfile(L);
  Assert.IsTrue(Length(D) > 0, 'Should produce points');
  for i := 1 to High(D) do
    Assert.IsTrue(D[i].Depth > D[i-1].Depth, 'Depth must be monotonically increasing');
end;

procedure TTestProfileCalc.Test_CalcDensity_ZeroRoughness_StepFunction;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
  i: Integer;
  AllEqual: Boolean;
begin
  // Two layers with zero roughness -> constant rho within each layer
  SetLength(L, 2);
  L[0].h := 10; L[0].s := 0; L[0].r := 3;
  L[1].h := 10; L[1].s := 0; L[1].r := 7;
  D := CalcDensityProfile(L);
  Assert.IsTrue(Length(D) > 10, 'Should produce many points');

  // Find the transition: first layer has rho=0 (surface, scale=-3), second has rho=3
  // With s=0, the Erf branch is skipped, so Val = rho directly
  // Layer 0 (surface): rho=0
  // Layer 1: rho = L[0].r = 3
  AllEqual := True;
  for i := 1 to High(D) do
    if Abs(D[i].Value - D[i-1].Value) > 0.01 then
    begin
      AllEqual := False;
      Break;
    end;
  Assert.IsFalse(AllEqual, 'Should have step between layers');
end;

procedure TTestProfileCalc.Test_CalcDensity_WithRoughness_SmoothTransition;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
  HasIntermediate: Boolean;
  i: Integer;
begin
  SetLength(L, 2);
  L[0].h := 20; L[0].s := 3; L[0].r := 0;
  L[1].h := 20; L[1].s := 3; L[1].r := 10;
  D := CalcDensityProfile(L);

  // With roughness, values should transition smoothly —
  // there should be intermediate values between 0 and 10
  HasIntermediate := False;
  for i := 0 to High(D) do
    if (D[i].Value > 1) and (D[i].Value < 9) then
    begin
      HasIntermediate := True;
      Break;
    end;
  Assert.IsTrue(HasIntermediate, 'Roughness should produce intermediate values');
end;

procedure TTestProfileCalc.Test_CalcDensity_RoughnessClamped;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
begin
  // Layer 1 has s > h/2 -> should be clamped
  SetLength(L, 2);
  L[0].h := 20; L[0].s := 1; L[0].r := 5;
  L[1].h := 4;  L[1].s := 10; L[1].r := 8;  // s=10 > h/2=2
  D := CalcDensityProfile(L);
  Assert.IsTrue(Length(D) > 0, 'Should not crash with clamped roughness');
end;

procedure TTestProfileCalc.Test_CalcDensity_SurfaceStartsNegative;
var
  L: TArray<TPLayer>;
  D: TArray<TDensityPoint>;
begin
  SetLength(L, 1);
  L[0].h := 10; L[0].s := 3; L[0].r := 5;
  D := CalcDensityProfile(L);
  Assert.IsTrue(D[0].Depth < 0, 'Surface layer starts at negative depth');
end;
```

**Step 3: Build and run — 6 new tests pass**

**Step 4: Commit**

Message: `Add CalcDensityProfile + 6 tests`

---

### Task 6: Refactor `unit_ProfilesManager.pas` to use `unit_ProfileCalc`

**Files:**
- Modify: `units/unit_ProfilesManager.pas`

**Step 1: Refactor ProfilesManager**

Changes:
1. Remove `TPLayer` record from interface (now in `unit_ProfileCalc`)
2. Remove `FLayers: array of TPLayer` field
3. Remove `GetVal` method declaration and implementation
4. Remove `FillLayers` method declaration and implementation
5. Remove standalone `Erf` function implementation
6. Remove `NesLib.FastMath` from implementation uses
7. Add `unit_ProfileCalc` to implementation uses
8. Rewrite `PlotDensityProfile` to call `BuildLayers` + `CalcDensityProfile`
9. Add private `StructureToStacks` helper method

The refactored `PlotDensityProfile`:

```delphi
procedure TProfileManager.PlotDensityProfile;
var
  Stacks: TStacksData;
  Layers: TArray<TPLayer>;
  Points: TArray<TDensityPoint>;
  i: Integer;
begin
  Stacks := StructureToStacks;
  Layers := BuildLayers(Stacks);
  Points := CalcDensityProfile(Layers);
  for i := 0 to High(Points) do
    FDensityProfile.AddXY(Points[i].Depth, Points[i].Value);
end;
```

The `StructureToStacks` helper:

```delphi
function TProfileManager.StructureToStacks: TStacksData;
var
  i, j: Integer;
begin
  SetLength(Result, Length(FStructure.Stacks));
  for i := 0 to High(FStructure.Stacks) do
  begin
    Result[i].N := FStructure.Stacks[i].N;
    Result[i].Layers := FStructure.Stacks[i].Layers.Data; // TLayersData
  end;
end;
```

Note: The exact accessor for `TXRCStack.Layers[j].Data` needs to match the existing pattern — check `GetLayersData` property on `TXRCStack`.

**Step 2: Build the main project to verify no regressions**

**Step 3: Commit**

Message: `Refactor ProfilesManager to use unit_ProfileCalc — thin UI wrapper`

---

### Task 7: Register new unit in main project and update TODO

**Files:**
- Modify: `Tests/TODO.md`

**Step 1: Update Tests/TODO.md — add item #16**

Add row:
```
| 16 | Add tests for `unit_ProfileCalc` — Erf, GetLayerVal, BuildLayers, CalcDensityProfile — 18 tests | 🟡 M | ✅ Done |
```

**Step 2: Commit TODO.md**

Message: `Updated Tests/TODO.md — item #16 done (unit_ProfileCalc, 18 tests)`
