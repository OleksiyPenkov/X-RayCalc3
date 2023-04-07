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
  unit_materials, VCLTee.TeeFunci;

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
    RzToolbar1: TRzToolbar;
    btnProjectAddFolder: TRzToolButton;
    btnModelCreate: TRzToolButton;
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
    LayerCopy: TAction;
    LayerCut: TAction;
    LayerPaste: TAction;
    LayerPasteBefore: TAction;
    LayerPasteAfter: TAction;
    CalcRun: TAction;
    ModelCreate: TAction;
    ModelProperites: TAction;
    DataLoad: TAction;
    DataPaste: TAction;
    ResultSave: TAction;
    ResultCopy: TAction;
    FileSaveAs: TAction;
    CalcTest: TAction;
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
    CalcFitting: TAction;
    actShowLibrary: TAction;
    actAutoFitting: TAction;
    il_16: TImageList;
    il_32: TImageList;
    Project1: TMenuItem;
    Project2: TMenuItem;
    Calc1: TMenuItem;
    Calc2: TMenuItem;
    About1: TMenuItem;
    Calc3: TMenuItem;
    Calcall1: TMenuItem;
    Reopen1: TMenuItem;
    Add1: TMenuItem;
    btnModelProperites: TRzToolButton;
    btnProjectItemCopy: TRzToolButton;
    rzspcr2: TRzSpacer;
    btnProjectItemDelete: TRzToolButton;
    dlgOpenProject: TOpenDialog;
    Zip: TAbZipper;
    UnZip: TAbUnZipper;
    pnlMain: TRzPanel;
    Pages: TRzPageControl;
    tsThickness: TRzTabSheet;
    tsRoughness: TRzTabSheet;
    tsDensity: TRzTabSheet;
    ChartToolBar: TRzToolbar;
    btnDataLoad: TRzToolButton;
    btnDataPaste: TRzToolButton;
    rzspcr3: TRzSpacer;
    btnCalcRun: TRzToolButton;
    rzspcr4: TRzSpacer;
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
    btnLayerCopy: TRzToolButton;
    btnLayerPaste: TRzToolButton;
    btnLayerDelete: TRzToolButton;
    btnLayerCut: TRzToolButton;
    pnl1: TPanel;
    Label5: TLabel;
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
    pnlWaveParams: TRzPanel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    edStartL: TEdit;
    edEndL: TEdit;
    edTheta: TEdit;
    edDL: TEdit;
    edN: TEdit;
    rzspcr5: TRzSpacer;
    btnClac: TRzToolButton;
    btnCalcAll: TRzToolButton;
    spnTime: TRzStatusPane;
    Label6: TLabel;
    cbIncrement: TRzComboBox;
    rgCalcMode: TRzRadioGroup;
    rgPolarisation: TRzRadioGroup;
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
    btnResultSave: TRzToolButton;
    btnBtnCopy: TRzToolButton;
    chThickness: TChart;
    chRoughness: TChart;
    chDensity: TChart;
    RzSpacer1: TRzSpacer;
    BtnDown: TRzToolButton;
    RzStatusPane7: TRzStatusPane;
    RzSpacer2: TRzSpacer;
    BtnExecute: TRzToolButton;
    procedure rgCalcModeClick(Sender: TObject);
    procedure btnChartScaleClick(Sender: TObject);
    procedure FileOpenExecute(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure ProjectAfterCellPaint(Sender: TBaseVirtualTree;
      TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
      CellRect: TRect);
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
    procedure Auto1Click(Sender: TObject);
    procedure Manual1Click(Sender: TObject);
    procedure pmiVisibleClick(Sender: TObject);
    procedure pmiEnabledClick(Sender: TObject);
    procedure Properties1Click(Sender: TObject);
    procedure actAutoFittingExecute(Sender: TObject);
  private
    Project : TXRCProjectTree;

    FProjectDir: string;
    FProjectName: string;
    FProjectFileName: string;
    FIgnoreFocusChange: Boolean;
    FProjectVersion: Byte;

    FModelsRoot: PVirtualNode;
    FDataRoot: PVirtualNode;

    FActiveModel, FActiveData, FLinkedData: PProjectData;
    LastNode, FLastModel: PVirtualNode;
    LastData: PProjectData;

    FLastID: integer;
    IsFolder, IsItem, IsData, IsModel, IsExtension: Boolean;
    StartTime: TDateTime;

    FSeriesList: TSeriesList ;
    FThicknessSeries: TSeriesList ;
    FRoughnessSeries: TSeriesList ;
    FDensitySeries: TSeriesList ;

    procedure CreateProjectTree;
    procedure LoadProject(const FileName: string; Clear: Boolean);
    function DataName(Data: PProjectData): string;
    function ModelName(Data: PProjectData): string;
    procedure CreateDefaultProject;
    procedure PrepareProjectFolder(const FileName: string; Clear: Boolean);
    procedure LoadProjectParams(var LinkedID, ActiveID: Integer);
    procedure RecoverProjectTree(const ActiveID: Integer);
    procedure RecoverDataCurves(const LinkedID: integer);
    procedure CreateDummyStructure;
    procedure FinalizeCalc(Calc: TCalc);
    procedure GetThreadParams(var CD: TThreadParams);
    procedure PlotResults(Calc: TCalc);
    procedure PrintMax;
    procedure SaveProject(const FileName: string);
    procedure SaveData;
    procedure AddCurve(var Data: PProjectData);
    procedure PlotDistributions(Model: TLayeredModel);
    procedure PrepareDistributionCharts;
    { Private declarations }
  public
    { Public declarations }
    procedure WMStackClick(var Msg: TMessage); message WM_STR_STACK_CLICK;
//    procedure WMStackDblClick(var Msg: TMessage); message WM_STR_STACKDBLCLICK;
    procedure OnMyMessage(var Msg: TMessage); message WM_RECALC;
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
  editor_Stack, editor_Layer, unit_FitHelpers, unit_LFPSO;

{$R *.dfm}

procedure TfrmMain.btnChartScaleClick(Sender: TObject);
begin
//  if (FSeriesList[FActiveModel.CurveID].Count = 0) and (FActiveData = nil) then
//    Exit;

  if Chart.LeftAxis.Logarithmic then
  begin
    Chart.LeftAxis.Logarithmic := False;
    btnChartScale.Caption := 'Log';
    if Chart.LeftAxis.Maximum > 0.01 then
      Chart.LeftAxis.AxisValuesFormat := '0.000'
    else
      Chart.LeftAxis.AxisValuesFormat := '0e-0';
  end
  else
  begin
    btnChartScale.Caption := 'Linear';
//    Chart.LeftAxis.Minimum := StrToFloat(Settings.MinLimit);
    Chart.LeftAxis.Logarithmic := True;
    Chart.LeftAxis.AxisValuesFormat := '0e-0';
  end;
end;

procedure TfrmMain.Manual1Click(Sender: TObject);
//var
//  Form: TedtrManualNorm;
begin
//  try
//    Form := TedtrManualNorm.Create(frmMain);
//    if Form.ShowModal = mrOk then
//    begin
//      ManualMerge(Form.edPos.Value, Form.edK.Value, FActiveData.Curve);
//      SeriesToFile(FActiveData.Curve, DataName(FActiveData));
//    end;
//  finally
//    Form.Free
//  end;
end;

function TfrmMain.ModelName(Data: PProjectData): string;
begin
  Result := Format('%smodel_%d.bin', [FProjectDir, Data.ID])
end;

procedure TfrmMain.OnMyMessage(var Msg: TMessage);
begin
  CalcRunExecute(Self);
end;


procedure TfrmMain.CreateProjectTree;
begin
  Project := TXRCProjectTree.Create(RzPanel1);
  Project.Parent := RzPanel1;

  Project.OnChange := ProjectChange;
  Project.OnDblClick := ProjectDblClick;
  Project.OnFocusChanging := ProjectFocusChanging;
  Project.OnAfterCellPaint := ProjectAfterCellPaint;
  Project.PopupMenu := pmProject;
end;


procedure TfrmMain.ProjectChange(Sender: TBaseVirtualTree; Node: PVirtualNode);
begin
  if FIgnoreFocusChange then
    Exit;

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
    FActiveData := LastData;

  if IsModel then
  begin
     FLastModel := LastNode;
     if LastData.Data <> '' then
        Structure.FromString(LastData.Data);
  end;
end;

procedure TfrmMain.ProjectDblClick(Sender: TObject);
begin
//  EditProjectItem;
end;

procedure TfrmMain.ProjectAfterCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellRect: TRect);
const
  Points: array [0 .. 2] of TPoint = ((X: 25; Y: 4), (X: 32; Y: 9),
    (X: 25; Y: 13));

