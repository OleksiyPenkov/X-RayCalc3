program xrccmd;

{$APPTYPE CONSOLE}

{$R *.res}

uses
  FastMM5,
  System.SysUtils,
  Forms,
  cmd_math_complex in 'units\cmd_math_complex.pas',
  cmd_math_globals in 'units\cmd_math_globals.pas',
  cmd_unit_calc in 'units\cmd_unit_calc.pas',
  cmd_unit_fit_types in 'units\cmd_unit_fit_types.pas',
  cmd_unit_fitting in 'units\cmd_unit_fitting.pas',
  cmd_unit_helpers in 'units\cmd_unit_helpers.pas',
  cmd_unit_main in 'units\cmd_unit_main.pas',
  cmd_unit_materials in 'units\cmd_unit_materials.pas',
  cmd_unit_types in 'units\cmd_unit_types.pas';

var
  Value: string;
  C: single;
  OperationMode: (omHelp, omSingleCalc, omFolderCalc, omFitting);
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
     end;

     write('Done. ');
     if VerboseMode then Readln(Value);

  except
    on E: Exception do
      Writeln(E.ClassName, ': ', E.Message);
  end;
end.
