unit unit_LFPSO_Poly;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TPolyLayer = array [1..3] of TFloatArray; //
  TPolySolution = array of TPolyLayer;
  TPolyPopulation = array of TPolySolution;

  TLFPSO_Poly = class (TLFPSO_BASE)
    private

      X, V : TPolyPopulation;  // solutions and velocityes
      pbest: TPolySolution; // best local solution
      gbest: TPolySolution; // best global solution
      abest: TPolySolution;

      function Poly(const N: Integer; const C: TFloatArray): Single;

      procedure Seed; override;
      procedure Set_Init_XPoly(const N, Index, ValueType: Integer; Val: TFitValue);
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure InitVelocity; override;
      procedure FindTheBest; override;
      function XtoStructure(const Index: integer): TFitStructure; override;
      function BestStructure(best: TPolySolution): TFitStructure;
      procedure Run(CalcConditions: TCalcThreadParams); override;
      function GetResult: TLayeredModel; override;
      function GetStructure: TFitStructure; override;
      procedure UpdateLFPSO(const t: integer);  override;
      procedure UpdatePSO(const t: integer); override;
      procedure CheckLimits(const i, j, k: integer);override;
      function ExpandToModel(Solution: TPolySolution): TLayeredModel;
    public
      //
  end;

implementation

uses
  Forms,
  System.SysUtils,
  Neslib.FastMath,
  unit_helpers,
  Dialogs;

{ TLFPSO Polynomial}

procedure TLFPSO_Poly.CheckLimits(const i, j, k: integer);
begin
//  if V[i][j][k] > Vmax[0][j][k] then
//             V[i][j][k] := Vmax[0][j][k];
//
//  if V[i][j][k] < Vmin[0][j][k] then
//             V[i][j][k] := Vmin[0][j][k];

//  X[i][j][k] := X[i][j][k] + V[i][j][k];

//  if X[i][j][k] > Xmax[0][j][k] then
//             X[i][j][k] := Xmax[0][j][k];
//
//  if X[i][j][k] < Xmin[0][j][k] then
//             X[i][j][k] := Xmin[0][j][k];
end;

procedure TLFPSO_Poly.UpdateLFPSO(const t: integer);
var
  i, j, k,c: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
        for c := 0 to High(X[I][j][k]) do
        begin // for every coefficient
          V[i][j][k][c] := Omega(t, FTMax) * LevyWalk(X[i][j][k][c], gbest[j][k][c])  +
                        c1 * Random * (pbest[j][k][c] - X[i][j][k][c]) +
                        c2 * Random * (gbest[j][k][c] - X[i][j][k][c]);

          X[i][j][k][c] := X[i][j][k][c] + V[i][j][k][c];
        end;

  end;
end;

procedure TLFPSO_Poly.UpdatePSO(const t: integer);
var
  i, j, k, c: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
        for c := 0 to High(X[I][j][k]) do  // for every coefficient
        begin
            V[i][j][k][c] := Omega(t, FTMax) * V[i][j][k][c]  +
                      c1 * Random * (pbest[j][k][c] - X[i][j][k][c]) +
                      c2 * Random * (gbest[j][k][c] - X[i][j][k][c]);

          X[i][j][k][c] := X[i][j][k][c] + V[i][j][k][c];
        end;
  end;
end;

procedure TLFPSO_Poly.Run;
var
  t: integer;
  switch: double;
  ReInitCount: integer;
  Vmax0: single;
  SuccessCount: integer;
begin
  Randomize;

  FReInit := False;
  FTerminated := False;
  Vmax0 := FFitParams.Vmax ;
  ReInitCount := 0;
  SuccessCount := 0;
  FGlobalBestChiSqr:= 1e12;
  FAbsoluteBestChiSqr := 1e12;
  FCalcParams := CalcConditions;
  SetLength(FMaterials, 0);

  ReInit(0);

  for t := 1 to FTMax do
  begin
    if FTerminated then Break;

    switch := Random;
    if switch < 0.5 then
      UpdatePSO(SuccessCount)
    else
      UpdateLFPSO(SuccessCount);

    FindTheBest;
    SendUpdateMessage(t);
    if FGlobalBestChiSqr < FFitParams.Tolerance then Break;

    if FFitParams.Shake and (FJammingCount > FFitParams.JammingMax) then
    begin
      FReInit := True;
      if ReInitCount > FFitParams.ReInitMax then
      begin
        ReInitCount := 0;
        SetStructure(BestStructure(abest));
        gbest := abest;
        FGlobalBestChiSqr := FAbsoluteBestChiSqr;
        FFitParams.Vmax := Vmax0;
      end
      else
      begin
        SetStructure(BestStructure(gbest));
        FGlobalBestChiSqr := FGlobalBestChiSqr  * FFitParams.KChiSqr;
        FFitParams.Vmax := FFitParams.Vmax * FFitParams.KVmax;
      end;
      ReInit(t);
      Inc(ReInitCount);
      FJammingCount := 0;
      dec(SuccessCount);
    end
    else begin
      abest := gbest;
      inc(SuccessCount);
    end;
  end;
