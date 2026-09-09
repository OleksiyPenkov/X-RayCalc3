unit TestMCPJournal;

interface

uses DUnitX.TestFramework, System.SysUtils, System.IOUtils, System.JSON, unit_MCPJournal;

type
  [TestFixture]
  TTestMCPJournal = class
  private
    FTemp: string;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure LogCall_Appends_DoesNotTruncate;
    [Test] procedure LogCall_PreExistingFile_NotTruncated;
    [Test] procedure LogEvent_NestsDataUnderDataKey;
    [Test] procedure Compact_Array65_BecomesLen;
    [Test] procedure Compact_Array64_Kept;
  end;

implementation

procedure TTestMCPJournal.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Journal_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTemp);
end;

procedure TTestMCPJournal.TearDown;
begin
  if TDirectory.Exists(FTemp) then TDirectory.Delete(FTemp, True);
end;

procedure TTestMCPJournal.LogCall_Appends_DoesNotTruncate;
var
  J: TJournal;
  Args, Res: TJSONObject;
  Lines: TArray<string>;
  First, Second: TJSONValue;
begin
  J := TJournal.Create(FTemp);
  try
    Args := TJSONObject.Create;
    Res := TJSONObject.Create;
    try
      Args.AddPair('a', TJSONNumber.Create(1));
      Res.AddPair('ok', TJSONBool.Create(True));
      J.LogCall('first_tool', Args, Res, nil, 7);
      J.LogCall('second_tool', Args, Res, nil, 9);
    finally
      Res.Free;
      Args.Free;
    end;
    Assert.IsTrue(TFile.Exists(J.Path), 'calls.jsonl was not created');
    Lines := TFile.ReadAllLines(J.Path, TEncoding.UTF8);
    Assert.AreEqual(2, Length(Lines), 'the second call must append, not truncate');

    First := TJSONObject.ParseJSONValue(Lines[0]);
    try
      Assert.IsNotNull(First, 'line 1 is not parseable JSON');
      Assert.AreEqual('first_tool', (First as TJSONObject).GetValue<string>('tool'));
      Assert.AreEqual(7, (First as TJSONObject).GetValue<Integer>('ms'));
      Assert.IsNotNull((First as TJSONObject).FindValue('result'));
    finally
      First.Free;
    end;

    Second := TJSONObject.ParseJSONValue(Lines[1]);
    try
      Assert.IsNotNull(Second, 'line 2 is not parseable JSON');
      Assert.AreEqual('second_tool', (Second as TJSONObject).GetValue<string>('tool'));
    finally
      Second.Free;
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPJournal.LogCall_PreExistingFile_NotTruncated;
const
  ExistingLine = '{"note":"written before the server started"}';
var
  J: TJournal;
  Lines: TArray<string>;
  Parsed: TJSONValue;
begin
  J := TJournal.Create(FTemp);
  try
    // A journal left behind by an earlier run must survive the next write.
    TFile.WriteAllBytes(J.Path, TEncoding.UTF8.GetBytes(ExistingLine + #10));
    J.LogCall('a_tool', nil, nil, nil, 3);
    Lines := TFile.ReadAllLines(J.Path, TEncoding.UTF8);
    Assert.AreEqual(2, Length(Lines), 'the pre-existing line must not be truncated away');
    Assert.AreEqual(ExistingLine, Lines[0], 'the pre-existing line must be unchanged');
    Parsed := TJSONObject.ParseJSONValue(Lines[1]);
    try
      Assert.IsNotNull(Parsed, 'the appended line is not parseable JSON');
      Assert.AreEqual('a_tool', (Parsed as TJSONObject).GetValue<string>('tool'));
    finally
      Parsed.Free;
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPJournal.LogEvent_NestsDataUnderDataKey;
var
  J: TJournal;
  Data: TJSONObject;
  Lines: TArray<string>;
  Parsed: TJSONValue;
  Line, Nested: TJSONObject;
begin
  J := TJournal.Create(FTemp);
  try
    Data := TJSONObject.Create;
    try
      // 'ts' inside the payload must not collide with the record's own 'ts'.
      Data.AddPair('ts', 'payload-not-a-timestamp');
      Data.AddPair('job', 'fit-1');
      J.LogEvent('job_started', Data);
    finally
      Data.Free;
    end;
    Lines := TFile.ReadAllLines(J.Path, TEncoding.UTF8);
    Assert.AreEqual(1, Length(Lines));
    Parsed := TJSONObject.ParseJSONValue(Lines[0]);
    try
      Assert.IsNotNull(Parsed, 'the event line is not parseable JSON');
      Line := Parsed as TJSONObject;
      Assert.AreEqual('job_started', Line.GetValue<string>('event'));
      Assert.IsNull(Line.FindValue('job'), 'payload keys must not be spliced in at top level');
      Assert.AreNotEqual('payload-not-a-timestamp', Line.GetValue<string>('ts'),
        'the record timestamp must not be overwritten by the payload');
      Assert.IsTrue(Line.FindValue('data') is TJSONObject, '"data" must be an object');
      Nested := TJSONObject(Line.FindValue('data'));
      Assert.AreEqual('fit-1', Nested.GetValue<string>('job'));
      Assert.AreEqual('payload-not-a-timestamp', Nested.GetValue<string>('ts'));
    finally
      Parsed.Free;
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPJournal.Compact_Array65_BecomesLen;
var
  Arr: TJSONArray;
  I: Integer;
  Compact: TJSONValue;
begin
  Arr := TJSONArray.Create;
  try
    for I := 1 to 65 do Arr.AddElement(TJSONNumber.Create(I));
    Compact := CompactForJournal(Arr);
    try
      Assert.IsTrue(Compact is TJSONObject, 'an array of 65 must compact to an object');
      Assert.AreEqual('{"_len":65}', Compact.ToJSON);
    finally
      Compact.Free;
    end;
  finally
    Arr.Free;
  end;
end;

procedure TTestMCPJournal.Compact_Array64_Kept;
var
  Arr: TJSONArray;
  I: Integer;
  Compact: TJSONValue;
begin
  Arr := TJSONArray.Create;
  try
    for I := 1 to 64 do Arr.AddElement(TJSONNumber.Create(I));
    Compact := CompactForJournal(Arr);
    try
      Assert.IsTrue(Compact is TJSONArray, 'an array of 64 must be kept as an array');
      Assert.AreEqual(64, TJSONArray(Compact).Count);
      Assert.AreEqual(Arr.ToJSON, Compact.ToJSON);
    finally
      Compact.Free;
    end;
  finally
    Arr.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPJournal);
end.
