 (* *****************************************************************************
  *
  *   X-Ray Calc CMD
  *
  *   Copyright (C) 2001-2022 Oleksiy Penkov
  *   e-mail: oleksiy.penkov@gmail.com
  *
  ****************************************************************************** *)

unit cmd_unit_calc;

interface

uses
//  FastMM4,
  Classes,
  cmd_unit_types,
  math_complex,
  OtlParallel,
  OtlCollections,
  OtlCommon,
  GpLists,
  OtlSync,
  System.SysUtils,
  cmd_unit_materials,
  unit_universal_refcalc;

type

  TThreadCalcParams = record
                  StartTeta, EndTeta, Step: single;
                  N: integer;
                  N0: integer
                end;

  TCalc = class(TObject)
    private
      ThreadCalcParams: array of TThreadCalcParams;

      FData: TDataArray;
      FResult: TDataArray;

      FLayeredModel: TLayeredModel;
      FLimit: single;

      FCD: TCalcParams;

      Tasks: array of TProc;
      NThreads : byte;
      FChiSquare: single;
      FChiSquarePlain: single;

      procedure CalcLambda(StartL, EndL, Theta: single; N: integer);
      procedure CalcTet(const Params: TThreadCalcParams);
      procedure CalcFollowModel(const Params: TThreadCalcParams);

      procedure RunThetaThreads;
      procedure Convolute(Width: single);
      procedure PrepareWorkers;


    public
      constructor Create;
      destructor Destroy; override;
      procedure Run;
      function CalcChiSquare: Single;
      function  RefCalc(t, Lambda:single; ALayers: TLayers): single;

      property CalcData: TCalcParams read FCD write FCD;
      property Results: TDataArray read FResult;
      property Model: TLayeredModel read FLayeredModel write FLayeredModel;
      property ExpValues: TDataArray read FData write FData;
      property ChiSquare: single read FChiSquare;
      property ChiSquarePlain: single read FChiSquarePlain;
  end;

implementation

uses
  Math,
  cmd_math_globals;

  { TCalc }

function TCalc.CalcChiSquare: Single;
var
  i: Integer;
  Bare, Plain: Single;
begin
  Result := 0;
  Plain := 0;
  for I := 0 to High(FResult) do
  begin
    Bare := Sqr((Log10(FData[i].r) - Log10(FResult[i].r))/Log10(FResult[i].r));
    // The bare data-to-fit disagreement, reported beside the angle-weighted
    // sum that is actually minimised
    Plain := Plain + Bare;
    Result := Result + Bare * Exp(FData[i].t);
  end;

  FChiSquare := Result;
  FChiSquarePlain := Plain;
end;

procedure TCalc.PrepareWorkers;
var
  N, i: Integer;
  dt, step: single;
begin
  {$IFDEF DEBUG}
    NThreads := 1;
  {$ELSE}
    NThreads := Environment.Process.Affinity.Count;
  {$ENDIF}

  SetLength(Tasks, NThreads);
  SetLength(ThreadCalcParams,  NThreads);

  N := FCD.N div NThreads;
  dt := (FCD.EndT - FCD.StartT) / NThreads;
  step := dt / N;

  for i := 0 to NThreads - 1 do
  begin
    ThreadCalcParams[i].StartTeta := FCD.StartT + i * dt;
    ThreadCalcParams[i].EndTeta := FCD.StartT + (i + 1) * dt;
    ThreadCalcParams[i].Step :=  step;
    ThreadCalcParams[i].N0 := N * i;
    ThreadCalcParams[i].N := N;
  end;

  SetLength(FResult, 0);
  SetLength(FResult, NThreads * N);
end;


