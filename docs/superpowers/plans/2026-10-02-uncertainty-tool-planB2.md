# Uncertainty tool, the window (plan B2) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** XRCUncert as a program the author can run: open a fitted `.xrcx`, press Run, read `value ± error` with plain warnings; started from the main app's Calc menu; its entries survive a main-app save; shipped by the installer with one help page.

**Architecture:** Everything that decides what the user reads lives in two VCL-free units on top of plan B1 (`unit_UncertView`: text and chart numbers; `unit_UncertSession`: one open project, its counts, priors and stored result), so it is tested in the existing suite. The window (`XRCUncert/`, built like `XRFCalc/`) only draws what they return and runs `RunUncertainty` on a worker thread. The main app changes in two places: one action and one call in its save.

**Tech Stack:** Delphi 13 VCL, Raize (`TRzPanel`, `TRzListView`), TeeChart (`VCLTee`), DUnitX, `System.Zip`; plan B1's `Shared/Bayes/unit_Uncert{Request,Run,Files,Counts}`; `unit_MCPProjectFile.ReadXRCX`; `Shared/Math/unit_otl_drain`.

**Spec:** `docs/superpowers/specs/2026-10-01-uncertainty-tool-design.md` (sections 2, 3, 5.4, 5.5, 6; decisions 1, 5 to 9). Plan B1 (`docs/superpowers/plans/2026-10-02-uncertainty-tool-planB1.md`) defines every type this plan consumes.

## Before this plan (done 2026-10-02, on the branch)

Two small test-first commits, the author's two open questions taken as "yes" (the recommendation):

1. **A held period is sampled.** Periodic mode gives every repeating stack with a free thickness a period slot: the fit's window when Free period was on, `HELD_PERIOD_WINDOW = 0.02` (2 % either way) when the fit held it. This replaces B1's D2 "held, no ±". A stack with no free thickness still has no period slot.
   Seen while doing it: with the period sampled, the tests' 400-step recipe no longer settles at the first attempt on the W/B4C fixture (it passes on the automatic longer one). At the standard recipe the new end-to-end case `PeriodicHeldPeriod_FromProjectFile` covers it (numbers in the Outcome).
2. **The MCP server saves Free period.** `fit_xrr`'s `fit.xrcx` carries `[FIT] FreePeriod` and `PeriodWindow` when a period was freed (the widest side of its bounds as a fraction of the start period).

## Global Constraints

