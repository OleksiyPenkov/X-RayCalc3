(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_MaterialSelector;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Buttons, Vcl.WinXCtrls,
  unit_helpers, unit_Config;

type
  TfrmMaterialSelector = class(TForm)
    SearchBox1: TSearchBox;
    lbFiles: TListBox;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure SelectMaterial(var Name: string);
  end;

var
  frmMaterialSelector: TfrmMaterialSelector;

implementation

{$R *.dfm}

{ TfrmMaterialSelector }

procedure TfrmMaterialSelector.SelectMaterial(var Name: string);
begin
  FillElementsList(Config.SystemDir[sdHenke], lbFiles);
  if ShowModal = mrOk then
  begin
    Name := lbFiles.Items[lbFiles.ItemIndex];
  end;
end;

end.
