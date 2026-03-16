unit frm_XRFMain;

interface

uses
  Winapi.Windows, Winapi.Messages,
  System.SysUtils, System.Classes,
  Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Vcl.StdCtrls, Vcl.ComCtrls;

type
  TfrmXRFMain = class(TForm)
    pnlSidebar: TPanel;
    sbConfig: TScrollBox;
    pnlButtons: TPanel;
    splMain: TSplitter;
    pnlCharts: TPanel;
  private
  public
  end;

var
  frmXRFMain: TfrmXRFMain;

implementation

{$R *.dfm}

end.
