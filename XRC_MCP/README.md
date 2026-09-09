# XRC_MCP

`XRC_MCP.exe` is a console MCP (Model Context Protocol) server that exposes the X-Ray Calc 3
calculation engine to LLM agents over a JSON-RPC 2.0 stdio loop. It is started with a mandatory
`--workdir <absolute path>`, which is the sandbox every tool is confined to.

Build it with the `XRC_MCP Win64` command in the repository's `CLAUDE.md` build table. Design and
requirements live in `docs/superpowers/specs/2026-09-09-xrc-mcp-design.md` and
`docs/superpowers/specs/2026-09-08-xraca-mcp-server-requirements.md`.

**Win64 build dependency:** `optimize_mirror` runs the universal optimizer through
OmniThreadLibrary's `Parallel.For`, and `fit_xrr` runs the LFPSO fit through the same
library's `Parallel.&For` (`unit_LFPSO_Base.pas`). Both need **OmniThreadLibrary 3.08 or later**
(the clone at `D:\DelphiProjects\_Libraries\OmniThreadLibrary` is checked out at `release-3.08`).
Older versions cast code pointers to `Cardinal` in `TOmniTaskExecutor.GetMethodAddrAndSignature`
and hang for ever under dcc64 (see `CLAUDE.md`, Dependencies). The same dependency applies to
`xrccmd -u`, XRFCalc, and the Win64 GUI's own fitting. The symptom of an old library is a job
stuck at iteration 0 with an empty `results\progress.log`, and a server that will not exit.

`units\gitrev.inc` is **not** in version control: the project's pre-build event regenerates it from
`git rev-parse --short HEAD` on every build, so `git` must be on `PATH`. Its value is what
`describe_server` reports as `git_revision`.

**Smoke test:** `pwsh -File XRC_MCP\smoke\session.ps1` drives one live stdio session against
`_Out\BIN\XRC_MCP.exe` in a throwaway work directory, calls every one of the 16 tools (jobs are
submitted, polled through `job_status` and read with `job_result`; one is stopped with
`cancel_job`) and checks the Ru/C Bragg-peak angle, seed determinism of `optimize_mirror` and
`fit_xrr`, the `path_outside_workdir` refusal, that the inbox is byte-identical afterwards, and
that `log\calls.jsonl` holds exactly one tool line per `tools/call` sent. Exit code 0 means every
check passed; `-KeepWorkdir` leaves the work directories behind for inspection. It takes a few
seconds.
