unit TestMCPUniversal;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestMCPUniversal = class
  public
    // --- the top-k rule ---
    [Test] procedure GenomeKey_IsTheDominantPair;
    [Test] procedure DistinctTopK_BestFirst_CollapsesNearDuplicates;
    [Test] procedure DistinctTopK_KeepsCandidatesThatDifferOnlyInN;
    [Test] procedure DistinctTopK_RespectsK;
    [Test] procedure DistinctTopK_EmptySwarmOrZeroK_IsEmpty;

    // --- genome -> structure ---
    [Test] procedure GenomeToStructure_Bilayer_MirrorsBuildLayers;
    [Test] procedure GenomeToStructure_Template_EmitsSublayersAndCap;

    // --- configuration ---
    [Test] procedure ConfigFromJSON_FillsTheMissingSections;
    [Test] procedure ConfigFromJSON_ResolvesLineSymbols;
    [Test] procedure ConfigFromJSON_KeepsWhatTheClientGave;
    [Test] procedure ConfigFromJSON_MissingElementPool_Raises;
    [Test] procedure ConfigFromJSON_MissingSubstrate_Raises;
    [Test] procedure ConfigFromJSON_PureElementsFalse_Raises;
    [Test] procedure ConfigFromJSON_LinesNotAnArray_SaysSo;
    [Test] procedure ConfigFromJSON_AbsoluteTemplateFile_IsOutsideTheWorkdir;
    [Test] procedure ConfigFromJSON_RelativeTemplateFile_ResolvesInTheWorkdir;

    // --- fitness overrides ---
    [Test] procedure FitnessConfigFromJSON_NoOverrides_IsTheBase;
    [Test] procedure FitnessConfigFromJSON_AppliesEveryKey;
    [Test] procedure FitnessConfigFromJSON_PIsComputedAsSP;
    [Test] procedure FitnessConfigFromJSON_BadPolarization_Raises;
    [Test] procedure FitnessConfigFromJSON_ScanGridIsBounded;
    [Test] procedure FitnessConfigToJSON_ReportsTheScanDefaults;
    [Test] procedure FitnessConfigToJSON_ScanDefaults_AreTheEnginesOwn;

    // --- the engine ---
    [Test] procedure EvaluateStructure_NoPeriodicStack_Raises;
    [Test] procedure EvaluateStructure_TooManyLines_Raises;
    [Test] procedure EvaluateStructure_RuC_MatchesEvaluateLayersDirect;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.IOUtils, System.Math,
  math_complex,
  unit_Config,
  unit_Types,
  cmd_unit_types,
  unit_materials_mix,
  unit_universal_types,
  unit_universal_fitness,
  unit_xrf_lines,
  unit_MCPErrors,
  unit_MCPSandbox,
  unit_MCPStructure,
  unit_MCPUniversal;

const
  // The Ru/C mirror the other MCP fixtures use: d = 68.5 A, N = 30, a Ru cap
  // and a Ru buffer on fused silica.
  RUC_JSON =
    '{"substrate":{"material":"SiO2","density":2.2,"sigma":3.0},' +
    '"stacks":[{"N":30,"layers":[' +
      '{"material":"Ru","thickness":14.7,"sigma":3.0,"density":12.4},' +
      '{"material":"C","thickness":53.8,"sigma":3.0,"density":2.2}]}],' +
    '"cap":{"material":"Ru","thickness":20.0,"sigma":3.0,"density":12.4},' +
    '"buffer":{"material":"Ru","thickness":197.0,"sigma":3.0,"density":12.4}}';

  LAMBDA_B  = 67.6;    // B K-alpha
  LAMBDA_SI = 7.126;   // Si K-alpha

{ ------------------------------------------------------------------ helpers -- }

function ParseObj(const S: string): TJSONObject;
begin
  Result := TJSONObject.ParseJSONValue(S) as TJSONObject;
  Assert.IsNotNull(Result, 'The test fixture JSON does not parse: ' + S);
end;

/// CreateGenome only sizes the composition arrays; SetLength on an array that
/// is already the right length keeps its contents, so a genome assigned over a
/// previous one would inherit its fractions. Every test genome is cleared here.
procedure ClearComposition(var G: TGenome);
var
  Role, i: Integer;
begin
  for Role := 0 to LAYERS_PER_PERIOD - 1 do
    for i := 0 to High(G.Composition[Role]) do
      G.Composition[Role][i] := 0;
end;

/// A genome whose two roles are pure Element0 / Element1 of a two-element pool.
function MakeGenome(Dom0, Dom1: Integer; d, Gamma, N: Single): TGenome;
begin
  Result := CreateGenome(2);
  ClearComposition(Result);
  Result.Composition[0][Dom0] := 1.0;
  Result.Composition[1][Dom1] := 1.0;
  Result.d := d;
  Result.Gamma := Gamma;
  Result.N := N;
  Result.Sigma := 3.0;
end;

/// The five-particle swarm every top-k test works on. Deliberately out of FoM
/// order, so that a DistinctTopK that forgot to sort cannot pass.
///   [0] W/Si d 50   gamma 0.40 N 120  FoM -4.8
///   [1] W/Si d 50   gamma 0.40 N 100  FoM -5.0   <- the global best
///   [2] W/Si d 60   gamma 0.40 N 100  FoM -4.6
///   [3] W/Si d 50.5 gamma 0.41 N 100  FoM -4.9   <- within tolerance of [1]
///   [4] Si/W d 50   gamma 0.40 N 100  FoM -4.7
function MakeSwarm: TParticleArray;

  procedure Put(Idx, Dom0, Dom1: Integer; d, Gamma, N, FoM: Single;
    var A: TParticleArray);
  begin
    A[Idx] := Default(TParticle);
    A[Idx].PBest := MakeGenome(Dom0, Dom1, d, Gamma, N);
    A[Idx].X := A[Idx].PBest;
    A[Idx].PBestFoM := FoM;
    A[Idx].CurrentFoM := FoM;
  end;

