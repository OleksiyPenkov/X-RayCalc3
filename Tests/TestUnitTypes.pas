unit TestUnitTypes;

interface

uses
  DUnitX.TestFramework,
  unit_types;

type
  [TestFixture]
  TTestFitValue = class
  public
    [Test] procedure Test_New;
    [Test] procedure Test_Init_Deviation;
    [Test] procedure Test_Init_MinMax;
    [Test] procedure Test_Init_NoArgs;
    [Test] procedure Test_Seed_InRange;
  end;

  [TestFixture]
  TTestFitStructure = class
  public
    [Test] procedure Test_Total_Empty;
    [Test] procedure Test_Total_WithLayers;
    [Test] procedure Test_TotalNP;
  end;

  [TestFixture]
  TTestLayerProfile = class
  public
    [Test] procedure Test_ProfileToString_Empty;
    [Test] procedure Test_ProfileToString_WithValues;
    [Test] procedure Test_ProfileFromString_Roundtrip;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TTestFitValue }

procedure TTestFitValue.Test_New;
var FV: TFitValue;
begin
  FV.New(10.0);
  Assert.AreEqual(Single(10.0), FV.V);
  Assert.AreEqual(Single(0.0), FV.min);
  Assert.AreEqual(Single(0.0), FV.max);
  Assert.IsFalse(FV.Paired);
end;

procedure TTestFitValue.Test_Init_Deviation;
var FV: TFitValue;
begin
  FV.New(100.0);
  FV.Init(0.1); // 10% deviation
  // min = 100 * (1 - 0.1) = 90
  // max = 100 * (1 + 0.1) = 110
  Assert.AreEqual(Single(90.0), FV.min, 1E-4);
  Assert.AreEqual(Single(110.0), FV.max, 1E-4);
end;

procedure TTestFitValue.Test_Init_MinMax;
var FV: TFitValue;
begin
  FV.New(50.0);
  FV.Init(20.0, 80.0);
  Assert.AreEqual(Single(20.0), FV.min);
  Assert.AreEqual(Single(80.0), FV.max);
end;

procedure TTestFitValue.Test_Init_NoArgs;
var FV: TFitValue;
begin
  FV.New(42.0);
  FV.Init; // sets min = max = V
  Assert.AreEqual(Single(42.0), FV.min);
  Assert.AreEqual(Single(42.0), FV.max);
end;

procedure TTestFitValue.Test_Seed_InRange;
var
  FV: TFitValue;
  i: Integer;
begin
  RandSeed := 12345;
  FV.New(0);
  FV.Init(10.0, 20.0);
  for i := 1 to 100 do
  begin
    FV.Seed;
    Assert.IsTrue((FV.V >= 10.0) and (FV.V <= 20.0),
      Format('Seed produced %g outside [10,20]', [FV.V]));
  end;
end;

{ TTestFitStructure }

procedure TTestFitStructure.Test_Total_Empty;
var FS: TFitStructure;
begin
  // Single stack with zero layers
  SetLength(FS.Stacks, 1);
  SetLength(FS.Stacks[0].Layers, 0);
  Assert.AreEqual(Word(0), FS.Total);
end;

procedure TTestFitStructure.Test_Total_WithLayers;
var FS: TFitStructure;
begin
  SetLength(FS.Stacks, 2);
  SetLength(FS.Stacks[0].Layers, 3);
  SetLength(FS.Stacks[1].Layers, 2);
  Assert.AreEqual(Word(5), FS.Total);
end;

procedure TTestFitStructure.Test_TotalNP;
var FS: TFitStructure;
begin
  SetLength(FS.Stacks, 2);
  // Stack 0: 3 layers, repeated 2 times
  FS.Stacks[0].N := 2;
  SetLength(FS.Stacks[0].Layers, 3);
  // Stack 1: 1 layer, repeated 5 times
  FS.Stacks[1].N := 5;
  SetLength(FS.Stacks[1].Layers, 1);
  // TotalNP = 3*2 + 1*5 = 11
  Assert.AreEqual(Word(11), FS.TotalNP);
end;

{ TTestLayerProfile }

procedure TTestLayerProfile.Test_ProfileToString_Empty;
var
  LD: TLayerData;
begin
  // H profile (ptH = 0, so p = 1)
  LD.ClearProfiles(1);
  Assert.AreEqual('', LD.ProfileToString(ptH));
end;

procedure TTestLayerProfile.Test_ProfileToString_WithValues;
var
  LD: TLayerData;
  S: string;
begin
  LD.ClearProfiles(1);
  LD.AddProfilePoint(1.5, 1);
  LD.AddProfilePoint(2.5, 1);
  S := LD.ProfileToString(ptH);
  Assert.IsNotEmpty(S);
  Assert.Contains(S, '1.5');
  Assert.Contains(S, '2.5');
  Assert.Contains(S, ';');
end;

procedure TTestLayerProfile.Test_ProfileFromString_Roundtrip;
var
  LD1, LD2: TLayerData;
  S: string;
begin
  LD1.ClearProfiles(1);
  LD1.AddProfilePoint(1.0, 1);
  LD1.AddProfilePoint(2.0, 1);
  LD1.AddProfilePoint(3.0, 1);
  S := LD1.ProfileToString(ptH);

  LD2.ClearProfiles(1);
  LD2.ProfileFromString(1, S);

  Assert.AreEqual(Length(LD1.PP[1]), Length(LD2.PP[1]));
  Assert.AreEqual(LD1.PP[1][0], LD2.PP[1][0], 1E-3);
  Assert.AreEqual(LD1.PP[1][1], LD2.PP[1][1], 1E-3);
  Assert.AreEqual(LD1.PP[1][2], LD2.PP[1][2], 1E-3);
end;

end.
