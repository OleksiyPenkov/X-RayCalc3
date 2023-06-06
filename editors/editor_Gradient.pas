unit editor_Gradient;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, JvExMask,
  JvToolEdit, JvBaseEdits, RzButton, Vcl.ExtCtrls, RzPanel, unit_types, unit_XRCStructure;

type
  TedtrGradient = class(TForm)
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    RzPanel1: TRzPanel;
    Label1: TLabel;
    Label2: TLabel;
    edRate: TJvCalcEdit;
    edTitle: TEdit;
    cbbStack: TComboBox;
    cbLayer: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    mmDescription: TMemo;
    rgSubject: TRadioGroup;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbbStackChange(Sender: TObject);
  private
    FData: PProjectData;
    FStructure: TXRCStructure;
    { Private declarations }

    procedure FillStacksList;
  public
    { Public declarations }
    property Data: PProjectData read FData write FData;
    property Structure: TXRCStructure write FStructure;
  end;

var
  edtrGradient: TedtrGradient;

implementation

{$R *.dfm}

uses frm_main;

procedure TedtrGradient.btnOKClick(Sender: TObject);
begin
  FData.Title := edTitle.Text;
  FData.ParentStackName := cbbStack.Text;
  FData.ParentLayerName := cbLayer.Text;
  FData.Rate := edRate.Value;
  FData.Form := gtLine;
  FData.Description := mmDescription.Lines.Text;
  FData.Subj := TParameterType(rgSubject.ItemIndex);
end;

procedure TedtrGradient.cbbStackChange(Sender: TObject);
begin
  if cbbStack.Text <> '' then
  begin
     FStructure.GetLayersList(cbbStack.Text, cbLayer.Items);
  end;
end;

procedure TedtrGradient.FillStacksList;
var
  i: Integer;
begin
  cbbStack.Text := '';
  FStructure.GetStacksList(True, cbbStack.Items);
  cbbStack.ItemIndex := 0;
end;

procedure TedtrGradient.FormShow(Sender: TObject);
begin
  FillStacksList;

  edTitle.Text := string(FData.Title);
  cbbStack.Text := string(FData.ParentStackName);
  cbLayer.Text := string(FData.ParentLayerName);
  edRate.Value := FData.Rate;
  rgSubject.ItemIndex := Ord(FData.Subj);
  mmDescription.Lines.Text := string(FData.Description);
end;

end.
