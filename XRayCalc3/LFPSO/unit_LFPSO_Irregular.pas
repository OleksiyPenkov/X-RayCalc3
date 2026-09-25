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
    private
      FStartFromTables: Boolean;
      FClampedStarts: Integer;
      procedure ApplyStartTables(const Inp: TFitStructure);
    public
    destructor Destroy; override;
      { Start each period from its entry of the layer's per-period table
        (TLayerData.PP, read through PeriodValue exactly as the GUI's model and
        the MCP's are built) instead of from the layer's single value. Set it
        before Structure. A free parameter keeps the layer's bounds in every
        period, its start clamped into them; a held one (min = max) is pinned
        to its own period's value. The GUI sets it for Resume and for Run with
        "Keep them" when the model has a Table; fit_xrr for "start_profiles". }
      property StartFromTables: Boolean read FStartFromTables write FStartFromTables;
      { After Structure: how many per-period start values lay outside their
        layer's limits and were moved onto the limit. }
      property ClampedStarts: Integer read FClampedStarts;
  end;

implementation

uses
  System.SysUtils,
  Neslib.FastMath,
  unit_DataProcessing;

{ TLFPSO Periodic}

procedure TLFPSO_Irregular.Smooth(const i: Word);
var
  Data: TDataArray;
  s, n : Integer;   // not Word: 0 to High of an empty list must not run
  W: ShortInt;
begin
  for s :=  0 to High(FSmoothies) do
  begin
    { unit_DataProcessing.Smooth averages the last W periods over the W
      before each; beyond half the periods that reaches before period 1 and
      its Word counters wrap. -1 (automatic) is always inside. }
    W := FFitParams.SmoothWindow;
    if W > Length(FSmoothies[s].Layers) div 2 then
      W := Length(FSmoothies[s].Layers) div 2;
    if W < -1 then
      W := -1;

    SetLength(Data, Length(FSmoothies[s].Layers));
    for n := 0 to High(Data) do
    begin
      Data[n].t := n;
      Data[n].r := X[i][FSmoothies[s].Layers[n]][FSmoothies[s].ParamID][0];
    end;

    Data := unit_DataProcessing.Smooth(Data, W);

    for n := 0 to High(Data) do
      X[i][FSmoothies[s].Layers[n]][FSmoothies[s].ParamID][0] := Data[n].r;
  end;
end;


procedure TLFPSO_Irregular.UpdateLFPSO(const t: integer);
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

    for j := 0 to High(X[I]) do // for every layer
      for k := 1 to 3 do           // for H, s, rho
      begin
        if FLinks[j][k] = -1 then
        begin
          if randIdx >= 0 then
            LTarget := X[randIdx][j][k][0]
          else
            LTarget := gbest[j][k][0];

          V[i][j][k][0] := Omega(t, FTMax) * LevyWalk(X[i][j][k][0], LTarget)  +
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
        { A paired parameter takes its first period's value, as in RangeSeed:
          the particle is scored before any update copies it across. }
        if FLinks[j][k] > -1 then
          X[i][j][k][0] := X[i][FLinks[j][k]][k][0]
        else
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

procedure TLFPSO_Irregular.ApplyStartTables(const Inp: TFitStructure);
var
  i, j, k, p, Index: Integer;
  Val: TFitValue;
begin
  { The order SetStructure expands in: stack by stack, period 1 (the surface
    end) first, the layers of each period in turn. }
  FClampedStarts := 0;
  Index := 0;
  for i := 0 to High(Inp.Stacks) do
    for k := 1 to Inp.Stacks[i].N do
      for j := 0 to High(Inp.Stacks[i].Layers) do
      begin
        for p := 1 to 3 do
        begin
          Val := Inp.Stacks[i].Layers[j].P[p];
          Val.V := Inp.Stacks[i].Layers[j].PeriodValue(p, k, Inp.Stacks[i].N, True);
          if Val.min = Val.max then
          begin
            Val.min := Val.V;
            Val.max := Val.V;
          end
          else if Val.V < Val.min then
          begin
            Val.V := Val.min;
            Inc(FClampedStarts);
          end
          else if Val.V > Val.max then
          begin
            Val.V := Val.max;
            Inc(FClampedStarts);
          end;
          Set_Init_X(Index, p, Val);
          FStructure.Stacks[0].Layers[Index].P[p] := Val;
        end;
        Inc(Index);
      end;
end;

procedure InitArray(const Length: Word; var A: TIndexes);
begin
  SetLength(A, 0);
  SetLength(A, Length);
end;

procedure TLFPSO_Irregular.SetStructure(const Inp: TFitStructure);
var
  { Integer, not Word: a loop to High of an empty list (no smoothing group when
    every parameter is paired, a stack without layers) must run no times
    rather than 65536. }
  i, j, k, l, p, Index, s: Integer;
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

  Init_Domains(0);

  { A re-initialisation (Shake) hands back the engine's own flattened structure:
    one stack of N = 1, from which the pairing cannot be read again. The links
    and the smoothing groups built on the first call stay as they are. Zeroing
    the links here, as this did until 2026-09-25, linked every parameter of
    every layer to layer 0 after the first shake. }
  if not FReInit then
  begin
    InitArray(FLayersCount, FLinks);
    SetLength(FSmoothies, 0);
  end;

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
               { A held parameter (empty range) is not smoothed: it keeps the
                 value it was given in each period, which need not be the same
                 in every one. }
               if FFitParams.Smooth and (Inp.Stacks[i].N > 1) and
                  (Inp.Stacks[i].Layers[j].P[p].max > Inp.Stacks[i].Layers[j].P[p].min) then   // create Smooths indexes for this layer
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

  { A shake hands back the engine's own flattened structure, which carries the
    tables' values and pinned bounds already. }
  if FStartFromTables and not FReInit then
    ApplyStartTables(Inp);

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
