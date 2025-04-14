(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_proj_item;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RzButton, ExtCtrls, RzPanel, unit_types, StdCtrls, RzCmboBx, RzCommon,
  Vcl.Mask;

type
  TedtrProjectItem = class(TForm)
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    RzPanel1: TRzPanel;
    edTitle: TLabeledEdit;
    mmDescription: TMemo;
    Color: TLabel;
    rzfrmcntrlr1: TRzFrameController;
    cbColor: TColorBox;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
  private
    { Private declarations }
    FData : PProjectData;
  public
    { Public declarations }
    property Data: PProjectData read FData write FData;
  end;

var
  edtrProjectItem: TedtrProjectItem;

implementation

{$R *.dfm}

procedure TedtrProjectItem.btnOKClick(Sender: TObject);
begin
  FData.Title := edTitle.Text;
  FData.Color := cbColor.Selected;
  FData.Description := mmDescription.Lines.Text;
end;

procedure TedtrProjectItem.FormShow(Sender: TObject);
begin
  edTitle.Text := FData.Title;
  cbColor.Selected := FData.Color;
  mmDescription.Lines.Text := FData.Description;
end;

end.
