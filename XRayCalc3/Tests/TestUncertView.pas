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

unit TestUncertView;

(* What the uncertainty tool's window shows, as data: rows, the error text,
   the table, the details, a typed known value. Nothing is calculated here. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUncertView = class
  public
    [Test] procedure ErrorText_Symmetric;
    [Test] procedure ErrorText_Asymmetric;
    [Test] procedure ErrorText_NaN;
    [Test] procedure ValueText_FollowsTheError;
    [Test] procedure Rows_GroupsAndOrder;
    [Test] procedure Rows_HeldNumber_HasNoError;
    [Test] procedure Rows_NoResult_ShowsPriorsOnly;
    [Test] procedure Rows_AtLimit_IsFlagged;
    [Test] procedure TableText_HeaderAndTabs;
    [Test] procedure TableCSV_QuotesCommasAndQuotes;
    [Test] procedure DepthSeries_OnePerTabledValue;
    [Test] procedure DetailsText_NamesStrongCorrelationsOnly;
    [Test] procedure ParsePrior_Number;
    [Test] procedure ParsePrior_Empty_Removes;
    [Test] procedure ParsePrior_NotANumber;
    [Test] procedure ParsePrior_ErrorNotPositive;
    [Test] procedure WithPrior_ReplacesAddsRemoves;
    [Test] procedure TimeLeftText_RoundsAndStaysQuietWhenUnknown;
    [Test] procedure CellEdit_KnownBeforeItsError_IsKeptNotStored;
    [Test] procedure CellEdit_ErrorCompletesTheKnownValue;
    [Test] procedure CellEdit_ErrorLeftEmpty_Refused;
    [Test] procedure CellEdit_NoteOrErrorWithoutKnown_Refused;
    [Test] procedure CellEdit_ClearedKnown_RemovesOnlyWhatIsStored;
    [Test] procedure CellEdit_Unchanged_IsNothing;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_UncertRequest, unit_UncertRun, unit_UncertView;

const
  MINUS = #$2212;
  ANGSTROM = #$00C5;

function N(const Name, Caption, Group: string; Kind: TUncertNameKind; Period: Integer = 0): TUncertName;
begin
  Result := Default(TUncertName);
  Result.Name := Name;
  Result.Caption := Caption;
  Result.Group := Group;
  Result.Kind := Kind;
  Result.Period := Period;
  Result.CanHavePrior := Kind in [unValue, unSummary];
  Result.Stack := 0;
  Result.Layer := -1;
  Result.P := -1;
  if Kind in [unValue, unPeriodValue] then
  begin
    Result.Layer := StrToInt(Name.Substring(4, 1));
    Result.P := 1;
  end;
end;

function V(const Name: string; P50, Minus, Plus: Double): TUncertValue;
begin
  Result := Default(TUncertValue);
  Result.Name := Name;
  Result.Best := P50;
  Result.P50 := P50;
  Result.P16 := P50 - Minus;
  Result.P84 := P50 + Plus;
  Result.Minus := Minus;
  Result.Plus := Plus;
  Result.RHat := 1.01;
end;

{ W thickness, one tabled entry, the period, the mean period, the background. }
procedure Periodic(out Names: TArray<TUncertName>; out Res: TUncertResult);
begin
  Names := [
    N('s0.l0.thickness', 'W  H, ' + ANGSTROM, 'ML', unValue),
    N('s0.l0.thickness[1]', 'W  H, ' + ANGSTROM + ', period 1', 'ML', unPeriodValue, 1),
    N('s0.period', 'Period, ' + ANGSTROM, 'ML', unPeriod),
    N('s0.period_mean', 'Mean period, ' + ANGSTROM, 'Summary', unSummary),
    N('s0.total', 'Total thickness, ' + ANGSTROM, 'Summary', unSummary),
    N('c0.background', 'Background', 'Measurement', unMeasurement)];
  Res := Default(TUncertResult);
  Res.Settled := True;
  Res.Device := 'CPU';
  Res.Walkers := 32;
  Res.StepsRun := 4000;
  Res.Seconds := 52;
  Res.Values := [
    V('s0.l0.thickness', 18.2345, 0.3, 0.3),
    V('s0.l0.thickness[1]', 18.1, 0.2, 0.2),
    V('s0.period', 55.7234, 0.12, 0.12),
    V('s0.period_mean', 55.7234, 0.12, 0.12),
    V('s0.total', 2785.3, 4.2, 4.0),
    V('c0.background', 1E-6, 1E-7, 1E-7)];
end;

function RowOf(const Rows: TArray<TUncertRow>; const Name: string): TUncertRow;
var
  k: Integer;
begin
  for k := 0 to High(Rows) do
    if Rows[k].Name = Name then
      Exit(Rows[k]);
  Assert.Fail('no row ' + Name);
end;

procedure TTestUncertView.TimeLeftText_RoundsAndStaysQuietWhenUnknown;
begin
  Assert.AreEqual('about 1 min 10 s left', TimeLeftText(72));
  Assert.AreEqual('about 12 min left', TimeLeftText(725));
  Assert.AreEqual('about 35 s left', TimeLeftText(33));
  Assert.AreEqual('a few seconds left', TimeLeftText(4));
  Assert.AreEqual('', TimeLeftText(0));
  Assert.AreEqual('', TimeLeftText(-1));
  Assert.AreEqual('', TimeLeftText(NaN));
  Assert.AreEqual('', TimeLeftText(Infinity));
end;

procedure TTestUncertView.ErrorText_Symmetric;
begin
  Assert.AreEqual('0.30', ErrorText(0.31, 0.29));
  Assert.AreEqual('4.1', ErrorText(4.2, 4.0));
  Assert.AreEqual('12', ErrorText(12.3, 12.1));
end;

procedure TTestUncertView.ErrorText_Asymmetric;
begin
  Assert.AreEqual('+0.30 / ' + MINUS + '0.10', ErrorText(0.1, 0.3));
end;

procedure TTestUncertView.ErrorText_NaN;
begin
  Assert.AreEqual('', ErrorText(NaN, 0.3));
  Assert.AreEqual('', ErrorText(0.3, NaN));
end;

procedure TTestUncertView.ValueText_FollowsTheError;
begin
  Assert.AreEqual('55.72', ValueText(55.7234, 0.11, 0.12));
  Assert.AreEqual('2785.3', ValueText(2785.3, 4.2, 4.0));
  Assert.AreEqual('18.235', ValueText(18.23456, NaN, NaN), 'five significant digits without an error');
  Assert.AreEqual('18.235', ValueText(18.23456, 0, 0), 'and for a number that does not move');
end;

procedure TTestUncertView.Rows_GroupsAndOrder;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Rows: TArray<TUncertRow>;
begin
  Periodic(Names, Res);
  Rows := RowsOf(Names, Res, True, nil);
  Assert.AreEqual(3, Integer(Length(Rows)), 'the period, the total and W: no table entry, no slot row, no measurement row');
  Assert.AreEqual('s0.period_mean', Rows[0].Name);
  Assert.AreEqual('Summary', Rows[0].Group);
  Assert.AreEqual('Period, ' + ANGSTROM, Rows[0].Caption, 'a sampled period is the period, not a mean');
  Assert.AreEqual('55.72', Rows[0].Value);
  Assert.AreEqual('0.12', Rows[0].Error);
  Assert.AreEqual('s0.total', Rows[1].Name);
  Assert.AreEqual('s0.l0.thickness', Rows[2].Name);
  Assert.AreEqual('ML', Rows[2].Group);
  Assert.AreEqual('18.23', Rows[2].Value);
  Assert.AreEqual('0.30', Rows[2].Error);

  { without a period slot the mean period keeps its caption }
  Delete(Names, 2, 1);
  Delete(Res.Values, 2, 1);
  Rows := RowsOf(Names, Res, True, nil);
  Assert.AreEqual('Mean period, ' + ANGSTROM, Rows[0].Caption);
end;

procedure TTestUncertView.Rows_HeldNumber_HasNoError;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Row: TUncertRow;
begin
  Periodic(Names, Res);
  Names[4].Held := True;
  Res.Values[4] := V('s0.total', 2785.3, 0, 0);
  Row := RowOf(RowsOf(Names, Res, True, nil), 's0.total');
  Assert.AreEqual('', Row.Error);
  Assert.AreEqual('2785.3', Row.Value);
end;

procedure TTestUncertView.Rows_NoResult_ShowsPriorsOnly;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Pr: TUncertPrior;
  Row: TUncertRow;
begin
  Periodic(Names, Res);
  Pr.Name := 's0.total';
  Pr.Mean := 2790;
  Pr.SD := 10;
  Pr.Note := 'profilometer';
  Row := RowOf(RowsOf(Names, Default(TUncertResult), False, [Pr]), 's0.total');
  Assert.AreEqual('2790', Row.Known);
  Assert.AreEqual('10', Row.KnownError);
  Assert.AreEqual('profilometer', Row.Note);
  Assert.AreEqual('', Row.Value);
  Assert.AreEqual('', Row.Error);
  Assert.IsTrue(Row.CanHavePrior);
end;

procedure TTestUncertView.Rows_AtLimit_IsFlagged;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Rows: TArray<TUncertRow>;
begin
  Periodic(Names, Res);
  Res.Values[0].AtLimit := True;
  Rows := RowsOf(Names, Res, True, nil);
  Assert.IsTrue(RowOf(Rows, 's0.l0.thickness').AtLimit);
  Assert.IsFalse(RowOf(Rows, 's0.total').AtLimit);
end;

procedure TTestUncertView.TableText_HeaderAndTabs;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Lines: TArray<string>;
begin
  Periodic(Names, Res);
  Lines := TableText(RowsOf(Names, Res, True, nil)).Split([sLineBreak]);
  Assert.AreEqual('Parameter'#9'Value'#9#$00B1#9'Known'#9#$00B1#9'Note', Lines[0]);
  Assert.AreEqual('Summary', Lines[1], 'a group is a line of its own');
  Assert.AreEqual('Period, ' + ANGSTROM + #9'55.72'#9'0.12'#9#9#9, Lines[2]);
  Assert.AreEqual('ML', Lines[4]);
end;

procedure TTestUncertView.TableCSV_QuotesCommasAndQuotes;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Pr: TUncertPrior;
  Lines: TArray<string>;
begin
  Periodic(Names, Res);
  Pr.Name := 's0.total';
  Pr.Mean := 2790;
  Pr.SD := 10;
  Pr.Note := 'a, "b"';
  Lines := TableCSV(RowsOf(Names, Res, True, [Pr])).Split([sLineBreak]);
  Assert.AreEqual('Group,Parameter,Value,Error,Known,Known error,Note', Lines[0]);
  Assert.AreEqual('Summary,"Total thickness, ' + ANGSTROM + '",2785.3,4.1,2790,10,"a, ""b"""', Lines[2]);
end;

procedure TTestUncertView.DepthSeries_OnePerTabledValue;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  D: TArray<TDepthSeries>;
  k: Integer;
begin
  SetLength(Names, 6);
  SetLength(Res.Values, 6);
  for k := 1 to 3 do
  begin
    Names[k - 1] := N(Format('s0.l0.thickness[%d]', [k]), Format('W  H, %s, period %d', [ANGSTROM, k]),
      'ML', unPeriodValue, k);
    Res.Values[k - 1] := V(Names[k - 1].Name, 20 + k, 0.5, 0.5);
    Names[k + 2] := N(Format('s0.l1.thickness[%d]', [k]), Format('Si  H, %s, period %d', [ANGSTROM, k]),
      'ML', unPeriodValue, k);
    Res.Values[k + 2] := V(Names[k + 2].Name, 30 + k, 0.5, 0.5);
  end;
  D := DepthSeriesOf(Names, Res, True);
  Assert.AreEqual(2, Integer(Length(D)));
  Assert.AreEqual('s0.l0.thickness', D[0].Name);
  Assert.AreEqual('ML: W  H, ' + ANGSTROM, D[0].Caption);
  Assert.AreEqual(3, Integer(Length(D[1].Period)));
  Assert.AreEqual(3.0, D[1].Period[2], 0.0);
  Assert.AreEqual(33.0, D[1].P50[2], 1E-12);
  Assert.AreEqual(32.5, D[1].P16[2], 1E-12);
  Assert.AreEqual(33.5, D[1].P84[2], 1E-12);

  D := DepthSeriesOf(Names, Default(TUncertResult), False);
  Assert.AreEqual(2, Integer(Length(D)), 'the series are known before a run');
  Assert.AreEqual(0, Integer(Length(D[0].P16)));
  Assert.AreEqual(3, Integer(Length(D[0].Period)));
end;

procedure TTestUncertView.DetailsText_NamesStrongCorrelationsOnly;
var
  Names: TArray<TUncertName>;
  Res: TUncertResult;
  Text: string;
  i, j: Integer;
begin
  Periodic(Names, Res);
  SetLength(Res.Correlation, 6, 6);
  for i := 0 to 5 do
    for j := 0 to 5 do
      Res.Correlation[i][j] := IfThen(i = j, 1.0, 0.3);
  Res.Correlation[0][4] := -0.85;
  Res.Correlation[4][0] := -0.85;
  Text := DetailsText(Names, Res);
  Assert.Contains(Text, 'CPU');
  Assert.Contains(Text, '4000');
  Assert.Contains(Text, 'Background');
  Assert.Contains(Text, MINUS + '0.85');
  Assert.AreEqual(2, Integer(Length(Text.Split(['0.85']))), 'the pair is named once');
  Assert.IsFalse(Text.Contains('0.30 '), 'a weak correlation is not listed');
  Assert.IsFalse(Text.ToLower.Contains('posterior'));
end;

procedure TTestUncertView.ParsePrior_Number;
var
  Pr: TUncertPrior;
  Remove: Boolean;
begin
  Assert.AreEqual('', ParsePrior('s0.total', ' 2790 ', '10', 'n', Pr, Remove));
  Assert.IsFalse(Remove);
  Assert.AreEqual('s0.total', Pr.Name);
  Assert.AreEqual(2790.0, Pr.Mean, 0.0);
  Assert.AreEqual(10.0, Pr.SD, 0.0);
  Assert.AreEqual('n', Pr.Note);
end;

procedure TTestUncertView.ParsePrior_Empty_Removes;
var
  Pr: TUncertPrior;
  Remove: Boolean;
begin
  Assert.AreEqual('', ParsePrior('s0.total', '  ', '10', 'n', Pr, Remove));
  Assert.IsTrue(Remove);
end;

procedure TTestUncertView.ParsePrior_NotANumber;
var
  Pr: TUncertPrior;
  Remove: Boolean;
begin
  Assert.Contains(ParsePrior('s0.total', '27,9', '1', '', Pr, Remove), 'number');
  Assert.Contains(ParsePrior('s0.total', 'abc', '1', '', Pr, Remove), 'number');
  Assert.Contains(ParsePrior('s0.total', 'NaN', '1', '', Pr, Remove), 'number');
end;

procedure TTestUncertView.ParsePrior_ErrorNotPositive;
var
  Pr: TUncertPrior;
  Remove: Boolean;
begin
  Assert.Contains(ParsePrior('s0.total', '2790', '0', '', Pr, Remove), 'greater than zero');
  Assert.Contains(ParsePrior('s0.total', '2790', '-1', '', Pr, Remove), 'greater than zero');
  Assert.Contains(ParsePrior('s0.total', '2790', '', '', Pr, Remove), 'greater than zero');
  Assert.Contains(ParsePrior('s0.total', '2790', 'x', '', Pr, Remove), 'greater than zero');
end;

procedure TTestUncertView.WithPrior_ReplacesAddsRemoves;
var
  A, B: TUncertPrior;
  L: TArray<TUncertPrior>;
begin
  A := Default(TUncertPrior);
  A.Name := 'a';
  A.Mean := 1;
  A.SD := 1;
  B := A;
  B.Name := 'b';
  L := WithPrior(nil, A, False);
  L := WithPrior(L, B, False);
  Assert.AreEqual(2, Integer(Length(L)));
  A.Mean := 5;
  L := WithPrior(L, A, False);
  Assert.AreEqual(2, Integer(Length(L)), 'replaced, not added');
  Assert.AreEqual(5.0, L[0].Mean, 0.0);
  L := WithPrior(L, A, True);
  Assert.AreEqual(1, Integer(Length(L)));
  Assert.AreEqual('b', L[0].Name);
  L := WithPrior(L, A, True);
  Assert.AreEqual(1, Integer(Length(L)), 'removing what is not there changes nothing');
end;

{ What an edit of a Known, +- or Note cell means: decided here, so the window
  only carries it out. }

function TotalRow(const Known, KnownError, Note: string): TUncertRow;
begin
  Result := Default(TUncertRow);
  Result.Name := 's0.total';
  Result.CanHavePrior := True;
  Result.Known := Known;
  Result.KnownError := KnownError;
  Result.Note := Note;
end;

procedure TTestUncertView.CellEdit_KnownBeforeItsError_IsKeptNotStored;
var
  NewRow: TUncertRow;
  Pr: TUncertPrior;
  Why: string;
begin
  Assert.IsTrue(DecideCellEdit(TotalRow('', '', ''), False, COL_KNOWN, ' 2790 ', NewRow, Pr, Why) = cePending);
  Assert.AreEqual('2790', NewRow.Known, 'the row keeps what was typed');
  Assert.AreEqual('', Why);
  Assert.IsTrue(DecideCellEdit(TotalRow('', '', ''), False, COL_KNOWN, '27,9', NewRow, Pr, Why) = ceRefuse,
    'but only a number');
  Assert.Contains(Why, 'number');
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '', ''), False, COL_NOTE, 'profilometer', NewRow, Pr, Why) = cePending,
    'a note before the +- waits too');
  Assert.AreEqual('profilometer', NewRow.Note);
