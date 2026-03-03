object frmCalcSettings: TfrmCalcSettings
  Left = 0
  Top = 0
  Width = 1048
  Height = 118
  Margins.Left = 3
  Margins.Top = 3
  Margins.Right = 3
  Margins.Bottom = 3
  Align = alClient
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clBlack
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object RzPanel6: TRzPanel
    AlignWithMargins = True
    Left = 393
    Top = 6
    Width = 652
    Height = 108
    Margins.Left = 3
    Margins.Top = 6
    Margins.Right = 3
    Margins.Bottom = 3
    Align = alClient
    Alignment = taLeftJustify
    AlignmentVertical = avTop
    BevelWidth = 1
    BorderOuter = fsFlatRounded
    Caption = 'Fitting'
    TabOrder = 0
    Color = 15987699
    StyleElements = [seFont, seClient, seBorder]
    object Label7: TLabel
      Left = 8
      Top = 29
      Width = 46
      Height = 14
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Iterations'
      StyleElements = [seFont, seClient, seBorder]
    end
    object Label8: TLabel
      Left = 6
      Top = 57
      Width = 50
      Height = 14
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Population'
      StyleElements = [seFont, seClient, seBorder]
    end
    object lblPolyOrder: TLabel
      Left = 291
      Top = 51
      Width = 28
      Height = 14
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Order'
      Enabled = False
      StyleElements = [seFont, seClient, seBorder]
    end
    object Label21: TLabel
      Left = 256
      Top = 83
      Width = 34
      Height = 16
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = ' TW'#967'2'
      StyleElements = [seFont, seClient, seBorder]
    end
    object rgFittingMode: TRzRadioGroup
      AlignWithMargins = True
      Left = 132
      Top = 3
      Width = 237
      Height = 39
      Margins.Left = 3
      Margins.Top = 15
      Margins.Right = 3
      Margins.Bottom = 3
      BevelWidth = 1
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
      Left = 60
      Top = 25
      Width = 50
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Alignment = taRightJustify
      NumbersOnly = True
      TabOrder = 1
      Text = '100'
      StyleElements = [seFont, seClient, seBorder]
    end
    object edFPopulation: TEdit
      Left = 60
      Top = 53
      Width = 50
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Alignment = taRightJustify
      NumbersOnly = True
      TabOrder = 2
      Text = '100'
      StyleElements = [seFont, seClient, seBorder]
    end
    object cbLFPSOShake: TRzCheckBox
      Left = 7
      Top = 81
      Width = 55
      Height = 19
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      AlignmentVertical = avCenter
      AutoSizeWidth = 110
      Caption = 'Shake'
      Checked = True
      State = cbChecked
      TabOrder = 3
    end
    object cbSeedRange: TRzCheckBox
      Left = 71
      Top = 81
      Width = 56
      Height = 19
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      AlignmentVertical = avCenter
      AutoSizeWidth = 113
      Caption = 'SeedR'
      Checked = True
      State = cbChecked
      TabOrder = 4
    end
    object edPolyOrder: TEdit
      Left = 335
      Top = 48
      Width = 34
      Height = 18
      Hint = 'Polynomial order'
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Left = 297
      Top = 78
      Width = 72
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Left = 141
      Top = 81
      Width = 46
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      AutoSizeWidth = 93
      Caption = 'PW '#967'2'
      Checked = True
      State = cbChecked
      TabOrder = 7
    end
    object btnAdvFitSettings: TRzBitBtn
      Left = 375
      Top = 9
      Width = 75
      Height = 92
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Advanced'#13'Settings'
      TabOrder = 8
      OnClick = btnAdvFitSettingsClick
      Margin = 4
      Spacing = 4
    end
    object cbSmooth: TRzCheckBox
      Left = 141
      Top = 48
      Width = 54
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      AutoSizeWidth = 109
      Caption = 'Smooth'
      State = cbUnchecked
      TabOrder = 9
    end
  end
  object RzPanel7: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 384
    Height = 112
    Margins.Left = 3
    Margins.Top = 3
    Margins.Right = 3
    Margins.Bottom = 3
    Align = alLeft
    BevelWidth = 1
    BorderOuter = fsNone
    TabOrder = 1
    Color = 15987699
    StyleElements = [seFont, seClient, seBorder]
    object rgPolarisation: TRzRadioGroup
      Left = 170
      Top = 0
      Width = 143
      Height = 42
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      BevelWidth = 1
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
      Left = 224
      Top = 47
      Width = 157
      Height = 64
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      BevelWidth = 1
      BorderOuter = fsFlatRounded
      Enabled = False
      TabOrder = 1
      Transparent = True
      Color = 15987699
      StyleElements = [seFont, seClient, seBorder]
      object Label9: TLabel
        Left = 8
        Top = 36
        Width = 16
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'l2'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label10: TLabel
        Left = 7
        Top = 13
        Width = 16
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'l1'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label11: TLabel
        Left = 89
        Top = 10
        Width = 8
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'q'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label12: TLabel
        Left = 86
        Top = 37
        Width = 18
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'Dl'
        Enabled = False
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object edStartL: TEdit
        Left = 28
        Top = 9
        Width = 47
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 0
        Text = '1'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edEndL: TEdit
        Left = 28
        Top = 35
        Width = 47
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 1
        Text = '10'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edTheta: TEdit
        Left = 109
        Top = 9
        Width = 40
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 2
        Text = '85'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edDL: TEdit
        Left = 109
        Top = 36
        Width = 40
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        Enabled = False
        TabOrder = 3
        Text = '0'
        StyleElements = [seFont, seClient, seBorder]
      end
    end
    object pnlAngleParams: TRzPanel
      Left = 3
      Top = 47
      Width = 215
      Height = 64
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      BevelWidth = 1
      BorderOuter = fsFlatRounded
      TabOrder = 2
      Transparent = True
      Color = 15987699
      StyleElements = [seFont, seClient, seBorder]
      object Label1: TLabel
        Left = 6
        Top = 36
        Width = 16
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'q2'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label2: TLabel
        Left = 6
        Top = 10
        Width = 16
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'q1'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label3: TLabel
        Left = 92
        Top = 10
        Width = 30
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'l(A)'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object Label4: TLabel
        Left = 94
        Top = 36
        Width = 17
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Caption = 'Dq'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        StyleElements = [seFont, seClient, seBorder]
      end
      object edStartTeta: TEdit
        Left = 26
        Top = 9
        Width = 50
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        TabOrder = 0
        Text = '0.01'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edEndTeta: TEdit
        Left = 26
        Top = 36
        Width = 50
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        TabOrder = 1
        Text = '10'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edWidth: TEdit
        Left = 115
        Top = 35
        Width = 48
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        TabOrder = 2
        Text = '0.015'
        StyleElements = [seFont, seClient, seBorder]
      end
      object edLambda: TEdit
        Left = 126
        Top = 9
        Width = 75
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        TabOrder = 3
        Text = '1.54043'
        StyleElements = [seFont, seClient, seBorder]
      end
      object cb2Theta: TRzCheckBox
        Left = 169
        Top = 36
        Width = 38
        Height = 20
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        AutoSizeWidth = 77
        Caption = '2q'
        Checked = True
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -15
        Font.Name = 'Symbol'
        Font.Style = []
        ParentFont = False
        State = cbChecked
        TabOrder = 4
        Transparent = True
        OnClick = cb2ThetaClick
      end
    end
    object rgCalcMode: TRzRadioGroup
      AlignWithMargins = True
      Left = 3
      Top = -1
      Width = 161
      Height = 42
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      BevelWidth = 1
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
      OnClick = rgCalcModeClick
      StyleElements = [seFont, seClient, seBorder]
    end
    object RzGroupBox2: TRzGroupBox
      Left = 319
      Top = 0
      Width = 62
      Height = 41
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      BevelWidth = 1
      Caption = 'N'
      Color = 15987699
      TabOrder = 4
      StyleElements = [seFont, seClient, seBorder]
      object edN: TEdit
        Left = 4
        Top = 15
        Width = 53
        Height = 18
        Margins.Left = 3
        Margins.Top = 3
        Margins.Right = 3
        Margins.Bottom = 3
        Alignment = taRightJustify
        NumbersOnly = True
        TabOrder = 0
        Text = '2000'
        StyleElements = [seFont, seClient, seBorder]
      end
    end
  end
end
