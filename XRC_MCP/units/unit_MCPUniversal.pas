(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

unit unit_MCPUniversal;

(* The universal (XRFCalc) engine, seen from the MCP side.

   Three jobs live here.

   1. Configuration. `TUniversalIO.ConfigFromJSONObject` parses XRFCalc's config
      JSON; ConfigFromJSON below normalises a tool's arguments into exactly that
      shape first - filling in the defaults XRFCalc's own run-config form
      applies, so that a client can send `{"lines": ["B", "Si"],
      "element_pool": ["Ru", "C"], "substrate": "Si"}` and get a runnable
      configuration - and then hands the object to the engine. Nothing is
      re-implemented: the numbers a missing section defaults to are here, the
      parsing of the sections themselves is the engine's.

   2. Evaluation of an explicit structure. `evaluate_lines` has a structure, not
      a genome, so it cannot go through TUniversalFitness.Evaluate. It goes
      through EvaluateLayers (task 8) with a builder that walks the expanded
      TLayeredModel the GUI adapter produces. The FoM is therefore the
      optimizer's own FoM, computed by the optimizer's own code, for a structure
      the optimizer never proposed.

   3. Genome reporting. The optimizer speaks genomes; clients speak structures.
      GenomeToStructure mirrors TUniversalFitness.BuildLayers layer for layer, so
      the structure a client is handed is the structure whose FoM was reported.
      DistinctTopK picks the alternatives worth showing out of the final swarm.

   Threading. TMaterialMixer.Initialize reads its tables through
   cmd_math_globals.ReadHenke, which looks for '.\Henke\<name>.bin' and therefore
   changes the process working directory while it reads. That is process-global
   state: every Initialize in this server - here and in the optimizer tool - must
   be made under HenkeCwdLock. *)

interface

uses
  System.SysUtils, System.JSON, System.SyncObjs,
  unit_Types,
  unit_universal_types, unit_universal_templates,
  unit_MCPJobs, unit_MCPStructure;

var
  /// <summary>Serialises TMaterialMixer.Initialize, which changes the process
  /// working directory while it reads the Henke tables. Every call to
  /// Initialize in this server is made while holding it.</summary>
  HenkeCwdLock: TCriticalSection;

/// <summary>The fitness settings a tool starts from when the client gives none:
/// w_R 1, w_FWHM 0.25, R_min_threshold 0.001, unpolarised, no divergence, no
/// dark zone, full purity weighting, engine default scan.</summary>
function DefaultFitnessConfig: TFitnessConfig;

/// <summary>A full TUniversalConfig from a tool's arguments. The object is
/// normalised into the shape TUniversalIO.ConfigFromJSONObject reads (missing
/// sections filled with the defaults XRFCalc applies) and then parsed by the
/// engine. HenkePath, OutputDir, ResumeFrom and TemplatePath are set by the
/// server, not by the client.</summary>
function ConfigFromJSON(const J: TJSONObject; const OutputDir: string): TUniversalConfig;

/// <summary>The TUniversalIO.SaveConfig shape, as an object rather than a file,
/// for echoing the configuration a run actually used. Caller frees.</summary>
function ConfigToJSON(const C: TUniversalConfig): TJSONObject;

/// <summary>Base with every key present in J applied over it. An absent key
/// leaves the base value alone; "polarization" takes "s", "p" or "sp" ("p" is
/// computed as "sp": the engine has no pure-p path).</summary>
function FitnessConfigFromJSON(const J: TJSONObject; const Base: TFitnessConfig): TFitnessConfig;

/// <summary>What the fitness function actually used, including the scan
/// defaults TUniversalFitness substitutes for 0. "theta_min" carries a note:
/// it is the optimizer's dark-zone threshold, not the start of the scan.
/// Caller frees.</summary>
function FitnessConfigToJSON(const F: TFitnessConfig): TJSONObject;

/// <summary>The emission lines of a "lines" argument. Each item is either an
/// object {name|element, lambda|energy, weight?} or a bare element symbol
/// ("Si") or symbol range ("B-Si"), whose wavelength comes from the XRF line
/// table. At least one line, at most MAX_LINES (the fitness function's fixed
/// per-line arrays).</summary>
function LinesFromJSON(const A: TJSONArray): TArray<TXRFLine>;

/// <summary>The optimizer's figure of merit for a structure the optimizer did
/// not propose - positive is better, which is the negative of what the PSO
/// minimises. The layer stack handed to TUniversalFitness.EvaluateLayers is the
/// expanded model BuildLayeredModel produces, so it is layer for layer the stack
/// calc_reflectivity would use; the epsilons come from the universal engine's
/// own mixer, at the wavelength of each line. A layer with density 0 gets the
/// Henke bulk density, as everywhere else in the server.
/// Raises EMCPError('invalid_structure') when the structure has no periodic
/// stack: the FoM needs a period and a repeat count for the Bragg angles and the
/// reference FWHM.</summary>
function EvaluateStructure(const S: TFitStructure; const Info: TStructureInfo;
  const Lines: TArray<TXRFLine>; const Fit: TFitnessConfig;
  out Results: TTargetResults): Single;

/// <summary>The dominant material of each of the two roles, 'W/Si' - the key
/// TUniversalFitness.BuildLayers looks the template library up with.</summary>
function GenomeKey(const G: TGenome; const ElementNames: TArray<string>): string;

/// <summary>The genome itself: composition per role, period, gamma, N, sigma,
/// cap and density factors. Caller frees.</summary>
function GenomeToJSON(const G: TGenome; const ElementNames: TArray<string>): TJSONObject;

/// <summary>The genome as a structure in the server's own JSON shape, mirroring
/// TUniversalFitness.BuildLayers: the template path emits the cap as "cap" and
/// one stack of the template's sublayers, the plain path emits one stack of two
/// layers d*gamma and d*(1-gamma) of the dominant element at the composition's
/// effective density. Densities are the ones the mixer used.
/// The structure returned reproduces the FoM that was reported for the genome
/// <b>only when the run used pure elements</b>: the plain path names the
/// dominant element of each role, and the structure JSON has no syntax for a
/// mixed composition (see describe_server.material_syntax). ConfigFromJSON
/// therefore refuses structure.pure_elements = false in v1, which is what keeps
/// this function's output faithful.
/// Two corners where the emitted structure is deliberately not layer-identical
/// to BuildLayers:
/// - a degenerate genome (a template sublayer whose gamma reduction eats the
///   whole period) yields a layer of thickness 0, exactly as BuildLayers
///   computes it; such a genome carries the engine's degeneracy penalty and is
///   never a winner;
/// - a template cap of zero thickness (CapH = 0) is omitted entirely, because a
///   zero-thickness layer is not a layer and would not survive a round trip
///   through the structure reader, whereas BuildLayers still emits it. Feeding
///   such a structure back to evaluate_lines can therefore give a slightly
///   different FoM. Only a cap of exactly zero thickness is affected.
/// Caller frees.</summary>
function GenomeToStructure(const G: TGenome; const C: TUniversalConfig;
  const Templates: TTemplateLibrary; const ElementNames: TArray<string>;
  const ElementDensities: TArray<Single>; SubstrateDensity: Single): TJSONObject;

/// <summary>Indices into Particles of the best K *distinct* personal bests,
/// best first. Sorted by PBestFoM ascending (the PSO minimises), then walked:
/// a particle joins the result when, against every particle already accepted,
/// it differs in the dominant material pair, or by more than 5% in period, or by
/// more than 0.05 in gamma, or in the rounded number of periods. Entry 0 is
/// therefore the swarm's best particle; the optimizer's ABest, which is that
/// same global best, is what the caller reports as entry 0.</summary>
function DistinctTopK(const Particles: TParticleArray; K: Integer;
  const ElementNames: TArray<string>): TArray<Integer>;

/// <summary>The pairwise half of the top-k rule: True when A and B are far
/// enough apart to be worth reporting side by side. DistinctTopK applies it
/// within the swarm; it is exported because the candidate that always takes
/// rank 1 - the optimizer's all-time best, which is not an entry of the final
/// swarm array - has to be measured against the swarm's own with the same
/// yardstick.</summary>
function GenomesDistinct(const A, B: TGenome;
  const ElementNames: TArray<string>): Boolean;

/// <summary>The optimize_mirror job body (design note section 5). Seeds
/// System.RandSeed from Job.Seed, runs TUniversalOptimizer over Config with the
/// job folder as its output directory, and leaves in Job.ResultObj the best
/// candidate, the distinct top-k alternatives, the files the run wrote and the
/// configuration it used. One .xrfx package per rank is written next to them as
/// rank_&lt;r&gt;.xrfx.
///
/// Cancellation: the optimizer is asked to stop from the progress callback, and
/// a run that was cut short returns <b>without</b> a result, so the job ends
/// cancelled with whatever the engine wrote still on disk.
///
/// How long a cancel takes, exactly, because it bounds server shutdown as well
/// (TJobManager.Destroy joins the worker with no timeout). The flag is polled
/// once per iteration, in OnIteration, which is the only place the engine hands
/// control back; and two stretches of a run cannot be interrupted at all:
/// <list type="bullet">
/// <item>the prologue - TMaterialMixer.Initialize plus the first full
///   evaluation of the population, which happens before iteration 0 is
///   reported;</item>
/// <item>the save tail after the loop breaks - the final evaluation, the best
///   structure, one reflectivity curve per line, the population dump and the
///   checkpoint.</item>
/// </list>
/// So a cancel waits up to one iteration plus the save tail, and one iteration
/// costs roughly population x lines x scan points x layers. With the engine's
/// default population of 1000 that is far more than a second; a client that
/// wants a responsive cancel should keep the population modest.
///
/// While a job runs it holds HenkeCwdLock, so an evaluate_lines call made in
/// the meantime cannot acquire it and fails fast with EMCPError('server_busy')
/// rather than waiting for the whole run. That is the price of the engine
/// changing the process working directory while it reads its tables; see
/// EvaluateStructure's TryEnter on HenkeCwdLock.
///
/// Raises EMCPError('optimizer_error') when the engine reported an error (it
/// catches its own exceptions and calls OnError, so the message is picked up
/// after Run returns) and when Run ended without a final state.</summary>
procedure RunOptimizeJob(Job: TJob; const Config: TUniversalConfig; TopK: Integer);

const
  /// The rule DistinctTopK applies, for describe_server and the optimize_mirror
  /// tool description.
  TOP_K_RULE =
    'Candidates are ranked by figure of merit (best first) and a candidate is ' +
    'kept only when it differs from every candidate already kept: a different ' +
    'dominant material pair, or a period more than 5% away, or a gamma more ' +
    'than 0.05 away, or a different rounded number of periods. Entry 0 is ' +
    'always the global best.';

  /// The relative period difference two candidates must exceed to count as
  /// distinct.
  TOPK_D_TOLERANCE = 0.05;
  /// The absolute gamma difference two candidates must exceed to count as
  /// distinct.
  TOPK_GAMMA_TOLERANCE = 0.05;

  /// The largest top_k a client may ask optimize_mirror for.
  MAX_TOP_K = 20;
  /// The default when it asks for none.
  DEFAULT_TOP_K = 5;

  /// Said in the result of every optimize_mirror job: one results folder is
  /// written per run, not per candidate. The manifest and the XRC structure
  /// inside each package are rewritten for the rank being packaged; the curves
  /// and the progress log are the winner's, because the engine computes them
  /// once, for the run.
  XRFX_SHARED_RESULTS_NOTE =
    'results folder is shared; the manifest and best_structure_xrc.json inside ' +
    'each package are rank-specific, curves and progress log are the winner''s';

  /// How far EvaluateStructure may land from the figure of merit the optimizer
  /// reported for the same candidate before the result carries a warning.
  /// Relative. A reported structure carries its layer densities as JSON
  /// numbers, and the genome's own mixed epsilons are not bit-identical to the
  /// ones rebuilt from them; since the scan window of each line is derived from
  /// the stack's optical constants (TUniversalFitness.PeakWindow), that
  /// difference also shifts the grid the peak is sampled on by a fraction of a
  /// step. Measured on the Ru/C regression fixture: 2.5E-4. This bound is still
  /// three orders of magnitude below anything physically meaningful, and the
  /// warning is about a report disagreeing with itself, not about the fit.
  CONSISTENCY_TOLERANCE = 1E-3;

implementation

uses
  System.Math, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults,
  math_complex,
  cmd_unit_types,
  unit_materials, unit_materials_mix,
  unit_universal_fitness, unit_universal_io, unit_universal_optimizer,
  unit_xrf_lines, unit_xrfx_package,
  unit_MCPErrors, unit_MCPMaterials, unit_MCPSandbox, unit_MCPUnits;

const
  // DEFAULT_SCAN_POINTS and the rest of the scan rule are the engine's own, from
  // unit_universal_types, so this unit cannot drift from what it reports.

  // evaluate_lines answers in the same round trip and the optimizer scans once
  // per line per particle per iteration, so the scan grid is bounded. 20000
  // points is two orders of magnitude finer than the engine's default and far
  // finer than any Bragg peak these mirrors have; a scan wider than 90 degrees
  // in theta covers the whole reflection half-space.
  MAX_SCAN_POINTS     = SCAN_POINTS_MAX;
  MAX_SCAN_HALF_RANGE = 90.0;

  SCAN_POINTS_NOTE =
    'A floor, not the grid: every line is scanned with at least this many ' +
    'points, and with more whenever its step would otherwise be coarser than ' +
    'its kinematic peak width divided by scan_points_per_fwhm_ref, up to ' +
    'scan_points_max. Each line reports the grid it got.';

  SCAN_HALF_ADAPTIVE_NOTE =
    '0 = adaptive: each line is scanned over max(0.5 deg, 4 kinematic widths) ' +
    'either side of its refraction-corrected peak, never starting inside the ' +
    'total-reflection plateau. See scan_half_deg in each line result.';

  SCAN_HALF_FIXED_NOTE =
    'A fixed half-range about each line''s refraction-corrected peak. The scan ' +
    'still never starts inside the total-reflection plateau, so a line whose ' +
    'peak sits close to it is scanned over less than this.';

  THETA_MIN_NOTE =
    'Optimizer dark-zone threshold, not the scan start: a line whose Bragg ' +
    'angle falls below it is penalised, not moved.';

{ --------------------------------------------------------------- defaults -- }

function DefaultFitnessConfig: TFitnessConfig;
begin
  Result := Default(TFitnessConfig);
  Result.wR := 1.0;
  Result.wFWHM := 0.25;
  Result.RMinThreshold := 0.001;
  Result.Polarization := cmd_unit_types.cmSP;
  Result.DeltaTheta := 0;
  Result.ThetaMin := 0;
  Result.wPurity := 1.0;
  Result.ScanPoints := 0;      // 0 = the engine's DEFAULT_SCAN_POINTS
  Result.ScanHalfRange := 0;   // 0 = the engine's adaptive window
  Result.NRef := DEFAULT_N_REF;
end;

{ ------------------------------------------------------------------ lines -- }

/// The XRF table lookup, with the engine's EArgumentException turned into the
/// structured error a client can act on.
function LambdaOfSymbol(const Symbol: string): Double;
begin
  try
    Result := GetXRFLambda(Symbol);
  except
    on E: EArgumentException do
      raise EMCPError.Create('invalid_argument',
        Format('"%s" is not an element in the XRF line table', [Symbol]),
        'describe_server reports the line table in use');
  end;
  if Result <= 0 then
    raise EMCPError.Create('invalid_argument',
      Format('The XRF line table has no usable wavelength for "%s"', [Symbol]));
end;

procedure AddLine(var Lines: TArray<TXRFLine>; const Name: string;
  Lambda, Weight: Double);
begin
  if Lambda <= 0 then
    raise EMCPError.Create('invalid_argument',
      Format('Line "%s": the wavelength must be greater than zero Angstrom', [Name]));
  if Weight < 0 then
    raise EMCPError.Create('invalid_argument',
      Format('Line "%s": "weight" must not be negative', [Name]));
  SetLength(Lines, Length(Lines) + 1);
  Lines[High(Lines)].Name := Name;
  Lines[High(Lines)].Lambda := Lambda;
  Lines[High(Lines)].Weight := Weight;
end;

function LinesFromJSON(const A: TJSONArray): TArray<TXRFLine>;
var
  i, k: Integer;
  Item: TJSONValue;
  Obj: TJSONObject;
  S, Name: string;
  Expanded: TArray<string>;
  Lambda: Double;
begin
  SetLength(Result, 0);
  if A = nil then
    raise EMCPError.Create('invalid_argument', 'Missing "lines"');

  for i := 0 to A.Count - 1 do
  begin
    Item := A.Items[i];

    if Item is TJSONString then
    begin
      S := Trim(Item.Value);
      if S = '' then
        raise EMCPError.Create('invalid_argument',
          Format('lines[%d] must be an element symbol', [i]));
      if Pos('-', S) > 0 then
      begin
        // 'B-Si': the same symbol range the XRFCalc config accepts
        Expanded := ExpandElementRange(S);
        for k := 0 to High(Expanded) do
          AddLine(Result, Expanded[k], LambdaOfSymbol(Expanded[k]), 1.0);
      end
      else
        AddLine(Result, S, LambdaOfSymbol(S), 1.0);
    end

    else if Item is TJSONObject then
    begin
      Obj := TJSONObject(Item);
      Name := Trim(JSONArgs.OptStr(Obj, 'name', JSONArgs.OptStr(Obj, 'element', '')));
      if Name = '' then
        raise EMCPError.Create('invalid_argument',
          Format('lines[%d] must have a "name"', [i]));
      // Either the wavelength or the energy, never both; neither means the line
      // is named and its wavelength comes from the table.
      Lambda := GetLambdaArg(Obj, 'lambda', 'energy', True, 0);
      if Lambda <= 0 then
        Lambda := LambdaOfSymbol(Name);
      AddLine(Result, Name, Lambda, JSONArgs.OptFloat(Obj, 'weight', 1.0));
    end

    else
      raise EMCPError.Create('invalid_argument',
        Format('lines[%d] must be an object or an element symbol', [i]));
  end;

  if Length(Result) = 0 then
    raise EMCPError.Create('invalid_argument', '"lines" must hold at least one line');
  // ComputeFoM keeps its per-line arrays on the stack, dimensioned MAX_LINES.
  if Length(Result) > MAX_LINES then
    raise EMCPError.Create('invalid_argument',
      Format('At most %d lines can be evaluated at once', [MAX_LINES]),
      IntToStr(Length(Result)));
end;

{ ---------------------------------------------------------------- fitness -- }

function ParsePolarizationValue(const S: string): TPolarisation;
begin
  if SameText(S, 's') then
    Exit(cmd_unit_types.cmS);
  if SameText(S, 'p') or SameText(S, 'sp') then
    Exit(cmd_unit_types.cmSP);
  raise EMCPError.Create('invalid_argument',
    '"polarization" must be "s", "p" or "sp"', S);
end;

function PolarizationName(P: TPolarisation): string;
begin
  if P = cmd_unit_types.cmS then
    Result := 's'
  else
    Result := 'sp';
end;

/// Every bound the fitness settings have to respect, wherever they came from -
/// a tool's "fitness" overrides or a whole configuration parsed by the engine.
procedure ValidateFitness(const F: TFitnessConfig);
begin
  if F.RMinThreshold < 0 then
    raise EMCPError.Create('invalid_argument', '"R_min_threshold" must not be negative');
  if F.DeltaTheta < 0 then
    raise EMCPError.Create('invalid_argument', '"delta_theta" must not be negative');
  if F.ThetaMin < 0 then
    raise EMCPError.Create('invalid_argument', '"theta_min" must not be negative');
  if F.ScanPoints < 0 then
    raise EMCPError.Create('invalid_argument', '"scan_points" must not be negative');
  // The scan needs enough points for a peak and its two half-maximum crossings.
  if (F.ScanPoints > 0) and (F.ScanPoints < 3) then
    raise EMCPError.Create('invalid_argument', '"scan_points" must be at least 3');
  if F.ScanPoints > MAX_SCAN_POINTS then
    raise EMCPError.Create('invalid_argument',
      Format('"scan_points" must not exceed %d', [MAX_SCAN_POINTS]),
      IntToStr(F.ScanPoints));
  if F.ScanHalfRange < 0 then
    raise EMCPError.Create('invalid_argument', '"scan_half_range" must not be negative');
  if F.NRef <= 0 then
    raise EMCPError.Create('invalid_argument',
      '"n_ref" is a number of periods and must be greater than zero',
      IntToStr(F.NRef));
  if F.ScanHalfRange > MAX_SCAN_HALF_RANGE then
    raise EMCPError.Create('invalid_argument',
      Format('"scan_half_range" must not exceed %g degrees', [Double(MAX_SCAN_HALF_RANGE)]));
end;

function FitnessConfigFromJSON(const J: TJSONObject;
  const Base: TFitnessConfig): TFitnessConfig;
begin
  Result := Base;
  if J = nil then
    Exit;

  Result.wR := JSONArgs.OptFloat(J, 'w_R', Result.wR);
  Result.wFWHM := JSONArgs.OptFloat(J, 'w_FWHM', Result.wFWHM);
  Result.RMinThreshold := JSONArgs.OptFloat(J, 'R_min_threshold', Result.RMinThreshold);
  Result.DeltaTheta := JSONArgs.OptFloat(J, 'delta_theta', Result.DeltaTheta);
  Result.ThetaMin := JSONArgs.OptFloat(J, 'theta_min', Result.ThetaMin);
  Result.wPurity := JSONArgs.OptFloat(J, 'w_purity', Result.wPurity);
  Result.ScanPoints := JSONArgs.OptInt(J, 'scan_points', Result.ScanPoints);
  Result.ScanHalfRange := JSONArgs.OptFloat(J, 'scan_half_range', Result.ScanHalfRange);
  Result.NRef := JSONArgs.OptInt(J, 'n_ref', Result.NRef);
  if JSONArgs.Has(J, 'polarization') then
    Result.Polarization := ParsePolarizationValue(JSONArgs.ReqStr(J, 'polarization'));

  ValidateFitness(Result);
end;

function FitnessConfigToJSON(const F: TFitnessConfig): TJSONObject;
var
  Points, NRef: Integer;
begin
  // What TUniversalFitness.Create resolved them to, not what was asked for.
  if F.ScanPoints > 0 then
    Points := F.ScanPoints
  else
    Points := DEFAULT_SCAN_POINTS;
  if F.NRef > 0 then
    NRef := F.NRef
  else
    NRef := DEFAULT_N_REF;

  Result := TJSONObject.Create;
  try
    Result.AddPair('w_R', JSONArgs.Num(F.wR));
    Result.AddPair('w_FWHM', JSONArgs.Num(F.wFWHM));
    Result.AddPair('R_min_threshold', JSONArgs.Num(F.RMinThreshold));
    Result.AddPair('w_purity', JSONArgs.Num(F.wPurity));
    Result.AddPair('polarization', PolarizationName(F.Polarization));
    Result.AddPair('delta_theta', JSONArgs.Num(F.DeltaTheta));
    Result.AddPair('theta_min', JSONArgs.Num(F.ThetaMin));
    Result.AddPair('theta_min_note', THETA_MIN_NOTE);
    Result.AddPair('n_ref', TJSONNumber.Create(NRef));
    // The grid is per line, so what belongs here is the rule. What it came to
    // for each line is in that line's own scan_step_deg / scan_points_used /
    // scan_half_deg.
    Result.AddPair('scan_points', TJSONNumber.Create(Points));
    Result.AddPair('scan_points_note', SCAN_POINTS_NOTE);
    Result.AddPair('scan_points_per_fwhm_ref',
      TJSONNumber.Create(POINTS_PER_FWHM_REF));
    Result.AddPair('scan_points_max', TJSONNumber.Create(SCAN_POINTS_MAX));
    Result.AddPair('scan_half_range', JSONArgs.Num(F.ScanHalfRange));
    if F.ScanHalfRange > 0 then
      Result.AddPair('scan_half_range_note', SCAN_HALF_FIXED_NOTE)
    else
      Result.AddPair('scan_half_range_note', SCAN_HALF_ADAPTIVE_NOTE);
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------------------------------------------------- configuration -- }