end;

procedure TTestUncertView.CellEdit_ErrorCompletesTheKnownValue;
var
  NewRow: TUncertRow;
  Pr: TUncertPrior;
  Why: string;
begin
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '', 'n'), False, COL_KNOWN_ERROR, '10', NewRow, Pr, Why) = ceStore);
  Assert.AreEqual('s0.total', Pr.Name);
  Assert.AreEqual(2790.0, Pr.Mean, 0.0);
  Assert.AreEqual(10.0, Pr.SD, 0.0);
  Assert.AreEqual('n', Pr.Note);
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '10', ''), True, COL_NOTE, 'TEM', NewRow, Pr, Why) = ceStore,
    'a note on a stored value is stored');
  Assert.AreEqual('TEM', Pr.Note);
end;

procedure TTestUncertView.CellEdit_ErrorLeftEmpty_Refused;
var
  NewRow: TUncertRow;
  Pr: TUncertPrior;
  Why: string;
begin
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '5', ''), True, COL_KNOWN_ERROR, '', NewRow, Pr, Why) = ceRefuse);
  Assert.Contains(Why, 'greater than zero');
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '', ''), False, COL_KNOWN_ERROR, '0', NewRow, Pr, Why) = ceRefuse);
end;

procedure TTestUncertView.CellEdit_NoteOrErrorWithoutKnown_Refused;
var
  NewRow: TUncertRow;
  Pr: TUncertPrior;
  Why: string;
