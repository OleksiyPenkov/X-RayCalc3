unit TestProjectTreeNodeIO;

(* TXRCProjectTree node streaming, specifically the variant-record trap.

   TProjectData is a variant record: prItem's ID, CurveID, Color, Active and
   Visible share memory with prExtension's Enabled, FromFit, ExtType, StackID,
   LayerID, PolyCount and Poly. ProjectSaveNode writes the extension fields for
   every node, so ProjectLoadNode has to read them for every node - but it may
   only STORE them on a node that really is an extension.

   A plain save/load round trip cannot catch a mistake here, because the writer
   and the reader alias the same bytes and cancel each other out. The test below
   therefore writes a project, patches the extension slots of a DATA item to
   sentinel values the way an older build's layout would have left them, and
   then loads it: the item's own fields must be untouched.

   This is the bug that dropped the linked measured curve from every pre-2026
   project - the data node came back with an ID matching neither [STATE]
   LinkedData nor its own data_<ID>.dat, so RecoverDataCurves deleted it. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestProjectTreeNodeIO = class
  private
    FTemp: string;
    function WriteProject(const ADataID: Integer): string;
    procedure PatchExtensionSlots(const AFileName: string; const ADataID: Integer);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure DataItem_SurvivesForeignExtensionSlots;
    [Test] procedure Extension_KeepsItsOwnFields;
    [Test] procedure ModelFromVersion7_LoadsWithBulkSubstrateDensity;
    [Test] procedure ModelFromVersion8_KeepsItsSubstrateDensity;
    [Test] procedure LegacySubstrateDensity_LeavesOtherTextAlone;
  private
    function LoadModelData(const FileName: string; Version: Integer): string;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.IOUtils,
  VirtualTrees, unit_Types, unit_XRCProjectTree;

const
  { A Unix-timestamp ID, as every project saved before the IDs became small
    counters carries. 0x64AE9EC3 - no byte is zero, so a sentinel landing on
    any one of them shows up. }
  DATA_ID = 1689165507;

  { What an older build's byte layout would leave in those slots. }
  SENTINEL_ENABLED = 1;
  SENTINEL_EXTTYPE = 2;
  SENTINEL_LAYERID = $7F7F7F7F;
  SENTINEL_STACKID = $6E6E6E6E;

  DATA_COLOR = $00AB55CC;

procedure TTestProjectTreeNodeIO.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'xrc_treeio_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTemp);
end;

procedure TTestProjectTreeNodeIO.TearDown;
begin
  if TDirectory.Exists(FTemp) then
    TDirectory.Delete(FTemp, True);
end;

{ Models group > one model > one gradient extension; Data group > one data item. }
function TTestProjectTreeNodeIO.WriteProject(const ADataID: Integer): string;
var
  Tree: TXRCProjectTree;
  Root, ModelNode, Node: PVirtualNode;
  PD: PProjectData;
  Coeffs: TPolyArray;
  i: Integer;
begin
  Result := TPath.Combine(FTemp, 'project.dsc');

  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);

    Root := Tree.AddChild(nil, nil);
    PD := Tree.GetNodeData(Root);
    PD.Title := 'Models';
    PD.Group := gtModel;
    PD.RowType := prGroup;

    ModelNode := Tree.AddChild(Root, nil);
    PD := Tree.GetNodeData(ModelNode);
    PD.Title := 'Model 1';
    PD.Group := gtModel;
    PD.RowType := prItem;
    PD.ID := 4;
    PD.CurveID := 0;
    PD.Color := $000000FF;
    PD.Active := True;
    PD.Visible := True;
    PD.Data := '{"Stacks":[],"Subs":{"M":"Si","s":1,"r":2.33}}';

    Node := Tree.AddChild(ModelNode, nil);
    PD := Tree.GetNodeData(Node);
    PD.Title := 'Gradient 1';
    PD.Group := gtModel;
    PD.RowType := prExtension;
    PD.Enabled := True;
    // Set by CreateFitGradientExtensions on every gradient a fit produced. It
    // rides along in the header's ID field - see the note in ProjectLoadNode.
    PD.FromFit := True;
    PD.ExtType := etFunction;
    PD.StackID := 1;
    PD.LayerID := 3;
    PD.Form := ffPoly;
    PD.Subj := ptS;
    SetLength(Coeffs, 4);
    for i := 0 to High(Coeffs) do
      Coeffs[i] := 0.5 * (i + 1);
    PD.SetPoly(Coeffs);

    Root := Tree.AddChild(nil, nil);
    PD := Tree.GetNodeData(Root);
    PD.Title := 'Data';
    PD.Group := gtData;
    PD.RowType := prGroup;

    Node := Tree.AddChild(Root, nil);
    PD := Tree.GetNodeData(Node);
    PD.Title := 'Measured';
    PD.Group := gtData;
    PD.RowType := prItem;
    PD.ID := ADataID;
    PD.CurveID := 0;
    PD.Color := DATA_COLOR;
    PD.Active := False;
    PD.Visible := True;

    Tree.SaveToFile(Result);
  finally
    Tree.Free;
  end;
end;

{ Overwrite the extension slots of the data item, leaving every other byte of
  the file alone. The node payload ProjectSaveNode writes is deterministic:
  ID, Title, RowType, Group, Active, Visible, Description, Color, and then the
  six extension fields - so the slots can be found by walking forward from the
  one place the ID appears. }
procedure TTestProjectTreeNodeIO.PatchExtensionSlots(const AFileName: string;
  const ADataID: Integer);
var
  Bytes: TBytes;
  i, Hits, Start, Ofs, Size: Integer;
begin
  Bytes := TFile.ReadAllBytes(AFileName);

  Hits := 0;
  Start := -1;
  for i := 0 to Length(Bytes) - SizeOf(Integer) do
    if PInteger(@Bytes[i])^ = ADataID then
    begin
      Inc(Hits);
      Start := i;
    end;
  Assert.AreEqual(1, Hits, 'the data ID must appear exactly once in the file');

  Ofs := Start + SizeOf(Integer);
  Size := PInteger(@Bytes[Ofs])^;                 // Title
  Inc(Ofs, SizeOf(Integer) + Size);
  Inc(Ofs, 4);                                    // RowType, Group, Active, Visible
  Size := PInteger(@Bytes[Ofs])^;                 // Description
  Inc(Ofs, SizeOf(Integer) + Size);
  Inc(Ofs, SizeOf(Integer));                      // Color

  Bytes[Ofs] := SENTINEL_ENABLED;
  Bytes[Ofs + 1] := SENTINEL_EXTTYPE;
  PInteger(@Bytes[Ofs + 2])^ := SENTINEL_LAYERID;
  PInteger(@Bytes[Ofs + 6])^ := SENTINEL_STACKID;

  TFile.WriteAllBytes(AFileName, Bytes);
end;

function TTestProjectTreeNodeIO.LoadModelData(const FileName: string;
  Version: Integer): string;
var
  Tree: TXRCProjectTree;
  Node: PVirtualNode;
  PD: PProjectData;
begin
  Result := '';
  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);
    Tree.Version := Version;
    Tree.LoadFromFile(FileName);
    Node := Tree.GetFirst;
    while Node <> nil do
    begin
      PD := Tree.GetNodeData(Node);
      if (PD.Group = gtModel) and (PD.RowType = prItem) then
        Exit(PD.Data);
      Node := Tree.GetNext(Node);
    end;
  finally
    Tree.Free;
  end;
