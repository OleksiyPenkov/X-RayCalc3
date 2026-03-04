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
    [Test] procedure Test_NegativeHMin_ReturnsError;
    [Test] procedure Test_NegativeSMin_ReturnsError;
    [Test] procedure Test_NegativeRhoMin_ReturnsError;
    [Test] procedure Test_RhoMaxExceedsDensity_ReturnsWarning;
    [Test] procedure Test_ClampToPhysics_CorrectsNegatives;
    [Test] procedure Test_ClampToPhysics_CapsRhoMax;
    [Test] procedure Test_ClampToPhysics_NoOpOnValid;
    [Test] procedure Test_ApplyDensity_FillsZeroV;
    [Test] procedure Test_ApplyDensity_NoOverrideNonZeroV;
    [Test] procedure Test_ApplyDensity_SkipsZeroNro;
    [Test] procedure Test_ApplyDensity_LeavesHAndSUntouched;
    [Test] procedure Test_Geometry_SMaxCappedByOwnH;
    [Test] procedure Test_Geometry_SMaxCappedByLowerNeighbor;
    [Test] procedure Test_Geometry_NoOpWhenWithinBounds;
    [Test] procedure Test_Geometry_PeriodicWrap;
    [Test] procedure Test_Geometry_HAndRhoUntouched;
    [Test] procedure Test_Narrow_HalvesRange;
    [Test] procedure Test_Narrow_VAtLowerLimit;
    [Test] procedure Test_Narrow_VAtUpperLimit;
    [Test] procedure Test_Narrow_SkipsLocked;
    [Test] procedure Test_Validate_AtLowerLimit;
    [Test] procedure Test_Validate_AtUpperLimit;
    [Test] procedure Test_Validate_NotAtLimit;
    [Test] procedure Test_Widen_AtLowerLimit;
    [Test] procedure Test_Widen_AtUpperLimit;
    [Test] procedure Test_Widen_SkipsNotAtLimit;
    [Test] procedure Test_Widen_SkipsLocked;
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

procedure TTestValidateLimits.Test_NegativeHMin_ReturnsError;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].min := -5.0;

  Issues := ValidateLimits(FS);
  Assert.IsTrue(HasErrors(Issues));

  Found := False;
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 1) and (Issues[i].Kind = likError) and
       (Pos('H min is negative', Issues[i].Message) > 0) then
      Found := True;
  Assert.IsTrue(Found, 'Expected "H min is negative" error');
end;

procedure TTestValidateLimits.Test_NegativeSMin_ReturnsError;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[2].min := -3.0;

  Issues := ValidateLimits(FS);
  Assert.IsTrue(HasErrors(Issues));

  Found := False;
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 2) and (Issues[i].Kind = likError) and
       (Pos('S min is negative', Issues[i].Message) > 0) then
      Found := True;
  Assert.IsTrue(Found, 'Expected "S min is negative" error');
end;

procedure TTestValidateLimits.Test_NegativeRhoMin_ReturnsError;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[3].min := -1.0;

  Issues := ValidateLimits(FS);
  Assert.IsTrue(HasErrors(Issues));

  Found := False;
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 3) and (Issues[i].Kind = likError) and
       (Pos('Rho min is negative', Issues[i].Message) > 0) then
      Found := True;
  Assert.IsTrue(Found, 'Expected "Rho min is negative" error');
end;

procedure TTestValidateLimits.Test_RhoMaxExceedsDensity_ReturnsWarning;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[3].V := 20.0;
  FS.Stacks[0].Layers[0].P[3].min := 15.0;
  FS.Stacks[0].Layers[0].P[3].max := 30.0;

  Issues := ValidateLimits(FS);

  Found := False;
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 3) and (Issues[i].Kind = likWarning) and
       (Pos('Rho max exceeds densest element', Issues[i].Message) > 0) then
      Found := True;
  Assert.IsTrue(Found, 'Expected "Rho max exceeds densest element" warning');
end;

