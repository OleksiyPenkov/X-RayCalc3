# Universal Mirror Optimizer — Design Specification

## Problem

Wavelength-Dispersive XRF spectrometers must mechanically switch between specialized analyzing crystals to scan light elements from Beryllium (114 A) to Magnesium (9.9 A). This is slow, expensive, and introduces calibration errors. The goal is to design a single multilayer mirror — a "Universal Mirror" — that provides high reflectivity and good energy resolution across the entire Be-Mg range simultaneously.

Designing such a mirror by hand is impractical: conflicting physics (wide layers for long wavelengths vs. fine layers for short), material absorption edges that create blind spots for specific elements, and a high-dimensional parameter space with non-intuitive optima.

## Solution

A multi-objective optimization engine integrated into the xrc_cmd CLI. It uses Levy Flight Particle Swarm Optimization (LFPSO) to evolve candidate multilayer structures, evaluating each candidate's reflectivity performance across all target element wavelengths simultaneously.

## CLI Interface

New mode: `-u <config.json>`

```
xrccmd -u mirror_config.json [-v]
```

### Configuration (JSON)

```json
{
  "targets": [
    {"element": "Be", "lambda": 114.0, "weight": 1.0},
    {"element": "B",  "lambda": 67.6,  "weight": 1.0},
    {"element": "C",  "lambda": 44.7,  "weight": 1.0},
    {"element": "N",  "lambda": 31.6,  "weight": 1.0},
    {"element": "O",  "lambda": 23.6,  "weight": 1.0},
    {"element": "F",  "lambda": 18.3,  "weight": 1.0},
    {"element": "Na", "lambda": 11.9,  "weight": 1.0},
    {"element": "Mg", "lambda": 9.89,  "weight": 1.0}
  ],
  "element_pool": ["W", "Mo", "V", "Si", "C", "B", "Ni", "Ti"],
  "structure": {
    "type": "bilayer",
    "layers_per_period": 2,
    "d":              {"min": 10,  "max": 120},
    "gamma":          {"min": 0.1, "max": 0.9},
    "N":              {"min": 20,  "max": 500},
    "sigma":          {"min": 0,   "max": 5},
    "density_factor": {"min": 0.5, "max": 1.5}
  },
  "fitness": {
    "w_R": 1.0,
    "w_FWHM": 0.5,
    "R_min_threshold": 0.001,
    "polarization": "sp"
  },
  "optimizer": {
    "population": 50,
    "iterations": 5000,
    "tolerance": 1e-6,
    "stagnation_limit": 200,
    "w1": 0.4,
    "w2": 0.5,
    "jamming_max": 30,
    "checkpoint_every": 100
  },
  "substrate": "Si",
  "henke_path": null,
  "output_dir": "./results",
  "resume_from": null
}
```

**Field descriptions:**

- `targets` — array of target elements with their characteristic Ka wavelengths (Angstroms) and relative optimization weights. Neon (Ne) is excluded as it is a noble gas and not relevant for XRF analysis. Elements that also appear in `element_pool` (e.g., B, C) are valid — a boron-containing layer must handle self-absorption at the boron K-edge. Weights are relative multipliers on each element's contribution to the FoM sum (not normalized internally); setting B to 0.5 and C to 2.0 means C is 4x more important than B.
- `element_pool` — elements available for layer composition; Henke scattering factors must exist for each in the `Henke/` directory
- `structure.type` — `"bilayer"` for v1.0 (2 layers per period: reflector + spacer). Multilayer support (3-4 layers per period for modeling intermixed interfaces) is deferred to a future version.
- `structure.layers_per_period` — number of distinct layers in one period (always 2 for bilayer in v1.0)
- `structure.d` — period thickness range in Angstroms
- `structure.gamma` — reflector-to-period thickness ratio range
- `structure.N` — number of period repetitions range
- `structure.sigma` — interface roughness range in Angstroms
- `structure.density_factor` — thin-film density multiplier range (accounts for reduced density in sputtered films). Each layer role in the period gets its own density_factor gene (2 genes for bilayer).
- `substrate` — substrate material name (e.g., `"Si"`, `"SiO2"`, `"glass"`). Must have a Henke entry. The substrate is a semi-infinite bottom layer and is NOT optimized.
- `henke_path` — path to the Henke database directory. If `null`, defaults to `Henke/` relative to the executable location.
- `fitness.w_R` — weight for peak reflectivity in the Figure of Merit
- `fitness.w_FWHM` — weight for FWHM penalty in the Figure of Merit
- `fitness.R_min_threshold` — minimum acceptable peak reflectivity; solutions below this at any target wavelength receive a heavy penalty
- `fitness.polarization` — always `"sp"` (S+P averaged, matching spectrometer geometry)
- `optimizer.*` — LFPSO algorithm parameters (population size, iteration limit, convergence tolerance, stagnation detection, checkpoint interval)
- `output_dir` — directory for all output files
- `resume_from` — path to a checkpoint JSON file to resume a previous run, or `null` to start fresh

