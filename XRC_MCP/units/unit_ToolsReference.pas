unit unit_ToolsReference;

(* Reference tools: the four calls an agent makes before it calculates anything.

   describe_server is the entry point. It answers, in one round trip, every
   question the requirements say a client must not have to guess: which build
   this is, which Henke tables it is reading, what the units are, which
   parameters can be fitted and which cannot, where the work directory is, and
   what the other tools are called. list_materials, optical_constants and
   list_templates then let the agent check a material before it puts it in a
   structure. *)

interface

uses unit_MCPTools;

procedure RegisterReferenceTools(Registry: TToolRegistry);

implementation

uses
  System.SysUtils, System.JSON,
  unit_universal_types, unit_universal_templates,
  unit_MCPVersion, unit_MCPErrors, unit_MCPUnits, unit_MCPSandbox,
  unit_MCPMaterials, unit_MCPUniversal, unit_MCPFit;

const
  // Reported by describe_server.limits. The values are the requirements'
  // ceilings; the units that enforce them cite the same numbers.
  MAX_LAYERS         = 20000;
  MAX_POINTS         = 100000;
  MAX_INLINE_POINTS  = 2000;
  MAX_JOBS_QUEUED    = 16;
  JOBS_CONCURRENT    = 1;

  MATERIAL_SYNTAX =
    'Henke table base name, case-insensitive (Ru, C, B4C, SiO2, RuB2, ...). ' +
    'list_materials enumerates them. Composition-mixing strings such as W0.7Si0.3 ' +
    'are not supported in v1.';

  STRUCTURE_ORDER =
    'stacks are listed from substrate to surface; within a stack, layers are ' +
    'ordered from the surface downwards - layers[0] is nearest the surface (under ' +
    'the cap), the last entry is nearest the substrate; cap is the top layer; buffer ' +
    'sits between substrate and the first stack';

  FIT_ENGINE = 'GUI LFPSO (TLFPSO_Periodic / TLFPSO_Poly)';

  { The definition lives in the unit that computes it, so describe_server and
    every fit_xrr result can never describe two different chi-squareds. }
  FIT_CHI2 = FIT_CHI2_DEFINITION;

  FIT_FREE_PARAMETERS =
    'layer thickness/sigma/density only. The GUI engine keeps the substrate fixed ' +
    '(TLFPSO_BASE.FillModel copies Subs.P verbatim; only stack layers are in the ' +
    'particle vector), so substrate sigma and density cannot be fitted - and the ' +
    'substrate density is ALWAYS the Henke bulk value, because TLayeredModel computes ' +
    'the substrate permittivity from the table and ignores a density supplied for it. ' +
    'The engine has no scale, background or resolution parameters either; asking for ' +
    'any of them is refused with error not_fittable.';

  { The one rule, kept in the unit that applies it: DistinctTopK is what
    optimize_mirror ranks its candidates with, and describe_server must not
    describe a different one. }
  FIT_TOP_K_RULE = TOP_K_RULE;

  ENGINE_DESCRIPTION =
    'X-Ray Calc 3 (Shared/Math, XRayCalc3/LFPSO, Shared/Universal) compiled into this binary';

  // Every error code a tool of this server can return, so a client can branch
  // on them without scraping messages.
  ERROR_CODES: array [0 .. 18] of string = (
    'invalid_argument', 'invalid_request', 'tool_not_found', 'path_outside_workdir',
    'inbox_readonly', 'not_found', 'invalid_structure', 'unknown_material', 'not_fittable',
    'already_exists', 'unsupported_project', 'job_unknown', 'job_not_finished',
    'job_failed', 'job_cancelled', 'too_many_jobs', 'optimizer_error', 'server_busy', 'internal');

function StringArraySchema: TJSONObject;
var
  Items: TJSONObject;
begin
  Items := TJSONObject.Create;
  Items.AddPair('type', 'string');
  Result := ArraySchema(Items);
end;

