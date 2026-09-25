(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_Types;

interface

uses
  SysUtils, VCLTee.Series, Graphics, math_complex;

type

  TFittingMode = (fmIrregular, fmPeriodic, fmPoly);

  TFloatArray = array of Single;
  TIntArray = array of Word;
  TPolyArray = array of single;

  TLayer = array [1..3] of TPolyArray;   // Array of layer parameters
  TSolution = array of TLayer; // H, Sigma, rho x N Layers
  TPopulation = array of TSolution;

  TRoughnessFunction = (rfError, rfExp, rfLinear, rfStep, rfSinus);
  TCalcMode = (cmTheta, cmLambda, cmTest);
  TPolarisation = (cmS, cmSP);

  TProjectGroupType = (gtModel, gtData);
  TProjRowType = (prGroup, prItem, prFolder, prExtension);
  TExtentionType = (etNone, etFunction, etTable, etRough);
  TFunctionForm = (ffNone, ffPoly, ffExp, ffParabolic, ffSQRT);
  TParameterType = (ptH, ptS, ptRho);

  PLineSeries = ^TLineSeries;

  PProjectData = ^TProjectdata;
  TProjectData = record
    Title: string;
    Group: TProjectGroupType;
    Description: string;
    Data: string;
    function IsModel: Boolean;
    function PolyD: TPolyArray;
    procedure SetPoly(var PolyD: TPolyArray);
    function IsFitExtension: Boolean;
    case RowType: TProjRowType of
      prGroup, prFolder:
        ();
      prItem:
        (ID: integer;
         CurveID: integer;
         Color: TColor;
         Active: boolean;
         Visible: boolean);
      prExtension:
         (Enabled: boolean;
          FromFit: Boolean;    // runtime only - never streamed to the project file
          case ExtType: TExtentionType of
            etFunction:
              (StackID: integer;
               LayerID: integer;
               PolyCount: Integer;
               Poly: array [0..9] of single;
               Form: TFunctionForm;
               Subj: TParameterType;
               );
            etTable:
              ();
         )
  end;

  TCalcThreadParams = record
    N: integer;
    K: integer;
    P: TPolarisation;
    RF: TRoughnessFunction;
    MVAWindow: Integer;
    case Mode: TCalcMode of
      cmTheta:
        (StartT, EndT, DT: single;
          Lambda: single);
      cmLambda:
        (StartL, EndL: single;
          Theta: single;
          DW: single);
  end;

  TFitParams = record
    NMax: integer;
     Pop: integer;
   Tolerance: Single;
    Vmax: single;
    JammingMax: integer;
     ReInitMax: integer;
       KChiSqr: single;
       KVmax  : single;
        w1, w2: single;
  MovAvgWindow: Single;

         Shake : boolean;
    ThetaWeight: integer;
       AdaptVel: Boolean;
 UseConstriction: Boolean;
         RangeSeed: Boolean;
      MaxPOrder: Integer;
          Ksxr : Single;
     PolyFactor: Integer;
         Smooth: Boolean;
   SmoothWindow: ShortInt;
     SolveScale: Boolean;   // TCalc.SolveScale for every evaluation of the fit
 ScaleWindowLog: Single;    // TCalc.ScaleWindowLog
     FreePeriod: Boolean;   // periodic mode: every N > 1 stack's period may move
   PeriodWindow: Single;    //   by this fraction of its start value either way
           Seed: Integer;   // GUI: the random seed of the next fits, 0 = draw one;
                            //   typed in Advanced settings, not saved with a project
  end;

  // Calculation data types

  TCalcLayer = record
    e: TComplex; { Epsilon }
    L, s, ro: single; { Thickness, sigma}
    K: TComplex; { kappa }
    RF, r: TComplex; { Fresnel coefficient }
    eRatio: single; { epsilon ratio, precomputed per model }
    s2: single; { sigma^2 / 2, precomputed per model for rfError roughness }
    RoughFactor: single; { cached roughness damping factor for cmSP reuse }
  end;

  TCalcLayers = array of TCalcLayer;

  TCalcModelSoA = record
    Count: Integer;
    eRe, eIm: TFloatArray;
    L, s, ro: TFloatArray;
    eRatio, s2: TFloatArray;
    procedure SetCount(N: Integer);
    procedure CopyFrom(const Layers: TCalcLayers);
  end;

  TCalcScratchSoA = record
    Count: Integer;
    KRe, KIm: TFloatArray;
    RFRe, RFIm: TFloatArray;
    RRe, RIm: TFloatArray;
    RoughFactor: TFloatArray;
    procedure SetCount(N: Integer);
  end;

  TFuncProfileRec = record
    public
      Func: TFunctionForm;
      Subj: TParameterType;
      LayerID: Word;
      StackID: Word;
      C: TPolyArray;

      { The period number of the next layer this profile applies to: 1, 2,
        3... in the order PrepareLayers walks the model (from the surface).
        ResetX starts the count again; PrepareLayers calls it for every
        profile before each pass, so a model generated more than once - a
        Lambda scan generates it once per wavelength - counts from 1 every
        time, whichever layer of the model the profile sits on. }
      function X(const i: Word): Word;
      procedure ResetX;
      function Ord: Word;
      procedure Assign(const Data: PProjectData);
      function PIndex: Word;
    private
       IntX: Word;
  end;

  TProfileFunctions = array of TFuncProfileRec;

  TMaterial = record
    Name: string;
    ro, am, tl: single;
    f: TComplex;
  end;

  TFitValue = record
    Paired: Boolean;
    Fixed: Boolean;   // does not move in the next fit; min/max keep their range
    V, min, max: single;
    procedure New(const Val: single);
    procedure Init(const dev: single); overload;
    procedure Init(const AMin, AMax: single); overload;
    procedure Init; overload;
    procedure Seed;
  end;

  TLayerData = record
    Material: string;
    P: array [1..3] of TFitValue;
    StackID, LayerID, Index: Word;
    PP: array [1..3] of TFloatArray;
  public
    procedure ClearProfiles(const p: Word);
    procedure AddProfilePoint(const Val: Single; Index: Word);
    function ProfileFromString(const p: Word; Profile: string): string;
    function ProfileToString(const Subj: TParameterType): string;
    { The value parameter Param (1 = H, 2 = sigma, 3 = rho) takes in period Period
      (from 1) of a stack repeated N times, before any gradient: the table
      value when tables are expanded (a non-periodic profile is enabled), the
      stack is periodic, Param is not paired and the table covers all N periods;
      the layer's own value otherwise. A table shorter than N - left over
      after N was raised - is ignored as a whole rather than read past its end.
      TXRCStructure.Model and every profile plot go through here. }
    function PeriodValue(const Param, Period, N: Integer; const ExpandTables: Boolean): Single;
  end;

  TLayersData = array of TLayerData;
  PLayersData = ^TLayersData ;

  TDataPoint = record
    t, r: single;
  end;

  TDataArray = array of TDataPoint;

  TMaterialsList = array of record
                        Name: string;
                     StackID: word;
                     LayerID: word;
                   end;

  // Fitting data types


  TFitStack = record
    ID: integer;
    N: integer;
    D: single;
    Header: string;
    Layers: array of TLayerData;
  end;

  TFitStructure = record
    Stacks: array of TFitStack;
    Subs: TLayerData;
    function Total: Word;
    function TotalNP: Word;

    procedure CopyContent(var Dest: TFitStructure);
  end;

const
  /// TFitValue index -> the name the fit engines and the MCP report it under.
  FIT_PARAM_NAMES: array[1..3] of string = ('thickness', 'sigma', 'density');

type
  /// Raised by TLFPSO_BASE.Run for a structure with an inverted fit range.
  EInvertedRange = class(Exception);

  /// One layer parameter whose fit range is inverted (min > max). Indices are
  /// the GUI's: stack, layer within the stack, and P[1..3].
  TInvertedRange = record
    StackIdx, LayerIdx, Param: Integer;
    RangeMin, RangeMax: Single;
  end;

/// Every layer parameter of S whose range is inverted (min > max), in GUI
/// order. A pinned parameter (min = max) is not inverted. Frozen parameters
/// are listed too: the periodic engine does not read Fixed, so their range is
/// what it would fit. The substrate is not listed; the engines do not fit it.
/// The GUI stores ranges without checking them, so a project file can carry
/// one (a density range pasted onto the wrong layer, say).
function InvertedRanges(const S: TFitStructure): TArray<TInvertedRange>;

/// 'stack "W-B4C" (0) layer 1 "B4C": the density range is inverted, min 14 > max 2.5'
function InvertedRangeText(const S: TFitStructure; const R: TInvertedRange): string;

implementation

{ TProjectData }

function TProjectData.IsModel: Boolean;
begin
  Result := (Group = gtModel) and (RowType = prItem);
end;

function TProjectData.IsFitExtension: Boolean;
begin
  Result := (RowType = prExtension) and FromFit;
end;

function TProjectData.PolyD: TPolyArray;
var
  i: Integer;
begin
  SetLength(Result, PolyCount + 1);
  for I := 0 to High(Result) do
    Result[i] := Poly[i];
end;

procedure TProjectData.SetPoly(var PolyD: TPolyArray);
var
  i: Integer;
begin
  if High(PolyD) < 10 then
    PolyCount := High(PolyD)
  else
    PolyCount := 9;
  for I := 0 to PolyCount do
    Poly[i] := PolyD[i];
end;

{ TCalcModelSoA }

procedure TCalcModelSoA.SetCount(N: Integer);
begin
  Count := N;
  SetLength(eRe, N);
  SetLength(eIm, N);
  SetLength(L, N);
  SetLength(s, N);
  SetLength(ro, N);
  SetLength(eRatio, N);
  SetLength(s2, N);
end;

procedure TCalcModelSoA.CopyFrom(const Layers: TCalcLayers);
var
  i: Integer;
begin
  SetCount(Length(Layers));
  for i := 0 to Count - 1 do
  begin
    eRe[i] := Layers[i].e.Re;
    eIm[i] := Layers[i].e.Im;
    L[i] := Layers[i].L;
    s[i] := Layers[i].s;
    ro[i] := Layers[i].ro;
    eRatio[i] := Layers[i].eRatio;
    s2[i] := Layers[i].s2;
  end;
end;

{ TCalcScratchSoA }

procedure TCalcScratchSoA.SetCount(N: Integer);
begin
  Count := N;
  SetLength(KRe, N);
  SetLength(KIm, N);
  SetLength(RFRe, N);
  SetLength(RFIm, N);
  SetLength(RRe, N);
  SetLength(RIm, N);
  SetLength(RoughFactor, N);
end;

{ TFitValue }

procedure TFitValue.Init(const AMin, AMax: single);
begin
  min := AMin;
  max := AMax;
end;

procedure TFitValue.Init;
begin
  min := V;
  max := V;
end;

procedure TFitValue.New(const Val: single);
begin
  V := Val;
  min := 0;
  max := 0;
  Paired := False;
  Fixed := False;
end;

procedure TFitValue.Seed;
begin
  V := Min + Random * (Max - min);
end;

procedure TFitValue.Init(const dev: single);
begin
  min := V * (1 - dev);
  max := V * (1 + dev);
end;

procedure TFitStructure.CopyContent(var Dest: TFitStructure);
var
  i, j, p: Integer;
begin
  SetLength(Dest.Stacks, Length(Stacks));
  for i := 0 to High(Stacks) do
  begin
    Dest.Stacks[i].ID := Stacks[i].ID;
    Dest.Stacks[i].N := Stacks[i].N;
    Dest.Stacks[i].D := Stacks[i].D;
    Dest.Stacks[i].Header := Stacks[i].Header;
    SetLength(Dest.Stacks[i].Layers, Length(Stacks[i].Layers));
    for j := 0 to High(Stacks[i].Layers) do
    begin
      Dest.Stacks[i].Layers[j] := Stacks[i].Layers[j];
      for p := 1 to 3 do
        Dest.Stacks[i].Layers[j].PP[p] := Copy(Stacks[i].Layers[j].PP[p]);
    end;
  end;
  Dest.Subs := Subs;
  for p := 1 to 3 do
    Dest.Subs.PP[p] := Copy(Subs.PP[p]);
end;

{ TFitPeriodicStructure }

function InvertedRanges(const S: TFitStructure): TArray<TInvertedRange>;
var
  i, j, p, n: Integer;
begin
  SetLength(Result, 0);
  n := 0;
  for i := 0 to High(S.Stacks) do
    for j := 0 to High(S.Stacks[i].Layers) do
      for p := 1 to 3 do
        if S.Stacks[i].Layers[j].P[p].min > S.Stacks[i].Layers[j].P[p].max then
        begin
          SetLength(Result, n + 1);
          Result[n].StackIdx := i;
          Result[n].LayerIdx := j;
          Result[n].Param    := p;
          Result[n].RangeMin := S.Stacks[i].Layers[j].P[p].min;
          Result[n].RangeMax := S.Stacks[i].Layers[j].P[p].max;
          Inc(n);
        end;
end;

function InvertedRangeText(const S: TFitStructure; const R: TInvertedRange): string;
begin
  Result := Format('stack "%s" (%d) layer %d "%s": the %s range is inverted, min %.6g > max %.6g',
    [S.Stacks[R.StackIdx].Header, R.StackIdx, R.LayerIdx,
     S.Stacks[R.StackIdx].Layers[R.LayerIdx].Material, FIT_PARAM_NAMES[R.Param],
     R.RangeMin, R.RangeMax], TFormatSettings.Invariant);
end;

function TFitStructure.Total: Word;
var
  i: Word;
begin
  Result := 0;
  for I := 0 to High(Stacks) do
    Result := Result + Length(Stacks[i].Layers);
end;

{ TFitStructure }

function TFitStructure.TotalNP: Word;
var
  i: Word;
begin
  Result := 0;
  for I := 0 to High(Stacks) do
    Result := Result + Length(Stacks[i].Layers) * Stacks[i].N;
end;

{ TLayerData }

procedure TLayerData.ClearProfiles;
begin
  SetLength(PP[p], 0);
end;

procedure TLayerData.AddProfilePoint(const Val: Single; Index: Word);
begin
  Insert(Val, PP[Index], MaxInt);
end;

function TLayerData.ProfileFromString(const p: Word; Profile: string): string;
var
  i, k: Integer;
  val: single;
begin
  i := 1;
  while i < Length(Profile) do
  begin
    k := Pos(';', Profile, i);
    { Every character up to the separator: until 2026-09-25 this read
      k - i - 1 of them and dropped the last written digit, so a table saved
      as 15.4579 came back as 15.457. }
    val := StrToFloat(copy(Profile, i, k - i));
    Insert(Val, PP[p], MaxInt);
    i := k + 1;
  end;
end;

function TLayerData.ProfileToString(const Subj: TParameterType): string;
var
  i, p: Integer;
  Val : single;
begin
  Result := '';
  p := Ord(Subj) + 1;
  for I := 0 to High(PP[p]) do
  begin
    Val := PP[p][i];
    Result := Format('%s%*.*f;',[Result, 5, 4, Val])
  end;
end;

function TLayerData.PeriodValue(const Param, Period, N: Integer; const ExpandTables: Boolean): Single;
begin
  if ExpandTables and (N > 1) and not P[Param].Paired and (Length(PP[Param]) >= N) then
    Result := PP[Param][Period - 1]
  else
    Result := P[Param].V;
end;

{ TFuncProfileRec }

procedure TFuncProfileRec.Assign(const Data: PProjectData);
begin
  LayerID := Data.LayerID;
  StackID := Data.StackID;
  Subj := Data.Subj;
  C := Data.PolyD;
end;

function TFuncProfileRec.Ord: Word;
begin
  Result := High(C);
end;

procedure TFuncProfileRec.ResetX;
begin
  IntX := 0;
end;

function TFuncProfileRec.PIndex: Word;
begin
  Result := System.Ord(Subj) + 1;
end;

function TFuncProfileRec.X(const i: Word): Word;
begin
  Inc(IntX);
  Result := IntX;
end;

end.
