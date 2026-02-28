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

implementation

uses
  System.Math;

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

end.
