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

unit TestUncertThread;

(* The uncertainty tool's worker thread: it delivers a result, it stops when
   asked, and nothing that goes wrong inside it leaves it as an exception. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUncertThread = class
  public
    [Test] procedure Thread_RunsAndDeliversTheResult;
    [Test] procedure Thread_StopThenWait_EndsQuickly;
    [Test] procedure Thread_EngineError_IsAFailureNotACrash;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.SyncObjs, System.Diagnostics,
  unit_Types, unit_MCPProjectFile, unit_UncertRequest, unit_UncertRun, unit_UncertThread,
  TestLogPosterior, TestUncertRun;

function Short: TUncertRecipe;
begin
  Result := TUncertRecipe.Standard;
  Result.Settle := 100;
  Result.Steps := 300;
  Result.BurnIn := 100;
  Result.Thin := 2;
  Result.Predictive := 20;
  Result.AgreeBelow := 10;                // one attempt: this is about the thread, not the walkers
end;

procedure TTestUncertThread.Thread_RunsAndDeliversTheResult;
var
  Counts: TArray<Double>;
  Req: TUncertRequest;
  T: TUncertThread;
  Done, Reports: Integer;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Assert.AreEqual('', BuildRequest(WB4CProject(6, Counts), Req));
  Done := 0;
  Reports := 0;
  T := TUncertThread.Create(Req, nil, Counts, False, 7, Short,
    procedure(Step, Total: Integer; SecondsLeft: Double)
    begin
      TInterlocked.Increment(Reports);
    end,
    procedure
    begin
      TInterlocked.Increment(Done);
    end);
  try
    T.WaitFor;
    Assert.AreEqual('', T.Failure);
    Assert.IsTrue(T.Result.Settled, T.Result.Message);
    Assert.AreEqual(Length(Req.Names), Integer(Length(T.Result.Values)));
    Assert.AreEqual(1, Done, 'told once that it has ended');
    Assert.IsTrue(Reports >= 4, Format('%d progress reports', [Reports]));
  finally
    T.Free;
  end;
end;

procedure TTestUncertThread.Thread_StopThenWait_EndsQuickly;
var
  Counts: TArray<Double>;
  Req: TUncertRequest;
  T: TUncertThread;
  Recipe: TUncertRecipe;
  First: TEvent;
  Watch: TStopwatch;
  Done: Integer;
begin
  Done := 0;
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Assert.AreEqual('', BuildRequest(WB4CProject(6, Counts), Req));
  Recipe := Short;
  Recipe.Steps := 200000;                 // would take many minutes
  Recipe.BurnIn := 1000;
  First := TEvent.Create(nil, True, False, '');
  try
    T := TUncertThread.Create(Req, nil, Counts, False, 7, Recipe,
      procedure(Step, Total: Integer; SecondsLeft: Double)
      begin
        First.SetEvent;
      end,
      procedure
      begin
        TInterlocked.Increment(Done);
      end);
    try
      Assert.IsTrue(First.WaitFor(60000) = wrSignaled, 'the run started');
      Watch := TStopwatch.StartNew;
      T.Stop;
      T.WaitFor;
      Assert.IsTrue(Watch.ElapsedMilliseconds < 15000,
        Format('ended %d ms after it was asked', [Watch.ElapsedMilliseconds]));
      Assert.IsTrue(T.Result.Stopped);
      Assert.IsFalse(T.Result.Settled);
      Assert.AreEqual('', T.Failure);
      Assert.AreEqual(1, Done, 'a stopped run says that it has ended too: the window waits for it');
    finally
      T.Free;
    end;
  finally
    First.Free;
  end;
end;

procedure TTestUncertThread.Thread_EngineError_IsAFailureNotACrash;
var
  Counts: TArray<Double>;
  Req: TUncertRequest;
  T: TUncertThread;
begin
  if not TWB4CFixture.TablesPresent then
    Assert.Pass('Henke tables W, B4C, Si are not installed');
  Assert.AreEqual('', BuildRequest(WB4CProject(6, Counts), Req));
  SetLength(Counts, Length(Counts) - 5);  // counts of another curve
  T := TUncertThread.Create(Req, nil, Counts, False, 7, Short, nil, nil);
  try
    T.WaitFor;
    Assert.IsFalse(T.Result.Settled);
    Assert.AreNotEqual('', T.Result.Message + T.Failure, 'it says why in a sentence');
  finally
    T.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUncertThread);

end.
