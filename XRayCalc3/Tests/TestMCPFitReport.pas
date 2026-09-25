unit TestMCPFitReport;

(* The fit report: the numbers a client is given instead of two long curves.

   Everything here is pure - two arrays in, one JSON object out - so the whole
   fixture runs without the engine and without a Henke table.

   The centrepiece is Reference_Orders_MatchTheOrchestratorsNumbers. The two
   curves under Tests\Data\report-ref are measured.dat and calc.dat of job
   fit-20260918-170706-196b, the C/Co mirror P2-05 fitted on 2026-09-18, and the
   four ratios the report must produce for them - 0.98, 1.22, 1.09 and 0.72 at
   theta 0.9163, 1.7772, 2.6578 and 3.5322 - were computed independently from
   the same files by the paper session's skilltest_compare.py. If the order
   finder is ever changed, that test says whether it still finds the orders a
   physicist found by hand. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  unit_Types, unit_MCPFitReport;

type
  [TestFixture]
  TTestMCPFitReport = class
  private
    /// <summary>Tests\Data\report-ref\&lt;Name&gt;, read as theta / value pairs
    /// with the one-line header WriteCurveFile puts there.</summary>
    function LoadReference(const Name: string): TDataArray;
    /// <summary>A slowly decaying curve modulated by a cosine of period
    /// FringeStep and depth Depth, with its maxima at 0.9 + k * FringeStep so
    /// that the first two Bragg orders of REF_PERIOD_FRINGE fall on two of
    /// them. Depth 0.5 gives a fringe contrast of 3.</summary>
    function FringeCurve(FringeStep: Double; Depth: Double = 0.5): TDataArray;
    /// <summary>The orders array of a report over the two curves.</summary>
    function OrdersOf(Rep: TJSONObject): TJSONArray;
    /// <summary>One order of the report, by its n.</summary>
    function OrderN(Rep: TJSONObject; N: Integer): TJSONObject;
  public
    [Test] procedure Background_IsTheMedianOfTheLastHundredPoints;
    [Test] procedure Background_ShortCurve_UsesEveryPoint;

    [Test] procedure Reference_Orders_MatchTheOrchestratorsNumbers;
    [Test] procedure Reference_Orders_AreTheSameWithAndWithoutRefraction;
    [Test] procedure Reference_EveryOrderIsVisible;
    [Test] procedure Reference_BandsCoverTheRange;

    [Test] procedure Orders_NoPeriod_AreNull;
    [Test] procedure Orders_BelowTheBackground_AreNotVisible;
    [Test] procedure Bands_ConstantRatio_IsTheSameInEveryBand;
    [Test] procedure Edge_HasThreePointsBeforeTheFirstMinimum;
    [Test] procedure Edge_PlateauWiggleIsNotTheFirstMinimum;
    [Test] procedure Fringes_PairEverySecondaryMaximumWithTheMinimumAfterIt;
    [Test] procedure Fringes_ContrastIsLocalAndNotTheFallBetweenTheOrders;
    [Test] procedure Fringes_BothCurvesAreReadAtTheSamePositions;
    [Test] procedure Fringes_OneOrderOnly_IsNull;
  end;

implementation

uses
  System.Classes, System.IOUtils, System.Math, System.Types;

const
  CU_K_ALPHA = 1.5406;

  { The fitted model of job fit-20260918-170706-196b: C 31.0259 + Co 19.1109. }
  REF_PERIOD = 50.136783599852905;
  { The critical angle of that C/Co stack, near enough for the order window. }
  REF_THETA_C = 0.30;

  { A period whose first two orders sit at 0.9 and 1.8 degrees. }
  REF_PERIOD_FRINGE = 49.0381;

{ --------------------------------------------------------------- helpers -- }

function TTestMCPFitReport.LoadReference(const Name: string): TDataArray;
var
  Lines: TStringList;
  Parts: TArray<string>;
  i, n: Integer;
  Path: string;
  FS: TFormatSettings;
begin
  Path := TPath.GetFullPath(TPath.Combine(ExtractFilePath(ParamStr(0)),
    '..\..\Data\report-ref\' + Name));
  Assert.IsTrue(TFile.Exists(Path), 'missing test asset: ' + Path);

  FS := TFormatSettings.Invariant;
  Lines := TStringList.Create;
  try
    Lines.LoadFromFile(Path);
    SetLength(Result, Lines.Count);
    n := 0;
    for i := 0 to Lines.Count - 1 do
    begin
      Parts := Lines[i].Split([#9, ' '], TStringSplitOptions.ExcludeEmpty);
      if Length(Parts) <> 2 then
        Continue;
      if not TryStrToFloat(Parts[0], Result[n].t, FS) then
        Continue;                     // the header line
      Result[n].r := StrToFloat(Parts[1], FS);
      Inc(n);
    end;
    SetLength(Result, n);
  finally
    Lines.Free;
  end;
  Assert.IsTrue(Length(Result) > 1000, 'the reference curve is too short');
end;

function TTestMCPFitReport.FringeCurve(FringeStep, Depth: Double): TDataArray;
const
  TMin = 0.2;
  TMax = 3.0;
  Points = 2801;                      // a step of exactly 0.001 degrees
var
  i: Integer;
  T: Double;
begin
  SetLength(Result, Points);
  for i := 0 to Points - 1 do
  begin
    T := TMin + i * (TMax - TMin) / (Points - 1);
    Result[i].t := T;
    Result[i].r := Exp(-0.2 * T) *
      (1 + Depth * Cos(2 * Pi * (T - 0.9) / FringeStep));
  end;
end;

function TTestMCPFitReport.OrdersOf(Rep: TJSONObject): TJSONArray;
begin
  Assert.IsTrue(Rep.GetValue('orders') is TJSONArray, '"orders" is an array');
  Result := Rep.GetValue('orders') as TJSONArray;
end;

function TTestMCPFitReport.OrderN(Rep: TJSONObject; N: Integer): TJSONObject;
var
  Arr: TJSONArray;
  i: Integer;
begin
  Result := nil;
  Arr := OrdersOf(Rep);
  for i := 0 to Arr.Count - 1 do
    if (Arr.Items[i] as TJSONObject).GetValue<Integer>('n') = N then
      Exit(Arr.Items[i] as TJSONObject);
  Assert.Fail(Format('the report has no order %d', [N]));
end;

/// The input for one report over two curves.
function InputOf(const Meas, Calc: TDataArray; Period, ThetaC: Double): TFitReportInput;
begin
  Result := Default(TFitReportInput);
  Result.Measured := Meas;
  Result.Calculated := Calc;
  Result.Lambda := CU_K_ALPHA;
  Result.Period := Period;
  Result.ThetaC := ThetaC;
end;

{ ------------------------------------------------------------ background -- }

procedure TTestMCPFitReport.Background_IsTheMedianOfTheLastHundredPoints;
var
  C: TDataArray;
  i: Integer;
begin
  { 300 points: the first 200 are large, the last 100 run 1 .. 100, whose
    median is 50.5. Only the tail may count. }
  SetLength(C, 300);
  for i := 0 to 199 do
  begin
    C[i].t := i * 0.01;
    C[i].r := 1000;
  end;
  for i := 200 to 299 do
  begin
    C[i].t := i * 0.01;
    C[i].r := i - 199;
  end;
  Assert.AreEqual(Double(50.5), ReportBackground(C), 1E-9);
end;

procedure TTestMCPFitReport.Background_ShortCurve_UsesEveryPoint;
var
  C: TDataArray;
  i: Integer;
begin
  SetLength(C, 5);
  for i := 0 to 4 do
  begin
    C[i].t := i * 0.1;
    C[i].r := i + 1;                  // 1 2 3 4 5, median 3
  end;
  Assert.AreEqual(Double(3), ReportBackground(C), 1E-9);
end;

{ ------------------------------------------------------- the reference -- }

procedure TTestMCPFitReport.Reference_Orders_MatchTheOrchestratorsNumbers;
const
  { theta of the measured maximum, and R_calc / I_meas, per order. }
  Theta: array [1 .. 4] of Double = (0.9163, 1.7772, 2.6578, 3.5322);
  Ratio: array [1 .. 4] of Double = (0.98, 1.22, 1.09, 0.72);
var
  Rep: TJSONObject;
  O: TJSONObject;
  n: Integer;
begin
  Rep := FitReportJSON(InputOf(LoadReference('measured.dat'),
                               LoadReference('calc.dat'),
                               REF_PERIOD, REF_THETA_C));
  try
    Assert.AreEqual(4, OrdersOf(Rep).Count,
      'four orders of a 50.14 A period fit inside 0.21 to 4 degrees');
    for n := 1 to 4 do
    begin
      O := OrderN(Rep, n);
      Assert.AreEqual(Theta[n], O.GetValue<Double>('theta_meas_deg'), 1E-4,
        Format('order %d sits where the measured maximum is', [n]));
      Assert.AreEqual(Ratio[n], O.GetValue<Double>('ratio'), 0.005,
        Format('order %d calculated over measured', [n]));
    end;
  finally
    Rep.Free;
  end;
end;

procedure TTestMCPFitReport.Reference_Orders_AreTheSameWithAndWithoutRefraction;
var
  Meas, Calc: TDataArray;
  A, B: TJSONObject;
  n: Integer;
begin
  { The window is widened by the refraction shift, which moves a Bragg maximum
    up and never down. On this mirror the shift is small enough that the orders
    come out the same either way; the test is here so that a change to the
    window has to be a deliberate one. }
  Meas := LoadReference('measured.dat');
  Calc := LoadReference('calc.dat');
  A := FitReportJSON(InputOf(Meas, Calc, REF_PERIOD, REF_THETA_C));
  try
    B := FitReportJSON(InputOf(Meas, Calc, REF_PERIOD, 0));
    try
      Assert.AreEqual(OrdersOf(A).Count, OrdersOf(B).Count);
      for n := 1 to OrdersOf(A).Count do
        Assert.AreEqual(OrderN(A, n).GetValue<Double>('theta_meas_deg'),
                        OrderN(B, n).GetValue<Double>('theta_meas_deg'), 1E-9,
                        Format('order %d', [n]));
    finally
      B.Free;
    end;
  finally
    A.Free;
  end;
end;

procedure TTestMCPFitReport.Reference_EveryOrderIsVisible;
var
  Rep: TJSONObject;
  n: Integer;
begin
  Rep := FitReportJSON(InputOf(LoadReference('measured.dat'),
                               LoadReference('calc.dat'),
                               REF_PERIOD, REF_THETA_C));
  try
    for n := 1 to 4 do
      Assert.IsTrue(OrderN(Rep, n).GetValue<Boolean>('visible'),
        Format('order %d stands above the background of this scan', [n]));
  finally
    Rep.Free;
  end;
end;

procedure TTestMCPFitReport.Reference_BandsCoverTheRange;
var
  Rep: TJSONObject;
  Bands: TJSONArray;
  i, Total: Integer;
begin
  Rep := FitReportJSON(InputOf(LoadReference('measured.dat'),
                               LoadReference('calc.dat'),
                               REF_PERIOD, REF_THETA_C));
  try
    Bands := Rep.GetValue('bands') as TJSONArray;
    Assert.AreEqual(REPORT_BANDS, Bands.Count);
    Total := 0;
    for i := 0 to Bands.Count - 1 do
      Total := Total + (Bands.Items[i] as TJSONObject).GetValue<Integer>('n');
    Assert.AreEqual(Length(LoadReference('measured.dat')), Total,
      'every point of the curve lands in exactly one band');
  finally
    Rep.Free;
  end;
end;

{ ---------------------------------------------------------- the pieces -- }

procedure TTestMCPFitReport.Orders_NoPeriod_AreNull;
var
  C: TDataArray;
  Rep: TJSONObject;
begin
  C := FringeCurve(0.15);
  Rep := FitReportJSON(InputOf(C, C, 0, 0.3));
  try
    Assert.IsTrue(Rep.GetValue('orders') is TJSONNull,
      'without a repeating stack there are no orders to count');
    Assert.IsTrue(Rep.GetValue('fringes') is TJSONNull);
    Assert.IsTrue(Rep.GetValue('bands') is TJSONArray,
      'the residual by band does not need a period');
  finally
    Rep.Free;
  end;
end;

procedure TTestMCPFitReport.Orders_BelowTheBackground_AreNotVisible;
var
  Meas, Calc: TDataArray;
  Rep: TJSONObject;
  i: Integer;
begin
  { A flat measured curve: nothing anywhere stands three times above the
    median of its own tail, so no order is visible - and every order is still
    reported, which is the point. }
  Calc := FringeCurve(0.15);
  SetLength(Meas, Length(Calc));
  for i := 0 to High(Calc) do
  begin
    Meas[i].t := Calc[i].t;
    Meas[i].r := 1E-6;
  end;

  Rep := FitReportJSON(InputOf(Meas, Calc, REF_PERIOD_FRINGE, 0));
  try
    Assert.IsTrue(OrdersOf(Rep).Count >= 2, 'the orders are reported anyway');
    Assert.IsFalse(OrderN(Rep, 1).GetValue<Boolean>('visible'));
    Assert.IsFalse(OrderN(Rep, 2).GetValue<Boolean>('visible'));
  finally
    Rep.Free;
  end;
end;

procedure TTestMCPFitReport.Bands_ConstantRatio_IsTheSameInEveryBand;
var
  Meas, Calc: TDataArray;
  Rep: TJSONObject;
  Bands: TJSONArray;
  B: TJSONObject;
  i: Integer;
begin
  Meas := FringeCurve(0.15);
  Calc := FringeCurve(0.15);
  for i := 0 to High(Calc) do
    Calc[i].r := Calc[i].r * 10;      // one decade above the data everywhere

  Rep := FitReportJSON(InputOf(Meas, Calc, 0, 0));
  try
    Bands := Rep.GetValue('bands') as TJSONArray;
    Assert.AreEqual(REPORT_BANDS, Bands.Count);
    for i := 0 to Bands.Count - 1 do
    begin
      B := Bands.Items[i] as TJSONObject;
      Assert.AreEqual(Double(1), B.GetValue<Double>('mean'), 1E-9,
        Format('band %d mean log10(R/I)', [i]));
      Assert.AreEqual(Double(1), B.GetValue<Double>('rms'), 1E-9,
        Format('band %d rms', [i]));
    end;
  finally
    Rep.Free;
  end;
end;

procedure TTestMCPFitReport.Edge_HasThreePointsBeforeTheFirstMinimum;
var
  C: TDataArray;
  Rep, Edge, P: TJSONObject;
  Points: TJSONArray;
  i: Integer;
  FirstMin: Double;
begin
  C := FringeCurve(0.15);
  Rep := FitReportJSON(InputOf(C, C, 0, 0));
  try
    Assert.IsTrue(Rep.GetValue('edge') is TJSONObject, '"edge" is an object');
    Edge := Rep.GetValue('edge') as TJSONObject;
    FirstMin := Edge.GetValue<Double>('first_min_deg');
    Points := Edge.GetValue('points') as TJSONArray;
    Assert.AreEqual(REPORT_EDGE_POINTS, Points.Count);
    for i := 0 to Points.Count - 1 do
    begin
      P := Points.Items[i] as TJSONObject;
      Assert.IsTrue(P.GetValue<Double>('theta_deg') > C[0].t,
        'an edge point is past the start of the range');
      Assert.IsTrue(P.GetValue<Double>('theta_deg') < FirstMin,
        'an edge point is before the first minimum');
      Assert.AreEqual(Double(1), P.GetValue<Double>('ratio'), 1E-9,
        'the same curve twice agrees with itself');
    end;
  finally
    Rep.Free;
  end;
end;


{ CoC5's fitted curve: a plateau that dips 0.1 % at theta 0.207, between the
  C and Co critical angles, then the edge from 0.25 with fringes. The first
  minimum is the first fringe's, past the edge; the wiggle is not one (it
  took the whole edge window until 3.9.4). }
procedure TTestMCPFitReport.Edge_PlateauWiggleIsNotTheFirstMinimum;
var
  C: TDataArray;
  Rep, Edge, P: TJSONObject;
  Points: TJSONArray;
  i: Integer;
  T: Double;
begin
  SetLength(C, 267);
  for i := 0 to High(C) do
  begin
    T := 0.20225 + i * 0.0015;
    C[i].t := T;
    if T < 0.25 then
      C[i].r := 0.837 * (1 - 0.001 * Exp(-Sqr((T - 0.207) / 0.003)))
    else
      C[i].r := 0.837 * Exp(-(T - 0.25) * 20) *
                (1 + 0.3 * Sin(2 * Pi * (T - 0.25) / 0.04 - Pi / 2) + 0.3);
  end;
  Rep := FitReportJSON(InputOf(C, C, 0, 0));
  try
    Assert.IsTrue(Rep.GetValue('edge') is TJSONObject, '"edge" is an object');
    Edge := Rep.GetValue('edge') as TJSONObject;
    Assert.IsTrue(Edge.GetValue<Double>('first_min_deg') > 0.25,
      Format('the first minimum is past the edge: %.5f', [Edge.GetValue<Double>('first_min_deg')]));
    Points := Edge.GetValue('points') as TJSONArray;
    Assert.AreEqual(REPORT_EDGE_POINTS, Points.Count);
    for i := 1 to Points.Count - 1 do
    begin
      P := Points.Items[i] as TJSONObject;
      Assert.IsTrue(P.GetValue<Double>('theta_deg') >
        (Points.Items[i - 1] as TJSONObject).GetValue<Double>('theta_deg'),
        'three distinct edge points');
    end;
  finally
    Rep.Free;
  end;
end;

{ Maxima every 0.15 degrees from 0.9: the first two orders of REF_PERIOD_FRINGE
  are the ones at 0.9 and 1.8, and five secondary maxima - each with a minimum
  after it - lie between them. }
procedure TTestMCPFitReport.Fringes_PairEverySecondaryMaximumWithTheMinimumAfterIt;
var
  C: TDataArray;
  Rep, Fr, M, Pair: TJSONObject;
  Pairs: TJSONArray;
  i: Integer;
begin
  C := FringeCurve(0.15);
  Rep := FitReportJSON(InputOf(C, C, REF_PERIOD_FRINGE, 0));
  try
    Assert.AreEqual(Double(0.9), OrderN(Rep, 1).GetValue<Double>('theta_meas_deg'),
      0.002, 'the first order is the maximum at 0.9 degrees');
    Assert.AreEqual(Double(1.8), OrderN(Rep, 2).GetValue<Double>('theta_meas_deg'),
      0.002, 'the second order is the maximum at 1.8 degrees');

    Assert.IsTrue(Rep.GetValue('fringes') is TJSONObject);
    Fr := Rep.GetValue('fringes') as TJSONObject;
    Assert.AreEqual(5, Fr.GetValue<Integer>('count'),
      'five secondary maxima between the two orders');

    M := Fr.GetValue('measured') as TJSONObject;
    Pairs := M.GetValue('pairs') as TJSONArray;
    Assert.AreEqual(5, Pairs.Count);
    for i := 0 to Pairs.Count - 1 do
    begin
      Pair := Pairs.Items[i] as TJSONObject;
      Assert.AreEqual(Double(1.05 + i * 0.15),
        Pair.GetValue<Double>('theta_max_deg'), 0.003,
        Format('fringe %d sits on a maximum of the modulation', [i]));
      Assert.AreEqual(Pair.GetValue<Double>('theta_max_deg') + 0.075,
        Pair.GetValue<Double>('theta_min_deg'), 0.003,
        'the minimum that follows it is half a fringe further on');
      Assert.IsTrue(Pair.GetValue<Double>('i_max') >
                    Pair.GetValue<Double>('i_min'));
    end;
  finally
    Rep.Free;
  end;
end;

{ The curve runs from 1.5 to 0.5 of its envelope, so every fringe has a contrast
  of 3 (times the small drop of the envelope over half a fringe). The largest
  maximum of the stretch over its smallest minimum would be a different and much
  larger number, because the envelope falls across the whole stretch; the report
  must give the local one. }
procedure TTestMCPFitReport.Fringes_ContrastIsLocalAndNotTheFallBetweenTheOrders;
var
  C: TDataArray;
  Rep, Fr, M, First_, Last_: TJSONObject;
  Pairs: TJSONArray;
begin
  C := FringeCurve(0.15);
  Rep := FitReportJSON(InputOf(C, C, REF_PERIOD_FRINGE, 0));
  try
    Fr := Rep.GetValue('fringes') as TJSONObject;
    M := Fr.GetValue('measured') as TJSONObject;
    Pairs := M.GetValue('pairs') as TJSONArray;
    First_ := Pairs.Items[0] as TJSONObject;
    Last_ := Pairs.Items[Pairs.Count - 1] as TJSONObject;

    Assert.AreEqual(Double(3.045), First_.GetValue<Double>('contrast'), 0.02,
      'the first fringe stands three times above the minimum after it');
    Assert.AreEqual(Double(3.045), Last_.GetValue<Double>('contrast'), 0.02,
      'and so does the last, although it is a decade lower on the curve');
    Assert.AreEqual(Double(3.045), M.GetValue<Double>('mean_contrast'), 0.02,
      'the mean of the five is the same number');
  finally
    Rep.Free;
  end;
end;

{ What the resolution of the calculation is chosen by: the same fringes read off
  both curves. The calculated curve here is modulated 1.8 to 0.2 - a contrast of
  9 against the measured 3 - and the report has to show that difference at the
  same angles rather than compare two sets of extrema found separately. }
procedure TTestMCPFitReport.Fringes_BothCurvesAreReadAtTheSamePositions;
var
  Meas, Calc: TDataArray;
  Rep, Fr, M, Cc: TJSONObject;
  MP, CP: TJSONArray;
  i: Integer;
begin
  Meas := FringeCurve(0.15, 0.5);
  Calc := FringeCurve(0.15, 0.8);
  Rep := FitReportJSON(InputOf(Meas, Calc, REF_PERIOD_FRINGE, 0));
  try
    Fr := Rep.GetValue('fringes') as TJSONObject;
    M := Fr.GetValue('measured') as TJSONObject;
    Cc := Fr.GetValue('calculated') as TJSONObject;
    MP := M.GetValue('pairs') as TJSONArray;
    CP := Cc.GetValue('pairs') as TJSONArray;

    Assert.AreEqual(MP.Count, CP.Count, 'one pair per fringe on both curves');
    for i := 0 to MP.Count - 1 do
    begin
      Assert.AreEqual((MP.Items[i] as TJSONObject).GetValue<Double>('theta_max_deg'),
                      (CP.Items[i] as TJSONObject).GetValue<Double>('theta_max_deg'),
                      1E-12, 'the same angle on both curves');
      Assert.AreEqual((MP.Items[i] as TJSONObject).GetValue<Double>('theta_min_deg'),
                      (CP.Items[i] as TJSONObject).GetValue<Double>('theta_min_deg'),
                      1E-12);
    end;

    Assert.AreEqual(Double(3.045), M.GetValue<Double>('mean_contrast'), 0.02,
      'the measured fringes stand three times above their minima');
    Assert.AreEqual(Double(9.14), Cc.GetValue<Double>('mean_contrast'), 0.05,
      'the calculated ones nine times: the calculation is too sharp');
  finally
    Rep.Free;
  end;
end;

procedure TTestMCPFitReport.Fringes_OneOrderOnly_IsNull;
var
  C: TDataArray;
  Rep: TJSONObject;
begin
  { A period so long that only the first order falls inside the range. }
  C := FringeCurve(0.15);
  Rep := FitReportJSON(InputOf(C, C, 20, 0));
  try
    Assert.IsTrue(Rep.GetValue('fringes') is TJSONNull,
      'the fringes between orders 1 and 2 need both of them');
  finally
    Rep.Free;
  end;
end;

initialization

TDUnitX.RegisterTestFixture(TTestMCPFitReport);

end.
