object frmExtensionSelector: TfrmExtensionSelector
  Left = 0
  Top = 0
  Caption = 'Select extension type'
  ClientHeight = 271
  ClientWidth = 482
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object btnOk: TBitBtn
    Left = 407
    Top = 240
    Width = 75
    Height = 25
    Caption = 'btnOk'
    ModalResult = 1
    TabOrder = 0
  end
  object pnlMain: TPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 476
    Height = 218
    Margins.Bottom = 50
    Align = alClient
    TabOrder = 1
    ExplicitWidth = 472
    ExplicitHeight = 217
    DesignSize = (
      476
      218)
    object txtGradient: TLabel
      Left = 88
      Top = 49
      Width = 253
      Height = 26
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Create a distribution of a layer parameter'
      WordWrap = True
      ExplicitWidth = 274
    end
    object txtUnregister: TLabel
      Left = 88
      Top = 119
      Width = 309
      Height = 51
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Create a distribution table of structure parameters'
      WordWrap = True
      ExplicitWidth = 330
    end
    object rbGradient: TRadioButton
      Left = 73
      Top = 26
      Width = 248
      Height = 17
      Caption = 'Gradient'
      Checked = True
      TabOrder = 0
      TabStop = True
    end
    object rbProfile: TRadioButton
      Left = 73
      Top = 96
      Width = 248
      Height = 17
      Caption = 'Distribution'
      TabOrder = 1
    end
  end
end
