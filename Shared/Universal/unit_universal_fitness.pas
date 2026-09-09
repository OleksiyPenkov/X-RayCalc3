unit unit_universal_fitness;

interface

uses
  System.SysUtils, System.Math, math_complex,
  cmd_unit_types, unit_universal_types, unit_materials_mix,
  unit_universal_templates;

type
  // Fills the layer stack for the given target wavelength index.
  TLayerSetBuilder = reference to procedure(TargetIdx: Integer;
    var Layers: TLayers);

  TUniversalFitness = class
  private
    FMixer: TMaterialMixer;
    FConfig: TUniversalConfig;
    FTargetCount: Integer;
    FPoolSize: Integer;
    FTemplates: TTemplateLibrary;
    FLayersBuf: TLayers;
    FCurveBuf: TDataArray;
    FConvBuf: TDataArray;
    FCurveLen: Integer;
    FScanPoints: Integer;
    FScanHalfRange: Single;

    procedure BuildLayers(const Genome: TGenome; TargetIdx: Integer);
    function GetDominantMaterial(const Comp: TCompositionGenes): string;
    procedure ScanReflectivity(
      Lambda, ThetaCenter, ThetaHalfRange: Single;
      NPoints: Integer);
    function ExtractRPeak: Single;
    function ExtractFWHM(RPeak: Single): Single;
    procedure Convolute(Width: Single);
    function ComputeFoM(const Build: TLayerSetBuilder; d: Single;
      NInt: Integer; Penalty: Single; var Results: TTargetResults): Single;
  public
    constructor Create(AMixer: TMaterialMixer; const AConfig: TUniversalConfig;
      const ATemplates: TTemplateLibrary);

    function Evaluate(const Genome: TGenome;
      var Results: TTargetResults): Single;

    // Same FoM code as Evaluate, but the layer stack for each target comes
    // from Builder; d and NInt drive the Bragg angles and FWHM_ref.
    // Contract: Results is grown to the configured target count if the caller
    // passed a shorter (or empty) array, so it is always safe to index
    // 0..High(Config.Lines) on return. d must be > 0; NInt is clamped to >= 1.
    function EvaluateLayers(const Builder: TLayerSetBuilder; d: Single;
      NInt: Integer; var Results: TTargetResults): Single;

    function GetCurve(const Genome: TGenome; TargetIdx: Integer): TDataArray;
  end;

implementation

uses
  unit_universal_refcalc;

const
  DEFAULT_SCAN_POINTS = 200;
  DEFAULT_SCAN_HALF_RANGE = 5.0;
  PENALTY_DARK = 100.0;
  PENALTY_DEGENERATE = 1.0;

constructor TUniversalFitness.Create(AMixer: TMaterialMixer;
  const AConfig: TUniversalConfig; const ATemplates: TTemplateLibrary);
begin
  inherited Create;
  FMixer := AMixer;
  FConfig := AConfig;
  FTemplates := ATemplates;
  FTargetCount := Length(AConfig.Lines);
  FPoolSize := Length(AConfig.ElementPool);
  if AConfig.Fitness.ScanPoints > 0 then
    FScanPoints := AConfig.Fitness.ScanPoints
  else
    FScanPoints := DEFAULT_SCAN_POINTS;
  if AConfig.Fitness.ScanHalfRange > 0 then
    FScanHalfRange := AConfig.Fitness.ScanHalfRange
  else
    FScanHalfRange := DEFAULT_SCAN_HALF_RANGE;
  SetLength(FCurveBuf, FScanPoints);
  SetLength(FConvBuf, FScanPoints);
end;

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

procedure TUniversalFitness.BuildLayers(const Genome: TGenome;
  TargetIdx: Integer);