## Particle Genome

Each particle in the swarm represents one candidate Universal Mirror. The genome has two parts:

### Composition Genes

For each layer role in the bilayer period (reflector and spacer):
- An array of mixing fractions, one per element in the pool
- Example with pool `[W, Mo, V, Si, C, B, Ni, Ti]`: layer 1 gets 8 floats that are normalized to sum to 1.0
- Total composition genes: `2 * len(element_pool)` (e.g., 16 for 8-element pool)

### Structural Genes

Continuous parameters:
- `d` — period thickness (Angstroms), range from config
- `gamma` — reflector thickness ratio, range from config
- `N` — number of periods (integer, kept as float internally for PSO continuity, rounded for evaluation)
- `sigma` — interface roughness (Angstroms), range from config
- `density_factor_1`, `density_factor_2` — one density multiplier per layer role (2 genes for bilayer), range from config

### Derived Quantities (computed, not optimized)

- Per-layer thickness: reflector = `d * gamma`, spacer = `d * (1 - gamma)`
- Per-layer optical constants: from mixing fractions x Henke f1, f2 at each target wavelength
- Per-layer density: weighted average of elemental densities x density multiplier

### Constraints

- Composition fractions re-normalized to sum=1.0 after every PSO/Levy update
- If all fractions clamp to 0 (degenerate): reset to uniform 1/n_elements
- `N` rounded to nearest integer for evaluation
- Reflective boundaries on all parameters (particle bounces off min/max with 0.5x damped velocity)

## Multi-Wavelength Fitness Evaluation

### Step 1: Build Layer Array

The fitness unit constructs a `TLayers` array (array of `TLayer` records with fields `.e`, `.H`, `.s`) directly from the genome, without going through `TLayeredModel`. This is because `TLayeredModel` in the cmd version lacks a `Reset`/`Generate` method for swapping optical constants across wavelengths. The layer array is built once per particle per iteration, then `.e` (dielectric constant) values are recomputed for each target wavelength.

Layer structure:
- Layer 0: vacuum (e = 1+0i, H = 0)
- Layers 1..2*N: periodic bilayer (reflector, spacer) repeated N times
- Layer 2*N+1: substrate (e from Henke lookup, H = 1e8)

For each layer, compute effective scattering factors by weighted sum of per-element Henke f1, f2 values:
- Effective scattering factors: `f1_mix = Sum(fi * f1_i)`, `f2_mix = Sum(fi * f2_i)`
- Effective atomic mass: `A_mix = Sum(fi * Ai)`
- Effective density: `rho_mix = Sum(fi * rho_i) * density_factor`
- Compute intermediate: `c = ClassicalElectronRadius * rho_mix / A_mix * lambda^2`
- Dielectric constant: `eps.re = 1 - f1_mix * c`, `eps.im = f2_mix * c`

Note: `eps.im` is positive (absorption), matching the sign convention used throughout the codebase (see `unit_materials.pas` line 191-193). Do not negate f2.

This is the virtual crystal approximation — standard for multilayer design when measured optical constants for the exact alloy are unavailable.

### Step 2: Evaluate at Each Target Wavelength