- Work only in the worktree `.claude/worktrees/uncertainty-tool`, branch `worktree-uncertainty-tool`. Never merge, rebase onto, or push to `master`. The only write outside the worktree is the test build in Task 7.
- Invoke `my-skills:delphi-development` before writing or changing code. Commit prefixes `+` / `*`, attribution lines at the end of every message. New files carry the short MIT header.
- **Every VCL control is defined in the DFM**, never created at run time (this includes the in-place editor of the list; `frm_Limits` creating its `TRzEdit` in code is not the pattern to copy). Conditional display is `Visible`.
- DFMs are written at 96 dpi (`PixelsPerInch = 96`). Containers: `AlignWithMargins = True` with `Align`; `TRzPanel` has `BorderOuter = fsFlatRounded`. Icons, if any, through `TImageCollection` + `TVirtualImageList`.
- **No GUI automation.** Nobody launches the program, sends keys or takes screenshots to verify it. The window is checked by the author (Task 7). What can be wrong without being seen is in the two VCL-free units and is tested there.
- User-facing text says "uncertainty", never "posterior"; every message is a plain sentence in XRR terms. Value, ±, plain warnings; sampler numbers only behind Details. No settings dialog.
- The tool never rewrites `params.dsc`, `project.dsc`, `calc.dat` or any `data_*.dat`; it writes only `uncert_<model id>.json` and `counts_<data id>.dat` through `WriteEntries`. The project version stays 8.
- Scope cuts (agreed, do not add back): no model picker (the project's active model and its linked curve); no joint fits; limits are not edited; the substrate is not sampled; no version bump and nothing on the download cards.
- Tests: Win32 Debug, in `XRayCalc3/Tests`, registered in `XRayCalc3Tests.dpr` and `.dproj` as B1's were. Build and run through the PowerShell tool:

```
$env:BDS = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'; $env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0'; & 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal 2>&1 | Select-String -Pattern 'error|Fatal'
$env:PATH = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;$env:PATH"; $env:XRC_TRUTH_GATE = ''; & XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue 2>&1 | Select-Object -Last 12
```

  One fixture: `--run:<Unit>.<Class>`. Each task is test first where it has logic: write the test, see it fail, implement, see it pass, run the whole suite, commit. `Test_Clipboard_Roundtrip` errors at random and is not a regression.

## Decisions this plan makes (the spec left them open)

| # | Decision | Why |
|---|---|---|
| E1 | The top line shows `Model: <title>   Curve: <title>` as text; there is no model combo. | B1's scope cut. The main app saves before launching, so the active model is the one the user was looking at. |
| E2 | Program names: `XRCUncert.exe` (Win32) and `XRCUncert.x64.exe` (Win64, `OutputExt`), both in `_Out\BIN`. The main app starts the one of its own bitness, from its own folder. | Both platforms share `_Out\BIN`; the GUI is named the same way. |
| E3 | The command line is one argument, the project path. No model ID. | E1. |
| E4 | The list's rows: Summary (period slots and summaries), one group per stack (plain values and derived layers), Measurement is not listed (scale, background and noise floor are in Details). Period-values and profile coefficients have no row; they are the Depth chart. A held number is shown with an empty ±. | Spec section 2; decision 7. |
| E5 | Known, its ± and Note are edited in place and stored in the project when the edit is confirmed (Enter or leaving the cell), keeping any stored result, which then shows as out of date. An empty Known removes the entry. | "Everything lives in the .xrcx"; no Save button to forget. |
| E6 | The run uses the graphics card when there is one and the fixed seed 20261002. The result and the counts are written to the project when the run ends settled; a run that was stopped or did not settle writes nothing. | A fixed seed makes the ELN record reproducible. |
| E7 | The Depth chart has one combo (in the DFM) listing each profiled or tabulated layer value; it is hidden, with its tab, for a periodic project. Bands are drawn as median line plus two thin 16 % / 84 % lines. | The smallest thing that shows a band; a filled band can follow if the author asks. |
| E8 | The main app's save step takes the tool's entries from the file the project was opened from (`FProjectFileName`), always, into its temp folder before zipping. | The tool is the only writer of those entries, so the file on disk is never older than the temp folder; no time comparison needed. |
| E9 | A project newer than `CURRENT_PROJECT_VERSION` is refused by the session with the main app's sentence. | Spec 1.1; `ReadXRCX` does not check it. |
| E10 | The test build for the author is a normal installer named `XRayCalc3_Setup_3.9.5-uncert-test.exe`, copied to `Z:\files\Software\`. `Z:\index.html` is not touched. | Decision 9. The directory listing shows it; that is what "test builds go to Z:" means. |

## File structure

| File | Responsibility |
|---|---|
| `Shared/Bayes/unit_UncertView.pas` (new, no VCL) | What the window shows, as data: rows, the ± text, the table as text and CSV, the Details text, the depth-chart points, parsing a typed Known / ±. |
| `Shared/Bayes/unit_UncertSession.pas` (new, no VCL) | One open project: read, refuse or build the request, find the counts, load the stored result and priors, say whether it is out of date, store priors, store a result. |
| `Shared/Bayes/unit_UncertFiles.pas` (modify) | `+ KeepToolEntries`. |
| `XRCUncert/Units/unit_UncertThread.pas` (new) | The worker thread around `RunUncertainty`. |
| `XRCUncert/XRCUncert.dpr`, `.dproj`, `Forms/frm_UncertMain.pas/.dfm`, `Forms/frm_UncertDetails.pas/.dfm` (new) | The program. |
| `XRCUncert/Help/index.html`, `style.css` (new) | The one help page. |
| `XRayCalc3/Forms/frm_Main.pas/.dfm`, `XRayCalc3/Views/frame_ProjectPanel.pas` (modify) | The menu item; the save step. |
| `XRC3.groupproj`, `_Installer/XRayCalc3Setup.iss`, `_Installer/deploy.sh`, `CLAUDE.md` (modify) | Build, ship, document. |
| `XRayCalc3/Tests/TestUncertView.pas`, `TestUncertSession.pas`, `TestUncertThread.pas` (new); `TestUncertFiles.pas` (modify) | Tests. |

## Review Focus

1. **The project file cannot be written when the run ends** (read-only, on a share that dropped, open in a scanner): the result stays on screen, one warning says it was not stored and why; Copy and Export still work. Test: Task 2, `StoreResult_ReadOnlyFile_SaysSoAndKeepsTheFile`.
2. **Closing the window, or opening another project, while a run is going:** the run is stopped and waited for before anything is freed; the thread never touches a freed form. Test: Task 3, `Thread_StopThenWait_EndsQuickly`; the form's part is in the author's checklist.
3. **A typed Known or ± that is not a number, a ± of zero or less, a decimal comma:** refused in one plain sentence, the cell keeps its old value, nothing is stored. Test: Task 1, `ParsePrior_*`.
4. **A stored result that no longer fits the project** (a layer added, the fit mode changed, another build's format): it is shown as out of date when its names still match the request and dropped silently when they do not; never an index error. Test: Task 2, `StoredResult_OfAnotherModelShape_IsDropped`.
5. **Something that is not a project is dropped on the window or given on the command line** (a `.dat`, a folder, a damaged zip, a project from the dropped 3.10 line): one plain sentence, the window stays usable and keeps the project it had. Test: Task 2, `Open_NotAProject_PlainSentence` and `Open_NewerProject_Refused`.

---

### Task 1: What the window shows, as data

**Files:** Create `Shared/Bayes/unit_UncertView.pas`, `XRayCalc3/Tests/TestUncertView.pas`; register the test in `XRayCalc3Tests.dpr` / `.dproj`.

**Interfaces:**
- Consumes: B1's `TUncertName`, `TUncertNameKind`, `TUncertPrior`, `TUncertRequest` (`unit_UncertRequest`), `TUncertValue`, `TUncertResult` (`unit_UncertRun`).
- Produces:

```pascal
type
  TUncertRow = record
    Name: string;                 // the reported name; '' never
    Group, Caption: string;
    Value, Error: string;         // '' while there is no result; Error '' for a held number
    Known, KnownError, Note: string;
    CanHavePrior: Boolean;
    AtLimit: Boolean;
  end;
  TDepthSeries = record
    Name: string;                 // 's0.l0.thickness'
    Caption: string;              // 'ML: W  H, Å'
    Period, P16, P50, P84: TArray<Double>;   // empty P16/P84 while there is no result
  end;

/// '0.3', or '+0.3 / −0.1' when the halves differ by more than a factor 1.5;
/// two significant digits; '' when either half is NaN.
function ErrorText(Minus, Plus: Double): string;
/// The value to the decimal place of its error's second digit; five
/// significant digits when there is no error.
function ValueText(Value, Minus, Plus: Double): string;
/// The list: unPeriod and unSummary rows in the group 'Summary', unValue rows
/// in their stack's group, in Names' order; no unPeriodValue, unCoefficient or
/// unMeasurement row. HasResult False: Value is the fitted value where the
/// request knows it (Best is not known yet: Value '').
function RowsOf(const Names: TArray<TUncertName>; const Res: TUncertResult;
  HasResult: Boolean; const Priors: TArray<TUncertPrior>): TArray<TUncertRow>;
/// Tab-separated, one header line, a line per row; Unicode kept.
function TableText(const Rows: TArray<TUncertRow>): string;
/// RFC 4180, the same columns, invariant numbers, UTF-8 with BOM when saved.
function TableCSV(const Rows: TArray<TUncertRow>): string;
/// One series per layer value that has unPeriodValue names.
function DepthSeriesOf(const Names: TArray<TUncertName>; const Res: TUncertResult;
  HasResult: Boolean): TArray<TDepthSeries>;
/// Device, walkers, steps, seconds, whether the longer run was needed, the
/// measurement's three values, R-hat per value, and every pair of values
/// whose correlation is at least 0.7 in size.
function DetailsText(const Names: TArray<TUncertName>; const Res: TUncertResult): string;
/// '' and the prior, or one plain sentence. KnownText '' means "remove":
/// '' is returned and Remove is True. Accepts a decimal point only.
function ParsePrior(const Name, KnownText, ErrorText, Note: string;
  out Prior: TUncertPrior; out Remove: Boolean): string;
/// Priors with the entry for Prior.Name replaced, added or (Remove) taken out.
function WithPrior(const Priors: TArray<TUncertPrior>; const Prior: TUncertPrior;
  Remove: Boolean): TArray<TUncertPrior>;
```

- [ ] **Step 1: Tests.** In `TestUncertView.pas`, on hand-built `TUncertName` / `TUncertValue` arrays (no engine):
  - `ErrorText_Symmetric`: `ErrorText(0.31, 0.29)` = `'0.30'`. `ErrorText_Asymmetric`: `ErrorText(0.1, 0.3)` = `'+0.30 / ' + #$2212 + '0.10'`. `ErrorText_NaN`: `''`.
  - `ValueText_FollowsTheError`: `ValueText(55.7234, 0.11, 0.12)` = `'55.72'`; `ValueText(2785.3, 4.2, 4.0)` = `'2785.3'`; `ValueText(18.23456, NaN, NaN)` = `'18.235'`.
  - `Rows_GroupsAndOrder`: names `s0.l0.thickness` (unValue, group `ML`), `s0.l0.thickness[1]` (unPeriodValue), `s0.period` (unPeriod), `s0.period_mean` (unSummary), `c0.background` (unMeasurement) give three rows: the two Summary rows first in Names' order, then the `ML` row; the row of `s0.period` has group `'Summary'`.
  - `Rows_HeldNumber_HasNoError`: a name with `Held = True` and a value gives `Error = ''` and a non-empty `Value`.
  - `Rows_NoResult_ShowsPriorsOnly`: `HasResult = False`, one prior on `s0.total` (2790 ± 10, note `'profilometer'`): that row has `Known = '2790'`, `KnownError = '10'`, `Note = 'profilometer'`, `Value = ''`.
  - `Rows_AtLimit_IsFlagged`.
  - `TableText_HeaderAndTabs`: first line `'Parameter'#9'Value'#9'±'#9'Known'#9'±'#9'Note'`; group names appear as their own lines.
  - `TableCSV_QuotesCommasAndQuotes`: a note `a, "b"` comes out as `"a, ""b"""`.
  - `DepthSeries_OnePerTabledValue`: names `s0.l0.thickness[1..3]` and `s0.l1.thickness[1..3]` give two series with `Period = [1, 2, 3]` and the values' P50; `HasResult = False` gives empty `P16`.
  - `DetailsText_NamesStrongCorrelationsOnly`: a 2 x 2 correlation with 0.85 off the diagonal names the pair once; with 0.3 it names none; the text holds the device and no `'posterior'`.
  - `ParsePrior_Number`: `('s0.total', '2790', '10', 'n')` gives `''` and the prior. `ParsePrior_Empty_Removes`. `ParsePrior_NotANumber`: `'27,9'` gives a sentence containing `'number'`. `ParsePrior_ErrorNotPositive`: `'0'` and `'-1'` and `''` (with a Known) give a sentence containing `'greater than zero'`.
  - `WithPrior_ReplacesAddsRemoves`.
- [ ] **Step 2:** Build: expect `F2613`/`F1026` unit `unit_UncertView` not found. Add an empty-bodied unit (every function returning its default) and run the fixture: every test fails on its assertion.
- [ ] **Step 3:** Implement. Notes: two significant digits of the error are `RoundTo(E, Floor(Log10(E)) - 1)`; the value is then formatted with `Max(0, 1 - Floor(Log10(E)))` decimals, `E` being the larger half; all number text through `TFormatSettings.Invariant`; the minus sign in the asymmetric form is U+2212.
- [ ] **Step 4:** Fixture green, whole suite, commit `+ unit_UncertView: the uncertainty tool's rows, error text, table and details as data`.

### Task 2: One open project

**Files:** Create `Shared/Bayes/unit_UncertSession.pas`, `XRayCalc3/Tests/TestUncertSession.pas`; modify `Shared/Bayes/unit_UncertFiles.pas`, `XRayCalc3/Tests/TestUncertFiles.pas`.

**Interfaces:**
- Consumes: `ReadXRCX`, `BuildRequest`, `BuildMap`, `StartProblem`, `CountsFromSource`, `SourceFileOf`, `CountsToText`, `CountsFromText`, `Fingerprint`, `ReadEntry`, `WriteEntries`, `StoredToJSON`, `StoredFromJSON`, `UncertEntryName`, `CountsEntryName`; `unit_ProjectVersion` (the main app's "newer project" check and sentence: read the unit first and use what it exports; do not copy its text).
- Produces:

```pascal
// unit_UncertFiles
/// Extracts every 'uncert_*.json' and 'counts_*.dat' entry of ProjectFile into
/// Dir, replacing files of the same name. Does nothing when ProjectFile is
/// missing or not an archive. Never raises.
procedure KeepToolEntries(const ProjectFile, Dir: string);

// unit_UncertSession
type
  TUncertSession = record
    FileName: string;
    Project: TXRCXProject;
    Refusal: string;                 // '' or why this project cannot be analysed: Run is off
    Request: TUncertRequest;         // valid when Refusal = ''
    Counts: TArray<Double>;          // nil: none
    CountsNote: string;              // '' or the plain sentence saying why there are none
    Priors: TArray<TUncertPrior>;
    HasResult: Boolean;
    Result: TUncertResult;
    OutOfDate: Boolean;              // a stored result made for another model, curve, counts or priors
  end;

const
  MSG_OUT_OF_DATE = 'The model, the curve or the known values have changed since this result ' +
    'was made. Run again.';

/// '' and the session, or one plain sentence when the file cannot be opened
/// at all (not found, not a project, a newer project). A project that opens
/// but cannot be analysed is a session with Refusal set.
function OpenSession(const FileName: string; out S: TUncertSession): string;
/// Replaces S.Priors and stores them (with the stored result, if any, which
/// then is out of date). '' or a plain sentence; S is unchanged when it fails.
function StorePriors(var S: TUncertSession; const Priors: TArray<TUncertPrior>): string;
/// Takes a settled result into S and stores it with the counts. '' or a plain
/// sentence; S holds the result either way.
function StoreResult(var S: TUncertSession; const Res: TUncertResult): string;
/// The warnings to show under the list, in order: S.Refusal; MSG_OUT_OF_DATE;
/// CountsNote; the result's own Message and Warnings.
function SessionWarnings(const S: TUncertSession): TArray<string>;
```

- [ ] **Step 1: Tests.** `TestUncertFiles`: `KeepToolEntries_CopiesOnlyTheToolsEntries` (a project with `uncert_1.json`, `counts_2.dat` written by `WriteEntries`: the two files appear in the temp dir with the entries' bytes, `params.dsc` does not); `KeepToolEntries_ReplacesAnOlderFile`; `KeepToolEntries_MissingFile_DoesNothing`. `TestUncertSession`, on projects written with `WriteXRCX` from `TestUncertRequest.ProjectOf(WSi(10), 1)` into a temp folder:
  - `Open_FittedProject_HasARequestAndNoResult`: `Refusal = ''`, `Length(Request.Names) > 0`, `HasResult = False`, `CountsNote <> ''` (no source file).
  - `Open_NothingFree_IsARefusalNotAnError`: the function returns `''`, `Refusal` contains `'free to vary'`.
  - `Open_NotAProject_PlainSentence`: a text file named `x.xrcx`, a missing path, a folder: each returns a sentence, none raises.
  - `Open_NewerProject_Refused`: a project whose `[INFO] Version` is `CURRENT_PROJECT_VERSION + 1` returns the main app's sentence.
  - `StorePriors_RoundTrip`: store one prior, open again: the prior is there, `HasResult = False`.
  - `StoreResult_RoundTrip`: a hand-built settled `TUncertResult` with one value per `Request.Names`; open again: `HasResult`, not `OutOfDate`, values equal.
  - `StoreResult_ThenPriorChanged_IsOutOfDate`; `StoreResult_ThenModelChanged_IsOutOfDate` (rewrite the project with one thickness changed, then `WriteEntries` the old entry back).
  - `StoredResult_OfAnotherModelShape_IsDropped`: the stored entry's names differ in number from the request's: `HasResult = False`, no exception.
  - `StoreResult_ReadOnlyFile_SaysSoAndKeepsTheFile`: the file made read-only: a sentence comes back, `S.HasResult` is True, the file's bytes are unchanged.
  - `StoredCounts_AreUsedWithoutTheSourceFile`: counts stored by `StoreResult`, source file absent: `Counts` has one per point and `CountsNote = ''`.
  - `SessionWarnings_Order`.
- [ ] **Step 2:** See them fail (unit missing, then assertions on empty bodies).
- [ ] **Step 3:** Implement. `OpenSession`: `ReadXRCX` inside `try/except` turning any exception into `'<file name> is not an X-Ray Calc project: ' + E.Message`; the version check; `BuildRequest` into `Refusal`; when it passes, `BuildMap` + `StartProblem` (free the map in `finally`) into `Refusal` too; counts from the stored entry (`CountsFromText`), else from `CountsFromSource(SourceFileOf(Project.DataNote), ...)`, else nil with the note `'No raw counts were found: the errors rely on the estimated noise only.'` when the source gave no better sentence; the stored entry through `ReadEntry` + `StoredFromJSON`; `HasResult` only when `Length(Stored.Result.Values) = Length(Request.Names)` and every name matches; `OutOfDate := Stored.Fingerprint <> Fingerprint(Project, Counts, Priors)`. `KeepToolEntries`: `TZipFile` opened for reading inside `try/except`, `MatchesMask`-free test on the lower-cased entry name (`StartsWith('uncert_') and EndsWith('.json')`, `StartsWith('counts_') and EndsWith('.dat')`).
- [ ] **Step 4:** Fixtures green, whole suite, commit `+ unit_UncertSession: an open project for the uncertainty tool; KeepToolEntries for the main program's save`.

### Task 3: The program, opening and running

**Files:** Create `XRCUncert/XRCUncert.dpr`, `XRCUncert/XRCUncert.dproj`, `XRCUncert/Units/unit_UncertThread.pas`, `XRCUncert/Forms/frm_UncertMain.pas` + `.dfm`, `XRayCalc3/Tests/TestUncertThread.pas`; modify `XRC3.groupproj`, `XRayCalc3/Tests/XRayCalc3Tests.dpr` / `.dproj` (search path `..\..\XRCUncert\Units`).

**Interfaces:**
- Consumes: Tasks 1 and 2; `RunUncertainty`; `DrainParallelTasksBeforeExit` (`unit_otl_drain`).
- Produces:

```pascal
// unit_UncertThread (no VCL)
type
  /// Runs one request. OnProgress and OnDone are called on the worker thread;
  /// the window forwards them with TThread.Queue. Not FreeOnTerminate: the
  /// owner stops it, waits for it and frees it.
  TUncertThread = class(TThread)
  public
    constructor Create(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
      const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64; const Recipe: TUncertRecipe;
      const OnProgress: TUncertProgress; const OnDone: TProc);
    procedure Stop;                     // asks; returns at once
    property Result: TUncertResult read FResult;   // valid after it has ended
    property Failure: string read FFailure;        // '' or the exception's message in a plain sentence
  protected
    procedure Execute; override;        // RunUncertainty in try/except, then finally DrainParallelTasksBeforeExit
  end;
```

  `TfrmUncertMain` (controls, all in the DFM): `pnlTop: TRzPanel` (alTop) with `lblModel: TLabel`, `btnOpen`, `btnRun`, `btnStop: TButton`, `lblProgress: TLabel`; `pnlBottom: TRzPanel` (alBottom) with `memWarnings: TMemo` (read-only, no border, `ParentColor`), `btnDetails`, `btnCopy`, `btnExport`, `btnHelp: TButton`; `lvParams: TRzListView` (alLeft, `ViewStyle = vsReport`, `GroupView = True`, `RowSelect = True`, `ReadOnly = True`, columns Parameter / Value / ± / Known / ± / Note) with `edCell: TEdit` (`Visible = False`, parented to the list view in the DFM); `splMain: TSplitter`; `pcCharts: TPageControl` (alClient) with `tsCurve` (`chCurve: TChart`) and `tsDepth` (`cbDepth: TComboBox` alTop, `chDepth: TChart`); `dlgOpen: TOpenDialog`, `dlgExport: TSaveDialog`. Public: `procedure OpenProject(const FileName: string)`.

- [ ] **Step 1: Thread tests** (`TestUncertThread`, on `TestUncertRun.WB4CProject` and `ShortRecipe`, CPU): `Thread_RunsAndDeliversTheResult` (start, `WaitFor`, `Failure = ''`, `Result.Settled`, `OnDone` was called once, progress was reported); `Thread_StopThenWait_EndsQuickly` (`Stop` right after the first progress report; `WaitFor` returns; `Result.Stopped`); `Thread_EngineError_IsAFailureNotACrash` (counts of the wrong length: no exception leaves the thread; `Result.Message` or `Failure` holds a sentence).
- [ ] **Step 2:** See them fail, implement the thread, fixture green.
- [ ] **Step 3: The project.** Copy `XRFCalc/XRFCalc.dproj` to `XRCUncert/XRCUncert.dproj` and change: a new `ProjectGuid`; `MainSource` `XRCUncert.dpr`; `SanitizedProjectName` `XRCUncert`; `DCC_UnitSearchPath` `..\Shared\Bayes;..\Shared\Math;..\Shared\Universal;..\XRC_MCP\units;..\XRC_CMD\Units;..\XRayCalc3\Units;..\XRayCalc3\LFPSO;Units;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)` (start from the test project's path, drop what the linker does not ask for); `DCC_ExeOutput` `..\_Out\BIN\` on **both** platforms (XRFCalc's Win32 group does not have it: add it), `DCC_DcuOutput` `..\_Out\DCU\XRCUncert\$(Platform)`; `OutputExt` `x64.exe` in the Win64 groups (as `XRayCalc3.dproj:172`); the post-build line copying `XRCUncert\Help` to `$(DCC_ExeOutput)\Help\XRCUncert\`; the `DCCReference` list replaced by this program's units; version info 1.0.0.0, product name `XRCUncert`. The `.dpr` is XRFCalc's shape: `Application.Title := 'XRCUncert'`, one `CreateForm`. Add the project to `XRC3.groupproj` after XRFCalc (the `Projects` item and the three targets, and in `Build` / `Clean` / `Make`'s lists).
- [ ] **Step 4: The form.** Write the DFM (96 dpi, client 1100 x 640, `Position = poScreenCenter`, list 520 wide) and the unit:
  - `FormCreate`: `DragAcceptFiles(Handle, True)`; `OpenProject(ParamStr(1))` when `ParamCount >= 1`. `WMDropFiles`: the first file to `OpenProject`. `btnOpenClick`: `dlgOpen` (`*.xrcx`).
  - `OpenProject`: if a run is going, ask `'A run is in progress. Stop it and open the other project?'` and on Yes `StopAndWait`; then `OpenSession`; a sentence from it goes to `MessageDlg(mtWarning)` and the window keeps the session it had; otherwise the session replaces the old one and `ShowSession` runs.
  - `ShowSession`: caption `'XRCUncert - ' + ExtractFileName(...)`; `lblModel` per E1; `lvParams` filled from `RowsOf` with one `TListGroup` per distinct group (`Items.BeginUpdate` / `EndUpdate`); `memWarnings.Lines` from `SessionWarnings`; `btnRun.Enabled := (Refusal = '') and not running`; `btnStop.Enabled := running`; `btnDetails`, `btnCopy`, `btnExport` enabled with a result; `tsDepth.TabVisible := Length(DepthSeriesOf(...)) > 0`.
  - `btnRunClick`: create `TUncertThread` with the session's request, priors, counts, `UseGPU = True`, seed `20261002`, `TUncertRecipe.Standard`; `OnProgress` queues `lblProgress.Caption := TimeLeftText(SecondsLeft)` (`'about 1 min 10 s left'`, `'a few seconds left'` below 5 s, `''` when unknown); `OnDone` queues `RunEnded`. Queued procedures first check a run serial number captured at start against the form's current one, and do nothing when they differ.
  - `RunEnded`: `WaitFor`, take `Result` / `Failure`, free the thread. Failure: `memWarnings` shows `'The run failed: ' + Failure`. Stopped: `'The run was stopped: nothing was changed.'` Not settled: the result's message, nothing stored (E6). Settled: `StoreResult`; its sentence, if any, is shown as `'The result was not stored in the project: ' + ...` above the other warnings. Then `ShowSession`.
  - `btnStopClick`: `Thread.Stop`, `btnStop.Enabled := False`, `lblProgress.Caption := 'Stopping...'`.
  - `StopAndWait` (used by `FormCloseQuery` and `OpenProject`): bump the run serial, `Stop`, `WaitFor`, free. `FormCloseQuery` asks `'A run is in progress. Stop it and close?'` first.
  - Charts, Details, Copy, Export, cell editing and Help are Task 4: their buttons exist in the DFM now with `Enabled = False`.
- [ ] **Step 5:** Build Win32 Release and Win64 Release (`XRCUncert\XRCUncert.dproj /t:Build /p:Config=Release /p:Platform=Win32|Win64`): no errors, no hints or warnings from the new units; `_Out\BIN\XRCUncert.exe` and `XRCUncert.x64.exe` exist. Whole suite. Commit `+ XRCUncert: the uncertainty tool opens a fitted project and runs`.

### Task 4: Charts, known values, Details, Copy and Export

**Files:** Modify `XRCUncert/Forms/frm_UncertMain.pas` + `.dfm`; create `XRCUncert/Forms/frm_UncertDetails.pas` + `.dfm`; add to `XRCUncert.dpr` / `.dproj`.

**Interfaces:**
- Consumes: Task 1's `RowsOf`, `DepthSeriesOf`, `TableText`, `TableCSV`, `DetailsText`, `ParsePrior`, `WithPrior`; Task 2's `StorePriors`; `TUncertBand`.
- Produces: `TfrmUncertDetails` with `memDetails: TMemo` (alClient, read-only, `Font.Name = 'Consolas'`, both scroll bars) and `btnClose`; `class procedure TfrmUncertDetails.ShowText(AOwner: TComponent; const Text: string)`.

No new logic of its own: everything shown comes from Task 1's functions, which are tested. Before using a TeeChart or list-view member not already used in this repository, find it in `$(BDS)\source` or the VCLTee headers; do not guess.

- [ ] **Step 1: Curve chart.** In the DFM give `chCurve` four series: `serMeasured: TPointSeries` (small circles), `serMedian: TLineSeries`, `serLow`, `serHigh: TLineSeries` (thin, the median's colour, lighter); left axis logarithmic, no legend, no 3D, title off. `ShowSession` fills `serMeasured` from the request's data (always) and the three lines from `Result.Band` when there is a result, clearing them otherwise. Points with a value of zero or less are skipped (log axis).
- [ ] **Step 2: Depth chart.** `chDepth` with `serDepthMedian`, `serDepthLow`, `serDepthHigh: TLineSeries` (points visible on the median). `cbDepth.Items` are the `TDepthSeries.Caption`s; `cbDepthChange` draws the chosen one; bottom axis title `'Period number'`, left axis title the caption. Setting `cbDepth.ItemIndex` in code does not fire `OnChange`: call the draw procedure after it.
- [ ] **Step 3: Known values.** `lvParams` `OnMouseDown`: `LVM_SUBITEMHITTEST` as `frm_Limits.ListViewClick` does; on columns Known, its ± or Note of a row with `CanHavePrior`, place `edCell` over the cell (`ListView_GetSubItemRect`) with the cell's text, show and focus it. `edCell` `OnKeyDown`: Enter commits, Escape hides. `OnExit` commits. Commit: build the three texts of that row with the edited one replaced, `ParsePrior`; a sentence goes to `MessageDlg(mtWarning)` and the cell keeps its old text; otherwise `StorePriors(Session, WithPrior(...))`, its sentence (if any) shown the same way, then `ShowSession`. While a run is going the editor does not open. A row without `CanHavePrior` shows its three cells empty and does nothing.
- [ ] **Step 4: Details, Copy, Export, Help.** `btnDetailsClick`: `TfrmUncertDetails.ShowText(Self, DetailsText(...))`. `btnCopyClick`: `Clipboard.AsText := TableText(Rows)`. `btnExportClick`: `dlgExport` (`*.csv`, default name the project's name + `_uncertainties.csv`), `TFile.WriteAllText(..., TableCSV(Rows), TEncoding.UTF8)` in `try/except` with a plain message. `btnHelpClick` and F1: `ShellExecute` on `ExtractFilePath(ParamStr(0)) + 'Help\XRCUncert\index.html'`, a plain message when the file is not there.
- [ ] **Step 5:** Build Win32 and Win64 Release without hints or warnings; whole suite; commit `+ XRCUncert: the curve and depth charts, known values, Details, Copy and Export`.

### Task 5: The main program's menu item and save step

**Files:** Modify `XRayCalc3/Forms/frm_Main.pas` + `.dfm`, `XRayCalc3/Views/frame_ProjectPanel.pas`, `XRayCalc3/XRayCalc3.dproj` (search path `..\Shared\Bayes`), and the search path of every project that compiles `frame_ProjectPanel` (the tests already have it).

**Interfaces:**
- Consumes: `KeepToolEntries` (Task 2); `TfrmProjectPanel.SaveCurrentProject: Boolean`, `ProjectFileName`.

- [ ] **Step 1: Save step.** In `TfrmProjectPanel.SaveProject` (`frame_ProjectPanel.pas:1924`), as the first statement inside `if SaveProjectINI(...) then begin`: `KeepToolEntries(FProjectFileName, FProjectDir);` with a one-line comment (the uncertainty tool writes its entries into the file while the project is open here; E8). `unit_UncertFiles` goes into the implementation `uses`. Check what `unit_UncertFiles` pulls into the main program (`unit_UncertRun` and the sampler core through its interface `uses`): if the GUI's Win32 build needs more than a search path entry, move `KeepToolEntries` into a new 30-line unit `Shared/Bayes/unit_UncertKeep.pas` (uses `System.Zip`, `System.SysUtils`, `System.IOUtils` only), move its three tests with it, and link that instead.
- [ ] **Step 2: Menu item.** `frm_Main.dfm`: `actCalcUncertainty: TAction` (category as `actCalcFitJobs`, `Caption = 'Parameter uncertainties...'`, `OnExecute = actCalcUncertaintyExecute`) and `miCalcUncertainty: TMenuItem` under `Calc1`, after `Calcbatchjobs1`. Handler: the tool's path is `ExtractFilePath(ParamStr(0)) + {$IFDEF WIN64}'XRCUncert.x64.exe'{$ELSE}'XRCUncert.exe'{$ENDIF}`; when it is not there, `MessageDlg('The uncertainty tool (XRCUncert) was not found beside the program.', mtWarning, [mbOK], 0)`; otherwise save through the same routine File - Save uses (it asks for a name for a new project; when it returns False, stop), then `ShellExecute(Handle, 'open', PChar(Tool), PChar('"' + ProjectFileName + '"'), nil, SW_SHOWNORMAL)`. Find how `frm_Main` reaches the project panel's save for File - Save and call that, not a copy of it. The action is disabled while a fit is running, the way `actCalcFitJobs` is.
- [ ] **Step 3:** Build `XRayCalc3` Win32 and Win64 Release, `xrccmd` and `XRC_MCP` (they share units); whole suite (the three `KeepToolEntries` tests cover the step's logic; spec test 5.4's "entries survive an open-save" is the main program's extract-all / zip-all plus this call). Commit `+ Calc - Parameter uncertainties starts XRCUncert; saving keeps the tool's entries`.

### Task 6: Installer, help page, project notes

**Files:** Create `XRCUncert/Help/index.html`, `XRCUncert/Help/style.css` (a copy of `XRFCalc/Help/style.css`); modify `_Installer/deploy.sh`, `_Installer/XRayCalc3Setup.iss`, `CLAUDE.md`.

- [ ] **Step 1: Help page.** One page, in the voice and markup of `XRFCalc/Help/Overview.html`, sections: what the tool gives (value ± error for the fitted parameters of one model and one curve); how to start it (Calc - Parameter uncertainties, or open a project); what it takes from the project (the fit mode, what the fit left free, the limits; a held period is still given an error); the list (Summary, the stacks, the ± and the `+a / −b` form); known values (what Known, ± and Note mean, an example with a profilometer thickness); the charts; the warnings, one line each with what to do (no raw counts; a value at its limit; the result repeats what was entered; not settled; out of date; more than 20 table values; not stored); Details; what it does not do (joint fits, editing the model). No sampler vocabulary outside the Details section. No screenshots (the window is not approved yet).
- [ ] **Step 2: deploy.sh.** `check_file` and `cp` for `_Out/BIN/XRCUncert.exe` (to `Win32/`) and `XRCUncert.x64.exe` (to `Win64/`); `mkdir -p "$DEPLOY_DIR/Help/XRCUncert"` and copy `XRCUncert/Help/*` there; the summary `echo` lines.
- [ ] **Step 3: The .iss.** Two `Source:` lines for the programs into `{app}`; `Source: "deploy\Help\XRCUncert\*"; DestDir: "{app}\Help\XRCUncert"; Flags: ignoreversion`; one `[Icons]` line `{group}\Parameter uncertainties` pointing at `{app}\XRCUncert.x64.exe`. `MyAppVersion` is not changed.
- [ ] **Step 4: CLAUDE.md.** Build table rows for `XRCUncert` Win32 and Win64; "Build all" names it; the Architecture tree gets `XRCUncert/` and `Shared/Bayes/`; the Output paragraph names the two programs; group project build order; one paragraph under Key Files on `unit_UncertSession` / `unit_UncertView` as the place where the tool's behaviour lives and is tested.
- [ ] **Step 5:** `bash _Installer/deploy.sh` runs through (after a full build, Task 7 does it for real); commit `+ XRCUncert in the installer, with its help page; CLAUDE.md`.

### Task 7: Whole-branch check and the author's test build

- [ ] **Step 1:** Build all: Win32 and Win64 Release of XRayCalc3, xrccmd, XRFCalc, XRCUncert; Win64 Release of XRC_MCP; the tests. No errors; no new hints or warnings.
- [ ] **Step 2:** Whole suite with the gate off (expect every test passing; the count goes into the Outcome). With `XRC_TRUTH_GATE=1`: `--run:TestUncertEndToEnd.TTestUncertEndToEnd` and the three `TestTruthGate.TTestTruthGate.*_TruthInsideRange` cases, in the background. The numbers of `PeriodicHeldPeriod_FromProjectFile` go into the Outcome.
- [ ] **Step 3:** `XRC_MCP\smoke\session.ps1` exits 0 (the server's `fit.xrcx` changed in "Before this plan").
- [ ] **Step 4:** Whole-branch review by a fresh reviewer (`code-reviewer`) over `72ce853..HEAD` against this plan and the spec; fix every Critical and Important finding test-first; list deferred minors in the ledger.
- [ ] **Step 5: Test build.** `bash _Installer/deploy.sh`, then `ISCC.exe /FXRayCalc3_Setup_3.9.5-uncert-test _Installer/XRayCalc3Setup.iss`; copy the result to `Z:\files\Software\`. Do not edit `Z:\index.html`. Nothing is pushed.
- [ ] **Step 6:** Fill in the Outcome section below; update the memory file `uncertainty_tool_project.md` and the handoff; commit `* Plan B2: outcome`.
- [ ] **Step 7: Stop and hand the author this checklist** (the GUI is his to judge; spec test 5.5):
  1. Install the test build; open a fitted periodic project in the main program; Calc - Parameter uncertainties: the tool opens on that project.
  2. Run: the time left counts down; the list fills with value ± error; the curve band lies on the data.
  3. Enter a Known value and ± on Total thickness; the result shows as out of date; Run again.
  4. Close the tool; in the main program change nothing and save; open the tool again: the result is still there. Change a thickness, save, open the tool: out of date.
  5. A profile project and a small table project: the Depth tab and its band.
  6. Stop during a run; close the window during a run; drop another project on the window during a run.
  7. A project with a `.xrdml` source that holds raw counts, and one without: the counts warning.
  8. Details, Copy table, Export, Help.
  9. Flag for the book: the Calc menu has one more item (any figure of that menu changes).

---

## Outcome

_2026-10-02. Tasks 1 to 6 implemented, reviewed once by a fresh reviewer, fixed; the test build is on
`Z:\files\Software\XRayCalc3_Setup_3.9.5-uncert-test.exe` (`Z:\index.html` not touched). Nothing is on
master; nothing is pushed._

**What was checked, and how**

| Check | Result |
|---|---|
| Whole suite, Win32 Debug, gate off | 1177 of 1177 (was 1129 before this plan) |
| End to end on project files, gate on (`TestUncertEndToEnd`) | 5 of 5 |
| Build: XRayCalc3, xrccmd, XRFCalc, XRCUncert (Win32 + Win64 Release), XRC_MCP (Win64) | no errors; no hints or warnings from the new units |
| `XRC_MCP\smoke\session.ps1` | PASS |
| `deploy.sh` + Inno Setup | installer built, 13.2 MB |

The held-period case at the standard recipe (the truth gate's cell, counting noise at I0 = 1E7, the
project saved without Free period, 32 walkers, 4000 steps, CPU, 52 s, settled at the first attempt):

| Value | Truth | 2.5 % | 50 % | 97.5 % | R-hat |
|---|---|---|---|---|---|
| period, Å | 34 | 33.9999 | 34.0001 | 34.0004 | 1.02 |
| interlayer thickness, Å | 6 | 5.99991 | 6.00014 | 6.00036 | 1.02 |

The other four end-to-end cases give the numbers of plan B1's Outcome to the last digit shown.

**What this does not show**

- **The window has never been run.** By the project's rule nobody launched XRCUncert or the main program
  to look at them. The form and its DFM are checked by the compiler and by one reader only; whether the
  form loads, how it looks, and how the cell editor behaves under real clicks are the author's checklist
  (Task 7, Step 7). The most likely first-run fault is a DFM property the form does not accept.
- The truth-gate fixture was not re-run to the end (stopped at its one-hour limit). It tests plan A's
  sampler core through its own map, which this plan did not change.
- The graphics-card path was not exercised by any test here (the tests run on the CPU); the window asks
  for the card and falls back as plan B1's runner does.
- No real measurement was used; no `.xrdml` with raw counts was opened through the window.
- Whether a stored result still counts as current after an unchanged save in the main program was not
  tested (checklist step 4). If it shows as out of date there, the fingerprint must be taken over the
  parsed structure instead of its text.

**Review.** One fresh reviewer over the whole range, reading only. No Critical finding. Fixed: a known
value entered with the mouse was refused and lost; after a refusal the editor opened on a cell nobody
clicked; a dropped file that was not a project stopped a running run before being refused; a zip entry
with a folder in its name was written outside the working folder by the main program's save step; a
fit period window of 100 % or more made a project impossible to analyse. The cell-edit decision now
lives in `unit_UncertView.DecideCellEdit` with six tests. Deferred minors and every ruling are in the
ledger (`.superpowers/sdd/2026-10-02-uncertainty-tool-planB2/progress.md`).

**Where the implementation differs from this plan**

- A sampled period is one row, "Period": no separate period row beside an identical mean-period row.
- `KeepToolEntries` is in `Shared/Bayes/unit_UncertKeep.pas`, so the main program links no sampler code.
- Calc - Parameter uncertainties always asks before saving (the main program does not track changes).
- A known value typed before its ± stays on the row, unsaved, until the ± is given; Enter moves on to
  the ± cell.
- Tasks 3 and 4 are one commit. The thread was written with its tests (no failing run seen first).
- The tool has no icon of its own; it uses the main program's.
- The series' point sizes are set in `FormCreate`, not in the DFM.
- A fit's own period window is cut to 50 % of the period.
