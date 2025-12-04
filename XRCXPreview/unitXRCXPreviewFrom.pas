unit unitXRCXPreviewFrom;

{$WARN SYMBOL_PLATFORM OFF}

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, Vcl.Graphics, Vcl.Controls,
  Vcl.Forms, Vcl.Dialogs, Winapi.ActiveX, Vcl.AxCtrls, XRCXPreview_TLB, StdVcl,
  Vcl.StdCtrls, VCLTee.TeEngine, Vcl.ExtCtrls, VCLTee.TeeProcs, VCLTee.Chart;

type
  TXRCXPreviewFrom = class(TActiveForm, IXRCXPreviewFrom)
    Chart: TChart;
  private
    { Private declarations }
    FEvents: IXRCXPreviewFromEvents;
    procedure ActivateEvent(Sender: TObject);
    procedure AfterMonitorDpiChangedEvent(Sender: TObject; OldDPI, NewDPI: Integer);
    procedure BeforeMonitorDpiChangedEvent(Sender: TObject; OldDPI, NewDPI: Integer);

    procedure ClickEvent(Sender: TObject);
    procedure CreateEvent(Sender: TObject);
    procedure DblClickEvent(Sender: TObject);
    procedure DeactivateEvent(Sender: TObject);
    procedure DestroyEvent(Sender: TObject);
    procedure KeyPressEvent(Sender: TObject; var Key: Char);
    procedure MouseEnterEvent(Sender: TObject);
    procedure MouseLeaveEvent(Sender: TObject);
    procedure PaintEvent(Sender: TObject);
  protected
    { Protected declarations }
    procedure DefinePropertyPages(DefinePropertyPage: TDefinePropertyPage); override;
    procedure EventSinkChanged(const EventSink: IUnknown); override;
    function Get_Active: WordBool; safecall;
    function Get_AlignDisabled: WordBool; safecall;
    function Get_AlignWithMargins: WordBool; safecall;
    function Get_AutoScroll: WordBool; safecall;
    function Get_AutoSize: WordBool; safecall;
    function Get_AxBorderStyle: TxActiveFormBorderStyle; safecall;
    function Get_BorderWidth: Integer; safecall;
    function Get_Caption: WideString; safecall;
    function Get_Color: OLE_COLOR; safecall;
    function Get_CurrentPPI: Integer; safecall;
    function Get_DockSite: WordBool; safecall;
    function Get_DoubleBuffered: WordBool; safecall;
    function Get_DoubleBufferedMode: TxDoubleBufferedMode; safecall;
    function Get_DropTarget: WordBool; safecall;
    function Get_Enabled: WordBool; safecall;
    function Get_ExplicitHeight: Integer; safecall;
    function Get_ExplicitLeft: Integer; safecall;
    function Get_ExplicitTop: Integer; safecall;
    function Get_ExplicitWidth: Integer; safecall;
    function Get_Font: IFontDisp; safecall;
    function Get_HelpFile: WideString; safecall;
    function Get_IsDrawingLocked: WordBool; safecall;
    function Get_KeyPreview: WordBool; safecall;
    function Get_MouseInClient: WordBool; safecall;
    function Get_ParentCustomHint: WordBool; safecall;
    function Get_ParentDoubleBuffered: WordBool; safecall;
    function Get_PixelsPerInch: Integer; safecall;
    function Get_PopupMode: TxPopupMode; safecall;
    function Get_PrintScale: TxPrintScale; safecall;
    function Get_RaiseOnNonMainThreadUsage: WordBool; safecall;
    function Get_RedrawDisabled: WordBool; safecall;
    function Get_RoundedCorners: TxRoundedCornerType; safecall;
    function Get_Scaled: WordBool; safecall;
    function Get_ScaleFactor: Single; safecall;
    function Get_ScreenSnap: WordBool; safecall;
    function Get_SnapBuffer: Integer; safecall;
    function Get_StyleName: WideString; safecall;
    function Get_UseDockManager: WordBool; safecall;
    function Get_Visible: WordBool; safecall;
    function Get_VisibleDockClientCount: Integer; safecall;
    procedure _Set_Font(var Value: IFontDisp); safecall;
    procedure Set_AlignWithMargins(Value: WordBool); safecall;
    procedure Set_AutoScroll(Value: WordBool); safecall;
    procedure Set_AutoSize(Value: WordBool); safecall;
    procedure Set_AxBorderStyle(Value: TxActiveFormBorderStyle); safecall;
    procedure Set_BorderWidth(Value: Integer); safecall;
    procedure Set_Caption(const Value: WideString); safecall;
    procedure Set_Color(Value: OLE_COLOR); safecall;
    procedure Set_DockSite(Value: WordBool); safecall;
    procedure Set_DoubleBuffered(Value: WordBool); safecall;
    procedure Set_DoubleBufferedMode(Value: TxDoubleBufferedMode); safecall;
    procedure Set_DropTarget(Value: WordBool); safecall;
    procedure Set_Enabled(Value: WordBool); safecall;
    procedure Set_Font(const Value: IFontDisp); safecall;
    procedure Set_HelpFile(const Value: WideString); safecall;
    procedure Set_KeyPreview(Value: WordBool); safecall;
    procedure Set_ParentCustomHint(Value: WordBool); safecall;
    procedure Set_ParentDoubleBuffered(Value: WordBool); safecall;
    procedure Set_PixelsPerInch(Value: Integer); safecall;
    procedure Set_PopupMode(Value: TxPopupMode); safecall;
    procedure Set_PrintScale(Value: TxPrintScale); safecall;
    procedure Set_RaiseOnNonMainThreadUsage(Value: WordBool); safecall;
    procedure Set_RoundedCorners(Value: TxRoundedCornerType); safecall;
    procedure Set_Scaled(Value: WordBool); safecall;
    procedure Set_ScreenSnap(Value: WordBool); safecall;
    procedure Set_SnapBuffer(Value: Integer); safecall;
    procedure Set_StyleName(const Value: WideString); safecall;
    procedure Set_UseDockManager(Value: WordBool); safecall;
    procedure Set_Visible(Value: WordBool); safecall;
  public
    { Public declarations }
    procedure Initialize; override;
  end;