var
  Data: PProjectData;
begin
  if (Column <> 0) or FIgnoreFocusChange then
    Exit;

  Data := Project.GetNodeData(Node);

  // TargetCanvas.Brush.Color := ;
  TargetCanvas.FillRect(CellRect);

  if Data = FActiveModel then
  begin
    TargetCanvas.Brush.Color := clRed;
    TargetCanvas.Pen.Color := clRed;
    TargetCanvas.Polygon(Points);
  end;

  if Data = FLinkedData then
  begin
    TargetCanvas.Pen.Color := clBlack;

    TargetCanvas.Ellipse(25, 2, 35, 15);
    TargetCanvas.Brush.Color := clGreen;
    TargetCanvas.Rectangle(25, 7, 35, 15);
    TargetCanvas.Rectangle(29, 9, 31, 13);
  end;

  TargetCanvas.Pen.Color := clGray;

  if Data.RowType = prItem then
  begin
    if Data.Visible then
      TargetCanvas.Brush.Color := Data.Color
    else
      TargetCanvas.Brush.Color := clLtGray;
    TargetCanvas.Rectangle(2, 5, 10, 13);
  end;
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

//  if not FIgnoreFocusChange and (FActiveModel <> nil) then
//    Tree.SaveToFile(ModelName(FActiveModel));

