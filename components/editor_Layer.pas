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
  unit_types, JvExMask, JvToolEdit, JvBaseEdits;

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
    procedure btnOKClick(Sender: TObject);
    procedure FormShow(Sender: TObject);

    procedure FillEdits;
    procedure SaveData;
    procedure edMaterialButtonClick(Sender: TObject);

  private
    { Private declarations }
  public
    { Public declarations }
    Data : TLayerData;
  end;

var
  edtrLayer: TedtrLayer;

implementation

//uses frm_MList;

{$R *.dfm}

procedure TedtrLayer.FillEdits;
begin
  edMaterial.Text := Data.Material;
  edH.Value := Data.H.V;
  edSigma.Value := Data.S.V;
  edRo.Value := Data.R.V;
end;

procedure TedtrLayer.FormShow(Sender: TObject);
begin
  FillEdits;
  ActiveControl := edMaterial;
end;

procedure TedtrLayer.SaveData;
begin
  Data.Material := edMaterial.Text;
  Data.H.V := edH.Value;
  Data.S.V := edSigma.Value;
  Data.R.V := edRo.Value;
end;

procedure TedtrLayer.btnOKClick(Sender: TObject);
begin
  SaveData;
end;

procedure TedtrLayer.edMaterialButtonClick(Sender: TObject);
begin
//  edMaterial.Text := GetElementName;
end;

end.
