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
begin
  raise ENotImplemented.Create('LoadManifest not yet implemented');
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
