unit unit_sys_helpers;

interface

uses
  Winapi.Windows, System.SysUtils;

  function SingleProcessorMask(const ProcessorIndex: Integer): DWORD_PTR;
  function CombinedProcessorMask(const Processors: array of Integer): DWORD_PTR;
  function GetNThreads: Integer;
  { A duration for people, its precision following its size: '0.84 s',
    '12.3 s', '7 min 25.3 s', '1 h 02 min 05 s'. }
  function FormatDuration(const Seconds: Double): string; overload;
  function FormatDuration(const Seconds: Double; const FS: TFormatSettings): string; overload;

implementation

uses
  Dialogs, unit_Config, OtlCommon;

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

function FormatDuration(const Seconds: Double): string;
begin
  Result := FormatDuration(Seconds, FormatSettings);
end;

function FormatDuration(const Seconds: Double; const FS: TFormatSettings): string;
var
  t, s: Double;
  h, m: Int64;
begin
  t := Seconds;
  if not (t > 0) then
    t := 0;
  { Each branch rounds to its own precision first, so that 9.996 s is
    '10.0 s' and not '10.00 s', and 59.97 s is '1 min 00.0 s', not '60.0 s'. }
  if Round(t * 100) < 1000 then
    Exit(Format('%.2f s', [Round(t * 100) / 100], FS));
  if Round(t * 10) < 600 then
    Exit(Format('%.1f s', [Round(t * 10) / 10], FS));
  if Round(t * 10) < 36000 then
  begin
    t := Round(t * 10) / 10;
    m := Trunc(t / 60);
    s := t - m * 60;
    Result := Format('%d min %.1f s', [m, s], FS);
    if s < 10 then                      // '7 min 05.3 s'
      Result := Format('%d min 0%.1f s', [m, s], FS);
    Exit;
  end;
  t := Round(t);
  h := Trunc(t / 3600);
  m := Trunc((t - h * 3600) / 60);
  Result := Format('%d h %.2d min %.2d s', [h, m, Round(t - h * 3600 - m * 60)], FS);
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
