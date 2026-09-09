unit TestMCPSandbox;

interface

uses DUnitX.TestFramework, System.SysUtils, System.IOUtils, unit_MCPSandbox, unit_MCPErrors;

type
  [TestFixture]
  TTestMCPSandbox = class
  private
    FTemp: string;
    FWD: TWorkDir;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure EnsureLayout_CreatesFourSubfolders;
    [Test] procedure ResolvePath_RelativeInside_ReturnsAbsoluteUnderRoot;
    [Test] procedure ResolvePath_ForwardSlashes_Normalised;
    [Test] procedure ResolvePath_DotDot_Refused;
    [Test] procedure ResolvePath_Rooted_Refused;
    [Test] procedure ResolvePath_DriveLetter_Refused;
    [Test] procedure ResolvePath_UNC_Refused;
    [Test] procedure ResolvePath_Empty_Refused;
    [Test] procedure ResolvePath_InboxWrite_Refused;
    [Test] procedure ResolvePath_InboxRead_Allowed;
    [Test] procedure RelativePath_RoundTrip;
    [Test] procedure FileSHA256_KnownValue;
  end;

implementation

procedure TTestMCPSandbox.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Sandbox_' + TGUID.NewGuid.ToString);
  FWD := TWorkDir.Create(FTemp);
  FWD.EnsureLayout;
end;

procedure TTestMCPSandbox.TearDown;
begin
  FWD.Free;
  if TDirectory.Exists(FTemp) then TDirectory.Delete(FTemp, True);
end;

procedure TTestMCPSandbox.EnsureLayout_CreatesFourSubfolders;
begin
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'projects')));
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'jobs')));
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'inbox')));
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'log')));
end;

procedure TTestMCPSandbox.ResolvePath_RelativeInside_ReturnsAbsoluteUnderRoot;
begin
  Assert.AreEqual(TPath.Combine(FTemp, 'projects\a.xrcx'), FWD.ResolvePath('projects\a.xrcx', True));
end;

procedure TTestMCPSandbox.ResolvePath_ForwardSlashes_Normalised;
begin
  Assert.AreEqual(TPath.Combine(FTemp, 'inbox\S1\c.dat'), FWD.ResolvePath('inbox/S1/c.dat', False));
end;

procedure TTestMCPSandbox.ResolvePath_DotDot_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('projects\..\..\x.txt', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_Rooted_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('\Windows\x.txt', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_DriveLetter_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('C:\x.txt', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_UNC_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('\\server\share\x', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_Empty_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_InboxWrite_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('inbox\S1\c.dat', True); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_InboxRead_Allowed;
begin
  Assert.IsTrue(FWD.ResolvePath('inbox\S1\c.dat', False).StartsWith(FTemp));
end;

procedure TTestMCPSandbox.RelativePath_RoundTrip;
begin
  Assert.AreEqual('jobs\fit-1\curve.dat', FWD.RelativePath(FWD.ResolvePath('jobs\fit-1\curve.dat', True)));
end;

procedure TTestMCPSandbox.FileSHA256_KnownValue;
var
  F: string;
begin
  F := TPath.Combine(FTemp, 'abc.txt');
  TFile.WriteAllText(F, 'abc', TEncoding.ASCII);
  Assert.AreEqual('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', FileSHA256(F));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPSandbox);
end.
