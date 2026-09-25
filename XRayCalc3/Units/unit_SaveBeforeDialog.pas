(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_SaveBeforeDialog;

interface

type
  TSaveBeforeAction = (sbaSave, sbaDiscard, sbaCancel);

/// <summary>File - New: save the current project first, discard it, or stay.
/// The program does not track changes, so it always asks.</summary>
function ConfirmSaveBeforeNew: TSaveBeforeAction;

implementation

uses
  System.UITypes, Vcl.Dialogs, Vcl.Forms;

resourcestring
  rstrNewCaption     = 'New project';
  rstrNewTitle       = 'Save the current project before starting a new one?';
  rstrNewText        = 'Unsaved results are lost otherwise.';
  rstrSaveCaption    = 'Save';
  rstrDiscardCaption = 'Don''t save';

function ConfirmSaveBeforeNew: TSaveBeforeAction;
const
  mrSaveProject    = 100;
  mrDiscardProject = 101;
var
  Dlg: TTaskDialog;
  Btn: TTaskDialogBaseButtonItem;
begin
  Result := sbaCancel;

  Dlg := TTaskDialog.Create(Application);
  try
    Dlg.Caption := rstrNewCaption;
    Dlg.Title := rstrNewTitle;
    Dlg.Text := rstrNewText;
    Dlg.CommonButtons := [tcbCancel];
    Dlg.Flags := [tfAllowDialogCancellation];
    Dlg.MainIcon := tdiWarning;

    Btn := Dlg.Buttons.Add;
    Btn.Caption := rstrSaveCaption;
    Btn.Default := True;
    Btn.ModalResult := mrSaveProject;

    Btn := Dlg.Buttons.Add;
    Btn.Caption := rstrDiscardCaption;
    Btn.ModalResult := mrDiscardProject;

    if Dlg.Execute then
      case Dlg.ModalResult of
        mrSaveProject:    Result := sbaSave;
        mrDiscardProject: Result := sbaDiscard;
      end;
  finally
    Dlg.Free;
  end;
end;

end.
