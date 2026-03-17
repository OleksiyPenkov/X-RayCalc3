unit unit_universal_io;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.IOUtils, System.Math,
  unit_universal_types, cmd_unit_types, unit_materials_mix,
  unit_universal_templates;

type
  TUniversalIO = class
  private
    FOutputDir: string;
    FLogFile: TextFile;
    FLogOpen: Boolean;
    procedure EnsureOutputDir;
  public
    constructor Create;
    destructor Destroy; override;

    class function LoadConfig(const FileName: string): TUniversalConfig;
    class procedure SaveConfig(const Config: TUniversalConfig;
      const FileName: string);

    procedure OpenLog(const OutputDir: string;
      const TargetNames: array of string);
    procedure LogIteration(Iteration: Integer; FoM: Single;
      const TargetResults: array of TTargetResult;
      const TargetNames: array of string;
      Diversity: Single);
    procedure CloseLog;

    procedure SaveBestStructure(const Config: TUniversalConfig;
      const Best: TGenome; FoM: Single;
      const TargetResults: array of TTargetResult;
      const OutputDir: string);
    procedure SaveCurve(const Element: string; const Curve: TDataArray;
      const OutputDir: string);
    procedure SavePopulation(const Config: TUniversalConfig;
      const Particles: array of TParticle;
      TopN: Integer; const OutputDir: string);

    procedure SaveXRCStructure(const Config: TUniversalConfig;
      const Best: TGenome; Mixer: TMaterialMixer;
      const Templates: TTemplateLibrary;
      const OutputDir: string);

    procedure SaveCheckpoint(const State: TOptState;
      const Config: TUniversalConfig;
      const OutputDir: string);
    function LoadCheckpoint(const FileName: string;
      const Config: TUniversalConfig): TOptState;
  end;

implementation

constructor TUniversalIO.Create;
begin
  inherited;
  FLogOpen := False;
end;

destructor TUniversalIO.Destroy;
begin
  if FLogOpen then
    CloseLog;
  inherited;
end;

procedure TUniversalIO.EnsureOutputDir;
begin
  if not TDirectory.Exists(FOutputDir) then
    TDirectory.CreateDirectory(FOutputDir);
end;

class function TUniversalIO.LoadConfig(const FileName: string): TUniversalConfig;
var
  JSON: TJSONObject;
  JTargets, JPool: TJSONArray;
  JStructure, JFitness, JOptimizer, JTarget, JRange: TJSONObject;
  Content: string;
  i: Integer;
