unit unit_MCPJobs;

(* Long-running work: the job registry, the queue and the one worker thread.

   Everything the client cannot wait for in a single round trip - a mirror
   optimisation, an XRR fit - is submitted as a job and polled afterwards with
   job_status / job_result / cancel_job.

   One worker, one job at a time (design note section 5). The reasons are not
   about load: System.RandSeed is process-global, so two seeded jobs running at
   once would not be reproducible; both engines already use every core through
   Parallel.For, so a second job would only take cores away from the first; and
   TMaterialMixer.Initialize changes the process working directory while it
   reads. The queue is therefore a genuine FIFO queue and is bounded
   (MAX_QUEUED_JOBS) so that a client cannot fill memory with work that will
   never run.

   On disk, jobs\<job_id>\ holds request.json (the arguments exactly as they
   arrived) and job.json (the status, rewritten on every state change and, at
   most every JOB_SAVE_INTERVAL_MS, on progress). A failed job's job.json also
   carries "error"; a cancelled job that produced something carries "partial".
   The registry itself is in memory only: after a restart every id is unknown,
   which is what the requirements ask for.

   Threading contract
   - Every mutable field of TJob is read and written under TJob.FLock, except
     the cancellation flag, which is an interlocked integer so that a tight
     body loop can poll it without touching a critical section.
   - ResultObj and ErrorObj are owned by the job. A caller never gets the
     object itself: CloneResult and ErrorJSON clone under the lock, so the
     worker cannot be mutating what a tool thread is copying.
   - Lock order is always manager first, job second. Nothing takes the manager
     lock while holding a job lock. *)

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.SyncObjs,
  System.Diagnostics, System.Generics.Collections,
  unit_MCPSandbox;

const
  MAX_QUEUED_JOBS      = 16;    // jobs waiting to run; the running one is extra
  JOB_SAVE_INTERVAL_MS = 250;   // job.json is not rewritten more often than this

