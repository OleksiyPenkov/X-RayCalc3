# X-Ray Calc 3 Project Memory

---

## LEVEL 1 — General (any project, any machine)

### User Preferences
- **No parallel agents** — don't offer or use parallel agent sessions; work sequentially
- **"commit all"** means commit everything without asking for confirmation — just do it
- **Display TODO lists as tables** — format as markdown tables (columns: #, Task, Size, Status)
- **Use colored emoji for Size and Status columns**: Size: 🟢 S, 🟡 M, 🟠 L, 🔴 XL; Status: ✅ Done, 🔴 Open, ⏸️ Deferred

### Fast Commands
Shorthand commands: `todo:`, `done:`, `wip:`, `refactor:`, `fix:`, `implement:`, `document:`, `analyze:`, `review:`, `find:`, `build`, `test:`, `commit:`, `status`, `next`, `help:`

- **`next:` command**: Always read and display the full TODO.md, then identify the next open item. Do NOT use agents or skills — just show the TODO and summarize what's next.

### Workflow Rules
- **Never mark TODO items as done** until user confirms they work in the running app — a successful build means nothing
- **Always commit TODO.md immediately** after any change — don't batch with other commits, don't forget
- **Always commit IDE-modified files** — if the user adjusted something in the IDE (DFM geometry, etc.), commit those changes too
- Analyze findings organized by: Bugs, Features, Refactoring, Documentation

---

## LEVEL 2 — General Delphi (any Delphi project)

### DFM Editing — Strict Rules
External edits to DFM can break form layout — user must reopen in IDE to fix.

**NEVER touch these DFM properties:**
- Coordinates/sizes: `Left`, `Top`, `Width`, `Height`, `ClientWidth`, `ClientHeight`
- Margins/padding: `Margins.*`, `Padding.*`
- Explicit cache: `ExplicitLeft`, `ExplicitTop`, `ExplicitWidth`, `ExplicitHeight`
- Scaling: `PixelsPerInch`, `TextHeight`, `Scaled`
- Layout: `Align`, `Anchors`, `Constraints.*`
- Inherited DFMs are especially fragile — avoid all edits if possible

**Safe to hand-edit in DFM files:**
- Text properties: `Caption`, `Text`, `Hint`
- Data binding: `DataField`, `DataSource`
- Events: `OnClick`, `OnChange`, `OnDblClick`, etc.
- State: `Visible`, `Enabled`, `TabOrder`, `Tag`
- List contents: `Items.Strings`, `Lines.Strings`
- Non-visual components: datasets, timers, menus, actions, image lists
- Column field names and titles (NOT widths)

### VCL Gotchas
- `TMenuItem.AutoHotkeys` defaults to `maAutomatic` — VCL auto-inserts `&` accelerators into captions. Set `AutoHotkeys := maManual` on parent menu when captions must be exact (e.g., style names passed to `TStyleManager.TrySetStyle`)
- `TStyleManager.TrySetStyle(Name, ShowErrorDialog)` — second param defaults to True, pass False to suppress error dialog
- WebView2 (TEdgeBrowser) doesn't survive VCL reparenting — call `CloseBrowserProcess` before reparent, `CMShowingChanged` + `CreateWebView` reinitializes in new parent

### Adding new visual components
- **Default: add to DFM** (designer) — do NOT create visual controls at runtime unless explicitly asked
- Only create controls in code (e.g., `FormCreate`) when the user explicitly requests runtime creation
- Non-visual components always go in DFM

### VCL Editor UI Patterns
Inherited editor form patterns: combos, checklists, grids, menu wiring.

### Aurelius TAureliusDataset
- Association fields (Proxy<T>, FK relationships) are NOT exposed as dataset fields
- Neither association name nor JoinColumn name works as DataField
- Use `TAureliusDataset.Current<T>` (generic method, requires explicit type arg) to get current entity
- For FK lookups: use regular TComboBox + manual sync, NOT TDBLookupComboBox
- Pattern: iterate lookup dataset → populate combo + store IDs, sync via DataSource.OnDataChange

### Aurelius ObjectManager Patterns
- `FManager.Save(Entity)` issues INSERT immediately for auto-increment IDs — ID is assigned in-memory
- `FManager.Flush` must be called before reading auto-generated IDs from cascade-saved entities (e.g., files added via collection)
- `FManager.Evict(Entity)` removes from identity map but preserves in-memory field values
- Deleting entities owned by a Proxy collection: **remove from parent collection first**, then `FManager.Remove` + `Flush` — otherwise AV in Flush
- Pattern for AddItem: `Save` → `Flush` → `Evict` (ensures ID assigned before detach)
- Pattern for AddFile: `Update(ParentItem)` → `Flush` (cascade saves new file, assigns ID)

### Unit Name Clash Gotchas
- When adding RTL units, check if they export common type names (`TFile`, `TStream`, etc.) that clash with domain entities
- `System.IOUtils` defines its own `TFile` record — avoid in units that declare a `TFile` entity

---

## LEVEL 3 — Project X-Ray Calc 3

*(To be filled as the project is worked on)*

---

## LEVEL 4 — Machine-specific

*(Fill in tool paths and build commands for the new machine)*