//  Tree.LoadFromFile(ModelName(Data));
  FActiveModel := Data;
  Project.Repaint;
end;

procedure TfrmMain.Properties1Click(Sender: TObject);
begin
//  EditProjectItem;
end;

procedure TfrmMain.DataCopyClpbrdExecute(Sender: TObject);
begin
  SeriesToClipboard(FSeriesList[FActiveData.CurveID]);
end;

procedure TfrmMain.DataExportExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
      SeriesToFile(FSeriesList[FActiveModel.CurveID], dlgSaveResult.FileName);
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

  FActiveData := Data;
  Project.Expanded[FDataRoot] := True;

end;

function TfrmMain.DataName(Data: PProjectData): string;
begin
  Result := Format('%sdata_%d.dat', [FProjectDir, Data.ID])
end;

procedure TfrmMain.DataNormExecute(Sender: TObject);
var
  s: string;
begin
  s := InputBox('Data normalization', 'Coefficient', '');
  if s <> '' then
  begin
    Normalize(StrToFloat(s), FSeriesList[FActiveData.CurveID]);
  end;
end;

procedure TfrmMain.actAutoFittingExecute(Sender: TObject);
var
  CD: TThreadParams;
  Calc: TCalc;
  LFPSO: TLFPSO_Periodic;
begin
  Randomize;

  if (FActiveModel = nil) then
    Exit;
  GetThreadParams(CD);
  try
    Calc := TCalc.Create;

    if (FLinkedData <> nil) and FSeriesList[FActiveModel.CurveID].Visible then
       Calc.ExpValues := SeriesToData(FSeriesList[FLinkedData.CurveID])
    else
      Exit;

    try
      LFPSO := TLFPSO_Periodic.Create(40, 200);
      Calc.Params := CD;
      Calc.Limit := StrToFloat(cbMinLimit.Text);

      LFPSO.Structure := Structure.ToFitStructure(0.5);
      LFPSO.ExpValues := Calc.ExpValues;
      LFPSO.Run(CD);

      Calc.Model := LFPSO.Result;
      Calc.Run;
      Calc.CalcChiSquare;
      spChiSqr.Caption := FloatToStrF(Calc.ChiSQR, ffFixed, 8, 1);

    except
      on E: exception do
      begin
        ShowMessage(E.Message);
        FSeriesList[FActiveModel.CurveID].EndUpdate;
        FSeriesList[FActiveModel.CurveID].Repaint;
        Screen.Cursor := crDefault;
        CalcRun.Enabled := True;
      end;
    end;
    FinalizeCalc(Calc);
  finally
    Calc.Free;
    LFPSO.Free;
  end;
