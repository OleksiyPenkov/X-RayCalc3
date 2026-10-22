unit TestHenkeLocation;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestHenkeLocation = class
  private
    FRoot: string;
    function NewDir(const Name: string): string;
    procedure PutFile(const Dir, Name, Text: string);
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Test_DirIsWritable_ExistingDir_True;
    [Test] procedure Test_DirIsWritable_ExistingDir_LeavesNothingBehind;
    [Test] procedure Test_DirIsWritable_MissingDir_False;
    [Test] procedure Test_DirIsWritable_PathIsFile_False;

    [Test] procedure Test_CopyHenkeTables_CopiesAllFiles;
    [Test] procedure Test_CopyHenkeTables_KeepsExistingTargetFile;
    [Test] procedure Test_CopyHenkeTables_MissingSource_Raises;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, unit_HenkeLocation;

procedure TTestHenkeLocation.Setup;
begin
  FRoot := TPath.Combine(TPath.GetTempPath, 'XRC_TestHenkeLoc_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FRoot);
end;

procedure TTestHenkeLocation.TearDown;
begin
  if TDirectory.Exists(FRoot) then
    TDirectory.Delete(FRoot, True);
end;

function TTestHenkeLocation.NewDir(const Name: string): string;
begin
  Result := TPath.Combine(FRoot, Name);
  TDirectory.CreateDirectory(Result);
end;

procedure TTestHenkeLocation.PutFile(const Dir, Name, Text: string);
begin
  TFile.WriteAllText(TPath.Combine(Dir, Name), Text);
end;

procedure TTestHenkeLocation.Test_DirIsWritable_ExistingDir_True;
begin
  Assert.IsTrue(DirIsWritable(NewDir('w')));
end;

procedure TTestHenkeLocation.Test_DirIsWritable_ExistingDir_LeavesNothingBehind;
var
  Dir: string;
begin
  Dir := NewDir('w');
  DirIsWritable(Dir);
  Assert.AreEqual(0, Length(TDirectory.GetFileSystemEntries(Dir)));
end;

procedure TTestHenkeLocation.Test_DirIsWritable_MissingDir_False;
begin
  Assert.IsFalse(DirIsWritable(TPath.Combine(FRoot, 'nope')));
end;

procedure TTestHenkeLocation.Test_DirIsWritable_PathIsFile_False;
var
  Dir: string;
begin
  Dir := NewDir('f');
  PutFile(Dir, 'x.bin', 'x');
  Assert.IsFalse(DirIsWritable(TPath.Combine(Dir, 'x.bin')));
end;

procedure TTestHenkeLocation.Test_CopyHenkeTables_CopiesAllFiles;
var
  Src, Dst: string;
begin
  Src := NewDir('src');
  Dst := TPath.Combine(FRoot, 'new\dst');
  PutFile(Src, 'Si.bin', 'silicon');
  PutFile(Src, 'W.bin', 'tungsten');

  Assert.AreEqual(2, CopyHenkeTables(Src, Dst));
  Assert.AreEqual('silicon', TFile.ReadAllText(TPath.Combine(Dst, 'Si.bin')));
  Assert.AreEqual('tungsten', TFile.ReadAllText(TPath.Combine(Dst, 'W.bin')));
end;

procedure TTestHenkeLocation.Test_CopyHenkeTables_KeepsExistingTargetFile;
var
  Src, Dst: string;
begin
  Src := NewDir('src');
  Dst := NewDir('dst');
  PutFile(Src, 'Si.bin', 'shipped');
  PutFile(Src, 'W.bin', 'tungsten');
  PutFile(Dst, 'Si.bin', 'edited by user');

  Assert.AreEqual(1, CopyHenkeTables(Src, Dst));
  Assert.AreEqual('edited by user', TFile.ReadAllText(TPath.Combine(Dst, 'Si.bin')));
  Assert.AreEqual('tungsten', TFile.ReadAllText(TPath.Combine(Dst, 'W.bin')));
end;

procedure TTestHenkeLocation.Test_CopyHenkeTables_MissingSource_Raises;
begin
  Assert.WillRaise(
    procedure
    begin
      CopyHenkeTables(TPath.Combine(FRoot, 'nope'), TPath.Combine(FRoot, 'dst'));
    end,
    EDirectoryNotFoundException);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestHenkeLocation);

end.
