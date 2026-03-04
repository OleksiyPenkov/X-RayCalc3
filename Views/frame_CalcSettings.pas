unit frame_CalcSettings;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes, System.IniFiles,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  RzPanel, RzRadGrp, RzRadChk, RzButton,
  unit_Types;

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
  public
    procedure LoadFromINI(INF: TMemIniFile);
    procedure ApplyModeSettings;
    procedure SaveToINI(INF: TMemIniFile);
    procedure ReadFitParams(var Params: TFitParams);
    procedure FillCalcThreadParams(var Params: TCalcThreadParams);
    procedure GetAxisRange(var AMin, AMax: Single);
    procedure LoadAdvancedParams(INF: TMemIniFile; var Params: TFitParams);
    procedure SaveAdvancedParams(INF: TMemIniFile; const Params: TFitParams);

    property CalcMode: Integer read GetCalcMode;
    property FittingMode: TFittingMode read GetFittingMode;
    property Polarisation: Integer read GetPolarisation;
    property Is2Theta: Boolean read GetIs2Theta;
    property IsPWChiSqr: Boolean read GetIsPWChiSqr;
    property ThetaWeightIndex: Integer read GetThetaWeightIndex;

    property OnCalcModeChange: TNotifyEvent read FOnCalcModeChange write FOnCalcModeChange;
    property OnFittingModeChange: TNotifyEvent read FOnFittingModeChange write FOnFittingModeChange;
    property OnAdvancedSettings: TAdvancedSettingsEvent read FOnAdvancedSettings write FOnAdvancedSettings;
  end;

implementation

{$R *.dfm}

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

function TfrmCalcSettings.GetIs2Theta: Boolean;
begin
  Result := cb2Theta.Checked;
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
end;

procedure TfrmCalcSettings.ReadFitParams(var Params: TFitParams);
begin
  Params.NMax := StrToInt(edFIter.Text);
  Params.Pop := StrToInt(edFPopulation.Text);
  Params.Shake := cbLFPSOShake.Checked;
  Params.ThetaWeight := cbTWChi.ItemIndex;
  Params.RangeSeed := cbSeedRange.Checked;
  Params.MaxPOrder := StrToInt(edPolyOrder.Text);
  Params.Smooth := cbSmooth.Checked;
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
  Params.SmoothWindow := INF.ReadInteger('LFPSO', 'SmoothWindow', -1);
  Params.Ksxr := StrToFloat(INF.ReadString('LFPSO', 'Ksxr', '0.2'));
  Params.PolyFactor := INF.ReadInteger('LFPSO', 'PolyFactor', 10);
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
  INF.WriteInteger('LFPSO', 'SmoothWindow', Params.SmoothWindow);
  INF.WriteString('LFPSO', 'Ksxr', Params.Ksxr.ToString);
  INF.WriteInteger('LFPSO', 'PolyFactor', Params.PolyFactor);
end;

end.
