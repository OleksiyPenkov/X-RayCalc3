unit unit_LFPSO_Poly;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TPolyLayer = array [1..3] of TVector; //
  TPolySolution = array of TPolyLayer;
  TPolyPopulation = array of TPolySolution;

  TLFPSO_Poly = class (TLFPSO_BASE)
    private

      X, V : TPolyPopulation;  // solutions and velocityes
      pbest: TPolySolution; // best local solution
      gbest: TPolySolution; // best global solution
      abest: TPolySolution;


      procedure Set_Init_XPoly(const N, Index, VT: Integer; Val: TFitValue);
      procedure SetStructure(const Inp: TFitStructure); override;
    public
      //
  end;

implementation

uses
  Forms,
  System.SysUtils,
  Neslib.FastMath,
  unit_helpers,
  Dialogs;

{ TLFPSO Polynomial}

procedure TLFPSO_Poly.SetStructure(const Inp: TFitStructure);
var
  i, j, k, Index: integer;
  D: double;
begin
  FStructure := Inp;
  FLayersCount := Inp.Total;

  SetLength(X, FPopulation);
  SetLength(V, FPopulation);
  Init_Domains;


  for I := 0 to FPopulation - 1 do
  begin
    SetLength(X[i], FLayersCount);
    SetLength(V[i], FLayersCount);
  end;

  Index := 0;
  for i := 0 to High(Inp.Stacks) do
  begin
    for j := 0 to High(Inp.Stacks[i].Layers) do
    begin
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 1, Inp.Stacks[i].Layers[j].H);
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 2, Inp.Stacks[i].Layers[j].s);
      Set_Init_XPoly(Inp.Stacks[i].N, Index, 3, Inp.Stacks[i].Layers[j].r);
      Inc(Index);
    end;
  end;
end;

procedure TLFPSO_Poly.Set_Init_XPoly(const N, Index, VT: Integer; Val: TFitValue);
begin
  if N = 1 then
  begin
    SetLength(X[0][Index][VT], 1);   // not periodic layer, only a0 = v
    SetLength(V[0][Index][VT], 1);
  end
  else begin
    SetLength(X[0][Index][VT], 10); // init array of a0..aN
    SetLength(V[0][Index][VT], 10);
  end;

    X[0][Index][VT][0] := Val.V;
    Xmax[0][VT][Index] := Val.max;
    Xmin[0][VT][Index] := Val.min;
  Xrange[0][VT][Index] := Xmax[0][1][Index] - Xmin[0][1][Index];
end;

end.
