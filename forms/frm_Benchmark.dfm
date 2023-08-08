object frmBenchmark: TfrmBenchmark
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Benchmark'
  ClientHeight = 409
  ClientWidth = 991
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  FormStyle = fsStayOnTop
  Position = poOwnerFormCenter
  TextHeight = 15
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 985
    Height = 403
    Align = alClient
    BorderOuter = fsGroove
    BorderWidth = 2
    Color = 15987699
    TabOrder = 0
    ExplicitWidth = 977
    ExplicitHeight = 391
    object BitBtn1: TBitBtn
      Left = 896
      Top = 363
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 0
      OnClick = BitBtn1Click
    end
    object Grid: TXRCGrid
      AlignWithMargins = True
      Left = 7
      Top = 7
      Width = 971
      Height = 342
      Margins.Bottom = 50
      Align = alClient
      TabOrder = 1
      AutoFit = False
      Text = #9#9#9#9
      ExplicitWidth = 963
      ExplicitHeight = 330
    end
  end
end
