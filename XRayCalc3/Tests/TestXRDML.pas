unit TestXRDML;

{ unit_xrdml: the PANalytical XRDML reader shared by the GUI's Load Data and
  XRC_MCP's inbox. The fixtures are the two spellings the schema versions use
  for the same things (counts / intensities, start-end / listPositions,
  commonCountingTime / countingTimes), a namespace-prefixed document, a rocking
  curve without a 2Theta axis, and, when the file is present on this machine,
  a real Empyrean 1.6 export from the exp-03 raw folder. }

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.IOUtils,
  unit_Types, unit_xrdml;

type
  [TestFixture]
  TTestXRDML = class
  public
    [Test] procedure Read16_IntensitiesStartEnd_CommonTime;
    [Test] procedure Read10_CountsListPositions_PerPointTimes_Attenuation;
    [Test] procedure Read_Intensities_IgnoreAttenuationFactors;
    [Test] procedure Read_PrefixedNamespace;
    [Test] procedure Read_OmegaOnly_IsRockingCurve;
    [Test] procedure Read_NoCountingTime_LeavesRawCounts;
    [Test] procedure Read_NoDataPoints_Raises;
    [Test] procedure Read_ListPositionsCountMismatch_Raises;
    [Test] procedure Read_NotXRDML_Raises;
    [Test] procedure Read_MalformedXML_Raises;
    [Test] procedure DescriptionLines_StartWithStar;
    [Test] procedure IsXRDMLFile_ByExtension;
    [Test] procedure FloorNonPositive_UsesTheRunningMinimum;
    [Test] procedure Read_RealEmpyreanFile_WhenPresent;
  end;

