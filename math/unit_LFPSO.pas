unit unit_LFPSO;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows;

const
  WM_CHI_UPDATE = WM_STR_BASE + 100;

type

  PUpdateFitProgressMsg = ^TUpdateFitProgressMsg ;
  TUpdateFitProgressMsg  = record
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

      FLastBestChiSqr  : single;
      FLastWorseChiSQR : single;
      FGlobalBestChiSqr: single;


      FTMax: integer;
      FPopulation: integer;
      FData, FResultingCurve: TDataArray;
      FLimit: single;
    FSuccededStepCount: Integer;

      procedure UpdateLFPSO(const t: integer);
      procedure Seed;
      procedure NormalizeD(const Particle: integer);
      procedure SetDomain(const Count: integer; var X: TPopulation);
      procedure InitVelocity;
      function XtoStructure(const Index: integer): TFitPeriodicStructure;

      function GetStructure: TFitPeriodicStructure;
      procedure SetStructure(const Inp: TFitPeriodicStructure);
      function FindTheBest: integer;
      procedure UpdatePSO(const t: integer);
      function GetResult: TLayeredModel;
      function GBestStructure: TFitPeriodicStructure;
      function LevyWalk(const X, gBest: single): single;
      procedure SendUpdateMessage(const Step: integer);
      procedure CheckLimits(const i, j, k: integer); inline;
    public
      constructor Create(const NMax, Population: integer);
      destructor Destroy; override;


      property Structure: TFitPeriodicStructure read GetStructure write SetStructure;
      property Result : TLayeredModel read GetResult;
      property ExpValues: TDataArray read FData write FData;
      property Limit: single write FLimit;

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
  Result := 0.1 + 0.9 * (1 - t / Tmax);
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
  FTMax := NMax;
  FPopulation := Population;

  SetLength(X, Population);
  SetLength(V, Population);

  SetLength(Xmax, 1);
  SetLength(Xmin, 1);
  SetLength(Vmax, 1);
  SetLength(Vmin, 1);
  SetLength(Xrange, 1);
end;

destructor TLFPSO_Periodic.Destroy;
begin

  inherited;
end;

function TLFPSO_Periodic.GetResult: TLayeredModel;
begin
  Result := ExpandPeriodicFitModel(GBestStructure);
end;

function TLFPSO_Periodic.GetStructure: TFitPeriodicStructure;
begin

end;

procedure TLFPSO_Periodic.InitVelocity;
var
  i, j, k: integer;
begin
  MultiplyVector(Xrange, 1, Vmax);
  MultiplyVector(Vmax, -1, Vmin);

  for i := 0 to High(V) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(V[i][j]) do // for every layer
        V[i][j][k] := Random * (Vmax[0][j][k] - Vmin[0][j][k]) + Vmin[0][j][k];
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
  dX, Y, S: single;
  num, den, sigma_u: single;
  u, v, z: single;
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
  c1, c2: single;
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
  end;

end;

procedure TLFPSO_Periodic.UpdatePSO(const t: integer);
var
  i, j, k: integer;
  c1, c2: single;
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
  end;
end;

procedure TLFPSO_Periodic.NormalizeD; // keep D for every periodic stack constant
var
  i, j: integer;
  Index, Last, Most: integer;
  D, HMax: single;
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

    D := 0; HMax := 0;
    for j := Index to Last do
    begin
      D := D + X[Particle][1][j];
      if X[Particle][1][j] > HMax then  // find the thickest layer
      begin
        HMax := X[Particle][1][j];
        Most := j;
      end;
    end;

    X[Particle][1][Most] := X[Particle][1][Most] + (FStructure.Stacks[i].D - D); // correct the thickest layer to maintain total D
  end;
end;

function TLFPSO_Periodic.FindTheBest: integer;
var
  i: integer;
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
          Result := i;
          FResultingCurve := Calc.Results;
        end;
        if Calc.ChiSQR > FLastWorseChiSQR then
        begin
          FLastWorseChiSQR :=  Calc.ChiSQR;
        end;
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
      inc(FSuccededStepCount);
    end
    else begin
      SetLength(FResultingCurve, 0);
      dec(FSuccededStepCount);
       if FSuccededStepCount < 1 then FSuccededStepCount := 1;
    end;
end;

procedure TLFPSO_Periodic.Run;
var
  t, BestX: integer;
  switch: single;
begin
  FCalcConditions := CalcConditions;
  FGlobalBestChiSqr:= 1e12;

  Seed;
  InitVelocity;
  BestX := FindTheBest;

  SendUpdateMessage(0);

  FSuccededStepCount := 1;

  for t := 1 to FTMax do
  begin
    switch := Random;
    if switch < 0.5 then
      UpdatePSO(FSuccededStepCount)
    else
      UpdateLFPSO(FSuccededStepCount);

    BestX := FindTheBest;

    SendUpdateMessage(t);
    if FGlobalBestChiSqr < 0.1 then Break;
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
  msg_prm.BestChi := FGlobalBestChiSqr;
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

procedure TLFPSO_Periodic.SetStructure(const Inp: TFitPeriodicStructure);
var
  i, j, Index: integer;
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

function TLFPSO_Periodic.GBestStructure: TFitPeriodicStructure;
var
  i, j, LayerIndex: integer;
begin
  Result := FStructure;
  LayerIndex := 0;
  for i := 0 to High(Result.Stacks) do
  begin
    for j := 0 to High(Result.Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[j].H.V := gbest[1][LayerIndex];
      Result.Stacks[i].Layers[j].s.V := gbest[2][LayerIndex];
      Result.Stacks[i].Layers[j].r.V := gbest[3][LayerIndex];
      Inc(LayerIndex);
    end;
  end;
end;

end.
