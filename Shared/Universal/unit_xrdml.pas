(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3.
  *
  *   X-Ray Calc 3 is free software: you can redistribute it and/or modify it
  *   under the terms of the GNU General Public License as published by the
  *   Free Software Foundation, either version 3 of the License, or (at your
  *   option) any later version.
  *
  *   X-Ray Calc 3 is distributed in the hope that it will be useful, but
  *   WITHOUT ANY WARRANTY; without even the implied warranty of
  *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU General
  *   Public License for more details: LICENSE in the repository root, or
  *   https://www.gnu.org/licenses/gpl-3.0.html
  *
  ****************************************************************************** *)

/// <summary>
///   Reads a PANalytical / Malvern XRDML file (schema 1.0 to 2.x) into one
///   measured curve. No VCL: the GUI's project panel and XRC_MCP's inbox share
///   it. The file's own facts come with the curve, so a caller need not guess
///   the angle axis or the wavelength.
///
///   What differs between schema versions, and how it is handled:
///   - Intensities are in a "counts" element (raw detector counts; a sibling
///     "beamAttenuationFactors" list, when present, is multiplied in) or in an
///     "intensities" element (already corrected; the factors are not applied
///     again). Both spellings occur in current 1.6 files.
///   - Positions of the scanned axis are "startPosition"/"endPosition"
///     (equidistant), or an explicit "listPositions", or a single
///     "commonPosition" (a fixed axis, never the curve's abscissa).
///   - Counting time is "commonCountingTime" or a per-point "countingTimes"
///     list. Intensity is counts per second, then normalised to 1 at the
///     maximum (PeakRate keeps the counts per second that 1 stands for); a
///     zero count is floored the way the text importers floor it.
///   - The wavelength: a file measured with the K-Alpha doublet through an
///     optic that passes both lines (no monochromator, mirror not hybrid)
///     implies the ratio-weighted pair, (kAlpha1 + r kAlpha2) / (1 + r), not
///     kAlpha1: with r = 0.5 that is 1.541874 A for Cu, and a period fitted at
///     1.540598 would be 0.08 % short. Lambda is that value when the file says
///     "K-Alpha" and gives the ratio, kAlpha1 otherwise, and LambdaRule says
///     which. The caller may still prefer its own wavelength.
///   - The abscissa is the "2Theta" positions element wherever it appears among
///     the positions; a scan without one (a rocking curve) uses "Omega" and
///     says so in XAxis.
///   - Elements are matched by local name, so a file whose elements carry a
///     namespace prefix reads the same as one with a default namespace.
///   External entities are never resolved (a crafted file cannot read local
///   files through the parser).
/// </summary>
unit unit_xrdml;

interface

uses
  System.SysUtils, unit_Types;

type
  EXRDMLError = class(Exception);

  TXRDMLScan = record
    Curve: TDataArray;         // t = angle on XAxis (deg), r = intensity normalised to 1 at the maximum
    PeakRate: Double;          // counts per second at the maximum, the value r = 1 stands for
    XAxis: string;             // '2Theta' or 'Omega'
    ScanAxis: string;          // the scan element's scanAxis: '2Theta-Omega', 'Omega', ...
    ScanMode: string;          // 'Continuous', 'Pre-set time', ...
    Status: string;            // 'Completed', 'Aborted', '' when the file does not say
    SampleId: string;
    Lambda: Double;            // the wavelength the file implies, Angstrom; 0 when it has none
    LambdaRule: string;        // how Lambda was chosen, for the header and the caller
    KAlpha1, KAlpha2: Double;  // as written; 0 when absent
    Ratio: Double;             // ratioKAlpha2KAlpha1; 0 when absent
    Intended: string;          // usedWavelength@intended: 'K-Alpha', 'K-Alpha1', ...
    Monochromatic: Boolean;    // a monochromator or a hybrid mirror in the incident path
    Anode: string;
    Detector: string;          // diffractedBeamPath/detector@name
    ReadOutPeriod: Double;     // the detector's readOutPeriod in s; 0 when absent
    ZerosFloored: Integer;     // points with a non-positive count, floored
    FirstNonPositive: Integer; // index in Curve of the first of them; -1 when there is none
    PeakCounts: Double;        // the value written in the file at the maximum: raw counts (x attenuation factor)
    IntensityUnit: string;     // the counts/intensities element's unit attribute, '' when absent
    CountingTime: Double;      // the common counting time in s; 0 when per-point
    StartTime: string;         // the scan header's startTimeStamp, as written
    SchemaVersion: string;     // '1.6' from the namespace, or the root's version attribute
    Corrected: Boolean;        // True: the file held "intensities", i.e. already corrected
    AttenuationApplied: Boolean;
    Points: Integer;
    /// <summary>Header lines for a data node or a measurement, each starting
    /// with '*' the way counter-file headers do.</summary>
    function DescriptionLines: TArray<string>;
  end;

