# Excluded Material Pairs

## Problem
The universal mirror optimizer freely combines any elements from the pool. Some pairs are physically or chemically incompatible (similar optical contrast, interdiffusion, no stable interfaces). These waste iterations and produce unusable results.

## Config Format
Add optional `"excluded_pairs"` array to `universal_mirror.json`:
```json
{
    "element_pool": ["W", "Mo", "Si", "SiC", "B", "B4C"],
    "excluded_pairs": ["Si/SiC", "B/B4C", "C/B4C", "Si/Si3N4"],
    ...
}
```
- Symmetric: `"Si/SiC"` also excludes `"SiC/Si"`
- Order within each string doesn't matter
- Optional field — omitting it or using `[]` means no exclusions

## Data Structure
Add to `TUniversalConfig` in `unit_universal_types.pas`:
```pascal
TExcludedPair = record
  Idx1, Idx2: Integer;  // indices into ElementPool
end;

// In TUniversalConfig:
ExcludedPairs: array of TExcludedPair;
```
Parsed at config load time. Resolve names to pool indices; raise an error if a material name isn't found in the pool.

## Enforcement (two points)

### 1. InitializePopulation (unit_universal_pso.pas)
When seeding pure-element pairs, check the candidate `Elem0/Elem1` against the excluded list. If excluded, cycle `Elem1` through the pool until a valid partner is found.

### 2. CheckLimits (unit_universal_pso.pas)
After normalization, find the dominant element in each layer. If the resulting pair is excluded, re-randomize Layer 1's composition to a random valid element (keeping Layer 0 fixed).

### Helper
`IsExcludedPair(Idx0, Idx1): Boolean` on `TUniversalPSO`. Checks both orderings against the list. Linear scan — pool sizes are 10-15 elements, list is tiny.

## Console Output
Print excluded pairs in the banner (cmd_unit_universal.pas) after the element pool:
```
Excluded: Si/SiC, B/B4C
```

## Scope
- Only applies in `PureElements` mode
- No changes to fitness, templates, or output formats
- No changes to SaveConfig (excluded_pairs round-trips through JSON)

## Files Changed
1. `unit_universal_types.pas` — add `TExcludedPair` record, add field to `TUniversalConfig`
2. `unit_universal_io.pas` — parse `excluded_pairs` in `LoadConfig`, write in `SaveConfig`
3. `unit_universal_pso.pas` — add `IsExcludedPair`, enforce in `InitializePopulation` and `CheckLimits`
4. `cmd_unit_universal.pas` — print excluded pairs in banner
