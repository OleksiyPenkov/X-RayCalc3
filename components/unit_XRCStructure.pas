unit unit_XRCStructure;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, unit_XRCLayerControl, unit_XRCStackControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface,
  unit_materials, unit_Types, System.JSON, System.Generics.Collections;

type

  TStacks = array of TXRCStack;

  TXRCStructure = class (TRzPanel)
    private
      Header: TRzPanel;
      Label1: TRzLabel;
      Label2: TRzLabel;
      Label3: TRzLabel;
      Label4: TRzLabel;
      Box: TJvDesignScrollBox;

      FStacks: TStacks;
      Substrate: TXRCStack;
      FPeriod: Single;

      FSelectedStack : Integer;

      FSelectedLayer : Integer;
      FSelectedLayerParent : Integer;

      FIncrement: single;
      FVisibility: boolean;

      FClipBoardLayers: TLayersData;
      JLayer, JStack, JSub: TJSONValue;

      procedure RealignStacks;
      procedure SetIncrement(const Value: single);
      function GetSelectedStack: Integer;
      function FindBoolValue(const Value: string): boolean;
      function FindValue(const Value: string; Base: single): single;
      function FindStrValue(const Value: string): string;
      function GetSelectedLayer: Integer;
    public
      constructor Create(AOwner: TComponent); override;
      destructor  Destroy; override;

      property SelectedStack: Integer read GetSelectedStack;
      property SelectedLayer: Integer read GetSelectedLayer;
      property Stacks: TStacks read FStacks;
      property Period: single read FPeriod;

      procedure AddLayer(const StackID: Integer; const Data: TLayerData);
      procedure InsertLayer(const Data: TLayerData);
      procedure AddStack(const N: Integer; const Title: string);
      procedure InsertStack(const N: Integer; const Title: string);
      procedure AddSubstrate(const Material: string; s, rho: single);
      procedure Select(const ID: Integer);
      procedure ClearSelection(const Reset:boolean = False); inline;
      procedure SelectLayer(const StackID, LayerID: Integer);
      procedure LinkLayer(const StackID, LayerID: Integer);
      procedure MoveLayer(const StackID, LayerID, Direction: Integer);
      procedure EditStack(const ID: Integer);
      procedure DeleteStack;
      procedure DeleteLayer; overload;
      procedure DeleteLayer(const StackID, LayerID: Integer); overload;

      function Model(const ExpandProfiles: Boolean): TLayeredModel;
      function Materials: TMaterialsList;

      function ToString: string; reintroduce; overload;
      procedure FromString(const S: string);
      function ToFitStructure: TFitStructure;
      procedure FromFitStructure(const Inp: TLayeredModel);
      procedure RecreateFromFitStructure(const Inp: TFitStructure);
      procedure UpdateInterfaceP(const Inp: TFitStructure);
      procedure UpdateInterfaceNP(const Inp: TFitStructure);
      procedure UpdateProfiles(const Inp: TLayeredModel);
      procedure UpdateProfilesP;
      procedure Clear;
      procedure CopyLayer(const Reset: boolean);
      procedure PasteLayer;
      function IsPeriodic: boolean; overload;
      function IsPeriodic(const Index: integer): boolean; overload;
      procedure GetStacksList(PeriodicOnly: Boolean; List: TStrings; var RealID: TIntArray);
      procedure GetLayersList(const ID: integer; List: TStrings);
      function GetStackSize(const ID: Integer): Integer;
      procedure EnablePairing;
      function IfValidLayerSelected: Boolean; inline;
    published
      property Increment: single read FIncrement write SetIncrement;
  end;

var
  Structure: TXRCStructure;

implementation

uses
  unit_consts;

{ TXRCStructure }

procedure TXRCStructure.AddLayer(const StackID: Integer;
  const Data: TLayerData);
begin
  if StackID <> -1 then
    FStacks[StackID].AddLayer(Data)
  else
    FStacks[High(FStacks)].AddLayer(Data)
end;

procedure TXRCStructure.RealignStacks;
var
  i, count: Integer;
  MaxHeigh: integer;

