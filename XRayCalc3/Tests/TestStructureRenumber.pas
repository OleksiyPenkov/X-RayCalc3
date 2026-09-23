unit TestStructureRenumber;

(* Layers addressed by (stack, layer) index.

   A gradient extension names its layer by index. When a layer or stack is
   inserted, deleted or moved, TXRCStructure.OnLayersRenumbered reports where
   every layer went, so the gradient can follow its layer rather than stay on
   the index and land on whichever layer takes its old place.

   Also here: the per-period table rule of TXRCStructure.Model, which the
   profile plots share (TLayerData.PeriodValue), and the table read back by
   FromString. *)

interface

uses
  DUnitX.TestFramework, Vcl.Forms,
  unit_Types, unit_XRCStructure;

type
  [TestFixture]
  TTestStructureRenumber = class
  private
    FHost: TForm;
    FMap: TLayerMap;
    FFired: Integer;
    procedure Renumbered(Sender: TObject; const Map: TLayerMap);
    function Build(const Json: string): TXRCStructure;
    procedure CheckPos(const Pos: TLayerPos; StackID, LayerID: Integer; const Msg: string);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure MoveLayer_SwapsTheTwoLayers;
    [Test] procedure DeleteLayer_DropsItAndShiftsTheRest;
    [Test] procedure InsertLayer_ShiftsTheLayersBelow;
    [Test] procedure InsertStack_ShiftsTheStacksBelow;
    [Test] procedure DeleteStack_DropsItsLayersAndShiftsTheRest;
    [Test] procedure MoveLayer_StaleIndices_DoNothing;
    [Test] procedure Model_ExpandsATableCoveringEveryPeriod;
    [Test] procedure Model_IgnoresATableShorterThanN;
    [Test] procedure FromString_LayerWithoutTable_KeepsNone;
  end;

implementation

uses
  System.SysUtils, unit_materials;

const
  { Two stacks: W/Si/C x 3, then Cr x 1, on Si. }
  MODEL =
    '{"Stacks":[' +
      '{"T":"ML","N":3,"Layers":[' +
        '{"M":"W","H":10,"s":3,"r":19.3},' +
        '{"M":"Si","H":20,"s":3,"r":2.33},' +
        '{"M":"C","H":5,"s":3,"r":2.2}]},' +
      '{"T":"Cap","N":1,"Layers":[{"M":"Cr","H":7,"s":3,"r":7.2}]}],' +
     '"Subs":{"M":"Si","s":3,"r":2.33}}';

procedure TTestStructureRenumber.Setup;
begin
  FHost := TForm.CreateNew(nil);
  FMap := nil;
  FFired := 0;
end;

procedure TTestStructureRenumber.TearDown;
begin
  FHost.Free;
end;

procedure TTestStructureRenumber.Renumbered(Sender: TObject; const Map: TLayerMap);
begin
  FMap := Map;
  Inc(FFired);
end;

function TTestStructureRenumber.Build(const Json: string): TXRCStructure;
begin
  Result := TXRCStructure.Create(FHost, 96);
  Result.Parent := FHost;
  Result.FromString(Json);
  Result.OnLayersRenumbered := Renumbered;
end;

procedure TTestStructureRenumber.CheckPos(const Pos: TLayerPos; StackID, LayerID: Integer;
  const Msg: string);
begin
  Assert.AreEqual(StackID, Pos.StackID, Msg + ': stack');
  Assert.AreEqual(LayerID, Pos.LayerID, Msg + ': layer');
end;

procedure TTestStructureRenumber.MoveLayer_SwapsTheTwoLayers;
var
  S: TXRCStructure;
begin
  S := Build(MODEL);
  S.MoveLayer(0, 0, 1);                        // W below Si

  Assert.AreEqual(1, FFired);
  Assert.AreEqual('Si', S.Stacks[0].LayerData[0].Material);
  CheckPos(FMap[0][0], 0, 1, 'W');
  CheckPos(FMap[0][1], 0, 0, 'Si');
  CheckPos(FMap[0][2], 0, 2, 'C');
  CheckPos(FMap[1][0], 1, 0, 'Cr');
end;

procedure TTestStructureRenumber.DeleteLayer_DropsItAndShiftsTheRest;
var
  S: TXRCStructure;
begin
  S := Build(MODEL);
  S.DeleteLayer(0, 0);                         // W

  Assert.AreEqual(1, FFired);
  CheckPos(FMap[0][0], -1, -1, 'W deleted');
  CheckPos(FMap[0][1], 0, 0, 'Si');
  CheckPos(FMap[0][2], 0, 1, 'C');
end;