function InvariantFloat(const V: Double): string;
begin
  Result := FloatToStr(V, TFormatSettings.Invariant);
end;

{ ---------------- describe_server ---------------- }

function ServerSection: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('name', 'xraca');
    Result.AddPair('version', ServerVersionString);
    Result.AddPair('git_revision', GitRevision);
    Result.AddPair('engine', ENGINE_DESCRIPTION);
    Result.AddPair('xraycalc3_exe_version', EngineVersionString);
  except
    Result.Free;
    raise;
  end;
end;

function UnitsSection: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('length', 'angstrom');
    Result.AddPair('density', 'g/cm3');
    Result.AddPair('angle', 'degrees, theta (grazing incidence, NOT 2theta)');
    Result.AddPair('energy', 'eV, lambda = ' + InvariantFloat(HC_EV_ANGSTROM) + ' / E');
    // The engines interpolate the Henke tables at E = math_globals.H / lambda,
    // which is not the same constant. Both are reported rather than unified.
    Result.AddPair('engine_table_constant',
      InvariantFloat(ENGINE_HC) + ' (math_globals.H, Henke interpolation only)');
    Result.AddPair('numeric_precision', 'Numeric results are rounded to 6 significant digits.');
  except
    Result.Free;
    raise;
  end;
end;

function LimitsSection: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('max_layers', TJSONNumber.Create(MAX_LAYERS));
    Result.AddPair('max_points', TJSONNumber.Create(MAX_POINTS));
    Result.AddPair('max_inline_points', TJSONNumber.Create(MAX_INLINE_POINTS));
    Result.AddPair('max_jobs_queued', TJSONNumber.Create(MAX_JOBS_QUEUED));
    Result.AddPair('jobs_concurrent', TJSONNumber.Create(JOBS_CONCURRENT));
    Result.AddPair('max_lines', TJSONNumber.Create(MAX_LINES));
    Result.AddPair('max_pool_elements', TJSONNumber.Create(MAX_POOL_ELEMENTS));
  except
    Result.Free;
    raise;
  end;
end;

function WorkDirSection: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    if WorkDir <> nil then
      Result.AddPair('root', WorkDir.Root)
    else
      Result.AddPair('root', TJSONNull.Create);
    Result.AddPair('projects', 'projects\');
    Result.AddPair('jobs', 'jobs\<job_id>\');
    Result.AddPair('inbox', 'inbox\<specimen>\ (read-only)');
    Result.AddPair('log', 'log\calls.jsonl');
  except
    Result.Free;
    raise;
  end;
end;

function FitSection: TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('engine', FIT_ENGINE);
    Result.AddPair('chi2', FIT_CHI2);
    Result.AddPair('free_parameters', FIT_FREE_PARAMETERS);
    Result.AddPair('top_k_rule', FIT_TOP_K_RULE);
  except
    Result.Free;
    raise;
  end;
end;

function ErrorsSection: TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;
  try
    for I := Low(ERROR_CODES) to High(ERROR_CODES) do
      Result.Add(ERROR_CODES[I]);
  except
    Result.Free;
    raise;
  end;
end;

function DescribeServer(Registry: TToolRegistry): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('server', ServerSection);
    Result.AddPair('henke', HenkeSummary);
    Result.AddPair('xrf_lines_file', LinesFile);
    if TemplatesFile = '' then
      Result.AddPair('templates_file', TJSONNull.Create)
    else
      Result.AddPair('templates_file', TemplatesFile);
    Result.AddPair('units', UnitsSection);
    Result.AddPair('material_syntax', MATERIAL_SYNTAX);
    Result.AddPair('structure_order', STRUCTURE_ORDER);
    Result.AddPair('limits', LimitsSection);
    Result.AddPair('workdir', WorkDirSection);
    Result.AddPair('fit', FitSection);
    Result.AddPair('errors', ErrorsSection);
    Result.AddPair('tools', Registry.Summaries);
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------- list_materials ---------------- }

function FormulaJSON(const Entry: TMaterialEntry): TJSONValue;
var
  Obj: TJSONObject;
  I: Integer;
begin
  if not Entry.Parsed then
    Exit(TJSONNull.Create);
  Obj := TJSONObject.Create;
  try
    for I := 0 to High(Entry.Parts) do
      Obj.AddPair(Entry.Parts[I].Symbol, JSONArgs.Num(Entry.Parts[I].Count));
  except
    Obj.Free;
    raise;
  end;
  Result := Obj;
end;

function ListMaterialsResult(const Params: TJSONObject): TJSONObject;
var
  Filter: TArray<string>;
  JFilter: TJSONArray;
  Entries: TArray<TMaterialEntry>;
  Arr: TJSONArray;
  Obj: TJSONObject;
  I: Integer;
begin
  SetLength(Filter, 0);
  JFilter := JSONArgs.OptArr(Params, 'filter');
  if JFilter <> nil then
  begin
    SetLength(Filter, JFilter.Count);
    for I := 0 to JFilter.Count - 1 do
      Filter[I] := JFilter.Items[I].Value;
  end;

  Entries := ListMaterials(Filter);

  Result := TJSONObject.Create;
  try
    Result.AddPair('count', TJSONNumber.Create(Length(Entries)));
    Arr := TJSONArray.Create;
    Result.AddPair('materials', Arr);
    for I := 0 to High(Entries) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('name', Entries[I].Name);
      Obj.AddPair('formula', FormulaJSON(Entries[I]));
      Obj.AddPair('is_element', TJSONBool.Create(Entries[I].IsElement));
      Obj.AddPair('bulk_density', JSONArgs.Num(Entries[I].BulkDensity));
      Obj.AddPair('atomic_mass', JSONArgs.Num(Entries[I].AtomicMass));
      Arr.AddElement(Obj);
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------- optical_constants ---------------- }

