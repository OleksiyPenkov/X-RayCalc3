unit TestSeriesIO;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestSeriesIO = class
  private
    FTempDir: string;
    function TempFile(const Name: string): string;
  public
    [Setup]    procedure Setup;
    [TearDown] procedure TearDown;

    { SeriesToFile / SeriesFromFile roundtrip }
    [Test] procedure Test_SeriesToFile_CreatesFile;
    [Test] procedure Test_SeriesFromFile_Roundtrip;
    [Test] procedure Test_SeriesFromFile_SkipsCommentLines;
    [Test] procedure Test_SeriesFromFile_SkipsSampleHeader;

    { SeriesToString }
    [Test] procedure Test_SeriesToString_ContainsData;

    { SeriesToClipboard / SeriesFromClipboard roundtrip }
    [Test] procedure Test_Clipboard_Roundtrip;

    { DataToFile }
    [Test] procedure Test_DataToFile_CreatesFile;
    [Test] procedure Test_DataToFile_Roundtrip;
  end;

implementation

uses
  unit_SeriesIO, unit_types, VclTee.Series, Clipbrd,
  System.SysUtils, System.IOUtils, System.Classes;

{ TTestSeriesIO }

procedure TTestSeriesIO.Setup;
begin
  FTempDir := TPath.Combine(TPath.GetTempPath, 'XRC_TestIO_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTempDir);
end;

procedure TTestSeriesIO.TearDown;
begin
  if TDirectory.Exists(FTempDir) then
    TDirectory.Delete(FTempDir, True);
end;

function TTestSeriesIO.TempFile(const Name: string): string;
begin
  Result := TPath.Combine(FTempDir, Name);
end;

{ --- SeriesToFile / SeriesFromFile --- }

procedure TTestSeriesIO.Test_SeriesToFile_CreatesFile;
var
  S: TLineSeries;
  fn: string;
begin
  S := TLineSeries.Create(nil);
  try
    S.AddXY(1.0, 0.5);
    S.AddXY(2.0, 0.3);
    fn := TempFile('test.dat');
    SeriesToFile(S, fn);
    Assert.IsTrue(TFile.Exists(fn), 'File should exist');
  finally
    S.Free;
  end;
end;

procedure TTestSeriesIO.Test_SeriesFromFile_Roundtrip;
var
  SOut, SIn: TLineSeries;
  fn, Descr: string;
begin
  SOut := TLineSeries.Create(nil);
  SIn := TLineSeries.Create(nil);
  try
    SOut.AddXY(0.5, 1.0);
    SOut.AddXY(1.0, 0.1);
    SOut.AddXY(1.5, 0.01);

    fn := TempFile('roundtrip.dat');
    SeriesToFile(SOut, fn);

    Descr := '';
    SeriesFromFile(SIn, fn, Descr);

    Assert.AreEqual(SOut.Count, SIn.Count, 'Point count');
    Assert.AreEqual(SOut.XValue[0], SIn.XValue[0], 0.01, 'X[0]');
    Assert.AreEqual(SOut.YValue[0], SIn.YValue[0], 0.01, 'Y[0]');
    Assert.AreEqual(SOut.XValue[2], SIn.XValue[2], 0.01, 'X[2]');
    Assert.AreEqual(SOut.YValue[2], SIn.YValue[2], 1E-4, 'Y[2]');
  finally
    SOut.Free;
    SIn.Free;
  end;
end;

procedure TTestSeriesIO.Test_SeriesFromFile_SkipsCommentLines;
var
  SL: TStringList;
  S: TLineSeries;
  fn, Descr: string;
begin
  // Lines starting with '*' are treated as description and stripped
  SL := TStringList.Create;
  S := TLineSeries.Create(nil);
  try
    SL.Add('* Comment line 1');
    SL.Add('* Comment line 2');
    SL.Add('1.0' + #9 + '0.5');
    SL.Add('2.0' + #9 + '0.3');
    fn := TempFile('comments.dat');
    SL.SaveToFile(fn);

    Descr := '';
    SeriesFromFile(S, fn, Descr);

    Assert.AreEqual(2, S.Count, 'Should read 2 data points');
    Assert.IsTrue(Pos('Comment line 1', Descr) > 0, 'Descr should contain comment');
    Assert.AreEqual(Double(1.0), S.XValue[0], 0.01, 'X[0]');
  finally
    SL.Free;
    S.Free;
  end;
end;

procedure TTestSeriesIO.Test_SeriesFromFile_SkipsSampleHeader;
var
  SL: TStringList;
  S: TLineSeries;
  fn, Descr: string;
  i: integer;
begin
  // When first line contains 'Sample', 21 lines are deleted from the top.
  // The remaining line 21 must not contain spaces (which would permanently
  // switch SeriesFromText separator from tab to space).
  SL := TStringList.Create;
  S := TLineSeries.Create(nil);
  try
    SL.Add('Sample: test');   // line 0 — triggers skip
    for i := 1 to 20 do
      SL.Add('header_' + IntToStr(i));
    SL.Add('');               // line 21 — blank, survives the skip, ignored by parser
    SL.Add('1.0' + #9 + '0.5');
    SL.Add('2.0' + #9 + '0.3');
    fn := TempFile('sample.dat');
    SL.SaveToFile(fn);

    Descr := '';
    SeriesFromFile(S, fn, Descr);

    Assert.AreEqual(2, S.Count, 'Should read 2 data points after skipping header');
    Assert.AreEqual(Double(1.0), S.XValue[0], 0.01, 'X[0]');
    Assert.AreEqual(Double(0.5), S.YValue[0], 0.01, 'Y[0]');
  finally
    SL.Free;
    S.Free;
  end;
end;

{ --- SeriesToString --- }

procedure TTestSeriesIO.Test_SeriesToString_ContainsData;
var
  S: TLineSeries;
  Txt: string;
begin
  S := TLineSeries.Create(nil);
  try
    S.AddXY(1.5, 0.123);
    S.AddXY(2.5, 0.456);
    Txt := SeriesToString(S);

    // Should contain header and data
    Assert.IsTrue(Pos('2Theta', Txt) > 0, 'Should contain column header');
    Assert.IsTrue(Pos('1.500', Txt) > 0, 'Should contain X value');
  finally
    S.Free;
  end;
end;

{ --- Clipboard --- }

procedure TTestSeriesIO.Test_Clipboard_Roundtrip;
var
  SOut, SIn: TLineSeries;
begin
  SOut := TLineSeries.Create(nil);
  SIn := TLineSeries.Create(nil);
  try
    SOut.AddXY(0.5, 1.0);
    SOut.AddXY(1.0, 0.1);
    SOut.AddXY(1.5, 0.01);

    try
      SeriesToClipboard(SOut, 0);  // mode 0 = 2Theta
    except
      on E: Exception do
      begin
        Assert.Pass('Clipboard not available: ' + E.Message);
        Exit;
      end;
    end;

    SeriesFromClipboard(SIn);

    Assert.AreEqual(SOut.Count, SIn.Count, 'Point count');
    Assert.AreEqual(SOut.XValue[0], SIn.XValue[0], 0.01, 'X[0]');
    Assert.AreEqual(SOut.YValue[0], SIn.YValue[0], 0.01, 'Y[0]');
    Assert.AreEqual(SOut.XValue[2], SIn.XValue[2], 0.01, 'X[2]');
    Assert.AreEqual(SOut.YValue[2], SIn.YValue[2], 1E-4, 'Y[2]');
  finally
    SOut.Free;
    SIn.Free;
  end;
end;

{ --- DataToFile --- }

procedure TTestSeriesIO.Test_DataToFile_CreatesFile;
var
  D: TDataArray;
  fn: string;
begin
  SetLength(D, 2);
  D[0].t := 1.0; D[0].r := 0.5;
  D[1].t := 2.0; D[1].r := 0.3;
  fn := TempFile('data.dat');
  DataToFile(fn, D);
  Assert.IsTrue(TFile.Exists(fn), 'File should exist');
end;

procedure TTestSeriesIO.Test_DataToFile_Roundtrip;
var
  D: TDataArray;
  SL: TStringList;
  fn: string;
begin
  SetLength(D, 2);
  D[0].t := 1.5; D[0].r := 0.25;
  D[1].t := 3.0; D[1].r := 0.75;
  fn := TempFile('data_rt.dat');
  DataToFile(fn, D);

  // Read back and verify content has the values
  SL := TStringList.Create;
  try
    SL.LoadFromFile(fn);
    Assert.AreEqual(2, SL.Count, 'Should have 2 lines');
    Assert.IsTrue(Pos('1.5', SL[0]) > 0, 'Line 0 should contain 1.5');
    Assert.IsTrue(Pos('3.0', SL[1]) > 0, 'Line 1 should contain 3.0');
  finally
    SL.Free;
  end;
end;

end.
