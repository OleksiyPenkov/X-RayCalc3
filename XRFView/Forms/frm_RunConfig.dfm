object frmRunConfig: TfrmRunConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Universal Mirror - Run Configuration'
  ClientHeight = 580
  ClientWidth = 520
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  object pnlButtons: TPanel
    Left = 0
    Top = 540
    Width = 520
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnRun: TButton
      Left = 250
      Top = 8
      Width = 80
      Height = 25
      Caption = 'Run'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnSaveConfig: TButton
      Left = 340
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Save Config...'
      TabOrder = 1
    end
    object btnCancel: TButton
      Left = 440
      Top = 8
      Width = 70
      Height = 25
      Caption = 'Cancel'
      Cancel = True
      ModalResult = 2
      TabOrder = 2
    end
    object chkAdvanced: TCheckBox
      Left = 8
      Top = 12
      Width = 120
      Height = 17
      Caption = 'Show Advanced'
      TabOrder = 3
    end
  end
  object ScrollBox: TScrollBox
    Left = 0
    Top = 0
    Width = 520
    Height = 540
    Align = alClient
    BorderStyle = bsNone
    TabOrder = 1
  end
end
