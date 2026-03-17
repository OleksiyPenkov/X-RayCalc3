# Overlap Penalty Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add purity-weighted reflectivity to the XRF fitness function, penalizing higher-order Bragg peak contamination between target elements.

**Architecture:** Restructure `Evaluate()` into three phases: (1) compute R_peak/FWHM per target and cross-reflectivities using already-built layer stacks, (2) compute per-target purity from cross-reflectivity matrix, (3) accumulate FoM using purity-weighted R. One new config field `wPurity` controls the penalty strength.

**Tech Stack:** Delphi Object Pascal, RAD Studio 37.0

**Spec:** `docs/superpowers/specs/2026-03-17-overlap-penalty-design.md`

---

## Chunk 1: Data structures and serialization

### Task 1: Add wPurity field to TFitnessConfig

**Files:**
- Modify: `Universal/unit_universal_types.pas:139-146`

- [ ] **Step 1: Add wPurity field to TFitnessConfig**

In `Universal/unit_universal_types.pas`, add `wPurity` after `ThetaMin` (line 145):

```pascal
  TFitnessConfig = record
    wR: Single;             // weight for R_peak
    wFWHM: Single;          // weight for FWHM penalty
    RMinThreshold: Single;  // minimum acceptable R_peak
    Polarization: TPolarisation;
    DeltaTheta: Single;     // beam divergence FWHM in degrees (0 = ideal)
    ThetaMin: Single;       // minimum Bragg angle in degrees (skip total reflection zone)
    wPurity: Single;        // [0..1] weight for spectral purity penalty (0 = off)
  end;
```

- [ ] **Step 2: Build to verify no compilation errors**

Run: Win64 Release build.
Expected: success — adding a field to a record is non-breaking.

- [ ] **Step 3: Commit**

```
git add Universal/unit_universal_types.pas
git commit -m "+ Add wPurity field to TFitnessConfig"
```

---

### Task 2: Add wPurity to JSON serialization

**Files:**
- Modify: `Universal/unit_universal_io.pas:149-170` (LoadConfig fitness block)
- Modify: `Universal/unit_universal_io.pas:271-281` (SaveConfig fitness block)

- [ ] **Step 1: Add wPurity deserialization in LoadConfig**

In `Universal/unit_universal_io.pas`, after the `theta_min` block (around line 160), add:

```pascal
    if JFitness.FindValue('w_purity') <> nil then
      Result.Fitness.wPurity := JFitness.GetValue<Double>('w_purity')
    else
      Result.Fitness.wPurity := 1.0;  // default: full purity weighting
```

- [ ] **Step 2: Add wPurity serialization in SaveConfig**

In `SaveConfig`, after the `theta_min` line (line 280), add:

```pascal
    JFitness.AddPair('w_purity', TJSONNumber.Create(Config.Fitness.wPurity));
```

- [ ] **Step 3: Build to verify**

Run: Win64 Release build.
Expected: success.

- [ ] **Step 4: Commit**

```
git add Universal/unit_universal_io.pas
git commit -m "+ Serialize wPurity in config JSON"
```

---

### Task 3: Add wPurity to XRFCalc GUI

**Files:**
- Modify: `XRFCalc/frm_XRFMain.dfm:544-646` (grpFitness)
- Modify: `XRFCalc/frm_XRFMain.pas:16-167` (form class + CollectConfigFromUI/LoadConfigToUI)

- [ ] **Step 1: Add label and edit to DFM**

In `XRFCalc/frm_XRFMain.dfm`, expand `grpFitness` height from 180 to 206. Then add new controls before the closing `end` of grpFitness (before line 646):

Change grpFitness Height:
```
        Height = 206
```

Add after `cmbPolarization` block (after line 645):

```
        object lblWPurity: TLabel
          Left = 8
          Top = 176
          Width = 44
          Height = 15
          Caption = 'w_purity'
        end
        object edWPurity: TEdit
          Left = 100
          Top = 174
          Width = 80
          Height = 23
          TabOrder = 6
          Text = '1.0'
        end
```

- [ ] **Step 2: Add field declarations to form class**

In `XRFCalc/frm_XRFMain.pas`, add after `cmbPolarization: TComboBox;` (line 59):