begin
  Content := TFile.ReadAllText(FileName);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    JTargets := JSON.GetValue<TJSONArray>('targets');
    SetLength(Result.Targets, JTargets.Count);
    for i := 0 to JTargets.Count - 1 do
    begin
      JTarget := JTargets.Items[i] as TJSONObject;
      Result.Targets[i].Name := JTarget.GetValue<string>('element');
      Result.Targets[i].Lambda := JTarget.GetValue<Double>('lambda');
      Result.Targets[i].Weight := JTarget.GetValue<Double>('weight');
    end;

    JPool := JSON.GetValue<TJSONArray>('element_pool');
    SetLength(Result.ElementPool, JPool.Count);
    for i := 0 to JPool.Count - 1 do
      Result.ElementPool[i] := JPool.Items[i].Value;

    JStructure := JSON.GetValue<TJSONObject>('structure');
    Result.Structure.StructureType := JStructure.GetValue<string>('type');
    Result.Structure.LayersPerPeriod := JStructure.GetValue<Integer>('layers_per_period');

    if JStructure.GetValue('pure_elements') <> nil then
      Result.Structure.PureElements := JStructure.GetValue<Boolean>('pure_elements')
    else
      Result.Structure.PureElements := False;

    JRange := JStructure.GetValue<TJSONObject>('d');
    Result.Structure.dRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.dRange.Max := JRange.GetValue<Double>('max');

    JRange := JStructure.GetValue<TJSONObject>('gamma');
    Result.Structure.GammaRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.GammaRange.Max := JRange.GetValue<Double>('max');

    JRange := JStructure.GetValue<TJSONObject>('N');
    Result.Structure.NRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.NRange.Max := JRange.GetValue<Double>('max');

    if JStructure.GetValue('sigma') is TJSONNumber then
    begin
      Result.Structure.SigmaFixed := JStructure.GetValue<Double>('sigma');
      Result.Structure.SigmaRange.Min := Result.Structure.SigmaFixed;
      Result.Structure.SigmaRange.Max := Result.Structure.SigmaFixed;
    end
    else
    begin
      JRange := JStructure.GetValue<TJSONObject>('sigma');
      Result.Structure.SigmaRange.Min := JRange.GetValue<Double>('min');
      Result.Structure.SigmaRange.Max := JRange.GetValue<Double>('max');
      Result.Structure.SigmaFixed := -1;
    end;

    JRange := JStructure.GetValue<TJSONObject>('density_factor');
    Result.Structure.DensityFactorRange.Min := JRange.GetValue<Double>('min');
    Result.Structure.DensityFactorRange.Max := JRange.GetValue<Double>('max');

    JFitness := JSON.GetValue<TJSONObject>('fitness');
    Result.Fitness.wR := JFitness.GetValue<Double>('w_R');
    Result.Fitness.wFWHM := JFitness.GetValue<Double>('w_FWHM');
    Result.Fitness.RMinThreshold := JFitness.GetValue<Double>('R_min_threshold');
    if JFitness.FindValue('delta_theta') <> nil then
      Result.Fitness.DeltaTheta := JFitness.GetValue<Double>('delta_theta')
    else
      Result.Fitness.DeltaTheta := 0;
    if JFitness.FindValue('theta_min') <> nil then
      Result.Fitness.ThetaMin := JFitness.GetValue<Double>('theta_min')
    else
      Result.Fitness.ThetaMin := 0;
    // Polarization
    if JFitness.FindValue('polarization') <> nil then
    begin
      if SameText(JFitness.GetValue<string>('polarization'), 's') then
        Result.Fitness.Polarization := cmS
      else
        Result.Fitness.Polarization := cmSP;
    end
    else
      Result.Fitness.Polarization := cmSP;  // default

    JOptimizer := JSON.GetValue<TJSONObject>('optimizer');
    Result.Optimizer.Population := JOptimizer.GetValue<Integer>('population');
    Result.Optimizer.Iterations := JOptimizer.GetValue<Integer>('iterations');
    Result.Optimizer.Tolerance := JOptimizer.GetValue<Double>('tolerance');
    Result.Optimizer.StagnationLimit := JOptimizer.GetValue<Integer>('stagnation_limit');
    Result.Optimizer.w1 := JOptimizer.GetValue<Double>('w1');
    Result.Optimizer.w2 := JOptimizer.GetValue<Double>('w2');
    Result.Optimizer.JammingMax := JOptimizer.GetValue<Integer>('jamming_max');
    Result.Optimizer.CheckpointEvery := JOptimizer.GetValue<Integer>('checkpoint_every');

    Result.Substrate := JSON.GetValue<string>('substrate');

    if JSON.GetValue('henke_path') is TJSONNull then
      Result.HenkePath := ExtractFilePath(ParamStr(0)) + 'Henke'
    else
      Result.HenkePath := JSON.GetValue<string>('henke_path');

    Result.OutputDir := JSON.GetValue<string>('output_dir');

    if JSON.GetValue('resume_from') is TJSONNull then
      Result.ResumeFrom := ''
    else
      Result.ResumeFrom := JSON.GetValue<string>('resume_from');

    if (JSON.FindValue('template_file') <> nil) and
       not (JSON.GetValue('template_file') is TJSONNull) then
      Result.TemplatePath := JSON.GetValue<string>('template_file')
    else
      Result.TemplatePath := '';
  finally
    JSON.Free;
  end;
end;

class procedure TUniversalIO.SaveConfig(const Config: TUniversalConfig;
  const FileName: string);
var
  JSON, JStructure, JFitness, JOptimizer, JTarget, JRange: TJSONObject;
  JTargets, JPool: TJSONArray;
  i: Integer;
