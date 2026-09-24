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
  /// A value this close to a bound, as a fraction of the range, is "at" it:
  /// the limits dialog flags it and Widen moves that bound. It is the lab
  /// fitting procedure's near_bound_fraction.
  NEAR_BOUND_FRACTION = 0.05;

{ The Henke table's bulk density of every layer, in the order the stacks and
  layers run (the order of TFitStructure.Total); 0 where the material has no
  table. It is the ceiling WidenAtLimit, AutoFixErrors and RecentreOnValue
  keep a density maximum under when it already sits at or below it. }
function BulkDensities(const Structure: TFitStructure): TArray<Single>;

function ValidateLimits(const Structure: TFitStructure): TArray<TLimitIssue>;
procedure ClampToPhysics(var Structure: TFitStructure);
function HasErrors(const Issues: TArray<TLimitIssue>): Boolean;
function HasWarnings(const Issues: TArray<TLimitIssue>): Boolean;
function IssuesToText(const Issues: TArray<TLimitIssue>): string;
function CellState(const Issues: TArray<TLimitIssue>;
  ItemIndex, SubItemIndex: Integer): TLimitIssueKind;

{ Column arithmetic for the limits dialog's list view. Its columns run Layer,
  then (Fix, min, max) per parameter, a stride of 3. Column is the 0-based
  column index the hit test returns; because column i holds subitem i - 1,
  that same number is what OnCustomDrawSubItem reports as SubItem, so one set
  of helpers serves both. }

{ 1..3 for the Fix column of H, S or Rho, 0 for any other column. }
function FreezeParamOf(const Column: Integer): Integer;

{ The index CellState expects: 0..5 over (Hmin, Hmax, Smin, Smax, Rmin, Rmax),
  or -1 for a Fix column, which carries no limit and is never validated. }
function LimitCellOf(const Column: Integer): Integer;

{ The SubItems index of the Fix cell governing the column's parameter:
  columns 1..3 -> 0, 4..6 -> 3, 7..9 -> 6. }
function FreezeCellOf(const Column: Integer): Integer;

procedure ApplyMaterialDensity(var Structure: TFitStructure;
  const NroValues: array of Single);
procedure ApplyGeometryCoupling(var Structure: TFitStructure);
procedure NarrowLimits(var Structure: TFitStructure; ShrinkFactor: Single);
procedure WidenAtLimit(var Structure: TFitStructure; ExpandFactor: Single;
  const Bulk: TArray<Single> = nil);
procedure AutoFixErrors(var Structure: TFitStructure; const Bulk: TArray<Single> = nil);

{ Pins every parameter marked Fixed to its current value by giving it an empty
  range. The optimizer needs no concept of freezing: Xrange = max - min = 0
  makes Rand(0) return 0 in XSeed and RangeSeed, and CheckLimits clamps to
  [Xmin, Xmax], so the value cannot move. Call this on the copy handed to the
  engine, never on a structure that is written back to the interface. }
procedure CollapseFixed(var Structure: TFitStructure);

{ Slides every free parameter's window so its current value sits at the centre,
  keeping the width it had. A value that ended hard against a boundary can then
  keep exploring past it. Frozen parameters keep their stored window - they are
  pinned by CollapseFixed at hand-off instead. A window that is already zero
  width re-centres to zero width and so stays pinned; only Fixed thaws.
  A window that would reach past a physical bound - min below zero, or Rho max
  above MAX_DENSITY - is slid back inside it with its width intact rather than
  truncated there. Truncating would cost half the window on every resume of a
  value sitting near the bound, and a few resumes later the parameter would be
  pinned with no Fixed flag to show for it. Only a window wider than the whole
  physical range still has to be shortened.
  A density maximum at or below the layer's bulk value (Bulk, from
  BulkDensities; nil for none) is a ceiling: the window slides down under it
  rather than past it.
  Apply ClampToPhysics afterwards. }