begin
  SetLength(Result, 5);
  Put(0, 0, 1, 50.0, 0.40, 120, -4.8, Result);
  Put(1, 0, 1, 50.0, 0.40, 100, -5.0, Result);
  Put(2, 0, 1, 60.0, 0.40, 100, -4.6, Result);
  Put(3, 0, 1, 50.5, 0.41, 100, -4.9, Result);
  Put(4, 1, 0, 50.0, 0.40, 100, -4.7, Result);
end;

function WSiNames: TArray<string>;
begin
  Result := ['W', 'Si'];
end;

function HenkePath: string;
begin
  Result := IncludeTrailingPathDelimiter(TConfig.SystemDir[sdHenke]);
end;

function HenkeTablesPresent: Boolean;
begin
  Result := TFile.Exists(HenkePath + 'Ru.bin') and
            TFile.Exists(HenkePath + 'C.bin') and
            TFile.Exists(HenkePath + 'SiO2.bin');
end;

{ ------------------------------------------------------------- the top-k rule -- }

procedure TTestMCPUniversal.GenomeKey_IsTheDominantPair;
var
  G: TGenome;
begin
  G := MakeGenome(0, 1, 50, 0.4, 100);
  Assert.AreEqual('W/Si', GenomeKey(G, WSiNames));

  G := MakeGenome(1, 0, 50, 0.4, 100);
  Assert.AreEqual('Si/W', GenomeKey(G, WSiNames));

  // A mixed role reports whichever element has the larger fraction.
  G := CreateGenome(2);
  ClearComposition(G);
  G.Composition[0][0] := 0.3;
  G.Composition[0][1] := 0.7;
  G.Composition[1][0] := 0.9;
  G.Composition[1][1] := 0.1;
  Assert.AreEqual('Si/W', GenomeKey(G, WSiNames));
end;

procedure TTestMCPUniversal.DistinctTopK_BestFirst_CollapsesNearDuplicates;
var
  Ranks: TArray<Integer>;
  Swarm: TParticleArray;
begin
  Swarm := MakeSwarm;
  Ranks := DistinctTopK(Swarm, 10, WSiNames);

  Assert.AreEqual(4, Length(Ranks),
    'particle 3 is within 5% in d and 0.05 in gamma of particle 1 and must collapse into it');
  Assert.AreEqual(1, Ranks[0], 'entry 0 must be the particle with the best (lowest) FoM');
  Assert.AreEqual(0, Ranks[1]);
  Assert.AreEqual(4, Ranks[2]);
  Assert.AreEqual(2, Ranks[3]);

  // Best first, all the way down.
  for var i := 1 to High(Ranks) do
    Assert.IsTrue(Swarm[Ranks[i - 1]].PBestFoM <= Swarm[Ranks[i]].PBestFoM,
      Format('rank %d has a better FoM than rank %d', [i, i - 1]));
end;

procedure TTestMCPUniversal.DistinctTopK_KeepsCandidatesThatDifferOnlyInN;
var
  Swarm: TParticleArray;
  Ranks: TArray<Integer>;
begin
  // Two candidates identical but for the period count: both are worth showing.
  SetLength(Swarm, 2);
  Swarm[0] := Default(TParticle);
  Swarm[0].PBest := MakeGenome(0, 1, 50.0, 0.40, 100);
  Swarm[0].PBestFoM := -5.0;
  Swarm[1] := Default(TParticle);
  Swarm[1].PBest := MakeGenome(0, 1, 50.0, 0.40, 140);
  Swarm[1].PBestFoM := -4.9;

  Ranks := DistinctTopK(Swarm, 10, WSiNames);
  Assert.AreEqual(2, Length(Ranks));

  // ... but the same N, and everything else within tolerance, is one candidate.
  Swarm[1].PBest.N := 100.4;      // NRound -> 100
  Ranks := DistinctTopK(Swarm, 10, WSiNames);
  Assert.AreEqual(1, Length(Ranks));
  Assert.AreEqual(0, Ranks[0]);
end;

procedure TTestMCPUniversal.DistinctTopK_RespectsK;
var
  Ranks: TArray<Integer>;
begin
  Ranks := DistinctTopK(MakeSwarm, 2, WSiNames);
  Assert.AreEqual(2, Length(Ranks));
  Assert.AreEqual(1, Ranks[0]);
  Assert.AreEqual(0, Ranks[1]);
end;

procedure TTestMCPUniversal.DistinctTopK_EmptySwarmOrZeroK_IsEmpty;
var
  Empty: TParticleArray;
begin
  SetLength(Empty, 0);
  Assert.AreEqual(0, Length(DistinctTopK(Empty, 5, WSiNames)));
  Assert.AreEqual(0, Length(DistinctTopK(MakeSwarm, 0, WSiNames)));
  Assert.AreEqual(0, Length(DistinctTopK(MakeSwarm, -1, WSiNames)));
end;

{ --------------------------------------------------------- genome -> structure -- }

/// The W/Si configuration both GenomeToStructure tests work on.
function WSiConfig(PureElements: Boolean): TUniversalConfig;
begin
  Result := Default(TUniversalConfig);
  SetLength(Result.ElementPool, 2);
  Result.ElementPool[0] := 'W';
  Result.ElementPool[1] := 'Si';
  Result.Substrate := 'Si';
  Result.Structure.PureElements := PureElements;
  Result.Structure.LayersPerPeriod := LAYERS_PER_PERIOD;
end;

function WSiDensities: TArray<Single>;
begin
  SetLength(Result, 2);
  Result[0] := 19.3;
  Result[1] := 2.33;
end;

/// The layers array of the one stack of a structure object.
function StackLayers(S: TJSONObject): TJSONArray;
begin
  Result := (S.GetValue<TJSONArray>('stacks').Items[0] as TJSONObject)
              .GetValue<TJSONArray>('layers');
end;

procedure AssertLayer(Layers: TJSONArray; Idx: Integer;
  const Material: string; Thickness, Sigma, Density: Double);
