unit PreviewHandler;

{$WARN SYMBOL_PLATFORM OFF}
{.$DEFINE USE_CODESITE}

interface

uses
  Classes, VCL.Controls, ComObj;

type
  TPreviewHandler = class abstract
  public
    { Create all controls needed for the preview and connect them to the
      parent given. The parent follows the size, color and font of the preview
      pane. The parent will stay valid until this instance is destroyed, so if
      you make the parent also the owner of the controls you don't need to free
      them in Destroy. }
    constructor Create(AParent: TWinControl); virtual;
    class function GetComClass: TComClass; virtual; abstract;
    class procedure Register(const AClassID: TGUID; const AName, ADescription, AFileExtension: string);
    {$REGION 'Clear Content'}
    ///	<summary>Clear Content</summary>
    ///	<remarks>This method is called when the preview should be cleared because
    ///	either another item was selected or the PreviewHandler will be
    ///	closed.</remarks>
    {$ENDREGION}
    procedure Unload; virtual;
  end;

  TStreamPreviewHandler = class abstract(TPreviewHandler)
  public
    {$REGION 'Render the preview from the stream data'}
    ///	<summary>Render the preview from the stream data</summary>
    ///	<remarks>Here you should render the data from the stream in whatever
    ///	fashion you want.</remarks>
    {$ENDREGION}
    procedure DoPreview(Stream: TStream); virtual; abstract;
    class function GetComClass: TComClass; override; final;
  end;

  TFilePreviewHandler = class abstract(TPreviewHandler)
  public
    {$REGION 'Render the preview from the file path'}
    ///	<summary>Render the preview from the file path</summary>
    ///	<remarks>Here you should render the data from the file path in whatever
    ///	fashion you want.</remarks>
    {$ENDREGION}
    procedure DoPreview(const FilePath: String); virtual; abstract;
    class function GetComClass: TComClass; override; final;
  end;

implementation

uses
{$IFDEF USE_CODESITE}
  CodeSiteLogging,
{$ENDIF}
  Windows, ActiveX, ComServ, ShlObj, PropSys, Types, SysUtils, VCL.Graphics, VCL.ExtCtrls;

