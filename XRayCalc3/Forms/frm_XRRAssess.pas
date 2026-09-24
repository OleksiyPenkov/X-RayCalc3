(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_XRRAssess;

(* Data - Assess XRR quality: is this measured curve worth fitting?

   The eight checks of unit_MCPAssess (the same ones the MCP server's
   assess_xrr runs) on the active measured curve, one row per check with its
   verdict, value, threshold and the sentence that explains it, and the text
   block underneath ready to paste into the specimen's record. The window
   holds the instrument numbers nobody records in a file - the detector's
   linear limit, the specimen length, the beam width - and re-runs the checks
   with them when Assess is pressed; a number left empty leaves its check "unknown", which is
   what the engine says rather than inventing a threshold. *)

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Classes, System.JSON,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, RzPanel, RzButton, RzListVw,
  unit_MCPAssess;

type
  TfrmXRRAssess = class(TForm)
    pnlTop: TRzPanel;
    lblSource: TLabel;
    lblDetector: TLabel;
    edDetector: TEdit;
    lblSample: TLabel;
    edSample: TEdit;
    lblBeam: TLabel;
    edBeam: TEdit;
    lblResolution: TLabel;
    edResolution: TEdit;
    lblVisible: TLabel;
    edVisible: TEdit;
    lblMinPoints: TLabel;
    edMinPoints: TEdit;
    chkStructure: TCheckBox;
    btnAssess: TRzBitBtn;
    lvChecks: TRzListView;
    pnlBottom: TRzPanel;
    mmSummary: TMemo;
    pnlButtons: TRzPanel;
    btnCopy: TRzBitBtn;
    btnClose: TRzBitBtn;
    procedure btnAssessClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure lvChecksCustomDrawItem(Sender: TCustomListView; Item: TListItem;
      State: TCustomDrawState; var DefaultDraw: Boolean);
  private
    FInput: TAssessInput;
    FSummary: string;
    function EditValue(Edit: TEdit; const Default: Double): Double;
    procedure RunAssessment;
    procedure ShowResult(Res: TJSONObject);
  public
    /// <summary>Shows the window for one curve. Inp carries the curve, the
    /// wavelength, the raw facts when there are any and the current structure;
    /// Source is the line that says where the curve came from.</summary>
    procedure Assess(const Inp: TAssessInput; const Source: string);
  end;

var
  frmXRRAssess: TfrmXRRAssess;

implementation

uses
  Vcl.Clipbrd, System.Math;

{$R *.dfm}

{ ------------------------------------------------------------- helpers -- }

/// A cell's text for a JSON value: '-' for null, the number as JSON writes it.
function CellText(V: TJSONValue): string;
begin
  if (V = nil) or (V is TJSONNull) then
    Result := '-'
  else if V is TJSONNumber then
    Result := TJSONNumber(V).Value
  else
    Result := V.Value;
end;

function TfrmXRRAssess.EditValue(Edit: TEdit; const Default: Double): Double;
var
  S: string;
begin
  S := Trim(Edit.Text);
  if S = '' then
    Exit(Default);
  { the system locale first (what the rest of the window uses), then the
    invariant one, so that both "0,015" and "0.015" are read }
  if not TryStrToFloat(S, Result) then
    if not TryStrToFloat(S, Result, TFormatSettings.Invariant) then
      Result := Default;
end;

{ ------------------------------------------------------------- running -- }

procedure TfrmXRRAssess.Assess(const Inp: TAssessInput; const Source: string);
begin
  FInput := Inp;
  lblSource.Caption := Source;
  chkStructure.Enabled := Inp.HasStructure;
  if not Inp.HasStructure then
    chkStructure.Checked := False;
  edResolution.Text := FloatToStr(Inp.Resolution);
  RunAssessment;
  ShowModal;
end;

procedure TfrmXRRAssess.RunAssessment;
var
  Inp: TAssessInput;
  Res: TJSONObject;
begin
  Inp := FInput;
  Inp.DetectorMaxCps := Max(0, EditValue(edDetector, 0));
  Inp.SampleLengthMm := Max(0, EditValue(edSample, 0));
  Inp.BeamWidthMm := Max(0, EditValue(edBeam, 0));
  Inp.Resolution := Max(0, EditValue(edResolution, FInput.Resolution));
  Inp.VisibleFactor := EditValue(edVisible, Inp.VisibleFactor);
  Inp.MinPointsPerFringe := EditValue(edMinPoints, Inp.MinPointsPerFringe);
  Inp.HasStructure := FInput.HasStructure and chkStructure.Checked;

  Screen.Cursor := crHourGlass;
  try
    try
      Res := AssessJSON(Inp);
      try
        ShowResult(Res);
      finally
        Res.Free;
      end;
    except
      on E: Exception do
      begin
        lvChecks.Items.Clear;
        FSummary := '';
        mmSummary.Text := 'The assessment could not run: ' + E.Message;
        Caption := 'XRR quality';
      end;
    end;
  finally
    Screen.Cursor := crDefault;
  end;
end;

procedure TfrmXRRAssess.ShowResult(Res: TJSONObject);
var
  Checks, Check, Design: TJSONObject;
  Pair: TJSONPair;
  Item: TListItem;
  Head: string;
begin
  Checks := Res.GetValue('checks') as TJSONObject;
  lvChecks.Items.BeginUpdate;
  try
    lvChecks.Items.Clear;
    for Pair in Checks do
    begin
      Check := Pair.JsonValue as TJSONObject;
      Item := lvChecks.Items.Add;
      Item.Caption := Pair.JsonString.Value;
      Item.SubItems.Add(Check.GetValue<string>('verdict'));
      Item.SubItems.Add(CellText(Check.GetValue('value')));
      Item.SubItems.Add(CellText(Check.GetValue('threshold')));
      Item.SubItems.Add(Check.GetValue<string>('why'));
    end;
  finally
    lvChecks.Items.EndUpdate;
  end;

  Caption := 'XRR quality: ' + Res.GetValue<string>('verdict');

  { the text block, headed by what it was computed from }
  Head := Format('%d points, theta %s to %s deg; lambda %s A (%s)',
    [Res.GetValue<Integer>('points'),
     CellText((Res.GetValue('theta_range_deg') as TJSONArray).Items[0]),
     CellText((Res.GetValue('theta_range_deg') as TJSONArray).Items[1]),
     CellText(Res.GetValue('lambda')), CellText(Res.GetValue('lambda_source'))]);
  Design := Res.GetValue('design') as TJSONObject;
  if Design <> nil then
    Head := Head + Format('; design: period %s A, total %s A, theta_c %s deg',
      [CellText(Design.GetValue('period_A')), CellText(Design.GetValue('total_thickness_A')),
       CellText(Design.GetValue('theta_c_deg'))])
  else
    Head := Head + '; no design';
  FSummary := Head + sLineBreak + 'verdict: ' + Res.GetValue<string>('verdict') + sLineBreak +
              Res.GetValue<string>('summary_text');
  mmSummary.Text := FSummary;
end;

{ -------------------------------------------------------------- events -- }

procedure TfrmXRRAssess.btnAssessClick(Sender: TObject);
begin
  RunAssessment;
end;

procedure TfrmXRRAssess.btnCopyClick(Sender: TObject);
begin
  if FSummary <> '' then
    Clipboard.AsText := FSummary;
end;

procedure TfrmXRRAssess.lvChecksCustomDrawItem(Sender: TCustomListView;
  Item: TListItem; State: TCustomDrawState; var DefaultDraw: Boolean);
var
  Verdict: string;
begin
  DefaultDraw := True;
  if Item.SubItems.Count = 0 then
    Exit;
  Verdict := Item.SubItems[0];
  Sender.Canvas.Font.Style := [];
  if Verdict = 'fail' then
  begin
    Sender.Canvas.Font.Color := clRed;
    Sender.Canvas.Font.Style := [fsBold];
  end
  else if Verdict = 'warn' then
    Sender.Canvas.Font.Color := $00008CFF        // orange
  else if Verdict = 'pass' then
    Sender.Canvas.Font.Color := clGreen
  else
    Sender.Canvas.Font.Color := clGrayText;
end;

end.
