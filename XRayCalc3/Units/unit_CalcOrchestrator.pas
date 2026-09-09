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
  System.SysUtils, System.Classes, System.JSON, System.DateUtils,
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
    FStartTime, FFitStartTime: TDateTime;
    FCalc: TCalc;
    FCalcThreadParams: TCalcThreadParams;
    FFitStructure: TFitStructure;
    FLastChiSquare, FABestChiSquare: Single;
    FBenchmarkMode, FFirstUpdate, FKeepExtensions: Boolean;
    FFitDuration: string;
    FHasFitResults: Boolean;

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

    { Internal }
    function PrepareCalc: Boolean;
    procedure GetThreadParams;
    procedure FinalizeCalc(Calc: TCalc);
    function GetFitParams: Boolean;
    function PrepareLFPSO: Boolean;
    procedure UpdateInterface(const FitStructure: TFitStructure;
      const Poly: TProfileFunctions; const Res: TLayeredModel;
      const CreateExtension: Boolean = True);
    procedure FinalizeFitting;
  public
    constructor Create(ACalcSettings: TfrmCalcSettings;
      AProjectPanel: TfrmProjectPanel; AChartInfo: TfrmChartInfo;
      AChartPages: TfrmChartPages; AChartMgr: TChartManager;
      AProfileMgr: TProfileManager);
    destructor Destroy; override;

    procedure RunCalc(const Recover: Boolean);
    procedure RunFitting;
    procedure StopCalc;
    procedure RecalcFromStructure;
    procedure HandleFitUpdate(var Msg: TMessage);
    procedure HandleFitComplete;
    procedure ExportFitResultsToJSON(const FileName: string);

    property LastChiSquare: Single read FLastChiSquare write FLastChiSquare;
    property BenchmarkMode: Boolean read FBenchmarkMode write FBenchmarkMode;
    property HasFitResults: Boolean read FHasFitResults;
    property OnEnableControls: TEnableControlsEvent write FOnEnableControls;
    property OnCalcTimeUpdate: TStatusUpdateEvent write FOnCalcTimeUpdate;
    property OnFitTimeUpdate: TStatusUpdateEvent write FOnFitTimeUpdate;
  end;

implementation

uses
  Winapi.Windows,
  Vcl.Controls,
  unit_DataProcessing, unit_SeriesIO,
  unit_LFPSO_Periodic, unit_LFPSO_Irregular, unit_LFPSO_Poly,
  unit_config,
  frm_Limits;

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
  FStartTime := Now;

  FProjectPanel.ActiveModelSeries.BeginUpdate;

  FCalcSettings.FillCalcThreadParams(FCalcThreadParams);
end;

procedure TCalcOrchestrator.FinalizeCalc(Calc: TCalc);
var
  Hour, Min, Sec, MSec: Word;
begin
  FProjectPanel.RescaleChart;
  FChartMgr.PlotResults(FProjectPanel.Project.ActiveModel.CurveID, Calc.Results);
  DecodeTime(Now - FStartTime, Hour, Min, Sec, MSec);
  if Assigned(FOnCalcTimeUpdate) then
    FOnCalcTimeUpdate(Format('Time: %d.%3.3d s.', [60 * Min + Sec, MSec]));
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
      end
      else begin
        FChartInfo.ClearChiSquare;
        FLastChiSquare := 0;
      end;

      FProfileMgr.Prepare(Structure, FChartPages.ThicknessChart, FChartPages.RoughnessChart, FChartPages.DensityChart);
      if FProjectPanel.IsNonPeriodicProfile then
         FProfileMgr.PlotProfileNP(FChartPages.IsProfileActive)
      else
        FProfileMgr.PlotProfile(FProjectPanel.IsNonPeriodicProfile, FChartPages.IsProfileActive);
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

function TCalcOrchestrator.GetFitParams: Boolean;
var
  FFitParams: TFitParams;
begin
  FFitParams := FProjectPanel.FitParams;
  if not FBenchmarkMode then
  begin
    Result := False;
    FFitStructure := Structure.ToFitStructure;
    if frmLimits.ShowLimits('Run', FFitStructure) then
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