type
  TPreviewHandlerClass = class of TPreviewHandler;
  TComPreviewHandler = class(TComObject, IPreviewHandler, IPreviewHandlerVisuals, IObjectWithSite, IOleWindow)
  strict private
    function IPreviewHandler.DoPreview = IPreviewHandler_DoPreview;
    function ContextSensitiveHelp(fEnterMode: LongBool): HRESULT; stdcall;
    function GetSite(const riid: TGUID; out site: IInterface): HRESULT; stdcall;
    function GetWindow(out wnd: HWND): HRESULT; stdcall;
    function IPreviewHandler_DoPreview: HRESULT; stdcall;
    function QueryFocus(var phwnd: HWND): HRESULT; stdcall;
    function SetBackgroundColor(color: Cardinal): HRESULT; stdcall;
    function SetFocus: HRESULT; stdcall;
    function SetFont(const plf: tagLOGFONTW): HRESULT; stdcall;
    function SetRect(var prc: TRect): HRESULT; stdcall;
    function SetSite(const pUnkSite: IInterface): HRESULT; stdcall;
    function SetTextColor(color: Cardinal): HRESULT; stdcall;
    function SetWindow(hwnd: HWND; var prc: TRect): HRESULT; stdcall;
    function TranslateAccelerator(var pmsg: tagMSG): HRESULT; stdcall;
    function Unload: HRESULT; stdcall;
  private
    FBackgroundColor: Cardinal;
    FBounds: TRect;
    FContainer: TWinControl;
    FLogFont: tagLOGFONTW;
    FParentWindow: HWND;
    FPreviewHandler: TPreviewHandler;
    FPreviewHandlerClass: TPreviewHandlerClass;
    FPreviewHandlerFrame: IPreviewHandlerFrame;
    FSite: IInterface;
    FTextColor: Cardinal;
  protected
    procedure CheckContainer;
    procedure CheckPreviewHandler;
    procedure InternalUnload; virtual; abstract;
    procedure InternalDoPreview; virtual; abstract;
    property Container: TWinControl read FContainer;
    property PreviewHandler: TPreviewHandler read FPreviewHandler;
  public
    destructor Destroy; override;
    property PreviewHandlerClass: TPreviewHandlerClass read FPreviewHandlerClass write FPreviewHandlerClass;
  end;

  TComStreamPreviewHandler = class(TComPreviewHandler, IInitializeWithStream)
  strict private
    function IInitializeWithStream.Initialize = IInitializeWithStream_Initialize;
    function IInitializeWithStream_Initialize(const pstream: IStream; grfMode: Cardinal): HRESULT; stdcall;
  private
    FIStream: IStream;
    FMode: Cardinal;
    function GetPreviewHandler: TStreamPreviewHandler;
  protected
    procedure InternalUnload; override;
    procedure InternalDoPreview; override;
    property PreviewHandler: TStreamPreviewHandler read GetPreviewHandler;
  end;

  TComFilePreviewHandler = class(TComPreviewHandler, IInitializeWithFile)
  strict private
    function IInitializeWithFile.Initialize = IInitializeWithFile_Initialize;
    function IInitializeWithFile_Initialize(pszFilePath: LPCWSTR; grfMode: DWORD): HRESULT; stdcall;
  private
    FFilePath: string;
    FMode: DWORD;
    function GetPreviewHandler: TFilePreviewHandler;
  protected
    procedure InternalDoPreview; override;
    procedure InternalUnload; override;
    property PreviewHandler: TFilePreviewHandler read GetPreviewHandler;
  end;

  TComPreviewHandlerFactory = class(TComObjectFactory)
  private
    FFileExtension: string;
    FPreviewHandlerClass: TPreviewHandlerClass;
    class procedure DeleteRegValue(const Key, ValueName: string; RootKey: DWord);
    class function IsRunningOnWOW64: Boolean;
  protected
    property FileExtension: string read FFileExtension;
  public
    constructor Create(APreviewHandlerClass: TPreviewHandlerClass; const AClassID: TGUID; const AName, ADescription, AFileExtension: string);
    function CreateComObject(const Controller: IUnknown): TComObject; override;
    procedure UpdateRegistry(Register: Boolean); override;
    property PreviewHandlerClass: TPreviewHandlerClass read FPreviewHandlerClass;
  end;

  TWinControlHelper = class helper for TWinControl
  public
    procedure SetFocusTabFirst;
    procedure SetFocusTabLast;
    procedure SetBackgroundColor(AColor: Cardinal);
    procedure SetBoundsRect(const ARect: TRect);
    procedure SetTextColor(AColor: Cardinal);
    procedure SetTextFont(const Source: tagLOGFONTW);
  end;

  TIStreamAdapter = class(TStream)
  private
    FTarget: IStream;
  protected
    function GetSize: Int64; override;
    procedure SetSize(NewSize: Longint); override;
    procedure SetSize(const NewSize: Int64); override;
  public
    constructor Create(ATarget: IStream);
    function Read(var Buffer; Count: Longint): Longint; override;
    function Seek(const Offset: Int64; Origin: TSeekOrigin): Int64; overload; override;
    function Write(const Buffer; Count: Longint): Longint; override;
    property Target: IStream read FTarget;
  end;

procedure TWinControlHelper.SetFocusTabFirst;
begin
  SelectNext(nil, true, true);
end;

procedure TWinControlHelper.SetFocusTabLast;
begin
  SelectNext(nil, false, true);
end;

procedure TWinControlHelper.SetBackgroundColor(AColor: Cardinal);
begin
  Color := AColor;
end;

procedure TWinControlHelper.SetBoundsRect(const ARect: TRect);
begin
  SetBounds(ARect.Left, ARect.Top, ARect.Right - ARect.Left, ARect.Bottom - ARect.Top);
end;

procedure TWinControlHelper.SetTextColor(AColor: Cardinal);
begin
  Font.Color := AColor;
end;

procedure TWinControlHelper.SetTextFont(const Source: tagLOGFONTW);
var
  fontStyle: TFontStyles;
