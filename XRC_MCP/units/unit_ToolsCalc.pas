unit unit_ToolsCalc;

(* The calculation tools: calc_reflectivity here, evaluate_lines in task 9.

   calc_reflectivity is synchronous. A theta scan of a few thousand points over
   a few hundred layers takes well under a second on every core of the machine,
   so there is nothing to queue: the tool creates its job folder, runs the
   engine, writes curve.dat, structure.json and request.json into it and returns
   the result in the same round trip. The folder is still called a job and still
   carries a job id, so that a curve produced here is referred to the same way
   as one produced by a fit. *)

interface

uses unit_MCPTools;

procedure RegisterCalcTools(Registry: TToolRegistry);

implementation

uses
  System.SysUtils, System.JSON, System.IOUtils,
  unit_Types,
  unit_MCPErrors, unit_MCPSandbox, unit_MCPUnits, unit_MCPStructure, unit_MCPCalc;

const
  DEFAULT_THETA_MIN    = 0.05;
  DEFAULT_THETA_MAX    = 5.0;
  DEFAULT_POINTS       = 2000;
  DEFAULT_INLINE_MAX   = 2000;
  DEFAULT_R_MIN        = 1E-7;

{ ------------------------------------------------------------ job folder -- }

{ Four hex digits from a GUID rather than from Random: the job id must be
  unique without touching RandSeed, which is process-global and is what makes a
  seeded fit reproducible (design note section 5). }
function FourHex: string;
var
  G: TGUID;
begin
  CreateGUID(G);
  Result := LowerCase(IntToHex(G.D1 and $FFFF, 4));
end;

/// Creates jobs\<prefix>-<yyyymmdd-hhnnss>-<4 hex>\ and returns its absolute
/// path; JobId is the folder name.
function CreateJobFolder(const Prefix: string; out JobId: string): string;
var
  Attempt: Integer;
begin
  for Attempt := 1 to 100 do
  begin
    JobId := Format('%s-%s-%s', [Prefix, FormatDateTime('yyyymmdd-hhnnss', Now), FourHex]);
    Result := TPath.Combine(WorkDir.JobsDir, JobId);
    if not TDirectory.Exists(Result) then
    begin
      TDirectory.CreateDirectory(Result);
      Exit;
    end;
  end;
  raise EMCPError.Create('internal', 'Cannot create a unique job folder', WorkDir.JobsDir);
end;

{ UTF-8 without a byte order mark: TEncoding.UTF8.GetBytes leaves the preamble
  out, where TFile.WriteAllText with the same encoding would write one, and a
  BOM in front of a '{' trips strict JSON parsers. }
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

{ --------------------------------------------------------- argument input -- }

/// 's' -> cmS; 'p' and 'sp' -> cmSP. The engine has two modes only: cmSP is
/// (Rs + Rp)/2, and there is no pure-p path, so 'p' is answered with 'sp' and
/// the echoed polarization says so.
function ParsePolarization(const S: string; out Effective: string): TPolarisation;
begin
  if SameText(S, 's') then
  begin
    Effective := 's';
    Exit(cmS);
  end;
  if SameText(S, 'p') or SameText(S, 'sp') then
  begin
    Effective := 'sp';
    Exit(cmSP);
  end;
  raise EMCPError.Create('invalid_argument',
    '"polarization" must be "s", "p" or "sp"', S);
end;

function PeaksToJSON(const Peaks: TArray<TPeak>): TJSONArray;
var
  i: Integer;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    for i := 0 to High(Peaks) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('order', TJSONNumber.Create(Peaks[i].Order));
      Obj.AddPair('theta_deg', JSONArgs.Num(Peaks[i].Theta));
      Obj.AddPair('r_peak', JSONArgs.Num(Peaks[i].R));
      Obj.AddPair('fwhm_deg', JSONArgs.Num(Peaks[i].FWHM));
      Result.AddElement(Obj);
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ ------------------------------------------------------ calc_reflectivity -- }

function CalcReflectivityResult(const Params: TJSONObject): TJSONObject;
var
  Req: TCalcRequest;
  Used: TFitStructure;
  Curve: TDataArray;
  Peaks: TArray<TPeak>;
  Bad, PolStr, EffPol, JobId, Folder, CurvePath: string;
  MaxInline: Integer;
  ThetaC: Double;
  StructJSON: TJSONObject;
  CurveJSON: TJSONArray;
