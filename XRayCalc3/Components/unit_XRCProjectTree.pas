(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
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
  Vcl.ImgList,
  Winapi.GDIPOBJ,
  Winapi.GDIPAPI,
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
      FTargetDPI: integer;
      FMarkerImages: TCustomImageList;

      procedure DrawMarker(TargetCanvas: TCanvas; const CellRect: TRect; const Index: Integer);
      procedure DrawColorSwatch(TargetCanvas: TCanvas; const CellRect: TRect; const AColor: TColor);

      procedure ProjectMeasureItem(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode;
                    var NodeHeight: TDimension);
      procedure ProjectAdvancedHeaderDraw(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo; const Elements: THeaderPaintElements);
      procedure ProjectFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
      procedure ProjectGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
      procedure ProjectPaintText(Sender: TBaseVirtualTree; const TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType);
      procedure ProjectHeaderDrawQueryElements(Sender: TVTHeader; var PaintInfo: THeaderPaintInfo; var Elements: THeaderPaintElements);
      procedure ProjectLoadNode(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream);
      procedure ProjectSaveNode(Sender: TBaseVirtualTree; Node: PVirtualNode; Stream: TStream);
      procedure ProjectAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
      function ScaleForDPI(Value: Integer): integer;
    public
      constructor Create(AOwner: TComponent; const DPI: integer); reintroduce; overload;
      destructor Destroy;  reintroduce; overload;
      property Version: Integer write FProjectVersion;
      property ActiveModel:PProjectData read FActiveModel write FActiveModel;
      property ActiveData:PProjectData read FActiveData write FActiveData;
      property LinkedData:PProjectData read FLinkedData write FLinkedData;
      property IgnoreFocusChange: boolean read FIgnoreFocusChange write FIgnoreFocusChange;
      { Markers painted in column 0. Deliberately not the inherited Images
        property, which would reserve space in the main column. }
      property MarkerImages: TCustomImageList read FMarkerImages write FMarkerImages;
      function ProfileAttached(Node: PVirtualNode): Boolean;
      property TargetDPI: integer read FTargetDPI write FTargetDPI;
      procedure Rescale;
    published

  end;

implementation

const
  DefaultDPI = 96;

  { Indices into MarkerImages (frame_ProjectPanel's vliTreeMarks). }
  MarkerActiveModel = 0;
  MarkerLinkedData  = 1;

  { Column 0 layout, in 96 dpi pixels. The column is 41 px wide, so the
    swatch and the 16 px marker sit side by side without touching. }
  SwatchLeft   = 5;
  SwatchSize   = 12;
  { A tighter radius keeps more of the outline on straight, pixel aligned
    edges, which is what reads as sharp at this size. }
  SwatchRadius = 2;
  MarkerLeft   = 21;

  { The marker icons' outline colour, so swatch and markers look related. }
  SwatchBorderColor = TColor($005F3719);

{ Rounded rectangle as a GDI+ path - GDI+ has no AddRoundedRect of its own. }
procedure AddRoundedRect(const Path: TGPGraphicsPath; const R: TGPRectF;
  const Radius: Single);
var
  D: Single;
begin
  D := Radius * 2;
  Path.AddArc(R.X, R.Y, D, D, 180, 90);
  Path.AddArc(R.X + R.Width - D, R.Y, D, D, 270, 90);
  Path.AddArc(R.X + R.Width - D, R.Y + R.Height - D, D, D, 0, 90);
  Path.AddArc(R.X, R.Y + R.Height - D, D, D, 90, 90);
  Path.CloseFigure;
end;

{ TXRCProjectTree }

function TXRCProjectTree.ScaleForDPI(Value: Integer): integer;
begin
  if FTargetDPI = DefaultDPI then
    Result := Value
  else
    Result := MulDiv(Value, FTargetDPI, DefaultDPI);
end;

constructor TXRCProjectTree.Create(AOwner: TComponent; const DPI: integer);
begin
  inherited Create(AOwner);
  FTargetDPI := DPI;

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
  DefaultNodeHeight := ScaleForDPI(25);
  DragMode := dmAutomatic;
  DragType := dtVCL;
  Font.Color := clWindowText;
  Font.Height := -13;//ScaleForDPI(16);
  Font.Name := 'Tahoma';
  Font.Style := [];
  { Wide enough for the Explorer chevron, which GetThemePartSize reports as
    16 px at 96 dpi. ChangeScale takes care of higher DPIs. }
  Indent := 16;
  { Spare width belongs to the item names, not to the marker column, which
    only ever holds a colour swatch and a 16 px marker. }
  Header.AutoSizeIndex := 1;
  Header.Background := 16765595;
  Header.Height := ScaleForDPI(23);
  Header.Options := [hoAutoResize, hoColumnResize, hoDrag, hoOwnerDraw, hoVisible];
  Header.ParentFont := False;
  Header.Font.Style := [fsBold];
  { naFromTop reads Node.Align as pixels from the node top, but its default
    value is 50 - a percentage meant for naProportional - which drops the
    expand button below the row and out of sight. The tree paints no node
    images, so naProportional only affects the button, which it centres. }
  NodeAlignment := naProportional;
  ParentFont := False;
  TreeOptions.MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize, toInitOnSave, toToggleOnDblClick, toWheelPanning];
  { toShowRoot is what gives the Models and Data nodes an expand button -
    without it VirtualTrees only paints one from node level 1 downwards. }
  TreeOptions.PaintOptions := [toShowButtons,toShowDropmark,toShowRoot,toThemeAware,toUseBlendedImages,toUseExplorerTheme];
  TreeOptions.SelectionOptions := [toFullRowSelect, toRightClickSelect, toMultiSelect];
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
  OnMeasureItem     := ProjectMeasureItem;

  Header.Columns.Add;
  Header.Columns.Add;

  Header.Columns[0].Width    := ScaleForDPI(41);
  Header.Columns[0].CheckBox := True;
  Header.Columns[0].Options  := [coAllowClick,coDraggable,coEnabled,coFixed,coParentBidiMode,coParentColor,coShowDropMark,coVisible,coAllowFocus];

  Header.Columns[1].Width    := 180; //ScaleForDPI(180);
  Header.Columns[1].CheckBox := False;
  Header.Columns[1].Options  := [coAllowClick,coDraggable,coEnabled,coParentBidiMode,coParentColor,coResizable,coShowDropMark,coVisible,coAllowFocus];
  Header.Columns[1].Text := 'Project Items';

  { Must come after the columns exist: TVTHeader.SetMainColumn clamps the value
    to Columns.Count - 1, so an earlier assignment is silently dropped and the
    tree ends up with no main column - hence no indentation and no expand
    buttons anywhere. }
  Header.MainColumn := 1;
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

procedure TXRCProjectTree.DrawMarker(TargetCanvas: TCanvas;
  const CellRect: TRect; const Index: Integer);
var
  X, Y: Integer;
begin
  if not Assigned(FMarkerImages) then
    Exit;

  X := CellRect.Left + ScaleForDPI(MarkerLeft);
  Y := CellRect.Top + (CellRect.Height - FMarkerImages.Height) div 2;
  FMarkerImages.Draw(TargetCanvas, X, Y, Index, True);
end;

procedure TXRCProjectTree.DrawColorSwatch(TargetCanvas: TCanvas;
  const CellRect: TRect; const AColor: TColor);
var
  Graphics: TGPGraphics;
  Path: TGPGraphicsPath;
  Brush: TGPSolidBrush;
  Pen: TGPPen;
  Size, X, Y: Integer;
begin
  Size := ScaleForDPI(SwatchSize);
  X := CellRect.Left + ScaleForDPI(SwatchLeft);
  Y := CellRect.Top + (CellRect.Height - Size) div 2;

  Graphics := TGPGraphics.Create(TargetCanvas.Handle);
  try
    Graphics.SetSmoothingMode(SmoothingModeAntiAlias);
    Graphics.SetPixelOffsetMode(PixelOffsetModeHalf);

    Path := TGPGraphicsPath.Create;
    try
      { With PixelOffsetModeHalf the half pixel inset is what puts the one
        pixel border on whole pixels instead of straddling two - measured, the
        other three combinations of offset mode and inset all leave a halo.
        The path spans Size - 1, which the border widens to Size. }
      AddRoundedRect(Path, MakeRect(X + 0.5, Y + 0.5, Size - 1.0, Size - 1.0),
        ScaleForDPI(SwatchRadius));

      Brush := TGPSolidBrush.Create(ColorRefToARGB(ColorToRGB(AColor)));
      try
        Graphics.FillPath(Brush, Path);
      finally
        Brush.Free;
      end;

      Pen := TGPPen.Create(ColorRefToARGB(ColorToRGB(SwatchBorderColor)), 1);
      try
        Graphics.DrawPath(Pen, Path);
      finally
        Pen.Free;
      end;
    finally
      Path.Free;
    end;
  finally
    Graphics.Free;
  end;
end;

procedure TXRCProjectTree.ProjectAfterCellPaint(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex;
  CellRect: TRect);
var
  Data: PProjectData;
begin
  if (Column <> 0) or FIgnoreFocusChange then
    Exit;

  Data := GetNodeData(Node);
  if Data = nil then
    Exit;

  if Data.RowType = prItem then
  begin
    if Data.Visible then
      DrawColorSwatch(TargetCanvas, CellRect, Data.Color)
    else
      DrawColorSwatch(TargetCanvas, CellRect, clLtGray);
  end;

  if Data = FActiveModel then
    DrawMarker(TargetCanvas, CellRect, MarkerActiveModel);

  if Data = FLinkedData then
    DrawMarker(TargetCanvas, CellRect, MarkerLinkedData);
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
  p, i, Order: Integer;

  { Everything after the fixed header belongs to the prExtension branch of
    TProjectData, which shares memory with prItem's ID, CurveID, Color, Active
    and Visible. ProjectSaveNode writes those fields for every node, so they
    have to be read back for every node - but they may only be STORED on a node
    that really is an extension.

    Reading them straight into Data worked only while the branch's layout was
    frozen. It is not: FromFit was inserted after Enabled and PolyCount before
    Poly, which moved ExtType from the second byte of ID onto the third and put
    PolyCount right on top of Active and Visible. An older project whose data
    items carry a Unix-timestamp ID then loaded with an ID matching neither
    [STATE] LinkedData nor its own data_<ID>.dat, and RecoverDataCurves dropped
    the node - the linked measured curve simply vanished.

    So: read into locals, copy into Data only for a real extension. The file
    format is untouched; only where the bytes land has been fixed. }
  LEnabled: Boolean;
  LExtType: TExtentionType;
  LStackID, LLayerID, LPolyCount: Integer;
  LPoly: array [0 .. 9] of Single;
  LForm: TFunctionForm;
  LSubj: TParameterType;
  LCoeff: Single;

  function GetString: string;
  var
    size: Integer;
    StrBuffer: PChar;
    Dumb: byte;
  begin
    Stream.Read(size, SizeOf(size));
    if Size > 1 then
    begin
      { ProjectSaveNode writes ByteLength(s) + 1 bytes: the characters plus the
        LOW byte of the terminating #0 only. Reading that into a buffer of
        exactly that size leaves no complete WideChar #0 at the end, so the
        PChar -> string conversion below runs past the buffer and appends
        whatever the heap holds there. Two extra zero bytes (AllocMem zeroes
        the block) terminate it properly. Nothing in the file format changes -
        this is the reader alone. }
      StrBuffer := AllocMem(size + 2);
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
  LEnabled := False;
  LExtType := etNone;
  LStackID := 0;
  LLayerID := 0;
  LPolyCount := 0;
  FillChar(LPoly, SizeOf(LPoly), 0);
  LForm := ffNone;
  LSubj := ptH;

  Data := Sender.GetNodeData(Node);
  Stream.Read(Data.ID, SizeOf(Integer));
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
          Stream.Read(LEnabled, SizeOf(LEnabled));
          Stream.Read(LExtType, SizeOf(LExtType));
          Stream.Read(LPoly[1], SizeOf(LPoly[1]));
          LPolyCount := 1;
          S := GetString;
          S := GetString;
          Stream.Read(LForm, SizeOf(LForm));
          Stream.Read(LSubj, SizeOf(LSubj));
          Data.Data := GetString;
       end;
    3: begin
          Stream.Read(LEnabled, SizeOf(LEnabled));
          Stream.Read(LExtType, SizeOf(LExtType));
          Stream.Read(LLayerID, SizeOf(Integer));
          Stream.Read(LStackID, SizeOf(Integer));
          Stream.Read(LForm, SizeOf(LForm));
          Stream.Read(LSubj, SizeOf(LSubj));
          for I := 1 to 3 do
            Stream.Read(LPoly[i], SizeOf(LPoly[i]));
          LPolyCount := 3;
          Data.Data := GetString;
       end;
    4: begin
          Stream.Read(LEnabled, SizeOf(LEnabled));
          Stream.Read(LExtType, SizeOf(LExtType));
          Stream.Read(LLayerID, SizeOf(Integer));
          Stream.Read(LStackID, SizeOf(Integer));
          Stream.Read(LForm, SizeOf(LForm));
          Stream.Read(LSubj, SizeOf(LSubj));
          for I := 1 to 9 do
            Stream.Read(LPoly[i], SizeOf(LPoly[i]));
          Stream.Read(Order, SizeOf(Single)); // skip legacy Poly[10]
          LPolyCount := 9;
          Data.Data := GetString;
       end;

    5: begin
          Stream.Read(LEnabled, SizeOf(LEnabled));
          Stream.Read(LExtType, SizeOf(LExtType));
          Stream.Read(LLayerID, SizeOf(Integer));
          Stream.Read(LStackID, SizeOf(Integer));
          Stream.Read(LForm, SizeOf(LForm));
          Stream.Read(LSubj, SizeOf(LSubj));

          if (Data.Group = gtModel) and (Data.RowType = prExtension) then
          begin
            for I := 1 to 9 do
              Stream.Read(LPoly[i], SizeOf(LPoly[i]));
            Stream.Read(Order, SizeOf(Single)); // skip legacy Poly[10]
            LPolyCount := 9;
          end;

          if (Data.Group = gtModel) and (Data.RowType = prItem) then
            Data.Data := GetString;
       end;
    6, 7: begin
          Stream.Read(LEnabled, SizeOf(LEnabled));
          Stream.Read(LExtType, SizeOf(LExtType));
          Stream.Read(LLayerID, SizeOf(Integer));
          Stream.Read(LStackID, SizeOf(Integer));
          Stream.Read(LForm, SizeOf(LForm));
          Stream.Read(LSubj, SizeOf(LSubj));

          if (Data.Group = gtModel) and (Data.RowType = prExtension) then
          begin
            // Order is whatever the file says, so consume every coefficient
            // to keep the stream in step but keep only the ones that fit.
            Stream.Read(Order, SizeOf(Order));
            for I := 1 to Order do
            begin
              Stream.Read(LCoeff, SizeOf(LCoeff));
              if I <= High(LPoly) then
                LPoly[i] := LCoeff;
            end;
            if Order > High(LPoly) then
              LPolyCount := High(LPoly)
            else
              LPolyCount := Order;
          end;

          if (Data.Group = gtModel) and (Data.RowType = prItem) then
            Data.Data := GetString;
       end;

  end; // case

  // Only an extension owns these fields; on any other node they would land on
  // ID, CurveID, Color, Active and Visible.
  if Data.RowType = prExtension then
  begin
    Data.Enabled := LEnabled;
    { FromFit is NOT touched here, despite what its declaration in unit_Types
      says about being runtime only. On an extension the four bytes of the
      header's ID field are Enabled, FromFit, ExtType and padding, so
      ProjectSaveNode really does store the flag and the read of Data.ID above
      really does restore it. Clearing it here would leave every extension
      loaded from a project looking as if a human had drawn it, and
      RunFitting would stop asking whether to keep or clear the gradients a
      previous fit produced before starting a new one. }
    Data.ExtType := LExtType;
    Data.StackID := LStackID;
    Data.LayerID := LLayerID;
    Data.PolyCount := LPolyCount;
    for I := 0 to High(LPoly) do
      Data.Poly[I] := LPoly[I];
    Data.Form := LForm;
    Data.Subj := LSubj;
  end;

  p := pos('}}', Data.Data);
  if p <> Length(Data.Data) - 1 then
      Data.Data := copy(Data.Data, 1, p + 1);

  if pos('Models', Data.Title) > 0 then Data.Title := 'Models';
  if pos('Data', Data.Title) > 0 then Data.Title := 'Data';
end;

procedure TXRCProjectTree.ProjectMeasureItem(Sender: TBaseVirtualTree;
  TargetCanvas: TCanvas; Node: PVirtualNode; var NodeHeight: TDimension);
begin
  NodeHeight := ScaleForDPI(NodeHeight);
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
  size, i, order: Integer;

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
  begin
    Order := Data.PolyCount;
    Stream.Write(Order, SizeOf(Order));
    for I := 1 to Order do
              Stream.Write(Data.Poly[i], SizeOf(Data.Poly[i]));
  end;
  if (Data.Group = gtModel) and (Data.RowType = prItem) then
    WriteString(Data.Data);
end;

procedure TXRCProjectTree.Rescale;
var
  Node: PVirtualNode;
begin
   ScaleForPPI(FTargetDPI);
  Node := GetFirstNoInit;
  while Assigned(Node) do
  begin
    Node.SetNodeHeight(ScaleForDPI(23));
    Node := GetNextNoInit(Node, True);
  end;
end;

end.
