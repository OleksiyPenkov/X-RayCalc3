# .xrfx Package Format & XRFView Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking. Invoke `delphi-development` skill before writing any Delphi code.

**Goal:** Bundle universal mirror optimization results into `.xrfx` ZIP archives and provide a standalone viewer application.

**Architecture:** New shared unit `unit_xrfx_package.pas` in `Universal/` handles packaging and loading. xrccmd calls it after optimization completes. Standalone XRFView Delphi VCL app uses Jam Shell Controls for file browsing and TChart for visualization.

**Tech Stack:** Delphi Object Pascal, System.Zip (TZipFile), System.JSON, DUnitX, Jam Shell Controls, RaizeComponents, TeeChart

**Spec:** `docs/superpowers/specs/2026-03-17-xrfx-package-format-design.md`

---

## Chunk 1: Shared Package Unit + Tests

### Task 1: Unit skeleton with types

**Files:**
- Create: `Universal/unit_xrfx_package.pas`
- Create: `Tests/TestXRFXPackage.pas`
- Modify: `Tests/XRayCalc3Tests.dpr` — add both units to uses clause

- [ ] **Step 1: Create unit_xrfx_package.pas with type declarations**

```pascal
unit unit_xrfx_package;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IOUtils,
  System.Zip, System.JSON, System.Generics.Collections,
  unit_universal_types;

const
  XRFX_MANIFEST_VERSION = 1;
  XRFX_EXT = '.xrfx';

type
  TXRFXStructureSummary = record
    StructureType: string;
    D, Gamma, Sigma: Double;
    N: Integer;
  end;

  TXRFXOptimizerInfo = record
    Population, Iterations, StagnationLimit: Integer;
  end;

  TXRFXElementResult = record
    Line: string;
    PeakR: Double;
    FWHM: Double;
  end;

  TXRFXManifest = record
    Version: Integer;
    Created: string;
    Generator: string;
    FoM: Double;
    TargetLines: TArray<string>;
    ElementPool: TArray<string>;
    Substrate: string;
    Structure: TXRFXStructureSummary;
    Optimizer: TXRFXOptimizerInfo;
    PerElement: TArray<TXRFXElementResult>;
    CurveFiles: TArray<string>;
  end;

  TXRFXLayer = record
    Material: string;
    Thickness: Double;
    Roughness: Double;
    Density: Double;
  end;

  TXRFXStructure = record
    Layers: TArray<TXRFXLayer>;
    Substrate: TXRFXLayer;
    StackN: Integer;
  end;

  TProgressEntry = record
    Iteration: Integer;
    FoM: Double;
    ElementR: TArray<Double>;
    Diversity: Double;
  end;

  // Local curve type — avoids pulling unit_universal_optimizer into the viewer
  TXRFXCurveData = record
    Element: string;
    Theta: TArray<Double>;
    Refl: TArray<Double>;
  end;

// Write side (xrccmd)
procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, ConfigFilePath, OutputPath: string);

// Read side (XRFView)
procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
function  LoadManifest(const ManifestPath: string): TXRFXManifest;
function  LoadXRCStructure(const JsonPath: string): TXRFXStructure;
function  LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
function  LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;

implementation

// Stubs — implemented in subsequent tasks

procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, ConfigFilePath, OutputPath: string);
begin
  raise ENotImplemented.Create('CreateXRFXPackage not yet implemented');
end;

procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
begin
  raise ENotImplemented.Create('ExtractXRFXPackage not yet implemented');
end;

function LoadManifest(const ManifestPath: string): TXRFXManifest;
begin
  raise ENotImplemented.Create('LoadManifest not yet implemented');
end;

function LoadXRCStructure(const JsonPath: string): TXRFXStructure;
begin
  raise ENotImplemented.Create('LoadXRCStructure not yet implemented');
end;

function LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
begin
  raise ENotImplemented.Create('LoadCurveFiles not yet implemented');
end;

function LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;
begin
  raise ENotImplemented.Create('LoadProgressLog not yet implemented');
end;

end.
```

Note: `ConfigFilePath` parameter added to `CreateXRFXPackage` beyond what the spec shows — needed to copy the original config JSON into the archive. The spec says "copy the input config JSON" but the original signature lacked the path.

- [ ] **Step 2: Create test scaffold TestXRFXPackage.pas**

```pascal
unit TestXRFXPackage;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.IOUtils,
  unit_xrfx_package, unit_universal_types;

type
  [TestFixture]
  TTestXRFXPackage = class
  private
    FTempDir: string;
    function CreateSampleResultsDir: string;
    function CreateSampleConfigFile: string;
    function CreateSampleManifestFile: string;
    function CreateSampleXRCStructureFile: string;
    function CreateSampleProgressLog: string;
    function CreateSampleXRFX: string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;
  end;

  [TestFixture]
  TTestManifestGeneration = class(TTestXRFXPackage)
  public
    [Test] procedure Test_CreateXRFXPackage_ProducesFile;
    [Test] procedure Test_CreateXRFXPackage_ContainsManifest;
    [Test] procedure Test_CreateXRFXPackage_ContainsConfig;
    [Test] procedure Test_CreateXRFXPackage_ExcludesCheckpoint;
    [Test] procedure Test_CreateXRFXPackage_ManifestHasCorrectVersion;
  end;

  [TestFixture]
  TTestManifestLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadManifest_ParsesVersion;
    [Test] procedure Test_LoadManifest_ParsesFoM;
    [Test] procedure Test_LoadManifest_ParsesTargetLines;
    [Test] procedure Test_LoadManifest_ParsesPerElement;
    [Test] procedure Test_LoadManifest_ParsesStructureSummary;
    [Test] procedure Test_LoadManifest_ParsesOptimizerInfo;
    [Test] procedure Test_LoadManifest_ParsesCurveFiles;
  end;

  [TestFixture]
  TTestExtraction = class(TTestXRFXPackage)
  public
    [Test] procedure Test_ExtractXRFXPackage_CreatesFiles;
    [Test] procedure Test_ExtractXRFXPackage_ManifestReadable;
  end;

  [TestFixture]
  TTestXRCStructureLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadXRCStructure_ParsesLayers;
    [Test] procedure Test_LoadXRCStructure_ParsesSubstrate;
    [Test] procedure Test_LoadXRCStructure_ParsesStackN;
  end;

  [TestFixture]
  TTestCurveLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadCurveFiles_ParsesElements;
    [Test] procedure Test_LoadCurveFiles_ParsesData;
    [Test] procedure Test_LoadCurveFiles_SkipsHeader;
  end;

  [TestFixture]
  TTestProgressLogLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadProgressLog_ParsesIterations;
    [Test] procedure Test_LoadProgressLog_ParsesFoM;
    [Test] procedure Test_LoadProgressLog_ParsesElementR;
  end;

implementation

{ TTestXRFXPackage }

procedure TTestXRFXPackage.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath,
    'XRC_TestXRFX_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTempDir);
end;

procedure TTestXRFXPackage.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

function TTestXRFXPackage.CreateSampleResultsDir: string;
var
  CurvesDir: string;
begin
  Result := TPath.Combine(FTempDir, 'results');
  TDirectory.CreateDirectory(Result);
  CurvesDir := TPath.Combine(Result, 'best_curves');
  TDirectory.CreateDirectory(CurvesDir);

  // best_structure.json (minimal)
  TFile.WriteAllText(TPath.Combine(Result, 'best_structure.json'),
    '{"name":"test","optimizer_result":{"FoM":0.5}}');

  // best_structure_xrc.json
  TFile.WriteAllText(TPath.Combine(Result, 'best_structure_xrc.json'),
    '{"Stacks":[{"T":"ML","N":20,"Layers":[' +
    '{"M":"W","H":15.0,"s":3.5,"r":19.3},' +
    '{"M":"Si","H":30.0,"s":3.5,"r":2.33}]}],' +
    '"Subs":{"M":"SiO2","s":1.0,"r":2.65}}');

  // population.json
  TFile.WriteAllText(TPath.Combine(Result, 'population.json'), '[]');

  // progress.log — matches actual format from unit_universal_io.pas:LogIteration
  // Columns: Iter(5) FoM(8) R_elem(5 each) Div(5) Best(18) Time(4:02)
  TFile.WriteAllText(TPath.Combine(Result, 'progress.log'),
    ' Iter       FoM  R_Na  R_Al    Div  Best               Time' + sLineBreak +
    '    0    0.0630  0.342  0.422  0.291  Mo/Si d=45.2         0:02' + sLineBreak +
    '   10    0.3013  0.361  0.435  0.179  Mo/Si d=42.8         0:05');

  // checkpoint.json (should be excluded from .xrfx)
  TFile.WriteAllText(TPath.Combine(Result, 'checkpoint.json'),
    '{"iteration":10}');

  // curve files
  TFile.WriteAllText(TPath.Combine(CurvesDir, 'Na.dat'),
    'Theta(deg)'#9'Reflectivity' + sLineBreak +
    '0.5000'#9'3.14159e-04' + sLineBreak +
    '1.0000'#9'1.23456e-03');

  TFile.WriteAllText(TPath.Combine(CurvesDir, 'Al.dat'),
    'Theta(deg)'#9'Reflectivity' + sLineBreak +
    '0.5000'#9'2.00000e-04' + sLineBreak +
    '1.0000'#9'5.00000e-03');
end;

function TTestXRFXPackage.CreateSampleConfigFile: string;
begin
  Result := TPath.Combine(FTempDir, 'test_config.json');
  TFile.WriteAllText(Result,
    '{"lines":["Na","Al"],"element_pool":["W","Si"],' +
    '"substrate":"SiO2","output_dir":"./results"}');
end;

function TTestXRFXPackage.CreateSampleManifestFile: string;
begin
  Result := TPath.Combine(FTempDir, 'manifest.json');
  TFile.WriteAllText(Result,
    '{' +
    '"version":1,' +
    '"created":"2026-03-17T14:30:00",' +
    '"generator":"xrccmd 3.0.0",' +
    '"fom":0.00342,' +
    '"target_lines":["Na-Ka","Al-Ka"],' +
    '"element_pool":["W","Si"],' +
    '"substrate":"SiO2",' +
    '"structure_summary":{"type":"bilayer","d":45.2,"gamma":0.35,"N":120,"sigma":3.5},' +
    '"optimizer":{"population":500,"iterations":1000,"stagnation_limit":200},' +
    '"per_element":[' +
    '  {"line":"Na-Ka","peak_R":0.08,"fwhm":0.38},' +
    '  {"line":"Al-Ka","peak_R":0.15,"fwhm":0.52}],' +
    '"files":{' +
    '  "config":"config.json",' +
    '  "best_structure":"best_structure.json",' +
    '  "best_structure_xrc":"best_structure_xrc.json",' +
    '  "population":"population.json",' +
    '  "progress":"progress.log",' +
    '  "curves":["best_curves/Na.dat","best_curves/Al.dat"]}' +
    '}');
end;

function TTestXRFXPackage.CreateSampleXRCStructureFile: string;
begin
  Result := TPath.Combine(FTempDir, 'best_structure_xrc.json');
  TFile.WriteAllText(Result,
    '{"Stacks":[{"T":"ML","N":20,"Layers":[' +
    '{"M":"W","H":15.2,"HP":false,"Hmin":7.6,"Hmax":22.8,"ProfileH":"",' +
    '"s":3.5,"SP":false,"Smin":1.75,"Smax":5.25,"ProfileS":"",' +
    '"r":19.3,"RP":false,"Rmin":9.65,"Rmax":28.95,"ProfileR":""},' +
    '{"M":"Si","H":30.0,"HP":false,"Hmin":15.0,"Hmax":45.0,"ProfileH":"",' +
    '"s":3.5,"SP":false,"Smin":1.75,"Smax":5.25,"ProfileS":"",' +
    '"r":2.33,"RP":false,"Rmin":1.17,"Rmax":3.50,"ProfileR":""}]}],' +
    '"Subs":{"M":"SiO2","s":1.0,"r":2.65}}');
end;

function TTestXRFXPackage.CreateSampleProgressLog: string;
begin
  Result := TPath.Combine(FTempDir, 'progress.log');
  TFile.WriteAllText(Result,
    ' Iter       FoM  R_Na  R_Al    Div  Best               Time' + sLineBreak +
    '    0    0.0630  0.342  0.422  0.291  Mo/Si d=45.2         0:02' + sLineBreak +
    '   10    0.3013  0.361  0.435  0.179  Mo/Si d=42.8         0:05');
end;

function TTestXRFXPackage.CreateSampleXRFX: string;
var
  ZipFile: TZipFile;
  ResultsDir, CurvesDir, ManifestPath: string;
begin
  // Create files to zip
  ResultsDir := TPath.Combine(FTempDir, 'to_zip');
  TDirectory.CreateDirectory(ResultsDir);
  CurvesDir := TPath.Combine(ResultsDir, 'best_curves');
  TDirectory.CreateDirectory(CurvesDir);

  TFile.WriteAllText(TPath.Combine(ResultsDir, 'manifest.json'),
    '{"version":1,"fom":0.5,"target_lines":["Na-Ka"],' +
    '"element_pool":["W","Si"],"substrate":"SiO2",' +
    '"structure_summary":{"type":"bilayer","d":40.0,"gamma":0.3,"N":100,"sigma":3.0},' +
    '"optimizer":{"population":200,"iterations":500,"stagnation_limit":100},' +
    '"per_element":[{"line":"Na-Ka","peak_R":0.1,"fwhm":0.4}],' +
    '"files":{"curves":["best_curves/Na.dat"]}}');
  TFile.WriteAllText(TPath.Combine(ResultsDir, 'best_structure.json'), '{}');
  TFile.WriteAllText(TPath.Combine(ResultsDir, 'best_structure_xrc.json'),
    '{"Stacks":[{"T":"ML","N":100,"Layers":[' +
    '{"M":"W","H":12.0,"s":3.0,"r":19.3},' +
    '{"M":"Si","H":28.0,"s":3.0,"r":2.33}]}],' +
    '"Subs":{"M":"SiO2","s":1.0,"r":2.65}}');
  TFile.WriteAllText(TPath.Combine(CurvesDir, 'Na.dat'),
    'Theta(deg)'#9'Reflectivity' + sLineBreak + '1.0'#9'0.1');

  Result := TPath.Combine(FTempDir, 'test.xrfx');
  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(Result, zmWrite);
    ZipFile.Add(TPath.Combine(ResultsDir, 'manifest.json'), 'manifest.json');
    ZipFile.Add(TPath.Combine(ResultsDir, 'best_structure.json'), 'best_structure.json');
    ZipFile.Add(TPath.Combine(ResultsDir, 'best_structure_xrc.json'), 'best_structure_xrc.json');
    ZipFile.Add(TPath.Combine(CurvesDir, 'Na.dat'), 'best_curves/Na.dat');
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

// Test method stubs — implemented in subsequent tasks alongside their implementations

{ TTestManifestGeneration }

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ProducesFile;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ContainsManifest;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ContainsConfig;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ExcludesCheckpoint;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ManifestHasCorrectVersion;
begin
  Assert.Pass('Stub');
end;

{ TTestManifestLoading }

procedure TTestManifestLoading.Test_LoadManifest_ParsesVersion;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesFoM;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesTargetLines;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesPerElement;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesStructureSummary;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesOptimizerInfo;
begin
  Assert.Pass('Stub');
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesCurveFiles;
begin
  Assert.Pass('Stub');
end;

{ TTestExtraction }

procedure TTestExtraction.Test_ExtractXRFXPackage_CreatesFiles;
begin
  Assert.Pass('Stub');
end;

procedure TTestExtraction.Test_ExtractXRFXPackage_ManifestReadable;
begin
  Assert.Pass('Stub');
end;

{ TTestXRCStructureLoading }

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesLayers;
begin
  Assert.Pass('Stub');
end;

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesSubstrate;
begin
  Assert.Pass('Stub');
end;

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesStackN;
begin
  Assert.Pass('Stub');
end;

{ TTestCurveLoading }

procedure TTestCurveLoading.Test_LoadCurveFiles_ParsesElements;
begin
  Assert.Pass('Stub');
end;

procedure TTestCurveLoading.Test_LoadCurveFiles_ParsesData;
begin
  Assert.Pass('Stub');
end;

procedure TTestCurveLoading.Test_LoadCurveFiles_SkipsHeader;
begin
  Assert.Pass('Stub');
end;

{ TTestProgressLogLoading }

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesIterations;
begin
  Assert.Pass('Stub');
end;

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesFoM;
begin
  Assert.Pass('Stub');
end;

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesElementR;
begin
  Assert.Pass('Stub');
end;

end.
```

