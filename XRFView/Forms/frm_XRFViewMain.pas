unit frm_XRFViewMain;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes,
  System.IOUtils, System.Generics.Collections,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ComCtrls,
  Vcl.ToolWin, Vcl.ExtCtrls, Vcl.ExtDlgs, Vcl.Menus,
  System.ImageList, Vcl.ImgList,
  RzSplit, RzPanel, RzStatus,
  JamShellBreadCrumbBar, ShellControls, ShellLink,
  Jam.Shell.Types, Jam.Shell.Controls.Types,
  Jam.Shell.Controls.BaseShellListView,
  unit_xrfx_package, unit_universal_types,
  xrfview_unit_loader,
  frame_StructureView, frame_CurvesView, frame_InfoView,
  frame_ProgressView, frame_CompareView;

type
  TfrmXRFViewMain = class(TForm)
    MainMenu1: TMainMenu;
    mnuFile: TMenuItem;
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
    MainSplitter: TRzSplitter;
    ShellSplitter: TRzSplitter;
    ShellTree: TJamShellTree;
    ShellList: TJamShellList;
    JamShellLink1: TJamShellLink;
    JamShellBreadCrumbBar1: TJamShellBreadCrumbBar;
    PageControl1: TPageControl;
    tabStructure: TTabSheet;
    tabCurves: TTabSheet;
    tabInfo: TTabSheet;
    tabProgress: TTabSheet;
    tabCompare: TTabSheet;
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
    procedure mnuExitClick(Sender: TObject);
    procedure mnuRegisterExtClick(Sender: TObject);
  private
    FLoader: TXRFViewLoader;
    FStructureView: TframeStructureView;
    FCurvesView: TframeCurvesView;
    FInfoView: TframeInfoView;
    FProgressView: TframeProgressView;
    FCompareView: TframeCompareView;
    procedure ProcessFile(const FileName: string);
    procedure ProcessMultipleFiles(const FileNames: TArray<string>);
    function  GetIniPath: string;
    procedure LoadSettings;
    procedure SaveSettings;
  end;

var
  frmXRFViewMain: TfrmXRFViewMain;

implementation

uses
  System.Win.Registry, System.IniFiles, ClipBrd;

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

procedure TfrmXRFViewMain.FormCreate(Sender: TObject);
begin
  FLoader := TXRFViewLoader.Create;

  FStructureView := TframeStructureView.Create(Self);
  FStructureView.Parent := tabStructure;
  FStructureView.Align := alClient;

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

  if (ParamCount > 0) and TFile.Exists(ParamStr(1)) then
    ShellList.Path := ExtractFilePath(ParamStr(1))
  else
    LoadSettings;
end;

procedure TfrmXRFViewMain.FormDestroy(Sender: TObject);
begin
  FreeAndNil(FLoader);
end;

procedure TfrmXRFViewMain.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  SaveSettings;
  Application.Terminate;
end;

procedure TfrmXRFViewMain.ShellListSelectItem(Sender: TObject;
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

procedure TfrmXRFViewMain.ProcessFile(const FileName: string);
begin
  try
    FLoader.LoadFile(FileName);

    FStructureView.LoadStructure(FLoader.GetResult(0).Structure,
      FLoader.Manifest.Structure);
    FCurvesView.LoadCurves(FLoader.GetResult(0).Curves);
    FInfoView.LoadManifestInfo(FLoader.Manifest);
    FProgressView.LoadProgress(FLoader.GetResult(0).Progress);

    tabCompare.TabVisible := False;
    spStatus.Caption := Format('FoM: %.6f  |  %s',
      [FLoader.Manifest.FoM, ExtractFileName(FileName)]);
  except
    on E: Exception do
      spStatus.Caption := 'Error: ' + E.Message;
  end;
end;

procedure TfrmXRFViewMain.ProcessMultipleFiles(const FileNames: TArray<string>);
var
  Manifests: TArray<TXRFXManifest>;
  i: Integer;
begin
  try
    FLoader.LoadMultiple(FileNames);

    FStructureView.LoadStructure(FLoader.GetResult(0).Structure,
      FLoader.Manifest.Structure);
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

procedure TfrmXRFViewMain.btnRefreshClick(Sender: TObject);
begin
  ShellTree.FullRefresh;
  ShellList.FullRefresh;
end;

procedure TfrmXRFViewMain.btnExportStructureClick(Sender: TObject);
begin
  if not FLoader.IsLoaded then Exit;
  dlgSave.DefaultExt := '.json';
  dlgSave.Filter := 'JSON structure|*.json';
  dlgSave.FileName := 'best_structure_xrc.json';
  if dlgSave.Execute then
    FLoader.ExtractFile('best_structure_xrc.json', dlgSave.FileName);
end;

procedure TfrmXRFViewMain.btnCopyDataClick(Sender: TObject);
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

procedure TfrmXRFViewMain.btnSaveImageClick(Sender: TObject);
begin
  if dlgSaveImage.Execute then
  begin
    if PageControl1.ActivePage = tabCurves then
      FCurvesView.chrtCurves.SaveToBitmapFile(dlgSaveImage.FileName)
    else if PageControl1.ActivePage = tabProgress then
      FProgressView.chrtProgress.SaveToBitmapFile(dlgSaveImage.FileName);
  end;
end;

procedure TfrmXRFViewMain.mnuExitClick(Sender: TObject);
begin
  Close;
end;

procedure TfrmXRFViewMain.mnuRegisterExtClick(Sender: TObject);
begin
  RegisterFileType('xrfx', Application.ExeName);
end;

function TfrmXRFViewMain.GetIniPath: string;
begin
  Result := ChangeFileExt(Application.ExeName, '.ini');
end;

procedure TfrmXRFViewMain.LoadSettings;
var
  Ini: TIniFile;
  Path: string;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    Path := Ini.ReadString('General', 'LastFolder', '');
    if (Path <> '') and TDirectory.Exists(Path) then
      ShellList.Path := Path;
  finally
    Ini.Free;
  end;
end;

procedure TfrmXRFViewMain.SaveSettings;
var
  Ini: TIniFile;
begin
  Ini := TIniFile.Create(GetIniPath);
  try
    Ini.WriteString('General', 'LastFolder', ShellList.Path);
  finally
    Ini.Free;
  end;
end;

end.
