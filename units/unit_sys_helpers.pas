unit unit_sys_helpers;

interface

uses
  Winapi.Windows;

  function SingleProcessorMask(const ProcessorIndex: Integer): DWORD_PTR;
  function CombinedProcessorMask(const Processors: array of Integer): DWORD_PTR;
  function GetNThreads: Integer;

implementation

uses
  Dialogs, unit_Config, OtlCommon, System.SysUtils;

const
    CPUS : array [0..7] of Integer = (0,1,2,3,4,5,6,7); // (0,1,2,3,4,5,6,7,8,9,10,11,12,13,14,15);
//
//
function SingleProcessorMask(const ProcessorIndex: Integer): DWORD_PTR;
begin
  //When shifting constants the compiler will force the result to be 32-bit
  //if you have more than 32 processors, `Result:= 1 shl x` will return
  //an incorrect result.
  Result := DWORD_PTR(1) shl (ProcessorIndex);
end;

function CombinedProcessorMask(const Processors: array of Integer): DWORD_PTR;
var
  i: Integer;
begin
  Result := 0;
  for i := low(Processors) to high(Processors) do
    Result := Result or SingleProcessorMask(Processors[i]);
end;

function GetNThreads: Integer;
begin
  if TConfig.Section<TCalcOptions>.NumberOfThreads = 0 then
     Result := Environment.Process.Affinity.Count
  else
    Result := TConfig.Section<TCalcOptions>.NumberOfThreads;

//  Result := Length(CPUS);
//  Environment.Process.Affinity.Mask := CombinedProcessorMask(CPUS);

//  if not SetProcessAffinityMask(GetCurrentProcess, SingleProcessorMask(16)) then
//   ShowMessage(SysErrorMessage(GetLastError));

end;


end.