```pascal
    lblWPurity: TLabel;
    edWPurity: TEdit;
```

- [ ] **Step 3: Wire LoadConfigToUI**

In `LoadConfigToUI`, after the polarization block (after line 330), add:

```pascal
  edWPurity.Text := FormatFloat('0.###', Config.Fitness.wPurity);
```

- [ ] **Step 4: Wire CollectConfigFromUI**

In `CollectConfigFromUI`, after the polarization block (after line 416), add:

```pascal
  Result.Fitness.wPurity := StrToFloatDef(edWPurity.Text, 1.0, FS);
```

- [ ] **Step 5: Build to verify**

Run: Win64 Release build.
Expected: success.

- [ ] **Step 6: Commit**

```
git add XRFCalc/frm_XRFMain.pas XRFCalc/frm_XRFMain.dfm
git commit -m "+ Add wPurity control to XRFCalc fitness group"
```

---

## Chunk 2: Core algorithm — restructure Evaluate()

### Task 4: Restructure Evaluate() with cross-reflectivity and purity

**Files:**
- Modify: `Universal/unit_universal_fitness.pas:335-415` (Evaluate function)

This is the core change. The current `Evaluate()` does everything in a single loop: for each target, build layers, scan, extract R/FWHM, accumulate FoM. We restructure into three phases.

- [ ] **Step 1: Replace the Evaluate() function**

Replace the entire `Evaluate` function (lines 335-415 of `Universal/unit_universal_fitness.pas`) with:

```pascal
function TUniversalFitness.Evaluate(const Genome: TGenome;
  var Results: TTargetResults): Single;
var
  i, j: Integer;
  SinArg: Single;
  FoM, FWHMRef: Single;
  NInt: Integer;
  Penalty: Single;
  Key: string;
  TemplIdx: Integer;
  ThetaArr: array[0..MAX_TARGETS-1] of Single;
  RPeakArr: array[0..MAX_TARGETS-1] of Single;
  FWHMArr: array[0..MAX_TARGETS-1] of Single;
  ValidArr: array[0..MAX_TARGETS-1] of Boolean;
  CrossR: array[0..MAX_TARGETS-1, 0..MAX_TARGETS-1] of Single;
  ContamSum, Purity, REffective: Single;
begin
  FoM := 0;
  Penalty := 0;
  NInt := NRound(Genome.N);

  // Template negative-thickness penalty
  if FConfig.Structure.PureElements and (Length(FTemplates) > 0) then
  begin
    Key := GetDominantMaterial(Genome.Composition[0]) + '/' +
           GetDominantMaterial(Genome.Composition[1]);
    TemplIdx := FindTemplate(FTemplates, Key);
    if TemplIdx >= 0 then
    begin
      if (Genome.d * Genome.Gamma - FTemplates[TemplIdx].GammaReduction < 0) or
         (Genome.d * (1 - Genome.Gamma) - FTemplates[TemplIdx].OneMinusGammaReduction < 0) then
        Penalty := Penalty + PENALTY_DEGENERATE;
    end;
  end;

  // --- Phase 1: Pre-compute Bragg angles ---
  for i := 0 to FTargetCount - 1 do
  begin
    ValidArr[i] := False;
    ThetaArr[i] := -1;
    RPeakArr[i] := 0;
    FWHMArr[i] := 0;
    Results[i].Valid := False;
    Results[i].RPeak := 0;
    Results[i].FWHM := 0;
    Results[i].ThetaBragg := 0;
    for j := 0 to FTargetCount - 1 do
      CrossR[i, j] := 0;

    SinArg := FConfig.Targets[i].Lambda / (2 * Genome.d);
    if SinArg >= 1.0 then
      Continue;

    ThetaArr[i] := RadToDeg(ArcSin(SinArg));
    Results[i].ThetaBragg := ThetaArr[i];

    if (FConfig.Fitness.ThetaMin > 0) and (ThetaArr[i] < FConfig.Fitness.ThetaMin) then
    begin
      Penalty := Penalty + PENALTY_DARK;
      Continue;
    end;

    ValidArr[i] := True;
    Results[i].Valid := True;
  end;

  // --- Phase 1b: Evaluate each target + compute cross-reflectivities ---
  for i := 0 to FTargetCount - 1 do
  begin
    if not ValidArr[i] then
      Continue;

    BuildLayers(Genome, i);
    ScanReflectivity(FConfig.Targets[i].Lambda,
      ThetaArr[i], SCAN_HALF_RANGE, SCAN_POINTS);
    Convolute(FConfig.Fitness.DeltaTheta);

    RPeakArr[i] := ExtractRPeak;
    FWHMArr[i] := ExtractFWHM(RPeakArr[i]);
    Results[i].RPeak := RPeakArr[i];
    Results[i].FWHM := FWHMArr[i];

    // While layer stack is built for lambda_i, evaluate at other targets' angles.
    // CrossR[j, i] = reflectivity of lambda_i at target j's Bragg angle.
    // lambda_i must be passed (not lambda_j) because FLayersBuf has epsilon for lambda_i.
    if FConfig.Fitness.wPurity > 0 then
      for j := 0 to FTargetCount - 1 do
        if (j <> i) and ValidArr[j] then
          CrossR[j, i] := RefCalcStandalone(ThetaArr[j], FConfig.Targets[i].Lambda,
            FLayersBuf, FConfig.Fitness.Polarization, rfError);
  end;

  // --- Phase 2+3: Compute purity and accumulate FoM ---
  for i := 0 to FTargetCount - 1 do
  begin
    if not ValidArr[i] then
      Continue;

    // Purity calculation
    if FConfig.Fitness.wPurity > 0 then
    begin
      ContamSum := 0;
      for j := 0 to FTargetCount - 1 do
        if j <> i then
          ContamSum := ContamSum + CrossR[i, j];

      if (RPeakArr[i] > 0) or (ContamSum > 0) then
        Purity := RPeakArr[i] / (RPeakArr[i] + ContamSum)
      else
        Purity := 0;

      REffective := RPeakArr[i] * (1.0 + FConfig.Fitness.wPurity * (Purity - 1.0));
    end
    else
      REffective := RPeakArr[i];

    // FWHM_ref
    FWHMRef := RadToDeg(
      FConfig.Targets[i].Lambda / (NInt * Genome.d * Cos(DegToRad(ThetaArr[i])))
    );
    if FWHMRef < 1e-10 then FWHMRef := 1e-10;

    FoM := FoM + FConfig.Targets[i].Weight * (
      FConfig.Fitness.wR * REffective -
      FConfig.Fitness.wFWHM * FWHMArr[i] / FWHMRef
    );

    // Penalty for dark elements
    if RPeakArr[i] < FConfig.Fitness.RMinThreshold then
      Penalty := Penalty + PENALTY_DARK;
  end;

  // Return negated FoM (PSO minimizes, we want to maximize FoM)
  Result := -(FoM - Penalty);
end;
```

