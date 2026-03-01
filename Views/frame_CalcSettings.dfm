object frmCalcSettings: TfrmCalcSettings
  Left = 0
  Top = 0
  Width = 2096
  Height = 235
  Margins.Left = 6
  Margins.Top = 6
  Margins.Right = 6
  Margins.Bottom = 6
  Align = alClient
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -22
  Font.Name = 'Tahoma'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object RzPanel6: TRzPanel
    AlignWithMargins = True
    Left = 786
    Top = 12
    Width = 1304
    Height = 217
    Margins.Left = 6
    Margins.Top = 12
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alClient
    Alignment = taLeftJustify
    AlignmentVertical = avTop
    BevelWidth = 2
    BorderOuter = fsFlatRounded
    Caption = 'Fitting'
    TabOrder = 0
    Color = 15987699
    StyleElements = [seFont, seClient, seBorder]
    object Label7: TLabel
      Left = 16
      Top = 58
      Width = 93
      Height = 27
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Iterations'
      StyleElements = [seFont, seClient, seBorder]
    end
    object Label8: TLabel
      Left = 12
      Top = 114
      Width = 101
      Height = 27
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Population'
      StyleElements = [seFont, seClient, seBorder]
    end
    object lblPolyOrder: TLabel
      Left = 582
      Top = 102
      Width = 56
      Height = 27
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Order'
      Enabled = False
      StyleElements = [seFont, seClient, seBorder]
    end
    object Label21: TLabel
      Left = 512
      Top = 166
      Width = 69
      Height = 32
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = ' TW'#967'2'
      StyleElements = [seFont, seClient, seBorder]
    end
    object rgFittingMode: TRzRadioGroup
      AlignWithMargins = True
      Left = 264
      Top = 6
      Width = 474
      Height = 78
      Margins.Left = 6
      Margins.Top = 30
      Margins.Right = 6
      Margins.Bottom = 6
      BevelWidth = 2
      Caption = 'Mode'
      Color = 15987699
      Columns = 3
      HorizontalSpacing = 16
      ItemIndex = 0
      Items.Strings = (
        'Irregualr'
        'Periodic'
        'Polynomial')
      SpaceEvenly = True
      StartXPos = 16
      StartYPos = 4
      TabOrder = 0
      VerticalSpacing = 6
      OnClick = rgFittingModeClick
      StyleElements = [seFont, seClient, seBorder]
    end
    object edFIter: TEdit
      Left = 120
      Top = 50
      Width = 100
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Alignment = taRightJustify
      NumbersOnly = True
      TabOrder = 1
      Text = '100'
      StyleElements = [seFont, seClient, seBorder]
    end
    object edFPopulation: TEdit
      Left = 120
      Top = 106
      Width = 100
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Alignment = taRightJustify
      NumbersOnly = True
      TabOrder = 2
      Text = '100'
      StyleElements = [seFont, seClient, seBorder]
    end
    object cbLFPSOShake: TRzCheckBox
      Left = 14
      Top = 162
      Width = 110
      Height = 38
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      AlignmentVertical = avCenter
      AutoSizeWidth = 110
      Caption = 'Shake'
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
    object cbSeedRange: TRzCheckBox
      Left = 142
      Top = 162
      Width = 113
      Height = 38
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      AlignmentVertical = avCenter
      AutoSizeWidth = 113
      Caption = 'SeedR'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object edPolyOrder: TEdit
      Left = 670
      Top = 96
      Width = 68
      Height = 37
      Hint = 'Polynomial order'
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Alignment = taRightJustify
      Enabled = False
      MaxLength = 1
      NumbersOnly = True
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      Text = '1'
      StyleElements = [seFont, seClient, seBorder]
    end
    object cbTWChi: TComboBox
      Left = 594
      Top = 156
      Width = 144
      Height = 40
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ItemIndex = 0
      TabOrder = 6
      Text = 'None'
      Items.Strings = (
        'None'
        'sqr'
        'line'
        'sqrt'
        '1/sqr'
        '1/sqrt')
      StyleElements = [seFont, seClient, seBorder]
    end
    object cbPWChiSqr: TRzCheckBox
      Left = 282
      Top = 162
      Width = 93
      Height = 36
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      AutoSizeWidth = 93
      Caption = 'PW '#967'2'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object btnAdvFitSettings: TRzBitBtn
      Left = 750
      Top = 18
      Width = 150
      Height = 184
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Advanced'#13'Settings'
      TabOrder = 8
      OnClick = btnAdvFitSettingsClick
      Margin = 4
      Spacing = 8
    end
    object cbSmooth: TRzCheckBox
      Left = 282
      Top = 96
      Width = 109
      Height = 36
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      AutoSizeWidth = 109
      Caption = 'Smooth'
      State = cbUnchecked
      TabOrder = 9
    end
  end
  object RzPanel7: TRzPanel
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 768
    Height = 223
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alLeft
    BevelWidth = 2
    BorderOuter = fsNone
    TabOrder = 1
    Color = 15987699
    StyleElements = [seFont, seClient, seBorder]
    object rgPolarisation: TRzRadioGroup
      Left = 340
      Top = 0
      Width = 286
      Height = 84
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      BevelWidth = 2
      BorderOuter = fsFlatRounded
      Caption = 'Polarization'
      Color = 15987699
      Columns = 2
      HorizontalSpacing = 16
      ItemIndex = 0
      Items.Strings = (
        's-type'
        'sp-type')
      SpaceEvenly = True
      StartXPos = 16
      StartYPos = 4
      TabOrder = 0
      VerticalSpacing = 6
      StyleElements = [seFont, seClient, seBorder]
    end
    object pnlWaveParams: TRzPanel
      Left = 448
      Top = 94
      Width = 314
      Height = 128
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      BevelWidth = 2
      BorderOuter = fsFlatRounded
      Enabled = False
      TabOrder = 1
      Transparent = True
      Color = 15987699
      StyleElements = [seFont, seClient, seBorder]
      object Label9: TLabel
        Left = 16
        Top = 72
        Width = 32
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'l2'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label10: TLabel
        Left = 14
        Top = 26
        Width = 32
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'l1'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label11: TLabel
        Left = 178
        Top = 20
        Width = 16
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'q'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label12: TLabel
        Left = 172
        Top = 74
        Width = 35
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'Dl'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object edStartL: TEdit
        Left = 56
        Top = 18
        Width = 94
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 0
        Text = '1'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edEndL: TEdit
        Left = 56
        Top = 70
        Width = 94
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 1
        Text = '10'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edTheta: TEdit
        Left = 218
        Top = 18
        Width = 80
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 2
        Text = '85'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edDL: TEdit
        Left = 218
        Top = 72
        Width = 80
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 3
        Text = '0'
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object pnlAngleParams: TRzPanel
      Left = 6
      Top = 94
      Width = 430
      Height = 128
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      BevelWidth = 2
      BorderOuter = fsFlatRounded
      TabOrder = 2
      Transparent = True
      Color = 15987699
      StyleElements = [seFont, seClient, seBorder]
      object Label1: TLabel
        Left = 12
        Top = 72
        Width = 31
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'q2'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label2: TLabel
        Left = 12
        Top = 20
        Width = 31
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'q1'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label3: TLabel
        Left = 184
        Top = 20
        Width = 59
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'l(A)'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label4: TLabel
        Left = 188
        Top = 72
        Width = 34
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Caption = 'Dq'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object edStartTeta: TEdit
        Left = 52
        Top = 18
        Width = 100
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        TabOrder = 0
        Text = '0.01'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edEndTeta: TEdit
        Left = 52
        Top = 72
        Width = 100
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        TabOrder = 1
        Text = '10'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edWidth: TEdit
        Left = 230
        Top = 70
        Width = 96
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        TabOrder = 2
        Text = '0.015'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edLambda: TEdit
        Left = 252
        Top = 18
        Width = 150
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        TabOrder = 3
        Text = '1.54043'
        StyleElements = [seFont, seClient, seBorder]
      end
      object cb2Theta: TRzCheckBox
        Left = 338
        Top = 72
        Width = 77
        Height = 41
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        AutoSizeWidth = 77
        Caption = '2q'
        Checked = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -30
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        State = cbChecked
        TabOrder = 4
        Transparent = True
      end
    end
    object rgCalcMode: TRzRadioGroup
      AlignWithMargins = True
      Left = 6
      Top = -2
      Width = 322
      Height = 84
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      BevelWidth = 2
      BorderOuter = fsFlatRounded
      Caption = 'Mode'
      Color = 15987699
      Columns = 2
      HorizontalSpacing = 16
      ItemIndex = 0
      Items.Strings = (
        'by angle'
        'by wave')
      SpaceEvenly = True
      StartXPos = 16
      StartYPos = 4
      TabOrder = 3
      VerticalSpacing = 6
      OnChanging = rgCalcModeChanging
      StyleElements = [seFont, seClient, seBorder]
    end
    object RzGroupBox2: TRzGroupBox
      Left = 638
      Top = 0
      Width = 124
      Height = 82
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      BevelWidth = 2
      Caption = 'N'
      Color = 15987699
      TabOrder = 4
      StyleElements = [seFont, seClient, seBorder]
      object edN: TEdit
        Left = 8
        Top = 30
        Width = 106
        Height = 37
        Margins.Left = 6
        Margins.Top = 6
        Margins.Right = 6
        Margins.Bottom = 6
        Alignment = taRightJustify
        NumbersOnly = True
        TabOrder = 0
        Text = '2000'
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
end
