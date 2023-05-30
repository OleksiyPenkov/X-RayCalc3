unit unit_XRCStructure;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, unit_XRCLayerControl, unit_XRCStackControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface,
  unit_materials, unit_Types, System.JSON, System.Generics.Collections;

type

  TXRCStructure = class (TRzPanel)
    private
      Header: TRzPanel;
      Label1: TRzLabel;
      Label2: TRzLabel;
      Label3: TRzLabel;
      Label4: TRzLabel;
      Box: TJvDesignScrollBox;

      Stacks: array of TXRCStack;
      Substrate: TXRCStack;

      FSelectedStack : Integer;

      FSelectedLayer : Integer;
      FSelectedLayerParent : Integer;

      FIncrement: single;
      FVisibility: boolean;

      FClipBoardLayers: TLayersData;

      procedure RealignStacks;
      procedure SetIncrement(const Value: single);
      function GetSelected: Integer;
      procedure ClearSelection(const Reset:boolean = False); inline;
    public
      constructor Create(AOwner: TComponent);
      destructor  Destroy; override;

      property Selected: Integer read GetSelected;

      procedure AddLayer(const StackID: Integer; const Data: TLayerData);
      procedure AddStack(const N: Integer; const Title: string);
      procedure InsertStack(const N: Integer; const Title: string);
      procedure AddSubstrate(const Material: string; s, rho: single);
      procedure Select(const ID: Integer);
      procedure SelectLayer(const StackID, LayerID: Integer);
      procedure EditStack(const ID: Integer);
      procedure DeleteStack;
      procedure DeleteLayer;

      function Model: TLayeredModel;
      function Materials: TMaterialsList;

      function ToString: string;
      procedure FromString(const S: string);
      function ToFitStructure: TFitStructure;
      procedure FromFitStructure(const Inp: TLayeredModel);
      procedure RecreateFromFitStructure(const Inp: TFitStructure);
      procedure StoreFitLimits(const Inp: TFitStructure);
      procedure StoreFitLimitsNP(const Inp: TFitStructure);
      procedure Clear;
      procedure CopyLayer(const Reset: boolean);
      procedure PasteLayer;
      function IsPeriodic(const Index: integer): boolean;
    published
      property Increment: single read FIncrement write SetIncrement;
  end;

var
  Structure: TXRCStructure;

implementation

{ TXRCStructure }

procedure TXRCStructure.AddLayer(const StackID: Integer;
  const Data: TLayerData);
begin
  if StackID <> -1 then
    Stacks[StackID].AddLayer(Data)
  else
    Stacks[High(Stacks)].AddLayer(Data)
end;

procedure TXRCStructure.RealignStacks;
var
  i, count: Integer;
  MaxHeigh: integer;

begin
  Count := Length(Stacks) - 1;
  Substrate.Align := alBottom;

  for I := 0 to Count do
    Stacks[i].Align := alNone;

  MaxHeigh := 20;
  for I := 0 to Count do
  begin
    Stacks[i].Top := MaxHeigh + 5;
    Stacks[i].Align := alTop;
    MaxHeigh := MaxHeigh + Stacks[i].Height + 5;
  end;

  Substrate.Top := ClientHeight - 5;
  Substrate.Align := alTop;

  Self.ClientHeight := MaxHeigh + Substrate.Height + 100;
  Visible := FVisibility;
end;

procedure TXRCStructure.RecreateFromFitStructure(const Inp: TFitStructure);
var
  i, j: integer;
begin
  //
  Visible := False;
  Clear;
  AddSubstrate(Inp.Subs.Material, Inp.Subs.s.V, Inp.Subs.r.V);

  AddStack(1, 'Main');
  for I := 0 to High(Inp.Stacks[0].Layers) do
  begin
    AddLayer(0, Inp.Stacks[0].Layers[i]);
  end;
  Visible := True;
end;

procedure TXRCStructure.AddStack(const N: Integer; const Title: string);
var
  Count: Integer;
