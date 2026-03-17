object frameCompareView: TframeCompareView
  Left = 0
  Top = 0
  Width = 600
  Height = 400
  TabOrder = 0
  object grdCompare: TStringGrid
    Left = 0
    Top = 0
    Width = 600
    Height = 400
    Align = alClient
    AlignWithMargins = True
    ColCount = 2
    FixedCols = 1
    RowCount = 8
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing]
    TabOrder = 0
    ColWidths = [120, 120]
  end
end
