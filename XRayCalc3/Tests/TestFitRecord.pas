unit TestFitRecord;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestFitRecord = class
  public
    [Test] procedure Matches_TheStructureTheFitEndedOn;
    [Test] procedure Matches_NotAfterOneThicknessChanged;
    [Test] procedure Matches_AgainWhenTheThicknessIsSetBack;
    [Test] procedure Matches_NotForAnotherModel;
    [Test] procedure Matches_RangesFlagsAndTitlesAreNotTheStructure;
    [Test] procedure Matches_PerPeriodTablesAtTheFourDecimalsTheFileKeeps;
    [Test] procedure Matches_PolynomialsWithoutC0;
    [Test] procedure Matches_NothingWithoutARecord;
    [Test] procedure GUIModel_ReloadedFromItsText_StillMatches;
    [Test] procedure GUIModel_EditedThenSetBack;
    [Test] procedure Write_Match_FitResultAsBefore_NoLastFit;
    [Test] procedure Write_NoMatch_LastFitOnly_ModelChanged;
    [Test] procedure Write_Match_RemovesLastFitAndModelChanged;
    [Test] procedure Write_NoRecord_NeitherSection;
    [Test] procedure Read_FromEitherSection;
    [Test] procedure File396_OpensAndSavesUnchanged;
    [Test] procedure ModelChanged_SetAndCleared;
  end;

implementation

uses
  System.SysUtils, System.Classes, System.JSON, System.IniFiles, Vcl.Forms,
  unit_Types, unit_FitRecord, unit_XRCStructure;

procedure SetParam(var P: TFitValue; V: Single);
begin
  P.V := V;
  P.min := V * 0.9;
  P.max := V * 1.1;
end;

function Fitted: TFitStructure;
begin
  Result := Default(TFitStructure);
  SetLength(Result.Stacks, 2);

  Result.Stacks[0].Header := 'Cap';
  Result.Stacks[0].N := 1;
  SetLength(Result.Stacks[0].Layers, 1);
  Result.Stacks[0].Layers[0].Material := 'C';
  SetParam(Result.Stacks[0].Layers[0].P[1], 21.537);
  SetParam(Result.Stacks[0].Layers[0].P[2], 3.0712);
  SetParam(Result.Stacks[0].Layers[0].P[3], 2.2);

  Result.Stacks[1].Header := 'ML';
  Result.Stacks[1].N := 3;
  SetLength(Result.Stacks[1].Layers, 2);
  Result.Stacks[1].Layers[0].Material := 'W';
  SetParam(Result.Stacks[1].Layers[0].P[1], 12.345678);
  SetParam(Result.Stacks[1].Layers[0].P[2], 3.1);
  SetParam(Result.Stacks[1].Layers[0].P[3], 19.3);
  Result.Stacks[1].Layers[0].PP[1] := [12.345678, 12.401234, 12.498765];
  Result.Stacks[1].Layers[1].Material := 'B4C';
  SetParam(Result.Stacks[1].Layers[1].P[1], 20.1);
  SetParam(Result.Stacks[1].Layers[1].P[2], 4.2);
  SetParam(Result.Stacks[1].Layers[1].P[3], 2.52);

  Result.Subs.Material := 'Si';
  Result.Subs.P[2].V := 3.0;
  Result.Subs.P[3].V := 2.33;
end;

function Copied(const S: TFitStructure): TFitStructure;
begin
  S.CopyContent(Result);
end;

function Gradient(C0: Single): TProfileFunctions;
begin
  SetLength(Result, 1);
  Result[0].Func := ffPoly;
  Result[0].Subj := ptH;
  Result[0].StackID := 1;
  Result[0].LayerID := 0;
  Result[0].C := [C0, 0.1234567, -0.0213];
end;

function RecordOf(const S: TFitStructure; const Poly: TProfileFunctions;
  WithPoly: Boolean): string;
var
  R: TJSONObject;
begin
  R := TJSONObject.Create;
  try
    R.AddPair('application', 'X-RayCalc3');
    R.AddPair('version', '3.9.6.1492');
    R.AddPair('fitDate', '2026-10-01T10:00:00.000+08:00');
    R.AddPair('fittingSeconds', TJSONNumber.Create(12.5));
    R.AddPair('fittingDevice', 'CPU');
    R.AddPair('seed', TJSONNumber.Create(42));
    R.AddPair('fittingMode', 'Periodic');
    R.AddPair('dataItem', 'd1');
    R.AddPair('chiSquared', TJSONNumber.Create(0.0123));
    R.AddPair('chiSquaredRecalc', TJSONNumber.Create(0.0124));
    R.AddPair('chiSquaredPlain', TJSONNull.Create);
    R.AddPair('chi2Scale', 'solved');
    R.AddPair('scaleRatio', TJSONNumber.Create(1.02));
    R.AddPair('scaleClamped', TJSONBool.Create(False));
    R.AddPair('structure', FitStructureJSON(S));
    if WithPoly then
      R.AddPair('polynomials', FitPolynomialsJSON(Poly));
    Result := R.ToJSON;
  finally
    R.Free;
  end;
