unit TestMCPUniversalJob;

(* The optimize_mirror job body, run for real through a job manager.

   The other MCP fixtures test the pieces - the top-k rule on a hand-built
   swarm, the genome-to-structure mapping, the configuration parser. This one
   tests the two properties that only show up when the whole thing runs: that
   the same seed gives the same answer, and that a cancelled run stops and
   leaves no result behind.

   Both tests drive a real TUniversalOptimizer over the real Henke tables, so
   they are skipped when the tables are not on this machine. The configuration
   is deliberately tiny (twenty particles, three iterations); the point is
   reproducibility, not a good mirror. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  unit_MCPSandbox, unit_MCPJobs;

type
  [TestFixture]
  TTestMCPUniversalJob = class
  private
    FTemp: string;
    FSavedWorkDir: TWorkDir;
    /// <summary>One complete run through a manager of its own, so that two
    /// runs share nothing but the seed. The result is the caller's to free.</summary>
    function RunOnce(out JobDir: string): TJSONObject;
    /// <summary>Polls Job.State until it is Wanted or TimeoutMs elapses.</summary>
    function WaitForState(Job: TJob; Wanted: TJobState; TimeoutMs: Integer): Boolean;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure SameSeedTwice_GivesTheSameAnswer;
    [Test] procedure Cancel_StopsTheRun_AndLeavesNoResult;
  end;

implementation

uses
  System.IOUtils, System.Math, System.Diagnostics, System.Zip,
  unit_Config,
  unit_universal_types,
  unit_MCPUniversal;

const
  TEST_SEED = 12345;
  TEST_TOP_K = 3;

  { The brief's tiny run: ten light-element lines, eight candidate materials,
    the XRFCalc default search space, and however many particles and iterations
    the caller asks for. }
  TINY_CONFIG =
    '{"lines":["Be","B","C","N","O","F","Na","Mg","Al","Si"],' +
    '"element_pool":["W","Mo","Cr","Si","B","B4C","Sc","C"],' +
    '"substrate":"Si",' +
    '"structure":{"d":{"min":30,"max":80},"gamma":{"min":0.15,"max":0.70},' +
    '"N":{"min":40,"max":200},"sigma":3},' +
    '"optimizer":{"population":%d,"iterations":%d}}';

{ ----------------------------------------------------------------- helpers -- }

function HenkePath: string;
begin
  Result := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);
end;

/// The materials the tiny run picks from. Without them there is nothing to
/// optimise and the test says so rather than failing.
function HenkeTablesPresent: Boolean;
const
  Needed: array [0 .. 4] of string = ('W', 'Mo', 'Si', 'B4C', 'Sc');
var
  i: Integer;
begin
  for i := Low(Needed) to High(Needed) do
    if not TFile.Exists(HenkePath + Needed[i] + '.bin') then
      Exit(False);
  Result := True;
end;

function TinyConfig(Population, Iterations: Integer): TUniversalConfig;
var
  J: TJSONObject;
begin
  J := TJSONObject.ParseJSONValue(
    Format(TINY_CONFIG, [Population, Iterations])) as TJSONObject;
  Assert.IsNotNull(J, 'the fixture configuration does not parse');
  try
    // The output directory is the job folder; RunOptimizeJob overwrites it.
    Result := ConfigFromJSON(J, '');
  finally
    J.Free;
  end;
end;

/// The dominant material of each role of a genome as GenomeToJSON reports it:
/// the composition array holds one object per role, whose keys are the
/// materials with a non-zero fraction.
function PairOfGenome(G: TJSONObject): string;
var
  Comp: TJSONArray;
  Role, i: Integer;
  RoleObj: TJSONObject;
  BestName: string;
  BestVal, V: Double;
begin
  Result := '';
  Comp := G.GetValue('composition') as TJSONArray;
  for Role := 0 to Comp.Count - 1 do
  begin
    RoleObj := Comp.Items[Role] as TJSONObject;
    BestName := '';
    BestVal := -1;
    for i := 0 to RoleObj.Count - 1 do
    begin
      V := (RoleObj.Pairs[i].JsonValue as TJSONNumber).AsDouble;
      if V > BestVal then
      begin
        BestVal := V;
        BestName := RoleObj.Pairs[i].JsonString.Value;
      end;
    end;
    if Role > 0 then
      Result := Result + '/';
    Result := Result + BestName;
  end;
end;

