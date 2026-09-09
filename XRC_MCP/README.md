# XRC_MCP

`XRC_MCP.exe` is a console MCP (Model Context Protocol) server that exposes the X-Ray Calc 3
calculation engine to LLM agents over a JSON-RPC 2.0 stdio loop. It is started with a mandatory
`--workdir <absolute path>`, which is the sandbox every tool is confined to.

Build it with the `XRC_MCP Win64` command in the repository's `CLAUDE.md` build table. Design and
requirements live in `docs/superpowers/specs/2026-09-09-xrc-mcp-design.md` and
`docs/superpowers/specs/2026-09-08-xraca-mcp-server-requirements.md`.

`units\gitrev.inc` is **not** in version control: the project's pre-build event regenerates it from
`git rev-parse --short HEAD` on every build, so `git` must be on `PATH`. Its value is what
`describe_server` reports as `git_revision`.
