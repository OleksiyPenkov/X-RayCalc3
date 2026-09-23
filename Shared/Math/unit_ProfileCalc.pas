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

function GetLayerVal(const Stacks: TStacksData;
  StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer): Single;

/// The layers of the depth profile, surface first. Profiles are the model's
/// gradient extensions (TfrmProjectPanel.GetProfileFunctions); each replaces its
/// parameter as TLayeredModel.PrepareLayers does - Poly of the period number
/// counted from 1 in its own stack - so the plot shows the structure that is
/// calculated. Without them every period takes the layer's value or its table.
function BuildLayers(const Stacks: TStacksData;
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

function GetLayerVal(const Stacks: TStacksData;
  StackIdx, LayerIdx, PeriodIdx, ValIdx: Integer): Single;
begin
  if Length(Stacks[StackIdx].Layers[LayerIdx].PP[ValIdx]) > 1 then
    Result := Stacks[StackIdx].Layers[LayerIdx].PP[ValIdx][PeriodIdx - 1]
  else
    Result := Stacks[StackIdx].Layers[LayerIdx].P[ValIdx].V;
end;

function BuildLayers(const Stacks: TStacksData;
  const Profiles: TProfileFunctions): TArray<TPLayer>;
var
  StackIdx, LayerIdx, PeriodIdx: Integer;
  Layer: TPLayer;

  // The last matching gradient wins, as it does in PrepareLayers.
  function Value(ValIdx: Integer): Single;
  var
    g: Integer;
  begin
    Result := GetLayerVal(Stacks, StackIdx, LayerIdx, PeriodIdx, ValIdx);
    for g := 0 to High(Profiles) do
      if (Integer(Profiles[g].StackID) = StackIdx) and (Integer(Profiles[g].LayerID) = LayerIdx) and
         (Integer(Profiles[g].PIndex) = ValIdx) and (Length(Profiles[g].C) > 0) then
        Result := Poly(PeriodIdx, Profiles[g]);
  end;

begin
  Result := nil;
  for StackIdx := 0 to High(Stacks) do
    for PeriodIdx := 1 to Stacks[StackIdx].N do
      for LayerIdx := 0 to High(Stacks[StackIdx].Layers) do
      begin
        Layer.h := Value(1);
        Layer.s := Value(2);
        Layer.r := Value(3);
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
