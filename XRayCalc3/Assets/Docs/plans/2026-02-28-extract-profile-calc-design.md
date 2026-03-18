# Extract Testable Profile Calculation Logic

## Problem

`unit_ProfilesManager.pas` contains pure math/physics logic (error function, layer aggregation, density profile calculation) tangled with VCL charting (TLineSeries, TChart). This prevents unit testing.

## Approach

Extract pure functions into a new `math/unit_ProfileCalc.pas` unit with zero VCL dependencies. `TProfileManager` becomes a thin UI wrapper.

## New Unit: `math/unit_ProfileCalc.pas`

### Dependencies
- `unit_Types` (TLayerData, TLayersData, TFuncProfileRec, TProfileFunctions)
- `Math` (Sqrt, Pi, Exp, Sqr)
- `math_globals` (FuncProfile)

### Types

```delphi
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
```

### Functions

1. **`Erf(sigma, xmax): Single`** — numerical error function via trapezoidal integration. Replace `NesLib.FastMath.FastExp` with standard `System.Math.Exp`.

2. **`GetLayerVal(const Stacks: TStacksData; StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer): Single`** — reads layer parameter value, checking PP array first, falling back to P[Val].V.

3. **`BuildLayers(const Stacks: TStacksData): TArray<TPLayer>`** — iterates stacks/periods/layers, calls GetLayerVal, returns flat array of TPLayer.

4. **`CalcDensityProfile(const Layers: TArray<TPLayer>): TArray<TDensityPoint>`** — the density calculation loop from PlotDensityProfile. Returns (Depth, Value) pairs instead of calling AddXY.

## Changes to `unit_ProfilesManager.pas`

- Remove `Erf`, `TPLayer`, `FillLayers`, `GetVal`
- Add `unit_ProfileCalc` to uses
- `PlotDensityProfile` calls `BuildLayers` + `CalcDensityProfile`, iterates result calling `FDensityProfile.AddXY`
- Add helper to convert `TXRCStructure.Stacks` to `TStacksData`

## Test File: `Tests/TestProfileCalc.pas`

### Test Cases

**Erf:**
- Erf(0, x) returns 0 (zero sigma = no broadening)
- Erf(sigma, 0) returns ~0.5 (midpoint)
- Erf(sigma, large_x) approaches 1.0
- Erf(sigma, -large_x) approaches 0.0
- Symmetry: Erf(s, x) + Erf(s, -x) ~ 1.0

**GetLayerVal:**
- Returns P[Val].V when PP is empty
- Returns PP[Val][PeriodIdx-1] when PP has data
- Handles single-element PP (falls back to P.V)

**BuildLayers:**
- Single stack, single layer, N=1 -> 1 TPLayer
- Multi-layer stack with N>1 -> N*LayerCount TPLayers
- Skips stacks with N=1 (matches original behavior) — WAIT: FillLayers does NOT skip N=1. PlotSimpleProfile etc. skip N=1, but FillLayers iterates all stacks. Keep original behavior.
- Values correctly read from PP arrays when present

**CalcDensityProfile:**
- Single layer -> monotonic depth values
- Two layers with zero roughness -> step function (constant rho within each layer)
- Layer with roughness -> smooth transition via Erf
- Roughness clamped to h/2 for non-surface layers
- Surface layer starts at negative depth
- Empty input -> empty output
