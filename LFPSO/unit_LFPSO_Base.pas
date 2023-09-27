(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_LFPSO_Base;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows;

const
  WM_CHI_UPDATE = WM_STR_BASE + 100;

type

  PUpdateFitProgressMsg = ^TUpdateFitProgressMsg ;
  TUpdateFitProgressMsg  = record
    LastChi : single;
    BestChi : single;
    Step    : integer;
    Curve   : TDataArray;
  end;

  TLayerIndexes = array [1..3] of SmallInt;
  TIndexes  = array of TLayerIndexes;

  TLFPSO_BASE = class
    protected
      FCalc: TCalc;

      FReInit : Boolean;
      FFitParams: TFitParams;
      FCalcParams: TCalcThreadParams;
      FStructure: TFitStructure;  // initial (input) structure

      FLayersCount: integer;
      FMaterials: TMaterials;

      X, V : TPopulation;  // solutions and velocityes
      Xmax : TPopulation; // 1 column for upper boundary
      Xmin : TPopulation; // 1 column for lower boundary
      Xrange : TPopulation;   // 1 column for delta X

      Vmax, VMin: TPopulation; // 1 column for min/max velocity

      pbest: TSolution; // best local solution
      gbest: TSolution; // best global solution
      abest: TSolution;

      FLastBestChiSqr  : single;
      FLastWorseChiSQR : single;
      FGlobalBestChiSqr: single;
      FAbsoluteBestChiSqr: single;
      FJammingCount    : integer;


      FTMax: integer;
      FPopulation: integer;
      FData, FResultingCurve: TDataArray;
      FLimit: single;
      FTerminated: Boolean;
      FMovAvg: TDataArray;
      CFactor: single;

      function FindTheBest: Boolean;
      function GetResult: TLayeredModel; virtual;

      function LevyWalk(const X, gBest: single): single;
      procedure SendUpdateMessage(const Step: integer);
      procedure CheckLimits(const i, j, k: integer); virtual;
      procedure SetParams(const Value: TFitParams); virtual;
      procedure Init(const Step: integer); //inline;
      function Omega(const t, TMax: integer): single; inline;
      procedure SetDomain(const Count, Order: integer; var X: TPopulation);

      procedure InitVelocity; virtual;
      procedure UpdatePSO(const t: integer); virtual;
      procedure UpdateLFPSO(const t: integer); virtual;
      procedure RangeSeed;virtual;
      procedure XSeed;virtual;
      procedure SetStructure(const Inp: TFitStructure); virtual;
      procedure UpdateStructure(Solution:TSolution); virtual;
      function FitModelToLayer(Solution: TSolution): TLayeredModel; virtual;
      procedure Set_Init_X(const LIndex, PIndex: Integer; Val: TFitValue);
      procedure Init_Domains(const Order: Integer);
      procedure ApplyCFactor(var c1, c2: single);// inline;
      function Rand(const dx: Single): single;
      function GetPolynomes: TProfileFunctions; virtual;
    private
     procedure Shake(const t: integer; var  SuccessCount, ReInitCount: integer; Vmax0, Ksxr0: single);
     procedure SendUpdateStep(const Step: integer);
     procedure CalcSolution(const X: TSolution);

    public
      constructor Create;
      destructor Destroy; override;

      property Materials: TMaterials read FMaterials write FMaterials;
      property Structure: TFitStructure read FStructure write SetStructure;
      property Result : TLayeredModel read GetResult;
      property ExpValues: TDataArray read FData write FData;
      property Limit: single write FLimit;
      property Params: TFitParams write SetParams;
      property MovAvg: TDataArray read FMovAvg write FMovAvg;
      property Polynomes:TProfileFunctions read GetPolynomes;

      procedure Run(CalcConditions: TCalcThreadParams); virtual;
      procedure Terminate;

  end;

  function Gamma( x : single) : single;
  procedure MultiplyVector(const X: TPopulation; v: single; var Result: TPopulation);
  function RS: integer;

const
  w_max = 0.9;
  w_min = 0.4;
  MaxC = 10;
  a = 0.5;
  eps = 1;

implementation

uses
  Forms,
  System.SysUtils,
  Neslib.FastMath,
  unit_helpers,
  Dialogs;

{ Supplementary}

function Gamma( x : single) : single;
const COF : array [0..14] of single =
                (  0.999999999999997092, // may as well include this in the array
                  57.1562356658629235,
                 -59.5979603554754912,
                  14.1360979747417471,
                 -0.491913816097620199,
                  0.339946499848118887e-4,
                  0.465236289270485756e-4,
                 -0.983744753048795646e-4,
                  0.158088703224912494e-3,
                 -0.210264441724104883e-3,
                  0.217439618115212643e-3,
                 -0.164318106536763890e-3,
                  0.844182239838527433e-4,
                 -0.261908384015814087e-4,
                  0.368991826595316234e-5);
const
  K = 2.5066282746310005;
  PI_OVER_K = PI / K;
var
  j : integer;
  tmp, w, ser : single;
  reflect : boolean;
begin
  reflect := (x < 0.5);
  if reflect then w := 1.0 - x else w := x;
  tmp := w + 5.2421875;
  tmp := (w + 0.5) * FastLn(tmp) - tmp;
  ser := COF[0];
  for j := 1 to 14 do ser := ser + COF[j]/(w + j);
  try
    if reflect then
      result := PI_OVER_K * w * FastExp(-tmp) / (FastSin(PI*x) * ser)
    else
      result := K * FastExp(tmp) * ser / w;
  except
    raise Exception.CreateFmt(
        'Gamma(%g) is undefined or out of floating-point range', [x]);
  end;
end;


procedure MultiplyVector(const X: TPopulation; v: single; var Result: TPopulation);
var
  i, j, k, p: integer;
begin
  for I := 0 to High(X) do                  // for every member of the population
    for j := 0 to High(X[i]) do             // for every layer
      for k := 1 to 3 do                    // for H, s, rho
        for p := 0 to High(X[i][j][k]) do
          Result[i][j][k][p] := X[i][j][k][p] * v;
end;

function RS: integer;
begin
  Result := 1 - Random(2);
  if Result = 0 then
       Result := 1;
end;

{ TLFPSO }

function TLFPSO_BASE.Rand(const dx: Single):single;
begin
  Result := (-1 + 2 * Random) * dx;
end;

procedure TLFPSO_BASE.XSeed;
begin

end;

function TLFPSO_BASE.Omega(const t, TMax: integer): single;
begin
  Result := FFitParams.w1 + FFitParams.w2 * (1 - t / Tmax);
end;

constructor TLFPSO_BASE.Create;
begin
  inherited ;
end;

procedure ClearArray(var A: TPopulation); inline;
begin
  Finalize(A);
end;

procedure ClearSolution(var A: TSolution); inline;
begin
//  SetLength(A, 0);
  Finalize(A);
end;

destructor TLFPSO_BASE.Destroy;
begin
  ClearArray(X);
  ClearArray(V);
  ClearArray(Xmax);
  ClearArray(Xmin);
  ClearArray(Vmax);
  ClearArray(Vmin);
  ClearArray(XRange);

  ClearSolution(pbest);
  ClearSolution(abest);
  ClearSolution(gbest);
  inherited;
end;

function TLFPSO_BASE.FitModelToLayer(Solution: TSolution): TLayeredModel;
var
  i, k, j, p, LayerIndex: Integer;
  Data: TLayersData;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  LayerIndex := 0;
  for I := 0 to High(FStructure.Stacks) do
  begin
    SetLength(Data, 0);
    SetLength(Data, Length(FStructure.Stacks[i].Layers));
    for k := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      Data[k].Material := FStructure.Stacks[i].Layers[k].Material;
      for p := 1 to 3 do
        Data[k].P[p].V := Solution[LayerIndex][p][0];

      Data[k].StackID := FStructure.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := FStructure.Stacks[i].Layers[k].LayerID;
      Inc(LayerIndex);
    end;

    for j := 1  to FStructure.Stacks[i].N do
      Result.AddLayers(-1, Data);
  end;

  SetLength(Data, 1);
  Data[0].Material := FStructure.Subs.Material;
  Data[0].P :=FStructure.Subs.P;


  Result.AddSubstrate(Data);
end;

function TLFPSO_BASE.GetPolynomes: TProfileFunctions;
begin

end;

function TLFPSO_BASE.GetResult: TLayeredModel;
begin
  Result := FitModelToLayer(abest);
end;

procedure TLFPSO_BASE.InitVelocity;
begin

end;

procedure TLFPSO_BASE.ApplyCFactor(var c1, c2: single);
begin
  if FFitParams.AdaptVel and (CFactor > 0) then
  begin
    c1 := CFactor;
    c2 := CFactor;
  end else
  begin
    c1 := 1;
    c2 := 1;
  end;
end;

procedure TLFPSO_BASE.CheckLimits(const i, j, k: integer);
begin
  if V[i][j][k][0] > Vmax[0][j][k][0] then
             V[i][j][k][0] := Vmax[0][j][k][0];

  if V[i][j][k][0] < Vmin[0][j][k][0] then
             V[i][j][k][0] := Vmin[0][j][k][0];

  X[i][j][k][0] := X[i][j][k][0] + V[i][j][k][0];

  if X[i][j][k][0] > Xmax[0][j][k][0] then
             X[i][j][k][0] := Xmax[0][j][k][0];

  if X[i][j][k][0] < Xmin[0][j][k][0] then
             X[i][j][k][0] := Xmin[0][j][k][0];

  if X[i][j][k][0] < 0 then ShowMessage(Format('%d %d %d',[i,j,k]));

end;

function TLFPSO_BASE.LevyWalk(const X, gBest: single): single;
const
  beta = 1.5;
var
  dX, S: double;
  num, den, sigma_u: double;
  u, v, z: double;
begin
  num := gamma(1 + beta) * FastSin(pi * beta / 2); // used for Numerator
  den := gamma(( 1 + beta)/2) * beta * FastPower(2, (beta-1)/2); // used for Denominator
  sigma_u := FastPower(num / den, 1 / beta); // Standard deviation

  u := Random * sigma_u;
  v := Random;
  z := u/ abs(FastPower(v, 1/ beta));

  S := 0.01 * z * (X - gBest);
  dX := X * S;
  Result := dX * Random;
end;


procedure TLFPSO_BASE.CalcSolution;
begin
  try
    FCalc := TCalc.Create;
    FCalc.Params    := FCalcParams;
    FCalc.ExpValues := FData;
    FCalc.MovAvg    := FMovAvg;
    FCalc.Limit     := FLimit;

    FCalc.Model := FitModelToLayer(X);
    if Length(FMaterials) <> 0 then
      FCalc.Model.Materials := FMaterials;    // loading from cache

    FCalc.Run;

    if Length(FMaterials) = 0 then
      FMaterials := FCalc.Model.Materials;    // saving to cache

    FCalc.CalcChiSquare(FFitParams.ThetaWeight);

    if FCalc.ChiSQR < FLastBestChiSqr then
    begin
      FLastBestChiSqr  := FCalc.ChiSQR;
      FResultingCurve := FCalc.Results;
      pbest := Copy(X, 0, MaxInt);
    end;

    if FCalc.ChiSQR > FLastWorseChiSQR then
      FLastWorseChiSQR :=  FCalc.ChiSQR;
  finally
    FreeAndNil(FCalc);
  end;
end;

function TLFPSO_BASE.FindTheBest: boolean;
var
  i : integer;
begin
  Result := False;
  FLastBestChiSqr  := 1e12;
  FLastWorseChiSQR := 0;

  for i := 0 to High(X) do
  begin
    CalcSolution(X[i]);
    Application.ProcessMessages;
    if FTerminated then Break;
  end;

//  CFactor := eps + (FGlobalBestChiSqr- FLastBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr);
  CFactor := 1;  // left for future

  if FLastBestChiSqr <  FGlobalBestChiSqr then
  begin
    FGlobalBestChiSqr := FLastBestChiSqr;
    gbest := Copy(pbest, 0, MaxInt);
    if FGlobalBestChiSqr < FAbsoluteBestChiSqr  then
    begin
      FAbsoluteBestChiSqr := FGlobalBestChiSqr;
      abest := Copy(gbest, 0, MaxInt);
      CalcSolution(abest);
      Result := True;
    end ;
  end
  else begin
    SetLength(FResultingCurve, 0);
    Inc(FJammingCount);
  end;
end;

procedure TLFPSO_BASE.Init(const Step: integer);
begin
  FJammingCount := 0;

  if (Step = 0) and FFitParams.RangeSeed then
    RangeSeed
  else
    XSeed;

  InitVelocity;
  FindTheBest;

  if Step = 0 then
    SendUpdateMessage(Step);
end;

procedure TLFPSO_BASE.Shake(const t: integer; var  SuccessCount, ReInitCount: integer; Vmax0, Ksxr0: single);
var
  TmpStructure: TFitStructure;
begin
  FReInit := True;
  if ReInitCount > FFitParams.ReInitMax then
  begin
    ReInitCount := 0;
    gbest := Copy(abest, 0, MaxInt);   // recover to absolute best solution
    FGlobalBestChiSqr := FAbsoluteBestChiSqr;
    FFitParams.Vmax := Vmax0;
    FFitParams.Ksxr := Ksxr0;
  end
  else
  begin
    FGlobalBestChiSqr := FGlobalBestChiSqr  * FFitParams.KChiSqr;
    FFitParams.Vmax := FFitParams.Vmax * FFitParams.KVmax;
    FFitParams.Ksxr := FFitParams.Ksxr * FFitParams.KVmax;
    Inc(ReInitCount);
    dec(SuccessCount);
  end;
  UpdateStructure(gbest);        // re-init based on current global best solution
  TmpStructure := FStructure;
  SetStructure(TmpStructure);    // Don't use X[0] = abest! The full re-set is requred

  Init(t);
  FJammingCount := 0;
end;

procedure TLFPSO_BASE.Run;
var
  t: integer;
  switch: double;
  ReInitCount: integer;
  Vmax0, Ksxr0: single;
  SuccessCount: integer;
begin
  Randomize;

  FReInit := False;
  FTerminated := False;
  Vmax0 := FFitParams.Vmax ;
  Ksxr0 := FFitParams.Ksxr ;
  ReInitCount := 0;
  SuccessCount := 0;
  FGlobalBestChiSqr:= 1e12;
  FAbsoluteBestChiSqr := 1e12;
  FCalcParams := CalcConditions;
  SetLength(FMaterials, 0);

  Init(0);

  for t := 1 to FTMax do
  begin
    if FTerminated then Break;
    Randomize;

    switch := Random;
    if switch < 0.5 then
      UpdatePSO(SuccessCount)
    else
      UpdateLFPSO(SuccessCount);

    if FindTheBest then
       SendUpdateMessage(t)
    else
      SendUpdateStep(t);

    if FGlobalBestChiSqr < FFitParams.Tolerance then Break;

    if FFitParams.Shake and (FJammingCount > FFitParams.JammingMax) then
      Shake(t, SuccessCount, ReInitCount, Vmax0, Ksxr0)
    else begin
      FFitParams.Vmax := Vmax0;
      FFitParams.Ksxr := Ksxr0;
      inc(SuccessCount);
    end;
  end;
//  ShowMessage(Format('%f %f %f',[abest[0][1][0], abest[0][1][1], FAbsoluteBestChiSqr]));
  UpdateStructure(abest);  // don't delete!
end;

procedure TLFPSO_BASE.RangeSeed;
begin

end;

procedure TLFPSO_BASE.SendUpdateMessage(const Step: integer);
var
  msg_prm: PUpdateFitProgressMsg;
begin
  New(msg_prm);
  msg_prm.LastChi := FGlobalBestChiSqr;
  msg_prm.BestChi := FAbsoluteBestChiSqr;
  msg_prm.Step := Step;
  msg_prm.Curve := FResultingCurve;

  PostMessage(
    Application.MainFormHandle,
    WM_CHI_UPDATE,
    LPARAM(msg_prm),
    0
  );
  Application.ProcessMessages;
end;

procedure TLFPSO_BASE.SendUpdateStep(const Step: integer);
var
  msg_prm: PUpdateFitProgressMsg;
begin
  New(msg_prm);
  msg_prm.LastChi := FGlobalBestChiSqr;
  msg_prm.BestChi := FAbsoluteBestChiSqr;
  msg_prm.Step := Step;
  msg_prm.Curve := nil;

  PostMessage(
    Application.MainFormHandle,
    WM_CHI_UPDATE,
    LPARAM(msg_prm),
    0
  );
  Application.ProcessMessages;
end;

procedure TLFPSO_BASE.SetDomain(const Count, Order: integer; var X: TPopulation);
var
  i, j, k: integer;
begin
  SetLength(X, FPopulation);
  for I := 0 to High(X) do
  begin
    SetLength(X[i], Count);
    for j := 0 to Count - 1 do
      for k := 1 to 3 do
      SetLength(X[i][j][k], Order + 1);
  end;
end;

procedure TLFPSO_BASE.SetParams(const Value: TFitParams);
begin
  FFitParams := Value;

  FTMax := FFitParams.NMax;
  FPopulation := FFitParams.Pop;

  SetLength(Xmax, 1);
  SetLength(Xmin, 1);
  SetLength(Vmax, 1);
  SetLength(Vmin, 1);
  SetLength(Xrange, 1);
end;

procedure TLFPSO_BASE.SetStructure(const Inp: TFitStructure);
begin

end;

procedure TLFPSO_BASE.Terminate;
begin
  FTerminated := True;
end;

procedure TLFPSO_BASE.UpdateLFPSO(const t: integer);
begin

end;

procedure TLFPSO_BASE.UpdatePSO(const t: integer);
begin

end;


procedure TLFPSO_BASE.UpdateStructure(Solution: TSolution);
var
  i, j, p, LayerIndex: integer;
begin
  LayerIndex := 0;
  for i := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
        FStructure.Stacks[i].Layers[j].P[p].V := Solution[LayerIndex][p][0];
      Inc(LayerIndex);
    end;
  end;
end;

procedure TLFPSO_BASE.Set_Init_X(const LIndex, PIndex: Integer; Val: TFitValue);
begin
       X[0][LIndex][PIndex][0] := Val.V;
    Xmax[0][LIndex][PIndex][0] := Val.max;
    Xmin[0][LIndex][PIndex][0] := Val.min;
  Xrange[0][LIndex][PIndex][0] := Xmax[0][LIndex][PIndex][0] - Xmin[0][LIndex][PIndex][0];
end;

procedure TLFPSO_BASE.Init_Domains;
begin
  SetDomain(FLayersCount, Order, X);
  SetDomain(FLayersCount, Order, Xmax);
  SetDomain(FLayersCount, Order, Xmin);
  SetDomain(FLayersCount, Order, Xrange);
  SetDomain(FLayersCount, Order, Vmin);
  SetDomain(FLayersCount, Order, Vmax);
  SetDomain(FLayersCount, Order, V);
end;

end.