var
  NInt, TotalLayers, LayerIdx, Period, Role, j, TemplIdx, ElemIdx, CapIdx: Integer;
  H1, H2, SubH: Single;
  Eps: TComplex;
  Dens: Single;
  Key: string;
  Templ: TTemplatePair;
  Cap: TTemplateCap;
  UseTemplate, HasCap: Boolean;
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
    // Select cap variant (if any)
    HasCap := Length(Templ.Caps) > 0;
    if HasCap then
    begin
      CapIdx := Round(Genome.CapVariant);
      if CapIdx < 0 then CapIdx := 0;
      if CapIdx > High(Templ.Caps) then CapIdx := High(Templ.Caps);
      Cap := Templ.Caps[CapIdx];
    end;

    // Template path: variable layers per period
    TotalLayers := 2 + NInt * Length(Templ.Layers);
    if HasCap then
      Inc(TotalLayers);
    SetLength(FLayersBuf, TotalLayers);

    // Layer 0: vacuum
    FLayersBuf[0].e.re := 1.0;
    FLayersBuf[0].e.im := 0.0;
    FLayersBuf[0].H := 0;
    FLayersBuf[0].S := 0;

    LayerIdx := 1;

    // Cap layer (if present)
    if HasCap then
    begin
      ElemIdx := FMixer.FindElementIndex(Cap.Material);
      FMixer.CalcSingleEpsilon(ElemIdx, Cap.Density, TargetIdx, Eps);
      FLayersBuf[LayerIdx].e := Eps;
      FLayersBuf[LayerIdx].H := Genome.CapH;
      FLayersBuf[LayerIdx].S := Cap.Sigma;
      FLayersBuf[LayerIdx].Rho := Cap.Density;
      Inc(LayerIdx);
    end;

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

        FLayersBuf[LayerIdx].e := Eps;
        FLayersBuf[LayerIdx].H := SubH;
        FLayersBuf[LayerIdx].S := Templ.Layers[j].Sigma;
        FLayersBuf[LayerIdx].Rho := Templ.Layers[j].Density;
        Inc(LayerIdx);
      end;
    end;

    // Substrate
    FMixer.CalcSubstrateEpsilon(TargetIdx, Eps);
    FLayersBuf[LayerIdx].e := Eps;
    FLayersBuf[LayerIdx].H := 1e8;
    FLayersBuf[LayerIdx].S := Genome.Sigma;
  end
  else
  begin
    // Original bilayer path (unchanged)
    TotalLayers := 2 + NInt * LAYERS_PER_PERIOD;
    SetLength(FLayersBuf, TotalLayers);

    FLayersBuf[0].e.re := 1.0;
    FLayersBuf[0].e.im := 0.0;
    FLayersBuf[0].H := 0;
    FLayersBuf[0].S := 0;

    H1 := Genome.d * Genome.Gamma;
    H2 := Genome.d * (1 - Genome.Gamma);

    LayerIdx := 1;
    for Period := 0 to NInt - 1 do
    begin
      for Role := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        FMixer.CalcMixedEpsilon(
          Genome.Composition[Role],
          1.0,
          TargetIdx,
          Eps, Dens
        );
        FLayersBuf[LayerIdx].e := Eps;
        if Role = 0 then
          FLayersBuf[LayerIdx].H := H1
        else
          FLayersBuf[LayerIdx].H := H2;
        FLayersBuf[LayerIdx].S := Genome.Sigma;
        FLayersBuf[LayerIdx].Rho := Dens;
        Inc(LayerIdx);
      end;
    end;

    FMixer.CalcSubstrateEpsilon(TargetIdx, Eps);
    FLayersBuf[LayerIdx].e := Eps;
    FLayersBuf[LayerIdx].H := 1e8;
    FLayersBuf[LayerIdx].S := Genome.Sigma;
  end;
end;

procedure TUniversalFitness.ScanReflectivity(
  Lambda, ThetaCenter, ThetaHalfRange: Single;
  NPoints: Integer);
var
  StartT, EndT, Step: Single;
  i: Integer;
begin
  StartT := Max(FConfig.Fitness.ThetaMin + 0.1, ThetaCenter - ThetaHalfRange);
  EndT := ThetaCenter + ThetaHalfRange;
  Step := (EndT - StartT) / NPoints;
  if Length(FCurveBuf) < NPoints then
    SetLength(FCurveBuf, NPoints);
  FCurveLen := NPoints;
  // No Copy needed: RefCalcStandalone fully recomputes K/RF/R from e/H/S
  for i := 0 to NPoints - 1 do
  begin
    FCurveBuf[i].t := StartT + i * Step;
    FCurveBuf[i].r := RefCalcStandalone(FCurveBuf[i].t, Lambda, FLayersBuf,
      FConfig.Fitness.Polarization, rfError);
  end;
end;

function TUniversalFitness.ExtractRPeak: Single;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to FCurveLen - 1 do
    if FCurveBuf[i].r > Result then
      Result := FCurveBuf[i].r;
end;

function TUniversalFitness.ExtractFWHM(RPeak: Single): Single;
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
  for i := 1 to FCurveLen - 1 do
    if FCurveBuf[i].r > FCurveBuf[PeakIdx].r then
      PeakIdx := i;

  // Walk left from peak to find half-max crossing
  ThetaLeft := FCurveBuf[0].t;
  for i := PeakIdx downto 1 do
    if FCurveBuf[i-1].r <= HalfMax then
    begin
      Frac := (HalfMax - FCurveBuf[i-1].r) / (FCurveBuf[i].r - FCurveBuf[i-1].r);
      ThetaLeft := FCurveBuf[i-1].t + Frac * (FCurveBuf[i].t - FCurveBuf[i-1].t);
      Break;
    end;

  // Walk right from peak to find half-max crossing
  ThetaRight := FCurveBuf[FCurveLen - 1].t;
  for i := PeakIdx to FCurveLen - 2 do
    if FCurveBuf[i+1].r <= HalfMax then
    begin
      Frac := (HalfMax - FCurveBuf[i+1].r) / (FCurveBuf[i].r - FCurveBuf[i+1].r);
      ThetaRight := FCurveBuf[i+1].t + Frac * (FCurveBuf[i].t - FCurveBuf[i+1].t);
      Break;
    end;

  Result := ThetaRight - ThetaLeft;
