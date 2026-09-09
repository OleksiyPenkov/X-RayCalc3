program XRayCalc3Tests;

{$APPTYPE CONSOLE}

{$STRONGLINKTYPES ON}

uses
  System.SysUtils,
  DUnitX.TestFramework,
  DUnitX.Loggers.Console,
  DUnitX.Loggers.XML.NUnit,
  DUnitX.Windows.Console,
  DUnitX.ConsoleWriter.Base,
  math_complex in '..\..\Shared\Math\math_complex.pas',
  math_globals in '..\..\Shared\Math\math_globals.pas',
  unit_Types in '..\Units\unit_Types.pas',
  unit_helpers in '..\Units\unit_helpers.pas',
  unit_Config in '..\Units\unit_Config.pas',
  unit_consts in '..\Units\unit_consts.pas',
  unit_SavitzkyGolay in '..\..\Shared\Math\unit_SavitzkyGolay.pas',
  unit_materials in '..\..\Shared\Math\unit_materials.pas',
  unit_calc in '..\..\Shared\Math\unit_calc.pas',
  TestMathComplex in 'TestMathComplex.pas',
  TestMathGlobals in 'TestMathGlobals.pas',
  TestUnitTypes in 'TestUnitTypes.pas',
  TestUnitHelpers in 'TestUnitHelpers.pas',
  TestSavitzkyGolay in 'TestSavitzkyGolay.pas',
  TestCalcEngine in 'TestCalcEngine.pas',
  TestConfig in 'TestConfig.pas',
  TestHenke in 'TestHenke.pas',
  TestCalcPhysics in 'TestCalcPhysics.pas',
  TestSeriesIO in 'TestSeriesIO.pas',
  unit_SMessages in '..\Components\unit_SMessages.pas',
  unit_LFPSO_Base in '..\LFPSO\unit_LFPSO_Base.pas',
  TestLFPSOBase in 'TestLFPSOBase.pas',
  unit_LFPSO_Periodic in '..\LFPSO\unit_LFPSO_Periodic.pas',
  unit_LFPSO_Irregular in '..\LFPSO\unit_LFPSO_Irregular.pas',
  TestLFPSOPeriodic in 'TestLFPSOPeriodic.pas',
  TestLFPSOIrregular in 'TestLFPSOIrregular.pas',
  TestLFPSOProgress in 'TestLFPSOProgress.pas',
  unit_ProfileCalc in '..\..\Shared\Math\unit_ProfileCalc.pas',
  TestProfileCalc in 'TestProfileCalc.pas',
  unit_SmartLimits in '..\Units\unit_SmartLimits.pas',
  TestSmartLimits in 'TestSmartLimits.pas',
  cmd_unit_types in '..\..\XRC_CMD\Units\cmd_unit_types.pas',
  cmd_math_globals in '..\..\XRC_CMD\Units\cmd_math_globals.pas',
  unit_materials_mix in '..\..\Shared\Math\unit_materials_mix.pas',
  TestMaterialMix in 'TestMaterialMix.pas',
  unit_universal_types in '..\..\Shared\Universal\unit_universal_types.pas',
  unit_universal_templates in '..\..\Shared\Universal\unit_universal_templates.pas',
  unit_universal_io in '..\..\Shared\Universal\unit_universal_io.pas',
  unit_xrf_lines in '..\..\Shared\Universal\unit_xrf_lines.pas',
  unit_xrfx_package in '..\..\Shared\Universal\unit_xrfx_package.pas',
  TestXRFLines in 'TestXRFLines.pas',
  TestXRFXPackage in 'TestXRFXPackage.pas',
  unit_MCPErrors in '..\..\XRC_MCP\units\unit_MCPErrors.pas',
  unit_MCPSandbox in '..\..\XRC_MCP\units\unit_MCPSandbox.pas',
  TestMCPSandbox in 'TestMCPSandbox.pas',
  unit_MCPJournal in '..\..\XRC_MCP\units\unit_MCPJournal.pas',
  TestMCPJournal in 'TestMCPJournal.pas',
  unit_MCPUnits in '..\..\XRC_MCP\units\unit_MCPUnits.pas',
  TestMCPUnits in 'TestMCPUnits.pas',
  unit_MCPStructure in '..\..\XRC_MCP\units\unit_MCPStructure.pas',
  TestMCPStructure in 'TestMCPStructure.pas',
  unit_MCPMaterials in '..\..\XRC_MCP\units\unit_MCPMaterials.pas',
  TestMCPMaterials in 'TestMCPMaterials.pas',
  unit_MCPCalc in '..\..\XRC_MCP\units\unit_MCPCalc.pas',
  TestMCPCalc in 'TestMCPCalc.pas',
  unit_universal_refcalc in '..\..\Shared\Universal\unit_universal_refcalc.pas',
  unit_universal_fitness in '..\..\Shared\Universal\unit_universal_fitness.pas',
  TestUniversalFitnessLayers in 'TestUniversalFitnessLayers.pas',
  unit_MCPUniversal in '..\..\XRC_MCP\units\unit_MCPUniversal.pas',
  TestMCPUniversal in 'TestMCPUniversal.pas',
  unit_MCPJobs in '..\..\XRC_MCP\units\unit_MCPJobs.pas',
  TestMCPJobs in 'TestMCPJobs.pas',
  unit_universal_pso in '..\..\Shared\Universal\unit_universal_pso.pas',
  unit_universal_optimizer in '..\..\Shared\Universal\unit_universal_optimizer.pas',
  TestMCPUniversalJob in 'TestMCPUniversalJob.pas';

{$R *.res}

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
begin
  try
    LoadXRFLines(ExpandFileName(ExtractFilePath(ParamStr(0))
      + '..\..\..\..\Shared\Universal\xrf_lines.json'));

    TDUnitX.CheckCommandLine;
    runner := TDUnitX.CreateRunner;
    runner.UseRTTI := True;
    runner.FailsOnNoAsserts := True;

    if TDUnitX.Options.ConsoleMode <> TDunitXConsoleMode.Off then
    begin
      logger := TDUnitXConsoleLogger.Create(TDUnitX.Options.ConsoleMode = TDunitXConsoleMode.Quiet);
      runner.AddLogger(logger);
    end;

    nunitLogger := TDUnitXXMLNUnitFileLogger.Create(TDUnitX.Options.XMLOutputFile);
    runner.AddLogger(nunitLogger);

    logger := nil;
    nunitLogger := nil;

    results := runner.Execute;
    runner := nil;

    if not results.AllPassed then
      System.ExitCode := 1;

    {$IFNDEF CI}
    if TDUnitX.Options.ExitBehavior = TDUnitXExitBehavior.Pause then
    begin
      System.Write('Done... Press <Enter> key to quit.');
      System.Readln;
    end;
    {$ENDIF}

    results := nil;
  except
    on E: Exception do
    begin
      System.Writeln(E.ClassName, ': ', E.Message);
      {$IFNDEF CI}
      System.Readln;
      {$ENDIF}
    end;
  end;
end.
