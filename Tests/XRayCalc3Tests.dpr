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
  math_complex in '..\math\math_complex.pas',
  math_globals in '..\math\math_globals.pas',
  unit_Types in '..\units\unit_Types.pas',
  unit_helpers in '..\units\unit_helpers.pas',
  unit_Config in '..\units\unit_Config.pas',
  unit_consts in '..\units\unit_consts.pas',
  unit_SavitzkyGolay in '..\math\unit_SavitzkyGolay.pas',
  TestMathComplex in 'TestMathComplex.pas',
  TestMathGlobals in 'TestMathGlobals.pas',
  TestUnitTypes in 'TestUnitTypes.pas',
  TestUnitHelpers in 'TestUnitHelpers.pas',
  TestSavitzkyGolay in 'TestSavitzkyGolay.pas';

{$R *.res}

var
  runner: ITestRunner;
  results: IRunResults;
  logger: ITestLogger;
  nunitLogger: ITestLogger;
begin
  try
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