procedure TTestValidateLimits.Test_ClampToPhysics_CorrectsNegatives;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  // Set negative mins and values below them
  FS.Stacks[0].Layers[0].P[1].V := -2.0;
  FS.Stacks[0].Layers[0].P[1].min := -5.0;
  FS.Stacks[0].Layers[0].P[2].V := -1.0;
  FS.Stacks[0].Layers[0].P[2].min := -3.0;
  FS.Stacks[0].Layers[0].P[3].V := -0.5;
  FS.Stacks[0].Layers[0].P[3].min := -1.0;

  ClampToPhysics(FS);

  // Mins clamped to 0
  Assert.AreEqual(Single(0.0), FS.Stacks[0].Layers[0].P[1].min, 'H min should be 0');
  Assert.AreEqual(Single(0.0), FS.Stacks[0].Layers[0].P[2].min, 'S min should be 0');
  Assert.AreEqual(Single(0.0), FS.Stacks[0].Layers[0].P[3].min, 'Rho min should be 0');
  // Values adjusted to min
  Assert.AreEqual(Single(0.0), FS.Stacks[0].Layers[0].P[1].V, 'H value should be clamped to min');
  Assert.AreEqual(Single(0.0), FS.Stacks[0].Layers[0].P[2].V, 'S value should be clamped to min');
  Assert.AreEqual(Single(0.0), FS.Stacks[0].Layers[0].P[3].V, 'Rho value should be clamped to min');
end;

procedure TTestValidateLimits.Test_ClampToPhysics_CapsRhoMax;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[3].V := 25.0;
  FS.Stacks[0].Layers[0].P[3].min := 10.0;
  FS.Stacks[0].Layers[0].P[3].max := 50.0;

  ClampToPhysics(FS);

  Assert.AreEqual(Single(MAX_DENSITY), FS.Stacks[0].Layers[0].P[3].max, 'Rho max should be capped to MAX_DENSITY');
  Assert.AreEqual(Single(MAX_DENSITY), FS.Stacks[0].Layers[0].P[3].V, 'Rho value should be clamped to max');
end;

procedure TTestValidateLimits.Test_ClampToPhysics_NoOpOnValid;
var
  FS, Original: TFitStructure;
  p: Integer;
begin
  FS := MakeStructure(1);
  Original := MakeStructure(1);

  ClampToPhysics(FS);

  for p := 1 to 3 do
  begin
    Assert.AreEqual(Original.Stacks[0].Layers[0].P[p].V, FS.Stacks[0].Layers[0].P[p].V,
      Format('P[%d].V should be unchanged', [p]));
    Assert.AreEqual(Original.Stacks[0].Layers[0].P[p].min, FS.Stacks[0].Layers[0].P[p].min,
      Format('P[%d].min should be unchanged', [p]));
    Assert.AreEqual(Original.Stacks[0].Layers[0].P[p].max, FS.Stacks[0].Layers[0].P[p].max,
      Format('P[%d].max should be unchanged', [p]));
  end;
end;

procedure TTestValidateLimits.Test_ApplyDensity_FillsZeroV;
var
  FS: TFitStructure;
  Nro: array of Single;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[3].V := 0;

  SetLength(Nro, 1);
  Nro[0] := 2.329;

  ApplyMaterialDensity(FS, Nro);
  Assert.AreEqual(Single(2.329), FS.Stacks[0].Layers[0].P[3].V,
    'V=0 should be filled with Henke Nro');
end;

procedure TTestValidateLimits.Test_ApplyDensity_NoOverrideNonZeroV;
var
  FS: TFitStructure;
  Nro: array of Single;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[3].V := 5.0;

  SetLength(Nro, 1);
  Nro[0] := 2.329;

  ApplyMaterialDensity(FS, Nro);
  Assert.AreEqual(Single(5.0), FS.Stacks[0].Layers[0].P[3].V,
    'Non-zero V should not be overridden');
end;

procedure TTestValidateLimits.Test_ApplyDensity_SkipsZeroNro;
var
  FS: TFitStructure;
  Nro: array of Single;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[3].V := 0;

  SetLength(Nro, 1);
  Nro[0] := 0;

  ApplyMaterialDensity(FS, Nro);
  Assert.AreEqual(Single(0), FS.Stacks[0].Layers[0].P[3].V,
    'V should stay 0 when Nro is 0 (unknown material)');
end;