end;

{ Until 3.9.1 the engine ignored the substrate density and used the Henke bulk
  value. A project saved before then must keep computing what it always did,
  so its substrate density loads as 0 - "bulk" - whatever the file says. }
procedure TTestProjectTreeNodeIO.ModelFromVersion7_LoadsWithBulkSubstrateDensity;
var
  Data: string;
begin
  Data := LoadModelData(WriteProject(DATA_ID), 7);
  Assert.Contains(Data, '"r":0', 'the substrate density is reset to bulk');
  Assert.DoesNotContain(Data, '2.33', 'the stored density is gone');
  Assert.Contains(Data, '"M":"Si"', 'the substrate material is kept');
  Assert.Contains(Data, '"s":1', 'the substrate roughness is kept');
end;

procedure TTestProjectTreeNodeIO.ModelFromVersion8_KeepsItsSubstrateDensity;
begin
  Assert.AreEqual('{"Stacks":[],"Subs":{"M":"Si","s":1,"r":2.33}}',
    LoadModelData(WriteProject(DATA_ID), 8),
    'a version 8 project keeps the density it was saved with');
end;

procedure TTestProjectTreeNodeIO.LegacySubstrateDensity_LeavesOtherTextAlone;
const
  S = '{"Stacks":[{"T":"ML","N":10,"Layers":[{"M":"W","H":25.5,"r":19.3}]}],' +
      '"Subs":{"M":"SiO2","s":3.8,"r":2.2}}';
begin
  Assert.AreEqual(
    '{"Stacks":[{"T":"ML","N":10,"Layers":[{"M":"W","H":25.5,"r":19.3}]}],' +
    '"Subs":{"M":"SiO2","s":3.8,"r":0}}',
    LegacySubstrateDensity(S), 'only the substrate density changes');
  Assert.AreEqual('not a structure', LegacySubstrateDensity('not a structure'));
  Assert.AreEqual('', LegacySubstrateDensity(''));