function OpticalConstantsResult(const Params: TJSONObject): TJSONObject;
var
  Material, Canonical: string;
  Lambda, Density, Window, EeV: Double;
  DensityUsed, Delta, Beta: Double;
begin
  Material := JSONArgs.ReqStr(Params, 'material');
  if not ResolveHenkeName(Material, Canonical) then
    raise EMCPError.Create('unknown_material',
      Format('No Henke table for material "%s"', [Material]),
      'list_materials enumerates the available tables');

  Lambda := GetLambdaArg(Params);
  // An absent density means "the bulk value from the table header". A density
  // that is present has to be a real one: 0 supplied on purpose is far more
  // likely a bug in the caller than a request for the bulk value, and it would
  // otherwise come back as a plausible-looking delta of zero.
  Density := 0;
  if JSONArgs.Has(Params, 'density') then
  begin
    Density := JSONArgs.OptFloat(Params, 'density', 0);
    if Density <= 0 then
      raise EMCPError.Create('invalid_argument',
        '"density" must be greater than zero g/cm^3',
        'omit "density" to use the bulk value from the Henke table header');
  end;
  Window := JSONArgs.OptFloat(Params, 'edge_window', DEFAULT_EDGE_WINDOW);
  if Window < 0 then
    raise EMCPError.Create('invalid_argument',
      '"edge_window" must not be negative (it is a fraction of the photon energy)');
  EeV := LambdaToEnergy(Lambda);

  if not OpticalConstants(Canonical, Lambda, Density, DensityUsed, Delta, Beta) then
    raise EMCPError.Create('unknown_material',
      Format('No Henke table for material "%s"', [Material]));

  Result := TJSONObject.Create;
  try
    Result.AddPair('material', Canonical);
    Result.AddPair('lambda_used', JSONArgs.Num(Lambda));
    Result.AddPair('energy_eV', JSONArgs.Num(EeV));
    Result.AddPair('density_used', JSONArgs.Num(DensityUsed));
    Result.AddPair('delta', JSONArgs.Num(Delta));
    Result.AddPair('beta', JSONArgs.Num(Beta));
    Result.AddPair('n', JSONArgs.Num(1 - Delta));
    Result.AddPair('k', JSONArgs.Num(Beta));
    Result.AddPair('edges', NearestEdges(Canonical, EeV, Window));
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------- list_templates ---------------- }

