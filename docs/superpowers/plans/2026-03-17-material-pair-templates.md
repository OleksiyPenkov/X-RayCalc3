# Material Pair Templates Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace ideal bilayer periods with realistic multi-layer structures (e.g., Mo/Si → Mo/MoSi2/Si/MoSi2) using material pair templates loaded from a JSON file.

**Architecture:** Templates are loaded from a standalone JSON file referenced by config. In `BuildLayers`, when pure-elements mode is active and a template matches the current material pair, the period is expanded into the template's sub-layers with fixed roughness and density. Template materials not in the optimizer's element pool are registered with the mixer as "extra" elements so their Henke data is loaded. Only d, Gamma, and N are optimized when a template is active.

**Tech Stack:** Delphi Object Pascal, System.JSON, DUnitX

**Spec:** `docs/superpowers/specs/2026-03-17-material-pair-templates-design.md`

---

## File Structure

| File | Action | Responsibility |
|------|--------|---------------|
| `Universal/unit_universal_types.pas` | Modify | Add template record types, TemplatePath to config |
| `Universal/unit_universal_templates.pas` | Create | Template JSON loading, material collection |
| `Math/unit_materials_mix.pas` | Modify | Add FindElementIndex, CalcSingleEpsilon; fix CalcMixedEpsilon loop bound |
| `Universal/unit_universal_fitness.pas` | Modify | Template-aware BuildLayers |
| `Universal/unit_universal_io.pas` | Modify | Parse/save template_file in config JSON |
| `Universal/unit_universal_optimizer.pas` | Modify | Load templates, register extra materials with mixer |
| `XRFCalc/frm_XRFMain.pas` | Modify | Template path UI field, config marshalling, INI persistence |
| `XRFCalc/frm_XRFMain.dfm` | Modify | Add template path controls to Paths group |
| `XRC_CMD/xrccmd.dpr` | Modify | Add unit_universal_templates to uses |
| `Tests/Test_Templates.pas` | Create | Unit tests for template loading and thickness computation |

---

## Chunk 1: Data Structures and Template Loading

### Task 1: Template Types

**Files:**
- Modify: `Universal/unit_universal_types.pas`

- [ ] **Step 1: Add template record types after TTargetResult**

Add the following types after the `TTargetResults` declaration (after line 42):

```pascal
  // Template sub-layer thickness type
  TThicknessType = (ttGamma, ttOneMinusGamma, ttFixed);

  // One sub-layer in a material pair template
  TTemplateLayer = record
    Material: string;
    ThicknessType: TThicknessType;
    FixedThickness: Single;  // Angstroms, only used when ThicknessType = ttFixed
    Sigma: Single;           // interface roughness (Angstroms)
    Density: Single;         // bulk density (g/cm3)
  end;

  // A complete template for one material pair
  TTemplatePair = record
    Key: string;              // "Mo/Si" — lookup key
    Description: string;      // human-readable description
    Layers: array of TTemplateLayer;
    GammaReduction: Single;   // sum of fixed thicknesses subtracted from gamma layer
    OneMinusGammaReduction: Single; // sum of fixed thicknesses subtracted from 1-gamma layer
  end;

  // Library of all loaded templates
  TTemplateLibrary = array of TTemplatePair;
```

- [ ] **Step 2: Add TemplatePath to TUniversalConfig**

In the `TUniversalConfig` record (around line 120-130), add `TemplatePath` after `ResumeFrom`:

```pascal
    ResumeFrom: string;
    TemplatePath: string;     // path to template JSON file (empty = no templates)
```

- [ ] **Step 3: Build to verify no syntax errors**

Run: Win32 Release build of xrccmd.
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```
git add Universal/unit_universal_types.pas
git commit -m "+ Add template data types and TemplatePath to config"
```

---

### Task 2: Template Loading Unit

**Files:**
- Create: `Universal/unit_universal_templates.pas`
- Modify: `XRC_CMD/xrccmd.dpr` (add to uses)

