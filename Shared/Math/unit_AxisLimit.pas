(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

{ The logarithmic axis limit is also passed to the calculation engine,
  so invalid free-text input must be rejected before either assignment. }

unit unit_AxisLimit;

interface

const
  AXIS_LIMIT_ITEMS: array [0 .. 9] of string = (
    '1E-3', '1E-4', '1E-5', '1E-6', '1E-7',
    '1E-8', '1E-9', '1E-10', '1E-11', '1E-12');

  DEFAULT_AXIS_LIMIT = 1E-7;
  DEFAULT_AXIS_LIMIT_TEXT = '1E-7';

function TryParseAxisLimit(const AText: string; const AAxisMaximum: Single;
  out AValue: Single): Boolean;

function AxisLimitToText(const AValue: Single): string;

implementation

uses
  System.SysUtils, System.Math;

var
  InvariantFormat: TFormatSettings;

function TryParseAxisLimit(const AText: string; const AAxisMaximum: Single;
  out AValue: Single): Boolean;
var
  S: string;
  V: Double;
begin
  AValue := 0;

  S := Trim(AText);
  if S = '' then
    Exit(False);

  // The user types whatever decimal separator their keyboard gives them, so
  // normalise to '.' and parse with invariant settings rather than letting the
  // machine's locale decide whether '3,5E-8' is a number.
  S := StringReplace(S, ',', '.', [rfReplaceAll]);

  if not TryStrToFloat(S, V, InvariantFormat) then
    Exit(False);

  if IsNan(V) or IsInfinite(V) then
    Exit(False);

  if (V <= 0) or (V >= AAxisMaximum) then
    Exit(False);

  AValue := V;
  // Something like 1E-300 parses as a Double but collapses to zero in a
  // Single, which would put the log axis right back where it started.
  Result := AValue > 0;
end;

function AxisLimitToText(const AValue: Single): string;
begin
  Result := FormatFloat('0.###E-0', AValue, InvariantFormat);
end;

initialization
  InvariantFormat := TFormatSettings.Invariant;

end.