begin
  FVisibility := Visible;
  Visible := False;
  Count := Length(Stacks);

  SetLength(Stacks, Count + 1);
  Stacks[Count] := TXRCStack.Create(Box, Title, N);
  Stacks[Count].ID := Count;

  RealignStacks;
end;

procedure TXRCStructure.AddSubstrate(const Material: string; s,
  rho: single);
begin
  Substrate := TXRCStack.Create(Box, 'Substrate', 1);
  Substrate.Width := ClientWidth;

  Substrate.AddSubstrate(Material, s, rho);
end;

procedure TXRCStructure.Clear;
var
  i: Integer;
begin
  for I := 0 to High(Stacks) do
     Stacks[i].Free;
  Finalize(Stacks);

  Substrate.Free;
end;

procedure TXRCStructure.ClearSelection;
var
  i: integer;
begin
  for I := 0 to High(Stacks) do
    Stacks[i].ClearSelection;

  if Reset then
  begin
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
  end;
end;

procedure TXRCStructure.CopyLayer;
begin
  FClipBoardLayers[0] := Stacks[FSelectedLayerParent].Layers[FSelectedLayer];
  ClearSelection(Reset);
end;

constructor TXRCStructure.Create(AOwner: TComponent);
begin
  inherited Create(AOwner);
  Align := alClient;
  BorderInner := fsNone;
  BorderOuter := fsNone;

  //RzPanel1
  Header := TRzPanel.Create(Self);

  //Label1
  Label1 := TRzLabel.Create(Self);

  //Label2
  Label2 := TRzLabel.Create(Self);

  //Label3
  Label3 := TRzLabel.Create(Self);

  //Label4
  Label4 := TRzLabel.Create(Self);

  //Box
  Box := TJvDesignScrollBox.Create(Self);

  //Header
  Header.Name := 'rzpnlHeader';
  Header.Parent := Self;
  Header.Height := 30;
  Header.AlignWithMargins := True;
  Header.Align := alTop;
  Header.BorderOuter := fsFlatRounded;
  Header.Color := clSkyBlue;
  Header.TabOrder := 0;

  //Label1
  Label1.Name := 'Label1';
  Label1.Parent := Header;
  Label1.Left := 5;
  Label1.Top := 6;
  Label1.Width := 37;
  Label1.Height := 16;
  Label1.Caption := 'Stack / Layer';
  Label1.Font.Color := clWindowText;
  Label1.Font.Height := -13;
  Label1.Font.Name := 'Tahoma';
  Label1.Font.Style := [fsBold];
  Label1.ParentFont := False;

  //Label2
  Label2.Name := 'Label2';
  Label2.Parent := Header;
  Label2.Left := 120;
  Label2.Top := 6;
  Label2.Width := 35;
  Label2.Height := 16;
  Label2.Caption := 'H (Å)';
  Label2.Font.Color := clWindowText;
  Label2.Font.Height := -13;
  Label2.Font.Name := 'Tahoma';
  Label2.Font.Style := [fsBold];
  Label2.ParentFont := False;

  //Label3
  Label3.Name := 'Label3';
  Label3.Parent := Header;
  Label3.Left := 191;
  Label3.Top := 6;
  Label3.Width := 35;
  Label3.Height := 16;
  Label3.Caption := 'σ (Å)';
  Label3.Font.Color := clWindowText;
  Label3.Font.Height := -13;
  Label3.Font.Name := 'Tahoma';
  Label3.Font.Style := [fsBold];
  Label3.ParentFont := False;

  //Label4
  Label4.Name := 'Label4';
  Label4.Parent := Header;
  Label4.Left := 250;
  Label4.Top := 6;
  Label4.Width := 65;
  Label4.Height := 16;
  Label4.Caption := 'ρ (g/cm³)  N';
  Label4.Font.Color := clWindowText;
  Label4.Font.Height := -13;
  Label4.Font.Name := 'Tahoma';
  Label4.Font.Style := [fsBold];
  Label4.ParentFont := False;

  //Box
  Box.Name := 'Box';
  Box.Parent := Self;
  Box.AlignWithMargins := True;
  Box.HorzScrollBar.Visible := False;
  Box.VertScrollBar.Style := ssFlat;
  Box.VertScrollBar.Tracking := True;
  Box.Align := alClient;
  Box.BevelInner := bvNone;
  Box.BevelOuter := bvNone;
  Box.BorderStyle := bsNone;
  Box.TabOrder := 1;

  FSelectedStack := -1;
  FSelectedLayerParent := -1;
  FSelectedLayer := -1;
  SetLength(FClipBoardLayers, 1);
