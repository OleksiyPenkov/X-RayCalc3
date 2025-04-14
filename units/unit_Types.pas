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
          case ExtType: TExtentionType of
            etFunction:
              (StackID: integer;
               LayerID: integer;
               Poly: array [0..10] of single;
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
         RangeSeed: Boolean;
      MaxPOrder: Integer;
          Ksxr : Single;
     PolyFactor: Integer;
         Smooth: Boolean;
   SmoothWindow: ShortInt;
  end;

  // Calculation data types

  TCalcLayer = record
    Name: string;
    e: TComplex; { Epsilon }
    L, s, ro: single; { Thickness, sigma}
    K: TComplex; { kappa }
    RF, r: TComplex; { Френелевский коэф. }
    LayerID, StackID: Word;
  end;

  TCalcLayers = array of TCalcLayer;

  TFuncProfileRec = record
    public
      Func: TFunctionForm;
      Subj: TParameterType;
      LayerID: Word;
      StackID: Word;
      C: TPolyArray;

      function X(const i: Word): Word;
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
    function ProfileFromSrting(const p: Word; Profile: string): string;
    function ProfileToSrting(const Subj: TParameterType): string;
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



implementation

{ TProjectData }

function TProjectData.IsModel: Boolean;
begin
  Result := (Group = gtModel) and (RowType = prItem);
end;

function TProjectData.PolyD: TPolyArray;
var
  i: Integer;
begin
  SetLength(Result, Trunc(Poly[10] + 1));
  for I := 0 to High(Result) do
    Result[i] := Poly[i];
end;

procedure TProjectData.SetPoly(var PolyD: TPolyArray);
var
  i: Integer;
begin
  for I := 0 to High(PolyD) do
  begin
    Poly[i] := PolyD[i];
    if i = 10 then Break;
  end;
  Poly[10] := High(PolyD);
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
begin
  Dest.Stacks := Copy(Stacks, 0, MaxInt);
  Dest.Subs := Subs;
end;

{ TFitPeriodicStructure }

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

function TLayerData.ProfileFromSrting(const p: Word; Profile: string): string;
var
  i, k: Integer;
  val: single;
begin
  i := 1;
  while i < Length(Profile) do
  begin
    k := Pos(';', Profile, i);
    val := StrToFloat(copy(Profile, i, k - i - 1));
    Insert(Val, PP[p], MaxInt);
    i := k + 1;
  end;
end;

function TLayerData.ProfileToSrting(const Subj: TParameterType): string;
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
  Result := Trunc(C[10]);
end;

function TFuncProfileRec.PIndex: Word;
begin
  Result := System.Ord(Subj) + 1;
end;

function TFuncProfileRec.X(const i: Word): Word;
begin
  if i = 1 then IntX := 0;
  Inc(IntX);
  Result := IntX;
end;

end.
