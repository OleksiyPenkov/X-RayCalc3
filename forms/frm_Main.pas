unit frm_Main;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzSplit, Vcl.ExtCtrls, RzPanel,
  Vcl.Menus, RzTabs, Vcl.ToolWin, Vcl.ComCtrls, RzButton, VirtualTrees,
  Vcl.StdCtrls, RzEdit, VclTee.TeeGDIPlus, VCLTee.TeEngine, VCLTee.TeeProcs,
  VCLTee.Chart, RzCmboBx, RzStatus, VCLTee.Series, RzRadChk, System.ImageList,
  Vcl.ImgList, System.Actions, Vcl.ActnList, Vcl.RibbonLunaStyleActnCtrls,
  Vcl.ActnMan, AbUnzper, AbBase, AbBrowse, AbZBrows, AbZipper, unit_Types,
  IdBaseComponent, IdZLibCompressorBase, IdCompressorZLib, unit_SMessages,
  unit_calc, unit_XRCProjectTree, RzRadGrp;

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
    chGradients: TChart;
    Series1: TPointSeries;
    tsRoughness: TRzTabSheet;
    Chart1: TChart;
    PointSeries1: TPointSeries;
    tsDensity: TRzTabSheet;
    Chart2: TChart;
    PointSeries2: TPointSeries;
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
    IdCompressorZLib1: TIdCompressorZLib;
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

    procedure CreateProjectTree;
    procedure LoadProject(const FileName: string; Clear: Boolean);
    function DataName(Data: PProjectData): string;
    function ModelName(Data: PProjectData): string;
    procedure CreateDefaultProject;
    procedure PrepareProjectFolder(const FileName: string; Clear: Boolean);
    procedure LoadProjectParams(var LinkedID, ActiveID: Integer);
    procedure RecoverProjectTree(const ActiveID: Integer);
    procedure RecoverDataCurves(const LinkedID: integer);
    procedure CreateDataCurve(const Data: PProjectData);
    procedure CreateDummyStructure;
    procedure FinalizeCalc(Calc: TCalc);
    procedure GetThreadParams(var CD: TThreadParams);
    procedure PlotResults(Calc: TCalc);
    procedure PrintMax;
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
  System.IniFiles, System.DateUtils, unit_settings, unit_helpers, unit_consts, unit_XRCStructure, unit_XRCLayerControl, editor_Stack;

{$R *.dfm}

procedure TfrmMain.btnChartScaleClick(Sender: TObject);
begin
//  if (FActiveModel.Curve.Count = 0) and (FActiveData = nil) then
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
    if Data.Curve.Visible then
      TargetCanvas.Brush.Color := Data.Curve.Color
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

procedure TfrmMain.DataCopyClpbrdExecute(Sender: TObject);
begin
  SeriesToClipboard(FActiveData.Curve);
end;

procedure TfrmMain.DataExportExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
      SeriesToFile(FActiveData.Curve, dlgSaveResult.FileName);
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
  Data.Curve := TLineSeries.Create(Chart);
  Data.Curve.Title := Data.Title;
  Data.Color := Data.Curve.Color;
  Data.Curve.LinePen.Width := 2;

  SeriesFromFile(Data.Curve, dlgLoadData.FileName, Data.Description);
  Chart.AddSeries(Data.Curve);

  SeriesToFile(Data.Curve, DataName(Data));

  FActiveData := Data;
  Project.Expanded[FDataRoot] := True;

end;

function TfrmMain.DataName(Data: PProjectData): string;
begin
  Result := Format('%sdata_%d.dat', [FProjectDir, Data.ID])
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
  Data.Curve := TLineSeries.Create(Chart);
  Data.Curve.Title := Data.Title;
  Data.Color := Data.Curve.Color;
  Data.Curve.LinePen.Width := 2;
  Project.Expanded[FDataRoot] := True;

  SeriesFromClipboard(Data.Curve);
  Chart.AddSeries(Data.Curve);
  SeriesToFile(Data.Curve, DataName(Data));
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
  FActiveModel.Curve.BeginUpdate;

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
  if FActiveModel.Curve.Count = 0 then
    Exit;

  my := 0;
  x1 := Chart.BottomAxis.Minimum;
  x2 := Chart.BottomAxis.Maximum;
  RI := 0;
  OldX := FActiveModel.Curve.XValue[1];
  for i := 2 to FActiveModel.Curve.Count - 2 do
  begin
    X := FActiveModel.Curve.XValue[i];
    Y := FActiveModel.Curve.YValue[i];
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
  FActiveModel.Curve.Clear;
  for j := 0 to High(Calc.Results) do
      FActiveModel.Curve.AddXY(Calc.Results[j].t, Calc.Results[j].R);
