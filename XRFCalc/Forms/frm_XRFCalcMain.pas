unit frm_XRFCalcMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.IOUtils, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ExtCtrls, Vcl.ExtDlgs, Vcl.Menus,
  System.ImageList, Vcl.ImgList,
  RzSplit, RzPanel, RzStatus, RzTabs,
  unit_xrfx_package, unit_universal_types,
  xrfcalc_unit_loader, xrfcalc_unit_runner,
  frame_CurvesView, frame_InfoView,
  frame_ProgressView, frame_RunConfig;

type
  TfrmXRFCalcMain = class(TForm)
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
    mnuSave: TMenuItem;
    mnuSaveAs: TMenuItem;
    mnuFileSep1: TMenuItem;
    mnuExit: TMenuItem;
    mnuView: TMenuItem;
    mnuTools: TMenuItem;
    mnuRegisterExt: TMenuItem;
    mnuHelp: TMenuItem;
    mnuHelpContents: TMenuItem;
    StatusBar: TRzStatusBar;
    spStatus: TRzStatusPane;
    ToolBar1: TToolBar;
    ToolBarImages: TImageList;
    btnOpen: TToolButton;
    tbSep0: TToolButton;
    btnExportStructure: TToolButton;
    btnCopyData: TToolButton;
    btnSaveImage: TToolButton;
    tbSep1: TToolButton;
    btnNewRun: TToolButton;
    tbSep2: TToolButton;
    btnStop: TToolButton;
    MainSplitter: TRzSplitter;
    PageControl1: TRzPageControl;
    tabCurves: TRzTabSheet;
    tabInfo: TRzTabSheet;
    tabProgress: TRzTabSheet;
    dlgSave: TSaveDialog;
    dlgSaveImage: TSavePictureDialog;
    dlgOpen: TOpenDialog;
    mnuOpen: TMenuItem;
    mnuSaveConfig: TMenuItem;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure btnOpenClick(Sender: TObject);
    procedure btnExportStructureClick(Sender: TObject);
    procedure btnCopyDataClick(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure mnuOpenClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure mnuSaveAsClick(Sender: TObject);
    procedure mnuSaveConfigClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuRegisterExtClick(Sender: TObject);
    procedure mnuHelpContentsClick(Sender: TObject);
    procedure btnNewRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FLoader: TXRFCalcLoader;
    FRunner: TXRCRunner;
    FRunTimer: TTimer;
    FRunStartTime: TDateTime;
    FInitialPath: string;
    FInitialFile: string;
    FSavePath: string;
    FUnsaved: Boolean;
    FCurvesView: TframeCurvesView;
    FInfoView: TframeInfoView;
    FProgressView: TframeProgressView;
    FRunConfig: TfrmRunConfig;
    procedure ProcessFile(const FileName: string);
    procedure LoadToolBarIcons;
    function  GetIniPath: string;
    procedure LoadSettings;
    procedure SaveSettings;
    procedure WMDeferredNavigate(var Msg: TMessage); message WM_USER + 100;
    procedure HandleIteration(const Data: TRunnerIterationData);
    procedure HandleCompleted(const XRFXPath: string);
    procedure HandleError(const ErrorMsg: string);
    procedure HandleRawLine(const Line: string);
    procedure RunTimerTick(Sender: TObject);
    function  CheckUnsaved: Boolean;
    procedure UpdateRunState;
    procedure StartRun(const ConfigPath: string; MaxIterations: Integer);
    procedure LoadConfigFromXRFX(const FileName: string);
  end;

var
  frmXRFCalcMain: TfrmXRFCalcMain;

implementation

uses
  System.Win.Registry, System.IniFiles, Winapi.ShlObj, Winapi.ShellAPI,
  ClipBrd, Vcl.Imaging.pngimage,
  unit_universal_io;

{$R *.dfm}

procedure RegisterFileType(const Ext, Description, ExePath: string);
var
  Reg: TRegistry;
begin
  Reg := TRegistry.Create;
  try
    Reg.RootKey := HKEY_CURRENT_USER;

    Reg.OpenKey('Software\Classes\.' + Ext, True);
    Reg.WriteString('', Ext + 'file');
    Reg.CloseKey;

    Reg.OpenKey('Software\Classes\' + Ext + 'file', True);
    Reg.WriteString('', Description);
    Reg.CloseKey;

    Reg.OpenKey('Software\Classes\' + Ext + 'file\DefaultIcon', True);
    Reg.WriteString('', ExePath + ',0');
    Reg.CloseKey;

    Reg.OpenKey('Software\Classes\' + Ext + 'file\shell\open\command', True);
    Reg.WriteString('', '"' + ExePath + '" "%1"');
    Reg.CloseKey;
  finally
    Reg.Free;
  end;
end;

procedure TfrmXRFCalcMain.LoadToolBarIcons;
const
  ResNames: array[0..5] of string = (
    'ICON_OPEN', 'ICON_EXPORT', 'ICON_COPY', 'ICON_SAVEIMG',
    'ICON_NEWRUN', 'ICON_STOP');
var
  i: Integer;
  RS: TResourceStream;
  PNG: TPngImage;
  Bmp: TBitmap;
begin
  ToolBarImages.Clear;
  for i := 0 to High(ResNames) do
  begin
    if FindResource(HInstance, PChar(ResNames[i]), RT_RCDATA) = 0 then Continue;
    RS := TResourceStream.Create(HInstance, ResNames[i], RT_RCDATA);
    PNG := TPngImage.Create;
    Bmp := TBitmap.Create;
    try
      PNG.LoadFromStream(RS);
      Bmp.SetSize(ToolBarImages.Width, ToolBarImages.Height);
      Bmp.Canvas.Brush.Color := clBtnFace;
      Bmp.Canvas.FillRect(Rect(0, 0, Bmp.Width, Bmp.Height));
      Bmp.Canvas.Draw(0, 0, PNG);
      ToolBarImages.Add(Bmp, nil);
    finally
      Bmp.Free;
      PNG.Free;
      RS.Free;
    end;
  end;
end;

procedure TfrmXRFCalcMain.FormCreate(Sender: TObject);
begin
  FLoader := TXRFCalcLoader.Create;
  LoadToolBarIcons;

  FCurvesView := TframeCurvesView.Create(Self);
  FCurvesView.Parent := tabCurves;
  FCurvesView.Align := alClient;

  FInfoView := TframeInfoView.Create(Self);
  FInfoView.Parent := tabInfo;
  FInfoView.Align := alClient;

  FProgressView := TframeProgressView.Create(Self);
  FProgressView.Parent := tabProgress;
  FProgressView.Align := alClient;

  FRunConfig := TfrmRunConfig.Create(Self);
  FRunConfig.Parent := MainSplitter;
  FRunConfig.Align := alClient;
  FRunConfig.SetDefaults;

  FRunner := TXRCRunner.Create;
  FRunner.OnIteration := HandleIteration;
  FRunner.OnCompleted := HandleCompleted;
  FRunner.OnError := HandleError;
  FRunner.OnRawLine := HandleRawLine;

  FRunTimer := TTimer.Create(Self);
  FRunTimer.Interval := 100;
  FRunTimer.Enabled := False;
  FRunTimer.OnTimer := RunTimerTick;

  LoadSettings;
  if (ParamCount > 0) and TFile.Exists(ParamStr(1)) then
  begin
    FInitialFile := ParamStr(1);
    FInitialPath := ExtractFilePath(ParamStr(1));
  end;

  if FInitialFile <> '' then
    PostMessage(Handle, WM_USER + 100, 0, 0);
end;

procedure TfrmXRFCalcMain.FormDestroy(Sender: TObject);
begin
  if FRunner.State = rsRunning then
    FRunner.Cancel;
  FreeAndNil(FRunner);
  FreeAndNil(FLoader);
end;

procedure TfrmXRFCalcMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if not CheckUnsaved then
  begin
    Action := caNone;
    Exit;
  end;
  SaveSettings;
end;

procedure TfrmXRFCalcMain.ProcessFile(const FileName: string);
begin
  try
    FLoader.LoadFile(FileName);
    FSavePath := FileName;
    FUnsaved := False;

    FCurvesView.LoadCurves(FLoader.GetResult(0).Curves);
    FCurvesView.LoadStructure(FLoader.GetResult(0).Structure,
      FLoader.Manifest.Structure);
    FInfoView.LoadManifestInfo(FLoader.Manifest);
    FCurvesView.LoadMetrics(FLoader.Manifest, FLoader.GetResult(0).Curves);
    FProgressView.LoadProgress(FLoader.GetResult(0).Progress);

    spStatus.Caption := Format('FoM: %.6f  |  %s',
      [FLoader.Manifest.FoM, ExtractFileName(FileName)]);
  except
    on E: Exception do
      spStatus.Caption := 'Error: ' + E.Message;
  end;
end;

procedure TfrmXRFCalcMain.btnExportStructureClick(Sender: TObject);
begin
  if not FLoader.IsLoaded then Exit;
  dlgSave.DefaultExt := '.json';
  dlgSave.Filter := 'JSON structure|*.json';
  dlgSave.FileName := 'best_structure_xrc.json';
  if dlgSave.Execute then
    FLoader.ExtractFile('best_structure_xrc.json', dlgSave.FileName);
end;

procedure TfrmXRFCalcMain.btnCopyDataClick(Sender: TObject);
var
  Lines: TStringList;
  i, j: Integer;
  R: TLoadedResult;
begin
  if not FLoader.IsLoaded then Exit;
  R := FLoader.GetResult(0);
  Lines := TStringList.Create;
  try
    for i := 0 to High(R.Curves) do
    begin
      Lines.Add('# ' + R.Curves[i].Element);
      for j := 0 to High(R.Curves[i].Theta) do
        Lines.Add(Format('%.4f'#9'%.8e', [R.Curves[i].Theta[j], R.Curves[i].Refl[j]]));
      Lines.Add('');
    end;
    Clipboard.AsText := Lines.Text;
  finally
    Lines.Free;
  end;
end;

procedure TfrmXRFCalcMain.btnSaveImageClick(Sender: TObject);
begin
  if dlgSaveImage.Execute then
  begin
    if PageControl1.ActivePage = tabCurves then
      FCurvesView.chrtCurves.SaveToBitmapFile(dlgSaveImage.FileName)
    else if PageControl1.ActivePage = tabProgress then
      FProgressView.chrtProgress.SaveToBitmapFile(dlgSaveImage.FileName);
  end;
end;

procedure TfrmXRFCalcMain.mnuSaveClick(Sender: TObject);
var
  SrcPath, DestPath: string;
begin
  if not FLoader.IsLoaded then Exit;
  SrcPath := FLoader.GetResult(0).FileName;

  if FSavePath <> '' then
    DestPath := FSavePath
  else
  begin
    mnuSaveAsClick(Sender);
    Exit;
  end;

  if not SameText(SrcPath, DestPath) then
    TFile.Copy(SrcPath, DestPath, True);
  FSavePath := DestPath;
  FUnsaved := False;
  spStatus.Caption := 'Saved: ' + ExtractFileName(DestPath);
end;

procedure TfrmXRFCalcMain.mnuSaveAsClick(Sender: TObject);
var
  SrcPath: string;
begin
  if not FLoader.IsLoaded then Exit;
  SrcPath := FLoader.GetResult(0).FileName;

  dlgSave.DefaultExt := '.xrfx';
  dlgSave.Filter := 'XRFX package|*.xrfx';
  dlgSave.InitialDir := ExtractFilePath(FSavePath);
  dlgSave.FileName := ExtractFileName(SrcPath);
  if dlgSave.Execute then
  begin
    if not SameText(SrcPath, dlgSave.FileName) then
      TFile.Copy(SrcPath, dlgSave.FileName, True);
    FSavePath := dlgSave.FileName;
    FUnsaved := False;
    spStatus.Caption := 'Saved: ' + ExtractFileName(dlgSave.FileName);
  end;
end;

procedure TfrmXRFCalcMain.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmXRFCalcMain.mnuRegisterExtClick(Sender: TObject);
begin
  RegisterFileType('xrfx', 'XRFCalc Package', Application.ExeName);
  SHChangeNotify(SHCNE_ASSOCCHANGED, SHCNF_IDLIST, nil, nil);
  spStatus.Caption := '.xrfx extension registered';
end;

procedure TfrmXRFCalcMain.mnuHelpContentsClick(Sender: TObject);
var
  HelpPath: string;
begin
  HelpPath := TPath.Combine(ExtractFilePath(Application.ExeName), 'Help\index.html');
  if TFile.Exists(HelpPath) then
    ShellExecute(Handle, 'open', PChar(HelpPath), nil, nil, SW_SHOWNORMAL)
  else
    spStatus.Caption := 'Help not found: ' + HelpPath;
end;

function TfrmXRFCalcMain.GetIniPath: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

procedure TfrmXRFCalcMain.LoadSettings;
var
  Ini: TIniFile;
  Path: string;
  V: Integer;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    Path := Ini.ReadString('General', 'LastFolder', '');
    if (Path <> '') and TDirectory.Exists(Path) then
      FInitialPath := Path;

    V := Ini.ReadInteger('Window', 'State', 0);
    if V = Ord(wsMaximized) then
      WindowState := wsMaximized;

    V := Ini.ReadInteger('Splitters', 'MainPct', 0);
    if V > 0 then MainSplitter.Percent := V;

    V := Ini.ReadInteger('Splitters', 'Metrics', 0);
    if V > 0 then FCurvesView.pnlMetrics.Height := V;

    V := Ini.ReadInteger('Splitters', 'ProgressChart', 0);
    if V > 0 then FProgressView.pnlChart.Height := V;
  finally
    Ini.Free;
  end;
end;

procedure TfrmXRFCalcMain.WMDeferredNavigate(var Msg: TMessage);
begin
  if (FInitialFile <> '') and TFile.Exists(FInitialFile) then
  begin
    ProcessFile(FInitialFile);
    LoadConfigFromXRFX(FInitialFile);
  end;
end;

procedure TfrmXRFCalcMain.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    if FSavePath <> '' then
      Ini.WriteString('General', 'LastFolder', ExtractFilePath(FSavePath))
    else if FInitialPath <> '' then
      Ini.WriteString('General', 'LastFolder', FInitialPath);
    Ini.WriteInteger('Splitters', 'MainPct', MainSplitter.Percent);
    Ini.WriteInteger('Splitters', 'Metrics', FCurvesView.pnlMetrics.Height);
    Ini.WriteInteger('Splitters', 'ProgressChart', FProgressView.pnlChart.Height);
    Ini.WriteInteger('Window', 'State', Ord(WindowState));
  finally
    Ini.Free;
  end;
end;

{ --- Runner Integration --- }

procedure TfrmXRFCalcMain.RunTimerTick(Sender: TObject);
begin
  FRunner.Poll;
end;

procedure TfrmXRFCalcMain.HandleIteration(const Data: TRunnerIterationData);
var
  Elapsed: TDateTime;
  Min, Sec: Integer;
begin
  FProgressView.AddIteration(Data);
  Elapsed := Now - FRunStartTime;
  Min := Trunc(Elapsed * 24 * 60);
  Sec := Trunc(Elapsed * 24 * 3600) mod 60;
  spStatus.Caption := Format('Running... Iteration %d | FoM: %.4f | %d:%02d',
    [Data.Iteration, Data.FoM, Min, Sec]);
end;

procedure TfrmXRFCalcMain.HandleCompleted(const XRFXPath: string);
var
  OutputDir: string;
begin
  FRunTimer.Enabled := False;
  FProgressView.SetStaticMode;
  UpdateRunState;

  // Clean up intermediate output_dir only (keep .xrfx for Save/Save As)
  OutputDir := TPath.Combine(ExtractFilePath(FRunner.ConfigPath), TEMP_OUTPUT_DIR);
  if TDirectory.Exists(OutputDir) then
    TDirectory.Delete(OutputDir, True);

  // Load the .xrfx from temp (keep live progress chart)
  if TFile.Exists(XRFXPath) then
  begin
    try
      FLoader.LoadFile(XRFXPath);
      FCurvesView.LoadCurves(FLoader.GetResult(0).Curves);
      FCurvesView.LoadStructure(FLoader.GetResult(0).Structure,
        FLoader.Manifest.Structure);
      FInfoView.LoadManifestInfo(FLoader.Manifest);
      FCurvesView.LoadMetrics(FLoader.Manifest, FLoader.GetResult(0).Curves);
      FUnsaved := True;
      spStatus.Caption := Format('FoM: %.6f  |  Unsaved — use File > Save',
        [FLoader.Manifest.FoM]);
    except
      on E: Exception do
        spStatus.Caption := 'Error: ' + E.Message;
    end;
  end;
end;

procedure TfrmXRFCalcMain.HandleError(const ErrorMsg: string);
begin
  FRunTimer.Enabled := False;
  FProgressView.SetStaticMode;
  UpdateRunState;
  spStatus.Caption := 'Error: ' + ErrorMsg;
end;

procedure TfrmXRFCalcMain.HandleRawLine(const Line: string);
begin
  FProgressView.AppendLog(Line);
end;

function TfrmXRFCalcMain.CheckUnsaved: Boolean;
begin
  if not FUnsaved then
    Exit(True);
  Result := MessageDlg('Current results have not been saved. Discard them?',
    mtConfirmation, [mbYes, mbNo], 0) = mrYes;
end;

procedure TfrmXRFCalcMain.UpdateRunState;
var
  Running: Boolean;
begin
  Running := FRunner.State = rsRunning;
  btnNewRun.Enabled := not Running;
  btnStop.Visible := Running;
end;

procedure TfrmXRFCalcMain.StartRun(const ConfigPath: string; MaxIterations: Integer);
begin
  PageControl1.ActivePage := tabProgress;
  FProgressView.SetLiveMode(MaxIterations);
  FRunStartTime := Now;

  try
    FRunner.Start(ConfigPath);
    FRunTimer.Enabled := True;
    UpdateRunState;
    spStatus.Caption := 'Starting optimization...';
  except
    on E: Exception do
    begin
      FProgressView.SetStaticMode;
      UpdateRunState;
      spStatus.Caption := 'Error: ' + E.Message;
    end;
  end;
end;

procedure TfrmXRFCalcMain.btnNewRunClick(Sender: TObject);
var
  Config: TUniversalConfig;
  ConfigPath, RunTempDir: string;
begin
  Config := FRunConfig.BuildConfig;
  RunTempDir := TPath.Combine(TPath.GetTempPath, 'XRFCalc\run_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(RunTempDir);
  Config.OutputDir := TPath.Combine(RunTempDir, TEMP_OUTPUT_DIR);
  ConfigPath := TPath.Combine(RunTempDir,
    'xrfcalc_' + FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '.json');
  TUniversalIO.SaveConfig(Config, ConfigPath);
  FSavePath := '';
  StartRun(ConfigPath, Config.Optimizer.Iterations);
end;

procedure TfrmXRFCalcMain.btnOpenClick(Sender: TObject);
begin
  if not CheckUnsaved then Exit;
  if FInitialPath <> '' then
    dlgOpen.InitialDir := FInitialPath;
  if dlgOpen.Execute then
  begin
    ProcessFile(dlgOpen.FileName);
    LoadConfigFromXRFX(dlgOpen.FileName);
    FInitialPath := ExtractFilePath(dlgOpen.FileName);
  end;
end;

procedure TfrmXRFCalcMain.mnuOpenClick(Sender: TObject);
begin
  btnOpenClick(Sender);
end;

procedure TfrmXRFCalcMain.mnuSaveConfigClick(Sender: TObject);
var
  Dlg: TSaveDialog;
  Config: TUniversalConfig;
begin
  Dlg := TSaveDialog.Create(Self);
  try
    Dlg.Filter := 'JSON config|*.json';
    Dlg.DefaultExt := 'json';
    if Dlg.Execute then
    begin
      Config := FRunConfig.BuildConfig;
      TUniversalIO.SaveConfig(Config, Dlg.FileName);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmXRFCalcMain.LoadConfigFromXRFX(const FileName: string);
var
  TempDir, ConfigJsonPath: string;
  Config: TUniversalConfig;
begin
  TempDir := FLoader.GetResult(0).TempDir;
  ConfigJsonPath := TPath.Combine(TempDir, 'config.json');
  if TFile.Exists(ConfigJsonPath) then
  begin
    Config := TUniversalIO.LoadConfig(ConfigJsonPath);
    FRunConfig.LoadFromConfig(Config);
  end
  else
    FRunConfig.SetDefaults;
end;

procedure TfrmXRFCalcMain.btnStopClick(Sender: TObject);
begin
  FRunner.Cancel;
  FRunTimer.Enabled := False;
  FProgressView.SetStaticMode;
  UpdateRunState;
  spStatus.Caption := 'Run cancelled';
end;

end.
