unit unit_ToolsJobs;

(* The three tools every long-running job is driven with: job_status,
   job_result and cancel_job.

   The submitting tools - optimize_mirror and fit_xrr - live in their own units;
   what they have in common is that they return a job id and nothing else, and
   that the client then polls it here. Keeping the polling tools together means
   the contract they share (what a state name means, what happens to an id the
   server has never seen) is written down in one place.

   An unknown id is deliberately *not* an error for job_status and cancel_job:
   the registry is in memory, so every id from before a restart is unknown, and
   an agent that polls one should be told the state plainly rather than have a
   failed call to interpret. job_result is the exception - there the client is
   asking for data that does not exist, and an error is the honest answer. *)

interface

uses unit_MCPTools;

procedure RegisterJobTools(Registry: TToolRegistry);

implementation

uses
  System.JSON, unit_MCPErrors, unit_MCPJobs;

function JobIdSchema: TJSONObject;
begin
  Result := SchemaObject(['job_id']);
  AddProp(Result, 'job_id', 'string',
    'The id returned when the job was submitted, for example ' +
    '"opt-20260909-142530-3f1c". It is also the name of the folder under ' +
    'jobs\ that holds the job''s files.');
end;

procedure RegisterJobTools(Registry: TToolRegistry);
begin
  Registry.Register('job_status',
    'Reports the state of a submitted job without waiting for it. The state is ' +
    'one of "queued", "running", "finished", "failed", "cancelled" and ' +
    '"unknown", together with the current iteration and the iteration budget, ' +
    'the best value so far (the figure of merit for an optimisation, chi-squared ' +
    'for a fit), the elapsed seconds, the last progress message and the random ' +
    'seed the job runs with. Poll this until the state is "finished" and then ' +
    'call job_result. The job registry lives in memory only, so an id from ' +
    'before a server restart comes back as "unknown" rather than as an error.',
    JobIdSchema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := Jobs.Status(JSONArgs.ReqStr(Params, 'job_id'));
    end);

  Registry.Register('job_result',
    'Returns the result of a finished job. Fails with "job_not_finished" while ' +
    'the job is still queued or running (the current status is in the error ' +
    'detail), with "job_failed" when it ended in an error (the original error ' +
    'code and message are in the detail), with "job_cancelled" when it was ' +
    'cancelled, and with "job_unknown" for an id this server does not know. The ' +
    'result is the same object every time it is asked for; the files it names ' +
    'stay under jobs\<job_id>\ for as long as the working directory does.',
    JobIdSchema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := Jobs.ResultOf(JSONArgs.ReqStr(Params, 'job_id'));
    end);

  Registry.Register('cancel_job',
    'Asks a job to stop and returns its state. A job that has not started yet ' +
    'is cancelled immediately; a running one is asked to stop and usually does ' +
    'so within a second or two, so the state reported here may still be ' +
    '"running" - poll job_status to see it become "cancelled". A job that has ' +
    'already finished, failed or been cancelled is left as it is, and an unknown ' +
    'id reports "unknown". Cancelling never deletes anything: whatever the job ' +
    'wrote under jobs\<job_id>\ stays there.',
    JobIdSchema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := Jobs.Cancel(JSONArgs.ReqStr(Params, 'job_id'));
    end);
end;

end.
