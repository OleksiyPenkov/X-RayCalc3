# XRF Emission Lines Lookup Table — Design Spec

## Goal

Replace hardcoded element-to-wavelength mappings with a JSON lookup table covering Li(Z=3) through U(Z=92). Simplify config files so targets can be specified as element names or ranges instead of explicit `{element, lambda, weight}` objects.

## Emission Line Selection

- **Ka** for Z=3 (Li) through Z=55 (Cs)
- **La** for Z=56 (Ba) through Z=92 (U)

This follows standard XRF practice where Ka energies become impractical above ~35 keV.

## JSON Table: `Universal/xrf_lines.json`

```json
{
  "description": "Characteristic X-ray emission wavelengths (Angstroms). Ka for Z=3-55, La for Z=56-92.",
  "lines": {
    "Li": {"Z": 3,  "lambda": 228.0,  "line": "Ka"},
    "Be": {"Z": 4, "lambda": 114.0, "line": "Ka"},
    "B":  {"Z": 5,  "lambda": 67.6,   "line": "Ka"},
    ...
    "Cs": {"Z": 55, "lambda": 0.4013, "line": "Ka"},
    "Ba": {"Z": 56, "lambda": 2.776,  "line": "La"},
    ...
    "U":  {"Z": 92, "lambda": 0.9110, "line": "La"}
  }
}
```

Each entry contains:
- `Z`: atomic number (used for range expansion ordering)
- `lambda`: wavelength in Angstroms (Double precision)
- `line`: emission line identifier (`"Ka"` or `"La"`)

## Config Format: Mixed Target Array

The `targets` field accepts a mixed array with four item types:

| Type | Example | Behavior |
|------|---------|----------|
| String | `"C"` | Single element, weight=1.0, lambda from table |
| Range string | `"B-Si"` | All elements B(Z=5) through Si(Z=14), weight=1.0, lambdas from table |
| Object (no lambda) | `{"element": "Al", "weight": 2.0}` | Custom weight, lambda from table |
| Legacy object | `{"element": "C", "lambda": 44.7, "weight": 1.0}` | Explicit lambda, backward compatible |

Per-element weight customization requires either the object form or individual string entries; ranges always expand with weight=1.0.

### Examples

Before:
```json
"targets": [
    {"element": "B", "lambda": 67.6, "weight": 1.0},
    {"element": "C", "lambda": 44.7, "weight": 1.0},
    {"element": "N", "lambda": 31.6, "weight": 1.0}
]
```

After:
```json
"targets": ["B-N"]
```

Mixed:
```json
"targets": ["B-O", {"element": "Al", "weight": 2.0}, "Si"]
```

## Save Behavior

`SaveConfig` always writes the expanded/legacy format with explicit `{element, lambda, weight}` objects. This is intentional — the simplified format is a convenience for authoring configs by hand, not a round-trip format.

## Code Changes

### New: `Universal/unit_xrf_lines.pas`

Provides lookup functions backed by a const array embedded in the unit (no external file dependency at runtime):

- `function GetXRFLambda(const Element: string): Double` — returns lambda for an element; raises `EArgumentException` if element not found
- `function ExpandElementRange(const RangeStr: string): TArray<string>` — expands `"B-Si"` to `['B','C','N','O','F','Ne','Na','Mg','Al','Si']` using Z ordering. Raises `EArgumentException` for unknown endpoints. Reversed ranges (e.g., `"Si-B"`) are silently reversed.
- `function GetAllElements: TArray<string>` — returns all elements Li-U in Z order

The JSON file (`Universal/xrf_lines.json`) serves as the canonical data source and is used to generate the const array. The Delphi unit embeds the data directly so there is no runtime file dependency — both XRFCalc and xrccmd work without deploying a separate JSON file.

Internal storage: a const array of records `(Symbol: string; Z: Byte; Lambda: Double)` sorted by Z, with a helper function that builds a `TDictionary<string, Integer>` index on first access (lazy init, immutable after creation, thread-safe for concurrent reads).

### Modified: `unit_universal_io.pas`

`LoadConfig` target parsing changes:

```
for each item in JTargets:
  if item is string:
    if contains '-':
      expand range via ExpandElementRange
      for each element: add TTargetElement(Name=el, Lambda=GetXRFLambda(el), Weight=1.0)
    else:
      add TTargetElement(Name=item, Lambda=GetXRFLambda(item), Weight=1.0)
  else if item is object:
    Name = element field
    Weight = weight field (default 1.0)
    if lambda field exists:
      Lambda = lambda field (legacy)
    else:
      Lambda = GetXRFLambda(Name)
```

### Modified: `frm_XRFMain.pas`

- Remove hardcoded `KAlphaData` array and `TARGET_COUNT` constant
- Populate `clbTargets` dynamically from a practical subset (Z=5..30, B through Zn — covers common XRF multilayer mirror targets). The `clbTargets` height and `sgWeights.RowCount` adjust dynamically based on the number of checked items.
- `CollectConfigFromUI` uses `GetXRFLambda` instead of `KAlphaData` lookups

### Consumers

Both XRFCalc (GUI) and xrccmd (CLI) benefit from these changes since they share `unit_universal_io.pas`. No separate file deployment needed because the data is embedded in the compiled unit.

### Unchanged

- `TTargetElement` record — still `{Name, Lambda, Weight}` after config resolution
- All downstream code: `TMaterialMixer`, fitness evaluation, optimizer
- Existing config files with explicit `lambda` fields continue to work

## Error Handling

- **Unknown element symbol:** `GetXRFLambda` raises `EArgumentException` with message `'Unknown element: "Xx"'`
- **Invalid range endpoint:** `ExpandElementRange` raises `EArgumentException` with message identifying the bad endpoint
- **Reversed range:** silently reversed (e.g., `"Si-B"` treated as `"B-Si"`)
- **Range spanning Ka/La boundary:** valid, each element uses its own line type

## Data Source

Wavelength values from NIST X-ray transition energies database, converted via `lambda = 12398.419 / E(eV)`. Values are weighted-average Ka (Ka1/Ka2 blend) for Z=3-55 and La1 for Z=56-92.
