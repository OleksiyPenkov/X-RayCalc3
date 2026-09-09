unit TestMCPInbox;

(* The measurement inbox: the text parser, meta.json and the two read-only
   tools that sit on top of them.

   Every test runs against its own temporary work directory, assigned to the
   global WorkDir in Setup and restored in TearDown, so that nothing here can
   reach the real inbox of a running server.

   The last test is the one the requirements ask for by name: the inbox is
   read-only, and the proof is that the SHA-256 of every file in it is the same
   after list_measurements and get_measurement have run as it was before. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.JSON, System.Generics.Collections,
  unit_Types, unit_MCPSandbox, unit_MCPErrors, unit_MCPInbox;

type
  [TestFixture]
  TTestMCPInbox = class
  private
    FTemp: string;
    FSavedWorkDir: TWorkDir;
    /// <summary>Splits Text on line breaks into a TStringList the caller frees.</summary>
    function LinesOf(const Text: string): TStringList;
    /// <summary>Writes Text to inbox\<Specimen>\<FileName> and returns the
    /// absolute path. The only writer of the test inbox: the code under test
    /// never writes there.</summary>
    function WriteInboxFile(const Specimen, FileName, Text: string): string;
    /// <summary>SHA-256 of every file under the inbox, keyed by absolute path.</summary>
    function InboxHashes: TDictionary<string, string>;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure ParseCurve_TabSeparated_WithHeader;
    [Test] procedure ParseCurve_SpaceSeparated;
    [Test] procedure ParseCurve_CommaDecimal;
    [Test] procedure ParseCurve_ZeroIntensity_ReplacedByMinPositive;
    [Test] procedure ParseCurve_SkipsNonNumericLines;
    [Test] procedure ReadMeta_Parses_Lambda_ThetaUnit;
    [Test] procedure ReadMeta_Energy_ConvertedToLambda;
    [Test] procedure ReadMeta_Absent_ThetaUnitAssumed;
    [Test] procedure ReadMeta_Malformed_RaisesInvalidArgument;
    [Test] procedure LoadMeasurement_2Theta_Converted;
    [Test] procedure LoadMeasurement_BadId_Raises;
    [Test] procedure LoadMeasurement_Missing_RaisesNotFound;
    [Test] procedure LoadMeasurement_Decimates_KeepsPointCount;
    [Test] procedure Decimate_KeepsEnds;
    [Test] procedure ListMeasurements_ListsSpecimensAndFilters;
    [Test] procedure ListMeasurements_LooseFilesIgnored;
    [Test] procedure GetMeasurementJSON_HasTheShapeTheClientExpects;
    [Test] procedure Inbox_SHA256_Unchanged_AfterListAndGet;
  end;

implementation

{ ----------------------------------------------------------------- fixture -- }

procedure TTestMCPInbox.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Inbox_' + TGUID.NewGuid.ToString);
  FSavedWorkDir := WorkDir;
  WorkDir := TWorkDir.Create(FTemp);
  WorkDir.EnsureLayout;
end;

procedure TTestMCPInbox.TearDown;
begin
  WorkDir.Free;
  WorkDir := FSavedWorkDir;
  try
    if TDirectory.Exists(FTemp) then
      TDirectory.Delete(FTemp, True);
  except
    // a leftover temp folder must not turn into a test failure
  end;
end;

function TTestMCPInbox.LinesOf(const Text: string): TStringList;
begin
  Result := TStringList.Create;
  Result.Text := Text;
end;

function TTestMCPInbox.WriteInboxFile(const Specimen, FileName, Text: string): string;
var
  Dir: string;
begin
  Dir := TPath.Combine(TPath.Combine(FTemp, 'inbox'), Specimen);
  TDirectory.CreateDirectory(Dir);
  Result := TPath.Combine(Dir, FileName);
  TFile.WriteAllText(Result, Text, TEncoding.ASCII);
end;

function TTestMCPInbox.InboxHashes: TDictionary<string, string>;
var
  F: string;
begin
  Result := TDictionary<string, string>.Create;
  try
    for F in TDirectory.GetFiles(TPath.Combine(FTemp, 'inbox'), '*',
      TSearchOption.soAllDirectories) do
      Result.Add(F, FileSHA256(F));
  except
    Result.Free;
    raise;
  end;
end;

{ ------------------------------------------------------------ ParseCurveText -- }

procedure TTestMCPInbox.ParseCurve_TabSeparated_WithHeader;
var
  SL: TStringList;
  Curve: TDataArray;
  Header: TArray<string>;
  N: Integer;
begin
  SL := LinesOf('2Theta'#9'Reflectivity'#13#10'deg'#9#13#10#13#10 +
                '0.010'#9'9.99E-1'#13#10'0.015'#9'9.9E-1');
  try
    N := ParseCurveText(SL, Curve, Header);
  finally
    SL.Free;
  end;
  Assert.AreEqual(2, N, 'point count');
  Assert.AreEqual(2, Length(Header), 'header lines');
  Assert.AreEqual('2Theta'#9'Reflectivity', Header[0]);
  Assert.AreEqual(Double(0.010), Double(Curve[0].t), 1E-6);
  Assert.AreEqual(Double(0.999), Double(Curve[0].r), 1E-6);
  Assert.AreEqual(Double(0.015), Double(Curve[1].t), 1E-6);
  Assert.AreEqual(Double(0.99), Double(Curve[1].r), 1E-6);
end;

procedure TTestMCPInbox.ParseCurve_SpaceSeparated;
var
  SL: TStringList;
  Curve: TDataArray;
  Header: TArray<string>;
  N: Integer;
begin
  SL := LinesOf('0.10 1.0E-1'#13#10'0.20 2.0E-2'#13#10'0.30 3.0E-3');
  try
    N := ParseCurveText(SL, Curve, Header);
  finally
    SL.Free;
  end;
  Assert.AreEqual(3, N);
  Assert.AreEqual(0, Length(Header));
  Assert.AreEqual(Double(0.30), Double(Curve[2].t), 1E-6);
  Assert.AreEqual(Double(3.0E-3), Double(Curve[2].r), 1E-9);
end;

procedure TTestMCPInbox.ParseCurve_CommaDecimal;
var
  SL: TStringList;
  Curve: TDataArray;
  Header: TArray<string>;
begin
  SL := LinesOf('0,5 1,2e-3');
  try
    Assert.AreEqual(1, ParseCurveText(SL, Curve, Header));
  finally
    SL.Free;
  end;
  Assert.AreEqual(Double(0.5), Double(Curve[0].t), 1E-6);
  Assert.AreEqual(Double(1.2E-3), Double(Curve[0].r), 1E-9);
end;

procedure TTestMCPInbox.ParseCurve_ZeroIntensity_ReplacedByMinPositive;
var
  SL: TStringList;
  Curve: TDataArray;
  Header: TArray<string>;
begin
  { 1e-2 is the smallest positive intensity seen when the zero is reached, so
    the zero and the negative that follows both become 1e-2. }
  SL := LinesOf('0.1 1.0E-1'#13#10'0.2 1.0E-2'#13#10'0.3 0'#13#10'0.4 -5.0E-3');
  try
    Assert.AreEqual(4, ParseCurveText(SL, Curve, Header));
  finally
    SL.Free;
  end;
  Assert.AreEqual(Double(1.0E-2), Double(Curve[2].r), 1E-9, 'zero replaced');
  Assert.AreEqual(Double(1.0E-2), Double(Curve[3].r), 1E-9, 'negative replaced');
end;

procedure TTestMCPInbox.ParseCurve_SkipsNonNumericLines;
var
  SL: TStringList;
  Curve: TDataArray;
  Header: TArray<string>;
begin
  SL := LinesOf('# comment line'#13#10'0.1 1.0E-1'#13#10'not a number here'#13#10'0.2 1.0E-2');
  try
    Assert.AreEqual(2, ParseCurveText(SL, Curve, Header));
  finally
    SL.Free;
  end;
  Assert.AreEqual(2, Length(Header), 'the two non-numeric lines are kept as header');
  Assert.AreEqual('# comment line', Header[0]);
  Assert.AreEqual('not a number here', Header[1]);
end;

{ ----------------------------------------------------------------- ReadMeta -- }

procedure TTestMCPInbox.ReadMeta_Parses_Lambda_ThetaUnit;
var
  Dir: string;
  Meta: TInboxMeta;
begin
  WriteInboxFile('S1', 'meta.json',
    '{"lambda": 1.5406, "date": "2026-09-01", "instrument": "D8", ' +
    '"theta_unit": "2theta", "operator": "AP"}');
  Dir := TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1');
  Assert.IsTrue(ReadMeta(Dir, Meta));
  try
    Assert.IsTrue(Meta.Present);
    Assert.AreEqual(Double(1.5406), Meta.Lambda, 1E-9);
    Assert.AreEqual('2026-09-01', Meta.DateStr);
    Assert.AreEqual('D8', Meta.Instrument);
    Assert.AreEqual('2theta', Meta.ThetaUnit);
    Assert.IsTrue(Meta.ThetaUnitDeclared);
    Assert.IsNotNull(Meta.Raw);
    Assert.AreEqual('AP', Meta.Raw.GetValue<string>('operator'), 'unknown keys pass through');
  finally
    Meta.Raw.Free;
  end;
end;

procedure TTestMCPInbox.ReadMeta_Energy_ConvertedToLambda;
var
  Dir: string;
  Meta: TInboxMeta;
begin
  WriteInboxFile('S1', 'meta.json', '{"energy": 8047.8}');
  Dir := TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1');
  Assert.IsTrue(ReadMeta(Dir, Meta));
  try
    Assert.AreEqual(12398.42 / 8047.8, Meta.Lambda, 1E-9);
  finally
    Meta.Raw.Free;
  end;
end;

procedure TTestMCPInbox.ReadMeta_Absent_ThetaUnitAssumed;
var
  Meta: TInboxMeta;
begin
  TDirectory.CreateDirectory(TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1'));
  Assert.IsFalse(ReadMeta(TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1'), Meta));
  Assert.IsFalse(Meta.Present);
  Assert.IsNull(Meta.Raw);
  Assert.AreEqual('theta', Meta.ThetaUnit);
  Assert.IsFalse(Meta.ThetaUnitDeclared);
end;

procedure TTestMCPInbox.ReadMeta_Malformed_RaisesInvalidArgument;
var
  Dir: string;
begin
  WriteInboxFile('S1', 'meta.json', '{ this is not json');
  Dir := TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1');
  Assert.WillRaiseWithMessage(
    procedure
    var
      Meta: TInboxMeta;
    begin
      ReadMeta(Dir, Meta);
    end, EMCPError, 'meta.json is not valid JSON');
end;

{ ---------------------------------------------------------- LoadMeasurement -- }

procedure TTestMCPInbox.LoadMeasurement_2Theta_Converted;
var
  M: TMeasurement;
begin
  WriteInboxFile('S1', 'c.dat', '1.0'#9'0.5'#13#10'2.0'#9'0.25');
  WriteInboxFile('S1', 'meta.json', '{"lambda": 1.5406, "theta_unit": "2theta"}');
  M := LoadMeasurement('S1/c.dat', 0);
  try
    Assert.IsTrue(M.Converted2Theta);
    Assert.AreEqual('2theta,intensity', M.Columns);
    Assert.AreEqual(2, M.Points);
    Assert.AreEqual(Double(0.5), Double(M.Curve[0].t), 1E-6);
    Assert.AreEqual(Double(1.0), Double(M.Curve[1].t), 1E-6);
    Assert.AreEqual(Double(0.5), M.ThetaMin, 1E-6);
    Assert.AreEqual(Double(1.0), M.ThetaMax, 1E-6);
    Assert.AreEqual(Double(1.5406), M.Meta.Lambda, 1E-9);
  finally
    M.Meta.Raw.Free;
  end;
end;

procedure TTestMCPInbox.LoadMeasurement_BadId_Raises;

  procedure Bad(const Id: string);
  begin
    Assert.WillRaise(
      procedure
      var
        M: TMeasurement;
      begin
        M := LoadMeasurement(Id, 0);
        M.Meta.Raw.Free;
      end, EMCPError, 'expected a refusal for "' + Id + '"');
  end;

begin
  Bad('a/../b');
  Bad('noslash');
  Bad('a/b/c');
  Bad('a/b.exe');
  Bad('/b.dat');
  Bad('a/');
end;

procedure TTestMCPInbox.LoadMeasurement_Missing_RaisesNotFound;
var
  Code: string;
begin
  TDirectory.CreateDirectory(TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1'));
  Code := '';
  try
    LoadMeasurement('S1/absent.dat', 0);
  except
    on E: EMCPError do
      Code := E.Code;
  end;
  Assert.AreEqual('not_found', Code);
end;

procedure TTestMCPInbox.LoadMeasurement_Decimates_KeepsPointCount;
var
  SL: TStringList;
  I: Integer;
  M: TMeasurement;
begin
  SL := TStringList.Create;
  try
    for I := 0 to 999 do
      SL.Add(Format('%d.%.2d'#9'1.0E-2', [I div 100, I mod 100]));
    WriteInboxFile('S1', 'big.dat', SL.Text);
  finally
    SL.Free;
  end;
  M := LoadMeasurement('S1/big.dat', 100);
  try
    Assert.AreEqual(1000, M.Points, 'points is the original count');
    Assert.IsTrue(Length(M.Curve) <= 100, 'decimated to at most max_points');
    Assert.AreEqual(Double(0.0), Double(M.Curve[0].t), 1E-6);
    Assert.AreEqual(Double(9.99), Double(M.Curve[High(M.Curve)].t), 1E-3);
    Assert.AreEqual(Double(9.99), M.ThetaMax, 1E-3, 'range from the full curve');
  finally
    M.Meta.Raw.Free;
  end;
end;

{ ------------------------------------------------------------ DecimateCurve -- }

procedure TTestMCPInbox.Decimate_KeepsEnds;
var
  C, D: TDataArray;
  I: Integer;
begin
  SetLength(C, 1000);
  for I := 0 to 999 do
  begin
    C[I].t := I;
    C[I].r := 1000 - I;
  end;
  D := DecimateCurve(C, 100);
  Assert.IsTrue(Length(D) <= 100, 'at most 100 points, got ' + IntToStr(Length(D)));
  Assert.IsTrue(Length(D) > 1);
  Assert.AreEqual(Double(0), Double(D[0].t), 1E-6, 'first kept');
  Assert.AreEqual(Double(999), Double(D[High(D)].t), 1E-6, 'last kept');
  Assert.AreEqual(Double(1), Double(D[High(D)].r), 1E-6, 'last point is the real one');

  D := DecimateCurve(C, 5000);
  Assert.AreEqual(1000, Length(D), 'a short enough curve is returned unchanged');
end;

{ --------------------------------------------------------- ListMeasurements -- }

procedure TTestMCPInbox.ListMeasurements_ListsSpecimensAndFilters;
var
  Arr: TJSONArray;
  Obj: TJSONObject;
  Files: TJSONArray;
begin
  WriteInboxFile('S1', 'c.dat', '0.1 1.0E-1');
  WriteInboxFile('S1', 'meta.json', '{"lambda": 1.5406}');
  WriteInboxFile('S2', 'd.txt', '0.1 1.0E-1');

  Arr := ListMeasurements('');
  try
    Assert.AreEqual(2, Arr.Count, 'two specimens');
  finally
    Arr.Free;
  end;

  Arr := ListMeasurements('s1');   // exact but case-insensitive
  try
    Assert.AreEqual(1, Arr.Count);
    Obj := Arr.Items[0] as TJSONObject;
    Assert.AreEqual('S1', Obj.GetValue<string>('specimen'));
    Files := Obj.GetValue('files') as TJSONArray;
    Assert.AreEqual(1, Files.Count, 'meta.json is not a measurement');
    Assert.AreEqual('c.dat', (Files.Items[0] as TJSONObject).GetValue<string>('name'));
    Assert.AreEqual('S1/c.dat', (Files.Items[0] as TJSONObject).GetValue<string>('id'));
    Assert.AreEqual(Int64(10), (Files.Items[0] as TJSONObject).GetValue<Int64>('size'));
    Assert.AreEqual(64, Length((Files.Items[0] as TJSONObject).GetValue<string>('sha256')));
    Assert.IsNotNull((Files.Items[0] as TJSONObject).GetValue('modified_utc'));
    Assert.IsTrue(Obj.GetValue('meta') is TJSONObject, 'meta.json is echoed');
  finally
    Arr.Free;
  end;

  Arr := ListMeasurements('S3');
  try
    Assert.AreEqual(0, Arr.Count, 'an unknown specimen filter matches nothing');
  finally
    Arr.Free;
  end;
end;

procedure TTestMCPInbox.ListMeasurements_LooseFilesIgnored;
var
  Arr: TJSONArray;
begin
  TFile.WriteAllText(TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'stray.dat'),
    '0.1 1.0E-1', TEncoding.ASCII);
  WriteInboxFile('S1', 'c.dat', '0.1 1.0E-1');

  Arr := ListMeasurements('');
  try
    Assert.AreEqual(1, Arr.Count, 'only the specimen folder is listed');
  finally
    Arr.Free;
  end;
  Assert.AreEqual(1, LooseFileCount, 'the stray file is counted, not listed');
end;

{ ------------------------------------------------------- get_measurement JSON -- }

procedure TTestMCPInbox.GetMeasurementJSON_HasTheShapeTheClientExpects;
var
  Obj: TJSONObject;
  Range: TJSONArray;
begin
  WriteInboxFile('S1', 'c.dat', '0.10'#9'1.0E-1'#13#10'0.20'#9'1.0E-2');

  Obj := GetMeasurementJSON('S1/c.dat', 2000);
  try
    Assert.AreEqual('S1/c.dat', Obj.GetValue<string>('measurement_id'));
    Assert.AreEqual('inbox\S1\c.dat', Obj.GetValue<string>('file'));
    Assert.AreEqual(2, Obj.GetValue<Integer>('points'));
    Assert.AreEqual(2, Obj.GetValue<Integer>('points_returned'));
    Assert.AreEqual('theta,intensity', Obj.GetValue<string>('columns'));
    Assert.IsFalse(Obj.GetValue<Boolean>('converted_from_2theta'));
    Assert.IsTrue(Obj.GetValue<Boolean>('theta_unit_assumed'), 'no meta.json, so theta assumed');
    Assert.IsTrue(Obj.GetValue('lambda') is TJSONNull);
    Assert.IsTrue(Obj.GetValue('meta') is TJSONNull);
    Range := Obj.GetValue('theta_range') as TJSONArray;
    Assert.AreEqual(Double(0.10), (Range.Items[0] as TJSONNumber).AsDouble, 1E-6);
    Assert.AreEqual(Double(0.20), (Range.Items[1] as TJSONNumber).AsDouble, 1E-6);
    Assert.AreEqual(2, (Obj.GetValue('curve') as TJSONArray).Count);
  finally
    Obj.Free;
  end;
end;

{ ------------------------------------------------------------ inbox is read-only -- }

procedure TTestMCPInbox.Inbox_SHA256_Unchanged_AfterListAndGet;
var
  Before, After: TDictionary<string, string>;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Pair: TPair<string, string>;
begin
  WriteInboxFile('S1', 'c.dat', '0.10'#9'1.0E-1'#13#10'0.20'#9'1.0E-2');
  WriteInboxFile('S1', 'meta.json', '{"lambda": 1.5406, "theta_unit": "2theta"}');
  WriteInboxFile('S2', 'd.xy', '0.10 1.0E-1'#13#10'0.20 1.0E-2');

  Before := InboxHashes;
  try
    Arr := ListMeasurements('');
    Arr.Free;
    Obj := GetMeasurementJSON('S1/c.dat', 2000);
    Obj.Free;
    Obj := GetMeasurementJSON('S2/d.xy', 1);
    Obj.Free;

    After := InboxHashes;
    try
      Assert.AreEqual(Before.Count, After.Count, 'no file added or removed');
      for Pair in Before do
      begin
        Assert.IsTrue(After.ContainsKey(Pair.Key), 'still present: ' + Pair.Key);
        Assert.AreEqual(Pair.Value, After[Pair.Key], 'unchanged: ' + Pair.Key);
      end;
    finally
      After.Free;
    end;
  finally
    Before.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPInbox);
end.
