unit unit_ProfileCalc;

interface

uses
  unit_Types;

type
  TPLayer = record
    h, s, r: Single;
  end;

  TStackData = record
    N: Integer;
    Layers: TLayersData;
  end;
  TStacksData = array of TStackData;

  TDensityPoint = record
    Depth, Value: Single;
  end;

function Erf(const sigma, xmax: Single): Single;

/// The value parameter ValIdx (1 = H, 2 = sigma, 3 = rho) of layer LayerIdx
/// takes in period PeriodIdx (from 1) of stack StackIdx in the calculated model.
/// TXRCStructure.Model(ExpandTables) sets it from the table or the layer's value
/// (TLayerData.PeriodValue), then TLayeredModel.PrepareLayers replaces it with
/// every gradient in Profiles aimed at (StackIdx, LayerIdx, ValIdx) in turn -
/// Poly of the period number counted in its own stack - so the last one wins.
/// Every profile plot reads its values here.
function ModelValue(const Stacks: TStacksData; const Profiles: TProfileFunctions;
  StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer; ExpandTables: Boolean): Single;

/// The layers of the depth profile, surface first, with the values of
/// ModelValue, so the plot shows the structure that is calculated. ExpandTables
/// is TfrmProjectPanel.IsNonPeriodicProfile; Profiles the model's gradient
/// extensions (TfrmProjectPanel.GetProfileFunctions).
function BuildLayers(const Stacks: TStacksData; ExpandTables: Boolean;
  const Profiles: TProfileFunctions = nil): TArray<TPLayer>;

function CalcDensityProfile(const Layers: TArray<TPLayer>): TArray<TDensityPoint>;

implementation

uses
  System.Math, math_globals;

function Erf(const sigma, xmax: Single): Single;
const
  dx = 0.05;
var
  x, i, pow: Single;
begin
  x := -sigma;
  i := 0;
  while x < xmax / (sigma / 1.77) do
  begin
    Pow := -1 * Sqr(x);
    i := i + dx * Exp(Pow);
    x := x + dx;
  end;
  Result := 1 / Sqrt(Pi) * i;
end;

function ModelValue(const Stacks: TStacksData; const Profiles: TProfileFunctions;
  StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer; ExpandTables: Boolean): Single;
var
  g: Integer;
begin
  Result := Stacks[StackIdx].Layers[LayerIdx].PeriodValue(ValIdx, PeriodIdx,
              Stacks[StackIdx].N, ExpandTables);
  for g := 0 to High(Profiles) do
    if (Integer(Profiles[g].StackID) = StackIdx) and (Integer(Profiles[g].LayerID) = LayerIdx) and
       (Integer(Profiles[g].PIndex) = ValIdx) and (Length(Profiles[g].C) > 0) then
      Result := Poly(PeriodIdx, Profiles[g]);
end;

function BuildLayers(const Stacks: TStacksData; ExpandTables: Boolean;
  const Profiles: TProfileFunctions): TArray<TPLayer>;
var
  StackIdx, LayerIdx, PeriodIdx: Integer;
  Layer: TPLayer;
begin
  Result := nil;
  for StackIdx := 0 to High(Stacks) do
    for PeriodIdx := 1 to Stacks[StackIdx].N do
      for LayerIdx := 0 to High(Stacks[StackIdx].Layers) do
      begin
        Layer.h := ModelValue(Stacks, Profiles, StackIdx, LayerIdx, PeriodIdx, 1, ExpandTables);
        Layer.s := ModelValue(Stacks, Profiles, StackIdx, LayerIdx, PeriodIdx, 2, ExpandTables);
        Layer.r := ModelValue(Stacks, Profiles, StackIdx, LayerIdx, PeriodIdx, 3, ExpandTables);
        Result := Result + [Layer];
      end;
end;

function CalcDensityProfile(const Layers: TArray<TPLayer>): TArray<TDensityPoint>;
var
  InLayerDepth, Depth, Val, s, rho, scale, EndDepth: Single;
  i: Integer;
  Pt: TDensityPoint;
begin
  Result := nil;
  if Length(Layers) = 0 then Exit;

  Depth := 0;
  for i := 0 to High(Layers) do
  begin
    s := Layers[i].s;
    if i = 0 then
    begin
      Depth := -s;
      rho := 0;
      scale := -Layers[i].r;
      if Length(Layers) > 1 then
        EndDepth := Layers[0].h - Layers[1].s
      else
        EndDepth := Layers[0].h;
    end
    else begin
      if Layers[i].s > Layers[i].h / 2 then
        s := Layers[i].h / 2;
      rho := Layers[i - 1].r;
      scale := rho - Layers[i].r;
      if i < High(Layers) then
        EndDepth := Layers[i].h - Layers[i + 1].s
      else
        EndDepth := Layers[i].h;
    end;

    InLayerDepth := -s;
    while InLayerDepth < EndDepth do
    begin
      InLayerDepth := InLayerDepth + 0.1;
      Depth := Depth + 0.1;
      if s > 0 then
        Val := rho - scale * Erf(s, InLayerDepth)
      else
        Val := rho;

      Pt.Depth := Depth;
      Pt.Value := Val;
      Result := Result + [Pt];
    end;
  end;
end;

end.
