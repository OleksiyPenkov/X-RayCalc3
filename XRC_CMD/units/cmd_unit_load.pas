unit cmd_unit_load;

interface

uses
  System.SysUtils,
  System.Classes,
  System.JSON,
  System.IOUtils,
  System.Generics.Collections,
  cmd_unit_materials,
  cmd_unit_types;

type
  /// <summary>
  /// Layer properties from JSON: {"SiO2": [18, 4, 3.5]}
  /// </summary>
  TLayer = record
    MaterialName: string;
    H: Double;  // T1
    Sigma: Double;  // T2
    Density: Double;     // T3
    class function FromJSON(const AJsonObj: TJSONObject): TLayer; static;
  end;

  /// <summary>
  /// Section properties: "top", "main", "bottom" blocks
  /// </summary>
  TStack = record
    SectionName: string;  // 'top', 'main', 'bottom'
    N: Integer;
    Layers: TArray<TLayer>;
    class function FromJSON(const AItemObj: TJSONObject): TStack; static;
  end;

  /// <summary>
  /// Override settings from JSON
  /// </summary>
  TOverride = record
    Lambda: Double;
    Mode: Integer;
    TwoTheta: Boolean;
    BeginVal: Integer;
    EndVal: Integer;
    class function FromJSON(const AJsonObj: TJSONObject): TOverride; static;
  end;

  /// <summary>
  /// Full config from JSON file
  /// </summary>
  TStructure = record
    Name: string;
    Override: TOverride;
    Structure: TArray<TStack>;
    class function LoadFromFile(const AFileName: string): TStructure; static;
  end;



  function LoadModel(const FileName: string; var Params: TCalcParams):TLayeredModel;

implementation

{ TLayer }

class function TLayer.FromJSON(const AJsonObj: TJSONObject): TLayer;
var
  LPair: TJSONPair;
  LArr: TJSONArray;
begin
  if (AJsonObj.Count <> 1) then
    raise Exception.Create('Invalid layer object');

  LPair := AJsonObj.Pairs[0];
  Result.MaterialName := LPair.JsonString.Value;

  LArr := LPair.JsonValue as TJSONArray;
  if (LArr = nil) or (LArr.Count < 3) then
    raise Exception.CreateFmt('Invalid layer array for %s', [Result.MaterialName]);

  Result.H := (LArr.Items[0] as TJSONNumber).AsDouble;
  Result.Sigma := (LArr.Items[1] as TJSONNumber).AsDouble;
  Result.Density    := (LArr.Items[2] as TJSONNumber).AsDouble;
end;

{ TStack }

class function TStack.FromJSON(const AItemObj: TJSONObject): TStack;
var
  LPair: TJSONPair;
  LSectionObj, LLayerObj: TJSONObject;
  LLayersArr: TJSONArray;
  LLayerVal: TJSONValue;
begin
  if (AItemObj.Count <> 1) then
    raise Exception.Create('Invalid section object');

  LPair := AItemObj.Pairs[0];
  Result.SectionName := LPair.JsonString.Value;
  LSectionObj := LPair.JsonValue as TJSONObject;

  Result.N := LSectionObj.GetValue<Integer>('N');

  LLayersArr := LSectionObj.GetValue<TJSONArray>('layers');
  if LLayersArr <> nil then
  begin
    SetLength(Result.Layers, LLayersArr.Count);
    for var i := 0 to LLayersArr.Count - 1 do
    begin
      LLayerVal := LLayersArr.Items[i];
      if LLayerVal is TJSONObject then
        Result.Layers[i] := TLayer.FromJSON(LLayerVal as TJSONObject);
    end;
  end;
end;

{ TOverride }

class function TOverride.FromJSON(const AJsonObj: TJSONObject): TOverride;
begin
  Result.Lambda   := AJsonObj.GetValue<Double>('lambda');
  Result.Mode     := AJsonObj.GetValue<Integer>('mode');
  Result.TwoTheta := AJsonObj.GetValue<Boolean>('x2theta');
  Result.BeginVal := AJsonObj.GetValue<Integer>('begin');
  Result.EndVal   := AJsonObj.GetValue<Integer>('end');
end;

{ TStructure }

