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
      Indexes: TIntArray;
      Counts: TIntArray;

      X, V : TPolyPopulation;
      Vmin, Vmax :  TPolyPopulation;   // solutions and velocityes
      pbest: TPolySolution; // best local solution
      gbest: TPolySolution; // best global solution
      abest: TPolySolution;

      function Poly(const N: Integer; const C: TFloatArray): Single;
      function GetPolyValues(const N: Integer; const C: TFloatArray): TFloatArray;

      procedure Seed; override;
      procedure Set_Init_XPoly(const N, Index, ValueType: Integer; const Paired: Boolean; Val: TFitValue);
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure InitVelocity; override;
      procedure FindTheBest; override;
      function BestStructure(best: TPolySolution): TFitStructure;
      procedure Run(CalcConditions: TCalcThreadParams); override;
      function GetResult: TLayeredModel; override;
      procedure UpdateLFPSO(const t: integer);  override;
      procedure UpdatePSO(const t: integer); override;
      procedure CheckLimits(const i, j, k: integer);override;
      function ExpandToModel(Solution: TPolySolution): TLayeredModel;
      function GetStructure: TFitStructure; override;
      procedure SetVelocityRanges;
      procedure Init_Domains; override;
      procedure SetDomainP(const Count: integer; var X: TPolyPopulation);
      procedure SetParams(const Value: TFitParams); override;
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
var
  OldX: TFloatArray;
   Val, Max, Min: Single;
   c, r: Integer;
begin
  for c := 0 to High(V[i][j][k]) do
  begin
    if V[i][j][k][c] > Vmax[0][j][k][c] then
               V[i][j][k][c] := Vmax[0][j][k][c];

    if V[i][j][k][0] < Vmin[0][j][k][c] then
               V[i][j][k][0] := Vmin[0][j][k][c];

    X[i][j][k][c] := X[i][j][k][c] + V[i][j][k][c]
  end;

  Max := 0; Min := 1E9;

  for r := 1 to Counts[j] do
  begin
    Val := Poly(r, X[i][j][k]);
    if Val > Max then
       Max := Val;
    if Val < Min then
       Min := Val;
  end;

  if Max > Xmax[0][Indexes[j]][k] then
  begin
    X[i][j][k][0] := Xmax[0][Indexes[j]][k];
    for c := 1 to High (X[i][j][k]) do
      X[i][j][k][c] := 0;
  end;

  if Min < Xmin[0][Indexes[j]][k] then
  begin
    X[i][j][k][0] := Xmin[0][Indexes[j]][k];
    for c := 1 to High (X[i][j][k]) do
      X[i][j][k][c] := 0;
  end;
end;

procedure TLFPSO_Poly.UpdateLFPSO(const t: integer);
var
  i, j, k,c: integer;
  c1, c2, Val: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do       // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do        // for H, s, rho
      begin
        for c := 0 to High(X[I][j][k]) do  // for every coefficient
        begin
          V[i][j][k][c] := Omega(t, FTMax) * LevyWalk(X[i][j][k][c], gbest[j][k][c])  +
                        c1 * Random * (pbest[j][k][c] - X[i][j][k][c]) +
                        c2 * Random * (gbest[j][k][c] - X[i][j][k][c]);
        end;
        CheckLimits(i, j, k);
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
      for k := 1 to 3 do
      begin
        for c := 0 to High(X[I][j][k]) do  // for every coefficient
        begin
            V[i][j][k][c] := Omega(t, FTMax) * V[i][j][k][c]  +
                      c1 * Random * (pbest[j][k][c] - X[i][j][k][c]) +
                      c2 * Random * (gbest[j][k][c] - X[i][j][k][c]);

        end;
        CheckLimits(i, j, k);
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
      if Result.Stacks[i].Layers[j].H.Paired then
            Result.Stacks[i].Layers[j].H.V := best[LayerIndex][1][0]
      else begin
         Result.Stacks[i].Layers[j].PH := GetPolyValues(Result.Stacks[i].N, best[LayerIndex][1]);
         Result.Stacks[i].Layers[j].H.V := Result.Stacks[i].Layers[j].PH[0];
      end;

      if Result.Stacks[i].Layers[j].s.Paired then
            Result.Stacks[i].Layers[j].s.V := best[LayerIndex][2][0]
      else begin
         Result.Stacks[i].Layers[j].PS := GetPolyValues(Result.Stacks[i].N, best[LayerIndex][2]);
         Result.Stacks[i].Layers[j].s.V := Result.Stacks[i].Layers[j].PS[0];
      end;

      if Result.Stacks[i].Layers[j].r.Paired then
         Result.Stacks[i].Layers[j].r.V := best[LayerIndex][3][0]
      else begin
         Result.Stacks[i].Layers[j].PR := GetPolyValues(Result.Stacks[i].N, best[LayerIndex][3]);
         Result.Stacks[i].Layers[j].r.V := Result.Stacks[i].Layers[j].PR[0];
      end;

      Inc(LayerIndex);
    end;
  end;