end;

procedure TfrmMain.ActionManagerChange(Sender: TObject);
begin
  FActiveModel.Data := Structure.ToString;
end;

procedure TfrmMain.AddCurve(var Data: PProjectData);
var
  Count: integer;
begin
  Count := Length(FSeriesList);
  SetLength(FSeriesList, Count + 1);
  FSeriesList[Count] := TLineSeries.Create(Chart);
  FSeriesList[Count].ParentChart := Chart;

  FSeriesList[Count].Title := Data.Title;
  Data.Color := FSeriesList[Count].Color;
  FSeriesList[Count].LinePen.Width := 2;
  Data.Visible := True;
  FSeriesList[Count].Visible := Data.Visible;
  Data.CurveID := Count;
end;

procedure TfrmMain.Auto1Click(Sender: TObject);
begin
  AutoMerge(FSeriesList[FActiveData.CurveID]);
  SeriesToFile(FSeriesList[FActiveData.CurveID], DataName(FActiveData));
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

  SeriesFromClipboard(FSeriesList[Data.CurveID]);
  SeriesToFile(FSeriesList[Data.CurveID], DataName(Data));
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
  Structure.DeleteStack(Structure.Selected);
  FActiveModel.Data := Structure.ToString;
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
  FActiveModel.Data := Structure.ToString;
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
  finally
    INF.Free;
  end;
end;

procedure TfrmMain.GetThreadParams(var CD: TThreadParams);
var
  StartT, EndT: single;
begin
  StartTime := Now;

  Screen.Cursor := crHourGlass;
  FSeriesList[FActiveModel.CurveID].BeginUpdate;

  CalcRun.Enabled := False;

  StartT := StrToFloat(edStartTeta.Text);
  EndT := StrToFloat(edEndTeta.Text);

  if cb2Theta.Checked then
    CD.k := 2
  else
    CD.k := 1;

  if rgPolarisation.ItemIndex = 0 then
    CD.P := cmS
  else
    CD.P := cmSP;

  case rgCalcMode.ItemIndex of
    0:begin
        CD.Mode := cmTheta;
        CD.Lambda := StrToFloat(edLambda.Text);
        CD.StartT := StartT;
        CD.EndT   := EndT;
        CD.DT     := StrToFloat(edWidth.Text);
      end;

    1:
      begin
//        ThreadsRunning := 1;
//        SetLength(FResults, 1);
//        CD.Mode := cmLambda;
//        CD.Theta := StrToFloat(edTheta.Text);
//        CD.StartL := StrToFloat(edStartL.Text);
//        CD.EndL := StrToFloat(edEndL.Text);
//        CD.DW := StrToFloat(edDL.Text);
      end;
  end;

  CD.RF := rfError;
  CD.N := StrToInt(edN.Text);
 end;

procedure TfrmMain.PrintMax;
var
  X, Y, mx, x1, x2, my, RI, OldX: single;
  i: Integer;
