unit unit_SMessages;

interface

uses
  WinApi.Windows,
  Winapi.Messages,
  System.AnsiStrings;

const
  WM_STR_BASE = WM_APP + $0500;

  WM_STR_STACK_CLICK = WM_STR_BASE + 0;
  WM_STR_STACKDBLCLICK = WM_STR_BASE + 1;

  procedure StackClick(ID: integer);
  procedure StackDoubleClick(ID: integer);

implementation

uses
  Forms, SysUtils;

procedure StackClick;
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_STACK_CLICK,
    ID,
    0
  );
end;

procedure StackDoubleClick;
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_STACKDBLCLICK,
    ID,
    0
  );
end;

end.
