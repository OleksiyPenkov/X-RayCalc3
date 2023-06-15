unit unit_LFPSO_Periodic;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Periodic = class (TLFPSO_BASE)
    private
      procedure UpdateLFPSO(const t: integer); override;
      procedure Seed; override;
      procedure NormalizeD(const ParticleIndex: integer);
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
    public
      //
  end;

implementation

uses
  unit_FitHelpers,
  Forms,
  System.SysUtils,
  Neslib.FastMath,
  unit_helpers,
  Dialogs;

{ TLFPSO Periodic}

procedure TLFPSO_Periodic.UpdateLFPSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: double;
begin
  c1 := c1m; //* (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);
  c2 := c2m; //* (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[I][j]) do // for every layer
      begin
        V[i][j][k] := Omega(t, FTMax) * LevyWalk(X[i][j][k], gbest[j][k])  +
                      c1 * Random * (pbest[j][k] - X[i][j][k]) +
                      c2 * Random * (gbest[j][k] - X[i][j][k]);

        CheckLimits(i, j, k);
      end;
    NormalizeD(i);
  end;

end;

procedure TLFPSO_Periodic.UpdatePSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: double;
begin
  c1 := c1m;// * (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);
  c2 := c2m;// * (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[I][j]) do // for every layer except subtrate
      begin
        V[i][j][k] := Omega(t, FTMax) * V[i][j][k]  +
                      c1 * Random * (pbest[j][k] - X[i][j][k]) +
                      c2 * Random * (gbest[j][k] - X[i][j][k]);

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
      Dreal := Dreal + X[ParticleIndex][1][j];

    f := (FStructure.Stacks[i].D - Dreal)/Dreal;
    for j := Index to Last do
      X[ParticleIndex][1][j] := X[ParticleIndex][1][j] * (1 + f);
  end;
end;

procedure TLFPSO_Periodic.InitVelocity;
var
  i, j, k: integer;
begin
  MultiplyVector(Xrange, FFitParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(V[i][j]) do // for every layer
        V[i][j][k] := Random * (Vmax[0][j][k] - Vmin[0][j][k]) + Vmin[0][j][k];
end;

procedure TLFPSO_Periodic.Seed;
var
  i, j, k: integer;
begin
  Randomize;

  for I := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[0][j]) do // for every layer
        X[i][j][k] := Xmin[0][j][k] + Random * (Xmax[0][j][k] - Xmin[0][j][k]);   // min + Random * (min-max)

    NormalizeD(i);
  end;
end;

procedure TLFPSO_Periodic.SetStructure(const Inp: TFitStructure);
var
  i, j, Index: integer;
  D: double;
begin
  FStructure := Inp;
  FLayersCount := Inp.Total;

  SetDomain(FLayersCount, X);
  SetDomain(FLayersCount, Xmax);
  SetDomain(FLayersCount, Xmin);
  SetDomain(FLayersCount, Xrange);
  SetDomain(FLayersCount, Vmin);
  SetDomain(FLayersCount, Vmax);
  SetDomain(FLayersCount, V);


  for I := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N > 1 then
    begin
      D := 0;
      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        FStructure.Stacks[i].Layers[j].LayerID := j;
        D := D + FStructure.Stacks[i].Layers[j].H.V;
      end;
      FStructure.Stacks[i].D := D;
    end;
  end;

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
       X[0][1][Index] := Inp.Stacks[i].Layers[j].H.V;
      Xmax[0][1][Index] := Inp.Stacks[i].Layers[j].H.max;
      Xmin[0][1][Index] := Inp.Stacks[i].Layers[j].H.min;
      Xrange[0][1][Index] := Xmax[0][1][Index] - Xmin[0][1][Index];

       X[0][2][Index] := Inp.Stacks[i].Layers[j].s.V;
      Xmax[0][2][Index] := Inp.Stacks[i].Layers[j].s.max;
      Xmin[0][2][Index] := Inp.Stacks[i].Layers[j].s.min;
      Xrange[0][2][Index] := Xmax[0][2][Index] - Xmin[0][2][Index];

       X[0][3][Index] := Inp.Stacks[i].Layers[j].r.V;
      Xmax[0][3][Index] := Inp.Stacks[i].Layers[j].r.max;
      Xmin[0][3][Index] := Inp.Stacks[i].Layers[j].r.min;
      Xrange[0][3][Index] := Xmax[0][3][Index] - Xmin[0][3][Index];

      Inc(Index);
    end;
  end;
end;

end.
