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

unit TestUncertRequest;

(* A fitted project as the uncertainty tool's parameter map, in each of the
   three fit modes, and the plain refusals. Nothing is calculated here. *)

interface

uses
  DUnitX.TestFramework, unit_Types, unit_MCPProjectFile;

type
  [TestFixture]
  TTestUncertRequest = class
  public
    [Test] procedure Periodic_FreeThicknesses_OneSlotOneDerived;
    [Test] procedure Periodic_FreePeriod_AddsThePeriodSlot;
    [Test] procedure Periodic_HeldPeriod_IsSampledInASmallWindow;
    [Test] procedure Periodic_VeryWidePeriodWindow_IsCut;
    [Test] procedure Periodic_FixedOrNoRange_NotSampled;
    [Test] procedure Periodic_StaleTable_IsDropped;
    [Test] procedure Profile_UsesTheGradientExtension;
    [Test] procedure Profile_NoExtension_ZeroGradient;
    [Test] procedure Table_OneSlotPerPeriod_KeepsTheFittedTable;
    [Test] procedure Table_NoTableExtension_StartsFromTheValue;
    [Test] procedure Table_TooLarge_Refused;
    [Test] procedure NoCurve_Refused;
    [Test] procedure NothingFree_Refused;
    [Test] procedure WavelengthScan_Refused;
    [Test] procedure Prior_OnATableEntry_Raises;
    [Test] procedure Prior_OnASummary_IsSet;
    [Test] procedure StartProblem_NamesTheValue;
    [Test] procedure Names_CaptionsGroupsAndKinds;
    [Test] procedure CalcParams_FollowTheProject;
    [Test] procedure UnlinkedCurve_Refused;
    [Test] procedure Profile_FrozenGradedValue_KeepsItsGradient;
    [Test] procedure Table_EntryOutsideItsLimits_IsNamed;
  end;

/// W / Si, N periods: W 20 A [15, 25], Si 30 A [25, 35]; sigma and density held.
function WSi(N: Integer): TFitStructure;
/// A project holding S, fitted in Mode (0 table, 1 periodic, 2 profile), with a
/// 50-point theta curve.
function ProjectOf(const S: TFitStructure; Mode: Integer): TXRCXProject;

implementation

uses
  System.SysUtils, System.Math, unit_MCPStructure, unit_ParamMap, unit_Likelihood,
  unit_UncertRequest;

function Lay(const M: string; H, HMin, HMax: Single): TLayerData;
begin
  Result := Default(TLayerData);
  Result.Material := M;
  Result.P[1].V := H; Result.P[1].min := HMin; Result.P[1].max := HMax;
  Result.P[2].V := 3; Result.P[2].min := 3; Result.P[2].max := 3;
  Result.P[3].V := 5; Result.P[3].min := 5; Result.P[3].max := 5;
end;

function WSi(N: Integer): TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].N := N;
  Result.Stacks[0].Header := 'ML';
  SetLength(Result.Stacks[0].Layers, 2);
  Result.Stacks[0].Layers[0] := Lay('W', 20, 15, 25);
  Result.Stacks[0].Layers[1] := Lay('Si', 30, 25, 35);
  Result.Subs := Lay('Si', 0, 0, 0);
end;

function ProjectOf(const S: TFitStructure; Mode: Integer): TXRCXProject;
var
  i: Integer;
begin
  Result := Default(TXRCXProject);
  Result.Params := DefaultCalcParams;
  Result.Params.FitMode := Mode;
  Result.Params.Lambda := 1.5406;
  Result.Params.Width := 0.01;
  Result.XRCData := StructureToXRCData(S, EmptyStructureInfo);
  Result.ModelTitle := 'Model 1';
  Result.ModelID := 1;
  Result.DataTitle := 'curve';
  Result.DataID := 2;
  Result.DataLinked := True;
  SetLength(Result.DataCurve, 50);
  for i := 0 to 49 do
  begin
    Result.DataCurve[i].t := 0.3 + i * 0.05;
    Result.DataCurve[i].r := 1E-3 + 1E-5 * i;
  end;
end;

function MapOf(const P: TXRCXProject; out Req: TUncertRequest): TParamMap;
var
  Why: string;
begin
  Why := BuildRequest(P, Req);
  Assert.AreEqual('', Why);
  Result := BuildMap(Req, nil);
end;

procedure TTestUncertRequest.Periodic_FreeThicknesses_OneSlotOneDerived;
var
  Req: TUncertRequest;
  M: TParamMap;
