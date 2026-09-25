unit TestCurveStyle;

(* unit_CurveStyle: how a curve's transparency and the chart's draw order are
   kept in params.dsc, keyed by the node's group and ID (M3, D3). *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.IniFiles, unit_CurveStyle;

type
  [TestFixture]
  TTestCurveStyle = class
  private
    FINI: TMemIniFile;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Key_NamesTheGroupAndTheID;

    [Test] procedure DrawOrder_FormatsBottomToTop;
    [Test] procedure DrawOrder_Empty_IsEmptyText;
    [Test] procedure DrawOrder_Parse_SkipsJunkAndRepeats;
    [Test] procedure DrawOrder_Parse_Empty_IsEmpty;
    [Test] procedure DrawOrder_RoundTripsThroughTheINI;
    [Test] procedure DrawOrder_Absent_ReadsEmpty;

    [Test] procedure Transparency_RoundTrips;
    [Test] procedure Transparency_Absent_IsZero;
    [Test] procedure Transparency_ModelAndDataWithOneID_AreApart;
    [Test] procedure Transparency_Zero_LeavesNoKey;
    [Test] procedure Transparency_OutOfRange_IsClamped;
  end;

implementation

procedure TTestCurveStyle.Setup;
begin
  FINI := TMemIniFile.Create('');
end;

procedure TTestCurveStyle.TearDown;
begin
  FINI.Free;
end;

procedure TTestCurveStyle.Key_NamesTheGroupAndTheID;
begin
  Assert.AreEqual('M3', CurveKey(True, 3), 'model');
  Assert.AreEqual('D3', CurveKey(False, 3), 'data');
end;

procedure TTestCurveStyle.DrawOrder_FormatsBottomToTop;
begin
  Assert.AreEqual('D12,M3,D7', FormatDrawOrder(['D12', 'M3', 'D7']));
end;

procedure TTestCurveStyle.DrawOrder_Empty_IsEmptyText;
begin
  Assert.AreEqual('', FormatDrawOrder([]));
end;

procedure TTestCurveStyle.DrawOrder_Parse_SkipsJunkAndRepeats;
begin
  Assert.AreEqual('D12,M3,D7,M7',
    string.Join(',', ParseDrawOrder('D12, M3,x,,D7,M3,D-4,12,M07,Q1,M,M7')));
end;

procedure TTestCurveStyle.DrawOrder_Parse_Empty_IsEmpty;
begin
  Assert.AreEqual(0, Integer(Length(ParseDrawOrder(''))));
end;

procedure TTestCurveStyle.DrawOrder_RoundTripsThroughTheINI;
begin
  WriteDrawOrder(FINI, ['D5', 'M0', 'D9']);
  Assert.AreEqual('D5,M0,D9', string.Join(',', ReadDrawOrder(FINI)));
end;

procedure TTestCurveStyle.DrawOrder_Absent_ReadsEmpty;
begin
  Assert.AreEqual(0, Integer(Length(ReadDrawOrder(FINI))));
end;

procedure TTestCurveStyle.Transparency_RoundTrips;
begin
  WriteCurveTransparency(FINI, 'D5', 40);
  Assert.AreEqual(40, ReadCurveTransparency(FINI, 'D5'));
end;

procedure TTestCurveStyle.Transparency_Absent_IsZero;
begin
  WriteCurveTransparency(FINI, 'D5', 40);
  Assert.AreEqual(0, ReadCurveTransparency(FINI, 'D6'));
end;

procedure TTestCurveStyle.Transparency_ModelAndDataWithOneID_AreApart;
begin
  { An older build could give a model the ID of a data curve. }
  WriteCurveTransparency(FINI, CurveKey(True, 3), 50);
  WriteCurveTransparency(FINI, CurveKey(False, 3), 0);
  Assert.AreEqual(50, ReadCurveTransparency(FINI, CurveKey(True, 3)), 'model');
  Assert.AreEqual(0, ReadCurveTransparency(FINI, CurveKey(False, 3)), 'data');
end;

procedure TTestCurveStyle.Transparency_Zero_LeavesNoKey;
begin
  WriteCurveTransparency(FINI, 'D5', 0);
  Assert.IsFalse(FINI.SectionExists(CURVES_SECTION), 'an opaque curve writes nothing');
end;

procedure TTestCurveStyle.Transparency_OutOfRange_IsClamped;
begin
  FINI.WriteString(CURVES_SECTION, 'Transparency.D1', '200');
  FINI.WriteString(CURVES_SECTION, 'Transparency.D2', '-5');
  FINI.WriteString(CURVES_SECTION, 'Transparency.D3', 'half');
  Assert.AreEqual(MAX_CURVE_TRANSPARENCY, ReadCurveTransparency(FINI, 'D1'), 'too high');
  Assert.AreEqual(0, ReadCurveTransparency(FINI, 'D2'), 'negative');
  Assert.AreEqual(0, ReadCurveTransparency(FINI, 'D3'), 'not a number');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCurveStyle);

end.
