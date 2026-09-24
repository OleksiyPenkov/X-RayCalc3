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
  RzListVw, unit_Types, unit_SmartLimits, Vcl.StdCtrls, Vcl.Buttons, RzButton, Vcl.Menus;

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
    btnFreeze: TBitBtn;
    btnThaw: TBitBtn;
    pmFreeze: TPopupMenu;
    miFreezeStack: TMenuItem;
    miFreezeLayer: TMenuItem;
    miFreezeAll: TMenuItem;
    miThawAll: TMenuItem;
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
    procedure btnFreezeClick(Sender: TObject);
    procedure btnThawClick(Sender: TObject);
    procedure miFreezeStackClick(Sender: TObject);
    procedure miFreezeLayerClick(Sender: TObject);
    procedure miFreezeAllClick(Sender: TObject);
    procedure miThawAllClick(Sender: TObject);
    procedure ListViewContextPopup(Sender: TObject; MousePos: TPoint;
      var Handled: Boolean);
  private
    ListViewEditor: TRzEdit;
    LItem: TListitem;
    FStructure: TFitStructure;
    FDPI: integer;
    FIssues: TArray<TLimitIssue>;

    function StackCaption(const StackIndex: Integer): string;

    procedure UserEditListView( Var Message: TMessage ); message USER_EDITLISTVIEW;
    procedure ListViewEditorExit(Sender: TObject);
    procedure EditorKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure StructureToView;
    procedure StructureFromView;
    procedure RunValidation;
    procedure ToggleFreezeAt(Item: TListItem; const ParamIndex: Integer);
    procedure SetFreeze(const Frozen, AllRows, StackOnly: Boolean);
  public
    { Public declarations }

    function ShowLimits(const ACaption: string; var Structure: TFitStructure): boolean;
  end;

var
  frmLimits: TfrmLimits;

implementation

{$R *.dfm}

uses
  System.UITypes, System.Math, CommCtrl, math_globals, math_complex;

var
  EDIT_COLUMN: integer;

procedure TfrmLimits.btnInitClick(Sender: TObject);
var
  i, j, p, Count, Index: integer;
  dP: array [1..3] of single;
  NroValues: array of Single;
  f: TComplex;
  Na, Nro, Rho: Single;

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
      Count := 1;
      for p := 1 to 3 do
      begin
        { A frozen parameter keeps the window it was given - Initialize is the
          one path that used to overwrite it. ApplyMaterialDensity above skips
          frozen Rho for the same reason. }
        if FStructure.Stacks[i].Layers[j].P[p].Fixed then
        begin
          Inc(Count, 3);
          Continue;
        end;

        if (p = 3) and (Index <= High(NroValues)) and (NroValues[Index] > 0) then
        begin
          { Rho: around the layer's own density (a thin carbon contamination
            at 0.9 is far from bulk 2.26, and a window around bulk would leave
            it out), with the maximum capped at the table's bulk value, the
            one physical ceiling - unless the density is already above it. }
          Rho := FStructure.Stacks[i].Layers[j].P[3].V;
          ListView.Items[Index].SubItems[Count] := Convert(Rho, -dP[p]);
          ListView.Items[Index].SubItems[Count + 1] := FloatToStrF(
            Max(Rho, Min(Rho * (1 + dP[p]), NroValues[Index])), ffFixed, 5, 2);
        end
        else
        begin
          ListView.Items[Index].SubItems[Count] := Convert(FStructure.Stacks[i].Layers[j].P[p].V, -dP[p]);
          ListView.Items[Index].SubItems[Count + 1] := Convert(FStructure.Stacks[i].Layers[j].P[p].V, dP[p]);
        end;
        Inc(Count, 3);
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
  WidenAtLimit(FStructure, 0.5, BulkDensities(FStructure));
  ClampToPhysics(FStructure);
  ApplyGeometryCoupling(FStructure);
  StructureToView;
end;

procedure TfrmLimits.btnFixClick(Sender: TObject);
begin
  StructureFromView;
  AutoFixErrors(FStructure, BulkDensities(FStructure));
  WidenAtLimit(FStructure, 0.5, BulkDensities(FStructure));
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
  P: Integer;

  function GetColumns(const X: integer): integer;
  var
    i, Edge: integer;
  begin
    Edge := 0;
    for i := 0 to ListView.Columns.Count - 1 do
    begin
      Inc(Edge, ListView.Columns[i].Width);
      if X < Edge then
        Exit(i);
    end;
    Result := -1;
  end;

