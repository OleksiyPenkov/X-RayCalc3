unit frm_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  System.Generics.Collections,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzSplit, Vcl.ExtCtrls, RzPanel,
  Vcl.Menus, RzTabs, Vcl.ToolWin, Vcl.ComCtrls, RzButton, VirtualTrees,
  Vcl.StdCtrls, RzEdit, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, RzCmboBx, RzStatus, VCLTee.Series, RzRadChk, System.ImageList,
  Vcl.ImgList, System.Actions, Vcl.ActnList,
  Vcl.ActnMan, AbUnzper, AbBase, AbBrowse, AbZBrows, AbZipper, unit_Types,
  unit_SMessages,
  unit_calc, unit_XRCProjectTree, RzRadGrp, unit_materials, VCLTee.TeeFunci, unit_LFPSO_Base, unit_LFPSO_Periodic, Vcl.Buttons,
  unit_LFPSO_Irregular, Vcl.Imaging.pngimage, frm_Benchmark,
  Vcl.PlatformDefaultStyleActnCtrls, unit_ProfilesManager;

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
    ilProject: TImageList;
    Project1: TMenuItem;
    Project2: TMenuItem;
    Calc1: TMenuItem;
    Calc2: TMenuItem;
    About1: TMenuItem;
    Calc3: TMenuItem;
    Calcall1: TMenuItem;
    miRecent: TMenuItem;
    dlgOpenProject: TOpenDialog;
    Zip: TAbZipper;
    UnZip: TAbUnZipper;
    pnlMain: TRzPanel;
    Pages: TRzPageControl;
    tsThickness: TRzTabSheet;
    tsRoughness: TRzTabSheet;
    tsDensity: TRzTabSheet;
    Chart: TChart;
    RzPanel3: TRzPanel;
    RzStatusPane1: TRzStatusPane;
    RzStatusPane2: TRzStatusPane;
    StatusY: TRzStatusPane;
    StatusX: TRzStatusPane;
    RzStatusPane3: TRzStatusPane;
    RzStatusPane4: TRzStatusPane;
    StatusMaxX: TRzStatusPane;
    StatusRMax: TRzStatusPane;
    RzStatusPane5: TRzStatusPane;
    StatusD: TRzStatusPane;
    RzStatusPane6: TRzStatusPane;
    StatusRi: TRzStatusPane;
    spChiSqr: TRzStatusPane;
    btnChartScale: TRzBitBtn;
    cbMinLimit: TRzComboBox;
    StructurePanel: TRzPanel;
    tlbStructure: TRzToolbar;
    btnPeriodAdd: TRzToolButton;
    btnPeriodInsert: TRzToolButton;
    btnPeriodDelete: TRzToolButton;
    rzspcr1: TRzSpacer;
    btnLayerAdd: TRzToolButton;
    btnLayerInsert: TRzToolButton;
    btnLayerPaste: TRzToolButton;
    btnLayerDelete: TRzToolButton;
    btnLayerCut: TRzToolButton;
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
    chRoughness: TChart;
    chDensity: TChart;
    chThickness: TChart;
    RzStatusPane7: TRzStatusPane;
    tsFittingProgress: TRzTabSheet;
    chFittingProgress: TChart;
    lsrConvergence: TLineSeries;
    spnFitTime: TRzStatusPane;
    pnlSettings: TPanel;
    RzPanel2: TRzPanel;
    Label6: TLabel;
    cbIncrement: TRzComboBox;
    RzPanel6: TRzPanel;
    RzPanel7: TRzPanel;
    rgPolarisation: TRzRadioGroup;
    pnlWaveParams: TRzPanel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    edStartL: TEdit;
    edEndL: TEdit;
    edTheta: TEdit;
    edDL: TEdit;
    pnlAngleParams: TRzPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edStartTeta: TEdit;
    edEndTeta: TEdit;
    edWidth: TEdit;
    edLambda: TEdit;
    cb2Theta: TRzCheckBox;
    rgCalcMode: TRzRadioGroup;
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
    btnSetFitLimits: TBitBtn;
    spChiBest: TRzStatusPane;
    dlgPrint: TPrintDialog;
    RzSpacer3: TRzSpacer;
    BtnFastForward: TRzToolButton;
    btnCopyLayer: TRzToolButton;
    actLayerCopy: TAction;
    actProjectItemDuplicate: TAction;
    tlbrProject: TRzToolbar;
    ilStructure: TImageList;
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
    RzGroupBox2: TRzGroupBox;
    edN: TEdit;
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
    btnCopyConvergence: TRzButton;
    actCopyStructureBitmap: TAction;
    Copyasimage1: TMenuItem;
    btnStop: TRzBitBtn;
    ilIcons: TImageList;
    actDataTrim: TAction;
    rim1: TMenuItem;
    actCalcFitJobs: TAction;
    Calcbatchjobs1: TMenuItem;
    pmRecentList: TPopupMenu;
    pmRecentList1: TMenuItem;
    rgFittingMode: TRzRadioGroup;
    edFIter: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    edFPopulation: TEdit;
    cbLFPSOShake: TRzCheckBox;
    cbSeedRange: TRzCheckBox;
    edPolyOrder: TEdit;
    lblPolyOrder: TLabel;
    Label21: TLabel;
    cbTWChi: TComboBox;
    cbPWChiSqr: TRzCheckBox;
    btnAdvFitSettings: TRzBitBtn;
    cbSmooth: TRzCheckBox;
    pnlX64: TRzStatusPane;
    tsProfile: TRzTabSheet;
    chProfile: TChart;
    DensityProfile: TLineSeries;
    procedure btnChartScaleClick(Sender: TObject);
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
    procedure cbIncrementChange(Sender: TObject);
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
    procedure ActionManagerChange(Sender: TObject);
    procedure LayerInsertExecute(Sender: TObject);
    procedure LayerDeleteExecute(Sender: TObject);
    procedure LayerCutExecute(Sender: TObject);
    procedure LayerPasteExecute(Sender: TObject);
    procedure DataNormExecute(Sender: TObject);
    procedure pmiLinkedClick(Sender: TObject);
    procedure pmiVisibleClick(Sender: TObject);
    procedure pmiEnabledClick(Sender: TObject);
    procedure actAutoFittingExecute(Sender: TObject);
    procedure btnSetFitLimitsClick(Sender: TObject);
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
    procedure CalcAllExecute(Sender: TObject);
    procedure CalcStopExecute(Sender: TObject);
    procedure ChartMouseMove(Sender: TObject; Shift: TShiftState; X,
      Y: Integer);
    procedure ChartMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartMouseUp(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure ChartZoom(Sender: TObject);
    procedure btnCopyConvergenceClick(Sender: TObject);
    procedure DataNormAutoExecute(Sender: TObject);
    procedure actEditHenkeExecute(Sender: TObject);
    procedure rgCalcModeChanging(Sender: TObject; NewIndex: Integer;
      var AllowChange: Boolean);
    procedure actProjecEditModelTextExecute(Sender: TObject);
    procedure cbMinLimitChange(Sender: TObject);
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
    procedure rgFittingModeClick(Sender: TObject);
    procedure btnAdvFitSettingsClick(Sender: TObject);
    procedure actRecoverModelExecute(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
      NewDPI: Integer);
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
    IsFolder, IsItem, IsData, IsModel, IsExtension: Boolean;
    StartTime, FitStartTime: TDateTime;
    FFitParams: TFitParams;
    FCalc: TCalc;
    FCalcThreadParams: TCalcThreadParams;
    FFitStructure: TFitStructure;
    FLastChiSquare: Single;
    FABestChiSquare: Single;

    FOperationsStack: TStack<String>;
    FRecentProjects : TList<String>;

    FTerminated: Boolean;
    FBenchmarkMode: Boolean;
    FBenchmarkPath: string;
    FBenchmarkRuns: Integer;
    FLastModelName: String;
    FFirstUpdate: Boolean;
    FSeriesList: TSeriesList ;
    PM: TProfileManager;
    FDPI: Integer;

    procedure CreateProjectTree;
    procedure LoadProject(const FileName: string; Clear: Boolean);
    function DataName(Data: PProjectData): string;
    procedure CreateDefaultProject;
    procedure PrepareProjectFolder(const FileName: string; Clear: Boolean);
    procedure LoadProjectParams(var LinkedID, ActiveID: System.Integer);
    procedure RecoverProjectTree(const ActiveID: Integer);
    procedure RecoverDataCurves(const LinkedID: integer);
    procedure FinalizeCalc(Calc: TCalc);
    procedure GetThreadParams;
    procedure PlotResults(const Data: TDataArray);
    procedure PrintMax;
    procedure SaveProject(const FileName: string);
    procedure SaveData;
    procedure AddCurve(Data: PProjectData);
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
    procedure AddRecentItem(const FileName: string);
    procedure RecentListOnClick(Sender: TObject);
    procedure FillRecentMenu;
    procedure LoadRecentProjectsList;
    function FittingMode: TFittingMode; inline;
    procedure RunCalc(const Recover: boolean);
    procedure UpdateInterface(const FitStructure: TFitStructure;
                              const Poly: TProfileFunctions;
                              const Res: TLayeredModel;
                              const CreateExtension: boolean = True);
    procedure UpdateProfileExtension;
    { Private declarations }
  public
    { Public declarations }
    procedure WMStackClick(var Msg: TMessage); message WM_STR_STACK_CLICK;
    procedure WMLayerClick(var Msg: TMessage); message WM_STR_LAYER_CLICK;
    procedure WMLayerDoubleClick(var Msg: TMessage); message WM_STR_LAYER_DOUBLECLICK;
    procedure WMLayerEditNext(var Msg: TMessage); message WM_STR_EDIT_NEXT;
    procedure WMLayerEditPrev(var Msg: TMessage); message WM_STR_EDIT_PREV;
    procedure WMLinkedClick(var Msg: TMessage); message WM_STR_Linked_CLICK;
    //procedure WMStackDblClick(var Msg: TMessage); message WM_STR_STACKDBLCLICK;
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
  System.IniFiles,
  System.DateUtils,
  System.UITypes,
  AbUtils,
  unit_helpers,
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
  frm_FitSettings;

{$R *.dfm}

procedure TfrmMain.btnAdvFitSettingsClick(Sender: TObject);
begin
  frmFitSettings.ShowSettings(FFitParams);
end;

procedure TfrmMain.btnChartScaleClick(Sender: TObject);
begin
//  if (FSeriesList[Project.ActiveModel.CurveID].Count = 0) and (Project.ActiveData = nil) then
//    Exit;

  if Chart.LeftAxis.Logarithmic then
  begin
    Chart.LeftAxis.Logarithmic := False;
    btnChartScale.Caption := 'Log';
    if Chart.LeftAxis.Maximum > 0.01 then
      Chart.LeftAxis.AxisValuesFormat := '0.000'
    else
      Chart.LeftAxis.AxisValuesFormat := '0x10E-0';
  end
  else
  begin
    btnChartScale.Caption := 'Linear';
//    Chart.LeftAxis.Minimum := StrToFloat(Settings.MinLimit);
    Chart.LeftAxis.Logarithmic := True;
    Chart.LeftAxis.AxisValuesFormat := '0x10E-0';
  end;
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

  AddCurve(Project.ActiveModel);
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
  lsrConvergence.AddXY(msg_prm.Step, msg_prm.BestChi);
//  if chFittingProgress.LeftAxis.Maximum < msg_prm.BestChi then
//    chFittingProgress.LeftAxis.Maximum := 1.1 * msg_prm.BestChi;


  spChiSqr.Caption := FloatToStrF(msg_prm.LastChi, ffFixed, 8, 4);
  spChiBest.Caption := FloatToStrF(msg_prm.BestChi, ffFixed, 8, 4);

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
    PlotResults(msg_prm.Curve);
    if TConfig.Section<TOtherOptions>.LiveUpdate then
    begin
      UpdateInterface(msg_prm.Structure, msg_prm.Poly, msg_prm.LayeredModel, FFirstUpdate);
      FFirstUpdate := False;
      if NeedsSaving then
           AutoSave;
    end;
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
  PM.PlotProfile(IsProfileEnbled and (FittingMode <> fmPeriodic));
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
  if LastData <> nil then
  begin
    IsModel := (LastData.Group = gtModel) and IsItem;
    if IsModel then
    begin
      LastData.Data := Structure.ToString;
      FLastModelName := LastData.Title;
    end;
  end;

  LastNode := Project.GetFirstSelected;
  LastData := Project.GetNodeData(LastNode);

  if LastData = nil then
  begin
    IsItem := False;
    IsData := False;
    IsModel := False;
    IsFolder := False;
    IsExtension := False;
    Exit;
  end;

  IsItem := LastData.RowType = prItem;
  IsExtension := LastData.RowType = prExtension;
  IsFolder := LastData.RowType = prFolder;
  IsData := LastData.Group = gtData;
  IsModel := (LastData.Group = gtModel) and IsItem;


  if IsItem and IsData then
    Project.ActiveData := LastData;

  if IsModel then
  begin
     FLastModel := LastNode;
     if LastData.Data <> '' then
     begin
       Structure.FromString(LastData.Data);
       FOperationsStack.Clear;
       FOperationsStack.Push(LastData.Data);
       PM.Prepare(Structure, chThickness, chRoughness, chDensity);
       PM.PlotProfile(IsProfileEnbled and (FittingMode <> fmPeriodic));
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
    SeriesToClipboard(FSeriesList[Data.CurveID]);
end;

procedure TfrmMain.DeleteModel(Node: PVirtualNode; Data: PProjectData);
begin
  FSeriesList[Data.CurveID].Free;
  Project.DeleteNode(Node);
  Project.Repaint;
  Project.ActiveModel := nil;
end;

procedure TfrmMain.DeleteData(Node: PVirtualNode; Data: PProjectData);
begin
  DeleteFile(DataName(Data));
  FSeriesList[Data.CurveID].Free;
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

procedure TfrmMain.UpdateProfileExtension;
begin
  //
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
const
  L : array [0..2] of string = ('H','S','rho');
var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i: Integer;
  Title: string;
  Found: Boolean;
begin
  for I := 0 to High(P) do
  begin
    Title := Format('F(%s %s/%s)', [L[Ord(P[i].Subj)],
                 Structure.Stacks[P[i].StackID].Title,
                 Structure.Stacks[P[i].StackID].Layers[P[i].LayerID].Data.Material]);

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
const
  L : array [0..2] of string = ('H','S','rho');

var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i: Integer;
  S: string;
begin
  for I := 0 to High(P) do
  begin
    Gradient := Project.AddChild(FLastModel);
    Data := Project.GetNodeData(Gradient);

    Data.Group := gtModel;
    Data.Enabled := True;
    Data.RowType := prExtension;
    S := Format('F(%s %s/%s)', [L[Ord(P[i].Subj)],
                 Structure.Stacks[P[i].StackID].Title,
                 Structure.Stacks[P[i].StackID].Layers[P[i].LayerID].Data.Material]);

    Data.Title := S;
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
          FSeriesList[Data.CurveID].Color := Data.Color;
          FSeriesList[Data.CurveID].Title := Data.Title;
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
  SeriesToClipboard(FSeriesList[Project.ActiveData.CurveID]);
end;

procedure TfrmMain.DataExportExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
      SeriesToFile(FSeriesList[Project.ActiveModel.CurveID], dlgSaveResult.FileName);
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

  AddCurve(Data);

  SeriesFromFile(FSeriesList[Data.CurveID], dlgLoadData.FileName, Data.Description);
  SeriesToFile(FSeriesList[Data.CurveID], DataName(Data));

  Project.ActiveData := Data;
  Project.Expanded[FDataRoot] := True;

end;

function TfrmMain.DataName(Data: PProjectData): string;
begin
  Result := Format('%sdata_%d.dat', [FProjectDir, Data.ID])
end;

procedure TfrmMain.DataNormAutoExecute(Sender: TObject);
begin
  //
end;

procedure TfrmMain.DataNormExecute(Sender: TObject);
var
  s: string;
begin
  s := InputBox('Data normalization', 'Coefficient', '');
  if s <> '' then
  begin
    Normalize(StrToFloat(s), FSeriesList[Project.ActiveData.CurveID]);
    SeriesToFile(FSeriesList[Project.ActiveData.CurveID], DataName(Project.ActiveData));
  end;
end;

procedure TfrmMain.actDataSmoothExecute(Sender: TObject);
var
  Data: TDataArray;
begin
  Data := SeriesToData(FSeriesList[Project.ActiveData.CurveID]);
  //TSavitzkyGolay.SmoothCurve(Data, 2, 8);
  Data := MovAvg(Data, 5);
  DataToSeries(Data, FSeriesList[Project.ActiveData.CurveID]);
  SeriesToFile(FSeriesList[Project.ActiveData.CurveID], DataName(Project.ActiveData));
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
    for I := 0 to FSeriesList[Project.ActiveData.CurveID].XValues.Count do
      if FSeriesList[Project.ActiveData.CurveID].XValues[i] >= val then
      begin
        Result := i;
        Break;
      end;
  end;

begin
  t1 := StrToFloat(edStartTeta.Text);
  t2 := StrToFloat(edEndTeta.Text);

  index := FindIndex(t1);
  if index > 1 then
  begin
    FSeriesList[Project.ActiveData.CurveID].BeginUpdate;
    FSeriesList[Project.ActiveData.CurveID].Delete(0, Index);
    FSeriesList[Project.ActiveData.CurveID].EndUpdate;
  end;

  index := FindIndex(t2);
  if index > 1 then
  begin
    FSeriesList[Project.ActiveData.CurveID].BeginUpdate;
    FSeriesList[Project.ActiveData.CurveID].Delete(index, FSeriesList[Project.ActiveData.CurveID].XValues.Count - Index - 1);
    FSeriesList[Project.ActiveData.CurveID].EndUpdate;
  end;
  SeriesToFile(FSeriesList[Project.ActiveData.CurveID], DataName(Project.ActiveData));
end;

procedure TfrmMain.actEditHenkeExecute(Sender: TObject);
begin
  edtrHenkeTable.ShowModal;
end;

procedure TfrmMain.ActionManagerChange(Sender: TObject);
begin
  Project.ActiveModel.Data := Structure.ToString;
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
  LoadProject(FProjectFileName, True);
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

procedure TfrmMain.AddCurve(Data: PProjectData);
var
  Count: integer;
begin
  Count := Length(FSeriesList);
  SetLength(FSeriesList, Count + 1);
  FSeriesList[Count] := TLineSeries.Create(Chart);
  FSeriesList[Count].ParentChart := Chart;

  FSeriesList[Count].Title := Data.Title;
  if Data.Color <> 0 then
    FSeriesList[Count].Color := Data.Color
  else
    Data.Color := FSeriesList[Count].Color;

  FSeriesList[Count].LinePen.Width := Config.Section<TGraphOptions>.LineWidth;
  Data.Visible := True;
  FSeriesList[Count].Visible := Data.Visible;
  Data.CurveID := Count;
end;

procedure TfrmMain.AutoSave;
var
  FileName, Path: string;
  p: Integer;
begin
  if TConfig.Section<TOtherOptions>.AutoSave then
  begin
    FileName := FProjectName;
    if TConfig.SystemDir[sdOutDir] <> '' then
      Path := TConfig.SystemDir[sdOutDir]
    else
      Path := ExtractFilePath(FileName);

    p := pos(PROJECT_EXT, FileName);
    Delete(FileName, p, Length(PROJECT_EXT));
    FileName := Path + FileName + '-fitted'+ PROJECT_EXT;
    SaveProject(FileName);
  end;
end;

procedure TfrmMain.btnSetFitLimitsClick(Sender: TObject);
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

  Data.ID := DateTimeToUnix(Now);
  Data.Title := 'Data ' + IntToStr(Node.Index + 1) + '.dat';
  Data.Group := gtData;
  Data.RowType := prItem;

  AddCurve(Data);
  Project.Expanded[FDataRoot] := True;

  SeriesFromClipboard(FSeriesList[Data.CurveID]);
  SeriesToFile(FSeriesList[Data.CurveID], DataName(Data));
end;

procedure TfrmMain.SaveHistory;
begin
  FOperationsStack.Push(Structure.ToString);
  FOperationsStack.TrimExcess;
end;

procedure TfrmMain.MatchToStructure;
begin
  PM.Prepare(Structure, chThickness, chRoughness, chDensity);
  PM.PlotProfile(IsProfileEnbled and (FittingMode <> fmPeriodic));
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
  FProjectDir := IncludeTrailingPathDelimiter(Config.TempPath + FProjectName);

  if Clear then
  begin
    // удаляем папку старого проекта
    if DirectoryExists(FProjectDir, False) then
      ClearDir(FProjectDir, True);
    //
    CreateDir(FProjectDir);
  end;

  UnZip.BaseDirectory := FProjectDir;
  UnZip.FileName := FileName;
  unZip.OpenArchive(FileName);
  unZip.ExtractFiles('*.*');
  unZip.CloseArchive;
end;


procedure TfrmMain.LoadProjectParams(var LinkedID, ActiveID: System.Integer);
var
  INF: TMemIniFile;
  Periodic, Poly: boolean;
  FitMode: Integer;
begin
  INF := TMemIniFile.Create(FProjectDir + PARAMETERS_FILE_NAME);
  try
    edN.Text := INF.ReadString('PARAMS', 'N', '1000');
    rgCalcMode.ItemIndex := INF.ReadInteger('PARAMS', 'Mode', 0);
    rgPolarisation.ItemIndex := INF.ReadInteger('PARAMS', 'Polarisation', 0);
    cbMinLimit.Text := INF.ReadString('PARAMS', 'MinLimit', '1E-7');

    edStartTeta.Text := INF.ReadString('ANGLE', 'Start', '0.01');
    edEndTeta.Text := INF.ReadString('ANGLE', 'End', '5');
    edLambda.Text := INF.ReadString('ANGLE', 'lambbda', '1.54043');
    edWidth.Text := INF.ReadString('ANGLE', 'width', '0.015');
    cb2Theta.Checked := INF.ReadBool('ANGLE', '2teta', True);

    edStartL.Text := INF.ReadString('WAVE', 'Start', '1');
    edEndL.Text := INF.ReadString('WAVE', 'End', '10');
    edTheta.Text := INF.ReadString('WAVE', 'Teta', '85');
    edDL.Text := INF.ReadString('WAVE', 'width', '0');

    LinkedID := INF.ReadInteger('STATE', 'LinkedData', -1);
    ActiveID := INF.ReadInteger('STATE', 'ActiveModel', -1);
    FProjectVersion := INF.ReadInteger('INFO', 'Version', 0);

    edFIter.Text            := INF.ReadString('FIT', 'Namx', '100');
    edFPopulation.Text      := INF.ReadString('FIT', 'Pop', '100');

    FitMode := INF.ReadInteger('FIT', 'Mode', -1);
    if FitMode = -1 then
    begin
      Periodic := INF.ReadBool('FIT', 'Periodic', False);
      Poly     := INF.ReadBool('FIT', 'Poly', False);

      if Periodic then rgFittingMode.ItemIndex := Ord(fmPeriodic);
      if Poly then rgFittingMode.ItemIndex := Ord(fmPoly);
    end
    else
      rgFittingMode.ItemIndex := FitMode;

    edPolyOrder.Text        := INF.ReadString('FIT', 'PolyOrder', '1');
    cbPWChiSqr.Checked  := INF.ReadBool('FIT', 'PWChi', True);
    cbTWChi.ItemIndex   := INF.ReadInteger('FIT', 'TWChi', 0);
    cbSeedRange.Checked  := INF.ReadBool('LFPSO', 'SeedRange', False);
    cbLFPSOShake.Checked    := INF.ReadBool('LFPSO', 'Shake', True);
    cbSmooth.Checked        := INF.ReadBool('LFPSO', 'Smooth', False);

    FFitParams.Tolerance := StrToFloat(INF.ReadString('FIT', 'Tol', '0.005'));
    FFitParams.MovAvgWindow := StrToFloat(INF.ReadString('FIT', 'Window', '0.05'));
    FFitParams.Vmax         := StrToFloat(INF.ReadString('LFPSO', 'Vmax', '0.1'));
    FFitParams.JammingMax   := StrToInt(INF.ReadString('LFPSO', 'Jmax', '1'));
    FFitParams.ReInitMax    := StrToInt(INF.ReadString('LFPSO', 'RIMax', '3'));
    FFitParams.KChiSqr      := StrToFloat(INF.ReadString('LFPSO', 'kChi', '1.41'));
    FFitParams.KVmax        := StrToFloat(INF.ReadString('LFPSO', 'kVmax', '1.41'));
    FFitParams.w1           := StrToFloat(INF.ReadString('LFPSO', 'w1', '0.3'));
    FFitParams.w2           := StrToFloat(INF.ReadString('LFPSO', 'w2', '0.3'));
    FFitParams.AdaptVel     := INF.ReadBool('LFPSO', 'AdaptV', False);
    FFitParams.SmoothWindow := INF.ReadInteger('LFPSO', 'SmoothWindow', -1);
    FFitParams.Ksxr         := StrToFloat(INF.ReadString('LFPSO', 'Ksxr', '0.2'));
    FFitParams.PolyFactor   := INF.ReadInteger('LFPSO', 'PolyFactor', 10);
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

  FFitParams.NMax := StrToInt(edFIter.Text);
  FFitParams.Pop  := StrToInt(edFPopulation.Text);
  FFitParams.Shake       := cbLFPSOShake.Checked;
  FFitParams.ThetaWeight := cbTWChi.ItemIndex;

  FFitParams.RangeSeed   := cbSeedRange.Checked;
  FFitParams.MaxPOrder   := StrToInt(edPolyOrder.Text);
  FFitParams.Smooth       := cbSmooth.Checked;

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
var
  StartT, EndT: single;
begin
  StartTime := Now;


  FSeriesList[Project.ActiveModel.CurveID].BeginUpdate;

  StartT := StrToFloat(edStartTeta.Text);
  EndT := StrToFloat(edEndTeta.Text);

  if cb2Theta.Checked then
    FCalcThreadParams.k := 2
  else
    FCalcThreadParams.k := 1;

  if rgPolarisation.ItemIndex = 0 then
    FCalcThreadParams.P := cmS
  else
    FCalcThreadParams.P := cmSP;

  case rgCalcMode.ItemIndex of
    0:begin
        FCalcThreadParams.Mode := cmTheta;
        FCalcThreadParams.Lambda := StrToFloat(edLambda.Text);
        FCalcThreadParams.StartT := StartT;
        FCalcThreadParams.EndT   := EndT;
        FCalcThreadParams.DT     := StrToFloat(edWidth.Text);
      end;

    1:
      begin
        FCalcThreadParams.Mode := cmLambda;
        FCalcThreadParams.Theta := StrToFloat(edTheta.Text);
        FCalcThreadParams.StartL := StrToFloat(edStartL.Text);
        FCalcThreadParams.EndL := StrToFloat(edEndL.Text);
        FCalcThreadParams.DW := StrToFloat(edDL.Text);
      end;
  end;

  FCalcThreadParams.RF := rfError;
  FCalcThreadParams.N := StrToInt(edN.Text);
 end;

procedure TfrmMain.HelpAboutExecute(Sender: TObject);
begin
  frmAbout.ShowModal;
end;

procedure TfrmMain.PrintMax;
var
  X, Y, mx, x1, x2, my, RI, OldX: single;
  i: Integer;
begin
  if FSeriesList[Project.ActiveModel.CurveID].Count = 0 then
    Exit;

  my := 0;  mx := 0;
  x1 := Chart.BottomAxis.Minimum;
  x2 := Chart.BottomAxis.Maximum;
  RI := 0;
  OldX := FSeriesList[Project.ActiveModel.CurveID].XValue[1];
  for i := 2 to FSeriesList[Project.ActiveModel.CurveID].Count - 2 do
  begin
    X := FSeriesList[Project.ActiveModel.CurveID].XValue[i];
    Y := FSeriesList[Project.ActiveModel.CurveID].YValue[i];
    if (X > x1) and (X < x2) and (Y > my) then
    begin
      RI := RI + Y * abs(OldX - X);
      my := Y;
      mx := X;
    end;
    OldX := X;
  end;

  if my < 0.01 then
    StatusRMax.Caption := FloatToStrF(my, ffExponent, 3, 2)
  else
    StatusRMax.Caption := FloatToStrF(my, ffFixed, 4, 3);

  StatusMaxX.Caption := FloatToStrF(mx, ffFixed, 5, 4);
  StatusRi.Caption := FloatToStrF(RI, ffFixed, 7, 4);
end;

procedure TfrmMain.PlotResults(const Data: TDataArray);
var
  j: Integer;
begin
  FSeriesList[Project.ActiveModel.CurveID].BeginUpdate;
  FSeriesList[Project.ActiveModel.CurveID].Clear;
  for j := 0 to High(Data) do
      FSeriesList[Project.ActiveModel.CurveID].AddXY(Data[j].t, Data[j].R);
  FSeriesList[Project.ActiveModel.CurveID].EndUpdate;
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
  FSeriesList[LastData.CurveID].Visible := pmiVisible.Checked;
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
  PlotResults(Calc.Results);
  DecodeTime(Now - StartTime, Hour, Min, Sec, MSec);
  spnTime.Caption := Format('Time: %d.%3.3d s.', [60 * Min + Sec, MSec]);
  FSeriesList[Project.ActiveModel.CurveID].EndUpdate;
  FSeriesList[Project.ActiveModel.CurveID].Repaint;
  StatusD.Caption := FloatToStrF(Structure.Period, ffFixed, 7, 2);
  Screen.Cursor := crDefault;
  PrintMax;
end;

function  TfrmMain.FittingMode: TFittingMode;
begin
  Result := TFittingMode(rgFittingMode.ItemIndex);
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
      if (Project.LinkedData <> nil) and FSeriesList[Project.ActiveModel.CurveID].Visible then
      begin
        FCalc.CalcChiSquare(cbTWChi.ItemIndex);
        spChiSqr.Caption := FloatToStrF(FCalc.ChiSQR, ffFixed, 8, 4);
      end
      else begin
        spChiSqr.Caption := '';
        FLastChiSquare := 0;
      end;

      if IsProfileEnbled and (FittingMode <> fmPeriodic) then
         PM.PlotProfileNP
     else
        PM.PlotProfile(IsProfileEnbled and (FittingMode <> fmPeriodic));
    except
      on E: exception do
      begin
        ShowMessage(E.Message);
        FSeriesList[Project.ActiveModel.CurveID].EndUpdate;
        FSeriesList[Project.ActiveModel.CurveID].Repaint;
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
  tlbStructure.Enabled := Enable;
  tlbrProject.Enabled := Enable;
  ChartToolBar.Enabled := Enable;
  btnCopyConvergence.Enabled := Enable;

  btnStop.Visible := not Enable;
  Structure.Enabled := Enable;
  Project.Enabled := Enable;
  pnlSettings.Enabled := Enable;
end;

function TfrmMain.PrepareCalc: Boolean;
begin
  Result :=False;
  if (Project.ActiveModel = nil) then Exit;

  FCalc := TCalc.Create;
  FCalc.Limit := StrToFloat(cbMinLimit.Text);
  if (Project.LinkedData <> nil) and FSeriesList[Project.ActiveModel.CurveID].Visible then
  begin
    FCalc.ExpValues := SeriesToData(FSeriesList[Project.LinkedData.CurveID]);
    if cbPWChiSqr.Checked then
      FCalc.MovAvg := MovAvg(FCalc.ExpValues, FFitParams.MovAvgWindow);
  end;

  GetThreadParams;
  FCalc.Params := FCalcThreadParams;
  FCalc.Model := Structure.Model(IsProfileEnbled and (FittingMode <> fmPeriodic));
  FCalc.Model.Profiles := GetProfileFunctions;
  Screen.Cursor := crHourGlass;
  Result := True;
end;


function TfrmMain.PrepareLFPSO: Boolean;
begin
  Result := False;
  case FittingMode of
    fmIrregular : LFPSO := TLFPSO_Irregular.Create;
    fmPeriodic  : LFPSO := TLFPSO_Periodic.Create;
    fmPoly      : LFPSO := TLFPSO_Poly.Create;
  end;

  GetThreadParams;

  LFPSO.Params := FFitParams;
  LFPSO.Limit := StrToFloat(cbMinLimit.Text);

  if (Project.LinkedData <> nil) and FSeriesList[Project.ActiveModel.CurveID].Visible then
  begin
    LFPSO.ExpValues := SeriesToData(FSeriesList[Project.LinkedData.CurveID]);
    if cbPWChiSqr.Checked then
      LFPSO.MovAvg := MovAvg(LFPSO.ExpValues, FFitParams.MovAvgWindow);
  end else
  begin
     FreeAndNil(LFPSO);
     ShowMessage('Measured curve is not linked!');
     Exit;
  end;

  LFPSO.Structure := FFitStructure;

  lsrConvergence.Clear;
  Pages.ActivePage := tsFittingProgress;
  chFittingProgress.BottomAxis.Minimum := 0;
  chFittingProgress.BottomAxis.Maximum := FFitParams.NMax;

  Result := True;
end;

procedure TfrmMain.acStructureUndoExecute(Sender: TObject);
begin
  if FOperationsStack.Count > 0 then
  begin
    Structure.FromString(FOperationsStack.Peek);
    FOperationsStack.Extract;
  end;
end;


procedure TfrmMain.UpdateInterface;
begin
  if Structure.IsPeriodic then
  begin
    if FittingMode = fmPeriodic then
       Structure.UpdateInterfaceP(FitStructure)
    else begin
      if FittingMode = fmPoly then
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
           CreateProfileExtension
        else
          UpdateProfileExtension;
        Structure.UpdateProfiles(Res);
      end;
    end;
  end
  else
    Structure.UpdateInterfaceNP(FitStructure);
end;

procedure TfrmMain.actAutoFittingExecute(Sender: TObject);
var
  Hour, Min, Sec, MSec: Word;
begin
  if not GetFitParams then Exit;

  try
    if not PrepareLFPSO then Exit;
    Screen.Cursor := crHourGlass;
    EnableControls(False);
    FitStartTime := Now;

    FFirstUpdate := True;

    FABestChiSquare := 1e32;
    LFPSO.Run(FCalcThreadParams);
//    UpdateInterface(LFPSO.Structure, LFPSO.Polynomes, LFPSO.Result, FFirstUpdate);

    Project.ActiveModel.Data  := Structure.ToString;
    DecodeTime(Now - FitStartTime, Hour, Min, Sec, MSec);
    spnFitTime.Caption := Format('Fitting Time: %2.2d:%2.2d:%2.2d sec', [Hour, Min, Sec]);
    CalcRunExecute(nil);
  finally
    Screen.Cursor := crDefault;
    EnableControls(True);
    FreeAndNil(LFPSO);
  end;
  //AutoSave;
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

    with Bitmap do
    begin
      Width  := MyRect.Right;
      Height := MyRect.Bottom;

      Canvas.CopyRect(MyRect, Structure.Canvas, MyRect);
    end;

    Image.Assign(Bitmap);
    Image.SaveToClipboardFormat(MyFormat, AData, APalette);
    ClipBoard.SetAsHandle(MyFormat,AData);
  finally
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

  FModelsRoot := Project.GetFirst;
  FDataRoot := Project.GetNextSibling(FModelsRoot);

  // для каждой модели нужно создать series
  Chart.SeriesList.Clear;
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
      AddCurve(Data);

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
//  if cbTreatPeriodic.Checked then
//        Structure.EnablePairing;
  Structure.PeriodicMode := FittingMode = fmPeriodic;
end;

procedure TfrmMain.ResultCopyExecute(Sender: TObject);
begin
  SeriesToClipboard(FSeriesList[Project.ActiveModel.CurveID]);
end;

procedure TfrmMain.ResultSaveExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
    SeriesToFile(FSeriesList[Project.ActiveModel.CurveID], dlgSaveResult.FileName);
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

      AddCurve(Data);
      SeriesFromFile(FSeriesList[Data.CurveID], DataName(Data), s);
      Chart.AddSeries(FSeriesList[Data.CurveID]);
      FSeriesList[Data.CurveID].Visible := Data.Visible;
    end
    else
      Project.DeleteNode(Node);
    Node := Project.GetNext(Node);
  end;
end;

procedure TfrmMain.RescaleChart;
begin
  Chart.BottomAxis.Minimum := 0;

  case rgCalcMode.ItemIndex of
    0:begin
        Chart.BottomAxis.Maximum := StrToFloat(edEndTeta.Text);
        Chart.BottomAxis.Minimum := StrToFloat(edStartTeta.Text);
      end;
    1:begin
        Chart.BottomAxis.Maximum := StrToFloat(edEndL.Text);
        Chart.BottomAxis.Minimum := StrToFloat(edStartL.Text);
      end;
  end;
  Chart.LeftAxis.Minimum := StrToFloat(cbMinLimit.Text);
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

procedure TfrmMain.LoadProject(const FileName: string; Clear: Boolean);
var
  LinkedID, ActiveID: System.Integer;
begin
  FIgnoreFocusChange := True;
  PrepareProjectFolder(FileName, Clear);
  LoadProjectParams(LinkedID, ActiveID);
  RecoverProjectTree(ActiveID);
  RecoverDataCurves(LinkedID);

  PM.ClearProfiles;
  FIgnoreFocusChange := False;
  Project.Repaint;
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
    dlgOpenProject.InitialDir := TConfig.SystemDir[sdProjDir];

  if dlgOpenProject.Execute then
  begin
    LoadProject(dlgOpenProject.FileName, True);
    if TConfig.Section<TOtherOptions>.AutoCalc then
      CalcRunExecute(frmMain);

    AddRecentItem(FProjectFileName);
  end;
end;


procedure TfrmMain.RecentListOnClick(Sender: TObject);
var
  Index : Integer;
begin
  Index := (Sender as TMenuItem).Tag - 100;
  FProjectFileName := FRecentProjects.List[Index];
  FRecentProjects.Move(Index, 0);
  FillRecentMenu;

  LoadProject(FProjectFileName, True);
  if TConfig.Section<TOtherOptions>.AutoCalc then
        CalcRunExecute(frmMain);
end;


procedure TfrmMain.FillRecentMenu;
var
  i: Integer;
  Item, PopupItem: TMenuItem;
begin
  miRecent.Clear;
  pmRecentList.Items.Clear;
  for I := 0 to FRecentProjects.Count - 1 do
  begin
    Item := TMenuItem.Create(miRecent);
    miRecent.Add(Item);
    Item.Caption := ExtractFileName(FRecentProjects.List[i]);
    Item.Tag := 100 + i;
    Item.OnClick := RecentListOnClick;

    PopupItem := TMenuItem.Create(pmRecentList);
    pmRecentList.Items.Add(PopupItem);
    PopupItem.Caption := Item.Caption;
    PopupItem.Tag := Item.Tag;
    PopupItem.OnClick := RecentListOnClick;
  end;
end;


procedure TfrmMain.AddRecentItem(const FileName: string);
begin
    FRecentProjects.Insert(0, FileName);
    if FRecentProjects.Count > MAX_RECENT_CAPACITY then
          FRecentProjects.Delete(FRecentProjects.Count - 1);

    TConfig.WiteStringList('Recent', FRecentProjects.List);
    FillRecentMenu;
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
//    Chart.Title.Text.Text := Structure.ToString;
    Chart.Title.Visible := True;
    Chart.PrintLandscape;
    Chart.Title.Visible := False;
  end;
end;

procedure TfrmMain.SaveProject(const FileName: string);
var
  INF: TMemIniFile;
begin
  INF := TMemIniFile.Create(FProjectDir + PARAMETERS_FILE_NAME);

  try
    INF.WriteString('PARAMS', 'N', edN.Text);
    INF.WriteInteger('PARAMS', 'Mode', rgCalcMode.ItemIndex);
    INF.WriteInteger('PARAMS', 'Polarisation', rgPolarisation.ItemIndex);
    INF.WriteString('PARAMS', 'MinLimit', cbMinLimit.Text);

    INF.WriteString('ANGLE', 'Start', edStartTeta.Text);
    INF.WriteString('ANGLE', 'End', edEndTeta.Text);
    INF.WriteString('ANGLE', 'lambbda', edLambda.Text);
    INF.WriteString('ANGLE', 'width', edWidth.Text);
    INF.WriteBool('ANGLE', '2teta', cb2Theta.Checked);

    INF.WriteString('WAVE', 'Start', edStartL.Text);
    INF.WriteString('WAVE', 'End', edEndL.Text);
    INF.WriteString('WAVE', 'Teta', edTheta.Text);
    INF.WriteString('WAVE', 'width', edDL.Text);

    INF.WriteInteger('INFO', 'Version', CURRENT_PROJECT_VERSION);

    if Project.LinkedData <> nil then
      INF.WriteInteger('STATE', 'LinkedData', Project.LinkedData.ID);
    if Project.ActiveModel <> nil then
    begin
      INF.WriteInteger('STATE', 'ActiveModel', Project.ActiveModel.ID);
      Project.ActiveModel.Data := Structure.ToString;
    end;

    INF.WriteString('FIT', 'Namx', edFIter.Text);
    INF.WriteString('FIT', 'Pop', edFPopulation.Text);
    INF.WriteInteger('FIT', 'Mode', rgFittingMode.ItemIndex);
    INF.WriteString('FIT', 'PolyOrder', edPolyOrder.Text);

    INF.WriteBool('FIT', 'PWChi', cbPWChiSqr.Checked);
    INF.WriteFloat('FIT', 'Window', FFitParams.MovAvgWindow);
    INF.WriteInteger('FIT', 'TWChi', cbTWChi.ItemIndex);

    INF.WriteString('FIT', 'Tol', FFitParams.Tolerance.ToString);
    INF.WriteString('LFPSO', 'Vmax', FFitParams.Vmax.ToString);
    INF.WriteString('LFPSO', 'Jmax', FFitParams.JammingMax.ToString);
    INF.WriteString('LFPSO', 'RIMax', FFitParams.ReInitMax.ToString);
    INF.WriteString('LFPSO', 'kChi', FFitParams.KChiSqr.ToString);
    INF.WriteString('LFPSO', 'kVmax', FFitParams.KVmax.ToString);
    INF.WriteString('LFPSO', 'w1', FFitParams.w1.ToString);
    INF.WriteString('LFPSO', 'w2', FFitParams.w2.ToString);
    INF.WriteBool('LFPSO', 'AdaptV', FFitParams.AdaptVel);

    INF.WriteBool('LFPSO', 'Shake', cbLFPSOShake.Checked);
    INF.WriteBool('LFPSO', 'SeedRange', cbSeedRange.Checked);
    INF.WriteBool('LFPSO', 'Smooth', cbSmooth.Checked);
    INF.WriteInteger('LFPSO', 'SmoothWindow', FFitParams.SmoothWindow);
    INF.WriteString('LFPSO', 'Ksxr', FFitParams.Ksxr.ToString);
    INF.WriteInteger('LFPSO', 'PolyFactor', FFitParams.PolyFactor );
    INF.UpdateFile;

    if FileExists(FileName) then
      DeleteFile(FileName);

    Project.SaveToFile(FProjectDir + PROJECT_FILE_NAME);

    Zip.ArchiveType := atZip;
    Zip.AutoSave := True;
    Zip.ForceType := True;
    Zip.OpenArchive(FileName);
    Zip.BaseDirectory  := FProjectDir;

    Zip.AddFiles('*.*', faAnyFile and faDirectory);
    Zip.CloseArchive;
  finally
    INF.Free;
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
      SeriesToFile(FSeriesList[Data.CurveID], DataName(Data));
    end;
    Node := Project.GetNext(Node);
  end;
end;

procedure TfrmMain.FileSaveAsExecute(Sender: TObject);
var
  OldProjectDir: string;
begin
  dlgSaveProject.FileName := ExtractFileName(FProjectFileName);
  if dlgSaveProject.Execute then
  begin
    OldProjectDir := FProjectDir;
    FProjectName := ExtractFileName(dlgSaveProject.FileName);
    FProjectDir := IncludeTrailingPathDelimiter
      (Config.TempPath + FProjectName);

    if DirectoryExists(FProjectDir) then
        ClearDir(FProjectDir, True);

    CreateDir(FProjectDir);
    SaveData;
    SaveProject(dlgSaveProject.FileName);
    LoadProject(dlgSaveProject.FileName, False);
    FProjectFileName := dlgSaveProject.FileName;
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

  xv := FSeriesList[Project.ActiveModel.CurveID].XScreenToValue(X);
  yv := FSeriesList[Project.ActiveModel.CurveID].YScreenToValue(Y);
  StatusX.Caption := FloatToStrF(xv, ffFixed, 4, 3);
  if yv < 0.01 then
    StatusY.Caption := FloatToStrF(yv, ffExponent, 3, 2)
  else
    StatusY.Caption := FloatToStrF(yv, ffFixed, 4, 3);

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
  PrintMax;
end;

procedure TfrmMain.CreateDefaultProject;
var
  PD: PProjectData;
  PG: PVirtualNode;
begin
  if DirectoryExists(FProjectDir) then
    ClearDir(FProjectDir);
  RemoveDirectory(PChar(FProjectDir));

  Chart.SeriesList.Clear;
  Project.Clear;
  Structure.AddSubstrate('Si', 5, 2.2);

  FLastID := 1;
  FProjectName := DEFAULT_PROJECT_NAME;
  FProjectDir := IncludeTrailingPathDelimiter(Config.TempPath + FProjectName);
  FProjectFileName := FProjectDir + FProjectName;
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
end;

procedure TfrmMain.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  FDPI := NewDPI;
  if Project.TargetDPI <> NewDPI then
  begin
    Project.TargetDPI := NewDPI;
    Project.ScaleForPPI(NewDPI);
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
var
  RecentList: array of String;
  i: Integer;
begin
  FRecentProjects := TList<String>.Create;

  SetLength(RecentList, MAX_RECENT_CAPACITY);
  TConfig.ReadStringList('Recent', RecentList);

  for i := 0 to High(RecentList) do
    if RecentList[i] <> '' then
      FRecentProjects.Add(RecentList[i]);

  FillRecentMenu;
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Value: string;
begin
  {$IFDEF  WIN64}
     pnlX64.Visible := True;
  {$ELSE}
     pnlX64.Visible := False;
  {$ENDIF}

  FDPI := Screen.PixelsPerInch;
  FormatSettings.DecimalSeparator := '.';
  Config := TConfig.Create;
  CreateProjectTree;

  PM := TProfileManager.Create;
  PM.DensityProfile := DensityProfile;

  Structure := TXRCStructure.Create(StructurePanel, FDPI);
  Structure.Parent := StructurePanel;

  FOperationsStack := TStack<String>.Create;
  FOperationsStack.Capacity := 10;

  LoadRecentProjectsList;

  Project.NodeDataSize := SizeOf(TProjectData);

//  CreateSettings;
  CreateDir(Config.TempDir);
  Pages.ActivePageindex := 0;


//  FindPCores;

  if ParamCount <> 0 then
  begin
     if FindCmdLineSwitch('f', Value, True, [clstValueNextParam]) then
      begin
        if FileExists(Value) then
        begin
          FProjectFileName := Value;
          LoadProject(FProjectFileName, True);
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

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  Project.Clear;
  FreeAndNil(Project);
  FreeAndNil(Structure);
  FreeAndNil(FOperationsStack);
  FreeAndNil(Config);
end;


procedure TfrmMain.rgCalcModeChanging(Sender: TObject; NewIndex: Integer;
  var AllowChange: Boolean);
begin
  case NewIndex of
    0:
      begin
        pnlAngleParams.Enabled := True;
        pnlWaveParams.Enabled := False;
        Chart.BottomAxis.Title.Caption := 'Incidence angle (deg)';
      end;
    1:
      begin
        pnlAngleParams.Enabled := False;
        pnlWaveParams.Enabled := True;
        Chart.BottomAxis.Title.Caption := 'Wavelength (Å)';
      end;
  end;
  AllowChange := True;
end;


procedure TfrmMain.rgFittingModeClick(Sender: TObject);
var
  Mode: TFittingMode;
begin
  Mode := FittingMode;
  Structure.PeriodicMode := FittingMode = fmPeriodic;
  cbSmooth.Enabled := FittingMode = fmIrregular;
  edPolyOrder.Enabled := Mode = fmPoly;
  lblPolyOrder.Enabled := edPolyOrder.Enabled;
end;

procedure TfrmMain.btnCopyConvergenceClick(Sender: TObject);
begin
  case Pages.ActivePageIndex of
    0..2: ;
    3: SeriesToClipboard('N','ChiSqr','','', lsrConvergence);
  end;
end;

procedure TfrmMain.cbIncrementChange(Sender: TObject);
begin
  Structure.Increment := StrToFloat(cbIncrement.Value);
end;

procedure TfrmMain.cbMinLimitChange(Sender: TObject);
begin
  Chart.LeftAxis.Minimum := StrToFloat(cbMinLimit.Text);
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

//procedure TfrmMain.WMStackDblClick(var Msg: TMessage);
//var
//  ID: Integer;
//begin
//  ID := Msg.WParam;
//  Structure.  EditStack(ID);
//end;

end.
