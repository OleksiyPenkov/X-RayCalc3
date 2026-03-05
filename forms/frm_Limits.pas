(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_Limits;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, RzEdit, Vcl.ComCtrls,
  RzListVw, unit_Types, unit_SmartLimits, Vcl.StdCtrls, Vcl.Buttons, RzButton;

Const
  USER_EDITLISTVIEW = WM_USER + 666;

type
  TfrmLimits = class(TForm)
    RzPanel1: TRzPanel;
    RzPanel2: TRzPanel;
    ListView: TRzListView;
    edFdH: TEdit;
    Label13: TLabel;
    Label14: TLabel;
    edFdS: TEdit;
    Label15: TLabel;
    edFdRho: TEdit;
    btnInit: TBitBtn;
    btnNarrow: TBitBtn;
    btnWiden: TBitBtn;
    btnFix: TBitBtn;
    btnSet: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    procedure ListViewClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure btnNarrowClick(Sender: TObject);
    procedure btnWidenClick(Sender: TObject);
    procedure btnFixClick(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
    procedure FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
      NewDPI: Integer);
    procedure btnSetClick(Sender: TObject);
    procedure ListViewCustomDrawSubItem(Sender: TCustomListView;
      Item: TListItem; SubItem: Integer; State: TCustomDrawState;
      var DefaultDraw: Boolean);
  private
    ListViewEditor: TRzEdit;
    LItem: TListitem;
    FStructure: TFitStructure;
    FDPI: integer;
    FIssues: TArray<TLimitIssue>;

    procedure UserEditListView( Var Message: TMessage ); message USER_EDITLISTVIEW;
    procedure ListViewEditorExit(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StructureToView;
    procedure StructureFromView;
    procedure RunValidation;
  public
    { Public declarations }

    function ShowLimits(const ACaption: string; var Structure: TFitStructure): boolean;
  end;

var
  frmLimits: TfrmLimits;

implementation

{$R *.dfm}

uses
  System.UITypes, CommCtrl, math_globals, math_complex;

var
  EDIT_COLUMN: integer;

procedure TfrmLimits.btnInitClick(Sender: TObject);
var
  i, j, p, Count, Index: integer;
  dP: array [1..3] of single;
  NroValues: array of Single;
  f: TComplex;
  Na, Nro: Single;

  function Convert(const Inp, D: single): string;
  var
    Val: single;
  begin
    Val := Inp + Inp * D;
    Result := FloatToStrF(Val, ffFixed, 5, 2);
  end;

begin
  dP[1] := StrToFloat(edFdH.Text);
  dP[2] := StrToFloat(edFdS.Text);
  dP[3] := StrToFloat(edFdRho.Text);

  // Look up Henke bulk density for each layer
  SetLength(NroValues, FStructure.Total);
  Index := 0;
  for i := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      try
        ReadHenke(FStructure.Stacks[i].Layers[j].Material, 8000, 0, f, Na, Nro);
        NroValues[Index] := Nro;
      except
        on E: EInOutError do
          NroValues[Index] := 0;
      end;
      Inc(Index);
    end;
  ApplyMaterialDensity(FStructure, NroValues);

  Index := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      Count := 0;
      for p := 1 to 3 do
      begin
        if (p = 3) and (Index <= High(NroValues)) and (NroValues[Index] > 0) then
        begin
          // Use Henke density as center for Rho limits
          ListView.Items[Index].SubItems[Count] := Convert(NroValues[Index], -dP[p]);
          ListView.Items[Index].SubItems[Count + 1] := Convert(NroValues[Index], dP[p]);
        end
        else
        begin
          ListView.Items[Index].SubItems[Count] := Convert(FStructure.Stacks[i].Layers[j].P[p].V, -dP[p]);
          ListView.Items[Index].SubItems[Count + 1] := Convert(FStructure.Stacks[i].Layers[j].P[p].V, dP[p]);
        end;
        Inc(Count, 2);
      end;
      Inc(Index);
    end;
  end;
  StructureFromView;
  ClampToPhysics(FStructure);
  ApplyGeometryCoupling(FStructure);
  StructureToView;
end;

procedure TfrmLimits.btnNarrowClick(Sender: TObject);
begin
  StructureFromView;
  NarrowLimits(FStructure, 0.5);
  ClampToPhysics(FStructure);
  ApplyGeometryCoupling(FStructure);
  StructureToView;
end;

procedure TfrmLimits.btnWidenClick(Sender: TObject);
begin
  StructureFromView;
  WidenAtLimit(FStructure, 0.5);
  ClampToPhysics(FStructure);
  ApplyGeometryCoupling(FStructure);
  StructureToView;
end;

procedure TfrmLimits.btnFixClick(Sender: TObject);
begin
  StructureFromView;
  AutoFixErrors(FStructure);
  WidenAtLimit(FStructure, 0.5);
  ClampToPhysics(FStructure);
  ApplyGeometryCoupling(FStructure);
  StructureToView;
end;

procedure TfrmLimits.EditorKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    ListViewEditor.Visible:=False;
end;

procedure TfrmLimits.FormAfterMonitorDpiChanged(Sender: TObject; OldDPI,
  NewDPI: Integer);
begin
  FDPI := NewDPI;
end;

procedure TfrmLimits.FormCreate(Sender: TObject);
begin
  //create the TEdit and assign the OnExit event
  ListViewEditor:=TRzEdit.Create(Self);
  ListViewEditor.Parent:=ListView;
  ListViewEditor.OnExit:=ListViewEditorExit;
  ListViewEditor.Visible:=False;
  ListViewEditor.OnKeyDown := EditorKeyDown;

  FDPI := Screen.PixelsPerInch;
end;

procedure TfrmLimits.ListViewClick(Sender: TObject);
var
  LPoint: TPoint;
  LVHitTestInfo: TLVHitTestInfo;

  function GetColumns(const X: integer):integer;
  var
    Pos: integer;
  begin
    Pos := (X - ListView.Columns[0].Width) div ListView.Columns[1].Width + 1;
    Result := Pos; //MulDiv(Pos, 96, FDPI);
  end;

begin
  LPoint:= ListView.ScreenToClient(Mouse.CursorPos);

  EDIT_COLUMN := GetColumns(LPoint.X);

  ZeroMemory( @LVHitTestInfo, SizeOf(LVHitTestInfo));
  LVHitTestInfo.pt := LPoint;
  //Check if the click was made in the column to edit
  If (ListView.perform( LVM_SUBITEMHITTEST, 0, LPARAM(@LVHitTestInfo))<>-1) and ( LVHitTestInfo.iSubItem = EDIT_COLUMN ) Then
    PostMessage( self.Handle, USER_EDITLISTVIEW, LVHitTestInfo.iItem, 0 )
  else
    ListViewEditor.Visible:=False; //hide the TEdit
end;

procedure TfrmLimits.ListViewEditorExit(Sender: TObject);
begin
  If Assigned(LItem) Then
  Begin
    //assign the vslue of the TEdit to the Subitem
    LItem.SubItems[ EDIT_COLUMN-1 ] := ListViewEditor.Text;
    LItem := nil;
  End;
  RunValidation;
end;

procedure TfrmLimits.RzBitBtn2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmLimits.StructureToView;
var
  i, j, p: integer;
  Group: TListGroup;
  ListItem: TListItem;
begin
  ListView.Items.Clear;
  ListView.Groups.Clear;

  for I := 0 to High(FStructure.Stacks) do
  begin
    Group := ListView.Groups.Add;
    Group.Header := FStructure.Stacks[i].Header;

    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      ListItem := ListView.Items.Add;
      ListItem.GroupID := Group.GroupID;
      ListItem.Caption := FStructure.Stacks[i].Layers[j].Material;

      for p := 1 to 3 do
      begin
        ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].P[p].min, ffFixed, 5, 2));
        ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].P[p].max, ffFixed, 5, 2));
      end;
    end;
  end;
  RunValidation;
