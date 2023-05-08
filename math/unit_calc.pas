 (* *****************************************************************************
  *
  *   X-Ray Calc 2
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_calc;

interface

uses
  Classes,
  Neslib.FastMath,
  unit_types,
  math_complex,
  OtlParallel,
  OtlCollections,
  OtlCommon,
  OtlTaskControl,
  OtlTask,
  GpLists,
  OtlSync,
  System.SysUtils,
  unit_materials;

type

  TCalcParams = record
                  StartTeta, EndTeta, Step: single;
                  N: integer;
                  N0: integer
                end;

  TCalc = class(TObject)
    private
      CalcParams: array of TCalcParams;

      FData: TDataArray;
      FResult: TDataArray;

      FLayeredModel: TLayeredModel;

      FLimit: single;

      FParams: TCalcThreadParams;

      FTotalD: single;
      FChiSQR: single;

      Tasks: array of TProc;
      NThreads : byte;
      FMovAvg: TDataArray;

      function  RefCalc(const ATheta, Lambda:single; ALayers: TCalcLayers): single;
      procedure CalcLambda(StartL, EndL, Theta: single; N: integer);
      procedure CalcTet(const Params: TCalcParams);
      procedure RunThetaThreads;
      procedure Convolute(Width: single);
      procedure PrepareWorkers;
    public
      constructor Create;
      destructor Free;
      procedure Run;
      function CalcChiSquare: single;

      property Params: TCalcThreadParams write FParams;
      property ExpValues: TDataArray read FData write FData;
      property MovAvg: TDataArray read FMovAvg write FMovAvg;
      property Limit: single read FLimit write FLimit;
      property Results: TDataArray read FResult;
      property TotalD: single read FTotalD;
      property ChiSQR: single read FChiSQR;
      property Model: TLayeredModel read FLayeredModel write FLayeredModel;
  end;

implementation

uses
  math_globals;

  { TCalc }
function Log10(const Val: single): single; inline;
begin
  Result := 0.2171472409516259 * FastLn(Val);
end;


function TCalc.CalcChiSquare: single;
var
  i: Integer;
  Chi: single;

  UseWeight: boolean;
  Ratio: single;

begin
  UseWeight := Length(FMovAvg) > 1;

  Result := 0;
  for I := 0 to High(FData) do
  begin
    Chi := Sqr((Log10(FData[i].r) - Log10(FResult[i].r))/Log10(FResult[i].r));
    if UseWeight  then
    begin
      Ratio := FData[i].r / FMovAvg[i].r;
      if Ratio > 3 then
        Chi := Chi * Ratio;
    end;

    Result := Result + Chi;
  end;

  FChiSQR := Result / High(FData) * 1000;
end;

procedure TCalc.PrepareWorkers;
var
  N, i: Integer;
  dt, step: single;
begin
//  {$IFDEF DEBUG}
//    NThreads := 1;
//  {$ELSE}
    NThreads := Environment.Process.Affinity.Count;
//  {$ENDIF}

  SetLength(Tasks, NThreads);
  SetLength(CalcParams,  NThreads);

  N := FParams.N div NThreads;
  dt := (FParams.EndT - FParams.StartT) / NThreads;
  step := dt / N;

  for i := 0 to NThreads - 1 do
  begin
    CalcParams[i].StartTeta := FParams.StartT + i * dt;
    CalcParams[i].EndTeta := FParams.StartT + (i + 1) * dt;
    CalcParams[i].Step :=  step;
    CalcParams[i].N0 := N * i;
    CalcParams[i].N := N;
  end;

  SetLength(FResult, 0);
  SetLength(FResult, NThreads * N);
end;

procedure TCalc.CalcLambda;
//var
//  i: integer;
//  Step: single;
//  R: single;
//  L: single;
//  LayeredModel: TLayeredModel;
//  Layers: TLayers;
 begin
//  LayeredModel := TLayeredModel.Create;
//  try
//    Step := (EndL - StartL) / N;
//    SetLength(FResult, N);
//    for i := 0 to N - 1 do
//    begin
//      L := StartL + i * Step;
//      LayeredModel.Generate(L);
//      Layers := LayeredModel.Layers;
//      FResult[i].t := L;
//      R := RefCalc(Theta, L, Layers);
//      if R > FLimit then
//        FResult[i].R := R
//      else
//        FResult[i].R := FLimit;
//    end;
//    FTotalD := LayeredModel.TotalD;
//  finally
//    LayeredModel.Free;
//  end;
end;

procedure TCalc.CalcTet;
var
  i: integer;
  R: single;
begin
  for i := 0 to Params.N - 1 do
  begin
    FResult[Params.N0 + i].t := Params.StartTeta + i * Params.Step;
    R := RefCalc((FResult[Params.N0 + i].t) / FParams.K, FParams.Lambda, FLayeredModel.Layers);
    if R > FLimit then
      FResult[Params.N0 + i].R := R
    else
      FResult[Params.N0 + i].R := FLimit;
  end;
end;

constructor TCalc.Create;
begin
  inherited Create;
  FLimit   := 1E-7;
end;

destructor TCalc.Free;
begin
  if FLayeredModel <> nil then
    FLayeredModel.Free;
end;

procedure TCalc.RunThetaThreads;
var
  Config: IOmniTaskConfig;
begin
  FLayeredModel.Generate(FParams.Lambda);
  FTotalD := FLayeredModel.TotalD;

  PrepareWorkers;

  Config := Parallel.TaskConfig;
  Config.SetPriority(tpAboveNormal);

  Parallel.ForEach(0, NThreads - 1, 1)
      .TaskConfig(Config)
      .Execute(
          procedure(const elem:Integer)
          begin
            CalcTet(CalcParams[elem]);
          end);
end;

procedure TCalc.Run;
begin
   case FParams.Mode of
    cmTheta : begin
                RunThetaThreads;
                Convolute(FParams.DT * FParams.K);
              end;
    cmLambda: begin
                CalcLambda(FParams.StartL, FParams.EndL, FParams.Theta, FParams.N);
                Convolute(FParams.DW);
              end;
  end;
end;

function TCalc.RefCalc(const ATheta, Lambda:single; ALayers: TCalcLayers): single;
var
  c1, c2, Rs, Rp, Rsp, s1, sin_t, cos_t, sqr_sin_t, t: single;

  function TotalRecursiveRefraction: single;
  var
    i: integer;
    Im: TComplex;
    a1, a2, b1, b2: TComplex;
  begin
    Im := ToComplex(0, 1);
    for i := High(ALayers) - 1 downto 0 do
    begin
      a1 := MulRZ(ALayers[i + 1].L * 2, ALayers[i + 1].K);
      a1 := MulZZ(Im, a1);
      a1 := ExpZ(a1);
      a1 := MulZZ(ALayers[i + 1].R, a1);
      b1 := AddZZ(ALayers[i].RF, a1);
      a2 := MulZZ(ALayers[i].RF, a1);
      b2 := AddZR(a2, 1);
      ALayers[i].R := DivZZ(b1, b2);
    end;
    Result := sqr(AbsZ(ALayers[0].R));
  end;

  function Roughness(const RF: TRoughnessFunction; const sigma, s: single):Single;inline;
  begin
      case RF of
        rfError:
          Result := FastExp(-1 * sqr(sigma) * sqr(s));
        rfExp:
          Result := 1 / (1 + (sqr(s) * sqr(sigma)) / 2);
        rfLinear:
          if sigma < 0.5 then
            Result := sin(sqrt(3) * sigma * s) /
              (sqrt(3) * sigma * s)
          else
            Result := 1;
        rfStep:
          Result := cos(sigma * s);
      end;
  end;

  procedure LayerAmplitudeRefractionS;     { Коэффициент отражения Rs}
  var
    i: integer;
    b1, b2: TComplex;
    s: Single;
  begin
    for i := 0 to Length(ALayers) - 2 do
    begin
      b1 := SubZZ(ALayers[i].K, ALayers[i + 1].K);
      b2 := AddZZ(ALayers[i].K, ALayers[i + 1].K);
      ALayers[i].RF := DivZZ(b1, b2);
      s1 := Abs(1 - (AbsZ(DivZZ(ALayers[i].e, ALayers[i + 1].e)) * sqr_sin_t));
      s := c1 * sqrt(cos_t * sqrt(s1));

      ALayers[i].RF := MulRZ(Roughness(FParams.RF, ALayers[i + 1].s, s), ALayers[i].RF);
    end;
  end;

  procedure LayerAmplitudeRefractionP;     { Коэффициент отражения Rp }
  var
    i: integer;
    a1, a2, b1, b2: TComplex;
    s: Single;
  begin
    for i := 0 to Length(ALayers) - 2 do
    begin
      a1 := DivZZ(ALayers[i].K, ALayers[i].e);
      a2 := DivZZ(ALayers[i + 1].K, ALayers[i + 1].e);
      b1 := SubZZ(MulRZ(1, a1), MulRZ(1, a2));
      b2 := AddZZ(MulRZ(1, a1), MulRZ(1, a2));
      ALayers[i].RF := DivZZ(b1, b2);
      s1 := Abs(1 - (AbsZ(DivZZ(ALayers[i].e, ALayers[i + 1].e)) * sqr_sin_t));
      s := c1 * sqrt(cos_t * sqrt(s1));

      ALayers[i].RF := MulRZ(Roughness(FParams.RF, ALayers[i + 1].s, s), ALayers[i].RF);
    end;
  end;

  procedure FresnelCoefficients;   { Френелевские коэффициенты (p-p) }
  var
    i: Integer;
    a1: TComplex;
  begin
    for i := 0 to Length(ALayers) - 1 do
      begin
        a1 := SqrtZ(AddZR(ALayers[i].e, -sqr_sin_t));
        ALayers[i].K := MulRZ(c2, a1);
      end;
  end;

begin
  c1 := 4 * Pi / Lambda; { волновое число }
  c2 := 2 * Pi / Lambda; {другое волновое число }
  t := Pi / 2 - Pi * ATheta / 180;

  FastSinCos(t, sin_t, cos_t);
  sqr_sin_t := sqr(sin_t);

  FresnelCoefficients;
  LayerAmplitudeRefractionS;
  Rs := TotalRecursiveRefraction;

  if FParams.P = cmSP then
  begin
    LayerAmplitudeRefractionP;
    Rp := TotalRecursiveRefraction;
    Rsp := (Rs + Rp) / 2;
    Result := Rsp;
  end
  else
    Result := Rs;
end;

procedure TCalc.Convolute(Width: single);
var
  Sum, delta, t1, c: single;
  i, N, k, p, Size: integer;
  sqr_Width: Single;

  Temp: TDataArray;

  function Gauss(const c, x, sqr_Width: single): single; inline;
  begin
    Result := c * FastExp(-2 * sqr(x) / sqr_Width);
  end;

begin
  if Width = 0 then Exit;

  Size := Length(FResult);
  Width := Width * 0.849;
  sqr_Width := sqr(Width);
  c := 1 / (Width * sqrt(Pi/2));

  delta := (FResult[Size - 1].t - FResult[0].t)/Size;
  N := Round(0.1/ delta);
  if frac(N / 2) = 0 then
    N := N - 1;

  SetLength(Temp, Size - 2*N);

  p := 0;
  for i := N to Size - N - 1 do
  begin
    t1 := -0.1;
    Sum := 0;
    for k := i - N to i + N do
    begin
      Sum := Sum + FResult[k].r * Gauss(c, t1, sqr_Width) * delta;
      t1 := t1 + delta;
    end;
    Temp[p].t := FResult[i + 1].t;
    Temp[p].R := Sum;
    inc(p);
  end;

  FResult := Temp;
end;

initialization


finalization


end.
