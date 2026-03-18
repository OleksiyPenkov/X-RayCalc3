object frmRunConfig: TfrmRunConfig
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'Universal Mirror - Run Configuration'
  ClientHeight = 420
  ClientWidth = 480
  Position = poMainFormCenter
  OnCreate = FormCreate
  PixelsPerInch = 96
  object pnlButtons: TPanel
    Left = 0
    Top = 380
    Width = 480
    Height = 40
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 0
    object btnRun: TButton
      Left = 210
      Top = 8
      Width = 80
      Height = 25
      Caption = 'Run'
      Default = True
      ModalResult = 1
      TabOrder = 0
    end
    object btnSaveConfig: TButton
      Left = 300
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Save Config...'
      TabOrder = 1
      OnClick = btnSaveConfigClick
    end
    object btnCancel: TButton
      Left = 400
      Top = 8
      Width = 70
      Height = 25
      Caption = 'Cancel'
      Cancel = True
      ModalResult = 2
      TabOrder = 2
    end
  end
  object PageControl: TPageControl
    Left = 0
    Top = 0
    Width = 480
    Height = 380
    ActivePage = tabTargets
    Align = alClient
    TabOrder = 1
    object tabTargets: TTabSheet
      Caption = 'Targets'
    end
    object tabStructure: TTabSheet
      Caption = 'Structure'
    end
    object tabOptimizer: TTabSheet
      Caption = 'Optimizer'
    end
    object tabFitness: TTabSheet
      Caption = 'Fitness'
    end
  end
end
