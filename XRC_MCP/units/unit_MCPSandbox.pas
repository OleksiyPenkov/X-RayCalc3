(* *****************************************************************************
  *
  *   X-Ray Calc 3 - XRC_MCP, the calculation engine as an MCP server
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

unit unit_MCPSandbox;

{ The work directory every tool is confined to.

  All tool arguments that name a file are *relative* paths interpreted against
  the work directory root. ResolvePath turns such a relative path into an
  absolute one and refuses anything that could escape the sandbox; RelativePath
  turns an absolute path back into the root-relative form echoed to the client.

  Layout created by EnsureLayout:
    <root>\projects   .xrcx projects written by the server
    <root>\jobs       per-job folders (inputs, results, logs)
    <root>\inbox      read-only drop box for measured data
    <root>\log        the server journal }

interface

uses System.SysUtils, System.Classes, System.IOUtils;

type
  TWorkDir = class
  private
    FRoot: string;   // absolute, no trailing delimiter
  public
    constructor Create(const ARoot: string);
    /// <summary>Reads --workdir from the command line. Raises a plain
    /// Exception (not EMCPError) when it is missing: at that point there is
    /// no protocol session to report a structured error into.</summary>
    class function CreateFromCommandLine: TWorkDir;
    procedure EnsureLayout;   // creates root, projects, jobs, inbox, log
    /// <summary>Absolute path under Root for a client-supplied relative path.
    /// Raises EMCPError('invalid_argument') when empty and
    /// EMCPError('path_outside_workdir') for rooted / drive-qualified / UNC
    /// paths and for anything containing a '..' segment. When ForWrite is
    /// True, paths inside the inbox raise EMCPError('inbox_readonly').</summary>
    function ResolvePath(const Rel: string; ForWrite: Boolean): string;
    /// <summary>Root-relative form (backslashes) of an absolute path, for
    /// echoing back to the client. Paths outside Root are returned as-is.</summary>
    function RelativePath(const Abs: string): string;
    function ProjectsDir: string;
    function JobsDir: string;
    function InboxDir: string;
    function LogDir: string;
    property Root: string read FRoot;
  end;

function FileSHA256(const Path: string): string;       // lowercase hex
function FileSizeOf(const Path: string): Int64;
function FileModifiedUTC(const Path: string): string;  // ISO-8601, UTC
function NowUTCString: string;                         // ISO-8601 with millis, UTC

var
  WorkDir: TWorkDir;

implementation

uses System.Hash, System.DateUtils, System.StrUtils, unit_MCPErrors;

{ TWorkDir }

constructor TWorkDir.Create(const ARoot: string);
begin
  inherited Create;
  if ARoot.Trim.IsEmpty then
    raise EMCPError.Create('invalid_argument', '--workdir must not be empty');
  if not TPath.IsPathRooted(ARoot.Trim) then
    raise EMCPError.Create('invalid_argument', '--workdir must be an absolute path', ARoot);
  FRoot := ExcludeTrailingPathDelimiter(ExpandFileName(ARoot.Trim));
end;

class function TWorkDir.CreateFromCommandLine: TWorkDir;
var
  I: Integer;
  Param, Value: string;
begin
  { Parsed by hand rather than with FindCmdLineSwitch: the registration command
    passes the GNU-style `--workdir "<path>"`, whose value sits in the next
    parameter and whose double dash FindCmdLineSwitch does not strip. Both
    `--workdir <path>` and `--workdir=<path>` are accepted. }
  Value := '';
  for I := 1 to ParamCount do
  begin
    Param := ParamStr(I);
    if Param.StartsWith('--workdir=', True) then
    begin
      Value := Param.Substring(Length('--workdir='));
      Break;
    end;
    if SameText(Param, '--workdir') or SameText(Param, '-workdir') or SameText(Param, '/workdir') then
    begin
      if I < ParamCount then
        Value := ParamStr(I + 1);
      Break;
    end;
  end;
  if Value.Trim.IsEmpty then
    raise Exception.Create('--workdir <path> is required');
  Result := TWorkDir.Create(Value);
end;

procedure TWorkDir.EnsureLayout;
begin
  TDirectory.CreateDirectory(FRoot);
  TDirectory.CreateDirectory(ProjectsDir);
  TDirectory.CreateDirectory(JobsDir);
  TDirectory.CreateDirectory(InboxDir);
  TDirectory.CreateDirectory(LogDir);
end;

function TWorkDir.ProjectsDir: string;
begin
  Result := TPath.Combine(FRoot, 'projects');
end;

function TWorkDir.JobsDir: string;
begin
  Result := TPath.Combine(FRoot, 'jobs');
end;

function TWorkDir.InboxDir: string;
begin
  Result := TPath.Combine(FRoot, 'inbox');
end;

function TWorkDir.LogDir: string;
begin
  Result := TPath.Combine(FRoot, 'log');
end;

function TWorkDir.ResolvePath(const Rel: string; ForWrite: Boolean): string;
var
  S, Full, Seg: string;
begin
  S := StringReplace(Trim(Rel), '/', '\', [rfReplaceAll]);
  if S = '' then
    raise EMCPError.Create('invalid_argument', 'Path argument is empty');
  if S.StartsWith('\\') or (Pos(':', S) > 0) or S.StartsWith('\') then
    raise EMCPError.Create('path_outside_workdir',
      'Only paths relative to the working directory are accepted', Rel);
  for Seg in S.Split(['\']) do
    if Seg = '..' then
      raise EMCPError.Create('path_outside_workdir', '".." is not allowed in paths', Rel);
  Full := ExpandFileName(TPath.Combine(FRoot, S));
  if not StartsText(FRoot + '\', Full) then
    raise EMCPError.Create('path_outside_workdir',
      'Path resolves outside the working directory', Rel);
  if ForWrite and (SameText(Full, InboxDir) or StartsText(InboxDir + '\', Full)) then
    raise EMCPError.Create('inbox_readonly', 'The inbox is never written by the server', Rel);
  Result := Full;
end;

function TWorkDir.RelativePath(const Abs: string): string;
begin
  if StartsText(FRoot + '\', Abs) then
    Result := Copy(Abs, Length(FRoot) + 2, MaxInt)
  else
    Result := Abs;
end;

function FileSHA256(const Path: string): string;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  try
    Result := LowerCase(THashSHA2.GetHashString(Stream, THashSHA2.TSHA2Version.SHA256));
  finally
    Stream.Free;
  end;
end;

function FileSizeOf(const Path: string): Int64;
begin
  Result := TFile.GetSize(Path);
end;

function FileModifiedUTC(const Path: string): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', TFile.GetLastWriteTimeUtc(Path));
end;

function NowUTCString: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now));
end;

end.