end;

function TLFPSO_Poly.ExpandToModel(Solution: TPolySolution): TLayeredModel;
var
  i, k, j: Integer;
  Data: TLayersData;
  LayerIndex: Integer;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  LayerIndex := 0;
  SetLength(Data, FStructure.TotalNP);

  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 1 to FStructure.Stacks[i].N do
      for k := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        Data[LayerIndex].Material := FStructure.Stacks[i].Layers[k].Material;
        Data[LayerIndex].H := FStructure.Stacks[i].Layers[k].H;
        Data[LayerIndex].H.V := Poly(j, Solution[k][1]);

        Data[LayerIndex].s := FStructure.Stacks[i].Layers[k].s;
//        Data[LayerIndex].s.V := Poly(j, Solution[k][2]);

        Data[LayerIndex].r := FStructure.Stacks[i].Layers[k].r;
//        Data[LayerIndex].r.V := Poly(j, Solution[k][3]);

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

function TLFPSO_Poly.GetPolyValues(const N: Integer; const C: TFloatArray): TFloatArray;
var
  i: Integer;
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
    Result[i] := Poly(i + 1, C);
end;

function TLFPSO_Poly.GetResult: TLayeredModel;
begin
  Result := ExpandToModel(pbest);
end;

function TLFPSO_Poly.GetStructure: TFitStructure;
begin
  Result := BestStructure(pbest);
end;

procedure TLFPSO_Poly.SetVelocityRanges;
var
  i, j, k, c: integer;
begin
  for I := 0 to High(Vmax) do                  // for every member of the population
    for j := 0 to High(Vmax[i]) do             // for every layer
      for k := 1 to 3 do                       // for H, s, rho
        for c := 0 to High(Vmax[i][j][k]) do
        begin
           Vmax[i][j][k][c] := Xrange[0][j][k] * FFitParams.Vmax;
           Vmin[i][j][k][c] := - Vmax[i][j][k][c];
        end;
end;

procedure TLFPSO_Poly.InitVelocity;
var
  i, j, k, p: integer;
