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
    [Test] procedure FitnessConfigToJSON_ReportsTheScanRuleAndNRef;
    [Test] procedure FitnessConfigToJSON_ScanEcho_MatchesWhatTheEngineScans;
    [Test] procedure FitnessConfigFromJSON_AppliesNRef;
    [Test] procedure FitnessConfigFromJSON_NonPositiveNRef_Raises;

    // --- the engine ---
    [Test] procedure EvaluateStructure_NoPeriodicStack_Raises;
    [Test] procedure EvaluateStructure_TooManyLines_Raises;
    [Test] procedure EvaluateStructure_RuC_MatchesEvaluateLayersDirect;
    [Test] procedure EvaluateStructure_HenkeCwdLockHeld_RaisesServerBusy;

    // --- the peak finder and the width reference (FoM defect, 2026-09-12) ---
    [Test] procedure EvaluateStructure_MoB4C_ShortLinesScoreTheBraggPeak;
    [Test] procedure EvaluateStructure_MoB4C_MorePeriodsScoreHigher;
    [Test] procedure EvaluateStructure_WB4CReference_ScoresTheDesign;
    [Test] procedure EvaluateStructure_ReportsTheScanGridPerLine;
    [Test] procedure EvaluateStructure_BLine_IsTheMainPeakAtEveryN;
    [Test] procedure EvaluateStructure_NarrowClientWindow_FindsTheBroadPeak;
    [Test] procedure EvaluateStructure_WideClientWindow_KeepsTheFirstOrder;
  end;

implementation

uses
  System.SysUtils, System.JSON, System.IOUtils, System.Math,
  System.Classes, System.SyncObjs,
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
  Assert.AreEqual(Double(0.25), Double(C.Fitness.wFWHM), 1E-6);
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
  Assert.AreEqual(Double(0.25), Double(C.Fitness.wFWHM), 1E-6, 'w_FWHM still defaults');
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
                '"scan_points":400,"scan_half_range":2.5,"n_ref":13}');
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
  Assert.AreEqual(13, F.NRef);
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

procedure TTestMCPUniversal.FitnessConfigToJSON_ReportsTheScanRuleAndNRef;
var
  F: TFitnessConfig;
  J: TJSONObject;
begin
  F := DefaultFitnessConfig;      // ScanPoints, ScanHalfRange and NRef are 0
  J := FitnessConfigToJSON(F);
  try
    Assert.AreEqual(200, J.GetValue<Integer>('scan_points'),
      'fitness_used must report the 200 the fitness class substitutes, not 0');

    // The scan window of an unset configuration is chosen per line, so there is
    // no single half-range to report: the echo carries the rule, each line
    // carries what the rule came to.
    Assert.AreEqual(Double(0), J.GetValue<Double>('scan_half_range'), 1E-9,
      'an unset scan_half_range is adaptive and must not be echoed as a fixed 5 degrees');
    Assert.IsTrue(J.GetValue<string>('scan_half_range_note').Contains('adaptive'),
      'the echo must say that an unset half-range is adaptive');
    Assert.AreEqual(POINTS_PER_FWHM_REF,
      J.GetValue<Integer>('scan_points_per_fwhm_ref'));
    Assert.AreEqual(SCAN_POINTS_MAX, J.GetValue<Integer>('scan_points_max'));

    Assert.AreEqual(DEFAULT_N_REF, J.GetValue<Integer>('n_ref'),
      'the width reference defaults to DEFAULT_N_REF periods');

    Assert.AreEqual('sp', J.GetValue<string>('polarization'));
    Assert.IsTrue(J.GetValue<string>('theta_min_note').Contains('dark-zone'),
      'theta_min must be labelled as the dark-zone threshold, not the scan start');
  finally
    J.Free;
  end;

  F.ScanPoints := 321;
  F.ScanHalfRange := 1.25;
  F.NRef := 20;
  J := FitnessConfigToJSON(F);
  try
    Assert.AreEqual(321, J.GetValue<Integer>('scan_points'));
    Assert.AreEqual(Double(1.25), J.GetValue<Double>('scan_half_range'), 1E-9);
    Assert.AreEqual(20, J.GetValue<Integer>('n_ref'));
  finally
    J.Free;
  end;
end;

