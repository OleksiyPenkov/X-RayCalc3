# XRF Emission Lines Lookup Table — Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Rename "Targets" to "Lines" throughout the XRF codebase to avoid confusion with sputtering targets. Replace hardcoded element-to-wavelength mappings with a comprehensive lookup table (Li–U) and support simplified line notation in config files.

**Architecture:** New `unit_xrf_lines.pas` embeds a const array of 90 elements with their characteristic emission wavelengths. Config loading in `unit_universal_io.pas` is updated to accept strings, ranges, and objects. The `TTargetElement` record is renamed to `TXRFLine` and `Config.Targets` becomes `Config.Lines`. All formats resolve to `{Name, Lambda, Weight}` at load time.

**Tech Stack:** Delphi Object Pascal, DUnitX test framework

---

## File Structure

| Action | File | Responsibility |
|--------|------|---------------|
| Modify | `Universal/unit_universal_types.pas` | Rename `TTargetElement`→`TXRFLine`, `Targets`→`Lines`, `MAX_TARGETS`→`MAX_LINES` |
| Modify | `Universal/unit_universal_io.pas` | Rename field refs, JSON key `"targets"`→`"lines"` (read both), mixed array parsing |
| Modify | `Universal/unit_universal_fitness.pas` | Rename `Config.Targets`→`Config.Lines` |
| Modify | `Universal/unit_universal_optimizer.pas` | Rename `Config.Targets`→`Config.Lines` |
| Modify | `Universal/unit_universal_pso.pas` | Rename `Config.Targets`→`Config.Lines` |
| Modify | `XRC_CMD/units/cmd_unit_universal.pas` | Rename `Config.Targets`→`Config.Lines` |
| Modify | `XRFCalc/frm_XRFMain.pas` | Rename refs, remove `KAlphaData`, use `GetXRFLambda` |
| Modify | `XRFCalc/frm_XRFMain.dfm` | Update `clbTargets` items, `sgWeights` row count, group caption |
| Modify | `UniversalMirror/*.json` (6 files) | JSON key `"targets"`→`"lines"`, simplify to element names/ranges |
| Create | `Universal/unit_xrf_lines.pas` | Const data table + lookup functions |
| Create | `Universal/xrf_lines.json` | Canonical reference data (not used at runtime) |
| Create | `Tests/TestXRFLines.pas` | Unit tests for lookup, range expansion, config loading |
| Modify | `Tests/XRayCalc3Tests.dpr` | Register new test unit and Universal/ dependencies |

---

## Chunk 1: Rename Targets → Lines

### Task 0: Rename types and config field

This is a mechanical rename across the codebase. `TTargetElement`→`TXRFLine`, `Config.Targets`→`Config.Lines`, `MAX_TARGETS`→`MAX_LINES`. The `TTargetResult`/`TTargetResults` types and `TargetResults` field stay unchanged — they describe evaluation results, not config entries.

**Files:**
- Modify: `Universal/unit_universal_types.pas`
- Modify: `Universal/unit_universal_io.pas`
- Modify: `Universal/unit_universal_fitness.pas`
- Modify: `Universal/unit_universal_optimizer.pas`
- Modify: `Universal/unit_universal_pso.pas`
- Modify: `XRC_CMD/units/cmd_unit_universal.pas`
- Modify: `XRFCalc/frm_XRFMain.pas`

- [ ] **Step 1: Rename in `unit_universal_types.pas`**

Three changes:

```pascal
// Line 10: MAX_TARGETS → MAX_LINES
MAX_LINES = 16;

// Lines 28-32: TTargetElement → TXRFLine
TXRFLine = record
  Name: string;
  Lambda: Single;       // characteristic wavelength in Angstroms
  Weight: Single;       // relative weight in FoM
end;

// Line 162: Targets field → Lines field
Lines: array of TXRFLine;
```

- [ ] **Step 2: Rename in `unit_universal_io.pas`**

In `LoadConfig` (lines 87-95), rename `Result.Targets` → `Result.Lines` and change JSON key to accept both `"lines"` and `"targets"` for backward compat:

```pascal
    // Try "lines" first, fall back to "targets" for backward compatibility
    if JSON.FindValue('lines') <> nil then
      JTargets := JSON.GetValue<TJSONArray>('lines')
    else
      JTargets := JSON.GetValue<TJSONArray>('targets');
    SetLength(Result.Lines, JTargets.Count);
    for i := 0 to JTargets.Count - 1 do
    begin
      JTarget := JTargets.Items[i] as TJSONObject;
      Result.Lines[i].Name := JTarget.GetValue<string>('element');
      Result.Lines[i].Lambda := JTarget.GetValue<Double>('lambda');
      Result.Lines[i].Weight := JTarget.GetValue<Double>('weight');
    end;
```

In `SaveConfig` (lines 220-230), rename `Config.Targets` → `Config.Lines` and write JSON key as `"lines"`:

