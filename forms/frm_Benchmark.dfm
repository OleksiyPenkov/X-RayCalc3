object frmBenchmark: TfrmBenchmark
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Benchmark'
  ClientHeight = 397
  ClientWidth = 983
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
    Width = 977
    Height = 391
    Align = alClient
    BorderOuter = fsGroove
    BorderWidth = 2
    Color = 15987699
    TabOrder = 0
    ExplicitWidth = 969
    ExplicitHeight = 379
    object btnCancel: TBitBtn
      Left = 895
      Top = 354
      Width = 75
      Height = 25
      Caption = 'Cancel'
      TabOrder = 0
      OnClick = btnCancelClick
    end
    object Grid: TXRCGrid
      AlignWithMargins = True
      Left = 7
      Top = 7
      Width = 963
      Height = 330
      Margins.Bottom = 50
      Align = alClient
      TabOrder = 1
      AutoFit = False
      Text = #9#9#9#9
      ExplicitWidth = 955
      ExplicitHeight = 318
    end
  end
end