procedure TTestValidateLimits.Test_ApplyDensity_LeavesHAndSUntouched;
var
  FS: TFitStructure;
  Nro: array of Single;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 7.5;   // H
  FS.Stacks[0].Layers[0].P[2].V := 3.0;   // S
  FS.Stacks[0].Layers[0].P[3].V := 0;     // Rho = sentinel

  SetLength(Nro, 1);
  Nro[0] := 2.329;

  ApplyMaterialDensity(FS, Nro);
  Assert.AreEqual(Single(7.5), FS.Stacks[0].Layers[0].P[1].V,
    'H should not be changed');
  Assert.AreEqual(Single(3.0), FS.Stacks[0].Layers[0].P[2].V,
    'S should not be changed');
end;

procedure TTestValidateLimits.Test_Geometry_SMaxCappedByOwnH;
var
  FS: TFitStructure;
begin
  // Single layer, non-periodic: S.max should be capped by own H
  FS := MakeStructure(1);
  FS.Stacks[0].N := 1;
  FS.Stacks[0].Layers[0].P[1].V := 10.0;   // H = 10
  FS.Stacks[0].Layers[0].P[2].max := 20.0;  // S.max = 20

  ApplyGeometryCoupling(FS);

  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[2].max,
    'S.max should be capped to own H (10)');
end;

procedure TTestValidateLimits.Test_Geometry_SMaxCappedByLowerNeighbor;
var
  FS: TFitStructure;
begin
  // Two layers: Layer[1].S.max capped by Layer[0].H
  FS := MakeStructure(2);
  FS.Stacks[0].N := 1;
  FS.Stacks[0].Layers[0].P[1].V := 8.0;    // Layer[0].H = 8
  FS.Stacks[0].Layers[1].P[1].V := 20.0;   // Layer[1].H = 20
  FS.Stacks[0].Layers[1].P[2].max := 15.0;  // Layer[1].S.max = 15

  ApplyGeometryCoupling(FS);

  Assert.AreEqual(Single(8.0), FS.Stacks[0].Layers[1].P[2].max,
    'S.max should be capped to lower neighbor H (8)');
end;

procedure TTestValidateLimits.Test_Geometry_NoOpWhenWithinBounds;
var
  FS: TFitStructure;
begin
  // S.max already within bounds — should not be modified
  FS := MakeStructure(2);
  FS.Stacks[0].N := 1;
  FS.Stacks[0].Layers[0].P[1].V := 12.0;   // Layer[0].H = 12
  FS.Stacks[0].Layers[1].P[1].V := 10.0;   // Layer[1].H = 10
  FS.Stacks[0].Layers[1].P[2].max := 5.0;   // S.max = 5, already < min(10, 12)

  ApplyGeometryCoupling(FS);

  Assert.AreEqual(Single(5.0), FS.Stacks[0].Layers[1].P[2].max,
    'S.max should remain 5 (already within bounds)');
end;

procedure TTestValidateLimits.Test_Geometry_PeriodicWrap;
var
  FS: TFitStructure;
begin
  // Periodic stack (N > 1): first layer wraps to last layer's H
  FS := MakeStructure(2);
  FS.Stacks[0].N := 5;  // periodic
  FS.Stacks[0].Layers[0].P[1].V := 30.0;   // Layer[0].H = 30
  FS.Stacks[0].Layers[0].P[2].max := 25.0;  // Layer[0].S.max = 25
  FS.Stacks[0].Layers[1].P[1].V := 7.0;    // Layer[1].H = 7 (last layer, wraps)

  ApplyGeometryCoupling(FS);

  // Layer[0]: H_self=30, H_below=Layer[1].H=7 (wrap), Bound=7
  Assert.AreEqual(Single(7.0), FS.Stacks[0].Layers[0].P[2].max,
    'S.max should be capped to last layer H via periodic wrap (7)');
end;

procedure TTestValidateLimits.Test_Geometry_HAndRhoUntouched;
var
  FS: TFitStructure;
