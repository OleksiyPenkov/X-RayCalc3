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

unit TestUncertRun;

(* The uncertainty run on the W/B4C cell of TestLogPosterior, held as a
   project: settle, restart, sample; the refusals; stop and progress. The
   recipes are short - the full one is the truth gate's business. *)

interface

uses
  DUnitX.TestFramework, unit_Types, unit_MCPProjectFile, unit_UncertRequest;

type
  [TestFixture]
  TTestUncertRun = class
  public
    [Test] procedure Settles_TruthInsideTheRange;
    [Test] procedure WithoutCounts_Warns;
    [Test] procedure Stop_ReturnsStopped;
    [Test] procedure Progress_IsReported;
    [Test] procedure WalkersDisagree_RepeatsThenRefusesInPlainWords;
    [Test] procedure StartOutsideLimits_RefusedBeforeRunning;
    [Test] procedure NarrowPrior_PullsTheResult_AndIsReported;
  end;

/// TWB4CFixture's cell with interlayer thickness H2 as a periodic project whose
/// curve is the model's own at 6 A, as counts at I0 = 1E6.
function WB4CProject(H2: Single; out Counts: TArray<Double>): TXRCXProject;

implementation

uses
  System.SysUtils, System.Math, unit_MCPStructure, unit_ParamMap, unit_LogPosterior,
  unit_UncertRun, TestLogPosterior;

const
  I0 = 1E6;
  THICKNESS = 's0.l2.thickness';

function WB4CProject(H2: Single; out Counts: TArray<Double>): TXRCXProject;
var
  Req: TUncertRequest;
  Map: TParamMap;
  Post: TLogPosterior;
  R: TDataArray;
  i: Integer;
begin
  Result := Default(TXRCXProject);
  Result.Params := DefaultCalcParams;
  Result.Params.FitMode := 1;
  Result.Params.Lambda := 1.5406;
  Result.Params.Width := 0;
  Result.Params.MinLimit := 1E-9;
  Result.ModelID := 1;
  Result.DataID := 2;
  Result.DataTitle := 'curve';
  Result.DataCurve := TWB4CFixture.Angles;

  { the truth's curve, through the request the tool itself would build }
  Result.XRCData := StructureToXRCData(TWB4CFixture.Structure(6), EmptyStructureInfo);
  Assert.AreEqual('', BuildRequest(Result, Req));
  Map := BuildMap(Req, nil);
  try
    Post := TLogPosterior.Create(Map, Req.Data, nil, Req.CalcParams, Req.RMin, COUNTS_MIN);
    try
      Assert.IsTrue(Post.EvaluateOnce(Map.StartVector, R).Feasible);
    finally
      Post.Free;
    end;
  finally
    Map.Free;
  end;
  SetLength(Counts, Length(R));
  for i := 0 to High(R) do
  begin
    Counts[i] := Round(R[i].r * I0);
    Result.DataCurve[i].r := Max(Counts[i], 1) / I0;
  end;

  Result.XRCData := StructureToXRCData(TWB4CFixture.Structure(H2), EmptyStructureInfo);
end;

function ShortRecipe: TUncertRecipe;
begin
  Result := TUncertRecipe.Standard;
  Result.Settle := 100;
  Result.Steps := 300;
  Result.BurnIn := 100;
  Result.Thin := 2;
  Result.Predictive := 20;
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

function HasWarning(const Res: TUncertResult; const Part: string): Boolean;
var
  W: string;
begin
  Result := False;
  for W in Res.Warnings do
    if W.Contains(Part) then
      Exit(True);
end;

procedure TTestUncertRun.Settles_TruthInsideTheRange;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
  V: TUncertValue;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(6, Counts);
  Assert.AreEqual('', BuildRequest(P, Req));
  Res := RunUncertainty(Req, nil, Counts, False, 7, nil, nil, ShortRecipe);
  Assert.IsTrue(Res.Settled, Res.Message);
  Assert.AreEqual('', Res.Message);
  Assert.IsFalse(Res.Stopped);
  Assert.AreEqual(Length(Req.Names), Length(Res.Values), 'one value per reported name');
  V := ValueOf(Res, THICKNESS);
  Assert.IsTrue((V.P2_5 <= 6) and (6 <= V.P97_5), Format('6 A inside %g .. %g', [V.P2_5, V.P97_5]));
  Assert.IsTrue((V.Minus > 0) and (V.Plus > 0), 'a range on both sides');
  Assert.AreEqual(6.0, V.Best, 1E-5, 'the fitted value');
  Assert.AreEqual(Length(Req.Data), Length(Res.Band.Theta));
  Assert.AreEqual('CPU', Res.Device);
  Assert.IsFalse(HasWarning(Res, 'No raw counts'));
  Assert.AreEqual(Length(Res.Values), Length(Res.Correlation));
end;

procedure TTestUncertRun.WithoutCounts_Warns;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(6, Counts);
  Assert.AreEqual('', BuildRequest(P, Req));
  Res := RunUncertainty(Req, nil, nil, False, 7, nil, nil, ShortRecipe);
  Assert.IsTrue(Res.Settled, Res.Message);
  Assert.IsTrue(HasWarning(Res, 'No raw counts'));
end;

procedure TTestUncertRun.Stop_ReturnsStopped;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
  Asked: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(6, Counts);
  Assert.AreEqual('', BuildRequest(P, Req));
  Asked := 0;
  Res := RunUncertainty(Req, nil, Counts, False, 7, nil,
    function: Boolean
    begin
      Inc(Asked);
      Result := Asked > 20;
    end, ShortRecipe);
  Assert.IsTrue(Res.Stopped);
  Assert.IsFalse(Res.Settled);
  Assert.IsTrue(Asked < 60, Format('stopped soon after it was asked, %d checks', [Asked]));
end;

procedure TTestUncertRun.Progress_IsReported;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
  Reports, LastStep, LastTotal: Integer;
  Rising: Boolean;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(6, Counts);
  Assert.AreEqual('', BuildRequest(P, Req));
  Reports := 0;
  LastStep := 0;
  LastTotal := 0;
  Rising := True;
  Res := RunUncertainty(Req, nil, Counts, False, 7,
    procedure(Step, Total: Integer; SecondsLeft: Double)
    begin
      Inc(Reports);
      if Step < LastStep then
        Rising := False;
      LastStep := Step;
      LastTotal := Total;
    end, nil, ShortRecipe);
  Assert.IsTrue(Res.Settled, Res.Message);
  Assert.IsTrue(Reports >= 4, Format('%d reports', [Reports]));
  Assert.IsTrue(Rising, 'the step count only rises');
  Assert.AreEqual(400, LastTotal, 'settling and sampling as one count');
  Assert.AreEqual(400, LastStep, 'the last report is the end');
end;

procedure TTestUncertRun.WalkersDisagree_RepeatsThenRefusesInPlainWords;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
  Recipe: TUncertRecipe;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(6, Counts);
  Assert.AreEqual('', BuildRequest(P, Req));
  Recipe := ShortRecipe;
  Recipe.Steps := 120;
  Recipe.AgreeBelow := 0.5;               // no chain can pass this: R-hat is about 1 at best
  Recipe.LongerFactor := 2;
  Res := RunUncertainty(Req, nil, Counts, False, 7, nil, nil, Recipe);
  Assert.IsFalse(Res.Settled);
  Assert.IsTrue(Res.Repeated, 'it tried once more, longer');
  Assert.Contains(Res.Message, 'has not settled');
  Assert.IsFalse(Res.Stopped);
end;

procedure TTestUncertRun.StartOutsideLimits_RefusedBeforeRunning;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
  Reports: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(9.5, Counts);            // the interlayer's limits are 3 .. 9
  Assert.AreEqual('', BuildRequest(P, Req));
  Reports := 0;
  Res := RunUncertainty(Req, nil, Counts, False, 7,
    procedure(Step, Total: Integer; SecondsLeft: Double)
    begin
      Inc(Reports);
    end, nil, ShortRecipe);
  Assert.IsFalse(Res.Settled);
  Assert.Contains(Res.Message, 'outside its limits');
  Assert.AreEqual(0, Reports, 'nothing was run');
end;

procedure TTestUncertRun.NarrowPrior_PullsTheResult_AndIsReported;
var
  P: TXRCXProject;
  Counts: TArray<Double>;
  Req: TUncertRequest;
  Res: TUncertResult;
  Pr: TUncertPrior;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  P := WB4CProject(6, Counts);
  Assert.AreEqual('', BuildRequest(P, Req));
  Pr := Default(TUncertPrior);
  Pr.Name := THICKNESS;
  Pr.Mean := 6.0005;
  Pr.SD := 5E-5;                            // several times narrower than the curve can tell
  Res := RunUncertainty(Req, [Pr], Counts, False, 7, nil, nil, ShortRecipe);
  Assert.IsTrue(Res.Settled, Res.Message);
  Assert.AreEqual(6.0005, ValueOf(Res, THICKNESS).P50, 2E-4, 'the entered value wins');
  Assert.IsTrue(ValueOf(Res, THICKNESS).P50 > 6.0002, 'and not the curve''s 6.0000');
  Assert.IsTrue(HasWarning(Res, 'repeats what was entered'));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertRun);

end.
