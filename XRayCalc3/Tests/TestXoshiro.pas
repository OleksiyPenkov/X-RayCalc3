(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit TestXoshiro;

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestXoshiro = class
  public
    [Test] procedure Seed42_ReferenceSequence;
    [Test] procedure Seed0_ReferenceSequence;
    [Test] procedure NextDouble_Reference;
    [Test] procedure NextDouble_InUnitInterval;
    [Test] procedure NextIndex_InRange_AndCoversAll;
    [Test] procedure Gaussian_MeanAndVariance;
    [Test] procedure StateCopy_ContinuesIdentically;
  end;

implementation

uses
  System.SysUtils, System.Math, unit_Xoshiro;

procedure TTestXoshiro.Seed42_ReferenceSequence;
var
  R: TXoshiro256;
begin
  R.Seed(42);
  Assert.AreEqual(IntToHex(UInt64($BDD732262FEB6E95), 16), IntToHex(R.S[0], 16), 'splitmix64 state 0');
  Assert.AreEqual(IntToHex(UInt64($581CE1FF0E4AE394), 16), IntToHex(R.S[3], 16), 'splitmix64 state 3');
  Assert.AreEqual(IntToHex(UInt64($15780B2E0C2EC716), 16), IntToHex(R.NextUInt64, 16));
  Assert.AreEqual(IntToHex(UInt64($6104D9866D113A7E), 16), IntToHex(R.NextUInt64, 16));
  Assert.AreEqual(IntToHex(UInt64($AE17533239E499A1), 16), IntToHex(R.NextUInt64, 16));
end;

procedure TTestXoshiro.Seed0_ReferenceSequence;
var
  R: TXoshiro256;
begin
  R.Seed(0);
  Assert.AreEqual(IntToHex(UInt64($99EC5F36CB75F2B4), 16), IntToHex(R.NextUInt64, 16));
  Assert.AreEqual(IntToHex(UInt64($BF6E1F784956452A), 16), IntToHex(R.NextUInt64, 16));
  Assert.AreEqual(IntToHex(UInt64($1A5F849D4933E6E0), 16), IntToHex(R.NextUInt64, 16));
end;

procedure TTestXoshiro.NextDouble_Reference;
var
  R: TXoshiro256;
begin
  R.Seed(42);
  Assert.AreEqual(0.08386297105988216, R.NextDouble, 1E-17);
  R.Seed(0);
  Assert.AreEqual(0.6012629994179048, R.NextDouble, 1E-16);
end;

procedure TTestXoshiro.NextDouble_InUnitInterval;
var
  R: TXoshiro256;
  i: Integer;
  X: Double;
begin
  R.Seed(7);
  for i := 1 to 100000 do
  begin
    X := R.NextDouble;
    Assert.IsTrue((X >= 0) and (X < 1));
  end;
end;

procedure TTestXoshiro.NextIndex_InRange_AndCoversAll;
var
  R: TXoshiro256;
  Hits: array [0 .. 6] of Integer;
  i, k: Integer;
begin
  FillChar(Hits, SizeOf(Hits), 0);
  R.Seed(3);
  for i := 1 to 7000 do
  begin
    k := R.NextIndex(7);
    Assert.IsTrue((k >= 0) and (k < 7));
    Inc(Hits[k]);
  end;
  for k := 0 to 6 do
    Assert.IsTrue(Hits[k] > 800, Format('index %d drawn %d times of 7000', [k, Hits[k]]));
end;

procedure TTestXoshiro.Gaussian_MeanAndVariance;
var
  R: TXoshiro256;
  i: Integer;
  X, Sum, Sum2: Double;
const
  N = 200000;
begin
  R.Seed(11);
  Sum := 0; Sum2 := 0;
  for i := 1 to N do
  begin
    X := R.NextGaussian;
    Sum := Sum + X;
    Sum2 := Sum2 + X * X;
  end;
  Assert.AreEqual(0.0, Sum / N, 0.01, 'mean');
  Assert.AreEqual(1.0, Sum2 / N - Sqr(Sum / N), 0.01, 'variance');
end;

procedure TTestXoshiro.StateCopy_ContinuesIdentically;
var
  A, B: TXoshiro256;
  i: Integer;
begin
  A.Seed(5);
  for i := 1 to 10 do
    A.NextUInt64;
  B := A;                       // a record copy is a saved state
  for i := 1 to 10 do
    Assert.AreEqual(IntToHex(A.NextUInt64, 16), IntToHex(B.NextUInt64, 16));
end;

initialization
  TDUnitX.RegisterTestFixture(TTestXoshiro);

end.