end;

procedure TUniversalFitness.Convolute(Width: Single);
var
  Size, N, i, k, p, NewLen: Integer;
  Delta, Sum, t1, sqrW, KernelSum: Single;
begin
  if Width <= 0 then Exit;

  Size := FCurveLen;
  if Size < 3 then Exit;

  Width := Width * 0.849;
  sqrW := Sqr(Width);

  Delta := (FCurveBuf[Size - 1].t - FCurveBuf[0].t) / Size;
  N := Round(3 * Width / Delta);
  if N < 1 then N := 1;
  if N >= Size div 2 then N := Size div 2 - 1;

  // Compute discrete kernel sum for proper normalization
  KernelSum := 0;
  for k := -N to N do
    KernelSum := KernelSum + Exp(-2 * Sqr(k * Delta) / sqrW);

  NewLen := Size - 2 * N;
  if Length(FConvBuf) < NewLen then
    SetLength(FConvBuf, NewLen);

  p := 0;
  for i := N to Size - N - 1 do
  begin
    t1 := -(N * Delta);
    Sum := 0;
    for k := i - N to i + N do
    begin
      Sum := Sum + FCurveBuf[k].r * Exp(-2 * Sqr(t1) / sqrW);
      t1 := t1 + Delta;
    end;
    FConvBuf[p].t := FCurveBuf[i].t;
    FConvBuf[p].r := Sum / KernelSum;
    Inc(p);
  end;

  // Copy convolved data back into FCurveBuf without resizing (no heap allocation)
  Move(FConvBuf[0], FCurveBuf[0], NewLen * SizeOf(TDataPoint));
  FCurveLen := NewLen;
end;

function TUniversalFitness.ComputeFoM(const Build: TLayerSetBuilder;
  d: Single; NInt: Integer; Penalty: Single;
  var Results: TTargetResults): Single;
var
  i, j: Integer;
  SinArg: Single;
  FoM, FWHMRef: Single;
  ThetaArr: array[0..MAX_LINES-1] of Single;
  RPeakArr: array[0..MAX_LINES-1] of Single;
  FWHMArr: array[0..MAX_LINES-1] of Single;
  ValidArr: array[0..MAX_LINES-1] of Boolean;
  CrossR: array[0..MAX_LINES-1, 0..MAX_LINES-1] of Single;
  ContamSum, Purity, REffective: Single;
begin
  FoM := 0;

  // Results is written unchecked below and Release builds have range checking
  // off, so make sure it is at least FTargetCount long. Existing callers
  // already size it correctly, for which this is a no-op.
  if Length(Results) < FTargetCount then
    SetLength(Results, FTargetCount);

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

    SinArg := FConfig.Lines[i].Lambda / (2 * d);
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

    Build(i, FLayersBuf);
    ScanReflectivity(FConfig.Lines[i].Lambda,
      ThetaArr[i], FScanHalfRange, FScanPoints);
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
          CrossR[j, i] := RefCalcStandalone(ThetaArr[j], FConfig.Lines[i].Lambda,
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
      FConfig.Lines[i].Lambda / (NInt * d * Cos(DegToRad(ThetaArr[i])))
    );
    if FWHMRef < 1e-10 then FWHMRef := 1e-10;

    FoM := FoM + FConfig.Lines[i].Weight * (
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

function TUniversalFitness.Evaluate(const Genome: TGenome;
  var Results: TTargetResults): Single;
var
  Penalty: Single;
  Key: string;
  TemplIdx: Integer;
begin
  Penalty := 0;

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

  Result := ComputeFoM(
    procedure(TargetIdx: Integer; var L: TLayers)
    begin
      BuildLayers(Genome, TargetIdx);
    end,
    Genome.d, NRound(Genome.N), Penalty, Results);
end;

function TUniversalFitness.EvaluateLayers(const Builder: TLayerSetBuilder;
  d: Single; NInt: Integer; var Results: TTargetResults): Single;
begin
  // Guards for the public explicit-layer entry point only. Evaluate is left
  // alone: its d and N come from the PSO, already bounded by the config.
  if d <= 0 then
    raise Exception.Create('EvaluateLayers: d must be > 0');
  NInt := Max(1, NInt);

  Result := ComputeFoM(Builder, d, NInt, 0, Results);
end;

function TUniversalFitness.GetCurve(const Genome: TGenome;
  TargetIdx: Integer): TDataArray;
var
  ThetaBragg, SinArg: Single;
begin
  SinArg := FConfig.Lines[TargetIdx].Lambda / (2 * Genome.d);
  if SinArg >= 1.0 then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  ThetaBragg := RadToDeg(ArcSin(SinArg));
  BuildLayers(Genome, TargetIdx);
  ScanReflectivity(FConfig.Lines[TargetIdx].Lambda,
    ThetaBragg, FScanHalfRange, FScanPoints);
  Convolute(FConfig.Fitness.DeltaTheta);
  Result := Copy(FCurveBuf, 0, FCurveLen);
end;

end.