implementation

uses System.Win.ComObj, System.Win.ComServ;

{$R *.DFM}

{ TXRCXPreviewFrom }

procedure TXRCXPreviewFrom.DefinePropertyPages(DefinePropertyPage: TDefinePropertyPage);
begin
  { Define property pages here.  Property pages are defined by calling
    DefinePropertyPage with the class id of the page.  For example,
      DefinePropertyPage(Class_XRCXPreviewFromPage); }
end;

procedure TXRCXPreviewFrom.EventSinkChanged(const EventSink: IUnknown);
begin
  FEvents := EventSink as IXRCXPreviewFromEvents;
  inherited EventSinkChanged(EventSink);
end;

procedure TXRCXPreviewFrom.Initialize;
begin
  inherited Initialize;
  OnActivate := ActivateEvent;
  OnAfterMonitorDpiChanged := AfterMonitorDpiChangedEvent;
  OnBeforeMonitorDpiChanged := BeforeMonitorDpiChangedEvent;
  OnClick := ClickEvent;
  OnCreate := CreateEvent;
  OnDblClick := DblClickEvent;
  OnDeactivate := DeactivateEvent;
  OnDestroy := DestroyEvent;
  OnKeyPress := KeyPressEvent;
  OnMouseEnter := MouseEnterEvent;
  OnMouseLeave := MouseLeaveEvent;
  OnPaint := PaintEvent;
end;

function TXRCXPreviewFrom.Get_Active: WordBool;
begin
  Result := Active;
end;

function TXRCXPreviewFrom.Get_AlignDisabled: WordBool;
begin
  Result := AlignDisabled;
end;

function TXRCXPreviewFrom.Get_AlignWithMargins: WordBool;
begin
  Result := AlignWithMargins;
end;

function TXRCXPreviewFrom.Get_AutoScroll: WordBool;
begin
  Result := AutoScroll;
end;

function TXRCXPreviewFrom.Get_AutoSize: WordBool;
begin
  Result := AutoSize;
end;

function TXRCXPreviewFrom.Get_AxBorderStyle: TxActiveFormBorderStyle;
begin
  Result := Ord(AxBorderStyle);
end;

function TXRCXPreviewFrom.Get_BorderWidth: Integer;
begin
  Result := Integer(BorderWidth);
end;

function TXRCXPreviewFrom.Get_Caption: WideString;
begin
  Result := WideString(Caption);
end;

function TXRCXPreviewFrom.Get_Color: OLE_COLOR;
begin
  Result := OLE_COLOR(Color);
end;

function TXRCXPreviewFrom.Get_CurrentPPI: Integer;
begin
  Result := CurrentPPI;
end;

function TXRCXPreviewFrom.Get_DockSite: WordBool;
begin
  Result := DockSite;
end;

function TXRCXPreviewFrom.Get_DoubleBuffered: WordBool;
begin
  Result := DoubleBuffered;
end;

function TXRCXPreviewFrom.Get_DoubleBufferedMode: TxDoubleBufferedMode;
begin
  Result := Ord(DoubleBufferedMode);
end;

function TXRCXPreviewFrom.Get_DropTarget: WordBool;
begin
  Result := DropTarget;
end;

