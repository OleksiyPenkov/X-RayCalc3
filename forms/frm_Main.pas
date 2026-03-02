unit frm_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes,
  Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzSplit, Vcl.ExtCtrls, RzPanel,
  Vcl.Menus, RzTabs, Vcl.ToolWin, Vcl.ComCtrls, RzButton,
  VirtualTrees, VirtualTrees.BaseTree, VirtualTrees.Types,
  Vcl.StdCtrls, RzEdit, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, RzCmboBx, RzStatus, VCLTee.Series, RzRadChk, System.ImageList,
  Vcl.ImgList, System.Actions, Vcl.ActnList,
  Vcl.ActnMan, unit_Types,
  unit_SMessages,
  unit_XRCProjectTree, RzRadGrp,
  VCLTee.TeeFunci, VCLTee.TeCanvas,
  unit_LFPSO_Base, Vcl.Buttons,
  Vcl.Imaging.pngimage, frm_Benchmark, frame_CalcSettings, frame_ChartInfo, frame_ChartPages, frame_StructurePanel, frame_ProjectPanel,
  Vcl.PlatformDefaultStyleActnCtrls, unit_ProfilesManager, unit_ChartManager,
  unit_CalcOrchestrator,
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
    FProjectPanel: TfrmProjectPanel;
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
    pnlMain: TRzPanel;
    RzPanel3: TRzPanel;
    FStructurePanel: TfrmStructurePanel;
    spnTime: TRzStatusPane;
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
    BtnFastForward: TRzToolButton;
    actLayerCopy: TAction;
    actProjectItemDuplicate: TAction;
    ilCalc: TImageList;
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
    vilModel: TVirtualImageList;
    vilCalc: TVirtualImageList;
    FCalcSettings: TfrmCalcSettings;
    FChartPages: TfrmChartPages;
    FChartInfo: TfrmChartInfo;
    procedure FileOpenExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
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
    procedure actNewMaterialExecute(Sender: TObject);
    procedure FileCopyPlotBMPExecute(Sender: TObject);
    procedure FilePlotCopyWMFExecute(Sender: TObject);
    procedure FilePlotToFileExecute(Sender: TObject);
    procedure HelpAboutExecute(Sender: TObject);
    procedure HelpContentExecute(Sender: TObject);
    procedure CalcAllExecute(Sender: TObject);
    procedure CalcStopExecute(Sender: TObject);
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
    procedure actDataTrimExecute(Sender: TObject);
    procedure actCalcFitJobsExecute(Sender: TObject);
    procedure actRecoverModelExecute(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
      NewDPI: Integer);
    procedure DataNormAutoExecute(Sender: TObject);
    procedure FormShow(Sender: TObject);
  private
    FOrchestrator: TCalcOrchestrator;
    FChartMgr: TChartManager;
    PM: TProfileManager;
    FDPI: Integer;
    FLockOwner: Boolean;
    FLockFile: File;

    procedure EnableControls(const Enable: Boolean);
    procedure UpdateCalcTime(const S: string);
    procedure UpdateFitTime(const S: string);
    procedure OnCalcModeChange(Sender: TObject);
    procedure OnFittingModeChange(Sender: TObject);
    procedure OnAdvancedSettings(Sender: TObject; var Params: TFitParams);

    procedure CreateTmpLock;
    procedure ReleaseTmpLock;
    procedure ScaleInterface;
    function GetActiveModelSeries: TFastLineSeries;
    function GetActiveDataSeries: TFastLineSeries;
    procedure OnSaveActiveData(Sender: TObject);
    procedure OnIncrementChange(Sender: TObject);
    procedure OnSetFitLimits(Sender: TObject);
    procedure OnProjectCaptionChange(const S: string);
    procedure OnLegendCheckBoxClick(Sender: TObject; Series: TChartSeries);
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
  unit_FileUtils,
  unit_XRCLayerControl,
  unit_XRCStructure,
  editor_Stack,
  editor_Layer,
  frm_Limits,
  ClipBrd,
  frm_NewMaterial,
  frm_about,
  editor_HenkeTable,
  unit_config,
  frm_settings,
  unit_XRCStackControl,
  unit_sys_helpers,
  frm_FitSettings,
  Winapi.ShellAPI;