end;

function NewIni: TMemIniFile;
begin
  Result := TMemIniFile.Create('');
end;

function SectionText(INF: TMemIniFile; const Section: string): string;
var
  SL: TStringList;
begin
  SL := TStringList.Create;
  try
    INF.ReadSectionValues(Section, SL);
    Result := SL.Text;
  finally
    SL.Free;
  end;
end;

function RecordValue(const RecordJSON, Key: string): TJSONValue;
var
  Parsed: TJSONValue;
begin
  Parsed := TJSONObject.ParseJSONValue(RecordJSON);
  try
    Result := TJSONObject(Parsed).GetValue(Key);
    if Result <> nil then
      Result := TJSONValue(Result.Clone);
  finally
    Parsed.Free;
  end;
end;

function HasModelChanged(const RecordJSON: string): Boolean;
var
  V: TJSONValue;
begin
  V := RecordValue(RecordJSON, MODEL_CHANGED_KEY);
  try
    Result := (V is TJSONBool) and TJSONBool(V).AsBoolean;
  finally
    V.Free;
  end;
end;


procedure TTestFitRecord.Matches_TheStructureTheFitEndedOn;
var
  F: TFitStructure;
begin
  F := Fitted;
  Assert.IsTrue(FitRecordMatches(RecordOf(F, nil, False), F, nil));
end;

procedure TTestFitRecord.Matches_NotAfterOneThicknessChanged;
var
  F, M: TFitStructure;
begin
  F := Fitted;
  M := Copied(F);
  M.Stacks[1].Layers[1].P[1].V := 20.2;
  Assert.IsFalse(FitRecordMatches(RecordOf(F, nil, False), M, nil));
end;

procedure TTestFitRecord.Matches_AgainWhenTheThicknessIsSetBack;
var
  F, M: TFitStructure;
  Rec: string;
begin
  F := Fitted;
  Rec := RecordOf(F, nil, False);
  M := Copied(F);
  M.Stacks[1].Layers[1].P[1].V := 20.2;
  Assert.IsFalse(FitRecordMatches(Rec, M, nil));
  M.Stacks[1].Layers[1].P[1].V := F.Stacks[1].Layers[1].P[1].V;
  Assert.IsTrue(FitRecordMatches(Rec, M, nil));
end;

procedure TTestFitRecord.Matches_NotForAnotherModel;
var
  F, M: TFitStructure;
  Rec: string;
begin
  F := Fitted;
  Rec := RecordOf(F, nil, False);

  M := Copied(F);
  M.Stacks[1].N := 4;
  Assert.IsFalse(FitRecordMatches(Rec, M, nil), 'another N');

  M := Copied(F);
  M.Stacks[1].Layers[0].Material := 'Mo';
  Assert.IsFalse(FitRecordMatches(Rec, M, nil), 'another material');

  M := Copied(F);
  SetLength(M.Stacks, 1);
  Assert.IsFalse(FitRecordMatches(Rec, M, nil), 'a stack fewer');

  M := Copied(F);
  M.Subs.P[2].V := 3.5;
  Assert.IsFalse(FitRecordMatches(Rec, M, nil), 'another substrate roughness');
end;

procedure TTestFitRecord.Matches_RangesFlagsAndTitlesAreNotTheStructure;
var
  F, M: TFitStructure;
  Rec: string;
begin
  F := Fitted;
  Rec := RecordOf(F, nil, False);

  M := Copied(F);
  M.Stacks[0].Layers[0].P[2].max := 9;
  M.Stacks[1].Layers[1].P[3].Fixed := True;
  M.Stacks[1].Header := 'Periodic';
  Assert.IsTrue(FitRecordMatches(Rec, M, nil), 'a range, a frozen flag, a title');

  M := Copied(F);
  M.Stacks[1].Layers[0].P[1].Paired := True;
  Assert.IsFalse(FitRecordMatches(Rec, M, nil),
    'pairing a parameter with a table drops the table from the model');
end;

