﻿unit unit_XRCStackControl;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, RzBckgnd, unit_XRCLayerControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface, unit_Types;

type

  TLayers = array of TXRCLayerControl;

  TXRCStack = class (TRzPanel)
    private
      lblLayers: TRzLabel;
      RzSeparator: TRzSeparator;


      FLayers: TLayers;
      FID: Integer;
      FN: Integer;
      FTitle: string;
      FSubstrate: Boolean;
      FEnablePairing: Boolean;
      FLinkedLayers: array [0..1] of Integer;

      procedure ClearLayers;
      procedure SetSelected(const Value: Boolean);
      procedure UpdateInfo;
      function GetLayersData: TLayersData;
      procedure SetIncrement(const Value: Single);
      function GetMaterialsList: TMaterialsList;
      procedure SetID(const Value: Integer);
      procedure UpdateLayersStatus(const Pairable: Boolean);
      procedure SetLayerColor(const ID: Integer);
      procedure RealignLayers;
    protected
      { Protected declarations }
      procedure FOnClick(Sender: TObject);
      procedure FOnDoubleClick(Sender: TObject);
    public
      constructor Create(AOwner: TComponent; const Title: string; const N: integer);
      destructor  Destroy; override;

      function AddLayer(Data: TLayerData; Pos: integer = -1): integer;
      procedure AddSubstrate(const Material: string; s, rho: single);
      procedure UpdateLayer(const Index: integer; AData: TLayerData);
      procedure DeleteLayer(const Index: integer);
      procedure UpdateLayersID;

      property Selected: Boolean write SetSelected;
      property ID: Integer read FID write SetID;
      property N:integer read FN;
      procedure Edit;
      property Layers:TLayers read FLayers write FLayers;
      property LayerData: TLayersData read GetLayersData;
      property Increment:Single write SetIncrement;
      property Title: string read FTitle;
      property Materials: TMaterialsList read GetMaterialsList;
      procedure ClearSelection;
      procedure Select(const LayerID: integer);
      procedure EnablePairing(const Enabled: Boolean);
      procedure LinkLayer(const LayerID: Integer);
  end;

implementation

uses
  unit_SMessages, editor_Stack;

{ TXRCStack }

procedure TXRCStack.SetLayerColor(const ID: Integer);
begin
  if (ID mod 2) = 0 then FLayers[ID].Color := $00FFE3C1
    else FLayers[ID].Color := $00FFD29B;
end;

function TXRCStack.AddLayer(Data: TLayerData; Pos: integer): integer;
var
  Count, i: Integer;
  Inserted: Boolean;
begin
  Count := Length(FLayers);
  if Pos = -1 then
  begin
    SetLength(FLayers, Count + 1);
    Pos := Count;
    Inserted := False;
  end
  else
  begin
    Insert(Nil, FLayers, Pos);
    Inserted := True;
  end;
  Data.StackID := FID;
  Data.LayerID := Pos;

  FLayers[Pos] := TXRCLayerControl.Create(Self, 0, Data);
  FLayers[Pos].Parent := Self;
  FLayers[Pos].Pairable := FN > 1;

  lblLayers.Top := 1;
  ClientHeight := 45 + (Count + 1) * (FLayers[Pos].Height + 3);
  if Inserted then
  begin
    UpdateLayersID;
    RealignLayers;
  end
  else begin
    SetLayerColor(Pos);
    FLayers[Pos].Top := ClientHeight - 10;
  end;
  Result := Pos;
end;

procedure TXRCStack.AddSubstrate(const Material: string; s, rho: single);
var
  Data: TLayerData;
begin
  SetLength(FLayers, 1);
  Data.Material := Material;
  Data.P[1].V := 1E8;
  Data.P[2].V := s;
  Data.P[3].V := rho;


  FLayers[0] := TXRCLayerControl.Create(Self, 0, Data);
  FLayers[0].Parent := Self;
  FLayers[0].Substrate := True;

  RzSeparator.Visible := False;
  lblLayers.Caption   := '';

  FSubstrate := True;
  lblLayers.Top := 1;
  FLayers[0].Top := ClientHeight - 10;
