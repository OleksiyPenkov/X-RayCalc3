unit unit_MCPMaterials;

(* The Henke material database, seen from the MCP side.

   The server never has its own table directory: it reads exactly the tables
   the GUI reads, through TConfig.SystemDir[sdHenke]. It never *writes* the
   configuration - assigning TConfig.SystemDir persists xrc3.ini, so the path
   is only ever read here.

   Two things the GUI never needed and this unit adds:

   - Canonical names. The .bin files on disk are inconsistently cased
     ("RU.bin", "Si.bin", "B4C.bin"). Windows file lookups are case-insensitive
     so the engine does not care, but list_materials has to report *a* name and
     an agent that echoes it back must get a hit. The directory is listed once
     and cached; ResolveHenkeName maps any casing onto the name as it appears
     on disk.

   - Formulae. A table name such as "B4C" is decomposed into element symbols so
     that list_materials can be filtered by an element pool and optical_constants
     can report the absorption edges of the constituent elements. This is a
     *description* of a table that already exists - it is not a composition
     syntax: there is no "W0.7Si0.3" table and the server cannot mix one. *)

interface

uses
  System.SysUtils, System.JSON;

type
  TFormulaPart = record
    Symbol: string;
    Count: Double;
  end;

  TMaterialEntry = record
    Name: string;                  // file base name exactly as it is on disk
    AtomicMass: Double;            // A, g/mol      - from the .bin header
    BulkDensity: Double;           // rho, g/cm^3   - from the .bin header
    Parsed: Boolean;               // the name decomposes into element symbols
    Parts: TArray<TFormulaPart>;
    IsElement: Boolean;            // the name is a single element symbol
  end;

const
  HENKE_SOURCE_NOTE =
    'X-Ray Calc .bin conversions of CXRO Henke f1/f2 tables; provenance not embedded ' +
    '- see open question 4';
  DEFAULT_EDGE_WINDOW = 0.25;

/// <summary>The GUI's Henke directory, with a trailing path delimiter.</summary>
function HenkeDir: string;
/// <summary>True when a table exists for this name, in any casing.</summary>
function HenkeExists(const Material: string): Boolean;
/// <summary>Maps any casing of a table name onto the base name as it is
/// spelled on disk. False (and Canonical = '') when there is no such table.</summary>
function ResolveHenkeName(const Material: string; out Canonical: string): Boolean;
/// <summary>Every table, or - when ElementFilter is not empty - every table
/// whose name decomposes into element symbols that are all in the filter.
/// Names that do not decompose are dropped by a non-empty filter.</summary>
function ListMaterials(const ElementFilter: TArray<string>): TArray<TMaterialEntry>;
/// <summary>Decomposes a chemical formula: 'B4C' -> [B:4, C:1],
/// 'W0.7Si0.3' -> [W:0.7, Si:0.3]. False when the string is empty, does not
/// parse completely, or names something that is not an element symbol.</summary>
function ParseFormula(const S: string; out Parts: TArray<TFormulaPart>): Boolean;
/// <summary>delta and beta of n = 1 - delta + i*beta at LambdaA Angstrom.
/// Density <= 0 means the bulk value from the table header. False when there
/// is no table for Material.</summary>
function OpticalConstants(const Material: string; LambdaA, Density: Double;
  out DensityUsed, Delta, Beta: Double): Boolean;
/// <summary>Absorption edges of the elements of Material within
/// +/-WindowFraction*EeV of EeV, nearest first:
/// [{element, edge_eV, distance_eV}]. Caller frees.</summary>
function NearestEdges(const Material: string; EeV, WindowFraction: Double): TJSONArray;
/// <summary>{path, table_count, newest_file_utc, source_note}. Caller frees.</summary>
function HenkeSummary: TJSONObject;

/// <summary>The XRF lines file: --lines &lt;file&gt;, else XRFLinesPath from
/// XRFCalc.ini beside the exe, else ..\..\Shared\Universal\xrf_lines.json,
/// else xrf_lines.json beside the exe. '' when none of them exists.</summary>
function ResolveLinesFile: string;
/// <summary>The template library: --templates &lt;file&gt;, else TemplatePath
/// from XRFCalc.ini beside the exe. '' when there is none - the server runs
/// without templates and list_templates then returns an empty array.</summary>
function ResolveTemplatesFile: string;

var
  // Filled once at startup by RunServer, reported by describe_server.
  LinesFile: string = '';
  TemplatesFile: string = '';

implementation

