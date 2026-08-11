(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_StaleExtDialog;

interface

type
  TStaleExtAction = (seaClear, seaKeep, seaCancel);

function ConfirmStaleExtensions: TStaleExtAction;

implementation

uses
  Vcl.Dialogs, Vcl.Forms;

resourcestring
  rstrStaleCaption = 'Extensions from the previous fitting';
  rstrStaleTitle   = 'This model still carries extensions created by an earlier fitting run.';
  rstrStaleText    = 'They will be applied to the model unless you remove them.';
  rstrClearCaption = 'Clear them';
  rstrClearHint    = 'Delete the extensions from the previous fit and start from the bare structure';
  rstrKeepCaption  = 'Keep them';
  rstrKeepHint     = 'Use them as the starting point; the new result will update them in place';

function ConfirmStaleExtensions: TStaleExtAction;
const
  mrClearExt = 100;
  mrKeepExt  = 101;
var
  Dlg: TTaskDialog;
  Btn: TTaskDialogBaseButtonItem;
begin
  Result := seaCancel;

  Dlg := TTaskDialog.Create(Application);
  try
    Dlg.Caption := rstrStaleCaption;
    Dlg.Title := rstrStaleTitle;
    Dlg.Text := rstrStaleText;
    Dlg.CommonButtons := [tcbCancel];
    Dlg.Flags := [tfAllowDialogCancellation, tfUseCommandLinks];
    Dlg.MainIcon := tdiWarning;

    Btn := Dlg.Buttons.Add;
    Btn.Caption := rstrClearCaption;
    (Btn as TTaskDialogButtonItem).CommandLinkHint := rstrClearHint;
    Btn.Default := True;
    Btn.ModalResult := mrClearExt;

    Btn := Dlg.Buttons.Add;
    Btn.Caption := rstrKeepCaption;
    (Btn as TTaskDialogButtonItem).CommandLinkHint := rstrKeepHint;
    Btn.ModalResult := mrKeepExt;

    if Dlg.Execute then
    begin
      case Dlg.ModalResult of
        mrClearExt: Result := seaClear;
        mrKeepExt:  Result := seaKeep;
      end;
    end;
  finally
    Dlg.Free;
  end;
end;

end.
