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

unit TestUncertCounts;

(* The raw counts of a curve, read again from the .xrdml its data node names. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUncertCounts = class
  private
    FDir: string;
    function Save(const Name, Text: string): string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure MatchingFile_GivesItsCounts;
    [Test] procedure MissingFile_NoneAndWhy;
    [Test] procedure TrimmedCurve_NoneAndWhy;
    [Test] procedure IntensitiesFile_NoneAndWhy;
    [Test] procedure NoSourceLine_NoneAndWhy;
    [Test] procedure TwoThetaProject_MatchesIn2Theta;
    [Test] procedure SourceFileOf_FindsTheLine;
    [Test] procedure CountsText_RoundTrip;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, unit_Types, unit_xrdml, unit_UncertCounts;

const
  HEAD =
    '<?xml version="1.0"?><xrdMeasurements version="1.0" status="Completed">' +
    '<xrdMeasurement measurementType="Scan">' +
    '<usedWavelength><kAlpha1 unit="Angstrom">1.540598</kAlpha1></usedWavelength>' +
    '<scan mode="Pre-set time" scanAxis="2Theta-Omega" status="Completed"><dataPoints>' +
    '<positions axis="2Theta" unit="deg"><listPositions>1.0 1.5 2.5 3.0</listPositions></positions>' +
    '<commonCountingTime unit="seconds">1</commonCountingTime>';
  TAIL = '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';
  WITH_COUNTS = HEAD + '<counts unit="counts">1000 200 30 4</counts>' + TAIL;
  WITH_INTENSITIES = HEAD + '<intensities unit="counts">1000 200 30 4</intensities>' + TAIL;

procedure TTestUncertCounts.Setup;
begin
  FDir := TPath.Combine(TPath.GetTempPath, 'xrcuncert_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FDir);
end;

procedure TTestUncertCounts.TearDown;
begin
  TDirectory.Delete(FDir, True);
end;

function TTestUncertCounts.Save(const Name, Text: string): string;
begin
  Result := TPath.Combine(FDir, Name);
  TFile.WriteAllText(Result, Text, TEncoding.UTF8);
end;

{ The curve as the project holds it: theta, as Load Data brings the scan. }
function CurveOf(const Text: string): TDataArray;
begin
  Result := ScanCurveInChartUnit(ReadXRDMLText(Text), False);
end;

procedure TTestUncertCounts.MatchingFile_GivesItsCounts;
var
  Counts: TArray<Double>;
  Why: string;
begin
  Counts := CountsFromSource(Save('a.xrdml', WITH_COUNTS), CurveOf(WITH_COUNTS), False, Why);
  Assert.AreEqual(4, Length(Counts), Why);
  Assert.AreEqual(1000.0, Counts[0], 0.0);
  Assert.AreEqual(4.0, Counts[3], 0.0);
  Assert.AreEqual('', Why);
end;

procedure TTestUncertCounts.MissingFile_NoneAndWhy;
var
  Why: string;
begin
  Assert.AreEqual(0, Length(CountsFromSource(TPath.Combine(FDir, 'gone.xrdml'), CurveOf(WITH_COUNTS), False, Why)));
  Assert.Contains(Why, 'was not found');
  Assert.Contains(Why, 'gone.xrdml');
end;

procedure TTestUncertCounts.TrimmedCurve_NoneAndWhy;
var
  Curve: TDataArray;
  Why: string;
begin
  Curve := CurveOf(WITH_COUNTS);
  Delete(Curve, 0, 1);                                     // trimmed in the main app
  Assert.AreEqual(0, Length(CountsFromSource(Save('a.xrdml', WITH_COUNTS), Curve, False, Why)));
  Assert.Contains(Why, 'no longer matches');
end;

procedure TTestUncertCounts.IntensitiesFile_NoneAndWhy;
var
  Why: string;
begin
  Assert.AreEqual(0, Length(CountsFromSource(Save('i.xrdml', WITH_INTENSITIES),
    CurveOf(WITH_INTENSITIES), False, Why)));
  Assert.Contains(Why, 'no raw counts');
end;

procedure TTestUncertCounts.NoSourceLine_NoneAndWhy;
var
  Why: string;
begin
  Assert.AreEqual(0, Length(CountsFromSource('', CurveOf(WITH_COUNTS), False, Why)));
  Assert.Contains(Why, 'does not name');
end;

procedure TTestUncertCounts.TwoThetaProject_MatchesIn2Theta;
var
  Why: string;
  Curve: TDataArray;
begin
  Curve := ScanCurveInChartUnit(ReadXRDMLText(WITH_COUNTS), True);
  Assert.AreEqual(4, Length(CountsFromSource(Save('a.xrdml', WITH_COUNTS), Curve, True, Why)), Why);
  Assert.AreEqual(0, Length(CountsFromSource(Save('a.xrdml', WITH_COUNTS), Curve, False, Why)),
    'a 2theta curve is not the theta scan');
end;

procedure TTestUncertCounts.SourceFileOf_FindsTheLine;
begin
  Assert.AreEqual('D:\data\XRR 1.xrdml',
    SourceFileOf('* Sample: A'#13#10'* Source file: D:\data\XRR 1.xrdml'#13#10'* Anode: Cu'));
  Assert.AreEqual('', SourceFileOf('* Sample: A'));
  Assert.AreEqual('', SourceFileOf(''));
end;

procedure TTestUncertCounts.CountsText_RoundTrip;
var
  C: TArray<Double>;
begin
  C := CountsFromText(CountsToText([1000, 0, 3.5, 12345678]));
  Assert.AreEqual(4, Length(C));
  Assert.AreEqual(1000.0, C[0], 0.0);
  Assert.AreEqual(0.0, C[1], 0.0);
  Assert.AreEqual(3.5, C[2], 0.0);
  Assert.AreEqual(12345678.0, C[3], 0.0);
  Assert.AreEqual(0, Length(CountsFromText('')));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertCounts);

end.
