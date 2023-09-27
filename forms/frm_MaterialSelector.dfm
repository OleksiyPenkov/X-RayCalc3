object frmMaterialSelector: TfrmMaterialSelector
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'Select material'
  ClientHeight = 391
  ClientWidth = 278
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  DesignSize = (
    278
    391)
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
    Left = 185
    Top = 360
    Width = 75
    Height = 25
    Anchors = [akRight, akBottom]
    Caption = 'Select'
    ModalResult = 1
    TabOrder = 2
    ExplicitLeft = 205
    ExplicitTop = 372
  end
  object BitBtn2: TBitBtn
    Left = 8
    Top = 360
    Width = 75
    Height = 25
    Anchors = [akLeft, akBottom]
    Caption = 'Cancel'
    ModalResult = 2
    TabOrder = 3
    ExplicitTop = 372
  end
end
