# Universal Mirror Optimizer — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking. Always invoke the `delphi-development` skill before writing any Delphi code.

**Goal:** Add a `-u` mode to xrccmd that optimizes multilayer mirror structures for simultaneous high reflectivity across Be-Mg wavelengths using LFPSO.

**Architecture:** Standalone PSO optimizer with its own particle representation (composition fractions + structural parameters). Builds TLayers arrays directly from the genome, evaluates reflectivity at multiple wavelengths using the existing cmd TCalc engine. Scalar Figure of Merit combines peak R and FWHM across all targets.

**Tech Stack:** Delphi/Object Pascal, OmniThreadLibrary for parallelism, System.JSON for config/checkpoint I/O, existing cmd_unit_calc.TCalc for Fresnel reflectivity, cmd_math_globals.ReadHenke for material database.

**Spec:** `docs/superpowers/specs/2026-03-16-universal-mirror-design.md`

---

## File Structure

| File | Responsibility |
|------|----------------|
| `XRC_CMD/units/cmd_unit_universal_types.pas` | All type declarations: TGenome, TParticle, TTargetElement, TUniversalConfig, TElementData, TTargetResult |
| `Math/unit_materials_mix.pas` | Henke caching, mixed-material optical constants computation |
| `XRC_CMD/units/cmd_unit_universal_io.pas` | JSON config loading, checkpoint save/load, progress logging, result export |
| `XRC_CMD/units/cmd_unit_universal_fitness.pas` | Build TLayers from genome, evaluate R/FWHM per target wavelength, compute FoM |
| `XRC_CMD/units/cmd_unit_universal_pso.pas` | PSO/Levy flight velocity update, reflective boundaries, composition normalization, shake, diversity |
| `XRC_CMD/units/cmd_unit_universal.pas` | Main orchestrator: initialization, main loop, convergence checks, Ctrl+C handler |
| `XRC_CMD/xrccmd.dpr` | Add `-u` switch dispatch |
| `Tests/test_materials_mix.pas` | Unit tests for mixed-material optical constants |

---

## Chunk 1: Foundation — Types and Material Mixing

### Task 1: Core Type Declarations

**Files:**
- Create: `XRC_CMD/units/cmd_unit_universal_types.pas`

- [ ] **Step 1: Create the types unit with all record definitions**

```pascal
unit cmd_unit_universal_types;

interface

uses
  System.SysUtils, System.Math;

const
  MAX_POOL_ELEMENTS = 16;
  MAX_TARGETS = 16;
  LAYERS_PER_PERIOD = 2; // bilayer v1.0

type
  // Per-element cached Henke data
  TElementData = record
    Name: string;
    AtomicMass: Single;   // A (g/mol)
    BulkDensity: Single;  // rho (g/cm3)
  end;

  // Cached f1/f2 at a specific wavelength for one element
  THenkeCacheEntry = record
    f1, f2: Single;
  end;

  // Target element definition
  TTargetElement = record
    Name: string;
    Lambda: Single;       // Ka wavelength in Angstroms
    Weight: Single;       // relative weight in FoM
  end;

  // Result of evaluating one target wavelength
  TTargetResult = record
    RPeak: Single;        // peak reflectivity (0..1)
    FWHM: Single;         // angular FWHM in degrees
    ThetaBragg: Single;   // Bragg angle in degrees
    Valid: Boolean;        // false if lambda/2d > 1 (no Bragg peak)
  end;

  // Range parameter (min/max bounds)
  TParamRange = record
    Min, Max: Single;
  end;

  // Composition fractions for one layer role
  TCompositionGenes = array of Single; // length = element_pool count, sum = 1.0

  // Full genome for one particle
  TGenome = record
    Composition: array [0..LAYERS_PER_PERIOD-1] of TCompositionGenes; // per-layer fractions
    d: Single;              // period thickness (A)
    Gamma: Single;          // reflector/period ratio
    N: Single;              // number of periods (float, rounded for eval)
    Sigma: Single;          // interface roughness (A)
    DensityFactor: array [0..LAYERS_PER_PERIOD-1] of Single; // per-layer density multiplier
  end;

  // Velocity vector (same shape as genome)
  TVelocity = record
    Composition: array [0..LAYERS_PER_PERIOD-1] of TCompositionGenes;
    d: Single;
    Gamma: Single;
    N: Single;
    Sigma: Single;
    DensityFactor: array [0..LAYERS_PER_PERIOD-1] of Single;
  end;

  // One particle in the swarm
  TParticle = record
    X: TGenome;           // current position
    V: TVelocity;         // velocity
    PBest: TGenome;       // personal best position
    PBestFoM: Single;     // personal best FoM (negated for minimization)
    CurrentFoM: Single;   // current FoM (negated)
    TargetResults: array of TTargetResult; // per-target evaluation results
  end;

  PParticle = ^TParticle;
  TTargetResults = array of TTargetResult; // concrete type for var/out parameters

  // Structure configuration from JSON
  TStructureConfig = record
    StructureType: string;  // 'bilayer'
    LayersPerPeriod: Integer;
    dRange: TParamRange;
    GammaRange: TParamRange;
    NRange: TParamRange;
    SigmaRange: TParamRange;
    DensityFactorRange: TParamRange;
  end;

  // Fitness configuration from JSON
  TFitnessConfig = record
    wR: Single;             // weight for R_peak
    wFWHM: Single;          // weight for FWHM penalty
    RMinThreshold: Single;  // minimum acceptable R_peak
  end;

  // Optimizer configuration from JSON
  TOptimizerConfig = record
    Population: Integer;
    Iterations: Integer;
    Tolerance: Single;
    StagnationLimit: Integer;
    w1, w2: Single;         // PSO inertia weight range
    JammingMax: Integer;
    CheckpointEvery: Integer;
  end;

  // Full configuration
  TUniversalConfig = record
    Targets: array of TTargetElement;
    ElementPool: array of string;
    Structure: TStructureConfig;
    Fitness: TFitnessConfig;
    Optimizer: TOptimizerConfig;
    Substrate: string;
    HenkePath: string;
    OutputDir: string;
    ResumeFrom: string;
  end;

  // Optimizer state (for checkpoint/resume)
  TOptState = record
    Iteration: Integer;
    GBest: TGenome;
    GBestFoM: Single;
    ABest: TGenome;
    ABestFoM: Single;
    JammingCount: Integer;
    Particles: array of TParticle;
  end;

// Utility functions
function CreateGenome(PoolSize: Integer): TGenome;
function CreateVelocity(PoolSize: Integer): TVelocity;
function NRound(Value: Single): Integer; // round N for evaluation

implementation

function CreateGenome(PoolSize: Integer): TGenome;
var
  i: Integer;
begin
  for i := 0 to LAYERS_PER_PERIOD - 1 do
    SetLength(Result.Composition[i], PoolSize);
  Result.d := 0;
  Result.Gamma := 0;
  Result.N := 0;
  Result.Sigma := 0;
  Result.DensityFactor[0] := 1.0;
  Result.DensityFactor[1] := 1.0;
end;

function CreateVelocity(PoolSize: Integer): TVelocity;
var
  i: Integer;
begin
  for i := 0 to LAYERS_PER_PERIOD - 1 do
    SetLength(Result.Composition[i], PoolSize);
  Result.d := 0;
  Result.Gamma := 0;
  Result.N := 0;
  Result.Sigma := 0;
  Result.DensityFactor[0] := 0;
  Result.DensityFactor[1] := 0;
end;

function NRound(Value: Single): Integer;
begin
  Result := Max(1, Round(Value));
end;

end.
```

- [ ] **Step 2: Build to verify syntax**

Run:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1
```
Note: The unit must be added to the .dpr uses clause first (Task 7), but for now just verify the file is syntactically valid by attempting a build. If it fails because it's not in the project, that's expected — we just want no Pascal syntax errors.

- [ ] **Step 3: Commit**

```
git add XRC_CMD/units/cmd_unit_universal_types.pas
git commit -m "+ Add Universal Mirror type declarations"
```

---

### Task 2: Material Mixing and Henke Caching

**Files:**
- Create: `Math/unit_materials_mix.pas`

**Context:**
- `ReadHenke` in `cmd_math_globals.pas` has signature: `procedure ReadHenke(const Name: string; E, L: single; var f: TComplex; var Na, Nro: single);`
- `H = 12398.6` is the energy-wavelength conversion constant
- `ClassicalElectronRadius = 0.54014E-5` is in `cmd_unit_materials.pas`
- `TComplex` type from `math_complex.pas` has `.re` and `.im` fields

- [ ] **Step 1: Create the material mixing unit**

```pascal
unit unit_materials_mix;

interface

uses
  System.SysUtils, System.Math, math_complex, cmd_math_globals;

const
  ClassicalElectronRadius = 0.54014E-5;

type
  // Per-element wavelength-independent data
  TElementInfo = record
    Name: string;
    AtomicMass: Single;
    BulkDensity: Single;
  end;

  // Cached f1/f2 for one element at one wavelength
  TCachedHenke = record
    f1, f2: Single;
  end;

  TMaterialMixer = class
  private
    FElements: array of TElementInfo;
    // FHenkeCache[element_idx, target_idx] -> (f1, f2)
    FHenkeCache: array of array of TCachedHenke;
    FTargetLambdas: array of Single;
    FHenkePath: string;
    FElementCount: Integer;
    FTargetCount: Integer;
    // Substrate data
    FSubstrateName: string;
    FSubstrateInfo: TElementInfo;
    FSubstrateHenke: array of TCachedHenke; // per target wavelength
  public
    constructor Create;
    procedure Initialize(const ElementNames: array of string;
      const TargetLambdas: array of Single;
      const SubstrateName: string;
      const HenkePath: string);

    // Compute mixed dielectric constant for a layer
    procedure CalcMixedEpsilon(
      const Fractions: array of Single;  // element mixing fractions (sum=1)
      DensityFactor: Single;             // density multiplier
      TargetIdx: Integer;                // which target wavelength
      out Epsilon: TComplex;             // output dielectric constant
      out EffDensity: Single             // output effective density
    );

    // Compute substrate dielectric constant at a target wavelength
    procedure CalcSubstrateEpsilon(
      TargetIdx: Integer;
      out Epsilon: TComplex
    );

    property ElementCount: Integer read FElementCount;
    property TargetCount: Integer read FTargetCount;
  end;

implementation

constructor TMaterialMixer.Create;
begin
  inherited;
  FElementCount := 0;
  FTargetCount := 0;
end;

procedure TMaterialMixer.Initialize(const ElementNames: array of string;
  const TargetLambdas: array of Single;
  const SubstrateName: string;
  const HenkePath: string);
var
  i, j: Integer;
  f: TComplex;
  Na, Nro: Single;
  SavedDir: string;
