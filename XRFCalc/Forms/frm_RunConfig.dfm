object frmRunConfig: TfrmRunConfig
  Left = 0
  Top = 0
  Width = 300
  Height = 500
  Align = alClient
  TabOrder = 0
  object PageControl: TRzPageControl
    Left = 0
    Top = 0
    Width = 300
    Height = 500
    ActivePage = tabTargets
    Align = alClient
    TabOrder = 0
    FixedDimension = 21
    object tabTargets: TRzTabSheet
      Caption = 'Targets'
    end
    object tabStructure: TRzTabSheet
      Caption = 'Structure'
    end
    object tabOptimizer: TRzTabSheet
      Caption = 'Optimizer'
    end
    object tabFitness: TRzTabSheet
      Caption = 'Fitness'
    end
  end
end