procedure RecentreOnValue(var Structure: TFitStructure; const Bulk: TArray<Single> = nil);

implementation

uses
  System.Math, math_globals, math_complex;

function BulkDensities(const Structure: TFitStructure): TArray<Single>;
var
  i, j, Index: Integer;
  f: TComplex;
  Na, Nro: Single;
begin
  SetLength(Result, Structure.Total);
  Index := 0;
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      Result[Index] := 0;
      try
        ReadHenke(Structure.Stacks[i].Layers[j].Material, 8000, 0, f, Na, Nro);
        Result[Index] := Nro;
      except
        on EInOutError do ;
      end;
      Inc(Index);
    end;
end;

{ The bulk ceiling of layer Index's density, or MaxSingle when there is none:
  no table, or a maximum already above bulk that the user set on purpose.
  The limits dialog shows and stores two decimals, so C's bulk 2.266 comes
  back from Initialize - or from a user typing what the dialog shows - as
  2.27. A maximum within that display rounding of bulk is the bulk ceiling,
  and is kept as it stands rather than shaved to the table's third decimal. }
function DensityCeiling(const Bulk: TArray<Single>; Index: Integer; CurrentMax: Single): Single;
const
  DISPLAY_ROUNDING = 0.005;   // half a unit in the dialog's second decimal
begin
  Result := MaxSingle;
  if (Index <= High(Bulk)) and (Bulk[Index] > 0) and
     (CurrentMax <= Bulk[Index] + DISPLAY_ROUNDING) then
    Result := System.Math.Max(Bulk[Index], CurrentMax);
end;

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
        if Structure.Stacks[i].Layers[j].P[p].Fixed then
          Continue;

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

        // Value at limit (within NEAR_BOUND_FRACTION of range from boundary)
        if (FV.min <> FV.max) and (FV.max > FV.min) then
        begin
          if (FV.V - FV.min) < NEAR_BOUND_FRACTION * (FV.max - FV.min) then
            AddIssue(Result, likWarning, Index, p,
              Format('%s: %s value at lower limit', [LayerName, ParamNames[p]]));
          if (FV.max - FV.V) < NEAR_BOUND_FRACTION * (FV.max - FV.min) then
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
        if Structure.Stacks[i].Layers[j].P[p].Fixed then
          Continue;

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

function FreezeParamOf(const Column: Integer): Integer;
begin
  if (Column >= 1) and ((Column - 1) mod 3 = 0) then
    Result := (Column - 1) div 3 + 1
  else
    Result := 0;
end;

function LimitCellOf(const Column: Integer): Integer;
var
  Group, Offset: Integer;
begin
  Group := (Column - 1) div 3;
  Offset := (Column - 1) mod 3;
  if Offset = 0 then
    Result := -1
  else
    Result := Group * 2 + (Offset - 1);
end;

function FreezeCellOf(const Column: Integer): Integer;
begin
  Result := ((Column - 1) div 3) * 3;
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
      if Structure.Stacks[i].Layers[j].P[3].Fixed then
      begin
        Inc(Index);
        Continue;
      end;

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
        if Structure.Stacks[i].Layers[j].P[p].Fixed then
          Continue;

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

procedure WidenAtLimit(var Structure: TFitStructure; ExpandFactor: Single;
  const Bulk: TArray<Single>);
var
  i, j, p, Index: Integer;
  Range, Ceiling: Single;
begin
  Index := -1;
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      Inc(Index);
      for p := 1 to 3 do
      begin
        if Structure.Stacks[i].Layers[j].P[p].Fixed then
          Continue;

        with Structure.Stacks[i].Layers[j].P[p] do
        begin
          if (min = max) or (max <= min) then
            Continue;

          Range := max - min;
          Ceiling := MaxSingle;
          if p = 3 then
            Ceiling := DensityCeiling(Bulk, Index, max);

          if (V - min) < NEAR_BOUND_FRACTION * Range then
            min := min - Range * ExpandFactor;

          { a density maximum held at bulk is not widened past it }
          if (max - V) < NEAR_BOUND_FRACTION * Range then
            max := System.Math.Min(max + Range * ExpandFactor, System.Math.Max(max, Ceiling));
        end;
      end;
    end;
end;

procedure AutoFixErrors(var Structure: TFitStructure; const Bulk: TArray<Single>);
var
  i, j, p, Index: Integer;
  Tmp, Ceiling: Single;
begin
  Index := -1;
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      Inc(Index);
      for p := 1 to 3 do
      begin
        if Structure.Stacks[i].Layers[j].P[p].Fixed then
          Continue;

        // Fix inverted min/max
        if Structure.Stacks[i].Layers[j].P[p].min > Structure.Stacks[i].Layers[j].P[p].max then
        begin
          Tmp := Structure.Stacks[i].Layers[j].P[p].min;
          Structure.Stacks[i].Layers[j].P[p].min := Structure.Stacks[i].Layers[j].P[p].max;
          Structure.Stacks[i].Layers[j].P[p].max := Tmp;
        end;

        // Fix value out of range. A density above a maximum held at bulk is
        // brought down to the bulk value instead of lifting the ceiling.
        with Structure.Stacks[i].Layers[j].P[p] do
        begin
          if V < min then
            min := V;
          if V > max then
          begin
            Ceiling := MaxSingle;
            if p = 3 then
              Ceiling := DensityCeiling(Bulk, Index, max);
            if V > Ceiling then
            begin
              max := Ceiling;
              V := Ceiling;
            end
            else
              max := V;
          end;
        end;
      end;
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
      if Structure.Stacks[i].Layers[j].P[2].Fixed then
        Continue;

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

procedure CollapseFixed(var Structure: TFitStructure);
var
  i, j, p: Integer;

  procedure Pin(var Value: TFitValue);
  begin
    if Value.Fixed then
    begin
      Value.min := Value.V;
      Value.max := Value.V;
    end;
  end;

begin
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
      for p := 1 to 3 do
        Pin(Structure.Stacks[i].Layers[j].P[p]);

  for p := 1 to 3 do
    Pin(Structure.Subs.P[p]);
end;

procedure RecentreOnValue(var Structure: TFitStructure; const Bulk: TArray<Single>);
var
  i, j, p, Index: Integer;
  Hi: Single;

  { The upper bound ClampToPhysics would enforce on this parameter. }
  function HiBound(const ParamIndex: Integer): Single;
  begin
    if ParamIndex = 3 then
      Result := MAX_DENSITY
    else
      Result := MaxSingle;
  end;

  procedure Recentre(var Value: TFitValue; const Lo, Hi: Single);
  var
    Width: Single;
  begin
    if Value.Fixed then
      Exit;
    Width := Value.max - Value.min;
    if Width <= 0 then
      Exit;

    Value.min := Value.V - Width / 2;
    Value.max := Value.V + Width / 2;

    { Slide, do not truncate: the width is what the next run gets to explore. }
    if Value.max > Hi then
    begin
      Value.max := Hi;
      Value.min := Hi - Width;
    end;
    if Value.min < Lo then
    begin
      Value.min := Lo;
      Value.max := Lo + Width;
    end;
    { Wider than the physical range itself - it has to give. }
    if Value.max > Hi then
      Value.max := Hi;
  end;

begin
  Index := -1;
  for i := 0 to High(Structure.Stacks) do
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      Inc(Index);
      for p := 1 to 3 do
      begin
        Hi := HiBound(p);
        if p = 3 then
          Hi := System.Math.Min(Hi, DensityCeiling(Bulk, Index, Structure.Stacks[i].Layers[j].P[p].max));
        Recentre(Structure.Stacks[i].Layers[j].P[p], 0, Hi);
      end;
    end;

  for p := 1 to 3 do
    Recentre(Structure.Subs.P[p], 0, HiBound(p));
end;

end.