begin
  FHenkePath := HenkePath;
  FElementCount := Length(ElementNames);
  FTargetCount := Length(TargetLambdas);

  SetLength(FElements, FElementCount);
  SetLength(FHenkeCache, FElementCount, FTargetCount);
  SetLength(FTargetLambdas, FTargetCount);

  for j := 0 to FTargetCount - 1 do
    FTargetLambdas[j] := TargetLambdas[j];

  // Change to Henke parent directory for ReadHenke file access
  // ReadHenke looks for '.\Henke\{Name}.bin', so CWD must be the PARENT of the Henke dir
  SavedDir := GetCurrentDir;
  try
    SetCurrentDir(ExtractFilePath(ExcludeTrailingPathDelimiter(FHenkePath)));

    // Load per-element data
    for i := 0 to FElementCount - 1 do
    begin
      FElements[i].Name := ElementNames[i];
      // Read at first target wavelength to get atomic mass and density
      ReadHenke(ElementNames[i], 0, FTargetLambdas[0], f, Na, Nro);
      FElements[i].AtomicMass := Na;
      FElements[i].BulkDensity := Nro;

      // Cache f1/f2 at all target wavelengths
      for j := 0 to FTargetCount - 1 do
      begin
        ReadHenke(ElementNames[i], 0, FTargetLambdas[j], f, Na, Nro);
        FHenkeCache[i][j].f1 := f.re;
        FHenkeCache[i][j].f2 := f.im;
      end;
    end;

    // Load substrate data
    FSubstrateName := SubstrateName;
    ReadHenke(SubstrateName, 0, FTargetLambdas[0], f, Na, Nro);
    FSubstrateInfo.Name := SubstrateName;
    FSubstrateInfo.AtomicMass := Na;
    FSubstrateInfo.BulkDensity := Nro;

    SetLength(FSubstrateHenke, FTargetCount);
    for j := 0 to FTargetCount - 1 do
    begin
      ReadHenke(SubstrateName, 0, FTargetLambdas[j], f, Na, Nro);
      FSubstrateHenke[j].f1 := f.re;
      FSubstrateHenke[j].f2 := f.im;
    end;
  finally
    SetCurrentDir(SavedDir);
  end;
end;

procedure TMaterialMixer.CalcMixedEpsilon(
  const Fractions: array of Single;
  DensityFactor: Single;
  TargetIdx: Integer;
  out Epsilon: TComplex;
  out EffDensity: Single);
var
  i: Integer;
  f1_mix, f2_mix, A_mix, rho_mix, c: Single;
  Lambda: Single;
begin
  f1_mix := 0;
  f2_mix := 0;
  A_mix := 0;
  rho_mix := 0;

  for i := 0 to FElementCount - 1 do
  begin
    f1_mix := f1_mix + Fractions[i] * FHenkeCache[i][TargetIdx].f1;
    f2_mix := f2_mix + Fractions[i] * FHenkeCache[i][TargetIdx].f2;
    A_mix  := A_mix  + Fractions[i] * FElements[i].AtomicMass;
    rho_mix := rho_mix + Fractions[i] * FElements[i].BulkDensity;
  end;

  rho_mix := rho_mix * DensityFactor;
  EffDensity := rho_mix;

  Lambda := FTargetLambdas[TargetIdx];
  c := ClassicalElectronRadius * rho_mix / A_mix * Sqr(Lambda);

  Epsilon.re := 1 - f1_mix * c;
  Epsilon.im := f2_mix * c;
end;

procedure TMaterialMixer.CalcSubstrateEpsilon(
  TargetIdx: Integer;
  out Epsilon: TComplex);
var
  c, Lambda: Single;
begin
  Lambda := FTargetLambdas[TargetIdx];
  c := ClassicalElectronRadius * FSubstrateInfo.BulkDensity
       / FSubstrateInfo.AtomicMass * Sqr(Lambda);

  Epsilon.re := 1 - FSubstrateHenke[TargetIdx].f1 * c;
  Epsilon.im := FSubstrateHenke[TargetIdx].f2 * c;
end;

end.
```

- [ ] **Step 2: Build to verify syntax**

Build xrccmd project (unit must be added to .dpr first — or just verify Pascal syntax with a quick compilation attempt).

- [ ] **Step 3: Commit**

```
git add Math/unit_materials_mix.pas
git commit -m "+ Add mixed-material Henke caching and optical constants"
```

---

### Task 3: Unit Tests for Material Mixing

**Files:**
- Create: `Tests/test_materials_mix.pas`
- Modify: `Tests/XRayCalc3Tests.dpr` — add test unit to uses clause

**Context:** Tests use DUnitX framework. Test runner: `Tests/_Out/BIN/XRayCalc3Tests.exe`

- [ ] **Step 1: Write tests for material mixing correctness**

```pascal
unit test_materials_mix;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Math,
  math_complex, unit_materials_mix;

type
  [TestFixture]
  TTestMaterialMix = class
  private
    FMixer: TMaterialMixer;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    // Pure element: fractions [1,0,...] should match single-element Henke lookup
    procedure TestPureElementMatchesHenke;

    [Test]
    // 50/50 mix: f1_mix should be average of two elements' f1
    procedure TestEqualMixAveragesScatteringFactors;

    [Test]
    // Epsilon real part should be < 1 (refraction in XUV)
    procedure TestEpsilonRealPartLessThanOne;

    [Test]
    // Epsilon imaginary part should be > 0 (absorption)
    procedure TestEpsilonImagPartPositive;

    [Test]
    // Substrate epsilon should be computable
    procedure TestSubstrateEpsilon;

    [Test]
    // Density factor scales effective density
    procedure TestDensityFactorScaling;
  end;

implementation

uses
  cmd_math_globals;

procedure TTestMaterialMix.Setup;
var
  Elements: array of string;
  Lambdas: array of Single;
begin
  FMixer := TMaterialMixer.Create;
  SetLength(Elements, 3);
  Elements[0] := 'W';
  Elements[1] := 'Si';
  Elements[2] := 'C';

  SetLength(Lambdas, 2);
  Lambdas[0] := 44.7;  // C Ka
  Lambdas[1] := 23.6;  // O Ka

  // HenkePath must point to directory containing Henke/*.bin files
  FMixer.Initialize(Elements, Lambdas, 'Si',
    ExtractFilePath(ParamStr(0)) + '..\..\Henke');
end;

procedure TTestMaterialMix.TearDown;
begin
  FMixer.Free;
end;

procedure TTestMaterialMix.TestPureElementMatchesHenke;
var
  Eps: TComplex;
  Dens: Single;
  Fractions: array[0..2] of Single;
  f: TComplex;
  Na, Nro, c: Single;
begin
  // Pure tungsten
  Fractions[0] := 1.0; Fractions[1] := 0.0; Fractions[2] := 0.0;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps, Dens);

  // Compare with direct Henke lookup
  ReadHenke('W', 0, 44.7, f, Na, Nro);
  c := ClassicalElectronRadius * Nro / Na * Sqr(44.7);

  Assert.AreEqual(1 - f.re * c, Eps.re, 1e-6, 'Epsilon real mismatch');
  Assert.AreEqual(f.im * c, Eps.im, 1e-6, 'Epsilon imag mismatch');
end;

procedure TTestMaterialMix.TestEqualMixAveragesScatteringFactors;
var
  EpsPure1, EpsPure2, EpsMix: TComplex;
  Dens1, Dens2, DensMix: Single;
  F1, F2, FMix: array[0..2] of Single;
begin
  F1[0] := 1.0; F1[1] := 0.0; F1[2] := 0.0; // pure W
  F2[0] := 0.0; F2[1] := 1.0; F2[2] := 0.0; // pure Si
  FMix[0] := 0.5; FMix[1] := 0.5; FMix[2] := 0.0; // 50/50

  FMixer.CalcMixedEpsilon(F1, 1.0, 0, EpsPure1, Dens1);
  FMixer.CalcMixedEpsilon(F2, 1.0, 0, EpsPure2, Dens2);
  FMixer.CalcMixedEpsilon(FMix, 1.0, 0, EpsMix, DensMix);

  // Mix density should be average of pure densities
  Assert.AreEqual((Dens1 + Dens2) / 2, DensMix, 0.01, 'Density mismatch');
end;

procedure TTestMaterialMix.TestEpsilonRealPartLessThanOne;
var
  Eps: TComplex;
  Dens: Single;
  Fractions: array[0..2] of Single;
begin
  Fractions[0] := 0.5; Fractions[1] := 0.3; Fractions[2] := 0.2;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps, Dens);
  Assert.IsTrue(Eps.re < 1.0, 'Epsilon real should be < 1 in XUV');
end;

procedure TTestMaterialMix.TestEpsilonImagPartPositive;
var
  Eps: TComplex;
  Dens: Single;
  Fractions: array[0..2] of Single;
begin
  Fractions[0] := 0.5; Fractions[1] := 0.3; Fractions[2] := 0.2;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps, Dens);
  Assert.IsTrue(Eps.im > 0, 'Epsilon imag (absorption) should be positive');
end;

procedure TTestMaterialMix.TestSubstrateEpsilon;
var
  Eps: TComplex;
begin
  FMixer.CalcSubstrateEpsilon(0, Eps);
  Assert.IsTrue(Eps.re < 1.0, 'Substrate eps.re should be < 1');
  Assert.IsTrue(Eps.im > 0, 'Substrate eps.im should be > 0');
end;

procedure TTestMaterialMix.TestDensityFactorScaling;
var
  Eps1, Eps05: TComplex;
  Dens1, Dens05: Single;
  Fractions: array[0..2] of Single;
begin
  Fractions[0] := 1.0; Fractions[1] := 0.0; Fractions[2] := 0.0;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps1, Dens1);
  FMixer.CalcMixedEpsilon(Fractions, 0.5, 0, Eps05, Dens05);
  Assert.AreEqual(Dens1 * 0.5, Dens05, 0.01, 'Half density factor -> half density');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMaterialMix);

end.
```

- [ ] **Step 2: Add test unit to test project**

Add `test_materials_mix in 'test_materials_mix.pas'` to the uses clause of `Tests/XRayCalc3Tests.dpr`.
Also add `unit_materials_mix in '..\Math\unit_materials_mix.pas'` if not already resolvable via search paths.

- [ ] **Step 3: Build and run tests**

Build tests:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

Run tests (filter to material mix tests):
```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All 6 material mixing tests pass.

- [ ] **Step 4: Commit**

```
git add Tests/test_materials_mix.pas Math/unit_materials_mix.pas
git commit -m "+ Add material mixing tests"
```

---

## Chunk 2: I/O — Config Loading and Output

### Task 4: JSON Config Loader and Output Writer

**Files:**
- Create: `XRC_CMD/units/cmd_unit_universal_io.pas`

