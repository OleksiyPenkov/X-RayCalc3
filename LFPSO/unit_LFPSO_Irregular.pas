(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_LFPSO_Irregular;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TSmoothieLayers = record
    StackID, LayerID, ParamID: Word;
        Layers: array of Word;
  end;

  TLFPSO_Irregular = class (TLFPSO_BASE)
  private
      procedure Smooth(const i: Word);
    protected
      FLinks : TIndexes;
      FSmoothies: array of TSmoothieLayers;

      procedure UpdateLFPSO(const t: integer); override;
      procedure RangeSeed; override;
      procedure XSeed; override;
      procedure SetStructure(const Inp: TFitStructure); override;
      procedure UpdatePSO(const t: integer); override;
      procedure InitVelocity; override;
    public
      //
    destructor Destroy; override;
  end;

implementation

uses
  Forms,
  System.SysUtils,
  Neslib.FastMath,
  unit_helpers,
  Dialogs;

{ TLFPSO Periodic}

procedure TLFPSO_Irregular.Smooth(const i: Word);
var
  Data: TDataArray;
  s, n : Word;
begin
  for s :=  0 to High(FSmoothies) do
  begin
    SetLength(Data, Length(FSmoothies[s].Layers));
    for n := 0 to High(Data) do
    begin
      Data[n].t := n;
      Data[n].r := X[i][FSmoothies[s].Layers[n]][FSmoothies[s].ParamID][0];
    end;

    Data := unit_helpers.Smooth(Data, FFitParams.SmoothWindow);

    for n := 0 to High(Data) do
      X[i][FSmoothies[s].Layers[n]][FSmoothies[s].ParamID][0] := Data[n].r;
  end;
end;


procedure TLFPSO_Irregular.UpdateLFPSO(const t: integer);
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
        end
        else
          X[i][j][k][0] := X[i][FLinks[j][k]][k][0];

        CheckLimits(i, j, k);
      end;

    if FFitParams.Smooth then Smooth(i);
  end;
end;

procedure TLFPSO_Irregular.UpdatePSO(const t: integer);
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
        end
        else
          X[i][j][k][0] := X[i][FLinks[j][k]][k][0];

        CheckLimits(i, j, k);
      end;

    if FFitParams.Smooth then Smooth(i);
  end;
end;

destructor TLFPSO_Irregular.Destroy;
begin
  Finalize(FLinks);
  inherited;
end;

procedure TLFPSO_Irregular.InitVelocity;
var
  i, j, k: Word;
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

procedure TLFPSO_Irregular.XSeed;
var
  i, j, k: Word;
begin
  for i := 1 to High(X) do          // for every member of the population
  begin
    for j := 0 to High(X[i]) do     //for every layer
      for k := 1 to 3 do
      begin            // for H, s, rho
        X[i][j][k][0] := X[0][j][k][0] + Rand(XRange[0][j][k][0] * FFitParams.Ksxr);
        CheckLimits(i, j, k);
      end;

    if FFitParams.Smooth then Smooth(i);
  end;
end;

procedure TLFPSO_Irregular.RangeSeed;
var
  i, j, k: Word;
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

        CheckLimits(i, j, k);
      end;

    if FFitParams.Smooth then Smooth(i);
  end;
end;

procedure InitArray(const Length: Word; var A: TIndexes);
begin
  SetLength(A, 0);
  SetLength(A, Length);
end;

procedure TLFPSO_Irregular.SetStructure(const Inp: TFitStructure);
var
  i, j, k, l, p, Index, s: Word;
  Links: TIndexes;
  NLayers: Word;
begin
  FLayersCount := Inp.TotalNP;

  // Init(FStructure)
  SetLength(FStructure.Stacks, 0);
  SetLength(FStructure.Stacks, 1);
  SetLength(FStructure.Stacks[0].Layers, FLayersCount);
  FStructure.Subs := Inp.Subs;
  FStructure.Stacks[0].N := 1;

  Init_Domains(0);

  InitArray(FLayersCount, FLinks);
  if not FReInit then
      SetLength(FSmoothies, 0);

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    NLayers := Length(Inp.Stacks[i].Layers);
    for k := 1 to Inp.Stacks[i].N do         // for every layer in stack
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
            begin
               if Inp.Stacks[i].Layers[j].P[p].Paired then
                  Links[j][p] := Index
               else
               if FFitParams.Smooth and (Inp.Stacks[i].N > 1) then   // create Smooths indexes for this layer
               begin
                 s := Length(FSmoothies);
                 SetLength(FSmoothies, s + 1);
                 SetLength(FSmoothies[s].Layers, Inp.Stacks[i].N);

                 FSmoothies[s].StackID := i;
                 FSmoothies[s].LayerID := j;
                 FSmoothies[s].ParamID := p;
               end;
            end;
          end
          else
            for l := 1 to 3 do
              FLinks[Index][l] := Links[j][l];
        end;
        Inc(Index);
      end;
    end;
  end;

  if not FReInit and FFitParams.Smooth then
  begin
    Index := 0;

    for i := 0 to High(Inp.Stacks) do
     for k := 0 to Inp.Stacks[i].N - 1 do
     begin
       for j := 0 to High(Inp.Stacks[i].Layers) do
       begin
         for s := 0 to High(FSmoothies) do
           if (FSmoothies[s].StackID = i) and
              (FSmoothies[s].LayerID = j)
           then
             FSmoothies[s].Layers[k] := Index;
         Inc(Index);
       end;
     end;
  end;

end;

end.