procedure TTestMCPUniversal.FitnessConfigToJSON_ScanEcho_MatchesWhatTheEngineScans;
var
  Config: TUniversalConfig;
  Mixer: TMaterialMixer;
  Fitness: TUniversalFitness;
  Templates: TTemplateLibrary;
  Elements: TArray<string>;
  Lambdas: TArray<Single>;
  Curve: cmd_unit_types.TDataArray;
  Res: TTargetResults;
  G: TGenome;
  J: TJSONObject;
  Step: Double;
  EchoedFloor: Integer;
begin
  // TUniversalFitness computes with the scan-rule constants of
  // unit_universal_types and fitness_used reports those same constants. This is
  // the test that keeps the echo honest: what the engine really scanned for one
  // line has to match what the echo and that line's own facts say it scanned.
  if not HenkeTablesPresent then
  begin
    Assert.Pass('Henke tables Ru/C/SiO2 not found in ' + HenkePath + ' - test skipped');
    Exit;
  end;

  J := FitnessConfigToJSON(DefaultFitnessConfig);
  try
    EchoedFloor := J.GetValue<Integer>('scan_points');
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
  Config.Fitness := DefaultFitnessConfig;   // the adaptive window
  Config.Structure.PureElements := False;
  SetLength(Templates, 0);

  G := MakeGenome(0, 1, 68.5, 0.2, 30);

  Mixer := TMaterialMixer.Create;
  try
    Mixer.Initialize(Elements, Lambdas, 'SiO2', HenkePath);
    Fitness := TUniversalFitness.Create(Mixer, Config, Templates);
    try
      SetLength(Res, 1);
      Fitness.Evaluate(G, Res);
      Curve := Fitness.GetCurve(G, 0);
    finally
      Fitness.Free;
    end;
  finally
    Mixer.Free;
  end;

  Assert.IsTrue(Length(Curve) > 2, 'the engine must return a curve');

  // The curve a client plots is the window the FoM scored.
  Assert.AreEqual(Res[0].ScanPointsUsed, Length(Curve),
    'GetCurve must scan the same grid the figure of merit scored');
  Step := Curve[1].t - Curve[0].t;
  Assert.AreEqual(Double(Res[0].ScanStep), Step, 1E-6,
    'the reported step must be the step of the curve');

  // The configured scan_points is a floor, and the window is the adaptive one.
  Assert.IsTrue(Res[0].ScanPointsUsed >= EchoedFloor,
    Format('scan_points is a floor: %d points scanned against a floor of %d',
      [Res[0].ScanPointsUsed, EchoedFloor]));
  Assert.IsTrue(Res[0].ScanHalf < DEFAULT_SCAN_HALF_RANGE,
    Format('the adaptive window must be narrower than the old fixed 5 degrees; ' +
      'got %.4f', [Res[0].ScanHalf]));

  // The scan ends at the refraction-corrected peak plus the half-range, and
  // refraction puts that peak above the kinematic Bragg angle.
  Assert.IsTrue(Res[0].ThetaPeak > Res[0].ThetaBragg,
    Format('refraction must shift the peak above the kinematic angle %.4f; got %.4f',
      [Res[0].ThetaBragg, Res[0].ThetaPeak]));
  Assert.AreEqual(Double(Res[0].ThetaPeak + Res[0].ScanHalf),
    Double(Curve[High(Curve)].t), 2 * Step,
    'the scan must end at the peak plus the reported half-range');
end;

procedure TTestMCPUniversal.FitnessConfigFromJSON_AppliesNRef;
var
  J: TJSONObject;
  F: TFitnessConfig;
begin
  J := ParseObj('{"n_ref":20}');
  try
    F := FitnessConfigFromJSON(J, DefaultFitnessConfig);
  finally
    J.Free;
  end;
  Assert.AreEqual(20, F.NRef, 'n_ref must be taken from the client');

  F := FitnessConfigFromJSON(nil, DefaultFitnessConfig);
  Assert.AreEqual(DEFAULT_N_REF, F.NRef,
    'an absent n_ref must resolve to DEFAULT_N_REF');
end;

procedure TTestMCPUniversal.FitnessConfigFromJSON_NonPositiveNRef_Raises;

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

begin
  Assert.AreEqual('invalid_argument', CodeFor('{"n_ref":0}'),
    'n_ref = 0 is not a number of periods');
  Assert.AreEqual('invalid_argument', CodeFor('{"n_ref":-3}'),
    'a negative n_ref is not a number of periods');
end;

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

