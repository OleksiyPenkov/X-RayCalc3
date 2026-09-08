# XRACA MCP server — requirements

_Issued 2026-09-08 by the paper-2 planning session (LLM-driven X-ray optics laboratory,
`D:\MultilayerLab\Papers\Agentic-Deposition-Control\docs\superpowers\specs\2026-09-08-llm-xray-optics-lab-design.md`).
This document states what the server must do and why. The implementing agent owns the
design of the code and writes its own spec and plan under `docs/superpowers/` in this
repository. Questions about the requirements go back to the author._

## 1. Purpose

Expose X-Ray Calc 3 and XRFCalc to an LLM agent over MCP so the agent can design a
periodic multilayer mirror for a set of XRF lines, evaluate structures, fit measured XRR
curves and read measurement files, without a GUI and without touching anything outside a
configured working directory. The server is one leg of a closed loop whose other leg is the
deposition-system bridge; the agent's calls and the server's answers become part of a
published process record, so every call must be logged and every result reproducible.

## 2. Non-negotiables

1. **Delphi only.** A new console project in the XRC3 group (working name `XRC_MCP`), built
   like `xrccmd`, output to `_Out/BIN/`. No Python, no scripts, no wrappers around the CLI.
2. **Transport** JSON-RPC 2.0 over stdio, MCP `initialize` / `tools/list` / `tools/call`, copied
   from `D:\APS\ELN\ELN3\ELN.MCPServer\unit_MCPProtocol.pas` and `unit_MCPServer.pas` (stdin
   and stdout forced to UTF-8, one JSON object per line). The plugin host, MySQL, WebDAV,
   key-file identity and registry config of that server are not needed.
3. **Same engine as the GUI.** Reflectivity, fitting (LFPSO) and the universal optimizer must
   be the units the GUI and `xrccmd` already use (`Shared/Math`, `Shared/Universal`,
   `XRC_CMD/units`, `XRayCalc3/LFPSO`). No re-implementation of physics. The implementer
   chooses between the `cmd_unit_*` and the `XRayCalc3/Units` variants where both exist, and
   states the choice; a fit produced by the server must load in the XRayCalc3 GUI as `.xrcx`
   and give the same curve, because the author will refit every agent result independently.
4. **Units.** All thicknesses and wavelengths in Å; roughness σ in Å; density in g/cm³;
   angles in degrees (θ, not 2θ, stated in every schema). Energy in eV is accepted anywhere a
   wavelength is, converted with λ[Å] = 12398.42 / E[eV], and the wavelength actually used is
   echoed back.