var
  L: TJSONObject;
begin
  L := Layers.Items[Idx] as TJSONObject;
  Assert.AreEqual(Material, L.GetValue<string>('material'),
    Format('layer %d material', [Idx]));
  Assert.AreEqual(Thickness, L.GetValue<Double>('thickness'), 1E-4,
    Format('layer %d thickness', [Idx]));
  Assert.AreEqual(Sigma, L.GetValue<Double>('sigma'), 1E-4,
    Format('layer %d sigma', [Idx]));
  Assert.AreEqual(Density, L.GetValue<Double>('density'), 1E-3,
    Format('layer %d density', [Idx]));
end;

procedure TTestMCPUniversal.GenomeToStructure_Bilayer_MirrorsBuildLayers;
var
  G: TGenome;
  C: TUniversalConfig;
  Templates: TTemplateLibrary;
  J: TJSONObject;
  Layers: TJSONArray;
  Subs: TJSONObject;
begin
  G := MakeGenome(0, 1, 50.0, 0.4, 100);   // W / Si, d 50, gamma 0.4, N 100
  G.Sigma := 3.0;
  C := WSiConfig(False);
  SetLength(Templates, 0);

  J := GenomeToStructure(G, C, Templates, WSiNames, WSiDensities, 2.33);
  try
    Assert.AreEqual(1, J.GetValue<TJSONArray>('stacks').Count, 'one stack');
    Assert.AreEqual(100,
      (J.GetValue<TJSONArray>('stacks').Items[0] as TJSONObject).GetValue<Integer>('N'));
    Assert.IsNull(J.FindValue('cap'), 'the plain bilayer path has no cap');

    Layers := StackLayers(J);
    Assert.AreEqual(2, Layers.Count);
    // BuildLayers emits role 0 (d*gamma) first, then role 1 (d*(1-gamma)).
    AssertLayer(Layers, 0, 'W', 20.0, 3.0, 19.3);
    AssertLayer(Layers, 1, 'Si', 30.0, 3.0, 2.33);

    Subs := J.GetValue<TJSONObject>('substrate');
    Assert.AreEqual('Si', Subs.GetValue<string>('material'));
    Assert.AreEqual(Double(3.0), Subs.GetValue<Double>('sigma'), 1E-4,
      'BuildLayers gives the substrate the genome roughness');
    Assert.AreEqual(Double(2.33), Subs.GetValue<Double>('density'), 1E-3);
  finally
    J.Free;
  end;
end;

procedure TTestMCPUniversal.GenomeToStructure_Template_EmitsSublayersAndCap;
var
  G: TGenome;
  C: TUniversalConfig;
  Templates: TTemplateLibrary;
  J, Cap: TJSONObject;
  Layers: TJSONArray;
begin
  // W / B4C(fixed 4 A) / Si, with the fixed sublayer taken out of the gamma
  // layer, and one C cap variant - the shape LoadTemplates produces.
  SetLength(Templates, 1);
  Templates[0].Key := 'W/Si';
  Templates[0].Description := 'test';
  SetLength(Templates[0].Layers, 3);
  Templates[0].Layers[0].Material := 'W';
  Templates[0].Layers[0].ThicknessType := ttGamma;
  Templates[0].Layers[0].Sigma := 3.0;
  Templates[0].Layers[0].Density := 19.3;
  Templates[0].Layers[1].Material := 'B4C';
  Templates[0].Layers[1].ThicknessType := ttFixed;
  Templates[0].Layers[1].FixedThickness := 4.0;
  Templates[0].Layers[1].Sigma := 2.0;
  Templates[0].Layers[1].Density := 2.5;
  Templates[0].Layers[2].Material := 'Si';
  Templates[0].Layers[2].ThicknessType := ttOneMinusGamma;
  Templates[0].Layers[2].Sigma := 3.5;
  Templates[0].Layers[2].Density := 2.33;
  Templates[0].GammaReduction := 4.0;
  Templates[0].OneMinusGammaReduction := 0.0;
  SetLength(Templates[0].Caps, 1);
  Templates[0].Caps[0].Name := 'C';
  Templates[0].Caps[0].Material := 'C';
  Templates[0].Caps[0].Sigma := 2.0;
  Templates[0].Caps[0].Density := 2.05;
  Templates[0].Caps[0].ThicknessRange.Min := 10;
  Templates[0].Caps[0].ThicknessRange.Max := 60;

  G := MakeGenome(0, 1, 50.0, 0.4, 100);
  G.Sigma := 3.0;
  G.CapH := 25.0;
  G.CapVariant := 0;
  C := WSiConfig(True);      // the template path needs pure_elements

  J := GenomeToStructure(G, C, Templates, WSiNames, WSiDensities, 2.33);
  try
    Layers := StackLayers(J);
    Assert.AreEqual(3, Layers.Count, 'one JSON layer per template sublayer');
    // gamma layer: d*gamma - gamma_reduction = 50*0.4 - 4
    AssertLayer(Layers, 0, 'W', 16.0, 3.0, 19.3);
    AssertLayer(Layers, 1, 'B4C', 4.0, 2.0, 2.5);
    // 1-gamma layer: d*(1-gamma) - one_minus_gamma_reduction = 50*0.6
    AssertLayer(Layers, 2, 'Si', 30.0, 3.5, 2.33);

    Cap := J.GetValue<TJSONObject>('cap');
    Assert.IsNotNull(Cap, 'a template cap with CapH > 0 becomes the JSON cap');
    Assert.AreEqual('C', Cap.GetValue<string>('material'));
    Assert.AreEqual(Double(25.0), Cap.GetValue<Double>('thickness'), 1E-4);
    Assert.AreEqual(Double(2.0), Cap.GetValue<Double>('sigma'), 1E-4);
    Assert.AreEqual(Double(2.05), Cap.GetValue<Double>('density'), 1E-3);
  finally
    J.Free;
  end;

  // No cap thickness, no cap layer: a zero-thickness layer is no layer.
  G.CapH := 0;
  J := GenomeToStructure(G, C, Templates, WSiNames, WSiDensities, 2.33);
  try
    Assert.IsNull(J.FindValue('cap'));
    Assert.AreEqual(3, StackLayers(J).Count);
  finally
    J.Free;
  end;