procedure TTestMCPUniversal.EvaluateStructure_HenkeCwdLockHeld_RaisesServerBusy;
var
  J: TJSONObject;
  S: TFitStructure;
  Info: TStructureInfo;
  Lines: TArray<TXRFLine>;
  Res: TTargetResults;
  Code: string;
  Holding, Release: TEvent;
  Holder: TThread;
begin
  // A running optimize_mirror job holds HenkeCwdLock for its whole Run (see
  // RunOptimizeJob), from the job's own worker thread. HenkeCwdLock wraps a
  // Windows critical section, which is reentrant for the thread that already
  // holds it - so acquiring it on this test's own thread and then calling
  // EvaluateStructure here would just re-enter it, not exercise TryEnter's
  // failure path. The cheap stand-in therefore needs a second thread to hold
  // the lock while the main thread calls EvaluateStructure.
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

  SetLength(Lines, 1);
  Lines[0].Name := 'Si';
  Lines[0].Lambda := LAMBDA_SI;
  Lines[0].Weight := 1;

  Holding := TEvent.Create(nil, True, False, '');
  Release := TEvent.Create(nil, True, False, '');
  try
    Holder := TThread.CreateAnonymousThread(
      procedure
      begin
        HenkeCwdLock.Acquire;
        try
          Holding.SetEvent;
          Release.WaitFor(INFINITE);
        finally
          HenkeCwdLock.Release;
        end;
      end);
    Holder.FreeOnTerminate := False;
    Holder.Start;
    try
      Holding.WaitFor(INFINITE);
      Code := ErrorCodeOf(
        procedure
        begin
          EvaluateStructure(S, Info, Lines, DefaultFitnessConfig, Res);
        end);
    finally
      Release.SetEvent;
      Holder.WaitFor;
      Holder.Free;
    end;
  finally
    Holding.Free;
    Release.Free;
  end;

  Assert.AreEqual('server_busy', Code,
    'evaluate_lines must fail fast, not block, while a job holds the engine lock');
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

{ ------------------------------- the peak finder and the width reference -- }

{ The figure of merit had two defects, both measured on the 3.8.0.850 server:

  - the scan window reached into the total-reflection plateau and the peak was
    the GLOBAL maximum of that window, so for a long period the short-wavelength
    lines (Na-Si) were scored R ~ 0.98 with a 1-2 degree "width" - the plateau,
    not their Bragg peak;
  - FWHM_ref was lambda / (N d cos theta), which shrinks as 1/N while the real
    peak width saturates at the extinction-limited width, so the width penalty
    grew proportionally to N and the optimizer was driven to N = 3..4.

  These three tests pin the physics the fix has to deliver. }

const
  // The agent's Mo/B4C design, layers top-down as evaluate_lines takes them.
  // The Na-Si lines sit close enough to this period's plateau edge that a
  // +/-5 degree window around their Bragg angle reaches into it.
  MOB4C_JSON =
    '{"substrate":{"material":"SiO2","density":2.65,"sigma":3.0},' +
    '"stacks":[{"N":%d,"layers":[' +
      '{"material":"B4C","thickness":25.5,"sigma":3.0,"density":2.37},' +
      '{"material":"Mo","thickness":12.0,"sigma":3.0,"density":10.22}]}],' +
    '"cap":{"material":"B4C","thickness":10.0,"sigma":3.0,"density":2.37}}';

  // The author's reference design: four sublayers, d = 67.14 A, N = 50.
  WB4C_JSON =
    '{"substrate":{"material":"SiO2","density":2.65,"sigma":0.1},' +
    '"stacks":[{"N":%d,"layers":[' +
      '{"material":"WC","thickness":1.95,"sigma":2.0,"density":6.51},' +
      '{"material":"W","thickness":3.18,"sigma":5.27,"density":19.24},' +
      '{"material":"WC","thickness":4.94,"sigma":9.82,"density":11.82},' +
      '{"material":"B4C","thickness":57.07,"sigma":2.66,"density":2.39}]}]}';

  // The nine lines of the investigation, bare symbols, in this order.
  NINE_LINES_JSON = '["B","C","N","O","F","Na","Mg","Al","Si"]';
  IDX_NA = 5;
  IDX_AL = 7;
  IDX_SI = 8;

function FoMTablesPresent: Boolean;
begin
  Result := TFile.Exists(HenkePath + 'Mo.bin') and
            TFile.Exists(HenkePath + 'B4C.bin') and
            TFile.Exists(HenkePath + 'WC.bin') and
            TFile.Exists(HenkePath + 'W.bin') and
            TFile.Exists(HenkePath + 'SiO2.bin');