```pascal
    // Lines
    JTargets := TJSONArray.Create;
    for i := 0 to High(Config.Lines) do
    begin
      JTarget := TJSONObject.Create;
      JTarget.AddPair('element', Config.Lines[i].Name);
      JTarget.AddPair('lambda', TJSONNumber.Create(Config.Lines[i].Lambda));
      JTarget.AddPair('weight', TJSONNumber.Create(Config.Lines[i].Weight));
      JTargets.Add(JTarget);
    end;
    JSON.AddPair('lines', JTargets);
```

In `SaveBestStructure` (lines 426-433), rename `Config.Targets` → `Config.Lines`:

```pascal
    for i := 0 to High(Config.Lines) do
    begin
      ...
      JPerElem.AddPair(Config.Lines[i].Name, JElem);
    end;
```

- [ ] **Step 3: Rename in `unit_universal_fitness.pas`**

Replace all `FConfig.Targets` → `FConfig.Lines` (5 occurrences at lines 59, 384, 408, 453, 457, 476, 485):

```
FConfig.Targets[i].Lambda  →  FConfig.Lines[i].Lambda
FConfig.Targets[i].Weight  →  FConfig.Lines[i].Weight
Length(AConfig.Targets)     →  Length(AConfig.Lines)
```

- [ ] **Step 4: Rename in `unit_universal_pso.pas`**

Replace `FConfig.Targets` → `FConfig.Lines` (2 occurrences at lines 229, 642):

```
Length(FConfig.Targets)  →  Length(FConfig.Lines)
```

- [ ] **Step 5: Rename in `unit_universal_optimizer.pas`**

Replace all `FConfig.Targets` → `FConfig.Lines` (~12 occurrences at lines 112-115, 139-144, 249, 315-321):

```
Length(FConfig.Targets)       →  Length(FConfig.Lines)
FConfig.Targets[i].Name      →  FConfig.Lines[i].Name
FConfig.Targets[i].Lambda    →  FConfig.Lines[i].Lambda
```

- [ ] **Step 6: Rename in `cmd_unit_universal.pas`**

Replace `Config.Targets` → `Config.Lines` (4 occurrences at lines 112-113, 137-138):

```
High(Config.Targets)       →  High(Config.Lines)
Config.Targets[i].Name     →  Config.Lines[i].Name
Config.Targets[i].Lambda   →  Config.Lines[i].Lambda
```

- [ ] **Step 7: Rename in `frm_XRFMain.pas`**

Replace `Config.Targets` → `Config.Lines` throughout (~12 occurrences). Also rename:
- `FXrccmdTargetNames` → `FXrccmdLineNames` (field declaration at line 143, and usages at lines 630-632, 713-714, 727-728)
- Error message at line 190: `'No target elements selected.'` → `'No XRF lines selected.'`
- `Result.Targets` → `Result.Lines` in `CollectConfigFromUI`
- Local var `TargetLambdas` → `LineLambdas` in `btnExportXRCClick` (lines 1077, 1091-1093)

- [ ] **Step 8: Build Win64 and run all tests**

Build XRFCalc:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Build and run tests:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All existing tests pass. No functional change — just a rename.

- [ ] **Step 9: Commit**

```
git add Universal/unit_universal_types.pas Universal/unit_universal_io.pas Universal/unit_universal_fitness.pas Universal/unit_universal_optimizer.pas Universal/unit_universal_pso.pas XRC_CMD/units/cmd_unit_universal.pas XRFCalc/frm_XRFMain.pas
git commit -m "* Rename Targets → Lines in XRF config types (avoid confusion with sputtering targets)"
```

---

### Task 1: Rename JSON key in config files

**Files:**
- Modify: `UniversalMirror/test_mosi_template.json`
- Modify: `UniversalMirror/test_mosi_no_template.json`
- Modify: `UniversalMirror/mirror_AL_C.json`
- Modify: `UniversalMirror/test_config.json`
- Modify: `UniversalMirror/test_resume_config.json`
- Modify: `UniversalMirror/universal_mirror.json`

- [ ] **Step 1: In each JSON file, rename `"targets":` → `"lines":`**

This is a one-line change per file. Example for `test_mosi_template.json`:

```json
// Before:
"targets": [
// After:
"lines": [
```

- [ ] **Step 2: Verify configs load correctly**

Build and run XRFCalc, load a config file via the UI to verify it parses the `"lines"` key.

- [ ] **Step 3: Commit**

```
git add UniversalMirror/*.json
git commit -m "* Rename JSON key 'targets' → 'lines' in config files"
```

---

## Chunk 2: Core Data and Lookup Unit

### Task 2: Create `unit_xrf_lines.pas` with const data table

**Files:**
- Create: `Universal/unit_xrf_lines.pas`

- [ ] **Step 1: Create the unit with const array and public interface**