function ThicknessJSON(const Layer: TTemplateLayer): TJSONValue;
begin
  case Layer.ThicknessType of
    ttGamma: Result := TJSONString.Create('gamma');
    ttOneMinusGamma: Result := TJSONString.Create('1-gamma');
  else
    Result := JSONArgs.Num(Layer.FixedThickness);
  end;
end;

/// <summary>True when both materials of a "A/B" template key are in the pool.
/// An empty pool matches every template.</summary>
function TemplateInPool(const Key: string; const Pool: TArray<string>): Boolean;
var
  SlashPos, I: Integer;
  Mat1, Mat2: string;
  Has1, Has2: Boolean;
begin
  if Length(Pool) = 0 then
    Exit(True);
  SlashPos := Pos('/', Key);
  if SlashPos <= 0 then
    Exit(False);
  Mat1 := Copy(Key, 1, SlashPos - 1);
  Mat2 := Copy(Key, SlashPos + 1, MaxInt);
  Has1 := False;
  Has2 := False;
  for I := 0 to High(Pool) do
  begin
    if SameText(Pool[I], Mat1) then Has1 := True;
    if SameText(Pool[I], Mat2) then Has2 := True;
  end;
  Result := Has1 and Has2;
end;

function ListTemplatesResult(const Params: TJSONObject): TJSONObject;
var
  Pool: TArray<string>;
  JPool: TJSONArray;
  Lib: TTemplateLibrary;
  Arr, Layers, Caps: TJSONArray;
  Obj, LayerObj, CapObj: TJSONObject;
  I, J: Integer;
begin
  SetLength(Pool, 0);
  JPool := JSONArgs.OptArr(Params, 'pool');
  if JPool <> nil then
  begin
    SetLength(Pool, JPool.Count);
    for I := 0 to JPool.Count - 1 do
      Pool[I] := JPool.Items[I].Value;
  end;

  if TemplatesFile = '' then
    SetLength(Lib, 0)
  else
    Lib := LoadTemplates(TemplatesFile);

  Result := TJSONObject.Create;
  try
    Arr := TJSONArray.Create;
    Result.AddPair('templates', Arr);
    for I := 0 to High(Lib) do
    begin
      if not TemplateInPool(Lib[I].Key, Pool) then
        Continue;

      Obj := TJSONObject.Create;
      Arr.AddElement(Obj);
      Obj.AddPair('key', Lib[I].Key);
      Obj.AddPair('description', Lib[I].Description);

      Layers := TJSONArray.Create;
      Obj.AddPair('layers', Layers);
      for J := 0 to High(Lib[I].Layers) do
      begin
        LayerObj := TJSONObject.Create;
        LayerObj.AddPair('material', Lib[I].Layers[J].Material);
        LayerObj.AddPair('thickness', ThicknessJSON(Lib[I].Layers[J]));
        LayerObj.AddPair('sigma', JSONArgs.Num(Lib[I].Layers[J].Sigma));
        LayerObj.AddPair('density', JSONArgs.Num(Lib[I].Layers[J].Density));
        Layers.AddElement(LayerObj);
      end;

      Caps := TJSONArray.Create;
      Obj.AddPair('caps', Caps);
      for J := 0 to High(Lib[I].Caps) do
      begin
        CapObj := TJSONObject.Create;
        CapObj.AddPair('name', Lib[I].Caps[J].Name);
        CapObj.AddPair('material', Lib[I].Caps[J].Material);
        CapObj.AddPair('sigma', JSONArgs.Num(Lib[I].Caps[J].Sigma));
        CapObj.AddPair('density', JSONArgs.Num(Lib[I].Caps[J].Density));
        CapObj.AddPair('thickness_min', JSONArgs.Num(Lib[I].Caps[J].ThicknessRange.Min));
        CapObj.AddPair('thickness_max', JSONArgs.Num(Lib[I].Caps[J].ThicknessRange.Max));
        Caps.AddElement(CapObj);
      end;

      Obj.AddPair('gamma_reduction', JSONArgs.Num(Lib[I].GammaReduction));
      Obj.AddPair('one_minus_gamma_reduction', JSONArgs.Num(Lib[I].OneMinusGammaReduction));
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------- registration ---------------- }

