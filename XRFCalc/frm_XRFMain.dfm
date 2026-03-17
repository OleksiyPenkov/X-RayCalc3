object frmXRFMain: TfrmXRFMain
  Left = 0
  Top = 0
  Caption = 'XRFCalc - Universal Mirror Optimizer'
  ClientHeight = 1006
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
  object splMain: TSplitter
    Left = 400
    Top = 0
    Height = 1006
    ExplicitLeft = 280
  end
  object pnlSidebar: TPanel
    Left = 0
    Top = 0
    Width = 400
    Height = 1006
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object sbConfig: TScrollBox
      Left = 0
      Top = 0
      Width = 400
      Height = 966
      Align = alClient
      BorderStyle = bsNone
      TabOrder = 0
      ExplicitWidth = 280
      ExplicitHeight = 560
      object grpTargets: TGroupBox
        Left = 0
        Top = 0
        Width = 383
        Height = 180
        Align = alTop
        Caption = 'Targets'
        TabOrder = 0
        ExplicitWidth = 263
        object clbTargets: TCheckListBox
          Left = 2
          Top = 17
          Width = 100
          Height = 161
          Align = alLeft
          ItemHeight = 15
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
        end
        object sgWeights: TStringGrid
          Left = 102
          Top = 17
          Width = 279
          Height = 161
          Align = alClient
          ColCount = 2
          FixedCols = 0
          RowCount = 11
          Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goEditing]
          TabOrder = 1
          ExplicitWidth = 159
        end
      end
      object grpElements: TGroupBox
        Left = 0
        Top = 180
        Width = 383
        Height = 150
        Align = alTop
        Caption = 'Element Pool'
        TabOrder = 1
        ExplicitWidth = 263
        object clbElements: TCheckListBox
          Left = 2
          Top = 17
          Width = 379
          Height = 131
          Align = alClient
          Columns = 2
          ItemHeight = 15
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
          ExplicitWidth = 259
        end
      end
      object grpStructure: TGroupBox
        Left = 0
        Top = 330
        Width = 383
        Height = 150
        Align = alTop
        Caption = 'Structure'
        TabOrder = 2
        ExplicitWidth = 263
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
      object grpFitness: TGroupBox
        Left = 0
        Top = 480
        Width = 383
        Height = 180
        Align = alTop
        Caption = 'Fitness'
        TabOrder = 3
        ExplicitWidth = 263
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
      end
      object grpOptimizer: TGroupBox
        Left = 0
        Top = 660
        Width = 383
        Height = 230
        Align = alTop
        Caption = 'Optimizer'
        TabOrder = 4
        ExplicitWidth = 263
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
      object grpSubstrate: TGroupBox
        Left = 0
        Top = 890
        Width = 383
        Height = 50
        Align = alTop
        Caption = 'Substrate'
        TabOrder = 5
        ExplicitWidth = 263
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
      object grpPaths: TGroupBox
        Left = 0
        Top = 940
        Width = 383
        Height = 106
        Align = alTop
        Caption = 'Paths'
        TabOrder = 6
        ExplicitWidth = 263
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
        object edHenkePath: TEdit
          Left = 60
          Top = 20
          Width = 175
          Height = 23
          TabOrder = 0
        end
        object edOutputDir: TEdit
          Left = 60
          Top = 46
          Width = 175
          Height = 23
          TabOrder = 1
        end
        object btnBrowseHenke: TButton
          Left = 240
          Top = 19
          Width = 30
          Height = 25
          Caption = '...'
          TabOrder = 2
          OnClick = btnBrowseHenkeClick
        end
        object btnBrowseOutput: TButton
          Left = 240
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
          Width = 175
          Height = 23
          TabOrder = 4
        end
        object btnBrowseTemplate: TButton
          Left = 240
          Top = 71
          Width = 30
          Height = 25
          Caption = '...'
          TabOrder = 5
          OnClick = btnBrowseTemplateClick
        end
      end
      object grpResults: TGroupBox
        Left = 0
        Top = 1046
        Width = 383
        Height = 200
        Align = alTop
        Caption = 'Results'
        TabOrder = 7
        Visible = False
        ExplicitWidth = 263
        object sgResults: TStringGrid
          Left = 8
          Top = 18
          Width = 260
          Height = 120
          ColCount = 3
          FixedCols = 0
          TabOrder = 0
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
      Top = 966
      Width = 400
      Height = 40
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitTop = 560
      ExplicitWidth = 280
      object lblProgress: TLabel
        Left = 224
        Top = 14
        Width = 32
        Height = 15
        Caption = 'Ready'
      end
      object btnStart: TButton
        Left = 4
        Top = 8
        Width = 50
        Height = 25
        Caption = 'Start'
        TabOrder = 0
        OnClick = btnStartClick
      end
      object btnStop: TButton
        Left = 58
        Top = 8
        Width = 50
        Height = 25
        Caption = 'Stop'
        Enabled = False
        TabOrder = 1
        OnClick = btnStopClick
      end
      object btnLoadConfig: TButton
        Left = 116
        Top = 8
        Width = 50
        Height = 25
        Caption = 'Load'
        TabOrder = 2
        OnClick = btnLoadConfigClick
      end
      object btnSaveConfig: TButton
        Left = 170
        Top = 8
        Width = 50
        Height = 25
        Caption = 'Save'
        TabOrder = 3
        OnClick = btnSaveConfigClick
      end
    end
  end
  object pnlCharts: TPanel
    Left = 403
    Top = 0
    Width = 1154
    Height = 1006
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
    ExplicitLeft = 285
    ExplicitWidth = 715
    ExplicitHeight = 600
    object splCharts: TSplitter
      Left = 0
      Top = 200
      Width = 1154
      Height = 5
      Cursor = crVSplit
      Align = alTop
      ExplicitWidth = 715
    end
    object chartConvergence: TChart
      Left = 0
      Top = 0
      Width = 1154
      Height = 200
      Legend.Visible = False
      Title.Text.Strings = (
        'FoM Convergence')
      LeftAxis.MaximumOffset = 1
      View3D = False
      Align = alTop
      TabOrder = 0
      ExplicitWidth = 715
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
      Top = 205
      Width = 1154
      Height = 801
      Align = alClient
      BevelOuter = bvNone
      TabOrder = 1
      ExplicitWidth = 715
      ExplicitHeight = 395
      object splBottom: TSplitter
        Left = 350
        Top = 0
        Width = 5
        Height = 801
        ExplicitHeight = 395
      end
      object chartRPeak: TChart
        Left = 0
        Top = 0
        Width = 350
        Height = 801
        Legend.Visible = False
        Title.Text.Strings = (
          'Peak Reflectivity')
        View3D = False
        Align = alLeft
        TabOrder = 0
        ExplicitHeight = 395
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
        Left = 355
        Top = 0
        Width = 799
        Height = 801
        Title.Text.Strings = (
          'Reflectivity Curves')
        View3D = False
        Align = alClient
        TabOrder = 1
        ExplicitWidth = 360
        ExplicitHeight = 395
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
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
end
