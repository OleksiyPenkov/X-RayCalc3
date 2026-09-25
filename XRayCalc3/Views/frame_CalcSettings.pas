unit frame_CalcSettings;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IniFiles,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  RzPanel, RzRadGrp, RzRadChk, RzButton,
  unit_Types;

const
  { The solved-scale window the MCP server uses when a request gives none
    (DEF_SCALE_SOLVE_WINDOW in unit_MCPFit), so a GUI fit and a server fit on
    the same settings are the same fit. }
  DEF_SCALE_SOLVE_WINDOW = 0.2;

type
  TAdvancedSettingsEvent = procedure(Sender: TObject; var Params: TFitParams) of object;

  TfrmCalcSettings = class(TFrame)
    RzPanel6: TRzPanel;
    Label7: TLabel;
    Label8: TLabel;
    lblPolyOrder: TLabel;
    Label21: TLabel;
    rgFittingMode: TRzRadioGroup;
    edFIter: TEdit;
    edFPopulation: TEdit;
    cbLFPSOShake: TRzCheckBox;
    cbSeedRange: TRzCheckBox;
    edPolyOrder: TEdit;
    cbTWChi: TComboBox;
    cbPWChiSqr: TRzCheckBox;
    btnAdvFitSettings: TRzBitBtn;
    cbSmooth: TRzCheckBox;
    RzPanel7: TRzPanel;
    rgPolarisation: TRzRadioGroup;
    pnlWaveParams: TRzPanel;
    Label9: TLabel;
    Label10: TLabel;
    Label11: TLabel;
    Label12: TLabel;
    edStartL: TEdit;
    edEndL: TEdit;
    edTheta: TEdit;
    edDL: TEdit;
    pnlAngleParams: TRzPanel;
    Label1: TLabel;
    Label2: TLabel;
    Label3: TLabel;
    Label4: TLabel;
    edStartTeta: TEdit;
    edEndTeta: TEdit;
    edWidth: TEdit;
    edLambda: TEdit;
    cb2Theta: TRzCheckBox;
    rgCalcMode: TRzRadioGroup;
    RzGroupBox2: TRzGroupBox;
    edN: TEdit;
    cbSolveScale: TRzCheckBox;
    lblScaleWindow: TLabel;
    edScaleWindow: TEdit;
    cbFreePeriod: TRzCheckBox;
    edPeriodWindow: TEdit;
    lblPeriodWindow: TLabel;
    procedure rgCalcModeChanging(Sender: TObject; NewIndex: Integer;
      var AllowChange: Boolean);
    procedure rgCalcModeClick(Sender: TObject);
    procedure cb2ThetaClick(Sender: TObject);
    procedure rgFittingModeClick(Sender: TObject);
    procedure btnAdvFitSettingsClick(Sender: TObject);
  private
    FOnCalcModeChange: TNotifyEvent;
    FOnFittingModeChange: TNotifyEvent;
    FOnAdvancedSettings: TAdvancedSettingsEvent;
    function GetCalcMode: Integer;
    function GetFittingMode: TFittingMode;
    function GetPolarisation: Integer;
    function GetIs2Theta: Boolean;
    function GetIsPWChiSqr: Boolean;
    function GetThetaWeightIndex: Integer;
    function GetLambda: Double;
    function GetResolution: Double;
    function GetSolveScale: Boolean;
    function GetScaleWindow: Double;
  public
    /// <summary>The engine's window from the fraction the operator types:
    /// log10(1 + w), the conversion unit_MCPFit.ParseFitParams makes for
    /// "scale_solve_window", so the same number means the same fit.</summary>
    class function ScaleWindowToLog(const Window: Double): Single; static;

    procedure LoadFromINI(INF: TMemIniFile);
    procedure ApplyModeSettings;
    procedure SaveToINI(INF: TMemIniFile);
    procedure ReadFitParams(var Params: TFitParams);
    procedure FillCalcThreadParams(var Params: TCalcThreadParams);
    procedure GetAxisRange(var AMin, AMax: Single);
    procedure LoadAdvancedParams(INF: TMemIniFile; var Params: TFitParams);
    procedure SaveAdvancedParams(INF: TMemIniFile; const Params: TFitParams);
    /// <summary>Sets the wavelength field (Angstrom), as an imported file that
    /// states its own wavelength does, so the operator need not type it.</summary>
    procedure SetLambda(const Value: Double);

    property CalcMode: Integer read GetCalcMode;
    property FittingMode: TFittingMode read GetFittingMode;
    property Polarisation: Integer read GetPolarisation;
    property Is2Theta: Boolean read GetIs2Theta;
    /// <summary>The wavelength field (Angstrom), 0 when it does not parse.</summary>
    property Lambda: Double read GetLambda;
    /// <summary>The theta-scan resolution field (deg FWHM), 0 when it does not parse.</summary>
    property Resolution: Double read GetResolution;
    property IsPWChiSqr: Boolean read GetIsPWChiSqr;
    property ThetaWeightIndex: Integer read GetThetaWeightIndex;
    /// <summary>Solve the measured scale inside the chi-squared.</summary>
    property SolveScale: Boolean read GetSolveScale;
    /// <summary>The solved-scale window as a fraction (0.2 = within x1.2 of
    /// the anchor; 0 pins it). Raises when the field is not a number >= 0.</summary>
    property ScaleWindow: Double read GetScaleWindow;
    /// <summary>ScaleWindow, or DEF_SCALE_SOLVE_WINDOW when the field is not
    /// a number >= 0: for a save or a recalculation, which must not fail on
    /// a field only a fit is refused for.</summary>
    function ScaleWindowOrDefault: Double;

    property OnCalcModeChange: TNotifyEvent read FOnCalcModeChange write FOnCalcModeChange;
    property OnFittingModeChange: TNotifyEvent read FOnFittingModeChange write FOnFittingModeChange;
    property OnAdvancedSettings: TAdvancedSettingsEvent read FOnAdvancedSettings write FOnAdvancedSettings;
  end;

