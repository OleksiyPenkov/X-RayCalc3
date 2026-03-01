(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_FileUtils;

interface

uses
  Windows,
  StdCtrls;

function ClearDir(const DirectoryName: string): boolean;

procedure FillElementsList(const Path: string; var List: TListBox);
function GetSpecialPath(CSIDL: word): string;
function c_GetTempPath: String;
function CreateFolders(const Root: string; const Path: string): Boolean;

function SimpleShellExecute(
  hWnd: HWND;
  const FileName: string;
  const Parameters: string = '';
  const Operation: string = 'open';
  ShowCmd: Integer = SW_SHOWNORMAL;
  const Directory: string = ''
  ): Cardinal;

implementation

uses
  SysUtils,
  IOUtils,
  ShellApi,
  ShlObj;

function CreateFolders(const Root: string; const Path: string): Boolean;
var
  FullPath: string;
begin
  if Path = '\' then
    FullPath := Root + Path
  else
    FullPath := TPath.Combine(Root, Path);

  Result := SysUtils.ForceDirectories(FullPath);
end;

function c_GetTempPath: String;
var
  Buffer: array[0..MAX_PATH] of Char;
begin
  SetString(Result, Buffer, GetTempPath(Length(Buffer), Buffer));
end;

function GetSpecialPath(CSIDL: word): string;
var
  S: string;
begin
  SetLength(S, MAX_PATH);
  if not SHGetSpecialFolderPath(0, PChar(S), CSIDL, True) then
    S := '';
  Result := IncludeTrailingPathDelimiter(PChar(S));
end;

function SimpleQuoteString(const Value: string): string;
const
  QUOTECHAR = '"';
begin
  if (Value = '') or (Value[1] = QUOTECHAR) then
    Result := Value
  else
    Result := QUOTECHAR + Value + QUOTECHAR;
end;

function SimpleShellExecute(
  hWnd: HWND;
  const FileName: string;
  const Parameters: string = '';
  const Operation: string = 'open';
  ShowCmd: Integer = SW_SHOWNORMAL;
  const Directory: string = ''
  ): Cardinal;
var
  AFileName: string;
  AParameters: string;
  ADirectory: string;
begin
  AFileName := SimpleQuoteString(FileName);
  AParameters := SimpleQuoteString(Parameters);
  ADirectory := Directory;
  Result := ShellAPI.ShellExecute(
    hWnd,
    PChar(Operation),
    PChar(AFileName),
    PChar(AParameters),
    PChar(Directory),
    ShowCmd
  );
end;

procedure FillElementsList(const Path: string; var List: TListBox);
const
  Mask = '*.bin';
var
  F: TSearchRec;

  function ShortName(s: string):string;
  begin
    Result := copy(s, 1, Length(s) - 4 );
  end;

begin
  List.Items.Clear;

  if FindFirst(Path + Mask, faAnyFile, F) = 0 then
  try
    repeat
      List.Items.Add(ShortName(F.Name));
    until FindNext(F) <> 0;
  finally
    SysUtils.FindClose(F);
  end;
end;

{$WARNINGS OFF}

function ClearDir(const DirectoryName: string): boolean;
var
  ACurrentDir: string;
begin
  Result := True;
  ACurrentDir := IncludeTrailingPathDelimiter(DirectoryName);

  if TDirectory.Exists(ACurrentDir) then
  begin
    TDirectory.Delete(ACurrentDir, True);
  end;
end;
{$WARNINGS ON}

end.