procedure TTestFitRecord.Matches_PerPeriodTablesAtTheFourDecimalsTheFileKeeps;
var
  F, M: TFitStructure;
  Rec: string;
  c: Integer;
begin
  F := Fitted;
  Rec := RecordOf(F, nil, False);

  M := Copied(F);
  for c := 0 to High(M.Stacks[1].Layers[0].PP[1]) do
    M.Stacks[1].Layers[0].PP[1][c] := StrToFloat(
      Format('%.4f', [M.Stacks[1].Layers[0].PP[1][c]], TFormatSettings.Invariant),
      TFormatSettings.Invariant);
  Assert.IsTrue(FitRecordMatches(Rec, M, nil), 'the table as project.dsc stores it');

  M.Stacks[1].Layers[0].PP[1][2] := M.Stacks[1].Layers[0].PP[1][2] + 0.001;
  Assert.IsFalse(FitRecordMatches(Rec, M, nil), 'one period changed');

  M := Copied(F);
  SetLength(M.Stacks[1].Layers[0].PP[1], 0);
  Assert.IsFalse(FitRecordMatches(Rec, M, nil), 'the table dropped');
end;

procedure TTestFitRecord.Matches_PolynomialsWithoutC0;
var
  F: TFitStructure;
  Rec: string;
  Active: TProfileFunctions;
begin
  F := Fitted;
  Rec := RecordOf(F, Gradient(12.345678), True);

  Active := Gradient(0);
  Assert.IsTrue(FitRecordMatches(Rec, F, Active), 'C[0] is not stored in the file');

  Active := Gradient(0);
  Active[0].C[1] := 0.1235;
  Assert.IsFalse(FitRecordMatches(Rec, F, Active), 'a coefficient changed');

  Active := Gradient(0);
  Active[0].Subj := ptS;
  Assert.IsFalse(FitRecordMatches(Rec, F, Active), 'another parameter');

  Assert.IsFalse(FitRecordMatches(Rec, F, nil), 'the gradient removed');

  Assert.IsTrue(FitRecordMatches(RecordOf(F, nil, False), F, Gradient(0)),
    'a record without polynomials says nothing of them');
end;

procedure TTestFitRecord.Matches_NothingWithoutARecord;
var
  F: TFitStructure;
begin
  F := Fitted;
  Assert.IsFalse(FitRecordMatches('', F, nil), 'no record');
  Assert.IsFalse(FitRecordMatches('{"chiSquared":1}', F, nil), 'a record without a structure');
  Assert.IsFalse(FitRecordMatches('not json', F, nil), 'an unreadable record');
end;

function ModelText(const F: TFitStructure): string;
var
  Fmt: string;
  c: Integer;
  Profile: string;
begin
  Profile := '';
  for c := 0 to High(F.Stacks[1].Layers[0].PP[1]) do
    Profile := Profile + Format('%.6f;', [F.Stacks[1].Layers[0].PP[1][c]]);
  Fmt :=
    '{"Stacks":[' +
      '{"T":"Cap","N":1,"Layers":[{"M":"C","H":%s,"Hmin":%s,"Hmax":%s,' +
        '"s":%s,"Smin":%s,"Smax":%s,"r":%s,"Rmin":%s,"Rmax":%s}]},' +
      '{"T":"ML","N":3,"Layers":[' +
        '{"M":"W","H":%s,"Hmin":%s,"Hmax":%s,"s":%s,"Smin":%s,"Smax":%s,' +
          '"r":%s,"Rmin":%s,"Rmax":%s,"ProfileH":"%s"},' +
        '{"M":"B4C","H":%s,"Hmin":%s,"Hmax":%s,"s":%s,"Smin":%s,"Smax":%s,' +
          '"r":%s,"Rmin":%s,"Rmax":%s}]}],' +
    '"Subs":{"M":"Si","s":%s,"r":%s}}';

  Result := Format(Fmt, [
    FloatToStr(F.Stacks[0].Layers[0].P[1].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[1].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[1].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[2].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[2].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[2].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[3].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[3].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[0].Layers[0].P[3].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[1].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[1].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[1].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[2].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[2].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[2].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[3].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[3].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[0].P[3].max, TFormatSettings.Invariant),
    Profile,
    FloatToStr(F.Stacks[1].Layers[1].P[1].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[1].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[1].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[2].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[2].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[2].max, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[3].V, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[3].min, TFormatSettings.Invariant),
    FloatToStr(F.Stacks[1].Layers[1].P[3].max, TFormatSettings.Invariant),
    FloatToStr(F.Subs.P[2].V, TFormatSettings.Invariant),
    FloatToStr(F.Subs.P[3].V, TFormatSettings.Invariant)]);