end;

{ ------------------------------------------------------------- configuration -- }

procedure TTestMCPUniversal.ConfigFromJSON_FillsTheMissingSections;
var
  J: TJSONObject;
  C: TUniversalConfig;
begin
  J := ParseObj('{"lines":[{"name":"B","lambda":67.6}],' +
                '"element_pool":["Ru","C"],"substrate":"Si"}');
  try
    C := ConfigFromJSON(J, 'C:\out');
  finally
    J.Free;
  end;

  // optimizer: XRFCalc's own run-config defaults
  Assert.AreEqual(1000, C.Optimizer.Population, 'population');
  Assert.AreEqual(100, C.Optimizer.Iterations, 'iterations');
  Assert.AreEqual(Double(1E-6), Double(C.Optimizer.Tolerance), 1E-12, 'tolerance');
  Assert.AreEqual(200, C.Optimizer.StagnationLimit, 'stagnation_limit');
  Assert.AreEqual(Double(0.4), Double(C.Optimizer.w1), 1E-6, 'w1');
  Assert.AreEqual(Double(0.5), Double(C.Optimizer.w2), 1E-6, 'w2');
  Assert.AreEqual(30, C.Optimizer.JammingMax, 'jamming_max');
  Assert.AreEqual(100, C.Optimizer.CheckpointEvery, 'checkpoint_every');

  // structure
  Assert.AreEqual('bilayer', C.Structure.StructureType);
  Assert.AreEqual(2, C.Structure.LayersPerPeriod);
  Assert.IsTrue(C.Structure.PureElements, 'pure_elements defaults to true');
  Assert.AreEqual(Double(30), Double(C.Structure.dRange.Min), 1E-6);
  Assert.AreEqual(Double(80), Double(C.Structure.dRange.Max), 1E-6);
  Assert.AreEqual(Double(0.15), Double(C.Structure.GammaRange.Min), 1E-6);
  Assert.AreEqual(Double(0.70), Double(C.Structure.GammaRange.Max), 1E-6);
  Assert.AreEqual(Double(40), Double(C.Structure.NRange.Min), 1E-6);
  Assert.AreEqual(Double(200), Double(C.Structure.NRange.Max), 1E-6);
  Assert.AreEqual(Double(3), Double(C.Structure.SigmaFixed), 1E-6, 'sigma is fixed at 3');
  Assert.AreEqual(Double(1), Double(C.Structure.DensityFactorFixed), 1E-6);

  // fitness
  Assert.AreEqual(Double(1.0), Double(C.Fitness.wR), 1E-6);
  Assert.AreEqual(Double(0.5), Double(C.Fitness.wFWHM), 1E-6);
  Assert.AreEqual(Double(0.001), Double(C.Fitness.RMinThreshold), 1E-9);
  Assert.AreEqual(Double(1.0), Double(C.Fitness.wPurity), 1E-6);
  Assert.IsTrue(C.Fitness.Polarization = cmd_unit_types.cmSP, 'polarization defaults to sp');

  // server-owned
  Assert.AreEqual('C:\out', C.OutputDir);
  Assert.AreEqual('', C.ResumeFrom);
  Assert.AreEqual('Si', C.Substrate);
  Assert.AreEqual(2, Length(C.ElementPool));
end;

procedure TTestMCPUniversal.ConfigFromJSON_ResolvesLineSymbols;
var
  J: TJSONObject;
  C: TUniversalConfig;
begin
  J := ParseObj('{"lines":["B","Si"],"element_pool":["Ru","C"],"substrate":"Si"}');
  try
    C := ConfigFromJSON(J, 'C:\out');
  finally
    J.Free;
  end;

  Assert.AreEqual(2, Length(C.Lines));
  Assert.AreEqual('B', C.Lines[0].Name);
  Assert.AreEqual('Si', C.Lines[1].Name);
  Assert.AreEqual(GetXRFLambda('B'), Double(C.Lines[0].Lambda), 1E-4,
    'a bare symbol takes its wavelength from the XRF line table');
  Assert.AreEqual(GetXRFLambda('Si'), Double(C.Lines[1].Lambda), 1E-4);
  Assert.AreEqual(Double(1.0), Double(C.Lines[0].Weight), 1E-6, 'weight defaults to 1');
end;

procedure TTestMCPUniversal.ConfigFromJSON_KeepsWhatTheClientGave;
var
  J: TJSONObject;
  C: TUniversalConfig;
begin
  J := ParseObj('{"lines":[{"name":"B","lambda":67.6,"weight":2.5}],' +
                '"element_pool":["Ru","C"],"substrate":"Si",' +
                '"structure":{"d":{"min":10,"max":20},"sigma":1.5},' +
                '"fitness":{"w_R":3,"polarization":"s"},' +
                '"optimizer":{"population":37,"iterations":9}}');
  try
    C := ConfigFromJSON(J, 'C:\out');
  finally
    J.Free;
  end;

  Assert.AreEqual(37, C.Optimizer.Population, 'a given key wins over the default');
  Assert.AreEqual(9, C.Optimizer.Iterations);
  Assert.AreEqual(200, C.Optimizer.StagnationLimit, 'the rest of the section still defaults');

  Assert.IsTrue(C.Structure.PureElements,
    'pure_elements stays true; v1 refuses an explicit false');
  Assert.AreEqual(Double(10), Double(C.Structure.dRange.Min), 1E-6);
  Assert.AreEqual(Double(20), Double(C.Structure.dRange.Max), 1E-6);
  Assert.AreEqual(Double(1.5), Double(C.Structure.SigmaFixed), 1E-6);
  Assert.AreEqual(Double(0.15), Double(C.Structure.GammaRange.Min), 1E-6, 'gamma still defaults');

  Assert.AreEqual(Double(3), Double(C.Fitness.wR), 1E-6);
  Assert.AreEqual(Double(0.5), Double(C.Fitness.wFWHM), 1E-6, 'w_FWHM still defaults');
  Assert.IsTrue(C.Fitness.Polarization = cmd_unit_types.cmS);

  Assert.AreEqual(Double(67.6), Double(C.Lines[0].Lambda), 1E-4);
  Assert.AreEqual(Double(2.5), Double(C.Lines[0].Weight), 1E-6);
