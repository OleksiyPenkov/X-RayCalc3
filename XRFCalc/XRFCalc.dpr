program XRFCalc;

uses
  Vcl.Forms,
  frm_XRFMain in 'frm_XRFMain.pas' {frmXRFMain},
  unit_xrf_thread in 'unit_xrf_thread.pas';

begin
  Application.Initialize;
  Application.MainFormOnTaskbar := True;
  Application.Title := 'XRFCalc';
  Application.CreateForm(TfrmXRFMain, frmXRFMain);
  Application.Run;
end.
