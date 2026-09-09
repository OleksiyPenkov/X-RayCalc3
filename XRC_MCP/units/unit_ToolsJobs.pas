unit unit_ToolsJobs;

(* The job tools: optimize_mirror, which submits one, and job_status,
   job_result and cancel_job, which drive every job whatever submitted it.

   A submitting tool returns a job id and nothing else; the client then polls it
   here. Keeping the polling tools next to the submission means the contract
   they share (what a state name means, what happens to an id the server has
   never seen, where the files land) is written down in one place.

   An unknown id is deliberately *not* an error for job_status and cancel_job:
   the registry is in memory, so every id from before a restart is unknown, and
   an agent that polls one should be told the state plainly rather than have a
   failed call to interpret. job_result is the exception - there the client is
   asking for data that does not exist, and an error is the honest answer.

   optimize_mirror validates its whole configuration synchronously - a
   configuration that cannot be read is an error on the submitting call, not a
   job that fails a minute later - and hands the parsed record to the body. The
   body itself is RunOptimizeJob in unit_MCPUniversal, where the engine lives. *)

interface

uses unit_MCPTools;

procedure RegisterJobTools(Registry: TToolRegistry);

implementation

uses
  System.SysUtils, System.JSON,
  unit_universal_types,
  unit_MCPErrors, unit_MCPJobs, unit_MCPUniversal;

function JobIdSchema: TJSONObject;
begin
  Result := SchemaObject(['job_id']);
  AddProp(Result, 'job_id', 'string',
    'The id returned when the job was submitted, for example ' +
    '"opt-20260909-142530-3f1c". It is also the name of the folder under ' +
    'jobs\ that holds the job''s files.');
end;

{ ------------------------------------------------------- optimize_mirror -- }

{ AddRefProp fills in the description, so nothing here adds one: two
  "description" keys in the same schema object is not a schema. }
function RangeSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'min', 'number', 'Lower bound of the search range.');
  AddProp(Result, 'max', 'number', 'Upper bound of the search range.');
end;

function StringItemSchema: TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('type', 'string');
end;

/// One item of "lines": the full object or a bare element symbol, exactly as
/// evaluate_lines accepts it.
function OptimizeLineSchema: TJSONObject;
var
  Obj, Str: TJSONObject;
  Arr: TJSONArray;
begin
  Obj := SchemaObject(['name']);
  AddProp(Obj, 'name', 'string',
    'Name of the line, normally the element symbol ("B", "Si"). With no ' +
    '"lambda" or "energy" the wavelength comes from the XRF line table.');
  AddProp(Obj, 'lambda', 'number', 'Wavelength of the line in Angstrom.');
  AddProp(Obj, 'energy', 'number', 'Photon energy of the line in eV.');
  AddProp(Obj, 'weight', 'number',
    'Relative weight of this line in the figure of merit (default 1).');

  Str := TJSONObject.Create;
  Str.AddPair('type', 'string');
  Str.AddPair('description',
    'An element symbol ("Si") or a symbol range ("Be-Si"), whose ' +
    'characteristic wavelength comes from the XRF line table. Weight 1.');

  Arr := TJSONArray.Create;
  Arr.AddElement(Obj);
  Arr.AddElement(Str);
  Result := TJSONObject.Create;
  Result.AddPair('oneOf', Arr);
end;

function OptimizeStructureSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'type', 'string',
    'Period type; "bilayer" is the only one in v1 (default).');
  AddProp(Result, 'pure_elements', 'boolean',
    'Must be true (the default). With mixed compositions the genome cannot be ' +
    'written back as a structure, so a reported candidate could not reproduce ' +
    'its own figure of merit; false is refused.');
  AddRefProp(Result, 'd',
    'Period thickness in Angstrom (default 30 to 80).', RangeSchema);
  AddRefProp(Result, 'gamma',
    'Fraction of the period taken by the first (reflector) layer, 0 to 1 ' +
    '(default 0.15 to 0.70).', RangeSchema);
  AddRefProp(Result, 'N',
    'Number of repetitions of the period (default 40 to 200).', RangeSchema);
  AddProp(Result, 'sigma', 'number',
    'Interface roughness in Angstrom, held fixed (default 3). Give an object ' +
    'with min and max instead to fit it.');
  AddProp(Result, 'density_factor', 'number',
    'Multiplier on the bulk density of every layer, held fixed (default 1). ' +
    'Give an object with min and max instead to fit it.');
end;

function OptimizeFitnessSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'w_R', 'number',
    'Weight of the peak reflectivity in the figure of merit (default 1).');
  AddProp(Result, 'w_FWHM', 'number',
    'Weight of the FWHM penalty, in units of the kinematic reference width ' +
    '(default 0.5).');
  AddProp(Result, 'R_min_threshold', 'number',
    'A line whose peak reflectivity falls below this is penalised as dark ' +
    '(default 0.001).');
  AddProp(Result, 'w_purity', 'number',
    'Weight of the spectral purity correction, 0 turns it off (default 1).');
  AddEnumProp(Result, 'polarization',
    'Polarization of the incident beam (default "sp"). The engine has no pure-p ' +
    'path, so "p" is computed as "sp".', ['s', 'p', 'sp']);
  AddProp(Result, 'delta_theta', 'number',
    'Beam divergence, the FWHM in degrees of the Gaussian each scan is ' +
    'convolved with (default 0 = no convolution).');
  AddProp(Result, 'theta_min', 'number',
    'Dark-zone threshold in degrees theta (default 0): a line whose Bragg angle ' +
    'falls below it is penalised. This is NOT where a scan starts.');
  AddProp(Result, 'scan_points', 'integer',
    'Points in the reflectivity scan around each Bragg angle (default 200, ' +
    'maximum 20000). Every particle of every iteration is scanned this finely, ' +
    'so this is the single biggest lever on how long a run takes.');
  AddProp(Result, 'scan_half_range', 'number',
    'Half-width in degrees of the scan around each Bragg angle (default 5, ' +
    'maximum 90).');
end;

function OptimizeOptimizerSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'population', 'integer',
    'Particles in the swarm (default 1000). Cost per iteration is linear in it.');
  AddProp(Result, 'iterations', 'integer',
    'Iteration budget (default 100). The run also stops early when the swarm ' +
    'has jammed.');
  AddProp(Result, 'tolerance', 'number', 'Convergence tolerance (default 1e-6).');
  AddProp(Result, 'stagnation_limit', 'integer',
    'Stop when this many particles are jammed on the same solution (default 200).');
  AddProp(Result, 'w1', 'number', 'Lower end of the PSO inertia weight (default 0.4).');
  AddProp(Result, 'w2', 'number', 'Upper end of the PSO inertia weight (default 0.5).');
  AddProp(Result, 'jamming_max', 'integer',
    'Length in iterations of the window the shake test looks back over (default 30).');
  AddProp(Result, 'checkpoint_every', 'integer',
    'Iterations between checkpoint writes (default 100).');
end;

function OptimizeConfigSchema: TJSONObject;
begin
  Result := SchemaObject(['lines', 'element_pool', 'substrate']);
  AddRefProp(Result, 'lines',
    'The emission lines the mirror is meant to serve, at most 16. Wavelengths ' +
    'are Angstrom, energies eV.',
    ArraySchema(OptimizeLineSchema));
  AddRefProp(Result, 'element_pool',
    'The materials the two layers of a period may be made of, as Henke table ' +
    'names ("W", "Mo", "B4C", "Sc"). The optimizer picks one for each role.',
    ArraySchema(StringItemSchema));
  AddProp(Result, 'substrate', 'string',
    'Henke table name of the substrate material, for example "Si".');
  AddRefProp(Result, 'excluded_pairs',
    'Material pairs the optimizer must not propose, each as "W/Si".',
    ArraySchema(StringItemSchema));
  AddRefProp(Result, 'structure',
    'The search space of the period. Every key is optional.',
    OptimizeStructureSchema);
  AddRefProp(Result, 'fitness',
    'The figure of merit. Every key is optional and defaults to the value ' +
    'evaluate_lines uses, so the two agree by construction.',
    OptimizeFitnessSchema);
  AddRefProp(Result, 'optimizer',
    'The particle swarm itself. Every key is optional.',
    OptimizeOptimizerSchema);
  AddProp(Result, 'template_file', 'string',
    'Template library to run against, relative to the working directory. The ' +
    '"template_file" tool argument takes precedence; with neither, the library ' +
    'the server was started with is used.');
end;

/// Submits one optimisation. The configuration is parsed and validated here so
/// that a client learns about a bad argument on this call rather than from a
/// job that fails a minute later; the record it produces is captured by the
/// body.
function SubmitOptimize(const Params: TJSONObject): TJSONObject;
var
  Work, Request: TJSONObject;
  Config: TUniversalConfig;
  Seed, TopK: Integer;
  G: TGUID;
  Job: TJob;