begin
  SetVelocityRanges;

  for i := 0 to High(V) do          // for every member of the population
    for j := 0 to High(V[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        for p := 0 to High(V[i][j][k]) do
          V[i][j][k][p] := (Random * (Vmax[0][j][k][p]- Vmin[0][j][k][p]) + Vmin[0][j][k][p])/(p + 1);
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
  Val: Single;
begin
  for i := 0 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do
      begin           // for H, s, rho
        for p := 0 to High(X[i][j][k]) do
        begin
          Val := Random * (Xmax[0][Indexes[j]][k] - Xmin[0][Indexes[j]][k]) / sqr(p + 1);
          X[i][j][k][p] := Xmin[0][Indexes[j]][k] + Val;   // min + Random * (min-max)
        end;
        CheckLimits(i, j, k);
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

  SetLength(Indexes, FStructure.TotalNP);
  SetLength(Counts, FStructure.TotalNP);
  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
      FStructure.Stacks[0].Layers[Index] := Inp.Stacks[i].Layers[j];

      Set_Init_XPoly(Inp.Stacks[i].N, Index, 1, Inp.Stacks[i].Layers[j].H.Paired, Inp.Stacks[i].Layers[j].H);
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 2, Inp.Stacks[i].Layers[j].s.Paired, Inp.Stacks[i].Layers[j].s);
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 3, Inp.Stacks[i].Layers[j].r.Paired, Inp.Stacks[i].Layers[j].r);
      Inc(Index);
    end;
  end;

  Index := 0;
  for I := 0 to High(FStructure.Stacks) do
    for j := 1 to FStructure.Stacks[i].N do
      for k := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        Indexes[Index] := k;
        Counts[Index]  := FStructure.Stacks[i].N;
        Inc(Index);
      end;

  for I := 1 to FPopulation - 1 do
    for j := 0 to High(X[i]) do
      for k := 1 to 3 do
      begin
        SetLength(X[i][j][k], Length(X[0][j][k]));   // not periodic layer, only a0 = v
        SetLength(V[i][j][k], Length(X[0][j][k]));
        SetLength(Vmin[i][j][k], Length(X[0][j][k]));
        SetLength(Vmax[i][j][k], Length(X[0][j][k]));
      end
end;

procedure TLFPSO_Poly.Set_Init_XPoly(const N, Index, ValueType: Integer; const Paired: Boolean; Val: TFitValue);
begin
  if Paired or (N = 1) then
  begin
    SetLength(X[0][Index][ValueType], 1);   // not periodic layer, only a0 = v
    SetLength(V[0][Index][ValueType], 1);
    SetLength(Vmin[0][Index][ValueType], 1);
    SetLength(Vmax[0][Index][ValueType], 1);
  end
  else begin
    SetLength(X[0][Index][ValueType], FFitParams.MaxPOrder + 1); // init array of a0..aN
    SetLength(V[0][Index][ValueType], FFitParams.MaxPOrder + 1);
    SetLength(Vmin[0][Index][ValueType], FFitParams.MaxPOrder + 1);
    SetLength(Vmax[0][Index][ValueType], FFitParams.MaxPOrder + 1);
  end;

    X[0][Index][ValueType][0] := Val.V;
    Xmax[0][Index][ValueType] := Val.max;
    Xmin[0][Index][ValueType] := Val.min;
  Xrange[0][Index][ValueType] := Xmax[0][Index][ValueType] - Xmin[0][Index][ValueType];
end;

procedure TLFPSO_Poly.Init_Domains;
begin
  SetDomainP(FLayersCount, X);
  SetDomain(FLayersCount, Xmax);
  SetDomain(FLayersCount, Xmin);
  SetDomain(FLayersCount, Xrange);
  SetDomainP(FLayersCount, Vmin);
  SetDomainP(FLayersCount, Vmax);
  SetDomainP(FLayersCount, V);
end;

procedure TLFPSO_Poly.SetDomainP(const Count: integer; var X: TPolyPopulation);
var
  i, j, k: integer;
begin
  SetLength(X, FPopulation);
  for I := 0 to High(X) do
    SetLength(X[i], Count);
end;

procedure TLFPSO_Poly.SetParams(const Value: TFitParams);
begin
  FFitParams := Value;

  FTMax := FFitParams.NMax;
  FPopulation := FFitParams.Pop;

  SetLength(X, FPopulation);
  SetLength(V, FPopulation);

  SetLength(Xmax, 1);
  SetLength(Xmin, 1);
  SetLength(Vmax, 1);
  SetLength(Vmin, 1);
  SetLength(Xrange, 1);
end;

end.
