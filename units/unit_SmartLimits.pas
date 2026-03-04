(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_SmartLimits;

interface

uses
  System.SysUtils, unit_Types;

type
  TLimitIssueKind = (likNone, likError, likWarning);

  TLimitIssue = record
    Kind: TLimitIssueKind;
    ItemIndex: Integer;
    ParamIndex: Integer;  // 1..3 (H, S, Rho)
    Message: string;
  end;

const
  MAX_DENSITY = 23.0;  // Osmium — densest stable element

function ValidateLimits(const Structure: TFitStructure): TArray<TLimitIssue>;
procedure ClampToPhysics(var Structure: TFitStructure);
function HasErrors(const Issues: TArray<TLimitIssue>): Boolean;
function HasWarnings(const Issues: TArray<TLimitIssue>): Boolean;
function IssuesToText(const Issues: TArray<TLimitIssue>): string;
function CellState(const Issues: TArray<TLimitIssue>;
  ItemIndex, SubItemIndex: Integer): TLimitIssueKind;
procedure ApplyMaterialDensity(var Structure: TFitStructure;
  const NroValues: array of Single);
procedure ApplyGeometryCoupling(var Structure: TFitStructure);
procedure NarrowLimits(var Structure: TFitStructure; ShrinkFactor: Single);
procedure WidenAtLimit(var Structure: TFitStructure; ExpandFactor: Single);
procedure AutoFixErrors(var Structure: TFitStructure);

implementation

uses
  System.Math;

const
  ParamNames: array [1..3] of string = ('H', 'S', 'Rho');

procedure AddIssue(var Issues: TArray<TLimitIssue>;
  Kind: TLimitIssueKind; ItemIndex, ParamIndex: Integer; const Msg: string);
var
  Len: Integer;
begin
  Len := Length(Issues);
  SetLength(Issues, Len + 1);
  Issues[Len].Kind := Kind;
  Issues[Len].ItemIndex := ItemIndex;
  Issues[Len].ParamIndex := ParamIndex;
  Issues[Len].Message := Msg;
end;

function ValidateLimits(const Structure: TFitStructure): TArray<TLimitIssue>;
var
  i, j, p, Index: Integer;
  LayerName: string;
  FV: TFitValue;
  AllLocked: Boolean;
begin
  SetLength(Result, 0);
  AllLocked := True;

  Index := 0;
  for i := 0 to High(Structure.Stacks) do
  begin
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      LayerName := Structure.Stacks[i].Layers[j].Material;

      for p := 1 to 3 do
      begin
        FV := Structure.Stacks[i].Layers[j].P[p];

        if FV.min <> FV.max then
          AllLocked := False;

        // Min > Max
        if FV.min > FV.max then
          AddIssue(Result, likError, Index, p,
            Format('%s: %s min > max', [LayerName, ParamNames[p]]));

        // Value below min
        if FV.V < FV.min then
          AddIssue(Result, likWarning, Index, p,
            Format('%s: %s value below min', [LayerName, ParamNames[p]]));

        // Value above max
        if FV.V > FV.max then
          AddIssue(Result, likWarning, Index, p,
            Format('%s: %s value above max', [LayerName, ParamNames[p]]));

        // Range too wide
        if (FV.min > 0) and (FV.max / FV.min > 100) then
          AddIssue(Result, likWarning, Index, p,
            Format('%s: %s range very wide', [LayerName, ParamNames[p]]));

        // Range too narrow
        if (FV.min <> FV.max) and (FV.V <> 0) and
           (Abs(FV.max - FV.min) < 0.01 * Abs(FV.V)) then
          AddIssue(Result, likWarning, Index, p,
            Format('%s: %s range very narrow', [LayerName, ParamNames[p]]));

        // Value at limit (within 1% of range from boundary)
        if (FV.min <> FV.max) and (FV.max > FV.min) then
        begin
          if (FV.V - FV.min) < 0.01 * (FV.max - FV.min) then
            AddIssue(Result, likWarning, Index, p,
              Format('%s: %s value at lower limit', [LayerName, ParamNames[p]]));
          if (FV.max - FV.V) < 0.01 * (FV.max - FV.min) then
            AddIssue(Result, likWarning, Index, p,
              Format('%s: %s value at upper limit', [LayerName, ParamNames[p]]));
        end;

        // Physics: negative min for H, S, Rho
        if (p in [1, 2, 3]) and (FV.min < 0) then
          AddIssue(Result, likError, Index, p,
            Format('%s: %s min is negative', [LayerName, ParamNames[p]]));

        // Physics: Rho max exceeds densest element
        if (p = 3) and (FV.max > MAX_DENSITY) then
          AddIssue(Result, likWarning, Index, p,
            Format('%s: Rho max exceeds densest element (23 g/cm'#179')',
              [LayerName]));
      end;

      Inc(Index);
    end;
  end;

  // Global: nothing to fit
  if AllLocked and (Index > 0) then
    AddIssue(Result, likWarning, -1, 0,
      'All parameters are locked '#8212' nothing to fit');
end;

procedure ClampToPhysics(var Structure: TFitStructure);
var
  i, j, p: Integer;
begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
      begin
        // H and S: min >= 0
        if p in [1, 2] then
        begin
          if Structure.Stacks[i].Layers[j].P[p].min < 0 then
            Structure.Stacks[i].Layers[j].P[p].min := 0;
        end;

        // Rho: min >= 0, max <= MAX_DENSITY
        if p = 3 then
        begin
          if Structure.Stacks[i].Layers[j].P[p].min < 0 then
            Structure.Stacks[i].Layers[j].P[p].min := 0;
          if Structure.Stacks[i].Layers[j].P[p].max > MAX_DENSITY then
            Structure.Stacks[i].Layers[j].P[p].max := MAX_DENSITY;
        end;

        // Ensure value stays within clamped bounds
        if Structure.Stacks[i].Layers[j].P[p].V < Structure.Stacks[i].Layers[j].P[p].min then
          Structure.Stacks[i].Layers[j].P[p].V := Structure.Stacks[i].Layers[j].P[p].min;
        if Structure.Stacks[i].Layers[j].P[p].V > Structure.Stacks[i].Layers[j].P[p].max then
          Structure.Stacks[i].Layers[j].P[p].V := Structure.Stacks[i].Layers[j].P[p].max;
      end;
end;

function HasErrors(const Issues: TArray<TLimitIssue>): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(Issues) do
    if Issues[i].Kind = likError then
      Exit(True);
  Result := False;
end;

function HasWarnings(const Issues: TArray<TLimitIssue>): Boolean;
var
  i: Integer;
begin
  for i := 0 to High(Issues) do
    if Issues[i].Kind = likWarning then
      Exit(True);
  Result := False;
end;

function IssuesToText(const Issues: TArray<TLimitIssue>): string;
var
  i: Integer;
  Prefix: string;
begin
  Result := '';
  for i := 0 to High(Issues) do
  begin
    if Issues[i].Kind = likError then
      Prefix := 'ERROR: '
    else
      Prefix := 'Warning: ';

    if Result <> '' then
      Result := Result + #13#10;
    Result := Result + Prefix + Issues[i].Message;
  end;
end;

function CellState(const Issues: TArray<TLimitIssue>;
  ItemIndex, SubItemIndex: Integer): TLimitIssueKind;
var
  i, ParamIdx: Integer;
begin
  // SubItemIndex 0..5 maps to ParamIndex 1..3:
  //   0,1 -> param 1 (H min/max)
  //   2,3 -> param 2 (S min/max)
  //   4,5 -> param 3 (Rho min/max)
  ParamIdx := (SubItemIndex div 2) + 1;

  Result := likNone;

  for i := 0 to High(Issues) do
  begin
    if (Issues[i].ItemIndex = ItemIndex) and (Issues[i].ParamIndex = ParamIdx) then
    begin
      if Issues[i].Kind = likError then
        Exit(likError);
      Result := likWarning;
    end;
  end;
end;

procedure ApplyMaterialDensity(var Structure: TFitStructure;
  const NroValues: array of Single);
var
  i, j, Index: Integer;
begin
  Index := 0;
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      if (Index <= High(NroValues)) and (NroValues[Index] > 0) and
         (Structure.Stacks[i].Layers[j].P[3].V = 0) then
        Structure.Stacks[i].Layers[j].P[3].V := NroValues[Index];
      Inc(Index);
    end;
end;

procedure NarrowLimits(var Structure: TFitStructure; ShrinkFactor: Single);
var
  i, j, p: Integer;
begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
      begin
        // Skip locked params (min == max)
        if Structure.Stacks[i].Layers[j].P[p].min = Structure.Stacks[i].Layers[j].P[p].max then
          Continue;

        with Structure.Stacks[i].Layers[j].P[p] do
        begin
          min := V - (V - min) * ShrinkFactor;
          max := V + (max - V) * ShrinkFactor;
        end;
      end;
end;

procedure WidenAtLimit(var Structure: TFitStructure; ExpandFactor: Single);
var
  i, j, p: Integer;
  Range: Single;
begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
      begin
        with Structure.Stacks[i].Layers[j].P[p] do
        begin
          if (min = max) or (max <= min) then
            Continue;

          Range := max - min;

          if (V - min) < 0.01 * Range then
            min := min - Range * ExpandFactor;

          if (max - V) < 0.01 * Range then
            max := max + Range * ExpandFactor;
        end;
      end;
end;

procedure AutoFixErrors(var Structure: TFitStructure);
var
  i, j, p: Integer;
  Tmp: Single;
begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
        if Structure.Stacks[i].Layers[j].P[p].min > Structure.Stacks[i].Layers[j].P[p].max then
        begin
          Tmp := Structure.Stacks[i].Layers[j].P[p].min;
          Structure.Stacks[i].Layers[j].P[p].min := Structure.Stacks[i].Layers[j].P[p].max;
          Structure.Stacks[i].Layers[j].P[p].max := Tmp;
        end;
end;

procedure ApplyGeometryCoupling(var Structure: TFitStructure);
var
  i, j: Integer;
  H_self, H_below, Bound: Single;
begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      H_self := Structure.Stacks[i].Layers[j].P[1].V;

      if j > 0 then
        // Same stack, not first layer
        H_below := Structure.Stacks[i].Layers[j - 1].P[1].V
      else if Structure.Stacks[i].N > 1 then
        // Periodic stack, first layer — wraps to last layer
        H_below := Structure.Stacks[i].Layers[High(Structure.Stacks[i].Layers)].P[1].V
      else if i > 0 then
        // Non-periodic, cross-stack boundary
        H_below := Structure.Stacks[i - 1].Layers[High(Structure.Stacks[i - 1].Layers)].P[1].V
      else
        // First layer of first stack, non-periodic — substrate is semi-infinite
        H_below := MaxSingle;

      Bound := Min(H_self, H_below);
      if Structure.Stacks[i].Layers[j].P[2].max > Bound then
        Structure.Stacks[i].Layers[j].P[2].max := Bound;
    end;
end;

end.
