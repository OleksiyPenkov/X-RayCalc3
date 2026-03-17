unit unit_universal_templates;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils,
  unit_universal_types;

function LoadTemplates(const FileName: string): TTemplateLibrary;
function FindTemplate(const Lib: TTemplateLibrary;
  const Key: string): Integer;
function CollectTemplateMaterials(const Lib: TTemplateLibrary): TArray<string>;

implementation

function ParseThicknessType(JValue: TJSONValue;
  out FixedThickness: Single): TThicknessType;
begin
  if JValue is TJSONString then
  begin
    if SameText(JValue.Value, 'gamma') then
    begin
      Result := ttGamma;
      FixedThickness := 0;
    end
    else if SameText(JValue.Value, '1-gamma') then
    begin
      Result := ttOneMinusGamma;
      FixedThickness := 0;
    end
    else
      raise Exception.CreateFmt('Unknown thickness type: %s', [JValue.Value]);
  end
  else if JValue is TJSONNumber then
  begin
    Result := ttFixed;
    FixedThickness := JValue.GetValue<Double>;
  end
  else
    raise Exception.Create('Invalid thickness value in template');
end;

procedure ComputeReductions(var Pair: TTemplatePair);
var
  GammaIdx, OneMinusIdx, i: Integer;
  DistG, DistOM: Integer;
begin
  Pair.GammaReduction := 0;
  Pair.OneMinusGammaReduction := 0;

  // Find indices of gamma and 1-gamma layers
  GammaIdx := -1;
  OneMinusIdx := -1;
  for i := 0 to High(Pair.Layers) do
  begin
    if Pair.Layers[i].ThicknessType = ttGamma then
      GammaIdx := i
    else if Pair.Layers[i].ThicknessType = ttOneMinusGamma then
      OneMinusIdx := i;
  end;

  if (GammaIdx < 0) or (OneMinusIdx < 0) then
    raise Exception.CreateFmt(
      'Template "%s" must have exactly one "gamma" and one "1-gamma" layer',
      [Pair.Key]);

  // Assign each fixed layer to its nearest main layer
  for i := 0 to High(Pair.Layers) do
  begin
    if Pair.Layers[i].ThicknessType <> ttFixed then
      Continue;
    DistG := Abs(i - GammaIdx);
    DistOM := Abs(i - OneMinusIdx);
    if DistG <= DistOM then
      Pair.GammaReduction := Pair.GammaReduction + Pair.Layers[i].FixedThickness
    else
      Pair.OneMinusGammaReduction := Pair.OneMinusGammaReduction + Pair.Layers[i].FixedThickness;
  end;
end;

function LoadTemplates(const FileName: string): TTemplateLibrary;
var
  Content: string;
  JSON: TJSONObject;
  JPair: TJSONPair;
  JPairObj: TJSONObject;
  JLayers: TJSONArray;
  JLayer: TJSONObject;
  i, j, PairIdx: Integer;
begin
  SetLength(Result, 0);
  if (FileName = '') or not FileExists(FileName) then
    Exit;

  Content := TFile.ReadAllText(FileName);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  if JSON = nil then
    raise Exception.Create('Invalid template JSON file');
  try
    SetLength(Result, JSON.Count);
    PairIdx := 0;
    for i := 0 to JSON.Count - 1 do
    begin
      JPair := JSON.Pairs[i];
      Result[PairIdx].Key := JPair.JsonString.Value;

      JPairObj := JPair.JsonValue as TJSONObject;

      if JPairObj.FindValue('description') <> nil then
        Result[PairIdx].Description := JPairObj.GetValue<string>('description')
      else
        Result[PairIdx].Description := '';

      JLayers := JPairObj.GetValue<TJSONArray>('layers');
      SetLength(Result[PairIdx].Layers, JLayers.Count);
      for j := 0 to JLayers.Count - 1 do
      begin
        JLayer := JLayers.Items[j] as TJSONObject;
        Result[PairIdx].Layers[j].Material := JLayer.GetValue<string>('material');
        Result[PairIdx].Layers[j].ThicknessType :=
          ParseThicknessType(JLayer.GetValue('thickness'),
            Result[PairIdx].Layers[j].FixedThickness);
        Result[PairIdx].Layers[j].Sigma := JLayer.GetValue<Double>('sigma');
        Result[PairIdx].Layers[j].Density := JLayer.GetValue<Double>('density');
      end;

      ComputeReductions(Result[PairIdx]);
      Inc(PairIdx);
    end;
  finally
    JSON.Free;
  end;
end;

function FindTemplate(const Lib: TTemplateLibrary;
  const Key: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(Lib) do
    if SameText(Lib[i].Key, Key) then
      Exit(i);
  Result := -1;
end;

function CollectTemplateMaterials(
  const Lib: TTemplateLibrary): TArray<string>;
var
  i, j, k: Integer;
  Found: Boolean;
  Count: Integer;
begin
  Count := 0;
  SetLength(Result, 64);
  for i := 0 to High(Lib) do
    for j := 0 to High(Lib[i].Layers) do
    begin
      Found := False;
      for k := 0 to Count - 1 do
        if SameText(Result[k], Lib[i].Layers[j].Material) then
        begin
          Found := True;
          Break;
        end;
      if not Found then
      begin
        if Count >= Length(Result) then
          SetLength(Result, Length(Result) * 2);
        Result[Count] := Lib[i].Layers[j].Material;
        Inc(Count);
      end;
    end;
  SetLength(Result, Count);
end;

end.