/// <summary>True for a ".xrdml" extension, case-insensitively.</summary>
function IsXRDMLFile(const FileName: string): Boolean;

/// <summary>Reads the first scan of the file. Raises EXRDMLError with a message
/// naming the missing or malformed element.</summary>
function ReadXRDMLFile(const FileName: string): TXRDMLScan;

/// <summary>The same for a document held in a string (tests, clipboard).</summary>
function ReadXRDMLText(const Text: string): TXRDMLScan;

/// <summary>A count of zero is a real reading at the tail of an XRR scan, but a
/// log-scale chart and a log-residual fit cannot take it. This applies the rule
/// the text importers already use (unit_SeriesIO, XRC_MCP's ParseCurveText): a
/// non-positive intensity becomes the smallest positive one seen before it,
/// with 1000 as the seed when none has been seen yet.</summary>
procedure FloorNonPositive(var Curve: TDataArray);

implementation

uses
  System.Classes, System.Math, System.StrUtils, System.Variants,
  Winapi.ActiveX, Xml.XMLDoc, Xml.XMLIntf, Xml.xmldom;

const
  XRDML_EXT = '.xrdml';

{ ------------------------------------------------------------------ helpers -- }

function IsXRDMLFile(const FileName: string): Boolean;
begin
  Result := SameText(ExtractFileExt(FileName), XRDML_EXT);
end;

/// The first child whose local name is Name, whatever its prefix; nil when
/// there is none. ChildNodes.FindNode matches the qualified name only.
function Child(const Parent: IXMLNode; const Name: string): IXMLNode;
var
  I: Integer;
  N: IXMLNode;
begin
  Result := nil;
  if Parent = nil then
    Exit;
  for I := 0 to Parent.ChildNodes.Count - 1 do
  begin
    N := Parent.ChildNodes[I];
    if (N.NodeType = ntElement) and (N.LocalName = Name) then
      Exit(N);
  end;
end;

function ChildText(const Parent: IXMLNode; const Name: string): string;
var
  N: IXMLNode;
begin
  Result := '';
  N := Child(Parent, Name);
  if (N <> nil) and not VarIsNull(N.NodeValue) then
    Result := Trim(VarToStr(N.NodeValue));
end;

function Attr(const N: IXMLNode; const Name: string): string;
begin
  Result := '';
  if (N <> nil) and N.HasAttribute(Name) then
    Result := Trim(VarToStr(N.Attributes[Name]));
end;

/// The 'positions' child whose axis attribute is Axis; nil when there is none.
function PositionsOf(const DataPoints: IXMLNode; const Axis: string): IXMLNode;
var
  I: Integer;
  N: IXMLNode;
begin
  Result := nil;
  for I := 0 to DataPoints.ChildNodes.Count - 1 do
  begin
    N := DataPoints.ChildNodes[I];
    if (N.NodeType = ntElement) and (N.LocalName = 'positions') and
       SameText(Attr(N, 'axis'), Axis) then
      Exit(N);
  end;
end;

function ParseNumber(const S, What: string): Double;
begin
  if not TryStrToFloat(S, Result, TFormatSettings.Invariant) then
    raise EXRDMLError.CreateFmt('%s is not a number: "%s"', [What, S]);
end;

/// A whitespace-separated list of numbers, as the counts and the position
/// lists are written. Tabs and line breaks count as separators too.
function ParseList(const S, What: string): TArray<Double>;
var
  I, Start, N, Len: Integer;
  Token: string;
