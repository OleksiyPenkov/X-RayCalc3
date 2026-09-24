(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)
unit unit_XRCStructure;

interface

uses
  SysUtils, Classes, VCL.Controls, VCL.ExtCtrls, RzEdit, RzSpnEdt, VCL.StdCtrls,
  VCL.Forms, unit_XRCLayerControl, unit_XRCStackControl,
  RzPanel, RzButton, RzLabel, RzRadChk, RzCommon, Vcl.Graphics, JvDesignSurface,
  unit_materials, unit_Types, System.JSON, System.Generics.Collections, unit_XRCPanel;

type

  TStacks = array of TXRCStack;

  TLayerPos = record
    StackID, LayerID: Integer;
  end;

  { Where the layers went in an insert, delete or move: Map[OldStack][OldLayer]
    is the layer's new (stack, layer), or (-1, -1) once it has been deleted.
    Anything that addresses a layer by its indices - a gradient extension -
    follows it through this map instead of landing on whichever layer takes
    its old place. }
  TLayerMap = TArray<TArray<TLayerPos>>;
  TLayersRenumberedEvent = procedure(Sender: TObject; const Map: TLayerMap) of object;

  TXRCStructure = class (TXRCPanel)
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
      FPeriodicMode: boolean;
      FRealHeight: Integer;
      FOnLayersRenumbered: TLayersRenumberedEvent;

      function LayerControls: TArray<TLayers>;
      procedure NotifyRenumbered(const Before: TArray<TLayers>);
      procedure RealignStacks;
      procedure SetIncrement(const Value: single);
      function GetSelectedStack: Integer;
      function FindBoolValue(const Value: string): boolean;
      function FindValue(const Value: string; Base: single): single;
      function FindStrValue(const Value: string): string;
      function GetSelectedLayer: Integer;
      procedure SetPeriodicMode(const Value: boolean);
      procedure SetCurrentLayerData(const Value: TLayerData);
      function GetSubstrateData: TLayerData;
      procedure SetSubstrateData(const Value: TLayerData);
    public
      constructor Create(AOwner: TComponent; const DPI: integer); reintroduce; overload;
      destructor  Destroy; override;

      property SelectedStack: Integer read GetSelectedStack;
      property SelectedLayer: Integer read GetSelectedLayer;
      property Stacks: TStacks read FStacks;
      property Period: single read FPeriod;
      property PeriodicMode: boolean read FPeriodicMode write SetPeriodicMode;

      procedure AddLayer(const StackID: Integer; const Data: TLayerData);
      procedure InsertLayer(const Data: TLayerData);
      procedure AddStack(const N: Integer; const Title: string);
      procedure InsertStack(const N: Integer; const Title: string);
      procedure AddSubstrate(const Material: string; s, rho: single);
      procedure Select(const ID: Integer);
      procedure ClearSelection(const Reset:boolean = False); inline;
      procedure SelectLayer(const StackID, LayerID: Integer);
      procedure EditNextLayer(const StackID, LayerID: Integer; Frwrd: boolean);

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
      { ValuesOnly = True takes only V (and Material) from Inp and leaves min,
        max, Paired and Fixed as the live layer holds them. That is what the fit
        write-back needs: the structure handed to the engine has its frozen
        parameters collapsed to min = max = V, and those collapsed ranges must
        never flow back into the interface. ValuesOnly = False is the authoring
        route - the limits dialog writing the user's edits back. }
      procedure UpdateInterfaceP(const Inp: TFitStructure; const ValuesOnly: Boolean = False);
      procedure UpdateInterfaceNP(const Inp: TFitStructure; const ValuesOnly: Boolean = False);
      { Sets or clears TFitValue.Fixed on H/sigma/rho for every layer of the given
        stack. This is the structure-panel entry point onto the same flag the
        fit-limits dialog edits; see UpdateInterfaceP for why the write-back must
        seed Data from the live layer rather than starting from a fresh record. }
      procedure SetStackFrozen(const StackID: Integer; const Frozen: Boolean);
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
//      procedure EnablePairing;
      function IfValidLayerSelected: Boolean; inline;
      function HasLayer(const StackID, LayerID: Integer): Boolean;
      property RealHeight: Integer read FRealHeight;
      property LayerData: TLayerData write SetCurrentLayerData;
      property SubstrateData: TLayerData read GetSubstrateData write SetSubstrateData;
      { Fired after InsertLayer, InsertStack, DeleteLayer, DeleteStack and
        MoveLayer. Appending (AddLayer, AddStack, PasteLayer) moves no layer;
        FromString and Clear replace the structure as a whole, so their layers
        have no predecessors to map. }
      property OnLayersRenumbered: TLayersRenumberedEvent read FOnLayersRenumbered write FOnLayersRenumbered;
    published
      property Increment: single read FIncrement write SetIncrement;
  end;

var
  Structure: TXRCStructure;

implementation

uses
  unit_consts, editor_Layer;

{ A Single as the shortest decimal that reads back as the same Single: 0.9,
  not the 0.899999976158142 its Double widening prints. The model text is
  both what Edit as text shows and what the project stores, so the value
  must survive the round trip exactly; nine significant digits always do. }
function SingleJSON(const V: Single): TJSONNumber;
var
  Prec: Integer;
  S: string;
begin
  for Prec := 1 to 9 do
  begin
    S := FloatToStrF(V, ffGeneral, Prec, 0, TFormatSettings.Invariant);
    if Single(StrToFloat(S, TFormatSettings.Invariant)) = V then
      Exit(TJSONNumber.Create(S));
  end;
  Result := TJSONNumber.Create(Double(V));
end;

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

  MaxHeigh := Header.Height;

  for I := 0 to Count do
  begin
    FStacks[i].Top := MaxHeigh + 5;
    FStacks[i].Align := alTop;
    MaxHeigh := MaxHeigh + FStacks[i].Height + 5;
  end;

  Substrate.Top := ClientHeight - 5;
  Substrate.Align := alTop;

  FRealHeight := MaxHeigh + Substrate.ClientHeight;
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
  FStacks[Count] := TXRCStack.Create(Box, Title, N, FTargetDPI);
  FStacks[Count].ID := Count;

  RealignStacks;
end;

procedure TXRCStructure.AddSubstrate(const Material: string; s,
  rho: single);
begin
  Substrate := TXRCStack.Create(Box, 'Substrate', 1, FTargetDPI);
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

function TXRCStructure.HasLayer(const StackID, LayerID: Integer): Boolean;
begin
  // Layer coordinates reach the main form through posted (asynchronous)
  // messages and may be stale by the time they are dispatched. Release builds
  // have range checking off, so indexing FStacks with them reads raw memory.
  Result := (StackID >= 0) and (StackID <= High(FStacks)) and
            (FStacks[StackID] <> nil) and
            (LayerID >= 0) and (LayerID <= High(FStacks[StackID].Layers));
end;

procedure TXRCStructure.CopyLayer;
begin
  if not IfValidLayerSelected then Exit;

  FClipBoardLayers[0] := FStacks[FSelectedLayerParent].LayerData[FSelectedLayer];
  ClearSelection(Reset);
end;

constructor TXRCStructure.Create(AOwner: TComponent; const DPI: integer);

  procedure CreateLabel(const Caption: string; Left: Integer; var MyLabel: TRzLabel);
  begin
    MyLabel := TRzLabel.Create(Self);

    MyLabel.Parent := Header;
    MyLabel.Left := Left;
    MyLabel.Top := 6;
    MyLabel.Width := ScaleForDPI(37);
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
  FTargetDPI := DPI;
  Align := alClient;
  BorderInner := fsNone;
  BorderOuter := fsNone;

  //RzPanel1
  Header := TRzPanel.Create(Self);

  //Labels
  CreateLabel('Stack / Layer', 6, Label1);
  CreateLabel('H (Å)', 110, Label2);
  CreateLabel('σ (Å)', 185, Label3);
  CreateLabel('ρ (g/cm³)   N', 248, Label4);

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
    DeleteLayer(FSelectedLayerParent, FSelectedLayer);
end;

procedure TXRCStructure.DeleteLayer(const StackID, LayerID: Integer);
var
  Before: TArray<TLayers>;
begin
  // The indices may come from a posted message and be stale by now.
  if not HasLayer(StackID, LayerID) then Exit;

  Before := LayerControls;
  FStacks[StackID].DeleteLayer(LayerID);
  FSelectedLayerParent := -1;
  FSelectedLayer := -1;
  NotifyRenumbered(Before);
end;

procedure TXRCStructure.DeleteStack;
var
  i: integer;
  Before: TArray<TLayers>;
begin
  if FSelectedStack > -1 then
  begin
    Before := LayerControls;
    FStacks[FSelectedStack].Free;
    Delete(FStacks, FSelectedStack, 1);
    FSelectedStack := -1;

    for I := 0 to High(FStacks) do
    begin
      FStacks[i].ID := i;
      FStacks[i].UpdateLayersID;
    end;
    NotifyRenumbered(Before);
  end;
end;

function TXRCStructure.LayerControls: TArray<TLayers>;
var
  i: Integer;
begin
  SetLength(Result, Length(FStacks));
  for i := 0 to High(FStacks) do
    Result[i] := Copy(FStacks[i].Layers);
end;

{ Layer controls keep their identity through every insert, delete and move -
  only their place in the arrays changes - so a layer is found again by its
  control. A deleted control is only compared, never dereferenced, and nothing
  is created between the snapshot and here that could take its address. }
procedure TXRCStructure.NotifyRenumbered(const Before: TArray<TLayers>);
var
  Map: TLayerMap;
  s, l, ns, nl: Integer;
begin
  if not Assigned(FOnLayersRenumbered) then Exit;

  SetLength(Map, Length(Before));
  for s := 0 to High(Before) do
  begin
    SetLength(Map[s], Length(Before[s]));
    for l := 0 to High(Before[s]) do
    begin
      Map[s][l].StackID := -1;
      Map[s][l].LayerID := -1;
      for ns := 0 to High(FStacks) do
        for nl := 0 to High(FStacks[ns].Layers) do
          if FStacks[ns].Layers[nl] = Before[s][l] then
          begin
            Map[s][l].StackID := ns;
            Map[s][l].LayerID := nl;
          end;
    end;
  end;
  FOnLayersRenumbered(Self, Map);
end;

destructor TXRCStructure.Destroy;
begin
//  FreeAndNil(Substrate);
  inherited Destroy;
end;

procedure TXRCStructure.EditNextLayer(const StackID, LayerID: Integer;
  Frwrd: boolean);
begin
  if not HasLayer(StackID, LayerID) then Exit;

  Stacks[StackID].UpdateLayer(LayerID, edtrLayer.GetData);

  if Frwrd then
  begin
    if LayerID < High(Stacks[StackID].Layers) then
    begin
      edtrLayer.SetData(False, Stacks[StackID].Layers[LayerID + 1].Data);
    end
    else if StackID < High(Stacks) then
    begin
      edtrLayer.SetData(False, Stacks[StackID + 1].Layers[0].Data);
    end;
  end
  else begin
    if LayerID > 0 then
    begin
      edtrLayer.SetData(False, Stacks[StackID].Layers[LayerID - 1].Data);
    end
    else if StackID > 0 then
    begin
      edtrLayer.SetData(False, Stacks[StackID - 1].Layers[High(Stacks[StackID - 1].Layers)].Data);
    end;
  end;

end;

procedure TXRCStructure.EditStack;
begin
  FStacks[ID].Edit;
end;


procedure TXRCStructure.InsertLayer(const Data: TLayerData);
var
  StackID: Integer;
  Before: TArray<TLayers>;
begin
  Before := LayerControls;
  StackID := FSelectedLayerParent;
  FStacks[StackID].AddLayer(Data, FSelectedLayer);
  NotifyRenumbered(Before);
end;

procedure TXRCStructure.InsertStack(const N: Integer; const Title: string);
var
  Count, pos, i: Integer;
  Before: TArray<TLayers>;
begin
  Before := LayerControls;
  FVisibility := Visible;
  Visible := False;

  Count := Length(FStacks);

  if FSelectedStack <> -1 then Pos := FSelectedStack
    else Pos := count;

  Insert(Nil, FStacks, pos);

  FStacks[Pos] := TXRCStack.Create(Box, Title, N, FTargetDPI);

  // Inserting shifts every stack after Pos down by one, so all IDs must be
  // renumbered - not just the new stack's. Layers cache their StackID and post
  // it back on click, so a stale ID routes the click to the wrong stack.
  for I := 0 to High(FStacks) do
  begin
    FStacks[i].ID := i;
    FStacks[i].UpdateLayersID;
  end;

  RealignStacks;
  NotifyRenumbered(Before);
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
  Source, StackLayers: TLayersData;
begin
  FPeriod := 0;
  Result := TLayeredModel.Create;
  Result.Init;

  for I := 0 to High(FStacks) do
  begin
    Source := FStacks[i].LayerData;
    StackLayers := Copy(Source);
    for j := 1  to FStacks[i].N do
    begin
      if ExpandProfiles and (FStacks[i].N > 1) then
      begin
        for k := 0 to High(StackLayers) do
          for p := 1 to 3 do
            StackLayers[k].P[p].V := Source[k].PeriodValue(p, j, FStacks[i].N, True);
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
var
  Before: TArray<TLayers>;
begin
  // The indices come from a posted message and may be stale by now.
  if not HasLayer(StackID, LayerID) then Exit;

  Before := LayerControls;
  FStacks[StackID].MoveLayer(LayerID, Direction);
  NotifyRenumbered(Before);
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

  // StackID arrives through a posted (asynchronous) message and may be stale by
  // the time it is dispatched - the structure can change in between.
  if (StackID < 0) or (StackID > High(FStacks)) then
  begin
    FSelectedLayerParent := -1;
    FSelectedLayer := -1;
    Exit;
  end;

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

procedure TXRCStructure.SetCurrentLayerData(const Value: TLayerData);
begin
  if not HasLayer(Value.StackID, Value.LayerID) then Exit;

  Stacks[Value.StackID].UpdateLayer(Value.LayerID, Value);
end;

procedure TXRCStructure.SetIncrement(const Value: single);
var
  i: Integer;
begin
  FIncrement := Value;
  for I := 0 to High(FStacks) do
    FStacks[i].Increment := Value;
end;

procedure TXRCStructure.SetPeriodicMode(const Value: boolean);
var
  Stack: TXRCStack;
begin
  for Stack in FStacks do
    Stack.EnablePairing(not Value);
end;

procedure TXRCStructure.SetSubstrateData(const Value: TLayerData);
begin
  Substrate.UpdateLayer(0, Value);
end;

procedure TXRCStructure.UpdateInterfaceNP(const Inp: TFitStructure;
  const ValuesOnly: Boolean);
var
  i, j, p: integer;
  Count: integer;
  Data: TLayerData;
begin
  { Only TLFPSO_Irregular's result fits here: one stack, every physical layer
    in order, repeats expanded. Anything else would be indexed past its end
    below - Release has no range check, so the layers would fill with garbage. }
  if Length(Inp.Stacks) <> 1 then
    raise EArgumentException.CreateFmt(
      'UpdateInterfaceNP expects the irregular engine''s single flattened stack, got %d stacks',
      [Length(Inp.Stacks)]);

  Count := 0;
  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].Layers) do
    begin
      // See UpdateInterfaceP: seed from the live layer so its cached
      // StackID/LayerID survive the write-back.
      Data := FStacks[i].Layers[j].Data;
      Data.Material := Inp.Stacks[0].Layers[Count].Material;
      if ValuesOnly then
      begin
        for p := 1 to 3 do
          Data.P[p].V := Inp.Stacks[0].Layers[Count].P[p].V;
      end
      else
        Data.P := Inp.Stacks[0].Layers[Count].P;
      FStacks[i].UpdateLayer(j, Data);
      inc(Count);
    end;
    inc(Count, (FStacks[i].N - 1) * (High(FStacks[i].Layers) + 1));
  end;
