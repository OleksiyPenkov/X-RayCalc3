unit unit_LFPSO_Poly;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Poly = class (TLFPSO_BASE)
    protected
      Indexes: TIntArray;
      Counts: TIntArray;

      procedure CheckLimitsP(const i, j, k, Ord: integer);
      procedure UpdateLFPSO(const t: integer); override;
      procedure RangeSeed; override;
      procedure XSeed; override;
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
      procedure Set_Init_XPoly(const N, Index, ValueType: Integer;
      const Paired: Boolean; Val: TFitValue);
      function FitModelToLayer(Solution: TSolution): TLayeredModel; override;
      function GetPolynomes: TProfileFunctions; override;
      function Order(const j, k: Integer): integer; inline;
    public
      destructor Destroy; override;
      //
  end;

implementation

uses
  Forms,
  System.SysUtils,
  Neslib.FastMath,
  unit_helpers,
  Dialogs, math_globals;

{ TLFPSO Periodic}

function TP(const n: Integer): Integer;
var
  i : Integer;
begin
  Result := 10;
  for I := 2 to n do
    Result := Result * 10;
end;

procedure TLFPSO_Poly.UpdateLFPSO(const t: integer);
var
  i, j, k,c, Ord: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 0 to High(X) do       // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do        // for H, s, rho
      begin
        Ord := Order(j, k);
        for c := 0 to Ord do  // for every coefficient
        begin
          V[i][j][k][c] := Omega(t, FTMax) * LevyWalk(X[i][j][k][c], gbest[j][k][c])  +
                        c1 * Random * (pbest[j][k][c] - X[i][j][k][c]) +
                        c2 * Random * (gbest[j][k][c] - X[i][j][k][c]);
        end;
        CheckLimitsP(i, j, k, Ord);
      end;
  end;
end;

procedure TLFPSO_Poly.UpdatePSO(const t: integer);
var
  i, j, k, c, Ord: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 0 to High(X) do // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do
      begin
        Ord := Order(j, k);
        for c := 0 to Ord do  // for every coefficient
        begin
            V[i][j][k][c] := Omega(t, FTMax) * V[i][j][k][c]  +
                      c1 * Random * (pbest[j][k][c] - X[i][j][k][c]) +
                      c2 * Random * (gbest[j][k][c] - X[i][j][k][c]);

        end;
        CheckLimitsP(i, j, k, Ord);
      end;
  end;
end;

procedure TLFPSO_Poly.CheckLimitsP(const i, j, k, Ord: integer);
var
   Val, Max, Min: Single;
   p, r: Integer;
begin
  for p := 0 to Ord do
  begin
    if V[i][j][k][p] > Vmax[0][j][k][p] then
               V[i][j][k][p] := Vmax[0][j][k][p];

    if V[i][j][k][p] < Vmin[0][j][k][p] then
               V[i][j][k][p] := Vmin[0][j][k][p];

    X[i][j][k][p] := X[i][j][k][p] + V[i][j][k][p]
  end;

  Max := 0; Min := 1E9;

  if Ord > 0 then
  begin
    for r := 1 to Counts[j] do
    begin
      Val := Poly(r, X[i][j][k]);
      if Val > Max then
         Max := Val;
      if Val < Min then
         Min := Val;
    end
  end
  else begin
    Max := X[i][j][k][0];
    Min := X[i][j][k][0];
  end;

  if Max > Xmax[0][Indexes[j]][k][0] then
  begin
    X[i][j][k][0] := Xmax[0][Indexes[j]][k][0];
    for p := 1 to Ord do
      if X[i][j][k][p] > 0 then
              X[i][j][k][p] := 0;
  end;

  if Min < Xmin[0][Indexes[j]][k][0] then
  begin
    X[i][j][k][0] := Xmin[0][Indexes[j]][k][0];
    for p := 1 to Ord do
      if X[i][j][k][p] < 0 then
              X[i][j][k][p] := 0;
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
        for p := 0 to Order(j, k) do
        begin
          if p > 0 then
          begin
            Vmax[0][j][k][p] :=  Vmax[0][j][k][0]/TP(p);
            Vmin[0][j][k][p] := -Vmax[0][j][k][p];
          end;
          V[i][j][k][p] := Rand(Vmax[0][j][k][p]);
        end;
      end;
end;

procedure TLFPSO_Poly.XSeed;
var
  i, j, k, p, Ord: integer;
begin
  for i := 1 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        Ord := Order(j, k);
        for p := 0 to Ord do  // for every oefficient of polynome
        if p = 0 then
           X[i][j][k][0] := X[0][j][k][0] + Rand(XRange[0][j][k][0] * FFitParams.Ksxr)
        else
           X[i][j][k][p] := X[0][j][k][p] + Rand(XRange[0][j][k][p] * FFitParams.Ksxr);

        CheckLimitsP(i, j, k, Ord);
      end;
  end;
end;