{$R *.dfm}

function TfrmMain.GetActiveModelSeries: TFastLineSeries;
begin
  if FProjectPanel.Project.ActiveModel <> nil then
    Result := FProjectPanel.ActiveModelSeries
  else
    Result := nil;
end;

function TfrmMain.GetActiveDataSeries: TFastLineSeries;
begin
  Result := FProjectPanel.ActiveDataSeries;
end;

procedure TfrmMain.OnSaveActiveData(Sender: TObject);
begin
  FProjectPanel.SaveActiveData;
end;

procedure TfrmMain.OnLegendCheckBoxClick(Sender: TObject; Series: TChartSeries);
begin
  FProjectPanel.SyncSeriesVisibility(Series);
end;

procedure TfrmMain.OnAdvancedSettings(Sender: TObject; var Params: TFitParams);
var
  P: TFitParams;
begin
  P := FProjectPanel.FitParams;
  frmFitSettings.ShowSettings(P);
  FProjectPanel.FitParams := P;
end;

procedure TfrmMain.OnProjectCaptionChange(const S: string);
begin
  Caption := S;
end;

procedure TfrmMain.ModelCreateExecute(Sender: TObject);
begin
  FProjectPanel.CreateModel;
end;

procedure TfrmMain.actItemProperitesExecute(Sender: TObject);
begin
  FProjectPanel.EditSelectedItem;
end;

procedure TfrmMain.OnCancelBenchmarkMsg(var Msg: TMessage);
begin
  FOrchestrator.StopCalc;
end;

procedure TfrmMain.OnFitUpdateMsg(var Msg: TMessage);
begin
  FOrchestrator.HandleFitUpdate(Msg);
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
  FOrchestrator.RecalcFromStructure;
end;

procedure TfrmMain.ProjectAddFolderExecute(Sender: TObject);
begin
  FProjectPanel.AddFolder;
end;

procedure TfrmMain.ProjectItemCopyExecute(Sender: TObject);
begin
  FProjectPanel.CopySelectedItem;
end;

procedure TfrmMain.ProjectItemDeleteExecute(Sender: TObject);
begin
  FProjectPanel.DeleteSelectedItems;
end;

procedure TfrmMain.ProjectItemExtensionExecute(Sender: TObject);
begin
  FProjectPanel.AddExtension;
end;

procedure TfrmMain.DataCopyClpbrdExecute(Sender: TObject);
begin
  FChartInfo.CopyDataToClipboard;
end;

procedure TfrmMain.DataExportExecute(Sender: TObject);
begin
  FChartInfo.ExportDataToFile;
end;

procedure TfrmMain.DataLoadExecute(Sender: TObject);
begin
  FProjectPanel.LoadData;
end;

procedure TfrmMain.DataNormAutoExecute(Sender: TObject);
begin
  FChartInfo.NormalizeDataAuto;
end;

procedure TfrmMain.DataNormExecute(Sender: TObject);
begin
  FChartInfo.NormalizeData;
end;

procedure TfrmMain.actDataSmoothExecute(Sender: TObject);
begin
  FChartInfo.SmoothData;
end;

procedure TfrmMain.actDataTrimExecute(Sender: TObject);
begin
  FChartInfo.TrimData;
end;

procedure TfrmMain.actEditHenkeExecute(Sender: TObject);
begin
  edtrHenkeTable.ShowModal;
end;

procedure TfrmMain.actLayerCopyExecute(Sender: TObject);
begin
  FProjectPanel.SaveHistory;
  Structure.CopyLayer(False);
end;

procedure TfrmMain.actModelCopyExecute(Sender: TObject);
begin
  FProjectPanel.CopyModel;
