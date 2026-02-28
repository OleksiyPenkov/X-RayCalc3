# Refactoring & Optimization TODO

## Bugs

| # | Task | Size | Status |
|---|------|------|--------|
| 1 | Fix `DivRZ` wrong formula — returns `(R/Z.Re, R/Z.Im)` when both nonzero, correct is `R*(x-yi)/(x²+y²)`. CMD now shares fix via `math_complex.pas` (`math_complex.pas:313-322`) | 🟢 S | ✅ Done |
| 2 | Fix `SqrtZ(0,0)` returns `(1,0)` instead of `(0,0)` (`math_complex.pas:534-535`) | 🟢 S | ✅ Done |
| 3 | Fix `PowZR2` infinite recursion — `PowZR2` → `PowZZ` → `PowZR2` when Z2.Im=0. Now computes directly via exp/ln (`math_complex.pas:580-583`) | 🟡 M | ✅ Done |
| 4 | Fix `TanhZ` swapped denominator — uses `cos(x)+cosh(y)` but correct is `cosh(x)+cos(y)` (`math_complex.pas:461-469`) | 🟢 S | ✅ Done |
| 5 | Fix `Smooth` — `.t` values never set in output array, all zero (`unit_helpers.pas:109-140`) | 🟢 S | ✅ Done |
| 6 | Fix `FillElementsList` — missing `FindClose(F)` after `FindFirst/FindNext`, file handle leak (`unit_helpers.pas:245-249`) | 🟢 S | ✅ Done |
| 7 | Fix `StringToComplex` — completely broken, only parsed Im part. Now moot: CMD shares `math_complex.pas` | 🟢 S | ✅ Done |
| 8 | Fix `cmd_unit_calc.TCalc` destructor — named `Free` instead of `Destroy override`, breaks destruction chain (`cmd_unit_calc.pas:206-208`) | 🟢 S | ✅ Done |
| 9 | Fix `TFitStructure.CopyContent` shallow copy — inner `Layers` arrays share references after copy (`unit_Types.pas:271-275`) | 🟡 M | ✅ Done |
| 10 | Fix `ClearDir` — removed unused `Full` parameter (`unit_helpers.pas:537`) | 🟢 S | ✅ Done |

## Refactoring

| # | Task | Size | Status |
|---|------|------|--------|
| 11 | Eliminate XRC_CMD code duplication — shared `math_complex.pas` via search path, deleted `cmd_math_complex.pas` (579 lines). Remaining CMD units (`cmd_math_globals`, `cmd_unit_calc`, `cmd_unit_types`, `cmd_unit_materials`) have diverged types and can't be shared without rewrite | 🔴 XL | ✅ Done |
| 12 | Delete `unit_settings_old.pas` — dead code, fully superseded by `unit_Config.pas`. Also re-declares helpers already in `unit_helpers.pas` | 🟢 S | ✅ Done |
| 13 | Delete or implement `FindPCores` — empty stub, all case branches are no-ops (`unit_sys_helpers.pas:55-87`) | 🟢 S | ✅ Done |
| 14 | Remove `with` statements in `unit_materials.pas` — 4 uses on `FLayers[i]`/`FMaterials[size]` (lines 106, 118, 165, 185). Replace with explicit variable refs | 🟡 M | ✅ Done |
| 15 | Name magic numbers — `kk` → `ClassicalElectronRadius`, `0.2171472409516259` → `InvTwoLn10`, `0.849` → `FWHMToGaussianWidth`, `DV` → commented | 🟡 M | ✅ Done |
| 16 | Replace fragile `Poly[0..10]` encoding — index 10 used as length marker in `TProjectData`. Use struct with explicit `Count` field (`unit_Types.pas:65-66`) | 🟡 M | ⏸️ Deferred |
| 17 | Fix implicit global `Structure` in `TProfileManager` — bare variable referenced without being a field or parameter (`unit_ProfilesManager.pas:105+`) | 🟡 M | ✅ Done |
| 18 | Replace old-style I/O in `DataToFile` — uses deprecated `Assign/Rewrite/Writeln/Close` without try/finally (`unit_helpers.pas:479-493`) | 🟢 S | ✅ Done |
| 19 | Remove redundant `Randomize` calls — called multiple times per run instead of once at startup (`unit_LFPSO_Base.pas:522,540`, `unit_LFPSO_Irregular.pas:177`) | 🟢 S | ✅ Done |
| 20 | Extract `DivZZ` denominator to local variable — `Z2.Re² + Z2.Im²` computed twice (`math_complex.pas:326-329`) | 🟢 S | ✅ Done |

## Optimizations

| # | Task | Size | Status |
|---|------|------|--------|
| 21 | Precompute `LevyWalk` constants — `Gamma(2.5)`, `Gamma(1.25)`, `sigma_u` are all constants (beta=1.5). Called thousands of times per iteration (`unit_LFPSO_Base.pas:373-392`) | 🟡 M | ✅ Done |
| 22 | Pool/reuse `TCalc` in `CalcSolution` — currently creates/destroys per particle in tight loop (`unit_LFPSO_Base.pas:396-427`) | 🟡 M | ✅ Done |
| 23 | ~~Avoid full array copy in `GetLayers`~~ — Copy is required: `RefCalc` mutates the passed array, copy prevents corruption of the model | 🟢 S | ⏸️ Deferred |
| 24 | Use dictionary for material lookup in `AddMaterial` — currently O(n) linear scan (`unit_materials.pas:96-102`) | 🟡 M | ✅ Done |
