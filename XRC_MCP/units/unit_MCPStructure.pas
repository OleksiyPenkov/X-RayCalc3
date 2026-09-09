unit unit_MCPStructure;

(* Structure adapter: the server's JSON structure (requirements 3) <-> the GUI's
   TFitStructure <-> the GUI's XRC data string, plus the expanded TLayeredModel
   the calculation engine consumes.

   Two orders are in play and they are opposites.

   The JSON lists stacks from the substrate up to the surface, with the optional
   cap and buffer named separately. The GUI (TXRCStructure) lists them the way a
   cross-section is drawn: surface first, substrate last. So

       XRC Stacks[0]        := cap          (N = 1, one layer)   - when present
       XRC Stacks[1..k]     := JSON stacks, reversed
       XRC Stacks[k+1]      := buffer       (N = 1, one layer)   - when present
       XRC Subs             := substrate

   TStructureInfo carries what the reverse mapping needs (which XRC stack was the
   cap, which was the buffer, and where each JSON stack ended up) so that
   StructureToJSON can put a structure back the way the client sent it, and so
   that the periodic tools can find the one multilayer stack without guessing.

   Nothing here touches a VCL control: this is TXRCStructure.ToString /
   FromString / ToFitStructure / Model and TLFPSO_BASE.FillModel with the
   controls taken out, so the strings the server writes are byte-comparable with
   the strings the GUI writes. *)

interface

uses
  System.SysUtils, System.JSON,
  unit_Types, unit_materials;

const
  /// Refuse a structure that would expand past this many physical layers.
  /// The engine allocates one TCalcLayer per expanded layer and per thread.
  MAX_LAYERS = 20000;

  /// What ValidateMaterials reports for a layer whose material name is blank.
  /// A blank name is not a valid Henke table name, and returning it verbatim
  /// would be indistinguishable from "everything is fine".
  UNNAMED_MATERIAL = '<empty>';

  HDR_CAP    = 'Cap';
  HDR_ML     = 'ML';
  HDR_BUFFER = 'Buffer';
  HDR_MAIN   = 'Main';

type
  TStructureInfo = record
    PeriodicStackIndex: Integer;    // index in TFitStructure.Stacks of the first stack with N > 1, -1 if none
    Period: Double;                 // sum of layer thicknesses of that stack (Angstrom), 0 if none
    N: Integer;                     // its N, 0 if none
    HasCap, HasBuffer: Boolean;
    StackMap: TArray<Integer>;      // JSON stacks[k] (substrate->surface) -> index in TFitStructure.Stacks
    CapIndex, BufferIndex: Integer; // TFitStructure.Stacks index of cap / buffer, -1 when absent
  end;

/// <summary>An info record with no stacks: every index -1, every flag False.</summary>
function EmptyStructureInfo: TStructureInfo;

/// <summary>Parse the requirements 3 structure JSON into the GUI order (surface
/// first). Raises EMCPError('invalid_structure', ...) with the offending JSON
/// path in Detail.</summary>
function StructureFromJSON(const J: TJSONObject; out Info: TStructureInfo): TFitStructure;

/// <summary>Inverse of StructureFromJSON: GUI order -> requirements 3 JSON.
/// Info labels cap and buffer; stacks are reported substrate->surface.
/// The caller owns the result.</summary>
function StructureToJSON(const S: TFitStructure; const Info: TStructureInfo): TJSONObject;

/// <summary>The GUI's TXRCStructure.ToString format ("Stacks" / "Subs" with the
/// 16 H, HP, Hmin, ... keys per layer).</summary>
function StructureToXRCData(const S: TFitStructure; const Info: TStructureInfo): string;

/// <summary>The GUI's TXRCStructure.FromString without the controls. Derives
/// Info from the stack headers.</summary>
function StructureFromXRCData(const Data: string; out Info: TStructureInfo): TFitStructure;

/// <summary>The expanded physical model TCalc consumes: the same layers
/// TXRCStructure.Model(False) and TLFPSO_BASE.FillModel produce. Caller frees.
/// Per-period profiles (TLayerData.PP) are applied by the caller.</summary>
function BuildLayeredModel(const S: TFitStructure): TLayeredModel;