function TXRCXPreviewFrom.Get_Enabled: WordBool;
begin
  Result := Enabled;
end;

function TXRCXPreviewFrom.Get_ExplicitHeight: Integer;
begin
  Result := ExplicitHeight;
end;

function TXRCXPreviewFrom.Get_ExplicitLeft: Integer;
begin
  Result := ExplicitLeft;
end;

function TXRCXPreviewFrom.Get_ExplicitTop: Integer;
begin
  Result := ExplicitTop;
end;

function TXRCXPreviewFrom.Get_ExplicitWidth: Integer;
begin
  Result := ExplicitWidth;
end;

function TXRCXPreviewFrom.Get_Font: IFontDisp;
begin
  GetOleFont(Font, Result);
end;

function TXRCXPreviewFrom.Get_HelpFile: WideString;
begin
  Result := WideString(HelpFile);
end;

function TXRCXPreviewFrom.Get_IsDrawingLocked: WordBool;
begin
  Result := IsDrawingLocked;
end;

function TXRCXPreviewFrom.Get_KeyPreview: WordBool;
begin
  Result := KeyPreview;
end;

function TXRCXPreviewFrom.Get_MouseInClient: WordBool;
begin
  Result := MouseInClient;
end;

function TXRCXPreviewFrom.Get_ParentCustomHint: WordBool;
begin
  Result := ParentCustomHint;
end;

function TXRCXPreviewFrom.Get_ParentDoubleBuffered: WordBool;
begin
  Result := ParentDoubleBuffered;
end;

function TXRCXPreviewFrom.Get_PixelsPerInch: Integer;
begin
  Result := PixelsPerInch;
end;

function TXRCXPreviewFrom.Get_PopupMode: TxPopupMode;
begin
  Result := Ord(PopupMode);
end;

function TXRCXPreviewFrom.Get_PrintScale: TxPrintScale;
begin
  Result := Ord(PrintScale);
end;

function TXRCXPreviewFrom.Get_RaiseOnNonMainThreadUsage: WordBool;
begin
  Result := RaiseOnNonMainThreadUsage;
end;

function TXRCXPreviewFrom.Get_RedrawDisabled: WordBool;
begin
  Result := RedrawDisabled;
end;

function TXRCXPreviewFrom.Get_RoundedCorners: TxRoundedCornerType;
begin
  Result := Ord(RoundedCorners);
end;

function TXRCXPreviewFrom.Get_Scaled: WordBool;
begin
  Result := Scaled;
end;

function TXRCXPreviewFrom.Get_ScaleFactor: Single;
begin
  Result := ScaleFactor;
end;

function TXRCXPreviewFrom.Get_ScreenSnap: WordBool;
begin
  Result := ScreenSnap;
end;

function TXRCXPreviewFrom.Get_SnapBuffer: Integer;
begin
  Result := SnapBuffer;
end;

function TXRCXPreviewFrom.Get_StyleName: WideString;
begin
  Result := WideString(StyleName);
end;

function TXRCXPreviewFrom.Get_UseDockManager: WordBool;
begin
  Result := UseDockManager;
end;

function TXRCXPreviewFrom.Get_Visible: WordBool;
begin
  Result := Visible;
end;

function TXRCXPreviewFrom.Get_VisibleDockClientCount: Integer;
begin
  Result := VisibleDockClientCount;
end;

procedure TXRCXPreviewFrom._Set_Font(var Value: IFontDisp);
begin
  SetOleFont(Font, Value);
end;

procedure TXRCXPreviewFrom.ActivateEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnActivate;
end;

procedure TXRCXPreviewFrom.AfterMonitorDpiChangedEvent(Sender: TObject; OldDPI, NewDPI: Integer);

begin
  if FEvents <> nil then FEvents.OnAfterMonitorDpiChanged(OldDPI, NewDPI);
end;

procedure TXRCXPreviewFrom.BeforeMonitorDpiChangedEvent(Sender: TObject; OldDPI, NewDPI: Integer);

begin
  if FEvents <> nil then FEvents.OnBeforeMonitorDpiChanged(OldDPI, NewDPI);
end;

procedure TXRCXPreviewFrom.ClickEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnClick;
end;

procedure TXRCXPreviewFrom.CreateEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnCreate;
end;

procedure TXRCXPreviewFrom.DblClickEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnDblClick;
end;

procedure TXRCXPreviewFrom.DeactivateEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnDeactivate;
end;

procedure TXRCXPreviewFrom.DestroyEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnDestroy;
end;

procedure TXRCXPreviewFrom.KeyPressEvent(Sender: TObject; var Key: Char);
var
  TempKey: Smallint;
begin
  TempKey := Smallint(Key);
  if FEvents <> nil then FEvents.OnKeyPress(TempKey);
  Key := Char(TempKey);