- [ ] **Step 3: Add units to test project**

In `Tests/XRayCalc3Tests.dpr`, add to the uses clause:

```pascal
  unit_xrfx_package in '..\Universal\unit_xrfx_package.pas',
  // ... in test units section:
  TestXRFXPackage in 'TestXRFXPackage.pas';
```

- [ ] **Step 4: Build tests and verify stubs pass**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All existing tests pass + new stub tests pass.

- [ ] **Step 5: Commit**

```
git add Universal/unit_xrfx_package.pas Tests/TestXRFXPackage.pas Tests/XRayCalc3Tests.dpr
git commit -m "+ Add unit_xrfx_package skeleton with types and test scaffold"
```

---

### Task 2: Implement LoadManifest

**Files:**
- Modify: `Universal/unit_xrfx_package.pas` — implement `LoadManifest`
- Modify: `Tests/TestXRFXPackage.pas` — activate manifest loading tests

- [ ] **Step 1: Write the failing tests**

Replace the `TTestManifestLoading` stubs with real tests:

```pascal
procedure TTestManifestLoading.Test_LoadManifest_ParsesVersion;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(1, M.Version);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesFoM;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(Double(0.00342), M.FoM, 1E-6);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesTargetLines;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(2, Length(M.TargetLines));
  Assert.AreEqual('Na-Ka', M.TargetLines[0]);
  Assert.AreEqual('Al-Ka', M.TargetLines[1]);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesPerElement;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(2, Length(M.PerElement));
  Assert.AreEqual('Na-Ka', M.PerElement[0].Line);
  Assert.AreEqual(Double(0.08), M.PerElement[0].PeakR, 1E-6);
  Assert.AreEqual(Double(0.38), M.PerElement[0].FWHM, 1E-6);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesStructureSummary;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual('bilayer', M.Structure.StructureType);
  Assert.AreEqual(Double(45.2), M.Structure.D, 1E-6);
  Assert.AreEqual(Double(0.35), M.Structure.Gamma, 1E-6);
  Assert.AreEqual(120, M.Structure.N);
  Assert.AreEqual(Double(3.5), M.Structure.Sigma, 1E-6);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesOptimizerInfo;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(500, M.Optimizer.Population);
  Assert.AreEqual(1000, M.Optimizer.Iterations);
  Assert.AreEqual(200, M.Optimizer.StagnationLimit);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesCurveFiles;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(2, Length(M.CurveFiles));
  Assert.AreEqual('best_curves/Na.dat', M.CurveFiles[0]);
end;
```

- [ ] **Step 2: Build and verify tests fail**

Build and run tests. Expected: `LoadManifest` tests fail with `ENotImplemented`.

- [ ] **Step 3: Implement LoadManifest**

```pascal
function LoadManifest(const ManifestPath: string): TXRFXManifest;
var
  Content: string;
  JSON, JStruct, JOpt: TJSONObject;
  JLines, JPool, JPerElem, JCurves: TJSONArray;
  JElem: TJSONObject;
  JFiles: TJSONObject;
  i: Integer;
begin
  Content := TFile.ReadAllText(ManifestPath);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    Result.Version := JSON.GetValue<Integer>('version');
    Result.Created := JSON.GetValue<string>('created');

    if JSON.FindValue('generator') <> nil then
      Result.Generator := JSON.GetValue<string>('generator');

    Result.FoM := JSON.GetValue<Double>('fom');
    Result.Substrate := JSON.GetValue<string>('substrate');

    // target_lines
    JLines := JSON.GetValue<TJSONArray>('target_lines');
    SetLength(Result.TargetLines, JLines.Count);
    for i := 0 to JLines.Count - 1 do
      Result.TargetLines[i] := JLines.Items[i].Value;

    // element_pool
    JPool := JSON.GetValue<TJSONArray>('element_pool');
    SetLength(Result.ElementPool, JPool.Count);
    for i := 0 to JPool.Count - 1 do
      Result.ElementPool[i] := JPool.Items[i].Value;

    // structure_summary
    JStruct := JSON.GetValue<TJSONObject>('structure_summary');
    Result.Structure.StructureType := JStruct.GetValue<string>('type');
    Result.Structure.D := JStruct.GetValue<Double>('d');
    Result.Structure.Gamma := JStruct.GetValue<Double>('gamma');
    Result.Structure.N := JStruct.GetValue<Integer>('N');
    Result.Structure.Sigma := JStruct.GetValue<Double>('sigma');

    // optimizer
    JOpt := JSON.GetValue<TJSONObject>('optimizer');
    Result.Optimizer.Population := JOpt.GetValue<Integer>('population');
    Result.Optimizer.Iterations := JOpt.GetValue<Integer>('iterations');
    Result.Optimizer.StagnationLimit := JOpt.GetValue<Integer>('stagnation_limit');

    // per_element
    JPerElem := JSON.GetValue<TJSONArray>('per_element');
    SetLength(Result.PerElement, JPerElem.Count);
    for i := 0 to JPerElem.Count - 1 do
    begin
      JElem := JPerElem.Items[i] as TJSONObject;
      Result.PerElement[i].Line := JElem.GetValue<string>('line');
      Result.PerElement[i].PeakR := JElem.GetValue<Double>('peak_R');
      Result.PerElement[i].FWHM := JElem.GetValue<Double>('fwhm');
    end;

    // files.curves
    if JSON.FindValue('files') <> nil then
    begin
      JFiles := JSON.GetValue<TJSONObject>('files');
      if JFiles.FindValue('curves') <> nil then
      begin
        JCurves := JFiles.GetValue<TJSONArray>('curves');
        SetLength(Result.CurveFiles, JCurves.Count);
        for i := 0 to JCurves.Count - 1 do
          Result.CurveFiles[i] := JCurves.Items[i].Value;
      end;
    end;
  finally
    JSON.Free;
  end;
end;
```

