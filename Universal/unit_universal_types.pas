unit unit_universal_types;

interface

uses
  System.SysUtils, System.Math,
  cmd_unit_types;

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

  TTargetResults = array of TTargetResult;

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
    TargetResults: TTargetResults; // per-target evaluation results
  end;

  PParticle = ^TParticle;
  TParticleArray = array of TParticle;

  // Structure configuration from JSON
  TStructureConfig = record
    StructureType: string;  // 'bilayer'
    LayersPerPeriod: Integer;
    PureElements: Boolean;  // true = no mixing, each layer is a single element
    dRange: TParamRange;
    GammaRange: TParamRange;
    NRange: TParamRange;
    SigmaFixed: Single;          // fixed roughness value (<=0 means use SigmaRange)
    SigmaRange: TParamRange;
    DensityFactorRange: TParamRange;
  end;

  // Fitness configuration from JSON
  TFitnessConfig = record
    wR: Single;             // weight for R_peak
    wFWHM: Single;          // weight for FWHM penalty
    RMinThreshold: Single;  // minimum acceptable R_peak
    Polarization: TPolarisation;
    DeltaTheta: Single;     // beam divergence FWHM in degrees (0 = ideal)
    ThetaMin: Single;       // minimum Bragg angle in degrees (skip total reflection zone)
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
    Particles: TParticleArray;
  end;

// Utility functions
function CreateGenome(PoolSize: Integer): TGenome;
function CreateVelocity(PoolSize: Integer): TVelocity;
function NRound(Value: Single): Integer;

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
