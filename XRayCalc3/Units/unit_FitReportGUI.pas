(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_FitReportGUI;

(* Result - Fit report: the input unit_MCPFitReport needs, built from what the
   GUI holds - the active model's calculated curve on the chart and the
   measured curve linked to it - and the fitted parameters that sit near a
   bound. No VCL here, so the tests can reach it.

   The report wants the two curves on the same angles, point for point, in
   theta. The chart's model curve is on the calculation grid, so it is
   resampled onto the measured angles (linear in log10 R between its two
   neighbours; measured points outside the calculated range are left out),
   and a 2theta chart is halved. The measured curve is taken at the solved
   scale of the last calculation, the one its chi2 and the Chart Info bar
   show, as fit_xrr's report does since 3.9.4. *)

interface

uses
  unit_Types, unit_MCPFitReport;

type
  /// <summary>A fitted parameter within NEAR_BOUND_FRACTION of its range of
  /// one end of it.</summary>
  TNearBound = record
    Stack: string;
    Layer: string;
    Param: Integer;          // 1..3: H, sigma, rho
    V, Min, Max: Single;
    AtUpper: Boolean;
  end;

/// <summary>The report input. Measured and Model are the chart's series in
/// its own unit (2theta when TwoTheta); ScaleLog is log10 of the solved
/// scale (0 = anchored).</summary>
function FitReportInput(const Measured, Model: TDataArray; TwoTheta: Boolean;
  ScaleLog, Lambda, Period, ThetaC: Double): TFitReportInput;

/// <summary>The period the report counts orders on: the first stack with
/// N &gt; 1, as fit_xrr's report takes it. 0 without one.</summary>
function FirstPeriod(const S: TFitStructure): Double;

/// <summary>Every free parameter of the layers within NEAR_BOUND_FRACTION of
/// its range of a bound, frozen and zero-width ones left out.</summary>
function NearBounds(const S: TFitStructure): TArray<TNearBound>;

implementation

uses
  System.Math, unit_SmartLimits;

function FitReportInput(const Measured, Model: TDataArray; TwoTheta: Boolean;
  ScaleLog, Lambda, Period, ThetaC: Double): TFitReportInput;
var
  i, j, n: Integer;
  K, Div2, X, F, L0, L1: Double;
begin
  Result := Default(TFitReportInput);
  Result.Lambda := Lambda;
  Result.Period := Period;
  Result.ThetaC := ThetaC;
  if (Length(Measured) = 0) or (Length(Model) < 2) then
    Exit;

  K := Power(10, ScaleLog);
  if TwoTheta then Div2 := 2 else Div2 := 1;

  SetLength(Result.Measured, Length(Measured));
  SetLength(Result.Calculated, Length(Measured));
  n := 0;
  j := 0;
  for i := 0 to High(Measured) do
  begin
    X := Measured[i].t;
    if (X < Model[0].t) or (X > Model[High(Model)].t) then
      Continue;
    while (j < High(Model) - 1) and (Model[j + 1].t < X) do
      Inc(j);
    if (Model[j].r <= 0) or (Model[j + 1].r <= 0) or (Model[j + 1].t <= Model[j].t) then
      Continue;
    F := (X - Model[j].t) / (Model[j + 1].t - Model[j].t);
    L0 := Log10(Model[j].r);
    L1 := Log10(Model[j + 1].r);

    Result.Measured[n].t := X / Div2;
    Result.Measured[n].r := Measured[i].r * K;
    Result.Calculated[n].t := X / Div2;
    Result.Calculated[n].r := Power(10, L0 + F * (L1 - L0));
    Inc(n);
  end;
  SetLength(Result.Measured, n);
  SetLength(Result.Calculated, n);
end;

function FirstPeriod(const S: TFitStructure): Double;
var
  i, j: Integer;
begin
  Result := 0;
  for i := 0 to High(S.Stacks) do
    if S.Stacks[i].N > 1 then
    begin
      for j := 0 to High(S.Stacks[i].Layers) do
        Result := Result + S.Stacks[i].Layers[j].P[1].V;
      Exit;
    end;
end;

function NearBounds(const S: TFitStructure): TArray<TNearBound>;
var
  i, j, p: Integer;
  Range: Single;
  NB: TNearBound;
begin
  Result := nil;
  for i := 0 to High(S.Stacks) do
    for j := 0 to High(S.Stacks[i].Layers) do
      for p := 1 to 3 do
        with S.Stacks[i].Layers[j].P[p] do
        begin
          Range := max - min;
          if Fixed or (Range <= 0) then
            Continue;
          NB.Stack := S.Stacks[i].Header;
          NB.Layer := S.Stacks[i].Layers[j].Material;
          NB.Param := p;
          NB.V := V;
          NB.Min := min;
          NB.Max := max;
          if (V - min) < NEAR_BOUND_FRACTION * Range then
          begin
            NB.AtUpper := False;
            Result := Result + [NB];
          end
          else if (max - V) < NEAR_BOUND_FRACTION * Range then
          begin
            NB.AtUpper := True;
            Result := Result + [NB];
          end;
        end;
end;

end.