end;

procedure TTestMCPUniversal.ConfigFromJSON_MissingElementPool_Raises;
var
  J: TJSONObject;
begin
  J := ParseObj('{"lines":["B"],"substrate":"Si"}');
  try
    Assert.WillRaise(
      procedure
      begin
        ConfigFromJSON(J, 'C:\out');
      end, EMCPError);
  finally
    J.Free;
  end;
end;

procedure TTestMCPUniversal.ConfigFromJSON_MissingSubstrate_Raises;
var
  J: TJSONObject;
begin
  J := ParseObj('{"lines":["B"],"element_pool":["Ru","C"]}');
  try
    Assert.WillRaise(
      procedure
      begin
        ConfigFromJSON(J, 'C:\out');
      end, EMCPError);
  finally
    J.Free;
  end;
end;

/// The code of the EMCPError Body raises, or '' when it raises nothing. Fails
/// the test when the exception is of some other class.
function ErrorCodeOf(const Body: TProc): string;
begin
  Result := '';
  try
    Body();
  except
    on E: EMCPError do
      Exit(E.Code);
    on E: Exception do
      Assert.Fail('Expected EMCPError, got ' + E.ClassName + ': ' + E.Message);
  end;
end;

procedure TTestMCPUniversal.ConfigFromJSON_PureElementsFalse_Raises;
var
  J: TJSONObject;
  Code: string;
begin
  // v1 optimises pure elements only: a mixed composition cannot be written back
  // as a structure, so a candidate would not reproduce its own figure of merit.
  J := ParseObj('{"lines":["B"],"element_pool":["Ru","C"],"substrate":"Si",' +
                '"structure":{"pure_elements":false}}');
  try
    Code := ErrorCodeOf(
      procedure
      begin
        ConfigFromJSON(J, 'C:\out');
      end);
  finally
    J.Free;
  end;
  Assert.AreEqual('invalid_argument', Code);
end;

procedure TTestMCPUniversal.ConfigFromJSON_LinesNotAnArray_SaysSo;
var
  J: TJSONObject;
  Msg: string;
begin
  J := ParseObj('{"lines":"B","element_pool":["Ru","C"],"substrate":"Si"}');
  try
    Msg := '';
    try
      ConfigFromJSON(J, 'C:\out');
    except
      on E: EMCPError do
        Msg := E.Message;
    end;
  finally
    J.Free;
  end;
  Assert.IsTrue(Msg.Contains('must be an array'),
    'a "lines" that is not an array must not be reported as a missing one, got: ' + Msg);
end;

/// A work directory the sandbox tests resolve against, installed as the global
/// one for the duration of Body and removed again afterwards.
procedure WithWorkDir(const Body: TProc);
var
  Saved: TWorkDir;
  Temp: string;
begin
  Temp := TPath.Combine(TPath.GetTempPath, 'xrcmcp_t9_' + TGUID.NewGuid.ToString);
  TDirectory.CreateDirectory(Temp);
  Saved := WorkDir;
  WorkDir := TWorkDir.Create(Temp);
  try
    Body();
  finally
    WorkDir.Free;
    WorkDir := Saved;
    try
      TDirectory.Delete(Temp, True);
    except
      // a leftover temp folder must not turn into a test failure
    end;
  end;
end;

procedure TTestMCPUniversal.ConfigFromJSON_AbsoluteTemplateFile_IsOutsideTheWorkdir;
var
  Code: string;
begin
  // "template_file" is a path the client chose, so it lives under the work
  // directory like every other client path - an absolute one is refused even
  // when it exists on this machine.
  WithWorkDir(
    procedure
    var
      J: TJSONObject;
    begin
      J := ParseObj('{"lines":["B"],"element_pool":["Ru","C"],"substrate":"Si",' +
                    '"template_file":"C:\\Windows\\win.ini"}');
      try
        Code := ErrorCodeOf(
          procedure
          begin
            ConfigFromJSON(J, 'C:\out');
          end);
      finally
        J.Free;
      end;
    end);
  Assert.AreEqual('path_outside_workdir', Code);

  WithWorkDir(
    procedure
    var
      J: TJSONObject;
    begin
      J := ParseObj('{"lines":["B"],"element_pool":["Ru","C"],"substrate":"Si",' +
                    '"template_file":"..\\escape.json"}');
      try
        Code := ErrorCodeOf(
          procedure
          begin
            ConfigFromJSON(J, 'C:\out');
          end);
      finally
        J.Free;
      end;
    end);
  Assert.AreEqual('path_outside_workdir', Code, '".." must not escape either');
end;

procedure TTestMCPUniversal.ConfigFromJSON_RelativeTemplateFile_ResolvesInTheWorkdir;
begin
  WithWorkDir(
    procedure
    var
      J: TJSONObject;
      C: TUniversalConfig;
    begin
      J := ParseObj('{"lines":["B"],"element_pool":["Ru","C"],"substrate":"Si",' +
                    '"template_file":"templates/mine.json"}');
      try
        C := ConfigFromJSON(J, 'C:\out');
      finally
        J.Free;
      end;
      Assert.AreEqual(
        IncludeTrailingPathDelimiter(WorkDir.Root) + 'templates\mine.json',
        C.TemplatePath,
        'a relative template file resolves under the work directory root');
    end);
end;

{ ---------------------------------------------------------- fitness overrides -- }

