unit unit_XRCProjectTree;

interface

uses
  System.SysUtils,
  WinApi.Windows,
  System.Types,
  System.Classes,
  Vcl.Controls,
  VCL.ComCtrls,
  Vcl.Graphics,
  VirtualTrees,
  VirtualTrees.Types,
  VirtualTrees.Colors,
  VirtualTrees.DragImage,
  VirtualTrees.Header,
  unit_Types;

type

  TXRCProjectTree = class (TVirtualStringTree)
    private
      FProjectVersion: Integer;

      procedure ProjectAdvancedHeaderDraw(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
      procedure ProjectFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
      procedure ProjectGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
      procedure ProjectPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
      procedure ProjectHeaderDrawQueryElements(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements);
      procedure ProjectLoadNode(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream);
      procedure ProjectSaveNode(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream);
    public
      constructor Create(AOwner: TComponent);
      destructor Free;

      property Version: Integer write FProjectVersion;
    published

  end;

implementation


{ TXRCProjectTree }

constructor TXRCProjectTree.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);

  //Project
  AlignWithMargins := True;
  Align := alClient;
  ButtonFillMode := fmTransparent;
  ButtonStyle := bsTriangle;
  Color := clWhite;
  Colors.BorderColor := clSkyBlue;
  Colors.DisabledColor := clGray;
  Colors.DropMarkColor := 15385233;
  Colors.DropTargetColor := 15385233;
  Colors.DropTargetBorderColor := 15385233;
  Colors.FocusedSelectionColor := 15385233;
  Colors.FocusedSelectionBorderColor := 15385233;
  Colors.GridLineColor := clSkyBlue;
  Colors.HeaderHotColor := clBlack;
  Colors.HotColor := clBlack;
  Colors.SelectionRectangleBlendColor := 15385233;
  Colors.SelectionRectangleBorderColor := 15385233;
  Colors.SelectionTextColor := clBlack;
  Colors.TreeLineColor := 9471874;
  Colors.UnfocusedColor := clGray;
  Colors.UnfocusedSelectionColor := clSkyBlue;
  Colors.UnfocusedSelectionBorderColor := clSkyBlue;
  DefaultNodeHeight := 25;
  DragMode := dmAutomatic;
  DragType := dtVCL;
  Font.Color := clWindowText;
  Font.Height := -13;
  Font.Name := 'Tahoma';
  Font.Style := [];
  Header.AutoSizeIndex := 0;
  Header.Background := 16765595;
  Header.Height := 23;
  Header.MainColumn := 1;
  Header.Options := [hoAutoResize, hoColumnResize, hoDrag, hoOwnerDraw, hoShowSortGlyphs, hoVisible];
  Header.ParentFont := False;
  Header.Font.Style := [fsBold];
  NodeAlignment := naFromTop;
  ParentFont := False;
  TabOrder := 1;
  TreeOptions.MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning];
  TreeOptions.PaintOptions := [toShowDropmark, toShowRoot, toThemeAware, toUseBlendedImages, toFullVertGridLines];
  TreeOptions.SelectionOptions := [toFullRowSelect, toRightClickSelect];
  Touch.InteractiveGestures := [TInteractiveGesture.igPan, TInteractiveGesture.igPressAndTap];
  Touch.InteractiveGestureOptions := [igoPanSingleFingerHorizontal, igoPanSingleFingerVertical, igoPanInertia, igoPanGutter, igoParentPassthrough];

  OnAdvancedHeaderDraw := ProjectAdvancedHeaderDraw;
  OnFreeNode := ProjectFreeNode;
  OnGetText := ProjectGetText;
  OnPaintText := ProjectPaintText;
  OnHeaderDrawQueryElements := ProjectHeaderDrawQueryElements;
  OnLoadNode := ProjectLoadNode;
  OnSaveNode := ProjectSaveNode;

  Header.Columns.Add;
  Header.Columns.Add;

  Header.Columns[0].Width    := 41;
  Header.Columns[0].CheckBox := True;
  Header.Columns[0].Options  := [coAllowClick,coDraggable,coEnabled,coParentBidiMode,coParentColor,coResizable,coShowDropMark,coVisible,coAllowFocus,coEditable,coStyleColor];

  Header.Columns[1].Width    := 180;
  Header.Columns[1].CheckBox := False;
  Header.Columns[1].Options  := [coAllowClick,coDraggable,coEnabled,coParentBidiMode,coParentColor,coResizable,coShowDropMark,coVisible,coAllowFocus,coEditable,coStyleColor];
  Header.Columns[1].Text := 'Project Items';
end;

destructor TXRCProjectTree.Free;
begin

  inherited Free;
end;

