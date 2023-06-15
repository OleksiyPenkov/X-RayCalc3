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

  TVector = array of single;   // Array of layer parameters

  TSolution = array [1..3] of TVector; // H, Sigma, rho x N Layers

  TPopulation = array of TSolution;

  TLFPSO_BASE = class
    protected
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

      function XtoStructure(const Index: integer): TFitStructure;
      procedure FindTheBest;
      function GetResult: TLayeredModel;

      function LevyWalk(const X, gBest: single): single;
      procedure SendUpdateMessage(const Step: integer);
      procedure CheckLimits(const i, j, k: integer); inline;
      procedure SetParams(const Value: TFitParams);
      procedure ReInit(const Step: integer); //inline;
      function Omega(const t, TMax: integer): single; inline;
      procedure SetDomain(const Count: integer; var X: TPopulation);

      procedure InitVelocity; virtual;
      procedure UpdatePSO(const t: integer); virtual;
      procedure UpdateLFPSO(const t: integer); virtual;
      procedure Seed;virtual;
      procedure SetStructure(const Inp: TFitStructure); virtual;
      function GBestStructure(best: TSolution): TFitStructure; virtual;
      function GetStructure: TFitStructure;
    private


    public
      constructor Create;
      destructor Destroy; override;

      property Materials: TMaterials read FMaterials write FMaterials;
      property Structure: TFitStructure read GetStructure write SetStructure;
      property Result : TLayeredModel read GetResult;
      property ExpValues: TDataArray read FData write FData;
      property Limit: single write FLimit;
      property Params: TFitParams write SetParams;
      property MovAvg: TDataArray read FMovAvg write FMovAvg;

      procedure Run(CalcConditions: TCalcThreadParams);
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
  c1m = 1.49445;
  c2m = 1.49445;


implementation

uses
  unit_FitHelpers,
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
  i, j, k: integer;
begin
  for I := 0 to High(X) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[i][j]) do // for every layer
        Result[i][j][k] := X[i][j][k] * v;
end;

function RS: integer;
begin
  Result := 1 - Random(2);
  if Result = 0 then
       Result := 1;
end;

{ TLFPSO }

function TLFPSO_BASE.Omega(const t, TMax: integer): single;
begin
  Result := FFitParams.w1 + FFitParams.w2 * (1 - t / Tmax);
end;

constructor TLFPSO_BASE.Create;
begin
  inherited ;
end;

destructor TLFPSO_BASE.Destroy;
begin

  inherited;
end;

function TLFPSO_BASE.GetResult: TLayeredModel;
begin
  Result := ExpandPeriodicFitModel(GBestStructure(abest));
end;

function TLFPSO_BASE.GetStructure: TFitStructure;
begin
  Result := GBestStructure(abest);
end;

procedure TLFPSO_BASE.InitVelocity;
begin

end;

procedure TLFPSO_BASE.CheckLimits(const i, j, k: integer);
begin
  if V[i][j][k] > Vmax[0][j][k] then
             V[i][j][k] := Vmax[0][j][k];

  if V[i][j][k] < Vmin[0][j][k] then
             V[i][j][k] := Vmin[0][j][k];

  X[i][j][k] := X[i][j][k] + V[i][j][k];

  if X[i][j][k] > Xmax[0][j][k] then
             X[i][j][k] := Xmax[0][j][k];

  if X[i][j][k] < Xmin[0][j][k] then
             X[i][j][k] := Xmin[0][j][k];
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



procedure TLFPSO_BASE.FindTheBest;
var
  i, Result: integer;
  Calc: TCalc;
begin
  FLastBestChiSqr  := 1e12;
  FLastWorseChiSQR := 0;

  for i := 0 to High(X) do
  begin
    if FTerminated then Break;
    try
      Calc := TCalc.Create;
      Calc.Params    := FCalcParams;
      Calc.ExpValues := FData;
      Calc.MovAvg    := FMovAvg;
      Calc.Limit     := FLimit;

      Calc.Model := ExpandPeriodicFitModel(XtoStructure(i));
      Calc.Model.Materials := FMaterials;
      Calc.Run;
      Calc.CalcChiSquare(FFitParams.ThetaWieght);

      if Calc.ChiSQR < FLastBestChiSqr then
      begin
        FLastBestChiSqr  := Calc.ChiSQR;
        FResultingCurve := Calc.Results;
        Result := i;
      end;

      if Calc.ChiSQR > FLastWorseChiSQR then
        FLastWorseChiSQR :=  Calc.ChiSQR;
    finally
      FreeAndNil(Calc);
      Application.ProcessMessages;
    end;
  end;

  pbest := X[Result];

  if FLastBestChiSqr <  FGlobalBestChiSqr then
  begin
    FGlobalBestChiSqr := FLastBestChiSqr;
    gbest := X[Result];
  end
  else begin
    SetLength(FResultingCurve, 0);
    Inc(FJammingCount);
  end;

  if FGlobalBestChiSqr < FAbsoluteBestChiSqr  then
  begin
    FAbsoluteBestChiSqr := FGlobalBestChiSqr;
    abest := X[Result];
  end;
