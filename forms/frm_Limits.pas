unit frm_Limits;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, RzEdit, Vcl.ComCtrls,
  RzListVw, unit_Types, Vcl.StdCtrls, Vcl.Buttons, RzButton;

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
    RzBitBtn1: TRzBitBtn;
    RzBitBtn2: TRzBitBtn;
    procedure ListViewClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure btnInitClick(Sender: TObject);
    procedure RzBitBtn2Click(Sender: TObject);
  private
    ListViewEditor: TRzEdit;
    LItem: TListitem;
    FStructure: TFitPeriodicStructure ;

    procedure UserEditListView( Var Message: TMessage ); message USER_EDITLISTVIEW;
    procedure ListViewEditorExit(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StructureToView;
    procedure StructureFromView;
  public
    { Public declarations }

    function Show(var Structure: TFitPeriodicStructure): boolean;
  end;

var
  frmLimits: TfrmLimits;

implementation

{$R *.dfm}

uses
  CommCtrl;

var
  EDIT_COLUMN: integer;

procedure TfrmLimits.btnInitClick(Sender: TObject);
var
  i, j, Index: integer;
  dH, dS, dRho: single;

  function Convert(const Inp, D: single): string;
  var
    Val: single;
  begin
    Val := Inp + Inp * D;
    Result := FloatToStrF(Val, ffFixed, 5, 2);
  end;

begin
  dH    := StrToFloat(edFdH.Text);
  dS    := StrToFloat(edFdS.Text);
  dRho  := StrToFloat(edFdRho.Text);

  Index := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      ListView.Items[Index].SubItems[0] := Convert(FStructure.Stacks[i].Layers[j].H.V, -dH);
      ListView.Items[Index].SubItems[1] := Convert(FStructure.Stacks[i].Layers[j].H.V, dH);

      ListView.Items[Index].SubItems[2] := Convert(FStructure.Stacks[i].Layers[j].s.V, -dS);
      ListView.Items[Index].SubItems[3] := Convert(FStructure.Stacks[i].Layers[j].s.V, dS);

      ListView.Items[Index].SubItems[4] := Convert(FStructure.Stacks[i].Layers[j].r.V, -dRho);
      ListView.Items[Index].SubItems[5] := Convert(FStructure.Stacks[i].Layers[j].r.V, dRho);

      Inc(Index);
    end;
  end;
end;

procedure TfrmLimits.EditorKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
begin
  if Key = VK_RETURN then
    ListViewEditor.Visible:=False;
end;

procedure TfrmLimits.FormCreate(Sender: TObject);
begin
  //create the TEdit and assign the OnExit event
  ListViewEditor:=TRzEdit.Create(Self);
  ListViewEditor.Parent:=ListView;
  ListViewEditor.OnExit:=ListViewEditorExit;
  ListViewEditor.Visible:=False;
  ListViewEditor.OnKeyDown := EditorKeyDown;
end;

procedure TfrmLimits.ListViewClick(Sender: TObject);
var
  LPoint: TPoint;
  LVHitTestInfo: TLVHitTestInfo;

  function GetColumns(const X: integer):integer;
  begin
    Result := (X - 100) div 70 + 1;
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
end;

procedure TfrmLimits.RzBitBtn2Click(Sender: TObject);
begin
  ModalResult := mrCancel;
end;

procedure TfrmLimits.StructureToView;
var
  i, j: integer;
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

      ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].H.min, ffFixed, 5, 2));
      ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].H.max, ffFixed, 5, 2));

      ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].s.min, ffFixed, 5, 2));
      ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].s.max, ffFixed, 5, 2));

      ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].r.min, ffFixed, 5, 2));
      ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].r.max, ffFixed, 5, 2));
    end;
  end;
end;

procedure TfrmLimits.StructureFromView;
var
  i, j, Index: integer;

begin

  Index := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      FStructure.Stacks[i].Layers[j].H.min := StrToFloat(ListView.Items[Index].SubItems[0]);
      FStructure.Stacks[i].Layers[j].H.max := StrToFloat(ListView.Items[Index].SubItems[1]);

      FStructure.Stacks[i].Layers[j].s.min := StrToFloat(ListView.Items[Index].SubItems[2]);
      FStructure.Stacks[i].Layers[j].s.max := StrToFloat(ListView.Items[Index].SubItems[3]);

      FStructure.Stacks[i].Layers[j].r.min := StrToFloat(ListView.Items[Index].SubItems[4]);
      FStructure.Stacks[i].Layers[j].r.max := StrToFloat(ListView.Items[Index].SubItems[5]);

      Inc(Index);
    end;
  end;

end;

function TfrmLimits.Show(var Structure: TFitPeriodicStructure): boolean;
begin
  Result := False;
  FStructure := Structure;

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

end.
