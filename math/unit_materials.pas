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
  unit_types,
  math_globals;

type

  TMaterials = array of TMaterial;

  TLayeredModel = class
  private
    FMaterials: TMaterials;

    CurrentLayer, CurrentMaterial: integer;

    FLayers: TCalcLayers;
    FLambda: Single;
    FTotalD: single;
    FProfiles: TProfileFunctions;

    procedure PrepareLayers;
//    function FindMaterial(const Name: string): TMaterial;
    procedure AddMaterial(const AName: string; Lambda: single);
    function GetLayers: TCalcLayers;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Init;

    procedure AddLayers(const StackID: integer;  Data: TLayersData);
    procedure AddSubstrate(const Data: TLayersData);

    procedure ExportToFile(const FileName: string);
    procedure LoadFromFile(const FileName: string);
    procedure Generate(const Lambda: Single);

    property Layers: TCalcLayers read GetLayers;
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

procedure TLayeredModel.AddLayers;
var
  i: Integer;
begin
  SetLength(FLayers, Length(FLayers) + Length(Data));

  for I := 0 to High(Data) do
  begin
    if StackID > 0 then
    begin
      FLayers[CurrentLayer + i].StackID := StackID;
      FLayers[CurrentLayer + i].LayerID  := Data[i].LayerID;
    end
    else begin
      FLayers[CurrentLayer + i].LayerID  := Data[i].LayerID;
      FLayers[CurrentLayer + i].StackID  := Data[i].StackID;
    end;

    FLayers[CurrentLayer + i].Name := Data[i].Material;
    FLayers[CurrentLayer + i].L    := Data[i].P[1].V;
    FLayers[CurrentLayer + i].s    := Data[i].P[2].V;
    FLayers[CurrentLayer + i].ro   := Data[i].P[3].V;
  end;
  inc(CurrentLayer, Length(Data));
end;

procedure TLayeredModel.AddMaterial(const AName: string; Lambda: single);
var
  i, size: integer;
begin
  size := length(FMaterials);
  for i := 0 to size - 1 do
    if FMaterials[i].Name = AName then
    begin
      CurrentMaterial := i;
      Exit;
    end;

  SetLength(FMaterials, size + 1);
  FMaterials[size].Name := AName;
  ReadHenke(AName, 0, Lambda, FMaterials[size].f, FMaterials[size].am, FMaterials[size].ro);
  CurrentMaterial := size;
end;

procedure TLayeredModel.AddSubstrate(const Data: TLayersData);
var
  idx: Integer;
begin
  SetLength(FLayers, Length(FLayers) + 1);
  idx := High(FLayers);
  FLayers[idx].Name    := Data[0].Material;
  FLayers[idx].L       := 1E8;
  FLayers[idx].s       := Data[0].P[2].V;
  FLayers[idx].ro      := Data[0].P[3].V;
  FLayers[idx].StackID := 65535;
  FLayers[idx].LayerID := 65535;
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
    AddMaterial(FLayers[i].Name, FLambda);
    if FLayers[i].ro <> 0 then
      l_ro := FLayers[i].ro
    else
      l_ro := FMaterials[CurrentMaterial].ro;   // use default value for density

    for g := 0 to High(FProfiles) do
    begin
      if (FLayers[i].StackID = FProfiles[g].StackID) and (FLayers[i].LayerID = FProfiles[g].LayerID) then
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

  AddMaterial(FLayers[High(FLayers)].Name, FLambda);
  c := ClassicalElectronRadius * FMaterials[CurrentMaterial].ro / FMaterials[CurrentMaterial].am * sqr(FLambda);
  FLayers[High(FLayers)].e.re := 1 - FMaterials[CurrentMaterial].f.re * c;
  FLayers[High(FLayers)].e.im := FMaterials[CurrentMaterial].f.im * c;
end;


constructor TLayeredModel.Create;
begin
  inherited ;
  SetLength(FMaterials, 0);
  SetLength(FLayers, 0);
  SetLength(FProfiles, 0);
end;

destructor TLayeredModel.Destroy;
begin
  Finalize(FMaterials);
  Finalize(FLayers);
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
      S := Format('%s;%f;%f;%f',[FLayers[i].Name, FLayers[i].L,FLayers[i].s,FLayers[i].ro]);
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

  FLayers[0].L := 1E10;
  FLayers[0].e.re := 1;
  FLayers[0].e.im := 0;

  CurrentLayer := 1;
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
    for I := 0 to High(FLayers) do
    begin
      srow.DelimitedText := sdata[i];
      FLayers[i].Name := srow[0];
      FLayers[i].L    := StrToFloat(srow[1]);
      FLayers[i].s    :=  StrToFloat(srow[2]);
      FLayers[i].ro   :=  StrToFloat(srow[3]);
    end;
  finally
    srow.Free;
    sdata.Free;
  end;
end;

end.
