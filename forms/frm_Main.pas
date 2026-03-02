unit frm_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzSplit, Vcl.ExtCtrls, RzPanel,
  Vcl.Menus, RzTabs, Vcl.ToolWin, Vcl.ComCtrls, RzButton,
  VirtualTrees, VirtualTrees.BaseTree, VirtualTrees.Types,
  Vcl.StdCtrls, RzEdit, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, RzCmboBx, RzStatus, VCLTee.Series, RzRadChk, System.ImageList,
  Vcl.ImgList, System.Actions, Vcl.ActnList,
  Vcl.ActnMan, AbUnzper, AbBase, AbBrowse, AbZBrows, AbZipper, unit_Types,
  unit_SMessages,
  unit_calc, unit_XRCProjectTree, RzRadGrp, unit_materials,
  VCLTee.TeeFunci, VCLTee.TeCanvas,
  unit_LFPSO_Base, unit_LFPSO_Periodic, Vcl.Buttons,
  unit_LFPSO_Irregular, Vcl.Imaging.pngimage, frm_Benchmark, frame_CalcSettings, frame_ChartInfo, frame_ChartPages, frame_StructurePanel,
  Vcl.PlatformDefaultStyleActnCtrls, unit_ProfilesManager, unit_RecentProjects, unit_ChartManager,
  Vcl.VirtualImageList, Vcl.BaseImageCollection, Vcl.ImageCollection;

