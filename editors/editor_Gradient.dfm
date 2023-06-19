object edtrGradient: TedtrGradient
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Gradient'
  ClientHeight = 272
  ClientWidth = 220
  Color = 16765595
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  TextHeight = 13
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 228
    Width = 214
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 189
    ExplicitWidth = 193
    DesignSize = (
      214
      41)
    object btnOK: TRzBitBtn
      Left = 9
      Top = 10
      Width = 66
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 0
      TabStop = False
      OnClick = btnOKClick
      Kind = bkOK
    end
    object btnCancel: TRzBitBtn
      Left = 135
      Top = 10
      Width = 72
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 1
      TabStop = False
      Kind = bkCancel
    end
  end
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 214
    Height = 219
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    ExplicitWidth = 193
    ExplicitHeight = 180
    object Label1: TLabel
      Left = 9
      Top = 10
      Width = 27
      Height = 13
      Caption = 'Name'
    end
    object Label2: TLabel
      Left = 111
      Top = 134
      Width = 23
      Height = 13
      Caption = 'Rate'
    end
    object Label3: TLabel
      Left = 9
      Top = 35
      Width = 26
      Height = 13
      Caption = 'Stack'
    end
    object Label4: TLabel
      Left = 111
      Top = 35
      Width = 27
      Height = 13
      Caption = 'Layer'
    end
    object edRate: TJvCalcEdit
      Left = 138
      Top = 131
      Width = 70
      Height = 21
      ButtonFlat = True
      TabOrder = 0
      DecimalPlacesAlwaysShown = False
    end
    object edTitle: TEdit
      Left = 42
      Top = 6
      Width = 165
      Height = 21
      TabOrder = 1
      Text = 'Gradient'
    end
    object cbbStack: TComboBox
      Left = 9
      Top = 54
      Width = 96
      Height = 21
      TabOrder = 2
      OnChange = cbbStackChange
    end
    object cbLayer: TComboBox
      Left = 111
      Top = 54
      Width = 96
      Height = 21
      TabOrder = 3
    end
    object mmDescription: TMemo
      Left = 9
      Top = 160
      Width = 198
      Height = 46
      ScrollBars = ssVertical
      TabOrder = 4
    end
    object rgSubject: TRadioGroup
      Left = 9
      Top = 77
      Width = 198
      Height = 48
      Caption = 'Apply to'
      Columns = 3
      ItemIndex = 0
      Items.Strings = (
        'H'
        'Sigma'
        'Rho')
      TabOrder = 5
    end
  end
end
