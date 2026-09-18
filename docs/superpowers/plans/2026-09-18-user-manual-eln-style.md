# User Manual in the ELN Help Style — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Convert the 19-chapter HTML user manual to the E-Lab Notebook help page anatomy and add Source Code, Wiki and MCP Server chapters.

**Architecture:** A one-off Python script rewrites each old chapter (`<main>` body) into the new template: breadcrumb bar, h1 + subtitle, on-page TOC from the h2s, callouts, See Also, bottom nav. The index and the three new chapters are written by hand. Two small reusable scripts stay in the repo: a link checker and a print.html/PDF builder.

**Tech Stack:** Static HTML + one shared CSS, Python 3.13 (stdlib only), Microsoft Edge headless for the PDF, bash `deploy.sh`, Inno Setup.

**Spec:** `docs/superpowers/specs/2026-09-18-user-manual-eln-style-design.md`

## Global Constraints

- Index file name stays `UserManual.html` (opened by `frm_Main.pas:629`); no Delphi changes.
- Chapter files renamed per the spec table; reading order = spec table order.
- Existing chapter text is kept verbatim; only structure changes.
- Old `h3 id="…"` values are preserved on the new `h2`; `.warning` → `.warn`.
- No `script.js`, no sidebar, no search box.
- The internal Gitea address never appears in the manual.
- Manual version 9, copyright 2001–2026.

---

### Task 1: Link checker (the test for everything that follows)

**Files:**
- Create: `XRayCalc3/Assets/Docs/tools/check_help.py`

- [ ] **Step 1: Write the checker.** It walks `Help/*.html`, and for every `href`/`src` that is relative checks the file exists, for every `#anchor` checks an `id="anchor"` exists in the target, for every `.page-toc a` checks the target is an `h2` in the same page, and for every chapter (not the index, not print.html) asserts exactly one `.topbar`, one `.page-toc` (or none if the page has no h2), one `.bottom-nav`, and none of `sidebar`, `script.js`, `class="warning"`. Exit 1 on any failure, print each failure as `file: message`.
- [ ] **Step 2: Run it on the current folder.** Expected: failures (old pages have sidebars). That proves it detects the old anatomy.
- [ ] **Step 3: Commit** `+ Help: link and anatomy checker for the user manual`.

### Task 2: New style.css

**Files:**
- Modify: `XRayCalc3/Assets/Docs/Help/style.css` (replace)

- [ ] **Step 1: Write the ELN stylesheet** as shared CSS: `body`, `.topbar` (+ `.app-title`, `.sep`, links), `.hero`, `.container` (820px for chapters, `.container.wide` 960px for the index), `.section-title`, `.card-grid`, `.card`, `.card-icon`, `.card-body`, `.card-title`, `.card-desc`, `h1`, `.subtitle`, `.page-toc`, `h2`, `h3`, `h4`, `p`, `table/th/td`, `ul/ol/li`, `code`, `pre`, `kbd`, `.note`, `.tip`, `.warn`, `.bottom-nav` (+ `.prev::before`, `.next::after`), `img.icon`, `.icon-ref`, `figure/figcaption`, `.layout-diagram`, `.badge`, `.footer`. Palette: `#1a5276` primary, `#2980b9` gradient end, greys as in ELN `Index.html`.
- [ ] **Step 2: Commit** together with Task 3 (a stylesheet alone is not testable).

### Task 3: Convert the 19 chapters

**Files:**
- Create (scratch, not committed): `<scratchpad>/convert_help.py`
- Create: the 19 renamed chapter files in `Help/`; delete the 19 numbered ones.

