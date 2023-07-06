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
  unit_calc, unit_XRCProjectTree, RzRadGrp, Vcl.RibbonLunaStyleActnCtrls,
  unit_materials, VCLTee.TeeFunci, unit_LFPSO_Base, unit_LFPSO_Periodic, Vcl.Buttons,
  unit_LFPSO_Regular;

type
  TSeriesList = array of TLineSeries;

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
    Reopen1: TMenuItem;
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
    RzToolbar2: TRzToolbar;
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
    chThickness: TChart;
    chRoughness: TChart;
    chDensity: TChart;
    RzStatusPane7: TRzStatusPane;
    tsFittingProgress: TRzTabSheet;
    chFittingProgress: TChart;
    lsrConvergence: TLineSeries;
    spnFitTime: TRzStatusPane;
    pnl1: TPanel;
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
    BtnCancel: TRzToolButton;
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
    RzPageControl1: TRzPageControl;
    TabSheet1: TRzTabSheet;
    TabSheet2: TRzTabSheet;
    edFIter: TEdit;
    Label7: TLabel;
    Label8: TLabel;
    edFPopulation: TEdit;
    Label20: TLabel;
    cbPWChiSqr: TRzCheckBox;
    Label5: TLabel;
    edFWindow: TEdit;
    cbTWChi: TComboBox;
    Label21: TLabel;
    edFitTolerance: TEdit;
    Label16: TLabel;
    edFVmax: TEdit;
    cbLFPSOShake: TRzCheckBox;
    Label18: TLabel;
    Label19: TLabel;
    edLFPSOOmega1: TEdit;
    edLFPSOOmega2: TEdit;
    Label17: TLabel;
    edLFPSORImax: TEdit;
    Label13: TLabel;
    edLFPSOChiFactor: TEdit;
    edLFPSOkVmax: TEdit;
    Label14: TLabel;
    edLFPSOSkip: TEdit;
    Label15: TLabel;
    cbTreatPeriodic: TRzCheckBox;
    RzButton1: TRzButton;
    NewFolder1: TMenuItem;
    N8: TMenuItem;
    actEditHenke: TAction;
    EditHenketable1: TMenuItem;
    actProjecEditModelText: TAction;
    actProjecEditModelText1: TMenuItem;
    N9: TMenuItem;
    cbPoly: TRzCheckBox;
    edPolyOrder: TEdit;
    N10: TMenuItem;
    Fitting1: TMenuItem;
    N11: TMenuItem;
    MaterialsLibrary1: TMenuItem;
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
    procedure RzButton1Click(Sender: TObject);
    procedure DataNormAutoExecute(Sender: TObject);
    procedure actEditHenkeExecute(Sender: TObject);
    procedure rgCalcModeChanging(Sender: TObject; NewIndex: Integer;
      var AllowChange: Boolean);
    procedure actProjecEditModelTextExecute(Sender: TObject);
    procedure cbMinLimitChange(Sender: TObject);
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

    FSeriesList: TSeriesList ;

    FSeriesArray: array [1..3] of TSeriesList;

    FProfiles: TProfileFunctions;
    FFitParams: TFitParams;
    FCalc: TCalc;
    FCalcThreadParams: TCalcThreadParams;
    FFitStructure: TFitStructure;
    FLastChiSquare: Single;

    procedure CreateProjectTree;
    procedure LoadProject(const FileName: string; Clear: Boolean);
    function DataName(Data: PProjectData): string;
    procedure CreateDefaultProject;
    procedure PrepareProjectFolder(const FileName: string; Clear: Boolean);
    procedure LoadProjectParams(var LinkedID, ActiveID: Integer);
    procedure RecoverProjectTree(const ActiveID: Integer);
    procedure RecoverDataCurves(const LinkedID: integer);
    procedure FinalizeCalc(Calc: TCalc);
    procedure GetThreadParams;
    procedure PlotResults(const Data: TDataArray);
    procedure PrintMax;
    procedure SaveProject(const FileName: string);
    procedure SaveData;
    procedure AddCurve(Data: PProjectData);
    procedure PrepareDistributionCharts;
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
    procedure PlotProfileNP;
    procedure PlotProfile;
    function IsProfileEnbled: Boolean;
    procedure PlotGradedProfile;
    procedure PlotSimpleProfile;
    procedure ClearProfiles;
    procedure PrepareInterfaceAF;
    function PrepareCalc: boolean;
    function PrepareLFPSO : boolean;
    procedure CreateFitGradientExtensions(const P: TProfileFunctions);
    { Private declarations }
  public
    { Public declarations }
    procedure WMStackClick(var Msg: TMessage); message WM_STR_STACK_CLICK;
    procedure WMLayerClick(var Msg: TMessage); message WM_STR_LAYER_CLICK;
    procedure WMLinkedClick(var Msg: TMessage); message WM_STR_Linked_CLICK;
    //procedure WMStackDblClick(var Msg: TMessage); message WM_STR_STACKDBLCLICK;
    procedure OnMyMessage(var Msg: TMessage); message WM_RECALC;
    procedure OnFitUpdateMsg(var Msg: TMessage); message WM_CHI_UPDATE;
  end;