function NumPair(const Value: Double): TJSONNumber;
begin
  Result := TJSONNumber.Create(Value);
end;

function RangeObject(Min, Max: Double): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('min', NumPair(Min));
  Result.AddPair('max', NumPair(Max));
end;

/// Adds Value under Key when the object has no such key yet. Ownership of Value
/// passes to the object either way.
procedure DefaultPair(O: TJSONObject; const Key: string; Value: TJSONValue);
begin
  if O.FindValue(Key) = nil then
    O.AddPair(Key, Value)
  else
    Value.Free;
end;

/// The object under Key, created empty and inserted when it is not there. Raises
/// invalid_argument when the key holds something that is not an object.
function SectionOf(O: TJSONObject; const Key: string): TJSONObject;
var
  V: TJSONValue;
begin
  V := O.FindValue(Key);
  if (V = nil) or (V is TJSONNull) then
  begin
    if V <> nil then
      O.RemovePair(Key).Free;
    Result := TJSONObject.Create;
    O.AddPair(Key, Result);
    Exit;
  end;
  if not (V is TJSONObject) then
    raise EMCPError.Create('invalid_argument', Format('"%s" must be an object', [Key]));
  Result := TJSONObject(V);
end;

procedure FillStructureDefaults(O: TJSONObject);
begin
  DefaultPair(O, 'type', TJSONString.Create('bilayer'));
  DefaultPair(O, 'layers_per_period', TJSONNumber.Create(LAYERS_PER_PERIOD));
  DefaultPair(O, 'pure_elements', TJSONBool.Create(True));
  DefaultPair(O, 'd', RangeObject(30, 80));
  DefaultPair(O, 'gamma', RangeObject(0.15, 0.70));
  DefaultPair(O, 'N', RangeObject(40, 200));
  DefaultPair(O, 'sigma', NumPair(3));
  DefaultPair(O, 'density_factor', NumPair(1));
