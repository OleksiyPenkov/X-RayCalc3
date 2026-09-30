(* *****************************************************************************
  *
  *   X-Ray Calc 3 - OmniThreadLibrary task-completion messages
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_otl_drain;

(* OmniThreadLibrary frees a Parallel.For / Parallel.ForEach task's control
   (two 10 000-slot message queues, ~400 KB) only when the thread that ran the
   loop handles the task's "terminated" window message. So:

   - after every loop, a thread that pumps no messages of its own (a job, fit
     or sampling thread) calls DrainThreadMessages, or it keeps every task
     control it ever created;

   - before such a thread ends, it calls DrainParallelTasksBeforeExit. The
     tasks post "terminated" after the loop has returned, so the last loop's
     messages can arrive after the last drain. Once the thread is gone so is
     its window: the pool worker's PostMessage fails with EOSError (invalid
     window handle), which kills the worker, and the task control is never
     freed. A thread started and ended 1800 times grew the process by up to
     1.6 GB. *)

interface

/// <summary>Handles every message waiting in this thread's queue. Call it
/// after each Parallel.For / ForEach on a thread that does not pump.</summary>
procedure DrainThreadMessages;

/// <summary>Call last in the Execute of a thread that ran Parallel loops:
/// pumps until OTL has freed every task control this thread created (the
/// thread's task monitor window is gone), for at most 10 s.</summary>
procedure DrainParallelTasksBeforeExit;

implementation

uses
  Winapi.Windows;

const
  { ponytail: relies on OTL 3.08 internals. Unobserved (OtlTaskControl,
    CreateInternalMonitor) attaches each task control to this thread's
    TOmniEventMonitor from GTaskControlEventMonitorPool, which ref-counts it
    per thread (OtlEventMonitor, TOmniCountedEventMonitor) and frees it - and
    with it its message-only 'DSiUtilWindow' (DSiWin32 DSiAllocateHWnd,
    CDSiHiddenWindowName) - when the last control is destroyed after its
    "terminated" message. On an OTL upgrade re-check those three, or this
    waits the full ceiling at every exit: a backstop, not the mechanism. }
  EXIT_DRAIN_CEILING_MS = 10000;
  OTL_WINDOW_CLASS = 'DSiUtilWindow';

procedure DrainThreadMessages;
var
  M: TMsg;
begin
  while PeekMessage(M, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(M);
    DispatchMessage(M);
  end;
end;

/// True while this thread still owns an OTL/DSi message-only window, i.e.
/// some task it created has not had its "terminated" message handled.
function ThreadHasOtlMonitor: Boolean;
var
  W: HWND;
  Me: DWORD;
begin
  Me := GetCurrentThreadId;
  W := FindWindowEx(HWND_MESSAGE, 0, OTL_WINDOW_CLASS, nil);
  while W <> 0 do
  begin
    if GetWindowThreadProcessId(W, nil) = Me then
      Exit(True);
    W := FindWindowEx(HWND_MESSAGE, W, OTL_WINDOW_CLASS, nil);
  end;
  Result := False;
end;

procedure DrainParallelTasksBeforeExit;
var
  Deadline: UInt64;
begin
  Deadline := GetTickCount64 + EXIT_DRAIN_CEILING_MS;
  DrainThreadMessages;
  while ThreadHasOtlMonitor and (GetTickCount64 < Deadline) do
  begin
    Sleep(1);
    DrainThreadMessages;
  end;
end;

end.
