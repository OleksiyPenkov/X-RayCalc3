unit unit_LFPSO;

interface

uses
  unit_materials, unit_Types, unit_calc;

type

  TVector = array of single;

  TXi = array [1..3] of TVector; // H, Sigma, rho

  TX = array of TXi;

  TLFPSO_Periodic = class
    private
      FCount: integer;

      X  : TX;
      Xu : TX;
      Xl : TX;

      FNMax: integer;
      FPopulation: integer;

      procedure LFPSO;
      procedure Seed;
      procedure SetDomain(const Count: integer; var X: TX);
      function GetStructure: TFitPeriodicStructure;
      procedure SetStructure(const Inp: TFitPeriodicStructure);

    public
      constructor Create(const NMax, Population: integer);
      destructor Destroy; override;


      property Structure: TFitPeriodicStructure read GetStructure write SetStructure;
      procedure Run(var Calc: TCalc);
  end;

implementation

{ TLFPSO }

constructor TLFPSO_Periodic.Create;
begin
  FNMax := NMax;
  FPopulation := Population;

  SetLength(X, Population);
  SetLength(Xu, 1);
  SetLength(Xl, 1);
end;

destructor TLFPSO_Periodic.Destroy;
begin

  inherited;
end;

function TLFPSO_Periodic.GetStructure: TFitPeriodicStructure;
begin

end;

procedure TLFPSO_Periodic.LFPSO;
begin

end;

procedure TLFPSO_Periodic.Run;
begin
  Seed;
end;

procedure TLFPSO_Periodic.Seed;
var
  i, j, k: integer;
begin
  for I := 1 to High(X) do // for every member of the population
    for j := 1 to 3 do // for H, s, rho
      for k := 0 to High(X[0][j]) do // for every layer
        X[i][j][k] := Xl[0][j][k] + Random * (Xu[0][j][k] - Xl[0][j][k]);   // min + Random * (min-max)
end;

procedure TLFPSO_Periodic.SetDomain(const Count: integer; var X: TX);
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
  FCount := Inp.Total;

  SetDomain(FCount, X);
  SetDomain(FCount, Xu);
  SetDomain(FCount, Xl);

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
       X[0][1][Index] := Inp.Stacks[i].Layers[j].H.V;
      Xu[0][1][Index] := Inp.Stacks[i].Layers[j].H.max;
      Xl[0][1][Index] := Inp.Stacks[i].Layers[j].H.min;

       X[0][2][Index] := Inp.Stacks[i].Layers[j].s.V;
      Xu[0][2][Index] := Inp.Stacks[i].Layers[j].s.max;
      Xl[0][2][Index] := Inp.Stacks[i].Layers[j].s.min;

       X[0][3][Index] := Inp.Stacks[i].Layers[j].r.V;
      Xu[0][3][Index] := Inp.Stacks[i].Layers[j].r.max;
      Xl[0][3][Index] := Inp.Stacks[i].Layers[j].r.min;

      Inc(Index);
    end;
  end;
end;

end.
