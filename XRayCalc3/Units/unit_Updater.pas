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

unit unit_Updater;

(* Help - Check for update: the latest GitHub release, and its setup downloaded
   and checked against the SHA-256 GitHub records for the asset. Network calls
   block; the caller runs them off the main thread. The installer itself is run
   by the main form, which has to close first. *)

interface

type
  TReleaseInfo = record
    Version: string;    // the tag without a leading 'v', e.g. 3.10.0
    PageURL: string;    // the release page on GitHub
    SetupName: string;  // '' when the release carries no setup
    SetupURL: string;
    Sha256: string;     // hex; '' when GitHub gives no digest
  end;

/// Reads a GitHub /releases/latest response. Raises when it is not one.
function ParseRelease(const Json: string): TReleaseInfo;

/// True when Remote is a later version than Local. Both are dotted numbers
/// (a leading 'v' is ignored); only the first three parts count, so a build
/// number never makes an update.
function IsNewer(const Remote, Local: string): Boolean;

/// Fetches and parses the latest release. Raises on any network error.
function FetchLatestRelease(const URL: string): TReleaseInfo;

/// Downloads the setup to the temp directory and returns its path. Raises,
/// deleting the file, when its SHA-256 differs from the one GitHub records.
function DownloadSetup(const Info: TReleaseInfo): string;

implementation

uses
  System.SysUtils, System.Classes, System.JSON, System.Hash, System.IOUtils,
  System.NetConsts, System.Net.URLClient, System.Net.HttpClient;

const
  TIMEOUT_MS = 15000;
  SETUP_PREFIX = 'XRayCalc3_Setup';

function StripV(const S: string): string;
begin
  Result := S.Trim;
  if Result.StartsWith('v', True) then
    Delete(Result, 1, 1);
end;

function ParseRelease(const Json: string): TReleaseInfo;
var
  Root: TJSONValue;
  Assets: TJSONArray;
  Asset: TJSONValue;
  Name, Digest: string;
begin
  Result := Default(TReleaseInfo);
  Root := TJSONObject.ParseJSONValue(Json);
  try
    if not (Root is TJSONObject) then
      raise Exception.Create('The update server did not return a release.');
    Result.Version := StripV(Root.GetValue<string>('tag_name', ''));
    if Result.Version = '' then
      raise Exception.Create('The update server did not return a release.');
    Result.PageURL := Root.GetValue<string>('html_url', '');

    if Root.TryGetValue<TJSONArray>('assets', Assets) then
      for Asset in Assets do
      begin
        Name := Asset.GetValue<string>('name', '');
        if Name.StartsWith(SETUP_PREFIX, True) and Name.EndsWith('.exe', True) then
        begin
          Result.SetupName := Name;
          Result.SetupURL := Asset.GetValue<string>('browser_download_url', '');
          Digest := Asset.GetValue<string>('digest', '');
          if Digest.StartsWith('sha256:', True) then
            Result.Sha256 := Copy(Digest, 8, MaxInt);
          Break;
        end;
      end;
  finally
    Root.Free;
  end;
end;

function IsNewer(const Remote, Local: string): Boolean;
var
  R, L: TArray<string>;
  i, a, b: Integer;
begin
  R := StripV(Remote).Split(['.']);
  L := StripV(Local).Split(['.']);
  for i := 0 to 2 do
  begin
    if i < Length(R) then a := StrToIntDef(R[i], 0) else a := 0;
    if i < Length(L) then b := StrToIntDef(L[i], 0) else b := 0;
    if a <> b then
      Exit(a > b);
  end;
  Result := False;
end;

{ Without a proxy of its own the client takes the Windows (Internet Options)
  one. Where GitHub is reachable only through a local proxy named in
  HTTPS_PROXY / HTTP_PROXY (the lab's machines), the API may still answer
  directly while the setup download times out, so those win. }
function NewClient: THTTPClient;
var
  Proxy: string;
begin
  Result := THTTPClient.Create;
  Proxy := GetEnvironmentVariable('HTTPS_PROXY');
  if Proxy = '' then
    Proxy := GetEnvironmentVariable('HTTP_PROXY');
  if Proxy <> '' then
    Result.ProxySettings := TProxySettings.Create(Proxy);
  Result.ConnectionTimeout := TIMEOUT_MS;
  Result.ResponseTimeout := TIMEOUT_MS;
  Result.UserAgent := 'XRayCalc3-Updater';
end;

function FetchLatestRelease(const URL: string): TReleaseInfo;
var
  Client: THTTPClient;
  Resp: IHTTPResponse;
begin
  Client := NewClient;
  try
    Client.Accept := 'application/vnd.github+json';
    Resp := Client.Get(URL);
    if Resp.StatusCode <> 200 then
      raise Exception.CreateFmt('The update server answered %d %s.',
        [Resp.StatusCode, Resp.StatusText]);
    Result := ParseRelease(Resp.ContentAsString(TEncoding.UTF8));
    Resp := nil;
  finally
    Client.Free;
  end;
end;

function DownloadSetup(const Info: TReleaseInfo): string;
var
  Client: THTTPClient;
  Stream: TFileStream;
  Resp: IHTTPResponse;
  Error, Hash: string;
begin
  if Info.SetupURL = '' then
    raise Exception.Create('This release has no setup to download.');
  Result := TPath.Combine(TPath.GetTempPath, Info.SetupName);
  Error := '';
  Client := NewClient;
  try
    Client.ResponseTimeout := 10 * 60 * 1000;   // the setup is ~11 MB
    Stream := TFileStream.Create(Result, fmCreate);
    try
      try
        Resp := Client.Get(Info.SetupURL, Stream);
        if Resp.StatusCode <> 200 then
          Error := Format('The download failed: %d %s.', [Resp.StatusCode, Resp.StatusText]);
        Resp := nil;
      except
        on E: Exception do
          Error := 'The download failed: ' + E.Message;
      end;
    finally
      Stream.Free;
    end;
  finally
    Client.Free;
  end;

  if Error <> '' then
  begin
    System.SysUtils.DeleteFile(Result);
    raise Exception.Create(Error);
  end;

  // ponytail: a release without a GitHub digest installs unchecked; GitHub records one for every asset since 2025
  if Info.Sha256 <> '' then
  begin
    Hash := THashSHA2.GetHashStringFromFile(Result);
    if not SameText(Hash, Info.Sha256) then
    begin
      System.SysUtils.DeleteFile(Result);
      raise Exception.Create('The downloaded setup is damaged (its SHA-256 differs from the release''s). Nothing was installed.');
    end;
  end;
end;

end.