var
  frmMain: TfrmMain;

implementation

uses
  System.IniFiles,
  System.DateUtils,
  AbUtils,
  unit_settings,
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
  unit_LFPSO_Poly;

{$R *.dfm}

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

procedure TfrmMain.OnFitUpdateMsg(var Msg: TMessage);
var
  msg_prm: PUpdateFitProgressMsg;
  Hour, Min, Sec, MSec: Word;
begin
  msg_prm := PUpdateFitProgressMsg(Msg.WParam);
  lsrConvergence.AddXY(msg_prm.Step, msg_prm.BestChi);
  if chFittingProgress.LeftAxis.Maximum < msg_prm.BestChi then
    chFittingProgress.LeftAxis.Maximum := 1.1 * msg_prm.BestChi;


  spChiSqr.Caption := FloatToStrF(msg_prm.BestChi, ffFixed, 8, 4);
  spChiBest.Caption := FloatToStrF(msg_prm.BestChi, ffFixed, 8, 4);
  if (Length(msg_prm.Curve) > 1) then
  begin
     PlotResults(msg_prm.Curve);
  end;
  Dispose(msg_prm);
  DecodeTime(Now - FitStartTime, Hour, Min, Sec, MSec);
  spnFitTime.Caption := Format('Fitting Time: %2.2d:%2.2d:%2.2d sec', [Hour, Min, Sec]);

end;

procedure TfrmMain.OnMyMessage(var Msg: TMessage);
begin
  PlotProfile;
  CalcRunExecute(Self);
end;

procedure TfrmMain.CreateProjectTree;
begin
  Project := TXRCProjectTree.Create(RzPanel1);
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
      LastData.Data := Structure.ToString;
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
        Structure.FromString(LastData.Data);
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
begin
  if IsModel and IsItem then
    DeleteModel(LastNode, LastData);
  if IsData and IsItem then
    DeleteData(LastNode, LastData);
  if IsFolder then
    DeleteFolder(LastNode);
  if IsExtension then
    DeleteExtension(LastNode);
  ProjectChange(Project, Nil);
end;

function TfrmMain.CreateChildNode(out Node: PVirtualNode): boolean;
var
  Data: PProjectData;
begin
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
  else begin
    ShowMessage('Parent model is not selected!');
    Result := False;
  end;
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
    etArb  : CreateProfileExtension;
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
    Data.Title := 'Profile';
    Data.ExtType := etArb;
    Data.StackID := -1;
    Data.LayerID := -1;
    Data.Form := ffPoly;

    Project.ClearSelection;
    Project.Selected[Node] := True;
  end;
end;

procedure TfrmMain.CreateFitGradientExtensions(const P: TProfileFunctions);
const
  L : array [0..2] of string = ('H','S','rho');

