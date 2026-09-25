(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit unit_CalcOrchestrator;

interface

uses
  System.SysUtils, System.Classes, System.JSON, System.DateUtils, System.Diagnostics,
  Winapi.Messages, Vcl.Forms, Vcl.Dialogs,
  unit_Types, unit_calc, unit_materials, unit_LFPSO_Base, unit_ProfilesManager,
  unit_ChartManager, unit_XRCStructure,
  frame_CalcSettings, frame_ChartInfo, frame_ChartPages, frame_ProjectPanel,
  unit_StaleExtDialog;

type
  TEnableControlsEvent = procedure(const Enable: Boolean) of object;
  TStatusUpdateEvent = procedure(const S: string) of object;

  TCalcOrchestrator = class
  private
    { Owned state - moved from frm_Main }
    FLFPSO: TLFPSO_Base;
    FFitThread: TThread;
    FCalcWatch, FFitWatch: TStopwatch;
    FCalc: TCalc;
    FCalcThreadParams: TCalcThreadParams;
    FFitStructure: TFitStructure;
    FLastChiSquare, FABestChiSquare: Single;
    FBenchmarkMode, FFirstUpdate, FKeepExtensions: Boolean;
    FFitDuration: string;
    FFitSeconds: Double;
    FFitDevice: string;          // what evaluated the last fit: 'CPU' or the GPU's name
    FHasFitResults: Boolean;
    { The last fit as it ran, captured when it starts - the settings may be
      changed while it runs or afterwards - and written into the project's
      fit record (BuildFitRecord) when it ends. }
    FFitMode: TFittingMode;
    FFitSeed: Integer;
    FFitResumed, FFitFromTables: Boolean;
    FFitStarted: TDateTime;
    FFitCalcParams: TCalcThreadParams;
    FFitSettings: TFitParams;
    FFitPWChi: Boolean;
    FFitRMin: Single;
    FFitTwoTheta: Boolean;
    FFitPoly: TProfileFunctions;
    FFitBestChi: Single;
    { The weighted and the plain chi-squared of the last calculation }
    FLastChi, FLastChiPlain: Single;
    { The scale the last chi-squared shown was taken at (RunCalc) }
    FLastSolveScale, FLastScaleClamped: Boolean;
    FLastScaleLog: Single;
    { Which measured curve that scale belongs to: its node ID and project. }
    FLastScaleDataID, FLastScaleProject: Integer;

    { Dependencies - not owned }
    FCalcSettings: TfrmCalcSettings;
    FProjectPanel: TfrmProjectPanel;
    FChartInfo: TfrmChartInfo;
    FChartPages: TfrmChartPages;
    FChartMgr: TChartManager;
    FProfileMgr: TProfileManager;

    { Callbacks }
    FOnEnableControls: TEnableControlsEvent;
    FOnCalcTimeUpdate: TStatusUpdateEvent;
    FOnFitTimeUpdate: TStatusUpdateEvent;
    FOnFitCurve: TNotifyEvent;

    { Internal }
    function PrepareCalc: Boolean;
    procedure GetThreadParams;
    procedure FinalizeCalc(Calc: TCalc);
    function GetFitParams(const Resume: Boolean): Boolean;
    function PrepareLFPSO(const Resume: Boolean): Boolean;
    procedure UpdateInterface(const FitStructure: TFitStructure;
      const Poly: TProfileFunctions; const Res: TLayeredModel;
      const CreateExtension: Boolean = True);
    procedure FinalizeFitting;
    procedure StartFitting(const Resume: Boolean);
    function BuildFitRecord: TJSONObject;
  public
    constructor Create(ACalcSettings: TfrmCalcSettings;
      AProjectPanel: TfrmProjectPanel; AChartInfo: TfrmChartInfo;
      AChartPages: TfrmChartPages; AChartMgr: TChartManager;
      AProfileMgr: TProfileManager);
    destructor Destroy; override;

    procedure RunCalc(const Recover: Boolean);
    procedure RunFitting;
    procedure ResumeFitting;
    procedure ModelChanged;
    procedure StopCalc;
    procedure RecalcFromStructure;
    procedure HandleFitUpdate(var Msg: TMessage);
    procedure HandleFitComplete;
    procedure ExportFitResultsToJSON(const FileName: string);

    property LastChiSquare: Single read FLastChiSquare write FLastChiSquare;
    property BenchmarkMode: Boolean read FBenchmarkMode write FBenchmarkMode;
    property HasFitResults: Boolean read FHasFitResults;
    /// The open project carries a record of a fit (this session's or a saved
    /// one), which Result - Export fit results writes out.
    function HasFitRecord: Boolean;
    /// The scale the last calculation's chi2 was taken at: solved or not,
    /// and log10 of its ratio to the anchored one (0 when anchored).
    property LastSolveScale: Boolean read FLastSolveScale;
    property LastScaleLog: Single read FLastScaleLog;
    property LastScaleDataID: Integer read FLastScaleDataID;
    property LastScaleProject: Integer read FLastScaleProject;
    property OnEnableControls: TEnableControlsEvent write FOnEnableControls;
    property OnCalcTimeUpdate: TStatusUpdateEvent write FOnCalcTimeUpdate;
    property OnFitTimeUpdate: TStatusUpdateEvent write FOnFitTimeUpdate;
    /// A running fit has just plotted its best curve so far on the chart.
    property OnFitCurve: TNotifyEvent write FOnFitCurve;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Controls,
  unit_DataProcessing, unit_SeriesIO,
  unit_LFPSO_Periodic, unit_LFPSO_Irregular, unit_LFPSO_Poly,
  unit_config, unit_SmartLimits, unit_sys_helpers, System.Math,
  unit_CrashReport, unit_consts, frm_Limits;

type
  TFittingThread = class(TThread)
  private
    FLFPSO: TLFPSO_BASE;
    FCalcParams: TCalcThreadParams;
  protected
    procedure Execute; override;
  end;

procedure TFittingThread.Execute;
begin
  try
    FLFPSO.Run(FCalcParams);
  finally
    PostMessage(Application.MainFormHandle, WM_FIT_COMPLETE, 0, 0);
  end;
end;

/// A seed for one fit run, from a GUID rather than Random: System.RandSeed is
/// what the engine is about to be seeded with, and reading it here would tie
/// every run's seed to the previous one. Positive, as TLFPSO_BASE.Seed wants
/// (a negative one means Randomize).
function NewFitSeed: Integer;
var
  G: TGUID;
begin
  G := TGUID.NewGuid;
  Result := Integer((G.D1 xor (Cardinal(G.D2) shl 16) xor Cardinal(G.D3))
                    and $7FFFFFFF);
  if Result = 0 then
    Result := 1;
end;

{ TCalcOrchestrator }

constructor TCalcOrchestrator.Create(ACalcSettings: TfrmCalcSettings;
  AProjectPanel: TfrmProjectPanel; AChartInfo: TfrmChartInfo;
  AChartPages: TfrmChartPages; AChartMgr: TChartManager;
  AProfileMgr: TProfileManager);
begin
  inherited Create;
  FCalcSettings := ACalcSettings;
  FProjectPanel := AProjectPanel;
  FChartInfo := AChartInfo;
  FChartPages := AChartPages;
  FChartMgr := AChartMgr;
  FProfileMgr := AProfileMgr;
end;

destructor TCalcOrchestrator.Destroy;
var
  LThread: TThread;
begin
  if FFitThread <> nil then
  begin
    FLFPSO.Terminate;
    LThread := FFitThread;
    FFitThread := nil;
    LThread.WaitFor;
    LThread.Free;
    FreeAndNil(FLFPSO);
  end;
  inherited;
end;

function TCalcOrchestrator.PrepareCalc: Boolean;
begin
  Result := False;
  if (FProjectPanel.Project.ActiveModel = nil) then Exit;

  FCalc := TCalc.Create;
  FCalc.Limit := FChartInfo.MinLimit;
  if (FProjectPanel.Project.LinkedData <> nil) and FProjectPanel.ActiveModelSeries.Visible then
  begin
    FCalc.ExpValues := SeriesToData(FChartMgr.Series[FProjectPanel.Project.LinkedData.CurveID]);
    if FCalcSettings.IsPWChiSqr then
      FCalc.MovAvg := MovAvg(FCalc.ExpValues, FProjectPanel.FitParams.MovAvgWindow);
    { The chi-squared shown is taken at the scale a fit with these settings
      would score it at, so the number after a fit is the fit's own. }
    FCalc.SolveScale := FCalcSettings.SolveScale;
    FCalc.ScaleWindowLog := TfrmCalcSettings.ScaleWindowToLog(FCalcSettings.ScaleWindowOrDefault);
  end;

  GetThreadParams;
  FCalc.Params := FCalcThreadParams;
  FCalc.Model := Structure.Model(FProjectPanel.IsNonPeriodicProfile);
  FCalc.Model.Profiles := FProjectPanel.GetProfileFunctions;
  Screen.Cursor := crHourGlass;
  Result := True;
end;

procedure TCalcOrchestrator.GetThreadParams;
begin
  FCalcWatch := TStopwatch.StartNew;

  FProjectPanel.ActiveModelSeries.BeginUpdate;

  FCalcSettings.FillCalcThreadParams(FCalcThreadParams);
end;

procedure TCalcOrchestrator.FinalizeCalc(Calc: TCalc);
begin
  FProjectPanel.RescaleChart;
  FChartMgr.PlotResults(FProjectPanel.Project.ActiveModel.CurveID, Calc.Results);
  if Assigned(FOnCalcTimeUpdate) then
    FOnCalcTimeUpdate('Time: ' + FormatDuration(FCalcWatch.Elapsed.TotalSeconds));
  FProjectPanel.ActiveModelSeries.EndUpdate;
  FProjectPanel.ActiveModelSeries.Repaint;
  FChartInfo.SetPeriod(Structure.Period);
  Screen.Cursor := crDefault;
  FChartInfo.SetPeakInfo(FProjectPanel.ActiveModelSeries, FChartInfo.Chart.BottomAxis.Minimum, FChartInfo.Chart.BottomAxis.Maximum);
end;

procedure TCalcOrchestrator.RunCalc(const Recover: Boolean);
begin
  try
    if not PrepareCalc then Exit;
    try
      if Assigned(FOnEnableControls) then
        FOnEnableControls(False);
      FCalc.Run;
      if (FProjectPanel.Project.LinkedData <> nil) and FProjectPanel.ActiveModelSeries.Visible then
      begin
        FCalc.CalcChiSquare(FCalcSettings.ThetaWeightIndex);
        FChartInfo.SetChiSquare(FCalc.ChiSQR, FCalc.ChiSQR);
        FChartInfo.SetChiSquarePlain(FCalc.ChiSQRPlain);
        FLastChi := FCalc.ChiSQR;
        FLastChiPlain := FCalc.ChiSQRPlain;
        FLastSolveScale := FCalc.SolveScale;
        FLastScaleLog := FCalc.ScaleLog;
        FLastScaleClamped := FCalc.ScaleClamped;
        FLastScaleDataID := FProjectPanel.Project.LinkedData.ID;
        FLastScaleProject := FProjectPanel.ProjectSerial;
        FChartInfo.SetChiScale(FLastSolveScale, FLastScaleLog, FLastScaleClamped);
      end
      else begin
        FChartInfo.ClearChiSquare;
        FChartInfo.ClearChiScale;
        FLastChiSquare := 0;
      end;

      FProjectPanel.PlotProfiles;
    except
      on E: exception do
      begin
        ShowMessage(E.Message);
        FProjectPanel.ActiveModelSeries.EndUpdate;
        FProjectPanel.ActiveModelSeries.Repaint;
        Screen.Cursor := crDefault;
      end;
    end;
    FinalizeCalc(FCalc);
  finally
    if Assigned(FOnEnableControls) then
      FOnEnableControls(True);
    FCalc.Free;
  end;
end;

function TCalcOrchestrator.GetFitParams(const Resume: Boolean): Boolean;
var
  FFitParams: TFitParams;
  Caption: string;
begin
  FFitParams := FProjectPanel.FitParams;
  if not FBenchmarkMode then
  begin
    Result := False;
    FFitStructure := Structure.ToFitStructure;
    if Resume then
    begin
      RecentreOnValue(FFitStructure, BulkDensities(FFitStructure));
      ClampToPhysics(FFitStructure);
    end;
    if Resume then
      Caption := 'Resume'
    else
      Caption := 'Run';
    if frmLimits.ShowLimits(Caption, FFitStructure) then
          Structure.UpdateInterfaceP(FFitStructure)
    else begin
      Exit;
    end;
  end
  else
    FFitStructure := Structure.ToFitStructure;

  FCalcSettings.ReadFitParams(FFitParams);
  FProjectPanel.FitParams := FFitParams;

  Result := True;
end;

function TCalcOrchestrator.PrepareLFPSO(const Resume: Boolean): Boolean;
var
  Ranges: TArray<TPeriodRange>;
  i: Integer;
begin
  Result := False;
  case FCalcSettings.FittingMode of
    fmIrregular : FLFPSO := TLFPSO_Irregular.Create;
    fmPeriodic  : FLFPSO := TLFPSO_Periodic.Create;
    fmPoly      : FLFPSO := TLFPSO_Poly.Create;
  end;

  { An irregular fit on a model whose Table is in use starts each period from
    its value in the Table, which is what the chart shows, rather than every
    period from the stack's single value: a Resume, a Run answered "Keep
    them", and a reopened project, whose Table is not flagged as a fit's and
    so is never offered for clearing. "Clear them" deletes the Table, and then
    every period starts from the single value. ToFitStructure carries the
    tables; the engine reads them in SetStructure, so this is set before
    Structure below. }
  FFitFromTables := (FCalcSettings.FittingMode = fmIrregular) and
    FProjectPanel.IsNonPeriodicProfile;
  if FLFPSO is TLFPSO_Irregular then
    TLFPSO_Irregular(FLFPSO).StartFromTables := FFitFromTables;

  { A seed of its own for every run, drawn here rather than by Randomize inside
    the engine, so that the fit record can say which one it was and typing it
    into Advanced settings repeats the fit. }
  FFitSeed := FProjectPanel.FitParams.Seed;
  if FFitSeed <= 0 then
    FFitSeed := NewFitSeed;
  FLFPSO.Seed := FFitSeed;

  GetThreadParams;

  FLFPSO.Params := FProjectPanel.FitParams;
  FLFPSO.Limit := FChartInfo.MinLimit;
  FLFPSO.UseGPU := TConfig.Section<TCalcOptions>.UseGPU;

  if (FProjectPanel.Project.LinkedData <> nil) and FProjectPanel.ActiveModelSeries.Visible then
  begin
    FLFPSO.ExpValues := SeriesToData(FChartMgr.Series[FProjectPanel.Project.LinkedData.CurveID]);
    if FCalcSettings.IsPWChiSqr then
      FLFPSO.MovAvg := MovAvg(FLFPSO.ExpValues, FProjectPanel.FitParams.MovAvgWindow);
  end else
  begin
     FreeAndNil(FLFPSO);
     ShowMessage('Measured curve is not linked!');
     Exit;
  end;

  { The gradient the model already carries, fed to the optimizer the same way
    PrepareCalc feeds it to TCalc. SetStructure consumes it, so it has to be in
    place before Structure is assigned. Without it every higher-order
    coefficient starts at zero, and a frozen gradient - whose empty range lets
    nothing move off that zero - is fitted flat. }
  if FCalcSettings.FittingMode = fmPoly then
    TLFPSO_Poly(FLFPSO).InitialPolynomes := FProjectPanel.GetProfileFunctions;

  { Frozen parameters become an empty range here and nowhere else. The engine
    has no concept of freezing; an empty range is what pins a value. }
  CollapseFixed(FFitStructure);
  FLFPSO.Structure := FFitStructure;

  { The limits are one window per layer, and after a Resume that window is
    centred on period 1's value: in a graded stack the other periods can lie
    outside it. They start from the limit and cannot get past it, so ask. }
  if FFitFromTables and not FBenchmarkMode and
     (TLFPSO_Irregular(FLFPSO).ClampedStarts > 0) and
     (MessageDlg(Format('%d per-period value(s) of the Table lie outside their ' +
        'layer''s fit limits. They will start from the limit and the fit ' +
        'cannot move them past it.'#13#10#13#10'Widen the limits in the ' +
        'Fitting Limits dialog to keep them. Start the fit anyway?',
        [TLFPSO_Irregular(FLFPSO).ClampedStarts]),
        mtWarning, [mbYes, mbNo], 0) <> mrYes) then
  begin
    FreeAndNil(FLFPSO);
    Exit;
  end;

  { Free period (periodic mode): each repeating stack's period may move by the
    window around the value it starts from - this run's model, so a resumed
    fit carries on from where the last one ended. The engine is the one
    fit_xrr's "target": "period" drives. }
  if (FCalcSettings.FittingMode = fmPeriodic) and FProjectPanel.FitParams.FreePeriod then
  begin
    Ranges := PeriodRanges(FFitStructure, FProjectPanel.FitParams.PeriodWindow);
    for i := 0 to High(Ranges) do
      TLFPSO_Periodic(FLFPSO).SetPeriodRange(i, Ranges[i].Min, Ranges[i].Max);
  end;

  FChartPages.PrepareConvergence(FProjectPanel.FitParams.NMax, Resume);
  FChartPages.PrepareDiagnostics(FProjectPanel.FitParams.NMax, Resume);

  FFitMode := FCalcSettings.FittingMode;
  FFitResumed := Resume;
  FFitStarted := Now;
  FFitCalcParams := FCalcThreadParams;
  FFitSettings := FProjectPanel.FitParams;
  FFitPWChi := FCalcSettings.IsPWChiSqr;
  FFitRMin := FChartInfo.MinLimit;
  FFitTwoTheta := FCalcSettings.Is2Theta;

  Result := True;
end;

procedure TCalcOrchestrator.StopCalc;
begin
  if FLFPSO <> nil then
    FLFPSO.Terminate;
  if FFitThread <> nil then
    FFitThread.Terminate;
end;

procedure TCalcOrchestrator.UpdateInterface(const FitStructure: TFitStructure;
  const Poly: TProfileFunctions; const Res: TLayeredModel;
  const CreateExtension: Boolean);
begin
  { The write-back follows the ENGINE that ran, not the shape of the model.
    TLFPSO_Irregular flattens the model into one stack of every physical layer
    and UpdateInterfaceNP walks that; the periodic and poly engines return the
    model in its own shape and UpdateInterfaceP walks it stack by stack. A
    non-periodic model (every N = 1) fitted in periodic mode - the mode every
    fit_xrr project opens in - came back in its own shape and used to be handed
    to UpdateInterfaceNP, which read Stacks[0] past its single layer: an access
    violation, or zeroed layers and a curve for the bare substrate. }
  case FCalcSettings.FittingMode of
    fmPeriodic:
      Structure.UpdateInterfaceP(FitStructure, True);
    fmPoly:
      begin
        Structure.UpdateInterfaceP(FitStructure, True);
        if Structure.IsPeriodic then
        begin
          if CreateExtension then
            FProjectPanel.CreateFitGradientExtensions(Poly)
          else
            FProjectPanel.UpdateFitGradientExtensions(Poly);
        end;
      end;
    fmIrregular:
      begin
        Structure.UpdateInterfaceNP(FitStructure, True);
        if Structure.IsPeriodic then
        begin
          if CreateExtension then
            FProjectPanel.CreateProfileExtension(True);
          Structure.UpdateProfiles(Res);
        end;
      end;
  end;
end;

procedure TCalcOrchestrator.StartFitting(const Resume: Boolean);
var
  FitThread: TFittingThread;
begin
  if FFitThread <> nil then Exit;

  { A resume continues from the extensions the last run produced - they are
    its starting point, not stale leftovers. Asking whether to clear them
    makes no sense there, and clearing them would throw away the depth
    profiles the polynomial fit is seeded from. Keep them, silently. }
  FKeepExtensions := Resume;
  if (not Resume) and (not FBenchmarkMode) and FProjectPanel.HasFitExtensions then
    case ConfirmStaleExtensions of
      seaCancel: Exit;
      seaClear:  FProjectPanel.ClearFitExtensions;
      seaKeep:   FKeepExtensions := True;
    end;

  if not GetFitParams(Resume) then Exit;
  if not PrepareLFPSO(Resume) then Exit;

  Screen.Cursor := crHourGlass;
  { The model is about to change: the record of the previous fit no longer
    describes it, and a live autosave must not store it beside the new one. }
  FProjectPanel.FitRecord := '';
  FProjectPanel.GenerateAutosaveName;
  if Assigned(FOnEnableControls) then
    FOnEnableControls(False);
  FFitWatch := TStopwatch.StartNew;
  FFirstUpdate := not FKeepExtensions;
  FABestChiSquare := 1e32;
  { The plain chi-squared belongs to a full curve, and the fit reports only the
    weighted one it minimises. Blank it until FinalizeFitting recalculates the
    model the fit ended on, rather than leave the pre-fit number standing. }
  FChartInfo.ClearChiSquarePlain;
  FChartInfo.SetChiScalePending(FProjectPanel.FitParams.SolveScale);

  FitThread := TFittingThread.Create(True);
  FitThread.FLFPSO := FLFPSO;
  FitThread.FCalcParams := FCalcThreadParams;
  FFitThread := FitThread;
  FitThread.Start;

  if FBenchmarkMode then
  begin
    FFitThread.WaitFor;
    FinalizeFitting;
  end;
end;

procedure TCalcOrchestrator.RunFitting;
begin
  StartFitting(False);
end;

{ Continue from where the last fit stopped: free parameters get their window
  slid onto the value they reached, frozen ones stay pinned to theirs. The best
  chi-squared is not carried across - changing the weight type changes the
  objective, so the two runs' numbers are not on the same scale. }
procedure TCalcOrchestrator.ResumeFitting;
begin
  if not FHasFitResults then
    Exit;
  StartFitting(True);
end;

{ The last fit's results belong to the model it ran on. Once another model is
  loaded or swapped in, there is nothing to resume: Resume would slide that
  model's windows onto its own values and write them back, which is not what
  the user asked for. Call this wherever the live structure is replaced. }
procedure TCalcOrchestrator.ModelChanged;
begin
  FHasFitResults := False;
end;

procedure TCalcOrchestrator.FinalizeFitting;
var
  Hour, Min, Sec, MSec: Word;
  FitResult: TLayeredModel;
  Rec: TJSONObject;
begin
  try
    FitResult := FLFPSO.Result;
    try
      FFitPoly := FLFPSO.Polynomes;
      { The chi-squared of the solution returned, rescored on the CPU after a
        GPU run - not the running minimum of the progress messages, which a
        benchmark or batch run never receives (it stays at 1e32) and which
        after a GPU run is the GPU's number. }
      FFitBestChi := FLFPSO.BestChiSquare;
      UpdateInterface(FLFPSO.Structure, FLFPSO.Polynomes, FitResult, FFirstUpdate);
    finally
      FitResult.Free;
    end;

    FProjectPanel.Project.ActiveModel.Data := Structure.ToString;
    FFitSeconds := FFitWatch.Elapsed.TotalSeconds;
    DecodeTime(FFitSeconds / SecsPerDay, Hour, Min, Sec, MSec);
    FFitDuration := Format('%2.2d:%2.2d:%2.2d', [Hour, Min, Sec]);   // the export's hh:mm:ss
    FFitDevice := FLFPSO.DeviceUsed;
    FHasFitResults := True;
    if Assigned(FOnFitTimeUpdate) then
      FOnFitTimeUpdate(Format('Fitting time: %s on %s',
        [FormatDuration(FFitSeconds), FFitDevice]));
    FLastChi := NaN;
    FLastChiPlain := NaN;
    FLastSolveScale := False;
    FLastScaleLog := 0;
    RunCalc(False);
    FChartInfo.SetChiSquare(FABestChiSquare, FABestChiSquare);
    { After RunCalc: the record carries the plain chi-squared and the scale of
      the model the fit ended on. Before AutoSave, which saves it. }
    Rec := BuildFitRecord;
    try
      FProjectPanel.FitRecord := Rec.ToJSON;
    finally
      Rec.Free;
    end;
    FProjectPanel.AutoSave;
  finally
    Screen.Cursor := crDefault;
    if Assigned(FOnEnableControls) then
      FOnEnableControls(True);
    FreeAndNil(FFitThread);
    FreeAndNil(FLFPSO);
  end;
end;

procedure TCalcOrchestrator.HandleFitComplete;
begin
  if FBenchmarkMode or (FFitThread = nil) then Exit;

  if FFitThread.FatalException <> nil then
  begin
    ShowMessage('Fitting error: ' + Exception(FFitThread.FatalException).Message);
    Screen.Cursor := crDefault;
    if Assigned(FOnEnableControls) then
      FOnEnableControls(True);
    FreeAndNil(FFitThread);
    FreeAndNil(FLFPSO);
    Exit;
  end;

  FinalizeFitting;
end;

procedure TCalcOrchestrator.RecalcFromStructure;
begin
  RunCalc(False);   // redraws the profile pages too
end;

procedure TCalcOrchestrator.HandleFitUpdate(var Msg: TMessage);
var
  msg_prm: PUpdateFitProgressMsg;
  NeedsSaving: Boolean;
begin
  msg_prm := PUpdateFitProgressMsg(Msg.WParam);
  FChartPages.AddConvergencePoint(msg_prm.Step, msg_prm.BestChi, msg_prm.WorstChi, msg_prm.WasShaken);
  FChartPages.AddDiagnosticPoint(msg_prm.Step, msg_prm.Diversity,
    msg_prm.MeanVelocity, msg_prm.JammingCount, msg_prm.LevyScale,
    msg_prm.CFact, FProjectPanel.FitParams.JammingMax);

  FChartInfo.SetChiSquare(msg_prm.LastChi, msg_prm.BestChi);

  FLastChiSquare :=  msg_prm.BestChi;
  if FABestChiSquare > FLastChiSquare then
  Begin
    NeedsSaving := True;
    FABestChiSquare := FLastChiSquare
  End
  else
    NeedsSaving := False;

  if msg_prm.Full then
  begin
    FChartMgr.PlotResults(FProjectPanel.Project.ActiveModel.CurveID, msg_prm.Curve);
    if Assigned(FOnFitCurve) then
      FOnFitCurve(Self);
    if TConfig.Section<TOtherOptions>.LiveUpdate then
    begin
      UpdateInterface(msg_prm.Structure, msg_prm.Poly, msg_prm.LayeredModel, FFirstUpdate);
      FFirstUpdate := False;
      if NeedsSaving then
           FProjectPanel.AutoSave;
    end;
    msg_prm.LayeredModel.Free;
  end;
  Dispose(msg_prm);
  if Assigned(FOnFitTimeUpdate) then
    FOnFitTimeUpdate('Fitting time: ' + FormatDuration(FFitWatch.Elapsed.TotalSeconds));
end;

function TCalcOrchestrator.HasFitRecord: Boolean;
begin
  Result := FProjectPanel.FitRecord <> '';
end;

{ Everything about the fit that just ended, as it ran: the settings captured in
  PrepareLFPSO, not the ones the panels hold now, the chi-squareds of the model
  it ended on, and that model with its limits, pairing, freezing and tables.
  It is kept with the project ([FITRESULT] in params.dsc), so Result - Export
  fit results writes the same object after the project is reopened. }
function TCalcOrchestrator.BuildFitRecord: TJSONObject;
const
  FittingModeNames: array[TFittingMode] of string = ('Irregular', 'Periodic', 'Polynomial');
  CalcModeNames: array[TCalcMode] of string = ('Theta', 'Lambda', 'Test');
  PolarisationNames: array[TPolarisation] of string = ('S', 'SP');
  RoughnessNames: array[TRoughnessFunction] of string = ('Error', 'Exp', 'Linear', 'Step', 'Sinus');
  ThetaWeightNames: array[0..5] of string =
    ('none', 'theta^2', 'theta', 'sqrt(theta)', '1/theta^2', '1/sqrt(theta)');
  ParamNames: array[1..3] of string = ('thickness', 'roughness', 'density');
  SubjNames: array[TParameterType] of string = ('thickness', 'roughness', 'density');
var
  JFit, JChi, JCalc, JStructure, JSubstrate, JStack, JLayer, JParam, JPoly: TJSONObject;
  JStacks, JLayers, JTable, JPolys, JCoeffs: TJSONArray;
  FitStruct: TFitStructure;
  i, j, q, c: Integer;   // q, not p: inside "with" a layer, p is its field P
  Platform: string;

  { A number JSON can hold: NAN and INF are written unquoted by TJSONNumber and
    would make the whole record unreadable. }
  function Num(const V: Double): TJSONValue;
  begin
    if IsNan(V) or IsInfinite(V) then
      Result := TJSONNull.Create
    else
      Result := TJSONNumber.Create(V);
  end;

begin
  FitStruct := Structure.ToFitStructure;
  {$IFDEF WIN64} Platform := 'Win64'; {$ELSE} Platform := 'Win32'; {$ENDIF}

  Result := TJSONObject.Create;
  try
    Result.AddPair('application', 'X-RayCalc3');
    Result.AddPair('version', TCrashReport.GetAppVersion);
    Result.AddPair('platform', Platform);
    Result.AddPair('projectVersion', TJSONNumber.Create(CURRENT_PROJECT_VERSION));
    Result.AddPair('fitDate', DateToISO8601(FFitStarted, False));
    Result.AddPair('fittingDuration', FFitDuration);
    Result.AddPair('fittingSeconds', TJSONNumber.Create(RoundTo(FFitSeconds, -3)));
    Result.AddPair('fittingDevice', FFitDevice);
    Result.AddPair('seed', TJSONNumber.Create(FFitSeed));
    Result.AddPair('resumed', TJSONBool.Create(FFitResumed));
    Result.AddPair('fittingMode', FittingModeNames[FFitMode]);
    if FFitMode = fmIrregular then
      Result.AddPair('startFromTables', TJSONBool.Create(FFitFromTables));
    if FProjectPanel.Project.ActiveModel <> nil then
      Result.AddPair('model', FProjectPanel.Project.ActiveModel.Title);
    if FProjectPanel.Project.LinkedData <> nil then
      Result.AddPair('dataItem', FProjectPanel.Project.LinkedData.Title);

    { chiSquared is the engine's best, the number the fit minimised;
      chiSquaredRecalc and chiSquaredPlain are the recalculation of the model
      it ended on, weighted and unweighted, at the scale below. }
    Result.AddPair('chiSquared', Num(FFitBestChi));
    Result.AddPair('chiSquaredRecalc', Num(FLastChi));
    Result.AddPair('chiSquaredPlain', Num(FLastChiPlain));
    if FFitSettings.SolveScale then
      Result.AddPair('chi2Scale', 'solved')
    else
      Result.AddPair('chi2Scale', 'anchored');
    if FLastSolveScale then
    begin
      Result.AddPair('scaleRatio', TJSONNumber.Create(RoundTo(Power(10, FLastScaleLog), -6)));
      Result.AddPair('scaleClamped', TJSONBool.Create(FLastScaleClamped));
    end;

    JChi := TJSONObject.Create;
    Result.AddPair('chi2Weighting', JChi);
    JChi.AddPair('thetaWeight', TJSONNumber.Create(FFitSettings.ThetaWeight));
    if (FFitSettings.ThetaWeight >= Low(ThetaWeightNames)) and
       (FFitSettings.ThetaWeight <= High(ThetaWeightNames)) then
      JChi.AddPair('thetaWeightName', ThetaWeightNames[FFitSettings.ThetaWeight]);
    JChi.AddPair('pointWeight', TJSONBool.Create(FFitPWChi));
    JChi.AddPair('movAvgWindow', TJSONNumber.Create(RoundTo(FFitSettings.MovAvgWindow, -6)));
    Result.AddPair('rMin', Num(FFitRMin));

    JFit := TJSONObject.Create;
    Result.AddPair('fitParams', JFit);
    JFit.AddPair('maxIterations', TJSONNumber.Create(FFitSettings.NMax));
    JFit.AddPair('population', TJSONNumber.Create(FFitSettings.Pop));
    JFit.AddPair('tolerance', TJSONNumber.Create(FFitSettings.Tolerance));
    JFit.AddPair('vMax', TJSONNumber.Create(FFitSettings.Vmax));
    JFit.AddPair('jammingMax', TJSONNumber.Create(FFitSettings.JammingMax));
    JFit.AddPair('reInitMax', TJSONNumber.Create(FFitSettings.ReInitMax));
    JFit.AddPair('kChiSqr', TJSONNumber.Create(FFitSettings.KChiSqr));
    JFit.AddPair('kVmax', TJSONNumber.Create(FFitSettings.KVmax));
    JFit.AddPair('w1', TJSONNumber.Create(FFitSettings.w1));
    JFit.AddPair('w2', TJSONNumber.Create(FFitSettings.w2));
    JFit.AddPair('ksxr', TJSONNumber.Create(FFitSettings.Ksxr));
    JFit.AddPair('shake', TJSONBool.Create(FFitSettings.Shake));
    JFit.AddPair('adaptVel', TJSONBool.Create(FFitSettings.AdaptVel));
    JFit.AddPair('useConstriction', TJSONBool.Create(FFitSettings.UseConstriction));
    if FFitMode <> fmPoly then          // the Polynomial engine has no range seed
      JFit.AddPair('rangeSeed', TJSONBool.Create(FFitSettings.RangeSeed));
    JFit.AddPair('solveScale', TJSONBool.Create(FFitSettings.SolveScale));
    { the fraction typed, back from the log10(1 + w) the engine holds }
    JFit.AddPair('scaleSolveWindow',
      TJSONNumber.Create(RoundTo(Power(10, FFitSettings.ScaleWindowLog) - 1, -6)));
    JFit.AddPair('freePeriod', TJSONBool.Create(FFitSettings.FreePeriod and
      (FFitMode = fmPeriodic)));
    if FFitSettings.FreePeriod and (FFitMode = fmPeriodic) then
      JFit.AddPair('periodWindow', TJSONNumber.Create(RoundTo(FFitSettings.PeriodWindow, -6)));
    if FFitMode = fmPoly then
    begin
      JFit.AddPair('polyOrder', TJSONNumber.Create(FFitSettings.MaxPOrder));
      JFit.AddPair('polyFactor', TJSONNumber.Create(FFitSettings.PolyFactor));
    end;
    if FFitMode = fmIrregular then
    begin
      JFit.AddPair('smooth', TJSONBool.Create(FFitSettings.Smooth));
      JFit.AddPair('smoothWindow', TJSONNumber.Create(FFitSettings.SmoothWindow));
    end;

    JCalc := TJSONObject.Create;
    Result.AddPair('calcParams', JCalc);
    JCalc.AddPair('mode', CalcModeNames[FFitCalcParams.Mode]);
    case FFitCalcParams.Mode of
      cmTheta:
        begin
          { the calculation's range is theta; the chart may show 2theta }
          JCalc.AddPair('startTheta', TJSONNumber.Create(FFitCalcParams.StartT));
          JCalc.AddPair('endTheta', TJSONNumber.Create(FFitCalcParams.EndT));
          JCalc.AddPair('deltaTheta', TJSONNumber.Create(FFitCalcParams.DT));
          JCalc.AddPair('wavelength', TJSONNumber.Create(FFitCalcParams.Lambda));
          JCalc.AddPair('chartIn2Theta', TJSONBool.Create(FFitTwoTheta));
        end;
      cmLambda:
        begin
          JCalc.AddPair('startLambda', TJSONNumber.Create(FFitCalcParams.StartL));
          JCalc.AddPair('endLambda', TJSONNumber.Create(FFitCalcParams.EndL));
          JCalc.AddPair('theta', TJSONNumber.Create(FFitCalcParams.Theta));
          JCalc.AddPair('deltaLambda', TJSONNumber.Create(FFitCalcParams.DW));
        end;
    end;
    JCalc.AddPair('points', TJSONNumber.Create(FFitCalcParams.N));
    JCalc.AddPair('polarisation', PolarisationNames[FFitCalcParams.P]);
    JCalc.AddPair('roughnessFunction', RoughnessNames[FFitCalcParams.RF]);

    JStructure := TJSONObject.Create;
    Result.AddPair('structure', JStructure);
    JStacks := TJSONArray.Create;
    JStructure.AddPair('stacks', JStacks);
    for i := 0 to High(FitStruct.Stacks) do
    begin
      JStack := TJSONObject.Create;
      JStacks.AddElement(JStack);
      JStack.AddPair('name', FitStruct.Stacks[i].Header);
      JStack.AddPair('repetitions', TJSONNumber.Create(FitStruct.Stacks[i].N));

      JLayers := TJSONArray.Create;
      JStack.AddPair('layers', JLayers);
      for j := 0 to High(FitStruct.Stacks[i].Layers) do
      begin
        JLayer := TJSONObject.Create;
        JLayers.AddElement(JLayer);
        JLayer.AddPair('material', FitStruct.Stacks[i].Layers[j].Material);
        for q := 1 to 3 do
          with FitStruct.Stacks[i].Layers[j] do
          begin
            JParam := TJSONObject.Create;
            JLayer.AddPair(ParamNames[q], JParam);
            JParam.AddPair('value', TJSONNumber.Create(P[q].V));
            JParam.AddPair('min', TJSONNumber.Create(P[q].min));
            JParam.AddPair('max', TJSONNumber.Create(P[q].max));
            JParam.AddPair('paired', TJSONBool.Create(P[q].Paired));
            JParam.AddPair('frozen', TJSONBool.Create(P[q].Fixed));
            { the per-period values of an irregular fit, surface end first,
              where the model uses them (TLayerData.PeriodValue) }
            if (FitStruct.Stacks[i].N > 1) and not P[q].Paired and
               (Length(PP[q]) >= FitStruct.Stacks[i].N) then
            begin
              JTable := TJSONArray.Create;
              JParam.AddPair('perPeriod', JTable);
              for c := 0 to FitStruct.Stacks[i].N - 1 do
                JTable.AddElement(TJSONNumber.Create(PP[q][c]));
            end;
          end;
      end;
    end;

    JSubstrate := TJSONObject.Create;
    JStructure.AddPair('substrate', JSubstrate);
    JSubstrate.AddPair('material', FitStruct.Subs.Material);
    JSubstrate.AddPair('roughness', TJSONNumber.Create(FitStruct.Subs.P[2].V));
    JSubstrate.AddPair('density', TJSONNumber.Create(FitStruct.Subs.P[3].V));

    { A polynomial fit's depth profiles: C[0] + C[1] n + ... over the periods,
      as the gradient extensions hold them. }
    if FFitMode = fmPoly then
    begin
      JPolys := TJSONArray.Create;
      Result.AddPair('polynomials', JPolys);
      for i := 0 to High(FFitPoly) do
      begin
        JPoly := TJSONObject.Create;
        JPolys.AddElement(JPoly);
        JPoly.AddPair('stack', TJSONNumber.Create(FFitPoly[i].StackID));
        JPoly.AddPair('layer', TJSONNumber.Create(FFitPoly[i].LayerID));
        JPoly.AddPair('parameter', SubjNames[FFitPoly[i].Subj]);
        JCoeffs := TJSONArray.Create;
        JPoly.AddPair('coefficients', JCoeffs);
        for c := 0 to High(FFitPoly[i].C) do
          JCoeffs.AddElement(TJSONNumber.Create(FFitPoly[i].C[c]));
      end;
    end;
  except
    Result.Free;
    raise;
  end;
end;

procedure TCalcOrchestrator.ExportFitResultsToJSON(const FileName: string);
var
  Parsed: TJSONValue;
  Root: TJSONObject;
  SL: TStringList;
begin
  Parsed := TJSONObject.ParseJSONValue(FProjectPanel.FitRecord);
  if not (Parsed is TJSONObject) then
  begin
    Parsed.Free;
    raise Exception.Create('The project''s fit record cannot be read.');
  end;
  Root := TJSONObject(Parsed);
  try
    Root.AddPair('exportDate', DateToISO8601(Now, False));
    SL := TStringList.Create;
    try
      SL.Text := Root.Format(2);
      SL.SaveToFile(FileName, TEncoding.UTF8);
    finally
      SL.Free;
    end;
  finally
    Root.Free;
  end;
end;

end.