begin
  JSON := TJSONObject.Create;
  try
    // Targets
    JTargets := TJSONArray.Create;
    for i := 0 to High(Config.Targets) do
    begin
      JTarget := TJSONObject.Create;
      JTarget.AddPair('element', Config.Targets[i].Name);
      JTarget.AddPair('lambda', TJSONNumber.Create(Config.Targets[i].Lambda));
      JTarget.AddPair('weight', TJSONNumber.Create(Config.Targets[i].Weight));
      JTargets.Add(JTarget);
    end;
    JSON.AddPair('targets', JTargets);

    // Element pool
    JPool := TJSONArray.Create;
    for i := 0 to High(Config.ElementPool) do
      JPool.Add(Config.ElementPool[i]);
    JSON.AddPair('element_pool', JPool);

    // Structure
    JStructure := TJSONObject.Create;
    JStructure.AddPair('type', Config.Structure.StructureType);
    JStructure.AddPair('layers_per_period', TJSONNumber.Create(Config.Structure.LayersPerPeriod));
    JStructure.AddPair('pure_elements', TJSONBool.Create(Config.Structure.PureElements));

    JRange := TJSONObject.Create;
    JRange.AddPair('min', TJSONNumber.Create(Config.Structure.dRange.Min));
    JRange.AddPair('max', TJSONNumber.Create(Config.Structure.dRange.Max));
    JStructure.AddPair('d', JRange);

    JRange := TJSONObject.Create;
    JRange.AddPair('min', TJSONNumber.Create(Config.Structure.GammaRange.Min));
    JRange.AddPair('max', TJSONNumber.Create(Config.Structure.GammaRange.Max));
    JStructure.AddPair('gamma', JRange);

    JRange := TJSONObject.Create;
    JRange.AddPair('min', TJSONNumber.Create(Config.Structure.NRange.Min));
    JRange.AddPair('max', TJSONNumber.Create(Config.Structure.NRange.Max));
    JStructure.AddPair('N', JRange);

    if Config.Structure.SigmaFixed >= 0 then
      JStructure.AddPair('sigma', TJSONNumber.Create(Config.Structure.SigmaFixed))
    else
    begin
      JRange := TJSONObject.Create;
      JRange.AddPair('min', TJSONNumber.Create(Config.Structure.SigmaRange.Min));
      JRange.AddPair('max', TJSONNumber.Create(Config.Structure.SigmaRange.Max));
      JStructure.AddPair('sigma', JRange);
    end;

    JRange := TJSONObject.Create;
    JRange.AddPair('min', TJSONNumber.Create(Config.Structure.DensityFactorRange.Min));
    JRange.AddPair('max', TJSONNumber.Create(Config.Structure.DensityFactorRange.Max));
    JStructure.AddPair('density_factor', JRange);
    JSON.AddPair('structure', JStructure);

    // Fitness
    JFitness := TJSONObject.Create;
    JFitness.AddPair('w_R', TJSONNumber.Create(Config.Fitness.wR));
    JFitness.AddPair('w_FWHM', TJSONNumber.Create(Config.Fitness.wFWHM));
    JFitness.AddPair('R_min_threshold', TJSONNumber.Create(Config.Fitness.RMinThreshold));
    if Config.Fitness.Polarization = cmS then
      JFitness.AddPair('polarization', 's')
    else
      JFitness.AddPair('polarization', 'sp');
    JFitness.AddPair('delta_theta', TJSONNumber.Create(Config.Fitness.DeltaTheta));
    JFitness.AddPair('theta_min', TJSONNumber.Create(Config.Fitness.ThetaMin));
    JSON.AddPair('fitness', JFitness);

    // Optimizer
    JOptimizer := TJSONObject.Create;
    JOptimizer.AddPair('population', TJSONNumber.Create(Config.Optimizer.Population));
    JOptimizer.AddPair('iterations', TJSONNumber.Create(Config.Optimizer.Iterations));
    JOptimizer.AddPair('tolerance', TJSONNumber.Create(Config.Optimizer.Tolerance));
    JOptimizer.AddPair('stagnation_limit', TJSONNumber.Create(Config.Optimizer.StagnationLimit));
    JOptimizer.AddPair('w1', TJSONNumber.Create(Config.Optimizer.w1));
    JOptimizer.AddPair('w2', TJSONNumber.Create(Config.Optimizer.w2));
    JOptimizer.AddPair('jamming_max', TJSONNumber.Create(Config.Optimizer.JammingMax));
    JOptimizer.AddPair('checkpoint_every', TJSONNumber.Create(Config.Optimizer.CheckpointEvery));
    JSON.AddPair('optimizer', JOptimizer);

    // Top-level fields
    JSON.AddPair('substrate', Config.Substrate);
    if Config.HenkePath = '' then
      JSON.AddPair('henke_path', TJSONNull.Create)
    else
      JSON.AddPair('henke_path', Config.HenkePath);
    JSON.AddPair('output_dir', Config.OutputDir);
    if Config.ResumeFrom <> '' then
      JSON.AddPair('resume_from', Config.ResumeFrom)
    else
      JSON.AddPair('resume_from', TJSONNull.Create);

    if Config.TemplatePath <> '' then
      JSON.AddPair('template_file', Config.TemplatePath)
    else
      JSON.AddPair('template_file', TJSONNull.Create);

    TFile.WriteAllText(FileName, JSON.Format);
  finally
    JSON.Free;
  end;
end;

procedure TUniversalIO.OpenLog(const OutputDir: string;
  const TargetNames: array of string);
var
  i: Integer;
  Header: string;
