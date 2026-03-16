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

    function Evaluate(const Genome: TGenome;
      var Results: TTargetResults): Single;

    function GetCurve(const Genome: TGenome; TargetIdx: Integer): TDataArray;
  end;

implementation

uses
  cmd_unit_calc;

const
  SCAN_POINTS = 200;
  SCAN_HALF_RANGE = 5.0;
  PENALTY_DARK = 100.0;
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
  TotalLayers := 2 + NInt * LAYERS_PER_PERIOD;
  SetLength(Result, TotalLayers);

  // Layer 0: vacuum
  Result[0].e.re := 1.0;
  Result[0].e.im := 0.0;
  Result[0].H := 0;
  Result[0].S := 0;

  // Bilayer thicknesses
  H1 := Genome.d * Genome.Gamma;
  H2 := Genome.d * (1 - Genome.Gamma);

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
    Params.P := cmSP;
    Params.RF := rfError;
    Params.Lambda := Lambda;
    Params.K := 1;
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
      Continue;

    ThetaBragg := RadToDeg(ArcSin(SinArg));
    Results[i].ThetaBragg := ThetaBragg;
    Results[i].Valid := True;

    // Build layer array and evaluate
    Layers := BuildLayers(Genome, i);
    Curve := ScanReflectivity(Layers, FConfig.Targets[i].Lambda,
      ThetaBragg, SCAN_HALF_RANGE, SCAN_POINTS);

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
end;

end.
