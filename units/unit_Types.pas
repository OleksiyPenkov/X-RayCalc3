unit unit_Types;

interface

uses
  SysUtils, VCLTee.Series, Graphics, math_complex;

type

  TFloatArray = array of Single;
  TIntArray = array of Integer;

  TRoughnessFunction = (rfError, rfExp, rfLinear, rfStep, rfSinus);
  TCalcMode = (cmTheta, cmLambda, cmTest);
  TPolarisation = (cmS, cmSP);

  TProjectGroupType = (gtModel, gtData);
  TProjRowType = (prGroup, prItem, prFolder, prExtension);
  TExtentionType = (etNone, etGradient, etProfile);
  TFunctionForm = (ffNone, ffLine, ffExp, ffParabolic, ffSQRT);
  TParameterType = (gsL, gsS, gsRo);

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
            etGradient:
              (StackID: integer;
               LayerID: integer;
               a, b, c: single;
               Form: TFunctionForm;
               Subj: TParameterType;
               );
            etProfile:
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
        CFactor: Boolean;
      MaxPOrder: Integer;
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

  TFunctionRec = record
    f: TFunctionForm;
    a, b, c: single;
  end;

  TGradientRec = record
    Func: TFunctionRec;
    Subj: TParameterType;
    NL: Integer;
    LayerID: integer;
    StackID: integer;
    Count: Integer;
  end;
  TGradients = array of TGradientRec;

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
    H, s, r: TFitValue;
    StackID, LayerID: integer;
    PH, PS, PR: TFloatArray;
  public
    procedure ClearProfiles;
    procedure AddProfilePoint(const H, s, r: Single);
    function ProfileFromSrting(const Subj: TParameterType;
      Profile: string): string;
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
begin
  SetLength(PH, 0);
  SetLength(PS, 0);
  SetLength(PR, 0);
end;

procedure TLayerData.AddProfilePoint(const H, s, r: Single);
begin
  Insert(H, PH, MaxInt);
  Insert(s, PS, MaxInt);
  Insert(r, PR, MaxInt);
end;

function TLayerData.ProfileFromSrting(const Subj: TParameterType;
  Profile: string): string;
var
  i, p: Integer;
  val: single;
begin
  i := 1; p := Pos(';', Profile);
  while i < Length(Profile) do
  begin
    p := Pos(';', Profile, i);
    val := StrToFloat(copy(Profile, i, p - i - 1));
    case Subj of
      gsL:    Insert(Val, PH, MaxInt);
      gsS:    Insert(Val, PS, MaxInt);
      gsRo:   Insert(Val, PR, MaxInt);
    end;
    i := p + 1;
  end;
end;

function TLayerData.ProfileToSrting(const Subj: TParameterType): string;
var
  i: Integer;
  Val : single;
begin
  Result := '';
  for I := 0 to High(PH) do
  begin
    case Subj of
      gsL:  Val := PH[i];
      gsS:  Val := PS[i];
      gsRo: Val := PR[i];
    end;
    Result := Format('%s%f;',[Result, Val])
  end;
end;

end.
