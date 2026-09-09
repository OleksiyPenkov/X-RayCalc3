unit TestMCPStructure;

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.JSON,
  unit_Types, unit_materials, unit_MCPStructure, unit_MCPErrors;

type
  [TestFixture]
  TTestMCPStructure = class
  private
    function Parse(const S: string): TJSONObject;
  public
    [Test] procedure FromJSON_OrderIsSurfaceFirst;
    [Test] procedure FromJSON_Info;
    [Test] procedure FromJSON_TwoStacks_ReversedOrder;
    [Test] procedure FromJSON_MissingDensity_IsZero;
    [Test] procedure FromJSON_MissingSubstrate_Raises;
    [Test] procedure FromJSON_NegativeThickness_Raises;
    [Test] procedure ToJSON_RoundTrip;
    [Test] procedure XRCData_RoundTrip;
    [Test] procedure XRCData_HasAllSixteenLayerKeys;
    [Test] procedure BuildLayeredModel_LayerCount;
    [Test] procedure BuildLayeredModel_TopLayerIsCap;
    // fix round 1
    [Test] procedure FromJSON_HugeN_Raises;
    [Test] procedure FromJSON_NonFiniteN_Raises;
    [Test] procedure XRCData_MultiLayerCapStaysAStack;
    [Test] procedure ToJSON_BadCapIndex_RaisesInternal;
    [Test] procedure FillDefaultDensities_SubstrateAlwaysBulk;
    [Test] procedure ValidateMaterials_EmptyNameIsReported;
  end;

implementation

const
  RUC_JSON = '{"substrate":{"material":"SiO2","density":2.2,"sigma":3.0},' +
    '"stacks":[{"N":30,"layers":[{"material":"Ru","thickness":14.7,"sigma":3.0,"density":12.4},' +
    '{"material":"C","thickness":53.8,"sigma":3.0,"density":2.2}]}],' +
    '"cap":{"material":"Ru","thickness":20.0,"sigma":3.0,"density":12.4},' +
    '"buffer":{"material":"Ru","thickness":197.0,"sigma":3.0,"density":12.4}}';

  TWO_STACK_JSON = '{"substrate":{"material":"Si","sigma":2.0},' +
    '"stacks":[{"N":10,"layers":[{"material":"W","thickness":10.0}]},' +
    '{"N":5,"layers":[{"material":"Mo","thickness":20.0}]}]}';

  // an XRC data string whose first stack is titled 'Cap' but is a real stack:
  // three repeats of two layers. It must not be flattened into a JSON "cap".
  FAT_CAP_XRC = '{"Stacks":[{"T":"Cap","N":3,"Layers":[' +
    '{"M":"Ru","H":10.0,"s":3.0,"r":12.4},' +
    '{"M":"C","H":20.0,"s":3.0,"r":2.2}]}],' +
    '"Subs":{"M":"Si","s":2.0,"r":0.0}}';

function TTestMCPStructure.Parse(const S: string): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue(S) as TJSONObject;
  Assert.IsNotNull(Result, 'test JSON must parse');
end;