**Context:**
- Existing JSON loading pattern in `cmd_unit_load.pas` uses `System.JSON` (TJSONObject, TJSONArray)
- Config JSON structure defined in spec lines 24-65
- Output files: progress.log, best_structure.json, best_curves/*.dat, population.json, checkpoint.json

- [ ] **Step 1: Create the I/O unit with config loading**

```pascal
unit cmd_unit_universal_io;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.Math,
  cmd_unit_universal_types, cmd_unit_types;

type
  TUniversalIO = class
  private
    FOutputDir: string;
    FLogFile: TextFile;
    FLogOpen: Boolean;
    procedure EnsureOutputDir;
  public
    constructor Create;
    destructor Destroy; override;

    // Config loading
    class function LoadConfig(const FileName: string): TUniversalConfig;

    // Progress logging
    procedure OpenLog(const OutputDir: string);
    procedure LogIteration(Iteration: Integer; FoM: Single;
      const TargetResults: array of TTargetResult;
      const TargetNames: array of string;
      Diversity: Single);
    procedure CloseLog;

    // Result output
    procedure SaveBestStructure(const Config: TUniversalConfig;
      const Best: TGenome; FoM: Single;
      const TargetResults: array of TTargetResult;
      const OutputDir: string);
    procedure SaveCurve(const Element: string; const Curve: TDataArray;
      const OutputDir: string);
    procedure SavePopulation(const Config: TUniversalConfig;
      const Particles: array of TParticle;
      TopN: Integer; const OutputDir: string);

    // Checkpoint save/load
    procedure SaveCheckpoint(const State: TOptState;
      const Config: TUniversalConfig;
      const OutputDir: string);
    function LoadCheckpoint(const FileName: string;
      const Config: TUniversalConfig): TOptState;
  end;

implementation

constructor TUniversalIO.Create;
begin
  inherited;
  FLogOpen := False;
end;

destructor TUniversalIO.Destroy;
begin
  if FLogOpen then
    CloseLog;
  inherited;
end;

procedure TUniversalIO.EnsureOutputDir;
begin
  if not TDirectory.Exists(FOutputDir) then
    TDirectory.CreateDirectory(FOutputDir);
end;

class function TUniversalIO.LoadConfig(const FileName: string): TUniversalConfig;
var
  JSON: TJSONObject;
  JTargets, JPool: TJSONArray;
  JStructure, JFitness, JOptimizer, JTarget, JRange: TJSONObject;
  Content: string;
  i: Integer;
begin
  Content := TFile.ReadAllText(FileName);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    // Targets
    JTargets := JSON.GetValue<TJSONArray>('targets');
    SetLength(Result.Targets, JTargets.Count);
    for i := 0 to JTargets.Count - 1 do
    begin
      JTarget := JTargets.Items[i] as TJSONObject;
      Result.Targets[i].Name := JTarget.GetValue<string>('element');
      Result.Targets[i].Lambda := JTarget.GetValue<Double>('lambda');
      Result.Targets[i].Weight := JTarget.GetValue<Double>('weight');
    end;

    // Element pool
    JPool := JSON.GetValue<TJSONArray>('element_pool');
    SetLength(Result.ElementPool, JPool.Count);
    for i := 0 to JPool.Count - 1 do
      Result.ElementPool[i] := JPool.Items[i].Value;

    // Structure
    JStructure := JSON.GetValue<TJSONObject>('structure');
    Result.Structure.StructureType := JStructure.GetValue<string>('type');
    Result.Structure.LayersPerPeriod := JStructure.GetValue<Integer>('layers_per_period');

    JRange := JStructure.GetValue<TJSONObject>('d');
    Result.Structure.dRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.dRange.Max := JRange.GetValue<Double>('max');

    JRange := JStructure.GetValue<TJSONObject>('gamma');
    Result.Structure.GammaRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.GammaRange.Max := JRange.GetValue<Double>('max');

    JRange := JStructure.GetValue<TJSONObject>('N');
    Result.Structure.NRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.NRange.Max := JRange.GetValue<Double>('max');

    JRange := JStructure.GetValue<TJSONObject>('sigma');
    Result.Structure.SigmaRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.SigmaRange.Max := JRange.GetValue<Double>('max');

    JRange := JStructure.GetValue<TJSONObject>('density_factor');
    Result.Structure.DensityFactorRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.DensityFactorRange.Max := JRange.GetValue<Double>('max');

    // Fitness
    JFitness := JSON.GetValue<TJSONObject>('fitness');
    Result.Fitness.wR := JFitness.GetValue<Double>('w_R');
    Result.Fitness.wFWHM := JFitness.GetValue<Double>('w_FWHM');
    Result.Fitness.RMinThreshold := JFitness.GetValue<Double>('R_min_threshold');

    // Optimizer
    JOptimizer := JSON.GetValue<TJSONObject>('optimizer');
    Result.Optimizer.Population := JOptimizer.GetValue<Integer>('population');
    Result.Optimizer.Iterations := JOptimizer.GetValue<Integer>('iterations');
    Result.Optimizer.Tolerance := JOptimizer.GetValue<Double>('tolerance');
    Result.Optimizer.StagnationLimit := JOptimizer.GetValue<Integer>('stagnation_limit');
    Result.Optimizer.w1 := JOptimizer.GetValue<Double>('w1');
    Result.Optimizer.w2 := JOptimizer.GetValue<Double>('w2');
    Result.Optimizer.JammingMax := JOptimizer.GetValue<Integer>('jamming_max');
    Result.Optimizer.CheckpointEvery := JOptimizer.GetValue<Integer>('checkpoint_every');

    // Top-level fields
    Result.Substrate := JSON.GetValue<string>('substrate');

    if JSON.GetValue('henke_path') is TJSONNull then
      Result.HenkePath := ExtractFilePath(ParamStr(0)) + 'Henke'
    else
      Result.HenkePath := JSON.GetValue<string>('henke_path');

    Result.OutputDir := JSON.GetValue<string>('output_dir');

    if JSON.GetValue('resume_from') is TJSONNull then
      Result.ResumeFrom := ''
    else
      Result.ResumeFrom := JSON.GetValue<string>('resume_from');
  finally
    JSON.Free;
  end;
end;

procedure TUniversalIO.OpenLog(const OutputDir: string);
begin
  FOutputDir := OutputDir;
  EnsureOutputDir;
  AssignFile(FLogFile, TPath.Combine(OutputDir, 'progress.log'));
  Rewrite(FLogFile);
  FLogOpen := True;
end;

procedure TUniversalIO.LogIteration(Iteration: Integer; FoM: Single;
  const TargetResults: array of TTargetResult;
  const TargetNames: array of string;
  Diversity: Single);
var
  i: Integer;
  Line: string;
begin
  Line := Format('%5d  %8.4f', [Iteration, FoM]);
  for i := 0 to High(TargetResults) do
    Line := Line + Format('  %5.3f', [TargetResults[i].RPeak]);
  Line := Line + Format('  %5.3f', [Diversity]);

  WriteLn(Line);
  if FLogOpen then
  begin
    WriteLn(FLogFile, Line);
    Flush(FLogFile);
  end;
end;

procedure TUniversalIO.CloseLog;
begin
  if FLogOpen then
  begin
    CloseFile(FLogFile);
    FLogOpen := False;
  end;
end;

procedure TUniversalIO.SaveBestStructure(const Config: TUniversalConfig;
  const Best: TGenome; FoM: Single;
  const TargetResults: array of TTargetResult;
  const OutputDir: string);
var
  JSON, JResult, JComp, JLayer, JPerElem, JElem: TJSONObject;
  JStructure, JStack, JTop, JBottom, JLayers, JSubLayers: TJSONArray;
  JLayerObj, JSubObj, JBottomObj, JBottomStack: TJSONObject;
  LayerValues: TJSONArray;
  NInt, i, j: Integer;
  LayerName: string;
  H1, H2: Single;
begin
  NInt := NRound(Best.N);
  H1 := Best.d * Best.Gamma;
  H2 := Best.d * (1 - Best.Gamma);

  JSON := TJSONObject.Create;
  try
    JSON.AddPair('name', 'Universal Mirror - Optimized');

    // Optimizer result metadata
    JResult := TJSONObject.Create;
    JResult.AddPair('FoM', TJSONNumber.Create(FoM));
    JResult.AddPair('d', TJSONNumber.Create(Best.d));
    JResult.AddPair('gamma', TJSONNumber.Create(Best.Gamma));
    JResult.AddPair('N', TJSONNumber.Create(NInt));
    JResult.AddPair('sigma', TJSONNumber.Create(Best.Sigma));

    // Composition per layer
    JComp := TJSONObject.Create;
    for i := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JLayer := TJSONObject.Create;
      for j := 0 to High(Config.ElementPool) do
        if Best.Composition[i][j] > 0.01 then
          JLayer.AddPair(Config.ElementPool[j],
            TJSONNumber.Create(RoundTo(Best.Composition[i][j], -3)));
      JComp.AddPair('layer_' + IntToStr(i + 1), JLayer);
    end;
    JResult.AddPair('composition', JComp);

    // Per-element results
    JPerElem := TJSONObject.Create;
    for i := 0 to High(Config.Targets) do
    begin
      JElem := TJSONObject.Create;
      JElem.AddPair('R_peak', TJSONNumber.Create(
        RoundTo(TargetResults[i].RPeak, -4)));
      JElem.AddPair('FWHM', TJSONNumber.Create(
        RoundTo(TargetResults[i].FWHM, -3)));
      JPerElem.AddPair(Config.Targets[i].Name, JElem);
    end;
    JResult.AddPair('per_element', JPerElem);
    JSON.AddPair('optimizer_result', JResult);

    // xrc_cmd-compatible structure section
    // Build layer name from composition (e.g., "W0.45Si0.30C0.25")
    JStructure := TJSONArray.Create;

    JTop := TJSONObject.Create;
    JLayers := TJSONArray.Create;
    for i := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      LayerName := '';
      for j := 0 to High(Config.ElementPool) do
        if Best.Composition[i][j] > 0.01 then
          LayerName := LayerName + Config.ElementPool[j] +
            FormatFloat('0.00', Best.Composition[i][j]);

      LayerValues := TJSONArray.Create;
      if i = 0 then
        LayerValues.Add(RoundTo(H1, -3))
      else
        LayerValues.Add(RoundTo(H2, -3));
      LayerValues.Add(RoundTo(Best.Sigma, -2));
      LayerValues.Add(RoundTo(Best.DensityFactor[i], -2));

      JLayerObj := TJSONObject.Create;
      JLayerObj.AddPair(LayerName, LayerValues);
      JLayers.Add(JLayerObj);
    end;
    JSubObj := TJSONObject.Create;
    JSubObj.AddPair('N', TJSONNumber.Create(NInt));
    JSubObj.AddPair('layers', JLayers);
    JTop.AddPair('top', JSubObj);
    JStructure.Add(JTop);

    // Substrate
    JBottom := TJSONObject.Create;
    JSubLayers := TJSONArray.Create;
    JBottomObj := TJSONObject.Create;
    LayerValues := TJSONArray.Create;
    LayerValues.Add(0);
    LayerValues.Add(1);
    LayerValues.Add(8.0);
    JBottomObj.AddPair(Config.Substrate, LayerValues);
    JSubLayers.Add(JBottomObj);
    JBottomStack := TJSONObject.Create;
    JBottomStack.AddPair('N', TJSONNumber.Create(1));
    JBottomStack.AddPair('layers', JSubLayers);
    JBottom.AddPair('bottom', JBottomStack);
    JStructure.Add(JBottom);

    JSON.AddPair('structure', JStructure);

    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'best_structure.json'),
      JSON.Format(2)
    );
  finally
    JSON.Free;
  end;
end;

procedure TUniversalIO.SaveCurve(const Element: string;
  const Curve: TDataArray; const OutputDir: string);
var
  CurvesDir, FileName: string;
  F: TextFile;
  i: Integer;
begin
  CurvesDir := TPath.Combine(OutputDir, 'best_curves');
  if not TDirectory.Exists(CurvesDir) then
    TDirectory.CreateDirectory(CurvesDir);

  FileName := TPath.Combine(CurvesDir, Element + '.dat');
  AssignFile(F, FileName);
  Rewrite(F);
  try
    for i := 0 to High(Curve) do
      WriteLn(F, Format('%.4f'#9'%.8e', [Curve[i].t, Curve[i].r]));
  finally
    CloseFile(F);
  end;
end;

procedure TUniversalIO.SavePopulation(const Config: TUniversalConfig;
  const Particles: array of TParticle;
  TopN: Integer; const OutputDir: string);
var
  JArray: TJSONArray;
  JParticle, JComp, JLayer, JPerElem, JElem: TJSONObject;
  i, j, k: Integer;
  Sorted: array of Integer;
  Temp: Integer;
begin
  // Sort particles by FoM (ascending = best negated FoM first)
  SetLength(Sorted, Length(Particles));
  for i := 0 to High(Sorted) do Sorted[i] := i;

  // Simple insertion sort (population is small)
  for i := 1 to High(Sorted) do
  begin
    j := i;
    while (j > 0) and (Particles[Sorted[j]].PBestFoM < Particles[Sorted[j-1]].PBestFoM) do
    begin
      Temp := Sorted[j]; Sorted[j] := Sorted[j-1]; Sorted[j-1] := Temp;
      Dec(j);
    end;
  end;

  if TopN > Length(Sorted) then TopN := Length(Sorted);

  JArray := TJSONArray.Create;
  try
    for i := 0 to TopN - 1 do
    begin
      k := Sorted[i];
      JParticle := TJSONObject.Create;
      JParticle.AddPair('FoM', TJSONNumber.Create(-Particles[k].PBestFoM));

      JComp := TJSONObject.Create;
      for j := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        JLayer := TJSONObject.Create;
        for var m := 0 to High(Config.ElementPool) do
          if Particles[k].PBest.Composition[j][m] > 0.01 then
            JLayer.AddPair(Config.ElementPool[m],
              TJSONNumber.Create(RoundTo(Particles[k].PBest.Composition[j][m], -3)));
        JComp.AddPair('layer_' + IntToStr(j + 1), JLayer);
      end;
      JParticle.AddPair('composition', JComp);

      JParticle.AddPair('d', TJSONNumber.Create(Particles[k].PBest.d));
      JParticle.AddPair('gamma', TJSONNumber.Create(Particles[k].PBest.Gamma));
      JParticle.AddPair('N', TJSONNumber.Create(NRound(Particles[k].PBest.N)));
      JParticle.AddPair('sigma', TJSONNumber.Create(Particles[k].PBest.Sigma));

      JArray.Add(JParticle);
    end;

    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'population.json'),
      JArray.Format(2)
    );
  finally
    JArray.Free;
  end;
end;

procedure TUniversalIO.SaveCheckpoint(const State: TOptState;
  const Config: TUniversalConfig; const OutputDir: string);
var
  JSON, JParticle, JGenome, JVel: TJSONObject;
  JParticles, JComp, JVComp: TJSONArray;
  i, j, k: Integer;

  function GenomeToJSON(const G: TGenome): TJSONObject;
  var
    JCompArr: TJSONArray;
    JFracs: TJSONArray;
    ii, jj: Integer;
  begin
    Result := TJSONObject.Create;
    JCompArr := TJSONArray.Create;
    for ii := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JFracs := TJSONArray.Create;
      for jj := 0 to High(G.Composition[ii]) do
        JFracs.Add(G.Composition[ii][jj]);
      JCompArr.Add(JFracs);
    end;
    Result.AddPair('composition', JCompArr);
    Result.AddPair('d', TJSONNumber.Create(G.d));
    Result.AddPair('gamma', TJSONNumber.Create(G.Gamma));
    Result.AddPair('N', TJSONNumber.Create(G.N));
    Result.AddPair('sigma', TJSONNumber.Create(G.Sigma));
    Result.AddPair('df0', TJSONNumber.Create(G.DensityFactor[0]));
    Result.AddPair('df1', TJSONNumber.Create(G.DensityFactor[1]));
  end;

begin
  EnsureOutputDir;
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('iteration', TJSONNumber.Create(State.Iteration));
    JSON.AddPair('gbest_fom', TJSONNumber.Create(State.GBestFoM));
    JSON.AddPair('abest_fom', TJSONNumber.Create(State.ABestFoM));
    JSON.AddPair('jamming_count', TJSONNumber.Create(State.JammingCount));
    JSON.AddPair('gbest', GenomeToJSON(State.GBest));
    JSON.AddPair('abest', GenomeToJSON(State.ABest));

    JParticles := TJSONArray.Create;
    for i := 0 to High(State.Particles) do
    begin
      JParticle := TJSONObject.Create;
      JParticle.AddPair('x', GenomeToJSON(State.Particles[i].X));
      JParticle.AddPair('pbest', GenomeToJSON(State.Particles[i].PBest));
      JParticle.AddPair('pbest_fom', TJSONNumber.Create(State.Particles[i].PBestFoM));
      // Velocity: reuse GenomeToJSON pattern (same shape as genome)
      JVel := TJSONObject.Create;
      JVComp := TJSONArray.Create;
      for j := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        var JVFracs := TJSONArray.Create;
        for k := 0 to High(State.Particles[i].V.Composition[j]) do
          JVFracs.Add(State.Particles[i].V.Composition[j][k]);
        JVComp.Add(JVFracs);
      end;
      JVel.AddPair('composition', JVComp);
      JVel.AddPair('d', TJSONNumber.Create(State.Particles[i].V.d));
      JVel.AddPair('gamma', TJSONNumber.Create(State.Particles[i].V.Gamma));
      JVel.AddPair('N', TJSONNumber.Create(State.Particles[i].V.N));
      JVel.AddPair('sigma', TJSONNumber.Create(State.Particles[i].V.Sigma));
      JVel.AddPair('df0', TJSONNumber.Create(State.Particles[i].V.DensityFactor[0]));
      JVel.AddPair('df1', TJSONNumber.Create(State.Particles[i].V.DensityFactor[1]));
      JParticle.AddPair('v', JVel);
      JParticles.Add(JParticle);
    end;
    JSON.AddPair('particles', JParticles);

    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'checkpoint.json'),
      JSON.Format(2)
    );
  finally
    JSON.Free;
  end;
end;

function TUniversalIO.LoadCheckpoint(const FileName: string;
  const Config: TUniversalConfig): TOptState;
var
  JSON, JParticle, JGenome: TJSONObject;
  JParticles, JComp, JFracs: TJSONArray;
  Content: string;
  i, j, k, PoolSize: Integer;

  function JSONToGenome(JG: TJSONObject): TGenome;
  var
    JCompArr, JFracArr: TJSONArray;
    ii, jj: Integer;
  begin
    Result := CreateGenome(Length(Config.ElementPool));
    JCompArr := JG.GetValue<TJSONArray>('composition');
    for ii := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JFracArr := JCompArr.Items[ii] as TJSONArray;
      for jj := 0 to JFracArr.Count - 1 do
        Result.Composition[ii][jj] := JFracArr.Items[jj].GetValue<Double>;
    end;
    Result.d := JG.GetValue<Double>('d');
    Result.Gamma := JG.GetValue<Double>('gamma');
    Result.N := JG.GetValue<Double>('N');
    Result.Sigma := JG.GetValue<Double>('sigma');
    Result.DensityFactor[0] := JG.GetValue<Double>('df0');
    Result.DensityFactor[1] := JG.GetValue<Double>('df1');
  end;

begin
  Content := TFile.ReadAllText(FileName);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    Result.Iteration := JSON.GetValue<Integer>('iteration');
    Result.GBestFoM := JSON.GetValue<Double>('gbest_fom');
    Result.ABestFoM := JSON.GetValue<Double>('abest_fom');
    Result.JammingCount := JSON.GetValue<Integer>('jamming_count');
    Result.GBest := JSONToGenome(JSON.GetValue<TJSONObject>('gbest'));
    Result.ABest := JSONToGenome(JSON.GetValue<TJSONObject>('abest'));

    JParticles := JSON.GetValue<TJSONArray>('particles');
    SetLength(Result.Particles, JParticles.Count);
    for i := 0 to JParticles.Count - 1 do
    begin
      JParticle := JParticles.Items[i] as TJSONObject;
      Result.Particles[i].X := JSONToGenome(JParticle.GetValue<TJSONObject>('x'));
      Result.Particles[i].PBest := JSONToGenome(JParticle.GetValue<TJSONObject>('pbest'));
      Result.Particles[i].PBestFoM := JParticle.GetValue<Double>('pbest_fom');
      // Restore velocity
      var JVel := JParticle.GetValue<TJSONObject>('v');
      Result.Particles[i].V := CreateVelocity(Length(Config.ElementPool));
      var JVComp := JVel.GetValue<TJSONArray>('composition');
      for j := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        var JVFracs := JVComp.Items[j] as TJSONArray;
        for k := 0 to JVFracs.Count - 1 do
          Result.Particles[i].V.Composition[j][k] := JVFracs.Items[k].GetValue<Double>;
      end;
      Result.Particles[i].V.d := JVel.GetValue<Double>('d');
      Result.Particles[i].V.Gamma := JVel.GetValue<Double>('gamma');
      Result.Particles[i].V.N := JVel.GetValue<Double>('N');
      Result.Particles[i].V.Sigma := JVel.GetValue<Double>('sigma');
      Result.Particles[i].V.DensityFactor[0] := JVel.GetValue<Double>('df0');
      Result.Particles[i].V.DensityFactor[1] := JVel.GetValue<Double>('df1');
    end;
  finally
    JSON.Free;
  end;
end;

end.
```

- [ ] **Step 2: Build to verify syntax**

- [ ] **Step 3: Commit**

```
git add XRC_CMD/units/cmd_unit_universal_io.pas
git commit -m "+ Add Universal Mirror config loading and output I/O"
```

---

## Chunk 3: Fitness Evaluation

### Task 5: Multi-Wavelength Fitness Evaluation

**Files:**
- Create: `XRC_CMD/units/cmd_unit_universal_fitness.pas`

**Context:**
- `TLayer` record in `cmd_unit_types.pas` (line 47): has fields `Name: string; e: TComplex; H, S, Rho: single; K, RF, r: TComplex`
- `TLayers = array of TLayer` (line 55)
- `TCalc` in `cmd_unit_calc.pas`: `RefCalc(t, Lambda: single; ALayers: TLayers): single` (line 51)
- `TCalc.CalcData: TCalcParams` — set scan parameters before calling `Run`
- `TCalcParams` (line 32): `N, K, P, RF, Mode, StartT, EndT, DT, Lambda`
- Layer 0 = vacuum (e = 1+0i, H = 0), last layer = substrate (H = 1e8)

- [ ] **Step 1: Create the fitness evaluation unit**

```pascal
unit cmd_unit_universal_fitness;

interface

uses
  System.SysUtils, System.Math, math_complex,
  cmd_unit_types, cmd_unit_universal_types, unit_materials_mix;

type
  TUniversalFitness = class
  private
    FMixer: TMaterialMixer;
    FConfig: TUniversalConfig;
    FTargetCount: Integer;
    FPoolSize: Integer;

    function BuildLayers(const Genome: TGenome; TargetIdx: Integer): TLayers;
    function ScanReflectivity(const Layers: TLayers;
      Lambda, ThetaCenter, ThetaHalfRange: Single;
      NPoints: Integer): TDataArray;
    function ExtractRPeak(const Curve: TDataArray): Single;
    function ExtractFWHM(const Curve: TDataArray; RPeak: Single): Single;
  public
    constructor Create(AMixer: TMaterialMixer; const AConfig: TUniversalConfig);

    // Evaluate one particle across all target wavelengths
    function Evaluate(const Genome: TGenome;
      var Results: TTargetResults): Single; // returns negated FoM

    // Get reflectivity curve for a specific target (for output)
    function GetCurve(const Genome: TGenome; TargetIdx: Integer): TDataArray;
  end;

implementation

uses
  cmd_unit_calc;

const
  SCAN_POINTS = 200;
  SCAN_HALF_RANGE = 5.0; // degrees each side of Bragg angle
  PENALTY_DARK = 100.0;  // penalty for R < threshold
  PENALTY_DEGENERATE = 1.0;

constructor TUniversalFitness.Create(AMixer: TMaterialMixer;
  const AConfig: TUniversalConfig);
begin
  inherited Create;
  FMixer := AMixer;
  FConfig := AConfig;
  FTargetCount := Length(AConfig.Targets);
  FPoolSize := Length(AConfig.ElementPool);
end;

function TUniversalFitness.BuildLayers(const Genome: TGenome;
  TargetIdx: Integer): TLayers;
var
  NInt, TotalLayers, LayerIdx, Period, Role: Integer;
  H1, H2: Single;
  Eps: TComplex;
  Dens: Single;
begin
  NInt := NRound(Genome.N);
  TotalLayers := 2 + NInt * LAYERS_PER_PERIOD; // vacuum + bilayers + substrate
  SetLength(Result, TotalLayers);

  // Layer 0: vacuum
  Result[0].e.re := 1.0;
  Result[0].e.im := 0.0;
  Result[0].H := 0;
  Result[0].S := 0;

  // Bilayer thicknesses
  H1 := Genome.d * Genome.Gamma;         // reflector
  H2 := Genome.d * (1 - Genome.Gamma);   // spacer

  // Periodic layers
  LayerIdx := 1;
  for Period := 0 to NInt - 1 do
  begin
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      FMixer.CalcMixedEpsilon(
        Genome.Composition[Role],
        Genome.DensityFactor[Role],
        TargetIdx,
        Eps, Dens
      );
      Result[LayerIdx].e := Eps;
      if Role = 0 then
        Result[LayerIdx].H := H1
      else
        Result[LayerIdx].H := H2;
      Result[LayerIdx].S := Genome.Sigma;
      Result[LayerIdx].Rho := Dens;
      Inc(LayerIdx);
    end;
  end;

  // Substrate (last layer)
  FMixer.CalcSubstrateEpsilon(TargetIdx, Eps);
  Result[LayerIdx].e := Eps;
  Result[LayerIdx].H := 1e8;
  Result[LayerIdx].S := Genome.Sigma;
end;

function TUniversalFitness.ScanReflectivity(const Layers: TLayers;
  Lambda, ThetaCenter, ThetaHalfRange: Single;
  NPoints: Integer): TDataArray;
var
  Calc: TCalc;
  Params: TCalcParams;
  StartT, EndT, Step: Single;
  i: Integer;
begin
  StartT := Max(0.1, ThetaCenter - ThetaHalfRange);
  EndT := ThetaCenter + ThetaHalfRange;
  Step := (EndT - StartT) / NPoints;

  SetLength(Result, NPoints);

  Calc := TCalc.Create;
  try
    // Set CalcData so RefCalc can read polarization and roughness settings
    Params.P := cmSP;       // S+P averaged
    Params.RF := rfError;   // error function roughness
    Params.Lambda := Lambda;
    Params.K := 1;          // theta mode
    Calc.CalcData := Params;

    for i := 0 to NPoints - 1 do
    begin
      Result[i].t := StartT + i * Step;
      Result[i].r := Calc.RefCalc(Result[i].t, Lambda, Layers);
    end;
  finally
    Calc.Free;
  end;
end;

function TUniversalFitness.ExtractRPeak(const Curve: TDataArray): Single;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(Curve) do
    if Curve[i].r > Result then
      Result := Curve[i].r;
end;

function TUniversalFitness.ExtractFWHM(const Curve: TDataArray;
  RPeak: Single): Single;
var
  HalfMax: Single;
  PeakIdx, i: Integer;
  ThetaLeft, ThetaRight, Frac: Single;
begin
  Result := 0;
  if RPeak <= 0 then Exit;

  HalfMax := RPeak / 2;

  // Find peak index
  PeakIdx := 0;
  for i := 1 to High(Curve) do
    if Curve[i].r > Curve[PeakIdx].r then
      PeakIdx := i;

  // Walk left from peak to find half-max crossing
  ThetaLeft := Curve[0].t; // default to scan start
  for i := PeakIdx downto 1 do
    if Curve[i-1].r <= HalfMax then
    begin
      // Linear interpolation
      Frac := (HalfMax - Curve[i-1].r) / (Curve[i].r - Curve[i-1].r);
      ThetaLeft := Curve[i-1].t + Frac * (Curve[i].t - Curve[i-1].t);
      Break;
    end;

  // Walk right from peak to find half-max crossing
  ThetaRight := Curve[High(Curve)].t; // default to scan end
  for i := PeakIdx to High(Curve) - 1 do
    if Curve[i+1].r <= HalfMax then
    begin
      Frac := (HalfMax - Curve[i+1].r) / (Curve[i].r - Curve[i+1].r);
      ThetaRight := Curve[i+1].t + Frac * (Curve[i].t - Curve[i+1].t);
      Break;
    end;

  Result := ThetaRight - ThetaLeft;
end;

function TUniversalFitness.Evaluate(const Genome: TGenome;
  var Results: TTargetResults): Single;
var
  i: Integer;
  Layers: TLayers;
  Curve: TDataArray;
  ThetaBragg, SinArg: Single;
  FoM, FWHMRef: Single;
  NInt: Integer;
  Penalty: Single;
begin
  FoM := 0;
  Penalty := 0;
  NInt := NRound(Genome.N);

  for i := 0 to FTargetCount - 1 do
  begin
    Results[i].Valid := False;
    Results[i].RPeak := 0;
    Results[i].FWHM := 0;
    Results[i].ThetaBragg := 0;

    // Check Bragg condition
    SinArg := FConfig.Targets[i].Lambda / (2 * Genome.d);
    if SinArg >= 1.0 then
      Continue; // no Bragg peak possible

    ThetaBragg := RadToDeg(ArcSin(SinArg));
    Results[i].ThetaBragg := ThetaBragg;
    Results[i].Valid := True;

    // Build layer array and evaluate
    Layers := BuildLayers(Genome, i);
    Curve := ScanReflectivity(Layers, FConfig.Targets[i].Lambda,
      ThetaBragg, SCAN_HALF_RANGE, SCAN_POINTS);

    Results[i].RPeak := ExtractRPeak(Curve);
    Results[i].FWHM := ExtractFWHM(Curve, Results[i].RPeak);

    // Compute FoM contribution for this target
    // FWHM_ref = lambda / (N * d * cos(theta_B)) in radians, convert to degrees
    FWHMRef := RadToDeg(
      FConfig.Targets[i].Lambda / (NInt * Genome.d * Cos(DegToRad(ThetaBragg)))
    );
    if FWHMRef < 1e-10 then FWHMRef := 1e-10; // avoid division by zero

    FoM := FoM + FConfig.Targets[i].Weight * (
      FConfig.Fitness.wR * Results[i].RPeak -
      FConfig.Fitness.wFWHM * Results[i].FWHM / FWHMRef
    );

    // Penalty for dark elements
    if Results[i].RPeak < FConfig.Fitness.RMinThreshold then
      Penalty := Penalty + PENALTY_DARK;
  end;

  // Return negated FoM (PSO minimizes, we want to maximize FoM)
  Result := -(FoM - Penalty);
end;

function TUniversalFitness.GetCurve(const Genome: TGenome;
  TargetIdx: Integer): TDataArray;
var
  Layers: TLayers;
  ThetaBragg, SinArg: Single;
begin
  SinArg := FConfig.Targets[TargetIdx].Lambda / (2 * Genome.d);
  if SinArg >= 1.0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  ThetaBragg := RadToDeg(ArcSin(SinArg));
  Layers := BuildLayers(Genome, TargetIdx);
  Result := ScanReflectivity(Layers, FConfig.Targets[TargetIdx].Lambda,
    ThetaBragg, SCAN_HALF_RANGE, SCAN_POINTS);
end;

end.
```

**Important note:** The `RefCalc` method in `cmd_unit_calc.pas` is private. The implementation will need one of:
(a) Move `RefCalc` to public in `cmd_unit_calc.pas`, or
(b) Implement a standalone `RefCalc` function in the fitness unit (copy the algorithm — ~100 lines), or
(c) Use `TCalc.Run` with proper `TCalcParams` setup instead of calling `RefCalc` directly.

Option (c) is cleanest — use `TCalc.Run` which calls `RunThetaThreads` internally and populates `Results`. Rewrite `ScanReflectivity` to:
1. Create TCalc, set CalcData params, assign a dummy TLayeredModel (or modify TCalc to accept TLayers directly)
2. Call `Run`, read `Results`

Option (a) is simplest — just change `RefCalc` from private to public in `cmd_unit_calc.pas`. This is a one-word change.

**Recommend option (a):** Change line 51 of `cmd_unit_calc.pas` from the `private` section to `public`.

- [ ] **Step 2: Make RefCalc public in cmd_unit_calc.pas**

In `XRC_CMD/units/cmd_unit_calc.pas`, move `RefCalc` declaration from the private section to public. The function signature remains:
```pascal
function RefCalc(t, Lambda: single; ALayers: TLayers): single;
```

- [ ] **Step 3: Build to verify syntax**

- [ ] **Step 4: Commit**

```
git add XRC_CMD/units/cmd_unit_universal_fitness.pas XRC_CMD/units/cmd_unit_calc.pas
git commit -m "+ Add multi-wavelength fitness evaluation engine"
```

---

## Chunk 4: PSO Engine

### Task 6: LFPSO Engine with Composition Normalization

**Files:**
- Create: `XRC_CMD/units/cmd_unit_universal_pso.pas`

**Context:**
- Existing LFPSO in `unit_LFPSO_Base.pas` uses: Levy flight with beta=1.5, adaptive scale 0.01→0.1, 30% random-peer targets, reflective boundaries with 0.5x damped velocity, diversity-aware shake
- PSO formula: `V = omega*V + c1*r1*(pbest-X) + c2*r2*(gbest-X)`
- Levy walk: `S = scale * z * (X - target)`, `dX = X * S * rand`
- Key addition: composition fraction normalization after every update

- [ ] **Step 1: Create the PSO engine unit**

```pascal
unit cmd_unit_universal_pso;

interface

uses
  System.SysUtils, System.Math, cmd_unit_universal_types;

type
  TUniversalPSO = class
  private
    FConfig: TUniversalConfig;
    FPoolSize: Integer;
    FParticles: array of TParticle;
    FGBest: TGenome;
    FGBestFoM: Single;
    FABest: TGenome;
    FABestFoM: Single;
    FJammingCount: Integer;
    FDiversity: Single;
    FMeanVelocity: Single;
    FLevySigmaU: Single;
    FLevyScale: Single;

    // Structural param ranges (cached for fast access)
    FdMin, FdMax, FdRange: Single;
    FGammaMin, FGammaMax, FGammaRange: Single;
    FNMin, FNMax, FNRange: Single;
    FSigmaMin, FSigmaMax, FSigmaRange: Single;
    FDFMin, FDFMax, FDFRange: Single;

    procedure InitRanges;
    procedure NormalizeComposition(var Comp: TCompositionGenes);
    procedure ReflectBound(var Value, Velocity: Single; AMin, AMax: Single);
    procedure EnforceConstraints(var P: TParticle);
    function LevyStep: Single;
    procedure CalcDiversity;

  public
    constructor Create(const AConfig: TUniversalConfig);

    procedure InitializePopulation;
    procedure UpdatePSO(Iteration, MaxIter: Integer);
    procedure UpdateLFPSO(Iteration, MaxIter: Integer);
    procedure Shake;

    // After fitness evaluation, call this to update bests
    procedure UpdateBests;

    // Access particles for fitness evaluation
    function GetParticle(Index: Integer): PParticle;
    function ParticleCount: Integer;

    property GBest: TGenome read FGBest;
    property GBestFoM: Single read FGBestFoM;
    property ABest: TGenome read FABest;
    property ABestFoM: Single read FABestFoM;
    property JammingCount: Integer read FJammingCount;
    property Diversity: Single read FDiversity;
    property MeanVelocity: Single read FMeanVelocity;

    // For checkpoint/resume
    function GetState: TOptState;
    procedure SetState(const State: TOptState);
  end;

implementation

const
  C1 = 2.05;
  C2 = 2.05;
  LEVY_BETA = 1.5;

constructor TUniversalPSO.Create(const AConfig: TUniversalConfig);
begin
  inherited Create;
  FConfig := AConfig;
  FPoolSize := Length(AConfig.ElementPool);
  FGBestFoM := MaxSingle;
  FABestFoM := MaxSingle;
  FJammingCount := 0;
  InitRanges;

  // Precomputed Levy sigma_u for Mantegna's algorithm with beta=1.5
  // Formula: (Gamma(1+b)*sin(pi*b/2) / (Gamma((1+b)/2)*b*2^((b-1)/2)))^(1/b)
  // = (1.3293*0.7071 / (0.8862*1.5*0.8409))^(1/1.5) = 0.6966
  FLevySigmaU := 0.6966;
end;

procedure TUniversalPSO.InitRanges;
begin
  FdMin := FConfig.Structure.dRange.Min;
  FdMax := FConfig.Structure.dRange.Max;
  FdRange := FdMax - FdMin;

  FGammaMin := FConfig.Structure.GammaRange.Min;
  FGammaMax := FConfig.Structure.GammaRange.Max;
  FGammaRange := FGammaMax - FGammaMin;

  FNMin := FConfig.Structure.NRange.Min;
  FNMax := FConfig.Structure.NRange.Max;
  FNRange := FNMax - FNMin;

  FSigmaMin := FConfig.Structure.SigmaRange.Min;
  FSigmaMax := FConfig.Structure.SigmaRange.Max;
  FSigmaRange := FSigmaMax - FSigmaMin;

  FDFMin := FConfig.Structure.DensityFactorRange.Min;
  FDFMax := FConfig.Structure.DensityFactorRange.Max;
  FDFRange := FDFMax - FDFMin;
end;

procedure TUniversalPSO.NormalizeComposition(var Comp: TCompositionGenes);
var
  i: Integer;
  Sum: Single;
begin
  // Clamp to [0, 1]
  Sum := 0;
  for i := 0 to High(Comp) do
  begin
    if Comp[i] < 0 then Comp[i] := 0;
    if Comp[i] > 1 then Comp[i] := 1;
    Sum := Sum + Comp[i];
  end;

  // Degenerate case
  if Sum < 1e-10 then
  begin
    for i := 0 to High(Comp) do
      Comp[i] := 1.0 / Length(Comp);
    Exit;
  end;

  // Normalize
  for i := 0 to High(Comp) do
    Comp[i] := Comp[i] / Sum;
end;

procedure TUniversalPSO.ReflectBound(var Value, Velocity: Single;
  AMin, AMax: Single);
begin
  if Value < AMin then
  begin
    Value := AMin + (AMin - Value);
    if Value > AMax then Value := AMin; // double reflection -> clamp
    Velocity := -0.5 * Velocity;
  end
  else if Value > AMax then
  begin
    Value := AMax - (Value - AMax);
    if Value < AMin then Value := AMax;
    Velocity := -0.5 * Velocity;
  end;
end;

procedure TUniversalPSO.EnforceConstraints(var P: TParticle);
var
  Role: Integer;
  DummyVel: Single;
begin
  // Structural parameter boundaries
  ReflectBound(P.X.d, P.V.d, FdMin, FdMax);
  ReflectBound(P.X.Gamma, P.V.Gamma, FGammaMin, FGammaMax);
  ReflectBound(P.X.N, P.V.N, FNMin, FNMax);
  ReflectBound(P.X.Sigma, P.V.Sigma, FSigmaMin, FSigmaMax);

  for Role := 0 to LAYERS_PER_PERIOD - 1 do
  begin
    ReflectBound(P.X.DensityFactor[Role], P.V.DensityFactor[Role],
      FDFMin, FDFMax);
    // Normalize composition fractions
    NormalizeComposition(P.X.Composition[Role]);
  end;
end;

function TUniversalPSO.LevyStep: Single;
var
  u, v, S: Single;
begin
  u := RandG(0, FLevySigmaU);
  v := RandG(0, 1);
  if Abs(v) < 1e-10 then v := 1e-10;
  S := u / Power(Abs(v), 1 / LEVY_BETA);
  Result := FLevyScale * S;
end;

procedure TUniversalPSO.InitializePopulation;
var
  i, j, Role: Integer;
begin
  SetLength(FParticles, FConfig.Optimizer.Population);

  for i := 0 to High(FParticles) do
  begin
    FParticles[i].X := CreateGenome(FPoolSize);
    FParticles[i].V := CreateVelocity(FPoolSize);
    FParticles[i].PBest := CreateGenome(FPoolSize);
    FParticles[i].PBestFoM := MaxSingle;
    FParticles[i].CurrentFoM := MaxSingle;
    SetLength(FParticles[i].TargetResults, Length(FConfig.Targets));

    // Random structural parameters
    FParticles[i].X.d := FdMin + Random * FdRange;
    FParticles[i].X.Gamma := FGammaMin + Random * FGammaRange;
    FParticles[i].X.N := FNMin + Random * FNRange;
    FParticles[i].X.Sigma := FSigmaMin + Random * FSigmaRange;

    // Random composition fractions + normalize
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      for j := 0 to FPoolSize - 1 do
        FParticles[i].X.Composition[Role][j] := Random;
      NormalizeComposition(FParticles[i].X.Composition[Role]);

      FParticles[i].X.DensityFactor[Role] := FDFMin + Random * FDFRange;
    end;

    // Initial velocities (10% of range)
    FParticles[i].V.d := (Random - 0.5) * FdRange * 0.2;
    FParticles[i].V.Gamma := (Random - 0.5) * FGammaRange * 0.2;
    FParticles[i].V.N := (Random - 0.5) * FNRange * 0.2;
    FParticles[i].V.Sigma := (Random - 0.5) * FSigmaRange * 0.2;
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      for j := 0 to FPoolSize - 1 do
        FParticles[i].V.Composition[Role][j] := (Random - 0.5) * 0.2;
      FParticles[i].V.DensityFactor[Role] := (Random - 0.5) * FDFRange * 0.2;
    end;
  end;
end;

procedure TUniversalPSO.UpdatePSO(Iteration, MaxIter: Integer);
var
  i, j, Role: Integer;
  Omega, r1, r2: Single;
begin
  // Linearly decreasing inertia weight
  Omega := FConfig.Optimizer.w1 +
    FConfig.Optimizer.w2 * (1 - Iteration / MaxIter);

  for i := 0 to High(FParticles) do
  begin
    r1 := Random;
    r2 := Random;

    // Structural genes
    FParticles[i].V.d := Omega * FParticles[i].V.d
      + C1 * r1 * (FParticles[i].PBest.d - FParticles[i].X.d)
      + C2 * r2 * (FGBest.d - FParticles[i].X.d);
    FParticles[i].X.d := FParticles[i].X.d + FParticles[i].V.d;

    r1 := Random; r2 := Random;
    FParticles[i].V.Gamma := Omega * FParticles[i].V.Gamma
      + C1 * r1 * (FParticles[i].PBest.Gamma - FParticles[i].X.Gamma)
      + C2 * r2 * (FGBest.Gamma - FParticles[i].X.Gamma);
    FParticles[i].X.Gamma := FParticles[i].X.Gamma + FParticles[i].V.Gamma;

    r1 := Random; r2 := Random;
    FParticles[i].V.N := Omega * FParticles[i].V.N
      + C1 * r1 * (FParticles[i].PBest.N - FParticles[i].X.N)
      + C2 * r2 * (FGBest.N - FParticles[i].X.N);
    FParticles[i].X.N := FParticles[i].X.N + FParticles[i].V.N;

    r1 := Random; r2 := Random;
    FParticles[i].V.Sigma := Omega * FParticles[i].V.Sigma
      + C1 * r1 * (FParticles[i].PBest.Sigma - FParticles[i].X.Sigma)
      + C2 * r2 * (FGBest.Sigma - FParticles[i].X.Sigma);
    FParticles[i].X.Sigma := FParticles[i].X.Sigma + FParticles[i].V.Sigma;

    // Composition and density factor genes
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      for j := 0 to FPoolSize - 1 do
      begin
        r1 := Random; r2 := Random;
        FParticles[i].V.Composition[Role][j] :=
          Omega * FParticles[i].V.Composition[Role][j]
          + C1 * r1 * (FParticles[i].PBest.Composition[Role][j] -
                        FParticles[i].X.Composition[Role][j])
          + C2 * r2 * (FGBest.Composition[Role][j] -
                        FParticles[i].X.Composition[Role][j]);
        FParticles[i].X.Composition[Role][j] :=
          FParticles[i].X.Composition[Role][j] +
          FParticles[i].V.Composition[Role][j];
      end;

      r1 := Random; r2 := Random;
      FParticles[i].V.DensityFactor[Role] :=
        Omega * FParticles[i].V.DensityFactor[Role]
        + C1 * r1 * (FParticles[i].PBest.DensityFactor[Role] -
                      FParticles[i].X.DensityFactor[Role])
        + C2 * r2 * (FGBest.DensityFactor[Role] -
                      FParticles[i].X.DensityFactor[Role]);
      FParticles[i].X.DensityFactor[Role] :=
        FParticles[i].X.DensityFactor[Role] +
        FParticles[i].V.DensityFactor[Role];
    end;

    EnforceConstraints(FParticles[i]);
  end;
end;

procedure TUniversalPSO.UpdateLFPSO(Iteration, MaxIter: Integer);
var
  i, j, Role, RandIdx: Integer;
  Omega, r1, r2, Step: Single;
  Target: TGenome;
begin
  Omega := FConfig.Optimizer.w1 +
    FConfig.Optimizer.w2 * (1 - Iteration / MaxIter);
  FLevyScale := 0.01 + 0.09 * (1 - Iteration / MaxIter);

  for i := 0 to High(FParticles) do
  begin
    // 30% chance: random peer as Levy target
    if Random < 0.3 then
    begin
      RandIdx := Random(Length(FParticles));
      Target := FParticles[RandIdx].X;
    end
    else
      Target := FGBest;

    // Structural genes with Levy flights
    Step := LevyStep;
    r1 := Random; r2 := Random;
    FParticles[i].V.d := Omega * Step * (FParticles[i].X.d - Target.d)
      + C1 * r1 * (FParticles[i].PBest.d - FParticles[i].X.d)
      + C2 * r2 * (FGBest.d - FParticles[i].X.d);
    FParticles[i].X.d := FParticles[i].X.d + FParticles[i].V.d;

    Step := LevyStep;
    r1 := Random; r2 := Random;
    FParticles[i].V.Gamma := Omega * Step * (FParticles[i].X.Gamma - Target.Gamma)
      + C1 * r1 * (FParticles[i].PBest.Gamma - FParticles[i].X.Gamma)
      + C2 * r2 * (FGBest.Gamma - FParticles[i].X.Gamma);
    FParticles[i].X.Gamma := FParticles[i].X.Gamma + FParticles[i].V.Gamma;

    Step := LevyStep;
    r1 := Random; r2 := Random;
    FParticles[i].V.N := Omega * Step * (FParticles[i].X.N - Target.N)
      + C1 * r1 * (FParticles[i].PBest.N - FParticles[i].X.N)
      + C2 * r2 * (FGBest.N - FParticles[i].X.N);
    FParticles[i].X.N := FParticles[i].X.N + FParticles[i].V.N;

    Step := LevyStep;
    r1 := Random; r2 := Random;
    FParticles[i].V.Sigma := Omega * Step * (FParticles[i].X.Sigma - Target.Sigma)
      + C1 * r1 * (FParticles[i].PBest.Sigma - FParticles[i].X.Sigma)
      + C2 * r2 * (FGBest.Sigma - FParticles[i].X.Sigma);
    FParticles[i].X.Sigma := FParticles[i].X.Sigma + FParticles[i].V.Sigma;

    // Composition genes with Levy flights
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      for j := 0 to FPoolSize - 1 do
      begin
        Step := LevyStep;
        r1 := Random; r2 := Random;
        FParticles[i].V.Composition[Role][j] :=
          Omega * Step * (FParticles[i].X.Composition[Role][j] -
                          Target.Composition[Role][j])
          + C1 * r1 * (FParticles[i].PBest.Composition[Role][j] -
                        FParticles[i].X.Composition[Role][j])
          + C2 * r2 * (FGBest.Composition[Role][j] -
                        FParticles[i].X.Composition[Role][j]);
        FParticles[i].X.Composition[Role][j] :=
          FParticles[i].X.Composition[Role][j] +
          FParticles[i].V.Composition[Role][j];
      end;

      Step := LevyStep;
      r1 := Random; r2 := Random;
      FParticles[i].V.DensityFactor[Role] :=
        Omega * Step * (FParticles[i].X.DensityFactor[Role] -
                        Target.DensityFactor[Role])
        + C1 * r1 * (FParticles[i].PBest.DensityFactor[Role] -
                      FParticles[i].X.DensityFactor[Role])
        + C2 * r2 * (FGBest.DensityFactor[Role] -
                      FParticles[i].X.DensityFactor[Role]);
      FParticles[i].X.DensityFactor[Role] :=
        FParticles[i].X.DensityFactor[Role] +
        FParticles[i].V.DensityFactor[Role];
    end;

    EnforceConstraints(FParticles[i]);
  end;
end;

procedure TUniversalPSO.UpdateBests;
var
  i: Integer;
  PrevGBest: Single;
begin
  PrevGBest := FGBestFoM;

  for i := 0 to High(FParticles) do
  begin
    // Update personal best
    if FParticles[i].CurrentFoM < FParticles[i].PBestFoM then
    begin
      FParticles[i].PBestFoM := FParticles[i].CurrentFoM;
      FParticles[i].PBest := FParticles[i].X;
    end;

    // Update global best
    if FParticles[i].CurrentFoM < FGBestFoM then
    begin
      FGBestFoM := FParticles[i].CurrentFoM;
      FGBest := FParticles[i].X;
    end;

    // Update absolute best
    if FParticles[i].CurrentFoM < FABestFoM then
    begin
      FABestFoM := FParticles[i].CurrentFoM;
      FABest := FParticles[i].X;
    end;
  end;

  // Stagnation tracking
  if FGBestFoM < PrevGBest - 1e-8 then
    FJammingCount := 0
  else
    Inc(FJammingCount);

  CalcDiversity;
end;

procedure TUniversalPSO.CalcDiversity;
var
  i: Integer;
  MeanD, Variance: Single;
begin
  if Length(FParticles) = 0 then
  begin
    FDiversity := 0;
    Exit;
  end;

  // Use d parameter as diversity proxy (normalized)
  MeanD := 0;
  for i := 0 to High(FParticles) do
    MeanD := MeanD + FParticles[i].X.d;
  MeanD := MeanD / Length(FParticles);

  Variance := 0;
  for i := 0 to High(FParticles) do
    Variance := Variance + Sqr(FParticles[i].X.d - MeanD);
  Variance := Variance / Length(FParticles);

  if FdRange > 0 then
    FDiversity := Sqrt(Variance) / FdRange
  else
    FDiversity := 0;
end;

procedure TUniversalPSO.Shake;
var
  i, j, Role: Integer;
begin
  // Re-initialize population from gbest with perturbation
  for i := 1 to High(FParticles) do // keep particle 0 as gbest
  begin
    FParticles[i].X := FGBest;

    // Add random perturbation (10% of range)
    FParticles[i].X.d := FParticles[i].X.d + (Random - 0.5) * FdRange * 0.2;
    FParticles[i].X.Gamma := FParticles[i].X.Gamma + (Random - 0.5) * FGammaRange * 0.2;
    FParticles[i].X.N := FParticles[i].X.N + (Random - 0.5) * FNRange * 0.2;
    FParticles[i].X.Sigma := FParticles[i].X.Sigma + (Random - 0.5) * FSigmaRange * 0.2;

    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      for j := 0 to FPoolSize - 1 do
        FParticles[i].X.Composition[Role][j] :=
          FParticles[i].X.Composition[Role][j] + (Random - 0.5) * 0.2;
      NormalizeComposition(FParticles[i].X.Composition[Role]);

      FParticles[i].X.DensityFactor[Role] :=
        FParticles[i].X.DensityFactor[Role] + (Random - 0.5) * FDFRange * 0.2;
    end;

    EnforceConstraints(FParticles[i]);

    // Reset velocity
    FParticles[i].V := CreateVelocity(FPoolSize);
    FParticles[i].V.d := (Random - 0.5) * FdRange * 0.1;
    FParticles[i].V.Gamma := (Random - 0.5) * FGammaRange * 0.1;
    FParticles[i].V.N := (Random - 0.5) * FNRange * 0.1;
    FParticles[i].V.Sigma := (Random - 0.5) * FSigmaRange * 0.1;
  end;

  FJammingCount := 0;
end;

function TUniversalPSO.ParticleCount: Integer;
begin
  Result := Length(FParticles);
end;

function TUniversalPSO.GetParticle(Index: Integer): PParticle;
begin
  Result := @FParticles[Index];
end;

function TUniversalPSO.GetState: TOptState;
begin
  Result.GBest := FGBest;
  Result.GBestFoM := FGBestFoM;
  Result.ABest := FABest;
  Result.ABestFoM := FABestFoM;
  Result.JammingCount := FJammingCount;
  Result.Particles := Copy(FParticles);
end;

procedure TUniversalPSO.SetState(const State: TOptState);
begin
  FGBest := State.GBest;
  FGBestFoM := State.GBestFoM;
  FABest := State.ABest;
  FABestFoM := State.ABestFoM;
  FJammingCount := State.JammingCount;
  FParticles := Copy(State.Particles);
end;

end.
```

- [ ] **Step 2: Build to verify syntax**

- [ ] **Step 3: Commit**

```
git add XRC_CMD/units/cmd_unit_universal_pso.pas
git commit -m "+ Add LFPSO engine with composition normalization"
```

---

## Chunk 5: Orchestrator and CLI Integration

### Task 7: Main Orchestrator

**Files:**
- Create: `XRC_CMD/units/cmd_unit_universal.pas`

**Context:** This unit wires everything together: loads config, initializes mixer + PSO + fitness, runs the main loop with parallel evaluation, handles Ctrl+C, writes output.

- [ ] **Step 1: Create the orchestrator unit**

```pascal
unit cmd_unit_universal;

interface

uses
  System.SysUtils;

procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);

implementation

uses
  System.Math, System.Classes, Windows,
  OtlParallel, OtlTaskControl,
  cmd_unit_types, cmd_unit_universal_types, cmd_unit_universal_io,
  cmd_unit_universal_fitness, cmd_unit_universal_pso,
  unit_materials_mix;

var
  GTerminated: Boolean = False;

function ConsoleCtrlHandler(dwCtrlType: DWORD): BOOL; stdcall;
begin
  GTerminated := True;
  WriteLn('');
  WriteLn('Interrupt received. Saving checkpoint and exiting...');
  Result := True;
end;

procedure cmdUniversalMirror(const ConfigFile: string; Verbose: Boolean);
var
  Config: TUniversalConfig;
  Mixer: TMaterialMixer;
  PSO: TUniversalPSO;
  Fitness: TUniversalFitness;
  IO: TUniversalIO;
  i, t: Integer;
  LevyProb, LevyBoost: Single;
  TargetLambdas: array of Single;
  ElementNames: array of string;
  TargetNames: array of string;
  StartIter: Integer;
  State: TOptState;
  BestResults: array of TTargetResult;
  Curve: TDataArray;
  P: PParticle;
begin
  // Register Ctrl+C handler
  SetConsoleCtrlHandler(@ConsoleCtrlHandler, True);
  try
    // Load configuration
    Config := TUniversalIO.LoadConfig(ConfigFile);

    // Print banner
    WriteLn('Universal Mirror Optimizer v1.0');
    Write('Targets:');
    for i := 0 to High(Config.Targets) do
      Write(Format(' %s(%.1fA)', [Config.Targets[i].Name, Config.Targets[i].Lambda]));
    WriteLn;
    Write('Pool:');
    for i := 0 to High(Config.ElementPool) do
      Write(' ' + Config.ElementPool[i]);
    WriteLn;
    WriteLn(Format('Structure: %s, d=[%.0f..%.0f], N=[%.0f..%.0f]',
      [Config.Structure.StructureType,
       Config.Structure.dRange.Min, Config.Structure.dRange.Max,
       Config.Structure.NRange.Min, Config.Structure.NRange.Max]));
    WriteLn(Format('Population: %d, Max iterations: %d',
      [Config.Optimizer.Population, Config.Optimizer.Iterations]));
    WriteLn('---');

    // Print header
    Write(Format('%5s  %8s', ['Iter', 'FoM']));
    for i := 0 to High(Config.Targets) do
      Write(Format('  %5s', ['R_' + Config.Targets[i].Name]));
    WriteLn(Format('  %5s', ['Div']));

    // Initialize material mixer with Henke caching
    SetLength(TargetLambdas, Length(Config.Targets));
    SetLength(TargetNames, Length(Config.Targets));
    for i := 0 to High(Config.Targets) do
    begin
      TargetLambdas[i] := Config.Targets[i].Lambda;
      TargetNames[i] := Config.Targets[i].Name;
    end;

    SetLength(ElementNames, Length(Config.ElementPool));
    for i := 0 to High(Config.ElementPool) do
      ElementNames[i] := Config.ElementPool[i];

    Mixer := TMaterialMixer.Create;
    PSO := TUniversalPSO.Create(Config);
    Fitness := TUniversalFitness.Create(Mixer, Config);
    IO := TUniversalIO.Create;
    try
      Mixer.Initialize(ElementNames, TargetLambdas,
        Config.Substrate, Config.HenkePath);

      IO.OpenLog(Config.OutputDir);

      // Initialize or resume
      if Config.ResumeFrom <> '' then
      begin
        State := IO.LoadCheckpoint(Config.ResumeFrom, Config);
        PSO.SetState(State);
        StartIter := State.Iteration + 1;
        WriteLn(Format('Resumed from iteration %d (FoM: %.6f)',
          [State.Iteration, -State.ABestFoM]));
      end
      else
      begin
        PSO.InitializePopulation;
        StartIter := 0;
      end;

      // Initial evaluation (parallel)
      SetLength(BestResults, Length(Config.Targets));
      Parallel.&For(0, PSO.ParticleCount - 1).Execute(
        procedure(Index: Integer)
        var
          LP: PParticle;
        begin
          LP := PSO.GetParticle(Index);
          LP^.CurrentFoM := Fitness.Evaluate(LP^.X, LP^.TargetResults);
        end
      );
      PSO.UpdateBests;

      // Evaluate best to populate BestResults for logging
      Fitness.Evaluate(PSO.ABest, BestResults);
      IO.LogIteration(0, -PSO.ABestFoM, BestResults, TargetNames,
        PSO.Diversity);

      // Main optimization loop
      for t := StartIter to Config.Optimizer.Iterations - 1 do
      begin
        if GTerminated then Break;

        // Adaptive Levy/PSO switching
        LevyProb := 0.3 + 0.4 * (1 - t / Config.Optimizer.Iterations);
        LevyBoost := Min(0.2, PSO.JammingCount * 0.05);
        LevyProb := Min(0.9, LevyProb + LevyBoost);

        if Random > LevyProb then
          PSO.UpdatePSO(t, Config.Optimizer.Iterations)
        else
          PSO.UpdateLFPSO(t, Config.Optimizer.Iterations);

        // Parallel fitness evaluation
        Parallel.&For(0, PSO.ParticleCount - 1).Execute(
          procedure(Index: Integer)
          var
            LP: PParticle;
          begin
            LP := PSO.GetParticle(Index);
            LP^.CurrentFoM := Fitness.Evaluate(LP^.X, LP^.TargetResults);
          end
        );

        PSO.UpdateBests;

        // Re-evaluate best to get its target results for logging
        Fitness.Evaluate(PSO.ABest, BestResults);

        // Progress reporting
        IO.LogIteration(t + 1, -PSO.ABestFoM, BestResults, TargetNames,
          PSO.Diversity);

        // Stagnation handling
        if PSO.JammingCount > Config.Optimizer.JammingMax then
        begin
          if PSO.Diversity < 0.01 then
          begin
            PSO.Shake;
            if Verbose then
              WriteLn(Format('  [Shake at iteration %d]', [t + 1]));
          end;
        end;

        // Convergence check
        if (PSO.JammingCount > Config.Optimizer.StagnationLimit) then
        begin
          WriteLn(Format('Converged at iteration %d (stagnation limit reached)', [t + 1]));
          Break;
        end;

        // Checkpoint
        if ((t + 1) mod Config.Optimizer.CheckpointEvery = 0) then
        begin
          State := PSO.GetState;
          State.Iteration := t + 1;
          IO.SaveCheckpoint(State, Config, Config.OutputDir);
          if Verbose then
            WriteLn(Format('  [Checkpoint saved at iteration %d]', [t + 1]));
        end;
      end;

      // Final output
      WriteLn('---');
      WriteLn('Optimization complete.');
      WriteLn(Format('Best FoM: %.6f', [-PSO.ABestFoM]));
      WriteLn(Format('Period d=%.2f A, gamma=%.3f, N=%d, sigma=%.2f A',
        [PSO.ABest.d, PSO.ABest.Gamma, NRound(PSO.ABest.N), PSO.ABest.Sigma]));

      // Print composition
      for i := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        Write(Format('Layer %d: ', [i + 1]));
        for var j := 0 to High(Config.ElementPool) do
          if PSO.ABest.Composition[i][j] > 0.01 then
            Write(Format('%s=%.1f%% ', [Config.ElementPool[j],
              PSO.ABest.Composition[i][j] * 100]));
        WriteLn;
      end;

      // Save results
      Fitness.Evaluate(PSO.ABest, BestResults);
      IO.SaveBestStructure(Config, PSO.ABest, -PSO.ABestFoM, BestResults,
        Config.OutputDir);

      // Save reflectivity curves per target
      for i := 0 to High(Config.Targets) do
      begin
        Curve := Fitness.GetCurve(PSO.ABest, i);
        if Length(Curve) > 0 then
          IO.SaveCurve(Config.Targets[i].Name, Curve, Config.OutputDir);
      end;

      // Save top solutions
      IO.SavePopulation(Config, PSO.GetState.Particles, 10, Config.OutputDir);

      // Final checkpoint
      State := PSO.GetState;
      State.Iteration := Config.Optimizer.Iterations;
      IO.SaveCheckpoint(State, Config, Config.OutputDir);

      IO.CloseLog;
    finally
      Mixer.Free;
      PSO.Free;
      Fitness.Free;
      IO.Free;
    end;
  finally
    SetConsoleCtrlHandler(@ConsoleCtrlHandler, False);
  end;
end;

end.
```

**Note on parallel evaluation:** The `Parallel.For` call from OTL captures a closure that accesses `PSO.GetParticle(Index)`. This returns a pointer to the particle in the internal array. Since each thread writes only to its own particle's `CurrentFoM` and `TargetResults`, there is no shared mutable state. However, each thread calls `Fitness.Evaluate` which creates its own local `TLayers` array and `TCalc` instance — no shared state there either. If `TCalc.Create` inside `ScanReflectivity` becomes a bottleneck, consider pre-creating one TCalc per thread and reusing it.

- [ ] **Step 2: Build to verify syntax**

- [ ] **Step 3: Commit**

```
git add XRC_CMD/units/cmd_unit_universal.pas
git commit -m "+ Add Universal Mirror main orchestrator with parallel evaluation"
```

---

### Task 8: CLI Integration

**Files:**
- Modify: `XRC_CMD/xrccmd.dpr`

**Context:** Current operation mode enum: `(omHelp, omSingleCalc, omFolderCalc, omFitting)`. Current switches use `FindCmdLineSwitch`. New `-u` switch dispatches to `cmdUniversalMirror`.

- [ ] **Step 1: Add -u switch and new units to xrccmd.dpr**

Add to uses clause (after existing units):
```pascal
  cmd_unit_universal in 'Units\cmd_unit_universal.pas',
  cmd_unit_universal_types in 'Units\cmd_unit_universal_types.pas',
  cmd_unit_universal_fitness in 'Units\cmd_unit_universal_fitness.pas',
  cmd_unit_universal_pso in 'Units\cmd_unit_universal_pso.pas',
  cmd_unit_universal_io in 'Units\cmd_unit_universal_io.pas',
  unit_materials_mix in '..\Math\unit_materials_mix.pas';
```

Add to operation mode enum:
```pascal
OperationMode: (omHelp, omSingleCalc, omFolderCalc, omFitting, omUniversal);
```

Add new variable:
```pascal
UniversalConfigFile: string;
```

Add switch detection (after the `-a` block, before `VerboseMode`):
```pascal
if FindCmdLineSwitch('u', Value, True, [clstValueNextParam]) then
begin
  UniversalConfigFile := Value;
  OperationMode := omUniversal;
end;
```

Add case branch:
```pascal
omUniversal  : cmdUniversalMirror(UniversalConfigFile, VerboseMode);
```

- [ ] **Step 2: Build xrccmd Win32 Release**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1
```

Expected: Build succeeds. Fix any compilation errors (missing unit references, type mismatches, etc.)

- [ ] **Step 3: Commit**

```
git add XRC_CMD/xrccmd.dpr
git commit -m "+ Wire -u switch for Universal Mirror optimizer in xrccmd"
```

---

## Chunk 6: Integration Testing

### Task 9: Create Test Configuration and Run End-to-End

**Files:**
- Create: `UniversalMirror/test_config.json` — minimal test config (2 targets, 3-element pool, 5 iterations, pop=5)

- [ ] **Step 1: Create a minimal test config**

```json
{
  "targets": [
    {"element": "C",  "lambda": 44.7, "weight": 1.0},
    {"element": "O",  "lambda": 23.6, "weight": 1.0}
  ],
  "element_pool": ["W", "Si", "C"],
  "structure": {
    "type": "bilayer",
    "layers_per_period": 2,
    "d":              {"min": 20, "max": 80},
    "gamma":          {"min": 0.2, "max": 0.8},
    "N":              {"min": 20, "max": 100},
    "sigma":          {"min": 0.5, "max": 3},
    "density_factor": {"min": 0.7, "max": 1.3}
  },
  "fitness": {
    "w_R": 1.0,
    "w_FWHM": 0.3,
    "R_min_threshold": 0.0001,
    "polarization": "sp"
  },
  "optimizer": {
    "population": 5,
    "iterations": 10,
    "tolerance": 1e-8,
    "stagnation_limit": 50,
    "w1": 0.4,
    "w2": 0.5,
    "jamming_max": 5,
    "checkpoint_every": 5
  },
  "substrate": "Si",
  "henke_path": null,
  "output_dir": "./UniversalMirror/test_results",
  "resume_from": null
}
```

- [ ] **Step 2: Run the optimizer with test config**

```
cmd.exe //c "cd /d D:\DelphiProjects\X-RayCalc\X-RayCalc3_Working && XRC_CMD\Out\CMDBin\xrccmd.exe -u UniversalMirror\test_config.json -v" 2>&1
```

Expected output:
- Banner with targets, pool, structure info
- 10 iteration lines showing FoM, R_C, R_O, Div
- "Optimization complete" with best FoM and structure
- Files created in `UniversalMirror/test_results/`:
  - `progress.log`
  - `best_structure.json`
  - `best_curves/C.dat`, `best_curves/O.dat`
  - `population.json`
  - `checkpoint.json`

- [ ] **Step 3: Verify output files exist and contain valid data**

Check that `best_structure.json` is valid JSON with the expected structure. Check that curve .dat files have reasonable angle/reflectivity values. Check that `checkpoint.json` can be used for resume.

- [ ] **Step 4: Test resume from checkpoint**

```
cmd.exe //c "cd /d D:\DelphiProjects\X-RayCalc\X-RayCalc3_Working && XRC_CMD\Out\CMDBin\xrccmd.exe -u UniversalMirror\test_resume_config.json -v" 2>&1
```

Where `test_resume_config.json` is the same as test_config.json but with:
```json
"resume_from": "./UniversalMirror/test_results/checkpoint.json"
```

Expected: "Resumed from iteration 10", then continues for more iterations.

- [ ] **Step 5: Commit test config and results verification**

```
git add UniversalMirror/test_config.json
git commit -m "+ Add integration test config for Universal Mirror optimizer"
```

---

### Task 10: Build All and Final Verification

- [ ] **Step 1: Build both platforms**

Win32:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win32 /nologo /v:minimal" 2>&1
```

Win64:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

- [ ] **Step 2: Build and run unit tests**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All existing tests + new material mixing tests pass.

- [ ] **Step 3: Run full integration test with realistic config**

Create `UniversalMirror/full_test_config.json` with all 8 Be-Mg targets, 8-element pool, pop=10, 50 iterations. Run and verify it completes without errors and produces physically reasonable results (R > 0 for at least some elements).

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "+ Universal Mirror optimizer v1.0 complete"
```