For each target element (e.g., C Ka at 44.7 A):
1. Recompute `.e` values for all layers at that wavelength using cached Henke data
2. Check Bragg condition: `theta_B = arcsin(lambda / 2d)`. If `lambda/2d > 1`, no Bragg peak is possible — assign R_peak = 0
3. Run angular reflectivity scan using `cmd_unit_calc.TCalc`:
   - Scan range: `theta_B +/- 5 degrees` (adaptive: narrowed after early iterations)
   - Points: 200
   - K factor: 1 (theta mode, not 2theta)
   - Polarization: S+P averaged (cmSP)
   - Roughness function: Error function (rfError) — standard for sputtered multilayers
   - Convolution width (DT): 0 (no instrumental broadening — we want intrinsic mirror performance)
4. Extract R_peak (maximum reflectivity) and FWHM (angular width at half-maximum)

### FWHM Extraction

1. Find maximum R in the angular scan -> R_peak at theta_peak
2. Half-maximum level: R_half = R_peak / 2
3. Walk left and right from theta_peak to find crossing points by linear interpolation
4. FWHM = theta_right - theta_left (degrees)

### Step 3: Compute Scalar Figure of Merit

**The FoM is maximized** (higher is better). Internally the optimizer negates FoM for compatibility with the PSO minimization convention (lower is better). All comparisons for pbest/gbest use the negated value.

```
FoM = Sum_i [ weight_i * (w_R * R_peak(lambda_i) - w_FWHM * FWHM(lambda_i) / FWHM_ref(lambda_i)) ]
```

- `weight_i` — per-element weight from config (relative multiplier, not normalized)
- `w_R`, `w_FWHM` — global weights from `fitness` config section
- `FWHM_ref(lambda_i)` — kinematic diffraction limit: `FWHM_ref = lambda / (N_particle * d * cos(theta_B))` (in radians, converted to degrees). This uses the particle's own N and d values, normalizing FWHM penalty so it measures deviation from the theoretical best achievable resolution for that structure.

### Step 4: Penalty Terms

- If R_peak < `R_min_threshold` at any target wavelength: heavy penalty (the mirror "goes dark" — unacceptable)
- If any composition is fully degenerate (all fractions zero for all layers): mild penalty to encourage material diversity

### Parallelization

- Outer loop: particles distributed across threads via OmniThreadLibrary `Parallel.For` (OTL is already linked by xrccmd through `cmd_unit_calc.pas`). Note: the existing cmd fitting module runs sequentially; this is a new parallelization at the particle level, similar to the GUI LFPSO's `FindTheBest()`.
- Inner loop: target wavelengths evaluated sequentially per particle (they share the same layer structure, only `.e` values change per wavelength). Each thread owns its own `TLayers` array — no shared mutable state.

## Optimizer Engine

Standalone PSO/Levy flight implementation reusing the algorithmic principles from the existing LFPSO but with its own particle representation.

### Initialization

1. Create population of `Pop` particles with random genomes within bounds
2. Composition fractions: random, then normalized to sum=1.0
3. Structural params: uniform random within configured min/max
4. Evaluate all particles
5. Set pbest = initial position, gbest = best in population

### Main Loop (per iteration)

1. **Adaptive Levy/PSO switching** — probability schedule: more Levy early (exploration), more PSO late (convergence), stagnation boost
2. **Velocity update** — standard PSO terms (inertia + cognitive + social) or Levy flight step with adaptive scale (0.1 -> 0.01 over iterations)
3. **Constraint enforcement:**
   - Reflective boundaries on all parameters
   - Re-normalize composition fractions to sum=1.0
   - Round N to nearest integer for evaluation (keep float internally)
4. **Evaluate all particles** — parallel multi-wavelength fitness
5. **Update pbest, gbest, abest**
6. **Stagnation detection & shake** — diversity-aware: delay shake while population is diverse, re-initialize from gbest when stuck
7. **Progress reporting** — write iteration summary to stdout and log file

### Convergence Criteria

- Max iterations reached
- FoM hasn't improved by more than `tolerance` for `stagnation_limit` iterations
- User interrupt: register a `SetConsoleCtrlHandler` callback (Windows API) at startup that sets a `Terminated` flag. The main loop checks this flag each iteration and performs a clean checkpoint save before exiting.

### Checkpoint & Resume

- Every `checkpoint_every` iterations: dump full population state to `checkpoint.json`
  - All particle positions, velocities, pbest, gbest, abest
  - Iteration counter, best FoM history
- Resume mode: load checkpoint, continue optimization from saved state

## Mixed-Material Optical Constants

