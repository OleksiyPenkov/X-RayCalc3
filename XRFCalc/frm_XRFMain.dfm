object frmXRFMain: TfrmXRFMain
  Left = 0
  Top = 0
  Caption = 'XRFCalc - Universal Mirror Optimizer'
  ClientHeight = 862
  ClientWidth = 1557
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object pnlCharts: TPanel
    Left = 417
    Top = 0
    Width = 1140
    Height = 862
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 0
    ExplicitLeft = 403
    ExplicitWidth = 1154
    ExplicitHeight = 1006
    object chartConvergence: TChart
      AlignWithMargins = True
      Left = 3
      Top = 659
      Width = 1134
      Height = 200
      Legend.Visible = False
      Title.Text.Strings = (
        'FoM Convergence')
      LeftAxis.MaximumOffset = 1
      View3D = False
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 0
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 1154
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
      object serFoM: TLineSeries
        Title = 'FoM'
        Brush.BackColor = clDefault
        LinePen.Width = 2
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
      end
    end
    object pnlBottomCharts: TPanel
      Left = 0
      Top = 0
      Width = 1140
      Height = 656
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 205
      ExplicitWidth = 1154
      ExplicitHeight = 801
      object splBottom: TSplitter
        Left = 356
        Top = 0
        Width = 5
        Height = 656
        ExplicitLeft = 350
        ExplicitHeight = 395
      end
      object chartRPeak: TChart
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 350
        Height = 650
        Legend.Visible = False
        Title.Text.Strings = (
          'Peak Reflectivity')
        View3D = False
        Align = alLeft
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitLeft = 0
        ExplicitTop = 0
        ExplicitHeight = 801
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
        object serRPeak: TBarSeries
          Marks.OnTop = True
          Title = 'R_peak'
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Bar'
          YValues.Order = loNone
        end
      end
      object chartCurves: TChart
        AlignWithMargins = True
        Left = 364
        Top = 3
        Width = 773
        Height = 650
        Title.Text.Strings = (
          'Reflectivity Curves')
        View3D = False
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 1
        ExplicitLeft = 355
        ExplicitTop = 0
        ExplicitWidth = 799
        ExplicitHeight = 801
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
    end
  end
  object RzPageControl1: TRzPageControl
    Left = 0
    Top = 0
    Width = 417
    Height = 862
    Hint = ''
    ActivePage = TabSheet1
    Align = alLeft
    TabIndex = 0
    TabOrder = 1
    FixedDimension = 21
    object TabSheet1: TRzTabSheet
      AlignWithMargins = True
      Caption = 'Structure'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object pnlSidebar: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 401
        Height = 825
        Align = alClient
        BevelOuter = bvNone
        TabOrder = 0
        ExplicitLeft = -104
        ExplicitTop = -881
        ExplicitWidth = 400
        ExplicitHeight = 1006
        object sbConfig: TScrollBox
          Left = 0
          Top = 0
          Width = 401
          Height = 763
          Align = alClient
          BorderStyle = bsNone
          TabOrder = 0
          ExplicitWidth = 390
          ExplicitHeight = 994
          object grpTargets: TGroupBox
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 395
            Height = 180
            Align = alTop
            Caption = 'Targets'
            TabOrder = 0
            ExplicitLeft = 0
            ExplicitTop = 0
            ExplicitWidth = 383
            object clbTargets: TCheckListBox
              AlignWithMargins = True
              Left = 5
              Top = 20
              Width = 100
              Height = 155
              Align = alLeft
              ItemHeight = 17
              Items.Strings = (
                'B'
                'C'
                'N'
                'O'
                'F'
                'Ne'
                'Na'
                'Mg'
                'Al'
                'Si')
              TabOrder = 0
              ExplicitLeft = 2
              ExplicitTop = 17
              ExplicitHeight = 161
            end
            object sgWeights: TStringGrid
              AlignWithMargins = True
              Left = 111
              Top = 20
              Width = 279
              Height = 155
              Align = alClient
              ColCount = 2
              FixedCols = 0
              RowCount = 11
              Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing]
              TabOrder = 1
              ExplicitLeft = 102
              ExplicitTop = 17
              ExplicitHeight = 161
            end
          end
          object grpElements: TGroupBox
            AlignWithMargins = True
            Left = 3
            Top = 189
            Width = 395
            Height = 150
            Align = alTop
            Caption = 'Element Pool'
            TabOrder = 1
            ExplicitLeft = 0
            ExplicitTop = 180
            ExplicitWidth = 383
            object clbElements: TCheckListBox
              Left = 2
              Top = 17
              Width = 391
              Height = 131
              Align = alClient
              Columns = 2
              ItemHeight = 17
              Items.Strings = (
                'W'
                'Mo'
                'Co'
                'V'
                'Cr'
                'Ru'
                'Ni'
                'Ti'
                'Al'
                'Si'
                'C'
                'B'
                'B4C'
                'SiC'
                'Si3N4'
                'WC')
              TabOrder = 0
              ExplicitWidth = 379
            end
          end
          object grpStructure: TGroupBox
            AlignWithMargins = True
            Left = 3
            Top = 345
            Width = 395
            Height = 150
            Align = alTop
            Caption = 'Structure'
            TabOrder = 2
            ExplicitLeft = 0
            ExplicitTop = 330
            ExplicitWidth = 383
            object lblDMin: TLabel
              Left = 8
              Top = 20
              Width = 31
              Height = 15
              Caption = 'd min'
            end
            object lblDMax: TLabel
              Left = 170
              Top = 20
              Width = 32
              Height = 15
              Caption = 'd max'
            end
            object lblGammaMin: TLabel
              Left = 8
              Top = 46
              Width = 30
              Height = 15
              Caption = #947' min'
            end
            object lblGammaMax: TLabel
              Left = 170
              Top = 46
              Width = 31
              Height = 15
              Caption = #947' max'
            end
            object lblNMin: TLabel
              Left = 8
              Top = 72
              Width = 33
              Height = 15
              Caption = 'N min'
            end
            object lblNMax: TLabel
              Left = 170
              Top = 72
              Width = 34
              Height = 15
              Caption = 'N max'
            end
            object lblSigma: TLabel
              Left = 8
              Top = 98
              Width = 32
              Height = 15
              Caption = 'sigma'
            end
            object edDMin: TEdit
              Left = 80
              Top = 18
              Width = 80
              Height = 23
              TabOrder = 0
            end
            object edDMax: TEdit
              Left = 210
              Top = 18
              Width = 80
              Height = 23
              TabOrder = 1
            end
            object edGammaMin: TEdit
              Left = 80
              Top = 44
              Width = 80
              Height = 23
              TabOrder = 2
            end
            object edGammaMax: TEdit
              Left = 210
              Top = 44
              Width = 80
              Height = 23
              TabOrder = 3
            end
            object edNMin: TEdit
              Left = 80
              Top = 70
              Width = 80
              Height = 23
              TabOrder = 4
            end
            object edNMax: TEdit
              Left = 210
              Top = 70
              Width = 80
              Height = 23
              TabOrder = 5
            end
            object edSigma: TEdit
              Left = 80
              Top = 96
              Width = 80
              Height = 23
              TabOrder = 6
            end
            object cbPureElements: TCheckBox
              Left = 8
              Top = 124
              Width = 120
              Height = 17
              Caption = 'Pure elements'
              TabOrder = 7
            end
          end
          object grpSubstrate: TGroupBox
            AlignWithMargins = True
            Left = 3
            Top = 501
            Width = 395
            Height = 50
            Align = alTop
            Caption = 'Substrate'
            TabOrder = 3
            ExplicitLeft = 0
            ExplicitTop = 890
            ExplicitWidth = 383
            object lblSubstrate: TLabel
              Left = 8
              Top = 22
              Width = 43
              Height = 15
              Caption = 'Material'
            end
            object edSubstrate: TEdit
              Left = 70
              Top = 20
              Width = 200
              Height = 23
              TabOrder = 0
            end
          end
          object grpResults: TGroupBox
            AlignWithMargins = True
            Left = 3
            Top = 557
            Width = 395
            Height = 200
            Align = alTop
            Caption = 'Results'
            TabOrder = 4
            Visible = False
            ExplicitLeft = 0
            ExplicitTop = 1072
            ExplicitWidth = 383
            object sgResults: TStringGrid
              Left = 2
              Top = 17
              Width = 391
              Height = 120
              Align = alTop
              ColCount = 3
              FixedCols = 0
              TabOrder = 0
              ExplicitLeft = 8
              ExplicitTop = 18
              ExplicitWidth = 353
            end
            object btnSaveStructure: TButton
              Left = 8
              Top = 145
              Width = 80
              Height = 25
              Caption = 'Save Struct.'
              TabOrder = 1
              OnClick = btnSaveStructureClick
            end
            object btnSaveCurves: TButton
              Left = 95
              Top = 145
              Width = 80
              Height = 25
              Caption = 'Save Curves'
              TabOrder = 2
              OnClick = btnSaveCurvesClick
            end
            object btnExportXRC: TButton
              Left = 182
              Top = 145
              Width = 90
              Height = 25
              Caption = 'Export to XRC3'
              TabOrder = 3
              OnClick = btnExportXRCClick
            end
          end
        end
        object pnlButtons: TPanel
          Left = 0
          Top = 763
          Width = 401
          Height = 62
          Align = alBottom
          BevelOuter = bvNone
          TabOrder = 1
          ExplicitLeft = 64
          ExplicitTop = 944
          ExplicitWidth = 400
          object lblProgress: TLabel
            Left = 4
            Top = 42
            Width = 32
            Height = 15
            Caption = 'Ready'
          end
          object btnStart: TButton
            Left = 4
            Top = 4
            Width = 50
            Height = 25
            Caption = 'Start'
            TabOrder = 0
            OnClick = btnStartClick
          end
          object btnStop: TButton
            Left = 58
            Top = 4
            Width = 50
            Height = 25
            Caption = 'Stop'
            Enabled = False
            TabOrder = 1
            OnClick = btnStopClick
          end
          object btnRunXrccmd: TButton
            Left = 116
            Top = 4
            Width = 80
            Height = 25
            Caption = 'Run xrccmd'
            TabOrder = 2
            OnClick = btnRunXrccmdClick
          end
          object btnLoadConfig: TButton
            Left = 204
            Top = 4
            Width = 50
            Height = 25
            Caption = 'Load'
            TabOrder = 3
            OnClick = btnLoadConfigClick
          end
          object btnSaveConfig: TButton
            Left = 258
            Top = 4
            Width = 50
            Height = 25
            Caption = 'Save'
            TabOrder = 4
            OnClick = btnSaveConfigClick
          end
          object btnLoadResults: TButton
            Left = 316
            Top = 4
            Width = 75
            Height = 25
            Caption = 'Load Results'
            TabOrder = 5
            OnClick = btnLoadResultsClick
          end
        end
      end
    end
    object TabSheet2: TRzTabSheet
      Caption = 'Optimization'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grpFitness: TGroupBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 407
        Height = 206
        Align = alTop
        Caption = 'Fitness'
        TabOrder = 0
        ExplicitLeft = 0
        ExplicitTop = 8
        ExplicitWidth = 402
        object lblWR: TLabel
          Left = 8
          Top = 20
          Width = 21
          Height = 15
          Caption = 'w_R'
        end
        object lblWFWHM: TLabel
          Left = 8
          Top = 46
          Width = 51
          Height = 15
          Caption = 'w_FWHM'
        end
        object lblRMinThreshold: TLabel
          Left = 8
          Top = 72
          Width = 52
          Height = 15
          Caption = 'R min thr.'
        end
        object lblThetaMin: TLabel
          Left = 8
          Top = 98
          Width = 31
          Height = 15
          Caption = #952' min'
        end
        object lblDeltaTheta: TLabel
          Left = 8
          Top = 124
          Width = 15
          Height = 15
          Caption = #916#952
        end
        object lblPolarization: TLabel
          Left = 8
          Top = 150
          Width = 62
          Height = 15
          Caption = 'Polarization'
        end
        object edWR: TEdit
          Left = 100
          Top = 18
          Width = 80
          Height = 23
          TabOrder = 0
        end
        object edWFWHM: TEdit
          Left = 100
          Top = 44
          Width = 80
          Height = 23
          TabOrder = 1
        end
        object edRMinThreshold: TEdit
          Left = 100
          Top = 70
          Width = 80
          Height = 23
          TabOrder = 2
        end
        object edThetaMin: TEdit
          Left = 100
          Top = 96
          Width = 80
          Height = 23
          TabOrder = 3
        end
        object edDeltaTheta: TEdit
          Left = 100
          Top = 122
          Width = 80
          Height = 23
          TabOrder = 4
        end
        object cmbPolarization: TComboBox
          Left = 100
          Top = 148
          Width = 80
          Height = 23
          Style = csDropDownList
          ItemIndex = 1
          TabOrder = 5
          Text = 'sp'
          Items.Strings = (
            's'
            'sp')
        end
        object lblWPurity: TLabel
          Left = 8
          Top = 176
          Width = 44
          Height = 15
          Caption = 'w_purity'
        end
        object edWPurity: TEdit
          Left = 100
          Top = 174
          Width = 80
          Height = 23
          TabOrder = 6
          Text = '1.0'
        end
      end
      object grpOptimizer: TGroupBox
        AlignWithMargins = True
        Left = 3
        Top = 189
        Width = 407
        Height = 230
        Align = alTop
        Caption = 'Optimizer'
        TabOrder = 1
        ExplicitLeft = 0
        ExplicitTop = 188
        ExplicitWidth = 402
        object lblPopulation: TLabel
          Left = 8
          Top = 20
          Width = 58
          Height = 15
          Caption = 'Population'
        end
        object lblIterations: TLabel
          Left = 8
          Top = 46
          Width = 49
          Height = 15
          Caption = 'Iterations'
        end
        object lblTolerance: TLabel
          Left = 8
          Top = 72
          Width = 51
          Height = 15
          Caption = 'Tolerance'
        end
        object lblStagnationLimit: TLabel
          Left = 8
          Top = 98
          Width = 80
          Height = 15
          Caption = 'Stagnation lim.'
        end
        object lblW1: TLabel
          Left = 8
          Top = 124
          Width = 15
          Height = 15
          Caption = 'w1'
        end
        object lblW2: TLabel
          Left = 8
          Top = 150
          Width = 15
          Height = 15
          Caption = 'w2'
        end
        object lblJammingMax: TLabel
          Left = 8
          Top = 176
          Width = 74
          Height = 15
          Caption = 'Jamming max'
        end
        object lblCheckpointEvery: TLabel
          Left = 8
          Top = 202
          Width = 61
          Height = 15
          Caption = 'Checkpoint'
        end
        object edPopulation: TEdit
          Left = 120
          Top = 18
          Width = 80
          Height = 23
          TabOrder = 0
        end
        object edIterations: TEdit
          Left = 120
          Top = 44
          Width = 80
          Height = 23
          TabOrder = 1
        end
        object edTolerance: TEdit
          Left = 120
          Top = 70
          Width = 80
          Height = 23
          TabOrder = 2
        end
        object edStagnationLimit: TEdit
          Left = 120
          Top = 96
          Width = 80
          Height = 23
          TabOrder = 3
        end
        object edW1: TEdit
          Left = 120
          Top = 122
          Width = 80
          Height = 23
          TabOrder = 4
        end
        object edW2: TEdit
          Left = 120
          Top = 148
          Width = 80
          Height = 23
          TabOrder = 5
        end
        object edJammingMax: TEdit
          Left = 120
          Top = 174
          Width = 80
          Height = 23
          TabOrder = 6
        end
        object edCheckpointEvery: TEdit
          Left = 120
          Top = 200
          Width = 80
          Height = 23
          TabOrder = 7
        end
      end
      object grpPaths: TGroupBox
        AlignWithMargins = True
        Left = 3
        Top = 425
        Width = 407
        Height = 132
        Align = alTop
        Caption = 'Paths'
        TabOrder = 2
        ExplicitLeft = 0
        ExplicitTop = 940
        ExplicitWidth = 383
        object lblHenkePath: TLabel
          Left = 8
          Top = 22
          Width = 34
          Height = 15
          Caption = 'Henke'
        end
        object lblOutputDir: TLabel
          Left = 8
          Top = 48
          Width = 38
          Height = 15
          Caption = 'Output'
        end
        object lblTemplatePath: TLabel
          Left = 8
          Top = 74
          Width = 49
          Height = 15
          Caption = 'Template'
        end
        object lblXrccmdPath: TLabel
          Left = 8
          Top = 100
          Width = 39
          Height = 15
          Caption = 'xrccmd'
        end
        object edHenkePath: TEdit
          Left = 60
          Top = 20
          Width = 265
          Height = 23
          TabOrder = 0
        end
        object edOutputDir: TEdit
          Left = 60
          Top = 46
          Width = 265
          Height = 23
          TabOrder = 1
        end
        object btnBrowseHenke: TButton
          Left = 344
          Top = 19
          Width = 30
          Height = 25
          Caption = '...'
          TabOrder = 2
          OnClick = btnBrowseHenkeClick
        end
        object btnBrowseOutput: TButton
          Left = 344
          Top = 45
          Width = 30
          Height = 25
          Caption = '...'
          TabOrder = 3
          OnClick = btnBrowseOutputClick
        end
        object edTemplatePath: TEdit
          Left = 60
          Top = 72
          Width = 265
          Height = 23
          TabOrder = 4
        end
        object btnBrowseTemplate: TButton
          Left = 344
          Top = 71
          Width = 30
          Height = 25
          Caption = '...'
          TabOrder = 5
          OnClick = btnBrowseTemplateClick
        end
        object edXrccmdPath: TEdit
          Left = 60
          Top = 98
          Width = 265
          Height = 23
          TabOrder = 6
        end
        object btnBrowseXrccmd: TButton
          Left = 344
          Top = 97
          Width = 30
          Height = 25
          Caption = '...'
          TabOrder = 7
          OnClick = btnBrowseXrccmdClick
        end
      end
    end
  end
  object dlgOpen: TOpenDialog
    Filter = 'JSON files|*.json'
    Left = 500
    Top = 300
  end
  object dlgSave: TSaveDialog
    DefaultExt = 'json'
    Filter = 'JSON files|*.json'
    Left = 540
    Top = 300
  end
  object dlgSaveStructure: TSaveDialog
    DefaultExt = 'json'
    Filter = 'JSON|*.json'
    Left = 580
    Top = 300
  end
  object tmrProgress: TTimer
    Enabled = False
    Interval = 500
    OnTimer = tmrProgressTimer
    Left = 620
    Top = 300
  end
  object dlgOpenXrccmd: TOpenDialog
    Filter = 'Executable|*.exe'
    Title = 'Select xrccmd.exe'
    Left = 660
    Top = 300
  end
end
