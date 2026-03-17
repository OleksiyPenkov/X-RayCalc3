unit unit_universal_fitness;

interface

uses
  System.SysUtils, System.Math, math_complex,
  cmd_unit_types, unit_universal_types, unit_materials_mix,
  unit_universal_templates;

type
  TUniversalFitness = class
  private
    FMixer: TMaterialMixer;
    FConfig: TUniversalConfig;
    FTargetCount: Integer;
    FPoolSize: Integer;
    FTemplates: TTemplateLibrary;

    function BuildLayers(const Genome: TGenome; TargetIdx: Integer): TLayers;
    function GetDominantMaterial(const Comp: TCompositionGenes): string;
    function ScanReflectivity(const Layers: TLayers;
      Lambda, ThetaCenter, ThetaHalfRange: Single;
      NPoints: Integer): TDataArray;
    function ExtractRPeak(const Curve: TDataArray): Single;
    function ExtractFWHM(const Curve: TDataArray; RPeak: Single): Single;
    procedure Convolute(var Curve: TDataArray; Width: Single);
  public
    constructor Create(AMixer: TMaterialMixer; const AConfig: TUniversalConfig;
      const ATemplates: TTemplateLibrary);

    function Evaluate(const Genome: TGenome;
      var Results: TTargetResults): Single;

    function GetCurve(const Genome: TGenome; TargetIdx: Integer): TDataArray;
  end;

implementation

uses
  unit_universal_refcalc;

const
  SCAN_POINTS = 200;
  SCAN_HALF_RANGE = 5.0;
  PENALTY_DARK = 100.0;
  PENALTY_DEGENERATE = 1.0;

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

function TUniversalFitness.BuildLayers(const Genome: TGenome;
  TargetIdx: Integer): TLayers;
var
  NInt, TotalLayers, LayerIdx, Period, Role, j, TemplIdx, ElemIdx: Integer;
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
    if Templ.HasCap then
      Inc(TotalLayers);
    SetLength(Result, TotalLayers);

    // Layer 0: vacuum
    Result[0].e.re := 1.0;
    Result[0].e.im := 0.0;
    Result[0].H := 0;
    Result[0].S := 0;

    LayerIdx := 1;

    // Cap layer (if present)
    if Templ.HasCap then
    begin
      ElemIdx := FMixer.FindElementIndex(Templ.Cap.Material);
      FMixer.CalcSingleEpsilon(ElemIdx, Templ.Cap.Density, TargetIdx, Eps);
      Result[LayerIdx].e := Eps;
      Result[LayerIdx].H := Genome.CapH;
      Result[LayerIdx].S := Templ.Cap.Sigma;
      Result[LayerIdx].Rho := Templ.Cap.Density;
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
          1.0,
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

function TUniversalFitness.ScanReflectivity(const Layers: TLayers;
  Lambda, ThetaCenter, ThetaHalfRange: Single;
  NPoints: Integer): TDataArray;
var
  StartT, EndT, Step: Single;
  i: Integer;
  LocalLayers: TLayers;
begin
  StartT := Max(FConfig.Fitness.ThetaMin + 0.1, ThetaCenter - ThetaHalfRange);
  EndT := ThetaCenter + ThetaHalfRange;
  Step := (EndT - StartT) / NPoints;
  SetLength(Result, NPoints);
  for i := 0 to NPoints - 1 do
  begin
    Result[i].t := StartT + i * Step;
    LocalLayers := Copy(Layers);
    Result[i].r := RefCalcStandalone(Result[i].t, Lambda, LocalLayers,
      FConfig.Fitness.Polarization, rfError);
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
  ThetaLeft := Curve[0].t;
  for i := PeakIdx downto 1 do
    if Curve[i-1].r <= HalfMax then
    begin
      Frac := (HalfMax - Curve[i-1].r) / (Curve[i].r - Curve[i-1].r);
      ThetaLeft := Curve[i-1].t + Frac * (Curve[i].t - Curve[i-1].t);
      Break;
    end;

  // Walk right from peak to find half-max crossing
  ThetaRight := Curve[High(Curve)].t;
  for i := PeakIdx to High(Curve) - 1 do
    if Curve[i+1].r <= HalfMax then
    begin
      Frac := (HalfMax - Curve[i+1].r) / (Curve[i].r - Curve[i+1].r);
      ThetaRight := Curve[i+1].t + Frac * (Curve[i].t - Curve[i+1].t);
      Break;
    end;

  Result := ThetaRight - ThetaLeft;
end;

procedure TUniversalFitness.Convolute(var Curve: TDataArray; Width: Single);
var
  Size, N, i, k, p: Integer;
  Delta, Sum, t1, c, sqrW: Single;
  Temp: TDataArray;
begin
  if Width <= 0 then Exit;

  Size := Length(Curve);
  if Size < 3 then Exit;

  Width := Width * 0.849;
  sqrW := Sqr(Width);
  c := 1 / (Width * Sqrt(Pi / 2));

  Delta := (Curve[Size - 1].t - Curve[0].t) / Size;
  N := Round(3 * Width / Delta);
  if N < 1 then N := 1;
  if N >= Size div 2 then N := Size div 2 - 1;

  SetLength(Temp, Size - 2 * N);

  p := 0;
  for i := N to Size - N - 1 do
  begin
    t1 := -(N * Delta);
    Sum := 0;
    for k := i - N to i + N do
    begin
      Sum := Sum + Curve[k].r * c * Exp(-2 * Sqr(t1) / sqrW) * Delta;
      t1 := t1 + Delta;
    end;
    Temp[p].t := Curve[i].t;
    Temp[p].r := Sum;
    Inc(p);
  end;

  Curve := Temp;
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
  Key: string;
  TemplIdx: Integer;
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

  for i := 0 to FTargetCount - 1 do
  begin
    Results[i].Valid := False;
    Results[i].RPeak := 0;
    Results[i].FWHM := 0;
    Results[i].ThetaBragg := 0;

    // Check Bragg condition
    SinArg := FConfig.Targets[i].Lambda / (2 * Genome.d);
    if SinArg >= 1.0 then
      Continue;

    ThetaBragg := RadToDeg(ArcSin(SinArg));
    Results[i].ThetaBragg := ThetaBragg;

    // Skip total reflection zone
    if (FConfig.Fitness.ThetaMin > 0) and (ThetaBragg < FConfig.Fitness.ThetaMin) then
    begin
      Penalty := Penalty + PENALTY_DARK;
      Continue;
    end;

    Results[i].Valid := True;

    // Build layer array and evaluate
    Layers := BuildLayers(Genome, i);
    Curve := ScanReflectivity(Layers, FConfig.Targets[i].Lambda,
      ThetaBragg, SCAN_HALF_RANGE, SCAN_POINTS);
    Convolute(Curve, FConfig.Fitness.DeltaTheta);

    Results[i].RPeak := ExtractRPeak(Curve);
    Results[i].FWHM := ExtractFWHM(Curve, Results[i].RPeak);

    // FWHM_ref = lambda / (N * d * cos(theta_B)) in radians, convert to degrees
    FWHMRef := RadToDeg(
      FConfig.Targets[i].Lambda / (NInt * Genome.d * Cos(DegToRad(ThetaBragg)))
    );
    if FWHMRef < 1e-10 then FWHMRef := 1e-10;

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
  Convolute(Result, FConfig.Fitness.DeltaTheta);
end;

end.