end;

procedure TfrmMain.FinalizeCalc(Calc: TCalc);
var
  Hour, Min, Sec, MSec: Word;
begin
  PlotResults(Calc);
  DecodeTime(Now - StartTime, Hour, Min, Sec, MSec);
  spnTime.Caption := Format('Time: %d.%3.3d s.', [60 * Min + Sec, MSec]);
  FActiveModel.Curve.EndUpdate;
  FActiveModel.Curve.Repaint;
  StatusD.Caption := FloatToStrF(Calc.TotalD, ffFixed, 7, 2);
  Screen.Cursor := crDefault;
  CalcRun.Enabled := True;
  PrintMax;
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

    if (FLinkedData <> nil) and FActiveData.Curve.Visible then
       Calc.ExpValues := SeriesToData(FLinkedData.Curve);

    try
      Calc.Params := CD;
      Calc.Limit := StrToFloat(cbMinLimit.Text);
      Calc.Model := Structure.Model;
      Calc.Run;
    except
      on E: exception do
      begin
        ShowMessage(E.Message);
        FActiveModel.Curve.EndUpdate;
        FActiveModel.Curve.Repaint;
        Screen.Cursor := crDefault;
        CalcRun.Enabled := True;
      end;
    end;
    FinalizeCalc(Calc);
  finally
    Calc.Free;
  end;
end;

procedure TfrmMain.CreateDataCurve(const Data: PProjectData);
begin
  Data.Curve := TLineSeries.Create(Chart);
  Data.Curve.Title := Data.Title;
  Chart.AddSeries(Data.Curve);
  Data.Curve.Color := Data.Color;
  Data.Curve.LinePen.Width := 2;
  Data.Curve.Visible := Data.Visible;
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
      CreateDataCurve(Data);

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
end;

procedure TfrmMain.ResultCopyExecute(Sender: TObject);
begin
  SeriesToClipboard(FActiveModel.Curve);
end;

procedure TfrmMain.ResultSaveExecute(Sender: TObject);
begin
  if dlgSaveResult.Execute then
    SeriesToFile(FActiveModel.Curve, dlgSaveResult.FileName);
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

      CreateDataCurve(Data);
      SeriesFromFile(Data.Curve, DataName(Data), s);
      Chart.AddSeries(Data.Curve);
    end
    else
      Project.DeleteNode(Node);
    Node := Project.GetNext(Node);
  end;
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

end;

procedure TfrmMain.FileOpenExecute(Sender: TObject);
begin
  if dlgOpenProject.Execute then
  begin
    LoadProject(dlgOpenProject.FileName, True);
//    AddRecentItem(FProjectFileName , True);
  end;
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
  PD := Project.GetNodeData(PL);
  PD.ID := FLastID;
  inc(FLastID);
  PD.Title := 'Model 1';
  PD.Group := gtModel;
  PD.RowType := prItem;
  PD.Curve := TLineSeries.Create(Chart);
  Chart.AddSeries(PD.Curve);
  PD.Curve.Title := PD.Title;
  PD.Curve.Color := clRed;
  PD.Color := clRed;
  PD.Curve.LinePen.Width := 2;
  FActiveModel := PD; // делаем ее дефолтной


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
  Data1, Data2, Data3: TLayerData;
begin
  Data1.Material := 'Si';
  Data1.H := 28; Data1.s := 2.5; Data1.r := 2.3;

  Data2.Material := 'MoSi2';
  Data2.H := 10; Data2.s := 3; Data2.r := 6.2;

  Data3.Material := 'Mo';
  Data3.H := 28; Data3.s := 2.5; Data3.r := 10;

  Structure.AddStack(1, 'Top');
  Structure.AddLayer(0, Data1);

  Structure.AddStack(5, 'Main');
  Structure.AddLayer(1, Data2);
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
        if FileExists(ParamStr(1)) then
        begin
          FProjectFileName := Value;
          LoadProject(FProjectFileName, True);
        end
        else
          CreateDefaultProject;
     end;
     if FindCmdLineSwitch('d') then
     begin
       CreateDefaultProject;
       CreateDummyStructure;
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
