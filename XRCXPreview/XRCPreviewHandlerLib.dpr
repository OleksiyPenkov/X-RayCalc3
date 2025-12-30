library XRCPreviewHandlerLib;

uses
  ComServ,
  PreviewHandler in 'PreviewHandler.pas' {PreviewHandler: CoClass},
  XRCPreviewHandler in 'XRCPreviewHandler.pas',
  frame_Chart in 'frame_Chart.pas' {frmChart: TFrame};

exports
  DllGetClassObject,
  DllCanUnloadNow,
  DllRegisterServer,
  DllUnregisterServer,
  DllInstall;

{$R *.RES}

begin
end.
