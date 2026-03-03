# X-RayCalc3 — Optimization & Feature TODO

## High Impact — Fitting Engine (LFPSO)

- [ ] **Eliminate excessive `Copy()` in population management**
  The optimizer does deep copies of solutions (`Copy(X[...], 0, MaxInt)`) on every fitness evaluation in `unit_LFPSO_Base.pas`. Implement an object pool or in-place swap pattern to reduce GC pressure and allocation overhead. Key lines: 327, 397-406, 401.

- [ ] **Batch UI update messages during fitting**
  `PostMessage` fires every N iterations (lines 663-668 in `unit_LFPSO_Base.pas`) with a full structure copy. Throttle to 10-20 updates/sec or coalesce multiple iterations into one message.

- [ ] **Thread-local material cache in LFPSO workers**
  `FMaterials` is shared across worker threads without synchronization (lines 437-438, 476-477 in `unit_LFPSO_Base.pas`) — a latent data race. Move to thread-local copies (one per `TCalcWorker`).

- [ ] **Lazy `FillModel` allocation sized to actual layer count**
  `FillModel` (lines 275-310 in `unit_LFPSO_Base.pas`) allocates `Data` array sized to the maximum possible stack depth. Size to actual layer count to save memory proportional to `(MaxLayers - ActualLayers) * PopulationSize`.

## Medium Impact — Calculation Engine

- [ ] **Persistent thread pool for `TCalc`**
  `Parallel.ForEach` in `RefCalc` (`unit_calc.pas` line 334) recreates tasks per calculation. Use a cached/persistent thread pool (`IOmniThreadPool`) to eliminate per-run thread creation overhead.

- [ ] **Parameterize convolution window size (currently hardcoded W=10)**
  Convolution window size is hardcoded in `unit_calc.pas` (lines 511-565). Make configurable to allow users to trade smoothness vs. speed.

- [ ] **SoA layout for inner `RefCalc` loop**
  Recent commit moved cold fields to parallel arrays. Next step: full Structure-of-Arrays for the hot path (e, L, s, ro) to enable better vectorization on x64.

## Medium Impact — Data & Lookup

- [ ] **Hash-map profile function lookup**
  `TProfileFunctions` is searched O(n) per layer by `(StackID, LayerID)` in `unit_materials.pas` (lines 176-184). Replace with `TDictionary` for O(1) lookup.

- [ ] **Implement adaptive velocity coefficient (`CFactor`) in PSO**
  Line 482 in `unit_LFPSO_Base.pas` has `CFactor := 1; // left for future`. Implement adaptive inertia weight (e.g., linearly decreasing 0.9 to 0.4) — typically accelerates convergence 20-40%.

## Lower Impact — UI & I/O

- [ ] **Bulk chart data insertion with `AddArray`**
  Replace per-point `AddXY` loops in `TChartManager.PlotResults` (`unit_ChartManager.pas` lines 82-93) with TeeChart's `AddArray` or direct `XValues`/`YValues` array assignment.

- [ ] **Replace `Application.ProcessMessages` with async pattern**
  `ProcessMessages` calls in the fitting loop (lines 479, 669 in `unit_LFPSO_Base.pas`) risk re-entrancy and UI stuttering. Use `TThread.Queue` or OTL's `Comm` channel instead.

- [ ] **Binary serialization for project internals**
  The INI-based `params.dsc` uses `StrToFloat` parsing in loops (`unit_Types.pas` line 339). Implement binary format for internal structure data to speed up load/save.

## New Features

- [ ] **Fitting convergence history / diagnostics panel**
  Track and display Chi² vs. iteration, particle diversity, and velocity statistics. Helps users understand fitting behavior and tune parameters.

- [ ] **Multi-start fitting with result comparison**
  Run N independent PSO optimizations and present top-K results ranked by Chi². Catches local minimum traps.

- [ ] **Export fitting results to JSON/CSV**
  Add JSON export with full metadata (layer parameters, fit quality, settings) to improve interoperability with Python/MATLAB post-processing workflows.
