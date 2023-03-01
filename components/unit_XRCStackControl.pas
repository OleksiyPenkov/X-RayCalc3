unit unit_XRCStackControl;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, RzBckgnd, unit_XRCLayerControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface, unit_Types;

type

  TXRCStack = class (TRzPanel)
    private
      lblLayers: TRzLabel;
      RzSeparator: TRzSeparator;


      FLayers: array of TXRCLayerControl;
      FID: Integer;
      FN: Integer;
      FTitle: string;
      FSubstrate: Boolean;

      procedure ClearLayers;
      procedure SetSelected(const Value: Boolean);
      procedure UpdateInfo;
      function GetLayersData: TLayersData;
      procedure SetIncrement(const Value: Single);

    protected
      { Protected declarations }
      procedure FOnClick(Sender: TObject);
      procedure FOnDoubleClick(Sender: TObject);
    public
      constructor Create(AOwner: TComponent; const Title: string; const N: integer);
      destructor  Destroy; override;

      procedure AddLayer(const Data: TLayerData);
      procedure AddSubstrate(const Material: string; rho, s: single);

      property Selected: Boolean write SetSelected;
      property ID: Integer read FID write FID;
      property N:integer read FN;
      procedure Edit;
      property Layers: TLayersData read GetLayersData;
      property Increment:Single write SetIncrement;
      property Title: string read FTitle;
    published
  end;

implementation

uses
  unit_SMessages, editor_Stack;

{ TXRCStack }

procedure TXRCStack.AddLayer(const Data: TLayerData);
var
  Count: Integer;
begin
  Count := Length(FLayers);
  SetLength(FLayers, Count + 1);

  FLayers[Count] := TXRCLayerControl.Create(Self, 0, Data);
  FLayers[Count].Parent := Self;

  if (Count mod 2) = 0 then FLayers[Count].Color := $00FFE3C1
    else FLayers[Count].Color := $00FFD29B;

  ClientHeight := 45 + (Count + 1) * (FLayers[Count].Height + 3);

  lblLayers.Top := 1;
  FLayers[Count].Top := ClientHeight - 10;
end;

procedure TXRCStack.AddSubstrate(const Material: string; rho, s: single);
var
  Data: TLayerData;
begin
  SetLength(FLayers, 1);
  Data.Material := Material;
  Data.H := 1E8;
  Data.r := rho;
  Data.s := s;


  FLayers[0] := TXRCLayerControl.Create(Self, 0, Data);
  FLayers[0].Parent := Self;
  FLayers[0].Substrate := True;

  RzSeparator.Visible := False;
  lblLayers.Caption   := '';

  FSubstrate := True;
end;

procedure TXRCStack.ClearLayers;
var
  i: Integer;
begin
  for I := 0 to High(FLayers) do
     FreeAndNil(FLayers[i]);

  SetLength(FLayers, 0);
end;

procedure TXRCStack.UpdateInfo;
begin
  Caption := FTitle;
  lblLayers.Caption := IntToStr(FN);
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

  UpdateInfo;
end;

destructor TXRCStack.Destroy;
begin
//  ClearLayers;
  inherited;
end;

procedure TXRCStack.Edit;
begin

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
