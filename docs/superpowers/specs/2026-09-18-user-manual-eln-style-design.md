# User manual in the E-Lab Notebook help style — design

_2026-09-18_

## Goal

Rework the X-Ray Calc 3 user manual (`XRayCalc3/Assets/Docs/Help/`) so that it has the same
page anatomy as the E-Lab Notebook 3 help (`d:\APS\ELN\ELN3\ELN.Desktop\Assets\Runtime\Help\`),
and add three chapters: the source repository and Git, the online (GitHub) wiki, and the
XRC_MCP server. Existing chapter text is kept; it is reorganised, not rewritten.

## What "the ELN style" is

| Element | Current manual | ELN help (target) |
|---|---|---|
| Index | flat grid of 19 numbered cards, search box | hero banner, cards grouped under section titles, icon + title + description per card |
| Chapter navigation | fixed top bar + fixed sidebar with the whole TOC | breadcrumb top bar (`App Help | Home / Chapter`), no sidebar |
| Chapter head | `h2` with numbered badge | `h1` + one-line `.subtitle` + "On this page" box listing the `h2` sections |
| Sections | `h3`/`h4` | `h2` with `id`, `h3` below |
| Callouts | `.note`, `.tip`, `.warning` | `.note`, `.tip`, `.warn` |
| End of page | prev / Home / next buttons, footer | See Also list, then `.bottom-nav` prev / Home / next |
| Scripts | `script.js` (sidebar highlight, search, back-to-top) | none |
| CSS | shared `style.css` | inline per page (kept shared here, see Decisions) |

## Files

Everything lives in `XRayCalc3/Assets/Docs/Help/`. Chapter files are renamed from numbered
to descriptive names; the index keeps its name because `frm_Main.pas:629` opens
`Help\UserManual.html` and no Delphi change is wanted.

| New file | From | Index group |
|---|---|---|
| `UserManual.html` | `UserManual.html` | (index) |
| `Introduction.html` | `01-introduction.html` | Getting Started |
| `QuickStart.html` | `02-quick-start.html` | Getting Started |
| `Installation.html` | `03-installation.html` | Getting Started |
| `Overview.html` | `04-overview.html` | Getting Started |
| `QuickReference.html` | `15-shortcuts.html` | Getting Started |
| `Projects.html` | `05-projects.html` | Working with Projects |
| `Models.html` | `06-models.html` | Working with Projects |
| `Data.html` | `07-data.html` | Working with Projects |
| `Calculation.html` | `08-calculation.html` | Working with Projects |
| `Fitting.html` | `09-fitting.html` | Working with Projects |
| `Results.html` | `10-results.html` | Working with Projects |
| `Charts.html` | `11-charts.html` | Working with Projects |
| `Profiles.html` | `12-profiles.html` | Working with Projects |
| `Tools.html` | `13-tools.html` | Tools and Settings |
| `Settings.html` | `14-settings.html` | Tools and Settings |
| `UniversalMirror.html` | `19-universal-mirror.html` | Tools and Settings |
| `MCPServer.html` | new | Automation |
| `FileFormats.html` | `16-formats.html` | Reference |
| `Examples.html` | `17-examples.html` | Reference |
| `Troubleshooting.html` | `18-troubleshooting.html` | Reference |
| `SourceCode.html` | new | Project and Community |
| `Wiki.html` | new | Project and Community |

Reading order for prev/next and for the PDF is the order of the table above.

Also changed: `style.css` (rewritten to the ELN palette and components), `print.html`
(regenerated), `UserManual.pdf` (rebuilt), `script.js` (deleted),
`_Installer/deploy.sh` and `_Installer/XRayCalc3Setup.iss` (drop the `script.js` lines).
Untouched: `UserManual.md`, `Help.hnd`, `images/`, all Delphi sources.

## Page template

```
<div class="topbar">X-Ray Calc 3 Help | <a>Home</a> / <Chapter></div>
<div class="container">
  <h1>Chapter</h1>
  <div class="subtitle">one line</div>
  <div class="page-toc">On this page: one <li> per h2</div>
  <h2 id="...">Section</h2> ...          (old h3 → h2, old h4 → h3)
  <h3>See Also</h3><ul>…</ul>
  <div class="bottom-nav"><a class="prev">…</a><a>Home</a><a class="next">…</a></div>
</div>
```

`h2` ids are derived from the heading text (lower-case, hyphens) unless the old page
already had an id on that heading, in which case the old id is kept so existing
cross-links keep working. `.warning` becomes `.warn`.

## New chapters

**SourceCode.html — Source Code and Git.** Repository `https://github.com/OleksiyPenkov/X-RayCalc3`;
clone command; branches (`master` = development since 2023, `main` and tag
`legacy-main-3.5.3` = the flat-layout 3.5.x history); repository layout table; building in the
RAD Studio 37 IDE and with MSBuild (`/t:Build`, Win32 primary, XRC_MCP Win64 only);
dependencies (OmniThreadLibrary 3.08+, FastMath, Raize, Virtual TreeView, Abbrevia, SynEdit,
DUnitX); running the tests; reporting issues and pull requests on GitHub; GPL v3; citing the
two papers. Source: `README.md`, `CLAUDE.md`. The internal Gitea mirror is not mentioned.

**Wiki.html — Online Wiki.** `https://github.com/OleksiyPenkov/X-RayCalc3/wiki`; the nine pages
(Home, Getting started, How to create a model and calculate XRR, Working with experimental data,
Working with experimental data (Data conditioning), Manual curve fitting, Benchmarks,
Troubleshooting, User Manual) with a one-line description and which chapter of this manual
covers the same ground; the Wiki button in the Help ribbon and the Home Page and Support
buttons next to it; editing a page on GitHub; cloning `X-RayCalc3.wiki.git`.

**MCPServer.html — MCP Server (XRC_MCP).** Modelled on ELN's `AIIntegration.html`: what the
server is; `XRC_MCP.exe --workdir <dir>`; registering with Claude Code (`claude mcp add`);
the work directory sandbox (`projects\`, `jobs\`, `inbox\`, `log\calls.jsonl`); tool tables
for reference (`describe_server`, `list_materials`, `optical_constants`, `list_templates`),
calculation (`calc_reflectivity`, `evaluate_lines`), optimisation and jobs
(`optimize_mirror`, `job_status`, `job_result`, `cancel_job`), fitting (`fit_xrr`), inbox
(`list_measurements`, `get_measurement`), projects (`save_project`, `load_project`,
`list_projects`); an example session; security (sandbox, inbox read-only, journal); the smoke
test; the OmniThreadLibrary 3.08 note. Source: `XRC_MCP/README.md`.

## Decisions

- Shared `style.css` instead of ELN's inline CSS: 22 pages, one place to change.
- Descriptive file names, as in ELN; numbered names would fight the grouped index.
- Card icons: existing `images/icons/*.png` where one fits; otherwise no icon.
- `UserManual.md` stays as a historical source and is not updated; the HTML is the source
  of truth from now on.
- Manual version 9, copyright 2001–2026.

## Verification

1. A link checker over `Help/*.html`: every relative `href`/`src` resolves to a file, every
   `#anchor` to an `id` in the target page, every page-toc entry to an `h2` on the same page.
2. Every chapter has exactly one `topbar`, `page-toc`, `bottom-nav`; no `sidebar`, no
   `script.js` reference, no `.warning` class remains.
3. `bash _Installer/deploy.sh` finishes without error and stages 23 HTML files.
4. `UserManual.pdf` regenerated from `print.html` opens and has all 22 chapters.
5. Open `UserManual.html` in a browser and click through the groups.