- [ ] **Step 1: Create unit_universal_templates.pas**

```pascal
unit unit_universal_templates;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  unit_universal_types;

function LoadTemplates(const FileName: string): TTemplateLibrary;
function FindTemplate(const Library: TTemplateLibrary;
  const Key: string): Integer;
function CollectTemplateMaterials(const Library: TTemplateLibrary): TArray<string>;

implementation

function ParseThicknessType(JValue: TJSONValue;
  out FixedThickness: Single): TThicknessType;
begin
  if JValue is TJSONString then
  begin
    if SameText(JValue.Value, 'gamma') then
    begin
      Result := ttGamma;
      FixedThickness := 0;
    end
    else if SameText(JValue.Value, '1-gamma') then
    begin
      Result := ttOneMinusGamma;
      FixedThickness := 0;
    end
    else
      raise Exception.CreateFmt('Unknown thickness type: %s', [JValue.Value]);
  end
  else if JValue is TJSONNumber then
  begin
    Result := ttFixed;
    FixedThickness := JValue.GetValue<Double>;
  end
  else
    raise Exception.Create('Invalid thickness value in template');
end;

procedure ComputeReductions(var Pair: TTemplatePair);
var
  GammaIdx, OneMinusIdx, i: Integer;
  DistG, DistOM: Integer;
begin
  Pair.GammaReduction := 0;
  Pair.OneMinusGammaReduction := 0;

  // Find indices of gamma and 1-gamma layers
  GammaIdx := -1;
  OneMinusIdx := -1;
  for i := 0 to High(Pair.Layers) do
  begin
    if Pair.Layers[i].ThicknessType = ttGamma then
      GammaIdx := i
    else if Pair.Layers[i].ThicknessType = ttOneMinusGamma then
      OneMinusIdx := i;
  end;

  if (GammaIdx < 0) or (OneMinusIdx < 0) then
    raise Exception.CreateFmt(
      'Template "%s" must have exactly one "gamma" and one "1-gamma" layer',
      [Pair.Key]);

  // Assign each fixed layer to its nearest main layer
  for i := 0 to High(Pair.Layers) do
  begin
    if Pair.Layers[i].ThicknessType <> ttFixed then
      Continue;
    DistG := Abs(i - GammaIdx);
    DistOM := Abs(i - OneMinusIdx);
    if DistG <= DistOM then
      Pair.GammaReduction := Pair.GammaReduction + Pair.Layers[i].FixedThickness
    else
      Pair.OneMinusGammaReduction := Pair.OneMinusGammaReduction + Pair.Layers[i].FixedThickness;
  end;
end;

function LoadTemplates(const FileName: string): TTemplateLibrary;
var
  Content: string;
  JSON: TJSONObject;
  JPair: TJSONPair;
  JPairObj: TJSONObject;
  JLayers: TJSONArray;
  JLayer: TJSONObject;
  i, PairIdx: Integer;
begin
  SetLength(Result, 0);
  if (FileName = '') or not FileExists(FileName) then
    Exit;

  Content := TFile.ReadAllText(FileName);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  if JSON = nil then
    raise Exception.Create('Invalid template JSON file');
  try
    SetLength(Result, JSON.Count);
    PairIdx := 0;
    for i := 0 to JSON.Count - 1 do
    begin
      JPair := JSON.Pairs[i];
      Result[PairIdx].Key := JPair.JsonString.Value;

      JPairObj := JPair.JsonValue as TJSONObject;

      if JPairObj.FindValue('description') <> nil then
        Result[PairIdx].Description := JPairObj.GetValue<string>('description')
      else
        Result[PairIdx].Description := '';

      JLayers := JPairObj.GetValue<TJSONArray>('layers');
      SetLength(Result[PairIdx].Layers, JLayers.Count);
      for var j := 0 to JLayers.Count - 1 do
      begin
        JLayer := JLayers.Items[j] as TJSONObject;
        Result[PairIdx].Layers[j].Material := JLayer.GetValue<string>('material');
        Result[PairIdx].Layers[j].ThicknessType :=
          ParseThicknessType(JLayer.GetValue('thickness'),
            Result[PairIdx].Layers[j].FixedThickness);
        Result[PairIdx].Layers[j].Sigma := JLayer.GetValue<Double>('sigma');
        Result[PairIdx].Layers[j].Density := JLayer.GetValue<Double>('density');
      end;

      ComputeReductions(Result[PairIdx]);
      Inc(PairIdx);
    end;
  finally
    JSON.Free;
  end;
end;

function FindTemplate(const Library: TTemplateLibrary;
  const Key: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Library) do
    if SameText(Library[i].Key, Key) then
      Exit(i);
  Result := -1;
end;

function CollectTemplateMaterials(
  const Library: TTemplateLibrary): TArray<string>;
var
  i, j, k: Integer;
  Found: Boolean;
  List: TArray<string>;
  Count: Integer;
begin
  Count := 0;
  SetLength(List, 64);
  for i := 0 to High(Library) do
    for j := 0 to High(Library[i].Layers) do
    begin
      Found := False;
      for k := 0 to Count - 1 do
        if SameText(List[k], Library[i].Layers[j].Material) then
        begin
          Found := True;
          Break;
        end;
      if not Found then
      begin
        if Count >= Length(List) then
          SetLength(List, Length(List) * 2);
        List[Count] := Library[i].Layers[j].Material;
        Inc(Count);
      end;
    end;
  SetLength(List, Count);
  Result := List;
end;

end.
```

