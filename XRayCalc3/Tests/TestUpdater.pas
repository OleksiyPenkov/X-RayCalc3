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

unit TestUpdater;

(* Help - Check for update: the version comparison and the reading of a GitHub
   /releases/latest answer. No network. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUpdater = class
  public
    [Test] procedure IsNewer_ComparesNumerically;
    [Test] procedure IsNewer_IgnoresBuildAndLeadingV;
    [Test] procedure Parse_PicksSetupAndDigest;
    [Test] procedure Parse_NoSetup_LeavesUrlEmpty;
    [Test] procedure Parse_NotARelease_Raises;
  end;

implementation

uses
  System.SysUtils, unit_Updater;

const
  RELEASE_JSON =
    '{"tag_name":"v3.10.0","html_url":"https://github.com/o/r/releases/tag/3.10.0",' +
    '"assets":[' +
    '{"name":"notes.txt","browser_download_url":"https://x/notes.txt","digest":"sha256:00"},' +
    '{"name":"XRayCalc3_Setup_3.10.0.exe","browser_download_url":"https://x/setup.exe",' +
    '"digest":"sha256:7d03a2c2"}]}';

procedure TTestUpdater.IsNewer_ComparesNumerically;
begin
  Assert.IsTrue(IsNewer('3.10.0', '3.9.4.1310'));
  Assert.IsFalse(IsNewer('3.9.4', '3.10.0.1350'));
  Assert.IsTrue(IsNewer('4.0', '3.99.99.1'));
  Assert.IsFalse(IsNewer('3.10.0', '3.10.0.1350'));
end;

procedure TTestUpdater.IsNewer_IgnoresBuildAndLeadingV;
begin
  Assert.IsFalse(IsNewer('3.9.2.970', '3.9.2.1000'));
  Assert.IsFalse(IsNewer('v3.9.2.2000', '3.9.2.970'));
  Assert.IsTrue(IsNewer('v3.9.3', '3.9.2.970'));
end;

procedure TTestUpdater.Parse_PicksSetupAndDigest;
var
  Info: TReleaseInfo;
begin
  Info := ParseRelease(RELEASE_JSON);
  Assert.AreEqual('3.10.0', Info.Version);
  Assert.AreEqual('XRayCalc3_Setup_3.10.0.exe', Info.SetupName);
  Assert.AreEqual('https://x/setup.exe', Info.SetupURL);
  Assert.AreEqual('7d03a2c2', Info.Sha256);
  Assert.AreEqual('https://github.com/o/r/releases/tag/3.10.0', Info.PageURL);
end;

procedure TTestUpdater.Parse_NoSetup_LeavesUrlEmpty;
var
  Info: TReleaseInfo;
begin
  Info := ParseRelease('{"tag_name":"3.9.4","assets":[]}');
  Assert.AreEqual('3.9.4', Info.Version);
  Assert.AreEqual('', Info.SetupURL);
end;

procedure TTestUpdater.Parse_NotARelease_Raises;
begin
  Assert.WillRaise(procedure begin ParseRelease('{"message":"Not Found"}') end, Exception);
  Assert.WillRaise(procedure begin ParseRelease('<html>') end, Exception);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUpdater);

end.