begin
  FOutputDir := OutputDir;
  EnsureOutputDir;
  AssignFile(FLogFile, TPath.Combine(OutputDir, 'progress.log'));
  Rewrite(FLogFile);
  FLogOpen := True;

  Header := Format('%5s  %8s', ['Iter', 'FoM']);
  for i := 0 to High(TargetNames) do
    Header := Header + Format('  %5s', ['R_' + TargetNames[i]]);
  Header := Header + Format('  %5s', ['Div']);
  WriteLn(FLogFile, Header);
  Flush(FLogFile);
end;

procedure TUniversalIO.LogIteration(Iteration: Integer; FoM: Single;
  const TargetResults: array of TTargetResult;
  const TargetNames: array of string;
  Diversity: Single);
var
  i: Integer;
  Line: string;
begin
  Line := Format('%5d  %8.4f', [Iteration, FoM]);
  for i := 0 to High(TargetResults) do
    Line := Line + Format('  %5.3f', [TargetResults[i].RPeak]);
  Line := Line + Format('  %5.3f', [Diversity]);

  if IsConsole then
    WriteLn(Line);
  if FLogOpen then
  begin
    WriteLn(FLogFile, Line);
    Flush(FLogFile);
  end;
end;

procedure TUniversalIO.CloseLog;
begin
  if FLogOpen then
  begin
    System.CloseFile(FLogFile);
    FLogOpen := False;
  end;
end;

procedure TUniversalIO.SaveBestStructure(const Config: TUniversalConfig;
  const Best: TGenome; FoM: Single;
  const TargetResults: array of TTargetResult;
  const OutputDir: string);
var
  JSON, JResult, JComp, JLayer, JPerElem, JElem: TJSONObject;
  JStructure: TJSONArray;
  JTop, JBottom: TJSONObject;
  JLayers, JSubLayers: TJSONArray;
  JLayerObj, JSubObj, JBottomObj, JBottomStack: TJSONObject;
  LayerValues: TJSONArray;
  NInt, i, j: Integer;
  LayerName: string;
  H1, H2: Single;
begin
  NInt := NRound(Best.N);
  H1 := Best.d * Best.Gamma;
  H2 := Best.d * (1 - Best.Gamma);

  JSON := TJSONObject.Create;
  try
    JSON.AddPair('name', 'Universal Mirror - Optimized');

    JResult := TJSONObject.Create;
    JResult.AddPair('FoM', TJSONNumber.Create(FoM));
    JResult.AddPair('d', TJSONNumber.Create(Best.d));
    JResult.AddPair('gamma', TJSONNumber.Create(Best.Gamma));
    JResult.AddPair('N', TJSONNumber.Create(NInt));
    JResult.AddPair('sigma', TJSONNumber.Create(Best.Sigma));

    JComp := TJSONObject.Create;
    for i := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JLayer := TJSONObject.Create;
      for j := 0 to High(Config.ElementPool) do
        if Best.Composition[i][j] > 0.01 then
          JLayer.AddPair(Config.ElementPool[j],
            TJSONNumber.Create(RoundTo(Best.Composition[i][j], -3)));
      JComp.AddPair('layer_' + IntToStr(i + 1), JLayer);
    end;
    JResult.AddPair('composition', JComp);

    JPerElem := TJSONObject.Create;
    for i := 0 to High(Config.Targets) do
    begin
      JElem := TJSONObject.Create;
      JElem.AddPair('R_peak', TJSONNumber.Create(
        RoundTo(TargetResults[i].RPeak, -4)));
      JElem.AddPair('FWHM', TJSONNumber.Create(
        RoundTo(TargetResults[i].FWHM, -3)));
      JPerElem.AddPair(Config.Targets[i].Name, JElem);
    end;
    JResult.AddPair('per_element', JPerElem);
    JSON.AddPair('optimizer_result', JResult);

    JStructure := TJSONArray.Create;

    JTop := TJSONObject.Create;
    JLayers := TJSONArray.Create;
    for i := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      LayerName := '';
      for j := 0 to High(Config.ElementPool) do
        if Best.Composition[i][j] > 0.01 then
          LayerName := LayerName + Config.ElementPool[j] +
            FormatFloat('0.00', Best.Composition[i][j]);

      LayerValues := TJSONArray.Create;
      if i = 0 then
        LayerValues.Add(RoundTo(H1, -3))
      else
        LayerValues.Add(RoundTo(H2, -3));
      LayerValues.Add(RoundTo(Best.Sigma, -2));
      LayerValues.Add(RoundTo(Best.DensityFactor[i], -2));

      JLayerObj := TJSONObject.Create;
      JLayerObj.AddPair(LayerName, LayerValues);
      JLayers.Add(JLayerObj);
    end;
    JSubObj := TJSONObject.Create;
    JSubObj.AddPair('N', TJSONNumber.Create(NInt));
    JSubObj.AddPair('layers', JLayers);
    JTop.AddPair('top', JSubObj);
    JStructure.Add(JTop);

    JBottom := TJSONObject.Create;
    JSubLayers := TJSONArray.Create;
    JBottomObj := TJSONObject.Create;
    LayerValues := TJSONArray.Create;
    LayerValues.Add(0);
    LayerValues.Add(1);
    LayerValues.Add(8.0);
    JBottomObj.AddPair(Config.Substrate, LayerValues);
    JSubLayers.Add(JBottomObj);
    JBottomStack := TJSONObject.Create;
    JBottomStack.AddPair('N', TJSONNumber.Create(1));
    JBottomStack.AddPair('layers', JSubLayers);
    JBottom.AddPair('bottom', JBottomStack);
    JStructure.Add(JBottom);

    JSON.AddPair('structure', JStructure);

    if not TDirectory.Exists(OutputDir) then
      TDirectory.CreateDirectory(OutputDir);
    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'best_structure.json'),
      JSON.Format(2)
    );
  finally
    JSON.Free;
  end;