- [ ] **Step 2: Add to xrccmd.dpr uses clause**

After line 25 (`unit_universal_optimizer`), add:

```pascal
  unit_universal_templates in '..\Universal\unit_universal_templates.pas',
```

- [ ] **Step 3: Build to verify**

Run: Win32 Release build of xrccmd.
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```
git add Universal/unit_universal_templates.pas XRC_CMD/xrccmd.dpr
git commit -m "+ Add template loading unit with JSON parsing and material collection"
```

---

### Task 3: CalcSingleEpsilon on TMaterialMixer

**Files:**
- Modify: `Math/unit_materials_mix.pas`

- [ ] **Step 1: Add FindElementIndex and CalcSingleEpsilon declarations**

In the `public` section of `TMaterialMixer` (after `GetElementName`, line 55), add:

```pascal
    function FindElementIndex(const Name: string): Integer;
    procedure CalcSingleEpsilon(
      ElementIndex: Integer;
      Density: Single;
      TargetIdx: Integer;
      out Epsilon: TComplex
    );
```

- [ ] **Step 2: Fix CalcMixedEpsilon loop bound**

In `CalcMixedEpsilon` (line 145), change:

```pascal
  for i := 0 to FElementCount - 1 do
```

to:

```pascal
  for i := 0 to High(Fractions) do
```

This ensures CalcMixedEpsilon only iterates over the composition fractions array, not the full element list (which may include extra template materials).

- [ ] **Step 3: Implement FindElementIndex and CalcSingleEpsilon**

Add before the closing `end.`:

```pascal
function TMaterialMixer.FindElementIndex(const Name: string): Integer;
var
  i: Integer;
begin
  for i := 0 to FElementCount - 1 do
    if SameText(FElements[i].Name, Name) then
      Exit(i);
  Result := -1;
end;

procedure TMaterialMixer.CalcSingleEpsilon(
  ElementIndex: Integer;
  Density: Single;
  TargetIdx: Integer;
  out Epsilon: TComplex);
var
  c, Lambda: Single;
begin
  Lambda := FTargetLambdas[TargetIdx];
  c := ClassicalElectronRadius * Density
       / FElements[ElementIndex].AtomicMass * Sqr(Lambda);
  Epsilon.re := 1 - FHenkeCache[ElementIndex][TargetIdx].f1 * c;
  Epsilon.im := FHenkeCache[ElementIndex][TargetIdx].f2 * c;
end;
```

