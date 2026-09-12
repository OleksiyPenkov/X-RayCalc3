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
      object grpLines: TGroupBox
        Align = alTop
        AlignWithMargins = True
        Caption = 'Target XRF Lines'
        Height = 160
        TabOrder = 0
        object lvLines: TListView
          Align = alClient
          AlignWithMargins = True
          Checkboxes = True
          Columns = <
            item
              Caption = 'Element'
              Width = 80
            end
            item
              Caption = 'Weight'
              Width = 60
            end>
          HideSelection = False
          ReadOnly = True
          RowSelect = True
          TabOrder = 0
          ViewStyle = vsReport
          OnSelectItem = LinesSelectItem
        end
        object pnlLineWeight: TPanel
          Align = alBottom
          BevelOuter = bvNone
          Height = 26
          TabOrder = 1
          object lblLineWeight: TLabel
            Left = 8
            Top = 5
            Caption = 'Weight:'
          end
          object edtLineWeight: TEdit
            Left = 60
            Top = 2
            Width = 60
            TabOrder = 0
            Text = '1.0'
            OnExit = LineWeightExit
          end
        end
      end
      object grpPool: TGroupBox
        Align = alTop
        AlignWithMargins = True
        Caption = 'Element Pool'
        Height = 110
        TabOrder = 1
        object clbPool: TCheckListBox
          Align = alClient
          AlignWithMargins = True
          Columns = 4
          TabOrder = 0
        end
      end
      object grpExcludedPairs: TGroupBox
        Align = alTop
        AlignWithMargins = True
        Caption = 'Excluded Pairs'
        Height = 110
        TabOrder = 2
        object clbExcludedPairs: TCheckListBox
          Align = alClient
          AlignWithMargins = True
          Columns = 3
          TabOrder = 0
        end
      end
    end
    object tabStructure: TRzTabSheet
      Caption = 'Structure'
      object lblDMin: TLabel
        Left = 8
        Top = 14
        Caption = 'd min (A)'
      end
      object lblDMax: TLabel
        Left = 8
        Top = 40
        Caption = 'd max (A)'
      end
      object lblGammaMin: TLabel
        Left = 8
        Top = 70
        Caption = 'Gamma min (x100)'
      end
      object lblGammaMax: TLabel
        Left = 8
        Top = 96
        Caption = 'Gamma max (x100)'
      end
      object lblNMin: TLabel
        Left = 8
        Top = 126
        Caption = 'N min'
      end
      object lblNMax: TLabel
        Left = 8
        Top = 152
        Caption = 'N max'
      end
      object lblSigma: TLabel
        Left = 8
        Top = 186
        Caption = 'Sigma (A)'
      end
      object lblDensityFactor: TLabel
        Left = 8
        Top = 212
        Caption = 'Density factor'
      end
      object lblSubstrate: TLabel
        Left = 8
        Top = 238
        Caption = 'Substrate'
      end
      object sedDMin: TSpinEdit
        Left = 108
        Top = 10
        Width = 70
        MaxValue = 500
        MinValue = 10
        TabOrder = 0
        Value = 30
      end
      object sedDMax: TSpinEdit
        Left = 108
        Top = 36
        Width = 70
        MaxValue = 500
        MinValue = 10
        TabOrder = 1
        Value = 80
      end
      object sedGammaMin: TSpinEdit
        Left = 108
        Top = 66
        Width = 70
        MaxValue = 99
        MinValue = 1
        TabOrder = 2
        Value = 15
      end
      object sedGammaMax: TSpinEdit
        Left = 108
        Top = 92
        Width = 70
        MaxValue = 99
        MinValue = 1
        TabOrder = 3
        Value = 70
      end
      object sedNMin: TSpinEdit
        Left = 108
        Top = 122
        Width = 70
        MaxValue = 1000
        MinValue = 1
        TabOrder = 4
        Value = 40
      end
      object sedNMax: TSpinEdit
        Left = 108
        Top = 148
        Width = 70
        MaxValue = 1000
        MinValue = 1
        TabOrder = 5
        Value = 200
      end
      object edtSigma: TEdit
        Left = 108
        Top = 182
        Width = 70
        TabOrder = 6
        Text = '3.5'
      end
      object edtDensityFactor: TEdit
        Left = 108
        Top = 208
        Width = 70
        TabOrder = 7
        Text = '0.95'
      end
      object edtSubstrate: TEdit
        Left = 108
        Top = 234
        Width = 70
        TabOrder = 8
        Text = 'SiO2'
      end
      object chkPureElements: TCheckBox
        Left = 8
        Top = 260
        Width = 200
        Caption = 'Pure elements (no mixing)'
        Checked = True
        State = cbChecked
        TabOrder = 9
      end
      object grpTemplate: TGroupBox
        Left = 8
        Top = 285
        Width = 270
        Height = 50
        Caption = 'Template File'
        TabOrder = 10
        object edtTemplatePath: TEdit
          Left = 8
          Top = 20
          Width = 210
          TabOrder = 0
        end
        object btnBrowseTemplate: TButton
          Left = 225
          Top = 18
          Width = 35
          Height = 25
          Caption = '...'
          TabOrder = 1
          OnClick = BrowseTemplateClick
        end
      end
    end
    object tabOptimizer: TRzTabSheet
      Caption = 'Optimizer'
      object lblPopulation: TLabel
        Left = 8
        Top = 14
        Caption = 'Population'
      end
      object lblIterations: TLabel
        Left = 8
        Top = 40
        Caption = 'Iterations'
      end
      object lblStagnation: TLabel
        Left = 8
        Top = 66
        Caption = 'Stagnation limit'
      end
      object lblW1: TLabel
        Left = 8
        Top = 100
        Caption = 'PSO w1'
      end
      object lblW2: TLabel
        Left = 8
        Top = 126
        Caption = 'PSO w2'
      end
      object lblTolerance: TLabel
        Left = 8
        Top = 152
        Caption = 'Tolerance'
      end
      object lblJammingMax: TLabel
        Left = 8
        Top = 178
        Caption = 'Jamming max'
      end
      object lblCheckpointEvery: TLabel
        Left = 8
        Top = 204
        Caption = 'Checkpoint every'
      end
      object sedPopulation: TSpinEdit
        Left = 108
        Top = 10
        Width = 70
        MaxValue = 10000
        MinValue = 10
        TabOrder = 0
        Value = 1000
      end
      object sedIterations: TSpinEdit
        Left = 108
        Top = 36
        Width = 70
        MaxValue = 10000
        MinValue = 1
        TabOrder = 1
        Value = 100
      end
      object sedStagnation: TSpinEdit
        Left = 108
        Top = 62
        Width = 70
        MaxValue = 10000
        MinValue = 1
        TabOrder = 2
        Value = 200
      end
      object edtW1: TEdit
        Left = 108
        Top = 96
        Width = 70
        TabOrder = 3
        Text = '0.4'
      end
      object edtW2: TEdit
        Left = 108
        Top = 122
        Width = 70
        TabOrder = 4
        Text = '0.5'
      end
      object edtTolerance: TEdit
        Left = 108
        Top = 148
        Width = 70
        TabOrder = 5
        Text = '1e-5'
      end
      object sedJammingMax: TSpinEdit
        Left = 108
        Top = 174
        Width = 70
        MaxValue = 100
        MinValue = 1
        TabOrder = 6
        Value = 5
      end
      object sedCheckpointEvery: TSpinEdit
        Left = 108
        Top = 200
        Width = 70
        MaxValue = 10000
        MinValue = 1
        TabOrder = 7
        Value = 100
      end
    end
    object tabFitness: TRzTabSheet
      Caption = 'Fitness'
      object lblWR: TLabel
        Left = 8
        Top = 14
        Caption = 'w_R'
      end
      object lblWFWHM: TLabel
        Left = 8
        Top = 40
        Caption = 'w_FWHM'
      end
      object lblNRef: TLabel
        Left = 186
        Top = 40
        Caption = 'n_ref'
      end
      object lblWPurity: TLabel
        Left = 8
        Top = 66
        Caption = 'w_purity'
      end
      object lblRMinThreshold: TLabel
        Left = 8
        Top = 92
        Caption = 'R_min threshold'
      end
      object lblDeltaTheta: TLabel
        Left = 8
        Top = 126
        Caption = 'Delta theta (deg)'
      end
      object lblThetaMin: TLabel
        Left = 8
        Top = 152
        Caption = 'Theta min (deg)'
      end
      object lblPolarization: TLabel
        Left = 8
        Top = 178
        Caption = 'Polarization'
      end
      object lblScanPoints: TLabel
        Left = 8
        Top = 212
        Caption = 'Scan points'
      end
      object lblScanHalfRange: TLabel
        Left = 8
        Top = 238
        Caption = 'Scan half-range'
      end
      object edtWR: TEdit
        Left = 108
        Top = 10
        Width = 70
        TabOrder = 0
        Text = '1.0'
      end
      object edtWFWHM: TEdit
        Left = 108
        Top = 36
        Width = 70
        TabOrder = 1
        Text = '0.25'
      end
      object sedNRef: TSpinEdit
        Left = 222
        Top = 36
        Width = 56
        MaxValue = 10000
        MinValue = 1
        TabOrder = 2
        Value = 50
      end
      object edtWPurity: TEdit
        Left = 108
        Top = 62
        Width = 70
        TabOrder = 3
        Text = '1.0'
      end
      object edtRMinThreshold: TEdit
        Left = 108
        Top = 88
        Width = 70
        TabOrder = 4
        Text = '0.001'
      end
      object edtDeltaTheta: TEdit
        Left = 108
        Top = 122
        Width = 70
        TabOrder = 5
        Text = '0'
      end
      object edtThetaMin: TEdit
        Left = 108
        Top = 148
        Width = 70
        TabOrder = 6
        Text = '0'
      end
      object cmbPolarization: TComboBox
        Left = 108
        Top = 174
        Width = 70
        Style = csDropDownList
        ItemIndex = 0
        TabOrder = 7
        Text = 'sp'
        Items.Strings = (
          'sp'
          's')
      end
      object sedScanPoints: TSpinEdit
        Left = 108
        Top = 208
        Width = 70
        MaxValue = 10000
        MinValue = 0
        TabOrder = 8
        Value = 0
      end
      object edtScanHalfRange: TEdit
        Left = 108
        Top = 234
        Width = 70
        TabOrder = 9
        Text = '0'
      end
      object grpHenke: TGroupBox
        Left = 8
        Top = 268
        Width = 270
        Height = 50
        Caption = 'Henke Database Path'
        TabOrder = 10
        object edtHenkePath: TEdit
          Left = 8
          Top = 20
          Width = 210
          TabOrder = 0
          Text = 'D:\DelphiProjects\X-RayCalc\Henke'
        end
        object btnBrowseHenke: TButton
          Left = 225
          Top = 18
          Width = 35
          Height = 25
          Caption = '...'
          TabOrder = 1
          OnClick = BrowseHenkeClick
        end
      end
      object grpXRFLines: TGroupBox
        Left = 8
        Top = 324
        Width = 270
        Height = 50
        Caption = 'XRF Lines File'
        TabOrder = 11
        object edtXRFLinesPath: TEdit
          Left = 8
          Top = 20
          Width = 210
          TabOrder = 0
        end
        object btnBrowseXRFLines: TButton
          Left = 225
          Top = 18
          Width = 35
          Height = 25
          Caption = '...'
          TabOrder = 1
          OnClick = BrowseXRFLinesClick
        end
      end
    end
  end
end
