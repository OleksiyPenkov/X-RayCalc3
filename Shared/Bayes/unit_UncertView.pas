(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_UncertView;

(* What the uncertainty tool's window shows, as data: the list's rows, the
   error text, the table as text and CSV, the Details text, the depth chart's
   points, and a typed known value. The window only draws these. No VCL. *)

interface

uses
  System.SysUtils, unit_UncertRequest, unit_UncertRun;

type
  TUncertRow = record
    Name: string;                 // the reported name
    Group, Caption: string;
    Value, Error: string;         // '' while there is no result; Error '' for a number that does not move
    Known, KnownError, Note: string;
    CanHavePrior: Boolean;
    AtLimit: Boolean;
  end;

  TDepthSeries = record
    Name: string;                 // 's0.l0.thickness'
    Caption: string;              // 'ML: W  H, A'
    Period, P16, P50, P84: TArray<Double>;   // P16, P50, P84 empty while there is no result
  end;

/// <summary>'0.30', or '+0.30 / -0.10' (a true minus sign) when the halves
/// differ by more than a factor 1.5; two significant digits; '' when either
/// half is NaN.</summary>
function ErrorText(Minus, Plus: Double): string;
/// <summary>The value to the decimal place of its error's second digit; five
/// significant digits when there is no error.</summary>
function ValueText(Value, Minus, Plus: Double): string;
/// <summary>The list: summaries first, then the plain values, each in Names'
/// order. A table entry, a profile coefficient, a period slot and the
/// measurement's values have no row; a stack whose period is sampled shows
/// its mean period as 'Period'.</summary>
function RowsOf(const Names: TArray<TUncertName>; const Res: TUncertResult;
  HasResult: Boolean; const Priors: TArray<TUncertPrior>): TArray<TUncertRow>;
/// <summary>Tab-separated: a header line, each group as a line of its own,
/// a line per row.</summary>
function TableText(const Rows: TArray<TUncertRow>): string;
/// <summary>RFC 4180, the group as the first column.</summary>
function TableCSV(const Rows: TArray<TUncertRow>): string;
/// <summary>One series per layer value that is given period by period.</summary>
function DepthSeriesOf(const Names: TArray<TUncertName>; const Res: TUncertResult;
  HasResult: Boolean): TArray<TDepthSeries>;
/// <summary>What Details shows: how the run went, the measurement's values,
/// how well the walkers agree on each value, and every pair of values that
/// move together (correlation of 0.7 or more in size).</summary>
function DetailsText(const Names: TArray<TUncertName>; const Res: TUncertResult): string;
/// <summary>'' and the known value, or one plain sentence. An empty
/// KnownText removes the entry: '' with Remove True. A decimal point only.</summary>
function ParsePrior(const Name, KnownText, ErrorText, Note: string;
  out Prior: TUncertPrior; out Remove: Boolean): string;
/// <summary>Priors with the entry for Prior.Name replaced, added or (Remove)
/// taken out.</summary>
function WithPrior(const Priors: TArray<TUncertPrior>; const Prior: TUncertPrior;
  Remove: Boolean): TArray<TUncertPrior>;
/// <summary>The progress line: 'about 1 min 10 s left', 'about 12 min left',
/// 'a few seconds left'; '' when the time is not known.</summary>
function TimeLeftText(Seconds: Double): string;

implementation

uses
  System.Math;

const
  MINUS_SIGN = #$2212;
  PLUS_MINUS = #$00B1;

function Inv: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

{ E > 0 rounded to two significant digits, and the decimals that show them. }
function TwoDigits(E: Double): Double;
begin
  Result := RoundTo(E, Floor(Log10(E)) - 1);
end;

function DecimalsFor(E: Double): Integer;
begin
  Result := Max(0, 1 - Floor(Log10(E)));
end;

function Fixed(X: Double; Decimals: Integer): string;
begin
  Result := FloatToStrF(X, ffFixed, 18, Decimals, Inv);
end;

function ErrorText(Minus, Plus: Double): string;
var
  E: Double;
  D: Integer;
begin
  if IsNan(Minus) or IsNan(Plus) then
    Exit('');
  if (Minus <= 0) and (Plus <= 0) then
    Exit('0');
  if Max(Minus, Plus) > 1.5 * Min(Minus, Plus) then
  begin
    D := DecimalsFor(TwoDigits(Max(Minus, Plus)));
    Exit('+' + Fixed(Plus, D) + ' / ' + MINUS_SIGN + Fixed(Minus, D));
  end;
  E := TwoDigits((Minus + Plus) / 2);
  Result := Fixed(E, DecimalsFor(E));
end;

function ValueText(Value, Minus, Plus: Double): string;
begin
  if IsNan(Value) then
    Exit('');
  if IsNan(Minus) or IsNan(Plus) or (Max(Minus, Plus) <= 0) then
    Exit(FloatToStrF(Value, ffGeneral, 5, 0, Inv));
  Result := Fixed(Value, DecimalsFor(TwoDigits(Max(Minus, Plus))));
end;

function PriorOf(const Priors: TArray<TUncertPrior>; const Name: string; out Prior: TUncertPrior): Boolean;
var
  k: Integer;
begin
  for k := 0 to High(Priors) do
    if Priors[k].Name = Name then
    begin
      Prior := Priors[k];
      Exit(True);
    end;
  Result := False;
end;

function RowsOf(const Names: TArray<TUncertName>; const Res: TUncertResult;
  HasResult: Boolean; const Priors: TArray<TUncertPrior>): TArray<TUncertRow>;
var
  Rows: TArray<TUncertRow>;

  function PeriodIsSampled(Stack: Integer): Boolean;
  var
    k: Integer;
  begin
    Result := False;
    for k := 0 to High(Names) do
      if (Names[k].Kind = unPeriod) and (Names[k].Stack = Stack) then
        Exit(True);
  end;

  procedure Add(k: Integer);
  var
    Row: TUncertRow;
    Prior: TUncertPrior;
    V: TUncertValue;
  begin
    Row := Default(TUncertRow);
    Row.Name := Names[k].Name;
    Row.Group := Names[k].Group;
    Row.Caption := Names[k].Caption;
    { the mean of a period that is one number is that period }
    if (Names[k].Kind = unSummary) and Names[k].Name.EndsWith('.period_mean') and
       PeriodIsSampled(Names[k].Stack) then
      Row.Caption := Row.Caption.Replace('Mean period', 'Period');
    Row.CanHavePrior := Names[k].CanHavePrior;
    if HasResult and (k <= High(Res.Values)) then
    begin
      V := Res.Values[k];
      Row.AtLimit := V.AtLimit;
      if IsNan(V.P50) then
        Row.Value := ValueText(V.Best, NaN, NaN)
      else
      begin
        Row.Value := ValueText(V.P50, V.Minus, V.Plus);
        if not Names[k].Held and (Max(V.Minus, V.Plus) > 0) then
          Row.Error := ErrorText(V.Minus, V.Plus);
      end;
    end;
    if PriorOf(Priors, Row.Name, Prior) then
    begin
      Row.Known := FloatToStr(Prior.Mean, Inv);
      Row.KnownError := FloatToStr(Prior.SD, Inv);
      Row.Note := Prior.Note;
    end;
    Rows := Rows + [Row];
  end;

var
  k: Integer;
begin
  Rows := nil;
  for k := 0 to High(Names) do
    if Names[k].Kind = unSummary then
      Add(k);
  for k := 0 to High(Names) do
    if Names[k].Kind = unValue then
      Add(k);
  Result := Rows;
end;

function TableText(const Rows: TArray<TUncertRow>): string;
var
  SB: TStringBuilder;
  k: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('Parameter'#9'Value'#9 + PLUS_MINUS + #9'Known'#9 + PLUS_MINUS + #9'Note');
    for k := 0 to High(Rows) do
    begin
      if (k = 0) or (Rows[k].Group <> Rows[k - 1].Group) then
        SB.Append(sLineBreak).Append(Rows[k].Group);
      SB.Append(sLineBreak).Append(Rows[k].Caption).Append(#9).Append(Rows[k].Value).Append(#9)
        .Append(Rows[k].Error).Append(#9).Append(Rows[k].Known).Append(#9)
        .Append(Rows[k].KnownError).Append(#9).Append(Rows[k].Note);
    end;
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function CSVField(const S: string): string;
begin
  if S.IndexOfAny([',', '"', #13, #10]) >= 0 then
    Result := '"' + S.Replace('"', '""') + '"'
  else
    Result := S;
end;

function TableCSV(const Rows: TArray<TUncertRow>): string;
var
  SB: TStringBuilder;
  k: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append('Group,Parameter,Value,Error,Known,Known error,Note');
    for k := 0 to High(Rows) do
      SB.Append(sLineBreak).Append(CSVField(Rows[k].Group)).Append(',')
        .Append(CSVField(Rows[k].Caption)).Append(',').Append(CSVField(Rows[k].Value)).Append(',')
        .Append(CSVField(Rows[k].Error)).Append(',').Append(CSVField(Rows[k].Known)).Append(',')
        .Append(CSVField(Rows[k].KnownError)).Append(',').Append(CSVField(Rows[k].Note));
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function DepthSeriesOf(const Names: TArray<TUncertName>; const Res: TUncertResult;
  HasResult: Boolean): TArray<TDepthSeries>;
var
  k, s, Hit, Cut: Integer;
  Key: string;
begin
  Result := nil;
  for k := 0 to High(Names) do
  begin
    if Names[k].Kind <> unPeriodValue then
      Continue;
    Key := Names[k].Name.Substring(0, Names[k].Name.IndexOf('['));
    Hit := -1;
    for s := 0 to High(Result) do
      if Result[s].Name = Key then
        Hit := s;
    if Hit < 0 then
    begin
      Hit := Length(Result);
      SetLength(Result, Hit + 1);
      Result[Hit].Name := Key;
      Result[Hit].Caption := Names[k].Caption;
      Cut := Result[Hit].Caption.LastIndexOf(', period');
      if Cut > 0 then
        Result[Hit].Caption := Result[Hit].Caption.Substring(0, Cut);
      Result[Hit].Caption := Names[k].Group + ': ' + Result[Hit].Caption;
    end;
    Result[Hit].Period := Result[Hit].Period + [Names[k].Period];
    if HasResult and (k <= High(Res.Values)) and not IsNan(Res.Values[k].P50) then
    begin
      Result[Hit].P16 := Result[Hit].P16 + [Res.Values[k].P16];
      Result[Hit].P50 := Result[Hit].P50 + [Res.Values[k].P50];
      Result[Hit].P84 := Result[Hit].P84 + [Res.Values[k].P84];
    end;
  end;
end;

function DetailsText(const Names: TArray<TUncertName>; const Res: TUncertResult): string;
var
  SB: TStringBuilder;
  i, j, Pairs, Count: Integer;

  function Title(k: Integer): string;
  begin
    Result := Names[k].Caption;
    if (Names[k].Group <> '') and (Names[k].Group <> 'Summary') and (Names[k].Group <> 'Measurement') then
      Result := Result + ' (' + Names[k].Group + ')';
  end;

  procedure Line(const S: string);
  begin
    SB.Append(S).Append(sLineBreak);
  end;

begin
  Count := Min(Length(Names), Length(Res.Values));
  SB := TStringBuilder.Create;
  try
    Line('The run');
    Line('  Calculated on: ' + Res.Device);
    Line(Format('  Walkers: %d, steps: %d', [Res.Walkers, Res.StepsRun]));
    Line(Format('  Time: %.0f s', [Res.Seconds], Inv));
    if Res.Repeated then
      Line('  The walkers disagreed after the first run; a longer second run was made.');
    Line('');
    Line('The measurement');
    for i := 0 to Count - 1 do
      if (Names[i].Kind = unMeasurement) and not IsNan(Res.Values[i].P50) then
        Line(Format('  %s: %s %s %s', [Names[i].Caption, FloatToStrF(Res.Values[i].P50, ffGeneral, 4, 0, Inv),
          PLUS_MINUS, FloatToStrF((Res.Values[i].Minus + Res.Values[i].Plus) / 2, ffGeneral, 2, 0, Inv)]));
    Line('');
    Line('How well the walkers agree (1.00 is full agreement; above 1.20 no errors are given)');
    for i := 0 to Count - 1 do
      if not IsNan(Res.Values[i].RHat) and not Names[i].Held then
        Line(Format('  %s: %.2f', [Title(i), Res.Values[i].RHat], Inv));
    Line('');
    Line('Values that move together (correlation of 0.7 or more in size)');
    Pairs := 0;
    for i := 0 to Min(Count, Length(Res.Correlation)) - 1 do
      for j := i + 1 to Min(Count, Length(Res.Correlation[i])) - 1 do
        if not IsNan(Res.Correlation[i][j]) and (Abs(Res.Correlation[i][j]) >= 0.7) and
           (Names[i].Kind <> unCoefficient) and (Names[j].Kind <> unCoefficient) then
        begin
          Line(Format('  %s and %s: %s', [Title(i), Title(j),
            Format('%.2f', [Res.Correlation[i][j]], Inv).Replace('-', MINUS_SIGN)]));
          Inc(Pairs);
        end;
    if Pairs = 0 then
      Line('  none');
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function ParsePrior(const Name, KnownText, ErrorText, Note: string;
  out Prior: TUncertPrior; out Remove: Boolean): string;
var
  Mean, SD: Double;
begin
  Result := '';
  Prior := Default(TUncertPrior);
  Remove := Trim(KnownText) = '';
  if Remove then
    Exit;
  if not TryStrToFloat(Trim(KnownText), Mean, Inv) or IsNan(Mean) or IsInfinite(Mean) then
    Exit(Format('"%s" is not a number. Type the known value with a decimal point, like 27.9.',
      [Trim(KnownText)]));
  if not TryStrToFloat(Trim(ErrorText), SD, Inv) or IsNan(SD) or IsInfinite(SD) or (SD <= 0) then
    Exit('A known value needs its ' + PLUS_MINUS + ': a number greater than zero, with a decimal point.');
  Prior.Name := Name;
  Prior.Mean := Mean;
  Prior.SD := SD;
  Prior.Note := Trim(Note);
end;

function WithPrior(const Priors: TArray<TUncertPrior>; const Prior: TUncertPrior;
  Remove: Boolean): TArray<TUncertPrior>;
var
  k: Integer;
  Found: Boolean;
begin
  Result := nil;
  Found := False;
  for k := 0 to High(Priors) do
    if Priors[k].Name <> Prior.Name then
      Result := Result + [Priors[k]]
    else if not Remove then
    begin
      Result := Result + [Prior];
      Found := True;
    end;
  if not Remove and not Found then
    Result := Result + [Prior];
end;

function TimeLeftText(Seconds: Double): string;
var
  S: Integer;
begin
  if IsNan(Seconds) or IsInfinite(Seconds) or (Seconds <= 0) then
    Exit('');
  if Seconds < 5 then
    Exit('a few seconds left');
  if Seconds < 60 then
    Exit(Format('about %d s left', [Ceil(Seconds / 5) * 5]));
  if Seconds >= 600 then
    Exit(Format('about %d min left', [Round(Seconds / 60)]));
  S := Round(Seconds / 10) * 10;
  if S mod 60 = 0 then
    Result := Format('about %d min left', [S div 60])
  else
    Result := Format('about %d min %d s left', [S div 60, S mod 60]);
end;

end.