uses
  System.Classes, System.Math, System.IOUtils, System.IniFiles,
  System.Generics.Collections, System.Generics.Defaults,
  math_complex, math_globals, unit_Config,
  // ClassicalElectronRadius: unit_materials keeps its copy in the
  // implementation section, so the identical exported one from
  // unit_materials_mix is used instead of adding a fourth copy of the number.
  unit_materials_mix,
  unit_MCPErrors, unit_MCPSandbox;

const
  // The 118 element symbols, canonical casing. A formula token has to be one
  // of these; nothing else is accepted as an element.
  ELEMENT_SYMBOLS: array [0 .. 117] of string = (
    'H',  'He', 'Li', 'Be', 'B',  'C',  'N',  'O',  'F',  'Ne',
    'Na', 'Mg', 'Al', 'Si', 'P',  'S',  'Cl', 'Ar', 'K',  'Ca',
    'Sc', 'Ti', 'V',  'Cr', 'Mn', 'Fe', 'Co', 'Ni', 'Cu', 'Zn',
    'Ga', 'Ge', 'As', 'Se', 'Br', 'Kr', 'Rb', 'Sr', 'Y',  'Zr',
    'Nb', 'Mo', 'Tc', 'Ru', 'Rh', 'Pd', 'Ag', 'Cd', 'In', 'Sn',
    'Sb', 'Te', 'I',  'Xe', 'Cs', 'Ba', 'La', 'Ce', 'Pr', 'Nd',
    'Pm', 'Sm', 'Eu', 'Gd', 'Tb', 'Dy', 'Ho', 'Er', 'Tm', 'Yb',
    'Lu', 'Hf', 'Ta', 'W',  'Re', 'Os', 'Ir', 'Pt', 'Au', 'Hg',
    'Tl', 'Pb', 'Bi', 'Po', 'At', 'Rn', 'Fr', 'Ra', 'Ac', 'Th',
    'Pa', 'U',  'Np', 'Pu', 'Am', 'Cm', 'Bk', 'Cf', 'Es', 'Fm',
    'Md', 'No', 'Lr', 'Rf', 'Db', 'Sg', 'Bh', 'Hs', 'Mt', 'Ds',
    'Rg', 'Cn', 'Nh', 'Fl', 'Mc', 'Lv', 'Ts', 'Og');

  // An edge: f2 jumps by more than this factor between two adjacent table
  // points that are closer together than EDGE_MAX_STEP in relative energy.
  EDGE_F2_RATIO = 1.5;
  EDGE_MAX_STEP = 0.02;

var
  // The directory listing and the parsed table headers, built once. FCacheDir
  // is the directory the cache was built for; if the configuration ever
  // pointed somewhere else the cache rebuilds itself.
  FCacheDir: string = '';
  FCacheValid: Boolean = False;
  FEntries: TArray<TMaterialEntry>;

function HenkeDir: string;
begin
  Result := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);
end;

{ ---------------- formula parsing ---------------- }

function IsElementSymbol(const S: string): Boolean;
var
  I: Integer;
begin
  for I := Low(ELEMENT_SYMBOLS) to High(ELEMENT_SYMBOLS) do
    if ELEMENT_SYMBOLS[I] = S then
      Exit(True);
  Result := False;
end;

/// <summary>The canonical spelling of an element symbol written in any case,
/// or '' when there is no such element.</summary>
function CanonicalElement(const S: string): string;
var
  I: Integer;
begin
  for I := Low(ELEMENT_SYMBOLS) to High(ELEMENT_SYMBOLS) do
    if SameText(ELEMENT_SYMBOLS[I], S) then
      Exit(ELEMENT_SYMBOLS[I]);
  Result := '';
end;

function ParseFormulaStrict(const S: string; out Parts: TArray<TFormulaPart>): Boolean;
var
  I, Start, N: Integer;
  Sym, Digits: string;
  Part: TFormulaPart;