end;

procedure TLFPSO_BASE.ReInit(const Step: integer);
begin
  FJammingCount := 0;

  Seed;
  InitVelocity;
  FindTheBest;

  SendUpdateMessage(Step);
end;


procedure TLFPSO_BASE.Run;
var
  t: integer;
  switch: double;
  ReInitCount: integer;
  Vmax0: single;
  SuccessCount: integer;
begin
  FReInit := False;
  FTerminated := False;
  Vmax0 := FFitParams.Vmax ;
  ReInitCount := 0;
  SuccessCount := 0;
  FGlobalBestChiSqr:= 1e12;
  FAbsoluteBestChiSqr := 1e12;
  FCalcParams := CalcConditions;
  SetLength(FMaterials, 0);

  ReInit(0);

  for t := 1 to FTMax do
  begin
    if FTerminated then Break;

    switch := Random;
    if switch < 0.5 then
      UpdatePSO(SuccessCount)
    else
      UpdateLFPSO(SuccessCount);

    FindTheBest;
    SendUpdateMessage(t);
    if FGlobalBestChiSqr < FFitParams.Tolerance then Break;

    if FFitParams.Shake and (FJammingCount > FFitParams.JammingMax) then
    begin
      FReInit := True;
      if ReInitCount > FFitParams.ReInitMax then
      begin
        ReInitCount := 0;
        SetStructure(GBestStructure(abest));
        gbest := abest;
        FGlobalBestChiSqr := FAbsoluteBestChiSqr;
        FFitParams.Vmax := Vmax0;
      end
      else
      begin
        SetStructure(GBestStructure(gbest));
        FGlobalBestChiSqr := FGlobalBestChiSqr  * FFitParams.KChiSqr;
        FFitParams.Vmax := FFitParams.Vmax * FFitParams.KVmax;
      end;
      ReInit(t);
      Inc(ReInitCount);
      FJammingCount := 0;
      dec(SuccessCount);
    end
    else begin
      abest := gbest;
      inc(SuccessCount);
    end;
  end;
end;

procedure TLFPSO_BASE.Seed;
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

procedure TLFPSO_BASE.SetDomain(const Count: integer; var X: TPopulation);
var
  i: integer;
begin
  for I := 0 to High(X) do
  begin
    SetLength(X[i][1], Count);
    SetLength(X[i][2], Count);
    SetLength(X[i][3], Count);
  end;
end;

procedure TLFPSO_BASE.SetParams(const Value: TFitParams);
begin
  FFitParams := Value;

  FTMax := FFitParams.NMax;
  FPopulation := FFitParams.Pop;

  SetLength(X, FPopulation);
  SetLength(V, FPopulation);

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

function TLFPSO_BASE.XtoStructure(const Index: integer): TFitStructure;
var
  i, j, LayerIndex: integer;
begin
  Result := FStructure;
  LayerIndex := 0;
  for i := 0 to High(Result.Stacks) do
  begin
    for j := 0 to High(Result.Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[j].H.V := X[Index][1][LayerIndex];
      Result.Stacks[i].Layers[j].s.V := X[Index][2][LayerIndex];
      Result.Stacks[i].Layers[j].r.V := X[Index][3][LayerIndex];
      Inc(LayerIndex);
    end;
  end;
end;

function TLFPSO_BASE.GBestStructure(best: TSolution): TFitStructure;
var
  i, j, LayerIndex: integer;
begin
  Result := FStructure;
  LayerIndex := 0;
  for i := 0 to High(Result.Stacks) do
  begin
    for j := 0 to High(Result.Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[j].H.V := best[1][LayerIndex];
      Result.Stacks[i].Layers[j].s.V := best[2][LayerIndex];
      Result.Stacks[i].Layers[j].r.V := best[3][LayerIndex];
      Inc(LayerIndex);
    end;
  end;
end;

end.
