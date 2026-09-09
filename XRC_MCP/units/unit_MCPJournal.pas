unit unit_MCPJournal;

(* The call journal: one JSON object per line in <workdir>\log\calls.jsonl.

  Every tool invocation is appended as

    {"ts":"...","tool":"...","args":{...},"result":{...}|"error":{...},"ms":n}

  The file is only ever appended to (opened for write, seeked to the end); it is
  never truncated, so the journal survives across server runs.

  Large arrays are not written out. A curve of ten thousand points would drown
  the journal and tell the reader nothing, so any array longer than 64 elements
  is replaced by {"_len": n} -- plus {"_sha256": "..."} when the object holding
  the array also carries a "file" or "path" pair naming an existing file, which
  is how the tools that return curves report them. The journal therefore shows
  what was returned and where the full data lives, in one short line. *)

interface

uses System.JSON, System.SyncObjs;

const
  JOURNAL_MAX_ARRAY = 64;   // arrays longer than this are compacted

type
  TJournal = class
  private
    FPath: string;
    FLock: TCriticalSection;
    procedure WriteLine(const Obj: TJSONObject);
  public
    constructor Create(const LogDir: string);
    destructor Destroy; override;
    /// <summary>Appends one call record. Args/ResultObj/ErrorObj are not owned
    /// and are left untouched; pass ErrorObj = nil for a successful call and
    /// ResultObj = nil for a failed one.</summary>
    procedure LogCall(const Tool: string; const Args, ResultObj, ErrorObj: TJSONObject; ElapsedMs: Int64);
    /// <summary>Appends one event record {"ts","event":Kind,...Data}. Used for
    /// job transitions. Data is not owned.</summary>
    procedure LogEvent(const Kind: string; const Data: TJSONObject);
    property Path: string read FPath;
  end;

/// <summary>Deep clone of V with long arrays compacted. The caller owns the
/// result. Returns nil for nil.</summary>
function CompactForJournal(const V: TJSONValue): TJSONValue;

var
  Journal: TJournal;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Generics.Collections,
  unit_MCPSandbox;

{ Absolute path of the file named by a "file" or "path" string pair of Parent,
  or '' when there is no such pair or it does not name an existing file.
  A relative value is resolved against the work directory root. }