begin
  SetLength(Parts, 0);
  if S = '' then
    Exit(False);

  I := 1;
  N := Length(S);
  while I <= N do
  begin
    // symbol: an upper-case letter and an optional lower-case letter
    if not CharInSet(S[I], ['A' .. 'Z']) then
      Exit(False);
    Sym := S[I];
    Inc(I);
    if (I <= N) and CharInSet(S[I], ['a' .. 'z']) then
    begin
      Sym := Sym + S[I];
      Inc(I);
    end;
    if not IsElementSymbol(Sym) then
      Exit(False);

    // count: an optional number, integer or decimal
    Start := I;
    while (I <= N) and CharInSet(S[I], ['0' .. '9']) do
      Inc(I);
    if (I <= N) and (S[I] = '.') then
    begin
      Inc(I);
      if (I > N) or not CharInSet(S[I], ['0' .. '9']) then
        Exit(False);           // a trailing '.' is not a number
      while (I <= N) and CharInSet(S[I], ['0' .. '9']) do
        Inc(I);
    end;
    Digits := Copy(S, Start, I - Start);

    Part.Symbol := Sym;
    if Digits = '' then
      Part.Count := 1
    else
      Part.Count := StrToFloat(Digits, TFormatSettings.Invariant);
    SetLength(Parts, Length(Parts) + 1);
    Parts[High(Parts)] := Part;
  end;

  Result := Length(Parts) > 0;
end;

function ParseFormula(const S: string; out Parts: TArray<TFormulaPart>): Boolean;
var
  Sym: string;
  Part: TFormulaPart;
begin
  if ParseFormulaStrict(S, Parts) then
    Exit(True);

  { Legacy all-caps element files. Half of the single-element tables on disk
    are spelled "RU.bin", "FE.bin", "SI.bin"; strictly tokenised, "RU" is R
    followed by U and R is not an element. The whole string is therefore given
    one more chance as a single element symbol written in the wrong case. This
    is deliberately limited to the *entire* string being one symbol: a
    case-insensitive tokeniser would happily read "SiIMD" as Si-I-Md. }
  SetLength(Parts, 0);
  if (Length(S) < 1) or (Length(S) > 2) then
    Exit(False);
  Sym := CanonicalElement(S);
  if Sym = '' then
    Exit(False);
  Part.Symbol := Sym;
  Part.Count := 1;
  SetLength(Parts, 1);
  Parts[0] := Part;
  Result := True;
end;

{ ---------------- the table directory ---------------- }

/// <summary>Atomic mass and bulk density from a .bin header: an int32-prefixed
/// name string followed by two singles.</summary>
function ReadHenkeHeader(const Path: string; out AtomicMass, BulkDensity: Double): Boolean;
var
  Stream: TFileStream;
  Size: Integer;
  Na, Nro: Single;
begin
  Result := False;
  AtomicMass := 0;
  BulkDensity := 0;
  try
    Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
    try
      if Stream.Size < SizeOf(Integer) then
        Exit;
      Stream.ReadBuffer(Size, SizeOf(Size));
      if (Size < 0) or (Stream.Position + Size + 2 * SizeOf(Single) > Stream.Size) then
        Exit;
      Stream.Position := Stream.Position + Size;
      Stream.ReadBuffer(Na, SizeOf(Na));
      Stream.ReadBuffer(Nro, SizeOf(Nro));
      AtomicMass := Na;
      BulkDensity := Nro;
      Result := True;
    finally
      Stream.Free;
    end;
  except
    on E: EStreamError do
      Result := False;
    on E: EInOutError do
      Result := False;
  end;
end;

procedure BuildCache;
var
  Dir: string;
  Files: TArray<string>;
  I: Integer;
  Entry: TMaterialEntry;
begin
  Dir := HenkeDir;
  if FCacheValid and SameText(FCacheDir, Dir) then
    Exit;

  SetLength(FEntries, 0);
  FCacheDir := Dir;
  FCacheValid := True;      // an unreadable directory caches as "no tables"
  if not TDirectory.Exists(Dir) then
    Exit;

  Files := TDirectory.GetFiles(Dir, '*.bin');
  TArray.Sort<string>(Files, TComparer<string>.Construct(
    function(const A, B: string): Integer
    begin
      Result := CompareText(TPath.GetFileNameWithoutExtension(A),
                            TPath.GetFileNameWithoutExtension(B));
    end));

  SetLength(FEntries, Length(Files));
  for I := 0 to High(Files) do
  begin
    Entry := Default(TMaterialEntry);
    Entry.Name := TPath.GetFileNameWithoutExtension(Files[I]);
    ReadHenkeHeader(Files[I], Entry.AtomicMass, Entry.BulkDensity);
    Entry.Parsed := ParseFormula(Entry.Name, Entry.Parts);
    Entry.IsElement := Entry.Parsed and (Length(Entry.Parts) = 1) and
      (Entry.Parts[0].Count = 1);
    FEntries[I] := Entry;
  end;
end;

function ResolveHenkeName(const Material: string; out Canonical: string): Boolean;
var
  I: Integer;
