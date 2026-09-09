unit unit_MCPSandbox;

{ The work directory every tool is confined to. This is the minimal version
  needed by the transport loop: command-line parsing and the folder layout.
  Task 2 adds ResolvePath / RelativePath and the hashing helpers. }

interface

type
  TWorkDir = class
  private
    FRoot: string;   // absolute, no trailing delimiter
  public
    constructor Create(const ARoot: string);
    /// <summary>Reads --workdir from the command line. Raises a plain
    /// Exception (not EMCPError) when it is missing: at that point there is
    /// no protocol session to report a structured error into.</summary>
    class function CreateFromCommandLine: TWorkDir;
    procedure EnsureLayout;   // creates root, projects, jobs, inbox, log
    function ProjectsDir: string;
    function JobsDir: string;
    function InboxDir: string;
    function LogDir: string;
    property Root: string read FRoot;
  end;

var
  WorkDir: TWorkDir;

implementation

uses
  System.SysUtils, System.IOUtils,
  unit_MCPErrors;

{ TWorkDir }

constructor TWorkDir.Create(const ARoot: string);
begin
  inherited Create;
  if ARoot.Trim.IsEmpty then
    raise EMCPError.Create('invalid_argument', '--workdir must not be empty');
  if not TPath.IsPathRooted(ARoot) then
    raise EMCPError.Create('invalid_argument', '--workdir must be an absolute path', ARoot);
  FRoot := ExcludeTrailingPathDelimiter(ExpandFileName(ARoot.Trim));
end;

class function TWorkDir.CreateFromCommandLine: TWorkDir;
var
  I: Integer;
  Param, Value: string;
begin
  Value := '';
  for I := 1 to ParamCount do
  begin
    Param := ParamStr(I);
    if Param.StartsWith('--workdir=', True) then
    begin
      Value := Param.Substring(Length('--workdir='));
      Break;
    end;
    if SameText(Param, '--workdir') or SameText(Param, '-workdir') or SameText(Param, '/workdir') then
    begin
      if I < ParamCount then
        Value := ParamStr(I + 1);
      Break;
    end;
  end;
  if Value.Trim.IsEmpty then
    raise Exception.Create('--workdir <path> is required');
  Result := TWorkDir.Create(Value);
end;

procedure TWorkDir.EnsureLayout;
begin
  TDirectory.CreateDirectory(FRoot);
  TDirectory.CreateDirectory(ProjectsDir);
  TDirectory.CreateDirectory(JobsDir);
  TDirectory.CreateDirectory(InboxDir);
  TDirectory.CreateDirectory(LogDir);
end;

function TWorkDir.ProjectsDir: string;
begin
  Result := TPath.Combine(FRoot, 'projects');
end;

function TWorkDir.JobsDir: string;
begin
  Result := TPath.Combine(FRoot, 'jobs');
end;

function TWorkDir.InboxDir: string;
begin
  Result := TPath.Combine(FRoot, 'inbox');
end;

function TWorkDir.LogDir: string;
begin
  Result := TPath.Combine(FRoot, 'log');
end;

end.