end;

procedure FillFitnessDefaults(O: TJSONObject);
begin
  DefaultPair(O, 'w_R', NumPair(1.0));
  DefaultPair(O, 'w_FWHM', NumPair(0.25));
  DefaultPair(O, 'n_ref', TJSONNumber.Create(DEFAULT_N_REF));
  DefaultPair(O, 'R_min_threshold', NumPair(0.001));
  DefaultPair(O, 'polarization', TJSONString.Create('sp'));
  DefaultPair(O, 'w_purity', NumPair(1.0));
end;

procedure FillOptimizerDefaults(O: TJSONObject);
begin
  DefaultPair(O, 'population', TJSONNumber.Create(1000));
  DefaultPair(O, 'iterations', TJSONNumber.Create(100));
  DefaultPair(O, 'tolerance', NumPair(1E-6));
  DefaultPair(O, 'stagnation_limit', TJSONNumber.Create(200));
  DefaultPair(O, 'w1', NumPair(0.4));
  DefaultPair(O, 'w2', NumPair(0.5));
  DefaultPair(O, 'jamming_max', TJSONNumber.Create(30));
  DefaultPair(O, 'checkpoint_every', TJSONNumber.Create(100));
end;

/// The template library a configuration should run against. A name the client
/// supplied is always resolved through the sandbox, so an absolute, a
/// drive-qualified, a UNC or a '..' path is refused with path_outside_workdir -
/// a template file is a file the client chooses, and every client-chosen path
/// in this server lives under the work directory. Naming none is not a path at
/// all: it selects the library the server itself was started with, which is a
/// server-side setting.
function ResolveConfigTemplatePath(const Given: string): string;
begin
  if Trim(Given) = '' then
    Exit(TemplatesFile);
  if WorkDir = nil then
    raise EMCPError.Create('internal',
      'There is no working directory, so "template_file" cannot be resolved');
  Result := WorkDir.ResolvePath(Given, False);
