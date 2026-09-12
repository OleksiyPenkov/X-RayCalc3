unit unit_universal_types;

interface

uses
  System.SysUtils, System.Math,
  cmd_unit_types;

const
  MAX_POOL_ELEMENTS = 16;
  MAX_LINES = 16;

  // The FoM's width reference uses a FIXED number of periods, not the N of the
  // structure: lambda / (N d cos theta) shrinks as 1/N while the real peak
  // width saturates at the extinction-limited one, so a reference tied to N
  // makes the width penalty grow with N and drives the optimizer to three or
  // four periods. 0 in a configuration means "use this".
  DEFAULT_N_REF = 50;

  // What a configuration of 0 means: 200 points per line, and a window chosen
  // per line rather than a fixed half-range (DEFAULT_SCAN_HALF_RANGE is what a
  // fixed window falls back to, and the widest an adaptive one is widened to).
  DEFAULT_SCAN_POINTS     = 200;
  DEFAULT_SCAN_HALF_RANGE = 5.0;

  // The scan grid of one line: the configured scan_points is a floor, the step
  // is never coarser than the kinematic reference width over
  // POINTS_PER_FWHM_REF, and SCAN_POINTS_MAX caps what that asks for.
  POINTS_PER_FWHM_REF = 10;
  SCAN_POINTS_MAX     = 20000;

  // The adaptive scan window, used when the configuration leaves
  // scan_half_range at 0. Half the window is WINDOW_FWHM_FACTOR kinematic
  // widths but never less than ADAPTIVE_HALF_FLOOR_DEG; the scan never starts
  // below PLATEAU_MARGIN times the critical angle of the stack, which is what
  // keeps the total-reflection plateau out of the peak search; and a peak that
  // does not fall to half its height inside the window is measured once more
  // over a window of at most WIDEN_HALF_LIMIT_DEG.
  ADAPTIVE_HALF_FLOOR_DEG = 0.5;
  WINDOW_FWHM_FACTOR      = 4;
  PLATEAU_MARGIN          = 1.15;
  WIDEN_HALF_LIMIT_DEG    = 5.0;
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

  // XRF emission line definition
  TXRFLine = record
    Name: string;
    Lambda: Single;       // characteristic wavelength in Angstroms
    Weight: Single;       // relative weight in FoM
  end;

  // Result of evaluating one target wavelength
  TTargetResult = record
    RPeak: Single;        // peak reflectivity (0..1)
    FWHM: Single;         // angular FWHM in degrees
    ThetaBragg: Single;   // kinematic Bragg angle in degrees, asin(lambda/2d)
    Valid: Boolean;        // false if lambda/2d > 1 (no Bragg peak)
    // What the peak search actually did, per line (TUniversalFitness.MeasureLine):
    ThetaPeak: Single;    // refraction-corrected centre of the scan, degrees
    ScanHalf: Single;     // half-range added either side of the angle pair, deg
    ScanStep: Single;     // grid step of that scan, degrees
    ScanPointsUsed: Integer; // points the peak was searched over
  end;

  TTargetResults = array of TTargetResult;

  // Range parameter (min/max bounds)
  TParamRange = record
    Min, Max: Single;
  end;

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

  // Capping layer definition (one variant)
  TTemplateCap = record
    Name: string;             // display name (e.g. "Si", "Ru")
    Material: string;
    Sigma: Single;            // interface roughness (Angstroms)
    Density: Single;          // bulk density (g/cm3)
    ThicknessRange: TParamRange; // optimizable thickness range (Angstroms)
  end;

  // A complete template for one material pair
  TTemplatePair = record
    Key: string;              // "Mo/Si" - lookup key
    Description: string;      // human-readable description
    Layers: array of TTemplateLayer;
    GammaReduction: Single;   // sum of fixed thicknesses subtracted from gamma layer
    OneMinusGammaReduction: Single; // sum of fixed thicknesses subtracted from 1-gamma layer
    Caps: array of TTemplateCap;  // cap variants (empty = no cap)
  end;

  // Library of all loaded templates
  TTemplateLibrary = array of TTemplatePair;

  // Composition fractions for one layer role
  TCompositionGenes = array of Single; // length = element_pool count, sum = 1.0

  // Full genome for one particle
  TGenome = record
    Composition: array [0..LAYERS_PER_PERIOD-1] of TCompositionGenes; // per-layer fractions
    d: Single;              // period thickness (A)
    Gamma: Single;          // reflector/period ratio
    N: Single;              // number of periods (float, rounded for eval)
    Sigma: Single;          // interface roughness (A)
    CapH: Single;           // capping layer thickness (A), 0 = no cap
    CapVariant: Single;     // cap variant selector (rounded to index into Caps[])
    DensityFactor: array [0..LAYERS_PER_PERIOD-1] of Single; // per-layer density multiplier
  end;

  // Velocity vector (same shape as genome)
  TVelocity = record
    Composition: array [0..LAYERS_PER_PERIOD-1] of TCompositionGenes;
    d: Single;
    Gamma: Single;
    N: Single;
    Sigma: Single;
    CapH: Single;
    CapVariant: Single;
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
    DensityFactorFixed: Single;  // fixed density factor (<=0 means use DensityFactorRange)
    DensityFactorRange: TParamRange;
    CapHRange: TParamRange;          // capping layer thickness range (0,0 = no cap)
    CapVariantCount: Integer;        // number of cap variants (0 = no cap)
  end;

  // Fitness configuration from JSON
  TFitnessConfig = record
    wR: Single;             // weight for R_peak
    wFWHM: Single;          // weight for FWHM penalty
    RMinThreshold: Single;  // minimum acceptable R_peak
    Polarization: TPolarisation;
    DeltaTheta: Single;     // beam divergence FWHM in degrees (0 = ideal)
    ThetaMin: Single;       // minimum Bragg angle in degrees (skip total reflection zone)
    wPurity: Single;        // [0..1] weight for spectral purity penalty (0 = off)
    ScanPoints: Integer;    // number of points in reflectivity scan (0 = default 200)
    ScanHalfRange: Single;  // fixed scan half-range in degrees (0 = adaptive)
    NRef: Integer;          // periods in the FWHM reference (0 = DEFAULT_N_REF)
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

  // Excluded material pair (by pool index, symmetric)
  TExcludedPair = record
    Idx1, Idx2: Integer;
  end;

  // Full configuration
  TUniversalConfig = record
    Lines: array of TXRFLine;
    ElementPool: array of string;
    ExcludedPairs: array of TExcludedPair;
    Structure: TStructureConfig;
    Fitness: TFitnessConfig;
    Optimizer: TOptimizerConfig;
    Substrate: string;
    HenkePath: string;
    OutputDir: string;
    ResumeFrom: string;
    TemplatePath: string;     // path to template JSON file (empty = no templates)
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
  Result.CapH := 0;
  Result.CapVariant := 0;
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
  Result.CapH := 0;
  Result.CapVariant := 0;
  Result.DensityFactor[0] := 0;
  Result.DensityFactor[1] := 0;
end;

function NRound(Value: Single): Integer;
begin
  Result := Max(1, Round(Value));
end;

end.
