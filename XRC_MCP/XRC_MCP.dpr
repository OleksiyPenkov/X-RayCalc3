program XRC_MCP;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  FastMM5,
  System.SysUtils,
  Vcl.Forms,
  // transport / server
  unit_MCPProtocol in 'units\unit_MCPProtocol.pas',
  unit_MCPTools in 'units\unit_MCPTools.pas',
  unit_MCPErrors in 'units\unit_MCPErrors.pas',
  unit_MCPVersion in 'units\unit_MCPVersion.pas',
  unit_MCPSandbox in 'units\unit_MCPSandbox.pas',
  unit_MCPUnits in 'units\unit_MCPUnits.pas',
  unit_MCPJournal in 'units\unit_MCPJournal.pas',
  unit_MCPJobs in 'units\unit_MCPJobs.pas',
  // engine units the structure adapter maps onto
  math_complex in '..\Shared\Math\math_complex.pas',
  math_globals in '..\Shared\Math\math_globals.pas',
  unit_Types in '..\XRayCalc3\Units\unit_Types.pas',
  unit_consts in '..\XRayCalc3\Units\unit_consts.pas',
  unit_Config in '..\XRayCalc3\Units\unit_Config.pas',
  unit_materials in '..\Shared\Math\unit_materials.pas',
  unit_MCPStructure in 'units\unit_MCPStructure.pas',
  unit_ToolsReference in 'units\unit_ToolsReference.pas',
  unit_ToolsCalc in 'units\unit_ToolsCalc.pas',
  unit_ToolsJobs in 'units\unit_ToolsJobs.pas',
  unit_ToolsFiles in 'units\unit_ToolsFiles.pas',
  unit_MCPServer in 'units\unit_MCPServer.pas';

begin
  Application.Initialize;    // TConfig and headless VCL classes need Application
  try
    RunServer;
  except
    on E: Exception do
    begin
      WriteLn(ErrOutput, 'Fatal: ' + E.Message);
      Flush(ErrOutput);
      ExitCode := 1;
    end;
  end;
end.
