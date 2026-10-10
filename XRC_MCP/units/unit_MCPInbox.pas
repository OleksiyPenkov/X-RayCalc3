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

unit unit_MCPInbox;


interface

uses
  System.Classes, System.SysUtils, System.JSON,
  unit_Types, unit_xrdml;

type
  /// <summary>meta.json beside the curve. Raw is the whole file and is owned by
  /// the caller; it is nil when the file is absent.</summary>
  TInboxMeta = record
    Lambda: Double;              // Angstrom; 0 when neither lambda nor energy was given
    DateStr: string;
    Instrument: string;
    ThetaUnit: string;           // 'theta' or '2theta'
    ThetaUnitDeclared: Boolean;  // False: ThetaUnit is the assumed default, not a declaration
    Raw: TJSONObject;            // owned by the caller
    Present: Boolean;
  end;

  /// <summary>One measurement read from the inbox. Meta.Raw is owned by the
  /// caller and has to be freed by it.</summary>
  TMeasurement = record
    Id: string;                     // '<specimen>/<file>', normalised
    Path: string;
    Curve: unit_Types.TDataArray;   // theta (deg), I - decimated when asked for
    Points: Integer;                // points in the file, before decimation
    ThetaMin: Double;               // both from the full curve, after conversion
    ThetaMax: Double;
    Columns: string;                // 'theta,intensity' | '2theta,intensity' - the declared unit
    Converted2Theta: Boolean;
    HeaderLines: TArray<string>;
    Meta: TInboxMeta;
    LambdaSource: string;           // 'meta.json', 'file: <rule>' or '' when there is none
    IsXRDML: Boolean;
    XRDML: TXRDMLScan;              // counting time, peak rate, zeros ... (Curve is in the file's axis)
  end;

const
  MEASUREMENT_EXTENSIONS: array [0 .. 3] of string = ('.dat', '.txt', '.xy', '.xrdml');
  DEFAULT_MAX_POINTS = 2000;

function ParseCurveText(const Lines: TStrings; out Curve: unit_Types.TDataArray;
  out Header: TArray<string>): Integer;

function ReadMeta(const Dir: string; out Meta: TInboxMeta): Boolean;

function LoadMeasurement(const Id: string; MaxPoints: Integer): TMeasurement;

function DecimateCurve(const C: unit_Types.TDataArray; MaxPoints: Integer): unit_Types.TDataArray;

/// <summary>[{specimen, files:[{name, id, size, sha256, modified_utc}],
/// meta:{...}|null}] over the subfolders of inbox\, optionally filtered to one
/// specimen (exact, case-insensitive). Caller frees.</summary>
function ListMeasurements(const SpecimenFilter: string): TJSONArray;

/// <summary>Files lying directly in inbox\ rather than in a specimen folder.
/// They are not measurements - the id needs a specimen - so they are counted
/// and reported rather than silently dropped.</summary>
function LooseFileCount: Integer;

/// <summary>The list_measurements result. Caller frees.</summary>
function ListMeasurementsJSON(const SpecimenFilter: string): TJSONObject;

/// <summary>The get_measurement result. MaxPoints is the tool's argument and
/// has to be at least 2; the LoadMeasurement sentinel 0 (no decimation at all)
/// is internal and is refused here. Caller frees.</summary>
function GetMeasurementJSON(const Id: string; MaxPoints: Integer): TJSONObject;

implementation

uses
  System.Character, System.Math, System.IOUtils, System.StrUtils,
  System.Generics.Collections, System.Generics.Defaults,
  unit_MCPErrors, unit_MCPSandbox, unit_MCPUnits;


procedure AppendStr(var A: TArray<string>; const S: string);
begin
  SetLength(A, Length(A) + 1);
  A[High(A)] := S;
end;

/// <summary>Loads a text file without ever asking for write access, and while
/// leaving the file shareable: an acquisition program may still have it open.</summary>
procedure LoadTextShared(SL: TStringList; const Path: string);
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyNone);
  try
    SL.LoadFromStream(Stream);
  finally
    Stream.Free;
  end;
end;

function IsMeasurementFile(const Path: string): Boolean;
var
  Ext: string;
  I: Integer;
begin
  Ext := LowerCase(TPath.GetExtension(Path));
  for I := Low(MEASUREMENT_EXTENSIONS) to High(MEASUREMENT_EXTENSIONS) do
    if Ext = MEASUREMENT_EXTENSIONS[I] then
      Exit(True);
  Result := False;
end;

function ExtensionList: string;
var
  I: Integer;
