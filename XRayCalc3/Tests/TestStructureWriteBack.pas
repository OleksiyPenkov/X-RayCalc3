unit TestStructureWriteBack;

(* Writing a fit result back into the structure panel.

   The irregular engine (TLFPSO_Irregular) flattens the model into ONE stack
   holding every physical layer, repeats expanded; UpdateInterfaceNP walks that
   flattened stack. The periodic and poly engines keep the model's own shape;
   UpdateInterfaceP walks it stack by stack.

   A non-periodic model (every stack N = 1) fitted with the periodic engine -
   which is what the GUI runs when [FIT] Mode = 1, and what every fit_xrr job
   writes - therefore comes back in the model's own shape and must go through
   UpdateInterfaceP. Handing it to UpdateInterfaceNP reads Stacks[0] past its
   single layer: an access violation in Release, or zeroed layers and a curve
   for the bare substrate. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestStructureWriteBack = class
  public
    [Test] procedure PeriodicShape_NonPeriodicModel_WritesBackStackByStack;
    [Test] procedure UpdateInterfaceNP_RejectsResultThatIsNotFlattened;
    [Test] procedure UpdateInterfaceNP_TakesTheFlattenedShape;
  end;

implementation

uses
  System.SysUtils, Vcl.Forms,
  unit_Types, unit_XRCStructure;

const
  { Three single-layer stacks on SiO2, as the MCP saved the accepted fit. }
  MODEL =
    '{"Stacks":[' +
      '{"T":"Main","N":1,"Layers":[{"M":"C","H":11.8,"s":4.8,"r":2.6}]},' +
      '{"T":"Main","N":1,"Layers":[{"M":"CoO","H":17.1,"s":6.5,"r":4.9}]},' +
      '{"T":"Main","N":1,"Layers":[{"M":"Co","H":289.9,"s":5.7,"r":8.8}]}],' +
     '"Subs":{"M":"SiO2","s":3.8,"r":2.65}}';

function Build(Host: TForm): TXRCStructure;
begin
  Result := TXRCStructure.Create(Host, 96);
  Result.Parent := Host;
  Result.FromString(MODEL);
end;

procedure TTestStructureWriteBack.PeriodicShape_NonPeriodicModel_WritesBackStackByStack;
var
  Host: TForm;
  S: TXRCStructure;
  Res: TFitStructure;
begin
  Host := TForm.CreateNew(nil);
  try
    S := Build(Host);
    Res := S.ToFitStructure;                 // the periodic engine's shape
    Assert.AreEqual(3, Length(Res.Stacks));
    Res.Stacks[2].Layers[0].P[1].V := 300;
    Res.Stacks[1].Layers[0].P[3].V := 5.5;

    S.UpdateInterfaceP(Res, True);

    Assert.AreEqual(300, S.Stacks[2].LayerData[0].P[1].V, 0.001, 'Co thickness');
    Assert.AreEqual(5.5, S.Stacks[1].LayerData[0].P[3].V, 0.001, 'CoO density');
    Assert.AreEqual('C', S.Stacks[0].LayerData[0].Material);
  finally
    Host.Free;
  end;
end;

procedure TTestStructureWriteBack.UpdateInterfaceNP_RejectsResultThatIsNotFlattened;
var
  Host: TForm;
  S: TXRCStructure;
  Res: TFitStructure;
begin
  Host := TForm.CreateNew(nil);
  try
    S := Build(Host);
    Res := S.ToFitStructure;                 // three stacks, not one
    Assert.WillRaise(
      procedure begin S.UpdateInterfaceNP(Res, True); end,
      EArgumentException);
  finally
    Host.Free;
  end;
end;

procedure TTestStructureWriteBack.UpdateInterfaceNP_TakesTheFlattenedShape;
var
  Host: TForm;
  S: TXRCStructure;
  Own, Flat: TFitStructure;
  i: Integer;
begin
  Host := TForm.CreateNew(nil);
  try
    S := Build(Host);
    Own := S.ToFitStructure;
    { What TLFPSO_Irregular.SetStructure makes of it: one stack, N = 1, the
      three layers in order. }
    SetLength(Flat.Stacks, 1);
    Flat.Stacks[0].N := 1;
    SetLength(Flat.Stacks[0].Layers, 3);
    for i := 0 to 2 do
      Flat.Stacks[0].Layers[i] := Own.Stacks[i].Layers[0];
    Flat.Subs := Own.Subs;
    Flat.Stacks[0].Layers[2].P[1].V := 300;

    S.UpdateInterfaceNP(Flat, True);

    Assert.AreEqual(300, S.Stacks[2].LayerData[0].P[1].V, 0.001, 'Co thickness');
    Assert.AreEqual('CoO', S.Stacks[1].LayerData[0].Material);
  finally
    Host.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStructureWriteBack);

end.
