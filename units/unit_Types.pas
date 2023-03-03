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
         Curve: PLineSeries;
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

  TThreadParams = record
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

  // Calculation data types

  TCalcLayer = record
    Name: string;
    e: TComplex; { Epsilon }
    L, s, ro: single; { Thickness, sigma}
    K: TComplex; { kappa }
    RF, r: TComplex; { Френелевский коэф. }
    LayerID, PeriodNo: integer;
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

  TLayerData = record
    Material: string;
    H, s, r: single;
    StackID: integer;
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

implementation

{ TProjectData }

function TProjectData.IsModel: Boolean;
begin
  Result := (Group = gtModel) and (RowType = prItem);
end;

end.