end;

procedure TXRCStructure.DeleteLayer;
begin
  if (FSelectedLayer >= 0) and (FSelectedLayerParent >= 0) then
  begin
    Stacks[FSelectedLayerParent].DeleteLayer(FSelectedLayer);
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
  end;
end;

procedure TXRCStructure.DeleteStack;
var
  i: integer;
begin
  if FSelectedStack > -1 then
  begin
    Stacks[FSelectedStack].Free;
    Delete(Stacks, FSelectedStack, 1);
    FSelectedStack := -1;

    for I := 0 to High(Stacks) do
      Stacks[i].ID := i;
  end;
end;

destructor TXRCStructure.Destroy;
begin
//  FreeAndNil(Substrate);
  inherited Destroy;
end;

procedure TXRCStructure.EditStack;
begin
  Stacks[ID].Edit;
end;

procedure TXRCStructure.InsertStack(const N: Integer; const Title: string);
var
  Count, pos: Integer;
begin
  Visible := False;
  Count := Length(Stacks);

  if FSelectedStack <> -1 then Pos := FSelectedStack
    else Pos := count;

  Insert(Nil, Stacks, pos);

  Stacks[Pos] := TXRCStack.Create(Box, Title, N);
  Stacks[Pos].ID := Pos;

  RealignStacks;
end;

function TXRCStructure.IsPeriodic(const Index: integer): boolean;
begin
  if Index > High(Stacks) then
    Result := False
  else
     Result := Stacks[Index].N > 1;
end;

function TXRCStructure.Materials: TMaterialsList;
var
  i: integer;
begin
  SetLength(Result, 0);
  for I := 0 to High(Stacks) do
  begin
    if Stacks[i].N > 1 then
       Result := Result + Stacks[i].Materials;
  end;
end;

function TXRCStructure.Model: TLayeredModel;
var
  i, j: Integer;
  StackLayers: TLayersData;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  for I := 0 to High(Stacks) do
  begin
    StackLayers := Stacks[i].Layers;
    for j := 1  to Stacks[i].N do
      Result.AddLayers(i, StackLayers);
  end;

  Result.AddSubstrate(Substrate.Layers);
end;

procedure TXRCStructure.PasteLayer;
begin
  if FSelectedStack <> -1 then
       Stacks[FSelectedStack].AddLayer(FClipBoardLayers[0])
  else
    if FSelectedLayerParent <> -1 then
        Stacks[FSelectedLayerParent].AddLayer(FClipBoardLayers[0])
end;

procedure TXRCStructure.Select(const ID: Integer);
var
  i: Integer;
begin
  if ID = FSelectedStack then
  begin
    FSelectedStack := -1;
    Stacks[ID].Selected := False;
  end
  else begin
    for I := 0 to High(Stacks) do
      Stacks[i].Selected := (ID = i);

    FSelectedStack := ID;
  end;
end;

procedure TXRCStructure.SelectLayer(const StackID, LayerID: Integer);
begin
  ClearSelection;

  if (StackID <> FSelectedLayerParent) and (LayerID <> FSelectedLayer) then
  begin
    Stacks[StackID].Select(LayerID);
    FSelectedLayerParent := StackID;
    FSelectedLayer := LayerID;
  end
  else begin
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
  end;
end;

procedure TXRCStructure.SetIncrement(const Value: single);
var
  i: Integer;
begin
  FIncrement := Value;
  for I := 0 to High(Stacks) do
    Stacks[i].Increment := Value;