/// <summary>After Model.Generate, copy the Henke bulk density back into every
/// layer that asked for it (r = 0), so the server can echo the value used.
/// The substrate density is overwritten <b>always</b>, not only when 0: the GUI
/// engine ignores a user-supplied substrate density. TLayeredModel.PrepareLayers
/// builds the substrate permittivity from the material's bulk density and never
/// reads the substrate layer's ro, so the bulk value is the value used.</summary>
procedure FillDefaultDensities(var S: TFitStructure; Model: TLayeredModel);

/// <summary>'' when every material has a Henke table, otherwise the name of the
/// first one that has not (TConfig.SystemDir[sdHenke] + Name + '.bin').
/// A layer with no material name at all reports UNNAMED_MATERIAL, so that an
/// empty name is never mistaken for a clean result.</summary>
function ValidateMaterials(const S: TFitStructure): string;

implementation

uses
  System.Math, System.IOUtils,
  unit_MCPErrors, unit_consts, unit_Config;

{ ---------------------------------------------------------------- helpers -- }

procedure StructErr(const Msg, Path: string);
begin
  raise EMCPError.Create('invalid_structure', Msg, Path);
end;

function ObjAt(const O: TJSONObject; const Key, Path: string; Required: Boolean): TJSONObject;
var
  V: TJSONValue;
begin
  Result := nil;
  if O = nil then V := nil else V := O.FindValue(Key);
  if (V = nil) or (V is TJSONNull) then
  begin
    if Required then
      StructErr(Format('Missing "%s"', [Key]), Path);
    Exit;
  end;
  if not (V is TJSONObject) then
    StructErr(Format('"%s" must be an object', [Key]), Path);
  Result := TJSONObject(V);
end;

function ArrAt(const O: TJSONObject; const Key, Path: string; Required: Boolean): TJSONArray;
var
  V: TJSONValue;
begin
  Result := nil;
  if O = nil then V := nil else V := O.FindValue(Key);
  if (V = nil) or (V is TJSONNull) then
  begin
    if Required then
      StructErr(Format('Missing "%s"', [Key]), Path);
    Exit;
  end;
  if not (V is TJSONArray) then
    StructErr(Format('"%s" must be an array', [Key]), Path);
  Result := TJSONArray(V);
end;

function StrAt(const O: TJSONObject; const Key, Path: string): string;
var
  V: TJSONValue;
begin
  V := O.FindValue(Key);
  if (V = nil) or (V is TJSONNull) or not (V is TJSONString) then
    StructErr(Format('"%s" must be a non-empty string', [Key]), Path);
  Result := Trim(V.Value);
  if Result = '' then
    StructErr(Format('"%s" must be a non-empty string', [Key]), Path);
end;

function NumAt(const O: TJSONObject; const Key, Path: string;
  Required: Boolean; const Default: Double): Double;
var
  V: TJSONValue;
begin
  V := O.FindValue(Key);
  if (V = nil) or (V is TJSONNull) then
  begin
    if Required then
      StructErr(Format('Missing "%s"', [Key]), Path);
    Exit(Default);
  end;
  if not (V is TJSONNumber) then
    StructErr(Format('"%s" must be a number', [Key]), Path);
  Result := TJSONNumber(V).AsDouble;
end;

/// The repeat count of a stack. Range-checked as a Double before Round, because
/// Round of a value outside the Integer range raises EInvalidOp, and that is not
/// the structured error a client should get for "N": 1e30.
function ReadStackN(const JStack: TJSONObject; const Path: string): Integer;
var
  D: Double;
begin
  D := NumAt(JStack, 'N', Path, False, 1);
  if IsNan(D) or IsInfinite(D) or (D < 1) or (D > MAX_LAYERS) then
    StructErr(Format('"N" must be a whole number between 1 and %d', [MAX_LAYERS]), Path);
  Result := Round(D);
  if (Result < 1) or (Result > MAX_LAYERS) then
    StructErr(Format('"N" must be a whole number between 1 and %d', [MAX_LAYERS]), Path);
end;

/// One JSON layer object -> one TLayerData, fully validated.
procedure ReadLayer(const JL: TJSONObject; const Path: string;
  const StackID, LayerID: Integer; var L: TLayerData);
var
  H, Sg, Ro: Double;
  p: Integer;