const
  { the shape of a 2026 Empyrean export: schema 1.6, "intensities", start/end,
    common counting time, a moving Omega axis beside 2Theta }
  XRDML_16 =
    '<?xml version="1.0" encoding="UTF-8"?>' +
    '<xrdMeasurements xmlns="http://www.xrdml.com/XRDMeasurement/1.6" status="Aborted">' +
    '<sample type="To be analyzed"><id>C(260917B)-XRR</id><name></name></sample>' +
    '<xrdMeasurement measurementType="Scan" status="Aborted" sampleMode="Reflection">' +
    '<usedWavelength intended="K-Alpha"><kAlpha1 unit="Angstrom">1.5405980</kAlpha1>' +
    '<kAlpha2 unit="Angstrom">1.5444260</kAlpha2></usedWavelength>' +
    '<incidentBeamPath><xRayTube id="1" name="Cu LFF"><tension unit="kV">40.0</tension>' +
    '<anodeMaterial>Cu</anodeMaterial></xRayTube></incidentBeamPath>' +
    '<scan appendNumber="0" mode="Continuous" scanAxis="2Theta-Omega" status="Aborted">' +
    '<header><startTimeStamp>2026-09-17T10:11:12+08:00</startTimeStamp></header>' +
    '<dataPoints>' +
    '<positions axis="2Theta" unit="deg"><startPosition>0.1</startPosition><endPosition>0.5</endPosition></positions>' +
    '<positions axis="Omega" unit="deg"><startPosition>0.05</startPosition><endPosition>0.25</endPosition></positions>' +
    '<positions axis="Phi" unit="deg"><commonPosition>0.00</commonPosition></positions>' +
    '<commonCountingTime unit="seconds">0.5</commonCountingTime>' +
    '<intensities unit="counts">100 200 300 400 500</intensities>' +
    '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';

  { the old spelling: "counts" with attenuation factors, explicit positions,
    per-point counting times, a version attribute and no namespace }
  XRDML_10 =
    '<?xml version="1.0"?>' +
    '<xrdMeasurements version="1.0" status="Completed">' +
    '<xrdMeasurement measurementType="Scan">' +
    '<usedWavelength><kAlpha1 unit="Angstrom">1.540598</kAlpha1></usedWavelength>' +
    '<scan mode="Pre-set time" scanAxis="2Theta-Omega" status="Completed">' +
    '<dataPoints>' +
    '<positions axis="2Theta" unit="deg"><listPositions>1.0 1.5 2.5</listPositions></positions>' +
    '<countingTimes unit="seconds">1 2 4</countingTimes>' +
    '<beamAttenuationFactors>1 1 100</beamAttenuationFactors>' +
    '<counts unit="counts">10 20 30</counts>' +
    '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';

  XRDML_INTENSITIES_WITH_FACTORS =
    '<xrdMeasurements xmlns="http://www.xrdml.com/XRDMeasurement/1.5">' +
    '<xrdMeasurement><scan scanAxis="2Theta-Omega"><dataPoints>' +
    '<positions axis="2Theta" unit="deg"><startPosition>1</startPosition><endPosition>2</endPosition></positions>' +
    '<commonCountingTime unit="seconds">2</commonCountingTime>' +
    '<beamAttenuationFactors>100 100</beamAttenuationFactors>' +
    '<intensities unit="counts">10 20</intensities>' +
    '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';

  XRDML_PREFIXED =
    '<x:xrdMeasurements xmlns:x="http://www.xrdml.com/XRDMeasurement/1.3">' +
    '<x:xrdMeasurement><x:scan scanAxis="2Theta"><x:dataPoints>' +
    '<x:positions axis="2Theta" unit="deg"><x:startPosition>10</x:startPosition><x:endPosition>12</x:endPosition></x:positions>' +
    '<x:commonCountingTime unit="seconds">1</x:commonCountingTime>' +
    '<x:counts unit="counts">1 2 3</x:counts>' +
    '</x:dataPoints></x:scan></x:xrdMeasurement></x:xrdMeasurements>';

  XRDML_OMEGA =
    '<xrdMeasurements xmlns="http://www.xrdml.com/XRDMeasurement/1.6">' +
    '<xrdMeasurement><scan scanAxis="Omega"><dataPoints>' +
    '<positions axis="2Theta" unit="deg"><commonPosition>1.0</commonPosition></positions>' +
    '<positions axis="Omega" unit="deg"><startPosition>0.4</startPosition><endPosition>0.6</endPosition></positions>' +
    '<commonCountingTime unit="seconds">1</commonCountingTime>' +
    '<counts unit="counts">5 6 7</counts>' +
    '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';

  XRDML_NO_TIME =
    '<xrdMeasurements xmlns="http://www.xrdml.com/XRDMeasurement/1.6">' +
    '<xrdMeasurement><scan scanAxis="2Theta-Omega"><dataPoints>' +
    '<positions axis="2Theta" unit="deg"><startPosition>1</startPosition><endPosition>2</endPosition></positions>' +
    '<counts unit="counts">7 9</counts>' +
    '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';

  XRDML_NO_DATA =
    '<xrdMeasurements xmlns="http://www.xrdml.com/XRDMeasurement/1.6">' +
    '<xrdMeasurement><scan scanAxis="2Theta-Omega"><header/></scan></xrdMeasurement></xrdMeasurements>';

  XRDML_BAD_LIST =
    '<xrdMeasurements xmlns="http://www.xrdml.com/XRDMeasurement/1.6">' +
    '<xrdMeasurement><scan scanAxis="2Theta-Omega"><dataPoints>' +
    '<positions axis="2Theta" unit="deg"><listPositions>1 2</listPositions></positions>' +
    '<commonCountingTime unit="seconds">1</commonCountingTime>' +
    '<counts unit="counts">1 2 3</counts>' +
    '</dataPoints></scan></xrdMeasurement></xrdMeasurements>';

  REAL_FILE = 'D:\MultilayerLab\Papers\LLM-XRay-Optics-Lab\experiments\runs\exp-03\raw\XRR 1_C(260917B)-XRR.xrdml';

implementation

procedure TTestXRDML.Read16_IntensitiesStartEnd_CommonTime;
var
  S: TXRDMLScan;
begin
  S := ReadXRDMLText(XRDML_16);
  Assert.AreEqual(5, Length(S.Curve));
  Assert.AreEqual(5, S.Points);
  Assert.AreEqual('2Theta', S.XAxis);
  Assert.AreEqual(0.1, S.Curve[0].t, 1e-6);
  Assert.AreEqual(0.2, S.Curve[1].t, 1e-6);
  Assert.AreEqual(0.5, S.Curve[4].t, 1e-6);
  Assert.AreEqual(0.2, S.Curve[0].r, 1e-6, '(100 / 0.5 s) / peak');
  Assert.AreEqual(1.0, S.Curve[4].r, 1e-6, 'the maximum is 1');
  Assert.AreEqual(1000.0, S.PeakRate, 1e-6, 'the peak in counts / s');
  Assert.AreEqual(1.540598, S.Lambda, 1e-9);
  Assert.AreEqual('Cu', S.Anode);
  Assert.AreEqual('C(260917B)-XRR', S.SampleId);
  Assert.AreEqual('1.6', S.SchemaVersion, 'from the namespace');
  Assert.AreEqual('Aborted', S.Status);
  Assert.AreEqual('2Theta-Omega', S.ScanAxis);
  Assert.AreEqual('Continuous', S.ScanMode);
  Assert.AreEqual('2026-09-17T10:11:12+08:00', S.StartTime);
  Assert.AreEqual(0.5, S.CountingTime, 1e-9);
  Assert.IsTrue(S.Corrected, '"intensities" are already corrected');
  Assert.IsFalse(S.AttenuationApplied);