begin
  if Jobs = nil then
    raise EMCPError.Create('internal', 'The job manager is not running');

  TopK := JSONArgs.OptInt(Params, 'top_k', DEFAULT_TOP_K);
  if (TopK < 1) or (TopK > MAX_TOP_K) then
    raise EMCPError.Create('invalid_argument',
      Format('"top_k" must be between 1 and %d', [MAX_TOP_K]), IntToStr(TopK));

  Work := JSONArgs.ReqObj(Params, 'config').Clone as TJSONObject;
  try
    { The tool argument wins over the same key inside the configuration: it is
      the one a client reaches for, and having two spellings disagree silently
      would be worse than either. }
    if JSONArgs.Has(Params, 'template_file') then
    begin
      if Work.FindValue('template_file') <> nil then
        Work.RemovePair('template_file').Free;
      Work.AddPair('template_file', JSONArgs.ReqStr(Params, 'template_file'));
    end;
    { The output directory is the job folder, which Submit has not created yet;
      RunOptimizeJob sets it before the run. }
    Config := ConfigFromJSON(Work, '');
  finally
    Work.Free;
  end;

  if JSONArgs.Has(Params, 'seed') then
    Seed := JSONArgs.OptInt(Params, 'seed', 0)
  else
  begin
    { From a GUID, not from Randomize/Random: those write System.RandSeed, which
      is process-global and is exactly what a job running at this moment is
      drawing from - a seed drawn here would make that job's answer
      irreproducible. NewJobFolder picks job ids the same way and for the same
      reason. The sign bit is masked off so the seed reads as a positive number
      in job.json. }
    G := TGUID.NewGuid;
    Seed := Integer((G.D1 xor (Cardinal(G.D2) shl 16) xor Cardinal(G.D3))
                    and $7FFFFFFF);
  end;

  { request.json records the arguments as they arrived, with the seed and top_k
    the server resolved, so a run can be repeated from the file alone. }
  Request := Params.Clone as TJSONObject;
  try
    if Request.FindValue('seed') <> nil then
      Request.RemovePair('seed').Free;
    Request.AddPair('seed', TJSONNumber.Create(Seed));
    if Request.FindValue('top_k') <> nil then
      Request.RemovePair('top_k').Free;
    Request.AddPair('top_k', TJSONNumber.Create(TopK));

    Job := Jobs.Submit(jkOptimize, Seed,
      procedure(AJob: TJob)
      begin
        RunOptimizeJob(AJob, Config, TopK);
      end,
      Request);
  finally
    Request.Free;
  end;

  Result := Job.StatusJSON;
end;

procedure RegisterOptimizeTool(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Schema := SchemaObject(['config']);
  AddRefProp(Schema, 'config',
    'The mirror design problem: which lines the multilayer must serve, which ' +
    'materials it may be made of, and how wide the search is. Lengths are ' +
    'Angstrom, angles theta in degrees, energies eV, densities g/cm^3.',
    OptimizeConfigSchema);
  AddProp(Schema, 'seed', 'integer',
    'Random seed. Two runs of the same configuration with the same seed give ' +
    'the same answer to the last digit. Omit it and the server draws one and ' +
    'reports it, so a run can always be repeated.');
  AddProp(Schema, 'top_k', 'integer',
    Format('How many distinct candidates to report, 1 to %d (default %d). ' +
      'Fewer come back when the swarm has fewer genuinely different ones.',
      [MAX_TOP_K, DEFAULT_TOP_K]));
  AddProp(Schema, 'template_file', 'string',
    'Template library to run against, as a path relative to the working ' +
    'directory. Omit it to use the library the server was started with. A ' +
    'template turns a material pair into a fixed sub-layer recipe (interlayers, ' +
    'a capping layer), so it changes what the optimizer is allowed to build.');

  Registry.Register('optimize_mirror',
    'Searches for the periodic multilayer that best serves a set of X-ray ' +
    'emission lines, with the XRFCalc particle swarm. This is a long-running ' +
    'job: the call returns a job_id at once, job_status reports the iteration ' +
    'and the best figure of merit as it goes, cancel_job stops it and ' +
    'job_result returns the answer. The result holds the winner and up to ' +
    'top_k genuinely different alternatives, each with its genome, its ' +
    'structure, the Bragg angle, peak reflectivity and FWHM of every line, and ' +
    'a rank_<n>.xrfx package that XRFCalc opens; the figure of merit is the one ' +
    'evaluate_lines computes, so a candidate can be re-scored and compared ' +
    'against a design of your own. The seed is echoed and a repeat of the same ' +
    'configuration with the same seed is bit-for-bit reproducible. One job runs ' +
    'at a time, and evaluate_lines waits while one does: both drive the same ' +
    'engine, which changes the process working directory while it reads its ' +
    'tables. Cancellation is not instant - the optimizer offers one point per ' +
    'iteration at which it can be stopped, and neither its prologue (reading ' +
    'the tables and evaluating the whole population once) nor the results it ' +
    'saves after stopping can be interrupted - so cancel_job takes up to one ' +
    'iteration plus that tail, which grows with population x lines x scan ' +
    'points. Keep the population modest if you want to be able to change your ' +
    'mind quickly. Angles are theta in degrees, never 2theta; lengths are Angstrom.',
    Schema,
    function(const P: TJSONObject): TJSONObject
    begin
      Result := SubmitOptimize(P);
    end);
end;

{ ------------------------------------------------------------ the polling -- }

procedure RegisterJobTools(Registry: TToolRegistry);
begin
  RegisterOptimizeTool(Registry);

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
