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

unit unit_UncertSession;

(* One project open in the uncertainty tool: the request built from it or the
   reason there is none, its raw counts, the known values and the stored
   result, whether that result still belongs to the project, and the two
   things the tool writes back. The window holds one of these and draws it.
   No VCL. *)

interface

uses
  System.SysUtils, unit_Types, unit_MCPProjectFile, unit_UncertRequest, unit_UncertRun;

type
  TUncertSession = record
    FileName: string;
    Project: TXRCXProject;
    Refusal: string;                 // '' or why this project cannot be analysed
    Request: TUncertRequest;         // valid when Refusal = ''
    Counts: TArray<Double>;          // nil: none
    CountsNote: string;              // '' or the plain sentence saying there are none, and why
    Priors: TArray<TUncertPrior>;
    HasResult: Boolean;
    Result: TUncertResult;
    OutOfDate: Boolean;              // the result was made for another model, curve, counts or known values
    StoredFingerprint: string;       // what the result was made for
    EntryNote: string;               // '' or what to know about the entry found in the project
  end;

const
  MSG_OUT_OF_DATE = 'The model, the curve or the known values have changed since this result ' +
    'was made. Run again.';
  MSG_OTHER_VERSION = 'The project holds uncertainties stored by another version of this tool, ' +
    'which this one cannot read. Running, or entering a known value, replaces them.';
  MSG_NO_COUNTS ='No raw counts were found: the errors rely on the estimated noise only.';

/// <summary>'' and the session, or one plain sentence when the file cannot
/// be opened at all (not found, not a project, a newer project). A project
/// that opens but cannot be analysed is a session with Refusal set.</summary>
function OpenSession(const FileName: string; out S: TUncertSession): string;
/// <summary>Replaces S.Priors and stores them, with the stored result if
/// there is one. '' or a plain sentence; S is unchanged when it fails.</summary>
function StorePriors(var S: TUncertSession; const Priors: TArray<TUncertPrior>): string;
/// <summary>Takes a settled result into S and stores it with the counts.
/// '' or a plain sentence; S holds the result either way.</summary>
function StoreResult(var S: TUncertSession; const Res: TUncertResult): string;
/// <summary>The lines under the list, in order: the refusal alone; else out
/// of date, the misfit, the counts note, the result's message and warnings.</summary>
function SessionWarnings(const S: TUncertSession): TArray<string>;

implementation

uses
  unit_ParamMap, unit_ProjectVersion, unit_UncertCounts, unit_UncertFiles;

{ The known values that still name something of this request. }
function PriorsThatApply(const Priors: TArray<TUncertPrior>; const Req: TUncertRequest): TArray<TUncertPrior>;
var
  i, k: Integer;
begin
  Result := nil;
  for i := 0 to High(Priors) do
    for k := 0 to High(Req.Names) do
      if (Req.Names[k].Name = Priors[i].Name) and Req.Names[k].CanHavePrior then
      begin
        Result := Result + [Priors[i]];
        Break;
      end;
end;

function SameNames(const Stored: TStoredUncert; const Req: TUncertRequest): Boolean;
var
  k: Integer;
begin
  Result := (Length(Stored.Names) = Length(Req.Names)) and
    (Length(Stored.Result.Values) = Length(Req.Names));
  if Result then
    for k := 0 to High(Req.Names) do
      if Stored.Names[k].Name <> Req.Names[k].Name then
        Exit(False);
end;

procedure FindCounts(var S: TUncertSession);
var
  Text, Why: string;
begin
  Why := '';
  S.Counts := nil;
  if ReadEntry(S.FileName, CountsEntryName(S.Project.DataID), Text) then
    S.Counts := CountsFromText(Text, S.Project.DataCurve, Why);
  if S.Counts = nil then
    S.Counts := CountsFromSource(SourceFileOf(S.Project.DataNote), S.Project.DataCurve,
      S.Project.TwoTheta, Why);
  if S.Counts = nil then
    S.CountsNote := Trim(MSG_NO_COUNTS + ' ' + Why);
end;

function OpenSession(const FileName: string; out S: TUncertSession): string;
var
  Text, Why: string;
  Stored: TStoredUncert;
  HasStored: Boolean;
  Map: TParamMap;
