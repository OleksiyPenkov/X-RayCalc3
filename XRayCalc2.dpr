program XRayCalc2;

uses
  Vcl.Forms,
  frm_Main in 'forms\frm_Main.pas' {frmMain},
  unit_Types in 'units\unit_Types.pas',
  math_complex in 'math\math_complex.pas',
  unit_settings in 'units\unit_settings.pas',
  unit_helpers in 'units\unit_helpers.pas',
  unit_consts in 'units\unit_consts.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.CreateForm(TfrmMain, frmMain);
  Application.Run;
end.
