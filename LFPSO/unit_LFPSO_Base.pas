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

  TLayerIndexes = array [1..3] of Integer;
  TIndexes  = array of TLayerIndexes;

  TLayer = array [1..3] of single;   // Array of layer parameters

  TSolution = array of TLayer; // H, Sigma, rho x N Layers

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
      CFactor: single;

      procedure FindTheBest; virtual;
      function GetResult: TLayeredModel; virtual;

      function LevyWalk(const X, gBest: single): single;
      procedure SendUpdateMessage(const Step: integer);
      procedure CheckLimits(const i, j, k: integer); virtual;
      procedure SetParams(const Value: TFitParams); virtual;
      procedure Init(const Step: integer); //inline;
      function Omega(const t, TMax: integer): single; inline;
      procedure SetDomain(const Count: integer; var X: TPopulation);

      procedure InitVelocity; virtual;
      procedure UpdatePSO(const t: integer); virtual;
      procedure UpdateLFPSO(const t: integer); virtual;
      procedure Seed;virtual;
      procedure ReSeed;virtual;
      procedure SetStructure(const Inp: TFitStructure); virtual;
      procedure UpdateStructure(const Solution:TSolution); virtual;
      function FitModelToLayer(Solution: TSolution): TLayeredModel;
      procedure Set_Init_X(const LIndex, PIndex: Integer; Val: TFitValue);
      procedure Init_DomainsP;
      procedure ApplyCFactor(var c1, c2: single);// inline;
      function Rand(const dx: Single): single;
    private
     procedure Shake(var SuccessCount, ReInitCount, t: integer; Vmax0: single);



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
  c1m = 1.41;
  c2m = 1.41;


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
  i, j, k: integer;
begin
  for I := 0 to High(X) do                  // for every member of the population
    for j := 0 to High(X[i]) do             // for every layer
      for k := 1 to 3 do                    // for H, s, rho
        Result[i][j][k] := X[i][j][k] * v;
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

procedure TLFPSO_BASE.ReSeed;
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

destructor TLFPSO_BASE.Destroy;
begin

  inherited;
end;

function TLFPSO_BASE.FitModelToLayer(Solution: TSolution): TLayeredModel;
var
  i, k, j, LayerIndex: Integer;
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
      Data[k].H.V := Solution[LayerIndex][1];
      Data[k].s.V := Solution[LayerIndex][2];
      Data[k].r.V := Solution[LayerIndex][3];
      Data[k].StackID := FStructure.Stacks[i].Layers[k].StackID;
      Data[k].LayerID := FStructure.Stacks[i].Layers[k].LayerID;
      Inc(LayerIndex);
    end;

    for j := 1  to FStructure.Stacks[i].N do
      Result.AddLayers(-1, Data);
  end;

  SetLength(Data, 1);
  Data[0].Material := FStructure.Subs.Material;
  Data[0].s := FStructure.Subs.s;
  Data[0].r := FStructure.Subs.r;

  Result.AddSubstrate(Data);
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
  if FFitParams.CFactor and (CFactor > 0) then
  begin
    c1 := c1m * CFactor;
    c2 := c2m * CFactor;
  end else
  begin
    c1 := c1m;
    c2 := c2m;
  end;
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

      Calc.Model := FitModelToLayer(X[i]);
      if Length(FMaterials) <> 0 then
        Calc.Model.Materials := FMaterials;    // loading from cache

      Calc.Run;

      if Length(FMaterials) = 0 then
        FMaterials := Calc.Model.Materials;    // saving to cache

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

  pbest := Copy(X[Result], 0, MaxInt);

  if FLastBestChiSqr <  FGlobalBestChiSqr then
  begin
    FGlobalBestChiSqr := FLastBestChiSqr;
    gbest := Copy(X[Result], 0, MaxInt);
    if FGlobalBestChiSqr < FAbsoluteBestChiSqr  then
    begin
      FAbsoluteBestChiSqr := FGlobalBestChiSqr;
      abest := Copy(gbest, 0, MaxInt);
    end;
  end
  else begin
    SetLength(FResultingCurve, 0);
    Inc(FJammingCount);
  end;

  CFactor := eps + (FLastBestChiSqr - FAbsoluteBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr);
end;

procedure TLFPSO_BASE.Init(const Step: integer);
begin
  FJammingCount := 0;

  if Step = 0 then
    Seed
  else
    ReSeed;

  InitVelocity;
  FindTheBest;

  SendUpdateMessage(Step);
end;

procedure TLFPSO_BASE.Shake(var  SuccessCount, ReInitCount, t: integer; Vmax0: single);
begin
  FReInit := True;
  if ReInitCount > FFitParams.ReInitMax then // recover previous best solution
  begin
    ReInitCount := 0;
    gbest := Copy(abest, 0, MaxInt);
    FGlobalBestChiSqr := FAbsoluteBestChiSqr;
    FFitParams.Vmax := Vmax0;
  end
  else
  begin
    FGlobalBestChiSqr := FGlobalBestChiSqr  * FFitParams.KChiSqr;
    FFitParams.Vmax := FFitParams.Vmax * FFitParams.KVmax;
  end;
  X[0] := Copy(gbest, 0, MaxInt);
  Init(t);
  Inc(ReInitCount);
  FJammingCount := 0;
  dec(SuccessCount);
end;

procedure TLFPSO_BASE.Run;
var
  t: integer;
  switch: double;
  ReInitCount: integer;
  Vmax0: single;
  SuccessCount: integer;
begin
  Randomize;

  FReInit := False;
  FTerminated := False;
  Vmax0 := FFitParams.Vmax ;
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

    switch := Random;
    if switch < 0.5 then
      UpdatePSO(SuccessCount)
    else
      UpdateLFPSO(SuccessCount);

    FindTheBest;
    SendUpdateMessage(t);
    if FGlobalBestChiSqr < FFitParams.Tolerance then Break;

    if FFitParams.Shake and (FJammingCount > FFitParams.JammingMax) then
      Shake(SuccessCount, ReInitCount, t, Vmax0)
    else
      inc(SuccessCount);
  end;
  UpdateStructure(abest);
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
  i, j, k: integer;
begin
  for I := 0 to High(X) do
    SetLength(X[i], Count);
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


procedure TLFPSO_BASE.UpdateStructure(const Solution: TSolution);
var
  i, j, LayerIndex: integer;
begin
  LayerIndex := 0;
  for i := 0 to High(FStructure.Stacks) do
  begin
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      FStructure.Stacks[i].Layers[j].H.V := Solution[LayerIndex][1];
      FStructure.Stacks[i].Layers[j].s.V := Solution[LayerIndex][2];
      FStructure.Stacks[i].Layers[j].r.V := Solution[LayerIndex][3];
      Inc(LayerIndex);
    end;
  end;
end;

procedure TLFPSO_BASE.Set_Init_X(const LIndex, PIndex: Integer; Val: TFitValue);
begin
       X[0][LIndex][PIndex] := Val.V;
    Xmax[0][LIndex][PIndex] := Val.max;
    Xmin[0][LIndex][PIndex] := Val.min;
  Xrange[0][LIndex][PIndex] := Xmax[0][LIndex][PIndex] - Xmin[0][LIndex][PIndex];
end;

procedure TLFPSO_BASE.Init_DomainsP;
begin
  SetDomain(FLayersCount, X);
  SetDomain(FLayersCount, Xmax);
  SetDomain(FLayersCount, Xmin);
  SetDomain(FLayersCount, Xrange);
  SetDomain(FLayersCount, Vmin);
  SetDomain(FLayersCount, Vmax);
  SetDomain(FLayersCount, V);
end;

end.