begin
  SetLength(Result, 0);
  N := 0;
  Len := Length(S);
  I := 1;
  while I <= Len do
  begin
    while (I <= Len) and (S[I] <= ' ') do
      Inc(I);
    if I > Len then
      Break;
    Start := I;
    while (I <= Len) and (S[I] > ' ') do
      Inc(I);
    Token := Copy(S, Start, I - Start);
    if N = Length(Result) then
      SetLength(Result, Max(64, 2 * N));
    Result[N] := ParseNumber(Token, What + ' value ' + IntToStr(N + 1));
    Inc(N);
  end;
  SetLength(Result, N);
end;

function SchemaVersionOf(const Root: IXMLNode): string;
var
  URI: string;
  P: Integer;
begin
  Result := Attr(Root, 'version');
  if Result <> '' then
    Exit;
  URI := Root.NamespaceURI;
  P := LastDelimiter('/', URI);
  if (P > 0) and (P < Length(URI)) then
    Result := Copy(URI, P + 1, MaxInt);
end;

{ ------------------------------------------------------------------- parsing -- }

function ReadScan(const XML: IXMLDocument): TXRDMLScan;
var
  Root, Sample, Measurement, Scan, Header, DataPoints, Positions, Wave, Beam,
  Tube, CountsNode: IXMLNode;
  I, N: Integer;
  Values, Times, Factors, Angles: TArray<Double>;
  A0, A1, T: Double;
