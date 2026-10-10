unit TestLayerControl;


interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestLayerControl = class
  public
    [Test] procedure Data_RefreshesMaterialCaption;
    [Test] procedure Data_RefreshesSubstrateMaterialCaption;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms,
  unit_Types, unit_XRCLayerControl;

function LayerOf(const Material: string; const Thickness: Single): TLayerData;
begin
  FillChar(Result, SizeOf(Result), 0);
  Result.Material := Material;
  Result.P[1].V := Thickness;
  Result.P[2].V := 0.5;
  Result.P[3].V := 2.33;
end;

procedure TTestLayerControl.Data_RefreshesMaterialCaption;
var
  Host: TForm;
  Card: TXRCLayerControl;
begin
  Host := TForm.CreateNew(nil);
  try
    Card := TXRCLayerControl.Create(Host, 0, LayerOf('Si', 10), 96);
    Assert.AreEqual('Si', Card.MaterialCaption);

    Card.Data := LayerOf('SiO2', 10);

    Assert.AreEqual('SiO2', Card.MaterialCaption);
    Assert.AreEqual('SiO2', Card.Data.Material);
  finally
    Host.Free;
  end;
end;

procedure TTestLayerControl.Data_RefreshesSubstrateMaterialCaption;
var
  Host: TForm;
  Card: TXRCLayerControl;
begin
  Host := TForm.CreateNew(nil);
  try
    Card := TXRCLayerControl.Create(Host, 0, LayerOf('Si', 1E8), 96);
    Card.Substrate := True;

    Card.Data := LayerOf('SiO2', 1E8);

    Assert.AreEqual('SiO2', Card.MaterialCaption);
  finally
    Host.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestLayerControl);

end.
