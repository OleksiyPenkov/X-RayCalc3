unit unit_CurveStyle;

(* How a curve's look on the main chart is kept in params.dsc, beside the
   ActiveModel and LinkedData IDs:

     [CURVES] Transparency.<key>=<percent>   only for a curve that is not opaque
     [STATE]  DrawOrder=<keys, bottom to top>

   A key is the node's group and ID, M3 for a model and D3 for a data curve:
   builds before 3.9.4 could give a model the ID of an existing data curve, so
   the ID alone does not name one curve in every project.

   The binary node stream (project.dsc) is not touched, so the project version
   stays where it is: an older build, and XRC_MCP, ignore these keys and show
   every curve opaque in the order the curves were created. *)

interface

uses
  System.IniFiles;

const
  CURVES_SECTION = 'CURVES';
  MAX_CURVE_TRANSPARENCY = 90;   // percent; a curve never vanishes altogether

function ClampTransparency(Value: Integer): Integer;

function CurveKey(IsModel: Boolean; ID: Integer): string;

function FormatDrawOrder(const Keys: array of string): string;
{ Well-formed keys (M or D, then a non-negative integer) in the order given;
  anything else and repeats are skipped. }
function ParseDrawOrder(const S: string): TArray<string>;

procedure WriteDrawOrder(INI: TCustomIniFile; const Keys: array of string);
function ReadDrawOrder(INI: TCustomIniFile): TArray<string>;

procedure WriteCurveTransparency(INI: TCustomIniFile; const Key: string; Percent: Integer);
function ReadCurveTransparency(INI: TCustomIniFile; const Key: string): Integer;

implementation

uses
  System.SysUtils, System.Math, System.Generics.Collections;

const
  STATE_SECTION = 'STATE';
  DRAW_ORDER_KEY = 'DrawOrder';

function ClampTransparency(Value: Integer): Integer;
begin
  Result := EnsureRange(Value, 0, MAX_CURVE_TRANSPARENCY);
end;

function CurveKey(IsModel: Boolean; ID: Integer): string;
const
  GROUP: array [Boolean] of Char = ('D', 'M');
begin
  Result := GROUP[IsModel] + IntToStr(ID);
end;

function IsCurveKey(const Key: string): Boolean;
var
  ID: Integer;
begin
  Result := (Length(Key) >= 2) and CharInSet(Key[1], ['M', 'D']) and
            TryStrToInt(Copy(Key, 2, MaxInt), ID) and (ID >= 0) and
            (CurveKey(Key[1] = 'M', ID) = Key);   // no sign, spaces or leading zeros
end;

function TransparencyKey(const Key: string): string;
begin
  Result := 'Transparency.' + Key;
end;

function FormatDrawOrder(const Keys: array of string): string;
begin
  Result := string.Join(',', Keys);
end;

function ParseDrawOrder(const S: string): TArray<string>;
var
  Part, Key: string;
begin
  Result := nil;
  for Part in S.Split([',']) do
  begin
    Key := Part.Trim;
    if IsCurveKey(Key) and not TArray.Contains<string>(Result, Key) then
      Result := Result + [Key];
  end;
end;

procedure WriteDrawOrder(INI: TCustomIniFile; const Keys: array of string);
begin
  INI.WriteString(STATE_SECTION, DRAW_ORDER_KEY, FormatDrawOrder(Keys));
end;

function ReadDrawOrder(INI: TCustomIniFile): TArray<string>;
begin
  Result := ParseDrawOrder(INI.ReadString(STATE_SECTION, DRAW_ORDER_KEY, ''));
end;

procedure WriteCurveTransparency(INI: TCustomIniFile; const Key: string; Percent: Integer);
begin
  Percent := ClampTransparency(Percent);
  if Percent = 0 then
    INI.DeleteKey(CURVES_SECTION, TransparencyKey(Key))
  else
    INI.WriteInteger(CURVES_SECTION, TransparencyKey(Key), Percent);
end;

function ReadCurveTransparency(INI: TCustomIniFile; const Key: string): Integer;
begin
  Result := ClampTransparency(INI.ReadInteger(CURVES_SECTION, TransparencyKey(Key), 0));
end;

end.
