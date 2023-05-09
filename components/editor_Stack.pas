(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_Stack;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RzEdit, StdCtrls, Mask, RzBtnEdt, RzButton, ExtCtrls, RzPanel,
  unit_types;

type
  TedtrStack = class(TForm)
    RzPanel1: TRzPanel;
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    Label1: TLabel;
    edN: TRzNumericEdit;
    Label2: TLabel;
    edTitle: TEdit;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Edit(var Name: string; var N: Integer);
  end;

var
  edtrStack: TedtrStack;

implementation

{$R *.dfm}


{ TedtrPeriod }

procedure TedtrStack.Edit(var Name: string; var N: Integer);
begin
  edN.Value := N;
  edTitle.Text := Name;
  if ShowModal = mrOk then
  begin
    N := edN.IntValue;
    Name := edTitle.Text;
  end
  else
    Name := '';
end;

end.