implementation

uses
  System.Math;

{$R *.dfm}

const
  { The window is kept in the INI in the invariant format, so a project
    saved under one locale reads back under another. }
  INI_SECTION_SCALE = 'FIT';
  INI_SOLVE_SCALE   = 'SolveScale';
  INI_SCALE_WINDOW  = 'ScaleWindow';
  INI_FREE_PERIOD   = 'FreePeriod';
  INI_PERIOD_WINDOW = 'PeriodWindow';   // per cent, invariant format
  DEF_PERIOD_WINDOW = 10;   // the fitting procedure bounds the period at +/- 10 %

function ReadPeriodWindow(INF: TMemIniFile): Double;
begin
  Result := StrToFloatDef(INF.ReadString(INI_SECTION_SCALE, INI_PERIOD_WINDOW, ''),
    DEF_PERIOD_WINDOW, TFormatSettings.Invariant);
  if Result <= 0 then
    Result := DEF_PERIOD_WINDOW;
end;

function ReadScaleWindow(INF: TMemIniFile): Double;
begin
  Result := StrToFloatDef(INF.ReadString(INI_SECTION_SCALE, INI_SCALE_WINDOW, ''),
    DEF_SCALE_SOLVE_WINDOW, TFormatSettings.Invariant);
  if Result < 0 then
    Result := DEF_SCALE_SOLVE_WINDOW;
end;

{ TfrmCalcSettings }

function TfrmCalcSettings.GetCalcMode: Integer;
begin
  Result := rgCalcMode.ItemIndex;
end;

function TfrmCalcSettings.GetFittingMode: TFittingMode;
begin
  Result := TFittingMode(rgFittingMode.ItemIndex);
end;

function TfrmCalcSettings.GetPolarisation: Integer;
begin
  Result := rgPolarisation.ItemIndex;
end;

procedure TfrmCalcSettings.SetLambda(const Value: Double);
begin
  { FillCalcThreadParams reads the field back with StrToFloat in the system
    locale, so it is written in the same locale }
  edLambda.Text := FloatToStr(Value);
end;

function TfrmCalcSettings.GetIs2Theta: Boolean;
begin
  Result := cb2Theta.Checked;
end;

function TfrmCalcSettings.GetLambda: Double;
begin
  { the same locale FillCalcThreadParams reads the field in }
  Result := StrToFloatDef(edLambda.Text, 0);