begin
  LPoint:= ListView.ScreenToClient(Mouse.CursorPos);

  EDIT_COLUMN := GetColumns(LPoint.X);

  P := FreezeParamOf(EDIT_COLUMN);
  if P > 0 then
  begin
    ListViewEditor.Visible := False;
    ToggleFreezeAt(ListView.GetItemAt(LPoint.X, LPoint.Y), P);
    Exit;
  end;

  ZeroMemory( @LVHitTestInfo, SizeOf(LVHitTestInfo));
  LVHitTestInfo.pt := LPoint;
  //Check if the click was made in the column to edit
  If (ListView.perform( LVM_SUBITEMHITTEST, 0, LPARAM(@LVHitTestInfo))<>-1) and ( LVHitTestInfo.iSubItem = EDIT_COLUMN ) Then
    PostMessage( self.Handle, USER_EDITLISTVIEW, LVHitTestInfo.iItem, 0 )
  else
    ListViewEditor.Visible:=False; //hide the TEdit
end;

{ A native list view does not move focus or selection on a right-click, so the
  popup would otherwise act on whatever was last left-clicked - possibly a row
  in another stack, possibly nothing at all. Resolve the row under the cursor
  first. A right-click inside an existing multi-selection keeps it; one outside
  replaces it, as Explorer does. MousePos is (-1, -1) for the keyboard menu
  key, where GetItemAt finds nothing and the current focus stands. }
procedure TfrmLimits.ListViewContextPopup(Sender: TObject; MousePos: TPoint;
  var Handled: Boolean);
var
  Item: TListItem;
  i: Integer;
begin
  Item := ListView.GetItemAt(MousePos.X, MousePos.Y);
  if Item = nil then
    Exit;

  if not Item.Selected then
    for i := 0 to ListView.Items.Count - 1 do
      ListView.Items[i].Selected := ListView.Items[i] = Item;

  ListView.ItemFocused := Item;
end;

procedure TfrmLimits.ToggleFreezeAt(Item: TListItem; const ParamIndex: Integer);
var
  i, j, Index: Integer;
begin
  if Item = nil then
    Exit;

  Index := 0;
  for i := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      if Index = Item.Index then
      begin
        with FStructure.Stacks[i].Layers[j].P[ParamIndex] do
          Fixed := not Fixed;
        StructureToView;
        Exit;
      end;
      Inc(Index);
    end;
end;

{ Frozen: True freezes, False thaws. StackOnly limits the sweep to the stack the
  focused row belongs to; AllRows ignores the selection entirely. }
procedure TfrmLimits.SetFreeze(const Frozen, AllRows, StackOnly: Boolean);
var
  i, j, p, Index, FocusStack: Integer;
  Touch: Boolean;
begin
  FocusStack := -1;
  if StackOnly then
  begin
    if ListView.ItemFocused = nil then
      Exit;
    Index := 0;
    for i := 0 to High(FStructure.Stacks) do
      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        if Index = ListView.ItemFocused.Index then
          FocusStack := i;
        Inc(Index);
      end;
  end;

  Index := 0;
  for i := 0 to High(FStructure.Stacks) do
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      if AllRows then
        Touch := True
      else if StackOnly then
        Touch := (i = FocusStack)
      else
        Touch := ListView.Items[Index].Selected;

      if Touch then
        for p := 1 to 3 do
          FStructure.Stacks[i].Layers[j].P[p].Fixed := Frozen;

      Inc(Index);
    end;

  StructureToView;
end;

procedure TfrmLimits.btnFreezeClick(Sender: TObject);
begin
  SetFreeze(True, False, False);
end;

procedure TfrmLimits.btnThawClick(Sender: TObject);
begin
  SetFreeze(False, False, False);
end;

procedure TfrmLimits.miFreezeStackClick(Sender: TObject);
begin
  SetFreeze(True, False, True);
end;

procedure TfrmLimits.miFreezeLayerClick(Sender: TObject);
begin
  SetFreeze(True, False, False);
end;

procedure TfrmLimits.miFreezeAllClick(Sender: TObject);
begin
  SetFreeze(True, True, False);