end;

function ConfigFromJSON(const J: TJSONObject; const OutputDir: string): TUniversalConfig;
var
  N: TJSONObject;
  Lines: TArray<TXRFLine>;
  Arr: TJSONArray;
  Obj, JStructure: TJSONObject;
  V: TJSONValue;
  Given: string;
  i: Integer;
begin
  if J = nil then
    raise EMCPError.Create('invalid_argument', 'The configuration must be a JSON object');

  // A normalised copy so that the engine's parser - which is the definition of
  // how a configuration is read - sees a complete document. The client's own
  // object is never modified.
  N := TJSONObject(J.Clone);
  try
    // Lines. The engine's parser wants {element, lambda, weight}; the server
    // accepts rather more than that, so the array is rewritten here.
    V := N.FindValue('lines');
    if V = nil then
      V := N.FindValue('targets');
    // "Missing" and "not an array" are different mistakes; LinesFromJSON only
    // ever sees nil, so the difference is drawn here.
    if (V <> nil) and not (V is TJSONArray) then
      raise EMCPError.Create('invalid_argument', '"lines" must be an array');
    Arr := TJSONArray(V);
    Lines := LinesFromJSON(Arr);
    if N.FindValue('lines') <> nil then
      N.RemovePair('lines').Free;
    if N.FindValue('targets') <> nil then
      N.RemovePair('targets').Free;
    Arr := TJSONArray.Create;
    N.AddPair('lines', Arr);
    for i := 0 to High(Lines) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('element', Lines[i].Name);
      Obj.AddPair('lambda', NumPair(Lines[i].Lambda));
      Obj.AddPair('weight', NumPair(Lines[i].Weight));
      Arr.AddElement(Obj);
    end;

    // The two things the server cannot invent.
    if not (N.FindValue('element_pool') is TJSONArray) then
      raise EMCPError.Create('invalid_argument',
        '"element_pool" must be an array of material names');
    if TJSONArray(N.FindValue('element_pool')).Count = 0 then
      raise EMCPError.Create('invalid_argument',
        '"element_pool" must hold at least one material');
    if JSONArgs.OptStr(N, 'substrate', '').Trim = '' then
      raise EMCPError.Create('invalid_argument', 'Missing "substrate"');

    JStructure := SectionOf(N, 'structure');
    // v1 optimises over pure elements only. With mixed compositions the
    // optimizer's genome cannot be written back as a structure - the structure
    // JSON names one material per layer and has no mixing syntax - so a
    // reported candidate would not reproduce its own figure of merit. Refusing
    // it here is better than reporting a structure that is not the one scored.
    V := JStructure.FindValue('pure_elements');
    if (V is TJSONBool) and not TJSONBool(V).AsBoolean then
      raise EMCPError.Create('invalid_argument',
        'structure.pure_elements must be true in v1: mixed compositions cannot ' +
        'be expressed in the structure JSON (see describe_server.material_syntax)');
    FillStructureDefaults(JStructure);
    FillFitnessDefaults(SectionOf(N, 'fitness'));
    FillOptimizerDefaults(SectionOf(N, 'optimizer'));

    // Server-owned. henke_path and output_dir are overwritten after parsing as
    // well; they are set here so that the engine's parser never sees them
    // missing.
    Given := JSONArgs.OptStr(N, 'template_file', '');
    if N.FindValue('henke_path') <> nil then
      N.RemovePair('henke_path').Free;
    if N.FindValue('output_dir') <> nil then
      N.RemovePair('output_dir').Free;
    if N.FindValue('resume_from') <> nil then
      N.RemovePair('resume_from').Free;
    N.AddPair('henke_path', HenkeDir);
    N.AddPair('output_dir', OutputDir);
    N.AddPair('resume_from', TJSONNull.Create);

    try
      Result := TUniversalIO.ConfigFromJSONObject(N);
    except
      on E: EMCPError do
        raise;
      on E: Exception do
        raise EMCPError.Create('invalid_argument',
          'The configuration could not be read: ' + E.Message);
    end;
  finally
    N.Free;
  end;

  // The engine parsed the fitness section; the server's bounds still apply.
  ValidateFitness(Result.Fitness);

  Result.HenkePath := HenkeDir;
  Result.OutputDir := OutputDir;
  Result.ResumeFrom := '';
  Result.TemplatePath := ResolveConfigTemplatePath(Given);
end;

function ConfigToJSON(const C: TUniversalConfig): TJSONObject;
var
  JLines, JPool, JExcl: TJSONArray;
  JLine, JStructure, JFitness, JOptimizer: TJSONObject;
  i: Integer;
begin
  Result := TJSONObject.Create;
  try
    JLines := TJSONArray.Create;
    Result.AddPair('lines', JLines);
    for i := 0 to High(C.Lines) do
    begin
      JLine := TJSONObject.Create;
      JLine.AddPair('element', C.Lines[i].Name);
      JLine.AddPair('lambda', JSONArgs.Num(C.Lines[i].Lambda));
      JLine.AddPair('weight', JSONArgs.Num(C.Lines[i].Weight));
      JLines.AddElement(JLine);
    end;

    JPool := TJSONArray.Create;
    Result.AddPair('element_pool', JPool);
    for i := 0 to High(C.ElementPool) do
      JPool.Add(C.ElementPool[i]);

    if Length(C.ExcludedPairs) > 0 then
    begin
      JExcl := TJSONArray.Create;
      Result.AddPair('excluded_pairs', JExcl);
      for i := 0 to High(C.ExcludedPairs) do
        JExcl.Add(C.ElementPool[C.ExcludedPairs[i].Idx1] + '/' +
                  C.ElementPool[C.ExcludedPairs[i].Idx2]);
    end;

    JStructure := TJSONObject.Create;
    Result.AddPair('structure', JStructure);
    JStructure.AddPair('type', C.Structure.StructureType);
    JStructure.AddPair('layers_per_period', TJSONNumber.Create(C.Structure.LayersPerPeriod));
    JStructure.AddPair('pure_elements', TJSONBool.Create(C.Structure.PureElements));
    JStructure.AddPair('d', RangeObject(C.Structure.dRange.Min, C.Structure.dRange.Max));
    JStructure.AddPair('gamma', RangeObject(C.Structure.GammaRange.Min, C.Structure.GammaRange.Max));
    JStructure.AddPair('N', RangeObject(C.Structure.NRange.Min, C.Structure.NRange.Max));
    if C.Structure.SigmaFixed >= 0 then
      JStructure.AddPair('sigma', JSONArgs.Num(C.Structure.SigmaFixed))
    else
      JStructure.AddPair('sigma',
        RangeObject(C.Structure.SigmaRange.Min, C.Structure.SigmaRange.Max));
    if C.Structure.DensityFactorFixed >= 0 then
      JStructure.AddPair('density_factor', JSONArgs.Num(C.Structure.DensityFactorFixed))
    else
      JStructure.AddPair('density_factor',
        RangeObject(C.Structure.DensityFactorRange.Min, C.Structure.DensityFactorRange.Max));

    JFitness := FitnessConfigToJSON(C.Fitness);
    Result.AddPair('fitness', JFitness);

    JOptimizer := TJSONObject.Create;
    Result.AddPair('optimizer', JOptimizer);
    JOptimizer.AddPair('population', TJSONNumber.Create(C.Optimizer.Population));
    JOptimizer.AddPair('iterations', TJSONNumber.Create(C.Optimizer.Iterations));
    JOptimizer.AddPair('tolerance', JSONArgs.Num(C.Optimizer.Tolerance));
    JOptimizer.AddPair('stagnation_limit', TJSONNumber.Create(C.Optimizer.StagnationLimit));
    JOptimizer.AddPair('w1', JSONArgs.Num(C.Optimizer.w1));
    JOptimizer.AddPair('w2', JSONArgs.Num(C.Optimizer.w2));
    JOptimizer.AddPair('jamming_max', TJSONNumber.Create(C.Optimizer.JammingMax));
    JOptimizer.AddPair('checkpoint_every', TJSONNumber.Create(C.Optimizer.CheckpointEvery));

    Result.AddPair('substrate', C.Substrate);
    if C.TemplatePath = '' then
      Result.AddPair('template_file', TJSONNull.Create)
    else
      Result.AddPair('template_file', C.TemplatePath);
  except
    Result.Free;
    raise;
  end;