type
  TJobState = (jsQueued, jsRunning, jsFinished, jsFailed, jsCancelled);
  TJobKind = (jkOptimize, jkFit);

  TJob = class;

  /// <summary>The work itself, run on the worker thread. It sets RandSeed from
  /// Job.Seed first thing, polls Job.CancelRequested often enough to stop
  /// within a second or two, reports progress with Job.Progress, and leaves the
  /// answer in Job.ResultObj. Raising EMCPError fails the job with that code.</summary>
  TJobBody = reference to procedure(Job: TJob);

  TJob = class
  private
    FLock: TCriticalSection;
    FId: string;
    FKind: TJobKind;
    FDir: string;
    FState: TJobState;
    FSeed: Integer;
    FIteration: Integer;
    FMaxIterations: Integer;
    FBestValue: Double;
    FLastMessage: string;
    FStartedUTC: string;
    FFinishedUTC: string;
    FStopwatch: TStopwatch;
    FSinceSave: TStopwatch;
    FCancelFlag: Integer;        // 0/1, touched only through TInterlocked
    FResultObj: TJSONObject;     // owned
    FErrorObj: TJSONObject;      // owned
    FBody: TJobBody;
    function StatusJSONLocked: TJSONObject;
    procedure SaveLocked;
    function GetState: TJobState;
    function GetSeed: Integer;
    procedure SetSeed(Value: Integer);
    function GetIteration: Integer;
    function GetMaxIterations: Integer;
    procedure SetMaxIterations(Value: Integer);
    function GetBestValue: Double;
    procedure SetBestValue(Value: Double);
    function GetLastMessage: string;
    procedure SetLastMessage(const Value: string);
    function GetCancelRequested: Boolean;
    procedure SetCancelRequested(Value: Boolean);
    procedure SetResultObj(Value: TJSONObject);
    function GetElapsedMs: Int64;
    function GetHasResult: Boolean;
  public
    constructor Create(const AId: string; AKind: TJobKind; const ADir: string);
    destructor Destroy; override;

    /// <summary>Called by the body. Updates the fields under the lock and
    /// rewrites job.json, but not more often than JOB_SAVE_INTERVAL_MS - a fit
    /// reports every iteration and the file would otherwise be the bottleneck.
    /// An empty AMsg leaves the previous message alone.</summary>
    procedure Progress(AIteration: Integer; ABest: Double; const AMsg: string = '');
    /// <summary>{job_id,state,kind,iteration,max_iterations,best_value,
    /// elapsed_s,last_message,seed}. Caller frees.</summary>
    function StatusJSON: TJSONObject;
    /// <summary>Writes job.json: the status, plus "error" when the job failed
    /// and "partial" when a cancelled job left a result behind.</summary>
    procedure SaveJobFile;
    /// <summary>A copy of the result, or nil when there is none. Caller frees.</summary>
    function CloneResult: TJSONObject;
    /// <summary>A copy of the error object, or nil. Caller frees.</summary>
    function CloneError: TJSONObject;
    /// <summary>Sets the error the job failed with (takes no ownership of
    /// anything; builds {code,message,detail} itself).</summary>
    procedure SetError(const ACode, AMessage, ADetail: string);

    property Id: string read FId;
    property Kind: TJobKind read FKind;
    property Dir: string read FDir;
    property State: TJobState read GetState;
    property Seed: Integer read GetSeed write SetSeed;
    property Iteration: Integer read GetIteration;
    property MaxIterations: Integer read GetMaxIterations write SetMaxIterations;
    property BestValue: Double read GetBestValue write SetBestValue;
    property LastMessage: string read GetLastMessage write SetLastMessage;
    property ElapsedMs: Int64 read GetElapsedMs;
    property HasResult: Boolean read GetHasResult;
    /// <summary>Polled by the body; set by Cancel and by the manager's
    /// destructor. Interlocked, so it needs no lock.</summary>
    property CancelRequested: Boolean read GetCancelRequested write SetCancelRequested;
    /// <summary>Write-only on purpose: the job takes ownership and any reader
    /// would be holding a pointer the worker may free. Read it with
    /// CloneResult.</summary>
    property ResultObj: TJSONObject write SetResultObj;
    property Body: TJobBody read FBody;
  end;

  TJobManager = class
  private
    FWorkDir: TWorkDir;                        // not owned
    FJobs: TObjectDictionary<string, TJob>;    // owns the jobs
    FQueue: TQueue<TJob>;                      // references only
    FWorker: TThread;
    FLock: TCriticalSection;
    FWake: TEvent;
    FTerminating: Boolean;
    FRunning: TJob;                            // the job the worker is in, or nil
    /// <summary>Pops the next queued job, marks it running and returns it; nil
    /// when the queue is empty or the manager is shutting down.</summary>
    function TakeNext: TJob;
    /// <summary>Runs one job to completion on the worker thread.</summary>
    procedure RunJob(Job: TJob);
    procedure RemoveFromQueueLocked(Job: TJob);
    function UnknownStatus(const Id: string): TJSONObject;
  public
    constructor Create(AWorkDir: TWorkDir);
    destructor Destroy; override;
    /// <summary>Creates jobs\&lt;id&gt;\, writes request.json and job.json,
    /// enqueues the job and wakes the worker. Raises EMCPError
    /// ('too_many_jobs') when MAX_QUEUED_JOBS are already waiting. The job
    /// comes back in state queued; it may already be running by the time the
    /// caller looks at it.</summary>
    function Submit(Kind: TJobKind; Seed: Integer; const Body: TJobBody;
      const Request: TJSONObject): TJob;
    /// <summary>The job with this id, or nil. The object stays alive until the
    /// manager is freed.</summary>
    function Find(const Id: string): TJob;
    /// <summary>The status object; {"job_id","state":"unknown"} for an id this
    /// server has never seen (the registry does not survive a restart).</summary>
    function Status(const Id: string): TJSONObject;
    /// <summary>A clone of the result of a finished job. Raises EMCPError
    /// job_unknown / job_not_finished / job_failed / job_cancelled otherwise.</summary>
    function ResultOf(const Id: string): TJSONObject;
    /// <summary>Requests cancellation and returns the status. A queued job is
    /// cancelled at once; a running one is asked to stop and the status
    /// returned is still "running"; a job that has already ended is unchanged;
    /// an unknown id is "unknown", not an error.</summary>
    function Cancel(const Id: string): TJSONObject;
    /// <summary>Jobs waiting to run (the running one is not counted).</summary>
    function QueuedCount: Integer;
  end;