procedure RegisterReferenceTools(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Registry.Register('describe_server',
    'Describes this server: what it is, how it was built and what it can do. ' +
    'Call it first: it reports the server version and git revision, the Henke table ' +
    'directory in use, the unit conventions (Angstrom, g/cm3, theta in degrees - not ' +
    '2theta - and eV), the material-name syntax, the substrate-to-surface structure ' +
    'order, the size limits, the work-directory layout, which fit parameters exist, ' +
    'the error codes it can return and a one-line summary of every other tool.',
    SchemaObject([]),
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := DescribeServer(Registry);
    end);

  Schema := SchemaObject([]);
  AddRefProp(Schema, 'filter',
    'Element symbols, for example ["Ru","C"]. Only tables whose formula consists ' +
    'entirely of these elements are returned; tables whose name does not decompose ' +
    'into element symbols are dropped. Omit or leave empty for every table.',
    StringArraySchema);
  Registry.Register('list_materials',
    'Lists the Henke tables this server can use, optionally filtered by an element pool. ' +
    'Each entry gives the table name to put in a structure, its formula, and the bulk ' +
    'density (g/cm3) and atomic mass (g/mol) stored in the table header. Material names ' +
    'are matched case-insensitively; there is no composition-mixing syntax.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := ListMaterialsResult(Params);
    end);

  Schema := SchemaObject(['material']);
  AddProp(Schema, 'material', 'string',
    'Henke table name, case-insensitive (for example "Ru", "B4C"). See list_materials.');
  AddProp(Schema, 'lambda', 'number',
    'Wavelength in Angstrom (A). Give either this or "energy", not both.');
  AddProp(Schema, 'energy', 'number',
    'Photon energy in eV (lambda = 12398.42 / E). Give either this or "lambda", not both.');
  AddProp(Schema, 'density', 'number',
    'Density in g/cm3. Omit to use the bulk density from the Henke table header; ' +
    'the value actually used is echoed back as density_used.');
  AddProp(Schema, 'edge_window', 'number',
    'Half-width of the absorption-edge search window as a fraction of the photon ' +
    'energy (dimensionless, default 0.25 = +/-25 %). Edges of the constituent ' +
    'elements inside the window are returned nearest first.');
  Registry.Register('optical_constants',
    'Optical constants of one material at one wavelength: delta and beta of ' +
    'n = 1 - delta + i*beta, plus n and k and the nearby absorption edges. ' +
    'Unknown materials are refused with error unknown_material.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := OpticalConstantsResult(Params);
    end);

  Schema := SchemaObject([]);
  AddRefProp(Schema, 'pool',
    'Element or material symbols, for example ["Ru","C"]. Only templates whose two ' +
    'key materials are both in the pool are returned (case-insensitive). Omit or ' +
    'leave empty for every template.',
    StringArraySchema);
  Registry.Register('list_templates',
    'Lists the multilayer design templates this server was started with, optionally ' +
    'filtered by a material pool. A template describes one period: its sub-layers with ' +
    'their thickness rule ("gamma", "1-gamma" or a fixed value in Angstrom), roughness ' +
    'sigma (A) and density (g/cm3), plus the capping-layer variants and the thickness ' +
    '(A) each interlayer removes from the gamma and 1-gamma layers. The array is empty ' +
    'when the server was started without a template file (describe_server.templates_file ' +
    'is then null).',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := ListTemplatesResult(Params);
    end);
end;

end.
