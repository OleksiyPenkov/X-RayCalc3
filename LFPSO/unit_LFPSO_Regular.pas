unit unit_LFPSO_Regular;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Regular = class (TLFPSO_BASE)
    private
      FLinks : array [1..3] of TIntArray;

      procedure UpdateLFPSO(const t: integer); override;
      procedure Seed; override;
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
        if FLinks[j][k] = -1 then
        begin
          V[i][j][k] := Omega(t, FTMax) * LevyWalk(X[i][j][k], gbest[j][k])  +
                        c1 * Random * (pbest[j][k] - X[i][j][k]) +
                        c2 * Random * (gbest[j][k] - X[i][j][k]);

          CheckLimits(i, j, k);
        end
        else
          X[i][j][k] := X[i][j][FLinks[j][k]];
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
        if FLinks[j][k] = -1 then
        begin
          V[i][j][k] := Omega(t, FTMax) * V[i][j][k]  +
                      c1 * Random * (pbest[j][k] - X[i][j][k]) +
                      c2 * Random * (gbest[j][k] - X[i][j][k]);

          CheckLimits(i, j, k);
        end
        else
          X[i][j][k] := X[i][j][FLinks[j][k]];
      end;
  end;
end;

procedure TLFPSO_Regular.InitVelocity;
var
  i, j, k: integer;
begin
  MultiplyVector(Xrange, FFitParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(V[i][j]) do // for every layer
        if FLinks[j][k] > -1 then
           V[i][j][k] := 0
        else
           V[i][j][k] := Random * (Vmax[0][j][k] - Vmin[0][j][k]) + Vmin[0][j][k];
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
      begin
        if FLinks[j][k] > -1 then
          X[i][j][k] := X[i][j][FLinks[j][k]]
        else
          X[i][j][k] := Xmin[0][j][k] + Random * (Xmax[0][j][k] - Xmin[0][j][k]);   // min + Random * (min-max)
      end;
  end;
end;

procedure InitArray(const Length: Integer; var A: TIntArray);
begin
  SetLength(A, 0);
  SetLength(A, Length);
end;

procedure TLFPSO_Regular.SetStructure(const Inp: TFitStructure);
var
  i, j, k, l, Index: integer;
  D: double;
  Links: array [1..3] of TIntArray;
  NLayers: Integer;
begin
  FLayersCount := Inp.TotalNP;

  // Init(FStructure)
  SetLength(FStructure.Stacks, 0);
  SetLength(FStructure.Stacks, 1);
  SetLength(FStructure.Stacks[0].Layers, FLayersCount);
  FStructure.Subs := Inp.Subs;
  FStructure.Stacks[0].N := 1;

  Init_Domains;

  if not FReInit then
    for l := 1 to 3 do
      InitArray(FLayersCount, FLinks[l]);

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    NLayers := Length(Inp.Stacks[i].Layers);
    for k := 1 to Inp.Stacks[i].N do
    begin
      if (k = 1) and not FReInit then
        for l := 1 to 3 do
          InitArray(NLayers, Links[l]);

      for j := 0 to NLayers - 1 do
      begin
        FStructure.Stacks[0].Layers[Index] := Inp.Stacks[i].Layers[j];

        Set_Init_X(Index, 1, Inp.Stacks[i].Layers[j].H);
        Set_Init_X(Index, 2, Inp.Stacks[i].Layers[j].s);
        Set_Init_X(Index, 3, Inp.Stacks[i].Layers[j].r);

        if not FReInit then
        begin
          if k = 1 then
          begin
            for l := 1 to 3 do
            begin
              FLinks[l][Index] := -1;
              Links[l][j] := -1;
            end;

            if Inp.Stacks[i].Layers[j].H.Paired then
              Links[1][j] := Index;

            if Inp.Stacks[i].Layers[j].s.Paired then
              Links[2][j] := Index;

            if Inp.Stacks[i].Layers[j].r.Paired then
              Links[3][j] := Index;
          end
          else
            for l := 1 to 3 do
              FLinks[l][Index] := Links[l][j] ;
        end;
        Inc(Index);
      end;
    end;
  end;
end;

end.
