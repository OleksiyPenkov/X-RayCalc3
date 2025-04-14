(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_SavitzkyGolay;

interface

uses
  System.SysUtils, System.Math, System.Types, System.Classes, unit_Types;

type
  TSavitzkyGolay = class
  protected
    class function CalculateCoefficients(order, windowSize: Integer): TArray<single>;
  public
    class procedure SmoothCurve(var data: TDataArray; order, windowSize: Integer);
  end;

implementation


class function TSavitzkyGolay.CalculateCoefficients(order, windowSize: Integer): TArray<single>;
var
  i, j, k: Integer;
  sum, factor: single;
  coefficients: TArray<single>;
begin
  SetLength(coefficients, windowSize);

  for i := 0 to windowSize - 1 do
  begin
    sum := 0;
    for j := -order to order do
    begin
      factor := 0;
      for k := 0 to order do
        factor := factor + Power(j, k);
      sum := sum + Power(i - (windowSize - 1) / 2, j) * factor;
    end;
    coefficients[i] := sum;
  end;

  Result := coefficients;
end;

class procedure TSavitzkyGolay.SmoothCurve(var data: TDataArray; order, windowSize: Integer);
var
  i, j, halfWindowSize: Integer;
  coefficients: TArray<single>;
  smoothedData: TArray<single>;
begin
  halfWindowSize := (windowSize - 1) div 2;
  coefficients := CalculateCoefficients(order, windowSize);
  SetLength(smoothedData, Length(data));

  for i := halfWindowSize + 1 to Length(data) - halfWindowSize - 1 do
  begin
    smoothedData[i] := 0;
    for j := -halfWindowSize to halfWindowSize do
      smoothedData[i] := smoothedData[i] + coefficients[j + halfWindowSize] * data[i + j].r * (data[i + j].t - data[i + j - 1].t);
  end;

  for i := halfWindowSize to Length(data) - halfWindowSize - 1 do
    data[i].r := smoothedData[i];
end;

end.
