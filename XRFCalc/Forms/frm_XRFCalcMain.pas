unit frm_XRFCalcMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.IOUtils, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ExtCtrls, Vcl.ExtDlgs, Vcl.Menus,
  System.ImageList, Vcl.ImgList,
  RzSplit, RzPanel, RzStatus, RzTabs,
  JamShellBreadCrumbBar, ShellControls, ShellLink,
  Jam.Shell.Types, Jam.Shell.Controls.Types,
  Jam.Shell.Controls.BaseShellListView,
  unit_xrfx_package, unit_universal_types,
  xrfcalc_unit_loader, xrfcalc_unit_runner,
  frame_CurvesView, frame_InfoView,
  frame_ProgressView, frame_CompareView;

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
    StatusBar: TRzStatusBar;
    spStatus: TRzStatusPane;
    ToolBar1: TToolBar;
    ToolBarImages: TImageList;
    btnRefresh: TToolButton;
    btnExportStructure: TToolButton;
    btnCopyData: TToolButton;
    btnSaveImage: TToolButton;
    tbSep1: TToolButton;
    btnNewRun: TToolButton;
    btnEditRun: TToolButton;
    tbSep2: TToolButton;
    btnStop: TToolButton;
    MainSplitter: TRzSplitter;
    ShellSplitter: TRzSplitter;
    ShellTree: TJamShellTree;
    ShellList: TJamShellList;
    JamShellLink1: TJamShellLink;
    JamShellBreadCrumbBar1: TJamShellBreadCrumbBar;
    PageControl1: TRzPageControl;
    tabCurves: TRzTabSheet;
    tabInfo: TRzTabSheet;
    tabProgress: TRzTabSheet;
    tabCompare: TRzTabSheet;
    dlgSave: TSaveDialog;
    dlgSaveImage: TSavePictureDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure ShellListSelectItem(Sender: TObject; Item: TListItem;
      Selected: Boolean);
    procedure btnRefreshClick(Sender: TObject);
    procedure btnExportStructureClick(Sender: TObject);
    procedure btnCopyDataClick(Sender: TObject);
    procedure btnSaveImageClick(Sender: TObject);
    procedure mnuSaveClick(Sender: TObject);
    procedure mnuSaveAsClick(Sender: TObject);
    procedure mnuExitClick(Sender: TObject);
    procedure mnuRegisterExtClick(Sender: TObject);
    procedure btnNewRunClick(Sender: TObject);
    procedure btnEditRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
  private
    FLoader: TXRFCalcLoader;
    FRunner: TXRCRunner;
    FRunTimer: TTimer;
    FRunStartTime: TDateTime;
    FInitialPath: string;
    FSavePath: string;
    FUnsaved: Boolean;
    FCurvesView: TframeCurvesView;
    FInfoView: TframeInfoView;
    FProgressView: TframeProgressView;
    FCompareView: TframeCompareView;
    procedure ProcessFile(const FileName: string);
    procedure ProcessMultipleFiles(const FileNames: TArray<string>);
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
  end;

var
  frmXRFCalcMain: TfrmXRFCalcMain;

implementation

uses
  System.Win.Registry, System.IniFiles, ClipBrd, Vcl.Imaging.pngimage,
  frm_RunConfig, unit_universal_io;

{$R *.dfm}