begin
  Assert.IsTrue(DecideCellEdit(TotalRow('', '', ''), False, COL_NOTE, 'TEM', NewRow, Pr, Why) = ceRefuse);
  Assert.Contains(Why, 'known value first');
  Assert.IsTrue(DecideCellEdit(TotalRow('', '', ''), False, COL_KNOWN_ERROR, '10', NewRow, Pr, Why) = ceRefuse);
end;

procedure TTestUncertView.CellEdit_ClearedKnown_RemovesOnlyWhatIsStored;
var
  NewRow: TUncertRow;
  Pr: TUncertPrior;
  Why: string;
begin
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '10', 'n'), True, COL_KNOWN, '', NewRow, Pr, Why) = ceRemove);
  Assert.AreEqual('s0.total', Pr.Name, 'which one to remove');
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '', ''), False, COL_KNOWN, '', NewRow, Pr, Why) = ceNothing,
    'a value that was never stored is just dropped');
  Assert.AreEqual('', NewRow.Known);
end;

procedure TTestUncertView.CellEdit_Unchanged_IsNothing;
var
  NewRow: TUncertRow;
  Pr: TUncertPrior;
  Why: string;
begin
  Assert.IsTrue(DecideCellEdit(TotalRow('2790', '10', 'n'), True, COL_KNOWN_ERROR, '10', NewRow, Pr, Why) = ceNothing,
    'nothing is written for an edit that changed nothing');
  Assert.IsTrue(DecideCellEdit(TotalRow('', '', ''), False, COL_KNOWN, '', NewRow, Pr, Why) = ceNothing);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertView);

end.
