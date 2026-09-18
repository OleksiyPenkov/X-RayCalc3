unit TestConfig;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestConfigOptions = class
  private
    FIniPath: string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Test_DefaultValues_Integer;
    [Test] procedure Test_DefaultValues_Boolean;
    [Test] procedure Test_DefaultValues_String;
    [Test] procedure Test_WriteRead_Integer;
    [Test] procedure Test_WriteRead_Boolean;
    [Test] procedure Test_WriteRead_String;
  end;

  [TestFixture]
  TTestRecentEntryStale = class
  public
    [Test] procedure Test_ExistingFile_NotStale;
    [Test] procedure Test_DeletedFile_IsStale;
    [Test] procedure Test_UNCPath_NeverStale;
    [Test] procedure Test_RelativePath_NeverStale;
  end;

implementation

uses
  unit_Config, unit_RecentProjects,
  IniFiles, System.SysUtils, System.IOUtils;

procedure TTestConfigOptions.Setup;
begin
  FIniPath := TPath.GetTempFileName;
end;

procedure TTestConfigOptions.TearDown;
begin
  if TFile.Exists(FIniPath) then
    TFile.Delete(FIniPath);
end;

procedure TTestConfigOptions.Test_DefaultValues_Integer;
var
  Ini: TIniFile;
  Opts: TCalcOptions;
begin
  // Empty INI -> should return DefaultValue attributes
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TCalcOptions.Create(Ini);
    try
      Assert.AreEqual(0, Opts.NumberOfThreads, 'Default NumberOfThreads = 0');
      Assert.AreEqual(20, Opts.BenchmarkRuns, 'Default BenchmarkRuns = 20');
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TTestConfigOptions.Test_DefaultValues_Boolean;
var
  Ini: TIniFile;
  Opts: TOtherOptions;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TOtherOptions.Create(Ini);
    try
      Assert.IsFalse(Opts.CheckForUpdates, 'Default CheckForUpdates = False');
      Assert.IsTrue(Opts.AutoCalc, 'Default AutoCalc = True');
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TTestConfigOptions.Test_DefaultValues_String;
var
  Ini: TIniFile;
  Opts: TPathOptions;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TPathOptions.Create(Ini);
    try
      Assert.AreEqual('Henke', Opts.HenkeDir, 'Default HenkeDir = Henke');
      Assert.AreEqual('Output', Opts.OutputDir, 'Default OutputDir = Output');
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TTestConfigOptions.Test_WriteRead_Integer;
var
  Ini: TIniFile;
  Opts: TCalcOptions;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TCalcOptions.Create(Ini);
    try
      Opts.NumberOfThreads := 8;
      Opts.BenchmarkRuns := 50;
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;

  // Re-open and read back
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TCalcOptions.Create(Ini);
    try
      Assert.AreEqual(8, Opts.NumberOfThreads);
      Assert.AreEqual(50, Opts.BenchmarkRuns);
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TTestConfigOptions.Test_WriteRead_Boolean;
var
  Ini: TIniFile;
  Opts: TOtherOptions;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TOtherOptions.Create(Ini);
    try
      Opts.CheckForUpdates := True;
      Opts.AutoCalc := False;
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;

  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TOtherOptions.Create(Ini);
    try
      Assert.IsTrue(Opts.CheckForUpdates);
      Assert.IsFalse(Opts.AutoCalc);
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;
end;

procedure TTestConfigOptions.Test_WriteRead_String;
var
  Ini: TIniFile;
  Opts: TPathOptions;
begin
  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TPathOptions.Create(Ini);
    try
      Opts.HenkeDir := 'MyCustomHenke';
      Opts.OutputDir := 'C:\Results';
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;

  Ini := TIniFile.Create(FIniPath);
  try
    Opts := TPathOptions.Create(Ini);
    try
      Assert.AreEqual('MyCustomHenke', Opts.HenkeDir);
      Assert.AreEqual('C:\Results', Opts.OutputDir);
    finally
      Opts.Free;
    end;
  finally
    Ini.Free;
  end;
end;

{ TTestRecentEntryStale }

procedure TTestRecentEntryStale.Test_ExistingFile_NotStale;
var
  FileName: string;
begin
  FileName := TPath.GetTempFileName;   // created on the local temp drive
  try
    Assert.IsFalse(IsRecentEntryStale(FileName),
      'A file that is there must not be pruned');
  finally
    TFile.Delete(FileName);
  end;
end;

procedure TTestRecentEntryStale.Test_DeletedFile_IsStale;
var
  FileName: string;
begin
  FileName := TPath.GetTempFileName;
  TFile.Delete(FileName);
  Assert.IsTrue(IsRecentEntryStale(FileName),
    'A deleted file on a fixed drive must be pruned');
end;

procedure TTestRecentEntryStale.Test_UNCPath_NeverStale;
begin
  // the share may simply be offline - never drop the entry over that
  Assert.IsFalse(IsRecentEntryStale('\\no-such-host\share\project.xrcx'));
end;

procedure TTestRecentEntryStale.Test_RelativePath_NeverStale;
begin
  Assert.IsFalse(IsRecentEntryStale('project.xrcx'));
end;

end.
