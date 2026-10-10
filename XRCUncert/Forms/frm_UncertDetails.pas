(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit frm_UncertDetails;

(* Details: what the main window keeps out of sight, as plain text. *)

interface

uses
  System.Classes, Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, RzPanel, RzCommon;

type
  TfrmUncertDetails = class(TForm)
    memDetails: TMemo;
    pnlBottom: TRzPanel;
    btnClose: TButton;
  public
    class procedure ShowText(AOwner: TComponent; const Text: string);
  end;

implementation

{$R *.dfm}

class procedure TfrmUncertDetails.ShowText(AOwner: TComponent; const Text: string);
var
  F: TfrmUncertDetails;
begin
  F := TfrmUncertDetails.Create(AOwner);
  try
    F.memDetails.Lines.Text := Text;
    F.ShowModal;
  finally
    F.Free;
  end;
end;

end.
