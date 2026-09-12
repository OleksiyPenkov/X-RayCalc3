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

unit unit_ToolsCalc;

(* The calculation tools: calc_reflectivity and evaluate_lines.

   calc_reflectivity is synchronous. A theta scan of a few thousand points over
   a few hundred layers takes well under a second on every core of the machine,
   so there is nothing to queue: the tool creates its job folder, runs the
   engine, writes curve.dat, structure.json and request.json into it and returns
   the result in the same round trip. The folder is still called a job and still
   carries a job id, so that a curve produced here is referred to the same way
   as one produced by a fit.

   evaluate_lines is synchronous for a different reason: it is a handful of
   short scans, one per emission line, and it writes nothing. It answers the
   question the mirror optimizer asks of every candidate - "how good is this
   multilayer for these lines" - for a structure the client already has, using
   the optimizer's own figure of merit so that the number is comparable with the
   one optimize_mirror reports. *)

interface

uses unit_MCPTools;

procedure RegisterCalcTools(Registry: TToolRegistry);

implementation

uses
  System.SysUtils, System.JSON, System.IOUtils,
  unit_Types, unit_materials,
  unit_universal_types,
  unit_MCPErrors, unit_MCPSandbox, unit_MCPUnits, unit_MCPStructure, unit_MCPCalc,
  unit_MCPUniversal, unit_MCPJobs;

const
  DEFAULT_THETA_MIN    = 0.05;
  DEFAULT_THETA_MAX    = 5.0;
  DEFAULT_POINTS       = 2000;
  DEFAULT_INLINE_MAX   = 2000;
  DEFAULT_R_MIN        = 1E-7;

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

  Folder := NewJobFolder('calc', JobId);
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

{ ---------------------------------------------------------- evaluate_lines -- }

function EvaluateLinesResult(const Params: TJSONObject): TJSONObject;
var
  Used: TFitStructure;
  Info: TStructureInfo;
  Lines: TArray<TXRFLine>;
  Fit: TFitnessConfig;
  Res: TTargetResults;
  FoM: Single;
  Model: TLayeredModel;
  JLines: TJSONArray;
  Line: TJSONObject;
  i: Integer;
begin
  Used := StructureFromJSON(JSONArgs.ReqObj(Params, 'structure'), Info);
  Lines := LinesFromJSON(JSONArgs.ReqArr(Params, 'lines'));
  Fit := FitnessConfigFromJSON(JSONArgs.OptObj(Params, 'fitness'), DefaultFitnessConfig);

  FoM := EvaluateStructure(Used, Info, Lines, Fit, Res);

  // The densities the calculation used, for the echoed structure. The universal
  // engine's mixer and the GUI's TLayeredModel read the same .bin headers, so
  // the bulk value filled in here is the one EvaluateStructure used.
  Model := BuildLayeredModel(Used);
  try
    Model.Generate(Lines[0].Lambda);
    FillDefaultDensities(Used, Model);
  finally
    Model.Free;
  end;

  Result := TJSONObject.Create;
  try
    Result.AddPair('fom', JSONArgs.Num(FoM));

    JLines := TJSONArray.Create;
    Result.AddPair('lines', JLines);
    for i := 0 to High(Lines) do
    begin
      Line := TJSONObject.Create;
      Line.AddPair('name', Lines[i].Name);
      Line.AddPair('lambda_used', JSONArgs.Num(Lines[i].Lambda));
      Line.AddPair('weight', JSONArgs.Num(Lines[i].Weight));
      Line.AddPair('theta_bragg_deg', JSONArgs.Num(Res[i].ThetaBragg));
      // Where the peak really is, and the window and grid it was measured on:
      // the scan is centred on the refraction-corrected angle, starts above the
      // total-reflection plateau, and is fine enough to resolve the width.
      Line.AddPair('theta_peak_deg', JSONArgs.Num(Res[i].ThetaPeak));
      Line.AddPair('r_peak', JSONArgs.Num(Res[i].RPeak));
      Line.AddPair('fwhm_deg', JSONArgs.Num(Res[i].FWHM));
      Line.AddPair('scan_half_deg', JSONArgs.Num(Res[i].ScanHalf));
      Line.AddPair('scan_step_deg', JSONArgs.Num(Res[i].ScanStep));
      Line.AddPair('scan_points_used', TJSONNumber.Create(Res[i].ScanPointsUsed));
      Line.AddPair('valid', TJSONBool.Create(Res[i].Valid));
      JLines.AddElement(Line);
    end;

    Result.AddPair('fitness_used', FitnessConfigToJSON(Fit));
    Result.AddPair('period_A', JSONArgs.Num(Info.Period));
    Result.AddPair('n_periods', TJSONNumber.Create(Info.N));
    Result.AddPair('structure_used', StructureToJSON(Used, Info));
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------------------------------------------------- registration -- }