```pascal
unit unit_xrf_lines;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TXRFLineRec = record
    Symbol: string;
    Z: Byte;
    Lambda: Double;  // Angstroms
  end;

function GetXRFLambda(const Element: string): Double;
function ExpandElementRange(const RangeStr: string): TArray<string>;
function GetAllElements: TArray<string>;

implementation

const
  XRF_LINE_COUNT = 90;
  XRFLines: array[0..XRF_LINE_COUNT-1] of TXRFLineRec = (
    // Ka lines: Z=3 (Li) through Z=55 (Cs)
    // lambda = 12398.419 / E(eV), using weighted-average Ka
    (Symbol: 'Li'; Z: 3;  Lambda: 228.0),
    (Symbol: 'Be'; Z: 4;  Lambda: 114.0),
    (Symbol: 'B';  Z: 5;  Lambda: 67.6),
    (Symbol: 'C';  Z: 6;  Lambda: 44.7),
    (Symbol: 'N';  Z: 7;  Lambda: 31.6),
    (Symbol: 'O';  Z: 8;  Lambda: 23.62),
    (Symbol: 'F';  Z: 9;  Lambda: 18.32),
    (Symbol: 'Ne'; Z: 10; Lambda: 14.61),
    (Symbol: 'Na'; Z: 11; Lambda: 11.91),
    (Symbol: 'Mg'; Z: 12; Lambda: 9.890),
    (Symbol: 'Al'; Z: 13; Lambda: 8.339),
    (Symbol: 'Si'; Z: 14; Lambda: 7.126),
    (Symbol: 'P';  Z: 15; Lambda: 6.158),
    (Symbol: 'S';  Z: 16; Lambda: 5.373),
    (Symbol: 'Cl'; Z: 17; Lambda: 4.729),
    (Symbol: 'Ar'; Z: 18; Lambda: 4.194),
    (Symbol: 'K';  Z: 19; Lambda: 3.742),
    (Symbol: 'Ca'; Z: 20; Lambda: 3.359),
    (Symbol: 'Sc'; Z: 21; Lambda: 3.032),
    (Symbol: 'Ti'; Z: 22; Lambda: 2.749),
    (Symbol: 'V';  Z: 23; Lambda: 2.504),
    (Symbol: 'Cr'; Z: 24; Lambda: 2.291),
    (Symbol: 'Mn'; Z: 25; Lambda: 2.103),
    (Symbol: 'Fe'; Z: 26; Lambda: 1.937),
    (Symbol: 'Co'; Z: 27; Lambda: 1.790),
    (Symbol: 'Ni'; Z: 28; Lambda: 1.659),
    (Symbol: 'Cu'; Z: 29; Lambda: 1.542),
    (Symbol: 'Zn'; Z: 30; Lambda: 1.436),
    (Symbol: 'Ga'; Z: 31; Lambda: 1.340),
    (Symbol: 'Ge'; Z: 32; Lambda: 1.254),
    (Symbol: 'As'; Z: 33; Lambda: 1.177),
    (Symbol: 'Se'; Z: 34; Lambda: 1.106),
    (Symbol: 'Br'; Z: 35; Lambda: 1.041),
    (Symbol: 'Kr'; Z: 36; Lambda: 0.9801),
    (Symbol: 'Rb'; Z: 37; Lambda: 0.9256),
    (Symbol: 'Sr'; Z: 38; Lambda: 0.8753),
    (Symbol: 'Y';  Z: 39; Lambda: 0.8288),
    (Symbol: 'Zr'; Z: 40; Lambda: 0.7859),
    (Symbol: 'Nb'; Z: 41; Lambda: 0.7462),
    (Symbol: 'Mo'; Z: 42; Lambda: 0.7093),
    (Symbol: 'Tc'; Z: 43; Lambda: 0.6749),
    (Symbol: 'Ru'; Z: 44; Lambda: 0.6428),
    (Symbol: 'Rh'; Z: 45; Lambda: 0.6132),
    (Symbol: 'Pd'; Z: 46; Lambda: 0.5854),
    (Symbol: 'Ag'; Z: 47; Lambda: 0.5594),
    (Symbol: 'Cd'; Z: 48; Lambda: 0.5348),
    (Symbol: 'In'; Z: 49; Lambda: 0.5118),
    (Symbol: 'Sn'; Z: 50; Lambda: 0.4900),
    (Symbol: 'Sb'; Z: 51; Lambda: 0.4695),
    (Symbol: 'Te'; Z: 52; Lambda: 0.4500),
    (Symbol: 'I';  Z: 53; Lambda: 0.4314),
    (Symbol: 'Xe'; Z: 54; Lambda: 0.4138),
    (Symbol: 'Cs'; Z: 55; Lambda: 0.3972),
    // La lines: Z=56 (Ba) through Z=92 (U)
    (Symbol: 'Ba'; Z: 56; Lambda: 2.776),
    (Symbol: 'La'; Z: 57; Lambda: 2.666),
    (Symbol: 'Ce'; Z: 58; Lambda: 2.562),
    (Symbol: 'Pr'; Z: 59; Lambda: 2.463),
    (Symbol: 'Nd'; Z: 60; Lambda: 2.370),
    (Symbol: 'Pm'; Z: 61; Lambda: 2.282),
    (Symbol: 'Sm'; Z: 62; Lambda: 2.200),
    (Symbol: 'Eu'; Z: 63; Lambda: 2.121),
    (Symbol: 'Gd'; Z: 64; Lambda: 2.047),
    (Symbol: 'Tb'; Z: 65; Lambda: 1.977),
    (Symbol: 'Dy'; Z: 66; Lambda: 1.909),
    (Symbol: 'Ho'; Z: 67; Lambda: 1.845),
    (Symbol: 'Er'; Z: 68; Lambda: 1.784),
    (Symbol: 'Tm'; Z: 69; Lambda: 1.727),
    (Symbol: 'Yb'; Z: 70; Lambda: 1.672),
    (Symbol: 'Lu'; Z: 71; Lambda: 1.620),
    (Symbol: 'Hf'; Z: 72; Lambda: 1.570),
    (Symbol: 'Ta'; Z: 73; Lambda: 1.522),
    (Symbol: 'W';  Z: 74; Lambda: 1.476),
    (Symbol: 'Re'; Z: 75; Lambda: 1.433),
    (Symbol: 'Os'; Z: 76; Lambda: 1.391),
    (Symbol: 'Ir'; Z: 77; Lambda: 1.351),
    (Symbol: 'Pt'; Z: 78; Lambda: 1.313),
    (Symbol: 'Au'; Z: 79; Lambda: 1.277),
    (Symbol: 'Hg'; Z: 80; Lambda: 1.241),
    (Symbol: 'Tl'; Z: 81; Lambda: 1.207),
    (Symbol: 'Pb'; Z: 82; Lambda: 1.175),
    (Symbol: 'Bi'; Z: 83; Lambda: 1.144),
    (Symbol: 'Po'; Z: 84; Lambda: 1.114),
    (Symbol: 'At'; Z: 85; Lambda: 1.085),
    (Symbol: 'Rn'; Z: 86; Lambda: 1.057),
    (Symbol: 'Fr'; Z: 87; Lambda: 1.031),
    (Symbol: 'Ra'; Z: 88; Lambda: 1.005),
    (Symbol: 'Ac'; Z: 89; Lambda: 0.9808),
    (Symbol: 'Th'; Z: 90; Lambda: 0.9573),
    (Symbol: 'Pa'; Z: 91; Lambda: 0.9348),
    (Symbol: 'U';  Z: 92; Lambda: 0.9131)
  );

var
  FIndex: TDictionary<string, Integer>;

procedure EnsureIndex;
var
  i: Integer;
begin
  if FIndex <> nil then Exit;
  FIndex := TDictionary<string, Integer>.Create(XRF_LINE_COUNT);
  for i := 0 to XRF_LINE_COUNT - 1 do
    FIndex.Add(UpperCase(XRFLines[i].Symbol), i);
end;

function GetXRFLambda(const Element: string): Double;
var
  Idx: Integer;
begin
  EnsureIndex;
  if not FIndex.TryGetValue(UpperCase(Trim(Element)), Idx) then
    raise EArgumentException.CreateFmt('Unknown element: "%s"', [Element]);
  Result := XRFLines[Idx].Lambda;
end;

function FindElementIndex(const Element: string): Integer;
begin
  EnsureIndex;
  if not FIndex.TryGetValue(UpperCase(Trim(Element)), Result) then
    raise EArgumentException.CreateFmt('Unknown element: "%s"', [Element]);
end;

function ExpandElementRange(const RangeStr: string): TArray<string>;
var
  Parts: TArray<string>;
  IdxFrom, IdxTo, Temp, i, Count: Integer;
begin
  Parts := RangeStr.Split(['-']);
  if Length(Parts) <> 2 then
    raise EArgumentException.CreateFmt('Invalid range format: "%s"', [RangeStr]);

  IdxFrom := FindElementIndex(Trim(Parts[0]));
  IdxTo := FindElementIndex(Trim(Parts[1]));

  // Silently reverse if needed
  if IdxFrom > IdxTo then
  begin
    Temp := IdxFrom;
    IdxFrom := IdxTo;
    IdxTo := Temp;
  end;

  Count := IdxTo - IdxFrom + 1;
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := XRFLines[IdxFrom + i].Symbol;
end;

function GetAllElements: TArray<string>;
var
  i: Integer;
begin
  SetLength(Result, XRF_LINE_COUNT);
  for i := 0 to XRF_LINE_COUNT - 1 do
    Result[i] := XRFLines[i].Symbol;
end;

initialization

finalization
  FIndex.Free;

end.
```

