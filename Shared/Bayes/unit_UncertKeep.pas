(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_UncertKeep;

(* The one thing the main program does for the uncertainty tool when it saves.

   The tool writes its entries (uncert_<model id>.json, counts_<data id>.dat)
   into the project file while the project may be open in the main program,
   which saves by zipping its working folder over that file. Before it does,
   the entries on disk are taken into the working folder. The tool is their
   only writer, so the file is never older than the folder.

   Kept apart from unit_UncertFiles so that the main program links no part of
   the sampler. No VCL. *)

interface

/// <summary>Extracts every 'uncert_*.json' and 'counts_*.dat' entry of
/// ProjectFile into Dir, replacing files of the same name. Does nothing when
/// ProjectFile is missing or not an archive. Never raises.</summary>
procedure KeepToolEntries(const ProjectFile, Dir: string);

implementation

uses
  System.SysUtils, System.IOUtils, System.Zip;

function IsToolEntry(const Name: string): Boolean;
var
  L: string;
begin
  L := Name.ToLower;
  Result := (L.StartsWith('uncert_') and L.EndsWith('.json')) or
            (L.StartsWith('counts_') and L.EndsWith('.dat'));
end;

procedure KeepToolEntries(const ProjectFile, Dir: string);
var
  Z: TZipFile;
  Entry: string;
  Bytes: TBytes;
begin
  if not FileExists(ProjectFile) then
    Exit;
  try
    Z := TZipFile.Create;
    try
      Z.Open(ProjectFile, zmRead);
      for Entry in Z.FileNames do
        if IsToolEntry(Entry) then
        begin
          Z.Read(Entry, Bytes);
          TFile.WriteAllBytes(TPath.Combine(Dir, Entry), Bytes);
        end;
    finally
      Z.Free;
    end;
  except
    { not an archive, or unreadable: the save goes on without the tool's entries }
  end;
end;

end.
