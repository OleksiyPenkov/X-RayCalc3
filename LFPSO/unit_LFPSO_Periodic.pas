unit unit_LFPSO_Periodic;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Periodic = class (TLFPSO_BASE)
    protected
      procedure UpdateLFPSO(const t: integer); override;
      procedure RangeSeed; override;
      procedure XSeed; override;
      procedure NormalizeD(const ParticleIndex: integer);
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
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

procedure TLFPSO_Periodic.UpdateLFPSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 0 to High(V[i]) do  //for every layer
      for k := 1 to 3 do         // for H, s, rho
      begin
        V[i][j][k][0] := Omega(t, FTMax) * LevyWalk(X[i][j][k][0], gbest[j][k][0])  +
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

procedure TLFPSO_Periodic.NormalizeD; // keep D for every periodic stack constant
var
  i, j: integer;
  Index, Last: integer;
  Dreal, f: double;
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

    Dreal := 0;
    for j := Index to Last do
      Dreal := Dreal + X[ParticleIndex][j][1][0];

    f := (FStructure.Stacks[i].D - Dreal)/Dreal;
    for j := Index to Last do
      X[ParticleIndex][j][1][0] := X[ParticleIndex][j][1][0] * (1 + f);
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
        X[i][j][k][0] := X[0][j][k][0] + Rand(XRange[0][j][k][0] * FFitParams.Ksxr);

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

  Init_Domains;

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
