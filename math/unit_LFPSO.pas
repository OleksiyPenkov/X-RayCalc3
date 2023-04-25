unit unit_LFPSO;

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

  TLFPSO_Periodic = class
    private
      FCalcConditions: TThreadParams;

      FLayersCount: integer;
      FStructure: TFitPeriodicStructure;  // initial (input) structure

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
      FParams: TFitParams;

      procedure UpdateLFPSO(const t: integer);
      procedure Seed;
      procedure NormalizeD(const Particle: integer);
      procedure SetDomain(const Count: integer; var X: TPopulation);
      procedure InitVelocity;
      function XtoStructure(const Index: integer): TFitPeriodicStructure;

      function GetStructure: TFitPeriodicStructure;
      procedure SetStructure(const Inp: TFitPeriodicStructure);
      procedure FindTheBest;
      procedure UpdatePSO(const t: integer);
      function GetResult: TLayeredModel;
      function GBestStructure(best: TSolution): TFitPeriodicStructure;
      function LevyWalk(const X, gBest: single): single;
      procedure SendUpdateMessage(const Step: integer);
      procedure CheckLimits(const i, j, k: integer); inline;
      procedure SetParams(const Value: TFitParams);
      procedure ReInit(const Step: integer); inline;
      procedure CopySolution(const Source: TSolution; var Dest: TSolution);
    public
      constructor Create;
      destructor Destroy; override;


      property Structure: TFitPeriodicStructure read GetStructure write SetStructure;
      property Result : TLayeredModel read GetResult;
      property ExpValues: TDataArray read FData write FData;
      property Limit: single write FLimit;
      property Params: TFitParams write SetParams;

      procedure Run(CalcConditions: TThreadParams);

  end;

implementation

uses unit_FitHelpers, Forms, System.SysUtils, System.Math, unit_helpers, Dialogs;

const
  w_max = 0.9;
  w_min = 0.4;
  MaxC = 10;
  a = 0.5;
  eps = 1;
  c1m = 1.49445;
  c2m = 1.49445;

{ Supplementary}

function Gamma( x : extended) : extended;
const COF : array [0..14] of extended =
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
  tmp, w, ser : extended;
  reflect : boolean;
begin
  reflect := (x < 0.5);
  if reflect then w := 1.0 - x else w := x;
  tmp := w + 5.2421875;
  tmp := (w + 0.5)*Ln(tmp) - tmp;
  ser := COF[0];
  for j := 1 to 14 do ser := ser + COF[j]/(w + j);
  try
    if reflect then
      result := PI_OVER_K * w * Exp(-tmp) / (Sin(PI*x) * ser)
    else
      result := K * Exp(tmp) * ser / w;
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

function Omega(const t, TMax: integer): single;
begin
  Result := 0.05 + 0.05 * (1 - t / Tmax);
end;

function RS: integer;
begin
  Result := 1 - Random(2);
  if Result = 0 then
       Result := 1;
end;

{ TLFPSO }

constructor TLFPSO_Periodic.Create;
begin
  inherited ;
end;

destructor TLFPSO_Periodic.Destroy;
begin

  inherited;
end;

function TLFPSO_Periodic.GetResult: TLayeredModel;
begin
  Result := ExpandPeriodicFitModel(GBestStructure(abest));
end;

function TLFPSO_Periodic.GetStructure: TFitPeriodicStructure;
begin
  Result := GBestStructure(abest);
end;

procedure TLFPSO_Periodic.InitVelocity;
var
  i, j, k: integer;
