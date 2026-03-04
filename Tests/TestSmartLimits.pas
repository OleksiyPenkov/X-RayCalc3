unit TestSmartLimits;

interface

uses
  DUnitX.TestFramework,
  unit_Types, unit_SmartLimits;

type
  [TestFixture]
  TTestValidateLimits = class
  private
    function MakeStructure(LayerCount: Integer): TFitStructure;
  public
    [Test] procedure Test_ValidLimits_NoIssues;
    [Test] procedure Test_MinGreaterThanMax_ReturnsError;
    [Test] procedure Test_ValueOutsideBounds_ReturnsWarnings;
    [Test] procedure Test_AllLocked_ReturnsWarning;
    [Test] procedure Test_RangeTooWide_ReturnsWarning;
    [Test] procedure Test_RangeTooNarrow_ReturnsWarning;
    [Test] procedure Test_MixedIssues;
    [Test] procedure Test_HasErrors_HasWarnings;
    [Test] procedure Test_CellState_Mapping;
  end;

implementation

uses
  System.SysUtils;

function TTestValidateLimits.MakeStructure(LayerCount: Integer): TFitStructure;
var
  j, p: Integer;
begin
  SetLength(Result.Stacks, 1);
  Result.Stacks[0].Header := 'Stack 1';
  SetLength(Result.Stacks[0].Layers, LayerCount);
  for j := 0 to LayerCount - 1 do
  begin
    Result.Stacks[0].Layers[j].Material := 'Layer' + IntToStr(j);
    for p := 1 to 3 do
    begin
      Result.Stacks[0].Layers[j].P[p].V := 10.0;
      Result.Stacks[0].Layers[j].P[p].min := 5.0;
      Result.Stacks[0].Layers[j].P[p].max := 15.0;
    end;
  end;
end;

procedure TTestValidateLimits.Test_ValidLimits_NoIssues;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
begin
  FS := MakeStructure(2);
  Issues := ValidateLimits(FS);
  Assert.AreEqual(0, Length(Issues));
end;

procedure TTestValidateLimits.Test_MinGreaterThanMax_ReturnsError;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
begin
  FS := MakeStructure(1);
  // H: min > max
  FS.Stacks[0].Layers[0].P[1].min := 20.0;
  FS.Stacks[0].Layers[0].P[1].max := 5.0;

  Issues := ValidateLimits(FS);
  Assert.IsTrue(HasErrors(Issues));

  // Check that the error targets the correct layer and param
  Assert.AreEqual(0, Issues[0].ItemIndex);
  Assert.AreEqual(1, Issues[0].ParamIndex);
  Assert.AreEqual(TLimitIssueKind.likError, Issues[0].Kind);
  Assert.Contains(Issues[0].Message, 'H min > max');
end;

procedure TTestValidateLimits.Test_ValueOutsideBounds_ReturnsWarnings;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  FoundBelow, FoundAbove: Boolean;
begin
  FS := MakeStructure(1);
  // H: value below min
  FS.Stacks[0].Layers[0].P[1].V := 2.0;
  FS.Stacks[0].Layers[0].P[1].min := 5.0;
  FS.Stacks[0].Layers[0].P[1].max := 15.0;
  // S: value above max
  FS.Stacks[0].Layers[0].P[2].V := 20.0;
  FS.Stacks[0].Layers[0].P[2].min := 5.0;
  FS.Stacks[0].Layers[0].P[2].max := 15.0;

  Issues := ValidateLimits(FS);
  Assert.IsFalse(HasErrors(Issues));
  Assert.IsTrue(HasWarnings(Issues));

  FoundBelow := False;
  FoundAbove := False;
  for i := 0 to High(Issues) do
  begin
    if (Issues[i].ParamIndex = 1) and (Pos('below min', Issues[i].Message) > 0) then
      FoundBelow := True;
    if (Issues[i].ParamIndex = 2) and (Pos('above max', Issues[i].Message) > 0) then
      FoundAbove := True;
  end;
  Assert.IsTrue(FoundBelow, 'Expected "value below min" warning for H');
  Assert.IsTrue(FoundAbove, 'Expected "value above max" warning for S');
end;

procedure TTestValidateLimits.Test_AllLocked_ReturnsWarning;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  p: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(2);
  // Lock all parameters: min = max
  for i := 0 to High(FS.Stacks[0].Layers) do
    for p := 1 to 3 do
    begin
      FS.Stacks[0].Layers[i].P[p].V := 10.0;
      FS.Stacks[0].Layers[i].P[p].min := 10.0;
      FS.Stacks[0].Layers[i].P[p].max := 10.0;
    end;

  Issues := ValidateLimits(FS);
  Assert.IsTrue(HasWarnings(Issues));

  Found := False;
  for i := 0 to High(Issues) do
    if Pos('nothing to fit', Issues[i].Message) > 0 then
      Found := True;
  Assert.IsTrue(Found, 'Expected "nothing to fit" warning');