end;

procedure TTestXRDML.Read10_CountsListPositions_PerPointTimes_Attenuation;
var
  S: TXRDMLScan;
begin
  S := ReadXRDMLText(XRDML_10);
  Assert.AreEqual(3, Length(S.Curve));
  Assert.AreEqual('1.0', S.SchemaVersion, 'from the version attribute');
  Assert.AreEqual(1.0, S.Curve[0].t, 1e-6);
  Assert.AreEqual(1.5, S.Curve[1].t, 1e-6);
  Assert.AreEqual(2.5, S.Curve[2].t, 1e-6);
  Assert.AreEqual(750.0, S.PeakRate, 1e-6, '30 x 100 / 4 s');
  Assert.AreEqual(10 / 750, S.Curve[0].r, 1e-6, '10 x 1 / 1 s, over the peak');
  Assert.AreEqual(10 / 750, S.Curve[1].r, 1e-6, '20 x 1 / 2 s, over the peak');
  Assert.AreEqual(1.0, S.Curve[2].r, 1e-6);
  Assert.AreEqual(0.0, S.CountingTime, 0, 'per-point times');
  Assert.IsFalse(S.Corrected);
  Assert.IsTrue(S.AttenuationApplied);
  Assert.AreEqual('Completed', S.Status);
end;

procedure TTestXRDML.Read_Intensities_IgnoreAttenuationFactors;
var
  S: TXRDMLScan;
begin
  // "intensities" are corrected already: the factors must not be applied twice
  S := ReadXRDMLText(XRDML_INTENSITIES_WITH_FACTORS);
  Assert.AreEqual(10.0, S.PeakRate, 1e-6, '20 / 2 s, no factor');
  Assert.AreEqual(0.5, S.Curve[0].r, 1e-6);
  Assert.AreEqual(1.0, S.Curve[1].r, 1e-6);
  Assert.IsFalse(S.AttenuationApplied);
  Assert.AreEqual('1.5', S.SchemaVersion);
end;

procedure TTestXRDML.Read_PrefixedNamespace;
var
  S: TXRDMLScan;
begin
  S := ReadXRDMLText(XRDML_PREFIXED);
  Assert.AreEqual(3, Length(S.Curve));
  Assert.AreEqual(10.0, S.Curve[0].t, 1e-6);
  Assert.AreEqual(11.0, S.Curve[1].t, 1e-6);
  Assert.AreEqual(12.0, S.Curve[2].t, 1e-6);
  Assert.AreEqual(1.0, S.Curve[2].r, 1e-6);
  Assert.AreEqual(1 / 3, S.Curve[0].r, 1e-6);
  Assert.AreEqual('1.3', S.SchemaVersion);
end;

procedure TTestXRDML.Read_OmegaOnly_IsRockingCurve;
var
  S: TXRDMLScan;
begin
  S := ReadXRDMLText(XRDML_OMEGA);
  Assert.AreEqual('Omega', S.XAxis, 'the fixed 2Theta axis is not the abscissa');
  Assert.AreEqual(0.4, S.Curve[0].t, 1e-6);
  Assert.AreEqual(0.6, S.Curve[2].t, 1e-6);
end;

procedure TTestXRDML.Read_NoCountingTime_LeavesRawCounts;
var
  S: TXRDMLScan;
begin
  S := ReadXRDMLText(XRDML_NO_TIME);
  Assert.AreEqual(9.0, S.PeakRate, 1e-6, 'raw counts, no time to divide by');
  Assert.AreEqual(7 / 9, S.Curve[0].r, 1e-6);
  Assert.AreEqual(1.0, S.Curve[1].r, 1e-6);
  Assert.AreEqual(0.0, S.CountingTime, 0);
end;

procedure TTestXRDML.Read_NoDataPoints_Raises;
begin
  Assert.WillRaise(procedure begin ReadXRDMLText(XRDML_NO_DATA); end, EXRDMLError);