begin
  L := Default(TLayerData);
  L.Material := StrAt(JL, 'material', Path + '.material');

  H := NumAt(JL, 'thickness', Path + '.thickness', True, 0);
  if not (H > 0) then
    StructErr('"thickness" must be greater than 0', Path + '.thickness');

  Sg := NumAt(JL, 'sigma', Path + '.sigma', False, 0);
  if Sg < 0 then
    StructErr('"sigma" must not be negative', Path + '.sigma');

  Ro := NumAt(JL, 'density', Path + '.density', False, 0);
  if Ro < 0 then
    StructErr('"density" must not be negative', Path + '.density');

  L.P[1].V := H;
  L.P[2].V := Sg;
  L.P[3].V := Ro;
  L.StackID := StackID;
  L.LayerID := LayerID;
  // fixed by default; Task 15 opens the bounds of the free parameters
  for p := 1 to 3 do
  begin
    L.P[p].Paired := False;
    L.P[p].min := L.P[p].V;
    L.P[p].max := L.P[p].V;
  end;
end;

/// A cap or buffer object -> a one-layer stack with N = 1.
procedure ReadSingleLayerStack(const JL: TJSONObject; const Path, Header: string;
  const StackID: Integer; var Stack: TFitStack);
begin
  Stack.ID := StackID;
  Stack.N := 1;
  Stack.D := 0;
  Stack.Header := Header;
  SetLength(Stack.Layers, 1);
  ReadLayer(JL, Path, StackID, 0, Stack.Layers[0]);
end;

function EmptyStructureInfo: TStructureInfo;
begin
  Result.PeriodicStackIndex := -1;
  Result.Period := 0;
  Result.N := 0;
  Result.HasCap := False;
  Result.HasBuffer := False;
  Result.CapIndex := -1;
  Result.BufferIndex := -1;
  SetLength(Result.StackMap, 0);
end;

/// Fill Stacks[i].D (the period, as TXRCStructure.ToFitStructure writes it) and
/// the periodic-stack part of Info. Shared by both readers.
procedure FinishStructure(var S: TFitStructure; var Info: TStructureInfo);
var
  i, j: Integer;
  D: Single;
  Total: Int64;   // Int64 on purpose: Length * N overflows Integer long before
                  // it reaches MAX_LAYERS, and Release builds have no overflow
                  // checking, so an Integer accumulator can wrap back under the
                  // limit and wave a 3-billion-layer structure through
begin
  Total := 0;
  Info.PeriodicStackIndex := -1;
  Info.Period := 0;
  Info.N := 0;

  for i := 0 to High(S.Stacks) do
  begin
    // guard the multiplication before making it, not after
    if S.Stacks[i].N < 1 then
      StructErr('"N" must be 1 or more', Format('stacks[%d].N', [i]));
    if S.Stacks[i].N > MAX_LAYERS then
      StructErr(Format('"N" must not exceed %d', [MAX_LAYERS]),
        Format('stacks[%d].N', [i]));

    D := 0;
    if S.Stacks[i].N > 1 then
      for j := 0 to High(S.Stacks[i].Layers) do
        D := D + S.Stacks[i].Layers[j].P[1].V;
    S.Stacks[i].D := D;

    if (Info.PeriodicStackIndex < 0) and (S.Stacks[i].N > 1) then
    begin
      Info.PeriodicStackIndex := i;
      Info.Period := D;
      Info.N := S.Stacks[i].N;
    end;

    Total := Total + Int64(Length(S.Stacks[i].Layers)) * Int64(S.Stacks[i].N);
    if Total > MAX_LAYERS then
      Break;
  end;

  if Total > MAX_LAYERS then
    StructErr(Format('The structure expands to %d layers, the limit is %d',
      [Total, MAX_LAYERS]), 'stacks');
end;

{ ------------------------------------------------------------- JSON input -- }

function StructureFromJSON(const J: TJSONObject; out Info: TStructureInfo): TFitStructure;
var
  JSubs, JCap, JBuf, JStack: TJSONObject;
  JStacks, JLayers: TJSONArray;
  i, k, Idx, NonEmpty: Integer;
  Path: string;
  Sg, Ro: Double;
  p: Integer;
