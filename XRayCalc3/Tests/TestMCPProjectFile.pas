unit TestMCPProjectFile;

(* .xrcx project files written and read by the server.

   The first test is the spike the whole task rests on: TXRCProjectTree is a
   TVirtualStringTree, and the question was whether one can be built, filled,
   saved and re-read in a console process that never shows a window. If it can,
   the bytes the server writes are the GUI's own bytes, written by the GUI's own
   OnSaveNode. If it cannot, the writer has to reproduce the stream by hand.

   It can, with no owner form and no window handle, so unit_MCPProjectFile uses
   the real component and the plan's fallback byte writer was never needed.

   The rest of the fixture pins the file down from both ends: the zip has the
   four flat entries the GUI's Abbrevia reader expects, params.dsc is a version
   7 parameter block whose angles are theta, and everything written comes back
   out of ReadXRCX unchanged - with the one documented exception that the GUI's
   own OnSaveNode does not store Poly[0] of a gradient extension.

   Every test that touches a tool runs against its own temporary work directory,
   assigned to the global WorkDir in Setup and restored in TearDown. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Classes, System.IOUtils,
  System.JSON, System.Zip, System.IniFiles,
  VirtualTrees, VirtualTrees.Types,
  unit_Types, unit_XRCProjectTree,
  unit_MCPSandbox, unit_MCPErrors, unit_MCPTools, unit_MCPStructure,
  unit_MCPProjectFile, unit_ToolsFiles, unit_Config;

type
  [TestFixture]
  TTestMCPProjectFile = class
  private
    FTemp: string;
    FSavedWorkDir: TWorkDir;
    function SampleXRCData: string;
    function SampleProject: TXRCXProject;
    function Ramp(N: Integer; T0, DT: Double): TDataArray;
    function ZipEntryNames(const Path: string): TArray<string>;
    /// <summary>Extracts one member of the archive into FTemp and returns its
    /// path.</summary>
    function ExtractMember(const Path, Member: string): string;
    /// <summary>Runs one registered file tool. The caller owns Args and the
    /// result.</summary>
    function CallTool(const Name: string; Args: TJSONObject): TJSONObject;
    /// <summary>A finished fit_xrr job folder, jobs\JobId with measured.dat
    /// and a fit.xrcx carrying Params, as RunFitJob leaves it.</summary>
    procedure MakeJobFolder(const JobId: string; const Params: TXRCXCalcParams);
    /// <summary>The fit settings a periodic fit_xrr job would have written,
    /// every value away from the GUI default.</summary>
    function JobParams: TXRCXCalcParams;
    /// <summary>save_project with RUC_JSON and the given extra arguments
    /// spliced in (',"curves":{...}'); returns the written file's path.</summary>
    function SaveRuc(const Name, Extra: string): string;
    /// <summary>params.dsc of an .xrcx, extracted; the caller frees it.</summary>
    function ParamsOf(const XRCXPath: string): TMemIniFile;
    /// <summary>Asserts that every key of Section reads the same in both.</summary>
    procedure AssertSameSection(A, B: TMemIniFile; const Section, What: string);
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure HeadlessTree_SaveLoad_RoundTrip;
    [Test] procedure WriteXRCX_ContainsExpectedEntries;
    [Test] procedure WriteXRCX_ParamsVersion7_ThetaNot2Theta;
    [Test] procedure WriteXRCX_Overwrite_IsAtomicAndLeavesNoTmpFile;
    [Test] procedure ReadXRCX_RoundTrip_Structure;
    [Test] procedure ReadXRCX_RoundTrip_Extension;
    [Test] procedure WriteXRCX_Extension_IsMarkedFromFit;
    [Test] procedure ReadXRCX_SampleFromELNPlugins;
    [Test] procedure ListProjects_ReportsEveryProject;
    [Test] procedure SaveProject_ExistingFile_WithoutOverwrite_Refused;
    [Test] procedure SaveProject_NameWithPathSeparator_Refused;
    [Test] procedure SaveProject_ReservedDeviceName_Refused;
    [Test] procedure SaveProject_FromJob_UsesTheJobsFitSettings;
    [Test] procedure SaveProject_FromJob_ExplicitRangeAndPointsKeepPrecedence;
    [Test] procedure SaveProject_InboxCurve_PeriodicStructure_WritesMode1;
    [Test] procedure SaveProject_NoCurve_SingleLayers_WritesMode0;
  end;

implementation

const
  SAMPLE_DATA = '{"Stacks":[],"Subs":{"M":"Si","s":1,"r":2.33}}';

  RUC_JSON = '{"substrate":{"material":"SiO2","density":2.2,"sigma":3.0},' +
    '"stacks":[{"N":30,"layers":[{"material":"Ru","thickness":14.7,"sigma":3.0,"density":12.4},' +
    '{"material":"C","thickness":53.8,"sigma":3.0,"density":2.2}]}]}';

  ELN_SAMPLE = 'D:\APS\ELN\ELN3Plugins\TestFiles\Hard.xrcx';

  { Two single layers, no repeating stack: an irregular structure. }
  IRREGULAR_JSON = '{"substrate":{"material":"SiO2","density":2.2,"sigma":3.0},' +
    '"stacks":[{"N":1,"layers":[{"material":"Ru","thickness":30,"sigma":3.0,"density":12.4}]},' +
    '{"N":1,"layers":[{"material":"C","thickness":50,"sigma":3.0,"density":2.2}]}]}';

/// save_project calculates the curve, so it needs the Henke tables of the
/// materials it stores; without them the test says so instead of failing.
function HenkeTablesPresent: Boolean;
const
  Needed: array [0 .. 2] of string = ('Ru', 'C', 'SiO2');
var
  i: Integer;
  Dir: string;
begin
  Dir := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);
  for i := Low(Needed) to High(Needed) do
    if not TFile.Exists(Dir + Needed[i] + '.bin') then
      Exit(False);
  Result := True;
