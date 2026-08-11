unit TestUnitTypes;

interface

uses
  DUnitX.TestFramework,
  unit_types;

type
  [TestFixture]
  TTestFitValue = class
  public
    [Test] procedure Test_New;
    [Test] procedure Test_Init_Deviation;
    [Test] procedure Test_Init_MinMax;
    [Test] procedure Test_Init_NoArgs;
    [Test] procedure Test_Seed_InRange;
  end;

  [TestFixture]
  TTestFitStructure = class
  public
    [Test] procedure Test_Total_Empty;
    [Test] procedure Test_Total_WithLayers;
    [Test] procedure Test_TotalNP;
  end;

  [TestFixture]
  TTestLayerProfile = class
  public
    [Test] procedure Test_ProfileToString_Empty;
    [Test] procedure Test_ProfileToString_WithValues;
    [Test] procedure Test_ProfileFromString_Roundtrip;
  end;

  [TestFixture]
  TTestFuncProfileRec = class
  public
    [Test] procedure Test_X_Counter;
    [Test] procedure Test_X_ResetOnFirst;
    [Test] procedure Test_Ord;
    [Test] procedure Test_PIndex;
  end;

  [TestFixture]
  TTestProjectData = class
  public
    [Test] procedure Test_IsModel_True;
    [Test] procedure Test_IsModel_False_WrongGroup;
    [Test] procedure Test_IsModel_False_WrongRowType;
    [Test] procedure Test_PolyD_SetPoly_Roundtrip;
    [Test] procedure Test_SetPoly_StoresOrder;
    [Test] procedure Test_IsFitExtension_True;
    [Test] procedure Test_IsFitExtension_False_NotFromFit;
    [Test] procedure Test_IsFitExtension_False_WrongRowType;
  end;

  [TestFixture]
  TTestFitStructureCopy = class
  public
    [Test] procedure Test_CopyContent;
  end;

implementation

uses
  System.SysUtils, System.Math;

{ TTestFitValue }

procedure TTestFitValue.Test_New;
var FV: TFitValue;
begin
  FV.New(10.0);
  Assert.AreEqual(Single(10.0), FV.V);
  Assert.AreEqual(Single(0.0), FV.min);
  Assert.AreEqual(Single(0.0), FV.max);
  Assert.IsFalse(FV.Paired);
end;

procedure TTestFitValue.Test_Init_Deviation;
var FV: TFitValue;
begin
  FV.New(100.0);
  FV.Init(0.1); // 10% deviation
  // min = 100 * (1 - 0.1) = 90
  // max = 100 * (1 + 0.1) = 110
  Assert.AreEqual(Single(90.0), FV.min, 1E-4);
  Assert.AreEqual(Single(110.0), FV.max, 1E-4);
end;

procedure TTestFitValue.Test_Init_MinMax;
var FV: TFitValue;
begin
  FV.New(50.0);
  FV.Init(20.0, 80.0);
  Assert.AreEqual(Single(20.0), FV.min);
  Assert.AreEqual(Single(80.0), FV.max);
end;

procedure TTestFitValue.Test_Init_NoArgs;
var FV: TFitValue;
begin
  FV.New(42.0);
  FV.Init; // sets min = max = V
  Assert.AreEqual(Single(42.0), FV.min);
  Assert.AreEqual(Single(42.0), FV.max);
end;

procedure TTestFitValue.Test_Seed_InRange;
var
  FV: TFitValue;
  i: Integer;
begin
  RandSeed := 12345;
  FV.New(0);
  FV.Init(10.0, 20.0);
  for i := 1 to 100 do
  begin
    FV.Seed;
    Assert.IsTrue((FV.V >= 10.0) and (FV.V <= 20.0),
      Format('Seed produced %g outside [10,20]', [FV.V]));
  end;
end;

{ TTestFitStructure }

procedure TTestFitStructure.Test_Total_Empty;
var FS: TFitStructure;
begin
  // Single stack with zero layers
  SetLength(FS.Stacks, 1);
  SetLength(FS.Stacks[0].Layers, 0);
  Assert.AreEqual(Word(0), FS.Total);
end;

