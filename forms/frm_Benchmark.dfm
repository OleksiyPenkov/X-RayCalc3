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
    ExplicitWidth = 993
    ExplicitHeight = 430
    object BitBtn1: TBitBtn
      Left = 896
      Top = 363
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 0
      OnClick = BitBtn1Click
    end
    object Grid: TStringGrid
      AlignWithMargins = True
      Left = 7
      Top = 7
      Width = 971
      Height = 342
      Margins.Bottom = 50
      Align = alClient
      ColCount = 6
      DefaultColWidth = 50
      FixedCols = 0
      RowCount = 2
      TabOrder = 1
      ExplicitTop = 54
      ExplicitWidth = 979
      ExplicitHeight = 322
    end
  end
end