begin
  Info := EmptyStructureInfo;
  Result := Default(TFitStructure);

  if J = nil then
    StructErr('The structure must be a JSON object', '');

  JSubs := ObjAt(J, 'substrate', 'substrate', True);
  JStacks := ArrAt(J, 'stacks', 'stacks', True);
  if JStacks.Count = 0 then
    StructErr('"stacks" must hold at least one stack', 'stacks');

  JCap := ObjAt(J, 'cap', 'cap', False);
  JBuf := ObjAt(J, 'buffer', 'buffer', False);

  SetLength(Result.Stacks, JStacks.Count + Ord(JCap <> nil) + Ord(JBuf <> nil));
  SetLength(Info.StackMap, JStacks.Count);
  Idx := 0;

  if JCap <> nil then
  begin
    ReadSingleLayerStack(JCap, 'cap', HDR_CAP, Idx, Result.Stacks[Idx]);
    Info.HasCap := True;
    Info.CapIndex := Idx;
    Inc(Idx);
  end;

  // JSON lists stacks substrate -> surface; the GUI wants surface first.
  NonEmpty := 0;
  for k := JStacks.Count - 1 downto 0 do
  begin
    Path := Format('stacks[%d]', [k]);
    if not (JStacks.Items[k] is TJSONObject) then
      StructErr('Each stack must be an object', Path);
    JStack := TJSONObject(JStacks.Items[k]);

    Result.Stacks[Idx].ID := Idx;
    Result.Stacks[Idx].N := ReadStackN(JStack, Path + '.N');

    JLayers := ArrAt(JStack, 'layers', Path + '.layers', True);
    SetLength(Result.Stacks[Idx].Layers, JLayers.Count);
    for i := 0 to JLayers.Count - 1 do
    begin
      if not (JLayers.Items[i] is TJSONObject) then
        StructErr('Each layer must be an object', Format('%s.layers[%d]', [Path, i]));
      ReadLayer(TJSONObject(JLayers.Items[i]), Format('%s.layers[%d]', [Path, i]),
        Idx, i, Result.Stacks[Idx].Layers[i]);
    end;

    if JLayers.Count > 0 then
      Inc(NonEmpty);
    if Result.Stacks[Idx].N > 1 then
      Result.Stacks[Idx].Header := HDR_ML
    else
      Result.Stacks[Idx].Header := HDR_MAIN;

    Info.StackMap[k] := Idx;
    Inc(Idx);
  end;

  if NonEmpty = 0 then
    StructErr('At least one stack must hold a layer', 'stacks');

  if JBuf <> nil then
  begin
    ReadSingleLayerStack(JBuf, 'buffer', HDR_BUFFER, Idx, Result.Stacks[Idx]);
    Info.HasBuffer := True;
    Info.BufferIndex := Idx;
  end;

  // substrate: half-infinite, so P[1] is the engine's 1E8 A sentinel
  Result.Subs := Default(TLayerData);
  Result.Subs.Material := StrAt(JSubs, 'material', 'substrate.material');
  Sg := NumAt(JSubs, 'sigma', 'substrate.sigma', False, 0);
  if Sg < 0 then
    StructErr('"sigma" must not be negative', 'substrate.sigma');
  Ro := NumAt(JSubs, 'density', 'substrate.density', False, 0);
  if Ro < 0 then
    StructErr('"density" must not be negative', 'substrate.density');
  Result.Subs.P[1].V := 1E8;
  Result.Subs.P[2].V := Sg;
  Result.Subs.P[3].V := Ro;
  Result.Subs.StackID := 65535;
  Result.Subs.LayerID := 65535;
  for p := 1 to 3 do
  begin
    Result.Subs.P[p].Paired := False;
    Result.Subs.P[p].min := Result.Subs.P[p].V;
    Result.Subs.P[p].max := Result.Subs.P[p].V;
  end;

  FinishStructure(Result, Info);
end;

{ ------------------------------------------------------------ JSON output -- }

function LayerToJSON(const L: TLayerData): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('material', L.Material);
  Result.AddPair('thickness', JSONArgs.Num(L.P[1].V));
  Result.AddPair('sigma', JSONArgs.Num(L.P[2].V));
  Result.AddPair('density', JSONArgs.Num(L.P[3].V));
end;

/// The JSON has no room for a multi-layer or repeated cap or buffer: it is one
/// layer object. Rather than quietly emit the first layer and lose the rest,
/// refuse an Info that points at a stack the JSON shape cannot hold.
procedure CheckSingleLayerStack(const S: TFitStructure; const Idx: Integer;
  const What: string);
begin
  if Idx < 0 then
    Exit;
  if (Idx > High(S.Stacks)) or (S.Stacks[Idx].N <> 1) or
     (Length(S.Stacks[Idx].Layers) <> 1) then
    raise EMCPError.Create('internal',
      Format('The %s stack must have N = 1 and exactly one layer to be reported as "%s"',
        [What, What]), Format('stacks[%d]', [Idx]));
end;

