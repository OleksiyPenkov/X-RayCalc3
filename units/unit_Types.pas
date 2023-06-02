unit unit_Types;

interface

uses
  SysUtils, VCLTee.Series, Graphics, math_complex;

type

  TRoughnessFunction = (rfError, rfExp, rfLinear, rfStep, rfSinus);
  TCalcMode = (cmTheta, cmLambda, cmTest);
  TPolarisation = (cmS, cmSP);

  TProjectGroupType = (gtModel, gtData);
  TProjRowType = (prGroup, prItem, prFolder, prExtension);
  TExtentionType = (etNone, etGradient, etProfile);
  TGradientForm = (gtLine, gtExp, gtSin, gtCos);
  TParameterType = (gsL, gsS, gsRo);

  PLineSeries = ^TLineSeries;

  PProjectData = ^TProjectdata;
  TProjectData = record
    Title: string;
    Group: TProjectGroupType;
    Description: string;
    Data: string;
    function IsModel:Boolean;

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
              (ParentLayerName: string [40];
               ParentStackName: string [40];
               Rate: single;
               Form: TGradientForm;
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
    f: (fNone, fLine, fExp, fParabolic, fFiting);
    a, b, c: single;
  end;

  TGradientRec = record
    Rate: single;
    Form: TGradientForm;
    Subj: TParameterType;
    ParentPeriod: string;
    ParentLayer: string;
  end;
  TGradients = array of TGradientRec;

  TMaterial = record
    Name: string;
    ro, am, tl: single;
    f: TComplex;
  end;

  TFitValue = record
    V, min, max: single;
    procedure Init(const dev: single); overload;
    procedure Init(const AMin, AMax: single); overload;
    procedure Init; overload;
    procedure Seed;
  end;

  TLayerData = record
    Material: string;
    H, s, r: TFitValue;
    StackID, LayerID: integer;
  end;

  TLayersData = array of TLayerData;

  TDataPoint = record
    t, r: single;
  end;

  TDataArray = array of TDataPoint;

  TDistrtibution = record
    Name: string;
    DType: TParameterType;
    Values: array of single;
  end;

  TDistributions = array of TDistrtibution;


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

end.