5. **Working directory sandbox.** One directory from the command line (`--workdir <path>`).
   Every path the server reads or writes is under it; a path argument that resolves outside
   is refused with an error, never silently remapped. Subfolders: `projects\`, `jobs\`,
   `inbox\`, `log\`.
6. **Journal.** Every `tools/call` and its result (or error) appended as one JSON line to
   `log\calls.jsonl` with a timestamp, the tool name, the full arguments and the full result
   (large arrays such as curves replaced by their length and a SHA-256 of the file they were
   written to). This file is a primary record for the paper; it must never be truncated by
   the server.
7. **Asynchronous long jobs.** `optimize_mirror` and `fit_xrr` return a `job_id` at once and run
   in a background thread (OmniThreadLibrary, as the GUI does). `job_status` reports state,
   iteration, best figure of merit or χ², elapsed time. `job_result` returns the result when
   finished and an error while running. `cancel_job` stops a job. Jobs survive nothing: if
   the server process ends, running jobs are lost and `job_status` on restart says so
   (`unknown`). Job folders `jobs\<job_id>\` hold checkpoint, log and outputs.
8. **Determinism.** `optimize_mirror` and `fit_xrr` accept `seed`; the seed used is echoed in
   the result; with the same seed and inputs the result is identical.
9. **Errors** are structured: `{code, message, detail}`; no stack traces, no dialogs, no
   `Readln`. The process must be safe to run headless.

## 3. Structure JSON

One format for every tool that takes or returns a structure:

```json
{
  "substrate": {"material": "SiO2", "density": 2.2, "sigma": 3.0},
  "stacks": [
    {"N": 30, "layers": [
      {"material": "Ru", "thickness": 14.7, "sigma": 3.0, "density": 12.4},
      {"material": "C",  "thickness": 53.8, "sigma": 3.0, "density": 2.2}
    ]}
  ],
  "cap": {"material": "Ru", "thickness": 20.0, "sigma": 3.0, "density": 12.4},
  "buffer": {"material": "Ru", "thickness": 197.0, "sigma": 3.0, "density": 12.4}
}
```

- `density` optional, defaults to the Henke bulk value; the value used is echoed.
- `cap` (top) and `buffer` (between substrate and the first stack) optional.
- Composition mixing (XRFCalc genome) is expressed as a material string the materials
  unit already parses, e.g. `"W0.7Si0.3"`; the implementer states the exact syntax in
  `describe_server`.
- Several stacks are allowed, in order from substrate to surface.
- Where `.xrcx` supports a per-period depth profile (polynomial per layer), the fitted
  structure returns it expanded as an array `thickness_profile[N]` per layer in addition
  to the mean thickness. The mean is what the agent compares.

## 4. Tools

Every tool has a JSON schema in `tools/list` with a description that states units and
angle convention. Names below are fixed; argument names may be refined by the implementer
and are then documented in `describe_server`.

### 4.1 Reference

| Tool | Arguments | Returns |
|---|---|---|
| `describe_server` | none | server version, X-Ray Calc engine version, Henke table source and date, units and conventions, material syntax, limits (max layers, max points, max jobs), working directory layout, list of tools with one-line summaries |
| `list_materials` | `filter` (optional list of element symbols: return only materials composed of these) | materials with formula, bulk density, atomic mass, and whether they are elements or compounds |
| `optical_constants` | `material`, `lambda` or `energy`, `density` (optional) | δ, β, n, k, the wavelength used, the density used, and the nearest absorption edges of each element in the material within a stated window |
| `list_templates` | `pool` (list of element symbols) | XRFCalc material-pair templates whose materials are all in the pool: key, description, layers, caps, thickness rules |

### 4.2 Calculation

| Tool | Arguments | Returns |
|---|---|---|
| `calc_reflectivity` | `structure`, `lambda` or `energy`, `theta_min`, `theta_max`, `points`, `polarization` (`s`, `p`, `sp`), `delta_theta` (beam divergence FWHM, optional) | curve `[theta, R]` written to `jobs\calc-<id>\curve.dat` and returned inline if ≤ `max_inline_points`; Bragg peaks: order, θ_B, R_peak, FWHM; total-reflection critical angle |
| `evaluate_lines` | `structure`, `lines` (array of `{name, lambda or energy, weight}`), `fitness` (optional overrides of the XRFCalc `TFitnessConfig` fields: `w_R`, `w_FWHM`, `R_min_threshold`, `polarization`, `delta_theta`, `theta_min`, `w_purity`, `scan_points`, `scan_half_range`) | per line: θ_B, R_peak, FWHM, `valid`; the figure of merit exactly as `unit_universal_fitness` computes it, with the fitness settings used echoed back |

`evaluate_lines` must call the same fitness code as the optimizer, so that a designed
structure evaluated here gives the optimizer's own figure of merit, and a fitted structure
evaluated here is comparable to it.

### 4.3 Optimisation

| Tool | Arguments | Returns |
|---|---|---|
| `optimize_mirror` | the XRFCalc configuration as JSON (lines, `element_pool`, `excluded_pairs`, `structure` ranges d/Γ/N/σ/density_factor/cap, `fitness`, `optimizer` population/iterations/tolerance/stagnation, `substrate`, `template` selection), `seed`, `top_k` (default 5) | `job_id` |
| `job_status` | `job_id` | `state` (`queued`, `running`, `finished`, `failed`, `cancelled`, `unknown`), iteration, best value, elapsed seconds, last message |
| `job_result` | `job_id` | for optimisation: `top_k` distinct structures (in the structure JSON), each with genome, figure of merit, per-line results, and the path of the `.xrfx` package written for it; the configuration used; the seed |
| `cancel_job` | `job_id` | state after cancel |

Distinctness of the top-K: the implementer defines a rule (for instance different material
pair or period differing by more than a stated fraction) and documents it, so that the
agent does not receive five copies of one optimum.

### 4.4 Fitting

| Tool | Arguments | Returns |
|---|---|---|
| `fit_xrr` | `measurement_id` (from the inbox) or `curve` inline; `structure` (start model); `free` (which parameters may vary: per layer thickness, σ, density; substrate σ; scale, background, resolution); `bounds` per free parameter; `lambda` of the measurement; `theta_range` to fit; `optimizer` population/iterations/tolerance; `seed`; `profile` flag (allow per-period thickness polynomials or not) | `job_id` |
| `job_result` (fit) | `job_id` | fitted structure JSON (mean thicknesses and, if `profile`, the expanded per-period profile); χ² and the residual definition; scale, background, resolution values; the start model; the measured, calculated and residual curves as files under `jobs\<job_id>\` (inline if small); the `.xrcx` path written for the fit |

The fit must be the GUI's LFPSO, with the same χ² definition, so the author can open the
`.xrcx` and continue or repeat it. Uncertainty estimates are not required in v1; the paper
gets them from independent refits.

### 4.5 Measurements (inbox)

| Tool | Arguments | Returns |
|---|---|---|
| `list_measurements` | `specimen` (optional filter) | for each `inbox\<specimen>\`: specimen name, files with size, SHA-256, modified time, and the metadata file contents if present |
| `get_measurement` | `measurement_id` (`<specimen>/<file>`), `max_points` (optional decimation for inline return) | parsed curve `[theta, I]` with the columns detected, the point count, θ range, and the metadata; the raw file is never modified |

Accepted curve formats: the text formats the GUI's data loader already reads (two-column
θ/I with optional header; `.dat`, `.txt`, `.xy`). The metadata file is `meta.json` beside
the curve with at least `lambda`, `date`, `instrument`, `theta_unit` (`theta` or `2theta`);
if `theta_unit` is `2theta` the server converts and says so in the result. The server never
writes into `inbox\`.

### 4.6 Projects

| Tool | Arguments | Returns |
|---|---|---|
| `save_project` | `structure`, `name`, optional `curves` to embed (a measurement id or a job's curves), `note` | `.xrcx` written to `projects\<name>.xrcx`, path and SHA-256; refuses to overwrite unless `overwrite: true` |
| `load_project` | `name` or path under `projects\` | structure JSON, embedded curves summary, project version |
| `list_projects` | none | names, sizes, SHA-256, modified times |

`.xrcx` files written here must open in XRayCalc3 without conversion (`CURRENT_PROJECT_VERSION`).

## 5. Out of scope

- Any access to the ELN, the deposition system, calibration data or rates. The agent
  converts structure to recipe on its own with the chamber bridge.
- Aperiodic structures and the XRFCalc GUI.
- Authentication: the server runs locally, one process per agent session, sandboxed by
  `--workdir`.
- Uncertainty estimation for fits (v2 if the paper needs it).

## 6. Acceptance

1. `tools/list` returns the tools of §4 with schemas stating units; `describe_server` returns
   what §4.1 says.
2. A Ru/C structure (d 68.5 Å, Γ 0.215, N 30, Ru buffer 197 Å, glass substrate) through
   `calc_reflectivity` at λ 1.5406 Å reproduces the GUI's curve for the same `.xrcx` within
   numerical noise; the first Bragg peak position agrees.
3. `optimize_mirror` with the XRFCalc example configuration (Be–Mg lines, its element pool)
   produces the same best figure of merit as XRFCalc itself for the same seed, population
   and iterations.
4. `fit_xrr` on a measured curve from `inbox\` reproduces, for the same start model and
   seed, the χ² of an `xrccmd -a` fit; the written `.xrcx` opens in the GUI and shows the same
   calculated curve.
5. A path argument outside `--workdir` is refused; `inbox\` is unchanged after every tool.
6. `log\calls.jsonl` holds one line per call after a session of all tools.
7. DUnitX tests for the structure JSON round trip, the unit conversions, the inbox parser
   and the sandbox check, in `XRayCalc3\Tests`.

## 7. Registration

The paper session registers the server per experiment with

```
claude mcp add -s user xraca -- "D:\DelphiProjects\X-RayCalc\X-RayCalc3_Working\_Out\BIN\XRC_MCP.exe" --workdir "<experiment directory>"
```

and starts the agent session from a `run-*.cmd` that carries only this server and the
chamber bridge. Nothing in the server should depend on the current directory of the process.

## 8. Questions for the author, if any arise

Send them to the paper session; do not guess on units, on the figure-of-merit formula, or
on the `.xrcx` version.
