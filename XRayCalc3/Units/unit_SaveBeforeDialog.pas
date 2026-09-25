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

/// <summary>Before the current project is replaced - File - New, Open, a
/// recent project: save it first, discard it, or stay. The program does not
/// track changes, so it always asks. Caption names the command, Title is the
/// question.</summary>
function ConfirmSaveBefore(const Caption, Title: string): TSaveBeforeAction;

implementation

uses
  System.UITypes, Vcl.Dialogs, Vcl.Forms;

resourcestring
  rstrLostText       = 'Unsaved results are lost otherwise.';
  rstrSaveCaption    = 'Save';
  rstrDiscardCaption = 'Don''t save';

function ConfirmSaveBefore(const Caption, Title: string): TSaveBeforeAction;
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
    Dlg.Caption := Caption;
    Dlg.Title := Title;
    Dlg.Text := rstrLostText;
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
