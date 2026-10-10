# Uncertainty core (plan A) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Restore the headless Bayes core from `archive/3.10-bayes` into `Shared/Bayes/`, extend it from periodic structures to profiles and tables, and prove on calculated curves with known truth that the reported ranges are right.

**Architecture:** The sampler, likelihood, posterior and GPU scorer come back unchanged. Two places change: `FillLayeredModel` (structure to layers) reads each period's value through `TLayerData.PeriodValue`, and `TParamMap` gains table slots, profile slots and per-stack summary numbers. A truth-gate fixture runs classic fit then sampler for each mode and writes a report.

**Tech Stack:** Delphi 13 (RAD Studio 37.0), DUnitX, OmniThreadLibrary 3.08 (patched), D3D11 compute (existing `TGpuEvaluator`).

**Spec:** `docs/superpowers/specs/2026-10-01-uncertainty-tool-design.md` (sections 4, 5 and 6; plan B covers the tool).

## Global Constraints

- Work only in the worktree `.claude/worktrees/uncertainty-tool`, branch `worktree-uncertainty-tool`. Never merge, rebase onto, or push to `master`.
- Invoke the `my-skills:delphi-development` skill before writing or changing code.
- Commit prefixes: `+` new feature, `*` modification or fix. End every commit message with the session's attribution lines.
- New files carry the short MIT header (copy it from `Shared/Bayes/unit_Likelihood.pas` once restored).
- Fields before methods in each visibility section of a class (`E2169` otherwise).
- Tests are Win32 Debug only. A test that needs the Henke tables W, B4C, Si passes with a note when they are missing (`TWB4CFixture.TablesPresent`), as the restored tests do.
- User-facing text says "uncertainty", never "posterior"; code keeps its names.
- Not restored, do not bring back: `unit_BayesRequest`, `unit_LFPSO_Posterior`, the MCP sample units, any `unit_Gui*`, the `TFitValue` prior fields, `TLayerData.Derived`, project version 9.
- `Shared/Math/unit_gpu_calc.pas` regains the likelihood kernel; every existing GPU and fit test must pass unchanged.

**Build the tests** (PowerShell; a fresh worktree also needs `XRC_MCP/units/gitrev.inc`, already generated here):

```powershell
$env:BDS = 'C:\Program Files (x86)\Embarcadero\Studio\37.0'; $env:BDSCOMMONDIR = 'C:\Users\Public\Documents\Embarcadero\Studio\37.0'; & 'C:\Windows\Microsoft.NET\Framework\v4.0.30319\msbuild.exe' XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal 2>&1 | Select-String -Pattern 'error|Fatal'
```

**Run the tests** (whole suite; baseline on this branch is 928 passed, 0 failed):

```powershell
$env:PATH = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;$env:PATH"; & XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue 2>&1 | Select-Object -Last 12
```

**Run one fixture:** add `--run:<UnitName>.<ClassName>`, e.g. `--run:TestParamMapModes.TTestParamMapModes`. If the runner reports no tests for that name, run the whole suite instead.

## Review Focus

1. **A table shorter than N** (left over after the period count was raised): `AddTable` must start every period from the layer's own value, not read past the table. Test in Task 4.
2. **NaN in a table or profile slot:** `Apply` must return False, not write NaN into the structure. Tests in Tasks 4 and 5.
3. **A fitted profile that leaves the layer's limits in some period:** the start vector is infeasible; `Apply` must say so rather than clamp. Test in Task 5.
4. **A single-period cap stack above a tabled stack:** `FillLayeredModel` must leave the N = 1 stack alone and expand only the tabled one. Test in Task 3.
5. **A curve without counts:** the sampler must run with `Counts = nil`. Test in Task 2.

---

### Task 1: Restore the core units and their tests

