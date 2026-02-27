unit TestUnitHelpers;

interface

uses
  DUnitX.TestFramework,
  unit_types;

type
  [TestFixture]
  TTestHelpers = class
  private
    function MakeData(const Values: array of Single): TDataArray;
  public
    { MovAvg }
    [Test] procedure Test_MovAvg_Constant;
    [Test] procedure Test_MovAvg_PreservesLength;
    [Test] procedure Test_MovAvg_KnownPattern;
    [Test] procedure Test_MovAvg_FractionalWindow;

    { Smooth }
    [Test] procedure Test_Smooth_Constant;
    [Test] procedure Test_Smooth_PreservesLength;
    [Test] procedure Test_Smooth_AutoWindow;
    [Test] procedure Test_Smooth_KnownPattern;

    { SeriesToData / DataToSeries }
    [Test] procedure Test_SeriesToData;
    [Test] procedure Test_DataToSeries;
    [Test] procedure Test_SeriesToData_DataToSeries_Roundtrip;

    { Normalize }
    [Test] procedure Test_Normalize;
    [Test] procedure Test_NormalizeAuto;

    { ManualMerge }
    [Test] procedure Test_ManualMerge;
  end;

implementation

uses
  unit_helpers, System.SysUtils, System.Math, VclTee.Series;

{ TTestHelpers }

function TTestHelpers.MakeData(const Values: array of Single): TDataArray;
var
  i: Integer;
begin
  SetLength(Result, Length(Values));
  for i := 0 to High(Values) do
  begin
    Result[i].t := i;
    Result[i].r := Values[i];
  end;
end;

{ --- MovAvg --- }

procedure TTestHelpers.Test_MovAvg_Constant;
var
  Inp, Out_: TDataArray;
  i: Integer;
begin
  // Constant array: moving average should stay constant
  Inp := MakeData([5, 5, 5, 5, 5, 5, 5, 5, 5, 5]);
  Out_ := MovAvg(Inp, 3);
  for i := 0 to High(Out_) do
    Assert.AreEqual(Single(5.0), Out_[i].r, 0.01,
      Format('MovAvg[%d] expected 5.0 got %g', [i, Out_[i].r]));
end;

procedure TTestHelpers.Test_MovAvg_PreservesLength;
var
  Inp, Out_: TDataArray;