end;

/// The nine lines, resolved from bare symbols the way evaluate_lines resolves
/// them.
function NineLines: TArray<TXRFLine>;
var
  A: TJSONArray;
begin
  A := TJSONObject.ParseJSONValue(NINE_LINES_JSON) as TJSONArray;
  Assert.IsNotNull(A, 'the nine-line list does not parse');
  try
    Result := LinesFromJSON(A);
  finally
    A.Free;
  end;
end;

/// One evaluate_lines call without the tool layer: the structure as JSON, the
/// nine lines, the fitness configuration, and the FoM the client would see
/// (higher is better - EvaluateStructure un-negates the engine's value).
function ScoreNineLines(const StructJSON: string; const Fit: TFitnessConfig;
  out Res: TTargetResults; out Info: TStructureInfo): Single;
var
  J: TJSONObject;
  S: TFitStructure;
begin
  J := ParseObj(StructJSON);
  try
    S := StructureFromJSON(J, Info);
  finally
    J.Free;
  end;
  Result := EvaluateStructure(S, Info, NineLines, Fit, Res);
end;

/// Every line of one evaluation, for the message of a failing acceptance
/// number: the angles, the peak, the width and the grid it was measured on.
function LineTable(const Res: TTargetResults): string;
var
  Lines: TArray<TXRFLine>;
  i: Integer;
begin
  Lines := NineLines;
  Result := '';
  for i := 0 to High(Res) do
    Result := Result + sLineBreak +
      Format('    %-3s lambda %7.3f  theta_B %7.4f  theta_peak %7.4f  ' +
             'R %8.5f  fwhm %8.5f  step %8.5f  points %5d  valid %s',
        [Lines[i].Name, Lines[i].Lambda, Res[i].ThetaBragg, Res[i].ThetaPeak,
         Res[i].RPeak, Res[i].FWHM, Res[i].ScanStep, Res[i].ScanPointsUsed,
         BoolToStr(Res[i].Valid, True)]);
end;

procedure TTestMCPUniversal.EvaluateStructure_MoB4C_ShortLinesScoreTheBraggPeak;
var
  Res: TTargetResults;
  Info: TStructureInfo;
begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  ScoreNineLines(Format(MOB4C_JSON, [20]), DefaultFitnessConfig, Res, Info);

  Assert.IsTrue(Res[IDX_SI].Valid, 'Si must have a Bragg peak for this period');

  // On the plateau Si scored 0.948 with a width of 0.87 degrees.
  Assert.IsTrue((Res[IDX_SI].RPeak >= 0.14) and (Res[IDX_SI].RPeak <= 0.19),
    Format('Si r_peak must be its Bragg peak (0.14..0.19), not the ' +
      'total-reflection plateau; got %.4f', [Res[IDX_SI].RPeak]));
  Assert.IsTrue(Res[IDX_SI].FWHM < 0.4,
    Format('Si fwhm must be the Bragg width, below 0.4 degrees; got %.4f',
      [Res[IDX_SI].FWHM]));

  Assert.IsTrue((Res[IDX_AL].RPeak >= 0.13) and (Res[IDX_AL].RPeak <= 0.19),
    Format('Al r_peak must be its Bragg peak (0.13..0.19); got %.4f',
      [Res[IDX_AL].RPeak]));
end;

procedure TTestMCPUniversal.EvaluateStructure_MoB4C_MorePeriodsScoreHigher;
var
  Res20, Res50: TTargetResults;
  Info20, Info50: TStructureInfo;
  FoM20, FoM50: Single;
begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  FoM20 := ScoreNineLines(Format(MOB4C_JSON, [20]), DefaultFitnessConfig,
    Res20, Info20);
  FoM50 := ScoreNineLines(Format(MOB4C_JSON, [50]), DefaultFitnessConfig,
    Res50, Info50);

  // More periods reflect more: the B K-alpha peak of this design rises from
  // 0.008 at N = 10 to 0.35 at N = 200. With FWHM_ref tied to N the FoM fell
  // instead (-1.17 at N = 20 against -2.64 at N = 50), which is what drove the
  // optimizer to three-period structures.
  Assert.IsTrue(Res50[0].RPeak > Res20[0].RPeak,
    Format('the B peak must grow with N: %.5f at N=20 against %.5f at N=50',
      [Res20[0].RPeak, Res50[0].RPeak]));
  Assert.IsTrue(FoM50 > FoM20,
    Format('N=50 must score better than N=20; got %.4f against %.4f',
      [FoM50, FoM20]));
