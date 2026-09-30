(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit TestOtlDrain;

(* A thread that runs Parallel.For and then ends, as every fit, sampling and
   job thread does. OTL's tasks post their "terminated" message after the loop
   has returned; one that lands after the thread's window is gone raises
   EOSError in the pool worker (killing it) and the task's control is never
   freed. unit_otl_drain.DrainParallelTasksBeforeExit must hold the thread
   until every such message has been handled. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestOtlDrain = class
  public
    { 200 threads x three 32-task loops. Before the exit drain ~5-10 % of them
      ended with messages still in flight (7-19 pool-worker EOSErrors per run
      on the 32-core reference machine); after it, none. }
    [Test] procedure ThreadsThatRunParallelFor_EndWithoutLosingATask;
  end;

implementation

uses
  Winapi.Windows, Winapi.PsAPI, System.SysUtils, System.Classes, OtlParallel,
  unit_otl_drain;

function AddVectoredExceptionHandler(First: ULONG; Handler: Pointer): Pointer; stdcall;
  external kernel32 name 'AddVectoredExceptionHandler';
function RemoveVectoredExceptionHandler(Handle: Pointer): ULONG; stdcall;
  external kernel32 name 'RemoveVectoredExceptionHandler';

const
  DELPHI_EXCEPTION = $0EEDFADE;

var
  OSErrors: Integer;
  FirstOSError: string;   // written by the thread that raised the first one only

{ Sees every first-chance exception in the process. A Delphi raise carries the
  exception object as its second parameter; the pool worker's failed post is
  an EOSError. Only counts (and keeps the first message), never handles. }
function CountOSErrors(P: PExceptionPointers): Integer; stdcall;
var
  R: PExceptionRecord;
begin
  R := P^.ExceptionRecord;
  if (R^.ExceptionCode = DELPHI_EXCEPTION) and (R^.NumberParameters >= 2) and
     (TObject(R^.ExceptionInformation[1]) is EOSError) and
     (InterlockedIncrement(OSErrors) = 1) then
    FirstOSError := EOSError(R^.ExceptionInformation[1]).Message;
  Result := 0;   // EXCEPTION_CONTINUE_SEARCH
end;

function PrivateBytes: Int64;
var
  C: TProcessMemoryCountersEx;
begin
  C.cb := SizeOf(C);
  Win32Check(GetProcessMemoryInfo(GetCurrentProcess, PPROCESS_MEMORY_COUNTERS(@C), SizeOf(C)));
  Result := C.PrivateUsage;
end;

type
  TLoopThread = class(TThread)
  protected
    procedure Execute; override;
  end;

procedure TLoopThread.Execute;
var
  k: Integer;
begin
  try
    for k := 1 to 3 do
    begin
      Parallel.&For(0, 63).NumTasks(32).Execute(
        procedure(i: Integer)
        var
          j: Integer;
          x: Double;
        begin
          x := 0;
          for j := 1 to 2000 do
            x := x + Sqrt(j);
          if x < 0 then
            raise EInvalidOp.Create('unreachable');
        end);
      DrainThreadMessages;
    end;
  finally
    DrainParallelTasksBeforeExit;
  end;
end;

procedure RunThreads(Count: Integer);
var
  i: Integer;
  T: TLoopThread;
begin
  for i := 1 to Count do
  begin
    T := TLoopThread.Create(False);
    try
      T.WaitFor;
      if T.FatalException <> nil then
        Assert.Fail('thread ' + IntToStr(i) + ': ' + Exception(T.FatalException).Message);
    finally
      T.Free;
    end;
  end;
end;

procedure TTestOtlDrain.ThreadsThatRunParallelFor_EndWithoutLosingATask;
const
  THREADS = 200;
  ALLOWED = 64 * 1024 * 1024;   // pool growth only; ~10-20 MB lost before, 0-10 MB after
var
  Handler: Pointer;
  Before, Grown: Int64;
begin
  RunThreads(10);   // the pool at its working size before the baseline
  Before := PrivateBytes;
  OSErrors := 0;
  FirstOSError := '';
  Handler := AddVectoredExceptionHandler(1, @CountOSErrors);
  try
    RunThreads(THREADS);
  finally
    RemoveVectoredExceptionHandler(Handler);
  end;
  Grown := PrivateBytes - Before;
  Assert.AreEqual(0, OSErrors, Format(
    '%d task "terminated" messages reached a thread that had already ended (first: %s)',
    [OSErrors, FirstOSError]));
  Assert.IsTrue(Grown < ALLOWED, Format('%d threads kept %d MB',
    [THREADS, Grown div (1024 * 1024)]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestOtlDrain);

end.