- [ ] **Step 4: Build to verify**

Run: Win32 Release build of xrccmd.
Expected: Build succeeds.

- [ ] **Step 5: Commit**

```
git add Math/unit_materials_mix.pas
git commit -m "+ Add CalcSingleEpsilon and FindElementIndex to TMaterialMixer"
```

---

## Chunk 2: Core Integration

### Task 4: Config IO for template_file

**Files:**
- Modify: `Universal/unit_universal_io.pas`

- [ ] **Step 1: Parse template_file in LoadConfig**

In `LoadConfig`, after the `resume_from` parsing block (after line 184), add:

```pascal
    if (JSON.FindValue('template_file') <> nil) and
       not (JSON.GetValue('template_file') is TJSONNull) then
      Result.TemplatePath := JSON.GetValue<string>('template_file')
    else
      Result.TemplatePath := '';
```

- [ ] **Step 2: Write template_file in SaveConfig**

In `SaveConfig`, after the `resume_from` block (after line 289), add:

```pascal
    if Config.TemplatePath <> '' then
      JSON.AddPair('template_file', Config.TemplatePath)
    else
      JSON.AddPair('template_file', TJSONNull.Create);
```

- [ ] **Step 3: Build to verify**

Run: Win32 Release build of xrccmd.
Expected: Build succeeds.

- [ ] **Step 4: Commit**

```
git add Universal/unit_universal_io.pas
git commit -m "+ Parse and save template_file in config JSON"
```

---

### Task 5: Interlayer Material Registration in Optimizer

**Files:**
- Modify: `Universal/unit_universal_optimizer.pas`

- [ ] **Step 1: Add unit_universal_templates to uses**

In the `implementation uses` clause (or interface uses if needed), add `unit_universal_templates`:

Change line 7:
```pascal
  cmd_unit_types, unit_universal_types, unit_universal_io,
  unit_universal_fitness, unit_universal_pso, unit_materials_mix;
```
to:
```pascal
  cmd_unit_types, unit_universal_types, unit_universal_io,
  unit_universal_fitness, unit_universal_pso, unit_materials_mix,
  unit_universal_templates;
```

- [ ] **Step 2: Add FTemplates field**

In `TUniversalOptimizer.private` (after `FCancelled: Boolean;`, line 48), add:

```pascal
    FTemplates: TTemplateLibrary;
```

- [ ] **Step 3: Load templates and merge materials in Run**

In `TUniversalOptimizer.Run`, after building the `ElementNames` array (after line 140) and before creating engine objects (line 143), add template loading and material merging:

```pascal
    // Load templates
    FTemplates := LoadTemplates(FConfig.TemplatePath);

    // Collect interlayer materials and merge with element pool
    if Length(FTemplates) > 0 then
    begin
      var ExtraMats := CollectTemplateMaterials(FTemplates);
      for var m := 0 to High(ExtraMats) do
      begin
        var AlreadyInPool := False;
        for var e := 0 to High(ElementNames) do
          if SameText(ElementNames[e], ExtraMats[m]) then
          begin
            AlreadyInPool := True;
            Break;
          end;
        if not AlreadyInPool then
        begin
          SetLength(ElementNames, Length(ElementNames) + 1);
          ElementNames[High(ElementNames)] := ExtraMats[m];
        end;
      end;
    end;
```

- [ ] **Step 4: Pass templates to TUniversalFitness**

Change the fitness constructor call (line 148):

From:
```pascal
    FFitness := TUniversalFitness.Create(FMixer, FConfig);
```
To:
```pascal
    FFitness := TUniversalFitness.Create(FMixer, FConfig, FTemplates);
```

(This requires updating the fitness constructor — done in Task 6.)

