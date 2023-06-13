(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2022-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_Layer;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Dialogs, RzEdit, StdCtrls, Mask, RzBtnEdt, RzButton, ExtCtrls, RzPanel,
  unit_types, JvExMask, JvToolEdit, JvBaseEdits, frm_MaterialSelector;

type
  TedtrLayer = class(TForm)
    RzPanel1: TRzPanel;
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    edMaterial: TRzButtonEdit;
    Label1: TLabel;
    Label2: TLabel;
    edRo: TJvCalcEdit;
    edH: TJvCalcEdit;
    edSigma: TJvCalcEdit;
    Label7: TLabel;
    Label6: TLabel;
    btnPrev: TRzBitBtn;
    btnNext: TRzBitBtn;
    procedure edMaterialButtonClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    function ShowEditor(const IsSubstrate: Boolean; var Data: TLayerData): boolean;
  end;

var
  edtrLayer: TedtrLayer;

implementation

//uses frm_MList;

{$R *.dfm}


function TedtrLayer.ShowEditor(const IsSubstrate: Boolean; var Data: TLayerData): boolean;
begin
  Result := False;
  edMaterial.Text := Data.Material;
  edH.Value := Data.H.V;
  edSigma.Value := Data.S.V;
  edRo.Value := Data.R.V;

  edH.Visible := not IsSubstrate;
  Label2.Visible :=  not IsSubstrate;


  ActiveControl := edMaterial;

  if ShowModal = mrOk then
  begin
    Data.Material := edMaterial.Text;
    Data.H.V := edH.Value;
    Data.S.V := edSigma.Value;
    Data.R.V := edRo.Value;
    Result := True;
  end;

end;

procedure TedtrLayer.edMaterialButtonClick(Sender: TObject);
var
  S: string;
begin
  frmMaterialSelector.SelectMaterial(S);
  edMaterial.Text := S;
end;

end.
