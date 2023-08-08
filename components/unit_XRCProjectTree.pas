(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

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
      FActiveModel: PProjectData;
      FLinkedData: PProjectData;
      FIgnoreFocusChange: boolean;
      FActiveData: PProjectData;

      procedure ProjectAdvancedHeaderDraw(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
      procedure ProjectFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
      procedure ProjectGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
      procedure ProjectPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
      procedure ProjectHeaderDrawQueryElements(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements);
      procedure ProjectLoadNode(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream);
      procedure ProjectSaveNode(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream);
      procedure ProjectAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
      procedure ProjectBeforeCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
    public
      constructor Create(AOwner: TComponent);  override;
      destructor Destroy;  reintroduce; overload;

      property Version: Integer write FProjectVersion;
      property ActiveModel:PProjectData read FActiveModel write FActiveModel;
      property ActiveData:PProjectData read FActiveData write FActiveData;
      property LinkedData:PProjectData read FLinkedData write FLinkedData;
      property IgnoreFocusChange: boolean read FIgnoreFocusChange write FIgnoreFocusChange;
      function ProfileAttached(Node: PVirtualNode): Boolean;
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
  Indent := 10;
  Header.AutoSizeIndex := 0;
  Header.Background := 16765595;
  Header.Height := 23;
  Header.MainColumn := 1;
  Header.Options := [hoAutoResize, hoColumnResize, hoDrag, hoOwnerDraw, hoVisible];
  Header.ParentFont := False;
  Header.Font.Style := [fsBold];
  NodeAlignment := naFromTop;
  ParentFont := False;
  TreeOptions.MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning];
  TreeOptions.PaintOptions := [toShowButtons,toShowDropmark,toThemeAware,toUseBlendedImages,toUseExplorerTheme];
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
  OnAfterCellPaint := ProjectAfterCellPaint;
  OnBeforeCellPaint := ProjectBeforeCellPaint;

  Header.Columns.Add;
  Header.Columns.Add;

  Header.Columns[0].Width    := 41;
  Header.Columns[0].CheckBox := True;
  Header.Columns[0].Options  := [coAllowClick,coDraggable,coEnabled,coFixed,coParentBidiMode,coParentColor,coShowDropMark,coVisible,coAllowFocus];

  Header.Columns[1].Width    := 180;
  Header.Columns[1].CheckBox := False;
  Header.Columns[1].Options  := [coAllowClick,coDraggable,coEnabled,coParentBidiMode,coParentColor,coResizable,coShowDropMark,coVisible,coAllowFocus];
  Header.Columns[1].Text := 'Project Items';
end;

destructor TXRCProjectTree.Destroy;
begin

  inherited Free;
end;

function TXRCProjectTree.ProfileAttached(Node: PVirtualNode): Boolean;
var
  Data: PProjectData;
begin
  Result := False;

  Node := GetFirstChild(Node);
  if Node <> nil then
  begin
    repeat
      Data := GetNodeData(Node);
      if Data.ExtType = etTable then
      begin
        Result := True;
        Break;
      end;
      Node := GetNextSibling(Node);
    until Node = nil;
  end;
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

procedure TXRCProjectTree.ProjectAfterCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellRect: TRect);
const
  Points: array [0 .. 2] of TPoint = ((X: 22; Y: 5), (X: 32; Y: 10),
    (X: 22; Y: 15));

var
  Data: PProjectData;
begin
  if (Column <> 0) or FIgnoreFocusChange then
    Exit;

  Data := GetNodeData(Node);

  if Data = FActiveModel then
  begin
    TargetCanvas.Brush.Color := clRed;
    TargetCanvas.Pen.Color := clRed;
    TargetCanvas.Polygon(Points);
  end;

  if Data = FLinkedData then
  begin
    TargetCanvas.Pen.Color := clBlack;

    TargetCanvas.Ellipse(25, 2, 35, 15);
    TargetCanvas.Brush.Color := clGreen;
    TargetCanvas.Rectangle(25, 7, 35, 15);
    TargetCanvas.Rectangle(29, 9, 31, 13);
  end;

  TargetCanvas.Pen.Color := clGray;

  if Data.RowType = prItem then
  begin
    if Data.Visible then
      TargetCanvas.Brush.Color := Data.Color
    else
      TargetCanvas.Brush.Color := clLtGray;
    TargetCanvas.Rectangle(5, 5, 16, 16);
  end;
