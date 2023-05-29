unit unit_LFPSO_Regular;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Regular = class (TLFPSO_BASE)
    private
      procedure UpdateLFPSO(const t: integer); override;
      procedure Seed; override;
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
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

procedure TLFPSO_Regular.UpdateLFPSO(const t: integer);
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
  end;
end;

procedure TLFPSO_Regular.UpdatePSO(const t: integer);
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
  end;
end;

procedure TLFPSO_Regular.Seed;
var
  i, j, k: integer;
begin
  Randomize;

  for I := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[0][j]) do // for every layer
        X[i][j][k] := Xmin[0][j][k] + Random * (Xmax[0][j][k] - Xmin[0][j][k]);   // min + Random * (min-max)
  end;
end;

procedure TLFPSO_Regular.SetStructure(const Inp: TFitStructure);
var
  i, j, k, Index: integer;
  D: double;
begin
  FLayersCount := Inp.TotalNP;

  // Init(FStructure)
  SetLength(FStructure.Stacks, 0);
  SetLength(FStructure.Stacks, 1);
  SetLength(FStructure.Stacks[0].Layers, FLayersCount);
  FStructure.Subs := Inp.Subs;
  FStructure.Stacks[0].N := 1;

  SetDomain(FLayersCount, X);
  SetDomain(FLayersCount, Xmax);
  SetDomain(FLayersCount, Xmin);
  SetDomain(FLayersCount, Xrange);
  SetDomain(FLayersCount, Vmin);
  SetDomain(FLayersCount, Vmax);
  SetDomain(FLayersCount, V);

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for k := 1 to Inp.Stacks[i].N do
      for j := 0 to High(Inp.Stacks[i].Layers) do
      begin
        FStructure.Stacks[0].Layers[Index] := Inp.Stacks[i].Layers[j];

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
