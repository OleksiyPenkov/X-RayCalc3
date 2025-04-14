(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

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
  WM_STR_LINKED_CLICK = WM_STR_BASE + 4;
  WM_STR_EDIT_NEXT    = WM_STR_BASE + 5;
  WM_STR_EDIT_PREV    = WM_STR_BASE + 6;
  WM_STR_LAYER_DOUBLECLICK = WM_STR_BASE + 7;

  WM_STR_LAYER_UP = WM_STR_BASE + 20;
  WM_STR_LAYER_DOWN = WM_STR_BASE + 21;
  WM_STR_LAYER_INSERT = WM_STR_BASE + 22;
  WM_STR_LAYER_DELETE = WM_STR_BASE + 23;


  procedure StackClick(const ID: integer);
  procedure StackDoubleClick(const ID: integer);
  procedure SendRecalcMessage;
  procedure LayerClick(const StackID, ID: integer);
  procedure LayerDoubleClick(const StackID, ID: integer);
  procedure LinkedClick(const StackID, ID: integer);
  procedure ArrangeLayer(const Msg: Cardinal; const StackID, ID: integer);
  procedure LayerEditNext(const StackID, ID: integer);
  procedure LayerEditPrev(const StackID, ID: integer);

implementation

uses
  Forms, SysUtils;

procedure ArrangeLayer(const Msg: Cardinal; const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    Msg,
    StackID,
    ID
  );
end;

procedure LinkedClick(const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_LINKED_CLICK ,
    StackID,
    ID
  );
end;

procedure LayerClick(const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_LAYER_CLICK,
    StackID,
    ID
  );
end;

procedure LayerDoubleClick(const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_LAYER_DOUBLECLICK,
    StackID,
    ID
  );
end;

procedure LayerEditNext(const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_EDIT_NEXT,
    StackID,
    ID
  );
end;



procedure LayerEditPrev(const StackID, ID: integer);
begin
  PostMessage(
    Application.MainFormHandle,
    WM_STR_EDIT_PREV,
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
