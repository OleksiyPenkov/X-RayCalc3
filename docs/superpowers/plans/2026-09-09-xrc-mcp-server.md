# XRC_MCP Server Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking. Always invoke the `delphi-development` skill before writing any Delphi code.

**Goal:** A Delphi console MCP server (`XRC_MCP.exe`) that exposes the X-Ray Calc 3 engine (reflectivity, LFPSO fitting, universal mirror optimizer, materials, `.xrcx` projects, measurement inbox) to an LLM agent over JSON-RPC 2.0 on stdio, sandboxed to a `--workdir`, with a complete call journal.

**Architecture:** Transport units copied from the ELN3 MCP server (`unit_MCPProtocol`, a trimmed `unit_MCPTools` registry). Tool handlers in `unit_Tools*.pas` call thin adapter units (`unit_MCP*.pas`) that build the GUI engine's own records (`TFitStructure`, `TLayeredModel`, `TCalcThreadParams`, `TUniversalConfig`) and run the GUI's own classes (`TCalc`, `TLFPSO_Periodic/Poly`, `TUniversalOptimizer`). Long jobs run on one worker `TThread`, one at a time, so seeds are reproducible. `.xrcx` files are written by the GUI's own `TXRCProjectTree` used headless.

**Tech Stack:** Delphi (RAD Studio 37.0), Win64 Release console app, System.JSON, System.Zip, System.Hash, OmniThreadLibrary (inside the engines), VirtualTreeView (project tree), DUnitX (tests, Win32 Debug).

**Spec:** `docs/superpowers/specs/2026-09-08-xrc-mcp-server-requirements.md` (requirements) and `docs/superpowers/specs/2026-09-09-xrc-mcp-design.md` (design decisions — read both; the design note settles engine choice, structure mapping, job model, `.xrcx` writing).

## Global Constraints

- Delphi only. New console project `XRC_MCP\XRC_MCP.dproj`, built like `XRC_CMD\xrccmd.dproj`, output `_Out\BIN\XRC_MCP.exe`. Always `/t:Build`, Win64 Release only. Build command (append to the prefix from `CLAUDE.md`): `XRC_MCP\XRC_MCP.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1`
- Transport: JSON-RPC 2.0 over stdio, one JSON object per line, stdin/stdout forced to UTF-8 (`SetTextCodePage(Input, 65001)`, `SetTextCodePage(Output, 65001)`), methods `initialize`, `tools/list`, `tools/call`; `notifications/*` ignored.
- Same engine as the GUI: `Shared/Math/unit_calc.pas`, `unit_materials.pas`, `math_globals.pas`, `XRayCalc3/LFPSO/*`, `Shared/Universal/*`. No physics re-implementation. Engine edits allowed only where listed (Tasks 8 and 12) and must leave GUI/xrccmd behaviour unchanged.
- Units: Å for thickness, wavelength, σ; g/cm³ for density; degrees θ (not 2θ) everywhere. `energy` (eV) accepted wherever `lambda` is: `λ[Å] = 12398.42 / E[eV]`; wavelength used is echoed.
- Sandbox: `--workdir <path>` mandatory; every path read or written is under it; outside → error `path_outside_workdir`; `inbox\` never written. Subfolders `projects\ jobs\ inbox\ log\`.
- Journal: every `tools/call` appended as one JSON line to `log\calls.jsonl`; never truncated; large arrays replaced by length + SHA-256 of the written file.
- Errors: `{code, message, detail}` objects; no stack traces, no dialogs, no `Readln`. Never `ShowMessage`.
- Determinism: `seed` accepted by `optimize_mirror` and `fit_xrr`, echoed; same seed + inputs → identical result.
- `.xrcx` written must open in XRayCalc3 without conversion: `[INFO] Version=7` (`CURRENT_PROJECT_VERSION`).
- Tests: DUnitX in `XRayCalc3\Tests` (Win32 Debug), units `TestMCPStructure`, `TestMCPUnits`, `TestMCPInbox`, `TestMCPSandbox` (+ `TestMCPProjectFile`, `TestUniversalFitnessLayers`). Build: `XRayCalc3\Tests\XRayCalc3Tests.dproj /t:Build /p:Config=Debug /nologo /v:minimal" 2>&1`; run: `cmd.exe //c "set PATH=C:\Program Files (x86)\Embarcadero\Studio\37.0\bin;%PATH%&& XRayCalc3\Tests\_Out\BIN\XRayCalc3Tests.exe --exitbehavior:Continue" 2>&1`.
- Git: commit after every task, prefixes `+` (feature) / `*` (fix), single branch `master`. Attribution lines from the session's system reminder.
- Delphi gotchas: fields before methods in each visibility section; `inherited Create` first / `inherited Destroy` last; every `Create` paired with `try/finally Free`; flag any API you are not sure exists.

---

## File Structure

| File | Responsibility |
|---|---|
| `XRC_MCP\XRC_MCP.dpr`, `XRC_MCP\XRC_MCP.dproj` | Console program; `{$APPTYPE CONSOLE}`; lists every unit with `in` paths like `xrccmd.dpr`; `Application.Initialize` (needed by `TConfig` and VCL classes used headless) |
| `XRC_MCP\units\unit_MCPProtocol.pas` | Copied verbatim from `D:\APS\ELN\ELN3\ELN.MCPServer\unit_MCPProtocol.pas`; server name `xrc` |
| `XRC_MCP\units\unit_MCPTools.pas` | Tool registry: `TToolHandler`, `TToolDef`, `TToolRegistry` (no user/scope/plugin context) |
| `XRC_MCP\units\unit_MCPErrors.pas` | `EMCPError` (code, message, detail) and `MCPErrorJSON` |
| `XRC_MCP\units\unit_MCPSandbox.pas` | `TWorkDir`: layout, `ResolvePath`, `EnsureLayout`, `FileSHA256`, command-line parsing |
| `XRC_MCP\units\unit_MCPJournal.pas` | `calls.jsonl` writer with array compaction |
| `XRC_MCP\units\unit_MCPUnits.pas` | λ/E conversion, 2θ→θ, `GetLambdaArg` |
| `XRC_MCP\units\unit_MCPStructure.pas` | Structure JSON ⇄ `TFitStructure`; `TFitStructure` → GUI data string; `TFitStructure` → `TLayeredModel`; validation |
| `XRC_MCP\units\unit_MCPMaterials.pas` | Henke directory scan, formula parser, δ/β/n/k, absorption edges |
| `XRC_MCP\units\unit_MCPCalc.pas` | Reflectivity curve via `TCalc`; Bragg peaks; critical angle; curve file |
| `XRC_MCP\units\unit_MCPUniversal.pas` | XRFCalc config JSON → `TUniversalConfig`; evaluate structure with `TUniversalFitness`; genome → structure JSON; top-k distinctness; optimize job body |
| `XRC_MCP\units\unit_MCPJobs.pas` | `TJobManager`: queue, worker thread, states, `job.json`, cancel |
| `XRC_MCP\units\unit_MCPFit.pas` | fit job body: LFPSO setup, progress, result assembly, `.xrcx` |
| `XRC_MCP\units\unit_MCPInbox.pas` | inbox listing, curve parser (θ/I text), `meta.json` |
| `XRC_MCP\units\unit_MCPProjectFile.pas` | `.xrcx` write/read using `TXRCProjectTree` + `System.Zip` |
| `XRC_MCP\units\unit_ToolsReference.pas` | `describe_server`, `list_materials`, `optical_constants`, `list_templates` |
| `XRC_MCP\units\unit_ToolsCalc.pas` | `calc_reflectivity`, `evaluate_lines` |
| `XRC_MCP\units\unit_ToolsJobs.pas` | `optimize_mirror`, `fit_xrr`, `job_status`, `job_result`, `cancel_job` |
| `XRC_MCP\units\unit_ToolsFiles.pas` | `list_measurements`, `get_measurement`, `save_project`, `load_project`, `list_projects` |
| `XRC_MCP\units\unit_MCPServer.pas` | `RunServer`: args, work dir, registry, main loop, journal |
| `XRC_MCP\units\unit_MCPVersion.pas` | Version strings (resource + `gitrev.inc`) |
| `XRayCalc3\LFPSO\unit_LFPSO_Base.pas` (modify) | `OnProgress` callback, `Seed` property |
| `Shared\Universal\unit_universal_fitness.pas` (modify) | `EvaluateLayers` public path sharing `ComputeFoM` with `Evaluate` |
| `Shared\Universal\unit_universal_optimizer.pas` (modify) | `FinalState` property |
| `XRayCalc3\Tests\TestMCP*.pas`, `TestUniversalFitnessLayers.pas` | DUnitX tests |
| `XRC3.groupproj`, `CLAUDE.md` | Register the project; build table row |

Shared JSON helper functions (`GetOptStr`, `GetOptFloat`, `GetOptInt`, `GetOptBool`, `RequireObj`, `RequireArr`, `Num(x)`) live in `unit_MCPErrors.pas` under the name `JSONArgs` (a record with static methods) so every tools unit uses one implementation.

---

## Task 1: Project scaffold and transport loop

**Files:**
- Create: `XRC_MCP\XRC_MCP.dpr`, `XRC_MCP\XRC_MCP.dproj`, `XRC_MCP\units\unit_MCPProtocol.pas`, `XRC_MCP\units\unit_MCPTools.pas`, `XRC_MCP\units\unit_MCPErrors.pas`, `XRC_MCP\units\unit_MCPVersion.pas`, `XRC_MCP\units\unit_MCPServer.pas`
- Modify: `XRC3.groupproj`, `CLAUDE.md`

**Interfaces:**
- Produces: `TToolHandler = reference to function(const Params: TJSONObject): TJSONObject;` `TToolRegistry.Register(Name, Description: string; InputSchema: TJSONObject; Handler: TToolHandler)`, `GetToolsList`, `Execute`, `HasTool`, `Summaries: TJSONArray` (name + one-line description, for `describe_server`).
- Produces: `EMCPError = class(Exception)` with `Code`, `Detail: string`; constructor `Create(const ACode, AMessage: string; const ADetail: string = '')`; `function MCPErrorJSON(const Code, Msg, Detail: string): TJSONObject`.
- Produces: `JSONArgs` static helpers (see below).
- Produces: `ServerVersionString: string`, `GitRevision: string` (from `units\gitrev.inc`, const `GIT_REV = '...'`).

- [ ] **Step 1: Copy the protocol unit**

Copy `D:\APS\ELN\ELN3\ELN.MCPServer\unit_MCPProtocol.pas` to `XRC_MCP\units\unit_MCPProtocol.pas` unchanged except:
- `ServerInfo.AddPair('name', 'xrc');`
- move `ServerVersionString` into `unit_MCPVersion.pas` and use it from there.

- [ ] **Step 2: Write `unit_MCPVersion.pas`**

```pascal
unit unit_MCPVersion;

interface

function ServerVersionString: string;   // FileVersion resource of XRC_MCP.exe, 'unversioned' if none
function GitRevision: string;           // GIT_REV from gitrev.inc
function EngineVersionString: string;   // FileVersion of XRayCalc3.exe beside the server exe, or 'not found'

implementation

uses Winapi.Windows, System.SysUtils, System.IOUtils;

{$I gitrev.inc}   // const GIT_REV = 'abc1234';  — regenerated by the dproj pre-build event

function FileVersionOf(const Path: string): string;
var
  Size, Handle: DWORD; Buffer: TBytes; FixedInfo: PVSFixedFileInfo; InfoLen: UINT;
begin
  Result := '';
  if not TFile.Exists(Path) then Exit;
  Size := GetFileVersionInfoSize(PChar(Path), Handle);
  if Size = 0 then Exit;
  SetLength(Buffer, Size);
  if GetFileVersionInfo(PChar(Path), Handle, Size, @Buffer[0]) and
     VerQueryValue(@Buffer[0], '\', Pointer(FixedInfo), InfoLen) then
    Result := Format('%d.%d.%d.%d', [HiWord(FixedInfo.dwFileVersionMS), LoWord(FixedInfo.dwFileVersionMS),
      HiWord(FixedInfo.dwFileVersionLS), LoWord(FixedInfo.dwFileVersionLS)]);
end;

function ServerVersionString: string;
begin
  Result := FileVersionOf(ParamStr(0));
  if Result = '' then Result := 'unversioned';
end;

function GitRevision: string;
begin
  Result := GIT_REV;
end;

function EngineVersionString: string;
begin
  Result := FileVersionOf(TPath.Combine(ExtractFilePath(ParamStr(0)), 'XRayCalc3.exe'));
  if Result = '' then Result := 'not found';
end;

end.
```

Create `XRC_MCP\units\gitrev.inc` containing `const GIT_REV = 'unknown';` and commit it. In the dproj add a pre-build event (property `PreBuildEvent` in the Base PropertyGroup):
`cmd /c for /f %%i in ('git -C "$(MSBuildProjectDirectory)\.." rev-parse --short HEAD') do echo const GIT_REV = '%%i'; > "$(MSBuildProjectDirectory)\units\gitrev.inc"`
Add `units\gitrev.inc` to `.gitignore`? No — keep the committed fallback and add the line `XRC_MCP/units/gitrev.inc` to `.gitignore` after the first commit so local regeneration does not churn history. (Do it: commit the fallback, then add the ignore rule, then `git rm --cached` is NOT needed because the file stays tracked; simply accept that the tracked copy stays 'unknown'.)

- [ ] **Step 3: Write `unit_MCPErrors.pas`**