procedure TTestMCPStructure.FromJSON_OrderIsSurfaceFirst;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
    Assert.AreEqual(3, Length(S.Stacks), 'cap + ML + buffer');
    Assert.AreEqual('Cap', S.Stacks[0].Header);
    Assert.AreEqual(30, S.Stacks[1].N);
    Assert.AreEqual('Buffer', S.Stacks[2].Header);
    Assert.AreEqual('SiO2', S.Subs.Material);
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.FromJSON_Info;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
    Assert.AreEqual(1, Info.PeriodicStackIndex);
    Assert.AreEqual(68.5, Info.Period, 1E-3);
    Assert.AreEqual(30, Info.N);
    Assert.IsTrue(Info.HasCap, 'HasCap');
    Assert.IsTrue(Info.HasBuffer, 'HasBuffer');
    Assert.AreEqual(1, Length(Info.StackMap));
    Assert.AreEqual(1, Info.StackMap[0]);
    Assert.AreEqual(0, Info.CapIndex);
    Assert.AreEqual(2, Info.BufferIndex);
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.FromJSON_TwoStacks_ReversedOrder;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
begin
  // JSON lists stacks substrate -> surface: A(N=10, W) then B(N=5, Mo).
  // The GUI order is surface first, so B comes first.
  J := Parse(TWO_STACK_JSON);
  try
    S := StructureFromJSON(J, Info);
    Assert.AreEqual(2, Length(S.Stacks));
    Assert.AreEqual(5, S.Stacks[0].N);
    Assert.AreEqual('Mo', S.Stacks[0].Layers[0].Material);
    Assert.AreEqual(10, S.Stacks[1].N);
    Assert.AreEqual('W', S.Stacks[1].Layers[0].Material);
    Assert.IsFalse(Info.HasCap, 'no cap');
    Assert.IsFalse(Info.HasBuffer, 'no buffer');
    Assert.AreEqual(-1, Info.CapIndex);
    Assert.AreEqual(-1, Info.BufferIndex);
    Assert.AreEqual(2, Length(Info.StackMap));
    Assert.AreEqual(1, Info.StackMap[0], 'JSON stacks[0] is the substrate-most stack');
    Assert.AreEqual(0, Info.StackMap[1]);
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.FromJSON_MissingDensity_IsZero;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
begin
  J := Parse(TWO_STACK_JSON);
  try
    S := StructureFromJSON(J, Info);
    Assert.AreEqual(0.0, Double(S.Stacks[0].Layers[0].P[3].V), 1E-9, 'density defaults to 0 (Henke bulk)');
    Assert.AreEqual(0.0, Double(S.Subs.P[3].V), 1E-9);
    Assert.AreEqual(0.0, Double(S.Stacks[1].Layers[0].P[2].V), 1E-9, 'sigma defaults to 0');
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.FromJSON_MissingSubstrate_Raises;
var
  J: TJSONObject;
begin
  J := Parse('{"stacks":[{"N":1,"layers":[{"material":"W","thickness":10.0}]}]}');
  try
    try
      var S: TFitStructure;
      var Info: TStructureInfo;
      S := StructureFromJSON(J, Info);
      Assert.Fail('a structure without a substrate must be refused');
    except
      on E: EMCPError do
        Assert.AreEqual('invalid_structure', E.Code);
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.FromJSON_NegativeThickness_Raises;
var
  J: TJSONObject;
begin
  J := Parse('{"substrate":{"material":"Si"},' +
    '"stacks":[{"N":1,"layers":[{"material":"W","thickness":-10.0}]}]}');
  try
    try
      var S: TFitStructure;
      var Info: TStructureInfo;
      S := StructureFromJSON(J, Info);
      Assert.Fail('a negative thickness must be refused');
    except
      on E: EMCPError do
      begin
        Assert.AreEqual('invalid_structure', E.Code);
        Assert.IsTrue(Pos('thickness', E.Detail) > 0, 'Detail names the offending path, got "' + E.Detail + '"');
      end;
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.ToJSON_RoundTrip;
var
  J1, J2: TJSONObject;
  S1, S2: TFitStructure;
  I1, I2: TStructureInfo;
  i, j, p: Integer;
begin
  J1 := Parse(RUC_JSON);
  try
    S1 := StructureFromJSON(J1, I1);
    J2 := StructureToJSON(S1, I1);
    try
      // stacks are reported substrate -> surface, cap and buffer are labelled
      Assert.IsNotNull(J2.FindValue('cap'), 'cap');
      Assert.IsNotNull(J2.FindValue('buffer'), 'buffer');
      Assert.IsNotNull(J2.FindValue('substrate'), 'substrate');
      Assert.AreEqual(1, (J2.FindValue('stacks') as TJSONArray).Count);
      Assert.AreEqual('Ru', J2.GetValue<string>('stacks[0].layers[0].material'));
      Assert.AreEqual('C', J2.GetValue<string>('stacks[0].layers[1].material'));

      S2 := StructureFromJSON(J2, I2);
    finally
      J2.Free;
    end;

    Assert.AreEqual(Length(S1.Stacks), Length(S2.Stacks));
    Assert.AreEqual(S1.Subs.Material, S2.Subs.Material);
    for p := 2 to 3 do
      Assert.AreEqual(Double(S1.Subs.P[p].V), Double(S2.Subs.P[p].V), 1E-4, 'substrate P' + IntToStr(p));
    for i := 0 to High(S1.Stacks) do
    begin
      Assert.AreEqual(S1.Stacks[i].N, S2.Stacks[i].N, 'N of stack ' + IntToStr(i));
      Assert.AreEqual(Length(S1.Stacks[i].Layers), Length(S2.Stacks[i].Layers));
      for j := 0 to High(S1.Stacks[i].Layers) do
      begin
        Assert.AreEqual(S1.Stacks[i].Layers[j].Material, S2.Stacks[i].Layers[j].Material);
        for p := 1 to 3 do
          Assert.AreEqual(Double(S1.Stacks[i].Layers[j].P[p].V),
                          Double(S2.Stacks[i].Layers[j].P[p].V), 1E-4,
                          Format('stack %d layer %d P%d', [i, j, p]));
      end;
    end;
    Assert.AreEqual(I1.PeriodicStackIndex, I2.PeriodicStackIndex);
    Assert.AreEqual(I1.CapIndex, I2.CapIndex);
    Assert.AreEqual(I1.BufferIndex, I2.BufferIndex);
  finally
    J1.Free;
  end;
