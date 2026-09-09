unit TestMCPMaterials;

{ unit_MCPMaterials: formula parsing and optical constants.

  The formula tests are pure and always run. The Henke tests need the GUI's
  real table directory; when it is not installed they pass with a note rather
  than fail, exactly as the clipboard test in TestSeriesIO does. They never
  assign TConfig.SystemDir - the MCP server must not rewrite xrc3.ini and
  neither may its tests. }

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestMCPMaterials = class
  private
    function HenkeAvailable(const Material: string): Boolean;
  public
    { ParseFormula }
    [Test] procedure ParseFormula_B4C;
    [Test] procedure ParseFormula_SiO2;
    [Test] procedure ParseFormula_FractionalCounts;
    [Test] procedure ParseFormula_Mo5B4C;
    [Test] procedure ParseFormula_SiIMD_IsNotAFormula;
    [Test] procedure ParseFormula_Empty_IsNotAFormula;
    [Test] procedure ParseFormula_TrailingDot_IsNotAFormula;
    [Test] procedure ParseFormula_AllCapsElementName;

    { Henke lookups }
    [Test] procedure ResolveHenkeName_IsCaseInsensitive;
    [Test] procedure HenkeExists_UnknownMaterial_False;
    [Test] procedure OpticalConstants_Si_CuKAlpha;
    [Test] procedure OpticalConstants_UnknownMaterial_False;
  end;

implementation

uses
  System.SysUtils, System.IOUtils,
  unit_MCPMaterials;

const
  CU_K_ALPHA = 1.5406;   // Angstrom

function TTestMCPMaterials.HenkeAvailable(const Material: string): Boolean;
begin
  Result := TFile.Exists(HenkeDir + Material + '.bin');
end;

{ --- ParseFormula --- }

procedure TTestMCPMaterials.ParseFormula_B4C;
var
  Parts: TArray<TFormulaPart>;
begin
  Assert.IsTrue(ParseFormula('B4C', Parts), 'B4C must parse');
  Assert.AreEqual(2, Length(Parts), 'B4C has two elements');
  Assert.AreEqual('B', Parts[0].Symbol);
  Assert.AreEqual(4.0, Parts[0].Count, 1E-9);
  Assert.AreEqual('C', Parts[1].Symbol);
  Assert.AreEqual(1.0, Parts[1].Count, 1E-9, 'an omitted count is 1');
end;

procedure TTestMCPMaterials.ParseFormula_SiO2;
var
  Parts: TArray<TFormulaPart>;
begin
  Assert.IsTrue(ParseFormula('SiO2', Parts), 'SiO2 must parse');
  Assert.AreEqual(2, Length(Parts));
  Assert.AreEqual('Si', Parts[0].Symbol, False, 'a two-letter symbol is one token');
  Assert.AreEqual(1.0, Parts[0].Count, 1E-9);
  Assert.AreEqual('O', Parts[1].Symbol);
  Assert.AreEqual(2.0, Parts[1].Count, 1E-9);
end;

procedure TTestMCPMaterials.ParseFormula_FractionalCounts;
var
  Parts: TArray<TFormulaPart>;
begin
  Assert.IsTrue(ParseFormula('W0.7Si0.3', Parts), 'fractional counts must parse');
  Assert.AreEqual(2, Length(Parts));
  Assert.AreEqual('W', Parts[0].Symbol);
  Assert.AreEqual(0.7, Parts[0].Count, 1E-9);
  Assert.AreEqual('Si', Parts[1].Symbol);
  Assert.AreEqual(0.3, Parts[1].Count, 1E-9);
end;

procedure TTestMCPMaterials.ParseFormula_Mo5B4C;
var
  Parts: TArray<TFormulaPart>;
begin
  Assert.IsTrue(ParseFormula('Mo5B4C', Parts), 'Mo5B4C must parse');
  Assert.AreEqual(3, Length(Parts));
  Assert.AreEqual('Mo', Parts[0].Symbol);
  Assert.AreEqual(5.0, Parts[0].Count, 1E-9);
  Assert.AreEqual('B', Parts[1].Symbol);
  Assert.AreEqual(4.0, Parts[1].Count, 1E-9);
  Assert.AreEqual('C', Parts[2].Symbol);
  Assert.AreEqual(1.0, Parts[2].Count, 1E-9);
