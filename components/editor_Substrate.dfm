object edtrSubstrate: TedtrSubstrate
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Substrate'
  ClientHeight = 124
  ClientWidth = 269
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 13
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 80
    Width = 263
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 37
    ExplicitWidth = 236
    object btnOK: TRzBitBtn
      Left = 11
      Top = 10
      Width = 93
      TabOrder = 0
      TabStop = False
      Kind = bkOK
    end
    object btnCancel: TRzBitBtn
      Left = 162
      Top = 10
      Width = 87
      TabOrder = 1
      TabStop = False
      Kind = bkCancel
    end
  end
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 263
    Height = 71
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    ExplicitWidth = 236
    ExplicitHeight = 28
    object Label1: TLabel
      Left = 9
      Top = 10
      Width = 95
      Height = 13
      Caption = 'Substrate'#39's material'
    end
    object Label7: TLabel
      Left = 169
      Top = 31
      Width = 9
      Height = 20
      Caption = 'r'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 67
      Top = 31
      Width = 10
      Height = 20
      Caption = 's'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -16
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object edMaterial: TRzButtonEdit
      Left = 110
      Top = 6
      Width = 139
      Height = 21
      Text = ''
      TabOrder = 0
      AltBtnNumGlyphs = 1
      ButtonNumGlyphs = 1
    end
    object edRo: TJvCalcEdit
      Left = 184
      Top = 33
      Width = 65
      Height = 21
      ButtonFlat = True
      TabOrder = 2
      DecimalPlacesAlwaysShown = False
    end
    object edSigma: TJvCalcEdit
      Left = 83
      Top = 33
      Width = 65
      Height = 21
      ButtonFlat = True
      TabOrder = 1
      DecimalPlacesAlwaysShown = False
    end
  end
end