begin
  // Verify that ApplyGeometryCoupling only modifies P[2].max
  FS := MakeStructure(1);
  FS.Stacks[0].N := 1;
  FS.Stacks[0].Layers[0].P[1].V := 10.0;
  FS.Stacks[0].Layers[0].P[1].min := 5.0;
  FS.Stacks[0].Layers[0].P[1].max := 20.0;
  FS.Stacks[0].Layers[0].P[2].V := 8.0;
  FS.Stacks[0].Layers[0].P[2].min := 3.0;
  FS.Stacks[0].Layers[0].P[2].max := 25.0;
  FS.Stacks[0].Layers[0].P[3].V := 5.0;
  FS.Stacks[0].Layers[0].P[3].min := 2.0;
  FS.Stacks[0].Layers[0].P[3].max := 15.0;

  ApplyGeometryCoupling(FS);

  // H limits untouched
  Assert.AreEqual(Single(5.0), FS.Stacks[0].Layers[0].P[1].min, 'H.min should be unchanged');
  Assert.AreEqual(Single(20.0), FS.Stacks[0].Layers[0].P[1].max, 'H.max should be unchanged');
  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[1].V, 'H.V should be unchanged');
  // Rho limits untouched
  Assert.AreEqual(Single(2.0), FS.Stacks[0].Layers[0].P[3].min, 'Rho.min should be unchanged');
  Assert.AreEqual(Single(15.0), FS.Stacks[0].Layers[0].P[3].max, 'Rho.max should be unchanged');
  Assert.AreEqual(Single(5.0), FS.Stacks[0].Layers[0].P[3].V, 'Rho.V should be unchanged');
  // S.min and S.V untouched (only S.max modified)
  Assert.AreEqual(Single(3.0), FS.Stacks[0].Layers[0].P[2].min, 'S.min should be unchanged');
  Assert.AreEqual(Single(8.0), FS.Stacks[0].Layers[0].P[2].V, 'S.V should be unchanged');
end;

procedure TTestValidateLimits.Test_Narrow_HalvesRange;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 50.0;
  FS.Stacks[0].Layers[0].P[1].min := 30.0;
  FS.Stacks[0].Layers[0].P[1].max := 70.0;

  NarrowLimits(FS, 0.5);

  Assert.AreEqual(Single(40.0), FS.Stacks[0].Layers[0].P[1].min, 'min should narrow to 40');
  Assert.AreEqual(Single(60.0), FS.Stacks[0].Layers[0].P[1].max, 'max should narrow to 60');
end;

procedure TTestValidateLimits.Test_Narrow_VAtLowerLimit;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 30.0;   // V == min
  FS.Stacks[0].Layers[0].P[1].min := 30.0;
  FS.Stacks[0].Layers[0].P[1].max := 70.0;

  NarrowLimits(FS, 0.5);

  Assert.AreEqual(Single(30.0), FS.Stacks[0].Layers[0].P[1].min, 'min should stay at 30');
  Assert.AreEqual(Single(50.0), FS.Stacks[0].Layers[0].P[1].max, 'max should narrow to 50');
end;

procedure TTestValidateLimits.Test_Narrow_VAtUpperLimit;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 70.0;   // V == max
  FS.Stacks[0].Layers[0].P[1].min := 30.0;
  FS.Stacks[0].Layers[0].P[1].max := 70.0;

  NarrowLimits(FS, 0.5);

  Assert.AreEqual(Single(50.0), FS.Stacks[0].Layers[0].P[1].min, 'min should narrow to 50');
  Assert.AreEqual(Single(70.0), FS.Stacks[0].Layers[0].P[1].max, 'max should stay at 70');
end;

procedure TTestValidateLimits.Test_Narrow_SkipsLocked;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 10.0;
  FS.Stacks[0].Layers[0].P[1].min := 10.0;
  FS.Stacks[0].Layers[0].P[1].max := 10.0;

  NarrowLimits(FS, 0.5);

  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[1].min, 'locked min should be unchanged');
  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[1].max, 'locked max should be unchanged');
end;

procedure TTestValidateLimits.Test_Validate_AtLowerLimit;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  // V at lower limit: V = min
  FS.Stacks[0].Layers[0].P[1].V := 5.0;
  FS.Stacks[0].Layers[0].P[1].min := 5.0;
  FS.Stacks[0].Layers[0].P[1].max := 15.0;

  Issues := ValidateLimits(FS);
  Found := False;
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 1) and (Pos('at lower limit', Issues[i].Message) > 0) then
      Found := True;
  Assert.IsTrue(Found, 'Expected "value at lower limit" warning');