end;

procedure TTestMCPMaterials.ParseFormula_SiIMD_IsNotAFormula;
var
  Parts: TArray<TFormulaPart>;
begin
  // "SiIMD" is a table name, not a compound: M is not an element symbol, and
  // the all-caps fallback must not read the tail as Md.
  Assert.IsFalse(ParseFormula('SiIMD', Parts), 'SiIMD must not parse');
  Assert.AreEqual(0, Length(Parts), 'a failed parse returns no parts');
end;

procedure TTestMCPMaterials.ParseFormula_Empty_IsNotAFormula;
var
  Parts: TArray<TFormulaPart>;
begin
  Assert.IsFalse(ParseFormula('', Parts), 'the empty string must not parse');
  Assert.AreEqual(0, Length(Parts));
end;

procedure TTestMCPMaterials.ParseFormula_TrailingDot_IsNotAFormula;
var
  Parts: TArray<TFormulaPart>;
begin
  Assert.IsFalse(ParseFormula('Si2.', Parts), 'a dangling decimal point must not parse');
end;

procedure TTestMCPMaterials.ParseFormula_AllCapsElementName;
var
  Parts: TArray<TFormulaPart>;
begin
  // Half the element tables on disk are spelled in upper case ("RU.bin").
  // Tokenised strictly, "RU" is R followed by U and R is not an element, so
  // the whole string gets one chance as a single case-insensitive symbol.
  Assert.IsTrue(ParseFormula('RU', Parts), 'RU must resolve to ruthenium');
  Assert.AreEqual(1, Length(Parts));
  Assert.AreEqual('Ru', Parts[0].Symbol, False, 'the canonical spelling is reported');
  Assert.AreEqual(1.0, Parts[0].Count, 1E-9);
end;

{ --- Henke lookups --- }

procedure TTestMCPMaterials.ResolveHenkeName_IsCaseInsensitive;
var
  Canonical, Upper: string;
begin
  if not HenkeAvailable('Si') then
    Assert.Pass('Henke table directory has no Si.bin: ' + HenkeDir);

  Assert.IsTrue(ResolveHenkeName('si', Canonical), 'lower case must resolve');
  Assert.IsTrue(ResolveHenkeName('SI', Upper), 'upper case must resolve');
  Assert.AreEqual(Canonical, Upper, False, 'every casing resolves to one name');
  // The spelling that comes back is the one on disk, whatever it is: silicon
  // is "Si.bin" here but the same directory also holds "RU.bin", so the test
  // asserts the file exists under exactly that name rather than a fixed case.
  Assert.IsTrue(SameText('Si', Canonical), 'silicon must resolve to Si');
  Assert.IsTrue(TFile.Exists(HenkeDir + Canonical + '.bin'),
    'the on-disk spelling is reported back');
end;

procedure TTestMCPMaterials.HenkeExists_UnknownMaterial_False;
begin
  Assert.IsFalse(HenkeExists('Xx'), 'there is no Xx table');
  Assert.IsFalse(HenkeExists(''), 'an empty name is not a material');
end;

procedure TTestMCPMaterials.OpticalConstants_Si_CuKAlpha;
var
  DensityUsed, Delta, Beta: Double;
begin
  if not HenkeAvailable('Si') then
    Assert.Pass('Henke table directory has no Si.bin: ' + HenkeDir);

  Assert.IsTrue(OpticalConstants('Si', CU_K_ALPHA, 0, DensityUsed, Delta, Beta),
    'Si must have optical constants at Cu K-alpha');
  Assert.AreEqual(7.6E-6, Delta, 1E-6, 'delta of Si at 1.5406 A');
  Assert.IsTrue(Beta > 0, 'beta must be positive');
  Assert.IsTrue((DensityUsed > 2.0) and (DensityUsed < 2.7),
    'a density of 0 means the bulk value from the table header');
end;

procedure TTestMCPMaterials.OpticalConstants_UnknownMaterial_False;
var
  DensityUsed, Delta, Beta: Double;
begin
  Assert.IsFalse(OpticalConstants('Xx', CU_K_ALPHA, 0, DensityUsed, Delta, Beta),
    'an unknown material has no optical constants');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPMaterials);

end.
