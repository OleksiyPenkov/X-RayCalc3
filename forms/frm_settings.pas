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
  RzPanel, Vcl.Samples.Spin;

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
    btnRegisterExtensions: TButton;
    tsInterface: TTabSheet;
    Label3: TLabel;
    lbl1: TLabel;
    tsCalc: TTabSheet;
    lbl2: TLabel;
    chkAutoClacOpen: TCheckBox;
    pnlCores: TPanel;
    Label1: TLabel;
    cbbCPUCores: TComboBox;
    tsGraphics: TTabSheet;
    lbl3: TLabel;
    Panel1: TPanel;
    Label2: TLabel;
    seLineWidth: TSpinEdit;

    procedure SaveSettingsClick(Sender: TObject);
    procedure ShowHelpClick(Sender: TObject);

    procedure tvSectionsChange(Sender: TObject; Node: TTreeNode);

    procedure FormShow(Sender: TObject);
    procedure edTimeOutChange(Sender: TObject);
    procedure btnRegisterExtensionsClick(Sender: TObject);

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
    if NumberOfThreads = -1 then
       cbbCPUCores.Text := 'Auto'
    else
      cbbCPUCores.Text := IntToStr(NumberOfThreads);
  end;

  with TConfig.Section<TGraphOptions> do
  begin
    seLineWidth.Value := LineWidth;
  end;

end;

procedure TfrmSettings.SaveSettings;
begin
  with TConfig.Section<TCalcOptions> do
  begin
    if cbbCPUCores.Text = 'Auto' then
       NumberOfThreads := -1
    else
      NumberOfThreads := StrToInt(cbbCPUCores.Text);
  end;

  with TConfig.Section<TGraphOptions> do
  begin
    LineWidth := seLineWidth.Value;
  end;
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
// ��������� ����������
//
//procedure TfrmSettings.SetPanelFontColor(Value: Graphics.TColor);
//begin
//end;

//procedure TfrmSettings.SetCustomFontColor(Sender: TObject);
//begin
//end;

//
//
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

procedure TfrmSettings.edTimeOutChange(Sender: TObject);
begin
//
end;

end.