begin
  Result := '';
  for I := Low(MEASUREMENT_EXTENSIONS) to High(MEASUREMENT_EXTENSIONS) do
    Result := Result + IfThen(I > Low(MEASUREMENT_EXTENSIONS), ', ') + MEASUREMENT_EXTENSIONS[I];
end;


/// <summary>The angle column, by SeriesFromText's rule to the letter: it has to
/// start with a digit, so '-0.5' is a comment and not an angle.</summary>
function StartsAngle(const S: string): Boolean;
begin
  Result := (S <> '') and S[1].IsNumber;
end;

/// <summary>The intensity column, which may carry a sign - a negative intensity
/// is data to be floored, not a comment. TryStrToFloat has the last word.</summary>
function StartsIntensity(const S: string): Boolean;
begin
  Result := (S <> '') and (S[1].IsNumber or CharInSet(S[1], ['-', '+']));
end;

function ParseCurveText(const Lines: TStrings; out Curve: unit_Types.TDataArray;
  out Header: TArray<string>): Integer;
var
  I, P, N: Integer;
  Line, S, S1, S2, Separator, Alt: string;
  X, Y, MinPositive: Double;
  FS: TFormatSettings;

  procedure FixDecimalPoint(var Value: string);
  var
    D: Integer;
  begin
    D := Pos(',', Value);
    if D > 0 then
      Value[D] := '.';
  end;

begin
  FS := TFormatSettings.Invariant;
  SetLength(Curve, Lines.Count);
  SetLength(Header, 0);
  N := 0;
  MinPositive := 1000;      // unit_SeriesIO's seed for the running minimum
  Separator := #9;
  for I := 0 to Lines.Count - 1 do
  begin
    Line := Lines[I];
    if Trim(Line) = '' then
      Continue;

    S := TrimLeft(Line);    // trailing whitespace is left alone: it can be the separator
    P := Pos(Separator, S);
    if P = 0 then
    begin
      if Separator = #9 then Alt := ' ' else Alt := #9;
      P := Pos(Alt, S);
      if P > 0 then
        Separator := Alt;
    end;

    if P > 0 then
    begin
      S1 := Trim(Copy(S, 1, P - 1));
      S2 := Trim(Copy(S, P + 1, MaxInt));
      if StartsAngle(S1) and StartsIntensity(S2) then
      begin
        FixDecimalPoint(S1);
        FixDecimalPoint(S2);
        if TryStrToFloat(S1, X, FS) and TryStrToFloat(S2, Y, FS) then
        begin
          if (Y > 0) and (Y < MinPositive) then
            MinPositive := Y;
          if Y <= 0 then
            Y := MinPositive;
          Curve[N].t := X;
          Curve[N].r := Y;
          Inc(N);
          Continue;
        end;
      end;
    end;

    AppendStr(Header, Line);
  end;
  SetLength(Curve, N);
  Result := N;
end;


/// <summary>A key read as text whatever its JSON type, so that
/// {"date": 20260901} is not an error.</summary>
function MetaText(Obj: TJSONObject; const Key: string): string;
var
  V: TJSONValue;
begin
  V := Obj.FindValue(Key);
  if (V = nil) or (V is TJSONNull) then
    Exit('');
  Result := V.Value;
end;

function ReadMeta(const Dir: string; out Meta: TInboxMeta): Boolean;
var
  Path, TU: string;
  SL: TStringList;
  V: TJSONValue;
begin
  Meta := Default(TInboxMeta);
  Meta.ThetaUnit := 'theta';

  Path := TPath.Combine(Dir, 'meta.json');
  if not TFile.Exists(Path) then
    Exit(False);

  SL := TStringList.Create;
  try
    LoadTextShared(SL, Path);
    V := TJSONObject.ParseJSONValue(SL.Text);
  finally
    SL.Free;
  end;
  if not (V is TJSONObject) then
  begin
    V.Free;
    raise EMCPError.Create('invalid_argument', 'meta.json is not valid JSON',
      WorkDir.RelativePath(Path));
  end;

  Meta.Raw := TJSONObject(V);
  Meta.Present := True;
  try
    if JSONArgs.Has(Meta.Raw, 'lambda') then
    begin
      Meta.Lambda := JSONArgs.ReqFloat(Meta.Raw, 'lambda');
      if Meta.Lambda <= 0 then
        raise EMCPError.Create('invalid_argument',
          'meta.json "lambda" must be greater than zero Angstrom', WorkDir.RelativePath(Path));
    end
    else if JSONArgs.Has(Meta.Raw, 'energy') then
      Meta.Lambda := EnergyToLambda(JSONArgs.ReqFloat(Meta.Raw, 'energy'));

    Meta.DateStr := MetaText(Meta.Raw, 'date');
    Meta.Instrument := MetaText(Meta.Raw, 'instrument');

    if JSONArgs.Has(Meta.Raw, 'theta_unit') then
    begin
      TU := LowerCase(Trim(MetaText(Meta.Raw, 'theta_unit')));
      if (TU <> 'theta') and (TU <> '2theta') then
        raise EMCPError.Create('invalid_argument',
          'meta.json "theta_unit" must be "theta" or "2theta"', TU);
      Meta.ThetaUnit := TU;
      Meta.ThetaUnitDeclared := True;
    end;
  except
    FreeAndNil(Meta.Raw);
    Meta.Present := False;
    raise;
  end;
  Result := True;
