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
  i, j, k, Index: integer;
  D: double;
  HLinks, SLinks, RLinks: TIntArray;
  NLayers: Integer;
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

  if not FReInit then
  begin
    InitArray(FLayersCount, FLinks[1]);
    InitArray(FLayersCount, FLinks[2]);
    InitArray(FLayersCount, FLinks[3]);
  end;

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    NLayers := Length(Inp.Stacks[i].Layers);
    for k := 1 to Inp.Stacks[i].N do
    begin
      if (k = 1) and not FReInit then
      begin
        InitArray(NLayers, HLinks);
        InitArray(NLayers, SLinks);
        InitArray(NLayers, RLinks);
      end;

      for j := 0 to NLayers - 1 do
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


        if not FReInit then
        begin
          if k = 1 then
          begin
            FLinks[1][Index] := -1;
            FLinks[2][Index] := -1;
            FLinks[3][Index] := -1;

            HLinks[j] := -1;
            SLinks[j] := -1;
            RLinks[j] := -1;

            if Inp.Stacks[i].Layers[j].H.Paired then
              HLinks[j] := Index;

            if Inp.Stacks[i].Layers[j].s.Paired then
              SLinks[j] := Index;

            if Inp.Stacks[i].Layers[j].r.Paired then
              RLinks[j] := Index;

          end
          else begin
            FLinks[1][Index] := HLinks[j] ;
            FLinks[2][Index] := SLinks[j] ;
            FLinks[3][Index] := RLinks[j] ;
          end;
        end;

        Inc(Index);
      end;
    end;
  end;
end;

end.
