unit unit_xrf_lines;

interface

uses
  System.SysUtils, System.Generics.Collections;

type
  TXRFLineRec = record
    Symbol: string;
    Z: Byte;
    Lambda: Double;  // Angstroms
  end;

procedure LoadXRFLines(const FileName: string);
function GetXRFLambda(const Element: string): Double;
function ExpandElementRange(const RangeStr: string): TArray<string>;
function GetAllElements: TArray<string>;

implementation

uses
  System.IOUtils, System.JSON, System.Generics.Defaults;

var
  FLines: TArray<TXRFLineRec>;
  FIndex: TDictionary<string, Integer>;
  FLoaded: Boolean;

procedure EnsureLoaded;
begin
  if not FLoaded then
    raise Exception.Create('XRF lines not loaded. Call LoadXRFLines first.');
end;

procedure LoadXRFLines(const FileName: string);
var
  JSON, LinesObj, EntryObj: TJSONObject;
  Pair: TJSONPair;
  i, Count: Integer;
begin
  if not TFile.Exists(FileName) then
    raise Exception.CreateFmt('XRF lines file not found: "%s"', [FileName]);

  JSON := TJSONObject.ParseJSONValue(TFile.ReadAllText(FileName)) as TJSONObject;
  if JSON = nil then
    raise Exception.Create('Invalid JSON in XRF lines file');
  try
    LinesObj := JSON.GetValue<TJSONObject>('lines');
    Count := LinesObj.Count;
    SetLength(FLines, Count);
    i := 0;
    for Pair in LinesObj do
    begin
      EntryObj := Pair.JsonValue as TJSONObject;
      FLines[i].Symbol := Pair.JsonString.Value;
      FLines[i].Z := EntryObj.GetValue<Byte>('Z');
      FLines[i].Lambda := EntryObj.GetValue<Double>('lambda');
      Inc(i);
    end;
  finally
    JSON.Free;
  end;

  // Sort by Z to maintain element ordering
  TArray.Sort<TXRFLineRec>(FLines, TComparer<TXRFLineRec>.Construct(
    function(const A, B: TXRFLineRec): Integer
    begin
      Result := Integer(A.Z) - Integer(B.Z);
    end));

  // Build lookup index
  FreeAndNil(FIndex);
  FIndex := TDictionary<string, Integer>.Create(Count);
  for i := 0 to High(FLines) do
    FIndex.Add(UpperCase(FLines[i].Symbol), i);

  FLoaded := True;
end;

function GetXRFLambda(const Element: string): Double;
var
  Idx: Integer;
begin
  EnsureLoaded;
  if not FIndex.TryGetValue(UpperCase(Trim(Element)), Idx) then
    raise EArgumentException.CreateFmt('Unknown element: "%s"', [Element]);
  Result := FLines[Idx].Lambda;
end;

function FindElementIndex(const Element: string): Integer;
begin
  EnsureLoaded;
  if not FIndex.TryGetValue(UpperCase(Trim(Element)), Result) then
    raise EArgumentException.CreateFmt('Unknown element: "%s"', [Element]);
end;

function ExpandElementRange(const RangeStr: string): TArray<string>;
var
  Parts: TArray<string>;
  IdxFrom, IdxTo, Temp, i, Count: Integer;
begin
  Parts := RangeStr.Split(['-']);
  if Length(Parts) <> 2 then
    raise EArgumentException.CreateFmt('Invalid range format: "%s"', [RangeStr]);

  IdxFrom := FindElementIndex(Trim(Parts[0]));
  IdxTo := FindElementIndex(Trim(Parts[1]));

  // Silently reverse if needed
  if IdxFrom > IdxTo then
  begin
    Temp := IdxFrom;
    IdxFrom := IdxTo;
    IdxTo := Temp;
  end;

  Count := IdxTo - IdxFrom + 1;
  SetLength(Result, Count);
  for i := 0 to Count - 1 do
    Result[i] := FLines[IdxFrom + i].Symbol;
end;

function GetAllElements: TArray<string>;
var
  i: Integer;
begin
  EnsureLoaded;
  SetLength(Result, Length(FLines));
  for i := 0 to High(FLines) do
    Result[i] := FLines[i].Symbol;
end;

initialization

finalization
  FIndex.Free;

end.
