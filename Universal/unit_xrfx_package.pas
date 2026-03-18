unit unit_xrfx_package;

interface

uses
  System.SysUtils, System.Classes, System.Types, System.IOUtils,
  System.Zip, System.JSON, System.Generics.Collections,
  unit_universal_types;

const
  XRFX_MANIFEST_VERSION = 1;
  XRFX_EXT = '.xrfx';

type
  TXRFXStructureSummary = record
    StructureType: string;
    D, Gamma, Sigma: Double;
    N: Integer;
  end;

  TXRFXOptimizerInfo = record
    Population, Iterations, StagnationLimit: Integer;
  end;

  TXRFXElementResult = record
    Line: string;
    PeakR: Double;
    FWHM: Double;
  end;

  TXRFXManifest = record
    Version: Integer;
    Created: string;
    Generator: string;
    FoM: Double;
    TargetLines: TArray<string>;
    ElementPool: TArray<string>;
    Substrate: string;
    Structure: TXRFXStructureSummary;
    Optimizer: TXRFXOptimizerInfo;
    PerElement: TArray<TXRFXElementResult>;
    CurveFiles: TArray<string>;
  end;

  TXRFXLayer = record
    Material: string;
    Thickness: Double;
    Roughness: Double;
    Density: Double;
  end;

  TXRFXStructure = record
    Layers: TArray<TXRFXLayer>;
    Substrate: TXRFXLayer;
    StackN: Integer;
  end;

  TProgressEntry = record
    Iteration: Integer;
    FoM: Double;
    ElementR: TArray<Double>;
    Diversity: Double;
  end;

  TXRFXCurveData = record
    Element: string;
    Theta: TArray<Double>;
    Refl: TArray<Double>;
  end;

// Write side (xrccmd)
procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, ConfigFilePath, OutputPath: string);

// Read side (XRFCalc)
procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
function  LoadManifest(const ManifestPath: string): TXRFXManifest;
function  LoadXRCStructure(const JsonPath: string): TXRFXStructure;
function  LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
function  LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;

implementation

function GenerateManifestJSON(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const CurveFiles: TArray<string>): string;
var
  JSON, JStruct, JOpt, JFiles: TJSONObject;
  JTargets, JPool, JPerElem, JCurves: TJSONArray;
  JElem: TJSONObject;
  i: Integer;
begin
  JSON := TJSONObject.Create;
  try
    JSON.AddPair('version', TJSONNumber.Create(XRFX_MANIFEST_VERSION));
    JSON.AddPair('created', FormatDateTime('yyyy-mm-dd"T"hh:nn:ss', Now));
    JSON.AddPair('generator', 'xrccmd');
    JSON.AddPair('fom', TJSONNumber.Create(FoM));

    // target_lines
    JTargets := TJSONArray.Create;
    for i := 0 to High(Config.Lines) do
      JTargets.Add(Config.Lines[i].Name);
    JSON.AddPair('target_lines', JTargets);

    // element_pool
    JPool := TJSONArray.Create;
    for i := 0 to High(Config.ElementPool) do
      JPool.Add(Config.ElementPool[i]);
    JSON.AddPair('element_pool', JPool);

    JSON.AddPair('substrate', Config.Substrate);

    // structure_summary
    JStruct := TJSONObject.Create;
    JStruct.AddPair('type', Config.Structure.StructureType);
    JStruct.AddPair('d', TJSONNumber.Create(BestGenome.d));
    JStruct.AddPair('gamma', TJSONNumber.Create(BestGenome.Gamma));
    JStruct.AddPair('N', TJSONNumber.Create(NRound(BestGenome.N)));
    JStruct.AddPair('sigma', TJSONNumber.Create(BestGenome.Sigma));
    JSON.AddPair('structure_summary', JStruct);

    // optimizer
    JOpt := TJSONObject.Create;
    JOpt.AddPair('population', TJSONNumber.Create(Config.Optimizer.Population));
    JOpt.AddPair('iterations', TJSONNumber.Create(Config.Optimizer.Iterations));
    JOpt.AddPair('stagnation_limit', TJSONNumber.Create(Config.Optimizer.StagnationLimit));
    JSON.AddPair('optimizer', JOpt);

    // per_element
    JPerElem := TJSONArray.Create;
    for i := 0 to High(PerElement) do
    begin
      JElem := TJSONObject.Create;
      JElem.AddPair('line', PerElement[i].Line);
      JElem.AddPair('peak_R', TJSONNumber.Create(PerElement[i].PeakR));
      JElem.AddPair('fwhm', TJSONNumber.Create(PerElement[i].FWHM));
      JPerElem.Add(JElem);
    end;
    JSON.AddPair('per_element', JPerElem);

    // files
    JFiles := TJSONObject.Create;
    JFiles.AddPair('config', 'config.json');
    JFiles.AddPair('best_structure', 'best_structure.json');
    JFiles.AddPair('best_structure_xrc', 'best_structure_xrc.json');
    JFiles.AddPair('population', 'population.json');
    JFiles.AddPair('progress', 'progress.log');

    JCurves := TJSONArray.Create;
    for i := 0 to High(CurveFiles) do
      JCurves.Add(CurveFiles[i]);
    JFiles.AddPair('curves', JCurves);
    JSON.AddPair('files', JFiles);

    Result := JSON.Format(2);
  finally
    JSON.Free;
  end;