/// One item of the "lines" array: either the full object or a bare element
/// symbol.
function LineItemSchema: TJSONObject;
var
  Obj, Str: TJSONObject;
  Arr: TJSONArray;
begin
  Obj := SchemaObject(['name']);
  AddProp(Obj, 'name', 'string',
    'Name of the line, normally the element symbol ("B", "Si"). With no ' +
    '"lambda" or "energy" the wavelength is looked up in the XRF line table.');
  AddProp(Obj, 'lambda', 'number',
    'Wavelength of the line in Angstrom. Give either this or "energy", not both.');
  AddProp(Obj, 'energy', 'number',
    'Photon energy of the line in eV. Give either this or "lambda", not both.');
  AddProp(Obj, 'weight', 'number',
    'Relative weight of this line in the figure of merit (default 1).');

  Str := TJSONObject.Create;
  Str.AddPair('type', 'string');
  Str.AddPair('description',
    'An element symbol ("Si"), or a symbol range ("B-Si"), whose characteristic ' +
    'wavelength comes from the XRF line table. Weight 1.');

  Arr := TJSONArray.Create;
  Arr.AddElement(Obj);
  Arr.AddElement(Str);
  Result := TJSONObject.Create;
  Result.AddPair('oneOf', Arr);
end;

function FitnessSchema: TJSONObject;
begin
  Result := SchemaObject([]);
  AddProp(Result, 'w_R', 'number',
    'Weight of the peak reflectivity in the figure of merit (default 1).');
  AddProp(Result, 'w_FWHM', 'number',
    'Weight of the FWHM penalty, in units of the kinematic reference width ' +
    'of n_ref periods (default 0.25). The width of a real peak saturates at the ' +
    'extinction-limited one, so a strongly absorbing line can exceed its ' +
    'reference width however many periods the mirror has.');
  AddProp(Result, 'n_ref', 'integer',
    'Periods in the reference width the FWHM penalty is measured in: ' +
    'lambda / (n_ref d cos theta), default 50. It is deliberately independent ' +
    'of the structure''s own number of periods - a reference tied to N makes ' +
    'the penalty grow with N while the real peak width saturates, which ' +
    'penalises exactly the designs that reflect best.');
  AddProp(Result, 'R_min_threshold', 'number',
    'A line whose peak reflectivity falls below this is penalised as dark ' +
    '(default 0.02). A channel reflecting less than a couple of per cent is of ' +
    'no use, so the default treats it as absent rather than weak; the penalty ' +
    'is 100 per dark line and is not tunable.');
  AddProp(Result, 'w_purity', 'number',
    'Weight of the spectral purity correction, 0 turns it off (default 1). ' +
    'Purity is the peak of a line divided by the peak plus the reflectivity of ' +
    'every other line at that same angle.');
  AddEnumProp(Result, 'polarization',
    'Polarization of the incident beam (default "sp"). The engine has no pure-p ' +
    'path, so "p" is computed as "sp".', ['s', 'p', 'sp']);
  AddProp(Result, 'delta_theta', 'number',
    'Beam divergence, the FWHM in degrees of the Gaussian each scan is ' +
    'convolved with (default 0 = no convolution).');
  AddProp(Result, 'theta_min', 'number',
    'Dark-zone threshold in degrees theta (default 0): a line whose Bragg angle ' +
    'falls below it is reported invalid and penalised. This is NOT where the ' +
    'scan starts - each line is scanned around its own Bragg angle.');
  AddProp(Result, 'scan_points', 'integer',
    'Floor on the points in the reflectivity scan of each line (default 200, ' +
    'minimum 3, maximum 20000). A line is scanned more finely when that is ' +
    'what it takes to resolve its width - at most a tenth of its kinematic ' +
    'width per step - so this bounds the scan from below, not above. Each ' +
    'line reports the grid it was given.');
  AddProp(Result, 'scan_half_range', 'number',
    'Fixed half-width in degrees of the scan around each line''s ' +
    'refraction-corrected peak (maximum 90). Omit it - the default - to let ' +
    'each line be scanned over max(0.5 deg, 4 kinematic widths), which is ' +
    'what keeps a narrow peak off a coarse grid and a wide one unclipped. ' +
    'Either way the scan starts above the total-reflection plateau and the ' +
    'peak taken is the local maximum nearest the expected angle, never the ' +
    'plateau itself.');