begin
  Count := Length(FStacks) - 1;
  Substrate.Align := alBottom;

  for I := 0 to Count do
    FStacks[i].Align := alNone;

  MaxHeigh := 20;
  for I := 0 to Count do
  begin
    FStacks[i].Top := MaxHeigh + 5;
    FStacks[i].Align := alTop;
    MaxHeigh := MaxHeigh + FStacks[i].Height + 5;
  end;

  Substrate.Top := ClientHeight - 5;
  Substrate.Align := alTop;

  Self.ClientHeight := MaxHeigh + Substrate.Height + 100;
  Visible := FVisibility;
end;

procedure TXRCStructure.RecreateFromFitStructure(const Inp: TFitStructure);
var
  i: integer;
begin
  //
  Visible := False;
  Clear;
  AddSubstrate(Inp.Subs.Material, Inp.Subs.P[2].V, Inp.Subs.P[3].V);

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
  Count := Length(FStacks);

  SetLength(FStacks, Count + 1);
  FStacks[Count] := TXRCStack.Create(Box, Title, N);
  FStacks[Count].ID := Count;

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
  for I := 0 to High(FStacks) do
     FStacks[i].Free;
  Finalize(FStacks);

  Substrate.Free;
end;


procedure TXRCStructure.ClearSelection;
var
  i: integer;
begin
  for I := 0 to High(FStacks) do
    FStacks[i].ClearSelection;

  if Reset then
  begin
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
  end;
end;

function TXRCStructure.IfValidLayerSelected: Boolean;
begin
  Result := (FSelectedLayerParent >= 0) or (FSelectedLayer >= 0);
end;

procedure TXRCStructure.CopyLayer;
begin
  if not IfValidLayerSelected then Exit;

  FClipBoardLayers[0] := FStacks[FSelectedLayerParent].LayerData[FSelectedLayer];
  ClearSelection(Reset);
end;

constructor TXRCStructure.Create(AOwner: TComponent);

  procedure CreateLabel(const Caption: string; Left: Integer; var MyLabel: TRzLabel);
  begin
    MyLabel := TRzLabel.Create(Self);

    MyLabel.Parent := Header;
    MyLabel.Left := Left;
    MyLabel.Top := 6;
    MyLabel.Width := 37;
    MyLabel.Height := 16;
    MyLabel.Caption := Caption;
    MyLabel.Font.Color := clWindowText;
    MyLabel.Font.Height := -13;
    MyLabel.Font.Name := 'Tahoma';
    MyLabel.Font.Style := [fsBold];
    MyLabel.ParentFont := False;
  end;

begin
  inherited Create(AOwner);
  Align := alClient;
  BorderInner := fsNone;
  BorderOuter := fsNone;

  //RzPanel1
  Header := TRzPanel.Create(Self);

  //Labels
  CreateLabel('Stack / Layer', 6, Label1);
  CreateLabel('H (Å)', 110, Label2);
  CreateLabel('σ (Å)', 181, Label3);
  CreateLabel('ρ (g/cm³)   N', 250, Label4);

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
  if IfValidLayerSelected then
  begin
    FStacks[FSelectedLayerParent].DeleteLayer(FSelectedLayer);
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
  end;
end;

procedure TXRCStructure.DeleteLayer(const StackID, LayerID: Integer);
begin
    FStacks[StackID].DeleteLayer(LayerID);
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
end;

procedure TXRCStructure.DeleteStack;
var
  i: integer;
begin
  if FSelectedStack > -1 then
  begin
    FStacks[FSelectedStack].Free;
    Delete(FStacks, FSelectedStack, 1);
    FSelectedStack := -1;

    for I := 0 to High(FStacks) do
    begin
      FStacks[i].ID := i;
      FStacks[i].UpdateLayersID;
    end;
  end;
end;

destructor TXRCStructure.Destroy;
begin
//  FreeAndNil(Substrate);
  inherited Destroy;
end;

procedure TXRCStructure.EditStack;
begin
  FStacks[ID].Edit;