function TCalcOrchestrator.PrepareLFPSO: Boolean;
begin
  Result := False;
  case FCalcSettings.FittingMode of
    fmIrregular : FLFPSO := TLFPSO_Irregular.Create;
    fmPeriodic  : FLFPSO := TLFPSO_Periodic.Create;
    fmPoly      : FLFPSO := TLFPSO_Poly.Create;
  end;

  GetThreadParams;

  FLFPSO.Params := FProjectPanel.FitParams;
  FLFPSO.Limit := FChartInfo.MinLimit;

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

  FLFPSO.Structure := FFitStructure;

  FChartPages.PrepareConvergence(FProjectPanel.FitParams.NMax);
  FChartPages.PrepareDiagnostics(FProjectPanel.FitParams.NMax);

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
  if Structure.IsPeriodic then
  begin
    if FCalcSettings.FittingMode = fmPeriodic then
       Structure.UpdateInterfaceP(FitStructure)
    else begin
      if FCalcSettings.FittingMode = fmPoly then
      begin
        Structure.UpdateInterfaceP(FitStructure);
        if CreateExtension then
          FProjectPanel.CreateFitGradientExtensions(Poly)
        else
          FProjectPanel.UpdateFitGradientExtensions(Poly)
      end
      else
      begin
        Structure.UpdateInterfaceNP(FitStructure);
        if CreateExtension then
           FProjectPanel.CreateProfileExtension(True);
        Structure.UpdateProfiles(Res);
      end;
    end;
  end
  else
    Structure.UpdateInterfaceNP(FitStructure);
end;

procedure TCalcOrchestrator.RunFitting;
var
  FitThread: TFittingThread;
begin
  if FFitThread <> nil then Exit;

  FKeepExtensions := False;
  if (not FBenchmarkMode) and FProjectPanel.HasFitExtensions then
    case ConfirmStaleExtensions of
      seaCancel: Exit;
      seaClear:  FProjectPanel.ClearFitExtensions;
      seaKeep:   FKeepExtensions := True;
    end;

  if not GetFitParams then Exit;
  if not PrepareLFPSO then Exit;

  Screen.Cursor := crHourGlass;
  FProjectPanel.GenerateAutosaveName;
  if Assigned(FOnEnableControls) then
    FOnEnableControls(False);
  FFitStartTime := Now;
  FFirstUpdate := not FKeepExtensions;
  FABestChiSquare := 1e32;

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

procedure TCalcOrchestrator.FinalizeFitting;
var
  Hour, Min, Sec, MSec: Word;
  FitResult: TLayeredModel;
begin
  try
    FitResult := FLFPSO.Result;
    try
      UpdateInterface(FLFPSO.Structure, FLFPSO.Polynomes, FitResult, FFirstUpdate);
    finally
      FitResult.Free;
    end;

    FProjectPanel.Project.ActiveModel.Data := Structure.ToString;
    DecodeTime(Now - FFitStartTime, Hour, Min, Sec, MSec);
    FFitDuration := Format('%2.2d:%2.2d:%2.2d', [Hour, Min, Sec]);
    FHasFitResults := True;
    if Assigned(FOnFitTimeUpdate) then
      FOnFitTimeUpdate(Format('Fitting Time: %s sec', [FFitDuration]));
    RunCalc(False);
    FChartInfo.SetChiSquare(FABestChiSquare, FABestChiSquare);
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
  FProfileMgr.PlotProfile(FProjectPanel.IsNonPeriodicProfile, FChartPages.IsProfileActive);
  RunCalc(False);
end;

procedure TCalcOrchestrator.HandleFitUpdate(var Msg: TMessage);
var
  msg_prm: PUpdateFitProgressMsg;
  Hour, Min, Sec, MSec: Word;
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
  DecodeTime(Now - FFitStartTime, Hour, Min, Sec, MSec);
  if Assigned(FOnFitTimeUpdate) then
    FOnFitTimeUpdate(Format('Fitting Time: %2.2d:%2.2d:%2.2d sec', [Hour, Min, Sec]));
end;

procedure TCalcOrchestrator.ExportFitResultsToJSON(const FileName: string);
const
  FittingModeNames: array[TFittingMode] of string = ('Irregular', 'Periodic', 'Polynomial');
  CalcModeNames: array[TCalcMode] of string = ('Theta', 'Lambda', 'Test');
  PolarisationNames: array[TPolarisation] of string = ('S', 'SP');
  RoughnessNames: array[TRoughnessFunction] of string = ('Error', 'Exp', 'Linear', 'Step', 'Sinus');
var
  Root, JFitParams, JCalcParams, JStructure, JSubstrate: TJSONObject;
  JStacks: TJSONArray;
  JStack: TJSONObject;
  JLayers: TJSONArray;
  JLayer, JThickness, JRoughness, JDensity: TJSONObject;
  FitParams: TFitParams;
  FitStruct: TFitStructure;
  i, j: Integer;
  SL: TStringList;
