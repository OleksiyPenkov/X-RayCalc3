(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_materials;

interface

uses
  SysUtils,
  System.Generics.Collections,
  unit_types,
  math_globals;

type

  TMaterials = array of TMaterial;

  TLayeredModel = class
  private
    FMaterials: TMaterials;
    FMaterialIndex: TDictionary<string, Integer>;

    CurrentLayer, CurrentMaterial: integer;

    FLayers: TCalcLayers;
    FLayerNames: TArray<string>;
    FLayerIDs: TArray<Word>;
    FStackIDs: TArray<Word>;
    FLambda: Single;
    FTotalD: single;
    FProfiles: TProfileFunctions;

    procedure PrepareLayers;
    procedure AddMaterial(const AName: string; Lambda: single);
    function GetLayers: TCalcLayers;
    procedure GrowParallel(NewLen: Integer);
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init;
    procedure Reset;

    procedure AddLayers(const StackID: integer;  Data: TLayersData); overload;
    procedure AddLayers(const StackID: integer; const Data: TLayersData; Count: integer); overload;
    procedure AddSubstrate(const Data: TLayersData);

    procedure ExportToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure Generate(const Lambda: Single);

    property Layers: TCalcLayers read GetLayers;
    property LayersDirect: TCalcLayers read FLayers;
    property LayerNames: TArray<string> read FLayerNames;
    property LayerIDs: TArray<Word> read FLayerIDs;
    property StackIDs: TArray<Word> read FStackIDs;
    property TotalD: Single read FTotalD;
    property Materials: TMaterials read FMaterials write FMaterials;
    property Profiles: TProfileFunctions read FProfiles write FProfiles;
   end;

implementation

uses
  System.Classes;

const
  ClassicalElectronRadius = 0.54014E-5;  // r_e * N_A / (2*pi) in CGS units

{ TLayeredModel }

procedure TLayeredModel.AddLayers(const StackID: integer; Data: TLayersData);
begin
  AddLayers(StackID, Data, Length(Data));
end;

procedure TLayeredModel.AddLayers(const StackID: integer; const Data: TLayersData; Count: integer);
var
  i, NewLen: Integer;
begin
  NewLen := CurrentLayer + Count;
  if Length(FLayers) < NewLen then
  begin
    SetLength(FLayers, NewLen);
    GrowParallel(NewLen);
  end;

  for I := 0 to Count - 1 do
  begin
    if StackID > 0 then
    begin
      FStackIDs[CurrentLayer + i] := StackID;
      FLayerIDs[CurrentLayer + i] := Data[i].LayerID;
    end
    else begin
      FLayerIDs[CurrentLayer + i] := Data[i].LayerID;
      FStackIDs[CurrentLayer + i] := Data[i].StackID;
    end;

    FLayerNames[CurrentLayer + i] := Data[i].Material;
    FLayers[CurrentLayer + i].L    := Data[i].P[1].V;
    FLayers[CurrentLayer + i].s    := Data[i].P[2].V;
    FLayers[CurrentLayer + i].ro   := Data[i].P[3].V;
  end;
  inc(CurrentLayer, Count);
end;

procedure TLayeredModel.AddMaterial(const AName: string; Lambda: single);
var
  idx, size: integer;
begin
  if FMaterialIndex.TryGetValue(AName, idx) then
  begin
    CurrentMaterial := idx;
    Exit;
  end;

  size := Length(FMaterials);
  SetLength(FMaterials, size + 1);
  FMaterials[size].Name := AName;
  ReadHenke(AName, 0, Lambda, FMaterials[size].f, FMaterials[size].am, FMaterials[size].ro);
  FMaterialIndex.Add(AName, size);
  CurrentMaterial := size;
end;

procedure TLayeredModel.AddSubstrate(const Data: TLayersData);
var
  idx, NewLen: Integer;
begin
  NewLen := CurrentLayer + 1;
  if Length(FLayers) < NewLen then
  begin
    SetLength(FLayers, NewLen);
    GrowParallel(NewLen);
  end;
  idx := CurrentLayer;
  FLayerNames[idx] := Data[0].Material;
  FLayers[idx].L   := 1E8;
  FLayers[idx].s   := Data[0].P[2].V;
  FLayers[idx].ro  := Data[0].P[3].V;
  FStackIDs[idx]   := 65535;
  FLayerIDs[idx]   := 65535;
end;

procedure TLayeredModel.Generate(const Lambda: Single);
begin
  FLambda := Lambda;
  PrepareLayers;
end;


function TLayeredModel.GetLayers: TCalcLayers;
begin
  Result := Copy(FLayers, 0, Length(FLayers));
end;

procedure TLayeredModel.PrepareLayers;
var
  i, g: Integer;
  c, l_ro: Single;
begin
  for I := 1 to High(FLayers) - 1 do
  begin
    AddMaterial(FLayerNames[i], FLambda);
    if FLayers[i].ro <> 0 then
      l_ro := FLayers[i].ro
    else
      l_ro := FMaterials[CurrentMaterial].ro;   // use default value for density

    for g := 0 to High(FProfiles) do
    begin
      if (FStackIDs[i] = FProfiles[g].StackID) and (FLayerIDs[i] = FProfiles[g].LayerID) then
      begin
        case FProfiles[g].Subj of
          ptH  : FLayers[i].L := Poly(FProfiles[g].X(i), FProfiles[g]);
          ptS  : FLayers[i].s := Poly(FProfiles[g].X(i), FProfiles[g]);
          ptRho: l_ro         := Poly(FProfiles[g].X(i), FProfiles[g]);
        end;
      end
    end;
    c := ClassicalElectronRadius * l_ro / FMaterials[CurrentMaterial].am * sqr(FLambda);
    FLayers[i].e.re := 1 - FMaterials[CurrentMaterial].f.re * c;
    FLayers[i].e.im := FMaterials[CurrentMaterial].f.im * c;
  end;

  AddMaterial(FLayerNames[High(FLayers)], FLambda);
  c := ClassicalElectronRadius * FMaterials[CurrentMaterial].ro / FMaterials[CurrentMaterial].am * sqr(FLambda);
  FLayers[High(FLayers)].e.re := 1 - FMaterials[CurrentMaterial].f.re * c;
  FLayers[High(FLayers)].e.im := FMaterials[CurrentMaterial].f.im * c;
end;


procedure TLayeredModel.GrowParallel(NewLen: Integer);
begin
  if Length(FLayerNames) < NewLen then
    SetLength(FLayerNames, NewLen);
  if Length(FLayerIDs) < NewLen then
    SetLength(FLayerIDs, NewLen);
  if Length(FStackIDs) < NewLen then
    SetLength(FStackIDs, NewLen);
end;

constructor TLayeredModel.Create;
begin
  inherited ;
  FMaterialIndex := TDictionary<string, Integer>.Create;
  SetLength(FMaterials, 0);
  SetLength(FLayers, 0);
  SetLength(FLayerNames, 0);
  SetLength(FLayerIDs, 0);
  SetLength(FStackIDs, 0);
  SetLength(FProfiles, 0);
end;

destructor TLayeredModel.Destroy;
begin
  FMaterialIndex.Free;
  Finalize(FMaterials);
  Finalize(FLayers);
  Finalize(FLayerNames);
  Finalize(FLayerIDs);
  Finalize(FStackIDs);
  Finalize(FProfiles);
  inherited;
end;

procedure TLayeredModel.ExportToFile(const FileName: string);
var
  SL: TStringList;
  i: Integer;
  S: string;
begin
  SL := TStringList.Create;
  try
    for I := 1 to High(FLayers) do
    begin
      S := Format('%s;%f;%f;%f',[FLayerNames[i], FLayers[i].L,FLayers[i].s,FLayers[i].ro]);
      SL.Add(S);
    end;
    SL.SaveToFile(FileName);
  finally
    FreeAndNil(SL);
  end;
end;

procedure TLayeredModel.Init;
begin
  SetLength(FLayers, 0);
  SetLength(FLayers, 1);
  SetLength(FLayerNames, 0);
  SetLength(FLayerNames, 1);
  SetLength(FLayerIDs, 0);
  SetLength(FLayerIDs, 1);
  SetLength(FStackIDs, 0);
  SetLength(FStackIDs, 1);

  FLayers[0].L := 1E10;
  FLayers[0].e.re := 1;
  FLayers[0].e.im := 0;

  CurrentLayer := 1;
end;

procedure TLayeredModel.Reset;
begin
  // Keep FLayers allocation — reuse on next FillModel
  if Length(FLayers) < 1 then
    SetLength(FLayers, 1);
  if Length(FLayerNames) < 1 then
    SetLength(FLayerNames, 1);
  if Length(FLayerIDs) < 1 then
    SetLength(FLayerIDs, 1);
  if Length(FStackIDs) < 1 then
    SetLength(FStackIDs, 1);

  FLayers[0].L := 1E10;
  FLayers[0].e.re := 1;
  FLayers[0].e.im := 0;

  CurrentLayer := 1;
  // FMaterials and FMaterialIndex preserved for caching
end;

procedure TLayeredModel.LoadFromFile(const FileName: string);
var
  sdata, srow: TStrings;
  i:integer;
begin
  sdata:=TStringList.Create;
  srow:=TStringList.Create;
  try
    srow.Delimiter := ';';
    srow.StrictDelimiter:= true;
    sdata.LoadFromFile(FileName, TEncoding.UTF8);
    SetLength(FLayers, 0);
    SetLength(FLayers, sdata.Count);
    SetLength(FLayerNames, sdata.Count);
    SetLength(FLayerIDs, sdata.Count);
    SetLength(FStackIDs, sdata.Count);
    for I := 0 to High(FLayers) do
    begin
      srow.DelimitedText := sdata[i];
      FLayerNames[i] := srow[0];
      FLayers[i].L   := StrToFloat(srow[1]);
      FLayers[i].s   := StrToFloat(srow[2]);
      FLayers[i].ro  := StrToFloat(srow[3]);
    end;
  finally
    srow.Free;
    sdata.Free;
  end;
end;

end.
