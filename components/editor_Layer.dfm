object edtrLayer: TedtrLayer
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Layer properties'
  ClientHeight = 125
  ClientWidth = 358
  Color = 16765595
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 352
    Height = 72
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitWidth = 344
    ExplicitHeight = 60
    object Label1: TLabel
      Left = 9
      Top = 10
      Width = 68
      Height = 13
      Caption = 'Layer material'
    end
    object Label2: TLabel
      Left = 5
      Top = 34
      Width = 30
      Height = 16
      Caption = 'H ('#197')'
      Font.Charset = ANSI_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label7: TLabel
      Left = 226
      Top = 34
      Width = 56
      Height = 16
      Caption = #961' (g/cm'#179')'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 114
      Top = 34
      Width = 30
      Height = 16
      Caption = #963' ('#197')'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object edMaterial: TRzButtonEdit
      Left = 90
      Top = 6
      Width = 255
      Height = 21
      Text = ''
      TabOrder = 0
      AltBtnNumGlyphs = 1
      ButtonNumGlyphs = 1
      OnButtonClick = edMaterialButtonClick
    end
    object edRo: TJvCalcEdit
      Left = 288
      Top = 33
      Width = 57
      Height = 21
      ButtonFlat = True
      TabOrder = 3
      DecimalPlacesAlwaysShown = False
    end
    object edH: TJvCalcEdit
      Left = 41
      Top = 33
      Width = 70
      Height = 21
      ButtonFlat = True
      TabOrder = 1
      DecimalPlacesAlwaysShown = False
    end
    object edSigma: TJvCalcEdit
      Left = 150
      Top = 33
      Width = 65
      Height = 21
      ButtonFlat = True
      TabOrder = 2
      DecimalPlacesAlwaysShown = False
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 81
    Width = 352
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    ExplicitTop = 69
    ExplicitWidth = 344
    object btnOK: TRzBitBtn
      Left = 192
      Top = 10
      Width = 70
      Alignment = taRightJustify
      ParentColor = True
      TabOrder = 2
      TabStop = False
      OnClick = btnOKClick
      Kind = bkOK
    end
    object btnCancel: TRzBitBtn
      Left = 272
      Top = 10
      Width = 70
      Alignment = taRightJustify
      ParentColor = True
      TabOrder = 3
      TabStop = False
      Kind = bkCancel
    end
    object btnPrev: TRzBitBtn
      Tag = 2
      Left = 10
      Top = 8
      Width = 39
      Caption = '<<'
      ParentColor = True
      TabOrder = 0
      TabStop = False
      OnClick = btnPrevClick
    end
    object btnNext: TRzBitBtn
      Tag = 1
      Left = 55
      Top = 8
      Width = 39
      Caption = '>>'
      ParentColor = True
      TabOrder = 1
      TabStop = False
      OnClick = btnNextClick
    end
  end
end
