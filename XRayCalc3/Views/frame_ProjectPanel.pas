unit frame_ProjectPanel;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections, System.IniFiles,
  System.UITypes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.Menus, Vcl.ImgList, Vcl.Dialogs,
  Vcl.Clipbrd,
  RzPanel, RzButton, RzEdit,
  Vcl.VirtualImageList, Vcl.BaseImageCollection, Vcl.ImageCollection,
  VirtualTrees, VirtualTrees.BaseTree, VirtualTrees.Types,
  AbBase, AbBrowse, AbZBrows, AbZipper, AbUnzper,
  VCLTee.TeEngine, VCLTee.Series,
  unit_Types, unit_XRCProjectTree, unit_ChartManager,
  frame_CalcSettings, frame_ChartInfo, frame_ChartPages,
  unit_ProfilesManager, unit_RecentProjects, unit_Config,
  unit_SeriesIO, unit_FileUtils, unit_consts, unit_materials,
  unit_XRCStructure,
  System.ImageList, Vcl.ExtCtrls;

type
  TStringProc = procedure(const S: string) of object;

  { A gradient extension's target at the time an undo point was taken. }
  TGradientTarget = record
    Ext: PProjectData;
    StackID, LayerID: Integer;
  end;

  { An undo point: the structure, and where its gradients pointed - a delete,
    insert or move renumbers them (RemapGradients), so undoing the structure
    alone would leave them on the wrong layer. }
  THistoryEntry = record
    Structure: string;
    Targets: TArray<TGradientTarget>;
  end;

  TfrmProjectPanel = class(TFrame)
    tlbrFile: TRzToolbar;
    BtnNew: TRzToolButton;
    BtnOpen: TRzToolButton;
    btnReopenProject: TRzToolButton;
    rzspcr2: TRzSpacer;
    BtnSave: TRzToolButton;
    RzSpacer1: TRzSpacer;
    BtnPrint: TRzToolButton;
    tlbrProject: TRzToolbar;
    btnAddModel: TRzToolButton;
    BtnExport: TRzToolButton;
    BtnCopy: TRzToolButton;
    BtnPaste: TRzToolButton;
    BtnEdit: TRzToolButton;
    RzSpacer4: TRzSpacer;
    btnAddExtension: TRzToolButton;
    RzSpacer5: TRzSpacer;
    BtnRecycle: TRzToolButton;
    RzPanel5: TRzPanel;
    mmDescription: TRzMemo;
    vliProject: TVirtualImageList;
    vliTreeMarks: TVirtualImageList;
    pmProject: TPopupMenu;
    pmiEnabled: TMenuItem;
    pmiVisible: TMenuItem;
    pmiLinked: TMenuItem;
    pmiDrawOrder: TMenuItem;
    pmiToFront: TMenuItem;
    pmiForward: TMenuItem;
    pmiBackward: TMenuItem;
    pmiToBack: TMenuItem;
    pmiNorm: TMenuItem;
    Auto1: TMenuItem;
    Manual1: TMenuItem;
    N1: TMenuItem;
    Properties1: TMenuItem;
    N5: TMenuItem;
    pmCopytoclipboard: TMenuItem;
    pmExporttofile: TMenuItem;
    dlgOpenProject: TOpenDialog;
    dlgSaveProject: TSaveDialog;
    dlgLoadData: TOpenDialog;
    Zip: TAbZipper;
    UnZip: TAbUnZipper;
    procedure pmiEnabledClick(Sender: TObject);
    procedure pmiVisibleClick(Sender: TObject);
    procedure pmiLinkedClick(Sender: TObject);
    procedure pmiDrawOrderClick(Sender: TObject);
    procedure pmProjectPopup(Sender: TObject);
  private
    FProject: TXRCProjectTree;

    FProjectDir: string;
    FProjectName: string;
    FProjectFileName: string;
    FIgnoreFocusChange: Boolean;
    FProjectVersion: Byte;

    FModelsRoot: PVirtualNode;
    FDataRoot: PVirtualNode;

    LastNode, FLastModel: PVirtualNode;
    FLastData: PProjectData;

    FLastID: integer;
    FFitParams: TFitParams;
    FAutoSaveFileName: string;

    FOperationsStack: TStack<THistoryEntry>;
    FRecentProjects: TRecentProjectsManager;

    FChartMgr: TChartManager;
    FCalcSettings: TfrmCalcSettings;
    FChartInfo: TfrmChartInfo;
    FChartPages: TfrmChartPages;
    FProfileMgr: TProfileManager;
    FStructure: TXRCStructure;

    FOnCaptionChange: TStringProc;
    FOnCalcRun: TNotifyEvent;
    { Fired whenever the live structure is replaced by another model - a
      project loaded or created, or a different model node focused. }
    FOnModelChanged: TNotifyEvent;
    { The curves on the chart changed: which are visible, which data is
      linked, or the set itself (after RefreshChartLegend). }
    FOnCurvesChanged: TNotifyEvent;
    FProjectSerial: Integer;

    procedure CreateNewModel(Node: PVirtualNode);
    procedure DeleteModel(Node: PVirtualNode; Data: PProjectData);
    procedure DeleteData(Node: PVirtualNode; Data: PProjectData);
    procedure DeleteExtension(Node: PVirtualNode);
    procedure DeleteFolder(Node: PVirtualNode);
    function  DataName(Data: PProjectData): string;
    procedure PrepareProjectFolder(const FileName: string; Clear: Boolean);
    procedure ExtractProject(const FileName: string);
    procedure LoadProjectParams(var LinkedID, ActiveID: Integer);
    procedure RecoverProjectTree(const ActiveID: Integer);
    procedure RecoverDataCurves(const LinkedID: integer);
    function  SaveProjectINI(const IniFileName: string): boolean;
    procedure SaveCurveStyles(INF: TCustomIniFile);
    procedure LoadCurveStyles;
    procedure CreateFunctionProfileExtension(Node: PVirtualNode);
    function  FindParentModel(out Node: PVirtualNode): PVirtualNode;
    function  CreateChildNode(out Node: PVirtualNode): boolean;
    procedure EditProjectItem;
    procedure EditGradient(var Data: PProjectData);
    procedure EditTable(var Data: PProjectData);
    procedure LoadRecentProjectsList(ARecentMenu: TMenuItem; ARecentPopup: TPopupMenu);
    procedure OnRecentProjectClick(Sender: TObject; const FileName: string);
    function  GetLastData: PProjectData;
    function  CreateDataNode(ParentNode: PVirtualNode; const Title: string): PProjectData;
    function  HistoryEntry(const AStructure: string): THistoryEntry;
    procedure RemapGradients(Sender: TObject; const Map: TLayerMap);
    procedure ExtensionChanged;
  public
    destructor Destroy; override;

    procedure Init(AImageCollection: TImageCollection; ADPI: Integer;
      AChartMgr: TChartManager; ACalcSettings: TfrmCalcSettings;
      AChartInfo: TfrmChartInfo; AChartPages: TfrmChartPages;
      AProfileMgr: TProfileManager;
      ARecentMenu: TMenuItem; ARecentPopup: TPopupMenu);

    procedure SetStructure(AStructure: TXRCStructure);

    procedure ConnectFileActions(
      ANew, AOpen, AReopen, ASave, APrint: TBasicAction;
      AOpenDropDown: TPopupMenu);
    procedure ConnectProjectActions(
      AModelCreate, ADuplicate, AModelCopy, AModelPaste,
      AProperties, AExtension, ADelete: TBasicAction);
    procedure ConnectPopupActions(
      ANormAuto, ANormManual, AProperties,
      ACopyData, AExportData: TBasicAction);

    procedure SetToolbarsEnabled(Value: Boolean);
    procedure SetDescription(const Text: string);

    { Project file operations }
    procedure NewProject;
    procedure OpenProject;
    { Both return False when the user cancels the Save As dialog. }
    function  SaveCurrentProject: Boolean;
    function  SaveProjectAs: Boolean;
    { Asks Save / Don't save / Cancel before the current project is replaced;
      True when it may go - saved or discarded. }
    function  MayReplaceProject(const Caption, Question: string): Boolean;
    procedure ReopenProject;

    { Tree operations }
    procedure CreateModel;
    procedure DuplicateModel;
    procedure CopyModel;
    procedure PasteModel;
    procedure CopySelectedItem;
    procedure DeleteSelectedItems;
    procedure EditSelectedItem;
    procedure EditModelText;
    procedure ImportStructure;
    procedure AddFolder;
    procedure AddExtension;

    { Data operations }
    procedure LoadData;
    procedure PasteData;
    procedure SaveData;
    procedure SaveActiveData;
    /// Appends Line to the active data item's description.
    procedure AppendActiveDataNote(const Line: string);

    { Project loading/saving }
    procedure LoadProject(const FileName: string);
    procedure SaveProject(const FileName: string);
    procedure CreateDefaultProject;

    { Tree event handlers }
    procedure ProjectChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ProjectDblClick(Sender: TObject);
    procedure ProjectFocusChanging(Sender: TBaseVirtualTree; OldNode,
      NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex;
      var Allowed: Boolean);

    { Fit/profile support }
    function  GetProfileFunctions: TProfileFunctions;
    function  IsProfileEnabled: Boolean;
    function  HasFitExtensions: Boolean;
    procedure ClearFitExtensions;
    procedure CreateFitGradientExtensions(const P: TProfileFunctions);
    procedure UpdateFitGradientExtensions(const P: TProfileFunctions);
    procedure MatchToStructure;
    /// Redraws the thickness, roughness and density pages for Structure with
    /// the active model's gradients. Unlike MatchToStructure it does not write
    /// Structure back into the active model.
    procedure PlotProfiles;

    { Utilities }
    procedure CreateProfileExtension(const AFromFit: Boolean = False);
    procedure RescaleChart;
    procedure RefreshChartLegend;
    { The chart series of the models shown on the chart, in tree order. }
    function  VisibleModelSeries: TArray<TFastLineSeries>;
    { The linked data's chart series and node ID, nil when no data is linked.
      Found by walking the tree, so a LinkedData left pointing at a freed node
      is never read. }
    function  LinkedDataSeries(out ID: Integer): TFastLineSeries;
    procedure SyncSeriesVisibility(Series: TChartSeries);
    procedure SaveHistory;
    { Restores the structure and the gradients' targets saved by the last
      SaveHistory. False when there is nothing to undo. }
    function  Undo: Boolean;
    procedure AutoSave;
    procedure GenerateAutosaveName;
    function  GradientTitle(const P: TFuncProfileRec): string;
    function  ActiveModelSeries: TFastLineSeries; inline;
    function  ActiveDataSeries: TFastLineSeries; inline;
    function  IsNonPeriodicProfile: Boolean; inline;

    { Properties }
    property Project: TXRCProjectTree read FProject;
    property ProjectDir: string read FProjectDir;
    property ProjectName: string read FProjectName;
    property ProjectFileName: string read FProjectFileName write FProjectFileName;
    property FitParams: TFitParams read FFitParams write FFitParams;
    property IgnoreFocusChange: Boolean read FIgnoreFocusChange write FIgnoreFocusChange;
    property ModelsRoot: PVirtualNode read FModelsRoot;
    property DataRoot: PVirtualNode read FDataRoot;
    property LastModel: PVirtualNode read FLastModel write FLastModel;
    property LastData: PProjectData read GetLastData;
    property AutoSaveFileName: string read FAutoSaveFileName;
    property RecentProjects: TRecentProjectsManager read FRecentProjects;
    property Structure: TXRCStructure read FStructure;

    property OnCaptionChange: TStringProc read FOnCaptionChange write FOnCaptionChange;
    property OnCalcRun: TNotifyEvent read FOnCalcRun write FOnCalcRun;
    property OnModelChanged: TNotifyEvent read FOnModelChanged write FOnModelChanged;
    property OnCurvesChanged: TNotifyEvent read FOnCurvesChanged write FOnCurvesChanged;
    { Changes whenever another project is loaded or a new one created, so a
      number remembered from one project is not taken for the next one's. }
    property ProjectSerial: Integer read FProjectSerial;
  end;

implementation

uses
  System.Win.ComObj, System.IOUtils, System.JSON, AbUtils,
  unit_xrdml, unit_CurveStyle, unit_SaveBeforeDialog,
  editor_proj_item, editor_ProfileFunction, editor_ProfileTable,
  editor_JSON, frm_ExtensionType;

{$R *.dfm}

const
  GradientLabels: array [0..2] of string = ('H', 'S', 'rho');

  { Edge of the project tree markers at 96 dpi, matching the 41 px wide first
    column of the tree. }
  TreeMarkSize = 16;

{ --- Old XRCX format (v2) support --- }

function ModelBinToJSON(const FileName: string): string;
{ Parses old X-RayCalc model_*.bin files (VirtualTreeView binary format).
  Scans for UserChunk (type=4) headers and extracts node data serialized by
  TreeSaveNode: Text(wstr) + RowType(1 byte) + H/s/r(wstr) + N(4 bytes).
  In VT's stream, child nodes appear before their parent, so layers precede
  their owning stack. Returns JSON compatible with TXRCStructure.FromString. }

  function ReadWStr(const Bytes: TBytes; var Pos: Integer): string;
  var
    Sz: Cardinal;
  begin
    Result := '';
    if Pos + 4 > Length(Bytes) then Exit;
    Sz := PCardinal(@Bytes[Pos])^;
    Inc(Pos, 4);
    if (Sz < 1) or (Sz > 200) or (Pos + Integer(Sz) > Length(Bytes)) then
    begin
      Pos := Length(Bytes);
      Exit;
    end;
    if Bytes[Pos + Integer(Sz) - 1] = 0 then
      Result := TEncoding.Unicode.GetString(Bytes, Pos, Integer(Sz) - 1);
    Inc(Pos, Integer(Sz));
  end;

const
  UserChunkType = 4;
  rtStack     = 0;
  rtLayer     = 1;
  rtSubstrate = 2;
type
  TBinLayer = record
    Material: string;
    H, S, R: Single;
  end;
  TBinStack = record
    Title: string;
    N: Integer;
    Layers: array of TBinLayer;
  end;
var
  FS: TFileStream;
  Bytes: TBytes;
  I, Pos, Len, ChunkType, ChunkSize: Integer;
  NodeText, NodeH, NodeS, NodeR: string;
  RowType: Byte;
  N: Integer;
  V: Single;
  PendingLayers: array of TBinLayer;
  PendingCount, StackCount: Integer;
  Stacks: array of TBinStack;
  SubsMaterial: string;
  SubsS, SubsR: Single;
  HasSubs: Boolean;
  J: Integer;
  JRoot, JSub, JStack, JLayer: TJSONObject;
  JStacks, JLayers: TJSONArray;
begin
  Result := '';
  if not FileExists(FileName) then Exit;

  FS := TFileStream.Create(FileName, fmOpenRead or fmShareDenyNone);
  try
    if FS.Size < 20 then Exit;
    SetLength(Bytes, FS.Size);
    FS.ReadBuffer(Bytes[0], FS.Size);
  finally
    FS.Free;
  end;

  Len := Length(Bytes);
  StackCount := 0;
  PendingCount := 0;
  HasSubs := False;
  SubsS := 0;
  SubsR := 0;

  I := 0;
  while I < Len - 12 do
  begin
    ChunkType := PInteger(@Bytes[I])^;
    if ChunkType <> UserChunkType then
    begin
      Inc(I);
      Continue;
    end;
    ChunkSize := PInteger(@Bytes[I + 4])^;
    if (ChunkSize < 10) or (ChunkSize > 500) or (I + 8 + ChunkSize > Len) then
    begin
      Inc(I);
      Continue;
    end;

    Pos := I + 8;

    NodeText := ReadWStr(Bytes, Pos);
    if (Pos >= Len) or (NodeText = '') then begin Inc(I); Continue; end;

    RowType := Bytes[Pos];
    Inc(Pos);
    if RowType > 2 then begin Inc(I); Continue; end;

    NodeH := ReadWStr(Bytes, Pos);
    NodeS := ReadWStr(Bytes, Pos);
    NodeR := ReadWStr(Bytes, Pos);

    if Pos + 4 > Len then begin Inc(I); Continue; end;
    N := PInteger(@Bytes[Pos])^;
    Inc(Pos, 4);

    case RowType of
      rtLayer:
      begin
        if not TryStrToFloat(StringReplace(NodeH, ',', '.', []),
          V, TFormatSettings.Invariant) then
        begin
          Inc(I);
          Continue;
        end;

        Inc(PendingCount);
        SetLength(PendingLayers, PendingCount);
        PendingLayers[PendingCount - 1].Material := NodeText;
        PendingLayers[PendingCount - 1].H := V;
        TryStrToFloat(StringReplace(NodeS, ',', '.', []),
          PendingLayers[PendingCount - 1].S, TFormatSettings.Invariant);
        TryStrToFloat(StringReplace(NodeR, ',', '.', []),
          PendingLayers[PendingCount - 1].R, TFormatSettings.Invariant);
      end;

      rtStack:
      begin
        if N > 10000 then begin Inc(I); Continue; end;

        Inc(StackCount);
        SetLength(Stacks, StackCount);
        Stacks[StackCount - 1].Title := NodeText;
        Stacks[StackCount - 1].N := N;
        SetLength(Stacks[StackCount - 1].Layers, PendingCount);
        for J := 0 to PendingCount - 1 do
          Stacks[StackCount - 1].Layers[J] := PendingLayers[J];
        PendingCount := 0;
        SetLength(PendingLayers, 0);
      end;

      rtSubstrate:
      begin
        SubsMaterial := NodeText;
        TryStrToFloat(StringReplace(NodeS, ',', '.', []),
          SubsS, TFormatSettings.Invariant);
        TryStrToFloat(StringReplace(NodeR, ',', '.', []),
          SubsR, TFormatSettings.Invariant);
        HasSubs := True;
      end;
    end;

    I := Pos;
  end;

  if StackCount = 0 then Exit;

  // Build JSON matching TXRCStructure.FromString format
  JRoot := TJSONObject.Create;
  try
    JStacks := TJSONArray.Create;
    for I := 0 to StackCount - 1 do
    begin
      JStack := TJSONObject.Create;
      JStack.AddPair('T', Stacks[I].Title);
      JStack.AddPair('N', Stacks[I].N);

      JLayers := TJSONArray.Create;
      for J := 0 to High(Stacks[I].Layers) do
      begin
        JLayer := TJSONObject.Create;
        JLayer.AddPair('M', Stacks[I].Layers[J].Material);
        JLayer.AddPair('H', TJSONNumber.Create(Stacks[I].Layers[J].H));
        JLayer.AddPair('s', TJSONNumber.Create(Stacks[I].Layers[J].S));
        JLayer.AddPair('r', TJSONNumber.Create(Stacks[I].Layers[J].R));
        JLayers.Add(JLayer);
      end;
      JStack.AddPair('Layers', JLayers);
      JStacks.Add(JStack);
    end;

    JSub := TJSONObject.Create;
    if HasSubs then
    begin
      JSub.AddPair('M', SubsMaterial);
      JSub.AddPair('s', TJSONNumber.Create(SubsS));
      JSub.AddPair('r', TJSONNumber.Create(SubsR));
    end
    else begin
      JSub.AddPair('M', 'Si');
      JSub.AddPair('s', TJSONNumber.Create(5.0));
      JSub.AddPair('r', TJSONNumber.Create(2.2));
    end;

    JRoot.AddPair('Stacks', JStacks);
    JRoot.AddPair('Subs', JSub);
    Result := JRoot.ToString;
  finally
    JRoot.Free;
  end;
end;

{ TfrmProjectPanel }

destructor TfrmProjectPanel.Destroy;
begin
  FreeAndNil(FOperationsStack);
  FreeAndNil(FRecentProjects);
  inherited;
end;

function TfrmProjectPanel.GetLastData: PProjectData;
begin
  Result := FLastData;
end;

function TfrmProjectPanel.ActiveModelSeries: TFastLineSeries;
begin
  Result := FChartMgr.Series[FProject.ActiveModel.CurveID];
end;

function TfrmProjectPanel.ActiveDataSeries: TFastLineSeries;
begin
  Result := FChartMgr.Series[FProject.ActiveData.CurveID];
end;

function TfrmProjectPanel.IsNonPeriodicProfile: Boolean;
begin
  Result := IsProfileEnabled and (FCalcSettings.FittingMode <> fmPeriodic);
end;

procedure TfrmProjectPanel.Init(AImageCollection: TImageCollection; ADPI: Integer;
  AChartMgr: TChartManager; ACalcSettings: TfrmCalcSettings;
  AChartInfo: TfrmChartInfo; AChartPages: TfrmChartPages;
  AProfileMgr: TProfileManager;
  ARecentMenu: TMenuItem; ARecentPopup: TPopupMenu);
begin
  vliProject.ImageCollection := AImageCollection;
  vliTreeMarks.ImageCollection := AImageCollection;
  vliTreeMarks.SetSize(TreeMarkSize * ADPI div 96, TreeMarkSize * ADPI div 96);

  FProject := TXRCProjectTree.Create(Self, ADPI);
  FProject.MarkerImages := vliTreeMarks;
  FProject.Parent := Self;
  FProject.PopupMenu := pmProject;
  FProject.NodeDataSize := SizeOf(TProjectData);

  FChartMgr := AChartMgr;
  FCalcSettings := ACalcSettings;
  FChartInfo := AChartInfo;
  FChartPages := AChartPages;
  FProfileMgr := AProfileMgr;

  FOperationsStack := TStack<THistoryEntry>.Create;
  FOperationsStack.Capacity := 10;

  LoadRecentProjectsList(ARecentMenu, ARecentPopup);
end;

procedure TfrmProjectPanel.SetStructure(AStructure: TXRCStructure);
begin
  FStructure := AStructure;
  FStructure.OnLayersRenumbered := RemapGradients;
end;

procedure TfrmProjectPanel.ConnectFileActions(
  ANew, AOpen, AReopen, ASave, APrint: TBasicAction;
  AOpenDropDown: TPopupMenu);

  procedure AssignAction(AButton: TRzToolButton; AAction: TBasicAction);
  var
    SavedIndex: Integer;
    SavedHint: string;
  begin
    SavedIndex := AButton.ImageIndex;
    SavedHint := AButton.Hint;
    AButton.Action := AAction;
    AButton.ImageIndex := SavedIndex;
    // a runtime Action assignment overwrites Hint even when the action has none
    if AButton.Hint = '' then
      AButton.Hint := SavedHint;
  end;

begin
  AssignAction(BtnNew, ANew);
  AssignAction(BtnOpen, AOpen);
  AssignAction(btnReopenProject, AReopen);
  AssignAction(BtnSave, ASave);
  AssignAction(BtnPrint, APrint);
  BtnOpen.DropDownMenu := AOpenDropDown;
end;

procedure TfrmProjectPanel.ConnectProjectActions(
  AModelCreate, ADuplicate, AModelCopy, AModelPaste,
  AProperties, AExtension, ADelete: TBasicAction);

  procedure AssignAction(AButton: TRzToolButton; AAction: TBasicAction);
  var
    SavedIndex: Integer;
    SavedHint: string;
  begin
    SavedIndex := AButton.ImageIndex;
    SavedHint := AButton.Hint;
    AButton.Action := AAction;
    AButton.ImageIndex := SavedIndex;
    // a runtime Action assignment overwrites Hint even when the action has none
    if AButton.Hint = '' then
      AButton.Hint := SavedHint;
  end;

begin
  AssignAction(btnAddModel, AModelCreate);
  AssignAction(BtnExport, ADuplicate);
  AssignAction(BtnCopy, AModelCopy);
  AssignAction(BtnPaste, AModelPaste);
  AssignAction(BtnEdit, AProperties);
  AssignAction(btnAddExtension, AExtension);
  AssignAction(BtnRecycle, ADelete);
end;

procedure TfrmProjectPanel.ConnectPopupActions(
  ANormAuto, ANormManual, AProperties,
  ACopyData, AExportData: TBasicAction);
begin
  Auto1.Action := ANormAuto;
  Manual1.Action := ANormManual;
  Properties1.Action := AProperties;
  pmCopytoclipboard.Action := ACopyData;
  pmCopytoclipboard.Caption := 'Copy data';
  pmExporttofile.Action := AExportData;
  pmExporttofile.Caption := 'Export Data';
end;

procedure TfrmProjectPanel.SetToolbarsEnabled(Value: Boolean);
begin
  tlbrFile.Enabled := Value;
  tlbrProject.Enabled := Value;
end;

procedure TfrmProjectPanel.SetDescription(const Text: string);
begin
  mmDescription.Lines.Text := Text;
end;

{ --- Popup menu handlers --- }

procedure TfrmProjectPanel.pmiEnabledClick(Sender: TObject);
begin
  FLastData.Enabled := not FLastData.Enabled;
  FProject.Repaint;
  if FLastData.RowType = prExtension then
    ExtensionChanged;
end;

procedure TfrmProjectPanel.pmiLinkedClick(Sender: TObject);
begin
  if not pmiLinked.Checked then
    FProject.LinkedData := nil
  else
    FProject.LinkedData := FLastData;
  FProject.Repaint;
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.pmiVisibleClick(Sender: TObject);
begin
  FChartMgr.Series[FLastData.CurveID].Active := pmiVisible.Checked;
  FChartMgr.Series[FLastData.CurveID].Visible := pmiVisible.Checked;
  FLastData.Visible := pmiVisible.Checked;
  FProject.Repaint;
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.pmiDrawOrderClick(Sender: TObject);
begin
  FChartMgr.MoveSeries(FLastData.CurveID, TDrawOrderMove((Sender as TMenuItem).Tag));
end;

procedure TfrmProjectPanel.pmProjectPopup(Sender: TObject);
var
  IsModel, IsProfile: boolean;
  Order: TArray<Integer>;
  Place: Integer;
begin
  case FLastData.RowType of
    prItem:
      begin
        IsModel := FLastData.IsModel;
        pmiEnabled.Visible := False;
        pmiVisible.Visible := True;
        pmiVisible.Checked := FLastData.Visible;
        pmiLinked.Visible  := not IsModel;
        pmiLinked.Checked  := FLastData = FProject.LinkedData;

        Order := FChartMgr.DrawOrder;
        Place := TArray.IndexOf<Integer>(Order, FLastData.CurveID);
        pmiDrawOrder.Visible := Place >= 0;
        pmiToFront.Enabled   := Place < High(Order);
        pmiForward.Enabled   := Place < High(Order);
        pmiBackward.Enabled  := Place > 0;
        pmiToBack.Enabled    := Place > 0;
        pmiNorm.Visible    := not IsModel;
        pmCopytoclipboard.Visible := not IsModel;
        pmExporttofile.Visible    := not IsModel;
      end;
    prExtension:
      begin
        pmiNorm.Visible := False;
        pmiEnabled.Visible := True;
        pmiEnabled.Checked := FLastData.Enabled;
        pmiVisible.Visible := False;
        pmiLinked.Visible  := False;
        pmiDrawOrder.Visible := False;
        IsProfile := FLastData.ExtType = etTable;
        pmCopytoclipboard.Visible := IsProfile;
        pmExporttofile.Visible    := IsProfile;
      end;
  else
    begin
      { A group or folder: no curve of its own. Its CurveID was never written,
        so it reads 0 and would act on the first model's curve. }
      pmiEnabled.Visible   := False;
      pmiVisible.Visible   := False;
      pmiLinked.Visible    := False;
      pmiDrawOrder.Visible := False;
    end;
  end;
end;

{ --- Internal helpers --- }

procedure TfrmProjectPanel.CreateNewModel(Node: PVirtualNode);
var
  PL: PVirtualNode;
begin
  PL := FProject.AddChild(Node, Nil);
  FProject.ActiveModel := FProject.GetNodeData(PL);
  FProject.ActiveModel.ID := FLastID;
  FProject.ActiveModel.Title := 'Model ' + IntToStr(FLastID);
  FProject.ActiveModel.Group := gtModel;
  FProject.ActiveModel.RowType := prItem;

  FChartMgr.AddSeries(FProject.ActiveModel);
  FProject.Expanded[Node] := True;
  inc(FLastID);
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.DeleteModel(Node: PVirtualNode; Data: PProjectData);
begin
  FChartMgr.DeleteSeries(Data.CurveID);
  FProject.DeleteNode(Node);
  FProject.Repaint;
  FProject.ActiveModel := nil;
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.DeleteData(Node: PVirtualNode; Data: PProjectData);
begin
  DeleteFile(DataName(Data));
  FChartMgr.DeleteSeries(Data.CurveID);
  FProject.DeleteNode(Node);
  FProject.Refresh;
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.DeleteExtension(Node: PVirtualNode);
begin
  FProject.DeleteNode(Node);
  FProject.Refresh;
end;

procedure TfrmProjectPanel.DeleteFolder(Node: PVirtualNode);
begin
  if Node.ChildCount = 0 then
    FProject.DeleteNode(Node)
  else
    ShowMessage('The folder is not empty! Can''t delete !');
end;

function TfrmProjectPanel.DataName(Data: PProjectData): string;
begin
  Result := Format('%sdata_%d.dat', [FProjectDir, Data.ID])
end;

procedure TfrmProjectPanel.PrepareProjectFolder(const FileName: string; Clear: Boolean);
begin
  FProjectFileName := FileName;
  FProjectName := ExtractFileName(FileName);
  FProjectDir := IncludeTrailingPathDelimiter(TConfig.TempPath + CreateClassID);

  if Clear then
  begin
    if DirectoryExists(FProjectDir, False) then
      ClearDir(FProjectDir);
    CreateDir(FProjectDir);
  end;
end;

procedure TfrmProjectPanel.ExtractProject(const FileName: string);
begin
  UnZip.BaseDirectory := FProjectDir;
  UnZip.FileName := FileName;
  UnZip.OpenArchive(FileName);
  UnZip.ExtractFiles('*.*');
  UnZip.CloseArchive;
end;

procedure TfrmProjectPanel.LoadProjectParams(var LinkedID, ActiveID: Integer);
var
  INF: TMemIniFile;
begin
  INF := TMemIniFile.Create(FProjectDir + PARAMETERS_FILE_NAME);
  try
    FCalcSettings.LoadFromINI(INF);
    FChartInfo.LoadFromINI(INF);

    LinkedID := INF.ReadInteger('STATE', 'LinkedData', -1);
    ActiveID := INF.ReadInteger('STATE', 'ActiveModel', -1);
    FChartInfo.Chart.LeftAxis.Logarithmic := INF.ReadBool('STATE', 'LogScale', True);
    FChartInfo.UpdateAxisFormat;
    FProjectVersion := INF.ReadInteger('INFO', 'Version', 0);

    FCalcSettings.LoadAdvancedParams(INF, FFitParams);
  finally
    INF.Free;
  end;
end;

procedure TfrmProjectPanel.RecoverProjectTree(const ActiveID: Integer);
var
  Node, First: PVirtualNode;
  Data: PProjectData;
  BinFile: string;
begin
  FProject.LinkedData := nil;
  FProject.Version := FProjectVersion;
  FProject.LoadFromFile(FProjectDir + PROJECT_FILE_NAME);

  FProject.Rescale;
  FProject.Repaint;

  FModelsRoot := FProject.GetFirst;
  FDataRoot := FProject.GetNextSibling(FModelsRoot);

  { A saved project restores whatever collapsed state it was stored with, which
    hides models or data behind a node the user never opened. }
  FProject.Expanded[FModelsRoot] := True;
  FProject.Expanded[FDataRoot] := True;

  FChartMgr.ClearAll;
  FProject.ActiveModel := nil;
  First := nil;
  FLastModel := nil;

  Node := FProject.GetFirstChild(FProject.GetFirst);
  while Node <> FDataRoot do
  begin
    Data := FProject.GetNodeData(Node);
    if Data.RowType = prItem then
    begin
      // Old format (v2): model data stored in model_N.bin, not JSON
      if (Data.Group = gtModel) and (Data.Data = '') then
      begin
        BinFile := Format('%smodel_%d.bin', [FProjectDir, Data.ID]);
        if FileExists(BinFile) then
          Data.Data := ModelBinToJSON(BinFile);
      end;

      if First = nil then
        First := Node;

      if ActiveID = Data.ID then
      begin
        FProject.ActiveModel := Data;
        LastNode := Node;
        FLastModel := Node;
        FLastData := Data;
      end;
      FChartMgr.AddSeries(Data);

      if Data.ID > FLastID then
        FLastID := Data.ID;
    end;
    Node := FProject.GetNext(Node);
  end;

  if FProject.ActiveModel = nil then
  begin
    { Falling back to the first model because [STATE] ActiveModel named none of
      them. It has to leave behind everything the matching branch above leaves
      behind, not just the two the chart needs.

      FLastModel is the node HasFitExtensions, ClearFitExtensions and both
      gradient writers walk from. Left nil, HasFitExtensions exits False on its
      nil guard, so RunFitting never offers to keep or clear an earlier fit's
      gradients and CreateFitGradientExtensions hangs the new ones off the tree
      root via AddChild(nil). FLastData would otherwise still point into the
      previous project's node memory, freed by the LoadFromFile above.

      Selecting the node cannot stand in for this: LoadProject holds
      IgnoreFocusChange for the whole of RecoverProjectTree, and ProjectChange
      exits on Node = LastNode in any case, because LastNode is assigned here
      before the selection is made. }
    LastNode := First;
    FLastModel := First;
    FProject.ActiveModel := FProject.GetNodeData(First);
    FLastData := FProject.ActiveModel;
  end;

  inc(FLastID);

  if FProject.ActiveModel = nil then
  begin
    FProject.FocusedNode := First;
    FProject.Selected[First] := True;
  end
  else
  begin
    FProject.FocusedNode := LastNode;
    FProject.Selected[LastNode] := True;
  end;

  Structure.FromString(FProject.ActiveModel.Data);
  Structure.PeriodicMode := FCalcSettings.FittingMode = fmPeriodic;
end;

procedure TfrmProjectPanel.RecoverDataCurves(const LinkedID: integer);
var
  Node: PVirtualNode;
  Data: PProjectData;
  s: string;
begin
  FProject.ActiveData := nil;

  Node := FProject.GetFirstChild(FDataRoot);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.RowType = prItem) and FileExists(DataName(Data)) then
    begin
      if FProject.ActiveData = nil then
        FProject.ActiveData := Data;

      if Data.ID = LinkedID then
        FProject.LinkedData := Data;

      { Models and data share one ID space, and a data curve's file is named
        after its ID: the next free ID has to clear the data too, or the next
        curve loaded takes an existing curve's ID and overwrites its file. }
      if Data.ID >= FLastID then
        FLastID := Data.ID + 1;

      FChartMgr.AddSeries(Data);
      SeriesFromFile(FChartMgr.Series[Data.CurveID], DataName(Data), s);
      FChartMgr.Series[Data.CurveID].Active := Data.Visible;
      FChartMgr.Series[Data.CurveID].Visible := Data.Visible;
    end
    else
      FProject.DeleteNode(Node);
    Node := FProject.GetNext(Node);
  end;
end;

{ Each curve's transparency and the chart's draw order, by the node's group and
  ID (see unit_CurveStyle). A curve's chart series holds both, not the node data. }
procedure TfrmProjectPanel.SaveCurveStyles(INF: TCustomIniFile);
var
  Node: PVirtualNode;
  Data: PProjectData;
  Keys, Order: TArray<string>;
  Key: string;
  CurveID: Integer;
begin
  SetLength(Keys, Length(FChartMgr.Series));

  Node := FProject.GetFirst;
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.RowType = prItem) and (Data.CurveID >= 0) and (Data.CurveID <= High(Keys)) then
    begin
      Key := CurveKey(Data.IsModel, Data.ID);
      Keys[Data.CurveID] := Key;
      WriteCurveTransparency(INF, Key, FChartMgr.GetTransparency(Data.CurveID));
    end;
    Node := FProject.GetNext(Node);
  end;

  Order := nil;
  for CurveID in FChartMgr.DrawOrder do
    if Keys[CurveID] <> '' then
      Order := Order + [Keys[CurveID]];
  WriteDrawOrder(INF, Order);
end;

{ After every curve of a loaded project is on the chart. A project saved before
  3.9.4 has neither key: every curve stays opaque, in creation order. }
procedure TfrmProjectPanel.LoadCurveStyles;
var
  INF: TMemIniFile;
  Node: PVirtualNode;
  Data: PProjectData;
  CurveOf: TDictionary<string, Integer>;
  Order: TArray<Integer>;
  Key: string;
  CurveID: Integer;
begin
  INF := TMemIniFile.Create(FProjectDir + PARAMETERS_FILE_NAME);
  CurveOf := TDictionary<string, Integer>.Create;
  try
    Node := FProject.GetFirst;
    while Node <> nil do
    begin
      Data := FProject.GetNodeData(Node);
      if Data.RowType = prItem then
      begin
        Key := CurveKey(Data.IsModel, Data.ID);
        CurveOf.AddOrSetValue(Key, Data.CurveID);
        FChartMgr.SetTransparency(Data.CurveID, ReadCurveTransparency(INF, Key));
      end;
      Node := FProject.GetNext(Node);
    end;

    Order := nil;
    for Key in ReadDrawOrder(INF) do
      if CurveOf.TryGetValue(Key, CurveID) then
        Order := Order + [CurveID];
    if Order <> nil then
      FChartMgr.ApplyDrawOrder(Order);
  finally
    CurveOf.Free;
    INF.Free;
  end;
end;

function TfrmProjectPanel.SaveProjectINI(const IniFileName: string): boolean;
var
  INF: TMemIniFile;
begin
  if FileExists(IniFileName) then
    DeleteFile(IniFileName);

  INF := TMemIniFile.Create(IniFileName);
  try
    FCalcSettings.SaveToINI(INF);
    FChartInfo.SaveToINI(INF);

    INF.WriteInteger('INFO', 'Version', CURRENT_PROJECT_VERSION);

    if FProject.LinkedData <> nil then
      INF.WriteInteger('STATE', 'LinkedData', FProject.LinkedData.ID);
    if FProject.ActiveModel <> nil then
    begin
      INF.WriteInteger('STATE', 'ActiveModel', FProject.ActiveModel.ID);
      FProject.ActiveModel.Data := Structure.ToString;
    end;

    INF.WriteBool('STATE', 'LogScale', FChartInfo.Chart.LeftAxis.Logarithmic);
    SaveCurveStyles(INF);

    FCalcSettings.SaveAdvancedParams(INF, FFitParams);
    INF.UpdateFile;
    Result := True;
  finally
    INF.Free;
  end;
end;

procedure TfrmProjectPanel.CreateProfileExtension(const AFromFit: Boolean);
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := FindParentModel(LastNode);
  if Node = nil then Exit;

  if not FProject.ProfileAttached(Node) then
  begin
    Node := FProject.AddChild(Node);
    Data := FProject.GetNodeData(Node);

    Data.Group := gtModel;
    Data.Enabled := True;
    Data.FromFit := AFromFit;
    Data.RowType := prExtension;
    Data.Title := 'Table';
    Data.ExtType := etTable;
    Data.StackID := -1;
    Data.LayerID := -1;
    Data.Form := ffNone;

    FProject.ClearSelection;
    FProject.Selected[Node] := True;
  end;
end;

procedure TfrmProjectPanel.CreateFunctionProfileExtension(Node: PVirtualNode);
var
  Data: PProjectData;
begin
  Data := FProject.GetNodeData(Node);

  Data.Group := gtModel;
  Data.Enabled := True;
  Data.RowType := prExtension;
  Data.Title := 'Gradient ' + IntToStr(Node.Parent.ChildCount);
  Data.ExtType := etFunction;
  Data.Poly[0] := 0;
  Data.Poly[1] := 0.14;
  Data.PolyCount := 1;
  Data.StackID := -1;
  Data.LayerID := -1;
  Data.Form := ffPoly;

  FProject.ClearSelection;
  FProject.Selected[Node] := True;
end;

function TfrmProjectPanel.FindParentModel(out Node: PVirtualNode): PVirtualNode;
var
  Data: PProjectData;
begin
  Result := nil;
  if Node = Nil then Exit;

  Data := FProject.GetNodeData(Node);
  if Data.Group = gtModel then
  begin
    if Data.RowType = prExtension then
      Result := Node.Parent
    else
      Result := Node;
  end
end;

function TfrmProjectPanel.CreateChildNode(out Node: PVirtualNode): boolean;
var
  Data: PProjectData;
begin
  Result := False;
  Node := FProject.GetFirstSelected;
  if Node = Nil then Exit;

  Data := FProject.GetNodeData(Node);
  if Data.Group = gtModel then
  begin
    if Data.RowType = prItem then
      Node := FProject.AddChild(Node);
    if Data.RowType = prExtension then
      Node := FProject.AddChild(Node.Parent);
    Result := True;
  end
  else
    ShowMessage('Parent model is not selected!');
end;

procedure TfrmProjectPanel.EditProjectItem;
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  Node := FProject.GetFirstSelected;
  Data := FProject.GetNodeData(Node);
  case Data.RowType of
    prFolder:
      begin
        Data.Title := InputBox('Folder', 'Edit the folder''s title', Data.Title);
      end;
    prItem:
      begin
        edtrProjectItem.Data := Data;
        edtrProjectItem.Transparency := FChartMgr.GetTransparency(Data.CurveID);
        if edtrProjectItem.ShowModal = mrOk then
        begin
          FChartMgr.Series[Data.CurveID].Color := Data.Color;
          FChartMgr.Series[Data.CurveID].Title := Data.Title;
          FChartMgr.SetTransparency(Data.CurveID, edtrProjectItem.Transparency);
          SetDescription(Data.Description);
          RefreshChartLegend;
        end;
      end;
    prExtension:
      begin
        case Data.ExtType of
          etFunction: EditGradient(Data);
          etTable   : EditTable(Data);
        end;
      end;
  end;
end;

procedure TfrmProjectPanel.EditGradient(var Data: PProjectData);
begin
  edtrProfileFunction.Data := Data;
  edtrProfileFunction.Structure := Structure;
  if edtrProfileFunction.ShowModal = mrOk then
  begin
    SetDescription(Data.Description);
    ExtensionChanged;
  end;
end;

procedure TfrmProjectPanel.EditTable(var Data: PProjectData);
begin
  edtrProfileTable.Data := Data;
  edtrProfileTable.Structure := Structure;
  if edtrProfileTable.ShowModal = mrOk then
  begin
    SetDescription(Data.Description);
    ExtensionChanged;
  end;
end;

{ An extension switched on or off or edited changes the model the curve is
  calculated from, so the curve, chi-squared and the profile pages are redone
  together (RunCalc redraws the pages) rather than the pages alone. }
procedure TfrmProjectPanel.ExtensionChanged;
begin
  if Assigned(FOnCalcRun) then
    FOnCalcRun(Self)
  else
    PlotProfiles;
end;

procedure TfrmProjectPanel.SyncSeriesVisibility(Series: TChartSeries);
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  Node := FProject.GetFirstChild(FProject.GetFirst);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.RowType = prItem) and (FChartMgr.Series[Data.CurveID] = Series) then
    begin
      Data.Visible := Series.Active;
      FProject.Repaint;
      Exit;
    end;
    Node := FProject.GetNext(Node);
  end;
end;

procedure TfrmProjectPanel.RescaleChart;
var
  AMin, AMax: Single;
begin
  FCalcSettings.GetAxisRange(AMin, AMax);
  FChartMgr.RescaleAxis(AMin, AMax, FChartInfo.MinLimit);
end;

procedure TfrmProjectPanel.RefreshChartLegend;
var
  Items: TArray<TLegendEntry>;
  Node: PVirtualNode;
  Data: PProjectData;
  Entry: TLegendEntry;
  Count: Integer;
  S: TFastLineSeries;
begin
  Count := 0;
  SetLength(Items, 0);

  // Iterate all nodes collecting prItem entries
  Node := FProject.GetFirstChild(FProject.GetFirst);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if Data.RowType = prItem then
    begin
      S := FChartMgr.Series[Data.CurveID];
      if S <> nil then
      begin
        Entry.Title := Data.Title;
        Entry.Color := Data.Color;
        Entry.Visible := Data.Visible;
        Entry.Linked := Data = FProject.LinkedData;
        Entry.Group := Data.Group;
        Entry.CurveID := Data.CurveID;
        Entry.Series := S;
        SetLength(Items, Count + 1);
        Items[Count] := Entry;
        Inc(Count);
      end;
    end;
    Node := FProject.GetNext(Node);
  end;

  FChartInfo.RefreshLegend(Items);
  if Assigned(FOnCurvesChanged) then
    FOnCurvesChanged(Self);
end;

function TfrmProjectPanel.LinkedDataSeries(out ID: Integer): TFastLineSeries;
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  Result := nil;
  ID := -1;
  if FProject.LinkedData = nil then
    Exit;
  Node := FProject.GetFirst;
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if Data = FProject.LinkedData then
    begin
      ID := Data.ID;
      Exit(FChartMgr.Series[Data.CurveID]);
    end;
    Node := FProject.GetNext(Node);
  end;
end;

function TfrmProjectPanel.VisibleModelSeries: TArray<TFastLineSeries>;
var
  Node: PVirtualNode;
  Data: PProjectData;
  S: TFastLineSeries;
begin
  Result := nil;
  Node := FProject.GetFirstChild(FProject.GetFirst);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if Data.IsModel then
    begin
      S := FChartMgr.Series[Data.CurveID];
      if (S <> nil) and S.Visible then
        Result := Result + [S];
    end;
    Node := FProject.GetNext(Node);
  end;
end;

procedure TfrmProjectPanel.LoadRecentProjectsList(ARecentMenu: TMenuItem; ARecentPopup: TPopupMenu);
begin
  FRecentProjects := TRecentProjectsManager.Create(MAX_RECENT_CAPACITY, ARecentMenu, ARecentPopup);
  FRecentProjects.OnClick := OnRecentProjectClick;
  FRecentProjects.Load;
end;

procedure TfrmProjectPanel.OnRecentProjectClick(Sender: TObject; const FileName: string);
begin
  if not FileExists(FileName) then
  begin
    MessageDlg('Project file not found:' + sLineBreak + FileName,
      mtError, [mbOK], 0);
    FRecentProjects.Remove(FileName);
    Exit;
  end;
  if not MayReplaceProject('Open project',
    'Save the current project before opening another one?') then
    Exit;

  FProjectFileName := FileName;
  PrepareProjectFolder(FProjectFileName, True);
  LoadProject(FProjectFileName);
  if TConfig.Section<TOtherOptions>.AutoCalc then
    if Assigned(FOnCalcRun) then
      FOnCalcRun(Self);
end;

{ --- Public project file operations --- }

procedure TfrmProjectPanel.NewProject;
begin
  Structure.Clear;
  FProfileMgr.ClearProfiles;
  FChartPages.ClearConvergence;   // and the diagnostics: the last fit's
  CreateDefaultProject;
end;

procedure TfrmProjectPanel.OpenProject;
begin
  if TConfig.SystemDir[sdProjDir] <> '' then
    dlgOpenProject.InitialDir := TConfig.SystemDir[sdProjDir]
  else
    dlgOpenProject.InitialDir := '';

  if dlgOpenProject.Execute then
  begin
    if not MayReplaceProject('Open project',
      'Save the current project before opening another one?') then
      Exit;
    PrepareProjectFolder(dlgOpenProject.FileName, True);
    LoadProject(dlgOpenProject.FileName);
    if TConfig.Section<TOtherOptions>.AutoCalc then
      if Assigned(FOnCalcRun) then
        FOnCalcRun(Self);

    FRecentProjects.Add(FProjectFileName);
  end;
end;

function TfrmProjectPanel.MayReplaceProject(const Caption, Question: string): Boolean;
begin
  case ConfirmSaveBefore(Caption, Question) of
    sbaSave:    Result := SaveCurrentProject;   // False: the Save As was cancelled
    sbaDiscard: Result := True;
  else
    Result := False;
  end;
end;

function TfrmProjectPanel.SaveCurrentProject: Boolean;
begin
  if FProjectName = DEFAULT_PROJECT_NAME then
    Result := SaveProjectAs
  else
  begin
    SaveProject(FProjectFileName);
    Result := True;
  end;
end;

function TfrmProjectPanel.SaveProjectAs: Boolean;
begin
  Result := False;
  if TConfig.SystemDir[sdProjDir] <> '' then
    dlgSaveProject.InitialDir := TConfig.SystemDir[sdProjDir]
  else
    dlgSaveProject.InitialDir := '';

  dlgSaveProject.FileName := ExtractFileName(FProjectFileName);
  if dlgSaveProject.Execute then
  begin
    FProjectName := ExtractFileName(dlgSaveProject.FileName);
    SaveData;
    SaveProject(dlgSaveProject.FileName);
    FProjectFileName := dlgSaveProject.FileName;
    FRecentProjects.Add(FProjectFileName);
    if Assigned(FOnCaptionChange) then
      FOnCaptionChange('X-Ray Calc 3: ' + FProjectName);
    Result := True;
  end;
end;

procedure TfrmProjectPanel.ReopenProject;
begin
  PrepareProjectFolder(FProjectFileName, True);
  LoadProject(FProjectFileName);
end;

{ --- Tree operations --- }

procedure TfrmProjectPanel.CreateModel;
begin
  FProject.ActiveModel.Data := Structure.ToString;
  CreateNewModel(FModelsRoot);
end;

procedure TfrmProjectPanel.DuplicateModel;
var
  S: string;
begin
  FProject.ActiveModel.Data := Structure.ToString;
  S := Structure.ToString;
  CreateNewModel(FModelsRoot);
  Structure.FromString(S);
  FProject.ActiveModel.Data := S;
end;

procedure TfrmProjectPanel.CopyModel;
begin
  ClipBoard.AsText := Structure.ToString;
end;

procedure TfrmProjectPanel.PasteModel;
begin
  FProject.ActiveModel.Data := Structure.ToString;
  CreateNewModel(FModelsRoot);
  FProject.ActiveModel.Data := ClipBoard.AsText;
  Structure.FromString(FProject.ActiveModel.Data);
end;

procedure TfrmProjectPanel.CopySelectedItem;
var
  Data: PProjectData;
begin
  Data := FProject.GetNodeData(FProject.GetFirstSelected);
  if (Data.Group = gtModel) and (Data.RowType = prItem) then
    ClipBoard.AsText := Structure.ToString;
  if (Data.Group = gtData) and (Data.RowType = prItem) then
    SeriesToClipboard(FChartMgr.Series[Data.CurveID], FCalcSettings.CalcMode,
      FCalcSettings.Is2Theta);
end;

procedure TfrmProjectPanel.DeleteSelectedItems;
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := FProject.GetFirstSelected;
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.Group = gtModel) and (Data.RowType = prItem) then
      DeleteModel(Node, Data);

    if (Data.Group = gtData) and (Data.RowType = prItem) then
    begin
      if Data = FProject.LinkedData then
        FProject.LinkedData := nil;
      DeleteData(Node, Data);
    end;

    if (Data.RowType = prFolder) then
      DeleteFolder(Node);
    if (Data.RowType = prExtension) then
      DeleteExtension(Node);
    Node := FProject.GetFirstSelected;
  end;
  LastNode := nil;
  ProjectChange(FProject, Nil);
end;

procedure TfrmProjectPanel.EditSelectedItem;
begin
  EditProjectItem;
end;

procedure TfrmProjectPanel.EditModelText;
var
  Str: string;
begin
  Str := Structure.ToString;
  if frmJsonEditor.Edit(Str) then
  begin
    Str := StringReplace(Str, #13#10, '', [rfReplaceAll]);
    Structure.FromString(Str);
  end;
end;

procedure TfrmProjectPanel.ImportStructure;
var
  Dlg: TOpenDialog;
  JSON: string;
  JObj: TJSONObject;
begin
  Dlg := TOpenDialog.Create(nil);
  try
    Dlg.Filter := 'JSON files (*.json)|*.json|All files (*.*)|*.*';
    Dlg.Title := 'Import Structure';
    if Dlg.Execute then
    begin
      JSON := TFile.ReadAllText(Dlg.FileName);

      JObj := TJSONObject.ParseJSONValue(JSON) as TJSONObject;
      if JObj = nil then
      begin
        MessageDlg('Invalid JSON file.', mtError, [mbOK], 0);
        Exit;
      end;
      try
        if (JObj.FindValue('Stacks') = nil) or (JObj.FindValue('Subs') = nil) then
        begin
          MessageDlg('This file is not a valid XRC structure.' + sLineBreak +
            'Expected format with "Stacks" and "Subs" keys.' + sLineBreak +
            'Use best_structure_xrc.json from Universal Mirror output.',
            mtError, [mbOK], 0);
          Exit;
        end;
      finally
        JObj.Free;
      end;

      if FProject.ActiveModel <> nil then
        FProject.ActiveModel.Data := Structure.ToString;
      CreateNewModel(FModelsRoot);
      FProject.ActiveModel.Data := JSON;
      Structure.FromString(JSON);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmProjectPanel.AddFolder;
var
  Node: PVirtualNode;
  Data: PProjectData;
  PD: PProjectData;
  s: string;
begin
  s := 'Folder';
  if not InputQuery('New folder', 'Input folder title', s) or (s = '') then
    Exit;

  Node := FProject.GetFirstSelected;
  if Node = nil then
    Node := FModelsRoot;

  PD := FProject.GetNodeData(Node);
  if PD.RowType <> prGroup then
  begin
    case PD.Group of
      gtModel:
        Node := FProject.AddChild(FModelsRoot);
      gtData:
        Node := FProject.AddChild(FDataRoot);
    end;
  end
  else
    Node := FProject.AddChild(Node);
  Data := FProject.GetNodeData(Node);
  Data.ID := 0;
  Data.Title := s;
  Data.Group := PD.Group;
  Data.RowType := prFolder;
  FProject.ClearSelection;
  FProject.Selected[Node] := True;
end;

procedure TfrmProjectPanel.AddExtension;
var
  EType: TExtentionType;
  Node: PVirtualNode;
begin
  EType := SelectExtensionTypeAction;
  if EType = etNone then Exit;

  case EType of
    etFunction:
      begin
        if CreateChildNode(Node) then
          CreateFunctionProfileExtension(Node);
      end;
    etTable:
      CreateProfileExtension;
  end;
end;

{ --- Data operations --- }

function TfrmProjectPanel.CreateDataNode(ParentNode: PVirtualNode;
  const Title: string): PProjectData;
var
  Node: PVirtualNode;
begin
  Node := FProject.AddChild(ParentNode);
  Result := FProject.GetNodeData(Node);
  Result.ID := FLastID;
  Inc(FLastID);
  Result.Title := Title;
  Result.Group := gtData;
  Result.RowType := prItem;
  FChartMgr.AddSeries(Result);
  FProject.Expanded[FDataRoot] := True;
end;

procedure TfrmProjectPanel.LoadData;
var
  Data: PProjectData;
  Node: PVirtualNode;
  Parent: PVirtualNode;
  IsXRDML: Boolean;
  Scan: TXRDMLScan;
  Curve: TDataArray;
  Descr, L: string;
  i: Integer;
begin
  if not dlgLoadData.Execute then
    Exit;

  { An XRDML file is parsed before any node exists, so an unreadable file
    leaves nothing behind. The chart shows the unit the 2-theta switch says,
    so the scanned axis is brought to it: an Empyrean 2Theta-Omega scan is in
    2Theta, a rocking curve (Omega only) is in theta already. The wavelength
    and the rest of what the file says go into the node's description. }
  IsXRDML := IsXRDMLFile(dlgLoadData.FileName);
  if IsXRDML then
  begin
    Scan := ReadXRDMLFile(dlgLoadData.FileName);
    Curve := Scan.Curve;
    if SameText(Scan.XAxis, '2Theta') and not FCalcSettings.Is2Theta then
      for i := 0 to High(Curve) do
        Curve[i].t := Curve[i].t / 2
    else if SameText(Scan.XAxis, 'Omega') and FCalcSettings.Is2Theta then
      for i := 0 to High(Curve) do
        Curve[i].t := Curve[i].t * 2;
    Descr := '';
    for L in Scan.DescriptionLines do
      Descr := Descr + L + #13#10;
    { Data - Assess XRR quality re-reads the file for the raw facts (counting
      time, count rates, zero counts) the chart series no longer carries }
    Descr := Descr + '* Source file: ' + dlgLoadData.FileName + #13#10;
    if FCalcSettings.Is2Theta then
      Descr := Descr + '* Loaded as 2Theta' + #13#10
    else
      Descr := Descr + '* Loaded as theta (incidence angle)' + #13#10;
    { the file states the wavelength it was measured at; taking it from there
      removes one thing the operator can get wrong }
    if Scan.Lambda > 0 then
    begin
      FCalcSettings.SetLambda(Scan.Lambda);
      Descr := Descr + '* Wavelength set to ' +
        FormatFloat('0.000000', Scan.Lambda, TFormatSettings.Invariant) + ' A from the file' + #13#10;
    end;
  end;

  Node := FProject.GetFirstSelected;
  if Node = nil then
    Node := FDataRoot;

  Data := FProject.GetNodeData(Node);
  if (Data.RowType = prFolder) and (Data.Group = gtData) then
    Parent := Node
  else
    Parent := FDataRoot;

  Data := CreateDataNode(Parent, ExtractFileName(dlgLoadData.FileName));
  if IsXRDML then
  begin
    DataToSeries(Curve, FChartMgr.Series[Data.CurveID]);
    Data.Description := Descr;
  end
  else
    SeriesFromFile(FChartMgr.Series[Data.CurveID], dlgLoadData.FileName, Data.Description);
  SeriesToFile(FChartMgr.Series[Data.CurveID], DataName(Data));

  FProject.ActiveData := Data;
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.PasteData;
var
  Data: PProjectData;
begin
  Data := CreateDataNode(FDataRoot, 'Data ' + IntToStr(FDataRoot.ChildCount) + '.dat');
  SeriesFromClipboard(FChartMgr.Series[Data.CurveID]);
  SeriesToFile(FChartMgr.Series[Data.CurveID], DataName(Data));
  RefreshChartLegend;
end;

procedure TfrmProjectPanel.SaveData;
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := FProject.GetFirstChild(FProject.GetFirst);
  while Node <> Nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.RowType = prItem) and (Data.Group = gtData) then
      SeriesToFile(FChartMgr.Series[Data.CurveID], DataName(Data));
    Node := FProject.GetNext(Node);
  end;
end;

procedure TfrmProjectPanel.SaveActiveData;
begin
  SeriesToFile(ActiveDataSeries, DataName(FProject.ActiveData));
end;

procedure TfrmProjectPanel.AppendActiveDataNote(const Line: string);
var
  Node: PVirtualNode;
begin
  if FProject.ActiveData = nil then
    Exit;
  FProject.ActiveData.Description := FProject.ActiveData.Description + Line + #13#10;
  Node := FProject.GetFirstSelected;
  if (Node <> nil) and (FProject.GetNodeData(Node) = FProject.ActiveData) then
    SetDescription(FProject.ActiveData.Description);
end;

{ --- Project loading/saving --- }

procedure TfrmProjectPanel.LoadProject(const FileName: string);
var
  LinkedID, ActiveID: Integer;
begin
  Inc(FProjectSerial);
  FIgnoreFocusChange := True;
  FProfileMgr.ClearProfiles;
  FChartPages.ClearConvergence;   // and the diagnostics: the last fit's
  ExtractProject(FileName);
  LoadProjectParams(LinkedID, ActiveID);
  RecoverProjectTree(ActiveID);
  RecoverDataCurves(LinkedID);
  LoadCurveStyles;
  FIgnoreFocusChange := False;
  if Assigned(FOnCaptionChange) then
    FOnCaptionChange('X-Ray Calc 3: ' + ExtractFileName(FileName));
  MatchToStructure;
  RescaleChart;
  RefreshChartLegend;
  FChartInfo.Chart.Repaint;
  if Assigned(FOnModelChanged) then
    FOnModelChanged(Self);
end;

procedure TfrmProjectPanel.SaveProject(const FileName: string);
begin
  if SaveProjectINI(FProjectDir + PARAMETERS_FILE_NAME) then
  begin
    FProject.SaveToFile(FProjectDir + PROJECT_FILE_NAME);

    SeriesToFile(ActiveModelSeries, FProjectDir + 'calc.dat');

    if FileExists(FileName) then
      DeleteFile(FileName);

    Zip.ArchiveType := atZip;
    Zip.AutoSave := True;
    Zip.ForceType := True;
    Zip.OpenArchive(FileName);
    Zip.BaseDirectory := FProjectDir;

    Zip.AddFiles('*.*', faAnyFile and faDirectory);
    Zip.CloseArchive;
  end;
end;

procedure TfrmProjectPanel.CreateDefaultProject;
var
  PD: PProjectData;
  PG: PVirtualNode;
  WasIgnoring: Boolean;
begin
  { These point into the nodes FProject.Clear frees, and CreateNewModel's
    RefreshChartLegend below already has listeners reading them. }
  FProject.LinkedData := nil;
  FProject.ActiveData := nil;
  FProject.ActiveModel := nil;
  Inc(FProjectSerial);
  FChartMgr.ClearAll;

  { FProject.Clear fires OnChange once its nodes are gone. ProjectChange would
    then save the live structure - already cleared by NewProject, its substrate
    freed - into LastNode, a node Clear has just freed: ToString copied the
    freed substrate's layer data from address 0 (File - New, 3.9.4.1070). }
  LastNode := nil;
  FLastModel := nil;
  FLastData := nil;
  WasIgnoring := FIgnoreFocusChange;
  FIgnoreFocusChange := True;
  try
    FProject.Clear;
  finally
    FIgnoreFocusChange := WasIgnoring;
  end;
  Structure.AddSubstrate('Si', 5, 2.2);

  FLastID := 1;
  FProjectName := DEFAULT_PROJECT_NAME;
  FProjectDir := IncludeTrailingPathDelimiter(TConfig.TempPath + CreateClassID);
  FProjectFileName := FProjectName;
  CreateDir(FProjectDir);

  PG := FProject.AddChild(Nil, Nil);
  PD := FProject.GetNodeData(PG);
  PD.Title := 'Models';
  PD.Group := gtModel;
  PD.RowType := prGroup;
  FModelsRoot := PG;

  CreateNewModel(FModelsRoot);
  FProject.Expanded[PG] := True;
  { The new model is the one in hand, as RecoverProjectTree leaves a loaded
    project: gradients and fit extensions are hung off FLastModel. }
  LastNode := FProject.GetFirstChild(FModelsRoot);
  FLastModel := LastNode;
  FLastData := FProject.ActiveModel;

  PG := FProject.AddChild(Nil, Nil);
  PD := FProject.GetNodeData(PG);
  PD.Title := 'Data';
  PD.Group := gtData;
  PD.RowType := prGroup;
  FProject.Expanded[PG] := True;
  FDataRoot := PG;

  if Assigned(FOnCaptionChange) then
    FOnCaptionChange('X-Ray Calc 3: ' + FProjectName);
  FProject.LinkedData := nil;

  FFitParams.Tolerance    := 0.005;
  FFitParams.MovAvgWindow := 0.05;
  FFitParams.Vmax         := 0.3;
  FFitParams.JammingMax   := 1;
  FFitParams.ReInitMax    := 3;
  FFitParams.KChiSqr      := 1.41;
  FFitParams.KVmax        := 1.41;
  FFitParams.w1           := 0.3;
  FFitParams.w2           := 0.3;
  FFitParams.AdaptVel     := False;
  FFitParams.UseConstriction := True;   // as LoadAdvancedParams' default; was left False
  FFitParams.SmoothWindow := -1;
  FFitParams.Ksxr         := 0.2;
  FFitParams.PolyFactor   := 10;

  FProject.Rescale;
  FCalcSettings.ApplyModeSettings;
  RefreshChartLegend;
  if Assigned(FOnModelChanged) then
    FOnModelChanged(Self);
end;

{ --- Tree event handlers --- }

procedure TfrmProjectPanel.ProjectChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FIgnoreFocusChange then
    Exit;

  if Node = LastNode then Exit;

  FLastData := FProject.GetNodeData(LastNode);
  if (FLastData <> nil) and FLastData.IsModel then
    FLastData.Data := Structure.ToString;

  LastNode := FProject.GetFirstSelected;
  FLastData := FProject.GetNodeData(LastNode);

  if FLastData = nil then
    Exit;

  if (FLastData.RowType = prItem) and (FLastData.Group = gtData) then
    FProject.ActiveData := FLastData;

  if FLastData.IsModel then
  begin
    FLastModel := LastNode;
    if FLastData.Data <> '' then
    begin
      Structure.FromString(FLastData.Data);
      FOperationsStack.Clear;
      FOperationsStack.Push(HistoryEntry(FLastData.Data));
      PlotProfiles;
      if Assigned(FOnModelChanged) then
        FOnModelChanged(Self);
    end;
  end;
end;

procedure TfrmProjectPanel.ProjectDblClick(Sender: TObject);
begin
  EditProjectItem;
end;

procedure TfrmProjectPanel.ProjectFocusChanging(Sender: TBaseVirtualTree; OldNode,
  NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex;
  var Allowed: Boolean);
var
  Data: PProjectData;
begin
  Allowed := True;
  Data := Sender.GetNodeData(NewNode);
  if Data = nil then Exit;

  SetDescription(Data.Description);

  if not((Data.RowType = prItem) and (Data.Group = gtModel)) then
    Exit;

  FProject.ActiveModel := Data;
  FProject.Repaint;
end;

{ --- Fit/profile support --- }

function TfrmProjectPanel.GetProfileFunctions: TProfileFunctions;
var
  Item: PVirtualNode;
  Data: PProjectData;
  Count: integer;
begin
  SetLength(Result, 0);
  Count := 0;
  if FLastModel = nil then Exit;

  Item := FProject.GetFirstChild(FLastModel);
  while Item <> Nil do
  begin
    Data := FProject.GetNodeData(Item);
    { A gradient added but never set up points at stack -1, and so does one
      whose layer has been deleted (RemapGradients). Neither has a layer to
      take C[0] from; skip it rather than index out of range - the Thickness
      page asks for these on every redraw, not only on Calculate. }
    if (Data.RowType = prExtension) and (Data.Enabled) and (Data.ExtType = etFunction) and
       Structure.HasLayer(Data.StackID, Data.LayerID) then
    begin
      SetLength(Result, Count + 1);
      Result[Count].C       := Data.PolyD;
      Result[Count].C[0]    := Structure.Stacks[Data.StackID].Layers[Data.LayerID].Data.P[Ord(Data.Subj) + 1].V;
      Result[Count].StackID := Data.StackID;
      Result[Count].LayerID := Data.LayerID;
      Result[Count].Func    := Data.Form;
      Result[Count].Subj    := Data.Subj;
      inc(count)
    end;
    Item := FProject.GetNextSibling(Item);
  end;
end;

function TfrmProjectPanel.IsProfileEnabled: Boolean;
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Result := False;
  Node := FProject.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if Data.ExtType = etTable then
    begin
      Result := Data.Enabled;
      Break;
    end;
    Node := FProject.GetNextSibling(Node);
  end;
end;

function TfrmProjectPanel.HasFitExtensions: Boolean;
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  Result := False;
  if FLastModel = nil then Exit;

  Node := FProject.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if Data.IsFitExtension then
    begin
      Result := True;
      Break;
    end;
    Node := FProject.GetNextSibling(Node);
  end;
end;

procedure TfrmProjectPanel.ClearFitExtensions;
var
  Node: PVirtualNode;
  Data: PProjectData;
  Doomed: TList<PVirtualNode>;
  i: Integer;
begin
  if FLastModel = nil then Exit;

  Doomed := TList<PVirtualNode>.Create;
  try
    Node := FProject.GetFirstChild(FLastModel);
    while Node <> nil do
    begin
      Data := FProject.GetNodeData(Node);
      if Data.IsFitExtension then
        Doomed.Add(Node);
      Node := FProject.GetNextSibling(Node);
    end;

    if Doomed.Count = 0 then Exit;

    // Collect first, delete after: GetNextSibling on a freed node is undefined
    for i := 0 to Doomed.Count - 1 do
      FProject.DeleteNode(Doomed[i]);
  finally
    Doomed.Free;
  end;

  FProject.Refresh;
  MatchToStructure;
end;

procedure TfrmProjectPanel.CreateFitGradientExtensions(const P: TProfileFunctions);
var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i: Integer;
begin
  for I := 0 to High(P) do
  begin
    Gradient := FProject.AddChild(FLastModel);
    Data := FProject.GetNodeData(Gradient);

    Data.Group := gtModel;
    Data.Enabled := True;
    Data.FromFit := True;
    Data.RowType := prExtension;
    Data.Title := GradientTitle(P[i]);
    Data.ExtType := etFunction;
    Data.Form := ffPoly;
    Data.Subj := P[i].Subj;
    Data.StackID := P[i].StackID;
    Data.LayerID := P[i].LayerID;
    Data.SetPoly(P[i].C);
  end;

  MatchToStructure;
  FProject.Expanded[FLastModel] := True;
  FProject.ClearSelection;
  FProject.Selected[FLastModel] := True;
end;

procedure TfrmProjectPanel.UpdateFitGradientExtensions(const P: TProfileFunctions);
var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i: Integer;
  Title: string;
begin
  for I := 0 to High(P) do
  begin
    Title := GradientTitle(P[i]);

    Gradient := FProject.GetFirstChild(FLastModel);
    while Gradient <> nil do
    begin
      Data := FProject.GetNodeData(Gradient);
      if (Data <> nil) and (Data.Title = Title) then
      begin
        Data.SetPoly(P[i].C);
        Break;
      end;
      Gradient := FProject.GetNextSibling(Gradient);
    end;
  end;

  MatchToStructure;
  FProject.Expanded[FLastModel] := True;
  FProject.ClearSelection;
  FProject.Selected[FLastModel] := True;
end;

procedure TfrmProjectPanel.PlotProfiles;
begin
  FProfileMgr.Prepare(Structure, FChartPages.ThicknessChart, FChartPages.RoughnessChart, FChartPages.DensityChart);
  { The gradients the calculation applies (TCalcOrchestrator.PrepareCalc hands
    the same list to the model). Without them the profile pages drew every
    period at the layer's own value, so a graded stack looked flat. }
  FProfileMgr.Profiles := GetProfileFunctions;
  FProfileMgr.PlotProfile(IsNonPeriodicProfile, FChartPages.IsProfileActive);
end;

procedure TfrmProjectPanel.MatchToStructure;
begin
  PlotProfiles;
  FProject.ActiveModel.Data := Structure.ToString;
end;

{ --- Utilities --- }

procedure TfrmProjectPanel.SaveHistory;
begin
  FOperationsStack.Push(HistoryEntry(Structure.ToString));
end;

function TfrmProjectPanel.HistoryEntry(const AStructure: string): THistoryEntry;
var
  Node: PVirtualNode;
  Data: PProjectData;
  Count: Integer;
begin
  Result.Structure := AStructure;
  SetLength(Result.Targets, 0);
  if FLastModel = nil then Exit;

  Count := 0;
  Node := FProject.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.RowType = prExtension) and (Data.ExtType = etFunction) then
    begin
      SetLength(Result.Targets, Count + 1);
      Result.Targets[Count].Ext := Data;
      Result.Targets[Count].StackID := Data.StackID;
      Result.Targets[Count].LayerID := Data.LayerID;
      Inc(Count);
    end;
    Node := FProject.GetNextSibling(Node);
  end;
end;

function TfrmProjectPanel.Undo: Boolean;
var
  Entry: THistoryEntry;
  Node: PVirtualNode;
  Data: PProjectData;
  i: Integer;
begin
  Result := FOperationsStack.Count > 0;
  if not Result then Exit;

  Entry := FOperationsStack.Pop;
  Structure.FromString(Entry.Structure);

  { Only extensions still under the model are restored: one deleted since
    the undo point is gone, and the history is cleared when another model is
    selected. }
  if FLastModel = nil then Exit;
  Node := FProject.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    for i := 0 to High(Entry.Targets) do
      if Entry.Targets[i].Ext = Data then
      begin
        Data.StackID := Entry.Targets[i].StackID;
        Data.LayerID := Entry.Targets[i].LayerID;
      end;
    Node := FProject.GetNextSibling(Node);
  end;
end;

{ Structure fires this after a layer or stack was inserted, deleted or moved.
  A gradient names its layer by (stack, layer) index, so without it the
  gradient stays on the index and lands on whichever layer now sits there. It
  follows its layer instead; one whose layer was deleted points at (-1, -1)
  and is skipped (GetProfileFunctions) until it is set up again. }
procedure TfrmProjectPanel.RemapGradients(Sender: TObject; const Map: TLayerMap);
var
  Node: PVirtualNode;
  Data: PProjectData;
  NewPos: TLayerPos;
begin
  if FLastModel = nil then Exit;

  Node := FProject.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := FProject.GetNodeData(Node);
    if (Data.RowType = prExtension) and (Data.ExtType = etFunction) and
       (Data.StackID >= 0) and (Data.StackID <= High(Map)) and
       (Data.LayerID >= 0) and (Data.LayerID <= High(Map[Data.StackID])) then
    begin
      NewPos := Map[Data.StackID][Data.LayerID];
      Data.StackID := NewPos.StackID;
      Data.LayerID := NewPos.LayerID;
    end;
    Node := FProject.GetNextSibling(Node);
  end;
end;

procedure TfrmProjectPanel.AutoSave;
begin
  if TConfig.Section<TOtherOptions>.AutoSave then
  begin
    { The Output folder is not created anywhere else. }
    ForceDirectories(ExtractFilePath(FAutoSaveFileName));
    SaveProject(FAutoSaveFileName);
  end;
end;

{ <project>-fitted.xrcx, in the Fitting Output folder when one is set and next
  to the project when the setting is blank. TConfig.SystemDir never returns ''
  (a blank setting is the program's own folder), so the setting itself is
  what is asked. A project that was never saved has no folder: its autosave
  goes to the Projects folder. }
procedure TfrmProjectPanel.GenerateAutosaveName;
var
  Path: string;
begin
  if Trim(TConfig.Section<TPathOptions>.OutputDir) <> '' then
    Path := TConfig.SystemDir[sdOutDir]
  else
  begin
    Path := ExtractFilePath(FProjectFileName);
    if Path = '' then
      Path := TConfig.SystemDir[sdProjDir];
  end;

  FAutoSaveFileName := IncludeTrailingPathDelimiter(Path) +
    ChangeFileExt(ExtractFileName(FProjectName), '') + '-fitted' + PROJECT_EXT;
end;

function TfrmProjectPanel.GradientTitle(const P: TFuncProfileRec): string;
begin
  Result := Format('F(%s %s/%s)', [GradientLabels[Ord(P.Subj)],
               Structure.Stacks[P.StackID].Title,
               Structure.Stacks[P.StackID].Layers[P.LayerID].Data.Material]);
end;

end.