begin
  Inp := MakeData([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  Out_ := MovAvg(Inp, 3);
  Assert.AreEqual(Length(Inp), Length(Out_));
end;

procedure TTestHelpers.Test_MovAvg_KnownPattern;
var
  Inp, Out_: TDataArray;
begin
  // With window=2, the averaged value at index i-offset should be mean of [i-2..i]
  Inp := MakeData([0, 0, 0, 3, 3, 3, 0, 0, 0, 0]);
  Out_ := MovAvg(Inp, 2);
  // Just verify the output has reasonable smoothing: center values should be non-zero
  Assert.IsTrue(Out_[4].r > 0, 'Center should have positive value after averaging');
end;

procedure TTestHelpers.Test_MovAvg_FractionalWindow;
var
  Inp, Out_: TDataArray;
begin
  // When W <= 1, Window = Round(Length * W)
  Inp := MakeData([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  Out_ := MovAvg(Inp, 0.3); // Window = Round(10 * 0.3) = 3
  Assert.AreEqual(Length(Inp), Length(Out_));
end;

{ --- Smooth --- }

procedure TTestHelpers.Test_Smooth_Constant;
var
  Inp, Out_: TDataArray;
  i: Integer;
begin
  Inp := MakeData([3, 3, 3, 3, 3, 3, 3, 3, 3, 3]);
  Out_ := Smooth(Inp, 2);
  for i := 0 to High(Out_) do
    Assert.AreEqual(Single(3.0), Out_[i].r, 0.01,
      Format('Smooth[%d] expected 3.0 got %g', [i, Out_[i].r]));
end;

procedure TTestHelpers.Test_Smooth_PreservesLength;
var
  Inp, Out_: TDataArray;
begin
  Inp := MakeData([1, 2, 3, 4, 5, 6, 7, 8, 9, 10]);
  Out_ := Smooth(Inp, 2);
  Assert.AreEqual(Length(Inp), Length(Out_));
end;

procedure TTestHelpers.Test_Smooth_AutoWindow;
var
  Inp, Out_: TDataArray;
begin
  // W = -1 triggers auto window calculation
  Inp := MakeData([1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
                    11, 12, 13, 14, 15, 16, 17, 18, 19, 20]);
  Out_ := Smooth(Inp, -1);
  Assert.AreEqual(Length(Inp), Length(Out_));
end;

procedure TTestHelpers.Test_Smooth_KnownPattern;
var
  Inp, Out_: TDataArray;
begin
  // Smoothing a step function should produce intermediate values
  Inp := MakeData([0, 0, 0, 0, 0, 10, 10, 10, 10, 10]);
  Out_ := Smooth(Inp, 2);
  // The transition region (around index 4-5) should have intermediate values
  Assert.IsTrue(Out_[4].r < 10.0, 'Transition should be smoothed below 10');
end;

{ --- SeriesToData / DataToSeries --- }

procedure TTestHelpers.Test_SeriesToData;
var
  S: TLineSeries;
  D: TDataArray;
begin
  S := TLineSeries.Create(nil);
  try
    S.AddXY(1.0, 10.0);
    S.AddXY(2.0, 20.0);
    S.AddXY(3.0, 30.0);
    D := SeriesToData(S);
    Assert.AreEqual(3, Length(D));
    Assert.AreEqual(Single(1.0), Single(D[0].t), 1E-5);
    Assert.AreEqual(Single(10.0), Single(D[0].r), 1E-5);
    Assert.AreEqual(Single(3.0), Single(D[2].t), 1E-5);
    Assert.AreEqual(Single(30.0), Single(D[2].r), 1E-5);
  finally
    S.Free;
  end;
end;

procedure TTestHelpers.Test_DataToSeries;
var
  S: TLineSeries;
  D: TDataArray;
begin
  D := MakeData([100, 200, 300]);
  S := TLineSeries.Create(nil);
  try
    DataToSeries(D, S);
    Assert.AreEqual(3, S.Count);
    Assert.AreEqual(Double(0), S.XValue[0], 1E-5);
    Assert.AreEqual(Double(100), S.YValue[0], 1E-5);
    Assert.AreEqual(Double(2), S.XValue[2], 1E-5);
    Assert.AreEqual(Double(300), S.YValue[2], 1E-5);
  finally
    S.Free;
  end;
end;

procedure TTestHelpers.Test_SeriesToData_DataToSeries_Roundtrip;
var
  S1, S2: TLineSeries;
  D: TDataArray;
begin
  S1 := TLineSeries.Create(nil);
  S2 := TLineSeries.Create(nil);
  try
    S1.AddXY(0.5, 1.5);
    S1.AddXY(1.5, 2.5);
    S1.AddXY(2.5, 3.5);
    D := SeriesToData(S1);
    DataToSeries(D, S2);
    Assert.AreEqual(S1.Count, S2.Count);
    Assert.AreEqual(S1.XValue[0], S2.XValue[0], 1E-3);
    Assert.AreEqual(S1.YValue[0], S2.YValue[0], 1E-3);
    Assert.AreEqual(S1.XValue[2], S2.XValue[2], 1E-3);
    Assert.AreEqual(S1.YValue[2], S2.YValue[2], 1E-3);
  finally
    S1.Free;
    S2.Free;
  end;
end;

{ --- Normalize --- }

procedure TTestHelpers.Test_Normalize;
var
  S: TLineSeries;
begin
  S := TLineSeries.Create(nil);
  try
    S.AddXY(1, 10);
    S.AddXY(2, 20);
    S.AddXY(3, 30);
    Normalize(10, S);
    Assert.AreEqual(Double(1.0), S.YValue[0], 1E-5);
    Assert.AreEqual(Double(2.0), S.YValue[1], 1E-5);
    Assert.AreEqual(Double(3.0), S.YValue[2], 1E-5);
  finally
    S.Free;
  end;
end;

procedure TTestHelpers.Test_NormalizeAuto;
var
  Calc, Exp: TLineSeries;
begin
  // NormalizeAuto: finds max of Exp, matches it to Calc at same X, scales Exp
  Calc := TLineSeries.Create(nil);
  Exp := TLineSeries.Create(nil);
  try
    // Calc: known curve at X=1..3
    Calc.AddXY(1, 5);
    Calc.AddXY(2, 10);
    Calc.AddXY(3, 5);
    // Exp: peak at X=2 with Y=100 (should be normalized to Calc's Y=10 at X=2)
    Exp.AddXY(1, 50);
    Exp.AddXY(2, 100);
    Exp.AddXY(3, 50);
    NormalizeAuto(Calc, Exp);
    // After normalization, Exp peak at X=2 should be close to Calc at X=2 (=10)
    Assert.AreEqual(Double(10.0), Exp.YValue[1], 0.5, 'Peak should be normalized to Calc value');
  finally
    Calc.Free;
    Exp.Free;
  end;
end;

{ --- ManualMerge --- }

procedure TTestHelpers.Test_ManualMerge;
var
  S: TLineSeries;
begin
  S := TLineSeries.Create(nil);
  try
    S.AddXY(1, 10);
    S.AddXY(2, 20);
    S.AddXY(3, 30);
    S.AddXY(4, 40);
    // ManualMerge at X=3, K=2: divides all points from X=3 onward by 2
    ManualMerge(3, 2, S);
    Assert.AreEqual(Double(10.0), S.YValue[0], 1E-5, 'Before merge point: unchanged');
    Assert.AreEqual(Double(20.0), S.YValue[1], 1E-5, 'Before merge point: unchanged');
    Assert.AreEqual(Double(15.0), S.YValue[2], 1E-5, 'At merge point: divided by 2');
    Assert.AreEqual(Double(20.0), S.YValue[3], 1E-5, 'After merge point: divided by 2');
  finally
    S.Free;
  end;
end;

end.
