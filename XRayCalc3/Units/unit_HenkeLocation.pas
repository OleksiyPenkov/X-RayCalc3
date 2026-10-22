(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_HenkeLocation;

interface

function DirIsWritable(const Dir: string): Boolean;

function CopyHenkeTables(const SrcDir, DstDir: string): Integer;

function EnsureHenkeDirWritable: Boolean;

implementation

uses
  System.SysUtils,
  System.IOUtils,
  System.Classes,
  System.UITypes,
  Vcl.Dialogs,
  unit_Config;

const
  USER_HENKE_DIR_NAME = 'Henke';

function DirIsWritable(const Dir: string): Boolean;
var
  Probe: string;
  Stream: TFileStream;
begin
  Result := False;
  if not TDirectory.Exists(Dir) then
    Exit;

  Probe := TPath.Combine(Dir, '~xrc_' + TGUID.NewGuid.ToString + '.tmp');
  try
    Stream := TFileStream.Create(Probe, fmCreate);
    Stream.Free;
    TFile.Delete(Probe);
    Result := True;
  except
    Result := False;
  end;
end;

function CopyHenkeTables(const SrcDir, DstDir: string): Integer;
var
  Src, Dst: string;
begin
  Result := 0;
  TDirectory.CreateDirectory(DstDir);

  for Src in TDirectory.GetFiles(SrcDir) do
  begin
    Dst := TPath.Combine(DstDir, TPath.GetFileName(Src));
    if TFile.Exists(Dst) then
      Continue;
    TFile.Copy(Src, Dst);
    Inc(Result);
  end;
end;

function EnsureHenkeDirWritable: Boolean;
var
  Current, Target: string;
begin
  Current := TConfig.SystemDir[sdHenke];
  if DirIsWritable(Current) then
    Exit(True);

  Target := TConfig.WorkPath + USER_HENKE_DIR_NAME;

  if MessageDlg(Format(
    'You do not have permission to write to the Henke tables folder:'#13#10 +
    '%s'#13#10#13#10 +
    'Copy the Henke tables to a folder you can write to and use it from now on?'#13#10 +
    '%s'#13#10#13#10 +
    'The folder can be changed later in Settings.',
    [Current, Target]), mtWarning, [mbYes, mbNo], 0) <> mrYes then
    Exit(False);

  try
    CopyHenkeTables(Current, Target);
    if not DirIsWritable(Target) then
      raise EInOutError.CreateFmt('Cannot write to %s', [Target]);
    TConfig.SystemDir[sdHenke] := Target;
    Result := True;
  except
    on E: Exception do
    begin
      MessageDlg(Format('Could not move the Henke tables to %s:'#13#10'%s',
        [Target, E.Message]), mtError, [mbOK], 0);
      Result := False;
    end;
  end;
end;

end.