procedure TLFPSO_Poly.RangeSeed;
var
  i, j, k, p: integer;
  Val: Single;
begin
  for i := 0 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        for p := 0 to Order(j, k) do  // for every oefficient of polynome
        begin
          if p = 0 then
          begin
            Val := Rand(XRange[0][Indexes[j]][k][0]);
            X[i][j][k][0] := X[0][Indexes[j]][k][0] + Val
          end
          else
            X[i][j][k][p] := Rand(1)/TP(p);
        end;
        CheckLimits(i, j, k);
      end;
  end;
end;

destructor TLFPSO_Poly.Destroy;
begin
  Finalize(Indexes);
  Finalize(Counts);

  inherited;
end;

function TLFPSO_Poly.FitModelToLayer(Solution: TSolution): TLayeredModel;
var
  i, k, j, p, LayerIndex: Integer;
  Data: TLayersData;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  LayerIndex := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    SetLength(Data, 0);
    SetLength(Data, Length(FStructure.Stacks[i].Layers));
    for k := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      Data[k].Material := FStructure.Stacks[i].Layers[k].Material;
      Data[k].Index    := LayerIndex;                              // Layer index accross Solution

      Data[k].StackID := FStructure.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := FStructure.Stacks[i].Layers[k].LayerID;
      Inc(LayerIndex);
    end;

    for j := 1 to FStructure.Stacks[i].N do
    begin
      for k := 0 to High(FStructure.Stacks[i].Layers) do
        for p := 1 to 3 do
          Data[k].P[p].V := Poly(j, Solution[Data[k].Index][p]);

      Result.AddLayers(-1, Data);
    end;
  end;

  SetLength(Data, 1);
  Data[0].Material := FStructure.Subs.Material;
  Data[0].P :=FStructure.Subs.P;


  Result.AddSubstrate(Data);
end;

function TLFPSO_Poly.GetPolynomes: TProfileFunctions;
var
  i, j, p, Base: integer;
  NewRecord: TFuncProfileRec;
begin
  NewRecord.Func := ffPoly;
  Base := 0;
  for i := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N = 1 then
    begin
     Inc(Base, FStructure.Stacks[i].N);
     Continue;
    end;

    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
      begin
        if not FStructure.Stacks[i].Layers[j].P[p].Paired then
        begin
          NewRecord.Subj := TParameterType(p - 1);
          NewRecord.LayerID := FStructure.Stacks[i].Layers[j].LayerID;
          NewRecord.StackID := FStructure.Stacks[i].Layers[j].StackID;
          NewRecord.C := abest[Indexes[Base + j]][p];
          Result := Result + [NewRecord];
        end;
      end;
    end;
    Inc(Base, FStructure.Stacks[i].N);
  end;
end;

procedure TLFPSO_Poly.SetStructure(const Inp: TFitStructure);
var
  i, j, k, p, Index, Base: integer;
begin
  SetLength(FStructure.Stacks, 0);
  FStructure := Inp;
  FLayersCount := Inp.Total;

  Init_Domains;

  SetLength(Indexes, 0);
  SetLength(Counts, 0);
  SetLength(Indexes, FStructure.TotalNP);
  SetLength(Counts, FStructure.TotalNP);
  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
        Set_Init_XPoly(Inp.Stacks[i].N, Index, p, Inp.Stacks[i].Layers[j].P[p].Paired, Inp.Stacks[i].Layers[j].P[p]);

      Inc(Index);
    end;
  end;

  Index := 0; Base := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 1 to FStructure.Stacks[i].N do
      for k := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        Indexes[Index] := Base + k;
        Counts[Index]  := FStructure.Stacks[i].N;
        Inc(Index);
      end;
    Inc(Base, FStructure.Stacks[i].N );
  end;

  for i := 1 to High(X) do          // for every member of the population
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do
         X[i][j][k][10] := X[0][j][k][10];
end;

procedure TLFPSO_Poly.Set_Init_XPoly(const N, Index, ValueType: Integer; const Paired: Boolean; Val: TFitValue);
var
  p: Integer;
begin
    X[0][Index][ValueType][0]    := Val.V;
    Xmax[0][Index][ValueType][0] := Val.max;
    Xmin[0][Index][ValueType][0] := Val.min;
  Xrange[0][Index][ValueType][0] := Xmax[0][Index][ValueType][0] - Xmin[0][Index][ValueType][0];

  if not (Paired or (N = 1)) then
  begin
    X[0][Index][ValueType][10]:= FFitParams.MaxPOrder;

    for p := 1 to Order(Index, ValueType) do
      Xrange[0][Index][ValueType][p] := Xrange[0][Index][ValueType][0] / TP(p);
  end;
end;

function TLFPSO_Poly.Order(const j, k: Integer): integer;
var
 v : single;
begin
  v := X[0][j][k][10];
  Result := System.Trunc(v);
end;

end.