end;

function TLFPSO_Poly.XtoStructure(const Index: integer): TFitStructure;
var
  i, j, LayerIndex: integer;
begin
  Result := FStructure;

  LayerIndex := 0;
  for i := 0 to High(Result.Stacks) do
  begin
    for j := 0 to High(Result.Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[j].H.V := Poly(j + 1, X[Index][LayerIndex][1]);
      Result.Stacks[i].Layers[j].s.V := Poly(j + 1, X[Index][LayerIndex][2]);
      Result.Stacks[i].Layers[j].r.V := Poly(j + 1, X[Index][LayerIndex][3]);
      Inc(LayerIndex);
    end;
  end;
end;

function TLFPSO_Poly.BestStructure(best: TPolySolution): TFitStructure;
var
  i, j, LayerIndex: integer;
begin
  Result := FStructure;
  LayerIndex := 0;
  for i := 0 to High(Result.Stacks) do
  begin
    for j := 0 to High(Result.Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[j].H.V := Poly(j + 1, best[LayerIndex][1]);

      Result.Stacks[i].Layers[j].s.V := Poly(j + 1, best[LayerIndex][2]);
      Result.Stacks[i].Layers[j].r.V := Poly(j + 1, best[LayerIndex][3]);
      Inc(LayerIndex);
    end;
  end;
end;

function TLFPSO_Poly.ExpandToModel(Solution: TPolySolution): TLayeredModel;
var
  i, k, j: Integer;
  Data: TLayersData;
  LayerIndex: Integer;
  Total: Integer;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  Total := FStructure.TotalNP;
  LayerIndex := 0;
  SetLength(Data, Total);
  for I := 0 to High(FStructure.Stacks) do
  begin

    for j := 1 to FStructure.Stacks[i].N do
      for k := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        Data[LayerIndex].Material := FStructure.Stacks[i].Layers[k].Material;
        Data[LayerIndex].H.V := Poly(k + 1, Solution[k][1]);

        Data[LayerIndex].s := FStructure.Stacks[i].Layers[k].s;
        Data[LayerIndex].s.V := Poly(k + 1, Solution[k][2]);

        Data[LayerIndex].r := FStructure.Stacks[i].Layers[k].r;
        Data[LayerIndex].r.V := Poly(k + 1, Solution[k][3]);

        Data[LayerIndex].StackID := FStructure.Stacks[i].Layers[k].StackID;
        Data[LayerIndex].LayerID := FStructure.Stacks[i].Layers[k].LayerID;
        Inc(LayerIndex);
      end;
  end;
  Result.AddLayers(-1, Data);

  //
  SetLength(Data, 1);
  Data[0].Material := FStructure.Subs.Material;
  Data[0].s := FStructure.Subs.s;
  Data[0].r := FStructure.Subs.r;

  Result.AddSubstrate(Data);
end;

procedure TLFPSO_Poly.FindTheBest;
var
  i, Result: integer;
  Calc: TCalc;
begin
  FLastBestChiSqr  := 1e12;
  FLastWorseChiSQR := 0;

  for i := 0 to High(X) do
  begin
    if FTerminated then Break;
    try
      Calc := TCalc.Create;
      Calc.Params    := FCalcParams;
      Calc.ExpValues := FData;
      Calc.MovAvg    := FMovAvg;
      Calc.Limit     := FLimit;

      Calc.Model := ExpandToModel(X[i]);
      Calc.Model.Materials := FMaterials;
      Calc.Run;
      Calc.CalcChiSquare(FFitParams.ThetaWieght);

      if Calc.ChiSQR < FLastBestChiSqr then
      begin
        FLastBestChiSqr  := Calc.ChiSQR;
        FResultingCurve := Calc.Results;
        Result := i;
      end;

      if Calc.ChiSQR > FLastWorseChiSQR then
        FLastWorseChiSQR :=  Calc.ChiSQR;
    finally
      FreeAndNil(Calc);
      Application.ProcessMessages;
    end;
  end;

  pbest := X[Result];

  if FLastBestChiSqr <  FGlobalBestChiSqr then
  begin
    FGlobalBestChiSqr := FLastBestChiSqr;
    gbest := X[Result];
  end
  else begin
    SetLength(FResultingCurve, 0);
    Inc(FJammingCount);
  end;

  if FGlobalBestChiSqr < FAbsoluteBestChiSqr  then
  begin
    FAbsoluteBestChiSqr := FGlobalBestChiSqr;
    abest := X[Result];
  end;

  CFactor := eps + (FLastBestChiSqr - FAbsoluteBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr);

end;

function TLFPSO_Poly.GetResult: TLayeredModel;
begin
  Result := ExpandToModel(abest);
end;

function TLFPSO_Poly.GetStructure: TFitStructure;
begin
  Result := BestStructure(abest);
end;

procedure TLFPSO_Poly.InitVelocity;
var
  i, j, k, p: integer;
begin
  MultiplyVector(Xrange, FFitParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do          // for every member of the population
    for j := 0 to High(V[i]) do     //for every layer
      for k := 1 to 3 do
      begin            // for H, s, rho
        V[i][j][k][0] := Random * (Vmax[0][j][k] - Vmin[0][j][k]) + Vmin[0][j][k];
        for p := 1 to High(V[i][j][k]) do
          V[i][j][k][p] := V[i][j][k][p - 1] / 10;
      end;
end;

function TLFPSO_Poly.Poly(const N: Integer; const C: TFloatArray): Single;
var
  i, Last: Integer;
begin
  Result := C[0]; Last := 1;
  for I := 1 to High(C) do
  begin
    Last := Last * N;
    Result := Result + C[i] * Last
  end;
end;

procedure TLFPSO_Poly.Seed;
var
  i, j, k, p: integer;
begin
  for i := 0 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do
      begin           // for H, s, rho
        X[i][j][k][0] := Xmin[0][j][k] + Random * (Xmax[0][j][k] - Xmin[0][j][k]);   // min + Random * (min-max)
        for p := 1 to High(X[i][j][k]) do
          X[i][j][k][p] := 0;
      end;
  end;
end;

procedure TLFPSO_Poly.SetStructure(const Inp: TFitStructure);
var
  i, j, k, Index: integer;
  D: double;
  NLayers: Integer;
begin
  FStructure := Inp;
  FLayersCount := Inp.Total;

  Init_Domains;

  SetLength(X, FPopulation);
  SetLength(V, FPopulation);

  for I := 0 to FPopulation - 1 do
  begin
    SetLength(X[i], FLayersCount);
    SetLength(V[i], FLayersCount);
  end;

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
      FStructure.Stacks[0].Layers[Index] := Inp.Stacks[i].Layers[j];

      Set_Init_XPoly(Inp.Stacks[i].N, Index, 1, Inp.Stacks[i].Layers[j].H);
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 2, Inp.Stacks[i].Layers[j].s);
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 3, Inp.Stacks[i].Layers[j].r);
      Inc(Index);
    end;
  end;

  for I := 1 to FPopulation - 1 do
    for j := 0 to High(X[i]) do
      for k := 1 to 3 do
      begin
        SetLength(X[i][j][k], Length(X[0][j][k]));   // not periodic layer, only a0 = v
        SetLength(V[i][j][k], Length(X[0][j][k]));
      end
end;

procedure TLFPSO_Poly.Set_Init_XPoly(const N, Index, ValueType: Integer; Val: TFitValue);
begin
  if N = 1 then
  begin
    SetLength(X[0][Index][ValueType], 1);   // not periodic layer, only a0 = v
    SetLength(V[0][Index][ValueType], 1);
  end
  else begin
    SetLength(X[0][Index][ValueType], FFitParams.MaxPOrder); // init array of a0..aN
    SetLength(V[0][Index][ValueType], FFitParams.MaxPOrder);
  end;

    X[0][Index][ValueType][0] := Val.V;
    Xmax[0][Index][ValueType] := Val.max;
    Xmin[0][Index][ValueType] := Val.min;
  Xrange[0][Index][ValueType] := Xmax[0][Index][ValueType] - Xmin[0][Index][ValueType];
end;

end.
