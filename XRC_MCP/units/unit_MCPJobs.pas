unit unit_MCPJobs;

{ Stub. Task 12 adds the queue, the worker thread, job.json and cancellation. }

interface

uses unit_MCPSandbox;

type
  TJobManager = class
  private
    FWorkDir: TWorkDir;   // not owned
  public
    constructor Create(AWorkDir: TWorkDir);
  end;

var
  Jobs: TJobManager;

implementation

{ TJobManager }

constructor TJobManager.Create(AWorkDir: TWorkDir);
begin
  inherited Create;
  FWorkDir := AWorkDir;
end;

end.
