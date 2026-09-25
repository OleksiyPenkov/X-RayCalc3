(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_FitReport;

(* Result - Fit report: is this fit any good? The numbers fit_xrr's report
   gives, for the active model against the measured curve linked to it - the
   Bragg orders measured against calculated, the critical edge, the fringe
   contrast between orders 1 and 2 and the residual in eight bands of angle -
   plus the fitted parameters that sit within 5 % of a bound. It is to a fit
   what Data - Assess XRR quality is to a measurement.

   Values only: no verdict, no colour. What a good fit looks like is the
   fitting procedure's to say, not the program's. Angles are in the chart's
   unit, 2theta or theta; the measured curve is at the solved scale of the
   last calculation (unit_FitReportGUI). *)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, RzPanel, RzButton, RzListVw,
  unit_Types, unit_MCPFitReport, unit_FitReportGUI;

type
  TfrmFitReport = class(TForm)
    pnlTop: TRzPanel;
    lblSource: TLabel;
    lblFacts: TLabel;
    grpOrders: TRzGroupBox;
    lvOrders: TRzListView;
    pnlMiddle: TRzPanel;
    grpEdge: TRzGroupBox;
    lvEdge: TRzListView;
    grpFringes: TRzGroupBox;
    lvFringes: TRzListView;
    grpBands: TRzGroupBox;
    lvBands: TRzListView;
    grpNear: TRzGroupBox;
    lvNear: TRzListView;
    pnlButtons: TRzPanel;
    btnCopy: TRzBitBtn;
    btnClose: TRzBitBtn;
    procedure btnCopyClick(Sender: TObject);
  private
    FK: Double;               // 2 on a 2theta chart, 1 on a theta chart
    FAngle: string;           // the chart's angle name
    procedure SetAngleCaptions;
    function AngleText(const ThetaDeg: Double): string;
    procedure ShowOrders(Rep: TJSONObject);
    procedure ShowEdge(Rep: TJSONObject);
    procedure ShowFringes(Rep: TJSONObject);
    procedure ShowBands(Rep: TJSONObject);
    procedure ShowNear(const Near: TArray<TNearBound>);
    procedure FitToWorkArea;
  public
    /// <summary>Computes the report on Inp (theta, the solved scale applied)
    /// and shows it. TwoTheta says how the chart shows angles; Source and
    /// Facts are the two header lines.</summary>
    procedure ShowReport(const Inp: TFitReportInput; TwoTheta: Boolean;
      const Near: TArray<TNearBound>; const Source, Facts: string);
  end;

var
  frmFitReport: TfrmFitReport;

implementation

uses
  Vcl.Clipbrd, System.Math;

{$R *.dfm}

const
  THETA = #$03B8;
  DEG = #$00B0;
  PARAM_NAMES: array [1..3] of string = ('H', #$03C3, #$03C1);

{ ------------------------------------------------------------- helpers -- }

function NumOf(V: TJSONValue; out D: Double): Boolean;
begin
  Result := (V <> nil) and (V is TJSONNumber);
  if Result then
    D := TJSONNumber(V).AsDouble
  else
    D := 0;
end;

/// An intensity or a reflectivity: five significant digits.
function RText(V: TJSONValue): string;
var
  D: Double;
begin
  if NumOf(V, D) then
    Result := FloatToStrF(D, ffGeneral, 5, 0)
  else
    Result := '-';
end;

/// A ratio or a residual in decades: three decimals.
function FText(V: TJSONValue): string;
var
  D: Double;
begin
  if NumOf(V, D) then
    Result := FloatToStrF(D, ffFixed, 7, 3)
  else
    Result := '-';
end;

function TfrmFitReport.AngleText(const ThetaDeg: Double): string;
begin
  Result := FloatToStrF(FK * ThetaDeg, ffFixed, 7, 4);
end;

function AngleOf(Obj: TJSONObject; const Name: string; out D: Double): Boolean;
begin
  Result := (Obj <> nil) and NumOf(Obj.GetValue(Name), D);
end;

procedure TfrmFitReport.SetAngleCaptions;
var
  U: string;
begin
  U := ' (' + DEG + ')';
  lvOrders.Columns[1].Caption := FAngle + ' meas' + U;
  lvOrders.Columns[2].Caption := FAngle + ' calc' + U;
  lvEdge.Columns[0].Caption := FAngle + U;
  lvBands.Columns[0].Caption := FAngle + ' from' + U;
  lvBands.Columns[1].Caption := FAngle + ' to' + U;
end;

{ ------------------------------------------------------------ showing -- }

procedure TfrmFitReport.ShowReport(const Inp: TFitReportInput; TwoTheta: Boolean;
  const Near: TArray<TNearBound>; const Source, Facts: string);
var
  Rep: TJSONObject;
begin
  if TwoTheta then
  begin
    FK := 2;
    FAngle := '2' + THETA;
  end
  else
  begin
    FK := 1;
    FAngle := THETA;
  end;
  SetAngleCaptions;
  lblSource.Caption := Source;
  lblFacts.Caption := Facts;

  Rep := FitReportJSON(Inp);
  try
    ShowOrders(Rep);
    ShowEdge(Rep);
    ShowFringes(Rep);
    ShowBands(Rep);
  finally
    Rep.Free;
  end;
  ShowNear(Near);
  FitToWorkArea;
  ShowModal;
end;

{ The form is 800 px tall at 96 dpi and scales with the display; at 200 % and
  more that is taller than the screen, and the bottom blocks - the bands and
  the parameters near a bound - would sit under the taskbar. The Bragg-order
  table is the one that gives way (it scrolls). }
procedure TfrmFitReport.FitToWorkArea;
var
  WA: TRect;
begin
  if Application.MainForm <> nil then
    WA := Screen.MonitorFromWindow(Application.MainForm.Handle).WorkareaRect
  else
    WA := Screen.WorkAreaRect;
  if Height > WA.Height then
    Height := WA.Height;
  if Width > WA.Width then
    Width := WA.Width;
end;

procedure TfrmFitReport.ShowOrders(Rep: TJSONObject);
var
  Orders: TJSONValue;
  O: TJSONObject;
  Item: TListItem;
  i: Integer;
  D: Double;
begin
  lvOrders.Items.BeginUpdate;
  try
    lvOrders.Items.Clear;
    Orders := Rep.GetValue('orders');
    if not (Orders is TJSONArray) then
    begin
      Item := lvOrders.Items.Add;
      Item.Caption := '-';
      Item.SubItems.Add('the model has no repeating stack, so no Bragg orders');
      Exit;
    end;
    for i := 0 to TJSONArray(Orders).Count - 1 do
    begin
      if not (TJSONArray(Orders).Items[i] is TJSONObject) then
        Continue;
      O := TJSONObject(TJSONArray(Orders).Items[i]);
      Item := lvOrders.Items.Add;
      Item.Caption := O.GetValue('n').Value;
      if AngleOf(O, 'theta_meas_deg', D) then
      begin
        Item.SubItems.Add(AngleText(D));
        if AngleOf(O, 'theta_calc_deg', D) then
          Item.SubItems.Add(AngleText(D))
        else
          Item.SubItems.Add('-');
        Item.SubItems.Add(RText(O.GetValue('i_meas')));
        Item.SubItems.Add(RText(O.GetValue('r_calc')));
        Item.SubItems.Add(FText(O.GetValue('ratio')));
        if (O.GetValue('visible') is TJSONBool) and TJSONBool(O.GetValue('visible')).AsBoolean then
          Item.SubItems.Add('yes')
        else
          Item.SubItems.Add('no');
      end
      else
      begin
        { outside the measured range: where the order would be }
        if AngleOf(O, 'theta_bragg_deg', D) then
          Item.SubItems.Add(AngleText(D) + ' *')
        else
          Item.SubItems.Add('-');
        Item.SubItems.Add('-');
        Item.SubItems.Add('-');
        Item.SubItems.Add('-');
        Item.SubItems.Add('-');
        Item.SubItems.Add('no');
      end;
    end;
  finally
    lvOrders.Items.EndUpdate;
  end;
end;

procedure TfrmFitReport.ShowEdge(Rep: TJSONObject);
var
  Edge: TJSONValue;
  Points: TJSONValue;
  P: TJSONObject;
  Item: TListItem;
  i: Integer;
  D: Double;
begin
  lvEdge.Items.BeginUpdate;
  try
    lvEdge.Items.Clear;
    Edge := Rep.GetValue('edge');
    if not (Edge is TJSONObject) then
      Exit;
    Points := TJSONObject(Edge).GetValue('points');
    if not (Points is TJSONArray) then
      Exit;
    for i := 0 to TJSONArray(Points).Count - 1 do
    begin
      if not (TJSONArray(Points).Items[i] is TJSONObject) then
        Continue;
      P := TJSONObject(TJSONArray(Points).Items[i]);
      Item := lvEdge.Items.Add;
      if AngleOf(P, 'theta_deg', D) then
        Item.Caption := AngleText(D)
      else
        Item.Caption := '-';
      Item.SubItems.Add(RText(P.GetValue('i_meas')));
      Item.SubItems.Add(RText(P.GetValue('r_calc')));
      Item.SubItems.Add(FText(P.GetValue('ratio')));
    end;
  finally
    lvEdge.Items.EndUpdate;
  end;
end;

procedure TfrmFitReport.ShowFringes(Rep: TJSONObject);
var
  Fr: TJSONValue;
  F, Side: TJSONObject;
  Between: TJSONValue;
  D: Double;

  procedure Row(const Name, Value: string);
  var
    Item: TListItem;
  begin
    Item := lvFringes.Items.Add;
    Item.Caption := Name;
    Item.SubItems.Add(Value);
  end;

  function MeanOf(const Name: string): string;
  begin
    Result := '-';
    if F.GetValue(Name) is TJSONObject then
    begin
      Side := TJSONObject(F.GetValue(Name));
      if NumOf(Side.GetValue('mean_contrast'), D) then
        Result := FloatToStrF(D, ffFixed, 7, 3);
    end;
  end;

begin
  lvFringes.Items.BeginUpdate;
  try
    lvFringes.Items.Clear;
    Fr := Rep.GetValue('fringes');
    if not (Fr is TJSONObject) then
    begin
      Row('Fringes', 'not found: orders 1 and 2 are needed');
      Exit;
    end;
    F := TJSONObject(Fr);
    Between := F.GetValue('between_deg');
    if (Between is TJSONArray) and (TJSONArray(Between).Count = 2) and
       NumOf(TJSONArray(Between).Items[0], D) then
    begin
      Row('Between, ' + FAngle + ' (' + DEG + ')', AngleText(D) + ' - ' +
        AngleText(TJSONNumber(TJSONArray(Between).Items[1]).AsDouble));
    end;
    Row('Pairs (maximum and next minimum)', F.GetValue('count').Value);
    Row('Mean contrast, measured', MeanOf('measured'));
    Row('Mean contrast, calculated', MeanOf('calculated'));
  finally
    lvFringes.Items.EndUpdate;
  end;
end;

procedure TfrmFitReport.ShowBands(Rep: TJSONObject);
var
  Bands: TJSONValue;
  B: TJSONObject;
  Range: TJSONValue;
  Item: TListItem;
  i: Integer;
  D: Double;
begin
  lvBands.Items.BeginUpdate;
  try
    lvBands.Items.Clear;
    Bands := Rep.GetValue('bands');
    if not (Bands is TJSONArray) then
      Exit;
    for i := 0 to TJSONArray(Bands).Count - 1 do
    begin
      if not (TJSONArray(Bands).Items[i] is TJSONObject) then
        Continue;
      B := TJSONObject(TJSONArray(Bands).Items[i]);
      Item := lvBands.Items.Add;
      Range := B.GetValue('theta_deg');
      if (Range is TJSONArray) and (TJSONArray(Range).Count = 2) and
         NumOf(TJSONArray(Range).Items[0], D) then
      begin
        Item.Caption := AngleText(D);
        Item.SubItems.Add(AngleText(TJSONNumber(TJSONArray(Range).Items[1]).AsDouble));
      end
      else
      begin
        Item.Caption := '-';
        Item.SubItems.Add('-');
      end;
      Item.SubItems.Add(B.GetValue('n').Value);
      Item.SubItems.Add(FText(B.GetValue('mean')));
      Item.SubItems.Add(FText(B.GetValue('rms')));
    end;
  finally
    lvBands.Items.EndUpdate;
  end;
end;

procedure TfrmFitReport.ShowNear(const Near: TArray<TNearBound>);
var
  NB: TNearBound;
  Item: TListItem;
begin
  lvNear.Items.BeginUpdate;
  try
    lvNear.Items.Clear;
    for NB in Near do
    begin
      Item := lvNear.Items.Add;
      Item.Caption := NB.Stack;
      Item.SubItems.Add(NB.Layer);
      Item.SubItems.Add(PARAM_NAMES[NB.Param]);
      Item.SubItems.Add(FloatToStrF(NB.V, ffGeneral, 6, 0));
      Item.SubItems.Add(FloatToStrF(NB.Min, ffGeneral, 6, 0));
      Item.SubItems.Add(FloatToStrF(NB.Max, ffGeneral, 6, 0));
      if NB.AtUpper then
        Item.SubItems.Add('max')
      else
        Item.SubItems.Add('min');
    end;
  finally
    lvNear.Items.EndUpdate;
  end;
end;

{ ---------------------------------------------------------------- copy -- }

procedure TfrmFitReport.btnCopyClick(Sender: TObject);
var
  SB: TStringBuilder;

  procedure AddTable(const Title: string; LV: TRzListView);
  var
    i, c: Integer;
    Line: string;
  begin
    SB.AppendLine(Title);
    Line := '';
    for c := 0 to LV.Columns.Count - 1 do
    begin
      if c > 0 then Line := Line + #9;
      Line := Line + LV.Columns[c].Caption;
    end;
    SB.AppendLine(Line);
    for i := 0 to LV.Items.Count - 1 do
    begin
      Line := LV.Items[i].Caption;
      for c := 0 to LV.Items[i].SubItems.Count - 1 do
        Line := Line + #9 + LV.Items[i].SubItems[c];
      SB.AppendLine(Line);
    end;
    SB.AppendLine;
  end;

begin
  SB := TStringBuilder.Create;
  try
    SB.AppendLine(lblSource.Caption);
    SB.AppendLine(lblFacts.Caption);
    SB.AppendLine;
    AddTable(grpOrders.Caption, lvOrders);
    AddTable(grpEdge.Caption, lvEdge);
    AddTable(grpFringes.Caption, lvFringes);
    AddTable(grpBands.Caption, lvBands);
    AddTable(grpNear.Caption, lvNear);
    Clipboard.AsText := SB.ToString;
  finally
    SB.Free;
  end;
end;

end.