begin
  Font.Height := Source.lfHeight;
  fontStyle := Font.Style;
  if Source.lfWeight >= FW_BOLD then
    Include(fontStyle, fsBold);
  if Source.lfItalic = 1 then
    Include(fontStyle, fsItalic);
  if Source.lfUnderline = 1 then
    Include(fontStyle, fsUnderline);
  if Source.lfStrikeOut = 1 then
    Include(fontStyle, fsStrikeOut);
  Font.Style := fontStyle;
  Font.Charset := TFontCharset(Source.lfCharSet);
  Font.Name := Source.lfFaceName;
  case Source.lfPitchAndFamily and $F of
    VARIABLE_PITCH: Font.Pitch := fpVariable;
    FIXED_PITCH: Font.Pitch := fpFixed;
  else
    Font.Pitch := fpDefault;
  end;
  Font.Orientation := Source.lfOrientation;
end;

constructor TComPreviewHandlerFactory.Create(APreviewHandlerClass: TPreviewHandlerClass; const AClassID: TGUID; const
    AName, ADescription, AFileExtension: string);
begin
  inherited Create(ComServ.ComServer, APreviewHandlerClass.GetComClass, AClassID, AName, ADescription, ciMultiInstance, tmApartment);
  FPreviewHandlerClass := APreviewHandlerClass;
  FFileExtension := AFileExtension;
end;

function TComPreviewHandlerFactory.CreateComObject(const Controller: IUnknown): TComObject;
begin
  result := inherited CreateComObject(Controller);
  TComPreviewHandler(result).PreviewHandlerClass := PreviewHandlerClass;
end;

class procedure TComPreviewHandlerFactory.DeleteRegValue(const Key, ValueName: string; RootKey: DWord);
var
  RegKey: HKEY;
begin
  if RegOpenKeyEx(RootKey, PChar(Key), 0, KEY_ALL_ACCESS, regKey) = ERROR_SUCCESS then begin
    try
      RegDeleteValue(regKey, PChar(ValueName));
    finally
      RegCloseKey(regKey)
    end;
  end;
end;

class function TComPreviewHandlerFactory.IsRunningOnWOW64: Boolean;
{ code taken from www.delphidabbler.com "IsWow64" }
type
  // Type of IsWow64Process API fn
  TIsWow64Process = function(Handle: Windows.THandle; var Res: Windows.BOOL): Windows.BOOL; stdcall;
var
  IsWow64Result: Windows.BOOL; // Result from IsWow64Process
  IsWow64Process: TIsWow64Process; // IsWow64Process fn reference
begin
{$IF defined(CPUX64)}
  // compiled for 64-bit: can't be running on Wow64
  result := false;
{$ELSE}
  // Try to load required function from kernel32
  IsWow64Process := Windows.GetProcAddress(Windows.GetModuleHandle('kernel32'), 'IsWow64Process');
  if Assigned(IsWow64Process) then begin
    // Function is implemented: call it
    if not IsWow64Process(Windows.GetCurrentProcess, IsWow64Result) then
      raise SysUtils.Exception.Create('IsWindows64: bad process handle');
    // Return result of function
    Result := IsWow64Result;
  end
  else
    // Function not implemented: can't be running on Wow64
    Result := False;
{$IFEND}
end;

procedure TComPreviewHandlerFactory.UpdateRegistry(Register: Boolean);
var
  plainFileName: string;
  sAppID, sClassID, ProgID, ServerKeyName, RegPrefix: string;
  RootKey: HKEY;
  RootKey2: HKEY;