begin
  Req := Default(TCalcRequest);
  Req.Structure := StructureFromJSON(JSONArgs.ReqObj(Params, 'structure'), Req.Info);

  Bad := ValidateMaterials(Req.Structure);
  if Bad <> '' then
    raise EMCPError.Create('unknown_material',
      Format('No Henke table for material "%s"', [Bad]),
      'list_materials enumerates the names this server knows');

  Req.Lambda := GetLambdaArg(Params);
  Req.ThetaMin := JSONArgs.OptFloat(Params, 'theta_min', DEFAULT_THETA_MIN);
  Req.ThetaMax := JSONArgs.OptFloat(Params, 'theta_max', DEFAULT_THETA_MAX);
  Req.DeltaTheta := JSONArgs.OptFloat(Params, 'delta_theta', 0);
  Req.Points := JSONArgs.OptInt(Params, 'points', DEFAULT_POINTS);
  Req.RMin := JSONArgs.OptFloat(Params, 'r_min', DEFAULT_R_MIN);
  PolStr := JSONArgs.OptStr(Params, 'polarization', 'sp');
  Req.Polarization := ParsePolarization(PolStr, EffPol);
  MaxInline := JSONArgs.OptInt(Params, 'max_inline_points', DEFAULT_INLINE_MAX);

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
  if Req.RMin <= 0 then
    raise EMCPError.Create('invalid_argument', '"r_min" must be greater than zero');
  if MaxInline < 0 then
    raise EMCPError.Create('invalid_argument', '"max_inline_points" must not be negative');

  Curve := RunCalc(Req, Used);
  ThetaC := CriticalAngleDeg(Used, Req.Lambda);
  Peaks := FindBraggPeaks(Curve, Req.Lambda, Req.Info.Period, ThetaC);

  Folder := CreateJobFolder('calc', JobId);
  CurvePath := TPath.Combine(Folder, 'curve.dat');
  WriteCurveFile(CurvePath, Curve, 'theta_deg', 'R');

  StructJSON := StructureToJSON(Used, Req.Info);
  try
    WriteJSONFile(TPath.Combine(Folder, 'structure.json'), StructJSON);
    WriteJSONFile(TPath.Combine(Folder, 'request.json'), Params);

    Result := TJSONObject.Create;
    try
      Result.AddPair('job_id', JobId);
      Result.AddPair('lambda_used', JSONArgs.Num(Req.Lambda));
      Result.AddPair('energy_eV', JSONArgs.Num(LambdaToEnergy(Req.Lambda)));
      Result.AddPair('theta_unit', 'deg theta');
      Result.AddPair('polarization', EffPol);
      Result.AddPair('delta_theta', JSONArgs.Num(Req.DeltaTheta));
      Result.AddPair('structure_used', StructJSON);
      StructJSON := nil;                       // owned by Result from here on
      // "file" sits immediately before "curve" so that the journal, which
      // compacts an array of more than 64 elements, finds the file naming the
      // full data in the same object and can hash it.
      Result.AddPair('file', WorkDir.RelativePath(CurvePath));
      Result.AddPair('points', TJSONNumber.Create(Length(Curve)));
      CurveJSON := CurveToJSON(Curve, MaxInline);
      if CurveJSON = nil then
        Result.AddPair('curve', TJSONNull.Create)
      else
        Result.AddPair('curve', CurveJSON);
      Result.AddPair('critical_angle_deg', JSONArgs.Num(ThetaC));
      Result.AddPair('bragg_peaks', PeaksToJSON(Peaks));
      Result.AddPair('period_A', JSONArgs.Num(Req.Info.Period));
      Result.AddPair('n_periods', TJSONNumber.Create(Req.Info.N));
    except
      Result.Free;
      raise;
    end;
  finally
    StructJSON.Free;
  end;
end;

{ ---------------------------------------------------------- registration -- }

procedure RegisterCalcTools(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Schema := SchemaObject(['structure']);
  AddRefProp(Schema, 'structure',
    'The multilayer to calculate. Stacks are listed from the substrate to the surface.',
    StructureSchema);
  AddProp(Schema, 'lambda', 'number',
    'Wavelength in Angstrom (A). Give either this or "energy", not both.');
  AddProp(Schema, 'energy', 'number',
    'Photon energy in eV (lambda = 12398.42 / E). Give either this or "lambda", not both.');
  AddProp(Schema, 'theta_min', 'number',
    'First incidence angle theta in degrees - NOT 2theta (default 0.05).');
  AddProp(Schema, 'theta_max', 'number',
    'Last incidence angle theta in degrees - NOT 2theta (default 5).');
  AddProp(Schema, 'points', 'integer',
    'Number of angles, evenly spaced from theta_min to theta_max inclusive ' +
    '(default 2000, maximum 100000). The curve returned holds exactly this many points.');
  AddEnumProp(Schema, 'polarization',
    'Polarization of the incident beam (default "sp"). "s" is the pure s curve; ' +
    '"sp" is the unpolarized average (Rs + Rp)/2. The engine has no pure-p path, ' +
    'so "p" is COMPUTED AS "sp" and the result echoes "sp" as the mode used.',
    ['s', 'p', 'sp']);
  AddProp(Schema, 'delta_theta', 'number',
    'Beam divergence, the FWHM in degrees of the Gaussian the curve is convolved ' +
    'with (default 0 = no convolution).');
  AddProp(Schema, 'r_min', 'number',
    'Floor the reflectivity is clamped to, so that a log plot has no zeros ' +
    '(default 1e-7). This is the engine''s TCalc.Limit.');
  AddProp(Schema, 'max_inline_points', 'integer',
    'Return the curve inline only when it has at most this many points ' +
    '(default 2000). A longer curve comes back as null and is read from "file".');
  Registry.Register('calc_reflectivity',
    'Calculates the specular X-ray reflectivity of a multilayer over a theta range. ' +
    'This is the X-Ray Calc 3 GUI engine, so the curve is the one the GUI draws for the ' +
    'same structure. Returns the curve inline (when short enough) and always as a ' +
    'two-column file under jobs\<job_id>\curve.dat, together with the Bragg peaks ' +
    '(order, position, peak reflectivity and FWHM), the total-reflection critical ' +
    'angle, the period and repeat count of the multilayer stack, and the structure ' +
    'with every omitted density filled in with the Henke bulk value that was used. ' +
    'Angles are theta in degrees, never 2theta; lengths are Angstrom.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := CalcReflectivityResult(Params);
    end);
end;

end.