end;

{ ------------------------------------------------- explicit-structure FoM -- }

/// The distinct materials of a structure, in the order they are first met from
/// the surface down, with the substrate material appended when it is not among
/// them. This is the mixer's element list.
function StructureMaterials(const S: TFitStructure): TArray<string>;

  procedure Add(const Name: string; var List: TArray<string>);
  var
    k: Integer;
  begin
    if Name = '' then
      Exit;
    for k := 0 to High(List) do
      if SameText(List[k], Name) then
        Exit;
    SetLength(List, Length(List) + 1);
    List[High(List)] := Name;
  end;

var
  i, j: Integer;
begin
  SetLength(Result, 0);
  for i := 0 to High(S.Stacks) do
    for j := 0 to High(S.Stacks[i].Layers) do
      Add(S.Stacks[i].Layers[j].Material, Result);
  Add(S.Subs.Material, Result);
end;

function EvaluateStructure(const S: TFitStructure; const Info: TStructureInfo;
  const Lines: TArray<TXRFLine>; const Fit: TFitnessConfig;
  out Results: TTargetResults): Single;
var
  Materials: TArray<string>;
  Lambdas: TArray<Single>;
  MatIdx: TArray<Integer>;
  Config: TUniversalConfig;
  Mixer: TMaterialMixer;
  Fitness: TUniversalFitness;
  Model: TLayeredModel;
  ModelLayers: TCalcLayers;
  Names: TArray<string>;
  SubSigma: Single;
  Bad: string;
  i, Last: Integer;
  Builder: TLayerSetBuilder;
begin
  SetLength(Results, 0);

  if Length(Lines) = 0 then
    raise EMCPError.Create('invalid_argument', '"lines" must hold at least one line');
  // ComputeFoM keeps its per-line arrays on the stack, dimensioned MAX_LINES,
  // and Release builds have range checking off: a longer list would be written
  // past the end of them. LinesFromJSON already refuses one, but this is the
  // engine's own precondition and belongs on the engine's own entry point.
  if Length(Lines) > MAX_LINES then
    raise EMCPError.Create('invalid_argument',
      Format('At most %d lines can be evaluated at once', [MAX_LINES]),
      IntToStr(Length(Lines)));
  if Info.PeriodicStackIndex < 0 then
    raise EMCPError.Create('invalid_structure',
      'The figure of merit needs a periodic stack: no stack has N greater than 1',
      'stacks');
  if not (Info.Period > 0) then
    raise EMCPError.Create('invalid_structure',
      'The periodic stack has a period of zero',
      Format('stacks[%d]', [Info.PeriodicStackIndex]));

  Bad := ValidateMaterials(S);
  if Bad <> '' then
    raise EMCPError.Create('unknown_material',
      Format('No Henke table for material "%s"', [Bad]),
      'list_materials enumerates the names this server knows');

  Materials := StructureMaterials(S);
  SetLength(Lambdas, Length(Lines));
  for i := 0 to High(Lines) do
    Lambdas[i] := Lines[i].Lambda;

  Config := Default(TUniversalConfig);
  SetLength(Config.Lines, Length(Lines));
  for i := 0 to High(Lines) do
    Config.Lines[i] := Lines[i];
  SetLength(Config.ElementPool, Length(Materials));
  for i := 0 to High(Materials) do
    Config.ElementPool[i] := Materials[i];
  Config.Fitness := Fit;
  Config.Substrate := S.Subs.Material;
  Config.HenkePath := HenkeDir;
  // Explicit layers, never a genome: the template path in BuildLayers must stay
  // out of reach, and PureElements is what switches it on.
  Config.Structure.PureElements := False;
  Config.Structure.StructureType := 'explicit';
  Config.Structure.LayersPerPeriod := LAYERS_PER_PERIOD;

  // The expanded stack, exactly as calc_reflectivity would build it: index 0 is
  // vacuum, the last index is the substrate.
  Model := BuildLayeredModel(S);
  try
    ModelLayers := Model.LayersDirect;
    Names := Model.LayerNames;
    Last := High(ModelLayers);
    if Last < 1 then
      raise EMCPError.Create('invalid_structure', 'The structure has no layers', 'stacks');

    Mixer := TMaterialMixer.Create;
    try
      // A running job (optimize_mirror) holds this lock for its whole Run, not
      // just its own Initialize call - see RunOptimizeJob. Blocking here would
      // make evaluate_lines wait out the job instead of answering in its own
      // round trip, and would make cancel_job/job_status unreachable until the
      // job ends. Fail fast instead.
      if not HenkeCwdLock.TryEnter then
        raise EMCPError.Create('server_busy',
          'a job is using the engine; evaluate_lines is unavailable until it finishes',
          'call job_status to check progress, or cancel_job to stop it');
      try
        Mixer.Initialize(Materials, Lambdas, S.Subs.Material, HenkeDir);
      finally
        HenkeCwdLock.Release;
      end;

      // Resolved once, not once per layer per line.
      SetLength(MatIdx, Last);      // 1 .. Last-1 are used; 0 is vacuum
      for i := 1 to Last - 1 do
      begin
        MatIdx[i] := Mixer.FindElementIndex(Names[i]);
        if MatIdx[i] < 0 then
          raise EMCPError.Create('internal',
            Format('Material "%s" is missing from the mixer element list', [Names[i]]));
      end;
      SubSigma := S.Subs.P[2].V;

      Fitness := TUniversalFitness.Create(Mixer, Config, nil);
      try
        Builder :=
          procedure(TargetIdx: Integer; var L: TLayers)
          var
            k: Integer;
            Rho: Single;
            Eps: TComplex;
          begin
            SetLength(L, Last + 1);

            L[0].e.re := 1.0;
            L[0].e.im := 0.0;
            L[0].H := 0;
            L[0].S := 0;
            L[0].Rho := 0;

            for k := 1 to Last - 1 do
            begin
              Rho := ModelLayers[k].ro;
              if Rho = 0 then
                Rho := Mixer.GetElementDensity(MatIdx[k]);
              Mixer.CalcSingleEpsilon(MatIdx[k], Rho, TargetIdx, Eps);
              L[k].e := Eps;
              L[k].H := ModelLayers[k].L;
              L[k].S := ModelLayers[k].s;
              L[k].Rho := Rho;
            end;

            // The substrate is half-infinite and always at its bulk density:
            // CalcSubstrateEpsilon does not take one.
            Mixer.CalcSubstrateEpsilon(TargetIdx, Eps);
            L[Last].e := Eps;
            L[Last].H := 1E8;
            L[Last].S := SubSigma;
            L[Last].Rho := Mixer.GetSubstrateDensity;
          end;

        Result := -Fitness.EvaluateLayers(Builder, Info.Period, Info.N, Results);
      finally
        Fitness.Free;
      end;
    finally
      Mixer.Free;
    end;
  finally
    Model.Free;
  end;
end;

{ ---------------------------------------------------------------- genomes -- }

function DominantIndex(const Comp: TCompositionGenes): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 1 to High(Comp) do
    if Comp[i] > Comp[Result] then
      Result := i;
end;

function DominantName(const Comp: TCompositionGenes;
  const ElementNames: TArray<string>): string;