begin
  M := MapOf(ProjectOf(WSi(10), 1), Req);
  try
    Assert.AreEqual(5, M.Count, 'W thickness, the period and the three measurement slots');
    Assert.AreEqual('s0.l0.thickness', M.Slots[0].Name);
    Assert.AreEqual(1, Length(M.Derived));
    Assert.AreEqual('s0.l1.thickness', M.Derived[0].Name, 'the thickest free thickness follows from the period');
    Assert.IsTrue(Req.Mode = fmPeriodic);
    Assert.AreEqual(0, Req.TableSlots);
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Periodic_FreePeriod_AddsThePeriodSlot;
var
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
  k: Integer;
begin
  P := ProjectOf(WSi(10), 1);
  P.Params.LFPSO.FreePeriod := True;
  P.Params.LFPSO.PeriodWindow := 0.05;
  M := MapOf(P, Req);
  try
    k := M.IndexOf('s0.period');
    Assert.IsTrue(k >= 0);
    Assert.AreEqual(47.5, M.Slots[k].Lower, 1E-4);
    Assert.AreEqual(52.5, M.Slots[k].Upper, 1E-4);
    Assert.AreEqual(50.0, M.Slots[k].Start, 1E-4);
  finally
    M.Free;
  end;
end;

{ The fit held the period, the tool does not: a period nobody let move has an
  uncertainty all the same, and a single free thickness would otherwise be
  pinned by it. }
procedure TTestUncertRequest.Periodic_HeldPeriod_IsSampledInASmallWindow;
var
  S: TFitStructure;
  Req: TUncertRequest;
  M: TParamMap;
  k: Integer;
begin
  M := MapOf(ProjectOf(WSi(10), 1), Req);
  try
    k := M.IndexOf('s0.period');
    Assert.IsTrue(k >= 0, 'the period is a slot though the fit held it');
    Assert.AreEqual(49.0, M.Slots[k].Lower, 1E-4, '2 % below the fitted period');
    Assert.AreEqual(51.0, M.Slots[k].Upper, 1E-4, '2 % above');
    Assert.AreEqual(50.0, M.Slots[k].Start, 1E-4);
  finally
    M.Free;
  end;

  S := WSi(10);
  S.Stacks[0].Layers[0].P[1].Fixed := True;          // one free thickness: Si
  M := MapOf(ProjectOf(S, 1), Req);
  try
    Assert.IsTrue(M.IndexOf('s0.period') >= 0, 'Si moves with the period: something is free');
  finally
    M.Free;
  end;

  S := WSi(10);
  S.Stacks[0].Layers[0].P[1].Fixed := True;
  S.Stacks[0].Layers[1].P[1].Fixed := True;
  S.Stacks[0].Layers[0].P[2].min := 1;               // only a roughness is free
  S.Stacks[0].Layers[0].P[2].max := 6;
  M := MapOf(ProjectOf(S, 1), Req);
  try
    Assert.AreEqual(-1, M.IndexOf('s0.period'), 'no free thickness: nothing can take up a change of period');
  finally
    M.Free;
  end;
end;

{ A fit whose period was free over a very wide range (an MCP fit with bounds
  from 10 to 130 A on a 50 A period) is still analysed: the window is cut to
  half the period either way. }
procedure TTestUncertRequest.Periodic_VeryWidePeriodWindow_IsCut;
var
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
  k: Integer;
begin
  P := ProjectOf(WSi(10), 1);
  P.Params.LFPSO.FreePeriod := True;
  P.Params.LFPSO.PeriodWindow := 1.6;
  M := MapOf(P, Req);
  try
    k := M.IndexOf('s0.period');
    Assert.IsTrue(k >= 0);
    Assert.AreEqual(25.0, M.Slots[k].Lower, 1E-4);
    Assert.AreEqual(75.0, M.Slots[k].Upper, 1E-4);
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Periodic_FixedOrNoRange_NotSampled;
var
  S: TFitStructure;
  Req: TUncertRequest;
  M: TParamMap;
begin
  S := WSi(10);
  S.Stacks[0].Layers[0].P[1].Fixed := True;          // has a range, but the fit held it
  S.Stacks[0].Layers[0].P[2].min := 1;               // sigma of W gets a range
  S.Stacks[0].Layers[0].P[2].max := 6;
  M := MapOf(ProjectOf(S, 1), Req);
  try
    Assert.AreEqual(-1, M.IndexOf('s0.l0.thickness'), 'a fixed value is not sampled');
    Assert.IsTrue(M.IndexOf('s0.l0.sigma') >= 0);
    Assert.AreEqual(-1, M.IndexOf('s0.l1.sigma'), 'min = max is not sampled');
    Assert.AreEqual(1, Length(M.Derived), 'Si is the only free thickness: it is the derived one');
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Periodic_StaleTable_IsDropped;
var
  S: TFitStructure;
  Req: TUncertRequest;
  M: TParamMap;
