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
    RzVersionInfo1: TRzVersionInfo;
    RzVersionInfoStatus2: TRzVersionInfoStatus;
    RzLabel2: TLabel;
    Label1: TLabel;
    RzURLLabel1: TRzURLLabel;
    Image1: TImage;
  private
    { Private declarations }
  public
    { Public declarations }
  end;

var
  frmAbout: TfrmAbout;

implementation

{$R *.dfm}

end.