end;

procedure TfrmLimits.miThawAllClick(Sender: TObject);
begin
  SetFreeze(False, True, False);
end;

procedure TfrmLimits.ListViewEditorExit(Sender: TObject);
begin
  If Assigned(LItem) and (FreezeParamOf(EDIT_COLUMN) = 0) Then
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

function TfrmLimits.StackCaption(const StackIndex: Integer): string;
var
  j, p, Frozen, Total: Integer;
begin
  Frozen := 0;
  Total := 0;
  for j := 0 to High(FStructure.Stacks[StackIndex].Layers) do
    for p := 1 to 3 do
    begin
      Inc(Total);
      if FStructure.Stacks[StackIndex].Layers[j].P[p].Fixed then
        Inc(Frozen);
    end;

  Result := FStructure.Stacks[StackIndex].Header;
  if Frozen = 0 then
    Exit;
  { An em dash as a literal byte would be mojibake: this file has no BOM, so
    the compiler reads it in the system ANSI codepage. }
  if Frozen = Total then
    Result := Format('%s '#8212' all %d frozen', [Result, Total])
  else
    Result := Format('%s '#8212' %d of %d frozen', [Result, Frozen, Total]);
end;

{ Rebuilding the list drops every Selected flag and nils ItemFocused, which
  would cost the user the selection they just froze - and make a second
  "Freeze this stack" a silent no-op. Row indices are stable here: the row
  count follows the structure, which this dialog never changes. }
procedure TfrmLimits.StructureToView;
var
  i, j, p: integer;
  Group: TListGroup;
  ListItem: TListItem;
  Selection: TArray<Integer>;
  Focused: Integer;
begin
  SetLength(Selection, 0);
  for i := 0 to ListView.Items.Count - 1 do
    if ListView.Items[i].Selected then
    begin
      SetLength(Selection, Length(Selection) + 1);
      Selection[High(Selection)] := i;
    end;
  if ListView.ItemFocused <> nil then
    Focused := ListView.ItemFocused.Index
  else
    Focused := -1;

  ListView.Items.BeginUpdate;
  try
    ListView.Items.Clear;
    ListView.Groups.Clear;

    for I := 0 to High(FStructure.Stacks) do
    begin
      Group := ListView.Groups.Add;
      Group.Header := StackCaption(i);

      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        ListItem := ListView.Items.Add;
        ListItem.GroupID := Group.GroupID;
        ListItem.Caption := FStructure.Stacks[i].Layers[j].Material;

        for p := 1 to 3 do
        begin
          if FStructure.Stacks[i].Layers[j].P[p].Fixed then
            ListItem.SubItems.Add('X')
          else
            ListItem.SubItems.Add('');
          ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].P[p].min, ffFixed, 5, 2));
          ListItem.SubItems.Add(FloatToStrF(FStructure.Stacks[i].Layers[j].P[p].max, ffFixed, 5, 2));
        end;
      end;
    end;

    for i := 0 to High(Selection) do
      if Selection[i] < ListView.Items.Count then
        ListView.Items[Selection[i]].Selected := True;
    if (Focused >= 0) and (Focused < ListView.Items.Count) then
      ListView.ItemFocused := ListView.Items[Focused];
  finally
    ListView.Items.EndUpdate;
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
      Count := 1;
      for p := 1 to 3 do
      begin
        FStructure.Stacks[i].Layers[j].P[p].min := StrToFloat(ListView.Items[Index].SubItems[Count]);
        FStructure.Stacks[i].Layers[j].P[p].max := StrToFloat(ListView.Items[Index].SubItems[Count + 1]);
        Inc(Count, 3);
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
  Cell: Integer;
begin
  if SubItem < 1 then
    Exit;

  if Item.SubItems[FreezeCellOf(SubItem)] = 'X' then
    Sender.Canvas.Font.Color := clGrayText
  else
    Sender.Canvas.Font.Color := clWindowText;

  Cell := LimitCellOf(SubItem);
  if Cell < 0 then
    Exit;

  Kind := CellState(FIssues, Item.Index, Cell);

  case Kind of
    likError:
      Sender.Canvas.Brush.Color := $CCCCFF;  // light red
    likWarning:
      Sender.Canvas.Brush.Color := $CCFFFF;  // light yellow
  end;
end;

end.
