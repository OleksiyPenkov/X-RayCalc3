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

function ValidateLimits(const Structure: TFitStructure): TArray<TLimitIssue>;
function HasErrors(const Issues: TArray<TLimitIssue>): Boolean;
function HasWarnings(const Issues: TArray<TLimitIssue>): Boolean;
function IssuesToText(const Issues: TArray<TLimitIssue>): string;
function CellState(const Issues: TArray<TLimitIssue>;
  ItemIndex, SubItemIndex: Integer): TLimitIssueKind;

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
      end;

      Inc(Index);
    end;
  end;

  // Global: nothing to fit
  if AllLocked and (Index > 0) then
    AddIssue(Result, likWarning, -1, 0,
      'All parameters are locked '#8212' nothing to fit');
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

end.
