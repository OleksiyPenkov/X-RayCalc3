program xrccmd;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  FastMM5,
  System.SysUtils,
  Forms,
  cmd_math_globals in 'Units\cmd_math_globals.pas',
  cmd_unit_calc in 'Units\cmd_unit_calc.pas',
  cmd_unit_fit_types in 'Units\cmd_unit_fit_types.pas',
  cmd_unit_fitting in 'Units\cmd_unit_fitting.pas',
  cmd_unit_helpers in 'Units\cmd_unit_helpers.pas',
  cmd_unit_main in 'Units\cmd_unit_main.pas',
  cmd_unit_materials in 'Units\cmd_unit_materials.pas',
  cmd_unit_types in 'Units\cmd_unit_types.pas',
  cmd_unit_load in 'Units\cmd_unit_load.pas',
  cmd_unit_universal in 'Units\cmd_unit_universal.pas',
  unit_universal_types in '..\Universal\unit_universal_types.pas',
  unit_universal_fitness in '..\Universal\unit_universal_fitness.pas',
  unit_universal_pso in '..\Universal\unit_universal_pso.pas',
  unit_universal_io in '..\Universal\unit_universal_io.pas',
  unit_universal_optimizer in '..\Universal\unit_universal_optimizer.pas',
  unit_materials_mix in '..\Math\unit_materials_mix.pas';

var
  Value: string;
  OperationMode: (omHelp, omSingleCalc, omFolderCalc, omFitting, omUniversal);
  UniversalConfigFile: string;
  VerboseMode : boolean = False;
begin
  try
    OperationMode := omSingleCalc;
    if ParamCount > 0 then
    begin
      if FindCmdLineSwitch('s', Value, True, [clstValueNextParam]) then
         InputStructureFileName := Value;

      if FindCmdLineSwitch('o', Value, True, [clstValueNextParam]) then
         OutputFileName := Value;

      if FindCmdLineSwitch('i', Value, True, [clstValueNextParam]) then
         InputDataFile := Value;

      if FindCmdLineSwitch('f', Value, True, [clstValueNextParam]) then
      begin
        InputStructureFileName := Value;
        NumberOfFiles := 50;

        if FindCmdLineSwitch('n', Value, True, [clstValueNextParam]) then
          NumberOfFiles := StrToInt(Value);

        OperationMode := omFolderCalc;
      end;

      if FindCmdLineSwitch('a', Value, True, [clstValueNextParam]) then
      begin
        InputStructureFileName := Value;
        OperationMode := omFitting;
      end;

      if FindCmdLineSwitch('u', Value, True, [clstValueNextParam]) then
      begin
        UniversalConfigFile := Value;
        OperationMode := omUniversal;
      end;

      VerboseMode := FindCmdLineSwitch('v');
      if FindCmdLineSwitch('h') then OperationMode := omHelp;

      if FindCmdLineSwitch('pop', Value, True, [clstValueNextParam]) then
          Population := StrToInt(Value);

      if FindCmdLineSwitch('iter', Value, True, [clstValueNextParam]) then
          Iterations := StrToInt(Value);
     end;

     case OperationMode of
       omHelp       : ShowHelp;
       omSingleCalc : cmdCalc(VerboseMode);
       omFolderCalc : cmdFolderCalc(VerboseMode);
       omFitting    : cmdFitting(VerboseMode);
       omUniversal  : cmdUniversalMirror(UniversalConfigFile, VerboseMode);
     end;

     write('Done.');
     if VerboseMode then
     begin
       write(' Press <Enter> to close');
       Readln;
     end;

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