end;

procedure TfrmMain.actModelPasteExecute(Sender: TObject);
begin
  FProjectPanel.PasteModel;
end;

procedure TfrmMain.actProjecEditModelTextExecute(Sender: TObject);
begin
  FProjectPanel.EditModelText;
end;

procedure TfrmMain.actProjectItemDuplicateExecute(Sender: TObject);
begin
  FProjectPanel.DuplicateModel;
end;

procedure TfrmMain.actProjectReopenExecute(Sender: TObject);
begin
  FProjectPanel.ReopenProject;
end;

procedure TfrmMain.actRecoverModelExecute(Sender: TObject);
begin
  FOrchestrator.RunCalc(True);
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


procedure TfrmMain.OnSetFitLimits(Sender: TObject);
var
  FitStructure: TFitStructure;
begin
  FitStructure := Structure.ToFitStructure;
  frmLimits.ShowLimits('Save', FitStructure);
  Structure.UpdateInterfaceP(FitStructure);
end;

procedure TfrmMain.DataPasteExecute(Sender: TObject);
begin
  FProjectPanel.PasteData;
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
    FProjectPanel.SaveHistory;
    Structure.AddStack(N, Name);
    FProjectPanel.MatchToStructure;
  end;
end;

procedure TfrmMain.PeriodDeleteExecute(Sender: TObject);
begin
  FProjectPanel.SaveHistory;
  Structure.DeleteStack;
  FProjectPanel.MatchToStructure;
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
    FProjectPanel.SaveHistory;
    Structure.InsertStack(N, Name);
    FProjectPanel.MatchToStructure;
  end;
end;


procedure TfrmMain.UpdateCalcTime(const S: string);
begin
  spnTime.Caption := S;
end;

procedure TfrmMain.UpdateFitTime(const S: string);
begin
  spnFitTime.Caption := S;
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

procedure TfrmMain.CalcAllExecute(Sender: TObject);
var
  Node: PVirtualNode;
  Data: PProjectData;
begin
  if FProjectPanel.ModelsRoot.ChildCount > 0 then
    Node := FProjectPanel.Project.GetFirstChild(FProjectPanel.ModelsRoot)
  else
    Exit;

  while Node <> nil do
  begin
    Data := FProjectPanel.Project.GetNodeData(Node);
    if Data.IsModel then
    begin
      FProjectPanel.Project.ActiveModel := Data;
      Structure.FromString(Data.Data);
      FOrchestrator.RunCalc(False);
    end;
    Node := FProjectPanel.Project.GetNextSibling(Node);
  end;
end;

procedure TfrmMain.CalcRunExecute(Sender: TObject);
begin
  FOrchestrator.RunCalc(False);
end;

procedure TfrmMain.CalcStopExecute(Sender: TObject);
begin
  FOrchestrator.StopCalc;
end;

procedure TfrmMain.EnableControls(const Enable: Boolean);
begin
  FProjectPanel.SetToolbarsEnabled(Enable);
  FStructurePanel.SetToolbarEnabled(Enable);
  ChartToolBar.Enabled := Enable;
  FChartPages.SetCopyEnabled(Enable);

  FChartInfo.btnStop.Visible := not Enable;
  Structure.Enabled := Enable;
  FProjectPanel.Project.Enabled := Enable;
  FCalcSettings.Enabled := Enable;
end;

procedure TfrmMain.acStructureUndoExecute(Sender: TObject);
begin
  if FProjectPanel.OperationsStack.Count > 0 then
    Structure.FromString(FProjectPanel.OperationsStack.Extract);
end;

procedure TfrmMain.actAutoFittingExecute(Sender: TObject);
begin
  FOrchestrator.RunFitting;
end;

procedure TfrmMain.actCalcBenchmarkExecute(Sender: TObject);
begin
  FOrchestrator.RunBenchmark;
end;

