unit unit_materials_mix;

interface

uses
  System.SysUtils, System.Math, math_complex, cmd_math_globals;

const
  ClassicalElectronRadius = 0.54014E-5;

type
  TElementInfo = record
    Name: string;
    AtomicMass: Single;
    BulkDensity: Single;
  end;

  TCachedHenke = record
    f1, f2: Single;
  end;

  TMaterialMixer = class
  private
    FElements: array of TElementInfo;
    FHenkeCache: array of array of TCachedHenke;
    FTargetLambdas: array of Single;
    FHenkePath: string;
    FElementCount: Integer;
    FTargetCount: Integer;
    FSubstrateName: string;
    FSubstrateInfo: TElementInfo;
    FSubstrateHenke: array of TCachedHenke;
  public
    constructor Create;
    procedure Initialize(const ElementNames: array of string;
      const TargetLambdas: array of Single;
      const SubstrateName: string;
      const HenkePath: string);

    procedure CalcMixedEpsilon(
      const Fractions: array of Single;
      DensityFactor: Single;
      TargetIdx: Integer;
      out Epsilon: TComplex;
      out EffDensity: Single
    );

    procedure CalcSubstrateEpsilon(
      TargetIdx: Integer;
      out Epsilon: TComplex
    );

    function GetElementDensity(Index: Integer): Single;
    function GetSubstrateDensity: Single;
    function GetElementName(Index: Integer): string;
    function FindElementIndex(const Name: string): Integer;
    procedure CalcSingleEpsilon(
      ElementIndex: Integer;
      Density: Single;
      TargetIdx: Integer;
      out Epsilon: TComplex
    );

    property ElementCount: Integer read FElementCount;
    property TargetCount: Integer read FTargetCount;
  end;

implementation

constructor TMaterialMixer.Create;
begin
  inherited;
  FElementCount := 0;
  FTargetCount := 0;
end;

procedure TMaterialMixer.Initialize(const ElementNames: array of string;
  const TargetLambdas: array of Single;
  const SubstrateName: string;
  const HenkePath: string);
var
  i, j: Integer;
  f: TComplex;
  Na, Nro: Single;
  SavedDir: string;
begin
  FHenkePath := HenkePath;
  FElementCount := Length(ElementNames);
  FTargetCount := Length(TargetLambdas);

  SetLength(FElements, FElementCount);
  SetLength(FHenkeCache, FElementCount, FTargetCount);
  SetLength(FTargetLambdas, FTargetCount);

  for j := 0 to FTargetCount - 1 do
    FTargetLambdas[j] := TargetLambdas[j];

  // ReadHenke looks for '.\Henke\{Name}.bin', so CWD must be the PARENT of the Henke dir
  SavedDir := GetCurrentDir;
  try
    SetCurrentDir(ExtractFilePath(ExcludeTrailingPathDelimiter(FHenkePath)));

    for i := 0 to FElementCount - 1 do
    begin
      FElements[i].Name := ElementNames[i];
      ReadHenke(ElementNames[i], 0, FTargetLambdas[0], f, Na, Nro);
      FElements[i].AtomicMass := Na;
      FElements[i].BulkDensity := Nro;

      for j := 0 to FTargetCount - 1 do
      begin
        ReadHenke(ElementNames[i], 0, FTargetLambdas[j], f, Na, Nro);
        FHenkeCache[i][j].f1 := f.re;
        FHenkeCache[i][j].f2 := f.im;
      end;
    end;

    FSubstrateName := SubstrateName;
    ReadHenke(SubstrateName, 0, FTargetLambdas[0], f, Na, Nro);
    FSubstrateInfo.Name := SubstrateName;
    FSubstrateInfo.AtomicMass := Na;
    FSubstrateInfo.BulkDensity := Nro;

    SetLength(FSubstrateHenke, FTargetCount);
    for j := 0 to FTargetCount - 1 do
    begin
      ReadHenke(SubstrateName, 0, FTargetLambdas[j], f, Na, Nro);
      FSubstrateHenke[j].f1 := f.re;
      FSubstrateHenke[j].f2 := f.im;
    end;
  finally
    SetCurrentDir(SavedDir);
  end;
end;

procedure TMaterialMixer.CalcMixedEpsilon(
  const Fractions: array of Single;
  DensityFactor: Single;
  TargetIdx: Integer;
  out Epsilon: TComplex;
  out EffDensity: Single);
var
  i: Integer;
  f1_mix, f2_mix, A_mix, rho_mix, c: Single;
  Lambda: Single;
begin
  f1_mix := 0;
  f2_mix := 0;
  A_mix := 0;
  rho_mix := 0;

  for i := 0 to High(Fractions) do
  begin
    f1_mix := f1_mix + Fractions[i] * FHenkeCache[i][TargetIdx].f1;
    f2_mix := f2_mix + Fractions[i] * FHenkeCache[i][TargetIdx].f2;
    A_mix  := A_mix  + Fractions[i] * FElements[i].AtomicMass;
    rho_mix := rho_mix + Fractions[i] * FElements[i].BulkDensity;
  end;

  rho_mix := rho_mix * DensityFactor;
  EffDensity := rho_mix;

  Lambda := FTargetLambdas[TargetIdx];
  c := ClassicalElectronRadius * rho_mix / A_mix * Sqr(Lambda);

  Epsilon.re := 1 - f1_mix * c;
  Epsilon.im := f2_mix * c;
end;

procedure TMaterialMixer.CalcSubstrateEpsilon(
  TargetIdx: Integer;
  out Epsilon: TComplex);
var
  c, Lambda: Single;
begin
  Lambda := FTargetLambdas[TargetIdx];
  c := ClassicalElectronRadius * FSubstrateInfo.BulkDensity
       / FSubstrateInfo.AtomicMass * Sqr(Lambda);

  Epsilon.re := 1 - FSubstrateHenke[TargetIdx].f1 * c;
  Epsilon.im := FSubstrateHenke[TargetIdx].f2 * c;
end;

function TMaterialMixer.GetElementDensity(Index: Integer): Single;
begin
  Result := FElements[Index].BulkDensity;
end;

function TMaterialMixer.GetSubstrateDensity: Single;
begin
  Result := FSubstrateInfo.BulkDensity;
end;

function TMaterialMixer.GetElementName(Index: Integer): string;
begin
  Result := FElements[Index].Name;
end;

function TMaterialMixer.FindElementIndex(const Name: string): Integer;
var
  i: Integer;
begin
  for i := 0 to FElementCount - 1 do
    if SameText(FElements[i].Name, Name) then
      Exit(i);
  Result := -1;
end;

procedure TMaterialMixer.CalcSingleEpsilon(
  ElementIndex: Integer;
  Density: Single;
  TargetIdx: Integer;
  out Epsilon: TComplex);
var
  c, Lambda: Single;
begin
  Lambda := FTargetLambdas[TargetIdx];
  c := ClassicalElectronRadius * Density
       / FElements[ElementIndex].AtomicMass * Sqr(Lambda);
  Epsilon.re := 1 - FHenkeCache[ElementIndex][TargetIdx].f1 * c;
  Epsilon.im := FHenkeCache[ElementIndex][TargetIdx].f2 * c;
end;

end.