procedure TTestStructureRenumber.InsertLayer_ShiftsTheLayersBelow;
var
  S: TXRCStructure;
  Data: TLayerData;
begin
  S := Build(MODEL);
  Data := S.Stacks[0].LayerData[0];
  Data.Material := 'Mo';
  S.SelectLayer(0, 1);                         // before Si
  S.InsertLayer(Data);

  Assert.AreEqual('Mo', S.Stacks[0].LayerData[1].Material);
  CheckPos(FMap[0][0], 0, 0, 'W');
  CheckPos(FMap[0][1], 0, 2, 'Si');
  CheckPos(FMap[0][2], 0, 3, 'C');
end;

procedure TTestStructureRenumber.InsertStack_ShiftsTheStacksBelow;
var
  S: TXRCStructure;
begin
  S := Build(MODEL);
  S.Select(0);
  S.InsertStack(1, 'New');                     // before ML

  Assert.AreEqual(3, Length(S.Stacks));
  CheckPos(FMap[0][1], 1, 1, 'Si');
  CheckPos(FMap[1][0], 2, 0, 'Cr');
end;

procedure TTestStructureRenumber.DeleteStack_DropsItsLayersAndShiftsTheRest;
var
  S: TXRCStructure;
begin
  S := Build(MODEL);
  S.Select(0);
  S.DeleteStack;

  Assert.AreEqual(1, FFired);
  CheckPos(FMap[0][0], -1, -1, 'W deleted');
  CheckPos(FMap[0][2], -1, -1, 'C deleted');
  CheckPos(FMap[1][0], 0, 0, 'Cr');
end;

// The layer menu posts its indices; by the time they arrive the layer may be
// gone. Nothing is moved and nothing is renumbered.
procedure TTestStructureRenumber.MoveLayer_StaleIndices_DoNothing;
var
  S: TXRCStructure;
begin
  S := Build(MODEL);
  S.MoveLayer(1, 5, -1);
  S.DeleteLayer(4, 0);

  Assert.AreEqual(0, FFired);
  Assert.AreEqual('W', S.Stacks[0].LayerData[0].Material);
end;

procedure TTestStructureRenumber.Model_ExpandsATableCoveringEveryPeriod;
var
  S: TXRCStructure;
  Data: TLayerData;
  M: TLayeredModel;
begin
  S := Build(MODEL);
  Data := S.Stacks[0].LayerData[0];
  Data.PP[1] := TFloatArray.Create(11, 12, 13);
  S.Stacks[0].UpdateLayer(0, Data);

  M := S.Model(True);
  try
    // Layer 0 is the ambient; each period is W, Si, C.
    Assert.AreEqual(Single(11), M.LayersDirect[1].L, 1E-5, 'period 1');
    Assert.AreEqual(Single(12), M.LayersDirect[4].L, 1E-5, 'period 2');
    Assert.AreEqual(Single(13), M.LayersDirect[7].L, 1E-5, 'period 3');
    Assert.AreEqual(Single(20), M.LayersDirect[8].L, 1E-5, 'Si has no table');
  finally
    M.Free;
  end;
end;

// A table made for N = 2 after N was raised to 3 used to be read past its end.
procedure TTestStructureRenumber.Model_IgnoresATableShorterThanN;
var
  S: TXRCStructure;
  Data: TLayerData;
  M: TLayeredModel;
begin
  S := Build(MODEL);
  Data := S.Stacks[0].LayerData[0];
  Data.PP[1] := TFloatArray.Create(11, 12);
  S.Stacks[0].UpdateLayer(0, Data);

  M := S.Model(True);
  try
    Assert.AreEqual(Single(10), M.LayersDirect[1].L, 1E-5, 'period 1');
    Assert.AreEqual(Single(10), M.LayersDirect[7].L, 1E-5, 'period 3');
  finally
    M.Free;
  end;
end;

// FromString reuses one record for every layer; a layer saved without a table
// took the table of the layer read before it.
procedure TTestStructureRenumber.FromString_LayerWithoutTable_KeepsNone;
var
  S: TXRCStructure;
  Data: TLayerData;
begin
  S := Build(MODEL);
  Data := S.Stacks[0].LayerData[0];
  Data.PP[1] := TFloatArray.Create(11, 12, 13);
  S.Stacks[0].UpdateLayer(0, Data);

  S.FromString(S.ToString);

  Assert.AreEqual(3, Integer(Length(S.Stacks[0].LayerData[0].PP[1])), 'W keeps its table');
  Assert.AreEqual(0, Integer(Length(S.Stacks[0].LayerData[1].PP[1])), 'Si has none');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestStructureRenumber);

end.
