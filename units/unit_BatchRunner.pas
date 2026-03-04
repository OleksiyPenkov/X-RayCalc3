(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_BatchRunner;

interface

uses
  System.SysUtils, Winapi.Windows, Vcl.Forms, Vcl.Dialogs,
  unit_CalcOrchestrator, frame_ProjectPanel;

type
  TBatchRunner = class
  private
    FOrchestrator: TCalcOrchestrator;
    FProjectPanel: TfrmProjectPanel;
    FBenchmarkPath: string;
    FBenchmarkRuns: Integer;
    FTerminated: Boolean;

    procedure ProcessBenchFile(Sender: TObject; const F: TSearchRec);
    procedure ProcessJobFile(Sender: TObject; const F: TSearchRec);
  public
    constructor Create(AOrchestrator: TCalcOrchestrator;
      AProjectPanel: TfrmProjectPanel);

    procedure RunBenchmark;
    procedure RunBatchJobs;
    procedure Stop;
  end;

implementation

uses
  unit_consts, unit_config, unit_files_list, frm_Benchmark;

{ TBatchRunner }

constructor TBatchRunner.Create(AOrchestrator: TCalcOrchestrator;
  AProjectPanel: TfrmProjectPanel);
begin
  inherited Create;
  FOrchestrator := AOrchestrator;
  FProjectPanel := AProjectPanel;
end;

procedure TBatchRunner.Stop;
begin
  FTerminated := True;
  FOrchestrator.StopCalc;
end;

procedure TBatchRunner.ProcessBenchFile(Sender: TObject; const F: TSearchRec);
var
  i: Integer;
begin
  FProjectPanel.ProjectFileName := FBenchmarkPath + F.Name;

  frmBenchmark.AddFile(ChangeFileExt(F.Name, ''));
  for i := 1 to FBenchmarkRuns do
  begin
    if FTerminated then Break;
    FProjectPanel.ReopenProject;
    FOrchestrator.RunFitting;
    Application.ProcessMessages;
    frmBenchmark.AddValue(i, FloatToStrF(FOrchestrator.LastChiSquare, ffFixed, 8, 4));
    frmBenchmark.CalcStats(False);
  end;
  if not FTerminated then frmBenchmark.CalcStats(True);
end;

procedure TBatchRunner.ProcessJobFile(Sender: TObject; const F: TSearchRec);
begin
  Application.ProcessMessages;
  if FTerminated then Exit;

  FProjectPanel.ProjectFileName := FBenchmarkPath + F.Name;

  FProjectPanel.ReopenProject;
  FOrchestrator.RunFitting;
end;

procedure TBatchRunner.RunBenchmark;
var
  Files: TFilesList;
begin
  FOrchestrator.LastChiSquare := 0;
  FBenchmarkRuns := TConfig.Section<TCalcOptions>.BenchmarkRuns;

  try
    FTerminated := False;
    frmBenchmark.Clear(FBenchmarkRuns);
    frmBenchmark.Init(TConfig.SystemDir[sdBenchOutDir]);
    frmBenchmark.Show;
    FOrchestrator.BenchmarkMode := True;

    Files := TFilesList.Create(nil);
    FBenchmarkPath := TConfig.SystemDir[sdBenchDir];
    Files.TargetPath := FBenchmarkPath;
    Files.Mask := '*' + PROJECT_EXT;
    Files.OnFile := ProcessBenchFile;
    Files.Process;
    FOrchestrator.BenchmarkMode := False;
  finally
    FreeAndNil(Files);
  end;
end;

procedure TBatchRunner.RunBatchJobs;
var
  Files: TFilesList;
begin
  try
    FTerminated := False;
    FOrchestrator.BenchmarkMode := True;
    Files := TFilesList.Create(nil);
    FBenchmarkPath := TConfig.SystemDir[sdJobsDir];
    Files.TargetPath := FBenchmarkPath;
    Files.Mask := '*' + PROJECT_EXT;
    Files.OnFile := ProcessJobFile;
    Files.Process;
    if not FTerminated then
      ShowMessage('All jobs done')
    else
      ShowMessage('Batch was terminated!');
  finally
    FreeAndNil(Files);
    FOrchestrator.BenchmarkMode := False;
  end;
end;

end.