end;

function Loaded(Host: TForm; const Text: string): TXRCStructure;
begin
  Result := TXRCStructure.Create(Host, 96);
  Result.Parent := Host;
  Result.FromString(Text);
end;

procedure TTestFitRecord.GUIModel_ReloadedFromItsText_StillMatches;
var
  Host: TForm;
  Editor, Reopened: TXRCStructure;
  Rec: string;
begin
  Host := TForm.CreateNew(nil);
  try
    Editor := Loaded(Host, ModelText(Fitted));
    Rec := RecordOf(Editor.ToFitStructure, nil, False);
    Assert.IsTrue(FitRecordMatches(Rec, Editor.ToFitStructure, nil), 'as the fit left it');

    Reopened := Loaded(Host, Editor.ToString);
    Assert.IsTrue(FitRecordMatches(Rec, Reopened.ToFitStructure, nil),
      'after the project.dsc text round trip, tables at four decimals');
  finally
    Host.Free;
  end;
end;

procedure TTestFitRecord.GUIModel_EditedThenSetBack;
var
  Host: TForm;
  Editor: TXRCStructure;
  Rec: string;
  S: TFitStructure;
  Original: Single;
begin
  Host := TForm.CreateNew(nil);
  try
    Editor := Loaded(Host, ModelText(Fitted));
    Rec := RecordOf(Editor.ToFitStructure, nil, False);

    S := Editor.ToFitStructure;
    Original := S.Stacks[1].Layers[1].P[1].V;
    S.Stacks[1].Layers[1].P[1].V := Original + 0.5;
    Editor.UpdateInterfaceP(S, True);
    Assert.IsFalse(FitRecordMatches(Rec, Editor.ToFitStructure, nil), 'edited');

    S.Stacks[1].Layers[1].P[1].V := Original;
    Editor.UpdateInterfaceP(S, True);
    Assert.IsTrue(FitRecordMatches(Rec, Editor.ToFitStructure, nil), 'set back');
  finally
    Host.Free;
  end;
end;

procedure TTestFitRecord.Write_Match_FitResultAsBefore_NoLastFit;
var
  INF: TMemIniFile;
  Rec: string;
begin
  Rec := RecordOf(Fitted, nil, False);
  INF := NewIni;
  try
    Assert.AreEqual(Ord(frpFitResult), Ord(WriteFitRecord(INF, Rec, True)));
    Assert.AreEqual(
      'chiSquared=0.0123'#13#10 +
      'chiSquaredRecalc=0.0124'#13#10 +
      'chiSquaredPlain=null'#13#10 +
      'chi2Scale=solved'#13#10 +
      'scaleRatio=1.02'#13#10 +
      'scaleClamped=false'#13#10 +
      'fittingMode=Periodic'#13#10 +
      'fitDate=2026-10-01T10:00:00.000+08:00'#13#10 +
      'fittingSeconds=12.5'#13#10 +
      'fittingDevice=CPU'#13#10 +
      'seed=42'#13#10 +
      'version=3.9.6.1492'#13#10 +
      'dataItem=d1'#13#10 +
      'Record=' + Rec + #13#10,
      SectionText(INF, FIT_RECORD_SECTION));
    Assert.IsFalse(INF.SectionExists(LAST_FIT_SECTION));
  finally
    INF.Free;
  end;
end;

procedure TTestFitRecord.Write_NoMatch_LastFitOnly_ModelChanged;
var
  INF: TMemIniFile;
  Rec, Stored: string;
  Keys: TStringList;
  V: TJSONValue;
