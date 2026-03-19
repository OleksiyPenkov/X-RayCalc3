program XRFCalc;

uses
  Vcl.Forms,
  frm_XRFCalcMain in 'Forms\frm_XRFCalcMain.pas' {frmXRFCalcMain},
  frame_CurvesView in 'Views\frame_CurvesView.pas' {frameCurvesView: TFrame},
  frame_InfoView in 'Views\frame_InfoView.pas' {frameInfoView: TFrame},
  frame_ProgressView in 'Views\frame_ProgressView.pas' {frameProgressView: TFrame},
  frame_CompareView in 'Views\frame_CompareView.pas' {frameCompareView: TFrame},
  xrfcalc_unit_loader in 'Units\xrfcalc_unit_loader.pas',
  xrfcalc_unit_runner in 'Units\xrfcalc_unit_runner.pas',
  frame_RunConfig in 'Views\frame_RunConfig.pas' {frmRunConfig: TFrame},
  unit_universal_io in '..\Shared\Universal\unit_universal_io.pas',
  unit_xrf_lines in '..\Shared\Universal\unit_xrf_lines.pas',
  unit_xrfx_package in '..\Shared\Universal\unit_xrfx_package.pas',
  unit_universal_types in '..\Shared\Universal\unit_universal_types.pas';

{$R *.res}
{$R XRFCalcIcons.RES}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.Title := 'XRFCalc';
  Application.CreateForm(TfrmXRFCalcMain, frmXRFCalcMain);
  Application.Run;
end.
