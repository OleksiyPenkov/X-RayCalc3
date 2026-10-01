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

   Apply is the only way from a vector to a structure. It returns False for a
   vector outside any slot's bounds, or whose derived thickness leaves the
   derived layer's bounds or is not positive: the posterior is zero there. *)

interface

uses
  System.SysUtils, unit_Types, unit_Likelihood;

type
  TSlotKind = (skParam, skPeriod, skLogScale, skBackground, skLnF);

  TParamSlot = record
    Name: string;
    Kind: TSlotKind;
    Stack, Layer, P: Integer;       // GUI indices; P 1 thickness, 2 sigma, 3 density
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

  EParamMap = class(Exception);

  TParamMap = class
  private
    FTemplate: TFitStructure;
    FSlots: TArray<TParamSlot>;
    FDerived: TArray<TDerivedLayer>;
    FFMin: Double;
    function GetSlot(i: Integer): TParamSlot;
    procedure AddSlot(const Slot: TParamSlot);
  public
    constructor Create(const Template: TFitStructure);
    procedure AddParam(const Name: string; Stack, Layer, P: Integer);
    procedure AddPeriod(const Name: string; Stack: Integer; Lower, Upper: Double);
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

constructor TParamMap.Create(const Template: TFitStructure);
begin
  inherited Create;
  Template.CopyContent(FTemplate);
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
end;

procedure TParamMap.AddPeriod(const Name: string; Stack: Integer; Lower, Upper: Double);
var
  Slot: TParamSlot;
begin
  if not (Lower < Upper) or (Lower <= 0) then
    raise EParamMap.CreateFmt('"%s": the period range must be 0 < min < max', [Name]);
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

procedure TParamMap.SetDerived(const Name: string; Stack, Layer: Integer);
var
  i: Integer;
  D: TDerivedLayer;
begin
  for i := 0 to High(FDerived) do
    if FDerived[i].Stack = Stack then
      raise EParamMap.CreateFmt('Stack %d already has a derived layer', [Stack]);
  { The derived thickness follows from the others: it cannot be a slot too. }
  for i := High(FSlots) downto 0 do
    if (FSlots[i].Kind = skParam) and (FSlots[i].Stack = Stack) and
       (FSlots[i].Layer = Layer) and (FSlots[i].P = 1) then
      Delete(FSlots, i, 1);
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
  raise EParamMap.CreateFmt('"%s" is not a free layer parameter of this fit', [Name]);
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
  i, j, k: Integer;
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
    end;
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
  i, IdxScale, IdxF: Integer;
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
end;

function TParamMap.ReportedValues(const Theta: array of Double; out Values: TArray<Double>): Boolean;
var
  S: TFitStructure;
  Nuis: TNuisance;
  i, n, IdxScale, IdxF: Integer;
begin
  Values := nil;
  FTemplate.CopyContent(S);
  if not Apply(Theta, S, Nuis) then
    Exit(False);
  IdxScale := IndexOf('c0.log10_scale');
  IdxF := IndexOf('c0.ln_f');
  SetLength(Values, Length(FSlots) + Ord((IdxScale >= 0) and (IdxF >= 0)) * 2 + Length(FDerived));
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
    Values[n + i] := S.Stacks[FDerived[i].Stack].Layers[FDerived[i].Layer].P[1].V;
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
end;

end.