class function TStructure.LoadFromFile(const AFileName: string): TStructure;
var
  LContent: string;
  LRootVal: TJSONValue;
  LRootObj: TJSONObject;
  LStructArr: TJSONArray;
  LItemVal: TJSONValue;
begin
  LContent := TFile.ReadAllText(AFileName);
  LRootVal := TJSONObject.ParseJSONValue(LContent);
  if (LRootVal = nil) or not (LRootVal is TJSONObject) then
    raise Exception.Create('Invalid JSON file');

  LRootObj := TJSONObject(LRootVal);
  try
    Result.Name := LRootObj.GetValue<string>('name');
    Result.Override := TOverride.FromJSON(LRootObj.GetValue<TJSONObject>('override'));

    LStructArr := LRootObj.GetValue<TJSONArray>('structure');
    if LStructArr <> nil then
    begin
      SetLength(Result.Structure, LStructArr.Count);
      for var i := 0 to LStructArr.Count - 1 do
      begin
        LItemVal := LStructArr.Items[i];
        if LItemVal is TJSONObject then
          Result.Structure[i] := TStack.FromJSON(LItemVal as TJSONObject);
      end;
    end;
  finally
    LRootObj.Free;
  end;
end;

function ReadLayeredModel(const FileName: string):TLayeredModel;
var
  i: Integer;
  SL, Line: TStringList;
  H, rho, sigma: Single;
  Name: string;

  procedure Convert;
  begin
    Name  := Line[0];
    H     := StrToFloat(Line[1]);
    sigma := StrToFloat(Line[2]);
    rho   := StrToFloat(Line[3]);
  end;

begin
  if not FileExists(FileName) then
  begin
    Writeln('File ', FileName, ' not found');
    Exit;
  end;

  Result := TLayeredModel.Create;

  SL   := TStringList.Create;
  Line := TStringList.Create;
  Line.StrictDelimiter := True;
  Line.Delimiter := ';';

  try
    SL.LoadFromFile(FileName);

    Result.Size := SL.Count - 1;

    for I := 0 to SL.Count - 2 do
    begin
      Line.DelimitedText := SL[i];
      Convert;
      Result.InitLayer(I + 1, Name, H, sigma, rho);
    end;

    Line.DelimitedText := SL[SL.Count - 1];
    Convert;
    Result.InitSubstrate(Name, H, sigma, rho);
  finally
    FreeAndNil(SL);
    FreeAndNil(Line);
  end;
end;

function StructureToModel(Structure: TStructure):TLayeredModel;
var
  Stack: TStack;
  Layer: TLayer;
  i, Count, MaxCount: integer;
begin
  Result := TLayeredModel.Create;

  MaxCount := 0;
  for Stack  in Structure.Structure do
    MaxCount := MaxCount + Stack.N * Length(Stack.Layers);

  Result.Size := MaxCount - 1;

  Count := 1;
  for Stack  in Structure.Structure do
  begin
    for I := 1 to Stack.N do
    begin
      for Layer in Stack.Layers do
      begin
        if Layer.H > 0 then
          Result.InitLayer(Count, Layer.MaterialName, Layer.H, Layer.sigma, Layer.Density)
        else
          Result.InitSubstrate(Layer.MaterialName, Layer.H, Layer.sigma, Layer.Density);
        inc(Count);
      end;
    end;
  end;
end;

procedure GetOverrides(Structure: TStructure; var AParams: TCalcParams);
var
  P: TOverride;
begin
  P := Structure.Override;

  AParams.Mode   := cmTheta;
  AParams.P      := cmSP;
  AParams.Lambda := P.Lambda;
  AParams.StartT := P.BeginVal;
  AParams.EndT   := P.EndVal;
  AParams.K      := 1;
end;

function LoadModel(const FileName: string; var Params: TCalcParams): TLayeredModel;
var
  ext : string;
  Structure: TStructure;
begin
  ext := ExtractFileExt(FileName);
  if LowerCase(ext) = '.json' then
  begin
    Structure := TStructure.LoadFromFile(FileName);
    GetOverrides(Structure, Params);
    Result := StructureToModel(Structure);
  end
  else
    Result := ReadLayeredModel(FileName);
end;

end.