end;

procedure TUniversalIO.SaveXRCStructure(const Config: TUniversalConfig;
  const Best: TGenome; Mixer: TMaterialMixer;
  const Templates: TTemplateLibrary;
  const OutputDir: string);
var
  JStruct, JStack, JLayer, JSub: TJSONObject;
  JStacks, JLayers: TJSONArray;
  NInt, i, j, DomIdx, DomIdx0, DomIdx1, TemplIdx: Integer;
  H, SubH, EffDensity: Single;
  MatName, Key: string;
  Templ: TTemplatePair;
begin
  NInt := NRound(Best.N);

  JStruct := TJSONObject.Create;
  try
    JStacks := TJSONArray.Create;
    JStack := TJSONObject.Create;
    JStack.AddPair('T', 'ML');
    JStack.AddPair('N', NInt);

    JLayers := TJSONArray.Create;

    // Check for template
    TemplIdx := -1;
    if Config.Structure.PureElements and (Length(Templates) > 0) then
    begin
      DomIdx0 := 0;
      for j := 1 to High(Config.ElementPool) do
        if Best.Composition[0][j] > Best.Composition[0][DomIdx0] then
          DomIdx0 := j;
      DomIdx1 := 0;
      for j := 1 to High(Config.ElementPool) do
        if Best.Composition[1][j] > Best.Composition[1][DomIdx1] then
          DomIdx1 := j;
      Key := Mixer.GetElementName(DomIdx0) + '/' + Mixer.GetElementName(DomIdx1);
      TemplIdx := FindTemplate(Templates, Key);
    end;

    if TemplIdx >= 0 then
    begin
      // Template-expanded layers
      Templ := Templates[TemplIdx];
      for i := 0 to High(Templ.Layers) do
      begin
        case Templ.Layers[i].ThicknessType of
          ttGamma: SubH := Best.d * Best.Gamma - Templ.GammaReduction;
          ttOneMinusGamma: SubH := Best.d * (1 - Best.Gamma) - Templ.OneMinusGammaReduction;
          ttFixed: SubH := Templ.Layers[i].FixedThickness;
        end;
        if SubH < 0 then SubH := 0;

        JLayer := TJSONObject.Create;
        JLayer.AddPair('M', Templ.Layers[i].Material);
        JLayer.AddPair('H', TJSONNumber.Create(RoundTo(SubH, -2)));
        JLayer.AddPair('HP', False);
        JLayer.AddPair('Hmin', TJSONNumber.Create(RoundTo(SubH * 0.5, -2)));
        JLayer.AddPair('Hmax', TJSONNumber.Create(RoundTo(SubH * 1.5, -2)));
        JLayer.AddPair('ProfileH', '');
        JLayer.AddPair('s', TJSONNumber.Create(RoundTo(Templ.Layers[i].Sigma, -2)));
        JLayer.AddPair('SP', False);
        JLayer.AddPair('Smin', TJSONNumber.Create(RoundTo(Templ.Layers[i].Sigma * 0.5, -2)));
        JLayer.AddPair('Smax', TJSONNumber.Create(RoundTo(Templ.Layers[i].Sigma * 1.5, -2)));
        JLayer.AddPair('ProfileS', '');
        JLayer.AddPair('r', TJSONNumber.Create(RoundTo(Templ.Layers[i].Density, -3)));
        JLayer.AddPair('RP', False);
        JLayer.AddPair('Rmin', TJSONNumber.Create(RoundTo(Templ.Layers[i].Density * 0.5, -3)));
        JLayer.AddPair('Rmax', TJSONNumber.Create(RoundTo(Templ.Layers[i].Density * 1.5, -3)));
        JLayer.AddPair('ProfileR', '');
        JLayers.Add(JLayer);
      end;
    end
    else
    begin
      // Original 2-layer output
      for i := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        DomIdx := 0;
        for j := 1 to High(Config.ElementPool) do
          if Best.Composition[i][j] > Best.Composition[i][DomIdx] then
            DomIdx := j;
        MatName := Mixer.GetElementName(DomIdx);

        if i = 0 then
          H := Best.d * Best.Gamma
        else
          H := Best.d * (1 - Best.Gamma);

        EffDensity := 0;
        for j := 0 to High(Config.ElementPool) do
          EffDensity := EffDensity + Best.Composition[i][j] * Mixer.GetElementDensity(j);
        EffDensity := EffDensity * Best.DensityFactor[i];

        JLayer := TJSONObject.Create;
        JLayer.AddPair('M', MatName);
        JLayer.AddPair('H', TJSONNumber.Create(RoundTo(H, -2)));
        JLayer.AddPair('HP', False);
        JLayer.AddPair('Hmin', TJSONNumber.Create(RoundTo(H * 0.5, -2)));
        JLayer.AddPair('Hmax', TJSONNumber.Create(RoundTo(H * 1.5, -2)));
        JLayer.AddPair('ProfileH', '');
        JLayer.AddPair('s', TJSONNumber.Create(RoundTo(Best.Sigma, -2)));
        JLayer.AddPair('SP', False);
        JLayer.AddPair('Smin', TJSONNumber.Create(RoundTo(Best.Sigma * 0.5, -2)));
        JLayer.AddPair('Smax', TJSONNumber.Create(RoundTo(Best.Sigma * 1.5, -2)));
        JLayer.AddPair('ProfileS', '');
        JLayer.AddPair('r', TJSONNumber.Create(RoundTo(EffDensity, -3)));
        JLayer.AddPair('RP', False);
        JLayer.AddPair('Rmin', TJSONNumber.Create(RoundTo(EffDensity * 0.5, -3)));
        JLayer.AddPair('Rmax', TJSONNumber.Create(RoundTo(EffDensity * 1.5, -3)));
        JLayer.AddPair('ProfileR', '');
        JLayers.Add(JLayer);
      end;
    end;
    JStack.AddPair('Layers', JLayers);
    JStacks.Add(JStack);

    JSub := TJSONObject.Create;
    JSub.AddPair('M', Config.Substrate);
    JSub.AddPair('s', TJSONNumber.Create(0.1));
    JSub.AddPair('r', TJSONNumber.Create(RoundTo(Mixer.GetSubstrateDensity, -3)));

    JStruct.AddPair('Stacks', JStacks);
    JStruct.AddPair('Subs', JSub);

    if not TDirectory.Exists(OutputDir) then
      TDirectory.CreateDirectory(OutputDir);
    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'best_structure_xrc.json'),
      JStruct.Format(2)
    );
  finally
    JStruct.Free;
  end;
