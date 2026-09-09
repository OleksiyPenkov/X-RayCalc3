unit unit_ToolsReference;

{ Reference tools: describe_server now, list_materials / optical_constants /
  list_templates in Task 6. }

interface

uses unit_MCPTools;

procedure RegisterReferenceTools(Registry: TToolRegistry);

implementation

uses
  System.JSON,
  unit_MCPVersion;

procedure RegisterReferenceTools(Registry: TToolRegistry);
begin
  Registry.Register('describe_server',
    'Describes this server: what it is, how it was built and what it can do. ' +
    'Call it first to learn the server version and the git revision it was built from.',
    SchemaObject([]),
    function(const Params: TJSONObject): TJSONObject
    begin
      Result := TJSONObject.Create;
      Result.AddPair('server_version', ServerVersionString);
      Result.AddPair('git_revision', GitRevision);
    end);
end;

end.