begin
  Result := Default(TXRDMLScan);
  Root := XML.DocumentElement;
  if (Root = nil) or (Root.LocalName <> 'xrdMeasurements') then
    raise EXRDMLError.Create('Not an XRDML document: the root element is not xrdMeasurements');
  Result.SchemaVersion := SchemaVersionOf(Root);
  Result.Status := Attr(Root, 'status');

  Sample := Child(Root, 'sample');
  if Sample <> nil then
    Result.SampleId := ChildText(Sample, 'id');

  Measurement := Child(Root, 'xrdMeasurement');
  if Measurement = nil then
    raise EXRDMLError.Create('No xrdMeasurement element');
  if Attr(Measurement, 'status') <> '' then
    Result.Status := Attr(Measurement, 'status');

  Wave := Child(Measurement, 'usedWavelength');
  if Wave <> nil then
  begin
    Result.Intended := Attr(Wave, 'intended');
    if ChildText(Wave, 'kAlpha1') <> '' then
      Result.KAlpha1 := ParseNumber(ChildText(Wave, 'kAlpha1'), 'kAlpha1');
    if ChildText(Wave, 'kAlpha2') <> '' then
      Result.KAlpha2 := ParseNumber(ChildText(Wave, 'kAlpha2'), 'kAlpha2');
    if ChildText(Wave, 'ratioKAlpha2KAlpha1') <> '' then
      Result.Ratio := ParseNumber(ChildText(Wave, 'ratioKAlpha2KAlpha1'), 'ratioKAlpha2KAlpha1');
  end;
  Beam := Child(Measurement, 'incidentBeamPath');
  if Beam <> nil then
  begin
    Tube := Child(Beam, 'xRayTube');
    if Tube <> nil then
      Result.Anode := ChildText(Tube, 'anodeMaterial');
    Result.Monochromatic := Child(Beam, 'monochromator') <> nil;
    if (Child(Beam, 'xRayMirror') <> nil) and SameText(Attr(Child(Beam, 'xRayMirror'), 'hybrid'), 'true') then
      Result.Monochromatic := True;
  end;
  { the wavelength the file implies }
  if (Result.KAlpha1 > 0) and (Result.KAlpha2 > 0) and (Result.Ratio > 0) and
     SameText(Result.Intended, 'K-Alpha') and not Result.Monochromatic then
  begin
    Result.Lambda := (Result.KAlpha1 + Result.Ratio * Result.KAlpha2) / (1 + Result.Ratio);
    Result.LambdaRule := 'K-Alpha doublet weighted by ratioKAlpha2KAlpha1 ' +
      FormatFloat('0.####', Result.Ratio, TFormatSettings.Invariant);
  end
  else if Result.KAlpha1 > 0 then
  begin
    Result.Lambda := Result.KAlpha1;
    if Result.Monochromatic then
      Result.LambdaRule := 'kAlpha1 (monochromatic incident optic)'
    else if not SameText(Result.Intended, 'K-Alpha') then
      Result.LambdaRule := 'kAlpha1 (intended ' + Result.Intended + ')'
    else
      Result.LambdaRule := 'kAlpha1 (no kAlpha2 ratio in the file)';
  end;
  Beam := Child(Measurement, 'diffractedBeamPath');
  if (Beam <> nil) and (Child(Beam, 'detector') <> nil) then
  begin
    Result.Detector := Attr(Child(Beam, 'detector'), 'name');
    if ChildText(Child(Beam, 'detector'), 'readOutPeriod') <> '' then
      Result.ReadOutPeriod := ParseNumber(ChildText(Child(Beam, 'detector'), 'readOutPeriod'), 'readOutPeriod');
  end;

  { the first scan that carries data points; a batch file holds several }
  Scan := nil;
  DataPoints := nil;
  for I := 0 to Measurement.ChildNodes.Count - 1 do
    if (Measurement.ChildNodes[I].NodeType = ntElement) and
       (Measurement.ChildNodes[I].LocalName = 'scan') then
    begin
      Scan := Measurement.ChildNodes[I];
      DataPoints := Child(Scan, 'dataPoints');
      if DataPoints <> nil then
        Break;
    end;
  if Scan = nil then
    raise EXRDMLError.Create('No scan element in the measurement');
  if DataPoints = nil then
    raise EXRDMLError.Create('The scan has no dataPoints element');

  Result.ScanAxis := Attr(Scan, 'scanAxis');
  Result.ScanMode := Attr(Scan, 'mode');
  if Attr(Scan, 'status') <> '' then
    Result.Status := Attr(Scan, 'status');
  Header := Child(Scan, 'header');
  if Header <> nil then
    Result.StartTime := ChildText(Header, 'startTimeStamp');

  { intensities: raw "counts" (factors apply) or corrected "intensities" }
  CountsNode := Child(DataPoints, 'counts');
  Result.Corrected := False;
  if CountsNode = nil then
  begin
    CountsNode := Child(DataPoints, 'intensities');
    Result.Corrected := True;
  end;
  if CountsNode = nil then
    raise EXRDMLError.Create('dataPoints has neither a counts nor an intensities element');
  Result.IntensityUnit := Attr(CountsNode, 'unit');
  Values := ParseList(VarToStr(CountsNode.NodeValue), 'counts');
  N := Length(Values);
  if N = 0 then
    raise EXRDMLError.Create('The counts element is empty');

  { the abscissa: the 2Theta axis when it moves; a rocking curve keeps 2Theta
    at a commonPosition and moves Omega instead }
  Positions := PositionsOf(DataPoints, '2Theta');
  Result.XAxis := '2Theta';
  if (Positions = nil) or ((Child(Positions, 'listPositions') = nil) and
     (Child(Positions, 'startPosition') = nil)) then
  begin
    if PositionsOf(DataPoints, 'Omega') <> nil then
    begin
      Positions := PositionsOf(DataPoints, 'Omega');
      Result.XAxis := 'Omega';
    end;
  end;
  if Positions = nil then
    raise EXRDMLError.Create('dataPoints has no 2Theta or Omega positions');
  SetLength(Angles, N);
  if Child(Positions, 'listPositions') <> nil then
  begin
    Angles := ParseList(ChildText(Positions, 'listPositions'), Result.XAxis + ' listPositions');
    if Length(Angles) <> N then
      raise EXRDMLError.CreateFmt('%s listPositions has %d values for %d counts',
        [Result.XAxis, Length(Angles), N]);
  end
  else if (Child(Positions, 'startPosition') <> nil) and (Child(Positions, 'endPosition') <> nil) then
  begin
    A0 := ParseNumber(ChildText(Positions, 'startPosition'), Result.XAxis + ' startPosition');
    A1 := ParseNumber(ChildText(Positions, 'endPosition'), Result.XAxis + ' endPosition');
    for I := 0 to N - 1 do
      if N > 1 then
        Angles[I] := A0 + (A1 - A0) * I / (N - 1)
      else
        Angles[I] := A0;
  end
  else if Child(Positions, 'commonPosition') <> nil then
    raise EXRDMLError.CreateFmt('The %s axis does not move in this scan (commonPosition only)', [Result.XAxis])
  else
    raise EXRDMLError.CreateFmt('The %s positions carry neither start/end nor listPositions', [Result.XAxis]);

  { counting time: one for all, or one per point; none leaves raw counts }
  SetLength(Times, 0);
  Result.CountingTime := 0;
  if Child(DataPoints, 'commonCountingTime') <> nil then
    Result.CountingTime := ParseNumber(ChildText(DataPoints, 'commonCountingTime'), 'commonCountingTime')
  else if Child(DataPoints, 'countingTimes') <> nil then
  begin
    Times := ParseList(ChildText(DataPoints, 'countingTimes'), 'countingTimes');
    if Length(Times) <> N then
      raise EXRDMLError.CreateFmt('countingTimes has %d values for %d counts', [Length(Times), N]);
  end;

  { attenuation factors belong to raw counts only }
  SetLength(Factors, 0);
  if (not Result.Corrected) and (Child(DataPoints, 'beamAttenuationFactors') <> nil) then
  begin
    Factors := ParseList(ChildText(DataPoints, 'beamAttenuationFactors'), 'beamAttenuationFactors');
    if Length(Factors) <> N then
      raise EXRDMLError.CreateFmt('beamAttenuationFactors has %d values for %d counts', [Length(Factors), N]);
    Result.AttenuationApplied := True;
  end;

  SetLength(Result.Curve, N);
  for I := 0 to N - 1 do
  begin
    Result.Curve[I].t := Angles[I];
    T := Values[I];
    if Result.AttenuationApplied then
      T := T * Factors[I];
    if Length(Times) > 0 then
    begin
      if Times[I] > 0 then
        T := T / Times[I];
    end
    else if Result.CountingTime > 0 then
      T := T / Result.CountingTime;
    Result.Curve[I].r := T;
  end;
  Result.Points := N;

  { the curve a reflectivity fit wants: floored, then 1 at the maximum. The
    peak rate is taken before the normalisation, so it is the raw counts per
    second the detector saw, the number a saturation check needs. }
  Result.ZerosFloored := 0;
  Result.FirstNonPositive := -1;
  for I := 0 to N - 1 do
    if Result.Curve[I].r <= 0 then
    begin
      Inc(Result.ZerosFloored);
      if Result.FirstNonPositive < 0 then
        Result.FirstNonPositive := I;
    end;
  FloorNonPositive(Result.Curve);
  Result.PeakRate := 0;
  Result.PeakCounts := 0;
  for I := 0 to N - 1 do
    if Result.Curve[I].r > Result.PeakRate then
    begin
      Result.PeakRate := Result.Curve[I].r;
      { the number in the file at that point, before the counting time:
        with the attenuation factor in, as the detector never saw it }
      Result.PeakCounts := Values[I];
      if Result.AttenuationApplied then
        Result.PeakCounts := Result.PeakCounts * Factors[I];
    end;
  if Result.PeakRate > 0 then
    for I := 0 to N - 1 do
      Result.Curve[I].r := Result.Curve[I].r / Result.PeakRate;