end;

procedure TXRCStructure.StoreFitLimits(const Inp: TFitStructure);
var
  i, j: integer;
  Count: integer;
  Data: TLayerData;
begin
  Count := 1;

  for I := 0 to High(Stacks) do
  begin
    for j := 0 to High(Stacks[i].Layers) do
    begin
      Data.Material := Inp.Stacks[i].Layers[j].Material;
      Data.H := Inp.Stacks[i].Layers[j].H;
      Data.s := Inp.Stacks[i].Layers[j].s;
      Data.r := Inp.Stacks[i].Layers[j].r;
      Stacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (Stacks[i].N - 1) * (High(Stacks[i].Layers) + 1));
  end;
end;

procedure TXRCStructure.StoreFitLimitsNP(const Inp: TFitStructure);
var
  i, j: integer;
  Count: integer;
  Data: TLayerData;
begin
  Count := 0;

  for I := 0 to High(Stacks) do
  begin
    for j := 0 to High(Stacks[i].Layers) do
    begin
      Data.Material := Inp.Stacks[0].Layers[Count].Material;
      Data.H := Inp.Stacks[0].Layers[Count].H;
      Data.s := Inp.Stacks[0].Layers[Count].s;
      Data.r := Inp.Stacks[0].Layers[Count].r;
      Stacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (Stacks[i].N - 1) * (High(Stacks[i].Layers) + 1));
  end;
end;

function TXRCStructure.ToFitStructure: TFitStructure;
var
  i, j: integer;
  D: single;
begin

  SetLength(Result.Stacks, Length(Stacks));

  for I := 0 to High(Stacks) do
  begin
    Result.Stacks[i].ID := Stacks[i].ID;
    Result.Stacks[i].N := Stacks[i].N;
    Result.Stacks[i].Header := Stacks[i].Title;

    SetLength(Result.Stacks[i].Layers, Length(Stacks[i].Layers));

    if Stacks[i].N > 1 then
    begin
      D := 0;
      for j := 0 to High(Stacks[i].Layers) do
      begin
        Result.Stacks[i].Layers[j].LayerID := j;
        D := D + Stacks[i].Layers[j].H.V;
      end;
      Result.Stacks[i].D := D;
    end;

    for j := 0 to High(Stacks[i].Layers) do
    begin
      Result.Stacks[i].Layers[j].Material := Stacks[i].Layers[j].Material;
      Result.Stacks[i].Layers[j].H := Stacks[i].Layers[j].H;
      Result.Stacks[i].Layers[j].s := Stacks[i].Layers[j].s;
      Result.Stacks[i].Layers[j].r := Stacks[i].Layers[j].r;
      Result.Stacks[i].Layers[j].StackID := i;
      Result.Stacks[i].Layers[j].LayerID := j;
    end;
    Result.Stacks[i].D := D;
  end;

  Result.Subs.Material := Substrate.Layers[0].Material;
  Result.Subs.H := Substrate.Layers[0].H;
  Result.Subs.s := Substrate.Layers[0].s;
  Result.Subs.r := Substrate.Layers[0].r;
end;

function TXRCStructure.ToString: string;
var
  i, j: Integer;
  Data: TLayerData;
  JStstructure, JLayer, JStack, JSub : TJSONObject;
  JStacks, JLayers : TJSONArray;