- [ ] **Step 2: Commit**

```
git add Universal/unit_xrf_lines.pas
git commit -m "+ Add unit_xrf_lines with emission line lookup table (Li-U)"
```

---

### Task 3: Create the reference JSON file

**Files:**
- Create: `Universal/xrf_lines.json`

- [ ] **Step 1: Generate the JSON from the const array data**

Create `Universal/xrf_lines.json` with the same data as the const array, structured as:

```json
{
  "description": "Characteristic X-ray emission wavelengths (Angstroms). Ka for Z=3-55 (Li-Cs), La for Z=56-92 (Ba-U). Source: NIST X-ray transition energies, lambda = 12398.419 / E(eV).",
  "lines": {
    "Li": {"Z": 3,  "lambda": 228.0,  "line": "Ka"},
    "Be": {"Z": 4,  "lambda": 114.0,  "line": "Ka"},
    ...all 90 elements...
    "U":  {"Z": 92, "lambda": 0.9131, "line": "La"}
  }
}
```

This file is the canonical reference only — not loaded at runtime.

- [ ] **Step 2: Commit**

```
git add Universal/xrf_lines.json
git commit -m "+ Add xrf_lines.json reference data (Li-U emission wavelengths)"
```

---

### Task 4: Write tests for `unit_xrf_lines`