end;

procedure TXRCStructure.EnablePairing;
var
  Stack: TXRCStack;
begin
  for Stack in FStacks do
    Stack.EnablePairing(True);
end;


procedure TXRCStructure.InsertLayer(const Data: TLayerData);
var
  StackID: Integer;
begin
  StackID := FSelectedLayerParent;
  FStacks[StackID].AddLayer(Data, FSelectedLayer);
end;

procedure TXRCStructure.InsertStack(const N: Integer; const Title: string);
var
  Count, pos: Integer;
begin
  Visible := False;
  Count := Length(FStacks);

  if FSelectedStack <> -1 then Pos := FSelectedStack
    else Pos := count;

  Insert(Nil, FStacks, pos);

  FStacks[Pos] := TXRCStack.Create(Box, Title, N);
  FStacks[Pos].ID := Pos;

  RealignStacks;
end;

function TXRCStructure.IsPeriodic: boolean;
var
  i: Integer;
begin
  Result := False;
  for I := 0 to High(FStacks) do
    if IsPeriodic(i) then
    begin
      Result := True;
      Break;
    end;
end;

function TXRCStructure.IsPeriodic(const Index: integer): boolean;
begin
  if Index > High(FStacks) then
    Result := False
  else
     Result := FStacks[Index].N > 1;
end;

procedure TXRCStructure.LinkLayer(const StackID, LayerID: Integer);
begin
  FStacks[StackID].LinkLayer(LayerID);
end;

function TXRCStructure.Materials: TMaterialsList;
var
  i: integer;
begin
  SetLength(Result, 0);
  for I := 0 to High(FStacks) do
  begin
    if FStacks[i].N > 1 then
       Result := Result + FStacks[i].Materials;
  end;
end;

function TXRCStructure.Model(const ExpandProfiles: Boolean): TLayeredModel;
var
  i, j, k, p: Integer;
  StackLayers: TLayersData;
begin
  FPeriod := 0;
  Result := TLayeredModel.Create;
  Result.Init;

  for I := 0 to High(FStacks) do
  begin
    StackLayers := FStacks[i].LayerData;
    for j := 1  to FStacks[i].N do
    begin
      if ExpandProfiles and (FStacks[i].N > 1) then
      begin
        for k := 0 to High(StackLayers) do
          for p := 1 to 3 do
            StackLayers[k].P[p].V := StackLayers[k].PP[p][j - 1];
      end;
      Result.AddLayers(i, StackLayers);
    end;
    if FStacks[i].N > 1 then
    begin
      FPeriod := 0;
      for k := 0 to High(StackLayers) do
        FPeriod := FPeriod + StackLayers[k].P[1].V;
    end;
  end;

  Result.AddSubstrate(Substrate.LayerData);
end;

procedure TXRCStructure.MoveLayer(const StackID, LayerID, Direction: Integer);
begin
  FStacks[StackID].MoveLayer(LayerID, Direction);
end;

procedure TXRCStructure.PasteLayer;
begin
  if FSelectedStack <> -1 then
       FStacks[FSelectedStack].AddLayer(FClipBoardLayers[0])
  else
    if FSelectedLayerParent <> -1 then
        FStacks[FSelectedLayerParent].AddLayer(FClipBoardLayers[0])
end;

procedure TXRCStructure.Select(const ID: Integer);
var
  i: Integer;
begin
  if ID = FSelectedStack then
  begin
    FSelectedStack := -1;
    FStacks[ID].Selected := False;
  end
  else begin
    for I := 0 to High(FStacks) do
      FStacks[i].Selected := (ID = i);

    FSelectedStack := ID;
  end;
end;

procedure TXRCStructure.SelectLayer(const StackID, LayerID: Integer);
begin
  ClearSelection;

  if (StackID <> FSelectedLayerParent) and (LayerID <> FSelectedLayer) then
  begin
    FStacks[StackID].Select(LayerID);
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
  for I := 0 to High(FStacks) do
    FStacks[i].Increment := Value;
end;

