(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
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
  kk = 0.54014E-5;

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

  with FMaterials[size] do
  begin
    Name := AName;
    ReadHenke(Name, 0, Lambda, f, am, ro);
  end;
  CurrentMaterial := size;

end;

procedure TLayeredModel.AddSubstrate(const Data: TLayersData);
begin
  SetLength(FLayers, Length(FLayers) + 1);
  with FLayers[Length(FLayers) - 1] do
  begin
    Name := Data[0].Material;
    L    := 1E8;
    s    := Data[0].P[2].V;
    ro   := Data[0].P[3].V;
    StackID := -99;
    LayerID := -99;
  end;
end;

//function TLayeredModel.FindMaterial(const Name: string): TMaterial;
//var
//  i: integer;
//begin
//  for i := 0 to length(FMaterials) - 1 do
//    if FMaterials[i].Name = Name then
//      Break;
//  Result := FMaterials[i];
//end;


procedure TLayeredModel.Generate(const Lambda: Single);
begin
  FLambda := Lambda;
  PrepareLayers;
end;


function TLayeredModel.GetLayers: TCalcLayers;
begin
  SetLength(Result, Length(FLayers));
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
      l_ro := FMaterials[CurrentMaterial].ro;   // use default falue for density

    with FLayers[i] do
    begin
      for g := 0 to High(FProfiles) do
      begin
        if (StackID = FProfiles[g].StackID) and (LayerID = FProfiles[g].LayerID) then
        begin
          case FProfiles[g].Subj of
            ptH : L     := Poly(FProfiles[g].X(i), FProfiles[g]);
            ptS : s     := Poly(FProfiles[g].X(i), FProfiles[g]);
            ptRho: l_ro := Poly(FProfiles[g].X(i), FProfiles[g]);
          end;
        end
      end;
      c := kk * l_ro / FMaterials[CurrentMaterial].am * sqr(FLambda);
      e.re := 1 - FMaterials[CurrentMaterial].f.re * c;
      e.im := FMaterials[CurrentMaterial].f.im * c;
    end;
  end;

  AddMaterial(FLayers[High(FLayers)].Name, FLambda);
  with FLayers[High(FLayers)] do
  begin
    c := kk * FMaterials[CurrentMaterial].ro / FMaterials[CurrentMaterial].am * sqr(FLambda);
    e.re := 1 - FMaterials[CurrentMaterial].f.re * c;
    e.im := FMaterials[CurrentMaterial].f.im * c;
  end;
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

end.
