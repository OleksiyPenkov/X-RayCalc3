unit unit_SavitzkyGolay;

interface

uses
  System.SysUtils, System.Math, System.Types, System.Classes, unit_Types;

type
  TSavitzkyGolay = class
  private
    class function CalculateCoefficients(order, windowSize: Integer): TArray<Double>;
  public
    class procedure SmoothCurve(var data: TDataArray; order, windowSize: Integer);
  end;

implementation


class function TSavitzkyGolay.CalculateCoefficients(order, windowSize: Integer): TArray<Double>;
var
  i, j, k: Integer;
  sum, factor: Double;
  coefficients: TArray<Double>;
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

  // Normalize coefficients
//  sum := 0;
//  for i := 0 to windowSize - 1 do
//    sum := sum + coefficients[i];
  sum := Abs(coefficients[windowSize - 1] - coefficients[0]);
  for i := 0 to windowSize - 1 do
    coefficients[i] := coefficients[i] / sum;

  Result := coefficients;
end;

class procedure TSavitzkyGolay.SmoothCurve(var data: TDataArray; order, windowSize: Integer);
var
  i, j, k, halfWindowSize: Integer;
  coefficients: TArray<Double>;
  smoothedData: TArray<Double>;
  Delta:Single;
begin
  halfWindowSize := (windowSize - 1) div 2;
  coefficients := CalculateCoefficients(order, windowSize);
  SetLength(smoothedData, Length(data));

  Delta := data[1].t - data[0].t;
  for I := 0 to High(data) do
    smoothedData[i] := Data[i].r;

  for i := halfWindowSize to Length(data) - halfWindowSize - 1 do
  begin
    for j := -halfWindowSize to halfWindowSize do
      smoothedData[i] := smoothedData[i] + coefficients[j + halfWindowSize] * data[i + j].r * delta;
  end;

  for i := halfWindowSize to Length(data) - halfWindowSize - 1 do
    data[i].r := smoothedData[i];
end;

end.
