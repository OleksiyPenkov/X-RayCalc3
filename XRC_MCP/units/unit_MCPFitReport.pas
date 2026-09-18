(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

unit unit_MCPFitReport;

(* The numbers a client needs to judge a fit, computed on the server.

   With points_inline_max at 0 a fit result carries no curves, and an agent with
   no file access used to rebuild the judgement by recomputing the fitted model
   with calc_reflectivity and reading peaks off two long lists in its context:
   about sixty thousand tokens per fit, and the step three rounds of agent fits
   got wrong. Everything here is what that reconstruction was for - the Bragg
   orders measured against calculated, the plateau edge, the fringe contrast,
   the residual by band - taken from the two curves the job already has.

   There is no verdict and no threshold anywhere in this unit. The fitting skill
   states what a good fit looks like; the server states what the numbers are.

   Two rules are worth saying out loud, because a search for maxima at large
   gets both of them wrong:

   - An order is looked for where the period says it must be, in the window
     unit_MCPCalc.BraggSearchWindow gives, and the largest point in that window
     is the order. There is no prominence test: an order that is not there is
     still reported, with "visible" false, because "the fourth order is in the
     noise" is exactly the kind of thing the client has to know.
   - The measured and the calculated maximum are located independently inside
     the same window, so that "the calculated peak sits 0.01 degrees below the
     measured one" survives into the report instead of being averaged away. *)

interface

uses
  System.JSON,
  unit_Types;

type
  /// <summary>The two curves a report is computed from and the model they
  /// belong to. Measured is the curve as it was fitted - scaled, smoothed and
  /// trimmed - and Calculated is one model's reflectivity on the same angles,
  /// so the two arrays run point for point.</summary>
  TFitReportInput = record
    Measured: unit_Types.TDataArray;
    Calculated: unit_Types.TDataArray;
    Lambda: Double;
    Period: Double;          // Angstrom; 0 when there is no repeating stack
    ThetaC: Double;          // critical angle in degrees, for the order window
  end;

const
  /// The fitting range is split into this many equal bands of theta.
  REPORT_BANDS = 8;
  /// The background is the median of the last this many fitted points.
  REPORT_BACKGROUND_POINTS = 100;
  /// An order counts as visible when it stands this far above the background.
  REPORT_VISIBLE_FACTOR = 3;
  /// Points reported between the start of the range and the first minimum.
  REPORT_EDGE_POINTS = 3;
  /// A fringe extremum is registered once the curve has turned back by this
  /// factor from the last one: a hysteresis that keeps the count of fringes
  /// from following the noise of a measured curve.
  REPORT_FRINGE_HYSTERESIS = 1.05;

/// <summary>The whole report: orders, edge, fringes, bands and the numbers they
/// are derived from. Caller frees. "orders" and "fringes" are null when the
/// structure has no repeating stack to give a period.</summary>
function FitReportJSON(const Inp: TFitReportInput): TJSONObject;

/// <summary>The median of the last REPORT_BACKGROUND_POINTS values of the
/// curve (all of them when it is shorter), which is what an order is called
/// visible against. 0 for an empty curve.</summary>
function ReportBackground(const C: unit_Types.TDataArray): Double;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections,
  unit_MCPErrors, unit_MCPCalc;

{ ------------------------------------------------------------- helpers -- }

/// A number, or JSON null when it cannot be formed (a ratio against zero, an
/// average of nothing). A null says "not computable here", where a 0 would be
/// read as a measurement.
function NumOrNull(Value: Double; Valid: Boolean): TJSONValue;
begin
  if Valid then
    Result := JSONArgs.Num(Value)
  else
    Result := TJSONNull.Create;
end;

function RatioOrNull(Num, Den: Double): TJSONValue;
begin
  if Den > 0 then
    Result := JSONArgs.Num(Num / Den)
  else
    Result := TJSONNull.Create;
end;

function ReportBackground(const C: unit_Types.TDataArray): Double;
var
  Tail: TArray<Double>;
  i, First, n: Integer;
begin
  Result := 0;
  n := Length(C);
  if n = 0 then
    Exit;

  First := Max(0, n - REPORT_BACKGROUND_POINTS);
  SetLength(Tail, n - First);
  for i := First to n - 1 do
    Tail[i - First] := C[i].r;
  TArray.Sort<Double>(Tail);

  n := Length(Tail);
  if Odd(n) then
    Result := Tail[n div 2]
  else
    Result := (Tail[n div 2 - 1] + Tail[n div 2]) / 2;
end;

/// Index of the point nearest Theta. -1 for an empty curve.
function NearestIndex(const C: unit_Types.TDataArray; Theta: Double): Integer;
var
  i: Integer;
  Best: Double;
begin
  Result := -1;
  Best := 0;
  for i := 0 to High(C) do
    if (Result < 0) or (Abs(C[i].t - Theta) < Best) then
    begin
      Result := i;
      Best := Abs(C[i].t - Theta);
    end;
end;

{ --------------------------------------------------------------- orders -- }

/// One order: where it should be, where the two curves put it, and how far
/// apart they are in height. Nil when the window holds no point of either curve.
function OrderJSON(const Inp: TFitReportInput; Order: Integer;
  Lo, Hi, Theta, Background: Double): TJSONObject;
var
  IM, IC: Integer;
begin
  Result := nil;
  IM := MaxIndexInRange(Inp.Measured, Lo, Hi);
  IC := MaxIndexInRange(Inp.Calculated, Lo, Hi);
  if (IM < 0) or (IC < 0) then
    Exit;

  Result := TJSONObject.Create;
  try
    Result.AddPair('n', TJSONNumber.Create(Order));
    Result.AddPair('theta_bragg_deg', JSONArgs.Num(Theta));
    Result.AddPair('window_deg', JSONArgs.NumArr(TArray<Double>.Create(Lo, Hi)));
    Result.AddPair('theta_meas_deg', JSONArgs.Num(Inp.Measured[IM].t));
    Result.AddPair('theta_calc_deg', JSONArgs.Num(Inp.Calculated[IC].t));
    Result.AddPair('i_meas', JSONArgs.Num(Inp.Measured[IM].r));
    Result.AddPair('r_calc', JSONArgs.Num(Inp.Calculated[IC].r));
    Result.AddPair('ratio', RatioOrNull(Inp.Calculated[IC].r, Inp.Measured[IM].r));
    Result.AddPair('visible',
      TJSONBool.Create(Inp.Measured[IM].r > REPORT_VISIBLE_FACTOR * Background));
  except
    Result.Free;
    raise;
  end;
end;

/// Every order of the period that falls inside the fitted range.
function OrdersJSON(const Inp: TFitReportInput; Background: Double): TJSONArray;
var
  Order: Integer;
  Lo, Hi, Theta, FirstT, LastT: Double;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    if (Inp.Period <= 0) or (Length(Inp.Measured) = 0) then
      Exit;

    FirstT := Inp.Measured[0].t;
    LastT := Inp.Measured[High(Inp.Measured)].t;

    Order := 1;
    while BraggSearchWindow(Order, Inp.Lambda, Inp.Period, Inp.ThetaC,
                            Lo, Hi, Theta) do
    begin
      if Theta > LastT then
        Break;
      if Theta >= FirstT then
      begin
        Obj := OrderJSON(Inp, Order, Lo, Hi, Theta, Background);
        if Obj <> nil then
          Result.AddElement(Obj);
      end;
      Inc(Order);
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ ----------------------------------------------------------------- edge -- }

/// The first minimum of the calculated curve: the foot of the plateau edge,
/// where the total-reflection region ends and the first fringe begins.
/// -1 when the curve only falls.
function FirstMinimumIndex(const C: unit_Types.TDataArray): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 1 to High(C) - 1 do
    if (C[i].r < C[i - 1].r) and (C[i].r <= C[i + 1].r) then
      Exit(i);
end;

/// Three points evenly spaced over the plateau edge - at a quarter, a half and
/// three quarters of the way from the start of the range to the first minimum -
/// with the measured and the calculated value at each. This is the stretch the
/// scale was chosen on, so a ratio far from 1 here says the normalisation is
/// wrong rather than the model.
function EdgeJSON(const Inp: TFitReportInput): TJSONValue;
var
  Obj, Point: TJSONObject;
  Points: TJSONArray;
  MinIdx, Idx, k: Integer;
  T0, T1, Theta: Double;
begin
  MinIdx := FirstMinimumIndex(Inp.Calculated);
  if (MinIdx < 1) or (Length(Inp.Measured) = 0) then
    Exit(TJSONNull.Create);

  T0 := Inp.Measured[0].t;
  T1 := Inp.Calculated[MinIdx].t;
  if T1 <= T0 then
    Exit(TJSONNull.Create);

  Obj := TJSONObject.Create;
  try
    Obj.AddPair('first_min_deg', JSONArgs.Num(T1));
    Points := TJSONArray.Create;
    Obj.AddPair('points', Points);

    for k := 1 to REPORT_EDGE_POINTS do
    begin
      Theta := T0 + (T1 - T0) * k / (REPORT_EDGE_POINTS + 1);
      Idx := NearestIndex(Inp.Measured, Theta);
      if (Idx < 0) or (Idx > High(Inp.Calculated)) then
        Continue;
      Point := TJSONObject.Create;
      Points.AddElement(Point);
      Point.AddPair('theta_deg', JSONArgs.Num(Inp.Measured[Idx].t));
      Point.AddPair('i_meas', JSONArgs.Num(Inp.Measured[Idx].r));
      Point.AddPair('r_calc', JSONArgs.Num(Inp.Calculated[Idx].r));
      Point.AddPair('ratio',
        RatioOrNull(Inp.Calculated[Idx].r, Inp.Measured[Idx].r));
    end;
    Result := Obj;
  except
    Obj.Free;
    raise;
  end;
end;

{ -------------------------------------------------------------- fringes -- }

type
  /// The secondary maxima and the minima between them over one stretch of a
  /// curve: how many, the largest maximum and the smallest minimum.
  TFringeStats = record
    Count: Integer;
    MaxOfMaxima, MinOfMinima: Double;
    HasMax, HasMin: Boolean;
  end;

/// Alternating extrema of C strictly between Lo and Hi, with a hysteresis: a
/// turn only counts once the curve has moved back by REPORT_FRINGE_HYSTERESIS
/// from the last extremum. Without it the count of fringes on a measured curve
/// is a count of its noise.
function FringeStatsOf(const C: unit_Types.TDataArray;
  Lo, Hi: Double): TFringeStats;
var
  i: Integer;
  Rising: Boolean;
  Extreme: Double;
  Stats: TFringeStats;

  procedure TakeMax(V: Double);
  begin
    Inc(Stats.Count);
    if (not Stats.HasMax) or (V > Stats.MaxOfMaxima) then
    begin
      Stats.MaxOfMaxima := V;
      Stats.HasMax := True;
    end;
  end;

  procedure TakeMin(V: Double);
  begin
    if (not Stats.HasMin) or (V < Stats.MinOfMinima) then
    begin
      Stats.MinOfMinima := V;
      Stats.HasMin := True;
    end;
  end;

begin
  Stats := Default(TFringeStats);
  Result := Stats;

  i := 0;
  while (i <= High(C)) and (C[i].t <= Lo) do
    Inc(i);
  if i > High(C) then
    Exit;

  { The stretch starts just past the first order, so the curve is falling. }
  Extreme := C[i].r;
  Rising := False;

  while (i <= High(C)) and (C[i].t < Hi) do
  begin
    if Rising then
    begin
      if C[i].r > Extreme then
        Extreme := C[i].r
      else if (C[i].r > 0) and (Extreme > REPORT_FRINGE_HYSTERESIS * C[i].r) then
      begin
        TakeMax(Extreme);
        Extreme := C[i].r;
        Rising := False;
      end;
    end
    else
    begin
      if C[i].r < Extreme then
        Extreme := C[i].r
      else if (Extreme > 0) and (C[i].r > REPORT_FRINGE_HYSTERESIS * Extreme) then
      begin
        TakeMin(Extreme);
        Extreme := C[i].r;
        Rising := True;
      end;
    end;
    Inc(i);
  end;

  Result := Stats;
end;

function FringeStatsJSON(const S: TFringeStats): TJSONObject;
begin
  Result := TJSONObject.Create;
  try
    Result.AddPair('count', TJSONNumber.Create(S.Count));
    Result.AddPair('max', NumOrNull(S.MaxOfMaxima, S.HasMax));
    Result.AddPair('min', NumOrNull(S.MinOfMinima, S.HasMin));
    if S.HasMax and S.HasMin and (S.MinOfMinima > 0) then
      Result.AddPair('contrast', JSONArgs.Num(S.MaxOfMaxima / S.MinOfMinima))
    else
      Result.AddPair('contrast', TJSONNull.Create);
  except
    Result.Free;
    raise;
  end;
end;

/// The fringes between the first and the second order, measured against
/// calculated. The stretch is bounded by the two measured order maxima, so both
/// curves are read over exactly the same angles. Null when the range does not
/// hold two orders.
function FringesJSON(const Inp: TFitReportInput; Orders: TJSONArray): TJSONValue;
var
  Obj: TJSONObject;
  Lo, Hi: Double;

  function ThetaOfOrder(N: Integer; out Theta: Double): Boolean;
  var
    k: Integer;
    O: TJSONObject;
  begin
    Result := False;
    Theta := 0;
    for k := 0 to Orders.Count - 1 do
      if Orders.Items[k] is TJSONObject then
      begin
        O := TJSONObject(Orders.Items[k]);
        if O.GetValue<Integer>('n') = N then
        begin
          Theta := O.GetValue<Double>('theta_meas_deg');
          Exit(True);
        end;
      end;
  end;

begin
  if (Orders = nil) or not (ThetaOfOrder(1, Lo) and ThetaOfOrder(2, Hi)) or
     (Hi <= Lo) then
    Exit(TJSONNull.Create);

  Obj := TJSONObject.Create;
  try
    Obj.AddPair('between_deg', JSONArgs.NumArr(TArray<Double>.Create(Lo, Hi)));
    Obj.AddPair('measured', FringeStatsJSON(FringeStatsOf(Inp.Measured, Lo, Hi)));
    Obj.AddPair('calculated',
      FringeStatsJSON(FringeStatsOf(Inp.Calculated, Lo, Hi)));
    Result := Obj;
  except
    Obj.Free;
    raise;
  end;
end;

{ ---------------------------------------------------------------- bands -- }

/// The fitting range in REPORT_BANDS equal bands of theta, each with the mean
/// and the rms of log10(R_calc / I_meas) over its points: where in angle the
/// model sits above the data and where below, in decades.
function BandsJSON(const Inp: TFitReportInput): TJSONArray;
var
  Sum, SumSq: array [0 .. REPORT_BANDS - 1] of Double;
  Count: array [0 .. REPORT_BANDS - 1] of Integer;
  i, b, n: Integer;
  T0, T1, Width, D: Double;
  Obj: TJSONObject;
begin
  Result := TJSONArray.Create;
  try
    n := Min(Length(Inp.Measured), Length(Inp.Calculated));
    if n < 1 then
      Exit;

    T0 := Inp.Measured[0].t;
    T1 := Inp.Measured[n - 1].t;
    if T1 <= T0 then
      Exit;
    Width := (T1 - T0) / REPORT_BANDS;

    for b := 0 to REPORT_BANDS - 1 do
    begin
      Sum[b] := 0;
      SumSq[b] := 0;
      Count[b] := 0;
    end;

    for i := 0 to n - 1 do
    begin
      if (Inp.Measured[i].r <= 0) or (Inp.Calculated[i].r <= 0) then
        Continue;
      b := Trunc((Inp.Measured[i].t - T0) / Width);
      b := EnsureRange(b, 0, REPORT_BANDS - 1);
      D := Log10(Inp.Calculated[i].r / Inp.Measured[i].r);
      Sum[b] := Sum[b] + D;
      SumSq[b] := SumSq[b] + D * D;
      Inc(Count[b]);
    end;

    for b := 0 to REPORT_BANDS - 1 do
    begin
      Obj := TJSONObject.Create;
      Result.AddElement(Obj);
      Obj.AddPair('theta_deg',
        JSONArgs.NumArr(TArray<Double>.Create(T0 + b * Width,
                                              T0 + (b + 1) * Width)));
      Obj.AddPair('n', TJSONNumber.Create(Count[b]));
      Obj.AddPair('mean', NumOrNull(Sum[b] / Max(1, Count[b]), Count[b] > 0));
      Obj.AddPair('rms',
        NumOrNull(Sqrt(SumSq[b] / Max(1, Count[b])), Count[b] > 0));
    end;
  except
    Result.Free;
    raise;
  end;
end;

{ --------------------------------------------------------------- report -- }

function FitReportJSON(const Inp: TFitReportInput): TJSONObject;
var
  Background: Double;
  Orders: TJSONArray;
begin
  Background := ReportBackground(Inp.Measured);

  Result := TJSONObject.Create;
  try
    Result.AddPair('period_A', JSONArgs.Num(Inp.Period));
    Result.AddPair('lambda', JSONArgs.Num(Inp.Lambda));
    Result.AddPair('critical_angle_deg', JSONArgs.Num(Inp.ThetaC));
    Result.AddPair('background', JSONArgs.Num(Background));

    if Inp.Period > 0 then
    begin
      Orders := OrdersJSON(Inp, Background);
      Result.AddPair('orders', Orders);
      Result.AddPair('fringes', FringesJSON(Inp, Orders));
    end
    else
    begin
      Result.AddPair('orders', TJSONNull.Create);
      Result.AddPair('fringes', TJSONNull.Create);
    end;

    Result.AddPair('edge', EdgeJSON(Inp));
    Result.AddPair('bands', BandsJSON(Inp));
  except
    Result.Free;
    raise;
  end;
end;

end.