end;

{ ----------------------------------------------------------------- fixture -- }

procedure TTestMCPProjectFile.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Proj_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(FTemp);
  FSavedWorkDir := WorkDir;
  WorkDir := TWorkDir.Create(FTemp);
  WorkDir.EnsureLayout;
end;

procedure TTestMCPProjectFile.TearDown;
begin
  WorkDir.Free;
  WorkDir := FSavedWorkDir;
  try
    if (FTemp <> '') and TDirectory.Exists(FTemp) then
      TDirectory.Delete(FTemp, True);
  except
    // a leftover temp folder must not turn into a test failure
  end;
end;

function TTestMCPProjectFile.SampleXRCData: string;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
begin
  J := TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject;
  Assert.IsNotNull(J, 'test JSON must parse');
  try
    S := StructureFromJSON(J, Info);
    Result := StructureToXRCData(S, Info);
  finally
    J.Free;
  end;
end;

function TTestMCPProjectFile.Ramp(N: Integer; T0, DT: Double): TDataArray;
var
  i: Integer;
begin
  SetLength(Result, N);
  for i := 0 to N - 1 do
  begin
    Result[i].t := T0 + i * DT;
    Result[i].r := 1E-3 * (i + 1);
  end;
end;

function TTestMCPProjectFile.SampleProject: TXRCXProject;
begin
  Result := Default(TXRCXProject);
  Result.Params := DefaultCalcParams;
  Result.Params.Lambda := 1.5406;
  Result.Params.ThetaStart := 0.05;
  Result.Params.ThetaEnd := 3.0;
  Result.Params.Points := 5;
  Result.Params.Width := 0.01;
  Result.ModelTitle := 'RuC test';
  Result.Note := 'written by the test';
  Result.XRCData := SampleXRCData;
  Result.CalcCurve := Ramp(5, 0.05, 0.7);
  Result.DataTitle := 'RuC-01/scan1.dat';  // 16 chars: the length that exposed the GetString terminator bug
  Result.DataCurve := Ramp(4, 0.1, 0.5);
end;

function TTestMCPProjectFile.ZipEntryNames(const Path: string): TArray<string>;
var
  Z: TZipFile;
begin
  Z := TZipFile.Create;
  try
    Z.Open(Path, zmRead);
    Result := Z.FileNames;
    Z.Close;
  finally
    Z.Free;
  end;
end;

function TTestMCPProjectFile.ExtractMember(const Path, Member: string): string;
var
  Dir: string;
begin
  Dir := TPath.Combine(FTemp, 'x_' + Copy(TGUID.NewGuid.ToString, 2, 8));
  TDirectory.CreateDirectory(Dir);
  TZipFile.ExtractZipFile(Path, Dir);
  Result := TPath.Combine(Dir, Member);
  Assert.IsTrue(TFile.Exists(Result), Member + ' is not in the archive');
end;

function TTestMCPProjectFile.CallTool(const Name: string; Args: TJSONObject): TJSONObject;
var
  Reg: TToolRegistry;
