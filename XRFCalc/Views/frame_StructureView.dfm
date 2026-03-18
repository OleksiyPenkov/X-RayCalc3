object frameStructureView: TframeStructureView
  Left = 0
  Top = 0
  Width = 600
  Height = 400
  TabOrder = 0
  object pnlSummary: TRzPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 65
    Align = alTop
    AlignWithMargins = True
    BorderOuter = fsNone
    TabOrder = 0
    object lblType: TRzLabel
      Left = 8
      Top = 4
      Width = 30
      Height = 13
      Caption = 'Type:'
    end
    object lblPeriod: TRzLabel
      Left = 8
      Top = 20
      Width = 15
      Height = 13
      Caption = 'd ='
    end
    object lblGamma: TRzLabel
      Left = 150
      Top = 20
      Width = 46
      Height = 13
      Caption = 'gamma ='
    end
    object lblN: TRzLabel
      Left = 300
      Top = 20
      Width = 14
      Height = 13
      Caption = 'N ='
    end
  end
  object grdLayers: TStringGrid
    Left = 0
    Top = 68
    Width = 600
    Height = 332
    Align = alClient
    AlignWithMargins = True
    ColCount = 5
    FixedCols = 0
    RowCount = 4
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing]
    TabOrder = 1
    ColWidths = (
      30
      100
      100
      100
      110)
  end
end