begin
  S := WSi(3);
  S.Stacks[0].Layers[0].PP[1] := [18, 20, 22];       // from an earlier table fit
  M := MapOf(ProjectOf(S, 1), Req);
  try
    Assert.AreEqual(0, Length(M.Template.Stacks[0].Layers[0].PP[1]));
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Profile_UsesTheGradientExtension;
var
  S: TFitStructure;
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
begin
  S := WSi(10);
  S.Stacks[0].Layers[1].P[1].Paired := True;         // Si: one value for the whole stack
  P := ProjectOf(S, 2);
  SetLength(P.Extensions, 1);
  P.Extensions[0].StackID := 0;
  P.Extensions[0].LayerID := 0;
  P.Extensions[0].Subj := ptH;
  P.Extensions[0].Coeffs := [0, 0.1];                // [0] is not stored: the layer's value stands for it
  M := MapOf(P, Req);
  try
    Assert.AreEqual(20.0, M.Slots[M.IndexOf('s0.l0.thickness.c0')].Start, 1E-5);
    Assert.AreEqual(0.1, M.Slots[M.IndexOf('s0.l0.thickness.c1')].Start, 1E-6);
    Assert.IsTrue(M.IndexOf('s0.l1.thickness') >= 0, 'a paired value is one slot');
    Assert.AreEqual(0, Length(M.Derived), 'no derived layer beside a profile');
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Profile_NoExtension_ZeroGradient;
var
  Req: TUncertRequest;
  M: TParamMap;
begin
  M := MapOf(ProjectOf(WSi(10), 2), Req);
  try
    Assert.AreEqual(0.0, M.Slots[M.IndexOf('s0.l0.thickness.c1')].Start, 0.0);
    Assert.AreEqual(0.0, M.Slots[M.IndexOf('s0.l1.thickness.c1')].Start, 0.0);
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Table_OneSlotPerPeriod_KeepsTheFittedTable;
var
  S: TFitStructure;
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
begin
  S := WSi(4);
  S.Stacks[0].Layers[0].PP[1] := [19, 20, 21, 22];
  S.Stacks[0].Layers[1].P[1].Paired := True;
  P := ProjectOf(S, 0);
  P.TableExtension := True;
  M := MapOf(P, Req);
  try
    Assert.AreEqual(4, Req.TableSlots);
    Assert.AreEqual(19.0, M.Slots[M.IndexOf('s0.l0.thickness[1]')].Start, 1E-5);
    Assert.AreEqual(22.0, M.Slots[M.IndexOf('s0.l0.thickness[4]')].Start, 1E-5);
    Assert.IsTrue(M.IndexOf('s0.l1.thickness') >= 0);
    Assert.IsTrue(Req.Mode = fmTable);
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Table_NoTableExtension_StartsFromTheValue;
var
  S: TFitStructure;
  Req: TUncertRequest;
  M: TParamMap;
begin
  S := WSi(4);
  S.Stacks[0].Layers[0].PP[1] := [19, 20, 21, 22];   // not expanded by the main program without the extension
  M := MapOf(ProjectOf(S, 0), Req);
  try
    Assert.AreEqual(20.0, M.Slots[M.IndexOf('s0.l0.thickness[1]')].Start, 1E-5);
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Table_TooLarge_Refused;
var
  S: TFitStructure;
  Req: TUncertRequest;
  Why: string;
begin
  S := WSi(21);
  S.Stacks[0].Layers[1].P[1].Paired := True;
  Why := BuildRequest(ProjectOf(S, 0), Req);
  Assert.Contains(Why, '21');
  Assert.Contains(Why, IntToStr(MAX_TABLE_SLOTS));
end;

procedure TTestUncertRequest.NoCurve_Refused;
var
  P: TXRCXProject;
  Req: TUncertRequest;
begin
  P := ProjectOf(WSi(10), 1);
  P.DataID := -1;
  P.DataTitle := '';
  P.DataCurve := nil;
  Assert.Contains(BuildRequest(P, Req), 'no measured curve');
end;

