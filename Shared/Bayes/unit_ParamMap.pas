(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_ParamMap;

(* A fit as a flat vector (spec section 1). Slots, in the order they are added:
   free layer parameters, free periods, then the curve's nuisance parameters
   (log10 scale, background, ln f). The periodic engine's projection onto the
   period (NormalizeD) is replaced by a derived layer: its thickness is the
   period - held or sampled - minus the other thicknesses of the cell.

   A layer value that differs from period to period is a table
   (TLayerData.PP, read by FillLayeredModel through PeriodValue). AddTable
   makes every entry a slot; AddProfile makes the coefficients of a
   polynomial in the period number the slots and writes the table from them.

   Apply is the only way from a vector to a structure. It returns False for a
   vector outside any slot's bounds, or whose derived thickness leaves the
   derived layer's bounds or is not positive: the posterior is zero there. *)

interface

uses
  System.SysUtils, unit_Types, unit_Likelihood;

type
  TSlotKind = (skParam, skPeriod, skLogScale, skBackground, skLnF, skTable, skPoly);

  TParamSlot = record
    Name: string;
    Kind: TSlotKind;
    Stack, Layer, P: Integer;       // GUI indices; P 1 thickness, 2 sigma, 3 density
    Period: Integer;                // skTable: the period, from 1 (the surface); skPoly: the coefficient's order
    Lower, Upper, Start: Double;
    HasPrior: Boolean;
    PriorMean, PriorSD: Double;
  end;

  TDerivedLayer = record
    Name: string;
    Stack, Layer: Integer;
    Lower, Upper: Double;           // the derived thickness must stay inside these
    FixedD: Double;                 // the period when no period slot samples it
    HasPrior: Boolean;
    PriorMean, PriorSD: Double;
  end;

  /// <summary>A polynomial profile: slots First .. First + Count - 1 are its
  /// coefficients c0 .. c(Count-1); period k of N takes sum c_i (k - 1)^i,
  /// which must stay inside Lower .. Upper in every period.</summary>
  TPolyGroup = record
    Name: string;
    Stack, Layer, P: Integer;
    First, Count, N: Integer;
    Lower, Upper: Double;
  end;

  TSummaryKind = (smPeriodMean, smTotal, smDrift);

  /// <summary>A number of a whole repeating stack, reported with every
  /// sample: the mean period, the total thickness, or the last period's
  /// thickness minus the first's (period 1 is at the surface).</summary>
  TStackSummary = record
    Name: string;
    Stack: Integer;
    Kind: TSummaryKind;
    HasPrior: Boolean;
    PriorMean, PriorSD: Double;
  end;

  EParamMap = class(Exception);

  TParamMap = class
  private
    FTemplate: TFitStructure;
    FSlots: TArray<TParamSlot>;
    FDerived: TArray<TDerivedLayer>;
    FPoly: TArray<TPolyGroup>;
    FSummaries: TArray<TStackSummary>;
    FFMin: Double;
    function GetSlot(i: Integer): TParamSlot;
    procedure AddSlot(const Slot: TParamSlot);
    function PolyValue(const G: TPolyGroup; const Theta: array of Double; Period: Integer): Double;
    function SummaryValue(const S: TFitStructure; const Sm: TStackSummary): Double;
    { A derived layer and a period slot hold or sample ONE period of a stack;
      a thickness table or profile gives every period its own. The two do not
      go together: each raises when the other is already there. }
    procedure CheckOnePeriod(const Name: string; Stack: Integer);
    procedure CheckNoPeriod(const Name: string; Stack, P: Integer);
  public
    /// <summary>The map of a copy of Template. Its per-period tables are
    /// dropped unless KeepTables: a structure fitted periodically may still
    /// carry a table from an earlier table fit, which the periodic model does
    /// not read. Pass True for a structure fitted in table mode; AddTable and
    /// AddProfile then put back the tables they sample.</summary>
    constructor Create(const Template: TFitStructure; KeepTables: Boolean = False);
    procedure AddParam(const Name: string; Stack, Layer, P: Integer);
    procedure AddPeriod(const Name: string; Stack: Integer; Lower, Upper: Double);
    /// <summary>One slot per period for the value P of a layer of a repeating
    /// stack, named Name[1] .. Name[N], period 1 at the surface. Each starts at
    /// its table entry (the layer's own value when the table is missing or
    /// shorter than N), moved into the layer's limits.</summary>
    procedure AddTable(const Name: string; Stack, Layer, P: Integer);
    /// <summary>The value P of a layer of a repeating stack as a polynomial in
    /// the period number: slots Name.c0 .. Name.c<order>, starting at C. c0
    /// keeps the layer's limits; the higher orders get bounds wide enough for
    /// any polynomial that stays inside those limits in every period, which
    /// Apply checks. The resulting values are reported as Name[1] .. Name[N].
    /// A coefficient cannot take a prior; a summary of the stack can.</summary>
    procedure AddProfile(const Name: string; Stack, Layer, P: Integer; const C: array of Double);
    /// <summary>Reports Prefix.period_mean, Prefix.total and Prefix.drift of a
    /// repeating stack, last in ReportedNames. SetPrior takes those names.</summary>
    procedure AddSummary(const Prefix: string; Stack: Integer);
    procedure SetDerived(const Name: string; Stack, Layer: Integer);
    procedure AddNuisance(ScaleWindowLog, BgMin, BgMax, FMin, FMax: Double);
    procedure SetPrior(const Name: string; Mean, SD: Double);
    function Count: Integer;
    function IndexOf(const Name: string): Integer;
    function StartVector: TArray<Double>;
    function Apply(const Theta: array of Double; var S: TFitStructure;
      out Nuis: TNuisance): Boolean;
    function PriorTerm(const Theta: array of Double; const S: TFitStructure): Double;
    function ReportedNames: TArray<string>;
    function ReportedValues(const Theta: array of Double; out Values: TArray<Double>): Boolean;
    property Slots[i: Integer]: TParamSlot read GetSlot;
    property Derived: TArray<TDerivedLayer> read FDerived;
    property Template: TFitStructure read FTemplate;
    property FMin: Double read FFMin;
  end;

implementation

uses
  System.Math;

const
  F_START = 0.05;

function StackPeriod(const S: TFitStructure; Stack: Integer): Double;
var
  k: Integer;
begin
  Result := 0;
  for k := 0 to High(S.Stacks[Stack].Layers) do
    Result := Result + S.Stacks[Stack].Layers[k].P[1].V;
end;

constructor TParamMap.Create(const Template: TFitStructure; KeepTables: Boolean);
var
  i, j, p: Integer;
begin
  inherited Create;
  Template.CopyContent(FTemplate);
  if not KeepTables then
    for i := 0 to High(FTemplate.Stacks) do
      for j := 0 to High(FTemplate.Stacks[i].Layers) do
        for p := 1 to 3 do
          FTemplate.Stacks[i].Layers[j].PP[p] := nil;
end;

/// A thickness of Stack that differs from period to period: a table the
/// model reads (held or sampled), or a profile.
function HasThicknessTable(const S: TFitStructure; Stack: Integer): Boolean;
var
  k: Integer;
begin
  Result := False;
  if S.Stacks[Stack].N < 2 then
    Exit;
  for k := 0 to High(S.Stacks[Stack].Layers) do
    if not S.Stacks[Stack].Layers[k].P[1].Paired and
       (Length(S.Stacks[Stack].Layers[k].PP[1]) >= S.Stacks[Stack].N) then
      Exit(True);
end;

function TParamMap.GetSlot(i: Integer): TParamSlot;
begin
  Result := FSlots[i];
end;

procedure TParamMap.AddSlot(const Slot: TParamSlot);
begin
  if IndexOf(Slot.Name) >= 0 then
    raise EParamMap.CreateFmt('The slot "%s" is already in the map', [Slot.Name]);
  FSlots := FSlots + [Slot];
end;

function TParamMap.Count: Integer;
begin
  Result := Length(FSlots);
end;

function TParamMap.IndexOf(const Name: string): Integer;
var
  i: Integer;
begin
  for i := 0 to High(FSlots) do
    if SameText(FSlots[i].Name, Name) then
      Exit(i);
  Result := -1;
end;

procedure TParamMap.AddParam(const Name: string; Stack, Layer, P: Integer);
var
  Slot: TParamSlot;
  V: TFitValue;
begin
  V := FTemplate.Stacks[Stack].Layers[Layer].P[P];
  if V.min > V.max then
    raise EParamMap.CreateFmt('"%s": the lower bound is above the upper one', [Name]);
  Slot := Default(TParamSlot);
  Slot.Name := Name;
  Slot.Kind := skParam;
  Slot.Stack := Stack;
  Slot.Layer := Layer;
  Slot.P := P;
  Slot.Lower := V.min;
  Slot.Upper := V.max;
  Slot.Start := V.V;
  AddSlot(Slot);
  { One slot is one value in every period: a table kept for this value would
    be what the model reads, and the slot would move nothing. }
  FTemplate.Stacks[Stack].Layers[Layer].PP[P] := nil;
end;

procedure TParamMap.CheckOnePeriod(const Name: string; Stack: Integer);
begin
  if HasThicknessTable(FTemplate, Stack) then
    raise EParamMap.CreateFmt('"%s": the stack has a thickness that differs from period to ' +
      'period, so its period is not one number', [Name]);
end;

procedure TParamMap.CheckNoPeriod(const Name: string; Stack, P: Integer);
var
  i: Integer;
begin
  if P <> 1 then
    Exit;
  for i := 0 to High(FDerived) do
    if FDerived[i].Stack = Stack then
      raise EParamMap.CreateFmt('"%s": the stack has a derived layer, which needs one period', [Name]);
  for i := 0 to High(FSlots) do
    if (FSlots[i].Kind = skPeriod) and (FSlots[i].Stack = Stack) then
      raise EParamMap.CreateFmt('"%s": the stack has a period slot, which needs one period', [Name]);
end;

procedure TParamMap.AddPeriod(const Name: string; Stack: Integer; Lower, Upper: Double);
var
  Slot: TParamSlot;
begin
  if not (Lower < Upper) or (Lower <= 0) then
    raise EParamMap.CreateFmt('"%s": the period range must be 0 < min < max', [Name]);
  CheckOnePeriod(Name, Stack);
  Slot := Default(TParamSlot);
  Slot.Name := Name;
  Slot.Kind := skPeriod;
  Slot.Stack := Stack;
  Slot.Layer := -1;
  Slot.Lower := Lower;
  Slot.Upper := Upper;
  Slot.Start := EnsureRange(StackPeriod(FTemplate, Stack), Lower, Upper);
  AddSlot(Slot);
end;

procedure TParamMap.AddTable(const Name: string; Stack, Layer, P: Integer);
var
  Slot: TParamSlot;
  V: TFitValue;
  T: TFloatArray;
  k, N: Integer;
begin
  V := FTemplate.Stacks[Stack].Layers[Layer].P[P];
  N := FTemplate.Stacks[Stack].N;
  if N < 2 then
    raise EParamMap.CreateFmt('"%s": a table needs a repeating stack', [Name]);
  if V.Paired then
    raise EParamMap.CreateFmt('"%s": a paired parameter has one value, not a table', [Name]);
  if V.min > V.max then
    raise EParamMap.CreateFmt('"%s": the lower bound is above the upper one', [Name]);
  CheckNoPeriod(Name, Stack, P);
  SetLength(T, N);
  for k := 1 to N do
    T[k - 1] := EnsureRange(FTemplate.Stacks[Stack].Layers[Layer].PeriodValue(P, k, N, True),
      V.min, V.max);
  FTemplate.Stacks[Stack].Layers[Layer].PP[P] := T;
  for k := 1 to N do
  begin
    Slot := Default(TParamSlot);
    Slot.Name := Format('%s[%d]', [Name, k]);
    Slot.Kind := skTable;
    Slot.Stack := Stack;
    Slot.Layer := Layer;
    Slot.P := P;
    Slot.Period := k;
    Slot.Lower := V.min;
    Slot.Upper := V.max;
    Slot.Start := T[k - 1];
    AddSlot(Slot);
  end;
end;

function TParamMap.PolyValue(const G: TPolyGroup; const Theta: array of Double; Period: Integer): Double;
var
  j: Integer;
  Pw: Double;
begin
  { math_globals.Poly's polynomial, here in Double and without that unit's
    VCL baggage: sum c_j (Period - 1)^j. }
  Result := 0;
  Pw := 1;
  for j := 0 to G.Count - 1 do
  begin
    Result := Result + Theta[G.First + j] * Pw;
    Pw := Pw * (Period - 1);
  end;
end;

procedure TParamMap.AddProfile(const Name: string; Stack, Layer, P: Integer; const C: array of Double);
var
  Slot: TParamSlot;
  V: TFitValue;
  G: TPolyGroup;
  j, N: Integer;
  W: Double;
begin
  V := FTemplate.Stacks[Stack].Layers[Layer].P[P];
  N := FTemplate.Stacks[Stack].N;
  if N < 2 then
    raise EParamMap.CreateFmt('"%s": a profile needs a repeating stack', [Name]);
  if V.Paired then
    raise EParamMap.CreateFmt('"%s": a paired parameter has one value, not a profile', [Name]);
  if not (V.min < V.max) then
    raise EParamMap.CreateFmt('"%s": a held value is not sampled', [Name]);
  if Length(C) < 2 then
    raise EParamMap.CreateFmt('"%s": a profile needs at least a gradient', [Name]);
  for j := 0 to High(C) do
    if IsNan(C[j]) or IsInfinite(C[j]) then
      raise EParamMap.CreateFmt('"%s": coefficient %d is not a number', [Name, j]);
  CheckNoPeriod(Name, Stack, P);

  G := Default(TPolyGroup);
  G.Name := Name;
  G.Stack := Stack;
  G.Layer := Layer;
  G.P := P;
  G.First := Length(FSlots);
  G.Count := Length(C);
  G.N := N;
  G.Lower := V.min;
  G.Upper := V.max;

  for j := 0 to High(C) do
  begin
    Slot := Default(TParamSlot);
    Slot.Name := Format('%s.c%d', [Name, j]);
    Slot.Kind := skPoly;
    Slot.Stack := Stack;
    Slot.Layer := Layer;
    Slot.P := P;
    Slot.Period := j;
    Slot.Start := C[j];
    if j = 0 then
    begin
      Slot.Lower := V.min;
      Slot.Upper := V.max;
    end
    else
    begin
      { Wide enough for every polynomial of this order that stays inside the
        limits: by V. A. Markov's theorem its coefficients are largest for the
        Chebyshev polynomial, whose grow slower than 6^order / 2 on the unit
        interval. What decides feasibility is the per-period check in Apply;
        this box only has to contain it. }
      W := Max((V.max - V.min) * Power(6, High(C)) / Power(N - 1, j), 2 * Abs(C[j]));
      Slot.Lower := -W;
      Slot.Upper := W;
    end;
    AddSlot(Slot);
  end;
  SetLength(FTemplate.Stacks[Stack].Layers[Layer].PP[P], N);
  FPoly := FPoly + [G];
end;

function PeriodThickness(const S: TFitStructure; Stack, Period: Integer): Double;
var
  k: Integer;
begin
  Result := 0;
  for k := 0 to High(S.Stacks[Stack].Layers) do
    Result := Result + S.Stacks[Stack].Layers[k].PeriodValue(1, Period, S.Stacks[Stack].N, True);
end;

function TParamMap.SummaryValue(const S: TFitStructure; const Sm: TStackSummary): Double;
var
  k, N: Integer;
begin
  N := S.Stacks[Sm.Stack].N;
  if Sm.Kind = smDrift then
    Exit(PeriodThickness(S, Sm.Stack, N) - PeriodThickness(S, Sm.Stack, 1));
  Result := 0;
  for k := 1 to N do
    Result := Result + PeriodThickness(S, Sm.Stack, k);
  if Sm.Kind = smPeriodMean then
    Result := Result / N;
end;

procedure TParamMap.AddSummary(const Prefix: string; Stack: Integer);
const
  Suffix: array [TSummaryKind] of string = ('.period_mean', '.total', '.drift');
var
  Sm: TStackSummary;
  K: TSummaryKind;
begin
  if FTemplate.Stacks[Stack].N < 2 then
    raise EParamMap.CreateFmt('"%s": a summary needs a repeating stack', [Prefix]);
  for K := Low(TSummaryKind) to High(TSummaryKind) do
  begin
    Sm := Default(TStackSummary);
    Sm.Name := Prefix + Suffix[K];
    Sm.Stack := Stack;
    Sm.Kind := K;
    FSummaries := FSummaries + [Sm];
  end;
end;

procedure TParamMap.SetDerived(const Name: string; Stack, Layer: Integer);
var
  i, j: Integer;
  D: TDerivedLayer;
begin
  for i := 0 to High(FDerived) do
    if FDerived[i].Stack = Stack then
      raise EParamMap.CreateFmt('Stack %d already has a derived layer', [Stack]);
  CheckOnePeriod(Name, Stack);
  { The derived thickness follows from the others: it cannot be a slot too. }
  for i := High(FSlots) downto 0 do
    if (FSlots[i].Kind = skParam) and (FSlots[i].Stack = Stack) and
       (FSlots[i].Layer = Layer) and (FSlots[i].P = 1) then
    begin
      Delete(FSlots, i, 1);
      for j := 0 to High(FPoly) do
        if FPoly[j].First > i then
          Dec(FPoly[j].First);
    end;
  D := Default(TDerivedLayer);
  D.Name := Name;
  D.Stack := Stack;
  D.Layer := Layer;
  D.Lower := FTemplate.Stacks[Stack].Layers[Layer].P[1].min;
  D.Upper := FTemplate.Stacks[Stack].Layers[Layer].P[1].max;
  D.FixedD := StackPeriod(FTemplate, Stack);
  FDerived := FDerived + [D];
end;

procedure TParamMap.AddNuisance(ScaleWindowLog, BgMin, BgMax, FMin, FMax: Double);
var
  Slot: TParamSlot;
begin
  if ScaleWindowLog < 0 then
    raise EParamMap.Create('The scale window must not be negative');
  if (BgMin < 0) or (BgMax < BgMin) then
    raise EParamMap.Create('The background range must be 0 <= min <= max');
  if (FMin <= 0) or (FMax < FMin) then
    raise EParamMap.Create('The f range must be 0 < min <= max');
  FFMin := FMin;

  Slot := Default(TParamSlot);
  Slot.Stack := -1; Slot.Layer := -1;

  Slot.Name := 'c0.log10_scale';
  Slot.Kind := skLogScale;
  Slot.Lower := -ScaleWindowLog;
  Slot.Upper := ScaleWindowLog;
  Slot.Start := 0;
  AddSlot(Slot);

  Slot.Name := 'c0.background';
  Slot.Kind := skBackground;
  Slot.Lower := BgMin;
  Slot.Upper := BgMax;
  Slot.Start := BgMin;
  AddSlot(Slot);

  Slot.Name := 'c0.ln_f';
  Slot.Kind := skLnF;
  Slot.Lower := Ln(FMin);
  Slot.Upper := Ln(FMax);
  Slot.Start := Ln(EnsureRange(F_START, FMin, FMax));
  AddSlot(Slot);
end;

procedure TParamMap.SetPrior(const Name: string; Mean, SD: Double);
var
  i: Integer;
begin
  if not (SD > 0) then
    raise EParamMap.CreateFmt('"%s": a prior needs sd > 0', [Name]);
  i := IndexOf(Name);
  if (i >= 0) and (FSlots[i].Kind = skParam) then
  begin
    FSlots[i].HasPrior := True;
    FSlots[i].PriorMean := Mean;
    FSlots[i].PriorSD := SD;
    Exit;
  end;
  for i := 0 to High(FDerived) do
    if SameText(FDerived[i].Name, Name) then
    begin
      FDerived[i].HasPrior := True;
      FDerived[i].PriorMean := Mean;
      FDerived[i].PriorSD := SD;
      Exit;
    end;
  for i := 0 to High(FSummaries) do
    if SameText(FSummaries[i].Name, Name) then
    begin
      FSummaries[i].HasPrior := True;
      FSummaries[i].PriorMean := Mean;
      FSummaries[i].PriorSD := SD;
      Exit;
    end;
  raise EParamMap.CreateFmt('"%s" is not a free layer parameter or a summary of this fit', [Name]);
end;

function TParamMap.StartVector: TArray<Double>;
var
  i: Integer;
begin
  SetLength(Result, Length(FSlots));
  for i := 0 to High(FSlots) do
    Result[i] := FSlots[i].Start;
end;

function TParamMap.Apply(const Theta: array of Double; var S: TFitStructure;
  out Nuis: TNuisance): Boolean;
var
  i, j, k, g: Integer;
  D: TArray<Double>;
  Period, Sum, H: Double;
begin
  Result := False;
  Nuis := Default(TNuisance);
  Nuis.F := FFMin;
  SetLength(D, Length(S.Stacks));
  for k := 0 to High(D) do
    D[k] := -1;

  for i := 0 to High(FSlots) do
  begin
    { Positive form: a NaN component compares False against both sides of a
      range, so the naive < / > test would fall through as "inside" it.
      Written this way, NaN is infeasible like anything else outside the slot. }
    if not ((Theta[i] >= FSlots[i].Lower) and (Theta[i] <= FSlots[i].Upper)) then
      Exit;
    case FSlots[i].Kind of
      skParam:
        S.Stacks[FSlots[i].Stack].Layers[FSlots[i].Layer].P[FSlots[i].P].V := Theta[i];
      skPeriod:
        D[FSlots[i].Stack] := Theta[i];
      skLogScale:
        Nuis.LogScale := Theta[i];
      skBackground:
        Nuis.Background := Theta[i];
      skLnF:
        Nuis.F := Exp(Theta[i]);
      skTable:
        S.Stacks[FSlots[i].Stack].Layers[FSlots[i].Layer].PP[FSlots[i].P][FSlots[i].Period - 1] := Theta[i];
      skPoly:
        ;   // read by the profile pass below
    end;
  end;

  for g := 0 to High(FPoly) do
  begin
    for k := 1 to FPoly[g].N do
    begin
      H := PolyValue(FPoly[g], Theta, k);
      { Positive form: NaN is outside. }
      if not ((H >= FPoly[g].Lower) and (H <= FPoly[g].Upper)) then
        Exit;
      S.Stacks[FPoly[g].Stack].Layers[FPoly[g].Layer].PP[FPoly[g].P][k - 1] := H;
    end;
    S.Stacks[FPoly[g].Stack].Layers[FPoly[g].Layer].P[FPoly[g].P].V := Theta[FPoly[g].First];
  end;

  for j := 0 to High(FDerived) do
  begin
    if D[FDerived[j].Stack] < 0 then
      Period := FDerived[j].FixedD
    else
      Period := D[FDerived[j].Stack];
    Sum := 0;
    for k := 0 to High(S.Stacks[FDerived[j].Stack].Layers) do
      if k <> FDerived[j].Layer then
        Sum := Sum + S.Stacks[FDerived[j].Stack].Layers[k].P[1].V;
    H := Period - Sum;
    if (H <= 0) or (H < FDerived[j].Lower) or (H > FDerived[j].Upper) then
      Exit;
    S.Stacks[FDerived[j].Stack].Layers[FDerived[j].Layer].P[1].V := H;
  end;
  Result := True;
end;

function TParamMap.ReportedNames: TArray<string>;
var
  i, k, IdxScale, IdxF: Integer;
begin
  SetLength(Result, Length(FSlots));
  for i := 0 to High(FSlots) do
    Result[i] := FSlots[i].Name;
  IdxScale := IndexOf('c0.log10_scale');
  IdxF := IndexOf('c0.ln_f');
  if (IdxScale >= 0) and (IdxF >= 0) then
    Result := Result + ['c0.scale', 'c0.f'];
  for i := 0 to High(FDerived) do
    Result := Result + [FDerived[i].Name];
  for i := 0 to High(FPoly) do
    for k := 1 to FPoly[i].N do
      Result := Result + [Format('%s[%d]', [FPoly[i].Name, k])];
  for i := 0 to High(FSummaries) do
    Result := Result + [FSummaries[i].Name];
end;

function TParamMap.ReportedValues(const Theta: array of Double; out Values: TArray<Double>): Boolean;
var
  S: TFitStructure;
  Nuis: TNuisance;
  i, k, n, IdxScale, IdxF: Integer;
begin
  Values := nil;
  FTemplate.CopyContent(S);
  if not Apply(Theta, S, Nuis) then
    Exit(False);
  IdxScale := IndexOf('c0.log10_scale');
  IdxF := IndexOf('c0.ln_f');
  n := Length(FSlots) + Ord((IdxScale >= 0) and (IdxF >= 0)) * 2 + Length(FDerived);
  for i := 0 to High(FPoly) do
    Inc(n, FPoly[i].N);
  Inc(n, Length(FSummaries));
  SetLength(Values, n);
  for i := 0 to High(FSlots) do
    Values[i] := Theta[i];
  n := Length(FSlots);
  if (IdxScale >= 0) and (IdxF >= 0) then
  begin
    Values[n] := Power(10, Theta[IdxScale]);
    Values[n + 1] := Exp(Theta[IdxF]);
    Inc(n, 2);
  end;
  for i := 0 to High(FDerived) do
  begin
    Values[n] := S.Stacks[FDerived[i].Stack].Layers[FDerived[i].Layer].P[1].V;
    Inc(n);
  end;
  for i := 0 to High(FPoly) do
    for k := 1 to FPoly[i].N do
    begin
      Values[n] := S.Stacks[FPoly[i].Stack].Layers[FPoly[i].Layer].PP[FPoly[i].P][k - 1];
      Inc(n);
    end;
  for i := 0 to High(FSummaries) do
  begin
    Values[n] := SummaryValue(S, FSummaries[i]);
    Inc(n);
  end;
  Result := True;
end;

function TParamMap.PriorTerm(const Theta: array of Double; const S: TFitStructure): Double;
var
  i: Integer;
begin
  Result := 0;
  for i := 0 to High(FSlots) do
    if FSlots[i].HasPrior then
      Result := Result + Sqr((Theta[i] - FSlots[i].PriorMean) / FSlots[i].PriorSD);
  for i := 0 to High(FDerived) do
    if FDerived[i].HasPrior then
      Result := Result + Sqr((S.Stacks[FDerived[i].Stack].Layers[FDerived[i].Layer].P[1].V -
        FDerived[i].PriorMean) / FDerived[i].PriorSD);
  for i := 0 to High(FSummaries) do
    if FSummaries[i].HasPrior then
      Result := Result + Sqr((SummaryValue(S, FSummaries[i]) - FSummaries[i].PriorMean) /
        FSummaries[i].PriorSD);
end;

end.