New shared unit `unit_materials_mix.pas` for computing optical constants of arbitrary elemental mixtures.

For a layer with fractions `[f_W=0.6, f_C=0.4]` at wavelength lambda:

1. Query Henke database for each element: `(f1_W, f2_W)`, `(f1_C, f2_C)`
2. Weighted scattering factors: `f1_mix = 0.6*f1_W + 0.4*f1_C` (same for f2)
3. Effective atomic mass: `A_mix = Sum(fi * Ai)`
4. Effective bulk density: `rho_mix = Sum(fi * rho_i) * density_factor`
5. Dielectric constant: `eps = 1 - (r_e * rho_mix * lambda^2 / A_mix) * (f1_mix - i*f2_mix)`

### Henke Caching

At startup:
1. Read each element's Henke file once to get wavelength-independent data: `atomic_mass`, `bulk_density`. Store in `[element_idx] -> (A, rho)`. This requires only `len(element_pool) + 1` file reads (pool elements + substrate).
2. Query f1, f2 at each target wavelength for each element. Store in `[element_idx, target_idx] -> (f1, f2)`. This is computed from the already-loaded Henke data via interpolation.

Total: one file read per element, zero file I/O during optimization.

Henke files are located via `henke_path` config field. If null, defaults to `Henke/` relative to the executable directory (using `ExtractFilePath(ParamStr(0))`).

## Output

All files written to `output_dir/`.

### Console Output (stdout)

```
Universal Mirror Optimizer v1.0
Targets: Be(114A) B(67.6A) C(44.7A) N(31.6A) O(23.6A) F(18.3A) Na(11.9A) Mg(9.89A)
Pool: W Mo V Si C B Ni Ti
Structure: bilayer, d=[10..120], N=[20..500]
Population: 50, Max iterations: 5000
---
Iter    FoM      R_Be   R_B    R_C    R_N    R_O    R_F    R_Na   R_Mg   Div
   1   0.0234   0.00   0.01   0.03   0.02   0.01   0.00   0.00   0.00   0.95
  10   0.1872   0.02   0.08   0.12   0.15   0.09   0.04   0.02   0.01   0.82
 100   0.4521   0.05   0.15   0.28   0.32   0.21   0.12   0.08   0.05   0.54
 ...
```

### Output Files

| File | Description |
|------|-------------|
| `progress.log` | Per-iteration: iteration, FoM, per-element R and FWHM, diversity, mean velocity |
| `best_structure.json` | Winning structure in xrc_cmd-compatible JSON format (can be opened in X-RayCalc3 GUI) |
| `best_curves/<Element>.dat` | One reflectivity curve file per target wavelength (angle vs reflectivity, tab-separated) |
| `population.json` | Top-N diverse high-scoring solutions found during the run with their per-element metrics |
| `checkpoint.json` | Full optimizer state for resume |

### best_structure.json Format

Compatible with existing xrc_cmd JSON loader:

```json
{
  "name": "Universal Mirror - Optimized",
  "optimizer_result": {
    "FoM": 0.4521,
    "composition": {
      "layer_1": {"W": 0.45, "Mo": 0.15, "V": 0.10, "Si": 0.30},
      "layer_2": {"C": 0.60, "B": 0.25, "Si": 0.15}
    },
    "d": 42.5,
    "gamma": 0.35,
    "N": 200,
    "sigma": 1.2,
    "per_element": {
      "Be": {"R_peak": 0.05, "FWHM": 2.1},
      "B":  {"R_peak": 0.15, "FWHM": 1.8},
      "C":  {"R_peak": 0.28, "FWHM": 1.2}
    }
  },
  "structure": [
    {"top": {"N": 200, "layers": [
      {"W0.45Mo0.15V0.10Si0.30": [14.875, 1.2, 12.5]},
      {"C0.60B0.25Si0.15":       [27.625, 1.2, 2.8]}
    ]}},
    {"bottom": {"N": 1, "layers": [
      {"substrate": [0, 1, 8.0]}
    ]}}
  ]
}
```

## Performance

### Cost Estimate

Per particle per iteration:
- 8 target wavelengths x 200-point angular scan x Fresnel recursion through N layers (100-500)
- ~8 x 200 x 500 = 800K Fresnel recursions per particle
- With 50 particles: ~40M recursions per iteration

