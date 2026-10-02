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

unit TestUncertEndToEnd;

(* The uncertainty tool's headless path on project files with known truth
   (plan B1, task 6). For a periodic model, a profile and a 10-entry table:
   the truth gate's truth, noise and classic fit; the fitted model and the
   curve written as a project; then only what the tool itself does - read the
   project, build the request, run the full recipe, write the result into the
   project, read it back.

   Opt-in like the truth gate: set XRC_TRUTH_GATE=1. Every run appends its
   numbers to UncertEndToEnd.txt next to the test runner. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUncertEndToEnd = class
  private
    FDir: string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure Periodic_FromProjectFile;
    [Test] procedure Profile_FromProjectFile;
    [Test] procedure Table_FromProjectFile;
    [Test] procedure LargeTable_IsRefusedAndNothingIsWritten;
  end;

implementation

uses
  System.SysUtils, System.Math, System.IOUtils, System.Zip,
  unit_Types, unit_Likelihood, unit_ParamMap, unit_LogPosterior, unit_MCPStructure,
  unit_MCPProjectFile, unit_UncertCounts, unit_UncertRequest, unit_UncertRun, unit_UncertFiles,
  TestLogPosterior, TestTruthGate;

const
  SEED = 1;

procedure Report(const Line: string);
begin
  TFile.AppendAllText(TPath.Combine(ExtractFilePath(ParamStr(0)), 'UncertEndToEnd.txt'),
    Line + sLineBreak);
end;

function Enabled: Boolean;
begin
  Result := GetEnvironmentVariable('XRC_TRUTH_GATE') = '1';
end;

procedure TTestUncertEndToEnd.Setup;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'xrcuncert_e2e_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FDir);
end;

procedure TTestUncertEndToEnd.TearDown;
begin
  TDirectory.Delete(FDir, True);
end;

{ 200 angles a project file keeps exactly: it stores three decimals. }
function Angles: TDataArray;
var
  i: Integer;
begin
  SetLength(Result, 200);
  for i := 0 to High(Result) do
  begin
    Result[i].t := 0.3 + i * 0.014;
    Result[i].r := 1;
  end;
end;

function CurveAt(const S: TFitStructure; const Data: TDataArray): TDataArray;
var
  Map: TParamMap;
  Post: TLogPosterior;
begin
  Map := TParamMap.Create(S, True);
  try
    Map.AddNuisance(Log10(1.2), 0, 1E-7, 0.001, 1);
    Post := TLogPosterior.Create(Map, Data, nil, TWB4CFixture.CalcParams(Data, 0), 1E-9, 10);
    try
      Assert.IsTrue(Post.EvaluateOnce(Map.StartVector, Result).Feasible);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
end;

{ The fitted model and its curve as the main program would have saved them. }
function FittedProject(Mode: TMode; N: Integer; out Counts: TArray<Double>): TXRCXProject;
var
  Clean, Data: TDataArray;
  Fitted: TFitStructure;
  C: TArray<Double>;
  k: Integer;
begin
  Clean := CurveAt(TruthStructure(Mode, N), Angles);
  Noisy(Clean, 1000 + SEED, Data, Counts);
  ClassicFit(Mode, N, Data, TWB4CFixture.CalcParams(Data, 0), SEED, Fitted, C);

  Result := Default(TXRCXProject);
  Result.Params := DefaultCalcParams;
  Result.Params.Lambda := 1.5406;
  Result.Params.Width := 0;
  Result.Params.MinLimit := 1E-9;
  Result.Params.Polarisation := 1;          // s + p, as TWB4CFixture.CalcParams made the truth
  Result.Params.Points := Length(Data);
  Result.Params.ThetaStart := Data[0].t;
  Result.Params.ThetaEnd := Data[High(Data)].t;
  Result.ModelTitle := 'Fitted';
  Result.DataTitle := 'measured';
  Result.DataNote := '* written by TestUncertEndToEnd';
  Result.DataCurve := Data;
  Result.CalcCurve := Clean;
  case Mode of
    gmPeriodic:
      begin
        { the fit moved the period: the project says so, as the main program's
          Free period box would }
        Result.Params.FitMode := 1;
        Result.Params.LFPSO.FreePeriod := True;
        Result.Params.LFPSO.PeriodWindow := 0.1;
      end;
    gmProfile:
      begin
        Result.Params.FitMode := 2;
        SetLength(Result.Extensions, 1);
        Result.Extensions[0].StackID := 0;
        Result.Extensions[0].LayerID := FREE_L;
        Result.Extensions[0].Subj := ptH;
        SetLength(Result.Extensions[0].Coeffs, Length(C));
        for k := 0 to High(C) do
          Result.Extensions[0].Coeffs[k] := C[k];
      end;
    gmTable:
      begin
        Result.Params.FitMode := 0;
        Result.TableExtension := True;
      end;
  end;
  Result.XRCData := StructureToXRCData(Fitted, EmptyStructureInfo);
end;

function ValueOf(const Res: TUncertResult; const Name: string): TUncertValue;
var
  k: Integer;
begin
  for k := 0 to High(Res.Values) do
    if Res.Values[k].Name = Name then
      Exit(Res.Values[k]);
  Assert.Fail('no value ' + Name);
end;

procedure AssertInside(const Res: TUncertResult; const Name: string; Truth: Double;
  var Log: string);
var
  V: TUncertValue;
begin
  V := ValueOf(Res, Name);
  Log := Log + Format('  %s truth %.6g  p2.5 %.6g  p16 %.6g  p50 %.6g  p84 %.6g  p97.5 %.6g  R-hat %.3f' +
    sLineBreak, [Name, Truth, V.P2_5, V.P16, V.P50, V.P84, V.P97_5, V.RHat]);
  Assert.IsTrue((V.P2_5 <= Truth) and (Truth <= V.P97_5),
    Format('%s: the truth %g is outside %g .. %g', [Name, Truth, V.P2_5, V.P97_5]));
end;

{ The tool's own path, start to finish, on the file at Path. }
function RunTool(const Path: string; const Counts: TArray<Double>; out Req: TUncertRequest;
  out Proj: TXRCXProject): TUncertResult;
var
  Why, Text: string;
  Stored, Back: TStoredUncert;
  Again: TXRCXProject;
  k: Integer;
begin
  Proj := ReadXRCX(Path);
  Why := BuildRequest(Proj, Req);
  Assert.AreEqual('', Why, 'the project is one the tool takes');
  Result := RunUncertainty(Req, nil, Counts, False, SEED, nil, nil);
  Assert.IsTrue(Result.Settled, Result.Message);

  Stored := Default(TStoredUncert);
  Stored.Fingerprint := Fingerprint(Proj, Counts, nil);
  Stored.HasResult := True;
  Stored.Result := Result;
  Stored.Names := Req.Names;
  Assert.AreEqual('', WriteEntries(Path,
    [UncertEntryName(Proj.ModelID), CountsEntryName(Proj.DataID)],
    [StoredToJSON(Stored), CountsToText(Counts)]));

  { and back, as the tool would find it tomorrow }
  Again := ReadXRCX(Path);
  Assert.AreEqual(Proj.XRCData, Again.XRCData, 'the model is untouched');
  Assert.IsTrue(ReadEntry(Path, UncertEntryName(Again.ModelID), Text));
  Assert.IsTrue(StoredFromJSON(Text, Back));
  Assert.AreEqual(Length(Result.Values), Length(Back.Result.Values));
  for k := 0 to High(Result.Values) do
    Assert.AreEqual(Result.Values[k].P50, Back.Result.Values[k].P50, 0.0,
      Result.Values[k].Name + ' is stored as it was computed');
  Assert.IsTrue(ReadEntry(Path, CountsEntryName(Again.DataID), Text));
  Assert.AreEqual(Back.Fingerprint, Fingerprint(Again, CountsFromText(Text), nil),
    'the stored result is current for the project as it now is');
  Again.XRCData := StringReplace(Again.XRCData, '"B4C"', '"C"', []);
  Assert.AreNotEqual(Back.Fingerprint, Fingerprint(Again, CountsFromText(Text), nil),
    'and out of date once the model changes');
end;

function PeriodMean(Mode: TMode; N: Integer): Double;
var
  k: Integer;
begin
  Result := 0;
  for k := 1 to N do
    Result := Result + 28 + TruthH(Mode, k);
  Result := Result / N;
end;

procedure TTestUncertEndToEnd.Periodic_FromProjectFile;
var
  Path, Log: string;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Proj: TXRCXProject;
  Res: TUncertResult;
begin
  if not Enabled then
    Assert.Pass('set XRC_TRUTH_GATE=1 to run the end-to-end cases');
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Path := TPath.Combine(FDir, 'periodic.xrcx');
  WriteXRCX(Path, FittedProject(gmPeriodic, 20, Counts));
  Res := RunTool(Path, Counts, Req, Proj);
  Log := Format('periodic: %d walkers, %d steps, %s, %.0f s, repeated %s' + sLineBreak,
    [Res.Walkers, Res.StepsRun, Res.Device, Res.Seconds, BoolToStr(Res.Repeated, True)]);
  try
    AssertInside(Res, 's0.period', 34, Log);
    AssertInside(Res, 's0.l2.thickness', 6, Log);
    AssertInside(Res, 's0.period_mean', 34, Log);
  finally
    Report(Log);
  end;
end;

procedure TTestUncertEndToEnd.Profile_FromProjectFile;
var
  Path, Log: string;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Proj: TXRCXProject;
  Res: TUncertResult;
begin
  if not Enabled then
    Assert.Pass('set XRC_TRUTH_GATE=1 to run the end-to-end cases');
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Path := TPath.Combine(FDir, 'profile.xrcx');
  WriteXRCX(Path, FittedProject(gmProfile, 20, Counts));
  Res := RunTool(Path, Counts, Req, Proj);
  Log := Format('profile: %d walkers, %d steps, %s, %.0f s, repeated %s' + sLineBreak,
    [Res.Walkers, Res.StepsRun, Res.Device, Res.Seconds, BoolToStr(Res.Repeated, True)]);
  try
    AssertInside(Res, 's0.l2.thickness.c1', 0.05, Log);
    AssertInside(Res, 's0.l2.thickness[20]', TruthH(gmProfile, 20), Log);
    AssertInside(Res, 's0.period_mean', PeriodMean(gmProfile, 20), Log);
    AssertInside(Res, 's0.drift', TruthH(gmProfile, 20) - TruthH(gmProfile, 1), Log);
  finally
    Report(Log);
  end;
end;

procedure TTestUncertEndToEnd.Table_FromProjectFile;
var
  Path, Log: string;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Proj: TXRCXProject;
  Res: TUncertResult;
begin
  if not Enabled then
    Assert.Pass('set XRC_TRUTH_GATE=1 to run the end-to-end cases');
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Path := TPath.Combine(FDir, 'table.xrcx');
  WriteXRCX(Path, FittedProject(gmTable, 10, Counts));
  Res := RunTool(Path, Counts, Req, Proj);
  Assert.AreEqual(10, Req.TableSlots);
  Log := Format('table (10 entries): %d walkers, %d steps, %s, %.0f s, repeated %s' + sLineBreak,
    [Res.Walkers, Res.StepsRun, Res.Device, Res.Seconds, BoolToStr(Res.Repeated, True)]);
  try
    AssertInside(Res, 's0.period_mean', PeriodMean(gmTable, 10), Log);
    AssertInside(Res, 's0.total', 10 * PeriodMean(gmTable, 10), Log);
  finally
    Report(Log);
  end;
end;

procedure TTestUncertEndToEnd.LargeTable_IsRefusedAndNothingIsWritten;
var
  Path, Why: string;
  S: TFitStructure;
  P, R: TXRCXProject;
  Req: TUncertRequest;
  Z: TZipFile;
  Before: Integer;
begin
  { no fit needed: the refusal comes before anything is run, so this case is
    not behind the gate switch }
  S := Cell(40, 6);
  P := Default(TXRCXProject);
  P.Params := DefaultCalcParams;
  P.Params.FitMode := 0;
  P.TableExtension := True;
  P.ModelTitle := 'Large table';
  P.DataTitle := 'measured';
  P.DataCurve := Angles;
  P.XRCData := StructureToXRCData(S, EmptyStructureInfo);
  Path := TPath.Combine(FDir, 'large.xrcx');
  WriteXRCX(Path, P);

  Z := TZipFile.Create;
  try
    Z.Open(Path, zmRead);
    Before := Z.FileCount;
    Z.Close;
    R := ReadXRCX(Path);
    Why := BuildRequest(R, Req);
    Assert.Contains(Why, '40');
    Assert.Contains(Why, 'at most 20');
    Z.Open(Path, zmRead);
    Assert.AreEqual(Before, Z.FileCount, 'a refused project is not written to');
  finally
    Z.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertEndToEnd);

end.
