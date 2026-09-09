unit TestUniversalFitnessLayers;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestUniversalFitnessLayers = class
  public
    [Test]
    procedure EvaluateLayers_MatchesEvaluate_ForSameGenome;
  end;

implementation

uses
  System.SysUtils, System.IOUtils, System.Math,
  math_complex,
  unit_Config,
  cmd_unit_types,
  unit_materials_mix,
  unit_universal_types,
  unit_universal_templates,
  unit_universal_fitness;

const
  // d = 80 A keeps BOTH lines below the Bragg cut-off, so both targets are
  // evaluated and the cross-reflectivity / purity path is exercised:
  //   Be  lambda = 114.00 -> SinArg = 114.00 / 160 = 0.7125
  //   Mg  lambda =   9.89 -> SinArg =   9.89 / 160 = 0.0618
  TEST_D = 80.0;
  TEST_N = 60;
  TEST_GAMMA = 0.4;
  TEST_SIGMA = 3.0;

procedure TTestUniversalFitnessLayers.EvaluateLayers_MatchesEvaluate_ForSameGenome;
var
  HenkePath: string;
  Config: TUniversalConfig;
  Templates: TTemplateLibrary;
  Mixer: TMaterialMixer;
  Fitness: TUniversalFitness;
  G: TGenome;
  R1, R2: TTargetResults;
  F1, F2: Single;
  Builder: TLayerSetBuilder;
  Lambdas: array of Single;
  Elements: array of string;
  CallCount: Integer;
  CalledIdx: TArray<Integer>;
  i, j: Integer;