var
  Gradient: PVirtualNode;
  Data: PProjectData;
  i, j: Integer;
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
    Data.Poly    := P[i].C;
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
          etArb :;
        end;

      end;
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
  end;
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

  FSeriesList[Count].LinePen.Width := 2;
  Data.Visible := True;
  FSeriesList[Count].Visible := Data.Visible;
  Data.CurveID := Count;
end;

procedure TfrmMain.btnSetFitLimitsClick(Sender: TObject);
var
    FitStructure: TFitStructure;
begin
  FitStructure := Structure.ToFitStructure;
  frmLimits.Show(FitStructure);
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

procedure TfrmMain.MatchToStructure;
begin
  PrepareDistributionCharts;
  PlotProfile;
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
     Structure.AddStack(N, Name);
end;

procedure TfrmMain.PeriodDeleteExecute(Sender: TObject);
begin
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
     Structure.InsertStack(N, Name);
  MatchToStructure;
end;

procedure TfrmMain.PrepareProjectFolder(const FileName: string; Clear: Boolean);
begin
  FProjectFileName := FileName;
  FProjectName := ExtractFileName(FileName);
  FProjectDir := IncludeTrailingPathDelimiter(Settings.TempPath + FProjectName);

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


procedure TfrmMain.LoadProjectParams(var LinkedID, ActiveID: Integer);
var
  INF: TMemIniFile;
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
    edFitTolerance.Text     := INF.ReadString('FIT', 'Tol', '0.005');
    cbTreatPeriodic.Checked := INF.ReadBool('FIT', 'Periodic', True);
    cbPoly.Checked          := INF.ReadBool('FIT', 'Poly', False);
    edPolyOrder.Text        := INF.ReadString('FIT', 'PolyOrder', '1');

    cbPWChiSqr.Checked  := INF.ReadBool('FIT', 'PWChi', True);
    edFWindow.Text      := INF.ReadString('FIT', 'Window', '0.05');
    cbTWChi.ItemIndex   := INF.ReadInteger('FIT', 'TWChi', 0);

    edFVmax.Text          := INF.ReadString('LFPSO', 'Vmax', '0.1');
    edLFPSOSkip.Text      := INF.ReadString('LFPSO', 'Jmax', '1');
    edLFPSORImax.Text     := INF.ReadString('LFPSO', 'RIMax', '3');
    edLFPSOChiFactor.Text := INF.ReadString('LFPSO', 'kChi', '2');
    edLFPSOkVmax.Text     := INF.ReadString('LFPSO', 'kVmax', '2');
    edLFPSOOmega1.Text    := INF.ReadString('LFPSO', 'w1', '0.1');
    edLFPSOOmega2.Text    := INF.ReadString('LFPSO', 'w2', '0.1');

    cbLFPSOShake.Checked  := INF.ReadBool('LFPSO', 'Shake', True);
  finally
    INF.Free;
  end;
end;

function TfrmMain.GetFitParams: boolean;
begin
  Result := False;
  FFitStructure := Structure.ToFitStructure;
  if frmLimits.Show(FFitStructure) then
        Structure.UpdateInterfaceP(FFitStructure)
  else begin
    Exit;
  end;

  FFitParams.NMax := StrToInt(edFIter.Text);
  FFitParams.Pop  := StrToInt(edFPopulation.Text);
  FFitParams.Vmax  := StrToFloat(edFVmax.Text);
  FFitParams.JammingMax := StrToInt(edLFPSOSkip.Text);
  FFitParams.ReInitMax  := StrToInt(edLFPSORImax.Text);
  FFitParams.KChiSqr    := StrToFloat(edLFPSOChiFactor.Text);
  FFitParams.KVmax      := StrToFloat(edLFPSOkVmax.Text);
  FFitParams.w1         := StrToFloat(edLFPSOOmega1.Text);
  FFitParams.w2         := StrToFloat(edLFPSOOmega2.Text);
  FFitParams.Tolerance := StrToFloat(edFitTolerance.Text);

  FFitParams.Shake       := cbLFPSOShake.Checked;
  FFitParams.ThetaWieght := cbTWChi.ItemIndex;
  FFitParams.CFactor     := True;
  FFitParams.MaxPOrder   := StrToInt(edPolyOrder.Text);
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
      Result[Count].C       := Data.Poly;
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

  Screen.Cursor := crHourGlass;
  FSeriesList[Project.ActiveModel.CurveID].BeginUpdate;

  CalcRun.Enabled := False;
  CalcAll.Enabled := False;
  actAutoFitting.Enabled := False;
  CalcStop.Enabled := True;


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

  my := 0;
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

                    IsProfile := LastData.ExtType = etArb;
                    pmCopytoclipboard.Visible := IsProfile;
                    pmExporttofile.Visible    := IsProfile;
                 end;
  end;
