(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2023 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)
unit frm_about;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, RzStatus, Vcl.StdCtrls, Vcl.Buttons,
  RzLabel, Vcl.ExtCtrls;

type
  TfrmAbout = class(TForm)
    RzLabel1: TRzLabel;
    BitBtn1: TBitBtn;
    RzVersionInfo: TRzVersionInfo;
    lblCopyRight: TLabel;
    Label1: TLabel;
    RzURLLabel1: TRzURLLabel;
    Image1: TImage;
    lblVersionInfo: TLabel;
    procedure FormCreate(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAbout: TfrmAbout;


resourcestring
  rstrAppVersionInfo   = 'Version: %s';
  rstrAppVersionInfo64 = 'Version: %s x64';
  rstrAppCopyRight = '(c) 2001-%d Oleksiy Penkov';
implementation

{$R *.dfm}

procedure TfrmAbout.FormCreate(Sender: TObject);
begin
  {$IFDEF  WIN64}
     lblVersionInfo.Caption := Format(rstrAppVersionInfo64, [RzVersionInfo.FileVersion]);
  {$ELSE}
    lblVersionInfo.Caption := Format(rstrAppVersionInfo, [RzVersionInfo.FileVersion]);
  {$ENDIF}

  lblCopyRight.Caption := Format(rstrAppCopyRight, [CurrentYear]);
end;

end.