begin
  HenkePath := TConfig.SystemDir[sdHenke];
  if not TFile.Exists(IncludeTrailingPathDelimiter(HenkePath) + 'W.bin') then
  begin
    Assert.Pass('Henke table W.bin not found in ' + HenkePath + ' - test skipped');
    Exit;
  end;

  // --- Config ---
  Config := Default(TUniversalConfig);

  SetLength(Config.Lines, 2);
  Config.Lines[0].Name := 'Be';
  Config.Lines[0].Lambda := 114.0;
  Config.Lines[0].Weight := 1.0;
  Config.Lines[1].Name := 'Mg';
  Config.Lines[1].Lambda := 9.89;
  Config.Lines[1].Weight := 1.0;

  SetLength(Config.ElementPool, 2);
  Config.ElementPool[0] := 'W';
  Config.ElementPool[1] := 'Si';

  Config.Structure.StructureType := 'bilayer';
  Config.Structure.LayersPerPeriod := LAYERS_PER_PERIOD;
  Config.Structure.PureElements := True;

  Config.Fitness.wR := 1.0;
  Config.Fitness.wFWHM := 0.5;
  Config.Fitness.RMinThreshold := 0.001;
  Config.Fitness.Polarization := cmSP;
  Config.Fitness.DeltaTheta := 0;
  Config.Fitness.ThetaMin := 0;
  Config.Fitness.wPurity := 1.0;
  Config.Fitness.ScanPoints := 200;
  Config.Fitness.ScanHalfRange := 5.0;

  Config.Substrate := 'Si';
  Config.HenkePath := HenkePath;

  SetLength(Templates, 0);

  SetLength(Elements, 2);
  Elements[0] := 'W';
  Elements[1] := 'Si';
  SetLength(Lambdas, 2);
  Lambdas[0] := 114.0;
  Lambdas[1] := 9.89;

  Mixer := TMaterialMixer.Create;
  try
    Mixer.Initialize(Elements, Lambdas, 'Si', HenkePath);

    Fitness := TUniversalFitness.Create(Mixer, Config, Templates);
    try
      // --- Genome ---
      G := CreateGenome(2);
      G.Composition[0][0] := 1.0;
      G.Composition[0][1] := 0.0;
      G.Composition[1][0] := 0.0;
      G.Composition[1][1] := 1.0;
      G.d := TEST_D;
      G.Gamma := TEST_GAMMA;
      G.N := TEST_N;
      G.Sigma := TEST_SIGMA;
      G.CapH := 0;
      G.CapVariant := 0;

      SetLength(R1, Length(Config.Lines));
      SetLength(R2, Length(Config.Lines));

      // Builder reproduces the non-template bilayer branch of BuildLayers
      // and records which targets it was asked to build.
      CallCount := 0;
      SetLength(CalledIdx, 0);
      Builder :=
        procedure(TargetIdx: Integer; var Layers: TLayers)
        var
          Period, Role, LayerIdx: Integer;
          H1, H2: Single;
          Eps: TComplex;
          Dens: Single;
        begin
          Inc(CallCount);
          SetLength(CalledIdx, CallCount);
          CalledIdx[CallCount - 1] := TargetIdx;

          SetLength(Layers, 2 + TEST_N * LAYERS_PER_PERIOD);

          Layers[0].e.re := 1.0;
          Layers[0].e.im := 0.0;
          Layers[0].H := 0;
          Layers[0].S := 0;

          H1 := TEST_D * TEST_GAMMA;
          H2 := TEST_D * (1 - TEST_GAMMA);

          LayerIdx := 1;
          for Period := 0 to TEST_N - 1 do
            for Role := 0 to LAYERS_PER_PERIOD - 1 do
            begin
              Mixer.CalcMixedEpsilon(G.Composition[Role], 1.0, TargetIdx,
                Eps, Dens);
              Layers[LayerIdx].e := Eps;
              if Role = 0 then
                Layers[LayerIdx].H := H1
              else
                Layers[LayerIdx].H := H2;
              Layers[LayerIdx].S := TEST_SIGMA;
              Layers[LayerIdx].Rho := Dens;
              Inc(LayerIdx);
            end;

          Mixer.CalcSubstrateEpsilon(TargetIdx, Eps);
          Layers[LayerIdx].e := Eps;
          Layers[LayerIdx].H := 1e8;
          Layers[LayerIdx].S := TEST_SIGMA;
        end;

      // EvaluateLayers runs FIRST, on a virgin FLayersBuf: a ComputeFoM that
      // failed to call Builder could not be masked by a stack left behind by
      // a previous Evaluate.
      F2 := Fitness.EvaluateLayers(Builder, TEST_D, TEST_N, R2);

      Assert.AreEqual(Length(Config.Lines), CallCount,
        'Builder must be invoked exactly once per target line');
      for i := 0 to High(CalledIdx) do
        Assert.IsTrue((CalledIdx[i] >= 0) and (CalledIdx[i] <= High(Config.Lines)),
          Format('Builder called with out-of-range TargetIdx %d', [CalledIdx[i]]));
      for i := 0 to High(CalledIdx) do
        for j := i + 1 to High(CalledIdx) do
          Assert.AreNotEqual(CalledIdx[i], CalledIdx[j],
            Format('Builder called twice with the same TargetIdx %d', [CalledIdx[i]]));

      F1 := Fitness.Evaluate(G, R1);

      // Both lines must be below the Bragg cut-off, otherwise the comparison
      // below (and the purity/cross-reflectivity path) would be vacuous.
      for i := 0 to High(Config.Lines) do
        Assert.IsTrue(R1[i].Valid,
          Format('Line %d must have a Bragg peak for this test to mean anything',
            [i]));

      Assert.AreEqual(Double(F1), Double(F2), 1e-6,
        'EvaluateLayers must match Evaluate for the same layer stack');

      for i := 0 to High(Config.Lines) do
      begin
        Assert.AreEqual(R1[i].Valid, R2[i].Valid,
          Format('Valid mismatch for line %d', [i]));
        Assert.AreEqual(Double(R1[i].RPeak), Double(R2[i].RPeak), 1e-6,
          Format('RPeak mismatch for line %d', [i]));
        Assert.AreEqual(Double(R1[i].FWHM), Double(R2[i].FWHM), 1e-6,
          Format('FWHM mismatch for line %d', [i]));
        Assert.AreEqual(Double(R1[i].ThetaBragg), Double(R2[i].ThetaBragg), 1e-6,
          Format('ThetaBragg mismatch for line %d', [i]));
      end;
    finally
      Fitness.Free;
    end;
  finally
    Mixer.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestUniversalFitnessLayers);

end.
