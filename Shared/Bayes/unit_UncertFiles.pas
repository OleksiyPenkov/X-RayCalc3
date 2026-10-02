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

unit unit_UncertFiles;

(* The uncertainty tool's own entries in a project archive:

     uncert_<model id>.json   the priors the user entered and the last result,
                              with a fingerprint of what the result was
                              computed from
     counts_<data id>.dat     the curve's raw counts, one per line

   The main program does not know these entries; it extracts every entry on
   open and zips every file back on save, so they travel with the project. The
   tool never rewrites anything else: WriteEntries copies every other entry's
   bytes into a new archive beside the project and swaps it in. The project's
   version stays what it was.

   A stored result whose fingerprint no longer matches the project is out of
   date: the model, the curve, the counts or the priors changed since. *)

interface

uses
  System.SysUtils, unit_Types, unit_MCPProjectFile, unit_UncertRequest, unit_UncertRun;

const
  UNCERT_FORMAT = 1;

type
  TStoredUncert = record
    Fingerprint: string;
    Priors: TArray<TUncertPrior>;    // kept even when nothing has been run yet
    HasResult: Boolean;
    Result: TUncertResult;
    Names: TArray<TUncertName>;      // what the result's values were called when it was made
  end;

function UncertEntryName(ModelID: Integer): string;
function CountsEntryName(DataID: Integer): string;

/// <summary>SHA-256, in hex, of what a result depends on: the model's
/// structure string, its profile coefficients and Table extension, the fit
/// mode and free-period settings, the curve's points, the counts, the
/// priors. Not the titles.</summary>
function Fingerprint(const P: TXRCXProject; const Counts: TArray<Double>;
  const Priors: TArray<TUncertPrior>): string;

function StoredToJSON(const S: TStoredUncert): string;
/// <summary>False, S empty, for text that is not this build's
/// uncert_&lt;id&gt;.json.</summary>
function StoredFromJSON(const Text: string; out S: TStoredUncert): Boolean;

/// <summary>Entry Name of the archive as text (UTF-8); False when the archive
/// or the entry is not there.</summary>
function ReadEntry(const ProjectFile, Name: string; out Text: string): Boolean;
/// <summary>Adds or replaces the named entries and leaves every other entry's
/// bytes as they were. '' or a plain sentence; the project is untouched when
/// it fails.</summary>
function WriteEntries(const ProjectFile: string; const Names, Texts: TArray<string>): string;

implementation

uses
  Winapi.Windows, System.Classes, System.Math, System.IOUtils, System.JSON, System.Hash,
  System.Zip, System.Generics.Collections;

function UncertEntryName(ModelID: Integer): string;
begin
  Result := Format('uncert_%d.json', [ModelID]);
end;

function CountsEntryName(DataID: Integer): string;
begin
  Result := Format('counts_%d.dat', [DataID]);
end;

{ ------------------------------------------------------------ fingerprint -- }

function Num(V: Double): string;
begin
  Result := FloatToStrF(V, ffGeneral, 17, 0, TFormatSettings.Invariant);
end;

function Fingerprint(const P: TXRCXProject; const Counts: TArray<Double>;
  const Priors: TArray<TUncertPrior>): string;
var
  SB: TStringBuilder;
  i, k: Integer;
begin
  SB := TStringBuilder.Create;
  try
    SB.Append(P.XRCData).Append('|mode ').Append(P.Params.FitMode);
    SB.Append('|table ').Append(Ord(P.TableExtension));
    SB.Append('|period ').Append(Ord(P.Params.LFPSO.FreePeriod)).Append(' ')
      .Append(Num(P.Params.LFPSO.PeriodWindow));
    SB.Append('|calc ').Append(Num(P.Params.Lambda)).Append(' ').Append(Num(P.Params.Width))
      .Append(' ').Append(P.Params.Polarisation).Append(' ').Append(Ord(P.TwoTheta))
      .Append(' ').Append(Num(P.Params.MinLimit));   // the model curve is cut off there
    for i := 0 to High(P.Extensions) do
    begin
      SB.Append('|ext ').Append(P.Extensions[i].StackID).Append(' ').Append(P.Extensions[i].LayerID)
        .Append(' ').Append(Ord(P.Extensions[i].Subj));
      for k := 1 to High(P.Extensions[i].Coeffs) do
        SB.Append(' ').Append(Num(P.Extensions[i].Coeffs[k]));
    end;
    SB.Append('|data');
    for i := 0 to High(P.DataCurve) do
      SB.Append(' ').Append(Num(P.DataCurve[i].t)).Append(':').Append(Num(P.DataCurve[i].r));
    SB.Append('|counts');
    for i := 0 to High(Counts) do
      SB.Append(' ').Append(Num(Counts[i]));
    for i := 0 to High(Priors) do
      SB.Append('|prior ').Append(Priors[i].Name).Append(' ').Append(Num(Priors[i].Mean))
        .Append(' ').Append(Num(Priors[i].SD));
    Result := THashSHA2.GetHashString(SB.ToString);
  finally
    SB.Free;
  end;
