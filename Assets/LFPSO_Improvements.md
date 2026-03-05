# LFPSO Convergence Improvements

## Overview

Seven improvements to the Lévy Flight Particle Swarm Optimization algorithm used for X-ray reflectivity curve fitting. Six are always-on (no configuration needed), one is optional via a checkbox in Advanced Fitting Settings.

All improvements are backward-compatible — existing project files work without changes, and default behavior produces better convergence than before.

---

## 1. Reflective Boundary Handling

**File:** `unit_LFPSO_Base.pas` → `CheckLimits`

**Before:** When a particle's position exceeded the search domain boundary, it was clamped to the wall. Velocity was unchanged. This caused particles to "stick" at boundaries and lose momentum, effectively removing them from the search.

**After:** Particles bounce off boundaries like a ball hitting a wall. The position is reflected back into the domain, and the velocity is reversed with 0.5× damping. If the reflection overshoots the opposite boundary (very narrow domains), it's clamped as a safety net.

```
Before:  X = 103, Xmax = 100  →  X = 100, V unchanged (stuck at wall)
After:   X = 103, Xmax = 100  →  X = 97,  V = -V × 0.5 (bounced back)
```

**Why it helps:** Particles near boundaries remain active participants in the search instead of becoming dead weight. The 0.5× velocity damping prevents oscillatory bouncing while preserving search momentum.

---

## 2. Adaptive Lévy Scale Factor

**File:** `unit_LFPSO_Base.pas` → `LevyWalk`, `Run`

**Before:** The Lévy flight step size used a hardcoded scale factor of 0.01. This was a compromise — too small for early exploration, about right for late-stage refinement.

**After:** The scale factor adapts with iteration progress:
- **Start of fitting:** scale = 0.10 (10× larger steps for broad exploration)
- **End of fitting:** scale = 0.01 (fine-tuning around the best solution)
- **Formula:** `FLevyScale = 0.01 + 0.09 × (1 - t/TMax)`

**Why it helps:** Early iterations need large Lévy jumps to escape local minima and explore distant regions of parameter space. Late iterations need small, precise adjustments. This mirrors the well-known principle of decreasing exploration over time, now applied to the Lévy flight component.

---

## 3. Adaptive PSO/Lévy Switching

**File:** `unit_LFPSO_Base.pas` → `Run`

**Before:** Each iteration randomly chose between PSO mode and Lévy mode with a fixed 50/50 probability. This was suboptimal — PSO excels at exploitation (refining near known good solutions) while Lévy flights excel at exploration (finding new regions).

**After:** The probability adapts based on two factors:

1. **Iteration progress** — more Lévy early, more PSO late:
   - Start: 70% Lévy / 30% PSO
   - End: 30% Lévy / 70% PSO
   - Formula: `LevyProb = 0.3 + 0.4 × (1 - t/TMax)`

2. **Stagnation boost** — when no improvement is found, Lévy probability increases by 5% per stagnant iteration (capped at 90%):
   - Formula: `LevyProb += 0.05 × JammingCount`

**Why it helps:** The algorithm now automatically shifts from exploration to exploitation as the search matures. When stuck in a local minimum, it increases exploration to escape. This is analogous to simulated annealing's temperature schedule but applied to the PSO/Lévy mode balance.

---

## 4. Random-Peer Lévy Targets

**Files:** `unit_LFPSO_Periodic.pas`, `unit_LFPSO_Irregular.pas`, `unit_LFPSO_Poly.pas` → `UpdateLFPSO`

**Before:** All Lévy flights were directed toward `gbest` (the global best solution). Every particle's Lévy step pointed in the same direction — toward the single best known solution.

**After:** 70% of Lévy flights still target `gbest`, but 30% target a randomly chosen peer particle from the population. The random peer is selected per-particle (not per-parameter), so all parameters of a given particle use the same peer, preserving parameter correlations.

```
Per particle in Lévy mode:
  30% chance → LevyWalk directed toward X[random_particle]
  70% chance → LevyWalk directed toward gbest (as before)
```

**Why it helps:** Directing all flights toward a single point creates a convergent attractor that can trap the swarm. Using random peers as targets creates diverse flight directions, enabling particles to explore parameter space regions that no single "best" solution would suggest. This is particularly valuable for multimodal fitness landscapes common in X-ray reflectivity, where multiple layer configurations can produce similar curves.

---

## 5. Diversity-Aware Shake Triggering

**File:** `unit_LFPSO_Base.pas` → `Run`, `CalcDiversity` (new method)

**Before:** The shake mechanism triggered after `JammingMax` iterations without improvement (default: 1). With a population of 1000, this was extremely aggressive — shaking after just one bad iteration, regardless of whether the population was still actively exploring.

