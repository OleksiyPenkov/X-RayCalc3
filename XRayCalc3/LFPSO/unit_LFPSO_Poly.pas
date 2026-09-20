(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_LFPSO_Poly;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Poly = class (TLFPSO_BASE)
    private
      MO: Integer;
      FInitialPolynomes: TProfileFunctions;

      function TP(const n: Integer): LongInt;
    protected
      Counts: TIntArray;

      procedure SeedInitialPoly(const N, Index, ValueType: Integer;
        const Paired: Boolean; const StackID, LayerID: Word);
      procedure CheckLimitsP(const i, j, k, Ord: integer);
      procedure UpdateLFPSO(const t: integer); override;
      procedure RangeSeed; override;
      procedure XSeed; override;
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
      procedure Set_Init_XPoly(const N, Index, ValueType: Integer;
      const Paired: Boolean; Val: TFitValue);
      procedure FillModel(Model: TLayeredModel; const Solution: TSolution); override;
      function FitModelToLayer(const Solution: TSolution): TLayeredModel; override;
      function GetPolynomes: TProfileFunctions; override;
    public
      destructor Destroy; override;

      { The gradient the fit starts from - the input counterpart of the
        inherited Polynomes property, which reports the gradient it ended on.
        Assign it before Structure: SetStructure is what consumes it, and it
        seeds the higher-order coefficients of X[0]. Without it they start at
        zero, which a free fit can recover from but a frozen one cannot. }
      property InitialPolynomes: TProfileFunctions write FInitialPolynomes;
  end;

implementation

uses
  System.SysUtils,
  Neslib.FastMath,
  math_globals;

{ TLFPSO Periodic}

function TLFPSO_Poly.TP(const n: Integer): LongInt;
var
  i : Integer;
begin
  Result := FFitParams.PolyFactor;
  for I := 2 to n do
    Result := Result * FFitParams.PolyFactor;
end;

procedure TLFPSO_Poly.UpdateLFPSO(const t: integer);
var
  i, j, k, c, Ord, randIdx: integer;
  c1, c2: single;
  LTarget: single;
begin
  ApplyCFactor(c1, c2);

  for i := 0 to High(X) do       // for every member of the population
  begin
    // 30% chance: Levy toward random peer for exploration diversity
    if Random < 0.3 then
      randIdx := Random(Length(X))
    else
      randIdx := -1;  // use gbest

    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do        // for H, s, rho
      begin
        Ord := High(X[0][j][k]);
        for c := 0 to Ord do  // for every coefficient
        begin
          if randIdx >= 0 then
            LTarget := X[randIdx][j][k][c]
          else
            LTarget := gbest[j][k][c];

          V[i][j][k][c] := Omega(t, FTMax) * LevyWalk(X[i][j][k][c], LTarget)  +
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
        Ord := High(X[0][j][k]);
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
   Max, Min: Single;
   p: Integer;

   procedure Eval;
   var
     r: integer;
     Val: single;
   begin
      Max := 0; Min := 1E9;
      for r := 1 to Counts[j] do
      begin
        Val := Poly(r, X[i][j][k]);
        if Val > Max then
          Max := Val;
        if Val < Min then
           Min := Val;
      end;
   end;


   procedure CheckRange;
   begin
      if X[i][j][k][0] > Xmax[0][j][k][0] then
                 X[i][j][k][0] := Xmax[0][j][k][0];
      if X[i][j][k][0] < Xmin[0][j][k][0] then
                 X[i][j][k][0] := Xmin[0][j][k][0];
   end;

begin
  { A frozen parameter has an empty range - CollapseFixed pins min = max = V -
    and a pinned parameter is not a constrained one. Eval below takes the
    polynomial's span across all periods and compares it with that single
    point, so ANY grading reads as out of range by construction, and the walk
    that follows only stops once every higher order is zero: freezing a graded
    stack would flatten the very gradient the freeze was meant to hold. Hold
    the whole polynomial at the seeded leader instead, and stop here.
    Xrange rather than Xmax - Xmin because Xrange[0] is the quantity the rest
    of the freeze mechanism keys on: XSeed's Rand(Xrange * Ksxr), InitVelocity's
    Vmax, and Set_Init_XPoly's Xrange[p] := Xrange[0] / TP(p). }
  if Xrange[0][j][k][0] = 0 then
  begin
    { Ord is High(X[0][j][k]) at every call site, and Set_Init_XPoly gives
      X[i][j][k] and V[i][j][k] that same length for every particle. }
    for p := 0 to Ord do
    begin
      X[i][j][k][p] := X[0][j][k][p];
      V[i][j][k][p] := 0;
    end;
    Exit;
  end;

  for p := 0 to Ord do
  begin
    if V[i][j][k][p] > Vmax[0][j][k][p] then
               V[i][j][k][p] := Vmax[0][j][k][p];

    if V[i][j][k][p] < Vmin[0][j][k][p] then
               V[i][j][k][p] := Vmin[0][j][k][p];

    X[i][j][k][p] := X[i][j][k][p] + V[i][j][k][p]
  end;

  if Ord > 0 then
  begin
    Eval;
    if (Min < Xmin[0][j][k][0]) or (Max > Xmax[0][j][k][0]) then
    begin
      for p := Ord downto 1 do
      begin
        X[i][j][k][p] := 0;
        V[i][j][k][p] := 0;
        Eval;
        if (Min >= Xmin[0][j][k][0]) and (Max <= Xmax[0][j][k][0]) then
          Break;
        if p = 1 then CheckRange;
      end;
    end;
//    else CheckRange;
  end
  else CheckRange;
end;

procedure TLFPSO_Poly.InitVelocity;
var
  i, j, k, p, Order: integer;
begin
  MultiplyVector(Xrange, FFitParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do          // for every member of the population
    for j := 0 to High(V[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        Order := High(X[0][j][k]);
        for p := 0 to Order do
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
        Ord := High(X[0][j][k]);
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
begin
  XSeed;
end;

destructor TLFPSO_Poly.Destroy;
begin
  Finalize(Counts);

  inherited;
end;

procedure TLFPSO_Poly.FillModel(Model: TLayeredModel; const Solution: TSolution);
var
  i, k, j, p, LayerIndex: Integer;
  Data: TLayersData;
begin
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
        begin
          if High(Solution[Data[k].Index][p]) = 0 then
            Data[k].P[p].V := Solution[Data[k].Index][p][0]
          else
            Data[k].P[p].V := Poly(j, Solution[Data[k].Index][p]);
        end;

      Model.AddLayers(-1, Data);
    end;
  end;

  SetLength(Data, 1);
  Data[0].Material := FStructure.Subs.Material;
  Data[0].P :=FStructure.Subs.P;

  Model.AddSubstrate(Data);
end;

function TLFPSO_Poly.FitModelToLayer(const Solution: TSolution): TLayeredModel;
begin
  Result := TLayeredModel.Create;
  Result.Init;
  FillModel(Result, Solution);
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
    { N = 1 is not an indexing special case, only "this stack has nothing to
      report": Set_Init_XPoly leaves its parameters a single coefficient, so
      there is no gradient to hand back. Its layers still own their slots in
      abest, and Base walks past them below like everyone else's. }
    if FStructure.Stacks[i].N > 1 then
      for j := 0 to High(FStructure.Stacks[i].Layers) do
        for p := 1 to 3 do
          if not FStructure.Stacks[i].Layers[j].P[p].Paired then
          begin
            NewRecord.Subj := TParameterType(p - 1);
            NewRecord.LayerID := FStructure.Stacks[i].Layers[j].LayerID;
            NewRecord.StackID := FStructure.Stacks[i].Layers[j].StackID;
            NewRecord.C := Copy(abest[Base + j][p], 0, MO);
            Result := Result + [NewRecord];
          end;

    { abest carries one slot per DECLARED layer, never one per period:
      Init_Domains sizes the population from FLayersCount := Inp.Total, which
      sums Length(Stacks[i].Layers) and is not expanded by N. Advancing Base by
      N here instead ran off the end of abest as soon as a second repeating
      stack followed the first - the depth-graded case this mode exists for. }
    Inc(Base, Length(FStructure.Stacks[i].Layers));
  end;
end;

procedure TLFPSO_Poly.SetStructure(const Inp: TFitStructure);
var
  i, j, k, p, Index: integer;
begin
  SetLength(FStructure.Stacks, 0);
  FStructure := Inp;
  FLayersCount := Inp.Total;

  MO := FFitParams.MaxPOrder + 1;
  Init_Domains(0);

  SetLength(Counts, 0);
  SetLength(Counts, FStructure.TotalNP);
  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
      begin
        Set_Init_XPoly(Inp.Stacks[i].N, Index, p, Inp.Stacks[i].Layers[j].P[p].Paired, Inp.Stacks[i].Layers[j].P[p]);
        SeedInitialPoly(Inp.Stacks[i].N, Index, p, Inp.Stacks[i].Layers[j].P[p].Paired,
          Inp.Stacks[i].Layers[j].StackID, Inp.Stacks[i].Layers[j].LayerID);
      end;

      Inc(Index);
    end;
  end;

  Index := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 1 to FStructure.Stacks[i].N do
      for k := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        Counts[Index]  := FStructure.Stacks[i].N;
        Inc(Index);
      end;
  end;
end;

procedure TLFPSO_Poly.Set_Init_XPoly(const N, Index, ValueType: Integer; const Paired: Boolean; Val: TFitValue);
var
  p, i: Integer;
begin
    X[0][Index][ValueType][0]    := Val.V;
    Xmin[0][Index][ValueType][0] := Val.min;
    Xmax[0][Index][ValueType][0] := Val.max;
  Xrange[0][Index][ValueType][0] := Xmax[0][Index][ValueType][0] - Xmin[0][Index][ValueType][0];

  if not (Paired or (N = 1)) then
  begin
    SetLength(X[0][Index][ValueType], MO);
    SetLength(Xrange[0][Index][ValueType], MO);
    SetLength(V[0][Index][ValueType], MO);
    SetLength(Vmin[0][Index][ValueType], MO);
    SetLength(Vmax[0][Index][ValueType], MO);

    for p := 1 to MO - 1 do
      Xrange[0][Index][ValueType][p] := Xrange[0][Index][ValueType][0] / TP(p);

    for i := 1 to High(X) do          // for every member of the population
    begin
      SetLength(X[i][Index][ValueType], MO);
      SetLength(V[i][Index][ValueType], MO);
    end;
  end;
end;

{ Load the layer's existing depth profile back into the swarm's first particle.

  Only orders >= 1: X[0][Index][ValueType][0] is the live structure's V, which
  may have been edited by hand since the profile was written and is therefore
  authoritative for the constant term.

  Profiles are matched to layers by identity (StackID, LayerID, Subj), never by
  position: the order in which the project panel hands them over is the order of
  the extension nodes, which has nothing to do with SetStructure's flat Index.

  No match leaves the coefficients at zero, which is what the user asked for by
  clearing the extensions. }
procedure TLFPSO_Poly.SeedInitialPoly(const N, Index, ValueType: Integer;
  const Paired: Boolean; const StackID, LayerID: Word);
var
  i, k, Count: Integer;
  Src: TFuncProfileRec;
begin
  { Set_Init_XPoly grows the coefficient array only here; everywhere else it is
    length 1 and orders >= 1 do not exist. }
  if Paired or (N = 1) then
    Exit;

  for i := 0 to High(FInitialPolynomes) do
  begin
    Src := FInitialPolynomes[i];

    { A hand-authored exponential, parabolic or square-root profile does not
      carry coefficients in this basis. }
    if Src.Func <> ffPoly then
      Continue;
    if (Src.StackID <> StackID) or (Src.LayerID <> LayerID) then
      Continue;
    if Src.PIndex <> Word(ValueType) then
      Continue;

    Count := Length(Src.C);          // fewer leaves the rest at 0, more truncates
    if Count > MO then
      Count := MO;

    for k := 1 to Count - 1 do
      X[0][Index][ValueType][k] := Src.C[k];

    Break;
  end;
end;

end.