begin
  Rec := RecordOf(Fitted, nil, False);
  INF := NewIni;
  Keys := TStringList.Create;
  try
    Assert.AreEqual(Ord(frpLastFit), Ord(WriteFitRecord(INF, Rec, False)));
    Assert.IsFalse(INF.SectionExists(FIT_RECORD_SECTION), 'no [FITRESULT]');
    INF.ReadSection(LAST_FIT_SECTION, Keys);
    Assert.AreEqual('Record'#13#10, Keys.Text, '[LASTFIT] has Record= only');
    Stored := INF.ReadString(LAST_FIT_SECTION, 'Record', '');
    Assert.IsTrue(HasModelChanged(Stored), '"modelChanged": true');
    V := RecordValue(Stored, 'chiSquared');
    try
      Assert.AreEqual('0.0123', V.ToJSON, 'the record itself is kept');
    finally
      V.Free;
    end;
  finally
    Keys.Free;
    INF.Free;
  end;
end;

procedure TTestFitRecord.Write_Match_RemovesLastFitAndModelChanged;
var
  INF: TMemIniFile;
  Rec, Stored: string;
begin
  Rec := RecordOf(Fitted, nil, False);
  INF := NewIni;
  try
    WriteFitRecord(INF, Rec, False);
    Stored := ReadFitRecord(INF);
    Assert.IsTrue(HasModelChanged(Stored));

    WriteFitRecord(INF, Stored, True);
    Assert.IsFalse(INF.SectionExists(LAST_FIT_SECTION), '[LASTFIT] removed');
    Assert.AreEqual(Rec, INF.ReadString(FIT_RECORD_SECTION, 'Record', ''),
      'the record as the fit wrote it, without modelChanged');
  finally
    INF.Free;
  end;
end;

procedure TTestFitRecord.Write_NoRecord_NeitherSection;
var
  INF: TMemIniFile;
begin
  INF := NewIni;
  try
    INF.WriteString(FIT_RECORD_SECTION, 'chiSquared', '1');
    INF.WriteString(LAST_FIT_SECTION, 'Record', '{}');
    Assert.AreEqual(Ord(frpNone), Ord(WriteFitRecord(INF, '', True)));
    Assert.IsFalse(INF.SectionExists(FIT_RECORD_SECTION));
    Assert.IsFalse(INF.SectionExists(LAST_FIT_SECTION));
  finally
    INF.Free;
  end;
end;

procedure TTestFitRecord.Read_FromEitherSection;
var
  INF: TMemIniFile;
  Rec: string;
begin
  Rec := RecordOf(Fitted, nil, False);
  INF := NewIni;
  try
    Assert.AreEqual('', ReadFitRecord(INF), 'none');
    WriteFitRecord(INF, Rec, True);
    Assert.AreEqual(Rec, ReadFitRecord(INF), '[FITRESULT]');
    WriteFitRecord(INF, Rec, False);
    Assert.AreEqual(FitRecordWithModelChanged(Rec, True), ReadFitRecord(INF), '[LASTFIT]');
  finally
    INF.Free;
  end;
end;

procedure TTestFitRecord.File396_OpensAndSavesUnchanged;
var
  Old, Saved: TMemIniFile;
  Lines: TStringList;
  Rec, Section: string;
  F: TFitStructure;
begin
  F := Fitted;
  Rec := RecordOf(F, nil, False);
  Section :=
    'chiSquared=0.0123'#13#10 +
    'chiSquaredRecalc=0.0124'#13#10 +
    'chiSquaredPlain=null'#13#10 +
    'chi2Scale=solved'#13#10 +
    'scaleRatio=1.02'#13#10 +
    'scaleClamped=false'#13#10 +
    'fittingMode=Periodic'#13#10 +
    'fitDate=2026-10-01T10:00:00.000+08:00'#13#10 +
    'fittingSeconds=12.5'#13#10 +
    'fittingDevice=CPU'#13#10 +
    'seed=42'#13#10 +
    'version=3.9.6.1492'#13#10 +
    'dataItem=d1'#13#10 +
    'Record=' + Rec + #13#10;

  Lines := TStringList.Create;
  Old := NewIni;
  Saved := NewIni;
  try
    Lines.Text := '[INFO]'#13#10'Version=8'#13#10'[FITRESULT]'#13#10 + Section;
    Old.SetStrings(Lines);

    Rec := ReadFitRecord(Old);
    Assert.AreEqual(Ord(frpFitResult),
      Ord(WriteFitRecord(Saved, Rec, FitRecordMatches(Rec, F, nil))));
    Assert.AreEqual(Section, SectionText(Saved, FIT_RECORD_SECTION));
  finally
    Saved.Free;
    Old.Free;
    Lines.Free;
  end;
end;

procedure TTestFitRecord.ModelChanged_SetAndCleared;
var
  Rec, Changed: string;
begin
  Rec := RecordOf(Fitted, nil, False);
  Assert.AreEqual(Rec, FitRecordWithModelChanged(Rec, False), 'nothing to clear: the text as it was');
  Changed := FitRecordWithModelChanged(Rec, True);
  Assert.IsTrue(HasModelChanged(Changed));
  Assert.AreEqual(Changed, FitRecordWithModelChanged(Changed, True), 'set once');
  Assert.AreEqual(Rec, FitRecordWithModelChanged(Changed, False));
  Assert.AreEqual('', FitRecordWithModelChanged('', True), 'no record stays none');
end;

initialization
  TDUnitX.RegisterTestFixture(TTestFitRecord);

end.
