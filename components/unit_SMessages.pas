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
  WM_RECALC = WM_STR_BASE + 2;
  WM_STR_LAYER_CLICK = WM_STR_BASE + 3;

  procedure StackClick(const ID: integer);
  procedure StackDoubleClick(const ID: integer);
  procedure SendRecalcMessage;
  procedure LayerClick(const StackID, ID: integer);

implementation

uses
  Forms, SysUtils;

procedure LayerClick(const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_LAYER_CLICK ,
    StackID,
    ID
  );
end;


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

procedure SendRecalcMessage;
begin
  PostMessage(
    Application.MainFormHandle,
    WM_RECALC,
    0,
    0
  );
end;

end.
