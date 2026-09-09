unit unit_MCPServer;

interface

procedure RunServer;

implementation

uses
  Winapi.Windows, System.SysUtils, System.IOUtils, System.JSON, System.Diagnostics,
  unit_MCPProtocol, unit_MCPTools, unit_MCPErrors, unit_MCPSandbox, unit_MCPJournal,
  unit_ToolsReference, unit_ToolsCalc, unit_ToolsJobs, unit_ToolsFiles, unit_MCPJobs,
  unit_MCPMaterials, unit_xrf_lines;

/// <summary>Resolves the XRF lines and template files and loads the lines
/// table, once, before any tool can run. The lines table is a process-wide
/// global of unit_xrf_lines and every universal-engine call needs it, so a
/// server that cannot find one is not usable: it says so on stderr, naming the
/// switch that fixes it, and exits. Templates are optional - without them
/// list_templates simply returns nothing.</summary>
procedure LoadReferenceData;
begin
  LinesFile := ResolveLinesFile;
  if LinesFile = '' then
    raise Exception.Create('XRF lines file not found. Give it with --lines <file>, ' +
      'or put XRFLinesPath in the XRFCalc.ini beside the executable, ' +
      'or xrf_lines.json beside the executable.');
  try
    LoadXRFLines(LinesFile);
  except
    on E: Exception do
      raise Exception.CreateFmt('Cannot load the XRF lines file "%s" (--lines <file>): %s',
        [LinesFile, E.Message]);
  end;

  TemplatesFile := ResolveTemplatesFile;
  // LoadTemplates returns an empty library for a file that is not there, so an
  // operator who mistyped --templates would otherwise only find out from an
  // empty list_templates. Say it once, on stderr, and carry on: templates are
  // optional and the server is still useful without them.
  if (TemplatesFile <> '') and not TFile.Exists(TemplatesFile) then
  begin
    WriteLn(ErrOutput, 'XRC_MCP: template file not found, list_templates will be empty: ' +
      TemplatesFile);
    Flush(ErrOutput);
  end;
end;

procedure RunServer;
var
  Registry: TToolRegistry;
  Line, Response, ToolName: string;
  Req: TMCPRequest;
  ToolResult, ToolArgs, ErrObj: TJSONObject;
  ToolsList: TJSONArray;
  SW: TStopwatch;
begin
  // Every object gets its own try/finally from the moment it exists, so a raise
  // in a later constructor cannot strand an earlier one. The globals are set
  // back to nil after they are freed: nothing may reach a dangling WorkDir,
  // Journal or Jobs after RunServer has torn them down.
  WorkDir := TWorkDir.CreateFromCommandLine;   // raises with a plain message when --workdir missing
  try
    WorkDir.EnsureLayout;
    LoadReferenceData;
    Journal := TJournal.Create(WorkDir.LogDir);
    try
      Jobs := TJobManager.Create(WorkDir);
      try
        Registry := TToolRegistry.Create;
        try
          RegisterReferenceTools(Registry);
          RegisterCalcTools(Registry);
          RegisterJobTools(Registry);
          RegisterFileTools(Registry);

          SetTextCodePage(Input, 65001);
          SetTextCodePage(Output, 65001);
          WriteLn(ErrOutput, 'XRC_MCP: workdir=' + WorkDir.Root);
          Flush(ErrOutput);

          while not EOF(Input) do
          begin
            ReadLn(Input, Line);
            if Line.Trim.IsEmpty then Continue;
            if not TMCPProtocol.ParseRequest(Line, Req) then
            begin
              WriteLn(ErrOutput, 'XRC_MCP: unparsable request');
              Continue;
            end;
            try
              if Req.IsNotification then Continue;
              if Req.Method = 'initialize' then
                Response := TMCPProtocol.MakeInitializeResult(Req.Id)
              else if Req.Method = 'tools/list' then
              begin
                ToolsList := Registry.GetToolsList;
                try Response := TMCPProtocol.MakeToolsListResult(Req.Id, ToolsList);
                finally ToolsList.Free; end;
              end
              else if Req.Method = 'tools/call' then
              begin
                ToolName := '';
                ToolArgs := nil;
                SW := TStopwatch.StartNew;
                try
                  if (Req.Params = nil) or (Req.Params.FindValue('name') = nil) then
                    raise EMCPError.Create('invalid_request', 'Missing params.name');
                  ToolName := Req.Params.GetValue<string>('name');
                  if Req.Params.FindValue('arguments') is TJSONObject then
                    ToolArgs := TJSONObject(Req.Params.FindValue('arguments'));
                  if not Registry.HasTool(ToolName) then
                    raise EMCPError.Create('tool_not_found', 'Tool not found: ' + ToolName);
                  ToolResult := Registry.Execute(ToolName, ToolArgs);
                  try
                    Journal.LogCall(ToolName, ToolArgs, ToolResult, nil, SW.ElapsedMilliseconds);
                    Response := TMCPProtocol.MakeToolResult(Req.Id, ToolResult.ToJSON);
                  finally ToolResult.Free; end;
                except
                  on E: EMCPError do
                  begin
                    ErrObj := MCPErrorJSON(E.Code, E.Message, E.Detail);
                    try
                      Journal.LogCall(ToolName, ToolArgs, nil, ErrObj, SW.ElapsedMilliseconds);
                      Response := TMCPProtocol.MakeToolError(Req.Id, ErrObj.ToJSON);
                    finally ErrObj.Free; end;
                  end;
                  on E: Exception do
                  begin
                    ErrObj := MCPErrorJSON('internal', E.Message, E.ClassName);
                    try
                      Journal.LogCall(ToolName, ToolArgs, nil, ErrObj, SW.ElapsedMilliseconds);
                      Response := TMCPProtocol.MakeToolError(Req.Id, ErrObj.ToJSON);
                    finally ErrObj.Free; end;
                  end;
                end;
              end
              else
                Response := TMCPProtocol.MakeError(Req.Id, -32601, 'Method not found');
              WriteLn(Output, Response);
              Flush(Output);
            finally
              Req.RawJSON.Free;
              Req.Id.Free;
            end;
          end;
        finally
          Registry.Free;
        end;
      finally
        Jobs.Free;      // cancels and waits for the worker
        Jobs := nil;
      end;
    finally
      Journal.Free;
      Journal := nil;
    end;
  finally
    WorkDir.Free;
    WorkDir := nil;
  end;
end;

end.
