unit unit_LFPSO;

interface

uses
  unit_materials, unit_Types, unit_calc;

type

  TVector = array of single;   // Array of layer parameters

  TSolution = array [1..3] of TVector; // H, Sigma, rho x N Layers

  TPopulation = array of TSolution;

  TLFPSO_Periodic = class
    private
      FLayersCount: integer;
      FStructure: TFitPeriodicStructure;

      X, V, Pi : TPopulation;
      Xmax : TPopulation;
      Xmin : TPopulation;

      Vmax, VMin: TPopulation;

      FNMax: integer;
      FPopulation: integer;

      procedure UpdateLFPSO(const t: integer);
      procedure Seed;
      procedure NormalizeD(const Particle: integer);
      procedure SetDomain(const Count: integer; var X: TPopulation);
      procedure InitVelocity;
      function XtoStructure(const Index: integer): TFitPeriodicStructure;

      function GetStructure: TFitPeriodicStructure;
      procedure SetStructure(const Inp: TFitPeriodicStructure);
      function FindTheBest(var Calc: TCalc): integer;

    public
      constructor Create(const NMax, Population: integer);
      destructor Destroy; override;


      property Structure: TFitPeriodicStructure read GetStructure write SetStructure;
      procedure Run(var Calc: TCalc);
  end;

implementation

uses unit_FitHelpers;

const
  c1min = 1;
  c1max = 2;
  c2min = 1;
  c2max = 2;
  w_max = 0.9;
  w_min = 0.4;
  k = 0.1;
  u = 3.999;
  MaxC = 10;
  a = 0.5;

{ Supplementary}

function MultiplyVector(const X: TPopulation; v: single): TPopulation;
var
  i, j, k: integer;
begin
  for I := 1 to High(X) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[0][j]) do // for every layer
        Result[i][j][k] := X[I][j][k] * v;
end;

{ TLFPSO }

constructor TLFPSO_Periodic.Create;
begin
  FNMax := NMax;
  FPopulation := Population;

  SetLength(X, Population);
  SetLength(V, Population);
  SetLength(Pi, Population);

  SetLength(Xmax, 1);
  SetLength(Xmin, 1);
  SetLength(Vmax, 1);
  SetLength(Vmin, 1);
end;

destructor TLFPSO_Periodic.Destroy;
begin

  inherited;
end;

function TLFPSO_Periodic.GetStructure: TFitPeriodicStructure;
begin

end;

procedure TLFPSO_Periodic.InitVelocity;
begin
  VMax := MultiplyVector(Xmax, k);
  Vmin := MultiplyVector(Vmax, -1);
end;

procedure TLFPSO_Periodic.UpdateLFPSO(const t: integer);
begin

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

function TLFPSO_Periodic.FindTheBest(var Calc: TCalc): integer;
var
  i: integer;
  MinChisqr: single;
begin
  MinChisqr := 1e12;
  for i := 0 to High(X) do
  begin
    Calc.Model := ExpandPeriodicFitModel(XtoStructure(i));
    Calc.Run;
    Calc.CalcChiSquare;
    if Calc.ChiSQR < MinChisqr then
    begin
      MinChisqr  := Calc.ChiSQR;
      Result := i;
    end;
  end;
end;

procedure TLFPSO_Periodic.Run;
var
  t, BestX: integer;
begin
  Seed;
  InitVelocity;
  BestX := FindTheBest(Calc);

  for t := 1 to FNMax do
  begin
    UpdateLFPSO(t);
    BestX := FindTheBest(Calc);
  end;
  Calc.Model := ExpandPeriodicFitModel(XtoStructure(BestX));
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
  SetDomain(FLayersCount, Vmin);
  SetDomain(FLayersCount, Vmax);

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
       X[0][1][Index] := Inp.Stacks[i].Layers[j].H.V;
      Xmax[0][1][Index] := Inp.Stacks[i].Layers[j].H.max;
      Xmin[0][1][Index] := Inp.Stacks[i].Layers[j].H.min;

       X[0][2][Index] := Inp.Stacks[i].Layers[j].s.V;
      Xmax[0][2][Index] := Inp.Stacks[i].Layers[j].s.max;
      Xmin[0][2][Index] := Inp.Stacks[i].Layers[j].s.min;

       X[0][3][Index] := Inp.Stacks[i].Layers[j].r.V;
      Xmax[0][3][Index] := Inp.Stacks[i].Layers[j].r.max;
      Xmin[0][3][Index] := Inp.Stacks[i].Layers[j].r.min;

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

end.