begin
  MultiplyVector(Xmax, FParams.Vmax, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(V[i][j]) do // for every layer
        V[i][j][k] := Random * (Vmax[0][j][k] - Vmin[0][j][k]) + Vmin[0][j][k];
end;

procedure TLFPSO_Periodic.CopySolution(const Source: TSolution; var Dest: TSolution);
begin
  Dest := Source;
end;

procedure TLFPSO_Periodic.CheckLimits(const i, j, k: integer);
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

function TLFPSO_Periodic.LevyWalk(const X, gBest: single): single;
const
  beta = 1.5;
var
  dX, S: double;
  num, den, sigma_u: double;
  u, v, z: double;
begin
  num := gamma(1 + beta) * sin(pi * beta / 2); // used for Numerator
  den := gamma(( 1 + beta)/2) * beta * power(2, (beta-1)/2); // used for Denominator
  sigma_u := power(num / den, 1 / beta); // Standard deviation

  u := Random * sigma_u;
  v := Random;
  z := u/ abs(power(v, 1/ beta));

  S := 0.01 * z * (X - gBest);
  dX := X * S;
  Result := dX * Random;
end;

procedure TLFPSO_Periodic.UpdateLFPSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: double;
begin
  c1 := c1m; //* (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);
  c2 := c2m; //* (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[I][j]) do // for every layer
      begin
        V[i][j][k] := Omega(t, FTMax) * LevyWalk(X[i][j][k], gbest[j][k])  +
                      c1 * Random * (pbest[j][k] - X[i][j][k]) +
                      c2 * Random * (gbest[j][k] - X[i][j][k]);

        CheckLimits(i, j, k);
      end;
    NormalizeD(i);
  end;

end;

procedure TLFPSO_Periodic.UpdatePSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: double;
begin
  c1 := c1m;// * (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);
  c2 := c2m;// * (FLastBestChiSqr - FGlobalBestChiSqr)/ (FLastWorseChiSQR - FGlobalBestChiSqr + eps);

  for i := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[I][j]) do // for every layer except subtrate
      begin
        V[i][j][k] := Omega(t, FTMax) * V[i][j][k]  +
                      c1 * Random * (pbest[j][k] - X[i][j][k]) +
                      c2 * Random * (gbest[j][k] - X[i][j][k]);

        CheckLimits(i, j, k);
      end;
    NormalizeD(i);
  end;
end;

procedure TLFPSO_Periodic.NormalizeD; // keep D for every periodic stack constant
var
  i, j: integer;
  Index, Last: integer;
  Dreal, f: double;
begin
  Index := 0;

  for I := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N = 1 then    // if not periodic stack
    begin
       Inc(Index, Length(FStructure.Stacks[i].Layers));
       Continue;
    end;
    Last := Index + Length(FStructure.Stacks[i].Layers) - 1;

    Dreal := 0;
    for j := Index to Last do
      Dreal := Dreal + X[Particle][1][j];

    f := (FStructure.Stacks[i].D - Dreal)/Dreal;
    for j := Index to Last do
      X[Particle][1][j] := X[Particle][1][j] * (1 + f);
  end;
end;

procedure TLFPSO_Periodic.FindTheBest;
var
  i, Result: integer;
  Calc: TCalc;
begin
  FLastBestChiSqr  := 1e12;
  FLastWorseChiSQR := 0;

    for i := 0 to High(X) do
    begin
      try
        Calc := TCalc.Create;
        Calc.Params := FCalcConditions;
        Calc.ExpValues := FData;
        Calc.Limit := FLimit;

        Calc.Model := ExpandPeriodicFitModel(XtoStructure(i));
        Calc.Run;
        Calc.CalcChiSquare;
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

    CopySolution(X[Result], pbest);

    if FLastBestChiSqr <  FGlobalBestChiSqr then
    begin
      FGlobalBestChiSqr := FLastBestChiSqr;
      CopySolution(X[Result], gbest);
    end
    else begin
      SetLength(FResultingCurve, 0);
      Inc(FJammingCount);
    end;

    if FGlobalBestChiSqr < FAbsoluteBestChiSqr  then
    begin
      FAbsoluteBestChiSqr := FGlobalBestChiSqr;
      CopySolution(X[Result], abest);
    end;

end;

procedure TLFPSO_Periodic.ReInit(const Step: integer);
begin
  FJammingCount := 0;

  Seed;
  InitVelocity;
  FindTheBest;

  SendUpdateMessage(Step);
end;


procedure TLFPSO_Periodic.Run;
var
  t: integer;
  switch: double;
  ReInitCount: integer;
  Vmax0: single;