function StructureToJSON(const S: TFitStructure; const Info: TStructureInfo): TJSONObject;
var
  JStacks, JLayers: TJSONArray;
  JStack, JSubs: TJSONObject;
  k, i, Idx: Integer;
begin
  CheckSingleLayerStack(S, Info.CapIndex, 'cap');
  CheckSingleLayerStack(S, Info.BufferIndex, 'buffer');

  Result := TJSONObject.Create;
  try
    JSubs := TJSONObject.Create;
    JSubs.AddPair('material', S.Subs.Material);
    JSubs.AddPair('sigma', JSONArgs.Num(S.Subs.P[2].V));
    JSubs.AddPair('density', JSONArgs.Num(S.Subs.P[3].V));
    Result.AddPair('substrate', JSubs);

    // substrate -> surface, i.e. the StackMap order
    JStacks := TJSONArray.Create;
    for k := 0 to High(Info.StackMap) do
    begin
      Idx := Info.StackMap[k];
      if (Idx < 0) or (Idx > High(S.Stacks)) then
        Continue;
      JStack := TJSONObject.Create;
      JStack.AddPair('N', TJSONNumber.Create(S.Stacks[Idx].N));
      JLayers := TJSONArray.Create;
      for i := 0 to High(S.Stacks[Idx].Layers) do
        JLayers.AddElement(LayerToJSON(S.Stacks[Idx].Layers[i]));
      JStack.AddPair('layers', JLayers);
      JStacks.AddElement(JStack);
    end;
    Result.AddPair('stacks', JStacks);

    // CheckSingleLayerStack above has already established the shape
    if Info.CapIndex >= 0 then
      Result.AddPair('cap', LayerToJSON(S.Stacks[Info.CapIndex].Layers[0]));

    if Info.BufferIndex >= 0 then
      Result.AddPair('buffer', LayerToJSON(S.Stacks[Info.BufferIndex].Layers[0]));
  except
    Result.Free;
    raise;
  end;
end;

{ ----------------------------------------------------- GUI data string I/O -- }

function StructureToXRCData(const S: TFitStructure; const Info: TStructureInfo): string;
var
  i, j, p: Integer;
  Data: TLayerData;
  JRoot, JStack, JLayer, JSub: TJSONObject;
  JStacks, JLayers: TJSONArray;
begin
  JRoot := TJSONObject.Create;
  try
    JStacks := TJSONArray.Create;
    for i := 0 to High(S.Stacks) do
    begin
      JStack := TJSONObject.Create;
      JStack.AddPair('T', S.Stacks[i].Header);
      JStack.AddPair('N', S.Stacks[i].N);

      JLayers := TJSONArray.Create;
      for j := 0 to High(S.Stacks[i].Layers) do
      begin
        Data := S.Stacks[i].Layers[j];

        JLayer := TJSONObject.Create;
        JLayer.AddPair('M', Data.Material);
        for p := 1 to 3 do
        begin
          JLayer.AddPair(PAlias[p], Data.P[p].V);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'P', Data.P[p].Paired);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'min', Data.P[p].min);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'max', Data.P[p].max);
          JLayer.AddPair('Profile' + UpperCase(PAlias[p]),
            Data.ProfileToString(TParameterType(p - 1)));
        end;
        JLayers.Add(JLayer);
      end;
      JStack.AddPair('Layers', JLayers);
      JStacks.Add(JStack);
    end;

    JSub := TJSONObject.Create;
    JSub.AddPair('M', S.Subs.Material);
    JSub.AddPair('s', S.Subs.P[2].V);
    JSub.AddPair('r', S.Subs.P[3].V);

    JRoot.AddPair('Stacks', JStacks);
    JRoot.AddPair('Subs', JSub);
    Result := JRoot.ToString;
  finally
    JRoot.Free;
  end;
end;

// TXRCStructure.FindValue / FindBoolValue / FindStrValue, without the field
function DataValue(const JL: TJSONValue; const Key: string; const Base: Single): Single;
var
  V: TJSONValue;
begin
  V := JL.FindValue(Key);
  if V <> nil then
    Result := V.AsType<Single>
  else
    Result := Base;
end;

function DataBool(const JL: TJSONValue; const Key: string): Boolean;
var
  V: TJSONValue;
begin
  V := JL.FindValue(Key);
  if V <> nil then
    Result := V.AsType<Boolean>
  else
    Result := False;
end;

