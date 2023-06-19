 (* *****************************************************************************
  *
  *   X-Ray Calc 3
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
                  N0: integer;
                  UseData: boolean;
                  Points: array of Single;
                end;

  TCalc = class(TObject)
    private
      CalcParams: array of TCalcParams;

      FData: TDataArray;
      FResult: TDataArray;
      FTemp: TDataArray;

      FLayeredModel: TLayeredModel;

      FLimit: single;

      FParams: TCalcThreadParams;

      FTotalD: single;
      FChiSQR: single;

      Tasks: array of TProc;
      NThreads : byte;
      FMovAvg: TDataArray;
      FTail: Integer;

      function  RefCalc(const ATheta, Lambda:single; ALayers: TCalcLayers): single;
      procedure CalcLambda(StartL, EndL, Theta: single; N: integer);
      procedure CalcTet(const Params: TCalcParams);
      procedure RunThetaThreads;
      procedure Convolute(Width: single);
      procedure PrepareWorkers;
      procedure Restore(const N1, N2: integer); inline;
      procedure MVA(const N1, N2: integer); inline;
    public
      constructor Create;
      destructor Free;
      procedure Run;
      function CalcChiSquare(const ThetaWieght: integer): single;

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
  math_globals, unit_helpers;

  { TCalc }
function Log10(const Val: single): single; inline;
begin
  Result := 0.2171472409516259 * FastLn(Val);
end;


function TCalc.CalcChiSquare(const ThetaWieght: integer): single;
var
  i: Integer;
  Chi: single;

  UseWeight: boolean;
  Ratio: single;

begin
  UseWeight := Length(FMovAvg) > 1;

  Result := 0;
  for I := FTail  to High(FData) - FTail - 1 do
  begin
    if FResult[i].r = 0 then Continue;

    Chi := Sqr((Log10(FData[i].r) - Log10(FResult[i].r))/Log10(FResult[i].r));
    if UseWeight  then
    begin
      Ratio := FData[i].r / FMovAvg[i].r;
      if Ratio > 3 then
        Chi := Chi * Ratio;
    end;
    case ThetaWieght of
      0: ;
      1: Chi := Chi * sqr (FResult[i].t);
      2: Chi := Chi * FResult[i].t;
      3: Chi := Chi * sqrt(FResult[i].t);
      4: Chi := Chi / sqr(FResult[i].t);
      5: Chi := Chi / sqrt(FResult[i].t);
    end;

    Result := Result + Chi;
  end;

  FChiSQR := Result / High(FData) * 1000;
end;

procedure TCalc.PrepareWorkers;
var
  N, i, j: Integer;
  dt, step: single;
begin
  NThreads := Environment.Process.Affinity.Count;
  {$IFDEF DEBUG}  NThreads := 8; {$ENDIF}

  SetLength(Tasks, NThreads);
  SetLength(CalcParams,  NThreads);
  SetLength(FResult, 0);

  if Length(FData) < 1 then
  begin
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
      CalcParams[i].UseData := False;
    end;

    SetLength(FResult, NThreads * N);
  end
  else begin
    N := Length(FData) div NThreads;
    for i := 0 to NThreads - 2 do
    begin
      CalcParams[i].StartTeta := 0;
      CalcParams[i].EndTeta   := 0;
      CalcParams[i].Step      := 0;
      CalcParams[i].N0 := N * i;
      CalcParams[i].N := N;
      CalcParams[i].UseData := True;

      SetLength(CalcParams[i].Points, N + 1);
      for j := 0 to N do
       CalcParams[i].Points[j] := FData[CalcParams[i].N0 + j].t;
    end;

    CalcParams[NThreads - 1].UseData := True;
    CalcParams[NThreads - 1].N0 := N * (NThreads - 1) ;
    CalcParams[NThreads - 1].N := Length(FData) - N * (NThreads - 1);
    SetLength(CalcParams[NThreads - 1].Points, CalcParams[NThreads - 1].N);
      for j := 0 to CalcParams[NThreads - 1].N - 1 do
       CalcParams[i].Points[j] := FData[CalcParams[NThreads - 1].N0 + j].t;

    SetLength(FResult, Length(FData));
  end;
end;

procedure TCalc.CalcLambda;
var
  i: integer;
  Step: single;
  R: single;
  L: single;
  Layers: TCalcLayers;
 begin
  Step := (EndL - StartL) / N;
  SetLength(FResult, N);
  for i := 0 to N - 1 do
  begin
    L := StartL + i * Step;
    FLayeredModel.Generate(L);
    Layers := FLayeredModel.Layers;
    FResult[i].t := L;
    R := RefCalc(Theta, L, Layers);
    if R > FLimit then
      FResult[i].R := R
    else
      FResult[i].R := FLimit;
  end;
end;

procedure TCalc.CalcTet;
var
  i: integer;
  R: single;
begin
  for i := 0 to Params.N - 1 do
  begin
    if Params.UseData then
       FResult[Params.N0 + i].t := Params.Points[i]
    else
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
  Config.SetPriority(tpHighest);

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

procedure TCalc.Restore(const N1, N2: integer);
var
  i: integer;
begin
  for i := N1 to N2 do
  begin
    FTemp[i].t := FResult[i].t;
    FTemp[i].R := FResult[i].r;
  end;
end;

procedure TCalc.MVA(const N1, N2: integer);
const
  W = 10;
var
  i, j: integer;
  S: single;
begin
  for i := N1 to N2 do
  begin
    S := 0;
    for J := i - W to i do
      S := S + FResult[j].r;
    S := S / (W + 1);

    FTemp[i].t := FResult[i].t;
    FTemp[i].R := S;
  end;
end;

function Gauss(const c, x, sqr_Width: single): single; inline;
begin
  Result := c * FastExp(-2 * sqr(x) / sqr_Width);
end;

procedure TCalc.Convolute(Width: single);
var
  Sum, delta, t1, c: single;
  i, N, k, Size: integer;
  sqr_Width: Single;
begin
  FTail := 0;
  if Width = 0 then Exit;

  Size := Length(FResult);
  Width := Width * 0.849;
  sqr_Width := sqr(Width);
  c := 1 / (Width * sqrt(Pi/2));

  delta := (FResult[Size - 1].t - FResult[0].t)/Size;
  N := Round(0.1/ delta);
  if frac(N / 2) = 0 then
    N := N - 1;

  SetLength(FTemp, Size);

  for i := N to Size - N - 1 do
  begin
    t1 := -0.1;
    Sum := 0;
    for k := i - N to i + N do
    begin
      Sum := Sum + FResult[k].r * Gauss(c, t1, sqr_Width) * delta;
      t1 := t1 + delta;
    end;
    FTemp[i].t := FResult[i].t;
    FTemp[i].R := Sum;
  end;

  Restore(0, N - 1);
  MVA(Size - N, Size - 1);

  FResult := FTemp;
  FTail := N;
end;

initialization


finalization


end.
