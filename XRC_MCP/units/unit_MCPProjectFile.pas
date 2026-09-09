unit unit_MCPProjectFile;

(* Reading and writing X-Ray Calc 3 `.xrcx` project files.

   An `.xrcx` is a zip of four flat entries:

     params.dsc    INI, exactly the keys TfrmCalcSettings.SaveToINI /
                   SaveAdvancedParams and TfrmChartInfo.SaveToINI write, plus
                   [INFO] Version and [STATE] ActiveModel / LinkedData / LogScale
     project.dsc   a VirtualTreeView node stream written by TXRCProjectTree
     calc.dat      the model curve, in the text format unit_SeriesIO writes
     data_<id>.dat one file per data node, same format

   **The headless tree.** project.dsc is written by the GUI's own
   TXRCProjectTree with the GUI's own OnSaveNode, so the bytes are the GUI's
   bytes rather than a reimplementation of them. The open question when this
   unit was planned was whether a TVirtualStringTree can be created, filled,
   saved and re-read in a console process that never shows a window; the plan
   carried a hand-rolled byte writer (plan Appendix A) as the fallback.

   It can. `TXRCProjectTree.Create(nil, 96)` needs no owner, no parent and no
   window handle: SaveToFile and LoadFromFile only walk nodes and stream them.
   The spike is TestMCPProjectFile.HeadlessTree_SaveLoad_RoundTrip, and it
   passes. **The fallback writer was not needed and is not implemented.**
   TXRCProjectTree is a VCL component, so the process still needs the VCL
   Application object to exist - XRC_MCP.dpr calls Application.Initialize.

   Three quirks of the GUI's node format that this unit has to live with,
   all of them read out of unit_XRCProjectTree.pas rather than assumed:

   1. TProjectData is a *variant* record. The prItem branch (ID, CurveID,
      Color, Active, Visible) and the prExtension branch (Enabled, ExtType,
      StackID, LayerID, PolyCount, Poly, Form, Subj) share the same memory, and
      ProjectSaveNode writes both sets of fields for every node regardless of
      its RowType. Writing an item field after an extension field on the same
      node therefore silently corrupts the other one. Every node built here
      assigns the fields of its own branch only, and never FillChars the record
      (it holds four managed strings; the tree already hands out zeroed node
      data).

   2. ProjectSaveNode writes Poly[1..PolyCount] - **Poly[0] is not stored**.
      That is deliberate in the GUI: GetProfileFunctions overwrites C[0] with
      the layer's current parameter value every time it reads a profile back.
      So Coeffs[0] survives a write/read round trip as 0, and callers must
      treat it the way the GUI does.

   3. ProjectLoadNode rewrites any title containing 'Models' or 'Data' to
      exactly 'Models' or 'Data' (it is how the GUI repairs the group captions
      of old files). A model named "Data 3" is therefore titled "Data" after a
      round trip. Mirrored here rather than worked around: a project written by
      this unit must behave in the GUI exactly like one the GUI wrote.

   Floats in params.dsc are written with TFormatSettings.Invariant. The GUI
   writes them with the machine locale and parses them with StrToFloat, whose
   FixDecimaPoint accepts a comma; a machine whose decimal separator is a comma
   would read an invariant '0.015' as a header line and fall back to the
   default. That is the same assumption the rest of the server makes. *)

interface

uses
  System.SysUtils, System.Classes,
  unit_Types;

type
  /// <summary>Everything params.dsc carries. Defaults are
  /// TfrmProjectPanel.CreateDefaultProject plus the defaults
  /// TfrmCalcSettings.LoadFromINI / LoadAdvancedParams fall back on.</summary>
  TXRCXCalcParams = record
    Lambda: Double;                 // [ANGLE] lambbda  (sic: the GUI key is misspelled)
    ThetaStart, ThetaEnd: Double;   // [ANGLE] Start / End, written in theta ([ANGLE] 2teta=0)
    Width: Double;                  // [ANGLE] width, the convolution width in degrees
    Points: Integer;                // [PARAMS] N
    Polarisation: Integer;          // [PARAMS] Polarisation, 0 = s, 1 = s+p
    MinLimit: Double;               // [PARAMS] MinLimit, the chart's lower R limit
    FitMode: Integer;               // [FIT] Mode, 0 irregular 1 periodic 2 poly
    FitIter, FitPop: Integer;       // [FIT] Namx / Pop
    PolyOrder: Integer;             // [FIT] PolyOrder
    PWChi: Boolean;                 // [FIT] PWChi
    TWChi: Integer;                 // [FIT] TWChi
    Tol, Window: Double;            // [FIT] Tol / Window
    LFPSO: TFitParams;              // [LFPSO] and the [FIT] mirrors of the same fields
  end;

  /// <summary>One gradient extension node: a polynomial profile over the
  /// periods of one layer. Coeffs is C[0..order] exactly as TProjectData.PolyD
  /// returns it; Coeffs[0] is not stored in the file (see the unit header).</summary>
  TXRCXProfileExt = record
    StackID, LayerID: Integer;
    Subj: TParameterType;
    Coeffs: TArray<Single>;
  end;

  TXRCXProject = record
    Params: TXRCXCalcParams;
    ModelTitle: string;
    Note: string;                       // the model node's Description
    XRCData: string;                    // the GUI structure string (TXRCStructure.ToString)
    Extensions: TArray<TXRCXProfileExt>;
    CalcCurve: unit_Types.TDataArray;   // calc.dat
    DataTitle: string;                  // '' = the project has no data node
    DataCurve: unit_Types.TDataArray;   // data_<id>.dat, theta
    Version: Integer;                   // [INFO] Version; set by ReadXRCX
  end;