procedure TTestUncertRequest.NothingFree_Refused;
var
  S: TFitStructure;
  Req: TUncertRequest;
begin
  S := WSi(10);
  S.Stacks[0].Layers[0].P[1].Fixed := True;
  S.Stacks[0].Layers[1].P[1].Fixed := True;
  Assert.Contains(BuildRequest(ProjectOf(S, 1), Req), 'free to vary');
end;

procedure TTestUncertRequest.WavelengthScan_Refused;
var
  P: TXRCXProject;
  Req: TUncertRequest;
begin
  P := ProjectOf(WSi(10), 1);
  P.CalcMode := 1;
  Assert.Contains(BuildRequest(P, Req), 'wavelength scan');
end;

procedure TTestUncertRequest.Prior_OnATableEntry_Raises;
var
  P: TXRCXProject;
  Req: TUncertRequest;
  Pr: TUncertPrior;
begin
  P := ProjectOf(WSi(4), 0);
  Assert.AreEqual('', BuildRequest(P, Req));
  Pr := Default(TUncertPrior);
  Pr.Name := 's0.l0.thickness[2]';
  Pr.Mean := 20;
  Pr.SD := 1;
  Assert.WillRaise(procedure begin BuildMap(Req, [Pr]).Free; end, EParamMap);
end;

procedure TTestUncertRequest.Prior_OnASummary_IsSet;
var
  P: TXRCXProject;
  Req: TUncertRequest;
  Pr: TUncertPrior;
  M: TParamMap;
  S: TFitStructure;
  N: TNuisance;
begin
  P := ProjectOf(WSi(4), 0);
  Assert.AreEqual('', BuildRequest(P, Req));
  Pr := Default(TUncertPrior);
  Pr.Name := 's0.total';
  Pr.Mean := 202;                                    // the model's total is 200
  Pr.SD := 1;
  M := BuildMap(Req, [Pr]);
  try
    M.Template.CopyContent(S);
    Assert.IsTrue(M.Apply(M.StartVector, S, N));
    Assert.AreEqual(4.0, M.PriorTerm(M.StartVector, S), 1E-4, '((200 - 202) / 1)^2');
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.StartProblem_NamesTheValue;
var
  S: TFitStructure;
  Req: TUncertRequest;
  M: TParamMap;
  Why: string;
begin
  S := WSi(10);
  S.Stacks[0].Layers[0].P[1].V := 26;                // edited by hand past its limit of 25
  M := MapOf(ProjectOf(S, 1), Req);
  try
    Why := StartProblem(M, Req);
    Assert.Contains(Why, 'W');
    Assert.Contains(Why, '26');
    Assert.Contains(Why, 'limits');
  finally
    M.Free;
  end;
  M := MapOf(ProjectOf(WSi(10), 1), Req);
  try
    Assert.AreEqual('', StartProblem(M, Req), 'a fit inside its limits has no problem');
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Names_CaptionsGroupsAndKinds;
var
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
  Names: TArray<string>;
  i: Integer;

  function Find(const Name: string): TUncertName;
  var
    k: Integer;
  begin
    for k := 0 to High(Req.Names) do
      if Req.Names[k].Name = Name then
        Exit(Req.Names[k]);
    Assert.Fail('no name ' + Name);
  end;

begin
  P := ProjectOf(WSi(10), 1);
  M := MapOf(P, Req);
  try
    Names := M.ReportedNames;
    Assert.AreEqual(Length(Names), Length(Req.Names), 'one description per reported value');
    for i := 0 to High(Names) do
      Assert.AreEqual(Names[i], Req.Names[i].Name, 'in the map''s order');
  finally
    M.Free;
  end;
  Assert.StartsWith('W', Find('s0.l0.thickness').Caption);
  Assert.AreEqual('ML', Find('s0.l0.thickness').Group, 'the stack''s title');
  Assert.IsTrue(Find('s0.l0.thickness').Kind = unValue);
  Assert.IsTrue(Find('s0.l0.thickness').CanHavePrior);
  Assert.IsTrue(Find('s0.l1.thickness').Kind = unValue, 'the derived layer is a value like any other');
  Assert.AreEqual('Summary', Find('s0.period_mean').Group);
  Assert.IsFalse(Find('s0.period_mean').Held, 'the period is sampled: it has an error to show');
  Assert.IsTrue(Find('s0.period').Kind = unPeriod);
  Assert.IsTrue(Find('s0.period_mean').CanHavePrior);
  Assert.AreEqual('Measurement', Find('c0.background').Group);
  Assert.IsFalse(Find('c0.background').CanHavePrior);
  Assert.IsTrue(Find('c0.ln_f').Kind = unMeasurement);

  P := ProjectOf(WSi(4), 0);
  Assert.AreEqual('', BuildRequest(P, Req));
  Assert.IsTrue(Find('s0.l0.thickness[3]').Kind = unPeriodValue);
  Assert.AreEqual(3, Find('s0.l0.thickness[3]').Period);
  Assert.IsFalse(Find('s0.l0.thickness[3]').CanHavePrior);
  Assert.IsFalse(Find('s0.period_mean').Held, 'a tabled stack''s mean period is a result');
