object frmBenchmark: TfrmBenchmark
  Left = 0
  Top = 0
  BorderStyle = bsNone
  Caption = 'Benchmark'
  ClientHeight = 436
  ClientWidth = 999
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
    Width = 993
    Height = 430
    Align = alClient
    BorderOuter = fsGroove
    BorderWidth = 2
    TabOrder = 0
    ExplicitLeft = 31
    ExplicitTop = 152
    ExplicitWidth = 185
    ExplicitHeight = 41
    object BitBtn1: TBitBtn
      Left = 896
      Top = 387
      Width = 75
      Height = 25
      Caption = 'Close'
      TabOrder = 0
      OnClick = BitBtn1Click
    end
    object Grid: TStringGrid
      AlignWithMargins = True
      Left = 7
      Top = 54
      Width = 979
      Height = 322
      Margins.Bottom = 50
      Align = alClient
      ColCount = 6
      DefaultColWidth = 50
      FixedCols = 0
      RowCount = 2
      TabOrder = 1
    end
    object pnl1: TPanel
      AlignWithMargins = True
      Left = 7
      Top = 7
      Width = 979
      Height = 41
      Align = alTop
      Alignment = taLeftJustify
      Caption = 'Benchmark'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -16
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 2
      ExplicitLeft = 5
      ExplicitTop = -3
      ExplicitWidth = 200
    end
  end
end
