unit unit_FitHelpers;

interface

uses
  unit_materials, unit_Types;


  // models conversion

  function ExpandPeriodicFitModel(const Inp: TFitPeriodicStructure): TLayeredModel;
  function SeedPeriodicModel(const Inp: TFitPeriodicStructure): TFitPeriodicStructure;

implementation

function ExpandPeriodicFitModel(const Inp: TFitPeriodicStructure): TLayeredModel;
var
  i, k, j: Integer;
  Data: TLayersData;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  for I := 0 to High(Inp.Stacks) do
  begin
    SetLength(Data, Length(Inp.Stacks[i].Layers));
    for k := 0 to High(Inp.Stacks[i].Layers) do
    begin
      Data[k].Material := Inp.Stacks[i].Layers[k].Material;
      Data[k].H := Inp.Stacks[i].Layers[k].H.V;
      Data[k].s := Inp.Stacks[i].Layers[k].s.V;
      Data[k].r := Inp.Stacks[i].Layers[k].r.V;
    end;


    for j := 0  to Inp.Stacks[i].N do
      Result.AddLayers(j, Data);
  end;

  SetLength(Data, 1);
  Data[0].Material := Inp.Subs.Material;
  Data[0].s := Inp.Subs.s.V;
  Data[0].r := Inp.Subs.r.V;

  Result.AddSubstrate(Data);
end;


function SeedPeriodicModel(const Inp: TFitPeriodicStructure): TFitPeriodicStructure;
var
  i, k, j: Integer;
  D, HMax: single;
begin
  Result := Inp;

  for I := 0 to High(Result.Stacks) do
  begin
    D := 0;  HMax := 0;
    for k := 0 to High(Result.Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[k].H.Seed;
      if Result.Stacks[i].Layers[k].H.V > HMax then
       j := k; // keep the index of thickest layer

      D := D + Result.Stacks[i].Layers[k].H.V;
      Result.Stacks[i].Layers[k].s.Seed;
      Result.Stacks[i].Layers[k].r.Seed;

    end;

    if Result.Stacks[i].N > 1 then         // correction to keep D of the stack constant
    begin
      // apply to thickest layer in the stack
      Result.Stacks[i].Layers[j].H.V := Result.Stacks[i].Layers[j].H.V + (Result.Stacks[i].D - D);
    end;
  end;

end;

end.
