unit TestMCPUnits;

interface

uses DUnitX.TestFramework, System.SysUtils, System.JSON, unit_MCPUnits, unit_MCPErrors;

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

initialization
  TDUnitX.RegisterTestFixture(TTestMCPUnits);
end.
