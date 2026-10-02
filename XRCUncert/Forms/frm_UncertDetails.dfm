object frmUncertDetails: TfrmUncertDetails
  Left = 0
  Top = 0
  BorderIcons = [biSystemMenu, biMaximize]
  Caption = 'Details'
  ClientHeight = 420
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poOwnerFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  object memDetails: TMemo
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 588
    Height = 368
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 0
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 0
    WordWrap = False
  end
  object pnlBottom: TPanel
    Left = 0
    Top = 374
    Width = 600
    Height = 46
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 1
    DesignSize = (
      600
      46)
    object btnClose: TButton
      Left = 509
      Top = 10
      Width = 85
      Height = 26
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = 'Close'
      Default = True
      ModalResult = 2
      TabOrder = 0
    end
  end
end
