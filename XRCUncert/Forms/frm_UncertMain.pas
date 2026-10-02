(* *****************************************************************************
  *
  *   X-Ray Calc 3 - the uncertainty tool
  *
  *   Copyright (C) 2026 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  *   This file is part of X-Ray Calc 3, released under the MIT License:
  *   see LICENSE in the repository root.
  *
  ****************************************************************************** *)

unit frm_UncertMain;

(* The uncertainty tool's window. It holds one TUncertSession and draws it:
   what is shown and what is stored is decided in unit_UncertSession and
   unit_UncertView, the run is unit_UncertThread. *)

interface

uses
  Winapi.Windows, Winapi.Messages, Winapi.ShellAPI, Winapi.CommCtrl,
  System.SysUtils, System.Classes, System.UITypes, System.IOUtils,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ExtCtrls,
  Vcl.ComCtrls, Vcl.Clipbrd,
  RzPanel, RzListVw, RzCommon,
  VCLTee.TeEngine, VCLTee.TeeProcs, VCLTee.Chart, VCLTee.Series, VCLTee.TeeGDIPlus,
  unit_UncertRequest, unit_UncertRun, unit_UncertView, unit_UncertSession, unit_UncertThread;

const
  WM_EDITCELL = WM_USER + 1;      // WParam the row, LParam the column: open the cell editor there