end;

procedure TfrmMain.FinalizeCalc(Calc: TCalc);
var
  Hour, Min, Sec, MSec: Word;
begin
  PlotResults(Calc.Results);
  DecodeTime(Now - StartTime, Hour, Min, Sec, MSec);
  spnTime.Caption := Format('Time: %d.%3.3d s.', [60 * Min + Sec, MSec]);
  FSeriesList[Project.ActiveModel.CurveID].EndUpdate;
  FSeriesList[Project.ActiveModel.CurveID].Repaint;
  StatusD.Caption := FloatToStrF(Structure.Period, ffFixed, 7, 2);
  Screen.Cursor := crDefault;

  CalcRun.Enabled := True;
  CalcAll.Enabled := True;
  actAutoFitting.Enabled := True;
  CalcStop.Enabled := False;


  PrintMax;
end;

procedure TfrmMain.PrepareDistributionCharts;
var
  Materials: TMaterialsList;

  procedure InitSereis(Series: TLineSeries);
  begin
    Series.LinePen.Width := 2;
    Series.Stairs := True;
    Series.Pointer.Visible := True;
    Series.Pointer.Size := 2;
  end;

  procedure CreateSeries(Chart: TChart; var SeriesList: TSeriesList);
  var
    i: integer;
  begin
    Chart.SeriesList.Clear;
    SetLength(SeriesList, High(Materials) + 1);

    for I := 0 to High(Materials) do
    begin
      SeriesList[i] := TLineSeries.Create(Chart);
      SeriesList[i].Title := Materials[i].Name;
      SeriesList[i].ParentChart := Chart;
      InitSereis(SeriesList[i]);
    end;
  end;

begin
  Materials := Structure.Materials;

  CreateSeries(chThickness, FSeriesArray[1]);
  CreateSeries(chRoughness, FSeriesArray[2]);
  CreateSeries(chDensity,   FSeriesArray[3]);
end;

procedure TfrmMain.PlotProfileNP;
var
  i, j, k, p, shift: integer;
begin
  shift := 1;
  for i := 0 to High(Structure.Stacks) do
  begin
    if Structure.Stacks[i].N = 1 then Continue;
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      for k := 0 to High(Structure.Stacks[i].Layers[j].Data.PP[1]) do
      begin
        for p := 1 to 3 do
         FSeriesArray[p][j].AddXY(k + shift, Structure.Stacks[i].Layers[j].Data.PP[p][k]);
      end;
    end;
    Inc(shift, Structure.Stacks[i].N);
  end;
end;

procedure TfrmMain.PlotGradedProfile;
var
  StackIndex, LayerIndex, PeriodIndex, GradientIndex, shift, d, p: integer;
  Profiled: Boolean;

  function IsProfile: boolean;
  begin
     Result := (Structure.Stacks[StackIndex].Layers[LayerIndex].StackID = FProfiles[GradientIndex].StackID) and
               (Structure.Stacks[StackIndex].Layers[LayerIndex].ID = FProfiles[GradientIndex].LayerID) and
               (FProfiles[GradientIndex].PIndex = p);
  end;

begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(Structure.Stacks) do
  begin
    if Structure.Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(Structure.Stacks[StackIndex].Layers) do
    begin
      for PeriodIndex := 1 to Structure.Stacks[StackIndex].N do
      begin
        for p := 1 to 3 do
        begin
          Profiled := False;
          for GradientIndex := 0 to High(FProfiles) do
          begin
            if IsProfile then
            begin
              FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
                                                    FuncProfile(PeriodIndex + shift, FProfiles[GradientIndex]));
              Profiled := True;
            end;
          end;
          if not Profiled then
              FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
                                                     Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[p].V);
         end;
        end;
    end;
    Inc(shift, Structure.Stacks[StackIndex].N);
    Inc(d, Length(Structure.Stacks[StackIndex].Layers));
  end;
end;


procedure TfrmMain.PlotSimpleProfile;
var
  StackIndex, LayerIndex, PeriodIndex, GradientIndex, shift, d, p: integer;
begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(Structure.Stacks) do
  begin
    if Structure.Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(Structure.Stacks[StackIndex].Layers) do
    begin
      for PeriodIndex := 1 to Structure.Stacks[StackIndex].N do
      begin
        for p := 1 to 3 do
          FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift, Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[p].V);
      end;
    end;
    Inc(shift, Structure.Stacks[StackIndex].N);
    Inc(d, Length(Structure.Stacks[StackIndex].Layers));
  end;
end;

procedure TfrmMain.ClearProfiles;
var
  StackIndex, p: integer;
begin
  for p := 1 to 3 do
    for StackIndex := 0 to High(FSeriesArray[p]) do
      FSeriesArray[p][StackIndex].Clear;
end;

procedure TfrmMain.PlotProfile;
begin
  ClearProfiles;

  FProfiles := GetProfileFunctions;
  if Length(FProfiles) > 0 then
    PlotGradedProfile
  else
      if IsProfileEnbled and not cbTreatPeriodic.Checked then
         PlotProfileNP
      else
        PlotSimpleProfile;
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

  while Node <> FDataRoot do
  begin
    Data := Project.GetNodeData(Node);
    if Data.RowType = prItem then
    begin
      Project.FocusedNode := Node;
      CalcRunExecute(Sender);
    end;
    Node := Project.GetNext(Node);
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
    if Data.ExtType = etArb then
    begin
      Result := Data.Enabled;
      Break;
    end;
    Node := Project.GetNextSibling(Node);
  end;

end;

procedure TfrmMain.CalcRunExecute(Sender: TObject);
begin
  try
    if not PrepareCalc then Exit;
    try
      FCalc.Model.Profiles := GetProfileFunctions;
      FCalc.Run;
      if (Project.LinkedData <> nil) and FSeriesList[Project.ActiveModel.CurveID].Visible then
      begin
        FLastChiSquare := FCalc.ChiSQR;
        FCalc.CalcChiSquare(cbTWChi.ItemIndex);
        spChiSqr.Caption := FloatToStrF(FCalc.ChiSQR, ffFixed, 8, 4);
      end
      else begin
        spChiSqr.Caption := '';
        FLastChiSquare := 0;
      end;

      if IsProfileEnbled and not cbTreatPeriodic.Checked then
         PlotProfileNP
     else
        PlotProfile;
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
    FCalc.Free;
  end;
end;

procedure TfrmMain.CalcStopExecute(Sender: TObject);
begin
 if LFPSO <> nil then
       LFPSO.Terminate;
end;


procedure TfrmMain.PrepareInterfaceAF;
begin
  lsrConvergence.Clear;
  Pages.ActivePage := tsFittingProgress;
  chFittingProgress.BottomAxis.Minimum := 0;
  chFittingProgress.BottomAxis.Maximum := FFitParams.NMax;
  chFittingProgress.BottomAxis.Minimum := -1;
  chFittingProgress.LeftAxis.Minimum := FFitParams.Tolerance / 5;
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
      FCalc.MovAvg := MovAvg(FCalc.ExpValues, StrToFloat(edFWindow.Text));
  end;

  GetThreadParams;
  FCalc.Params := FCalcThreadParams;
  FCalc.Model := Structure.Model(IsProfileEnbled and not cbTreatPeriodic.Checked);
  Result := True;