- [ ] **Step 4: Build and verify tests pass**

- [ ] **Step 5: Commit**

```
git add Universal/unit_xrfx_package.pas Tests/TestXRFXPackage.pas
git commit -m "+ Implement LoadManifest for .xrfx manifest parsing"
```

---

### Task 3: Implement CreateXRFXPackage (manifest generation + ZIP)

**Files:**
- Modify: `Universal/unit_xrfx_package.pas` — implement `CreateXRFXPackage` + helper `GenerateManifestJSON`
- Modify: `Tests/TestXRFXPackage.pas` — activate generation tests

- [ ] **Step 1: Write the failing tests**

Replace `TTestManifestGeneration` stubs:

```pascal
procedure TTestManifestGeneration.Test_CreateXRFXPackage_ProducesFile;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, [], ResultsDir, ConfigFile, OutputPath);
  Assert.IsTrue(TFile.Exists(OutputPath));
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ContainsManifest;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  ZipFile: TZipFile;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, [], ResultsDir, ConfigFile, OutputPath);

  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmRead);
    Assert.IsTrue(ZipFile.IndexOf('manifest.json') >= 0);
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ContainsConfig;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  ZipFile: TZipFile;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, [], ResultsDir, ConfigFile, OutputPath);

  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmRead);
    Assert.IsTrue(ZipFile.IndexOf('config.json') >= 0);
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ExcludesCheckpoint;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  ZipFile: TZipFile;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, [], ResultsDir, ConfigFile, OutputPath);

  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmRead);
    Assert.IsTrue(ZipFile.IndexOf('checkpoint.json') < 0);
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ManifestHasCorrectVersion;
var
  ResultsDir, ConfigFile, OutputPath, ExtractDir: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  M: TXRFXManifest;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');
  ExtractDir := TPath.Combine(FTempDir, 'extracted');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, [], ResultsDir, ConfigFile, OutputPath);

  // Extract and check manifest
  ExtractXRFXPackage(OutputPath, ExtractDir);
  M := LoadManifest(TPath.Combine(ExtractDir, 'manifest.json'));
  Assert.AreEqual(XRFX_MANIFEST_VERSION, M.Version);
end;
```

Note: The last test depends on `ExtractXRFXPackage` — implement both before running.

- [ ] **Step 2: Implement GenerateManifestJSON helper and CreateXRFXPackage**

```pascal
function GenerateManifestJSON(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const CurveFiles: TArray<string>): string;
var
  JSON, JStruct, JOpt, JFiles: TJSONObject;
  JTargets, JPool, JPerElem, JCurves: TJSONArray;
  JElem: TJSONObject;
  i: Integer;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('version', TJSONNumber.Create(XRFX_MANIFEST_VERSION));
    JSON.AddPair('created', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
    JSON.AddPair('generator', 'xrccmd');
    JSON.AddPair('fom', TJSONNumber.Create(FoM));

    // target_lines
    JTargets := TJSONArray.Create;
    for i := 0 to High(Config.Lines) do
      JTargets.Add(Config.Lines[i].Name);
    JSON.AddPair('target_lines', JTargets);

    // element_pool
    JPool := TJSONArray.Create;
    for i := 0 to High(Config.ElementPool) do
      JPool.Add(Config.ElementPool[i]);
    JSON.AddPair('element_pool', JPool);

    JSON.AddPair('substrate', Config.Substrate);

    // structure_summary
    JStruct := TJSONObject.Create;
    JStruct.AddPair('type', Config.Structure.StructureType);
    JStruct.AddPair('d', TJSONNumber.Create(BestGenome.d));
    JStruct.AddPair('gamma', TJSONNumber.Create(BestGenome.Gamma));
    JStruct.AddPair('N', TJSONNumber.Create(NRound(BestGenome.N)));
    JStruct.AddPair('sigma', TJSONNumber.Create(BestGenome.Sigma));
    JSON.AddPair('structure_summary', JStruct);

    // optimizer
    JOpt := TJSONObject.Create;
    JOpt.AddPair('population', TJSONNumber.Create(Config.Optimizer.Population));
    JOpt.AddPair('iterations', TJSONNumber.Create(Config.Optimizer.Iterations));
    JOpt.AddPair('stagnation_limit', TJSONNumber.Create(Config.Optimizer.StagnationLimit));
    JSON.AddPair('optimizer', JOpt);

    // per_element
    JPerElem := TJSONArray.Create;
    for i := 0 to High(PerElement) do
    begin
      JElem := TJSONObject.Create;
      JElem.AddPair('line', PerElement[i].Line);
      JElem.AddPair('peak_R', TJSONNumber.Create(PerElement[i].PeakR));
      JElem.AddPair('fwhm', TJSONNumber.Create(PerElement[i].FWHM));
      JPerElem.Add(JElem);
    end;
    JSON.AddPair('per_element', JPerElem);

    // files
    JFiles := TJSONObject.Create;
    JFiles.AddPair('config', 'config.json');
    JFiles.AddPair('best_structure', 'best_structure.json');
    JFiles.AddPair('best_structure_xrc', 'best_structure_xrc.json');
    JFiles.AddPair('population', 'population.json');
    JFiles.AddPair('progress', 'progress.log');

    JCurves := TJSONArray.Create;
    for i := 0 to High(CurveFiles) do
      JCurves.Add(CurveFiles[i]);
    JFiles.AddPair('curves', JCurves);
    JSON.AddPair('files', JFiles);

    Result := JSON.Format(2);
  finally
    JSON.Free;
  end;
end;

procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, ConfigFilePath, OutputPath: string);
var
  ZipFile: TZipFile;
  Files: TStringDynArray;
  FilePath, RelPath, CurvesDir: string;
  CurveFiles: TArray<string>;
  ManifestPath, ConfigDest: string;
  CurveNames: TStringDynArray;
  i: Integer;
begin
  // 1. Copy config JSON into results dir
  ConfigDest := TPath.Combine(ResultsDir, 'config.json');
  if TFile.Exists(ConfigFilePath) then
    TFile.Copy(ConfigFilePath, ConfigDest, True);

  // 2. Discover curve files for manifest
  CurvesDir := TPath.Combine(ResultsDir, 'best_curves');
  if TDirectory.Exists(CurvesDir) then
  begin
    CurveNames := TDirectory.GetFiles(CurvesDir, '*.dat');
    SetLength(CurveFiles, Length(CurveNames));
    for i := 0 to High(CurveNames) do
      CurveFiles[i] := 'best_curves/' + TPath.GetFileName(CurveNames[i]);
  end;

  // 3. Generate manifest.json
  ManifestPath := TPath.Combine(ResultsDir, 'manifest.json');
  TFile.WriteAllText(ManifestPath,
    GenerateManifestJSON(Config, BestGenome, FoM, PerElement, CurveFiles));

  // 4. ZIP everything except checkpoint.json
  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmWrite);

    Files := TDirectory.GetFiles(ResultsDir, '*', TSearchOption.soAllDirectories);
    for FilePath in Files do
    begin
      if SameText(TPath.GetFileName(FilePath), 'checkpoint.json') then
        Continue;

      // Build relative path using forward slashes
      RelPath := FilePath.Substring(Length(IncludeTrailingPathDelimiter(ResultsDir)));
      RelPath := StringReplace(RelPath, '\', '/', [rfReplaceAll]);
      ZipFile.Add(FilePath, RelPath);
    end;

    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;
```

- [ ] **Step 3: Implement ExtractXRFXPackage**

```pascal
procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
begin
  if not TDirectory.Exists(TempDir) then
    TDirectory.CreateDirectory(TempDir);

  TZipFile.ExtractZipFile(XRFXPath, TempDir);
end;
```

- [ ] **Step 4: Build and verify tests pass**

- [ ] **Step 5: Commit**

```
git add Universal/unit_xrfx_package.pas Tests/TestXRFXPackage.pas
git commit -m "+ Implement CreateXRFXPackage and ExtractXRFXPackage"
```

---

### Task 4: Implement LoadXRCStructure

**Files:**
- Modify: `Universal/unit_xrfx_package.pas`
- Modify: `Tests/TestXRFXPackage.pas`

- [ ] **Step 1: Write the failing tests**

Replace `TTestXRCStructureLoading` stubs:

```pascal
procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesLayers;
var
  S: TXRFXStructure;
begin
  S := LoadXRCStructure(CreateSampleXRCStructureFile);
  Assert.AreEqual(2, Length(S.Layers));
  Assert.AreEqual('W', S.Layers[0].Material);
  Assert.AreEqual(Double(15.2), S.Layers[0].Thickness, 1E-6);
  Assert.AreEqual(Double(3.5), S.Layers[0].Roughness, 1E-6);
  Assert.AreEqual(Double(19.3), S.Layers[0].Density, 1E-6);
  Assert.AreEqual('Si', S.Layers[1].Material);
end;

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesSubstrate;
var
  S: TXRFXStructure;
begin
  S := LoadXRCStructure(CreateSampleXRCStructureFile);
  Assert.AreEqual('SiO2', S.Substrate.Material);
  Assert.AreEqual(Double(1.0), S.Substrate.Roughness, 1E-6);
  Assert.AreEqual(Double(2.65), S.Substrate.Density, 1E-6);
end;

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesStackN;
var
  S: TXRFXStructure;
begin
  S := LoadXRCStructure(CreateSampleXRCStructureFile);
  Assert.AreEqual(20, S.StackN);
end;
```