end;

procedure TTestMCPUniversal.EvaluateStructure_WB4CReference_ScoresTheDesign;
var
  Res, Res20: TTargetResults;
  Info, Info20: TStructureInfo;
  FoM, FoM20: Single;
begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  FoM := ScoreNineLines(Format(WB4C_JSON, [50]), DefaultFitnessConfig, Res, Info);

  Assert.AreEqual(50, Info.N, 'the reference design repeats 50 times');
  Assert.IsTrue((Info.Period > 67.0) and (Info.Period < 67.2),
    Format('the reference period is 67.14 A; got %.3f', [Info.Period]));

  Assert.IsTrue((Res[IDX_NA].RPeak >= 0.35) and (Res[IDX_NA].RPeak <= 0.48),
    Format('Na r_peak must be 0.35..0.48; got %.4f%s',
      [Res[IDX_NA].RPeak, LineTable(Res)]));
  Assert.IsTrue(Res[IDX_SI].FWHM < 0.15,
    Format('Si fwhm must be below 0.15 degrees; got %.4f%s',
      [Res[IDX_SI].FWHM, LineTable(Res)]));

  // The score itself is judged relatively. The remaining cost of this design is
  // the width penalty on its long-wavelength lines, whose real peaks are
  // extinction-broadened to 1.0-1.6 times the kinematic width of DEFAULT_N_REF
  // periods - physics, not a defect - so the absolute number depends on w_FWHM
  // and n_ref, which are the author's to set. What must hold for any sane pair
  // of those is that the reference design beats its own shorter version and is
  // nowhere near the -16.7 the plateau used to score it.
  FoM20 := ScoreNineLines(Format(WB4C_JSON, [20]), DefaultFitnessConfig,
    Res20, Info20);
  Assert.IsTrue(FoM > FoM20,
    Format('N=50 must score better than N=20; got %.4f against %.4f%s',
      [FoM, FoM20, LineTable(Res)]));
  Assert.IsTrue(FoM > -16.7,
    Format('the plateau scored this design -16.7; got %.4f%s',
      [FoM, LineTable(Res)]));
end;

procedure TTestMCPUniversal.EvaluateStructure_ReportsTheScanGridPerLine;
var
  Res: TTargetResults;
  Info: TStructureInfo;
  i: Integer;
begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  ScoreNineLines(Format(WB4C_JSON, [50]), DefaultFitnessConfig, Res, Info);

  for i := 0 to High(Res) do
  begin
    if not Res[i].Valid then
      Continue;
    if Res[i].RPeak <= 0 then
      Continue;   // a dark line measured nothing, and says so

    Assert.IsTrue(Res[i].ScanPointsUsed >= DEFAULT_SCAN_POINTS,
      Format('line %d: scan_points is a floor, got %d points',
        [i, Res[i].ScanPointsUsed]));
    Assert.IsTrue(Res[i].ScanPointsUsed <= SCAN_POINTS_MAX,
      Format('line %d: %d points exceeds the cap', [i, Res[i].ScanPointsUsed]));
    Assert.IsTrue(Res[i].ScanStep > 0,
      Format('line %d: a scanned line must report its step', [i]));
    // The window is the half-range either side of BOTH the kinematic and the
    // refraction-corrected angle, so its span is 2 * half plus the shift
    // between them.
    Assert.IsTrue(Res[i].ScanStep * Res[i].ScanPointsUsed <=
                  2 * Res[i].ScanHalf + Abs(Res[i].ThetaPeak - Res[i].ThetaBragg)
                  + Res[i].ScanStep,
      Format('line %d: the grid must fit inside the reported window ' +
        '(step %.5f x %d points against half %.4f and a shift of %.4f)',
        [i, Res[i].ScanStep, Res[i].ScanPointsUsed, Res[i].ScanHalf,
         Res[i].ThetaPeak - Res[i].ThetaBragg]));
    Assert.IsTrue(Res[i].ThetaPeak >= Res[i].ThetaBragg,
      Format('line %d: refraction shifts the peak up, never down', [i]));

    // The point of the grid rule: the width is measured over many steps, not
    // read off two or three of them.
    Assert.IsTrue(Res[i].FWHM > 2 * Res[i].ScanStep,
      Format('line %d: fwhm %.5f is not resolved by a step of %.5f',
        [i, Res[i].FWHM, Res[i].ScanStep]));
  end;