end;

function TfrmCalcSettings.GetResolution: Double;
begin
  Result := StrToFloatDef(edWidth.Text, 0);
end;

class function TfrmCalcSettings.ScaleWindowToLog(const Window: Double): Single;
begin
  Result := System.Math.Log10(1 + Window);
end;

function TfrmCalcSettings.GetSolveScale: Boolean;
begin
  Result := cbSolveScale.Checked;
end;

function TfrmCalcSettings.GetScaleWindow: Double;
begin
  { the system locale, as every other number field of the frame }
  Result := StrToFloat(Trim(edScaleWindow.Text));
  if Result < 0 then
    raise EConvertError.CreateFmt('The scale window cannot be negative (%s): ' +
      'it is the fraction the solved scale may differ from the anchored one',
      [edScaleWindow.Text]);
end;

function TfrmCalcSettings.ScaleWindowOrDefault: Double;
begin
  if not TryStrToFloat(Trim(edScaleWindow.Text), Result) or (Result < 0) then
    Result := DEF_SCALE_SOLVE_WINDOW;
end;

function TfrmCalcSettings.GetIsPWChiSqr: Boolean;
begin
  Result := cbPWChiSqr.Checked;
end;

function TfrmCalcSettings.GetThetaWeightIndex: Integer;
begin
  Result := cbTWChi.ItemIndex;
end;

procedure TfrmCalcSettings.rgCalcModeChanging(Sender: TObject;
  NewIndex: Integer; var AllowChange: Boolean);
begin
  case NewIndex of
    0:
      begin
        pnlAngleParams.Enabled := True;
        pnlWaveParams.Enabled := False;
      end;
    1:
      begin
        pnlAngleParams.Enabled := False;
        pnlWaveParams.Enabled := True;
      end;
  end;
  AllowChange := True;
end;

procedure TfrmCalcSettings.rgCalcModeClick(Sender: TObject);
begin
  if Assigned(FOnCalcModeChange) then
    FOnCalcModeChange(Self);
end;

procedure TfrmCalcSettings.cb2ThetaClick(Sender: TObject);
begin
  if Assigned(FOnCalcModeChange) then
    FOnCalcModeChange(Self);
end;

procedure TfrmCalcSettings.rgFittingModeClick(Sender: TObject);
begin
  cbSmooth.Enabled := FittingMode = fmIrregular;
  edPolyOrder.Enabled := FittingMode = fmPoly;
  lblPolyOrder.Enabled := edPolyOrder.Enabled;
  { TLFPSO_Poly.RangeSeed is its XSeed: the polynomial engine always seeds
    around the start model, so the box would change nothing there. }
  cbSeedRange.Enabled := FittingMode <> fmPoly;
  cbFreePeriod.Enabled := FittingMode = fmPeriodic;
  edPeriodWindow.Enabled := cbFreePeriod.Enabled;
  lblPeriodWindow.Enabled := cbFreePeriod.Enabled;
  if Assigned(FOnFittingModeChange) then
    FOnFittingModeChange(Self);
end;

procedure TfrmCalcSettings.btnAdvFitSettingsClick(Sender: TObject);
var
  Params: TFitParams;
begin
  if Assigned(FOnAdvancedSettings) then
    FOnAdvancedSettings(Self, Params);
end;

procedure TfrmCalcSettings.LoadFromINI(INF: TMemIniFile);
var
  FitMode: Integer;
  Periodic, Poly: Boolean;
