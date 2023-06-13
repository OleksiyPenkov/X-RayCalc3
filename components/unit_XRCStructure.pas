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

      FSelectedStack : Integer;

      FSelectedLayer : Integer;
      FSelectedLayerParent : Integer;

      FIncrement: single;
      FVisibility: boolean;

      FClipBoardLayers: TLayersData;
      JLayer, JStack, JSub: TJSONValue;

      procedure RealignStacks;
      procedure SetIncrement(const Value: single);
      function GetSelected: Integer;
      procedure ClearSelection(const Reset:boolean = False); inline;
      function FindBoolValue(const Value: string): boolean;
      function FindValue(const Value: string; Base: single): single;
      function FindStrValue(const Value: string): string;
    public
      constructor Create(AOwner: TComponent);
      destructor  Destroy; override;

      property Selected: Integer read GetSelected;
      property Stacks: TStacks read FStacks;

      procedure AddLayer(const StackID: Integer; const Data: TLayerData);
      procedure AddStack(const N: Integer; const Title: string);
      procedure InsertStack(const N: Integer; const Title: string);
      procedure AddSubstrate(const Material: string; s, rho: single);
      procedure Select(const ID: Integer);
      procedure SelectLayer(const StackID, LayerID: Integer);
      procedure LinkLayer(const StackID, LayerID: Integer);
      procedure EditStack(const ID: Integer);
      procedure DeleteStack;
      procedure DeleteLayer;

      function Model(const ExpandProfiles: Boolean): TLayeredModel;
      function Materials: TMaterialsList;

      function ToString: string;
      procedure FromString(const S: string);
      function ToFitStructure: TFitStructure;
      procedure FromFitStructure(const Inp: TLayeredModel);
      procedure RecreateFromFitStructure(const Inp: TFitStructure);
      procedure UpdateInterfaceP(const Inp: TFitStructure);
      procedure UpdateInterfaceNP(const Inp: TFitStructure);
      procedure UpdateProfiles(const Inp: TLayeredModel);
      procedure Clear;
      procedure CopyLayer(const Reset: boolean);
      procedure PasteLayer;
      function IsPeriodic: boolean; overload;
      function IsPeriodic(const Index: integer): boolean; overload;
      procedure GetStacksList(PeriodicOnly: Boolean; List: TStrings; var RealID: TIntArray);
      procedure GetLayersList(const ID: integer; List: TStrings);
      function GetStackSize(const ID: Integer): Integer;
      procedure EnablePairing;
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

procedure TXRCStructure.CopyLayer;
begin
  FClipBoardLayers[0] := FStacks[FSelectedLayerParent].LayerData[FSelectedLayer];
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
  Label2.Left := 110;
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
  Label3.Left := 181;
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
  Label4.Caption := 'ρ (g/cm³)   N';
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
    FStacks[FSelectedLayerParent].DeleteLayer(FSelectedLayer);
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
    FStacks[FSelectedStack].Free;
    Delete(FStacks, FSelectedStack, 1);
    FSelectedStack := -1;

    for I := 0 to High(FStacks) do
      FStacks[i].ID := i;
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
  i, j, k: Integer;
  StackLayers: TLayersData;