var
  Idx: Integer;
begin
  Idx := DominantIndex(Comp);
  if (Idx >= 0) and (Idx <= High(ElementNames)) then
    Result := ElementNames[Idx]
  else
    Result := '';
end;

function GenomeKey(const G: TGenome; const ElementNames: TArray<string>): string;
begin
  Result := DominantName(G.Composition[0], ElementNames) + '/' +
            DominantName(G.Composition[1], ElementNames);
end;

function EffectiveDensity(const Comp: TCompositionGenes;
  const ElementDensities: TArray<Single>): Double;
var
  i: Integer;
begin
  // Sum fraction * bulk density, the same mixture rule CalcMixedEpsilon uses
  // with a density factor of 1 - which is what BuildLayers passes.
  Result := 0;
  for i := 0 to High(Comp) do
    if i <= High(ElementDensities) then
      Result := Result + Comp[i] * ElementDensities[i];
end;

function GenomeToJSON(const G: TGenome; const ElementNames: TArray<string>): TJSONObject;
var
  JComp, JDens: TJSONArray;
  JRole: TJSONObject;
  Role, i: Integer;
begin
  Result := TJSONObject.Create;
  try
    JComp := TJSONArray.Create;
    Result.AddPair('composition', JComp);
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JRole := TJSONObject.Create;
      JComp.AddElement(JRole);
      for i := 0 to High(G.Composition[Role]) do
        if (i <= High(ElementNames)) and (G.Composition[Role][i] > 0) then
          JRole.AddPair(ElementNames[i], JSONArgs.Num(G.Composition[Role][i]));
    end;

    Result.AddPair('d', JSONArgs.Num(G.d));
    Result.AddPair('gamma', JSONArgs.Num(G.Gamma));
    Result.AddPair('N', TJSONNumber.Create(NRound(G.N)));
    Result.AddPair('sigma', JSONArgs.Num(G.Sigma));
    Result.AddPair('cap_h', JSONArgs.Num(G.CapH));
    Result.AddPair('cap_variant', TJSONNumber.Create(Round(G.CapVariant)));

    JDens := TJSONArray.Create;
    Result.AddPair('density_factor', JDens);
    for Role := 0 to LAYERS_PER_PERIOD - 1 do
      JDens.AddElement(JSONArgs.Num(G.DensityFactor[Role]));
  except
    Result.Free;
    raise;
  end;
end;

function LayerObject(const Material: string; Thickness, Sigma, Density: Double): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('material', Material);
  Result.AddPair('thickness', JSONArgs.Num(Thickness));
  Result.AddPair('sigma', JSONArgs.Num(Sigma));
  Result.AddPair('density', JSONArgs.Num(Density));
end;

function GenomeToStructure(const G: TGenome; const C: TUniversalConfig;
  const Templates: TTemplateLibrary; const ElementNames: TArray<string>;
  const ElementDensities: TArray<Single>; SubstrateDensity: Single): TJSONObject;
var
  JStacks, JLayers: TJSONArray;
  JStack, JSubs: TJSONObject;
  TemplIdx, CapIdx, Role, j: Integer;
  Templ: TTemplatePair;
  Cap: TTemplateCap;
  SubH, H: Double;
begin
  // The same test BuildLayers makes, in the same order.
  TemplIdx := -1;
  if C.Structure.PureElements and (Length(Templates) > 0) then
    TemplIdx := FindTemplate(Templates, GenomeKey(G, ElementNames));

  Result := TJSONObject.Create;
  try
    JSubs := TJSONObject.Create;
    JSubs.AddPair('material', C.Substrate);
    JSubs.AddPair('sigma', JSONArgs.Num(G.Sigma));
    JSubs.AddPair('density', JSONArgs.Num(SubstrateDensity));
    Result.AddPair('substrate', JSubs);

    JStacks := TJSONArray.Create;
    Result.AddPair('stacks', JStacks);

    JStack := TJSONObject.Create;
    JStack.AddPair('N', TJSONNumber.Create(NRound(G.N)));
    JLayers := TJSONArray.Create;
    JStack.AddPair('layers', JLayers);
    JStacks.AddElement(JStack);

    if TemplIdx >= 0 then
    begin
      Templ := Templates[TemplIdx];
      for j := 0 to High(Templ.Layers) do
      begin
        case Templ.Layers[j].ThicknessType of
          ttGamma:
            SubH := G.d * G.Gamma - Templ.GammaReduction;
          ttOneMinusGamma:
            SubH := G.d * (1 - G.Gamma) - Templ.OneMinusGammaReduction;
        else
          SubH := Templ.Layers[j].FixedThickness;
        end;
        if SubH < 0 then
          SubH := 0;
        JLayers.AddElement(LayerObject(Templ.Layers[j].Material, SubH,
          Templ.Layers[j].Sigma, Templ.Layers[j].Density));
      end;

      // The cap sits above the topmost stack, so it is the JSON "cap".
      // BuildLayers includes it whenever the template has one; a cap of zero
      // thickness is no layer at all and would not survive a round trip through
      // the structure reader, so it is left out here.
      if (Length(Templ.Caps) > 0) and (G.CapH > 0) then
      begin
        CapIdx := Round(G.CapVariant);
        if CapIdx < 0 then
          CapIdx := 0;
        if CapIdx > High(Templ.Caps) then
          CapIdx := High(Templ.Caps);
        Cap := Templ.Caps[CapIdx];
        Result.AddPair('cap',
          LayerObject(Cap.Material, G.CapH, Cap.Sigma, Cap.Density));
      end;
    end
    else
    begin
      for Role := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        if Role = 0 then
          H := G.d * G.Gamma
        else
          H := G.d * (1 - G.Gamma);
        JLayers.AddElement(LayerObject(
          DominantName(G.Composition[Role], ElementNames), H, G.Sigma,
          EffectiveDensity(G.Composition[Role], ElementDensities)));
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ ------------------------------------------------------------ top-k rule -- }

/// True when A and B are far enough apart to both be worth reporting.
function GenomesDistinct(const A, B: TGenome;
  const ElementNames: TArray<string>): Boolean;
var
  RelD: Double;
begin
  if not SameText(GenomeKey(A, ElementNames), GenomeKey(B, ElementNames)) then
    Exit(True);
  if NRound(A.N) <> NRound(B.N) then
    Exit(True);
  if Abs(A.Gamma - B.Gamma) > TOPK_GAMMA_TOLERANCE then
    Exit(True);
  // A period of zero cannot be a relative reference; anything but another zero
  // is a different period then.
  if B.d = 0 then
    Exit(A.d <> 0);
  RelD := Abs(A.d - B.d) / Abs(B.d);
  Result := RelD > TOPK_D_TOLERANCE;
end;

function DistinctTopK(const Particles: TParticleArray; K: Integer;
  const ElementNames: TArray<string>): TArray<Integer>;
var
  Order: TArray<Integer>;
  Accepted: TArray<Integer>;
  i, j, Idx: Integer;
  Keep: Boolean;
begin
  SetLength(Result, 0);
  if (K <= 0) or (Length(Particles) = 0) then
    Exit;

  SetLength(Order, Length(Particles));
  for i := 0 to High(Order) do
    Order[i] := i;

  // The PSO minimises, so ascending PBestFoM is best first. Ties keep the
  // original swarm order, so the same swarm always yields the same list.
  TArray.Sort<Integer>(Order, TComparer<Integer>.Construct(
    function(const A, B: Integer): Integer
    begin
      Result := CompareValue(Particles[A].PBestFoM, Particles[B].PBestFoM);
      if Result = 0 then
        Result := CompareValue(A, B);
    end));

  SetLength(Accepted, 0);
  for i := 0 to High(Order) do
  begin
    Idx := Order[i];
    Keep := True;
    for j := 0 to High(Accepted) do
      if not GenomesDistinct(Particles[Idx].PBest, Particles[Accepted[j]].PBest,
        ElementNames) then
      begin
        Keep := False;
        Break;
      end;
    if not Keep then
      Continue;
    SetLength(Accepted, Length(Accepted) + 1);
    Accepted[High(Accepted)] := Idx;
    if Length(Accepted) >= K then
      Break;
  end;

  Result := Accepted;
end;

{ ------------------------------------------------------- the optimize job -- }