end;

procedure TfrmLimits.StructureFromView;
var
  i, j, p, Count, Index: integer;

begin

  Index := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      Count := 0;
      for p := 1 to 3 do
      begin
        FStructure.Stacks[i].Layers[j].P[p].min := StrToFloat(ListView.Items[Index].SubItems[Count]);
        FStructure.Stacks[i].Layers[j].P[p].max := StrToFloat(ListView.Items[Index].SubItems[Count + 1]);
        Inc(Count, 2);
      end;
      Inc(Index);
    end;
  end;

end;

function TfrmLimits.ShowLimits(const ACaption: string; var Structure: TFitStructure): boolean;
begin
  FStructure := Structure;
  btnSet.Caption := ACaption;

  StructureToView;

  if ShowModal = mrOk then
  begin
    StructureFromView;
    Structure := FStructure;
    Result := True;
  end
  else Result := False;
end;

procedure TfrmLimits.UserEditListView(var Message: TMessage);
var
  LRect: TRect;
begin
  LRect.Top := EDIT_COLUMN;
  LRect.Left:= LVIR_BOUNDS;
  ListView.Perform( LVM_GETSUBITEMRECT, Message.wparam,  LPARAM(@LRect) );
  MapWindowPoints( ListView.Handle, ListViewEditor.Parent.Handle, LRect, 2 );
  //get the current Item to edit
  LItem := ListView.Items[ Message.wparam ];
  //set the text of the Edit
  ListViewEditor.Text := LItem.Subitems[ EDIT_COLUMN-1];
  //set the bounds of the TEdit
  ListViewEditor.BoundsRect := LRect;
  //Show the TEdit
  ListViewEditor.Visible:=True;
end;

procedure TfrmLimits.RunValidation;
begin
  StructureFromView;
  FIssues := ValidateLimits(FStructure);
  ListView.Invalidate;
end;

procedure TfrmLimits.btnSetClick(Sender: TObject);
begin
  RunValidation;

  if HasErrors(FIssues) then
  begin
    ShowMessage(IssuesToText(FIssues));
    Exit;
  end;

  if HasWarnings(FIssues) then
  begin
    if MessageDlg(IssuesToText(FIssues) + #13#10 + #13#10 + 'Proceed anyway?',
      mtWarning, [mbYes, mbNo], 0) <> mrYes then
      Exit;
  end;

  ModalResult := mrOk;
end;

procedure TfrmLimits.ListViewCustomDrawSubItem(Sender: TCustomListView;
  Item: TListItem; SubItem: Integer; State: TCustomDrawState;
  var DefaultDraw: Boolean);
var
  Kind: TLimitIssueKind;
begin
  if SubItem < 1 then
    Exit;

  Kind := CellState(FIssues, Item.Index, SubItem - 1);

  case Kind of
    likError:
      Sender.Canvas.Brush.Color := $CCCCFF;  // light red
    likWarning:
      Sender.Canvas.Brush.Color := $CCFFFF;  // light yellow
  end;
end;

end.