end;


function TfrmMain.PrepareLFPSO: Boolean;
begin
  Result := False;
  if cbTreatPeriodic.Checked then
     LFPSO := TLFPSO_Periodic.Create
  else
    if cbPoly.Checked then
       LFPSO := TLFPSO_Poly.Create
     else
       LFPSO := TLFPSO_Regular.Create;

  GetThreadParams;

  LFPSO.Params := FFitParams;
  LFPSO.Limit := StrToFloat(cbMinLimit.Text);

  if (Project.LinkedData <> nil) and FSeriesList[Project.ActiveModel.CurveID].Visible then
  begin
    LFPSO.ExpValues := SeriesToData(FSeriesList[Project.LinkedData.CurveID]);
    if cbPWChiSqr.Checked then
      LFPSO.MovAvg := MovAvg(LFPSO.ExpValues, StrToFloat(edFWindow.Text));
  end else
  begin
     FreeAndNil(LFPSO);
     ShowMessage('Measured curve is not linked!');
     Exit;
  end;

  LFPSO.Structure := FFitStructure;
  PrepareInterfaceAF;
  Result := True;
end;

procedure TfrmMain.actAutoFittingExecute(Sender: TObject);
var
  Hour, Min, Sec, MSec: Word;
  Node: PVirtualNode;
begin
  if not GetFitParams then Exit;

  try
    if not PrepareLFPSO then Exit;
    FitStartTime := Now;

    LFPSO.Run(FCalcThreadParams);

    if Structure.IsPeriodic then
    begin
      Structure.UpdateInterfaceP(LFPSO.Structure);
      if not cbTreatPeriodic.Checked then
      begin
        if cbPoly.Checked then
         CreateFitGradientExtensions(LFPSO.Polynomes)
        else begin
          CreateProfileExtension;
          Structure.UpdateProfiles(LFPSO.Result);
        end;

      end;
    end
    else
      Structure.UpdateInterfaceNP(LFPSO.Structure);

    Project.ActiveModel.Data  := Structure.ToString;
    DecodeTime(Now - FitStartTime, Hour, Min, Sec, MSec);
    spnFitTime.Caption := Format('Fitting Time: %2.2d:%2.2d:%2.2d sec', [Hour, Min, Sec]);
    CalcRunExecute(nil);
  finally
    Screen.Cursor := crDefault;
    FreeAndNil(LFPSO);
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
  Structure.EnablePairing;
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

procedure TfrmMain.LayerAddExecute(Sender: TObject);
var
  Data: TLayerData;
begin
  if Structure.SelectedStack = -1 then
  begin
    ShowMessage('Stack is not selected!');
    Exit;
  end;

  Data.Material := 'Si';

  Data.P[1].New(25);
  Data.P[2].New(3);
  Data.P[3].New(0);

  if edtrLayer.ShowEditor(False, Data) then
    Structure.AddLayer(Structure.SelectedStack, Data);
  MatchToStructure;
end;

procedure TfrmMain.LayerCutExecute(Sender: TObject);
begin
  Structure.CopyLayer(False);
  Structure.DeleteLayer;
  MatchToStructure;
end;

procedure TfrmMain.LayerDeleteExecute(Sender: TObject);
begin
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

  Data.Material := 'Si';

  Data.P[1].New(25);
  Data.P[2].New(3);
  Data.P[3].New(0);

  if edtrLayer.ShowEditor(False, Data) then
        Structure.InsertLayer(Data);
  MatchToStructure;
end;

procedure TfrmMain.LayerPasteExecute(Sender: TObject);
begin
  Structure.PasteLayer;
  MatchToStructure;
end;

procedure TfrmMain.LoadProject(const FileName: string; Clear: Boolean);
var
  LinkedID, ActiveID: Integer;
