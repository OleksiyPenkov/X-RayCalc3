(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_Likelihood;

(* The likelihood of one measured curve against one model curve (spec section 2).

     M_i   = 10^LogScale * R_i + Background
     r_i   = ln D_i - ln M_i                 (natural log - never unit_calc.Log10,
                                              which is half of log10)
     s_i^2 = 1/N_i + f^2                     (f^2 alone without counts)
     -2 ln L = sum (r_i^2 / s_i^2 + ln s_i^2)   (the 2 pi constant left out)

   Points with a count below NMin (or not positive) are left out and counted.
   Cost is -2 ln L minus the constant sum ln(1/N_i + FMin^2): it differs from
   -2 ln L only by a number that does not depend on any parameter, and it is
   never negative, which the LFPSO's shake (it multiplies the best score by
   KChiSqr > 1) and its tolerance stop both need. *)

interface

uses
  unit_Types;

type
  /// <summary>The nuisance parameters of one curve.</summary>
  TNuisance = record
    LogScale: Double;    // log10 of the factor on the model curve
    Background: Double;  // added after scaling, in the units of the measured curve
    F: Double;           // model-error floor, relative (a standard deviation in ln I)
  end;

  TLikelihoodTerms = record
    Cost: Double;            // what the optimiser minimises; >= 0
    Minus2LnL: Double;
    Chi2Data: Double;        // sum r^2 / s^2
    PointsUsed: Integer;
    PointsExcluded: Integer; // counts below NMin, non-positive counts or data
  end;

/// <summary>The terms over points First..Last. Counts is empty when the curve
/// has none, otherwise one raw detector count per point of Data. Data and
/// Model are on the same angles. Preconditions: Model r > 0, Background >= 0,
/// Nuis.F >= FMin > 0.</summary>
function CurveLikelihood(const Data, Model: TDataArray; const Counts: TArray<Double>;
  First, Last: Integer; NMin: Double; const Nuis: TNuisance; FMin: Double): TLikelihoodTerms;

/// <summary>The one rule for which points the likelihood keeps: a count, when
/// the curve has counts, that is positive and at least NMin (a NaN count
/// fails both), and a positive intensity.</summary>
function PointUsed(const Data: TDataArray; const Counts: TArray<Double>; i: Integer;
  NMin: Double): Boolean;

/// <summary>Minus2LnL - Cost of CurveLikelihood for any nuisance: the constant
/// sum ln(1/N_i + FMin^2) over the points used (ln FMin^2 without counts).</summary>
function LikelihoodCostOffset(const Data: TDataArray; const Counts: TArray<Double>;
  First, Last: Integer; NMin, FMin: Double): Double;

/// <summary>M = 10^LogScale * R + Background, on R's angles.</summary>
function ScaledModel(const R: TDataArray; const Nuis: TNuisance): TDataArray;

implementation

uses
  System.Math;

/// <summary>M = S * R + Background: the one place the scale/background model
/// is written, shared by CurveLikelihood (per point, in the fit's hot loop -
/// no array allocation) and ScaledModel (for display/reporting).</summary>
function ModelIntensity(R, S, Background: Double): Double; inline;
begin
  Result := S * R + Background;
end;

function CurveLikelihood(const Data, Model: TDataArray; const Counts: TArray<Double>;
  First, Last: Integer; NMin: Double; const Nuis: TNuisance; FMin: Double): TLikelihoodTerms;
var
  i: Integer;
  S, F2, FMin2, M, Res, V, VMin: Double;
  HasCounts: Boolean;
begin
  Result := Default(TLikelihoodTerms);
  HasCounts := Length(Counts) > 0;
  S := Power(10, Nuis.LogScale);
  F2 := Sqr(Nuis.F);
  FMin2 := Sqr(FMin);
  for i := First to Last do
  begin
    if not PointUsed(Data, Counts, i, NMin) then
    begin
      Inc(Result.PointsExcluded);
      Continue;
    end;
    M := ModelIntensity(Model[i].r, S, Nuis.Background);
    Res := Ln(Data[i].r) - Ln(M);
    if HasCounts then
    begin
      V := 1 / Counts[i] + F2;
      VMin := 1 / Counts[i] + FMin2;
    end
    else
    begin
      V := F2;
      VMin := FMin2;
    end;
    Result.Chi2Data := Result.Chi2Data + Sqr(Res) / V;
    Result.Minus2LnL := Result.Minus2LnL + Sqr(Res) / V + Ln(V);
    Result.Cost := Result.Cost + Sqr(Res) / V + Ln(V / VMin);
    Inc(Result.PointsUsed);
  end;
end;

function PointUsed(const Data: TDataArray; const Counts: TArray<Double>; i: Integer;
  NMin: Double): Boolean;
begin
  { Positive form, as before: a NaN count must fall through to "left out".
    NaN compares False against every side of (> 0) and (>= NMin) alike, so
    testing the condition that KEEPS a point - then excluding what fails it -
    is what makes a NaN count fall through to excluded rather than through
    both negated comparisons back into "used". }
  if (Length(Counts) > 0) and not ((Counts[i] > 0) and (Counts[i] >= NMin)) then
    Exit(False);
  Result := Data[i].r > 0;
end;

function LikelihoodCostOffset(const Data: TDataArray; const Counts: TArray<Double>;
  First, Last: Integer; NMin, FMin: Double): Double;
var
  i: Integer;
  FMin2: Double;
begin
  Result := 0;
  FMin2 := Sqr(FMin);
  for i := First to Last do
    if PointUsed(Data, Counts, i, NMin) then
    begin
      if Length(Counts) > 0 then
        Result := Result + Ln(1 / Counts[i] + FMin2)
      else
        Result := Result + Ln(FMin2);
    end;
end;

function ScaledModel(const R: TDataArray; const Nuis: TNuisance): TDataArray;
var
  i: Integer;
  S: Double;
begin
  S := Power(10, Nuis.LogScale);
  SetLength(Result, Length(R));
  for i := 0 to High(R) do
  begin
    Result[i].t := R[i].t;
    Result[i].r := ModelIntensity(R[i].r, S, Nuis.Background);
  end;
end;

end.
