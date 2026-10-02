(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_UncertRequest;

(* A fitted project as the uncertainty tool's parameter map.

   What is sampled is what the fit left free: every layer value that is not
   Fixed and has min < max, in the fit mode the project was saved with.

     periodic  one slot per free value. In a repeating stack the thickest free
               thickness is the derived layer (the period minus the others);
               the period is a slot only when the fit had Free period on,
               inside its window, and is held at the fitted value otherwise -
               what TLFPSO_Periodic does.
     profile   an unpaired free value of a repeating stack is a polynomial in
               the period number, starting at the layer's value and its
               gradient extension; everything else is one slot.
     table     an unpaired free value of a repeating stack is one slot per
               period, starting at the fitted table when the model has its
               Table extension; everything else is one slot. More than
               MAX_TABLE_SLOTS table slots are refused: the truth gate found
               10 sound and 40 not (plan A's Outcome).

   Every repeating stack reports its summary numbers. The substrate is not
   sampled; the classic engines do not fit it either. Every refusal is a plain
   sentence. No VCL. *)

interface

uses
  System.SysUtils, unit_Types, unit_ParamMap, unit_MCPProjectFile;

const
  MAX_TABLE_SLOTS = 20;
  { The measurement's own three values (3.10's defaults): the scale within
    10^+-0.2, the background up to ten times the smallest measured value, the
    relative noise floor f from 0.1 % to 100 %. }
  SCALE_WINDOW_LOG = 0.2;
  BACKGROUND_FACTOR = 10;
  F_MIN = 0.001;
  F_MAX = 1;
  { A count below this is left out of the likelihood. }
  COUNTS_MIN = 10;

type
  TFitModeKind = (fmTable, fmPeriodic, fmProfile);       // [FIT] Mode 0, 1, 2

  /// <summary>What the user knows from elsewhere: Name is a reported name
  /// that can carry one (a plain value, a derived layer, a summary).</summary>
  TUncertPrior = record
    Name: string;
    Mean, SD: Double;
    Note: string;
  end;

  TUncertNameKind = (
    unValue,          // a layer value with one number for the whole stack
    unPeriodValue,    // a table entry or a profile's value in one period: a point of the depth chart
    unCoefficient,    // a profile's coefficient: sampled, not shown as a row
    unPeriod,         // a sampled period
    unSummary,        // mean period, total thickness, drift
    unMeasurement);   // scale, background, noise floor

  /// <summary>One reported value as the window names it, in the map's
  /// reported order.</summary>
  TUncertName = record
    Name: string;            // the reported name, e.g. 's0.l2.thickness'
    Caption: string;         // 'W  H, A'
    Group: string;           // 'Summary', the stack's title, 'Measurement'
    Kind: TUncertNameKind;
    Held: Boolean;           // a number that does not move in this fit mode: shown without an error
    CanHavePrior: Boolean;
    Stack, Layer, P: Integer;   // -1 where it does not apply
    Period: Integer;            // unPeriodValue: the period, from 1 at the surface
  end;

  TUncertRequest = record
    Mode: TFitModeKind;
    Structure: TFitStructure;           // as fitted
    Extensions: TArray<TXRCXProfileExt>;
    KeepTables: Boolean;                // the model has its Table extension
    FreePeriod: Boolean;
    PeriodWindow: Double;               // a fraction
    Data: TDataArray;
    CalcParams: TCalcThreadParams;
    RMin: Double;
    BackgroundMax: Double;
    Names: TArray<TUncertName>;
    TableSlots: Integer;
  end;

/// <summary>'' and a request, or a plain sentence saying why this project
/// cannot be analysed.</summary>
function BuildRequest(const P: TXRCXProject; out Req: TUncertRequest): string;
/// <summary>The map of Req with the priors set; the caller frees it. Raises
/// EParamMap for a prior on a name that cannot carry one.</summary>
function BuildMap(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>): TParamMap;
/// <summary>'' when the fitted values are a feasible start, else a plain
/// sentence naming what lies outside its limits.</summary>
function StartProblem(Map: TParamMap; const Req: TUncertRequest): string;

implementation

uses
  System.Math, unit_Likelihood, unit_MCPStructure;

const
  FIELD: array [1 .. 3] of string = ('thickness', 'sigma', 'density');
  ANGSTROM = #$00C5;
  SIGMA = #$03C3;
  RHO = #$03C1;

function Free(const V: TFitValue): Boolean;
begin
  Result := not V.Fixed and (V.min < V.max);
end;

function SlotName(Stack, Layer, P: Integer): string;
begin
  Result := Format('s%d.l%d.%s', [Stack, Layer, FIELD[P]]);
end;

function StackTitle(const S: TFitStructure; Stack: Integer): string;
begin
  Result := S.Stacks[Stack].Header;
  if Result = '' then
    Result := Format('Stack %d', [Stack + 1]);
end;

function ValueCaption(const S: TFitStructure; Stack, Layer, P: Integer): string;
begin
  case P of
    1: Result := S.Stacks[Stack].Layers[Layer].Material + '  H, ' + ANGSTROM;
    2: Result := S.Stacks[Stack].Layers[Layer].Material + '  ' + SIGMA + ', ' + ANGSTROM;
  else
    Result := S.Stacks[Stack].Layers[Layer].Material + '  ' + RHO + ', g/cm' + #$00B3;
  end;
end;

function StackPeriodOf(const S: TFitStructure; Stack: Integer): Double;
var
  k: Integer;
begin
  Result := 0;
  for k := 0 to High(S.Stacks[Stack].Layers) do
    Result := Result + S.Stacks[Stack].Layers[k].P[1].V;
end;

{ The coefficients a profile starts from: the layer's value, then the gradient
  extension's orders 1 and up (its [0] is not stored in a project). }
function ProfileStart(const Req: TUncertRequest; Stack, Layer, P: Integer): TArray<Double>;
var
  i, k: Integer;
begin
  Result := [Req.Structure.Stacks[Stack].Layers[Layer].P[P].V, 0];
  for i := 0 to High(Req.Extensions) do
    if (Req.Extensions[i].StackID = Stack) and (Req.Extensions[i].LayerID = Layer) and
       (Ord(Req.Extensions[i].Subj) + 1 = P) and (Length(Req.Extensions[i].Coeffs) >= 2) then
    begin
      SetLength(Result, Length(Req.Extensions[i].Coeffs));
      for k := 1 to High(Result) do
        Result[k] := Req.Extensions[i].Coeffs[k];
      Exit;
    end;
end;

{ Every structure slot of Req, the summaries and the measurement's three. }
procedure Populate(Map: TParamMap; const Req: TUncertRequest);
var
  i, j, p, Derived: Integer;
  S: TFitStructure;
  Repeats, PerPeriod: Boolean;
  D: Double;
begin
  S := Req.Structure;
  for i := 0 to High(S.Stacks) do
  begin
    Repeats := S.Stacks[i].N > 1;

    { Periodic: the thickest free thickness of a repeating stack follows
      from the period. }
    Derived := -1;
    if Repeats and (Req.Mode = fmPeriodic) then
      for j := 0 to High(S.Stacks[i].Layers) do
        if Free(S.Stacks[i].Layers[j].P[1]) and
           ((Derived < 0) or (S.Stacks[i].Layers[j].P[1].V > S.Stacks[i].Layers[Derived].P[1].V)) then
          Derived := j;

    for j := 0 to High(S.Stacks[i].Layers) do
      for p := 1 to 3 do
      begin
        if not Free(S.Stacks[i].Layers[j].P[p]) then
          Continue;
        if (p = 1) and (j = Derived) then
          Continue;
        PerPeriod := Repeats and not S.Stacks[i].Layers[j].P[p].Paired;
        if PerPeriod and (Req.Mode = fmTable) then
          Map.AddTable(SlotName(i, j, p), i, j, p)
        else if PerPeriod and (Req.Mode = fmProfile) then
          Map.AddProfile(SlotName(i, j, p), i, j, p, ProfileStart(Req, i, j, p))
        else
          Map.AddParam(SlotName(i, j, p), i, j, p);
      end;

    if Derived >= 0 then
    begin
      Map.SetDerived(SlotName(i, Derived, 1), i, Derived);
      if Req.FreePeriod then
      begin
        D := StackPeriodOf(S, i);
        Map.AddPeriod(Format('s%d.period', [i]), i, D * (1 - Req.PeriodWindow),
          D * (1 + Req.PeriodWindow));
      end;
    end;
  end;

  for i := 0 to High(S.Stacks) do
    if S.Stacks[i].N > 1 then
      Map.AddSummary(Format('s%d', [i]), i);
  Map.AddNuisance(SCALE_WINDOW_LOG, 0, Req.BackgroundMax, F_MIN, F_MAX);
end;

function NewMap(const Req: TUncertRequest): TParamMap;
begin
  { Profile mode keeps the tables BuildRequest wrote for the held graded
    values (HoldFrozenProfiles); every other table it has already dropped. }
  Result := TParamMap.Create(Req.Structure,
    ((Req.Mode = fmTable) and Req.KeepTables) or (Req.Mode = fmProfile));
  try
    Populate(Result, Req);
  except
    Result.Free;
    raise;
  end;
end;

{ 's3.l12.sigma[7]' -> stack 3, layer 12, P 2, period 7; False for any other shape. }
function ParseLayerName(const Name: string; out Stack, Layer, P, Period: Integer;
  out Coefficient: Boolean): Boolean;
var
  Parts: TArray<string>;
  Tail: string;
  k, q: Integer;
begin
  Result := False;
  Period := 0;
  Coefficient := False;
  Parts := Name.Split(['.']);
  if (Length(Parts) < 3) or not Parts[0].StartsWith('s') or not Parts[1].StartsWith('l') then
    Exit;
  if not TryStrToInt(Parts[0].Substring(1), Stack) or not TryStrToInt(Parts[1].Substring(1), Layer) then
    Exit;
  Tail := Parts[2];
  k := Tail.IndexOf('[');
  if k > 0 then
  begin
    if not TryStrToInt(Tail.Substring(k + 1).TrimRight([']']), Period) then
      Exit;
    Tail := Tail.Substring(0, k);
  end;
  P := 0;
  for q := 1 to 3 do
    if Tail = FIELD[q] then
      P := q;
  if P = 0 then
    Exit;
  Coefficient := (Length(Parts) = 4) and Parts[3].StartsWith('c');
  Result := (Length(Parts) = 3) or Coefficient;
end;

function Describe(const Name: string; const Req: TUncertRequest; Map: TParamMap): TUncertName;
var
  Stack, Layer, P, Period, i: Integer;
  Coefficient, Tabled, ThicknessSlot, HasDerived: Boolean;
  Tail: string;
begin
  Result := Default(TUncertName);
  Result.Name := Name;
  Result.Stack := -1;
  Result.Layer := -1;
  Result.P := -1;

  if Name.StartsWith('c0.') then
  begin
    Result.Kind := unMeasurement;
    Result.Group := 'Measurement';
    Tail := Name.Substring(3);
    if Tail = 'log10_scale' then
      Result.Caption := 'Scale, log10'
    else if Tail = 'scale' then
      Result.Caption := 'Scale'
    else if Tail = 'background' then
      Result.Caption := 'Background'
    else if Tail = 'ln_f' then
      Result.Caption := 'Noise floor, ln f'
    else
      Result.Caption := 'Noise floor f';
    Exit;
  end;

  if ParseLayerName(Name, Stack, Layer, P, Period, Coefficient) then
  begin
    Result.Stack := Stack;
    Result.Layer := Layer;
    Result.P := P;
    Result.Group := StackTitle(Req.Structure, Stack);
    Result.Caption := ValueCaption(Req.Structure, Stack, Layer, P);
    if Coefficient then
    begin
      Result.Kind := unCoefficient;
      Result.Caption := Result.Caption + ', profile ' + Name.Substring(Name.LastIndexOf('.') + 1);
    end
    else if Period > 0 then
    begin
      Result.Kind := unPeriodValue;
      Result.Period := Period;
      Result.Caption := Format('%s, period %d', [Result.Caption, Period]);
    end
    else
    begin
      Result.Kind := unValue;
      Result.CanHavePrior := True;
    end;
    Exit;
  end;

  { 's<k>.period', 's<k>.period_mean', 's<k>.total', 's<k>.drift' }
  Tail := Name.Substring(Name.IndexOf('.') + 1);
  if not TryStrToInt(Name.Substring(1, Name.IndexOf('.') - 1), Stack) then
    Stack := -1;
  Result.Stack := Stack;
  if Tail = 'period' then
  begin
    Result.Kind := unPeriod;
    Result.Group := StackTitle(Req.Structure, Stack);
    Result.Caption := 'Period, ' + ANGSTROM;
    Exit;
  end;
  Result.Kind := unSummary;
  Result.Group := 'Summary';
  Result.CanHavePrior := True;
  if Tail = 'period_mean' then
    Result.Caption := 'Mean period, ' + ANGSTROM
  else if Tail = 'total' then
    Result.Caption := 'Total thickness, ' + ANGSTROM
  else
    Result.Caption := 'Period drift, ' + ANGSTROM;
  if Length(Req.Structure.Stacks) > 1 then
    Result.Caption := StackTitle(Req.Structure, Stack) + ': ' + Result.Caption;

  { A stack whose every period is the same and whose period is not sampled
    has nothing to report an error on. }
  Tabled := False;
  ThicknessSlot := False;
  for i := 0 to Map.Count - 1 do
    if (Map.Slots[i].Stack = Stack) and (Map.Slots[i].P = 1) then
    begin
      if Map.Slots[i].Kind in [skTable, skPoly] then
        Tabled := True;
      if Map.Slots[i].Kind = skParam then
        ThicknessSlot := True;
    end;
  HasDerived := False;
  for i := 0 to High(Map.Derived) do
    if Map.Derived[i].Stack = Stack then
      HasDerived := True;
  if Tail = 'drift' then
    Result.Held := not Tabled
  else
    { the period stands still: a derived layer makes up for the free
      thicknesses, or no thickness is free at all }
    Result.Held := not Tabled and (Map.IndexOf(Format('s%d.period', [Stack])) < 0) and
      (HasDerived or not ThicknessSlot);
end;

{ Profile mode. TLFPSO_Poly gives every unpaired value of a repeating stack
  its polynomial whether it is free or not, and holds a frozen one at its
  gradient. A value the tool does not sample must therefore keep that
  gradient: it is written into the layer's table, which the model reads.
  Every table left over from an earlier table fit is dropped first. }
procedure HoldFrozenProfiles(var Req: TUncertRequest);
var
  i, j, p, k, q: Integer;
  C: TArray<Double>;
  V, Pw: Double;
  Graded: Boolean;
begin
  for i := 0 to High(Req.Structure.Stacks) do
    for j := 0 to High(Req.Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
      begin
        Req.Structure.Stacks[i].Layers[j].PP[p] := nil;
        if (Req.Structure.Stacks[i].N < 2) or Req.Structure.Stacks[i].Layers[j].P[p].Paired or
           Free(Req.Structure.Stacks[i].Layers[j].P[p]) then
          Continue;
        C := ProfileStart(Req, i, j, p);
        Graded := False;
        for q := 1 to High(C) do
          if C[q] <> 0 then
            Graded := True;
        if not Graded then
          Continue;
        SetLength(Req.Structure.Stacks[i].Layers[j].PP[p], Req.Structure.Stacks[i].N);
        for k := 1 to Req.Structure.Stacks[i].N do
        begin
          V := 0;
          Pw := 1;
          for q := 0 to High(C) do
          begin
            V := V + C[q] * Pw;
            Pw := Pw * (k - 1);
          end;
          Req.Structure.Stacks[i].Layers[j].PP[p][k - 1] := V;
        end;
      end;
end;

function BuildRequest(const P: TXRCXProject; out Req: TUncertRequest): string;
var
  Info: TStructureInfo;
  Map: TParamMap;
  Names: TArray<string>;
  i, Structural: Integer;
  MinR: Double;
begin
  Result := '';
  Req := Default(TUncertRequest);

  if P.CalcMode <> 0 then
    Exit('A wavelength scan cannot be analysed: the uncertainties need an angle scan.');
  if (P.DataID < 0) or not P.DataLinked or (Length(P.DataCurve) < 3) then
    Exit('The model has no measured curve linked to it. Link one in the main program and save the project.');

  try
    Req.Structure := StructureFromXRCData(P.XRCData, Info);
  except
    on E: Exception do
      Exit('The model''s structure could not be read: ' + E.Message);
  end;

  case P.Params.FitMode of
    0: Req.Mode := fmTable;
    2: Req.Mode := fmProfile;
  else
    Req.Mode := fmPeriodic;
  end;
  Req.Extensions := P.Extensions;
  Req.KeepTables := P.TableExtension;
  Req.FreePeriod := P.Params.LFPSO.FreePeriod;
  Req.PeriodWindow := P.Params.LFPSO.PeriodWindow;
  Req.Data := Copy(P.DataCurve);
  Req.RMin := P.Params.MinLimit;
  if Req.Mode = fmProfile then
    HoldFrozenProfiles(Req);

  MinR := Infinity;
  for i := 0 to High(Req.Data) do
    if (Req.Data[i].r > 0) and (Req.Data[i].r < MinR) then
      MinR := Req.Data[i].r;
  if IsInfinite(MinR) then
    Exit('The measured curve has no positive intensity.');
  Req.BackgroundMax := BACKGROUND_FACTOR * MinR;

  { As frame_CalcSettings.FillCalcThreadParams fills them for a fit. }
  Req.CalcParams := Default(TCalcThreadParams);
  Req.CalcParams.Mode := cmTheta;
  Req.CalcParams.Lambda := P.Params.Lambda;
  Req.CalcParams.StartT := Req.Data[0].t;
  Req.CalcParams.EndT := Req.Data[High(Req.Data)].t;
  Req.CalcParams.DT := P.Params.Width;
  Req.CalcParams.N := Length(Req.Data);
  if P.TwoTheta then
    Req.CalcParams.K := 2
  else
    Req.CalcParams.K := 1;
  if P.Params.Polarisation = 0 then
    Req.CalcParams.P := cmS
  else
    Req.CalcParams.P := cmSP;
  Req.CalcParams.RF := rfError;
  Req.CalcParams.MVAWindow := 10;

  try
    Map := NewMap(Req);
  except
    on E: EParamMap do
      Exit('The model cannot be analysed: ' + E.Message);
  end;
  try
    Structural := 0;
    for i := 0 to Map.Count - 1 do
    begin
      if not (Map.Slots[i].Kind in [skLogScale, skBackground, skLnF]) then
        Inc(Structural);
      if Map.Slots[i].Kind = skTable then
        Inc(Req.TableSlots);
    end;
    if Structural = 0 then
      Exit('Nothing in the model is free to vary: every value is fixed or has no range.');
    if Req.TableSlots > MAX_TABLE_SLOTS then
      Exit(Format('The model has %d per-period table values free; uncertainties can be given ' +
        'for at most %d. Fit it with a profile, or pair or fix some of the values.',
        [Req.TableSlots, MAX_TABLE_SLOTS]));
    Names := Map.ReportedNames;
    SetLength(Req.Names, Length(Names));
    for i := 0 to High(Names) do
      Req.Names[i] := Describe(Names[i], Req, Map);
  finally
    Map.Free;
  end;
end;

function BuildMap(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>): TParamMap;
var
  i: Integer;
begin
  Result := NewMap(Req);
  try
    for i := 0 to High(Priors) do
      Result.SetPrior(Priors[i].Name, Priors[i].Mean, Priors[i].SD);
  except
    Result.Free;
    raise;
  end;
end;

function StartProblem(Map: TParamMap; const Req: TUncertRequest): string;
var
  S: TFitStructure;
  Nuis: TNuisance;
  i, k: Integer;
  Caption: string;
  Fitted: Double;
begin
  Result := '';
  { A table entry starts inside its limits whatever the fit left (AddTable
    moves it there), so the fitted table is checked here: starting from a
    model that is not the fitted one must not pass in silence. }
  for i := 0 to Map.Count - 1 do
    if Map.Slots[i].Kind = skTable then
    begin
      Fitted := Req.Structure.Stacks[Map.Slots[i].Stack].Layers[Map.Slots[i].Layer].PeriodValue(
        Map.Slots[i].P, Map.Slots[i].Period, Req.Structure.Stacks[Map.Slots[i].Stack].N,
        Req.KeepTables);
      if not ((Fitted >= Map.Slots[i].Lower) and (Fitted <= Map.Slots[i].Upper)) then
      begin
        Caption := Map.Slots[i].Name;
        for k := 0 to High(Req.Names) do
          if Req.Names[k].Name = Map.Slots[i].Name then
            Caption := Format('%s (%s)', [Req.Names[k].Caption, Req.Names[k].Group]);
        Exit(Format('%s is %.5g, outside its limits %.5g to %.5g. Correct the value or its ' +
          'limits in the main program and fit again.',
          [Caption, Fitted, Map.Slots[i].Lower, Map.Slots[i].Upper]));
      end;
    end;
  Map.Template.CopyContent(S);
  if Map.Apply(Map.StartVector, S, Nuis) then
    Exit;
  for i := 0 to Map.Count - 1 do
    if not ((Map.Slots[i].Start >= Map.Slots[i].Lower) and (Map.Slots[i].Start <= Map.Slots[i].Upper)) then
    begin
      Caption := Map.Slots[i].Name;
      for k := 0 to High(Req.Names) do
        if Req.Names[k].Name = Map.Slots[i].Name then
          Caption := Format('%s (%s)', [Req.Names[k].Caption, Req.Names[k].Group]);
      Exit(Format('%s is %.5g, outside its limits %.5g to %.5g. Correct the value or its ' +
        'limits in the main program and fit again.',
        [Caption, Map.Slots[i].Start, Map.Slots[i].Lower, Map.Slots[i].Upper]));
    end;
  Result := 'The fitted model does not respect its own limits: a layer whose thickness follows ' +
    'from the period, or a profile, leaves its limits in some period. Fit again or widen the limits.';
end;

end.