procedure TXRCProjectTree.ProjectAdvancedHeaderDraw(Sender: TVTHeader;
  var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
begin
  if hpeBackground in Elements then
  begin
    PaintInfo.TargetCanvas.Brush.Color := clSkyBlue; // <-- your color here
    if Assigned(PaintInfo.Column) then
      DrawFrameControl(PaintInfo.TargetCanvas.Handle, PaintInfo.PaintRectangle, DFC_BUTTON, DFCS_FLAT or DFCS_ADJUSTRECT); // <-- I think, that this keeps the style of the header background, but I'm not sure about that
    PaintInfo.TargetCanvas.FillRect(PaintInfo.PaintRectangle);
  end;
end;



procedure TXRCProjectTree.ProjectFreeNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode);
var
  Data: PProjectData;
begin
  Data := Sender.GetNodeData(Node);
  Finalize(Data^);
end;

procedure TXRCProjectTree.ProjectGetText(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType;
  var CellText: string);
var
  Data: PProjectData;
begin
  Data := Sender.GetNodeData(Node);
  case Column of
    1:
      CellText := Data.Title;
    0:
      CellText := '';
  end;
end;

procedure TXRCProjectTree.ProjectHeaderDrawQueryElements(Sender: TVTHeader;
  var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements);
begin
  Elements := [hpeBackground];
end;

procedure TXRCProjectTree.ProjectLoadNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Stream: TStream);
var
  Data: PProjectData;

  function GetString: string;
  var
    size: Integer;
    StrBuffer: PChar;
    Dumb: byte;
  begin
    Stream.Read(size, SizeOf(size));
    if Size > 1 then
    begin
      StrBuffer := AllocMem(size);
      Stream.Read(StrBuffer^, size);
      Result := (StrBuffer);
      FreeMem(StrBuffer);
    end
    else begin
      Stream.Read(Dumb, 1);
      Result := '';
    end;
  end;

begin
  Data := Sender.GetNodeData(Node);
  Stream.Read(Data.ID, SizeOf(Data.ID));
  Data.Title := GetString;
  Stream.Read(Data.RowType, SizeOf(Data.RowType));
  Stream.Read(Data.Group, SizeOf(Data.Group));
  Stream.Read(Data.Active, SizeOf(Data.Active));
  Stream.Read(Data.Visible, SizeOf(Data.Visible));
  Data.Description := GetString;
  Stream.Read(Data.Color, SizeOf(Data.Color));

  if FProjectVersion < 1 then Exit;

  Stream.Read(Data.Enabled, SizeOf(Data.Enabled));
  Stream.Read(Data.ExtType, SizeOf(Data.ExtType));
  Stream.Read(Data.Rate, SizeOf(Data.Rate));
  Data.ParentLayerName := GetString;
  Data.ParentStackName := GetString;
  Stream.Read(Data.Form, SizeOf(Data.Form));
  Stream.Read(Data.Subj, SizeOf(Data.Subj));

  if FProjectVersion < 2 then Exit;
  Data.Data := GetString;
end;

procedure TXRCProjectTree.ProjectPaintText(Sender: TBaseVirtualTree;
  const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  TextType: TVSTTextType);
var
  Data: PProjectData;
begin
  Data := Sender.GetNodeData(Node);
  if Data.RowType = prGroup then
    TargetCanvas.Font.Style := [fsBold];
  if Data.RowType = prFolder then
    TargetCanvas.Font.Style := [fsBold, fsItalic];
  if (Data.RowType <> prGroup) and  not Data.Enabled then
    TargetCanvas.Font.Color := clGray;

end;

procedure TXRCProjectTree.ProjectSaveNode(Sender: TBaseVirtualTree;
  Node: PVirtualNode; Stream: TStream);
var
  Data: PProjectData;
  size: Integer;

  procedure WriteString(const s: string);
  begin
    size := ByteLength(s) + 1;
    Stream.Write(size, SizeOf(size));
    Stream.Write(PChar(s)^, size);
  end;

begin
  Data := Sender.GetNodeData(Node);
  if Data = Nil then
    Exit;
  Stream.Write(Data.ID, SizeOf(Data.ID));
  WriteString(Data.Title);
  Stream.Write(Data.RowType, SizeOf(Data.RowType));
  Stream.Write(Data.Group, SizeOf(Data.Group));
  Stream.Write(Data.Active, SizeOf(Data.Active));
  Stream.Write(Data.Visible, SizeOf(Data.Visible));
  WriteString(Data.Description);
  Stream.Write(Data.Color, SizeOf(Data.Color));
  Stream.Write(Data.Enabled, SizeOf(Data.Enabled));
  Stream.Write(Data.ExtType, SizeOf(Data.ExtType));
  Stream.Write(Data.Rate, SizeOf(Data.Rate));
  WriteString(Data.ParentLayerName);
  WriteString(Data.ParentStackName);
  Stream.Write(Data.Form, SizeOf(Data.Form));
  Stream.Write(Data.Subj, SizeOf(Data.Subj));
  WriteString(Data.Data);
end;

end.
