(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

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
  rstrGradientRadioCaption  = 'Function';
  rstrGradientRadioHint     = 'Define (H, s, rho) as a function of N';
  rstrProfileRadioCaption   = 'Arbitrary values';
  rstrProfileRadioHint      = 'Define (H, s, rho)manually as the distribution table';
  rstrRoughRadioCaption     = 'Roughness function';
  rstrRoughRadioHint        = 'Set the special roughness function for given layers';


function SelectExtensionTypeAction: TExtentionType;
const
  mrGradient = 100;
  mrProfile = 101;
  mrRoughness = 102;
var
  xpDlg: TfrmExtensionSelector;
  vistaDlg: TTaskDialog;
  dlgBtn: TTaskDialogBaseButtonItem;
begin
  Result := etNone;

  if (Win32MajorVersion >= 6) and UseLatestCommonDialogs and StyleServices.Enabled then
  begin
    vistaDlg := TTaskDialog.Create(Application);
    try
      vistaDlg.CommonButtons := [tcbCancel];
      vistaDlg.Flags := [tfAllowDialogCancellation, tfUseCommandLinks];
      vistaDlg.MainIcon := tdiInformation;
      vistaDlg.Caption := 'Select type of new extension';

      dlgBtn := vistaDlg.Buttons.Add;
      dlgBtn.Caption := rstrGradientRadioCaption;
      (dlgBtn as TTaskDialogButtonItem).CommandLinkHint := rstrGradientRadioHint ;
      dlgBtn.Default := True;
      dlgBtn.ModalResult := mrGradient;

      dlgBtn := vistaDlg.Buttons.Add;
      dlgBtn.Enabled := False;
      dlgBtn.Caption := rstrProfileRadioCaption;
      (dlgBtn as TTaskDialogButtonItem).CommandLinkHint := rstrProfileRadioHint ;
      dlgBtn.ModalResult := mrProfile;

      dlgBtn := vistaDlg.Buttons.Add;
      dlgBtn.Enabled := False;
      dlgBtn.Caption := rstrRoughRadioCaption;
      (dlgBtn as TTaskDialogButtonItem).CommandLinkHint := rstrRoughRadioHint ;
      dlgBtn.ModalResult := mrRoughness;

      if vistaDlg.Execute then
      begin
        if mrGradient = vistaDlg.ModalResult then
          Result := etFunction
        else if mrProfile = vistaDlg.ModalResult  then
          Result := etTable
        else if mrRoughness = vistaDlg.ModalResult  then
          Result := etRough;
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
          Result := etFunction
        else if xpDlg.rbProfile.Checked then
          Result := etTable
      end;
    finally
      xpDlg.Free;
    end;
  end;
end;

end.