function JobStateName(S: TJobState): string;
function JobKindName(K: TJobKind): string;
function JobKindPrefix(K: TJobKind): string;   // 'opt' | 'fit'

/// <summary>Creates jobs\&lt;prefix&gt;-yyyymmdd-hhnnss-&lt;4 hex&gt;\ under the
/// work directory and returns its absolute path; JobId is the folder name. The
/// hex comes from a GUID, not from Random: the id must be unique without
/// touching RandSeed, which is process-global and is what makes a seeded job
/// reproducible.</summary>
function NewJobFolder(const Prefix: string; out JobId: string): string; overload;
function NewJobFolder(AWorkDir: TWorkDir; const Prefix: string; out JobId: string): string; overload;

var
  Jobs: TJobManager;

implementation

uses
  System.IOUtils, unit_MCPErrors, unit_MCPJournal;

function JobStateName(S: TJobState): string;
begin
  case S of
    jsQueued:    Result := 'queued';
    jsRunning:   Result := 'running';
    jsFinished:  Result := 'finished';
    jsFailed:    Result := 'failed';
    jsCancelled: Result := 'cancelled';
  else
    Result := 'unknown';
  end;
end;

function JobKindName(K: TJobKind): string;
begin
  if K = jkFit then Result := 'fit' else Result := 'optimize';
end;

function JobKindPrefix(K: TJobKind): string;
begin
  if K = jkFit then Result := 'fit' else Result := 'opt';
end;

{ Four hex digits from a GUID rather than from Random: see NewJobFolder. }
function FourHex: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := LowerCase(IntToHex(G.D1 and $FFFF, 4));
end;

function NewJobFolder(AWorkDir: TWorkDir; const Prefix: string; out JobId: string): string;
var
  Attempt: Integer;
begin
  if AWorkDir = nil then
    raise EMCPError.Create('internal', 'No work directory');
  for Attempt := 1 to 100 do
  begin
    JobId := Format('%s-%s-%s', [Prefix, FormatDateTime('yyyymmdd-hhnnss', Now), FourHex]);
    Result := TPath.Combine(AWorkDir.JobsDir, JobId);
    if not TDirectory.Exists(Result) then
    begin
      TDirectory.CreateDirectory(Result);
      Exit;
    end;
  end;
  raise EMCPError.Create('internal', 'Cannot create a unique job folder', AWorkDir.JobsDir);
end;

function NewJobFolder(const Prefix: string; out JobId: string): string;
begin
  Result := NewJobFolder(WorkDir, Prefix, JobId);
end;

{ UTF-8 without a byte order mark: TFile.WriteAllText with TEncoding.UTF8
  writes a preamble and a BOM in front of a '{' trips strict JSON parsers. }
procedure WriteJSONFile(const Path: string; const V: TJSONValue);
var
  S: string;
begin
  if V = nil then
    S := '{}'
  else
    S := V.ToJSON;
  TFile.WriteAllBytes(Path, TEncoding.UTF8.GetBytes(S));
end;

{ ------------------------------------------------------------------ TJob -- }

constructor TJob.Create(const AId: string; AKind: TJobKind; const ADir: string);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FId := AId;
  FKind := AKind;
  FDir := ADir;
  FState := jsQueued;
  FSeed := -1;
  FBestValue := 0;
  FStopwatch := TStopwatch.Create;
  FSinceSave := TStopwatch.Create;
end;

destructor TJob.Destroy;
begin
  FResultObj.Free;
  FErrorObj.Free;
  FLock.Free;
  inherited Destroy;
end;

