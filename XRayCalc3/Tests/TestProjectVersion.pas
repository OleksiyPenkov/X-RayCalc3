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

unit TestProjectVersion;

(* A project saved by a newer build is refused before anything is loaded. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestProjectVersion = class
  private
    FTemp: string;
    function ArchiveWith(const Name, ParamsText: string): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ReadsVersionFromParams;
    [Test] procedure NoParams_IsVersionZero;
    { CheckProjectFile is what every open path asks before it touches the
      open project: a refused file must come back as False with the reason,
      never as an exception that leaves the caller half-way. }
    [Test] procedure CheckProjectFile_Current_True;
    [Test] procedure CheckProjectFile_Newer_FalseWithReason;
    [Test] procedure CheckProjectFile_NotAZip_FalseWithReason;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Zip,
  unit_consts, unit_ProjectVersion;

procedure TTestProjectVersion.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'xrc_ver_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTemp);
end;

procedure TTestProjectVersion.TearDown;
begin
  if TDirectory.Exists(FTemp) then
    TDirectory.Delete(FTemp, True);
end;

{ An archive holding one member called Name with ParamsText in it. }
function TTestProjectVersion.ArchiveWith(const Name, ParamsText: string): string;
var
  Z: TZipFile;
begin
  Result := TPath.Combine(FTemp, TGUID.NewGuid.ToString + '.xrcx');
  Z := TZipFile.Create;
  try
    Z.Open(Result, zmWrite);
    Z.Add(TEncoding.UTF8.GetBytes(ParamsText), Name);
    Z.Close;
  finally
    Z.Free;
  end;
end;

procedure TTestProjectVersion.ReadsVersionFromParams;
begin
  Assert.AreEqual(9, XRCXFileVersion(ArchiveWith('params.dsc',
    '[PARAMS]'#13#10'N=5'#13#10'[INFO]'#13#10'Version=9'#13#10)));
end;

procedure TTestProjectVersion.NoParams_IsVersionZero;
begin
  Assert.AreEqual(0, XRCXFileVersion(ArchiveWith('calc.dat', '0.1 1'#13#10)));
end;

procedure TTestProjectVersion.CheckProjectFile_Current_True;
var
  Why: string;
begin
  Why := 'stale';
  Assert.IsTrue(CheckProjectFile(ArchiveWith('params.dsc',
    Format('[INFO]'#13#10'Version=%d'#13#10, [CURRENT_PROJECT_VERSION])), Why));
  Assert.AreEqual('', Why);
end;

procedure TTestProjectVersion.CheckProjectFile_Newer_FalseWithReason;
var
  Why: string;
begin
  Assert.IsFalse(CheckProjectFile(ArchiveWith('params.dsc',
    Format('[INFO]'#13#10'Version=%d'#13#10, [CURRENT_PROJECT_VERSION + 1])), Why));
  Assert.AreEqual(NewerProjectMessage(CURRENT_PROJECT_VERSION + 1), Why);
  Assert.Contains(Why, 'newer X-Ray Calc');
end;

procedure TTestProjectVersion.CheckProjectFile_NotAZip_FalseWithReason;
var
  Path, Why: string;
  OK: Boolean;
begin
  Path := TPath.Combine(FTemp, 'plain.xrcx');
  TFile.WriteAllText(Path, 'not an archive');
  OK := True;
  Assert.WillNotRaiseAny(
    procedure
    begin
      OK := CheckProjectFile(Path, Why);
    end);
  Assert.IsFalse(OK);
  Assert.StartsWith('Cannot open the project', Why);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProjectVersion);

end.
