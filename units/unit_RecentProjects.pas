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

    procedure MenuItemClick(Sender: TObject);
    procedure FillMenus;
  public
    constructor Create(AMaxCapacity: Integer; AMenuParent: TMenuItem;
      APopupParent: TPopupMenu);
    destructor Destroy; override;

    procedure Load;
    procedure Save;
    procedure Add(const FileName: string);

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
begin
  TConfig.WriteStringList('Recent', FItems.List);
end;

procedure TRecentProjectsManager.Add(const FileName: string);
var
  Idx: Integer;
begin
  Idx := FItems.IndexOf(FileName);
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

procedure TRecentProjectsManager.FillMenus;
var
  i: Integer;
  Item, PopupItem: TMenuItem;
begin
  FMenuParent.Clear;
  FPopupParent.Items.Clear;

  for i := 0 to FItems.Count - 1 do
  begin
    Item := TMenuItem.Create(FMenuParent);
    FMenuParent.Add(Item);
    Item.Caption := ExtractFileName(FItems.List[i]);
    Item.Tag := i;
    Item.OnClick := MenuItemClick;

    PopupItem := TMenuItem.Create(FPopupParent);
    FPopupParent.Items.Add(PopupItem);
    PopupItem.Caption := Item.Caption;
    PopupItem.Tag := i;
    PopupItem.OnClick := MenuItemClick;
  end;
end;

procedure TRecentProjectsManager.MenuItemClick(Sender: TObject);
var
  Index: Integer;
  FileName: string;
begin
  Index := (Sender as TMenuItem).Tag;
  FileName := FItems.List[Index];
  FItems.Move(Index, 0);
  FillMenus;

  if Assigned(FOnClick) then
    FOnClick(Sender, FileName);
end;

end.
