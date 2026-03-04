unit unit_ProfilesManager;

interface

uses
  System.Generics.Collections,
  VCLTee.Series, unit_XRCStructure, VCLTee.Chart, unit_types, unit_ProfileCalc;

type
  TSeriesList = array of TLineSeries;

  TProfileManager = class
    private
      FStructure: TXRCStructure;
      FSeriesArray: array [1..4] of TSeriesList;

      FDensityProfile: TLineSeries;
      FProfiles: TProfileFunctions;
      FProfileIndex: TDictionary<Cardinal, TArray<Integer>>;
      function StructureToStacks: TStacksData;
      procedure SetProfiles(const Value: TProfileFunctions);
    public
      constructor Create;
      destructor Destroy; override;

      procedure PlotProfile(const PlotNP, PlotD: boolean);
      procedure PlotProfileNP(const PlotD: boolean);
      procedure PlotGradedProfile;
      procedure PlotSimpleProfile;
      procedure PlotDensityProfile;
      procedure ClearProfiles;
      procedure Prepare(AStructure: TXRCStructure; chThickness, chRoughness, chDensity: TChart);

      property Profiles: TProfileFunctions write SetProfiles;
      property DensityProfile: TLineSeries write FDensityProfile;
    end;

implementation

uses
  unit_materials, VCLTee.TeEngine, VCLTee.TeeProcs, math_globals;


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
    Chart.SeriesList.Clear;
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

procedure TProfileManager.PlotProfileNP;
var
  i, j,  p, n, shift: integer;
begin
  ClearProfiles;
  shift := 1;
  for i := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[i].N = 1 then Continue;
    for j := 0 to High(FStructure.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
      begin
        FSeriesArray[p][j].Clear;
        if not FStructure.Stacks[i].Layers[j].Data.P[p].Paired then
        begin
          for n := 0 to High(FStructure.Stacks[i].Layers[j].Data.PP[p]) do
               FSeriesArray[p][j].AddXY(n + shift, FStructure.Stacks[i].Layers[j].Data.PP[p][n]);
        end
        else begin
          for n := 0 to FStructure.Stacks[i].N - 1 do
               FSeriesArray[p][j].AddXY(n + shift, FStructure.Stacks[i].Layers[j].Data.P[p].V);
        end;
      end;
    end;
    Inc(shift, FStructure.Stacks[i].N);
  end;
  if PlotD then
      PlotDensityProfile;
end;

procedure TProfileManager.SetProfiles(const Value: TProfileFunctions);
var
  i, Len: Integer;
  Key: Cardinal;
  Indices: TArray<Integer>;
begin
  FProfiles := Value;
  FProfileIndex.Clear;
  for i := 0 to High(FProfiles) do
  begin
    Key := Cardinal(FProfiles[i].StackID) shl 16 or FProfiles[i].LayerID;
    if FProfileIndex.TryGetValue(Key, Indices) then
    begin
      Len := Length(Indices);
      SetLength(Indices, Len + 1);
      Indices[Len] := i;
      FProfileIndex[Key] := Indices;
    end
    else begin
      SetLength(Indices, 1);
      Indices[0] := i;
      FProfileIndex.Add(Key, Indices);
    end;
  end;
end;

procedure TProfileManager.PlotGradedProfile;
var
  StackIndex, LayerIndex, PeriodIndex, gi, shift, d, p: integer;
  Profiled, HasProfiles: Boolean;
  Key: Cardinal;
  Indices: TArray<Integer>;
begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(FStructure.Stacks[StackIndex].Layers) do
    begin
      Key := Cardinal(FStructure.Stacks[StackIndex].Layers[LayerIndex].StackID) shl 16
           or FStructure.Stacks[StackIndex].Layers[LayerIndex].ID;
      HasProfiles := FProfileIndex.TryGetValue(Key, Indices);

      for PeriodIndex := 1 to FStructure.Stacks[StackIndex].N do
      begin
        for p := 1 to 3 do
        begin
          Profiled := False;
          if HasProfiles then
            for gi := 0 to High(Indices) do
              if FProfiles[Indices[gi]].PIndex = p then
              begin
                FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
                                                      FuncProfile(PeriodIndex + shift, FProfiles[Indices[gi]]));
                Profiled := True;
              end;
          if not Profiled then
              FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
                                                     FStructure.Stacks[StackIndex].Layers[LayerIndex].Data.P[p].V);
        end;
      end;
    end;
    Inc(shift, FStructure.Stacks[StackIndex].N);
    Inc(d, Length(FStructure.Stacks[StackIndex].Layers));
  end;
end;


procedure TProfileManager.PlotSimpleProfile;
var
  StackIndex, LayerIndex, PeriodIndex, shift, d, p: integer;
  Val: single;
begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(FStructure.Stacks) do
  begin
    if FStructure.Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(FStructure.Stacks[StackIndex].Layers) do
    begin
      for PeriodIndex := 1 to FStructure.Stacks[StackIndex].N do
      begin
        for p := 1 to 3 do
        begin
          Val := FStructure.Stacks[StackIndex].Layers[LayerIndex].Data.P[p].V;
          FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift, Val);
        end;
      end;
    end;
    Inc(shift, FStructure.Stacks[StackIndex].N);
    Inc(d, Length(FStructure.Stacks[StackIndex].Layers));
  end;
end;

constructor TProfileManager.Create;
begin
  FProfileIndex := TDictionary<Cardinal, TArray<Integer>>.Create;
end;

destructor TProfileManager.Destroy;
begin
  FProfileIndex.Free;
  inherited;
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

procedure TProfileManager.PlotDensityProfile;
var
  Stacks: TStacksData;
  Layers: TArray<TPLayer>;
  Points: TArray<TDensityPoint>;
  i: Integer;
begin
  Stacks := StructureToStacks;
  Layers := BuildLayers(Stacks);
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

//      if IsProfileEnbled and (FittingMode <> fmPeriodic) then

procedure TProfileManager.PlotProfile(const PlotNP, PlotD: boolean);
begin
  ClearProfiles;

  if Length(FProfiles) > 0 then
    PlotGradedProfile
  else
      if PlotNP then
         PlotProfileNP(false)
      else
        PlotSimpleProfile;

  if PlotD then
      PlotDensityProfile;
end;

end.