end;

procedure TXRCXPreviewFrom.MouseEnterEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnMouseEnter;
end;

procedure TXRCXPreviewFrom.MouseLeaveEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnMouseLeave;
end;

procedure TXRCXPreviewFrom.PaintEvent(Sender: TObject);
begin
  if FEvents <> nil then FEvents.OnPaint;
end;

procedure TXRCXPreviewFrom.Set_AlignWithMargins(Value: WordBool);
begin
  AlignWithMargins := Value;
end;

procedure TXRCXPreviewFrom.Set_AutoScroll(Value: WordBool);
begin
  AutoScroll := Value;
end;

procedure TXRCXPreviewFrom.Set_AutoSize(Value: WordBool);
begin
  AutoSize := Value;
end;

procedure TXRCXPreviewFrom.Set_AxBorderStyle(Value: TxActiveFormBorderStyle);
begin
  AxBorderStyle := TActiveFormBorderStyle(Value);
end;

procedure TXRCXPreviewFrom.Set_BorderWidth(Value: Integer);
begin
  BorderWidth := TBorderWidth(Value);
end;

procedure TXRCXPreviewFrom.Set_Caption(const Value: WideString);
begin
  Caption := TCaption(Value);
end;

procedure TXRCXPreviewFrom.Set_Color(Value: OLE_COLOR);
begin
  Color := TColor(Value);
end;

procedure TXRCXPreviewFrom.Set_DockSite(Value: WordBool);
begin
  DockSite := Value;
end;

procedure TXRCXPreviewFrom.Set_DoubleBuffered(Value: WordBool);
begin
  DoubleBuffered := Value;
end;

procedure TXRCXPreviewFrom.Set_DoubleBufferedMode(Value: TxDoubleBufferedMode);
begin
  DoubleBufferedMode := TDoubleBufferedMode(Value);
end;

procedure TXRCXPreviewFrom.Set_DropTarget(Value: WordBool);
begin
  DropTarget := Value;
end;

procedure TXRCXPreviewFrom.Set_Enabled(Value: WordBool);
begin
  Enabled := Value;
end;

procedure TXRCXPreviewFrom.Set_Font(const Value: IFontDisp);
begin
  SetOleFont(Font, Value);
end;

procedure TXRCXPreviewFrom.Set_HelpFile(const Value: WideString);
begin
  HelpFile := string(Value);
end;

procedure TXRCXPreviewFrom.Set_KeyPreview(Value: WordBool);
begin
  KeyPreview := Value;
end;

procedure TXRCXPreviewFrom.Set_ParentCustomHint(Value: WordBool);
begin
  ParentCustomHint := Value;
end;

procedure TXRCXPreviewFrom.Set_ParentDoubleBuffered(Value: WordBool);
begin
  ParentDoubleBuffered := Value;
end;

procedure TXRCXPreviewFrom.Set_PixelsPerInch(Value: Integer);
begin
  PixelsPerInch := Value;
end;

procedure TXRCXPreviewFrom.Set_PopupMode(Value: TxPopupMode);
begin
  PopupMode := TPopupMode(Value);
end;

procedure TXRCXPreviewFrom.Set_PrintScale(Value: TxPrintScale);
begin
  PrintScale := TPrintScale(Value);
end;

procedure TXRCXPreviewFrom.Set_RaiseOnNonMainThreadUsage(Value: WordBool);
begin
  RaiseOnNonMainThreadUsage := Value;
end;

procedure TXRCXPreviewFrom.Set_RoundedCorners(Value: TxRoundedCornerType);
begin
  RoundedCorners := TRoundedCornerType(Value);
end;

procedure TXRCXPreviewFrom.Set_Scaled(Value: WordBool);
begin
  Scaled := Value;
end;

procedure TXRCXPreviewFrom.Set_ScreenSnap(Value: WordBool);
begin
  ScreenSnap := Value;
end;

procedure TXRCXPreviewFrom.Set_SnapBuffer(Value: Integer);
begin
  SnapBuffer := Value;
end;

procedure TXRCXPreviewFrom.Set_StyleName(const Value: WideString);
begin
  StyleName := string(Value);
end;

procedure TXRCXPreviewFrom.Set_UseDockManager(Value: WordBool);
begin
  UseDockManager := Value;
end;

procedure TXRCXPreviewFrom.Set_Visible(Value: WordBool);
begin
  Visible := Value;
end;

initialization
  TActiveFormFactory.Create(
    ComServer,
    TActiveFormControl,
    TXRCXPreviewFrom,
    Class_XRCXPreviewFrom,
    0,
    '',
    OLEMISC_SIMPLEFRAME or OLEMISC_ACTSLIKELABEL,
    tmApartment);
end.