**Files:**
- Create (from the archive): `Shared/Bayes/unit_Xoshiro.pas`, `unit_ChainStats.pas`, `unit_Expression.pas`, `unit_StretchSampler.pas`, `unit_Likelihood.pas`, `unit_ParamMap.pas`, `unit_LogPosterior.pas`, `unit_JointPosterior.pas`, `unit_PosteriorBatch.pas`, `unit_GpuPosterior.pas`
- Create (from the archive): `XRayCalc3/Tests/TestXoshiro.pas`, `TestChainStats.pas`, `TestExpression.pas`, `TestStretchSampler.pas`, `TestLikelihood.pas`, `TestParamMap.pas`, `TestLogPosterior.pas`, `TestJointPosterior.pas`, `TestPosteriorBatch.pas`, `TestGpuPosterior.pas`
- Replace (from the archive): `Shared/Math/unit_gpu_calc.pas`, `XRayCalc3/Tests/TestGpuCalc.pas`
- Modify: `XRayCalc3/LFPSO/unit_LFPSO_Base.pas` (interface, after `SetMaterial`'s declaration near line 213)
- Modify: `XRayCalc3/Tests/XRayCalc3Tests.dpr`, `XRayCalc3/Tests/XRayCalc3Tests.dproj`

**Interfaces:**
- Consumes: nothing from this plan.
- Produces: `TParamMap` (`Create(Template)`, `AddParam`, `AddPeriod`, `SetDerived`, `AddNuisance(ScaleWindowLog, BgMin, BgMax, FMin, FMax)`, `SetPrior`, `Apply(Theta, var S, out Nuis): Boolean`, `PriorTerm`, `ReportedNames`, `ReportedValues`, `StartVector`, `Template`); `TLogPosterior.Create(Map, Data, Counts, CalcParams, RMin, NMin)`, `.EvaluateOnce(Theta, out Curve): TPosteriorTerms`; `FillLayeredModel(Model, S)`; `TJointPosterior.CreateSingle(Posterior, Owns)`; `TPosteriorBatch.Create(Joint, Workers, UseGPU)`, `.LogProb`, `.LogProbOnCpu`, `.GpuUsed`; `TXoshiro256` (`Seed(UInt64)`, `NextDouble`, `NextGaussian`); `TWB4CFixture` in `TestLogPosterior` (`TablesPresent`, `Structure(H2)`, `Angles`, `CalcParams(Data, Resolution)`).

- [ ] **Step 1: Bring the units and tests out of the archive**

```bash
git checkout archive/3.10-bayes -- XRayCalc3/Bayes/unit_Xoshiro.pas XRayCalc3/Bayes/unit_ChainStats.pas XRayCalc3/Bayes/unit_Expression.pas XRayCalc3/Bayes/unit_StretchSampler.pas XRayCalc3/Bayes/unit_Likelihood.pas XRayCalc3/Bayes/unit_ParamMap.pas XRayCalc3/Bayes/unit_LogPosterior.pas XRayCalc3/Bayes/unit_JointPosterior.pas XRayCalc3/Bayes/unit_PosteriorBatch.pas XRayCalc3/Bayes/unit_GpuPosterior.pas
git mv XRayCalc3/Bayes Shared/Bayes
git checkout archive/3.10-bayes -- XRayCalc3/Tests/TestXoshiro.pas XRayCalc3/Tests/TestChainStats.pas XRayCalc3/Tests/TestExpression.pas XRayCalc3/Tests/TestStretchSampler.pas XRayCalc3/Tests/TestLikelihood.pas XRayCalc3/Tests/TestParamMap.pas XRayCalc3/Tests/TestLogPosterior.pas XRayCalc3/Tests/TestJointPosterior.pas XRayCalc3/Tests/TestPosteriorBatch.pas XRayCalc3/Tests/TestGpuPosterior.pas
git checkout archive/3.10-bayes -- Shared/Math/unit_gpu_calc.pas XRayCalc3/Tests/TestGpuCalc.pas
```

- [ ] **Step 2: Check what the two replaced files lost from master**

Run: `git diff HEAD -- Shared/Math/unit_gpu_calc.pas XRayCalc3/Tests/TestGpuCalc.pas`

Expected: additions only (the `LogLik` kernel, `TGpuLikInputs`, `SetupLikelihood`, `EvaluateLikelihood`, four `LogLik_*` tests) plus a handful of reworded comment lines. For every removed (`-`) line that is a comment master worded differently, put master's wording back by hand. A removed line of code is a stop: report it instead of continuing.

- [ ] **Step 3: Export the two helpers the batch and the GPU scorer use**

In `XRayCalc3/LFPSO/unit_LFPSO_Base.pas`, in the interface section directly after the line `procedure SetMaterial(var Data: TLayerData; const Name: string); inline;`, add:

```pascal
  { OTL's Parallel.&For does not hand an exception raised in the loop body
    back to the caller - the worker never signals completion and the caller
    waits for ever. Every loop body keeps the first exception with
    KeepFirstError; the caller raises it with RaiseKept once the loop is
    over. }
  procedure KeepFirstError(var Slot: Pointer);
  procedure RaiseKept(var Slot: Pointer);
```

The implementations already exist in that unit (lines 332-349); nothing else changes there.

- [ ] **Step 4: Register the units in the test program**

In `XRayCalc3/Tests/XRayCalc3Tests.dpr` replace the last line of the uses list

```pascal
  TestOtlDrain in 'TestOtlDrain.pas';
```

with

```pascal
  TestOtlDrain in 'TestOtlDrain.pas',
  unit_Xoshiro in '..\..\Shared\Bayes\unit_Xoshiro.pas',
  TestXoshiro in 'TestXoshiro.pas',
  unit_ChainStats in '..\..\Shared\Bayes\unit_ChainStats.pas',
  TestChainStats in 'TestChainStats.pas',
  unit_Expression in '..\..\Shared\Bayes\unit_Expression.pas',
  TestExpression in 'TestExpression.pas',
  unit_StretchSampler in '..\..\Shared\Bayes\unit_StretchSampler.pas',
  TestStretchSampler in 'TestStretchSampler.pas',
  unit_Likelihood in '..\..\Shared\Bayes\unit_Likelihood.pas',
  TestLikelihood in 'TestLikelihood.pas',
  unit_ParamMap in '..\..\Shared\Bayes\unit_ParamMap.pas',
  TestParamMap in 'TestParamMap.pas',
  unit_LogPosterior in '..\..\Shared\Bayes\unit_LogPosterior.pas',
  TestLogPosterior in 'TestLogPosterior.pas',
  unit_JointPosterior in '..\..\Shared\Bayes\unit_JointPosterior.pas',
  TestJointPosterior in 'TestJointPosterior.pas',
  unit_PosteriorBatch in '..\..\Shared\Bayes\unit_PosteriorBatch.pas',
  TestPosteriorBatch in 'TestPosteriorBatch.pas',
  unit_GpuPosterior in '..\..\Shared\Bayes\unit_GpuPosterior.pas',
  TestGpuPosterior in 'TestGpuPosterior.pas';
```

In `XRayCalc3/Tests/XRayCalc3Tests.dproj`:
- in `<DCC_UnitSearchPath>` (line 52) insert `..\..\Shared\Bayes;` directly after `..\..\Shared\Math;`
- directly after `<DCCReference Include="TestOtlDrain.pas"/>` add one `<DCCReference Include="..."/>` line per entry above, in the same order, with the same paths (`..\..\Shared\Bayes\unit_Xoshiro.pas`, `TestXoshiro.pas`, and so on).

- [ ] **Step 5: Build**

Run the build command from Global Constraints.
Expected: no `error` or `Fatal` lines. If a restored unit names something that exists only on the archive branch, find it with `git diff HEAD archive/3.10-bayes -- <the file that declares it>`, port only that declaration, and name it in the commit message. `unit_LFPSO_Posterior`, `unit_BayesRequest` and `unit_MCP*` must not be needed; if one is, stop and report.

- [ ] **Step 6: Run the whole suite**

Expected: `Tests Failed : 0`, `Tests Errored : 0`, and `Tests Found` above 1010 (928 before, plus the restored fixtures). `Test_Clipboard_Roundtrip` is a known random error, not a regression.

- [ ] **Step 7: Commit**

```bash
git add Shared/Bayes Shared/Math/unit_gpu_calc.pas XRayCalc3/LFPSO/unit_LFPSO_Base.pas XRayCalc3/Tests
git commit -m "+ Bayes core restored into Shared/Bayes from archive/3.10-bayes; GPU likelihood kernel back"
```

---

### Task 2: The sampler run, driven without the server

**Files:**
- Create (from the archive): `Shared/Bayes/unit_SampleRun.pas`
- Create: `XRayCalc3/Tests/TestSampleRun.pas` (new; the archived one needs the MCP request layer)
- Modify: `XRayCalc3/Tests/XRayCalc3Tests.dpr`, `XRayCalc3/Tests/XRayCalc3Tests.dproj`

**Interfaces:**
- Consumes: Task 1's `TParamMap`, `TLogPosterior`, `TJointPosterior`, `TWB4CFixture`.
- Produces: `TSampleRun.Create(Joint, Walkers, Threads, UseGPU, Derived)`, `.Start(StartMode, StartTheta, Seed)` with `StartMode` `'fit'` or `'bounds'`, `.Advance(BurnIn, Thin): Boolean`, `.Finish(Data: TArray<TDataArray>; PredictiveSamples: Integer; Seed: UInt64): TSampleResult`, `.Rows`, `.Names`; `TSampleResult.Params[k]` with `.Name` and `.Summary` (`Mean, P2_5, P16, P50, P84, P97_5`), `.Bands[m]` (`Present, Theta, Measured, P16, P50, P84`), `.AcceptanceMean`, `.TauSlowest`, `.TauDoubtful`.

- [ ] **Step 1: Bring the unit out of the archive**

```bash
git checkout archive/3.10-bayes -- XRayCalc3/Bayes/unit_SampleRun.pas
git mv XRayCalc3/Bayes/unit_SampleRun.pas Shared/Bayes/unit_SampleRun.pas
```

It uses `unit_MCPErrors` (`EMCPError`), which is already in the test program and free of server code. Leave that as it is.

- [ ] **Step 2: Write the failing test**

Create `XRayCalc3/Tests/TestSampleRun.pas` with the MIT header and:

```pascal
unit TestSampleRun;

(* TSampleRun driven directly, as the uncertainty tool drives it: no job, no
   files, no JSON. The model is TestLogPosterior's W/B4C cell; the data is its
   own curve at the true vector, as counts. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestSampleRun = class
  public
    [Test] procedure Runs_RowsStatsAndBand;
    [Test] procedure NothingRecorded_NoBand;
    [Test] procedure SameSeed_SameRows;
    [Test] procedure WithoutCounts_Runs;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Types, unit_Likelihood, unit_ParamMap,
  unit_LogPosterior, unit_JointPosterior, unit_SampleRun, TestLogPosterior;

const
  WALKERS = 16;
  I0 = 1E6;

type
  { Everything one run owns, freed in the reverse order of creation. }
  TRig = record
    Map: TParamMap;
    Post: TLogPosterior;
    Joint: TJointPosterior;
    Run: TSampleRun;
    Data: TDataArray;
    procedure Build(WithCounts: Boolean);
    procedure Chain(Steps, BurnIn: Integer; Seed: UInt64);
    procedure Free;
  end;

function MakeMap: TParamMap;
begin
  Result := TParamMap.Create(TWB4CFixture.Structure(6));
  Result.AddParam('s0.l2.thickness', 0, 2, 1);
  Result.SetDerived('s0.l3.thickness', 0, 3);
  Result.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
end;

procedure TRig.Build(WithCounts: Boolean);
var
  R: TDataArray;
  Counts: TArray<Double>;
  Truth: TLogPosterior;
  i: Integer;
begin
  Self := Default(TRig);
  Map := MakeMap;
  Data := TWB4CFixture.Angles;
  Truth := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
  try
    Truth.EvaluateOnce(Map.StartVector, R);
  finally
    Truth.Free;
  end;
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Counts[i] := Round(R[i].r * I0);
    Data[i].r := Max(Counts[i], 1) / I0;
  end;
  if not WithCounts then
    Counts := nil;
  Post := TLogPosterior.Create(Map, Data, Counts, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
  Joint := TJointPosterior.CreateSingle(Post, False);
  Run := TSampleRun.Create(Joint, WALKERS, 1, False, nil);
end;

procedure TRig.Chain(Steps, BurnIn: Integer; Seed: UInt64);
var
  st: Integer;
begin
  Run.Start('fit', Joint.StartVector, Seed);
  for st := 1 to Steps do
    Run.Advance(BurnIn, 1);
end;

procedure TRig.Free;
begin
  Run.Free;
  Joint.Free;
  Post.Free;
  Map.Free;
end;

procedure TTestSampleRun.Runs_RowsStatsAndBand;
var
  Rig: TRig;
  R: TSampleResult;
  k: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(True);
  try
    Rig.Chain(60, 20, 7);
    Assert.AreEqual(WALKERS * 40, Rig.Run.Rows.Count, '40 recorded steps of 16 walkers');
    R := Rig.Run.Finish([Rig.Data], 10, 7);
    Assert.AreEqual(60, R.StepsTotal);
    Assert.AreEqual(40, R.PerWalker);
    Assert.AreEqual(Length(Rig.Run.Names), Length(R.Params));
    for k := 0 to High(R.Params) do
      Assert.AreEqual(Rig.Run.Names[k], R.Params[k].Name);
    Assert.AreEqual('s0.l2.thickness', R.Params[0].Name);
    Assert.IsTrue((R.Params[0].Summary.P50 > 5.5) and (R.Params[0].Summary.P50 < 6.5),
      Format('the chain stays at the true 6 A, median %g', [R.Params[0].Summary.P50]));
    Assert.AreEqual(1, Length(R.Bands));
    Assert.IsTrue(R.Bands[0].Present);
    Assert.AreEqual(Length(Rig.Data), Length(R.Bands[0].Theta), 'one band point per measured point');
    Assert.AreEqual('CPU', R.DeviceUsed);
  finally
    Rig.Free;
  end;
end;

procedure TTestSampleRun.NothingRecorded_NoBand;
var
  Rig: TRig;
  R: TSampleResult;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(True);
  try
    Rig.Chain(5, 10, 7);            // every step is burn-in
    R := Rig.Run.Finish([Rig.Data], 10, 7);
    Assert.AreEqual(0, R.Recorded);
    Assert.IsFalse(R.Bands[0].Present, 'nothing to draw a band from');
  finally
    Rig.Free;
  end;
end;

procedure TTestSampleRun.SameSeed_SameRows;
var
  A, B: TRig;
  i, k: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  A.Build(True);
  B.Build(True);
  try
    A.Chain(20, 5, 42);
    B.Chain(20, 5, 42);
    Assert.AreEqual(A.Run.Rows.Count, B.Run.Rows.Count);
    for i := 0 to A.Run.Rows.Count - 1 do
      for k := 0 to High(A.Run.Rows[i].Values) do
        Assert.AreEqual(A.Run.Rows[i].Values[k], B.Run.Rows[i].Values[k], 0.0,
          Format('row %d value %d', [i, k]));
  finally
    B.Free;
    A.Free;
  end;
end;

procedure TTestSampleRun.WithoutCounts_Runs;
var
  Rig: TRig;
  R: TSampleResult;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Rig.Build(False);
  try
    Rig.Chain(30, 10, 3);
    R := Rig.Run.Finish([Rig.Data], 10, 3);
    Assert.AreEqual(WALKERS * 20, R.Recorded, 'a curve without counts is sampled with f alone');
    Assert.IsTrue(R.Bands[0].Present);
  finally
    Rig.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestSampleRun);

end.
```

- [ ] **Step 3: Register and build to see it fail**

Append to the `.dpr` uses list (replacing the final `;` after `TestGpuPosterior in 'TestGpuPosterior.pas'` with `,`):

```pascal
  unit_SampleRun in '..\..\Shared\Bayes\unit_SampleRun.pas',
  TestSampleRun in 'TestSampleRun.pas';
```

and the two matching `<DCCReference>` lines to the `.dproj`. Build.
Expected: a clean build (the unit exists). If `TSampleRun` or `TSampleResult` members used above differ from the restored unit's, fix the test to the unit, not the unit to the test.

- [ ] **Step 4: Run the fixture**

Run with `--run:TestSampleRun.TTestSampleRun`.
Expected: 4 passed.

- [ ] **Step 5: Commit**

```bash
git add Shared/Bayes/unit_SampleRun.pas XRayCalc3/Tests
git commit -m "+ unit_SampleRun restored; its tests drive it without the MCP request layer"
```

---

### Task 3: The model reads each period's own value

**Files:**
- Modify: `Shared/Bayes/unit_LogPosterior.pas` (`FillLayeredModel`)
- Create: `XRayCalc3/Tests/TestPosteriorModes.pas`
- Modify: `XRayCalc3/Tests/XRayCalc3Tests.dpr`, `.dproj`

**Interfaces:**
- Consumes: `TLayerData.PeriodValue(Param, Period, N, ExpandTables)` (`unit_Types`): the table value when the stack repeats, the parameter is not paired and the table covers all N periods; the layer's own value otherwise. Period 1 is at the surface.
- Produces: `FillLayeredModel` honouring `TLayerData.PP`; the test helpers `Lay(...)` and `CurveOf(S)` in `TestPosteriorModes`, used again in Tasks 4 and 5.

- [ ] **Step 1: Write the failing test**

Create `XRayCalc3/Tests/TestPosteriorModes.pas` with the MIT header and:

```pascal
unit TestPosteriorModes;

(* The posterior on structures that are not periodic: a per-period table and
   a polynomial profile must give the curve of the same layers written out
   one by one. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

type
  [TestFixture]
  TTestPosteriorModes = class
  public
    [Test] procedure Table_CurveEqualsExplicitStacks;
    [Test] procedure Table_UnderASinglePeriodCap;
    [Test] procedure Periodic_CurveUnchangedByAnEmptyTable;
  end;

function Lay(const M: string; H, HMin, HMax, Sigma, Rho: Single; LayerID: Word): TLayerData;
function CurveOf(const S: TFitStructure): TDataArray;

implementation

uses
  System.SysUtils, System.Math, unit_Likelihood, unit_ParamMap, unit_LogPosterior,
  TestLogPosterior;

function Lay(const M: string; H, HMin, HMax, Sigma, Rho: Single; LayerID: Word): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.LayerID := LayerID;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := Sigma; Result.P[2].min := Sigma; Result.P[2].max := Sigma;
  Result.P[3].V := Rho; Result.P[3].min := Rho; Result.P[3].max := Rho;
end;

function CurveOf(const S: TFitStructure): TDataArray;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Data: TDataArray;
begin
  Data := TWB4CFixture.Angles;
  Map := TParamMap.Create(S);
  try
    Map.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Assert.IsTrue(Post.EvaluateOnce(Map.StartVector, Result).Feasible);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

{ W / B4C, three periods, W thickness 9, 10, 11 A from the surface down. }
function Tabled: TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 3;
  SetLength(Result.Stacks[0].Layers, 2);
  Result.Stacks[0].Layers[0] := Lay('W', 10, 5, 15, 2, 19.3, 0);
  Result.Stacks[0].Layers[0].PP[1] := [9, 10, 11];
  Result.Stacks[0].Layers[1] := Lay('B4C', 15, 15, 15, 2, 2.52, 1);
  Result.Subs := Lay('Si', 0, 0, 0, 3, 2.33, 0);
end;

{ The same six layers as three stacks of one period each. }
function Explicit: TFitStructure;
var
  k: Integer;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 3);
  for k := 0 to 2 do
  begin
    Result.Stacks[k].N := 1;
    SetLength(Result.Stacks[k].Layers, 2);
    Result.Stacks[k].Layers[0] := Lay('W', 9 + k, 5, 15, 2, 19.3, 0);
    Result.Stacks[k].Layers[1] := Lay('B4C', 15, 15, 15, 2, 2.52, 1);
  end;
  Result.Subs := Lay('Si', 0, 0, 0, 3, 2.33, 0);
end;

procedure AssertSameCurve(const A, B: TDataArray; const Msg: string);
var
  i: Integer;
begin
  Assert.AreEqual(Length(A), Length(B), Msg);
  for i := 0 to High(A) do
    Assert.AreEqual(Double(A[i].r), Double(B[i].r), 1E-6 * Abs(A[i].r), Format('%s, point %d', [Msg, i]));
end;

procedure TTestPosteriorModes.Table_CurveEqualsExplicitStacks;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  AssertSameCurve(CurveOf(Explicit), CurveOf(Tabled), 'a table is its layers written out');
end;

procedure TTestPosteriorModes.Table_UnderASinglePeriodCap;
var
  T, E: TFitStructure;
  Cap: TFitStack;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Cap := Default(TFitStack);
  Cap.N := 1;
  SetLength(Cap.Layers, 1);
  Cap.Layers[0] := Lay('B4C', 20, 20, 20, 2, 2.52, 0);
  { a stale table on a single-period layer is not read }
  Cap.Layers[0].PP[1] := [99];
  T := Tabled;
  Insert(Cap, T.Stacks, 0);
  E := Explicit;
  Insert(Cap, E.Stacks, 0);
  AssertSameCurve(CurveOf(E), CurveOf(T), 'the cap keeps its own value');
end;

procedure TTestPosteriorModes.Periodic_CurveUnchangedByAnEmptyTable;
var
  P, Q: TFitStructure;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := TWB4CFixture.Structure(6);
  Q := TWB4CFixture.Structure(6);
  Q.Stacks[0].Layers[2].PP[1] := [1, 2, 3];      // shorter than N = 20: ignored as a whole
  AssertSameCurve(CurveOf(P), CurveOf(Q), 'a table shorter than N is not a table');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestPosteriorModes);

end.
```

Register `TestPosteriorModes in 'TestPosteriorModes.pas'` in the `.dpr` (append, moving the final `;`) and the `.dproj`.

- [ ] **Step 2: Run to see it fail**

Build, run `--run:TestPosteriorModes.TTestPosteriorModes`.
Expected: `Table_CurveEqualsExplicitStacks` and `Table_UnderASinglePeriodCap` FAIL (the model repeats the layer's single value); `Periodic_CurveUnchangedByAnEmptyTable` passes.

- [ ] **Step 3: Implement**

In `Shared/Bayes/unit_LogPosterior.pas` replace the body of `FillLayeredModel` and its doc comment:

```pascal
/// <summary>The expanded model of S: every stack repeated N times, then the
/// substrate. A layer value with a per-period table (TLayerData.PeriodValue:
/// a repeating stack, not paired, the table covering all N periods) takes its
/// own value in every period, period 1 at the surface; a stack without one is
/// built as TLFPSO_BASE.FillModel builds it.</summary>
procedure FillLayeredModel(Model: TLayeredModel; const S: TFitStructure);
```

```pascal
procedure FillLayeredModel(Model: TLayeredModel; const S: TFitStructure);
var
  i, j, k, p, StackLen, MaxStackLen: Integer;
  Data: TLayersData;
  Tabled: Boolean;
begin
  MaxStackLen := 1;
  for i := 0 to High(S.Stacks) do
    if Length(S.Stacks[i].Layers) > MaxStackLen then
      MaxStackLen := Length(S.Stacks[i].Layers);
  if Length(Model.FillScratch) < MaxStackLen then
    SetLength(Model.FillScratch, MaxStackLen);
  Data := Model.FillScratch;

  for i := 0 to High(S.Stacks) do
  begin
    StackLen := Length(S.Stacks[i].Layers);
    Tabled := False;
    for k := 0 to StackLen - 1 do
    begin
      SetMaterial(Data[k], S.Stacks[i].Layers[k].Material);
      for p := 1 to 3 do
      begin
        Data[k].P[p].V := S.Stacks[i].Layers[k].P[p].V;
        if (S.Stacks[i].N > 1) and not S.Stacks[i].Layers[k].P[p].Paired and
           (Length(S.Stacks[i].Layers[k].PP[p]) >= S.Stacks[i].N) then
          Tabled := True;
      end;
      Data[k].StackID := S.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := S.Stacks[i].Layers[k].LayerID;
    end;
    for j := 1 to S.Stacks[i].N do
    begin
      if Tabled then
        for k := 0 to StackLen - 1 do
          for p := 1 to 3 do
            Data[k].P[p].V := S.Stacks[i].Layers[k].PeriodValue(p, j, S.Stacks[i].N, True);
      Model.AddLayers(-1, Data, StackLen);
    end;
  end;

  SetMaterial(Data[0], S.Subs.Material);
  Data[0].P := S.Subs.P;
  Model.AddSubstrate(Data);    // reads Data[0] only
end;
```

- [ ] **Step 4: Run the fixture, then the whole suite**

Expected: 3 passed in the fixture; the whole suite has 0 failed (a periodic structure takes the same code path as before, so every restored test keeps its numbers).

- [ ] **Step 5: Commit**

```bash
git add Shared/Bayes/unit_LogPosterior.pas XRayCalc3/Tests
git commit -m "* FillLayeredModel reads each period's value from the layer's table"
```

---

### Task 4: Table slots

**Files:**
- Modify: `Shared/Bayes/unit_ParamMap.pas`
- Create: `XRayCalc3/Tests/TestParamMapModes.pas`
- Modify: `XRayCalc3/Tests/TestPosteriorModes.pas`, `XRayCalc3Tests.dpr`, `.dproj`

**Interfaces:**
- Consumes: Task 3's `FillLayeredModel`, `Lay`, `CurveOf`.
- Produces: `TSlotKind` gains `skTable, skPoly`; `TParamSlot` gains `Period: Integer` (skTable: the period, from 1; skPoly: the coefficient's order); `procedure TParamMap.AddTable(const Name: string; Stack, Layer, P: Integer)` adding slots `Name[1]` .. `Name[N]`.

- [ ] **Step 1: Write the failing tests**

Create `XRayCalc3/Tests/TestParamMapModes.pas` with the MIT header and:

```pascal
unit TestParamMapModes;

(* TParamMap beyond the periodic cell: table slots, profile slots and the
   per-stack summary numbers. No Henke tables needed: nothing is calculated. *)

interface

uses
  DUnitX.TestFramework, unit_Types;

type
  [TestFixture]
  TTestParamMapModes = class
  public
    [Test] procedure AddTable_OneSlotPerPeriod;
    [Test] procedure AddTable_ShortTable_StartsFromTheValue;
    [Test] procedure AddTable_StartClampedIntoLimits;
    [Test] procedure Apply_TableSlots_WriteTheirPeriod;
    [Test] procedure Apply_TableOutsideLimits_Infeasible;
    [Test] procedure Apply_TableNaN_Infeasible;
    [Test] procedure AddTable_PairedOrSinglePeriod_Raises;
  end;

function Cell5: TFitStructure;

implementation

uses
  System.SysUtils, System.Math, unit_Likelihood, unit_ParamMap;

function Layer(const M: string; H, HMin, HMax: Single): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := 3; Result.P[2].min := 3; Result.P[2].max := 3;
  Result.P[3].V := 5; Result.P[3].min := 5; Result.P[3].max := 5;
end;

{ Two layers, five periods: layer 0 is 10 A [8, 12], layer 1 is 20 A, held. }
function Cell5: TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := 5;
  Result.Stacks[0].D := 30;
  SetLength(Result.Stacks[0].Layers, 2);
  Result.Stacks[0].Layers[0] := Layer('W', 10, 8, 12);
  Result.Stacks[0].Layers[1] := Layer('B4C', 20, 20, 20);
  Result.Subs := Layer('Si', 0, 0, 0);
end;

procedure TTestParamMapModes.AddTable_OneSlotPerPeriod;
var
  S: TFitStructure;
  M: TParamMap;
  k: Integer;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].PP[1] := [9, 9.5, 10, 10.5, 11];
  M := TParamMap.Create(S);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    Assert.AreEqual(5, M.Count);
    for k := 1 to 5 do
    begin
      Assert.AreEqual(Format('s0.l0.thickness[%d]', [k]), M.Slots[k - 1].Name);
      Assert.AreEqual(8.5 + 0.5 * k, M.Slots[k - 1].Start, 1E-6);
      Assert.AreEqual(8.0, M.Slots[k - 1].Lower, 1E-6);
      Assert.AreEqual(12.0, M.Slots[k - 1].Upper, 1E-6);
    end;
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddTable_ShortTable_StartsFromTheValue;
var
  S: TFitStructure;
  M: TParamMap;
  k: Integer;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].PP[1] := [9, 9.5];        // left over from N = 2
  M := TParamMap.Create(S);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    for k := 0 to 4 do
      Assert.AreEqual(10.0, M.Slots[k].Start, 1E-6, 'a table shorter than N is ignored as a whole');
    Assert.AreEqual(5, Length(M.Template.Stacks[0].Layers[0].PP[1]), 'the template carries a full table');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddTable_StartClampedIntoLimits;
var
  S: TFitStructure;
  M: TParamMap;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].PP[1] := [7, 10, 10, 10, 13];
  M := TParamMap.Create(S);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    Assert.AreEqual(8.0, M.Slots[0].Start, 1E-6);
    Assert.AreEqual(12.0, M.Slots[4].Start, 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_TableSlots_WriteTheirPeriod;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
  k: Integer;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([8.5, 9, 10, 11, 11.5], S, N));
    for k := 1 to 5 do
      Assert.AreEqual(Double(S.Stacks[0].Layers[0].PP[1][k - 1]),
        Double(S.Stacks[0].Layers[0].PeriodValue(1, k, 5, True)), 0.0);
    Assert.AreEqual(8.5, Double(S.Stacks[0].Layers[0].PP[1][0]), 1E-6);
    Assert.AreEqual(11.5, Double(S.Stacks[0].Layers[0].PP[1][4]), 1E-6);
    Assert.AreEqual(10.0, Double(M.Template.Stacks[0].Layers[0].PP[1][0]), 1E-6,
      'Apply writes the copy, never the template');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_TableOutsideLimits_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([10, 10, 12.5, 10, 10], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_TableNaN_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([10, NaN, 10, 10, 10], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddTable_PairedOrSinglePeriod_Raises;
var
  S: TFitStructure;
  M: TParamMap;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].P[1].Paired := True;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddTable('s0.l0.thickness', 0, 0, 1); end, EParamMap,
      'a paired parameter has one value');
  finally
    M.Free;
  end;
  S := Cell5;
  S.Stacks[0].N := 1;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddTable('s0.l0.thickness', 0, 0, 1); end, EParamMap,
      'a single period has no table');
  finally
    M.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestParamMapModes);

end.
```

Add to `TTestPosteriorModes` (declaration and body), with `unit_JointPosterior, unit_PosteriorBatch, unit_StretchSampler` added to the implementation uses:

```pascal
    [Test] procedure Table_GpuScoresAsTheCpu;
```

```pascal
{ The GPU scorer packs what FillLayeredModel builds, so a tabled model must
  score on the GPU as on the CPU. Passes with a note when no GPU ran. }
procedure TTestPosteriorModes.Table_GpuScoresAsTheCpu;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Joint: TJointPosterior;
  Batch: TPosteriorBatch;
  Data, R: TDataArray;
  Vecs, Blobs: TArray<TVector>;
  Gpu, Cpu: TArray<Double>;
  i: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Data := TWB4CFixture.Angles;
  Map := TParamMap.Create(Tabled);
  Post := nil; Joint := nil; Batch := nil;
  try
    Map.AddTable('s0.l0.thickness', 0, 0, 1);
    Map.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    Post.EvaluateOnce(Map.StartVector, R);
    for i := 0 to High(Data) do
      Data[i].r := R[i].r;
    Post.Free;
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    Joint := TJointPosterior.CreateSingle(Post, False);
    Batch := TPosteriorBatch.Create(Joint, 2, True);
    SetLength(Vecs, 3);
    for i := 0 to 2 do
    begin
      Vecs[i] := Joint.StartVector;
      Vecs[i][i] := Vecs[i][i] + 0.4;           // move one period's W thickness
    end;
    Batch.LogProb(Vecs, Gpu, Blobs);
    if not Batch.GpuUsed then
      Assert.Pass('no GPU evaluated the batch: ' + Batch.GpuError);
    Batch.LogProbOnCpu(Vecs, Cpu, Blobs);
    for i := 0 to 2 do
      Assert.AreEqual(Cpu[i], Gpu[i], 0.25, Format('ln p of vector %d', [i]));
  finally
    Batch.Free;
    Joint.Free;
    Post.Free;
    Map.Free;
  end;
end;
```

Register `TestParamMapModes in 'TestParamMapModes.pas'` in the `.dpr` and `.dproj`.

- [ ] **Step 2: Run to see it fail**

Build. Expected: compile errors, `AddTable` undeclared.

- [ ] **Step 3: Implement**

In `Shared/Bayes/unit_ParamMap.pas`:

Unit header comment, add after the first paragraph:

```pascal
   A layer value that differs from period to period is a table
   (TLayerData.PP, read by FillLayeredModel through PeriodValue). AddTable
   makes every entry a slot; AddProfile makes the coefficients of a
   polynomial in the period number the slots and writes the table from them.
```

Types:

```pascal
  TSlotKind = (skParam, skPeriod, skLogScale, skBackground, skLnF, skTable, skPoly);

  TParamSlot = record
    Name: string;
    Kind: TSlotKind;
    Stack, Layer, P: Integer;       // GUI indices; P 1 thickness, 2 sigma, 3 density
    Period: Integer;                // skTable: the period, from 1 (the surface); skPoly: the coefficient's order
    Lower, Upper, Start: Double;
    HasPrior: Boolean;
    PriorMean, PriorSD: Double;
  end;
```

Public method, after `AddPeriod`:

```pascal
    /// <summary>One slot per period for the value P of a layer of a repeating
    /// stack, named Name[1] .. Name[N], period 1 at the surface. Each starts at
    /// its table entry (the layer's own value when the table is missing or
    /// shorter than N), moved into the layer's limits.</summary>
    procedure AddTable(const Name: string; Stack, Layer, P: Integer);
```

Implementation, after `AddPeriod`:

```pascal
procedure TParamMap.AddTable(const Name: string; Stack, Layer, P: Integer);
var
  Slot: TParamSlot;
  V: TFitValue;
  T: TFloatArray;
  k, N: Integer;
begin
  V := FTemplate.Stacks[Stack].Layers[Layer].P[P];
  N := FTemplate.Stacks[Stack].N;
  if N < 2 then
    raise EParamMap.CreateFmt('"%s": a table needs a repeating stack', [Name]);
  if V.Paired then
    raise EParamMap.CreateFmt('"%s": a paired parameter has one value, not a table', [Name]);
  if V.min > V.max then
    raise EParamMap.CreateFmt('"%s": the lower bound is above the upper one', [Name]);
  SetLength(T, N);
  for k := 1 to N do
    T[k - 1] := EnsureRange(FTemplate.Stacks[Stack].Layers[Layer].PeriodValue(P, k, N, True),
      V.min, V.max);
  FTemplate.Stacks[Stack].Layers[Layer].PP[P] := T;
  for k := 1 to N do
  begin
    Slot := Default(TParamSlot);
    Slot.Name := Format('%s[%d]', [Name, k]);
    Slot.Kind := skTable;
    Slot.Stack := Stack;
    Slot.Layer := Layer;
    Slot.P := P;
    Slot.Period := k;
    Slot.Lower := V.min;
    Slot.Upper := V.max;
    Slot.Start := T[k - 1];
    AddSlot(Slot);
  end;
end;
```

In `Apply`, add to the `case`:

```pascal
      skTable:
        S.Stacks[FSlots[i].Stack].Layers[FSlots[i].Layer].PP[FSlots[i].P][FSlots[i].Period - 1] := Theta[i];
      skPoly:
        ;   // read by the profile pass below (Task 5)
```

`Apply` relies on S being a copy of the template (`Template.CopyContent`), which every caller already makes: that is where the full-length table comes from.

- [ ] **Step 4: Run the fixtures**

Run `--run:TestParamMapModes.TTestParamMapModes` (7 passed) and `--run:TestPosteriorModes.TTestPosteriorModes` (4 passed, or the GPU one passing with its note).

- [ ] **Step 5: Commit**

```bash
git add Shared/Bayes/unit_ParamMap.pas XRayCalc3/Tests
git commit -m "+ TParamMap.AddTable: one slot per period of a tabled layer value"
```

---

### Task 5: Profile slots

**Files:**
- Modify: `Shared/Bayes/unit_ParamMap.pas`
- Modify: `XRayCalc3/Tests/TestParamMapModes.pas`, `XRayCalc3/Tests/TestPosteriorModes.pas`

**Interfaces:**
- Consumes: Task 4's slot kinds and `Period` field.
- Produces: `procedure TParamMap.AddProfile(const Name: string; Stack, Layer, P: Integer; const C: array of Double)` adding slots `Name.c0` .. `Name.c<order>`; the value in period k is `sum C[i] * (k - 1)^i`, as `math_globals.Poly`. `ReportedNames` gains `Name[1]` .. `Name[N]` for each profile, after the derived layers.

- [ ] **Step 1: Write the failing tests**

Add to `TTestParamMapModes`:

```pascal
    [Test] procedure AddProfile_SlotsAndBounds;
    [Test] procedure Apply_Profile_FillsEveryPeriod;
    [Test] procedure Apply_ProfileLeavesLimits_Infeasible;
    [Test] procedure Apply_ProfileStartOutsideLimits_Infeasible;
    [Test] procedure Apply_ProfileNaN_Infeasible;
    [Test] procedure AddProfile_BadInput_Raises;
    [Test] procedure Reported_ProfilePeriods;
    [Test] procedure SetDerived_AfterAProfile_KeepsItsSlots;
```

```pascal
procedure TTestParamMapModes.AddProfile_SlotsAndBounds;
var
  M: TParamMap;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    Assert.AreEqual(2, M.Count);
    Assert.AreEqual('s0.l0.thickness.c0', M.Slots[0].Name);
    Assert.AreEqual('s0.l0.thickness.c1', M.Slots[1].Name);
    Assert.AreEqual(8.0, M.Slots[0].Lower, 1E-6);
    Assert.AreEqual(12.0, M.Slots[0].Upper, 1E-6);
    Assert.AreEqual(10.0, M.Slots[0].Start, 1E-6);
    Assert.AreEqual(0.25, M.Slots[1].Start, 1E-6);
    { the gradient may take the whole range across the N - 1 = 4 steps, twice over }
    Assert.AreEqual(-2.0, M.Slots[1].Lower, 1E-6);
    Assert.AreEqual(2.0, M.Slots[1].Upper, 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_Profile_FillsEveryPeriod;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
  k: Integer;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([9, 0.5], S, N));
    for k := 1 to 5 do
      Assert.AreEqual(9 + 0.5 * (k - 1), Double(S.Stacks[0].Layers[0].PeriodValue(1, k, 5, True)), 1E-5);
    Assert.AreEqual(9.0, Double(S.Stacks[0].Layers[0].P[1].V), 1E-6, 'the layer''s own value is c0');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_ProfileLeavesLimits_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([11, 0.5], S, N), 'period 5 would be 13 A, above 12');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_ProfileStartOutsideLimits_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [11, 0.5]);    // a fit that ended outside
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply(M.StartVector, S, N), 'not clamped: the caller must hear of it');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Apply_ProfileNaN_Infeasible;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    M.Template.CopyContent(S);
    Assert.IsFalse(M.Apply([10, NaN], S, N));
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.AddProfile_BadInput_Raises;
var
  S: TFitStructure;
  M: TParamMap;
begin
  M := TParamMap.Create(Cell5);
  try
    Assert.WillRaise(procedure begin M.AddProfile('s0.l0.thickness', 0, 0, 1, [10]); end,
      EParamMap, 'a profile needs a gradient');
    Assert.WillRaise(procedure begin M.AddProfile('s0.l1.thickness', 0, 1, 1, [20, 0]); end,
      EParamMap, 'a held value is not sampled');
  finally
    M.Free;
  end;
  S := Cell5;
  S.Stacks[0].Layers[0].P[1].Paired := True;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0]); end,
      EParamMap, 'a paired parameter has one value');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Reported_ProfilePeriods;
var
  M: TParamMap;
  Names: TArray<string>;
  Values: TArray<Double>;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddProfile('s0.l0.thickness', 0, 0, 1, [10, 0.25]);
    Names := M.ReportedNames;
    Assert.AreEqual(7, Length(Names), 'two coefficients and five periods');
    Assert.AreEqual('s0.l0.thickness[1]', Names[2]);
    Assert.AreEqual('s0.l0.thickness[5]', Names[6]);
    Assert.IsTrue(M.ReportedValues([9, 0.5], Values));
    Assert.AreEqual(9.0, Values[2], 1E-5);
    Assert.AreEqual(11.0, Values[6], 1E-5);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.SetDerived_AfterAProfile_KeepsItsSlots;
var
  S, A: TFitStructure;
  M: TParamMap;
  N: TNuisance;
begin
  S := Cell5;
  S.Stacks[0].Layers[0].P[2].min := 1;                         // Cell5 holds sigma; a profile needs a range
  S.Stacks[0].Layers[0].P[2].max := 5;
  S.Stacks[0].Layers[1].P[1].min := 15;
  S.Stacks[0].Layers[1].P[1].max := 25;
  M := TParamMap.Create(S);
  try
    M.AddParam('s0.l1.thickness', 0, 1, 1);                    // slot 0, removed below
    M.AddProfile('s0.l0.sigma', 0, 0, 2, [3, 0]);              // slots 1, 2 -> 0, 1
    M.SetDerived('s0.l1.thickness', 0, 1);
    Assert.AreEqual(2, M.Count);
    M.Template.CopyContent(A);
    Assert.IsTrue(M.Apply(M.StartVector, A, N), 'the profile still reads its own two slots');
  finally
    M.Free;
  end;
end;
```

Add to `TTestPosteriorModes`:

```pascal
    [Test] procedure Profile_CurveEqualsItsTable;
```

```pascal
procedure TTestPosteriorModes.Profile_CurveEqualsItsTable;
var
  Map: TParamMap;
  Post: TLogPosterior;
  Data, R: TDataArray;
  S: TFitStructure;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  S := Tabled;
  S.Stacks[0].Layers[0].PP[1] := nil;
  Data := TWB4CFixture.Angles;
  Map := TParamMap.Create(S);
  try
    Map.AddProfile('s0.l0.thickness', 0, 0, 1, [9, 1]);       // 9, 10, 11: Tabled's table
    Map.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Assert.IsTrue(Post.EvaluateOnce(Map.StartVector, R).Feasible);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
  AssertSameCurve(CurveOf(Tabled), R, 'a profile is the table of its values');
end;
```

- [ ] **Step 2: Run to see it fail**

Build. Expected: compile errors, `AddProfile` undeclared.

- [ ] **Step 3: Implement**

In `Shared/Bayes/unit_ParamMap.pas`:

Type, after `TDerivedLayer`:

```pascal
  /// <summary>A polynomial profile: slots First .. First + Count - 1 are its
  /// coefficients c0 .. c(Count-1); period k of N takes sum c_i (k - 1)^i,
  /// which must stay inside Lower .. Upper in every period.</summary>
  TPolyGroup = record
    Name: string;
    Stack, Layer, P: Integer;
    First, Count, N: Integer;
    Lower, Upper: Double;
  end;
```

Private field `FPoly: TArray<TPolyGroup>;` (before the methods), and a private function:

```pascal
    function PolyValue(const G: TPolyGroup; const Theta: array of Double; Period: Integer): Double;
```

Public method, after `AddTable`:

```pascal
    /// <summary>The value P of a layer of a repeating stack as a polynomial in
    /// the period number: slots Name.c0 .. Name.c<order>, starting at C. c0
    /// keeps the layer's limits; a higher order may move the value across
    /// twice its range over the stack. The resulting values are reported as
    /// Name[1] .. Name[N].</summary>
    procedure AddProfile(const Name: string; Stack, Layer, P: Integer; const C: array of Double);
```

Implementation:

```pascal
function TParamMap.PolyValue(const G: TPolyGroup; const Theta: array of Double; Period: Integer): Double;
var
  j: Integer;
  Pw: Double;
begin
  { math_globals.Poly's polynomial, here in Double and without that unit's
    VCL baggage: sum c_j (Period - 1)^j. }
  Result := 0;
  Pw := 1;
  for j := 0 to G.Count - 1 do
  begin
    Result := Result + Theta[G.First + j] * Pw;
    Pw := Pw * (Period - 1);
  end;
end;

procedure TParamMap.AddProfile(const Name: string; Stack, Layer, P: Integer; const C: array of Double);
var
  Slot: TParamSlot;
  V: TFitValue;
  G: TPolyGroup;
  j, N: Integer;
  W: Double;
begin
  V := FTemplate.Stacks[Stack].Layers[Layer].P[P];
  N := FTemplate.Stacks[Stack].N;
  if N < 2 then
    raise EParamMap.CreateFmt('"%s": a profile needs a repeating stack', [Name]);
  if V.Paired then
    raise EParamMap.CreateFmt('"%s": a paired parameter has one value, not a profile', [Name]);
  if not (V.min < V.max) then
    raise EParamMap.CreateFmt('"%s": a held value is not sampled', [Name]);
  if Length(C) < 2 then
    raise EParamMap.CreateFmt('"%s": a profile needs at least a gradient', [Name]);

  G := Default(TPolyGroup);
  G.Name := Name;
  G.Stack := Stack;
  G.Layer := Layer;
  G.P := P;
  G.First := Length(FSlots);
  G.Count := Length(C);
  G.N := N;
  G.Lower := V.min;
  G.Upper := V.max;

  for j := 0 to High(C) do
  begin
    Slot := Default(TParamSlot);
    Slot.Name := Format('%s.c%d', [Name, j]);
    Slot.Kind := skPoly;
    Slot.Stack := Stack;
    Slot.Layer := Layer;
    Slot.P := P;
    Slot.Period := j;
    Slot.Start := C[j];
    if j = 0 then
    begin
      Slot.Lower := V.min;
      Slot.Upper := V.max;
    end
    else
    begin
      W := Max(2 * (V.max - V.min) / Power(N - 1, j), 2 * Abs(C[j]));
      Slot.Lower := -W;
      Slot.Upper := W;
    end;
    AddSlot(Slot);
  end;
  SetLength(FTemplate.Stacks[Stack].Layers[Layer].PP[P], N);
  FPoly := FPoly + [G];
end;
```

In `SetDerived`, inside the loop that deletes the derived thickness's slot, keep the groups pointing at their own slots:

```pascal
  for i := High(FSlots) downto 0 do
    if (FSlots[i].Kind = skParam) and (FSlots[i].Stack = Stack) and
       (FSlots[i].Layer = Layer) and (FSlots[i].P = 1) then
    begin
      Delete(FSlots, i, 1);
      for j := 0 to High(FPoly) do
        if FPoly[j].First > i then
          Dec(FPoly[j].First);
    end;
```

(declare `j: Integer` there).

In `Apply`, after the slot loop and before the derived-layer loop (declare `g: Integer`):

```pascal
  for g := 0 to High(FPoly) do
  begin
    for k := 1 to FPoly[g].N do
    begin
      H := PolyValue(FPoly[g], Theta, k);
      { Positive form: NaN is outside. }
      if not ((H >= FPoly[g].Lower) and (H <= FPoly[g].Upper)) then
        Exit;
      S.Stacks[FPoly[g].Stack].Layers[FPoly[g].Layer].PP[FPoly[g].P][k - 1] := H;
    end;
    S.Stacks[FPoly[g].Stack].Layers[FPoly[g].Layer].P[FPoly[g].P].V := Theta[FPoly[g].First];
  end;
```

`ReportedNames`, after the derived names:

```pascal
  for i := 0 to High(FPoly) do
    for k := 1 to FPoly[i].N do
      Result := Result + [Format('%s[%d]', [FPoly[i].Name, k])];
```

(declare `k: Integer`).

`ReportedValues`: grow `Values` by the sum of `FPoly[i].N` and, after the derived values, append `S.Stacks[..].Layers[..].PP[P][k - 1]` for every group and period in the same order. Replace the `SetLength` and the tail of the function with:

```pascal
  n := Length(FSlots) + Ord((IdxScale >= 0) and (IdxF >= 0)) * 2 + Length(FDerived);
  for i := 0 to High(FPoly) do
    Inc(n, FPoly[i].N);
  SetLength(Values, n);
  for i := 0 to High(FSlots) do
    Values[i] := Theta[i];
  n := Length(FSlots);
  if (IdxScale >= 0) and (IdxF >= 0) then
  begin
    Values[n] := Power(10, Theta[IdxScale]);
    Values[n + 1] := Exp(Theta[IdxF]);
    Inc(n, 2);
  end;
  for i := 0 to High(FDerived) do
  begin
    Values[n] := S.Stacks[FDerived[i].Stack].Layers[FDerived[i].Layer].P[1].V;
    Inc(n);
  end;
  for i := 0 to High(FPoly) do
    for k := 1 to FPoly[i].N do
    begin
      Values[n] := S.Stacks[FPoly[i].Stack].Layers[FPoly[i].Layer].PP[FPoly[i].P][k - 1];
      Inc(n);
    end;
  Result := True;
```

(declare `k: Integer`).

- [ ] **Step 4: Run the fixtures, then the whole suite**

Expected: `TTestParamMapModes` 15 passed, `TTestPosteriorModes` 5 passed, whole suite 0 failed (the restored `TestParamMap` and `TestJointPosterior` pin that the periodic names and values did not move).

- [ ] **Step 5: Commit**

```bash
git add Shared/Bayes/unit_ParamMap.pas XRayCalc3/Tests
git commit -m "+ TParamMap.AddProfile: a layer value as a polynomial in the period number"
```

---

### Task 6: Summary numbers and their priors

**Files:**
- Modify: `Shared/Bayes/unit_ParamMap.pas`
- Modify: `XRayCalc3/Tests/TestParamMapModes.pas`

**Interfaces:**
- Consumes: Tasks 4 and 5.
- Produces: `procedure TParamMap.AddSummary(const Prefix: string; Stack: Integer)` adding the reported names `Prefix.period_mean`, `Prefix.total`, `Prefix.drift` (last in `ReportedNames`); `SetPrior` accepts those names. Definitions, with D_k the sum of the stack's layer thicknesses in period k (period 1 at the surface): mean = sum D_k / N, total = sum D_k, drift = D_N - D_1.

The spec names `unit_Expression` for these; they are computed in the map instead, so that a prior on one is part of `PriorTerm` on both the CPU and the GPU path, and every recorded sample carries them without a second evaluator. `unit_Expression` stays for `TSampleRun`'s derived quantities.

- [ ] **Step 1: Write the failing tests**

Add to `TTestParamMapModes`:

```pascal
    [Test] procedure Summary_PeriodicCell;
    [Test] procedure Summary_FollowsATable;
    [Test] procedure Summary_Prior_AddsToThePriorTerm;
    [Test] procedure Summary_SinglePeriodStack_Raises;
```

```pascal
procedure TTestParamMapModes.Summary_PeriodicCell;
var
  M: TParamMap;
  Names: TArray<string>;
  Values: TArray<Double>;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddParam('s0.l0.thickness', 0, 0, 1);
    M.AddSummary('s0', 0);
    Names := M.ReportedNames;
    Assert.AreEqual(4, Length(Names));
    Assert.AreEqual('s0.period_mean', Names[1]);
    Assert.AreEqual('s0.total', Names[2]);
    Assert.AreEqual('s0.drift', Names[3]);
    Assert.IsTrue(M.ReportedValues([11], Values));
    Assert.AreEqual(31.0, Values[1], 1E-5);
    Assert.AreEqual(155.0, Values[2], 1E-4);
    Assert.AreEqual(0.0, Values[3], 1E-6);
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_FollowsATable;
var
  M: TParamMap;
  Values: TArray<Double>;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.AddSummary('s0', 0);
    Assert.IsTrue(M.ReportedValues([9, 9.5, 10, 10.5, 11], Values));
    Assert.AreEqual(30.0, Values[5], 1E-5, 'mean period');
    Assert.AreEqual(150.0, Values[6], 1E-4, 'total');
    Assert.AreEqual(2.0, Values[7], 1E-5, 'last period minus the first');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_Prior_AddsToThePriorTerm;
var
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  M := TParamMap.Create(Cell5);
  try
    M.AddTable('s0.l0.thickness', 0, 0, 1);
    M.AddSummary('s0', 0);
    M.SetPrior('s0.total', 152, 2);
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply([9, 9.5, 10, 10.5, 11], S, N));
    Assert.AreEqual(1.0, M.PriorTerm([9, 9.5, 10, 10.5, 11], S), 1E-6, '((150 - 152) / 2)^2');
  finally
    M.Free;
  end;
end;

procedure TTestParamMapModes.Summary_SinglePeriodStack_Raises;
var
  S: TFitStructure;
  M: TParamMap;
begin
  S := Cell5;
  S.Stacks[0].N := 1;
  M := TParamMap.Create(S);
  try
    Assert.WillRaise(procedure begin M.AddSummary('s0', 0); end, EParamMap);
  finally
    M.Free;
  end;
end;
```

- [ ] **Step 2: Run to see it fail**

Build. Expected: compile errors, `AddSummary` undeclared.

- [ ] **Step 3: Implement**

In `Shared/Bayes/unit_ParamMap.pas`:

Types, after `TPolyGroup`:

```pascal
  TSummaryKind = (smPeriodMean, smTotal, smDrift);

  /// <summary>A number of a whole repeating stack, reported with every
  /// sample: the mean period, the total thickness, or the last period's
  /// thickness minus the first's (period 1 is at the surface).</summary>
  TStackSummary = record
    Name: string;
    Stack: Integer;
    Kind: TSummaryKind;
    HasPrior: Boolean;
    PriorMean, PriorSD: Double;
  end;
```

Private field `FSummaries: TArray<TStackSummary>;` and private function:

```pascal
    function SummaryValue(const S: TFitStructure; const Sm: TStackSummary): Double;
```

Public:

```pascal
    /// <summary>Reports Prefix.period_mean, Prefix.total and Prefix.drift of a
    /// repeating stack, last in ReportedNames. SetPrior takes those names.</summary>
    procedure AddSummary(const Prefix: string; Stack: Integer);
```

Implementation:

```pascal
function PeriodThickness(const S: TFitStructure; Stack, Period: Integer): Double;
var
  k: Integer;
begin
  Result := 0;
  for k := 0 to High(S.Stacks[Stack].Layers) do
    Result := Result + S.Stacks[Stack].Layers[k].PeriodValue(1, Period, S.Stacks[Stack].N, True);
end;

function TParamMap.SummaryValue(const S: TFitStructure; const Sm: TStackSummary): Double;
var
  k, N: Integer;
begin
  N := S.Stacks[Sm.Stack].N;
  if Sm.Kind = smDrift then
    Exit(PeriodThickness(S, Sm.Stack, N) - PeriodThickness(S, Sm.Stack, 1));
  Result := 0;
  for k := 1 to N do
    Result := Result + PeriodThickness(S, Sm.Stack, k);
  if Sm.Kind = smPeriodMean then
    Result := Result / N;
end;

procedure TParamMap.AddSummary(const Prefix: string; Stack: Integer);
const
  Suffix: array [TSummaryKind] of string = ('.period_mean', '.total', '.drift');
var
  Sm: TStackSummary;
  K: TSummaryKind;
begin
  if FTemplate.Stacks[Stack].N < 2 then
    raise EParamMap.CreateFmt('"%s": a summary needs a repeating stack', [Prefix]);
  for K := Low(TSummaryKind) to High(TSummaryKind) do
  begin
    Sm := Default(TStackSummary);
    Sm.Name := Prefix + Suffix[K];
    Sm.Stack := Stack;
    Sm.Kind := K;
    FSummaries := FSummaries + [Sm];
  end;
end;
```

`SetPrior`: before the final `raise`, add

```pascal
  for i := 0 to High(FSummaries) do
    if SameText(FSummaries[i].Name, Name) then
    begin
      FSummaries[i].HasPrior := True;
      FSummaries[i].PriorMean := Mean;
      FSummaries[i].PriorSD := SD;
      Exit;
    end;
```

and reword the final message to `'"%s" is not a free layer parameter or a summary of this fit'`. The restored `TestParamMap.SetPrior_UnknownName_Raises` checks the exception class only; if it checks the text, update that expectation to the new wording.

`PriorTerm`: append

```pascal
  for i := 0 to High(FSummaries) do
    if FSummaries[i].HasPrior then
      Result := Result + Sqr((SummaryValue(S, FSummaries[i]) - FSummaries[i].PriorMean) /
        FSummaries[i].PriorSD);
```

`ReportedNames`: append `FSummaries[i].Name` for every summary, last.

`ReportedValues`: add `Length(FSummaries)` to the size and, after the profile values, `Values[n] := SummaryValue(S, FSummaries[i]); Inc(n);` for every summary.

- [ ] **Step 4: Run the fixture, then the whole suite**

Expected: `TTestParamMapModes` 19 passed; whole suite 0 failed.

- [ ] **Step 5: Commit**

```bash
git add Shared/Bayes/unit_ParamMap.pas XRayCalc3/Tests
git commit -m "+ TParamMap.AddSummary: mean period, total thickness and drift of a stack, with priors"
```

---

### Task 7: The truth gate

**Files:**
- Create: `XRayCalc3/Tests/TestTruthGate.pas`
- Modify: `XRayCalc3/Tests/XRayCalc3Tests.dpr`, `.dproj`
- Modify: this plan (the Outcome section at the end)

**Interfaces:**
- Consumes: everything above; the classic engines `TLFPSO_Periodic`, `TLFPSO_Poly`, `TLFPSO_Irregular` (`Params`, `Limit`, `ExpValues`, `Seed`, `Structure`, `Run(CalcParams)`, `Polynomes`).
- Produces: `XRayCalc3/Tests/_Out/BIN/TruthGate.txt`, the numbers plan B's defaults and the large-table threshold are set from.

The fixture is opt-in: it passes with a note unless the environment variable `XRC_TRUTH_GATE` is `1`, so the ordinary suite stays fast.

Each case: a truth structure gives a curve; counting noise at I0 = 1E7 gives the data and counts; a classic fit starts from a design that is not the truth; the map is built from the fit's answer; the sampler starts in a ball around it (`'fit'`); the truth is checked against the 16-84 % and 2.5-97.5 % ranges. Six seeds per case, each with its own noise.

- [ ] **Step 1: Write the fixture**

Create `XRayCalc3/Tests/TestTruthGate.pas` with the MIT header and:

```pascal
unit TestTruthGate;

(* The truth gate of the uncertainty core (plan A, task 7). Classic fit, then
   the sampler, on calculated curves with known truth and counting noise, for
   a periodic structure, a profile and a table. Opt-in: set XRC_TRUTH_GATE=1.
   Every run appends its numbers to TruthGate.txt next to the test runner. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestTruthGate = class
  public
    [Test] procedure Periodic_TruthInsideRange;
    [Test] procedure Profile_TruthInsideRange;
    [Test] procedure Table_TruthInsideRange;
    [Test] procedure LargeTable_Report;
  end;

implementation

uses
  System.SysUtils, System.Math, System.IOUtils, System.Diagnostics,
  unit_Types, unit_Xoshiro, unit_Likelihood, unit_ParamMap, unit_LogPosterior,
  unit_JointPosterior, unit_SampleRun, unit_LFPSO_Base, unit_LFPSO_Periodic,
  unit_LFPSO_Poly, unit_LFPSO_Irregular, TestLogPosterior, TestPosteriorModes;

const
  I0     = 1E7;
  SEEDS  = 6;
  STEPS  = 3000;
  BURN   = 1000;
  THIN   = 10;
  FREE_L = 2;                 // the W-on-B4C interlayer of TWB4CFixture's cell

type
  TMode = (gmPeriodic, gmProfile, gmTable);

  TTally = record
    Trials, In68, In95: Integer;
    procedure Add(const R: TSampleResult; const Name: string; Truth: Double; var Log: string);
    function F68: Double;
    function F95: Double;
  end;

function Enabled: Boolean;
begin
  Result := GetEnvironmentVariable('XRC_TRUTH_GATE') = '1';
end;

procedure Report(const Line: string);
begin
  TFile.AppendAllText(TPath.Combine(ExtractFilePath(ParamStr(0)), 'TruthGate.txt'),
    Line + sLineBreak);
end;

procedure TTally.Add(const R: TSampleResult; const Name: string; Truth: Double; var Log: string);
var
  k: Integer;
begin
  for k := 0 to High(R.Params) do
    if SameText(R.Params[k].Name, Name) then
    begin
      Inc(Trials);
      if (Truth >= R.Params[k].Summary.P16) and (Truth <= R.Params[k].Summary.P84) then
        Inc(In68);
      if (Truth >= R.Params[k].Summary.P2_5) and (Truth <= R.Params[k].Summary.P97_5) then
        Inc(In95);
      Log := Log + Format('  %s truth %.5g  p16 %.5g  p50 %.5g  p84 %.5g' + sLineBreak,
        [Name, Truth, R.Params[k].Summary.P16, R.Params[k].Summary.P50, R.Params[k].Summary.P84]);
      Exit;
    end;
  Assert.Fail('no reported value named ' + Name);
end;

function TTally.F68: Double;
begin
  Result := In68 / Max(1, Trials);
end;

function TTally.F95: Double;
begin
  Result := In95 / Max(1, Trials);
end;

{ TWB4CFixture's cell with N periods; every value paired (one value for the
  whole stack) and held, except the interlayer thickness, free in [3, 9]. }
function Cell(N: Integer; H2: Single): TFitStructure;
var
  j, p: Integer;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := N;
  SetLength(Result.Stacks[0].Layers, 4);
  Result.Stacks[0].Layers[0] := Lay('W', 3, 3, 3, 2, 11, 0);
  Result.Stacks[0].Layers[1] := Lay('W', 10, 10, 10, 2, 19.3, 1);
  Result.Stacks[0].Layers[2] := Lay('W', H2, 3, 9, 2, 11, 2);
  Result.Stacks[0].Layers[3] := Lay('B4C', 15, 15, 15, 2, 2.52, 3);
  for j := 0 to 3 do
    for p := 1 to 3 do
      Result.Stacks[0].Layers[j].P[p].Paired := not ((j = FREE_L) and (p = 1));
  Result.Subs := Lay('Si', 0, 0, 0, 3, 2.33, 0);
end;

{ The truth's interlayer thickness in period k (from 1, at the surface). }
function TruthH(Mode: TMode; k: Integer): Double;
begin
  case Mode of
    gmProfile: Result := 5.5 + 0.05 * (k - 1);
    gmTable:   Result := 6 + 0.4 * Sin(1.3 * k);
  else
    Result := 6;
  end;
end;

function TruthStructure(Mode: TMode; N: Integer): TFitStructure;
var
  k: Integer;
begin
  Result := Cell(N, 6);
  if Mode = gmPeriodic then
    Exit;
  SetLength(Result.Stacks[0].Layers[FREE_L].PP[1], N);
  for k := 1 to N do
    Result.Stacks[0].Layers[FREE_L].PP[1][k - 1] := TruthH(Mode, k);
end;

procedure Noisy(const R: TDataArray; Seed: UInt64; out Data: TDataArray; out Counts: TArray<Double>);
var
  Rng: TXoshiro256;
  i: Integer;
  Lam: Double;
begin
  Rng.Seed(Seed);
  Data := Copy(R);
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Lam := I0 * R[i].r;
    Counts[i] := Max(0, Round(Lam + Sqrt(Lam) * Rng.NextGaussian));
    Data[i].r := Max(Counts[i], 1) / I0;
  end;
end;

function ClassicParams(Order: Integer): TFitParams;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.NMax       := 300;
  Result.Pop        := 60;
  Result.Tolerance  := 0;
  Result.Vmax       := 0.3;
  Result.JammingMax := 100;
  Result.ReInitMax  := 3;
  Result.KChiSqr    := 1.5;
  Result.KVmax      := 1.2;
  Result.w1         := 0.4;
  Result.w2         := 0.5;
  Result.Ksxr       := 0.1;
  Result.MaxPOrder  := Order;
  Result.PolyFactor := 10;
end;

{ The classic fit from the design (interlayer 4.5 A everywhere), and the
  structure and profile coefficients the map is then built from. }
procedure ClassicFit(Mode: TMode; N: Integer; const Data: TDataArray;
  const CP: TCalcThreadParams; Seed: Integer; out Fitted: TFitStructure; out C: TArray<Double>);
var
  Engine: TLFPSO_BASE;
  Flat: TFitStructure;
  Polys: TProfileFunctions;
  i, k: Integer;
begin
  C := nil;
  Fitted := Cell(N, 4.5);
  case Mode of
    gmProfile: Engine := TLFPSO_Poly.Create;
    gmTable:   Engine := TLFPSO_Irregular.Create;
  else
    Engine := TLFPSO_Periodic.Create;
  end;
  try
    Engine.Params := ClassicParams(Ord(Mode = gmProfile));
    Engine.Limit := 1E-9;
    Engine.ExpValues := Data;
    Engine.Seed := Seed;
    Engine.Structure := Fitted;
    Engine.Run(CP);
    case Mode of
      gmPeriodic:
        Fitted.Stacks[0].Layers[FREE_L].P[1].V := Engine.Structure.Stacks[0].Layers[FREE_L].P[1].V;
      gmProfile:
        begin
          Polys := Engine.Polynomes;
          for i := 0 to High(Polys) do
            if (Polys[i].LayerID = FREE_L) and (Polys[i].Subj = ptH) then
            begin
              SetLength(C, Length(Polys[i].C));
              for k := 0 to High(C) do
                C[k] := Polys[i].C[k];
            end;
          Assert.IsTrue(Length(C) >= 2, 'the classic profile fit reports a gradient');
          Fitted.Stacks[0].Layers[FREE_L].P[1].V := C[0];
        end;
      gmTable:
        begin
          { The irregular engine's structure is one stack of N x 4 layers,
            period 1 first, the layers of each period in turn. }
          Flat := Engine.Structure;
          SetLength(Fitted.Stacks[0].Layers[FREE_L].PP[1], N);
          for k := 1 to N do
            Fitted.Stacks[0].Layers[FREE_L].PP[1][k - 1] :=
              Flat.Stacks[0].Layers[(k - 1) * 4 + FREE_L].P[1].V;
        end;
    end;
  finally
    Engine.Free;
  end;
end;

function BuildMap(Mode: TMode; const Fitted: TFitStructure; const C: TArray<Double>): TParamMap;
begin
  Result := TParamMap.Create(Fitted);
  case Mode of
    gmPeriodic: Result.AddParam('s0.l2.thickness', 0, FREE_L, 1);
    gmProfile:  Result.AddProfile('s0.l2.thickness', 0, FREE_L, 1, C);
    gmTable:    Result.AddTable('s0.l2.thickness', 0, FREE_L, 1);
  end;
  Result.AddSummary('s0', 0);
  Result.AddNuisance(Log10(1.2), 0, 1E-6, 0.001, 1);
end;

{ One seed of one case: noise, classic fit, sampler; the truth tallied. }
procedure RunCase(Mode: TMode; N: Integer; Seed: Integer; var Params, Sums: TTally;
  const Title: string);
var
  Truth, Fitted: TFitStructure;
  Clean, Data: TDataArray;
  Counts: TArray<Double>;
  C: TArray<Double>;
  CP: TCalcThreadParams;
  Map: TParamMap;
  Post: TLogPosterior;
  Joint: TJointPosterior;
  Run: TSampleRun;
  R: TSampleResult;
  Walkers, st, k: Integer;
  SumD, D1, DN: Double;
  Log: string;
  Watch: TStopwatch;
begin
  Watch := TStopwatch.StartNew;
  Truth := TruthStructure(Mode, N);
  Clean := CurveOf(Truth);
  Noisy(Clean, UInt64(1000 + Seed), Data, Counts);
  CP := TWB4CFixture.CalcParams(Data, 0);
  ClassicFit(Mode, N, Data, CP, Seed, Fitted, C);

  Map := BuildMap(Mode, Fitted, C);
  Post := nil; Joint := nil; Run := nil;
  try
    Post := TLogPosterior.Create(Map, Data, Counts, CP, 1E-9, 10);
    Joint := TJointPosterior.CreateSingle(Post, False);
    Walkers := Max(32, 2 * Joint.Count + 2);
    Run := TSampleRun.Create(Joint, Walkers, CPUCount, False, nil);
    Run.Start('fit', Joint.StartVector, UInt64(Seed));
    for st := 1 to STEPS do
      Run.Advance(BURN, THIN);
    R := Run.Finish([Data], 50, UInt64(Seed));

    Log := Format('%s seed %d: %d slots, %d walkers, acceptance %.3f, slowest tau %s, %d doubtful, %.0f s' +
      sLineBreak, [Title, Seed, Joint.Count, Walkers, R.AcceptanceMean,
      R.Params[R.TauSlowest].Name, Length(R.TauDoubtful), Watch.Elapsed.TotalSeconds]);
    case Mode of
      gmPeriodic:
        Params.Add(R, 's0.l2.thickness', 6, Log);
      gmProfile:
        begin
          Params.Add(R, 's0.l2.thickness.c0', 5.5, Log);
          Params.Add(R, 's0.l2.thickness.c1', 0.05, Log);
        end;
      gmTable:
        for k := 1 to N do
          Params.Add(R, Format('s0.l2.thickness[%d]', [k]), TruthH(Mode, k), Log);
    end;
    SumD := 0;
    for k := 1 to N do
      SumD := SumD + 28 + TruthH(Mode, k);
    D1 := 28 + TruthH(Mode, 1);
    DN := 28 + TruthH(Mode, N);
    Sums.Add(R, 's0.period_mean', SumD / N, Log);
    Sums.Add(R, 's0.total', SumD, Log);
    if Mode <> gmPeriodic then
      Sums.Add(R, 's0.drift', DN - D1, Log);
    Report(Log);
  finally
    Run.Free;
    Joint.Free;
    Post.Free;
    Map.Free;
  end;
end;

procedure RunMode(Mode: TMode; N: Integer; const Title: string; MustHold: Boolean);
var
  Params, Sums: TTally;
  Seed: Integer;
begin
  Params := Default(TTally);
  Sums := Default(TTally);
  for Seed := 1 to SEEDS do
    RunCase(Mode, N, Seed, Params, Sums, Title);
  Report(Format('%s: parameters %d/%d in 16-84, %d/%d in 2.5-97.5; summaries %d/%d and %d/%d' + sLineBreak,
    [Title, Params.In68, Params.Trials, Params.In95, Params.Trials,
     Sums.In68, Sums.Trials, Sums.In95, Sums.Trials]));
  if not MustHold then
    Exit;
  { 68 % and 95 % are the expected rates; the bounds allow for the few trials. }
  Assert.IsTrue((Params.F68 >= 0.35) and (Params.F68 <= 0.95),
    Format('%s parameters: %.2f of the truths inside 16-84 %%', [Title, Params.F68]));
  Assert.IsTrue(Params.F95 >= 0.75,
    Format('%s parameters: %.2f of the truths inside 2.5-97.5 %%', [Title, Params.F95]));
  Assert.IsTrue((Sums.F68 >= 0.35) and (Sums.F68 <= 0.95),
    Format('%s summaries: %.2f of the truths inside 16-84 %%', [Title, Sums.F68]));
  Assert.IsTrue(Sums.F95 >= 0.75,
    Format('%s summaries: %.2f of the truths inside 2.5-97.5 %%', [Title, Sums.F95]));
end;

procedure Guard;
begin
  if not Enabled then
    Assert.Pass('set XRC_TRUTH_GATE=1 to run the truth gate');
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
end;

procedure TTestTruthGate.Periodic_TruthInsideRange;
begin
  Guard;
  RunMode(gmPeriodic, 20, 'periodic', True);
end;

procedure TTestTruthGate.Profile_TruthInsideRange;
begin
  Guard;
  RunMode(gmProfile, 20, 'profile', True);
end;

procedure TTestTruthGate.Table_TruthInsideRange;
begin
  Guard;
  RunMode(gmTable, 10, 'table (10 entries)', True);
end;

procedure TTestTruthGate.LargeTable_Report;
begin
  Guard;
  { No assertion: the numbers decide where the tool's "indicative" warning starts. }
  RunMode(gmTable, 40, 'table (40 entries)', False);
  RunMode(gmTable, 80, 'table (80 entries)', False);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestTruthGate);

end.
```

Register `unit_LFPSO_Periodic` and `unit_LFPSO_Irregular` in the `.dpr`/`.dproj` only if they are not already there (`unit_LFPSO_Poly` is), then `TestTruthGate in 'TestTruthGate.pas'`.

`Assert.Pass` raises, so `Guard` leaves the test at once when the gate is off.

- [ ] **Step 2: Build, and check the ordinary suite is unaffected**

Run the whole suite without the variable.
Expected: 0 failed; the four gate tests pass with their note in well under a second.

- [ ] **Step 3: Run the gate**

```powershell
$env:XRC_TRUTH_GATE = '1'; $env:PATH = "C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;$env:PATH"; & XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --run:TestTruthGate.TTestTruthGate --exitbehavior:Continue 2>&1 | Select-Object -Last 30; Get-Content XRayCalc3\Tests\_Out\BIN\TruthGate.txt
```

Run it in the background: it is long (three modes, six seeds, plus the two large tables). Delete `TruthGate.txt` before a rerun, as the fixture appends.

If a classic fit itself fails here (an engine raises, or reports no gradient), that is a fault of the gate's setup, not of the core: fix the setup (the engine's parameters, the pairing flags) and rerun. Do not loosen the coverage bounds to make a case pass.

- [ ] **Step 4: Record the outcome and stop**

Fill in the Outcome section below from `TruthGate.txt` and the runner's summary: per case the coverage counts, the acceptance, the doubtful-tau count and the time per seed; then one line each for the two questions the gate answers:

- Is burn-in from the classic fit enough for all three modes? (Yes when the three `*_TruthInsideRange` tests pass.)
- At what number of table entries do the ranges stop being trustworthy? (From the 10, 40 and 80 entry lines.)

Commit, then stop and report to the author. Plan B is written only after the author has seen these numbers. If a mode fails, the next step is the author's decision (the spec's fallback is a short automatic likelihood refinement before sampling); it is not part of this plan.

```bash
git add XRayCalc3/Tests docs/superpowers/plans/2026-10-01-uncertainty-core-planA.md
git commit -m "+ Truth gate: classic fit then sampler on known-truth curves, periodic, profile and table"
```

---

## Outcome

_2026-10-01. Win32 Debug, CPU only, I0 = 1E7, 3000 steps (1000 burn-in, every 10th recorded), six
seeds per case, each with its own noise and its own classic fit from the design (interlayer 4.5 A)._

| Case | Slots | Walkers | Truth in 16-84 % | in 2.5-97.5 % | Summaries 16-84 / 2.5-97.5 | Worst R-hat | Acceptance | Time per seed |
|---|---|---|---|---|---|---|---|---|
| Periodic | 4 | 32 | 4/6 | 6/6 | 8/12, 12/12 | 1.02 | 0.51-0.55 | 39 s |
| Profile | 5 | 32 | 10/12 | 12/12 | 13/18, 18/18 | 1.03 | 0.48-0.51 | 39 s |
| Table, 10 entries | 13 | 32 | 45/60 | 55/60 | 17/18, 18/18 | 18.2 (seed 2) | 0.36 | 26-39 s |
| Table, 40 entries | 43 | 88 | 86/240 | 142/240 | 4/18, 11/18 | 3.1 | 0.12-0.15 | ~2 min |
| Table, 80 entries | 83 | 168 | 117/480 | 228/480 | 1/18, 2/18 | 5.2 | 0.08-0.11 | ~5 min |

Every slot's autocorrelation time was reported doubtful in every run: 200 recorded steps per walker
are too few for that estimate, so it says nothing either way here.

**Is burn-in from the classic fit enough?**

- Periodic and profile: yes. The classic fit ended within 0.01 A of the truth and the ranges cover it
  at about the expected rate.
- Table, 10 entries: yes in five seeds of six. In seed 2 the classic fit ended in a different place
  (entries up to 0.6 A off) and the walkers had not come together after 3000 steps (R-hat 18). The
  `Table_TruthInsideRange` test fails on that seed, as it should.
- So the start decides: a good classic fit needs nothing more; a poor one is not repaired by the
  burn-in, and R-hat across the walkers shows it.

**Where do tables stop being trustworthy?** Between 10 and 40 entries at these settings. At 40 and 80
entries the walkers have not converged (R-hat 3 to 5, acceptance near 0.1) and the reported ranges are
wrong: the truth is inside the 16-84 % range about a third of the time or less, and the summary numbers
fail as well (4 of 18, then 1 of 18). The spec's promise that a large table "still gets its summary
numbers" does not hold with this sampler at this run length. Whether a much longer run fixes it was
not tested.

**Two faults found in the gate itself and fixed** (commit ce98518):

- The classic periodic engine holds the period at the design's value unless given a range, so the one
  free thickness could not move; the gate now opens the period range.
- With that fault the first periodic run passed the plan's coverage bounds while half the walkers sat
  0.8 A from the truth. Coverage counts alone cannot see a split chain; the gate now also requires
  R-hat below 1.2 for every tallied value.

**Decisions for the author before plan B:** what the tool does when the walkers disagree (run longer,
refine first, or refuse with a plain message), and what it offers for tables above roughly 10 to 20
entries. The author's answer (2026-10-01): follow the recommendations - detect disagreement, one
automatic repair, then a plain message; and test run length before deciding on large tables.

### Follow-up, same day

**Run length or method?** Ten times the steps, no other change:

- Table, 10 entries, the failed seed: the medians sit on the truth (7/10 and 10/10), but R-hat is up
  to 72. Most walkers found the optimum; a few stayed behind for good. More steps do not bring them back.
- Table, 40 entries: R-hat 1.3 to 1.9, truth in 16-84 % for 17 of 40, summaries 0 of 3. Not a
  run-length problem.

**The repair, now in the core** (`TSampleRun.Recentre`, `unit_ChainStats.RHat`, `TParamStat.RHat`,
`TSampleResult.RHatWorst`, `RHAT_AGREE = 1.2`): 1000 settling steps, then the chain starts again in a
ball around its best walker, then the 3000 steps as before.

| Case | Truth in 16-84 % | in 2.5-97.5 % | Summaries 16-84 / 2.5-97.5 | Worst R-hat |
|---|---|---|---|---|
| Periodic | 4/6 | 6/6 | 8/12, 12/12 | 1.02 |
| Profile | 10/12 | 12/12 | 13/18, 18/18 | 1.02 |
| Table, 10 entries | 41/60 | 55/60 | 16/18, 18/18 | 1.13 |
| Table, 40 entries | 95/240 | 164/240 | 9/18, 12/18 | 3.4 |
| Table, 80 entries | 117/480 | 233/480 | 1/18, 1/18 | 6.0 |

All three gate tests pass, the failed seed included. The whole suite passes with the gate off
(1062 of 1062). Large tables stay wrong and R-hat says so in every case; nothing was tested between
10 and 40 entries.

**What plan B takes from this:**

- Every run is settle, restart around the best walker, sample. When `RHatWorst` is above `RHAT_AGREE`
  the tool repeats that once at a longer length; if the walkers still disagree it shows no ranges and
  says in plain words that the fit has not settled.
- A structure with more than 20 sampled table entries is refused before the run with one line saying
  why. The limit is a time saver, not the safeguard: the R-hat check is.
