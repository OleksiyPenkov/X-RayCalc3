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

unit unit_LogPosterior;

(* The log-posterior of one curve (spec section 2): a vector goes through the map to a
   structure, the structure to a model, the model through TCalc to R on the
   measured angles, and R through CurveLikelihood. The prior term is added on
   top; Cost = likelihood cost + prior term is what the optimiser minimises and
   what phase B's sampler will turn into ln p = -Cost / 2 + const.

   Evaluate is called from several threads at once: every call gets the
   Calc and Model of its own thread and works on its own copy of the
   structure. It never calls Random.

   TLogPosterior is theta-mode (cmTheta) only: First/Last assume the DT*K
   convolution TCalc.CalcChiSquare sums over, and cmLambda convolves with DW
   instead - a different half-window this class does not compute. Create
   raises for any other TCalcThreadParams.Mode. *)

interface

uses
  unit_Types, unit_materials, unit_calc, unit_Likelihood, unit_ParamMap;

const
  /// The score of a vector outside the posterior's support. Below the 1e12
  /// TLFPSO_BASE.EvaluateOnCpu starts every worker's best at, so the
  /// reduction still works when a whole worker saw nothing feasible.
  /// A FEASIBLE vector's cost can exceed this value too - a poor candidate
  /// well inside the support can still score arbitrarily high - so this
  /// constant alone never tells a caller whether a vector was in bounds.
  INFEASIBLE_COST = 1E10;

type
  TPosteriorTerms = record
    /// False when Theta was outside TParamMap's support (Apply returned
    /// False): Cost is then exactly INFEASIBLE_COST and Likelihood,
    /// PriorTerm and Nuisance are not meaningful. True never bounds Cost from
    /// above - see INFEASIBLE_COST. Callers, phase B's sampler among them,
    /// must decide ln p = -infinity from Feasible, never by comparing Cost
    /// against INFEASIBLE_COST or any other threshold.
    Feasible: Boolean;
    Likelihood: TLikelihoodTerms;
    PriorTerm: Double;
    Cost: Double;
    Nuisance: TNuisance;
  end;

  TLogPosterior = class
  private
    FMap: TParamMap;
    FData: TDataArray;
    FCounts: TArray<Double>;
    FCalcParams: TCalcThreadParams;
    FRMin, FNMin: Double;
    FFirst, FLast: Integer;
  public
    constructor Create(AMap: TParamMap; const AData: TDataArray;
      const ACounts: TArray<Double>; const ACalcParams: TCalcThreadParams;
      ARMin, ANMin: Double);
    function NewCalc: TCalc;
    function Evaluate(Calc: TCalc; Model: TLayeredModel; const Theta: array of Double;
      out Curve: TDataArray): TPosteriorTerms;
    function EvaluateOnce(const Theta: array of Double; out Curve: TDataArray): TPosteriorTerms;
    property Map: TParamMap read FMap;
    property Data: TDataArray read FData;
    property Counts: TArray<Double> read FCounts;
    property CalcParams: TCalcThreadParams read FCalcParams;
    property RMin: Double read FRMin;
    property NMin: Double read FNMin;
    property First: Integer read FFirst;
    property Last: Integer read FLast;
  end;

/// <summary>The expanded model of S: every stack repeated N times, then the
/// substrate. A layer value with a per-period table (TLayerData.PeriodValue:
/// a repeating stack, not paired, the table covering all N periods) takes its
/// own value in every period, period 1 at the surface; a stack without one is
/// built as TLFPSO_BASE.FillModel builds it.</summary>
procedure FillLayeredModel(Model: TLayeredModel; const S: TFitStructure);

implementation

uses
  System.SysUtils, unit_LFPSO_Base;

procedure FillLayeredModel(Model: TLayeredModel; const S: TFitStructure);
var
  i, j, k, p, StackLen, MaxStackLen: Integer;
  Data: TLayersData;
  Tabled: Boolean;