function TJob.StatusJSONLocked: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('job_id', FId);
    Result.AddPair('state', JobStateName(FState));
    Result.AddPair('kind', JobKindName(FKind));
    Result.AddPair('iteration', TJSONNumber.Create(FIteration));
    Result.AddPair('max_iterations', TJSONNumber.Create(FMaxIterations));
    Result.AddPair('best_value', JSONArgs.Num(FBestValue));
    Result.AddPair('elapsed_s', JSONArgs.Num(FStopwatch.ElapsedMilliseconds / 1000));
    Result.AddPair('last_message', FLastMessage);
    Result.AddPair('seed', TJSONNumber.Create(FSeed));
    if FStartedUTC <> '' then
      Result.AddPair('started_utc', FStartedUTC);
    if FFinishedUTC <> '' then
      Result.AddPair('finished_utc', FFinishedUTC);
  except
    Result.Free;
    raise;
  end;
end;

procedure TJob.SaveLocked;
var
  Obj: TJSONObject;
begin
  { job.json is diagnostics on disk; a file that cannot be written must not
    take a running fit down with it. }
  try
    Obj := StatusJSONLocked;
    try
      if (FState = jsFailed) and (FErrorObj <> nil) then
        Obj.AddPair('error', FErrorObj.Clone as TJSONValue);
      if (FState = jsCancelled) and (FResultObj <> nil) then
        Obj.AddPair('partial', FResultObj.Clone as TJSONValue);
      WriteJSONFile(TPath.Combine(FDir, 'job.json'), Obj);
    finally
      Obj.Free;
    end;
    FSinceSave := TStopwatch.StartNew;
  except
    on E: Exception do
    begin
      WriteLn(ErrOutput, 'XRC_MCP: cannot write job.json for ' + FId + ': ' + E.Message);
      Flush(ErrOutput);
    end;
  end;
end;

procedure TJob.Progress(AIteration: Integer; ABest: Double; const AMsg: string);
begin
  FLock.Enter;
  try
    FIteration := AIteration;
    FBestValue := ABest;
    if AMsg <> '' then
      FLastMessage := AMsg;
    if (not FSinceSave.IsRunning) or (FSinceSave.ElapsedMilliseconds >= JOB_SAVE_INTERVAL_MS) then
      SaveLocked;
  finally
    FLock.Leave;
  end;
end;

function TJob.StatusJSON: TJSONObject;
begin
  FLock.Enter;
  try
    Result := StatusJSONLocked;
  finally
    FLock.Leave;
  end;
end;

procedure TJob.SaveJobFile;
begin
  FLock.Enter;
  try
    SaveLocked;
  finally
    FLock.Leave;
  end;
end;

function TJob.CloneResult: TJSONObject;
begin
  FLock.Enter;
  try
    if FResultObj = nil then
      Result := nil
    else
      Result := FResultObj.Clone as TJSONObject;
  finally
    FLock.Leave;
  end;
end;

function TJob.CloneError: TJSONObject;
begin
  FLock.Enter;
  try
    if FErrorObj = nil then
      Result := nil
    else
      Result := FErrorObj.Clone as TJSONObject;
  finally
    FLock.Leave;
  end;
end;

procedure TJob.SetError(const ACode, AMessage, ADetail: string);
begin
  FLock.Enter;
  try
    FErrorObj.Free;
    FErrorObj := MCPErrorJSON(ACode, AMessage, ADetail);
  finally
    FLock.Leave;
  end;
end;

function TJob.GetState: TJobState;
begin
  FLock.Enter;
  try
    Result := FState;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetSeed: Integer;
begin
  FLock.Enter;
  try
    Result := FSeed;
  finally
    FLock.Leave;
  end;
end;

procedure TJob.SetSeed(Value: Integer);
begin
  FLock.Enter;
  try
    FSeed := Value;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetIteration: Integer;
begin
  FLock.Enter;
  try
    Result := FIteration;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetMaxIterations: Integer;
begin
  FLock.Enter;
  try
    Result := FMaxIterations;
  finally
    FLock.Leave;
  end;
