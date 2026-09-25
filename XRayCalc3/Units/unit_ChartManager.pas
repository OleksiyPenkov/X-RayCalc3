unit unit_ChartManager;

interface

uses
  VCLTee.Chart, VCLTee.Series, VCLTee.TeEngine, VCLTee.TeCanvas,
  unit_Types;

type
  TFastSeriesList = array of TFastLineSeries;

  { Where a curve goes in the draw order: the curve painted last is on top. }
  TDrawOrderMove = (dmToFront, dmForward, dmBackward, dmToBack);

  TChartManager = class
  private
    FChart: TChart;
    FSeriesList: TFastSeriesList;
    FLineWidth: Integer;
    function ChartIndexOf(CurveID: Integer): Integer;
    function IsCurve(CurveID: Integer): Boolean;
  public
    constructor Create(AChart: TChart; ALineWidth: Integer);

    function AddSeries(Data: PProjectData): Integer;
    procedure DeleteSeries(CurveID: Integer);
    procedure ClearAll;

    procedure PlotResults(CurveID: Integer; const Data: TDataArray);
    procedure RescaleAxis(AMin, AMax, AMinLimit: Single);

    procedure ScaleFonts(ABaseSize, ATargetDPI: Integer);

    { Percent, 0 (opaque) .. MAX_CURVE_TRANSPARENCY; out-of-range values are clamped. }
    procedure SetTransparency(CurveID, Percent: Integer);
    function GetTransparency(CurveID: Integer): Integer;

    { The CurveIDs of the live curves in the order they are painted, bottom to top. }
    function DrawOrder: TArray<Integer>;
    procedure MoveSeries(CurveID: Integer; Move: TDrawOrderMove);
    { Paints the listed curves first, in the order given, and every other live
      curve above them in its present order. Unknown, deleted and repeated
      CurveIDs are ignored. }
    procedure ApplyDrawOrder(const CurveIDs: array of Integer);

    property Series: TFastSeriesList read FSeriesList;
    property Chart: TChart read FChart;
    property LineWidth: Integer read FLineWidth write FLineWidth;
  end;

implementation

uses
  Winapi.Windows, System.SysUtils, System.Generics.Collections, unit_CurveStyle;

{ TChartManager }

constructor TChartManager.Create(AChart: TChart; ALineWidth: Integer);
begin
  inherited Create;
  FChart := AChart;
  FLineWidth := ALineWidth;
end;

function TChartManager.AddSeries(Data: PProjectData): Integer;
var
  Index: Integer;
begin
  Index := Length(FSeriesList);
  SetLength(FSeriesList, Index + 1);
  FSeriesList[Index] := TFastLineSeries.Create(FChart);
  FSeriesList[Index].ParentChart := FChart;

  FSeriesList[Index].Title := Data.Title;
  if Data.Color <> 0 then
    FSeriesList[Index].Color := Data.Color
  else
    Data.Color := FSeriesList[Index].Color;

  FSeriesList[Index].LinePen.Width := FLineWidth;
  Data.Visible := True;
  FSeriesList[Index].Visible := Data.Visible;
  Data.CurveID := Index;
  Result := Index;
end;

procedure TChartManager.DeleteSeries(CurveID: Integer);
begin
  FreeAndNil(FSeriesList[CurveID]);
end;

procedure TChartManager.ClearAll;
begin
  while FChart.SeriesCount > 0 do
    FChart.Series[0].Free;
  SetLength(FSeriesList, 0);
end;

procedure TChartManager.PlotResults(CurveID: Integer; const Data: TDataArray);
var
  j, Count: Integer;
  S: TFastLineSeries;
begin
  Count := Length(Data);
  S := FSeriesList[CurveID];
  S.BeginUpdate;
  S.Clear;

  SetLength(S.XValues.Value, Count);
  SetLength(S.YValues.Value, Count);
  for j := 0 to Count - 1 do
  begin
    S.XValues.Value[j] := Data[j].t;
    S.YValues.Value[j] := Data[j].R;
  end;
  S.XValues.Count := Count;
  S.YValues.Count := Count;

  S.EndUpdate;
end;

procedure TChartManager.RescaleAxis(AMin, AMax, AMinLimit: Single);
begin
  FChart.BottomAxis.Minimum := AMin;
  FChart.BottomAxis.Maximum := AMax;
  FChart.LeftAxis.Minimum := AMinLimit;