procedure TCalc.CalcLambda;
var
  i: integer;
  Step: single;
  R: single;
  L: single;
  LayeredModel: TLayeredModel;
  Layers: TLayers;
 begin
  LayeredModel := TLayeredModel.Create;

  try
    Step := (EndL - StartL) / N;
    SetLength(FResult, N);
    for i := 0 to N - 1 do
    begin
      L := StartL + i * Step;
      LayeredModel.CalcOpticalConstants(L);
      Layers := LayeredModel.Layers;
      FResult[i].t := L;
      R := RefCalc(Theta, L, Layers);
      if R > FLimit then
        FResult[i].R := R
      else
        FResult[i].R := FLimit;
    end;
  finally
    LayeredModel.Free;
  end;
end;

procedure TCalc.CalcFollowModel;
var
  i: integer;
  R: single;
  Layers: TLayers;
begin
  Layers :=FLayeredModel.Layers;
  for i := 0 to Params.N - 1 do
  begin
    FResult[Params.N0 + i].t := FData[Params.N0 + i].t;
    R := RefCalc((FResult[Params.N0 + i].t) / FCD.K, FCD.Lambda, Layers);
    if R > FLimit then
      FResult[Params.N0 + i].R := R
    else
      FResult[Params.N0 + i].R := FLimit;
  end;
end;


procedure TCalc.CalcTet;
var
  i: integer;
  R: single;
  Layers: TLayers;
begin
  Layers :=FLayeredModel.Layers;
  for i := 0 to Params.N - 1 do
  begin
    FResult[Params.N0 + i].t := Params.StartTeta + i * Params.Step;
    R := RefCalc((FResult[Params.N0 + i].t) / FCD.K, FCD.Lambda, Layers);
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
  inherited;
end;

procedure TCalc.RunThetaThreads;
begin
  try
    if FData <> nil then
    begin
      FCD.N := High(FData) + 1;
      PrepareWorkers;
      Parallel.ForEach(0, NThreads - 1, 1)
        .Execute(
            procedure(const elem:Integer)
            begin
              CalcFollowModel(ThreadCalcParams[elem]);
            end);
    end
    else begin
      PrepareWorkers;
      Parallel.ForEach(0, NThreads - 1, 1)
        .Execute(
            procedure(const elem:Integer)
            begin
              CalcTet(ThreadCalcParams[elem]);
            end);
    end;
    if FCD.DT <> 0 then
     Convolute(FCD.DT * FCD.K);
  finally

  end;
end;

procedure TCalc.Run;
begin
   case FCD.Mode of
    cmTheta : begin
                FLayeredModel.CalcOpticalConstants(FCD.Lambda);
                RunThetaThreads;
              end;
    cmLambda: begin
                CalcLambda(FCD.StartL, FCD.EndL, FCD.Theta, FCD.N);
//                Convolute(FCD.DW);
              end;
  end;
end;

{ Delegates to unit_universal_refcalc.RefCalcStandalone, extracted from this
  method: same roughness functions, the same use of FCD.RF/FCD.P, and the
  same order of the S and P passes - only the RF source differed (this
  method read FCD.RF directly; RefCalcStandalone takes it as a parameter).
  Both now carry the cancellation-free (eps - 1) + sin^2(grazing) form, as
  TCalc.RefCalc in Shared/Math/unit_calc.pas (precision-followups, Task 5). }
function TCalc.RefCalc(t, Lambda:single; ALayers: TLayers): single;
begin
  Result := RefCalcStandalone(t, Lambda, ALayers, FCD.P, FCD.RF);
end;

procedure TCalc.Convolute(Width: single);
var
  Sum, delta, t1, c: single;
  i, N, k, p, Size: integer;
  sqr_Width: Single;

  Temp: TDataArray;

  function Gauss(const c, x, sqr_Width: single): single; inline;
  begin
    Result := c * exp(-2 * sqr(x) / sqr_Width);
  end;

begin
  if Width = 0 then Exit;

  Size := Length(FResult);
  Width := Width * 0.849;
  sqr_Width := sqr(Width);
  c := 1 / (Width * sqrt(Pi/2));

  delta := (FResult[Size - 1].t - FResult[0].t)/Size;
  N := Round(0.1 / delta);
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