procedure RegisterFileType(const Prefix, ExePath: string);
begin
  with TRegistry.Create do
  try
    RootKey := HKEY_CURRENT_USER;
    OpenKey('Software\Classes\.' + Prefix, True);
    WriteString('', Prefix + 'file');
    CloseKey;
    CreateKey('Software\Classes\' + Prefix + 'file');
    OpenKey('Software\Classes\' + Prefix + 'file\DefaultIcon', True);
    WriteString('', ExePath + ',0');
    CloseKey;
    OpenKey('Software\Classes\' + Prefix + 'file\shell\open\command', True);
    WriteString('', '"' + ExePath + '" "%1"');
    CloseKey;
  finally
    Free;
  end;
end;

procedure TfrmXRFCalcMain.LoadToolBarIcons;
const
  ResNames: array[0..6] of string = (
    'ICON_REFRESH', 'ICON_EXPORT', 'ICON_COPY', 'ICON_SAVEIMG',
    'ICON_NEWRUN', 'ICON_EDITRUN', 'ICON_STOP');
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

  FCompareView := TframeCompareView.Create(Self);
  FCompareView.Parent := tabCompare;
  FCompareView.Align := alClient;

  tabCompare.TabVisible := False;

  FRunner := TXRCRunner.Create;
  FRunner.OnIteration := HandleIteration;
  FRunner.OnCompleted := HandleCompleted;
  FRunner.OnError := HandleError;
  FRunner.OnRawLine := HandleRawLine;

  FRunTimer := TTimer.Create(Self);
  FRunTimer.Interval := 100;
  FRunTimer.Enabled := False;
  FRunTimer.OnTimer := RunTimerTick;

  if (ParamCount > 0) and TFile.Exists(ParamStr(1)) then
    FInitialPath := ExtractFilePath(ParamStr(1))
  else
    LoadSettings;

  if FInitialPath <> '' then
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

procedure TfrmXRFCalcMain.ShellListSelectItem(Sender: TObject;
  Item: TListItem; Selected: Boolean);
var
  FileName: string;
  SelectedFiles: TArray<string>;
  i: Integer;
begin
  if Item = nil then Exit;

  SetLength(SelectedFiles, 0);
  for i := 0 to ShellList.Items.Count - 1 do
  begin
    if ShellList.Items[i].Selected then
    begin
      FileName := IncludeTrailingPathDelimiter(ShellList.Path) +
        ShellList.Items[i].Caption;
      if SameText(ExtractFileExt(FileName), XRFX_EXT) and
         TFile.Exists(FileName) then
      begin
        SetLength(SelectedFiles, Length(SelectedFiles) + 1);
        SelectedFiles[High(SelectedFiles)] := FileName;
      end;
    end;
  end;

  if Length(SelectedFiles) = 0 then Exit;
  if not CheckUnsaved then Exit;

  try
    Screen.Cursor := crHourGlass;
    if Length(SelectedFiles) = 1 then
      ProcessFile(SelectedFiles[0])
    else
      ProcessMultipleFiles(SelectedFiles);
  finally
    Screen.Cursor := crDefault;
  end;
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

    tabCompare.TabVisible := False;
    spStatus.Caption := Format('FoM: %.6f  |  %s',
      [FLoader.Manifest.FoM, ExtractFileName(FileName)]);
  except
    on E: Exception do
      spStatus.Caption := 'Error: ' + E.Message;
  end;
end;

procedure TfrmXRFCalcMain.ProcessMultipleFiles(const FileNames: TArray<string>);
var
  Manifests: TArray<TXRFXManifest>;
  i: Integer;
begin
  try
    FLoader.LoadMultiple(FileNames);

    FInfoView.LoadManifestInfo(FLoader.Manifest);
    FProgressView.LoadProgress(FLoader.GetResult(0).Progress);

    FCurvesView.Clear;
    for i := 0 to FLoader.ResultCount - 1 do
      FCurvesView.AddCurves(FLoader.GetResult(i).Curves,
        ExtractFileName(FLoader.GetResult(i).FileName));

    SetLength(Manifests, FLoader.ResultCount);
    for i := 0 to FLoader.ResultCount - 1 do
      Manifests[i] := FLoader.GetResult(i).Manifest;

    FCompareView.LoadComparison(Manifests, FileNames);
    tabCompare.TabVisible := True;

    spStatus.Caption := Format('%d files compared', [FLoader.ResultCount]);
  except
    on E: Exception do
      spStatus.Caption := 'Error: ' + E.Message;
  end;
end;

procedure TfrmXRFCalcMain.btnRefreshClick(Sender: TObject);
begin
  ShellTree.FullRefresh;
  ShellList.FullRefresh;
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
    // No save path yet — default to working directory
    DestPath := TPath.Combine(ShellList.Path,
      ExtractFileName(SrcPath));
  end;

  if not SameText(SrcPath, DestPath) then
    TFile.Copy(SrcPath, DestPath, True);
  FSavePath := DestPath;
  FUnsaved := False;
  ShellList.FullRefresh;
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
  dlgSave.InitialDir := ShellList.Path;
  dlgSave.FileName := ExtractFileName(SrcPath);
  if dlgSave.Execute then
  begin
    if not SameText(SrcPath, dlgSave.FileName) then
      TFile.Copy(SrcPath, dlgSave.FileName, True);
    FSavePath := dlgSave.FileName;
    FUnsaved := False;
    ShellList.FullRefresh;
    spStatus.Caption := 'Saved: ' + ExtractFileName(dlgSave.FileName);
  end;
end;

procedure TfrmXRFCalcMain.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmXRFCalcMain.mnuRegisterExtClick(Sender: TObject);
begin
  RegisterFileType('xrfx', Application.ExeName);
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

    V := Ini.ReadInteger('Splitters', 'ShellPct', 0);
    if V > 0 then ShellSplitter.Percent := V;

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
  if (FInitialPath <> '') and TDirectory.Exists(FInitialPath) then
    ShellList.Path := FInitialPath;
end;

procedure TfrmXRFCalcMain.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    Ini.WriteString('General', 'LastFolder', ShellList.Path);
    Ini.WriteInteger('Splitters', 'MainPct', MainSplitter.Percent);
    Ini.WriteInteger('Splitters', 'ShellPct', ShellSplitter.Percent);
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
      tabCompare.TabVisible := False;
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
  btnEditRun.Enabled := not Running;
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
  Dlg: TfrmRunConfig;
  Config: TUniversalConfig;
  ConfigPath, RunTempDir: string;
begin
  Dlg := TfrmRunConfig.Create(Self);
  try
    Dlg.SetDefaults;
    if Dlg.ShowModal = mrOk then
    begin
      Config := Dlg.BuildConfig;

      // Use system temp for config and output
      RunTempDir := TPath.Combine(TPath.GetTempPath, 'XRFCalc\run_' + TGUID.NewGuid.ToString);
      TDirectory.CreateDirectory(RunTempDir);
      Config.OutputDir := TPath.Combine(RunTempDir, TEMP_OUTPUT_DIR);

      ConfigPath := TPath.Combine(RunTempDir,
        'xrfcalc_' + FormatDateTime('yyyy-mm-dd_hhnnss', Now) + '.json');
      TUniversalIO.SaveConfig(Config, ConfigPath);

      FSavePath := '';
      StartRun(ConfigPath, Config.Optimizer.Iterations);
    end;
  finally
    Dlg.Free;
  end;
end;

procedure TfrmXRFCalcMain.btnEditRunClick(Sender: TObject);
var
  ConfigJsonPath, TempDir, RunTempDir: string;
  Config: TUniversalConfig;
  Dlg: TfrmRunConfig;
  ConfigPath: string;
begin
  if not FLoader.IsLoaded then
  begin
    spStatus.Caption := 'Select an .xrfx file first';
    Exit;
  end;

  TempDir := FLoader.GetResult(0).TempDir;
  ConfigJsonPath := TPath.Combine(TempDir, 'config.json');

  if not TFile.Exists(ConfigJsonPath) then
  begin
    spStatus.Caption := 'No config.json found in this .xrfx package';
    Exit;
  end;

  Config := TUniversalIO.LoadConfig(ConfigJsonPath);

  Dlg := TfrmRunConfig.Create(Self);
  try
    Dlg.LoadFromConfig(Config);
    if Dlg.ShowModal = mrOk then
    begin
      Config := Dlg.BuildConfig;

      // Use system temp for config and output
      RunTempDir := TPath.Combine(TPath.GetTempPath, 'XRFCalc\run_' + TGUID.NewGuid.ToString);
      TDirectory.CreateDirectory(RunTempDir);
      Config.OutputDir := TPath.Combine(RunTempDir, TEMP_OUTPUT_DIR);

      ConfigPath := TPath.Combine(RunTempDir, 'xrfcalc_run.json');
      TUniversalIO.SaveConfig(Config, ConfigPath);

      // FSavePath stays as the original file — Save will overwrite it
      StartRun(ConfigPath, Config.Optimizer.Iterations);
    end;
  finally
    Dlg.Free;
  end;
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
