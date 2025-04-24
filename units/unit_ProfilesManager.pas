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
      function GetSigma(const StackIndex, LayerIndex, PeriodIndex: integer): single;
      function GetRho(const StackIndex, LayerIndex, PeriodIndex: integer): single;
      procedure FillLayers;
    public
      constructor Create;
      destructor Destroy; override;

      procedure PlotProfile(const PlotNP: boolean);
      procedure PlotProfileNP;
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


function Erf(const sigma, xmax: single): single;
const
  dx = 0.01;
var
  x, i, pow: single;
begin
  x := -sigma; i:= 0;
  while x < xmax/(sigma/1.77) do
  begin
    Pow := -1 * sqr(x);
    i := i + dx * exp(Pow);
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
begin

end;

function TProfileManager.GetSigma(const StackIndex, LayerIndex, PeriodIndex: integer): single;
begin
  if Length(Structure.Stacks[StackIndex].Layers[LayerIndex].Data.PP[2]) > 1 then
     Result := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.PP[2][PeriodIndex - 1]
  else
    Result := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[2].V;
end;

function TProfileManager.GetRho(const StackIndex, LayerIndex, PeriodIndex: integer): single;
begin
  if Length(Structure.Stacks[StackIndex].Layers[LayerIndex].Data.PP[3]) > 1 then
     Result := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.PP[3][PeriodIndex - 1]
  else
    Result := Structure.Stacks[StackIndex].Layers[LayerIndex].Data.P[3].V;
end;


procedure TProfileManager.PlotDensityProfile;
var
  StackIndex, LayerIndex, PeriodIndex: integer;
  InLayerDepth, Depth, Val: single;
  s, tots, lasts, lastrho, rho, thickness, scale,EndDepth: single;
begin
  for StackIndex := 0 to High(Structure.Stacks) do
  begin
    for PeriodIndex := 1 to Structure.Stacks[StackIndex].N do
    begin
      for LayerIndex := 0 to High(Structure.Stacks[StackIndex].Layers) do
      begin
        if (StackIndex = 0) and (PeriodIndex = 1) and (LayerIndex = 0) then // surface layer
        begin
          s := GetSigma(0, 0, 1);
          InLayerDepth := -s;
          Depth := InLayerDepth;
          lastrho := 0;
          rho := GetRho(0, 0, 1);
          scale := rho - lastrho;
          EndDepth := Structure.Stacks[0].Layers[0].Data.P[1].V;
        end
        else begin
          InLayerDepth := 0;
          lastrho := rho;
          rho := GetRho(StackIndex, LayerIndex, PeriodIndex);
          scale := rho - lastrho;
          EndDepth := Structure.Stacks[0].Layers[0].Data.P[1].V;
        end;
        tots := 0;
        while InLayerDepth < EndDepth do
        begin
          InLayerDepth := InLayerDepth + 0.1;
          Depth := Depth + 0.1;
          if s > 0 then
            Val := lastrho + scale * Erf(s, InlayerDepth)
          else
            Val := rho;
          FDensityProfile.AddXY(Depth, Val);
        end;
      end;
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

procedure TProfileManager.PlotProfile(const PlotNP: boolean);
begin
  ClearProfiles;

  if Length(FProfiles) > 0 then
    PlotGradedProfile
  else
      if PlotNP then
         PlotProfileNP
      else
        PlotSimpleProfile;

  PlotDensityProfile;
end;

end.
