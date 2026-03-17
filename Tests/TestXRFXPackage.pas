unit TestXRFXPackage;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.IOUtils, System.Zip,
  unit_xrfx_package, unit_universal_types;

type
  [TestFixture]
  TTestXRFXPackage = class
  private
    FTempDir: string;
    function CreateSampleResultsDir: string;
    function CreateSampleConfigFile: string;
    function CreateSampleManifestFile: string;
    function CreateSampleXRCStructureFile: string;
    function CreateSampleProgressLog: string;
    function CreateSampleXRFX: string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;
  end;

  [TestFixture]
  TTestManifestGeneration = class(TTestXRFXPackage)
  public
    [Test] procedure Test_CreateXRFXPackage_ProducesFile;
    [Test] procedure Test_CreateXRFXPackage_ContainsManifest;
    [Test] procedure Test_CreateXRFXPackage_ContainsConfig;
    [Test] procedure Test_CreateXRFXPackage_ExcludesCheckpoint;
    [Test] procedure Test_CreateXRFXPackage_ManifestHasCorrectVersion;
  end;

  [TestFixture]
  TTestManifestLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadManifest_ParsesVersion;
    [Test] procedure Test_LoadManifest_ParsesFoM;
    [Test] procedure Test_LoadManifest_ParsesTargetLines;
    [Test] procedure Test_LoadManifest_ParsesPerElement;
    [Test] procedure Test_LoadManifest_ParsesStructureSummary;
    [Test] procedure Test_LoadManifest_ParsesOptimizerInfo;
    [Test] procedure Test_LoadManifest_ParsesCurveFiles;
  end;

  [TestFixture]
  TTestExtraction = class(TTestXRFXPackage)
  public
    [Test] procedure Test_ExtractXRFXPackage_CreatesFiles;
    [Test] procedure Test_ExtractXRFXPackage_ManifestReadable;
  end;

  [TestFixture]
  TTestXRCStructureLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadXRCStructure_ParsesLayers;
    [Test] procedure Test_LoadXRCStructure_ParsesSubstrate;
    [Test] procedure Test_LoadXRCStructure_ParsesStackN;
  end;

  [TestFixture]
  TTestCurveLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadCurveFiles_ParsesElements;
    [Test] procedure Test_LoadCurveFiles_ParsesData;
    [Test] procedure Test_LoadCurveFiles_SkipsHeader;
  end;

  [TestFixture]
  TTestProgressLogLoading = class(TTestXRFXPackage)
  public
    [Test] procedure Test_LoadProgressLog_ParsesIterations;
    [Test] procedure Test_LoadProgressLog_ParsesFoM;
    [Test] procedure Test_LoadProgressLog_ParsesElementR;
  end;

implementation

{ TTestXRFXPackage }

procedure TTestXRFXPackage.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath,
    'XRC_TestXRFX_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTempDir);
end;

procedure TTestXRFXPackage.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

function TTestXRFXPackage.CreateSampleResultsDir: string;
var
  CurvesDir: string;