- [ ] **Step 2: Build and verify tests fail**

- [ ] **Step 3: Implement LoadXRCStructure**

```pascal
function LoadXRCStructure(const JsonPath: string): TXRFXStructure;
var
  Content: string;
  JSON, JSubs, JLayer: TJSONObject;
  JStacks, JLayers: TJSONArray;
  JStack: TJSONObject;
  i: Integer;
begin
  Content := TFile.ReadAllText(JsonPath);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    // Parse first stack (ML = multilayer)
    JStacks := JSON.GetValue<TJSONArray>('Stacks');
    JStack := JStacks.Items[0] as TJSONObject;
    Result.StackN := JStack.GetValue<Integer>('N');

    JLayers := JStack.GetValue<TJSONArray>('Layers');
    SetLength(Result.Layers, JLayers.Count);
    for i := 0 to JLayers.Count - 1 do
    begin
      JLayer := JLayers.Items[i] as TJSONObject;
      Result.Layers[i].Material := JLayer.GetValue<string>('M');
      Result.Layers[i].Thickness := JLayer.GetValue<Double>('H');
      Result.Layers[i].Roughness := JLayer.GetValue<Double>('s');
      Result.Layers[i].Density := JLayer.GetValue<Double>('r');
    end;

    // Substrate
    JSubs := JSON.GetValue<TJSONObject>('Subs');
    Result.Substrate.Material := JSubs.GetValue<string>('M');
    Result.Substrate.Roughness := JSubs.GetValue<Double>('s');
    Result.Substrate.Density := JSubs.GetValue<Double>('r');
    Result.Substrate.Thickness := 0;
  finally
    JSON.Free;
  end;
end;
```

- [ ] **Step 4: Build and verify tests pass**

- [ ] **Step 5: Commit**

```
git add Universal/unit_xrfx_package.pas Tests/TestXRFXPackage.pas
git commit -m "+ Implement LoadXRCStructure for .xrfx viewer"
```

---

### Task 5: Implement LoadProgressLog

**Files:**
- Modify: `Universal/unit_xrfx_package.pas`
- Modify: `Tests/TestXRFXPackage.pas`

- [ ] **Step 1: Write the failing tests**

Replace `TTestProgressLogLoading` stubs:

```pascal
procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesIterations;
var
  Entries: TArray<TProgressEntry>;
begin
  Entries := LoadProgressLog(CreateSampleProgressLog);
  Assert.AreEqual(2, Length(Entries));
  Assert.AreEqual(0, Entries[0].Iteration);
  Assert.AreEqual(10, Entries[1].Iteration);
end;

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesFoM;
var
  Entries: TArray<TProgressEntry>;
begin
  Entries := LoadProgressLog(CreateSampleProgressLog);
  Assert.AreEqual(Double(0.0630), Entries[0].FoM, 1E-4);
  Assert.AreEqual(Double(0.3013), Entries[1].FoM, 1E-4);
end;

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesElementR;
var
  Entries: TArray<TProgressEntry>;
begin
  Entries := LoadProgressLog(CreateSampleProgressLog);
  // 2 element columns: R_Na, R_Al
  Assert.AreEqual(2, Length(Entries[0].ElementR));
  Assert.AreEqual(Double(0.342), Entries[0].ElementR[0], 1E-3);
  Assert.AreEqual(Double(0.422), Entries[0].ElementR[1], 1E-3);
end;
```

- [ ] **Step 2: Build and verify tests fail**

- [ ] **Step 3: Implement LoadProgressLog**

The progress.log format (from `unit_universal_io.pas:OpenLog` and `LogIteration`):
- Header: `%5s  %8s  [%5s per R_elem]  %5s  %-18s  %8s`
  = `Iter  FoM  R_Na  R_Al  Div  Best               Time`
- Data: `%5d  %8.4f  [%5.3f per elem]  %5.3f  %-18s  %4d:%02d`

Key insight: the `Best` column is a free-text `%-18s` field that may contain spaces (e.g. `Mo/Si d=45.2`). Splitting on whitespace breaks it. Solution: use the header to count `R_` columns, then for data lines take only the first `2 + numElements + 1` whitespace-split tokens (Iter, FoM, R_values, Div). Everything after Div (BestInfo + Time) is ignored.

```pascal
function LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;
var
  AllLines: TStringDynArray;
  Line: string;
  Parts, HeaderParts: TArray<string>;
  i, j, NumElements, NumExpectedTokens: Integer;
  Entry: TProgressEntry;
  ResultList: TList<TProgressEntry>;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  AllLines := TFile.ReadAllLines(LogPath);
  ResultList := TList<TProgressEntry>.Create;
  try
    // Step 1: Parse header to count R_ columns
    NumElements := 0;
    for i := 0 to High(AllLines) do
    begin
      Line := Trim(AllLines[i]);
      if Line.StartsWith('Iter') then
      begin
        HeaderParts := Line.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
        for j := 0 to High(HeaderParts) do
          if HeaderParts[j].StartsWith('R_') then
            Inc(NumElements);
        Break;
      end;
    end;

    // We need: Iter + FoM + NumElements R values + Div = 2 + NumElements + 1
    NumExpectedTokens := 2 + NumElements + 1;

    // Step 2: Parse data lines
    for i := 0 to High(AllLines) do
    begin
      Line := Trim(AllLines[i]);
      if (Line = '') or Line.StartsWith('Iter') then
        Continue;

      Parts := Line.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
      if Length(Parts) < NumExpectedTokens then
        Continue;

      Entry := Default(TProgressEntry);
      Entry.Iteration := StrToInt(Parts[0]);
      Entry.FoM := StrToFloat(Parts[1], FS);

      SetLength(Entry.ElementR, NumElements);
      for j := 0 to NumElements - 1 do
        Entry.ElementR[j] := StrToFloat(Parts[2 + j], FS);

      Entry.Diversity := StrToFloat(Parts[2 + NumElements], FS);

      ResultList.Add(Entry);
    end;

    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;
```

- [ ] **Step 4: Build and verify tests pass**

- [ ] **Step 5: Commit**

```
git add Universal/unit_xrfx_package.pas Tests/TestXRFXPackage.pas
git commit -m "+ Implement LoadProgressLog for .xrfx viewer"
```

---

### Task 5b: Implement LoadCurveFiles

**Files:**
- Modify: `Universal/unit_xrfx_package.pas`
- Modify: `Tests/TestXRFXPackage.pas`

- [ ] **Step 1: Write the failing tests**

Replace `TTestCurveLoading` stubs:

```pascal
procedure TTestCurveLoading.Test_LoadCurveFiles_ParsesElements;
var
  Curves: TArray<TXRFXCurveData>;
  CurvesDir: string;
begin
  CreateSampleResultsDir; // creates best_curves/ with Na.dat, Al.dat
  CurvesDir := TPath.Combine(TPath.Combine(FTempDir, 'results'), 'best_curves');
  Curves := LoadCurveFiles(CurvesDir);
  Assert.AreEqual(2, Length(Curves));
  // Elements derived from filenames
  Assert.IsTrue((Curves[0].Element = 'Na') or (Curves[0].Element = 'Al'));
end;

procedure TTestCurveLoading.Test_LoadCurveFiles_ParsesData;
var
  Curves: TArray<TXRFXCurveData>;
  CurvesDir: string;
  i: Integer;
begin
  CreateSampleResultsDir;
  CurvesDir := TPath.Combine(TPath.Combine(FTempDir, 'results'), 'best_curves');
  Curves := LoadCurveFiles(CurvesDir);
  // Find Na curve
  for i := 0 to High(Curves) do
    if Curves[i].Element = 'Na' then
    begin
      Assert.AreEqual(2, Length(Curves[i].Theta));
      Assert.AreEqual(Double(0.5), Curves[i].Theta[0], 1E-4);
      Assert.AreEqual(Double(3.14159e-04), Curves[i].Refl[0], 1E-8);
      Exit;
    end;
  Assert.Fail('Na curve not found');
end;

procedure TTestCurveLoading.Test_LoadCurveFiles_SkipsHeader;
var
  Curves: TArray<TXRFXCurveData>;
  CurvesDir: string;
  i: Integer;
begin
  CreateSampleResultsDir;
  CurvesDir := TPath.Combine(TPath.Combine(FTempDir, 'results'), 'best_curves');
  Curves := LoadCurveFiles(CurvesDir);
  // Each file has header + 2 data lines = 2 data points
  for i := 0 to High(Curves) do
    Assert.AreEqual(2, Length(Curves[i].Theta),
      'Curve ' + Curves[i].Element + ' should have 2 data points');
end;
```

- [ ] **Step 2: Build and verify tests fail**

- [ ] **Step 3: Implement LoadCurveFiles**

```pascal
function LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
var
  FileNames: TStringDynArray;
  i, j: Integer;
  Lines: TStringDynArray;
  Parts: TArray<string>;
  ThetaList: TList<Double>;
  ReflList: TList<Double>;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  if not TDirectory.Exists(CurvesDir) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  FileNames := TDirectory.GetFiles(CurvesDir, '*.dat');
  SetLength(Result, Length(FileNames));

  for i := 0 to High(FileNames) do
  begin
    Result[i].Element := TPath.GetFileNameWithoutExtension(FileNames[i]);
    Lines := TFile.ReadAllLines(FileNames[i]);

    ThetaList := TList<Double>.Create;
    ReflList := TList<Double>.Create;
    try
      for j := 0 to High(Lines) do
      begin
        if Lines[j].StartsWith('Theta') or (Trim(Lines[j]) = '') then
          Continue;
        Parts := Lines[j].Split([#9]);
        if Length(Parts) >= 2 then
        begin
          ThetaList.Add(StrToFloat(Trim(Parts[0]), FS));
          ReflList.Add(StrToFloat(Trim(Parts[1]), FS));
        end;
      end;
      Result[i].Theta := ThetaList.ToArray;
      Result[i].Refl := ReflList.ToArray;
    finally
      ThetaList.Free;
      ReflList.Free;
    end;
  end;
end;
```

- [ ] **Step 4: Build and verify tests pass**

- [ ] **Step 5: Commit**

```
git add Universal/unit_xrfx_package.pas Tests/TestXRFXPackage.pas
git commit -m "+ Implement LoadCurveFiles for .xrfx viewer"
```

---

### Task 6: Round-trip integration test

**Files:**
- Modify: `Tests/TestXRFXPackage.pas` — activate extraction tests

- [ ] **Step 1: Write the failing tests**

Replace `TTestExtraction` stubs:

```pascal
procedure TTestExtraction.Test_ExtractXRFXPackage_CreatesFiles;
var
  XRFXPath, ExtractDir: string;
begin
  XRFXPath := CreateSampleXRFX;
  ExtractDir := TPath.Combine(FTempDir, 'extracted');
  ExtractXRFXPackage(XRFXPath, ExtractDir);

  Assert.IsTrue(TFile.Exists(TPath.Combine(ExtractDir, 'manifest.json')));
  Assert.IsTrue(TFile.Exists(TPath.Combine(ExtractDir, 'best_structure.json')));
  Assert.IsTrue(TFile.Exists(TPath.Combine(ExtractDir, 'best_structure_xrc.json')));
  Assert.IsTrue(TFile.Exists(TPath.Combine(ExtractDir, 'best_curves\Na.dat')));
end;

procedure TTestExtraction.Test_ExtractXRFXPackage_ManifestReadable;
var
  XRFXPath, ExtractDir: string;
  M: TXRFXManifest;
begin
  XRFXPath := CreateSampleXRFX;
  ExtractDir := TPath.Combine(FTempDir, 'extracted');
  ExtractXRFXPackage(XRFXPath, ExtractDir);

  M := LoadManifest(TPath.Combine(ExtractDir, 'manifest.json'));
  Assert.AreEqual(1, M.Version);
  Assert.AreEqual(Double(0.5), M.FoM, 1E-6);
end;
```

- [ ] **Step 2: Build and verify tests pass** (these should already pass with existing implementations)

- [ ] **Step 3: Commit**

```
git add Tests/TestXRFXPackage.pas
git commit -m "* Activate extraction round-trip tests"
```

---

## Chunk 2: xrccmd Integration

### Task 7: Wire CreateXRFXPackage into xrccmd

**Files:**
- Modify: `XRC_CMD/units/cmd_unit_universal.pas` — store completion data, call package creation
- Modify: `XRC_CMD/xrccmd.dproj` — add `unit_xrfx_package` to search path (if needed)

The integration point: `TConsoleHandler.HandleCompletion` already receives `TIterationData` containing `BestGenome` and `PerElement: TArray<TElementResult>`. We store this and call packaging after `Optimizer.Run`.

- [ ] **Step 1: Add fields to TConsoleHandler**

In `cmd_unit_universal.pas`, add to `TConsoleHandler`:

```pascal
  private
    // existing fields...
    FLastIterData: TIterationData;
    FCompleted: Boolean;
  public
    // existing methods...
    property Completed: Boolean read FCompleted;
    property LastIterData: TIterationData read FLastIterData;
```

- [ ] **Step 2: Store data in HandleCompletion**

At the start of `HandleCompletion` (around line 72):

```pascal
procedure TConsoleHandler.HandleCompletion(const Data: TIterationData;
  const Curves: TArray<TCurveData>);
begin
  FLastIterData := Data;
  FCompleted := True;
  // ... existing console output code unchanged ...
```

- [ ] **Step 3: Add packaging call after Optimizer.Run in cmdUniversalMirror**

After the `Optimizer.Run` call (around line 149) and before the `finally` block, add:

```pascal
    Optimizer.Run;

    // Package results into .xrfx
    if Handler.Completed then
    begin
      var PerElem: TArray<TXRFXElementResult>;
      SetLength(PerElem, Length(Handler.LastIterData.PerElement));
      for var i := 0 to High(PerElem) do
      begin
        PerElem[i].Line := Handler.LastIterData.PerElement[i].Element;
        PerElem[i].PeakR := Handler.LastIterData.PerElement[i].RPeak;
        PerElem[i].FWHM := Handler.LastIterData.PerElement[i].FWHM;
      end;

      var XRFXPath := ChangeFileExt(ConfigFile, XRFX_EXT);
      CreateXRFXPackage(Config, Handler.LastIterData.BestGenome,
        Handler.LastIterData.FoM,
        PerElem, Config.OutputDir, ConfigFile, XRFXPath);
      WriteLn('Package saved: ' + XRFXPath);
    end;
```

- [ ] **Step 4: Add uses clauses**

In `cmd_unit_universal.pas`, add to the uses clause:

```pascal
  unit_xrfx_package
```

- [ ] **Step 5: Build xrccmd Win64**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

If `unit_xrfx_package` is not found, add `..\..\Universal` to xrccmd.dproj's `DCC_UnitSearchPath` or add the unit explicitly to `xrccmd.dpr`'s uses clause with a relative path:

```pascal
  unit_xrfx_package in '..\Universal\unit_xrfx_package.pas',
```

- [ ] **Step 6: Build tests and verify all pass**

- [ ] **Step 7: Commit**

```
git add XRC_CMD/units/cmd_unit_universal.pas XRC_CMD/xrccmd.dpr
git commit -m "+ Generate .xrfx package after universal mirror optimization"
```

---

## Chunk 3: XRFView Application

### Task 8: Project skeleton and main form

**Files:**
- Create: `XRFView/XRFView.dpr`
- Create: `XRFView/Forms/frm_XRFViewMain.pas`
- Create: `XRFView/Forms/frm_XRFViewMain.dfm`
- Modify: `XRC3.groupproj` — add XRFView project

This task creates the project and the main form with the TriboViewer-style layout: shell tree + shell list on the left, TPageControl on the right, toolbar and status bar.

- [ ] **Step 1: Create XRFView.dpr**

```pascal
program XRFView;

uses
  Vcl.Forms,
  frm_XRFViewMain in 'Forms\frm_XRFViewMain.pas' {frmXRFViewMain},
  unit_xrfx_package in '..\Universal\unit_xrfx_package.pas',
  unit_universal_types in '..\Universal\unit_universal_types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.Title := 'XRFView';
  Application.CreateForm(TfrmXRFViewMain, frmXRFViewMain);
  Application.Run;
end.
```

- [ ] **Step 2: Create frm_XRFViewMain.pas**

Main form with:
- TToolBar (top) with buttons: Refresh, Export Structure, Copy Data, Save Image
- TRzSplitter (MainSplitter) horizontal — left: shell panel, right: detail panel
- Left side: TRzSplitter (ShellSplitter) vertical — top: TJamShellTree, bottom: TJamShellList
- TJamShellBreadCrumbBar above the shell tree
- Right side: TPageControl with tabs: Structure, Curves, Info, Progress, Compare
- TRzStatusBar (bottom)

```pascal
unit frm_XRFViewMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.IOUtils, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ExtCtrls, Vcl.ExtDlgs, Vcl.Menus,
  System.ImageList, Vcl.ImgList,
  RzPanel, RzSplit,
  JamShellBreadCrumbBar, ShellControls, ShellLink,
  Jam.Shell.Types, Jam.Shell.Controls.Types,
  Jam.Shell.Controls.BaseShellListView,
  unit_xrfx_package, unit_universal_types,
  xrfview_unit_loader;

type
  TfrmXRFViewMain = class(TForm)
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuExit: TMenuItem;
    mnuView: TMenuItem;
    mnuTools: TMenuItem;
    mnuRegisterExt: TMenuItem;
    RzStatusBar1: TRzStatusBar;
    ToolBar1: TToolBar;
    ToolBarImages: TImageList;
    btnRefresh: TToolButton;
    btnExportStructure: TToolButton;
    btnCopyData: TToolButton;
    btnSaveImage: TToolButton;
    MainSplitter: TRzSplitter;
    ShellSplitter: TRzSplitter;
    ShellTree: TJamShellTree;
    ShellList: TJamShellList;
    JamShellLink1: TJamShellLink;
    JamShellBreadCrumbBar1: TJamShellBreadCrumbBar;
    PageControl1: TPageControl;
    tabStructure: TTabSheet;
    tabCurves: TTabSheet;
    tabInfo: TTabSheet;
    tabProgress: TTabSheet;
    tabCompare: TTabSheet;
    dlgSave: TSaveDialog;
    dlgSaveImage: TSavePictureDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShellListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnExportStructureClick(Sender: TObject);
    procedure btnCopyDataClick(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuRegisterExtClick(Sender: TObject);
  private
    FLoader: TXRFViewLoader;
    procedure ProcessFile(const FileName: string);
  end;

var
  frmXRFViewMain: TfrmXRFViewMain;

implementation

uses
  System.Win.Registry, ClipBrd;

{$R *.dfm}

procedure RegisterFileType(const Prefix, ExePath: string);
begin
  with TRegistry.Create do
  try
    RootKey := HKEY_CURRENT_USER;
    OpenKey('Software\Classes\.' + Prefix, True);
    WriteString('', Prefix + 'file');
    CloseKey;
    CreateKey('Software\Classes\' + Prefix + 'file');
    OpenKey('Software\Classes\' + Prefix + 'file\DefaultIcon', True);
    WriteString('', ExePath + ',0');
    CloseKey;
    OpenKey('Software\Classes\' + Prefix + 'file\shell\open\command', True);
    WriteString('', '"' + ExePath + '" "%1"');
    CloseKey;
  finally
    Free;
  end;
end;

procedure TfrmXRFViewMain.FormCreate(Sender: TObject);
begin
  FLoader := TXRFViewLoader.Create;
  tabCompare.TabVisible := False; // only visible in comparison mode

  // Handle command-line file open
  if (ParamCount > 0) and TFile.Exists(ParamStr(1)) then
  begin
    ShellList.Path := ExtractFilePath(ParamStr(1));
  end;
end;

procedure TfrmXRFViewMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLoader);
end;

procedure TfrmXRFViewMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  Application.Terminate;
end;

procedure TfrmXRFViewMain.ShellListSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  FileName: string;
begin
  if (Item = nil) or not Selected then Exit;

  FileName := IncludeTrailingPathDelimiter(ShellList.Path) + Item.Caption;
  if not TFile.Exists(FileName) then Exit;
  if not SameText(ExtractFileExt(FileName), XRFX_EXT) then Exit;

  try
    Screen.Cursor := crHourGlass;
    ProcessFile(FileName);
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmXRFViewMain.ProcessFile(const FileName: string);
begin
  FLoader.LoadFile(FileName);
  // TODO: populate frames from FLoader data (Tasks 9-12)
  RzStatusBar1.SimpleText := Format('FoM: %.6f  |  %s',
    [FLoader.Manifest.FoM, ExtractFileName(FileName)]);
end;

procedure TfrmXRFViewMain.btnRefreshClick(Sender: TObject);
begin
  ShellTree.FullRefresh;
  ShellList.FullRefresh;
end;

procedure TfrmXRFViewMain.btnExportStructureClick(Sender: TObject);
begin
  if not FLoader.IsLoaded then Exit;
  dlgSave.DefaultExt := '.json';
  dlgSave.Filter := 'JSON structure|*.json';
  dlgSave.FileName := 'best_structure_xrc.json';
  if dlgSave.Execute then
    FLoader.ExtractFile('best_structure_xrc.json', dlgSave.FileName);
end;

procedure TfrmXRFViewMain.btnCopyDataClick(Sender: TObject);
begin
  // Copy active chart data to clipboard — implemented in Task 10
end;

procedure TfrmXRFViewMain.btnSaveImageClick(Sender: TObject);
begin
  // Save active chart as image — implemented in Task 10
end;

procedure TfrmXRFViewMain.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmXRFViewMain.mnuRegisterExtClick(Sender: TObject);
begin
  RegisterFileType('xrfx', Application.ExeName);
end;

end.
```

