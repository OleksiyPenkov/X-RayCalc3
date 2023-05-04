(* *****************************************************************************
  *
  *   X-Ray Calc 2
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_Substrate;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, JvExMask, JvToolEdit, JvBaseEdits, StdCtrls, Mask, RzEdit, RzBtnEdt,
  RzButton, ExtCtrls, RzPanel, unit_types;

type
  TedtrSubstrate = class(TForm)
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    RzPanel1: TRzPanel;
    Label1: TLabel;
    Label7: TLabel;
    Label6: TLabel;
    edMaterial: TRzButtonEdit;
    edRo: TJvCalcEdit;
    edSigma: TJvCalcEdit;
  private
    { Private declarations }
  public
    { Public declarations }
    procedure Edit(var Material, Sigma, rho: string);
  end;

var
  edtrSubstrate: TedtrSubstrate;

implementation

{$R *.dfm}

procedure TedtrSubstrate.Edit;
begin
  edMaterial.Text := Material;
  edSigma.Text := Sigma;
  edRo.Text := rho;
  if ShowModal = mrOk then
  begin
    Material := edMaterial.Text;
    Sigma := edSigma.Text;
    rho := edRo.Text;
  end;
end;


end.
