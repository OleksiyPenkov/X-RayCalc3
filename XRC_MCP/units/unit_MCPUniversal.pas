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
  unit_MCPStructure;

var
  /// <summary>Serialises TMaterialMixer.Initialize, which changes the process
  /// working directory while it reads the Henke tables. Every call to
  /// Initialize in this server is made while holding it.</summary>
  HenkeCwdLock: TCriticalSection;

/// <summary>The fitness settings a tool starts from when the client gives none:
/// w_R 1, w_FWHM 0.5, R_min_threshold 0.001, unpolarised, no divergence, no
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
/// effective density. Densities are the ones the mixer used, so the structure
/// returned is the structure whose FoM was reported.
/// A degenerate genome (a template sublayer whose gamma reduction eats the whole
/// period) yields a layer of thickness 0, exactly as BuildLayers computes it;
/// such a genome carries the engine's degeneracy penalty and is never a winner.
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

implementation

uses
  System.Math, System.IOUtils, System.Generics.Collections,
  System.Generics.Defaults,
  math_complex,
  cmd_unit_types,
  unit_materials, unit_materials_mix,
  unit_universal_fitness, unit_universal_io, unit_xrf_lines,
  unit_MCPErrors, unit_MCPMaterials, unit_MCPSandbox, unit_MCPUnits;

const
  // TUniversalFitness substitutes these when the configuration says 0.
  DEFAULT_SCAN_POINTS     = 200;
  DEFAULT_SCAN_HALF_RANGE = 5.0;

  THETA_MIN_NOTE =
    'Optimizer dark-zone threshold, not the scan start: a line whose Bragg ' +
    'angle falls below it is penalised, not moved.';

{ --------------------------------------------------------------- defaults -- }

function DefaultFitnessConfig: TFitnessConfig;
begin
  Result := Default(TFitnessConfig);
  Result.wR := 1.0;
  Result.wFWHM := 0.5;
  Result.RMinThreshold := 0.001;
  Result.Polarization := cmd_unit_types.cmSP;
  Result.DeltaTheta := 0;
  Result.ThetaMin := 0;
  Result.wPurity := 1.0;
  Result.ScanPoints := 0;      // 0 = the engine's DEFAULT_SCAN_POINTS
  Result.ScanHalfRange := 0;   // 0 = the engine's DEFAULT_SCAN_HALF_RANGE
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
  if JSONArgs.Has(J, 'polarization') then
    Result.Polarization := ParsePolarizationValue(JSONArgs.ReqStr(J, 'polarization'));

  if Result.RMinThreshold < 0 then
    raise EMCPError.Create('invalid_argument', '"R_min_threshold" must not be negative');
  if Result.DeltaTheta < 0 then
    raise EMCPError.Create('invalid_argument', '"delta_theta" must not be negative');
  if Result.ThetaMin < 0 then
    raise EMCPError.Create('invalid_argument', '"theta_min" must not be negative');
  if Result.ScanPoints < 0 then
    raise EMCPError.Create('invalid_argument', '"scan_points" must not be negative');
  // The scan needs enough points for a peak and its two half-maximum crossings.
  if (Result.ScanPoints > 0) and (Result.ScanPoints < 3) then
    raise EMCPError.Create('invalid_argument', '"scan_points" must be at least 3');
  if Result.ScanHalfRange < 0 then
    raise EMCPError.Create('invalid_argument', '"scan_half_range" must not be negative');
end;

function FitnessConfigToJSON(const F: TFitnessConfig): TJSONObject;
var
  Points: Integer;
  HalfRange: Double;
begin
  // What TUniversalFitness.Create resolved them to, not what was asked for.
  if F.ScanPoints > 0 then
    Points := F.ScanPoints
  else
    Points := DEFAULT_SCAN_POINTS;
  if F.ScanHalfRange > 0 then
    HalfRange := F.ScanHalfRange
  else
    HalfRange := DEFAULT_SCAN_HALF_RANGE;

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
    Result.AddPair('scan_points', TJSONNumber.Create(Points));
    Result.AddPair('scan_half_range', JSONArgs.Num(HalfRange));
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
  DefaultPair(O, 'w_FWHM', NumPair(0.5));
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

/// The template library a configuration should run against. A client that names
/// one gets that file (relative names are resolved inside the sandbox); a client
/// that names none gets the library the server was started with.
function ResolveConfigTemplatePath(const Given: string): string;
begin
  Result := Trim(Given);
  if Result = '' then
    Exit(TemplatesFile);
  if TFile.Exists(Result) then
    Exit;
  if not TPath.IsRelativePath(Result) then
    Exit;
  if WorkDir <> nil then
    Result := WorkDir.ResolvePath(Result, False);
end;

function ConfigFromJSON(const J: TJSONObject; const OutputDir: string): TUniversalConfig;
var
  N: TJSONObject;
  Lines: TArray<TXRFLine>;
  Arr: TJSONArray;
  Obj: TJSONObject;
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
    if N.FindValue('lines') <> nil then
      Arr := JSONArgs.OptArr(N, 'lines')
    else
      Arr := JSONArgs.OptArr(N, 'targets');
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

    FillStructureDefaults(SectionOf(N, 'structure'));
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
      HenkeCwdLock.Acquire;
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

initialization
  HenkeCwdLock := TCriticalSection.Create;

finalization
  HenkeCwdLock.Free;

end.
