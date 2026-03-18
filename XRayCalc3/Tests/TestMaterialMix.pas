unit TestMaterialMix;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Math,
  math_complex, unit_materials_mix;

type
  [TestFixture]
  TTestMaterialMix = class
  private
    FMixer: TMaterialMixer;
    FHenkePath: string;
  public
    [Setup]
    procedure Setup;
    [TearDown]
    procedure TearDown;

    [Test]
    procedure TestPureElementMatchesHenke;

    [Test]
    procedure TestEqualMixAveragesDensity;

    [Test]
    procedure TestEpsilonRealPartLessThanOne;

    [Test]
    procedure TestEpsilonImagPartPositive;

    [Test]
    procedure TestSubstrateEpsilon;

    [Test]
    procedure TestDensityFactorScaling;
  end;

implementation

uses
  cmd_math_globals;

const
  ClassicalElectronRadius = 0.54014E-5;

procedure TTestMaterialMix.Setup;
var
  Elements: array of string;
  Lambdas: array of Single;
begin
  FMixer := TMaterialMixer.Create;
  SetLength(Elements, 3);
  Elements[0] := 'W';
  Elements[1] := 'Si';
  Elements[2] := 'C';

  SetLength(Lambdas, 2);
  Lambdas[0] := 44.7;  // C Ka
  Lambdas[1] := 23.6;  // O Ka

  FHenkePath := 'd:\SoftwareStorage\X-RayCalc3\Henke';
  FMixer.Initialize(Elements, Lambdas, 'Si', FHenkePath);
end;

procedure TTestMaterialMix.TearDown;
begin
  FMixer.Free;
end;

procedure TTestMaterialMix.TestPureElementMatchesHenke;
var
  Eps: TComplex;
  Dens: Single;
  Fractions: array[0..2] of Single;
  f: TComplex;
  Na, Nro, c: Single;
  SavedDir: string;
begin
  Fractions[0] := 1.0; Fractions[1] := 0.0; Fractions[2] := 0.0;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps, Dens);

  // ReadHenke uses .\Henke\ relative to CWD
  SavedDir := GetCurrentDir;
  try
    SetCurrentDir(ExtractFilePath(ExcludeTrailingPathDelimiter(FHenkePath)));
    ReadHenke('W', 0, 44.7, f, Na, Nro);
  finally
    SetCurrentDir(SavedDir);
  end;
  c := ClassicalElectronRadius * Nro / Na * Sqr(44.7);

  Assert.AreEqual(Double(1 - f.re * c), Double(Eps.re), 1e-4, 'Epsilon real mismatch');
  Assert.AreEqual(Double(f.im * c), Double(Eps.im), 1e-4, 'Epsilon imag mismatch');
end;

procedure TTestMaterialMix.TestEqualMixAveragesDensity;
var
  EpsPure1, EpsPure2, EpsMix: TComplex;
  Dens1, Dens2, DensMix: Single;
  F1, F2, FMix: array[0..2] of Single;
begin
  F1[0] := 1.0; F1[1] := 0.0; F1[2] := 0.0;
  F2[0] := 0.0; F2[1] := 1.0; F2[2] := 0.0;
  FMix[0] := 0.5; FMix[1] := 0.5; FMix[2] := 0.0;

  FMixer.CalcMixedEpsilon(F1, 1.0, 0, EpsPure1, Dens1);
  FMixer.CalcMixedEpsilon(F2, 1.0, 0, EpsPure2, Dens2);
  FMixer.CalcMixedEpsilon(FMix, 1.0, 0, EpsMix, DensMix);

  Assert.AreEqual(Double((Dens1 + Dens2) / 2), Double(DensMix), 0.01,
    'Mix density should be average of pure densities');
end;

procedure TTestMaterialMix.TestEpsilonRealPartLessThanOne;
var
  Eps: TComplex;
  Dens: Single;
  Fractions: array[0..2] of Single;
begin
  Fractions[0] := 0.5; Fractions[1] := 0.3; Fractions[2] := 0.2;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps, Dens);
  Assert.IsTrue(Eps.re < 1.0, 'Epsilon real should be < 1 in XUV');
end;

procedure TTestMaterialMix.TestEpsilonImagPartPositive;
var
  Eps: TComplex;
  Dens: Single;
  Fractions: array[0..2] of Single;
begin
  Fractions[0] := 0.5; Fractions[1] := 0.3; Fractions[2] := 0.2;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps, Dens);
  Assert.IsTrue(Eps.im > 0, 'Epsilon imag (absorption) should be positive');
end;

procedure TTestMaterialMix.TestSubstrateEpsilon;
var
  Eps: TComplex;
begin
  FMixer.CalcSubstrateEpsilon(0, Eps);
  Assert.IsTrue(Eps.re < 1.0, 'Substrate eps.re should be < 1');
  Assert.IsTrue(Eps.im > 0, 'Substrate eps.im should be > 0');
end;

procedure TTestMaterialMix.TestDensityFactorScaling;
var
  Eps1, Eps05: TComplex;
  Dens1, Dens05: Single;
  Fractions: array[0..2] of Single;
begin
  Fractions[0] := 1.0; Fractions[1] := 0.0; Fractions[2] := 0.0;
  FMixer.CalcMixedEpsilon(Fractions, 1.0, 0, Eps1, Dens1);
  FMixer.CalcMixedEpsilon(Fractions, 0.5, 0, Eps05, Dens05);
  Assert.AreEqual(Double(Dens1 * 0.5), Double(Dens05), 0.01,
    'Half density factor -> half density');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMaterialMix);

end.