end;

procedure TTestUncertRequest.CalcParams_FollowTheProject;
var
  P: TXRCXProject;
  Req: TUncertRequest;
begin
  P := ProjectOf(WSi(10), 1);
  P.Params.Polarisation := 1;
  Assert.AreEqual('', BuildRequest(P, Req));
  Assert.IsTrue(Req.CalcParams.Mode = cmTheta);
  Assert.AreEqual(1, Req.CalcParams.K);
  Assert.AreEqual(50, Req.CalcParams.N);
  Assert.AreEqual(0.01, Double(Req.CalcParams.DT), 1E-7);
  Assert.AreEqual(1.5406, Double(Req.CalcParams.Lambda), 1E-5);
  Assert.IsTrue(Req.CalcParams.P = cmSP);
  Assert.AreEqual(50, Length(Req.Data));
  P.TwoTheta := True;
  Assert.AreEqual('', BuildRequest(P, Req));
  Assert.AreEqual(2, Req.CalcParams.K, 'a 2theta project is calculated as the main program does');
end;

procedure TTestUncertRequest.UnlinkedCurve_Refused;
var
  P: TXRCXProject;
  Req: TUncertRequest;
begin
  P := ProjectOf(WSi(10), 1);
  P.DataLinked := False;                             // a curve in the project, linked to nothing
  Assert.Contains(BuildRequest(P, Req), 'no measured curve');
end;

{ The profile fit holds a frozen value at its gradient (TLFPSO_Poly), so the
  model the tool samples around must keep that gradient too. }
procedure TTestUncertRequest.Profile_FrozenGradedValue_KeepsItsGradient;
var
  S: TFitStructure;
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
  k: Integer;
begin
  S := WSi(4);
  S.Stacks[0].Layers[0].P[1].Fixed := True;          // W thickness: graded, then frozen
  S.Stacks[0].Layers[1].PP[1] := [1, 2, 3, 4];       // a stale table on Si, from an earlier table fit
  P := ProjectOf(S, 2);
  SetLength(P.Extensions, 1);
  P.Extensions[0].StackID := 0;
  P.Extensions[0].LayerID := 0;
  P.Extensions[0].Subj := ptH;
  P.Extensions[0].Coeffs := [0, 0.5];
  M := MapOf(P, Req);
  try
    Assert.AreEqual(-1, M.IndexOf('s0.l0.thickness.c0'), 'a frozen value is not sampled');
    for k := 1 to 4 do
      Assert.AreEqual(20 + 0.5 * (k - 1),
        Double(M.Template.Stacks[0].Layers[0].PeriodValue(1, k, 4, True)), 1E-5,
        Format('period %d keeps the fitted gradient', [k]));
    Assert.IsTrue(M.IndexOf('s0.l1.thickness.c0') >= 0, 'Si is sampled as a profile');
    Assert.AreEqual(30.0, M.Slots[M.IndexOf('s0.l1.thickness.c0')].Start, 1E-5, 'not from the stale table');
  finally
    M.Free;
  end;
end;

procedure TTestUncertRequest.Table_EntryOutsideItsLimits_IsNamed;
var
  S: TFitStructure;
  P: TXRCXProject;
  Req: TUncertRequest;
  M: TParamMap;
  Why: string;
begin
  S := WSi(4);
  S.Stacks[0].Layers[0].PP[1] := [19, 20, 26, 22];   // period 3 past the limit of 25
  S.Stacks[0].Layers[1].P[1].Paired := True;
  P := ProjectOf(S, 0);
  P.TableExtension := True;
  M := MapOf(P, Req);
  try
    Why := StartProblem(M, Req);
    Assert.Contains(Why, '26');
    Assert.Contains(Why, 'period 3');
    Assert.Contains(Why, 'limits');
  finally
    M.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertRequest);

end.
