object frameCurvesView: TframeCurvesView
  Left = 0
  Top = 0
  Width = 600
  Height = 400
  TabOrder = 0
  object chrtCurves: TChart
    Left = 0
    Top = 0
    Width = 450
    Height = 400
    Align = alClient
    AlignWithMargins = True
    View3D = False
    TabOrder = 0
  end
  object pnlLegend: TPanel
    Left = 453
    Top = 0
    Width = 147
    Height = 400
    Align = alRight
    AlignWithMargins = True
    BevelOuter = bvNone
    TabOrder = 1
    object clbElements: TCheckListBox
      Left = 0
      Top = 0
      Width = 147
      Height = 400
      Align = alClient
      ItemHeight = 13
      TabOrder = 0
      OnClickCheck = clbElementsClickCheck
    end
  end
end