end;

procedure TTestValidateLimits.Test_Validate_AtUpperLimit;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
  Found: Boolean;
begin
  FS := MakeStructure(1);
  // V at upper limit: V = max
  FS.Stacks[0].Layers[0].P[1].V := 15.0;
  FS.Stacks[0].Layers[0].P[1].min := 5.0;
  FS.Stacks[0].Layers[0].P[1].max := 15.0;

  Issues := ValidateLimits(FS);
  Found := False;
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 1) and (Pos('at upper limit', Issues[i].Message) > 0) then
      Found := True;
  Assert.IsTrue(Found, 'Expected "value at upper limit" warning');
end;

procedure TTestValidateLimits.Test_Validate_NotAtLimit;
var
  FS: TFitStructure;
  Issues: TArray<TLimitIssue>;
  i: Integer;
begin
  FS := MakeStructure(1);
  // V at center — no "at limit" warnings expected
  FS.Stacks[0].Layers[0].P[1].V := 10.0;
  FS.Stacks[0].Layers[0].P[1].min := 5.0;
  FS.Stacks[0].Layers[0].P[1].max := 15.0;

  Issues := ValidateLimits(FS);
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 1) and (Pos('at lower limit', Issues[i].Message) > 0) then
      Assert.Fail('Unexpected "value at lower limit" warning');
  for i := 0 to High(Issues) do
    if (Issues[i].ParamIndex = 1) and (Pos('at upper limit', Issues[i].Message) > 0) then
      Assert.Fail('Unexpected "value at upper limit" warning');
  Assert.Pass;
end;

procedure TTestValidateLimits.Test_Widen_AtLowerLimit;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 30.0;   // V == min (at lower limit)
  FS.Stacks[0].Layers[0].P[1].min := 30.0;
  FS.Stacks[0].Layers[0].P[1].max := 70.0;

  WidenAtLimit(FS, 0.5);

  // Range=40, min extends by 40*0.5=20 downward
  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[1].min, 'min should widen to 10');
  Assert.AreEqual(Single(70.0), FS.Stacks[0].Layers[0].P[1].max, 'max should stay at 70');
end;

procedure TTestValidateLimits.Test_Widen_AtUpperLimit;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 70.0;   // V == max (at upper limit)
  FS.Stacks[0].Layers[0].P[1].min := 30.0;
  FS.Stacks[0].Layers[0].P[1].max := 70.0;

  WidenAtLimit(FS, 0.5);

  // Range=40, max extends by 40*0.5=20 upward
  Assert.AreEqual(Single(30.0), FS.Stacks[0].Layers[0].P[1].min, 'min should stay at 30');
  Assert.AreEqual(Single(90.0), FS.Stacks[0].Layers[0].P[1].max, 'max should widen to 90');
end;

procedure TTestValidateLimits.Test_Widen_SkipsNotAtLimit;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 50.0;   // V at center
  FS.Stacks[0].Layers[0].P[1].min := 30.0;
  FS.Stacks[0].Layers[0].P[1].max := 70.0;

  WidenAtLimit(FS, 0.5);

  Assert.AreEqual(Single(30.0), FS.Stacks[0].Layers[0].P[1].min, 'min should be unchanged');
  Assert.AreEqual(Single(70.0), FS.Stacks[0].Layers[0].P[1].max, 'max should be unchanged');
end;

procedure TTestValidateLimits.Test_Widen_SkipsLocked;
var
  FS: TFitStructure;
begin
  FS := MakeStructure(1);
  FS.Stacks[0].Layers[0].P[1].V := 10.0;
  FS.Stacks[0].Layers[0].P[1].min := 10.0;
  FS.Stacks[0].Layers[0].P[1].max := 10.0;

  WidenAtLimit(FS, 0.5);

  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[1].min, 'locked min should be unchanged');
  Assert.AreEqual(Single(10.0), FS.Stacks[0].Layers[0].P[1].max, 'locked max should be unchanged');
end;

end.