begin
  Canonical := '';
  if Material.Trim = '' then
    Exit(False);
  BuildCache;
  for I := 0 to High(FEntries) do
    if SameText(FEntries[I].Name, Material) then
    begin
      Canonical := FEntries[I].Name;
      Exit(True);
    end;
  Result := False;
end;

function HenkeExists(const Material: string): Boolean;
var
  Canonical: string;
begin
  Result := ResolveHenkeName(Material, Canonical);
end;

function ListMaterials(const ElementFilter: TArray<string>): TArray<TMaterialEntry>;

  function InFilter(const Symbol: string): Boolean;
  var
    K: Integer;
  begin
    for K := 0 to High(ElementFilter) do
      if SameText(ElementFilter[K], Symbol) then
        Exit(True);
    Result := False;
  end;

  function Keep(const Entry: TMaterialEntry): Boolean;
  var
    J: Integer;
  begin
    if Length(ElementFilter) = 0 then
      Exit(True);
    if not Entry.Parsed then
      Exit(False);
    for J := 0 to High(Entry.Parts) do
      if not InFilter(Entry.Parts[J].Symbol) then
        Exit(False);
    Result := True;
  end;

var
  I, Count: Integer;
begin
  BuildCache;
  SetLength(Result, Length(FEntries));
  Count := 0;
  for I := 0 to High(FEntries) do
    if Keep(FEntries[I]) then
    begin
      Result[Count] := FEntries[I];
      Inc(Count);
    end;
  SetLength(Result, Count);
end;

{ ---------------- optical constants ---------------- }

function OpticalConstants(const Material: string; LambdaA, Density: Double;
  out DensityUsed, Delta, Beta: Double): Boolean;
var
  Canonical: string;
  f: TComplex;
  Na, Nro: Single;
  c: Double;
begin
  DensityUsed := 0;
  Delta := 0;
  Beta := 0;
  if not ResolveHenkeName(Material, Canonical) then
    Exit(False);

  Na := 0;
  Nro := 0;
  f.Re := 0;
  f.Im := 0;
  // E = 0 makes ReadHenke interpolate at H/lambda, exactly as the engines do.
  ReadHenke(Canonical, 0, LambdaA, f, Na, Nro);
  if Na <= 0 then
    raise EMCPError.Create('internal',
      Format('Henke table "%s" has no atomic mass in its header', [Canonical]));

  if Density > 0 then
    DensityUsed := Density
  else
    DensityUsed := Nro;

  // epsilon = 1 - f1*c + i*f2*c and n = 1 - delta + i*beta with
  // epsilon ~ 1 - 2*delta + 2i*beta, so delta = f1*c/2 and beta = f2*c/2.
  c := ClassicalElectronRadius * DensityUsed / Na * Sqr(LambdaA);
  Delta := 0.5 * f.Re * c;
  Beta := 0.5 * f.Im * c;
  Result := True;
end;

type
  TEdgeHit = record
    Element: string;
    Energy: Double;
    Distance: Double;
  end;

function NearestEdges(const Material: string; EeV, WindowFraction: Double): TJSONArray;
var
  Canonical, SymFile: string;
  Parts: TArray<TFormulaPart>;
  Hits: TArray<TEdgeHit>;
  Hit: TEdgeHit;
  Table: THenkeTable;
  Na, Nro: Single;
  I, J: Integer;
  Window: Double;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    if (EeV <= 0) or (WindowFraction <= 0) then
      Exit;
    if not ResolveHenkeName(Material, Canonical) then
      Exit;
    if not ParseFormula(Canonical, Parts) then
      Exit;

    Window := WindowFraction * EeV;
    SetLength(Hits, 0);
    for I := 0 to High(Parts) do
    begin
      if not ResolveHenkeName(Parts[I].Symbol, SymFile) then
        Continue;               // no table for this element: nothing to report
      SetLength(Table, 0);      // ReadHenkeTable appends, so start empty
      ReadHenkeTable(SymFile, Na, Nro, Table);
      for J := 0 to High(Table) - 1 do
      begin
        if (Table[J].f2 <= 0) or (Table[J].e <= 0) then
          Continue;
        if (Table[J + 1].f2 / Table[J].f2 <= EDGE_F2_RATIO) then
          Continue;
        if (Table[J + 1].e - Table[J].e >= EDGE_MAX_STEP * Table[J].e) then
          Continue;
        if Abs(Table[J].e - EeV) > Window then
          Continue;
        Hit.Element := Parts[I].Symbol;
        Hit.Energy := Table[J].e;
        Hit.Distance := Table[J].e - EeV;
        SetLength(Hits, Length(Hits) + 1);
        Hits[High(Hits)] := Hit;
      end;
    end;

    TArray.Sort<TEdgeHit>(Hits, TComparer<TEdgeHit>.Construct(
      function(const A, B: TEdgeHit): Integer
      begin
        Result := CompareValue(Abs(A.Distance), Abs(B.Distance));
      end));

    for I := 0 to High(Hits) do
    begin
      Obj := TJSONObject.Create;
      Obj.AddPair('element', Hits[I].Element);
      Obj.AddPair('edge_eV', JSONArgs.Num(Hits[I].Energy));
      Obj.AddPair('distance_eV', JSONArgs.Num(Hits[I].Distance));
      Result.AddElement(Obj);
    end;
  except
    Result.Free;
    raise;
  end;