type
  TfrmMain = class(TForm)
    mmMain: TMainMenu;
    File1: TMenuItem;
    File2: TMenuItem;
    Openproject1: TMenuItem;
    Openproject2: TMenuItem;
    Saveprojectas1: TMenuItem;
    Saveprojectas2: TMenuItem;
    Settings1: TMenuItem;
    Settings2: TMenuItem;
    Exit1: TMenuItem;
    Status: TRzStatusBar;
    LeftSplitter: TRzSplitter;
    RzPanel1: TRzPanel;
    tlbrFile: TRzToolbar;
    RzPanel5: TRzPanel;
    mmDescription: TRzMemo;
    ActionManager: TActionManager;
    FileNew: TAction;
    FileOpen: TAction;
    FileSave: TAction;
    FilePrint: TAction;
    FileClose: TAction;
    LayerAdd: TAction;
    LayerInsert: TAction;
    LayerDelete: TAction;
    PeriodAdd: TAction;
    PeriodInsert: TAction;
    PeriodDelete: TAction;
    LayerCut: TAction;
    LayerPaste: TAction;
    LayerPasteBefore: TAction;
    LayerPasteAfter: TAction;
    CalcRun: TAction;
    ModelCreate: TAction;
    actItemProperites: TAction;
    DataLoad: TAction;
    DataPaste: TAction;
    ResultSave: TAction;
    ResultCopy: TAction;
    FileSaveAs: TAction;
    ProjectAddFolder: TAction;
    CalcAll: TAction;
    ProjectItemDelete: TAction;
    ProjectItemCopy: TAction;
    CalcStop: TAction;
    DataNormAuto: TAction;
    DataNormMan: TAction;
    DataNorm: TAction;
    FilePlotToFile: TAction;
    FileCopyPlotBMP: TAction;
    FilePlotCopyWMF: TAction;
    HelpHelp: TAction;
    HelpRegistration: TAction;
    HelpAbout: TAction;
    HelpContent: TAction;
    actHomePage: TAction;
    actCheckUpdate: TAction;
    actWiki: TAction;
    actSupport: TAction;
    actQuickStart: TAction;
    actHelpStructure: TAction;
    actHelpFitting: TAction;
    ProjectItemExtension: TAction;
    DataCopyClpbrd: TAction;
    DataExport: TAction;
    actNewMaterial: TAction;
    actAutoFitting: TAction;
    Project1: TMenuItem;
    Project2: TMenuItem;
    Calc1: TMenuItem;
    Calc2: TMenuItem;
    UserManual1: TMenuItem;
    N15: TMenuItem;
    About1: TMenuItem;
    Calc3: TMenuItem;
    Calcall1: TMenuItem;
    miRecent: TMenuItem;
    dlgOpenProject: TOpenDialog;
    Zip: TAbZipper;
    UnZip: TAbUnZipper;
    pnlMain: TRzPanel;
    RzPanel3: TRzPanel;
    FChartInfo: TfrmChartInfo;
    FStructurePanel: TfrmStructurePanel;
    spnTime: TRzStatusPane;
    dlgSaveResult: TSaveDialog;
    dlgLoadData: TOpenDialog;
    dlgSaveProject: TSaveDialog;
    dlgExport: TSaveDialog;
    pmProject: TPopupMenu;
    pmiNorm: TMenuItem;
    Auto1: TMenuItem;
    Manual1: TMenuItem;
    pmiVisible: TMenuItem;
    pmiLinked: TMenuItem;
    pmiEnabled: TMenuItem;
    N1: TMenuItem;
    Properties1: TMenuItem;
    N5: TMenuItem;
    pmCopytoclipboard: TMenuItem;
    pmExporttofile: TMenuItem;
    spnFitTime: TRzStatusPane;
    pnlSettings: TPanel;
    ChartToolBar: TRzToolbar;
    btnDataLoad: TRzToolButton;
    btnDataPaste: TRzToolButton;
    rzspcr3: TRzSpacer;
    btnCalcRun: TRzToolButton;
    rzspcr4: TRzSpacer;
    btnResultSave: TRzToolButton;
    btnBtnCopy: TRzToolButton;
    RzSpacer2: TRzSpacer;
    BtnExecute: TRzToolButton;
    dlgPrint: TPrintDialog;
    BtnFastForward: TRzToolButton;
    actLayerCopy: TAction;
    actProjectItemDuplicate: TAction;
    tlbrProject: TRzToolbar;
    ilCalc: TImageList;
    BtnNew: TRzToolButton;
    BtnOpen: TRzToolButton;
    BtnSave: TRzToolButton;
    RzSpacer1: TRzSpacer;
    BtnPrint: TRzToolButton;
    btnAddModel: TRzToolButton;
    BtnExport: TRzToolButton;
    BtnCopy: TRzToolButton;
    BtnPaste: TRzToolButton;
    BtnEdit: TRzToolButton;
    RzSpacer4: TRzSpacer;
    btnAddExtension: TRzToolButton;
    RzSpacer5: TRzSpacer;
    BtnRecycle: TRzToolButton;
    actModelCopy: TAction;
    actModelPaste: TAction;
    btnCopyImage: TRzToolButton;
    btnPrintGraphics: TRzToolButton;
    ools1: TMenuItem;
    ShowLibrary1: TMenuItem;
    Result1: TMenuItem;
    Save1: TMenuItem;
    Copytoclipboard1: TMenuItem;
    CopyasBMP1: TMenuItem;
    CopyasWMF1: TMenuItem;
    Saveplotasfile1: TMenuItem;
    N2: TMenuItem;
    New1: TMenuItem;
    Copymodel1: TMenuItem;
    PasteModel1: TMenuItem;
    Newextension1: TMenuItem;
    Add1: TMenuItem;
    Insert1: TMenuItem;
    Delete1: TMenuItem;
    N3: TMenuItem;
    Add2: TMenuItem;
    Insert2: TMenuItem;
    Copy1: TMenuItem;
    Paste1: TMenuItem;
    Cut1: TMenuItem;
    N4: TMenuItem;
    Delete2: TMenuItem;
    RzVersionInfoStatus1: TRzVersionInfoStatus;
    Data1: TMenuItem;
    Loadfromfile1: TMenuItem;
    Pastefromclipboard1: TMenuItem;
    N6: TMenuItem;
    Normalize1: TMenuItem;
    NormalizeAuto1: TMenuItem;
    Smooth1: TMenuItem;
    N7: TMenuItem;
    Copytoclipboad1: TMenuItem;
    Exporttofile1: TMenuItem;
    NewFolder1: TMenuItem;
    N8: TMenuItem;
    actEditHenke: TAction;
    EditHenketable1: TMenuItem;
    actProjecEditModelText: TAction;
    actProjecEditModelText1: TMenuItem;
    N9: TMenuItem;
    N10: TMenuItem;
    Fitting1: TMenuItem;
    N11: TMenuItem;
    MaterialsLibrary1: TMenuItem;
    actDataSmooth: TAction;
    N12: TMenuItem;
    N13: TMenuItem;
    acStructureUndo: TAction;
    Undo1: TMenuItem;
    btnReopenProject: TRzToolButton;
    rzspcr2: TRzSpacer;
    actProjectReopen: TAction;
    actCalcBenchmark: TAction;
    N14: TMenuItem;
    Benchmark1: TMenuItem;
    actSystemSettings: TAction;
    actSystemExit: TAction;
    actCopyStructureBitmap: TAction;
    Copyasimage1: TMenuItem;
    ilIcons: TImageList;
    actDataTrim: TAction;
    rim1: TMenuItem;
    actCalcFitJobs: TAction;
    Calcbatchjobs1: TMenuItem;
    pmRecentList: TPopupMenu;
    pmRecentList1: TMenuItem;
    pnlX64: TRzStatusPane;
    ImageCollection: TImageCollection;
    vliProject: TVirtualImageList;
    vilModel: TVirtualImageList;
    vilCalc: TVirtualImageList;
    FCalcSettings: TfrmCalcSettings;
    FChartPages: TfrmChartPages;
    Chart: TChart;
    btnStop: TRzBitBtn;
    procedure FileOpenExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ProjectChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure ProjectDblClick(Sender: TObject);
    procedure ProjectFocusChanging(Sender: TBaseVirtualTree; OldNode,
      NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex;
      var Allowed: Boolean);
    procedure FormDestroy(Sender: TObject);
    procedure PeriodAddExecute(Sender: TObject);
    procedure PeriodInsertExecute(Sender: TObject);
    procedure CalcRunExecute(Sender: TObject);
    procedure PeriodDeleteExecute(Sender: TObject);
    procedure DataPasteExecute(Sender: TObject);
    procedure DataCopyClpbrdExecute(Sender: TObject);
    procedure DataExportExecute(Sender: TObject);
    procedure ResultSaveExecute(Sender: TObject);
    procedure ResultCopyExecute(Sender: TObject);
    procedure DataLoadExecute(Sender: TObject);
    procedure FileSaveExecute(Sender: TObject);
    procedure FileSaveAsExecute(Sender: TObject);
    procedure LayerAddExecute(Sender: TObject);

    procedure LayerInsertExecute(Sender: TObject);
    procedure LayerDeleteExecute(Sender: TObject);
    procedure LayerCutExecute(Sender: TObject);
    procedure LayerPasteExecute(Sender: TObject);
    procedure DataNormExecute(Sender: TObject);
    procedure pmiLinkedClick(Sender: TObject);
    procedure pmiVisibleClick(Sender: TObject);
    procedure pmiEnabledClick(Sender: TObject);
    procedure actAutoFittingExecute(Sender: TObject);
    procedure ProjectAddFolderExecute(Sender: TObject);
    procedure ModelCreateExecute(Sender: TObject);
    procedure FileNewExecute(Sender: TObject);
    procedure actItemProperitesExecute(Sender: TObject);
    procedure ProjectItemDeleteExecute(Sender: TObject);
    procedure ProjectItemCopyExecute(Sender: TObject);
    procedure ProjectItemExtensionExecute(Sender: TObject);
    procedure FilePrintExecute(Sender: TObject);
    procedure actLayerCopyExecute(Sender: TObject);
    procedure actProjectItemDuplicateExecute(Sender: TObject);
    procedure actModelCopyExecute(Sender: TObject);
    procedure actModelPasteExecute(Sender: TObject);
    procedure pmProjectPopup(Sender: TObject);
    procedure actNewMaterialExecute(Sender: TObject);
    procedure FileCopyPlotBMPExecute(Sender: TObject);
    procedure FilePlotCopyWMFExecute(Sender: TObject);
    procedure FilePlotToFileExecute(Sender: TObject);
    procedure HelpAboutExecute(Sender: TObject);
    procedure HelpContentExecute(Sender: TObject);
    procedure CalcAllExecute(Sender: TObject);
    procedure CalcStopExecute(Sender: TObject);
    procedure ChartMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ChartMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartZoom(Sender: TObject);
    procedure actEditHenkeExecute(Sender: TObject);
    procedure actProjecEditModelTextExecute(Sender: TObject);
    procedure actDataSmoothExecute(Sender: TObject);
    procedure acStructureUndoExecute(Sender: TObject);
    procedure actProjectReopenExecute(Sender: TObject);
    procedure actCalcBenchmarkExecute(Sender: TObject);
    procedure actSystemSettingsExecute(Sender: TObject);
    procedure actSystemExitExecute(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure actCopyStructureBitmapExecute(Sender: TObject);
    procedure ChartResize(Sender: TObject);
    procedure actDataTrimExecute(Sender: TObject);
    procedure actCalcFitJobsExecute(Sender: TObject);
    procedure actRecoverModelExecute(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
      NewDPI: Integer);
    procedure DataNormAutoExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    Project : TXRCProjectTree;
    LFPSO: TLFPSO_Base;

    FProjectDir: string;
    FProjectName: string;
    FProjectFileName: string;
    FIgnoreFocusChange: Boolean;
    FProjectVersion: Byte;

    FModelsRoot: PVirtualNode;
    FDataRoot: PVirtualNode;

    LastNode, FLastModel: PVirtualNode;
    LastData: PProjectData;

    FLastID: integer;
    StartTime, FitStartTime: TDateTime;
    FFitParams: TFitParams;
    FCalc: TCalc;
    FCalcThreadParams: TCalcThreadParams;
    FFitStructure: TFitStructure;
    FLastChiSquare: Single;
    FABestChiSquare: Single;
    FAutoSaveFileName: string;

    FOperationsStack: TStack<String>;
    FRecentProjects : TRecentProjectsManager;

    FTerminated: Boolean;
    FBenchmarkMode: Boolean;
    FBenchmarkPath: string;
    FBenchmarkRuns: Integer;
    FFirstUpdate: Boolean;
    FChartMgr: TChartManager;
    PM: TProfileManager;
    FDPI: Integer;
    FLockOwner: Boolean;
    FLockFile: File;

    procedure CreateProjectTree;
    procedure LoadProject(const FileName: string);
    function DataName(Data: PProjectData): string;
    procedure CreateDefaultProject;
    procedure PrepareProjectFolder(const FileName: string; Clear: Boolean);
    procedure LoadProjectParams(var LinkedID, ActiveID: System.Integer);
    procedure RecoverProjectTree(const ActiveID: Integer);
    procedure RecoverDataCurves(const LinkedID: integer);
    procedure FinalizeCalc(Calc: TCalc);
    procedure GetThreadParams;
    procedure SaveProject(const FileName: string);
    procedure SaveData;
    function GetFitParams: boolean;
    procedure EditProjectItem;
    procedure DeleteModel(Node: PVirtualNode; Data: PProjectData);
    procedure DeleteData(Node: PVirtualNode; Data: PProjectData);
    procedure DeleteExtension(Node: PVirtualNode);
    procedure DeleteFolder(Node: PVirtualNode);
    procedure CreateNewModel(Node: PVirtualNode);
    procedure MatchToStructure;
    procedure CreateFunctionProfileExtension(Node: PVirtualNode);
    procedure EditGradient(var Data: PProjectData);
    function CreateChildNode(out Node: PVirtualNode): boolean; //inline;
    function GetProfileFunctions: TProfileFunctions;
    procedure CreateProfileExtension;
    function FindParentModel(out Node: PVirtualNode): PVirtualNode;
    function IsProfileEnbled: Boolean;
    function PrepareCalc: boolean;
    function PrepareLFPSO : boolean;
    procedure CreateFitGradientExtensions(const P: TProfileFunctions);
    procedure UpdateFitGradientExtensions(const P: TProfileFunctions);
    procedure SaveHistory;
    procedure RescaleChart;
    procedure ProcessBenchFile(Sender: TObject; const F: TSearchRec);
    procedure EditTable(var Data: PProjectData);
    procedure EnableControls(const Enable: boolean);
    procedure AutoSave;
    procedure ProcessJobFile(Sender: TObject; const F: TSearchRec);
    procedure LoadRecentProjectsList;
    procedure OnRecentProjectClick(Sender: TObject; const FileName: string);
    procedure OnCalcModeChange(Sender: TObject);
    procedure OnFittingModeChange(Sender: TObject);
    procedure OnAdvancedSettings(Sender: TObject; var Params: TFitParams);
    procedure RunCalc(const Recover: boolean);
    procedure UpdateInterface(const FitStructure: TFitStructure;
                              const Poly: TProfileFunctions;
                              const Res: TLayeredModel;
                              const CreateExtension: boolean = True);

    procedure CreateTmpLock;
    procedure ReleaseTmpLock;
    function SaveProjectINI(const IniFileName: string):boolean;
    procedure LoadAutoSave;
    procedure ExtractProject(const FileName: string);
    procedure GenerateAutosaveName;
    procedure ScaleInterface;
    function ActiveModelSeries: TFastLineSeries; inline;
    function ActiveDataSeries: TFastLineSeries; inline;
    function IsNonPeriodicProfile: Boolean; inline;
    procedure SaveActiveData;
    function GradientTitle(const P: TFuncProfileRec): string;
    procedure OnChartScaleToggle(Sender: TObject);
    procedure OnChartMinLimitChange(Sender: TObject);
    procedure OnIncrementChange(Sender: TObject);
    procedure OnSetFitLimits(Sender: TObject);
  public
    { Public declarations }
    procedure WMStackClick(var Msg: TMessage); message WM_STR_STACK_CLICK;
    procedure WMLayerClick(var Msg: TMessage); message WM_STR_LAYER_CLICK;
    procedure WMLayerDoubleClick(var Msg: TMessage); message WM_STR_LAYER_DOUBLECLICK;
    procedure WMLayerEditNext(var Msg: TMessage); message WM_STR_EDIT_NEXT;
    procedure WMLayerEditPrev(var Msg: TMessage); message WM_STR_EDIT_PREV;
    procedure WMLinkedClick(var Msg: TMessage); message WM_STR_Linked_CLICK;
    procedure OnMyMessage(var Msg: TMessage); message WM_RECALC;
    procedure OnFitUpdateMsg(var Msg: TMessage); message WM_CHI_UPDATE;
    procedure OnLayerUPMsg(var Msg: TMessage); message WM_STR_LAYER_UP;
    procedure OnLayerDownMsg(var Msg: TMessage); message WM_STR_LAYER_DOWN;
    procedure OnLayerDeleteMsg(var Msg: TMessage); message WM_STR_LAYER_DELETE;
    procedure OnLayerInsertMsg(var Msg: TMessage); message WM_STR_LAYER_INSERT;
    procedure OnCancelBenchmarkMsg(var Msg: TMessage); message WM_BENCH_CANCEL;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  ComObj,
  System.IniFiles,
  System.UITypes,
  AbUtils,
  unit_SeriesIO,
  unit_DataProcessing,
  unit_FileUtils,
  unit_consts,
  unit_XRCLayerControl,
  unit_XRCStructure,
  editor_Stack,
  editor_Layer,
  frm_Limits,
  editor_proj_item,
  ClipBrd,
  frm_NewMaterial,
  frm_about,
  editor_ProfileFunction,
  frm_ExtensionType,
  math_globals,
  editor_HenkeTable,
  editor_JSON,
  unit_LFPSO_Poly,
  unit_SavitzkyGolay,
  unit_files_list,
  unit_config,
  frm_settings,
  unit_XRCStackControl,
  editor_ProfileTable,
  unit_sys_helpers,
  frm_FitSettings,
  Winapi.ShellAPI;

{$R *.dfm}

const
  GradientLabels: array [0..2] of string = ('H', 'S', 'rho');

function TfrmMain.ActiveModelSeries: TFastLineSeries;
begin
  Result := FChartMgr.Series[Project.ActiveModel.CurveID];
end;

function TfrmMain.ActiveDataSeries: TFastLineSeries;
begin
  Result := FChartMgr.Series[Project.ActiveData.CurveID];
end;

function TfrmMain.IsNonPeriodicProfile: Boolean;
begin
  Result := IsProfileEnbled and (FCalcSettings.FittingMode <> fmPeriodic);
end;

procedure TfrmMain.SaveActiveData;
begin
  SeriesToFile(ActiveDataSeries, DataName(Project.ActiveData));
end;

function TfrmMain.GradientTitle(const P: TFuncProfileRec): string;
begin
  Result := Format('F(%s %s/%s)', [GradientLabels[Ord(P.Subj)],
               Structure.Stacks[P.StackID].Title,
               Structure.Stacks[P.StackID].Layers[P.LayerID].Data.Material]);
end;

procedure TfrmMain.OnAdvancedSettings(Sender: TObject; var Params: TFitParams);
begin
  frmFitSettings.ShowSettings(FFitParams);
end;

procedure TfrmMain.OnChartScaleToggle(Sender: TObject);
begin
  if Chart.LeftAxis.Logarithmic then
  begin
    Chart.LeftAxis.Logarithmic := False;
    FChartInfo.SetScaleCaption('Log');
    if Chart.LeftAxis.Maximum > 0.01 then
      Chart.LeftAxis.AxisValuesFormat := '0.000'
    else
      Chart.LeftAxis.AxisValuesFormat := '0x10E-0';
  end
  else
  begin
    FChartInfo.SetScaleCaption('Linear');
    Chart.LeftAxis.Logarithmic := True;
    Chart.LeftAxis.AxisValuesFormat := '0x10E-0';
  end;
end;

procedure TfrmMain.OnChartMinLimitChange(Sender: TObject);
begin
  Chart.LeftAxis.Minimum := FChartInfo.MinLimit;
end;

procedure TfrmMain.CreateNewModel(Node: PVirtualNode);
var
  PL: PVirtualNode;
begin
  // добавляем модель
  PL := Project.AddChild(Node, Nil);
  Project.ActiveModel := Project.GetNodeData(PL);
  Project.ActiveModel.ID := FLastID;
  Project.ActiveModel.Title := 'Model ' + IntToStr(FLastID);
  Project.ActiveModel.Group := gtModel;
  Project.ActiveModel.RowType := prItem;

  FChartMgr.AddSeries(Project.ActiveModel);
  Project.Expanded[Node] := True;
  inc(FLastID);
end;

procedure TfrmMain.ModelCreateExecute(Sender: TObject);
begin
  Project.ActiveModel.Data := Structure.ToString;
  CreateNewModel(FModelsRoot);
end;

procedure TfrmMain.actItemProperitesExecute(Sender: TObject);
begin
  EditProjectItem;
end;

procedure TfrmMain.OnCancelBenchmarkMsg(var Msg: TMessage);
begin
  CalcStopExecute(nil);
end;

procedure TfrmMain.OnFitUpdateMsg(var Msg: TMessage);
var
  msg_prm: PUpdateFitProgressMsg;
  Hour, Min, Sec, MSec: Word;
  NeedsSaving: boolean;
begin
  msg_prm := PUpdateFitProgressMsg(Msg.WParam);
  FChartPages.AddConvergencePoint(msg_prm.Step, msg_prm.BestChi);

  FChartInfo.SetChiSquare(msg_prm.LastChi, msg_prm.BestChi);

  FLastChiSquare :=  msg_prm.BestChi;
  if FABestChiSquare > FLastChiSquare then
  Begin
    NeedsSaving := True;
    FABestChiSquare := FLastChiSquare
  End
  else
    NeedsSaving := False;

  if msg_prm.Full then
  begin
    FChartMgr.PlotResults(Project.ActiveModel.CurveID, msg_prm.Curve);
    if TConfig.Section<TOtherOptions>.LiveUpdate then
    begin
      UpdateInterface(msg_prm.Structure, msg_prm.Poly, msg_prm.LayeredModel, FFirstUpdate);
      FFirstUpdate := False;
      if NeedsSaving then
           AutoSave;
    end;
    msg_prm.LayeredModel.Free;
  end;
  Dispose(msg_prm);
  DecodeTime(Now - FitStartTime, Hour, Min, Sec, MSec);
  spnFitTime.Caption := Format('Fitting Time: %2.2d:%2.2d:%2.2d sec', [Hour, Min, Sec]);
end;

procedure TfrmMain.OnLayerDeleteMsg(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.DeleteLayer(LayerID, ID);
end;

procedure TfrmMain.OnLayerDownMsg(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.MoveLayer(LayerID, ID, 1);
end;

procedure TfrmMain.OnLayerInsertMsg(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.SelectLayer(LayerID, ID);
  LayerInsertExecute(nil);
  Structure.ClearSelection;
end;

procedure TfrmMain.OnLayerUPMsg(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.MoveLayer(LayerID, ID, -1);
end;

procedure TfrmMain.OnMyMessage(var Msg: TMessage);
begin
  PM.PlotProfile(IsNonPeriodicProfile, FChartPages.IsProfileActive);
  CalcRunExecute(Self);
end;

procedure TfrmMain.CreateProjectTree;
begin
  Project := TXRCProjectTree.Create(RzPanel1, FDPI);
  Project.Parent := RzPanel1;

  Project.OnChange := ProjectChange;
  Project.OnDblClick := ProjectDblClick;
  Project.OnFocusChanging := ProjectFocusChanging;
  Project.PopupMenu := pmProject;
end;


procedure TfrmMain.ProjectChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FIgnoreFocusChange then
    Exit;

  if Node = LastNode then Exit;

  LastData := Project.GetNodeData(LastNode);
  if (LastData <> nil) and LastData.IsModel then
    LastData.Data := Structure.ToString;

  LastNode := Project.GetFirstSelected;
  LastData := Project.GetNodeData(LastNode);

  if LastData = nil then
    Exit;

  if (LastData.RowType = prItem) and (LastData.Group = gtData) then
    Project.ActiveData := LastData;

  if LastData.IsModel then
  begin
     FLastModel := LastNode;
     if LastData.Data <> '' then
     begin
       Structure.FromString(LastData.Data);
       FOperationsStack.Clear;
       FOperationsStack.Push(LastData.Data);
       PM.Prepare(Structure, FChartPages.ThicknessChart, FChartPages.RoughnessChart, FChartPages.DensityChart);
       PM.PlotProfile(IsNonPeriodicProfile, FChartPages.IsProfileActive);
     end;
  end;
end;

procedure TfrmMain.ProjectDblClick(Sender: TObject);
begin
  EditProjectItem;
end;

procedure TfrmMain.ProjectAddFolderExecute(Sender: TObject);
var
  Node: PVirtualNode;
  Data: PProjectData;
  PD: PProjectData;

  s: string;
begin
  s := 'Folder';
  if not InputQuery('New folder', 'Input folder title', s) or (s = '') then
    Exit;

  Node := Project.GetFirstSelected;
  if Node = nil then
    Node := FModelsRoot;

  PD := Project.GetNodeData(Node);
  if PD.RowType <> prGroup then
  begin
    case PD.Group of
      gtModel:
        Node := Project.AddChild(FModelsRoot);
      gtData:
        Node := Project.AddChild(FDataRoot);
    end;
  end
  else
    Node := Project.AddChild(Node);
  Data := Project.GetNodeData(Node);
  Data.ID := 0;
  Data.Title := s;
  Data.Group := PD.Group;
  Data.RowType := prFolder;
  Project.ClearSelection;
  Project.Selected[Node] := True;
end;

procedure TfrmMain.ProjectFocusChanging(Sender: TBaseVirtualTree; OldNode,
  NewNode: PVirtualNode; OldColumn, NewColumn: TColumnIndex;
  var Allowed: Boolean);
var
  Data: PProjectData;
begin
  Allowed := True;
  Data := Sender.GetNodeData(NewNode);
  if Data = nil then Exit;

  mmDescription.Lines.Text := Data.Description;

  if not((Data.RowType = prItem) and (Data.Group = gtModel)) then
    Exit;

  Project.ActiveModel := Data;
  Project.Repaint;
end;

procedure TfrmMain.ProjectItemCopyExecute(Sender: TObject);
var
  Data: PProjectData;
begin
  Data := Project.GetNodeData(Project.GetFirstSelected);
  if (Data.Group = gtModel) and (Data.RowType = prItem) then
  begin
    ClipBoard.AsText := Structure.ToString;
  end;
  if (Data.Group = gtData) and (Data.RowType = prItem) then
    SeriesToClipboard(FChartMgr.Series[Data.CurveID], FCalcSettings.CalcMode);
end;

procedure TfrmMain.DeleteModel(Node: PVirtualNode; Data: PProjectData);
begin
  FChartMgr.DeleteSeries(Data.CurveID);
  Project.DeleteNode(Node);
  Project.Repaint;
  Project.ActiveModel := nil;
end;

procedure TfrmMain.DeleteData(Node: PVirtualNode; Data: PProjectData);
begin
  DeleteFile(DataName(Data));
  FChartMgr.DeleteSeries(Data.CurveID);
  Project.DeleteNode(Node);
  Project.Refresh;
end;

procedure TfrmMain.DeleteExtension(Node: PVirtualNode);
begin
  Project.DeleteNode(Node);
  Project.Refresh;
end;

procedure TfrmMain.DeleteFolder(Node: PVirtualNode);
begin
  if Node.ChildCount = 0 then
    Project.DeleteNode(Node)
  else
    ShowMessage('The folder is not empty! Can''t delete !');
end;

procedure TfrmMain.ProjectItemDeleteExecute(Sender: TObject);
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := Project.GetFirstSelected;
  while Node <> nil do
  begin
    Data := Project.GetNodeData(Node);
    if (Data.Group = gtModel) and (Data.RowType = prItem) then
      DeleteModel(Node, Data);

    if (Data.Group = gtData) and (Data.RowType = prItem) then
    begin
      if Data = Project.LinkedData then
        Project.LinkedData := nil;
      DeleteData(Node, Data);
    end;

    if (Data.RowType = prFolder) then
      DeleteFolder(Node);
    if (Data.RowType = prExtension) then
      DeleteExtension(Node);
    Node := Project.GetFirstSelected;
  end;
  LastNode := nil;
  ProjectChange(Project, Nil);
end;

function TfrmMain.CreateChildNode(out Node: PVirtualNode): boolean;
var
  Data: PProjectData;
begin
  Result := False;
  Node := Project.GetFirstSelected;
  if Node = Nil  then Exit;

  Data := Project.GetNodeData(Node);
  if Data.Group = gtModel then
  begin
    if Data.RowType = prItem then
      Node := Project.AddChild(Node);
    if Data.RowType = prExtension then
      Node := Project.AddChild(Node.Parent);
    Result := True;
  end
  else
    ShowMessage('Parent model is not selected!');
end;

function TfrmMain.FindParentModel(out Node: PVirtualNode): PVirtualNode;
var
  Data: PProjectData;
begin
  Result := nil;
  if Node = Nil  then Exit;

  Data := Project.GetNodeData(Node);
  if Data.Group = gtModel then
  begin
    if Data.RowType = prExtension then
      Result := Node.Parent
    else
      Result := Node;
  end
end;

procedure TfrmMain.ProjectItemExtensionExecute(Sender: TObject);
var
  EType: TExtentionType;
  Node : PVirtualNode;
begin
  EType := SelectExtensionTypeAction;
  if EType = etNone then Exit;

  case EType of
    etFunction : begin
                    if CreateChildNode(Node) then
                          CreateFunctionProfileExtension(Node);
                  end;
    etTable  : CreateProfileExtension;
  end;
end;

procedure TfrmMain.CreateProfileExtension;
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := FindParentModel(LastNode);
  if Node = nil then Exit;


  if not Project.ProfileAttached(Node) then
  begin
    Node := Project.AddChild(Node);
    Data := Project.GetNodeData(Node);

    Data.Group := gtModel;
    Data.Enabled := True;
    Data.RowType := prExtension;
    Data.Title := 'Table';
    Data.ExtType := etTable;
    Data.StackID := -1;
    Data.LayerID := -1;
    Data.Form := ffNone;

    Project.ClearSelection;
    Project.Selected[Node] := True;
  end;
end;

procedure TfrmMain.UpdateFitGradientExtensions(const P: TProfileFunctions);
var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i: Integer;
  Title: string;
  Found: Boolean;
begin
  for I := 0 to High(P) do
  begin
    Title := GradientTitle(P[i]);

    Gradient := FLastModel.FirstChild;
    Found := False;
    repeat
      Data := Project.GetNodeData(Gradient);
      if Data.Title = Title then
      begin
        Data.SetPoly(P[i].C);
        Found := True;
      end
      else
        Gradient := Gradient.NextSibling;
    until Found or (Gradient <> FLastModel.LastChild);
  end;

  MatchToStructure;
  Project.Expanded[FLastModel] := True;
  Project.ClearSelection;
  Project.Selected[FLastModel] := True;
end;

procedure TfrmMain.CreateFitGradientExtensions(const P: TProfileFunctions);
var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i: Integer;
begin
  for I := 0 to High(P) do
  begin
    Gradient := Project.AddChild(FLastModel);
    Data := Project.GetNodeData(Gradient);

    Data.Group := gtModel;
    Data.Enabled := True;
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
  Project.Expanded[FLastModel] := True;
  Project.ClearSelection;
  Project.Selected[FLastModel] := True;
end;

procedure TfrmMain.CreateFunctionProfileExtension(Node: PVirtualNode);
var
  Data: PProjectData;
begin
  Data := Project.GetNodeData(Node);

  Data.Group := gtModel;
  Data.Enabled := True;
  Data.RowType := prExtension;
  Data.Title := 'Gradient ' + IntToStr(Node.Parent.ChildCount);
  Data.ExtType := etFunction;
  Data.Poly[0] := 0;
  Data.Poly[1] := 0.14;
  Data.Poly[10] := 1;
  Data.StackID := -1;
  Data.LayerID := -1;
  Data.Form := ffPoly;

  Project.ClearSelection;
  Project.Selected[Node] := True;
end;

procedure TfrmMain.EditProjectItem;
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  Node := Project.GetFirstSelected;
  Data := Project.GetNodeData(Node);
  case Data.RowType of
    prFolder:
      begin
        Data.Title := InputBox('Folder', 'Edit the folder''s title', Data.Title);
      end;
    prItem:
      begin
        edtrProjectItem.Data := Data;
        if edtrProjectItem.ShowModal = mrOk then
        begin
          FChartMgr.Series[Data.CurveID].Color := Data.Color;
          FChartMgr.Series[Data.CurveID].Title := Data.Title;
          mmDescription.Lines.Text := Data.Description;
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


procedure TfrmMain.EditTable(var Data: PProjectData);
begin
  edtrProfileTable.Data := Data;
  edtrProfileTable.Structure := Structure;
  if edtrProfileTable.ShowModal = mrOk then
  begin
    mmDescription.Lines.Text := Data.Description;
  end;
end;

procedure TfrmMain.EditGradient(var Data: PProjectData);
begin
  edtrProfileFunction.Data := Data;
  edtrProfileFunction.Structure := Structure;
  if edtrProfileFunction.ShowModal = mrOk then
  begin
    mmDescription.Lines.Text := Data.Description;
  end;
end;

procedure TfrmMain.DataCopyClpbrdExecute(Sender: TObject);
begin
  SeriesToClipboard(ActiveDataSeries, FCalcSettings.CalcMode);
end;

procedure TfrmMain.DataExportExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
      SeriesToFile(ActiveModelSeries, dlgSaveResult.FileName);
end;

procedure TfrmMain.DataLoadExecute(Sender: TObject);
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  if not dlgLoadData.Execute then
    Exit;

  Node := Project.GetFirstSelected;
  if Node = nil then
    Node := FDataRoot;

  Data := Project.GetNodeData(Node);
  if (Data.RowType = prFolder) and (Data.Group = gtData) then
    Node := Project.AddChild(Node)
  else
    Node := Project.AddChild(FDataRoot);

  Data := Project.GetNodeData(Node);
  Data.ID := FLastID;
  inc(FLastID);
  Data.Title := ExtractFileName(dlgLoadData.FileName);
  Data.Group := gtData;
  Data.RowType := prItem;

  FChartMgr.AddSeries(Data);

  SeriesFromFile(FChartMgr.Series[Data.CurveID], dlgLoadData.FileName, Data.Description);
  SeriesToFile(FChartMgr.Series[Data.CurveID], DataName(Data));

  Project.ActiveData := Data;
  Project.Expanded[FDataRoot] := True;
end;

function TfrmMain.DataName(Data: PProjectData): string;
begin
  Result := Format('%sdata_%d.dat', [FProjectDir, Data.ID])
end;

procedure TfrmMain.DataNormAutoExecute(Sender: TObject);
var
  ModelSeries, DataSeries: TFastLineSeries;
begin
  ModelSeries := ActiveModelSeries;
  DataSeries := ActiveDataSeries;
  NormalizeAuto(ModelSeries, DataSeries);
  SaveActiveData;
end;

procedure TfrmMain.DataNormExecute(Sender: TObject);
var
  s: string;
  DataSeries: TFastLineSeries;
begin
  s := InputBox('Data normalization', 'Coefficient', '');
  if s <> '' then
  begin
    DataSeries := ActiveDataSeries;
    Normalize(StrToFloat(s), DataSeries);
    SaveActiveData;
  end;
end;

procedure TfrmMain.actDataSmoothExecute(Sender: TObject);
var
  Data: TDataArray;
  DataSeries: TFastLineSeries;
begin
  DataSeries := ActiveDataSeries;
  Data := SeriesToData(DataSeries);
  Data := MovAvg(Data, 5);
  DataToSeries(Data, DataSeries);
  SaveActiveData;
end;

procedure TfrmMain.actDataTrimExecute(Sender: TObject);
var
  t1, t2: single;
  index: integer;

  function FindIndex(const val: single): integer;
  var
    i: integer;
  begin
    Result := -1;
    for I := 0 to ActiveDataSeries.XValues.Count - 1 do
      if ActiveDataSeries.XValues[i] >= val then
      begin
        Result := i;
        Break;
      end;
  end;

begin
  FCalcSettings.GetAxisRange(t1, t2);

  index := FindIndex(t1);
  if index > 1 then
  begin
    ActiveDataSeries.BeginUpdate;
    ActiveDataSeries.Delete(0, Index);
    ActiveDataSeries.EndUpdate;
  end;

  index := FindIndex(t2);
  if index > 1 then
  begin
    ActiveDataSeries.BeginUpdate;
    ActiveDataSeries.Delete(index, ActiveDataSeries.XValues.Count - Index - 1);
    ActiveDataSeries.EndUpdate;
  end;
  SaveActiveData;
end;

procedure TfrmMain.actEditHenkeExecute(Sender: TObject);
begin
  edtrHenkeTable.ShowModal;
end;

procedure TfrmMain.actLayerCopyExecute(Sender: TObject);
begin
  SaveHistory;

  Structure.CopyLayer(False);
end;

procedure TfrmMain.actModelCopyExecute(Sender: TObject);
begin
  ClipBoard.AsText := Structure.ToString;
end;

procedure TfrmMain.actModelPasteExecute(Sender: TObject);
begin
  Project.ActiveModel.Data := Structure.ToString;
  CreateNewModel(FModelsRoot);
  Project.ActiveModel.Data := ClipBoard.AsText;
  Structure.FromString(Project.ActiveModel.Data);
end;

procedure TfrmMain.actProjecEditModelTextExecute(Sender: TObject);
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

procedure TfrmMain.actProjectItemDuplicateExecute(Sender: TObject);
var
  S: string;
begin
  Project.ActiveModel.Data := Structure.ToString;
  S := Structure.ToString;
  CreateNewModel(FModelsRoot);
  Structure.FromString(S);
  Project.ActiveModel.Data := S;
end;

procedure TfrmMain.actProjectReopenExecute(Sender: TObject);
begin
  PrepareProjectFolder(FProjectFileName, True);
  LoadProject(FProjectFileName);
end;

procedure TfrmMain.actRecoverModelExecute(Sender: TObject);
begin
  RunCalc(True);
end;

procedure TfrmMain.actSystemExitExecute(Sender: TObject);
begin
  Close;
end;

procedure TfrmMain.actSystemSettingsExecute(Sender: TObject);
begin
  frmSettings.ShowModal;
end;

procedure TfrmMain.actNewMaterialExecute(Sender: TObject);
begin
  frmNewMaterial.ShowModal;
end;


procedure TfrmMain.GenerateAutosaveName;
var
  FileName, Path: string;
  p: Integer;
begin
  FileName := FProjectName;
  if TConfig.SystemDir[sdOutDir] <> '' then
    Path := TConfig.SystemDir[sdOutDir]
  else
    Path := ExtractFilePath(FileName);

  p := pos(PROJECT_EXT, FileName);
  Delete(FileName, p, Length(PROJECT_EXT));
  FAutoSaveFileName := Path + FileName + '-fitted'+ PROJECT_EXT;
end;

procedure TfrmMain.AutoSave;

begin
  if TConfig.Section<TOtherOptions>.AutoSave then
  begin
    SaveProject(FAutoSaveFileName);
  end;
end;

procedure TfrmMain.OnSetFitLimits(Sender: TObject);
var
  FitStructure: TFitStructure;
begin
  FitStructure := Structure.ToFitStructure;
  frmLimits.ShowLimits('Save', FitStructure);
  Structure.UpdateInterfaceP(FitStructure);
end;

procedure TfrmMain.DataPasteExecute(Sender: TObject);
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := Project.AddChild(FDataRoot);
  Data := Project.GetNodeData(Node);

  Data.ID := FLastID;
  inc(FLastID);
  Data.Title := 'Data ' + IntToStr(Node.Index + 1) + '.dat';
  Data.Group := gtData;
  Data.RowType := prItem;

  FChartMgr.AddSeries(Data);
  Project.Expanded[FDataRoot] := True;

  SeriesFromClipboard(FChartMgr.Series[Data.CurveID]);
  SeriesToFile(FChartMgr.Series[Data.CurveID], DataName(Data));
end;

procedure TfrmMain.SaveHistory;
begin
  FOperationsStack.Push(Structure.ToString);
end;

procedure TfrmMain.MatchToStructure;
begin
  PM.Prepare(Structure, FChartPages.ThicknessChart, FChartPages.RoughnessChart, FChartPages.DensityChart);
  PM.PlotProfile(IsNonPeriodicProfile, FChartPages.IsProfileActive);
  Project.ActiveModel.Data := Structure.ToString;
end;

procedure TfrmMain.PeriodAddExecute(Sender: TObject);
var
  Name: string;
  N   : Integer;
begin
  N := 1;
  edtrStack.Edit(Name, N);
  if Name <> '' then
  begin
    SaveHistory;
    Structure.AddStack(N, Name);
    MatchToStructure;
  end;
end;

procedure TfrmMain.PeriodDeleteExecute(Sender: TObject);
begin
  SaveHistory;

  Structure.DeleteStack;
  MatchToStructure;
end;

procedure TfrmMain.PeriodInsertExecute(Sender: TObject);
var
  Name: string;
  N   : Integer;
begin
  N := 1;
  edtrStack.Edit(Name, N);
  if Name <> '' then
  begin
    SaveHistory;
    Structure.InsertStack(N, Name);
    MatchToStructure;
  end;
end;

procedure TfrmMain.PrepareProjectFolder(const FileName: string; Clear: Boolean);
begin
  FProjectFileName := FileName;
  FProjectName := ExtractFileName(FileName);
  FProjectDir := IncludeTrailingPathDelimiter(Config.TempPath + CreateClassID);

  if Clear then
  begin
    // удаляем папку старого проекта
    if DirectoryExists(FProjectDir, False) then
      ClearDir(FProjectDir);
    //
    CreateDir(FProjectDir);
  end;
end;

procedure TfrmMain.ExtractProject(const FileName:string);
begin
  UnZip.BaseDirectory := FProjectDir;
  UnZip.FileName := FileName;
  unZip.OpenArchive(FileName);
  unZip.ExtractFiles('*.*');
  unZip.CloseArchive;
end;


procedure TfrmMain.LoadProjectParams(var LinkedID, ActiveID: System.Integer);
var
  INF: TMemIniFile;
begin
  INF := TMemIniFile.Create(FProjectDir + PARAMETERS_FILE_NAME);
  try
    FCalcSettings.LoadFromINI(INF);
    FChartInfo.LoadFromINI(INF);

    LinkedID := INF.ReadInteger('STATE', 'LinkedData', -1);
    ActiveID := INF.ReadInteger('STATE', 'ActiveModel', -1);
    Chart.LeftAxis.Logarithmic := INF.ReadBool('STATE', 'LogScale', True);
    FProjectVersion := INF.ReadInteger('INFO', 'Version', 0);

    FCalcSettings.LoadAdvancedParams(INF, FFitParams);
  finally
    INF.Free;
  end;
end;

function TfrmMain.GetFitParams: boolean;
begin
  if not FBenchmarkMode then
  begin
    Result := False;
    FFitStructure := Structure.ToFitStructure;
    if frmLimits.ShowLimits('Run', FFitStructure) then
          Structure.UpdateInterfaceP(FFitStructure)
    else begin
      Exit;
    end;
  end
  else
    FFitStructure := Structure.ToFitStructure;

  FCalcSettings.ReadFitParams(FFitParams);

  Result := True;
end;

function TfrmMain.GetProfileFunctions: TProfileFunctions;
var
  Item: PVirtualNode;
  Data: PProjectData;
  Count: integer;
begin
  SetLength(Result, 0);
  Count := 0;
  Item := Project.GetFirstChild(FLastModel);
  while Item <> Nil do
  begin
    Data := Project.GetNodeData(Item);
    if (Data.RowType = prExtension) and (Data.Enabled) and (Data.ExtType = etFunction) then
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
    Item := Project.GetNextSibling(Item);
  end;
end;

procedure TfrmMain.GetThreadParams;
begin
  StartTime := Now;

  ActiveModelSeries.BeginUpdate;

  FCalcSettings.FillCalcThreadParams(FCalcThreadParams);
end;

procedure TfrmMain.HelpAboutExecute(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.HelpContentExecute(Sender: TObject);
var
  ManualPath: string;
begin
  ManualPath := TConfig.AppPath + 'Help\UserManual.html';
  ShellExecute(Handle, 'open', PChar(ManualPath), nil, nil, SW_SHOWNORMAL);
end;

procedure TfrmMain.pmiEnabledClick(Sender: TObject);
begin
  LastData.Enabled := not LastData.Enabled;
  Project.Repaint;
end;

procedure TfrmMain.pmiLinkedClick(Sender: TObject);
begin
  if not pmiLinked.Checked then
    Project.LinkedData := nil
  else
    Project.LinkedData := LastData;

  Project.Repaint;
end;

procedure TfrmMain.pmiVisibleClick(Sender: TObject);
begin
  FChartMgr.Series[LastData.CurveID].Visible := pmiVisible.Checked;
  LastData.Visible := pmiVisible.Checked;
  Project.Repaint;
end;

procedure TfrmMain.pmProjectPopup(Sender: TObject);
var
  IsModel, IsProfile: boolean;
begin
  case LastData.RowType of
        prItem:  begin
                    IsModel := LastData.IsModel;
                    pmiEnabled.Visible := False;
                    pmiVisible.Visible := True;
                    pmiVisible.Checked := LastData.Visible;
                    pmiLinked.Visible  := not IsModel;
                    pmiLinked.Checked  := LastData = Project.LinkedData;
                    pmiNorm.Visible    :=  not IsModel;
                    pmCopytoclipboard.Visible := not IsModel;
                    pmExporttofile.Visible    := not IsModel;
                 end;
    prExtension: begin
                    pmiNorm.Visible := False;
                    pmiEnabled.Visible := True;
                    pmiEnabled.Checked := LastData.Enabled;
                    pmiVisible.Visible := False;
                    pmiLinked.Visible  := False;

                    IsProfile := LastData.ExtType = etTable;
                    pmCopytoclipboard.Visible := IsProfile;
                    pmExporttofile.Visible    := IsProfile;
                 end;
  end;
end;

procedure TfrmMain.FinalizeCalc(Calc: TCalc);
var
  Hour, Min, Sec, MSec: Word;
begin
  RescaleChart;
  FChartMgr.PlotResults(Project.ActiveModel.CurveID, Calc.Results);
  DecodeTime(Now - StartTime, Hour, Min, Sec, MSec);
  spnTime.Caption := Format('Time: %d.%3.3d s.', [60 * Min + Sec, MSec]);
  ActiveModelSeries.EndUpdate;
  ActiveModelSeries.Repaint;
  FChartInfo.SetPeriod(Structure.Period);
  Screen.Cursor := crDefault;
  FChartInfo.SetPeakInfo(ActiveModelSeries, Chart.BottomAxis.Minimum, Chart.BottomAxis.Maximum);
end;

procedure TfrmMain.CalcAllExecute(Sender: TObject);
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  if FModelsRoot.ChildCount > 0 then
    Node := Project.GetFirstChild(FModelsRoot)
  else
    Exit;

  while Node <> nil do
  begin
    Data := Project.GetNodeData(Node);
    if Data.IsModel then
    begin
      Project.ActiveModel := Data;
      Structure.FromString(Data.Data);
      CalcRunExecute(Sender);
    end;
    Node := Project.GetNextSibling(Node);
  end;
end;

function TfrmMain.IsProfileEnbled: Boolean;
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Result := False;
  Node := Project.GetFirstChild(FLastModel);
  while Node <> nil do
  begin
    Data := Project.GetNodeData(Node);
    if Data.ExtType = etTable then
    begin
      Result := Data.Enabled;
      Break;
    end;
    Node := Project.GetNextSibling(Node);
  end;

end;

procedure TfrmMain.RunCalc(const Recover: boolean);
begin
  try
    if not PrepareCalc then Exit;
    try
      EnableControls(False);
      FCalc.Run;
      if (Project.LinkedData <> nil) and ActiveModelSeries.Visible then
      begin
        FCalc.CalcChiSquare(FCalcSettings.ThetaWeightIndex);
        FChartInfo.SetChiSquare(FCalc.ChiSQR, FCalc.ChiSQR);
      end
      else begin
        FChartInfo.ClearChiSquare;
        FLastChiSquare := 0;
      end;

      PM.Prepare(Structure, FChartPages.ThicknessChart, FChartPages.RoughnessChart, FChartPages.DensityChart);
      if IsNonPeriodicProfile then
         PM.PlotProfileNP(FChartPages.IsProfileActive)
      else
        PM.PlotProfile(IsNonPeriodicProfile, FChartPages.IsProfileActive);
    except
      on E: exception do
      begin
        ShowMessage(E.Message);
        ActiveModelSeries.EndUpdate;
        ActiveModelSeries.Repaint;
        Screen.Cursor := crDefault;
        CalcRun.Enabled := True;
      end;
    end;
    FinalizeCalc(FCalc);
  finally
    EnableControls(True);
    FCalc.Free;
  end;
end;

procedure TfrmMain.CalcRunExecute(Sender: TObject);
begin
  RunCalc(False);
end;

procedure TfrmMain.CalcStopExecute(Sender: TObject);
begin
  FTerminated := True;

  if LFPSO <> nil then
  begin
       LFPSO.Terminate;
  end;
end;

procedure TfrmMain.EnableControls(const Enable: boolean);
begin
  tlbrFile.Enabled := Enable;
  FStructurePanel.SetToolbarEnabled(Enable);
  tlbrProject.Enabled := Enable;
  ChartToolBar.Enabled := Enable;
  FChartPages.SetCopyEnabled(Enable);

  btnStop.Visible := not Enable;
  Structure.Enabled := Enable;
  Project.Enabled := Enable;
  FCalcSettings.Enabled := Enable;
end;

function TfrmMain.PrepareCalc: Boolean;
begin
  Result :=False;
  if (Project.ActiveModel = nil) then Exit;

  FCalc := TCalc.Create;
  FCalc.Limit := FChartInfo.MinLimit;
  if (Project.LinkedData <> nil) and ActiveModelSeries.Visible then
  begin
    FCalc.ExpValues := SeriesToData(FChartMgr.Series[Project.LinkedData.CurveID]);
    if FCalcSettings.IsPWChiSqr then
      FCalc.MovAvg := MovAvg(FCalc.ExpValues, FFitParams.MovAvgWindow);
  end;

  GetThreadParams;
  FCalc.Params := FCalcThreadParams;
  FCalc.Model := Structure.Model(IsNonPeriodicProfile);
  FCalc.Model.Profiles := GetProfileFunctions;
  Screen.Cursor := crHourGlass;
  Result := True;
end;


function TfrmMain.PrepareLFPSO: Boolean;
begin
  Result := False;
  case FCalcSettings.FittingMode of
    fmIrregular : LFPSO := TLFPSO_Irregular.Create;
    fmPeriodic  : LFPSO := TLFPSO_Periodic.Create;
    fmPoly      : LFPSO := TLFPSO_Poly.Create;
  end;

  GetThreadParams;

  LFPSO.Params := FFitParams;
  LFPSO.Limit := FChartInfo.MinLimit;

  if (Project.LinkedData <> nil) and ActiveModelSeries.Visible then
  begin
    LFPSO.ExpValues := SeriesToData(FChartMgr.Series[Project.LinkedData.CurveID]);
    if FCalcSettings.IsPWChiSqr then
      LFPSO.MovAvg := MovAvg(LFPSO.ExpValues, FFitParams.MovAvgWindow);
  end else
  begin
     FreeAndNil(LFPSO);
     ShowMessage('Measured curve is not linked!');
     Exit;
  end;

  LFPSO.Structure := FFitStructure;

  FChartPages.PrepareConvergence(FFitParams.NMax);

  Result := True;
end;

procedure TfrmMain.acStructureUndoExecute(Sender: TObject);
begin
  if FOperationsStack.Count > 0 then
  begin
    Structure.FromString(FOperationsStack.Extract);
  end;
end;


procedure TfrmMain.UpdateInterface;
begin
  if Structure.IsPeriodic then
  begin
    if FCalcSettings.FittingMode = fmPeriodic then
       Structure.UpdateInterfaceP(FitStructure)
    else begin
      if FCalcSettings.FittingMode = fmPoly then
      begin
        Structure.UpdateInterfaceP(FitStructure);
        if CreateExtension then
          CreateFitGradientExtensions(Poly)
        else
          UpdateFitGradientExtensions(Poly)
      end
      else
      begin
        Structure.UpdateInterfaceNP(FitStructure);
        if CreateExtension then
           CreateProfileExtension;
        Structure.UpdateProfiles(Res);
      end;
    end;
  end
  else
    Structure.UpdateInterfaceNP(FitStructure);
end;

procedure TfrmMain.LoadAutoSave;
begin
  if FileExists(FAutoSaveFileName) then
  begin
    LoadProject(FAutoSaveFileName);
    CalcRunExecute(frmMain);
  end;
end;

procedure TfrmMain.actAutoFittingExecute(Sender: TObject);
var
  Hour, Min, Sec, MSec: Word;
  FitResult: TLayeredModel;
begin
  if not GetFitParams then Exit;

  try
    if not PrepareLFPSO then Exit;
    Screen.Cursor := crHourGlass;
    GenerateAutosaveName;
    EnableControls(False);
    FitStartTime := Now;

    FFirstUpdate := True;

    FABestChiSquare := 1e32;
    LFPSO.Run(FCalcThreadParams);
    FitResult := LFPSO.Result;
    try
      UpdateInterface(LFPSO.Structure, LFPSO.Polynomes, FitResult, FFirstUpdate);
    finally
      FitResult.Free;
    end;

    Project.ActiveModel.Data  := Structure.ToString;
    DecodeTime(Now - FitStartTime, Hour, Min, Sec, MSec);
    spnFitTime.Caption := Format('Fitting Time: %2.2d:%2.2d:%2.2d sec', [Hour, Min, Sec]);
    CalcRunExecute(nil);
  finally
    Screen.Cursor := crDefault;
    EnableControls(True);
    FreeAndNil(LFPSO);
  end;
  LoadAutoSave;
end;

procedure TfrmMain.ProcessJobFile(Sender: TObject; const F: TSearchRec);
begin
  Application.ProcessMessages;
  if FTerminated then Exit;

  FProjectFileName := FBenchmarkPath + F.Name;

  actProjectReopenExecute(nil);
  actAutoFittingExecute(nil);
  //AutoSave;
end;

procedure TfrmMain.ProcessBenchFile(Sender: TObject; const F: TSearchRec);
var
  i: Integer;
begin
  FProjectFileName := FBenchmarkPath + F.Name;

  frmBenchmark.AddFile(ChangeFileExt(F.Name, ''));
  for i := 1 to FBenchmarkRuns do
  begin
    if FTerminated then Break;
    actProjectReopenExecute(nil);
    actAutoFittingExecute(nil);
    Application.ProcessMessages;
    frmBenchmark.AddValue(i, FloatToStrF(FLastChiSquare, ffFixed, 8, 4));
    frmBenchmark.CalcStats(False);
  end;
  if not FTerminated then frmBenchmark.CalcStats(True);
end;

procedure TfrmMain.actCalcBenchmarkExecute(Sender: TObject);
var
  Files: TFilesList;
begin
  FLastChiSquare := 0;
  FBenchmarkRuns := TConfig.Section<TCalcOptions>.BenchmarkRuns;

  try
    FTerminated := False;
    frmBenchmark.Clear(FBenchmarkRuns);
    frmBenchmark.Init(TConfig.SystemDir[sdBenchOutDir]);
    frmBenchmark.Show;
    FBenchmarkMode := True;

    Files := TFilesList.Create(nil);
    FBenchmarkPath := TConfig.SystemDir[sdBenchDir];
    Files.TargetPath := FBenchmarkPath;
    Files.Mask := '*' + PROJECT_EXT;
    Files.OnFile := ProcessBenchFile;
    Files.Process;
    FBenchmarkMode := False;
  finally
    FreeAndNil(Files);
  end;
end;

procedure TfrmMain.actCalcFitJobsExecute(Sender: TObject);
var
  Files: TFilesList;
begin
  try
    FTerminated := False;
    FBenchmarkMode := True;
    Files := TFilesList.Create(nil);
    FBenchmarkPath := TConfig.SystemDir[sdJobsDir];
    Files.TargetPath := FBenchmarkPath;
    Files.Mask := '*' + PROJECT_EXT;
    Files.OnFile := ProcessJobFile;
    Files.Process;
    if not FTerminated then
      ShowMessage('All jobs done')
    else
      ShowMessage('Batch was terminated!');
  finally
    FreeAndNil(Files);
    FBenchmarkMode := False;
  end;
end;

procedure TfrmMain.actCopyStructureBitmapExecute(Sender: TObject);
var
  Image: TPNGImage;
  Bitmap: TBitmap;
  MyFormat: Word;
  AData: THandle;
  APalette: HPALETTE;
  MyRect : TRect;
begin
  Image := TPNGImage.Create;
  Bitmap := TBitmap.Create;
  try
    MyRect := Rect(0, 0, Structure.Width, Structure.Height);

    Bitmap.Width  := MyRect.Right;
    Bitmap.Height := MyRect.Bottom;
    Bitmap.Canvas.CopyRect(MyRect, Structure.Canvas, MyRect);

    Image.Assign(Bitmap);
    Image.SaveToClipboardFormat(MyFormat, AData, APalette);
    ClipBoard.SetAsHandle(MyFormat,AData);
  finally
    FreeAndNil(Bitmap);
    FreeAndNil(Image);
  end;
end;

procedure TfrmMain.RecoverProjectTree(const ActiveID: Integer);
var
  Node, First: PVirtualNode;
  Data: PProjectData;
begin
  Project.LinkedData := nil;
  // восстанавливаем дерево проектов
  Project.Version := FProjectVersion;
  Project.LoadFromFile(FProjectDir + PROJECT_FILE_NAME);

  Project.Rescale;
  Project.Repaint;

  FModelsRoot := Project.GetFirst;
  FDataRoot := Project.GetNextSibling(FModelsRoot);

  // для каждой модели нужно создать series
  FChartMgr.ClearAll;
  Project.ActiveModel := nil;
  First := nil;
  FLastModel := nil;

  Node := Project.GetFirstChild(Project.GetFirst);
  while Node <> FDataRoot do
  begin
    Data := Project.GetNodeData(Node);
    if Data.RowType = prItem then
    begin
      if First = nil then
        First := Node;

      if ActiveID = Data.ID then
      begin
        Project.ActiveModel := Data;
        LastNode := Node;
        FLastModel := Node;
        LastData := Data;
      end;
      FChartMgr.AddSeries(Data);

      if Data.ID > FLastID then
        FLastID := Data.ID;
    end;
    Node := Project.GetNext(Node);
  end;

  if Project.ActiveModel = nil then
  begin
    LastNode := First;
    Project.ActiveModel := Project.GetNodeData(First);
  end;

  inc(FLastID);

  if Project.ActiveModel = nil then
  begin
    Project.FocusedNode := First;
    Project.Selected[First] := True;
  end
  else
  begin
    Project.FocusedNode := LastNode;
    Project.Selected[LastNode] := True;
  end;

  Structure.FromString(Project.ActiveModel.Data);
  Structure.PeriodicMode := FCalcSettings.FittingMode = fmPeriodic;
end;

procedure TfrmMain.ResultCopyExecute(Sender: TObject);
begin
  SeriesToClipboard(ActiveModelSeries, FCalcSettings.CalcMode);
end;

procedure TfrmMain.ResultSaveExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
    SeriesToFile(ActiveModelSeries, dlgSaveResult.FileName);
end;

procedure TfrmMain.RecoverDataCurves(const LinkedID: integer);
var
  Node: PVirtualNode;
  Data: PProjectData;
  s: string;
begin
  Project.ActiveData := nil;

  Node := Project.GetFirstChild(FDataRoot);
  while Node <> nil do
  begin
    Data := Project.GetNodeData(Node);
    if (Data.RowType = prItem) and FileExists(DataName(Data)) then
    begin
      if Project.ActiveData = nil then
        Project.ActiveData := Data;

      if Data.ID = LinkedID then
        Project.LinkedData := Data;

      FChartMgr.AddSeries(Data);
      SeriesFromFile(FChartMgr.Series[Data.CurveID], DataName(Data), s);
      FChartMgr.Series[Data.CurveID].Visible := Data.Visible;
    end
    else
      Project.DeleteNode(Node);
    Node := Project.GetNext(Node);
  end;
end;

procedure TfrmMain.RescaleChart;
var
  AMin, AMax: Single;
begin
  FCalcSettings.GetAxisRange(AMin, AMax);
  FChartMgr.RescaleAxis(AMin, AMax, FChartInfo.MinLimit);
end;

procedure TfrmMain.LayerAddExecute(Sender: TObject);
var
  Data: TLayerData;
begin
  if Structure.SelectedStack = -1 then
  begin
    ShowMessage('Stack is not selected!');
    Exit;
  end;

  SaveHistory;

  Data.Material := 'Si';

  Data.P[1].New(25);
  Data.P[2].New(3);
  Data.P[3].New(0);

  edtrLayer.SetData(False, Data);
  if edtrLayer.ShowModal = mrOk then
    Structure.AddLayer(Structure.SelectedStack, edtrLayer.GetData);
  MatchToStructure;
end;

procedure TfrmMain.LayerCutExecute(Sender: TObject);
begin
  SaveHistory;

  Structure.CopyLayer(False);
  Structure.DeleteLayer;
  MatchToStructure;
end;

procedure TfrmMain.LayerDeleteExecute(Sender: TObject);
begin
  SaveHistory;

  Structure.DeleteLayer;
  MatchToStructure;
end;

procedure TfrmMain.LayerInsertExecute(Sender: TObject);
var
  Data: TLayerData;
begin
  if Structure.SelectedLayer = -1 then
  begin
    ShowMessage('Parent layer is not selected!');
    Exit;
  end;

  SaveHistory;

  Data.Material := 'Si';

  Data.P[1].New(25);
  Data.P[2].New(3);
  Data.P[3].New(0);

  edtrLayer.SetData(False, Data);
  if edtrLayer.ShowModal = mrOk then
        Structure.InsertLayer(edtrLayer.GetData);
  MatchToStructure;
end;

procedure TfrmMain.LayerPasteExecute(Sender: TObject);
begin
  SaveHistory;

  Structure.PasteLayer;
  MatchToStructure;
end;

procedure TfrmMain.LoadProject(const FileName: string);
var
  LinkedID, ActiveID: System.Integer;
begin
  FIgnoreFocusChange := True;
  PM.ClearProfiles;
  ExtractProject(FileName);
  LoadProjectParams(LinkedID, ActiveID);
  RecoverProjectTree(ActiveID);
  RecoverDataCurves(LinkedID);
  FIgnoreFocusChange := False;
  Caption := 'X-Ray Calc 3: ' + ExtractFileName(FileName);
  MatchToStructure;
  RescaleChart;
end;

procedure TfrmMain.FileCopyPlotBMPExecute(Sender: TObject);
begin
  Chart.CopyToClipboardBitmap;
end;

procedure TfrmMain.FileNewExecute(Sender: TObject);
begin
  Structure.Clear;
  PM.ClearProfiles;
  CreateDefaultProject;
end;

procedure TfrmMain.FileOpenExecute(Sender: TObject);
begin
  if TConfig.SystemDir[sdProjDir] <> '' then
    dlgOpenProject.InitialDir := TConfig.SystemDir[sdProjDir]
  else
    dlgOpenProject.InitialDir := '';

  if dlgOpenProject.Execute then
  begin
    PrepareProjectFolder(dlgOpenProject.FileName, True);
    LoadProject(dlgOpenProject.FileName);
    if TConfig.Section<TOtherOptions>.AutoCalc then
      CalcRunExecute(frmMain);

    FRecentProjects.Add(FProjectFileName);
  end;
end;


procedure TfrmMain.OnRecentProjectClick(Sender: TObject; const FileName: string);
begin
  FProjectFileName := FileName;
  PrepareProjectFolder(FProjectFileName, True);
  LoadProject(FProjectFileName);
  if TConfig.Section<TOtherOptions>.AutoCalc then
    CalcRunExecute(frmMain);
end;

procedure TfrmMain.FilePlotCopyWMFExecute(Sender: TObject);
begin
  Chart.CopyToClipboardMetafile(True);
end;

procedure TfrmMain.FilePlotToFileExecute(Sender: TObject);
begin
  if dlgExport.Execute then
    Case dlgExport.FilterIndex of
      1:
        Chart.SaveToBitmapFile(dlgExport.FileName + '.bmp');
      2:
        Chart.SaveToMetafileEnh(dlgExport.FileName + '.emf');
      3:
        Chart.SaveToMetafile(dlgExport.FileName + '.wmf');
    end;
end;

procedure TfrmMain.FilePrintExecute(Sender: TObject);
begin
  if dlgPrint.Execute then
  begin
    Chart.Title.Visible := True;
    Chart.PrintLandscape;
    Chart.Title.Visible := False;
  end;
end;


function TfrmMain.SaveProjectINI(const IniFileName: string):boolean;
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

    if Project.LinkedData <> nil then
      INF.WriteInteger('STATE', 'LinkedData', Project.LinkedData.ID);
    if Project.ActiveModel <> nil then
    begin
      INF.WriteInteger('STATE', 'ActiveModel', Project.ActiveModel.ID);
      Project.ActiveModel.Data := Structure.ToString;
    end;

    INF.WriteBool('STATE', 'LogScale', Chart.LeftAxis.Logarithmic);

    FCalcSettings.SaveAdvancedParams(INF, FFitParams);
    INF.UpdateFile;
    Result := True;
  finally
    INF.Free;
  end;
end;

procedure TfrmMain.SaveProject(const FileName: string);

begin
  if SaveProjectINI(FProjectDir + PARAMETERS_FILE_NAME) then
  begin
    Project.SaveToFile(FProjectDir + PROJECT_FILE_NAME);

    SeriesToFile(ActiveModelSeries, FProjectDir + 'calc.dat' );

    if FileExists(FileName) then
      DeleteFile(FileName);         // must be here!

    Zip.ArchiveType := atZip;
    Zip.AutoSave := True;
    Zip.ForceType := True;
    Zip.OpenArchive(FileName);
    Zip.BaseDirectory  := FProjectDir;

    Zip.AddFiles('*.*', faAnyFile and faDirectory);
    Zip.CloseArchive;
  end;
end;

procedure TfrmMain.SaveData;
var
  Data: PProjectData;
  Node: PVirtualNode;
begin
  Node := Project.GetFirstChild(Project.GetFirst);
  while Node <> Nil do
  begin
    Data := Project.GetNodeData(Node);
    if (Data.RowType = prItem) and (Data.Group =  gtData) then
    begin
      SeriesToFile(FChartMgr.Series[Data.CurveID], DataName(Data));
    end;
    Node := Project.GetNext(Node);
  end;
end;

procedure TfrmMain.FileSaveAsExecute(Sender: TObject);
begin
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
    Caption := 'X-Ray Calc 3: ' + FProjectName;
  end;
end;

procedure TfrmMain.FileSaveExecute(Sender: TObject);
begin
  if FProjectName = DEFAULT_PROJECT_NAME then
    FileSaveAsExecute(Sender)
  else
    SaveProject(FProjectFileName);
end;

procedure TfrmMain.ChartMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    Screen.Cursor := crSizeAll;
end;

procedure TfrmMain.ChartMouseMove(Sender: TObject; Shift: TShiftState; X,
  Y: Integer);
var
  xv, yv: single;
  R: TRect;
begin
  if Project.ActiveModel = nil then
    Exit;

  xv := ActiveModelSeries.XScreenToValue(X);
  yv := ActiveModelSeries.YScreenToValue(Y);
  FChartInfo.SetCursorPos(xv, yv);

  R := Chart.Legend.RectLegend;

  if (X > R.Left) and (X < R.Right) and (Y > R.Top) and (Y < R.Bottom) then
    Chart.Cursor := crArrow
  else
    Chart.Cursor := crCross;
end;

procedure TfrmMain.ChartMouseUp(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if Button = mbRight then
    Screen.Cursor := crDefault;
end;

procedure TfrmMain.ChartResize(Sender: TObject);
begin
  btnStop.Left := Chart.ClientWidth div 2 - 40;
end;

procedure TfrmMain.ChartZoom(Sender: TObject);
begin
  FChartInfo.SetPeakInfo(ActiveModelSeries, Chart.BottomAxis.Minimum, Chart.BottomAxis.Maximum);
end;

procedure TfrmMain.CreateDefaultProject;
var
  PD: PProjectData;
  PG: PVirtualNode;
begin
  FChartMgr.ClearAll;
  Project.Clear;
  Structure.AddSubstrate('Si', 5, 2.2);

  FLastID := 1;
  FProjectName := DEFAULT_PROJECT_NAME;
  FProjectDir := IncludeTrailingPathDelimiter(Config.TempPath + CreateClassID);
  FProjectFileName := FProjectName;
  CreateDir(FProjectDir);

  // дефолтный проект
  PG := Project.AddChild(Nil, Nil);
  PD := Project.GetNodeData(PG);
  PD.Title := 'Models';
  PD.Group := gtModel;
  PD.RowType := prGroup;

  FModelsRoot := PG;

  // добавляем модель
  CreateNewModel(FModelsRoot);
  Project.Expanded[PG] := True;

  // данные
  PG := Project.AddChild(Nil, Nil);
  PD := Project.GetNodeData(PG);
  PD.Title := 'Data';
  PD.Group := gtData;
  PD.RowType := prGroup;
  Project.Expanded[PG] := True;

  FDataRoot := PG;
  Caption := 'X-Ray Calc 3: ' + FProjectName;
  Project.LinkedData := nil;

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
  FFitParams.SmoothWindow := -1;
  FFitParams.Ksxr         := 0.2;
  FFitParams.PolyFactor   := 10;

  Project.Rescale;
end;

procedure TfrmMain.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  FDPI := NewDPI;
  if Project.TargetDPI <> NewDPI then
  begin
    Project.TargetDPI := NewDPI;
    Project.Rescale;
    ScaleInterface;
  end;
  if Structure.TargetDPI <> NewDPI then
  begin
    Structure.TargetDPI := NewDPI;
    if LastData <> nil then
    begin
      LastData.Data :=Structure.ToString;
      Structure.FromString(LastData.Data);
    end;
  end;

end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('Exit X-Ray Calc 3?', mtConfirmation, [mbYes, mbNo], 0, mbNO) = mrYes;
end;

procedure TfrmMain.LoadRecentProjectsList;
begin
  FRecentProjects := TRecentProjectsManager.Create(MAX_RECENT_CAPACITY, miRecent, pmRecentList);
  FRecentProjects.OnClick := OnRecentProjectClick;
  FRecentProjects.Load;
end;

procedure TfrmMain.CreateTmpLock;
begin
  if FileExists(Config.SystemFileName[sfLock]) then
    FLockOwner := False
  else begin
    AssignFile(FLockFile, Config.SystemFileName[sfLock]);
    Rewrite(FLockFile);
    FLockOwner := True;
  end;
end;

procedure TfrmMain.ReleaseTmpLock;
begin
  if FLockOwner then
  begin
    CloseFile(FLockFile);
    DeleteFile(Config.SystemFileName[sfLock]);
    ClearDir(Config.TempDir);
  end;
end;

procedure TfrmMain.ScaleInterface;
var
  Size : integer;
begin
  FDPI := Screen.PixelsPerInch;
  if FDPI < 150 then
    Size := 10
  else
    Size := 6;

  FChartMgr.ScaleFonts(Size, FDPI);
  FChartPages.ScaleSubChartFonts(Size - 2, FDPI);
end;

procedure TfrmMain.FormCreate(Sender: TObject);
begin
  {$IFDEF  WIN64}
     pnlX64.Visible := True;
  {$ELSE}
     pnlX64.Visible := False;
  {$ENDIF}


  FormatSettings.DecimalSeparator := '.';
  FChartMgr := TChartManager.Create(Chart, 2);
  ScaleInterface;
  Config := TConfig.Create;
  FChartMgr.LineWidth := Config.Section<TGraphOptions>.LineWidth;
  CreateProjectTree;

  FCalcSettings.OnCalcModeChange := OnCalcModeChange;
  FCalcSettings.OnFittingModeChange := OnFittingModeChange;
  FCalcSettings.OnAdvancedSettings := OnAdvancedSettings;

  FChartInfo.OnScaleToggle := OnChartScaleToggle;
  FChartInfo.OnMinLimitChange := OnChartMinLimitChange;

  PM := TProfileManager.Create;
  PM.DensityProfile := FChartPages.ProfileSeries;

  FStructurePanel.ConnectActions(vilModel,
    PeriodAdd, PeriodInsert, PeriodDelete,
    LayerAdd, LayerInsert, actLayerCopy, LayerCut, LayerPaste, LayerDelete);
  FStructurePanel.OnIncrementChange := OnIncrementChange;
  FStructurePanel.OnSetFitLimits := OnSetFitLimits;

  Structure := TXRCStructure.Create(FStructurePanel, FDPI);
  Structure.Parent := FStructurePanel;

  FOperationsStack := TStack<String>.Create;
  FOperationsStack.Capacity := 10;

  LoadRecentProjectsList;

  Project.NodeDataSize := SizeOf(TProjectData);

  CreateDir(Config.TempDir);
  CreateTmpLock;
  FChartPages.ResetToFirstPage;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  Project.Clear;
  ReleaseTmpLock;
  FreeAndNil(Project);
  FreeAndNil(Structure);
  FreeAndNil(FOperationsStack);
  FreeAndNil(FRecentProjects);
  FreeAndNil(FChartMgr);
  FreeAndNil(Config);
end;


procedure TfrmMain.OnCalcModeChange(Sender: TObject);
begin
  case FCalcSettings.CalcMode of
    0: Chart.BottomAxis.Title.Caption := 'Incidence angle (deg)';
    1: Chart.BottomAxis.Title.Caption := 'Wavelength (Å)';
  end;
end;

procedure TfrmMain.OnFittingModeChange(Sender: TObject);
begin
  Structure.PeriodicMode := FCalcSettings.FittingMode = fmPeriodic;
end;

procedure TfrmMain.OnIncrementChange(Sender: TObject);
begin
  Structure.Increment := FStructurePanel.IncrementValue;
end;

procedure TfrmMain.FormShow(Sender: TObject);
var
  Value: string;
begin
  if ParamCount <> 0 then
  begin
     if FindCmdLineSwitch('f', Value, True, [clstValueNextParam]) then
      begin
        if FileExists(Value) then
        begin
          FProjectFileName := Value;
           PrepareProjectFolder(FProjectFileName, True);
          LoadProject(FProjectFileName);
          if FindCmdLineSwitch('a') or TConfig.Section<TOtherOptions>.AutoCalc then
            CalcRunExecute(frmMain);
        end
        else
          CreateDefaultProject;
     end;
  end
  else
    CreateDefaultProject;
end;


procedure TfrmMain.WMLayerClick(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.SelectLayer(LayerID, ID);
end;

procedure TfrmMain.WMLayerDoubleClick(var Msg: TMessage);
var
  StackID, LayerID: Integer;
  ifSubstrate : boolean;

begin
  LayerID := Msg.LParam;
  StackID := Msg.WParam;
  ifSubstrate := (LayerID = 65535) and (StackID = 65535);
  if IfSubstrate then
        edtrLayer.SetData(True, Structure.SubstrateData)
  else
    edtrLayer.SetData(False, Structure.Stacks[StackID].Layers[LayerID].Data);

  if edtrLayer.ShowModal = mrOk then
  begin
    if IfSubstrate then
      Structure.SubstrateData := edtrLayer.GetData
    else
      Structure.LayerData := edtrLayer.GetData;
  end;
end;

procedure TfrmMain.WMLayerEditNext(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.EditNextLayer(LayerID, ID, True);
end;

procedure TfrmMain.WMLayerEditPrev(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.EditNextLayer(LayerID, ID, False);
end;

procedure TfrmMain.WMLinkedClick(var Msg: TMessage);
var
  ID, LayerID: Integer;
begin
  LayerID := Msg.WParam;
  ID := Msg.LParam;
  Structure.LinkLayer(LayerID, ID);
end;

procedure TfrmMain.WMStackClick(var Msg: TMessage);
var
  ID: Integer;
begin
  ID := Msg.WParam;
  Structure.Select(ID);
end;

end.