end;

{ The B K-alpha line is the hard case for the peak rule: at 67.6 A its Bragg
  angle is steep (64 deg for the agent design, 30 deg for the reference), its
  peak is degrees wide, and refraction near the B K edge shifts it by more than
  a degree. Taking the local maximum NEAREST the expected angle picked a
  sidelobe at N = 100 and 200, and a window centred on an over-estimated
  refraction shift lost the peak entirely. The peak is therefore the HIGHEST
  interior local maximum of a window that spans both the kinematic and the
  refraction-corrected angle: the plateau tail is monotonic and has no interior
  maximum, so it still cannot win, and a sidelobe is by definition lower than
  the main peak. Values measured on the engine at 12d22dc with the rule
  corrected. }

procedure TTestMCPUniversal.EvaluateStructure_BLine_IsTheMainPeakAtEveryN;

  procedure CheckB(const StructJSON, What: string; Expected: Single);
  var
    Res: TTargetResults;
    Info: TStructureInfo;
  begin
    ScoreNineLines(StructJSON, DefaultFitnessConfig, Res, Info);
    Assert.IsTrue(Res[0].RPeak > 0,
      Format('%s: B must not be dark%s', [What, LineTable(Res)]));
    Assert.AreEqual(Double(Expected), Double(Res[0].RPeak), 0.1 * Expected,
      Format('%s: B r_peak must be the main peak, about %.3f%s',
        [What, Expected, LineTable(Res)]));
  end;

begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  // A sidelobe scored 0.017 with a 3.4-3.6 degree width for both of these.
  CheckB(Format(MOB4C_JSON, [100]), 'Mo/B4C N=100', 0.253);
  CheckB(Format(MOB4C_JSON, [200]), 'Mo/B4C N=200', 0.351);

  // This one went dark: the main peak fell outside a window centred on the
  // refraction-corrected angle alone.
  CheckB(Format(WB4C_JSON, [200]), 'W/B4C reference N=200', 0.220);
end;

procedure TTestMCPUniversal.EvaluateStructure_NarrowClientWindow_FindsTheBroadPeak;
var
  Res: TTargetResults;
  Info: TStructureInfo;
  Fit: TFitnessConfig;
begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  // Half a degree either side of a peak several degrees wide: the window sits
  // entirely on the peak's flank and holds no interior maximum at all. As long
  // as the plateau did not clip the scan, the honest answer is the best point
  // in the window, not "dark".
  Fit := DefaultFitnessConfig;
  Fit.ScanHalfRange := 0.5;

  ScoreNineLines(Format(MOB4C_JSON, [50]), Fit, Res, Info);

  Assert.IsTrue(Res[0].RPeak > 0,
    Format('a narrow client window must not make a broad peak dark%s',
      [LineTable(Res)]));
  Assert.AreEqual(Double(0.120), Double(Res[0].RPeak), 0.012,
    Format('B r_peak in a 0.5 degree window must be about 0.120%s',
      [LineTable(Res)]));
end;

procedure TTestMCPUniversal.EvaluateStructure_WideClientWindow_KeepsTheFirstOrder;
var
  Res: TTargetResults;
  Info: TStructureInfo;
  Fit: TFitnessConfig;
begin
  if not FoMTablesPresent then
  begin
    Assert.Pass('Henke tables Mo/B4C/WC/W/SiO2 not found in ' + HenkePath +
      ' - test skipped');
    Exit;
  end;

  // Five degrees either side of Si's 3.0 degree Bragg angle puts its SECOND
  // order, near 6.5 degrees, inside the window. The peak of a line is its first
  // order: a candidate maximum is kept only when 2 d sin(theta) / lambda, with
  // the refraction-corrected sine, is within half an order of 1.
  Fit := DefaultFitnessConfig;
  Fit.ScanHalfRange := 5.0;

  ScoreNineLines(Format(MOB4C_JSON, [50]), Fit, Res, Info);

  Assert.AreEqual(Double(0.425), Double(Res[IDX_SI].RPeak), 0.0425,
    Format('Si must be scored on its first order, about 0.425%s',
      [LineTable(Res)]));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestMCPUniversal);

end.