end;

/// MSXML lives on COM. The GUI has initialised it; a console server or a test
/// runner may not have, so initialise for the duration of the parse and undo
/// only what this call did. RPC_E_CHANGED_MODE means the thread already has
/// COM in the other apartment model: the parser works there too, nothing to
/// undo.
function ParseDocument(const Load: TProc<IXMLDocument>): TXRDMLScan;
var
  XML: IXMLDocument;
  HR: HRESULT;
  Initialised: Boolean;
begin
  HR := CoInitializeEx(nil, COINIT_APARTMENTTHREADED);
  Initialised := (HR = S_OK) or (HR = S_FALSE);
  try
    XML := TXMLDocument.Create(nil);
    XML.ParseOptions := XML.ParseOptions - [poResolveExternals];
    try
      Load(XML);
    except
      on E: EDOMParseError do
        raise EXRDMLError.Create('Malformed XML: ' + E.Message);
    end;
    XML.Active := True;
    Result := ReadScan(XML);
    XML := nil;
  finally
    if Initialised then
      CoUninitialize;
  end;
end;

function ReadXRDMLFile(const FileName: string): TXRDMLScan;
begin
  if not FileExists(FileName) then
    raise EXRDMLError.CreateFmt('File not found: %s', [FileName]);
  Result := ParseDocument(
    procedure(XML: IXMLDocument)
    begin
      XML.LoadFromFile(FileName);
    end);