begin
  edN.Text := INF.ReadString('PARAMS', 'N', '1000');
  rgCalcMode.ItemIndex := INF.ReadInteger('PARAMS', 'Mode', 0);
  rgPolarisation.ItemIndex := INF.ReadInteger('PARAMS', 'Polarisation', 0);

  edStartTeta.Text := INF.ReadString('ANGLE', 'Start', '0.01');
  edEndTeta.Text := INF.ReadString('ANGLE', 'End', '5');
  edLambda.Text := INF.ReadString('ANGLE', 'lambbda', '1.54043');
  edWidth.Text := INF.ReadString('ANGLE', 'width', '0.015');
  cb2Theta.Checked := INF.ReadBool('ANGLE', '2teta', True);

  edStartL.Text := INF.ReadString('WAVE', 'Start', '1');
  edEndL.Text := INF.ReadString('WAVE', 'End', '10');
  edTheta.Text := INF.ReadString('WAVE', 'Teta', '85');
  edDL.Text := INF.ReadString('WAVE', 'width', '0');

  edFIter.Text := INF.ReadString('FIT', 'Namx', '100');
  edFPopulation.Text := INF.ReadString('FIT', 'Pop', '1000');

  FitMode := INF.ReadInteger('FIT', 'Mode', -1);
  if FitMode = -1 then
  begin
    Periodic := INF.ReadBool('FIT', 'Periodic', False);
    Poly     := INF.ReadBool('FIT', 'Poly', False);

    if Periodic then rgFittingMode.ItemIndex := Ord(fmPeriodic);
    if Poly then rgFittingMode.ItemIndex := Ord(fmPoly);
  end
  else
    rgFittingMode.ItemIndex := FitMode;

  edPolyOrder.Text := INF.ReadString('FIT', 'PolyOrder', '1');
  cbPWChiSqr.Checked := INF.ReadBool('FIT', 'PWChi', True);
  cbTWChi.ItemIndex := INF.ReadInteger('FIT', 'TWChi', 0);
  cbSeedRange.Checked := INF.ReadBool('LFPSO', 'SeedRange', False);
  cbLFPSOShake.Checked := INF.ReadBool('LFPSO', 'Shake', True);
  cbSmooth.Checked := INF.ReadBool('LFPSO', 'Smooth', False);
  { A project saved before the option existed opens with the server's
    defaults: solved, window 0.2. }
  cbSolveScale.Checked := INF.ReadBool(INI_SECTION_SCALE, INI_SOLVE_SCALE, True);
  edScaleWindow.Text := FloatToStr(ReadScaleWindow(INF));
  { A project saved before the option existed holds its period, as it did. }
  cbFreePeriod.Checked := INF.ReadBool(INI_SECTION_SCALE, INI_FREE_PERIOD, False);
  edPeriodWindow.Text := FloatToStr(ReadPeriodWindow(INF));

  ApplyModeSettings;
end;

procedure TfrmCalcSettings.ApplyModeSettings;
begin
  case rgCalcMode.ItemIndex of
    0:
      begin
        pnlAngleParams.Enabled := True;
        pnlWaveParams.Enabled := False;
      end;
    1:
      begin
        pnlAngleParams.Enabled := False;
        pnlWaveParams.Enabled := True;
      end;
  end;

  cbSmooth.Enabled := FittingMode = fmIrregular;
  edPolyOrder.Enabled := FittingMode = fmPoly;
  lblPolyOrder.Enabled := edPolyOrder.Enabled;
  { TLFPSO_Poly.RangeSeed is its XSeed: the polynomial engine always seeds
    around the start model, so the box would change nothing there. }
  cbSeedRange.Enabled := FittingMode <> fmPoly;
  cbFreePeriod.Enabled := FittingMode = fmPeriodic;
  edPeriodWindow.Enabled := cbFreePeriod.Enabled;
  lblPeriodWindow.Enabled := cbFreePeriod.Enabled;

  if Assigned(FOnCalcModeChange) then
    FOnCalcModeChange(Self);
  if Assigned(FOnFittingModeChange) then
    FOnFittingModeChange(Self);
end;

