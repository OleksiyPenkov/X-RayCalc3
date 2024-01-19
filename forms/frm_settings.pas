(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)


unit frm_settings;

interface

uses
  Windows,
  Messages,
  SysUtils,
  Variants,
  Classes,
  Graphics,
  Controls,
  Forms,
  Dialogs,
  StdCtrls,
  Mask,
  ExtCtrls,
  ComCtrls,
  ImgList,
  unit_AutoCompleteEdit,
  RzPanel, Vcl.Samples.Spin, RzEdit, RzBtnEdt, MHLButtonedEdit, RzShellDialogs;

type
  TfrmSettings = class(TForm)
    pcSetPages: TPageControl;
    tsPaths: TTabSheet;
    dlgColors: TColorDialog;
    tvSections: TTreeView;
    tsBehavour: TTabSheet;
    pnButtons: TPanel;
    btnOk: TButton;
    btnCancel: TButton;
    btnHelp: TButton;
    Panel3: TPanel;
    Label6: TLabel;
    chkCheckForUpdates: TCheckBox;
    tsInterface: TTabSheet;
    Label3: TLabel;
    lbl1: TLabel;
    tsCalc: TTabSheet;
    lbl2: TLabel;
    chkAutoCalcOpen: TCheckBox;
    tsGraphics: TTabSheet;
    lbl3: TLabel;
    chkAutoSaveResults: TCheckBox;
    rzpnl1: TRzPanel;
    Label4: TLabel;
    RzPanel1: TRzPanel;
    Label1: TLabel;
    cbbCPUCores: TComboBox;
    RzPanel2: TRzPanel;
    Label2: TLabel;
    seLineWidth: TSpinEdit;
    edProjectDir: TRzButtonEdit;
    RzPanel3: TRzPanel;
    Label5: TLabel;
    edOutputDir: TRzButtonEdit;
    RzPanel4: TRzPanel;
    Label7: TLabel;
    edBenchmarkDir: TRzButtonEdit;
    btnRegisterExtensions: TButton;
    RzPanel6: TRzPanel;
    Label9: TLabel;
    edHenkeDir: TRzButtonEdit;
    dlgFolder: TRzSelectFolderDialog;
    Label11: TLabel;
    RzPanel7: TRzPanel;
    Label12: TLabel;
    seBenchRuns: TSpinEdit;
    RzPanel8: TRzPanel;
    Label13: TLabel;
    edBenchOutputDir: TRzButtonEdit;
    RzPanel9: TRzPanel;
    Label14: TLabel;
    edJobsDir: TRzButtonEdit;
    chkLiveUpdate: TCheckBox;

    procedure SaveSettingsClick(Sender: TObject);
    procedure ShowHelpClick(Sender: TObject);

    procedure tvSectionsChange(Sender: TObject; Node: TTreeNode);

    procedure FormShow(Sender: TObject);
    procedure edTimeOutChange(Sender: TObject);
    procedure btnRegisterExtensionsClick(Sender: TObject);
    procedure edBenchmarkDirButtonClick(Sender: TObject);

  private
//    procedure SetPanelFontColor(Value: Graphics.TColor);

  public
    procedure LoadSetting;
    procedure SaveSettings;
  end;

var
  frmSettings: TfrmSettings;

implementation

uses
  StrUtils,
  Character,
  unit_Helpers,
  unit_Config,
  System.Win.Registry;

{$R *.dfm}

procedure TfrmSettings.LoadSetting;
begin
  with TConfig.Section<TCalcOptions> do
  begin
    if NumberOfThreads = 0 then
       cbbCPUCores.ItemIndex := 0
    else
      cbbCPUCores.Text := IntToStr(NumberOfThreads);
    seBenchRuns.Value := BenchmarkRuns;
  end;

  with TConfig.Section<TGraphOptions> do
  begin
    seLineWidth.Value := LineWidth;
  end;


  with TConfig.Section<TOtherOptions> do
  begin
    chkAutoCalcOpen.Checked    := AutoCalc;
    chkAutoSaveResults.Checked := AutoSave;
    chkLiveUpdate.Checked      := LiveUpdate;
  end;

  edHenkeDir.Text        := Config.SystemDirS[sdHenke];
  edProjectDir.Text      := Config.SystemDirS[sdProjDir];
  edBenchmarkDir.Text    := Config.SystemDirS[sdBenchDir];
  edOutputDir.Text       := Config.SystemDirS[sdOutDir];
  edBenchOutputDir.Text  := Config.SystemDirS[sdBenchOutDir];
  edJobsDir.Text         := Config.SystemDirS[sdJobsDir];