end;

{ ------------------------------------------------------------------ JSON -- }

function JNum(V: Double): TJSONValue;
begin
  if IsNan(V) or IsInfinite(V) then
    Result := TJSONNull.Create
  else
    { 17 significant digits: what a Double needs to come back to the last bit.
      TJSONNumber.Create(Double) writes fewer. }
    Result := TJSONNumber.Create(Num(V));
end;

function JArr(const A: TArray<Double>): TJSONArray;
var
  i: Integer;
begin
  Result := TJSONArray.Create;
  for i := 0 to High(A) do
    Result.AddElement(JNum(A[i]));
end;

function GNum(O: TJSONObject; const Key: string): Double;
var
  V: TJSONValue;
begin
  V := O.GetValue(Key);
  if V is TJSONNumber then
    Result := TJSONNumber(V).AsDouble
  else
    Result := NaN;
end;

function ArrOf(V: TJSONValue): TArray<Double>;
var
  A: TJSONArray;
  i: Integer;
begin
  Result := nil;
  if not (V is TJSONArray) then
    Exit;
  A := TJSONArray(V);
  SetLength(Result, A.Count);
  for i := 0 to A.Count - 1 do
    if A.Items[i] is TJSONNumber then
      Result[i] := TJSONNumber(A.Items[i]).AsDouble
    else
      Result[i] := NaN;
end;

function GArr(O: TJSONObject; const Key: string): TArray<Double>;
begin
  Result := ArrOf(O.GetValue(Key));
end;

function StoredToJSON(const S: TStoredUncert): string;
var
  Root, O, R, Band: TJSONObject;
  A, Row: TJSONArray;
  i: Integer;
begin
  Root := TJSONObject.Create;
  try
    Root.AddPair('format', TJSONNumber.Create(UNCERT_FORMAT));
    Root.AddPair('fingerprint', S.Fingerprint);

    A := TJSONArray.Create;
    Root.AddPair('priors', A);
    for i := 0 to High(S.Priors) do
    begin
      O := TJSONObject.Create;
      A.AddElement(O);
      O.AddPair('name', S.Priors[i].Name);
      O.AddPair('mean', JNum(S.Priors[i].Mean));
      O.AddPair('sd', JNum(S.Priors[i].SD));
      O.AddPair('note', S.Priors[i].Note);
    end;

    A := TJSONArray.Create;
    Root.AddPair('names', A);
    for i := 0 to High(S.Names) do
    begin
      O := TJSONObject.Create;
      A.AddElement(O);
      O.AddPair('name', S.Names[i].Name);
      O.AddPair('caption', S.Names[i].Caption);
      O.AddPair('group', S.Names[i].Group);
      O.AddPair('kind', TJSONNumber.Create(Ord(S.Names[i].Kind)));
      O.AddPair('held', TJSONBool.Create(S.Names[i].Held));
      O.AddPair('can_have_prior', TJSONBool.Create(S.Names[i].CanHavePrior));
      O.AddPair('stack', TJSONNumber.Create(S.Names[i].Stack));
      O.AddPair('layer', TJSONNumber.Create(S.Names[i].Layer));
      O.AddPair('p', TJSONNumber.Create(S.Names[i].P));
      O.AddPair('period', TJSONNumber.Create(S.Names[i].Period));
    end;

    if S.HasResult then
    begin
      R := TJSONObject.Create;
      Root.AddPair('result', R);
      R.AddPair('settled', TJSONBool.Create(S.Result.Settled));
      R.AddPair('message', S.Result.Message);
      R.AddPair('device', S.Result.Device);
      R.AddPair('seconds', JNum(S.Result.Seconds));
      R.AddPair('repeated', TJSONBool.Create(S.Result.Repeated));
      R.AddPair('walkers', TJSONNumber.Create(S.Result.Walkers));
      R.AddPair('steps', TJSONNumber.Create(S.Result.StepsRun));
      A := TJSONArray.Create;
      R.AddPair('warnings', A);
      for i := 0 to High(S.Result.Warnings) do
        A.Add(S.Result.Warnings[i]);
      A := TJSONArray.Create;
      R.AddPair('values', A);
      for i := 0 to High(S.Result.Values) do
      begin
        O := TJSONObject.Create;
        A.AddElement(O);
        O.AddPair('name', S.Result.Values[i].Name);
        O.AddPair('best', JNum(S.Result.Values[i].Best));
        O.AddPair('p2_5', JNum(S.Result.Values[i].P2_5));
        O.AddPair('p16', JNum(S.Result.Values[i].P16));
        O.AddPair('p50', JNum(S.Result.Values[i].P50));
        O.AddPair('p84', JNum(S.Result.Values[i].P84));
        O.AddPair('p97_5', JNum(S.Result.Values[i].P97_5));
        O.AddPair('minus', JNum(S.Result.Values[i].Minus));
        O.AddPair('plus', JNum(S.Result.Values[i].Plus));
        O.AddPair('rhat', JNum(S.Result.Values[i].RHat));
        O.AddPair('at_limit', TJSONBool.Create(S.Result.Values[i].AtLimit));
      end;
      Band := TJSONObject.Create;
      R.AddPair('band', Band);
      Band.AddPair('theta', JArr(S.Result.Band.Theta));
      Band.AddPair('measured', JArr(S.Result.Band.Measured));
      Band.AddPair('p16', JArr(S.Result.Band.P16));
      Band.AddPair('p50', JArr(S.Result.Band.P50));
      Band.AddPair('p84', JArr(S.Result.Band.P84));
      A := TJSONArray.Create;
      R.AddPair('correlation', A);
      for i := 0 to High(S.Result.Correlation) do
      begin
        Row := JArr(S.Result.Correlation[i]);
        A.AddElement(Row);
      end;
    end;
    Result := Root.ToJSON;
  finally
    Root.Free;
  end;