const
  /// The ID the model node written by this unit carries, and the value of
  /// [STATE] ActiveModel. The GUI numbers models from 1.
  XRCX_MODEL_ID = 1;
  /// The ID of the data node, and of [STATE] LinkedData. The GUI's FLastID
  /// hands the first data node of a default project the number 2.
  XRCX_DATA_ID = 2;

  CALC_CURVE_NAME = 'calc.dat';

/// <summary>The parameter block of a freshly created GUI project.</summary>
function DefaultCalcParams: TXRCXCalcParams;

/// <summary>The name of the data curve file of a data node with this ID,
/// TfrmProjectPanel.DataName without the directory.</summary>
function DataCurveName(ID: Integer): string;

/// <summary>Writes a complete .xrcx. Builds the four members in a temporary
/// directory, zips it with flat entry names and removes the directory again.
/// An existing file at Path is replaced.</summary>
procedure WriteXRCX(const Path: string; const P: TXRCXProject);

/// <summary>Reads an .xrcx written by this unit or by the GUI. Raises
/// EMCPError('invalid_argument') when Path is not a readable zip archive, and
/// EMCPError('unsupported_project') when the archive has no project.dsc or
/// when the project's model structure is not in it (v2 projects keep it in a
/// separate model_N.bin).</summary>
function ReadXRCX(const Path: string): TXRCXProject;

/// <summary>The unit_SeriesIO text format: two header lines, a blank line, then
/// FloatToStrF(x, ffFixed, 5, 3) TAB FloatToStrF(y, ffExponent, 5, 4).</summary>
procedure WriteCurveText(const Path: string; const C: unit_Types.TDataArray;
  const ColX, ColY, UnitX: string);

/// <summary>unit_SeriesIO.SeriesFromText: tab-separated (space as a fallback),
/// a comma accepted as the decimal mark, non-numeric lines skipped.</summary>
function ReadCurveText(const Path: string): unit_Types.TDataArray;

implementation

uses
  System.IOUtils, System.IniFiles, System.Zip, System.Character,
  System.SyncObjs,
  Vcl.Graphics,
  VirtualTrees,
  unit_consts, unit_XRCProjectTree, unit_MCPErrors, unit_MCPStructure;

const
  { TfrmProjectPanel.GradientLabels - the label the gradient node title uses. }
  GRADIENT_LABELS: array [0 .. 2] of string = ('H', 'S', 'rho');

  { The [WAVE] section describes the wavelength-scan mode, which the server
    never uses. The GUI writes it unconditionally, so these are the values
    TfrmCalcSettings.LoadFromINI falls back on. }
  WAVE_START = '1';
  WAVE_END   = '10';
  WAVE_THETA = '85';
  WAVE_WIDTH = '0';

{ ------------------------------------------------------------- utilities -- }

function Inv: TFormatSettings;
begin
  Result := TFormatSettings.Invariant;
end;

function F(const V: Double): string;
begin
  Result := FloatToStr(V, Inv);
end;