end;

procedure TfrmSettings.SaveSettings;
begin
  with TConfig.Section<TCalcOptions> do
  begin
    if cbbCPUCores.ItemIndex = 0 then
      NumberOfThreads := 0
    else
      NumberOfThreads := StrToInt(cbbCPUCores.Text);
    BenchmarkRuns := seBenchRuns.Value;
  end;

  with TConfig.Section<TGraphOptions> do
  begin
    LineWidth := seLineWidth.Value;
  end;

  with TConfig.Section<TOtherOptions> do
  begin
    AutoCalc   := chkAutoCalcOpen.Checked;
    AutoSave   := chkAutoSaveResults.Checked;
    LiveUpdate := chkLiveUpdate.Checked;
  end;

  Config.SystemDir[sdHenke]       := edHenkeDir.Text;
  Config.SystemDir[sdProjDir]     := edProjectDir.Text;
  Config.SystemDir[sdBenchDir]    := edBenchmarkDir.Text;
  Config.SystemDir[sdOutDir]      := edOutputDir.Text;
  Config.SystemDir[sdBenchOutDir] := edBenchOutputDir.Text;
  Config.SystemDirS[sdJobsDir]    := edJobsDir.Text;
end;


procedure TfrmSettings.ShowHelpClick(Sender: TObject);
begin
//  HtmlHelp(Application.Handle, PChar(TConfig.SystemFileName[sfAppHelp]), HH_HELP_CONTEXT, pcSetPages.ActivePage.HelpContext);
end;

procedure TfrmSettings.SaveSettingsClick(Sender: TObject);
begin
  SaveSettings;

  Close;
end;


procedure TfrmSettings.FormShow(Sender: TObject);
begin
//  SetWindowPos(Handle,HWND_TOPMOST,Top,Left,0,0,SWP_NOSIZE);
//  SetFocus;
  LoadSetting;
end;

//
procedure TfrmSettings.tvSectionsChange(Sender: TObject; Node: TTreeNode);
begin
  pcSetPages.ActivePageIndex := tvSections.Selected.Index;
end;

procedure RegisterFileType(prefix: string; exepfad: string);
begin
 with TRegistry.Create do
   try
     RootKey := HKEY_CURRENT_USER;
     OpenKey('Software\\Classes\\' + '.' + prefix, True);
     WriteString('', prefix + 'file');
     CloseKey;
     CreateKey('Software\\Classes\\' + prefix + 'file');
     OpenKey('Software\\Classes\\' + prefix + 'file\\DefaultIcon', True);
     WriteString('', exepfad + ',0');
     CloseKey;
     OpenKey('Software\\Classes\\' + prefix + 'file\\shell\\open\\command', True);
     WriteString('', '"' + exepfad + '"-f "%1"');
     CloseKey;
   finally
     Free;
   end;
end;

procedure TfrmSettings.btnRegisterExtensionsClick(Sender: TObject);
begin
  RegisterFileType('xrcx', Application.ExeName);
end;


// ============================================================================

procedure TfrmSettings.edBenchmarkDirButtonClick(Sender: TObject);
var
  DirType: TXRCSystemDir;
begin
  DirType := TXRCSystemDir((Sender as TRzButtonEdit).Tag);

  dlgFolder.SelectedPathName := TConfig.SystemDir[DirType];
  if dlgFolder.Execute then
  begin
    TConfig.SystemDirS[DirType] := dlgFolder.SelectedPathName;
    (Sender as TRzButtonEdit).Text := TConfig.SystemDirS[DirType];
  end;
end;

procedure TfrmSettings.edTimeOutChange(Sender: TObject);
begin
//
end;

end.
