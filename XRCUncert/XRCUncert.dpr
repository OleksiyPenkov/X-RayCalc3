program XRCUncert;

uses
  Vcl.Forms,
  frm_UncertMain in 'Forms\frm_UncertMain.pas' {frmUncertMain},
  frm_UncertDetails in 'Forms\frm_UncertDetails.pas' {frmUncertDetails},
  unit_UncertThread in 'Units\unit_UncertThread.pas',
  unit_UncertView in '..\Shared\Bayes\unit_UncertView.pas',
  unit_UncertSession in '..\Shared\Bayes\unit_UncertSession.pas',
  unit_UncertRequest in '..\Shared\Bayes\unit_UncertRequest.pas',
  unit_UncertRun in '..\Shared\Bayes\unit_UncertRun.pas',
  unit_UncertFiles in '..\Shared\Bayes\unit_UncertFiles.pas',
  unit_UncertCounts in '..\Shared\Bayes\unit_UncertCounts.pas';

{$R *.res}

begin
  Application.Initialize;
  Application.MainFormOnTaskBar := True;
  Application.Title := 'XRCUncert';
  Application.CreateForm(TfrmUncertMain, frmUncertMain);
  Application.Run;
end.
