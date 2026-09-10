unit unit_ToolsJobs;

(* The job tools: optimize_mirror and fit_xrr, which submit one, and
   job_status, job_result and cancel_job, which drive every job whatever
   submitted it.

   A submitting tool returns a job id and nothing else; the client then polls it
   here. Keeping the polling tools next to the submission means the contract
   they share (what a state name means, what happens to an id the server has
   never seen, where the files land) is written down in one place.

   An unknown id is deliberately *not* an error for job_status and cancel_job:
   the registry is in memory, so every id from before a restart is unknown, and
   an agent that polls one should be told the state plainly rather than have a
   failed call to interpret. job_result is the exception - there the client is
   asking for data that does not exist, and an error is the honest answer.

   Both submitting tools validate their whole request synchronously - an
   argument that cannot be read is an error on the submitting call, not a job
   that fails a minute later - and hand the parsed record to the body. The
   bodies themselves live next to their engines: RunOptimizeJob in
   unit_MCPUniversal, RunFitJob in unit_MCPFit. *)

interface

uses unit_MCPTools;

procedure RegisterJobTools(Registry: TToolRegistry);

implementation

uses
  System.SysUtils, System.JSON,
  unit_universal_types,
  unit_MCPErrors, unit_MCPJobs, unit_MCPUniversal, unit_MCPFit;

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
  begin
    Seed := JSONArgs.OptInt(Params, 'seed', 0);
    if Seed < 0 then
      raise EMCPError.Create('invalid_argument', '"seed" must not be negative',
        IntToStr(Seed));
  end
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
    'against a design of your own. The shared results\ folder on disk (progress ' +
    'log, checkpoint, population) always describes rank 1, the winner; each ' +
    'rank_<n>.xrfx package, though, is a self-contained zip snapshot taken at the ' +
    'moment it was written and does not change afterwards. The seed is echoed ' +
    'and a repeat of the same configuration with the same seed is bit-for-bit ' +
    'reproducible. One job runs at a time, and evaluate_lines is refused with ' +
    'server_busy while one does: both drive the same engine, which changes the ' +
    'process working directory while it reads its tables. Cancellation is not ' +
    'instant - the optimizer offers one point per ' +
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

{ ---------------------------------------------------------------- fit_xrr -- }

function FitCurveItemSchema: TJSONObject;
var
  Num: TJSONObject;
begin
  Num := TJSONObject.Create;
  Num.AddPair('type', 'number');
  Result := ArraySchema(Num);
  Result.AddPair('minItems', TJSONNumber.Create(2));
  Result.AddPair('maxItems', TJSONNumber.Create(2));
end;

function FitThetaRangeSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'min', 'number',
    'Lowest theta in degrees to fit (default: the first measured point).');
  AddProp(Result, 'max', 'number',
    'Highest theta in degrees to fit (default: the last measured point).');
end;

function FitFreeItemSchema: TJSONObject;
var
  Names: TJSONObject;
begin
  Result := SchemaObject([]);
  AddEnumProp(Result, 'target',
    'What the entry addresses (default "layer"). "layer" frees the listed ' +
    'parameters of one layer. "period" frees the period of a repeating stack ' +
    '(its index in "stacks"; no "layer" or "parameters"): the engine then ' +
    'lets the sum of that stack''s thicknesses move inside the period bounds ' +
    'instead of rescaling the layers back to the start period after every ' +
    'move - at least one thickness of the stack must be free as well. The ' +
    'other targets are listed so that asking for them is answered with ' +
    '"not_fittable" rather than silently ignored.',
    ['layer', 'period', 'substrate', 'scale', 'background', 'resolution']);
  AddProp(Result, 'stack', 'integer',
    'Index in "stacks", counted from the substrate up; or the string "cap" or ' +
    '"buffer" to address those layers ("period" takes an index only).');
  AddProp(Result, 'layer', 'integer',
    'Index of the layer inside that stack, in the order "layers" lists them. ' +
    'Optional (and 0) for "cap" and "buffer"; not used with "period".');

  Names := TJSONObject.Create;
  Names.AddPair('type', 'string');
  AddRefProp(Result, 'parameters',
    'Which of "thickness", "sigma" and "density" of that layer take part in ' +
    'the fit (required for "layer"). Freeing the thicknesses of a repeating ' +
    'stack without freeing its period fits the ratio between them at a fixed ' +
    'period.', ArraySchema(Names));
end;