begin
  Vmax0 := FParams.Vmax ;
  ReInitCount := 0;
  FGlobalBestChiSqr:= 1e12;
  FAbsoluteBestChiSqr := 1e12;
  FCalcConditions := CalcConditions;

  ReInit(0);

  for t := 1 to FTMax do
  begin
    switch := Random;
    if switch < 0.5 then
      UpdatePSO(t)
    else
      UpdateLFPSO(t);

    FindTheBest;
    SendUpdateMessage(t);
    if FGlobalBestChiSqr < 0.0005 then Break;

    if FParams.Shake and (FJammingCount > FParams.JammingMax) then
    begin
      if ReInitCount > FParams.ReInitMax then
      begin
        ReInitCount := 0;
        SetStructure(GBestStructure(abest));
        CopySolution(abest, gbest);
        FGlobalBestChiSqr := FAbsoluteBestChiSqr;
        FParams.Vmax := Vmax0;
      end
      else
      begin
        SetStructure(GBestStructure(gbest));
        FGlobalBestChiSqr := FGlobalBestChiSqr  * FParams.KChiSqr;
        FParams.Vmax := FParams.Vmax * FParams.KVmax;
      end;
      ReInit(t);
      Inc(ReInitCount);
      FJammingCount := 0;
    end;
  end;
end;

procedure TLFPSO_Periodic.Seed;
var
  i, j, k: integer;
begin
  Randomize;

  for I := 1 to High(X) do // for every member of the population
  begin
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[0][j]) do // for every layer
        X[i][j][k] := Xmin[0][j][k] + Random * (Xmax[0][j][k] - Xmin[0][j][k]);   // min + Random * (min-max)

    NormalizeD(i);
  end;
end;

procedure TLFPSO_Periodic.SendUpdateMessage(const Step: integer);
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

procedure TLFPSO_Periodic.SetDomain(const Count: integer; var X: TPopulation);
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

procedure TLFPSO_Periodic.SetParams(const Value: TFitParams);
begin
  FParams := Value;

  FTMax := FParams.NMax;
  FPopulation := FParams.Pop;

  SetLength(X, FPopulation);
  SetLength(V, FPopulation);

  SetLength(Xmax, 1);
  SetLength(Xmin, 1);
  SetLength(Vmax, 1);
  SetLength(Vmin, 1);
  SetLength(Xrange, 1);
end;

procedure TLFPSO_Periodic.SetStructure(const Inp: TFitPeriodicStructure);
var
  i, j, Index: integer;
  D: double;
begin
  FStructure := Inp;
  FLayersCount := Inp.Total;

  SetDomain(FLayersCount, X);
  SetDomain(FLayersCount, Xmax);
  SetDomain(FLayersCount, Xmin);
  SetDomain(FLayersCount, Xrange);
  SetDomain(FLayersCount, Vmin);
  SetDomain(FLayersCount, Vmax);
  SetDomain(FLayersCount, V);


  for I := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N > 1 then
    begin
      D := 0;
      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        FStructure.Stacks[i].Layers[j].ID := j;
        D := D + FStructure.Stacks[i].Layers[j].H.V;
      end;
      FStructure.Stacks[i].D := D;
    end;
  end;

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
       X[0][1][Index] := Inp.Stacks[i].Layers[j].H.V;
      Xmax[0][1][Index] := Inp.Stacks[i].Layers[j].H.max;
      Xmin[0][1][Index] := Inp.Stacks[i].Layers[j].H.min;
      Xrange[0][1][Index] := Xmax[0][1][Index] - Xmin[0][1][Index];

       X[0][2][Index] := Inp.Stacks[i].Layers[j].s.V;
      Xmax[0][2][Index] := Inp.Stacks[i].Layers[j].s.max;
      Xmin[0][2][Index] := Inp.Stacks[i].Layers[j].s.min;
      Xrange[0][2][Index] := Xmax[0][2][Index] - Xmin[0][2][Index];

       X[0][3][Index] := Inp.Stacks[i].Layers[j].r.V;
      Xmax[0][3][Index] := Inp.Stacks[i].Layers[j].r.max;
      Xmin[0][3][Index] := Inp.Stacks[i].Layers[j].r.min;
      Xrange[0][3][Index] := Xmax[0][3][Index] - Xmin[0][3][Index];

      Inc(Index);
    end;
  end;
end;

function TLFPSO_Periodic.XtoStructure(const Index: integer): TFitPeriodicStructure;
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

function TLFPSO_Periodic.GBestStructure(best: TSolution): TFitPeriodicStructure;
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