procedure TfrmCalcSettings.SaveToINI(INF: TMemIniFile);
begin
  INF.WriteString('PARAMS', 'N', edN.Text);
  INF.WriteInteger('PARAMS', 'Mode', rgCalcMode.ItemIndex);
  INF.WriteInteger('PARAMS', 'Polarisation', rgPolarisation.ItemIndex);

  INF.WriteString('ANGLE', 'Start', edStartTeta.Text);
  INF.WriteString('ANGLE', 'End', edEndTeta.Text);
  INF.WriteString('ANGLE', 'lambbda', edLambda.Text);
  INF.WriteString('ANGLE', 'width', edWidth.Text);
  INF.WriteBool('ANGLE', '2teta', cb2Theta.Checked);

  INF.WriteString('WAVE', 'Start', edStartL.Text);
  INF.WriteString('WAVE', 'End', edEndL.Text);
  INF.WriteString('WAVE', 'Teta', edTheta.Text);
  INF.WriteString('WAVE', 'width', edDL.Text);

  INF.WriteString('FIT', 'Namx', edFIter.Text);
  INF.WriteString('FIT', 'Pop', edFPopulation.Text);
  INF.WriteInteger('FIT', 'Mode', rgFittingMode.ItemIndex);
  INF.WriteString('FIT', 'PolyOrder', edPolyOrder.Text);

  INF.WriteBool('FIT', 'PWChi', cbPWChiSqr.Checked);
  INF.WriteInteger('FIT', 'TWChi', cbTWChi.ItemIndex);

  INF.WriteBool('LFPSO', 'Shake', cbLFPSOShake.Checked);
  INF.WriteBool('LFPSO', 'SeedRange', cbSeedRange.Checked);
  INF.WriteBool('LFPSO', 'Smooth', cbSmooth.Checked);

  { A field that does not parse is saved as the default rather than failing
    the save; the next fit refuses it in ReadFitParams. }
  INF.WriteBool(INI_SECTION_SCALE, INI_SOLVE_SCALE, cbSolveScale.Checked);
  INF.WriteString(INI_SECTION_SCALE, INI_SCALE_WINDOW,
    FloatToStr(ScaleWindowOrDefault, TFormatSettings.Invariant));
  INF.WriteBool(INI_SECTION_SCALE, INI_FREE_PERIOD, cbFreePeriod.Checked);
  INF.WriteString(INI_SECTION_SCALE, INI_PERIOD_WINDOW,
    FloatToStr(StrToFloatDef(Trim(edPeriodWindow.Text), DEF_PERIOD_WINDOW),
    TFormatSettings.Invariant));
end;

procedure TfrmCalcSettings.ReadFitParams(var Params: TFitParams);
begin
  Params.NMax := StrToInt(edFIter.Text);
  Params.Pop := StrToInt(edFPopulation.Text);
  Params.Shake := cbLFPSOShake.Checked;
  Params.ThetaWeight := cbTWChi.ItemIndex;
  Params.RangeSeed := cbSeedRange.Checked;
  { 1..9: TProjectData.Poly holds ten coefficients and the profile editor
    offers orders 1 to 9. The box is one digit, but it can be empty, and a
    project file can carry anything. }
  Params.MaxPOrder := EnsureRange(StrToIntDef(Trim(edPolyOrder.Text), 1), 1, 9);
  Params.Smooth := cbSmooth.Checked;
  Params.SolveScale := SolveScale;
  Params.ScaleWindowLog := ScaleWindowToLog(ScaleWindow);
  Params.FreePeriod := cbFreePeriod.Checked;
  Params.PeriodWindow := StrToFloat(Trim(edPeriodWindow.Text)) / 100;
  if Params.FreePeriod and (Params.PeriodWindow <= 0) then
    raise EConvertError.CreateFmt('The period window must be positive (%s %%): it is ' +
      'how far each period may move from its start value', [edPeriodWindow.Text]);
end;

procedure TfrmCalcSettings.FillCalcThreadParams(var Params: TCalcThreadParams);
begin
  if cb2Theta.Checked then
    Params.k := 2
  else
    Params.k := 1;

  if rgPolarisation.ItemIndex = 0 then
    Params.P := cmS
  else
    Params.P := cmSP;

  case rgCalcMode.ItemIndex of
    0:
      begin
        Params.Mode := cmTheta;
        Params.Lambda := StrToFloat(edLambda.Text);
        Params.StartT := StrToFloat(edStartTeta.Text);
        Params.EndT := StrToFloat(edEndTeta.Text);
        Params.DT := StrToFloat(edWidth.Text);
      end;
    1:
      begin
        Params.Mode := cmLambda;
        Params.Theta := StrToFloat(edTheta.Text);
        Params.StartL := StrToFloat(edStartL.Text);
        Params.EndL := StrToFloat(edEndL.Text);
        Params.DW := StrToFloat(edDL.Text);
      end;
  end;

  Params.RF := rfError;
  Params.N := StrToInt(edN.Text);
  Params.MVAWindow := 10;