end;

procedure TXRCStructure.UpdateInterfaceP(const Inp: TFitStructure;
  const ValuesOnly: Boolean);
var
  i, j, p: integer;
  Data: TLayerData;
begin
  for I := 0 to High(FStacks) do
  begin
    for j := 0 to High(FStacks[i].Layers) do
    begin
      // Start from the layer as it stands: a fresh TLayerData only has its
      // managed fields zeroed, so StackID/LayerID would arrive as stack
      // garbage and the layer would post that garbage back on the next click.
      Data := FStacks[i].Layers[j].Data;
      Data.Material := Inp.Stacks[i].Layers[j].Material;
      if ValuesOnly then
      begin
        for p := 1 to 3 do
          Data.P[p].V := Inp.Stacks[i].Layers[j].P[p].V;
      end
      else
        Data.P := Inp.Stacks[i].Layers[j].P;
      FStacks[i].UpdateLayer(j, Data);
    end;
  end;
end;

procedure TXRCStructure.SetStackFrozen(const StackID: Integer; const Frozen: Boolean);
var
  j, p: integer;
  Data: TLayerData;
begin
  if (StackID < 0) or (StackID > High(FStacks)) then Exit;

  for j := 0 to High(FStacks[StackID].Layers) do
  begin
    // See UpdateInterfaceP: seed from the live layer so its cached
    // StackID/LayerID survive the write-back.
    Data := FStacks[StackID].Layers[j].Data;
    for p := 1 to 3 do
      Data.P[p].Fixed := Frozen;
    FStacks[StackID].UpdateLayer(j, Data);
  end;

  FStacks[StackID].UpdateInfo;
