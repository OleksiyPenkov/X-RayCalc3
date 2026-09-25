unit TestChartManager;

(* TChartManager: a curve's transparency, and the draw order of the curves on
   the main chart - which one is painted on top. The chart is drawn off screen
   through the GDI+ canvas the main chart uses, so the blend test sees what the
   window would show. *)

interface

uses
  DUnitX.TestFramework, System.SysUtils, System.Types, Winapi.Windows,
  Vcl.Graphics, VCLTee.Chart, VCLTee.TeeGDIPlus,
  unit_Types, unit_CurveStyle, unit_ChartManager;

type
  [TestFixture]
  TTestChartManager = class
  private
    FChart: TChart;
    FMgr: TChartManager;
    FData: array of TProjectData;
    function Add(AColor: TColor): Integer;
    function OrderText: string;
    function CentrePixel: TColor;
  public
    [Setup] procedure Setup;
    [TearDown] procedure TearDown;

    [Test] procedure Transparency_BlendsTheCurveWithTheOneBelow;
    [Test] procedure Transparency_Zero_DrawsTheCurveOpaque;
    [Test] procedure Transparency_IsClampedToTheMaximum;
    [Test] procedure Transparency_OfANewCurve_IsZero;

    [Test] procedure DrawOrder_IsCreationOrder;
    [Test] procedure DrawOrder_SkipsDeletedCurves;
    [Test] procedure Move_ToFront_PaintsTheCurveLast;
    [Test] procedure Move_ToBack_PaintsTheCurveFirst;
    [Test] procedure Move_Forward_SwapsWithTheNextOne;
    [Test] procedure Move_Backward_SwapsWithThePreviousOne;
    [Test] procedure Move_PastEitherEnd_ChangesNothing;
    [Test] procedure Move_ToFront_PutsTheCurveOnTopOfTheImage;
    [Test] procedure Apply_ListedCurvesFirst_UnlistedOnTop;
    [Test] procedure Apply_IgnoresUnknownDeletedAndRepeatedIDs;
  end;

implementation

const
  W = 200;
  H = 100;

procedure TTestChartManager.Setup;
begin
  FChart := TChart.Create(nil);
  FChart.Width := W;
  FChart.Height := H;
  FChart.Canvas := TGDIPlusCanvas.Create;
  FChart.View3D := False;
  FChart.Legend.Visible := False;
  FChart.AxisVisible := False;
  FChart.Color := clWhite;
  FChart.Gradient.Visible := False;
  FChart.BackWall.Visible := False;
  FChart.BottomAxis.SetMinMax(0, 1);
  FChart.LeftAxis.SetMinMax(0, 1);
  FMgr := TChartManager.Create(FChart, 8);
  SetLength(FData, 0);
end;

procedure TTestChartManager.TearDown;
begin
  FMgr.Free;
  FChart.Free;
end;

function TTestChartManager.Add(AColor: TColor): Integer;
var
  i: Integer;
  Line: TDataArray;
begin
  { AddSeries keeps the pointer only for the call, so a growing array is safe. }
  i := Length(FData);
  SetLength(FData, i + 1);
  FData[i].Title := 'curve ' + IntToStr(i);
  FData[i].RowType := prItem;
  FData[i].Color := AColor;
  Result := FMgr.AddSeries(@FData[i]);

  SetLength(Line, 2);
  Line[0].t := 0;
  Line[0].r := 0.5;
  Line[1].t := 1;
  Line[1].r := 0.5;
  FMgr.PlotResults(Result, Line);
end;

function TTestChartManager.OrderText: string;
var
  ID: Integer;
begin
  Result := '';
  for ID in FMgr.DrawOrder do
  begin
    if Result <> '' then
      Result := Result + ',';
    Result := Result + IntToStr(ID);
  end;
end;

function TTestChartManager.CentrePixel: TColor;
var
  Bmp: TBitmap;
  X, Y: Integer;
begin
  Bmp := FChart.TeeCreateBitmap(clWhite, Rect(0, 0, W, H));
  try
    X := FChart.BottomAxis.CalcXPosValue(0.5);
    Y := FChart.LeftAxis.CalcYPosValue(0.5);
    Result := Bmp.Canvas.Pixels[X, Y];
  finally
    Bmp.Free;
  end;