begin
  Result := '';
  S := Default(TUncertSession);
  S.FileName := FileName;
  if not FileExists(FileName) then
    Exit(Format('The project file %s was not found.', [FileName]));
  if not CheckProjectFile(FileName, Why) then
    Exit(Why);
  try
    S.Project := ReadXRCX(FileName);
  except
    on E: Exception do
      Exit(Format('%s is not an X-Ray Calc project: %s', [ExtractFileName(FileName), E.Message]));
  end;

  HasStored := False;
  if ReadEntry(FileName, UncertEntryName(S.Project.ModelID), Text) then
  begin
    HasStored := StoredFromJSON(Text, Stored);
    if HasStored then
      S.Priors := Stored.Priors
    else
      S.EntryNote := MSG_OTHER_VERSION;
  end;

  S.Refusal := BuildRequest(S.Project, S.Request);
  if S.Refusal <> '' then
    Exit;
  S.Priors := PriorsThatApply(S.Priors, S.Request);
  try
    Map := BuildMap(S.Request, S.Priors);
    try
      S.Refusal := StartProblem(Map, S.Request);
    finally
      Map.Free;
    end;
  except
    on E: EParamMap do
      S.Refusal := 'The model cannot be analysed: ' + E.Message;
  end;
  if S.Refusal <> '' then
    Exit;

  FindCounts(S);
  if HasStored and Stored.HasResult and SameNames(Stored, S.Request) then
  begin
    S.HasResult := True;
    S.Result := Stored.Result;
    S.StoredFingerprint := Stored.Fingerprint;
    S.OutOfDate := S.StoredFingerprint <> Fingerprint(S.Project, S.Counts, S.Priors);
  end;
end;

function WriteSession(const S: TUncertSession; WithCounts: Boolean): string;
var
  Stored: TStoredUncert;
  Names, Texts: TArray<string>;
begin
  Stored := Default(TStoredUncert);
  Stored.Fingerprint := S.StoredFingerprint;
  Stored.Priors := S.Priors;
  Stored.HasResult := S.HasResult;
  Stored.Result := S.Result;
  Stored.Names := S.Request.Names;
  Names := [UncertEntryName(S.Project.ModelID)];
  Texts := [StoredToJSON(Stored)];
  if WithCounts and (S.Counts <> nil) then
  begin
    Names := Names + [CountsEntryName(S.Project.DataID)];
    Texts := Texts + [CountsToText(S.Counts, S.Project.DataCurve)];
  end;
  Result := WriteEntries(S.FileName, Names, Texts);
end;

function StorePriors(var S: TUncertSession; const Priors: TArray<TUncertPrior>): string;
var
  T: TUncertSession;
begin
  if S.Refusal = '' then
    try
      BuildMap(S.Request, Priors).Free;
    except
      on E: EParamMap do
        Exit('A known value cannot be given for that parameter.');
    end;
  T := S;
  T.Priors := Priors;
  T.OutOfDate := T.HasResult and
    (T.StoredFingerprint <> Fingerprint(T.Project, T.Counts, T.Priors));
  Result := WriteSession(T, False);
  if Result = '' then
    S := T;
end;

function StoreResult(var S: TUncertSession; const Res: TUncertResult): string;
begin
  S.Result := Res;
  S.HasResult := True;
  S.OutOfDate := False;
  S.StoredFingerprint := Fingerprint(S.Project, S.Counts, S.Priors);
  Result := WriteSession(S, True);
end;

function SessionWarnings(const S: TUncertSession): TArray<string>;
var
  W: string;
  k: Integer;
begin
  Result := nil;
  if S.Refusal <> '' then
  begin
    Result := [S.Refusal];
    Exit;
  end;
  if S.EntryNote <> '' then
    Result := Result + [S.EntryNote];
  if S.HasResult and S.OutOfDate then
    Result := Result + [MSG_OUT_OF_DATE];
  { the misfit before everything it explains; from the stored values, so a
    result of any age says it }
  if S.HasResult and S.Result.Settled then
    for k := 0 to High(S.Result.Values) do
      if S.Result.Values[k].Name = 'c0.f' then
      begin
        W := MisfitWarning(S.Request.Data, S.Result.Values[k].P50);
        if W <> '' then
          Result := Result + [W + MISFIT_WIDENS];
      end;
  if S.CountsNote <> '' then
    Result := Result + [S.CountsNote];
  if not S.HasResult then
    Exit;
  if S.Result.Message <> '' then
    Result := Result + [S.Result.Message];
  for W in S.Result.Warnings do
    if (S.CountsNote = '') or (W <> WARN_NO_COUNTS) then
      Result := Result + [W];
end;

end.