**Files:**
- Create: `Tests/TestXRFLines.pas`
- Modify: `Tests/XRayCalc3Tests.dpr`

- [ ] **Step 1: Write the test unit**

```pascal
unit TestXRFLines;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestXRFLines = class
  public
    [Test] procedure Test_GetLambda_KnownElements;
    [Test] procedure Test_GetLambda_CaseInsensitive;
    [Test] procedure Test_GetLambda_UnknownRaises;
    [Test] procedure Test_ExpandRange_Normal;
    [Test] procedure Test_ExpandRange_SingleElement;
    [Test] procedure Test_ExpandRange_Reversed;
    [Test] procedure Test_ExpandRange_InvalidEndpoint;
    [Test] procedure Test_ExpandRange_CrossKaLa;
    [Test] procedure Test_GetAllElements_Count;
    [Test] procedure Test_GetAllElements_Order;
  end;

implementation

uses
  System.SysUtils, unit_xrf_lines;

procedure TTestXRFLines.Test_GetLambda_KnownElements;
begin
  Assert.AreEqual(67.6,   GetXRFLambda('B'),  0.01, 'B Ka');
  Assert.AreEqual(44.7,   GetXRFLambda('C'),  0.01, 'C Ka');
  Assert.AreEqual(7.126,  GetXRFLambda('Si'), 0.01, 'Si Ka');
  Assert.AreEqual(0.9131, GetXRFLambda('U'),  0.01, 'U La');
end;

procedure TTestXRFLines.Test_GetLambda_CaseInsensitive;
begin
  Assert.AreEqual(GetXRFLambda('Si'), GetXRFLambda('si'), 0.001);
  Assert.AreEqual(GetXRFLambda('Si'), GetXRFLambda('SI'), 0.001);
end;

procedure TTestXRFLines.Test_GetLambda_UnknownRaises;
begin
  Assert.WillRaise(
    procedure begin GetXRFLambda('Xx'); end,
    EArgumentException
  );
end;

procedure TTestXRFLines.Test_ExpandRange_Normal;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('B-N');
  Assert.AreEqual(3, Length(R));
  Assert.AreEqual('B', R[0]);
  Assert.AreEqual('C', R[1]);
  Assert.AreEqual('N', R[2]);
end;

procedure TTestXRFLines.Test_ExpandRange_SingleElement;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('C-C');
  Assert.AreEqual(1, Length(R));
  Assert.AreEqual('C', R[0]);
end;

procedure TTestXRFLines.Test_ExpandRange_Reversed;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('Si-B');
  Assert.AreEqual(10, Length(R));
  Assert.AreEqual('B', R[0]);
  Assert.AreEqual('Si', R[9]);
end;

procedure TTestXRFLines.Test_ExpandRange_InvalidEndpoint;
begin
  Assert.WillRaise(
    procedure begin ExpandElementRange('Xx-Si'); end,
    EArgumentException
  );
end;

procedure TTestXRFLines.Test_ExpandRange_CrossKaLa;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('Cs-Ba');
  Assert.AreEqual(2, Length(R));
  Assert.AreEqual('Cs', R[0]);
  Assert.AreEqual('Ba', R[1]);
end;

procedure TTestXRFLines.Test_GetAllElements_Count;
begin
  Assert.AreEqual(90, Length(GetAllElements));
end;

procedure TTestXRFLines.Test_GetAllElements_Order;
var
  All: TArray<string>;
begin
  All := GetAllElements;
  Assert.AreEqual('Li', All[0]);
  Assert.AreEqual('U', All[89]);
end;

end.
```

- [ ] **Step 2: Register in `XRayCalc3Tests.dpr`**

Add to the uses clause (after the `TestMaterialMix` line):

```pascal
  unit_universal_types in '..\Universal\unit_universal_types.pas',
  unit_universal_io in '..\Universal\unit_universal_io.pas',
  unit_universal_templates in '..\Universal\unit_universal_templates.pas',
  unit_xrf_lines in '..\Universal\unit_xrf_lines.pas',
  TestXRFLines in 'TestXRFLines.pas';
```

