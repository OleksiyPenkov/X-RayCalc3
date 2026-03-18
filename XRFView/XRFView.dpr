program XRFView;

uses
  Vcl.Forms,
  frm_XRFViewMain in 'Forms\frm_XRFViewMain.pas' {frmXRFViewMain},
  frame_StructureView in 'Views\frame_StructureView.pas' {frameStructureView: TFrame},
  frame_CurvesView in 'Views\frame_CurvesView.pas' {frameCurvesView: TFrame},
  frame_InfoView in 'Views\frame_InfoView.pas' {frameInfoView: TFrame},
  frame_ProgressView in 'Views\frame_ProgressView.pas' {frameProgressView: TFrame},
  frame_CompareView in 'Views\frame_CompareView.pas' {frameCompareView: TFrame},
  xrfview_unit_loader in 'Units\xrfview_unit_loader.pas',
  xrfview_unit_runner in 'Units\xrfview_unit_runner.pas',
  frm_RunConfig in 'Forms\frm_RunConfig.pas' {frmRunConfig},
  unit_universal_io in '..\Universal\unit_universal_io.pas',
  unit_xrf_lines in '..\Universal\unit_xrf_lines.pas',
  unit_xrfx_package in '..\Universal\unit_xrfx_package.pas',
  unit_universal_types in '..\Universal\unit_universal_types.pas';

{$R *.res}
{$R XRFViewIcons.RES}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.Title := 'XRFView';
  Application.CreateForm(TfrmXRFViewMain, frmXRFViewMain);
  Application.Run;
end.