end;

procedure TChartManager.ScaleFonts(ABaseSize, ATargetDPI: Integer);
var
  I: Integer;
  ScaledBaseSize: Integer;
  ScaledLargeSize: Integer;
begin
  ScaledBaseSize := MulDiv(ABaseSize, ATargetDPI, 96);
  ScaledLargeSize := Round(ScaledBaseSize * 1.2);

  FChart.DefaultFont.Size := ScaledBaseSize;

  FChart.Title.Font.Size := ScaledLargeSize;
  FChart.SubTitle.Font.Size := ScaledLargeSize;
  FChart.Foot.Font.Size := ScaledLargeSize;
  FChart.SubFoot.Font.Size := ScaledLargeSize;

  for I := 0 to FChart.Axes.Count - 1 do
  begin
    FChart.Axes[I].LabelsFont.Size := ScaledBaseSize;
    FChart.Axes[I].Title.Font.Size := ScaledLargeSize;
  end;

  for I := 0 to FChart.SeriesCount - 1 do
    FChart.Series[I].Marks.Font.Size := ScaledBaseSize;
end;

function TChartManager.IsCurve(CurveID: Integer): Boolean;
begin
  Result := (CurveID >= 0) and (CurveID < Length(FSeriesList)) and
            Assigned(FSeriesList[CurveID]);
end;

function TChartManager.ChartIndexOf(CurveID: Integer): Integer;
var
  i: Integer;
begin
  for i := 0 to FChart.SeriesCount - 1 do
    if FChart.Series[i] = FSeriesList[CurveID] then
      Exit(i);
  Result := -1;
end;

procedure TChartManager.SetTransparency(CurveID, Percent: Integer);
begin
  if IsCurve(CurveID) then
    FSeriesList[CurveID].Transparency := ClampTransparency(Percent);
end;

function TChartManager.GetTransparency(CurveID: Integer): Integer;
begin
  if IsCurve(CurveID) then
    Result := FSeriesList[CurveID].Transparency
  else
    Result := 0;
end;

function TChartManager.DrawOrder: TArray<Integer>;
var
  i, CurveID: Integer;
begin
  Result := nil;
  for i := 0 to FChart.SeriesCount - 1 do
    for CurveID := 0 to High(FSeriesList) do
      if Assigned(FSeriesList[CurveID]) and (FChart.Series[i] = FSeriesList[CurveID]) then
      begin
        Result := Result + [CurveID];
        Break;
      end;
end;

procedure TChartManager.MoveSeries(CurveID: Integer; Move: TDrawOrderMove);
var
  Order: TArray<Integer>;
  From, Target: Integer;
begin
  Order := DrawOrder;
  From := TArray.IndexOf<Integer>(Order, CurveID);
  if From < 0 then
    Exit;

  case Move of
    dmToFront : Target := High(Order);
    dmForward : Target := From + 1;
    dmBackward: Target := From - 1;
  else
    Target := 0;
  end;
  if (Target < 0) or (Target > High(Order)) or (Target = From) then
    Exit;

  Delete(Order, From, 1);
  Insert(CurveID, Order, Target);
  ApplyDrawOrder(Order);
end;

procedure TChartManager.ApplyDrawOrder(const CurveIDs: array of Integer);
var
  Current, Wanted, Slots: TArray<Integer>;
  CurveID, i, j: Integer;
begin
  Current := DrawOrder;
  Wanted := nil;
  for CurveID in CurveIDs do
    if TArray.Contains<Integer>(Current, CurveID) and
       not TArray.Contains<Integer>(Wanted, CurveID) then
      Wanted := Wanted + [CurveID];
  for CurveID in Current do
    if not TArray.Contains<Integer>(Wanted, CurveID) then
      Wanted := Wanted + [CurveID];

  { The chart positions the curves hold now, ascending. Filling them in turn
    only ever swaps two curves, so a series the manager does not own keeps
    its place. }
  SetLength(Slots, Length(Current));
  for i := 0 to High(Current) do
    Slots[i] := ChartIndexOf(Current[i]);

  for i := 0 to High(Wanted) do
  begin
    j := ChartIndexOf(Wanted[i]);
    if j <> Slots[i] then
      FChart.ExchangeSeries(Slots[i], j);
  end;
end;

end.