begin
  FitParams := FProjectPanel.FitParams;
  FitStruct := Structure.ToFitStructure;

  Root := TJSONObject.Create;
  try
    Root.AddPair('application', 'X-RayCalc3');
    Root.AddPair('exportDate', DateToISO8601(Now, False));
    Root.AddPair('fittingDuration', FFitDuration);
    Root.AddPair('chiSquared', TJSONNumber.Create(FABestChiSquare));
    Root.AddPair('fittingMode', FittingModeNames[FCalcSettings.FittingMode]);

    // fitParams
    JFitParams := TJSONObject.Create;
    JFitParams.AddPair('maxIterations', TJSONNumber.Create(FitParams.NMax));
    JFitParams.AddPair('population', TJSONNumber.Create(FitParams.Pop));
    JFitParams.AddPair('tolerance', TJSONNumber.Create(FitParams.Tolerance));
    JFitParams.AddPair('vMax', TJSONNumber.Create(FitParams.Vmax));
    JFitParams.AddPair('jammingMax', TJSONNumber.Create(FitParams.JammingMax));
    JFitParams.AddPair('reInitMax', TJSONNumber.Create(FitParams.ReInitMax));
    JFitParams.AddPair('kChiSqr', TJSONNumber.Create(FitParams.KChiSqr));
    JFitParams.AddPair('kVmax', TJSONNumber.Create(FitParams.KVmax));
    JFitParams.AddPair('w1', TJSONNumber.Create(FitParams.w1));
    JFitParams.AddPair('w2', TJSONNumber.Create(FitParams.w2));
    JFitParams.AddPair('shake', TJSONBool.Create(FitParams.Shake));
    JFitParams.AddPair('adaptVel', TJSONBool.Create(FitParams.AdaptVel));
    JFitParams.AddPair('useConstriction', TJSONBool.Create(FitParams.UseConstriction));
    JFitParams.AddPair('rangeSeed', TJSONBool.Create(FitParams.RangeSeed));
    Root.AddPair('fitParams', JFitParams);

    // calcParams
    JCalcParams := TJSONObject.Create;
    JCalcParams.AddPair('mode', CalcModeNames[FCalcThreadParams.Mode]);
    case FCalcThreadParams.Mode of
      cmTheta:
        begin
          JCalcParams.AddPair('startAngle', TJSONNumber.Create(FCalcThreadParams.StartT));
          JCalcParams.AddPair('endAngle', TJSONNumber.Create(FCalcThreadParams.EndT));
          JCalcParams.AddPair('step', TJSONNumber.Create(FCalcThreadParams.DT));
          JCalcParams.AddPair('wavelength', TJSONNumber.Create(FCalcThreadParams.Lambda));
        end;
      cmLambda:
        begin
          JCalcParams.AddPair('startLambda', TJSONNumber.Create(FCalcThreadParams.StartL));
          JCalcParams.AddPair('endLambda', TJSONNumber.Create(FCalcThreadParams.EndL));
          JCalcParams.AddPair('theta', TJSONNumber.Create(FCalcThreadParams.Theta));
          JCalcParams.AddPair('stepLambda', TJSONNumber.Create(FCalcThreadParams.DW));
        end;
    end;
    JCalcParams.AddPair('polarisation', PolarisationNames[FCalcThreadParams.P]);
    JCalcParams.AddPair('roughnessFunction', RoughnessNames[FCalcThreadParams.RF]);
    Root.AddPair('calcParams', JCalcParams);

    // structure
    JStructure := TJSONObject.Create;
    JStacks := TJSONArray.Create;
    for i := 0 to High(FitStruct.Stacks) do
    begin
      JStack := TJSONObject.Create;
      JStack.AddPair('name', FitStruct.Stacks[i].Header);
      JStack.AddPair('repetitions', TJSONNumber.Create(FitStruct.Stacks[i].N));

      JLayers := TJSONArray.Create;
      for j := 0 to High(FitStruct.Stacks[i].Layers) do
      begin
        JLayer := TJSONObject.Create;
        JLayer.AddPair('material', FitStruct.Stacks[i].Layers[j].Material);

        JThickness := TJSONObject.Create;
        JThickness.AddPair('value', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[1].V));
        JThickness.AddPair('min', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[1].min));
        JThickness.AddPair('max', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[1].max));
        JLayer.AddPair('thickness', JThickness);

        JRoughness := TJSONObject.Create;
        JRoughness.AddPair('value', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[2].V));
        JRoughness.AddPair('min', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[2].min));
        JRoughness.AddPair('max', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[2].max));
        JLayer.AddPair('roughness', JRoughness);

        JDensity := TJSONObject.Create;
        JDensity.AddPair('value', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[3].V));
        JDensity.AddPair('min', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[3].min));
        JDensity.AddPair('max', TJSONNumber.Create(FitStruct.Stacks[i].Layers[j].P[3].max));
        JLayer.AddPair('density', JDensity);

        JLayers.Add(JLayer);
      end;
      JStack.AddPair('layers', JLayers);
      JStacks.Add(JStack);
    end;
    JStructure.AddPair('stacks', JStacks);

    // substrate
    JSubstrate := TJSONObject.Create;
    JSubstrate.AddPair('material', FitStruct.Subs.Material);
    JSubstrate.AddPair('roughness', TJSONNumber.Create(FitStruct.Subs.P[2].V));
    JSubstrate.AddPair('density', TJSONNumber.Create(FitStruct.Subs.P[3].V));
    JStructure.AddPair('substrate', JSubstrate);

    Root.AddPair('structure', JStructure);

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