procedure TXRCStructure.UpdateInterfaceNP(const Inp: TFitStructure);
var
  i, j: integer;
  Count: integer;
  Data: TLayerData;
begin
  Count := 0;
  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].Layers) do
    begin
      Data.Material := Inp.Stacks[0].Layers[Count].Material;
      Data.P := Inp.Stacks[0].Layers[Count].P;
      FStacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (FStacks[i].N - 1) * (High(FStacks[i].Layers) + 1));
  end;
end;

procedure TXRCStructure.UpdateInterfaceP(const Inp: TFitStructure);
var
  i, j: integer;
  Data: TLayerData;
begin
  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].LayerData) do
    begin
      Data.Material := Inp.Stacks[i].Layers[j].Material;
      Data.P := Inp.Stacks[i].Layers[j].P;
      FStacks[i].UpdateLayer(j, Data);
    end;
  end;
end;

procedure TXRCStructure.UpdateProfiles(const Inp: TLayeredModel);
var
  i, j, SID, LID: integer;
begin
  for I := 0 to High(FStacks) do
     for j := 0 to High(FStacks[i].Layers) do
       FStacks[i].Layers[j].Data.ClearProfiles;

  for I := 1 to High(Inp.Layers) - 1 do
  begin
    SID := Inp.Layers[i].StackID;
    LID := Inp.Layers[i].LayerID;
    Structure.FStacks[SID].Layers[LID].Data.AddProfilePoint(Inp.Layers[i].L, Inp.Layers[i].s, Inp.Layers[i].ro);
  end;
end;

procedure TXRCStructure.UpdateProfilesP;
begin

end;

function TXRCStructure.ToFitStructure: TFitStructure;
var
  i, j: integer;
  D: single;
begin

  SetLength(Result.Stacks, Length(FStacks));

  for I := 0 to High(FStacks) do
  begin
    Result.Stacks[i].ID := FStacks[i].ID;
    Result.Stacks[i].N := FStacks[i].N;
    Result.Stacks[i].Header := FStacks[i].Title;

    SetLength(Result.Stacks[i].Layers, Length(FStacks[i].LayerData));

    D := 0;
    if FStacks[i].N > 1 then
    begin
      for j := 0 to High(FStacks[i].LayerData) do
      begin
        Result.Stacks[i].Layers[j].LayerID := j;
        D := D + FStacks[i].LayerData[j].P[1].V;
      end;
      Result.Stacks[i].D := D;
    end;

    for j := 0 to High(FStacks[i].LayerData) do
    begin
      Result.Stacks[i].Layers[j].Material := FStacks[i].LayerData[j].Material;
      Result.Stacks[i].Layers[j].P := FStacks[i].LayerData[j].P;
      Result.Stacks[i].Layers[j].StackID := i;
      Result.Stacks[i].Layers[j].LayerID := j;
    end;
    Result.Stacks[i].D := D;
  end;

  Result.Subs.Material := Substrate.LayerData[0].Material;
  Result.Subs.P := Substrate.LayerData[0].P;
end;

function TXRCStructure.ToString: string;
var
  i, j, p: Integer;
  Data: TLayerData;
  JStstructure, JLayer, JStack, JSub : TJSONObject;
  JStacks, JLayers : TJSONArray;
  Profile: string;
