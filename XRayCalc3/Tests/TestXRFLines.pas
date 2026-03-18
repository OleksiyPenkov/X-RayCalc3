unit TestXRFLines;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestXRFLines = class
  public
    [Test] procedure Test_GetLambda_KnownElements;
    [Test] procedure Test_GetLambda_CaseInsensitive;
    [Test] procedure Test_GetLambda_UnknownRaises;
    [Test] procedure Test_ExpandRange_Normal;
    [Test] procedure Test_ExpandRange_SingleElement;
    [Test] procedure Test_ExpandRange_Reversed;
    [Test] procedure Test_ExpandRange_InvalidEndpoint;
    [Test] procedure Test_ExpandRange_CrossKaLa;
    [Test] procedure Test_GetAllElements_Count;
    [Test] procedure Test_GetAllElements_Order;
  end;

  [TestFixture]
  TTestConfigLines = class
  private
    FTempDir: string;
    function WriteConfig(const LinesJSON: string): string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Test_LoadConfig_LegacyFormat;
    [Test] procedure Test_LoadConfig_StringElements;
    [Test] procedure Test_LoadConfig_RangeExpansion;
    [Test] procedure Test_LoadConfig_MixedFormat;
    [Test] procedure Test_LoadConfig_ObjectNoLambda;
    [Test] procedure Test_LoadConfig_BackwardCompatTargetsKey;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, Winapi.Windows,
  unit_xrf_lines, unit_universal_io, unit_universal_types;

procedure TTestXRFLines.Test_GetLambda_KnownElements;
begin
  Assert.AreEqual(67.6,   GetXRFLambda('B'),  0.01, 'B Ka');
  Assert.AreEqual(44.7,   GetXRFLambda('C'),  0.01, 'C Ka');
  Assert.AreEqual(7.126,  GetXRFLambda('Si'), 0.01, 'Si Ka');
  Assert.AreEqual(0.9131, GetXRFLambda('U'),  0.01, 'U La');
end;

procedure TTestXRFLines.Test_GetLambda_CaseInsensitive;
begin
  Assert.AreEqual(GetXRFLambda('Si'), GetXRFLambda('si'), 0.001);
  Assert.AreEqual(GetXRFLambda('Si'), GetXRFLambda('SI'), 0.001);
end;

procedure TTestXRFLines.Test_GetLambda_UnknownRaises;
begin
  Assert.WillRaise(
    procedure begin GetXRFLambda('Xx'); end,
    EArgumentException
  );
end;

procedure TTestXRFLines.Test_ExpandRange_Normal;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('B-N');
  Assert.AreEqual(3, Length(R));
  Assert.AreEqual('B', R[0]);
  Assert.AreEqual('C', R[1]);
  Assert.AreEqual('N', R[2]);
end;

procedure TTestXRFLines.Test_ExpandRange_SingleElement;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('C-C');
  Assert.AreEqual(1, Length(R));
  Assert.AreEqual('C', R[0]);
end;

procedure TTestXRFLines.Test_ExpandRange_Reversed;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('Si-B');
  Assert.AreEqual(10, Length(R));
  Assert.AreEqual('B', R[0]);
  Assert.AreEqual('Si', R[9]);
end;

procedure TTestXRFLines.Test_ExpandRange_InvalidEndpoint;
begin
  Assert.WillRaise(
    procedure begin ExpandElementRange('Xx-Si'); end,
    EArgumentException
  );
end;

procedure TTestXRFLines.Test_ExpandRange_CrossKaLa;
var
  R: TArray<string>;
begin
  R := ExpandElementRange('Cs-Ba');
  Assert.AreEqual(2, Length(R));
  Assert.AreEqual('Cs', R[0]);
  Assert.AreEqual('Ba', R[1]);
end;

procedure TTestXRFLines.Test_GetAllElements_Count;
begin
  Assert.AreEqual(90, Length(GetAllElements));
end;

procedure TTestXRFLines.Test_GetAllElements_Order;
var
  All: TArray<string>;
begin
  All := GetAllElements;
  Assert.AreEqual('Li', All[0]);
  Assert.AreEqual('U', All[89]);
end;

{ TTestConfigLines }

procedure TTestConfigLines.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'xrf_test_' + IntToStr(GetTickCount));
  TDirectory.CreateDirectory(FTempDir);
end;

procedure TTestConfigLines.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

function TTestConfigLines.WriteConfig(const LinesJSON: string): string;
var
  Config: string;
