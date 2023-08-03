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

    public
      procedure AutoSizeCol(Column: integer);
      procedure SaveToFile(const FileName: String);
    published
      property AutoFit: Boolean read FAutoFit write SetAutofit;
      property Text: string read GetText write SetText;
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

procedure TXRCGrid.SaveToFile(const FileName: String);
var
  F: TextFile;
begin
  AssignFile(F, FileName);
  Rewrite(F);
  Write(F, GetText);
  CloseFile(F);
end;

end.