end;

procedure TJob.SetMaxIterations(Value: Integer);
begin
  FLock.Enter;
  try
    FMaxIterations := Value;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetBestValue: Double;
begin
  FLock.Enter;
  try
    Result := FBestValue;
  finally
    FLock.Leave;
  end;
end;

procedure TJob.SetBestValue(Value: Double);
begin
  FLock.Enter;
  try
    FBestValue := Value;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetLastMessage: string;
begin
  FLock.Enter;
  try
    Result := FLastMessage;
  finally
    FLock.Leave;
  end;
end;

procedure TJob.SetLastMessage(const Value: string);
begin
  FLock.Enter;
  try
    FLastMessage := Value;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetCancelRequested: Boolean;
begin
  // CompareExchange(Target, 0, 0) writes nothing and returns the current value:
  // an atomic read of a field another thread may be writing.
  Result := TInterlocked.CompareExchange(FCancelFlag, 0, 0) <> 0;
end;

procedure TJob.SetCancelRequested(Value: Boolean);
begin
  if Value then
    TInterlocked.Exchange(FCancelFlag, 1)
  else
    TInterlocked.Exchange(FCancelFlag, 0);
end;

procedure TJob.SetResultObj(Value: TJSONObject);
begin
  FLock.Enter;
  try
    if Value <> FResultObj then
    begin
      FResultObj.Free;
      FResultObj := Value;
    end;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetElapsedMs: Int64;
begin
  FLock.Enter;
  try
    Result := FStopwatch.ElapsedMilliseconds;
  finally
    FLock.Leave;
  end;
end;

function TJob.GetHasResult: Boolean;
begin
  FLock.Enter;
  try
    Result := FResultObj <> nil;
  finally
    FLock.Leave;
  end;
end;

{ ----------------------------------------------------------- the worker -- }

type
  TJobWorker = class(TThread)
  private
    FManager: TJobManager;
  protected
    procedure Execute; override;
  public
    constructor Create(AManager: TJobManager);
  end;

constructor TJobWorker.Create(AManager: TJobManager);
begin
  FManager := AManager;
  FreeOnTerminate := False;
  inherited Create(False);
end;

procedure TJobWorker.Execute;
var
  Job: TJob;
begin
  NameThreadForDebugging('XRC_MCP jobs');
  while not Terminated do
  begin
    Job := FManager.TakeNext;
    if Job = nil then
    begin
      // A timed wait rather than an infinite one: the event is signalled by
      // both Submit and the destructor, and a bounded wait means a missed
      // signal costs a quarter of a second, not a hung shutdown.
      FManager.FWake.WaitFor(250);
      Continue;
    end;
    FManager.RunJob(Job);
  end;
end;

{ ----------------------------------------------------------- TJobManager -- }

constructor TJobManager.Create(AWorkDir: TWorkDir);
begin
  inherited Create;
  FWorkDir := AWorkDir;
  FLock := TCriticalSection.Create;
  FWake := TEvent.Create(nil, False, False, '');   // auto-reset, initially clear
  FJobs := TObjectDictionary<string, TJob>.Create([doOwnsValues]);
  FQueue := TQueue<TJob>.Create;
  FWorker := TJobWorker.Create(Self);              // last: everything it uses exists
end;

destructor TJobManager.Destroy;
begin
  if FLock <> nil then
  begin
    FLock.Enter;
    try
      FTerminating := True;
      if FRunning <> nil then
        FRunning.CancelRequested := True;   // ask the body to stop
    finally
      FLock.Leave;
    end;
  end;
  if FWorker <> nil then
  begin
    FWorker.Terminate;
    if FWake <> nil then
      FWake.SetEvent;
    FWorker.WaitFor;          // the running body finishes before we free anything
    FWorker.Free;
    FWorker := nil;
  end;
  FQueue.Free;
  FJobs.Free;                 // owns the jobs
  FWake.Free;
  FLock.Free;
  inherited Destroy;
end;