end;

procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, ConfigFilePath, OutputPath: string);
var
  ZipFile: TZipFile;
  Files: TStringDynArray;
  FilePath, RelPath, CurvesDir: string;
  CurveFilesList: TArray<string>;
  ManifestPath, ConfigDest: string;
  CurveNames: TStringDynArray;
  i: Integer;
begin
  // 1. Copy config JSON into results dir
  ConfigDest := TPath.Combine(ResultsDir, 'config.json');
  if TFile.Exists(ConfigFilePath) then
    TFile.Copy(ConfigFilePath, ConfigDest, True);

  // 2. Discover curve files for manifest
  CurvesDir := TPath.Combine(ResultsDir, 'best_curves');
  if TDirectory.Exists(CurvesDir) then
  begin
    CurveNames := TDirectory.GetFiles(CurvesDir, '*.dat');
    SetLength(CurveFilesList, Length(CurveNames));
    for i := 0 to High(CurveNames) do
      CurveFilesList[i] := 'best_curves/' + TPath.GetFileName(CurveNames[i]);
  end;

  // 3. Generate manifest.json
  ManifestPath := TPath.Combine(ResultsDir, 'manifest.json');
  TFile.WriteAllText(ManifestPath,
    GenerateManifestJSON(Config, BestGenome, FoM, PerElement, CurveFilesList));

  // 4. ZIP everything except checkpoint.json
  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmWrite);

    Files := TDirectory.GetFiles(ResultsDir, '*', TSearchOption.soAllDirectories);
    for FilePath in Files do
    begin
      if SameText(TPath.GetFileName(FilePath), 'checkpoint.json') then
        Continue;

      // Build relative path using forward slashes
      RelPath := FilePath.Substring(Length(IncludeTrailingPathDelimiter(ResultsDir)));
      RelPath := StringReplace(RelPath, '\', '/', [rfReplaceAll]);
      ZipFile.Add(FilePath, RelPath);
    end;

    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
begin
  if not TDirectory.Exists(TempDir) then
    TDirectory.CreateDirectory(TempDir);

  TZipFile.ExtractZipFile(XRFXPath, TempDir);
end;

function LoadManifest(const ManifestPath: string): TXRFXManifest;
var
  Content: string;
  JSON, JStruct, JOpt, JFiles: TJSONObject;
  JLines, JPool, JPerElem, JCurves: TJSONArray;
  JElem: TJSONObject;
  i: Integer;
begin
  Content := TFile.ReadAllText(ManifestPath);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    Result.Version := JSON.GetValue<Integer>('version');
    Result.Created := JSON.GetValue<string>('created', '');

    if JSON.FindValue('generator') <> nil then
      Result.Generator := JSON.GetValue<string>('generator');

    Result.FoM := JSON.GetValue<Double>('fom');
    Result.Substrate := JSON.GetValue<string>('substrate');

    // target_lines
    JLines := JSON.GetValue<TJSONArray>('target_lines');
    SetLength(Result.TargetLines, JLines.Count);
    for i := 0 to JLines.Count - 1 do
      Result.TargetLines[i] := JLines.Items[i].Value;

    // element_pool
    JPool := JSON.GetValue<TJSONArray>('element_pool');
    SetLength(Result.ElementPool, JPool.Count);
    for i := 0 to JPool.Count - 1 do
      Result.ElementPool[i] := JPool.Items[i].Value;

    // structure_summary
    JStruct := JSON.GetValue<TJSONObject>('structure_summary');
    Result.Structure.StructureType := JStruct.GetValue<string>('type');
    Result.Structure.D := JStruct.GetValue<Double>('d');
    Result.Structure.Gamma := JStruct.GetValue<Double>('gamma');
    Result.Structure.N := JStruct.GetValue<Integer>('N');
    Result.Structure.Sigma := JStruct.GetValue<Double>('sigma');

    // optimizer
    JOpt := JSON.GetValue<TJSONObject>('optimizer');
    Result.Optimizer.Population := JOpt.GetValue<Integer>('population');
    Result.Optimizer.Iterations := JOpt.GetValue<Integer>('iterations');
    Result.Optimizer.StagnationLimit := JOpt.GetValue<Integer>('stagnation_limit');

    // per_element
    JPerElem := JSON.GetValue<TJSONArray>('per_element');
    SetLength(Result.PerElement, JPerElem.Count);
    for i := 0 to JPerElem.Count - 1 do
    begin
      JElem := JPerElem.Items[i] as TJSONObject;
      Result.PerElement[i].Line := JElem.GetValue<string>('line');
      Result.PerElement[i].PeakR := JElem.GetValue<Double>('peak_R');
      Result.PerElement[i].FWHM := JElem.GetValue<Double>('fwhm');
    end;

    // files.curves
    if JSON.FindValue('files') <> nil then
    begin
      JFiles := JSON.GetValue<TJSONObject>('files');
      if JFiles.FindValue('curves') <> nil then
      begin
        JCurves := JFiles.GetValue<TJSONArray>('curves');
        SetLength(Result.CurveFiles, JCurves.Count);
        for i := 0 to JCurves.Count - 1 do
          Result.CurveFiles[i] := JCurves.Items[i].Value;
      end;
    end;
  finally
    JSON.Free;
  end;
end;

function LoadXRCStructure(const JsonPath: string): TXRFXStructure;
var
  Content: string;
  JSON, JSubs, JLayer: TJSONObject;
  JStacks, JLayers: TJSONArray;
  JStack: TJSONObject;
  i: Integer;
begin
  Content := TFile.ReadAllText(JsonPath);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    // Parse first stack (ML = multilayer)
    JStacks := JSON.GetValue<TJSONArray>('Stacks');
    JStack := JStacks.Items[0] as TJSONObject;
    Result.StackN := JStack.GetValue<Integer>('N');

    JLayers := JStack.GetValue<TJSONArray>('Layers');
    SetLength(Result.Layers, JLayers.Count);
    for i := 0 to JLayers.Count - 1 do
    begin
      JLayer := JLayers.Items[i] as TJSONObject;
      Result.Layers[i].Material := JLayer.GetValue<string>('M');
      Result.Layers[i].Thickness := JLayer.GetValue<Double>('H');
      Result.Layers[i].Roughness := JLayer.GetValue<Double>('s');
      Result.Layers[i].Density := JLayer.GetValue<Double>('r');
    end;

    // Substrate
    JSubs := JSON.GetValue<TJSONObject>('Subs');
    Result.Substrate.Material := JSubs.GetValue<string>('M');
    Result.Substrate.Roughness := JSubs.GetValue<Double>('s');
    Result.Substrate.Density := JSubs.GetValue<Double>('r');
    Result.Substrate.Thickness := 0;
  finally
    JSON.Free;
  end;
end;

function LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
var
  FileNames: TStringDynArray;
  i, j: Integer;
  Lines: TStringDynArray;
  Parts: TArray<string>;
  ThetaList: TList<Double>;
  ReflList: TList<Double>;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  if not TDirectory.Exists(CurvesDir) then
  begin
    SetLength(Result, 0);
    Exit;
  end;

  FileNames := TDirectory.GetFiles(CurvesDir, '*.dat');
  SetLength(Result, Length(FileNames));

  for i := 0 to High(FileNames) do
  begin
    Result[i].Element := TPath.GetFileNameWithoutExtension(FileNames[i]);
    Lines := TFile.ReadAllLines(FileNames[i]);

    ThetaList := TList<Double>.Create;
    ReflList := TList<Double>.Create;
    try
      for j := 0 to High(Lines) do
      begin
        if Lines[j].StartsWith('Theta') or (Trim(Lines[j]) = '') then
          Continue;
        Parts := Lines[j].Split([#9]);
        if Length(Parts) >= 2 then
        begin
          ThetaList.Add(StrToFloat(Trim(Parts[0]), FS));
          ReflList.Add(StrToFloat(Trim(Parts[1]), FS));
        end;
      end;
      Result[i].Theta := ThetaList.ToArray;
      Result[i].Refl := ReflList.ToArray;
    finally
      ThetaList.Free;
      ReflList.Free;
    end;
  end;
end;

function LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;
var
  AllLines: TStringDynArray;
  Line: string;
  Parts, HeaderParts: TArray<string>;
  i, j, NumElements, NumExpectedTokens: Integer;
  Entry: TProgressEntry;
  ResultList: TList<TProgressEntry>;
  FS: TFormatSettings;
begin
  FS := TFormatSettings.Create;
  FS.DecimalSeparator := '.';

  AllLines := TFile.ReadAllLines(LogPath);
  ResultList := TList<TProgressEntry>.Create;
  try
    // Step 1: Parse header to count R_ columns
    NumElements := 0;
    for i := 0 to High(AllLines) do
    begin
      Line := Trim(AllLines[i]);
      if Line.StartsWith('Iter') then
      begin
        HeaderParts := Line.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
        for j := 0 to High(HeaderParts) do
          if HeaderParts[j].StartsWith('R_') then
            Inc(NumElements);
        Break;
      end;
    end;

    // We need: Iter + FoM + NumElements R values + Div
    NumExpectedTokens := 2 + NumElements + 1;

    // Step 2: Parse data lines
    for i := 0 to High(AllLines) do
    begin
      Line := Trim(AllLines[i]);
      if (Line = '') or Line.StartsWith('Iter') then
        Continue;

      Parts := Line.Split([' ', #9], TStringSplitOptions.ExcludeEmpty);
      if Length(Parts) < NumExpectedTokens then
        Continue;

      Entry := Default(TProgressEntry);
      Entry.Iteration := StrToInt(Parts[0]);
      Entry.FoM := StrToFloat(Parts[1], FS);

      SetLength(Entry.ElementR, NumElements);
      for j := 0 to NumElements - 1 do
        Entry.ElementR[j] := StrToFloat(Parts[2 + j], FS);

      Entry.Diversity := StrToFloat(Parts[2 + NumElements], FS);

      ResultList.Add(Entry);
    end;

    Result := ResultList.ToArray;
  finally
    ResultList.Free;
  end;
end;

end.
