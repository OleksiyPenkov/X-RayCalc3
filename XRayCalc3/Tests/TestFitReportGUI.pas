unit TestFitReportGUI;

(* Result - Fit report: the input unit_FitReportGUI builds from the chart's two
   curves - resampled onto the measured angles, halved on a 2theta chart, the
   measured curve at the solved scale - and the near-bound list. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Math, System.JSON,
  unit_Types, unit_MCPFitReport, unit_FitReportGUI;

type
  [TestFixture]
  TTestFitReportGUI = class
  public
    [Test] procedure Input_ResamplesTheModelOntoTheMeasuredAngles;
    [Test] procedure Input_HalvesA2ThetaChart_AndAppliesTheScale;
    [Test] procedure Input_LeavesOutPointsTheModelDoesNotCover;
    [Test] procedure Report_OnIdenticalCurves_OrdersRatioIsOne;
    [Test] procedure FirstPeriod_IsTheFirstRepeatingStack;
    [Test] procedure NearBounds_FivePercent_FrozenLeftOut;
  end;

implementation

function Curve(const T, R: array of Double): TDataArray;
var
  i: Integer;
begin
  SetLength(Result, Length(T));
  for i := 0 to High(T) do
  begin
    Result[i].t := T[i];
    Result[i].r := R[i];
  end;
end;

procedure TTestFitReportGUI.Input_ResamplesTheModelOntoTheMeasuredAngles;
var
  Inp: TFitReportInput;
begin
  { log-linear: halfway between 1E-2 and 1E-4 is 1E-3 }
  Inp := FitReportInput(Curve([1.0, 1.5], [0.5, 0.5]), Curve([1.0, 2.0], [1E-2, 1E-4]),
    False, 0, 1.5406, 0, 0);
  Assert.AreEqual(2, Integer(Length(Inp.Calculated)));
  Assert.AreEqual(1E-2, Double(Inp.Calculated[0].r), 1E-8);
  Assert.AreEqual(1E-3, Double(Inp.Calculated[1].r), 1E-8);
  Assert.AreEqual(Double(Inp.Measured[1].t), Double(Inp.Calculated[1].t), 0, 'point for point');
end;

procedure TTestFitReportGUI.Input_HalvesA2ThetaChart_AndAppliesTheScale;
var
  Inp: TFitReportInput;
begin
  Inp := FitReportInput(Curve([2.0], [0.4]), Curve([1.0, 3.0], [1, 1]),
    True, Log10(1.25), 1.5406, 0, 0);
  Assert.AreEqual(1, Integer(Length(Inp.Measured)));
  Assert.AreEqual(1.0, Double(Inp.Measured[0].t), 1E-9, '2theta 2.0 is theta 1.0');
  Assert.AreEqual(0.5, Double(Inp.Measured[0].r), 1E-6, 'measured x the solved scale 1.25');
end;

procedure TTestFitReportGUI.Input_LeavesOutPointsTheModelDoesNotCover;
var
  Inp: TFitReportInput;
begin
  Inp := FitReportInput(Curve([0.5, 1.0, 2.0, 3.5], [1, 1, 1, 1]),
    Curve([1.0, 3.0], [1, 1]), False, 0, 1.5406, 0, 0);
  Assert.AreEqual(2, Integer(Length(Inp.Measured)), 'only 1.0 and 2.0 lie inside 1.0-3.0');
  Assert.AreEqual(1.0, Double(Inp.Measured[0].t), 1E-9);
  Assert.AreEqual(2.0, Double(Inp.Measured[1].t), 1E-9);
end;

{ The same curve as data and model: every order's calc/meas is 1. A Bragg
  peak of a 50 A period at 1.5406 A sits near theta 0.88 deg. }
procedure TTestFitReportGUI.Report_OnIdenticalCurves_OrdersRatioIsOne;
var
  C: TDataArray;
  Inp: TFitReportInput;
  Rep: TJSONObject;
  Orders: TJSONArray;
  i: Integer;
  T, ThetaB: Double;
begin
  SetLength(C, 1000);
  ThetaB := RadToDeg(ArcSin(1.5406 / (2 * 50)));
  for i := 0 to High(C) do
  begin
    T := 0.3 + i * 0.002;
    C[i].t := T;
    C[i].r := 1E-4 + 1E-2 * Exp(-Sqr((T - ThetaB) / 0.01));
  end;
  Inp := FitReportInput(C, C, False, 0, 1.5406, 50, 0.2);
  Rep := FitReportJSON(Inp);
  try
    Orders := Rep.GetValue('orders') as TJSONArray;
    Assert.IsTrue(Orders.Count >= 1, 'order 1 is in the range');
    Assert.AreEqual(1.0, (Orders.Items[0] as TJSONObject).GetValue<Double>('ratio'), 1E-4);
  finally
    Rep.Free;
  end;
end;

procedure TTestFitReportGUI.FirstPeriod_IsTheFirstRepeatingStack;
var
  S: TFitStructure;
begin
  SetLength(S.Stacks, 3);
  S.Stacks[0].N := 1;
  SetLength(S.Stacks[0].Layers, 1);
  S.Stacks[0].Layers[0].P[1].V := 30;
  S.Stacks[1].N := 20;
  SetLength(S.Stacks[1].Layers, 2);
  S.Stacks[1].Layers[0].P[1].V := 18.8;
  S.Stacks[1].Layers[1].P[1].V := 31.2;
  S.Stacks[2].N := 5;
  SetLength(S.Stacks[2].Layers, 1);
  S.Stacks[2].Layers[0].P[1].V := 99;
  Assert.AreEqual(50.0, FirstPeriod(S), 1E-4);
end;

procedure TTestFitReportGUI.NearBounds_FivePercent_FrozenLeftOut;
var
  S: TFitStructure;
  NB: TArray<TNearBound>;
  p: Integer;
begin
  SetLength(S.Stacks, 1);
  S.Stacks[0].Header := 'ML';
  S.Stacks[0].N := 10;
  SetLength(S.Stacks[0].Layers, 1);
  S.Stacks[0].Layers[0].Material := 'Co';
  for p := 1 to 3 do
  begin
    S.Stacks[0].Layers[0].P[p].min := 0;
    S.Stacks[0].Layers[0].P[p].max := 10;
    S.Stacks[0].Layers[0].P[p].V := 5;
  end;
  S.Stacks[0].Layers[0].P[1].V := 9.7;        // 3 % from max
  S.Stacks[0].Layers[0].P[2].V := 0.2;        // 2 % from min, but frozen
  S.Stacks[0].Layers[0].P[2].Fixed := True;
  S.Stacks[0].Layers[0].P[3].V := 0.4;        // 4 % from min

  NB := NearBounds(S);
  Assert.AreEqual(2, Integer(Length(NB)));
  Assert.AreEqual(1, NB[0].Param);
  Assert.IsTrue(NB[0].AtUpper);
  Assert.AreEqual('Co', NB[0].Layer);
  Assert.AreEqual(3, NB[1].Param);
  Assert.IsFalse(NB[1].AtUpper);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFitReportGUI);

end.
