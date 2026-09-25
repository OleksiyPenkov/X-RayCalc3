unit TestResiduals;

(* unit_Residuals: the residual strip's numbers - log10(R_calc / (I_meas K))
   per measured point, the points on the R min floor, and the bands, which
   must be the Fit report's to the last digit. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Math, System.JSON,
  unit_Types, unit_MCPFitReport, unit_FitReportGUI, unit_Residuals;

type
  [TestFixture]
  TTestResiduals = class
  public
    [Test] procedure ModelAgainstItselfTimesK_IsZeroEverywhere;
    [Test] procedure ModelOnTheFloor_IsFlagged;
    [Test] procedure MeasuredAtOrBelowTheFloor_IsFlagged;
    [Test] procedure BandMeans_AreTheReportsToTheLastDigit;
    [Test] procedure TwoTheta_GivesTheSameResidualsAtDoubledAngles;
    [Test] procedure NoMeasuredCurve_GivesNothing;
    [Test] procedure ZeroWidthRange_HasNoBands;
  end;

implementation

const
  RMIN = 1E-7;

{ A reflectivity-like curve on 0.05 .. 3 deg: falls by 6 decades with a
  wiggle, and never below the floor unless Floor is set. }
function Model(Floor: Double = 0; Mul: Double = 1): TDataArray;
var
  i: Integer;
  T: Double;
begin
  SetLength(Result, 300);
  for i := 0 to High(Result) do
  begin
    T := 0.05 + i * 0.01;
    Result[i].t := T * Mul;
    Result[i].r := Power(10, -2 * T) * (1 + 0.5 * Sin(20 * T));
    if Result[i].r < Floor then
      Result[i].r := Floor;
  end;
end;

{ The measured curve: the model divided by K, with a misfit that grows with
  angle, on every third model angle. }
function Measured(const M: TDataArray; K, Misfit: Double): TDataArray;
var
  i, n: Integer;
begin
  SetLength(Result, Length(M) div 3);
  n := 0;
  i := 0;
  while (i <= High(M)) and (n < Length(Result)) do
  begin
    Result[n].t := M[i].t;
    Result[n].r := M[i].r / K * Power(10, Misfit * i / Length(M));
    Inc(n);
    Inc(i, 3);
  end;
  SetLength(Result, n);
end;

procedure TTestResiduals.ModelAgainstItselfTimesK_IsZeroEverywhere;
var
  M: TDataArray;
  C: TResidualCurve;
  P: TResidualPoint;
begin
  M := Model;
  C := ResidualCurve(FitReportInput(Measured(M, 2.5, 0), M, False, Log10(2.5), 1.54, 0, 0),
                     False, RMIN);
  Assert.AreEqual(100, Integer(Length(C.Points)), 'every measured point');
  for P in C.Points do
  begin
    Assert.AreEqual(0.0, P.D, 1E-6, Format('residual at %.3f', [P.X]));
    Assert.IsFalse(P.Floored, Format('not floored at %.3f', [P.X]));
  end;
end;

procedure TTestResiduals.ModelOnTheFloor_IsFlagged;
var
  M: TDataArray;
  C: TResidualCurve;
  P: TResidualPoint;
  Floored, Clear: Integer;
begin
  { Floored from about 2.3 deg; the measured curve stays above it. }
  M := Model(Power(10, -4.6));
  C := ResidualCurve(FitReportInput(Measured(Model, 1, 0), M, False, 0, 1.54, 0, 0),
                     False, Power(10, -4.6));
  Floored := 0;
  Clear := 0;
  for P in C.Points do
    if P.Floored then
    begin
      Inc(Floored);
      Assert.IsTrue(P.X > 2.0, Format('floored at %.3f', [P.X]));
    end
    else
      Inc(Clear);
  Assert.IsTrue(Floored > 0, 'the tail is flagged');
  Assert.IsTrue(Clear > 0, 'the start is not');
end;

procedure TTestResiduals.MeasuredAtOrBelowTheFloor_IsFlagged;
var
  M, D: TDataArray;
  C: TResidualCurve;
begin
  M := Model;
  D := Measured(M, 1, 0);
  D[10].r := RMIN;        // at the floor
  D[20].r := RMIN / 3;    // below it
  C := ResidualCurve(FitReportInput(D, M, False, 0, 1.54, 0, 0), False, RMIN);
  Assert.IsTrue(C.Points[10].Floored, 'at the floor');
  Assert.IsTrue(C.Points[20].Floored, 'below the floor');
  Assert.IsFalse(C.Points[15].Floored, 'above it');
end;

procedure TTestResiduals.BandMeans_AreTheReportsToTheLastDigit;
var
  M: TDataArray;
  Inp: TFitReportInput;
  C: TResidualCurve;
  Rep: TJSONObject;
  Bands: TJSONArray;
  Band: TJSONObject;
  Expected: TJSONValue;
  b: Integer;
begin
  M := Model;
  Inp := FitReportInput(Measured(M, 1.7, 0.4), M, False, Log10(1.3), 1.54, 0, 0);
  C := ResidualCurve(Inp, False, RMIN);

  Rep := FitReportJSON(Inp);
  try
    Bands := Rep.GetValue('bands') as TJSONArray;
    Assert.AreEqual(Bands.Count, Integer(Length(C.Bands)), 'as many bands');
    for b := 0 to Bands.Count - 1 do
    begin
      Band := Bands.Items[b] as TJSONObject;
      Assert.AreEqual(Band.GetValue<Integer>('n'), C.Bands[b].Count, Format('band %d n', [b]));
      { The report prints 6 significant digits; the strip's number, printed the
        same way, must read the same - and before printing, both are one Double. }
      Expected := NumOrNull(C.Bands[b].Mean, True);
      try
        Assert.AreEqual(Band.GetValue('mean').ToString, Expected.ToString, Format('band %d mean', [b]));
      finally
        Expected.Free;
      end;
      Assert.IsTrue(ReportBands(Inp)[b].Mean = C.Bands[b].Mean, Format('band %d mean, unrounded', [b]));
      Assert.IsTrue(ReportBands(Inp)[b].Theta0 = C.Bands[b].Theta0, Format('band %d start', [b]));
      Assert.AreEqual((Band.GetValue('theta_deg') as TJSONArray).Items[0].GetValue<Double>,
                      C.Bands[b].Theta0, 1E-5, Format('band %d start as printed', [b]));
    end;
  finally
    Rep.Free;
  end;
end;

procedure TTestResiduals.TwoTheta_GivesTheSameResidualsAtDoubledAngles;
var
  M, M2: TDataArray;
  C, C2: TResidualCurve;
  i: Integer;
begin
  M := Model;
  M2 := Model(0, 2);
  C := ResidualCurve(FitReportInput(Measured(M, 1, 0.4), M, False, 0, 1.54, 0, 0), False, RMIN);
  C2 := ResidualCurve(FitReportInput(Measured(M2, 1, 0.4), M2, True, 0, 1.54, 0, 0), True, RMIN);

  Assert.AreEqual(Length(C.Points), Length(C2.Points), 'as many points');
  for i := 0 to High(C.Points) do
  begin
    Assert.AreEqual(2 * C.Points[i].X, C2.Points[i].X, 1E-5, Format('angle %d', [i]));
    Assert.AreEqual(C.Points[i].D, C2.Points[i].D, 1E-6, Format('residual %d', [i]));
  end;
  Assert.AreEqual(2 * C.Bands[3].Theta0, C2.Bands[3].Theta0, 1E-5, 'band edges in 2theta');
end;

procedure TTestResiduals.NoMeasuredCurve_GivesNothing;
var
  C: TResidualCurve;
begin
  C := ResidualCurve(FitReportInput(nil, Model, False, 0, 1.54, 0, 0), False, RMIN);
  Assert.AreEqual(0, Integer(Length(C.Points)), 'points');
  Assert.AreEqual(0, Integer(Length(C.Bands)), 'bands');
end;

procedure TTestResiduals.ZeroWidthRange_HasNoBands;
var
  Inp: TFitReportInput;
  i: Integer;
begin
  Inp := Default(TFitReportInput);
  SetLength(Inp.Measured, 3);
  SetLength(Inp.Calculated, 3);
  for i := 0 to 2 do
  begin
    Inp.Measured[i].t := 1;
    Inp.Measured[i].r := 1E-3;
    Inp.Calculated[i].t := 1;
    Inp.Calculated[i].r := 2E-3;
  end;
  Assert.AreEqual(0, Integer(Length(ReportBands(Inp))), 'report');
  Assert.AreEqual(0, Integer(Length(ResidualCurve(Inp, False, RMIN).Bands)), 'strip');
  Assert.AreEqual(3, Integer(Length(ResidualCurve(Inp, False, RMIN).Points)), 'the points are still there');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestResiduals);

end.