end;

procedure TXRCProjectTree.ProjectBeforeCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellPaintMode: TVTCellPaintMode; CellRect: TRect; var ContentRect: TRect);
var
  Data: PProjectData;
begin
  Data := Sender.GetNodeData(Node);
  case Data.RowType of
    prFolder: ContentRect.Left    := ContentRect.Left + 5;
    prGroup : ContentRect.Left    := ContentRect.Left + Integer(Indent);
    prItem  : ContentRect.Left    := ContentRect.Left + Integer(Indent) * 2;
    prExtension: ContentRect.Left := ContentRect.Left + Integer(Indent) * 3;
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
  S: string;
  p, i: Integer;

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

  case FProjectVersion of
    2: begin
          Stream.Read(Data.Enabled, SizeOf(Data.Enabled));
          Stream.Read(Data.ExtType, SizeOf(Data.ExtType));
          Stream.Read(Data.Poly[1], SizeOf(Data.Poly[1]));
          S := GetString;
          S := GetString;
          Stream.Read(Data.Form, SizeOf(Data.Form));
          Stream.Read(Data.Subj, SizeOf(Data.Subj));
          Data.Data := GetString;
       end;
    3: begin
          Stream.Read(Data.Enabled, SizeOf(Data.Enabled));
          Stream.Read(Data.ExtType, SizeOf(Data.ExtType));
          Stream.Read(Data.LayerID, SizeOf(Data.LayerID));
          Stream.Read(Data.StackID, SizeOf(Data.StackID));
          Stream.Read(Data.Form, SizeOf(Data.Form));
          Stream.Read(Data.Subj, SizeOf(Data.Subj));
          for I := 1 to 3 do
            Stream.Read(Data.Poly[i], SizeOf(Data.Poly[i]));
          Data.Data := GetString;
       end;
    4: begin
          Stream.Read(Data.Enabled, SizeOf(Data.Enabled));
          Stream.Read(Data.ExtType, SizeOf(Data.ExtType));
          Stream.Read(Data.LayerID, SizeOf(Data.LayerID));
          Stream.Read(Data.StackID, SizeOf(Data.StackID));
          Stream.Read(Data.Form, SizeOf(Data.Form));
          Stream.Read(Data.Subj, SizeOf(Data.Subj));
          for I := 1 to 10 do
            Stream.Read(Data.Poly[i], SizeOf(Data.Poly[i]));
          Data.Data := GetString;
       end;

    5: begin
          Stream.Read(Data.Enabled, SizeOf(Data.Enabled));
          Stream.Read(Data.ExtType, SizeOf(Data.ExtType));
          Stream.Read(Data.LayerID, SizeOf(Data.LayerID));
          Stream.Read(Data.StackID, SizeOf(Data.StackID));
          Stream.Read(Data.Form, SizeOf(Data.Form));
          Stream.Read(Data.Subj, SizeOf(Data.Subj));

          if (Data.Group = gtModel) and (Data.RowType = prExtension) then
            for I := 1 to 10 do
              Stream.Read(Data.Poly[i], SizeOf(Data.Poly[i]));

          if (Data.Group = gtModel) and (Data.RowType = prItem) then
            Data.Data := GetString;
       end;
  end; // case

  p := pos('}}', Data.Data);
  if p <> Length(Data.Data) - 1 then
      Data.Data := copy(Data.Data, 1, p + 1);
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
  size, i: Integer;

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
  Stream.Write(Data.LayerID, SizeOf(Data.LayerID));
  Stream.Write(Data.StackID, SizeOf(Data.StackID));
  Stream.Write(Data.Form, SizeOf(Data.Form));
  Stream.Write(Data.Subj, SizeOf(Data.Subj));

  if (Data.Group = gtModel) and (Data.RowType = prExtension) then
    for I := 1 to 10 do
              Stream.Write(Data.Poly[i], SizeOf(Data.Poly[i]));
  if (Data.Group = gtModel) and (Data.RowType = prItem) then
    WriteString(Data.Data);
end;

end.