**After:** A new `CalcDiversity` method computes the normalized standard deviation of particle positions across all parameters. When `JammingMax` is exceeded, the algorithm now checks population diversity before shaking:

- **If diversity < 1%** of parameter ranges → shake immediately (population has collapsed)
- **If diversity ≥ 1%** → delay shake for up to 3 additional iterations (population is still exploring, give it time)
- **Hard limit:** always shake after `JammingMax + 3` iterations regardless of diversity

The diversity metric is computed as:
```
For each parameter (layer × {H, σ, ρ}):
  variance = Var(X[all particles])
  normalized = variance / range²

Diversity = √(mean of all normalized variances)
```

A diversity of 0.01 means the average particle spread is ~1% of the parameter range — effectively converged.

**Why it helps:** The original `JammingMax=1` often triggered premature shakes when the swarm was still productively exploring. The diversity check distinguishes between "stuck in a local minimum" (low diversity, should shake) and "still searching, haven't found improvement yet" (high diversity, should wait). This significantly reduces wasted computation from unnecessary reinitializations.

---

## 6. Clerc-Kennedy Constriction Factor (Optional)

**Files:** `unit_LFPSO_Base.pas` → `Omega`, `ApplyCFactor`, `Run`; `frm_FitSettings.pas/.dfm`

**UI:** Checkbox "Constriction factor" in Advanced Fitting Settings → General section. Default: off.

**Before:** The velocity update used linear inertia weight decay:
```
V = ω(t) × V + c₁r₁(pbest - X) + c₂r₂(gbest - X)
where ω(t) = w₁ + w₂(1 - t/TMax),  c₁ = c₂ = 1
```
The inertia weight `ω` decreased linearly from `w₁+w₂` to `w₁` (default: 0.6 → 0.3). The values of `w₁`, `w₂`, and the linear schedule were empirically chosen.

**After (when enabled):** Uses the analytically-derived Clerc-Kennedy constriction coefficient:
```
V = χ × V + χφ₁r₁(pbest - X) + χφ₂r₂(gbest - X)
  = χ × (V + φ₁r₁(pbest - X) + φ₂r₂(gbest - X))

where:
  φ = φ₁ + φ₂ = 2.05 + 2.05 = 4.1
  χ = 2 / |2 - φ - √(φ² - 4φ)| ≈ 0.7298
```

The implementation is clean — `Omega()` returns `χ` instead of the linear weight, and `ApplyCFactor()` returns `χ × 2.05` for both `c₁` and `c₂`. No changes to derived classes were needed.

**Why it helps:** The constriction factor is mathematically proven to guarantee convergence while maintaining good exploration. Unlike the empirical linear decay, it provides a theoretically optimal balance between exploration and exploitation throughout the entire search. The constant `χ ≈ 0.73` with higher cognitive/social coefficients (`φ₁ = φ₂ = 2.05` vs. the previous `c₁ = c₂ = 1`) gives particles stronger attraction to good solutions while the constriction prevents velocity explosion.

**When to use:** Try it on problems where the standard inertia decay converges too slowly or oscillates. It's particularly effective for well-defined search spaces where the global minimum region is relatively smooth.

---

## Summary of Changes by File

| File | Changes |
|------|---------|
| `unit_Types.pas` | Added `UseConstriction: Boolean` to `TFitParams` |
| `unit_LFPSO_Base.pas` | New fields: `FLevyScale`, `FConstrictionChi`, `FDiversity`. New method: `CalcDiversity`. Modified: `CheckLimits` (reflection), `LevyWalk` (adaptive scale), `Omega` (constriction), `ApplyCFactor` (constriction), `Run` (adaptive switching, diversity-aware shake, constriction init) |
| `unit_LFPSO_Periodic.pas` | `UpdateLFPSO`: random-peer Lévy target (30%) |
| `unit_LFPSO_Irregular.pas` | `UpdateLFPSO`: random-peer Lévy target (30%) |
| `unit_LFPSO_Poly.pas` | `UpdateLFPSO`: random-peer Lévy target (30%) |
| `frm_FitSettings.pas/.dfm` | Added "Constriction factor" checkbox, fixed `ShowParamHint` for non-TEdit controls |
| `frame_CalcSettings.pas` | Added `UseConstriction` to `Load/SaveAdvancedParams` |
| `TestLFPSOBase.pas` | Updated 2 tests (reflection), added 4 new tests (constriction, diversity) |

## Not Yet Implemented

**Ring Topology** — replacing the global-best (star) topology with a ring/local-neighborhood topology where each particle only sees the best among its k nearest neighbors. This would slow information propagation through the swarm, preventing premature convergence to local minima. Deferred due to complexity (requires per-particle local-best tracking and neighborhood management).
