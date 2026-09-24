(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_DataProcessing;

interface

uses
  VCLTee.TeEngine,
  unit_types;

procedure AutoMerge(Series: TChartSeries);
procedure ManualMerge( X, K: single; Series: TChartSeries);
procedure Normalize(K: single; Series: TChartSeries);
/// <summary>Scales the measured curve so that its maximum below SearchBelow
/// (every point when SearchBelow <= 0, or when no point lies below it) equals
/// the calculated curve at that angle. Factor is what the data were divided
/// by, AnchorX the angle of the maximum used.</summary>
procedure NormalizeAuto(Calc, Exp: TChartSeries; SearchBelow: Single;
  out Factor, AnchorX: Single);

function MovAvg(const Inp: TDataArray; W: single): TDataArray;
function Smooth(const Inp: TDataArray; W: ShortInt): TDataArray;

implementation

uses
  System.SysUtils;

function Smooth(const Inp: TDataArray; W: ShortInt): TDataArray;
var
  i, j, Max: word;
  s: single;
begin
  Max := Length(Inp) - 1;
  SetLength(Result, Max + 1);

  if W = -1 then
  begin
    W := Round(Max / 10);
    if W < 1 then W := 1;
  end;

  for I := 0 to Max - W do
  begin
    S := 0;
    for j := i to i + W do
      S := S + Inp[j].r;
    Result[i].t := Inp[i].t;
    Result[i].r := S/(W + 1);
  end;

  for I := Max - W + 1 to Max do
  begin
    S := 0;
    for j := i - W to i - 1 do
      S := S + Inp[j].r;
    Result[i].t := Inp[i].t;
    Result[i].r := S/W;
  end;
end;

function MovAvg(const Inp: TDataArray; W: single): TDataArray;
var
  i, j: integer;
  V: single;
  Offset, Window: integer;
begin
  SetLength(Result, Length(Inp));
  if W > 1 then
    Window := Trunc(W)
  else
    Window := Round(Length(Inp) * W);

  Offset := Window div 2;

  V := 0;
  for I := Window to High(Inp) do
  begin
    V := 0;
    for j := i - Window to i do
      V := V + Inp[j].r;

    V := V / (Window + 1);
    Result[i - offset].t := Inp[i - offset].t;
    Result[i - offset].r := V;
  end;

  for I := 0 to offset do
  begin
    Result[i].t := Inp[i].t;
    Result[i].r := Inp[i].r;
  end;

  for I := High(Inp) - Offset to High(Inp) do
  begin
    Result[i].t := Inp[i].t;
    Result[i].r := V;
  end;
end;

procedure Normalize(K: single; Series: TChartSeries);
var
  i: integer;
begin
  for I := 0 to Series.Count - 1 do
      Series.YValue[i] := Series.YValue[i] / K;
end;

{ The maximum is looked for below SearchBelow only, as the MCP server's
  "scale": "auto" does below auto_theta_max: on a misaligned specimen the
  first Bragg order can stand above a depressed plateau, and anchoring on it
  scales the whole curve by the wrong number without a word. }
procedure NormalizeAuto(Calc, Exp: TChartSeries; SearchBelow: Single;
  out Factor, AnchorX: Single);
var
  i, IMax: integer;
  Max, Min, AX: Double;   // the series hold Doubles: a Single angle misses its own point
begin
  IMax := -1;
  Max := 0;
  if SearchBelow > 0 then
    for i := 0 to Exp.Count - 1 do
      if (Exp.XValue[i] < SearchBelow) and ((IMax < 0) or (Exp.YValue[i] > Max)) then
      begin
        IMax := i;
        Max := Exp.YValue[i];
      end;
  if IMax < 0 then
  begin
    Max := Exp.YValues.MaxValue;
    IMax := Exp.YValues.Locate(Max);
  end;
  AX := Exp.XValue[IMax];
  AnchorX := AX;

  { the first calculated point at or above the data maximum's angle; none
    (the model stops short of it) or a zero there leaves the data as they are }
  i := 0;
  while (i < Calc.XValues.Count) and (Calc.XValues[i] < AX) do inc(i);
  if (i >= Calc.XValues.Count) or (Calc.YValues[i] <= 0) then
    raise Exception.CreateFmt('Normalize (Auto): the calculated curve does not reach %g, ' +
      'the angle of the measured maximum. Calculate the model over a range that covers it.', [AX]);

  Min := Calc.YValues[i];
  Factor := Max / Min;

  for I := 0 to Exp.Count - 1 do
    Exp.YValue[i] := Exp.YValue[i] / Factor;
end;

function GetDevider(D: single): single;
const
  DV : array [0..1] of single = (9.3, 73);  // known intensity jump dividers for auto-merge
var
  i : integer;
begin
  Result := 0;
  for I := 0 to 1 do
    if (D > DV[i] * 0.5) and (D < DV[i] * 1.5) then
    begin
      Result := DV[i];
      Break;
    end;
end;

procedure AutoMerge(Series: TChartSeries);
var
  i, Pos: integer;
  Max: single;
begin
  Max := 0; Pos := 0;

  for I := 0 to Series.Count - 2 do
  begin
    Max := Series.YValue[i + 1] / Series.YValue[i];
    if Max > 8 then
    begin
      Pos := i + 1;
      Max := GetDevider(Max);
      Break;
    end;
  end;

  for I := Pos to Series.Count - 1 do
    Series.YValue[i] := Series.YValue[i] / Max;
end;

procedure ManualMerge( X, K: single; Series: TChartSeries);
var
  i, pos: integer;
begin
  Pos := Series.XValues.Locate(X);
  for I := Pos to Series.Count - 1 do
    Series.YValue[i] := Series.YValue[i] / K;
end;

end.
