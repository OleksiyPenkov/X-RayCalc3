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
  TGradientSubject = (gsL, gsS, gsRo);

  PProjectData = ^TProjectdata;
  TProjectData = record
    Title: string;
    Group: TProjectGroupType;
    Description: string;

    function IsModel:Boolean;

    case RowType: TProjRowType of
      prGroup, prFolder:
        ();
      prItem:
        (ID: integer;
         Curve: TLineSeries;
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
               Subj: TGradientSubject;
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

  TLayer = record
    Name: string;
    e: TComplex; { Epsilon }
    L, s, ro: single; { Thickness, sigma}
    K: TComplex; { kappa }
    RF, r: TComplex; { Френелевский коэф. }
    LID: byte;
  end;


  TLayers = array of TLayer;

  TFunctionRec = record
    f: (fNone, fLine, fExp, fParabolic, fFiting);
    a, b, c: single;
  end;

  TGradientRec = record
    Rate: single;
    Form: TGradientForm;
    Subj: TGradientSubject;
    ParentPeriod: string;
    ParentLayer: string;
  end;
  TGradients = array of TGradientRec;

  TMaterial = record
    Name: string;
    ro, am, tl: single;
    f: TComplex;
    H, s: TFunctionRec;
  end;

  TDataPoint = record
    t, r: single;
  end;

  TDataArray = array of TDataPoint;

implementation

{ TProjectData }

function TProjectData.IsModel: Boolean;
begin
  Result := (Group = gtModel) and (RowType = prItem);
end;

end.
