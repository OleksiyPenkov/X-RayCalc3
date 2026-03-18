unit unit_RecentProjects;

interface

uses
  System.SysUtils, System.Classes, System.Generics.Collections,
  Vcl.Menus;

type
  TRecentProjectClickEvent = procedure(Sender: TObject; const FileName: string) of object;

  TRecentProjectsManager = class
  private
    FItems: TList<string>;
    FMaxCapacity: Integer;
    FMenuParent: TMenuItem;
    FPopupParent: TPopupMenu;
    FOnClick: TRecentProjectClickEvent;

    function IndexOfFile(const FileName: string): Integer;
    procedure MenuItemClick(Sender: TObject);
    procedure ClearMenuClick(Sender: TObject);
    procedure FillMenus;
  public
    constructor Create(AMaxCapacity: Integer; AMenuParent: TMenuItem;
      APopupParent: TPopupMenu);
    destructor Destroy; override;

    procedure Load;
    procedure Save;
    procedure Add(const FileName: string);
    procedure Remove(const FileName: string);
    procedure Clear;

    property OnClick: TRecentProjectClickEvent read FOnClick write FOnClick;
  end;

implementation

uses
  unit_Config, unit_consts;

{ TRecentProjectsManager }

constructor TRecentProjectsManager.Create(AMaxCapacity: Integer;
  AMenuParent: TMenuItem; APopupParent: TPopupMenu);
begin
  inherited Create;
  FMaxCapacity := AMaxCapacity;
  FMenuParent := AMenuParent;
  FPopupParent := APopupParent;
  FItems := TList<string>.Create;
end;

destructor TRecentProjectsManager.Destroy;
begin
  FreeAndNil(FItems);
  inherited;
end;

function TRecentProjectsManager.IndexOfFile(const FileName: string): Integer;
var
  i: Integer;
begin
  for i := 0 to FItems.Count - 1 do
    if SameText(FItems[i], FileName) then
      Exit(i);
  Result := -1;
end;

procedure TRecentProjectsManager.Load;
var
  RecentList: array of string;
  i: Integer;
begin
  FItems.Clear;
  SetLength(RecentList, FMaxCapacity);
  TConfig.ReadStringList('Recent', RecentList);

  for i := 0 to High(RecentList) do
    if RecentList[i] <> '' then
      FItems.Add(RecentList[i]);

  FillMenus;
end;

procedure TRecentProjectsManager.Save;
var
  RecentList: array of string;
  i: Integer;
begin
  SetLength(RecentList, FItems.Count);
  for i := 0 to FItems.Count - 1 do
    RecentList[i] := FItems[i];
  TConfig.WriteStringList('Recent', RecentList);
end;

procedure TRecentProjectsManager.Add(const FileName: string);
var
  Idx: Integer;
begin
  Idx := IndexOfFile(FileName);
  if Idx >= 0 then
    FItems.Move(Idx, 0)
  else
  begin
    FItems.Insert(0, FileName);
    if FItems.Count > FMaxCapacity then
      FItems.Delete(FItems.Count - 1);
  end;
  Save;
  FillMenus;
end;

procedure TRecentProjectsManager.Remove(const FileName: string);
var
  Idx: Integer;
begin
  Idx := IndexOfFile(FileName);
  if Idx >= 0 then
  begin
    FItems.Delete(Idx);
    Save;
    FillMenus;
  end;
end;

procedure TRecentProjectsManager.Clear;
begin
  FItems.Clear;
  Save;
  FillMenus;
end;

procedure TRecentProjectsManager.FillMenus;

  procedure AddItems(Parent: TComponent; AddProc: TProc<TMenuItem>);
  var
    i: Integer;
    Item, Sep, ClearItem: TMenuItem;
  begin
    for i := 0 to FItems.Count - 1 do
    begin
      Item := TMenuItem.Create(Parent);
      Item.Caption := ExtractFileName(FItems[i]);
      Item.Hint := FItems[i];
      Item.Tag := i;
      Item.OnClick := MenuItemClick;
      AddProc(Item);
    end;

    if FItems.Count > 0 then
    begin
      Sep := TMenuItem.Create(Parent);
      Sep.Caption := '-';
      AddProc(Sep);

      ClearItem := TMenuItem.Create(Parent);
      ClearItem.Caption := 'Clear recent list';
      ClearItem.OnClick := ClearMenuClick;
      AddProc(ClearItem);
    end;
  end;

begin
  FMenuParent.Clear;
  FPopupParent.Items.Clear;

  AddItems(FMenuParent,
    procedure(Item: TMenuItem)
    begin
      FMenuParent.Add(Item);
    end);

  AddItems(FPopupParent,
    procedure(Item: TMenuItem)
    begin
      FPopupParent.Items.Add(Item);
    end);
end;

procedure TRecentProjectsManager.MenuItemClick(Sender: TObject);
var
  Index: Integer;
  FileName: string;
begin
  Index := (Sender as TMenuItem).Tag;
  FileName := FItems[Index];
  FItems.Move(Index, 0);
  Save;
  FillMenus;

  if Assigned(FOnClick) then
    FOnClick(Sender, FileName);
end;

procedure TRecentProjectsManager.ClearMenuClick(Sender: TObject);
begin
  Clear;
end;

end.
