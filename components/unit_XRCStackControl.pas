unit unit_XRCStackControl;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, RzBckgnd, unit_XRCLayerControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface;

type

  TXRCStack = class (TRzPanel)
    private
      lblLayers: TRzLabel;
      RzSeparator1: TRzSeparator;


      Layers: array of TXRCLayerControl;


      procedure ClearLayers;
    public
      constructor Create(AOwner: TComponent; const Title: string; const N: integer);
      destructor  Destroy; override;

      procedure AddLayer(const Data: TLayerData);
    published
  end;

implementation

{ TXRCStack }

procedure TXRCStack.AddLayer(const Data: TLayerData);
var
  Count: Integer;
begin
  Count := Length(Layers);
  SetLength(Layers, Count + 1);

  Layers[Count] := TXRCLayerControl.Create(Self, 0, Data);
  Layers[Count].Parent := Self;
end;

procedure TXRCStack.ClearLayers;
var
  i: Integer;
begin
  for I := 0 to High(Layers) do
     FreeAndNil(Layers[i]);

  SetLength(Layers, 0);
end;

constructor TXRCStack.Create(AOwner: TComponent; const Title: string; const N: integer);
begin
  inherited Create(AOwner);
  Parent := AOwner as TWinControl;
  Top := 5;
  Align := alTop;
  Height := 80;

  Alignment := taLeftJustify;
  AlignmentVertical := avTop;
  BorderOuter := fsNone;
  BorderHighlight := clTeal;
  BorderWidth := 2;
  Caption := Title;
//  Font.Color := clNavy;
//  Font.Style := [fsBold];

 //lblLayers
  lblLayers := TRzLabel.Create(Self);

  //RzSeparator1
  RzSeparator1 := TRzSeparator.Create(Self);

  //lblLayers
  lblLayers.Name := 'lblLayers';
  lblLayers.Parent := Self;
  lblLayers.AlignWithMargins := True;
  lblLayers.Margins.Left := 50;
  lblLayers.Align := alTop;
  lblLayers.Alignment := taRightJustify;
  lblLayers.Caption := IntToStr(N);
  lblLayers.Font.Color := clNavy;
  lblLayers.Font.Style := [fsBold];
  lblLayers.ParentFont := False;

  //RzSeparator1
  RzSeparator1.Name := 'RzSeparator1';
  RzSeparator1.Parent := Self;
  RzSeparator1.AlignWithMargins := True;
  RzSeparator1.ShowGradient := True;
  RzSeparator1.Align := alBottom;
  RzSeparator1.Color := 16765595;
end;

destructor TXRCStack.Destroy;
begin
  ClearLayers;
  inherited;
end;

end.
