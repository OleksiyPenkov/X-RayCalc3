(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit unit_UncertThread;

(* The worker thread the uncertainty tool runs RunUncertainty on. It runs
   Parallel loops and pumps no messages, so it ends with
   DrainParallelTasksBeforeExit. No VCL. *)

interface

uses
  System.SysUtils, System.Classes, unit_UncertRequest, unit_UncertRun;

type
  /// <summary>Runs one request. OnProgress and OnDone are called on the
  /// worker thread; a window forwards them with TThread.Queue. Not
  /// FreeOnTerminate: the owner stops it, waits for it and frees it.</summary>
  TUncertThread = class(TThread)
  private
    FReq: TUncertRequest;
    FPriors: TArray<TUncertPrior>;
    FCounts: TArray<Double>;
    FUseGPU: Boolean;
    FSeed: UInt64;
    FRecipe: TUncertRecipe;
    FOnProgress: TUncertProgress;
    FOnDone: TProc;
    FStop: Boolean;
    FResult: TUncertResult;
    FFailure: string;
  protected
    procedure Execute; override;
  public
    constructor Create(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
      const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64; const Recipe: TUncertRecipe;
      const OnProgress: TUncertProgress; const OnDone: TProc);
    /// <summary>Asks the run to end; returns at once.</summary>
    procedure Stop;
    /// <summary>Valid once the thread has ended.</summary>
    property Result: TUncertResult read FResult;
    /// <summary>'' or what went wrong, when the run ended in an exception.</summary>
    property Failure: string read FFailure;
  end;

implementation

uses
  unit_otl_drain;

constructor TUncertThread.Create(const Req: TUncertRequest; const Priors: TArray<TUncertPrior>;
  const Counts: TArray<Double>; UseGPU: Boolean; Seed: UInt64; const Recipe: TUncertRecipe;
  const OnProgress: TUncertProgress; const OnDone: TProc);
begin
  FReq := Req;
  FPriors := Priors;
  FCounts := Counts;
  FUseGPU := UseGPU;
  FSeed := Seed;
  FRecipe := Recipe;
  FOnProgress := OnProgress;
  FOnDone := OnDone;
  inherited Create(False);
end;

procedure TUncertThread.Stop;
begin
  FStop := True;
end;

procedure TUncertThread.Execute;
begin
  { Whatever happens, the owner is told that the run has ended: it shows
    "running" until then. }
  try
    try
      try
        FResult := RunUncertainty(FReq, FPriors, FCounts, FUseGPU, FSeed, FOnProgress,
          function: Boolean
          begin
            Result := FStop;
          end, FRecipe);
      except
        on E: Exception do
          FFailure := E.Message;
      end;
    finally
      DrainParallelTasksBeforeExit;
    end;
  finally
    if Assigned(FOnDone) then
      FOnDone();
  end;
end;

end.