- [ ] **Step 3: Create frm_XRFViewMain.dfm**

Create the DFM via the IDE or write the text-format DFM. The layout mirrors TriboViewer's `frm_Main.dfm` structure. Key properties:
- `ShellList.Filter := '*.xrfx'`
- `ShellList.FileSystemOnly := True`
- `ShellList.ReadOnly := True`
- `ShellTree.RootedAt := SF_DRIVES`
- `MainSplitter.Position := 350` (left panel width)
- `ShellSplitter.Percent := 40` (tree gets 40%, list gets 60%)

Build and verify the form compiles and runs (empty tabs).

- [ ] **Step 4: Add XRFView to group project**

In `XRC3.groupproj`, add:

```xml
<Projects Include="XRFView\XRFView.dproj">
    <Dependencies/>
</Projects>
```

- [ ] **Step 5: Build XRFView Win64**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

- [ ] **Step 6: Commit**

```
git add XRFView/ XRC3.groupproj
git commit -m "+ Add XRFView project skeleton with shell navigation layout"
```

---

### Task 9: Loader orchestrator

**Files:**
- Create: `XRFView/Units/xrfview_unit_loader.pas`

- [ ] **Step 1: Implement TXRFViewLoader**

```pascal
unit xrfview_unit_loader;

interface

uses
  System.SysUtils, System.IOUtils, System.Classes,
  System.Generics.Collections,
  unit_xrfx_package;

type
  TLoadedResult = record
    FileName: string;
    TempDir: string;
    Manifest: TXRFXManifest;
    Structure: TXRFXStructure;
    Curves: TArray<TXRFXCurveData>;
    Progress: TArray<TProgressEntry>;
  end;

  TXRFViewLoader = class
  private
    FResults: TList<TLoadedResult>;
    FBaseTempDir: string;
    function  GetManifest: TXRFXManifest;
    procedure CleanupTemp(const TempDir: string);
    procedure CleanupStale;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFile(const FileName: string);
    procedure LoadMultiple(const FileNames: TArray<string>);
    procedure Clear;
    function  ExtractFile(const ArchiveName, DestPath: string): Boolean;
    function  IsLoaded: Boolean;
    function  ResultCount: Integer;
    property  Manifest: TXRFXManifest read GetManifest;
    function  GetResult(Index: Integer): TLoadedResult;
  end;

implementation

constructor TXRFViewLoader.Create;
begin
  inherited;
  FResults := TList<TLoadedResult>.Create;
  FBaseTempDir := TPath.Combine(TPath.GetTempPath, 'XRFView');
  if not TDirectory.Exists(FBaseTempDir) then
    TDirectory.CreateDirectory(FBaseTempDir);
  CleanupStale;
end;

destructor TXRFViewLoader.Destroy;
var
  R: TLoadedResult;
begin
  for R in FResults do
    CleanupTemp(R.TempDir);
  FreeAndNil(FResults);
  inherited;
end;

procedure TXRFViewLoader.CleanupTemp(const TempDir: string);
begin
  if TDirectory.Exists(TempDir) then
    TDirectory.Delete(TempDir, True);
end;

procedure TXRFViewLoader.CleanupStale;
var
  Dirs: TStringDynArray;
  Dir: string;
begin
  if not TDirectory.Exists(FBaseTempDir) then Exit;
  Dirs := TDirectory.GetDirectories(FBaseTempDir);
  for Dir in Dirs do
  begin
    if TDirectory.GetCreationTime(Dir) < Now - 1 then // older than 24h
      TDirectory.Delete(Dir, True);
  end;
end;

procedure TXRFViewLoader.Clear;
var
  R: TLoadedResult;
begin
  for R in FResults do
    CleanupTemp(R.TempDir);
  FResults.Clear;
end;

procedure TXRFViewLoader.LoadFile(const FileName: string);
var
  R: TLoadedResult;
  CurvesDir: string;
begin
  Clear;

  R := Default(TLoadedResult);
  R.FileName := FileName;
  R.TempDir := TPath.Combine(FBaseTempDir, TGUID.NewGuid.ToString);

  ExtractXRFXPackage(FileName, R.TempDir);
  R.Manifest := LoadManifest(TPath.Combine(R.TempDir, 'manifest.json'));

  // Load structure (optional — file may be missing)
  var XRCPath := TPath.Combine(R.TempDir, 'best_structure_xrc.json');
  if TFile.Exists(XRCPath) then
    R.Structure := LoadXRCStructure(XRCPath);

  // Load curves via shared function (handles locale, header skipping)
  CurvesDir := TPath.Combine(R.TempDir, 'best_curves');
  R.Curves := LoadCurveFiles(CurvesDir);

  // Load progress
  var ProgressPath := TPath.Combine(R.TempDir, 'progress.log');
  if TFile.Exists(ProgressPath) then
    R.Progress := LoadProgressLog(ProgressPath);

  FResults.Add(R);
end;

procedure TXRFViewLoader.LoadMultiple(const FileNames: TArray<string>);
var
  FN: string;
begin
  Clear;
  for FN in FileNames do
  begin
    // Same as LoadFile but without Clear
    var R: TLoadedResult := Default(TLoadedResult);
    R.FileName := FN;
    R.TempDir := TPath.Combine(FBaseTempDir, TGUID.NewGuid.ToString);
    ExtractXRFXPackage(FN, R.TempDir);
    R.Manifest := LoadManifest(TPath.Combine(R.TempDir, 'manifest.json'));

    var XRCPath := TPath.Combine(R.TempDir, 'best_structure_xrc.json');
    if TFile.Exists(XRCPath) then
      R.Structure := LoadXRCStructure(XRCPath);

    FResults.Add(R);
  end;
end;

function TXRFViewLoader.ExtractFile(const ArchiveName, DestPath: string): Boolean;
var
  SrcPath: string;
begin
  Result := False;
  if not IsLoaded then Exit;
  SrcPath := TPath.Combine(FResults[0].TempDir, ArchiveName);
  if TFile.Exists(SrcPath) then
  begin
    TFile.Copy(SrcPath, DestPath, True);
    Result := True;
  end;
end;

function TXRFViewLoader.IsLoaded: Boolean;
begin
  Result := FResults.Count > 0;
end;

function TXRFViewLoader.ResultCount: Integer;
begin
  Result := FResults.Count;
end;

function TXRFViewLoader.GetManifest: TXRFXManifest;
begin
  if FResults.Count > 0 then
    Result := FResults[0].Manifest
  else
    Result := Default(TXRFXManifest);
end;

function TXRFViewLoader.GetResult(Index: Integer): TLoadedResult;
begin
  Result := FResults[Index];
end;

end.
```

Note: `GetManifest` needs to be declared as a function in the class declaration (not as a `read` property accessor directly). Adjust the class declaration accordingly — replace `property Manifest: TXRFXManifest read GetManifest;` with the function.

- [ ] **Step 2: Add to XRFView.dpr uses clause**

```pascal
  xrfview_unit_loader in 'Units\xrfview_unit_loader.pas',
```

- [ ] **Step 3: Build and verify**

- [ ] **Step 4: Commit**

```
git add XRFView/Units/xrfview_unit_loader.pas XRFView/XRFView.dpr
git commit -m "+ Add XRFViewLoader orchestrator for .xrfx file loading"
```

---

### Task 10: View frames — Structure and Info

**Files:**
- Create: `XRFView/Views/frame_StructureView.pas` + `.dfm`
- Create: `XRFView/Views/frame_InfoView.pas` + `.dfm`

- [ ] **Step 1: Implement frame_StructureView**

A TFrame containing a TStringGrid for the layer table and TLabels for summary info (d, gamma, N, type).

```pascal
unit frame_StructureView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Grids, Vcl.StdCtrls, Vcl.ExtCtrls,
  unit_xrfx_package;

type
  TframeStructureView = class(TFrame)
    grdLayers: TStringGrid;
    pnlSummary: TPanel;
    lblPeriod: TLabel;
    lblGamma: TLabel;
    lblN: TLabel;
    lblType: TLabel;
  public
    procedure LoadStructure(const Structure: TXRFXStructure;
      const Summary: TXRFXStructureSummary);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeStructureView.LoadStructure(const Structure: TXRFXStructure;
  const Summary: TXRFXStructureSummary);
var
  i, Row: Integer;
begin
  grdLayers.ColCount := 5;
  grdLayers.RowCount := Length(Structure.Layers) + 2; // header + substrate
  grdLayers.FixedRows := 1;

  // Header
  grdLayers.Cells[0, 0] := '#';
  grdLayers.Cells[1, 0] := 'Material';
  grdLayers.Cells[2, 0] := 'Thickness (A)';
  grdLayers.Cells[3, 0] := 'Roughness (A)';
  grdLayers.Cells[4, 0] := 'Density (g/cm3)';

  // Layers
  for i := 0 to High(Structure.Layers) do
  begin
    Row := i + 1;
    grdLayers.Cells[0, Row] := IntToStr(i + 1);
    grdLayers.Cells[1, Row] := Structure.Layers[i].Material;
    grdLayers.Cells[2, Row] := Format('%.2f', [Structure.Layers[i].Thickness]);
    grdLayers.Cells[3, Row] := Format('%.2f', [Structure.Layers[i].Roughness]);
    grdLayers.Cells[4, Row] := Format('%.2f', [Structure.Layers[i].Density]);
  end;

  // Substrate row
  Row := Length(Structure.Layers) + 1;
  grdLayers.Cells[0, Row] := 'Sub';
  grdLayers.Cells[1, Row] := Structure.Substrate.Material;
  grdLayers.Cells[2, Row] := '--';
  grdLayers.Cells[3, Row] := Format('%.2f', [Structure.Substrate.Roughness]);
  grdLayers.Cells[4, Row] := Format('%.2f', [Structure.Substrate.Density]);

  // Summary labels
  lblType.Caption := 'Type: ' + Summary.StructureType;
  lblPeriod.Caption := Format('d = %.2f A', [Summary.D]);
  lblGamma.Caption := Format('gamma = %.3f', [Summary.Gamma]);
  lblN.Caption := Format('N = %d', [Summary.N]);
end;

procedure TframeStructureView.Clear;
var
  c, r: Integer;
begin
  for c := 0 to grdLayers.ColCount - 1 do
    for r := 0 to grdLayers.RowCount - 1 do
      grdLayers.Cells[c, r] := '';
  lblType.Caption := '';
  lblPeriod.Caption := '';
  lblGamma.Caption := '';
  lblN.Caption := '';
end;

end.
```

