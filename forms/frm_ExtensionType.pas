unit frm_ExtensionType;

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
  Themes,
  pngimage,
  ExtCtrls,
  unit_Types,
  Vcl.Buttons;

type
  TfrmExtensionSelector = class(TForm)
    pnlMain: TPanel;
    rbGradient: TRadioButton;
    txtGradient: TLabel;
    rbProfile: TRadioButton;
    btnOk: TBitBtn;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmExtensionSelector: TfrmExtensionSelector;

 function SelectExtensionTypeAction: TExtentionType;

implementation

{$R *.dfm}

resourcestring
  rstrGradientRadioCaption  = 'Gradient';
  rstrGradientRadioHint     = 'Create ad istribution of a parameter (H, s, rho) for cirtain layer';
  rstrProfileRadioCaption   = 'Profile';
  rstrProfileRadioHint      = 'Create a parameters'' distribution table';

function SelectExtensionTypeAction: TExtentionType;
const
  mrGradient = 100;
  mrProfile = 101;
var
  xpDlg: TfrmExtensionSelector;
  vistaDlg: TTaskDialog;
  dlgBtn: TTaskDialogBaseButtonItem;
begin
  Result := etNone;

  if (Win32MajorVersion >= 6) and UseLatestCommonDialogs and ThemeServices.ThemesEnabled then
  begin
    vistaDlg := TTaskDialog.Create(Application);
    try
      vistaDlg.CommonButtons := [tcbCancel];
      vistaDlg.Flags := [tfAllowDialogCancellation, tfUseCommandLinks];
      vistaDlg.MainIcon := tdiWarning;
      vistaDlg.Caption := 'Select type of new extension';

      dlgBtn := vistaDlg.Buttons.Add;
      Assert(dlgBtn is TTaskDialogButtonItem);
      dlgBtn.Caption := rstrGradientRadioCaption;
      (dlgBtn as TTaskDialogButtonItem).CommandLinkHint := rstrGradientRadioHint ;
      dlgBtn.Default := True;
      dlgBtn.ModalResult := mrGradient;

      dlgBtn := vistaDlg.Buttons.Add;
      Assert(dlgBtn is TTaskDialogButtonItem);
      dlgBtn.Caption := rstrProfileRadioCaption;
      (dlgBtn as TTaskDialogButtonItem).CommandLinkHint := rstrProfileRadioHint ;
      dlgBtn.ModalResult := mrProfile;

      if vistaDlg.Execute then
      begin
        if mrGradient = vistaDlg.ModalResult then
          Result := etGradient
        else if mrProfile = vistaDlg.ModalResult  then
          Result := etProfile;
      end;
    finally
      vistaDlg.Free;
    end;
  end
  else
  begin
    xpDlg := TfrmExtensionSelector.Create(Application);
    try
      if mrOk = xpDlg.ShowModal then
      begin
        if xpDlg.rbGradient.Checked then
          Result := etGradient
        else if xpDlg.rbProfile.Checked then
          Result := etProfile
      end;
    finally
      xpDlg.Free;
    end;
  end;
end;

end.
