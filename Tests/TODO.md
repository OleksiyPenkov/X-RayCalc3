# Test Coverage TODO

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Add tests for remaining `math_complex` functions — 29 tests added, 3 bugs found (PowZR2 recursion, TanhZ denominator, ArcSinZ domain) | 🟡 M | ✅ Done |
| 2 | Add tests for `math_globals` — CopyData, FuncProfile, Poly(FuncProfileRec) (Sort skipped — needs TLineSeries, Interp is private) | 🟢 S | ✅ Done |
| 3 | Add tests for `math_globals` — ReadHenke, ReadHenkeTable, WriteHenkeTable — 8 tests (real DB + roundtrip + interpolation + error handling) | 🟡 M | ✅ Done |
| 4 | Add tests for `unit_helpers` — Normalize, NormalizeAuto, ManualMerge (AutoMerge needs GetDevider — private) | 🟡 M | ✅ Done |
| 5 | Add tests for `unit_helpers` — SeriesToData, DataToSeries + roundtrip | 🟢 S | ✅ Done |
| 6 | Add tests for `unit_helpers` — SeriesToFile, SeriesFromFile, Clipboard, SeriesToString, DataToFile — 8 tests (file I/O roundtrip, comment/header parsing, clipboard with graceful skip) | 🟡 M | ✅ Done |
| 7 | Add tests for `unit_Types` — TProjectData (IsModel, PolyD/SetPoly), TFitStructure.CopyContent | 🟡 M | ✅ Done |
| 8 | Add tests for `unit_Types` — `TFuncProfileRec` (X, Ord, PIndex) | 🟢 S | ✅ Done |
| 9 | Add tests for `unit_calc` — TCalc constructor, ExpValues. RefCalc/CalcTet private + needs Henke DB | 🟠 L | ✅ Done |
| 10 | Add tests for `unit_calc` — RefCalc, CalcTet, CalcLambda — 7 tests (physics validation, grid, UseData, wavelength scan) | 🟠 L | ✅ Done |
| 11 | Add tests for `unit_materials` — TLayeredModel Init, AddLayers, AddSubstrate, full assembly | 🟠 L | ✅ Done |
| 12 | Add tests for `unit_Config` — RTTI defaults + write/read roundtrip (int/bool/string) | 🟡 M | ✅ Done |
| 13 | Add tests for `unit_LFPSO_Base` — 27 tests (Gamma, MultiplyVector, RS, SolutionToString, Omega, SetParams, SetDomain, Init_Domains, Set_Init_X, CheckLimits, ApplyCFactor, Rand, LevyWalk, UpdateStructure, FitModelToLayer, Terminate) | 🔴 XL | ✅ Done |
| 14 | Add tests for `unit_LFPSO_Periodic` / `unit_LFPSO_Irregular` — 24 tests (SetStructure, NormalizeD, InitVelocity, XSeed, RangeSeed, linking, smoothies) | 🔴 XL | ✅ Done |
| 15 | Add tests for `unit_SavitzkyGolay` — 4 tests, found off-by-one bug in loop bounds | 🟢 S | ✅ Done |
