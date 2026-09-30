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
     freed. A thread started and ended 1800 times grew the process by 1.6 GB. *)

interface

/// <summary>Handles every message waiting in this thread's queue. Call it
/// after each Parallel.For / ForEach on a thread that does not pump.</summary>
procedure DrainThreadMessages;

/// <summary>Call last in the Execute of a thread that ran Parallel loops:
/// drains until OTL's pool has no task queued or running (so every task has
/// posted its "terminated" message), then once more. Returns at once on a
/// thread that never called DrainThreadMessages.</summary>
procedure DrainParallelTasksBeforeExit;

implementation

uses
  Winapi.Windows, OtlParallel;

const
  { ponytail: GlobalParallelPool.IsIdle counts every thread's tasks, so a pool
    kept busy by another thread (or a worker that died and never reported
    back) holds this thread's exit for up to this long. A per-thread count of
    outstanding tasks would need OTL to expose one. }
  EXIT_DRAIN_CEILING_MS = 10000;

threadvar
  RanParallel: Boolean;   // this thread drained after a loop at least once

procedure PumpThreadMessages;
var
  M: TMsg;
begin
  while PeekMessage(M, 0, 0, 0, PM_REMOVE) do
  begin
    TranslateMessage(M);
    DispatchMessage(M);
  end;
end;

procedure DrainThreadMessages;
begin
  RanParallel := True;
  PumpThreadMessages;
end;

procedure DrainParallelTasksBeforeExit;
var
  Deadline: UInt64;
begin
  { Without a loop on this thread there is nothing to wait for, and
    GlobalParallelPool would create the pool just to ask. }
  if not RanParallel then
    Exit;
  Deadline := GetTickCount64 + EXIT_DRAIN_CEILING_MS;
  { IsIdle turns true only after the pool's manager has seen each work item
    complete, and a task posts "terminated" before its work item completes. }
  while not GlobalParallelPool.IsIdle and (GetTickCount64 < Deadline) do
  begin
    PumpThreadMessages;
    Sleep(1);
  end;
  PumpThreadMessages;
end;

end.