end;

procedure TXRCStack.ClearLayers;
var
  i: Integer;
begin
  for I := 0 to High(FLayers) do
     FreeAndNil(FLayers[i]);

  SetLength(FLayers, 0);
end;

procedure TXRCStack.ClearSelection;
var
  i: integer;
begin
  for I := 0 to High(FLayers) do
    FLayers[i].Selected := False;
end;

procedure TXRCStack.UpdateInfo;
begin
  Caption := FTitle;
  lblLayers.Caption := IntToStr(FN);
end;

procedure TXRCStack.UpdateLayer(const Index: integer; AData: TLayerData);
begin
  FLayers[Index].Onset := True;
  FLayers[Index].Data  := AData;
  FLayers[Index].Onset := False;
end;

procedure TXRCStack.UpdateLayersID;
var
  i: Integer;
begin
  for I := 0 to High(Layers) do
  begin
    Layers[i].UpdateID(FID, i);
    SetLayerColor(i);
  end;
end;

procedure TXRCStack.UpdateLayersStatus(const Pairable: Boolean);
var
  i: integer;
begin
  for I := 0 to High(FLayers) do
    FLayers[i].Pairable := Pairable;
end;

constructor TXRCStack.Create(AOwner: TComponent; const Title: string; const N: integer);
begin
  inherited Create(AOwner);
  FN := N;
  FTitle := Title;

  Parent := AOwner as TWinControl;
//  Top := 10;
//  Align := alNone;
  Height := 80;

  Alignment := taLeftJustify;
  AlignmentVertical := avTop;
  BorderOuter := fsNone;
  BorderHighlight := clTeal;
  BorderWidth := 2;

//  Font.Color := clNavy;
//  Font.Style := [fsBold];

 //lblLayers
  lblLayers := TRzLabel.Create(Self);

  //RzSeparator1
  RzSeparator := TRzSeparator.Create(Self);

  //lblLayers
  lblLayers.Name := 'lblLayers';
  lblLayers.Parent := Self;
  lblLayers.AlignWithMargins := True;
  lblLayers.Margins.Left := 50;
  lblLayers.Align := alTop;
  lblLayers.Alignment := taRightJustify;
  lblLayers.Font.Color := clNavy;
  lblLayers.Font.Style := [fsBold];
  lblLayers.ParentFont := False;

  //RzSeparator1
  RzSeparator.Name := 'RzSeparator1';
  RzSeparator.Parent := Self;
  RzSeparator.AlignWithMargins := True;
  RzSeparator.ShowGradient := True;
  RzSeparator.Align := alBottom;
  RzSeparator.Color := 16765595;

  OnClick := FOnClick;
  OnDblClick := FOnDoubleClick;

  FLinkedLayers[0] := -1;
  FLinkedLayers[1] := -1;

  UpdateInfo;
end;

procedure TXRCStack.DeleteLayer(const Index: integer);
begin
  FreeAndNil(FLayers[Index]);
  Delete(FLayers, Index, 1);

  if Length(FLayers) > 0 then
    Height := Height - FLayers[0].Height
  else
    Height := 80;

  UpdateLayersID;
end;

destructor TXRCStack.Destroy;
begin
//  ClearLayers;
  inherited;
end;

procedure TXRCStack.Edit;
begin

end;

procedure TXRCStack.EnablePairing(const Enabled: Boolean);
begin
  FEnablePairing := Enabled;
  UpdateLayersStatus((FN > 1) and Enabled);
end;

procedure TXRCStack.FOnClick(Sender: TObject);
begin
  if RzSeparator.Visible  then StackClick(FID);
end;

