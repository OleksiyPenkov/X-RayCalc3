(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_LFPSO_Periodic;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Periodic = class (TLFPSO_BASE)
    private
      { Per-stack period range, indexed like FStructure.Stacks. An entry with
        Max <= Min (the default) holds the stack at its start period, which is
        what the GUI always does; SetPeriodRange opens it. }
      FPeriodMin: TArray<Double>;
      FPeriodMax: TArray<Double>;
    protected
      procedure UpdateLFPSO(const t: integer); override;
      procedure RangeSeed; override;
      procedure XSeed; override;
      procedure NormalizeD(const ParticleIndex: integer);
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
    public
      /// <summary>Lets the period of stack StackIndex move inside [AMin, AMax]
      /// instead of being held at its start value: NormalizeD then rescales
      /// the stack's layers only when their sum leaves that range, to the
      /// nearer bound. AMax &lt;= AMin restores the hold. Call after Structure
      /// is set; the GUI never calls it, so its fits are unchanged.</summary>
      procedure SetPeriodRange(StackIndex: Integer; AMin, AMax: Double);
  end;

implementation

uses
  System.SysUtils,
  Neslib.FastMath;

{ TLFPSO Periodic}

procedure TLFPSO_Periodic.UpdateLFPSO(const t: integer);
var
  i, j, k, randIdx: integer;
  c1, c2: single;
  LTarget: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do // for every member of the population
  begin
    // 30% chance: Levy toward random peer for exploration diversity
    if Random < 0.3 then
      randIdx := Random(Length(X))
    else
      randIdx := -1;  // use gbest

    for j := 0 to High(V[i]) do  //for every layer
      for k := 1 to 3 do         // for H, s, rho
      begin
        if randIdx >= 0 then
          LTarget := X[randIdx][j][k][0]
        else
          LTarget := gbest[j][k][0];

        V[i][j][k][0] := Omega(t, FTMax) * LevyWalk(X[i][j][k][0], LTarget)  +
                      c1 * Random * (pbest[j][k][0] - X[i][j][k][0]) +
                      c2 * Random * (gbest[j][k][0] - X[i][j][k][0]);

        CheckLimits(i, j, k);
      end;
    NormalizeD(i);
  end;

end;

procedure TLFPSO_Periodic.UpdatePSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 0 to High(V) do          // for every member of the population
  begin
    for j := 0 to High(V[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        V[i][j][k][0] := Omega(t, FTMax) * V[i][j][k][0]  +
                      c1 * Random * (pbest[j][k][0] - X[i][j][k][0]) +
                      c2 * Random * (gbest[j][k][0] - X[i][j][k][0]);

        CheckLimits(i, j, k);
      end;
    NormalizeD(i);
  end;
end;

procedure TLFPSO_Periodic.SetPeriodRange(StackIndex: Integer; AMin, AMax: Double);
begin
  if StackIndex < 0 then
    Exit;
  if StackIndex >= Length(FPeriodMin) then
  begin
    SetLength(FPeriodMin, StackIndex + 1);   // new entries are 0/0: held
    SetLength(FPeriodMax, StackIndex + 1);
  end;
  FPeriodMin[StackIndex] := AMin;
  FPeriodMax[StackIndex] := AMax;
end;

{ Keeps the period of every periodic stack - at the start model's value, or
  inside the range SetPeriodRange opened - without moving any thickness outside
  its own [Xmin, Xmax]. The correction is spread over the layers in proportion
  to their thickness, so that with room everywhere the ratio between them is
  kept exactly as the plain rescaling did; a layer that reaches its bound stops
  there and the remainder goes to the others, and a fixed thickness
  (Xmin = Xmax) never moves. A period the bounds cannot reach is left at the
  nearest sum they allow rather than forced. Before 2026-09-16 one factor was
  applied to every layer, which drove thicknesses through their bounds - and
  below zero when the pull-back was large - in fit_xrr results. }
procedure TLFPSO_Periodic.NormalizeD(const ParticleIndex: integer);
var
  i, j, Pass: integer;
  Index, Last: integer;
  Dreal, Target, Delta, W, Lo, Hi, Xj, Tol: double;
  Uniform: Boolean;

  function HasRoom(const Layer: integer): Boolean;
  begin
    if Delta > 0 then
      Result := X[ParticleIndex][Layer][1][0] < Xmax[0][Layer][1][0]
    else
      Result := X[ParticleIndex][Layer][1][0] > Xmin[0][Layer][1][0];
  end;

  function Weight(const Layer: integer): double;
  begin
    if Uniform then
      Result := 1
    else if X[ParticleIndex][Layer][1][0] > 0 then
      Result := X[ParticleIndex][Layer][1][0]
    else
      Result := 0;
  end;

  function StackSum: double;
  var
    k: integer;
  begin
    Result := 0;
    for k := Index to Last do
      Result := Result + X[ParticleIndex][k][1][0];
  end;

begin
  Index := 0;

  for I := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N = 1 then    // if not periodic stack
    begin
       Inc(Index, Length(FStructure.Stacks[i].Layers));
       Continue;
    end;
    Last := Index + Length(FStructure.Stacks[i].Layers) - 1;

    // every thickness inside its own bounds first: XSeed and CheckLimits
    // already see to that, so this only guards a caller that did not
    for j := Index to Last do
    begin
      Lo := Xmin[0][j][1][0];
      Hi := Xmax[0][j][1][0];
      if X[ParticleIndex][j][1][0] < Lo then
        X[ParticleIndex][j][1][0] := Lo
      else if X[ParticleIndex][j][1][0] > Hi then
        X[ParticleIndex][j][1][0] := Hi;
    end;

    Dreal := StackSum;

    if (i < Length(FPeriodMin)) and (FPeriodMax[i] > FPeriodMin[i]) then
    begin
      // a free period: touch the layers only when their sum leaves the range
      if Dreal < FPeriodMin[i] then
        Target := FPeriodMin[i]
      else if Dreal > FPeriodMax[i] then
        Target := FPeriodMax[i]
      else
      begin
        Index := Last + 1;
        Continue;
      end;
    end
    else
      Target := FStructure.Stacks[i].D;

    Tol := 1E-6 * Abs(Target);
    if Tol < 1E-6 then
      Tol := 1E-6;

    // Every pass either lands on the target or pins one more layer to its
    // bound, so one pass per layer plus one is always enough.
    for Pass := 0 to Last - Index + 1 do
    begin
      Delta := Target - Dreal;
      if Abs(Delta) <= Tol then
        Break;

      Uniform := False;
      W := 0;
      for j := Index to Last do
        if HasRoom(j) then
          W := W + Weight(j);
      if W <= 0 then
      begin
        // nothing with a positive thickness can move: share the correction
        // equally among the layers that still have room, if any
        Uniform := True;
        for j := Index to Last do
          if HasRoom(j) then
            W := W + 1;
        if W <= 0 then
          Break;                        // the bounds cannot reach this period
      end;

      for j := Index to Last do
        if HasRoom(j) then
        begin
          Lo := Xmin[0][j][1][0];
          Hi := Xmax[0][j][1][0];
          Xj := X[ParticleIndex][j][1][0] + Delta * Weight(j) / W;
          if Xj < Lo then
            Xj := Lo
          else if Xj > Hi then
            Xj := Hi;
          X[ParticleIndex][j][1][0] := Xj;
        end;

      Dreal := StackSum;
    end;

    Index := Last + 1;
  end;
end;

procedure TLFPSO_Periodic.XSeed;
var
  i, j, k: integer;
begin
  for i := 1 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
      begin
        X[i][j][k][0] := X[0][j][k][0] + Rand(XRange[0][j][k][0] * FFitParams.Ksxr);
        { Clamp the seed as TLFPSO_Irregular.XSeed does through CheckLimits:
          a seed outside its bounds was evaluated as it stood, and when it
          scored best - after a shake, or with range_seed off - the fit ended
          on a value the client never allowed (fit_xrr, 2026-09-16). }
        if X[i][j][k][0] < Xmin[0][j][k][0] then
          X[i][j][k][0] := Xmin[0][j][k][0]
        else if X[i][j][k][0] > Xmax[0][j][k][0] then
          X[i][j][k][0] := Xmax[0][j][k][0];
      end;

    NormalizeD(i);
  end;
end;

procedure TLFPSO_Periodic.RangeSeed;
var
  i, j, k: integer;
begin
  for i := 0 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
       X[i][j][k][0] := Xmin[0][j][k][0] + Random * XRange[0][j][k][0];   // min + Random * (min-max)
    NormalizeD(i);
  end;
end;

procedure TLFPSO_Periodic.InitVelocity;
var
  i, j, k: integer;
begin
  MultiplyVector(Xrange, FFitParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do          // for every member of the population
    for j := 0 to High(V[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
        V[i][j][k][0] := Random * (Vmax[0][j][k][0] - Vmin[0][j][k][0]) + Vmin[0][j][k][0];
end;

procedure TLFPSO_Periodic.SetStructure(const Inp: TFitStructure);
var
  i, j, p, Index: integer;
  D: double;
begin
  FStructure := Inp;
  FLayersCount := Inp.Total;

  Init_Domains(0);

  for I := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N > 1 then
    begin
      D := 0;
      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        FStructure.Stacks[i].Layers[j].LayerID := j;
        D := D + FStructure.Stacks[i].Layers[j].P[1].V;
      end;
      FStructure.Stacks[i].D := D;
    end;
  end;

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
        Set_Init_X(Index, p, Inp.Stacks[i].Layers[j].P[p]);

      Inc(Index);
    end;
  end;
end;

end.