begin
  FIgnoreFocusChange := True;
  PrepareProjectFolder(FileName, Clear);
  LoadProjectParams(LinkedID, ActiveID);
  RecoverProjectTree(ActiveID);
  RecoverDataCurves(LinkedID);

  ClearProfiles;
  FIgnoreFocusChange := False;
  Project.Repaint;
  Caption := 'X-Ray Calc 3: ' + ExtractFileName(FileName);
  MatchToStructure;
end;

procedure TfrmMain.FileCopyPlotBMPExecute(Sender: TObject);
begin
  Chart.CopyToClipboardBitmap;
end;

procedure TfrmMain.FileNewExecute(Sender: TObject);
begin
  Structure.Clear;
  ClearProfiles;
  CreateDefaultProject;
end;

procedure TfrmMain.FileOpenExecute(Sender: TObject);
begin
  if dlgOpenProject.Execute then
  begin
    LoadProject(dlgOpenProject.FileName, True);
//    AddRecentItem(FProjectFileName , True);
  end;
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
    INF.WriteString('FIT', 'Tol', edFitTolerance.Text);
    INF.WriteBool('FIT', 'Periodic', cbTreatPeriodic.Checked);
    INF.WriteBool('FIT', 'Poly', cbPoly.Checked);
    INF.WriteString('FIT', 'PolyOrder', edPolyOrder.Text);

    INF.WriteBool('FIT', 'PWChi', cbPWChiSqr.Checked);
    INF.WriteString('FIT', 'Window', edFWindow.Text);
    INF.WriteInteger('FIT', 'TWChi', cbTWChi.ItemIndex);

    INF.WriteString('LFPSO', 'Vmax', edFVmax.Text);
    INF.WriteString('LFPSO', 'Jmax', edLFPSOSkip.Text );
    INF.WriteString('LFPSO', 'RIMax', edLFPSORImax.Text );
    INF.WriteString('LFPSO', 'kChi', edLFPSOChiFactor.Text);
    INF.WriteString('LFPSO', 'kVmax', edLFPSOkVmax.Text );
    INF.WriteString('LFPSO', 'w1', edLFPSOOmega1.Text );
    INF.WriteString('LFPSO', 'w2', edLFPSOOmega2.Text);
    INF.WriteBool('LFPSO', 'Shake', cbLFPSOShake.Checked);

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
  if dlgSaveProject.Execute then
  begin
    OldProjectDir := FProjectDir;
    FProjectName := ExtractFileName(dlgSaveProject.FileName);
    FProjectDir := IncludeTrailingPathDelimiter
      (Settings.TempPath + FProjectName);

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
  if FProjectName = 'noname.xrcx' then
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
  FProjectName := 'noname.xrcx';
  FProjectDir := IncludeTrailingPathDelimiter(Settings.TempPath + FProjectName);
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
end;

procedure TfrmMain.FormCreate(Sender: TObject);
var
  Value: string;
begin
  CreateProjectTree;

  Structure := TXRCStructure.Create(StructurePanel);
  Structure.Parent := StructurePanel;

  FormatSettings.DecimalSeparator := '.';
  Project.NodeDataSize := SizeOf(TProjectData);

  CreateSettings;
  CreateDir(Settings.TempDir);
  Pages.ActivePageindex := 0;

  if ParamCount <> 0 then
  begin
     if FindCmdLineSwitch('f', Value, True, [clstValueNextParam]) then
      begin
        if FileExists(Value) then
        begin
          FProjectFileName := Value;
          LoadProject(FProjectFileName, True);
          if FindCmdLineSwitch('a') then
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
  FreeAndNil(Structure);
  FreeAndNil(Settings);
end;


procedure TfrmMain.rgCalcModeChanging(Sender: TObject; NewIndex: Integer;
  var AllowChange: Boolean);
begin
  case NewIndex of
    0:
      begin
        pnlAngleParams.Enabled := True;
        pnlWaveParams.Enabled := False;
      end;
    1:
      begin
        pnlAngleParams.Enabled := False;
        pnlWaveParams.Enabled := True;
      end;
  end;
  AllowChange := True;
end;


procedure TfrmMain.RzButton1Click(Sender: TObject);
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
