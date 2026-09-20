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

  { ChiSQRPlain is the sum CalcChiSquare builds with the peak and angle weights
    left off. The weights are what the fit optimises against; the plain number
    is the bare data-to-fit disagreement the GUI shows beside it, so what these
    tests pin down is that no weight can move it. }
  [TestFixture]
  TTestChiSquare = class
  public
    [Test] procedure Test_Plain_EqualsChiSQR_WhenNothingIsWeighted;
    [Test] procedure Test_Plain_MatchesHandSum;
    [Test] procedure Test_Plain_IgnoresThetaWeight;
    [Test] procedure Test_Plain_IgnoresPeakWeight;
  end;

implementation

uses
  unit_materials, unit_calc, System.SysUtils, System.Math;

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
    Assert.AreEqual('Si', M.LayerNames[1]);
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
    Assert.AreEqual('Si', M.LayerNames[1]);
    Assert.AreEqual('Mo', M.LayerNames[2]);
    Assert.AreEqual('Au', M.LayerNames[3]);
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
    Assert.AreEqual('Glass', M.LayerNames[1]);
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
    Assert.AreEqual('Si', M.LayerNames[1]);
    Assert.AreEqual('Glass', M.LayerNames[2]);
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

{ TTestChiSquare }

type
  { CalcChiSquare scores FData against FResult; the calculated curve normally
    comes from Run, and is put there directly here so the arithmetic is the
    only thing under test. }
  TChiCalc = class(TCalc)
  public
    procedure SetResults(const A: TDataArray);
  end;

procedure TChiCalc.SetResults(const A: TDataArray);
begin
  FResult := Copy(A);
end;

{ Four measured points an order of magnitude apart, and a calculated curve that
  misses each of them by a different amount. Every r is positive, so no point is
  skipped, and every theta differs from 1, so an angle weight cannot be mistaken
  for no weight. }
procedure MakeChiCurves(out Data, Calc: TDataArray);
begin
  SetLength(Data, 4);
  Data[0].t := 0.5; Data[0].r := 1E-1;
  Data[1].t := 1.5; Data[1].r := 1E-2;
  Data[2].t := 2.5; Data[2].r := 1E-3;
  Data[3].t := 3.5; Data[3].r := 1E-4;

  SetLength(Calc, 4);
  Calc[0].t := 0.5; Calc[0].r := 1.1E-1;
  Calc[1].t := 1.5; Calc[1].r := 0.9E-2;
  Calc[2].t := 2.5; Calc[2].r := 1.2E-3;
  Calc[3].t := 3.5; Calc[3].r := 1.0E-4;
end;

function MakeChiCalc(const Data, Calc: TDataArray): TChiCalc;
begin
  Result := TChiCalc.Create;
  Result.ExpValues := Data;
  Result.SetResults(Calc);
end;

procedure TTestChiSquare.Test_Plain_EqualsChiSQR_WhenNothingIsWeighted;
var
  C: TChiCalc;
  Data, Calc: TDataArray;
begin
  MakeChiCurves(Data, Calc);
  C := MakeChiCalc(Data, Calc);
  try
    C.CalcChiSquare(0);
    Assert.AreEqual(Double(C.ChiSQR), Double(C.ChiSQRPlain), 1E-9,
      'With no peak weight and no angle weight the two sums are the same sum');
  finally
    C.Free;
  end;
end;

procedure TTestChiSquare.Test_Plain_MatchesHandSum;
var
  C: TChiCalc;
  Data, Calc: TDataArray;
  i: Integer;
  LogCalc, Expected: Double;
begin
  MakeChiCurves(Data, Calc);
  C := MakeChiCalc(Data, Calc);
  try
    C.CalcChiSquare(0);

    { The same range CalcChiSquare walks: FTail is 0 without a resolution
      convolution, so the points are 0 .. n - 2, normalised by n - 1. }
    Expected := 0;
    for i := 0 to High(Data) - 1 do
    begin
      LogCalc := Log10(Calc[i].r);
      Expected := Expected + Sqr((Log10(Data[i].r) - LogCalc) / LogCalc);
    end;
    Expected := Expected / High(Data) * 1000;

    { The engine takes its logarithms with FastLn, and the residual is the
      difference of two nearly equal ones, so the approximation shows up
      magnified: a few parts in ten thousand, against an exact Log10. }
    Assert.AreEqual(Expected, Double(C.ChiSQRPlain), Abs(Expected) * 2E-3,
      Format('plain chi-squared should be %.6g', [Expected]));
  finally
    C.Free;
  end;
end;

procedure TTestChiSquare.Test_Plain_IgnoresThetaWeight;
var
  C: TChiCalc;
  Data, Calc: TDataArray;
  Unweighted: Single;
  W: Integer;
begin
  MakeChiCurves(Data, Calc);
  C := MakeChiCalc(Data, Calc);
  try
    C.CalcChiSquare(0);
    Unweighted := C.ChiSQRPlain;

    for W := 1 to 5 do
    begin
      C.CalcChiSquare(W);
      Assert.AreEqual(Double(Unweighted), Double(C.ChiSQRPlain), 1E-9,
        Format('theta_weight %d must not move the plain sum', [W]));
    end;

    { And the weights really are doing something, or the test above is empty. }
    C.CalcChiSquare(1);
    Assert.AreNotEqual(Double(C.ChiSQRPlain), Double(C.ChiSQR), 1E-6,
      'theta_weight 1 should change the weighted sum');
  finally
    C.Free;
  end;
end;

procedure TTestChiSquare.Test_Plain_IgnoresPeakWeight;
var
  C: TChiCalc;
  Data, Calc, Avg: TDataArray;
  i: Integer;
  Unweighted: Single;
begin
  MakeChiCurves(Data, Calc);
  C := MakeChiCalc(Data, Calc);
  try
    C.CalcChiSquare(0);
    Unweighted := C.ChiSQRPlain;

    { A moving average a tenth of the data: every ratio is 10, over the 3 that
      turns the peak weight on. }
    SetLength(Avg, Length(Data));
    for i := 0 to High(Data) do
    begin
      Avg[i].t := Data[i].t;
      Avg[i].r := Data[i].r * 0.1;
    end;
    C.MovAvg := Avg;

    C.CalcChiSquare(0);
    Assert.AreEqual(Double(Unweighted), Double(C.ChiSQRPlain), 1E-9,
      'the peak weight must not move the plain sum');
    Assert.IsTrue(C.ChiSQR > C.ChiSQRPlain * 5,
      Format('a peak weight of 10 should inflate the weighted sum: %.6g vs %.6g',
             [C.ChiSQR, C.ChiSQRPlain]));
  finally
    C.Free;
  end;
end;

end.
