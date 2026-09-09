unit unit_MCPTools;

interface

uses System.JSON, System.SysUtils, System.Generics.Collections;

type
  TToolHandler = reference to function(const Params: TJSONObject): TJSONObject;

  TToolDef = record
    Name: string;
    Description: string;
    InputSchema: TJSONObject;   // owned
    Handler: TToolHandler;
  end;

  TToolRegistry = class
  private
    FTools: TList<TToolDef>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Register(const Name, Description: string; InputSchema: TJSONObject; Handler: TToolHandler);
    function GetToolsList: TJSONArray;       // caller frees
    function Summaries: TJSONArray;          // [{name, summary}] first sentence of Description; caller frees
    function Execute(const ToolName: string; const Params: TJSONObject): TJSONObject;
    function HasTool(const Name: string): Boolean;
  end;

// Schema builders shared by all tools units
function SchemaObject(const Required: array of string): TJSONObject;
procedure AddProp(Schema: TJSONObject; const Name, TypeName, Description: string);
procedure AddEnumProp(Schema: TJSONObject; const Name, Description: string; const Values: array of string);
procedure AddRefProp(Schema: TJSONObject; const Name, Description: string; Def: TJSONObject);
function ArraySchema(Items: TJSONObject): TJSONObject;
function StructureSchema: TJSONObject;   // the structure object of the design note, section 3

implementation

uses unit_MCPErrors;

{ TToolRegistry }

constructor TToolRegistry.Create;
begin
  inherited Create;
  FTools := TList<TToolDef>.Create;
end;

destructor TToolRegistry.Destroy;
var
  I: Integer;
begin
  for I := 0 to FTools.Count - 1 do
    FTools[I].InputSchema.Free;
  FTools.Free;
  inherited Destroy;
end;

procedure TToolRegistry.Register(const Name, Description: string;
  InputSchema: TJSONObject; Handler: TToolHandler);
var
  Def: TToolDef;
begin
  Def.Name := Name;
  Def.Description := Description;
  Def.InputSchema := InputSchema;
  Def.Handler := Handler;
  FTools.Add(Def);
end;

function TToolRegistry.GetToolsList: TJSONArray;
var
  I: Integer;
  Def: TToolDef;
  ToolObj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for I := 0 to FTools.Count - 1 do
  begin
    Def := FTools[I];
    ToolObj := TJSONObject.Create;
    ToolObj.AddPair('name', Def.Name);
    ToolObj.AddPair('description', Def.Description);
    if Def.InputSchema = nil then
      ToolObj.AddPair('inputSchema', SchemaObject([]))
    else
      ToolObj.AddPair(TJSONPair.Create('inputSchema', TJSONValue(Def.InputSchema.Clone)));
    Result.AddElement(ToolObj);
  end;
end;

function TToolRegistry.Summaries: TJSONArray;
var
  I, P: Integer;
  S: string;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  for I := 0 to FTools.Count - 1 do
  begin
    S := FTools[I].Description;
    P := Pos('. ', S);
    if P > 0 then
      S := Copy(S, 1, P);          // keep the closing period of the first sentence
    Obj := TJSONObject.Create;
    Obj.AddPair('name', FTools[I].Name);
    Obj.AddPair('summary', S.Trim);
    Result.AddElement(Obj);
  end;
end;

function TToolRegistry.Execute(const ToolName: string; const Params: TJSONObject): TJSONObject;
var
  I: Integer;
begin
  for I := 0 to FTools.Count - 1 do
    if FTools[I].Name = ToolName then
      Exit(FTools[I].Handler(Params));
  raise EMCPError.Create('tool_not_found', 'Tool not found: ' + ToolName);
end;

function TToolRegistry.HasTool(const Name: string): Boolean;
var
  I: Integer;
begin
  for I := 0 to FTools.Count - 1 do
    if FTools[I].Name = Name then
      Exit(True);
  Result := False;
end;

{ Schema builders }