type
  /// The optimizer's event sink for one run. It lives on the worker thread for
  /// as long as Run does; every event fires on that same thread, so no
  /// synchronisation is needed beyond what TJob already does for itself.
  TOptimizeRunner = class
  private
    FJob: TJob;
    FOptimizer: TUniversalOptimizer;
    FNames: TArray<string>;
    FLastIteration: Integer;
    FErrorMsg: string;
    FHasError: Boolean;
    FCancelSeen: Boolean;
  public
    constructor Create(AJob: TJob; const ANames: TArray<string>);
    procedure HandleIteration(const Data: TIterationData);
    procedure HandleError(const AMessage: string);
    property Optimizer: TUniversalOptimizer read FOptimizer write FOptimizer;
    /// The last iteration number the engine reported, which is how many
    /// iterations actually ran: TOptState.Iteration is stamped with the
    /// configured budget whether the loop reached it or not.
    property LastIteration: Integer read FLastIteration;
    property ErrorMsg: string read FErrorMsg;
    property HasError: Boolean read FHasError;
    /// True when the progress callback saw the cancellation flag and asked the
    /// engine to stop, so the run was cut short and must not report a result.
    property CancelSeen: Boolean read FCancelSeen;
  end;

constructor TOptimizeRunner.Create(AJob: TJob; const ANames: TArray<string>);
begin
  inherited Create;
  FJob := AJob;
  FNames := ANames;
  FLastIteration := 0;
end;

procedure TOptimizeRunner.HandleIteration(const Data: TIterationData);
begin
  FLastIteration := Data.Iteration;
  FJob.Progress(Data.Iteration, Data.FoM,
    Format('%s d=%.1f gamma=%.3f N=%d',
      [GenomeKey(Data.BestGenome, FNames), Data.BestGenome.d,
       Data.BestGenome.Gamma, NRound(Data.BestGenome.N)]));
  { The only place the engine hands control back, so the only place the
    cancellation flag can be looked at. }
  if FJob.CancelRequested then
  begin
    FCancelSeen := True;
    if FOptimizer <> nil then
      FOptimizer.Cancel;
  end;
end;

procedure TOptimizeRunner.HandleError(const AMessage: string);
begin
  { Run catches its own exceptions and calls this from inside its except block,
    then returns normally. The message is kept and turned into an EMCPError by
    the caller, after Run has come back. Only the first is kept: a second one
    would be a consequence of the first. }
  if not FHasError then
  begin
    FHasError := True;
    FErrorMsg := AMessage;
  end;
end;

/// The path a client sees: relative to the work directory when it is under it.
function JobRelPath(const Abs: string): string;
begin
  if WorkDir <> nil then
    Result := WorkDir.RelativePath(Abs)
  else
    Result := Abs;
end;

/// {name, lambda, theta_bragg_deg, r_peak, fwhm_deg, valid} per line, the same
/// shape evaluate_lines reports. Caller frees.
function LinesResultJSON(const Lines: array of TXRFLine;
  const Res: TTargetResults): TJSONArray;
var
  i: Integer;
  JLine: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    for i := 0 to High(Lines) do
    begin
      JLine := TJSONObject.Create;
      JLine.AddPair('name', Lines[i].Name);
      JLine.AddPair('lambda', JSONArgs.Num(Lines[i].Lambda));
      if i <= High(Res) then
      begin
        JLine.AddPair('theta_bragg_deg', JSONArgs.Num(Res[i].ThetaBragg));
        JLine.AddPair('r_peak', JSONArgs.Num(Res[i].RPeak));
        JLine.AddPair('fwhm_deg', JSONArgs.Num(Res[i].FWHM));
        JLine.AddPair('valid', TJSONBool.Create(Res[i].Valid));
      end;
      Result.AddElement(JLine);
    end;
  except
    Result.Free;
    raise;
  end;
end;

/// EvaluateStructure over the structure of rank 1, compared with the figure of
/// merit the optimizer reported for the same candidate. '' when they agree.
/// The check is the answer to "does the structure I am shown reproduce the
/// number I am shown", and it is never fatal: a warning is more useful than a
/// failed job.
function ConsistencyWarning(const JStructure: TJSONObject;
  const C: TUniversalConfig; ReportedFoM: Double): string;
var
  S: TFitStructure;
  Info: TStructureInfo;
  Res: TTargetResults;
  Check: Single;
  Scale: Double;
begin
  Result := '';
  try
    S := StructureFromJSON(JStructure, Info);
    Check := EvaluateStructure(S, Info, C.Lines, C.Fitness, Res);
  except
    on E: Exception do
      Exit(Format('The reported structure could not be re-scored: %s', [E.Message]));
  end;
  Scale := Abs(ReportedFoM);
  if Scale < 1E-12 then
    Scale := 1;
  if Abs(Check - ReportedFoM) / Scale > CONSISTENCY_TOLERANCE then
    Result := Format(
      'The structure reported for rank 1 scores %.9g when it is fed back ' +
      'through evaluate_lines, but the optimizer reported %.9g for the genome ' +
      'it came from. Trust the genome; the structure is a report of it.',
      [Check, ReportedFoM]);
end;

procedure RunOptimizeJob(Job: TJob; const Config: TUniversalConfig; TopK: Integer);
var
  C: TUniversalConfig;
  Runner: TOptimizeRunner;
  Opt: TUniversalOptimizer;
  State: TOptState;
  Templates: TTemplateLibrary;
  Names: TArray<string>;
  Densities: TArray<Single>;
  Lambdas: TArray<Single>;
  SubDensity: Single;
  Mixer: TMaterialMixer;
  Fitness: TUniversalFitness;
  IO: TUniversalIO;
  Idxs: TArray<Integer>;
  Ranks: TArray<TGenome>;
  Res: TTargetResults;
  PerElem: TArray<TXRFXElementResult>;
  ConfigPath, ResultsDir, XRFXPath: string;
  Result_, JRank, JFiles, JConfigUsed: TJSONObject;
  JTopK: TJSONArray;
  FoM: Double;
  BestFoM: Double;
  JBestStructure: TJSONObject;
  Warning: string;
  WasConsole, Cancelled: Boolean;
  i, r: Integer;
