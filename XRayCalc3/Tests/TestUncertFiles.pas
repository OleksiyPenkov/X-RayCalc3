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

unit TestUncertFiles;

(* The uncertainty result and the priors as entries of the project file: the
   JSON round trip, the fingerprint, and the entry writer that touches nothing
   else in the archive. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUncertFiles = class
  private
    FDir: string;
    function NewProject(const Name: string): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Json_RoundTrip;
    [Test] procedure Json_NotSettled_KeepsTheMessageAndNoRanges;
    [Test] procedure Json_Garbage_IsRefused;
    [Test] procedure Json_NumbersComeBackToTheLastBit;
    [Test] procedure Fingerprint_FollowsWhatTheResultDependsOn;
    [Test] procedure WriteEntries_AddsAndLeavesTheRestAlone;
    [Test] procedure WriteEntries_ReplacesItsOwnEntry;
    [Test] procedure WriteEntries_ReadOnlyFile_SaysSoAndTouchesNothing;
    [Test] procedure WriteEntries_FileInUse_SaysSoAndTouchesNothing;
    [Test] procedure ReadEntry_Missing_IsFalse;
    [Test] procedure EntryNames;
    [Test] procedure KeepToolEntries_CopiesOnlyTheToolsEntries;
    [Test] procedure KeepToolEntries_ReplacesAnOlderFile;
    [Test] procedure KeepToolEntries_EntryWithAPath_IsSkipped;
    [Test] procedure MainProgramSave_KeepsWhatTheToolWroteMeanwhile;
    [Test] procedure KeepToolEntries_MissingFile_DoesNothing;
    [Test] procedure RemoveToolEntries_TakesOnlyTheToolsEntries;
    [Test] procedure RemoveToolEntries_ReadOnlyFile_SaysSoAndTouchesNothing;
    [Test] procedure MainProgramSave_AfterTheToolCleared_DoesNotBringTheEntriesBack;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math, System.Zip,
  unit_Types, unit_MCPProjectFile, unit_UncertRequest, unit_UncertRun, unit_UncertFiles,
  unit_UncertKeep, TestUncertRequest;

procedure TTestUncertFiles.Setup;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'xrcuncert_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FDir);
end;

procedure TTestUncertFiles.TearDown;
var
  F: string;
begin
  for F in TDirectory.GetFiles(FDir) do
    TFile.SetAttributes(F, []);
  TDirectory.Delete(FDir, True);
end;

function TTestUncertFiles.NewProject(const Name: string): string;
begin
  Result := TPath.Combine(FDir, Name);
  WriteXRCX(Result, ProjectOf(WSi(10), 1));
end;

function EntryBytes(const Zip, Name: string): TBytes;
var
  Z: TZipFile;
begin
  Z := TZipFile.Create;
  try
    Z.Open(Zip, zmRead);
    Z.Read(Name, Result);
  finally
    Z.Free;
  end;
end;

function EntryList(const Zip: string): TArray<string>;
var
  Z: TZipFile;
begin
  Z := TZipFile.Create;
  try
    Z.Open(Zip, zmRead);
    Result := Z.FileNames;
  finally
    Z.Free;
  end;
end;

function SameBytes(const A, B: TBytes): Boolean;
begin
  Result := (Length(A) = Length(B)) and ((Length(A) = 0) or CompareMem(@A[0], @B[0], Length(A)));
end;

function Sample: TStoredUncert;
var
  Req: TUncertRequest;
begin
  Assert.AreEqual('', BuildRequest(ProjectOf(WSi(10), 1), Req));
  Result := Default(TStoredUncert);
  Result.Fingerprint := 'abc123';
  Result.Names := Req.Names;
  SetLength(Result.Priors, 1);
  Result.Priors[0].Name := 's0.total';
  Result.Priors[0].Mean := 500;
  Result.Priors[0].SD := 2.5;
  Result.Priors[0].Note := 'TEM, "cross-section" 3';
  Result.HasResult := True;
  Result.Result.Settled := True;
  Result.Result.Device := 'CPU';
  Result.Result.Seconds := 12.5;
  Result.Result.Repeated := True;
  Result.Result.Walkers := 32;
  Result.Result.StepsRun := 4000;
  Result.Result.Warnings := ['No raw counts: the errors rely on the estimated noise only.'];
  SetLength(Result.Result.Values, 2);
  Result.Result.Values[0].Name := 's0.l0.thickness';
  Result.Result.Values[0].Best := 20;
  Result.Result.Values[0].P2_5 := 19.6;
  Result.Result.Values[0].P16 := 19.8;
  Result.Result.Values[0].P50 := 20.01;
  Result.Result.Values[0].P84 := 20.2;
  Result.Result.Values[0].P97_5 := 20.4;
  Result.Result.Values[0].Minus := 0.21;
  Result.Result.Values[0].Plus := 0.19;
  Result.Result.Values[0].RHat := 1.02;
  Result.Result.Values[0].AtLimit := True;
  Result.Result.Values[1].Name := 's0.period_mean';
  Result.Result.Values[1].Best := 50;
  Result.Result.Values[1].P50 := 50;
  Result.Result.Values[1].P16 := NaN;          // a number that cannot be written as JSON
  Result.Result.Band.Theta := [0.3, 0.35];
  Result.Result.Band.Measured := [1E-3, 9E-4];
  Result.Result.Band.P16 := [9.5E-4, 8.5E-4];
  Result.Result.Band.P50 := [1E-3, 9E-4];
  Result.Result.Band.P84 := [1.05E-3, 9.5E-4];
  Result.Result.Correlation := [[1, -0.4], [-0.4, 1]];
end;

procedure TTestUncertFiles.Json_RoundTrip;
var
  A, B: TStoredUncert;
begin
  A := Sample;
  Assert.IsTrue(StoredFromJSON(StoredToJSON(A), B));
  Assert.AreEqual(A.Fingerprint, B.Fingerprint);
  Assert.AreEqual(1, Length(B.Priors));
  Assert.AreEqual('s0.total', B.Priors[0].Name);
  Assert.AreEqual(500.0, B.Priors[0].Mean, 0.0);
  Assert.AreEqual(2.5, B.Priors[0].SD, 0.0);
  Assert.AreEqual(A.Priors[0].Note, B.Priors[0].Note);
  Assert.IsTrue(B.HasResult);
  Assert.IsTrue(B.Result.Settled);
  Assert.AreEqual('CPU', B.Result.Device);
  Assert.AreEqual(12.5, B.Result.Seconds, 0.0);
  Assert.IsTrue(B.Result.Repeated);
  Assert.AreEqual(32, B.Result.Walkers);
  Assert.AreEqual(4000, B.Result.StepsRun);
  Assert.AreEqual(1, Length(B.Result.Warnings));
  Assert.AreEqual(A.Result.Warnings[0], B.Result.Warnings[0]);
  Assert.AreEqual(2, Length(B.Result.Values));
  Assert.AreEqual('s0.l0.thickness', B.Result.Values[0].Name);
  Assert.AreEqual(20.01, B.Result.Values[0].P50, 0.0);
  Assert.AreEqual(19.6, B.Result.Values[0].P2_5, 0.0);
  Assert.AreEqual(0.19, B.Result.Values[0].Plus, 0.0);
  Assert.AreEqual(1.02, B.Result.Values[0].RHat, 0.0);
  Assert.IsTrue(B.Result.Values[0].AtLimit);
  Assert.IsTrue(IsNaN(B.Result.Values[1].P16), 'NaN comes back as NaN');
  Assert.AreEqual(2, Length(B.Result.Band.Theta));
  Assert.AreEqual(9.5E-4, B.Result.Band.P84[1], 0.0);
  Assert.AreEqual(-0.4, B.Result.Correlation[0][1], 0.0);
  Assert.AreEqual(Length(A.Names), Length(B.Names));
  Assert.AreEqual(A.Names[0].Caption, B.Names[0].Caption, 'captions with non-ASCII letters survive');
  Assert.IsTrue(A.Names[0].Kind = B.Names[0].Kind);
  Assert.AreEqual(A.Names[High(A.Names)].Group, B.Names[High(B.Names)].Group);
end;

procedure TTestUncertFiles.Json_NotSettled_KeepsTheMessageAndNoRanges;
var
  A, B: TStoredUncert;
begin
  A := Sample;
  A.Result.Settled := False;
  A.Result.Message := MSG_NOT_SETTLED;
  Assert.IsTrue(StoredFromJSON(StoredToJSON(A), B));
  Assert.IsFalse(B.Result.Settled);
  Assert.AreEqual(MSG_NOT_SETTLED, B.Result.Message);
  A := Default(TStoredUncert);            // priors entered, nothing run yet
  SetLength(A.Priors, 1);
  A.Priors[0].Name := 's0.total';
  Assert.IsTrue(StoredFromJSON(StoredToJSON(A), B));
  Assert.IsFalse(B.HasResult);
  Assert.AreEqual(1, Length(B.Priors));
end;

{ Found by the end-to-end run: 34.0001358059798... came back one bit off. }
procedure TTestUncertFiles.Json_NumbersComeBackToTheLastBit;
const
  Awkward: array [0 .. 3] of Double = (1 / 3, 34.000135805979752, 6.3861378180304703, 1.2345678901234567E-9);
var
  A, B: TStoredUncert;
  i: Integer;
begin
  A := Sample;
  for i := Low(Awkward) to High(Awkward) do
  begin
    A.Result.Values[0].P50 := Awkward[i];
    A.Result.Band.P50[0] := Awkward[i];
    A.Priors[0].Mean := Awkward[i];
    Assert.IsTrue(StoredFromJSON(StoredToJSON(A), B));
    Assert.AreEqual(Awkward[i], B.Result.Values[0].P50, 0.0);
    Assert.AreEqual(Awkward[i], B.Result.Band.P50[0], 0.0);
    Assert.AreEqual(Awkward[i], B.Priors[0].Mean, 0.0);
  end;
end;

procedure TTestUncertFiles.Json_Garbage_IsRefused;
var
  B: TStoredUncert;
begin
  Assert.IsFalse(StoredFromJSON('', B));
  Assert.IsFalse(StoredFromJSON('not json', B));
  Assert.IsFalse(StoredFromJSON('{"format": 99}', B), 'a format this build does not know');
  { format 1 passed a weaker check: its known values are kept, its result is not shown }
  Assert.IsTrue(StoredFromJSON('{"format":1,"priors":[{"name":"s0.total","mean":500,"sd":2,"note":"n"}],' +
    '"result":{"settled":true,"values":[]}}', B));
  Assert.AreEqual(1, Integer(Length(B.Priors)));
  Assert.AreEqual(500.0, B.Priors[0].Mean, 0.0);
  Assert.IsFalse(B.HasResult, 'a result of the older check is not read');
  Assert.IsFalse(StoredFromJSON('[1, 2]', B));
end;

procedure TTestUncertFiles.Fingerprint_FollowsWhatTheResultDependsOn;
var
  P, Q: TXRCXProject;
  Pr: TArray<TUncertPrior>;
  Base: string;
begin
  P := ProjectOf(WSi(10), 1);
  Base := Fingerprint(P, [100, 200], nil);
  Assert.AreEqual(64, Length(Base), 'SHA-256 in hex');
  Assert.AreEqual(Base, Fingerprint(P, [100, 200], nil), 'the same inputs, the same fingerprint');

  Q := P;
  Q.ModelTitle := 'renamed';
  Assert.AreEqual(Base, Fingerprint(Q, [100, 200], nil), 'a title is not an input');

  Q := ProjectOf(WSi(11), 1);
  Assert.AreNotEqual(Base, Fingerprint(Q, [100, 200], nil), 'the structure');
  Q := P;
  Q.DataCurve := Copy(P.DataCurve);
  Q.DataCurve[3].r := Q.DataCurve[3].r * 1.01;
  Assert.AreNotEqual(Base, Fingerprint(Q, [100, 200], nil), 'a data point');
  Assert.AreNotEqual(Base, Fingerprint(P, [100, 201], nil), 'a count');
  Q := P;
  Q.Params.MinLimit := P.Params.MinLimit * 100;
  Assert.AreNotEqual(Base, Fingerprint(Q, [100, 200], nil), 'the lower limit the model curve is cut at');
  Assert.AreNotEqual(Base, Fingerprint(P, nil, nil), 'no counts');
  Q := P;
  Q.Params.FitMode := 2;
  Assert.AreNotEqual(Base, Fingerprint(Q, [100, 200], nil), 'the fit mode');
  SetLength(Pr, 1);
  Pr[0].Name := 's0.total';
  Pr[0].Mean := 500;
  Pr[0].SD := 2;
  Assert.AreNotEqual(Base, Fingerprint(P, [100, 200], Pr), 'a prior');
end;

procedure TTestUncertFiles.WriteEntries_AddsAndLeavesTheRestAlone;
var
  Path, Text, E: string;
  Before: TArray<string>;
  Old: TArray<TBytes>;
  i: Integer;
  R: TXRCXProject;
begin
  Path := NewProject('a.xrcx');
  Before := EntryList(Path);
  SetLength(Old, Length(Before));
  for i := 0 to High(Before) do
    Old[i] := EntryBytes(Path, Before[i]);

  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json', 'counts_2.dat'], ['{"a": 1}', '10'#10'20'#10]));

  Assert.AreEqual(Length(Before) + 2, Length(EntryList(Path)));
  for i := 0 to High(Before) do
    Assert.IsTrue(SameBytes(Old[i], EntryBytes(Path, Before[i])), Before[i] + ' is byte for byte what it was');
  Assert.IsTrue(ReadEntry(Path, 'uncert_1.json', Text));
  Assert.AreEqual('{"a": 1}', Text);
  Assert.IsTrue(ReadEntry(Path, 'counts_2.dat', Text));
  Assert.AreEqual('10'#10'20'#10, Text);
  R := ReadXRCX(Path);
  Assert.AreEqual('Model 1', R.ModelTitle, 'the project still opens');
  for E in TDirectory.GetFiles(FDir) do
    Assert.AreEqual('a.xrcx', TPath.GetFileName(E), 'no temporary file is left behind');
end;

procedure TTestUncertFiles.WriteEntries_ReplacesItsOwnEntry;
var
  Path, Text: string;
  N: Integer;
begin
  Path := NewProject('b.xrcx');
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json'], ['first']));
  N := Length(EntryList(Path));
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json'], ['second']));
  Assert.AreEqual(N, Length(EntryList(Path)), 'replaced, not added again');
  Assert.IsTrue(ReadEntry(Path, 'uncert_1.json', Text));
  Assert.AreEqual('second', Text);
end;

procedure TTestUncertFiles.WriteEntries_ReadOnlyFile_SaysSoAndTouchesNothing;
var
  Path, Why: string;
  Old: TBytes;
begin
  Path := NewProject('ro.xrcx');
  Old := TFile.ReadAllBytes(Path);
  TFile.SetAttributes(Path, [TFileAttribute.faReadOnly]);
  Why := WriteEntries(Path, ['uncert_1.json'], ['x']);
  Assert.Contains(Why, 'read-only');
  Assert.IsFalse(Why.Contains('result'), 'it may be a known value that was being stored: ' + Why);
  Assert.IsTrue(SameBytes(Old, TFile.ReadAllBytes(Path)), 'the project is what it was');
  Assert.AreEqual(1, Length(TDirectory.GetFiles(FDir)), 'no temporary file is left behind');
end;

procedure TTestUncertFiles.WriteEntries_FileInUse_SaysSoAndTouchesNothing;
var
  Path, Why: string;
  Old: TBytes;
  Lock: TFileStream;
begin
  Path := NewProject('busy.xrcx');
  Old := TFile.ReadAllBytes(Path);
  Lock := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);   // another program has it open
  try
    Why := WriteEntries(Path, ['uncert_1.json'], ['x']);
  finally
    Lock.Free;
  end;
  Assert.Contains(Why, 'could be stored');
  Assert.IsFalse(Why.Contains('result'), Why);
  Assert.IsTrue(SameBytes(Old, TFile.ReadAllBytes(Path)), 'the project is what it was');
  Assert.AreEqual(1, Length(TDirectory.GetFiles(FDir)), 'nothing else is left beside it');
end;

procedure TTestUncertFiles.ReadEntry_Missing_IsFalse;
var
  Text: string;
begin
  Assert.IsFalse(ReadEntry(NewProject('c.xrcx'), 'uncert_1.json', Text));
  Assert.IsFalse(ReadEntry(TPath.Combine(FDir, 'none.xrcx'), 'uncert_1.json', Text));
end;

procedure TTestUncertFiles.EntryNames;
begin
  Assert.AreEqual('uncert_3.json', UncertEntryName(3));
  Assert.AreEqual('counts_12.dat', CountsEntryName(12));
end;

{ The main program's save: what the tool wrote into the file on disk goes into
  the folder the project is zipped from. }
procedure TTestUncertFiles.KeepToolEntries_CopiesOnlyTheToolsEntries;
var
  Path, Dir: string;
begin
  Path := NewProject('a.xrcx');
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json', 'counts_2.dat'], ['{"a":1}', '5' + sLineBreak + '7']));
  Dir := TPath.Combine(FDir, 'work');
  TDirectory.CreateDirectory(Dir);
  KeepToolEntries(Path, Dir + PathDelim);
  Assert.AreEqual('{"a":1}', TFile.ReadAllText(TPath.Combine(Dir, 'uncert_1.json'), TEncoding.UTF8));
  Assert.IsTrue(SameBytes(EntryBytes(Path, 'counts_2.dat'), TFile.ReadAllBytes(TPath.Combine(Dir, 'counts_2.dat'))));
  Assert.AreEqual(2, Integer(Length(TDirectory.GetFiles(Dir))), 'nothing of the project itself');
end;

procedure TTestUncertFiles.KeepToolEntries_ReplacesAnOlderFile;
var
  Path, Dir: string;
begin
  Path := NewProject('a.xrcx');
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json'], ['new']));
  Dir := TPath.Combine(FDir, 'work');
  TDirectory.CreateDirectory(Dir);
  TFile.WriteAllText(TPath.Combine(Dir, 'uncert_1.json'), 'old');
  KeepToolEntries(Path, Dir);
  Assert.AreEqual('new', TFile.ReadAllText(TPath.Combine(Dir, 'uncert_1.json'), TEncoding.UTF8));
end;

{ An archive is not trusted to name its entries politely: one with a folder in
  its name is left alone, and the plain ones beside it are still taken. }
procedure TTestUncertFiles.KeepToolEntries_EntryWithAPath_IsSkipped;
var
  Path, Dir, Work: string;
  Z: TZipFile;
begin
  Path := TPath.Combine(FDir, 'odd.xrcx');
  Z := TZipFile.Create;
  try
    Z.Open(Path, zmWrite);
    Z.Add(TEncoding.UTF8.GetBytes('out'), 'uncert_x/../../uncert_escaped.json');
    Z.Add(TEncoding.UTF8.GetBytes('sub'), 'sub/uncert_2.json');
    Z.Add(TEncoding.UTF8.GetBytes('good'), 'uncert_1.json');
    Z.Close;
  finally
    Z.Free;
  end;
  Dir := TPath.Combine(FDir, 'a');
  Work := TPath.Combine(Dir, 'work');
  TDirectory.CreateDirectory(Work);
  KeepToolEntries(Path, Work);
  Assert.AreEqual('good', TFile.ReadAllText(TPath.Combine(Work, 'uncert_1.json'), TEncoding.UTF8));
  Assert.AreEqual(1, Integer(Length(TDirectory.GetFiles(Dir, '*', TSearchOption.soAllDirectories))),
    'nothing but the plain entry, and nothing outside the folder');
  Assert.IsFalse(TFile.Exists(TPath.Combine(FDir, 'uncert_escaped.json')));
end;

{ The main program's save as it happens: the project was extracted into a
  working folder when it was opened; the tool then writes into the file; the
  save takes the tool's entries, deletes the file and zips the folder. }
procedure TTestUncertFiles.MainProgramSave_KeepsWhatTheToolWroteMeanwhile;
var
  Path, Work, Text, F: string;
  Before: TArray<string>;
  Z: TZipFile;
begin
  Path := NewProject('open.xrcx');
  Before := EntryList(Path);
  Work := TPath.Combine(FDir, 'work');
  TZipFile.ExtractZipFile(Path, Work);                       // File - Open

  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json'], ['made while open']));   // the tool

  KeepToolEntries(Path, Work);                               // File - Save
  TFile.Delete(Path);
  Z := TZipFile.Create;
  try
    Z.Open(Path, zmWrite);
    for F in TDirectory.GetFiles(Work) do
      Z.Add(F, TPath.GetFileName(F));
    Z.Close;
  finally
    Z.Free;
  end;

  Assert.IsTrue(ReadEntry(Path, 'uncert_1.json', Text), 'the result is in the saved project');
  Assert.AreEqual('made while open', Text);
  Assert.AreEqual(Length(Before) + 1, Integer(Length(EntryList(Path))), 'beside everything the project had');
  Assert.AreEqual('Model 1', ReadXRCX(Path).ModelTitle, 'which still opens');
end;

procedure TTestUncertFiles.KeepToolEntries_MissingFile_DoesNothing;
var
  Dir, Bad: string;
begin
  Dir := TPath.Combine(FDir, 'work');
  TDirectory.CreateDirectory(Dir);
  KeepToolEntries(TPath.Combine(FDir, 'none.xrcx'), Dir);
  KeepToolEntries('', Dir);
  Bad := TPath.Combine(FDir, 'bad.xrcx');
  TFile.WriteAllText(Bad, 'not an archive');
  KeepToolEntries(Bad, Dir);
  Assert.AreEqual(0, Integer(Length(TDirectory.GetFiles(Dir))));
end;

procedure TTestUncertFiles.RemoveToolEntries_TakesOnlyTheToolsEntries;
var
  Path, E: string;
  Before: TArray<string>;
  Old: TArray<TBytes>;
  i: Integer;
begin
  Path := NewProject('a.xrcx');
  Before := EntryList(Path);
  SetLength(Old, Length(Before));
  for i := 0 to High(Before) do
    Old[i] := EntryBytes(Path, Before[i]);
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json', 'uncert_7.json', 'counts_2.dat'], ['a', 'b', 'c']));

  Assert.AreEqual('', RemoveToolEntries(Path));

  Assert.AreEqual(Length(Before), Length(EntryList(Path)), 'every entry of the tool is gone, of any model');
  for i := 0 to High(Before) do
    Assert.IsTrue(SameBytes(Old[i], EntryBytes(Path, Before[i])), Before[i] + ' is byte for byte what it was');
  Assert.AreEqual('Model 1', ReadXRCX(Path).ModelTitle, 'the project still opens');
  for E in TDirectory.GetFiles(FDir) do
    Assert.AreEqual('a.xrcx', TPath.GetFileName(E), 'no temporary file is left behind');
  Assert.AreEqual('', RemoveToolEntries(Path), 'nothing to remove is not a failure');
end;

procedure TTestUncertFiles.RemoveToolEntries_ReadOnlyFile_SaysSoAndTouchesNothing;
var
  Path, Why: string;
  Old: TBytes;
begin
  Path := NewProject('ro.xrcx');
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json'], ['x']));
  Old := TFile.ReadAllBytes(Path);
  TFile.SetAttributes(Path, [TFileAttribute.faReadOnly]);
  Why := RemoveToolEntries(Path);
  Assert.Contains(Why, 'read-only');
  Assert.IsFalse(Why.Contains('stored'), 'nothing was being stored: ' + Why);
  Assert.IsTrue(SameBytes(Old, TFile.ReadAllBytes(Path)), 'the project is what it was');
end;

{ The project is open in the main program, its working folder holding the
  entries it was extracted with; the tool clears them from the file; the next
  save must not zip the folder's copies back in. }
procedure TTestUncertFiles.MainProgramSave_AfterTheToolCleared_DoesNotBringTheEntriesBack;
var
  Path, Work: string;
begin
  Path := NewProject('open.xrcx');
  Assert.AreEqual('', WriteEntries(Path, ['uncert_1.json', 'counts_2.dat'], ['r', 'c']));
  Work := TPath.Combine(FDir, 'work');
  TZipFile.ExtractZipFile(Path, Work);                       // File - Open
  Assert.IsTrue(TFile.Exists(TPath.Combine(Work, 'uncert_1.json')));

  Assert.AreEqual('', RemoveToolEntries(Path));              // the tool's Clear

  KeepToolEntries(Path, Work);                               // File - Save, before the folder is zipped
  Assert.IsFalse(TFile.Exists(TPath.Combine(Work, 'uncert_1.json')), 'the result');
  Assert.IsFalse(TFile.Exists(TPath.Combine(Work, 'counts_2.dat')), 'the counts');
  Assert.IsTrue(TFile.Exists(TPath.Combine(Work, 'project.dsc')), 'the project''s own files stay');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertFiles);

end.
