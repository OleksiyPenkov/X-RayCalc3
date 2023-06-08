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
    { Private declarations }
    FData: PProjectData;
    FStructure: TXRCStructure;
    FRealStackID: TIntArray;

    procedure FillStacksList;
    function ListedStackID(const AbsoluteID: integer): Integer;
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
  FData.StackID := FRealStackID[cbbStack.ItemIndex];
  FData.LayerID := cbLayer.ItemIndex;
  FData.a := edRate.Value;
  FData.Form := ffLine;
  FData.Description := mmDescription.Lines.Text;
  FData.Subj := TParameterType(rgSubject.ItemIndex);
end;

procedure TedtrGradient.cbbStackChange(Sender: TObject);
begin
  if cbbStack.ItemIndex <> -1 then
    FStructure.GetLayersList(FRealStackID[cbbStack.ItemIndex], cbLayer.Items);
end;

procedure TedtrGradient.FillStacksList;
var
  i: Integer;
begin
  cbbStack.Text := '';
  FStructure.GetStacksList(True, cbbStack.Items, FRealStackID);
  cbbStack.ItemIndex := 0;
end;

procedure TedtrGradient.FormShow(Sender: TObject);
begin
  FillStacksList;

  edTitle.Text := string(FData.Title);
  cbbStack.ItemIndex := ListedStackID(FData.StackID);
  cbbStackChange(Sender);
  cbLayer.ItemIndex  := FData.LayerID;
  edRate.Value := FData.a;
  rgSubject.ItemIndex := Ord(FData.Subj);
  mmDescription.Lines.Text := string(FData.Description);
end;

function TedtrGradient.ListedStackID(const AbsoluteID: integer): Integer;
var
  i: Integer;
begin
  Result := -1;
  for i := 0 to High(FRealStackID) do
    if FRealStackID[i] = AbsoluteID then
    begin
      Result := i;
      Break;
    end;
end;

end.
