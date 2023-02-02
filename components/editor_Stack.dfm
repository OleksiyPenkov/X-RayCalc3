object edtrStack: TedtrStack
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Stack properties'
  ClientHeight = 96
  ClientWidth = 312
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
    Width = 306
    Height = 43
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitWidth = 264
    ExplicitHeight = 17
    object Label1: TLabel
      Left = 9
      Top = 13
      Width = 55
      Height = 13
      Caption = 'Stack name'
    end
    object Label2: TLabel
      Left = 199
      Top = 13
      Width = 7
      Height = 13
      Caption = 'N'
    end
    object edN: TRzNumericEdit
      Left = 233
      Top = 10
      Width = 65
      Height = 21
      TabOrder = 0
      CalculatorVisible = True
      Max = 10000.000000000000000000
      DisplayFormat = ',0;(,0)'
    end
    object edTitle: TEdit
      Left = 81
      Top = 10
      Width = 112
      Height = 21
      TabOrder = 1
      Text = 'Stack'
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 52
    Width = 306
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    ExplicitTop = 26
    ExplicitWidth = 264
    object btnOK: TRzBitBtn
      Left = 18
      Top = 10
      Width = 105
      ParentColor = True
      TabOrder = 0
      Kind = bkOK
    end
    object RzBitBtn2: TRzBitBtn
      Left = 199
      Top = 10
      Width = 99
      ParentColor = True
      TabOrder = 1
      Kind = bkCancel
    end
  end
end
