unit unit_ProfilesManager;

interface

uses
  VCLTee.Series, unit_XRCStructure, VCLTee.Chart, unit_types, unit_ProfileCalc;

type
  TSeriesList = array of TLineSeries;

  TProfileManager = class
    private
      FStructure: TXRCStructure;
      FSeriesArray: array [1..4] of TSeriesList;

      FDensityProfile: TLineSeries;
      FProfiles: TProfileFunctions;
      function StructureToStacks: TStacksData;
      procedure PlotPeriodProfiles(const Stacks: TStacksData; const ExpandTables: Boolean);
      procedure PlotDensityProfile(const Stacks: TStacksData; const ExpandTables: Boolean);
    public
      { ExpandTables is TfrmProjectPanel.IsNonPeriodicProfile, the flag the
        calculation hands TXRCStructure.Model; PlotD draws the depth profile too. }
      procedure PlotProfile(const ExpandTables, PlotD: boolean);
      procedure ClearProfiles;
      procedure Prepare(AStructure: TXRCStructure; chThickness, chRoughness, chDensity: TChart);

      property Profiles: TProfileFunctions write FProfiles;
      property DensityProfile: TLineSeries write FDensityProfile;
    end;

implementation

uses
  unit_materials, VCLTee.TeEngine, VCLTee.TeeProcs;


procedure TProfileManager.Prepare(AStructure: TXRCStructure; chThickness, chRoughness, chDensity: TChart);
var
  Materials: TMaterialsList;

  procedure InitSereis(Series: TLineSeries);
  begin
    Series.LinePen.Width := 2;
    Series.Stairs := True;
    Series.Pointer.Visible := True;
    Series.Pointer.Size := 2;
  end;

  procedure CreateSeries(Chart: TChart; var SeriesList: TSeriesList);
  var
    i: integer;
  begin
    { The chart owns its series, and SeriesList.Clear only unlists them, so
      every redraw left the previous set behind in memory. }
    Chart.FreeAllSeries;
    SetLength(SeriesList, High(Materials) + 1);

    for I := 0 to High(Materials) do
    begin
      SeriesList[i] := TLineSeries.Create(Chart);
      SeriesList[i].Title := Materials[i].Name;
      SeriesList[i].ParentChart := Chart;
      InitSereis(SeriesList[i]);
    end;
  end;

begin
  FStructure := AStructure;
  Materials := FStructure.Materials;

  CreateSeries(chThickness, FSeriesArray[1]);
  CreateSeries(chRoughness, FSeriesArray[2]);
  CreateSeries(chDensity,   FSeriesArray[3]);
end;

{ One point per period for every layer of the periodic stacks, at the value the
  calculation gives it (ModelValue): the table or the layer's value, replaced
  by the last gradient aimed at it. A gradient counts periods from 1 in its own
  stack, so it is evaluated at PeriodIndex, never at the chart position
  PeriodIndex + shift. }
procedure TProfileManager.PlotPeriodProfiles(const Stacks: TStacksData; const ExpandTables: Boolean);
var
  StackIndex, LayerIndex, PeriodIndex, shift, d, p: integer;
begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(Stacks) do
  begin
    if Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(Stacks[StackIndex].Layers) do
      for PeriodIndex := 1 to Stacks[StackIndex].N do
        for p := 1 to 3 do
          FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
            ModelValue(Stacks, FProfiles, StackIndex, LayerIndex, PeriodIndex, p, ExpandTables));

    Inc(shift, Stacks[StackIndex].N);
    Inc(d, Length(Stacks[StackIndex].Layers));
  end;
end;

function TProfileManager.StructureToStacks: TStacksData;
var
  i: Integer;
begin
  SetLength(Result, Length(FStructure.Stacks));
  for i := 0 to High(FStructure.Stacks) do
  begin
    Result[i].N := FStructure.Stacks[i].N;
    Result[i].Layers := FStructure.Stacks[i].LayerData;
  end;
end;

procedure TProfileManager.PlotDensityProfile(const Stacks: TStacksData; const ExpandTables: Boolean);
var
  Layers: TArray<TPLayer>;
  Points: TArray<TDensityPoint>;
  i: Integer;
begin
  Layers := BuildLayers(Stacks, ExpandTables, FProfiles);
  Points := CalcDensityProfile(Layers);
  for i := 0 to High(Points) do
    FDensityProfile.AddXY(Points[i].Depth, Points[i].Value);
end;

procedure TProfileManager.ClearProfiles;
var
  StackIndex, p: integer;
begin
  for p := 1 to 3 do
    for StackIndex := 0 to High(FSeriesArray[p]) do
      FSeriesArray[p][StackIndex].Clear;

  FDensityProfile.Clear;
end;

procedure TProfileManager.PlotProfile(const ExpandTables, PlotD: boolean);
var
  Stacks: TStacksData;
begin
  ClearProfiles;
  Stacks := StructureToStacks;
  PlotPeriodProfiles(Stacks, ExpandTables);
  if PlotD then
    PlotDensityProfile(Stacks, ExpandTables);
end;

end.