procedure TTestMCPUniversal.FitnessConfigFromJSON_NoOverrides_IsTheBase;
var
  Base, F: TFitnessConfig;
  J: TJSONObject;
begin
  Base := DefaultFitnessConfig;

  F := FitnessConfigFromJSON(nil, Base);
  Assert.AreEqual(Double(Base.wR), Double(F.wR), 1E-9);
  Assert.AreEqual(Double(Base.wFWHM), Double(F.wFWHM), 1E-9);
  Assert.AreEqual(Double(Base.wPurity), Double(F.wPurity), 1E-9);
  Assert.AreEqual(0, F.ScanPoints, 'an untouched scan_points stays at the "engine default" 0');

  J := ParseObj('{}');
  try
    F := FitnessConfigFromJSON(J, Base);
  finally
    J.Free;
  end;
  Assert.AreEqual(Double(Base.RMinThreshold), Double(F.RMinThreshold), 1E-9);
  Assert.IsTrue(F.Polarization = Base.Polarization);
end;

procedure TTestMCPUniversal.FitnessConfigFromJSON_AppliesEveryKey;
var
  F: TFitnessConfig;
  J: TJSONObject;
begin
  J := ParseObj('{"w_R":2,"w_FWHM":0.25,"R_min_threshold":0.01,"w_purity":0,' +
                '"polarization":"s","delta_theta":0.02,"theta_min":1.5,' +
                '"scan_points":400,"scan_half_range":2.5}');
  try
    F := FitnessConfigFromJSON(J, DefaultFitnessConfig);
  finally
    J.Free;
  end;

  Assert.AreEqual(Double(2), Double(F.wR), 1E-6);
  Assert.AreEqual(Double(0.25), Double(F.wFWHM), 1E-6);
  Assert.AreEqual(Double(0.01), Double(F.RMinThreshold), 1E-9);
  Assert.AreEqual(Double(0), Double(F.wPurity), 1E-9);
  Assert.IsTrue(F.Polarization = cmd_unit_types.cmS);
  Assert.AreEqual(Double(0.02), Double(F.DeltaTheta), 1E-9);
  Assert.AreEqual(Double(1.5), Double(F.ThetaMin), 1E-6);
  Assert.AreEqual(400, F.ScanPoints);
  Assert.AreEqual(Double(2.5), Double(F.ScanHalfRange), 1E-6);
end;

procedure TTestMCPUniversal.FitnessConfigFromJSON_PIsComputedAsSP;
var
  F: TFitnessConfig;
  J: TJSONObject;
begin
  J := ParseObj('{"polarization":"p"}');
  try
    F := FitnessConfigFromJSON(J, DefaultFitnessConfig);
  finally
    J.Free;
  end;
  Assert.IsTrue(F.Polarization = cmd_unit_types.cmSP,
    'the engine has no pure-p path, so "p" is computed as "sp"');
end;

procedure TTestMCPUniversal.FitnessConfigFromJSON_BadPolarization_Raises;
var
  J: TJSONObject;
begin
  J := ParseObj('{"polarization":"circular"}');
  try
    Assert.WillRaise(
      procedure
      begin
        FitnessConfigFromJSON(J, DefaultFitnessConfig);
      end, EMCPError);
  finally
    J.Free;
  end;
end;

procedure TTestMCPUniversal.FitnessConfigFromJSON_ScanGridIsBounded;

  function CodeFor(const Overrides: string): string;
  var
    J: TJSONObject;
  begin
    J := ParseObj(Overrides);
    try
      Result := ErrorCodeOf(
        procedure
        begin
          FitnessConfigFromJSON(J, DefaultFitnessConfig);
        end);
    finally
      J.Free;
    end;
  end;

var
  J: TJSONObject;
  F: TFitnessConfig;
begin
  // evaluate_lines answers in the same round trip, so the scan grid a client
  // can ask for is bounded at both ends.
  Assert.AreEqual('invalid_argument', CodeFor('{"scan_points":500000000}'),
    'an unbounded scan would hang a synchronous call');
  Assert.AreEqual('invalid_argument', CodeFor('{"scan_points":20001}'));
  Assert.AreEqual('invalid_argument', CodeFor('{"scan_half_range":90.5}'));
  Assert.AreEqual('invalid_argument', CodeFor('{"scan_points":2}'),
    'a scan too coarse to hold a peak and its two half-maximum crossings');
  Assert.AreEqual('invalid_argument', CodeFor('{"scan_points":-1}'));
  Assert.AreEqual('invalid_argument', CodeFor('{"scan_half_range":-1}'));

  // The limits themselves are accepted.
  J := ParseObj('{"scan_points":20000,"scan_half_range":90}');
  try
    F := FitnessConfigFromJSON(J, DefaultFitnessConfig);
  finally
    J.Free;
  end;
  Assert.AreEqual(20000, F.ScanPoints);
  Assert.AreEqual(Double(90), Double(F.ScanHalfRange), 1E-9);
end;

procedure TTestMCPUniversal.FitnessConfigToJSON_ReportsTheScanDefaults;
var
  F: TFitnessConfig;
  J: TJSONObject;
begin
  F := DefaultFitnessConfig;      // ScanPoints and ScanHalfRange are 0 = "engine default"
  J := FitnessConfigToJSON(F);
  try
    Assert.AreEqual(200, J.GetValue<Integer>('scan_points'),
      'fitness_used must report the 200 the fitness class substitutes, not 0');
    Assert.AreEqual(Double(5.0), J.GetValue<Double>('scan_half_range'), 1E-9);
    Assert.AreEqual('sp', J.GetValue<string>('polarization'));
    Assert.IsTrue(J.GetValue<string>('theta_min_note').Contains('dark-zone'),
      'theta_min must be labelled as the dark-zone threshold, not the scan start');
  finally
    J.Free;
  end;

  F.ScanPoints := 321;
  F.ScanHalfRange := 1.25;
  J := FitnessConfigToJSON(F);
  try
    Assert.AreEqual(321, J.GetValue<Integer>('scan_points'));
    Assert.AreEqual(Double(1.25), J.GetValue<Double>('scan_half_range'), 1E-9);
  finally
    J.Free;
  end;
