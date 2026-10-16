(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_FitRecord;

(* [FITRESULT] is in params.dsc only while the active model is the structure the
   fit ended on; otherwise the record goes to [LASTFIT] with "modelChanged":
   true and no per-key values. A reader takes the presence of [FITRESULT] as "a
   fit result is present" and a missing chiSquared as 0, so an empty
   [FITRESULT] would report a chi-squared of 0. *)

interface

uses
  System.SysUtils, System.JSON, System.IniFiles,
  unit_Types;

const
  FIT_RECORD_SECTION = 'FITRESULT';
  LAST_FIT_SECTION = 'LASTFIT';
  MODEL_CHANGED_KEY = 'modelChanged';

  FITTING_MODE_NAMES: array [TFittingMode] of string = ('Irregular', 'Periodic', 'Polynomial');

type
  TFitRecordPlace = (frpNone, frpFitResult, frpLastFit);

const
  FIT_RECORD_PLACE_NAMES: array [TFitRecordPlace] of string = ('none', 'FITRESULT', 'LASTFIT');

function FitRecordNumber(const V: Double): TJSONValue;

function FitStructureJSON(const S: TFitStructure): TJSONObject;

function FitPolynomialsJSON(const Poly: TProfileFunctions): TJSONArray;

function FitSettingsJSON(const Settings: TFitParams; Mode: TFittingMode): TJSONObject;

function Chi2WeightingJSON(const Settings: TFitParams; PointWeight: Boolean): TJSONObject;

/// <summary>True when the record's structure (and its polynomials, when it has
/// them) is S with Poly: the repetitions, materials, values, per-period tables
/// and substrate, not the fit ranges, pairing and frozen flags or stack titles,
/// compared at the precision params.dsc and project.dsc store: Singles, the
/// tables at four decimals, and the polynomial coefficients without C[0], which
/// the file does not keep.</summary>
function FitRecordMatches(const RecordJSON: string; const S: TFitStructure;
  const Poly: TProfileFunctions): Boolean;

function FitRecordWithModelChanged(const RecordJSON: string; Changed: Boolean): string;

function WriteFitRecord(INF: TCustomIniFile; const RecordJSON: string;
  Matches: Boolean): TFitRecordPlace;

function ReadFitRecord(INF: TCustomIniFile): string;

implementation

uses
  System.Math, System.Generics.Collections, System.Generics.Defaults;

const
  PARAM_NAMES: array [1 .. 3] of string = ('thickness', 'roughness', 'density');
  SUBJ_NAMES: array [TParameterType] of string = ('thickness', 'roughness', 'density');
  THETA_WEIGHT_NAMES: array [0 .. 5] of string =
    ('none', 'theta^2', 'theta', 'sqrt(theta)', '1/theta^2', '1/sqrt(theta)');

  PER_PERIOD_KEY = 'perPeriod';

  { TProjectData.SetPoly keeps C[0..9] }
  STORED_COEFFS = 10;

  RECORD_KEYS: array [0 .. 12] of string = ('chiSquared', 'chiSquaredRecalc',
    'chiSquaredPlain', 'chi2Scale', 'scaleRatio', 'scaleClamped', 'fittingMode',
    'fitDate', 'fittingSeconds', 'fittingDevice', 'seed', 'version', 'dataItem');

function FitRecordNumber(const V: Double): TJSONValue;
begin
  if IsNan(V) or IsInfinite(V) then
    Result := TJSONNull.Create
  else
    Result := TJSONNumber.Create(V);
end;

function FitStructureJSON(const S: TFitStructure): TJSONObject;
var
  JStacks, JLayers, JTable: TJSONArray;
  JStack, JLayer, JParam, JSubstrate: TJSONObject;
  i, j, q, c: Integer;
begin
  Result := TJSONObject.Create;
  try
    JStacks := TJSONArray.Create;
    Result.AddPair('stacks', JStacks);
    for i := 0 to High(S.Stacks) do
    begin
      JStack := TJSONObject.Create;
      JStacks.AddElement(JStack);
      JStack.AddPair('name', S.Stacks[i].Header);
      JStack.AddPair('repetitions', TJSONNumber.Create(S.Stacks[i].N));

      JLayers := TJSONArray.Create;
      JStack.AddPair('layers', JLayers);
      for j := 0 to High(S.Stacks[i].Layers) do
      begin
        JLayer := TJSONObject.Create;
        JLayers.AddElement(JLayer);
        JLayer.AddPair('material', S.Stacks[i].Layers[j].Material);
        for q := 1 to 3 do
        begin
          JParam := TJSONObject.Create;
          JLayer.AddPair(PARAM_NAMES[q], JParam);
          JParam.AddPair('value', TJSONNumber.Create(S.Stacks[i].Layers[j].P[q].V));
          JParam.AddPair('min', TJSONNumber.Create(S.Stacks[i].Layers[j].P[q].min));
          JParam.AddPair('max', TJSONNumber.Create(S.Stacks[i].Layers[j].P[q].max));
          JParam.AddPair('paired', TJSONBool.Create(S.Stacks[i].Layers[j].P[q].Paired));
          JParam.AddPair('frozen', TJSONBool.Create(S.Stacks[i].Layers[j].P[q].Fixed));
          { where TLayerData.PeriodValue reads a table }
          if (S.Stacks[i].N > 1) and not S.Stacks[i].Layers[j].P[q].Paired and
             (Length(S.Stacks[i].Layers[j].PP[q]) >= S.Stacks[i].N) then
          begin
            JTable := TJSONArray.Create;
            JParam.AddPair(PER_PERIOD_KEY, JTable);
            for c := 0 to S.Stacks[i].N - 1 do
              JTable.AddElement(TJSONNumber.Create(S.Stacks[i].Layers[j].PP[q][c]));
          end;
        end;
      end;
    end;

    JSubstrate := TJSONObject.Create;
    Result.AddPair('substrate', JSubstrate);
    JSubstrate.AddPair('material', S.Subs.Material);
    JSubstrate.AddPair('roughness', TJSONNumber.Create(S.Subs.P[2].V));
    JSubstrate.AddPair('density', TJSONNumber.Create(S.Subs.P[3].V));
  except
    Result.Free;
    raise;
  end;
end;

function FitPolynomialsJSON(const Poly: TProfileFunctions): TJSONArray;
var
  JPoly: TJSONObject;
  JCoeffs: TJSONArray;
  i, c: Integer;
begin
  Result := TJSONArray.Create;
  try
    for i := 0 to High(Poly) do
    begin
      JPoly := TJSONObject.Create;
      Result.AddElement(JPoly);
      JPoly.AddPair('stack', TJSONNumber.Create(Poly[i].StackID));
      JPoly.AddPair('layer', TJSONNumber.Create(Poly[i].LayerID));
      JPoly.AddPair('parameter', SUBJ_NAMES[Poly[i].Subj]);
      JCoeffs := TJSONArray.Create;
      JPoly.AddPair('coefficients', JCoeffs);
      for c := 0 to High(Poly[i].C) do
        JCoeffs.AddElement(TJSONNumber.Create(Poly[i].C[c]));
    end;
  except
    Result.Free;
    raise;
  end;
end;

function FitSettingsJSON(const Settings: TFitParams; Mode: TFittingMode): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('maxIterations', TJSONNumber.Create(Settings.NMax));
    Result.AddPair('population', TJSONNumber.Create(Settings.Pop));
    Result.AddPair('tolerance', TJSONNumber.Create(Settings.Tolerance));
    Result.AddPair('vMax', TJSONNumber.Create(Settings.Vmax));
    Result.AddPair('jammingMax', TJSONNumber.Create(Settings.JammingMax));
    Result.AddPair('reInitMax', TJSONNumber.Create(Settings.ReInitMax));
    Result.AddPair('kChiSqr', TJSONNumber.Create(Settings.KChiSqr));
    Result.AddPair('kVmax', TJSONNumber.Create(Settings.KVmax));
    Result.AddPair('w1', TJSONNumber.Create(Settings.w1));
    Result.AddPair('w2', TJSONNumber.Create(Settings.w2));
    Result.AddPair('ksxr', TJSONNumber.Create(Settings.Ksxr));
    Result.AddPair('shake', TJSONBool.Create(Settings.Shake));
    Result.AddPair('adaptVel', TJSONBool.Create(Settings.AdaptVel));
    Result.AddPair('useConstriction', TJSONBool.Create(Settings.UseConstriction));
    if Mode <> fmPoly then          // the Polynomial engine has no range seed
      Result.AddPair('rangeSeed', TJSONBool.Create(Settings.RangeSeed));
    Result.AddPair('solveScale', TJSONBool.Create(Settings.SolveScale));
    { the fraction typed, back from the log10(1 + w) the engine holds }
    Result.AddPair('scaleSolveWindow',
      TJSONNumber.Create(RoundTo(Power(10, Settings.ScaleWindowLog) - 1, -6)));
    Result.AddPair('freePeriod', TJSONBool.Create(Settings.FreePeriod and
      (Mode = fmPeriodic)));
    if Settings.FreePeriod and (Mode = fmPeriodic) then
      Result.AddPair('periodWindow', TJSONNumber.Create(RoundTo(Settings.PeriodWindow, -6)));
    if Mode = fmPoly then
    begin
      Result.AddPair('polyOrder', TJSONNumber.Create(Settings.MaxPOrder));
      Result.AddPair('polyFactor', TJSONNumber.Create(Settings.PolyFactor));
    end;
    if Mode = fmIrregular then
    begin
      Result.AddPair('smooth', TJSONBool.Create(Settings.Smooth));
      Result.AddPair('smoothWindow', TJSONNumber.Create(Settings.SmoothWindow));
    end;
  except
    Result.Free;
    raise;
  end;
end;

function Chi2WeightingJSON(const Settings: TFitParams; PointWeight: Boolean): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('thetaWeight', TJSONNumber.Create(Settings.ThetaWeight));
    if (Settings.ThetaWeight >= Low(THETA_WEIGHT_NAMES)) and
       (Settings.ThetaWeight <= High(THETA_WEIGHT_NAMES)) then
      Result.AddPair('thetaWeightName', THETA_WEIGHT_NAMES[Settings.ThetaWeight]);
    Result.AddPair('pointWeight', TJSONBool.Create(PointWeight));
    Result.AddPair('movAvgWindow', TJSONNumber.Create(RoundTo(Settings.MovAvgWindow, -6)));
  except
    Result.Free;
    raise;
  end;
end;


function TableValue(const V: Single): Single;
begin
  Result := StrToFloat(Format('%.4f', [V], TFormatSettings.Invariant),
    TFormatSettings.Invariant);
end;

{ The fit's settings and labels, not the structure the reflectivity is
  computed from. }
function IsSetting(const Key: string): Boolean;
begin
  Result := (Key = 'name') or (Key = 'min') or (Key = 'max') or
    (Key = 'paired') or (Key = 'frozen');
end;

function StructureKeyCount(const O: TJSONObject): Integer;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to O.Count - 1 do
    if not IsSetting(O.Pairs[i].JsonString.Value) then
      Inc(Result);
end;

function SameTree(const A, B: TJSONValue; const Key: string): Boolean;
var
  i: Integer;
  Pair: TJSONPair;
  VA, VB: Single;
begin
  if (A is TJSONObject) and (B is TJSONObject) then
  begin
    if StructureKeyCount(TJSONObject(A)) <> StructureKeyCount(TJSONObject(B)) then
      Exit(False);
    for i := 0 to TJSONObject(A).Count - 1 do
    begin
      Pair := TJSONObject(A).Pairs[i];
      if IsSetting(Pair.JsonString.Value) then
        Continue;
      if not SameTree(Pair.JsonValue, TJSONObject(B).GetValue(Pair.JsonString.Value),
        Pair.JsonString.Value) then
        Exit(False);
    end;
    Exit(True);
  end;

  if (A is TJSONArray) and (B is TJSONArray) then
  begin
    if TJSONArray(A).Count <> TJSONArray(B).Count then
      Exit(False);
    for i := 0 to TJSONArray(A).Count - 1 do
      if not SameTree(TJSONArray(A).Items[i], TJSONArray(B).Items[i], Key) then
        Exit(False);
    Exit(True);
  end;

  { TJSONNumber descends from TJSONString: test it first }
  if (A is TJSONNumber) and (B is TJSONNumber) then
  begin
    VA := TJSONNumber(A).AsDouble;
    VB := TJSONNumber(B).AsDouble;
    if Key = PER_PERIOD_KEY then
      Exit(TableValue(VA) = TableValue(VB));
    Exit(VA = VB);
  end;
  if (A is TJSONNumber) or (B is TJSONNumber) then
    Exit(False);

  if (A is TJSONBool) and (B is TJSONBool) then
    Exit(TJSONBool(A).AsBoolean = TJSONBool(B).AsBoolean);

  if (A is TJSONString) and (B is TJSONString) then
    Exit(TJSONString(A).Value = TJSONString(B).Value);

  Result := (A is TJSONNull) and (B is TJSONNull);
end;

type
  TPolyEntry = record
    Stack, Layer: Integer;
    Parameter: string;
    C: TPolyArray;
  end;

function SortedEntries(const Entries: TArray<TPolyEntry>): TArray<TPolyEntry>;
begin
  Result := Copy(Entries);
  TArray.Sort<TPolyEntry>(Result, TComparer<TPolyEntry>.Construct(
    function(const L, R: TPolyEntry): Integer
    begin
      Result := CompareValue(L.Stack, R.Stack);
      if Result = 0 then
        Result := CompareValue(L.Layer, R.Layer);
      if Result = 0 then
        Result := CompareStr(L.Parameter, R.Parameter);
    end));
end;

function StoredCoeffs(const C: TPolyArray): TPolyArray;
begin
  Result := Copy(C, 0, Min(Length(C), STORED_COEFFS));
end;

function RecordEntries(const JPolys: TJSONArray; out Entries: TArray<TPolyEntry>): Boolean;
var
  i, c: Integer;
  JPoly: TJSONObject;
  JCoeffs: TJSONArray;
  Coeffs: TPolyArray;
begin
  SetLength(Entries, JPolys.Count);
  for i := 0 to JPolys.Count - 1 do
  begin
    if not (JPolys.Items[i] is TJSONObject) then
      Exit(False);
    JPoly := TJSONObject(JPolys.Items[i]);
    if not (JPoly.GetValue('stack') is TJSONNumber) or
       not (JPoly.GetValue('layer') is TJSONNumber) or
       not (JPoly.GetValue('parameter') is TJSONString) or
       not (JPoly.GetValue('coefficients') is TJSONArray) then
      Exit(False);
    Entries[i].Stack := TJSONNumber(JPoly.GetValue('stack')).AsInt;
    Entries[i].Layer := TJSONNumber(JPoly.GetValue('layer')).AsInt;
    Entries[i].Parameter := JPoly.GetValue('parameter').Value;
    JCoeffs := TJSONArray(JPoly.GetValue('coefficients'));
    SetLength(Coeffs, JCoeffs.Count);
    for c := 0 to JCoeffs.Count - 1 do
    begin
      if not (JCoeffs.Items[c] is TJSONNumber) then
        Exit(False);
      Coeffs[c] := TJSONNumber(JCoeffs.Items[c]).AsDouble;
    end;
    Entries[i].C := StoredCoeffs(Coeffs);
  end;
  Result := True;
end;

function ActiveEntries(const Poly: TProfileFunctions): TArray<TPolyEntry>;
var
  i: Integer;
begin
  SetLength(Result, Length(Poly));
  for i := 0 to High(Poly) do
  begin
    Result[i].Stack := Poly[i].StackID;
    Result[i].Layer := Poly[i].LayerID;
    Result[i].Parameter := SUBJ_NAMES[Poly[i].Subj];
    Result[i].C := StoredCoeffs(Poly[i].C);
  end;
end;

function SamePolynomials(const JPolys: TJSONArray; const Poly: TProfileFunctions): Boolean;
var
  Rec, Act: TArray<TPolyEntry>;
  i, c: Integer;
begin
  if not RecordEntries(JPolys, Rec) then
    Exit(False);
  Act := ActiveEntries(Poly);
  if Length(Rec) <> Length(Act) then
    Exit(False);
  Rec := SortedEntries(Rec);
  Act := SortedEntries(Act);
  for i := 0 to High(Rec) do
  begin
    if (Rec[i].Stack <> Act[i].Stack) or (Rec[i].Layer <> Act[i].Layer) or
       (Rec[i].Parameter <> Act[i].Parameter) or
       (Length(Rec[i].C) <> Length(Act[i].C)) then
      Exit(False);
    { C[0] is the layer's own value, compared with the structure }
    for c := 1 to High(Rec[i].C) do
      if Rec[i].C[c] <> Act[i].C[c] then
        Exit(False);
  end;
  Result := True;
end;

function FitRecordMatches(const RecordJSON: string; const S: TFitStructure;
  const Poly: TProfileFunctions): Boolean;
var
  Parsed, RecPolys: TJSONValue;
  Active: TJSONObject;
begin
  Result := False;
  if RecordJSON = '' then
    Exit;
  Parsed := TJSONObject.ParseJSONValue(RecordJSON);
  try
    if not (Parsed is TJSONObject) then
      Exit;
    Active := FitStructureJSON(S);
    try
      if not SameTree(TJSONObject(Parsed).GetValue('structure'), Active, '') then
        Exit;
    finally
      Active.Free;
    end;
    { a record without polynomials is of a fit that had none to report }
    RecPolys := TJSONObject(Parsed).GetValue('polynomials');
    if RecPolys = nil then
      Exit(True);
    Result := (RecPolys is TJSONArray) and SamePolynomials(TJSONArray(RecPolys), Poly);
  finally
    Parsed.Free;
  end;
end;

function FitRecordWithModelChanged(const RecordJSON: string; Changed: Boolean): string;
var
  Parsed, Current: TJSONValue;
  Rec: TJSONObject;
begin
  Result := RecordJSON;
  if RecordJSON = '' then
    Exit;
  Parsed := TJSONObject.ParseJSONValue(RecordJSON);
  try
    if not (Parsed is TJSONObject) then
      Exit;
    Rec := TJSONObject(Parsed);
    Current := Rec.GetValue(MODEL_CHANGED_KEY);
    if Changed then
    begin
      if (Current is TJSONBool) and TJSONBool(Current).AsBoolean then
        Exit;
      Rec.RemovePair(MODEL_CHANGED_KEY).Free;
      Rec.AddPair(MODEL_CHANGED_KEY, TJSONBool.Create(True));
    end
    else
    begin
      if Current = nil then
        Exit;
      Rec.RemovePair(MODEL_CHANGED_KEY).Free;
    end;
    Result := Rec.ToJSON;
  finally
    Parsed.Free;
  end;
end;

procedure WriteRecordKeys(INF: TCustomIniFile; const RecordJSON: string);
var
  Rec, V: TJSONValue;
  Key: string;
begin
  Rec := TJSONObject.ParseJSONValue(RecordJSON);
  try
    if Rec is TJSONObject then
      for Key in RECORD_KEYS do
      begin
        V := TJSONObject(Rec).GetValue(Key);
        if V is TJSONString then
          INF.WriteString(FIT_RECORD_SECTION, Key, V.Value)
        else if V <> nil then
          INF.WriteString(FIT_RECORD_SECTION, Key, V.ToJSON);
      end;
  finally
    Rec.Free;
  end;
end;

function WriteFitRecord(INF: TCustomIniFile; const RecordJSON: string;
  Matches: Boolean): TFitRecordPlace;
var
  Rec: string;
begin
  INF.EraseSection(FIT_RECORD_SECTION);
  INF.EraseSection(LAST_FIT_SECTION);
  if RecordJSON = '' then
    Exit(frpNone);

  if Matches then
  begin
    Rec := FitRecordWithModelChanged(RecordJSON, False);
    WriteRecordKeys(INF, Rec);
    INF.WriteString(FIT_RECORD_SECTION, 'Record', Rec);
    Result := frpFitResult;
  end
  else
  begin
    INF.WriteString(LAST_FIT_SECTION, 'Record', FitRecordWithModelChanged(RecordJSON, True));
    Result := frpLastFit;
  end;
end;

function ReadFitRecord(INF: TCustomIniFile): string;
begin
  Result := INF.ReadString(FIT_RECORD_SECTION, 'Record', '');
  if Result = '' then
    Result := INF.ReadString(LAST_FIT_SECTION, 'Record', '');
end;

end.
