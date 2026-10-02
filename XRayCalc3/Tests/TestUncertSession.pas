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

unit TestUncertSession;

(* One project open in the uncertainty tool: what it finds in the file, what
   it refuses and how, and what it writes back. Nothing is sampled here. *)

interface

uses
  DUnitX.TestFramework, unit_Types, unit_MCPProjectFile;

type
  [TestFixture]
  TTestUncertSession = class
  private
    FDir: string;
    function NewProject(const Name: string; const P: TXRCXProject): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Open_FittedProject_HasARequestAndNoResult;
    [Test] procedure Open_NothingFree_IsARefusalNotAnError;
    [Test] procedure Open_StartOutsideLimits_IsARefusal;
    [Test] procedure Open_NotAProject_PlainSentence;
    [Test] procedure Open_NewerProject_Refused;
    [Test] procedure StorePriors_RoundTrip;
    [Test] procedure StorePriors_OnATableEntry_Refused;
    [Test] procedure StoreResult_RoundTrip;
    [Test] procedure StoreResult_ThenPriorChanged_IsOutOfDate;
    [Test] procedure StoreResult_ThenModelChanged_IsOutOfDate;
    [Test] procedure StoredResult_OfAnotherModelShape_IsDropped;
    [Test] procedure StoreResult_ReadOnlyFile_SaysSoAndKeepsTheFile;
    [Test] procedure StoredCounts_AreUsedWithoutTheSourceFile;
    [Test] procedure Open_EntryOfAnotherVersion_IsSaidNotIgnored;
    [Test] procedure StorePriors_ReadOnlyFile_SpeaksOfTheKnownValue;
    [Test] procedure SessionWarnings_Order;
    [Test] procedure SessionWarnings_MisfitComesFirst;
    [Test] procedure ClearStored_LeavesAProjectAsIfNeverAnalysed;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils, System.Math,
  unit_consts, unit_UncertRequest, unit_UncertRun, unit_UncertFiles, unit_UncertSession,
  TestUncertRequest;

procedure TTestUncertSession.Setup;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'xrcsession_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FDir);
end;

procedure TTestUncertSession.TearDown;
var
  F: string;
begin
  for F in TDirectory.GetFiles(FDir) do
    TFile.SetAttributes(F, []);
  TDirectory.Delete(FDir, True);
end;

function TTestUncertSession.NewProject(const Name: string; const P: TXRCXProject): string;
begin
  Result := TPath.Combine(FDir, Name);
  WriteXRCX(Result, P);
end;

function Opened(const Path: string): TUncertSession;
begin
  Assert.AreEqual('', OpenSession(Path, Result));
end;

