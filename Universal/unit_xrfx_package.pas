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

// Read side (XRFView)
procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
function  LoadManifest(const ManifestPath: string): TXRFXManifest;
function  LoadXRCStructure(const JsonPath: string): TXRFXStructure;
function  LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
function  LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;

implementation

// Stubs — implemented in subsequent tasks

procedure CreateXRFXPackage(
  const Config: TUniversalConfig;
  const BestGenome: TGenome;
  FoM: Double;
  const PerElement: TArray<TXRFXElementResult>;
  const ResultsDir, ConfigFilePath, OutputPath: string);
begin
  raise ENotImplemented.Create('CreateXRFXPackage not yet implemented');
end;

procedure ExtractXRFXPackage(const XRFXPath, TempDir: string);
begin
  raise ENotImplemented.Create('ExtractXRFXPackage not yet implemented');
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
begin
  raise ENotImplemented.Create('LoadXRCStructure not yet implemented');
end;

function LoadCurveFiles(const CurvesDir: string): TArray<TXRFXCurveData>;
begin
  raise ENotImplemented.Create('LoadCurveFiles not yet implemented');
end;

function LoadProgressLog(const LogPath: string): TArray<TProgressEntry>;
begin
  raise ENotImplemented.Create('LoadProgressLog not yet implemented');
end;

end.
