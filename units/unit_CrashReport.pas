(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_CrashReport;

interface

uses
  System.SysUtils, System.Classes;

type
  TCrashReport = class
  public
    class function BuildReport(E: Exception; Addr: Pointer): string;
    class procedure SaveToFile(const ReportText: string);
  private
    class function GetAppVersion: string;
    class function GetOSInfo: string;
    class function GetMemoryInfo: string;
    class function GetPlatformStr: string;
    class function GetModuleInfo(Addr: Pointer): string;
    class function GetLogDir: string;
  end;

  TExceptionHelper = class
  public
    class procedure HandleException(Sender: TObject; E: Exception);
  end;

implementation

uses
  Winapi.Windows, unit_Config, frm_CrashReport;

{ TCrashReport }

class function TCrashReport.GetAppVersion: string;
var
  FileName: string;
  Size, Dummy: DWORD;
  Buffer: TBytes;
  Info: PVSFixedFileInfo;
  InfoLen: UINT;
begin
  Result := 'Unknown';
  try
    FileName := ParamStr(0);
    Size := GetFileVersionInfoSize(PChar(FileName), Dummy);
    if Size = 0 then Exit;

    SetLength(Buffer, Size);
    if not GetFileVersionInfo(PChar(FileName), 0, Size, @Buffer[0]) then Exit;
    if not VerQueryValue(@Buffer[0], '\', Pointer(Info), InfoLen) then Exit;

    Result := Format('%d.%d.%d.%d', [
      HiWord(Info.dwFileVersionMS),
      LoWord(Info.dwFileVersionMS),
      HiWord(Info.dwFileVersionLS),
      LoWord(Info.dwFileVersionLS)
    ]);
  except
  end;
end;

class function TCrashReport.GetOSInfo: string;
begin
  try
    Result := TOSVersion.ToString;
  except
    Result := 'Unknown';
  end;
end;

class function TCrashReport.GetMemoryInfo: string;
var
  MemStatus: TMemoryStatusEx;
begin
  try
    MemStatus.dwLength := SizeOf(MemStatus);
    if GlobalMemoryStatusEx(MemStatus) then
      Result := Format('%d MB total, %d MB available; Load: %d%%', [
        MemStatus.ullTotalPhys div (1024 * 1024),
        MemStatus.ullAvailPhys div (1024 * 1024),
        MemStatus.dwMemoryLoad
      ])
    else
      Result := 'Unavailable';
  except
    Result := 'Unavailable';
  end;
end;

class function TCrashReport.GetPlatformStr: string;
begin
  {$IFDEF WIN64}
  Result := 'Win64';
  {$ELSE}
  Result := 'Win32';
  {$ENDIF}
end;

class function TCrashReport.GetModuleInfo(Addr: Pointer): string;
var
  Module: HMODULE;
  ModuleName: array[0..MAX_PATH] of Char;
  Offset: NativeUInt;
  MemInfo: TMemoryBasicInformation;
begin
  try
    if Addr = nil then
      Exit('Address: nil');

    Module := 0;
    if VirtualQuery(Addr, MemInfo, SizeOf(MemInfo)) <> 0 then
      Module := HMODULE(MemInfo.AllocationBase);

    if Module <> 0 then
    begin
      GetModuleFileName(Module, ModuleName, Length(ModuleName));
      Offset := NativeUInt(Addr) - Module;
      Result := Format('Module: %s, Address: $%p, Offset: $%x', [
        ExtractFileName(ModuleName), Addr, Offset]);
    end
    else
      Result := Format('Address: $%p', [Addr]);
  except
    Result := Format('Address: $%p', [Addr]);
  end;
end;

class function TCrashReport.GetLogDir: string;
begin
  try
    Result := TConfig.WorkPath + 'Logs\';
  except
    Result := GetEnvironmentVariable('TEMP') + '\X-RayCalc3\Logs\';
  end;
end;

class function TCrashReport.BuildReport(E: Exception; Addr: Pointer): string;
var
  SL: TStringList;
  Inner: Exception;
begin
  SL := TStringList.Create;
  try
    SL.Add('=== X-Ray Calc 3 - Crash Report ===');
    SL.Add(Format('Date/Time:       %s', [FormatDateTime('yyyy-mm-dd hh:nn:ss', Now)]));
    SL.Add(Format('App Version:     %s', [GetAppVersion]));
    SL.Add(Format('Platform:        %s', [GetPlatformStr]));
    SL.Add(Format('OS:              %s', [GetOSInfo]));
    SL.Add(Format('Memory:          %s', [GetMemoryInfo]));
    SL.Add('');
    SL.Add('--- Exception ---');
    SL.Add(Format('Class:           %s', [E.ClassName]));
    SL.Add(Format('Message:         %s', [E.Message]));
    SL.Add(Format('Location:        %s', [GetModuleInfo(Addr)]));

    Inner := E.InnerException;
    while Inner <> nil do
    begin
      SL.Add('');
      SL.Add('--- Inner Exception ---');
      SL.Add(Format('Class:           %s', [Inner.ClassName]));
      SL.Add(Format('Message:         %s', [Inner.Message]));
      Inner := Inner.InnerException;
    end;

    SL.Add('');
    SL.Add('=== End of Report ===');
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

class procedure TCrashReport.SaveToFile(const ReportText: string);
var
  LogDir, FileName: string;
  SL: TStringList;
begin
  try
    LogDir := GetLogDir;
    ForceDirectories(LogDir);
    FileName := LogDir + 'crash_' + FormatDateTime('yyyymmdd_hhnnss', Now) + '.log';
    SL := TStringList.Create;
    try
      SL.Text := ReportText;
      SL.SaveToFile(FileName);
    finally
      SL.Free;
    end;
  except
  end;
end;

{ TExceptionHelper }

class procedure TExceptionHelper.HandleException(Sender: TObject; E: Exception);
var
  Report: string;
  Dlg: TfrmCrashReport;
begin
  try
    Report := TCrashReport.BuildReport(E, ExceptAddr);
    TCrashReport.SaveToFile(Report);

    Dlg := TfrmCrashReport.Create(nil);
    try
      Dlg.ReportText := Report;
      Dlg.ShowModal;
    finally
      Dlg.Free;
    end;
  except
    on E2: Exception do
    try
      if Report = '' then
        Report := E.ClassName + ': ' + E.Message;
      MessageBox(0, PChar(Report), 'X-Ray Calc 3 - Unexpected Error',
        MB_OK or MB_ICONERROR or MB_TASKMODAL);
    except
    end;
  end;
end;

initialization

finalization

end.
