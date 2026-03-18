unit TestHenke;

interface

uses
  DUnitX.TestFramework,
  math_globals,
  math_complex;

type
  [TestFixture]
  TTestHenke = class
  private
    FSavedHenkeDir: string;
    FTempDir: string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { ReadHenkeTable — real DB }
    [Test] procedure Test_ReadHenkeTable_Si_LoadsData;
    [Test] procedure Test_ReadHenkeTable_Si_EnergiesAscending;
    [Test] procedure Test_ReadHenkeTable_NonExistent_Raises;

    { ReadHenke — real DB }
    [Test] procedure Test_ReadHenke_Si_ByEnergy;
    [Test] procedure Test_ReadHenke_Si_ByLambda;
    [Test] procedure Test_ReadHenke_NonExistent_Raises;

    { WriteHenkeTable + ReadHenkeTable roundtrip }
    [Test] procedure Test_WriteRead_Roundtrip;
    [Test] procedure Test_WriteRead_Roundtrip_ReadHenke;
  end;

const
  HENKE_DB_PATH = 'd:\SoftwareStorage\X-RayCalc3\Henke';

implementation

uses
  unit_Config, System.SysUtils, System.IOUtils;

procedure TTestHenke.Setup;
begin
  FSavedHenkeDir := TConfig.Section<TPathOptions>.HenkeDir;
  FTempDir := TPath.Combine(TPath.GetTempPath, 'XRC_TestHenke_' + TGUID.NewGuid.ToString);
end;

procedure TTestHenke.TearDown;
begin
  TConfig.Section<TPathOptions>.HenkeDir := FSavedHenkeDir;
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

{ --- ReadHenkeTable — real DB --- }

procedure TTestHenke.Test_ReadHenkeTable_Si_LoadsData;
var
  Na, Nro: Single;
  Table: THenkeTable;
begin
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;

  SetLength(Table, 0);
  ReadHenkeTable('Si', Na, Nro, Table);

  Assert.IsTrue(Na > 0, 'Na must be positive');
  Assert.IsTrue(Nro > 0, 'Nro must be positive');
  Assert.IsTrue(Length(Table) > 100, 'Si table should have many records');
  Assert.IsTrue(Table[0].e > 0, 'First energy must be positive');
  Assert.IsTrue(Table[0].f1 <> 0, 'f1 should be nonzero');
end;

procedure TTestHenke.Test_ReadHenkeTable_Si_EnergiesAscending;
var
  Na, Nro: Single;
  Table: THenkeTable;
  i: Integer;
begin
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;

  SetLength(Table, 0);
  ReadHenkeTable('Si', Na, Nro, Table);

  for i := 1 to High(Table) do
    Assert.IsTrue(Table[i].e >= Table[i-1].e,
      Format('Energy not ascending at index %d: %.1f < %.1f', [i, Table[i].e, Table[i-1].e]));
end;

procedure TTestHenke.Test_ReadHenkeTable_NonExistent_Raises;
begin
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;

  Assert.WillRaise(
    procedure
    var Na, Nro: Single; Table: THenkeTable;
    begin
      SetLength(Table, 0);
      ReadHenkeTable('ZzNonExistent99', Na, Nro, Table);
    end,
    EInOutError);
end;

{ --- ReadHenke — real DB --- }

procedure TTestHenke.Test_ReadHenke_Si_ByEnergy;
var
  f: TComplex;
  Na, Nro: Single;
begin
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;

  // Cu Ka energy = 8047.8 eV
  ReadHenke('Si', 8047.8, 0, f, Na, Nro);

  Assert.IsTrue(Na > 0, 'Na must be positive');
  Assert.IsTrue(Nro > 0, 'Nro must be positive');
  // Si Z=14; at 8 keV f1 should be close to Z (10..15 range)
  Assert.IsTrue((f.Re > 5) and (f.Re < 20),
    Format('f1 = %.4f out of expected range for Si at 8 keV', [f.Re]));
  Assert.IsTrue(f.Im > 0,
    Format('f2 = %.4f should be positive', [f.Im]));
end;

procedure TTestHenke.Test_ReadHenke_Si_ByLambda;
var
  fE, fL: TComplex;
  NaE, NroE, NaL, NroL: Single;