- [ ] **Step 1: Write the converter.** Table `CHAPTERS = [(old, new, title, subtitle), …]` in reading order. For each: read old file, take the text between `<main class="content">` and `<div class="page-nav">`, drop the leading `<h2><span class="num">…</span> Title</h2>` (keep a trailing `<span class="badge">` as `BADGE`), promote `h3`→`h2` (keep `id`, else `id` = slug of the text), `h4`→`h3`, `class="warning"`→`class="warn"`, rewrite every `href="NN-old.html…"` to the new name, build the page-toc from the h2s, append the See Also list from a `SEE_ALSO = {new: [(file, label), …]}` map, then the bottom-nav from the neighbours in `CHAPTERS`, and write the new file. Delete the old file afterwards with `git mv` semantics (write new, `git rm` old).
- [ ] **Step 2: Run the converter, then `python tools/check_help.py`.** Expected: only the index fails (still links old names) — fix in Task 4.
- [ ] **Step 3: Open three converted pages in Edge** (`Fitting.html`, `Overview.html`, `UniversalMirror.html`) and check figures, tables, callouts and the TOC.
- [ ] **Step 4: Commit** `* Help: user manual chapters in the E-Lab Notebook page layout`.

### Task 4: Index page

**Files:**
- Modify: `Help/UserManual.html` (replace)

- [ ] **Step 1: Write the index**: hero (title, one-line welcome), six `.section-title` groups from the spec with a `.card` per chapter (icon from `images/icons/` where one fits, otherwise none), footer with author, email and the 2024 citation.
- [ ] **Step 2: Run the checker.** Expected: PASS for everything except the three new chapters, which do not exist yet (the index links them). Leave them failing until Task 5.
- [ ] **Step 3: Commit** `* Help: grouped index page`.

### Task 5: New chapters

**Files:**
- Create: `Help/SourceCode.html`, `Help/Wiki.html`, `Help/MCPServer.html`

- [ ] **Step 1: SourceCode.html** — sections: Repository, Getting the Source, Branches and History, Repository Layout, Building (IDE, MSBuild, output folders), Dependencies, Running the Tests, Contributing (issues, pull requests), Licence and Citation. Content from `README.md` and `CLAUDE.md` (public parts only).
- [ ] **Step 2: Wiki.html** — sections: Overview, Opening the Wiki from the Application (Help ribbon: Home Page, Wiki, Support), Wiki Pages (table: page, what it covers, matching chapter here), Editing the Wiki, Cloning the Wiki.
- [ ] **Step 3: MCPServer.html** — sections: Overview, Installation and Registration, The Working Directory, Reference Tools, Calculation Tools, Optimisation and Jobs, Fitting, Inbox, Projects, Example Session, Security, Smoke Test. Content from `XRC_MCP/README.md`.
- [ ] **Step 4: Run the checker.** Expected: PASS, 0 failures.
- [ ] **Step 5: Commit** `+ Help: Source Code, Online Wiki and MCP Server chapters`.

### Task 6: print.html and PDF

**Files:**
- Create: `XRayCalc3/Assets/Docs/tools/make_print.py`
- Modify: `Help/print.html` (regenerated), `Help/UserManual.pdf` (rebuilt)

- [ ] **Step 1: Write the builder.** It concatenates the `.container` body of each chapter in reading order (dropping topbar, page-toc, bottom-nav), prefixes a title page and a TOC, adds print CSS (`h1.chapter { page-break-before: always }`), writes `print.html`, then runs `msedge --headless --disable-gpu --print-to-pdf=UserManual.pdf --no-pdf-header-footer print.html`.
- [ ] **Step 2: Run it; open the PDF; check chapter count = 22.**
- [ ] **Step 3: Commit** `* Help: print.html builder and regenerated UserManual.pdf`.

### Task 7: Installer and cleanup

**Files:**
- Modify: `_Installer/deploy.sh:43-44,93-95`, `_Installer/XRayCalc3Setup.iss:45-46`
- Delete: `Help/script.js`

- [ ] **Step 1: Remove `script.js`** and its lines from `deploy.sh` and the `.iss`.
- [ ] **Step 2: Run `bash _Installer/deploy.sh`.** Expected: finishes, reports 23 HTML files staged (22 chapters + index; `print.html` makes 24 if counted — record the actual figure).
- [ ] **Step 3: Run the checker one last time; commit** `* Help: drop script.js from the deployment`.