begin
  if FSeriesList[FActiveModel.CurveID].Count = 0 then
    Exit;

  my := 0;
  x1 := Chart.BottomAxis.Minimum;
  x2 := Chart.BottomAxis.Maximum;
  RI := 0;
  OldX := FSeriesList[FActiveModel.CurveID].XValue[1];
  for i := 2 to FSeriesList[FActiveModel.CurveID].Count - 2 do
  begin
    X := FSeriesList[FActiveModel.CurveID].XValue[i];
    Y := FSeriesList[FActiveModel.CurveID].YValue[i];
    if (X > x1) and (X < x2) and (Y > my) then
    begin
      RI := RI + Y * abs(OldX - X);
      my := Y;
      mx := X;
    end;
    OldX := X;
  end;

  if my < 0.01 then
  begin
    StatusRMax.Caption := FloatToStrF(my, ffExponent, 3, 2);
    Chart.LeftAxis.AxisValuesFormat := '0.00e-0';
  end
  else
  begin
    StatusRMax.Caption := FloatToStrF(my, ffFixed, 4, 3);
    Chart.LeftAxis.AxisValuesFormat := '0.000';
  end;

  StatusMaxX.Caption := FloatToStrF(mx, ffFixed, 5, 4);
  StatusRi.Caption := FloatToStrF(RI, ffFixed, 7, 4);
end;

 procedure TfrmMain.PlotResults(Calc: TCalc);
var
  j: Integer;
begin
  FSeriesList[FActiveModel.CurveID].Clear;
  for j := 0 to High(Calc.Results) do
      FSeriesList[FActiveModel.CurveID].AddXY(Calc.Results[j].t, Calc.Results[j].R);
end;

procedure TfrmMain.pmiEnabledClick(Sender: TObject);
begin
  LastData.Enabled := not LastData.Enabled;
  Project.Repaint;
end;

procedure TfrmMain.pmiLinkedClick(Sender: TObject);
begin
  if not pmiLinked.Checked then
    FLinkedData := nil
  else
    FLinkedData := LastData;

  Project.Repaint;
end;

procedure TfrmMain.pmiVisibleClick(Sender: TObject);
begin
//  LastData.CurveID.Visible := not LastData.Curve.Visible;
  Project.Repaint;
end;

procedure TfrmMain.FinalizeCalc(Calc: TCalc);
var
  Hour, Min, Sec, MSec: Word;
begin
  PlotResults(Calc);
  DecodeTime(Now - StartTime, Hour, Min, Sec, MSec);
  spnTime.Caption := Format('Time: %d.%3.3d s.', [60 * Min + Sec, MSec]);
  FSeriesList[FActiveModel.CurveID].EndUpdate;
  FSeriesList[FActiveModel.CurveID].Repaint;
  StatusD.Caption := FloatToStrF(Calc.TotalD, ffFixed, 7, 2);
  Screen.Cursor := crDefault;
  CalcRun.Enabled := True;
  PrintMax;
end;

procedure TfrmMain.PrepareDistributionCharts;
var
  Materials: TMaterialsList;
  i: integer;

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


  CreateSeries(chThickness, FThicknessSeries);
  CreateSeries(chRoughness, FRoughnessSeries);
  CreateSeries(chDensity, FDensitySeries);

end;

procedure TfrmMain.PlotDistributions(Model: TLayeredModel);
var
  i, j: integer;
begin
  for i := 0 to High(FThicknessSeries) do
  begin
    FThicknessSeries[i].Clear;
    FRoughnessSeries[i].Clear;
    FDensitySeries[i].Clear;
  end;

  for i := 1 to High(Model.Layers) - 1 do
  begin
    FThicknessSeries[Model.Layers[i].LayerID].AddXY(Model.Layers[i].PeriodNo, Model.Layers[i].L);
    FRoughnessSeries[Model.Layers[i].LayerID].AddXY(Model.Layers[i].PeriodNo, Model.Layers[i].s);
    FDensitySeries[Model.Layers[i].LayerID].AddXY(Model.Layers[i].PeriodNo, Model.Layers[i].ro);
  end;
end;

procedure TfrmMain.CalcRunExecute(Sender: TObject);
var
  CD: TThreadParams;
  Calc: TCalc;