end;

function HenkeSummary: TJSONObject;
var
  Dir, Newest: string;
  Files: TArray<string>;
  I: Integer;
  NewestTime, T: TDateTime;
begin
  Dir := HenkeDir;
  BuildCache;
  Result := TJSONObject.Create;
  try
    Result.AddPair('path', ExcludeTrailingPathDelimiter(Dir));
    Result.AddPair('table_count', TJSONNumber.Create(Length(FEntries)));

    Newest := '';
    NewestTime := 0;
    if TDirectory.Exists(Dir) then
    begin
      Files := TDirectory.GetFiles(Dir, '*.bin');
      for I := 0 to High(Files) do
      begin
        T := TFile.GetLastWriteTimeUtc(Files[I]);
        if (Newest = '') or (T > NewestTime) then
        begin
          Newest := Files[I];
          NewestTime := T;
        end;
      end;
    end;
    if Newest = '' then
      Result.AddPair('newest_file_utc', TJSONNull.Create)
    else
      Result.AddPair('newest_file_utc', FileModifiedUTC(Newest));

    Result.AddPair('source_note', HENKE_SOURCE_NOTE);
  except
    Result.Free;
    raise;
  end;
end;

{ ---------------- file resolution ---------------- }

/// <summary>`--name <value>` / `--name=<value>` / `-name <value>` /
/// `/name <value>`, the same spellings TWorkDir accepts for --workdir.</summary>
function SwitchValue(const Name: string; out Value: string): Boolean;
var
  I: Integer;
  Param: string;
begin
  Value := '';
  for I := 1 to ParamCount do
  begin
    Param := ParamStr(I);
    if Param.StartsWith('--' + Name + '=', True) then
    begin
      Value := Param.Substring(Length(Name) + 3);
      Exit(True);
    end;
    if SameText(Param, '--' + Name) or SameText(Param, '-' + Name) or
       SameText(Param, '/' + Name) then
    begin
      if I < ParamCount then
        Value := ParamStr(I + 1);
      Exit(True);
    end;
  end;
  Result := False;
end;

function ExeDir: string;
begin
  Result := IncludeTrailingPathDelimiter(ExtractFilePath(ParamStr(0)));
end;

/// <summary>A key of [General] in the XRFCalc.ini beside the exe, or '' when
/// there is no ini or no such key.</summary>
function XRFCalcIniValue(const Key: string): string;
var
  IniPath: string;
  Ini: TIniFile;
begin
  Result := '';
  IniPath := ExeDir + 'XRFCalc.ini';
  if not TFile.Exists(IniPath) then
    Exit;
  Ini := TIniFile.Create(IniPath);
  try
    Result := Ini.ReadString('General', Key, '').Trim;
  finally
    Ini.Free;
  end;
end;

function ResolveLinesFile: string;
var
  Value: string;
begin
  // An explicit switch wins outright, existing or not: silently falling back
  // to a different file than the operator named would be worse than failing.
  if SwitchValue('lines', Value) then
    Exit(Value.Trim);

  Result := XRFCalcIniValue('XRFLinesPath');
  if (Result <> '') and TFile.Exists(Result) then
    Exit;

  Result := TPath.GetFullPath(ExeDir + '..\..\Shared\Universal\xrf_lines.json');
  if TFile.Exists(Result) then
    Exit;

  Result := ExeDir + 'xrf_lines.json';
  if TFile.Exists(Result) then
    Exit;

  Result := '';
end;

function ResolveTemplatesFile: string;
var
  Value: string;
begin
  if SwitchValue('templates', Value) then
    Exit(Value.Trim);

  Result := XRFCalcIniValue('TemplatePath');
  if (Result <> '') and TFile.Exists(Result) then
    Exit;

  Result := '';
end;

end.