procedure TTestFitStructure.Test_Total_WithLayers;
var FS: TFitStructure;
begin
  SetLength(FS.Stacks, 2);
  SetLength(FS.Stacks[0].Layers, 3);
  SetLength(FS.Stacks[1].Layers, 2);
  Assert.AreEqual(Word(5), FS.Total);
end;

procedure TTestFitStructure.Test_TotalNP;
var FS: TFitStructure;
begin
  SetLength(FS.Stacks, 2);
  // Stack 0: 3 layers, repeated 2 times
  FS.Stacks[0].N := 2;
  SetLength(FS.Stacks[0].Layers, 3);
  // Stack 1: 1 layer, repeated 5 times
  FS.Stacks[1].N := 5;
  SetLength(FS.Stacks[1].Layers, 1);
  // TotalNP = 3*2 + 1*5 = 11
  Assert.AreEqual(Word(11), FS.TotalNP);
end;

{ TTestLayerProfile }

procedure TTestLayerProfile.Test_ProfileToString_Empty;
var
  LD: TLayerData;
begin
  // H profile (ptH = 0, so p = 1)
  LD.ClearProfiles(1);
  Assert.AreEqual('', LD.ProfileToString(ptH));
end;

procedure TTestLayerProfile.Test_ProfileToString_WithValues;
var
  LD: TLayerData;
  S: string;
begin
  LD.ClearProfiles(1);
  LD.AddProfilePoint(1.5, 1);
  LD.AddProfilePoint(2.5, 1);
  S := LD.ProfileToString(ptH);
  Assert.IsNotEmpty(S);
  Assert.Contains(S, '1.5');
  Assert.Contains(S, '2.5');
  Assert.Contains(S, ';');
end;

procedure TTestLayerProfile.Test_ProfileFromString_Roundtrip;
var
  LD1, LD2: TLayerData;
  S: string;
begin
  LD1.ClearProfiles(1);
  LD1.AddProfilePoint(1.0, 1);
  LD1.AddProfilePoint(2.0, 1);
  LD1.AddProfilePoint(3.0, 1);
  S := LD1.ProfileToString(ptH);

  LD2.ClearProfiles(1);
  LD2.ProfileFromString(1, S);

  Assert.AreEqual(Length(LD1.PP[1]), Length(LD2.PP[1]));
  Assert.AreEqual(LD1.PP[1][0], LD2.PP[1][0], 1E-3);
  Assert.AreEqual(LD1.PP[1][1], LD2.PP[1][1], 1E-3);
  Assert.AreEqual(LD1.PP[1][2], LD2.PP[1][2], 1E-3);
end;

{ TTestFuncProfileRec }

procedure TTestFuncProfileRec.Test_X_Counter;
var FP: TFuncProfileRec;
begin
  // X(1) resets counter to 0, then increments -> returns 1
  // X(2) increments -> returns 2
  // X(3) increments -> returns 3
  Assert.AreEqual(Word(1), FP.X(1));
  Assert.AreEqual(Word(2), FP.X(2));
  Assert.AreEqual(Word(3), FP.X(3));
end;

procedure TTestFuncProfileRec.Test_X_ResetOnFirst;
var FP: TFuncProfileRec;
begin
  // Calling X(1) again should reset the counter
  FP.X(1);
  FP.X(2);
  FP.X(3);
  // Reset
  Assert.AreEqual(Word(1), FP.X(1));
  Assert.AreEqual(Word(2), FP.X(2));
end;

procedure TTestFuncProfileRec.Test_Ord;
var FP: TFuncProfileRec;
begin
  // Ord returns High(C) — the polynomial order derived from array length
  SetLength(FP.C, 4);
  Assert.AreEqual(Word(3), FP.Ord);
end;

procedure TTestFuncProfileRec.Test_PIndex;
var FP: TFuncProfileRec;
begin
  // PIndex = System.Ord(Subj) + 1
  // ptH = 0 -> PIndex = 1
  // ptS = 1 -> PIndex = 2
  // ptRho = 2 -> PIndex = 3
  FP.Subj := ptH;
  Assert.AreEqual(Word(1), FP.PIndex);
  FP.Subj := ptS;
  Assert.AreEqual(Word(2), FP.PIndex);
  FP.Subj := ptRho;
  Assert.AreEqual(Word(3), FP.PIndex);