end;

procedure TTestProjectTreeNodeIO.DataItem_SurvivesForeignExtensionSlots;
var
  FileName: string;
  Tree: TXRCProjectTree;
  Node: PVirtualNode;
  PD: PProjectData;
  Found: Boolean;
  GotID, GotColor, GotCurveID: Integer;
  GotActive, GotVisible: Boolean;
begin
  FileName := WriteProject(DATA_ID);
  PatchExtensionSlots(FileName, DATA_ID);

  Found := False;
  GotID := 0; GotColor := 0; GotCurveID := 0;
  GotActive := True; GotVisible := False;

  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);
    Tree.Version := 7;
    Tree.LoadFromFile(FileName);

    Node := Tree.GetFirst;
    while Node <> nil do
    begin
      PD := Tree.GetNodeData(Node);
      if (PD.Group = gtData) and (PD.RowType = prItem) then
      begin
        Found := True;
        GotID := PD.ID;
        GotColor := PD.Color;
        GotCurveID := PD.CurveID;
        GotActive := PD.Active;
        GotVisible := PD.Visible;
      end;
      Node := Tree.GetNext(Node);
    end;
  finally
    Tree.Free;
  end;

  Assert.IsTrue(Found, 'the data item is missing from the reloaded tree');
  Assert.AreEqual(DATA_ID, GotID, 'ID must not take bytes from the extension slots');
  Assert.AreEqual(DATA_COLOR, GotColor, 'Color must not be overwritten by LayerID');
  Assert.AreEqual(0, GotCurveID, 'CurveID must not be overwritten by StackID');
  Assert.IsFalse(GotActive, 'Active must not be overwritten by PolyCount');
  Assert.IsTrue(GotVisible, 'Visible must not be overwritten by PolyCount');
end;

procedure TTestProjectTreeNodeIO.Extension_KeepsItsOwnFields;
var
  FileName: string;
  Tree: TXRCProjectTree;
  Node: PVirtualNode;
  PD: PProjectData;
  Found: Boolean;
  Coeffs: TPolyArray;
  GotStack, GotLayer, GotCount: Integer;
  GotEnabled, GotFromFit: Boolean;
  GotExtType: TExtentionType;
  GotForm: TFunctionForm;
  GotSubj: TParameterType;
begin
  FileName := WriteProject(DATA_ID);

  Found := False;
  GotStack := 0; GotLayer := 0; GotCount := 0;
  GotEnabled := False; GotFromFit := False;
  GotExtType := etNone; GotForm := ffNone; GotSubj := ptH;
  Coeffs := nil;

  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);
    Tree.Version := 7;
    Tree.LoadFromFile(FileName);

    Node := Tree.GetFirst;
    while Node <> nil do
    begin
      PD := Tree.GetNodeData(Node);
      if PD.RowType = prExtension then
      begin
        Found := True;
        GotEnabled := PD.Enabled;
        GotFromFit := PD.FromFit;
        GotExtType := PD.ExtType;
        GotStack := PD.StackID;
        GotLayer := PD.LayerID;
        GotCount := PD.PolyCount;
        GotForm := PD.Form;
        GotSubj := PD.Subj;
        Coeffs := PD.PolyD;
      end;
      Node := Tree.GetNext(Node);
    end;
  finally
    Tree.Free;
  end;

  Assert.IsTrue(Found, 'the extension is missing from the reloaded tree');
  Assert.IsTrue(GotEnabled, 'Enabled');
  { Without this, RunFitting stops asking whether to keep or clear the
    gradients an earlier fit produced, because HasFitExtensions reads it. }
  Assert.IsTrue(GotFromFit, 'FromFit must survive a save/load round trip');
  Assert.AreEqual(Ord(etFunction), Ord(GotExtType), 'ExtType');
  Assert.AreEqual(1, GotStack, 'StackID');
  Assert.AreEqual(3, GotLayer, 'LayerID');
  Assert.AreEqual(3, GotCount, 'PolyCount');
  Assert.AreEqual(Ord(ffPoly), Ord(GotForm), 'Form');
  Assert.AreEqual(Ord(ptS), Ord(GotSubj), 'Subj');

  // Poly[0] is deliberately not stored - see the note in unit_MCPProjectFile.
  Assert.AreEqual(4, Length(Coeffs), 'coefficient count');
  Assert.AreEqual(Single(1.0), Coeffs[1], 1E-6, 'Poly[1]');
  Assert.AreEqual(Single(1.5), Coeffs[2], 1E-6, 'Poly[2]');
  Assert.AreEqual(Single(2.0), Coeffs[3], 1E-6, 'Poly[3]');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestProjectTreeNodeIO);

end.