- [ ] **Step 5: Build to verify** (will fail until Task 6 is done — that's expected)

- [ ] **Step 6: Commit**

```
git add Universal/unit_universal_optimizer.pas
git commit -m "+ Load templates and register interlayer materials with mixer"
```

---

### Task 6: Template-Aware BuildLayers

**Files:**
- Modify: `Universal/unit_universal_fitness.pas`

- [ ] **Step 1: Add unit_universal_templates to uses**

Add to the interface uses clause (line 7):

```pascal
  cmd_unit_types, unit_universal_types, unit_materials_mix,
  unit_universal_templates;
```

- [ ] **Step 2: Add FTemplates field and update constructor**

Add field to `TUniversalFitness.private` (after `FPoolSize`, line 15):

```pascal
    FTemplates: TTemplateLibrary;
```

Update the constructor declaration (line 25):

```pascal
    constructor Create(AMixer: TMaterialMixer; const AConfig: TUniversalConfig;
      const ATemplates: TTemplateLibrary);
```

Update the constructor implementation (line 44):

```pascal
constructor TUniversalFitness.Create(AMixer: TMaterialMixer;
  const AConfig: TUniversalConfig; const ATemplates: TTemplateLibrary);
begin
  inherited Create;
  FMixer := AMixer;
  FConfig := AConfig;
  FTemplates := ATemplates;
  FTargetCount := Length(AConfig.Targets);
  FPoolSize := Length(AConfig.ElementPool);
end;
```

- [ ] **Step 3: Add helper to get dominant material name**

Add a private method declaration:

```pascal
    function GetDominantMaterial(const Comp: TCompositionGenes): string;
```

Implementation:

```pascal
function TUniversalFitness.GetDominantMaterial(
  const Comp: TCompositionGenes): string;
var
  i, DomIdx: Integer;
begin
  DomIdx := 0;
  for i := 1 to High(Comp) do
    if Comp[i] > Comp[DomIdx] then
      DomIdx := i;
  Result := FMixer.GetElementName(DomIdx);
end;
```

- [ ] **Step 4: Rewrite BuildLayers with template support**

Replace the entire `BuildLayers` function (lines 54-104) with:

```pascal
function TUniversalFitness.BuildLayers(const Genome: TGenome;
  TargetIdx: Integer): TLayers;
var
  NInt, TotalLayers, LayerIdx, Period, Role, i, j, TemplIdx, ElemIdx: Integer;
  H1, H2, SubH: Single;
  Eps: TComplex;
  Dens: Single;
  Key: string;
  Templ: TTemplatePair;
  UseTemplate: Boolean;
begin
  NInt := NRound(Genome.N);

  // Determine if template applies
  UseTemplate := False;
  if FConfig.Structure.PureElements and (Length(FTemplates) > 0) then
  begin
    Key := GetDominantMaterial(Genome.Composition[0]) + '/' +
           GetDominantMaterial(Genome.Composition[1]);
    TemplIdx := FindTemplate(FTemplates, Key);
    if TemplIdx >= 0 then
    begin
      Templ := FTemplates[TemplIdx];
      UseTemplate := True;
    end;
  end;

  if UseTemplate then
  begin
    // Template path: variable layers per period
    TotalLayers := 2 + NInt * Length(Templ.Layers);
    SetLength(Result, TotalLayers);

    // Layer 0: vacuum
    Result[0].e.re := 1.0;
    Result[0].e.im := 0.0;
    Result[0].H := 0;
    Result[0].S := 0;

    LayerIdx := 1;
    for Period := 0 to NInt - 1 do
    begin
      for j := 0 to High(Templ.Layers) do
      begin
        // Compute thickness
        case Templ.Layers[j].ThicknessType of
          ttGamma:
            SubH := Genome.d * Genome.Gamma - Templ.GammaReduction;
          ttOneMinusGamma:
            SubH := Genome.d * (1 - Genome.Gamma) - Templ.OneMinusGammaReduction;
          ttFixed:
            SubH := Templ.Layers[j].FixedThickness;
        end;
        if SubH < 0 then SubH := 0;

        // Compute epsilon from template material at fixed density
        ElemIdx := FMixer.FindElementIndex(Templ.Layers[j].Material);
        FMixer.CalcSingleEpsilon(ElemIdx, Templ.Layers[j].Density,
          TargetIdx, Eps);

        Result[LayerIdx].e := Eps;
        Result[LayerIdx].H := SubH;
        Result[LayerIdx].S := Templ.Layers[j].Sigma;
        Result[LayerIdx].Rho := Templ.Layers[j].Density;
        Inc(LayerIdx);
      end;
    end;

    // Substrate
    FMixer.CalcSubstrateEpsilon(TargetIdx, Eps);
    Result[LayerIdx].e := Eps;
    Result[LayerIdx].H := 1e8;
    Result[LayerIdx].S := Genome.Sigma;
  end
  else
  begin
    // Original bilayer path (unchanged)
    TotalLayers := 2 + NInt * LAYERS_PER_PERIOD;
    SetLength(Result, TotalLayers);

    Result[0].e.re := 1.0;
    Result[0].e.im := 0.0;
    Result[0].H := 0;
    Result[0].S := 0;

    H1 := Genome.d * Genome.Gamma;
    H2 := Genome.d * (1 - Genome.Gamma);

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

    FMixer.CalcSubstrateEpsilon(TargetIdx, Eps);
    Result[LayerIdx].e := Eps;
    Result[LayerIdx].H := 1e8;
    Result[LayerIdx].S := Genome.Sigma;
  end;
end;
```

- [ ] **Step 5: Add negative-thickness penalty in Evaluate**

In `TUniversalFitness.Evaluate`, after the NInt assignment (line 231) and before the target loop, add a penalty check when templates are active:

```pascal
  // Template negative-thickness penalty
  if FConfig.Structure.PureElements and (Length(FTemplates) > 0) then
  begin
    var TKey := GetDominantMaterial(Genome.Composition[0]) + '/' +
                GetDominantMaterial(Genome.Composition[1]);
    var TIdx := FindTemplate(FTemplates, TKey);
    if TIdx >= 0 then
    begin
      var HGamma := Genome.d * Genome.Gamma - FTemplates[TIdx].GammaReduction;
      var HOneMinus := Genome.d * (1 - Genome.Gamma) - FTemplates[TIdx].OneMinusGammaReduction;
      if (HGamma < 0) or (HOneMinus < 0) then
        Penalty := Penalty + PENALTY_DEGENERATE;
    end;
  end;
```

- [ ] **Step 6: Build to verify**

Run: Win32 Release build of xrccmd.
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```
git add Universal/unit_universal_fitness.pas
git commit -m "+ Template-aware BuildLayers with sub-layer expansion"
```

---

## Chunk 3: GUI and Testing

### Task 7: GUI Integration

**Files:**
- Modify: `XRFCalc/frm_XRFMain.pas`
- Modify: `XRFCalc/frm_XRFMain.dfm`

- [ ] **Step 1: Add template path controls to form class**

In `TfrmXRFMain` class, add after `btnBrowseOutput` (line 92):

```pascal
    lblTemplatePath: TLabel;
    edTemplatePath: TEdit;
    btnBrowseTemplate: TButton;
```

Add event handler declaration (after `btnBrowseOutputClick`, line 121):

```pascal
    procedure btnBrowseTemplateClick(Sender: TObject);
```

- [ ] **Step 2: Add template controls to DFM**

In the DFM, inside `grpPaths`, increase the group height from 80 to 106 and add the template controls after `btnBrowseOutput`. The new controls go after the `btnBrowseOutput` object block:

```
    object lblTemplatePath: TLabel
      Left = 8
      Top = 74
      Width = 52
      Height = 15
      Caption = 'Template'
    end
    object edTemplatePath: TEdit
      Left = 60
      Top = 72
      Width = 175
      Height = 23
      TabOrder = 4
    end
    object btnBrowseTemplate: TButton
      Left = 240
      Top = 71
      Width = 30
      Height = 25
      Caption = '...'
      TabOrder = 5
      OnClick = btnBrowseTemplateClick
    end
```

Also update grpPaths Height from `80` to `106`.

- [ ] **Step 3: Implement btnBrowseTemplateClick**

Add to implementation section:

```pascal
procedure TfrmXRFMain.btnBrowseTemplateClick(Sender: TObject);
var
  Dlg: TOpenDialog;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dlg.Title := 'Select template file';
    if edTemplatePath.Text <> '' then
      Dlg.InitialDir := ExtractFilePath(edTemplatePath.Text);
    if Dlg.Execute then
      edTemplatePath.Text := Dlg.FileName;
  finally
    Dlg.Free;
  end;
end;
```

- [ ] **Step 4: Add template path to config marshalling**

In `LoadConfigToUI`, after the Paths section (after line 301), add:

```pascal
  edTemplatePath.Text := Config.TemplatePath;
```

In `CollectConfigFromUI`, after the Paths section (after line 386), add:

```pascal
  Result.TemplatePath := edTemplatePath.Text;
```

- [ ] **Step 5: Add template path to INI persistence**

In `FormCreate`, after `edOutputDir.Text` line, add:

```pascal
    edTemplatePath.Text := Ini.ReadString('Paths', 'TemplatePath', '');
```

In `FormDestroy`, after `edOutputDir` write, add:

```pascal
    Ini.WriteString('Paths', 'TemplatePath', edTemplatePath.Text);
```

- [ ] **Step 6: Build XRFCalc to verify**

Run: Win32 Release build of XRFCalc (via XRayCalc3.dproj or XRFCalc.dproj).
Expected: Build succeeds.

- [ ] **Step 7: Commit**

```
git add XRFCalc/frm_XRFMain.pas XRFCalc/frm_XRFMain.dfm
git commit -m "+ Add template file path to GUI with browse and persistence"
```

---

### Task 8: Sample Template File

**Files:**
- Create: `UniversalMirror/templates.json`

- [ ] **Step 1: Create sample template file**

```json
{
  "Mo/Si": {
    "description": "Mo/Si with MoSi2 interdiffusion layers (~1nm each side)",
    "layers": [
      { "material": "Mo",    "thickness": "gamma",    "sigma": 0.3, "density": 10.2 },
      { "material": "MoSi2", "thickness": 1.0,        "sigma": 0.3, "density": 6.3  },
      { "material": "Si",    "thickness": "1-gamma",  "sigma": 0.5, "density": 2.33 },
      { "material": "MoSi2", "thickness": 0.8,        "sigma": 0.3, "density": 6.3  }
    ]
  },
  "W/Si": {
    "description": "W/Si with WSi2 interdiffusion layers",
    "layers": [
      { "material": "W",     "thickness": "gamma",    "sigma": 0.2, "density": 19.3 },
      { "material": "WSi2",  "thickness": 0.5,        "sigma": 0.3, "density": 9.86 },
      { "material": "Si",    "thickness": "1-gamma",  "sigma": 0.4, "density": 2.33 },
      { "material": "WSi2",  "thickness": 0.5,        "sigma": 0.3, "density": 9.86 }
    ]
  },
  "W/B4C": {
    "description": "W/B4C ideal bilayer (no known interlayers)",
    "layers": [
      { "material": "W",   "thickness": "gamma",    "sigma": 0.2, "density": 19.3 },
      { "material": "B4C", "thickness": "1-gamma",  "sigma": 0.3, "density": 2.52 }
    ]
  },
  "Cr/Sc": {
    "description": "Cr/Sc with CrSc interdiffusion layer on Cr-on-Sc interface",
    "layers": [
      { "material": "Cr",   "thickness": "gamma",    "sigma": 0.3, "density": 7.19  },
      { "material": "Sc",   "thickness": "1-gamma",  "sigma": 0.3, "density": 2.99  },
      { "material": "CrSc", "thickness": 0.5,        "sigma": 0.3, "density": 5.09  }
    ]
  }
}
```

- [ ] **Step 2: Commit**

```
git add UniversalMirror/templates.json
git commit -m "+ Add sample material pair template file"
```

---

### Task 9: Build All and Verify

**Files:** None (build verification only)

- [ ] **Step 1: Build xrccmd Win32 Release**

Run the full build command for xrccmd.
Expected: Build succeeds with no errors.

- [ ] **Step 2: Build XRFCalc Win32 Release**

Run: Win32 Release build.
Expected: Build succeeds with no errors.

- [ ] **Step 3: Build Win64 Release**

Run: Win64 Release build.
Expected: Build succeeds with no errors.

- [ ] **Step 4: Commit any fixes if needed**

---

### Task 10: Update SaveBestStructure and SaveXRCStructure for Templates

**Files:**
- Modify: `Universal/unit_universal_io.pas`

When a template is active, the saved best structure should reflect the expanded sub-layers, not just the 2-layer bilayer.

- [ ] **Step 1: Add unit_universal_templates to unit_universal_io uses**

Add `unit_universal_templates` to the interface uses clause.

- [ ] **Step 2: Update SaveXRCStructure signature to accept templates**

Change the declaration and implementation to accept the template library:

```pascal
    procedure SaveXRCStructure(const Config: TUniversalConfig;
      const Best: TGenome; Mixer: TMaterialMixer;
      const Templates: TTemplateLibrary;
      const OutputDir: string);
```

- [ ] **Step 3: Add template expansion in SaveXRCStructure**

In `SaveXRCStructure`, after finding dominant material names for both layers, check for a matching template. If found, output the expanded sub-layers instead of the 2-layer bilayer:

```pascal
  // Check for template
  var Mat1 := Mixer.GetElementName(DomIdx0);
  var Mat2 := Mixer.GetElementName(DomIdx1);
  var TKey := Mat1 + '/' + Mat2;
  var TIdx := FindTemplate(Templates, TKey);

  if Config.Structure.PureElements and (TIdx >= 0) then
  begin
    // Template-expanded layers
    var Templ := Templates[TIdx];
    for var li := 0 to High(Templ.Layers) do
    begin
      var SubH: Single;
      case Templ.Layers[li].ThicknessType of
        ttGamma: SubH := Best.d * Best.Gamma - Templ.GammaReduction;
        ttOneMinusGamma: SubH := Best.d * (1 - Best.Gamma) - Templ.OneMinusGammaReduction;
        ttFixed: SubH := Templ.Layers[li].FixedThickness;
      end;
      if SubH < 0 then SubH := 0;

      JLayer := TJSONObject.Create;
      JLayer.AddPair('M', Templ.Layers[li].Material);
      JLayer.AddPair('H', TJSONNumber.Create(RoundTo(SubH, -2)));
      JLayer.AddPair('HP', False);
      JLayer.AddPair('s', TJSONNumber.Create(RoundTo(Templ.Layers[li].Sigma, -2)));
      JLayer.AddPair('SP', False);
      JLayer.AddPair('r', TJSONNumber.Create(RoundTo(Templ.Layers[li].Density, -3)));
      JLayer.AddPair('RP', False);
      JLayers.Add(JLayer);
    end;
  end
  else
  begin
    // Original 2-layer output (existing code)
    ...
  end;
```

- [ ] **Step 4: Update caller in unit_universal_optimizer.pas**

Change the SaveXRCStructure call (line 233):

From:
```pascal
      FIO.SaveXRCStructure(FConfig, FPSO.ABest, FMixer, FConfig.OutputDir);
```
To:
```pascal
      FIO.SaveXRCStructure(FConfig, FPSO.ABest, FMixer, FTemplates, FConfig.OutputDir);
```

- [ ] **Step 5: Build to verify**

Run: Win32 Release build.
Expected: Build succeeds.

- [ ] **Step 6: Commit**

```
git add Universal/unit_universal_io.pas Universal/unit_universal_optimizer.pas
git commit -m "* Expand template sub-layers in saved XRC structure"
```