- [ ] **Step 2: Implement frame_InfoView**

A TFrame with TLabels or a TMemo displaying manifest metadata.

```pascal
unit frame_InfoView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.StdCtrls, Vcl.ExtCtrls,
  unit_xrfx_package;

type
  TframeInfoView = class(TFrame)
    mmoInfo: TMemo;
  public
    procedure LoadManifestInfo(const M: TXRFXManifest);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeInfoView.LoadManifestInfo(const M: TXRFXManifest);
var
  i: Integer;
begin
  mmoInfo.Lines.Clear;
  mmoInfo.Lines.Add('Figure of Merit: ' + Format('%.6f', [M.FoM]));
  mmoInfo.Lines.Add('Created: ' + M.Created);
  mmoInfo.Lines.Add('Generator: ' + M.Generator);
  mmoInfo.Lines.Add('Substrate: ' + M.Substrate);
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Structure ---');
  mmoInfo.Lines.Add('Type: ' + M.Structure.StructureType);
  mmoInfo.Lines.Add(Format('d = %.2f A', [M.Structure.D]));
  mmoInfo.Lines.Add(Format('gamma = %.3f', [M.Structure.Gamma]));
  mmoInfo.Lines.Add(Format('N = %d', [M.Structure.N]));
  mmoInfo.Lines.Add(Format('sigma = %.2f A', [M.Structure.Sigma]));
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Target Lines ---');
  for i := 0 to High(M.TargetLines) do
    mmoInfo.Lines.Add('  ' + M.TargetLines[i]);
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Element Pool ---');
  for i := 0 to High(M.ElementPool) do
    mmoInfo.Lines.Add('  ' + M.ElementPool[i]);
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Optimizer ---');
  mmoInfo.Lines.Add(Format('Population: %d', [M.Optimizer.Population]));
  mmoInfo.Lines.Add(Format('Iterations: %d', [M.Optimizer.Iterations]));
  mmoInfo.Lines.Add(Format('Stagnation limit: %d', [M.Optimizer.StagnationLimit]));
  mmoInfo.Lines.Add('');
  mmoInfo.Lines.Add('--- Per-Element Results ---');
  for i := 0 to High(M.PerElement) do
    mmoInfo.Lines.Add(Format('  %s: peak R = %.4f, FWHM = %.3f',
      [M.PerElement[i].Line, M.PerElement[i].PeakR, M.PerElement[i].FWHM]));
end;

procedure TframeInfoView.Clear;
begin
  mmoInfo.Lines.Clear;
end;

end.
```

- [ ] **Step 3: Create DFM files for both frames, add to project, build**

- [ ] **Step 4: Commit**

```
git add XRFView/Views/frame_StructureView.* XRFView/Views/frame_InfoView.*
git commit -m "+ Add Structure and Info view frames for XRFView"
```

---

### Task 11: View frames — Curves and Progress

**Files:**
- Create: `XRFView/Views/frame_CurvesView.pas` + `.dfm`
- Create: `XRFView/Views/frame_ProgressView.pas` + `.dfm`

- [ ] **Step 1: Implement frame_CurvesView**

TFrame with a TChart. One TLineSeries per element, log Y-axis.

```pascal
unit frame_CurvesView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.CheckLst,
  unit_xrfx_package;

type
  TframeCurvesView = class(TFrame)
    chrtCurves: TChart;
    pnlLegend: TPanel;
    clbElements: TCheckListBox;
    procedure clbElementsClickCheck(Sender: TObject);
  public
    procedure LoadCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string = '');
    procedure AddCurves(const Curves: TArray<TXRFXCurveData>;
      const FileLabel: string);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeCurvesView.LoadCurves(const Curves: TArray<TXRFXCurveData>;
  const FileLabel: string);
begin
  Clear;
  AddCurves(Curves, FileLabel);
end;

procedure TframeCurvesView.AddCurves(const Curves: TArray<TXRFXCurveData>;
  const FileLabel: string);
var
  i, j: Integer;
  Series: TLineSeries;
  Title: string;
begin
  for i := 0 to High(Curves) do
  begin
    Series := TLineSeries.Create(chrtCurves);
    if FileLabel <> '' then
      Title := FileLabel + ' / ' + Curves[i].Element
    else
      Title := Curves[i].Element;
    Series.Title := Title;

    for j := 0 to High(Curves[i].Theta) do
      Series.AddXY(Curves[i].Theta[j], Curves[i].Refl[j]);

    chrtCurves.AddSeries(Series);
    clbElements.Items.Add(Title);
    clbElements.Checked[clbElements.Count - 1] := True;
  end;

  chrtCurves.LeftAxis.Logarithmic := True;
  chrtCurves.BottomAxis.Title.Caption := 'Theta (degrees)';
  chrtCurves.LeftAxis.Title.Caption := 'Reflectivity';
end;

procedure TframeCurvesView.Clear;
begin
  chrtCurves.FreeAllSeries;
  clbElements.Clear;
end;

procedure TframeCurvesView.clbElementsClickCheck(Sender: TObject);
var
  i: Integer;
begin
  for i := 0 to clbElements.Count - 1 do
    if i < chrtCurves.SeriesCount then
      chrtCurves.Series[i].Active := clbElements.Checked[i];
end;

end.
```

- [ ] **Step 2: Implement frame_ProgressView**

TFrame with a TChart showing FoM vs iteration.

```pascal
unit frame_ProgressView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeeProcs,
  unit_xrfx_package;

type
  TframeProgressView = class(TFrame)
    chrtProgress: TChart;
  public
    procedure LoadProgress(const Entries: TArray<TProgressEntry>);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeProgressView.LoadProgress(const Entries: TArray<TProgressEntry>);
var
  Series: TLineSeries;
  i: Integer;
begin
  Clear;
  Series := TLineSeries.Create(chrtProgress);
  Series.Title := 'FoM';

  for i := 0 to High(Entries) do
    Series.AddXY(Entries[i].Iteration, Entries[i].FoM);

  chrtProgress.AddSeries(Series);
  chrtProgress.LeftAxis.Logarithmic := True;
  chrtProgress.BottomAxis.Title.Caption := 'Iteration';
  chrtProgress.LeftAxis.Title.Caption := 'Figure of Merit';
end;

procedure TframeProgressView.Clear;
begin
  chrtProgress.FreeAllSeries;
end;

end.
```

- [ ] **Step 3: Create DFM files, add to project, build**

Key DFM properties:
- `frame_CurvesView.dfm`: TChart aligned `alClient`, TPanel with TCheckListBox aligned `alRight` (width ~150)
- `frame_ProgressView.dfm`: TChart aligned `alClient`

- [ ] **Step 4: Commit**

```
git add XRFView/Views/frame_CurvesView.* XRFView/Views/frame_ProgressView.*
git commit -m "+ Add Curves and Progress view frames for XRFView"
```

---

### Task 12: Wire frames into main form

**Files:**
- Modify: `XRFView/Forms/frm_XRFViewMain.pas` — create frames, populate from loader

- [ ] **Step 1: Add frame fields and creation**

In `frm_XRFViewMain.pas`, add private fields:

```pascal
  private
    FLoader: TXRFViewLoader;
    FStructureView: TframeStructureView;
    FCurvesView: TframeCurvesView;
    FInfoView: TframeInfoView;
    FProgressView: TframeProgressView;
```

In `FormCreate`, create and parent each frame to its tab:

```pascal
  FStructureView := TframeStructureView.Create(Self);
  FStructureView.Parent := tabStructure;
  FStructureView.Align := alClient;

  FCurvesView := TframeCurvesView.Create(Self);
  FCurvesView.Parent := tabCurves;
  FCurvesView.Align := alClient;

  FInfoView := TframeInfoView.Create(Self);
  FInfoView.Parent := tabInfo;
  FInfoView.Align := alClient;

  FProgressView := TframeProgressView.Create(Self);
  FProgressView.Parent := tabProgress;
  FProgressView.Align := alClient;
```

- [ ] **Step 2: Populate frames in ProcessFile**

```pascal
procedure TfrmXRFViewMain.ProcessFile(const FileName: string);
begin
  FLoader.LoadFile(FileName);

  FStructureView.LoadStructure(FLoader.GetResult(0).Structure,
    FLoader.Manifest.Structure);
  FCurvesView.LoadCurves(FLoader.GetResult(0).Curves);
  FInfoView.LoadManifestInfo(FLoader.Manifest);
  FProgressView.LoadProgress(FLoader.GetResult(0).Progress);

  tabCompare.TabVisible := False;
  RzStatusBar1.SimpleText := Format('FoM: %.6f  |  %s',
    [FLoader.Manifest.FoM, ExtractFileName(FileName)]);
end;
```

- [ ] **Step 3: Implement Copy Data and Save Image buttons**

```pascal
procedure TfrmXRFViewMain.btnCopyDataClick(Sender: TObject);
var
  Lines: TStringList;
  i, j: Integer;
  R: TLoadedResult;
begin
  if not FLoader.IsLoaded then Exit;
  R := FLoader.GetResult(0);
  Lines := TStringList.Create;
  try
    for i := 0 to High(R.Curves) do
    begin
      Lines.Add('# ' + R.Curves[i].Element);
      for j := 0 to High(R.Curves[i].Theta) do
        Lines.Add(Format('%.4f'#9'%.8e', [R.Curves[i].Theta[j], R.Curves[i].Refl[j]]));
      Lines.Add('');
    end;
    Clipboard.AsText := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TfrmXRFViewMain.btnSaveImageClick(Sender: TObject);
begin
  if dlgSaveImage.Execute then
  begin
    if PageControl1.ActivePage = tabCurves then
      FCurvesView.chrtCurves.SaveToBitmapFile(dlgSaveImage.FileName)
    else if PageControl1.ActivePage = tabProgress then
      FProgressView.chrtProgress.SaveToBitmapFile(dlgSaveImage.FileName);
  end;
end;
```

- [ ] **Step 4: Build and manually test with a sample .xrfx file**

- [ ] **Step 5: Commit**

```
git add XRFView/Forms/frm_XRFViewMain.pas XRFView/XRFView.dpr
git commit -m "+ Wire view frames into XRFView main form"
```

---

### Task 13: Comparison mode