/// The top-k rule, written out again here rather than borrowed from the unit
/// under test: a test that calls the same function it is checking proves
/// nothing about the rule.
function EntriesAreDistinct(A, B: TJSONObject): Boolean;
var
  GA, GB: TJSONObject;
  dA, dB: Double;
begin
  GA := A.GetValue('genome') as TJSONObject;
  GB := B.GetValue('genome') as TJSONObject;
  if not SameText(PairOfGenome(GA), PairOfGenome(GB)) then
    Exit(True);
  if GA.GetValue<Integer>('N') <> GB.GetValue<Integer>('N') then
    Exit(True);
  if Abs(GA.GetValue<Double>('gamma') - GB.GetValue<Double>('gamma')) > 0.05 then
    Exit(True);
  dA := GA.GetValue<Double>('d');
  dB := GB.GetValue<Double>('d');
  if dB = 0 then
    Exit(dA <> 0);
  Result := Abs(dA - dB) / Abs(dB) > 0.05;
end;

/// The consistency warning of a result, or '' when there is none.
function WarningOf(R: TJSONObject): string;
var
  V: TJSONValue;
begin
  V := R.FindValue('consistency_warning');
  if V = nil then
    Result := ''
  else
    Result := V.Value;
end;

/// The period and the repeat count of the stack in a package's
/// best_structure_xrc.json - what XRFCalc shows when it opens the file. The
/// period is the sum of the layer thicknesses of the repeating stack.
procedure PackagedStack(const XRFXPath: string; out Period: Double; out N: Integer);
var
  Zip: TZipFile;
  Bytes: TBytes;
  J, Stack: TJSONObject;
  Stacks, Layers: TJSONArray;
  i, k: Integer;
  Best: Integer;
begin
  Period := 0;
  N := 0;
  Zip := TZipFile.Create;
  try
    Zip.Open(XRFXPath, zmRead);
    Zip.Read('best_structure_xrc.json', Bytes);
    Zip.Close;
  finally
    Zip.Free;
  end;
  J := TJSONObject.ParseJSONValue(TEncoding.UTF8.GetString(Bytes)) as TJSONObject;
  Assert.IsNotNull(J, 'best_structure_xrc.json in ' + XRFXPath + ' does not parse');
  try
    Stacks := J.GetValue('Stacks') as TJSONArray;
    // The multilayer is the stack that repeats; a cap or a buffer has N = 1.
    Best := -1;
    for i := 0 to Stacks.Count - 1 do
      if (Stacks.Items[i] as TJSONObject).GetValue<Integer>('N') > N then
      begin
        N := (Stacks.Items[i] as TJSONObject).GetValue<Integer>('N');
        Best := i;
      end;
    if Best < 0 then
      Exit;
    Stack := Stacks.Items[Best] as TJSONObject;
    Layers := Stack.GetValue('Layers') as TJSONArray;
    for k := 0 to Layers.Count - 1 do
      Period := Period + (Layers.Items[k] as TJSONObject).GetValue<Double>('H');
  finally
    J.Free;
  end;
end;

/// The candidate object with its file path taken out, so that two runs in two
/// different job folders can be compared as text.
function WithoutPaths(Src: TJSONObject): string;
var
  Copy_: TJSONObject;
begin
  Copy_ := Src.Clone as TJSONObject;
  try
    if Copy_.FindValue('xrfx') <> nil then
      Copy_.RemovePair('xrfx').Free;
    Result := Copy_.ToJSON;
  finally
    Copy_.Free;
  end;
end;

/// The whole ranking as text, with the per-entry .xrfx paths taken out: they
/// carry the job id, which is different for every run by design.
function RankingWithoutPaths(Arr: TJSONArray): string;
var
  i: Integer;
begin
  Result := '';
  for i := 0 to Arr.Count - 1 do
    Result := Result + WithoutPaths(Arr.Items[i] as TJSONObject) + sLineBreak;
end;

{ ----------------------------------------------------------------- fixture -- }

procedure TTestMCPUniversalJob.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_OptJob_' + TGUID.NewGuid.ToString);
  FSavedWorkDir := WorkDir;
  WorkDir := TWorkDir.Create(FTemp);
  WorkDir.EnsureLayout;
end;

procedure TTestMCPUniversalJob.TearDown;
begin
  WorkDir.Free;
  WorkDir := FSavedWorkDir;
  try
    if TDirectory.Exists(FTemp) then
      TDirectory.Delete(FTemp, True);
  except
    // a leftover temp folder must not turn into a test failure
  end;
end;

function TTestMCPUniversalJob.WaitForState(Job: TJob; Wanted: TJobState;
  TimeoutMs: Integer): Boolean;