/// <summary>The "properties" object of a schema built by SchemaObject.</summary>
function SchemaProps(Schema: TJSONObject): TJSONObject;
begin
  Result := Schema.GetValue('properties') as TJSONObject;
end;

function SchemaObject(const Required: array of string): TJSONObject;
var
  Arr: TJSONArray;
  I: Integer;
begin
  Result := TJSONObject.Create;
  Result.AddPair('type', 'object');
  Result.AddPair('properties', TJSONObject.Create);
  Arr := TJSONArray.Create;
  for I := Low(Required) to High(Required) do
    Arr.Add(Required[I]);
  Result.AddPair('required', Arr);
end;

procedure AddProp(Schema: TJSONObject; const Name, TypeName, Description: string);
var
  Prop: TJSONObject;
begin
  Prop := TJSONObject.Create;
  Prop.AddPair('type', TypeName);
  Prop.AddPair('description', Description);
  SchemaProps(Schema).AddPair(Name, Prop);
end;

procedure AddEnumProp(Schema: TJSONObject; const Name, Description: string; const Values: array of string);
var
  Prop: TJSONObject;
  Arr: TJSONArray;
  I: Integer;
begin
  Arr := TJSONArray.Create;
  for I := Low(Values) to High(Values) do
    Arr.Add(Values[I]);
  Prop := TJSONObject.Create;
  Prop.AddPair('type', 'string');
  Prop.AddPair('description', Description);
  Prop.AddPair('enum', Arr);
  SchemaProps(Schema).AddPair(Name, Prop);
end;

procedure AddRefProp(Schema: TJSONObject; const Name, Description: string; Def: TJSONObject);
begin
  Def.AddPair('description', Description);
  SchemaProps(Schema).AddPair(Name, Def);
end;

function ArraySchema(Items: TJSONObject): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('type', 'array');
  Result.AddPair('items', Items);
end;

function StructureSchema: TJSONObject;

  function LayerSchema: TJSONObject;
  begin
    Result := SchemaObject(['material', 'thickness']);
    AddProp(Result, 'material', 'string',
      'Henke table material name, case-insensitive (for example "Ru", "C", "B4C", "SiO2"). ' +
      'There is no composition-mixing syntax; see describe_server.material_syntax.');
    AddProp(Result, 'thickness', 'number', 'Layer thickness in Angstrom.');
    AddProp(Result, 'sigma', 'number', 'Interface roughness in Angstrom (default 0).');
    AddProp(Result, 'density', 'number',
      'Density in g/cm^3. Omit to use the Henke bulk density; the value actually used is echoed back.');
  end;

var
  Substrate, Stack: TJSONObject;
begin
  Result := SchemaObject(['substrate', 'stacks']);

  Substrate := SchemaObject(['material']);
  AddProp(Substrate, 'material', 'string', 'Henke table material name of the substrate.');
  AddProp(Substrate, 'sigma', 'number', 'Substrate roughness in Angstrom (default 0).');
  AddProp(Substrate, 'density', 'number', 'Substrate density in g/cm^3; omit for the Henke bulk density.');
  AddRefProp(Result, 'substrate', 'The substrate the stacks sit on.', Substrate);

  Stack := SchemaObject(['N', 'layers']);
  AddProp(Stack, 'N', 'integer', 'Number of repetitions of this period.');
  AddRefProp(Stack, 'layers',
    'The layers of one period, ordered from the surface downwards: layers[0] is the layer ' +
    'nearest the surface (under the cap), the last entry is nearest the substrate.',
    ArraySchema(LayerSchema));
  AddRefProp(Result, 'stacks', 'Stacks in order from the substrate to the surface.', ArraySchema(Stack));

  AddRefProp(Result, 'cap', 'Optional capping layer above the topmost stack.', LayerSchema);
  AddRefProp(Result, 'buffer', 'Optional buffer layer between the substrate and the first stack.', LayerSchema);
end;

end.
