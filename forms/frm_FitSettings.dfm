object frmFitSettings: TfrmFitSettings
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Advanced fitting settings'
  ClientHeight = 441
  ClientWidth = 447
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  StyleName = 'Windows'
  TextHeight = 15
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 441
    Height = 388
    Align = alClient
    BorderOuter = fsFlatRounded
    TabOrder = 0
    object Tip: TMHLStaticTip
      AlignWithMargins = True
      Left = 5
      Top = 332
      Width = 431
      Height = 51
      Align = alBottom
      Caption = 'Select a parameter to see its description'
      ExplicitLeft = 2
      ExplicitTop = 336
      ExplicitWidth = 441
    end
    object RzGroupBox1: TRzGroupBox
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 431
      Height = 55
      Align = alTop
      Caption = 'General'
      TabOrder = 0
      object Label20: TLabel
        Left = 12
        Top = 23
        Width = 47
        Height = 13
        Caption = 'Tolerance'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object edFitTolerance: TEdit
        Left = 65
        Top = 19
        Width = 43
        Height = 22
        Hint = 'Target tolerance (cost function). Fitting stops when reach it.'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = '0.005'
        OnEnter = ShowParamHint
      end
      object cbAdaptiveVelocity: TRzCheckBox
        Left = 352
        Top = 20
        Width = 44
        Height = 17
        AlignmentVertical = avCenter
        Caption = 'Ad.V'
        State = cbUnchecked
        TabOrder = 1
        Visible = False
      end
    end
    object RzGroupBox2: TRzGroupBox
      AlignWithMargins = True
      Left = 5
      Top = 66
      Width = 431
      Height = 103
      Align = alTop
      Caption = 'LFPSO'
      Color = 15987699
      TabOrder = 1
      object Label16: TLabel
        Left = 11
        Top = 48
        Width = 26
        Height = 13
        Caption = 'Vmax'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label18: TLabel
        Left = 108
        Top = 49
        Width = 17
        Height = 13
        Caption = ' '#969'1'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label19: TLabel
        Left = 189
        Top = 49
        Width = 17
        Height = 13
        Caption = ' '#969'2'
        Font.Charset = GREEK_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label15: TLabel
        Left = 99
        Top = 24
        Width = 25
        Height = 13
        Caption = 'Jmax'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label17: TLabel
        Left = 4
        Top = 23
        Width = 33
        Height = 13
        Caption = 'SHmax'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label13: TLabel
        Left = 26
        Top = 74
        Width = 11
        Height = 13
        Caption = 'k1'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object Label14: TLabel
        Left = 110
        Top = 74
        Width = 11
        Height = 13
        Caption = 'k2'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object edFVmax: TEdit
        Left = 43
        Top = 44
        Width = 50
        Height = 22
        Hint = 'Max. particle velocity factor'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 0
        Text = '0.3'
        OnEnter = ShowParamHint
      end
      object edLFPSOOmega1: TEdit
        Left = 131
        Top = 44
        Width = 50
        Height = 22
        Hint = 'Velocity scale factor (permanent)'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 1
        Text = '0.3'
        OnEnter = ShowParamHint
      end
      object edLFPSOOmega2: TEdit
        Left = 212
        Top = 45
        Width = 50
        Height = 22
        Hint = 'Velocity reducing factor'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 2
        Text = '0.1'
        OnEnter = ShowParamHint
      end
      object edLFPSOSkip: TEdit
        Left = 130
        Top = 19
        Width = 51
        Height = 22
        Hint = 'Number of iterations without improvement to perform shake'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 3
        Text = '1'
        OnEnter = ShowParamHint
      end
      object edLFPSORImax: TEdit
        Left = 43
        Top = 19
        Width = 50
        Height = 22
        Hint = 'Max. number of consequent shakes'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 4
        Text = '3'
        OnEnter = ShowParamHint
      end
      object edLFPSOChiFactor: TEdit
        Left = 43
        Top = 70
        Width = 50
        Height = 22
        Hint = 'Velocity shake coefficient'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 5
        Text = '1.41'
        OnEnter = ShowParamHint
      end
      object edLFPSOkVmax: TEdit
        Left = 130
        Top = 70
        Width = 50
        Height = 22
        Hint = 'Best cost functuion shake coefficient'
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
        TabOrder = 6
        Text = '1.41'
        OnEnter = ShowParamHint
      end
    end
    object RzGroupBox3: TRzGroupBox
      AlignWithMargins = True
      Left = 5
      Top = 175
      Width = 431
      Height = 55
      Align = alTop
      Caption = 'Irregular'
      Color = 15987699
      TabOrder = 2
      ExplicitTop = 151
      object Label1: TLabel
        Left = 12
        Top = 23
        Width = 89
        Height = 13
        Caption = 'Smoothing window'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentFont = False
      end
      object edIrrSmoothWindow: TEdit
        Left = 107
        Top = 19
        Width = 50
        Height = 22
        Hint = 
          'Width of the smoothing windows (integer). Set "-1" for automatic' +
          ' '
        Alignment = taRightJustify
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clBlack
        Font.Height = -12
        Font.Name = 'Tahoma'
        Font.Style = []
        NumbersOnly = True
        ParentFont = False
        TabOrder = 0
        Text = '3'
        OnEnter = ShowParamHint
      end
    end
    object RzGroupBox4: TRzGroupBox
      AlignWithMargins = True
      Left = 5
      Top = 236
      Width = 431
      Height = 55
      Align = alTop
      Caption = 'Polynomial'
      Color = 15987699
      TabOrder = 3
      ExplicitTop = 212
      object Label8: TLabel
        Left = 10
        Top = 25
        Width = 94
        Height = 15
        Caption = 'Polynomial factor'
      end
      object Label10: TLabel
        Left = 249
        Top = 27
        Width = 22
        Height = 15
        Caption = 'Ksxr'
      end
      object sePolyFactor: TSpinEdit
        Left = 105
        Top = 22
        Width = 84
        Height = 24
        MaxValue = 15
        MinValue = 1
        TabOrder = 0
        Value = 10
      end
      object edKsxr: TEdit
        Left = 279
        Top = 23
        Width = 49
        Height = 23
        Hint = 'Velocity scale factor for polynomes'
        NumbersOnly = True
        TabOrder = 1
        Text = '0.2'
        OnEnter = ShowParamHint
      end
    end
  end
  object rzpnl1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 397
    Width = 441
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    object btnSave: TRzBitBtn
      Left = 360
      Top = 8
      TabOrder = 0
      Kind = bkOK
    end
    object btnCancel: TBitBtn
      Left = 9
      Top = 8
      Width = 75
      Height = 25
      Kind = bkCancel
      NumGlyphs = 2
      TabOrder = 1
    end
  end
end