begin
  if (FActiveModel = nil) then
    Exit;
  GetThreadParams(CD);
  try
    Calc := TCalc.Create;

    if (FLinkedData <> nil) and FSeriesList[FActiveModel.CurveID].Visible then
       Calc.ExpValues := SeriesToData(FSeriesList[FLinkedData.CurveID]);

    try
      Calc.Params := CD;
      Calc.Limit := StrToFloat(cbMinLimit.Text);
      Calc.Model := Structure.Model;
      PlotDistributions(Calc.Model);
      Calc.Run;
      if (FLinkedData <> nil) and FSeriesList[FActiveModel.CurveID].Visible then
      begin
        Calc.CalcChiSquare;
        spChiSqr.Caption := FloatToStrF(Calc.ChiSQR, ffFixed, 8, 1);
      end
      else
        spChiSqr.Caption := '';

    except
      on E: exception do
      begin
        ShowMessage(E.Message);
        FSeriesList[FActiveModel.CurveID].EndUpdate;
        FSeriesList[FActiveModel.CurveID].Repaint;
        Screen.Cursor := crDefault;
        CalcRun.Enabled := True;
      end;
    end;
    FinalizeCalc(Calc);
  finally
    Calc.Free;
  end;
end;

procedure TfrmMain.RecoverProjectTree(const ActiveID: Integer);
var
  Node, First: PVirtualNode;
  Data: PProjectData;
begin
  // восстанавливаем дерево проектов
  Project.Version := FProjectVersion;
  Project.LoadFromFile(FProjectDir + PROJECT_FILE_NAME);

  FModelsRoot := Project.GetFirst;
  FDataRoot := Project.GetNextSibling(FModelsRoot);

  // для каждой модели нужно создать series
  Chart.SeriesList.Clear;
  FActiveModel := nil;
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
        FActiveModel := Data;
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

  if FActiveModel = nil then
  begin
    LastNode := First;
    FActiveModel := Project.GetNodeData(First);
  end;

  inc(FLastID);

  if FActiveModel = nil then
  begin
    Project.FocusedNode := First;
    Project.Selected[First] := True;
  end
  else
  begin
    Project.FocusedNode := LastNode;
    Project.Selected[LastNode] := True;
  end;

  Structure.FromString(FActiveModel.Data);
end;

procedure TfrmMain.ResultCopyExecute(Sender: TObject);
begin
  SeriesToClipboard(FSeriesList[FActiveModel.CurveID]);
end;

procedure TfrmMain.ResultSaveExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
    SeriesToFile(FSeriesList[FActiveModel.CurveID], dlgSaveResult.FileName);
end;

procedure TfrmMain.RecoverDataCurves(const LinkedID: integer);
var
  Node: PVirtualNode;
  Data: PProjectData;
  s: string;
begin
  FActiveData := nil;

  Node := Project.GetFirstChild(FDataRoot);
  while Node <> nil do
  begin
    Data := Project.GetNodeData(Node);
    if (Data.RowType = prItem) and FileExists(DataName(Data)) then
    begin
      if FActiveData = nil then
        FActiveData := Data;

      if Data.ID = LinkedID then
        FLinkedData := Data;

      AddCurve(Data);
      SeriesFromFile(FSeriesList[Data.CurveID], DataName(Data), s);
      Chart.AddSeries(FSeriesList[Data.CurveID]);
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
  if edtrLayer.ShowModal = mrOk then
    Structure.AddLayer(Structure.Selected, edtrLayer.Data);
  FActiveModel.Data := Structure.ToString;
end;

procedure TfrmMain.LayerCutExecute(Sender: TObject);
begin
  FActiveModel.Data := Structure.ToString;
end;

procedure TfrmMain.LayerDeleteExecute(Sender: TObject);
begin
  FActiveModel.Data := Structure.ToString;
end;

procedure TfrmMain.LayerInsertExecute(Sender: TObject);
begin
  FActiveModel.Data := Structure.ToString;
end;

procedure TfrmMain.LayerPasteExecute(Sender: TObject);
begin
  FActiveModel.Data := Structure.ToString;
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

  FIgnoreFocusChange := False;
  Project.Repaint;
  PrepareDistributionCharts;
end;

procedure TfrmMain.FileOpenExecute(Sender: TObject);
begin
  if dlgOpenProject.Execute then
  begin
    LoadProject(dlgOpenProject.FileName, True);
