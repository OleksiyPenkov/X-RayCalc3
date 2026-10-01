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

unit unit_Xoshiro;

(* The sampler's own random numbers: xoshiro256** (Blackman & Vigna, 2018),
   seeded through splitmix64. A value type, so a state is saved by copying
   the record, and the chain never touches System.Random / RandSeed, which
   are process-global and shared with the LFPSO. *)

{$OVERFLOWCHECKS OFF}
{$RANGECHECKS OFF}

interface

type
  TXoshiroState = array [0 .. 3] of UInt64;

  TXoshiro256 = record
    S: TXoshiroState;
    procedure Seed(Value: UInt64);
    function NextUInt64: UInt64;
    function NextDouble: Double;
    function NextGaussian: Double;
    function NextIndex(N: Integer): Integer;
  end;

implementation

uses
  System.Math;

function Rotl(X: UInt64; K: Integer): UInt64; inline;
begin
  Result := (X shl K) or (X shr (64 - K));
end;

procedure TXoshiro256.Seed(Value: UInt64);
var
  i: Integer;
  Z: UInt64;
begin
  for i := 0 to 3 do
  begin
    Value := Value + UInt64($9E3779B97F4A7C15);
    Z := Value;
    Z := (Z xor (Z shr 30)) * UInt64($BF58476D1CE4E5B9);
    Z := (Z xor (Z shr 27)) * UInt64($94D049BB133111EB);
    S[i] := Z xor (Z shr 31);
  end;
end;

function TXoshiro256.NextUInt64: UInt64;
var
  T: UInt64;
begin
  Result := Rotl(S[1] * 5, 7) * 9;
  T := S[1] shl 17;
  S[2] := S[2] xor S[0];
  S[3] := S[3] xor S[1];
  S[1] := S[1] xor S[2];
  S[0] := S[0] xor S[3];
  S[2] := S[2] xor T;
  S[3] := Rotl(S[3], 45);
end;

function TXoshiro256.NextDouble: Double;
begin
  Result := (NextUInt64 shr 11) * (1.0 / 9007199254740992.0);   // 2^-53
end;

function TXoshiro256.NextGaussian: Double;
var
  U1, U2: Double;
begin
  U1 := 1.0 - NextDouble;        // (0, 1]: Ln never sees 0
  U2 := NextDouble;
  Result := Sqrt(-2 * Ln(U1)) * Cos(2 * Pi * U2);
end;

function TXoshiro256.NextIndex(N: Integer): Integer;
begin
  Result := Trunc(NextDouble * N);
  if Result >= N then
    Result := N - 1;
end;

end.