end;

procedure TfrmCalcSettings.GetAxisRange(var AMin, AMax: Single);
begin
  case rgCalcMode.ItemIndex of
    0:
      begin
        AMin := StrToFloat(edStartTeta.Text);
        AMax := StrToFloat(edEndTeta.Text);
      end;
    1:
      begin
        AMin := StrToFloat(edStartL.Text);
        AMax := StrToFloat(edEndL.Text);
      end;
  end;
end;

procedure TfrmCalcSettings.LoadAdvancedParams(INF: TMemIniFile; var Params: TFitParams);
begin
  Params.Tolerance := StrToFloat(INF.ReadString('FIT', 'Tol', '0.005'));
  Params.MovAvgWindow := StrToFloat(INF.ReadString('FIT', 'Window', '0.05'));
  Params.Vmax := StrToFloat(INF.ReadString('LFPSO', 'Vmax', '0.1'));
  Params.JammingMax := StrToInt(INF.ReadString('LFPSO', 'Jmax', '1'));
  Params.ReInitMax := StrToInt(INF.ReadString('LFPSO', 'RIMax', '3'));
  Params.KChiSqr := StrToFloat(INF.ReadString('LFPSO', 'kChi', '1.41'));
  Params.KVmax := StrToFloat(INF.ReadString('LFPSO', 'kVmax', '1.41'));
  Params.w1 := StrToFloat(INF.ReadString('LFPSO', 'w1', '0.3'));
  Params.w2 := StrToFloat(INF.ReadString('LFPSO', 'w2', '0.3'));
  Params.AdaptVel := INF.ReadBool('LFPSO', 'AdaptV', False);
  Params.UseConstriction := INF.ReadBool('LFPSO', 'Constriction', True);
  Params.SmoothWindow := INF.ReadInteger('LFPSO', 'SmoothWindow', -1);
  Params.Ksxr := StrToFloat(INF.ReadString('LFPSO', 'Ksxr', '0.2'));
  Params.PolyFactor := INF.ReadInteger('LFPSO', 'PolyFactor', 10);
  { The same keys LoadFromINI puts in the checkbox and the field; the
    frame's controls own them and SaveToINI writes them. }
  Params.SolveScale := INF.ReadBool(INI_SECTION_SCALE, INI_SOLVE_SCALE, True);
  Params.ScaleWindowLog := ScaleWindowToLog(ReadScaleWindow(INF));
  Params.FreePeriod := INF.ReadBool(INI_SECTION_SCALE, INI_FREE_PERIOD, False);
  Params.PeriodWindow := ReadPeriodWindow(INF) / 100;
end;

procedure TfrmCalcSettings.SaveAdvancedParams(INF: TMemIniFile; const Params: TFitParams);
begin
  INF.WriteFloat('FIT', 'Window', Params.MovAvgWindow);
  INF.WriteString('FIT', 'Tol', Params.Tolerance.ToString);
  INF.WriteString('LFPSO', 'Vmax', Params.Vmax.ToString);
  INF.WriteString('LFPSO', 'Jmax', Params.JammingMax.ToString);
  INF.WriteString('LFPSO', 'RIMax', Params.ReInitMax.ToString);
  INF.WriteString('LFPSO', 'kChi', Params.KChiSqr.ToString);
  INF.WriteString('LFPSO', 'kVmax', Params.KVmax.ToString);
  INF.WriteString('LFPSO', 'w1', Params.w1.ToString);
  INF.WriteString('LFPSO', 'w2', Params.w2.ToString);
  INF.WriteBool('LFPSO', 'AdaptV', Params.AdaptVel);
  INF.WriteBool('LFPSO', 'Constriction', Params.UseConstriction);
  INF.WriteInteger('LFPSO', 'SmoothWindow', Params.SmoothWindow);
  INF.WriteString('LFPSO', 'Ksxr', Params.Ksxr.ToString);
  INF.WriteInteger('LFPSO', 'PolyFactor', Params.PolyFactor);
  { SolveScale and the scale window are not written here: SaveToINI writes
    them from the controls, which a stored Params may lag until the next fit. }
end;

end.