function FS(const V: Single): string;
begin
  { The LFPSO parameters are Singles. Printing them as Doubles turns the GUI's
    "0.3" into "0.300000011920929"; seven significant digits is what
    Single.ToString - the GUI's own SaveAdvancedParams - produces. }
  Result := FloatToStrF(V, ffGeneral, 7, 0, Inv);
end;

function FG(const V: Double): string;
begin
  { The GUI's MinLimit combo holds strings like '1E-7'. ffGeneral with no
    minimum exponent width reproduces them and parses back in any locale,
    having no decimal separator at all. }
  Result := FloatToStrF(V, ffGeneral, 15, 0, Inv);
end;

function ReadFloat(INF: TMemIniFile; const Sect, Key: string; const Default: Double): Double;
var
  S: string;
begin
  S := Trim(INF.ReadString(Sect, Key, ''));
  if S = '' then
    Exit(Default);
  S := StringReplace(S, ',', '.', [rfReplaceAll]);
  if not TryStrToFloat(S, Result, Inv) then
    Result := Default;
end;

function NewTempDir: string;
begin
  Result := TPath.Combine(TPath.GetTempPath,
    'xrcmcp_' + Copy(TGUID.NewGuid.ToString, 2, 36));
  TDirectory.CreateDirectory(Result);
end;

procedure DropTempDir(const Dir: string);
begin
  try
    if (Dir <> '') and TDirectory.Exists(Dir) then
      TDirectory.Delete(Dir, True);
  except
    // A temporary directory that cannot be removed is not worth failing a
    // tool call over; the OS cleans %TEMP% eventually.
  end;
end;

function DataCurveName(ID: Integer): string;
begin
  Result := Format('data_%d.dat', [ID]);
end;

{ ------------------------------------------------------------ curve files -- }

procedure WriteCurveText(const Path: string; const C: unit_Types.TDataArray;
  const ColX, ColY, UnitX: string);
var
  SL: TStringList;
  i: Integer;
  Fmt: TFormatSettings;
begin
  Fmt := Inv;
  SL := TStringList.Create;
  try
    SL.Add(ColX + #9 + ColY);
    SL.Add(UnitX + #9);          // SeriesToText passes an empty y unit
    SL.Add('');
    for i := 0 to High(C) do
      SL.Add(FloatToStrF(C[i].t, ffFixed, 5, 3, Fmt) + #9 +
             FloatToStrF(C[i].r, ffExponent, 5, 4, Fmt));
    SL.SaveToFile(Path);
  finally
    SL.Free;
  end;
end;

function ReadCurveText(const Path: string): unit_Types.TDataArray;
var
  SL: TStringList;
  i, p, N: Integer;
  Line, S1, S2, Sep: string;
  X, Y: Single;
begin
  SetLength(Result, 0);
  if not TFile.Exists(Path) then
    Exit;

  SL := TStringList.Create;
  try
    SL.LoadFromFile(Path);
    SetLength(Result, SL.Count);
    N := 0;
    Sep := #9;
    for i := 0 to SL.Count - 1 do
    begin
      Line := SL[i];
      if Line = '' then
        Continue;

      p := Pos(Sep, Line);
      if p = 0 then
      begin
        Sep := ' ';
        p := Pos(Sep, Line);
      end;
      if p = 0 then
        Continue;

      S1 := Trim(Copy(Line, 1, p - 1));
      S2 := Trim(Copy(Line, p + 1, MaxInt));
      if (S1 = '') or (S2 = '') then
        Continue;
      if not (S1[1].IsNumber or CharInSet(S1[1], ['-', '+'])) then
        Continue;
      if not (S2[1].IsNumber or CharInSet(S2[1], ['-', '+'])) then
        Continue;

      S1 := StringReplace(S1, ',', '.', [rfReplaceAll]);
      S2 := StringReplace(S2, ',', '.', [rfReplaceAll]);
      if not TryStrToFloat(S1, X, Inv) then Continue;
      if not TryStrToFloat(S2, Y, Inv) then Continue;

      Result[N].t := X;
      Result[N].r := Y;
      Inc(N);
    end;
    SetLength(Result, N);
  finally
    SL.Free;
  end;
end;

{ ---------------------------------------------------------- params.dsc ----- }

function DefaultCalcParams: TXRCXCalcParams;
begin
  Result := Default(TXRCXCalcParams);

  Result.Lambda       := 1.54043;
  Result.ThetaStart   := 0.01;
  Result.ThetaEnd     := 5;
  Result.Width        := 0.015;
  Result.Points       := 1000;
  Result.Polarisation := 0;
  Result.MinLimit     := 1E-7;

  Result.FitMode   := 0;
  Result.FitIter   := 100;
  Result.FitPop    := 1000;
  Result.PolyOrder := 1;
  Result.PWChi     := True;
  Result.TWChi     := 0;
  Result.Tol       := 0.005;
  Result.Window    := 0.05;

  // CreateDefaultProject, plus the LoadFromINI / LoadAdvancedParams fallbacks
  Result.LFPSO.NMax            := Result.FitIter;
  Result.LFPSO.Pop             := Result.FitPop;
  Result.LFPSO.Tolerance       := Result.Tol;
  Result.LFPSO.MovAvgWindow    := Result.Window;
  Result.LFPSO.Vmax            := 0.3;
  Result.LFPSO.JammingMax      := 1;
  Result.LFPSO.ReInitMax       := 3;
  Result.LFPSO.KChiSqr         := 1.41;
  Result.LFPSO.KVmax           := 1.41;
  Result.LFPSO.w1              := 0.3;
  Result.LFPSO.w2              := 0.3;
  Result.LFPSO.AdaptVel        := False;
  Result.LFPSO.UseConstriction := True;
  Result.LFPSO.SmoothWindow    := -1;
  Result.LFPSO.Ksxr            := 0.2;
  Result.LFPSO.PolyFactor      := 10;
  Result.LFPSO.Shake           := True;
  Result.LFPSO.RangeSeed       := False;
  Result.LFPSO.Smooth          := False;
  Result.LFPSO.ThetaWeight     := Result.TWChi;
  Result.LFPSO.MaxPOrder       := Result.PolyOrder;
end;

procedure WriteParams(const FileName: string; const P: TXRCXProject);
var
  INF: TMemIniFile;
  C: TXRCXCalcParams;
begin
  C := P.Params;
  if TFile.Exists(FileName) then
    TFile.Delete(FileName);

  INF := TMemIniFile.Create(FileName);
  try
    // TfrmCalcSettings.SaveToINI + TfrmChartInfo.SaveToINI
    INF.WriteString('PARAMS', 'N', IntToStr(C.Points));
    INF.WriteInteger('PARAMS', 'Mode', 0);            // 0 = theta scan
    INF.WriteInteger('PARAMS', 'Polarisation', C.Polarisation);
    INF.WriteString('PARAMS', 'MinLimit', FG(C.MinLimit));

    INF.WriteString('ANGLE', 'Start', F(C.ThetaStart));
    INF.WriteString('ANGLE', 'End', F(C.ThetaEnd));
    INF.WriteString('ANGLE', 'lambbda', F(C.Lambda));
    INF.WriteString('ANGLE', 'width', F(C.Width));
    INF.WriteBool('ANGLE', '2teta', False);           // the angles above are theta

    INF.WriteString('WAVE', 'Start', WAVE_START);
    INF.WriteString('WAVE', 'End', WAVE_END);
    INF.WriteString('WAVE', 'Teta', WAVE_THETA);
    INF.WriteString('WAVE', 'width', WAVE_WIDTH);

    INF.WriteInteger('INFO', 'Version', CURRENT_PROJECT_VERSION);

    INF.WriteInteger('STATE', 'ActiveModel', XRCX_MODEL_ID);
    if P.DataTitle <> '' then
      INF.WriteInteger('STATE', 'LinkedData', XRCX_DATA_ID);
    INF.WriteBool('STATE', 'LogScale', True);

    INF.WriteString('FIT', 'Namx', IntToStr(C.FitIter));
    INF.WriteString('FIT', 'Pop', IntToStr(C.FitPop));
    INF.WriteInteger('FIT', 'Mode', C.FitMode);
    INF.WriteString('FIT', 'PolyOrder', IntToStr(C.PolyOrder));
    INF.WriteBool('FIT', 'PWChi', C.PWChi);
    INF.WriteInteger('FIT', 'TWChi', C.TWChi);
    // TfrmCalcSettings.SaveAdvancedParams
    INF.WriteString('FIT', 'Window', F(C.Window));
    INF.WriteString('FIT', 'Tol', F(C.Tol));

    INF.WriteString('LFPSO', 'Vmax', FS(C.LFPSO.Vmax));
    INF.WriteString('LFPSO', 'Jmax', IntToStr(C.LFPSO.JammingMax));
    INF.WriteString('LFPSO', 'RIMax', IntToStr(C.LFPSO.ReInitMax));
    INF.WriteString('LFPSO', 'kChi', FS(C.LFPSO.KChiSqr));
    INF.WriteString('LFPSO', 'kVmax', FS(C.LFPSO.KVmax));
    INF.WriteString('LFPSO', 'w1', FS(C.LFPSO.w1));
    INF.WriteString('LFPSO', 'w2', FS(C.LFPSO.w2));
    INF.WriteBool('LFPSO', 'AdaptV', C.LFPSO.AdaptVel);
    INF.WriteBool('LFPSO', 'Constriction', C.LFPSO.UseConstriction);
    INF.WriteBool('LFPSO', 'Shake', C.LFPSO.Shake);
    INF.WriteBool('LFPSO', 'SeedRange', C.LFPSO.RangeSeed);
    INF.WriteBool('LFPSO', 'Smooth', C.LFPSO.Smooth);
    INF.WriteInteger('LFPSO', 'SmoothWindow', C.LFPSO.SmoothWindow);
    INF.WriteString('LFPSO', 'Ksxr', FS(C.LFPSO.Ksxr));
    INF.WriteInteger('LFPSO', 'PolyFactor', C.LFPSO.PolyFactor);

    INF.UpdateFile;
  finally
    INF.Free;
  end;
end;

procedure ReadParams(const FileName: string; var P: TXRCXProject;
  out ActiveModel, LinkedData: Integer);
var
  INF: TMemIniFile;
  D: TXRCXCalcParams;
begin
  D := DefaultCalcParams;
  P.Params := D;
  P.Version := 0;
  ActiveModel := -1;
  LinkedData := -1;
  if not TFile.Exists(FileName) then
    Exit;

  INF := TMemIniFile.Create(FileName);
  try
    P.Params.Points       := StrToIntDef(INF.ReadString('PARAMS', 'N', ''), D.Points);
    P.Params.Polarisation := INF.ReadInteger('PARAMS', 'Polarisation', D.Polarisation);
    P.Params.MinLimit     := ReadFloat(INF, 'PARAMS', 'MinLimit', D.MinLimit);

    P.Params.ThetaStart := ReadFloat(INF, 'ANGLE', 'Start', D.ThetaStart);
    P.Params.ThetaEnd   := ReadFloat(INF, 'ANGLE', 'End', D.ThetaEnd);
    P.Params.Lambda     := ReadFloat(INF, 'ANGLE', 'lambbda', D.Lambda);
    P.Params.Width      := ReadFloat(INF, 'ANGLE', 'width', D.Width);
    { A file written with 2teta=1 holds 2theta in [ANGLE] Start / End; the GUI
      halves it when it fills the calculation parameters. Report theta. }
    if INF.ReadBool('ANGLE', '2teta', True) then
    begin
      P.Params.ThetaStart := P.Params.ThetaStart / 2;
      P.Params.ThetaEnd   := P.Params.ThetaEnd / 2;
    end;

    P.Params.FitIter   := StrToIntDef(INF.ReadString('FIT', 'Namx', ''), D.FitIter);
    P.Params.FitPop    := StrToIntDef(INF.ReadString('FIT', 'Pop', ''), D.FitPop);
    P.Params.FitMode   := INF.ReadInteger('FIT', 'Mode', D.FitMode);
    P.Params.PolyOrder := StrToIntDef(INF.ReadString('FIT', 'PolyOrder', ''), D.PolyOrder);
    P.Params.PWChi     := INF.ReadBool('FIT', 'PWChi', D.PWChi);
    P.Params.TWChi     := INF.ReadInteger('FIT', 'TWChi', D.TWChi);
    P.Params.Tol       := ReadFloat(INF, 'FIT', 'Tol', D.Tol);
    P.Params.Window    := ReadFloat(INF, 'FIT', 'Window', D.Window);

    P.Params.LFPSO.Vmax            := ReadFloat(INF, 'LFPSO', 'Vmax', D.LFPSO.Vmax);
    P.Params.LFPSO.JammingMax      := INF.ReadInteger('LFPSO', 'Jmax', D.LFPSO.JammingMax);
    P.Params.LFPSO.ReInitMax       := INF.ReadInteger('LFPSO', 'RIMax', D.LFPSO.ReInitMax);
    P.Params.LFPSO.KChiSqr         := ReadFloat(INF, 'LFPSO', 'kChi', D.LFPSO.KChiSqr);
    P.Params.LFPSO.KVmax           := ReadFloat(INF, 'LFPSO', 'kVmax', D.LFPSO.KVmax);
    P.Params.LFPSO.w1              := ReadFloat(INF, 'LFPSO', 'w1', D.LFPSO.w1);
    P.Params.LFPSO.w2              := ReadFloat(INF, 'LFPSO', 'w2', D.LFPSO.w2);
    P.Params.LFPSO.AdaptVel        := INF.ReadBool('LFPSO', 'AdaptV', D.LFPSO.AdaptVel);
    P.Params.LFPSO.UseConstriction := INF.ReadBool('LFPSO', 'Constriction', D.LFPSO.UseConstriction);
    P.Params.LFPSO.Shake           := INF.ReadBool('LFPSO', 'Shake', D.LFPSO.Shake);
    P.Params.LFPSO.RangeSeed       := INF.ReadBool('LFPSO', 'SeedRange', D.LFPSO.RangeSeed);
    P.Params.LFPSO.Smooth          := INF.ReadBool('LFPSO', 'Smooth', D.LFPSO.Smooth);
    P.Params.LFPSO.SmoothWindow    := INF.ReadInteger('LFPSO', 'SmoothWindow', D.LFPSO.SmoothWindow);
    P.Params.LFPSO.Ksxr            := ReadFloat(INF, 'LFPSO', 'Ksxr', D.LFPSO.Ksxr);
    P.Params.LFPSO.PolyFactor      := INF.ReadInteger('LFPSO', 'PolyFactor', D.LFPSO.PolyFactor);

    P.Params.LFPSO.NMax         := P.Params.FitIter;
    P.Params.LFPSO.Pop          := P.Params.FitPop;
    P.Params.LFPSO.Tolerance    := P.Params.Tol;
    P.Params.LFPSO.MovAvgWindow := P.Params.Window;
    P.Params.LFPSO.ThetaWeight  := P.Params.TWChi;
    P.Params.LFPSO.MaxPOrder    := P.Params.PolyOrder;

    P.Version   := INF.ReadInteger('INFO', 'Version', 0);
    ActiveModel := INF.ReadInteger('STATE', 'ActiveModel', -1);
    LinkedData  := INF.ReadInteger('STATE', 'LinkedData', -1);
  finally
    INF.Free;
  end;
end;

{ --------------------------------------------------------- project.dsc ----- }

/// TfrmProjectPanel.GradientTitle: 'F(<label> <stack title>/<material>)'.
/// The stack title and the material come out of the model's own structure
/// string, so the node reads in the GUI exactly as a GUI-made one does. A
/// structure that cannot be parsed, or indices that do not point into it,
/// fall back to the numeric form rather than failing the save.
function GradientTitle(const Ext: TXRCXProfileExt; const XRCData: string): string;
var
  S: TFitStructure;
  Info: TStructureInfo;
  Label_: string;
begin
  Label_ := GRADIENT_LABELS[Ord(Ext.Subj)];
  Result := Format('F(%s %d/%d)', [Label_, Ext.StackID, Ext.LayerID]);
  if XRCData = '' then
    Exit;
  try
    S := StructureFromXRCData(XRCData, Info);
  except
    Exit;
  end;
  if (Ext.StackID < 0) or (Ext.StackID > High(S.Stacks)) then
    Exit;
  if (Ext.LayerID < 0) or (Ext.LayerID > High(S.Stacks[Ext.StackID].Layers)) then
    Exit;
  Result := Format('F(%s %s/%s)', [Label_, S.Stacks[Ext.StackID].Header,
    S.Stacks[Ext.StackID].Layers[Ext.LayerID].Material]);
end;

{ ------------------------------------------------------ the headless tree -- }

(* TXRCProjectTree is a VCL control, and VirtualTrees says in so many words that
   parts of it "must only be called from UI thread": building one walks through
   TBaseVirtualTree code that reaches System.Classes.CheckSynchronize, which
   raises EThread on every thread except the one System.MainThreadID names.
   fit_xrr writes its .xrcx from the job worker, so that is exactly what
   happened - the fit finished and then died in TXRCProjectTree.Create with
   "CheckSynchronize called from thread $..., which is NOT the main thread".

   This process has no UI thread. XRC_MCP calls Application.Initialize so that
   VCL components can exist, but it never creates a window, never runs a message
   loop, and nothing in it ever calls TThread.Synchronize or TThread.Queue - so
   the queue CheckSynchronize drains is always empty and draining it is a no-op
   wherever it happens. What the tree needs is therefore not the main thread but
   *a* thread that no other tree is being built on.

   TreeScope provides that: it takes a lock, so only one headless tree exists at
   a time, and for as long as the lock is held it names the current thread as
   the main one. Both are restored in a finally. The window is a few
   milliseconds around one Create/SaveToFile/Free, and the only readers of
   MainThreadID in this process are the RTL's "am I on the UI thread" tests,
   which are answered more usefully by "yes" than by a raise. *)
type
  TTreeScope = record
  private
    FSavedMainThread: TThreadID;
  public
    procedure Enter;
    procedure Leave;
  end;

var
  TreeLock: TCriticalSection;

procedure TTreeScope.Enter;
begin
  TreeLock.Acquire;
  FSavedMainThread := MainThreadID;
  MainThreadID := TThread.CurrentThread.ThreadID;
end;

procedure TTreeScope.Leave;
begin
  MainThreadID := FSavedMainThread;
  TreeLock.Release;
end;

procedure WriteTree(const FileName: string; const P: TXRCXProject);
var
  Scope: TTreeScope;
  Tree: TXRCProjectTree;
  GroupNode, ModelNode, Node: PVirtualNode;
  PD: PProjectData;
  i, j: Integer;
  Coeffs: TPolyArray;
begin
  Scope.Enter;
  try
    Tree := TXRCProjectTree.Create(nil, 96);
    try
      Tree.NodeDataSize := SizeOf(TProjectData);

      { Models group. RecoverProjectTree takes GetFirst as the models root and its
        next sibling as the data root, so the order of the two groups is part of
        the format. }
      GroupNode := Tree.AddChild(nil, nil);
      PD := Tree.GetNodeData(GroupNode);
      PD.Title := 'Models';
      PD.Description := '';
      PD.Data := '';
      PD.Group := gtModel;
      PD.RowType := prGroup;

      ModelNode := Tree.AddChild(GroupNode, nil);
      PD := Tree.GetNodeData(ModelNode);
      PD.Title := P.ModelTitle;
      PD.Description := P.Note;
      PD.Data := P.XRCData;
      PD.Group := gtModel;
      PD.RowType := prItem;
      // prItem branch only - see quirk 1 in the unit header
      PD.ID := XRCX_MODEL_ID;
      PD.CurveID := 0;
      PD.Color := clRed;
      PD.Active := True;
      PD.Visible := True;

      for i := 0 to High(P.Extensions) do
      begin
        Node := Tree.AddChild(ModelNode, nil);
        PD := Tree.GetNodeData(Node);
        PD.Title := GradientTitle(P.Extensions[i], P.XRCData);
        PD.Description := '';
        PD.Data := '';
        PD.Group := gtModel;
        PD.RowType := prExtension;
        // prExtension branch only
        PD.Enabled := True;
        PD.ExtType := etFunction;
        PD.StackID := P.Extensions[i].StackID;
        PD.LayerID := P.Extensions[i].LayerID;
        PD.Form := ffPoly;
        PD.Subj := P.Extensions[i].Subj;
        SetLength(Coeffs, Length(P.Extensions[i].Coeffs));
        for j := 0 to High(Coeffs) do
          Coeffs[j] := P.Extensions[i].Coeffs[j];
        PD.SetPoly(Coeffs);
      end;

      GroupNode := Tree.AddChild(nil, nil);
      PD := Tree.GetNodeData(GroupNode);
      PD.Title := 'Data';
      PD.Description := '';
      PD.Data := '';
      PD.Group := gtData;
      PD.RowType := prGroup;

      if P.DataTitle <> '' then
      begin
        Node := Tree.AddChild(GroupNode, nil);
        PD := Tree.GetNodeData(Node);
        PD.Title := P.DataTitle;
        PD.Description := '';
        PD.Data := '';
        PD.Group := gtData;
        PD.RowType := prItem;
        PD.ID := XRCX_DATA_ID;
        PD.CurveID := 0;
        PD.Color := clBlue;
        PD.Active := True;
        PD.Visible := True;
      end;

      Tree.SaveToFile(FileName);
    finally
      Tree.Free;
    end;
  finally
    Scope.Leave;
  end;
end;

/// Walks the loaded tree and fills the model title, the structure string, the
/// gradient extensions and the data node's title and ID.
procedure ReadTree(const FileName: string; var P: TXRCXProject;
  ActiveModel, LinkedData: Integer; out DataID: Integer);
var
  Scope: TTreeScope;
  Tree: TXRCProjectTree;
  Node, Child, Chosen, ChosenData: PVirtualNode;
  FirstModel, MatchModel, FirstData, MatchData: PVirtualNode;
  PD: PProjectData;
  Ext: TXRCXProfileExt;
  Poly: TPolyArray;
  i: Integer;
begin
  DataID := -1;
  FirstModel := nil;
  MatchModel := nil;
  FirstData := nil;
  MatchData := nil;

  Scope.Enter;
  try
    Tree := TXRCProjectTree.Create(nil, 96);
    try
      Tree.NodeDataSize := SizeOf(TProjectData);
      Tree.Version := P.Version;      // ProjectLoadNode switches on it - set first
      Tree.LoadFromFile(FileName);

      { RecoverProjectTree takes the model named by [STATE] ActiveModel and falls
        back to the first one; RecoverDataCurves does the same with LinkedData. }
      Node := Tree.GetFirst;
      while Node <> nil do
      begin
        PD := Tree.GetNodeData(Node);
        if PD.RowType = prItem then
          if PD.Group = gtModel then
          begin
            if FirstModel = nil then
              FirstModel := Node;
            if (MatchModel = nil) and (PD.ID = ActiveModel) then
              MatchModel := Node;
          end
          else
          begin
            if FirstData = nil then
              FirstData := Node;
            if (MatchData = nil) and (PD.ID = LinkedData) then
              MatchData := Node;
          end;
        Node := Tree.GetNext(Node);
      end;

      if MatchModel <> nil then Chosen := MatchModel else Chosen := FirstModel;
      if MatchData <> nil then ChosenData := MatchData else ChosenData := FirstData;

      if Chosen = nil then
        raise EMCPError.Create('unsupported_project',
          'the project has no model node', TPath.GetFileName(FileName));

      PD := Tree.GetNodeData(Chosen);
      P.ModelTitle := PD.Title;
      P.Note := PD.Description;
      P.XRCData := PD.Data;

      if P.XRCData = '' then
        raise EMCPError.Create('unsupported_project',
          'model stored in legacy binary format; open and re-save in XRayCalc3',
          Format('model_%d.bin', [PD.ID]));

      SetLength(P.Extensions, 0);
      Child := Tree.GetFirstChild(Chosen);
      while Child <> nil do
      begin
        PD := Tree.GetNodeData(Child);
        if (PD.RowType = prExtension) and (PD.ExtType = etFunction) then
        begin
          Ext := Default(TXRCXProfileExt);
          Ext.StackID := PD.StackID;
          Ext.LayerID := PD.LayerID;
          Ext.Subj := PD.Subj;
          Poly := PD.PolyD;
          SetLength(Ext.Coeffs, Length(Poly));
          for i := 0 to High(Poly) do
            Ext.Coeffs[i] := Poly[i];
          P.Extensions := P.Extensions + [Ext];
        end;
        Child := Tree.GetNextSibling(Child);
      end;

      if ChosenData <> nil then
      begin
        PD := Tree.GetNodeData(ChosenData);
        P.DataTitle := PD.Title;
        DataID := PD.ID;
      end;
    finally
      Tree.Free;
    end;
  finally
    Scope.Leave;
  end;
end;

{ ------------------------------------------------------------- the file ---- }

procedure WriteXRCX(const Path: string; const P: TXRCXProject);
var
  Dir, TmpPath: string;
begin
  Dir := NewTempDir;
  try
    WriteParams(TPath.Combine(Dir, PARAMETERS_FILE_NAME), P);
    WriteTree(TPath.Combine(Dir, PROJECT_FILE_NAME), P);
    WriteCurveText(TPath.Combine(Dir, CALC_CURVE_NAME), P.CalcCurve,
      '2Theta', 'Reflectivity', 'deg');
    if P.DataTitle <> '' then
      WriteCurveText(TPath.Combine(Dir, DataCurveName(XRCX_DATA_ID)), P.DataCurve,
        'Theta', 'Intensity', 'deg');

    { Zip to a temporary file next to Path first, on the overwrite path a
      failure while zipping (disk full, a virus scanner holding a handle, the
      file open in the GUI) must leave the existing project in place rather
      than deleting it before the replacement exists. Only once the archive
      is complete do we drop the old file and move the new one over it. }
    TmpPath := Path + '.tmp';
    if TFile.Exists(TmpPath) then
      TFile.Delete(TmpPath);
    try
      // Flat entry names: every member sits directly in Dir, and
      // ZipDirectoryContents strips the root path from each one.
      TZipFile.ZipDirectoryContents(TmpPath, Dir);
    except
      if TFile.Exists(TmpPath) then
        TFile.Delete(TmpPath);
      raise;
    end;

    if TFile.Exists(Path) then
      TFile.Delete(Path);
    TFile.Move(TmpPath, Path);
  finally
    DropTempDir(Dir);
  end;
end;

function ReadXRCX(const Path: string): TXRCXProject;
var
  Dir, ProjectFile: string;
  ActiveModel, LinkedData, DataID: Integer;
begin
  Result := Default(TXRCXProject);
  Result.Params := DefaultCalcParams;

  Dir := NewTempDir;
  try
    try
      TZipFile.ExtractZipFile(Path, Dir);
    except
      on E: Exception do
        raise EMCPError.Create('invalid_argument',
          'the file is not a readable .xrcx archive: ' + E.Message,
          TPath.GetFileName(Path));
    end;

    ProjectFile := TPath.Combine(Dir, PROJECT_FILE_NAME);
    if not TFile.Exists(ProjectFile) then
      raise EMCPError.Create('unsupported_project',
        'the archive has no ' + PROJECT_FILE_NAME, TPath.GetFileName(Path));

    ReadParams(TPath.Combine(Dir, PARAMETERS_FILE_NAME), Result, ActiveModel, LinkedData);
    ReadTree(ProjectFile, Result, ActiveModel, LinkedData, DataID);

    Result.CalcCurve := ReadCurveText(TPath.Combine(Dir, CALC_CURVE_NAME));
    if (Result.DataTitle <> '') and (DataID >= 0) then
      Result.DataCurve := ReadCurveText(TPath.Combine(Dir, DataCurveName(DataID)));
  finally
    DropTempDir(Dir);
  end;
end;

initialization
  TreeLock := TCriticalSection.Create;

finalization
  TreeLock.Free;

end.