end;

procedure TXRCStructure.UpdateProfiles(const Inp: TLayeredModel);
var
  i, j, p, SID, LID: integer;
begin
  for I := 0 to High(FStacks) do
     for j := 0 to High(FStacks[i].Layers) do
       for p := 1 to 3 do
         FStacks[i].Layers[j].Data.ClearProfiles(p);

  for I := 1 to High(Inp.Layers) - 1 do
  begin
    SID := Inp.StackIDs[i];
    LID := Inp.LayerIDs[i];
    for p := 1 to 3 do
      if not Structure.FStacks[SID].Layers[LID].Data.P[p].Paired then
        case p of
          1: Structure.FStacks[SID].Layers[LID].Data.AddProfilePoint(Inp.Layers[i].L, 1);
          2: Structure.FStacks[SID].Layers[LID].Data.AddProfilePoint(Inp.Layers[i].s, 2);
          3: Structure.FStacks[SID].Layers[LID].Data.AddProfilePoint(Inp.Layers[i].ro, 3);
        end;
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
          JLayer.AddPair(PAlias[p], SingleJSON(Data.P[p].V));
          JLayer.AddPair(UpperCase(PAlias[p]) + 'P', Data.P[p].Paired);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'F', Data.P[p].Fixed);
          JLayer.AddPair(UpperCase(PAlias[p]) + 'min', SingleJSON(Data.P[p].min));
          JLayer.AddPair(UpperCase(PAlias[p]) + 'max', SingleJSON(Data.P[p].max));
          Profile := Data.ProfileToString(TParameterType(p - 1));
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
    JSub.AddPair('s', SingleJSON(Data.P[2].V));
    JSub.AddPair('r', SingleJSON(Data.P[3].V));

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
      // Only the three values come from the fit - the identity, the pairing
      // flags and the fit limits belong to the layer and must survive.
      Data := FStacks[i].Layers[j].Data;
      Data.Material := Inp.LayerNames[Count];
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
          Data.P[p].Fixed := FindBoolValue(UpperCase(PAlias[p]) + 'F');
          Data.P[p].min := FindValue(UpperCase(PAlias[p]) + 'min', Data.P[p].V);
          Data.P[p].max := FindValue(UpperCase(PAlias[p]) + 'max', Data.P[p].V);

          { Data is reused for every layer, so a layer saved without a table
            must not keep the one read for the layer before it. }
          Data.ClearProfiles(p);
          PS := FindStrValue('Profile' + UpperCase(PAlias[p]));
          if PS <> '' then
            Data.ProfileFromString(p, PS);

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

function TXRCStructure.GetSubstrateData: TLayerData;
begin
  Result := Substrate.Layers[0].Data;
end;

end.