var
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  while SW.ElapsedMilliseconds < TimeoutMs do
  begin
    if Job.State = Wanted then
      Exit(True);
    Sleep(25);
  end;
  Result := Job.State = Wanted;
end;

function TTestMCPUniversalJob.RunOnce(out JobDir: string): TJSONObject;
var
  Mgr: TJobManager;
  Job: TJob;
  Request: TJSONObject;
  Config: TUniversalConfig;
begin
  Config := TinyConfig(20, 3);
  Mgr := TJobManager.Create(WorkDir);
  try
    Request := TJSONObject.Create;
    try
      Request.AddPair('seed', TJSONNumber.Create(TEST_SEED));
      Job := Mgr.Submit(jkOptimize, TEST_SEED,
        procedure(AJob: TJob)
        begin
          RunOptimizeJob(AJob, Config, TEST_TOP_K);
        end,
        Request);
    finally
      Request.Free;
    end;

    Assert.IsTrue(WaitForState(Job, jsFinished, 180000),
      'the run did not finish in three minutes; state is ' +
      JobStateName(Job.State));
    JobDir := Job.Dir;
    Result := Job.CloneResult;
    Assert.IsNotNull(Result, 'a finished job must have a result');
  finally
    Mgr.Free;     // joins the worker before the manager goes away
  end;
end;

{ ------------------------------------------------------------ determinism -- }

procedure TTestMCPUniversalJob.SameSeedTwice_GivesTheSameAnswer;
var
  R1, R2: TJSONObject;
  Dir1, Dir2: string;
  Best1, Best2: TJSONObject;
  TopK: TJSONArray;
  Rank2, Genome2: TJSONObject;
  Period: Double;
  NPeriods: Integer;
  i, j: Integer;
  JobFile: TJSONObject;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables W/Mo/Si/B4C/Sc not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  R1 := RunOnce(Dir1);
  try
    R2 := RunOnce(Dir2);
    try
      Assert.AreNotEqual(Dir1, Dir2, 'the two runs must use two job folders');

      Best1 := R1.GetValue('best') as TJSONObject;
      Best2 := R2.GetValue('best') as TJSONObject;

      { The figure of merit to every digit the server prints. }
      Assert.AreEqual(
        (Best1.GetValue('fom') as TJSONNumber).ToJSON,
        (Best2.GetValue('fom') as TJSONNumber).ToJSON,
        'the same seed must give the same figure of merit');

      { And the whole candidate with it - genome, structure and per-line
        results - so that a difference anywhere is caught, not only in the one
        number. Only the .xrfx path differs, because the job ids do. }
      Assert.AreEqual(WithoutPaths(Best1), WithoutPaths(Best2),
        'the same seed must give the same best candidate');

      Assert.AreEqual(TEST_SEED, R1.GetValue<Integer>('seed'),
        'the seed the job ran with is reported back');
      Assert.AreEqual(3, R1.GetValue<Integer>('iterations_run'),
        'three iterations were asked for');

      { Top-k: at most what was asked for, and every pair genuinely different
        by the published rule. }
      TopK := R1.GetValue('top_k') as TJSONArray;
      Assert.IsTrue(TopK.Count >= 1, 'there is always at least the winner');
      Assert.IsTrue(TopK.Count <= TEST_TOP_K,
        Format('top_k must hold at most %d entries, got %d',
          [TEST_TOP_K, TopK.Count]));
      Assert.AreEqual(WithoutPaths(Best1),
        WithoutPaths(TopK.Items[0] as TJSONObject),
        'rank 1 is the best candidate');
      for i := 0 to TopK.Count - 1 do
        for j := i + 1 to TopK.Count - 1 do
          Assert.IsTrue(
            EntriesAreDistinct(TopK.Items[i] as TJSONObject,
                               TopK.Items[j] as TJSONObject),
            Format('top_k entries %d and %d are not distinct by the rule',
              [i + 1, j + 1]));

      { The whole ranking, not only the winner, is reproducible. }
      Assert.AreEqual(
        RankingWithoutPaths(R1.GetValue('top_k') as TJSONArray),
        RankingWithoutPaths(R2.GetValue('top_k') as TJSONArray),
        'the same seed must give the same top_k, entry for entry');

      { Nothing may disagree with itself: a consistency_warning means the
        structure the client is shown does not reproduce the figure of merit it
        is shown, or that rank 1 re-scores differently from the run. }
      Assert.IsTrue(R1.FindValue('consistency_warning') = nil,
        'run 1 reported a consistency warning: ' + WarningOf(R1));
      Assert.IsTrue(R2.FindValue('consistency_warning') = nil,
        'run 2 reported a consistency warning: ' + WarningOf(R2));

      { The packages, and the state on disk. }
      Assert.IsTrue(TFile.Exists(TPath.Combine(Dir1, 'rank_1.xrfx')),
        'rank_1.xrfx must be written next to the job files');
      Assert.IsTrue(TFile.Exists(TPath.Combine(Dir1, 'config.json')),
        'the configuration the run used must be kept');
      for i := 2 to TopK.Count do
        Assert.IsTrue(
          TFile.Exists(TPath.Combine(Dir1, Format('rank_%d.xrfx', [i]))),
          Format('top_k has %d entries, so rank_%d.xrfx must exist',
            [TopK.Count, i]));

      { Each package must describe the rank it was written for. The results
        folder is shared, so best_structure_xrc.json is rewritten per rank; if
        that were skipped, rank 2's package would show the winner's stack. }
      if TopK.Count >= 2 then
      begin
        Rank2 := TopK.Items[1] as TJSONObject;
        Genome2 := Rank2.GetValue('genome') as TJSONObject;
        PackagedStack(TPath.Combine(Dir1, 'rank_2.xrfx'), Period, NPeriods);
        Assert.AreEqual(Genome2.GetValue<Integer>('N'), NPeriods,
          'rank_2.xrfx must carry rank 2''s repeat count, not the winner''s');
        Assert.AreEqual(Genome2.GetValue<Double>('d'), Period, 0.05,
          'rank_2.xrfx must carry rank 2''s period, not the winner''s');
      end;

      JobFile := TJSONObject.ParseJSONValue(
        TFile.ReadAllText(TPath.Combine(Dir1, 'job.json'))) as TJSONObject;
      Assert.IsNotNull(JobFile, 'job.json must be readable JSON');
      try
        Assert.AreEqual('finished', JobFile.GetValue<string>('state'));
        Assert.AreEqual(TEST_SEED, JobFile.GetValue<Integer>('seed'),
          'job.json carries the seed, so a run can be repeated from the folder');
      finally
        JobFile.Free;
      end;
    finally
      R2.Free;
    end;
  finally
    R1.Free;
  end;