type
  TfrmUncertMain = class(TForm)
    pnlTop: TRzPanel;
    btnOpen: TButton;
    btnRun: TButton;
    btnStop: TButton;
    lblModel: TLabel;
    lblProgress: TLabel;
    pnlBottom: TRzPanel;
    memWarnings: TMemo;
    pnlButtons: TRzPanel;
    btnDetails: TButton;
    btnCopy: TButton;
    btnExport: TButton;
    btnHelp: TButton;
    lblDigits: TLabel;
    cbDigits: TComboBox;
    lvParams: TRzListView;
    edCell: TEdit;
    splMain: TSplitter;
    pcCharts: TPageControl;
    tsCurve: TTabSheet;
    tsDepth: TTabSheet;
    chCurve: TChart;
    serMeasured: TPointSeries;
    serLow: TLineSeries;
    serHigh: TLineSeries;
    serMedian: TLineSeries;
    cbDepth: TComboBox;
    chDepth: TChart;
    serDepthLow: TLineSeries;
    serDepthHigh: TLineSeries;
    serDepthMedian: TLineSeries;
    dlgOpen: TOpenDialog;
    dlgExport: TSaveDialog;
    procedure FormCreate(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCloseQuery(Sender: TObject; var CanClose: Boolean);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure btnOpenClick(Sender: TObject);
    procedure btnRunClick(Sender: TObject);
    procedure btnStopClick(Sender: TObject);
    procedure btnDetailsClick(Sender: TObject);
    procedure btnCopyClick(Sender: TObject);
    procedure btnExportClick(Sender: TObject);
    procedure btnHelpClick(Sender: TObject);
    procedure cbDepthChange(Sender: TObject);
    procedure cbDigitsChange(Sender: TObject);
    procedure lvParamsClick(Sender: TObject);
    procedure edCellExit(Sender: TObject);
    procedure edCellKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure edCellKeyPress(Sender: TObject; var Key: Char);
  private
    FSession: TUncertSession;
    FOpen: Boolean;                 // a project is open
    FThread: TUncertThread;         // nil: no run is going
    FSerial: Integer;               // of the current run; a queued call of an older one does nothing
    FNote: string;                  // how the last run ended, when it left no result
    FRows: TArray<TUncertRow>;
    FDepth: TArray<TDepthSeries>;
    FEditRow, FEditColumn: Integer;
    FLastEdit: TCellEdit;           // what the last CommitCell came to
    FRefusedAt: Cardinal;           // tick of the last refusal message
    FStopping: Boolean;             // Stop was pressed on the current run
    procedure WMDropFiles(var Msg: TWMDropFiles); message WM_DROPFILES;
    procedure WMEditCell(var Msg: TMessage); message WM_EDITCELL;
    function Running: Boolean;
    procedure ShowSession;
    procedure FillList;
    procedure DrawCurve;
    procedure DrawDepth;
    procedure RunEnded;
    procedure StopAndWait;
    procedure EditCell(Row, Column: Integer);
    function CommitCell: Boolean;
  public
    /// <summary>Opens FileName in place of the project shown; says why in a
    /// message and keeps the project it had when it cannot.</summary>
    procedure OpenProject(const FileName: string);
  end;

var
  frmUncertMain: TfrmUncertMain;

implementation

{$R *.dfm}

uses
  frm_UncertDetails;

const
  RUN_SEED = 20261002;            // fixed: the same project gives the same result
  HELP_PAGE = 'Help\XRCUncert\index.html';

procedure TfrmUncertMain.FormCreate(Sender: TObject);
begin
  edCell.Parent := lvParams;
  serMeasured.Pointer.Style := psCircle;
  serMeasured.Pointer.HorizSize := 2;
  serMeasured.Pointer.VertSize := 2;
  serMeasured.Pointer.Pen.Visible := False;
  serDepthMedian.Pointer.Style := psCircle;
  serDepthMedian.Pointer.HorizSize := 2;
  serDepthMedian.Pointer.VertSize := 2;
  DragAcceptFiles(Handle, True);
  ShowSession;
  if ParamCount >= 1 then
    OpenProject(ParamStr(1));
end;

procedure TfrmUncertMain.FormDestroy(Sender: TObject);
begin
  StopAndWait;
end;

procedure TfrmUncertMain.FormCloseQuery(Sender: TObject; var CanClose: Boolean);
begin
  CanClose := not Running or
    (MessageDlg('A run is in progress. Stop it and close?', mtConfirmation, [mbYes, mbNo], 0) = mrYes);
  if CanClose then
    StopAndWait;
end;

procedure TfrmUncertMain.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_F1 then
    btnHelpClick(Sender);
end;

procedure TfrmUncertMain.WMDropFiles(var Msg: TWMDropFiles);
var
  Name: string;
  Len: Cardinal;
begin
  try
    Len := DragQueryFile(Msg.Drop, 0, nil, 0);       // its length: a path can be longer than MAX_PATH
    if Len > 0 then
    begin
      SetLength(Name, Len);
      DragQueryFile(Msg.Drop, 0, PChar(Name), Len + 1);
      OpenProject(Name);
    end;
  finally
    DragFinish(Msg.Drop);
  end;
end;

function TfrmUncertMain.Running: Boolean;
begin
  Result := FThread <> nil;
end;

procedure TfrmUncertMain.btnOpenClick(Sender: TObject);
begin
  if dlgOpen.Execute then
    OpenProject(dlgOpen.FileName);
end;

procedure TfrmUncertMain.OpenProject(const FileName: string);
var
  S: TUncertSession;
  Why: string;
begin
  { Read first: a file that is not a project costs the window nothing, not
    even a run in progress. }
  Why := OpenSession(FileName, S);
  if Why <> '' then
  begin
    MessageDlg(Why, mtWarning, [mbOK], 0);
    Exit;
  end;
  if Running then
  begin
    if MessageDlg('A run is in progress. Stop it and open the other project?', mtConfirmation,
      [mbYes, mbNo], 0) <> mrYes then
      Exit;
    StopAndWait;
  end;
  edCell.Visible := False;
  FSession := S;
  FOpen := True;
  FNote := '';
  ShowSession;
end;

procedure TfrmUncertMain.ShowSession;
var
  W: string;
begin
  if FOpen then
  begin
    Caption := 'XRCUncert - ' + ExtractFileName(FSession.FileName);
    lblModel.Caption := Format('Model: %s      Curve: %s',
      [FSession.Project.ModelTitle, FSession.Project.DataTitle]);
    FRows := RowsOf(FSession.Request.Names, FSession.Result, FSession.HasResult, FSession.Priors,
      cbDigits.ItemIndex + 1);
    FDepth := DepthSeriesOf(FSession.Request.Names, FSession.Result, FSession.HasResult);
  end
  else
  begin
    Caption := 'XRCUncert';
    lblModel.Caption := 'Open a fitted project, or drop it here.';
    FRows := nil;
    FDepth := nil;
  end;
  FillList;

  memWarnings.Lines.BeginUpdate;
  try
    memWarnings.Lines.Clear;
    if FNote <> '' then
      memWarnings.Lines.Add(FNote);
    if FOpen then
      for W in SessionWarnings(FSession) do
        memWarnings.Lines.Add(W);
  finally
    memWarnings.Lines.EndUpdate;
  end;

  btnRun.Enabled := FOpen and (FSession.Refusal = '') and not Running;
  btnStop.Enabled := Running;
  btnDetails.Enabled := FOpen and FSession.HasResult;
  btnCopy.Enabled := Length(FRows) > 0;
  btnExport.Enabled := Length(FRows) > 0;
  if not Running then
    lblProgress.Caption := '';

  DrawCurve;
  DrawDepth;
end;

procedure TfrmUncertMain.FillList;
var
  k: Integer;
  Group: TListGroup;
  Item: TListItem;
begin
  lvParams.Items.BeginUpdate;
  try
    lvParams.Items.Clear;
    lvParams.Groups.Clear;
    Group := nil;
    for k := 0 to High(FRows) do
    begin
      if (Group = nil) or (Group.Header <> FRows[k].Group) then
      begin
        Group := lvParams.Groups.Add;
        Group.Header := FRows[k].Group;
      end;
      Item := lvParams.Items.Add;
      Item.GroupID := Group.GroupID;
      Item.Caption := FRows[k].Caption;
      Item.SubItems.Add(FRows[k].Value);
      Item.SubItems.Add(FRows[k].Error);
      Item.SubItems.Add(FRows[k].Known);
      Item.SubItems.Add(FRows[k].KnownError);
      Item.SubItems.Add(FRows[k].Note);
    end;
  finally
    lvParams.Items.EndUpdate;
  end;
end;

{ The measured points, and the model's 16-84 % range over them when there is
  a result. The axis is logarithmic: a value of zero or less is left out. }
procedure TfrmUncertMain.DrawCurve;
var
  k: Integer;
  B: TUncertBand;
begin
  serMeasured.Clear;
  serLow.Clear;
  serMedian.Clear;
  serHigh.Clear;
  if not FOpen then
    Exit;
  for k := 0 to High(FSession.Request.Data) do
    if FSession.Request.Data[k].r > 0 then
      serMeasured.AddXY(FSession.Request.Data[k].t, FSession.Request.Data[k].r);
  if not FSession.HasResult then
    Exit;
  B := FSession.Result.Band;
  if (Length(B.P16) <> Length(B.Theta)) or (Length(B.P50) <> Length(B.Theta)) or
     (Length(B.P84) <> Length(B.Theta)) then
    Exit;
  for k := 0 to High(B.Theta) do
    if (B.P16[k] > 0) and (B.P50[k] > 0) and (B.P84[k] > 0) then
    begin
      serLow.AddXY(B.Theta[k], B.P16[k]);
      serMedian.AddXY(B.Theta[k], B.P50[k]);
      serHigh.AddXY(B.Theta[k], B.P84[k]);
    end;
end;

procedure TfrmUncertMain.DrawDepth;
var
  k, Keep: Integer;
begin
  tsDepth.TabVisible := Length(FDepth) > 0;
  Keep := cbDepth.ItemIndex;
  cbDepth.Items.BeginUpdate;
  try
    cbDepth.Items.Clear;
    for k := 0 to High(FDepth) do
      cbDepth.Items.Add(FDepth[k].Caption);
  finally
    cbDepth.Items.EndUpdate;
  end;
  if (Keep < 0) or (Keep > High(FDepth)) then
    Keep := 0;
  if Length(FDepth) > 0 then
    cbDepth.ItemIndex := Keep;
  cbDepthChange(nil);       // setting ItemIndex in code does not fire OnChange
end;

{ The table again with the digits chosen; a cell being edited is given up. }
procedure TfrmUncertMain.cbDigitsChange(Sender: TObject);
begin
  edCell.Visible := False;
  ShowSession;
end;

procedure TfrmUncertMain.cbDepthChange(Sender: TObject);
var
  k: Integer;
  D: TDepthSeries;
begin
  serDepthLow.Clear;
  serDepthMedian.Clear;
  serDepthHigh.Clear;
  if (cbDepth.ItemIndex < 0) or (cbDepth.ItemIndex > High(FDepth)) then
    Exit;
  D := FDepth[cbDepth.ItemIndex];
  chDepth.LeftAxis.Title.Caption := D.Caption;
  if Length(D.P50) <> Length(D.Period) then
    Exit;
  for k := 0 to High(D.Period) do
  begin
    serDepthLow.AddXY(D.Period[k], D.P16[k]);
    serDepthMedian.AddXY(D.Period[k], D.P50[k]);
    serDepthHigh.AddXY(D.Period[k], D.P84[k]);
  end;
end;

procedure TfrmUncertMain.btnRunClick(Sender: TObject);
var
  Serial: Integer;
begin
  if Running or not FOpen or (FSession.Refusal <> '') then
    Exit;
  edCell.Visible := False;
  Inc(FSerial);
  Serial := FSerial;
  FStopping := False;
  FNote := '';
  { Both callbacks arrive on the worker thread. What they queue belongs to
    that thread, so freeing it takes the calls not yet made with it. }
  FThread := TUncertThread.Create(FSession.Request, FSession.Priors, FSession.Counts, True,
    RUN_SEED, TUncertRecipe.Standard,
    procedure(Step, Total: Integer; SecondsLeft: Double)
    var
      Text: string;
    begin
      Text := TimeLeftText(SecondsLeft);
      { a longer total is the second attempt: say so, or the time left
        jumps from seconds to minutes with no reason given }
      if Total > TUncertRecipe.Standard.Settle + TUncertRecipe.Standard.Steps then
        Text := 'Not settled yet, running once more, longer: ' + Text;
      TThread.Queue(TThread.CurrentThread,
        procedure
        begin
          if (Serial = FSerial) and not FStopping then
            lblProgress.Caption := Text;
        end);
    end,
    procedure
    begin
      TThread.Queue(TThread.CurrentThread,
        procedure
        begin
          if Serial = FSerial then
            RunEnded;
        end);
    end);
  ShowSession;
  lblProgress.Caption := 'Starting...';
end;

procedure TfrmUncertMain.btnStopClick(Sender: TObject);
begin
  if not Running then
    Exit;
  FThread.Stop;
  FStopping := True;              // a progress report still on its way must not overwrite the line
  btnStop.Enabled := False;
  lblProgress.Caption := 'Stopping...';
end;

procedure TfrmUncertMain.RunEnded;
var
  T: TUncertThread;
  Res: TUncertResult;
  Why: string;
begin
  T := FThread;
  if T = nil then
    Exit;
  FThread := nil;
  Inc(FSerial);                   // nothing queued by this run is wanted any more
  try
    T.WaitFor;
    Res := T.Result;
    Why := T.Failure;
  finally
    T.Free;
  end;

  if Why <> '' then
    FNote := 'The run failed: ' + Why
  else if Res.Stopped then
    FNote := 'The run was stopped: nothing was changed.'
  else if not Res.Settled then
  begin
    FNote := Res.Message;
    if FNote = '' then
      FNote := MSG_NOT_SETTLED;
  end
  else
  begin
    Why := StoreResult(FSession, Res);
    if Why <> '' then
      FNote := 'The result is shown here only. ' + Why;
  end;
  ShowSession;
end;

procedure TfrmUncertMain.StopAndWait;
var
  T: TUncertThread;
begin
  T := FThread;
  if T = nil then
    Exit;
  FThread := nil;
  Inc(FSerial);
  T.Stop;
  T.WaitFor;
  T.Free;
  FNote := 'The run was stopped: nothing was changed.';
end;

{ ---------------------------------------------------------- known values -- }

{ What an edit means is decided by unit_UncertView.DecideCellEdit; here it is
  only carried out. The editor is opened through a posted message, after the
  click and its focus changes are over (as frm_Limits does). }

procedure TfrmUncertMain.lvParamsClick(Sender: TObject);
var
  Info: TLVHitTestInfo;
  Hit: Boolean;
begin
  { The click that dismissed a refusal's message box is not a click on a cell. }
  if GetTickCount - FRefusedAt < 300 then
    Exit;
  ZeroMemory(@Info, SizeOf(Info));
  Info.pt := lvParams.ScreenToClient(Mouse.CursorPos);
  Hit := (lvParams.Perform(LVM_SUBITEMHITTEST, 0, LPARAM(@Info)) <> -1) and
    (Info.iItem >= 0) and (Info.iItem <= High(FRows)) and FRows[Info.iItem].CanHavePrior and
    (Info.iSubItem in [COL_KNOWN, COL_KNOWN_ERROR, COL_NOTE]);
  if edCell.Visible and Hit and (Info.iItem = FEditRow) and (Info.iSubItem = FEditColumn) then
  begin
    edCell.SetFocus;
    Exit;
  end;
  if CommitCell and Hit and not Running then
    PostMessage(Handle, WM_EDITCELL, Info.iItem, Info.iSubItem);
end;

procedure TfrmUncertMain.WMEditCell(var Msg: TMessage);
begin
  if not Running and (Msg.WParam <= WPARAM(High(FRows))) and (Length(FRows) > 0) and
     FRows[Msg.WParam].CanHavePrior then
    EditCell(Msg.WParam, Msg.LParam);
end;

procedure TfrmUncertMain.EditCell(Row, Column: Integer);
var
  R: TRect;
begin
  if not ListView_GetSubItemRect(lvParams.Handle, Row, Column, LVIR_LABEL, @R) then
    Exit;
  FEditRow := Row;
  FEditColumn := Column;
  edCell.BoundsRect := R;
  edCell.Text := lvParams.Items[Row].SubItems[Column - 1];
  edCell.Visible := True;
  edCell.SetFocus;
  edCell.SelectAll;
end;

procedure TfrmUncertMain.edCellExit(Sender: TObject);
begin
  CommitCell;
end;

procedure TfrmUncertMain.edCellKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_RETURN then
  begin
    Key := 0;
    { Enter on a known value that still has no +-: on to its +- cell }
    if CommitCell and (FLastEdit = cePending) and (FEditColumn = COL_KNOWN) then
      PostMessage(Handle, WM_EDITCELL, FEditRow, COL_KNOWN_ERROR);
  end
  else if Key = VK_ESCAPE then
  begin
    Key := 0;
    edCell.Visible := False;
    ShowSession;                  // and what was typed but not stored goes with it
  end;
end;

procedure TfrmUncertMain.edCellKeyPress(Sender: TObject; var Key: Char);
begin
  if CharInSet(Key, [#13, #27]) then
    Key := #0;                    // handled in KeyDown; no beep
end;

{ False when the edit was refused (a message has been shown). }
function TfrmUncertMain.CommitCell: Boolean;
var
  NewRow: TUncertRow;
  Prior, Old: TUncertPrior;
  Why: string;
  k: Integer;
  Stored: Boolean;
begin
  Result := True;
  FLastEdit := ceNothing;
  if not edCell.Visible then
    Exit;
  edCell.Visible := False;        // first: a message below takes the focus and would come back here
  if (FEditRow < 0) or (FEditRow > High(FRows)) then
    Exit;
  Stored := False;
  for Old in FSession.Priors do
    if Old.Name = FRows[FEditRow].Name then
      Stored := True;

  FLastEdit := DecideCellEdit(FRows[FEditRow], Stored, FEditColumn, edCell.Text, NewRow, Prior, Why);
  case FLastEdit of
    ceNothing, cePending:
      begin
        { shown, not stored: a known value waits for its +- }
        FRows[FEditRow] := NewRow;
        k := FEditRow;
        lvParams.Items[k].SubItems[COL_KNOWN - 1] := NewRow.Known;
        lvParams.Items[k].SubItems[COL_KNOWN_ERROR - 1] := NewRow.KnownError;
        lvParams.Items[k].SubItems[COL_NOTE - 1] := NewRow.Note;
        Exit;
      end;
    ceStore:
      Why := StorePriors(FSession, WithPrior(FSession.Priors, Prior, False));
    ceRemove:
      Why := StorePriors(FSession, WithPrior(FSession.Priors, Prior, True));
  end;
  if Why <> '' then
  begin
    MessageDlg(Why, mtWarning, [mbOK], 0);
    FRefusedAt := GetTickCount;
    Result := False;
  end;
  ShowSession;
end;

{ -------------------------------------------- details, copy, export, help -- }

procedure TfrmUncertMain.btnDetailsClick(Sender: TObject);
begin
  TfrmUncertDetails.ShowText(Self, DetailsText(FSession.Request.Names, FSession.Result));
end;

procedure TfrmUncertMain.btnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := TableText(FRows);
end;

procedure TfrmUncertMain.btnExportClick(Sender: TObject);
begin
  dlgExport.FileName := ChangeFileExt(ExtractFileName(FSession.FileName), '') + '_uncertainties.csv';
  if not dlgExport.Execute then
    Exit;
  try
    TFile.WriteAllText(dlgExport.FileName, TableCSV(FRows), TEncoding.UTF8);
  except
    on E: Exception do
      MessageDlg('The table could not be written: ' + E.Message, mtWarning, [mbOK], 0);
  end;
end;

procedure TfrmUncertMain.btnHelpClick(Sender: TObject);
var
  Page: string;
begin
  Page := ExtractFilePath(ParamStr(0)) + HELP_PAGE;
  if FileExists(Page) then
    ShellExecute(Handle, 'open', PChar(Page), nil, nil, SW_SHOWNORMAL)
  else
    MessageDlg('The help page was not found: ' + Page, mtInformation, [mbOK], 0);
end;

end.
