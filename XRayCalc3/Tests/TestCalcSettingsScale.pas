unit TestCalcSettingsScale;

(* The GUI's solved-scale option (Fitting - Solve scale in chi2, Window).

   The MCP server sets TFitParams.SolveScale from "scale_solve" and
   ScaleWindowLog from "scale_solve_window" w as log10(1 + w)
   (unit_MCPFit.ParseFitParams; TestMCPFit covers that side). The GUI must
   make the same conversion from the same number, so a fit made in the
   desktop program and one made through the server are the same fit, and the
   choice must survive the project file. *)

interface

uses
  DUnitX.TestFramework;

type
  [TestFixture]
  TTestCalcSettingsScale = class
  public
    [Test] procedure WindowMapsToLog10OnePlusW;
    [Test] procedure ReadFitParams_SetsSolveScaleAndWindow;
    [Test] procedure ReadFitParams_Unchecked_Anchors;
    [Test] procedure ReadFitParams_NegativeWindowRefused;
    [Test] procedure Defaults_MatchTheServer;
    [Test] procedure Ini_RoundTrip;
    [Test] procedure Ini_ProjectWithoutTheKeys_OpensSolvedAtDefault;
  end;

implementation

uses
  System.SysUtils, System.Math, System.IniFiles, System.IOUtils, Vcl.Controls, Vcl.Forms,
  unit_Types, frame_CalcSettings;

type
  { TCustomFrame.CreateParams parents a frame without a Parent to
    Application.Handle, which is 0 in this console runner, and the DFM needs
    handles while it streams in. This one takes the window it was created
    parented to instead. }
  THostedCalcSettings = class(TfrmCalcSettings)
  protected
    procedure CreateParams(var Params: TCreateParams); override;
  end;

procedure THostedCalcSettings.CreateParams(var Params: TCreateParams);
begin
  inherited;
  if (Parent = nil) and (ParentWindow <> 0) then
    Params.WndParent := ParentWindow;
end;

{ The host is never shown; it destroys its child controls, so freeing it
  frees the frame. }
function NewSettings(out Host: TForm): TfrmCalcSettings;
begin
  Host := TForm.CreateNew(nil);
  Result := THostedCalcSettings.CreateParented(Host.Handle);
  Result.Parent := Host;
end;

function NewIni: TMemIniFile;
begin
  { never written to disk: UpdateFile is not called }
  Result := TMemIniFile.Create(TPath.Combine(TPath.GetTempPath, 'xrc_scale_test.ini'));
end;

procedure TTestCalcSettingsScale.WindowMapsToLog10OnePlusW;
begin
  Assert.AreEqual(0.0, Double(TfrmCalcSettings.ScaleWindowToLog(0)), 0, '0 pins the scale');
  Assert.AreEqual(Log10(1.2), Double(TfrmCalcSettings.ScaleWindowToLog(0.2)), 1E-7);
  Assert.AreEqual(Log10(1.7), Double(TfrmCalcSettings.ScaleWindowToLog(0.7)), 1E-7);
  Assert.AreEqual(Log10(2.0), Double(TfrmCalcSettings.ScaleWindowToLog(1.0)), 1E-7);
end;

procedure TTestCalcSettingsScale.ReadFitParams_SetsSolveScaleAndWindow;
var
  F: TfrmCalcSettings;
  Host: TForm;
  P: TFitParams;
begin
  F := NewSettings(Host);
  try
    F.cbSolveScale.Checked := True;
    F.edScaleWindow.Text := FloatToStr(0.7);
    P := Default(TFitParams);
    F.ReadFitParams(P);
    Assert.IsTrue(P.SolveScale);
    Assert.AreEqual(Log10(1.7), Double(P.ScaleWindowLog), 1E-7,
      'the window typed means what the same number means in a request');
  finally
    Host.Free;
  end;
end;

procedure TTestCalcSettingsScale.ReadFitParams_Unchecked_Anchors;
var
  F: TfrmCalcSettings;
  Host: TForm;
  P: TFitParams;
