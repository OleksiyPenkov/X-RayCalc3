# Uncertainty tool, headless part (plan B1) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Everything XRCUncert does without its window: read a fitted `.xrcx`, build the parameter map for its fit mode, run the sampler to a settled answer or a plain refusal, and store the result and the priors in the project file. Proven end to end on a project file with known truth.

**Architecture:** Four small VCL-free units in `Shared/Bayes/` on top of plan A's core: a request builder (project to map), a runner (settle, restart, sample, repeat once), a result file (JSON plus the archive entry writer), and the counts reader. The window of plan B2 only draws what these return.

**Tech Stack:** Delphi 13, DUnitX, `System.Zip`, `System.JSON`; plan A's `Shared/Bayes` core; `unit_MCPProjectFile.ReadXRCX`, `unit_MCPStructure.StructureFromXRCData`, `unit_xrdml`.

**Spec:** `docs/superpowers/specs/2026-10-01-uncertainty-tool-design.md` (sections 1, 3 and 4; decisions 2 to 7, 4a). Plan A's Outcome section is the evidence for the run recipe and the table limit.

## Global Constraints

- Work only in the worktree `.claude/worktrees/uncertainty-tool`, branch `worktree-uncertainty-tool`. Never merge, rebase onto, or push to `master`.
- Invoke `my-skills:delphi-development` before writing or changing code. Commit prefixes `+` / `*`, attribution lines at the end of every message. New files carry the short MIT header.
- The new units use no VCL and no server unit (jobs, sandbox, inbox). `unit_MCPErrors`, `unit_MCPStructure` and `unit_MCPProjectFile` are allowed: the main app already links them.
- The project version stays 8. The tool never rewrites `params.dsc`, `project.dsc`, `calc.dat` or any `data_*.dat`.
- User-facing text says "uncertainty", never "posterior"; every message a user can see is a plain sentence in XRR terms.
- Tests: Win32 Debug, in `XRayCalc3/Tests`, registered in `XRayCalc3Tests.dpr` and `.dproj` as plan A's were. Build and run commands as in plan A. Each task is test first: write the test, see it fail, implement, see it pass, run the whole suite, commit.
- Scope cuts agreed for this version (do not add back): no model picker (the project's active model and its linked curve, as `ReadXRCX` takes them); no joint fits; the substrate is not sampled (the classic engines do not fit it either); limits are not edited.

## Decisions this plan makes (the spec left them open)

| # | Decision | Why |
|---|---|---|
| D1 | Which values are sampled: every layer value that is not `Fixed` and has `min < max`, in the fit mode stored in the project (`[FIT] Mode`: 0 table, 1 periodic, 2 profile). | "The free parameters and their limits are taken as they stand." |
| D2 | Periodic mode, each repeating stack: one slot per free value; the stack's thickest free thickness becomes the derived layer; the period is a slot only when the fit had Free period on, within its Period window, and is held at the fitted value otherwise. A held period is reported as held, with no ±. | The classic periodic fit does the same: it holds D unless Free period is on. |
| D3 | Profile mode: an unpaired free value of a repeating stack is a profile whose coefficients come from the layer's gradient extension (first-order with zero gradient when there is none); everything else is a plain slot. | As `TLFPSO_Poly` treats them. |
| D4 | Table mode: an unpaired free value of a repeating stack is a table (tables kept); everything else is a plain slot. More than 20 table slots: refused before the run. | Spec decision 4. |
| D5 | Every repeating stack gets its summary numbers. Priors are stored and applied by reported name; only plain slots, derived layers and summaries can carry one. | Plan A, `TParamMap.SetPrior`. |
| D6 | Run recipe: walkers = max(32, 2 x slots + 2); settle 1000, restart around the best walker, 3000 steps with 1000 burn-in, every 10th recorded. If `RHatWorst > RHAT_AGREE`: once more at three times every length. Still above: the result carries no ranges and the message "The fit has not settled: the uncertainties cannot be given. Refit the model and try again." | Plan A's gate ran exactly this recipe. |
| D7 | Nuisance ranges: scale window 0.2 in log10, background 0 to 10 x the smallest measured value, f from 0.001 to 1. | The 3.10 defaults (`DEF_LIKE_SCALE_WINDOW`, `DEF_F_MIN`). |
| D8 | Result entry `uncert_<model id>.json`; counts entry `counts_<data id>.dat`. The fingerprint is a SHA-256 over the model's structure string, the profile coefficients, the fit mode, the curve's points, the counts and the priors. | Spec section 1.5. |

## Review Focus

1. **A project with no linked curve, or a model with nothing free:** a plain refusal, not an exception trace.
2. **A fitted value outside its own limits** (the classic engines can leave one there after a manual edit): the start is infeasible; the tool must say which value and why, before running.
3. **A wavelength-scan project** (`[PARAMS] Mode` not theta): refused in plain words; the likelihood is theta-only.
4. **The `.xrdml` source is gone, or its angles no longer match the curve** (trimmed, smoothed): run without counts and say so; never attach counts to the wrong points.
5. **The project file is read-only or open elsewhere when the result is written:** the result stays in memory and the caller is told; the project is never left half-written.

---

### Task 1: Counts from the `.xrdml` source

**Files:** Replace from the archive: `Shared/Universal/unit_xrdml.pas`, `XRayCalc3/Tests/TestXRDML.pas`. Create: `Shared/Bayes/unit_UncertCounts.pas`, `XRayCalc3/Tests/TestUncertCounts.pas`.

**Interfaces:**
- Consumes: `TXRDMLScan.Counts`, `ScanCurveInChartUnit(Scan, TwoTheta)`, `SameScanAngles(A, B)`, `SameScanIntensities(Scan, Curve, Counts)` (all restored from `archive/3.10-bayes`; the diff against master is additive).
- Produces:

```pascal
type
  TCountsSource = (csNone, csStored, csSourceFile);
/// The raw counts for Curve, one per point, or nil. Tries SourceFile (an
/// .xrdml whose angles and intensities match Curve up to one factor); Why says
/// in plain words why there are none.
function CountsFromSource(const SourceFile: string; const Curve: TDataArray;
  out Why: string): TArray<Double>;
/// The '* Source file: ' line of a data node's description; '' when absent.
function SourceFileOf(const Description: string): string;
function CountsToText(const Counts: TArray<Double>): string;      // one number per line, invariant
function CountsFromText(const Text: string): TArray<Double>;
```

- [ ] **Step 1:** `git checkout archive/3.10-bayes -- Shared/Universal/unit_xrdml.pas XRayCalc3/Tests/TestXRDML.pas`; check `git diff HEAD` shows additions only (one changed line in the test file: keep master's wording if it is a comment).
- [ ] **Step 2:** Write `TestUncertCounts`: source file missing gives nil and "The measurement file ... was not found"; an `.xrdml` whose angles match gives its counts; a curve with one point removed gives nil and "The curve no longer matches its measurement file (it was trimmed or smoothed)"; a file with intensities instead of counts gives nil and "The measurement file holds no raw counts"; `SourceFileOf` on a three-line description; text round trip of counts including 0. Use the `.xrdml` fixtures `TestXRDML` already uses.
- [ ] **Step 3:** Build: expect `unit_UncertCounts` not found. Implement the unit (about 80 lines; `ReadXRDMLFile`, `IsXRDMLFile`, the two `SameScan*` checks, theta as the chart unit).
- [ ] **Step 4:** Run the fixture and the whole suite; commit `+ Counts from a curve's .xrdml source, for the uncertainty tool`.

### Task 2: The project reader hands over what the tool needs

**Files:** Modify `XRC_MCP/units/unit_MCPProjectFile.pas`; add tests to `XRayCalc3/Tests/TestMCPProjectFile.pas`.

**Interfaces:**
- Produces: `TXRCXProject` gains `ModelID, DataID: Integer` (`DataID` -1 without a curve), `DataNote: string` (the data node's Description), `CalcMode: Integer` (`[PARAMS] Mode`, 0 = theta), and `Params.LFPSO.FreePeriod` / `.PeriodWindow` read from the keys `frame_CalcSettings` writes (`INI_SECTION_SCALE`, `INI_FREE_PERIOD`, `INI_PERIOD_WINDOW`). `WriteXRCX` writes `DataNote` and those keys so a test project round-trips.

- [ ] **Step 1:** Tests: a project written with a data note and Free period on reads back with both, with `ModelID = XRCX_MODEL_ID` and `DataID = XRCX_DATA_ID`; a project without data reads `DataID = -1`; the existing ELN sample project still loads with the same values as before.
- [ ] **Step 2:** See them fail (fields undeclared), implement, whole suite, commit `* ReadXRCX hands over the model and data IDs, the data note, the calc mode and the free-period settings`.

### Task 3: From a project to a parameter map

**Files:** Create `Shared/Bayes/unit_UncertRequest.pas`, `XRayCalc3/Tests/TestUncertRequest.pas`.

**Interfaces:**
- Consumes: Task 2's `TXRCXProject`; `StructureFromXRCData`; plan A's `TParamMap` (`Create(Template, KeepTables)`, `AddParam`, `AddPeriod`, `SetDerived`, `AddTable`, `AddProfile`, `AddSummary`, `AddNuisance`, `SetPrior`).
- Produces:

```pascal
const
  MAX_TABLE_SLOTS = 20;
type
  TFitModeKind = (fmTable, fmPeriodic, fmProfile);       // [FIT] Mode 0, 1, 2
  TUncertPrior = record
    Name: string;            // a reported name
    Mean, SD: Double;
    Note: string;
  end;
  /// One row the window shows, in the map's reported order.
  TUncertName = record
    Name: string;            // the reported name, e.g. 's0.l2.thickness'
    Caption: string;         // 'W  H, Å' - material, H / σ / ρ, unit
    Group: string;           // 'Summary', the stack's title, 'Measurement'
    Held: Boolean;           // a period that is not sampled: shown without ±
    CanHavePrior: Boolean;
    Stack, Layer, P, Period: Integer;   // Period > 0: a point of the depth chart
  end;
  TUncertRequest = record
    Mode: TFitModeKind;
    Structure: TFitStructure;           // as fitted
    Data: TDataArray;
    CalcParams: TCalcThreadParams;
    RMin: Double;
    Names: TArray<TUncertName>;
    TableSlots: Integer;
  end;
/// '' and a request, or a plain sentence saying why this project cannot be
/// analysed (no curve, nothing free, a wavelength scan, a table too large).
function BuildRequest(const P: TXRCXProject; out Req: TUncertRequest): string;
/// The map of Req with the priors set; the caller frees it. Raises
/// EParamMap for a prior on a name that cannot carry one.
function BuildMap(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>): TParamMap;
/// '' or the plain sentence naming the first value that starts outside its
/// own limits ("W thickness in stack 2 is 31.2 Å, outside its limits 10 to 30 Å").
function StartProblem(Map: TParamMap; const Req: TUncertRequest): string;
```

Rules D1 to D5 and D7. Slot names are plan A's: `s<stack>.l<layer>.<thickness|sigma|density>` with the stack and layer as their indices in `TFitStructure.Stacks`, `s<stack>.period`, `s<stack>` as the summary prefix. The roughness function is the one the main app's configuration holds (find where `TCalc` takes it in `frame_CalcSettings.FillCalcThreadParams`; `rfError` when the configuration is not readable); `MVAWindow` and `K` as that same function sets them.

- [ ] **Step 1:** Tests, each on a `TXRCXProject` built in the test with `StructureToXRCData`: periodic with two free thicknesses gives one slot, one derived layer, held period, three summaries, three nuisance slots; Free period on adds `s0.period` within the window; profile mode with a gradient extension gives `c0`, `c1` starting at the layer's value and the extension's gradient; profile mode without an extension starts at zero gradient; table mode gives N slots and keeps the fitted table; 21 table slots are refused with the limit named; no curve, nothing free, wavelength scan each give their sentence; a `Fixed` value and a `min = max` value are not sampled; a prior on a table entry raises; `StartProblem` names a value outside its limits; captions and groups for a two-stack structure.
- [ ] **Step 2:** See them fail, implement, fixture and whole suite, commit `+ unit_UncertRequest: a fitted project as a parameter map, in the project's fit mode`.

### Task 4: The run

**Files:** Create `Shared/Bayes/unit_UncertRun.pas`, `XRayCalc3/Tests/TestUncertRun.pas`.

**Interfaces:**
- Consumes: Task 3; plan A's `TLogPosterior`, `TJointPosterior.CreateSingle`, `TSampleRun` (`Start`, `Advance`, `Recentre`, `Finish`, `RHatWorst`, `RHAT_AGREE`).
- Produces:

```pascal
type
  TUncertValue = record
    Name: string;
    Best, P16, P50, P84, P2_5, P97_5: Double;   // Best: the fitted start value
    Minus, Plus: Double;                        // P50 - P16, P84 - P50
    RHat: Double;
    AtLimit: Boolean;                           // the range touches the value's limit
  end;
  TUncertBand = record                          // the curve band, on the data's angles
    Theta, Measured, P16, P50, P84: TArray<Double>;
  end;
  TUncertResult = record
    Settled: Boolean;                           // False: Values hold no ranges to show
    Message: string;                            // why not, in plain words; '' when settled
    Values: TArray<TUncertValue>;               // in Req.Names' order
    Band: TUncertBand;
    Warnings: TArray<string>;                   // plain sentences
    Device: string;                             // 'CPU' or the adapter
    Correlation: TArray<TArray<Double>>;        // for Details
    Seconds: Double;
    Repeated: Boolean;                          // the longer second run was needed
    Stopped: Boolean;                           // the user stopped it; nothing to show
  end;
  TUncertProgress = reference to procedure(Step, Total: Integer; SecondsLeft: Double);
  TUncertStop = reference to function: Boolean;
/// D6's recipe. Runs on the calling thread, which must not be the VCL main
/// thread; the caller drains OTL messages when it ends (DrainParallelTasksBeforeExit).
function RunUncertainty(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
  const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64;
  const OnProgress: TUncertProgress; const ShouldStop: TUncertStop): TUncertResult;
```

Warnings, each only when true: no counts ("No raw counts: the errors rely on the estimated noise only."); a value at its limit ("<caption> sits at its limit: its error is cut off there."); the GPU failed mid-run ("The graphics card stopped; the run finished on the processor."); a prior that the data did not improve on (half the range at least 0.8 of the prior's ±: "<caption>: the result repeats what was entered as known."). `SecondsLeft` comes from the rate over the last two reports (port `TEtaEstimator` from the archive's `unit_GuiUncertainty`), totalled over the stages still to come.

- [ ] **Step 1:** Tests on plan A's W/B4C fixture (counts as rounded intensities, short lengths through three optional test-only parameters of an overload: settle, steps, burn-in): a run settles, the true thickness is inside the 2.5-97.5 range, `Minus`/`Plus` are positive, the band has one point per data point; without counts the first warning appears; a stop request returns `Stopped` within one report interval; progress is reported with rising steps; a request whose start sits far from the optimum with a recipe too short to settle returns `Settled = False`, `Repeated = True` and the message; a prior narrower than the data pulls the median towards it.
- [ ] **Step 2:** See them fail, implement, fixture and whole suite, commit `+ unit_UncertRun: settle, restart, sample, once more if the walkers disagree, else a plain refusal`.

### Task 5: The result in the project file

**Files:** Create `Shared/Bayes/unit_UncertFiles.pas`, `XRayCalc3/Tests/TestUncertFiles.pas`.

**Interfaces:**
- Produces:

```pascal
function UncertEntryName(ModelID: Integer): string;      // 'uncert_<id>.json'
function CountsEntryName(DataID: Integer): string;       // 'counts_<id>.dat'
/// SHA-256 (hex) over what D8 lists.
function Fingerprint(const P: TXRCXProject; const Counts: TArray<Double>;
  const Priors: TArray<TUncertPrior>): string;
type
  TStoredUncert = record
    Format: Integer;                 // 1
    Fingerprint: string;
    Priors: TArray<TUncertPrior>;    // kept even when there is no result yet
    HasResult: Boolean;
    Result: TUncertResult;
    Names: TArray<TUncertName>;
  end;
function StoredToJSON(const S: TStoredUncert): string;
function StoredFromJSON(const Text: string; out S: TStoredUncert): Boolean;
/// Entry Name of the archive as text; False when it is not there.
function ReadEntry(const ProjectFile, Name: string; out Text: string): Boolean;
/// Adds or replaces the named entries and leaves every other entry byte for
/// byte as it was: written to a temporary file beside the project, then
/// swapped in. Returns '' or a plain sentence (read-only, in use); the project
/// is untouched when it fails.
function WriteEntries(const ProjectFile: string; const Names, Texts: TArray<string>): string;
```

- [ ] **Step 1:** Tests: JSON round trip of a result with warnings, a held value, NaN-free numbers and priors; `StoredFromJSON` on garbage returns False; the fingerprint changes with the structure string, a data point, a count and a prior, and not with the model title; `WriteEntries` on a project written by `WriteXRCX` leaves `params.dsc`, `project.dsc`, `calc.dat` and `data_2.dat` with identical bytes, adds the entry, replaces it on a second call, and `ReadXRCX` still reads the project; on a read-only file it returns its sentence and the file's bytes are unchanged.
- [ ] **Step 2:** See them fail, implement (`System.Zip.TZipFile`: read each entry's bytes, write them to the new archive, then the tool's entries; `TFile.Replace` or delete-and-rename for the swap), fixture and whole suite, commit `+ unit_UncertFiles: the uncertainty result and priors as entries of the project file`.

### Task 6: End to end on a project file with known truth

**Files:** Create `XRayCalc3/Tests/TestUncertEndToEnd.pas`.

**Interfaces:** consumes Tasks 1 to 5 and plan A's gate helpers (`Cell`, `TruthStructure`, `Noisy`, `ClassicFit` move from `TestTruthGate` into its interface section).

Opt-in with `XRC_TRUTH_GATE=1`, like the gate, because it runs the full recipe.

- [ ] **Step 1:** For each of periodic, profile and a 10-entry table: build the truth, the noisy curve and the classic fit as the gate does; write the fitted model and the curve as a project with `WriteXRCX` (profile: the gradient extension; table: the table extension and the tables in the structure string); then only through the tool's own path: `ReadXRCX`, `BuildRequest`, `BuildMap`, `StartProblem`, `RunUncertainty`, `WriteEntries`, and again `ReadXRCX`, `ReadEntry`, `StoredFromJSON`. Assert: no refusal; `Settled`; the truth inside the 2.5-97.5 range of the free value(s) and of the mean period; the stored result equals the one returned; the fingerprint of the re-read project matches; after changing one thickness in the structure string it does not.
- [ ] **Step 2:** One more case: the same periodic project with a 40-entry table model is refused by `BuildRequest` with the limit's sentence, and nothing is written.
- [ ] **Step 3:** Run with the gate on; record the numbers (coverage, time per case, the device) in an Outcome section at the end of this plan; whole suite with the gate off; commit `+ The uncertainty tool's headless path, end to end on project files with known truth`.
- [ ] **Step 4:** Stop and report to the author. Plan B2 (the window, the main app's menu item and save step, installer, help) is written after this.

---

## Outcome

_2026-10-02. Win32 Debug, CPU, one seed per case. Each case: the truth gate's truth, counting noise at
I0 = 1E7 and classic fit; the fitted model written as a project file; then the tool's own path (read the
project, build the request, the standard recipe, write the result and the counts into the project,
read both back)._

| Case | Value | Truth | 2.5 % | 50 % | 97.5 % | R-hat | Time |
|---|---|---|---|---|---|---|---|
| Periodic, period free | period, Å | 34 | 33.9999 | 34.0001 | 34.0004 | 1.01 | 52 s |
| | interlayer thickness, Å | 6 | 5.99991 | 6.00014 | 6.00036 | 1.01 | |
| Profile | gradient, Å per period | 0.05 | 0.04997 | 0.05009 | 0.05022 | 1.03 | 52 s |
| | thickness in period 20, Å | 6.45 | 6.4497 | 6.4510 | 6.4523 | 1.03 | |
| | mean period, Å | 33.975 | 33.9749 | 33.9751 | 33.9754 | 1.02 | |
| | drift, Å | 0.95 | 0.9494 | 0.9517 | 0.9541 | 1.03 | |
| Table, 10 entries | mean period, Å | 34.0108 | 34.0089 | 34.0105 | 34.0121 | 1.07 | 36 s |
| | total thickness, Å | 340.108 | 340.089 | 340.105 | 340.121 | 1.07 | |

Every truth is inside its 2.5-97.5 % range; every run settled at the first attempt (32 walkers, 4000
steps). The stored result equals the computed one to the last bit, the stored fingerprint matches the
re-read project, and it stops matching once the model's structure string changes. A 40-entry table
model is refused before anything runs and the project is not written to. Whole suite with the gate
off: 1123 of 1123.

One fault found by this run and fixed: the result file wrote numbers with too few digits, so a stored
value came back one bit off (`Json_NumbersComeBackToTheLastBit`).

What this does not show: one seed per case is a check that the path works, not a coverage rate (plan
A's gate has those); no real measurement was used; the GPU was not used; the counts came from the
test, not from an `.xrdml` (that path is unit-tested on its own).

Tasks 1, 2 and 5 were written test and implementation together, so their tests were not seen failing
first; Tasks 3, 4 and the precision fix were.
