unit unit_LFPSO_Poly;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Poly = class (TLFPSO_BASE)
    private
      Indexes: TIntArray;
      Counts: TIntArray;

      function Poly(const x: Integer; const C: TFloatArray): Single;

      procedure CheckLimits(const i, j, k: integer); override;
      procedure UpdateLFPSO(const t: integer); override;
      procedure Seed; override;
      procedure ReSeed; override;
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
      procedure Set_Init_XPoly(const N, Index, ValueType: Integer;
      const Paired: Boolean; Val: TFitValue);
      function FitModelToLayer(Solution: TSolution): TLayeredModel; override;
      function GetPolynomes: TPolynomes; override;
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

{ TLFPSO Periodic}

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

  if Max > Xmax[0][Indexes[j]][k][0] then
  begin
    X[i][j][k][0] := Xmax[0][Indexes[j]][k][0];
    for c := 1 to High (X[i][j][k]) do
      if X[i][j][k][c] > 0 then
              X[i][j][k][c] := 0;
  end;

  if Min < Xmin[0][Indexes[j]][k][0] then
  begin
    X[i][j][k][0] := Xmin[0][Indexes[j]][k][0];
    for c := 1 to High (X[i][j][k]) do
      if X[i][j][k][c] < 0 then
              X[i][j][k][c] := 0;
  end;
end;

procedure TLFPSO_Poly.InitVelocity;
var
  i, j, k, p: integer;
begin
  MultiplyVector(Xrange, FFitParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do          // for every member of the population
    for j := 0 to High(V[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        for p := 0 to High(V[i][j][k]) do
          V[i][j][k][p] := (Random * (Vmax[0][j][k][p]- Vmin[0][j][k][p]) + Vmin[0][j][k][p])/(p + 1);
      end;
end;

function TLFPSO_Poly.Poly(const x: Integer; const C: TFloatArray): Single;
var
  i, Last: Integer;
begin
  Result := C[0]; Last := 1;
  for I := 1 to High(C) do
  begin
    Last := Last * x;
    Result := Result + C[i] * Last
  end;
end;

procedure TLFPSO_Poly.ReSeed;
begin
  Seed;
end;

procedure TLFPSO_Poly.Seed;
var
  i, j, k, p: integer;
  Val: Single;
begin
  for i := 0 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        for p := 0 to High(X[i][j][k]) do  // for every oefficient of polynome
        begin
          if p = 0 then
          begin
            Val := Rand(XRange[0][Indexes[j]][k][0]) / sqr(p + 1);
            X[i][j][k][0] := X[0][Indexes[j]][k][0] + Val
          end
          else
            X[i][j][k][p] := Rand(1)/sqr(1 + p);
        end;
        CheckLimits(i, j, k);
      end;
  end;
end;

function TLFPSO_Poly.FitModelToLayer(Solution: TSolution): TLayeredModel;
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
        Data[LayerIndex].H.V := Poly(j, Solution[k][1]);
        Data[LayerIndex].s.V := Poly(j, Solution[k][2]);
        Data[LayerIndex].r.V := Poly(j, Solution[k][3]);

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

function TLFPSO_Poly.GetPolynomes: TPolynomes;
var
  i, j, LayerIndex: integer;
  NewRecord: TPolynomeRecord;

begin
  LayerIndex := 0;
  for i := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      if not FStructure.Stacks[i].Layers[j].H.Paired then
      begin
        NewRecord.PT := ptH;
        NewRecord.LayerID := FStructure.Stacks[i].Layers[j].LayerID;
        NewRecord.StackID := FStructure.Stacks[i].Layers[j].StackID;
        NewRecord.C := Copy(abest[LayerIndex][1], 1, MaxInt);
        Result := Result + [NewRecord];
      end;

      if not FStructure.Stacks[i].Layers[j].s.Paired then
      begin
        NewRecord.PT := ptS;
        NewRecord.LayerID := FStructure.Stacks[i].Layers[j].LayerID;
        NewRecord.StackID := FStructure.Stacks[i].Layers[j].StackID;
        NewRecord.C := Copy(abest[LayerIndex][2], 1, MaxInt);
        Result := Result + [NewRecord];
      end;

      if not FStructure.Stacks[i].Layers[j].r.Paired then
      begin
        NewRecord.PT := ptRho;
        NewRecord.LayerID := FStructure.Stacks[i].Layers[j].LayerID;
        NewRecord.StackID := FStructure.Stacks[i].Layers[j].StackID;
        NewRecord.C := Copy(abest[LayerIndex][3], 1, MaxInt);
        Result := Result + [NewRecord];
      end;
      Inc(LayerIndex);
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
var
  p: Integer;
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
    Xmax[0][Index][ValueType][0] := Val.max;
    Xmin[0][Index][ValueType][0] := Val.min;
  Xrange[0][Index][ValueType][0] := Xmax[0][Index][ValueType][0] - Xmin[0][Index][ValueType][0];

  for p := 1 to High(Xrange[0][Index][ValueType]) do
    Xrange[0][Index][ValueType][p] := Xrange[0][Index][ValueType][0] / Sqr(p + 1);
end;

end.
