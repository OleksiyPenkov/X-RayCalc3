object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  HelpContext = 144
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 431
  ClientWidth = 613
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  TextHeight = 13
  object pcSetPages: TPageControl
    AlignWithMargins = True
    Left = 159
    Top = 3
    Width = 451
    Height = 384
    ActivePage = tsBehavour
    Align = alClient
    TabOrder = 1
    object tsPaths: TTabSheet
      HelpContext = 143
      Caption = 'tsPaths'
      TabVisible = False
      object lbl1: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Files and Paths'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 84
      end
      object rzpnl1: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 63
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 0
        object Label4: TLabel
          Left = 8
          Top = 11
          Width = 110
          Height = 13
          Caption = 'Default Project'#39's folder'
        end
        object edProjectDir: TRzButtonEdit
          Tag = 1
          Left = 132
          Top = 14
          Width = 301
          Height = 21
          Text = ''
          TabOrder = 0
          AltBtnNumGlyphs = 1
          ButtonNumGlyphs = 1
          OnButtonClick = edBenchmarkDirButtonClick
        end
      end
      object RzPanel3: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 104
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 1
        object Label5: TLabel
          Left = 8
          Top = 11
          Width = 101
          Height = 13
          Caption = 'Default output folder'
        end
        object edOutputDir: TRzButtonEdit
          Tag = 2
          Left = 132
          Top = 8
          Width = 301
          Height = 21
          Text = ''
          TabOrder = 0
          AltBtnNumGlyphs = 1
          ButtonNumGlyphs = 1
          OnButtonClick = edBenchmarkDirButtonClick
        end
      end
      object RzPanel4: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 145
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 2
        object Label7: TLabel
          Left = 8
          Top = 11
          Width = 110
          Height = 13
          Caption = 'Benchmark input folder'
        end
        object edBenchmarkDir: TRzButtonEdit
          Tag = 3
          Left = 132
          Top = 8
          Width = 301
          Height = 21
          Text = ''
          TabOrder = 0
          AltBtnNumGlyphs = 1
          ButtonNumGlyphs = 1
          OnButtonClick = edBenchmarkDirButtonClick
        end
      end
      object btnRegisterExtensions: TButton
        Left = 3
        Top = 346
        Width = 437
        Height = 25
        Caption = 'Register file associations (xrcx)'
        TabOrder = 3
        OnClick = btnRegisterExtensionsClick
      end
      object RzPanel6: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 22
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 4
        object Label9: TLabel
          Left = 8
          Top = 11
          Width = 59
          Height = 13
          Caption = 'Henke libray'
        end
        object edHenkeDir: TRzButtonEdit
          Left = 132
          Top = 8
          Width = 301
          Height = 21
          Text = ''
          TabOrder = 0
          AltBtnNumGlyphs = 1
          ButtonNumGlyphs = 1
          OnButtonClick = edBenchmarkDirButtonClick
        end
      end
      object RzPanel8: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 186
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 5
        object Label13: TLabel
          Left = 8
          Top = 11
          Width = 118
          Height = 13
          Caption = 'Benchmark output folder'
        end
        object edBenchOutputDir: TRzButtonEdit
          Tag = 4
          Left = 132
          Top = 8
          Width = 301
          Height = 21
          Text = ''
          TabOrder = 0
          AltBtnNumGlyphs = 1
          ButtonNumGlyphs = 1
          OnButtonClick = edBenchmarkDirButtonClick
        end
      end
      object RzPanel9: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 227
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 6
        object Label14: TLabel
          Left = 8
          Top = 11
          Width = 81
          Height = 13
          Caption = 'Batch jobs folder'
        end
        object edJobsDir: TRzButtonEdit
          Tag = 4
          Left = 132
          Top = 8
          Width = 301
          Height = 21
          Text = ''
          TabOrder = 0
          AltBtnNumGlyphs = 1
          ButtonNumGlyphs = 1
          OnButtonClick = edBenchmarkDirButtonClick
        end
      end
    end
    object tsBehavour: TTabSheet
      Caption = 'tsBehavior'
      ImageIndex = 5
      TabVisible = False
      object Panel3: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 362
        Margins.Bottom = 9
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object Label6: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 431
          Height = 13
          Align = alTop
          Caption = 'Behavior'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Transparent = True
          ExplicitWidth = 50
        end
        object chkCheckForUpdates: TCheckBox
          AlignWithMargins = True
          Left = 9
          Top = 91
          Width = 425
          Height = 17
          Margins.Left = 9
          Align = alTop
          Caption = 'Automatically check for updates'
          Color = clBtnFace
          ParentColor = False
          TabOrder = 0
          ExplicitTop = 68
        end
        object chkAutoCalcOpen: TCheckBox
          AlignWithMargins = True
          Left = 9
          Top = 22
          Width = 425
          Height = 17
          Margins.Left = 9
          Align = alTop
          Caption = 'Automatically calculate when opening  poject'
          Color = clBtnFace
          ParentColor = False
          TabOrder = 1
        end
        object chkAutoSaveResults: TCheckBox
          AlignWithMargins = True
          Left = 9
          Top = 68
          Width = 425
          Height = 17
          Margins.Left = 9
          Align = alTop
          Caption = 'Automatically save results to output folder after fitting'
          Color = clBtnFace
          ParentColor = False
          TabOrder = 2
          ExplicitTop = 45
        end
        object chkLiveUpdate: TCheckBox
          AlignWithMargins = True
          Left = 9
          Top = 45
          Width = 425
          Height = 17
          Margins.Left = 9
          Align = alTop
          Caption = 'Live update structure panel during fitting '
          Color = clBtnFace
          ParentColor = False
          TabOrder = 3
        end
      end
    end
    object tsInterface: TTabSheet
      Caption = 'tsInterface'
      ImageIndex = 3
      TabVisible = False
      object Label3: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Interface settings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 102
      end
    end
    object tsCalc: TTabSheet
      Caption = 'Calc & Fit'
      ImageIndex = 3
      TabVisible = False
      object lbl2: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Calc settings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 72
      end
      object Label11: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 63
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Benchmark'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 64
      end
      object RzPanel1: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 22
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 0
        object Label1: TLabel
          Left = 8
          Top = 11
          Width = 137
          Height = 13
          Caption = 'Number od CPU cores to use'
        end
        object cbbCPUCores: TComboBox
          Left = 275
          Top = 8
          Width = 145
          Height = 21
          ItemIndex = 0
          TabOrder = 0
          Text = 'Auto (Use all)'
          Items.Strings = (
            'Auto (Use all)'
            '2'
            '4'
            '8'
            '12'
            '16'
            '32'
            '64')
        end
      end
      object RzPanel7: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 82
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 1
        object Label12: TLabel
          Left = 9
          Top = 9
          Width = 74
          Height = 13
          Caption = 'Number of runs'
        end
        object seBenchRuns: TSpinEdit
          Left = 104
          Top = 6
          Width = 84
          Height = 22
          MaxValue = 100
          MinValue = 1
          TabOrder = 0
          Value = 10
        end
      end
    end
    object tsGraphics: TTabSheet
      Caption = 'tsGraphics'
      ImageIndex = 4
      TabVisible = False
      object lbl3: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Graphics settings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 98
      end
      object RzPanel2: TRzPanel
        AlignWithMargins = True
        Left = 3
        Top = 22
        Width = 437
        Height = 35
        Align = alTop
        BorderOuter = fsFlatRounded
        Color = 15987699
        TabOrder = 0
        object Label2: TLabel
          Left = 9
          Top = 9
          Width = 83
          Height = 13
          Caption = 'Default line width'
        end
        object seLineWidth: TSpinEdit
          Left = 104
          Top = 6
          Width = 84
          Height = 22
          MaxValue = 10
          MinValue = 1
          TabOrder = 0
          Value = 2
        end
      end
    end
  end
  object pnButtons: TPanel
    Left = 0
    Top = 390
    Width = 613
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pnButtons'
    ShowCaption = False
    TabOrder = 2
    DesignSize = (
      613
      41)
    object btnOk: TButton
      Left = 413
      Top = 10
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Save'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = SaveSettingsClick
    end
    object btnCancel: TButton
      Left = 494
      Top = 10
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
    end
    object btnHelp: TButton
      Left = 12
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Help'
      TabOrder = 2
      OnClick = ShowHelpClick
    end
  end
  object tvSections: TTreeView
    AlignWithMargins = True
    Left = 3
    Top = 5
    Width = 150
    Height = 381
    Margins.Top = 5
    Margins.Bottom = 4
    Align = alLeft
    HideSelection = False
    Indent = 19
    RowSelect = True
    TabOrder = 0
    OnChange = tvSectionsChange
    Items.NodeData = {
      070500000009540054007200650065004E006F00640065003D00000000000000
      00000000FFFFFFFFFFFFFFFFFFFFFFFF000000000000000000010F5000610074
      0068007300200061006E0064002000460069006C006500730000002F00000000
      00000000000000FFFFFFFFFFFFFFFF0000000000000000000000000001084200
      650068006100760069006F0072000000310000000000000000000000FFFFFFFF
      FFFFFFFF00000000000000000000000000010949006E00740065007200660061
      00630065000000330000000000000000000000FFFFFFFFFFFFFFFF0000000000
      0000000000000000010A430061006C0063002000260020004600690074000000
      2F0000000000000000000000FFFFFFFFFFFFFFFF000000000000000000000000
      00010847007200610070006800690063007300}
  end
  object dlgColors: TColorDialog
    Left = 32
    Top = 176
  end
  object dlgFolder: TRzSelectFolderDialog
    Left = 411
    Top = 281
  end
end