### Optimizations

1. **Henke caching** — pre-query all elements at all target wavelengths at startup. Zero file I/O during optimization.
2. **Model reuse** — layer structure (N periods, same sequence) is identical across target wavelengths. Build `TLayers` array once per particle (thicknesses, roughnesses), then swap only `.e` (dielectric constant) values per target wavelength before calling RefCalc.
3. **Parallel evaluation** — distribute particles across threads via OTL. With 50 particles and 8 cores: ~6 particles per core per iteration.
4. **Adaptive scan range** — after early iterations when approximate d is known, narrow angular scan window around expected Bragg peak.
5. **Early termination** — if `lambda/2d > 1` (no Bragg condition possible), skip full calculation and assign R_peak = 0.

### Estimated Runtime

- Single Fresnel recursion ~1us (500 layers, complex arithmetic)
- Per iteration: ~40M x 1us / 8 cores ~ 5 seconds
- 5000 iterations ~ 7 hours
- Checkpoint/resume makes overnight runs practical

## Code Organization

### New Files

| File | Purpose |
|------|---------|
| `XRC_CMD/units/cmd_unit_universal.pas` | Main orchestrator: parse config, run optimization loop, write output |
| `XRC_CMD/units/cmd_unit_universal_types.pas` | Types: TParticle, TGenome, TTargetElement, TUniversalConfig, TOptState |
| `XRC_CMD/units/cmd_unit_universal_fitness.pas` | Multi-wavelength fitness: build model from genome, compute R/FWHM per target, calculate FoM |
| `XRC_CMD/units/cmd_unit_universal_pso.pas` | PSO/Levy flight engine: velocity update, boundary handling, composition normalization, shake |
| `XRC_CMD/units/cmd_unit_universal_io.pas` | I/O: config loading, checkpoint save/load, progress logging, result export |
| `Math/unit_materials_mix.pas` | Mixed-material optical constants: weighted Henke f1/f2, density from elemental fractions |

### Modified Files

| File | Change |
|------|--------|
| `XRC_CMD/xrccmd.dpr` | Add `-u` switch and dispatch to `cmdUniversalMirror()` |

### Reused Without Changes

| File | What We Use |
|------|-------------|
| `XRC_CMD/units/cmd_unit_calc.pas` | TCalc for reflectivity computation (RefCalc, angular scans) |
| `XRC_CMD/units/cmd_math_globals.pas` | ReadHenke() for per-element scattering factors at startup |
| `XRC_CMD/units/cmd_unit_helpers.pas` | File I/O utilities |

Note: `cmd_unit_materials.pas` (`TLayeredModel`) is NOT used. The fitness unit builds `TLayers` arrays directly from the genome, bypassing `TLayeredModel` which lacks the ability to swap optical constants across wavelengths without full rebuild.

### Dependency Flow

```
xrccmd.dpr
  +-- cmd_unit_universal              (orchestrator)
       +-- cmd_unit_universal_types
       +-- cmd_unit_universal_fitness
       |    +-- unit_materials_mix     (mixed Henke computation + caching)
       |    +-- cmd_unit_calc          (TCalc - reflectivity)
       |    +-- cmd_math_globals       (ReadHenke - startup only)
       +-- cmd_unit_universal_pso      (optimizer engine)
       +-- cmd_unit_universal_io       (config, checkpoint, output)
```

## Future Extensions

The design supports future evolution without architectural changes:

- **Multilayer structure type**: Add `"type": "multilayer"` with `layers_per_period` > 2 to model intermixed interfaces. Requires additional genome genes for per-layer thickness ratios (replacing the single gamma parameter) and additional composition gene arrays. The config schema already has the `type` and `layers_per_period` fields reserved.
- **Pareto multi-objective (NSGA-II)**: Replace the scalar FoM in the fitness unit with non-dominated sorting and crowding distance. The particle representation and evaluation pipeline remain unchanged. The `population.json` output would then contain true Pareto-front solutions.
- **GUI integration**: The optimizer output (best_structure.json) is already compatible with the X-RayCalc3 GUI. A future GUI panel could launch xrccmd as a subprocess and monitor progress.log in real-time.
- **Aperiodic/depth-graded structures**: Per-layer thickness genes instead of d+gamma, enabling chirped mirror designs.