begin
  if Instancing = ciInternal then
    Exit;

  ComServer.GetRegRootAndPrefix(RootKey, RegPrefix);
  if ComServer.PerUserRegistration then
    RootKey2 := HKEY_CURRENT_USER
  else
    RootKey2 := HKEY_LOCAL_MACHINE;
  sClassID := GUIDToString(ClassID);
  ProgID := GetProgID;
  ServerKeyName := RegPrefix + 'CLSID\' + sClassID + '\' + ComServer.ServerKey;
  if IsRunningOnWOW64 then
    sAppID := '{534A1E02-D58F-44f0-B58B-36CBED287C7C}' // for Win32 shell extension running on Win64
  else
    sAppID := '{6d2b5079-2f0b-48dd-ab7f-97cec514d30b}';

  if Register then begin
    inherited;
    plainFileName := ExtractFileName(ComServer.ServerFileName);
    CreateRegKey(RegPrefix + 'CLSID\' + sClassID, 'AppID', sAppID, RootKey);
    if ProgID <> '' then begin
      CreateRegKey(ServerKeyName, 'ProgID', ProgID, RootKey);
      CreateRegKey(ServerKeyName, 'VersionIndependentProgID', ProgID, RootKey);
      CreateRegKey(RegPrefix + ProgID + '\shellex\' + SID_IPreviewHandler, '', sClassID, RootKey);
      CreateRegKey(RegPrefix + FileExtension, '', ProgID, RootKey);
      CreateRegKey('SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers', sClassID, Description, RootKey2);
    end;
  end
  else begin
    if ProgID <> '' then begin
      DeleteRegValue('SOFTWARE\Microsoft\Windows\CurrentVersion\PreviewHandlers', sClassID, RootKey2);
      DeleteRegKey(RegPrefix + FileExtension, RootKey);
      DeleteRegKey(RegPrefix + ProgID + '\shellex', RootKey);
    end;
    inherited;
  end;
end;

destructor TComPreviewHandler.Destroy;
begin
  FPreviewHandler.Free;
  FContainer.Free;
  inherited Destroy;
end;

procedure TComPreviewHandler.CheckContainer;
begin
  if FContainer = nil then begin
    { I sprang for a TPanel here, because it makes things so much simpler. }
    FContainer := TPanel.Create(nil);
    TPanel(FContainer).BevelOuter := bvNone;
    FContainer.SetBackgroundColor(FBackgroundColor);
    FContainer.SetTextFont(FLogFont);
    FContainer.SetTextColor(FTextColor);
    FContainer.SetBoundsRect(FBounds);
    FContainer.ParentWindow := FParentWindow;
  end;
end;

procedure TComPreviewHandler.CheckPreviewHandler;
begin
  if FPreviewHandler = nil then begin
    CheckContainer;
    FPreviewHandler := PreviewHandlerClass.Create(Container);
  end;
end;

function TComPreviewHandler.ContextSensitiveHelp(fEnterMode: LongBool): HRESULT;
begin
  result := E_NOTIMPL;
end;

function TComPreviewHandler.GetSite(const riid: TGUID; out site: IInterface): HRESULT;
begin
  site := nil;
  if FSite = nil then
    result := E_FAIL
  else if Supports(FSite, riid, site) then
    result := S_OK
  else
    result := E_NOINTERFACE;
end;

function TComPreviewHandler.GetWindow(out wnd: HWND): HRESULT;
begin
  if Container = nil then begin
    result := E_FAIL;
  end
  else begin
    wnd := Container.Handle;
    result := S_OK;
  end;
end;

function TComPreviewHandler.IPreviewHandler_DoPreview: HRESULT;
begin
  try
    CheckPreviewHandler;
    InternalDoPreview;
  except
    on E: Exception do begin
    {$IFDEF USE_CODESITE}
      CodeSite.SendException(E);
    {$ENDIF}
    end;
  end;
  result := S_OK;
end;

function TComPreviewHandler.QueryFocus(var phwnd: HWND): HRESULT;
begin
  phwnd := GetFocus;
  result := S_OK;
end;

function TComPreviewHandler.SetBackgroundColor(color: Cardinal): HRESULT;
begin
  FBackgroundColor := color;
  if Container <> nil then
    Container.SetBackgroundColor(FBackgroundColor);
  result := S_OK;
end;

function TComPreviewHandler.SetFocus: HRESULT;
begin
  if Container <> nil then begin
    if GetKeyState(VK_SHIFT) < 0 then
      Container.SetFocusTabLast
    else
      Container.SetFocusTabFirst;
  end;
  result := S_OK;
end;

function TComPreviewHandler.SetFont(const plf: tagLOGFONTW): HRESULT;
begin
  FLogFont := plf;
  if Container <> nil then
    Container.SetTextFont(FLogFont);
  result := S_OK;
end;

function TComPreviewHandler.SetRect(var prc: TRect): HRESULT;
begin
  FBounds := prc;
  if Container <> nil then
    Container.SetBoundsRect(FBounds);
  result := S_OK;
end;

function TComPreviewHandler.SetSite(const pUnkSite: IInterface): HRESULT;
begin
  FSite := PUnkSite;
  FPreviewHandlerFrame := FSite as IPreviewHandlerFrame;
  result := S_OK;
end;

function TComPreviewHandler.SetTextColor(color: Cardinal): HRESULT;
begin
  FTextColor := color;
  if Container <> nil then
    Container.SetTextColor(FTextColor);
  result := S_OK;
end;

function TComPreviewHandler.SetWindow(hwnd: HWND; var prc: TRect): HRESULT;
begin
  FParentWindow := hwnd;
  FBounds := prc;
  if Container <> nil then begin
    Container.ParentWindow := FParentWindow;
    Container.SetBoundsRect(FBounds);
  end;
  result := S_OK;
end;

function TComPreviewHandler.TranslateAccelerator(var pmsg: tagMSG): HRESULT;
begin
  if FPreviewHandlerFrame = nil then
    result := S_FALSE
  else
    result := FPreviewHandlerFrame.TranslateAccelerator(pmsg);
end;

function TComPreviewHandler.Unload: HRESULT;
begin
  if PreviewHandler <> nil then
    PreviewHandler.Unload;
  InternalUnload;
  result := S_OK;
end;

constructor TPreviewHandler.Create(AParent: TWinControl);
begin
  inherited Create;
end;

class procedure TPreviewHandler.Register(const AClassID: TGUID; const AName, ADescription, AFileExtension: string);
begin
  TComPreviewHandlerFactory.Create(Self, AClassID, AName, ADescription, AFileExtension);
end;

procedure TPreviewHandler.Unload;
begin
end;

constructor TIStreamAdapter.Create(ATarget: IStream);
begin
  inherited Create;
  FTarget := ATarget;
end;

function TIStreamAdapter.GetSize: Int64;
var
  statStg: TStatStg;
begin
  if Target.Stat(statStg, STATFLAG_NONAME) = S_OK then
    result := statStg.cbSize
  else
    result := -1;
end;

function TIStreamAdapter.Read(var Buffer; Count: Longint): Longint;
begin
  Target.Read(@Buffer, Count, @result);
end;

function TIStreamAdapter.Seek(const Offset: Int64; Origin: TSeekOrigin): Int64;
begin
  Target.Seek(Offset, Ord(Origin), Uint64(result));
end;

procedure TIStreamAdapter.SetSize(const NewSize: Int64);
begin
  raise ENotImplemented.Create('SetSize not implemented');
//  Target.SetSize(NewSize);
end;

procedure TIStreamAdapter.SetSize(NewSize: Longint);
begin
  SetSize(Int64(NewSize));
end;

function TIStreamAdapter.Write(const Buffer; Count: Longint): Longint;
begin
  raise ENotImplemented.Create('Write not implemented');
//  Target.Write(@Buffer, Count, @result);
end;

function TComStreamPreviewHandler.GetPreviewHandler: TStreamPreviewHandler;
begin
  Result := inherited PreviewHandler as TStreamPreviewHandler;
end;

function TComStreamPreviewHandler.IInitializeWithStream_Initialize(const pstream: IStream; grfMode: Cardinal): HRESULT;
begin
  FIStream := pStream;
  FMode := grfMode;
  result := S_OK;
end;

procedure TComStreamPreviewHandler.InternalUnload;
begin
  FIStream := nil;
end;

procedure TComStreamPreviewHandler.InternalDoPreview;
var
  stream: TIStreamAdapter;
begin
  stream := TIStreamAdapter.Create(FIStream);
  try
    PreviewHandler.DoPreview(stream);
  finally
    stream.Free;
  end;
end;

function TComFilePreviewHandler.GetPreviewHandler: TFilePreviewHandler;
begin
  Result := inherited PreviewHandler as TFilePreviewHandler;
end;

function TComFilePreviewHandler.IInitializeWithFile_Initialize(pszFilePath: LPCWSTR; grfMode: DWORD): HRESULT;
begin
  FFilePath := pszFilePath;
  FMode := grfMode;
  result := S_OK;
end;

procedure TComFilePreviewHandler.InternalDoPreview;
begin
  PreviewHandler.DoPreview(FFilePath);
end;

procedure TComFilePreviewHandler.InternalUnload;
begin
  FFilePath := '';
end;

class function TFilePreviewHandler.GetComClass: TComClass;
begin
  result := TComFilePreviewHandler;
end;

class function TStreamPreviewHandler.GetComClass: TComClass;
begin
  result := TComStreamPreviewHandler;
end;

initialization
{$IFDEF USE_CODESITE}
  CodeSiteManager.ConnectUsingTcp;
{$ENDIF}
end.