begin
  Reg := TToolRegistry.Create;
  try
    RegisterFileTools(Reg);
    Result := Reg.Execute(Name, Args);
  finally
    Reg.Free;
  end;
end;

function TTestMCPProjectFile.JobParams: TXRCXCalcParams;
begin
  Result := DefaultCalcParams;
  Result.Lambda       := 1.540598;
  Result.ThetaStart   := 0.3;
  Result.ThetaEnd     := 1.72;
  Result.Width        := 0.02;
  Result.Points       := 300;
  Result.Polarisation := 1;
  Result.MinLimit     := 1E-6;
  Result.FitMode      := 1;          // periodic
  Result.FitIter      := 200;
  Result.FitPop       := 150;
  Result.PolyOrder    := 2;
  Result.PWChi        := False;
  Result.TWChi        := 1;
  Result.Tol          := 0.001;
  Result.Window       := 0.07;
  Result.LFPSO.NMax         := 200;
  Result.LFPSO.Pop          := 150;
  Result.LFPSO.Tolerance    := 0.001;
  Result.LFPSO.MovAvgWindow := 0.07;
  Result.LFPSO.ThetaWeight  := 1;
  Result.LFPSO.MaxPOrder    := 2;
  Result.LFPSO.Ksxr         := 0.15;
  Result.LFPSO.RangeSeed    := True;
end;

procedure TTestMCPProjectFile.MakeJobFolder(const JobId: string;
  const Params: TXRCXCalcParams);
var
  Dir: string;
  P: TXRCXProject;
begin
  Dir := TPath.Combine(WorkDir.JobsDir, JobId);
  TDirectory.CreateDirectory(Dir);
  WriteCurveText(TPath.Combine(Dir, 'measured.dat'), Ramp(20, 0.3, 0.07),
    'theta_deg', 'I', 'deg');
  P := SampleProject;
  P.Params := Params;
  P.DataTitle := JobId;
  P.DataCurve := Ramp(20, 0.3, 0.07);
  WriteXRCX(TPath.Combine(Dir, 'fit.xrcx'), P);
end;

function TTestMCPProjectFile.SaveRuc(const Name, Extra: string): string;
var
  Args, Res: TJSONObject;
begin
  Args := TJSONObject.ParseJSONValue(Format('{"structure":%s,"name":"%s"%s}',
    [RUC_JSON, Name, Extra])) as TJSONObject;
  Assert.IsNotNull(Args, 'the save_project arguments must parse');
  try
    Res := CallTool('save_project', Args);
    try
      Result := TPath.Combine(WorkDir.Root, Res.GetValue<string>('file'));
    finally
      Res.Free;
    end;
  finally
    Args.Free;
  end;
  Assert.IsTrue(TFile.Exists(Result), 'the project was written');
end;

function TTestMCPProjectFile.ParamsOf(const XRCXPath: string): TMemIniFile;
begin
  Result := TMemIniFile.Create(ExtractMember(XRCXPath, 'params.dsc'));
end;

procedure TTestMCPProjectFile.AssertSameSection(A, B: TMemIniFile;
  const Section, What: string);
var
  Keys: TStringList;
  i: Integer;
begin
  Keys := TStringList.Create;
  try
    B.ReadSection(Section, Keys);
    Assert.IsTrue(Keys.Count > 0, Format('[%s] is present in %s', [Section, What]));
    for i := 0 to Keys.Count - 1 do
      Assert.AreEqual(B.ReadString(Section, Keys[i], '<absent>'),
                      A.ReadString(Section, Keys[i], '<absent>'),
        Format('[%s] %s: %s', [Section, Keys[i], What]));
  finally
    Keys.Free;
  end;
end;

{ ------------------------------------------------------------- the spike --- }

procedure TTestMCPProjectFile.HeadlessTree_SaveLoad_RoundTrip;
var
  Tree: TXRCProjectTree;
  Root, Node: PVirtualNode;
  PD: PProjectData;
  FileName: string;
  Titles: TArray<string>;
  ModelData: string;