begin
  F := NewSettings(Host);
  try
    F.cbSolveScale.Checked := False;
    P := Default(TFitParams);
    P.SolveScale := True;
    F.ReadFitParams(P);
    Assert.IsFalse(P.SolveScale);
  finally
    Host.Free;
  end;
end;

procedure TTestCalcSettingsScale.ReadFitParams_NegativeWindowRefused;
var
  F: TfrmCalcSettings;
  Host: TForm;
  P: TFitParams;
begin
  F := NewSettings(Host);
  try
    F.edScaleWindow.Text := FloatToStr(-0.1);
    P := Default(TFitParams);
    Assert.WillRaise(
      procedure
      begin
        F.ReadFitParams(P);
      end, EConvertError);
    Assert.AreEqual(Double(DEF_SCALE_SOLVE_WINDOW), F.ScaleWindowOrDefault, 1E-12,
      'a save or a recalculation falls back to the default instead');
  finally
    Host.Free;
  end;
end;

procedure TTestCalcSettingsScale.Defaults_MatchTheServer;
var
  F: TfrmCalcSettings;
  Host: TForm;
begin
  Assert.AreEqual(Double(0.2), Double(DEF_SCALE_SOLVE_WINDOW), 1E-12, 'unit_MCPFit.DEF_SCALE_SOLVE_WINDOW');
  F := NewSettings(Host);
  try
    Assert.IsTrue(F.SolveScale, 'solved by default, as "scale_solve"');
    Assert.AreEqual(Double(DEF_SCALE_SOLVE_WINDOW), F.ScaleWindow, 1E-12);
  finally
    Host.Free;
  end;
end;

procedure TTestCalcSettingsScale.Ini_RoundTrip;
var
  A, B: TfrmCalcSettings;
  HostA, HostB: TForm;
  INF: TMemIniFile;
  P: TFitParams;
begin
  INF := NewIni;
  A := NewSettings(HostA);
  B := NewSettings(HostB);
  try
    A.cbSolveScale.Checked := False;
    A.edScaleWindow.Text := FloatToStr(0.35);
    A.SaveToINI(INF);

    B.cbSolveScale.Checked := True;
    B.edScaleWindow.Text := '9';
    B.LoadFromINI(INF);
    Assert.IsFalse(B.SolveScale);
    Assert.AreEqual(Double(0.35), B.ScaleWindow, 1E-12);

    { the key is invariant whatever the locale the field is typed in }
    Assert.AreEqual('0.35', INF.ReadString('FIT', 'ScaleWindow', ''));

    P := Default(TFitParams);
    P.SolveScale := True;
    B.LoadAdvancedParams(INF, P);
    Assert.IsFalse(P.SolveScale, 'the project''s fit params follow the file');
    Assert.AreEqual(Log10(1.35), Double(P.ScaleWindowLog), 1E-7);
  finally
    HostB.Free;
    HostA.Free;
    INF.Free;
  end;
end;

procedure TTestCalcSettingsScale.Ini_ProjectWithoutTheKeys_OpensSolvedAtDefault;
var
  F: TfrmCalcSettings;
  Host: TForm;
  INF: TMemIniFile;
  P: TFitParams;
begin
  INF := NewIni;
  F := NewSettings(Host);
  try
    F.cbSolveScale.Checked := False;
    F.edScaleWindow.Text := '5';
    F.LoadFromINI(INF);
    Assert.IsTrue(F.SolveScale);
    Assert.AreEqual(Double(DEF_SCALE_SOLVE_WINDOW), F.ScaleWindow, 1E-12);

    P := Default(TFitParams);
    F.LoadAdvancedParams(INF, P);
    Assert.IsTrue(P.SolveScale);
    Assert.AreEqual(Log10(1.2), Double(P.ScaleWindowLog), 1E-7);
  finally
    Host.Free;
    INF.Free;
  end;
end;

initialization
  TDUnitX.RegisterTestFixture(TTestCalcSettingsScale);

end.