begin
  JStstructure := TJSONObject.Create;
  try
    JStacks :=  TJSONArray.Create;
    for I := 0 to High(Stacks) do
    begin
      JStack :=  TJSONObject.Create;
      JStack.AddPair('T', Stacks[i].Title);
      JStack.AddPair('N', Stacks[i].N);

      JLayers := TJSONArray.Create;
      for j := 0 to High(Stacks[i].Layers) do
      begin
        Data := Stacks[i].Layers[j];

        JLayer := TJSONObject.Create;
        JLayer.AddPair('M', Data.Material);
        JLayer.AddPair('H', Data.H.V);
        JLayer.AddPair('Hmin', Data.H.min);
        JLayer.AddPair('Hmax', Data.H.max);

        JLayer.AddPair('s', Data.s.V);
        JLayer.AddPair('Smin', Data.s.min);
        JLayer.AddPair('Smax', Data.s.max);

        JLayer.AddPair('r', Data.r.V);
        JLayer.AddPair('Rmin', Data.r.min);
        JLayer.AddPair('Rmax', Data.r.max);

        JLayers.Add(JLayer);
      end;
      JStack.AddPair('Layers', JLayers);
      JStacks.Add(JStack);
    end;

    Data := Substrate.Layers[0];
    JSub := TJSONObject.Create;
    JSub.AddPair('M', Data.Material);
    JSub.AddPair('s', Data.s.V);
    JSub.AddPair('r', Data.r.V);

    JStstructure.AddPair('Stacks', JStacks);
    JStstructure.AddPair('Subs', JSub);
    Result := JStstructure.ToString;
  finally
    FreeAndNil(JStstructure);
  end;
end;

procedure TXRCStructure.FromFitStructure(const Inp: TLayeredModel);
var
  i, j: integer;
  Count: integer;
  Data: TLayerData;
begin
  Count := 1;

  for I := 0 to High(Stacks) do
  begin
    for j := 0 to High(Stacks[i].Layers) do
    begin
      Data.Material := Inp.Layers[Count].Name;
      Data.H.V := Inp.Layers[Count].L;
      Data.s.V := Inp.Layers[Count].s * 1.41;
      Data.r.V := Inp.Layers[Count].ro;
      Stacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (Stacks[i].N - 1) * (High(Stacks[i].Layers) + 1));
  end;
end;

procedure TXRCStructure.FromString(const S: string);
var
  i, j, p: Integer;
  Data: TLayerData;
  JStstructure: TJSONObject;
  JLayer, JStack, JSub: TJSONValue;
  JStacks, JLayers : TJSONArray;
  ts: string;

  function FindValue(const Value: string; Base: single): single;
  var
    JVal : TJSONValue;
  begin
    JVal := JLayer.FindValue(Value);
    if JVal <> nil then
       Result := StrToFloat(JVal.Value)
    else
      Result := Base;
  end;

begin
  Visible := False;
  Clear;

  p := pos('}}', s);
  ts := copy(S, 1, p + 1);

  JStstructure := TJSonObject.ParseJSONValue(ts) as TJSonObject;

  try
    JSub := JStstructure.Get('Subs').JsonValue;
    AddSubstrate(JSub.GetValue<string>('M'), JSub.GetValue<single>('s'), JSub.GetValue<single>('r'));

    JStacks := JStstructure.Get('Stacks').JsonValue as TJSONArray;
    for I := 0 to JStacks.Count - 1 do
    begin
      JStack := JStacks.Items[i];
      AddStack(JStack.GetValue<integer>('N'), JStack.GetValue<string>('T'));
      JLayers := JStack.GetValue<TJsonArray>('Layers');

      for j := 0 to JLayers.Count - 1 do
      begin
        JLayer := JLayers.Items[j];
        Data.Material := JLayer.GetValue<string>('M');

        Data.H.V := JLayer.GetValue<single>('H');
        Data.H.min := FindValue('Hmin', Data.H.V);
        Data.H.max := FindValue('Hmax', Data.H.V);

        Data.s.V := JLayer.GetValue<single>('s');
        Data.s.min := FindValue('Smin', Data.s.V);
        Data.s.max := FindValue('Smax', Data.s.V);

        Data.r.V := JLayer.GetValue<single>('r');
        Data.r.min := FindValue('Rmin', Data.r.V);
        Data.r.max := FindValue('Rmax', Data.r.V);

        Stacks[i].AddLayer(Data);
      end;
    end;

  finally
    FreeAndNil(JStstructure);
  end;

  Visible := True;
end;

function TXRCStructure.GetSelected: Integer;
begin
  Result := FSelectedStack;
end;

end.