end;

procedure TUniversalIO.SaveCurve(const Element: string;
  const Curve: TDataArray; const OutputDir: string);
var
  CurvesDir, FileName: string;
  F: TextFile;
  i: Integer;
begin
  CurvesDir := TPath.Combine(OutputDir, 'best_curves');
  if not TDirectory.Exists(CurvesDir) then
    TDirectory.CreateDirectory(CurvesDir);

  FileName := TPath.Combine(CurvesDir, Element + '.dat');
  AssignFile(F, FileName);
  Rewrite(F);
  try
    WriteLn(F, 'Theta(deg)'#9'Reflectivity');
    for i := 0 to High(Curve) do
      WriteLn(F, Format('%.4f'#9'%.8e', [Curve[i].t, Curve[i].r]));
  finally
    System.CloseFile(F);
  end;
end;

procedure TUniversalIO.SavePopulation(const Config: TUniversalConfig;
  const Particles: array of TParticle;
  TopN: Integer; const OutputDir: string);
var
  JArray: TJSONArray;
  JParticle, JComp, JLayer: TJSONObject;
  i, j, k, m: Integer;
  Sorted: array of Integer;
  Temp: Integer;
begin
  SetLength(Sorted, Length(Particles));
  for i := 0 to High(Sorted) do Sorted[i] := i;

  for i := 1 to High(Sorted) do
  begin
    j := i;
    while (j > 0) and (Particles[Sorted[j]].PBestFoM < Particles[Sorted[j-1]].PBestFoM) do
    begin
      Temp := Sorted[j]; Sorted[j] := Sorted[j-1]; Sorted[j-1] := Temp;
      Dec(j);
    end;
  end;

  if TopN > Length(Sorted) then TopN := Length(Sorted);

  JArray := TJSONArray.Create;
  try
    for i := 0 to TopN - 1 do
    begin
      k := Sorted[i];
      JParticle := TJSONObject.Create;
      JParticle.AddPair('FoM', TJSONNumber.Create(-Particles[k].PBestFoM));

      JComp := TJSONObject.Create;
      for j := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        JLayer := TJSONObject.Create;
        for m := 0 to High(Config.ElementPool) do
          if Particles[k].PBest.Composition[j][m] > 0.01 then
            JLayer.AddPair(Config.ElementPool[m],
              TJSONNumber.Create(RoundTo(Particles[k].PBest.Composition[j][m], -3)));
        JComp.AddPair('layer_' + IntToStr(j + 1), JLayer);
      end;
      JParticle.AddPair('composition', JComp);

      JParticle.AddPair('d', TJSONNumber.Create(Particles[k].PBest.d));
      JParticle.AddPair('gamma', TJSONNumber.Create(Particles[k].PBest.Gamma));
      JParticle.AddPair('N', TJSONNumber.Create(NRound(Particles[k].PBest.N)));
      JParticle.AddPair('sigma', TJSONNumber.Create(Particles[k].PBest.Sigma));

      JArray.Add(JParticle);
    end;

    if not TDirectory.Exists(OutputDir) then
      TDirectory.CreateDirectory(OutputDir);
    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'population.json'),
      JArray.Format(2)
    );
  finally
    JArray.Free;
  end;
end;

procedure TUniversalIO.SaveCheckpoint(const State: TOptState;
  const Config: TUniversalConfig; const OutputDir: string);
var
  JSON, JParticle, JVel: TJSONObject;
  JParticles, JVComp, JVFracs: TJSONArray;
  i, j, k: Integer;

  function GenomeToJSON(const G: TGenome): TJSONObject;
  var
    JCompArr, JFracs: TJSONArray;
    ii, jj: Integer;
  begin
    Result := TJSONObject.Create;
    JCompArr := TJSONArray.Create;
    for ii := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JFracs := TJSONArray.Create;
      for jj := 0 to High(G.Composition[ii]) do
        JFracs.Add(G.Composition[ii][jj]);
      JCompArr.Add(JFracs);
    end;
    Result.AddPair('composition', JCompArr);
    Result.AddPair('d', TJSONNumber.Create(G.d));
    Result.AddPair('gamma', TJSONNumber.Create(G.Gamma));
    Result.AddPair('N', TJSONNumber.Create(G.N));
    Result.AddPair('sigma', TJSONNumber.Create(G.Sigma));
    Result.AddPair('df0', TJSONNumber.Create(G.DensityFactor[0]));
    Result.AddPair('df1', TJSONNumber.Create(G.DensityFactor[1]));
  end;

begin
  if not TDirectory.Exists(OutputDir) then
    TDirectory.CreateDirectory(OutputDir);

  JSON := TJSONObject.Create;
  try
    JSON.AddPair('iteration', TJSONNumber.Create(State.Iteration));
    JSON.AddPair('gbest_fom', TJSONNumber.Create(State.GBestFoM));
    JSON.AddPair('abest_fom', TJSONNumber.Create(State.ABestFoM));
    JSON.AddPair('jamming_count', TJSONNumber.Create(State.JammingCount));
    JSON.AddPair('gbest', GenomeToJSON(State.GBest));
    JSON.AddPair('abest', GenomeToJSON(State.ABest));

    JParticles := TJSONArray.Create;
    for i := 0 to High(State.Particles) do
    begin
      JParticle := TJSONObject.Create;
      JParticle.AddPair('x', GenomeToJSON(State.Particles[i].X));
      JParticle.AddPair('pbest', GenomeToJSON(State.Particles[i].PBest));
      JParticle.AddPair('pbest_fom', TJSONNumber.Create(State.Particles[i].PBestFoM));
      // Velocity
      JVel := TJSONObject.Create;
      JVComp := TJSONArray.Create;
      for j := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        JVFracs := TJSONArray.Create;
        for k := 0 to High(State.Particles[i].V.Composition[j]) do
          JVFracs.Add(State.Particles[i].V.Composition[j][k]);
        JVComp.Add(JVFracs);
      end;
      JVel.AddPair('composition', JVComp);
      JVel.AddPair('d', TJSONNumber.Create(State.Particles[i].V.d));
      JVel.AddPair('gamma', TJSONNumber.Create(State.Particles[i].V.Gamma));
      JVel.AddPair('N', TJSONNumber.Create(State.Particles[i].V.N));
      JVel.AddPair('sigma', TJSONNumber.Create(State.Particles[i].V.Sigma));
      JVel.AddPair('df0', TJSONNumber.Create(State.Particles[i].V.DensityFactor[0]));
      JVel.AddPair('df1', TJSONNumber.Create(State.Particles[i].V.DensityFactor[1]));
      JParticle.AddPair('v', JVel);
      JParticles.Add(JParticle);
    end;
    JSON.AddPair('particles', JParticles);

    TFile.WriteAllText(
      TPath.Combine(OutputDir, 'checkpoint.json'),
      JSON.Format(2)
    );
  finally
    JSON.Free;
  end;
end;

function TUniversalIO.LoadCheckpoint(const FileName: string;
  const Config: TUniversalConfig): TOptState;
var
  JSON, JParticle, JVel: TJSONObject;
  JParticles, JVComp, JVFracs: TJSONArray;
  Content: string;
  i, j, k: Integer;

  function JSONToGenome(JG: TJSONObject): TGenome;
  var
    JCompArr, JFracArr: TJSONArray;
    ii, jj: Integer;
  begin
    Result := CreateGenome(Length(Config.ElementPool));
    JCompArr := JG.GetValue<TJSONArray>('composition');
    for ii := 0 to LAYERS_PER_PERIOD - 1 do
    begin
      JFracArr := JCompArr.Items[ii] as TJSONArray;
      for jj := 0 to JFracArr.Count - 1 do
        Result.Composition[ii][jj] := JFracArr.Items[jj].GetValue<Double>;
    end;
    Result.d := JG.GetValue<Double>('d');
    Result.Gamma := JG.GetValue<Double>('gamma');
    Result.N := JG.GetValue<Double>('N');
    Result.Sigma := JG.GetValue<Double>('sigma');
    Result.DensityFactor[0] := JG.GetValue<Double>('df0');
    Result.DensityFactor[1] := JG.GetValue<Double>('df1');
  end;

begin
  Content := TFile.ReadAllText(FileName);
  JSON := TJSONObject.ParseJSONValue(Content) as TJSONObject;
  try
    Result.Iteration := JSON.GetValue<Integer>('iteration');
    Result.GBestFoM := JSON.GetValue<Double>('gbest_fom');
    Result.ABestFoM := JSON.GetValue<Double>('abest_fom');
    Result.JammingCount := JSON.GetValue<Integer>('jamming_count');
    Result.GBest := JSONToGenome(JSON.GetValue<TJSONObject>('gbest'));
    Result.ABest := JSONToGenome(JSON.GetValue<TJSONObject>('abest'));

    JParticles := JSON.GetValue<TJSONArray>('particles');
    SetLength(Result.Particles, JParticles.Count);
    for i := 0 to JParticles.Count - 1 do
    begin
      JParticle := JParticles.Items[i] as TJSONObject;
      Result.Particles[i].X := JSONToGenome(JParticle.GetValue<TJSONObject>('x'));
      Result.Particles[i].PBest := JSONToGenome(JParticle.GetValue<TJSONObject>('pbest'));
      Result.Particles[i].PBestFoM := JParticle.GetValue<Double>('pbest_fom');
      // Restore velocity
      JVel := JParticle.GetValue<TJSONObject>('v');
      Result.Particles[i].V := CreateVelocity(Length(Config.ElementPool));
      JVComp := JVel.GetValue<TJSONArray>('composition');
      for j := 0 to LAYERS_PER_PERIOD - 1 do
      begin
        JVFracs := JVComp.Items[j] as TJSONArray;
        for k := 0 to JVFracs.Count - 1 do
          Result.Particles[i].V.Composition[j][k] := JVFracs.Items[k].GetValue<Double>;
      end;
      Result.Particles[i].V.d := JVel.GetValue<Double>('d');
      Result.Particles[i].V.Gamma := JVel.GetValue<Double>('gamma');
      Result.Particles[i].V.N := JVel.GetValue<Double>('N');
      Result.Particles[i].V.Sigma := JVel.GetValue<Double>('sigma');
      Result.Particles[i].V.DensityFactor[0] := JVel.GetValue<Double>('df0');
      Result.Particles[i].V.DensityFactor[1] := JVel.GetValue<Double>('df1');
    end;
  finally
    JSON.Free;
  end;
end;

end.