begin
  FileName := TPath.Combine(FTemp, 'project.dsc');

  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);

    Root := Tree.AddChild(nil, nil);
    PD := Tree.GetNodeData(Root);
    PD.Title := 'Models';
    PD.Group := gtModel;
    PD.RowType := prGroup;

    Node := Tree.AddChild(Root, nil);
    PD := Tree.GetNodeData(Node);
    PD.ID := 1;
    PD.Title := 'Model 1';
    PD.Group := gtModel;
    PD.RowType := prItem;
    PD.Active := True;
    PD.Visible := True;
    PD.Color := $0000FF;
    PD.Data := SAMPLE_DATA;

    Root := Tree.AddChild(nil, nil);
    PD := Tree.GetNodeData(Root);
    PD.Title := 'Data';
    PD.Group := gtData;
    PD.RowType := prGroup;

    Tree.SaveToFile(FileName);
  finally
    Tree.Free;
  end;

  Assert.IsTrue(TFile.Exists(FileName), 'project.dsc was not written');

  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);
    Tree.Version := 7;
    Tree.LoadFromFile(FileName);

    Titles := [];
    ModelData := '';
    Node := Tree.GetFirst;
    while Node <> nil do
    begin
      PD := Tree.GetNodeData(Node);
      Titles := Titles + [PD.Title];
      if (PD.Group = gtModel) and (PD.RowType = prItem) then
        ModelData := PD.Data;
      Node := Tree.GetNext(Node);
    end;
  finally
    Tree.Free;
  end;

  Assert.AreEqual(3, Length(Titles), 'node count');
  Assert.AreEqual('Models', Titles[0]);
  Assert.AreEqual('Model 1', Titles[1]);
  Assert.AreEqual('Data', Titles[2]);
  Assert.AreEqual(SAMPLE_DATA, ModelData);
end;

{ ------------------------------------------------------------- the writer -- }

procedure TTestMCPProjectFile.WriteXRCX_ContainsExpectedEntries;
var
  Path: string;
  Names: TArray<string>;
  Found: TStringList;
  S: string;
