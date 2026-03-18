(* *****************************************************************************
  *
  *   X-Ray Calc 3
  *
  *   Copyright (C) 2001-2025 Oleksiy Penkov
  *   e-mail: oleksiypenkov@intl.zju.edu.cn
  *
  ****************************************************************************** *)

unit frm_CrashReport;

interface

uses
  Winapi.Windows, System.SysUtils, System.Classes,
  Vcl.Controls, Vcl.Forms, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Clipbrd;

type
  TfrmCrashReport = class(TForm)
    pnlTop: TPanel;
    lblTitle: TLabel;
    lblInfo: TLabel;
    mmoReport: TMemo;
    pnlButtons: TPanel;
    btnCopy: TButton;
    btnClose: TButton;
    procedure btnCopyClick(Sender: TObject);
    procedure btnCloseClick(Sender: TObject);
  private
    FReportText: string;
    procedure SetReportText(const Value: string);
  public
    property ReportText: string read FReportText write SetReportText;
  end;

implementation

{$R *.dfm}

procedure TfrmCrashReport.SetReportText(const Value: string);
begin
  FReportText := Value;
  mmoReport.Text := Value;
end;

procedure TfrmCrashReport.btnCopyClick(Sender: TObject);
begin
  Clipboard.AsText := mmoReport.Text;
  btnCopy.Caption := 'Copied!';
end;

procedure TfrmCrashReport.btnCloseClick(Sender: TObject);
begin
  ModalResult := mrClose;
end;

end.