begin
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
        begin
          StackLayers[k].H.V := StackLayers[k].PH[j - 1];
          StackLayers[k].s.V := StackLayers[k].PS[j - 1];
          StackLayers[k].r.V := StackLayers[k].PR[j - 1];
        end;
      end;
      Result.AddLayers(i, StackLayers);
    end;
  end;

  Result.AddSubstrate(Substrate.LayerData);
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
      Data.H := Inp.Stacks[0].Layers[Count].H;
      Data.s := Inp.Stacks[0].Layers[Count].s;
      Data.r := Inp.Stacks[0].Layers[Count].r;
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
      Data.H := Inp.Stacks[i].Layers[j].H;
      Data.s := Inp.Stacks[i].Layers[j].s;
      Data.r := Inp.Stacks[i].Layers[j].r;
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

    if FStacks[i].N > 1 then
    begin
      D := 0;
      for j := 0 to High(FStacks[i].LayerData) do
      begin
        Result.Stacks[i].Layers[j].LayerID := j;
        D := D + FStacks[i].LayerData[j].H.V;
      end;
      Result.Stacks[i].D := D;
    end;

    for j := 0 to High(FStacks[i].LayerData) do
    begin
      Result.Stacks[i].Layers[j].Material := FStacks[i].LayerData[j].Material;
      Result.Stacks[i].Layers[j].H := FStacks[i].LayerData[j].H;
      Result.Stacks[i].Layers[j].s := FStacks[i].LayerData[j].s;
      Result.Stacks[i].Layers[j].r := FStacks[i].LayerData[j].r;
      Result.Stacks[i].Layers[j].StackID := i;
      Result.Stacks[i].Layers[j].LayerID := j;
    end;
    Result.Stacks[i].D := D;
  end;

  Result.Subs.Material := Substrate.LayerData[0].Material;
  Result.Subs.H := Substrate.LayerData[0].H;
  Result.Subs.s := Substrate.LayerData[0].s;
  Result.Subs.r := Substrate.LayerData[0].r;
end;

function TXRCStructure.ToString: string;
var
  i, j: Integer;
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
        JLayer.AddPair('H', Data.H.V);
        JLayer.AddPair('HP', Data.H.Paired);
        JLayer.AddPair('Hmin', Data.H.min);
        JLayer.AddPair('Hmax', Data.H.max);
        Profile := Data.ProfileToSrting(gsL);
        JLayer.AddPair('ProfileH', Profile);

        JLayer.AddPair('s', Data.s.V);
        JLayer.AddPair('SP', Data.s.Paired);
        JLayer.AddPair('Smin', Data.s.min);
        JLayer.AddPair('Smax', Data.s.max);
        Profile := Data.ProfileToSrting(gsS);
        JLayer.AddPair('ProfileS', Profile);

        JLayer.AddPair('r', Data.r.V);
        JLayer.AddPair('RP', Data.r.Paired);
        JLayer.AddPair('Rmin', Data.r.min);
        JLayer.AddPair('Rmax', Data.r.max);
        Profile := Data.ProfileToSrting(gsRo);
        JLayer.AddPair('ProfileR', Profile);

        JLayers.Add(JLayer);
      end;
      JStack.AddPair('Layers', JLayers);
      JStacks.Add(JStack);
    end;

    Data := Substrate.LayerData[0];
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

  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].LayerData) do
    begin
      Data.Material := Inp.Layers[Count].Name;
      Data.H.V := Inp.Layers[Count].L;
      Data.s.V := Inp.Layers[Count].s * 1.41;
      Data.r.V := Inp.Layers[Count].ro;
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
  ts: string;
  Profiles: array [1..3] of string;
  LayerIndex: Integer;

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
        Data.H.Paired := FindBoolValue('HP');
        Data.H.min := FindValue('Hmin', Data.H.V);
        Data.H.max := FindValue('Hmax', Data.H.V);
        Profiles[1] := FindStrValue('ProfileH');


        Data.s.V := JLayer.GetValue<single>('s');
        Data.s.Paired := FindBoolValue('SP');
        Data.s.min := FindValue('Smin', Data.s.V);
        Data.s.max := FindValue('Smax', Data.s.V);
        Profiles[2] := FindStrValue('ProfileS');


        Data.r.V := JLayer.GetValue<single>('r');
        Data.r.Paired := FindBoolValue('RP');
        Data.r.min := FindValue('Rmin', Data.r.V);
        Data.r.max := FindValue('Rmax', Data.r.V);
        Profiles[3] := FindStrValue('ProfileR');

        if Profiles[1] <> '' then
        begin
          Data.ClearProfiles;
          Data.ProfileFromSrting(gsL, Profiles[1]);
          Data.ProfileFromSrting(gsS, Profiles[2]);
          Data.ProfileFromSrting(gsRo, Profiles[3]);
        end;

        LayerIndex := FStacks[i].AddLayer(Data);
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

function TXRCStructure.GetSelected: Integer;
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
