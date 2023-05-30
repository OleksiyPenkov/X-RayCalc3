unit unit_FitHelpers;

interface

uses
  unit_materials, unit_Types, unit_calc;

  // fitting
//  procedure AutoFit(const Inp:TFitPeriodicStructure; var Calc: TCalc);

  // models conversion

  function ExpandPeriodicFitModel(const Inp: TFitStructure): TLayeredModel;
  function SeedPeriodicModel(const Inp: TFitStructure): TFitStructure;

implementation

// Autofitting
// procedure AutoFit(const Inp:TFitPeriodicStructure; var Calc: TCalc);
//const
//  Population = 50;
//var
//  i: integer;
//  Models: array [0..(Population - 1)] of TFitPeriodicStructure;
//  MinChisqr: single;
//  Best: integer;
//begin
//  Randomize;
//  MinChisqr := 10000000;
//
//  Models[0] := Inp;
//  for I := 1 to High(Models) do
//     Models[i] := SeedPeriodicModel(Models[0]);
//
//
//  for I := 0 to High(Models) do
//  begin
//    Calc.Model := ExpandPeriodicFitModel(Models[i]);
//    Calc.Run;
//
//    Calc.CalcChiSquare();
//
//    if Calc.ChiSQR < MinChisqr then
//    begin
//      MinChisqr  := Calc.ChiSQR;
//      Best := i;
//    end;
//
//  end;
//  Calc.Model := ExpandPeriodicFitModel(Models[Best]);
//end;


  // models conversion

function ExpandPeriodicFitModel(const Inp: TFitStructure): TLayeredModel;
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
      Data[k].H := Inp.Stacks[i].Layers[k].H;
      Data[k].s := Inp.Stacks[i].Layers[k].s;
      Data[k].r := Inp.Stacks[i].Layers[k].r;
      Data[k].StackID := Inp.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := Inp.Stacks[i].Layers[k].LayerID;
    end;

    for j := 1  to Inp.Stacks[i].N do
      Result.AddLayers(-1, Data);
  end;

  SetLength(Data, 1);
  Data[0].Material := Inp.Subs.Material;
  Data[0].s := Inp.Subs.s;
  Data[0].r := Inp.Subs.r;

  Result.AddSubstrate(Data);
end;


function SeedPeriodicModel(const Inp: TFitStructure): TFitStructure;
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
