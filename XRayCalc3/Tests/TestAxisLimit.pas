unit TestAxisLimit;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestAxisLimit = class
  public
    { Accepted input }
    [Test] procedure Test_Parse_LowerCaseExponent;
    [Test] procedure Test_Parse_UpperCaseExponent;
    [Test] procedure Test_Parse_Mantissa;
    [Test] procedure Test_Parse_CommaDecimalSeparator;
    [Test] procedure Test_Parse_SurroundingSpaces;
    [Test] procedure Test_Parse_PlainDecimal;

    { Rejected input - every one of these used to reach the axis }
    [Test] procedure Test_Reject_Empty;
    [Test] procedure Test_Reject_Garbage;
    [Test] procedure Test_Reject_HalfTypedExponent;
    [Test] procedure Test_Reject_Zero;
    [Test] procedure Test_Reject_Negative;
    [Test] procedure Test_Reject_AtAxisMaximum;
    [Test] procedure Test_Reject_AboveAxisMaximum;
    [Test] procedure Test_Reject_UnderflowsSingle;

    { Formatting }
    [Test] procedure Test_Format_WholeMantissa;
    [Test] procedure Test_Format_FractionalMantissa;
    [Test] procedure Test_Format_Default;

    { The drop-down list must agree with the parser }
    [Test] procedure Test_ListItems_AllParseAndRoundTrip;
  end;

implementation

uses
  System.SysUtils, unit_AxisLimit;

const
  AXIS_MAX = 1.0;

procedure TTestAxisLimit.Test_Parse_LowerCaseExponent;
var
  V: Single;
begin
  Assert.IsTrue(TryParseAxisLimit('1e-8', AXIS_MAX, V), 'accepted');
  Assert.AreEqual(Single(1E-8), V, 1E-12);
end;

procedure TTestAxisLimit.Test_Parse_UpperCaseExponent;
var
  V: Single;
begin
  Assert.IsTrue(TryParseAxisLimit('1E-8', AXIS_MAX, V), 'accepted');
  Assert.AreEqual(Single(1E-8), V, 1E-12);
end;

procedure TTestAxisLimit.Test_Parse_Mantissa;
var
  V: Single;
begin
  Assert.IsTrue(TryParseAxisLimit('3.5E-8', AXIS_MAX, V), 'accepted');
  Assert.AreEqual(Single(3.5E-8), V, 1E-12);
end;

procedure TTestAxisLimit.Test_Parse_CommaDecimalSeparator;
var
  V: Single;
begin
  // A user on a comma-decimal locale types 3,5E-8 - StrToFloat with the
  // invariant settings would reject it, so the parser normalises first.
  Assert.IsTrue(TryParseAxisLimit('3,5E-8', AXIS_MAX, V), 'accepted');
  Assert.AreEqual(Single(3.5E-8), V, 1E-12);
end;

procedure TTestAxisLimit.Test_Parse_SurroundingSpaces;
var
  V: Single;
begin
  Assert.IsTrue(TryParseAxisLimit('  1E-8  ', AXIS_MAX, V), 'accepted');
  Assert.AreEqual(Single(1E-8), V, 1E-12);
end;

procedure TTestAxisLimit.Test_Parse_PlainDecimal;
var
  V: Single;
begin
  Assert.IsTrue(TryParseAxisLimit('0.001', AXIS_MAX, V), 'accepted');
  Assert.AreEqual(Single(1E-3), V, 1E-9);
end;

procedure TTestAxisLimit.Test_Reject_Empty;
var
  V: Single;
begin
  Assert.IsFalse(TryParseAxisLimit('', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_Garbage;
var
  V: Single;
begin
  Assert.IsFalse(TryParseAxisLimit('abc', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_HalfTypedExponent;
var
  V: Single;
begin
  // What the old OnChange handler saw after the second keystroke of '1e-8'.
  Assert.IsFalse(TryParseAxisLimit('1e', AXIS_MAX, V));
  Assert.IsFalse(TryParseAxisLimit('1e-', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_Zero;
var
  V: Single;
begin
  // A logarithmic axis cannot show zero.
  Assert.IsFalse(TryParseAxisLimit('0', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_Negative;
var
  V: Single;
begin
  Assert.IsFalse(TryParseAxisLimit('-1E-8', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_AtAxisMaximum;
var
  V: Single;
begin
  // Minimum = Maximum leaves the axis with no range.
  Assert.IsFalse(TryParseAxisLimit('1', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_AboveAxisMaximum;
var
  V: Single;
begin
  // The first keystroke of '5E-7' on the old handler.
  Assert.IsFalse(TryParseAxisLimit('5', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Reject_UnderflowsSingle;
var
  V: Single;
begin
  // Parses as a Double but collapses to zero once stored in a Single.
  Assert.IsFalse(TryParseAxisLimit('1E-300', AXIS_MAX, V));
end;

procedure TTestAxisLimit.Test_Format_WholeMantissa;
begin
  Assert.AreEqual('1E-8', AxisLimitToText(1E-8));
end;

procedure TTestAxisLimit.Test_Format_FractionalMantissa;
begin
  Assert.AreEqual('3.5E-8', AxisLimitToText(3.5E-8));
end;

procedure TTestAxisLimit.Test_Format_Default;
begin
  Assert.AreEqual(DEFAULT_AXIS_LIMIT_TEXT, AxisLimitToText(DEFAULT_AXIS_LIMIT));
end;

procedure TTestAxisLimit.Test_ListItems_AllParseAndRoundTrip;
var
  i: Integer;
  V: Single;
begin
  for i := Low(AXIS_LIMIT_ITEMS) to High(AXIS_LIMIT_ITEMS) do
  begin
    Assert.IsTrue(TryParseAxisLimit(AXIS_LIMIT_ITEMS[i], AXIS_MAX, V),
      AXIS_LIMIT_ITEMS[i] + ' parses');
    Assert.AreEqual(AXIS_LIMIT_ITEMS[i], AxisLimitToText(V),
      AXIS_LIMIT_ITEMS[i] + ' round-trips');
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestAxisLimit);

end.