begin
  Result := TPath.Combine(FTempDir, 'test_config.json');
  Config :=
    '{' +
    '  "lines": ' + LinesJSON + ',' +
    '  "element_pool": ["Mo", "Si"],' +
    '  "structure": {' +
    '    "type": "bilayer", "layers_per_period": 2,' +
    '    "d": {"min": 20, "max": 80},' +
    '    "gamma": {"min": 0.2, "max": 0.6},' +
    '    "N": {"min": 20, "max": 200},' +
    '    "sigma": 3.5' +
    '  },' +
    '  "fitness": {' +
    '    "w_R": 1.0, "w_FWHM": 0.5, "R_min_threshold": 0.001,' +
    '    "polarization": "sp", "delta_theta": 0.1, "theta_min": 3.0' +
    '  },' +
    '  "optimizer": {' +
    '    "population": 50, "iterations": 10, "tolerance": 1e-6,' +
    '    "stagnation_limit": 5, "w1": 0.4, "w2": 0.5,' +
    '    "jamming_max": 3, "checkpoint_every": 100' +
    '  },' +
    '  "substrate": "SiO2",' +
    '  "henke_path": null,' +
    '  "output_dir": ".",' +
    '  "resume_from": null' +
    '}';
  TFile.WriteAllText(Result, Config);
end;

procedure TTestConfigLines.Test_LoadConfig_LegacyFormat;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig(
    '[{"element": "B", "lambda": 67.6, "weight": 1.0},' +
    ' {"element": "C", "lambda": 44.7, "weight": 2.0}]'));
  Assert.AreEqual(2, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual(67.6, Double(C.Lines[0].Lambda), 0.01);
  Assert.AreEqual(2.0, Double(C.Lines[1].Weight), 0.01);
end;

procedure TTestConfigLines.Test_LoadConfig_StringElements;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig('["B", "C", "Si"]'));
  Assert.AreEqual(3, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual(67.6, Double(C.Lines[0].Lambda), 0.01);
  Assert.AreEqual(1.0, Double(C.Lines[0].Weight), 0.01);
  Assert.AreEqual('Si', C.Lines[2].Name);
  Assert.AreEqual(7.126, Double(C.Lines[2].Lambda), 0.01);
end;

procedure TTestConfigLines.Test_LoadConfig_RangeExpansion;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig('["B-N"]'));
  Assert.AreEqual(3, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual('C', C.Lines[1].Name);
  Assert.AreEqual('N', C.Lines[2].Name);
end;

procedure TTestConfigLines.Test_LoadConfig_MixedFormat;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig(
    '["B-N", {"element": "Al", "weight": 2.0}, "Si"]'));
  Assert.AreEqual(5, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual('N', C.Lines[2].Name);
  Assert.AreEqual('Al', C.Lines[3].Name);
  Assert.AreEqual(2.0, Double(C.Lines[3].Weight), 0.01);
  Assert.AreEqual('Si', C.Lines[4].Name);
end;

procedure TTestConfigLines.Test_LoadConfig_ObjectNoLambda;
var
  C: TUniversalConfig;
begin
  C := TUniversalIO.LoadConfig(WriteConfig(
    '[{"element": "Al", "weight": 3.0}]'));
  Assert.AreEqual(1, Length(C.Lines));
  Assert.AreEqual('Al', C.Lines[0].Name);
  Assert.AreEqual(8.339, Double(C.Lines[0].Lambda), 0.01);
  Assert.AreEqual(3.0, Double(C.Lines[0].Weight), 0.01);
end;

procedure TTestConfigLines.Test_LoadConfig_BackwardCompatTargetsKey;
var
  C: TUniversalConfig;
  ConfigPath, ConfigStr: string;
begin
  ConfigPath := TPath.Combine(FTempDir, 'old_config.json');
  ConfigStr :=
    '{' +
    '  "targets": ["B", "C"],' +
    '  "element_pool": ["Mo", "Si"],' +
    '  "structure": {' +
    '    "type": "bilayer", "layers_per_period": 2,' +
    '    "d": {"min": 20, "max": 80},' +
    '    "gamma": {"min": 0.2, "max": 0.6},' +
    '    "N": {"min": 20, "max": 200},' +
    '    "sigma": 3.5' +
    '  },' +
    '  "fitness": {' +
    '    "w_R": 1.0, "w_FWHM": 0.5, "R_min_threshold": 0.001,' +
    '    "polarization": "sp", "delta_theta": 0.1, "theta_min": 3.0' +
    '  },' +
    '  "optimizer": {' +
    '    "population": 50, "iterations": 10, "tolerance": 1e-6,' +
    '    "stagnation_limit": 5, "w1": 0.4, "w2": 0.5,' +
    '    "jamming_max": 3, "checkpoint_every": 100' +
    '  },' +
    '  "substrate": "SiO2",' +
    '  "henke_path": null,' +
    '  "output_dir": ".",' +
    '  "resume_from": null' +
    '}';
  TFile.WriteAllText(ConfigPath, ConfigStr);
  C := TUniversalIO.LoadConfig(ConfigPath);
  Assert.AreEqual(2, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
end;

end.
