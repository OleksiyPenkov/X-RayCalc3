unit frm_FitSettings;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.ExtCtrls, RzPanel, RzButton,
  RzRadChk, Vcl.StdCtrls, RzTabs, unit_Types, Vcl.Buttons, unit_StaticTip,
  Vcl.Mask, RzEdit, Vcl.Samples.Spin;

type
  TfrmFitSettings = class(TForm)
    RzPanel1: TRzPanel;
    rzpnl1: TRzPanel;
    RzGroupBox1: TRzGroupBox;
    edFitTolerance: TEdit;
    Label20: TLabel;
    cbAdaptiveVelocity: TRzCheckBox;
    cbConstriction: TRzCheckBox;
    RzGroupBox2: TRzGroupBox;
    Label16: TLabel;
    edFVmax: TEdit;
    Label18: TLabel;
    edLFPSOOmega1: TEdit;
    Label19: TLabel;
    edLFPSOOmega2: TEdit;
    edLFPSOSkip: TEdit;
    Label15: TLabel;
    edLFPSORImax: TEdit;
    Label17: TLabel;
    Label13: TLabel;
    edLFPSOChiFactor: TEdit;
    Label14: TLabel;
    edLFPSOkVmax: TEdit;
    RzGroupBox3: TRzGroupBox;
    Label1: TLabel;
    edIrrSmoothWindow: TEdit;
    btnSave: TRzBitBtn;
    btnCancel: TBitBtn;
    RzGroupBox4: TRzGroupBox;
    sePolyFactor: TSpinEdit;
    Label8: TLabel;
    Label10: TLabel;
    edKsxr: TEdit;
    Tip: TStaticTip;
    procedure ShowParamHint(Sender: TObject);
  private
    { Private declarations }
  public
    { Public declarations }
    procedure ShowSettings(var Params: TFitParams);
  end;

var
  frmFitSettings: TfrmFitSettings;

implementation

{$R *.dfm}

{ TfrmFitSettings }

procedure TfrmFitSettings.ShowParamHint(Sender: TObject);
begin
  Tip.Caption := (Sender as TControl).Hint;
end;

procedure TfrmFitSettings.ShowSettings(var Params: TFitParams);
begin
  edFVmax.Text            := FloatToStrF(Params.Vmax, ffGeneral, 7, 0);
  edLFPSOSkip.Text        := Params.JammingMax.ToString;
  edLFPSORImax.Text       := Params.ReInitMax.ToString;
  edLFPSOChiFactor.Text   := FloatToStrF(Params.KChiSqr, ffGeneral, 7, 0);
  edLFPSOkVmax.Text       := FloatToStrF(Params.KVmax, ffGeneral, 7, 0);
  edLFPSOOmega1.Text      := FloatToStrF(Params.w1, ffGeneral, 7, 0);
  edLFPSOOmega2.Text      := FloatToStrF(Params.w2, ffGeneral, 7, 0);
  edFitTolerance.Text     := FloatToStrF(Params.Tolerance, ffGeneral, 7, 0);
  edIrrSmoothWindow.Text  := Params.SmoothWindow.ToString;

  sePolyFactor.Value      := Params.PolyFactor;
  edKsxr.Text             := FloatToStrF(Params.Ksxr, ffGeneral, 7, 0);

  cbAdaptiveVelocity.Checked := Params.AdaptVel;
  cbConstriction.Checked     := Params.UseConstriction;

  if ShowModal = mrOk then
  begin
    Params.Vmax            := StrToFloat(edFVmax.Text);
    Params.JammingMax      := StrToInt(edLFPSOSkip.Text);
    Params.ReInitMax       := StrToInt(edLFPSORImax.Text);
    Params.KChiSqr         := StrToFloat(edLFPSOChiFactor.Text);
    Params.KVmax           := StrToFloat(edLFPSOkVmax.Text);
    Params.w1              := StrToFloat(edLFPSOOmega1.Text);
    Params.w2              := StrToFloat(edLFPSOOmega2.Text);
    Params.Tolerance       := StrToFloat(edFitTolerance.Text);
    Params.AdaptVel        := cbAdaptiveVelocity.Checked;
    Params.UseConstriction := cbConstriction.Checked;
    Params.SmoothWindow    := StrToInt(edIrrSmoothWindow.Text);

    Params.PolyFactor      := sePolyFactor.Value;
    Params.Ksxr            := StrToFloat(edKsxr.Text);

  end;
end;

end.
