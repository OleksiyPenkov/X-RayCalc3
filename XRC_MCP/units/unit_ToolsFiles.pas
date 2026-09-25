(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_ToolsFiles;

(* The file tools: the measurement inbox and the .xrcx projects.

   Both inbox tools are read-only, and deliberately so: inbox\ holds the
   experimental data, the one thing in the work directory the server has no
   business changing. list_measurements says what is there and what its SHA-256
   is, get_measurement hands the parsed curve back, and neither ever opens a
   file for writing.

   The three project tools are the other side of that: projects\ is the one
   place the server writes files a person opens by hand. save_project computes
   the model curve and writes a .xrcx that the X-Ray Calc 3 GUI opens with no
   conversion step; load_project reads one back; list_projects says what is
   there. The file format lives in unit_MCPProjectFile. *)

interface

uses System.JSON, unit_MCPTools;

procedure RegisterFileTools(Registry: TToolRegistry);

/// <summary>The assess_xrr tool: reads the measurement from the inbox, the
/// design and the instrument numbers from Params, and returns the assessment
/// (unit_MCPAssess) with the measurement's identity in front of it. Caller
/// frees. Here rather than in unit_MCPAssess so that the assessment itself
/// stays free of the inbox and the sandbox, and the GUI can share it.</summary>
function AssessMeasurementJSON(const Params: TJSONObject): TJSONObject;

implementation

uses
  System.SysUtils, System.IOUtils, System.Types, System.StrUtils,
  System.Generics.Collections, System.Generics.Defaults,
  unit_Types,
  unit_MCPErrors, unit_MCPInbox, unit_MCPSandbox, unit_MCPUnits,
  unit_MCPStructure, unit_MCPCalc, unit_MCPProjectFile, unit_MCPAssess,
  unit_MCPFit, unit_consts;

{ ----------------------------------------------------------- assess_xrr -- }

function AssessMeasurementJSON(const Params: TJSONObject): TJSONObject;
var
  M: TMeasurement;
  Inp: TAssessInput;
  JS: TJSONObject;
  Bad: string;
  i: Integer;
begin
  M := LoadMeasurement(JSONArgs.ReqStr(Params, 'measurement_id'), 0);
  try
    if M.IsXRDML then
      Inp := AssessInputFromScan(M.XRDML)     // the raw facts, the curve in theta
    else
    begin
      Inp := DefaultAssessInput;
      Inp.Curve := M.Curve;
      Inp.TwoThetaScan := M.Converted2Theta;
    end;

    { the same rule as fit_xrr: "lambda" or "energy" from the arguments,
      the measurement's own wavelength (the file's, else meta.json's) when
      neither is given }
    Inp.Lambda := GetLambdaArg(Params, 'lambda', 'energy', True, M.Meta.Lambda);
    if (Params.GetValue('lambda') <> nil) or (Params.GetValue('energy') <> nil) then
      Inp.LambdaSource := 'argument'
    else
      Inp.LambdaSource := M.LambdaSource;

    JS := JSONArgs.OptObj(Params, 'structure');
    if JS <> nil then
    begin
      { a bare substrate ("stacks": []) is a design here: a glass reference
        is measured for its critical angle and its plateau }
      Inp.Structure := StructureFromJSON(JS, Inp.Info, True);
      Bad := ValidateMaterials(Inp.Structure);
      if Bad <> '' then
        raise EMCPError.Create('unknown_material',
          Format('No Henke table for material "%s"', [Bad]),
          'list_materials enumerates the names this server knows');
      Inp.HasStructure := True;
    end;

    Inp.Resolution := JSONArgs.OptFloat(Params, 'resolution', DEF_RESOLUTION);
    Inp.DetectorMaxCps := JSONArgs.OptFloat(Params, 'detector_max_cps', 0);
    Inp.SampleLengthMm := JSONArgs.OptFloat(Params, 'sample_length_mm', 0);
    Inp.BeamWidthMm := JSONArgs.OptFloat(Params, 'beam_width_mm', 0);
    if (Inp.Resolution < 0) or (Inp.DetectorMaxCps < 0) or (Inp.SampleLengthMm < 0) or
       (Inp.BeamWidthMm < 0) then
      raise EMCPError.Create('invalid_argument',
        '"resolution", "detector_max_cps", "sample_length_mm" and "beam_width_mm" cannot be negative');
    Inp.VisibleFactor := JSONArgs.OptFloat(Params, 'order_visible_factor', Inp.VisibleFactor);
    Inp.MinPointsPerFringe := JSONArgs.OptFloat(Params, 'min_points_per_fringe',
                                                Inp.MinPointsPerFringe);

    Result := TJSONObject.Create;
    try
      Result.AddPair('measurement_id', M.Id);
      Result.AddPair('file', WorkDir.RelativePath(M.Path));
      Result.AddPair('format', IfThen(M.IsXRDML, 'xrdml', 'text'));
      AssessInto(Inp, Result);
    except
      Result.Free;
      raise;
    end;
  finally
    M.Meta.Raw.Free;
  end;
end;

procedure RegisterInboxTools(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Schema := SchemaObject([]);
  AddProp(Schema, 'specimen', 'string',
    'List only this specimen folder (exact name, case-insensitive). ' +
    'Omit to list every specimen in the inbox.');
  Registry.Register('list_measurements',
    'Lists the measured curves waiting in the inbox. The inbox is one folder per ' +
    'specimen under inbox\, and each file in it is a measurement identified by ' +
    '"<specimen>/<file>" - the measurement_id get_measurement and fit_xrr take. ' +
    'For every file the name, id, size, SHA-256 and last-modified time are ' +
    'reported, together with the contents of the specimen''s meta.json when it ' +
    'has one. A specimen whose meta.json cannot be read is still listed, with ' +
    '"meta": null and a "meta_error" saying what is wrong with it, so that one ' +
    'bad file never hides the rest of the inbox. Files lying loose in inbox\ ' +
    'rather than in a specimen folder have no id and are only counted, as ' +
    '"loose_files". Nothing here is ever written.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := ListMeasurementsJSON(JSONArgs.OptStr(Params, 'specimen', ''));
    end);

  Schema := SchemaObject(['measurement_id']);
  AddProp(Schema, 'measurement_id', 'string',
    'The measurement to read, as "<specimen>/<file>" exactly as list_measurements ' +
    'reports it. The file extension must be .dat, .txt, .xy or .xrdml. A ' +
    '.xrdml file (PANalytical) is read directly: its angle axis (2Theta as ' +
    'scanned, converted to theta here) comes from the file; its wavelength is ' +
    'the one the file implies (the K-Alpha doublet weighted by the file''s ' +
    'ratio when the incident optic passes both lines, 1.541874 A for Cu; ' +
    'kAlpha1 when a monochromator or hybrid mirror selects it); it overrides a ' +
    'lambda in meta.json, which is then reported in "header" but not used, so ' +
    'that a wavelength typed by hand cannot displace the measured one; ' +
    '"lambda_source" says "file: <rule>". Counts are ' +
    'divided by the counting time, a zero count becomes the smallest positive ' +
    'intensity before it, and the curve is normalised to 1 at its maximum; the ' +
    'peak rate (attenuation factors in), the counting time, the detector and its readOutPeriod are ' +
    'in "header", so one count and the detector''s linear range stay ' +
    'recoverable.');
  AddProp(Schema, 'max_points', 'integer',
    'Decimate the curve to at most this many points before returning it ' +
    '(default 2000; minimum 2; first and last points are always kept). ' +
    '"points" is the number in the file and "points_returned" the number returned.');
  Registry.Register('get_measurement',
    'Reads one measured curve from the inbox and returns it as [theta, intensity] ' +
    'pairs. The file is parsed the way the X-Ray Calc 3 GUI parses it: two ' +
    'columns separated by a tab or a space, a comma accepted as the decimal mark, ' +
    'non-numeric lines returned as "header", and a non-positive intensity ' +
    'replaced by the smallest positive one seen so far. When the specimen''s ' +
    'meta.json says "theta_unit": "2theta" every angle is halved, so the curve ' +
    'returned is always theta in degrees, and "converted_from_2theta" says ' +
    'whether that happened; when meta.json does not say, theta is assumed and ' +
    '"theta_unit_assumed" is true. The file is opened read-only and is never modified.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := GetMeasurementJSON(JSONArgs.ReqStr(Params, 'measurement_id'),
        JSONArgs.OptInt(Params, 'max_points', DEFAULT_MAX_POINTS));
    end);

  Schema := SchemaObject(['measurement_id']);
  AddProp(Schema, 'measurement_id', 'string',
    'The measurement to assess, as "<specimen>/<file>" exactly as list_measurements ' +
    'reports it. An .xrdml is read raw, so the counting time, the peak count rate, ' +
    'the detector and the zero counts are known; a two-column .dat/.txt/.xy ' +
    'answers "unknown" for every check that needs one of those.');
  AddRefProp(Schema, 'structure',
    'The design (optional): the same structure object calc_reflectivity takes. With it, ' +
    'the checks that need a period (orders, points per order), a total thickness ' +
    '(points per Kiessig fringe) or a critical angle (total reflection) can answer, ' +
    'and the design''s own reflectivity on the measured range says what the ' +
    'measurement could have shown. Unlike the other tools this one accepts a bare ' +
    'substrate, "stacks": [] - a glass reference - for its critical angle and plateau.',
    StructureSchema);
  AddProp(Schema, 'lambda', 'number',
    'Wavelength in Angstrom for the design; defaults to the file''s (an .xrdml) or ' +
    'meta.json''s. Required with "structure" when neither has one. "energy" in eV ' +
    'is accepted instead, as in fit_xrr.');
  AddProp(Schema, 'energy', 'number', 'Photon energy in eV, in place of "lambda".');
  AddProp(Schema, 'resolution', 'number',
    'Theta FWHM in degrees the design''s model is convolved with, so that it is the ' +
    'curve a fit would compare against (default fit_xrr''s 0.015). 0 for none.');
  AddProp(Schema, 'detector_max_cps', 'number',
    'The detector''s linear count-rate limit in counts per second, judged against the ' +
    'rate the detector itself saw (attenuation factors out). Without it the counting ' +
    'check reports the peak rate and says "unknown"; no limit is built in.');
  AddProp(Schema, 'sample_length_mm', 'number',
    'The specimen''s length along the beam, mm. With beam_width_mm it places the ' +
    'footprint knee asin(beam / length).');
  AddProp(Schema, 'beam_width_mm', 'number', 'The incident beam''s width, mm.');
  AddProp(Schema, 'order_visible_factor', 'number',
    'An order is visible when it stands this many times above the background ' +
    '(default 3, the fit report''s).');
  AddProp(Schema, 'min_points_per_fringe', 'number',
    'The sampling check warns below this many points per Kiessig fringe (default 3) ' +
    'and fails below 2 whatever is given, for fringes coarser than "resolution"; ' +
    'finer fringes are not measurable at any step and are judged by the points ' +
    'per resolution width instead.');
  Registry.Register('assess_xrr',
    'Says whether a measured XRR curve is worth fitting, before anyone fits it: eight ' +
    'checks on the measurement itself - the peak count rate against the detector''s ' +
    'linear limit, the first Bragg order against the low-angle maximum, whether the ' +
    'scan started below the critical angle, how many orders stand above the ' +
    'background against the design, how much of the scan sits at the background, ' +
    'points per Kiessig fringe and per order, the footprint knee, and the zero counts. ' +
    'Every check is {value, threshold, verdict, why} with the numbers it was made ' +
    'from; the verdict is "unknown" whenever the input it needs is missing (no ' +
    'detector limit, no design, no raw file) and never falls back on a threshold ' +
    'invented here. "summary_text" is one line per check, ready to be filed with the ' +
    'specimen by the client. Every angle is theta in degrees with the file''s 2theta ' +
    'beside it. The file is opened read-only; nothing is written anywhere.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := AssessMeasurementJSON(Params);
    end);
end;

{ ---------------------------------------------------------- project tools -- }

const
  { The calculation defaults of save_project. They are calc_reflectivity's, so
    that the curve stored in a project is the curve calc_reflectivity returns
    for the same structure and the same arguments. }
  DEFAULT_THETA_MIN = 0.05;
  DEFAULT_THETA_MAX = 5.0;
  DEFAULT_POINTS    = 2000;
  DEFAULT_R_MIN     = 1E-7;
  DEFAULT_LAMBDA    = 1.54043;      // Cu K-alpha, the GUI's default

  NAME_EXTRA_CHARS = ['_', '-', '.', ' ', '(', ')', '#'];

  { Windows reserved device names: invalid as a file name with or without an
    extension, and regardless of case. The check is against the part of the
    name before its first '.', which is how Windows itself decides. }
  RESERVED_DEVICE_NAMES: array [0 .. 21] of string = (
    'CON', 'PRN', 'AUX', 'NUL',
    'COM1', 'COM2', 'COM3', 'COM4', 'COM5', 'COM6', 'COM7', 'COM8', 'COM9',
    'LPT1', 'LPT2', 'LPT3', 'LPT4', 'LPT5', 'LPT6', 'LPT7', 'LPT8', 'LPT9');

/// True when S is one of the Windows reserved device names, comparing only
/// the part of S before its first '.' (so 'CON', 'con.xrcx' and
/// 'CON.foo.xrcx' are all reserved, but 'CONsole' is not).
function IsReservedDeviceName(const S: string): Boolean;
var
  Base, R: string;
  P: Integer;
begin
  P := Pos('.', S);
  if P > 0 then
    Base := Copy(S, 1, P - 1)
  else
    Base := S;
  Result := False;
  for R in RESERVED_DEVICE_NAMES do
    if SameText(Base, R) then
      Exit(True);
end;

/// The project name without its extension. Accepts [A-Za-z0-9_\-. ()#]+ and
/// nothing else, so no argument can name a directory, walk out of projects\ or
/// carry a character Windows refuses. Also refuses a Windows reserved device
/// name (CON, PRN, AUX, NUL, COM1-9, LPT1-9) and a name whose base part ends
/// in '.' or a space, both of which Windows silently mangles.
function ValidateProjectName(const Raw: string): string;
var
  S: string;
  C: Char;
begin
  S := Trim(Raw);
  if S = '' then
    raise EMCPError.Create('invalid_argument', '"name" must not be empty');
  for C in S do
    if not (CharInSet(C, ['A' .. 'Z', 'a' .. 'z', '0' .. '9']) or CharInSet(C, NAME_EXTRA_CHARS)) then
      raise EMCPError.Create('invalid_argument',
        'A project name may hold only letters, digits and "_-. ()#"', Raw);
  if SameText(TPath.GetExtension(S), PROJECT_EXT) then
    S := Copy(S, 1, Length(S) - Length(PROJECT_EXT));
  if (S <> '') and CharInSet(S[Length(S)], ['.', ' ']) then
    raise EMCPError.Create('invalid_argument',
      'A project name may not end in "." or a space', Raw);
  if Trim(S) = '' then
    raise EMCPError.Create('invalid_argument', '"name" must not be empty', Raw);
  if IsReservedDeviceName(S) then
    raise EMCPError.Create('invalid_argument',
      Format('"%s" is a Windows reserved device name', [S]), Raw);
  Result := S;
end;

function ParameterName(const Subj: TParameterType): string;
begin
  case Subj of
    ptH: Result := 'thickness';
    ptS: Result := 'sigma';
  else
    Result := 'density';
  end;
end;

/// The data curve named by the tool's "curves" argument, in theta. For a job
/// curve, Proj.Params is also replaced by the parameter block of the job's own
/// fit.xrcx (the engine that ran, its iterations and population, the chi-squared
/// weighting, the resolution width and the range), and FromJob says so; before
/// 2026-09-16 a project saved from a periodic fit carried the GUI defaults
/// instead and opened in X-Ray Calc 3 as an irregular fit of 100 x 1000.
procedure LoadRequestedCurve(const Curves: TJSONObject; var Proj: TXRCXProject;
  out FromJob: Boolean);
var
  MeasId, JobId, JobFile, JobXRCX: string;
  M: TMeasurement;
begin
  FromJob := False;
  if Curves = nil then
    Exit;
  MeasId := Trim(JSONArgs.OptStr(Curves, 'measurement_id', ''));
  JobId := Trim(JSONArgs.OptStr(Curves, 'job_id', ''));

  if (MeasId <> '') and (JobId <> '') then
    raise EMCPError.Create('invalid_argument',
      '"curves" takes either "measurement_id" or "job_id", not both');

  if MeasId <> '' then
  begin
    M := LoadMeasurement(MeasId, 0);       // 0 = the whole curve, no decimation
    try
      Proj.DataCurve := M.Curve;
      Proj.DataTitle := M.Id;
    finally
      M.Meta.Raw.Free;                     // LoadMeasurement hands ownership over
    end;
    Exit;
  end;

  if JobId <> '' then
  begin
    JobFile := WorkDir.ResolvePath(TPath.Combine(TPath.Combine('jobs', JobId), 'measured.dat'), False);
    if not TFile.Exists(JobFile) then
      raise EMCPError.Create('invalid_argument',
        'job curves are embedded by fit_xrr', JobId);
    Proj.DataCurve := ReadCurveText(JobFile);
    Proj.DataTitle := JobId;
    { fit.xrcx is written when the fit finishes; a job still running has only
      its measured curve and the project keeps the defaults. }
    JobXRCX := WorkDir.ResolvePath(TPath.Combine(TPath.Combine('jobs', JobId), 'fit.xrcx'), False);
    if TFile.Exists(JobXRCX) then
    begin
      Proj.Params := ReadXRCX(JobXRCX).Params;
      FromJob := True;
    end;
  end;
end;

/// [FIT] Mode for a project that does not come from a fit job: 1 (periodic)
/// when the structure has a repeating stack, else 0 (irregular) - what the
/// GUI's own fit dialog would pick for it.
function FitModeFor(const S: TFitStructure): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(S.Stacks) do
    if S.Stacks[i].N > 1 then
      Exit(1);
end;

function SaveProjectResult(const Params: TJSONObject): TJSONObject;
var
  Req: TCalcRequest;
  Used: TFitStructure;
  Proj: TXRCXProject;
  Bad, Name, FileName: string;
  FromJob: Boolean;
begin
  Proj := Default(TXRCXProject);
  Proj.Params := DefaultCalcParams;

  Req := Default(TCalcRequest);
  Req.Structure := StructureFromJSON(JSONArgs.ReqObj(Params, 'structure'), Req.Info);

  { The cheap argument checks first: a client that names an existing project
    learns so without waiting for a Henke lookup or a calculation. }
  Name := ValidateProjectName(JSONArgs.ReqStr(Params, 'name'));
  FileName := WorkDir.ResolvePath(TPath.Combine('projects', Name + PROJECT_EXT), True);
  if TFile.Exists(FileName) and not JSONArgs.OptBool(Params, 'overwrite', False) then
    raise EMCPError.Create('already_exists',
      Format('projects\%s%s already exists; pass "overwrite": true to replace it',
        [Name, PROJECT_EXT]),
      WorkDir.RelativePath(FileName));

  Bad := ValidateMaterials(Req.Structure);
  if Bad <> '' then
    raise EMCPError.Create('unknown_material',
      Format('No Henke table for material "%s"', [Bad]),
      'list_materials enumerates the names this server knows');

  { The curve first: a job curve brings the job's parameter block with it,
    which is then the default for everything the client does not say. }
  LoadRequestedCurve(JSONArgs.OptObj(Params, 'curves'), Proj, FromJob);

  if FromJob then
  begin
    Req.Lambda := GetLambdaArg(Params, 'lambda', 'energy', True, Proj.Params.Lambda);
    Req.ThetaMin := JSONArgs.OptFloat(Params, 'theta_min', Proj.Params.ThetaStart);
    Req.ThetaMax := JSONArgs.OptFloat(Params, 'theta_max', Proj.Params.ThetaEnd);
    Req.DeltaTheta := JSONArgs.OptFloat(Params, 'delta_theta', Proj.Params.Width);
    Req.Points := JSONArgs.OptInt(Params, 'points', Proj.Params.Points);
    Req.RMin := Proj.Params.MinLimit;
    if Proj.Params.Polarisation = 0 then
      Req.Polarization := cmS
    else
      Req.Polarization := cmSP;
  end
  else
  begin
    Req.Lambda := GetLambdaArg(Params, 'lambda', 'energy', True, DEFAULT_LAMBDA);
    Req.ThetaMin := JSONArgs.OptFloat(Params, 'theta_min', DEFAULT_THETA_MIN);
    Req.ThetaMax := JSONArgs.OptFloat(Params, 'theta_max', DEFAULT_THETA_MAX);
    Req.DeltaTheta := JSONArgs.OptFloat(Params, 'delta_theta', 0);
    Req.Points := JSONArgs.OptInt(Params, 'points', DEFAULT_POINTS);
    Req.RMin := DEFAULT_R_MIN;
    Req.Polarization := cmS;           // params.dsc says [PARAMS] Polarisation=0
    Proj.Params.FitMode := FitModeFor(Req.Structure);
  end;

  if Req.ThetaMin < 0 then
    raise EMCPError.Create('invalid_argument', '"theta_min" must not be negative');
  if Req.ThetaMax > 90 then
    raise EMCPError.Create('invalid_argument', '"theta_max" must not exceed 90 degrees (theta, not 2theta)');
  if Req.ThetaMax <= Req.ThetaMin then
    raise EMCPError.Create('invalid_argument', '"theta_max" must be greater than "theta_min"');
  if Req.Points < 2 then
    raise EMCPError.Create('invalid_argument', '"points" must be at least 2');
  if Req.Points > MAX_CALC_POINTS then
    raise EMCPError.Create('invalid_argument',
      Format('"points" must not exceed %d', [MAX_CALC_POINTS]), IntToStr(Req.Points));
  if Req.DeltaTheta < 0 then
    raise EMCPError.Create('invalid_argument', '"delta_theta" must not be negative');

  Proj.CalcCurve := RunCalc(Req, Used);

  Proj.ModelTitle := Name;
  Proj.Note := JSONArgs.OptStr(Params, 'note', '');
  // The densities the engine used, not the ones omitted from the request: the
  // file then says exactly what produced the curve stored beside it.
  Proj.XRCData := StructureToXRCData(Used, Req.Info);

  Proj.Params.Lambda       := Req.Lambda;
  Proj.Params.ThetaStart   := Req.ThetaMin;
  Proj.Params.ThetaEnd     := Req.ThetaMax;
  Proj.Params.Width        := Req.DeltaTheta;
  Proj.Params.Points       := Req.Points;
  if Req.Polarization = cmS then
    Proj.Params.Polarisation := 0
  else
    Proj.Params.Polarisation := 1;
  Proj.Params.MinLimit     := Req.RMin;

  WriteXRCX(FileName, Proj);

  Result := TJSONObject.Create;
  try
    Result.AddPair('file', WorkDir.RelativePath(FileName));
    Result.AddPair('sha256', FileSHA256(FileName));
    Result.AddPair('size', TJSONNumber.Create(FileSizeOf(FileName)));
    Result.AddPair('version', TJSONNumber.Create(CURRENT_PROJECT_VERSION));
    Result.AddPair('lambda_used', JSONArgs.Num(Req.Lambda));
  except
    Result.Free;
    raise;
  end;
end;

function LoadProjectResult(const Params: TJSONObject): TJSONObject;
var
  Proj: TXRCXProject;
  S: TFitStructure;
  Info: TStructureInfo;
  Rel, Full: string;
  Profiles, Coeffs: TJSONArray;
  Prof, CalcParams, Curves: TJSONObject;
  i, j: Integer;
begin
  Rel := Trim(JSONArgs.OptStr(Params, 'path', ''));
  if Rel = '' then
    Rel := Trim(JSONArgs.OptStr(Params, 'name', ''));
  if Rel = '' then
    raise EMCPError.Create('invalid_argument', 'Either "name" or "path" is required');

  Rel := StringReplace(Rel, '/', '\', [rfReplaceAll]);
  { Without this a control character or a '*' reaches TPath.Combine inside
    ResolvePath, which raises an RTL exception the client sees as "internal". }
  if not TPath.HasValidPathChars(Rel, False) then
    raise EMCPError.Create('invalid_argument',
      'The path holds characters a file name may not have', Rel);
  if Pos('\', Rel) = 0 then
    Rel := 'projects\' + Rel;
  if TPath.GetExtension(Rel) = '' then
    Rel := Rel + PROJECT_EXT;

  Full := WorkDir.ResolvePath(Rel, False);
  if not TFile.Exists(Full) then
    raise EMCPError.Create('not_found', 'No such project', WorkDir.RelativePath(Full));

  Proj := ReadXRCX(Full);
  S := StructureFromXRCData(Proj.XRCData, Info);

  Result := TJSONObject.Create;
  try
    Result.AddPair('file', WorkDir.RelativePath(Full));
    Result.AddPair('version', TJSONNumber.Create(Proj.Version));
    Result.AddPair('model_title', Proj.ModelTitle);
    Result.AddPair('note', Proj.Note);
    Result.AddPair('structure', StructureToJSON(S, Info));
    Result.AddPair('inverted_ranges', InvertedRangesJSON(S));

    { Every child JSON value is attached to its parent immediately after it is
      created, before anything that could raise (a float conversion, a file
      read) runs on it. That way the whole tree is owned by Result at every
      point, and "Result.Free; raise;" below can never leak a node that was
      built but not yet linked in. }
    Profiles := TJSONArray.Create;
    Result.AddPair('profiles', Profiles);
    for i := 0 to High(Proj.Extensions) do
    begin
      Prof := TJSONObject.Create;
      Profiles.AddElement(Prof);
      Prof.AddPair('stack', TJSONNumber.Create(Proj.Extensions[i].StackID));
      Prof.AddPair('layer', TJSONNumber.Create(Proj.Extensions[i].LayerID));
      Prof.AddPair('parameter', ParameterName(Proj.Extensions[i].Subj));
      Coeffs := TJSONArray.Create;
      Prof.AddPair('coefficients', Coeffs);
      for j := 0 to High(Proj.Extensions[i].Coeffs) do
        Coeffs.AddElement(JSONArgs.Num(Proj.Extensions[i].Coeffs[j]));
    end;

    CalcParams := TJSONObject.Create;
    Result.AddPair('calc_params', CalcParams);
    CalcParams.AddPair('lambda', JSONArgs.Num(Proj.Params.Lambda));
    CalcParams.AddPair('theta_start', JSONArgs.Num(Proj.Params.ThetaStart));
    CalcParams.AddPair('theta_end', JSONArgs.Num(Proj.Params.ThetaEnd));
    CalcParams.AddPair('width', JSONArgs.Num(Proj.Params.Width));
    CalcParams.AddPair('points', TJSONNumber.Create(Proj.Params.Points));
    if Proj.Params.Polarisation = 0 then
      CalcParams.AddPair('polarisation', 's')
    else
      CalcParams.AddPair('polarisation', 'sp');

    Curves := TJSONObject.Create;
    Result.AddPair('curves', Curves);
    Curves.AddPair('calc_points', TJSONNumber.Create(Length(Proj.CalcCurve)));
    Curves.AddPair('data_points', TJSONNumber.Create(Length(Proj.DataCurve)));
    if Proj.DataTitle = '' then
      Curves.AddPair('data_title', TJSONNull.Create)
    else
      Curves.AddPair('data_title', Proj.DataTitle);

    Result.AddPair('sha256', FileSHA256(Full));
  except
    Result.Free;
    raise;
  end;
end;

function ListProjectsResult: TJSONObject;
var
  Files: TStringDynArray;
  Arr: TJSONArray;
  Obj: TJSONObject;
  FileName: string;
begin
  Arr := TJSONArray.Create;
  Result := TJSONObject.Create;
  try
    Result.AddPair('projects', Arr);
    if not TDirectory.Exists(WorkDir.ProjectsDir) then
      Exit;
    Files := TDirectory.GetFiles(WorkDir.ProjectsDir, '*' + PROJECT_EXT,
      TSearchOption.soTopDirectoryOnly);
    TArray.Sort<string>(Files);
    for FileName in Files do
    begin
      // Obj is attached to Arr (and so to Result) immediately after creation,
      // before FileSHA256/FileModifiedUTC - which can raise on a file that
      // disappears or locks up mid-listing - run on it, so the exception
      // path below never leaks a half-built entry.
      Obj := TJSONObject.Create;
      Arr.AddElement(Obj);
      Obj.AddPair('name', TPath.GetFileNameWithoutExtension(FileName));
      Obj.AddPair('file', WorkDir.RelativePath(FileName));
      Obj.AddPair('size', TJSONNumber.Create(FileSizeOf(FileName)));
      Obj.AddPair('sha256', FileSHA256(FileName));
      Obj.AddPair('modified_utc', FileModifiedUTC(FileName));
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure RegisterProjectTools(Registry: TToolRegistry);
var
  Schema, Curves: TJSONObject;
begin
  Schema := SchemaObject(['structure', 'name']);
  AddRefProp(Schema, 'structure', 'The layer structure to store, in the form ' +
    'calc_reflectivity takes.', StructureSchema);
  AddProp(Schema, 'name', 'string',
    'File name under projects\, without a path. Letters, digits and "_-. ()#" ' +
    'only; ".xrcx" is appended when it is missing. The name is also the title ' +
    'of the model node inside the project - and a name that contains "Data" or ' +
    '"Models" comes back shortened to just that word, because the GUI rewrites ' +
    'such titles when it loads a project.');
  Curves := SchemaObject([]);
  AddProp(Curves, 'measurement_id', 'string',
    'Embed this inbox measurement as the project''s data curve, in theta. The ' +
    'measurement_id becomes the title of the data node inside the project - ' +
    'and one that contains "Data" or "Models" comes back shortened to just ' +
    'that word, because the GUI rewrites such titles when it loads a project.');
  AddProp(Curves, 'job_id', 'string',
    'Embed the measured curve of a finished fit_xrr job. The project then ' +
    'also takes the job''s own fit settings and calculation parameters (the ' +
    'engine mode, iterations, population, chi-squared weighting, resolution ' +
    'width, wavelength and angular range), so it opens in the GUI as that ' +
    'fit; "theta_min", "theta_max", "points", "delta_theta" and "lambda" ' +
    'given explicitly still win.');
  AddRefProp(Schema, 'curves',
    'Optional measured curve to store beside the calculated one, as a data ' +
    'node the GUI plots. Give either "measurement_id" or "job_id", not both.',
    Curves);
  AddProp(Schema, 'note', 'string',
    'Free text stored as the model node''s description.');
  AddProp(Schema, 'overwrite', 'boolean',
    'Replace an existing project of the same name (default false; without it ' +
    'an existing file is reported as "already_exists").');
  AddProp(Schema, 'lambda', 'number',
    'Wavelength in Angstrom for the stored curve (default 1.54043, Cu K-alpha). ' +
    'Give either "lambda" or "energy".');
  AddProp(Schema, 'energy', 'number',
    'Photon energy in eV instead of "lambda".');
  AddProp(Schema, 'theta_min', 'number',
    'First incidence angle theta in degrees (default 0.05).');
  AddProp(Schema, 'theta_max', 'number',
    'Last incidence angle theta in degrees (default 5).');
  AddProp(Schema, 'points', 'integer',
    'Number of points of the stored curve (default 2000).');
  AddProp(Schema, 'delta_theta', 'number',
    'Instrumental convolution width in degrees (default 0, no convolution).');
  Registry.Register('save_project',
    'Writes an X-Ray Calc 3 project file that opens in the GUI with no ' +
    'conversion. The structure is stored as the active model, the reflectivity ' +
    'is calculated here and stored beside it as calc.dat, and an optional ' +
    'measured curve is stored as a linked data node, so that opening the file ' +
    'shows the same curve the server computed. Angles are written as theta ' +
    '(the file sets 2teta=0), the parameter block is a version 7 params.dsc ' +
    'with the GUI''s own keys and defaults (fit mode periodic when the ' +
    'structure has a repeating stack, irregular otherwise; or the fit ' +
    'settings of the job named in "curves"), and the densities stored are the ' +
    'ones the engine used rather than the ones asked for: a layer whose ' +
    'density was omitted gets the Henke bulk value, and so does a substrate ' +
    'whose density was omitted; a substrate density that is given is kept ' +
    'and used, as it has been since 3.9.1. The file ' +
    'lands in projects\<name>.xrcx and its SHA-256 and size are reported.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := SaveProjectResult(Params);
    end);

  Schema := SchemaObject([]);
  AddProp(Schema, 'name', 'string',
    'Project in projects\, with or without the .xrcx extension.');
  AddProp(Schema, 'path', 'string',
    'Path of the project relative to the working directory, e.g. ' +
    '"projects\ruc.xrcx". A bare name is looked up in projects\.');
  Registry.Register('load_project',
    'Reads an X-Ray Calc 3 project file back. Returns the active model''s ' +
    'structure in the same JSON form calc_reflectivity takes, the polynomial ' +
    'profile extensions attached to it, the calculation parameters from ' +
    'params.dsc (angles always as theta, whatever the file stores), how many ' +
    'points the stored calculated and measured curves have, and the file''s ' +
    'SHA-256. A project old enough to keep its model in a separate model_N.bin ' +
    'rather than in the project tree is reported as "unsupported_project": ' +
    'open and re-save it in XRayCalc3 first. A profile''s coefficients are ' +
    'reported as stored: the file does not keep the constant term, so ' +
    'coefficients[0] is always 0 and the layer''s own value is the real ' +
    'C[0]. "inverted_ranges" lists every fit range in the file whose min ' +
    'exceeds its max (the GUI stores ranges unchecked); the fit engine ' +
    'refuses to start on such a layer until the range is corrected.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := LoadProjectResult(Params);
    end);

  Registry.Register('list_projects',
    'Lists the .xrcx projects in projects\. For each one the name, the ' +
    'work-directory-relative path, the size, the SHA-256 and the last-modified ' +
    'time in UTC, sorted by name. Nothing outside projects\ is listed and ' +
    'nothing is written.',
    SchemaObject([]),
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := ListProjectsResult;
    end);
end;

procedure RegisterFileTools(Registry: TToolRegistry);
begin
  RegisterInboxTools(Registry);
  RegisterProjectTools(Registry);
end;

end.
