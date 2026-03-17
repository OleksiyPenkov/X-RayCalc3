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
    object chkLogScale: TCheckBox
      Left = 0
      Top = 0
      Width = 147
      Height = 17
      Align = alTop
      Caption = 'Log scale'
      Checked = True
      State = cbChecked
      TabOrder = 0
      OnClick = chkLogScaleClick
    end
    object chkTotal: TCheckBox
      Left = 0
      Top = 17
      Width = 147
      Height = 17
      Align = alTop
      Caption = 'Total curve'
      TabOrder = 1
      OnClick = chkTotalClick
    end
    object clbElements: TCheckListBox
      Left = 0
      Top = 34
      Width = 147
      Height = 366
      Align = alClient
      ItemHeight = 13
      TabOrder = 2
      OnClickCheck = clbElementsClickCheck
    end
  end
end