function TJobManager.UnknownStatus(const Id: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('job_id', Id);
    Result.AddPair('state', 'unknown');
  except
    Result.Free;
    raise;
  end;
end;

function TJobManager.Submit(Kind: TJobKind; Seed: Integer; const Body: TJobBody;
  const Request: TJSONObject): TJob;
var
  Id, Dir: string;
  Job: TJob;
begin
  if not Assigned(Body) then
    raise EMCPError.Create('internal', 'Job submitted without a body');

  { The whole submission is one critical section: the queue check and the
    enqueue have to be atomic or two clients could each see fifteen queued jobs
    and both add one. Creating the folder and writing request.json inside it
    costs a millisecond and only ever competes with status polls. }
  FLock.Enter;
  try
    if FTerminating then
      raise EMCPError.Create('server_stopping', 'The server is shutting down');
    if FQueue.Count >= MAX_QUEUED_JOBS then
      raise EMCPError.Create('too_many_jobs',
        Format('At most %d jobs may be queued; wait for one to finish or cancel one',
          [MAX_QUEUED_JOBS]), Format('queued=%d', [FQueue.Count]));

    Dir := NewJobFolder(FWorkDir, JobKindPrefix(Kind), Id);
    Job := TJob.Create(Id, Kind, Dir);
    try
      Job.FSeed := Seed;
      Job.FBody := Body;
      WriteJSONFile(TPath.Combine(Dir, 'request.json'), Request);
      FJobs.Add(Id, Job);       // the dictionary owns it from here on
    except
      Job.Free;
      raise;
    end;
    Job.SaveJobFile;
    FQueue.Enqueue(Job);
    Result := Job;
  finally
    FLock.Leave;
  end;
  FWake.SetEvent;
end;

function TJobManager.Find(const Id: string): TJob;
begin
  FLock.Enter;
  try
    if not FJobs.TryGetValue(Id, Result) then
      Result := nil;
  finally
    FLock.Leave;
  end;
end;

function TJobManager.QueuedCount: Integer;
begin
  FLock.Enter;
  try
    Result := FQueue.Count;
  finally
    FLock.Leave;
  end;
end;

function TJobManager.TakeNext: TJob;
var
  Job: TJob;
begin
  Result := nil;
  FLock.Enter;
  try
    if FTerminating or (FQueue.Count = 0) then
      Exit;
    Job := FQueue.Dequeue;
    FRunning := Job;
  finally
    FLock.Leave;
  end;

  Job.FLock.Enter;
  try
    Job.FState := jsRunning;
    Job.FStartedUTC := NowUTCString;
    Job.FStopwatch := TStopwatch.StartNew;
    Job.SaveLocked;
  finally
    Job.FLock.Leave;
  end;
  Result := Job;
end;

procedure TJobManager.RunJob(Job: TJob);
var
  Status: TJSONObject;
  Final: TJobState;
begin
  Final := jsFailed;
  try
    try
      Job.FBody(Job);   // FBody, not the property: a property of a method
                        // reference type cannot be invoked with arguments
      if Job.CancelRequested then
        Final := jsCancelled
      else
        Final := jsFinished;
    except
      on E: EMCPError do
      begin
        Job.SetError(E.Code, E.Message, E.Detail);
        Final := jsFailed;
      end;
      on E: Exception do
      begin
        Job.SetError('internal', E.Message, E.ClassName);
        Final := jsFailed;
      end;
    end;
  finally
    { The final state, the finish time and the last job.json write all happen
      together under the job's lock, so no poller can see a finished job whose
      elapsed time is still ticking. }
    Job.FLock.Enter;
    try
      Job.FState := Final;
      Job.FStopwatch.Stop;
      Job.FFinishedUTC := NowUTCString;
      Job.SaveLocked;
      Status := Job.StatusJSONLocked;
    finally
      Job.FLock.Leave;
    end;

    FLock.Enter;
    try
      FRunning := nil;
    finally
      FLock.Leave;
    end;

    try
      if Journal <> nil then
        Journal.LogEvent('job', Status);
    finally
      Status.Free;
    end;
  end;
end;

function TJobManager.Status(const Id: string): TJSONObject;
var
  Job: TJob;
begin
  FLock.Enter;
  try
    if not FJobs.TryGetValue(Id, Job) then
      Exit(UnknownStatus(Id));
    Result := Job.StatusJSON;
  finally
    FLock.Leave;
  end;
end;

function TJobManager.ResultOf(const Id: string): TJSONObject;
var
  Job: TJob;
  St: TJobState;
  Status, Err: TJSONObject;
  Detail, Msg: string;
begin
  FLock.Enter;
  try
    if not FJobs.TryGetValue(Id, Job) then
      raise EMCPError.Create('job_unknown',
        Format('No job "%s" on this server. The job registry is in memory only, ' +
          'so every id from before a restart is unknown.', [Id]), Id);

    St := Job.State;
    case St of
      jsFinished:
        begin
          Result := Job.CloneResult;
          if Result = nil then
            raise EMCPError.Create('internal',
              Format('Job %s finished without a result', [Id]), Id);
        end;

      jsFailed:
        begin
          Err := Job.CloneError;
          try
            if Err = nil then
              Detail := ''
            else
              Detail := Err.ToJSON;
            if (Err <> nil) and (Err.FindValue('message') <> nil) then
              Msg := Err.GetValue<string>('message')
            else
              Msg := 'the job failed';
          finally
            Err.Free;
          end;
          raise EMCPError.Create('job_failed',
            Format('Job %s failed: %s', [Id, Msg]), Detail);
        end;

      jsCancelled:
        begin
          Status := Job.StatusJSON;
          try
            Detail := Status.ToJSON;
          finally
            Status.Free;
          end;
          Msg := Format('Job %s was cancelled and has no result.', [Id]);
          if Job.HasResult then
            Msg := Msg + ' A partial result is in job.json under "partial".';
          raise EMCPError.Create('job_cancelled', Msg, Detail);
        end;

    else    // jsQueued, jsRunning
      Status := Job.StatusJSON;
      try
        Detail := Status.ToJSON;
      finally
        Status.Free;
      end;
      raise EMCPError.Create('job_not_finished',
        Format('Job %s is %s; poll job_status until it is finished',
          [Id, JobStateName(St)]), Detail);
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TJobManager.RemoveFromQueueLocked(Job: TJob);
var
  Kept: TArray<TJob>;
  I, N: Integer;
  Item: TJob;
begin
  N := FQueue.Count;
  if N = 0 then
    Exit;
  SetLength(Kept, 0);
  for I := 1 to N do
  begin
    Item := FQueue.Dequeue;
    if Item <> Job then
    begin
      SetLength(Kept, Length(Kept) + 1);
      Kept[High(Kept)] := Item;
    end;
  end;
  for I := 0 to High(Kept) do
    FQueue.Enqueue(Kept[I]);      // FIFO order is preserved
end;

function TJobManager.Cancel(const Id: string): TJSONObject;
var
  Job: TJob;
  Ended: Boolean;
begin
  Ended := False;
  FLock.Enter;
  try
    if not FJobs.TryGetValue(Id, Job) then
      Exit(UnknownStatus(Id));

    Job.CancelRequested := True;
    if Job.State = jsQueued then
    begin
      { It has not started, so there is no body to notice the flag: take it out
        of the queue and end it here. }
      RemoveFromQueueLocked(Job);
      Ended := True;
      Job.FLock.Enter;
      try
        Job.FState := jsCancelled;
        Job.FFinishedUTC := NowUTCString;
        Job.SaveLocked;
        Result := Job.StatusJSONLocked;
      finally
        Job.FLock.Leave;
      end;
    end
    else
      { Running: it stays running until the body notices. Finished, failed or
        already cancelled: unchanged. Either way the caller gets the state as
        it is now. }
      Result := Job.StatusJSON;
  finally
    FLock.Leave;
  end;

  if Ended and (Journal <> nil) then
    Journal.LogEvent('job', Result);
end;

end.