```pascal
unit unit_MCPErrors;

interface

uses System.SysUtils, System.JSON;

type
  EMCPError = class(Exception)
  private
    FCode: string;
    FDetail: string;
  public
    constructor Create(const ACode, AMessage: string; const ADetail: string = ''); reintroduce;
    property Code: string read FCode;
    property Detail: string read FDetail;
  end;

  JSONArgs = record
    class function OptStr(const P: TJSONObject; const Key, Default: string): string; static;
    class function OptFloat(const P: TJSONObject; const Key: string; Default: Double): Double; static;
    class function OptInt(const P: TJSONObject; const Key: string; Default: Integer): Integer; static;
    class function OptBool(const P: TJSONObject; const Key: string; Default: Boolean): Boolean; static;
    class function Has(const P: TJSONObject; const Key: string): Boolean; static;   // present and not null
    class function ReqStr(const P: TJSONObject; const Key: string): string; static; // raises invalid_argument
    class function ReqFloat(const P: TJSONObject; const Key: string): Double; static;
    class function ReqObj(const P: TJSONObject; const Key: string): TJSONObject; static; // not owned
    class function ReqArr(const P: TJSONObject; const Key: string): TJSONArray; static;
    class function OptObj(const P: TJSONObject; const Key: string): TJSONObject; static; // nil if absent
    class function OptArr(const P: TJSONObject; const Key: string): TJSONArray; static;
    class function Num(const V: Double): TJSONNumber; static;      // 6 significant digits, integers as integers
    class function NumArr(const V: TArray<Double>): TJSONArray; static;
  end;

function MCPErrorJSON(const Code, Msg, Detail: string): TJSONObject;

implementation

uses System.Math;

constructor EMCPError.Create(const ACode, AMessage, ADetail: string);
begin
  inherited Create(AMessage);
  FCode := ACode;
  FDetail := ADetail;
end;

function MCPErrorJSON(const Code, Msg, Detail: string): TJSONObject;
begin
  Result := TJSONObject.Create;
  Result.AddPair('code', Code);
  Result.AddPair('message', Msg);
  Result.AddPair('detail', Detail);
end;

class function JSONArgs.Has(const P: TJSONObject; const Key: string): Boolean;
begin
  Result := (P <> nil) and (P.FindValue(Key) <> nil) and not (P.FindValue(Key) is TJSONNull);
end;

class function JSONArgs.OptStr(const P: TJSONObject; const Key, Default: string): string;
begin
  if Has(P, Key) then Result := P.GetValue<string>(Key) else Result := Default;
end;

class function JSONArgs.OptFloat(const P: TJSONObject; const Key: string; Default: Double): Double;
begin
  if Has(P, Key) then
  begin
    if not (P.FindValue(Key) is TJSONNumber) then
      raise EMCPError.Create('invalid_argument', Format('"%s" must be a number', [Key]));
    Result := P.GetValue<Double>(Key);
  end
  else Result := Default;
end;

class function JSONArgs.OptInt(const P: TJSONObject; const Key: string; Default: Integer): Integer;
begin
  Result := Round(OptFloat(P, Key, Default));
end;

class function JSONArgs.OptBool(const P: TJSONObject; const Key: string; Default: Boolean): Boolean;
begin
  if Has(P, Key) then
  begin
    if not (P.FindValue(Key) is TJSONBool) then
      raise EMCPError.Create('invalid_argument', Format('"%s" must be true or false', [Key]));
    Result := P.GetValue<Boolean>(Key);
  end
  else Result := Default;
end;

class function JSONArgs.ReqStr(const P: TJSONObject; const Key: string): string;
begin
  if not Has(P, Key) then raise EMCPError.Create('invalid_argument', Format('Missing "%s"', [Key]));
  Result := P.GetValue<string>(Key);
end;

class function JSONArgs.ReqFloat(const P: TJSONObject; const Key: string): Double;
begin
  if not Has(P, Key) then raise EMCPError.Create('invalid_argument', Format('Missing "%s"', [Key]));
  Result := OptFloat(P, Key, 0);
end;

class function JSONArgs.ReqObj(const P: TJSONObject; const Key: string): TJSONObject;
begin
  if not Has(P, Key) or not (P.FindValue(Key) is TJSONObject) then
    raise EMCPError.Create('invalid_argument', Format('"%s" must be an object', [Key]));
  Result := TJSONObject(P.FindValue(Key));
end;

class function JSONArgs.ReqArr(const P: TJSONObject; const Key: string): TJSONArray;
begin
  if not Has(P, Key) or not (P.FindValue(Key) is TJSONArray) then
    raise EMCPError.Create('invalid_argument', Format('"%s" must be an array', [Key]));
  Result := TJSONArray(P.FindValue(Key));
end;

class function JSONArgs.OptObj(const P: TJSONObject; const Key: string): TJSONObject;
begin
  if Has(P, Key) then Result := ReqObj(P, Key) else Result := nil;
end;

class function JSONArgs.OptArr(const P: TJSONObject; const Key: string): TJSONArray;
begin
  if Has(P, Key) then Result := ReqArr(P, Key) else Result := nil;
end;

class function JSONArgs.Num(const V: Double): TJSONNumber;
var
  R: Double; Mag: Integer;
begin
  if IsNan(V) or IsInfinite(V) then Exit(TJSONNumber.Create(0));
  if (Frac(V) = 0) and (Abs(V) < 1e15) then Exit(TJSONNumber.Create(Int64(Round(V))));
  if V = 0 then Exit(TJSONNumber.Create(0));
  Mag := Floor(Log10(Abs(V)));
  R := RoundTo(V, Mag - 5);
  Result := TJSONNumber.Create(R);
end;

class function JSONArgs.NumArr(const V: TArray<Double>): TJSONArray;
var
  i: Integer;
begin
  Result := TJSONArray.Create;
  for i := 0 to High(V) do Result.AddElement(Num(V[i]));
end;

end.
```

- [ ] **Step 4: Write `unit_MCPTools.pas`**

Take the ELN `TToolRegistry` (shown in the research notes) and simplify: no `TToolContext`, no scoping.

```pascal
unit unit_MCPTools;

interface

uses System.JSON, System.SysUtils, System.Generics.Collections;

type
  TToolHandler = reference to function(const Params: TJSONObject): TJSONObject;

  TToolDef = record
    Name: string;
    Description: string;
    InputSchema: TJSONObject;   // owned
    Handler: TToolHandler;
  end;

  TToolRegistry = class
  private
    FTools: TList<TToolDef>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Register(const Name, Description: string; InputSchema: TJSONObject; Handler: TToolHandler);
    function GetToolsList: TJSONArray;       // caller frees
    function Summaries: TJSONArray;          // [{name, summary}] first sentence of Description; caller frees
    function Execute(const ToolName: string; const Params: TJSONObject): TJSONObject;
    function HasTool(const Name: string): Boolean;
  end;

// Schema builders shared by all tools units
function SchemaObject(const Required: array of string): TJSONObject;                  // {"type":"object","properties":{},"required":[...]}
procedure AddProp(Schema: TJSONObject; const Name, TypeName, Description: string);   // adds to properties; TypeName 'number'|'string'|'integer'|'boolean'|'object'|'array'
procedure AddEnumProp(Schema: TJSONObject; const Name, Description: string; const Values: array of string);
procedure AddRefProp(Schema: TJSONObject; const Name, Description: string; Def: TJSONObject); // object/array sub-schema (owned by Schema)
function StructureSchema: TJSONObject;   // the §3 structure object schema, description states units (Å, g/cm³)

implementation
// ... straightforward; Execute raises EMCPError('tool_not_found', ...) when missing.
end.
```

`Summaries` returns the part of `Description` up to the first `. ` (period + space) — so every description in this plan starts with a one-sentence summary.

- [ ] **Step 5: Write `unit_MCPServer.pas` (loop only; tools registered in later tasks)**

```pascal
unit unit_MCPServer;

interface

procedure RunServer;

implementation

uses
  Winapi.Windows, System.SysUtils, System.IOUtils, System.JSON, System.Diagnostics,
  unit_MCPProtocol, unit_MCPTools, unit_MCPErrors, unit_MCPSandbox, unit_MCPJournal,
  unit_ToolsReference, unit_ToolsCalc, unit_ToolsJobs, unit_ToolsFiles, unit_MCPJobs;

procedure RunServer;
var
  Registry: TToolRegistry;
  Line, Response, ToolName: string;
  Req: TMCPRequest;
  ToolResult, ToolArgs, ErrObj: TJSONObject;
  ToolsList: TJSONArray;
  SW: TStopwatch;
begin
  WorkDir := TWorkDir.CreateFromCommandLine;     // raises with a plain message when --workdir missing
  try
    WorkDir.EnsureLayout;
    Journal := TJournal.Create(WorkDir.LogDir);
    Jobs := TJobManager.Create(WorkDir);
    Registry := TToolRegistry.Create;
    try
      RegisterReferenceTools(Registry);
      RegisterCalcTools(Registry);
      RegisterJobTools(Registry);
      RegisterFileTools(Registry);

      SetTextCodePage(Input, 65001);
      SetTextCodePage(Output, 65001);
      WriteLn(ErrOutput, 'XRC_MCP: workdir=' + WorkDir.Root);
      Flush(ErrOutput);

      while not EOF(Input) do
      begin
        ReadLn(Input, Line);
        if Line.Trim.IsEmpty then Continue;
        if not TMCPProtocol.ParseRequest(Line, Req) then
        begin
          WriteLn(ErrOutput, 'XRC_MCP: unparsable request');
          Continue;
        end;
        try
          if Req.IsNotification then Continue;
          if Req.Method = 'initialize' then
            Response := TMCPProtocol.MakeInitializeResult(Req.Id)
          else if Req.Method = 'tools/list' then
          begin
            ToolsList := Registry.GetToolsList;
            try Response := TMCPProtocol.MakeToolsListResult(Req.Id, ToolsList);
            finally ToolsList.Free; end;
          end
          else if Req.Method = 'tools/call' then
          begin
            ToolName := '';
            ToolArgs := nil;
            SW := TStopwatch.StartNew;
            try
              if (Req.Params = nil) or (Req.Params.FindValue('name') = nil) then
                raise EMCPError.Create('invalid_request', 'Missing params.name');
              ToolName := Req.Params.GetValue<string>('name');
              if Req.Params.FindValue('arguments') is TJSONObject then
                ToolArgs := TJSONObject(Req.Params.FindValue('arguments'));
              if not Registry.HasTool(ToolName) then
                raise EMCPError.Create('tool_not_found', 'Tool not found: ' + ToolName);
              ToolResult := Registry.Execute(ToolName, ToolArgs);
              try
                Journal.LogCall(ToolName, ToolArgs, ToolResult, nil, SW.ElapsedMilliseconds);
                Response := TMCPProtocol.MakeToolResult(Req.Id, ToolResult.ToJSON);
              finally ToolResult.Free; end;
            except
              on E: EMCPError do
              begin
                ErrObj := MCPErrorJSON(E.Code, E.Message, E.Detail);
                try
                  Journal.LogCall(ToolName, ToolArgs, nil, ErrObj, SW.ElapsedMilliseconds);
                  Response := TMCPProtocol.MakeToolError(Req.Id, ErrObj.ToJSON);
                finally ErrObj.Free; end;
              end;
              on E: Exception do
              begin
                ErrObj := MCPErrorJSON('internal', E.Message, E.ClassName);
                try
                  Journal.LogCall(ToolName, ToolArgs, nil, ErrObj, SW.ElapsedMilliseconds);
                  Response := TMCPProtocol.MakeToolError(Req.Id, ErrObj.ToJSON);
                finally ErrObj.Free; end;
              end;
            end;
          end
          else
            Response := TMCPProtocol.MakeError(Req.Id, -32601, 'Method not found');
          WriteLn(Output, Response);
          Flush(Output);
        finally
          Req.RawJSON.Free;
          Req.Id.Free;
        end;
      end;
    finally
      Registry.Free;
      Jobs.Free;      // cancels and waits for the worker
      Journal.Free;
    end;
  finally
    WorkDir.Free;
  end;
end;

end.
```

Globals `WorkDir: TWorkDir`, `Journal: TJournal`, `Jobs: TJobManager` are declared in their own units' interface sections (`var WorkDir: TWorkDir;` in `unit_MCPSandbox`, etc.) so tool units reach them without a context record.

For this task, stub `unit_MCPSandbox`, `unit_MCPJournal`, `unit_MCPJobs` and the four `unit_Tools*` with empty registration procedures so the program links; Tasks 2–3 and 6–15 fill them. `unit_ToolsReference` registers a minimal `describe_server` returning `{server_version, git_revision}` now; Task 6 completes it.

- [ ] **Step 6: Write the dpr**

```pascal
program XRC_MCP;

{$APPTYPE CONSOLE}
{$R *.res}

uses
  FastMM5,
  System.SysUtils,
  Vcl.Forms,
  // transport / server
  unit_MCPProtocol in 'units\unit_MCPProtocol.pas',
  unit_MCPTools in 'units\unit_MCPTools.pas',
  unit_MCPErrors in 'units\unit_MCPErrors.pas',
  unit_MCPVersion in 'units\unit_MCPVersion.pas',
  unit_MCPSandbox in 'units\unit_MCPSandbox.pas',
  unit_MCPJournal in 'units\unit_MCPJournal.pas',
  unit_MCPUnits in 'units\unit_MCPUnits.pas',
  unit_MCPStructure in 'units\unit_MCPStructure.pas',
  unit_MCPMaterials in 'units\unit_MCPMaterials.pas',
  unit_MCPCalc in 'units\unit_MCPCalc.pas',
  unit_MCPUniversal in 'units\unit_MCPUniversal.pas',
  unit_MCPJobs in 'units\unit_MCPJobs.pas',
  unit_MCPFit in 'units\unit_MCPFit.pas',
  unit_MCPInbox in 'units\unit_MCPInbox.pas',
  unit_MCPProjectFile in 'units\unit_MCPProjectFile.pas',
  unit_ToolsReference in 'units\unit_ToolsReference.pas',
  unit_ToolsCalc in 'units\unit_ToolsCalc.pas',
  unit_ToolsJobs in 'units\unit_ToolsJobs.pas',
  unit_ToolsFiles in 'units\unit_ToolsFiles.pas',
  unit_MCPServer in 'units\unit_MCPServer.pas',
  // GUI engine
  math_complex in '..\Shared\Math\math_complex.pas',
  math_globals in '..\Shared\Math\math_globals.pas',
  unit_Types in '..\XRayCalc3\Units\unit_Types.pas',
  unit_consts in '..\XRayCalc3\Units\unit_consts.pas',
  unit_Config in '..\XRayCalc3\Units\unit_Config.pas',
  unit_materials in '..\Shared\Math\unit_materials.pas',
  unit_calc in '..\Shared\Math\unit_calc.pas',
  unit_SeriesIO in '..\XRayCalc3\Units\unit_SeriesIO.pas',
  unit_DataProcessing in '..\XRayCalc3\Units\unit_DataProcessing.pas',
  unit_FileUtils in '..\XRayCalc3\Units\unit_FileUtils.pas',
  unit_SMessages in '..\XRayCalc3\Components\unit_SMessages.pas',
  unit_LFPSO_Base in '..\XRayCalc3\LFPSO\unit_LFPSO_Base.pas',
  unit_LFPSO_Periodic in '..\XRayCalc3\LFPSO\unit_LFPSO_Periodic.pas',
  unit_LFPSO_Poly in '..\XRayCalc3\LFPSO\unit_LFPSO_Poly.pas',
  unit_XRCProjectTree in '..\XRayCalc3\Components\unit_XRCProjectTree.pas',
  // universal engine
  cmd_unit_types in '..\XRC_CMD\Units\cmd_unit_types.pas',
  cmd_math_globals in '..\XRC_CMD\Units\cmd_math_globals.pas',
  unit_materials_mix in '..\Shared\Math\unit_materials_mix.pas',
  unit_universal_types in '..\Shared\Universal\unit_universal_types.pas',
  unit_universal_fitness in '..\Shared\Universal\unit_universal_fitness.pas',
  unit_universal_pso in '..\Shared\Universal\unit_universal_pso.pas',
  unit_universal_io in '..\Shared\Universal\unit_universal_io.pas',
  unit_universal_optimizer in '..\Shared\Universal\unit_universal_optimizer.pas',
  unit_universal_templates in '..\Shared\Universal\unit_universal_templates.pas',
  unit_universal_refcalc in '..\Shared\Universal\unit_universal_refcalc.pas',
  unit_xrfx_package in '..\Shared\Universal\unit_xrfx_package.pas',
  unit_xrf_lines in '..\Shared\Universal\unit_xrf_lines.pas';

begin
  Application.Initialize;    // TConfig and headless VCL classes need Application
  try
    RunServer;
  except
    on E: Exception do
    begin
      WriteLn(ErrOutput, 'Fatal: ' + E.Message);
      Flush(ErrOutput);
      ExitCode := 1;
    end;
  end;
end.
```