function SiblingFilePath(const Parent: TJSONObject): string;

  function Candidate(const Key: string): string;
  var
    V: TJSONValue;
    S: string;
  begin
    Result := '';
    V := Parent.FindValue(Key);
    if not (V is TJSONString) then Exit;
    S := TJSONString(V).Value.Trim;
    if S = '' then Exit;
    if not TPath.IsPathRooted(S) then
    begin
      if WorkDir = nil then Exit;
      S := TPath.Combine(WorkDir.Root, StringReplace(S, '/', '\', [rfReplaceAll]));
    end;
    if TFile.Exists(S) then Result := S;
  end;

begin
  Result := '';
  if Parent = nil then Exit;
  Result := Candidate('file');
  if Result = '' then Result := Candidate('path');
end;

{ Parent is the object the value sits in, or nil at the top level and inside
  arrays; it is only consulted for the "file"/"path" sibling of a long array. }
function CompactValue(const V: TJSONValue; const Parent: TJSONObject): TJSONValue;
var
  I: Integer;
  Obj: TJSONObject;
  Arr: TJSONArray;
  Rep: TJSONObject;
  ArrClone: TJSONArray;
  Sibling, Hash: string;
begin
  if V = nil then Exit(nil);

  if V is TJSONObject then
  begin
    Obj := TJSONObject(V);
    Result := TJSONObject.Create;
    try
      for I := 0 to Obj.Count - 1 do
        TJSONObject(Result).AddPair(Obj.Pairs[I].JsonString.Value,
          CompactValue(Obj.Pairs[I].JsonValue, Obj));
    except
      Result.Free;
      raise;
    end;
  end
  else if V is TJSONArray then
  begin
    Arr := TJSONArray(V);
    if Arr.Count > JOURNAL_MAX_ARRAY then
    begin
      Rep := TJSONObject.Create;
      try
        Rep.AddPair('_len', TJSONNumber.Create(Arr.Count));
        Sibling := SiblingFilePath(Parent);
        if Sibling <> '' then
        begin
          Hash := '';
          try
            Hash := FileSHA256(Sibling);
          except
            Hash := '';   // an unreadable file must not break the journal
          end;
          if Hash <> '' then Rep.AddPair('_sha256', Hash);
        end;
      except
        Rep.Free;
        raise;
      end;
      Result := Rep;
    end
    else
    begin
      ArrClone := TJSONArray.Create;
      try
        for I := 0 to Arr.Count - 1 do
          ArrClone.AddElement(CompactValue(Arr.Items[I], nil));
      except
        ArrClone.Free;
        raise;
      end;
      Result := ArrClone;
    end;
  end
  else
    Result := V.Clone as TJSONValue;
end;

function CompactForJournal(const V: TJSONValue): TJSONValue;
begin
  Result := CompactValue(V, nil);
end;

{ TJournal }

constructor TJournal.Create(const LogDir: string);
begin
  inherited Create;
  FLock := TCriticalSection.Create;
  FPath := TPath.Combine(LogDir, 'calls.jsonl');
  if not TDirectory.Exists(LogDir) then
    TDirectory.CreateDirectory(LogDir);
end;

destructor TJournal.Destroy;
begin
  FLock.Free;
  inherited Destroy;
end;

procedure TJournal.WriteLine(const Obj: TJSONObject);
var
  Stream: TFileStream;
  Bytes: TBytes;
begin
  Bytes := TEncoding.UTF8.GetBytes(Obj.ToJSON + #10);
  FLock.Enter;
  try
    if TFile.Exists(FPath) then
      Stream := TFileStream.Create(FPath, fmOpenWrite or fmShareDenyNone)
    else
      Stream := TFileStream.Create(FPath, fmCreate or fmShareDenyNone);
    try
      Stream.Seek(Int64(0), soEnd);   // append; the journal is never truncated
      if Length(Bytes) > 0 then
        Stream.WriteBuffer(Bytes[0], Length(Bytes));
    finally
      Stream.Free;
    end;
  finally
    FLock.Leave;
  end;
end;

procedure TJournal.LogCall(const Tool: string; const Args, ResultObj, ErrorObj: TJSONObject;
  ElapsedMs: Int64);
var
  Line: TJSONObject;
  Empty: TJSONObject;
begin
  { The journal is diagnostics: a failure to write it must never turn a
    successful tool call into an error response. }
  try
    Line := TJSONObject.Create;
    try
      Line.AddPair('ts', NowUTCString);
      Line.AddPair('tool', Tool);
      if Args <> nil then
        Line.AddPair('args', CompactForJournal(Args))
      else
      begin
        Empty := TJSONObject.Create;
        Line.AddPair('args', Empty);
      end;
      if ErrorObj <> nil then
        Line.AddPair('error', ErrorObj.Clone as TJSONValue)
      else if ResultObj <> nil then
        Line.AddPair('result', CompactForJournal(ResultObj));
      Line.AddPair('ms', TJSONNumber.Create(ElapsedMs));
      WriteLine(Line);
    finally
      Line.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn(ErrOutput, 'XRC_MCP: journal write failed: ' + E.Message);
      Flush(ErrOutput);
    end;
  end;
end;

procedure TJournal.LogEvent(const Kind: string; const Data: TJSONObject);
var
  Line: TJSONObject;
  I: Integer;
begin
  try
    Line := TJSONObject.Create;
    try
      Line.AddPair('ts', NowUTCString);
      Line.AddPair('event', Kind);
      if Data <> nil then
        for I := 0 to Data.Count - 1 do
          Line.AddPair(Data.Pairs[I].JsonString.Value,
            CompactValue(Data.Pairs[I].JsonValue, Data));
      WriteLine(Line);
    finally
      Line.Free;
    end;
  except
    on E: Exception do
    begin
      WriteLn(ErrOutput, 'XRC_MCP: journal write failed: ' + E.Message);
      Flush(ErrOutput);
    end;
  end;
end;

end.