end;

{ ----------------------------------------------------------- cancellation -- }

procedure TTestMCPUniversalJob.Cancel_StopsTheRun_AndLeavesNoResult;
var
  Mgr: TJobManager;
  Job: TJob;
  Request: TJSONObject;
  Config: TUniversalConfig;
  SW: TStopwatch;
  Stopped: Boolean;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables W/Mo/Si/B4C/Sc not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  { Two hundred particles and five hundred iterations: far more work than the
    test will wait for, so the run can only end by being stopped. }
  Config := TinyConfig(200, 500);
  Mgr := TJobManager.Create(WorkDir);
  try
    Request := TJSONObject.Create;
    try
      Request.AddPair('seed', TJSONNumber.Create(TEST_SEED));
      Job := Mgr.Submit(jkOptimize, TEST_SEED,
        procedure(AJob: TJob)
        begin
          RunOptimizeJob(AJob, Config, TEST_TOP_K);
        end,
        Request);
    finally
      Request.Free;
    end;

    { Wait for the first progress report, which is where the body looks at the
      cancellation flag. A message means the callback has fired at least once. }
    SW := TStopwatch.StartNew;
    while (Job.LastMessage = '') and (Job.State in [jsQueued, jsRunning]) and
          (SW.ElapsedMilliseconds < 120000) do
      Sleep(25);
    Assert.AreNotEqual('', Job.LastMessage,
      'the optimizer reported no progress within two minutes');

    SW := TStopwatch.StartNew;
    Mgr.Cancel(Job.Id);
    Stopped := WaitForState(Job, jsCancelled, 10000);
    Assert.IsTrue(Stopped,
      Format('a cancelled run must stop within ten seconds; after %d ms it is %s',
        [SW.ElapsedMilliseconds, JobStateName(Job.State)]));
    Assert.IsFalse(Job.HasResult,
      'a run that was cut short must not leave a result: the job is cancelled, ' +
      'not finished');

    { What the engine did write is still there, which is the point of leaving
      the folder alone. }
    Assert.IsTrue(
      TFile.Exists(TPath.Combine(TPath.Combine(Job.Dir, 'results'), 'progress.log')),
      'the partial progress log stays in the job folder');
  finally
    Mgr.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPUniversalJob);

end.