end;

function StoredFromJSON(const Text: string; out S: TStoredUncert): Boolean;
var
  V, Item: TJSONValue;
  Root, O, R, Band: TJSONObject;
  A: TJSONArray;
  i: Integer;
begin
  Result := False;
  S := Default(TStoredUncert);
  V := TJSONObject.ParseJSONValue(Text);
  try
    if not (V is TJSONObject) then
      Exit;
    Root := TJSONObject(V);
    if Root.GetValue<Integer>('format', 0) <> UNCERT_FORMAT then
      Exit;
    S.Fingerprint := Root.GetValue<string>('fingerprint', '');

    if Root.GetValue('priors') is TJSONArray then
    begin
      A := TJSONArray(Root.GetValue('priors'));
      SetLength(S.Priors, A.Count);
      for i := 0 to A.Count - 1 do
        if A.Items[i] is TJSONObject then
        begin
          O := TJSONObject(A.Items[i]);
          S.Priors[i].Name := O.GetValue<string>('name', '');
          S.Priors[i].Mean := GNum(O, 'mean');
          S.Priors[i].SD := GNum(O, 'sd');
          S.Priors[i].Note := O.GetValue<string>('note', '');
        end;
    end;

    if Root.GetValue('names') is TJSONArray then
    begin
      A := TJSONArray(Root.GetValue('names'));
      SetLength(S.Names, A.Count);
      for i := 0 to A.Count - 1 do
        if A.Items[i] is TJSONObject then
        begin
          O := TJSONObject(A.Items[i]);
          S.Names[i].Name := O.GetValue<string>('name', '');
          S.Names[i].Caption := O.GetValue<string>('caption', '');
          S.Names[i].Group := O.GetValue<string>('group', '');
          S.Names[i].Kind := TUncertNameKind(EnsureRange(O.GetValue<Integer>('kind', 0),
            Ord(Low(TUncertNameKind)), Ord(High(TUncertNameKind))));
          S.Names[i].Held := O.GetValue<Boolean>('held', False);
          S.Names[i].CanHavePrior := O.GetValue<Boolean>('can_have_prior', False);
          S.Names[i].Stack := O.GetValue<Integer>('stack', -1);
          S.Names[i].Layer := O.GetValue<Integer>('layer', -1);
          S.Names[i].P := O.GetValue<Integer>('p', -1);
          S.Names[i].Period := O.GetValue<Integer>('period', 0);
        end;
    end;

    if Root.GetValue('result') is TJSONObject then
    begin
      R := TJSONObject(Root.GetValue('result'));
      S.HasResult := True;
      S.Result.Settled := R.GetValue<Boolean>('settled', False);
      S.Result.Message := R.GetValue<string>('message', '');
      S.Result.Device := R.GetValue<string>('device', '');
      S.Result.Seconds := GNum(R, 'seconds');
      S.Result.Repeated := R.GetValue<Boolean>('repeated', False);
      S.Result.Walkers := R.GetValue<Integer>('walkers', 0);
      S.Result.StepsRun := R.GetValue<Integer>('steps', 0);
      if R.GetValue('warnings') is TJSONArray then
        for Item in TJSONArray(R.GetValue('warnings')) do
          S.Result.Warnings := S.Result.Warnings + [Item.Value];
      if R.GetValue('values') is TJSONArray then
      begin
        A := TJSONArray(R.GetValue('values'));
        SetLength(S.Result.Values, A.Count);
        for i := 0 to A.Count - 1 do
          if A.Items[i] is TJSONObject then
          begin
            O := TJSONObject(A.Items[i]);
            S.Result.Values[i].Name := O.GetValue<string>('name', '');
            S.Result.Values[i].Best := GNum(O, 'best');
            S.Result.Values[i].P2_5 := GNum(O, 'p2_5');
            S.Result.Values[i].P16 := GNum(O, 'p16');
            S.Result.Values[i].P50 := GNum(O, 'p50');
            S.Result.Values[i].P84 := GNum(O, 'p84');
            S.Result.Values[i].P97_5 := GNum(O, 'p97_5');
            S.Result.Values[i].Minus := GNum(O, 'minus');
            S.Result.Values[i].Plus := GNum(O, 'plus');
            S.Result.Values[i].RHat := GNum(O, 'rhat');
            S.Result.Values[i].AtLimit := O.GetValue<Boolean>('at_limit', False);
          end;
      end;
      if R.GetValue('band') is TJSONObject then
      begin
        Band := TJSONObject(R.GetValue('band'));
        S.Result.Band.Theta := GArr(Band, 'theta');
        S.Result.Band.Measured := GArr(Band, 'measured');
        S.Result.Band.P16 := GArr(Band, 'p16');
        S.Result.Band.P50 := GArr(Band, 'p50');
        S.Result.Band.P84 := GArr(Band, 'p84');
      end;
      if R.GetValue('correlation') is TJSONArray then
      begin
        A := TJSONArray(R.GetValue('correlation'));
        SetLength(S.Result.Correlation, A.Count);
        for i := 0 to A.Count - 1 do
          S.Result.Correlation[i] := ArrOf(A.Items[i]);
      end;
    end;
    Result := True;
  finally
    V.Free;
    if not Result then
      S := Default(TStoredUncert);
  end;
