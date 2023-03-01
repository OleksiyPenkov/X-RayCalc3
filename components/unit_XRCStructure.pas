unit unit_XRCStructure;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, unit_XRCLayerControl, unit_XRCStackControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface,
  unit_materials, unit_Types, System.JSON;

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
      FIncrement: single;
      FVisibility: boolean;

      procedure RealignStacks;
      procedure SetIncrement(const Value: single);
      procedure Clean;
      function GetSelected: Integer;
    public
      constructor Create(AOwner: TComponent);
      destructor  Destroy; override;

      property Selected: Integer read GetSelected;

      procedure AddLayer(const StackID: Integer; const Data: TLayerData);
      procedure AddStack(const N: Integer; const Title: string);
      procedure InsertStack(const N: Integer; const Title: string);
      procedure AddSubstrate(const Material: string; rho, s: single);
      procedure Select(const ID: Integer);
      procedure EditStack(const ID: Integer);
      procedure DeleteStack(const ID: Integer);

      function Model: TLayeredModel;

      function ToString: string;
      procedure FromString(const S: string);
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
  Stacks[StackID].AddLayer(Data);
end;

procedure TXRCStructure.RealignStacks;
var
  i, count: Integer;
  top: Integer;

begin
  Count := Length(Stacks) - 1;
  Substrate.Align := alNone;

  for I := 0 to Count do
    Stacks[i].Align := alNone;

  for I := 0 to Count do
  begin
    Stacks[i].Top := i * 80;
    Stacks[i].Align := alTop;
  end;

  Substrate.Top := ClientHeight - 5;
  Substrate.Align := alTop;

  Visible := FVisibility;
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

procedure TXRCStructure.AddSubstrate(const Material: string; rho,
  s: single);
begin
  Substrate := TXRCStack.Create(Box, 'Substrate', 1);
  Substrate.Top  := 0;
  Substrate.Left := 0;
  Substrate.Width := ClientWidth;

  Substrate.AddSubstrate(Material, rho, s);
end;

procedure TXRCStructure.Clean;
var
  i: Integer;
begin
  for I := 0 to High(Stacks) do
     Stacks[i].Free;
  Finalize(Stacks);

  Substrate.Free;
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
end;

procedure TXRCStructure.DeleteStack(const ID: Integer);
begin
  if ID > -1 then
  begin
    Stacks[ID].Free;
    Delete(Stacks, ID, 1);
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
  i, count, pos: Integer;
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

function TXRCStructure.Model: TLayeredModel;
var
  i, k, j: Integer;
  StackLayers: TLayersData;
begin
  Result := TLayeredModel.Create;
  Result.Init;

  for I := 0 to High(Stacks) do
  begin
    StackLayers := Stacks[i].Layers;
    for j := 0  to Stacks[i].N do
        Result.AddLayers(StackLayers);
  end;

  Result.AddSubstrate(Substrate.Layers);
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

procedure TXRCStructure.SetIncrement(const Value: single);
var
  i: Integer;
begin
  FIncrement := Value;
  for I := 0 to High(Stacks) do
    Stacks[i].Increment := Value;
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
        JLayer.AddPair('H', Data.H);
        JLayer.AddPair('s', Data.s);
        JLayer.AddPair('r', Data.r);

        JLayers.Add(JLayer);
      end;
      JStack.AddPair('Layers', JLayers);
      JStacks.Add(JStack);
    end;

    Data := Substrate.Layers[0];
    JSub := TJSONObject.Create;
    JSub.AddPair('M', Data.Material);
    JSub.AddPair('s', Data.s);
    JSub.AddPair('r', Data.r);

    JStstructure.AddPair('Stacks', JStacks);
    JStstructure.AddPair('Subs', JSub);
    Result := JStstructure.ToString;
  finally
    FreeAndNil(JStstructure);
  end;
end;

procedure TXRCStructure.FromString(const S: string);
var
  i, j: Integer;
  Data: TLayerData;
  JStstructure: TJSONObject;
  JLayer, JStack, JSub : TJSONValue;
  JStacks, JLayers : TJSONArray;
begin
  Visible := False;
  Clean;

  JStstructure := TJSonObject.ParseJSONValue(S) as TJSonObject;

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
        Data.H := JLayer.GetValue<single>('H');
        Data.s := JLayer.GetValue<single>('s');
        Data.r := JLayer.GetValue<single>('r');

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