The `unit_universal_*` entries provide explicit paths so the test project can find `Universal/` units (needed by integration tests in Task 6). `unit_xrf_lines` itself only depends on `System.SysUtils` and `System.Generics.Collections`.

- [ ] **Step 3: Build and run tests**

Build:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

Run:
```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: All 10 new tests pass, all existing tests still pass.

- [ ] **Step 4: Commit**

```
git add Tests/TestXRFLines.pas Tests/XRayCalc3Tests.dpr
git commit -m "+ Add unit tests for XRF lines lookup"
```

---

## Chunk 3: Config Loading + Mixed Format

### Task 5: Update `LoadConfig` to support mixed line array

**Files:**
- Modify: `Universal/unit_universal_io.pas`

- [ ] **Step 1: Add `unit_xrf_lines` to the uses clause**

```pascal
uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.Math,
  unit_universal_types, cmd_unit_types, unit_materials_mix,
  unit_universal_templates, unit_xrf_lines;
```

- [ ] **Step 2: Replace the line parsing block in `LoadConfig`**

Replace the `JTargets` parsing loop (which was already renamed in Task 0) with:

```pascal
    // Try "lines" first, fall back to "targets" for backward compatibility
    if JSON.FindValue('lines') <> nil then
      JTargets := JSON.GetValue<TJSONArray>('lines')
    else
      JTargets := JSON.GetValue<TJSONArray>('targets');
    SetLength(Result.Lines, 0);
    for i := 0 to JTargets.Count - 1 do
    begin
      if JTargets.Items[i] is TJSONString then
      begin
        var S := JTargets.Items[i].Value;
        if Pos('-', S) > 0 then
        begin
          var Expanded := ExpandElementRange(S);
          for var j := 0 to High(Expanded) do
          begin
            SetLength(Result.Lines, Length(Result.Lines) + 1);
            Result.Lines[High(Result.Lines)].Name := Expanded[j];
            Result.Lines[High(Result.Lines)].Lambda := GetXRFLambda(Expanded[j]);
            Result.Lines[High(Result.Lines)].Weight := 1.0;
          end;
        end
        else
        begin
          SetLength(Result.Lines, Length(Result.Lines) + 1);
          Result.Lines[High(Result.Lines)].Name := S;
          Result.Lines[High(Result.Lines)].Lambda := GetXRFLambda(S);
          Result.Lines[High(Result.Lines)].Weight := 1.0;
        end;
      end
      else if JTargets.Items[i] is TJSONObject then
      begin
        JTarget := JTargets.Items[i] as TJSONObject;
        SetLength(Result.Lines, Length(Result.Lines) + 1);
        Result.Lines[High(Result.Lines)].Name := JTarget.GetValue<string>('element');
        if JTarget.FindValue('lambda') <> nil then
          Result.Lines[High(Result.Lines)].Lambda := JTarget.GetValue<Double>('lambda')
        else
          Result.Lines[High(Result.Lines)].Lambda :=
            GetXRFLambda(Result.Lines[High(Result.Lines)].Name);
        if JTarget.FindValue('weight') <> nil then
          Result.Lines[High(Result.Lines)].Weight := JTarget.GetValue<Double>('weight')
        else
          Result.Lines[High(Result.Lines)].Weight := 1.0;
      end;
    end;
```

- [ ] **Step 3: Build Win64 and run tests**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Build and run tests. All existing tests must still pass.

- [ ] **Step 4: Commit**

```
git add Universal/unit_universal_io.pas
git commit -m "+ Support mixed line array (strings, ranges, objects) in LoadConfig"
```

---

### Task 6: Add integration tests for config loading

**Files:**
- Modify: `Tests/TestXRFLines.pas`

- [ ] **Step 1: Add config-loading integration tests**

Add a new test fixture to `TestXRFLines.pas`:

```pascal
type
  [TestFixture]
  TTestConfigLines = class
  private
    FTempDir: string;
    function WriteConfig(const LinesJSON: string): string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Test_LoadConfig_LegacyFormat;
    [Test] procedure Test_LoadConfig_StringElements;
    [Test] procedure Test_LoadConfig_RangeExpansion;
    [Test] procedure Test_LoadConfig_MixedFormat;
    [Test] procedure Test_LoadConfig_ObjectNoLambda;
    [Test] procedure Test_LoadConfig_BackwardCompatTargetsKey;
  end;
```

Implementation:

```pascal
procedure TTestConfigLines.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'xrf_test_' + IntToStr(GetTickCount));
  TDirectory.CreateDirectory(FTempDir);
end;

procedure TTestConfigLines.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

function TTestConfigLines.WriteConfig(const LinesJSON: string): string;
var
  Config: string;
