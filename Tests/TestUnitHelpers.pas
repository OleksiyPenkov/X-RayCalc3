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
  end;

implementation

uses
  unit_helpers, System.SysUtils, System.Math;

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

end.
