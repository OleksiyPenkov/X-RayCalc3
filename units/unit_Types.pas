unit unit_Types;

interface

uses
  SysUtils, VCLTee.Series, Graphics, math_complex;

type

  TFloatArray = array of Single;
  TIntArray = array of Integer;
  TPolyArray = array [0..10] of single;

  TRoughnessFunction = (rfError, rfExp, rfLinear, rfStep, rfSinus);
  TCalcMode = (cmTheta, cmLambda, cmTest);
  TPolarisation = (cmS, cmSP);

  TProjectGroupType = (gtModel, gtData);
  TProjRowType = (prGroup, prItem, prFolder, prExtension);
  TExtentionType = (etNone, etFunction, etArb, etRough);
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
               Poly: TPolyArray;
               Form: TFunctionForm;
               Subj: TParameterType;
               );
            etArb:
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

         Shake : boolean;
    ThetaWieght: integer;
       AdaptVel: Boolean;
         RangeSeed: Boolean;
      MaxPOrder: Integer;
          Ksxr : Single;
  end;

  // Calculation data types

  TCalcLayer = record
    Name: string;
    e: TComplex; { Epsilon }
    L, s, ro: single; { Thickness, sigma}
    K: TComplex; { kappa }
    RF, r: TComplex; { Френелевский коэф. }
    LayerID, StackID: integer;
  end;


  TCalcLayers = array of TCalcLayer;

  TFuncProfileRec = record
    public
      Func: TFunctionForm;
      Subj: TParameterType;
      LayerID: integer;
      StackID: integer;
      C: TPolyArray;

      function X(const i: integer): Integer;
      function Ord: Integer;
      procedure Assign(const Data: PProjectData);
      function PIndex: Integer;
    private
       IntX: Integer;
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
    StackID, LayerID, Index: integer;
    PP: array [1..3] of TFloatArray;
  public
    procedure ClearProfiles;
    procedure AddProfilePoint(const H, s, r: Single);
    function ProfileFromSrting(const p: integer; Profile: string): string;
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
                     StackID: integer;
                     LayerID: integer;
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
    function Total: integer;
    function TotalNP: integer;
  end;



implementation

{ TProjectData }

function TProjectData.IsModel: Boolean;
begin
  Result := (Group = gtModel) and (RowType = prItem);
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

{ TFitPeriodicStructure }

function TFitStructure.Total: integer;
var
  i: integer;
begin
  Result := 0;
  for I := 0 to High(Stacks) do
    Result := Result + Length(Stacks[i].Layers);
end;

{ TFitStructure }

function TFitStructure.TotalNP: integer;
var
  i: integer;
begin
  Result := 0;
  for I := 0 to High(Stacks) do
    Result := Result + Length(Stacks[i].Layers) * Stacks[i].N;
end;

{ TLayerData }

procedure TLayerData.ClearProfiles;
var
  p: Integer;
begin
  for p := 1 to 3 do
    SetLength(PP[p], 0);
end;

procedure TLayerData.AddProfilePoint(const H, s, r: Single);
begin
  Insert(H, PP[1], MaxInt);
  Insert(s, PP[2], MaxInt);
  Insert(r, PP[3], MaxInt);
end;

function TLayerData.ProfileFromSrting(const p: integer; Profile: string): string;
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
    Result := Format('%s%f;',[Result, Val])
  end;
end;

{ TFuncProfileRec }

procedure TFuncProfileRec.Assign(const Data: PProjectData);
begin
  LayerID := Data.LayerID;
  StackID := Data.StackID;
  Subj := Data.Subj;
  C := Data.Poly;
end;

function TFuncProfileRec.Ord: Integer;
begin
  Result := Trunc(C[10]);
end;

function TFuncProfileRec.PIndex: Integer;
begin
  Result := System.Ord(Subj) + 1;
end;

function TFuncProfileRec.X(const i: integer): Integer;
begin
  if i = 1 then IntX := 0;
  Inc(IntX);
  Result := IntX;
end;

end.