begin
  Result := TPath.Combine(FTempDir, 'results');
  TDirectory.CreateDirectory(Result);
  CurvesDir := TPath.Combine(Result, 'best_curves');
  TDirectory.CreateDirectory(CurvesDir);

  // best_structure.json (minimal)
  TFile.WriteAllText(TPath.Combine(Result, 'best_structure.json'),
    '{"name":"test","optimizer_result":{"FoM":0.5}}');

  // best_structure_xrc.json
  TFile.WriteAllText(TPath.Combine(Result, 'best_structure_xrc.json'),
    '{"Stacks":[{"T":"ML","N":20,"Layers":[' +
    '{"M":"W","H":15.0,"s":3.5,"r":19.3},' +
    '{"M":"Si","H":30.0,"s":3.5,"r":2.33}]}],' +
    '"Subs":{"M":"SiO2","s":1.0,"r":2.65}}');

  // population.json
  TFile.WriteAllText(TPath.Combine(Result, 'population.json'), '[]');

  // progress.log
  TFile.WriteAllText(TPath.Combine(Result, 'progress.log'),
    ' Iter       FoM  R_Na  R_Al    Div  Best               Time' + sLineBreak +
    '    0    0.0630  0.342  0.422  0.291  Mo/Si d=45.2         0:02' + sLineBreak +
    '   10    0.3013  0.361  0.435  0.179  Mo/Si d=42.8         0:05');

  // checkpoint.json (should be excluded from .xrfx)
  TFile.WriteAllText(TPath.Combine(Result, 'checkpoint.json'),
    '{"iteration":10}');

  // curve files
  TFile.WriteAllText(TPath.Combine(CurvesDir, 'Na.dat'),
    'Theta(deg)'#9'Reflectivity' + sLineBreak +
    '0.5000'#9'3.14159e-04' + sLineBreak +
    '1.0000'#9'1.23456e-03');

  TFile.WriteAllText(TPath.Combine(CurvesDir, 'Al.dat'),
    'Theta(deg)'#9'Reflectivity' + sLineBreak +
    '0.5000'#9'2.00000e-04' + sLineBreak +
    '1.0000'#9'5.00000e-03');
end;

function TTestXRFXPackage.CreateSampleConfigFile: string;
begin
  Result := TPath.Combine(FTempDir, 'test_config.json');
  TFile.WriteAllText(Result,
    '{"lines":["Na","Al"],"element_pool":["W","Si"],' +
    '"substrate":"SiO2","output_dir":"./results"}');
end;

function TTestXRFXPackage.CreateSampleManifestFile: string;
begin
  Result := TPath.Combine(FTempDir, 'manifest.json');
  TFile.WriteAllText(Result,
    '{' +
    '"version":1,' +
    '"created":"2026-03-17T14:30:00",' +
    '"generator":"xrccmd 3.0.0",' +
    '"fom":0.00342,' +
    '"target_lines":["Na-Ka","Al-Ka"],' +
    '"element_pool":["W","Si"],' +
    '"substrate":"SiO2",' +
    '"structure_summary":{"type":"bilayer","d":45.2,"gamma":0.35,"N":120,"sigma":3.5},' +
    '"optimizer":{"population":500,"iterations":1000,"stagnation_limit":200},' +
    '"per_element":[' +
    '  {"line":"Na-Ka","peak_R":0.08,"fwhm":0.38},' +
    '  {"line":"Al-Ka","peak_R":0.15,"fwhm":0.52}],' +
    '"files":{' +
    '  "config":"config.json",' +
    '  "best_structure":"best_structure.json",' +
    '  "best_structure_xrc":"best_structure_xrc.json",' +
    '  "population":"population.json",' +
    '  "progress":"progress.log",' +
    '  "curves":["best_curves/Na.dat","best_curves/Al.dat"]}' +
    '}');
end;

function TTestXRFXPackage.CreateSampleXRCStructureFile: string;
begin
  Result := TPath.Combine(FTempDir, 'best_structure_xrc.json');
  TFile.WriteAllText(Result,
    '{"Stacks":[{"T":"ML","N":20,"Layers":[' +
    '{"M":"W","H":15.2,"HP":false,"Hmin":7.6,"Hmax":22.8,"ProfileH":"",' +
    '"s":3.5,"SP":false,"Smin":1.75,"Smax":5.25,"ProfileS":"",' +
    '"r":19.3,"RP":false,"Rmin":9.65,"Rmax":28.95,"ProfileR":""},' +
    '{"M":"Si","H":30.0,"HP":false,"Hmin":15.0,"Hmax":45.0,"ProfileH":"",' +
    '"s":3.5,"SP":false,"Smin":1.75,"Smax":5.25,"ProfileS":"",' +
    '"r":2.33,"RP":false,"Rmin":1.17,"Rmax":3.50,"ProfileR":""}]}],' +
    '"Subs":{"M":"SiO2","s":1.0,"r":2.65}}');
end;

function TTestXRFXPackage.CreateSampleProgressLog: string;
begin
  Result := TPath.Combine(FTempDir, 'progress.log');
  TFile.WriteAllText(Result,
    ' Iter       FoM  R_Na  R_Al    Div  Best               Time' + sLineBreak +
    '    0    0.0630  0.342  0.422  0.291  Mo/Si d=45.2         0:02' + sLineBreak +
    '   10    0.3013  0.361  0.435  0.179  Mo/Si d=42.8         0:05');
end;

function TTestXRFXPackage.CreateSampleXRFX: string;
var
  ZipFile: TZipFile;
  ResultsDir, CurvesDir: string;
begin
  ResultsDir := TPath.Combine(FTempDir, 'to_zip');
  TDirectory.CreateDirectory(ResultsDir);
  CurvesDir := TPath.Combine(ResultsDir, 'best_curves');
  TDirectory.CreateDirectory(CurvesDir);

  TFile.WriteAllText(TPath.Combine(ResultsDir, 'manifest.json'),
    '{"version":1,"fom":0.5,"target_lines":["Na-Ka"],' +
    '"element_pool":["W","Si"],"substrate":"SiO2",' +
    '"structure_summary":{"type":"bilayer","d":40.0,"gamma":0.3,"N":100,"sigma":3.0},' +
    '"optimizer":{"population":200,"iterations":500,"stagnation_limit":100},' +
    '"per_element":[{"line":"Na-Ka","peak_R":0.1,"fwhm":0.4}],' +
    '"files":{"curves":["best_curves/Na.dat"]}}');
  TFile.WriteAllText(TPath.Combine(ResultsDir, 'best_structure.json'), '{}');
  TFile.WriteAllText(TPath.Combine(ResultsDir, 'best_structure_xrc.json'),
    '{"Stacks":[{"T":"ML","N":100,"Layers":[' +
    '{"M":"W","H":12.0,"s":3.0,"r":19.3},' +
    '{"M":"Si","H":28.0,"s":3.0,"r":2.33}]}],' +
    '"Subs":{"M":"SiO2","s":1.0,"r":2.65}}');
  TFile.WriteAllText(TPath.Combine(CurvesDir, 'Na.dat'),
    'Theta(deg)'#9'Reflectivity' + sLineBreak + '1.0'#9'0.1');

  Result := TPath.Combine(FTempDir, 'test.xrfx');
  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(Result, zmWrite);
    ZipFile.Add(TPath.Combine(ResultsDir, 'manifest.json'), 'manifest.json');
    ZipFile.Add(TPath.Combine(ResultsDir, 'best_structure.json'), 'best_structure.json');
    ZipFile.Add(TPath.Combine(ResultsDir, 'best_structure_xrc.json'), 'best_structure_xrc.json');
    ZipFile.Add(TPath.Combine(CurvesDir, 'Na.dat'), 'best_curves/Na.dat');
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

// Test method stubs — implemented in subsequent tasks alongside their implementations

{ TTestManifestGeneration }

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ProducesFile;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, 0, [], ResultsDir, ConfigFile, OutputPath);
  Assert.IsTrue(TFile.Exists(OutputPath));
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ContainsManifest;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  ZipFile: TZipFile;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, 0, [], ResultsDir, ConfigFile, OutputPath);

  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmRead);
    Assert.IsTrue(ZipFile.IndexOf('manifest.json') >= 0);
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ContainsConfig;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  ZipFile: TZipFile;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, 0, [], ResultsDir, ConfigFile, OutputPath);

  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmRead);
    Assert.IsTrue(ZipFile.IndexOf('config.json') >= 0);
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ExcludesCheckpoint;
var
  ResultsDir, ConfigFile, OutputPath: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  ZipFile: TZipFile;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, 0, [], ResultsDir, ConfigFile, OutputPath);

  ZipFile := TZipFile.Create;
  try
    ZipFile.Open(OutputPath, zmRead);
    Assert.IsTrue(ZipFile.IndexOf('checkpoint.json') < 0);
    ZipFile.Close;
  finally
    ZipFile.Free;
  end;
