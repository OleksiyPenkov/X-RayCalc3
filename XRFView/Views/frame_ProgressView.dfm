object frameProgressView: TframeProgressView
  Left = 0
  Top = 0
  Width = 600
  Height = 400
  TabOrder = 0
  object pnlChart: TPanel
    Left = 0
    Top = 264
    Width = 600
    Height = 136
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object chrtProgress: TChart
      Left = 0
      Top = 0
      Width = 600
      Height = 136
      Legend.Visible = False
      Align = alClient
      AlignWithMargins = True
      View3D = False
      TabOrder = 0
    end
  end
  object Splitter1: TSplitter
    Left = 0
    Top = 260
    Width = 600
    Height = 4
    Cursor = crVSplit
    Align = alBottom
  end
  object MemoLog: TMemo
    Left = 0
    Top = 0
    Width = 600
    Height = 260
    Align = alClient
    AlignWithMargins = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssVertical
    TabOrder = 1
    WordWrap = False
  end
end