{ A settled result with one value per name of S's request. }
function ResultFor(const S: TUncertSession): TUncertResult;
var
  k: Integer;
begin
  Result := Default(TUncertResult);
  Result.Settled := True;
  Result.Device := 'CPU';
  Result.Walkers := 32;
  Result.StepsRun := 4000;
  SetLength(Result.Values, Length(S.Request.Names));
  for k := 0 to High(Result.Values) do
  begin
    Result.Values[k].Name := S.Request.Names[k].Name;
    Result.Values[k].Best := 10 + k;
    Result.Values[k].P2_5 := 9 + k;
    Result.Values[k].P16 := 9.5 + k;
    Result.Values[k].P50 := 10 + k;
    Result.Values[k].P84 := 10.5 + k;
    Result.Values[k].P97_5 := 11 + k;
    Result.Values[k].Minus := 0.5;
    Result.Values[k].Plus := 0.5;
    Result.Values[k].RHat := 1.01;
    if Result.Values[k].Name = 'c0.f' then
      Result.Values[k].P50 := 0.01;        // a model that follows its curve
  end;
end;

function TotalPrior(Mean: Double): TUncertPrior;
begin
  Result := Default(TUncertPrior);
  Result.Name := 's0.total';
  Result.Mean := Mean;
  Result.SD := 5;
  Result.Note := 'profilometer';
end;

procedure TTestUncertSession.Open_FittedProject_HasARequestAndNoResult;
var
  S: TUncertSession;
begin
  S := Opened(NewProject('a.xrcx', ProjectOf(WSi(10), 1)));
  Assert.AreEqual('', S.Refusal);
  Assert.IsTrue(Length(S.Request.Names) > 0);
  Assert.IsFalse(S.HasResult);
  Assert.IsFalse(S.OutOfDate);
  Assert.AreEqual(0, Integer(Length(S.Counts)));
  Assert.Contains(S.CountsNote, 'No raw counts');
  Assert.AreEqual('Model 1', S.Project.ModelTitle);
end;

procedure TTestUncertSession.Open_NothingFree_IsARefusalNotAnError;
var
  St: TFitStructure;
  S: TUncertSession;
begin
  St := WSi(10);
  St.Stacks[0].Layers[0].P[1].Fixed := True;
  St.Stacks[0].Layers[1].P[1].Fixed := True;
  Assert.AreEqual('', OpenSession(NewProject('a.xrcx', ProjectOf(St, 1)), S));
  Assert.Contains(S.Refusal, 'free to vary');
  Assert.AreEqual(1, Integer(Length(SessionWarnings(S))), 'the refusal and nothing else');
end;

procedure TTestUncertSession.Open_StartOutsideLimits_IsARefusal;
var
  St: TFitStructure;
  S: TUncertSession;
begin
  St := WSi(10);
  St.Stacks[0].Layers[0].P[1].V := 26;               // past its limit of 25
  Assert.AreEqual('', OpenSession(NewProject('a.xrcx', ProjectOf(St, 1)), S));
  Assert.Contains(S.Refusal, 'limits');
end;

procedure TTestUncertSession.Open_NotAProject_PlainSentence;
var
  S: TUncertSession;
  Path: string;
begin
  Path := TPath.Combine(FDir, 'x.xrcx');
  TFile.WriteAllText(Path, 'theta intensity' + sLineBreak + '0.1 1');
  Assert.AreNotEqual('', OpenSession(Path, S), 'a text file');
  Assert.Contains(OpenSession(TPath.Combine(FDir, 'none.xrcx'), S), 'not found');
  Assert.AreNotEqual('', OpenSession(FDir, S), 'a folder');
  Assert.AreNotEqual('', OpenSession('', S), 'no name at all');
end;

procedure TTestUncertSession.Open_NewerProject_Refused;
var
  S: TUncertSession;
  Path, Text: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  Assert.IsTrue(ReadEntry(Path, PARAMETERS_FILE_NAME, Text));
  Text := Text.Replace(Format('Version=%d', [CURRENT_PROJECT_VERSION]),
    Format('Version=%d', [CURRENT_PROJECT_VERSION + 1]));
  Assert.AreEqual('', WriteEntries(Path, [PARAMETERS_FILE_NAME], [Text]));
  Assert.Contains(OpenSession(Path, S), 'newer');
end;

procedure TTestUncertSession.StorePriors_RoundTrip;
var
  S: TUncertSession;
  Path: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Assert.AreEqual('', StorePriors(S, [TotalPrior(500)]));
  Assert.AreEqual(1, Integer(Length(S.Priors)));
  S := Opened(Path);
  Assert.AreEqual(1, Integer(Length(S.Priors)));
  Assert.AreEqual('s0.total', S.Priors[0].Name);
  Assert.AreEqual(500.0, S.Priors[0].Mean, 0.0);
  Assert.AreEqual('profilometer', S.Priors[0].Note);
  Assert.IsFalse(S.HasResult);
  Assert.IsFalse(S.OutOfDate, 'nothing to be out of date');

  Assert.AreEqual('', StorePriors(S, nil));
  S := Opened(Path);
  Assert.AreEqual(0, Integer(Length(S.Priors)), 'and taken away again');
end;

procedure TTestUncertSession.StorePriors_OnATableEntry_Refused;
var
  S: TUncertSession;
  Pr: TUncertPrior;
begin
  S := Opened(NewProject('a.xrcx', ProjectOf(WSi(4), 0)));
  Pr := TotalPrior(200);
  Pr.Name := 's0.l0.thickness[2]';
  Assert.AreNotEqual('', StorePriors(S, [Pr]));
  Assert.AreEqual(0, Integer(Length(S.Priors)), 'the session keeps what it had');
end;

procedure TTestUncertSession.StoreResult_RoundTrip;
var
  S, T: TUncertSession;
  Path: string;
  k: Integer;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Assert.AreEqual('', StoreResult(S, ResultFor(S)));
  Assert.IsTrue(S.HasResult);
  Assert.IsFalse(S.OutOfDate);
  T := Opened(Path);
  Assert.IsTrue(T.HasResult);
  Assert.IsFalse(T.OutOfDate);
  Assert.AreEqual(Length(S.Result.Values), Length(T.Result.Values));
  for k := 0 to High(T.Result.Values) do
    Assert.AreEqual(S.Result.Values[k].P50, T.Result.Values[k].P50, 0.0);
  Assert.AreEqual(ReadXRCX(Path).XRCData, S.Project.XRCData, 'the model is untouched');
end;

procedure TTestUncertSession.StoreResult_ThenPriorChanged_IsOutOfDate;
var
  S: TUncertSession;
  Path: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Assert.AreEqual('', StoreResult(S, ResultFor(S)));
  Assert.AreEqual('', StorePriors(S, [TotalPrior(500)]));
  Assert.IsTrue(S.HasResult, 'the result is kept');
  Assert.IsTrue(S.OutOfDate);
  S := Opened(Path);
  Assert.IsTrue(S.HasResult);
  Assert.IsTrue(S.OutOfDate, 'and is out of date tomorrow too');
  Assert.AreEqual(MSG_OUT_OF_DATE, SessionWarnings(S)[0]);

  Assert.AreEqual('', StorePriors(S, nil));
  Assert.IsFalse(S.OutOfDate, 'taking the known value away again makes the result current');
end;

procedure TTestUncertSession.StoreResult_ThenModelChanged_IsOutOfDate;
var
  S: TUncertSession;
  St: TFitStructure;
  Path, Entry: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Assert.AreEqual('', StoreResult(S, ResultFor(S)));
  Assert.IsTrue(ReadEntry(Path, UncertEntryName(S.Project.ModelID), Entry));

  St := WSi(10);
  St.Stacks[0].Layers[0].P[1].V := 21;               // the main program refitted and saved
  WriteXRCX(Path, ProjectOf(St, 1));
  Assert.AreEqual('', WriteEntries(Path, [UncertEntryName(S.Project.ModelID)], [Entry]));
  S := Opened(Path);
  Assert.IsTrue(S.HasResult);
  Assert.IsTrue(S.OutOfDate);
end;

procedure TTestUncertSession.StoredResult_OfAnotherModelShape_IsDropped;
var
  S: TUncertSession;
  St: TFitStructure;
  Path, Entry: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Assert.AreEqual('', StorePriors(S, [TotalPrior(500)]));
  Assert.AreEqual('', StoreResult(S, ResultFor(S)));
  Assert.IsTrue(ReadEntry(Path, UncertEntryName(S.Project.ModelID), Entry));

  St := WSi(10);
  St.Stacks[0].Layers[0].P[2].min := 1;              // a roughness freed: one more name
  St.Stacks[0].Layers[0].P[2].max := 6;
  WriteXRCX(Path, ProjectOf(St, 1));
  Assert.AreEqual('', WriteEntries(Path, [UncertEntryName(S.Project.ModelID)], [Entry]));
  S := Opened(Path);
  Assert.IsFalse(S.HasResult, 'a result for another set of values is not shown');
  Assert.IsFalse(S.OutOfDate);
  Assert.AreEqual(1, Integer(Length(S.Priors)), 'the known value still applies');
  Assert.AreEqual('', S.Refusal);
end;

procedure TTestUncertSession.StoreResult_ReadOnlyFile_SaysSoAndKeepsTheFile;
var
  S: TUncertSession;
  Path: string;
  Before: TBytes;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Before := TFile.ReadAllBytes(Path);
  TFile.SetAttributes(Path, [TFileAttribute.faReadOnly]);
  Assert.AreNotEqual('', StoreResult(S, ResultFor(S)));
  Assert.IsTrue(S.HasResult, 'the window still has the result to show');
  Assert.AreEqual(Length(Before), Integer(Length(TFile.ReadAllBytes(Path))));
  Assert.IsTrue(CompareMem(@Before[0], @TFile.ReadAllBytes(Path)[0], Length(Before)));
  Assert.AreNotEqual('', StorePriors(S, [TotalPrior(500)]));
  Assert.AreEqual(0, Integer(Length(S.Priors)), 'a known value that could not be stored is not taken');
end;

procedure TTestUncertSession.StoredCounts_AreUsedWithoutTheSourceFile;
var
  S: TUncertSession;
  Path: string;
  k: Integer;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  SetLength(S.Counts, Length(S.Project.DataCurve));
  for k := 0 to High(S.Counts) do
    S.Counts[k] := 1000 + k;
  Assert.AreEqual('', StoreResult(S, ResultFor(S)));
  S := Opened(Path);
  Assert.AreEqual(Length(S.Project.DataCurve), Integer(Length(S.Counts)));
  Assert.AreEqual(1007.0, S.Counts[7], 0.0);
  Assert.AreEqual('', S.CountsNote);
  Assert.IsFalse(S.OutOfDate, 'the counts it was made with are the counts it finds');
end;

{ An entry this build cannot read (another version of the tool wrote it) is
  not passed over in silence: the next store replaces it. }
procedure TTestUncertSession.Open_EntryOfAnotherVersion_IsSaidNotIgnored;
var
  S: TUncertSession;
  Path: string;
  W: TArray<string>;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  Assert.AreEqual('', WriteEntries(Path, [UncertEntryName(XRCX_MODEL_ID)], ['{"format":99,"priors":[]}']));
  S := Opened(Path);
  Assert.IsFalse(S.HasResult);
  Assert.AreEqual('', S.Refusal, 'the project can still be analysed');
  W := SessionWarnings(S);
  Assert.IsTrue(Length(W) >= 1);
  Assert.Contains(W[0], 'another version');

  S := Opened(NewProject('b.xrcx', ProjectOf(WSi(10), 1)));
  Assert.AreEqual('', S.EntryNote, 'no entry, nothing to say');
end;

procedure TTestUncertSession.StorePriors_ReadOnlyFile_SpeaksOfTheKnownValue;
var
  S: TUncertSession;
  Path, Why: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  TFile.SetAttributes(Path, [TFileAttribute.faReadOnly]);
  Why := StorePriors(S, [TotalPrior(500)]);
  Assert.Contains(Why, 'read-only');
  Assert.IsFalse(Why.Contains('result'), 'no result was being stored: ' + Why);
end;

procedure TTestUncertSession.SessionWarnings_Order;
var
  S: TUncertSession;
  Res: TUncertResult;
  W: TArray<string>;
begin
  S := Opened(NewProject('a.xrcx', ProjectOf(WSi(10), 1)));
  Res := ResultFor(S);
  Res.Warnings := [WARN_NO_COUNTS,
    'W  H sits at its limit: its error is cut off there.'];
  Assert.AreEqual('', StoreResult(S, Res));
  Assert.AreEqual('', StorePriors(S, [TotalPrior(500)]));
  W := SessionWarnings(S);
  Assert.AreEqual(3, Integer(Length(W)), 'out of date, no counts (once), at its limit');
  Assert.AreEqual(MSG_OUT_OF_DATE, W[0]);
  Assert.Contains(W[1], 'No raw counts');
  Assert.Contains(W[2], 'limit');
end;

{ Said from the stored values, so a result of any age gets it, and first: it
  is the line that explains the rest. }
procedure TTestUncertSession.SessionWarnings_MisfitComesFirst;
var
  S: TUncertSession;
  Res: TUncertResult;
  W: TArray<string>;
  k: Integer;
  Found: Boolean;
begin
  S := Opened(NewProject('a.xrcx', ProjectOf(WSi(10), 1)));
  Res := ResultFor(S);
  Res.Warnings := ['W  H sits at its limit: its error is cut off there.'];
  Found := False;
  for k := 0 to High(Res.Values) do
    if Res.Values[k].Name = 'c0.f' then
    begin
      Res.Values[k].P50 := 0.2;
      Found := True;
    end;
  Assert.IsTrue(Found, 'the result carries the noise floor');
  Assert.AreEqual('', StoreResult(S, Res));
  W := SessionWarnings(S);
  Assert.Contains(W[0], 'misses the measured curve by about 20 %');
  Assert.Contains(W[High(W)], 'limit');
end;

procedure TTestUncertSession.ClearStored_LeavesAProjectAsIfNeverAnalysed;
var
  S, Again: TUncertSession;
  Path, Text: string;
begin
  Path := NewProject('a.xrcx', ProjectOf(WSi(10), 1));
  S := Opened(Path);
  Assert.AreEqual('', StoreResult(S, ResultFor(S)));
  Assert.AreEqual('', StorePriors(S, [TotalPrior(500)]));
  Assert.IsTrue(S.HasResult);

  Assert.AreEqual('', ClearStored(S));

  Assert.IsFalse(S.HasResult, 'no result in the session');
  Assert.AreEqual(0, Integer(Length(S.Priors)), 'no known values');
  Assert.AreEqual(Path, S.FileName, 'the same project stays open');
  Assert.IsFalse(ReadEntry(Path, UncertEntryName(S.Project.ModelID), Text), 'and nothing in the file');
  Again := Opened(Path);
  Assert.IsFalse(Again.HasResult);
  Assert.AreEqual('', Again.EntryNote);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertSession);

end.