`unit_LFPSO_Irregular` is not needed (irregular mode is not exposed). If a unit pulls it in transitively, add it.

- [ ] **Step 7: Write the dproj**

Copy `XRC_CMD\xrccmd.dproj`, then edit: new `ProjectGuid` (generate with PowerShell `[guid]::NewGuid()`), `MainSource` `XRC_MCP.dpr`, `ProjectName` `XRC_MCP`, `SanitizedProjectName` `XRC_MCP`; Base `DCC_UnitSearchPath` = `..\Shared\Math;..\Shared\Universal;..\XRC_CMD\Units;..\XRayCalc3\Units;..\XRayCalc3\LFPSO;..\XRayCalc3\Components;D:\DelphiProjects\X-RayCalc\FastMath\FastMath;$(DCC_UnitSearchPath)`; `DCC_DcuOutput` = `.\Out\DCU`; both platform groups `DCC_ExeOutput` = `..\_Out\BIN\`; replace the `DCCReference` item group with one entry per unit in the dpr; delete the `Deployment` block; keep `VerInfo_Keys` with `FileVersion=1.0.0.0`, `FileDescription=XRC MCP server`; add `<PreBuildEvent>` from Step 2. Add `Out` to `.gitignore` if not already covered (`/XRC_MCP/Out`).

- [ ] **Step 8: Register in the group project and CLAUDE.md**

`XRC3.groupproj`: add `<Projects Include="XRC_MCP\XRC_MCP.dproj"><Dependencies/></Projects>`, the three `XRC_MCP`, `XRC_MCP:Clean`, `XRC_MCP:Make` targets, and append `;XRC_MCP` to the `Build`, `Clean`, `Make` `CallTarget` lists. `CLAUDE.md`: add the build-table row `| XRC_MCP Win64 | XRC_MCP\XRC_MCP.dproj /t:Build /p:Config=Release /p:Platform=Win64 /nologo /v:minimal" 2>&1 |`, an `XRC_MCP/` line in the architecture tree ("MCP server for LLM agents; spec in docs/superpowers/specs/2026-09-09-xrc-mcp-design.md"), and update the group build order line.

- [ ] **Step 9: Build and smoke-test the loop**

Run the build command. Expected: `XRC_MCP.exe` in `_Out\BIN\`, no errors (warnings about unused units are fine).

Smoke test (PowerShell):
```powershell
New-Item -ItemType Directory -Force "$env:TEMP\xrcmcp_smoke" | Out-Null
'{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' + "`n" + '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' + "`n" + '{"jsonrpc":"2.0","id":3,"method":"tools/call","params":{"name":"describe_server","arguments":{}}}' |
  & "_Out\BIN\XRC_MCP.exe" --workdir "$env:TEMP\xrcmcp_smoke"