end;

function ReadXRDMLText(const Text: string): TXRDMLScan;
begin
  Result := ParseDocument(
    procedure(XML: IXMLDocument)
    begin
      XML.LoadFromXML(Text);
    end);
end;

procedure FloorNonPositive(var Curve: TDataArray);
var
  I: Integer;
  MinPositive: Single;
begin
  MinPositive := 1000;
  for I := 0 to High(Curve) do
  begin
    if (Curve[I].r > 0) and (Curve[I].r < MinPositive) then
      MinPositive := Curve[I].r;
    if Curve[I].r <= 0 then
      Curve[I].r := MinPositive;
  end;
end;

{ ---------------------------------------------------------------- TXRDMLScan -- }

function TXRDMLScan.DescriptionLines: TArray<string>;
var
  S: string;
begin
  SetLength(Result, 0);
  S := '* XRDML ' + SchemaVersion;
  if ScanAxis <> '' then
    S := S + ', scan ' + ScanAxis;
  if ScanMode <> '' then
    S := S + ' (' + ScanMode + ')';
  if Status <> '' then
    S := S + ', status ' + Status;
  Result := Result + [S];
  if SampleId <> '' then
    Result := Result + ['* Sample: ' + SampleId];
  if Lambda > 0 then
  begin
    S := '* Wavelength: ' + FormatFloat('0.000000', Lambda, TFormatSettings.Invariant) + ' A';
    if Anode <> '' then
      S := S + ' (' + Anode + ')';
    S := S + ', ' + LambdaRule;
    if (KAlpha1 > 0) and (KAlpha2 > 0) then
      S := S + '; kAlpha1 ' + FormatFloat('0.000000', KAlpha1, TFormatSettings.Invariant) +
           ', kAlpha2 ' + FormatFloat('0.000000', KAlpha2, TFormatSettings.Invariant);
    Result := Result + [S];
  end;
  if Detector <> '' then
  begin
    S := '* Detector: ' + Detector;
    if ReadOutPeriod > 0 then
      S := S + ', readOutPeriod ' + FormatFloat('0.###', ReadOutPeriod, TFormatSettings.Invariant) + ' s';
    Result := Result + [S];
  end;
  if StartTime <> '' then
    Result := Result + ['* Started: ' + StartTime];
  if CountingTime > 0 then
    S := '* Counting time: ' + FormatFloat('0.###', CountingTime, TFormatSettings.Invariant) + ' s per point'
  else
    S := '* Counting time: per point';
  { keyed to what the file carries, not to the element's name: an
    "intensities" element with no attenuation factors is plain counts, and
    calling it corrected would hide a detector at its ceiling }
  if AttenuationApplied then
    S := S + '; counts x attenuation factor / s'
  else
    S := S + '; counts / s, no attenuation factors in the file';
  Result := Result + [S];
  Result := Result + ['* Intensity normalised to 1 at the maximum; raw peak rate ' +
    FormatFloat('0.###', PeakRate, TFormatSettings.Invariant) +
    ' counts / s (counts / counting time, before normalisation)'];
  if ZerosFloored > 0 then
    Result := Result + ['* Zero counts: ' + IntToStr(ZerosFloored) + ' of ' + IntToStr(Points) +
      ' points floored to the smallest positive intensity before each (1000 counts / s when none)'];
  Result := Result + ['* Angle column: ' + XAxis + ' as scanned, ' + IntToStr(Points) + ' points'];
end;

end.
