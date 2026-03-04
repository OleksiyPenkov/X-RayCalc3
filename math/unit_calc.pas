 (* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
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
    protected
      CalcParams: array of TCalcParams;

      FData: TDataArray;
      FResult: TDataArray;
      FTemp: TDataArray;
      FMovAvg: TDataArray;

      FLayeredModel: TLayeredModel;

      FLimit: single;

      FParams: TCalcThreadParams;

      FTotalD: single;
      FChiSQR: single;

      Tasks: array of TProc;
      NThreads : integer;

      FTail: Integer;
      FConvWeights: array of Single;
      FConvN: Integer;
      FWorkersReady: Boolean;
      FMaxThreads: Integer;
      FLogData: array of Single;
      FLogDataReady: Boolean;

      function  RefCalc(const ATheta, c1, c2: single;
        const AModel: TCalcModelSoA; var AScratch: TCalcScratchSoA): single;
      procedure CalcLambda(StartL, EndL, Theta: single; N: integer);
      procedure CalcTet(const Params: TCalcParams);
      procedure RunThetaThreads;
      procedure Convolute(Width: single);
      procedure PrepareWorkers;
      procedure Restore(const N1, N2: integer); inline;
      procedure MVA(const N1, N2: integer); inline;
    public
      constructor Create;
      destructor Destroy; override;
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
      property MaxThreads: Integer read FMaxThreads write FMaxThreads;
  end;

implementation

uses
  math_globals, unit_SeriesIO, unit_Config, unit_sys_helpers;

const
  InvTwoLn10 = 0.2171472409516259;       // 1/(2*ln(10)), for ln-to-log10 conversion
  FWHMToGaussianWidth = 0.849;            // 1/sqrt(2*ln(2)), FWHM to Gaussian width

  { TCalc }

procedure ClearArray(var A: TDataArray); inline;
begin
  Finalize(A);
end;

function Log10(const Val: single): single; inline;
begin
  Result := InvTwoLn10 * FastLn(Val);
end;


function TCalc.CalcChiSquare(const ThetaWieght: integer): single;
var
  i: Integer;
  Chi: single;
  LogResult: single;

  UseWeight: boolean;
  Ratio: single;

begin
  // Pre-compute Log10 of experimental data once — FData never changes during fitting
  if not FLogDataReady then
  begin
    SetLength(FLogData, Length(FData));
    for i := 0 to High(FData) do
      FLogData[i] := Log10(FData[i].r);
    FLogDataReady := True;
  end;

  UseWeight := Length(FMovAvg) > 1;

  Result := 0;
  for I := FTail  to High(FData) - FTail - 1 do
  begin
    if FResult[i].r = 0 then Continue;

    LogResult := Log10(FResult[i].r);
    Chi := Sqr((FLogData[i] - LogResult) / LogResult);
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
  Result := FChiSQR;
end;


procedure TCalc.PrepareWorkers;
var
  Count, j, n: Integer;
  dt, step: single;
begin
  if FWorkersReady then Exit;

  if FMaxThreads > 0 then
    NThreads := FMaxThreads
  else
    NThreads := GetNThreads;

  SetLength(Tasks, NThreads);
  SetLength(CalcParams,  NThreads);

  if Length(FData) < 1 then
  begin
    Count := FParams.N div NThreads;
    dt := (FParams.EndT - FParams.StartT) / NThreads;
    step := dt / Count;

    for n := 0 to NThreads - 1 do
    begin
      CalcParams[n].StartTeta := FParams.StartT + n * dt;
      CalcParams[n].EndTeta := FParams.StartT + (n + 1) * dt;
      CalcParams[n].Step :=  step;
      CalcParams[n].N0 := Count * n;
      CalcParams[n].N := Count;
      CalcParams[n].UseData := False;
    end;

    SetLength(FResult, NThreads * Count);
  end
  else begin
    Count := Length(FData) div NThreads;
    for n := 0 to NThreads - 2 do
    begin
      CalcParams[n].StartTeta := 0;
      CalcParams[n].EndTeta   := 0;
      CalcParams[n].Step      := 0;
      CalcParams[n].N0 := Count * n;
      CalcParams[n].N := Count;
      CalcParams[n].UseData := True;

      SetLength(CalcParams[n].Points, Count + 1);
      for j := 0 to Count do
       CalcParams[n].Points[j] := FData[CalcParams[n].N0 + j].t;
    end;

    CalcParams[NThreads - 1].UseData := True;
    CalcParams[NThreads - 1].N0 := Count * (NThreads - 1) ;
    CalcParams[NThreads - 1].N := Length(FData) - Count * (NThreads - 1);
    SetLength(CalcParams[NThreads - 1].Points, CalcParams[NThreads - 1].N);
      for j := 0 to CalcParams[NThreads - 1].N - 1 do
       CalcParams[NThreads - 1].Points[j] := FData[CalcParams[NThreads - 1].N0 + j].t;

    SetLength(FResult, Length(FData));
  end;

  FWorkersReady := True;
end;

procedure TCalc.CalcLambda;
var
  i, j: integer;
  Step: single;
  R, c1, c2: single;
  L: single;
  Layers: TCalcLayers;
  Model: TCalcModelSoA;
  Scratch: TCalcScratchSoA;
begin
  Step := (EndL - StartL) / N;
  SetLength(FResult, N);
  Scratch.Count := 0;
  for i := 0 to N - 1 do
  begin
    L := StartL + i * Step;
    FLayeredModel.Generate(L);
    Layers := FLayeredModel.Layers;
    // Precompute per-layer constants for this lambda
    for j := 0 to Length(Layers) - 2 do
    begin
      Layers[j].eRatio := AbsZ(DivZZ(Layers[j].e, Layers[j + 1].e));
      Layers[j + 1].s2 := Sqr(Layers[j + 1].s) * 0.50299;
    end;
    // Transpose AoS -> SoA
    Model.CopyFrom(Layers);
    if Scratch.Count <> Model.Count then
      Scratch.SetCount(Model.Count);
    // Compute wave constants per lambda
    c1 := 4 * Pi / L;
    c2 := c1 * 0.5;
    FResult[i].t := L;
    R := RefCalc(Theta, c1, c2, Model, Scratch);
    if R > FLimit then
      FResult[i].R := R
    else
      FResult[i].R := FLimit;
  end;
end;

procedure TCalc.CalcTet;
var
  i: integer;
  R, c1, c2: single;
  Layers: TCalcLayers;
  Model: TCalcModelSoA;
  Scratch: TCalcScratchSoA;
begin
  if NThreads <= 1 then
    Layers := FLayeredModel.LayersDirect  // single thread — no copy needed
  else
    Layers := FLayeredModel.Layers;  // multi-thread — each thread needs its own copy

  // Precompute per-layer constants — depend only on model, not on theta
  for i := 0 to Length(Layers) - 2 do
  begin
    Layers[i].eRatio := AbsZ(DivZZ(Layers[i].e, Layers[i + 1].e));
    Layers[i + 1].s2 := Sqr(Layers[i + 1].s) * 0.50299; { sqr(sigma/1.41) for rfError }
  end;

  // Transpose AoS -> SoA once before angle loop
  Model.CopyFrom(Layers);
  Scratch.SetCount(Model.Count);

  // Precompute wave constants — constant across all angles
  c1 := 4 * Pi / FParams.Lambda;
  c2 := c1 * 0.5;

  for i := 0 to Params.N - 1 do
  begin
    if Params.UseData then
       FResult[Params.N0 + i].t := Params.Points[i]
    else
      FResult[Params.N0 + i].t := Params.StartTeta + i * Params.Step;

    R := RefCalc((FResult[Params.N0 + i].t) / FParams.K, c1, c2, Model, Scratch);
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

destructor TCalc.Destroy;
begin
  ClearArray(FData);
  ClearArray(FResult);
  ClearArray(FTemp);
  ClearArray(FMovAvg);

  if FLayeredModel <> nil then
    FLayeredModel.Free;

  Finalize(Tasks);
  Finalize(CalcParams);
  Finalize(FConvWeights);
  Finalize(FLogData);
  inherited;
end;

procedure TCalc.RunThetaThreads;
var
  Config: IOmniTaskConfig;
begin
  FLayeredModel.Generate(FParams.Lambda);
  FTotalD := FLayeredModel.TotalD;

  PrepareWorkers;

  if NThreads = 1 then
    CalcTet(CalcParams[0])
  else begin
    Config := Parallel.TaskConfig;
    Config.SetPriority(tpHighest);

    Parallel.ForEach(0, NThreads - 1, 1)
        .TaskConfig(Config)
        .Execute(
            procedure(const elem:System.Integer)
            begin
              CalcTet(CalcParams[elem]);
            end);
  end;
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

function TCalc.RefCalc(const ATheta, c1, c2: single;
  const AModel: TCalcModelSoA; var AScratch: TCalcScratchSoA): single;
var
  Rs, Rp, Rsp, s1, sin_t, cos_t, sqr_sin_t, t: single;

  function TotalRecursiveRefraction: single;
  var
    i: integer;
    L2, expVal, sinP, cosP: single;
    Rn, a1, a2, b1, b2, RFi, Ri: TComplex;
  begin
    for i := AModel.Count - 2 downto 0 do
    begin
      { Fused: MulRZ(2L, K) * i -> ExpZ -> MulZZ(R, .) }
      L2 := AModel.L[i + 1] * 2;
      expVal := FastExp(-L2 * AScratch.KIm[i + 1]);
      FastSinCos(L2 * AScratch.KRe[i + 1], sinP, cosP);
      Rn.Re := AScratch.RRe[i + 1];
      Rn.Im := AScratch.RIm[i + 1];
      a1.Re := expVal * (Rn.Re * cosP - Rn.Im * sinP);
      a1.Im := expVal * (Rn.Re * sinP + Rn.Im * cosP);

      RFi.Re := AScratch.RFRe[i];
      RFi.Im := AScratch.RFIm[i];
      b1 := AddZZ(RFi, a1);
      a2 := MulZZ(RFi, a1);
      b2 := AddZR(a2, 1);
      Ri := DivZZ(b1, b2);
      AScratch.RRe[i] := Ri.Re;
      AScratch.RIm[i] := Ri.Im;
    end;
    Result := Sqr(AScratch.RRe[0]) + Sqr(AScratch.RIm[0]);
  end;

  function Roughness(const RF: TRoughnessFunction; const sigma, s2, s: single): single; inline;
  begin
    case RF of
      rfError:
        Result := FastExp(-s2 * sqr(s));
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
      else
        Result := 0;
    end;
  end;

  procedure LayerAmplitudeRefractionS;    { Reflection coefficient Rs }
  var
    i: integer;
    Ki, Ki1, b1, b2, RF: TComplex;
    sv, rfVal: single;
  begin
    for i := 0 to AModel.Count - 2 do
    begin
      Ki.Re := AScratch.KRe[i];
      Ki.Im := AScratch.KIm[i];
      Ki1.Re := AScratch.KRe[i + 1];
      Ki1.Im := AScratch.KIm[i + 1];
      b1 := SubZZ(Ki, Ki1);
      b2 := AddZZ(Ki, Ki1);
      RF := DivZZ(b1, b2);
      s1 := Abs(1 - (AModel.eRatio[i] * sqr_sin_t));
      sv := c1 * sqrt(cos_t * sqrt(s1));

      rfVal := Roughness(FParams.RF, AModel.s[i + 1], AModel.s2[i + 1], sv);
      AScratch.RoughFactor[i] := rfVal; { cache for P-polarization reuse }
      RF := MulRZ(rfVal, RF);
      AScratch.RFRe[i] := RF.Re;
      AScratch.RFIm[i] := RF.Im;
    end;
  end;

  procedure LayerAmplitudeRefractionP;      { Reflection coefficient Rp }
  var
    i: integer;
    Ki, Ki1, ei, ei1, a1, a2, b1, b2, RF: TComplex;
  begin
    for i := 0 to AModel.Count - 2 do
    begin
      Ki.Re := AScratch.KRe[i];
      Ki.Im := AScratch.KIm[i];
      Ki1.Re := AScratch.KRe[i + 1];
      Ki1.Im := AScratch.KIm[i + 1];
      ei.Re := AModel.eRe[i];
      ei.Im := AModel.eIm[i];
      ei1.Re := AModel.eRe[i + 1];
      ei1.Im := AModel.eIm[i + 1];
      a1 := DivZZ(Ki, ei);
      a2 := DivZZ(Ki1, ei1);
      b1 := SubZZ(a1, a2);
      b2 := AddZZ(a1, a2);
      RF := DivZZ(b1, b2);

      RF := MulRZ(AScratch.RoughFactor[i], RF); { reuse cached factor }
      AScratch.RFRe[i] := RF.Re;
      AScratch.RFIm[i] := RF.Im;
    end;
  end;

  procedure FresnelCoefficients;   { Fresnel coefficients }
  var
    i: integer;
    a1, K: TComplex;
  begin
    for i := 0 to AModel.Count - 1 do
    begin
      a1 := SqrtZ(AddZR(ToComplex(AModel.eRe[i], AModel.eIm[i]), -sqr_sin_t));
      K := MulRZ(c2, a1);
      AScratch.KRe[i] := K.Re;
      AScratch.KIm[i] := K.Im;
    end;
  end;

begin
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
  i, N, k, Size, WinSize: integer;
  sqr_Width: Single;
begin
  FTail := 0;
  if Width = 0 then Exit;

  Size := Length(FResult);

  // Compute Gaussian weights once — reuse across all subsequent calls
  if Length(FConvWeights) = 0 then
  begin
    Width := Width * FWHMToGaussianWidth;
    sqr_Width := sqr(Width);
    c := 1 / (Width * sqrt(Pi/2));

    delta := (FResult[Size - 1].t - FResult[0].t)/Size;
    N := Round(0.1/ delta);
    if frac(N / 2) = 0 then
      N := N - 1;

    WinSize := 2 * N + 1;
    SetLength(FConvWeights, WinSize);
    t1 := -0.1;
    for k := 0 to WinSize - 1 do
    begin
      FConvWeights[k] := Gauss(c, t1, sqr_Width) * delta;
      t1 := t1 + delta;
    end;
    FConvN := N;
  end;

  N := FConvN;
  WinSize := Length(FConvWeights);

  if Length(FTemp) <> Size then
    SetLength(FTemp, Size);

  for i := N to Size - N - 1 do
  begin
    Sum := 0;
    for k := 0 to WinSize - 1 do
      Sum := Sum + FResult[i - N + k].r * FConvWeights[k];
    FTemp[i].t := FResult[i].t;
    FTemp[i].R := Sum;
  end;

  Restore(0, N - 1);
  MVA(Size - N, Size - 1);

  Move(FTemp[0], FResult[0], Size * SizeOf(TDataPoint));
  FTail := N;
end;

initialization


finalization


end.
