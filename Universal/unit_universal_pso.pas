unit unit_universal_pso;

interface

uses
  System.SysUtils, System.Math, unit_universal_types;

type
  TUniversalPSO = class
  private
    FConfig: TUniversalConfig;
    FPoolSize: Integer;
    FParticles: TParticleArray;
    FGBest: TGenome;
    FGBestFoM: Single;
    FABest: TGenome;
    FABestFoM: Single;
    FJammingCount: Integer;
    FDiversity: Single;
    FMeanVelocity: Single;
    FLevySigmaU: Single;
    FLevyScale: Single;

    FdMin, FdMax, FdRange: Single;
    FGammaMin, FGammaMax, FGammaRange: Single;
    FNMin, FNMax, FNRange: Single;
    FSigmaMin, FSigmaMax, FSigmaRange: Single;
    FSigmaFixed: Boolean;
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

    procedure UpdateBests;

    function GetParticle(Index: Integer): PParticle;
    function ParticleCount: Integer;

    property GBest: TGenome read FGBest;
    property GBestFoM: Single read FGBestFoM;
    property ABest: TGenome read FABest;
    property ABestFoM: Single read FABestFoM;
    property JammingCount: Integer read FJammingCount;
    property Diversity: Single read FDiversity;
    property MeanVelocity: Single read FMeanVelocity;

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
  FSigmaFixed := FConfig.Structure.SigmaFixed >= 0;

  FDFMin := FConfig.Structure.DensityFactorRange.Min;
  FDFMax := FConfig.Structure.DensityFactorRange.Max;
  FDFRange := FDFMax - FDFMin;
end;

procedure TUniversalPSO.NormalizeComposition(var Comp: TCompositionGenes);
var
  i, BestIdx: Integer;
  Sum, BestVal: Single;
begin
  Sum := 0;
  for i := 0 to High(Comp) do
  begin
    if Comp[i] < 0 then Comp[i] := 0;
    if Comp[i] > 1 then Comp[i] := 1;
    Sum := Sum + Comp[i];
  end;

  if Sum < 1e-10 then
  begin
    for i := 0 to High(Comp) do
      Comp[i] := 1.0 / Length(Comp);
    Sum := 1.0;
  end
  else
  begin
    for i := 0 to High(Comp) do
      Comp[i] := Comp[i] / Sum;
  end;

  // Pure elements mode: snap to one-hot (argmax)
  if FConfig.Structure.PureElements then
  begin
    BestIdx := 0;
    BestVal := Comp[0];
    for i := 1 to High(Comp) do
      if Comp[i] > BestVal then
      begin
        BestVal := Comp[i];
        BestIdx := i;
      end;
    for i := 0 to High(Comp) do
      Comp[i] := 0;
    Comp[BestIdx] := 1.0;
  end;
end;

procedure TUniversalPSO.ReflectBound(var Value, Velocity: Single;
  AMin, AMax: Single);
