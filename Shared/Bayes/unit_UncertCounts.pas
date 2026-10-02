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

unit unit_UncertCounts;

(* The raw detector counts behind a measured curve. A project keeps the curve
   normalised; the counts are read again from the .xrdml the data node names
   ('* Source file: ', written by Load Data) and kept only when that file is
   still the curve: the same angles, the same intensities up to one factor.
   A trimmed or smoothed curve has no counts - attaching them to other points
   would weigh the wrong data. Every "no" comes with a plain sentence. *)

interface

uses
  unit_Types;

/// <summary>The counts for Curve, one per point, or nil with Why saying why
/// there are none. TwoTheta: the project keeps its curves in 2theta
/// (TXRCXProject.TwoTheta).</summary>
function CountsFromSource(const SourceFile: string; const Curve: TDataArray;
  TwoTheta: Boolean; out Why: string): TArray<Double>;
/// <summary>The path on the '* Source file: ' line of a data node's
/// description; '' when there is no such line.</summary>
function SourceFileOf(const Description: string): string;
/// <summary>The counts_&lt;id&gt;.dat entry: a first line naming the curve the
/// counts belong to (a hash of its points), then one count per line,
/// invariant format.</summary>
function CountsToText(const Counts: TArray<Double>; const Curve: TDataArray): string;
/// <summary>The counts of the entry when it was written for exactly this
/// Curve; nil, with Why, for any other curve or a damaged entry. The main
/// program keeps the entry when the curve is trimmed or smoothed.</summary>
function CountsFromText(const Text: string; const Curve: TDataArray; out Why: string): TArray<Double>;

implementation

uses
  System.SysUtils, System.Classes, System.Hash, unit_xrdml;

const
  SOURCE_TAG = '* Source file: ';
  CURVE_TAG = '# curve ';

{ What the counts belong to: the curve's points, as the project stores them. }
function CurveHash(const Curve: TDataArray): string;
var
  SB: TStringBuilder;
  i: Integer;
begin
  SB := TStringBuilder.Create;
  try
    for i := 0 to High(Curve) do
      SB.Append(FloatToStrF(Curve[i].t, ffGeneral, 9, 0, TFormatSettings.Invariant)).Append(':')
        .Append(FloatToStrF(Curve[i].r, ffGeneral, 9, 0, TFormatSettings.Invariant)).Append(' ');
    Result := THashSHA2.GetHashString(SB.ToString);
  finally
    SB.Free;
  end;
end;

function SourceFileOf(const Description: string): string;
var
  L: string;
begin
  Result := '';
  for L in Description.Split([#13#10, #10]) do
    if L.StartsWith(SOURCE_TAG) then
      Result := L.Substring(Length(SOURCE_TAG)).Trim;
end;

function CountsFromSource(const SourceFile: string; const Curve: TDataArray;
  TwoTheta: Boolean; out Why: string): TArray<Double>;
var
  Scan: TXRDMLScan;
  C: TDataArray;
begin
  Result := nil;
  Why := '';
  if SourceFile = '' then
  begin
    Why := 'The curve does not name the measurement file it came from.';
    Exit;
  end;
  if not FileExists(SourceFile) then
  begin
    Why := Format('The measurement file %s was not found.', [SourceFile]);
    Exit;
  end;
  if not IsXRDMLFile(SourceFile) then
  begin
    Why := 'Raw counts can only be read from an .xrdml measurement file.';
    Exit;
  end;
  try
    Scan := ReadXRDMLFile(SourceFile);
  except
    on E: Exception do
    begin
      Why := 'The measurement file could not be read: ' + E.Message;
      Exit;
    end;
  end;
  if Length(Scan.Counts) = 0 then
  begin
    Why := 'The measurement file holds no raw counts (its intensities are already corrected).';
    Exit;
  end;
  C := ScanCurveInChartUnit(Scan, TwoTheta);
  if not SameScanAngles(C, Curve) or not SameScanIntensities(C, Curve, Scan.Counts) then
  begin
    Why := 'The curve no longer matches its measurement file (it was trimmed, smoothed or edited).';
    Exit;
  end;
  Result := Copy(Scan.Counts);
end;

function CountsToText(const Counts: TArray<Double>; const Curve: TDataArray): string;
var
  SB: TStringBuilder;
  i: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append(CURVE_TAG).Append(CurveHash(Curve)).Append(#10);
    for i := 0 to High(Counts) do
      SB.Append(FloatToStrF(Counts[i], ffGeneral, 17, 0, TFormatSettings.Invariant)).Append(#10);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function CountsFromText(const Text: string; const Curve: TDataArray; out Why: string): TArray<Double>;
var
  L: string;
  V: Double;
  First: Boolean;
begin
  Result := nil;
  Why := '';
  First := True;
  for L in Text.Split([#13#10, #10]) do
  begin
    if First then
    begin
      First := False;
      if L <> CURVE_TAG + CurveHash(Curve) then
      begin
        Why := 'The stored counts belong to another curve: this one was trimmed, smoothed or replaced since.';
        Exit;
      end;
      Continue;
    end;
    if L.Trim = '' then
      Continue;
    if not TryStrToFloat(L.Trim, V, TFormatSettings.Invariant) then
    begin
      { one bad line would shift every count after it onto the wrong point }
      Why := 'The stored counts are damaged.';
      Exit(nil);
    end;
    Result := Result + [V];
  end;
  if Length(Result) <> Length(Curve) then
  begin
    Why := 'The stored counts belong to another curve: this one was trimmed, smoothed or replaced since.';
    Result := nil;
  end;
end;

end.