function FitBoundItemSchema: TJSONObject;
begin
  Result := SchemaObject(['min', 'max']);
  AddEnumProp(Result, 'target',
    '"layer" (default) bounds one layer parameter; "period" bounds the period ' +
    'of a repeating stack whose period is in "free" (Angstrom, "parameter" ' +
    'optional). Anything else is refused with "not_fittable".',
    ['layer', 'period', 'substrate', 'scale', 'background', 'resolution']);
  AddProp(Result, 'stack', 'integer',
    'Index in "stacks" from the substrate up, or "cap" or "buffer".');
  AddProp(Result, 'layer', 'integer', 'Index of the layer inside that stack.');
  AddEnumProp(Result, 'parameter',
    'The parameter this bound applies to (required for "layer"). It must be ' +
    'one the same layer lists in "free": a bound on a fixed parameter would ' +
    'have no effect and is an error.',
    ['thickness', 'sigma', 'density', 'period']);
  AddProp(Result, 'min', 'number',
    'Lower end of the search range, in Angstrom or g/cm^3. A thickness or ' +
    'period bound must be greater than zero; a sigma or density bound is ' +
    'clamped at zero. The start value must lie inside the range.');
  AddProp(Result, 'max', 'number', 'Upper end of the search range.');
end;

function FitOptimizerSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'population', 'integer',
    Format('Particles in the swarm (default %d). Cost per iteration is linear ' +
      'in it, and so is how long a cancel takes.', [DEF_POPULATION]));
  AddProp(Result, 'iterations', 'integer',
    Format('Iteration budget (default %d). The run also stops early when the ' +
      'chi-squared falls below "tolerance".', [DEF_ITERATIONS]));
  AddProp(Result, 'tolerance', 'number',
    Format('Stop as soon as the chi-squared is below this (default %g).',
      [DEF_TOLERANCE]));
  AddProp(Result, 'shake', 'boolean',
    'Re-seed the swarm when it jams (default true).');
  AddProp(Result, 'range_seed', 'boolean',
    'Draw the whole starting swarm uniformly from the bounds (default true). ' +
    'False keeps the start model as particle 0 and scatters the rest around it.');
  AddProp(Result, 'jamming_max', 'integer',
    Format('Iterations without improvement before the shake test fires (default %d).',
      [DEF_JAMMING_MAX]));
  AddProp(Result, 'reinit_max', 'integer',
    Format('Shakes before the swarm is put back on the all-time best (default %d).',
      [DEF_REINIT_MAX]));
  AddProp(Result, 'k_chi', 'number',
    Format('Factor the global best chi-squared is relaxed by on a shake (default %g).',
      [DEF_K_CHI]));
  AddProp(Result, 'k_vmax', 'number',
    Format('Factor the velocity limit and the seed spread grow by on a shake ' +
      '(default %g).', [DEF_K_VMAX]));
  AddProp(Result, 'w1', 'number',
    Format('Lower end of the PSO inertia weight (default %g); ignored while ' +
      '"use_constriction" is true.', [DEF_W1]));
  AddProp(Result, 'w2', 'number',
    Format('Span of the PSO inertia weight above w1 (default %g).', [DEF_W2]));
  AddProp(Result, 'vmax', 'number',
    Format('Velocity limit as a fraction of each parameter''s range (default %g).',
      [DEF_VMAX]));
  AddProp(Result, 'adapt_velocity', 'boolean',
    'Shrink the acceleration factors over the run (default false).');
  AddProp(Result, 'use_constriction', 'boolean',
    'Use the Clerc-Kennedy constriction factor instead of the inertia weight ' +
    '(default true).');
  AddProp(Result, 'ksxr', 'number',
    Format('Spread of the swarm around the start model, as a fraction of each ' +
      'range (default %g). Only used when "range_seed" is false.', [DEF_KSXR]));
  AddProp(Result, 'poly_factor', 'integer',
    Format('Divisor applied to the range of each successive polynomial ' +
      'coefficient in a "profile" fit (default %d).', [DEF_POLY_FACTOR]));
  AddProp(Result, 'poly_order', 'integer',
    Format('Order of the per-period polynomial in a "profile" fit (default %d).',
      [DEF_POLY_ORDER]));
end;

