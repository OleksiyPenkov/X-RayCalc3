(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_ProjectVersion;

(* Which .xrcx project versions this build can read.

   TXRCProjectTree.ProjectLoadNode branches on the version, and one it has no
   branch for leaves the rest of the node unread: the stream goes out of step
   and every model loads without its structure. So a newer file must be refused
   before anything of the open project is discarded, which is what
   XRCXFileVersion is for: it reads [INFO] Version from params.dsc inside the
   archive and nothing else. *)

interface

/// <summary>[INFO] Version of an .xrcx archive, read from its params.dsc
/// without extracting anything else. 0 when the archive has no params.dsc or
/// the key is missing (the oldest projects). Raises when Path is not a zip
/// archive.</summary>
function XRCXFileVersion(const Path: string): Integer;

/// <summary>What to tell the user about a project of version V this build
/// cannot load.</summary>
function NewerProjectMessage(V: Integer): string;

/// <summary>Whether this build can open the project at Path, asked before
/// anything of the open project is touched. False, with the reason in Why,
/// for a newer version or a file that is not an archive; never raises.</summary>
function CheckProjectFile(const Path: string; out Why: string): Boolean;

implementation

uses
  System.SysUtils, System.Classes, System.Zip, System.IniFiles,
  unit_consts;

function XRCXFileVersion(const Path: string): Integer;
var
  Z: TZipFile;
  Bytes: TBytes;
  Stream: TBytesStream;
  Lines: TStringList;
  INF: TMemIniFile;
begin
  Result := 0;
  Z := TZipFile.Create;
  try
    Z.Open(Path, zmRead);
    if Z.IndexOf(PARAMETERS_FILE_NAME) < 0 then
      Exit;
    Z.Read(PARAMETERS_FILE_NAME, Bytes);
    Z.Close;
  finally
    Z.Free;
  end;

  Stream := TBytesStream.Create(Bytes);
  Lines := TStringList.Create;
  INF := TMemIniFile.Create('');
  try
    Lines.LoadFromStream(Stream);   // honours a BOM; ANSI otherwise, as TMemIniFile writes it
    INF.SetStrings(Lines);
    Result := INF.ReadInteger('INFO', 'Version', 0);
  finally
    INF.Free;
    Lines.Free;
    Stream.Free;
  end;
end;

function NewerProjectMessage(V: Integer): string;
begin
  Result := Format('This project cannot be opened: it was saved by a newer X-Ray Calc ' +
    '(project version %d; this version reads up to %d).', [V, CURRENT_PROJECT_VERSION]);
end;

function CheckProjectFile(const Path: string; out Why: string): Boolean;
var
  V: Integer;
begin
  Why := '';
  try
    V := XRCXFileVersion(Path);
  except
    on E: Exception do
    begin
      Why := 'Cannot open the project: ' + E.Message;
      Exit(False);
    end;
  end;
  Result := V <= CURRENT_PROJECT_VERSION;
  if not Result then
    Why := NewerProjectMessage(V);
end;

end.