begin
  JStstructure := TJSONObject.Create;
  try
    JStacks :=  TJSONArray.Create;
    for I := 0 to High(FStacks) do
    begin
      JStack :=  TJSONObject.Create;
      JStack.AddPair('T', FStacks[i].Title);
      JStack.AddPair('N', FStacks[i].N);

      JLayers := TJSONArray.Create;
      for j := 0 to High(FStacks[i].LayerData) do
      begin
        Data := FStacks[i].LayerData[j];

        JLayer := TJSONObject.Create;
        JLayer.AddPair('M', Data.Material);

        for p := 1 to 3 do
        begin
          JLayer.AddPair(PAlias[p], Data.P[p].V);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'P', Data.P[p].Paired);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'min', Data.P[p].min);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'max', Data.P[p].max);
          Profile := Data.ProfileToSrting(ptH);
          JLayer.AddPair('Profile' + UpperCase(PAlias[p]), Profile);
        end;

        JLayers.Add(JLayer);
      end;
      JStack.AddPair('Layers', JLayers);
      JStacks.Add(JStack);
    end;

    Data := Substrate.LayerData[0];
    JSub := TJSONObject.Create;
    JSub.AddPair('M', Data.Material);
    JSub.AddPair('s', Data.P[2].V);
    JSub.AddPair('r', Data.P[3].V);

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

  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].LayerData) do
    begin
      Data.Material := Inp.Layers[Count].Name;
      Data.P[1].V := Inp.Layers[Count].L;
      Data.P[2].V := Inp.Layers[Count].s;
      Data.P[3].V := Inp.Layers[Count].ro;
      FStacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (FStacks[i].N - 1) * (High(FStacks[i].LayerData) + 1));
  end;
end;


function TXRCStructure.FindValue(const Value: string; Base: single): single;
var
  JVal : TJSONValue;
begin
  JVal := JLayer.FindValue(Value);
  if JVal <> nil then
     Result := JVal.AsType<single>
  else
    Result := Base;
end;


function TXRCStructure.FindBoolValue(const Value: string): boolean;
var
  JVal : TJSONValue;
begin
  JVal := JLayer.FindValue(Value);
  if JVal <> nil then
     Result := JVal.AsType<Boolean>
  else
    Result := False;
end;

function TXRCStructure.FindStrValue(const Value: string): string;
var
  JVal : TJSONValue;
begin
  JVal := JLayer.FindValue(Value);
  if JVal <> nil then
     Result := JVal.AsType<String>
  else
    Result := '';
end;

procedure TXRCStructure.FromString(const S: string);
var
  i, j, p: Integer;
  Data: TLayerData;
  JStstructure: TJSONObject;
  JStacks, JLayers : TJSONArray;
  PS: string;

begin
  Visible := False;
  Clear;

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

        for p := 1 to 3 do
        begin
          Data.P[p].V := JLayer.GetValue<single>(PAlias[p]);
          Data.P[p].Paired := FindBoolValue(UpperCase(PAlias[p]) + 'P');
          Data.P[p].min := FindValue(UpperCase(PAlias[p]) + 'min', Data.P[p].V);
          Data.P[p].max := FindValue(UpperCase(PAlias[p]) + 'max', Data.P[p].V);

          PS := FindStrValue('Profile' + UpperCase(PAlias[p]));
          if PS <> '' then
          begin
            Data.ClearProfiles;
            Data.ProfileFromSrting(p, PS);
          end;

        end;
        FStacks[i].AddLayer(Data);
      end;
    end;

  finally
    FreeAndNil(JStstructure);
  end;

  Visible := True;
end;

procedure TXRCStructure.GetLayersList(const ID: integer; List: TStrings);
var
  j: Integer;
begin
  List.Clear;
  for j := 0 to High(FStacks[ID].LayerData) do
         List.Add(FStacks[ID].LayerData[j].Material);
end;

function TXRCStructure.GetSelectedLayer: Integer;
begin
  Result := FSelectedLayer
end;

function TXRCStructure.GetSelectedStack: Integer;
begin
  Result := FSelectedStack;
end;

function TXRCStructure.GetStackSize(const ID: Integer): Integer;
begin
  if ID < Length(FStacks) then
     Result := FStacks[ID].N
  else
    Result := -1;
end;

procedure TXRCStructure.GetStacksList(PeriodicOnly: Boolean; List: TStrings; var RealID: TIntArray);
var
  i, count: Integer;
begin
  List.Clear;
  count := 0;
  for I := 0 to High(FStacks) do
  begin
    if not PeriodicOnly then
       List.Add(FStacks[i].Title)
    else
      if FStacks[i].N > 1 then
      begin
        List.Add(FStacks[i].Title);
        Inc(Count);
        SetLength(RealID, Count);
        RealID[count - 1] := i;
      end;
  end;
end;

end.
