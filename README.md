# X-Ray Calc 3

X-Ray Calc 3 is a Windows program for the simulation of X-ray reflectivity (XRR) of layered
structures and for fitting measured curves with a particle-swarm optimiser (LFPSO). It is the
current version of X-Ray Calc, written in Delphi (Object Pascal). This repository also holds the
command-line interface, the XRF mirror-design program XRFCalc, and XRC_MCP, a server that exposes
the same calculation engine to LLM agents over the Model Context Protocol.

Documentation: the [wiki](https://github.com/OleksiyPenkov/X-RayCalc3/wiki) (getting started,
user manual, manual fitting, working with experimental data).

## Citing

- Penkov, O. V., Kopylets, I. A., Khadem, M. & Qin, T. (2020). *X-Ray Calc: a software for the
  simulation of X-ray reflectivity.* SoftwareX **12**, 100528.
  https://doi.org/10.1016/j.softx.2020.100528
- Penkov, O. V. et al. (2024). *X-Ray Calc 3.* J. Appl. Cryst. **57**, 555–566.
  https://doi.org/10.1107/S1600576724001031

## Downloads

Windows installers are published under
[Releases](https://github.com/OleksiyPenkov/X-RayCalc3/releases). The installer ships the 32-bit
and 64-bit GUI, the Henke optical-constant tables and example projects.

## Repository layout

```
XRayCalc3/     GUI application (Forms, Views, Units, LFPSO, Components, Editors, Assets, Tests)
XRC_CMD/       xrccmd, command-line calculation, fitting and universal-mirror optimisation
XRFCalc/       XRF mirror design GUI (universal-mirror optimiser)
XRC_MCP/       MCP server for LLM agents (JSON-RPC 2.0 over stdio, 16 tools)
Shared/Math/       Calculation engine, complex math, materials database
Shared/Universal/  Universal-mirror types, fitness, templates, XRF lines, .xrfx packages
_Installer/    Inno Setup script and deployment
docs/          Design documents and implementation plans
XRC3.groupproj Delphi project group; build order XRayCalc3 → XRayCalcVisualControls → xrccmd → XRFCalc → XRC_MCP
```

Project files are `.xrcx` (a zip archive with the model tree, parameters and curves); the
current project version is 7. Lengths are in ångström, densities in g/cm³, angles are the grazing
angle θ in degrees.

## Building

- Embarcadero RAD Studio 37.0 (Delphi 13). Build with the IDE or with MSBuild, using `/t:Build`
  (`/t:Make` does not work with these projects):

  ```
  msbuild XRayCalc3\XRayCalc3.dproj /t:Build /p:Config=Release /p:Platform=Win32
  msbuild XRC_CMD\xrccmd.dproj      /t:Build /p:Config=Release /p:Platform=Win32
  msbuild XRFCalc\XRFCalc.dproj     /t:Build /p:Config=Release /p:Platform=Win32
  msbuild XRC_MCP\XRC_MCP.dproj     /t:Build /p:Config=Release /p:Platform=Win64
  ```

  Executables land in `_Out\BIN\`. The 64-bit GUI is `XRayCalc3.x64.exe`; Win32 is the primary
  target for the GUI and the CLI, and XRC_MCP is built for Win64 only.

- Dependencies, on the Delphi library path:
  - [OmniThreadLibrary](https://github.com/gabr42/OmniThreadLibrary) **3.08 or later**. Older
    versions truncate 64-bit code pointers in `OtlTaskControl.pas`, and every Win64 build that
    runs the optimiser or the fit then hangs at the first iteration.
  - [FastMath](https://github.com/neslib/FastMath)
  - Raize Components (Konopka Signature VCL Controls), Virtual TreeView, Abbrevia, SynEdit
  - DUnitX (shipped with RAD Studio) for the tests
- Tests: `XRayCalc3\Tests\XRayCalc3Tests.dproj` (Win32 Debug), a DUnitX suite covering the
  calculation engine, the Henke tables, the LFPSO fit, the universal optimiser and every XRC_MCP
  unit. Run `XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe` after building.
- XRC_MCP regenerates `XRC_MCP\units\gitrev.inc` from `git describe --always --dirty` in its
  pre-build event, so `git` must be on `PATH`; the value is what the server reports as its
  revision, and a `-dirty` suffix means the tree had uncommitted changes when it was built.

## XRC_MCP: the engine as an MCP server

`XRC_MCP.exe --workdir <absolute path>` runs a JSON-RPC 2.0 server on stdin/stdout that an MCP
client such as Claude Code can connect to. The working directory is a sandbox: `projects\`
(`.xrcx` files the server writes and reads), `jobs\` (one folder per long-running job),
`inbox\` (measured curves placed there by a person; the server never writes into it) and
`log\calls.jsonl` (every call and result, appended, never truncated). The tools cover reference
data (`describe_server`, `list_materials`, `optical_constants`, `list_templates`), calculation
(`calc_reflectivity`, `evaluate_lines`), optimisation (`optimize_mirror` with `job_status`,
`job_result`, `cancel_job`), fitting (`fit_xrr`), the inbox (`list_measurements`,
`get_measurement`) and projects (`save_project`, `load_project`, `list_projects`). The engines
are the GUI's own: the curve, the χ² and the figure of merit are the numbers X-Ray Calc 3 and
XRFCalc display, and a fit written by the server opens in the GUI as an `.xrcx` file.

Register it with Claude Code, one working directory per experiment:

```
claude mcp add -s user xrc -- "<path>\_Out\BIN\XRC_MCP.exe" --workdir "<experiment directory>"
```

Details, argument shapes and the smoke test are in [`XRC_MCP/README.md`](XRC_MCP/README.md);
the requirements and design notes are in `docs/superpowers/specs/`.

## History

The branch `master` carries the development history since 2023. The repository's earlier public
history, with the flat layout and the 3.5.x releases, is preserved under the tag
`legacy-main-3.5.3` and on the branch `main`.

## Licence

GNU General Public License v3.0; see [LICENSE](LICENSE).