end;

procedure TTestChartManager.Transparency_BlendsTheCurveWithTheOneBelow;
var
  Blue: Integer;
  P: TColor;
begin
  Add(clRed);
  Blue := Add(clBlue);
  FMgr.SetTransparency(Blue, 50);

  P := CentrePixel;
  Assert.IsTrue(GetRValue(P) in [60..200], Format('red shows through: $%.6x', [P]));
  Assert.IsTrue(GetBValue(P) in [60..200], Format('blue is half strength: $%.6x', [P]));
end;

procedure TTestChartManager.Transparency_Zero_DrawsTheCurveOpaque;
var
  P: TColor;
begin
  Add(clRed);
  Add(clBlue);

  P := CentrePixel;
  Assert.AreEqual(0, Integer(GetRValue(P)), Format('no red under an opaque line: $%.6x', [P]));
  Assert.AreEqual(255, Integer(GetBValue(P)), Format('full blue: $%.6x', [P]));
end;

procedure TTestChartManager.Transparency_IsClampedToTheMaximum;
var
  C: Integer;
begin
  C := Add(clBlue);
  FMgr.SetTransparency(C, 150);
  Assert.AreEqual(MAX_CURVE_TRANSPARENCY, FMgr.GetTransparency(C), 'above the maximum');
  FMgr.SetTransparency(C, -10);
  Assert.AreEqual(0, FMgr.GetTransparency(C), 'below zero');
end;

procedure TTestChartManager.Transparency_OfANewCurve_IsZero;
begin
  Assert.AreEqual(0, FMgr.GetTransparency(Add(clBlue)));
end;

procedure TTestChartManager.DrawOrder_IsCreationOrder;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  Assert.AreEqual('0,1,2', OrderText);
end;

procedure TTestChartManager.DrawOrder_SkipsDeletedCurves;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.DeleteSeries(1);
  Assert.AreEqual('0,2', OrderText);
end;

procedure TTestChartManager.Move_ToFront_PaintsTheCurveLast;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.MoveSeries(0, dmToFront);
  Assert.AreEqual('1,2,0', OrderText);
end;

procedure TTestChartManager.Move_ToBack_PaintsTheCurveFirst;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.MoveSeries(2, dmToBack);
  Assert.AreEqual('2,0,1', OrderText);
end;

procedure TTestChartManager.Move_Forward_SwapsWithTheNextOne;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.MoveSeries(0, dmForward);
  Assert.AreEqual('1,0,2', OrderText);
end;

procedure TTestChartManager.Move_Backward_SwapsWithThePreviousOne;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.MoveSeries(2, dmBackward);
  Assert.AreEqual('0,2,1', OrderText);
end;

procedure TTestChartManager.Move_PastEitherEnd_ChangesNothing;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.MoveSeries(2, dmForward);
  FMgr.MoveSeries(2, dmToFront);
  FMgr.MoveSeries(0, dmBackward);
  FMgr.MoveSeries(0, dmToBack);
  Assert.AreEqual('0,1,2', OrderText);
end;

procedure TTestChartManager.Move_ToFront_PutsTheCurveOnTopOfTheImage;
var
  Red: Integer;
  P: TColor;
begin
  Red := Add(clRed);
  Add(clBlue);
  FMgr.MoveSeries(Red, dmToFront);

  P := CentrePixel;
  Assert.AreEqual(255, Integer(GetRValue(P)), Format('red on top: $%.6x', [P]));
  Assert.AreEqual(0, Integer(GetBValue(P)), Format('blue hidden: $%.6x', [P]));
end;

procedure TTestChartManager.Apply_ListedCurvesFirst_UnlistedOnTop;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  Add(clYellow);
  FMgr.ApplyDrawOrder([3, 1]);
  Assert.AreEqual('3,1,0,2', OrderText);
end;

procedure TTestChartManager.Apply_IgnoresUnknownDeletedAndRepeatedIDs;
begin
  Add(clRed);
  Add(clGreen);
  Add(clBlue);
  FMgr.DeleteSeries(0);
  FMgr.ApplyDrawOrder([7, 2, -1, 0, 2, 1]);
  Assert.AreEqual('2,1', OrderText);
end;

initialization
  TDUnitX.RegisterTestFixture(TTestChartManager);

end.
