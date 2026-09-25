(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_Residuals;

(* The residual strip under the main chart: log10(R_calc / (I_meas K)) at each
   measured point, from the same report input the Fit report is computed from
   (unit_FitReportGUI.FitReportInput: the model resampled onto the measured
   angles, the measured curve at the solved scale), so the strip, the report
   and chi2 agree. The bands are the report's own (ReportBands). No VCL here,
   so the tests can reach it. *)

interface

uses
  unit_MCPFitReport;

const
  /// A model point within this factor of R min is taken to sit on the floor.
  FLOOR_MARGIN = 1.01;
  /// A measured point this close above R min, relative, counts as on it.
  MEASURED_FLOOR_TOL = 1E-5;

type
  TResidualPoint = record
    X: Double;          // the chart's unit: 2theta on a 2theta chart
    D: Double;          // log10(R_calc / (I_meas K))
    Floored: Boolean;   // the model on the R min floor, or I_meas K at or below it
  end;

  TResidualCurve = record
    Points: TArray<TResidualPoint>;
    Bands: TArray<TReportBand>;   // edges in the chart's unit
  end;

/// <summary>The residual of the report input Inp (theta, measured already at
/// the solved scale). TwoTheta doubles the angles back to the chart's unit.
/// Points where either curve is not positive are left out, as the report's
/// bands leave them out.</summary>
function ResidualCurve(const Inp: TFitReportInput; TwoTheta: Boolean;
  RMin: Double): TResidualCurve;

implementation

uses
  System.Math;

function ResidualCurve(const Inp: TFitReportInput; TwoTheta: Boolean;
  RMin: Double): TResidualCurve;
var
  i, n, Count: Integer;
  Mul, Meas, Calc: Double;
begin
  Result := Default(TResidualCurve);
  if TwoTheta then Mul := 2 else Mul := 1;

  n := Min(Length(Inp.Measured), Length(Inp.Calculated));
  SetLength(Result.Points, n);
  Count := 0;
  for i := 0 to n - 1 do
  begin
    Meas := Inp.Measured[i].r;
    Calc := Inp.Calculated[i].r;
    if (Meas <= 0) or (Calc <= 0) then
      Continue;
    Result.Points[Count].X := Inp.Measured[i].t * Mul;
    Result.Points[Count].D := Log10(Inp.Calculated[i].r / Inp.Measured[i].r);  // as ReportBands
    { A measured point typed in at R min is a Single, a rounding step off the
      Single R min; the margin (as AboveFloor's) keeps "at" meaning at. }
    Result.Points[Count].Floored := (Calc <= RMin * FLOOR_MARGIN) or
                                    (Meas <= RMin * (1 + MEASURED_FLOOR_TOL));
    Inc(Count);
  end;
  SetLength(Result.Points, Count);

  Result.Bands := ReportBands(Inp);
  for i := 0 to High(Result.Bands) do
  begin
    Result.Bands[i].Theta0 := Result.Bands[i].Theta0 * Mul;
    Result.Bands[i].Theta1 := Result.Bands[i].Theta1 * Mul;
  end;
end;

end.