procedure TfrmMain.actCalcFitJobsExecute(Sender: TObject);
begin
  FOrchestrator.RunBatchJobs;
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

procedure TfrmMain.ResultCopyExecute(Sender: TObject);
begin
  FChartInfo.CopyResultToClipboard;
end;

procedure TfrmMain.ResultSaveExecute(Sender: TObject);
begin
  FChartInfo.SaveResultToFile;
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

  FProjectPanel.SaveHistory;

  Data.Material := 'Si';

  Data.P[1].New(25);
  Data.P[2].New(3);
  Data.P[3].New(0);

  edtrLayer.SetData(False, Data);
  if edtrLayer.ShowModal = mrOk then
    Structure.AddLayer(Structure.SelectedStack, edtrLayer.GetData);
  FProjectPanel.MatchToStructure;
end;

procedure TfrmMain.LayerCutExecute(Sender: TObject);
begin
  FProjectPanel.SaveHistory;

  Structure.CopyLayer(False);
  Structure.DeleteLayer;
  FProjectPanel.MatchToStructure;
end;

procedure TfrmMain.LayerDeleteExecute(Sender: TObject);
begin
  FProjectPanel.SaveHistory;

  Structure.DeleteLayer;
  FProjectPanel.MatchToStructure;
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

  FProjectPanel.SaveHistory;

  Data.Material := 'Si';

  Data.P[1].New(25);
  Data.P[2].New(3);
  Data.P[3].New(0);

  edtrLayer.SetData(False, Data);
  if edtrLayer.ShowModal = mrOk then
        Structure.InsertLayer(edtrLayer.GetData);
  FProjectPanel.MatchToStructure;
end;

procedure TfrmMain.LayerPasteExecute(Sender: TObject);
begin
  FProjectPanel.SaveHistory;

  Structure.PasteLayer;
  FProjectPanel.MatchToStructure;
end;

procedure TfrmMain.FileCopyPlotBMPExecute(Sender: TObject);
begin
  FChartInfo.CopyPlotBitmap;
end;

procedure TfrmMain.FileNewExecute(Sender: TObject);
begin
  FProjectPanel.NewProject;
end;

procedure TfrmMain.FileOpenExecute(Sender: TObject);
begin
  FProjectPanel.OpenProject;
end;

procedure TfrmMain.FilePlotCopyWMFExecute(Sender: TObject);
begin
  FChartInfo.CopyPlotMetafile;
end;

procedure TfrmMain.FilePlotToFileExecute(Sender: TObject);
begin
  FChartInfo.ExportPlotToFile;
end;

procedure TfrmMain.FilePrintExecute(Sender: TObject);
begin
  FChartInfo.PrintChart;
end;


procedure TfrmMain.FileSaveAsExecute(Sender: TObject);
begin
  FProjectPanel.SaveProjectAs;
end;

procedure TfrmMain.FileSaveExecute(Sender: TObject);
begin
  FProjectPanel.SaveCurrentProject;
end;

procedure TfrmMain.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  FDPI := NewDPI;
  if FProjectPanel.Project.TargetDPI <> NewDPI then
  begin
    FProjectPanel.Project.TargetDPI := NewDPI;
    FProjectPanel.Project.Rescale;
    ScaleInterface;
  end;
  if Structure.TargetDPI <> NewDPI then
  begin
    Structure.TargetDPI := NewDPI;
    if FProjectPanel.LastData <> nil then
    begin
      FProjectPanel.LastData.Data := Structure.ToString;
      Structure.FromString(FProjectPanel.LastData.Data);
    end;
  end;
end;