```
Expected: three JSON lines on stdout; line 1 contains `"serverInfo":{"name":"xrc"`; line 3 contains `server_version`. Running with no `--workdir` prints `Fatal: --workdir <path> is required` on stderr and exit code 1.

- [ ] **Step 10: Commit**

```bash
git add XRC_MCP XRC3.groupproj CLAUDE.md .gitignore docs/superpowers
git commit -m "+ XRC_MCP: console MCP server scaffold (JSON-RPC stdio loop, tool registry, design note and plan)"
```

---

## Task 2: Work-directory sandbox

**Files:**
- Create: `XRC_MCP\units\unit_MCPSandbox.pas`
- Test: `XRayCalc3\Tests\TestMCPSandbox.pas`
- Modify: `XRayCalc3\Tests\XRayCalc3Tests.dpr`, `XRayCalc3\Tests\XRayCalc3Tests.dproj` (add `..\..\XRC_MCP\units` to `DCC_UnitSearchPath`, add the unit and test references)

**Interfaces:**
- Produces:

```pascal
type
  TWorkDir = class
  private
    FRoot: string;   // absolute, no trailing delimiter
  public
    constructor Create(const ARoot: string);           // ExpandFileName; raises EMCPError('invalid_argument') if relative
    class function CreateFromCommandLine: TWorkDir;     // --workdir value; raises Exception('--workdir <path> is required')
    procedure EnsureLayout;                             // creates root, projects, jobs, inbox, log
    function ResolvePath(const Rel: string; ForWrite: Boolean): string; // absolute path under Root
    function RelativePath(const Abs: string): string;   // Root-relative with backslashes, for echoing
    function ProjectsDir: string; function JobsDir: string; function InboxDir: string; function LogDir: string;
    property Root: string read FRoot;
  end;

function FileSHA256(const Path: string): string;   // lowercase hex, System.Hash.THashSHA2
function FileSizeOf(const Path: string): Int64;
function FileModifiedUTC(const Path: string): string; // ISO-8601 'yyyy-mm-dd"T"hh:nn:ss"Z"'
function NowUTCString: string;

var
  WorkDir: TWorkDir;
```

`ResolvePath` rules (every rule is one test): empty → `invalid_argument`; `TPath.IsPathRooted(Rel)` or contains `:` or starts with `\\` → `path_outside_workdir`; any segment equal to `..` → `path_outside_workdir`; expanded path (`ExpandFileName(TPath.Combine(Root, Rel))`) must start with `Root + '\'` case-insensitively → else `path_outside_workdir`; `ForWrite` and path starts with `InboxDir + '\'` (or equals it) → `inbox_readonly`. Forward slashes are normalised to backslashes first.

- [ ] **Step 1: Write the failing tests**

```pascal
unit TestMCPSandbox;

interface

uses DUnitX.TestFramework, System.SysUtils, System.IOUtils, unit_MCPSandbox, unit_MCPErrors;

type
  [TestFixture]
  TTestMCPSandbox = class
  private
    FTemp: string;
    FWD: TWorkDir;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;
    [Test] procedure EnsureLayout_CreatesFourSubfolders;
    [Test] procedure ResolvePath_RelativeInside_ReturnsAbsoluteUnderRoot;
    [Test] procedure ResolvePath_ForwardSlashes_Normalised;
    [Test] procedure ResolvePath_DotDot_Refused;
    [Test] procedure ResolvePath_Rooted_Refused;
    [Test] procedure ResolvePath_DriveLetter_Refused;
    [Test] procedure ResolvePath_UNC_Refused;
    [Test] procedure ResolvePath_Empty_Refused;
    [Test] procedure ResolvePath_InboxWrite_Refused;
    [Test] procedure ResolvePath_InboxRead_Allowed;
    [Test] procedure RelativePath_RoundTrip;
    [Test] procedure FileSHA256_KnownValue;
  end;

implementation

procedure TTestMCPSandbox.Setup;
begin
  FTemp := TPath.Combine(TPath.GetTempPath, 'XRC_MCP_Sandbox_' + TGUID.NewGuid.ToString);
  FWD := TWorkDir.Create(FTemp);
  FWD.EnsureLayout;
end;

procedure TTestMCPSandbox.TearDown;
begin
  FWD.Free;
  if TDirectory.Exists(FTemp) then TDirectory.Delete(FTemp, True);
end;

procedure TTestMCPSandbox.EnsureLayout_CreatesFourSubfolders;
begin
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'projects')));
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'jobs')));
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'inbox')));
  Assert.IsTrue(TDirectory.Exists(TPath.Combine(FTemp, 'log')));
end;

procedure TTestMCPSandbox.ResolvePath_RelativeInside_ReturnsAbsoluteUnderRoot;
begin
  Assert.AreEqual(TPath.Combine(FTemp, 'projects\a.xrcx'), FWD.ResolvePath('projects\a.xrcx', True));
end;

procedure TTestMCPSandbox.ResolvePath_ForwardSlashes_Normalised;
begin
  Assert.AreEqual(TPath.Combine(FTemp, 'inbox\S1\c.dat'), FWD.ResolvePath('inbox/S1/c.dat', False));
end;

procedure TTestMCPSandbox.ResolvePath_DotDot_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('projects\..\..\x.txt', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_Rooted_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('\Windows\x.txt', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_DriveLetter_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('C:\x.txt', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_UNC_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('\\server\share\x', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_Empty_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('', False); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_InboxWrite_Refused;
begin
  Assert.WillRaise(procedure begin FWD.ResolvePath('inbox\S1\c.dat', True); end, EMCPError);
end;

procedure TTestMCPSandbox.ResolvePath_InboxRead_Allowed;
begin
  Assert.IsTrue(FWD.ResolvePath('inbox\S1\c.dat', False).StartsWith(FTemp));
end;

procedure TTestMCPSandbox.RelativePath_RoundTrip;
begin
  Assert.AreEqual('jobs\fit-1\curve.dat', FWD.RelativePath(FWD.ResolvePath('jobs\fit-1\curve.dat', True)));
end;

procedure TTestMCPSandbox.FileSHA256_KnownValue;
var
  F: string;
begin
  F := TPath.Combine(FTemp, 'abc.txt');
  TFile.WriteAllText(F, 'abc', TEncoding.ASCII);
  Assert.AreEqual('ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad', FileSHA256(F));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPSandbox);
end.
```

Add to the dpr: `unit_MCPErrors in '..\..\XRC_MCP\units\unit_MCPErrors.pas'`, `unit_MCPSandbox in '..\..\XRC_MCP\units\unit_MCPSandbox.pas'`, `TestMCPSandbox in 'TestMCPSandbox.pas'`; add the `DCCReference` entries to the dproj.

- [ ] **Step 2: Build tests, verify they fail to compile (unit missing)**

Run the test build. Expected: `F2613 Unit 'unit_MCPSandbox' not found`.

- [ ] **Step 3: Implement `unit_MCPSandbox.pas`**

```pascal
unit unit_MCPSandbox;

interface

uses System.SysUtils, System.Classes, System.IOUtils;

type
  TWorkDir = class
  private
    FRoot: string;
  public
    constructor Create(const ARoot: string);
    class function CreateFromCommandLine: TWorkDir;
    procedure EnsureLayout;
    function ResolvePath(const Rel: string; ForWrite: Boolean): string;
    function RelativePath(const Abs: string): string;
    function ProjectsDir: string;
    function JobsDir: string;
    function InboxDir: string;
    function LogDir: string;
    property Root: string read FRoot;
  end;

function FileSHA256(const Path: string): string;
function FileSizeOf(const Path: string): Int64;
function FileModifiedUTC(const Path: string): string;
function NowUTCString: string;

var
  WorkDir: TWorkDir;

implementation

uses System.Hash, System.DateUtils, System.StrUtils, unit_MCPErrors;

constructor TWorkDir.Create(const ARoot: string);
begin
  inherited Create;
  if (ARoot = '') or not TPath.IsPathRooted(ARoot) then
    raise EMCPError.Create('invalid_argument', '--workdir must be an absolute path', ARoot);
  FRoot := ExcludeTrailingPathDelimiter(ExpandFileName(ARoot));
end;

class function TWorkDir.CreateFromCommandLine: TWorkDir;
var
  Value: string;
begin
  if not FindCmdLineSwitch('workdir', Value, True, [clstValueNextParam, clstValueAppended]) or (Trim(Value) = '') then
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

function TWorkDir.ProjectsDir: string; begin Result := TPath.Combine(FRoot, 'projects'); end;
function TWorkDir.JobsDir: string;     begin Result := TPath.Combine(FRoot, 'jobs'); end;
function TWorkDir.InboxDir: string;    begin Result := TPath.Combine(FRoot, 'inbox'); end;
function TWorkDir.LogDir: string;      begin Result := TPath.Combine(FRoot, 'log'); end;

function TWorkDir.ResolvePath(const Rel: string; ForWrite: Boolean): string;
var
  S, Full: string;
  Seg: string;
begin
  S := StringReplace(Trim(Rel), '/', '\', [rfReplaceAll]);
  if S = '' then
    raise EMCPError.Create('invalid_argument', 'Path argument is empty');
  if S.StartsWith('\\') or (Pos(':', S) > 0) or S.StartsWith('\') then
    raise EMCPError.Create('path_outside_workdir', 'Only paths relative to the working directory are accepted', Rel);
  for Seg in S.Split(['\']) do
    if Seg = '..' then
      raise EMCPError.Create('path_outside_workdir', '".." is not allowed in paths', Rel);
  Full := ExpandFileName(TPath.Combine(FRoot, S));
  if not StartsText(FRoot + '\', Full) then
    raise EMCPError.Create('path_outside_workdir', 'Path resolves outside the working directory', Rel);
  if ForWrite and (SameText(Full, InboxDir) or StartsText(InboxDir + '\', Full)) then
    raise EMCPError.Create('inbox_readonly', 'The inbox is never written by the server', Rel);
  Result := Full;
end;

function TWorkDir.RelativePath(const Abs: string): string;
begin
  if StartsText(FRoot + '\', Abs) then
    Result := Copy(Abs, Length(FRoot) + 2, MaxInt)
  else
    Result := Abs;
end;

function FileSHA256(const Path: string): string;
var
  Stream: TFileStream;
begin
  Stream := TFileStream.Create(Path, fmOpenRead or fmShareDenyWrite);
  try
    Result := LowerCase(THashSHA2.GetHashString(Stream, THashSHA2.TSHA2Version.SHA256));
  finally
    Stream.Free;
  end;
end;

function FileSizeOf(const Path: string): Int64;
begin
  Result := TFile.GetSize(Path);
end;

function FileModifiedUTC(const Path: string): string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss"Z"', TFile.GetLastWriteTimeUtc(Path));
end;

function NowUTCString: string;
begin
  Result := FormatDateTime('yyyy-mm-dd"T"hh:nn:ss.zzz"Z"', TTimeZone.Local.ToUniversalTime(Now));
end;

end.
```

Note: `TPath.IsPathRooted` and `THashSHA2.GetHashString(Stream, Version)` exist in Delphi 10.x+ RTL; if `GetHashString` with a stream overload is not found, use `THashSHA2.GetHashBytes(Stream)`+`THash.DigestAsString`.

- [ ] **Step 4: Build and run tests**

Expected: all 12 `TTestMCPSandbox` tests pass; total test count = previous 266 + 12.

- [ ] **Step 5: Commit**

```bash
git add XRC_MCP/units/unit_MCPSandbox.pas XRayCalc3/Tests
git commit -m "+ XRC_MCP: working-directory sandbox with path resolution rules and tests"
```

---

## Task 3: Journal

**Files:**
- Create: `XRC_MCP\units\unit_MCPJournal.pas`
- Modify: `XRC_MCP\units\unit_MCPServer.pas` (already calls `Journal.LogCall`)

**Interfaces:**
- Produces:

```pascal
type
  TJournal = class
  private
    FPath: string;
    FLock: TCriticalSection;
  public
    constructor Create(const LogDir: string);      // FPath := LogDir\calls.jsonl
    destructor Destroy; override;
    procedure LogCall(const Tool: string; const Args, ResultObj, ErrorObj: TJSONObject; ElapsedMs: Int64);
    procedure LogEvent(const Kind: string; const Data: TJSONObject);   // {"ts","event":Kind,...} — job transitions
  end;

function CompactForJournal(const V: TJSONValue): TJSONValue;   // deep clone; arrays with >64 elements → {"_len":n,"_sha256":s}

var
  Journal: TJournal;
```

Compaction rule: recursively clone; a `TJSONArray` with `Count > 64` becomes `{"_len": Count}`; if the enclosing object has a sibling string pair named `file` or `path` whose value is an existing file (resolved under `WorkDir.Root` when relative), add `"_sha256": FileSHA256(that file)`. Objects and small arrays are cloned recursively. Tools that return curves always put the curve array next to its `file` pair (see Task 7), so the journal shows `curve: {_len, _sha256}`.

- [ ] **Step 1: Implement**

Write line: `{"ts": NowUTCString, "tool": Tool, "args": Compact(Args or {}), "result": Compact(ResultObj) | "error": ErrorObj clone, "ms": ElapsedMs}` serialised with `ToJSON`, appended with a `TFileStream` opened `fmOpenWrite or fmShareDenyNone` (create if missing), `Seek(0, soEnd)`, UTF-8 bytes + `#10`, under `FLock`. Never call `Rewrite` or truncate.

- [ ] **Step 2: Verify**

Build the server; run the Task 1 smoke test twice against the same work dir. Expected: `log\calls.jsonl` has two lines (the two `describe_server` calls), each parseable JSON with `"tool":"describe_server"`.

- [ ] **Step 3: Commit** — `+ XRC_MCP: call journal (log\calls.jsonl) with large-array compaction`

---

## Task 4: Unit conversions

**Files:**
- Create: `XRC_MCP\units\unit_MCPUnits.pas`
- Test: `XRayCalc3\Tests\TestMCPUnits.pas` (+ dpr/dproj entries)

**Interfaces:**
- Produces:

```pascal
const
  HC_EV_ANGSTROM = 12398.42;       // requirements §2.4
  ENGINE_HC = 12398.6;             // math_globals.H, used by the engines for table lookup (reported, not used here)

function EnergyToLambda(EeV: Double): Double;       // 12398.42 / E; raises invalid_argument if E <= 0
function LambdaToEnergy(LambdaA: Double): Double;
function TwoThetaToTheta(TwoTheta: Double): Double; // /2
// Reads "lambda" or "energy" from Params (exactly one required unless AllowMissing). Returns λ used.
function GetLambdaArg(const P: TJSONObject; const LambdaKey: string = 'lambda'; const EnergyKey: string = 'energy'; AllowMissing: Boolean = False; Default: Double = 0): Double;
```

- [ ] **Step 1: Tests**

```pascal
[Test] procedure EnergyToLambda_CuKa;   // 8047.8 eV → 1.5406 ± 0.0002
[Test] procedure LambdaToEnergy_RoundTrip; // λ=9.89 → E → λ within 1e-9
[Test] procedure EnergyToLambda_Zero_Raises; // EMCPError
[Test] procedure GetLambdaArg_LambdaOnly;   // {"lambda":1.54} → 1.54
[Test] procedure GetLambdaArg_EnergyOnly;   // {"energy":8047.8} → 1.5406
[Test] procedure GetLambdaArg_Both_Raises;  // both present → EMCPError code invalid_argument
[Test] procedure GetLambdaArg_Neither_Raises;
[Test] procedure GetLambdaArg_Neither_Default_WhenAllowed;
[Test] procedure TwoThetaToTheta_Halves;
```

- [ ] **Step 2: Run (fail), implement, run (pass), commit** — `+ XRC_MCP: wavelength/energy and 2theta conversions with tests`

---

## Task 5: Structure JSON adapter

**Files:**
- Create: `XRC_MCP\units\unit_MCPStructure.pas`
- Test: `XRayCalc3\Tests\TestMCPStructure.pas`

**Interfaces:**
- Consumes: `unit_Types.TFitStructure`, `TFitStack`, `TLayerData`, `TFitValue`, `unit_materials.TLayeredModel`, `unit_consts.PAlias`.
- Produces:

```pascal
type
  TStructureInfo = record
    PeriodicStackIndex: Integer;   // index in TFitStructure.Stacks of the first stack with N > 1, -1 if none
    Period: Double;                // sum of layer thicknesses of that stack (Å), 0 if none
    N: Integer;                    // its N
    HasCap, HasBuffer: Boolean;
    StackMap: TArray<Integer>;     // JSON stacks[k] (substrate→surface) → index in TFitStructure.Stacks
    CapIndex, BufferIndex: Integer; // TFitStructure.Stacks index of cap / buffer, -1 when absent
  end;

// Parse the requirements §3 JSON into the GUI order (surface first). Raises EMCPError('invalid_structure', ...) with the offending path in Detail.
function StructureFromJSON(const J: TJSONObject; out Info: TStructureInfo): TFitStructure;
// Inverse: GUI order → §3 JSON. Uses Info to label cap/buffer; stacks reported substrate→surface.
function StructureToJSON(const S: TFitStructure; const Info: TStructureInfo): TJSONObject;
// The GUI's TXRCStructure.ToString format ("Stacks"/"Subs" with H,HP,Hmin,... fields). Stack titles: 'Cap', 'ML', 'Buffer' / 'Main'.
function StructureToXRCData(const S: TFitStructure; const Info: TStructureInfo): string;
function StructureFromXRCData(const Data: string; out Info: TStructureInfo): TFitStructure;
// Expanded physical model for TCalc (same as TXRCStructure.Model(False) + TLFPSO_BASE.FillModel)
function BuildLayeredModel(const S: TFitStructure): TLayeredModel;   // caller frees
// Echo of densities: after TLayeredModel.Generate, reads Materials[].ro for layers whose r = 0
procedure FillDefaultDensities(var S: TFitStructure; Model: TLayeredModel);
function ValidateMaterials(const S: TFitStructure): string; // '' or the first unknown material name (Henke file missing)
```

Mapping (from the design note §3): JSON `cap` → `Stacks[0]` (N=1, Header 'Cap'); JSON `stacks[k-1..0]` → next stacks (Header 'ML'); JSON `buffer` → last stack (N=1, Header 'Buffer'); `substrate` → `Subs` (`P[1].V = 1E8`, `P[2] = sigma`, `P[3] = density`). Layer fields: `P[1].V = thickness`, `P[2].V = sigma` (default 0), `P[3].V = density` (default 0 = Henke bulk). `min/max` default to `V` (fixed); Task 15 sets bounds for free parameters. `StackID = stack index`, `LayerID = layer index`, `Paired = False`. `Stacks[i].D` = sum of thicknesses when N > 1 (as `TXRCStructure.ToFitStructure`).

Validation: `substrate.material` required; at least one stack with ≥ 1 layer; `N ≥ 1`; `thickness > 0`; `sigma ≥ 0`; `density ≥ 0`; total expanded layers ≤ 20000 (`MAX_LAYERS`); unknown material → `unknown_material` with the name in Detail (checked against `TConfig.SystemDir[sdHenke] + Name + '.bin'`).

`StructureToXRCData` writes for every layer the 16 pairs in `TXRCStructure.ToString` order: `M`, then for p in 1..3: `PAlias[p]` value, `<P>P` paired bool, `<P>min`, `<P>max`, `Profile<P>` (`TLayerData.ProfileToString`, `''` when no profile). Substrate object `{"M","s","r"}`. `StructureFromXRCData` is `TXRCStructure.FromString` without the controls (use `FindValue` fallbacks exactly as `FindBoolValue/FindValue/FindStrValue` do: missing `HP` → false, missing `Hmin/Hmax` → V).

`BuildLayeredModel`: `Model := TLayeredModel.Create; Model.Init;` then for each stack, for `j := 1 to N`: `Model.AddLayers(-1, Data, StackLen)` with `Data[k].Material/P/StackID/LayerID` from the stack (exactly `TLFPSO_BASE.FillModel`), then `Model.AddSubstrate(Copy(Data,0,1))` with the substrate. Profiles (`PP`) are applied by the caller when needed (Task 15 uses the LFPSO result model instead).

- [ ] **Step 1: Tests**

```pascal
const RUC_JSON = '{"substrate":{"material":"SiO2","density":2.2,"sigma":3.0},' +
  '"stacks":[{"N":30,"layers":[{"material":"Ru","thickness":14.7,"sigma":3.0,"density":12.4},' +
  '{"material":"C","thickness":53.8,"sigma":3.0,"density":2.2}]}],' +
  '"cap":{"material":"Ru","thickness":20.0,"sigma":3.0,"density":12.4},' +
  '"buffer":{"material":"Ru","thickness":197.0,"sigma":3.0,"density":12.4}}';

[Test] procedure FromJSON_OrderIsSurfaceFirst;        // Stacks[0].Header='Cap', Stacks[1].N=30, Stacks[2].Header='Buffer'
[Test] procedure FromJSON_Info;                       // PeriodicStackIndex=1, Period≈68.5, N=30, HasCap, HasBuffer, StackMap=[1], CapIndex=0, BufferIndex=2
[Test] procedure FromJSON_TwoStacks_ReversedOrder;    // stacks [A(N=10), B(N=5)] → Stacks: B first, then A
[Test] procedure FromJSON_MissingDensity_IsZero;
[Test] procedure FromJSON_MissingSubstrate_Raises;    // invalid_structure
[Test] procedure FromJSON_NegativeThickness_Raises;
[Test] procedure ToJSON_RoundTrip;                    // FromJSON→ToJSON→FromJSON equal fields (materials, N, H, s, r) and stacks substrate→surface
[Test] procedure XRCData_RoundTrip;                   // StructureToXRCData→StructureFromXRCData equal; contains '"Stacks"' and '"Subs"'
[Test] procedure XRCData_HasAllSixteenLayerKeys;      // parse JSON, check keys M,H,HP,Hmin,Hmax,ProfileH,s,SP,Smin,Smax,ProfileS,r,RP,Rmin,Rmax,ProfileR
[Test] procedure BuildLayeredModel_LayerCount;        // Layers length = 1 (vacuum) + 1 + 60 + 1 + 1 (substrate) = 64
[Test] procedure BuildLayeredModel_TopLayerIsCap;     // Layers[1].L = 20, LayerNames[1]='Ru'
```

`BuildLayeredModel` tests need no Henke files (no `Generate` call).

- [ ] **Step 2: Run (fail), implement, run (pass), commit** — `+ XRC_MCP: structure JSON <-> TFitStructure/XRC data string adapters with tests`

---

## Task 6: Materials, Henke and `describe_server`

**Files:**
- Create: `XRC_MCP\units\unit_MCPMaterials.pas`, complete `XRC_MCP\units\unit_ToolsReference.pas`
- Consumes: `math_globals.ReadHenkeTable(Name, Na, Nro, Table)` (table of `(e, f1, f2)`), `unit_Config.TConfig.SystemDir[sdHenke]`, `unit_materials.ClassicalElectronRadius` (= 0.54014E-5, so `c = CER·ρ/A·λ²` is `2δ`), `unit_universal_templates.LoadTemplates`, `unit_xrf_lines.LoadXRFLines/GetAllElements`.

**Interfaces:**
- Produces:

```pascal
type
  TFormulaPart = record Symbol: string; Count: Double; end;
  TMaterialEntry = record
    Name: string;          // file base name as on disk
    AtomicMass, BulkDensity: Double;   // from the .bin header
    Parsed: Boolean;
    Parts: TArray<TFormulaPart>;
    IsElement: Boolean;
  end;

function HenkeDir: string;                                   // TConfig.SystemDir[sdHenke] (with trailing delimiter)
function HenkeExists(const Material: string): Boolean;
function ListMaterials(const ElementFilter: TArray<string>): TArray<TMaterialEntry>; // filter empty = all; else Parsed and every part symbol in filter
function ParseFormula(const S: string; out Parts: TArray<TFormulaPart>): Boolean;   // 'B4C' → [B:4, C:1]; 'W0.7Si0.3' → [W:0.7, Si:0.3]; 'SiIMD' → False
function OpticalConstants(const Material: string; LambdaA, Density: Double; out DensityUsed, Delta, Beta: Double): Boolean; // Density<=0 → bulk
function NearestEdges(const Material: string; EeV, WindowFraction: Double): TJSONArray; // per element in the formula: [{element, edge_eV, distance_eV}] within ±WindowFraction·E
function HenkeSummary: TJSONObject;   // {path, table_count, newest_file_utc, source_note}
```

`OpticalConstants`: `ReadHenke(Material, 0, LambdaA, f, Na, Nro)` (the GUI's `math_globals` version); `c := ClassicalElectronRadius * ρ / Na * λ²`; `Delta := 0.5 * f.re * c`; `Beta := 0.5 * f.im * c` (from `ε = 1 − f1·c + i·f2·c`, `n = 1 − δ + iβ`, `ε ≈ 1 − 2δ + 2iβ`). `n = 1 − δ`, `k = β`.

`NearestEdges`: for each element symbol in the formula, `ReadHenkeTable(symbol, Na, Nro, Table)`; an edge is a table index `i` where `Table[i+1].f2 / Table[i].f2 > 1.5` and `Table[i+1].e − Table[i].e < 0.02·Table[i].e`; report edges with `|e − E| ≤ WindowFraction·E`, sorted by distance. Window default 0.25. If the symbol has no table, skip it.

`ParseFormula`: tokens `[A-Z][a-z]?` followed by an optional number (`\d+(\.\d+)?`); the whole string must be consumed; symbols must be in a fixed list of the 118 element symbols (put the list in the unit). Case: file names on disk are mixed (`SI.bin`, `Si.bin`, `RU.bin`) — try the exact name, else `TDirectory.GetFiles(HenkeDir, '*.bin')` case-insensitive match (cache the directory listing once).

`describe_server` result (all keys required by requirements §4.1):

```json
{
 "server": {"name":"xrc","version":<ServerVersionString>,"git_revision":<GitRevision>,"engine":"X-Ray Calc 3 (Shared/Math, XRayCalc3/LFPSO, Shared/Universal) compiled into this binary","xraycalc3_exe_version":<EngineVersionString>},
 "henke": {"path":..,"table_count":..,"newest_file_utc":..,"source_note":"X-Ray Calc .bin conversions of CXRO Henke f1/f2 tables; provenance not embedded — see open question 4"},
 "xrf_lines_file": <path>, "templates_file": <path or null>,
 "units": {"length":"angstrom","density":"g/cm3","angle":"degrees, theta (grazing incidence, NOT 2theta)","energy":"eV, lambda = 12398.42 / E","engine_table_constant":"12398.6 (math_globals.H, Henke interpolation only)"},
 "material_syntax": "Henke table base name, case-insensitive (Ru, C, B4C, SiO2, RuB2, ...). list_materials enumerates them. Composition-mixing strings such as W0.7Si0.3 are not supported in v1.",
 "structure_order": "stacks are listed from substrate to surface; cap is the top layer; buffer sits between substrate and the first stack",
 "limits": {"max_layers":20000,"max_points":100000,"max_inline_points":2000,"max_jobs_queued":16,"jobs_concurrent":1,"max_lines":16,"max_pool_elements":16},
 "workdir": {"root":..,"projects":"projects\\","jobs":"jobs\\<job_id>\\","inbox":"inbox\\<specimen>\\ (read-only)","log":"log\\calls.jsonl"},
 "fit": {"engine":"GUI LFPSO (TLFPSO_Periodic / TLFPSO_Poly)","chi2":"1000/(n-1) * sum(((log10 I_meas - log10 R_calc)/log10 R_calc)^2 * w_point * w_theta) over points [tail..n-tail); w_point = I/movavg(I) when > 3 (point_weight=true); w_theta from theta_weight 0..5 as in the GUI","free_parameters":"layer thickness/sigma/density only. The GUI engine keeps the substrate fixed (TLFPSO_BASE.FillModel copies Subs.P verbatim; only stack layers are in the particle vector), and it has no scale, background or resolution parameters; those are refused with error not_fittable","top_k_rule":"see optimize_mirror description"},
 "tools": <Registry.Summaries>
}
```

`list_materials`, `optical_constants`, `list_templates` results:

- `list_materials {filter?: string[]}` → `{"count", "materials":[{"name","formula":{"B":4,"C":1}|null,"is_element","bulk_density","atomic_mass"}]}`.
- `optical_constants {material, lambda|energy, density?, edge_window?}` → `{"material","lambda_used","energy_eV","density_used","delta","beta","n","k","edges":[...]}`; unknown material → `unknown_material`.
- `list_templates {pool: string[]}` → `{"templates":[{"key","description","layers":[{"material","thickness":"gamma"|"1-gamma"|<Å>,"sigma","density"}],"caps":[{"name","material","sigma","density","thickness_min","thickness_max"}],"gamma_reduction","one_minus_gamma_reduction"}]}` for templates whose two key materials are both in `pool` (case-insensitive). Empty pool → all templates. Templates file: `--templates <file>` switch, default `TemplatePath` from `XRFCalc.ini` beside the exe (`[General] TemplatePath`) if present, else none (then `list_templates` returns an empty array and `describe_server.templates_file` is null).

XRF lines: `--lines <file>` switch, default `XRFLinesPath` from `XRFCalc.ini` beside the exe, else `<exe dir>\..\..\Shared\Universal\xrf_lines.json`, else `<exe dir>\xrf_lines.json`. Loaded once at startup with `LoadXRFLines`; failure to find any is a startup error (fatal, message names the switch).

Schemas: every tool's `inputSchema` is built with the Task 1 helpers; descriptions must state units ("Å", "g/cm³", "θ in degrees, not 2θ") on every numeric property.

- [ ] **Step 1: Implement units and tools**
- [ ] **Step 2: Verify with the smoke harness**

Pipe `describe_server`, `list_materials {"filter":["Ru","C"]}` (expect `Ru`, `C`, `RuC`-like names only), `optical_constants {"material":"Ru","lambda":1.5406}` (expect δ ≈ 3.2e-5 ± 1e-5 range and β > 0), `list_templates {"pool":["Ru","C"]}` (expect `Ru/C`), `optical_constants {"material":"Xx","lambda":1.54}` (expect `isError` with code `unknown_material`).

- [ ] **Step 3: Commit** — `+ XRC_MCP: describe_server, list_materials, optical_constants, list_templates`

---

## Task 7: `calc_reflectivity`

**Files:**
- Create: `XRC_MCP\units\unit_MCPCalc.pas`, `XRC_MCP\units\unit_ToolsCalc.pas` (calc part; `evaluate_lines` added in Task 9)
- Consumes: `unit_calc.TCalc`, `unit_Types.TCalcThreadParams` (`Mode := cmTheta; StartT; EndT; DT; Lambda; N; K := 1; P; RF := rfError; MVAWindow := 10`), `unit_MCPStructure.BuildLayeredModel`.

**Interfaces:**
- Produces:

```pascal
type
  TPeak = record Order: Integer; Theta, R, FWHM: Double; end;
  TCalcRequest = record
    Structure: TFitStructure; Info: TStructureInfo;
    Lambda, ThetaMin, ThetaMax, DeltaTheta: Double; Points: Integer;
    Polarization: unit_Types.TPolarisation; RMin: Double;   // RMin = TCalc.Limit, default 1e-7
  end;

function RunCalc(const Req: TCalcRequest; out DensitiesUsed: TFitStructure): unit_Types.TDataArray; // θ ascending
function FindBraggPeaks(const Curve: unit_Types.TDataArray; Lambda, Period: Double; ThetaC: Double): TArray<TPeak>;
function CriticalAngleDeg(const S: TFitStructure; Lambda: Double): Double;  // sqrt(2δ) of the topmost layer (or substrate if no layers), degrees
procedure WriteCurveFile(const Path: string; const Curve: unit_Types.TDataArray; const XLabel, YLabel: string); // "theta_deg<TAB>R" header + "%.6g<TAB>%.8e"
function CurveToJSON(const Curve: unit_Types.TDataArray; MaxPoints: Integer): TJSONArray; // [[θ,R],...]; nil when Length > MaxPoints
```

`RunCalc` (this is `TCalcOrchestrator.PrepareCalc` + `RunCalc` without the UI):

```pascal
Calc := TCalc.Create;
try
  Calc.Limit := Req.RMin;
  P.Mode := cmTheta; P.Lambda := Req.Lambda; P.StartT := Req.ThetaMin; P.EndT := Req.ThetaMax;
  P.DT := Req.DeltaTheta; P.N := Req.Points; P.K := 1; P.P := Req.Polarization; P.RF := rfError; P.MVAWindow := 10;
  Calc.Params := P;
  Calc.Model := BuildLayeredModel(Req.Structure);   // TCalc frees Model in Destroy? — check unit_calc.TCalc.Destroy; if it does NOT free, free it here
  Calc.Run;
  Result := Copy(Calc.Results);
  FillDefaultDensities(DensitiesUsed, Calc.Model);
finally
  Calc.Free;
end;
```

Important: read `TCalc.Destroy` in `Shared\Math\unit_calc.pas` and `TCalc.PrepareWorkers` to confirm ownership of `Model` and thread count (`NThreads` uses `TConfig.Section<TCalcOptions>.NumberOfThreads`, 0 = all cores; leave as is). `Polarization` `'s'` → `cmS`, `'p'` and `'sp'` → `cmSP` (the engine has two modes; document in the schema that `p` is computed as `sp`).

`FindBraggPeaks`: local maxima (`R[i] > R[i-1]` and `R[i] ≥ R[i+1]`) with `θ > ThetaC + 0.05°` and `R[i] > 3·min(R[i-w..i+w])` for `w = max(3, Points div 200)`; `FWHM` by linear interpolation of the half-maximum crossings on each side; `Order := Round(2·Period·sin(θ)/λ)` when `Period > 0`, else the running index from 1. Keep peaks with `Order ≥ 1`; if two peaks share an order keep the higher R.

Tool `calc_reflectivity` args: `structure` (required), `lambda|energy`, `theta_min` (default 0.05), `theta_max` (default 5), `points` (default 2000, max `max_points`), `polarization` (`s|p|sp`, default `sp`), `delta_theta` (default 0), `r_min` (default 1e-7), `max_inline_points` (default 2000). Result:

```json
{"job_id":"calc-…","lambda_used":..,"energy_eV":..,"theta_unit":"deg theta","polarization":..,"delta_theta":..,
 "structure_used":<StructureToJSON with densities filled>,
 "file":"jobs\\calc-…\\curve.dat","points":N,"curve":[[θ,R],...] or null,
 "critical_angle_deg":..,"bragg_peaks":[{"order","theta_deg","r_peak","fwhm_deg"}],
 "period_A":..,"n_periods":..}
```

The job folder `jobs\calc-<stamp>\` is created synchronously (no worker) and also holds `structure.json` (the echoed structure) and `request.json`.

- [ ] **Step 1: Implement**
- [ ] **Step 2: Verify acceptance 2 (server side)**

Smoke: `calc_reflectivity` with the Ru/C structure from Task 5 (`d = 68.5`, `Γ = 0.215` → Ru 14.73 / C 53.77, N 30, Ru buffer 197, substrate `SiO2`), `lambda 1.5406`, `theta_min 0.1`, `theta_max 4`, `points 2000`. Expected: first Bragg peak `theta_deg` within 0.01° of `asin(1.5406/(2·68.5)) = 0.644°`… (compute: `1.5406/137 = 0.011245`, `asin → 0.6443°`), `r_peak` between 0.3 and 0.9, `curve.dat` exists, journal line has `"curve":{"_len":2000,"_sha256":…}`.

Author's check (not automated): open `projects\` `.xrcx` written in Task 14 for this structure in XRayCalc3 and compare curves.

- [ ] **Step 3: Commit** — `+ XRC_MCP: calc_reflectivity with Bragg peak and critical angle report`

---

## Task 8: Engine refactor — `TUniversalFitness.EvaluateLayers`, `TUniversalOptimizer.FinalState`

**Files:**
- Modify: `Shared\Universal\unit_universal_fitness.pas`, `Shared\Universal\unit_universal_optimizer.pas`
- Test: `XRayCalc3\Tests\TestUniversalFitnessLayers.pas`

**Interfaces:**
- Produces (fitness):

```pascal
type
  TLayerSetBuilder = reference to procedure(TargetIdx: Integer; var Layers: TLayers); // fills FLayersBuf for target λ
public
  // Existing: function Evaluate(const Genome: TGenome; var Results: TTargetResults): Single;
  // New: same FoM code, but the layer stack for each target comes from Builder; d and NInt drive Bragg angles and FWHM_ref.
  function EvaluateLayers(const Builder: TLayerSetBuilder; d: Single; NInt: Integer; var Results: TTargetResults): Single;
```

Refactor: move everything in `Evaluate` after the template-penalty block into a private `function ComputeFoM(const Build: TLayerSetBuilder; d: Single; NInt: Integer; Penalty: Single; var Results: TTargetResults): Single` where the per-target loop calls `Build(i, FLayersBuf)` instead of `BuildLayers(Genome, i)`. `Evaluate` becomes: compute the template penalty as now, then `Result := ComputeFoM(procedure(i: Integer; var L: TLayers) begin BuildLayers(Genome, i) end, Genome.d, NRound(Genome.N), Penalty, Results)`. `EvaluateLayers` calls `ComputeFoM(Builder, d, NInt, 0, Results)`. No numeric change anywhere.

- Produces (optimizer): `property FinalState: TOptState read FFinalState;` assigned from `FPSO.GetState` right after the final `FIO.SaveCheckpoint` (still inside `try`, before the `finally` frees `FPSO`). Also `property Templates: TTemplateLibrary read FTemplates;` and `property Mixer: TMaterialMixer read FMixer;` are NOT safe after Run (freed) — instead add `property FinalTemplates: TTemplateLibrary read FTemplates` (array copy survives) and capture element names/densities into a new record `TFinalInfo = record ElementNames: TArray<string>; ElementDensities: TArray<Single>; SubstrateDensity: Single; end; property FinalInfo: TFinalInfo read FFinalInfo;` filled before freeing the mixer.

- [ ] **Step 1: Test**

```pascal
[TestFixture] TTestUniversalFitnessLayers
[Test] procedure EvaluateLayers_MatchesEvaluate_ForSameGenome;
```
Build a `TUniversalConfig` in code: lines `Be 114.0`, `Mg 9.89`, pool `['W','Si']`, `Structure.PureElements := True`, `Fitness.wR 1, wFWHM 0.5, RMinThreshold 0.001, Polarization cmSP, wPurity 1, ScanPoints 200, ScanHalfRange 5`, substrate `Si`, `HenkePath := TConfig.SystemDir[sdHenke]`. Mixer `Initialize(['W','Si'], [114.0, 9.89], 'Si', HenkePath)`. Genome: `Composition[0] = [1,0]`, `[1] = [0,1]`, `d 40`, `Gamma 0.4`, `N 60`, `Sigma 3`. `F1 := Fitness.Evaluate(G, R1)`; `F2 := Fitness.EvaluateLayers(Builder, 40, 60, R2)` where `Builder` builds the bilayer exactly as the non-template branch of `BuildLayers` (vacuum, N×(W H1, Si H2), substrate) using `Mixer.CalcMixedEpsilon`. Assert `Abs(F1 − F2) < 1e-6` and per-line `RPeak/FWHM` equal within 1e-6. Skip (Assert.Pass with message) if `W.bin` is missing.

The test needs `unit_Config` for the Henke path (already linked) and `TConfig` initialised (the test dpr uses `Application`? `unit_Config` uses `Forms`; it is already in the test build — fine).

- [ ] **Step 2: Refactor, run all tests (existing 266 + new pass), rebuild XRayCalc3, xrccmd, XRFCalc (Win64 Release) to prove nothing else broke**
- [ ] **Step 3: Commit** — `* universal fitness: EvaluateLayers shares ComputeFoM with Evaluate; optimizer exposes FinalState`

---

## Task 9: Universal adapter and `evaluate_lines`

**Files:**
- Create: `XRC_MCP\units\unit_MCPUniversal.pas`; extend `unit_ToolsCalc.pas`
- Consumes: Task 8 API, `TUniversalIO.LoadConfig` field names (the config JSON keys are exactly XRFCalc's: `lines`, `element_pool`, `excluded_pairs`, `structure{type,layers_per_period,pure_elements,d,gamma,N,sigma,density_factor}`, `fitness{w_R,w_FWHM,R_min_threshold,polarization,delta_theta,theta_min,w_purity,scan_points,scan_half_range}`, `optimizer{population,iterations,tolerance,stagnation_limit,w1,w2,jamming_max,checkpoint_every}`, `substrate`, `template_file`).

**Interfaces:**
- Produces:

```pascal
function ConfigFromJSON(const J: TJSONObject; const OutputDir: string): TUniversalConfig;
  // Same parsing as TUniversalIO.LoadConfig but from an object (write a shared private routine by moving LoadConfig's body into a new public
  // class function TUniversalIO.ConfigFromJSONObject(JSON: TJSONObject): TUniversalConfig and have LoadConfig call it — a mechanical engine edit,
  // no numeric change). Then: HenkePath := HenkeDir; OutputDir := arg; ResumeFrom := ''; TemplatePath := resolved (see below).
  // Lines: each item {name, lambda|energy, weight?} (weight default 1); a bare string is an element symbol → GetXRFLambda.
  // Defaults when a section is missing: optimizer {population 1000, iterations 100, tolerance 1e-6, stagnation_limit 200, w1 0.4, w2 0.5, jamming_max 30, checkpoint_every 100}
  // (XRFCalc TframeRunConfig.SetDefaults + design spec); fitness {w_R 1, w_FWHM 0.5, R_min_threshold 0.001, polarization sp, w_purity 1};
  // structure {type bilayer, layers_per_period 2, pure_elements true, d 30..80, gamma 0.15..0.70, N 40..200, sigma 3 fixed, density_factor 1}.
function ConfigToJSON(const C: TUniversalConfig): TJSONObject;          // TUniversalIO.SaveConfig shape (echo)
function FitnessConfigFromJSON(const J: TJSONObject; const Base: TFitnessConfig): TFitnessConfig; // overrides for evaluate_lines
function LinesFromJSON(const A: TJSONArray): TArray<TXRFLine>;

// Evaluate an explicit structure with the optimizer's own FoM.
function EvaluateStructure(const S: TFitStructure; const Info: TStructureInfo; const Lines: TArray<TXRFLine>;
  const Fit: TFitnessConfig; out Results: TTargetResults): Single;   // returns FoM (positive = -Evaluate)

// Genome → §3 structure JSON (mirrors TUniversalFitness.BuildLayers: template path with cap and per-period sublayers, or plain bilayer)
function GenomeToStructure(const G: TGenome; const C: TUniversalConfig; const Templates: TTemplateLibrary;
  const ElementNames: TArray<string>; const ElementDensities: TArray<Single>; SubstrateDensity: Single): TJSONObject;
function GenomeToJSON(const G: TGenome; const ElementNames: TArray<string>): TJSONObject; // {composition:[{W:1}, {Si:1}], d, gamma, N, sigma, cap_h, cap_variant, density_factor:[..]}
function GenomeKey(const G: TGenome; const ElementNames: TArray<string>): string;         // 'W/Si' dominant pair
function DistinctTopK(const Particles: TParticleArray; K: Integer; const ElementNames: TArray<string>): TArray<Integer>;
```

`EvaluateStructure`: materials = distinct layer materials + substrate; `Mixer.Initialize(materials, lambdas, substrate, HenkeDir)`; `Config.Lines := Lines; Config.ElementPool := materials; Config.Fitness := Fit; Config.Structure.PureElements := False;` `Fitness := TUniversalFitness.Create(Mixer, Config, nil)`; `Builder`: layer 0 vacuum (`e = (1,0)`, `H 0`, `S 0`), then every expanded layer of `BuildLayeredModel(S)` order (surface first) with `Mixer.CalcSingleEpsilon(FindElementIndex(mat), density (bulk when 0), TargetIdx, Eps)`, `H`, `S = sigma`, `Rho`; last: substrate `CalcSubstrateEpsilon`, `H 1e8`, `S = substrate sigma`. `d := Info.Period`, `NInt := Info.N` (error `invalid_structure` "no periodic stack" when `Info.PeriodicStackIndex < 0`). Return `-Fitness.EvaluateLayers(...)`. Wrap `Initialize` in the global `HenkeCwdLock: TCriticalSection` (declared in `unit_MCPUniversal`, also used by Task 11).

`DistinctTopK` rule (documented in the `optimize_mirror` description and `describe_server.fit.top_k_rule`): sort particles by `PBestFoM` ascending (best first); walk; accept a particle if for every accepted one either `GenomeKey` differs, or `|d − d_acc| / d_acc > 0.05`, or `|Γ − Γ_acc| > 0.05`, or `NRound(N) ≠ NRound(N_acc)`; stop at K. Always include the optimizer's `ABest` as entry 0 (it is the global best).

`evaluate_lines` tool args: `structure`, `lines` (array of `{name, lambda|energy, weight?}` or element symbols), `fitness` (optional overrides). Result: `{"fom", "lines":[{"name","lambda_used","theta_bragg_deg","r_peak","fwhm_deg","valid"}], "fitness_used":{w_R,...,scan_points,scan_half_range,polarization,delta_theta,theta_min}, "period_A","n_periods","structure_used"}`. Note the fitness `theta_min` is the optimizer's dark-zone threshold, not the scan start.

- [ ] **Step 1: Implement** (including the mechanical `TUniversalIO.ConfigFromJSONObject` split; rebuild xrccmd and XRFCalc afterwards)
- [ ] **Step 2: Verify**

Smoke: `evaluate_lines` for the Ru/C structure with lines `[{"name":"B","lambda":67.6},{"name":"Si","lambda":7.126}]`. Expected: `fom` finite, both `valid` true, `theta_bragg_deg` for Si ≈ `asin(7.126/137) = 2.98°`, `r_peak` in (0,1).

- [ ] **Step 3: Commit** — `+ XRC_MCP: evaluate_lines via TUniversalFitness.EvaluateLayers; XRFCalc config adapter`

---

## Task 10: Job manager

**Files:**
- Create: `XRC_MCP\units\unit_MCPJobs.pas`, `XRC_MCP\units\unit_ToolsJobs.pas` (status/result/cancel; submit tools in Tasks 11 and 15)

**Interfaces:**
- Produces:

```pascal
type
  TJobState = (jsQueued, jsRunning, jsFinished, jsFailed, jsCancelled);
  TJobKind = (jkOptimize, jkFit);

  TJob = class;
  TJobBody = reference to procedure(Job: TJob);   // runs on the worker; checks Job.CancelRequested; sets Job.ResultObj

  TJob = class
  private
    FLock: TCriticalSection;
  public
    Id: string;                 // 'opt-yyyymmdd-hhnnss-xxxx' | 'fit-...'
    Kind: TJobKind;
    State: TJobState;
    Dir: string;                // jobs\<id>\ absolute
    Seed: Integer;
    Iteration, MaxIterations: Integer;
    BestValue: Double;          // FoM (optimize) or χ² (fit)
    LastMessage: string;
    StartedUTC, FinishedUTC: string;
    Stopwatch: TStopwatch;
    CancelRequested: Boolean;   // read with TInterlocked/volatile
    ResultObj: TJSONObject;     // owned; set by body on success
    ErrorObj: TJSONObject;      // owned; set on failure {code,message,detail}
    Body: TJobBody;
    procedure Progress(AIteration: Integer; ABest: Double; const AMsg: string); // updates fields under lock, rewrites job.json (throttled to ≥ 250 ms apart)
    function StatusJSON: TJSONObject;   // {job_id,state,kind,iteration,max_iterations,best_value,elapsed_s,last_message,seed}
    procedure SaveJobFile;              // job.json = StatusJSON (+ error when failed)
  end;

  TJobManager = class
  private
    FJobs: TObjectDictionary<string, TJob>;
    FQueue: TQueue<TJob>;
    FWorker: TThread;
    FLock: TCriticalSection;
    FWake: TEvent;
    FTerminating: Boolean;
  public
    constructor Create(AWorkDir: TWorkDir);
    destructor Destroy; override;       // sets terminating, cancels running job, waits for worker
    function Submit(Kind: TJobKind; Seed: Integer; const Body: TJobBody; const Request: TJSONObject): TJob; // creates Dir, writes request.json, enqueues (raises 'too_many_jobs' when queue ≥ 16)
    function Find(const Id: string): TJob;    // nil when unknown
    function Status(const Id: string): TJSONObject;   // unknown → {"job_id","state":"unknown"}
    function ResultOf(const Id: string): TJSONObject; // raises job_not_finished / job_failed / job_cancelled / job_unknown
    function Cancel(const Id: string): TJSONObject;   // sets CancelRequested; queued → cancelled at once; returns Status
  end;

var
  Jobs: TJobManager;
```

Worker loop: wait on `FWake`; pop; `State := jsRunning; StartedUTC; Stopwatch.StartNew; SaveJobFile;` `try Body(Job); if CancelRequested then State := jsCancelled else State := jsFinished; except on E: EMCPError → ErrorObj, jsFailed; on E: Exception → ErrorObj internal, jsFailed; end; FinishedUTC; SaveJobFile; Journal.LogEvent('job', StatusJSON)`. Seed handling belongs to the body (it sets `RandSeed` first thing) so the value is echoed in `job.json`.

Tools:
- `job_status {job_id}` → `Jobs.Status`.
- `job_result {job_id}` → `Jobs.ResultOf` (a clone of `ResultObj`; errors as above with the status inside `detail`).
- `cancel_job {job_id}` → `Jobs.Cancel`.

- [ ] **Step 1: Implement.** The tool surface stays exactly §4 (no hidden test tools); the queue and cancel paths are exercised by Task 11 and Task 15.
- [ ] **Step 2: Build; `job_status {"job_id":"nope"}` → `state: unknown`; `job_result {"job_id":"nope"}` → error `job_unknown`. Commit** — `+ XRC_MCP: job manager (single worker, queue, job.json, cancel)`

---

## Task 11: `optimize_mirror` job

**Files:**
- Extend: `unit_MCPUniversal.pas` (`RunOptimizeJob`), `unit_ToolsJobs.pas`
- Consumes: `TUniversalOptimizer` (`OnIteration`, `OnCompleted`, `OnError`, `Cancel`, `FinalState`, `FinalInfo`, `FinalTemplates`), `unit_xrfx_package.CreateXRFXPackage`, `TUniversalIO.SaveConfig`.

Tool args: the XRFCalc configuration object under `config` (all sections optional with the Task 9 defaults; `lines` and `element_pool` required), `seed` (optional), `top_k` (default 5, max 20), `template_file` (optional path under workdir; else server default). Result of `job_result`:

```json
{"job_id","seed","config_used":<ConfigToJSON>,"template_file":..,"iterations_run","elapsed_s",
 "best":{"fom","genome":..,"structure":..,"lines":[{"name","lambda","theta_bragg_deg","r_peak","fwhm_deg","valid"}],"xrfx":"jobs\\opt-…\\rank_1.xrfx"},
 "top_k":[ ...same shape for rank 1..k ... ],
 "top_k_rule":"distinct by dominant material pair, or period differing > 5 %, or gamma differing > 0.05, or different N",
 "files":{"progress_log":"jobs\\opt-…\\results\\progress.log","checkpoint":"jobs\\opt-…\\results\\checkpoint.json","population":"jobs\\opt-…\\results\\population.json"}}
```

Body (`RunOptimizeJob(Job, Config, TopK)`):
1. `RandSeed := Job.Seed;` (seed chosen by the tool: `Randomize; Seed := Random(MaxInt)` when absent).
2. `Config.OutputDir := Job.Dir\results`; `TUniversalIO.SaveConfig(Config, Job.Dir\config.json)`.
3. `Opt := TUniversalOptimizer.Create(Config)`; `OnIteration` → `Job.Progress(Data.Iteration, Data.FoM, BestInfo)`, and `if Job.CancelRequested then Opt.Cancel`; `OnError` → raise `EMCPError('optimizer_error', Msg)` after Run returns (store the message in a local, since the event fires inside Run's except).
4. Under `HenkeCwdLock`: `Opt.Run` (the lock covers the whole run — the only other user is `evaluate_lines`, which is fast; acceptable).
5. After Run: `State := Opt.FinalState`; ranks = `DistinctTopK(State.Particles, TopK, Names)` with `ABest` forced first. For each rank `r`: `PerElem` from a fresh `TUniversalFitness.Evaluate` on the genome (needs a mixer — re-create `TMaterialMixer` + `TUniversalFitness` with `Config` and `Opt.FinalTemplates`, again under the lock); `structure := GenomeToStructure(...)`; write `rank_r.xrfx` with `CreateXRFXPackage(Config, Genome, FoM, PerElem, Config.OutputDir, Job.Dir\config.json, Job.Dir\rank_r.xrfx)` (the package embeds `results\`; for rank > 1 that is the best run's results — acceptable, documented in the result as `"note":"results folder is shared; rank-specific data are the manifest and structure"`).
6. Consistency assertion built into the job: `EvaluateStructure(structure of rank 1)` must equal `best.fom` within 1e-4 relative; if not, add `"consistency_warning"` to the result (do not fail).

Cancel: `Opt.Cancel` makes `Run` exit its loop and still save results; the job ends `cancelled` with a partial result available through `job_result`? No — `ResultOf` refuses cancelled jobs; store the partial result in `job.json` under `partial` so it is not lost.

- [ ] **Step 1: Implement**
- [ ] **Step 2: Verify acceptance 3 (server side)**

Config (XRFCalc defaults, tiny run): lines `["Be","B","C","N","O","F","Na","Mg","Al","Si"]`, pool `["W","Mo","Cr","Si","B","B4C","Sc","C"]`, structure `d 30..80, gamma 0.15..0.7, N 40..200, sigma 3`, optimizer `population 50, iterations 5`, `seed 12345`, `top_k 3`. Run twice with the same seed: `best.fom` identical to all digits; `top_k` has ≤ 3 entries, all distinct by the rule; `rank_1.xrfx` exists and `job.json` says `finished`. Cross-check with XRFCalc/xrccmd: save the `config_used` to a file, add `"output_dir"`, run `_Out\BIN\xrccmd.exe -u that.json` with `RandSeed`… xrccmd has no seed switch; so instead compare against a second server run (determinism) and report the FoM to the author for the XRFCalc comparison (the author runs XRFCalc with the same config; equality requires the seed patch there too — note in Open Questions).

- [ ] **Step 3: Commit** — `+ XRC_MCP: optimize_mirror job with seed, distinct top-k and .xrfx packages`

---

## Task 12: Engine change — `TLFPSO_BASE.OnProgress` and `Seed`

**Files:**
- Modify: `XRayCalc3\LFPSO\unit_LFPSO_Base.pas`

**Interfaces:**
- Produces:

```pascal
type
  TFitProgressEvent = procedure(const Msg: TUpdateFitProgressMsg) of object;   // callee owns Msg.LayeredModel (may be nil when Full=False)
  // in TLFPSO_BASE:
  private
    FOnProgress: TFitProgressEvent;
    FSeed: Integer;   // -1 = Randomize (GUI default)
  public
    property OnProgress: TFitProgressEvent read FOnProgress write FOnProgress;
    property Seed: Integer read FSeed write FSeed;
    property BestChiSquare: single read FAbsoluteBestChiSqr;
    property BestCurve: TDataArray read FResultingCurve;
```

Changes:
- constructor: `FSeed := -1`.
- `Run`: replace `Randomize;` with `if FSeed < 0 then Randomize else RandSeed := FSeed;`.
- `SendUpdateMessage` and `SendUpdateStep`: after filling `msg_prm^`, `if Assigned(FOnProgress) then begin FOnProgress(msg_prm^); Dispose(msg_prm); end else PostMessage(...)` (the callee frees `LayeredModel` when `Full`).
- Note `FResultingCurve` is emptied in `FindTheBest` when no improvement; keep a separate `FBestCurve` copy assigned whenever `abest` improves and expose that as `BestCurve`.

Field-order rule: fields before methods/properties in each section.

- [ ] **Step 1: Edit; rebuild XRayCalc3 Win64 Release and the test project; run tests (LFPSO tests must still pass)**
- [ ] **Step 2: Commit** — `* LFPSO base: optional OnProgress callback, Seed property, BestChiSquare/BestCurve (no behaviour change for the GUI)`

---

## Task 13: Measurement inbox

**Files:**
- Create: `XRC_MCP\units\unit_MCPInbox.pas`; `unit_ToolsFiles.pas` (inbox part)
- Test: `XRayCalc3\Tests\TestMCPInbox.pas`

**Interfaces:**
- Produces:

```pascal
type
  TInboxMeta = record Lambda: Double; DateStr, Instrument, ThetaUnit: string; Raw: TJSONObject; Present: Boolean; end; // Raw owned by caller
  TMeasurement = record
    Id: string;                 // '<specimen>/<file>'
    Path: string;               // absolute
    Curve: unit_Types.TDataArray;   // θ (deg), I — after 2θ conversion when meta says '2theta'
    Columns: string;            // 'theta,intensity' | '2theta,intensity' (as detected/declared)
    Converted2Theta: Boolean;
    HeaderLines: TArray<string>;
    Meta: TInboxMeta;
  end;

function ParseCurveText(const Lines: TStrings; out Curve: unit_Types.TDataArray; out Header: TArray<string>): Integer; // returns point count; same rules as unit_SeriesIO.SeriesFromText (tab or space separated, ',' decimal fixed, non-numeric lines skipped and kept as header, zero/negative I replaced by running minimum positive I)
function ReadMeta(const Dir: string; out Meta: TInboxMeta): Boolean;       // meta.json beside the curve
function LoadMeasurement(const Id: string; MaxPoints: Integer): TMeasurement; // Id validated: exactly one '/', no '..'; extension in .dat/.txt/.xy (case-insensitive); resolves under inbox\
function DecimateCurve(const C: unit_Types.TDataArray; MaxPoints: Integer): unit_Types.TDataArray; // every k-th point, keeps first and last
function ListMeasurements(const SpecimenFilter: string): TJSONArray;  // [{specimen, files:[{name, id, size, sha256, modified_utc}], meta:{...}|null}]
```

`meta.json` keys: `lambda` (Å) or `energy` (eV), `date`, `instrument`, `theta_unit` (`theta` | `2theta`, default `theta` when absent and reported as `"theta_unit_assumed": true`). Any other keys are passed through in `meta`.

Tools:
- `list_measurements {specimen?}` → `{"inbox":"inbox\\","specimens":[...]}`.
- `get_measurement {measurement_id, max_points?}` → `{"measurement_id","file","points","points_returned","theta_range":[min,max],"columns","converted_from_2theta","lambda":..|null,"meta":{...}|null,"header":[...],"curve":[[θ,I],...]}`.

- [ ] **Step 1: Tests**

```pascal
[Test] procedure ParseCurve_TabSeparated_WithHeader;   // "2Theta\tReflectivity\ndeg\t\n\n0.010\t9.99E-1\n0.015\t9.9E-1" → 2 points, header 2 lines
[Test] procedure ParseCurve_SpaceSeparated;
[Test] procedure ParseCurve_CommaDecimal;              // "0,5 1,2e-3" → 0.5, 1.2e-3
[Test] procedure ParseCurve_ZeroIntensity_ReplacedByMinPositive;
[Test] procedure ParseCurve_SkipsNonNumericLines;
[Test] procedure ReadMeta_Parses_Lambda_ThetaUnit;
[Test] procedure ReadMeta_Energy_ConvertedToLambda;
[Test] procedure LoadMeasurement_2Theta_Converted;     // meta theta_unit=2theta, data 1.0 → θ 0.5, Converted2Theta true
[Test] procedure LoadMeasurement_BadId_Raises;         // 'a/../b', 'noslash', 'a/b/c', 'a/b.exe'
[Test] procedure Decimate_KeepsEnds;                   // 1000 points, max 100 → ≤ 100, first and last kept
```
Tests create a temporary inbox (`WorkDir := TWorkDir.Create(temp)` global, restored in TearDown).

- [ ] **Step 2: Run (fail), implement, run (pass)**
- [ ] **Step 3: Verify inbox untouched**: after `list_measurements` + `get_measurement`, the SHA-256 of every inbox file is unchanged (assert in a test that lists SHA before/after).
- [ ] **Step 4: Commit** — `+ XRC_MCP: measurement inbox tools with curve parser and meta.json`

---

## Task 14: `.xrcx` project files

**Files:**
- Create: `XRC_MCP\units\unit_MCPProjectFile.pas`; `unit_ToolsFiles.pas` (project part)
- Test: `XRayCalc3\Tests\TestMCPProjectFile.pas` (needs `unit_XRCProjectTree` and VirtualTrees in the test build — add `..\Components` is already on the test search path; add `unit_XRCProjectTree in '..\Components\unit_XRCProjectTree.pas'` to the test dpr)
- Consumes: `unit_XRCProjectTree.TXRCProjectTree`, `unit_Types.TProjectData` (variant record), `unit_consts` (`CURRENT_PROJECT_VERSION`, `PARAMETERS_FILE_NAME`, `PROJECT_FILE_NAME`), `unit_SeriesIO` text format, `System.Zip`.

**Interfaces:**
- Produces:

```pascal
type
  TXRCXCalcParams = record        // what params.dsc stores; defaults = CreateDefaultProject + SaveToINI defaults
    Lambda: Double;               // [ANGLE] lambbda   (sic — the GUI key is misspelled; keep it)
    ThetaStart, ThetaEnd: Double; // [ANGLE] Start/End, written in θ; [ANGLE] 2teta=0
    Width: Double;                // [ANGLE] width (convolution)
    Points: Integer;              // [PARAMS] N
    Polarisation: Integer;        // [PARAMS] Polarisation 0=s 1=sp
    MinLimit: Double;             // [PARAMS] MinLimit
    FitMode: Integer;             // [FIT] Mode 0 irregular 1 periodic 2 poly
    FitIter, FitPop: Integer;     // [FIT] Namx / Pop
    PolyOrder: Integer;           // [FIT] PolyOrder
    PWChi: Boolean; TWChi: Integer; Tol, Window: Double;   // [FIT]
    LFPSO: TFitParams;            // [LFPSO] Vmax,Jmax,RIMax,kChi,kVmax,w1,w2,AdaptV,Constriction,SmoothWindow,Ksxr,PolyFactor,Shake,SeedRange,Smooth
  end;

  TXRCXProfileExt = record StackID, LayerID: Integer; Subj: TParameterType; Coeffs: TArray<Single>; end; // C[0..order]

  TXRCXProject = record
    Params: TXRCXCalcParams;
    ModelTitle: string;
    XRCData: string;               // GUI structure data string
    Extensions: TArray<TXRCXProfileExt>;
    CalcCurve: unit_Types.TDataArray;   // calc.dat
    DataTitle: string;             // '' = no data node
    DataCurve: unit_Types.TDataArray;   // data_<id>.dat, θ
    Version: Integer;              // read
  end;

function DefaultCalcParams: TXRCXCalcParams;
procedure WriteXRCX(const Path: string; const P: TXRCXProject);   // builds a temp dir, params.dsc, project.dsc, calc.dat, data_2.dat, zips
function ReadXRCX(const Path: string): TXRCXProject;              // unzips to temp, reads params.dsc, loads project.dsc with TXRCProjectTree, reads curves
```

`WriteXRCX` details:
- Temp dir `TPath.Combine(TPath.GetTempPath, 'xrcmcp_' + GUID)`, removed in `finally`.
- `params.dsc` via `TMemIniFile`, exactly the keys of `TfrmCalcSettings.SaveToINI`, `TfrmChartInfo.SaveToINI`, `SaveAdvancedParams` plus `[INFO] Version=7`, `[STATE] ActiveModel=1`, `[STATE] LinkedData=2` (only when a data curve is present), `[STATE] LogScale=1`; float formatting with `TFormatSettings.Invariant` (`INF.WriteString(..., FloatToStr(V, Invariant))`), `2teta=0`.
- `project.dsc`: `Tree := TXRCProjectTree.Create(nil, 96); Tree.NodeDataSize := SizeOf(TProjectData);` root nodes exactly as `CreateDefaultProject`: `Models` group (`Group gtModel, RowType prGroup, Title 'Models'`) with child model item (`ID 1, Title ModelTitle, Group gtModel, RowType prItem, Active True, Visible True, Color clRed ($0000FF), Data := XRCData`) and, per extension, a child of the model (`RowType prExtension, Group gtModel, Enabled True, ExtType etFunction, Form ffPoly, Subj, StackID, LayerID, SetPoly(coeffs)` — `TProjectData.SetPoly` takes `C[0..order]`, `PolyCount := order`); `Data` group (`Group gtData, RowType prGroup, Title 'Data'`) with an optional data item (`ID 2, Title DataTitle, Group gtData, RowType prItem, Active True, Visible True, Color clBlue`). `Tree.Expanded[...] := True` is irrelevant for the file. `Tree.SaveToFile(project.dsc)`; free the tree. Zero the record before filling (`FillChar(PD^, SizeOf(TProjectData), 0)` is NOT allowed on a record with managed strings — instead assign every field explicitly; the tree allocates zeroed node data already).
- `calc.dat`: header `2Theta<TAB>Reflectivity`, `deg<TAB>`, blank, then `FloatToStrF(x, ffFixed, 5, 3) + #9 + FloatToStrF(y, ffExponent, 5, 4)` with invariant settings (the GUI reads with `SeriesFromText`, so the header text does not matter, only that the first token is non-numeric). `data_2.dat` same format with header `Theta<TAB>Intensity`.
- Zip with `TZipFile.ZipDirectoryContents(Path, TempDir)` — verify the entries have no directory prefix (Abbrevia's `BaseDirectory` + `*.*` gives flat names); if `ZipDirectoryContents` prefixes, add files one by one with `TZipFile.Add(FileName, ArchiveName)`.

`ReadXRCX`: `TZipFile.ExtractZipFile(Path, TempDir)`; `params.dsc` via `TMemIniFile` (read what `LoadFromINI`/`LoadAdvancedParams` read, same defaults); `Tree.LoadFromFile(project.dsc)` with `Tree.Version := INF.ReadInteger('INFO','Version',0)` set BEFORE loading (`ProjectLoadNode` switches on it); walk `Tree.GetFirst/GetNext`, pick the model item whose `ID = [STATE] ActiveModel` (or the first), its `Data`, its extension children, the data item whose `ID = LinkedData` (or the first) → `data_<ID>.dat`; `calc.dat` if present. Old projects with `model_N.bin` (`Data = ''`) → `EMCPError('unsupported_project', 'model stored in legacy binary format; open and re-save in XRayCalc3')`.

Tools:
- `save_project {structure, name, curves?: {measurement_id?: string, job_id?: string}, note?, overwrite?: false, lambda?, theta_min?, theta_max?, points?, delta_theta?}` → writes `projects\<name>.xrcx` (name: `[A-Za-z0-9_\-. ()#]+`, no path separators, `.xrcx` appended if missing), `ModelTitle := name`, `Description := note` (set `PD.Description`), calc curve computed with Task 7 `RunCalc` (so the file opens with a curve), data curve from the measurement (θ) or from `jobs\<job_id>\measured.dat`; result `{"file","sha256","size","version":7,"lambda_used"}`; existing file and not `overwrite` → `already_exists`.
- `load_project {name | path}` → `{"file","version","model_title","structure":<§3 JSON>,"profiles":[{stack,layer,parameter,coefficients}],"calc_params":{lambda,theta_start,theta_end,width,points,polarisation},"curves":{"calc_points":n,"data_points":n,"data_title"},"sha256"}`.
- `list_projects {}` → `{"projects":[{"name","file","size","sha256","modified_utc"}]}`.

- [ ] **Step 1: Test (headless tree spike first — this is the risk of the task)**

```pascal
[Test] procedure HeadlessTree_SaveLoad_RoundTrip;   // TXRCProjectTree.Create(nil,96), NodeDataSize, 2 groups + model item with Data='{"Stacks":[],"Subs":{"M":"Si","s":1,"r":2.33}}', SaveToFile, new tree LoadFromFile, walk, assert titles/Data equal
[Test] procedure WriteXRCX_ContainsExpectedEntries;  // zip has params.dsc, project.dsc, calc.dat, data_2.dat
[Test] procedure WriteXRCX_ParamsVersion7_ThetaNot2Theta;
[Test] procedure ReadXRCX_RoundTrip_Structure;       // XRCData equal after write+read, extensions equal
[Test] procedure ReadXRCX_SampleFromELNPlugins;      // if D:\APS\ELN\ELN3Plugins\TestFiles\Hard.xrcx exists: Version=7, XRCData contains '"Stacks"', CalcCurve non-empty; else Assert.Pass
```

If `HeadlessTree_SaveLoad_RoundTrip` cannot be made to pass (exception from VirtualTrees without a window), implement the writer from Appendix A instead, keep the reader on the tree (`LoadFromFile` needs the same object; if that also fails, port the ELN plugin's byte scanner `unit_XRCExtensionParser.pas` + the UTF-16 JSON scan from `frame_XRCViewer.LoadModelStructure`), and record the outcome in the design note.

- [ ] **Step 2: Run (fail), implement, run (pass)**
- [ ] **Step 3: GUI check (author or you, if the GUI can be launched)**: `save_project` the Ru/C structure, open `projects\ruc.xrcx` in `_Out\BIN\XRayCalc3.exe`, press calculate; the curve must be the file's `calc.dat` curve. Record the result in the commit message.
- [ ] **Step 4: Commit** — `+ XRC_MCP: save_project / load_project / list_projects writing GUI-compatible .xrcx (v7)`

---

## Task 15: `fit_xrr` job

**Files:**
- Create: `XRC_MCP\units\unit_MCPFit.pas`; extend `unit_ToolsJobs.pas`
- Consumes: Task 12 API, `TLFPSO_Periodic`, `TLFPSO_Poly`, `unit_Types.TFitParams`, `unit_DataProcessing.MovAvg`, Task 14 `WriteXRCX`, Task 7 `RunCalc`/`WriteCurveFile`.

Tool args:

```
measurement_id | curve ([[θ,I],...]; requires lambda), lambda|energy (required with curve; with measurement_id defaults to meta.lambda),
structure (start model), theta_range {min,max} (default: data range), resolution (θ FWHM deg, default 0.015),
free: [ {"target":"layer","stack":k,"layer":j,"parameters":["thickness","sigma","density"]}, {"target":"substrate","parameters":["sigma","density"]} ]
bounds: [ {"target":"layer","stack":k,"layer":j,"parameter":"thickness","min":..,"max":..}, ... ]  (default ±30 % of the start value; density and sigma clamp min ≥ 0)
optimizer: {population (default 100), iterations (default 100), tolerance (0.005), shake (true), range_seed (true), jamming_max 1, reinit_max 3, k_chi 1.41, k_vmax 1.41, w1 0.3, w2 0.3, vmax 0.3, adapt_velocity false, use_constriction true, ksxr 0.2, poly_factor 10, poly_order 1}
chi2: {theta_weight 0..5 (0), point_weight (true), movavg_window (0.05)}
profile: false | true (uses TLFPSO_Poly with poly_order; requires a periodic stack)
polarization: s|sp (sp), seed, r_min (1e-7), points_inline_max (2000)
```

`stack`/`layer` indices refer to the §3 JSON: `stack` = index in `stacks` (substrate→surface), `layer` = index in that stack's `layers`; `"stack":"cap"` and `"stack":"buffer"` address those layers. The adapter converts to the GUI indices through `TStructureInfo` (keep a map `JSONStackIndex → GUI stack index` in `TStructureInfo`: add field `StackMap: TArray<Integer>` in Task 5 — do it now if it was not done).

Body (`RunFitJob`), mirroring `TCalcOrchestrator.PrepareLFPSO`/`RunFitting`/`FinalizeFitting` without UI:
1. `RandSeed` not needed (LFPSO seeds itself from `Seed`).
2. Load data: measurement (Task 13, `MaxPoints 0`) or inline curve; restrict to `theta_range`; write `jobs\<id>\measured.dat`.
3. `FS := StructureFromJSON(structure, Info)`; apply `free`/`bounds`: for each free parameter set `P[p].min/max` from bounds or ±30 %; every non-free parameter keeps `min = max = V` (the engine then has zero range → fixed: `Xrange = 0` → `Rand(0) = 0` in `TLFPSO_Periodic.XSeed`, and `CheckLimits` clamps to `[Xmin, Xmax]`). The substrate is not in the particle vector (`TLFPSO_BASE.FillModel` copies `FStructure.Subs.P` verbatim), so `target=substrate`, `scale`, `background` and `resolution` inside `free` are refused with `not_fittable` (design note §4).
4. `CalcParams`: `Mode cmTheta; Lambda; StartT/EndT = theta_range; DT = resolution; N = number of data points (the engine uses the data θ points when ExpValues is set — confirm in TCalc.PrepareWorkers/UseData); K 1; P; RF rfError; MVAWindow 10`.
5. `FitParams` from `optimizer`/`chi2` (`ThetaWeight := chi2.theta_weight`, `MovAvgWindow`, `NMax := iterations`, `Pop := population`, `MaxPOrder := poly_order`, `Smooth False`, `SmoothWindow -1`).
6. `if profile then L := TLFPSO_Poly.Create else L := TLFPSO_Periodic.Create;` `L.Seed := Job.Seed; L.Params := FitParams; L.Limit := r_min; L.ExpValues := Data; if point_weight then L.MovAvg := MovAvg(Data, MovAvgWindow); L.Structure := FS; L.OnProgress := handler` — handler: `Job.Progress(Msg.Step, Msg.BestChi, Format('chi2 %.4g, diversity %.3f', [..]))`, free `Msg.LayeredModel` when assigned, and `if Job.CancelRequested then L.Terminate`.
7. `L.Run(CalcParams)` (synchronously on the worker thread — `Run` uses `Parallel.For` internally and drains its own message queue; fine on a non-main thread as the GUI already does this in `TFittingThread`).
8. Result: `FittedFS := L.Structure` (updated by `UpdateStructure(abest)`), `Poly := L.Polynomes` (profile mode), `Model := L.Result` (expanded `TLayeredModel`; per-period thickness from `Model.LayersDirect[i].L` grouped by `StackIDs/LayerIDs`).
   - `chi2 := L.BestChiSquare`; recompute the final curve with `RunCalc` on `FittedFS` at the data θ points? `RunCalc` uses a uniform grid; instead build `TCalc` with `ExpValues := Data` exactly like step 4–5 and `Model := L.Result` so the calculated curve is on the measured points; `chi2_recalc := Calc.CalcChiSquare(ThetaWeight)`; report both (they must agree; if not, `consistency_warning`).
   - Write `calc.dat` (θ, R), `residual.dat` (θ, log10 I − log10 R), `measured.dat` (already).
   - `.xrcx`: `WriteXRCX(jobs\<id>\fit.xrcx, P)` with `Params` (lambda, θ range, width = resolution, points = data count, polarisation, MinLimit r_min, FitMode 1 or 2, FitIter/Pop, PolyOrder, PWChi, TWChi, Tol, Window, LFPSO from FitParams), `XRCData := StructureToXRCData(FittedFS, Info)` (with min/max as used), `Extensions` from `Poly` (`Coeffs := Rec.C`, `StackID/LayerID` are the GUI indices already), `CalcCurve`, `DataTitle := measurement id or 'inline'`, `DataCurve := Data`.
9. `ResultObj`:

```json
{"job_id","seed","chi2","chi2_recalc","chi2_definition":<describe_server.fit.chi2 text>,"chi2_settings":{theta_weight,point_weight,movavg_window},
 "iterations_run","elapsed_s","lambda_used","theta_range":[..],"resolution_deg","polarization","engine":"TLFPSO_Periodic"|"TLFPSO_Poly",
 "start_structure":<§3>,"fitted_structure":<§3 with "thickness_profile":[..] per layer when profile>,"bounds_used":[...],
 "profiles":[{"stack","layer","parameter","coefficients":[..]}],
 "files":{"xrcx":"jobs\\fit-…\\fit.xrcx","measured":"…\\measured.dat","calculated":"…\\calc.dat","residual":"…\\residual.dat"},
 "measured":[[θ,I]]|null,"calculated":[[θ,R]]|null,"residual":[[θ,r]]|null,
 "scale":1.0,"background":0.0,"note":"scale and background are not fitted by the GUI engine (v1)"}
```

- [ ] **Step 1: Implement**
- [ ] **Step 2: Verify**

Create `inbox\S1\meta.json` `{"lambda":1.5406,"date":"2026-09-09","instrument":"test","theta_unit":"theta"}` and `inbox\S1\xrr.dat` from a `calc_reflectivity` curve of the Ru/C structure with `delta_theta 0.015` (copy `curve.dat`; Task 13's parser accepts it). Run `fit_xrr` with the start model perturbed (Ru 13.5 / C 55.0), free thickness of both layers, `population 30, iterations 20, seed 7`. Expected: `finished`, `chi2` decreases below the start χ² (report both: compute the start χ² by a `TCalc` run on the start model — add `"chi2_start"` to the result), `fit.xrcx` exists, `job_status` during the run shows increasing `iteration`. Run twice with `seed 7`: identical `chi2` and structure. `cancel_job` on a running fit (population 200, iterations 500) → state `cancelled` within a few seconds.

Author's acceptance 4: open `fit.xrcx` in XRayCalc3 → the curve and χ² shown equal the result's `chi2` (χ² display uses the same `CalcChiSquare`).

- [ ] **Step 3: Commit** — `+ XRC_MCP: fit_xrr job on the GUI LFPSO with seed, bounds, profiles and .xrcx output`

---

## Task 16: End-to-end session, docs, handoff

**Files:**
- Create: `XRC_MCP\smoke\session.ps1` (pipes a full session — every tool once — into the exe against a temp workdir and checks: 16 journal lines, inbox SHA unchanged, `path_outside_workdir` returned for `{"name":"load_project","arguments":{"path":"..\\..\\x.xrcx"}}`)
- Modify: `docs/superpowers/specs/2026-09-09-xrc-mcp-design.md` (record deviations found during implementation), `CLAUDE.md` (registration line from requirements §7), `_Installer/XRayCalc3Setup.iss` — NOT modified (out of scope; note it).

- [x] **Step 1: Write and run `session.ps1`**; fix anything it finds.
      `XRC_MCP\smoke\session.ps1` drives one live stdio session (16 tools, 32 `tools/call`
      requests including job polls) against a temp work directory and exits 0. Run of
      2026-09-09 against `_Out\BIN\XRC_MCP.exe` git `9d6fcee`: `PASS`, 4 s wall clock.
      It found no server defect — no server code was changed for it.
- [x] **Step 2: Acceptance checklist in the plan (tick with evidence)**
  1. [x] `tools/list` names: describe_server, list_materials, optical_constants, list_templates, calc_reflectivity, evaluate_lines, optimize_mirror, job_status, job_result, cancel_job, fit_xrr, list_measurements, get_measurement, save_project, load_project, list_projects — 16 tools; every numeric property description mentions its unit.
     *Evidence:* `session.ps1` asserts the set: `[1/16] tools/list : 16 tools, all expected
     names present` (no missing, no extra). Units: a sweep of every `"type":"number"` property
     in the schemas leaves 29 without a unit word, and all 29 are either dimensionless
     (weights `w_R`/`w_FWHM`/`w_purity`/`weight`, PSO `w1`/`w2`/`k_chi`/`k_vmax`, `tolerance`,
     `r_min` and `R_min_threshold`, which are reflectivities) or take the unit from the
     object that encloses them (`structure.d/gamma/N` `.min`/`.max` under "Period thickness in
     Angstrom", `bounds[].max` beside a `min` that says "in Angstrom or g/cm^3").
  2. [x] Ru/C curve — first Bragg peak at 0.687° (refraction-corrected; the Bragg-law estimate 0.644° is not what the engine gives), `.xrcx` opens in GUI (author).
     *Evidence:* `calc_reflectivity`, λ 1.5406 Å, 0.1–4°, 2000 points → first peak
     **0.685293°**, R 0.842592, θ_c 0.477043°; on a 40000-point grid the same peak is
     **0.685795°**, so 0.6858° is the engine's value and the grid, not the physics, accounts
     for the difference. Both are inside the 0.687° ± 0.01 the script asserts. GUI-open check
     reported by Task 14/15 implementers; author to confirm.
  3. [x] Same seed → same FoM (two runs).
     *Evidence:* two `optimize_mirror` jobs, seed 12345, lines Al+Si, pool W/Si/B4C/Sc/C/Mo,
     population 20 × 3 iterations → **fom = 0.180236** both times, same genome
     (d = 33.9438 Å, γ = 0.214677, N = 49). Task 11 saw the same on its larger configuration
     (fom −1.3279 twice).
  4. [x] Same seed → same χ²; `.xrcx` opens (author).
     *Evidence:* two `fit_xrr` jobs, seed 7, start model Ru 13.5 / C 55.0 against
     `inbox\S1\xrr.dat`, population 20 × 5 iterations, tolerance 1e-9 so the whole budget is
     used → **χ² = 0.000187058** both times (start χ² 5.85037, 5 iterations run) and a
     byte-identical `fitted_structure`. `fit.xrcx` written for both. GUI-open check reported
     by Task 14/15 implementers; author to confirm.
  5. [x] Outside path refused; inbox SHA unchanged.
     *Evidence:* `load_project {"path":"..\\..\\x.xrcx"}` → `isError`, code
     **`path_outside_workdir`**. `inbox\S1` SHA-256 before and after the session:
     `xrr.dat 76091C3F…4B1`, `meta.json E5BBFCAA…93D` — identical.
  6. [x] Journal has one line per call.
     *Evidence:* `log\calls.jsonl` holds **32 lines carrying a `tool` key for the 32
     `tools/call` requests sent**, plus 5 `event: job` lifecycle lines (37 total), and all 16
     tool names appear. The script asserts the tool-line count against its own request counter.
  7. [x] Test units present and passing.
     *Evidence:* 12 MCP test units (`TestMCPCalc`, `…Fit`, `…Inbox`, `…Jobs`, `…Journal`,
     `…Materials`, `…ProjectFile`, `…Sandbox`, `…Structure`, `…Units`, `…Universal`,
     `…UniversalJob`) in `XRayCalc3\Tests\`. Win32 Debug run of 2026-09-09:
     **494 found, 494 passed, 0 failed, 0 errored, 0 leaked.**
- [x] **Step 3: Write the open-questions list for the author** into `docs/superpowers/specs/2026-09-09-xrc-mcp-design.md` §8 (already drafted; append anything new, e.g. the substrate-not-fittable finding and the XRFCalc seed comparison).
      §8 items 7–13 added; item 6's stale "`_Out\BIN\XRayCalc3.exe` is a Win32 binary" sentence
      corrected. `_Installer\XRayCalc3Setup.iss` deliberately not modified (noted in §8.14).
- [x] **Step 4: Commit** — `+ XRC_MCP: end-to-end smoke session script; design note updated with implementation findings`

---

## Appendix A — `project.dsc` byte layout (fallback writer only)

VirtualTreeView 8.x stream, little-endian, verified against `D:\APS\ELN\ELN3Plugins\TestFiles\Hard.xrcx`:

```
MagicID      12 bytes: WideChars #$2045 'V' 'T' #$0003 ' ' #$2046   (bytes 45 20 56 00 54 00 03 00 20 00 46 20)
Count        Cardinal: number of top-level nodes (2: Models, Data)
per node:
  NodeChunk  Header {ChunkType=1, ChunkSize=Int32 bytes after header}
    BaseChunk Header {ChunkType=2, ChunkSize}
      Body: ChildCount Cardinal | NodeHeight Int32 (any, e.g. 25) | States Cardinal (0xE1 for an expanded, visible, initialized node with children; 0x61 for a leaf) | Align Byte 50 | CheckState Byte 0 | CheckType Byte 0 | Reserved Cardinal 0
      child NodeChunks follow inside the BaseChunk (children are inside the parent's base chunk; FinishChunkHeader patches sizes)
    UserChunk Header {ChunkType=4, ChunkSize} payload = TXRCProjectTree.ProjectSaveNode:
      ID Int32 | Title (Int32 size, UTF-16LE bytes + 1 zero byte) | RowType Byte | Group Byte | Active Byte | Visible Byte | Description (len-str) | Color Int32 |
      Enabled Byte | ExtType Byte | LayerID Int32 | StackID Int32 | Form Byte | Subj Byte |
      [Group=gtModel & RowType=prExtension: Order Int32, Order × Single] |
      [Group=gtModel & RowType=prItem: Data (len-str)]
```

Enum encodings (1 byte): RowType 0 prGroup, 1 prItem, 2 prFolder, 3 prExtension; Group 0 gtModel, 1 gtData; ExtType 0 etNone, 1 etFunction, 2 etTable, 3 etRough; Form 0 ffNone, 1 ffPoly, 2 ffExp, 3 ffParabolic, 4 ffSQRT; Subj 0 ptH, 1 ptS, 2 ptRho. `ProjectLoadNode` (v6/7) reads the same fields in the same order. `States` bit positions follow `TVirtualNodeState` declaration order in `VirtualTrees.Types.pas` (vsInitialized = bit 0); confirm 0xE1/0x61 against the sample before relying on them.
