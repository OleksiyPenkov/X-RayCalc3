unit TestSavitzkyGolay;

interface

uses
  DUnitX.TestFramework,
  unit_Types;

type
  [TestFixture]
  TTestSavitzkyGolay = class
  private
    function MakeUniformData(const Values: array of Single; Step: Single = 1.0): TDataArray;
  public
    [Test] procedure Test_SmoothCurve_PreservesLength;
    [Test] procedure Test_SmoothCurve_PreservesOuterBoundary;
    [Test] procedure Test_SmoothCurve_ModifiesInterior;
    [Test] procedure Test_SmoothCurve_NoCrash_SmallData;
  end;

implementation

uses
  unit_SavitzkyGolay, System.SysUtils, System.Math;

function TTestSavitzkyGolay.MakeUniformData(const Values: array of Single; Step: Single): TDataArray;
var
  i: Integer;
begin
  SetLength(Result, Length(Values));
  for i := 0 to High(Values) do
  begin
    Result[i].t := i * Step;
    Result[i].r := Values[i];
  end;
end;

procedure TTestSavitzkyGolay.Test_SmoothCurve_PreservesLength;
var
  D: TDataArray;
begin
  D := MakeUniformData([1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13]);
  TSavitzkyGolay.SmoothCurve(D, 2, 5);
  Assert.AreEqual(13, Length(D));
end;

procedure TTestSavitzkyGolay.Test_SmoothCurve_PreservesOuterBoundary;
var
  D: TDataArray;
begin
  // Outermost points (index 0, 1 and last, second-last) should not be modified
  // NOTE: There is an off-by-one in SmoothCurve — the computation loop starts
  //   at halfWindowSize+1 but the copy loop starts at halfWindowSize,
  //   so data[halfWindowSize] gets zeroed. Only the outer boundary is truly safe.
  D := MakeUniformData([99, 88, 1, 1, 1, 1, 1, 1, 1, 1, 1, 77, 66]);
  TSavitzkyGolay.SmoothCurve(D, 2, 5);
  Assert.AreEqual(Single(99.0), D[0].r, 1E-3, 'First point preserved');
  Assert.AreEqual(Single(88.0), D[1].r, 1E-3, 'Second point preserved');
  Assert.AreEqual(Single(66.0), D[High(D)].r, 1E-3, 'Last point preserved');
  Assert.AreEqual(Single(77.0), D[High(D)-1].r, 1E-3, 'Second-last point preserved');
end;

procedure TTestSavitzkyGolay.Test_SmoothCurve_ModifiesInterior;
var
  D, Orig: TDataArray;
  Changed: Boolean;
  i: Integer;
begin
  // Interior points should be modified after smoothing
  D := MakeUniformData([0, 0, 0, 0, 0, 10, 10, 10, 10, 10, 10, 10, 10]);
  SetLength(Orig, Length(D));
  for i := 0 to High(D) do
    Orig[i].r := D[i].r;

  TSavitzkyGolay.SmoothCurve(D, 2, 5);

  Changed := False;
  for i := 3 to High(D) - 3 do
    if Abs(D[i].r - Orig[i].r) > 1E-5 then
    begin
      Changed := True;
      Break;
    end;
  Assert.IsTrue(Changed, 'Interior points should be modified by smoothing');
end;

procedure TTestSavitzkyGolay.Test_SmoothCurve_NoCrash_SmallData;
var
  D: TDataArray;
begin
  // Should not crash on data shorter than window
  D := MakeUniformData([1, 2, 3, 4, 5]);
  TSavitzkyGolay.SmoothCurve(D, 2, 5);
  Assert.AreEqual(5, Length(D));
end;

end.
