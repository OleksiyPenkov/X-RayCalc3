# X-RayCalc3 — TODO

## Fitting Engine (LFPSO)

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~1~~ | ~~Eliminate excessive `Copy()` in population management~~ | ~~🟡 M~~ | Done — `04c8bb2` added `CopySolution()` deep-copy helper; dead `CalcSolution` removed |
| ~~2~~ | ~~Batch UI update messages during fitting — throttle `PostMessage` to 10-20/sec~~ | ~~🟢 S~~ | Deferred |
| ~~3~~ | ~~Implement adaptive velocity coefficient (`CFactor`)~~ | ~~🟡 M~~ | Done — `f866b42` linearly decreases CFactor from (w1+w2) to w1 |
| ~~4~~ | ~~Replace `Application.ProcessMessages` with async pattern (`TThread.Queue` or OTL Comm) — re-entrancy risk~~ | ~~🟡 M~~ | Done — `a02281b` moved fitting to background thread with OTL message pump |

## Calculation Engine

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~5~~ | ~~SoA layout for inner `RefCalc` loop — full Structure-of-Arrays for hot path (e, L, s, ro) for better x64 vectorization~~ | ~~🟡 M~~ | Done — `de34747` added `TCalcModelSoA`/`TCalcScratchSoA`, rewrote `RefCalc` |
| ~~6~~ | ~~Hash-map profile function lookup — `TProfileFunctions` searched O(n) per layer by `(StackID, LayerID)`. Replace with `TDictionary`~~ | ~~🟡 M~~ | Done — `7ce344c` added `FProfileIndex` dictionary to `TLayeredModel` and `TProfileManager` |
| ~~7~~ | ~~Parameterize convolution window size (currently hardcoded W=10) — allow users to trade smoothness vs. speed~~ | ~~🟢 S~~ | Done — `MVAWindow` field on `TCalcThreadParams`, default 10 |

## Main Form Decoupling

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~8~~ | ~~Extract Benchmark/Batch Jobs → `TBatchRunner` class~~ | ~~🟢 S~~ | Done — `f852718` created `unit_BatchRunner.pas` |
| ~~9~~ | ~~Extract Project File I/O~~ | ~~🟡 M~~ | Done — extracted to `frame_ProjectPanel`; form has thin wrappers |
| ~~10~~ | ~~Extract Data Curve Operations~~ | ~~🟢 S~~ | Done — delegated to `frame_ChartInfo`/`frame_ProjectPanel` |
| ~~11~~ | ~~Extract Profile Extensions CRUD~~ | ~~🟢 S~~ | Done — delegated to `frame_ProjectPanel` |
| ~~12~~ | ~~Extract Fitting/LFPSO orchestration~~ | ~~🟡 M~~ | Done — `47d54f6` created `TCalcOrchestrator` |

## Code Cleanup

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~13~~ | ~~Replace fragile `Poly[0..10]` encoding — index 10 used as length marker. Use struct with explicit `Count` field~~ | ~~🟡 M~~ | Done — `f67355a` added explicit `PolyCount` field |
| ~~14~~ | ~~Fix `TConfig` misleading instance — `Create` is no-op, all state is `class var`. Remove fake instance~~ | ~~🟢 S~~ | Done — `f852718` removed fake instance, all access via `TConfig.` |
| ~~15~~ | ~~Unify `PeriodAddExecute` / `PeriodInsertExecute` — only 4-line difference~~ | ~~🟢 S~~ | Done — `f852718` extracted `DoAddStack` helper |
| ~~16~~ | ~~Unify `DataLoadExecute` / `DataPasteExecute` — different node placement logic~~ | ~~🟢 S~~ | Done — `f852718` extracted `CreateDataNode` helper |

## UI & I/O

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~17~~ | ~~Bulk chart data insertion with `AddArray` — replace per-point `AddXY` loop~~ | ~~🟢 S~~ | Done — `f852718` bulk `SetLength` + direct array fill |
| ~~18~~ | ~~Binary serialization for project internals — replace INI `StrToFloat` parsing~~ | ~~🟡 M~~ | Dropped — backward compatibility risk outweighs benefit |

## New Features

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~19~~ | ~~Fitting convergence history / diagnostics panel — Chi² vs. iteration, particle diversity, velocity stats~~ | ~~🟡 M~~ | Done — `13cc5c8` added Diagnostics tab with real-time LFPSO metrics |
| 20 | Multi-start fitting with result comparison — N independent runs, top-K ranked by Chi² | 🟡 M | |
| 21 | Export fitting results to JSON/CSV — full metadata for Python/MATLAB interop | 🟢 S | |

## XRFCalc (Universal Mirror GUI)

| # | Task | Size | Notes |
|---|------|------|-------|
| ~~22~~ | ~~Standalone VCL GUI app for multi-target multilayer mirror optimization~~ | ~~🔴 L~~ | Done — XRFCalc project with config UI, live charts, threaded optimizer |
| 23 | Allow user-defined elements not in the checklist — editable element pool | 🟢 S | Currently limited to hardcoded checklist |
| 24 | Log panel — show optimizer text output in a memo instead of only file | 🟡 M | |
| 25 | Structure visualization — layer stack diagram showing d, gamma, N, materials | 🟡 M | |
| 26 | Comparison mode — overlay curves from multiple runs | 🟡 M | |
| 27 | Parameter sensitivity display — show how FoM changes near optimum | 🟡 M | |
