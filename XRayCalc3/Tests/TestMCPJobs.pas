unit TestMCPJobs;

(* The job manager, exercised with trivial bodies rather than with the engines.

   What is being tested here is the machinery - the queue, the single worker,
   the state transitions, cancellation and the files on disk - so the bodies are
   short Sleep loops that poll CancelRequested and report progress exactly as a
   fit or an optimisation does. A real engine would make these tests slow and
   would test the engine, not the manager.

   Every test uses its own temp work directory and frees the manager in
   TearDown, which is also what proves the destructor joins the worker: if it
   did not, the directory delete that follows would fail on a locked file. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.JSON, System.Diagnostics,
  unit_MCPSandbox, unit_MCPErrors, unit_MCPJobs;

type
  [TestFixture]
  TTestMCPJobs = class
  private
    FTemp: string;
    FWD: TWorkDir;
    FMgr: TJobManager;
    /// <summary>A body that loops Iterations times, sleeping 10 ms and
    /// reporting progress each time, stops when cancellation is requested and
    /// otherwise leaves {"ok":true,"iterations":n} behind.</summary>
    function LoopBody(Iterations: Integer): TJobBody;
    /// <summary>A body that raises EMCPError with this code.</summary>
    function FailingBody(const Code, Msg: string): TJobBody;
    /// <summary>A body that raises a plain Exception - the kind the manager has
    /// to turn into an 'internal' failure rather than let out.</summary>
    function RaisingBody(const Msg: string): TJobBody;
    /// <summary>A body that replaces its own job folder with a file, so every
    /// job.json write fails, and then reports progress Iterations times.</summary>
    function BreakDirBody(Iterations: Integer): TJobBody;
    /// <summary>Polls Job.State until it is Wanted or TimeoutMs elapses.</summary>
    function WaitForState(Job: TJob; Wanted: TJobState; TimeoutMs: Integer): Boolean;
    function StateOf(Status: TJSONObject): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Submit_RunsAndFinishes_WithResult;
    [Test] procedure Submit_WritesRequestJSON;
    [Test] procedure Finished_JobFileExists;
    [Test] procedure Status_UnknownId_IsUnknown;
    [Test] procedure Cancel_UnknownId_IsUnknown;
    [Test] procedure ResultOf_UnknownId_RaisesJobUnknown;
    [Test] procedure ResultOf_RunningJob_RaisesJobNotFinished;
    [Test] procedure Cancel_QueuedJob_CancelledAtOnce;
    [Test] procedure Cancel_RunningJob_BecomesCancelled;
    [Test] procedure ResultOf_CancelledJob_RaisesJobCancelled;
    [Test] procedure FailingBody_JobFailed_WithCodeInError;
    [Test] procedure Queue_SeventeenthSubmit_RaisesTooManyJobs;
    [Test] procedure Progress_IsReportedInStatus;
    [Test] procedure NewJobFolder_CreatesUniqueFolder;
    [Test] procedure UnwritableJobDir_JobStillFinishes_WarnsOnce;
    [Test] procedure PlainExceptionBody_FailsInternal_QueueSurvives;
  end;

implementation

{ ------------------------------------------------------------- fixture -- }

procedure TTestMCPJobs.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Jobs_' + TGUID.NewGuid.ToString);
  FWD := TWorkDir.Create(FTemp);
  FWD.EnsureLayout;
  FMgr := TJobManager.Create(FWD);
end;

procedure TTestMCPJobs.TearDown;
begin
  FMgr.Free;      // cancels the running job and waits for the worker
  FMgr := nil;
  FWD.Free;
  FWD := nil;
  if TDirectory.Exists(FTemp) then
    TDirectory.Delete(FTemp, True);
end;

function TTestMCPJobs.LoopBody(Iterations: Integer): TJobBody;
begin
  Result :=
    procedure(Job: TJob)
    var
      I: Integer;
      R: TJSONObject;
    begin
      RandSeed := Job.Seed;          // what a real body does first
      Job.MaxIterations := Iterations;
      for I := 1 to Iterations do
      begin
        if Job.CancelRequested then
          Exit;                      // no result: the manager marks it cancelled
        Sleep(10);
        Job.Progress(I, I * 1.0, 'step ' + IntToStr(I));
      end;
      R := TJSONObject.Create;
      R.AddPair('ok', TJSONBool.Create(True));
      R.AddPair('iterations', TJSONNumber.Create(Iterations));
      Job.ResultObj := R;            // the job owns it from here on
    end;
end;

function TTestMCPJobs.FailingBody(const Code, Msg: string): TJobBody;
begin
  Result :=
    procedure(Job: TJob)
    begin
      Sleep(10);
      raise EMCPError.Create(Code, Msg, 'from the test body');
    end;
end;

function TTestMCPJobs.RaisingBody(const Msg: string): TJobBody;
begin
  Result :=
    procedure(Job: TJob)
    begin
      Sleep(10);
      raise Exception.Create(Msg);
    end;
end;

function TTestMCPJobs.BreakDirBody(Iterations: Integer): TJobBody;
begin
  Result :=
    procedure(Job: TJob)
    var
      I: Integer;
      R: TJSONObject;
    begin
      { A file where the folder should be: every write into it fails, which is
        what a read-only or deleted work directory looks like from here. }
      TDirectory.Delete(Job.Dir, True);
      TFile.WriteAllText(Job.Dir, 'not a directory');
      for I := 1 to Iterations do
      begin
        if Job.CancelRequested then
          Exit;
        Sleep(10);
        Job.Progress(I, I * 1.0, 'step ' + IntToStr(I));
      end;
      R := TJSONObject.Create;
      R.AddPair('ok', TJSONBool.Create(True));
      Job.ResultObj := R;
    end;
end;

function TTestMCPJobs.WaitForState(Job: TJob; Wanted: TJobState; TimeoutMs: Integer): Boolean;
var
  SW: TStopwatch;
begin
  SW := TStopwatch.StartNew;
  while SW.ElapsedMilliseconds < TimeoutMs do
  begin
    if Job.State = Wanted then
      Exit(True);
    Sleep(5);
  end;
  Result := Job.State = Wanted;
end;

function TTestMCPJobs.StateOf(Status: TJSONObject): string;
begin
  try
    Result := Status.GetValue<string>('state');
  finally
    Status.Free;
  end;
end;

{ --------------------------------------------------------------- tests -- }

procedure TTestMCPJobs.Submit_RunsAndFinishes_WithResult;
var
  Job: TJob;
  Res: TJSONObject;
begin
  Job := FMgr.Submit(jkOptimize, 42, LoopBody(3), nil);
  Assert.IsTrue(WaitForState(Job, jsFinished, 5000), 'the job must finish');
  Assert.AreEqual('finished', StateOf(FMgr.Status(Job.Id)));

  Res := FMgr.ResultOf(Job.Id);
  try
    Assert.IsTrue(Res.GetValue<Boolean>('ok'), 'the body''s result comes back');
    Assert.AreEqual(3, Res.GetValue<Integer>('iterations'));
  finally
    Res.Free;
  end;

  // A clone, not the job's own object: asking twice must work.
  Res := FMgr.ResultOf(Job.Id);
  try
    Assert.IsNotNull(Res);
  finally
    Res.Free;
  end;

  Assert.AreEqual(42, Job.Seed, 'the seed is echoed');
end;

procedure TTestMCPJobs.Submit_WritesRequestJSON;
var
  Job: TJob;
  Req: TJSONObject;
  Text: string;
begin
  Req := TJSONObject.Create;
  try
    Req.AddPair('hello', 'world');
    Job := FMgr.Submit(jkFit, 1, LoopBody(1), Req);
  finally
    Req.Free;      // Submit copies it out to disk and keeps nothing
  end;
  Assert.IsTrue(TFile.Exists(TPath.Combine(Job.Dir, 'request.json')),
    'request.json is written at submit');
  Text := TFile.ReadAllText(TPath.Combine(Job.Dir, 'request.json'), TEncoding.UTF8);
  Assert.IsTrue(Pos('"hello"', Text) > 0, 'request.json holds the arguments, got ' + Text);
  Assert.IsTrue(Job.Id.StartsWith('fit-'), 'a fit job id starts with fit-, got ' + Job.Id);
end;

procedure TTestMCPJobs.Finished_JobFileExists;
var
  Job: TJob;
  Text: string;
begin
  Job := FMgr.Submit(jkOptimize, 7, LoopBody(2), nil);
  Assert.IsTrue(WaitForState(Job, jsFinished, 5000), 'the job must finish');
  Assert.IsTrue(TFile.Exists(TPath.Combine(Job.Dir, 'job.json')),
    'job.json is written for a finished job');
  Text := TFile.ReadAllText(TPath.Combine(Job.Dir, 'job.json'), TEncoding.UTF8);
  Assert.IsTrue(Pos('"finished"', Text) > 0, 'job.json holds the final state, got ' + Text);
  Assert.IsTrue(Pos(Job.Id, Text) > 0, 'job.json names the job');
end;

procedure TTestMCPJobs.Status_UnknownId_IsUnknown;
begin
  Assert.AreEqual('unknown', StateOf(FMgr.Status('no-such-job')));
end;

procedure TTestMCPJobs.Cancel_UnknownId_IsUnknown;
begin
  Assert.AreEqual('unknown', StateOf(FMgr.Cancel('no-such-job')));
end;

procedure TTestMCPJobs.ResultOf_UnknownId_RaisesJobUnknown;
begin
  try
    FMgr.ResultOf('no-such-job').Free;
    Assert.Fail('an unknown id must be an error for job_result');
  except
    on E: EMCPError do
      Assert.AreEqual('job_unknown', E.Code);
  end;
end;

procedure TTestMCPJobs.ResultOf_RunningJob_RaisesJobNotFinished;
var
  Job: TJob;
begin
  Job := FMgr.Submit(jkFit, 1, LoopBody(500), nil);   // 5 s of work
  Assert.IsTrue(WaitForState(Job, jsRunning, 2000), 'the job must start');
  try
    FMgr.ResultOf(Job.Id).Free;
    Assert.Fail('a running job has no result yet');
  except
    on E: EMCPError do
    begin
      Assert.AreEqual('job_not_finished', E.Code);
      Assert.IsTrue(Pos('"running"', E.Detail) > 0,
        'the detail carries the status, got "' + E.Detail + '"');
    end;
  end;
end;

procedure TTestMCPJobs.Cancel_QueuedJob_CancelledAtOnce;
var
  Blocker, Queued: TJob;
begin
  Blocker := FMgr.Submit(jkFit, 1, LoopBody(500), nil);
  Assert.IsTrue(WaitForState(Blocker, jsRunning, 2000), 'the first job must start');

  Queued := FMgr.Submit(jkFit, 2, LoopBody(1), nil);
  Assert.AreEqual('queued', StateOf(FMgr.Status(Queued.Id)), 'the worker is busy');

  // No sleeping: a queued job is cancelled synchronously.
  Assert.AreEqual('cancelled', StateOf(FMgr.Cancel(Queued.Id)));
  Assert.AreEqual(0, FMgr.QueuedCount, 'it is taken out of the queue');
  Assert.IsTrue(TFile.Exists(TPath.Combine(Queued.Dir, 'job.json')),
    'the cancelled job still has its job.json');
end;

procedure TTestMCPJobs.Cancel_RunningJob_BecomesCancelled;
var
  Job: TJob;
  StateNow: string;
begin
  Job := FMgr.Submit(jkOptimize, 1, LoopBody(500), nil);
  Assert.IsTrue(WaitForState(Job, jsRunning, 2000), 'the job must start');

  // The status returned by cancel_job is the current one: the body has not
  // noticed yet, so it is still running.
  StateNow := StateOf(FMgr.Cancel(Job.Id));
  Assert.AreEqual('running', StateNow);

  Assert.IsTrue(WaitForState(Job, jsCancelled, 2000),
    'the body polls CancelRequested and stops within two seconds');
end;

procedure TTestMCPJobs.ResultOf_CancelledJob_RaisesJobCancelled;
var
  Job: TJob;
begin
  Job := FMgr.Submit(jkOptimize, 1, LoopBody(500), nil);
  Assert.IsTrue(WaitForState(Job, jsRunning, 2000), 'the job must start');
  FMgr.Cancel(Job.Id).Free;
  Assert.IsTrue(WaitForState(Job, jsCancelled, 2000), 'the job must stop');

  try
    FMgr.ResultOf(Job.Id).Free;
    Assert.Fail('a cancelled job has no result');
  except
    on E: EMCPError do
      Assert.AreEqual('job_cancelled', E.Code);
  end;
end;

procedure TTestMCPJobs.FailingBody_JobFailed_WithCodeInError;
var
  Job: TJob;
  Text: string;
begin
  Job := FMgr.Submit(jkFit, 1, FailingBody('unknown_material', 'no table for Xx'), nil);
  Assert.IsTrue(WaitForState(Job, jsFailed, 5000), 'the job must fail');

  try
    FMgr.ResultOf(Job.Id).Free;
    Assert.Fail('a failed job has no result');
  except
    on E: EMCPError do
    begin
      Assert.AreEqual('job_failed', E.Code);
      Assert.IsTrue(Pos('unknown_material', E.Detail) > 0,
        'the body''s own code is in the detail, got "' + E.Detail + '"');
      Assert.IsTrue(Pos('no table for Xx', E.Message) > 0,
        'the body''s message is reported, got "' + E.Message + '"');
    end;
  end;

  Text := TFile.ReadAllText(TPath.Combine(Job.Dir, 'job.json'), TEncoding.UTF8);
  Assert.IsTrue(Pos('"error"', Text) > 0, 'job.json carries the error, got ' + Text);
  Assert.IsTrue(Pos('unknown_material', Text) > 0, 'with the original code');
end;

procedure TTestMCPJobs.Queue_SeventeenthSubmit_RaisesTooManyJobs;
var
  Blocker: TJob;
  I: Integer;
  Raised: Boolean;
  Code: string;
begin
  { The worker has to be busy before the queue can be filled, otherwise it
    would be draining it while the test fills it. }
  Blocker := FMgr.Submit(jkOptimize, 1, LoopBody(500), nil);
  Assert.IsTrue(WaitForState(Blocker, jsRunning, 2000), 'the first job must start');

  for I := 1 to MAX_QUEUED_JOBS do
    FMgr.Submit(jkOptimize, I, LoopBody(1), nil);
  Assert.AreEqual(MAX_QUEUED_JOBS, FMgr.QueuedCount);

  Raised := False;
  Code := '';
  try
    FMgr.Submit(jkOptimize, 99, LoopBody(1), nil);
  except
    on E: EMCPError do
    begin
      Raised := True;
      Code := E.Code;
    end;
  end;
  Assert.IsTrue(Raised, 'the seventeenth queued job must be refused');
  Assert.AreEqual('too_many_jobs', Code);
end;

procedure TTestMCPJobs.Progress_IsReportedInStatus;
var
  Job: TJob;
  Status: TJSONObject;
begin
  Job := FMgr.Submit(jkFit, 1, LoopBody(500), nil);
  Assert.IsTrue(WaitForState(Job, jsRunning, 2000), 'the job must start');
  Sleep(200);   // several iterations of the body

  Status := FMgr.Status(Job.Id);
  try
    Assert.AreEqual('running', Status.GetValue<string>('state'));
    Assert.AreEqual('fit', Status.GetValue<string>('kind'));
    Assert.IsTrue(Status.GetValue<Integer>('iteration') > 0, 'the iteration advances');
    Assert.AreEqual(500, Status.GetValue<Integer>('max_iterations'));
    Assert.IsTrue(Status.GetValue<Double>('elapsed_s') > 0, 'the clock runs');
    Assert.IsTrue(Status.GetValue<string>('last_message').StartsWith('step '),
      'the last progress message is reported');
  finally
    Status.Free;
  end;
end;

procedure TTestMCPJobs.NewJobFolder_CreatesUniqueFolder;
var
  IdA, IdB, DirA, DirB: string;
begin
  DirA := NewJobFolder(FWD, 'calc', IdA);
  DirB := NewJobFolder(FWD, 'calc', IdB);
  Assert.AreNotEqual(IdA, IdB, 'two folders made in the same second differ');
  Assert.IsTrue(TDirectory.Exists(DirA));
  Assert.IsTrue(TDirectory.Exists(DirB));
  Assert.IsTrue(IdA.StartsWith('calc-'), 'the prefix is kept, got ' + IdA);
  Assert.AreEqual(TPath.Combine(FWD.JobsDir, IdA), DirA);
end;

procedure TTestMCPJobs.UnwritableJobDir_JobStillFinishes_WarnsOnce;
var
  Job: TJob;
  ErrPath: string;
  SavedErr: TTextRec;
  Line, Captured: string;
  Warnings: Integer;
  F: TextFile;
  Res: TJSONObject;
begin
  { The warning is written to stderr, so stderr is where it has to be counted.
    ErrOutput is redirected for the length of the job and put back afterwards.
    File variables cannot be assigned, and the record holds a pointer into
    itself, so it is copied out and back into the same storage with Move. }
  ErrPath := TPath.Combine(FTemp, 'stderr.txt');
  Move(TTextRec(ErrOutput), SavedErr, SizeOf(TTextRec));
  AssignFile(ErrOutput, ErrPath);
  Rewrite(ErrOutput);
  try
    Job := FMgr.Submit(jkFit, 1, BreakDirBody(50), nil);   // ~500 ms of progress
    Assert.IsTrue(WaitForState(Job, jsFinished, 10000),
      'a job.json that cannot be written must not stop the job');
  finally
    CloseFile(ErrOutput);
    Move(SavedErr, TTextRec(ErrOutput), SizeOf(TTextRec));
  end;

  // The in-memory status is unaffected by the file having failed.
  Assert.AreEqual('finished', StateOf(FMgr.Status(Job.Id)));
  Res := FMgr.ResultOf(Job.Id);
  try
    Assert.IsTrue(Res.GetValue<Boolean>('ok'), 'the result is still there');
  finally
    Res.Free;
  end;

  { Warnings are counted by their prefix, not by counting lines: the operating
    system message quoted in one can itself run to a second line. }
  Warnings := 0;
  Captured := '';
  AssignFile(F, ErrPath);
  Reset(F);
  try
    while not Eof(F) do
    begin
      ReadLn(F, Line);
      Captured := Captured + Line + '|';
      if Line.StartsWith('XRC_MCP:') then
        Inc(Warnings);
    end;
  finally
    CloseFile(F);
  end;
  Assert.IsTrue(Warnings = 1,
    Format('exactly one warning per job, got %d in: %s', [Warnings, Captured]));
end;

procedure TTestMCPJobs.PlainExceptionBody_FailsInternal_QueueSurvives;
var
  Bad, Good: TJob;
begin
  Bad := FMgr.Submit(jkOptimize, 1, RaisingBody('something the body did not expect'), nil);
  Assert.IsTrue(WaitForState(Bad, jsFailed, 5000), 'the job must fail');
  try
    FMgr.ResultOf(Bad.Id).Free;
    Assert.Fail('a failed job has no result');
  except
    on E: EMCPError do
    begin
      Assert.AreEqual('job_failed', E.Code);
      Assert.IsTrue(Pos('internal', E.Detail) > 0,
        'an exception that is not an EMCPError is reported as internal, got "' + E.Detail + '"');
    end;
  end;

  // The worker is the only one there is: it has to still be there.
  Good := FMgr.Submit(jkOptimize, 2, LoopBody(2), nil);
  Assert.IsTrue(WaitForState(Good, jsFinished, 5000),
    'the queue survives a job that blew up');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPJobs);

end.
