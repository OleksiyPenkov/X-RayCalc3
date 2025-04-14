(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit editor_ProfileFunction;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.Mask, JvExMask,
  JvToolEdit, JvBaseEdits, RzButton, Vcl.ExtCtrls, RzPanel, unit_types, unit_XRCStructure,
  System.ImageList, Vcl.ImgList, Vcl.Grids, RzGrids, Vcl.Imaging.pngimage,
  RzEdit, RzSpnEdt, RzCmboBx, VclTee.TeeGDIPlus, Vcl.Buttons, VCLTee.TeEngine,
  VCLTee.Series, VCLTee.TeeProcs, VCLTee.Chart;

type
  TedtrProfileFunction = class(TForm)
    RzPanel2: TRzPanel;
    btnOK: TRzBitBtn;
    btnCancel: TRzBitBtn;
    RzPanel1: TRzPanel;
    Label1: TLabel;
    edTitle: TEdit;
    cbbStack: TComboBox;
    cbLayer: TComboBox;
    Label3: TLabel;
    Label4: TLabel;
    mmDescription: TMemo;
    rgSubject: TRadioGroup;
    cbFunctionType: TRzComboBox;
    Label2: TLabel;
    lbl1: TLabel;
    seOrder: TRzSpinEdit;
    Grid: TRzStringGrid;
    lbl2: TLabel;
    ilEquations: TImageList;
    Image1: TImage;
    Chart: TChart;
    Series1: TLineSeries;
    btnPreview: TBitBtn;
    btnFunctionHelp: TBitBtn;
    btnCopy: TBitBtn;
    procedure FormShow(Sender: TObject);
    procedure btnOKClick(Sender: TObject);
    procedure cbbStackChange(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure seOrderChange(Sender: TObject);
    procedure btnPreviewClick(Sender: TObject);
    procedure cbLayerChange(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
  private
    { Private declarations }
    FData: PProjectData;
    FStructure: TXRCStructure;
    FRealStackID: unit_types.TIntArray;

    procedure FillStacksList;
    function ListedStackID(const AbsoluteID: integer): Integer;
    procedure FillCoefficients;
    procedure GetCoefficients;
  public
    { Public declarations }
    property Data: PProjectData read FData write FData;
    property Structure: TXRCStructure write FStructure;
  end;

var
  edtrProfileFunction: TedtrProfileFunction;

implementation

{$R *.dfm}

uses frm_main, math_globals, unit_helpers;

procedure TedtrProfileFunction.btnCopyClick(Sender: TObject);
begin
  SeriesToClipboard('N', FData.Title, '', 'A', Series1);
end;

procedure TedtrProfileFunction.btnOKClick(Sender: TObject);
begin
  FData.Title := edTitle.Text;
  FData.StackID := FRealStackID[cbbStack.ItemIndex];
  FData.LayerID := cbLayer.ItemIndex;
  GetCoefficients;
  FData.Form := ffPoly;
  FData.Description := mmDescription.Lines.Text;
  FData.Subj := TParameterType(rgSubject.ItemIndex);
end;

procedure TedtrProfileFunction.btnPreviewClick(Sender: TObject);
var
  i: Integer;
  PolyRec : TFuncProfileRec;
begin
  if (FData.StackID = -1) or (FData.LayerID = -1) then Exit;

  Series1.Clear;
  GetCoefficients;
  PolyRec.Assign(FData);
  PolyRec.C[0] := FStructure.Stacks[PolyRec.StackID].Layers[PolyRec.LayerID].Data.P[PolyRec.PIndex].V;

  for I := 1 to FStructure.Stacks[PolyRec.StackID].N do
  begin
    Series1.AddXY(i, Poly(i, PolyRec.C));
  end;
end;

procedure TedtrProfileFunction.cbbStackChange(Sender: TObject);
begin
  if cbbStack.ItemIndex <> -1 then
  begin
    FData.StackID := FRealStackID[cbbStack.ItemIndex];
    FStructure.GetLayersList(FData.StackID, cbLayer.Items);
  end;
end;

procedure TedtrProfileFunction.cbLayerChange(Sender: TObject);
begin
  FData.LayerID := cbLayer.ItemIndex;
end;

procedure TedtrProfileFunction.FillStacksList;
begin
  cbbStack.Text := '';
  FStructure.GetStacksList(True, cbbStack.Items, FRealStackID);
  cbbStack.ItemIndex := 0;
end;

procedure TedtrProfileFunction.FillCoefficients;
var
  i: integer;
  N: Integer;
begin
  N := High(Data.PolyD);
  seOrder.IntValue := N;
  Grid.RowCount := N + 1;
  for i := 1 to N do
  begin
    Grid.Cells[0, i] := Format('c%d',[i]);
    Grid.Cells[1, i] := FloatToStrF(FData.PolyD[i], ffGeneral, 4, 3);
  end;
end;

procedure TedtrProfileFunction.FormCreate(Sender: TObject);
begin
  Grid.Cells[0, 0] := 'Coefficient';
  Grid.Cells[1, 0] := 'Value';
end;

procedure TedtrProfileFunction.FormShow(Sender: TObject);
begin
  FillStacksList;

  edTitle.Text := string(FData.Title);
  cbbStack.ItemIndex := ListedStackID(FData.StackID);
  cbbStackChange(Sender);
  cbLayer.ItemIndex  := FData.LayerID;
  rgSubject.ItemIndex := Ord(FData.Subj);
  mmDescription.Lines.Text := string(FData.Description);
  FillCoefficients;
  btnPreviewClick(nil);
end;

procedure TedtrProfileFunction.GetCoefficients;
var
  i: Integer;
begin
  FData.Poly[10] := seOrder.IntValue;
  for I := 1 to Trunc(FData.Poly[10]) do
    FData.Poly[i] := StrToFloat( Grid.Cells[1, i]);
end;

function TedtrProfileFunction.ListedStackID(const AbsoluteID: integer): Integer;
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

procedure TedtrProfileFunction.seOrderChange(Sender: TObject);
begin
  Grid.RowCount := seOrder.IntValue + 1;
  Grid.Cells[0, Grid.RowCount - 1] := Format('c%d',[Grid.RowCount - 1]);
end;

end.