end;

{ --------------------------------------------------------------- archive -- }

function ReadEntry(const ProjectFile, Name: string; out Text: string): Boolean;
var
  Z: TZipFile;
  Bytes: TBytes;
begin
  Result := False;
  Text := '';
  if not TFile.Exists(ProjectFile) then
    Exit;
  Z := TZipFile.Create;
  try
    try
      Z.Open(ProjectFile, zmRead);
      if Z.IndexOf(Name) < 0 then
        Exit;
      Z.Read(Name, Bytes);
      Text := TEncoding.UTF8.GetString(Bytes);
      Result := True;
    except
      on Exception do
        Result := False;       // not a readable archive: there is no entry to give
    end;
  finally
    Z.Free;
  end;
end;

function IsOwn(const Entry: string; const Names: TArray<string>): Boolean;
var
  N: string;
begin
  Result := False;
  for N in Names do
    if SameText(N, Entry) then
      Exit(True);
end;

function WriteEntries(const ProjectFile: string; const Names, Texts: TArray<string>): string;
var
  Src, Dst: TZipFile;
  Tmp, Entry: string;
  Bytes: TBytes;
  i: Integer;
begin
  Result := '';
  if Length(Names) <> Length(Texts) then
    raise EArgumentException.Create('WriteEntries: one text per name');
  if not TFile.Exists(ProjectFile) then
    Exit(Format('The project file %s was not found.', [ProjectFile]));
  if TFileAttribute.faReadOnly in TFile.GetAttributes(ProjectFile) then
    Exit(Format('The project file %s is read-only: the result was not saved.',
      [TPath.GetFileName(ProjectFile)]));

  Tmp := ProjectFile + '.uncert-new';
  try
    Src := TZipFile.Create;
    Dst := TZipFile.Create;
    try
      Src.Open(ProjectFile, zmRead);
      Dst.Open(Tmp, zmWrite);
      for Entry in Src.FileNames do
        if not IsOwn(Entry, Names) then
        begin
          Src.Read(Entry, Bytes);
          Dst.Add(Bytes, Entry);
        end;
      for i := 0 to High(Names) do
        Dst.Add(TEncoding.UTF8.GetBytes(Texts[i]), Names[i]);
      Dst.Close;
      Src.Close;
    finally
      Dst.Free;
      Src.Free;
    end;

    { One step: the new archive takes the project's name. Either it happens
      or the project is what it was; there is no moment without a project
      and nothing to put back. }
    if not MoveFileEx(PChar(Tmp), PChar(ProjectFile),
      MOVEFILE_REPLACE_EXISTING or MOVEFILE_WRITE_THROUGH) then
      RaiseLastOSError;
  except
    on E: Exception do
    begin
      if TFile.Exists(Tmp) then
        try
          TFile.Delete(Tmp);
        except
        end;
      Result := Format('The result could not be saved into %s (%s). Close the project in the ' +
        'main program, or check that the file can be written, and try again.',
        [TPath.GetFileName(ProjectFile), E.Message]);
    end;
  end;
end;

end.
