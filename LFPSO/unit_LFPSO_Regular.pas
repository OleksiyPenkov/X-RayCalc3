unit unit_LFPSO_Regular;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Regular = class (TLFPSO_BASE)
    private
      FLinks : TIndexes;

      procedure UpdateLFPSO(const t: integer); override;
      procedure Seed; override;
      procedure ReSeed; override;
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
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
      begin
        if FLinks[j][k] = -1 then
        begin
          V[i][j][k][0] := Omega(t, FTMax) * LevyWalk(X[i][j][k][0], gbest[j][k][0])  +
                        c1 * Random * (pbest[j][k][0] - X[i][j][k][0]) +
                        c2 * Random * (gbest[j][k][0] - X[i][j][k][0]);
          CheckLimits(i, j, k);
        end
        else
          X[i][j][k][0] := X[i][FLinks[j][k]][k][0];
      end;

  end;
end;

procedure TLFPSO_Regular.UpdatePSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: single;
begin
  ApplyCFactor(c1, c2);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
      begin
        if FLinks[j][k] = -1 then
        begin
          V[i][j][k][0] := Omega(t, FTMax) * V[i][j][k][0]  +
                      c1 * Random * (pbest[j][k][0] - X[i][j][k][0]) +
                      c2 * Random * (gbest[j][k][0] - X[i][j][k][0]);
          CheckLimits(i, j, k);
        end
        else
          X[i][j][k][0] := X[i][FLinks[j][k]][k][0];
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
    for j := 0 to High(V[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
        if FLinks[j][k] > -1 then
           V[i][j][k][0] := 0
        else
           V[i][j][k][0] := Random * (Vmax[0][j][k][0] - Vmin[0][j][k][0]) + Vmin[0][j][k][0];

end;

procedure TLFPSO_Regular.ReSeed;
var
  i, j, k: integer;
begin
  for i := 0 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do            // for H, s, rho
        X[i][j][k][0] := X[0][j][k][0] + Rand(XRange[0][j][k][0]);
  end;
end;

procedure TLFPSO_Regular.Seed;
var
  i, j, k: integer;
begin
  Randomize;

  for I := 1 to High(X) do // for every member of the population
  begin
    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
      begin
        if FLinks[j][k] > -1 then
          X[i][j][k][0] := X[i][FLinks[j][k]][k][0]
        else
          X[i][j][k][0] := Xmin[0][j][k][0] + Random * (Xmax[0][j][k][0] - Xmin[0][j][k][0]);   // min + Random * (min-max)
      end;
  end;
end;

procedure InitArray(const Length: Integer; var A: TIndexes);
begin
  SetLength(A, 0);
  SetLength(A, Length);
end;

procedure TLFPSO_Regular.SetStructure(const Inp: TFitStructure);
var
  i, j, k, l, p, Index: integer;
  D: double;
  Links: TIndexes;
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

  InitArray(FLayersCount, FLinks);

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    NLayers := Length(Inp.Stacks[i].Layers);
    for k := 1 to Inp.Stacks[i].N do
    begin
      if (k = 1) and not FReInit then

      InitArray(NLayers, Links);

      for j := 0 to NLayers - 1 do
      begin
        FStructure.Stacks[0].Layers[Index] := Inp.Stacks[i].Layers[j];

        for p := 1 to 3 do
          Set_Init_X(Index, p, Inp.Stacks[i].Layers[j].P[p]);

        if not FReInit then
        begin
          if k = 1 then
          begin
            for l := 1 to 3 do
            begin
              FLinks[Index][l] := -1;
              Links[j][l] := -1;
            end;

            for p := 1 to 3 do
               if Inp.Stacks[i].Layers[j].P[p].Paired then
                  Links[j][1] := Index;
          end
          else
            for l := 1 to 3 do
              FLinks[Index][l] := Links[j][l] ;
        end;
        Inc(Index);
      end;
    end;
  end;
end;

end.