end;

procedure TTestValidateLimits.Test_RangeTooWide_ReturnsWarning;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  // H: min=1, max=200 -> ratio 200 > 100
  FS.Stacks[0].Layers[0].P[1].V := 100.0;
  FS.Stacks[0].Layers[0].P[1].min := 1.0;
  FS.Stacks[0].Layers[0].P[1].max := 200.0;

  Issues := ValidateLimits(FS);
  Found := False;
  for i := 0 to High(Issues) do
    if Pos('range very wide', Issues[i].Message) > 0 then
      Found := True;
  Assert.IsTrue(Found, 'Expected "range very wide" warning');
end;

procedure TTestValidateLimits.Test_RangeTooNarrow_ReturnsWarning;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  // H: V=100, range = [99.999, 100.001] -> abs(max-min)=0.002, 0.01*100=1.0 -> narrow
  FS.Stacks[0].Layers[0].P[1].V := 100.0;
  FS.Stacks[0].Layers[0].P[1].min := 99.999;
  FS.Stacks[0].Layers[0].P[1].max := 100.001;

  Issues := ValidateLimits(FS);
  Found := False;
  for i := 0 to High(Issues) do
    if Pos('range very narrow', Issues[i].Message) > 0 then
      Found := True;
  Assert.IsTrue(Found, 'Expected "range very narrow" warning');
end;

procedure TTestValidateLimits.Test_MixedIssues;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
begin
  FS := MakeStructure(2);
  // Layer 0, H: min > max (error)
  FS.Stacks[0].Layers[0].P[1].min := 20.0;
  FS.Stacks[0].Layers[0].P[1].max := 5.0;
  // Layer 1, S: value below min (warning)
  FS.Stacks[0].Layers[1].P[2].V := 1.0;
  FS.Stacks[0].Layers[1].P[2].min := 5.0;
  FS.Stacks[0].Layers[1].P[2].max := 15.0;

  Issues := ValidateLimits(FS);
  Assert.IsTrue(HasErrors(Issues), 'Expected errors');
  Assert.IsTrue(HasWarnings(Issues), 'Expected warnings');
end;

procedure TTestValidateLimits.Test_HasErrors_HasWarnings;
var
  Issues: TArray<TLimitIssue>;
begin
  // Empty
  SetLength(Issues, 0);
  Assert.IsFalse(HasErrors(Issues));
  Assert.IsFalse(HasWarnings(Issues));

  // One error
  SetLength(Issues, 1);
  Issues[0].Kind := likError;
  Assert.IsTrue(HasErrors(Issues));
  Assert.IsFalse(HasWarnings(Issues));

  // One warning
  Issues[0].Kind := likWarning;
  Assert.IsFalse(HasErrors(Issues));
  Assert.IsTrue(HasWarnings(Issues));
end;

procedure TTestValidateLimits.Test_CellState_Mapping;
var
  Issues: TArray<TLimitIssue>;
begin
  SetLength(Issues, 2);
  // Error on item 0, param 1 (H)
  Issues[0].Kind := likError;
  Issues[0].ItemIndex := 0;
  Issues[0].ParamIndex := 1;
  // Warning on item 0, param 2 (S)
  Issues[1].Kind := likWarning;
  Issues[1].ItemIndex := 0;
  Issues[1].ParamIndex := 2;

  // SubItem 0,1 -> param 1 -> error
  Assert.AreEqual(TLimitIssueKind.likError, CellState(Issues, 0, 0));
  Assert.AreEqual(TLimitIssueKind.likError, CellState(Issues, 0, 1));
  // SubItem 2,3 -> param 2 -> warning
  Assert.AreEqual(TLimitIssueKind.likWarning, CellState(Issues, 0, 2));
  Assert.AreEqual(TLimitIssueKind.likWarning, CellState(Issues, 0, 3));
  // SubItem 4,5 -> param 3 -> no issue
  Assert.AreEqual(TLimitIssueKind.likNone, CellState(Issues, 0, 4));
  Assert.AreEqual(TLimitIssueKind.likNone, CellState(Issues, 0, 5));
  // Different item -> no issue
  Assert.AreEqual(TLimitIssueKind.likNone, CellState(Issues, 1, 0));
end;

end.
