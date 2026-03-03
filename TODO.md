# X-RayCalc3 — TODO

## Fitting Engine (LFPSO)

| # | Task | Size | Notes |
|---|------|------|-------|
| 1 | Eliminate excessive `Copy()` in population management — `Copy(X, 0, MaxInt)` on pbest update. Use object pool or in-place swap | 🟡 M | `unit_LFPSO_Base.pas:411` |
| 2 | Batch UI update messages during fitting — throttle `PostMessage` to 10-20/sec | 🟢 S | `unit_LFPSO_Base.pas:680` |
| 3 | Implement adaptive velocity coefficient (`CFactor`) — currently hardcoded to 1. Linearly decrease 0.9→0.4 for 20-40% faster convergence | 🟡 M | `unit_LFPSO_Base.pas:494` |
| 4 | Replace `Application.ProcessMessages` with async pattern (`TThread.Queue` or OTL Comm) — re-entrancy risk | 🟡 M | Lines 490, 680, 700 |

## Calculation Engine

| # | Task | Size | Notes |
|---|------|------|-------|
| 5 | SoA layout for inner `RefCalc` loop — full Structure-of-Arrays for hot path (e, L, s, ro) for better x64 vectorization | 🟡 M | `unit_calc.pas` |
| 6 | Hash-map profile function lookup — `TProfileFunctions` searched O(n) per layer by `(StackID, LayerID)`. Replace with `TDictionary` | 🟡 M | `unit_materials.pas` |
| 7 | Parameterize convolution window size (currently hardcoded W=10) — allow users to trade smoothness vs. speed | 🟢 S | `unit_calc.pas` |

## Main Form Decoupling

| # | Task | Size | Notes |
|---|------|------|-------|
| 8 | Extract Benchmark/Batch Jobs → `TBatchRunner` class | 🟢 S | Tightly coupled to form actions |
| 9 | Extract Project File I/O → `TProjectFileManager` class | 🟡 M | Tightly coupled to form state |
| 10 | Extract Data Curve Operations | 🟢 S | Action handlers must stay on form |
| 11 | Extract Profile Extensions CRUD | 🟢 S | Coupled to Project tree + Structure |
| 12 | Extract Fitting/LFPSO orchestration | 🟡 M | Tightly coupled to form state |

## Code Cleanup

| # | Task | Size | Notes |
|---|------|------|-------|
| 13 | Replace fragile `Poly[0..10]` encoding — index 10 used as length marker. Use struct with explicit `Count` field | 🟡 M | `unit_Types.pas:65-66` |
| 14 | Fix `TConfig` misleading instance — `Create` is no-op, all state is `class var`. Remove fake instance | 🟢 S | `frm_Main.pas`, `unit_Config.pas` |
| 15 | Unify `PeriodAddExecute` / `PeriodInsertExecute` — only 4-line difference | 🟢 S | `frm_Main.pas` |
| 16 | Unify `DataLoadExecute` / `DataPasteExecute` — different node placement logic | 🟢 S | `frm_Main.pas` |

## UI & I/O

| # | Task | Size | Notes |
|---|------|------|-------|
| 17 | Bulk chart data insertion with `AddArray` — replace per-point `AddXY` loop | 🟢 S | `unit_ChartManager.pas:91` |
| 18 | Binary serialization for project internals — replace INI `StrToFloat` parsing | 🟡 M | `unit_Types.pas` |

## New Features

| # | Task | Size | Notes |
|---|------|------|-------|
| 19 | Fitting convergence history / diagnostics panel — Chi² vs. iteration, particle diversity, velocity stats | 🟡 M | |
| 20 | Multi-start fitting with result comparison — N independent runs, top-K ranked by Chi² | 🟡 M | |
| 21 | Export fitting results to JSON/CSV — full metadata for Python/MATLAB interop | 🟢 S | |
