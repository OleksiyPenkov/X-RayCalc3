object frmMain: TfrmMain
  Left = 190
  Top = 152
  Caption = 'X-Ray Calc 3'
  ClientHeight = 1110
  ClientWidth = 1982
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Menu = mmMain
  Position = poDesigned
  WindowState = wsMaximized
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnShow = FormShow
  TextHeight = 15
  object Status: TRzStatusBar
    Left = 0
    Top = 1091
    Width = 1982
    Height = 19
    BorderInner = fsNone
    BorderOuter = fsNone
    BorderSides = [sdLeft, sdTop, sdRight, sdBottom]
    BorderWidth = 0
    Color = 15987699
    TabOrder = 0
    object spnTime: TRzStatusPane
      Left = 0
      Top = 0
      Height = 19
      Align = alLeft
      Caption = ''
    end
    object spnFitTime: TRzStatusPane
      Left = 100
      Top = 0
      Width = 150
      Height = 19
      Align = alLeft
      Caption = ''
    end
    object RzVersionInfoStatus1: TRzVersionInfoStatus
      Left = 1852
      Top = 0
      Height = 19
      Align = alRight
      Field = vifFileVersion
      VersionInfo = frmAbout.RzVersionInfo
      FileVersionFormat = fvfFull
      ExplicitLeft = 1542
    end
    object pnlX64: TRzStatusPane
      Left = 1952
      Top = 0
      Width = 30
      Height = 19
      Align = alRight
      Caption = 'x64'
      ExplicitLeft = 1642
    end
  end
  object LeftSplitter: TRzSplitter
    Left = 0
    Top = 0
    Width = 1982
    Height = 1091
    Position = 245
    Percent = 12
    UpperLeft.Color = 15987699
    LowerRight.Color = 15987699
    SplitterWidth = 8
    Align = alClient
    Color = 15987699
    TabOrder = 1
    BarSize = (
      245
      0
      253
      1091)
    UpperLeftControls = (
      FProjectPanel)
    LowerRightControls = (
      pnlMain
      FStructurePanel)
    inline FProjectPanel: TfrmProjectPanel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 239
      Height = 1085
      Align = alClient
      Color = 15987699
      ParentColor = False
      TabOrder = 0
      ExplicitLeft = 3
      ExplicitTop = 3
      inherited tlbrFile: TRzToolbar
        ExplicitLeft = 3
        ExplicitTop = 3
        ExplicitWidth = 233
        ToolbarControls = (
          BtnNew
          BtnOpen
          btnReopenProject
          rzspcr2
          BtnSave
          RzSpacer1
          BtnPrint)
      end
      inherited tlbrProject: TRzToolbar
        ExplicitLeft = 3
        ExplicitTop = 38
        ExplicitWidth = 233
        ToolbarControls = (
          btnAddModel
          BtnExport
          BtnCopy
          BtnPaste
          BtnEdit
          RzSpacer4
          btnAddExtension
          RzSpacer5
          BtnRecycle)
      end
      inherited RzPanel5: TRzPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitLeft = 3
        ExplicitTop = 1000
        ExplicitWidth = 233
      end
    end
    object pnlMain: TRzPanel
      AlignWithMargins = True
      Left = 356
      Top = 3
      Width = 1373
      Height = 1085
      Margins.Left = 0
      Margins.Right = 0
      Align = alClient
      BorderOuter = fsFlatRounded
      TabOrder = 0
      Color = 15987699
      object RzPanel3: TRzPanel
        AlignWithMargins = True
        Left = 5
        Top = 888
        Width = 1363
        Height = 192
        Align = alBottom
        BorderOuter = fsFlatRounded
        FlatColor = clSkyBlue
        TabOrder = 0
        Color = 15987699
        inline FChartPages: TfrmChartPages
          AlignWithMargins = True
          Left = 5
          Top = 5
          Width = 1353
          Height = 182
          Align = alClient
          TabOrder = 0
          ExplicitLeft = 5
          ExplicitTop = 5
          ExplicitWidth = 1353
          ExplicitHeight = 182
          inherited Pages: TRzPageControl
            Width = 1353
            Height = 182
            ExplicitWidth = 1353
            ExplicitHeight = 182
            FixedDimension = 21
            inherited tsThickness: TRzTabSheet
              ExplicitLeft = 1
              ExplicitTop = 22
              ExplicitWidth = 1044
              ExplicitHeight = 138
            end
            inherited tsRoughness: TRzTabSheet
              ExplicitLeft = 1
              ExplicitTop = 22
              ExplicitWidth = 1044
              ExplicitHeight = 138
            end
            inherited tsDensity: TRzTabSheet
              ExplicitLeft = 1
              ExplicitTop = 22
              ExplicitWidth = 1044
              ExplicitHeight = 138
            end
            inherited tsProfile: TRzTabSheet
              ExplicitWidth = 1349
              ExplicitHeight = 157
              inherited chProfile: TChart
                Width = 1343
                Height = 151
                ExplicitWidth = 1343
                ExplicitHeight = 151
              end
            end
            inherited tsFittingProgress: TRzTabSheet
              ExplicitLeft = 0
              ExplicitTop = 0
              ExplicitWidth = 0
              ExplicitHeight = 0
            end
          end
        end
      end
      object pnlSettings: TPanel
        AlignWithMargins = True
        Left = 5
        Top = 40
        Width = 1363
        Height = 118
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 1
        inline FCalcSettings: TfrmCalcSettings
          Left = 0
          Top = 0
          Width = 1363
          Height = 118
          Margins.Left = 12
          Margins.Top = 12
          Margins.Right = 12
          Margins.Bottom = 12
          Align = alClient
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
          TabOrder = 0
          ExplicitWidth = 1363
          inherited RzPanel6: TRzPanel
            Width = 967
            StyleElements = [seFont, seClient, seBorder]
            ExplicitWidth = 967
            ExplicitHeight = 109
            inherited Label7: TLabel
              StyleElements = [seFont, seClient, seBorder]
            end
            inherited Label8: TLabel
              StyleElements = [seFont, seClient, seBorder]
            end
            inherited lblPolyOrder: TLabel
              StyleElements = [seFont, seClient, seBorder]
            end
            inherited Label21: TLabel
              StyleElements = [seFont, seClient, seBorder]
            end
            inherited rgFittingMode: TRzRadioGroup
              StyleElements = [seFont, seClient, seBorder]
            end
            inherited edFIter: TEdit
              Height = 21
              StyleElements = [seFont, seClient, seBorder]
              ExplicitHeight = 21
            end
            inherited edFPopulation: TEdit
              Height = 21
              StyleElements = [seFont, seClient, seBorder]
              ExplicitHeight = 21
            end
            inherited cbLFPSOShake: TRzCheckBox
              Width = 52
              Height = 19
              AutoSizeWidth = 52
              ExplicitWidth = 52
              ExplicitHeight = 19
            end
            inherited cbSeedRange: TRzCheckBox
              Width = 54
              Height = 19
              AutoSizeWidth = 54
              ExplicitWidth = 54
              ExplicitHeight = 19
            end
            inherited edPolyOrder: TEdit
              Height = 21
              StyleElements = [seFont, seClient, seBorder]
              ExplicitHeight = 21
            end
            inherited cbTWChi: TComboBox
              StyleElements = [seFont, seClient, seBorder]
              ExplicitHeight = 21
            end
            inherited cbPWChiSqr: TRzCheckBox
              Width = 54
              Height = 19
              AutoSizeWidth = 54
              ExplicitWidth = 54
              ExplicitHeight = 19
            end
            inherited cbSmooth: TRzCheckBox
              Width = 59
              Height = 19
              AutoSizeWidth = 59
              ExplicitWidth = 59
              ExplicitHeight = 19
            end
          end
          inherited RzPanel7: TRzPanel
            StyleElements = [seFont, seClient, seBorder]
            inherited rgPolarisation: TRzRadioGroup
              StyleElements = [seFont, seClient, seBorder]
              TabOrder = 3
            end
            inherited pnlWaveParams: TRzPanel
              StyleElements = [seFont, seClient, seBorder]
              inherited Label9: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited Label10: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited Label11: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited Label12: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited edStartL: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited edEndL: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited edTheta: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited edDL: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
            end
            inherited pnlAngleParams: TRzPanel
              StyleElements = [seFont, seClient, seBorder]
              inherited Label1: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited Label2: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited Label3: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited Label4: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited edStartTeta: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited edEndTeta: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited edWidth: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited edLambda: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
              inherited cb2Theta: TRzCheckBox
                Width = 39
                AutoSizeWidth = 39
                ExplicitWidth = 39
              end
            end
            inherited rgCalcMode: TRzRadioGroup
              StyleElements = [seFont, seClient, seBorder]
              TabOrder = 0
            end
            inherited RzGroupBox2: TRzGroupBox
              StyleElements = [seFont, seClient, seBorder]
              inherited edN: TEdit
                Height = 21
                StyleElements = [seFont, seClient, seBorder]
                ExplicitHeight = 21
              end
            end
          end
        end
      end
      object ChartToolBar: TRzToolbar
        AlignWithMargins = True
        Left = 5
        Top = 5
        Width = 1363
        Height = 29
        Images = vilCalc
        TextOptions = ttoCustom
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        StyleName = 'Windows'
        TabOrder = 2
        ToolbarControls = (
          btnCalcRun
          BtnFastForward
          BtnExecute
          RzSpacer2
          rzspcr4
          btnResultSave
          btnBtnCopy
          btnCopyImage
          btnPrintGraphics
          rzspcr3
          btnDataLoad
          btnDataPaste)
        object btnDataLoad: TRzToolButton
          Left = 236
          Top = 2
          Hint = 'Load curve'
          ImageIndex = 3
          Action = DataLoad
          ParentShowHint = False
          ShowHint = True
        end
        object btnDataPaste: TRzToolButton
          Left = 264
          Top = 2
          Hint = 'Paste curve'
          ImageIndex = 4
          Action = DataPaste
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr3: TRzSpacer
          Left = 225
          Top = 2
        end
        object btnCalcRun: TRzToolButton
          Left = 7
          Top = 2
          Hint = 'Calculate'
          ImageIndex = 0
          Action = CalcRun
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr4: TRzSpacer
          Left = 102
          Top = 2
        end
        object btnResultSave: TRzToolButton
          Left = 113
          Top = 2
          Hint = 'Save resulting curve'
          ImageIndex = 5
          Action = ResultSave
          ParentShowHint = False
          ShowHint = True
        end
        object btnBtnCopy: TRzToolButton
          Left = 141
          Top = 2
          Hint = 'Copy resulting curve'
          ImageIndex = 6
          Action = ResultCopy
          ParentShowHint = False
          ShowHint = True
        end
        object RzSpacer2: TRzSpacer
          Left = 91
          Top = 2
        end
        object BtnExecute: TRzToolButton
          Left = 63
          Top = 2
          Hint = 'Auto Fitting'
          ImageIndex = 2
          Action = actAutoFitting
          ParentShowHint = False
          ShowHint = True
        end
        object BtnFastForward: TRzToolButton
          Left = 35
          Top = 2
          Hint = 'Calculate all'
          ImageIndex = 1
          Action = CalcAll
          ParentShowHint = False
          ShowHint = True
        end
        object btnCopyImage: TRzToolButton
          Left = 169
          Top = 2
          Hint = 'Copy resulting curve as image'
          ImageIndex = 7
          Action = FilePlotCopyWMF
          ParentShowHint = False
          ShowHint = True
        end
        object btnPrintGraphics: TRzToolButton
          Left = 197
          Top = 2
          Hint = 'Save chart as image'
          ImageIndex = 8
          Action = FilePlotToFile
          ParentShowHint = False
          ShowHint = True
        end
      end
      inline FChartInfo: TfrmChartInfo
        AlignWithMargins = True
        Left = 5
        Top = 164
        Width = 1363
        Height = 718
        Align = alClient
        Color = 15987699
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = []
        ParentColor = False
        ParentFont = False
        TabOrder = 3
        ExplicitLeft = 5
        ExplicitTop = 164
        ExplicitWidth = 1363
        ExplicitHeight = 718
        inherited Chart: TChart
          Width = 1357
          Height = 662
        end
        inherited pnlInfo: TRzPanel
          Top = 668
          Width = 1363
          StyleElements = [seFont, seClient, seBorder]
          ExplicitTop = 668
          ExplicitWidth = 1363
          inherited btnChartScale: TRzBitBtn
            Left = 1155
            ExplicitLeft = 1155
          end
          inherited cbMinLimit: TRzComboBox
            Left = 1236
            StyleElements = [seFont, seClient, seBorder]
            ExplicitLeft = 1236
          end
        end
      end
    end
    inline FStructurePanel: TfrmStructurePanel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 350
      Height = 1085
      Align = alLeft
      Color = 15987699
      ParentColor = False
      TabOrder = 1
      ExplicitLeft = 3
      ExplicitTop = 3
      ExplicitHeight = 1085
      inherited tlbStructure: TRzToolbar
        ToolbarControls = (
          btnPeriodAdd
          btnPeriodInsert
          btnPeriodDelete
          rzspcr1
          btnLayerAdd
          btnLayerInsert
          btnCopyLayer
          btnLayerCut
          btnLayerPaste
          RzSpacer3
          btnLayerDelete)
      end
      inherited RzPanel2: TRzPanel
        StyleElements = [seFont, seClient, seBorder]
        ExplicitTop = 38
        inherited Label6: TLabel
          StyleElements = [seFont, seClient, seBorder]
        end
        inherited cbIncrement: TRzComboBox
          StyleElements = [seFont, seClient, seBorder]
        end
      end
    end
  end
  object mmMain: TMainMenu
    Images = vilMenu
    Left = 512
    Top = 368
    object File1: TMenuItem
      Caption = 'File'
      object File2: TMenuItem
        ImageIndex = 0
        Action = FileNew
      end
      object Openproject1: TMenuItem
        ImageIndex = 1
        Action = FileOpen
      end
      object miRecent: TMenuItem
        ImageIndex = 2
        Caption = 'Recent projects'
      end
      object Openproject2: TMenuItem
        ImageIndex = 3
        Action = FileSave
      end
      object Saveprojectas1: TMenuItem
        ImageIndex = 42
        Action = FileSaveAs
      end
      object Saveprojectas2: TMenuItem
        Caption = '-'
      end
      object Settings1: TMenuItem
        ImageIndex = 29
        Action = actSystemSettings
      end
      object Settings2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        ImageIndex = 30
        Action = actSystemExit
      end
    end
    object Project1: TMenuItem
      Caption = 'Project'
      object New1: TMenuItem
        ImageIndex = 5
        Action = ModelCreate
        Caption = 'New model'
      end
      object Newextension1: TMenuItem
        ImageIndex = 7
        Action = actProjectItemDuplicate
      end
      object Copymodel1: TMenuItem
        ImageIndex = 7
        Action = actModelCopy
      end
      object PasteModel1: TMenuItem
        Action = actModelPaste
      end
      object N8: TMenuItem
        Caption = '-'
      end
      object NewFolder1: TMenuItem
        ImageIndex = 31
        Action = ProjectAddFolder
      end
    end
    object Project2: TMenuItem
      Caption = 'Structure'
      Hint = 'Add Stack'
      object Add1: TMenuItem
        ImageIndex = 13
        Action = PeriodAdd
        Caption = 'Add Stack'
      end
      object Insert1: TMenuItem
        ImageIndex = 13
        Action = PeriodInsert
        Caption = 'Insert Stack'
      end
      object Delete1: TMenuItem
        ImageIndex = 18
        Action = PeriodDelete
        Caption = 'Delete Stack'
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object Add2: TMenuItem
        ImageIndex = 12
        Action = LayerAdd
        Caption = 'Add Layer'
      end
      object Insert2: TMenuItem
        ImageIndex = 12
        Action = LayerInsert
        Caption = 'Insert Layer'
      end
      object Copy1: TMenuItem
        ImageIndex = 20
        Action = actLayerCopy
        Caption = 'Copy Layer'
      end
      object Paste1: TMenuItem
        ImageIndex = 16
        Action = LayerPaste
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object actProjecEditModelText1: TMenuItem
        ImageIndex = 9
        Action = actProjecEditModelText
      end
      object mnuImportStructure: TMenuItem
        Action = actImportStructure
      end
      object Copyasimage1: TMenuItem
        ImageIndex = 28
        Action = actCopyStructureBitmap
      end
      object N9: TMenuItem
        Caption = '-'
      end
      object Cut1: TMenuItem
        ImageIndex = 15
        Action = LayerCut
      end
      object Delete2: TMenuItem
        ImageIndex = 11
        Action = LayerDelete
      end
      object N12: TMenuItem
        Caption = '-'
      end
      object N13: TMenuItem
        Caption = '-'
      end
      object Undo1: TMenuItem
        ImageIndex = 32
        Action = acStructureUndo
      end
    end
    object Data1: TMenuItem
      Caption = 'Data'
      object Loadfromfile1: TMenuItem
        ImageIndex = 24
        Action = DataLoad
        Caption = 'Load ...'
      end
      object Pastefromclipboard1: TMenuItem
        ImageIndex = 25
        Action = DataPaste
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object Normalize1: TMenuItem
        ImageIndex = 33
        Action = DataNorm
        Caption = 'Normalize ...'
      end
      object NormalizeAuto1: TMenuItem
        ImageIndex = 33
        Action = DataNormAuto
        Caption = 'Normalize (Auto)'
      end
      object Smooth1: TMenuItem
        ImageIndex = 34
        Action = actDataSmooth
      end
      object rim1: TMenuItem
        ImageIndex = 35
        Action = actDataTrim
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object Copytoclipboad1: TMenuItem
        ImageIndex = 27
        Action = DataCopyClpbrd
        Caption = 'Copy to clipboard'
      end
      object Exporttofile1: TMenuItem
        ImageIndex = 6
        Caption = 'Export to file ...'
      end
    end
    object Calc1: TMenuItem
      Caption = 'Calc'
      object Calc3: TMenuItem
        ImageIndex = 21
        Action = CalcRun
      end
      object Calcall1: TMenuItem
        ImageIndex = 22
        Caption = 'Calc all'
        ShortCut = 123
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object Fitting1: TMenuItem
        ImageIndex = 23
        Action = actAutoFitting
      end
      object Calcbatchjobs1: TMenuItem
        ImageIndex = 36
        Action = actCalcFitJobs
      end
      object N14: TMenuItem
        Caption = '-'
      end
      object Benchmark1: TMenuItem
        ImageIndex = 37
        Action = actCalcBenchmark
      end
    end
    object Result1: TMenuItem
      Caption = 'Result'
      object Save1: TMenuItem
        ImageIndex = 26
        Action = ResultSave
      end
      object Saveplotasfile1: TMenuItem
        ImageIndex = 6
        Action = FilePlotToFile
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Copytoclipboard1: TMenuItem
        ImageIndex = 27
        Action = ResultCopy
      end
      object CopyasBMP1: TMenuItem
        ImageIndex = 28
        Action = FileCopyPlotBMP
      end
      object CopyasWMF1: TMenuItem
        ImageIndex = 28
        Action = FilePlotCopyWMF
      end
      object N16: TMenuItem
        Caption = '-'
      end
      object ExportFitResults1: TMenuItem
        ImageIndex = 6
        Action = FitExportJSON
      end
    end
    object ools1: TMenuItem
      Caption = 'Tools'
      object ShowLibrary1: TMenuItem
        ImageIndex = 38
        Action = actNewMaterial
        Caption = 'Create new material ...'
      end
      object EditHenketable1: TMenuItem
        ImageIndex = 39
        Action = actEditHenke
      end
      object N11: TMenuItem
        Caption = '-'
      end
      object MaterialsLibrary1: TMenuItem
        ImageIndex = 38
        Caption = 'Materials Library'
        Enabled = False
      end
    end
    object Calc2: TMenuItem
      Caption = 'Help'
      object UserManual1: TMenuItem
        ImageIndex = 40
        Action = HelpContent
      end
      object N15: TMenuItem
        Caption = '-'
      end
      object About1: TMenuItem
        ImageIndex = 41
        Action = HelpAbout
      end
    end
  end
  object ActionManager: TActionManager
    ActionBars = <
      item
        Items = <
          item
            Items = <
              item
                Action = PeriodInsert
                Caption = '&Insert'
        ImageIndex = 41
              end>
            Action = PeriodAdd
            Caption = '&Add'
            ImageIndex = 1
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Action = PeriodDelete
            Caption = '&Delete'
            ImageIndex = 29
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = LayerInsert
                Caption = '&Insert'
                ImageIndex = 2
                ShortCut = 45
              end>
            Action = LayerAdd
            Caption = '&Add'
            ImageIndex = 0
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Caption = '-'
          end
          item
            Action = LayerDelete
            Caption = '&Delete'
            ImageIndex = 14
            ShortCut = 16430
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
      end
      item
        Items = <
          item
            ChangesAllowed = [caModify]
            Items = <
              item
                Action = FileNew
                Caption = '&New project'
              end
              item
                Action = FileOpen
                Caption = '&Open project ...'
                ShortCut = 114
              end
              item
                Action = FileSave
                Caption = '&Save project'
                ShortCut = 16467
              end
              item
                Action = FilePrint
                Caption = '&Print'
              end
              item
                Action = FileClose
                Caption = '&Exit'
              end>
            Caption = '&ActionClientItem0'
            KeyTip = 'F'
          end>
        AutoSize = False
      end
      item
        Items = <
          item
            Action = LayerCut
            Caption = 'C&ut'
            ImageIndex = 8
            ShortCut = 24664
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Items = <
              item
                Action = LayerPasteBefore
                Caption = '&Paste before'
              end
              item
                Action = LayerPasteAfter
                Caption = 'P&aster after'
              end
              item
                Action = LayerPaste
                Caption = 'Pa&ste'
                ImageIndex = 10
                ShortCut = 24662
              end>
            Action = LayerPaste
            Caption = '&Paste'
            ImageIndex = 10
            ShortCut = 24662
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end>
      end
      item
        Items = <
          item
            Action = CalcRun
            Caption = '&Run'
            ImageIndex = 14
            ShortCut = 116
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Caption = '&ActionClientItem0'
            CommandStyle = csControl
            CommandProperties.Width = 125
          end>
      end
      item
        Items = <
          item
            Caption = '&CheckBox1'
            CommandStyle = csControl
            CommandProperties.Width = 125
          end>
      end
      item
        Items = <
          item
            Caption = '&Edit1'
            CommandStyle = csControl
            CommandProperties.Width = 125
          end>
      end
      item
        Items = <
          item
            Action = ModelCreate
            Caption = '&New'
            ImageIndex = 47
          end
          item
            Action = actItemProperites
            Caption = '&Properies'
            ImageIndex = 36
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = DataPaste
                Caption = '&From clipboard'
              end>
            Action = DataLoad
            Caption = '&Load'
            ImageIndex = 1
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end>
      end
      item
        Items = <
          item
            Caption = '&Label6'
            CommandStyle = csComboBox
            CommandProperties.Width = 0
          end>
      end
      item
      end
      item
        Items = <
          item
            Items = <
              item
                Action = ResultCopy
                Caption = '&Copy to clipboard'
                ImageIndex = 33
              end>
            Action = ResultSave
            ImageIndex = 2
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end>
      end
      item
        Items = <
          item
            Caption = '&ActionClientItem0'
            CommandStyle = csControl
            CommandProperties.Width = 125
          end>
      end
      item
        Items = <
          item
            Caption = '&ActionClientItem0'
          end>
      end
      item
        Items = <
          item
            ChangesAllowed = [caModify]
            Items = <
              item
                Action = FileNew
                Caption = '&New project'
              end
              item
                Action = FileOpen
                Caption = '&Open project ...'
                ShortCut = 114
              end
              item
                Items = <
                  item
                    Action = FileSave
                    Caption = '&Save project'
                    CommandStyle = csMenu
                    ImageIndex = 16
                    ShortCut = 16467
                    CommandProperties.Width = 0
                    CommandProperties.Content.Strings = (
                      'Save project with the same file name')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -6
                    CommandProperties.Font.Name = 'Tahoma'
                    CommandProperties.Font.Style = []
                    CommandProperties.Height = 0
                    CommandProperties.ShowRichContent = True
                  end
                  item
                    Action = FileSaveAs
                    Caption = 'S&ave project As ...'
                    CommandStyle = csMenu
                    ImageIndex = 11
                    ShortCut = 113
                    CommandProperties.Width = 0
                    CommandProperties.Content.Strings = (
                      'Select file name and location')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -6
                    CommandProperties.Font.Name = 'Tahoma'
                    CommandProperties.Font.Style = []
                    CommandProperties.Height = 0
                    CommandProperties.ShowRichContent = True
                  end>
                Action = FileSave
                Caption = '&Save project'
                ShortCut = 16467
              end
              item
                Caption = '-'
              end
              item
                ContextItems.SmallIcons = False
                ContextItems = <>
                Items = <
                  item
                    Action = FilePlotToFile
                    CommandStyle = csMenu
                    ImageIndex = 14
                    CommandProperties.Width = 0
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -6
                    CommandProperties.Font.Name = 'Tahoma'
                    CommandProperties.Font.Style = []
                    CommandProperties.Height = 0
                  end
                  item
                    Action = FileCopyPlotBMP
                    Caption = '&Copy as BMP'
                    CommandStyle = csMenu
                    ImageIndex = 13
                    CommandProperties.Width = 0
                    CommandProperties.Content.Strings = (
                      'Copy plot to clipboard as bitmap')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -6
                    CommandProperties.Font.Name = 'Tahoma'
                    CommandProperties.Font.Style = []
                    CommandProperties.Height = 0
                    CommandProperties.ShowRichContent = True
                  end
                  item
                    Action = FilePlotCopyWMF
                    Caption = 'C&opy as WMF'
                    CommandStyle = csMenu
                    ImageIndex = 13
                    CommandProperties.Width = 0
                    CommandProperties.Content.Strings = (
                      'Copy plot to clipboard as Windows metafile')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -6
                    CommandProperties.Font.Name = 'Tahoma'
                    CommandProperties.Font.Style = []
                    CommandProperties.Height = 0
                    CommandProperties.ShowRichContent = True
                  end>
                Caption = 'E&xport plot'
                ImageIndex = 15
              end
              item
                Action = FilePrint
                Caption = '&Print'
              end
              item
                Caption = '-'
              end
              item
                Action = FileClose
                Caption = '&Exit'
              end>
            Caption = '&ActionClientItem0'
            KeyTip = 'F'
          end>
        AutoSize = False
      end
      item
        Items = <
          item
            Action = ModelCreate
            Caption = '&New'
            ImageIndex = 47
          end>
      end
      item
        Items = <
          item
            Caption = '-'
          end>
      end
      item
        Items = <
          item
            Action = PeriodAdd
            Caption = '&Add'
            ImageIndex = 1
          end
          item
            Action = PeriodInsert
            Caption = '&Insert'
            ImageIndex = 13
          end
          item
            Action = PeriodDelete
            Caption = '&Delete'
            ImageIndex = 29
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = LayerInsert
                Caption = '&Insert'
                ImageIndex = 2
                ShortCut = 45
              end>
            Action = LayerAdd
            Caption = '&Add'
            ImageIndex = 0
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Caption = '-'
          end
          item
            Items = <
              item
                Action = LayerPasteBefore
                Caption = '&Paste before'
              end
              item
                Action = LayerPasteAfter
                Caption = 'P&aster after'
              end>
            Action = LayerPaste
            Caption = '&Paste'
            ImageIndex = 10
            ShortCut = 24662
            CommandProperties.ButtonType = btSplit
          end
          item
            Items = <
              item
                Action = LayerCut
                Caption = '&Cut'
                ImageIndex = 8
                ShortCut = 24664
              end>
            Action = LayerDelete
            Caption = '&Delete'
            ImageIndex = 14
            ShortCut = 16430
            CommandProperties.ButtonType = btSplit
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = CalcAll
                Caption = '&Compute All'
                ShortCut = 117
              end>
            Action = CalcRun
            Caption = '&Run'
            ImageIndex = 9
            ShortCut = 116
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btDropDown
          end
          item
            Caption = '-'
          end
          item
            Action = CalcStop
            Caption = '&Stop'
            ImageIndex = 4
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Color = 16776176
            Caption = '-'
          end
          item
            Action = actAutoFitting
            Caption = '&Auto Fitting'
            ImageIndex = 50
            ShortCut = 118
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Action = ResultSave
            ImageIndex = 2
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = ResultCopy
                Caption = '&Copy to clipboard'
                ImageIndex = 33
              end>
            Action = ResultSave
            Caption = '&Export'
            ImageIndex = 35
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end>
      end
      item
        Items = <
          item
            Caption = '&ActionClientItem0'
            CommandStyle = csControl
            CommandProperties.Width = 75
          end>
      end
      item
        Items = <
          item
            Action = ProjectAddFolder
            Caption = '&New Folder'
          end>
      end
      item
        Items = <
          item
            Caption = '&RibbonSpinEdit1'
          end>
      end
      item
        Items = <
          item
            Action = ModelCreate
            Caption = 'N&ew Model'
            ImageIndex = 47
          end
          item
            Action = ProjectAddFolder
            Caption = '&New Folder'
            ImageIndex = 23
          end
          item
            Action = ProjectItemExtension
            Caption = 'Ne&w extension'
            ImageIndex = 0
          end
          item
            Caption = '-'
          end
          item
            Action = ProjectItemCopy
            Caption = '&Copy as text'
            ImageIndex = 11
          end
          item
            Action = actItemProperites
            Caption = '&Properies'
            ImageIndex = 36
          end
          item
            Action = ProjectItemDelete
            Caption = '&Delete Item'
            ImageIndex = 48
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = DataPaste
                Caption = '&From clipboard'
                ImageIndex = 10
              end>
            Action = DataLoad
            Caption = '&Load'
            ImageIndex = 23
            KeyTip = #1087#1086#1088#1087#1087#1086#1088#1087#1086#1087#1086#1088#1086
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Caption = '-'
          end
          item
            Action = DataNormAuto
            Caption = '&Auto merge'
          end
          item
            Action = DataNormMan
            Caption = '&Manual merge'
          end
          item
            Action = DataNorm
            Caption = '&Normalize'
          end>
      end
      item
        AutoSize = False
      end
      item
        Items = <
          item
            Action = FileNew
            Caption = '&New'
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Caption = '-'
          end
          item
            Tag = 888
            Action = FileOpen
            Caption = '&Open'
            ShortCut = 114
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Caption = '-'
          end
          item
            Action = FileSave
            Caption = '&Save'
            ShortCut = 16467
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Caption = '-'
          end
          item
            Action = FileSaveAs
            Caption = 'S&ave as'
            ShortCut = 113
          end
          item
            Items = <
              item
                Action = FileCopyPlotBMP
                Caption = '&Copy as BMP'
              end
              item
                Action = FilePlotCopyWMF
                Caption = 'C&opy as WMF'
              end
              item
                Caption = '&ActionClientItem2'
              end>
            Action = FilePrint
            Caption = '&Print'
            ImageIndex = 4
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = FileCopyPlotBMP
                Caption = '&Copy as BMP'
              end
              item
                Action = FilePlotCopyWMF
                Caption = 'C&opy as WMF'
              end>
            Action = FilePlotToFile
            Caption = '&Save'
            ImageIndex = 15
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end>
      end
      item
        Items = <
          item
            Action = HelpRegistration
            Caption = '&Input Serial'#13#10'Number'
            ImageIndex = 18
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Action = HelpContent
            Caption = '&Manual'
            ImageIndex = 26
            ShortCut = 112
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Action = HelpAbout
            Caption = '&About'
            ImageIndex = 25
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Action = actHomePage
            Caption = '&Home'#13#10'Page'
            ImageIndex = 19
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Action = actWiki
            Caption = '&Wiki'
            ImageIndex = 20
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Action = actSupport
            Caption = '&Support'
            ImageIndex = 22
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Action = actQuickStart
            Caption = '&Getting started'
            ImageIndex = 23
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Caption = '-'
          end
          item
            Action = actHelpStructure
            Caption = '&Multilayer'#13#10'Structure'
            ImageIndex = 24
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Action = actHelpFitting
            Caption = '&Fitting'
            ImageIndex = 24
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
        Items = <
          item
            Caption = '-'
          end
          item
            Action = CalcStop
            Caption = 'S&top'
            ImageIndex = 4
            CommandProperties.ButtonSize = bsLarge
          end>
      end
      item
      end
      item
        Items = <
          item
            Action = actNewMaterial
            Caption = '&Library'
            ImageIndex = 19
            CommandProperties.ButtonSize = bsLarge
          end>
      end>
    Left = 376
    Top = 316
    StyleName = 'Platform Default'
    object FileNew: TAction
      Category = 'Project'
      Caption = 'New project'
      Hint = 'New project'
      OnExecute = FileNewExecute
    end
    object FileOpen: TAction
      Category = 'Project'
      Caption = 'Open project ...'
      Hint = 'Open project'
      ShortCut = 114
      OnExecute = FileOpenExecute
    end
    object FileSave: TAction
      Category = 'Project'
      Caption = 'Save project'
      Hint = 'Save project'
      ShortCut = 16467
      OnExecute = FileSaveExecute
    end
    object FilePrint: TAction
      Category = 'Project'
      Caption = 'Print'
      Hint = 'Print'
      OnExecute = FilePrintExecute
    end
    object FileClose: TAction
      Category = 'Project'
      Caption = 'Exit'
    end
    object LayerAdd: TAction
      Category = 'Layer'
      Caption = 'Add'
      ImageIndex = 0
      OnExecute = LayerAddExecute
    end
    object LayerInsert: TAction
      Category = 'Layer'
      Caption = 'Insert'
      ImageIndex = 2
      ShortCut = 45
      OnExecute = LayerInsertExecute
    end
    object LayerDelete: TAction
      Category = 'Layer'
      Caption = 'Delete'
      ImageIndex = 14
      ShortCut = 16430
      OnExecute = LayerDeleteExecute
    end
    object PeriodAdd: TAction
      Category = 'Period'
      Caption = 'Add'
      Hint = 'Add Stack'
      ImageIndex = 1
      OnExecute = PeriodAddExecute
    end
    object PeriodInsert: TAction
      Category = 'Period'
      Caption = 'Insert'
      Hint = 'Insert Stack'
      ImageIndex = 13
      OnExecute = PeriodInsertExecute
    end
    object PeriodDelete: TAction
      Category = 'Period'
      Caption = 'Delete'
      Hint = 'Delete stack'
      ImageIndex = 29
      OnExecute = PeriodDeleteExecute
    end
    object actLayerCopy: TAction
      Category = 'Layer'
      Caption = 'Copy'
      Hint = 'Copy Layer'
      ImageIndex = 6
      ShortCut = 24643
      OnExecute = actLayerCopyExecute
    end
    object LayerCut: TAction
      Category = 'Layer'
      Caption = 'Cut'
      ImageIndex = 8
      ShortCut = 24664
      OnExecute = LayerCutExecute
    end
    object LayerPaste: TAction
      Category = 'Layer'
      Caption = 'Paste'
      Hint = 'Paste & replace'
      ImageIndex = 10
      ShortCut = 24662
      OnExecute = LayerPasteExecute
    end
    object LayerPasteBefore: TAction
      Category = 'Layer'
      Caption = 'Paste before'
    end
    object LayerPasteAfter: TAction
      Category = 'Layer'
      Caption = 'Paster after'
    end
    object CalcRun: TAction
      Category = 'Calc'
      Caption = 'Run'
      Hint = 'Start calculation'
      ImageIndex = 43
      ShortCut = 116
      OnExecute = CalcRunExecute
    end
    object ModelCreate: TAction
      Category = 'Project Item'
      Caption = 'New'
      Hint = 'Add project item'
      ImageIndex = 47
      OnExecute = ModelCreateExecute
    end
    object actItemProperites: TAction
      Category = 'Project Item'
      Caption = 'Properies'
      ImageIndex = 36
      OnExecute = actItemProperitesExecute
    end
    object DataLoad: TAction
      Category = 'Data'
      Caption = 'Load'
      ImageIndex = 23
      OnExecute = DataLoadExecute
    end
    object DataPaste: TAction
      Category = 'Data'
      Caption = 'From clipboard'
      ImageIndex = 10
      OnExecute = DataPasteExecute
    end
    object ResultSave: TAction
      Category = 'Result'
      Caption = 'Export ...'
      ImageIndex = 35
      OnExecute = ResultSaveExecute
    end
    object ResultCopy: TAction
      Category = 'Result'
      Caption = 'Copy to clipboard'
      ImageIndex = 33
      OnExecute = ResultCopyExecute
    end
    object FileSaveAs: TAction
      Category = 'Project'
      Caption = 'Save project As ...'
      ShortCut = 113
      OnExecute = FileSaveAsExecute
    end
    object ProjectAddFolder: TAction
      Category = 'Project Item'
      Caption = 'New Folder'
      ImageIndex = 23
      OnExecute = ProjectAddFolderExecute
    end
    object CalcAll: TAction
      Category = 'Calc'
      Caption = 'Calc all models'
      ShortCut = 117
      OnExecute = CalcAllExecute
    end
    object ProjectItemDelete: TAction
      Category = 'Project Item'
      Caption = 'Delete Item'
      ImageIndex = 48
      OnExecute = ProjectItemDeleteExecute
    end
    object ProjectItemCopy: TAction
      Category = 'Project Item'
      Caption = 'Copy as text'
      ImageIndex = 11
      OnExecute = ProjectItemCopyExecute
    end
    object CalcStop: TAction
      Category = 'Calc'
      Caption = 'Stop'
      ImageIndex = 46
      OnExecute = CalcStopExecute
    end
    object DataNormAuto: TAction
      Category = 'Data'
      Caption = 'Auto'
      OnExecute = DataNormAutoExecute
    end
    object DataNormMan: TAction
      Category = 'Data'
      Caption = 'Manual'
    end
    object DataNorm: TAction
      Category = 'Data'
      Caption = 'Normalize'
      OnExecute = DataNormExecute
    end
    object FilePlotToFile: TAction
      Category = 'Plot'
      Caption = 'Save as graphics ...'
      OnExecute = FilePlotToFileExecute
    end
    object FileCopyPlotBMP: TAction
      Category = 'Plot'
      Caption = 'Copy as BMP'
      OnExecute = FileCopyPlotBMPExecute
    end
    object FilePlotCopyWMF: TAction
      Category = 'Plot'
      Caption = 'Copy as WMF'
      OnExecute = FilePlotCopyWMFExecute
    end
    object HelpHelp: TAction
      Category = 'Help'
      Caption = 'Help'
      ImageIndex = 18
    end
    object HelpRegistration: TAction
      Category = 'Help'
      Caption = 'Registration'
      ImageIndex = 22
    end
    object HelpAbout: TAction
      Category = 'Help'
      Caption = 'About ...'
      ImageIndex = 21
      OnExecute = HelpAboutExecute
    end
    object HelpContent: TAction
      Category = 'Help'
      Caption = 'User Manual'
      ImageIndex = 19
      ShortCut = 112
      OnExecute = HelpContentExecute
    end
    object actHomePage: TAction
      Category = 'Help'
      Caption = 'Home'#13#10'Page'
    end
    object actCheckUpdate: TAction
      Category = 'Help'
      Caption = 'Check for'#13#10'Update'
    end
    object actWiki: TAction
      Category = 'Help'
      Caption = 'Wiki'
    end
    object actSupport: TAction
      Category = 'Help'
      Caption = 'Support'
    end
    object actQuickStart: TAction
      Category = 'Help'
      Caption = 'Getting Started'
    end
    object actHelpStructure: TAction
      Category = 'Help'
      Caption = 'Multilayer'#13#10'Structure'
    end
    object actHelpFitting: TAction
      Category = 'Help'
      Caption = 'Fitting'
    end
    object ProjectItemExtension: TAction
      Category = 'Project Item'
      Caption = 'New extension'
      ImageIndex = 0
      OnExecute = ProjectItemExtensionExecute
    end
    object DataCopyClpbrd: TAction
      Category = 'Data'
      Caption = 'DataCopyClpbrd'
      OnExecute = DataCopyClpbrdExecute
    end
    object DataExport: TAction
      Category = 'Data'
      Caption = 'DataExport'
      OnExecute = DataExportExecute
    end
    object actNewMaterial: TAction
      Category = 'Materials'
      Caption = 'New material'
      OnExecute = actNewMaterialExecute
    end
    object actAutoFitting: TAction
      Category = 'Calc'
      Caption = 'Auto Fitting'
      ImageIndex = 50
      ShortCut = 118
      OnExecute = actAutoFittingExecute
    end
    object actProjectItemDuplicate: TAction
      Category = 'Project Item'
      Caption = 'Duplicate Model'
      Hint = 'Duplicate model'
      ImageIndex = 57
      OnExecute = actProjectItemDuplicateExecute
    end
    object actModelCopy: TAction
      Category = 'Project Item'
      Caption = 'Copy model'
      OnExecute = actModelCopyExecute
    end
    object actModelPaste: TAction
      Category = 'Project Item'
      Caption = 'Paste Model'
      OnExecute = actModelPasteExecute
    end
    object actEditHenke: TAction
      Category = 'Materials'
      Caption = 'Edit Henke table...'
      OnExecute = actEditHenkeExecute
    end
    object actProjecEditModelText: TAction
      Category = 'Project Item'
      Caption = 'Edit as text ...'
      OnExecute = actProjecEditModelTextExecute
    end
    object actImportStructure: TAction
      Category = 'Project Item'
      Caption = 'Import structure ...'
      OnExecute = actImportStructureExecute
    end
    object actDataSmooth: TAction
      Category = 'Data'
      Caption = 'Smooth'
      Hint = 'Smooth data curve'
      OnExecute = actDataSmoothExecute
    end
    object acStructureUndo: TAction
      Category = 'Layer'
      Caption = 'Undo'
      ShortCut = 16474
      OnExecute = acStructureUndoExecute
    end
    object actProjectReopen: TAction
      Category = 'Project'
      Caption = 'Reopen'
      Hint = 'Reopen project'
      ShortCut = 114
      OnExecute = actProjectReopenExecute
    end
    object actCalcBenchmark: TAction
      Category = 'Calc'
      Caption = 'Benchmark'
      OnExecute = actCalcBenchmarkExecute
    end
    object actSystemSettings: TAction
      Category = 'System'
      Caption = 'Settings ...'
      OnExecute = actSystemSettingsExecute
    end
    object actSystemExit: TAction
      Category = 'System'
      Caption = 'Exit'
      OnExecute = actSystemExitExecute
    end
    object actCopyStructureBitmap: TAction
      Category = 'Project Item'
      Caption = 'Copy as image'
      OnExecute = actCopyStructureBitmapExecute
    end
    object actDataTrim: TAction
      Category = 'Data'
      Caption = 'Trim'
      OnExecute = actDataTrimExecute
    end
    object actCalcFitJobs: TAction
      Category = 'Calc'
      Caption = 'Batch jobs Fitting'
      OnExecute = actCalcFitJobsExecute
    end
    object FitExportJSON: TAction
      Category = 'Result'
      Caption = 'Export fit results...'
      OnExecute = FitExportJSONExecute
    end
  end
  object dlgSaveFitJSON: TSaveDialog
    DefaultExt = 'json'
    Filter = 'JSON files (*.json)|*.json'
    Title = 'Export Fit Results'
    Left = 504
    Top = 216
  end
  object ilCalc: TImageList
    ColorDepth = cd32Bit
    Left = 444
    Top = 216
    Bitmap = {
      494C01010A004800040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000003000000001002000000000000030
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000202021838533AA2129F
      1FFF139F1FFF38533AA202020218000000000000000000000000000000000000
      0000686868FF686868FF676767FF676767FF666666FF656565FF656565FF6464
      64FF636363FF636363FF636363FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000009020202191616164C558958D683EE
      A8FF84F0ACFF558A59D61616164C0202021800000000246595FF246595FF2465
      95FF787878FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFEEEEEEFFF6F6F6FF727272FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000505052638563AA7189322F60C9517FC64E0
      90FF64E493FF0C9518FC189322F638533AA200000000246595FF4C9DC1FF4E9F
      C4FF868686FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF818181FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000C7C93FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF228AA1FF119E1CFF81DF9CFF62D486FF1FC0
      58FF22C960FF65E494FF84F2ADFF139F20FF00000000246595FF4EA0C5FF50A3
      C6FF919191FFF2F2F2FF98A9CBFFE6E6E6FFE6E6E6FFE6E6E6FFE6E6E6FFE5E5
      E5FFE2E2E2FFF0F0F0FF8C8C8CFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000007788FFFA3E6FFFF50D0FFFF40CA
      FFFF41CAFFFF40CAFFFF44CBFFFF8EE2FFFF139E1BFF84DD99FF62D283FF1FB7
      51FF1FC259FF64E190FF84EEA9FF129F1FFF00000000296B99FF51A4C7FF52A7
      C9FF999999FFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF979797FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF49A6BCFF53D1FFFF14BC
      FBFF13BBFBFF13BBFBFF16BBFBFF43CBFFFF46BA95FF159D27FF099818FF62D1
      83FF62D587FF0C9518FB189322F638533AA2000000002F729FFF53A9CAFF54AB
      CCFFA0A0A0FFF6F6F6FF98A9CBFFEEEEEEFFEEEEEEFFEEEEEEFFEDEDEDFFEBEB
      EBFFEAEAEAFFF3F3F3FF9E9E9EFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF229DBFFF89DCF8FF2CC7
      FEFF1BC1FDFF1DC1FDFF1EC1FDFF24C5FDFF37CBFFFF70DCFFFF58BC7CFF83DD
      99FF83E29DFF4D9F62F11414144902020218000000003477A4FF55ACCCFF56AF
      CFFFA6A6A6FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFA4A4A4FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF35C9FFFF4FA8B9FF5ED9
      FFFF24C7FDFF24C7FDFF24C8FDFF24C7FDFF20C6FDFF3DD0FFFF4ABE95FF139E
      1BFF129E1CFF4BAE7BFF1113154D00000000000000003C83ADFF57B0D0FF59B2
      D3FFA9A9A9FFF8F8F8FF98A9CBFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF2F2
      F2FFEFEFEFFFF6F6F6FFA7A7A7FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF40D1FFFF0D94BCFF90E3
      FBFF38D1FDFF2ACDFCFF2CCEFCFF2CCEFCFF2BCDFCFF33CFFCFF56D9FFFF7EE2
      FFFF82E3FFFFA4EFFFFF0F4E5CC70000000000000000428AB2FF59B4D4FF5BB6
      D7FFACACACFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFABABABFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF44D1FFFF19C3FBFF57AB
      BDFF68DFFFFF36D3FEFF35D2FEFF35D2FEFF35D2FEFF36D2FEFF37D2FEFF38D3
      FEFF37D2FEFF57DCFFFF71C4DCFF02060634000000004791B8FF5BB7D7FF5DBA
      D9FFADADADFFFBFBFBFF98A9CBFFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6
      F6FFF3F3F3FFF8F8F8FFADADADFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF46D4FFFF25CDFFFF1299
      BAFFA6E6FAFF8AE4FEFF87E4FDFF88E4FDFF88E4FDFF88E4FDFF86E4FDFF85E5
      FFFF86E6FFFF8BE5FFFFBFF7FFFF0D4854C2000000004F9AC0FF5EBBD9FF5FBD
      DCFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFB6B6
      B6FFB4B4B4FFBFBFBFFFADADADFF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF4BD6FFFF29CDFDFF2ACA
      F9FF09829BFF087A91FF087A91FF087A91FF087A91FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF096171E000000000509DC1FF61BFDDFF62C1
      DEFFAFAFAFFFFCFCFCFF98A9CBFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFBCBC
      BCFFE9E9E9FFBABABAFF4343439F000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000087A91FF4ED8FFFF2CCEFEFF2FCF
      FEFF30D2FFFF2FD1FFFF33D3FFFF4BD9FFFF52DDFFFF52DDFFFF6AE4FFFF67BF
      D3FF0000000900000000000000000000000000000000519EC2FF63C2E0FF898C
      8EFF787C7DFF717475FF696C6DFF696C6DFF626566FF626566FF626566FFE2E2
      E2FFBBBBBBFF4343439F00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000017859AFF75E4FFFF35D1FEFF31D0
      FEFF2FD0FEFF36D1FEFF70E2FFFF1C8AA0FF087A91FF087A91FF087A91FF107E
      94FF0000000800000000000000000000000000000000529FC2FF65C6E2FF66A7
      BAFF696B6BFF717374FF878C8EFF8F9899FF757878FF696A6BFF959595FFAFAF
      AFFF799EAFFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000010E11572D94A9FF7DE7FFFF53DC
      FFFF52DCFFFF79E7FFFF2B94A9FF00090A440000000000000000000000000000
      0000000000000000000000000000000000000000000053A0C4FF67CAE6FF69CC
      E7FF6E6F6FFFADB2B4FFA3A9AAFFB8C2C4FFB0B5B6FF676868FF74E1F7FF76E3
      F8FF368BB5FF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001060836138297FF087A
      91FF087A91FF158398FF00080A41000000000000000000000000000000000000
      0000000000000000000000000000000000000000000054A3C5FF54A3C5FF55A4
      C6FF517587FF577D8EFF697880FF6B7C83FF507586FF527888FF57A9CBFF4AA0
      C5FF4096BCFF0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000060000
      00230000002100000020000000200000002000000020000000200000001F0000
      00240000001D0000000000000000000000000000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A0504032900000006000000060000000300000000000000000000001FB0B0
      B0F1CCCCCCF9C3C3C3F8C3C3C3F8C7C7C7F8C1C1C1F8C5C5C5F8C4C4C4F8DCDC
      DCFB404040B100000000000000000000000000000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB09090969383838B23B3B3BB6BCBC
      BCF6FCFCFCFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF4F4F4FFF5F5F5FFF7F7
      F7FF727272DA393939B23E3E3EB802020238000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000D0705044E2219197D0000
      0C6D2117308E30223D9A04001069572D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5606060C3E7E7E7FFE4E4E4FF4848
      48FF3D3D3DFF414141FF414141FF404040FF404040FF3F3F3FFF424242FF2C2C
      2CFF777777FFF5F5F5FFF2F2F2FF151515800D0707493C2424911D16165C2721
      2165645454A019141554231C1A67554444A81D0E6ED5311E58C64E3771D6271F
      2D8F2C241F70574749951711115675403ED00D0707493C2424911D16165C2721
      2165645454A019151555221C1966564644A8231275D734215FC8503873D72E24
      339230272272594A4C971812125774403ED00D0707493C2424911D16165C2721
      2165645454A019151555221C1966574645A8221274D534215EC6513875D52920
      2E8C2E25216F564B4D9418121255743F3ED0585858BBE0E0E0FFE3E3E3FFA2A2
      A1FF7A7D81FF818489FF818487FF818487FF828589FF82868AFF80878BFF7E82
      84FFC3C3C2FFE2E2E2FFEAEAEAFF131313771B111161412828950504042B0A08
      083D483939880303022B1A151C7E432C6CDA09031E9C140830B941267DEF0503
      03571D161682251E1F8A05030343613435CE1B111161412828950504042B0A08
      083D483939880303022C1A151D7E4E3578D70C061C891A0E37A85735A1EF0201
      012C1C16165E2C25246B030303246B3738C91B111161412828950504042B0A08
      083D483939880303022C1A151D7F4E3477D5100A1F881E1238A6543494F00605
      054E1E1817672720206F020202246D3A3AC95C5C5CBBEEEEEEFFEBEBEBFFFAFC
      FCFFFFFAF2FFFAF0E3FFFBF3E9FFFBF3E8FFFBF1E5FFFBEDE0FFFBE8DBFFFFFB
      F7FFF4F5F6FFE9E9E9FFFAFAFAFF1313137701000019251616720101011B0303
      032B362B287B0101012E13073EB5422558F5322419C6383339CA362A4AEF1E1E
      1EA13A352FB83F2F14C3090700824A2629C701000019251616720101011B0303
      032B362B287B0101012F1D1140AD512DB1F00C090F5E17111970513773C60000
      0009100C0C46231D1D6101000014663434C301000019251616720101011B0303
      032B362B287B0101012F1F1243AB432787EC00000EBA0A0812BB271B32F70000
      00AC0F0C0CA3131010B30000005D5C3232C1616161BDFEFEFEFFFEFFFFFFFEFC
      FBFFDA9B64FFC98846FFCB965DFFCB965CFFCB8F51FFCB7E40FFC85D1BFFE7A6
      86FFFFFFFFFFFEFEFFFFFFFFFFFF1414147A26161673513333A7211818653127
      29805C455FC4382A3DA32D1E3DB4B68F33F2FFD67EFFE0DBD2FF7D7C76FFFCF7
      F7FFFCECDAFFF6C467FF916D34EB4D272ED426161673513333A7211818653127
      29805C455FC438293DA73D2C4BB2604D479F1B1616543028276F473B3887211A
      1C6656434AA25044438F1F17175D794242D726161673513333A7211818653127
      29805C455FC438293DA73B2A46A67B6856CE80765CF6898988F7807F7BF18986
      86F4929090FC7D7E7EFF231C1CB96E3C3CCD636363BFFFFFFFFFFFFFFFFFFFF6
      F2FFDA9260FFCB8B50FFD49558FFD79B60FFD59155FFD37E44FFD5662CFFE89F
      7CFFFFFFFFFFFFFFFFFFFFFFFFFF0D0D0D6E020101212113136C000000050704
      106D483268C50000219304030458AC873EEBFAC978FFEDE4DAFFC3BEBDFFEEEA
      EAFFF3E3CBFFF8C46CFF604920C92E1418B6020101212113136C000000050704
      106D483268C5000020980806095619151352000000000C09116B292232940000
      208A1A2473D1120F0F51000000005E2E2FBB020101212113136C000000050704
      106D483268C500002098050405425B4C46AE8C724ADE928673E3929397E87D7F
      80D9929396E4939393F304040461452323AA0D0D0D67DBDBDBF8FFFFFFFFFFF5
      EFFFDFA184FFD8A78DFFE3AE8BFFE1AB85FFE1A681FFE3A17DFFE69A76FFEBB1
      96FFFFFFFFFFFFFFFFFFCBCBCBF400000017130B0B543E28238F382442A64535
      46A66E536EC83C2471C5382B3299B79049F4ECB65AFFF1CE95FFFCE0B2FFF3D8
      ABFFEBC585FFEEB85BFF836536E150292DD6130B0B543E28238F382442A64535
      46A66E536EC8392370C844353D985F514C9C251D1E6C4D4C7FE66F7FDFF6203B
      C1E01D48D1EC31386BCF261D1D6D7D4443D4130B0B543E28238F382442A64535
      46A66E536EC8392370C83D2F368C87736DD19A805BEDA27E51EF9D9281F28C8A
      89E99F917FEF8D9095F82B2121A7733F3ECE00000000040404332C2D2E8CDED3
      CDFDF1C0ABFFF7CDBBFFF4CCBBFFF5CDBCFFF4CBB9FFF3C6B3FFF0BFAAFFEDC4
      B0FF96989ADD1414146A0202022A00000000110B0B4E291A16790A05116F100B
      1571392E2E7C080412670201012CC0954CF8F3D294FFEDE9DBFFEBE4D1FFEAE3
      D2FFF1EBDAFFF6CD83FF664E22CF36191DBF110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B030302292E29286D000001193B3D65C87787C3DF0A19
      8FBF1328ABD11038C7EA0B0A1971593028AB110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B01000017786666C08D7D61E3987852E79A7950EB8472
      57DD9D7D53E78E8370F40A080876502A2AB4000000000000000000000011BCBD
      BDF7F7F2EFFFF9EDE7FFF7ECE7FFF2EAE7FFECE4E1FFE5DDD9FFDFD8D5FFE4E2
      E1FF4A4A4AA90000000000000000000000000201012025161578160C2B981813
      166B463836860403032C0D0A0950B78E4AF9D7BE93FFC7C8CCFFCDCAC6FFCBC8
      C5FFD9D8D9FFDDBC84FF705629D6401E23C80201012025161578160C2B981813
      166B463836860504042F100D0D4C3E36357E060506383D4070D96370CEED0101
      95CA0C0EBBDB1E2388DE0F0B0E57673833BD0201012025161578160C2B981813
      166B463836860504042F0A08083C7E6A69C7958C85E7A4948AEAA08978EE8B75
      60E29F8771EB96836EF6120E0F895B3031BD000000000000000002020224CBCB
      CCF8FFFFFFFFFFFFFFFFFFFFFFFFFAFDFEFFF2F5F7FFECEFF1FFE5E8EAFFE7E9
      EAFF535353AF0000000000000000000000002214146C4C2F30A52F1C52B81C17
      15646250519E1513134B251D1D6CBE9953FFEED6ADFFDDDBD8FFE5DFD5FFE8E2
      D8FFE4E2DDFFECCF9AFF876A3AE14C252ACA2214146C4C2F30A52F1C52B81C17
      15646250519E1713134D2C25256B5C4B4A991512114D28222B8B3F3850BB191A
      5ACD181495EF3D33368A110D0C45774040D42214146C4C2F30A52F1C52B81C17
      15646250519E1713134D211D1D5D8A6968D5AE9794F6BFABA2F6BCA391F7A986
      5BF2B58C49F5AD8B3DFF211A189F683A3CC7000000000000000002020227DFDF
      DFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFDFDFFF6F6F6FFEFEFEFFFE9E9E9FFE9E9
      E9FF535353B00000000000000000000000002517156E41252DA0060014750000
      000F2F242471000000000101011D775A36DE6A5633C8806B4BD6947D58E36252
      35C385714EDA977C4FE422180A91441F22B62517156E41252DA0060014750000
      000F2F242471000000000201011E291F1F6B0000000004030326221B195F0A09
      0A48221A238C120E0D4900000000652E2EC62517156E41252DA0060014750000
      000F2F242471000000000000000E5C4241AF412C29AA5D443EBC75584CCE412E
      21A1684E36C1735739D40201013654292AB800000000000000000000000A2626
      268DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8F8F8FFF2F2F2FFEDED
      EDFF535353B000000000000000000000000004030228371F2696200F12782112
      126E3821218D1C0E0E6825151576301C1D8A13090964201110782C1818871208
      08612312127C29171784150A0B65442121A604030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A341E1E88140A
      0A5927171575311D1D851A0D0D67412020A504030228371F2696200F12782112
      126E3821218D1C0E0E6826141477331F1F87140A0A59211212702E1B1B811309
      0A58251516762B191A7C180C0C61432020A60000000000000000000000000303
      032ECECECEF1D4D4D4F1D2D2D2F0D2D2D2F0D2D2D2F0D0D0D0F0CBCBCBEFDDDD
      DDF8555555B00000000000000000000000000000000000000000000000100100
      001600000008010000190000001300000004000000100000000A000000050000
      0011000000080000000600000012000000000000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0100
      00190000000E0000000C01000019000000000000000000000000000000100100
      001600000008010000190000001300000008010000160000000E000000080100
      00170000000C0000000A01000018000000000000000000000000000000000000
      001211111159101010570F0F0F550F0F0F550F0F0F550F0F0F550E0E0E521C1C
      1C781818186F0000000000000000000000000000000000000000000000020000
      0008000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000EEDDCD00EEDDCD00EEDDCD00EEDD
      CD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDD
      CD00EEDDCD00EEDDCD00EEDDCD00EEDDCD000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000003002600A60009
      0094000000420000000800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000EDDCCC00EDDDCC00EFDFCF00EDDD
      CD00F1E1D000F2E3D200F1E1D000F1E1D000F1E0D000F1E1D000F1E1D000F2E3
      D200F0E0D000EEDDCD00EDDDCD00EDDDCD000000000000000000000000000000
      0000040403523A3A33B1585652D4545250D553514DD53C3B34BC0808076B0000
      001B000000000000000000000000000000000000000000000000008100E30098
      00FF003C00D80000007000000021000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000EDDCCC00ECDCCC00E2D0C100EDDD
      CD00DBC8B900CDB8AB00D5C1B600D6C3B600D5C1B300D5C2B500D4C1B500CDB8
      AB00D7C3B500E8D8C800ECDCCC00ECDCCC000000000000000000000000174544
      3CB9B8B5C3FF8683D2FF8684DDFF9896E3FF8987DBFF7B77C8FF9A95A5FF4E4D
      42CC000000410000000000000000000000000000000000000000007500D700B7
      00FF00AE00FF007200F4001E00BC0000005D0000000D00000000000000000000
      0000000000000000000000000000000000000000000099330000993300000000
      0000000000000000000000000000000000009933000099330000000000000000
      000000000000000000000000000000000000ECDBCB00F0E0D000D4C0B100C9B1
      A300C7B0A100BDA69A00B5A09500AE989400C3B2B200AD969100B6A09600C3AC
      A000E5D1C100EEDCCB00F0E0CF00ECDBCB000000000000000012858579DAA6A3
      DEFF3837E3FF5B5BF6FF8C8DFAFFA4A5FBFF9393FCFF6465FAFF3C3BE6FF7E7A
      C2FF7F7B6BEA0000004000000000000000000000000000000000007700D800B7
      00FF00B600FF00B600FF00AA00FF005100E6000500900000002C000000000000
      0000000000000000000000000000000000000000000099330000CC6600009933
      00000000000000000000000000000000000099330000CC660000993300000000
      000000000000000000000000000000000000EEDDCD00EBD9C900CEB8AC00C5AF
      A500B59D9500C3ACA200CBB6AA00B29C9800CCBCBC00B59C9700CCB7AB00CCB9
      AE00CDB9AE00CAB5AB00CEB8AB00F1DFCF000000000044443CB2ACAAE4FF1B1A
      DDFF4142F1FF5656EDFF7272F3FF7C7CF3FF7575F3FF5A5AEDFF4848F3FF1D1E
      E7FF8682C3FF555247D20000001A000000000000000000000000007700D800B6
      00FF00B100FF00B400FF00B600FF00B700FF008B00FE001F00BE0000006C0000
      0020000000000000000000000000000000000000000099330000CC660000CC66
      00009933000000000000000000000000000099330000CC660000CC6600009933
      000000000000000000000000000000000000F4E3D100DAC5B600CEBFBF00EDE8
      EB00ECE6E800ECE5E700EFE9EC00DFD6D700A58D8C00E6DEE000EDE8EB00E8E2
      E600EAE3E400F2E8E600CFBFBE00DDC7B60012120F6FC0BEC7FF2020C9FF1D1D
      D0FF5252CDFF7777C0FF4B4BE5FF5353F6FF4C4CE6FF7676BFFF5352CCFF2323
      D5FF1E1ECBFFA9A4B0FF0808066C000000000000000000000000007700D800B6
      00FF00B200FF00B200FF00B200FF00B500FF00B700FF00AA00FF007500F7000D
      00A4000000430000000E00000000000000000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      000099330000000000000000000000000000F5E4D200D7C1B200C5B1AD00DACC
      C500D5C6BF00D5C6BE00D8C8BF00D4C4BB00BAA59D00D2C2BA00D7C8BF00DCCC
      C500CFBDB7009691A200B29E9C00DFC9B8009D9B83E07776C0FF0000B5FF1111
      B8FF6C6CB5FFDBDBB1FF8383BDFF2C2CD9FF8080BEFFDADAB0FF6F6FB5FF1414
      BCFF0000B5FF7370C2FF43423ABF000000000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B200FF00B400FF00B500FF00B000FF009B
      00FF004B00E10008009300000020000000000000000099330000CC660000CC66
      0000CC660000CC660000993300000000000099330000CC660000CC660000CC66
      0000CC660000993300000000000000000000F3E2D200D9C2B400D4B6A000E7C9
      BB00E4C7BA00DFC2B200DEBAA700E1BFAE00EACEC100E1C2B300DFBBAA00F3CF
      A50091858D00656C9300BF9B8200E1CCBE00CFCCB4FF413FB5FF000091FF0A0A
      A4FF1111B2FF7C7BB4FFC3C3B3FFA4A4B4FFC1C1B3FF7B7BB4FF1212B3FF0C0C
      A8FF000092FF3F3DBAFF626058D7000000000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B300FF00B200FF00B300FF00B500FF00B0
      00FF00B300FF004C00DB00000020000000000000000099330000CC660000CC66
      0000CC660000CC660000CC6600009933000099330000CC660000CC660000CC66
      0000CC660000CC6600009933000000000000F2E1D100D9C3B400E1C7AF00EDD4
      C800E0C4BF00F3D9DD00F4D8DB00F5D4D800F2D4D700E4C9C300F2D5C300D5B9
      A3005A699B00B59E9500ECCAA700D7C3B600BFBAABFF5857BEFF2827ACFF0E0E
      A4FF0000A5FF0101A2FFBCBCC7FFECECD1FFBDBDC8FF0302A3FF0000A7FF1010
      A6FF2828ADFF5E5DC6FF605F5BD6000000000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B300FF00B500FF00B600FF00B200FF008A
      00FA002600A50001003200000000000000000000000099330000CC660000CC66
      0000CC660000CC660000993300000000000099330000CC660000CC660000CC66
      0000CC660000993300000000000000000000F3E0D000D9C3B400E0C5AC00F6DE
      C000F4DABC00DDC1B100DFC3C400DFBEBD00D2B19D00D9BDA200DFC3A300B99B
      8800937F8000F9DAB400E4C4A600D7C2B600A4A095FF8C8AC6FF6F6FE4FF2D2D
      C7FF1A1ABAFF9999D8FFFFFFFAFFE4E4EDFFFFFFFBFF9F9FD9FF2020BDFF3333
      C8FF7071E2FFA19FDBFF5F5D5AD7000000000000000000000000007700D800B6
      00FF00B100FF00B300FF00B500FF00B600FF00B100FF008900FA002500A40002
      0036000000000000000000000000000000000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      000099330000000000000000000000000000F2E0D000DAC3B400DEC2AA00E6CB
      B100EFD6BA00FBE3C500ECD4BB00D6B9A000BC9A8000D1B09400D6B59900C19E
      8500DBB89700FFE7C000DEBFA200D7C2B600747067DB8481B1FF8181E3FF3636
      C1FF8F8FD4FFFFFFFFFFA9A9DFFF1A1AB8FFADADE4FFFFFFFFFF9696D6FF3D3D
      C2FF7C7CDEFFB0ADD4FF3E3D3AB4000000000000000000000000007700D800B6
      00FF00B400FF00B600FF00B300FF008C00FB002500A400020035000000000000
      0000000000000000000000000000000000000000000099330000CC660000CC66
      00009933000000000000000000000000000099330000CC660000CC6600009933
      000000000000000000000000000000000000F3E1D100DAC4B500DEC2AA00E7CC
      B200DEC3AB00E9D0B600FBE4C700D6B69B00D2B49400A0967100A1987300C2AD
      8B00D9B69A00EDCDAC00E1C3A500D8C3B700141413648D8896FF8E8ED7FF7474
      DAFF6C6CC7FF9797D4FF3B3CC1FF3B3BCAFF3F3EC3FF9A9AD6FF7272C9FF7575
      D9FF8989D6FFCAC8D0FF03030352000000000000000000000000007400D700B7
      00FF00B200FF008900FA002500A5000200360000000000000000000000000000
      0000000000000000000000000000000000000000000099330000CC6600009933
      00000000000000000000000000000000000099330000CC660000993300000000
      000000000000000000000000000000000000F6E6D800DAC5B800E0C5AD00F3DA
      BE00EFD4BA00F0D7BB00EDD3B800E2C4A700EBCEAE00A89B7E00AEAD8A00C6B5
      9400EFCDAC00E5C3A300E6C6A700D7C5BA00000000003A3937A38E8AACFFA2A2
      E7FF8686DCFF5C5CC8FF6766D1FF6969D0FF6868D0FF5F5FC9FF8787DCFF8C8C
      D7FFB9B7DAFF4B4A46C000000002000000000000000000000000008400E8008F
      00FD002400A30002003500000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099330000993300000000
      0000000000000000000000000000000000009933000099330000000000000000
      000000000000000000000000000000000000F6E6D900E1CCC100CBAF9C00EBD2
      B900EBD2B900EDD3BA00DEC3AC00CDB09A00FFF5DE00D2BCA6009D917B00D2BA
      A300E5C3A400D1AF9500CFB19A00E6D5CA0000000000000000095D5C58CD908B
      A9FFA2A1D9FFA7A7E5FFA1A1E3FF9D9EE1FFA0A1E2FFA4A4E2FF9C9BD4FFB0AD
      CDFF7D7B77DA0000001800000000000000000000000000000005001A007B0003
      0040000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F1E0D300F2E1D500DFCBC000D3BE
      B200D4BFB400D7C1B500D8C3B800C5AB9E00EADACA00E4D3C200CAB49E00F7DF
      C500C7AC9900D1BBB100E1CEC200F5E4D80000000000000000000000000D3736
      359E837E8BF68F8CAEFF918FBAFF9392C1FF9390BCFF9694B5FFA19EA8F83A39
      36AD000000150000000000000000000000000000000000000001000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F1E0D400F1E0D400F9E9DD00FAEB
      DF00F7E8DD00F8E9DD00FDEEE200F2E1D700BDA29500E2CFC000EDD8C300C7AC
      9D00DDCAC100FEF1E600F7E8DB00F0DFD3000000000000000000000000000000
      0000161614676B6861D499948FFFA09A96FFA3A09BFF7B7A73D9121210720000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000300000000100010000000000800100000000000000000000
      000000000000000000000000FFFFFF0000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFF000000000000FFFF00000000
      0000FFFF0000000000009F3F0000000000008F1F000000000000870F00000000
      0000830700000000000081030000000000008001000000000000810300000000
      00008307000000000000870F0000000000008F1F0000000000009F3F00000000
      0000FFFF000000000000FFFF0000000000000000000000000000000000000000
      000000000000}
  end
  object ilIcons: TImageList
    Height = 32
    Width = 32
    Left = 296
    Top = 404
    Bitmap = {
      494C010101000800040020002000FFFFFFFFFF10FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000800000002000000001002000000000000040
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF0D0E9F000D0EA0000D0E9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E
      9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E
      9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E9E000D0E9E000D0EA0000D0E
      9F00000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      A0001315F4001315EA001315EA001315EA001315EA001315EA001315EA001315
      EA001315EA001315EA001315EA001315EA001315EA001315EA001315EA001315
      EA001315EA001315EA001315EA001315EA001315EA001315EA001315EA001315
      F4000D0E9F00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      A1001315EA001314DF001314DF001314DF001314DF001314DF001314DF001314
      DF001314DF001314DF001314DF001314DF001314DF001314DF001314DF001314
      DF001314DF001314DF001314DF001314DF001314DF001314DF001314DE001315
      EA000D0EA000000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9E001315E8001314DD001314DD001314DD001314DD001112DD000B0CDC001314
      DD001314DD001314DD001314DD001314DD001314DD001314DD001314DD001314
      DD001314DD000B0CDB001112DC001314DC001314DC001314DC001314DC001315
      E7000D0E9D00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9E001315E7001314DB001314DB001314DB001112DB00090AD9002021DD000607
      D9001314DB001314DB001314DB001314DB001314DB001314DB001314DB001314
      DB000607D8002021DC00090AD9001112DA001314DB001314DA001314DA001315
      E5000D0E9C00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9D001214E4001213DA001314D9001112D9000000D4007373E800E6E6FA003C3D
      DF000000D5001314D9001213D9001213D9001213D9001213D9001314D9000000
      D4003C3DDF00E6E6FA007273E7000000D4001011D8001213D9001213D8001213
      E3000D0E9C00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9C001213E2001213D8001011D7000809D6007172E800FFFFFF00FFFFFF00F0F0
      FC003A3ADD000000D3001213D7001213D7001213D7001213D7000000D2003A3B
      DD00F0F0FC00FFFFFF00FFFFFF007171E8000809D5001011D6001112D7001112
      E1000D0E9B00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9C001112E0001112D600090AD4001D1DD500F8F8FB00FFFFFF00FFFFFF00FFFF
      FF00F1F1FC003838DB000000D1001314D5001314D5000000D0003839DB00F1F1
      FC00FFFFFF00FFFFFF00FFFFFF00F7F7FB001C1DD4000A0BD3001213D5001213
      DF000D0E9B00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9B001213DE001213D4001213D5000505CB003939B000F1F1F400FFFFFF00FFFF
      FF00FFFFFF00F1F1FC003B3BDA000000CF000000CE003B3CDA00F1F1FC00FFFF
      FF00FFFFFF00FFFFFF00F0F0F5003839B0000505CB001213D4001213D3001213
      DD000D0E9A00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9B001213DC001213D2001213D2001213D5000000C0003738AD00F2F2F500FFFF
      FF00FFFFFF00FFFFFF00F2F2FC002B2CD6002B2CD600F2F2FC00FFFFFF00FFFF
      FF00FFFFFF00F2F2F5003737AC000000BF001213D4001213D1001213D1001213
      DB000D0E9A00000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      9A001213DA001213D0001213D0001213D0001314D5000000BF003536AC00F1F1
      F500FFFFFF00FFFFFF00FFFFFF00EEEFFB00EFEFFB00FFFFFF00FFFFFF00FFFF
      FF00F0F1F5003536AC000000BF001314D4001213CF001213CF001213CF001213
      D9000D0E9900000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0D0E
      99001213D8001112CE001112CE001112CE001213CE001213D3000000BD003839
      AD00F2F2F600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00F2F2
      F5003839AD000000BD001213D2001112CD001112CD001112CD001112CD001112
      D7000C0D9800000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      99001112D6001112CC001112CC001112CC001112CC001112CC001213D1000000
      BC002A2AAA00E6E6F200FFFFFF00FFFFFF00FFFFFF00FFFFFF00E6E6F200292A
      AA000000BC001213D0001112CB001011CB001011CB001011CB001011CB001011
      D5000B0C9800000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0B0C
      98001011D4001011CA001011CA001011CA001011CA001112CA001213CA000000
      C8002B2CC600E6E6F200FFFFFF00FFFFFF00FFFFFF00FFFFFF00E6E6F2002B2C
      C6000000C8001213CA001112C9001112C9001112C9001112C9001112C9001112
      D2000C0D9700000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      98001112D1001112C8001112C8001112C8001112C8001112C8000000C2003A3B
      D100F2F3FE00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00F2F2
      FE003A3BD0000000C2001112C8001112C7001112C7001112C7001112C7001112
      D0000C0D9700000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      97001112D0001112C7001112C6001112C6001112C7000000C0003738CF00F1F1
      FB00FFFFFF00FFFFFF00FFFFFF00EEEEF600EEEEF600FFFFFF00FFFFFF00FFFF
      FF00F1F1FB003737CE000000BF001113C6001112C6001112C5001112C6001112
      CE000C0D9600000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      97001112CE001112C5001112C5001112C5000000BE00393ACE00F2F3FB00FFFF
      FF00FFFFFF00FFFFFF00F1F2F6002829A8002929A800F2F2F600FFFFFF00FFFF
      FF00FFFFFF00F2F2FB00393ACD000000BD001112C4001112C4001112C4001112
      CD000C0D9500000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      96001112CC001112C3001112C3000405BF003A3BCD00F1F1FB00FFFFFF00FFFF
      FF00FFFFFF00F1F1F6003839AC000000B5000000B5003939AC00F1F1F600FFFF
      FF00FFFFFF00FFFFFF00F1F1FB003A3ACC000405BE001011C2001011C2001011
      CB000C0D9500000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      95001011CA001011C1000809BE001B1CC300F8F8FE00FFFFFF00FFFFFF00FFFF
      FF00F1F1F6003536AB000000B1001112C4001112C4000000B1003636AB00F1F1
      F600FFFFFF00FFFFFF00FFFFFF00F7F7FE001B1BC2000708BD000F10C0000F10
      C9000C0D9500000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      95000F10C8000F10BF000E0FBF000707B7006F70C200FFFFFF00FFFFFF00F0F0
      F6003738AC000000B0001011C2001011BE001011BE001011C2000000B0003838
      AC00F0F0F600FFFFFF00FFFFFF006F6FC2000707B6000E0FBE000F10BE000F10
      C7000C0D9400000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      94001011C5001011BD001011BD000E0FBE000000A5007071C000E5E5F0003839
      AD000000AE001011C0001011BC001011BC001011BC001011BC001011C0000000
      AE00393AAD00E5E5F0007070C0000000A4000E0FBD001011BC001011BC001011
      C4000C0D9300000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      94001011C3001011BB001011BB001011BB000E0FBE000405AA001A1BA1000203
      B0001011BE001011BB001011BB001011BB001011BB001011BA001011BA001011
      BE000203B0001A1BA0000405AA000E0FBD001011BA001011BA001011BA001011
      C2000C0D9300000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      93001011C1001011B9001011B9001011B9001011B9000E0FBA000809B6001011
      BB001011B9001011B9001011B9001011B9001011B9001011B9001011B9001011
      B8001011BA000809B5000E0FB9001011B8001011B8001011B8001011B8001011
      C0000C0D9200000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      94001011C0001011B7001011B7001011B7001011B7001011B7001011B8001011
      B7001011B7001011B7001011B7001011B7000F10B7000F10B7000F10B7000F10
      B7000F10B7001011B7000F10B7000F10B7000F10B6000F10B6000F10B6000F10
      BE000C0D9300000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0C0D
      96001011C7001011BE001011BE000F11BD000F11BD000F10BD000F10BD000F10
      BD000F10BD000F10BD000F10BD000F10BD000F10BD000F10BD000F10BD000F10
      BD000F10BD000F10BD000F10BD000F10BD000F10BD000F10BD000F10BD000F10
      C6000C0D9500000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF0C0D95000C0D93000C0D92000C0D92000C0D92000C0D92000C0D92000C0D
      92000C0D92000C0D92000C0D92000C0D92000C0D92000C0D92000C0D92000C0D
      92000C0D92000C0D92000C0D92000C0D92000C0D92000C0D92000C0D93000C0D
      9500000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF000000FF000000FF000000FF0000
      00FF000000FF000000FF000000FF000000FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000080000000200000000100010000000000000200000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFF000000000000000000000000
      FFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000
      F000000F000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000E0000007000000000000000000000000
      E0000007000000000000000000000000F000000F000000000000000000000000
      FFFFFFFF000000000000000000000000FFFFFFFF000000000000000000000000
      FFFFFFFF00000000000000000000000000000000000000000000000000000000
      000000000000}
  end
  object pmRecentList: TPopupMenu
    Left = 139
    Top = 387
    object pmRecentList1: TMenuItem
      Caption = 'pmRecentList'
    end
  end
  object ImageCollection: TImageCollection
    Images = <
      item
        Name = 'Project\01_New'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000047D49444154789CB5986D5054551CC69F5D7009324A041A0C67C8A2BE
              D8D4942539D34C33CD549AD08B5A890A88A5295A3389A55620BD686905056A56
              A222A00219990A6AE58726C561C6518B1A5845884DE245C9805DD865777D0EB0
              E0B87BF7DE85B3BF99FF73CFF9B3ECFEEE3DF7DE9DBD3A68C7F55AD7D6179C2C
              816BAB192D1F265E234A3F580231D78A9012E5182C31D68CDA07E9F044525874
              A73E1B7A678215B8953D9F3000974D3D2D5370A6B29553BE45BFA4284DA809EA
              27C6A594F7C219CFF188A1E4555357FBA3F8E39089D31E969DA549524D303032
              2ED9C62D72B256E081C9B11C69E78DB539385B5BCFD1A06467EB34D4543471AA
              59524DD040C15E6E71BCEC0BA66FA467E4A2CBDC8BF0B050FC76BA6644929A05
              7F29F55D7065662ECC660BD25267A168FF319C3AF397CF929A057F2EC961FA46
              7A461E8FA0198B931238034A0E1C47F5B9DA1B252D2C21E9F1EA56130CA2A0D8
              4BFCB42F9BE91BAB32F3606C684254C478CE0630363533B9E74087A9AAEE3EE0
              6407A7E220084937340B1EDB9BCDF48DC2D24A9CAB39CFD1300EA78317CE458E
              80D6AAEAC9C09F9738EC62F55F8C37A259F0E89ECF99727872EE9B4C21786A0A
              10F137F0EB554EC53DD20DCD8247240A3E3524687C849B46E0841014CBEC868E
              E58D21C1CAE2CF9872783A71259382574E4E455D788314C18AA24F9972983E2F
              9D2959F070A1BAE079731FEE0E09E4C83B33E6FB41F0D0EE4D4C658A9B2DA8FE
              DF868743C720312A981D659E59B08A2959F060C146A6329B9BCCB860B1E3AEE0
              00A44D0C61479999496F31250BFEB86B2353992DA661C165D121EC28139FEC07
              C1033B3F612AB3F51FCB90E0D23B82D9512621E56DA664C11F767CCC544608D6
              F73830E926BDAAE0B30B5733250B7EAF22B8ED3AC1252A82CFFB43707FFE0626
              50CF65F4C4C1CB565CB23A31C1A0C3CCF10676DC99C4E517BC90BA862959F0BB
              EDEB51DA66C5E92ECF825A78706C00E64418306BD15ACE240B967DBB1E65EDA3
              179C1D6EC0EC57FC2058FACD474C2E31CF334F1CBE6243B3CD89A8313ACC081B
              C38E3BE2FC14CC79F51DA664C192AF3F642AB3BDC58A8BBD4EDC19A4C3A2DB3D
              9F832E5E5CFC2E53B2E0BE6DDE05F35B87055323BD0BBEB4C40F827BBFFA80A9
              4C7E9B0D0D148C1182119E97D8C5CBAFBDC7942CB8474570C775820B5504E7FA
              43B078EBFB4C6576B6F5A181F7C118DE07532202D9512671690653B260D1962C
              A632E51D769CB538717FB00ECF8D0B60479979CB329992050B376731BDE35A62
              35E6A7F9417077DE3AC862C1F2751048152CC81DD86B1924ADC862CA111C7AF4
              B1EB4B7982C9AF67312958454148125CB33C09F7C6C660B4D41A1BB021AF0006
              3BBA4DD5558F03918DA3F9E16E888E4B2EE77F4EE7582A06ABE388A9F3C26A18
              4F3471DAC9E2C7B8A326188887E22744EBC7E543A79B6AD5632C7BA3C660B51F
              35D9FEDD84DFDB1B81A816FEEA36B3DDC77243C7F2869EC52FD669A140F76D88
              BD3904C676F135A1C33DCC9150C7C76CB1E13618CDDDC02DFF71795D47CFC172
              434D50FC5D480AA9205620F018E776D11F2101CE810AA65405ABFFA9969063CF
              9D6B24DC73475605A83E0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\02_OpenProject'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000003D749444154789CED977B68536718C69FA436AE6DEA5CEC5AB76658D9
              3AFC63B01BC3323618DB18BB908DB1E1366957B7B14D51C16BB55EEBB5782D62
              8BA2289616ADA2B4225EF10F41D06A511045A45149E889D45ADBE8696B9B98C4
              E78D9EA42D514F4D7B54E80F9EE77DBFEF949E27E7927C9F092F388301E36530
              60BC0C068C97972EA08C45664AAA48A37B2F84280DE903945451BFD1FDA4267C
              F5A7CDAE9A4B600EFDE8035EE59C1E2E35D5967FC6DA45F9A920D56F21BB0734
              BF9533A1A60B2107FB3E6109FA4B95B30D4B81932A87FC6CE180A2B8D1024A4D
              48CFC9972B80C2C9B918933D8ADD93B9E274A3B8AC9201836DAFB4A88EAB576B
              2E70BA9DBA4F851E292E249820359101E53661EBEA02BA3E36EFA8C6B9CB4E58
              0281134A9D330F38E3E5B4FC9F00F52CC8871285916082991AA2052C5B319DAE
              8F96D6BB58B5A122D4E6F79986FA3AFE6A38EF39049C92AB28012327D281F6B7
              F20C8B641CEA1E50AE60272B4A8AA6D06373A3F116EE75FA589B59BB70DDE581
              877D1BFB78490CA0CA83AE02D455DDE2501EB760CC8013731DE89410376FA3D5
              ABC27B47452BD54C0D347C54AA953AF7FFDA0B1733E093B08FB02123C386D159
              99484D49C2DBA333614D4EC2FBEF65F3E8B373E19213D38A4AC32F9C72F6E247
              C01B3781C31D261E137A04FC70CC3BB05A797286B04A08D68CD76D18996EE3D1
              81E3CB71D3E84053CBE90F505FAFB05563063CBEBB846E3C5FFFF6F0E56CAAAD
              FD044877F336DF31712CF408786CD77ABAF17CF3C70CBA043C3D164873F1DB20
              76C0233BD7D18DE7DBF133E90CD8C280F569AEC7063C54B9966E3CDFE7CEA2EB
              0878B0620D3D8A4B6982F76E3BBBFE63F8B01464D9D3D945F9216F365D47C003
              E5ABE951DC9E8109382AB36740477E015D47C0FD3B56D18DE7A70973E83A0256
              6F2FA61BCFCF7F17D27504DCB76D25DD787EF9671E5D47C0BD5B57D0A3288DB7
              A1B675B0EB3BA9D664D8478E60F7747EFD773E5D47C03D5B96D3A378C201EFB1
              EB3BA9FCC9CCD41970DC7F0BE83A02566D5E46379EDF272EA4EB08B873D352BA
              F18C9FB488AE236065D912BAF1E44E5E4CD711B0A2B408CF83BC2945101EB758
              88EC490AA7E67357970523B9E274A178633957D46857EA6ABFE8BDDC929A68CF
              C9AFF101DFB17F6E587CC1A38A7A6D2E9CA71A388C2C58A526E063C79B76F36B
              DB61328DF59961E59CA1587C81638ABF710D2E36BB7B2FF905B9CD16E0D361DC
              7B0F47764A329CCD899C33E15DFA4053CF6D66769A1FCE0EAE4A52BDBCBD2A67
              239B26417A0929A186524380CF390EC8BC0124841E2A894FD961AAE7B65343C6
              22060B4B90B111305C98E023C938B271EF8D36AF55A390508256F10077E7B5C0
              7ED712730000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\03_Reopen'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000058549444154789CED977D4CD4751CC7DF777020DC29C6A32808891246
              36D499CC6552D27A12D7AA39CD07329B980F9BD532CD2CD4994F2B72A9A96565
              EA6056CAB465EADC6C6E0A9226031FE27CE0E474F2204F0708771ED7FB73E781
              7077F85388F507AFEDF3FE7C3EDFDF6FF77BFFBEBF87FBFE54F89FD363B0B3F4
              18EC2C3D063B4B8FC1CED2DEA0F4126A86640927F7D6828DE1446A2B43B24497
              71EF4155183F2330C2A4CE80DA36D10C04704C098565393B9E666E625818CD8C
              2E3379AF417564E25BD94DB0A5B07E207C9A2D1B8DA74A5600C74D6C796E7683
              129DC66950B2576862AACC0096CC9B86B82151AC3AE6A2DE80D59B76D160735D
              AF4A53CAA54BD9F91CAE67DC61D8EE46A7106382640D0DCA65C2B7EB165195B1
              E5C77D387D5E0F1FABF598314F3F1DC8ADE6B0FC8E95F130C84949D81163829A
              E1ED34B869D57B54655456D562ED869DB63A8B59E56B6E98B934FE4661528C39
              D84FA3B656596C8684F45306EEA604A729B98725A4B7A928821894196C644646
              FA7CAA7B6EDC2CC7ED463373057313AE145FC79C01F93868F0C3B291E588D0DA
              EF9216CE57F9624341100E1BB5EC3A466345D675342D425E56395BF9A166B706
              E74C4B41A39828BD85AA6A13AA6B4CA8625430DC71F54D3DB563724AFD91763C
              1CB56639946778ABEC33E619D29C0F9C5B831D11111488B0B0403C1A3D00BDB5
              7E18D3BF09C9E5DBB885D743ED8DAA27DE863960103B1EACE60AFA5ED80DB545
              9E1BA031F849DC7C660D2B57F20BF55898BED1FEC0194F158C00C24B81830D2A
              6E13D48C1683C3E30643A7F3430C4D68694272584820FA850672AB2B83B25FA1
              3A300D4C46F988D67B584C869CC9802FB350C66D75DCC71DE3272DA4729FCA93
              09282A32B234B93578242B83AA9CC1FB27505BA98D4C46D970C7C104B5A50E51
              4766C1EB4E3D2CFE6130246FE7A82BCF4F769C58594ECE2820D4C0CB5CA3622F
              B4317828F34BAA72620FB8BEDB6B22C7A334A1D564D8D9AF1050729415509472
              80EACA0B53DEA78AC193A381E062E0847B837FECFE82AA9CA0A24CAA2B75FD46
              A3A9CF2056401FE35184E76F60055C4B5C85DB41C358B5E5C5A91F5069B09206
              8B828B3D1AFC7DD77A6AD7A26928C3E063B359019792B6F15287B26ACBCBD33E
              A42A30F8DB4FEBA85D8FE67619952F383F5773C284198BA80A0CEEDFB196DAFD
              4C4CFD88AAC060F60FEEDF55EDF1B93B23660F33F2A0BC3A73315581C1BDDB57
              533B46CCC59F98CB0A3837667397987C6DD612AA0283BF7CF739B5637455E7F0
              D8DFE9108A87CEC5ADF0675971CDC6775DEC9974F8D715A33DA79FFB99EA9937
              DEF998AAC0E09E6DABA8F767D4B14954A0A2DF385C8D9BC7CA81988C3B2B260D
              EC5AC94BDA43F5CCA4D94BA90A0C666D5D49BD3F09B90BE0DB588EA65E212818
              B906566F2D471D88C9A16757405B6F60E720775C16D53393D396511518CCFC66
              05F5FE8494FE8998A22DACB88CD646E3726C1A1A74D1702226E3F397C3BFA184
              1D57346333A99E99F2EEA7540506776F5E4E55467CC14A04D45C60C5753E67B0
              64E0EB341BC50EF6D98BBCF62BBC6954281CF6096A031E67E59EA9733FA32A30
              B873633A9422071F7A310301B50E939EB078EB90FBD456569E993E3F1D82A7FF
              E29625FF9205A9FC688AC6831054F917A28C7BA16BB8C6AE9546DF60FC139386
              7AFF81F619F6C4457D31567FBD830B56D41BF37292DAAF66246B221253B3CDC0
              4BAC1F9A08DD9D9665BFB15E03639D372BE5F8989B0F194D9717437F426E5C93
              1813247B61644AFF08F523DF43A51ACD95B98E63DD8A8FD97AD868B9B91E0515
              86F62B6A41CDF001C6F4E133D91743B4FED0576838A6422CF5BFA6885F714382
              2DD037F089EA5DCDCB6BE268CB378920B5981453BE0C5E9BB1ECAD32DE0D78D9
              1CE1C7BBEC20A3ED579D13E92568CC1E82F4DD01CDD969BE1BD2B77C17B7C739
              EECCDD8598129C19FF02135448C87015B2580000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\04_Save'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000056149444154789CCD98795094751CC69F5D61112215059D9CB5ACC466
              9AFE7072D255C73C4A0BAFC0EC501134CD139D1A0E6F60B1BC0D133C4B4D44F1
              2A0D0F14356B0CDC19C76AD269527494438D235C03963DD8DD9E1F88CBEEB2F9
              BE883B7D66BECFFB3EEF32BB9FF7B7EFBEC02AF03FE7BF041B1F6BDCB626768E
              A071EB91E65E5C1C13A37C3002D15B834621B1B572C4568C475C5F588137A23A
              AAAB94A950DAC79881F63CD6DA5C29335946E1D7BD65DCB7701A459BC55550D9
              4D33F98809F6D1DC6F96405F15BA3FD7957BD2B8557807D51633F71C28ACB63F
              4B4DF7C3F17BF66D56134748DA386EB80AFA74D6448BB3C27AED5CF47A25947B
              0E62976E40ADD98245F3A2D9A4B17CC32EF8AB7CB16ED93C54D71810BB240D57
              8B6E37481AF511B87CB4843FE651D255504541F1C33877E84BA6337189691434
              23614E249B34566FCCA4A00A6B53E6B2A15E326E697ABD24ACB6AB65B59511B8
              72BC980F89D77593F428F8C34177C1D8A434988C267C3A6B3C9B34523767C1AF
              AD1FD6F11D694448C6274A93F42878F6C07AA633717C5203053F99F13E9B34D6
              6F3D80000AAE4D896173505D538B84248F92751C3BC74DD08F82466E71667F2A
              D399783EA1C16844CCD4716CD248DF7E88826DB146EB2C281092F1C9E92828BA
              D32069D4873FB82685835849BB47C1D3FBDC0513F86406831133A744B04963CB
              CEC30808688BD5C9EE82022199A06D90ACFFE05CFC63287049CF87C44A7A16CC
              CDFA82E9CC7CED46541B6A313D6A0C9B34B665642330C01FAB92E6B0358F901C
              3B6D31F78032DDA59781E0BBC08F35AC751E054FED5DC7746641CA263E990153
              268E6493C6CE3DC711F854005626CE66F3CC5B13629914ACC8EB8DEBEA220AFE
              C3EA59F0E41E77C1D42D59C8BB78199D4382D8A451567E0FC307F5E1AA87B379
              E6ED890F0475057DB82904F2EF736B51309AF2503027732DD399D2F24A649F3C
              8F9B85BCA82512C29399307638BA847464F34C58641C93829517FAE25AF0AD47
              0A1ECF5CC3F41E2323E39932048FEDF6AEE0A84932058F66AC667A8FD151094C
              1982D9BB5631BDC798E8F94C1982DF7FE35DC17726CB143CB27325D37B844F59
              C094217878C70AA6F788F868215386E077DBBD2B3876AA4CC16FBF5ECE74E6DA
              8D221416DF85897F55B7949E2F3E5B3FAEBC3B6D115386E0A1AF3E673A10723F
              E5FD8236010150FAFBF3887C6CB5B5B01A0C1834E05537C9711F2F66CA103CB8
              CD59F058EECF28AF322068C810B69673EFDC39A83BB5C7B0C17DD91CBC375DA6
              E0FE6D9F311D9CC8CD43799D0D1D34FDD85A8E5E7701213E4A8C183E80CDC107
              D397306508EEDBBA8CE920E734052D7674E8A7616B39FA0B3A84F82A1036CC59
              F0C3194B993204B3B6380B9EA0E0DF7514D468D85A8E5EA743271F0546B8088E
              9F295370EFE614A6831367F251D94A2BD8912B38E2CDFE6C0E26CC4A64CA10DC
              B349CB74904341B182418F790DDEE335285630CC4570E2EC24A60CC1CC8D5AA6
              839CB3F9A8A8FF140F656B3995B9A7A0EE128CA1AFBFC6E620728E4CC1DDE9C9
              68CAF59BC538AFFB0D3EBEBE68D3AE1D8FC8C7C67BA085F7C2819A5EE8F17C37
              1E713029261902C98219690D67D41421595C52FA58BF497ABCA076931344CDD5
              321F2DF8F09B855D1BDC059F24D1F3B44C0AEA280809820B63A2F05268777883
              AB05B7B0223D032A2B6A4A2EEA06039D0B81F342D0EDDF4E955A137DC40C8471
              DFEBA8CCB65325553716A020BF98B58AE3B6823EE83DBAAB5A19B4030A455FB3
              12813CE61554666B6E89E5AF35B85C51083C53CAFB868187AD0A4653941C15D0
              9F1FD39A0E08E557020515BE3CA6404FE693E21ABFC90A0DB6A0C050033CADE7
              DB2B568F6F246CAE82A20B4921E5C7F10106B2BB9D482BD3C6DE30FE94CAE140
              DC266C1CFBBFFEEBD27BE8B074BD0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\05_Print'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000058849444154789CCD980D4C94751CC7BFC7BD8846822F61D2F16241E2
              5A26363984DC6CB5969635A7692A0156F3255BF9325F5BE56A61EA4A6B1A66E5
              DB0CCCD9B05A59AEA99B9B806C92A2177AA89C07BE9CC8205E4E0EEFE8FB3B7A
              8E83533C7CE0D667FBFDFEFFDFFF39783EFB3FF77FFECF731AFCCFE9AE60773F
              7F375A195D12E809E57312210C697B02917333A495B82D819C4C836732064637
              6AB6D7BA3180B5FCBB40FEEE8E84A3D5DABFB125DB6CCE3BCFB285A188FA11C8
              8942A253B2F6EB43F513E38C515AD6AAA9B05D76373737EDAA2AAC5A0A1CA9E7
              9022E9C7DD04E5B8F6A194CCC309F1B14FAD7A2793A57AB2BFDC0973B9F584BD
              F0C42B40E9750E39182E462BA30322D015725CC7193CFC487C74DAB205E92CD5
              B36EF36E982D17FFB21795CC02CE5CE15003E3164385E0C3C6B445F367B054CF
              869C3C982F584FDA6B8B5F4359591587E432AB138C8B33A62D9C3B8DA57A367E
              BD17672B28D8509281D3A72B39D4138251696FBF3195A57A367DB78F82B693F6
              9AA24C9C3B67E3D03D09CA31099D9182C362A252E7CD9ECC523D5BB6E7E3EC25
              AF60E71994F02202B743C69510C143B1314353E764BCC4523D5B77FD0CCBA5CA
              FF04A3F81D3CD25950C28308F822B5849621ADEC1C3AA369F6C1D898216367CF
              7A81A57AB67FFF2B2CB6AA53F6EA822C941BB98A8F34705804E55EA88448B68A
              848277C7680626B1EE40985E87C80707B3A71EFBD56A34B4884F47F42EECA942
              F33214EFB9CEB285E1F615F4EC18CD68F5930B2606972BBFB2D83A17382A97DD
              A9084AAB8D4CC9146B7CB36E29E28719D90B1E27CF58B070F52618DCEE86CAE3
              A5A381A1D780034D222648ABA720AF2EF0E70F1B9983CFB3D31732F32B505330
              4A59DD2226781683227830EF73E6DEA5A8D6732A9822FA30B7F1DC8CC5CC142C
              2C1C03445A7999EB34AC05119419BCC916BFE77EC6DC7B14D53A917BB9893D60
              66543F4A1AD8039E9FB98459040B4CC0E00AE0D8ED057FDBBD9EB9F7385EE744
              DE15CFA93063682892C3DB0427A62F65A6600D05CF7521F8CBAE75CCBD4B719D
              673D624CB89EB98D4919CB980310FC69C75AE6E0F372D672E60004F3B7AD610E
              3E935F5FC91C80E08FDF6633079F296FAE620E4070EFD64F9883CFB439EF3107
              20B867CBC7CCED343639F804928F4687E7B06A060F8CC094179FC6038306B06A
              E7D579EF330720989BF311733B1B72726129B7E2F1E1B1ACD4537AD68A54D313
              489F3691553B33E77FC01C80E0EECDABE14BF6861D18747F28F67DB582957AA6
              BEF5296ED4DFC4AA4559F0257DC16A0877BA517BB7BA957CBD4C4C8883C2DA2F
              44B06F0F0B3AB0FCDD2C2894592AB086AFA306171A2B8B0BC777DEEAA4D51B53
              32F73B8109ECFB312E29B147058F9694B1E78FC1E9FEA3B2FEFC0A588ED9587A
              1F16A4D5E2C94951C69001DBA0D1989C2108E398175FC163A72EC276AD96BDC0
              891E1281D491C3D8BBB3A0C1E93A58D972753D4AABAD9D1FB704B9CC0620B53F
              D76D0412EEEB070BF4887769230725E48C1BFDD8A89E15FCBBD46E2F59CC53DE
              4488EE16CAB52E24F029DAD2D408DCCF7FDEF1815590BE48EA197D80F16C398F
              D0F0A5293EDF949498AC08AAA54DD07CCA7EC33C0796E66AFE9CE4E02B890BE8
              2BC16FD90106653B3DF20B524B50CC1B9E9726D3E847C72A8281CCA0EF8C75C6
              2BD8CD97265F645C09CE60D62153D2F0D41E16BCA7D74E5FE49884FCB2702839
              69789A22A816AF60FB4F1FCA0C8A98841711E80A39AE332667EEEC17D6773A77
              12B9E4AAE14EE276D43B0A6CC5C57301F3650EF90A764004BA428E6B478C989E
              F84FB86E490B7423D1EA0AE16D48C6EF993EAE9006DBAD0B1FA2A4C60AC4D8B9
              289A38CC05D27D414166CD008C0F036EF016E40E45A24B0B9D4E036787BBC0DD
              3118DA044EBB29A3E1AE35B04EB99D306461F811C809E43322A96350D4D3CA98
              1A283A8192EDB71306C7FCF917705789B32BFC50140000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Project\06_AddModel'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000004F249444154789CB5977B50546518C6DF73B86C5C5C08B92A4CCD983A
              CE9063334C5033E01FCD3015499956432AA28534534D17D19244248CB21B2054
              285D404110CC160A61B2126C5218AB41134BC802591676352E02CBA5718FCFB7
              CB2E03B3CBEE613F7E33EF73DEEF3B3B7B7EFB9DCB9C15C83EE6CF98B7729050
              0CF35636B31D94ED63254E16838D1D8549B1324C16EB6563EB80023D94E8173A
              24E69028C54F10F9604E16EE44FFA9C7B411D452AFC3105F619464250B5B8262
              5854926A9CA435E8E70C2407D5C3371EA04BB56A0CC750B750B2246D09BA0646
              6DFE1F5BCACD7C9956852F45E738AFA4E5D2852BFFA09B941CD23D48AD755D18
              CA96B425E80EC1716CE9F4F13CA43C52F7E4D3B07E9CFCFD94F4CBEFAD4E49DA
              15FCA94ABEE0F68C7CD2EB47E9C5ADEBA8ECC4296A6EF973CE9276057FACCC45
              CA23754F0156504FDB12E33122AAAC394DE72F5E9929398A6292B3DEDDB60415
              1064BF927E38968394C78E8C026AEFE8A2908085189968EFEA41E29713F5AB9B
              DAEE253AD78F215B04266913BB82A72A7290F228ADAAA78BAD7FA39BC2201970
              E3FC8B8E48D7743E9CE8B206ED30CA7833DAC2AEE0F7E51F23F9109BF03A9209
              364710055C23FA791043F68CB4895DC1FAA31F21F9F0F0B3DB914CB0FD7E6C3A
              89CE3241769A6D22A0AC6111AC2BFB10C9874736A42221D8772E92DAFC3BB808
              9E2CE527F8E8C67910AC3DF201920F719B7620390B7E77F87D241F1E4BDC89E4
              2CF86DC9946067B78E066EEAD13986AFD293EE5A1C88CEC49ACD3B919C056B8A
              F7234D74765FA7C1A111748EE1B3C00B8201E84CC427BD81E42C58FDD57B483E
              3CBEE54D2467C16F380AAE9D0FC1135FBE8BE4C3935B7721390B7EFD4536D284
              BAE706DD1C1A45E718CA051E141AE28FCEC4BAE7D2909C058F7F3E4370588FCE
              3194DE9ED304D73F3F0F825545EF20F9F054F25B48CE829587F621F9F0F4B6DD
              48CE82C70EF2137C26C5243836AAD9E4E916B45274119743C14082D0228854DD
              7DB6B805BBA76157B0A2300B6942A3EDA3E111DB3789B797072D0AF243679D84
              17D28D0714240450040521B1845A2D12F3442A770F614B4743F1008646306715
              8BE0D1CFDE469AE8D1D9170C09B42EC8FE44A5A4EEC7ABB581FC6363C9273292
              A283BCB007AFADDA11EA6F6CA4BE33674810C53FDC15528C59D2AE60D9A79948
              E7C92B2CA7DF2EFC4561C9C9E41E1C8C1988C52D411245D75E45E2D5BAB797BA
              8A8A98944AD35CB21653ACB78A45B0F4934CA4735C53F7507A76A165E5CCCC14
              649857527411EE63D7A480396B58048F14EC256751D53690EA64032D494FC768
              0A6B828CAB5959B86F844C4D53F15E5B8296FFC587F33390CE71E050055DD60E
              5042FA6B941D118C19DBA4FDDA4BE5593934A1D5556B9A8B9FB02B5872C079C1
              FC2208EA062961F7AB8E09EECBC5F5A89D5D30342AE9FA0449CA5D2F25D2F2A5
              77933354D735520D8AE729760B8B4CCA1F17A414F44EC30E224AC4F526714579
              2E8EDA9027185CD74F88E48DB1538828F68076EC3123184F2FA6D05B877D9F1B
              0A62E1BEB46CC29BDA048C25919661760EDCA1F5F5F65BB1E2A024D13D7EAB57
              D39D3131D31FD458B53EAC9E288A97DC145274879D07359B67052952A0B08D86
              F42D3637475C249FB0854AAF109F3C49A0384C90627225C7B1720CB672EE1E94
              649663CC7640B68F15C48C5B73CD159C60238645511B57E22A8AC7CC2A8CD9B7
              B2970515BBE6309A862307347FC6BC751626CACA216E03254067470BCB160400
              00000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\07_Export'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000058E49444154789CE5970B6C14551486FFD95D06B6DDF2AC05A4A0AD6D
              4541432450C4145B091A02C4805504AC6D256851B44250234A0A3EA334208A02
              121E8A15D1026990102548230885A29484E7B614A48BC00A74E99BEDEE8EFF59
              686D85ED2C4C4B4CF89273E6DC79DCFBCDCC9DD95905FF736E2DC1844D256920
              DB47C5AC422BA1305A85C44DC7077835EF3696302BE6A4FC5151452C0DD32A82
              89DB8E77F6547B28A70C6093684596504B527E52948B0D43B48A60C28F252B35
              200D4D60C7ABB68F8E4967690885610899779A86952CAF4251906E743E2A8C1B
              A661DE69406736AF829DBB8CCE47F671DDC831CAC0A51BBB5A7BF5DDC27200DB
              2DA01501B58FEC187D7F051B72AC8FC173F2872E7240B0C8BE4AFFFEA9514E1B
              D6DF9E9C1C69EB7B4F57AED3A5EAC8E10B7FE5E63AC22BDC130F1D5A53CA55F5
              0C1F4324250222830683ECA7C40D4D1B58E3D3B6B8814EECF5F0DF05F611C02E
              17B7D53D9477649862B6FCC29A436A493BC6C4E683C7304C114352F771799F0A
              54A8973CE34AF7E5EC61FB12C3C36057FEB826D2811EB28F2972C833E97CC365
              8B1C072A749C3B9189928BA781A2F3DC5E4BC184008266C48FEC11A974CF7543
              8B57BDBECA7A0D5967F796AD04F26BB95D247D0C8D7115D2414BC87653C4A0D4
              E91C661E6BA83E5F9EC3B53B0B762B3BEF58CEDF8D4AAE7653F0E10082123CA7
              84B0C841772C759BCD63D9E6F5F3BDE3DCB77A21AB1A46D35BDE0C393810B2CD
              1C39386D85DBA4A5B066179E794E57610EEC21EC34E422B0B38A6B7951E1A560
              620041C1CCA0E450DB6D0F44672AAA7916DBE0D55CE7282CCB00F2ABD914492F
              A399644307FF4541E2846E61D5EA7AAB1909AA57A9745BAAB39DE7F7E7C1AE52
              AA4B05AF1C25FD723E863674FD814493DA612B6BF8DC75C3778EEB9F8F7F9171
              4C0C4A2684440CEE93AEC232DB6D82ADD6EBDB53E9AE4AC1FE0DA7B85DE6A597
              D12829075E0BCEB9D42A8E6E1539D49467382E1D3C8292D02B72FEB92367EC97
              6320FEDBC261ED3A76F99925EA2BCA1FDD3D71D0AF2C9B22639918ED80446BEF
              7BC3E3355BE8372249EB3A47C18168E07779E04452FA94F01F742DDAF1C97373
              89B58BB3D023A21BAB96395AE9467609EF3A9919D309778771581DCE38CF63FC
              D4B9AC0067C1DE7EC0413E74E045F03F382D0AAA149433C1B6DC85CCFA1CADAA
              C7FC2B823344D0C60B150449C999CC143CF7DB4094F42CE3D4914E4450EE8EBE
              E0D6EF3F61D6C74EC105A5BCFB647A7447C4052938FCA957992958503C988B3F
              F9E08960C3F4D117DCF2DD02667DECD5F55878BC921590191586B8D0E004473C
              3D9D99821776C5C31E7E2258C1F614ACE3123FAD99CFAC4F31053F3D21D30778
              E54E1B6283147C6CC20C6603829B73B299F529AEF660D149799D01D3FA8452D0
              C24A9F919366321B10DCB47A1EB33E25351E7C5E56C30A78A97708624282131C
              95F21AB301C18D5F7FCCAC8F082E76C8EB11981A690D5A70CCB3AF331B10CC5B
              F511B33EC76ABD5872EAB260462F2BEEE24F50303C9EF606B301C10D2B3E64D6
              4704BF3CED7FF0F17CCFF6410B8E7DEE4D660382EB967FC0AC4F2905979DF1FF
              F8604A0F15D1410A3E317916B301C11F96BDCFAC4F699D0FCBCFBA590193BB53
              B08389953E4F4E798BD980E0DAA5EF31EB53EED130FFF465C1193D5574B104EA
              BA39E35F789BD980E09A25EF3207878B9242E720E5840919B3990D08E67C3197
              B9ED98F46216B301C1D58BE6A02D49993607C2F50A367E2C7CF5D9E5336C2B52
              5F9ECB6C40F066D1E473CBC5A587A123F860EA1FFCA6EDC7BAEDF1FA8E395DC7
              9251AC3AF877A2826B74052DFCCE08014E4620B6930DC5FC1F11772ED0BEC6B0
              876B88E52D2DBE5805F471F2FBA9866BBD0C8D115050DEB222D981FFC955FE79
              93761BA2F26A59F912DD2C0F66E3D51302090A22D510424BFB1AC17FA5884835
              44237A83CA76899B81884A34E3660D7EC3FC03615084475FDB76F30000000049
              454E44AE426082}
          end>
      end
      item
        Name = 'Project\08_Copy'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000051649444154789CCD987D4CD4751CC7DFBFBBE34E40B41C63D9B0D596
              ACFECB5A13DBDA9CAE660FDA6A9AA689242ACA5040047992275110441E875A61
              8449F4B0B456D36CB5B63661F14F9B6E15D88271AD27620AF1700707BD3FFC38
              C47BF8DDF9FBD1E66B7BBFBEDFEFEFEEBCF7FD7EDCF7EE54709713A8A0FB76F7
              A8974946708F41E3EF89E5B8C4341D41D67A70979A988EAC2541E1EB4915AC8E
              5B143D68AA8269729D1358C863860871A1F5373832D1D1FA3797638CBB68407C
              15342D898DBFE0C0E45ACEE70CABCB75DEDED193087C37C8255FF754C980F82A
              68898ADD26AF12F9A9F17834E621CEF4F363E7AF28AE6E827562E25FFBF7571F
              0716FF095C1CE64D2E26E05954184FAC2CE8E08896FA02DA389B938B68E0AFFE
              B6C7D0D969E77490919330C968A2309ECC147CAF369F36CEEBFB8A69166C6F7F
              1288EAE165BEC9E53833C168A2309ECC146CAEC9A38D13975242B3607FDB7274
              46760357A4A0FB0C4AFCE2ABA08D054739A2A92A97364E7CDA119A05FFB9168B
              AE881EE0DB1B5C8E31B3CBC95C721B0AE3C94CC1774E64D3C679637F29CD827D
              3FADC075532FD036C0E5EC8232CAE596C85C328566C1C6E359B471120E94D1FE
              D1DA27350BBE5591491B67674639AD8DBF7D52B3E0E96319B44AFFCD218C8CCA
              E302133ACF8A450BC33953493C5841F32FEFE35AFA767EB8D685D4C23ABFFBA4
              66C153A5E9B44AFFC030461D72F60333CF1682450BC23853D99D5D4903DF7C54
              437BB36A430ACDBF511FFBA466C186A3FB69E324E59CA081AF3FACA6BD59FD6A
              2ACD823EF64985F264A6607D89FA40A324E755D3C057AD55B437CF6C4AA3A520
              F7494476CFDA27B50BD61E4EA18DB3EF500D0D5C7E5F3D939E3CFB9A7AA57889
              3D3772ED8235457B69958121071C4E39EB81B1592D58106EE34C25A5A08E062E
              B554D2DEACD99C4EEB285855904CAB0C0EB3E098BCB102630B312322EC56C1B4
              A27A9AEFCD73C7696F9EDB7280D651B0323F89364E7A71030D7C7156DD6E3C79
              616B06ADA36045DE1EDA3819252769E0F3E672DA9B17E332691D05CB731369E3
              641E394D039FBD7B8CF666DDB683B48E8265D9BB689561C738C6C7A73E1EBDB0
              581484D92C9CF926ABF44D1AF8B4C9F767F24BF159B48E8247B376D02A230E17
              C65D7E0A9A1584DACC9CF926A7EC6D1A387FC677C197B767D1C1179CF9C25A92
              99401B27AFBC91063E692CA5BD7925219BD6513061E31A3CB8643167FAE9EEFD
              1D8D1F5CC2FC79A168AA3FC423DEACDF9143DF41C1E8D86D179CDC9E389F3356
              AD58863DDBD773E6CD869DB974F0052D7862EDFDD1A67BCF4051963B4D98CF63
              865819BB0C711B9F4778582857DE6C4CCCA3832F6862ACC0530B80A17BB0343C
              0C5D7D2188E177C7C908C6A244453ED2C6FBA0F5D461DA389B76AB973ED88272
              4C4A863036C6023CCDB58BC7AD1C1DE6A8D8183B8FA3E564316D9CCD7BF2E9E0
              0B0A725C629A8E206B4908DF44031C71AEA18836CE96A402FACE0ABA91DB256E
              642E054738E26C7D21E682ADC98510F4149C8DDC5722054739A2B94E7DE54689
              DB5B44B360905F58B590CB3D53B03873171E88BE8F33FDFCDCD58DD2BA66585D
              18B277B4AF0CE62BBF1652D0F27FEC9356E7C497F6C15FB2D075A597CB4146CE
              A0CF1F4D5AC8FDCDEE7DD2695656736D18ABD375D93EF64705AEF6F504F3B333
              1072166FED930F0F85E37A9405317D7AFE2DA093FF83B034720C5DC34340C40D
              5E5E397BBC40FE7FB807421E2325A7F7C9951CF979A31BF3A49A5096BAC84C5D
              5A29C763EA93E9411E2791621241D67A982A42A49444D69229FE03DAC75147C9
              1CC2750000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\09_Paste'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000054849444154789CB5987B50546518C69F5D36EE8218322AEB051BF48F
              72C6D114B47126C7BC34A5E9E4DD14D41C0DB334C95B656096162996693AA989
              57BC3452D9905AD1D48C08688343E38C3096D8AE2220BA2C2CB0B0BB3DEFEE2C
              64EEC22E87F39B799E7DDFEF1CF63CFB7D7B0E7B8E065D83BC8F484BB971FC4F
              9D42DE5409F2F7D49430FD88C89C66ADB6803DEC0E9BA92AE0C111E49FAD666B
              A3EC948414F905DFBCD3C86C69316646943EA25F416068485CF080380E01BAE0
              60D4FC51FC97C1689C84E2637738D44CB9838A7C464375066DDF51C9C90E876D
              1ACB277B8C9F10179990C0E1364C8585A8399F7BCB64D3DC0E76D88F565D3E72
              1080956AA17C0EA9A1FC45AB1F357FA1D5A1DD171D19D112ACD3E95A863D0D4F
              0175578AD0D4D26CAB329903606B49AD2C32EE077EADE7661BE553487F03CAFE
              01B189497991911189DB37BDA1ABAF6F4046D677B0F41F8896C6466E762D7150
              F90D6C58341521AC535233ECD6C686DF0C45D792802BF7B88BEC28011D54BBC8
              013B42F61109F21AD03731F9972706F67D6675CA5CB680C5D288FCCB25B03434
              B103424382307AE410673861DBEE63B876E3EFE2CA82AB738092BB1C72CFA23B
              A0BC8A1E410EE80DD926729D0CAE5A14A04F5878212E2E76D4AAA533D9764CE6
              DE93B87EB3FC6A654D41124AA32A80823A0EBB038A643645528B5A91037A4283
              710B7AE8CDDA4C681D53AC4024C71E62F080582C5F3C9D55C7ECDA7F9A018DAC
              1EE5311BB28D685A83A2EC2AB672B6BB833AF11650CB65CC698263326B8FC4F7
              EB8365C9535975CC9E833928BB759B9567026DB63386A2F2A5C0EF66B69C0F67
              4827DE02EA621293E4D36047DA0A0C7D2A9E551BAB377E8E72E35DA4A6F02BE5
              039B33B3307CC820A4AF5DC2AE8DE23FCBB0326D2702EDF63A4361C930A037BF
              9FB9166E722FBFD780810CD8C457E49DFA8CFE30E7F20AB0955FFCF0E020C4F4
              8CE288776A6BEB516D32631D4FA889631FBE14096367BC49072A6BF287A2B4D4
              C052665126C7B7803F9FDC417F94F379854EF9C284B1239DF2C4B8992BE90C78
              E9D20820A69CCB6C62DB7A31D7509E680DF8D3894CBA7A3C376B155D02E6737A
              A36F02174D70CD60BB018318502EA6B890AD6EC0F1B357D119B086014B3B11F0
              DCF1ED74F59838E72DBA82803F1EDB46578F497357D31504CC3DFA295D3D9E9F
              974A5710F087C31974F57861FEDB740501CF1EFA84AE1E2F2E58435710F0FBAC
              B680E5C64A3CA8B5B0EA3CDD2342D13F3686958BC9496BE80A027E7BF063BA8B
              5BC62A98CCF5AC3A4F64B730F48BEDC9CAC54BC96BE90A02E67CBD95AE1E5317
              AEA32B0878E6C016BA7A4C5BB49EAE20E037FB3FA2ABC7CB8B37D015043CBDAF
              2DA0E14E35CC750DAC7CA75B7808F4BDA3597966FAAB0A039EFAEA43BA0B63C5
              3DD4D65958F94E447828627B3DCECA333396BC435710F0C4DECD74F598B5F45D
              BA8280D97B3EA0ABC7EC65EFD115043CFEE526BA7ACC796D235D41C0A3BBD3E9
              2E2A2AEFA3CED2FE49121E1A825E3151AC7C635ECAFB7405018FEC4AA7BBA8A8
              BA0F7992D01E61610CD8C17DCA7F7965B9C28087BF48839ACC7F3D0D82BF015B
              EF49B276BA3EA15A24AD48A733A09FF724AD01D7AF5880C1F103A006D7CB6E62
              CBCE43BC7147BDA1E8D2B37EDDD5E9139372ACFCC1CB5A7502ADF67306F38D75
              28BBF80F5B332533E8A0BC06D461F8E43E7A6DD401683409562DC239A60A8156
              DB79437345064AAACBFD79B2A0A50281D1117C52D61DF161A128AB7E8C631A0C
              A27715A50C111FDD8C324B3DFF6B3FE0F2CAEC71E15CCB2B780B28E312524205
              513A600C7B9B8C7721019C25510843E552CEA595701C73D1DE01659B88C19C12
              A4EF4ADC412494487A512BFF021AF58E471CFDA83D0000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Project\10_Edit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000038849444154789CED985B4853711CC77F9BDBCC99E0A516B963D2650F
              5D0831C291968260B7B7C044D212B27A3108228A30B4F2257A11B297ECAD97EA
              A1171F222FA084B4298AF71B6633CFBC6C6C6E6E737373AEDF6F3669B48B733B
              873DF8812FE77FFE17FE1FF6DF7FE77F2680386757305A7605A3854F419A8B22
              C4101B18CFDF048506F081108ACAD31987641CCBC0BA8C67A0AF458F45178644
              2901E1435008E74B33189774D2099086F7200130B336A312865BB478EBC0B831
              0125B916F4C98DA1DCBEBC9C135805A01E18DB94B4E8CEC1E8D739AC0A2AC9A5
              A0574EE692B663F93406F2724E42D9B512F8F4E55B20493B8624FDBE935C09FA
              C929B20E825C7E003A550381249759D5F42980EE65ECBB8621418A172E04FF93
              7BF1F41E489392E04DF36768EFEEF34A12EA81519078042656DDAF04185AC4AA
              55CC3A8633C1A0721E8FC79BC6771FA14B3588CDB859DC020BEB9C2D85418386
              0FC1B072D6553BD4BD6A8699B9055C5A81999D9BBD01C95A16A6F6EBB95EE288
              E4C0BD31A35B60EF8354AB85A934032EB609C739309C6C929DC9A5EA59184941
              B91F2B38CE2717F39F194EE5886804A39533E338FACE059523762AC88B1CB113
              41DEE4884805799523221114E0912943E690746099173962BB82D44FC8286F69
              F054C2F02547D0C4DB4108C5378F310EF188D3BD2E561CCA84E74FEEA2E01E4E
              E588ED08521F61565ED5DB94C2824B19178AB2271B5E82222B13EA1E577B7FF6
              B9922368F270609FD26446996C385C5B8BA7A34D48F2082E35C1951C81938784
              DA053265C5B3BDB967ABE557AE3278BF05497AF1CA696B2055A78DA51C4102A1
              A07611935F65C87EF03045889B8270CC6AC0D0DA66739ACD22A7CDC6EAD6E66B
              C0890FFE8934632CE508120805EEDCCADB12C5F10679D975994DA301535BABD5
              6A362D098CBAA625DB700FFC14A38C08CF71897822E9B3E018BC8F8D1C114A90
              DA1298FC3BD3E9972F665B7B7B2C28B6E8D1EA9BF4F05B0D09B65598905801D2
              F15DA293A4E8A14FAF9124477B2726904430844C6E45392427BE5F4B10FF4A5C
              3134B2FD43FD588D228928966203F88EE52D29FAC428319323420A1E2DA828B1
              AF8BC4F3AADE715C46FC47408442523B8A61FCC47C52BE6BCC0825486D22CC1E
              8C044322F820F1BE33FC2B46E10C9208057E6A9080A12B095148C817CE092748
              501F8A4FC877E5059A38AEF1137CFDA1A31EAB0A81173C5D8F2A8BEB210C8104
              8B80173C9D110BC623712FF807317AAF47338DE3950000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Project\11_AddExtension'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000048D49444154789CED976D50545518C79F7BAFDC5D5E826A90F7A6D492
              3E949A2F2CA9A0D34C9459014E0DE24BBB084435D30C5A9A1AA00819BDCA4C8D
              D590B5C4805A665059A6D3805A08BD104D7C326D981206D0301C16D885BDA7FF
              412F2D3BBBCEBA1CAC0FFD669EFF3DE7DC9DBDBF7DEED99DBB12FDC7F95F70A2
              78139451FC9C7ED4711DFB0243E9F0B186D28F3EE17E413E97A62F5E77CF39BB
              B3284CA1590EA230ACF98D4AD4D7E7A4B6D0297259C7C9F7EBB1348C1A41B1CB
              7545B8902BF2B44473B18DA80063E18438B5F2DFBEAFDA81E1008A8B72415E5E
              71159479E7FA479C47438C81ECE9EC15D2A2843B29243808A726C657F5CDF4C6
              9E83AC7F6850521D436BCEB6ECFF02CBE8C36827AF78BB5D0595D84473033ED6
              E2928DD9B428611696C471049265BB6B30A2969EA6B674A21FFFC47808C505BD
              76D15530202ED17C8EEFB9AF3F2CC7542CFDB6414ACDDA42AAA6F59FFDAEC544
              34B593A841EFA24F826A44A2D98E231DDDB70B299E7B57AE4712F59CFF761E9D
              8EFB1D821731E582BC8B1EF1287864EFEB48F1A4646E4042B0E9D704ECA876A2
              137DE48FE0E19AD790E2B97FD5334808F69E34D1A9F076A2462E886DEF9BA001
              827CD3D297D5AF22C5B36CF5B348018287AA5E418A67F9DA8D4801829F7FF032
              523C0F3EB6092940F0D3CA9790E279D8FC1C5280609DB50C299E54CB66A400C1
              4FDE9B1CC1F4759B9102040FEE7911299E15D95B9002040FBCBB13299E4772B6
              2205087E54F102523C8FE63E8F1420B8FF9D52A47832F20A900204F7BD5D8214
              CFCA270A9102046BDEDA8114CFAA278B90FE0B8E3D2C54EF2E468A67F553DB90
              13108C4BB4E081958556BDB99D4433303044799BCA487592ED62CF85BCA0A9A1
              B365458E87824692D42AC954D7D1686DC54BC7E12E580FC185F939193477F6ED
              5812C7374DAD54515D4712A33E5C340C4B64888C4412D9BBBB91A332B56AA094
              D5DE60FD0BD351B0364640ECDD59F70D33EDB310A38165AF4993E26FBB998202
              8D3835311A9B7FA69A8F0FB341FBB0449A46E1292914663251526430CEE2B1B5
              DB46178E1DA3DEE3C74992E55F54034BD6255D05159471FA82B5A5FD8A9C8FB1
              506414BA4737E5E6921A158519C496CF4012251D3A8324727475D11F15155CAA
              B6B3B9321D4B7C3C067F8F29A8E0B8B9190F3854E306EC97788742973EA69FE0
              3D6C230AEB90983453EF9C8EBB2047EFA4AC4877F13DE92AC8E19201A820A279
              D7E15F6108DD6A37D2E90885669E777FAD6F9C0A6711F363731425E8F1198585
              58F8074F829C332525F8DE48C59D4DD6EDEE17E5735EBC93105D8AE26327D678
              F983C2A2174CAB3444472DCB2C5C4F3BE75FBABDDED8FA4317ED2DD9458EEE9E
              BACE666B9AA78BF235BD7847F991A31FAF161693603EA046473D945990EF9B60
              6939F663B757411DFD9C7EF49B1893791BBE1F45226EF1A410BBD0324773B29F
              447C49268D1893A596114BF5ED67461ABDBD58C2F81A71CB52CBF5C376E984A6
              6977DCB86409DD909C3CFE871A5DEB45F764596E0B30B0A4760F3FD4930E9774
              0C9295771253325CEEA41D9DE3F0CEA98164D1E538D7545087EF49A6511A319A
              8329B7E00F0BB57CCF61368E7F45F06AF81B272625473AAE91CD000000004945
              4E44AE426082}
          end>
      end
      item
        Name = 'Project\12_DeleteExtension'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000046749444154789CED976D50545518C79F7B2F2CCBB2421F849980A614
              943E949A266C6A8D5363656F80D560A0EE2214E54C3366695A86A056F4EE4C8D
              E598B5C8B06999B1BD9A8C033316424D44139F141DA6643F80BD400BEC2EBB7B
              FA3FE4A57567A17539581FFACD3CFF7BCEB93B7B7F3C7BF6EE45A1FF38FF0B4E
              96F10455149FD38F3AA1E36810281D1E0751FA312AC22FC87365E692B537F779
              0395291ACDF111A5602D660C44FDFD01EA4C8E536B7A4EBCDB84A511941F25CE
              D784B05028EA0C8BB57A90682BC6D2310782BBCE7C5BB71DC321148BB220D7B8
              840AAADC39B73FD06836268A47CB56288B73AF25739209A726C7974D6DF4FABE
              C3C2ED19560C3ECFAAB3ED073FC732FA30DAC9093FEE50412DC3626DC69FB564
              C7C6325A9C3B074BF2380AC99ADD0E8CA8BDB7B5B390E8BB5F30F6A05870DC2E
              860AC6675AAC7DBCE78EBDBF0B53B9B8078729BF740B198241F7D96FDAF38852
              5D44CD7A17A31234A459AC5E1CA9F1C06B48F92C5BF91892A8F7DCD70BA82BF3
              27080E60CA82DCC58844143CFADEAB48F9DCFAC00624045B4FE5624775131DEF
              A758048F385E41CAE7F6E2C79110FCF5441E9D9CDE4DD4C282D8F6D109264090
              372D7D51FF32523ECB4B9E404A10FCACEE25A47CEE5CBD112941F0D3FD2F22E5
              73D79A4D4809821FD7BE8094CF3DD6279112049DF61AA47CF26D9B9112043F7A
              676A040BD76E464A103CBCEF79A47C56946D414A103CF4F67348F9DC57FE1452
              82E0077B9F45CAE7FE079F464A103CB86727523E45155B9112040FBCB503299F
              950F3F839420E878733B523EC58F542263171C7B58A8DF5D8D944FC9BA6DC849
              08665A6C786015C9756F54916C86863C54B1A9860C011A1CE8FDADC2949A3C57
              D5D41C280449513A14959C3D2DF60EBCF402C2059B20B8687D7911CD9F7B3596
              E4F1556B07EDAD779222A81F174DC1126569DC3CA2D38178E4A84C83215129ED
              6EB6FF8EE928581B233EE386D2DB4644F013B3314194AD2A5072665D49A64423
              4E4D8E96B61FC8F1E111E1F57895A0205A671CA07B0D6E9CF99B5AEF34DA8FD2
              14FA31CEA8DCA44B860A6A28E3CC85AB77BA35753DC6525151E81EED31F751B6
              FA57E7C2E90AC653853B95A51A5C6DB58558E2F118FC1E71A8A4CCF94577F80C
              C60DD82F393E8D92B01633788F41BF267A14A1CC8ED4B970F44EAA9A721DEFC9
              5041862579439888164CC37F8566CAF61AA92B4DA3D9E7C25F1B1D27A78BB4EB
              33CA35CDF4D0B1641716FE995B06D2F1BD51AA5DADF6AAF08BF29C8B3B09D1A5
              281E07B0C6150B9AB87CE18CDAAC78FF72C7B259744555154DC4CF385FDC788A
              CE040C4E579BBD20D245794D2FEE281F19FD78B188F45CEBA1ACB891BBEBA314
              2C81E0E9090475F473FA3166D2F3ACDBF0FDA894F1114F09198B6CF38201F1BD
              8C2FC994919E676B1024F2A3BBCD28A31F2F9630BE445CB5D47699DF238E0704
              5D634DF883D6A042E1AE71F770A3EEC48DFAC64837EA2987257DC364E74E624A
              D9E77FEABAC67EEA14A721916CBA1C73490575784F8A201590A07998B2053F2C
              34F09EC3EC02FE15C18BE14F456A0B4776A5D8CF0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_layer'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000046F49444154789CED97514C55751CC7BFE71CEEE55EB0104C404084CC
              410F6E342BAC2BC843B3AD28743E245B138CD1D8EA218DE51632C7405DC5CAB6
              726E94619B6BCD3278E8A18716E06A811630EF1426E83504EEBD281A83F05E2E
              F7F4FD5FBA7A22AE01E71CF4C1CFF63D67BFDFB970BEFB9DF3FFDEFF95709FF3
              C0A05EEE99C1D4674B73D4208AA0AA392CE944EA9264340FFED2D8C5EA364B6E
              30A3A074B97F52FD4205B6B2447452128F80CFE3E13164A8C96A9776B95A1A6F
              B214F5D21132E793DAD46070FD235BB6202E37177949B1BC029CF64CE0466B2B
              46DBDA20C9F2396BB49A2F4CCE6550A6443F2CC348C9DD79528554B4BABC1CD6
              E4647668ECC5B53C0279DFF7F308F8DD6E0C3434881B370DB51FDFC6B386E7CB
              12D2C6FCDB24552EBA19443CF8DFD835044542AC5D424E787261661B14842729
              2BD2135A0372E25325BBA1A03E2B3D15CB96D9D9320EF7C828DCDE51ACADAE66
              7587B90C0AFA6B6BB96EA41AAD41257563494B467ACAA64FDEAB64692CB5F5C7
              F0FBC0088AAB77E3E093338F3712EF9E75E3ABDA8FE0F7789BB5062DAB3796FE
              949D95E9A8ABAA60692C870E1F47D7E07514EF7B6B7E06EB0EF37DF4FCD7E0BA
              AC0C47CD3BE52C8DE564F38F21E979C43306D7AD7154BD5DC6D258AE0C0CA3AA
              EE0812F2F311BF79333B33CC6530D222B1ACDCB0AB52B2040F3E9A9A0C9BDDC6
              96B1F4F4B920A9C0FC62466A1E6A6FDCAA35A8E099C2E4C4C0C3C55628857E59
              8D1333665FC80854E9D654876C8B7E8EF19599C029C6739AFF0A6A4E6D94D393
              65D9698956F35CB3825A04B485E25FAC5F8EECA958040216F445F1332AA593C7
              A683B0D902319E04252E734D1DBF2E5E6017D1FF4CD2C7C909C4E4AC76940A73
              2C59DF414241F18A449FB2DDAAA2E8CF69399ECF437B5D37F629FCE00D8E9F40
              F77743AB9EDE912DC9B6424E338797C4DDC566A1E96E9B0511D47BF8A03F10EF
              608C09EFA093EF208281BDDE8E139F0198A0A6A8201511ADC15050A7A4266DAA
              A92C63693CFBEB3FC7F01FC3AD57CF384B80CE6B6CDDA28441959A13ADC150CC
              6464A439F654BCC2D2783E3CFA357A2FBBBABCEDDDC5C0B961B6FEA202D4420C
              A638DE786D3B4BE3F9F4D8B7E8750D747B7F3DFB2A706190AD712A40CDDF607A
              FA2AC7EB3B5F66693C1F377C8391A16B3F0F9CE9A85894C17050A7AD5C01BBCD
              CA96B15CE4B789E49B3CE4E9BCF0E5621EB1F9413DE93FED19779F42FFD8A5C5
              2C1299B250A606359C225E9C37D8E1796131232D6550B314D39BA6224E4FA035
              703BA8CDD8510B7E3BDFC779E90C6AB376D48237F7D6E3CAE5ABFA82DAAC1DB5
              60DF81A3E8EEB9A82FA8CDDA510BF6BFDF00676FBFBEA0366B472DA83A700483
              AE61FD412D763366ECA8CFF7B98C08EAB81D56C82F6982DA30A4095F9B6772E8
              14FA262F714D5F676B418B44A6A22806F58687F8EB20068F07A2A028A2CFD2AF
              FDECC2B032590301153D519C968553EB1C6357C40CEB90C188CCBEA930234C5A
              287156280329A0991661CA4F89B3989C5044661B147558C2AC19D064C8545877
              4518998B487DA3F85F6361CC36A29B0706F5F237B0850937E3D4584B00000000
              49454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_period'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000033E49444154789CED975D48536118C79FB3B38D6D7DF885CB391B4B14
              358A02898C79B1AE82504CEA226F9A257D5C09C9A0BCE893D020C910EAC222B0
              F0269282F2A22B57D68549D84896E148C58FE54765E2D2CDB39DFEE7B0C9B46D
              4D770C85FDE0E1F579DEB1F3C3F3EEBF3386D63909C1784908C6CB861494A184
              79B0A4C68FE251C2FA4F960A1CAA4ACD9AF19633BCAC6CDA4F29789BA5FB71A2
              22E6E5A47CEA71A63FB51D6FBD07231157574BC4EB846EC8B4FB2CE789A5863C
              839E349BD518494B8FC349E4E3AC2CC35612C3ECA200B10AB2FA228BCD68C82C
              6EAAAF412B3DD5B5B7696860C436D2EDB0107DF8AEDB6F99C5386641C5F6A2CA
              8EFCBC1DA66B17CFA0959E2B379BC9DED7FF71A2CB5E41F4C905C1698C572698
              9B6B345DB256A1959EDA1B776974D0F56EB8BBFB2C91630C823F308E5D30BDF0
              A49551F8EBB2F519A452AB30921687739018CF5CFD78CFE747ABF90FB274A024
              43CB6DAD50125BE295F14938C8C2BE5052C03373DECE71F7681B39E7BEAEE60C
              CA500AD426A2DDC994BFB089384E414E395EC3A3E224C7E727958AA35E7213F5
              FEC4C40DC179AC310B3264AE48D37AD8A34A9ECA7EF96429C4482016827A815E
              4DF8675BC9FE6C0CED3C0417B02E0A9ADB07F672BCAF9161A8056D19CF533283
              3F82083958831B7D2B5BBF8D346B70067B9D43F8FEE02E4CBC6F7D807616821E
              AC8B82C52FFACD38561DB863769CAE3B10BC2A6E0410733053A72DBE6C3D8556
              7AAE373C24D7C8B7D7C8C113E1CE605090915179E7E19CE7E897088A31633466
              99AA4F1F432B3D4DF79FD29781C188390821519078FEE0DBD25C1BFABF050D06
              9DE99CE5085AE9696C7E4293635311731042D105833998959E466A95122369E9
              1F7645CD410845154CE4E086CFC170846E2CE6E09A3E0F46C9C170846E8839F8
              1F9E0723E660384237C498493C0FAEF7E7419EDC7572BFA61C1156809148AC82
              811C4C3AAE245969480E4A06E3F6BC1997BBDA748AEC7BB8F24E8C4462151472
              508E420E166E21F26AA8809313CB0A73B4DED0D7AE0C25828BE378EA9373B851
              BFF1799EC1147948E8A3FF3E5E7E5141469014025B5859948498216313A4BC28
              61E5031591E582421F2C41762D80A42815ACA80822EB9A8460BC2404E3252118
              2F7F006C96CD97CD683C010000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_row_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000041249444154789CED986D6C53551CC69F7B6FDB75D0654CEC98742D73
              4A867E2544B47CF09B5FA68BAF41304C5C40A6D1886EF105C28B9117334C8C06
              A7202668301A7589C9BE33892FC1A965B1E998EC8DB68CB5DDE2C6DA75ED6E7B
              7DCECA16B641D7EBF40E92FD92FF3DE7F9B7699F9C7BEFF99F7324DCE4DCB206
              6F94370A8D31C14C23424F86CC5808D20C617022849149243C5453547A25F9A8
              A4C955436914F12BD77EFEBF6385D41C310D7C815F9A23942A639A41B9785DF5
              4E283852E172C066CB67CA587EF7750229B52EDC7AEA33CA18439D34285AD9B1
              BEBAA5CCB5724363433DA5F1D4D637E0624FF08760AB6F0BED0E3235268C0944
              6B72AE7FF6F4BD6BCADD87F6BC40693C6FBEFD113CED7F9D0B9F6D7B1AF8F332
              53A3C29840B41306D754DCE93EB06B07A5F1EC3AF031DA3A3ADBC2C3BF3D83F6
              F63EA64684318168A70CEE7F633BA5F1EC3D7C2C6330EAD902AF37C8D46C83AB
              2BCADCFBEAB7511ACFBE86E3F07674CD6170F52AF7EED76A288DE79DF74EC07B
              A13BBBC1BBEE5EE57E6BE7564AE3D973B01197FCFD3F05A2BFEEB8EE33685FBB
              B54E32A70F963B4A60CDB732652CBECE5E4889D1C321CFF993C0F27EA0252631
              2F10AD82FB2B57148F176CB2484A6552910A99635E621881A62195F831AC5E6E
              8267A40B3837C064FCDA3F9771DF2376BBB6ECA93C2D5D3504A54846CAD07A9C
              87F196C8DFA1AFD119EF01CE0E33959C6690A5EE558E6383B8C54BFEC52DD696
              DA78E598C7A2BCEAC72B6E71726C77E88FDE4F671A14ADC25277DAE958B161FF
              EBDB29F53194023E14C589BCB41C58A6B0A393BDEF1E43D0DF7726D8EAAD9E79
              8B459B798BCB9DEEBA173753EAC33F2EE1CB68C6D5265B0A2EB3C69E3E8E1C3D
              055F57CFD55237FB25C9182C2B75BF52BB91323702AA8C9F932624E8279CCE3C
              B2C5721A79FCC5072C2A9CA63433B9F17EE357F0F55ECC5EEACA68F0E56D4F50
              E6C677897C04D399919B49A99CC2E37971F672E383E3DFA24318CC365173B9E5
              AEAD798C32372E6926B4A6AC48F22706B48CD1DBA5142C5CEDAE53C6E0905466
              72A3F144133AFC81EC065DAE3BDCCF575751EAA30F66346B85EC0195D2305662
              9C3D7D7C72F27B5CF007E730E82C713FB7B992521F51CE4FDF98ECEC014FAA11
              D8C0D75A2747398291FEC1B94B5DA9FD3658AC16A6F421D90A78E57C181DE155
              3FDD81FEC552372F722E750BB9AB9BB3D4719A59E05D5D207BA9BB797675B35F
              92098362D3B4B8ABBB018BBBBAF9B2B8AB9B2F995D5DFC50C8D3FEF9F5CE6664
              96BA9262B570A305F2C349994B13C9A83297418A25CE84E27D4DAC24DD9CB607
              999A3ADD12C80C136329B0B68093F812DCA39AA028224F3935A9FFF7582C1A54
              55C379930A984701CF1566638CA9F34181E88B1026CD0CD12A0C037930CDC999
              26B9FEA539C6B4135681D093911939E3A1492EC7AFC63F5DB33CD0D11864FD00
              00000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_cut_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000075549444154789CED58696C5455143EEFBDE94C3BB41497D6928EA2B8
              806C2A521809D5C61F1A63D85C6280362D1891C51863042B92B0B82121110413
              6455444CA3EC014944686264EB0EA502D3C14287D2CEB4035DA633F366E63DBF
              F3E843693B65A613D118BFE4CBBBE7CE3DF77CEF9C7BDFBDAD40FF72FC2F3056
              FCA7040AC387CFB84F5164F1F4E9AD17602B1D54C148200C1B963BD0600888E5
              E5DB6A882804B22F332C04301268E21AFA84EC46A26683BF7D624DD9F7C5E897
              410EC4427B82386874CEC82BA258C4FEFDDAD4272B2BB79C43BF0CB24066B788
              54A0387468F640579264439B10A425BED1F76C757541154C2FD893484D9C4714
              0F424D326C32D7B764D5D4EC3C89661BD8936FE4024143CAA8A9330543DC6AB4
              490829671ABCEE17A8729F03A60F0C829D332150E6CB77A606CC07D11E012267
              DE25CED2AA02A24A27AC563008C62C90C7496042BA357B5580A4E9689337A414
              B516554D242A6981E907391BBA4801949232720F2548948936C585020597AE9C
              584ED5896EA2F22674E9D9D77DBA802789149CC53830D19291BD5E96A4C96893
              3114DAE928B2CD263ACE2251C5EBD9102DA3F336CBA29A83361983EA3E47F1F1
              C578C766888340ADBC01501FDF2DA211C86359A491864E48BFCB9CBC5795C4C1
              B0490DC9EFB98A2E6F202AD48392C59A334326711D9AC8916A73BAEB6791FD72
              1D51BF26A25F789C0CB2B8B0D96370D068C0E3B9D4467A64B2C562EA5B228B94
              089B8C4A709AE3C4B707D0F4A667648F0F485201DAE8A73647E0FC242A6BAA27
              4A85B8423DD321B047710C0E182DD88745C6DFF7C82B6303A6F8ED2CD218525A
              D5806F4A82C1E4F119A45D5090CCE2D440EB9C4B8173155499047147515E6D43
              45248EC1C17A032E35443E97909A71FB6B241956C02623513D66546595FAC384
              02EF87AE26C776B2F9B1E652AF12FDA86F0A2E6D44E8AD40068B34807D521E9F
              F6769F07EE5F98367E024CA8DCBB87BCF633AB1B8A2BB640B69BE8D415747BC0
              2018B138462C02D99789C465263DB16D659DD437990553A8B5257874E1CC2CB2
              FB51566D53F0F70E554752AF31627080582082D2C08C9CA569F9EFE68BA67898
              48537333D957AE58E52AAAFC1CD983406A07A32AAD8E5804B2AFA87F4ECC0306
              50FF89932042A5CBBB774BED172E901A9017B84A1C1BFEA90C8A0F8DCD7BBC5D
              517F42646DC70AC19637159C818274DB9AEB3B5BF64EBD54F1C3AF187F4BD7A0
              8833F60E4BC06C6371B09117CF5C6753F931AA367BD21F1B323A60326D412FB1
              48479B7B2CFDA65CBC55BB58A0AC2977A4FA8C3FA33D02448FF703A7AB7427C4
              E153723B97935247F59F4E06E37234214939EBF4BA27E362510BEB6FFD0EF278
              E96E6BEE0E3FD178B471C68670C6162FC21707E22AAFA08BB3C448B064E4E0CC
              165F401BE3945D8EE2DAD94485FC02708F4C24078C043C8E295A9EC85D890FF1
              5CB419A5CE63B65938F75B90B92604E733563B8B8138A2AC448B75C07E2C830C
              D86452435B6A8F9F9F47748445F23816C9082B9483DE0C3C862959C6E44C9705
              F14BB431352E00BEBA3974AAEE320ACAE22052CB8CBEBE44D0C46776AA31710F
              49E220D81D170BC746EC6C0F4C5D240B64760107EE09FC3BB2969347AAF8BA9E
              0920444260ADF368E96654B291280DA5EDB20158A0C4C7618A35753E26CABF66
              036AA85C5584CDAEA2C6AFE0C72FA5EF6E15BC01F00B0B6D3324798C3BF40B67
              67E0C25AD2DAE6CEFBCB0EE5407A10ED369DE437EF4810691CEC2EF02ACAF156
              4F73369DDE530713EFAFBDA0EEAF219C40EE17711B3ECCE232470DA7C9CF3F45
              4989663227C45383CB4DDF141CA0B233D52C52BF55F34D85B3C1996044E15F3B
              A1D312B92E928574079C10D93821A4F5992387D1C27933D0D515F94BBE40103B
              09B2FFFD86D2FA7508A22F7E5C5863F267911AC20994D2ADB98518396ED98259
              347CC8FDE8EA8A535576CAFF782D5A4A99F358C58B44275D307C20C1FF702FFD
              79A9B0402D8BE104C659ACB92E19A7C49EAF3F85D93D3CED5E9A327B316ECD4A
              9BE3448995A88AD792074406739DBDF4E74F5510BC99C0BC4699D4BE3B367D02
              B37B70809C3796E238238FE3AA6D1CD98C8E8E3241601E0446EB7FA416DDEC8F
              E4DF5C6021028C5DF2CEAB3464D040747545D5D9F3B468C546B49493CE267B6E
              278187A2F78F4260CA98693305C1B066CCA30FD35BB3A6A2AB2B3EFA6C13559E
              FD9D047FFBB286B2D35B11924BA49518FEAFF5D23FA2124B6002B2807F57A863
              32460CA6679EB6D23DE9696436C7D3195B0DEDDC574855786A6FDF78EE75AAF6
              36742C721FC888EFEC3FF8C17BA9BDDD47172FD5F7E41FD12611C1381A36C962
              494CFE4EFEF304E9044CEE75CCA70A672D72E6EC282F9787118B3F0BD4104E20
              F7B348135156DFBB46A6CD508D712F1943E243E8235952EC82DFB7BFA1F5E26E
              AAE68B428A1B93E379FD43CB88C55FCB1E83858403FF268146043113B993B034
              CCF4603FDC5200DB55BCA9017F6BF0FDAF104F42A26E38AA62F5D7C093F404FE
              9D336100796226DB0C7E5304D11804D9BE617220567F6D829B81C7E8E4C9F9C9
              E0C9F4497576071EAF336A7F7D70240837B6DB89BB41AFFCFF00E4F6C756707D
              E3F00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_paste_lined_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000054849444154789CB5987B50546518C69F5D36EE8218322AEB051BF48F
              72C6D114B47126C7BC34A5E9E4DD14D41C0DB334C95B656096162996693AA989
              57BC3452D9905AD1D48C08688343E38C3096D8AE2220BA2C2CB0B0BB3DEFEE2C
              64EEC22E87F39B799E7DDFEF1CF63CFB7D7B0E7B8E065D83BC8F484BB971FC4F
              9D42DE5409F2F7D49430FD88C89C66ADB6803DEC0E9BA92AE0C111E49FAD666B
              A3EC948414F905DFBCD3C86C69316646943EA25F416068485CF080380E01BAE0
              60D4FC51FC97C1689C84E2637738D44CB9838A7C464375066DDF51C9C90E876D
              1ACB277B8C9F10179990C0E1364C8585A8399F7BCB64D3DC0E76D88F565D3E72
              1080956AA17C0EA9A1FC45AB1F357FA1D5A1DD171D19D112ACD3E95A863D0D4F
              0175578AD0D4D26CAB329903606B49AD2C32EE077EADE7661BE553487F03CAFE
              01B189497991911189DB37BDA1ABAF6F4046D677B0F41F8896C6466E762D7150
              F90D6C58341521AC535233ECD6C686DF0C45D792802BF7B88BEC28011D54BBC8
              013B42F61109F21AD03731F9972706F67D6675CA5CB680C5D288FCCB25B03434
              B103424382307AE410673861DBEE63B876E3EFE2CA82AB738092BB1C72CFA23B
              A0BC8A1E410EE80DD926729D0CAE5A14A04F5878212E2E76D4AAA533D9764CE6
              DE93B87EB3FC6A654D41124AA32A80823A0EBB038A643645528B5A91037A4283
              710B7AE8CDDA4C681D53AC4024C71E62F080582C5F3C9D55C7ECDA7F9A018DAC
              1EE5311BB28D685A83A2EC2AB672B6BB833AF11650CB65CC698263326B8FC4F7
              EB8365C9535975CC9E833928BB759B9567026DB63386A2F2A5C0EF66B69C0F67
              4827DE02EA621293E4D36047DA0A0C7D2A9E551BAB377E8E72E35DA4A6F02BE5
              039B33B3307CC820A4AF5DC2AE8DE23FCBB0326D2702EDF63A4361C930A037BF
              9FB9166E722FBFD780810CD8C457E49DFA8CFE30E7F20AB0955FFCF0E020C4F4
              8CE288776A6BEB516D32631D4FA889631FBE14096367BC49072A6BF287A2B4D4
              C052665126C7B7803F9FDC417F94F379854EF9C284B1239DF2C4B8992BE90C78
              E9D20820A69CCB6C62DB7A31D7509E680DF8D3894CBA7A3C376B155D02E6737A
              A36F02174D70CD60BB018318502EA6B890AD6EC0F1B357D119B086014B3B11F0
              DCF1ED74F59838E72DBA82803F1EDB46578F497357D31504CC3DFA295D3D9E9F
              974A5710F087C31974F57861FEDB740501CF1EFA84AE1E2F2E58435710F0FBAC
              B680E5C64A3CA8B5B0EA3CDD2342D13F3686958BC9496BE80A027E7BF063BA8B
              5BC62A98CCF5AC3A4F64B730F48BEDC9CAC54BC96BE90A02E67CBD95AE1E5317
              AEA32B0878E6C016BA7A4C5BB49EAE20E037FB3FA2ABC7CB8B37D015043CBDAF
              2DA0E14E35CC750DAC7CA75B7808F4BDA3597966FAAB0A039EFAEA43BA0B63C5
              3DD4D65958F94E447828627B3DCECA333396BC435710F0C4DECD74F598B5F45D
              BA8280D97B3EA0ABC7EC65EFD115043CFEE526BA7ACC796D235D41C0A3BBD3E9
              2E2A2AEFA3CED2FE49121E1A825E3151AC7C635ECAFB7405018FEC4AA7BBA8A8
              BA0F7992D01E61610CD8C17DCA7F7965B9C28087BF48839ACC7F3D0D82BF015B
              EF49B276BA3EA15A24AD48A733A09FF724AD01D7AF5880C1F103A006D7CB6E62
              CBCE43BC7147BDA1E8D2B37EDDD5E9139372ACFCC1CB5A7502ADF67306F38D75
              28BBF80F5B332533E8A0BC06D461F8E43E7A6DD401683409562DC239A60A8156
              DB79437345064AAACBFD79B2A0A50281D1117C52D61DF161A128AB7E8C631A0C
              A27715A50C111FDD8C324B3DFF6B3FE0F2CAEC71E15CCB2B780B28E312524205
              513A600C7B9B8C7721019C25510843E552CEA595701C73D1DE01659B88C19C12
              A4EF4ADC412494487A512BFF021AF58E471CFDA83D0000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Model\decrease_indent_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000042249444154789CED985F681C5518C5BF3B336E3669D104358849EBC6
              545AEA8B6D518B26657DB184149382FF9EDC2D8290A7FE417C10E9830F0A2AB5
              7D12046D45457C10534DC863861695364863D15A684A9A36A56DD242529A6DB3
              9D99DB73269925BBC9FE69B2B369A13F38F9EEF7ED65F6E4EECE615825F738F7
              ADC17CF34AA1219F5C23EC0319D072E04134E88B4602946C7DB7AEF17A7ABBD2
              46C7842775D832F7F5D0898AEA19B7AE7E2F7FF58CA375A02C8346FDF389DD62
              CA176B573748CDCA6A8C2ACB89534322AEF3FED8C08FDFA29D829CC020ABD1B0
              3961C7563FD972E0933D682BCFCE0FF7C9C8F0A83D3A702A21F2F7358C6ED118
              61B5566D4EF63FB336F6F2C71FBC87B6F2ECFDEC6BF9F7F4D0E0D8B1936F8B9C
              BC8CD1148D1156ABF185C4778F3CFAF09BEFBCB5CD5C511DC5A8B2ECFBEA279D
              4EDDF865F4F8E05E91C72E89D85906CDC61793AF8A657C9376DD27D0579C882B
              29ED4C755D3CF1FF9F22FF8D6194A231C24A55896CAA6D7C36F652DA92C775D4
              3331CB8F9B75932D1E5369FC95F163578E8B4CA444EAF1FDB327319A9EFB065C
              D35004C22DBC09D5B0104B9C2F40302F87491A34209CA1544D8BD8302969C8CD
              BD387B06348DB25284F35C306BC3EB7DA87168A9D830289403DD866036730A59
              704691A0CE4549EB1B75F5B76A12379574E0920BED591451CFEB1D37AEFF2003
              87C7D0D264D18FC77F7DCB6FA763028EBCB6EE9C608640DF8333FE7CC3FA3568
              CB47A1A0CECB96DEB33B3DADF763E384F29C8D30790181DEBF7E5D73CBA71F75
              6147F92814D4F388F70FD7BA29F7A0D6D28996473909831B607034AC402F14D4
              59C47B879F73B5FBAB1689C90C2396323BEDF6A67FB0CE047A57F275DE4C65A3
              505067083E522C7DB0E1B0B9C24CDAAF344DCCB4B381AEF5CF694356A22F1B08
              99BC41EDD3DA337410A796945994A8DD47B735EFC73280FB112D12414ED6AEDA
              F8F4D669D78B66027DB1C15D4A50B7FC7E262E4AF563E9A394EC38DABEE690CC
              474134542512AFC63550D3E819598B34586A50E304BBB1AB034B1F43A95D47DA
              9B0F60990B4F11A6C4821E82709D38B4146CBCB5500EC40C8459FFBFCEA6B5E7
              EC2E2DFA4B2C7D7092DD668DB9C39EF90E92CC93372ED739E91A759895859283
              9A77B1A3DD6E2C9F82E048CE99CADC8EBB78106D684FDE7715D47E0E4EB987F4
              EC478E8D41509F6F08E9C9FBAE823A20F8C8B1F1DE09EA5CE27DC33101765BD3
              08CAF2067511B87F26A84378F246C8140EEA12E07E464C84413DEFC93BCCA0CE
              A1D89C8660B2C2410DD807E2492D045F0B04636D501FD6716829D83028940331
              0361D6FFAF33640278D97EFA2812D4A10570A9140A6A5623AC002E954241CD6A
              8515C0A55228A8593301FCE0A78F3C2064F206352B55B5600057886241CD350D
              4520DCC2C57EFA28374150FF81A0969B10EBBC3767CF80A651568A701E3630E8
              0B267D7990BE036E81519F3AD670C10000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\delete_row_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000039749444154789CED986948545114C7CF7B6F9C6C350B9752A7C90AAB
              AF1115AF0F7D8BC092A2A28DACA4D28268515A69A3150B22282B33B0B0854288
              843E6A5284598DD2306AEEE3A48E4BAEE3323EE7F5BF8E8AEB8C605D0DFCC1E1
              DCFF9981F7E7BD79F7CCB9028D73FE5B83C3D579A122BA186884E99E10116381
              03C10C760533D283406B23BC031BED1B05550CAB779037BED2F7F37F8E270929
              D59A9A67F439A51A5241F43328FA2E0F3F4612DD0AD105D0B4699351E2CB3753
              0151A7125D9599F404D286507A0CB22C06AC0C4FD3EBE6AE8E8B8D81E44F544C
              2C95165B3E58324DBB61B716A536668CC1B22668E59ED4A58B83E5EBE70F41F2
              E7F4E5FB64C8F999559591BD9DE847054A2DCC1883E52E838B43E6CB57CF4642
              F2E7ECD507949D57905DD5F07517E5E494A3D4C48C3158EE3578E9D40148FE5C
              B8F1C869B0D9B09B8C460B4A830D2E0AD1CB1763F643F2E7626C3C19F30ADD18
              5C344F3E772202923F576E279031BFC8B5C1050BE7C9678EED85E4CFF96B71F4
              CB5CF9A9ACF94BE490BF419F657BA3050FC7B5E0007FF29CEC89125F4C052524
              B4B7DCB01A721389665712A5D904D4192C4BB42AD4CFB763FA0EAD2085DA25C1
              0B35D405040F54953ADB3F562915C964682A24CAAA41B1B5EFC5455AB1C1C747
              9DB97592EA08AB27C95BA44EAEFD781275A455D7595F51416B315146034AF67E
              06D1EA8EE33EC6B2473C650C1EB1913D627BDB39EBF792C7030DB22CA1D5A506
              05F8ADBE74F200247F2EDC7C44167379BA25D3183EF011B3EC7C8B8383E4E8C3
              3B21F973EB5E12990A8BBB5BDDE097C469501F281F8DDA06E91ABF772FC8A3FE
              3756EEE998398BACEB714D37DC897B49A69252D7AD4E0F8347F66F861C9EA9E6
              42D23F7F80D5C829D9114936DD02AC86E76EFC1BCA63065D6DD4F8BB2547456C
              82748DEEFD6BD236D661E51EFB0C6F32AFDB82956BE2129229CF5CE6DAA04E37
              473E181E06C99F87896F29DF6C716330C85FDEB73314923FF77007AB2B6BDDB7
              BA409F59A4F5D4A2C497A2B2CA8956372A46DCEAC672AA73DBEAB0CD8CF15457
              E6BAD58D9FA96EF04BD265900D4D1353DD304C4C75A36562AA1B2DCEA9AEF5BA
              D590F374A8B31911ADCEDF57F1DAA62571BD5D54BDD0E5589D1B82AD3DDDDA5A
              9E8C4E52846DBBDFE916434468105389964DC7263E8596281A92245687ECDDD4
              FF3E5AAD4A8AA252AE4621F268213234A26A43F49E0F32D89A0533E981605942
              70648D039B334C921DC172BF135606D33DE1BC73FC81491C3E77C71F6EBC18D0
              3D6134F00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\increase_indent_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000041549444154789CED984B6854571CC6FFF7DEE96412A526B40DA5463B
              69148BDDB495B6D29A326E2AC11423F4B5EA4C5B2864E583D245292EBA68A12D
              565705C1172AE24234909065AE6F344882F85A44A210511385286634E39C397E
              DF1DEF388FCCC364EE8D823FF872CEFF7F0F77BE3933E7CB650C79CE79610D16
              EBFB85861CF28DB0766542B3410AA2414734E262C8AA9F1A9AEE25D61ADA5C33
              9E92062CC9BEEE392131BAC702B7F7C8A9EE31944928C7A0D9F851748358F2EF
              9285F3A56E6E2D5AFE3270714844257F19EDDFB703E50494740D7234E72F8FDA
              E1856FADD8FAE74694FEB3EEB7CD726D78C41EE9BF1815397B07AD8734463806
              162C8FF52D5E12FEEC8F5F7F46E93F9BFEDE26E72F0F0D8E9E3EF79DC8B99B68
              4DD018E11868FA38BA7BDE6BAF7EF3FDB7EDD69CDA105AFEB2F9FFFD3A11BF7F
              70E4CCE02691D76F88D83906ADA64F625F48C0DC9E50EA4DD4BE135412D7C989
              CEEB03974E8A5C18452B4E6384235523B2ACBEE9BDF0A78980BCA143290BBDE2
              A89C43367D2C43E3AF8C9DBE7546643C2ED288EF9F7D17ADC9EC17E09C868210
              8EF0328C6600B1C4FE14B8FD6A98A44113C21E4ACDA4880D93928054FECD5933
              A069942345D8CF07BD365CEFC51881668A0D834225A14710CC66762107F628E2
              8ED918D2FA7543E3C3BAE80343D6E09653AD9916A154AA67CCBCB757FABB4651
              D264EEC713E91D0E0BB0DB9AAF4A9A9CEB4F3010E81BB1C7FF7CB07411CAEA51
              2AA81D734AA901EC71BD6918EB8FAE6ED98A763E5C6F21D0FB96BEDBB2E2AFDF
              3B51568F5241ED1A1CD422F3508A61C861ABCEFAC15ED93C8ED285EB3D0BF452
              41ED10E9197E3FA9D5614CDF86E8E6AA65586BEDD5CD8328095A4F03BD33F615
              0F53D52815D419227DC3F56A42EDD28203F084AC8F9CEBD381AEF58184297351
              570D844CD1A02EA0B5FBCA7A2DFA3F4C1DB070D7B1F6453F626A4241E464FD82
              0FDF5935A952A14CA04F37B82B0CEA025A7B86625ACB4E4CD368BDF2F8978B8F
              6046433522915ADC03630235236B9A069F21A8337CDE73655D4AEB2D983A6061
              1776B00353C25D84290940AF40B81C8166820D834225216620CC3AEF3A17E73B
              18573BB173AE1931C4D870ACBD650BA624F3E48DDB75DC5566037A55A17C50E3
              142BAD0EE16D8425CDB5806175649D62E2D99377C5418D5270A1CB9A63C5ECC2
              1CF4ECC9BBE2A0CEFB48B3E1FA590C6A981490F5BF381FAE9FDDA02E03D7A783
              DA83276F844CE5415D04AE67C40419D4054FDE3E0675B93E0DC1A4FF41CDDA15
              776A2A78CD158CB541BD9847A09960C3A05049881908B3CEBBCE9009E059FBE9
              A34C507B16C095522AA8397A16C095522AA8397A16C095522AA8396602F8E54F
              1F4540C8140D6A8E54CD9401EC13E5829A731A0A4238C2E57EFAA8366E509F40
              50CB038863C18BB36640D328478AB0EF3530E808261DA520FD18240D529FD81F
              120A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_copy_lined_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000051649444154789CCD987D4CD4751CC7DFBFBBE34E40B41C63D9B0D596
              ACFECB5A13DBDA9CAE660FDA6A9AA689242ACA5040047992275110441E875A61
              8449F4B0B456D36CB5B63661F14F9B6E15D88271AD27620AF1700707BD3FFC38
              C47BF8DDF9FBD1E66B7BBFBEDFEFEFEEBCF7FD7EDCF7EE54709713A8A0FB76F7
              A8974946708F41E3EF89E5B8C4341D41D67A70979A988EAC2541E1EB4915AC8E
              5B143D68AA8269729D1358C863860871A1F5373832D1D1FA3797638CBB68407C
              15342D898DBFE0C0E45ACEE70CABCB75DEDED193087C37C8255FF754C980F82A
              68898ADD26AF12F9A9F17834E621CEF4F363E7AF28AE6E827562E25FFBF7571F
              0716FF095C1CE64D2E26E05954184FAC2CE8E08896FA02DA389B938B68E0AFFE
              B6C7D0D969E77490919330C968A2309ECC147CAF369F36CEEBFB8A69166C6F7F
              1288EAE165BEC9E53833C168A2309ECC146CAEC9A38D13975242B3607FDB7274
              46760357A4A0FB0C4AFCE2ABA08D054739A2A92A97364E7CDA119A05FFB9168B
              AE881EE0DB1B5C8E31B3CBC95C721B0AE3C94CC1774E64D3C679637F29CD827D
              3FADC075532FD036C0E5EC8232CAE596C85C328566C1C6E359B471120E94D1FE
              D1DA27350BBE5591491B67674639AD8DBF7D52B3E0E96319B44AFFCD218C8CCA
              E302133ACF8A450BC33953493C5841F32FEFE35AFA767EB8D685D4C23ABFFBA4
              66C153A5E9B44AFFC030461D72F60333CF1682450BC23853D99D5D4903DF7C54
              437BB36A430ACDBF511FFBA466C186A3FB69E324E59CA081AF3FACA6BD59FD6A
              2ACD823EF64985F264A6607D89FA40A324E755D3C057AD55B437CF6C4AA3A520
              F7494476CFDA27B50BD61E4EA18DB3EF500D0D5C7E5F3D939E3CFB9A7AA57889
              3D3772ED8235457B69958121071C4E39EB81B1592D58106EE34C25A5A08E062E
              B554D2DEACD99C4EEB285855904CAB0C0EB3E098BCB102630B312322EC56C1B4
              A27A9AEFCD73C7696F9EDB7280D651B0323F89364E7A71030D7C7156DD6E3C79
              616B06ADA36045DE1EDA3819252769E0F3E672DA9B17E332691D05CB731369E3
              641E394D039FBD7B8CF666DDB683B48E8265D9BB689561C738C6C7A73E1EBDB0
              581484D92C9CF926ABF44D1AF8B4C9F767F24BF159B48E8247B376D02A230E17
              C65D7E0A9A1584DACC9CF926A7EC6D1A387FC677C197B767D1C1179CF9C25A92
              99401B27AFBC91063E692CA5BD7925219BD6513061E31A3CB8643167FAE9EEFD
              1D8D1F5CC2FC79A168AA3FC423DEACDF9143DF41C1E8D86D179CDC9E389F3356
              AD58863DDBD773E6CD869DB974F0052D7862EDFDD1A67BCF4051963B4D98CF63
              865819BB0C711B9F4778582857DE6C4CCCA3832F6862ACC0530B80A17BB0343C
              0C5D7D2188E177C7C908C6A244453ED2C6FBA0F5D461DA389B76AB973ED88272
              4C4A863036C6023CCDB58BC7AD1C1DE6A8D8183B8FA3E564316D9CCD7BF2E9E0
              0B0A725C629A8E206B4908DF44031C71AEA18836CE96A402FACE0ABA91DB256E
              642E054738E26C7D21E682ADC98510F4149C8DDC5722054739A2B94E7DE54689
              DB5B44B360905F58B590CB3D53B03873171E88BE8F33FDFCDCD58DD2BA66585D
              18B277B4AF0CE62BBF1652D0F27FEC9356E7C497F6C15FB2D075A597CB4146CE
              A0CF1F4D5AC8FDCDEE7DD2695656736D18ABD375D93EF64705AEF6F504F3B333
              1072166FED930F0F85E37A9405317D7AFE2DA093FF83B034720C5DC34340C40D
              5E5E397BBC40FE7FB807421E2325A7F7C9951CF979A31BF3A49A5096BAC84C5D
              5A29C763EA93E9411E2791621241D67A982A42A49444D69229FE03DAC75147C9
              1CC2750000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\40_Play'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000092C49444154789CCD987954537716C7BF2F0961D7E3426A05655CE61C
              ADCB8C5A147414A40A2EA002E2CAA6B63AD6CE51AB63DDEB86B5626B3DAD75A9
              75A98E4EB52E751B8B7334C8695129A2B851092E08162228A9642121C9DC1B8C
              26904018FB473FE77CF9DD777F8FF7BEB9BF775F7E20E00FCEEF61D0F61AB631
              632659B18D5DA6EE055D857F8FC5F02822311CDB6235652259631E592E51F782
              8DC1E7D7AA7F4CAB0093F7281825612AC11CE82932B5279F24BEBBE9A1CE282A
              6A2EA0482F42A652A8388EAC931534652219496CD0AA06E19BB90A5749E83020
              25BC5C6F5EE629C6403A7619ADD1F493AFB866DDA38B07CED3A181544362C366
              92535C31C8E708DDBA25742CF212EFB435161AD4033DBBFD199D3AF8A38DAC25
              A9156581526505E9090AEF9520EF660132B2AF53B616A9604CF7785CB350A1F8
              F71D3AD4938C2436C9AA07DFBC21785EE4DF3731561089BEA2AB35F7F1F034C7
              47870AB151A1F0F1F6A2E9C6A9526B70E464060E9DC83057E9B482D4687A861A
              E3DCE2DCFDDFD1B48EE4B49A6CC0193C27920525CF851869146378685FCC9C12
              E3B2B1BAB0D1B42FF623F3E7E715AD36AE56E6EEFB8C220D8997BD9E4936E108
              CEDB999B951C83D891A114BD3A474E6560F39EA314911BBD29F5F195BD1B2954
              93EA9964238EE0658D3388440729C68299131111D697A297EC3D74066A8D0E09
              6323A9A29E94691AE9F2CB58BFE500458446F3AE32EFD0B714D99AB4E0C8A088
              1B42E52BC9D1C3DCECDDA4318819114A697B16ACF802B9F98568D3AA2566A68C
              417F6A98A672F47406BEFCE618F899742B5747DDBB77E41AA535247E26CDA47A
              06F958E41B947C9EBB35725010E651F51CF1C1CACDB8F96B39A41E1EA82A2BC3
              C0377B607AD268BCE6D792665D6775DA4E645EB941268DF2E2ECC20420AB92D2
              DC385C45331BB24544EFB9B7D446733A77EBEECF9708CE966FD1AA2F51A0A981
              7F521254972EE1496626A4944F8C8FC0E8E18328728D2AB51629FF48B574B79B
              419B5292A33C05C89FD19465A96D0D72FCA27A89B1119814174129C72C5EBDE5
              8541C6505909E5D97454FDF20B3AB66F8B797F1F8F8E81FE34D338FB0FA763EF
              9174AA222E1467E7D10573CB296DA9229BB222A2AFAFD63253B3328A7168DB6A
              783BA91EB368CD1614DA18B4A2268395E96751A57A8AD8C88198481FB4A1EB30
              6AAA62FC8C651401CAF2072150C8EF50C855ACB13318109C384D0FD1F690DEDD
              B0746E0A1A62712A1B34D633C898743A3CCDC84079F6656AA2167827611482DF
              EC4E33CE59B37137B2AEDCA477A36E953257B115C8794A69BDD5208FA280A094
              3D7AB179F2F449D118356C20A59CB324752B0AB58E0D5AD19596A2E2C4714B13
              0DA00F3D6D7234644E9AE8F8994C6CDF7F0252BDF13FC557AEBD075C57525ACB
              C6181E25ED8253CE57C33CE0A38533D0BD6B274A3967E9DAC60D5AB16DA249B1
              43111DF9378AECB971BB108BD66DA3C8744D79F1EA04A055292057B331864789
              2C385141856CBF63C30790B576FC49AD2CFB689BCB0619BB266AD716B3DF8E47
              87C0B63453CBBD078F30FBC34DE4CFA450FE961D8BFCFC124A3F63630C6FA5C8
              6072358DF87ED73AFAD930CBD76D6F92412BB54DF40335910A93460FC1F83143
              285BCBE8290BE92737CA8FBDA108784815FCCDA1C1A32E185CF14A066BBB9C0D
              C6DB188CB11ABC783108903D003255021D3356838534066C5DBF8096B80585CE
              59FEF176DCD79A5C3668BFC4AFE3BD6963F1A7F62F97F87ED123BCBFE273DA1D
              9AEE2AB32F8F776830809A84BE7FFBAFFAE7DBE8D6A523A59CF3E1FAAF5C36A8
              BA4C4D72A1B649C68D09C7C8A10328B2E766FE5D2C4FDB4191294F599E955277
              897994F807257F631063C2D4F12331C2C1456C5991D6B8C1DAD7CC097ACD94A2
              DF5FBB22654214FC9CACCCE9B33F62E7B7A7F835935EACF9797EDD26E15122EB
              97F40E0461335F6CFEAC044A3967E5861D4E0D5A5ED4172EA09C2AD7BA450B4C
              9D380241BDDEA019E76CD8BC0F97AEDE8650AD5957969BBFC7D16B468490A836
              3273AB628AB1EBB325F0F672FE15B52AED6BDCAFAE6FD0B609A2C24310372ABC
              C1EB306A8D1653E6A452440DA22D1A866BE505755FD48C88240DE837E59C5E30
              858C8B0A475C7438A51CB37A83BD41DB2608F46F835953E21048CDE00A874F9C
              C3C193E768B360FAA938FBD21CC0978A64FF55C7884892B6C113236B203DEEE3
              E16EDEB4769EE0ECD3AFF9840D9A2D066D9B606C741886BDD59F22D7E0EACD5E
              FC096DB7AA0541A39A539677E7BFC0AD5F69EA19C96EB3C0319BF4F40F4E3E62
              00868605F7C274FA5BC4116B3FDD893B4A156D58DD2D4D10D4B30B12C60D871F
              6D0E9AC2C66D07904DCF9EA57A95B7DE4781899E3DC7DB2D860DBA75EE3CE10D
              5D0B8F0CDA38F8268F1D86087A96EA92FAE92EDC52DCB73441D2B848F4F94B57
              CA368DF47359D8F3DD193207B5F9D1E3A925250F6E007EF4ECC9B97A06523D83
              7CCC263D027A4D9AA07777DB413166248CC1C0905E14BDE4E8A9F3F4B78E0E31
              2307C3CBCB83324D23332B17DBF61DA38830A8962B55374E41E1578646B6FC0C
              E724242FBF3E93E70B6E92A51423318E2A393898A257E7D869390E932C18755B
              94D9B9BB01775AD6EB1568E48F262B5C453792B75FEF84798254BC9862CB7336
              6DF2E8FFAB620C57FCEB7F7D8FECBC7C3A22D85CA5620F0A8C4F80AB6C4E4DB2
              2C2DC98233839C7F6152D6337E9CD4C36B3DFDA7CA87BB3B6270883034AC1FBC
              3C5D33AAD1EA70567E09E9E7B32CDDCACF9CDEA4FA589973EB075AA8A7648E0C
              DA99B3548F6123CEE039AB49AF0E1D62BB1B5A7BAFD48B4561784E9F1E5DD0B5
              7320DA05B4812775737B1A99A2E2526875D57848E36DC503E45CCFA76C2DDCAD
              E647159B4A3CEF28A0F0ACA465255996B59E39864D3404CFB3497E26A95C213E
              FE7DDA0D11449E53F5620CA29CCBB03143F5B38365DA871751A0A32E6DA6A286
              A8A2291D899F3913C9CE1CC3061A83CF618949F42E0EF3A4FD89373A377F5DE6
              FBDA70A9E016A4970A6DE99F683E108B3AD139F46C99EED2D95552BDB9D460AE
              BE52662A97E35A092DA3842AE54EA69AD372CAB574A69E6424B131563DF8C6AE
              C2E75AABC972A74526E9C930A4E86270434D8D040AB1988E81CE462324921AE4
              BBF1D291112919CAA9A698C5156339AC9A2D7CD3A6C0E75BC566D90C990D23C9
              E9388C64E439424C3796938130929CCDB0B85A746C316555833CBF5893B1FE1E
              8F2C326681635BAC066C4D31D6B151FE07C89CF4909300B0510000000049454E
              44AE426082}
          end>
      end
      item
        Name = 'Calc\41_Forward'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000091F49444154789CCD980B5494651AC7FFDFCC305CCD9328EB2AEA9AB6
              6A5E523920E82AA469666AA9EB5D04B5526B5DAFA969B5996B99B6C73CAD5BB6
              AE79214D4154BC84683A2CA7D00811BC7170D405416100131518066666FFCFE0
              E0709F39ED9ED3EF9C3FEFF3BEDF33DFF3E77DBFF79B1714FCCAF95F1874BC87
              632C58293B8EB1D3D4BDA1B3C8E74482B42A4A90D811BB290B658FA5153945DD
              1B3687E4576BE0385F7F8BF758983561258AB593A7CAD2913E29A96EB96534AB
              725A2AC831A99064508AE3907CB498972C949912837635891473169925A5F3A0
              C8A14526EBBB9E6A0C66DF69CACD961F5AA8ABD6DF3EBBF70CBB9554152586AD
              54A338635072949E3D673C95E3A5DEEE682C34B037FAF47C1A5D3AB7475BBF56
              942F47817C43317517D76FE621E3F23524A65CE468355AC59CE05158B552AFFF
              268B5D1365A6C4A4A81E52BC29E4BAAA7D50F87845A5FA27EFD6D2C7C3D33A71
              4CA8327E74287CBCBD78B9791E969621F66822A28F245A1F1ACB15ADD9F20055
              E6C5B9697B6278D948353A9B62A031E49ACA2F306231D4D8C8182F860661FEAC
              714E1BAB8B18DDF8F73D48FAE9D18C5698D71AD2A23E655446C9B2D73329261A
              42C66B997B33621CC6BF14CAE897137B2C115B761E64443726CBBAC2F3BB3731
              2CA5EA9914230D21CB3AA152A5DACF18D3C60E43F7A73B6160506FF69A26FDB2
              1EA5A5E5CDE626E87EC486CFF7322265656F1832A2F731723469A321832AD910
              252D34A926589F7863E62BB6823B0F9CC0F27953313C2C88298D13151DEF74EE
              C1E389F8C7AE439067D2ADA874F4CD9BB1E91C2EA3E499B4CD625D83D257B508
              8C3823BBF5852181583A7F2ABE8E398103299930190C1816D40B8B39D618AEE4
              0A6B376E47D2F94B3469D6E5A65C9F0124DFE3B06C1C9945AB187244C5F7DCB0
              52B3354176EB8ECF562B3EDE9EB6A2DF161AE1DDAD1BEE44456148602F2C9B3F
              85E9F571255778C8D5895CB0CEB6BBDD2ACB23F3520DC700DD035EB22DB5A341
              896B662F7CFC084C9B308243C09E0309B6A2BEA1A130E6E7DB0A073CD3054BE6
              4DE68EF664C6635CC9B5239FD91D9BC059C4BF735332660269451C3652B50CAA
              F8F5D5DACFF2440163446F5D0BEF4737941BC4175517152C46230A77EF422B77
              353E5E3DBF264F7025D78E3CE313E7BECB083014658740AFCB6228B35855CBA0
              7F70F81C13545F86F4EF89771647C2CE5EFE76F14515354505297C87857DB57C
              0FAD9E5753D8955C47FEBA690792CF5FE6BBD1F881214DFF0590FA33874D7683
              D2AAFC0323779AD4D6E9AF4F1B83B1230773A89ABDB12771A2B87651410A171E
              894355760E3E5A3D179D3BB57329D791B8F8247CB9E708B426F3B7B9E7D3FF04
              5C3470B85C8C09D26A3A04479EA98075D0472BE7A2578F2E1CAAE69B830D17B5
              531C17076356163E5C3517E7380BCEE63A9ABC74F53ADE5EBF959125DD70F6C2
              14C0379F9BA5548C09D26AFC82C3F59CC88EDB3E5901BFD6AD38548D184CB86B
              6AB4A850C0C2552C1CD0E7F7B8ECDED2A9DC85AF4DC480809E1C016E66DFC6C2
              BF6CA63F8BDE703F653C3233F338FC408C097294A2C1880AB638FCD57AFE7CCC
              BE43A79A352894A4A7239FCBD87AF010A773572D08C7003EF3C2CBB356F2A76C
              94EFFB43EF7F8B3378BF418307EB188CFE3F1A7C9B06831E191C673778F66C20
              E0970D249528EC0B7683D7D9FA7FB1613997F84986D5ECA7C1533F573659D4BE
              6C41FD7B2043EDE354EE8A3FCF40CFEE4F7104F84FCE6D2C79FF339E0E2D370C
              293F4E6ED0A03F3709BF7F077EF0D6AB351F14A20F7FD7A4C1E2A37CF033B3B0
              66C51CA4A45D753AF7771D1F6F92CB9937F0DEC66D8C2C1986A2E4C8BA4B2CAD
              A67D60C4AE4A35A6CC9EFC12460D1FC4A16AC4E077F7EA17B5BF3A34FCDE5DB9
              60BAADA02BB98E1C3FF93DB6EF3B26AF9984DCB29F96D5DD24D26AFC06CC7C0D
              8AB26540DF1E58F6E60C0E5513132745AB6A1595827776EF86AF0658B3FC5578
              7B55BF7C5DC975E4932D513877E12A948AB2F50569993B1B7ACDA81032BAAD9F
              D5379731BEFA7475CD8D62E24EE374C9E3A28E05DF7F6B4E4D9EE04AAE9DD2B2
              72CC5AB48E11374879CE48A4175DABFBA2165494D67FC0ACD326C5123269F450
              4C18339443C081238F8BDA0F00217DBB2362F2A87A055DC9B5239FD97FF4340F
              0B961F7253CE2D025AE4D6FDAA135494A65DF0D417AAA08DF3F170B76EFE70A9
              22378DE10D74F7CD3547A890BEDD303F7202D3EBE34AAE20B3B770D5DF78DCAA
              5094B29245051959A7802B7778E90155EBB020B198F46C1F1C115B091E8883FB
              E175FE2D127BF40CE22FDEB01D429F0F791633268D625AC3B8922B6CDABA1729
              7CF66CB377EFCA125CB3F0D96BF8B8258841B7AE5DA73C637CD2239107871611
              7F1CC9DFD28898E33ACC0B7F058343FA31A5710ED2A0B3B909A793B133269EE6
              506ABD5D383B2F2FFB12D0C6C0CD21B3C739AA6F50FA62D2C3BFDFB4292677B7
              6D8C3166F81FD0B5B33F029EEDC15ED36466DD4469B9B1D9DCA4E4346C8D3AC4
              885496BC6728B9740CFA360568E6C82FC89886F26A13307D99E2A6798731C227
              8CC488E78219FD720E1DD7E10065C36CFCDC9092B60370E7B25E2C46337F34D9
              915974A3BCDBF49FB154D1AA573146609FEE9833FD65787979B0E73A657C54FE
              F5F561A46464B247C4DC3DFD4E5C33DF052E88B952CAB6B4948DC60CCA788D49
              BF3E1327693DBC36F03F553EB2BB473C17A20C0F1B002F4FE78C9671C94FEACE
              21E14CB26DB7CA3367B2947C6C48BD72820BC5D7C9051AAC65CE367B8218690C
              B96637E9D5B9F3F85E95ADBDD798D4AA303C22A07777F4E8DA091DFCDBC2D3C3
              1D1DD90A39B9F9283756E016DBABFA6CA45ECCE46835B25BADB78B37E77966E9
              A1F7BCC765A56CCB5ACF9C20269A42AE8B497926395D213EED033A3CAFA83C67
              9BD418C231A7116395150FF61794DF3A8B6B46EED2274AB8211EF292919267CE
              42D532278881E6901C919AD202619E3CCD79A36BCBDFFAB5F8CD8B5AC52DD0A4
              55DAF19F683E50ABBA3087CF96E506B31F6A4DD6FC4A6BC5F9024B910EE9795C
              460D67CA9DA65A723975E5CC3451664A8C89EA21859D4572EDB32972E7225326
              1A8616DD2BDD5055A5815EAD661FE86A3643A3A942A69B2C1D8D686928B582B1
              48664CD4E0AC3922455D41F2ED12B3628666C3281DFB619459AE11350BEB6820
              8CD2891991CC16FB36537635C9A39BB98CFD73D28A68CC86C48ED80D389A12EC
              6DB3FC171914969F9D3D2AF00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\42_AutoFit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D00000AFA49444154789CED58795C55D516FECE3977605266444410C1592B73
              2853321BA4C42105290512032411154BB0D4A70295F34C9A5A0EA9F9E469F51C
              20B51444434C0D0904B95741C501111914B817EEE5BEB5AE424668AF17BE5F7F
              F4FD7E9F7B9FB5F7D9EB3B6BEDB5F745017F71FC2DF0CFE2B10ACCBD7667390C
              75416008E2E6CE4E2DA651EF0FE1710914B30A4B6264A27CF68D9B25F408383A
              D8A246A3D9F5447B8777E8B192584BAC231A880FC5E310281C555DB7B3373755
              15DD2CB5F47B671E181B97CE80879B338A6E157F30F089E0CF80E4BB64AE21B2
              406693781C02C5CC8B25C172A57CFD969D89D898904426C0CACC14DB3F9D070B
              7333A8B3B2870FF3EA778CCC1C491D9123D9249A5B20AF276517947E23C844EF
              8089F350587C9B4CF7D0AB5B072C8D998C3ABDFECEC16F13FBBF1BB6FD129054
              4D437A629322056273423C7EF6AC9D958D6B913ABF10A1D18BC90438DBDAA0B0
              E49E50DF21033169FC28686B6A4E3DED3EE27520AD8CCC5A228BFC4DAA9B5320
              AF2564A88B42248562DDDA4D5F6357520A9980F58BA2B034FE4B9CBF7C959E80
              1913C762F0A0BEA8BC5BB1EDD9AE7ED381F40A32F37EE428FE4AA4406C2EF05A
              52C6C5E223A2240D088A8833A6B76767772C8E8940D1CDDB088B5A82BB9A6AE3
              7E5C387712DCDBB5C1ADE2E2992FF60EDBF0B0A2E1459B0B62CA4F57DC2DADCD
              F232B3D5981EB7864C409FF7A3D1C2C20C53DC5A409D7BA1C1DEC9A50DE6CF0D
              8799A9F26E5E4EEE9837BD3D8F93F93745D35C02791D313DEFFA7B0AB962E1B2
              B53B70E0E88FB0E8D4094EA3FD6808F030116F4F75B7B4F972D7016CD97D802C
              8067EF1E98FDDE78E87435790713F7FBCC9A1A7289CC1A228B34465120FE1134
              9E6F5C84C076E994EAE61951147BBC193A1B6555D5E8111A026DABD6B091505E
              5B7C2D615047B737FADB98B45CB262338E9FC9A25780C05183E1EFE305AD4673
              A45FB7370280E3E564D6128D45C30BFF37E0794C91C82D83C5712AB81552332E
              78985AB43C7FE25416624900C36F4A28F44ECE70BD921D995029733673769FEE
              A494F46FDB8952DCFC4FA1BA7C8D66010B674E448FAEEE282B2F5BF372AF7131
              C00F77C8CCFBB14EA07F7E0F3C4738917B234694C4C9D487AE56B7E3B9AE4E33
              A8CB5FAA230A69398531329962E6CAF53B7130F514DABC3604767D7A21B2ADC9
              2DEF91A386DB3BF7AEEE386DEA364192BAB5518AF04605E67DF46943D12CFB30
              12ADEC6D7029BF20D07770DF445AB39258CBCE1F051E17D2CEDF58290A42C44D
              AA4A86032DA4D16A760FEC11301148E585EAD272AF9FAFAED6BA844C5B806A0A
              AAFBF4283203C12D345F8D0F7EFD43A89DAFBB87F7973BBE1A982888B2EE7D5A
              CAE0A0CAC6F20D09340BE8E0E284B80FC260666672E7E73319DEA1635ECD2473
              150B7814C4E4ACCBBD4CE48A932C2E72F62AE317AF8C9D0A37572714D311316C
              40D8E749273674B4B6B64D3D4C915BF1D9BF60FBFC40E2F3E8662EC121F3D01B
              7153E3CF0236457494547799B9DCC6BA97D732FFB616034A7470BE74E87BEC4D
              4A0663B0676F44848CA6A2D19D3F7CE03B9F39EF065D7A94401E938E9FBB7658
              1405CF390BD6E36CEE4532D12F135B6B2C8B9B025313C55D756E5E405BF776C3
              4C95A6C10B567E81B49FCEA143541404A509C63B48D782FD7D474125BB4A8731
              879FF71543E1F5EFEC85959232C289D25DBA7327CE66E59219981A3C1A2F7AF6
              424579E95AAF67C6C7B08887414CCE2CF491CBA4846C12367BD17A32FD827E3D
              BB217A72206A6B6B5474309B6B34354E01113134023C3D2E104F75F7C033DA92
              3523C3C7AC475E2BAA86D40A1AAA2532448FC9F31C5DBDFC53B410DA3BCA808C
              E5AB4914DF7AC0BA45336067D3F2AE6777AF9E023D3705B6CB52B3AFA9A9E312
              1EBD08374A4A6161628A6E9DDD909E718E86697FBD3914DEAFF4A71E25EFD869
              ACDAB4CB78EEB974688F68774B1CDC9FE8171B1D9F01B4A6F42655D1343E3A18
              B42CA4F613D6B5EE3CE2A5931506B4EA2D68B067713C9981253193616F6B55E9
              E9FB523F9ED8186C138E9CBD1C2B93A459FB0F1DC7C69DFBC94407EB94703CDF
              D6169F7F1C8F1BA5A5640196CE89403BDAE0B18B3F834AA38773E05B30A1C3E8
              7D7B64BEEC3F241479B694DE349ECC155F47341E4BF729770D8C701A1914B9BF
              9DB9BCCBC5F26A3CABD0A1ADBD35CACBCB760D0DF689E5498D21261E55D99A59
              99A8AAAA35961133961A0BC3D5CB0BCA3E7DE1467BC6465B898425F1D06B34C6
              FDF85EB83FA2E2E2D1C6CF0FE61D3BE1454B193ADFB9B268ECBBA1DB90EB789D
              E2CBE9E5E38805D6837D3315F4E92D420F6D4CC9D10A5D1CE5A2DE5F51BE75E4
              A0496B803B253CE141F0B37838A3608B284AFE5FFC733FF61D4E8389A3235C42
              42690870931B2AF26B8596E6DA2A64AEFEC4289253AF3551C22DC2784C6296B3
              02DBB76F796DDBE29D2A20AB984C55444E2F47EF4118FD1115CEA3E7B771193B
              620FF5C51F66FAF8224746EFFC5CC6131E849874F27C2FA5D2F464F1AD524C9E
              B58C4C40A7499360B0B6C1336686A22BC9FBA6D53E376C53B10E4AA9A20C79EB
              37184532DAFBFB6358CF0E7852D2FE30B4DFDB91E4FF2A70BC3EBD2C8ED918AC
              814552A94049E496514BACE1C17A705FFAFE4CFE618892E747CB3722EB7C3E99
              80807933502153C23DEFC7B00FC2E79DFE78FBAAAEA7EDDC3715D51A24ED8F27
              519892427B2F102E753508EFE381C2CB97168E1B3E611B90739D5EE76BAB717A
              1B837D335928B70C03F157579D9894AEF291CB15093979F9885BB1A921B5CF9A
              8BE82F561E1A1912F40FA86A2865B6551BBF5B31E1A2BC658CBEBC1CDF5F2D83
              A26D5BB8893A04B652546EDFBC7DD496D5096A4A11CDA58BA5E9F436E085A4FC
              767A035C855A5DC5D1111D32C8548F861F0BDCCA0E9CCA570B82E0327DF60A63
              95BA4D0883DCC1019E16A829DCF1F9C8ADEBF614D08D404E53D9A9624F5ACE86
              148D62547AE53DDF7ED6229CAA2B76FBBEE3FB31D4CED780E43232D7101F153D
              78EE537F432B8C201165A9433DACC9D400B2192126A6AB63253A560E1E3981AD
              BBBFA5ABEADE75D54A06F8D4957E317648E02AC0FA061D19F54E25FA768B2F93
              E357EFD6988EA667F8A274EB982963D7224F7E1BC8A60F3116878E48FE9B0647
              4FA7D7E753D70841C0F8546F8FCDB80F818884C4A3F616766D5474D95B46CDBD
              77DF76888E86A050629C55DDEDD0716387E3422D393C4B34FECA60A7FCAE825C
              9803B72CD1596746AB1BEE575F398DDD25F246FF9DE85D8834C040FF036188A1
              F7E79229F9D8508F41D41A2110B1EFC485ADA288801DF44BF7404A3AACFBF6C5
              CB9E7DD0BDB50DEAAEA8E74C9A13BB172A05452F991D73F4EA9DF2A6A618FFB6
              FA88DC1AEEF3A1A0F4E653632D994BED7495BA6492F4245D106EC9AFB9158070
              4F60BABAACA4A4CC322A7635A5F55E6A7B9800AF28AA3347BD1D120675D54DFA
              E3F1165D57BCF7387A062283DF67B2506E193CC61FC02DF3A118B057F50245ED
              08BDB885F65E50433405AC3CE6ED114953A84BD89BA62E2F292D6B397FF337B0
              7F2B088CF15640E1A9F490B9EB3E4C478E5D1115061F17354476DE18C6751EC0
              2385D583A2B799268EA3970BA82DA0D7C8ABF0143D37140BF581AF52CE2D5028
              15333EB955873B148C0166C09335A55F8D7975EA023A6349DC69DAF4E0D3584F
              A4B5FE3C5E38926FA5ABD4F321DE24EA8BC5289060B1FB48E6EA6D5AF34076EF
              A32FDE1A306D12FDD1A02761192534CE1B9E53DB54F4FE2778EE5707190CD884
              07D2C9F04C54BF6EA8C3D7D435164BBD4005D102E861852E3A8A1FE1976AE4AA
              E5D49274239B0503F6A97EA2383D2513A49EC9DE6E19646AC0807DEA0200AE5C
              2CF5027993CB892C945B462D918571CBC298FF77D40BFCCBE26F817F16FF0152
              78427022F37EE40000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\43_DataLoad'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000055849444154789CED977D6C13651CC7BFED6D07DDBA11C2A84C2732E2
              6622F887E0184E0723040D31C48020028EF1122310744250234A06BE46594094
              80C480220E44DEB2104394208B2F3018324900A11D30A1302C2063DDD6EDD6F6
              FCFECA36C0ADBDEA6D8B513FC9EF77BF7B7B9ECF3DF7DCF56AC13F9CFF9660CE
              AE33FD404A46A756A283E8304191F307026758224651523B4AB2C3041FDEE9CA
              81C5B29725A0EB237E189356820EE07F41B3FC2B05E51C092B43670419BA8160
              CBF1B20C1DDF1C86C809D122C75A060ECC4BF5D8B19D353CA5EBB3B8D0187E0A
              0E0F2368710C9D5ACE8525A9469B7CFCF8A6D3DCD6C40832F4E6088B741A0D72
              9C253D6BDAE0FAA0BE9B463DD8EA2F974A9DA380FDD5DCD7F050F189611625E6
              5BD6ECB25550CEB33A86E65110F7A9408DDAE81F77BABCE820D71B197E069B0A
              45BB480346C831D694A14F4F07944291634765EECB95F9A8B85605FC7C85FB7D
              14CC0E23A82073749F14CB6D5B35E8996A20E86DD251F0DBA1739FF095EEE37E
              910C3274461BA48148C87EAB23236F1EBB59CA1A6A3058ECAE3E5000A78D8D27
              5E05BEF772B346C1E1610425784DD909291977ADD114652CD7397EC1D73DE51B
              56B0AA67DC7CCB6F414E0E87EC5352864C5BA759F55CD66CC2BFD4535D560467
              1C1B8DBB06ECABE5560E2A0214CC092328280C4A66D97B0FEA9F6F5195855C07
              47739BBBECDC2CA0A48EAB221960DC22D9D2C09FB1206752AF843A75BB4D41B6
              1AB078B598BA42CF9523C570AA94EA59C391A364482EC8D0B3B61FCDB1AADDF7
              B046506B18B96FDCC012DC40FA91A79892D9718E217DA7AB8859A45961F70582
              07BD5A6D2E8EEC38CFFD322F038C564939B13D38E7F26AD9BB4DE4507F7596BB
              F1D80954C437CB85E68E5C71488E81CC8D65C362137B7EC3124D35571F393039
              E33B9637237D5919B1408EEDCE7B9332757BFCE72249EB0677E9D1FEC04FF2C0
              89A4B429113AA93D62F9E4695C62F3EA02F471F4621599935E0D8515BCEB64C1
              DD3D704F02BB35E0A2E70A26CE5EC24A5E59870600C7F8D08183107A70220AAA
              14942BC1DEAD2B988D3959DB8465CD82F345D0CE818A8211E3F3992978F9C7C1
              A8483EC7A9238D88A0DC1D63C13D5FBECF6C8C9382CB4FF3EE9379FD13911EA5
              E0C8275F60A660A96B0817BFF2C113C196E9632CB8FB8BE5CCC638EB9AB0E28C
              9715909F9A80F4F8E804473D358F9982BFEFCF8433A9325AC16E146CE0125F6F
              5AC66C8C8B821F54CAF4019EEF67475A94828F4E9ACF6C4270575121B331AE3A
              3F569E95D71930B76F3C05635819337ACA026613825F6D58CADC968D553E94D5
              483BC66424C66272B28D555B1ECB7D91D984E0CECFDE636E8B2FA06395BB1E17
              1A43ED84E5F66E56CC4989834D69BFAB31535F62362158FCE9BBCCED73A13180
              D5E77D680835D596EE5660F61D364A2A5C6B9FC7A7BDCC6C4270C7BA7798C373
              C8EBC7964BA1777A1B26F456F14042E4B93876C62BCC2604B7AD7D9B39322278
              B8567E426F30C8AE84048D7862E6426613825B3E7E8B3932BEA08EB5173554F1
              434F488EB560661F15366BB8E66F30E19957994D086E5EF326B331555A10EB3C
              D22E30C3118B649513300A263EFB1AB309C14D1FBDC11C1DE575D76FF3FDF10A
              73744C9AB588D98460D1AA25CC9DC7943905CC260437AC5C8CCE2477EE62087F
              55B0F56361FD87D7AFB0B3C87B6E09B309C1AEE2A6CFAD6A2EFD0C03C107F30E
              F39B7600EBCE27103CE5A93E351E2ED5CDBF1335DC622818C3EF8C38E0AC0369
              3DEC70F17F44FAE570C79AC399A4238DB7D475AD16E8EBE1F7533DB706183A23
              ACA0BCC444B23B5FC3FC39E05F9B4E45E568D934CAC983D93A7A42384141A45A
              428874AC1942234544AA255A31EA54F64B7405222A710B5DD5F9DFE60F37AB8E
              4731CDEC020000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\44_DataPaste'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000061449444154789CB598096C93651CC69F1EEB3AC00D10A68C810C3348
              54120202034222410E8320841B840D10C721CA7D29088882DC384150AE718E2B
              4CC520A0623401B601199992B005DCA0855D0CC6E8D6753D7CFE2DDDC1DA6DDD
              B7FE92E7E9FF7DBF6FDFFBF47DBFF76B3B151A06B98E484DB9713CA77A211755
              82FC3D35B47178B790C432B53A896DD81DB6C23CCDE343B87C269F4D1B65A724
              A4C82778F17A23B3A5469F51CDC283DB26E91A0545E8DB45B00BD0EAF528B89E
              7AC760340E42EA9107EC2AA3DC4145754645D507759B9E31310E876D38CBD79B
              F71F1011D2A307BB2B284C4E46C1F9B3770B6DAAFB7A87FD70DED543FB015828
              2B55E7902ACA57D4E13D274EB638D4BB5B84045BF55AADD6DAE54D780AA8BD96
              82526B992DAFB048039B75416E8A710FF0A789876D549D42FA1A50CED7B48E8A
              BE1812121CB579F5C75A93A9041BE27F42F12BED61359B79D8B5C48159B7B16C
              CA3004B19EB96083DD622EF9CB9072331AB8F690A7C88912D041D5880C581B72
              8E4890574D9BA8983F5E6DDFA6F7FC99E3D9048A8BCDB87C350DC525A56C018D
              8202D1AB7B27673861D38E23B879FBBFD4DCA41BE380B41C76B967D11D505E45
              D59001BD21C744AECDE0AA459AF01E932F4444B4EE393776349BB5B365D771DC
              CACCBA915B90148DF466D940D25376BB038A643645528BCA91013DA142BF49CD
              C38BD45BA0760CB50021ECAB42C776AD316BEA4856B5B37DCF490634B2AA4E80
              0D0946942E424A421E9BB2DBDD419D780BA8E6322696C23184B54722DB86617A
              CC3056B5B3737F2232EEDE67E5199DCD76DA9092150BFC5DC426E7C319D289B7
              80DAD0A8687937D8BA72363ABF11C9AA82F92BBE419631070B66F296AA036BB6
              C4A36BA70E58B5781A5B15A4FE9381392BE3A0B3DB9F1A92D3BA00AD787F9E2D
              E621F7F27B0DA863C052BEE2E2896DF4AA9CBB988475BCF19BE80311DAB2197B
              BCF3E48909F9854558C20D35B06FD54791D077D4277420B7E07267A4A71B58CA
              2CCAE4D42DE0EFC7B7D2AB73FE62B253756140DFEE4E79A2DFE8397406BC72A5
              1B109AC5652E64B3FC61AEA23C511EF0B7635BE8FEE3ED3173E912F032A7B745
              2670A910AE19AC31602003CAC3141712FC1BB0FFD8B974062C60C0F47A043C77
              7433DD7F0C1C378FAE20E0AF4736D195F3D0E21C0F2FEAE4995FC1A0F1F3E90A
              029E3DBC91AE0CA3D986B82C132B6051FB26681E5011F29D090BE80A02FE7270
              03BDFE1494D9B131D38412BBF3A981E5CF051C3C71215D41C03307D6D3EB4789
              CD811D8662184B9D6361EC4B7A740F096055C1BB9316D11504FC39BEFE011372
              CC48792263017D9A0660584B3DABAA0C895618F0C7FD5FD37DE77C81051728A1
              7D9006335A07B1AACE7B318BE90A0226EE5B47AF8ADC5742E57BA932FF9AAC88
              CF763EE711C65D1B1BA64790C6F350C3262FA12B08787AEF5A7A058F186E9BD1
              79081FB6D2232CB06AC8FBBCDFBE7F60E6A600F43C14EBE19CCA0C9FB294AE20
              E0A93D5FD12B7864B563FDBD52564010C75DD886B3A3765D46766A9CB194E7B8
              76ECC4501D5E6BAC61E59D115397D115043CB9BB6A40E1DA532B4EE5CB35F805
              49A7C26C2EA1B09BCB7AC7ECBC2E06370F40EF602DAB9A19F981C280277EF892
              5E1D0978DD245FDB802ECF66A9727B448B0056B5336ADAA77405018FED5A43F7
              CCF66C0BB2CB5CCBE9E6E50015A68606F0FEF376E9AA8C89FD8CAE2060C2CE2F
              E89E31F39EDBFCA00CE66719F5BCDABC56750F278C9DBE9CAE20E0D1EF56D3BD
              2333B82FCFEA0C392354EB9C415F183763055D41C0C33B56D16BE6F1B35DDB54
              ABA2FBC684999FD315043CB47D15DD7FBC3F4B61C083DFAE843F99F8D14A08BE
              062CFF4D121FE77A87FE227AF62A3A03FAF89BA43CE0D2D993D031B21DFCC1AD
              8C4CAC8D3B009D0D2643CA95B77CFA55171E159D68E1175ED67E4767B19F3314
              DD5E828C4BF7D82CA264061D94D7805A741D1216AE6EB6172A550F8B1A4DD8E7
              177416DB794359F606A4E567F18333873F328AD96DA36A0CA8A67440AF60FEA7
              AC29221B374246BE7C76A9D081DE50A43344648B3264149B80171E737965F6B8
              70AEE515BC05947E0929A102292DD0876D9BF437201ACE922888A1CE52CEA595
              70EC7351D380724CC4604E09D26E48DC41249448DAA272FE0711CFE5473A15CE
              A20000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\45_ResultSave'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000004DD49444154789CB5987B50546518C69F5D771730BCE48514B1696AB0
              9986669AD151AAA969A6996A26A58B5A21C8450B5324A754522B906E66644060
              374B938BCA2533CB40ADFCC30971981CD3B0012A21D62510050576D95DD8EDF9
              382C24CBBACBD9CFDFCCFB9CF73B9CD9F3DBEF9CEFB0BB1A78C7758C6BAB0627
              4BE0DAFACCF54E2AFE264A3B5002311E2D424A9463A044EF339E4EA8C1C37193
              C23AB559D03AA36CC004EE538501B864EC699983D315AD1CF2A5FA2545F98427
              41EDCCC88403563817B0F71B4A5E3176B5DD8BDF0F1939EC61F5B17C92F424A8
              0B898CB7738BEC8C14DC1311CE6EF4ACD9948DDF6AFF663720D9D97A1F6ACA9B
              38F459D293A08182566E71AC2C87A98E7569B9E8325B3165D278FC72AA4695A4
              57C19F4BD50BAE4DCF85D96C41F2B28528DA7F14274FFF316A49AF823F956433
              D5B12E2D8F336846525C144740C9C163A83E533B5CD2C2129223AE6E4F820114
              14EF0E3F166731D5B13E3D0FF50D4D983E7532470AF54DCD4CCE00D06EACAABB
              1B38D1CEA1980C21E98657C1A3FBB298EA282CADC0999A3FD90DE1703AB870CE
              B3035AABAA23807326B65DACFE45391CAF8247F67EC894CB23D1AF3085E0C939
              C0D47F80E3573814CF4837BC0A1EBE01828F0E0AD6CFE5A611A81482E232BBA1
              618DC4A060C59E6D4CFFB9645316EA6483168F2D59CB8E82974FCC43DD9406BF
              04CB8B3E60FAC7859E3EE43676B303526F0F464C422A3B49823F14FA2778D9EE
              40E6F92E581C4E8E80B43BC6213651A2E0A1824CA63A2C7D4E6C6FEAC605AB72
              79A3A70562EE04031E5FBA9E234982DFE7BFCF54C72E930567BB7AD9010F4ED4
              E3C9904076C0FC388933F8DD6E7582072EF6E07887F2688BB84987C4D020760A
              0BE2250A1EFC6A2B7374545FB5A3B855395F2857EDCA1941081A3374AAA88457
              999204BFDDF51E730871D30B26E9B54C774CBCDFB28C167640200F79392CC8ED
              D82712373025097EF33FC176CAE50C9C3C89972C34E0DA13BBFE6E51DE03D650
              6EF83182A7640AEEDFB985A92004B636F5EF4610CF9B7A2B2F9D567909F118D9
              61B2C234F0405E3CD580D9E374ECDC797AD946A624C1AFBF7C9739C4AF9DBD28
              6B536EFE508306293302D901052D569C332B72F78FD761FE643DBB9159B87C13
              539260D917D70A0ACADA6C38D5A57C3A9A1D3C06019CC5CAABCAE3E4AEB15AC4
              8604B0F3CCA2E7250A96EE7887E94E9EC98A66BBF2DFC1C574BD06CBA719062F
              BB2716BFF01A539260C9E76F33DD11F7DC36930D3DCA55ED5FB1C994BB59E7E9
              25877826E975A624C1E2CF461614347341EC6CB5A38713B9EA163DA6F399E70B
              CFAE9028B8EFD3B7989EE9E8A51D99E8C3CCB978EEC537989204F77A115443B4
              4CC13D9FBCC994CB9295694C4982451F6730E512B32A9D2949B0707B06532EB1
              C912050BF23643364B576F86C01FC1C15F16F27395772B93B8940CA624C1DD1F
              C9178C7F298349C12A0A42A5605864C2451B9CE337AE8EC39DE1B74116B5F50D
              D892970F431FBA8DD5550F01218D6ABEB8EB67CE4BC8B56A9C2BD8DF100C36C7
              6163E75F1B505FD9C461276B54823AD6D8199131391A876E914D8B608EA561B0
              F51D31DAFFCDC4D9B6467EC468E1B76F3377F7B2DCD0B04642CBD2B328163111
              B36CC1A8D370ECD46216F7FA431D7F660B9F6247BDB91B18D7C1CBEB9A3D07CB
              0D4F8262BF284A2180C5ED0394EE13FBFC648C53A9204A95B3FA7FD51272DCE7
              CE7F691A8C47C417A0D70000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\46_CopyResult'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000005D949444154789CCD987D4CD4751CC7DFF7C02120A98D58366CB5254B
              D75AD69AD8D6E6743ACBB4D57CCA0720415143F1090445104451501161A82546
              90460F4B6D9566ABB5B589CB7FDA7459600BE6B552C910E2E10EEEAEF7E7F7BB
              3BB807EE8EDFD9D66BFBBCBFDFCFEF7E0FEFDFF7FBBDCF7D4187FF39C10CBA3E
              77B55A713004571B32C33D588E4BE89D2148AE059729BB33249708097F0FD561
              66F283095DFA0AE81DF3ADC0181E0B8B081B1A7F872507571AEF30ED67B88C06
              C59F41FD84A4D4B31638E6B17FDF30D96C67CC57DA3280EFBB98F2BD159341F1
              67D0189F94226F89828DA99894F8387BDAB9DEFC1B8A0FD7C164B7FF63FEE1EA
              B3C0F85BC0F91E7E6463041D451DC31B130D5AD8E2747521357C9666165181DB
              779B9E4173B399DD2E860C828311101DC31BB7C1F78F1450474E878C0D196BA0
              90E51B8AA93478F9F2F3407C1BA7F91ED301869D11101DC31BB7C1FACA7CEAC8
              B835003474A8B74D1FE7504C26679530A3C1BB4D53D11CD70A5C1283AE119418
              16F54E9E44D2601F5BD455ECA0864E1F1F55F3B75E6985B7C6DA3186065337ED
              6146837F5D4B424B6C1BF05D07D37E86F34C05E94B78A06378E336F8EEA13C6A
              E89CBC67C02D9B7ACBB931363C1DA93EEFCDCDA5541A6CFF791A6EE86F024D9D
              4C871A9456A65B42FA120AEADD3C711BAC3D904B0D8D2F7B0CB86AD5B3073C65
              B2636EB4732192B4ADFBA8C313A84E0634F84E790E15B867574F1BA357AEF1E1
              1A8D9DEF8D608F5F01831D29A3E51983ACCA2EA30666B83AA93ED913B7C1E3FB
              B315730D3D2666C0A2282B0D789ABCCD296DE889648F17EA1C58156361CB6408
              19DBCAA95C799F1CA17AF2E3B5166CDC55356C9DF4BA9582DBE0B1D22DE8A4C1
              13BD51CCF801473D3DBAD76DC042AF277AA26071BEE7F2A83EC4EB9517F7604D
              DE412AF0EDC795545F662CCCA2F265FDD449F5CE9EB80DD6ECDD4C057E1A30E2
              A2551DA5876860D9A85EF680537D51B86357D7DD6C9305938DAC317E58B7FD10
              15F8E6A3C3545F662EDA48A5413F755247F1C66DB0BA44BD50F8BA7F14AEDBD4
              7536D9202F47E3CE7C12F35911CA257EC9CC3F4CE53D1A2BA8BECC5AB2892A06
              592711D73AA44E0636786477167590466B0CDA1D06F60689D3D9B0C4D4CDDEF0
              6CD85949052E7EA08EA437B3DF50678A53EC5DC8031BAC2C5A4F1DC4C215D130
              F0807BCDC99A5C61ECE49AE4620C4056611515B870FA20D597394BB7503518AC
              28CCA47A222378CE1ECB3AA0C3427DA73282C1D854544DE577F3D401AA2F2F2D
              DB4AD560F060C13AAA2F5DCE4D76AC5AAA82B2A5B8860A7CD1A0961B6FE6AEC8
              A66A30589EBF961A3ED92547A9C0E7F565545F5E49CEA16A3058B623831A3E39
              7B8E5381CFDEDB4FF5657ECA36AA0683FBF25653C327B7F46D2A70AECEFF6FF2
              ABA9B9540D06F7E6A653C367FBBE1354E0CC49FF065F5B994B0DDDA07BC35A92
              93460D9FFCB25A2AF0696D29D597D7D3F2A81A0CA62D9E83C7268C674F3BAD37
              FF40ED8717307A5414EAAA77F2882F0BD2B7534760302129E5AC95E589FDFBC6
              8C6953B076E502F67C59B86A07357483463C37EF9104FDB893D0E9A672AB379A
              C7C2627AD214242F7E1931D151CC7C599C914F0DDDA0546113F0C20340F7584C
              8C89464B7B0412F9D3E188651875F1714F36F11C341EDB4D0D9F256BD4A90FD5
              A01C1393B25589641881179973670A135B8B213E29D1CCE3387DB4981A3E4BD7
              1650433728C87109BD3304C92522F825EA648B533545D4F059B6AE903A32832E
              E4730917D21783BD6CD150BD0BF7831599BB20683138143957420CF6B1457D95
              FAE6E192BCBE884A83216E580321D3ED36589CB31A8F263CCC9E767E69694569
              553D4C36749BAF5C9E1ECA963F1062D0F85FD44993D5FE95B9EBD75CB45CBAC9
              B48B2123C82DF2C890F30DAE3A6935E866320F1B93D576D1DCFF6739AEB6B785
              F2676730641407EBE413DD31B8116F4462BB967B01CDFCBB61625C3F5A7ABAB9
              05EEE0F4CAE87182D4DDB0969BCA3562D25927A7B3E5EF8D66E43F0112FCAF00
              CE3394A915733CA63E4C0B729D8418931024D7826284882909C92514FE054161
              95479F1AFD8E0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\47_CopyImage'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000061F49444154789CED987B50547514C7BFEC2ECB5356125FB9683EA749
              B3C947928292A9692A8EE8686ABE35A7B11CD17CDB344D2A29218C694E93AF7C
              849562E003038734C4D64867A0E40F40455D0909587617D86581A5EF6F9785C8
              45E0EA3635D367E69C7BCFB9577E9F7BAE77B98B1BFEE5FC2FF8B8FCA705C531
              11B2FA70207A4F823A8603B16FAD0FB1DF40738BB90D1830BF97DE17313C7BA4
              0550B1E7124CB5486F27B76C2FD0C4A5B2E452A8655819369C09DAE4CA7CDDAE
              5B50E7C7FA1FC1BDB676E6FD8C92F3409289650D83B3A10CE3EFC8D441F31378
              2993063FD7071FAE5B025F1F6FB69F3C854525D87B301E97327E8512B8A6D564
              4F05324A79C8CC1053AC7326A8A060310555A70F45BA4CCE41DE6D2D96AE8D82
              D26A2DD7FE7C7D18D0B100B858C143B6293A1354760A9A5FC52D52BF8965763D
              A367AC64068A8AD307214F7D8F82069642D0FA48C10B5FC73037A5BCC284944B
              19C8BA91C70A18D8BF0FC68E1ACA497BB192C6989911CC14D4E4BE04C8F38134
              3D5A239872BCA9E0CDFCFBD8127500DA9252F4EAD6851DE0D6FD42A83B3C85CD
              6B16A1F733DDD8693B63DF8860A660E94FC39013900F5CD103A8663815F4A0A0
              995B24C7ED64B62326B7625D347AF70EC4ACF0B1F0F6F26417A83499B16BDFB7
              30E88CD8B57DB5A4498E9BB58A5982E0F9AFA299ED2424FD88BD4712F0E9472B
              1BE41C08C977DF8FC5DB73A760CA8491ECB48DF1B357334B104C3AF609B39D2D
              D107A12B3560C5B219AC1E2672D711A8BB76C4E6D50B59B58D0973DE63962078
              EE68A3E0D69D07514CC1E58BC3593D4CF4677136C14DAB16B26A1BAFBF2951F0
              EC9128663B89E7D3F0F9B1446C59BB185E9E1EEC3462325761F38EFD5836270C
              61E343D8691B13E7AE61962078FAF00E663B157C48566E8C456060274C7C3508
              9EF59266CA1D3B9902A3D184D86D2BE123E121993C6F2DB304C1C42FB7333772
              FB4E0122630EA350A74380AA1D3C954A68FF2841177F7F6C8898879E3D9EE659
              6D276CFE3A66098209873E666E4AE66F3938FEDD0594F2632520A03D860FEA8F
              D090C1F0F1F6E251694C59B09E5982E0A9034D0573F2EEE062FA3578A8035901
              55DA7B081D3118FDFAF460259DA98BD6334B108CDF1FC96CA744A7C789C454B8
              FBF9A17D48083B40595A1AAA0D064C0F1B8D0EFE2A769AE70ADF5804C3873ECF
              DC94F0C51B9825089EDCB78DD92E77FAFBCBA8F3F4822A28086EEEEEECF255A3
              BA1A7A8D066E661326BF16DCAC64CECDBB9CFC75EE013DBB77C5A8E183A054DA
              7F8660DA928DCC12044F7CB115164B35E24E25A3C60AF88F7E053245E30F1658
              6BAAA14BFD010A7E299835751CFEBAB0E0F707C538C38B5376E9028FCE9D61CC
              CC4487A75498342EB8E1DCE94B37314B103CBAFB039C494E87BEBC027E9C9CC2
              CFF9846A0C7A18384995AF0F171E01C7C262F26753D261F5F0427BFE7B31F9AA
              0785A8A0A45CE686896347D8A63EE3ADCD3C5B82E0ECB03128E622FEC1C190AB
              9CCB39A8D5EBA1BB7C19015C70CAC4505878FBC5C5197871AAE010C8BCBD7996
              1D716E99E62AE45C3D74F88B58BB650FBB1204C7850C81EFC017E0A956B36A19
              B3568BF2AC4CF4EDD59D6F3F95B6DBDB9E720A3E580F515D43490D6A8C7A24A7
              FDC2461B04F9CA6FB670277CF9E256CB39109286AC4CEE017E2D5C9C955336F0
              769F3B79164AD6DAD60A8A092ADBF961FA8608966DC7987D0332FE7FF3E9DB8F
              55CB9C888C81C56868FD046D82FE1D10BEE61D96AE273E6A372CBA92560BDA5E
              F9ED82CB59BA9EF8A83D12043DBD3199B758A190B3E53A8C7C982E6C8FE5A35D
              53A5D5E48A5F51772858C66D0DC3B960E7A17333EBE4B2677B840463C898912E
              9334F351CC4ED320F7E22521985FA4BB3A0D79EABB68E16BA77BE0CB73E656D5
              29F6731F4AB9828FE3A33F03256332C162AEE40EA92C5B5394959B046417B02A
              670841A75FDCC5B83C3B0E9BB3C0CD2A8B50CA656A7EE478B0E71A6AADB75065
              D85B5479231579AA62FE05A4845DF139CC5FAECE05650C4A86FA007A8EAECA17
              7D2C1EC8EB2447BF6267E74B2727A00E28A5888C425E46CA8987438CD4363D06
              9A5BB05E124A7B84F03ED73677EE6322A7489A10E28DB2452D83D2761EB5A890
              14C71D5B8163FB24A1A02D849408B1DF404B0B3A8E3BB6AEC221E5D836E0EA85
              1F9B3F010AC6E84747D58ED30000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Settings'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000058949444154789CED976D6C535518C7FFBD5D6F5FD60D58573658C7C2
              22911810D1A823A218914462F8A0C37D81BD84393E080A594208062244124266
              C02C314488E14D94008148225321422292004EDE268E306083C2D6976DB06E6B
              7BCBEDF5790AEBB652CA696B081FF64B9E9C7B9E737ACF7FCF3DE7DEFF7478C6
              1911982E2302D32591401E8B8D54D0E284308F5B94F392634679950269BA5FC5
              34EAF3AD392F8C598F8B72583BE93CB3EB27EA8628548A3085B0C8780BEA30BB
              22A7B04FB73D08CC932D99413937D7487921149F0FF007E88A50D5FB4A289821
              6BE15F9DFDED9FE0D2B176CA2A14C2226305725F2A2CA93CA4D972E68CFBA0D4
              64CACFA7D49309070268DFBD1BBDAE0E144F184F19E0FACD3BB08EC981124610
              5D9E93CEB3571700A77B6848A11012C9828622394A162E52A0DF56F4710D44C5
              31B7F7EF83C9EBC6E62F96206F6C0E65808BFFB4606DDD76C09E8BDE5BB7A0F5
              F9977A2EEDDB4B435466DCA76091098915A82F28A9AAD765596B262E5B6EA0BE
              105CBDAB5FD5A1B6A60CB3DF7A953283FC78F0377C7FE828644386AA0582FB6F
              9FFD7725D0D84943010A16A8513C96588119052595C78D138A6616545450578C
              405B2BDAE8F1AE5FB918532617536690A6E6EB58BD712BACF63CF4BAEF9C779F
              6E2A03C6B980867E1AE64393944003EDBF7A2D2BBB7AE2B26549577069552966
              BDF13265063972F44F6CDF77842A28AB08FA0F39CF5C5803D83A80137D34CC8F
              392981198ED72ACA1449B727A53DE876634D6D15ECB63194013C9DDDF872D30E
              04B2B2D17BB30D5AE8DEE79EC6D603E954504F6172CCA83C88D1B659E34A3F34
              8A8AE42AB6EFDC855E8F0B4505F930994DB8D2D2FAE014F3A9F57AFF729EBDB6
              1C0892B8D4F7A0449181A9EF3A1CA6F15B15BD6EB66CB12A72AE4DA6BC108AAF
              87DE83F4066506DE836AF89453B9B60E177C37814B1E1A49F914735FA22041AF
              67DBA716CD974DF2CC9084C9D0E9782C2964556B09F5F5FFEDBADC740C309272
              4B37BD07591CFF052C2E61F598788B72EEA14858805732E98F35012103A648BC
              05A84C0ACF198E963B3CA7F36A90A4309A0D217A287E60141D8A13D4D2E3A6DA
              523043050EBD8E32FCA683709E45B2203ACD73A96DA088E49987EDDBD42A344F
              A5D64C118B9F1635B398FB248E021C5C3986C622701B1B51E2DC340A8FC50633
              D04A63672CAC84A69F4666E2455A77201F0769D8A2039805CC44829B46193AE7
              C1F59B1FD90A4396EF6823CD930D7AD56230727561A5933B7A4C365D89D1E1F2
              04BDBE3E632233F1604171787EC44CD8ED3973E8DAE4F47461129903ABC58C73
              CDD7504CAF98959F95C342624568BEDA8A9D7B7F0EBA3BE29B095E3019A266E2
              85E78AD0D5DD83BA21E6C0E5EEC28A75DFA020DF8E258B4A2923C69596366CDC
              F2435C33918C409E2BB199C8CCB2D4DCF5F519E29983C3BFFC816FF71CC6D76B
              3F15AE2253BB7AB31A8C6326785151782EB99DCAE3E3F3C6CE6C73B9139A83E5
              D5F331A9B8903262D46F3B802B375A1F3113BCA8283C3783F65FBD392BB39A2B
              98C81C6C58B5186693913262AC5EBF455582C147CC042F2A0ACFD50F9889E7E9
              60DCF3F9B1AA76B839D8B06907EDC9D1282F7B8F3262DCE9F062D3B6FD71CD04
              2F2A0ACF9528226622277BD42CFA52183BBABBC91CE42193F6DB65DAEC0EBB0D
              D50BDE8749B07A37E8DF82C30DA7942E6F675C33C18B26030B1C6E26F4FA3079
              3DCE93833120DB4A5F4741BA3AEF2977FBFD72C44CF85D6BD1D47E2BD64C242B
              90E7B318FA4EFF3F662218EE6DF434BA8F9126121531133D3494F27B90E1DF3C
              14998499188A2C47BE12680AABF4A90FD143A1C7D9C88782F75D541C4564B154
              E0DFB14816648863264421117349640345EADFE2C7C1BF8D8D546031B11125D5
              9B3E35D21258B7FBF773D46045F93BD3A979623F15D215789E1A16F012354FEC
              A7425A029F062302D3E59917F81FBC227E4CB1AA224A0000000049454E44AE42
              6082}
          end>
      end
      item
        Name = 'Menu\Menu_Exit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000095C49444154789CED977B50D4D715C7BFFBDB07BB2CF28C88BC1456D1
              184645031233B14C663A49631A6B4C216AACA40F5B5F315ADF1A3531F115AB35
              5A49D3581F539BD1A9E36862B49934A53AA9202A62AC1260515916960576792D
              BBFCF6D573765DBBC2B2ACB17FF48F7E670EF7DC7BEEDEFBF99DFBF8FD90E07F
              5CFF077C547D5740DFEFB8EC6DFE72073096AF1C50BD071C48DCDF6BCFFC3836
              A9479927714BA7B54BDCC354822B1510C8787697CEE614EAA224A893B8C44F75
              F2CEF3B8F8592B859C642E3206F45950F164A18AFB0AE3C7CF4A6F91CB378852
              BC46F59025774A8EA9DBDBB756559DACA6AA9D8C41D98242F2A4A14840DECCD8
              2136C5461A6D11D53D9A38660426E78C85262D0909F1B1904545532BD0D6D088
              2E8B15DADB7A7CF15529BEADD353EB3D3924BB8C0EC35E5C3BD744357FD0800A
              0550A0E58C8BB7877F49FE5832FCE07B39F849C1F304154735AF5A4527D6DE34
              93076C1913833885943CAF0CC6561C39760E67FF71896A9E94DD6AB676FC0815
              271BA8DA43E65BFA3E1A085018953367824510BE1481A851A94958BE68962763
              BD55D565C72E6D0779C0324D243222E4E43D28CEE8DBDB0FA0BED50485D3D529
              17C5576E571C2BA190952C206430404FE692EDE1D50C97357A0436ADFA1922D4
              2A0AF51503EEAEF5022E4D0F0CC8E2A5DF4490E595351EC8FA2ED364DC3A5347
              A18090FD014A68CFC5C5DB147F237F6CD6680D76BC7D7FEB051403EEB9DD491E
              B0246D50BF803EADDCB88F20B584E4FAD668354DC78D333A6AB69139C9681778
              150890DB84E4A7E6EE11DD5838323511DB372E84A054A2B8D58617E20367B0DA
              C2805DE431600446AA03037E6EB4222F4E0997CD863756EEA4E536D309EF29D2
              9719DE018ADBA90B2D98278B1E4886E92DBE4A340D4A7915F928DAFA6BA40F4F
              C207773A09C2815FA4A8313652419107C5801FDCF102BE313C30E0F50E117FD0
              592826A33E83507B478FF96B7E43116050B3F959ADF6F435727910CE2243F601
              E4BA909C5D785894BA673FF7CC93583A7F268E3674A3B44D844A9060D3C848A8
              A4DCED4131FCDEBB3C36B0781803CAC87B5056A71B9BAA3B6075B931295A81D9
              89E1D85DF409FE7AE132EFC7CFEACBAAE603A526EACA279B01DDBD67E237C463
              74A518C9C7A1DFAEC52DA91A279B6C1EB8C5C3D448524A29D2570CB8AFCE421E
              5D94A9EA80802CBDCD490F62F140CE1AAAC2707B170ADFDC4211C068D24D42D5
              57D5E4F2933AC8FA000A49397366D805E1F8B8D1E9D8B27E3E366B3B61B2BB31
              73A81239510AEA125835DD0EFCAEAE9B3C60616A3846840706645D6A17F149A3
              0DB17209DED20CC29B6B77A3BAAE01E8B6AC305E6FF913EDC536EA2692B97A03
              4A7DCB3B6FF64B487B3A17071BAC88E181D20751B87F31E07E9D1770414A7040
              D6E6DA4E98E9C15F4F54E1F6D725F8E8E8692844E7D9FAABD717D26E6DA62E7C
              EDF40194A5E41616F7C0FDF4D635BFC48588A1A8B13A316D7018A6C42828DCBF
              18B0A89EC704E627AB06043C6F1671AAB90799113264B73760CDD6DF53ABABC2
              5872ED55E09B46AAF0D33A7A03CAE373E7D4D04AA77EBC731576B479A136A7AB
              031E0C7F69BB9D28D2DF034C5241131E78AFFAC407E6AD5AEF9E5DA8E8C0920D
              7B88CF5563EC287B1995957A6AE64BB50FA0223E776E0F953875681B56D47807
              787F849AFE06979632FDA1DE461EF0AB242534AAE0802CFFF1A715AE268F0E4A
              CBD7135093ACA37DC8AF257BBF80270F6EC32AAD7780ED9AD0003F6AB09107CC
              4B0C0DD07FFCE9AFAF268F004B4AB281F8BBC08576AA06CCA096CAE40F77ACC4
              AE8E3072816DE9E1F437B86A19B0D1F36C9837340CE92100AEAEE56D461997B5
              61D9A6BD743DBB6A8D65970A820226E716FE5D847BF23B2B7E8E33EA44981D6E
              AC4C09438C4CA070FF323B5CD8A1F3023E4CFF189904532D0DD8F0FEC7D4EABA
              6E6CB958E8B7C47D00E549D9738FD8A578F5A7052FC0342E1B37BB5D98F1981C
              1323A4140E2E7E18164F3A90AE743971A2C58E09346E78F925FCF1D8E77CCD7C
              51DF7D7979B043224BCE999D2F0AB2A399A3D2F0FD798538637660825AEA81FC
              6F8AE1AE5A9C981127C7B15D45A8D53542D2DEB1BEE956CD8960D78C144FBD98
              10EF8EAB271F5BDE5B8E43561594B45A0B12142165261471A6F71B44D8E86D5B
              A8B262EDBA9DD44A07C4DAF01C2A9AE855D7FF454D2850A464CF3DDC23457E5E
              6E16864C7B09E51617B2D402A6C7CA28FCE83A6972DC1FB3E9D4691497947B97
              F76AD93A60683DEDBF7E5F755C9765644C1FD3161B798D7CAC5FB708C72531E4
              D19772821CD18F98C536CADE6E839D3C20DF6DC6BBEFED238F36BFAEB940AFAF
              FB06B861A06A179983ACCFC702D7398B61E939AFBDDB25489726C4C460F2D205
              B8210A48A07772E163525A72EEF6F0B2D117CCA116270CF40ECE54B8F0CFDDFB
              61309B1166178FE8AE5CDD0B44135CF0CF2D16034A31FEF9A421F2C167DD5261
              74E6131988CD2FA0814190C0DCB8878764B8C3AD0CE71D437FE430B4DA3AEFDD
              27D62F4085E93650C17B8FB3E72463404FC67A8BDB043205C64D4F490E8BBC22
              0A8818439031AFE4A3D9294134DD385322048C5262405006BB6E75A3D4E2461B
              4D3B58EA86F92FC771F35F55F4910A4B7D635D3E221A75A84C20B8D03EF959DC
              4E1850A68D2B986C0F539E60484D5A2A06CF9A0D934446210A52AF712A0986D0
              D247516F36563B81B035D15256109CCD331510EB76E0EE81836834183C70E868
              5F52EFBC711535838DC04586B391D12FBD702C9AA25F7116794A151E9F9A1A1F
              117B02522183EAC879F987087F22130D6E2FE8404A943860BD568ED24FCF518D
              C4CBDA58BF184A5D236AA25AE9DA6EA356BE56188EB3775FC10059FF81CC9C9A
              94A41AB4D82E0DA3FF1BBCD24CCC42EA9359904547C32695C32653502B65D621
              42E9B4C3D1D686BACBE5D05E29A756AF3C07C261F8337A1A1B50194307E26227
              350784630D04C8F241860179111A4DE4E33DB151CB44A9F022B5852CBEE7DC4D
              A6037ABDB6961E81DEB33164C57C20F8C40684638502C86248363A7FA0A33149
              8D0C7562BC32768A42A67C56544812698A08DA021A8AD374AE5A7AA42E85E836
              D8AD96F34D8AAE3254D451B6E416404D192BA5D2B3DFE84C7BC0D8022A544016
              F765483606E58C929954B4A7C330DA2E87C321438D544A316084D30999CC814A
              394148284BB1B48CC554828DDA3C506CF70F4420F1A40F23EEEF330665183E29
              5C92E5511BDD431ED17D826206E0E563E3370397DC46B1FB1654F7067B68F97E
              C7251B8179C4BEBF7C00FE502C5F39A07A0FF85DE43F86BFCFF207F1F743D6BF
              01DC53E463AAAD7DBA0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_NewFolder'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000003C749444154789CED976948146118C79FD9D9C3B2B2365D23A5D30CFA
              50449005155404151511145D62D1A722BAA3E34B653796745894116187845448
              444411085D76D94144D95A9A96BA98BB1E89AECE4EFF6775D64DC7D5F45D30F0
              07FFE77DE675657E3BF3BEE3285137A747B0ABF40876951EC1AEF2DF09F2B1A1
              29DC6B68BD8A6870AF203C7282827662461A31356146753D25A31F8B04E28323
              3B6D0AC63AA41EF1204191F417946D931272308E45DAC5ECA94F297A519848F4
              A80A876E84053942F1173441904F44670F6DA1DEBD42D0B5E6B3BD800E9FB906
              414F754879D57CBB3DF31DA67F230D080B7284E12F688620DF323A7F641B6ADB
              A45ECEA4D71FED645694ACA2975FE2899EBB30CDBFAB20EDA17D016D0C88AEE0
              A9C40DA86D53EEACA46329E96A75BD5BB2B86B5617E6FCB84BF494AF220B063A
              31FF8CC36B96C37D40740577AF5F41CE0A5E5A444E5795AF2F47EF429862C72F
              AAAEF57EBCC3A8E429EC5357B7F2DB9B8C5738E4E5D4DE17FA4BD002C15A8C41
              45523C9F4A5F7E9D49F4445B1601AFA4AE60F4402B45465AD111D922AC34C8D6
              D847B6EA07A2EB38D3176F44257264BF1E43145E4C94C5CB42DB5CBAE80A3ECC
              38812A9E994B36A142B0ECC904B2477F8760250E5990AFA22EBA820FAE27A38A
              67D6D22DA810CCFE3211430136560546ED41AF8B8468F804EFA51F4715CFECE5
              5B512158FE2C8E72C3F33B2D78F7EA3154F1CC5DD9F87CF5179C72F37D94B177
              5F4FD69CE1386E8DAEE09D2B49A8E29917BF1DB55970626A627FF3E0619F3145
              46591EAE27A92B783BED28AA781624EC406D168C4B3F39CED46FC07D4C611FAB
              D31FCF1F95452DD015CCBC7404553C0B57EF44152078EBE26154F12C5AB30B55
              80E08D0B0751C5B36C7B1299C2C2C8143B686DA8756449E8D0E818C96CF12E78
              83246F52257A8BD68B2C5101AF495DC18CD403A8627136A874FCA71B5DC7E18D
              A32B78FDDC7E54B1B820985CC28FBC8ED3A6E0B5B389A8E259B53BD97B8B8DA3
              6CEB42ADB1257D86458DD46EB144D26655F5F86EB1D168CC6F798B7DAF5B5752
              F65230885FBF9798CE6E129F60DAE93DA862A9A9A9A5B53B1A9FAFDADFE2CE08
              E6618C468287E2C973389F2DE1B799B8F4A4F1FF22681A3C69D9EC06C59844B2
              61348E8341A9C55DB1B330C7FE9CDF07E32EED8B304544E562DEBB2178CD510B
              FC0565C442347900516518C5D48590DD26536C99FF673A4F6EB84A310E85EC16
              6CC4FE2EED8D7ADAED4F430C268BAA27C7F89F9C7B963423109D6AC4FDE03981
              C82AFE8F6E40C36BDD8D2808E6DAA6A5001F1B9AC23D47242CC3E1F73F0EF701
              112D209C1EC1AED2ED05FF002DA49B2477C1AA760000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Undo'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000064349444154789CED556B708C57187EF6DB4BF6929515778930D10443
              DD5297925474AA191A772364820E6550CAA0697454931894D1844186D0AABA8B
              448391042D6168D0BA054D4624AA49456E9BCDE6B689B57DDF8D8DCD1289D9B4
              FA23CFCC33E79CE73BDFFB3DE73DE7BC9F08FF73341BB417CD06ED45B3417BD1
              6CD05E341BB417CD06ED458306B3B4268DA1BCE42C44A2BEB97985A400EDDBB6
              82C9640CEBE1D23214FF32EA33C8BAE8F6C3475E6289E28808825BE22F2958B3
              651F344A05A223BE40BBD61A7D0FD70F7B02578B686E25F129D1446C52B0115B
              B0265CCF2C7C5F2613620491E0B4FB5002BE3F9C4032A0912BB03D32186D5B69
              CA7ABA790F02EE3E22594F3412D920B3C9C066ACC163E15666FE4C412289A63E
              366CDD8F93C957A8073892B9C8F005E8DAC505C5BAA258EFA963C371FB760E3D
              2A253E21BECC9CAD663B7E25D89035C4D732F3368A05F182D2B20A84844521FD
              217F1FF070EB88A5F3A79ACD95E874677CFA4C0A070C7428DBE401E72A688A25
              83D6B08CB9B525C3D2D68B3A067FCFCC3B289348030452C5623129F6E1A9D178
              DB6482EE89C9986A3418CEF7F7743946322FC44236C8AC1764A506BF65146C94
              49854532A9047C5B1FE7F3D9B70F9C6D4795927A3530199F9654565747DFBB93
              BE79F268EF7C92F858BCD268ADC194B45CAD5A25D7E4176A31796E289A125E3D
              3DE03DA837FC860F341B66A33AAD76F1E0DEF3638104034D61A32FAD02B5062F
              DEFDBBD849AD70CA2FD022605E18294D0F2E5113FC7D31D17F98D96859997ED3
              3B9EAEABE85119B19AF8824911D18C0BA9D91B1572D922B98394B6B8A849B6F8
              FE831C73AC942BA9C82E7C1EAF9B9B0B962D08341F014365459C9767C05C72C0
              95A08A58C764AD4146D2957B47344EEA895289D02497C41AB7EE64606F4C12AE
              A7DDA7514D36BF5939DF6C525FACDBEADD77461899E47A5A279322A2157C5BC7
              5F88FA56A5524D2F2FAFC09AC85DC8CCC9251D70EFD401B383C6A133B514F0CC
              F85981EB912535E02D693544460E48D1F4E6A030A945F3268E53FB0C19EAD9A6
              5D7B2F4747B597835CD1879E605F6C12F6C49DA25E8DC9352BE6C1BDB30B1EE7
              E67C3A72689F432473262D266D0D4201F8381E3C1D39AB65CB566B698C9D7B7F
              4272CA0DEAD514EAE58B67C0CDB53D4AF5253113870786024A5AB58A02569039
              319161A4B80AA281B6A1424ADF72484A39F489C6D979AE201239FE7CFE2A2276
              1CA67935F575F59773A154CAF5C7E38EFAAC0A89CFA28BC375952F8E8982D401
              05848C32A98A8E0BF3EBD8D1651B073C96908CB8C4647A5463323478369C9D5B
              94FA0F1E37A881422D1029A6AF845A79E4AE45DD070E18102D96483C0E1E3D8D
              FDF167480602C77E8029E3474057ACDDEE3738288C2A7231C97CBB5F30C8630E
              4AAB86326A4FE2BB9DDCDD7788C442874B976F62E7816364D0012B83E7C059E3
              543666CEF8218DF8D559629A4D6E3D70A2479FDEFD9244B4F0D075D1B8999E45
              3115D8B6E173D0252DF5E935BA3F7083168D72E2137ED916AC3D0BE8AB58B63A
              C0D567986FAC5822F52C28E28501AD9D35282E28F82168D9C711484B6383B4CD
              B519645A83E3319EC5843C31E58F254A957AE59DF44C7CBDE13B928099934761
              D488A1C87EF0E7D2C0D14BF60197752457595EB605EB4C0A3852BE62DD04979E
              7DBD16AA5AA8A7D1E745157A5D4280DF67EBC9572190CA7F84FAB6D81A1C8F29
              252A4F5DBB9F28154B072E0A8940AE568B5E1E5DF0D5B259D097E80F8FF1090A
              06AE17D0BC4A7EA13EF033269D21D0B91CE4483BA94677235D24429A948A6B2A
              A794DAE7B7AE01703CCEA4ECC4C5F45572857CE9DE98933879368524607F5438
              0C5515373E1A3C790A15A65C92CAF88586C073D8A4844846CD2D834D5511B9E5
              CC311B038E27893B73C34FA5713A7E8ACCED894D2409D8BE3E0452B138C37FD6
              980996A3C3931B039EC7E4D573CB60439C356E998D05BF2F6C3E10DFAEAB7BAF
              9CF47B0FB076CB8F2401CB174C47378F2E181534AD1FEE5DFA8BA4461BB4C076
              FEEB18B38640941DFF35E371A1B6B84570F8661A02EB572EACA90ED347BE870C
              D787C0B912DB0FFE57108892F8E43B9BC50E0E73ACAB83B6207FF7B490D91154
              BEB2497AED0C3615F8BB62AA10CAD8B3EB3649E58A49B417A292A2C29820FF25
              51E4ABB63AF0C43705CEA29448D5E16D27AAC94AEA1324E5648E536A2EFE6FD2
              60A3D06CD05EFC034697416E137DA55C0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Normalize'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000008A149444154789CED586950545716FEE8866611414590C9B86B947174
              445187E01206234C1C17DC90315194322E834B601403464512834140880B5312
              07955071DC62E206A81429B74683822268B3280AD834BBB22FDD734EC7D78260
              03093AF3235FD557EFDDFBCE3DE77BE79E7B6FBFD6C1FF397E13F86BF12A8122
              A2F04C4554123B0BEC572083FD0B6C01C1A8294416B68B6ED2231D85F4E0786A
              D7121B899D21522731F7690F6365FD62A55229CA7B94F3CD5F278D29A1FE0622
              FB6F21B23581BA16B66EF57485429ADA0F482AA5DB6A228B54117F29D4E24C44
              CA241D88FA511B2A55636EE2A56BF68B5DA7E653B38ED842646B02F548201B93
              C0A461406A01DD3E23F25B361BDC01701C51DAE3D2309158ECF1915720358188
              106F9494146FB71BBE241848E0189C1816A9010F7C191212C8D30A4545D248A4
              F6A4B74B784A4D16D86CF073083EB4891749B314834C0DF46531F18908D8138D
              DE663D10BDCF0F798F73FDDFB35DFC3570A398EC38AE92A8F125386F8A17024B
              AE5943D68B045E2AA7660391070BE0B10219EC546053F073D19D9CA283553575
              1FAC5CB703B98525F8C463011C278DA93C10B9D739C8EF87FB9D2D90EA29B787
              7E9DFE621515FB237946F4CC0913388060A30940A0EC3D1E64AC672C3B742406
              078EC56094D56004FBAF82A2407EC8E1EFD3439169463112390697168FD7A0A3
              02D581599C41BD51928E08FDA849BDAAA7D7AF5FB459EAE242B6EA20C28262FF
              E294ECE2F8CA9A9A898B577D86B2AA6A046FF6C008AB8195070F85CFDDE9772C
              1BE8AEA032AA245B4D0C01ECE065B42550272953E12FD6156F5CED1D4C4D6057
              E03F515555F5BDDDB0852B2810D72B8F571275A46905930D8C74E3A28FC6E2E0
              F158CADE207CE9E781BC27F97BFFB670D67E64F692035778A7E031EC9FA98176
              81C519A39021CE6B229021BE99559879273DABEFFACFC3A909B8CD76C482B94E
              C8C992B9394FB13B435D1544B6E797892F2C2E9BB8C627449DBD1D9FAEC41F86
              F4578C7B7FDA6C643550E6BA15D24B55922DDB3713C7E8B040695ACE643D7DA3
              B89DFF3A8CB84B3F510F85303244E8179EE8D1ADABCCD66AAA1390CC9B6F8D34
              FD91BD9EC43056B0759C38069E2B5CF128E761E0ACE56BBF458684B2975046B6
              5C162C8ED90C1D15284A4C971FA8AEADFD609957803A2323AD0622E55E36C68F
              1E0E5F4F37941417ED70B2FD470805AEB82E93DF551495F575275BC6BF437CD0
              B37B5785EDB449B3906548FB6B1FCADEB96A7AC4BE5B8863B45720D75543EC95
              14B36EE696B2F84B3F99EE8C388291430762CD3217ACDD18868A9A6A04F82CC7
              1F870EAC3879E4B083D3D4E9764626C6A1BB22FE43D94BA2ECD960F547F371F7
              76B297BBEFEA78C8BA53F65A5FB94DA155E0606FEFFB2289FE50BAD5E0F7FA22
              944447A16CE264E8F7B2A49E1750161522C47600021E56941737C094BA34B010
              ABB0C652F7B6EF832A03F23984BA9A40957C79DADBA3E8A605B40BDCB0E1BE48
              4FD24C2007BABCF5730C58B69CCE440BEA7981DA82028C576423DF663CF2EB9A
              27E52D8908534AD23C23F507AE78D927094C2181D674D3025A053699E267E72E
              DFEBD7B587C9BD23272FE0F00F17E160371AAB96CEC3AD9B3736585B8FD99C26
              7BD0655360048C0D0C11E4BF1A8545A510DAE141EB2116E1F67B2E0B9623B396
              A636B998DC73ED09FBE52BD15E8115F1377336E949747D3C36EC80BCB814FEEB
              96C2EAEDFE0AFB91335C4EC647CE34B330F70CDC1D85C4E474BC633D0C55D535
              48B99F0DD7E993316FE6649C3F7BD6D5DF3BE42ED0931687BAA65BFC30680DED
              10887CE06A6542CAE3B4F48C077DB704ED8765F7EEB439AF43A13C3F7CEE940F
              2301A3B28BB74E9E2A2D7B36D47BEB1EF58261B0DD76DA9495F5F5E7A7B93B7F
              0A5957CA5E12678FFDB7993D463B04363E39258DB43136EC7A263CF23812A4B7
              E032CD0173A63BE0426CACCB36EFB03B24B0F4DB0BBB275A9A5B1E3D7E2A1E47
              4EC7D368C0C36D362651299C8F3B37FF8BF561A9C05DCA1E9E11795B5112DB44
              3B044AE47137F6EFACAD6F705DEBBB539D9DAFB679A18B81FED5E94B66784266
              FA84A6AD9C4A4A14238DF85ACF407FCEC6CFF6D06860DB260F9497959E986D3F
              6F3B9DB76497584ADD354416D766F618DA05165D19EDE3EE5FEDE0649778599A
              6C121EF51D860FEE0F5F2F77E4E53EFAD26DC3B26F90CE67694205992360EFF1
              B7468FB53E2316EB5A51134A556365D4A1A8395161C71F02B7695306DBB53B7B
              8CB604DA1CDB77CCDEC4B45BF0F6D048A4663CC4F20F9D31C1F64F954EF3E73B
              21AB96B27287037356382312BFE083BD47588F706F68A897C49C3A7B3A72F751
              9A560BAABB04CAB2665366DB7641BB40A974EC69E9E9DD65E5157FF6DA12AADE
              3282FCD742A9AC8F9B6BEFE24BCB208F029791691D91C15F8312C0DE08A834A4
              7B820189BF5449376CD3AE85D1145A052E99F38EB3FDBB8E27BF3F9B8013313F
              E2DD7123E14E19BC75F5DA52DF8F03AED2F78A9CCC846913C02275896222FBE7
              67CC0E654E003B78191A81419B57869A99997FECE3B70BF2D2527CB26A11060F
              E85330C36DA133321BF29F6F1994A166C1D9A74006F70BEC3004274DA11118B8
              71C5573DCDCDD76CDDB18F5AC096F5CB505820DFB364BD7BC4F31FB2DA365CC1
              F72F12264070D2141A81EF8FEDE334D775D1011DB1E877D444634363C17747A3
              171E083B91FDFCA7521577137F95086DD02A50519C6ABB7AD62CD5B8BF38CE6B
              5429757F3C7BEE54E4EE635477A64574BA70F6EA882C8EF95AA05DA034710CD0
              853225A12CD550E18B4888119D63CD562583FA5F0FB40BA48D1A99A694B1249E
              4A16A124B2285E957C7D1DE0380CF5B52D81363F7F75995450BDB1201EC422F9
              CA10AE9D09F6C9E4384AAD02FF47B8A3F8F95F35DEBE1A5B15D8DBD6AD9C0ACC
              80EEDF3C1A95F71537D21CA9AC4AA855D39A403D221D55D6161852650455CFD6
              6C5E40A788A7A3732091A890AAA2FA36A0927AB540E1A8A2B3D49EC4B69AE5D7
              04FAE04102D75E3DF19553CC6091C259FAA64122D564A1AD2E1201FC8CF9A6C1
              E218EAEB7F015A630B7171F5CE6A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Smooth'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000003F949444154789CED98C96F13571CC77F6F66EC0413120AC12E525542
              23B555176AB75565A954D8AD54A9874AEDA5521A42807F00107000A42C122782
              14CE9C08663DC181E5427050582220C48808B14909481070763B8BB1C7F3F83E
              13A3309ED893C4E320948FF4D55B2679FEE4FD9E5F1233FAC059149C2F33094A
              48FA1947346441484B4C47727A37DDC12316EE68F915E3D748125910492341C5
              E9AD4DA0A57047F71AA2CE6174271121C9918262246883601C2D043BBF21EA7E
              856E1451910F42D00E4151560A8F75FE40DDE52F88DA22180AC1829739BBE0D0
              0D373D7241B07D14C345412316059B0297BBD0D0EE9ADF3D680CF9ED42CF0699
              D1D3B6BFD6F6920E4B05EB8E5FADEEB7151D9B90147A652BEE1D939511BCA41B
              8F3280C8882CCB1EBD24E6339893E0F49DF25DECA9482693F532D736AA0C7626
              80C82804DD9608369F0C56A82AEF4197AE2F73D5F72B458DE8BEC3A1A943C80A
              89F3D1B0527C0853EFC1641692991CD2CB0918A267D6820703C17F38F133CFEC
              4BA96BE94ACCBCE5F3D7E3B4428BB5542A13DBD5311EC2D41ADCF58DBB6BFE68
              2093E445B029D0DAF0CC5E529F96C3A2910D91BED2B264821485ADDD51E5EF6D
              0A047D900B125024E6D951ED17C239C15A19CC5A70CFA9ABB7DB4B3EFD095DB2
              718D7E1E1F38E14CC4FEC7B0056772334D7130D07A8813DB866E08F31EB43961
              889E5909FACEF7B89996B89360526A2D5FA48FC4CE09F43BD57C26B81CA56E23
              0041379A9CA416D5614A50BC6B8765FB92F652D76AEC4A29A6E88B78F4E4F7E3
              C355E80AAE40C247F3644E82CDC783EE41A674DD2C5945E28E137C3739F2E0AB
              78B44AD57817865898FDBBABC67F16DD793127C1EDA76F36DD752CDF85B26244
              54198B4270A851BC3BB1B3214C992E612E4C09FE72B8FE13FB4AA7AA389669AA
              A6D512E70D3485B84A3C138358283F3BA627A7E0D77FEF55CAFDEB6F6398814B
              9DECF046FBBDE8BEBB4E28CF98125CE55FDFCA89CA309502BF15E8DBD848B8F9
              3FAF2BDF25D593535094B8EED8FE2B7D4525A5CF8B1CE756C7276D95B1C856DC
              772D90DA4C16C3103D1982078E365C628CADC314314EBD9C518524B12D3BABFD
              47C8624C098A77F181A397F63126D5613A8555674E8F69410C55DC7FEB70CF1D
              2180F25A72E6F464171C7CECA1C7F2F3B420A22105E5A31114FF172710DC36A9
              140C13828433787DBAA0D5A45F23D566171CB8F6233D297B89CF67A2188A128B
              6F12B112B1BE88384E5A56C105E2DED4A76A31246928F899B776344E548C7EE1
              496A0FC3B7EEFF89AA0D61143312B4210E22B793BE9C70102F37FA1A1C8E0151
              86FC62B773EAE6384AC563D904C51F790AB284C80759C35DB608193F749B387B
              0964C6120B84A48CCCF4DC4A20998A10357C93A411CF440A8D9013A4DA377D5A
              3F537CBC273A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Trim'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000007E249444154789CED570D705457153EEFBECDFE84A4410A4B6316DB64
              ACE810400B9B0969E9A0B53ACE9822EDB499404242B51D28D4B15AD476B4B5E8
              A8D42A50EAE8B4553453B0A96D69F9D3B6A0CCD442C92694C09248167652B321
              C96E12F2B7D9CD7BBBEFF99D076F256537EE2663ED74FACD7C33E79CBDE7DEEF
              9DF3DEBD7725FA80E3238153C5874AA0347FFEDD859AA688D3A79F7B17BE7689
              3A980EA4E2E29A228B4515274EEC6A27A238C8B9CC9490C0746088EB99163F67
              251AB48C8D2E6F7FE7CF8D882B202FC4422782985B527DC305213C9C3F7D44BF
              D9EBAD6B435C0159203329D21528E6CDAB2A0AE5CA3ED8844586ECBDD12F9F3D
              5BDF0237024E24D2101716E220D4E4C1A7ECEEA165EDEDBB4FC21C0127CA4D5F
              206899B578E5BD92256B3B6C92E2DA3F7B22FDB793777F006E148C81EFAD8444
              4BEF9CE954B30FC25E00A26691C782C75BEA89BC4178C3600C9CB2401E27838E
              82D2AA6D2AC96B605324AE79863D2DCB899A86E08E815C0D53A404CAB9EE9ABF
              39645A0A9BB2E26A7DE78586C7E96C4E3FD1893E84CCEA9B3957802749175CC5
              2C30C7E5AE7A4691E515B0C91A8FEF0E787CEB888EB1487431510DE12AA9DDA1
              08BD1A365963FAFE40E3B11FE11907210E028DF6AAA0393E293211C86359A495
              E6DD56303B3B6FAF2E8B4FC3273DAE3C14F2743D4B74D85C945CA5D5772B249E
              86891AE9BE607FF75A3AD7759E687A1FD19B3C4E01595CCAEA3178D14CC0E3B9
              D5565AB8C2E5B25DD5A408CA814F562DB62AD0B0F3AF302305EEAA725596EB61
              234E2301D5FF357AA7AF9BC8097187CD4AC7C109C53178C14CC1392CD25EB8B0
              A24CB5D95F6291D6B836ACABD14A87C5168E5AE457A0208FC5E9EAF07D9D6A5B
              33797321EE28DA6B7C50698963F0629301B71A22BFE270BA67DC43B2E509F864
              25EAC68CBAA2533E5C2888FC24D41778897C6378E79C03447F313F0A6E6D5A98
              AC40068BB480D3662D5AF56D29CBF203D80948B1C8F69EC6E63AC886B8531710
              0A8331306D718CA908E45C260AB734D7557A5D233E8A4FC04740EB0C845A2BE8
              DC18DA6A7C14BCDFA1EB28EA45A60D5E602A10A05CE4AEDEA415157EFF9AF2DB
              E0A2CF7BF750D8EFDB16F2789F44F5209046C18C5A6B622A02395798DB49D186
              FBC9327D3A42E8E3C000F99FDA4EBAAA3C1C6A0A3CFBFFAAA0F85459EDA2514D
              7F032BE77D72E3777561B319F3C5068734FFF66DC2F8B295C8CACEE617DF42F8
              7D7D0705CED8AB5D6AB68FC5C1A78F952EDA3A73D9AD1524096DF0EF87EA826F
              1F7B086162918191FE326AD5FEF57E7DC5122DABBCDA19B51E82BD004424F2E3
              60E8F86E3A9B3D403483DB49CEC5F96BC8627D1C262469678291FE15B85874C0
              FB9FED833C9629E694D6BC3C46540EFBD219DBF028761C88F35E4088ABC470B8
              DCD538B3C5EDB0314E7B25D0D8B18EE8303F00D28D2AEA979812BC603AE0714C
              D9B5A4660B36E2F5B019C7836FFBD6E2DC1F42E5FAB0389FB1C6590C64112DCB
              71955E7B00AF811B3ED9F4785DC731FF46A223E638B392CCA4E0452702FFCE14
              85C5959F8F39ACF78CC974277C4C8D0B40A47B3DC53BBAA875762FC44164A232
              0C01DAF8CC765A73F6902CE6C2E777721F8DA8BF0FB43E7F082EB4273E1C16C9
              1C075E3C15F837A9A0A4FA0E49886730531EFC04B0505891C29B820D675E263A
              8DEA25BE527311CEB7B86EA8BC8B2C96DF2842E4C04F00BBFB90AEC6BED9D9B4
              13F98650AE28E73213E0499281E392ABA4F60FE67DAEA8E01A0A047B6111E5CF
              9C41EF7605616121E33EE8479B8FF0BBC50B713518E3EE83D7E63BA9ABB71F16
              AE62CE99E4EFEC86857C2DFE62A0E1B9B530F901399F05320DB09064105C3955
              881772EC0EDAB8BE92CA4AE6534FF0E202B39D33E848C329FAC5AFFF4423D108
              E9E1C886D0A9179EC74FE6BB4599E4D368747DF0647D3D7E32F3CD874C2A9063
              B2ABB4A6178F93F7E8036B6889BB18A12B71D4E3A5C7B6EC4015B1D7799A1712
              9DEC4598B7115C586B4293CC87E2C4C76388792F44E18DB5B784E3FAEBD7CFF9
              386DFDE90308A5C6B71EDE42BE8EF3649546BF1138DABD878FB5C2B29A9BC31A
              BD36C9FC218413554C26507696547F8784D8BCFCD69BE8EBABCA114A8DDFEDDC
              4BAFBEF10F5CFBA35B431EFFAF883C03B34AAAEE9384FCF3CCF3DB7F89FF36FD
              089BBB819E54201678901728FFE28DB466E557114A8D1DBBF6D1DE836FE16FE8
              D8933D9ED3DBF8F632CBBD7A9D244B3FCB3CBF652BDA1C4298DB9C5AA0AB74F5
              9714920E14CDC9A7CD8F6C402835BEB7E929F2632BD46383F7871ACF1D608105
              255537A942DE9779BE7F7F5A02419BCB5DDBADC87AEE836B57D2E2CF7E06A12B
              D178A2959EF8ED2EBCE4140E0C786F219F38CF2DC64F84FCCECCF32D9DE9B498
              4F80AC82CF5555A836F98FBC4DDCBB7A392D5A387E91A6E6567ABAEED58BDB84
              3AF84870B8650FB5CD8640E3EE47C8BF6B92F9FFF523E11857910FFB1D38ECEF
              806D6CD473AFBF8E18677CEDFFD96895F8EB8191861F529B1DAD31B609639B01
              EC93CC87E289B71986514530C7B9A0A2C26AB76FE6BF96F013E0B628DAE0663C
              F96BD4E6405B9BFB1036375AC654F28DEA315209E438D30A4EC3B5EF2AD792B9
              5F188B896241B891EA515F68B0C343D270144F8E969C04C71D558CA9E4330DF0
              24A9C0BF31B9125868A91DF93674807DC08127B5E2657E935BCA13C337266632
              3897C9E327936F80279808FC3B935BCEEF25936D06B781DF1526DB3C31F37270
              2E93733897C93683733897C936E732C78193D3018F3379397842931381F34C5E
              0ECE339914FF06E9F0E95636BFA3C10000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_BatchJobs'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000007B449444154789CCD98795454E719C69F191810B4127A723C4D82A9C6
              636D5A73B4F5D460CFE989D1C46317A9568DBB6C6E24C18545F61D0141418A82
              AC2208B2090A685B164DEC3F2E4D9442B5801A2D349145186491C561F27C7361
              748E080CCE1F79CE799F7BDFF7CE707FBCDFBDDFFDEEC8F003D7440127FABDB1
              A466E86822279233C4F7C4D6901A640840B1D54A9C68BC129F954D5F646707B5
              7AA5721096FC73A2F6CA32334256F3959319DCED67A8185AC8F19E407C4E6665
              BDD9A11F46C9534CCD06E7CC7A4BCEDA2BEBFFDFB5A81EB6771841F5D4ADF97A
              560A4B3D0C2DA438F16812C7450818A3E9D67695969653AD7392438C981B4C7F
              DAE431D8DFD37DB9F1FA2D5BE0AB472CF53204A05A9CFC6512C764568BB6D873
              285776A8E496164678CFDCDC6CEAAC196FF1D0C4B5ECC3F7B16CF142EE49720B
              88C357FFA9BDD97CB56A0350FD1D4B3D8CA78C1101876B720EA9BD34A4A68333
              DE7E4374F19575BFA1095DBD4FE0E9B491A00B59015CFD8FE2C67FEBAA9A3BFE
              B519B76F7FCB5227634440918B10432886B462AAC514EBB87037911B4CDB5C22
              F0ABB9B310E0EEC80C700F1080F555CD5D37B6A2A6A691A511016558BAF5C756
              9DF218C8D536BC9D2C583388165BCFC7E6D5CB616E3E89191016930E85B11122
              033F6706EC0F1C1FA09C1D3BDB07F50AEE1B5C8B17CEC3F62D2BB9071C884D87
              A9B1310E067CC60CF0083A2601B65DB5455D5D034B23021A4FB3B61DE0164702
              9D317FEE6CEEBDBA6ED6D4636F601CA64C324342A41B2B40F85F333480E1FE9F
              3203BC82E3C7056842C03E6E71293F966E387DB8760F1DC888F5A5031171991A
              C0303F2766807748827E8017F38ED00DA7259FECA503E9313E7420F25826AF41
              05C27D2540AFD00454E90358911B43379C3E5AB78F0E9C88F6A2035147B3A030
              61077D2440EF0302F0CE9880A604143338CA730C0BF8F17A0930F590271D381C
              9F0D85C218A13EBB9801BE078EA3AA560FC0B2D3D174C369D906173A9012E541
              07A21304A00221DE3B99017E6189FA01FE3DFB305D57FFBE7507DDDDBD58F49B
              B9CCF4D3F28DAE742029723F9DB344FC69284C1508F6DAC10CF00F4FD20FF06F
              5987E8BACA3E53A689850BE6C265D73A4C996CC6EAF8F4FB4DD2F49218216DA3
              8FE7621201033D24C0C0837A025E38353260E9DD26A04389A7CDCDF0DB6787F7
              7E318B47C6D61F364B6009E1AE747630318F1D3446F07E09D03F320935B577C7
              0F783E338AAEABD38565F8476B1F2C3FF800ED5F7E89B6CB9761B3FC77D8B0EA
              634C1EA39B7FDCE24E07E2C35CE8406C523E046090FB7666404054B27E802519
              91745DE51496A3EC910428D4FFF021DA4B8BF19A420ED71DEB30F3A76FB23AB2
              566C95AEBDA3A1D27C189772460318E8B68D1987F8508A7E80C5270FD2759553
              548EF247FD5A40A1C1DE5E4D3795D7AE613D3BB96ED547ACBE281B5BE9EE8D0B
              D94327686A01EF6213F8BB3B320382A3525153AF07E0B9F408BAAE728B2A50DE
              A60B38ACDE07F7D19C978F77D8C57D3BD662DAEB96AC3ED39FED3CE91CDAE0DD
              740E751A3B48403F37476640C8213D018BD25E04CC3B5B818AF691018544371F
              1517A3BFE101763BAEC5C25FFF925549AB1C3CE9BC39B808114A482BE4102BE0
              EBEAC80C083D2C00EF8D1FB030359CAEABBC7315A86C1F181DB084800F1EC0D9
              718D0EE05F1CA5475CF4D0F22AF14411014DE0EDE2C08CEBC3E834FD00CFA484
              D175957FAE1295CA910135439C9F8F99D3DF60F7D6BC30C4ABB779D3F9881B5A
              5E1D4F3F0B8589097C5CEC99717D187D02B7EEE80158907C80AEABFCE24A5C54
              3ED501145D6BE774A3BC7A156B6C9660ADCD52565FD49AEDD22A266A68F59294
              714E03E8BDCF9E193B18A327605E52285D5705C51771A9E319A09866DA4A4BC0
              373D383BACC60C76EF65FA64872F9DCB2C9F9D742039B39880A6F0DA6B07A1F0
              23E912E0184B7E2D606E62285D57674A9E018AAEB5717A59BE741156AF5882C9
              E666FCC4CBB56EA72F9D0BD5A1676FEAA912CD35E8B1C70E42076305E037E307
              CC391E42D79500AC6868839A8FBA81A626B8396DC4BB7366F2C8D85ABFCB8FCE
              4E796EA7036959A51AC0FDBB6D9989B7BA23AAC7AD8FAF34745DDB35DA6BA716
              303B2198AEABC2D24B2862CC9FF77338D9AEE21BDAE85D7B5E1B9DFCE9BC193C
              B6D1D9C1ECF3686E51E26DAB6968696953B574741AA9D11DD672A53673B41777
              2D60567C105D57B7EBBE41CF935E2C98F72E33FDB4E9D3003AE73B77073A3B98
              73018DF7BFEDEE3792DD23835AD6D777BEA9F3EB02DCB1681DEDA70F2DE0A963
              4174C369F3671260B09B3D9DF36162AEAA47D975ADF17A8D27F0A49BBF113C01
              267511AE838745F7540C01C897F567D202661E0D8421B5E5F34008BD33FD2768
              533E56293B7B8C647D3D114DDD5539A8B36803AE0BA8BEA1D0C2093D0F684240
              F1019C8C93FE6343C9D639882EA4AE6670487B2F34DDA82E60D7389C37DB7940
              9C575C73024C845632C6B0B4805ECE5B3167F60C1842B5F5F7111E97011315BA
              1BDBAA6D70B7AB93BF11B063A61C520B0EE917DCD7C0A98742473A8056D6B667
              FBB942E7BEC165D2AF2A6BFCFA9E2FAFB96682F1BAFB425C4E3CDDCBE1849E07
              34C682156F5AC92DD32093BDDF2FC714D60C220DDCC0C32854B7FC0FA86A6569
              B86B623805988811F53CA09C6102FC762AD0FD1A664F36477DAB8235197E469F
              A8EA78F2D9AF0FA0BE875DFB9112F8278718038C61B851F53D2DB9EC56CCB010
              340000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Benchmark'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D00000A2749444154789CCD987B5C54651EC69FB93480C97A278901314049AB
              2D14C4142FED6A9AB18A99998A90FAF192959B614A19255968B2E6655DC4944A
              8DD44CCC4B96EE2A96A682A2A222C2209719150653AE016798997DDE19078D65
              60D0FED8EFE7F3CC79CFEF7DCF39CFF9BD97F3820CFFE7FC9106EDDDCB4CDD33
              F66EDA1AC43D6C92537763A284419B5A8DB8E9FD20C3B3D33AA82BA43099593E
              BACC840E8C092B3267C8F6962A6F6CC6F1BDA58CD453C2A050ABB85F8372B7C0
              8837A1407C4F2F0FB469EBC2909533591AC0581FA54FFF2A89A7D5543D65A25A
              C5FD1814D72A3C82230E7B7B3D3C7075DC3C9EDEE18DE81528CCD71DD1A5674D
              014EDF64A8963252ADCAA278C8BD20AE13527A06471EF2EFD97DC0E28533787A
              87F797AEC7B9ECDCB3FA93672702174A18AAA2441685412187100F692DE21A31
              19149E8193C2CC4AE5A73D7CBBBBBF17358DA13B442F590B9DF6DA35437D6D7C
              C9A9BCADCC6205C31265BA2D874C8A87398A682B43C88B9DBA18DACC75025EE3
              D3DA3166E1118FAE70767166C94A96A6003654408564C467FA7AC31A9C49D633
              243269EB6E21BB88873A82682757074F7E85898BB7191313A36FC0A39647E4E4
              6B61AA17CF04EA24037AF878C1C5C509A7322EE172D15546AD466592F4776D46
              D9B7C0FE3A8684D166B329A35A42B4913F141CB19277798D65F4E9E58BF0F123
              F0E7DE7E3C6B99731773B179FB0F382D663691C1F879C9892DF359FC8DE2FBDA
              37291EDE1CA25EAE0E8AFC5C929BC359C6C2D913317C68104B568AF537713CFD
              3CAE97DE447EC1554680EEDE1E70EFD211FD031F4757B78E8C583970380D4B13
              925962368DC6145D7AE14CE0673179EC9A9451F610757275FF8855921973DA3A
              BBE01F8BE7C0870F179CBBA841F28E1F1BB22210E35070E56A317FAD886C4F1C
              F72CB3EDCB33EB75EF7F9284AADA1A38998D9BB4270BA39A33294CD8438CB9A9
              12149FB18C754BA31ACC257EB90B3BF61F81303DE2997EE8E5E78D477B78E36E
              2EE514202BB7003F1C3A6931336EE4608C1939080F31A39934F9D6876BD98A6E
              AA6B5E2B3DBF7D2B8BC2A48112261BB06750CCD6CE6A439B5CBE56BBF9B32660
              D8606BB77E9AF035F6FF948E5EBEDD3073F21874EED49E51FBDCF8B50CCBD76E
              81AEF4579E019B572FC243ECFE8347D2B07CDD5676B5A95257563C08B9CA2B9C
              38356C524F3564B129832226F3098E88AD04DE7DCADF077131AF3204ACDFB40B
              3B7FF8192F8C18C46C0C66A4658E9E3C87C4E4DD2C59193B220433A68C61896B
              65ECBF70263B0F4E526DA23643B3986B6519C362769B6FCB62A63122A6540747
              948AEC7DF2EE6C3CDECB07E7B3F2F0F64709CC9C1716CC0967939639969689F5
              5FEF61C98ABA4B274B261BDF53653255E9D2CE070067F56CF61BD5904561A631
              728FA0F0170C72F9763FAF87B1EAE3790C31954B12905BA0430CBF189D3B5A96
              C166F985E6366CDDC79295E91346A10787456CFC46F879ABF1D1A2D98C0273DF
              5981DCA26B1C79556FE9D3745F0127CB19666EAC63B12983DC0044AE36C0FCEA
              E4B0617879EC70947009993A2F0EA3870D40E8B303D9A4797EE1B293B4ED7B96
              AC4C7DE9393CCD2547B0E7C7A3F8EEE03124AD88B68CC5AF771EC09694837032
              1AB76BD32FBECD7DD00D36ABA58441735306C50620B50EE60171D133F1D8A33E
              D8C371B73E790FA2664EB07C219AE3F8A9F3F87CFB7E96ACBC327E24FAF7B59A
              13E4E415213E712B664C0C45E888105CB89487E8B8445A317263913901C82C66
              B36ACA483569F001B7E0700D7BDA6B43FC02B8F12D57AFDF8E7F1F3B6D596AEC
              A135CAB1B702A8ACAE817EF76E5415152272DC0804F77D8CB5BF67D6C2788C1E
              3E10D3268522BFF01AE6C6AC62BE4C1A7D45FA5864675F65934AAA9E6AD2A0CA
              2D38A28E477CF7C552FE023171EB51565685057327F3AC6936563BA14AA66489
              8B59591942AEE7A05F9FDE3CFB5F96ADDA82F6EDDB22367A06CF80D1910BF90B
              E86F1C0B8046AD0552F9AA9635B17983294956831F2CB31A9CFFFA449E35CDBA
              9A076190895D18BBC0508759AE124B4DB37C4DB2C5E0070BAC06C3A6DE3678E2
              4420E056C82F4B394FEB29938C3F8D1106F37854AF5BF636DC3A77C03F377E83
              43BF646075EC1B0C37CD5593020724679680E1AA5A78C88D2C35CD1B31AB11FA
              D70178E5E5E751C0193C6FF11A8E38D3157D7ADA4B0E195407471E96607E3A36
              6A3A7AFB3F827D62D66DDB87D723C3E0C325E27EC8E352B5E68B14CEEC5118C5
              55E162F615C4C46F608D29537FE378A4235DFC8067BFC8357532F3CC97429FC1
              8B7FFB0B4A6FDCC2ECE8788C1C1488614382D8E4DE39989A66F95426C445A10B
              7BE79BDDFFC1B63D87F8C9337EABAB3CB5D89149A254074D1A2FC9955F3DE2E9
              8EA5EFCD6108885DBE11055ACEB8E92FA2437B57465ACFADB24AACDAF00DBC3D
              1F46CCFC698C70FBF6E15A5CD15E87ACBC6251C9A5BC1D8E2C330ACA591D1879
              5D52985DDF9F370DBD7A7647D6E57C2C5EC1AF00BF2ED3C343D9A4F56CD8BCC7
              F2D5687C4F9511D5BA5B97864163B8E6C8422DA6A2CA2770CA87950A59D463BC
              D1A237A73204EC6057ECD87718C343FA60E8C000461CE7F0D10C1CF8F934C68D
              1A8A711C3A82259F26E1024D3A19A44DDAF2F495D074A2C1963F7522A6449F50
              77B5BCD30591C5D953C210D2FF2986B9A3F97227524F9C851FBB7FCCA84168DF
              CE9551FB94955762D7BE9F90CB6E1C12FC2466448C6594F3F4F819246C4AB166
              4F2A7A01E76EE603E74A58F51B65197F94C54C63444CC8C933E0E509752A5512
              CBF8387A16BAD1942065EF61ECF83E951B561582027AA3BB973BC75557D6DCA1
              405B8CFCA2EB48CBB8C80DAB8471CF0D41D8F343592336B3F958B2F20B583094
              C7E8CB2FEC85A65DB1A3DB2D81882B81912E1EC11D5719A08C14BBE777DE8C80
              97DA9D5540361FB2735FEAEFFEBC54F3B328D0717361A397AF37C68E1A02FF1E
              DD7966BD6E65E2369AAE61F6A4145D59CE32E44AA5BC9A63CFB10DAB0D39F500
              D556DD377C83A4948F61D9B28B1EC8AEB22176CC1999D99663A18E4920DDD45D
              2D3BED8027FC2D471B47393412B7EC6289835C321ED055E47C004D2DDF2693E6
              5AB7E517883A61520584B4F5ECD72DBE4EA698C2734B56463F3718FE7EDE7084
              ECDC027CF7FD91866CABA4BACDBA8A2B09D0D4DC02DAFFCA1129CCD9264643F6
              04C2447388FA06935D1E771FEFE4E2B25492A32D6396BFE29E7CA2277AD2A88B
              B313BBDF3A0E8B98C99ADA3A5CA6B1B399971BFECA13134232952FD35766FD88
              1C9732E04F3468DF9C40186809D1E6B649B481DF304F4FD78EB3CC4AE74936A3
              2D218CC94CD2B7DAFAE264546BF5D0B4A1B9CC0A56555306AA497302F1704710
              ED844925278E13F71D0F722CBBBA05F93EEF6476E95727470F7ED65DA190FBB0
              0DC4879FCB7D95CA68CE3554559F29315C3D04DCAC85E6411A52567243C0E31F
              F7AF0F1BA2AD9082A25191D17ECEEC1DCAE80C7F4985FA7A25340A510FF81A8D
              502AEB91AD62F7296AD99C3A4959BA5318B37CCA6ECB2EE281AD455C23248CD8
              240CF3388459368A3AA2E08353457684119B219B5867518BDCBE59ABB15D278E
              8D7537C24463096CC716F92F7C5B266586ABF62F0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_NewMaterial'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000056C49444154789CCD987F6C53551CC54FBBAD1B13B6E17E219411C220
              1815B638608CA02402CA0F330D24C8603F244434590415352E8811C91215150C
              894190C84F25617F104114300C8950D880C144601D191B5DB2BDAE5BD94AB7B5
              6BEBF9368EC0ECDAD7D13A3FC9B9F7DDF3DEF64EEEBBEFFB6EAAC1FF9C870928
              7F2B0A06CF3F524DB037E8457B9F8440FFA73794FB3EA922D03FF6853625BBF0
              32FB2729D530E135B341C9068E7671D843A90A196C40B93E82019DEC31343915
              1812C323FFD81AEAD9028AA1723C90A630A49D4317C5DCFED150C1208F349201
              BB25DCA855AF711898C66DDFC2666E86623166C2A83301E5EDB455CDE2C003A6
              8DC1A882020E03D3B87BB777161583712A87F5C0192BFBB0058C62C0AEA0026E
              DF0E5B731394D6B3D35093748B01EF009065E2A6FC32E080EC31347504101DCD
              23FFC8EC09FF79C0CC89E3D806E6D2F59B6C0721E0F11FBF621B9839AFBCC576
              10021EFBE14BB68199BBF46DB68310F097FD5FB00DCC0B79EFB01D848047F76D
              621B9879CBD6B21D84803FEF551770FEF2410A7864CFE76C03B320FF5DB60C68
              F9331BC6C85BC03929D4610BA863C04EF6C197196FC061F5FCD449400715D280
              72AD6674CED2428F267AE7A37109484A8AA7159896963B686DB7C2E1B27DAC18
              1AB703675B697753B25910F58BDC542D722D7732F99C0E6DDAD71BD620393181
              5660CC162BDE5CBF9947EE26C5707166303B1AB9A95AB413B20AB2ECD1DA73E9
              63D350B2BA90967A4AB7EC426D5D033C0EEB92C60AA55CED8BA236A05CA7D54F
              CB3FEDD068A79714E763E2F831B4D473DD588FD2AD7B78E4BAAC18AEE672655A
              3890B52C013D944FE4C66AD022E7E524BD26BE392E6E1836AD2FA6153C6B376C
              457B7B074CCD7539A83D5543AB83F2BBED521350AED1EAA714ED72447896AD5C
              B200395327D10A9E33E7AF60C78123D0F5B88E982A8DAFB3DCB4D296974502FA
              9C45B97920E49A487D76A14D17A5D3957EF80662556CF37D61EFEC42C927DFC0
              E174384D868B9380EA66DA364A66714001E5BC2679C6ABEF6B5CEED21767E760
              E19C19B406CEE1E37FE0A71367E071B9B6982BAE7D0A5CB0D296599480A20790
              00FE90F3B2C5BFCD3E75E37B2B91383C9E8703C7D27607EB3EDBC12377AB62A8
              CE06AA58722025A7870A3A20D75EFE4B8888287B3AF3712C5FFC3CAD8767EFC1
              5F71E1D23574BBECABCD15F507B816A5E43828598B0FE02FA09C63612EA8E4E1
              E4D52B16217DAC9ED6C3535B67C2969D65AC38EE1B4A45D57CAE45336D2939FF
              2ADC12A23FB4932717A45B86686F8C193D02C52B17D30A1D5B771C44FDED2644
              DB957937AFD83909E552729CD403B3D85F40F1B5FAE945650E8F27372FF73964
              654CA4153A2AABAE63FFA1DF5872DC274D957F15F165B100E8A224E0BD599420
              BEF016E614775C63C2B04722D7AD29A0157A366EDE0D6BC75D9762699801E349
              232D1BD543B9292FBE028AA7499D56B8D1A3C10773676661F63359B442CF89DF
              2B71EC74253C4EE777E60B751FF9DAE54898BE88C797A3D0AA8B8A7CA4A47819
              6262A269859EAEAE6E7E9FF7B170F7742A86AA0C606453DF5D8E84E98B362323
              6F5C4B8CAEE6A927D2B168E1B3B4C247D9E153A8BE5A0BDCED5860AAB69CE7CB
              D24EBB87F23E669F0129EFB65E9F9C885545B91C868F6DDF1F82C96CE1EF3686
              29406203BFD852139D94DF80F2F5A8603F499F381CBAD8F03C6287BD1B264B1B
              1FA8AB4A6933AC40ED63FCE5EBB404F43B83E24522336F644A64D431446002C7
              E1C3853AC5C19DCDE58E06CE20D760F95DBA12D04379C3F4453C11A76D563CBF
              9E0948EF8C456D0AA3B6881F3A6A923C48575CA81DC21723B6EDBE4F9E841379
              83F8427C2DA50366312867140E1987019D3C4ACE58B914E9DEB5E70D274890FE
              9073A2084A7A51389030A2DED222BAC7DF4F114A47331614470000000049454E
              44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_EditTable'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000004BE49444154789CD5987B4C9B5518C69F761B53909B54740C06431937
              C7C5A601D4091B7373323061C368E2C0C4A8890E59A253879A3170D1CC445998
              71FE43C27004E32E882604DC9C461D04848148100873956E5CDD2C05620B6D7D
              4EB5A458D652DA2FD15FF2BEE7BC872FF97E3D87BE5FBECAF01FE77F27286A11
              7286184558B19D2F1733C38AE99F106B2216C5F6A63264E6DF1EAA937F00B939
              C700F8734D125619517B15FA57D1563BCE72966115B5C356501E96FA749D1EE6
              6CCE25C7CB683CAB69533F0F7CA763C9FDB048DA612BB83238B5407C1A941F2A
              44D2BD519C799ECE9F07B0EF6005BC4CA6294D6BF77DC09A51A061867F3232EC
              76D156D08B827A8EB870EA28B3746CDE5DC40C8C5D6F4E427FBF8653B18B6273
              9626F8F567E5CCD2B1256F1F33055B5A5440B09AC7AC6539C7B03B6619C3CABC
              E0F1775F464B7B0F67CEF9FDC624B3194181FE1C9DB327EF11643E6E156C4E01
              1457808B4250ECA043C1D514FC9323EEE2CD921362E0E37D0B2BC7FC32A06636
              23262A02CE10D72A93A25175AA911505AF53B07F198271F78423F7D174AC0F0F
              61E5982F1ABF6706B2B73FC8EC1871ADBFAF0FAA4EBB2998961C87E48D1B101F
              BD9E95631ACEB7309BB123338DA363C4B541817EEE0B6E7F4885A0005F281363
              5839E6DCB76DCCC0D67415B363C4B50A4520AACF34B1724370DB2625D4432308
              5B7B272BC7A87F1B6606C2D7AD61768CB83655B5D17DC1A3A52FA1ED522F67CE
              E9E9BDCC6C467CECDD1C9DF3E4AE6DC87A6A3F676E08969716E1C7250B0E3263
              C9824FE43E8C9D7BDC1454B0CDA8246A33897C849EACFB8A951B827191EB90BB
              33439236E3CD0F5D53778E951B8262F754493192B4193FF6C19ACFDD14DCFA80
              12C141FE92B49940FEFBB82DB8252D195787C72469334A3E046AEBCFB37243F0
              C85B2FA0A3AB8F33E7F4F6FDCA6C466C742447E7E43D9689DDCF1473068C2E5B
              F04D0AFE248DA02228001F559EE68C4673DAB289F6B1632E0B2AF8BC5425C47A
              BCCD7CF343076E687508CEC961C523AEAF87C9305B347AA9E663964B178C8E08
              435ECE668FB799C203EF43AF3758047D1313A1EBEAB248CACCC667AFB57E52C9
              4B4C8C052C2AA88C8F468A32D6E36DA6E88D7244161763F0F0613B49C84CBB86
              5BAACFF0B205C81856E60533F82D0EB923D0A36D6652378D23C73F45D82BFB59
              01836565164981CB82E9A949181919F7689B11823D436358FBE25E567F232405
              2E1FF1DBAF3D87CEEE7ECE9C33A99B82C9644680BF2FAB9B736D781C7D3A3D02
              B2B2A06D6D83B6A39DABB86CD04E978E779EACE57CE95F92EA0F4BE069CE7E79
              014DCD5D586132616A6606A6B9B9E5F7C113C74AE06944BF9CA554427C14F2F7
              9640E0EA9364FEB5B3AAE220B37414141E62A6A08BAF9DF382070AF3111D1501
              29E81BB882772A4EF0B7194C6BDA5A325C7A710F4D2DA833003B38971C2F83A9
              51A31B7C1D03178758EA186207CD8C05D80AAE84323B24541E5809992CC520C7
              6D5C93042F83B149333BF21EBA27D4AEFC7824677801F7FB01D30188F2F1C6C0
              C42AAEC9B081D953F453224A318B819969C0F70F1EAFD83D1E9CFDF10A6C05C5
              5C480AA9D58C95C026D646B1EE4156709744DC4AA90686E568851CD7ECF9F7CD
              452D8262961088DA935845849408518B58949BDDDCBA6E1DA540488970889402
              1EE12F3ACF8B47D4BF66A70000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Help'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000048B49444154789CB5987D50D3751CC7DF1BB029021A029727969E61FF
              D05D579654D75D773D3F400F52A62810A5960F75A7584A055296151918943D62
              2228029991046AE51F5D88477A665207D384581A83501B6C6C635BEFEFC6E88E
              3D8FAFAFBBCFFBFBF97EF7BBEDB5EFEEF7FBDD7E0AF8C7758C6B0C053B4BE01A
              03C6D7878AD74429474A20E6C122A444D9464AF401E3ED0315B833333651AF2C
              86D29E660626732D2454C03FDAA19EB938D1A4E3946FE590141510DE04953352
              B2F799604F653F6E2879493BD0770B4E3568391D62595901497A130C4F48C9B2
              704449E16A5C9F9CC42E785EC82BC12FED7FB01B91D4EB6E455B6337A7014B7A
              135451D0C41187EBB632432337BF14030613E26263F0D3F1B69024FD0AFE501B
              BAE0DA8252180C46ACCC998FAABD8770F4C4EF414BFA15FCBEA684191AB9F965
              DC41039665A67106D4D41F46EBC9F6B192469690F478767B135453507C3B7CB7
              A798191AEB0ACAA0E9ECC6B4F8A99C39D1749F677207800BDA968EEB80231738
              159B2124DDF02B78A8BA98191A95B54D38D9769ADDFFD8EC369E3867D901BA96
              D664E0B7736C07588E93722C7E050FEE7E8F29977B16AE610AC1A37381F83F81
              1F2F712AAE916EF8153C701904EF1D15D4DCCCA10B681682E2677643C1F2C4A8
              60D3AE2D4CB9DCB7682D9382FD47E6A123AE735C828D55EF32E5727F462E5392
              E0B795F2051F582C51B0616711D33346AB1DFB7443386D1C46BFC58ED80805A6
              ABC3F048C204F64A1EE1990797AC634A12DC5FF10ED39D7E8B0D5BBA06611CB9
              074CA48FAB17AC489C886B22C3D9B9F350E68B4C4982DFECF02CB8FD9C11A706
              871D626BAE9AE4D831B1A3D53D43A3EB9B6647F3487752B3240AD67FF136D39D
              6D7F1971C668C58204356E8A89E08A13B1265E13E45D1DE9101F4B5AF64B4C49
              825F6F7F8B1938F57D265E7687D90145B32731DD79F8A9F54C49825F052158AB
              33E167BD53EEAE2B227077AC8A9D3B8FCA14DC5BBE99E99FDA5E138EE99DF7FB
              DB26872375AA6739C163391B989204BFFCFC4DA66F8E71D7EAFA9CF7FAF4B808
              DC18EDF9EC7531FFE93CA624C1BACFFC0BEEEFB7A0F9DF61CC9AA0C4D22BD55C
              F14DFA3312056B3F7D83E99B060A9E37DB71435498A3FCF1F8D2979992046B3E
              D9C4F4CDF1012B2EF21A38254C1190E013CB5E614A12DCF3B17FC1729D19674D
              76CC522B9093A0E28A6F162C972858FDD1EB4CDF94F75AD049C19942303E822B
              BE79F2D957999204770720182C0B650AEEDAF61A532E8B9ECB674A12ACFAB090
              29978C15054C4982951F1432E5B278A544C19D651B219B25AB3642301EC1D127
              0B15A5CE6F2B93CCD5854C49823BDE972F98F57C2193822D144488828929D9BD
              66D86336ACCAC4B54933218B764D273697554065C5A0B6B5E50E20A12B943FEE
              1133E665979A14F6E5EC2F0B2AB3ED80567F663D34CDDD9CEA59410986B322A7
              A7646C55D8C2D3CD4A44712E0D95D97A506BF9BB08BFF67501D37AF8EFDBC0E5
              61961B0A9627942C71CFA258F214CC3147A143C1B95D89395C1D0F1D7CCC9614
              6781C63008445FE4CFEBDA3D1BCB0D6F82625D14A5A06671BC9DD256B1364EC2
              ECCE9A48A94696E3A99690E39A3BFF011B0D7247607AF44C0000000049454E44
              AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_About'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000082549444154789CED987B7054E519C69F3D6777B3B900268125900B90
              702FC3C5961071288C331DA93A2AD6721129012915B9892237292043895AA965
              600A5290CBD45A3A439952156AAD0D3296400409A2047283ECE6B6B9B121B7DD
              CDEEF67977D934249BDD133ACEF40F7F33EF9EF77BCFE63BBF7DBFEF9C5DD0E1
              FF9CEF04FF57EE5530F07772EC1C1DF1060921700C4BE709C321EFF7C7949FC6
              253A4CD3745EF509BBCE3B2852F1A4000A43AEEEB1B4BA95D23E3A94EA3CCEBF
              590CB73FC3D90F6A79CACDF03044301021918B6945DEAB8C1FFF4C6A8DC1B0C9
              A9E2598EDB514D26F41E3B169E5607EC97F358B91B835B7734DA6ECFBA7EFD78
              01872E86884A8494948B6A41C1B43971FD5B8D9B39DB328E7D7C7FF4504C4E1F
              8BB4218928898AC5493BCF92CC5E4E44B536A3A8A40C1F7F7A0ED74ACB58BD43
              9BEE37B6B6CA5DB874AA8AA38EA241D122A87039E3CDAEA84F988F65E0C753D3
              F1B359D391608EE7C84FADD38D1D8576C41B552C19D20B51AAC2AA9F4A5B2D8E
              1C3D8593A7CF73E46BD9D5EA9686279177BC9C430723B0F45D0827A88C489F77
              7F93A27CE204FA8C4849C4EA65CFF83A762F48475F7BE300ACB57530BA3DB70D
              4EE7D32579477378AA8511543294A0AF7349AEA802919B307228B6AC7D0E31D1
              913C7537D2BD239646667E9E1E188DE4483DB3AE3436B5600B25BFCC2FF4495A
              1BEB26E3EA87A53C1554B23B411DF75CBCB9D5F84FE663278C4CC39BAFB56FBD
              A088E4A66B7666C04A2EF1F01803B3EE59B37937258BA8E4B9666BA99B812B1F
              5A586E65B819DC057E82094A4D497A60FE4EA7174B87A50CC41B9B9706ED5C67
              965DA9E7AB08C66058746841E9E48A356F71B9EB79873BF694E5566E05B2E513
              72C17C5DF4498A4C67E45192566E325C678E3D592F2375B0B63DB7FC6BBFE08A
              C1E10585E21B6558B27E0733A05775FD434545272E3195BD225D14C92E823256
              9226661E76AADEB90F4FF901562D99C39236567C738BAF141D2482C1F76067DE
              DEF33EFE7EE60BD98F1F5873AF2F01CED5B1EC6088A057843A22DF107DF948B1
              31C7A1DF6E40FF7E71CCB4B1F2AAAC10973A255AB36055751D325FDCCE0CB0D5
              5926E1FAA7054CA58B6D8C2E824A62FABC9FB814E5CFE346A662FB467E208DBC
              5FD182F37617336068948A390322116750380ACF8B1BDE46416939D0DCF48AED
              72CD1FB81765299C0C4F674135B0BC8BE73E8EC7A74F61E9DBE7C4A933D8F7DE
              09189DEE93D68B97970297AB5996C74E17417D724666B603DE07B3D6FF026346
              A5B1F4ED73E56A11D667BDC3CC9367CBB9341BF8AA828366465B67418339635E
              21573A65FF5B6B61EEC1FE13EA5CB2AFA179690394DC2CC7CA4D3BE9E729B435
              E43E85FCFC32966F33BA081ACD19F31D3CE2AF875EE7AB76442EEBA6AC0AB07E
              90F6FD17E089CC757CE58D52F3F9FD284CB2701F3670E8EA56F0F8C19E0916B5
              B8B1AFBC9519B078A00969912A33EDCC58B08EAF14CCC99908986F0267EC1C06
              ED60118F497BDF5C0373DF58A6DA2816C10ADF67C3E2011148ED81E00DDEC12F
              6DD9C5C7B3A7D8967B7E5648C1A48CCC7F39E19DBCF59545F81E1F355A11C1DF
              57CA9301F87982B147825FE71763D3AFF733F35CB6D59CCDECB0C45D040D8913
              E71F71A998BD70D62378E4470FB2A48DE2560FF6DF115C2482268599363EFAC7
              E778F7E847F298F9D8DAFCC5EA5037893E297DEE4CA7A27F6FCC8821D8BC7A11
              4BDA10C103557EC1E7FAF74C70EDD6DD28B65440676FD85875B5F058A8C78C8A
              071E4B307BE3ADCCB17BFBCBE8A7711F9650F05D9B8B19B0D06CC0108D82D535
              F558B6610733DE202DE50F23AFAA20D4835A6635264F9C7FD8A162E6B48C0978
              7EC1532C8547040F56B7310316F4D36B16DC7BF02FC8CEF9D2BFBC17735F0506
              B039DD7FD5C9583F7CF88CD1B7E27A5F628ED75F7D01839207300BCD0DC7DD82
              8323C20BDEB45460DDAF7EC78C9BDF523DABACACF42B7EAF5472D8ED8F0519CB
              CC11A9E9CF6E6B54D45509B1B1D8B6F179444545B2DC3D2278A8C6CD0CC8ECAB
              86156C6E6EC1C66D7B51595F8F0897F388E5C2C55DC07D940BFD734B9099558C
              9F9ED8DFD0EFA45755468E193618EB572D60B97B6E38BC385CEB179C1F2F823A
              66DDF3CBAC3D28B6D0479E7D4EEB0BC8AB2B01F264EF49F7642211F475AC3352
              134923C6CD484E8AE87DC1A920663425572E9ECD4E9A78AA2BB7DC5EECB2F9E6
              C472B382FB5499A62BCDCDADD8B9EF4FF8A6E0067FA4A2C95A513A13311516E4
              27504EDB4F7E41EA2AC33464DCACC9AE08D331914C4D4CC0C2794F22252981A7
              BA2292427772A5D64AEC7EE7A86F59450E0DF69556F7958B28ECC71FC86745AE
              9521DDF34F4482CFE447BA28929118F5688A3926EE18546538C7989A319EBF15
              A7A26FFC7D1C85A7A6F6164E9C3A8DD339973822B2AC15D6E530F12E29EC530B
              5CB8C5AA3C56444EBAD74E2841E1BF92631E4D4C8CECB5DCA5462CE1D8877474
              F2A471486647234D11ED9D954EB5F0FF682C3CFEFB5C1E8ACB2A59F5E3BB21DA
              2AFF08474539F26379439CBDCD725039219CA010908C00A6C5A4A5F51EE588EB
              F39253551E634D33F29CF356D51D282B2B2AE6CE69006219D97243C81D1B544E
              D0222888A48481610226456378F440B329EE8746BDE921A75137909788E11648
              E3795ECE53CC8FD468747A2B5D2D4D9F55191B739157CA6E199A806876EC1C8F
              BEFDE66288984450B40A0AF25E91941051E928A32E927B3A02235D06B4B5E951
              A8AA3CC77F39B9DDD0EBDB906FA0848E5D8AE33266F30809D67C5212ED374430
              E4A23D41DE1F081115193D438E8C69ACB9E51C5179E16C1190E5936863C8516A
              3CD71E21B933598F09FC9D1C2528E643F28E04043A4A098163583A4F782F749C
              A3632E7414E9986BE63F92DD3E6335C7B69A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_SaveAs'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D000005F249444154789CCD980B5094551886DF5D964590501B2FC1A0E034D4
              E854661A903399533396A5085A93868297D44C659A0401959B666A5E438CCC54
              40C5BB21A6A6D3C5CB801822633A969205C84D64E426CB5ED8DDDEC3BAAE0BAC
              BBC0EE4CCFCCF79DF39D7F77CFB3E7ECFEFFBF2BC1FF9C27091A8F19DBEEA067
              088CADCD7434B91813217D1802517705A39068B50CD18AB099B6134BF056D8D3
              DE8DD24D90EA83D4402F8E7597EBD52ACD78146656B3AF6118456DA2ADA07460
              E08C2C15F413D86F87BBB31CBE3E5EEC59A7B8A4020F346AF6388956F7D75D55
              7D30FEC82E67A96208491DC32A6D0565FD03C3C5BBC4E6A44578F9053FF60C2C
              8E4B46B35A83D8883056D6599D9C01672727289B55B8595A6E9054D685E0DAF1
              321EB659B2ADA09C82E2C9F8EDF0D7CC2622E3B7A059A946E4825056D659BF75
              2F5C7BC891183D1B917129AD92D0EA6E5637DF0FC1F51377F810318F55498B82
              BF1E32175C9CB0052A850A9FCD9FC2CA3A9B53F7C3C5CD051BB8130F9A14888A
              B728D9C2B0F899B428F8CBC1CDCC2622398142A942C49CF759592779FB61B8F5
              70C1FA150B598192CD5892F098A4B22EF8E1762B1962253B946C2BE84241F104
              FC7C6013B38928BEB842A1C4FCD99358592775C751B8B9F5C0BA2483A0404846
              25A6A0A8B4C2F099CCBFF1265050C743625184A008332C0A9ED9BF91D94474E2
              563C5034635EF84456D6D9967E0CEE6EAE589BB8809509213969F632F680EABC
              82A140DF4AE06C13CB0EB7DAA2E0E97DE682314914E4676956E87856D6D9B9F7
              47B8F774C39A047341C1DB533F67A6604DCE08FCED5D4AC1069642B0DD17C6A2
              E04F991B984D6C4ADD879CFC6BE8DFAF0F2BEB54DFABC5D831FE981B16CCCA9C
              773E5ACCCCC7E415F9B3290172EBD8764EF0D4DEF5CC26EEDEBB8FEC5317F02F
              4FC0B630D8C70B53278FE52ABAB232675C68243305EF5F0CC0ADBEC514AC87E1
              2A63BBE0C93DE682F6E4DD6976103CB17B1DB363786F7A147337058F677CC5EC
              1826842D61EEA66076FA5A66C710141ECDDC4DC163698E139C38C30E8259BBD6
              303B86E09931CC06C17E6EAF0E7192EB1555BF671EE190ED823FEC5CCD6CA2F8
              4E25CA2BEF41A3116FB473F80EF282EF404FF60C84CC8A65A68DA67EA5B3AC57
              1CBBA0C8AC8A4BE9BBD83583E3663C123CBAC324585C5A89CB853778B7E80427
              77778ED88E5EA9848E371923870FA5A82747C04B5D2C9CD88A0B5BFFA02076B8
              9AD9D9904A2433CBF3D2D2F01816058F7CFF25B381B3395750CB6BA8877F00AB
              CE539793034F5E8146F9BFC40A98FCF152C838B55EAF6F157C6AD830345EBDDA
              A1A445C143DB57311B38977B05752DFAD617EA0A62F2DE3209DE18F50A2BE083
              39CB5A57F0D9A5CB707BD5AA769212A924A4E2625A161F6259F0E0775F301B38
              975B6827C1E1AC800FE72E87CCD91983A3635801B757AE6C9514D82C78609B49
              F03C056BB57A787451B081827D9C2418FD5070CABCE5907BF4824F44042B0342
              5260F316EFFFD6F004C1F98BF659C1D1AF1904A77E12879E837C30202418F5F9
              97550D05053A9AFCA353A9961B57CE8845C17DA92B980D08C1DA26253C02BAF6
              2569B87409037ABB2370E48BAC80D0F9F170EEE90EAD4AD94085347D53C5C6CA
              C2937778C8F6F360E63726C1D2B22A5CBEFA27A43219649D3CCDE8789A69618C
              1C360483BC9FE108053F8D67E62D1C4FD45DBE92ECD99AC46C42485656D540DD
              22EE2B3B870FC58C7282690B1298F985E88EE0EE9444388AE90B1321E89660C6
              16C3BB7404618B9298BB26F8E877717AB2E304C3239298299847417451307661
              189EF7F385BDB959548CD52919906BD154969F378657E312E082106C615817F4
              0E0CCFE27F52E3D8772872B5EE7459E3ED1814E58AD34B2343ACA09E61465B41
              19464CF0F296F6D9098924402D45E7CE293622576BCF9469AAD6E15A4D09E079
              97BF21151CD632AC0A4A1972609407D0D41B7EFCE55D54E3CC31099E63B607B7
              28E1D75783224513F0541DB757AC1E37ADFDF60ADA0A8A5A480A2917860C789D
              B5568CDB0927AE9208574A9D62B46EAD90E3587B3A9A588C89A0586B08446D2F
              8C22424A84A84574C89326361E33B6F64648897822FF018838CB4742F7C6E900
              00000049454E44AE426082}
          end>
      end>
    Left = 326
    Top = 546
  end
  object vilModel: TVirtualImageList
    Images = <
      item
        CollectionIndex = 12
        CollectionName = 'Model\add_layer'
        Name = 'add_layer'
      end
      item
        CollectionIndex = 13
        CollectionName = 'Model\add_period'
        Name = 'add_period'
      end
      item
        CollectionIndex = 14
        CollectionName = 'Model\add_row_32_h'
        Name = 'add_row_32_h'
      end
      item
        CollectionIndex = 15
        CollectionName = 'Model\clipboard_cut_32_h'
        Name = 'clipboard_cut_32_h'
      end
      item
        CollectionIndex = 16
        CollectionName = 'Model\clipboard_paste_lined_32'
        Name = 'clipboard_paste_lined_32'
      end
      item
        CollectionIndex = 17
        CollectionName = 'Model\decrease_indent_32'
        Name = 'decrease_indent_32'
      end
      item
        CollectionIndex = 18
        CollectionName = 'Model\delete_row_32_h'
        Name = 'delete_row_32_h'
      end
      item
        CollectionIndex = 19
        CollectionName = 'Model\increase_indent_32_h'
        Name = 'increase_indent_32_h'
      end
      item
        CollectionIndex = 20
        CollectionName = 'Model\clipboard_copy_lined_32'
        Name = 'clipboard_copy_lined_32'
      end>
    ImageCollection = ImageCollection
    Left = 265
    Top = 83
  end
  object vilCalc: TVirtualImageList
    Images = <
      item
        CollectionIndex = 21
        CollectionName = 'Calc\40_Play'
        Name = '40_Play'
      end
      item
        CollectionIndex = 22
        CollectionName = 'Calc\41_Forward'
        Name = '41_Forward'
      end
      item
        CollectionIndex = 23
        CollectionName = 'Calc\42_AutoFit'
        Name = '42_AutoFit'
      end
      item
        CollectionIndex = 24
        CollectionName = 'Calc\43_DataLoad'
        Name = '43_DataLoad'
      end
      item
        CollectionIndex = 25
        CollectionName = 'Calc\44_DataPaste'
        Name = '44_DataPaste'
      end
      item
        CollectionIndex = 26
        CollectionName = 'Calc\45_ResultSave'
        Name = '45_ResultSave'
      end
      item
        CollectionIndex = 27
        CollectionName = 'Calc\46_CopyResult'
        Name = '46_CopyResult'
      end
      item
        CollectionIndex = 28
        CollectionName = 'Calc\47_CopyImage'
        Name = '47_CopyImage'
      end
      item
        CollectionIndex = 4
        CollectionName = 'Project\05_Print'
        Name = '05_Print'
      end>
    ImageCollection = ImageCollection
    Left = 711
    Top = 189
  end
  object vilMenu: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'Project\01_New'
        Name = '01_New'
      end
      item
        CollectionIndex = 1
        CollectionName = 'Project\02_OpenProject'
        Name = '02_OpenProject'
      end
      item
        CollectionIndex = 2
        CollectionName = 'Project\03_Reopen'
        Name = '03_Reopen'
      end
      item
        CollectionIndex = 3
        CollectionName = 'Project\04_Save'
        Name = '04_Save'
      end
      item
        CollectionIndex = 4
        CollectionName = 'Project\05_Print'
        Name = '05_Print'
      end
      item
        CollectionIndex = 5
        CollectionName = 'Project\06_AddModel'
        Name = '06_AddModel'
      end
      item
        CollectionIndex = 6
        CollectionName = 'Project\07_Export'
        Name = '07_Export'
      end
      item
        CollectionIndex = 7
        CollectionName = 'Project\08_Copy'
        Name = '08_Copy'
      end
      item
        CollectionIndex = 8
        CollectionName = 'Project\09_Paste'
        Name = '09_Paste'
      end
      item
        CollectionIndex = 9
        CollectionName = 'Project\10_Edit'
        Name = '10_Edit'
      end
      item
        CollectionIndex = 10
        CollectionName = 'Project\11_AddExtension'
        Name = '11_AddExtension'
      end
      item
        CollectionIndex = 11
        CollectionName = 'Project\12_DeleteExtension'
        Name = '12_DeleteExtension'
      end
      item
        CollectionIndex = 12
        CollectionName = 'Model\add_layer'
        Name = 'add_layer'
      end
      item
        CollectionIndex = 13
        CollectionName = 'Model\add_period'
        Name = 'add_period'
      end
      item
        CollectionIndex = 14
        CollectionName = 'Model\add_row_32_h'
        Name = 'add_row_32_h'
      end
      item
        CollectionIndex = 15
        CollectionName = 'Model\clipboard_cut_32_h'
        Name = 'clipboard_cut'
      end
      item
        CollectionIndex = 16
        CollectionName = 'Model\clipboard_paste_lined_32'
        Name = 'clipboard_paste'
      end
      item
        CollectionIndex = 17
        CollectionName = 'Model\decrease_indent_32'
        Name = 'decrease_indent'
      end
      item
        CollectionIndex = 18
        CollectionName = 'Model\delete_row_32_h'
        Name = 'delete_row'
      end
      item
        CollectionIndex = 19
        CollectionName = 'Model\increase_indent_32_h'
        Name = 'increase_indent'
      end
      item
        CollectionIndex = 20
        CollectionName = 'Model\clipboard_copy_lined_32'
        Name = 'clipboard_copy'
      end
      item
        CollectionIndex = 21
        CollectionName = 'Calc\40_Play'
        Name = '40_Play'
      end
      item
        CollectionIndex = 22
        CollectionName = 'Calc\41_Forward'
        Name = '41_Forward'
      end
      item
        CollectionIndex = 23
        CollectionName = 'Calc\42_AutoFit'
        Name = '42_AutoFit'
      end
      item
        CollectionIndex = 24
        CollectionName = 'Calc\43_DataLoad'
        Name = '43_DataLoad'
      end
      item
        CollectionIndex = 25
        CollectionName = 'Calc\44_DataPaste'
        Name = '44_DataPaste'
      end
      item
        CollectionIndex = 26
        CollectionName = 'Calc\45_ResultSave'
        Name = '45_ResultSave'
      end
      item
        CollectionIndex = 27
        CollectionName = 'Calc\46_CopyResult'
        Name = '46_CopyResult'
      end
      item
        CollectionIndex = 28
        CollectionName = 'Calc\47_CopyImage'
        Name = '47_CopyImage'
      end
      item
        CollectionIndex = 29
        CollectionName = 'Menu\Menu_Settings'
        Name = 'Menu_Settings'
      end
      item
        CollectionIndex = 30
        CollectionName = 'Menu\Menu_Exit'
        Name = 'Menu_Exit'
      end
      item
        CollectionIndex = 31
        CollectionName = 'Menu\Menu_NewFolder'
        Name = 'Menu_NewFolder'
      end
      item
        CollectionIndex = 32
        CollectionName = 'Menu\Menu_Undo'
        Name = 'Menu_Undo'
      end
      item
        CollectionIndex = 33
        CollectionName = 'Menu\Menu_Normalize'
        Name = 'Menu_Normalize'
      end
      item
        CollectionIndex = 34
        CollectionName = 'Menu\Menu_Smooth'
        Name = 'Menu_Smooth'
      end
      item
        CollectionIndex = 35
        CollectionName = 'Menu\Menu_Trim'
        Name = 'Menu_Trim'
      end
      item
        CollectionIndex = 36
        CollectionName = 'Menu\Menu_BatchJobs'
        Name = 'Menu_BatchJobs'
      end
      item
        CollectionIndex = 37
        CollectionName = 'Menu\Menu_Benchmark'
        Name = 'Menu_Benchmark'
      end
      item
        CollectionIndex = 38
        CollectionName = 'Menu\Menu_NewMaterial'
        Name = 'Menu_NewMaterial'
      end
      item
        CollectionIndex = 39
        CollectionName = 'Menu\Menu_EditTable'
        Name = 'Menu_EditTable'
      end
      item
        CollectionIndex = 40
        CollectionName = 'Menu\Menu_Help'
        Name = 'Menu_Help'
      end
      item
        CollectionIndex = 41
        CollectionName = 'Menu\Menu_About'
        Name = 'Menu_About'
      end
      item
        CollectionIndex = 42
        CollectionName = 'Menu\Menu_SaveAs'
        Name = 'Menu_SaveAs'
      end>
    ImageCollection = ImageCollection
    Left = 711
    Top = 240
  end

end
