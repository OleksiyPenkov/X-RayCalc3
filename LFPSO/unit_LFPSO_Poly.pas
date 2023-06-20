unit unit_LFPSO_Poly;

interface

uses
  unit_materials, unit_Types, unit_calc, unit_SMessages, Windows,
  unit_LFPSO_Base;

type

  TLFPSO_Poly = class (TLFPSO_BASE)
    private
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
  i, j, Index: integer;
  D: double;
begin
  FStructure := Inp;
  FLayersCount := Inp.Total;

  Init_Domains;

  for I := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N > 1 then
    begin
      D := 0;
      for j := 0 to High(FStructure.Stacks[i].Layers) do
      begin
        FStructure.Stacks[i].Layers[j].LayerID := j;
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
      Set_Init_X(Index, 1, Inp.Stacks[i].Layers[j].H);
      Set_Init_X(Index, 2, Inp.Stacks[i].Layers[j].s);
      Set_Init_X(Index, 3, Inp.Stacks[i].Layers[j].r);

      Inc(Index);
    end;
  end;
end;

end.
