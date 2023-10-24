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
    procedure btnNextClick(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure btnPrevClick(Sender: TObject);

  private
    { Private declarations }
    FData: TLayerData;
    FSeq: boolean;
  public
    { Public declarations }
    procedure SetData(const IsSubstrate: Boolean; Data: TLayerData);
    function GetData: TLayerData;
    property Seq: boolean read FSeq;
  end;

var
  edtrLayer: TedtrLayer;

implementation

uses
  unit_SMessages;

//uses frm_MList;

{$R *.dfm}


procedure TedtrLayer.btnNextClick(Sender: TObject);
begin
  LayerEditNext(FData.StackID, FData.LayerID);
end;

procedure TedtrLayer.btnOKClick(Sender: TObject);
begin
  FSeq := False;
end;

procedure TedtrLayer.btnPrevClick(Sender: TObject);
begin
  LayerEditPrev(FData.StackID, FData.LayerID);
end;

procedure TedtrLayer.edMaterialButtonClick(Sender: TObject);
var
  S: string;
begin
  frmMaterialSelector.SelectMaterial(S);
  edMaterial.Text := S;
end;

function TedtrLayer.GetData: TLayerData;
begin
  Result := FData;

  Result.Material := edMaterial.Text;
  Result.P[1].V := edH.Value;
  Result.P[2].V := edSigma.Value;
  Result.P[3].V := edRo.Value;

end;

procedure TedtrLayer.SetData(const IsSubstrate: Boolean; Data: TLayerData);
begin
  FSeq := Self.Showing;

  FData := Data;

  edMaterial.Text := Data.Material;
  edH.Value := Data.P[1].V;
  edSigma.Value := Data.P[2].V;
  edRo.Value := Data.P[3].V;

  edH.Visible := not IsSubstrate;
  Label2.Visible :=  not IsSubstrate;

  btnPrev.Visible := not IsSubstrate;
  btnNext.Visible := not IsSubstrate;

  ActiveControl := edMaterial;
end;

end.
