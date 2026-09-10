(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

unit unit_MCPProtocol;

interface

uses
  System.JSON;

type
  TMCPRequest = record
    Id: TJSONValue;        // cloned — caller must free
    Method: string;
    Params: TJSONObject;   // nil for parameterless methods; NOT owned — do not free
    IsNotification: Boolean;
    RawJSON: TJSONObject;  // the parsed root object — caller must free to release Params
  end;

  TMCPProtocol = class
  public
    /// <summary>Parse a JSON-RPC 2.0 request from a single line of text.
    /// On success the caller owns Req.Id (cloned) and Req.RawJSON (which
    /// transitively owns Req.Params).  On failure nothing is allocated.</summary>
    class function ParseRequest(const Line: string; out Req: TMCPRequest): Boolean;

    /// <summary>Build a JSON-RPC 2.0 success response.</summary>
    class function MakeResult(const Id: TJSONValue; const AResult: TJSONValue): string;

    /// <summary>Build a JSON-RPC 2.0 error response.</summary>
    class function MakeError(const Id: TJSONValue; Code: Integer; const Msg: string): string;

    /// <summary>Build an MCP tool result (content array with a single text item).</summary>
    class function MakeToolResult(const Id: TJSONValue; const Content: string): string;

    /// <summary>Build an MCP tool error result (isError = true).</summary>
    class function MakeToolError(const Id: TJSONValue; const ErrorMsg: string): string;

    /// <summary>Build the response to "initialize" with server capabilities.</summary>
    class function MakeInitializeResult(const Id: TJSONValue): string;

    /// <summary>Build the response to "tools/list".</summary>
    class function MakeToolsListResult(const Id: TJSONValue; const Tools: TJSONArray): string;
  end;

implementation

uses
  System.SysUtils,
  unit_MCPVersion;

{ --------------------------------------------------------------------------- }
{  Helpers                                                                      }
{ --------------------------------------------------------------------------- }

/// <summary>Clone a TJSONValue so the copy has independent lifetime.</summary>
function CloneId(const Src: TJSONValue): TJSONValue;
begin
  if Src = nil then
    Result := TJSONNull.Create
  else
    Result := TJSONValue(Src.Clone);
end;

/// <summary>Create the outer JSON-RPC 2.0 envelope with id, serialise to
/// string, free the object and return the string.</summary>
function BuildEnvelope(const Id: TJSONValue): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('jsonrpc', '2.0');
  if Id = nil then
    Result.AddPair(TJSONPair.Create('id', TJSONNull.Create))
  else
    Result.AddPair(TJSONPair.Create('id', TJSONValue(Id.Clone)));
end;

function SerializeAndFree(Obj: TJSONObject): string;
begin
  try
    Result := Obj.ToJSON;
  finally
    Obj.Free;
  end;
end;

{ --------------------------------------------------------------------------- }
{  TMCPProtocol                                                                }
{ --------------------------------------------------------------------------- }

class function TMCPProtocol.ParseRequest(const Line: string;
  out Req: TMCPRequest): Boolean;
var
  Root: TJSONValue;
  Obj: TJSONObject;
  IdVal: TJSONValue;
  MethodVal: TJSONValue;
  ParamsVal: TJSONValue;
begin
  Result := False;

  // Zero-init
  Req.Id := nil;
  Req.Method := '';
  Req.Params := nil;
  Req.IsNotification := False;
  Req.RawJSON := nil;

  if Line.Trim.IsEmpty then
    Exit;

  Root := TJSONObject.ParseJSONValue(Line);
  if Root = nil then
    Exit;

  if not (Root is TJSONObject) then
  begin
    Root.Free;
    Exit;
  end;

  Obj := TJSONObject(Root);

  // "method" is required
  MethodVal := Obj.FindValue('method');
  if (MethodVal = nil) or not (MethodVal is TJSONString) then
  begin
    Obj.Free;
    Exit;
  end;
  Req.Method := TJSONString(MethodVal).Value;

  // "id" — absent means notification
  IdVal := Obj.FindValue('id');
  if IdVal = nil then
  begin
    Req.IsNotification := True;
    Req.Id := nil;
  end
  else
  begin
    Req.IsNotification := False;
    Req.Id := TJSONValue(IdVal.Clone);  // independent copy
  end;

  // "params" — optional
  ParamsVal := Obj.FindValue('params');
  if (ParamsVal <> nil) and (ParamsVal is TJSONObject) then
    Req.Params := TJSONObject(ParamsVal)   // owned by Obj
  else
    Req.Params := nil;

  Req.RawJSON := Obj;  // caller must free
  Result := True;
end;

class function TMCPProtocol.MakeResult(const Id: TJSONValue;
  const AResult: TJSONValue): string;
var
  Obj: TJSONObject;
begin
  Obj := BuildEnvelope(Id);
  if AResult = nil then
    Obj.AddPair(TJSONPair.Create('result', TJSONObject.Create))
  else
    Obj.AddPair(TJSONPair.Create('result', TJSONValue(AResult.Clone)));
  Result := SerializeAndFree(Obj);
end;

class function TMCPProtocol.MakeError(const Id: TJSONValue; Code: Integer;
  const Msg: string): string;
var
  Obj, ErrObj: TJSONObject;
begin
  Obj := BuildEnvelope(Id);
  ErrObj := TJSONObject.Create;
  ErrObj.AddPair('code', TJSONNumber.Create(Code));
  ErrObj.AddPair('message', Msg);
  Obj.AddPair('error', ErrObj);  // ErrObj now owned by Obj
  Result := SerializeAndFree(Obj);
end;

class function TMCPProtocol.MakeToolResult(const Id: TJSONValue;
  const Content: string): string;
var
  Obj, ResultObj, ContentItem: TJSONObject;
  ContentArr: TJSONArray;
begin
  Obj := BuildEnvelope(Id);

  ContentItem := TJSONObject.Create;
  ContentItem.AddPair('type', 'text');
  ContentItem.AddPair('text', Content);

  ContentArr := TJSONArray.Create;
  ContentArr.AddElement(ContentItem);

  ResultObj := TJSONObject.Create;
  ResultObj.AddPair('content', ContentArr);

  Obj.AddPair('result', ResultObj);
  Result := SerializeAndFree(Obj);
end;

class function TMCPProtocol.MakeToolError(const Id: TJSONValue;
  const ErrorMsg: string): string;
var
  Obj, ResultObj, ContentItem: TJSONObject;
  ContentArr: TJSONArray;
begin
  Obj := BuildEnvelope(Id);

  ContentItem := TJSONObject.Create;
  ContentItem.AddPair('type', 'text');
  ContentItem.AddPair('text', ErrorMsg);

  ContentArr := TJSONArray.Create;
  ContentArr.AddElement(ContentItem);

  ResultObj := TJSONObject.Create;
  ResultObj.AddPair('content', ContentArr);
  ResultObj.AddPair('isError', TJSONBool.Create(True));

  Obj.AddPair('result', ResultObj);
  Result := SerializeAndFree(Obj);
end;

class function TMCPProtocol.MakeInitializeResult(const Id: TJSONValue): string;
var
  Obj, ResultObj, Capabilities, ToolsCap, ServerInfo: TJSONObject;
begin
  Obj := BuildEnvelope(Id);

  ToolsCap := TJSONObject.Create;
  Capabilities := TJSONObject.Create;
  Capabilities.AddPair('tools', ToolsCap);

  ServerInfo := TJSONObject.Create;
  ServerInfo.AddPair('name', 'xrc');
  ServerInfo.AddPair('version', ServerVersionString);

  ResultObj := TJSONObject.Create;
  ResultObj.AddPair('protocolVersion', '2024-11-05');
  ResultObj.AddPair('capabilities', Capabilities);
  ResultObj.AddPair('serverInfo', ServerInfo);

  Obj.AddPair('result', ResultObj);
  Result := SerializeAndFree(Obj);
end;

class function TMCPProtocol.MakeToolsListResult(const Id: TJSONValue;
  const Tools: TJSONArray): string;
var
  Obj, ResultObj: TJSONObject;
begin
  Obj := BuildEnvelope(Id);

  ResultObj := TJSONObject.Create;
  if Tools = nil then
    ResultObj.AddPair('tools', TJSONArray.Create)
  else
    ResultObj.AddPair(TJSONPair.Create('tools', TJSONValue(Tools.Clone)));

  Obj.AddPair('result', ResultObj);
  Result := SerializeAndFree(Obj);
end;

end.