begin
  if Job = nil then
    raise EMCPError.Create('internal', 'The optimize job body was called without a job');
  if TopK < 1 then
    TopK := 1;
  if TopK > MAX_TOP_K then
    TopK := MAX_TOP_K;

  C := Config;
  ResultsDir := TPath.Combine(Job.Dir, 'results');
  C.OutputDir := ResultsDir;
  TDirectory.CreateDirectory(ResultsDir);

  // The configuration exactly as the run will use it, next to the results the
  // run writes. CreateXRFXPackage copies this file into the package.
  ConfigPath := TPath.Combine(Job.Dir, 'config.json');
  TUniversalIO.SaveConfig(C, ConfigPath);

  Job.MaxIterations := C.Optimizer.Iterations;

  SetLength(Names, Length(C.ElementPool));
  for i := 0 to High(C.ElementPool) do
    Names[i] := C.ElementPool[i];

  Runner := TOptimizeRunner.Create(Job, Names);
  try
    Opt := TUniversalOptimizer.Create(C);
    try
      Runner.Optimizer := Opt;
      Opt.OnIteration := Runner.HandleIteration;
      Opt.OnError := Runner.HandleError;

      { TMaterialMixer.Initialize changes the process working directory while it
        reads, so the whole run is made under the lock. The only other holder is
        evaluate_lines, which takes it for the length of one Initialize. }
      HenkeCwdLock.Acquire;
      { TUniversalIO.LogIteration writes its progress line to standard output
        when the process has a console - which this one does, and standard
        output is the JSON-RPC transport. Nothing in the engine can be told not
        to, so IsConsole is cleared for the length of the run. It is read
        nowhere in the write path of the protocol (WriteLn(Output, ...) does not
        consult it), only by code that decides between a console message and a
        dialog. }
      WasConsole := IsConsole;
      try
        IsConsole := False;
        { The seed, immediately before Run: TUniversalPSO draws every random
          number on this thread, and RandSeed is process-global, which is why
          only one job runs at a time. }
        RandSeed := Job.Seed;
        { BUILD DEPENDENCY - READ THIS BEFORE BUILDING FOR Win64.

          Opt.Run evaluates the population through OmniThreadLibrary's
          Parallel.For. OmniThreadLibrary 3.08 or later is required: earlier
          versions cast code pointers to Cardinal in
          TOmniTaskExecutor.GetMethodAddrAndSignature (OtlTaskControl.pas),
          which under dcc64 truncates a 64-bit pointer, the task pool never
          answers, and Parallel.For waits for ever. The symptom is a job that
          stays at iteration 0 with results\progress.log holding nothing but
          its header - and because this thread is inside HenkeCwdLock and
          TJobManager.Destroy joins the worker without a timeout, the whole
          server then refuses to exit. It is not specific to this server:
          `xrccmd -u`, XRFCalc and the Win64 GUI's LFPSO fit hang the same way.
          Win32 is not affected, which is why the test suite passes either way.
          The shared clone (D:\DelphiProjects\_Libraries\OmniThreadLibrary) is
          checked out at tag release-3.08, which carries upstream's fix
          (commit 220e9d03). See CLAUDE.md (Dependencies) and XRC_MCP\README.md. }
        Opt.Run;
      finally
        IsConsole := WasConsole;
        HenkeCwdLock.Release;
      end;

      if Runner.HasError then
        raise EMCPError.Create('optimizer_error', Runner.ErrorMsg,
          JobRelPath(ConfigPath));

      { A run that was asked to stop leaves no result: the job ends cancelled
        and what the engine wrote stays in the job folder. A cancel that landed
        after the last progress report was never acted on, so that run finished
        and keeps its answer. }
      if Runner.CancelSeen then
        Exit;

      State := Opt.FinalState;
      if State.Particles = nil then
        raise EMCPError.Create('optimizer_error',
          'The optimizer returned without a final state');

      Templates := Opt.FinalTemplates;
      Names := Opt.FinalInfo.ElementNames;
      Densities := Opt.FinalInfo.ElementDensities;
      SubDensity := Opt.FinalInfo.SubstrateDensity;
    finally
      Opt.Free;
    end;

    { Rank 1 is the optimizer's all-time best, which is not necessarily an entry
      of the final swarm array; DistinctTopK ranks the swarm and cannot see it,
      so the alternatives are filtered against it here with the same rule. }
    SetLength(Ranks, 1);
    Ranks[0] := State.ABest;
    { A couple more than asked for: the first entry the swarm offers is normally
      ABest itself, and any other that is not distinct from it is dropped below,
      so asking for exactly TopK could come back short for no good reason. }
    Idxs := DistinctTopK(State.Particles, TopK + 2, Names);
    for i := 0 to High(Idxs) do
    begin
      if Length(Ranks) >= TopK then
        Break;
      if GenomesDistinct(State.Particles[Idxs[i]].PBest, State.ABest, Names) then
      begin
        SetLength(Ranks, Length(Ranks) + 1);
        Ranks[High(Ranks)] := State.Particles[Idxs[i]].PBest;
      end;
    end;

    SetLength(Lambdas, Length(C.Lines));
    for i := 0 to High(C.Lines) do
      Lambdas[i] := C.Lines[i].Lambda;

    Cancelled := False;
    Result_ := TJSONObject.Create;
    try
      JTopK := TJSONArray.Create;
      Result_.AddPair('top_k', JTopK);
      BestFoM := 0;
      JBestStructure := nil;

      { One mixer and one fitness for every rank: they are the run's own, rebuilt
        from the element list and the templates the run ended with, so a genome
        scores here exactly what it scored inside Run. }
      Mixer := TMaterialMixer.Create;
      try
        HenkeCwdLock.Acquire;
        try
          Mixer.Initialize(Names, Lambdas, C.Substrate, C.HenkePath);
        finally
          HenkeCwdLock.Release;
        end;

        Fitness := TUniversalFitness.Create(Mixer, C, Templates);
        try
          IO := TUniversalIO.Create;
          try
            for r := 0 to High(Ranks) do
            begin
              { Packaging a rank writes a zip; a cancel that arrives here is acted
                on rather than made to wait for all of them. }
              if Job.CancelRequested then
              begin
                Cancelled := True;
                Break;
              end;

              SetLength(Res, 0);
              // Evaluate returns the negated figure of merit: the PSO minimises.
              FoM := -Fitness.Evaluate(Ranks[r], Res);

              JRank := TJSONObject.Create;
              JTopK.AddElement(JRank);
              JRank.AddPair('rank', TJSONNumber.Create(r + 1));
              JRank.AddPair('fom', JSONArgs.Num(FoM));
              JRank.AddPair('genome', GenomeToJSON(Ranks[r], Names));
              JRank.AddPair('structure',
                GenomeToStructure(Ranks[r], C, Templates, Names, Densities, SubDensity));
              JRank.AddPair('lines', LinesResultJSON(C.Lines, Res));

              SetLength(PerElem, Length(C.Lines));
              for i := 0 to High(C.Lines) do
              begin
                // Cleared, not overwritten: the array is reused for every rank and
                // a line without a result would otherwise keep the last rank's.
                PerElem[i] := Default(TXRFXElementResult);
                PerElem[i].Line := C.Lines[i].Name;
                if i <= High(Res) then
                begin
                  PerElem[i].PeakR := Res[i].RPeak;
                  PerElem[i].FWHM := Res[i].FWHM;
                end;
              end;

              { CreateXRFXPackage zips the whole results folder, and the structure
                file in it is whatever the last writer left there - the winner's,
                as Run wrote it. Rewritten here for the rank about to be packaged,
                so that XRFCalc shows the stack the manifest describes. Rank 1's
                is put back after the loop, so the folder on disk stays the
                winner's. }
              IO.SaveXRCStructure(C, Ranks[r], Mixer, Templates, ResultsDir);

              XRFXPath := TPath.Combine(Job.Dir, Format('rank_%d%s', [r + 1, XRFX_EXT]));
              CreateXRFXPackage(C, Ranks[r], FoM, PerElem, ResultsDir, ConfigPath,
                XRFXPath);
              JRank.AddPair('xrfx', JobRelPath(XRFXPath));
              JRank.AddPair('note', XRFX_SHARED_RESULTS_NOTE);

              if r = 0 then
              begin
                BestFoM := FoM;
                JBestStructure := JRank.GetValue('structure') as TJSONObject;
                Result_.AddPair('best', JRank.Clone as TJSONObject);
              end;
            end;

            { The folder is the run's own output, so it ends as the winner's
              even though the packages needed it to change under them. }
            IO.SaveXRCStructure(C, Ranks[0], Mixer, Templates, ResultsDir);
          finally
            IO.Free;
          end;
        finally
          Fitness.Free;
        end;
      finally
        Mixer.Free;
      end;

      Result_.AddPair('job_id', Job.Id);
      Result_.AddPair('seed', TJSONNumber.Create(Job.Seed));
      JConfigUsed := ConfigToJSON(C);
      Result_.AddPair('config_used', JConfigUsed);
      { ConfigToJSON echoes the template library as the absolute path the engine
        opened; a client only ever sees work-directory-relative paths, and the
        top-level template_file already reports one. }
      if JConfigUsed.FindValue('template_file') <> nil then
        JConfigUsed.RemovePair('template_file').Free;
      if C.TemplatePath = '' then
        JConfigUsed.AddPair('template_file', TJSONNull.Create)
      else
        JConfigUsed.AddPair('template_file', JobRelPath(C.TemplatePath));
      if C.TemplatePath = '' then
        Result_.AddPair('template_file', TJSONNull.Create)
      else
        Result_.AddPair('template_file', JobRelPath(C.TemplatePath));
      Result_.AddPair('iterations_run', TJSONNumber.Create(Runner.LastIteration));
      Result_.AddPair('elapsed_s', JSONArgs.Num(Job.ElapsedMs / 1000));
      Result_.AddPair('top_k_rule', TOP_K_RULE);

      JFiles := TJSONObject.Create;
      Result_.AddPair('files', JFiles);
      JFiles.AddPair('progress_log', JobRelPath(TPath.Combine(ResultsDir, 'progress.log')));
      JFiles.AddPair('checkpoint', JobRelPath(TPath.Combine(ResultsDir, 'checkpoint.json')));
      JFiles.AddPair('population', JobRelPath(TPath.Combine(ResultsDir, 'population.json')));
      JFiles.AddPair('config', JobRelPath(ConfigPath));

      if not Cancelled then
      begin
        Warning := '';
        { The figure of merit reported for rank 1 is a fresh evaluation of
          ABest, so it must be the number the optimizer itself ended with. If
          the two ever part company the genome is being scored against a
          different mixer or a different fitness, and the whole result is
          suspect - say so rather than let it pass. }
        if Abs(BestFoM - (-State.ABestFoM)) /
           Max(Abs(State.ABestFoM), 1E-12) > CONSISTENCY_TOLERANCE then
          Warning := Format(
            'Rank 1 re-scores as %.9g but the optimizer finished on %.9g. The ' +
            'candidate was evaluated against a different mixer or fitness than ' +
            'the run used; treat every number in this result with suspicion. ',
            [BestFoM, -State.ABestFoM]);
        if JBestStructure <> nil then
          Warning := Warning + ConsistencyWarning(JBestStructure, C, BestFoM);
        if Warning <> '' then
          Result_.AddPair('consistency_warning', Trim(Warning));
      end;
    except
      Result_.Free;
      raise;
    end;

    { The job manager records a body that left a result as finished, so a run
      that was cut short throws its half-built answer away and lets the job end
      cancelled. The files it wrote are still in the job folder. }
    if Cancelled then
      Result_.Free
    else
      Job.ResultObj := Result_;
  finally
    Runner.Free;
  end;
end;

initialization
  HenkeCwdLock := TCriticalSection.Create;

finalization
  HenkeCwdLock.Free;

end.