end;

{ TTestProjectData }

procedure TTestProjectData.Test_IsModel_True;
var PD: TProjectData;
begin
  PD.Group := gtModel;
  PD.RowType := prItem;
  Assert.IsTrue(PD.IsModel);
end;

procedure TTestProjectData.Test_IsModel_False_WrongGroup;
var PD: TProjectData;
begin
  PD.Group := gtData;
  PD.RowType := prItem;
  Assert.IsFalse(PD.IsModel);
end;

procedure TTestProjectData.Test_IsModel_False_WrongRowType;
var PD: TProjectData;
begin
  PD.Group := gtModel;
  PD.RowType := prGroup;
  Assert.IsFalse(PD.IsModel);
end;

procedure TTestProjectData.Test_PolyD_SetPoly_Roundtrip;
var
  PD: TProjectData;
  Src, Dst: TPolyArray;
begin
  // SetPoly stores coefficients into PD.Poly[0..9] + PolyCount, PolyD reads them back
  SetLength(Src, 3);
  Src[0] := 1.5;
  Src[1] := 2.5;
  Src[2] := 3.5;

  PD.RowType := prExtension;
  PD.SetPoly(Src);
  Dst := PD.PolyD;

  Assert.AreEqual(3, Length(Dst));
  Assert.AreEqual(Single(1.5), Dst[0], 1E-5);
  Assert.AreEqual(Single(2.5), Dst[1], 1E-5);
  Assert.AreEqual(Single(3.5), Dst[2], 1E-5);
end;

procedure TTestProjectData.Test_SetPoly_StoresOrder;
var
  PD: TProjectData;
  Src: TPolyArray;
begin
  // SetPoly stores High(PolyD) in PolyCount
  SetLength(Src, 4);
  Src[0] := 10; Src[1] := 20; Src[2] := 30; Src[3] := 40;

  PD.RowType := prExtension;
  PD.SetPoly(Src);

  Assert.AreEqual(3, PD.PolyCount);
end;

procedure TTestProjectData.Test_IsFitExtension_True;
var PD: TProjectData;
begin
  PD.RowType := prExtension;
  PD.FromFit := True;
  Assert.IsTrue(PD.IsFitExtension);
end;

procedure TTestProjectData.Test_IsFitExtension_False_NotFromFit;
var PD: TProjectData;
begin
  // A hand-added extension must never be reported as fit-generated
  PD.RowType := prExtension;
  PD.FromFit := False;
  Assert.IsFalse(PD.IsFitExtension);
end;

procedure TTestProjectData.Test_IsFitExtension_False_WrongRowType;
var PD: TProjectData;
begin
  // FromFit shares storage with the prItem branch of the variant record,
  // so the RowType guard is what makes the predicate safe
  PD.RowType := prItem;
  PD.FromFit := True;
  Assert.IsFalse(PD.IsFitExtension);
end;

{ TTestFitStructureCopy }

procedure TTestFitStructureCopy.Test_CopyContent;
var
  Src, Dst: TFitStructure;
begin
  SetLength(Src.Stacks, 1);
  Src.Stacks[0].N := 3;
  SetLength(Src.Stacks[0].Layers, 2);
  Src.Stacks[0].Layers[0].Material := 'Si';
  Src.Stacks[0].Layers[0].P[1].New(10);
  Src.Stacks[0].Layers[1].Material := 'Au';
  Src.Stacks[0].Layers[1].P[1].New(20);
  Src.Subs.Material := 'Glass';

  Src.CopyContent(Dst);

  Assert.AreEqual(1, Length(Dst.Stacks));
  Assert.AreEqual(Word(3), Dst.Stacks[0].N);
  Assert.AreEqual(2, Length(Dst.Stacks[0].Layers));
  Assert.AreEqual('Si', Dst.Stacks[0].Layers[0].Material);
  Assert.AreEqual(Single(10), Dst.Stacks[0].Layers[0].P[1].V, 1E-5);
  Assert.AreEqual('Au', Dst.Stacks[0].Layers[1].Material);
  Assert.AreEqual('Glass', Dst.Subs.Material);
end;

end.
