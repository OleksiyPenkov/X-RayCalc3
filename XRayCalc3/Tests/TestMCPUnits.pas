unit TestMCPUnits;

interface

uses DUnitX.TestFramework, System.SysUtils, System.Math, System.JSON, unit_MCPUnits, unit_MCPErrors;

type
  [TestFixture]
  TTestMCPUnits = class
  public
    [Test] procedure EnergyToLambda_CuKa;
    [Test] procedure LambdaToEnergy_RoundTrip;
    [Test] procedure EnergyToLambda_Zero_Raises;
    [Test] procedure GetLambdaArg_LambdaOnly;
    [Test] procedure GetLambdaArg_EnergyOnly;
    [Test] procedure GetLambdaArg_Both_Raises;
    [Test] procedure GetLambdaArg_Neither_Raises;
    [Test] procedure GetLambdaArg_Neither_Default_WhenAllowed;
    [Test] procedure TwoThetaToTheta_Halves;
  end;

  /// JSONArgs.Num: six significant digits for any finite magnitude. The
  /// fit result puts profile polynomial coefficients and residuals through
  /// it, and a cubic term of 1e-17 is an ordinary value there.
  [TestFixture]
  TTestJSONArgsNum = class
  private
    function NumOf(const V: Double): Double;
  public
    [Test] procedure Num_Tiny_DoesNotRaise;
    [Test] procedure Num_TinyNegative_DoesNotRaise;
    [Test] procedure Num_Huge_DoesNotRaise;
    [Test] procedure Num_Denormal_DoesNotRaise;
    [Test] procedure Num_SixSignificantDigits;
    [Test] procedure Num_Integer_StaysInteger;
    [Test] procedure Num_NaN_IsZero;
    [Test] procedure NumArr_Tiny_DoesNotRaise;
  end;

implementation

procedure TTestMCPUnits.EnergyToLambda_CuKa;
begin
  // Cu Kalpha: 8047.8 eV is 1.5406 A
  Assert.AreEqual(1.5406, EnergyToLambda(8047.8), 0.0002);
end;

procedure TTestMCPUnits.LambdaToEnergy_RoundTrip;
begin
  Assert.AreEqual(9.89, EnergyToLambda(LambdaToEnergy(9.89)), 1e-9);
end;

procedure TTestMCPUnits.EnergyToLambda_Zero_Raises;
begin
  Assert.WillRaise(procedure begin EnergyToLambda(0); end, EMCPError);
end;

procedure TTestMCPUnits.GetLambdaArg_LambdaOnly;
var
  P: TJSONObject;
begin
  P := TJSONObject.Create;
  try
    P.AddPair('lambda', TJSONNumber.Create(1.54));
    Assert.AreEqual(1.54, GetLambdaArg(P), 1e-12);
  finally
    P.Free;
  end;
end;

procedure TTestMCPUnits.GetLambdaArg_EnergyOnly;
var
  P: TJSONObject;
begin
  P := TJSONObject.Create;
  try
    P.AddPair('energy', TJSONNumber.Create(8047.8));
    Assert.AreEqual(1.5406, GetLambdaArg(P), 0.0002);
  finally
    P.Free;
  end;
end;

procedure TTestMCPUnits.GetLambdaArg_Both_Raises;
var
  P: TJSONObject;
begin
  P := TJSONObject.Create;
  try
    P.AddPair('lambda', TJSONNumber.Create(1.54));
    P.AddPair('energy', TJSONNumber.Create(8047.8));
    try
      GetLambdaArg(P);
      Assert.Fail('"lambda" and "energy" together must be refused');
    except
      on E: EMCPError do
        Assert.AreEqual('invalid_argument', E.Code);
    end;
  finally
    P.Free;
  end;
end;

procedure TTestMCPUnits.GetLambdaArg_Neither_Raises;
var
  P: TJSONObject;
begin
  P := TJSONObject.Create;
  try
    Assert.WillRaise(procedure begin GetLambdaArg(P); end, EMCPError);
  finally
    P.Free;
  end;
end;

procedure TTestMCPUnits.GetLambdaArg_Neither_Default_WhenAllowed;
var
  P: TJSONObject;
begin
  P := TJSONObject.Create;
  try
    Assert.AreEqual(1.234, GetLambdaArg(P, 'lambda', 'energy', True, 1.234), 1e-12);
  finally
    P.Free;
  end;
end;

procedure TTestMCPUnits.TwoThetaToTheta_Halves;
begin
  Assert.AreEqual(1.25, TwoThetaToTheta(2.5), 1e-12);
end;

{ TTestJSONArgsNum }

function TTestJSONArgsNum.NumOf(const V: Double): Double;
var
  N: TJSONNumber;
begin
  N := JSONArgs.Num(V);
  try
    Result := N.AsDouble;
  finally
    N.Free;
  end;
end;

procedure TTestJSONArgsNum.Num_Tiny_DoesNotRaise;
begin
  // Below 1e-15 the old code asked RoundTo for more than 20 decimals, which
  // System.Math refuses with a bare EArgumentException ('Invalid argument').
  Assert.AreEqual(1.5e-17, NumOf(1.5e-17), 1.5e-17 * 1e-5);
end;

procedure TTestJSONArgsNum.Num_TinyNegative_DoesNotRaise;
begin
  Assert.AreEqual(-4.2e-21, NumOf(-4.2e-21), 4.2e-21 * 1e-5);
end;

procedure TTestJSONArgsNum.Num_Huge_DoesNotRaise;
begin
  Assert.AreEqual(2.5e30, NumOf(2.5e30), 2.5e30 * 1e-5);
end;

procedure TTestJSONArgsNum.Num_Denormal_DoesNotRaise;
begin
  // A denormal is finite and non-zero; it must come back as some finite number.
  Assert.IsFalse(IsInfinite(NumOf(5e-320)));
  Assert.IsFalse(IsNan(NumOf(5e-320)));
end;

procedure TTestJSONArgsNum.Num_SixSignificantDigits;
begin
  Assert.AreEqual(1.23457, NumOf(1.23456789), 1e-9);
  Assert.AreEqual(123457000.0, NumOf(123456789.5), 1e-3);
  Assert.AreEqual(0.00123457, NumOf(0.001234567891), 1e-12);
end;

procedure TTestJSONArgsNum.Num_Integer_StaysInteger;
var
  N: TJSONNumber;
begin
  N := JSONArgs.Num(3.0);
  try
    Assert.AreEqual('3', N.ToJSON);
  finally
    N.Free;
  end;
end;

procedure TTestJSONArgsNum.Num_NaN_IsZero;
begin
  Assert.AreEqual(0.0, NumOf(NaN), 0);
end;

procedure TTestJSONArgsNum.NumArr_Tiny_DoesNotRaise;
var
  A: TJSONArray;
begin
  A := JSONArgs.NumArr(TArray<Double>.Create(1.0, 1e-18, -3e-25));
  try
    Assert.AreEqual(3, A.Count);
    Assert.AreEqual(1e-18, TJSONNumber(A.Items[1]).AsDouble, 1e-23);
  finally
    A.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPUnits);
  TDUnitX.RegisterTestFixture(TTestJSONArgsNum);
end.