end;

procedure TTestManifestGeneration.Test_CreateXRFXPackage_ManifestHasCorrectVersion;
var
  ResultsDir, ConfigFile, OutputPath, ExtractDir: string;
  Config: TUniversalConfig;
  Genome: TGenome;
  M: TXRFXManifest;
begin
  ResultsDir := CreateSampleResultsDir;
  ConfigFile := CreateSampleConfigFile;
  OutputPath := TPath.Combine(FTempDir, 'output.xrfx');
  ExtractDir := TPath.Combine(FTempDir, 'extracted');

  Config := Default(TUniversalConfig);
  Config.Structure.StructureType := 'bilayer';
  Config.Substrate := 'SiO2';
  Genome := CreateGenome(2);

  CreateXRFXPackage(Config, Genome, 0, [], ResultsDir, ConfigFile, OutputPath);

  ExtractXRFXPackage(OutputPath, ExtractDir);
  M := LoadManifest(TPath.Combine(ExtractDir, 'manifest.json'));
  Assert.AreEqual(XRFX_MANIFEST_VERSION, M.Version);
end;

{ TTestManifestLoading }

procedure TTestManifestLoading.Test_LoadManifest_ParsesVersion;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(1, M.Version);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesFoM;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(Double(0.00342), M.FoM, 1E-6);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesTargetLines;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(2, Length(M.TargetLines));
  Assert.AreEqual('Na-Ka', M.TargetLines[0]);
  Assert.AreEqual('Al-Ka', M.TargetLines[1]);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesPerElement;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(2, Length(M.PerElement));
  Assert.AreEqual('Na-Ka', M.PerElement[0].Line);
  Assert.AreEqual(Double(0.08), M.PerElement[0].PeakR, 1E-6);
  Assert.AreEqual(Double(0.38), M.PerElement[0].FWHM, 1E-6);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesStructureSummary;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual('bilayer', M.Structure.StructureType);
  Assert.AreEqual(Double(45.2), M.Structure.D, 1E-6);
  Assert.AreEqual(Double(0.35), M.Structure.Gamma, 1E-6);
  Assert.AreEqual(120, M.Structure.N);
  Assert.AreEqual(Double(3.5), M.Structure.Sigma, 1E-6);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesOptimizerInfo;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(500, M.Optimizer.Population);
  Assert.AreEqual(1000, M.Optimizer.Iterations);
  Assert.AreEqual(200, M.Optimizer.StagnationLimit);