end;

procedure RegisterEvaluateLines(Registry: TToolRegistry);
var
  Schema: TJSONObject;
begin
  Schema := SchemaObject(['structure', 'lines']);
  AddRefProp(Schema, 'structure',
    'The multilayer to evaluate. Stacks are listed from the substrate to the ' +
    'surface. Exactly one stack must repeat (N greater than 1): its period and ' +
    'repeat count set the Bragg angles and the reference width.',
    StructureSchema);
  AddRefProp(Schema, 'lines',
    'The emission lines the mirror is meant to serve, at most 16.',
    ArraySchema(LineItemSchema));
  AddRefProp(Schema, 'fitness',
    'Overrides for the figure of merit. Every key is optional and defaults to ' +
    'the value the mirror optimizer uses.', FitnessSchema);
  Registry.Register('evaluate_lines',
    'Scores a multilayer against a set of X-ray emission lines with the mirror ' +
    'optimizer''s own figure of merit. This is the XRFCalc engine, so the number ' +
    'returned is directly comparable with the one optimize_mirror reports, and a ' +
    'structure optimize_mirror proposed scores here exactly as it scored there. ' +
    'Each line is scanned around its own Bragg angle for the given period, and ' +
    'the result reports, per line, the Bragg angle, the peak reflectivity and the ' +
    'angular FWHM, plus the single figure of merit combining them (higher is ' +
    'better). Every fitness setting actually used is echoed back, including the ' +
    'scan defaults. The scan grid is bounded (at most 20000 points over a half ' +
    'range of at most 90 degrees) because the call answers in the same round ' +
    'trip. Angles are theta in degrees, never 2theta; lengths are Angstrom. ' +
    'Refused with server_busy while an optimize_mirror job is running, because ' +
    'both share the engine''s Henke table reader; poll job_status or use ' +
    'cancel_job, then retry.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := EvaluateLinesResult(Params);
    end);
end;

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
    'angle (sqrt(2<delta>), <delta> the thickness-weighted mean over the top 500 A ' +
    'of the structure, substrate included where the film is thinner - the plateau ' +
    'edge of the film, not of its top layer), the period and repeat count of the ' +
    'multilayer stack, and the structure ' +
    'with every omitted density filled in with the Henke bulk value that was used. ' +
    'Angles are theta in degrees, never 2theta; lengths are Angstrom.',
    Schema,
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := CalcReflectivityResult(Params);
    end);

  RegisterEvaluateLines(Registry);
end;

end.
