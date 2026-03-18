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
    object pnlStructure: TPanel
      Left = 10
      Top = 10
      Width = 260
      Height = 200
      BevelOuter = bvNone
      Color = 15790320
      ParentBackground = False
      TabOrder = 0
      Visible = False
      object lblStructureHeader: TLabel
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 252
        Height = 15
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 2
        Align = alTop
        Alignment = taCenter
        Caption = 'Structure'
        Font.Height = -12
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object grdStructure: TStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 24
        Width = 254
        Height = 173
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Align = alClient
        BorderStyle = bsNone
        ColCount = 4
        DefaultDrawing = False
        DefaultRowHeight = 18
        FixedCols = 0
        Font.Height = -11
        Font.Name = 'Segoe UI'
        ParentFont = False
        ScrollBars = ssNone
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine]
        TabOrder = 0
        OnDrawCell = grdStructureDrawCell
      end
    end
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