**Files:**
- Create: `XRFView/Views/frame_CompareView.pas` + `.dfm`
- Modify: `XRFView/Forms/frm_XRFViewMain.pas` — handle multi-select

- [ ] **Step 1: Implement frame_CompareView**

TFrame with a TStringGrid showing parameters as rows, files as columns.

```pascal
unit frame_CompareView;

interface

uses
  System.SysUtils, System.Classes, Vcl.Controls, Vcl.Forms,
  Vcl.Grids,
  unit_xrfx_package;

type
  TframeCompareView = class(TFrame)
    grdCompare: TStringGrid;
  public
    procedure LoadComparison(const Manifests: TArray<TXRFXManifest>;
      const FileNames: TArray<string>);
    procedure Clear;
  end;

implementation

{$R *.dfm}

procedure TframeCompareView.LoadComparison(
  const Manifests: TArray<TXRFXManifest>;
  const FileNames: TArray<string>);
var
  Col, Row, i, j: Integer;
  BaseRows: Integer;
begin
  if Length(Manifests) = 0 then Exit;

  // Determine rows: fixed params + per-element R + per-element FWHM
  BaseRows := 6; // FoM, d, gamma, N, sigma, substrate
  // Use first manifest's per_element as row template
  grdCompare.ColCount := Length(Manifests) + 1;
  grdCompare.RowCount := BaseRows + Length(Manifests[0].PerElement) * 2 + 1;
  grdCompare.FixedCols := 1;
  grdCompare.FixedRows := 1;

  // Header row
  grdCompare.Cells[0, 0] := 'Parameter';
  for Col := 0 to High(Manifests) do
    grdCompare.Cells[Col + 1, 0] := ExtractFileName(FileNames[Col]);

  // Row labels
  grdCompare.Cells[0, 1] := 'FoM';
  grdCompare.Cells[0, 2] := 'd (A)';
  grdCompare.Cells[0, 3] := 'gamma';
  grdCompare.Cells[0, 4] := 'N';
  grdCompare.Cells[0, 5] := 'sigma (A)';
  grdCompare.Cells[0, 6] := 'Substrate';

  Row := 7;
  for j := 0 to High(Manifests[0].PerElement) do
  begin
    grdCompare.Cells[0, Row] := Manifests[0].PerElement[j].Line + ' peak R';
    Inc(Row);
    grdCompare.Cells[0, Row] := Manifests[0].PerElement[j].Line + ' FWHM';
    Inc(Row);
  end;

  // Data columns
  for Col := 0 to High(Manifests) do
  begin
    grdCompare.Cells[Col + 1, 1] := Format('%.6f', [Manifests[Col].FoM]);
    grdCompare.Cells[Col + 1, 2] := Format('%.2f', [Manifests[Col].Structure.D]);
    grdCompare.Cells[Col + 1, 3] := Format('%.3f', [Manifests[Col].Structure.Gamma]);
    grdCompare.Cells[Col + 1, 4] := IntToStr(Manifests[Col].Structure.N);
    grdCompare.Cells[Col + 1, 5] := Format('%.2f', [Manifests[Col].Structure.Sigma]);
    grdCompare.Cells[Col + 1, 6] := Manifests[Col].Substrate;

    Row := 7;
    for j := 0 to High(Manifests[Col].PerElement) do
    begin
      grdCompare.Cells[Col + 1, Row] := Format('%.4f', [Manifests[Col].PerElement[j].PeakR]);
      Inc(Row);
      grdCompare.Cells[Col + 1, Row] := Format('%.3f', [Manifests[Col].PerElement[j].FWHM]);
      Inc(Row);
    end;
  end;
end;

procedure TframeCompareView.Clear;
var
  c, r: Integer;
begin
  for c := 0 to grdCompare.ColCount - 1 do
    for r := 0 to grdCompare.RowCount - 1 do
      grdCompare.Cells[c, r] := '';
end;

end.
```

- [ ] **Step 2: Add comparison handling to main form**

In `frm_XRFViewMain.pas`, modify `ShellListSelectItem` to detect multi-select:

```pascal
procedure TfrmXRFViewMain.ShellListSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  FileName: string;
  SelectedFiles: TArray<string>;
  i: Integer;
begin
  if Item = nil then Exit;

  // Collect all selected .xrfx files
  SetLength(SelectedFiles, 0);
  for i := 0 to ShellList.Items.Count - 1 do
  begin
    if ShellList.Items[i].Selected then
    begin
      FileName := IncludeTrailingPathDelimiter(ShellList.Path) +
        ShellList.Items[i].Caption;
      if SameText(ExtractFileExt(FileName), XRFX_EXT) and
         TFile.Exists(FileName) then
      begin
        SetLength(SelectedFiles, Length(SelectedFiles) + 1);
        SelectedFiles[High(SelectedFiles)] := FileName;
      end;
    end;
  end;

  if Length(SelectedFiles) = 0 then Exit;

  try
    Screen.Cursor := crHourGlass;
    if Length(SelectedFiles) = 1 then
      ProcessFile(SelectedFiles[0])
    else
      ProcessMultipleFiles(SelectedFiles);
  finally
    Screen.Cursor := crDefault;
  end;
end;
```

Add `ProcessMultipleFiles`:

```pascal
procedure TfrmXRFViewMain.ProcessMultipleFiles(const FileNames: TArray<string>);
var
  Manifests: TArray<TXRFXManifest>;
  i: Integer;
begin
  FLoader.LoadMultiple(FileNames);

  // Structure/Info/Progress show first file
  FStructureView.LoadStructure(FLoader.GetResult(0).Structure,
    FLoader.Manifest.Structure);
  FInfoView.LoadManifestInfo(FLoader.Manifest);
  FProgressView.LoadProgress(FLoader.GetResult(0).Progress);

  // Curves: overlay all files
  FCurvesView.Clear;
  for i := 0 to FLoader.ResultCount - 1 do
    FCurvesView.AddCurves(FLoader.GetResult(i).Curves,
      ExtractFileName(FLoader.GetResult(i).FileName));

  // Comparison grid
  SetLength(Manifests, FLoader.ResultCount);
  for i := 0 to FLoader.ResultCount - 1 do
    Manifests[i] := FLoader.GetResult(i).Manifest;

  FCompareView.LoadComparison(Manifests, FileNames);
  tabCompare.TabVisible := True;

  RzStatusBar1.SimpleText := Format('%d files compared', [FLoader.ResultCount]);
end;
```

- [ ] **Step 3: Add FCompareView field and creation in FormCreate**

```pascal
  FCompareView := TframeCompareView.Create(Self);
  FCompareView.Parent := tabCompare;
  FCompareView.Align := alClient;
```

- [ ] **Step 4: Enable multi-select on ShellList**

In the DFM, set `ShellList.MultiSelect := True`.

- [ ] **Step 5: Build and manually test comparison mode**

- [ ] **Step 6: Commit**

```
git add XRFView/Views/frame_CompareView.* XRFView/Forms/frm_XRFViewMain.*
git commit -m "+ Add comparison mode with multi-file overlay and parameter grid"
```

---

### Task 14: Final integration and cleanup

**Files:**
- Modify: `XRFView/XRFView.dpr` — ensure all units listed
- Modify: `XRC3.groupproj` — verify build order

- [ ] **Step 1: Verify XRFView.dpr has all units**

```pascal
program XRFView;

uses
  Vcl.Forms,
  frm_XRFViewMain in 'Forms\frm_XRFViewMain.pas' {frmXRFViewMain},
  frame_StructureView in 'Views\frame_StructureView.pas' {frameStructureView: TFrame},
  frame_CurvesView in 'Views\frame_CurvesView.pas' {frameCurvesView: TFrame},
  frame_InfoView in 'Views\frame_InfoView.pas' {frameInfoView: TFrame},
  frame_ProgressView in 'Views\frame_ProgressView.pas' {frameProgressView: TFrame},
  frame_CompareView in 'Views\frame_CompareView.pas' {frameCompareView: TFrame},
  xrfview_unit_loader in 'Units\xrfview_unit_loader.pas',
  unit_xrfx_package in '..\Universal\unit_xrfx_package.pas',
  unit_universal_types in '..\Universal\unit_universal_types.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.Title := 'XRFView';
  Application.CreateForm(TfrmXRFViewMain, frmXRFViewMain);
  Application.Run;
end.
```

- [ ] **Step 2: Build all — tests, xrccmd, XRFView**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRC_CMD\xrccmd.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFView\XRFView.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

- [ ] **Step 3: Run all tests, verify all pass**

- [ ] **Step 4: Final commit**

```
git add -A
git commit -m "+ Complete .xrfx package format and XRFView application"
```

---

## Summary

| Chunk | Tasks | What it delivers |
|-------|-------|-----------------|
| 1 | 1–6 | `unit_xrfx_package.pas` — create, extract, load .xrfx archives. Full test coverage. |
| 2 | 7 | xrccmd generates `.xrfx` after universal optimization completes |
| 3 | 8–14 | Standalone XRFView app — browse, inspect, compare .xrfx files |

**Task dependencies:** Chunk 1 must complete before Chunks 2 and 3. Chunks 2 and 3 are independent of each other.

---

## Implementation Notes

Items for the implementer to handle during execution:

1. **DFM files must be created** — The plan provides `.pas` code but not `.dfm` content. For the main form (`frm_XRFViewMain.dfm`), create it in the IDE using TriboViewer's `frm_Main.dfm` as a reference template. For simpler frames (StructureView, InfoView, CurvesView, ProgressView, CompareView), minimal DFMs can be written as text.

2. **XRFView.dproj must be created** — Use the IDE to create the project file, or copy and adapt an existing `.dproj` (e.g., from XRFCalc). Set output directory to `XRFView\_Out\BIN\`, DCU output to `XRFView\_Out\DCU64\`, and add `..\..\Universal` to the unit search path.

3. **`ProcessMultipleFiles` declaration** — Add to the `private` section of `TfrmXRFViewMain` class declaration alongside `ProcessFile`.

4. **"Extract all" export** — Spec calls for a button to unzip entire .xrfx to a chosen folder. Add a toolbar button that calls `ExtractXRFXPackage(CurrentFile, UserChosenDir)` via a `TSaveDialog` or `TBrowseForFolder`.

5. **Status bar warnings** — When loading a .xrfx, if files referenced in `manifest.files` are missing from the archive, show a warning in the status bar and disable the corresponding tabs.

6. **Error handling** — Add try/except in `ProcessFile` for malformed JSON, missing manifest, and corrupt ZIP files per the spec's error handling section.

7. **`TStringDynArray` usage** — `System.Types` is now in the uses clause. Alternatively, replace `TStringDynArray` with `TArray<string>` for consistency.