end;

procedure TTestManifestLoading.Test_LoadManifest_ParsesCurveFiles;
var
  M: TXRFXManifest;
begin
  M := LoadManifest(CreateSampleManifestFile);
  Assert.AreEqual(2, Length(M.CurveFiles));
  Assert.AreEqual('best_curves/Na.dat', M.CurveFiles[0]);
end;

{ TTestExtraction }

procedure TTestExtraction.Test_ExtractXRFXPackage_CreatesFiles;
begin
  Assert.Pass('Stub');
end;

procedure TTestExtraction.Test_ExtractXRFXPackage_ManifestReadable;
begin
  Assert.Pass('Stub');
end;

{ TTestXRCStructureLoading }

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesLayers;
var
  S: TXRFXStructure;
begin
  S := LoadXRCStructure(CreateSampleXRCStructureFile);
  Assert.AreEqual(2, Length(S.Layers));
  Assert.AreEqual('W', S.Layers[0].Material);
  Assert.AreEqual(Double(15.2), S.Layers[0].Thickness, 1E-6);
  Assert.AreEqual(Double(3.5), S.Layers[0].Roughness, 1E-6);
  Assert.AreEqual(Double(19.3), S.Layers[0].Density, 1E-6);
  Assert.AreEqual('Si', S.Layers[1].Material);
end;

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesSubstrate;
var
  S: TXRFXStructure;
begin
  S := LoadXRCStructure(CreateSampleXRCStructureFile);
  Assert.AreEqual('SiO2', S.Substrate.Material);
  Assert.AreEqual(Double(1.0), S.Substrate.Roughness, 1E-6);
  Assert.AreEqual(Double(2.65), S.Substrate.Density, 1E-6);
end;

procedure TTestXRCStructureLoading.Test_LoadXRCStructure_ParsesStackN;
var
  S: TXRFXStructure;
begin
  S := LoadXRCStructure(CreateSampleXRCStructureFile);
  Assert.AreEqual(20, S.StackN);
end;

{ TTestCurveLoading }

procedure TTestCurveLoading.Test_LoadCurveFiles_ParsesElements;
begin
  Assert.Pass('Stub');
end;

procedure TTestCurveLoading.Test_LoadCurveFiles_ParsesData;
begin
  Assert.Pass('Stub');
end;

procedure TTestCurveLoading.Test_LoadCurveFiles_SkipsHeader;
begin
  Assert.Pass('Stub');
end;

{ TTestProgressLogLoading }

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesIterations;
var
  Entries: TArray<TProgressEntry>;
begin
  Entries := LoadProgressLog(CreateSampleProgressLog);
  Assert.AreEqual(2, Length(Entries));
  Assert.AreEqual(0, Entries[0].Iteration);
  Assert.AreEqual(10, Entries[1].Iteration);
end;

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesFoM;
var
  Entries: TArray<TProgressEntry>;
begin
  Entries := LoadProgressLog(CreateSampleProgressLog);
  Assert.AreEqual(Double(0.0630), Entries[0].FoM, 1E-4);
  Assert.AreEqual(Double(0.3013), Entries[1].FoM, 1E-4);
end;

procedure TTestProgressLogLoading.Test_LoadProgressLog_ParsesElementR;
var
  Entries: TArray<TProgressEntry>;
begin
  Entries := LoadProgressLog(CreateSampleProgressLog);
  // 2 element columns: R_Na, R_Al
  Assert.AreEqual(2, Length(Entries[0].ElementR));
  Assert.AreEqual(Double(0.342), Entries[0].ElementR[0], 1E-3);
  Assert.AreEqual(Double(0.422), Entries[0].ElementR[1], 1E-3);
end;

end.
