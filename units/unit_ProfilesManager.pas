unit unit_ProfilesManager;

interface

uses
  VCLTee.Series, unit_XRCStructure, VCLTee.Chart, unit_types;

type
  TSeriesList = array of TLineSeries;

  TPLayer = record
    h, s, r: single;
  end;

  TProfileManager = class
    private
      FSeriesArray: array [1..4] of TSeriesList;
      FLayers: array of TPLayer;

      FDensityProfile: TLineSeries;
      FProfiles: TProfileFunctions;
      function GetVal(const StackIndex, LayerIndex, PeriodIndex, Val: integer): single;
      procedure FillLayers;
    public
      constructor Create;
      destructor Destroy; override;

      procedure PlotProfile(const PlotNP, PlotD: boolean);
      procedure PlotProfileNP(const PlotD: boolean);
      procedure PlotGradedProfile;
      procedure PlotSimpleProfile;
      procedure PlotDensityProfile;
      procedure ClearProfiles;
      procedure Prepare(Structure: TXRCStructure; chThickness, chRoughness, chDensity: TChart);

      property Profiles: TProfileFunctions write FProfiles;
      property DensityProfile: TLineSeries write FDensityProfile;
    end;

implementation

uses
  unit_materials, VCLTee.TeEngine, VCLTee.TeeProcs, math_globals,
  NesLib.FastMath;


function Erf(const sigma, xmax: single): single; inline;
const
  dx = 0.05;
var
  x, i, pow: single;
begin
  x := -sigma; i:= 0;
  while x < xmax/(sigma/1.77) do
  begin
    Pow := -1 * sqr(x);
    i := i + dx * FastExp(Pow);
    x := x + dx;
  end;
  Result := 1/sqrt(pi) * i;
end;

procedure TProfileManager.Prepare(Structure: TXRCStructure; chThickness, chRoughness, chDensity: TChart);
var
  Materials: TMaterialsList;

  procedure InitSereis(Series: TLineSeries);
  begin
    Series.LinePen.Width := 3;
    Series.Stairs := True;
    Series.Pointer.Visible := True;
    Series.Pointer.Size := 4;
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
  Materials := Structure.Materials;

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
  for i := 0 to High(Structure.Stacks) do
  begin
    if Structure.Stacks[i].N = 1 then Continue;
    for j := 0 to High(Structure.Stacks[i].Layers) do
    begin
      for p := 1 to 3 do
      begin
        FSeriesArray[p][j].Clear;
        if not Structure.Stacks[i].Layers[j].Data.P[p].Paired then
        begin
          for n := 0 to High(Structure.Stacks[i].Layers[j].Data.PP[p]) do
               FSeriesArray[p][j].AddXY(n + shift, Structure.Stacks[i].Layers[j].Data.PP[p][n]);
        end
        else begin
          for n := 0 to Structure.Stacks[i].N - 1 do
               FSeriesArray[p][j].AddXY(n + shift, Structure.Stacks[i].Layers[j].Data.P[p].V);
        end;
      end;
    end;
    Inc(shift, Structure.Stacks[i].N);
  end;
  if PlotD then
      PlotDensityProfile;
end;

procedure TProfileManager.PlotGradedProfile;
var
  StackIndex, LayerIndex, PeriodIndex, GradientIndex, shift, d, p: integer;
  Profiled: Boolean;

  function IsProfile: boolean;
  begin
     Result := (Structure.Stacks[StackIndex].Layers[LayerIndex].StackID = FProfiles[GradientIndex].StackID) and
               (Structure.Stacks[StackIndex].Layers[LayerIndex].ID = FProfiles[GradientIndex].LayerID) and
               (FProfiles[GradientIndex].PIndex = p);
  end;

begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(Structure.Stacks) do
  begin
    if Structure.Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(Structure.Stacks[StackIndex].Layers) do
    begin
      for PeriodIndex := 1 to Structure.Stacks[StackIndex].N do
      begin
        for p := 1 to 3 do
        begin
          Profiled := False;
          for GradientIndex := 0 to High(FProfiles) do
          begin
            if IsProfile then
            begin
              FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
                                                    FuncProfile(PeriodIndex + shift, FProfiles[GradientIndex]));
              Profiled := True;
            end;
          end;
          if not Profiled then
              FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift,
                                                     Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[p].V);
         end;
        end;
    end;
    Inc(shift, Structure.Stacks[StackIndex].N);
    Inc(d, Length(Structure.Stacks[StackIndex].Layers));
  end;
end;


procedure TProfileManager.PlotSimpleProfile;
var
  StackIndex, LayerIndex, PeriodIndex, shift, d, p: integer;
  Val: single;
begin
  shift := 0; d := 0;
  for StackIndex := 0 to High(Structure.Stacks) do
  begin
    if Structure.Stacks[StackIndex].N = 1 then Continue;

    for LayerIndex := 0 to High(Structure.Stacks[StackIndex].Layers) do
    begin
      for PeriodIndex := 1 to Structure.Stacks[StackIndex].N do
      begin
        for p := 1 to 3 do
        begin
          Val := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[p].V;
          FSeriesArray[p][LayerIndex + d].AddXY(PeriodIndex + shift, Val);
        end;
      end;
    end;
    Inc(shift, Structure.Stacks[StackIndex].N);
    Inc(d, Length(Structure.Stacks[StackIndex].Layers));
  end;
end;

constructor TProfileManager.Create;
begin

end;

destructor TProfileManager.Destroy;
begin

  inherited;
end;

procedure TProfileManager.FillLayers;
var
  StackIndex, LayerIndex, PeriodIndex: integer;
  Layer: TPLayer;
begin
  SetLength(FLayers, 0);
  for StackIndex := 0 to High(Structure.Stacks) do
  begin
    for PeriodIndex := 1 to Structure.Stacks[StackIndex].N do
    begin
      for LayerIndex := 0 to High(Structure.Stacks[StackIndex].Layers) do
      begin
        Layer.h := GetVal(StackIndex, LayerIndex, PeriodIndex, 1);
        Layer.s := GetVal(StackIndex, LayerIndex, PeriodIndex, 2);
        Layer.r := GetVal(StackIndex, LayerIndex, PeriodIndex, 3);

        FLayers := FLayers +[Layer];
      end;
    end;
  end;
end;

function TProfileManager.GetVal(const StackIndex, LayerIndex, PeriodIndex, Val: integer): single;
begin
  if Length(Structure.Stacks[StackIndex].Layers[LayerIndex].Data.PP[Val]) > 1 then
     Result := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.PP[Val][PeriodIndex - 1]
  else
    Result := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[Val].V;
end;

procedure TProfileManager.PlotDensityProfile;
var
  InLayerDepth, Depth, Val: single;
  s, rho, scale, EndDepth: single;
  i: integer;
begin
  Depth := 0;
  FillLayers;
  for I := 0 to High(FLayers) do
  begin
    s := FLayers[i].s;
    if (i = 0)  then // surface layer
    begin
      Depth := -s;
      rho := 0;
      scale := - FLayers[i].r;
      if Length(FLayers) > 1 then
        EndDepth := FLayers[0].h - FLayers[1].s
      else
        EndDepth := FLayers[0].h;
    end
    else begin
      if FLayers[i].s > FLayers[i].h / 2 then
          s :=FLayers[i].h / 2;
      rho := FLayers[i - 1].r;
      scale := rho - FLayers[i].r;
      if i < High(FLayers) then
      begin
        EndDepth := FLayers[i].h - FLayers[i + 1].s;
      end
      else
        EndDepth := FLayers[i].h;
    end;
    InLayerDepth := -s;
    while InLayerDepth < EndDepth do
    begin
      InLayerDepth := InLayerDepth + 0.1;
      Depth := Depth + 0.1;
      if s > 0 then
        Val := rho - scale * Erf(s, InlayerDepth)
      else
        Val := rho;
      FDensityProfile.AddXY(Depth, Val);
    end;
  end;
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