begin
  Result := TPath.Combine(FTempDir, 'test_config.json');
  Config :=
    '{' +
    '  "lines": ' + LinesJSON + ',' +
    '  "element_pool": ["Mo", "Si"],' +
    '  "structure": {' +
    '    "type": "bilayer", "layers_per_period": 2,' +
    '    "d": {"min": 20, "max": 80},' +
    '    "gamma": {"min": 0.2, "max": 0.6},' +
    '    "N": {"min": 20, "max": 200},' +
    '    "sigma": 3.5' +
    '  },' +
    '  "fitness": {' +
    '    "w_R": 1.0, "w_FWHM": 0.5, "R_min_threshold": 0.001,' +
    '    "polarization": "sp", "delta_theta": 0.1, "theta_min": 3.0' +
    '  },' +
    '  "optimizer": {' +
    '    "population": 50, "iterations": 10, "tolerance": 1e-6,' +
    '    "stagnation_limit": 5, "w1": 0.4, "w2": 0.5,' +
    '    "jamming_max": 3, "checkpoint_every": 100' +
    '  },' +
    '  "substrate": "SiO2",' +
    '  "henke_path": null,' +
    '  "output_dir": ".",' +
    '  "resume_from": null' +
    '}';
  TFile.WriteAllText(Result, Config);
end;

procedure TTestConfigLines.Test_LoadConfig_LegacyFormat;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig(
    '[{"element": "B", "lambda": 67.6, "weight": 1.0},' +
    ' {"element": "C", "lambda": 44.7, "weight": 2.0}]'));
  Assert.AreEqual(2, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual(67.6, Double(C.Lines[0].Lambda), 0.01);
  Assert.AreEqual(2.0, Double(C.Lines[1].Weight), 0.01);
end;

procedure TTestConfigLines.Test_LoadConfig_StringElements;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig('["B", "C", "Si"]'));
  Assert.AreEqual(3, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual(67.6, Double(C.Lines[0].Lambda), 0.01);
  Assert.AreEqual(1.0, Double(C.Lines[0].Weight), 0.01);
  Assert.AreEqual('Si', C.Lines[2].Name);
  Assert.AreEqual(7.126, Double(C.Lines[2].Lambda), 0.01);
end;

procedure TTestConfigLines.Test_LoadConfig_RangeExpansion;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig('["B-N"]'));
  Assert.AreEqual(3, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual('C', C.Lines[1].Name);
  Assert.AreEqual('N', C.Lines[2].Name);
end;

procedure TTestConfigLines.Test_LoadConfig_MixedFormat;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig(
    '["B-N", {"element": "Al", "weight": 2.0}, "Si"]'));
  Assert.AreEqual(5, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual('N', C.Lines[2].Name);
  Assert.AreEqual('Al', C.Lines[3].Name);
  Assert.AreEqual(2.0, Double(C.Lines[3].Weight), 0.01);
  Assert.AreEqual('Si', C.Lines[4].Name);
end;

procedure TTestConfigLines.Test_LoadConfig_ObjectNoLambda;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig(
    '[{"element": "Al", "weight": 3.0}]'));
  Assert.AreEqual(1, Length(C.Lines));
  Assert.AreEqual('Al', C.Lines[0].Name);
  Assert.AreEqual(8.339, Double(C.Lines[0].Lambda), 0.01);
  Assert.AreEqual(3.0, Double(C.Lines[0].Weight), 0.01);
end;

procedure TTestConfigLines.Test_LoadConfig_BackwardCompatTargetsKey;
var
  C: TUniversalConfig;
  ConfigPath, ConfigStr: string;
