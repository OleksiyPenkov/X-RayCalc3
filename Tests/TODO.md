# Test Coverage TODO

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Add tests for remaining `math_complex` functions — 29 tests added, 3 bugs found (PowZR2 recursion, TanhZ denominator, ArcSinZ domain) | 🟡 M | ✅ Done |
| 2 | Add tests for `math_globals` — CopyData, FuncProfile, Poly(FuncProfileRec) (Sort skipped — needs TLineSeries, Interp is private) | 🟢 S | ✅ Done |
| 3 | Add tests for `math_globals` — `ReadHenke`, `ReadHenkeTable`, `WriteHenkeTable` | 🟡 M | ⏸️ Deferred |
| 4 | Add tests for `unit_helpers` — Normalize, NormalizeAuto, ManualMerge (AutoMerge needs GetDevider — private) | 🟡 M | ✅ Done |
| 5 | Add tests for `unit_helpers` — SeriesToData, DataToSeries + roundtrip | 🟢 S | ✅ Done |
| 6 | Add tests for `unit_helpers` — `SeriesToClipboard`, `SeriesFromClipboard`, `SeriesToFile`, `SeriesFromFile` | 🟡 M | ⏸️ Deferred |
| 7 | Add tests for `unit_Types` — TProjectData (IsModel, PolyD/SetPoly), TFitStructure.CopyContent | 🟡 M | ✅ Done |
| 8 | Add tests for `unit_Types` — `TFuncProfileRec` (X, Ord, PIndex) | 🟢 S | ✅ Done |
| 9 | Add tests for `unit_calc` — TCalc constructor, ExpValues. RefCalc/CalcTet private + needs Henke DB | 🟠 L | ✅ Done |
| 10 | Add tests for `unit_calc` — CalcLambda, CalcTet (private, needs Henke DB) | 🟠 L | ⏸️ Deferred |
| 11 | Add tests for `unit_materials` — TLayeredModel Init, AddLayers, AddSubstrate, full assembly | 🟠 L | ✅ Done |
| 12 | Add tests for `unit_Config` — RTTI-based option loading/saving | 🟡 M | 🔴 Open |
| 13 | Add tests for `unit_LFPSO_Base` — particle swarm optimizer core logic | 🔴 XL | 🔴 Open |
| 14 | Add tests for `unit_LFPSO_Periodic` / `unit_LFPSO_Irregular` — structure-specific PSO | 🔴 XL | 🔴 Open |
| 15 | Add tests for `unit_SavitzkyGolay` — 4 tests, found off-by-one bug in loop bounds | 🟢 S | ✅ Done |