function FitChi2Schema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'theta_weight', 'integer',
    'Angular weight of the chi-squared, 0 to 5 as in the GUI (default 0 = ' +
    'none). 1 weights by theta^2, 2 by theta, 3 by sqrt(theta), 4 by ' +
    '1/theta^2, 5 by 1/sqrt(theta).');
  AddProp(Result, 'point_weight', 'boolean',
    'Weight a point up when its intensity stands more than three times above ' +
    'the moving average, so that Bragg peaks count for more than the ' +
    'background (default true).');
  AddProp(Result, 'movavg_window', 'number',
    Format('Window of that moving average, as a fraction of the number of ' +
      'points (default %g).', [DEF_MOVAVG]));
end;

/// Submits one fit. The whole request is parsed and validated here - the
/// measurement is read, the structure is built and the bounds are resolved - so
/// that a client learns about a bad argument on this call rather than from a
/// job that fails a minute later.
function SubmitFit(const Params: TJSONObject): TJSONObject;
var
  Req: TFitRequest;
  Request: TJSONObject;
  Seed: Integer;
  G: TGUID;
  Job: TJob;
begin
  if Jobs = nil then
    raise EMCPError.Create('internal', 'The job manager is not running');

  Req := ParseFitRequest(Params);

  if JSONArgs.Has(Params, 'seed') then
  begin
    Seed := JSONArgs.OptInt(Params, 'seed', 0);
    if Seed < 0 then
      raise EMCPError.Create('invalid_argument', '"seed" must not be negative',
        IntToStr(Seed));
  end
  else
  begin
    { From a GUID, not from Randomize/Random: those write System.RandSeed, which
      is process-global and is exactly what a job running at this moment is
      drawing from. SubmitOptimize draws its seed the same way and for the same
      reason. }
    G := TGUID.NewGuid;
    Seed := Integer((G.D1 xor (Cardinal(G.D2) shl 16) xor Cardinal(G.D3))
                    and $7FFFFFFF);
  end;

  { request.json records the arguments as they arrived, with the seed the
    server resolved, so a run can be repeated from the file alone. }
  Request := Params.Clone as TJSONObject;
  try
    if Request.FindValue('seed') <> nil then
      Request.RemovePair('seed').Free;
    Request.AddPair('seed', TJSONNumber.Create(Seed));

    Job := Jobs.Submit(jkFit, Seed,
      procedure(AJob: TJob)
      begin
        RunFitJob(AJob, Req);
      end,
      Request);
  finally
    Request.Free;
  end;

  Result := Job.StatusJSON;
end;

