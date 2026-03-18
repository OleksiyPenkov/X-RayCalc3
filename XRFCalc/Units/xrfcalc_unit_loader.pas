unit xrfcalc_unit_loader;

interface

uses
  System.SysUtils, System.IOUtils, System.Classes, System.Types,
  System.Generics.Collections,
  unit_xrfx_package;

type
  TLoadedResult = record
    FileName: string;
    TempDir: string;
    Manifest: TXRFXManifest;
    Structure: TXRFXStructure;
    Curves: TArray<TXRFXCurveData>;
    Progress: TArray<TProgressEntry>;
  end;

  TXRFCalcLoader = class
  private
    FResults: TList<TLoadedResult>;
    FBaseTempDir: string;
    function  GetManifest: TXRFXManifest;
    procedure CleanupTemp(const TempDir: string);
    procedure CleanupStale;
  public
    constructor Create;
    destructor Destroy; override;
    procedure LoadFile(const FileName: string);
    procedure LoadMultiple(const FileNames: TArray<string>);
    procedure Clear;
    function  ExtractFile(const ArchiveName, DestPath: string): Boolean;
    function  IsLoaded: Boolean;
    function  ResultCount: Integer;
    property  Manifest: TXRFXManifest read GetManifest;
    function  GetResult(Index: Integer): TLoadedResult;
  end;

implementation

constructor TXRFCalcLoader.Create;
begin
  inherited;
  FResults := TList<TLoadedResult>.Create;
  FBaseTempDir := TPath.Combine(TPath.GetTempPath, 'XRFCalc');
  if not TDirectory.Exists(FBaseTempDir) then
    TDirectory.CreateDirectory(FBaseTempDir);
  CleanupStale;
end;

destructor TXRFCalcLoader.Destroy;
var
  R: TLoadedResult;
begin
  for R in FResults do
    CleanupTemp(R.TempDir);
  FreeAndNil(FResults);
  inherited;
end;

procedure TXRFCalcLoader.CleanupTemp(const TempDir: string);
begin
  if TDirectory.Exists(TempDir) then
    TDirectory.Delete(TempDir, True);
end;

procedure TXRFCalcLoader.CleanupStale;
var
  Dirs: TStringDynArray;
  Dir: string;
begin
  if not TDirectory.Exists(FBaseTempDir) then Exit;
  Dirs := TDirectory.GetDirectories(FBaseTempDir);
  for Dir in Dirs do
  begin
    if TDirectory.GetCreationTime(Dir) < Now - 1 then
      TDirectory.Delete(Dir, True);
  end;
end;

procedure TXRFCalcLoader.Clear;
var
  R: TLoadedResult;
begin
  for R in FResults do
    CleanupTemp(R.TempDir);
  FResults.Clear;
end;

procedure TXRFCalcLoader.LoadFile(const FileName: string);
var
  R: TLoadedResult;
  CurvesDir, XRCPath, ProgressPath: string;
begin
  Clear;

  R := Default(TLoadedResult);
  R.FileName := FileName;
  R.TempDir := TPath.Combine(FBaseTempDir, TGUID.NewGuid.ToString);

  ExtractXRFXPackage(FileName, R.TempDir);
  R.Manifest := LoadManifest(TPath.Combine(R.TempDir, 'manifest.json'));

  XRCPath := TPath.Combine(R.TempDir, 'best_structure_xrc.json');
  if TFile.Exists(XRCPath) then
    R.Structure := LoadXRCStructure(XRCPath);

  CurvesDir := TPath.Combine(R.TempDir, 'best_curves');
  R.Curves := LoadCurveFiles(CurvesDir);

  ProgressPath := TPath.Combine(R.TempDir, 'progress.log');
  if TFile.Exists(ProgressPath) then
    R.Progress := LoadProgressLog(ProgressPath);

  FResults.Add(R);
end;

procedure TXRFCalcLoader.LoadMultiple(const FileNames: TArray<string>);
var
  FN: string;
  R: TLoadedResult;
  XRCPath, CurvesDir, ProgressPath: string;
begin
  Clear;
  for FN in FileNames do
  begin
    R := Default(TLoadedResult);
    R.FileName := FN;
    R.TempDir := TPath.Combine(FBaseTempDir, TGUID.NewGuid.ToString);
    ExtractXRFXPackage(FN, R.TempDir);
    R.Manifest := LoadManifest(TPath.Combine(R.TempDir, 'manifest.json'));

    XRCPath := TPath.Combine(R.TempDir, 'best_structure_xrc.json');
    if TFile.Exists(XRCPath) then
      R.Structure := LoadXRCStructure(XRCPath);

    CurvesDir := TPath.Combine(R.TempDir, 'best_curves');
    R.Curves := LoadCurveFiles(CurvesDir);

    ProgressPath := TPath.Combine(R.TempDir, 'progress.log');
    if TFile.Exists(ProgressPath) then
      R.Progress := LoadProgressLog(ProgressPath);

    FResults.Add(R);
  end;
end;

function TXRFCalcLoader.ExtractFile(const ArchiveName, DestPath: string): Boolean;
var
  SrcPath: string;
begin
  Result := False;
  if not IsLoaded then Exit;
  SrcPath := TPath.Combine(FResults[0].TempDir, ArchiveName);
  if TFile.Exists(SrcPath) then
  begin
    TFile.Copy(SrcPath, DestPath, True);
    Result := True;
  end;
end;

function TXRFCalcLoader.IsLoaded: Boolean;
begin
  Result := FResults.Count > 0;
end;

function TXRFCalcLoader.ResultCount: Integer;
begin
  Result := FResults.Count;
end;

function TXRFCalcLoader.GetManifest: TXRFXManifest;
begin
  if FResults.Count > 0 then
    Result := FResults[0].Manifest
  else
    Result := Default(TXRFXManifest);
end;

function TXRFCalcLoader.GetResult(Index: Integer): TLoadedResult;
begin
  Result := FResults[Index];
end;

end.
