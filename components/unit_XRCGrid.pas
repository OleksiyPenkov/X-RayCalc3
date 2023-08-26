(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_XRCGrid;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzGrids, VCL.StdCtrls;

type

  TXRCGrid = class (TRzStringGrid)
    private
      FAutoFit: Boolean;

      procedure SetAutofit(const Value: Boolean);
      function GetText: string;
      procedure SetText(const Value: string);
    procedure SetEnableStat(const Value: boolean);

    public
      procedure AutoSizeCol(Column: integer);
      procedure SaveToFile(const FileName: String);
      procedure CalcStat;
    published
      property AutoFit: Boolean read FAutoFit write SetAutofit;
      property Text: string read GetText write SetText;
      property EnableStat: boolean write SetEnableStat;

  end;

procedure Register;

implementation

procedure Register;
begin
  RegisterComponents('X-RayCalcComponents', [TXRCGrid]);
end;

{ TXRCGrid }

procedure TXRCGrid.SetAutofit(const Value: Boolean);
begin
  FAutoFit := Value;
end;

procedure TXRCGrid.SetEnableStat(const Value: boolean);
var
  N : Integer;
begin
  N := Self.ColCount - 1;
  Self.ColCount := Self.ColCount + 2;
  Self.Cells[N + 1, 0] := 'Mean';
  Self.Cells[N + 2, 0] := 'Std';
end;

procedure TXRCGrid.SetText(const Value: string);
begin

end;

procedure TXRCGrid.AutoSizeCol(Column: integer);
var
  i, W, WMax: integer;
begin
  WMax := 0;
  for i := 0 to (Self.RowCount - 1) do begin
    W := Self.Canvas.TextWidth(Self.Cells[Column, i]);
    if W > WMax then
      WMax := W;
  end;
  Self.ColWidths[Column] := WMax + 10;
end;

procedure TXRCGrid.CalcStat;
var
  x, y, N: Integer;
  Values: array of Single;
  Mean, Std: single;
begin
  try
    N := Self.ColCount - 3;
    if N < 1 then Exit;

    SetLength(Values, N);

    for y := 1 to Self.RowCount-1 do
    begin
      Mean := 0;
      for x := 1 to N do
      begin
        Values[x - 1] := StrToFloat(Self.Cells[x, y]);
        Mean := Mean + Values[x - 1];
      end;
      Mean := Mean / N;

      Std := 0;
      for x := 0 to High(Values) do
        Std := Std + Sqr(Values[x] - Mean);

      Std := Sqrt(Std/(N - 1));

      Self.Cells[N + 1, y] := FloatToStrF(Mean, ffFixed, 4, 3);
      Self.Cells[N + 2, y] := FloatToStrF(Std, ffFixed, 4, 3);
    end;
  except
    on Exception do;
  end;
end;

function TXRCGrid.GetText: string;
var
  x, y: Integer;
begin
  Result := '';
  for y := 0 to Self.RowCount-1 do
  begin
    for x := 0 to Self.ColCount - 2 do
      Result := Result + Self.Cells[x, y] + #9;

    Result := Result + Self.Cells[Self.ColCount - 1, y] + #13#10;
  end;
end;

procedure TXRCGrid.SaveToFile;
var
  F: TextFile;
begin
  AssignFile(F, FileName);
  Rewrite(F);
  Write(F, GetText);
  CloseFile(F);
end;

end.