end;

procedure TTestMCPUniversal.FitnessConfigToJSON_ScanDefaults_AreTheEnginesOwn;
var
  Config: TUniversalConfig;
  Mixer: TMaterialMixer;
  Fitness: TUniversalFitness;
  Templates: TTemplateLibrary;
  Elements: TArray<string>;
  Lambdas: TArray<Single>;
  Curve: cmd_unit_types.TDataArray;
  G: TGenome;
  J: TJSONObject;
  Theta, Start, Step, HalfRange: Double;
  EchoedPoints: Integer;
  EchoedHalfRange: Double;
begin
  // TUniversalFitness keeps its two scan defaults in its implementation
  // section, so fitness_used has to carry its own copy of them. This is the
  // test that keeps the copy honest: the numbers reported for a configuration
  // that asks for neither must be the numbers the fitness class actually scans
  // with. If the engine's defaults move, this fails rather than the server
  // quietly reporting a scan that never happened.
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables Ru/C/SiO2 not found in ' + HenkePath + ' - test skipped');
    Exit;
  end;

  J := FitnessConfigToJSON(DefaultFitnessConfig);
  try
    EchoedPoints := J.GetValue<Integer>('scan_points');
    EchoedHalfRange := J.GetValue<Double>('scan_half_range');
  finally
    J.Free;
  end;

  Elements := ['Ru', 'C'];
  SetLength(Lambdas, 1);
  Lambdas[0] := LAMBDA_SI;

  Config := Default(TUniversalConfig);
  SetLength(Config.Lines, 1);
  Config.Lines[0].Name := 'Si';
  Config.Lines[0].Lambda := LAMBDA_SI;
  Config.Lines[0].Weight := 1.0;
  SetLength(Config.ElementPool, 2);
  Config.ElementPool[0] := 'Ru';
  Config.ElementPool[1] := 'C';
  Config.Substrate := 'SiO2';
  Config.Fitness := DefaultFitnessConfig;   // ScanPoints and ScanHalfRange are 0
  Config.Structure.PureElements := False;
  SetLength(Templates, 0);

  G := MakeGenome(0, 1, 68.5, 0.2, 30);

  Mixer := TMaterialMixer.Create;
  try
    Mixer.Initialize(Elements, Lambdas, 'SiO2', HenkePath);
    Fitness := TUniversalFitness.Create(Mixer, Config, Templates);
    try
      Curve := Fitness.GetCurve(G, 0);
    finally
      Fitness.Free;
    end;
  finally
    Mixer.Free;
  end;

  Assert.AreEqual(EchoedPoints, Length(Curve),
    'fitness_used.scan_points must be the number of points the engine scanned');

  // ScanReflectivity runs from Max(theta_min + 0.1, theta - halfRange) to
  // theta + halfRange in ScanPoints steps, so the half range is what the step
  // and the start imply.
  Theta := RadToDeg(ArcSin(LAMBDA_SI / (2 * 68.5)));
  Start := Curve[0].t;
  Step := Curve[1].t - Curve[0].t;
  HalfRange := Start + Step * Length(Curve) - Theta;
  Assert.AreEqual(EchoedHalfRange, HalfRange, 1E-4,
    'fitness_used.scan_half_range must be the half range the engine scanned');
end;

{ ------------------------------------------------------------------- engine -- }

procedure TTestMCPUniversal.EvaluateStructure_NoPeriodicStack_Raises;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  Lines: TArray<TXRFLine>;
  Res: TTargetResults;
begin
  J := ParseObj('{"substrate":{"material":"Si"},' +
                '"stacks":[{"N":1,"layers":[{"material":"Ru","thickness":50}]}]}');
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;
  Assert.AreEqual(-1, Info.PeriodicStackIndex, 'the fixture must have no repeating stack');

  SetLength(Lines, 1);
  Lines[0].Name := 'Si';
  Lines[0].Lambda := LAMBDA_SI;
  Lines[0].Weight := 1;

  Assert.WillRaise(
    procedure
    begin
      EvaluateStructure(S, Info, Lines, DefaultFitnessConfig, Res);
    end, EMCPError,
    'A structure with no repeating stack has no period, so it has no figure of merit');
end;

procedure TTestMCPUniversal.EvaluateStructure_TooManyLines_Raises;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  Lines: TArray<TXRFLine>;
  Res: TTargetResults;
  Code: string;
  i: Integer;