function DataStr(const JL: TJSONValue; const Key: string): string;
var
  V: TJSONValue;
begin
  V := JL.FindValue(Key);
  if V <> nil then
    Result := V.AsType<string>
  else
    Result := '';
end;

function StructureFromXRCData(const Data: string; out Info: TStructureInfo): TFitStructure;
var
  JRoot: TJSONObject;
  JVal: TJSONValue;
  JStacks, JLayers: TJSONArray;
  JStack, JLayer, JSub: TJSONValue;
  i, j, p, First, Last, Count: Integer;
  PS: string;
begin
  Info := EmptyStructureInfo;
  Result := Default(TFitStructure);

  JVal := TJSONObject.ParseJSONValue(Data);
  if not (JVal is TJSONObject) then
  begin
    JVal.Free;
    StructErr('The structure data string is not a JSON object', '');
  end;
  JRoot := TJSONObject(JVal);
  try
    JSub := JRoot.FindValue('Subs');
    if JSub = nil then
      StructErr('Missing "Subs"', 'Subs');
    Result.Subs := Default(TLayerData);
    Result.Subs.Material := JSub.GetValue<string>('M');
    Result.Subs.P[1].V := 1E8;
    Result.Subs.P[2].V := JSub.GetValue<Single>('s');
    Result.Subs.P[3].V := JSub.GetValue<Single>('r');
    Result.Subs.StackID := 65535;
    Result.Subs.LayerID := 65535;
    for p := 1 to 3 do
    begin
      Result.Subs.P[p].min := Result.Subs.P[p].V;
      Result.Subs.P[p].max := Result.Subs.P[p].V;
    end;

    JStacks := JRoot.FindValue('Stacks') as TJSONArray;
    if JStacks = nil then
      StructErr('Missing "Stacks"', 'Stacks');

    SetLength(Result.Stacks, JStacks.Count);
    for i := 0 to JStacks.Count - 1 do
    begin
      JStack := JStacks.Items[i];
      Result.Stacks[i].ID := i;
      Result.Stacks[i].N := JStack.GetValue<Integer>('N');
      Result.Stacks[i].Header := JStack.GetValue<string>('T');

      JLayers := JStack.GetValue<TJSONArray>('Layers');
      SetLength(Result.Stacks[i].Layers, JLayers.Count);
      for j := 0 to JLayers.Count - 1 do
      begin
        JLayer := JLayers.Items[j];
        // a fresh record per layer: the GUI reuses one and leaks profiles into
        // the next layer when the next has none
        Result.Stacks[i].Layers[j] := Default(TLayerData);
        Result.Stacks[i].Layers[j].Material := JLayer.GetValue<string>('M');
        Result.Stacks[i].Layers[j].StackID := i;
        Result.Stacks[i].Layers[j].LayerID := j;

        for p := 1 to 3 do
        begin
          Result.Stacks[i].Layers[j].P[p].V := JLayer.GetValue<Single>(PAlias[p]);
          Result.Stacks[i].Layers[j].P[p].Paired := DataBool(JLayer, UpperCase(PAlias[p]) + 'P');
          Result.Stacks[i].Layers[j].P[p].min := DataValue(JLayer,
            UpperCase(PAlias[p]) + 'min', Result.Stacks[i].Layers[j].P[p].V);
          Result.Stacks[i].Layers[j].P[p].max := DataValue(JLayer,
            UpperCase(PAlias[p]) + 'max', Result.Stacks[i].Layers[j].P[p].V);

          PS := DataStr(JLayer, 'Profile' + UpperCase(PAlias[p]));
          if PS <> '' then
          begin
            Result.Stacks[i].Layers[j].ClearProfiles(p);
            Result.Stacks[i].Layers[j].ProfileFromString(p, PS);
          end;
        end;
      end;
    end;
  finally
    JRoot.Free;
  end;

  // Cap and buffer are recognised by the headers StructureToXRCData writes -
  // but the title alone is not enough. The JSON "cap" / "buffer" is a single
  // layer object, so a stack titled 'Cap' that carries several layers or repeats
  // (N > 1) cannot be reported that way without losing content. Such a stack
  // stays an ordinary stack in StackMap and keeps all of its layers.
  First := 0;
  Last := High(Result.Stacks);
  if (Last >= 0) and SameText(Result.Stacks[0].Header, HDR_CAP) and
     (Result.Stacks[0].N = 1) and (Length(Result.Stacks[0].Layers) = 1) then
  begin
    Info.HasCap := True;
    Info.CapIndex := 0;
    First := 1;
  end;
  if (Last >= First) and SameText(Result.Stacks[Last].Header, HDR_BUFFER) and
     (Result.Stacks[Last].N = 1) and (Length(Result.Stacks[Last].Layers) = 1) then
  begin
    Info.HasBuffer := True;
    Info.BufferIndex := Last;
    Dec(Last);
  end;

  Count := Last - First + 1;
  if Count < 0 then
    Count := 0;
  SetLength(Info.StackMap, Count);
  // StackMap is indexed substrate -> surface, the stacks run surface -> substrate
  for i := 0 to Count - 1 do
    Info.StackMap[i] := Last - i;

  FinishStructure(Result, Info);