procedure TXRCStack.FOnDoubleClick(Sender: TObject);
begin
  if not FSubstrate then
  begin
    edtrStack.Edit(FTitle, FN);
    UpdateInfo;
    UpdateLayersStatus((FN > 1) and FEnablePairing);
  end
  else begin
    FLayers[0].Edit;
  end;
end;

function TXRCStack.GetLayersData: TLayersData;
var
  i: Integer;
begin
  SetLength(Result, Length(FLayers));
  for i := 0 to High(FLayers) do
    Result[i] := FLayers[i].Data;
end;


function TXRCStack.GetMaterialsList: TMaterialsList;
var
  i: integer;
  Cache: array of string;
begin
  SetLength(Result, Length(FLayers));
  for i := 0 to High(FLayers) do
  begin
    Result[i].Name := Format('%s (%s)',[FLayers[i].Data.Material, FTitle]);
    Result[i].StackID := FID;
    Result[i].LayerID := i + 1;
  end;
end;

procedure TXRCStack.LinkLayer(const LayerID: Integer);
var
  State, Found: Boolean;
      i: integer;
begin
  State := FLayers[LayerID].LinkChecked;
  if State then
  begin
    if (FLinkedLayers[0] <> -1) and (FLinkedLayers[1] <> -1) then
    begin
      FLayers[LayerID].LinkChecked := False;
      Exit; // only 2 links ara allowed
    end;

    Found := False;
    for i:=0 to High(FLinkedLayers) do
    begin
      if LayerID = FLinkedLayers[i] then
      begin
        Found := True;
        Break;
      end;
    end;
    if Found then Exit;
    if FLinkedLayers[0] = -1 then
      FLinkedLayers[0] := LayerID
    else
      FLinkedLayers[1] := LayerID;
  end else
  begin
    for i:=0 to High(FLinkedLayers) do
    begin
      if LayerID = FLinkedLayers[i] then
      begin
        if Assigned(FLayers[FLinkedLayers[i]].Linked) and
           Assigned(FLayers[FLinkedLayers[i]].Linked.Linked) then
                       FLayers[FLinkedLayers[i]].Linked.Linked := nil;  //clear mutual link

        FLayers[FLinkedLayers[i]].Linked := nil;
        FLinkedLayers[i] := -1;
        Break;
      end;
    end;
  end;

  if (FLinkedLayers[0] <> -1) and (FLinkedLayers[1] <> -1) then
  begin
    FLayers[FLinkedLayers[0]].Linked := FLayers[FLinkedLayers[1]]; //set mutual links
    FLayers[FLinkedLayers[1]].Linked := FLayers[FLinkedLayers[0]];
  end;

end;

procedure TXRCStack.RealignLayers;
var
  i, count: Integer;
  MaxHeigh: integer;
begin
  Visible := False;
  Count := Length(FLayers) - 1;

  for I := 0 to Count do
    FLayers[i].Align := alNone;

  MaxHeigh := 20;
  for I := 0 to Count do
  begin
    FLayers[i].Top := MaxHeigh + 5;
    FLayers[i].Align := alTop;
    MaxHeigh := MaxHeigh + FLayers[i].Height + 5;
  end;
  Visible := True;
end;

procedure TXRCStack.Select(const LayerID: integer);
begin
  FLayers[LayerID].Selected := True;
end;

procedure TXRCStack.SetID(const Value: Integer);
var
  i: integer;
begin
  FID := Value;
  for I := 0 to High(FLayers) do
    FLayers[i].UpdateID(I, -1);
end;

procedure TXRCStack.SetIncrement(const Value: Single);
var
  i: Integer;
begin
  for i := 0 to High(FLayers) do
    FLayers[i].Increment := Value;
end;

procedure TXRCStack.SetSelected(const Value: Boolean);
begin
  if Value then
  begin
    BorderColor := clBlue; //clHighlight;
    BorderWidth := 2;
  end
  else begin
    BorderColor := clBtnFace;
    BorderWidth := 0;
  end;
end;

end.