begin
  // ComputeFoM keeps its per-line arrays on the stack, dimensioned MAX_LINES,
  // and Release builds have range checking off, so the refusal has to be at the
  // entry point rather than in the engine.
  J := ParseObj(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;

  SetLength(Lines, MAX_LINES + 1);
  for i := 0 to High(Lines) do
  begin
    Lines[i].Name := 'Si';
    Lines[i].Lambda := LAMBDA_SI;
    Lines[i].Weight := 1;
  end;

  Code := ErrorCodeOf(
    procedure
    begin
      EvaluateStructure(S, Info, Lines, DefaultFitnessConfig, Res);
    end);
  Assert.AreEqual('invalid_argument', Code,
    Format('more than %d lines must be refused before the engine is entered',
      [MAX_LINES]));
end;

procedure TTestMCPUniversal.EvaluateStructure_RuC_MatchesEvaluateLayersDirect;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  Lines: TArray<TXRFLine>;
  Fit: TFitnessConfig;
  ResAdapter, ResDirect: TTargetResults;
  FoMAdapter, FoMDirect: Single;
  Config: TUniversalConfig;
  Mixer: TMaterialMixer;
  Fitness: TUniversalFitness;
  Builder: TLayerSetBuilder;
  Elements: TArray<string>;
  Lambdas: TArray<Single>;
  Templates: TTemplateLibrary;
  RuIdx, CIdx: Integer;
  i: Integer;
begin
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables Ru/C/SiO2 not found in ' + HenkePath + ' - test skipped');
    Exit;
  end;

  J := ParseObj(RUC_JSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;
  Assert.AreEqual(30, Info.N, 'the fixture must repeat 30 times');
  Assert.IsTrue(Info.Period > 0);

  SetLength(Lines, 2);
  Lines[0].Name := 'B';
  Lines[0].Lambda := LAMBDA_B;
  Lines[0].Weight := 1.0;
  Lines[1].Name := 'Si';
  Lines[1].Lambda := LAMBDA_SI;
  Lines[1].Weight := 1.0;

  Fit := DefaultFitnessConfig;

  // --- what the adapter computes ---
  FoMAdapter := EvaluateStructure(S, Info, Lines, Fit, ResAdapter);

  // --- the same thing, built by hand ---
  // Materials in the order the adapter collects them: surface down, substrate
  // last. Cap Ru, then Ru/C of the period, then the Ru buffer, then SiO2.
  Elements := ['Ru', 'C', 'SiO2'];
  SetLength(Lambdas, 2);
  Lambdas[0] := LAMBDA_B;
  Lambdas[1] := LAMBDA_SI;

  Config := Default(TUniversalConfig);
  SetLength(Config.Lines, 2);
  Config.Lines[0] := Lines[0];
  Config.Lines[1] := Lines[1];
  SetLength(Config.ElementPool, 3);
  for i := 0 to 2 do
    Config.ElementPool[i] := Elements[i];
  Config.Fitness := Fit;
  Config.Substrate := 'SiO2';
  Config.Structure.PureElements := False;
  SetLength(Templates, 0);

  Mixer := TMaterialMixer.Create;
  try
    Mixer.Initialize(Elements, Lambdas, 'SiO2', HenkePath);
    RuIdx := Mixer.FindElementIndex('Ru');
    CIdx := Mixer.FindElementIndex('C');
    Assert.IsTrue((RuIdx >= 0) and (CIdx >= 0), 'the mixer must know Ru and C');

    Fitness := TUniversalFitness.Create(Mixer, Config, Templates);
    try
      // vacuum | Ru cap 20 | 30 x (Ru 14.7, C 53.8) | Ru buffer 197 | SiO2
      Builder :=
        procedure(TargetIdx: Integer; var L: TLayers)
        var
          Period, Idx: Integer;
          Eps: TComplex;
        begin
          SetLength(L, 1 + 1 + 30 * 2 + 1 + 1);

          L[0].e.re := 1.0;
          L[0].e.im := 0.0;
          L[0].H := 0;
          L[0].S := 0;

          Idx := 1;
          Mixer.CalcSingleEpsilon(RuIdx, 12.4, TargetIdx, Eps);
          L[Idx].e := Eps;
          L[Idx].H := 20.0;
          L[Idx].S := 3.0;
          L[Idx].Rho := 12.4;
          Inc(Idx);

          for Period := 0 to 29 do
          begin
            Mixer.CalcSingleEpsilon(RuIdx, 12.4, TargetIdx, Eps);
            L[Idx].e := Eps;
            L[Idx].H := 14.7;
            L[Idx].S := 3.0;
            L[Idx].Rho := 12.4;
            Inc(Idx);

            Mixer.CalcSingleEpsilon(CIdx, 2.2, TargetIdx, Eps);
            L[Idx].e := Eps;
            L[Idx].H := 53.8;
            L[Idx].S := 3.0;
            L[Idx].Rho := 2.2;
            Inc(Idx);
          end;

          Mixer.CalcSingleEpsilon(RuIdx, 12.4, TargetIdx, Eps);
          L[Idx].e := Eps;
          L[Idx].H := 197.0;
          L[Idx].S := 3.0;
          L[Idx].Rho := 12.4;
          Inc(Idx);

          Mixer.CalcSubstrateEpsilon(TargetIdx, Eps);
          L[Idx].e := Eps;
          L[Idx].H := 1E8;
          L[Idx].S := 3.0;
          L[Idx].Rho := Mixer.GetSubstrateDensity;
        end;

      FoMDirect := -Fitness.EvaluateLayers(Builder, Info.Period, Info.N, ResDirect);
    finally
      Fitness.Free;
    end;
  finally
    Mixer.Free;
  end;

  // Both lines must actually produce a Bragg peak, otherwise the comparison
  // would be a comparison of two penalties.
  for i := 0 to High(Lines) do
    Assert.IsTrue(ResAdapter[i].Valid,
      Format('line %s must have a Bragg peak for this test to mean anything',
        [Lines[i].Name]));

  Assert.AreEqual(Double(FoMDirect), Double(FoMAdapter), 1E-6,
    'EvaluateStructure must feed EvaluateLayers exactly the layers built by hand');

  for i := 0 to High(Lines) do
  begin
    Assert.AreEqual(ResDirect[i].Valid, ResAdapter[i].Valid,
      Format('Valid mismatch for %s', [Lines[i].Name]));
    Assert.AreEqual(Double(ResDirect[i].ThetaBragg), Double(ResAdapter[i].ThetaBragg), 1E-6,
      Format('ThetaBragg mismatch for %s', [Lines[i].Name]));
    Assert.AreEqual(Double(ResDirect[i].RPeak), Double(ResAdapter[i].RPeak), 1E-6,
      Format('RPeak mismatch for %s', [Lines[i].Name]));
    Assert.AreEqual(Double(ResDirect[i].FWHM), Double(ResAdapter[i].FWHM), 1E-6,
      Format('FWHM mismatch for %s', [Lines[i].Name]));
  end;

  // The Si Bragg angle is the textbook one for this period.
  Assert.AreEqual(RadToDeg(ArcSin(LAMBDA_SI / (2 * Info.Period))),
    Double(ResAdapter[1].ThetaBragg), 1E-4);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPUniversal);

end.