begin
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;

  // E = H / L;  for Cu Ka: L = 1.5406 A => E = 12398.6/1.5406 = 8047.8
  ReadHenke('Si', 8047.8, 0, fE, NaE, NroE);
  ReadHenke('Si', 0, 1.5406, fL, NaL, NroL);

  Assert.AreEqual(NaE, NaL, 1E-5, 'Na should match');
  Assert.AreEqual(NroE, NroL, 1E-5, 'Nro should match');
  // Allow small tolerance since E=H/L introduces floating-point rounding
  Assert.AreEqual(fE.Re, fL.Re, 0.1, 'f1 should be close');
  Assert.AreEqual(fE.Im, fL.Im, 0.05, 'f2 should be close');
end;

procedure TTestHenke.Test_ReadHenke_NonExistent_Raises;
begin
  TConfig.SystemDir[sdHenke] := HENKE_DB_PATH;

  Assert.WillRaise(
    procedure
    var f: TComplex; Na, Nro: Single;
    begin
      ReadHenke('ZzNonExistent99', 8000, 0, f, Na, Nro);
    end,
    EInOutError);
end;

{ --- WriteHenkeTable + ReadHenkeTable roundtrip --- }

procedure TTestHenke.Test_WriteRead_Roundtrip;
var
  TableOut, TableIn: THenkeTable;
  NaOut, NroOut, NaIn, NroIn: Single;
  i: Integer;
begin
  TDirectory.CreateDirectory(FTempDir);
  TConfig.SystemDir[sdHenke] := FTempDir;

  NaOut := 28.086;   // Si atomic mass
  NroOut := 2.329;   // Si density

  SetLength(TableOut, 3);
  TableOut[0].e := 100;   TableOut[0].f1 := 10.5;  TableOut[0].f2 := 1.2;
  TableOut[1].e := 1000;  TableOut[1].f1 := 12.8;  TableOut[1].f2 := 0.8;
  TableOut[2].e := 10000; TableOut[2].f1 := 14.1;  TableOut[2].f2 := 0.3;

  WriteHenkeTable('TestEl', NaOut, NroOut, TableOut);

  SetLength(TableIn, 0);
  ReadHenkeTable('TestEl', NaIn, NroIn, TableIn);

  Assert.AreEqual(NaOut, NaIn, 1E-5, 'Na roundtrip');
  Assert.AreEqual(NroOut, NroIn, 1E-5, 'Nro roundtrip');
  Assert.AreEqual(Length(TableOut), Length(TableIn), 'Table length');

  for i := 0 to High(TableOut) do
  begin
    Assert.AreEqual(TableOut[i].e,  TableIn[i].e,  1E-5, Format('e[%d]', [i]));
    Assert.AreEqual(TableOut[i].f1, TableIn[i].f1, 1E-5, Format('f1[%d]', [i]));
    Assert.AreEqual(TableOut[i].f2, TableIn[i].f2, 1E-5, Format('f2[%d]', [i]));
  end;
end;

procedure TTestHenke.Test_WriteRead_Roundtrip_ReadHenke;
var
  TableOut: THenkeTable;
  f: TComplex;
  Na, Nro: Single;
begin
  TDirectory.CreateDirectory(FTempDir);
  TConfig.SystemDir[sdHenke] := FTempDir;

  SetLength(TableOut, 3);
  TableOut[0].e := 100;   TableOut[0].f1 := 10.0;  TableOut[0].f2 := 2.0;
  TableOut[1].e := 1000;  TableOut[1].f1 := 13.0;  TableOut[1].f2 := 1.0;
  TableOut[2].e := 10000; TableOut[2].f1 := 14.0;  TableOut[2].f2 := 0.5;

  WriteHenkeTable('TestEl2', 28.0, 2.33, TableOut);

  // Read at E=550 — between first two points, should interpolate
  ReadHenke('TestEl2', 550, 0, f, Na, Nro);

  Assert.AreEqual(Single(28.0), Na, 1E-5, 'Na');
  Assert.AreEqual(Single(2.33), Nro, 1E-5, 'Nro');

  // Linear interpolation between (100,10) and (1000,13) at E=550:
  // f1 = 10 + (13-10)/(1000-100) * (550-100) = 10 + 3/900 * 450 = 11.5
  Assert.AreEqual(Single(11.5), f.Re, 0.01, 'f1 interpolated');
  // f2 = 2 + (1-2)/(1000-100) * (550-100) = 2 - 1/900 * 450 = 1.5
  Assert.AreEqual(Single(1.5), f.Im, 0.01, 'f2 interpolated');
end;

end.