begin
  MaxStackLen := 1;
  for i := 0 to High(S.Stacks) do
    if Length(S.Stacks[i].Layers) > MaxStackLen then
      MaxStackLen := Length(S.Stacks[i].Layers);
  if Length(Model.FillScratch) < MaxStackLen then
    SetLength(Model.FillScratch, MaxStackLen);
  Data := Model.FillScratch;

  for i := 0 to High(S.Stacks) do
  begin
    StackLen := Length(S.Stacks[i].Layers);
    Tabled := False;
    for k := 0 to StackLen - 1 do
    begin
      SetMaterial(Data[k], S.Stacks[i].Layers[k].Material);
      for p := 1 to 3 do
      begin
        Data[k].P[p].V := S.Stacks[i].Layers[k].P[p].V;
        if (S.Stacks[i].N > 1) and not S.Stacks[i].Layers[k].P[p].Paired and
           (Length(S.Stacks[i].Layers[k].PP[p]) >= S.Stacks[i].N) then
          Tabled := True;
      end;
      Data[k].StackID := S.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := S.Stacks[i].Layers[k].LayerID;
    end;
    for j := 1 to S.Stacks[i].N do
    begin
      if Tabled then
        for k := 0 to StackLen - 1 do
          for p := 1 to 3 do
            Data[k].P[p].V := S.Stacks[i].Layers[k].PeriodValue(p, j, S.Stacks[i].N, True);
      Model.AddLayers(-1, Data, StackLen);
    end;
  end;

  SetMaterial(Data[0], S.Subs.Material);
  Data[0].P := S.Subs.P;
  Model.AddSubstrate(Data);    // reads Data[0] only
end;

constructor TLogPosterior.Create(AMap: TParamMap; const AData: TDataArray;
  const ACounts: TArray<Double>; const ACalcParams: TCalcThreadParams;
  ARMin, ANMin: Double);
var
  Width: Single;
  N: Integer;
begin
  inherited Create;
  if ACalcParams.Mode <> cmTheta then
    raise Exception.Create('TLogPosterior.Create: CalcParams.Mode must be ' +
      'cmTheta - First/Last assume the DT*K convolution, and cmLambda ' +
      'convolves with DW instead');
  if (Length(ACounts) > 0) and (Length(ACounts) <> Length(AData)) then
    raise Exception.CreateFmt('%d counts for %d points', [Length(ACounts), Length(AData)]);
  FMap := AMap;
  FData := Copy(AData);
  FCounts := Copy(ACounts);
  FCalcParams := ACalcParams;
  FRMin := ARMin;
  FNMin := ANMin;
  { The points TCalc.CalcChiSquare sums: the convolution half-window is left
    out at both ends (the last ones are a moving average, not a convolution). }
  Width := FCalcParams.DT * FCalcParams.K;
  N := 0;
  if Width > 0 then
    ConvolutionWeights(FData[0].t, FData[High(FData)].t, Length(FData), Width, N);
  FFirst := N;
  FLast := High(FData) - N;
end;

function TLogPosterior.NewCalc: TCalc;
begin
  Result := TCalc.Create;
  Result.MaxThreads := 1;
  Result.Params := FCalcParams;
  Result.ExpValues := FData;
  Result.Limit := FRMin;
end;

function TLogPosterior.Evaluate(Calc: TCalc; Model: TLayeredModel;
  const Theta: array of Double; out Curve: TDataArray): TPosteriorTerms;
var
  S: TFitStructure;
begin
  Result := Default(TPosteriorTerms);
  Curve := nil;
  FMap.Template.CopyContent(S);
  if not FMap.Apply(Theta, S, Result.Nuisance) then
  begin
    Result.Cost := INFEASIBLE_COST;
    Exit;
  end;
  Result.Feasible := True;
  Model.Reset;
  FillLayeredModel(Model, S);
  Calc.Model := Model;
  Calc.Run;
  Curve := Copy(Calc.Results);
  Result.Likelihood := CurveLikelihood(FData, Curve, FCounts, FFirst, FLast, FNMin,
    Result.Nuisance, FMap.FMin);
  Result.PriorTerm := FMap.PriorTerm(Theta, S);
  Result.Cost := Result.Likelihood.Cost + Result.PriorTerm;
end;

function TLogPosterior.EvaluateOnce(const Theta: array of Double;
  out Curve: TDataArray): TPosteriorTerms;
var
  Calc: TCalc;
  Model: TLayeredModel;
begin
  Model := TLayeredModel.Create;
  try
    Model.Init;
    Calc := NewCalc;
    try
      Result := Evaluate(Calc, Model, Theta, Curve);
    finally
      Calc.Model := nil;      // TCalc.Destroy frees its model; this one is ours
      Calc.Free;
    end;
  finally
    Model.Free;
  end;
end;

end.