begin
  // Write config with old "targets" key instead of "lines"
  ConfigPath := TPath.Combine(FTempDir, 'old_config.json');
  ConfigStr :=
    '{' +
    '  "targets": ["B", "C"],' +
    '  "element_pool": ["Mo", "Si"],' +
    '  "structure": {' +
    '    "type": "bilayer", "layers_per_period": 2,' +
    '    "d": {"min": 20, "max": 80},' +
    '    "gamma": {"min": 0.2, "max": 0.6},' +
    '    "N": {"min": 20, "max": 200},' +
    '    "sigma": 3.5' +
    '  },' +
    '  "fitness": {' +
    '    "w_R": 1.0, "w_FWHM": 0.5, "R_min_threshold": 0.001,' +
    '    "polarization": "sp", "delta_theta": 0.1, "theta_min": 3.0' +
    '  },' +
    '  "optimizer": {' +
    '    "population": 50, "iterations": 10, "tolerance": 1e-6,' +
    '    "stagnation_limit": 5, "w1": 0.4, "w2": 0.5,' +
    '    "jamming_max": 3, "checkpoint_every": 100' +
    '  },' +
    '  "substrate": "SiO2",' +
    '  "henke_path": null,' +
    '  "output_dir": ".",' +
    '  "resume_from": null' +
    '}';
  TFile.WriteAllText(ConfigPath, ConfigStr);
  C := TUniversalIO.LoadConfig(ConfigPath);
  Assert.AreEqual(2, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
end;
```

Add `unit_universal_io, unit_universal_types, System.IOUtils` to the test unit's implementation uses.

- [ ] **Step 2: Build and run tests**

Build and run the test runner. All new and existing tests must pass.

- [ ] **Step 3: Commit**

```
git add Tests/TestXRFLines.pas
git commit -m "+ Add integration tests for mixed-format config loading and backward compat"
```

---

## Chunk 4: UI Changes

### Task 7: Update `frm_XRFMain` to use the lookup table

**Files:**
- Modify: `XRFCalc/frm_XRFMain.pas`
- Modify: `XRFCalc/frm_XRFMain.dfm`

- [ ] **Step 1: Add `unit_xrf_lines` to the implementation uses clause**

```pascal
uses
  System.IniFiles, System.IOUtils, System.JSON, Vcl.FileCtrl,
  unit_universal_io, cmd_unit_types, unit_materials_mix, unit_xrf_lines;
```

- [ ] **Step 2: Remove the hardcoded `KAlphaData` and `TARGET_COUNT`**

Delete the `TARGET_COUNT` const and `KAlphaData` array (lines 169-185 in the original, already partially modified by Task 0).

- [ ] **Step 3: Update `CollectConfigFromUI` to use `GetXRFLambda`**

Replace the line collection code with:

```pascal
  // Lines: collect checked items with lambda and weight
  LineIdx := 0;
  SetLength(Result.Lines, clbTargets.Count);
  for i := 0 to clbTargets.Count - 1 do
  begin
    if clbTargets.Checked[i] then
    begin
      Result.Lines[LineIdx].Name := clbTargets.Items[i];
      Result.Lines[LineIdx].Lambda := GetXRFLambda(clbTargets.Items[i]);
      Result.Lines[LineIdx].Weight := StrToFloatDef(sgWeights.Cells[1, i + 1], 1.0, FS);
      Inc(LineIdx);
    end;
  end;
  SetLength(Result.Lines, LineIdx);
```

Rename local var `TargetIdx` → `LineIdx`.

- [ ] **Step 4: Update `clbTargets` items in the DFM**

Replace the `clbTargets` Items.Strings block (B through Si) with B through Zn (Z=5..30, 26 elements):

```
            Items.Strings = (
              'B'
              'C'
              'N'
              'O'
              'F'
              'Ne'
              'Na'
              'Mg'
              'Al'
              'Si'
              'P'
              'S'
              'Cl'
              'Ar'
              'K'
              'Ca'
              'Sc'
              'Ti'
              'V'
              'Cr'
              'Mn'
              'Fe'
              'Co'
              'Ni'
              'Cu'
              'Zn')
```

Also update:
- `grpTargets` Caption: `'Targets'` → `'XRF Lines'`
- `grpTargets` Height: `180` → `280`
- `sgWeights` RowCount: `11` → `27` (1 header + 26 elements)

- [ ] **Step 5: Build Win64**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRFCalc\XRFCalc.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

- [ ] **Step 6: Run all tests**

Build and run tests. All tests must pass.

- [ ] **Step 7: Commit**

```
git add XRFCalc/frm_XRFMain.pas XRFCalc/frm_XRFMain.dfm
git commit -m "* Replace hardcoded KAlphaData with unit_xrf_lines lookup, expand line list to B-Zn"
```

---

### Task 8: Simplify existing config files

**Files:**
- Modify: `UniversalMirror/test_mosi_template.json`
- Modify: `UniversalMirror/mirror_AL_C.json`

- [ ] **Step 1: Simplify `test_mosi_template.json`**

Replace:
```json
"lines": [
    {"element": "B", "lambda": 67.6, "weight": 1.0},
    {"element": "C", "lambda": 44.7, "weight": 1.0},
    {"element": "N", "lambda": 31.6, "weight": 1.0}
]
```

With:
```json
"lines": ["B-N"]
```

- [ ] **Step 2: Simplify `mirror_AL_C.json`**

Replace the 7-element explicit array with:
```json
"lines": ["C-F", "Na-Al"]
```

(Skips Ne — it's a noble gas and wasn't in the original.)

- [ ] **Step 3: Verify configs load correctly**

Build and run XRFCalc, load each config file via the UI.

- [ ] **Step 4: Commit**

```
git add UniversalMirror/test_mosi_template.json UniversalMirror/mirror_AL_C.json
git commit -m "* Simplify config line definitions to use element names and ranges"
```

---

## Verification Checklist

After all tasks are complete:

- [ ] All 16+ new tests pass (lookup, range, config loading, backward compat)
- [ ] All ~266 existing tests still pass
- [ ] Win64 Release builds cleanly
- [ ] No references to `TTargetElement` or `Config.Targets` remain in source
- [ ] Old configs with `"targets"` key still load correctly (backward compat)
- [ ] New configs with `"lines"` key and simplified format load correctly
- [ ] `SaveConfig` writes `"lines"` key with expanded format
- [ ] UI group box shows "XRF Lines", lists B through Zn with correct weights grid
