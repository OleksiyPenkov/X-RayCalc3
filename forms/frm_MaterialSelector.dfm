object frmMaterialSelector: TfrmMaterialSelector
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Select material'
  ClientHeight = 402
  ClientWidth = 288
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  TextHeight = 15
  object SearchBox1: TSearchBox
    Left = 8
    Top = 8
    Width = 272
    Height = 23
    TabOrder = 0
  end
  object lbFiles: TListBox
    Left = 8
    Top = 37
    Width = 272
    Height = 326
    ItemHeight = 15
    TabOrder = 1
  end
  object BitBtn1: TBitBtn
    Left = 205
    Top = 372
    Width = 75
    Height = 25
    Caption = 'Select'
    ModalResult = 1
    TabOrder = 2
  end
  object BitBtn2: TBitBtn
    Left = 8
    Top = 372
    Width = 75
    Height = 25
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
  end
end
