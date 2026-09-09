unit unit_MCPJournal;

{ Stub. The transport loop already calls LogCall on every tool invocation;
  Task 3 turns these into the JSONL journal under <workdir>\log. }

interface

uses System.JSON;

type
  TJournal = class
  private
    FLogDir: string;
  public
    constructor Create(const ALogDir: string);
    procedure LogCall(const Tool: string; const Args, ResultObj, ErrorObj: TJSONObject; ElapsedMs: Int64);
    procedure LogEvent(const Kind: string; const Data: TJSONObject);
  end;

var
  Journal: TJournal;

implementation

{ TJournal }

constructor TJournal.Create(const ALogDir: string);
begin
  inherited Create;
  FLogDir := ALogDir;
end;

procedure TJournal.LogCall(const Tool: string; const Args, ResultObj, ErrorObj: TJSONObject;
  ElapsedMs: Int64);
begin
  // Task 3.
end;

procedure TJournal.LogEvent(const Kind: string; const Data: TJSONObject);
begin
  // Task 3.
end;

end.