end;

procedure TTestMCPStructure.XRCData_RoundTrip;
var
  JR: TJSONObject;
  S1, S2: TFitStructure;
  I1, I2: TStructureInfo;
  Data: string;
  i, j, p: Integer;
begin
  JR := Parse(RUC_JSON);
  try
    S1 := StructureFromJSON(JR, I1);
  finally
    JR.Free;
  end;

  Data := StructureToXRCData(S1, I1);
  Assert.IsTrue(Pos('"Stacks"', Data) > 0, 'the GUI data string has a "Stacks" key');
  Assert.IsTrue(Pos('"Subs"', Data) > 0, 'the GUI data string has a "Subs" key');

  S2 := StructureFromXRCData(Data, I2);

  Assert.AreEqual(Length(S1.Stacks), Length(S2.Stacks));
  Assert.AreEqual(S1.Subs.Material, S2.Subs.Material);
  Assert.AreEqual(Double(S1.Subs.P[2].V), Double(S2.Subs.P[2].V), 1E-4);
  Assert.AreEqual(Double(S1.Subs.P[3].V), Double(S2.Subs.P[3].V), 1E-4);
  for i := 0 to High(S1.Stacks) do
  begin
    Assert.AreEqual(S1.Stacks[i].N, S2.Stacks[i].N);
    Assert.AreEqual(S1.Stacks[i].Header, S2.Stacks[i].Header);
    Assert.AreEqual(Double(S1.Stacks[i].D), Double(S2.Stacks[i].D), 1E-4);
    Assert.AreEqual(Length(S1.Stacks[i].Layers), Length(S2.Stacks[i].Layers));
    for j := 0 to High(S1.Stacks[i].Layers) do
    begin
      Assert.AreEqual(S1.Stacks[i].Layers[j].Material, S2.Stacks[i].Layers[j].Material);
      Assert.AreEqual(Integer(S1.Stacks[i].Layers[j].StackID), Integer(S2.Stacks[i].Layers[j].StackID));
      Assert.AreEqual(Integer(S1.Stacks[i].Layers[j].LayerID), Integer(S2.Stacks[i].Layers[j].LayerID));
      for p := 1 to 3 do
      begin
        Assert.AreEqual(Double(S1.Stacks[i].Layers[j].P[p].V),
                        Double(S2.Stacks[i].Layers[j].P[p].V), 1E-4);
        Assert.AreEqual(Double(S1.Stacks[i].Layers[j].P[p].min),
                        Double(S2.Stacks[i].Layers[j].P[p].min), 1E-4);
        Assert.AreEqual(Double(S1.Stacks[i].Layers[j].P[p].max),
                        Double(S2.Stacks[i].Layers[j].P[p].max), 1E-4);
        Assert.AreEqual(S1.Stacks[i].Layers[j].P[p].Paired,
                        S2.Stacks[i].Layers[j].P[p].Paired);
      end;
    end;
  end;
  Assert.AreEqual(I1.PeriodicStackIndex, I2.PeriodicStackIndex);
  Assert.AreEqual(I1.N, I2.N);
  Assert.AreEqual(I1.CapIndex, I2.CapIndex);
  Assert.AreEqual(I1.BufferIndex, I2.BufferIndex);
  Assert.AreEqual(Length(I1.StackMap), Length(I2.StackMap));
  for i := 0 to High(I1.StackMap) do
    Assert.AreEqual(I1.StackMap[i], I2.StackMap[i]);