end;


procedure SplitMeasurementId(const Id: string; out Specimen, FileName: string);
const
  SHAPE = 'measurement_id must be "<specimen>/<file>", one folder deep';
var
  Parts: TArray<string>;
  S, Ext: string;
begin
  S := StringReplace(Trim(Id), '\', '/', [rfReplaceAll]);
  if S = '' then
    raise EMCPError.Create('invalid_argument', 'measurement_id must not be empty');

  Parts := S.Split(['/']);
  if Length(Parts) <> 2 then
    raise EMCPError.Create('invalid_argument', SHAPE, Id);
  Specimen := Parts[0];
  FileName := Parts[1];
  if (Specimen = '') or (FileName = '') then
    raise EMCPError.Create('invalid_argument', SHAPE, Id);
  if (Specimen = '.') or (Specimen = '..') or (FileName = '.') or (FileName = '..') then
    raise EMCPError.Create('invalid_argument',
      '"." and ".." are not allowed in a measurement_id', Id);

  Ext := LowerCase(TPath.GetExtension(FileName));
  if not IsMeasurementFile(FileName) then
    raise EMCPError.Create('invalid_argument',
      Format('A measurement file has one of these extensions: %s', [ExtensionList]),
      IfThen(Ext = '', Id, Ext));
end;


function DecimateCurve(const C: unit_Types.TDataArray; MaxPoints: Integer): unit_Types.TDataArray;
var
  N, K, M, I: Integer;
begin
  N := Length(C);
  if (MaxPoints <= 0) or (N <= MaxPoints) then
    Exit(C);
  if MaxPoints < 2 then
    MaxPoints := 2;                 // both ends have to fit

  K := Ceil(N / MaxPoints);
  M := Ceil(N / K);                 // <= MaxPoints, because K >= N / MaxPoints
  SetLength(Result, M);
  for I := 0 to M - 1 do
    Result[I] := C[I * K];
  Result[M - 1] := C[N - 1];
end;


/// <summary>Drops the two headers SeriesFromFile knows about: the 21-line block
/// a "Sample" first line announces, and the leading '*' description, which is
/// kept and returned.</summary>
procedure StripFileHeader(SL: TStringList; out Description: TArray<string>);
var
  I: Integer;
begin
  SetLength(Description, 0);
  if SL.Count = 0 then
    Exit;
  if Pos('Sample', SL[0]) > 0 then
    for I := 1 to 21 do
      if SL.Count > 0 then
        SL.Delete(0);
  while (SL.Count > 0) and (SL[0] <> '') and (SL[0][1] = '*') do
  begin
    AppendStr(Description, SL[0]);
    SL.Delete(0);
  end;
end;

function LoadMeasurement(const Id: string; MaxPoints: Integer): TMeasurement;
var
  Specimen, FileName, Rel: string;
  SL: TStringList;
  Description, Parsed: TArray<string>;
  Full: unit_Types.TDataArray;
  I: Integer;
  IsXRDML: Boolean;
  Scan: TXRDMLScan;
begin
  Result := Default(TMeasurement);
  SplitMeasurementId(Id, Specimen, FileName);
  Result.Id := Specimen + '/' + FileName;

  Rel := 'inbox\' + Specimen + '\' + FileName;
  Result.Path := WorkDir.ResolvePath(Rel, False);
  if not TFile.Exists(Result.Path) then
    raise EMCPError.Create('not_found',
      Format('No measurement "%s" in the inbox', [Result.Id]),
      WorkDir.RelativePath(Result.Path));

  IsXRDML := IsXRDMLFile(Result.Path);
  SetLength(Parsed, 0);
  if IsXRDML then
  begin
    try
      Scan := ReadXRDMLFile(Result.Path);
    except
      on E: EXRDMLError do
        raise EMCPError.Create('invalid_argument',
          'The XRDML file cannot be read: ' + E.Message, WorkDir.RelativePath(Result.Path));
    end;
    Full := Scan.Curve;
    Description := Scan.DescriptionLines;
    Result.IsXRDML := True;
    Result.XRDML := Scan;
    { its own copy: Full is converted to theta in place below, and the record
      promises the file's axis }
    Result.XRDML.Curve := Copy(Scan.Curve);
  end
  else
  begin
    SL := TStringList.Create;
    try
      LoadTextShared(SL, Result.Path);
      StripFileHeader(SL, Description);
      ParseCurveText(SL, Full, Parsed);
    finally
      SL.Free;
    end;
  end;

  Result.HeaderLines := Description;
  for I := 0 to High(Parsed) do
    AppendStr(Result.HeaderLines, Parsed[I]);

  if Length(Full) = 0 then
    raise EMCPError.Create('invalid_argument',
      'No two-column numeric data found in the measurement file',
      WorkDir.RelativePath(Result.Path));

  ReadMeta(ExtractFileDir(Result.Path), Result.Meta);
  try
    if Result.Meta.Lambda > 0 then
      Result.LambdaSource := 'meta.json';
    { The file's facts win over meta.json: the axis it was scanned on, and the
      wavelength it was measured at (the doublet weighted by its ratio when the
      optic passes both lines, kAlpha1 otherwise). The author's rule: a
      wavelength typed by hand is the operator error this import removes. A
      meta.json that says otherwise is reported in the header, not used. }
    if IsXRDML then
    begin
      if SameText(Scan.XAxis, '2Theta') then
        Result.Meta.ThetaUnit := '2theta'
      else
        Result.Meta.ThetaUnit := 'theta';
      Result.Meta.ThetaUnitDeclared := True;
      if Scan.Lambda > 0 then
      begin
        if (Result.Meta.Lambda > 0) and (Abs(Result.Meta.Lambda - Scan.Lambda) > 1E-6) then
          AppendStr(Result.HeaderLines, Format('* meta.json lambda %s A is not used: the file implies %s A (%s)',
            [FloatToStr(Result.Meta.Lambda, TFormatSettings.Invariant),
             FormatFloat('0.000000', Scan.Lambda, TFormatSettings.Invariant), Scan.LambdaRule]));
        Result.Meta.Lambda := Scan.Lambda;
        Result.LambdaSource := 'file: ' + Scan.LambdaRule;
      end;
    end;
    Result.Converted2Theta := SameText(Result.Meta.ThetaUnit, '2theta');
    if Result.Converted2Theta then
    begin
      for I := 0 to High(Full) do
        Full[I].t := TwoThetaToTheta(Full[I].t);
      Result.Columns := '2theta,intensity';
    end
    else
      Result.Columns := 'theta,intensity';

    Result.Points := Length(Full);
    Result.ThetaMin := Full[0].t;
    Result.ThetaMax := Full[0].t;
    for I := 1 to High(Full) do
    begin
      Result.ThetaMin := Min(Result.ThetaMin, Full[I].t);
      Result.ThetaMax := Max(Result.ThetaMax, Full[I].t);
    end;

    Result.Curve := DecimateCurve(Full, MaxPoints);
  except
    FreeAndNil(Result.Meta.Raw);
    raise;
  end;
end;


function SortedNames(const A: TArray<string>): TArray<string>;
begin
  Result := Copy(A, 0, Length(A));
  TArray.Sort<string>(Result, TStringComparer.Ordinal);
end;

function ListMeasurements(const SpecimenFilter: string): TJSONArray;
var
  Dir, F, Specimen, Filter: string;
  Obj, FileObj: TJSONObject;
  Files: TJSONArray;
  Meta: TInboxMeta;
begin
  Filter := Trim(SpecimenFilter);
  Result := TJSONArray.Create;
  try
    if not TDirectory.Exists(WorkDir.InboxDir) then
      Exit;
    for Dir in SortedNames(TDirectory.GetDirectories(WorkDir.InboxDir)) do
    begin
      Specimen := ExtractFileName(ExcludeTrailingPathDelimiter(Dir));
      if (Filter <> '') and not SameText(Specimen, Filter) then
        Continue;

      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('specimen', Specimen);

      Files := TJSONArray.Create;
      Obj.AddPair('files', Files);
      for F in SortedNames(TDirectory.GetFiles(Dir)) do
      begin
        if not IsMeasurementFile(F) then
          Continue;
        FileObj := TJSONObject.Create;
        Files.AddElement(FileObj);
        FileObj.AddPair('name', ExtractFileName(F));
        FileObj.AddPair('id', Specimen + '/' + ExtractFileName(F));
        FileObj.AddPair('size', TJSONNumber.Create(FileSizeOf(F)));
        FileObj.AddPair('sha256', FileSHA256(F));
        FileObj.AddPair('modified_utc', FileModifiedUTC(F));
      end;

      { A meta.json this specimen cannot parse must not cost the client the
        listing of every other specimen: it is reported on the specimen it
        belongs to and the call succeeds. get_measurement on a file in that
        folder still raises - there the metadata is part of the answer. }
      try
        if ReadMeta(Dir, Meta) then
          Obj.AddPair('meta', Meta.Raw)   // ownership moves into the result
        else
          Obj.AddPair('meta', TJSONNull.Create);
      except
        on E: EMCPError do
        begin
          Obj.AddPair('meta', TJSONNull.Create);
          Obj.AddPair('meta_error', E.Message);
        end;
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

function LooseFileCount: Integer;
begin
  if not TDirectory.Exists(WorkDir.InboxDir) then
    Exit(0);
  Result := Length(TDirectory.GetFiles(WorkDir.InboxDir));
end;

function ListMeasurementsJSON(const SpecimenFilter: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('inbox', 'inbox\');
    Result.AddPair('specimens', ListMeasurements(SpecimenFilter));
    Result.AddPair('loose_files', TJSONNumber.Create(LooseFileCount));
  except
    Result.Free;
    raise;
  end;
end;


function CurveToJSONArray(const Curve: unit_Types.TDataArray): TJSONArray;
var
  I: Integer;
  PointPair: TJSONArray;
begin
  Result := TJSONArray.Create;
  try
    for I := 0 to High(Curve) do
    begin
      PointPair := TJSONArray.Create;
      Result.AddElement(PointPair);
      PointPair.AddElement(JSONArgs.Num(Curve[I].t));
      PointPair.AddElement(JSONArgs.Num(Curve[I].r));
    end;
  except
    Result.Free;
    raise;
  end;
end;

function StringsToJSON(const A: TArray<string>): TJSONArray;
var
  I: Integer;
begin
  Result := TJSONArray.Create;
  for I := 0 to High(A) do
    Result.Add(A[I]);
end;

function GetMeasurementJSON(const Id: string; MaxPoints: Integer): TJSONObject;
var
  M: TMeasurement;
  Range: TJSONArray;
begin
  if MaxPoints < 2 then
    raise EMCPError.Create('invalid_argument',
      '"max_points" must be at least 2, so that both ends of the curve fit',
      IntToStr(MaxPoints));
  M := LoadMeasurement(Id, MaxPoints);
  try
    Result := TJSONObject.Create;
    try
      Result.AddPair('measurement_id', M.Id);
      Result.AddPair('file', WorkDir.RelativePath(M.Path));
      Result.AddPair('points', TJSONNumber.Create(M.Points));
      Result.AddPair('points_returned', TJSONNumber.Create(Length(M.Curve)));

      Range := TJSONArray.Create;
      Result.AddPair('theta_range', Range);
      Range.AddElement(JSONArgs.Num(M.ThetaMin));
      Range.AddElement(JSONArgs.Num(M.ThetaMax));

      Result.AddPair('columns', M.Columns);
      Result.AddPair('converted_from_2theta', TJSONBool.Create(M.Converted2Theta));
      Result.AddPair('theta_unit', M.Meta.ThetaUnit);
      Result.AddPair('theta_unit_assumed', TJSONBool.Create(not M.Meta.ThetaUnitDeclared));

      if M.Meta.Lambda > 0 then
      begin
        Result.AddPair('lambda', JSONArgs.Num(M.Meta.Lambda));
        Result.AddPair('lambda_source', M.LambdaSource);
      end
      else
      begin
        Result.AddPair('lambda', TJSONNull.Create);
        Result.AddPair('lambda_source', TJSONNull.Create);
      end;

      if M.Meta.Present then
      begin
        Result.AddPair('meta', M.Meta.Raw);   // ownership moves into the result
        M.Meta.Raw := nil;
      end
      else
        Result.AddPair('meta', TJSONNull.Create);

      Result.AddPair('header', StringsToJSON(M.HeaderLines));
      Result.AddPair('curve', CurveToJSONArray(M.Curve));
    except
      Result.Free;
      raise;
    end;
  finally
    M.Meta.Raw.Free;
  end;
end;

end.
