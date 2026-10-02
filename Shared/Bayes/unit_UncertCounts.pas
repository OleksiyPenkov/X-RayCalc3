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

/// <summary>The counts for Curve (theta, as the project stores it), one per
/// point, or nil with Why saying why there are none.</summary>
function CountsFromSource(const SourceFile: string; const Curve: TDataArray;
  out Why: string): TArray<Double>;
/// <summary>The path on the '* Source file: ' line of a data node's
/// description; '' when there is no such line.</summary>
function SourceFileOf(const Description: string): string;
/// <summary>One count per line, invariant format: the counts_&lt;id&gt;.dat entry.</summary>
function CountsToText(const Counts: TArray<Double>): string;
function CountsFromText(const Text: string): TArray<Double>;

implementation

uses
  System.SysUtils, System.Classes, unit_xrdml;

const
  SOURCE_TAG = '* Source file: ';

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
  out Why: string): TArray<Double>;
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
  C := ScanCurveInChartUnit(Scan, False);
  if not SameScanAngles(C, Curve) or not SameScanIntensities(C, Curve, Scan.Counts) then
  begin
    Why := 'The curve no longer matches its measurement file (it was trimmed, smoothed or edited).';
    Exit;
  end;
  Result := Copy(Scan.Counts);
end;

function CountsToText(const Counts: TArray<Double>): string;
var
  SB: TStringBuilder;
  i: Integer;
begin
  SB := TStringBuilder.Create;
  try
    for i := 0 to High(Counts) do
      SB.Append(FloatToStrF(Counts[i], ffGeneral, 17, 0, TFormatSettings.Invariant)).Append(#10);
    Result := SB.ToString;
  finally
    SB.Free;
  end;
end;

function CountsFromText(const Text: string): TArray<Double>;
var
  L: string;
  V: Double;
begin
  Result := nil;
  for L in Text.Split([#13#10, #10]) do
    if TryStrToFloat(L.Trim, V, TFormatSettings.Invariant) then
      Result := Result + [V];
end;

end.