procedure TfrmMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := MessageDlg('Exit X-Ray Calc 3?', mtConfirmation, [mbYes, mbNo], 0, mbNO) = mrYes;
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
  FChartMgr := TChartManager.Create(FChartInfo.Chart, 2);
  ScaleInterface;
  Config := TConfig.Create;
  FChartMgr.LineWidth := Config.Section<TGraphOptions>.LineWidth;

  PM := TProfileManager.Create;
  PM.DensityProfile := FChartPages.ProfileSeries;

  FOrchestrator := TCalcOrchestrator.Create(
    FCalcSettings, FProjectPanel, FChartInfo, FChartPages, FChartMgr, PM);
  FOrchestrator.OnEnableControls := EnableControls;
  FOrchestrator.OnCalcTimeUpdate := UpdateCalcTime;
  FOrchestrator.OnFitTimeUpdate := UpdateFitTime;

  FProjectPanel.Init(ImageCollection, FDPI, FChartMgr, FCalcSettings,
    FChartInfo, FChartPages, PM, miRecent, pmRecentList);
  FProjectPanel.OnCaptionChange := OnProjectCaptionChange;
  FProjectPanel.OnCalcRun := CalcRunExecute;

  FProjectPanel.Project.OnChange := FProjectPanel.ProjectChange;
  FProjectPanel.Project.OnDblClick := FProjectPanel.ProjectDblClick;
  FProjectPanel.Project.OnFocusChanging := FProjectPanel.ProjectFocusChanging;

  FProjectPanel.ConnectFileActions(
    FileNew, FileOpen, actProjectReopen, FileSave, FilePrint, pmRecentList);
  FProjectPanel.ConnectProjectActions(
    ModelCreate, actProjectItemDuplicate, actModelCopy, actModelPaste,
    actItemProperites, ProjectItemExtension, ProjectItemDelete);
  FProjectPanel.ConnectPopupActions(
    DataNormAuto, DataNorm, actItemProperites, DataCopyClpbrd, DataExport);

  FCalcSettings.OnCalcModeChange := OnCalcModeChange;
  FCalcSettings.OnFittingModeChange := OnFittingModeChange;
  FCalcSettings.OnAdvancedSettings := OnAdvancedSettings;

  FChartInfo.CalcSettings := FCalcSettings;
  FChartInfo.OnGetActiveModelSeries := GetActiveModelSeries;
  FChartInfo.OnGetActiveDataSeries := GetActiveDataSeries;
  FChartInfo.OnSaveActiveData := OnSaveActiveData;
  FChartInfo.OnLegendCheckBoxClick := OnLegendCheckBoxClick;

  FStructurePanel.ConnectActions(vilModel,
    PeriodAdd, PeriodInsert, PeriodDelete,
    LayerAdd, LayerInsert, actLayerCopy, LayerCut, LayerPaste, LayerDelete);
  FStructurePanel.OnIncrementChange := OnIncrementChange;
  FStructurePanel.OnSetFitLimits := OnSetFitLimits;

  Structure := TXRCStructure.Create(FStructurePanel, FDPI);
  Structure.Parent := FStructurePanel;
  FProjectPanel.SetStructure(Structure);

  CreateDir(Config.TempDir);
  CreateTmpLock;
  FChartPages.ResetToFirstPage;
end;

procedure TfrmMain.FormDestroy(Sender: TObject);
begin
  FProjectPanel.Project.Clear;
  ReleaseTmpLock;
  FreeAndNil(FOrchestrator);
  FreeAndNil(Structure);
  FreeAndNil(FChartMgr);
  FreeAndNil(Config);
end;


procedure TfrmMain.OnCalcModeChange(Sender: TObject);
begin
  case FCalcSettings.CalcMode of
    0: FChartInfo.Chart.BottomAxis.Title.Caption := 'Incidence angle (deg)';
    1: FChartInfo.Chart.BottomAxis.Title.Caption := 'Wavelength (Å)';
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
          FProjectPanel.ProjectFileName := Value;
          FProjectPanel.ReopenProject;
          if FindCmdLineSwitch('a') or TConfig.Section<TOtherOptions>.AutoCalc then
            CalcRunExecute(frmMain);
        end
        else
          FProjectPanel.CreateDefaultProject;
     end;
  end
  else
    FProjectPanel.CreateDefaultProject;
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