procedure RegisterFitTool(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Schema := SchemaObject(['structure', 'free']);
  AddRefProp(Schema, 'structure',
    'The start model. Lengths are Angstrom, densities g/cm^3; stacks are ' +
    'listed from the substrate to the surface.', StructureSchema);
  AddProp(Schema, 'measurement_id', 'string',
    'A curve in the inbox, as "<specimen>/<file>". Give this or "curve", not ' +
    'both. The wavelength then defaults to the "lambda" in that specimen''s ' +
    'meta.json.');
  AddRefProp(Schema, 'curve',
    'The measured curve inline, as [[theta_deg, intensity], ...], ordered by ' +
    'increasing theta. Intensities must be positive: the chi-squared is ' +
    'computed on their logarithm. Requires "lambda" or "energy".',
    ArraySchema(FitCurveItemSchema));
  AddProp(Schema, 'lambda', 'number',
    'Wavelength in Angstrom. Required with "curve"; with "measurement_id" it ' +
    'overrides the meta.json value.');
  AddProp(Schema, 'energy', 'number',
    'Photon energy in eV, instead of "lambda".');
  AddRefProp(Schema, 'theta_range',
    'The part of the measured curve to fit (the wiki''s "trim"), in degrees ' +
    'theta (never 2theta). Defaults to the whole curve.', FitThetaRangeSchema);
  AddProp(Schema, 'scale', 'number',
    'Fixed multiplier applied to the measured intensities before the fit - ' +
    'the wiki''s "normalise to the total-reflection plateau" step, chosen by ' +
    'the caller (default 1). It is not fitted; the result echoes it, and ' +
    'measured.dat and fit.xrcx hold the scaled curve so that X-Ray Calc 3 ' +
    'shows the same data.');
  AddProp(Schema, 'resolution', 'number',
    Format('Instrumental resolution as the FWHM in degrees theta of the ' +
      'Gaussian the calculated curve is convolved with (default %g). It is ' +
      'held fixed - the engine cannot fit it.', [DEF_RESOLUTION]));
  AddRefProp(Schema, 'free',
    'Which layer parameters take part in the fit. Everything not listed here ' +
    'is held at its start value.', ArraySchema(FitFreeItemSchema));
  AddRefProp(Schema, 'bounds',
    Format('Search range of a free parameter or period. One with no bound ' +
      'gets the start value plus and minus %d%%; sigma and density are ' +
      'clamped at zero. A parameter that starts at 0 has no such default ' +
      'range and needs an explicit bound (an omitted density starts at the ' +
      'bulk value, not at 0). The start value must lie inside the range: the ' +
      'engine seeds the swarm around it.', [Round(DEF_FREE_DEVIATION * 100)]),
    ArraySchema(FitBoundItemSchema));
  AddRefProp(Schema, 'optimizer',
    'The particle swarm itself. Every key is optional and defaults to the ' +
    'value the GUI uses.', FitOptimizerSchema);
  AddRefProp(Schema, 'chi2',
    'How the residual is weighted. describe_server.fit.chi2 gives the formula.',
    FitChi2Schema);
  AddProp(Schema, 'profile', 'boolean',
    'Fit a polynomial profile of each parameter over the periods of the ' +
    'repeating stack (TLFPSO_Poly) instead of one value per layer (default ' +
    'false). It needs exactly one stack with N > 1, and reports the ' +
    'coefficients in "profiles" and the per-period thicknesses in ' +
    '"fitted_structure".');
  AddEnumProp(Schema, 'polarization',
    'Polarization of the incident beam (default "sp"). The engine has no ' +
    'pure-p path, so "p" is computed as "sp" and the result echoes "sp".',
    ['s', 'p', 'sp']);
  AddProp(Schema, 'seed', 'integer',
    'Random seed. Two runs of the same request with the same seed give the ' +
    'same answer to the last digit. Omit it and the server draws one and ' +
    'reports it, so a run can always be repeated.');
  AddProp(Schema, 'r_min', 'number',
    Format('Floor the calculated reflectivity is clamped to (default %g). It ' +
      'is also the chart minimum stored in the .xrcx.', [DEF_R_MIN]));
  AddProp(Schema, 'points_inline_max', 'integer',
    Format('Longest curve returned inline in the result (default %d). Longer ' +
      'ones come back as null and are read from the files instead.',
      [DEF_INLINE_MAX]));

  Registry.Register('fit_xrr',
    'Fits a layer model to a measured reflectivity curve with the GUI''s ' +
    'LFPSO, minimising the same chi-squared X-Ray Calc 3 displays. This is a ' +
    'long-running job: the call returns a job_id at once, job_status reports ' +
    'the iteration and the best chi-squared as it goes, cancel_job stops it ' +
    'and job_result returns the answer. The result holds the fitted structure, ' +
    'the chi-squared of the start model and of the fit, the measured, ' +
    'calculated and residual curves, and a fit.xrcx that X-Ray Calc 3 opens ' +
    'with the model, the curves and the fit settings in place. Layer ' +
    'thickness, sigma and density, and the period of a repeating stack, can ' +
    'be fitted: the substrate is not in the engine''s particle vector and ' +
    'there are no scale, background or resolution parameters, so asking for ' +
    'those is refused with "not_fittable" ("scale" is accepted as a fixed ' +
    'multiplier of the data instead). By default a repeating stack keeps the ' +
    'period of the start model - the engine rescales its layers after every ' +
    'move - so fitting the thicknesses of such a stack fits the ratio between ' +
    'them at a fixed period; free the period ("target":"period" in "free", ' +
    'bounds in Angstrom) to fit d itself, for example from the Bragg peaks ' +
    'calc_reflectivity reports. The result says in "period_mode" how each ' +
    'repeating stack was treated (held, free, or floating in a profile fit, ' +
    'where the polynomial engine never holds the period). ' +
    'Cancellation is not instant: the engine offers one point per ' +
    'iteration at which it can be stopped, so cancel_job takes up to one ' +
    'iteration, which grows with population x points x layers. Angles are ' +
    'theta in degrees, never 2theta; lengths are Angstrom.',
    Schema,
    function(const P: TJSONObject): TJSONObject
    begin
      Result := SubmitFit(P);
    end);
end;

{ ------------------------------------------------------------ the polling -- }

procedure RegisterJobTools(Registry: TToolRegistry);
begin
  RegisterOptimizeTool(Registry);
  RegisterFitTool(Registry);

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
