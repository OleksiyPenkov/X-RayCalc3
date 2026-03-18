object frameCurvesView: TframeCurvesView
  Left = 0
  Top = 0
  Width = 800
  Height = 500
  TabOrder = 0
  object pnlInfo: TRzPanel
    Left = 0
    Top = 470
    Width = 800
    Height = 30
    Align = alBottom
    AlignWithMargins = True
    BorderOuter = fsNone
    TabOrder = 0
    DesignSize = (
      800
      30)
    object spThetaLabel: TRzStatusPane
      Left = 4
      Top = 4
      Width = 40
      Alignment = taRightJustify
      Caption = 'Theta'
    end
    object spTheta: TRzStatusPane
      Left = 46
      Top = 4
      Width = 60
      Caption = ''
    end
    object spRLabel: TRzStatusPane
      Left = 110
      Top = 4
      Width = 15
      Alignment = taRightJustify
      Caption = 'R'
    end
    object spR: TRzStatusPane
      Left = 128
      Top = 4
      Width = 80
      Caption = ''
    end
    object chkTotal: TRzCheckBox
      Left = 220
      Top = 7
      Width = 90
      Height = 17
      Caption = 'Total curve'
      Checked = True
      TabOrder = 0
      OnClick = chkTotalClick
    end
    object btnScale: TRzBitBtn
      Left = 650
      Top = 2
      Width = 65
      Height = 25
      Anchors = [akTop, akRight]
      Caption = 'Log'
      TabOrder = 1
      OnClick = btnScaleClick
    end
    object cbMinLimit: TRzComboBox
      Left = 722
      Top = 3
      Width = 72
      Height = 21
      Anchors = [akTop, akRight]
      TabOrder = 2
      Text = '1E-7'
      OnChange = cbMinLimitChange
      Items.Strings = (
        '1E-4'
        '1E-5'
        '1E-6'
        '1E-7'
        '1E-8'
        '1E-9')
    end
  end
  object pnlMetrics: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 313
    Width = 794
    Height = 154
    Align = alBottom
    BorderOuter = fsNone
    TabOrder = 1
    Visible = False
    OnResize = pnlMetricsResize
    object chrtPeakPos: TChart
      Left = 0
      Top = 0
      Width = 198
      Height = 154
      Legend.Visible = False
      MarginBottom = 1
      MarginLeft = 2
      MarginRight = 1
      MarginTop = 2
      Title.Text.Strings = (
        'Peak Position')
      Title.Font.Height = -12
      Title.Font.Style = [fsBold]
      LeftAxis.Title.Caption = 'Degrees'
      View3D = False
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 0
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
    end
    object chrtR: TChart
      Left = 198
      Top = 0
      Width = 198
      Height = 154
      Legend.Visible = False
      MarginBottom = 1
      MarginLeft = 2
      MarginRight = 1
      MarginTop = 2
      Title.Text.Strings = (
        'R')
      Title.Font.Height = -12
      Title.Font.Style = [fsBold]
      LeftAxis.Title.Caption = 'Reflectivity'
      View3D = False
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 1
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
    end
    object chrtFWHM: TChart
      Left = 396
      Top = 0
      Width = 198
      Height = 154
      Legend.Visible = False
      MarginBottom = 1
      MarginLeft = 2
      MarginRight = 1
      MarginTop = 2
      Title.Text.Strings = (
        'FWHM')
      Title.Font.Height = -12
      Title.Font.Style = [fsBold]
      LeftAxis.Title.Caption = 'Degrees'
      View3D = False
      Align = alLeft
      BevelOuter = bvNone
      TabOrder = 2
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
    end
    object chrtSNR: TChart
      Left = 594
      Top = 0
      Width = 200
      Height = 154
      Legend.Visible = False
      MarginBottom = 1
      MarginLeft = 2
      MarginRight = 1
      MarginTop = 2
      Title.Text.Strings = (
        'SNR')
      Title.Font.Height = -12
      Title.Font.Style = [fsBold]
      LeftAxis.Title.Caption = 'Ratio'
      View3D = False
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 3
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
    end
  end
  object splMetrics: TSplitter
    Left = 0
    Top = 309
    Width = 800
    Height = 4
    Cursor = crVSplit
    Align = alBottom
    Visible = False
  end
  object chrtCurves: TChart
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 794
    Height = 303
    Cursor = crCross
    Legend.Visible = False
    Legend.ResizeChart = False
    MarginBottom = 1
    MarginLeft = 2
    MarginRight = 1
    MarginTop = 2
    Title.Visible = False
    BottomAxis.Title.Caption = 'Theta (deg)'
    BottomAxis.Title.Font.Height = -13
    LeftAxis.Logarithmic = False
    LeftAxis.Title.Caption = 'Reflectivity'
    LeftAxis.Title.Font.Height = -13
    View3D = False
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 2
    OnMouseMove = ChartMouseMove
    OnResize = ChartResize
    DefaultCanvas = 'TGDIPlusCanvas'
    ColorPaletteIndex = 13
    object pnlStructure: TRzPanel
      Left = 10
      Top = 10
      Width = 300
      Height = 200
      BorderOuter = fsFlatRounded
      FlatColor = clGray
      Color = clWhite
      TabOrder = 0
      Visible = False
      object lblStructureHeader: TRzLabel
        AlignWithMargins = True
        Left = 4
        Top = 4
        Width = 292
        Height = 18
        Margins.Left = 4
        Margins.Top = 4
        Margins.Right = 4
        Margins.Bottom = 2
        Align = alTop
        Alignment = taCenter
        Caption = 'Structure'
        Font.Height = -15
        Font.Name = 'Segoe UI'
        Font.Style = [fsBold]
        ParentFont = False
      end
      object grdStructure: TStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 27
        Width = 294
        Height = 170
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Align = alClient
        BorderStyle = bsNone
        ColCount = 4
        DefaultDrawing = False
        DefaultRowHeight = 22
        FixedCols = 0
        Font.Height = -13
        Font.Name = 'Segoe UI'
        ParentFont = False
        ScrollBars = ssNone
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine]
        TabOrder = 0
        OnDrawCell = grdStructureDrawCell
      end
    end
    object pnlLegend: TRzPanel
      Left = 440
      Top = 10
      Width = 140
      Height = 40
      BorderOuter = fsFlatRounded
      FlatColor = clGray
      Color = clWhite
      TabOrder = 1
      Visible = False
      object sbLegend: TScrollBox
        Left = 2
        Top = 2
        Width = 136
        Height = 36
        Align = alClient
        BorderStyle = bsNone
        Color = clWhite
        ParentColor = False
        TabOrder = 0
      end
    end
  end
end
