(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_MCPErrors;

interface

uses System.SysUtils, System.JSON;

type
  EMCPError = class(Exception)
  private
    FCode: string;
    FDetail: string;
  public
    constructor Create(const ACode, AMessage: string; const ADetail: string = ''); reintroduce;
    property Code: string read FCode;
    property Detail: string read FDetail;
  end;

  JSONArgs = record
    class function OptStr(const P: TJSONObject; const Key, Default: string): string; static;
    class function OptFloat(const P: TJSONObject; const Key: string; Default: Double): Double; static;
    class function OptInt(const P: TJSONObject; const Key: string; Default: Integer): Integer; static;
    class function OptBool(const P: TJSONObject; const Key: string; Default: Boolean): Boolean; static;
    class function Has(const P: TJSONObject; const Key: string): Boolean; static;
    class function ReqStr(const P: TJSONObject; const Key: string): string; static;
    class function ReqFloat(const P: TJSONObject; const Key: string): Double; static;
    class function ReqObj(const P: TJSONObject; const Key: string): TJSONObject; static; // not owned
    class function ReqArr(const P: TJSONObject; const Key: string): TJSONArray; static;
    class function OptObj(const P: TJSONObject; const Key: string): TJSONObject; static;
    class function OptArr(const P: TJSONObject; const Key: string): TJSONArray; static;
    class function Num(const V: Double): TJSONNumber; static;
    class function NumArr(const V: TArray<Double>): TJSONArray; static;
  end;

function MCPErrorJSON(const Code, Msg, Detail: string): TJSONObject;

implementation

uses System.Math;

constructor EMCPError.Create(const ACode, AMessage, ADetail: string);
begin
  inherited Create(AMessage);
  FCode := ACode;
  FDetail := ADetail;
end;

function MCPErrorJSON(const Code, Msg, Detail: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('code', Code);
  Result.AddPair('message', Msg);
  Result.AddPair('detail', Detail);
end;

class function JSONArgs.Has(const P: TJSONObject; const Key: string): Boolean;
begin
  Result := (P <> nil) and (P.FindValue(Key) <> nil) and not (P.FindValue(Key) is TJSONNull);
end;

class function JSONArgs.OptStr(const P: TJSONObject; const Key, Default: string): string;
begin
  if Has(P, Key) then Result := P.GetValue<string>(Key) else Result := Default;
end;

class function JSONArgs.OptFloat(const P: TJSONObject; const Key: string; Default: Double): Double;
begin
  if Has(P, Key) then
  begin
    if not (P.FindValue(Key) is TJSONNumber) then
      raise EMCPError.Create('invalid_argument', Format('"%s" must be a number', [Key]));
    Result := P.GetValue<Double>(Key);
  end
  else Result := Default;
end;

class function JSONArgs.OptInt(const P: TJSONObject; const Key: string; Default: Integer): Integer;
begin
  Result := Round(OptFloat(P, Key, Default));
end;

class function JSONArgs.OptBool(const P: TJSONObject; const Key: string; Default: Boolean): Boolean;
begin
  if Has(P, Key) then
  begin
    if not (P.FindValue(Key) is TJSONBool) then
      raise EMCPError.Create('invalid_argument', Format('"%s" must be true or false', [Key]));
    Result := P.GetValue<Boolean>(Key);
  end
  else Result := Default;
end;

class function JSONArgs.ReqStr(const P: TJSONObject; const Key: string): string;
begin
  if not Has(P, Key) then raise EMCPError.Create('invalid_argument', Format('Missing "%s"', [Key]));
  Result := P.GetValue<string>(Key);
end;

class function JSONArgs.ReqFloat(const P: TJSONObject; const Key: string): Double;
begin
  if not Has(P, Key) then raise EMCPError.Create('invalid_argument', Format('Missing "%s"', [Key]));
  Result := OptFloat(P, Key, 0);
end;

class function JSONArgs.ReqObj(const P: TJSONObject; const Key: string): TJSONObject;
begin
  if not Has(P, Key) or not (P.FindValue(Key) is TJSONObject) then
    raise EMCPError.Create('invalid_argument', Format('"%s" must be an object', [Key]));
  Result := TJSONObject(P.FindValue(Key));
end;

class function JSONArgs.ReqArr(const P: TJSONObject; const Key: string): TJSONArray;
begin
  if not Has(P, Key) or not (P.FindValue(Key) is TJSONArray) then
    raise EMCPError.Create('invalid_argument', Format('"%s" must be an array', [Key]));
  Result := TJSONArray(P.FindValue(Key));
end;

class function JSONArgs.OptObj(const P: TJSONObject; const Key: string): TJSONObject;
begin
  if Has(P, Key) then Result := ReqObj(P, Key) else Result := nil;
end;

class function JSONArgs.OptArr(const P: TJSONObject; const Key: string): TJSONArray;
begin
  if Has(P, Key) then Result := ReqArr(P, Key) else Result := nil;
end;

class function JSONArgs.Num(const V: Double): TJSONNumber;
var
  R: Double;
begin
  if IsNan(V) or IsInfinite(V) then Exit(TJSONNumber.Create(0));
  if (Frac(V) = 0) and (Abs(V) < 1e15) then Exit(TJSONNumber.Create(Int64(Round(V))));
  if V = 0 then Exit(TJSONNumber.Create(0));
  // RoundTo's digit argument is declared -37..37 but implemented -20..20.
  // The formatter also handles values below 1e-15, such as cubic coefficients.
  R := StrToFloat(Format('%.6g', [V], TFormatSettings.Invariant),
                  TFormatSettings.Invariant);
  Result := TJSONNumber.Create(R);
end;

class function JSONArgs.NumArr(const V: TArray<Double>): TJSONArray;
var
  i: Integer;
begin
  Result := TJSONArray.Create;
  for i := 0 to High(V) do Result.AddElement(Num(V[i]));
end;

end.
