# Material Pair Templates — Design Spec

## Goal

Add a template system that replaces ideal bilayer periods with realistic multi-layer structures based on known material pair data. When the optimizer picks a material pair that has a template (e.g., Mo/Si → Mo/MoSi2/Si/MoSi2), the fitness evaluation uses the real sub-layer structure with fixed roughness and density values from the template.

## Context

Real deposited multilayer mirrors don't have sharp interfaces. Material pairs form interdiffusion/compound layers at interfaces. For example, Mo/Si actually deposits as Mo/MoSi2/Si/MoSi2 with ~1 nm MoSi2 interlayers. The interlayer thickness, roughness, and density are not controllable — they are material properties. Different pairs have 2, 3, or 4 layers per period.

## Rules

- Templates apply in **pure elements mode only** (each layer is a single material)
- Template lookup key: `"Layer1Material/Layer2Material"` — **order matters** (Mo/Si ≠ Si/Mo)
- If a template exists for the pair → use it
- If no template exists → fall back to ideal 2-layer period
- Mixed composition mode → always ideal 2-layer (templates ignored)

## Template JSON Format

File: standalone JSON file referenced by config via `"template_file"` path.

```json
{
  "Mo/Si": {
    "layers": [
      { "material": "Mo",    "thickness": "gamma",   "sigma": 0.3, "density": 19.3 },
      { "material": "MoSi2", "thickness": 1.0,       "sigma": 0.3, "density": 6.3  },
      { "material": "Si",    "thickness": "1-gamma",  "sigma": 0.5, "density": 2.33 },
      { "material": "MoSi2", "thickness": 0.8,        "sigma": 0.3, "density": 6.3  }
    ]
  },
  "W/B4C": {
    "layers": [
      { "material": "W",   "thickness": "gamma",   "sigma": 0.2, "density": 19.3 },
      { "material": "B4C", "thickness": "1-gamma",  "sigma": 0.3, "density": 2.52 }
    ]
  }
}
```

### Thickness field

- `"gamma"` — computed as `d * Gamma - sum(fixed interlayer thicknesses on this side)`
- `"1-gamma"` — computed as `d * (1-Gamma) - sum(fixed interlayer thicknesses on other side)`
- Numeric value (e.g., `1.0`) — absolute thickness in Angstroms, fixed

"This side" means: interlayers adjacent to the gamma layer reduce the gamma layer's effective thickness, and interlayers adjacent to the 1-gamma layer reduce its effective thickness. The allocation rule: each interlayer's thickness is subtracted from the main layer it is closest to. In the Mo/Si example:
- Mo effective H = `d * Gamma - 1.0` (the first MoSi2 at 1.0 Å)
- Si effective H = `d * (1-Gamma) - 0.8` (the second MoSi2 at 0.8 Å)

If the computed main layer thickness would go negative (period too small for the interlayers), apply a fitness penalty.

### Sigma and density

- `sigma` — interface roughness in Angstroms, fixed per sub-layer
- `density` — bulk density in g/cm³, fixed per sub-layer

When a template is active, the genome's `Sigma` and `DensityFactor` fields are ignored. All roughness and density values come from the template.

## Optimized parameters (template mode)

Only three genome parameters are optimized:
- **d** — total period thickness (Å)
- **Gamma** — ratio of first main layer to period
- **N** — number of periods

`Sigma` and `DensityFactor` are excluded from PSO search when a template is matched.

## Architecture

### Insertion point

`BuildLayers` in `unit_universal_fitness.pas` is the single function that converts a genome into a TLayers array. This is where template expansion happens.

Current flow:
```
For each period:
  Layer1: H = d*gamma,     epsilon from Composition[0], sigma from genome
  Layer2: H = d*(1-gamma), epsilon from Composition[1], sigma from genome
```

With templates:
```
For each period:
  Determine dominant materials → key "Mat1/Mat2"
  If pure elements mode AND template found:
    For each template sub-layer:
      H = absolute or computed from d/gamma
      epsilon computed from material name + fixed density
      sigma from template
  Else:
    Current 2-layer logic (unchanged)
```

### Components to add/modify

1. **Template types** (`unit_universal_types.pas`)
   - `TTemplateLayer` record: Material (string), Thickness (string or float), Sigma (Single), Density (Single)
   - `TTemplatePair` record: Layers (array of TTemplateLayer)
   - `TTemplateLibrary` = TDictionary<string, TTemplatePair>
   - `TUniversalConfig.TemplatePath: string`

2. **Template loading** (`unit_universal_io.pas`)
   - `LoadTemplates(FileName): TTemplateLibrary` — parse JSON into template dictionary

3. **Interlayer material registration** (`unit_universal_fitness.pas` or mixer)
   - Templates introduce materials not in the element pool (e.g., MoSi2). These must be registered with the mixer so their Henke data is loaded. Collect all unique materials from templates, add to the element list before `TMaterialMixer.Initialize`.

4. **Epsilon calculation for template layers** (`unit_materials_mix.pas`)
   - Need a method to compute epsilon for a single material at a given density (not from composition fractions). Add `CalcSingleEpsilon(ElementIndex, Density, TargetIdx, out Epsilon)`.

5. **BuildLayers modification** (`unit_universal_fitness.pas`)
   - Accept template library reference
   - When pure elements + template matched: build expanded layer stack
   - Layer count per period becomes variable (not fixed at LAYERS_PER_PERIOD)
   - Negative main-layer thickness → fitness penalty

6. **Config integration** (`unit_universal_io.pas`)
   - Parse `"template_file"` from config JSON → `Config.TemplatePath`
   - `SaveConfig` writes it back

7. **GUI** (`frm_XRFMain.pas/dfm`)
   - Add template file path field + browse button in the Paths group
   - Persist in INI file like Henke path

### Data flow

```
Config.TemplatePath → LoadTemplates() → TTemplateLibrary
                                              ↓
Collect interlayer materials → add to element pool → TMaterialMixer.Initialize
                                              ↓
BuildLayers(Genome, TargetIdx):
  If PureElements AND template exists for pair:
    Expand period using template sub-layers
    Compute epsilon per sub-layer via CalcSingleEpsilon
  Else:
    Current path (CalcMixedEpsilon)
```

## Edge cases

- **Period too small**: If `d * Gamma` or `d * (1-Gamma)` is less than the sum of fixed interlayer thicknesses, the main layer would have negative thickness. Clamp to zero and apply fitness penalty.
- **Template file missing**: If `TemplatePath` is empty or file doesn't exist, proceed without templates (all pairs use ideal bilayer).
- **Interlayer material not in Henke database**: Raise error during mixer initialization (fail fast).
- **Asymmetric interlayers**: The template format naturally supports this — different thickness/sigma on each side of the main layers.