end;

procedure TTestMCPStructure.XRCData_HasAllSixteenLayerKeys;
const
  KEYS: array [0..15] of string = ('M',
    'H', 'HP', 'Hmin', 'Hmax', 'ProfileH',
    's', 'SP', 'Smin', 'Smax', 'ProfileS',
    'r', 'RP', 'Rmin', 'Rmax', 'ProfileR');
var
  J, JRoot, JLayer: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  Data: string;
  k: Integer;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;

  Data := StructureToXRCData(S, Info);
  JRoot := TJSONObject.ParseJSONValue(Data) as TJSONObject;
  Assert.IsNotNull(JRoot, 'the data string must be valid JSON');
  try
    JLayer := JRoot.GetValue<TJSONObject>('Stacks[1].Layers[0]');
    Assert.IsNotNull(JLayer);
    for k := 0 to High(KEYS) do
      Assert.IsNotNull(JLayer.FindValue(KEYS[k]), 'missing layer key "' + KEYS[k] + '"');
    Assert.AreEqual(16, JLayer.Count, 'exactly the 16 GUI layer keys');

    Assert.IsNotNull(JRoot.GetValue<TJSONObject>('Subs').FindValue('M'));
    Assert.IsNotNull(JRoot.GetValue<TJSONObject>('Subs').FindValue('s'));
    Assert.IsNotNull(JRoot.GetValue<TJSONObject>('Subs').FindValue('r'));
  finally
    JRoot.Free;
  end;
end;

procedure TTestMCPStructure.BuildLayeredModel_LayerCount;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  M: TLayeredModel;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;

  M := BuildLayeredModel(S);
  try
    // vacuum + cap + 30 * 2 + buffer + substrate
    Assert.AreEqual(64, Length(M.Layers));
  finally
    M.Free;
  end;
end;

procedure TTestMCPStructure.BuildLayeredModel_TopLayerIsCap;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  M: TLayeredModel;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;

  M := BuildLayeredModel(S);
  try
    Assert.AreEqual(20.0, Double(M.Layers[1].L), 1E-4);
    Assert.AreEqual('Ru', M.LayerNames[1]);
    Assert.AreEqual('SiO2', M.LayerNames[63], 'the substrate is last');
  finally
    M.Free;
  end;
end;

{ ---------------------------------------------------------- fix round 1 -- }

procedure TTestMCPStructure.FromJSON_HugeN_Raises;
var
  J: TJSONObject;
begin
  // Length(Layers) * N would overflow Integer and wrap back under MAX_LAYERS
  J := Parse('{"substrate":{"material":"Si"},"stacks":[{"N":1500000000,' +
    '"layers":[{"material":"W","thickness":10.0},{"material":"Si","thickness":10.0}]}]}');
  try
    try
      var S: TFitStructure;
      var Info: TStructureInfo;
      S := StructureFromJSON(J, Info);
      Assert.Fail('an N of 1.5e9 must be refused, not wrapped');
    except
      on E: EMCPError do
        Assert.AreEqual('invalid_structure', E.Code);
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.FromJSON_NonFiniteN_Raises;
var
  J: TJSONObject;
begin
  // Round() of 1e30 raises EInvalidOp; the client must see a structured error
  J := Parse('{"substrate":{"material":"Si"},"stacks":[{"N":1e30,' +
    '"layers":[{"material":"W","thickness":10.0}]}]}');
  try
    try
      var S: TFitStructure;
      var Info: TStructureInfo;
      S := StructureFromJSON(J, Info);
      Assert.Fail('an N of 1e30 must be refused');
    except
      on E: EMCPError do
      begin
        Assert.AreEqual('invalid_structure', E.Code);
        Assert.IsTrue(Pos('N', E.Detail) > 0, 'Detail names the offending path, got "' + E.Detail + '"');
      end;
    end;
  finally
    J.Free;
  end;