- [ ] **Step 2: Build to verify compilation**

Run: Win64 Release build.
Expected: success.

- [ ] **Step 3: Run existing tests**

Run: build and execute `Tests\XRayCalc3Tests.dproj`.
Expected: all 266 tests pass. Existing tests don't set `wPurity`, so Delphi zero-initializes it to 0.0, meaning no purity penalty — backward compatible.

- [ ] **Step 4: Commit**

```
git add Universal/unit_universal_fitness.pas
git commit -m "+ Restructure Evaluate() with cross-reflectivity purity penalty"
```

---

## Chunk 3: Verification

### Task 5: Build all and run tests

- [ ] **Step 1: Full Win64 Release build**

Build the main project and XRFCalc:
```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1
```

Expected: success.

- [ ] **Step 2: Build and run tests**

```
cmd.exe //c "set BDS=C:\Program Files (x86)\Embarcadero\Studio\37.0&& set BDSCOMMONDIR=C:\Users\Public\Documents\Embarcadero\Studio\37.0&& C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1
```

```
cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1
```

Expected: all tests pass.

- [ ] **Step 3: Verify backward compatibility with existing config**

Load the existing config `UniversalMirror/universal_mirror.json` (which has no `w_purity` field). Confirm `LoadConfig` defaults `wPurity` to 1.0. Save it back out, confirm `w_purity: 1.0` appears in the output.

- [ ] **Step 4: Final commit if any fixes were needed**

```
git add -A
git commit -m "* Fix any issues found during verification"
```