end;

procedure TTestXRDML.Read_ListPositionsCountMismatch_Raises;
var
  Msg: string;
begin
  Msg := '';
  try
    ReadXRDMLText(XRDML_BAD_LIST);
  except
    on E: EXRDMLError do
      Msg := E.Message;
  end;
  Assert.IsTrue(Pos('listPositions', Msg) > 0, 'the message names the element: ' + Msg);
end;

procedure TTestXRDML.Read_NotXRDML_Raises;
begin
  Assert.WillRaise(procedure begin ReadXRDMLText('<root><a>1</a></root>'); end, EXRDMLError);
end;

procedure TTestXRDML.Read_MalformedXML_Raises;
begin
  Assert.WillRaise(procedure begin ReadXRDMLText('<xrdMeasurements><unclosed>'); end, EXRDMLError);
end;

procedure TTestXRDML.DescriptionLines_StartWithStar;
var
  S: TXRDMLScan;
  L: string;
  Lines: TArray<string>;
begin
  S := ReadXRDMLText(XRDML_16);
  Lines := S.DescriptionLines;
  Assert.IsTrue(Length(Lines) >= 4);
  for L in Lines do
    Assert.IsTrue((L <> '') and (L[1] = '*'), 'a header line starts with *: ' + L);
  Assert.IsTrue(Pos('1.540598', string.Join(#10, Lines)) > 0, 'the wavelength is in the header');
  Assert.IsTrue(Pos('2Theta', string.Join(#10, Lines)) > 0, 'the angle axis is in the header');
  Assert.IsTrue(Pos('normalised to 1', string.Join(#10, Lines)) > 0, 'the normalisation is in the header');
end;

procedure TTestXRDML.IsXRDMLFile_ByExtension;
begin
  Assert.IsTrue(IsXRDMLFile('C:\data\XRR 1_C(260917B)-XRR.xrdml'));
  Assert.IsTrue(IsXRDMLFile('a.XRDML'));
  Assert.IsFalse(IsXRDMLFile('a.xrdml.dat'));
  Assert.IsFalse(IsXRDMLFile('a.dat'));
end;

procedure TTestXRDML.FloorNonPositive_UsesTheRunningMinimum;
var
  C: TDataArray;
begin
  { the same rule as unit_SeriesIO and ParseCurveText: a zero becomes the
    smallest positive value seen so far, 1000 when nothing positive came first }
  SetLength(C, 5);
  C[0].r := 0;    C[1].r := 20;  C[2].r := 5;  C[3].r := 0;  C[4].r := -1;
  FloorNonPositive(C);
  Assert.AreEqual(1000.0, C[0].r, 1e-6, 'nothing positive seen yet: the seed');
  Assert.AreEqual(20.0, C[1].r, 1e-6);
  Assert.AreEqual(5.0, C[2].r, 1e-6);
  Assert.AreEqual(5.0, C[3].r, 1e-6, 'the running minimum');
  Assert.AreEqual(5.0, C[4].r, 1e-6, 'a negative is floored too');
end;

procedure TTestXRDML.Read_RealEmpyreanFile_WhenPresent;
var
  S: TXRDMLScan;
begin
  if not TFile.Exists(REAL_FILE) then
  begin
    Assert.IsTrue(True, 'the exp-03 raw file is not on this machine; skipped');
    Exit;
  end;
  S := ReadXRDMLFile(REAL_FILE);
  Assert.AreEqual('2Theta', S.XAxis);
  Assert.IsTrue(S.Points > 1000, 'a full XRR scan');
  Assert.AreEqual(S.Points, Length(S.Curve));
  Assert.AreEqual(0.0955, S.Curve[0].t, 1e-5);
  Assert.AreEqual(8.7655, S.Curve[High(S.Curve)].t, 1e-4);
  Assert.AreEqual(927993 / 0.176, S.PeakRate, 1.0, 'the plateau maximum in counts per second');
  Assert.AreEqual(338638 / 927993, S.Curve[0].r, 1e-5, 'the first point over the peak');
  Assert.IsTrue(S.Curve[High(S.Curve)].r > 0, 'the tail zero is floored');
  Assert.AreEqual(1.540598, S.Lambda, 1e-6);
  Assert.AreEqual('C(260917B)-XRR', S.SampleId);
  Assert.AreEqual('1.6', S.SchemaVersion);
  Assert.AreEqual('Aborted', S.Status);
  Assert.IsTrue(S.Corrected);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXRDML);
end.
