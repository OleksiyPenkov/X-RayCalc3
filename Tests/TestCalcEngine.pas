unit TestCalcEngine;

interface

uses
  DUnitX.TestFramework,
  unit_Types,
  math_complex;

type
  [TestFixture]
  TTestLayeredModel = class
  public
    [Test] procedure Test_Init_CreatesVacuumLayer;
    [Test] procedure Test_AddLayers_SingleLayer;
    [Test] procedure Test_AddLayers_MultipleStacks;
    [Test] procedure Test_AddSubstrate;
    [Test] procedure Test_FullStructure_VacuumPlusLayersPlusSubstrate;
  end;

  [TestFixture]
  TTestCalc = class
  public
    [Test] procedure Test_Create_DefaultLimit;
    [Test] procedure Test_SetExpValues;
  end;

implementation

uses
  unit_materials, unit_calc, System.SysUtils;

{ TTestLayeredModel }

procedure TTestLayeredModel.Test_Init_CreatesVacuumLayer;
var
  M: TLayeredModel;
  L: TCalcLayers;
begin
  M := TLayeredModel.Create;
  try
    M.Init;
    L := M.Layers;
    Assert.AreEqual(1, Length(L), 'Init should create 1 vacuum layer');
    Assert.AreEqual(Single(1.0), L[0].e.Re, 1E-5, 'Vacuum epsilon.Re = 1');
    Assert.AreEqual(Single(0.0), L[0].e.Im, 1E-5, 'Vacuum epsilon.Im = 0');
  finally
    M.Free;
  end;
end;

procedure TTestLayeredModel.Test_AddLayers_SingleLayer;
var
  M: TLayeredModel;
  LD: TLayersData;
  L: TCalcLayers;
begin
  M := TLayeredModel.Create;
  try
    M.Init;

    SetLength(LD, 1);
    LD[0].Material := 'Si';
    LD[0].P[1].New(100);  // H = 100 Angstrom
    LD[0].P[2].New(3);    // sigma = 3
    LD[0].P[3].New(2.33); // rho = 2.33
    LD[0].LayerID := 1;
    LD[0].StackID := 1;

    M.AddLayers(1, LD);
    L := M.Layers;

    Assert.AreEqual(2, Length(L), 'Vacuum + 1 layer = 2');
    Assert.AreEqual('Si', L[1].Name);
    Assert.AreEqual(Single(100), L[1].L, 1E-5, 'Layer thickness');
    Assert.AreEqual(Single(3), L[1].s, 1E-5, 'Layer sigma');
    Assert.AreEqual(Single(2.33), L[1].ro, 1E-3, 'Layer density');
  finally
    M.Free;
  end;
end;

procedure TTestLayeredModel.Test_AddLayers_MultipleStacks;
var
  M: TLayeredModel;
  LD1, LD2: TLayersData;
  L: TCalcLayers;
begin
  M := TLayeredModel.Create;
  try
    M.Init;

    // Stack 1: 2 layers
    SetLength(LD1, 2);
    LD1[0].Material := 'Si';
    LD1[0].P[1].New(50);
    LD1[0].P[2].New(1);
    LD1[0].P[3].New(2.33);
    LD1[1].Material := 'Mo';
    LD1[1].P[1].New(30);
    LD1[1].P[2].New(2);
    LD1[1].P[3].New(10.2);
    M.AddLayers(1, LD1);

    // Stack 2: 1 layer
    SetLength(LD2, 1);
    LD2[0].Material := 'Au';
    LD2[0].P[1].New(10);
    LD2[0].P[2].New(0.5);
    LD2[0].P[3].New(19.3);
    M.AddLayers(2, LD2);

    L := M.Layers;
    Assert.AreEqual(4, Length(L), 'Vacuum + 2 + 1 = 4');
    Assert.AreEqual('Si', L[1].Name);
    Assert.AreEqual('Mo', L[2].Name);
    Assert.AreEqual('Au', L[3].Name);
  finally
    M.Free;
  end;
end;

procedure TTestLayeredModel.Test_AddSubstrate;
var
  M: TLayeredModel;
  LD: TLayersData;
  L: TCalcLayers;
begin
  M := TLayeredModel.Create;
  try
    M.Init;

    SetLength(LD, 1);
    LD[0].Material := 'Glass';
    LD[0].P[2].New(2.5);  // sigma
    LD[0].P[3].New(2.2);  // rho

    M.AddSubstrate(LD);
    L := M.Layers;

    Assert.AreEqual(2, Length(L), 'Vacuum + substrate = 2');
    Assert.AreEqual('Glass', L[1].Name);
    Assert.AreEqual(Single(1E8), L[1].L, 1E3, 'Substrate has very large thickness');
    Assert.AreEqual(Single(2.5), L[1].s, 1E-5);
    Assert.AreEqual(Single(2.2), L[1].ro, 1E-3);
  finally
    M.Free;
  end;
end;

procedure TTestLayeredModel.Test_FullStructure_VacuumPlusLayersPlusSubstrate;
var
  M: TLayeredModel;
  LD, SubLD: TLayersData;
  L: TCalcLayers;
begin
  // Build: Vacuum | Si(100A) | Substrate(Glass)
  M := TLayeredModel.Create;
  try
    M.Init;

    SetLength(LD, 1);
    LD[0].Material := 'Si';
    LD[0].P[1].New(100);
    LD[0].P[2].New(3);
    LD[0].P[3].New(2.33);
    M.AddLayers(1, LD);

    SetLength(SubLD, 1);
    SubLD[0].Material := 'Glass';
    SubLD[0].P[2].New(1);
    SubLD[0].P[3].New(2.2);
    M.AddSubstrate(SubLD);

    L := M.Layers;
    Assert.AreEqual(3, Length(L), 'Vacuum + Si + Glass = 3');
    Assert.AreEqual(Single(1.0), L[0].e.Re, 1E-5, 'First layer is vacuum');
    Assert.AreEqual('Si', L[1].Name);
    Assert.AreEqual('Glass', L[2].Name);
  finally
    M.Free;
  end;
end;

{ TTestCalc }

procedure TTestCalc.Test_Create_DefaultLimit;
var
  C: TCalc;
begin
  C := TCalc.Create;
  try
    Assert.AreEqual(Single(1E-7), C.Limit, 1E-10, 'Default limit should be 1E-7');
  finally
    C.Free;
  end;
end;

procedure TTestCalc.Test_SetExpValues;
var
  C: TCalc;
  D: TDataArray;
begin
  C := TCalc.Create;
  try
    SetLength(D, 3);
    D[0].t := 0.5; D[0].r := 1.0;
    D[1].t := 1.0; D[1].r := 0.5;
    D[2].t := 1.5; D[2].r := 0.1;
    C.ExpValues := D;
    Assert.AreEqual(3, Length(C.ExpValues));
    Assert.AreEqual(Single(0.5), Single(C.ExpValues[0].t), 1E-5);
  finally
    C.Free;
  end;
end;

end.