//    AddRecentItem(FProjectFileName , True);
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

    INF.WriteString('ANGLE', 'Start', edStartTeta.Text);
    INF.WriteString('ANGLE', 'End', edEndTeta.Text);
    INF.WriteString('ANGLE', 'lambbda', edLambda.Text);
    INF.WriteString('ANGLE', 'width', edWidth.Text);
    INF.WriteBool('ANGLE', '2teta', cb2Theta.Checked);

    INF.WriteString('WAVE', 'Start', edStartL.Text);
    INF.WriteString('WAVE', 'End', edEndL.Text);
    INF.WriteString('WAVE', 'Teta', edTheta.Text);
    INF.WriteString('WAVE', 'width', edDL.Text);

    INF.WriteInteger('INFO', 'Version', CurrentProjectVersion);

    if FLinkedData <> nil then
      INF.WriteInteger('STATE', 'LinkedData', FLinkedData.ID);
    if FActiveModel <> nil then
    begin
      INF.WriteInteger('STATE', 'ActiveModel', FActiveModel.ID);
      FActiveModel.Data := Structure.ToString;
    end;

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

procedure TfrmMain.CreateDefaultProject;
var
  PD: PProjectData;
  PG, PL: PVirtualNode;
begin
  if DirectoryExists(FProjectDir) then
    ClearDir(FProjectDir);
  RemoveDirectory(PChar(FProjectDir));

  Chart.SeriesList.Clear;
  Project.Clear;

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
  PL := Project.AddChild(PG, Nil);
  FActiveModel := Project.GetNodeData(PL);
  FActiveModel.ID := FLastID;
  inc(FLastID);
  FActiveModel.Title := 'Model 1';
  FActiveModel.Group := gtModel;
  FActiveModel.RowType := prItem;

  AddCurve(FActiveModel);

//  Tree.SaveToFile(ModelName(PD)); // сохраняем модель
  Project.Expanded[PG] := True;

  // данные
  PG := Project.AddChild(Nil, Nil);
  PD := Project.GetNodeData(PG);
  PD.Title := 'Data';
  PD.Group := gtData;
  PD.RowType := prGroup;
  Project.Expanded[PG] := True;

  FDataRoot := PG;
  Structure.AddSubstrate('SiO2', 2.2, 5);
end;

procedure TfrmMain.CreateDummyStructure;
var
  Data1, Data2, Data3, Data4: TLayerData;
begin
  Data1.Material := 'Si';
  Data1.H := 23; Data1.s := 2.5; Data1.r := 2.3;

  Data2.Material := 'MoSi2';
  Data2.H := 6; Data2.s := 3; Data2.r := 6.2;

  Data3.Material := 'Mo';
  Data3.H := 14; Data3.s := 2.5; Data3.r := 10;

  Data4.Material := 'MoSi2';
  Data4.H := 12; Data2.s := 3; Data2.r := 6.2;

  Structure.AddStack(1, 'Top');
  Structure.AddLayer(0, Data1);

  Structure.AddStack(5, 'Main');
  Structure.AddLayer(1, Data4);
  Structure.AddLayer(1, Data3);
  Structure.AddLayer(1, Data2);
  Structure.AddLayer(1, Data1);
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
     if FindCmdLineSwitch('d') then
     begin
       CreateDefaultProject;
       CreateDummyStructure;
       PrepareDistributionCharts;
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

procedure TfrmMain.rgCalcModeClick(Sender: TObject);
begin
  case rgCalcMode.ItemIndex of
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
end;

procedure TfrmMain.cbIncrementChange(Sender: TObject);
begin
  Structure.Increment := StrToFloat(cbIncrement.Value);
end;

procedure TfrmMain.WMStackClick(var Msg: TMessage);
var
  ID: Integer;
begin
  ID := Msg.WParam;
  Structure.Select(ID);
  PeriodInsert.Enabled := (ID > 0);
end;

//procedure TfrmMain.WMStackDblClick(var Msg: TMessage);
//var
//  ID: Integer;
//begin
//  ID := Msg.WParam;
//  Structure.EditStack(ID);
//end;

end.