begin
  Path := TPath.Combine(FTemp, 'entries.xrcx');
  WriteXRCX(Path, SampleProject);
  Assert.IsTrue(TFile.Exists(Path), 'the archive was not written');

  Names := ZipEntryNames(Path);
  Found := TStringList.Create;
  try
    for S in Names do
      Found.Add(S);
    Assert.AreEqual(4, Found.Count, 'entry count');
    // Abbrevia extracts with '*.*' into a flat folder: no entry may carry a
    // directory prefix, or the GUI will not find it.
    for S in Names do
      Assert.IsTrue((Pos('/', S) = 0) and (Pos('\', S) = 0),
        'entry "' + S + '" carries a directory prefix');
    Assert.IsTrue(Found.IndexOf('params.dsc') >= 0, 'params.dsc');
    Assert.IsTrue(Found.IndexOf('project.dsc') >= 0, 'project.dsc');
    Assert.IsTrue(Found.IndexOf('calc.dat') >= 0, 'calc.dat');
    Assert.IsTrue(Found.IndexOf('data_2.dat') >= 0, 'data_2.dat');
  finally
    Found.Free;
  end;
end;

procedure TTestMCPProjectFile.WriteXRCX_ParamsVersion7_ThetaNot2Theta;
var
  Path, ParamsFile: string;
  INF: TMemIniFile;
  P: TXRCXProject;
begin
  P := SampleProject;
  Path := TPath.Combine(FTemp, 'params.xrcx');
  WriteXRCX(Path, P);

  ParamsFile := ExtractMember(Path, 'params.dsc');
  INF := TMemIniFile.Create(ParamsFile);
  try
    Assert.AreEqual(7, INF.ReadInteger('INFO', 'Version', 0), '[INFO] Version');
    Assert.IsFalse(INF.ReadBool('ANGLE', '2teta', True),
      '[ANGLE] 2teta must be 0: the stored angles are theta');
    Assert.AreEqual('0.05', INF.ReadString('ANGLE', 'Start', ''), '[ANGLE] Start');
    Assert.AreEqual('3', INF.ReadString('ANGLE', 'End', ''), '[ANGLE] End');
    Assert.AreEqual('1.5406', INF.ReadString('ANGLE', 'lambbda', ''),
      '[ANGLE] lambbda - the GUI key is misspelled and must stay so');
    Assert.AreEqual('5', INF.ReadString('PARAMS', 'N', ''), '[PARAMS] N');
    Assert.AreEqual(0, INF.ReadInteger('PARAMS', 'Mode', -1), '[PARAMS] Mode = theta scan');
    Assert.AreEqual(1, INF.ReadInteger('STATE', 'ActiveModel', -1), '[STATE] ActiveModel');
    Assert.AreEqual(2, INF.ReadInteger('STATE', 'LinkedData', -1), '[STATE] LinkedData');
    Assert.IsTrue(INF.ReadBool('STATE', 'LogScale', False), '[STATE] LogScale');
    // the advanced block the GUI's LoadAdvancedParams reads back
    Assert.AreEqual('0.3', INF.ReadString('LFPSO', 'Vmax', ''), '[LFPSO] Vmax');
    Assert.AreEqual(10, INF.ReadInteger('LFPSO', 'PolyFactor', 0), '[LFPSO] PolyFactor');
    Assert.AreEqual(-1, INF.ReadInteger('LFPSO', 'SmoothWindow', 0), '[LFPSO] SmoothWindow');
    Assert.AreEqual('1E-7', INF.ReadString('PARAMS', 'MinLimit', ''), '[PARAMS] MinLimit');
  finally
    INF.Free;
  end;
end;

procedure TTestMCPProjectFile.WriteXRCX_Overwrite_IsAtomicAndLeavesNoTmpFile;
var
  Path: string;
  First, Second, Read_: TXRCXProject;
begin
  Path := TPath.Combine(FTemp, 'overwrite.xrcx');

  First := SampleProject;
  First.ModelTitle := 'first version';
  WriteXRCX(Path, First);
  Assert.IsTrue(TFile.Exists(Path), 'the first write did not create the file');

  Second := SampleProject;
  Second.ModelTitle := 'second version';
  Second.CalcCurve := Ramp(3, 0.2, 1.1);
  WriteXRCX(Path, Second);

  Assert.IsTrue(TFile.Exists(Path), 'the overwrite did not leave the file behind');
  Assert.IsFalse(TFile.Exists(Path + '.tmp'), 'a .tmp file was left behind');

  Read_ := ReadXRCX(Path);
  Assert.AreEqual('second version', Read_.ModelTitle,
    'the overwritten content must be the new content and must be readable');
  Assert.AreEqual(3, Length(Read_.CalcCurve), 'the overwritten calc curve');
end;

{ ------------------------------------------------------------- the reader -- }

procedure TTestMCPProjectFile.ReadXRCX_RoundTrip_Structure;
var
  Path: string;
  Written, Read_: TXRCXProject;
begin
  Written := SampleProject;
  Path := TPath.Combine(FTemp, 'round.xrcx');
  WriteXRCX(Path, Written);

  Read_ := ReadXRCX(Path);

  Assert.AreEqual(7, Read_.Version, 'version');
  Assert.AreEqual(Written.ModelTitle, Read_.ModelTitle, 'model title');
  Assert.AreEqual(Written.Note, Read_.Note, 'description');
  Assert.AreEqual(Written.XRCData, Read_.XRCData, 'structure string');
  Assert.AreEqual(Written.DataTitle, Read_.DataTitle, 'data title');

  Assert.AreEqual(Length(Written.CalcCurve), Length(Read_.CalcCurve), 'calc points');
  Assert.AreEqual(Length(Written.DataCurve), Length(Read_.DataCurve), 'data points');
  Assert.AreEqual(Double(Written.CalcCurve[0].t), Double(Read_.CalcCurve[0].t), 1E-3, 'first theta');
  Assert.AreEqual(Double(Written.CalcCurve[4].t), Double(Read_.CalcCurve[4].t), 1E-3, 'last theta');
  Assert.AreEqual(Double(Written.DataCurve[0].r), Double(Read_.DataCurve[0].r), 1E-7, 'first data R');

  Assert.AreEqual(Double(Written.Params.Lambda), Double(Read_.Params.Lambda), 1E-9, 'lambda');
  Assert.AreEqual(Double(Written.Params.ThetaStart), Double(Read_.Params.ThetaStart), 1E-9, 'theta start');
  Assert.AreEqual(Double(Written.Params.ThetaEnd), Double(Read_.Params.ThetaEnd), 1E-9, 'theta end');
  Assert.AreEqual(Double(Written.Params.Width), Double(Read_.Params.Width), 1E-9, 'width');
  Assert.AreEqual(Written.Params.Points, Read_.Params.Points, 'points');
  Assert.AreEqual(Double(Written.Params.MinLimit), Double(Read_.Params.MinLimit), 1E-12, 'min limit');
end;

procedure TTestMCPProjectFile.ReadXRCX_RoundTrip_Extension;
var
  Path: string;
  Written, Read_: TXRCXProject;
  Ext: TXRCXProfileExt;
begin
  Written := SampleProject;

  Ext := Default(TXRCXProfileExt);
  Ext.StackID := 0;
  Ext.LayerID := 1;
  Ext.Subj := ptS;
  Ext.Coeffs := [9.5, 2.5, 3.5, 4.5];     // C[0..3]: order 3, three stored coefficients
  Written.Extensions := [Ext];

  Path := TPath.Combine(FTemp, 'ext.xrcx');
  WriteXRCX(Path, Written);
  Read_ := ReadXRCX(Path);

  Assert.AreEqual(1, Length(Read_.Extensions), 'one extension node');
  Assert.AreEqual(0, Read_.Extensions[0].StackID, 'stack');
  Assert.AreEqual(1, Read_.Extensions[0].LayerID, 'layer');
  Assert.IsTrue(Read_.Extensions[0].Subj = ptS, 'subject');
  Assert.AreEqual(4, Length(Read_.Extensions[0].Coeffs), 'C[0..order]');
  Assert.AreEqual(2.5, Double(Read_.Extensions[0].Coeffs[1]), 1E-6, 'C1');
  Assert.AreEqual(3.5, Double(Read_.Extensions[0].Coeffs[2]), 1E-6, 'C2');
  Assert.AreEqual(4.5, Double(Read_.Extensions[0].Coeffs[3]), 1E-6, 'C3');
  // ProjectSaveNode writes Poly[1..PolyCount]; the GUI refills C[0] from the
  // layer's own parameter every time it reads a profile back.
  Assert.AreEqual(0.0, Double(Read_.Extensions[0].Coeffs[0]), 1E-9,
    'C0 is not stored in the file, by design');
end;

{ Every extension WriteTree emits came out of a fit - WriteFitProject is the
  only caller that fills Extensions, from FitExtensions(Poly) - so each node
  must carry FromFit.

  The GUI reads that flag through TProjectData.IsFitExtension. RunFitting asks
  HasFitExtensions before it starts, and only offers to keep or clear the
  gradients of an earlier fit when the answer is True. An .xrcx written here
  without the flag opens in the GUI looking as if a human had drawn its
  gradients by hand: no prompt, and the next fit silently stacks a second set
  of gradients on top of the first.

  ReadXRCX cannot see this - TXRCXProfileExt has no FromFit field - so the test
  goes to the tree the file actually holds. }
procedure TTestMCPProjectFile.WriteXRCX_Extension_IsMarkedFromFit;
var
  Path, DscPath: string;
  P: TXRCXProject;
  Ext: TXRCXProfileExt;
  Tree: TXRCProjectTree;
  Node: PVirtualNode;
  PD: PProjectData;
  Found: Boolean;
  GotFromFit, GotEnabled: Boolean;
  GotExtType: TExtentionType;
begin
  P := SampleProject;

  Ext := Default(TXRCXProfileExt);
  Ext.StackID := 0;
  Ext.LayerID := 1;
  Ext.Subj := ptH;
  Ext.Coeffs := [9.5, 2.5, 3.5, 4.5];
  P.Extensions := [Ext];

  Path := TPath.Combine(FTemp, 'fromfit.xrcx');
  WriteXRCX(Path, P);
  DscPath := ExtractMember(Path, 'project.dsc');

  Found := False;
  GotFromFit := False;
  GotEnabled := False;
  GotExtType := etNone;

  Tree := TXRCProjectTree.Create(nil, 96);
  try
    Tree.NodeDataSize := SizeOf(TProjectData);
    Tree.Version := 7;
    Tree.LoadFromFile(DscPath);

    Node := Tree.GetFirst;
    while Node <> nil do
    begin
      PD := Tree.GetNodeData(Node);
      if PD.RowType = prExtension then
      begin
        Found := True;
        GotFromFit := PD.FromFit;
        GotEnabled := PD.Enabled;
        GotExtType := PD.ExtType;
      end;
      Node := Tree.GetNext(Node);
    end;
  finally
    Tree.Free;
  end;

  Assert.IsTrue(Found, 'the extension is missing from the written tree');
  Assert.IsTrue(GotEnabled, 'Enabled');
  Assert.AreEqual(Ord(etFunction), Ord(GotExtType), 'ExtType');
  Assert.IsTrue(GotFromFit,
    'a gradient written by a fit job must be marked FromFit, or the GUI will ' +
    'not offer to clear it before the next fit');
end;

procedure TTestMCPProjectFile.ReadXRCX_SampleFromELNPlugins;
var
  P: TXRCXProject;
begin
  if not TFile.Exists(ELN_SAMPLE) then
    Assert.Pass('the reference project is not on this machine: ' + ELN_SAMPLE);

  P := ReadXRCX(ELN_SAMPLE);
  Assert.AreEqual(7, P.Version, 'the reference project is version 7');
  Assert.IsTrue(Pos('"Stacks"', P.XRCData) > 0, 'the model structure string was read');
  Assert.IsTrue(Length(P.CalcCurve) > 0, 'calc.dat was read');
  Assert.AreEqual('', P.DataTitle, 'the reference project has no data node');
end;

{ -------------------------------------------------------------- the tools -- }

procedure TTestMCPProjectFile.ListProjects_ReportsEveryProject;
var
  Res: TJSONObject;
  Arr: TJSONArray;
  Obj: TJSONObject;
  Args: TJSONObject;
  P: TXRCXProject;
begin
  P := SampleProject;
  WriteXRCX(TPath.Combine(WorkDir.ProjectsDir, 'alpha.xrcx'), P);
  WriteXRCX(TPath.Combine(WorkDir.ProjectsDir, 'beta.xrcx'), P);
  // not a project: it must not be listed
  TFile.WriteAllText(TPath.Combine(WorkDir.ProjectsDir, 'notes.txt'), 'x');

  Args := TJSONObject.Create;
  try
    Res := CallTool('list_projects', Args);
    try
      Arr := Res.GetValue('projects') as TJSONArray;
      Assert.AreEqual(2, Arr.Count, 'two projects');
      Obj := Arr.Items[0] as TJSONObject;
      Assert.AreEqual('alpha', Obj.GetValue<string>('name'), 'name');
      Assert.AreEqual('projects\alpha.xrcx', Obj.GetValue<string>('file'), 'file');
      Assert.IsTrue(Obj.GetValue<Int64>('size') > 0, 'size');
      Assert.AreEqual(64, Length(Obj.GetValue<string>('sha256')), 'sha256 is 64 hex digits');
      Assert.IsTrue(Obj.GetValue<string>('modified_utc').EndsWith('Z'), 'modified_utc is UTC');
      Assert.AreEqual('beta', (Arr.Items[1] as TJSONObject).GetValue<string>('name'), 'sorted by name');
    finally
      Res.Free;
    end;
  finally
    Args.Free;
  end;
end;

procedure TTestMCPProjectFile.SaveProject_ExistingFile_WithoutOverwrite_Refused;
var
  Args: TJSONObject;
  Res: TJSONObject;
  Code: string;
begin
  WriteXRCX(TPath.Combine(WorkDir.ProjectsDir, 'dup.xrcx'), SampleProject);

  Args := TJSONObject.Create;
  try
    Args.AddPair('structure', TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject);
    Args.AddPair('name', 'dup');
    Code := '';
    Res := nil;
    try
      Res := CallTool('save_project', Args);
    except
      on E: EMCPError do
        Code := E.Code;
    end;
    Res.Free;
    Assert.AreEqual('already_exists', Code,
      'an existing project must not be replaced without "overwrite"');
  finally
    Args.Free;
  end;
end;

procedure TTestMCPProjectFile.SaveProject_NameWithPathSeparator_Refused;
var
  Args: TJSONObject;
  Res: TJSONObject;
  Code: string;
begin
  Args := TJSONObject.Create;
  try
    Args.AddPair('structure', TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject);
    Args.AddPair('name', '..\escape');
    Code := '';
    Res := nil;
    try
      Res := CallTool('save_project', Args);
    except
      on E: EMCPError do
        Code := E.Code;
    end;
    Res.Free;
    Assert.AreEqual('invalid_argument', Code, 'a name may not carry a path');
  finally
    Args.Free;
  end;
end;

procedure TTestMCPProjectFile.SaveProject_ReservedDeviceName_Refused;
var
  Args: TJSONObject;
  Res: TJSONObject;
  Code: string;
begin
  Args := TJSONObject.Create;
  try
    Args.AddPair('structure', TJSONObject.ParseJSONValue(RUC_JSON) as TJSONObject);
    Args.AddPair('name', 'CON');
    Code := '';
    Res := nil;
    try
      Res := CallTool('save_project', Args);
    except
      on E: EMCPError do
        Code := E.Code;
    end;
    Res.Free;
    Assert.AreEqual('invalid_argument', Code,
      'a Windows reserved device name must be refused');
  finally
    Args.Free;
  end;
end;

{ ------------------------------------------- save_project fit settings ---- }

procedure TTestMCPProjectFile.SaveProject_FromJob_UsesTheJobsFitSettings;
var
  Saved, JobFile: TMemIniFile;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  MakeJobFolder('fit-job-1', JobParams);

  Saved := ParamsOf(SaveRuc('from_job', ',"curves":{"job_id":"fit-job-1"}'));
  try
    JobFile := ParamsOf(TPath.Combine(TPath.Combine(WorkDir.JobsDir, 'fit-job-1'), 'fit.xrcx'));
    try
      AssertSameSection(Saved, JobFile, 'FIT', 'the saved project must carry the job''s fit settings');
      AssertSameSection(Saved, JobFile, 'LFPSO', 'the saved project must carry the job''s LFPSO settings');
      AssertSameSection(Saved, JobFile, 'PARAMS', 'the saved project must carry the job''s calculation parameters');
      AssertSameSection(Saved, JobFile, 'ANGLE', 'the saved project must carry the job''s angular range');
      Assert.AreEqual(1, Saved.ReadInteger('FIT', 'Mode', -1), 'periodic, as the job ran');
    finally
      JobFile.Free;
    end;
  finally
    Saved.Free;
  end;
end;

procedure TTestMCPProjectFile.SaveProject_FromJob_ExplicitRangeAndPointsKeepPrecedence;
var
  Saved, JobFile: TMemIniFile;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  MakeJobFolder('fit-job-2', JobParams);

  Saved := ParamsOf(SaveRuc('from_job_range',
    ',"curves":{"job_id":"fit-job-2"},"theta_min":0.1,"theta_max":2.5,"points":50'));
  try
    JobFile := ParamsOf(TPath.Combine(TPath.Combine(WorkDir.JobsDir, 'fit-job-2'), 'fit.xrcx'));
    try
      AssertSameSection(Saved, JobFile, 'FIT', 'the fit settings still come from the job');
      Assert.AreEqual('0.1', Saved.ReadString('ANGLE', 'Start', ''), 'an explicit theta_min wins');
      Assert.AreEqual('2.5', Saved.ReadString('ANGLE', 'End', ''), 'an explicit theta_max wins');
      Assert.AreEqual('50', Saved.ReadString('PARAMS', 'N', ''), 'an explicit points wins');
      Assert.AreEqual(JobFile.ReadString('ANGLE', 'width', 'a'),
                      Saved.ReadString('ANGLE', 'width', 'b'),
        'the resolution width not given still comes from the job');
    finally
      JobFile.Free;
    end;
  finally
    Saved.Free;
  end;
end;

procedure TTestMCPProjectFile.SaveProject_InboxCurve_PeriodicStructure_WritesMode1;
var
  Dir: string;
  Saved: TMemIniFile;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Dir := TPath.Combine(TPath.Combine(FTemp, 'inbox'), 'S1');
  TDirectory.CreateDirectory(Dir);
  TFile.WriteAllText(TPath.Combine(Dir, 'c.dat'),
    '0.5'#9'1.0'#13#10'0.6'#9'0.5'#13#10'0.7'#9'0.25'#13#10, TEncoding.ASCII);

  Saved := ParamsOf(SaveRuc('from_inbox', ',"curves":{"measurement_id":"S1/c.dat"}'));
  try
    Assert.AreEqual(1, Saved.ReadInteger('FIT', 'Mode', -1),
      'a structure with a repeating stack opens as a periodic fit');
    Assert.AreEqual('100', Saved.ReadString('FIT', 'Namx', ''), 'the other fit settings stay at the defaults');
    Assert.AreEqual('1000', Saved.ReadString('FIT', 'Pop', ''), 'the other fit settings stay at the defaults');
  finally
    Saved.Free;
  end;
end;

procedure TTestMCPProjectFile.SaveProject_NoCurve_SingleLayers_WritesMode0;
var
  Args, Res: TJSONObject;
  Saved: TMemIniFile;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables not installed on this machine');
    Exit;
  end;
  Args := TJSONObject.ParseJSONValue(Format('{"structure":%s,"name":"irregular"}',
    [IRREGULAR_JSON])) as TJSONObject;
  try
    Res := CallTool('save_project', Args);
    try
      Saved := ParamsOf(TPath.Combine(WorkDir.Root, Res.GetValue<string>('file')));
      try
        Assert.AreEqual(0, Saved.ReadInteger('FIT', 'Mode', -1),
          'single layers only: an irregular fit');
      finally
        Saved.Free;
      end;
    finally
      Res.Free;
    end;
  finally
    Args.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPProjectFile);

end.