end;

{ ------------------------------------------------------------ calculation -- }

function BuildLayeredModel(const S: TFitStructure): TLayeredModel;
var
  i, j, k, p, StackLen, MaxStackLen: Integer;
  Data: TLayersData;
begin
  Result := TLayeredModel.Create;
  try
    Result.Init;

    MaxStackLen := 1;  // at least 1 for the substrate
    for i := 0 to High(S.Stacks) do
      if Length(S.Stacks[i].Layers) > MaxStackLen then
        MaxStackLen := Length(S.Stacks[i].Layers);
    SetLength(Data, MaxStackLen);

    for i := 0 to High(S.Stacks) do
    begin
      StackLen := Length(S.Stacks[i].Layers);
      for k := 0 to StackLen - 1 do
      begin
        Data[k].Material := S.Stacks[i].Layers[k].Material;
        for p := 1 to 3 do
          Data[k].P[p].V := S.Stacks[i].Layers[k].P[p].V;
        Data[k].StackID := S.Stacks[i].Layers[k].StackID;
        Data[k].LayerID := S.Stacks[i].Layers[k].LayerID;
      end;

      for j := 1 to S.Stacks[i].N do
        Result.AddLayers(-1, Data, StackLen);
    end;

    Data[0].Material := S.Subs.Material;
    Data[0].P := S.Subs.P;
    Result.AddSubstrate(Copy(Data, 0, 1));
  except
    Result.Free;
    raise;
  end;
end;

procedure FillDefaultDensities(var S: TFitStructure; Model: TLayeredModel);

  function BulkOf(const Name: string; out Ro: Single): Boolean;
  var
    m: Integer;
    Mats: TMaterials;
  begin
    Ro := 0;
    Result := False;
    Mats := Model.Materials;
    for m := 0 to High(Mats) do
      if SameText(Mats[m].Name, Name) then
      begin
        Ro := Mats[m].ro;
        Exit(True);
      end;
  end;

var
  i, j: Integer;
  Ro: Single;
begin
  if Model = nil then
    Exit;
  for i := 0 to High(S.Stacks) do
    for j := 0 to High(S.Stacks[i].Layers) do
      if S.Stacks[i].Layers[j].P[3].V = 0 then
        if BulkOf(S.Stacks[i].Layers[j].Material, Ro) then
          S.Stacks[i].Layers[j].P[3].V := Ro;

  // The substrate is not a "when 0" case. TLayeredModel.PrepareLayers computes
  // the substrate permittivity from FMaterials[..].ro unconditionally and never
  // looks at FLayers[High].ro, so a substrate density the client supplied was
  // not used by the calculation. Echoing it back would be a lie; echo the bulk
  // value the engine actually used.
  if BulkOf(S.Subs.Material, Ro) then
    S.Subs.P[3].V := Ro;
end;

function ValidateMaterials(const S: TFitStructure): string;
var
  Dir: string;

  function Known(const Name: string): Boolean;
  begin
    Result := (Name <> '') and TFile.Exists(Dir + Name + '.bin');
  end;

  // never '' for a failure: '' is the "all materials are known" answer
  function Report(const Name: string): string;
  begin
    if Name = '' then
      Result := UNNAMED_MATERIAL
    else
      Result := Name;
  end;

var
  i, j: Integer;
begin
  Result := '';
  Dir := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);

  for i := 0 to High(S.Stacks) do
    for j := 0 to High(S.Stacks[i].Layers) do
      if not Known(S.Stacks[i].Layers[j].Material) then
        Exit(Report(S.Stacks[i].Layers[j].Material));

  if not Known(S.Subs.Material) then
    Exit(Report(S.Subs.Material));
end;

end.