begin
  if Value < AMin then
  begin
    Value := AMin + (AMin - Value);
    if Value > AMax then Value := AMin;
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
begin
  ReflectBound(P.X.d, P.V.d, FdMin, FdMax);
  ReflectBound(P.X.Gamma, P.V.Gamma, FGammaMin, FGammaMax);
  ReflectBound(P.X.N, P.V.N, FNMin, FNMax);
  ReflectBound(P.X.Sigma, P.V.Sigma, FSigmaMin, FSigmaMax);

  for Role := 0 to LAYERS_PER_PERIOD - 1 do
  begin
    ReflectBound(P.X.DensityFactor[Role], P.V.DensityFactor[Role],
      FDFMin, FDFMax);
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
  Elem0, Elem1: Integer;
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
    if FSigmaFixed then
      FParticles[i].X.Sigma := FConfig.Structure.SigmaFixed
    else
      FParticles[i].X.Sigma := FSigmaMin + Random * FSigmaRange;

    // Composition initialization
    if FConfig.Structure.PureElements then
    begin
      // Seed diverse element pairs systematically then random
      Elem0 := i mod FPoolSize;
      Elem1 := (i div FPoolSize) mod FPoolSize;
      // Ensure different elements for each layer role
      if (Elem0 = Elem1) and (FPoolSize > 1) then
        Elem1 := (Elem1 + 1) mod FPoolSize;

      for j := 0 to FPoolSize - 1 do
        FParticles[i].X.Composition[0][j] := 0;
      FParticles[i].X.Composition[0][Elem0] := 1.0;

      for j := 0 to FPoolSize - 1 do
        FParticles[i].X.Composition[1][j] := 0;
      FParticles[i].X.Composition[1][Elem1] := 1.0;
    end
    else
    begin
      for Role := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        for j := 0 to FPoolSize - 1 do
          FParticles[i].X.Composition[Role][j] := Random;
        NormalizeComposition(FParticles[i].X.Composition[Role]);
      end;
    end;

    for Role := 0 to LAYERS_PER_PERIOD - 1 do
      FParticles[i].X.DensityFactor[Role] := FDFMin + Random * FDFRange;

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
  Omega := FConfig.Optimizer.w1 +
    FConfig.Optimizer.w2 * (1 - Iteration / MaxIter);

  for i := 0 to High(FParticles) do
  begin
    r1 := Random;
    r2 := Random;

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

    if not FSigmaFixed then
    begin
      r1 := Random; r2 := Random;
      FParticles[i].V.Sigma := Omega * FParticles[i].V.Sigma
        + C1 * r1 * (FParticles[i].PBest.Sigma - FParticles[i].X.Sigma)
        + C2 * r2 * (FGBest.Sigma - FParticles[i].X.Sigma);
      FParticles[i].X.Sigma := FParticles[i].X.Sigma + FParticles[i].V.Sigma;
    end;

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

    if not FSigmaFixed then
    begin
      Step := LevyStep;
      r1 := Random; r2 := Random;
      FParticles[i].V.Sigma := Omega * Step * (FParticles[i].X.Sigma - Target.Sigma)
        + C1 * r1 * (FParticles[i].PBest.Sigma - FParticles[i].X.Sigma)
        + C2 * r2 * (FGBest.Sigma - FParticles[i].X.Sigma);
      FParticles[i].X.Sigma := FParticles[i].X.Sigma + FParticles[i].V.Sigma;
    end;

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
    if FParticles[i].CurrentFoM < FParticles[i].PBestFoM then
    begin
      FParticles[i].PBestFoM := FParticles[i].CurrentFoM;
      FParticles[i].PBest := FParticles[i].X;
    end;

    if FParticles[i].CurrentFoM < FGBestFoM then
    begin
      FGBestFoM := FParticles[i].CurrentFoM;
      FGBest := FParticles[i].X;
    end;

    if FParticles[i].CurrentFoM < FABestFoM then
    begin
      FABestFoM := FParticles[i].CurrentFoM;
      FABest := FParticles[i].X;
    end;
  end;

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
  for i := 1 to High(FParticles) do
  begin
    FParticles[i].X := FGBest;

    FParticles[i].X.d := FParticles[i].X.d + (Random - 0.5) * FdRange * 0.2;
    FParticles[i].X.Gamma := FParticles[i].X.Gamma + (Random - 0.5) * FGammaRange * 0.2;
    FParticles[i].X.N := FParticles[i].X.N + (Random - 0.5) * FNRange * 0.2;
    FParticles[i].X.Sigma := FParticles[i].X.Sigma + (Random - 0.5) * FSigmaRange * 0.2;

    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      if FConfig.Structure.PureElements and (Random < 0.5) then
      begin
        // 50% chance to pick a completely random element
        for j := 0 to FPoolSize - 1 do
          FParticles[i].X.Composition[Role][j] := 0;
        FParticles[i].X.Composition[Role][Random(FPoolSize)] := 1.0;
      end
      else
      begin
        for j := 0 to FPoolSize - 1 do
          FParticles[i].X.Composition[Role][j] :=
            FParticles[i].X.Composition[Role][j] + (Random - 0.5) * 0.2;
        NormalizeComposition(FParticles[i].X.Composition[Role]);
      end;

      FParticles[i].X.DensityFactor[Role] :=
        FParticles[i].X.DensityFactor[Role] + (Random - 0.5) * FDFRange * 0.2;
    end;

    EnforceConstraints(FParticles[i]);

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
var
  i: Integer;
begin
  FGBest := State.GBest;
  FGBestFoM := State.GBestFoM;
  FABest := State.ABest;
  FABestFoM := State.ABestFoM;
  FJammingCount := State.JammingCount;
  FParticles := Copy(State.Particles);
  // Ensure TargetResults is allocated (not saved in checkpoint)
  for i := 0 to High(FParticles) do
    if Length(FParticles[i].TargetResults) = 0 then
      SetLength(FParticles[i].TargetResults, Length(FConfig.Targets));
end;

end.
