object edtrProjectItem: TedtrProjectItem
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Properties'
  ClientHeight = 204
  ClientWidth = 374
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
    Top = 160
    Width = 368
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    object btnOK: TRzBitBtn
      Left = 19
      Top = 10
      Width = 102
      ParentColor = True
      TabOrder = 0
      TabStop = False
      OnClick = btnOKClick
      Kind = bkOK
    end
    object btnCancel: TRzBitBtn
      Left = 244
      Top = 10
      Width = 109
      Color = 16765595
      TabOrder = 1
      TabStop = False
      Kind = bkCancel
    end
  end
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 368
    Height = 151
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    object Color: TLabel
      Left = 257
      Top = 5
      Width = 25
      Height = 13
      Caption = 'Color'
    end
    object edTitle: TLabeledEdit
      Left = 8
      Top = 24
      Width = 243
      Height = 21
      EditLabel.Width = 20
      EditLabel.Height = 13
      EditLabel.Caption = 'Title'
      TabOrder = 0
      Text = ''
    end
    object mmDescription: TMemo
      Left = 8
      Top = 64
      Width = 361
      Height = 89
      ScrollBars = ssVertical
      TabOrder = 1
    end
    object cbColor: TColorBox
      Left = 257
      Top = 24
      Width = 104
      Height = 22
      DefaultColorColor = clRed
      Style = [cbStandardColors, cbExtendedColors, cbCustomColor, cbPrettyNames, cbCustomColors]
      TabOrder = 2
    end
  end
  object rzfrmcntrlr1: TRzFrameController
    FlatButtonColor = 16765595
    FocusColor = 16776176
    FrameVisible = True
    FramingPreference = fpCustomFraming
    ParentColor = True
    Left = 179
    Top = 91
  end
end