end;

procedure TTestMCPStructure.XRCData_MultiLayerCapStaysAStack;
var
  S: TFitStructure;
  Info: TStructureInfo;
  JOut: TJSONObject;
  JStacks: TJSONArray;
begin
  S := StructureFromXRCData(FAT_CAP_XRC, Info);

  Assert.AreEqual(1, Length(S.Stacks));
  Assert.AreEqual(3, S.Stacks[0].N);
  Assert.AreEqual(2, Length(S.Stacks[0].Layers));
  Assert.AreEqual(-1, Info.CapIndex, 'a repeated multi-layer stack is not a cap');
  Assert.IsFalse(Info.HasCap, 'HasCap');
  Assert.AreEqual(1, Length(Info.StackMap), 'it stays an ordinary stack');
  Assert.AreEqual(0, Info.StackMap[0]);

  JOut := StructureToJSON(S, Info);
  try
    Assert.IsNull(JOut.FindValue('cap'), 'no "cap" key');
    JStacks := JOut.FindValue('stacks') as TJSONArray;
    Assert.AreEqual(1, JStacks.Count);
    Assert.AreEqual(3, JOut.GetValue<Integer>('stacks[0].N'));
    Assert.AreEqual(2, (JStacks.Items[0] as TJSONObject).GetValue<TJSONArray>('layers').Count,
      'both layers survive the round trip');
    Assert.AreEqual('Ru', JOut.GetValue<string>('stacks[0].layers[0].material'));
    Assert.AreEqual('C', JOut.GetValue<string>('stacks[0].layers[1].material'));
  finally
    JOut.Free;
  end;
end;

procedure TTestMCPStructure.ToJSON_BadCapIndex_RaisesInternal;
var
  S: TFitStructure;
  Info, Bad: TStructureInfo;
begin
  S := StructureFromXRCData(FAT_CAP_XRC, Info);
  Bad := Info;
  Bad.CapIndex := 0;   // point at the three-repeat, two-layer stack
  Bad.HasCap := True;
  try
    var J: TJSONObject := StructureToJSON(S, Bad);
    J.Free;
    Assert.Fail('a cap index pointing at a multi-layer stack must be refused, not silently truncated');
  except
    on E: EMCPError do
      Assert.AreEqual('internal', E.Code);
  end;
end;

procedure TTestMCPStructure.FillDefaultDensities_SubstrateAlwaysBulk;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  M: TLayeredModel;
  Mats: TMaterials;
begin
  J := Parse(RUC_JSON);   // substrate SiO2 with an explicit density of 2.2
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;
  // the C layer of the ML stack asks for the bulk value
  S.Stacks[1].Layers[1].P[3].V := 0;

  M := TLayeredModel.Create;
  try
    // stand in for what Generate/ReadHenke would have filled in, so the test
    // needs no Henke tables
    SetLength(Mats, 3);
    Mats[0].Name := 'SiO2'; Mats[0].ro := 2.65;
    Mats[1].Name := 'Ru';   Mats[1].ro := 12.41;
    Mats[2].Name := 'C';    Mats[2].ro := 2.26;
    M.Materials := Mats;

    FillDefaultDensities(S, M);
  finally
    M.Free;
  end;

  // the engine ignores a supplied substrate density, so the echo must be bulk
  Assert.AreEqual(2.65, Double(S.Subs.P[3].V), 1E-4,
    'the substrate density is always the bulk value the engine used');
  // a layer that asked for bulk gets it
  Assert.AreEqual(2.26, Double(S.Stacks[1].Layers[1].P[3].V), 1E-4);
  // a layer that supplied one keeps it
  Assert.AreEqual(12.4, Double(S.Stacks[1].Layers[0].P[3].V), 1E-4);
  Assert.AreEqual(12.4, Double(S.Stacks[0].Layers[0].P[3].V), 1E-4, 'cap keeps its density');
end;

procedure TTestMCPStructure.ValidateMaterials_EmptyNameIsReported;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
begin
  J := Parse(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;
  S.Stacks[0].Layers[0].Material := '';

  // '' would be indistinguishable from "every material is known"
  Assert.AreEqual('<empty>', ValidateMaterials(S));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPStructure);

end.
