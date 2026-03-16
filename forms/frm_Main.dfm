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
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000E549444154789C
              63601805831D38CEF3F0729EEFF6D87981FB7F42D8B4DDF208D51DE04CA4E520
              AC576B447D4738136939CC016047745A1E1F5007E851D311CE643A806A8E7026
              C101D8F0A803186815052E0B3CFEB71FEA0463109BEE51D071B8EB3F0C80D874
              77C0C20B8BE10E00B1471DE03C6CA3C0059ADA679F998B82CF3E3B077700888D
              2E0FCB1D143BA00329B5930A407A87BE035CA051B0FCF24A147CF9E515B84520
              36BA3CD5A2C079A013A1F3A803160CD228E818E8CAC865A0AB6367BA35C9E613
              DF2F40C74E0BDC1F51EC00A705AE9E2083C8B1DC79BE9B07C50E6018EE0000DD
              171408C91E50AD0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\02_OpenProject'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000F049444154789C
              63601805A360148C0234209A7AE03F419C76209461201D209272E0B558F21EF1
              01738028C811A90736D0D40162E987FE1B743FF8EFB4F42BD5B0E3D22F778972
              804CFE89FF56B3DE50D572B003967C9941D001AAB597FF3B2CFA4475CB21F81B
              E1C4EB44138BC1C1FFD77EE92791017380D3922FA7095A4E5B077C6D67184807
              382FFDEC32600E705CFCF9BFC5AAFF9C03E600B3C9CFFF136539AD1CA0D57C63
              601D2057747AE01C60BFF0E37FB1D40303E700E3FEC7E0BA65C01CA05E7F7560
              1D209D779C340788A61E784C6C9B8078BCFF11D10E10493DE009D2404DCB45D3
              F67B10ED805130E20000DB0B68BC6FACB5760000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\03_Reopen'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000001E149444154789C
              63601805A360148C0234209A7AE03F419C76209461201DD0B7F5C157B1E43DE2
              03E280AE4D0FFE838048EA810D74774017D47210202AAA9030C50EE842B21C04
              C4D210722076E6DCEBFFB3E65EFF2F917E90FA0EE842B31C044096C1E4416C18
              3876EBC37FD5FC23D47540EBFA7B443B0004CEDEFBF45F3AF320F51CD0BD1933
              04D0A3A079EDBDFF7FFEFE83CB776EBC4F1D07C8661DFAFFE9FB1F0C07607368
              D5F2DB70F98FDF7E83F552EC80A84997E186DE7AFEF57FF3DABB381D209E76E0
              FF9D17DFE0EAC3275CA2DC01F5AB211682C0CC3D4FE08912576E99B3EF095C7D
              DDAA3B943BA0152901F66F7D4830BF4FDCFE10AE1E942E28764026520ADF73F9
              2D410780D4C000482FC50E30AC38F1FF1F3471FFFEFBEFBF6DC3699C96DB359C
              86E7041065587E9C3AD970F72584AFEEBEFCF6DFA4EA04861AB3EA93FFEFBF42
              24C09D17DF50AF1CB0AA3DF5FFEB0F445604B1E71F78FA3F73CE35305E70E0E9
              FF6F3FFFC2E53F7FFFF3DFB2F61475EB82E8C997FFFFF885B00417F8FEEBEFFF
              888988EC47350788A61EF8EFDC7CE6FF85079F705A7EEEFEA7FF4ECD67B0EA25
              C5018F09A574DFAEF3FFFBB63EFCBFE6E44B30EEDDF2E0BF4FE7793C7AF63F22
              DA0122A9073C411A08398278BCFF9168DA7E0FA21D300A461C0000A70B4C5E92
              93D09B0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\04_Save'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000CE49444154789C
              ED953D0EC2300C467301D4253E133F032B152B0AE76064A4DC808D5B24672837
              A0948DB26633CA10212204493020819FF46DB5BE27D96D8560983BC899198132
              0D28833EC5788BBDFEE661DC33D719BD10B94050EEF2ACDCE7762E530282F27C
              018352E9E5570520470288059225E00D022E2C205E594191FC1D205E01108405
              04AF2016088E67BADEE1F16C3196B6B3585635DD11B65D7CB9E770B27402B9B0
              00FCCC0D94559D24E1CA272BC2B700FEF15FD0D00BE87DB4805466E80628CB61
              AE07D1028CF82017D4FF395389F143DD0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\05_Print'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000EC49444154789C
              63601805A38000E0715F7094D77DE17FB2B0DB82C30C94025E722D87E2510730
              8C4601A58077C4254291B47DDEA229079E88A61EF80FC2943A00668E68EA81C7
              22A9073C093A4034F5C063244DFFF9FD56906D39482FB259A2A9FB1F11E380FF
              B4C434778058EA81FFAAB597C158346D001CA05A7BF9BFD3D2AF60AC56736904
              3A4034ED00D862D5EA4B031305A2039D08458783031E236B3875E7E37F72C189
              DB1F482F8844520F78223B8252806CB968DA7E0F0652C17F28B8F0E2CFFF7537
              7E1385416A6180640B07AD03C805740B810B48BE1E760E384C76F8FFFF7F8862
              07300C770000AA4614E6848E39030000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\06_AddModel'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000001BA49444154789C
              ED96CF4B024114C7F7D45F50FD173B3AB3100506E5927B8FFC3784BA19B34A79
              D92E12454507993D87E7B53A74E89407F5549075E950417428EBDCC4DB6D9745
              CDFDE188143EF8C26314DF67DEFBFA18499AC424BA227B929D52CDCC4E9A659E
              5453E3519436B547956906FC86143754A619510BF78869466C80748C9BF72AF3
              1CBF03E6B0C51DFD0F80DADD19BF7D6D8792D53E150F70FD72131A00BE2B1C20
              676DF0FDFA6128E5ACF57FE80175DC00B58909AD3F68C2E5CA0A9F2FA7B84C49
              4BD6C9A723DC4494945011CD8E142075B0C4134585239DF04441E1F92AB50539
              9C211D77649A5C136242AB6BF341715480228E36AB3A770372F71CE9E46B2084
              1A7213FA371FB4DDBDB9ABA38B630F0072FF6732C5EFC97C722610609009FDA6
              8399FB0B0401D8103ADE16E601529AF366BE7BBE67EBEABEEE0140EE9EBB9E00
              630A0380F6FB671E148E277067AC00E083BE00F6C3728811542E99ADE643CB2B
              08B97B1E3C0216FD51BA505E8C6E428AB7FA02D8CF72A619513A11F96FA8E337
              A5A84CF705881BB05C60C984594488E255A1C5FD1060AEDF5631DC7C64C5A59F
              800D074B0651DC40947C38C20D98B9F0B68B886F96874C9ECDCDAB8C00000000
              49454E44AE426082}
          end>
      end
      item
        Name = 'Project\07_Export'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000011449444154789C
              EDD64D0A82501007702F106D1C3D521FABEE103EC8A3D419845AD8A276768026
              30DAB7715B4974800EF0622A2BEC8966A3453630308AFAFFA93C51D3FEF5EDA5
              77B10D168660A14CEB7A67E2B30320633875AD31E24740C6F00870414C571F05
              D438119013C086801700AA2E0C600A94B6139C9BE652018640395CEC6554E3E5
              2111C10E30281CEFE13784AF46B0024C81D2F50F32A95C05820D60A684272158
              00A6227CBD3D2AE7388205603BC153C060B6B96DD31C07D2398500DCEBDDF5BD
              3B80E6F8536205180265CF09CE4D33ED8B03928E630180A2558052BF84FD3FC0
              ABFA2BB01F9666B4E44A05188A25572A003EFD4302550284F901F3DDDB00DDC2
              165D284F388879F36D80F6EB7502B0C12E891E9941870000000049454E44AE42
              6082}
          end>
      end
      item
        Name = 'Project\08_Copy'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000AA49444154789C
              63601805A300077058F6C5DB71E997274E4BBFFE270D7F79ECB4E48B2703A5C0
              096410C99643B0E3922F8FA8E080AFFF29C1A30E6018F151209A7A00861F8BA4
              1EF01C4807FC174DDDFF68801D7080F434E134EA80A5A351F0753411FE1FE9D9
              F00BD9ED019BB9EFA9E080255F3CC97104C872A5F2F3943B001DA01B482A66A0
              14888E3A2075E0A3E031F90E20A33D800E40AD1AF21CB1FF9168DA7E0F0C0347
              C1600100E0B5A6FB609A5C9F0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\09_Paste'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000FB49444154789C
              636018054309382CFBE2EDB8F4CB13A7A55FFF63C75F1E3B2DF9E24933073881
              2CC06939043B2EF9F268183B60C9174F9BD96F705A6E3DEBF57FE7655F3C1868
              0978DD17FEC787A9669148DA3E6FD194034F44530FFC47C67C5E4B705ACEE7B5
              14452D143F16493D407AC2144D3DF0188B61FF8563B6637504C872901C363DA2
              A9FB494F17A2580D221F8F3A8061340A867C225C76E4F9FF0B0F3E1185971C7E
              4E7D079CBEFB91680780D452DD01DE9DE7FF572EBF4D14F6EA38375A0EFCA77B
              225C8225E1D135119EC692F0E89A08BDB024BCD1CA4894C228784CBDA2988C06
              8948EA014FEA3862FF23D1B4FDB46DA88E82210D007C4E37E0B440452D000000
              0049454E44AE426082}
          end>
      end
      item
        Name = 'Project\10_Edit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000F349444154789C
              63601805A3603882D779DC07DEE6701F1F30CB9F0532FC0761BA3BE2E772D586
              0F0D2260CBE9EE889FCB551B7EAE50FD0FC27477C44F24CBE9EE889F582CC7E6
              8837B93CFBE96AF94F287E5F2BF4FF4DDE0059FE7385EAFF1F2B54EA472DA71A
              F8391AEC2B46139C2AFDB2DA9B4A3ED7F795820393CF41E07501EF5A50118ACF
              1134B31C045E2573BC0639E05D093FFD2DFF50CF27F42C84F1FFEB548EFF3F96
              AAD0D7721078572250FB3C92F9FFF7F98AF4B71C04DEE4709FFB32590662E172
              D56F3F97ABECFEB15CA5FCC72A152D067A80CFDD12277F2E5799F463B99AE7FF
              55329C74B174148C0286010200F56AFC6698630AF80000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Project\11_AddExtension'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000018949444154789C
              ED56B14EC33010CDC41740FF226EEC4888A1434944BC23FA31457623E8121684
              902AC4502533EA17303030C1D0F607581880155A668CCEC15150A8DA248EC4E0
              273DE9749172CF77E7275B9681C17F42EFA6B7E527C1991707AF7E4245157A09
              7DF1631AC1BF4A0BF0631A552D5C604CA3D202BC1A272F32782BDF814457F194
              468065465016BE59C2C45C43AAC580F6C70762EFBC236C46E636279F29F10C31
              3244216A35BA849D5157B44357204E447BE08AFE8449420C39C4F1C266CE5123
              023AA3AE40032892F278C28502C42A8F38F9FA53845FB3EDEAE48A5777D79900
              88F3DF6C863F9CBEB3A34D00CC3C5F609D002982E3D35F02E463A2A20032DCCD
              667E717B29F9F0F498098058E5D54EC0626A7B9040FBF3335F877427F0A2F824
              8B6954A5135504C01E58BA00775E8D607C1F4BCE9EE7594188557EE508EA409A
              4CD92564F8449F8010B560A61B5F438EDFDDD0DDB67402CC054C661323420C1F
              6A2D9E1701CBB5CA8AE1E48D15B77E000E072683189E22469629F11466AEBDED
              75F10D42DFB3D758E4CC7A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\12_DeleteExtension'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000015349444154789C
              ED56BD4A034110DECA2730E6C2CC419AC011C8ECBB88CF913C830AE17C80BC88
              C59E07B6368128B9B5B1B0545BA3D6AE8C5CC423C999DDDB038BFDE0EB969D6F
              FE3E46888080FF84FBE1F0A020BA28889EB594C68505D193264AF92F6B019A28
              750DBC41A2D45A40D120F38D4A48F9625F01E929FB924180082DB0850E4328C3
              1A4A2F06B41C8DCCCD606032C43B85F8C1CC106F15C079DEED1EB53A84F32431
              791C73F05D7C530027AD089827495DE01F2AC4CFAD2274C3B2FF917995002B15
              451D6F02CA9E5B51019C55047C1F138E02AEFB7D93C5B1598EC7E6613AAD25BF
              E1B73C98DE0E922B0E3E99987DC16F79202B02F88C62112E95C85D0400AC842F
              F0CEAF5BF0389BD572670B9A804DC67608338053E10BEC70DC538B0D78BDECF5
              0E854FB0B9B0C9EC634419C0B1D7E0BF45F070D565DE5A70B11611451D361985
              B85088EF2517DC73EF656F8A2F9595981F10473A570000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Model\add_layer'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000015849444154789C
              636018053404C669C6AC92318AAE52B1F245200C6233D833B030D00348462BDA
              4AC5C9DF968E53F86F5A6009C620B654ACFC2DC958251BDA5B1E2BFF0366F9F7
              9FDFC118C9113F24E3E5AC69623928D8613E07E190B688FF300062C3C4A5E3E4
              6FD2243A40F10CF3794467F4FFA665AD700780D820317848C4CB39631890B62B
              EB68DAEEACFFE462E7091EF060C70560D121152B5F8CE9000A2C076197892439
              A088EA0E085C18F69FB228D84D9903527666FC57CBD6FA4F4422BC813511A6ED
              CE3C4CA923429646FE974D50FA8F2F1B4AC5C8595194DA0901503E076535F482
              08E4739A5B0E07F60C2C52B18A2ED271F285200C8E734279DF7981FB51E705EE
              FFA9819DE6BB1DC66B1936402DCB61988154E03CE21DE034DFED30F542C1ED10
              C951300AF46A8D8EEAD51AFDA706D6AD35243D1BEA51C972181E750003A940B7
              D6F030D5A2A0C670341B8E8251C040080000F9D95898F5CC5817000000004945
              4E44AE426082}
          end>
      end
      item
        Name = 'Model\add_period'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000DD49444154789C
              63601805A3602400ED6A1359DD6A031738AED015A4AFE5B586DFF46A8DFEC3B0
              7EB5B1034E0D69BBB28EA6EDCEFA4F1D9C79987407ECA696E5100C0B05BD1AE3
              E201730008802C25D2019987A9E6805D5987487600ADC0A803F491A240294B33
              4F3A56BE533A4EBE0923A8F46A8D8E2267194AB06EADE1616C51A094AED62A1D
              ABF057265E2E1A9B03FE5313E374409CFC0BAC89856E0E8855B88FD501A060A3
              9A036A0C0F91EC005A81D16CA84F7451BC8BBAB521C9519036F09551D64057C7
              9954AD0D496E90501B0CB80306BC513A0A4601030100001EE7C38B2A581A8700
              00000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_row_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000E449444154789C
              ED96410AC230104573353334693D41175E42D1EB38D97B005D5BC4AA27D09DB6
              B8F2000A4224B51537C1048DA2CE830FA14933BF6DA67CC608E28ED6306E038A
              1294D44184A2E02A4A980D4051042B5E8B2BB9B31B50D745F97E1144CDFE6480
              D127F86817A0DC5A0D7015253E26D251A7924F0B028AD86AC0004ACE5C8B1FCF
              A74AAE26388A8C3D021C9FA63719E8063376BDEF6903DD715F2FCB955E1F3637
              03666CAE99B9E006E645AE6D98B9DF7F0310FA0C701459A82E0025A62FCD03A9
              E77F80F2003C3A07502FA04092FF6F24C32FCB03E05BDC250F10ECCD5C001E07
              A73F556FD3570000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_cut_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000020149444154789C
              ED563D4BC440105DB510143D35BB39B4B0100B0B2BFD237EA09522DCED0644F4
              2F5CE3295696FA1B6C6C44FCC0CCC859881C575A68E16F1051D0C293BD2477EB
              7AE726B944047DB010D897DD37336F2621E41FBF1FD50E3B0F4B72C9E7E4F906
              3001CB4C60D55B500CC12F2AFC6592B0807726DCF9D65C77DEE324288014AA9D
              8CE3517028E5F894CDC1A44EB31C98601C1E1B3C38250B075DED0B20840CAD5F
              F73301B78A888791B5732BD8CFAC9606A9C0FB7AE41CEE322B30409284A54728
              E0AC1661C80C2502DB8119ADC645CA714BF508E5B848D204FBEC7229A62188C3
              26491D85CF294FC574260C6E944699C057A5EE6FF6EAF918F911145A64203065
              DAA09AE97453A67AB9AD7701874DDD94A97581D56AD2FDC41CC818269D6952B6
              052B77D5473996627C0BAEE5BBB12F1E5F3FEEA61C76D476F3A277CF64C4CDF9
              EEA1D61DAF8CC37E33BEF17226B0ACB79A62B68AE4C4E51B41BDC8837ABB2CEF
              EECA45059E28A5D88ECBFF16D9A5D35ECAE1C5577E215D5EDF948E17087E8D5F
              869D724F547E88E8DDE940B5CD7156DF67799CAB47E55C4E45E5B72F40C8DFAE
              080234BE51405649A9ACE1979472443FA5CF7A09C2F08D0224A8C03DC5C5504B
              A35CFE61BEA9B6E2F28D18F2265BA5655B71B851DB2A2A3F14C66B8305B71B0E
              F7D22823697658547E680C3BE59E9AD99CCBA930358CCA277F1E1FDE4591885D
              1B84BD0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_paste_lined_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000FB49444154789C
              636018054309382CFBE2EDB8F4CB13A7A55FFF63C75F1E3B2DF9E24933073881
              2CC06939043B2EF9F268183B60C9174F9BD96F705A6E3DEBF57FE7655F3C1868
              0978DD17FEC787A9669148DA3E6FD194034F44530FFC47C67C5E4B705ACEE7B5
              14452D143F16493D407AC2144D3DF0188B61FF8563B6637504C872901C363DA2
              A9FB494F17A2580D221F8F3A8061340A867C225C76E4F9FF0B0F3E1185971C7E
              4E7D079CBEFB91680780D452DD01DE9DE7FF572EBF4D14F6EA38375A0EFCA77B
              225C8225E1D135119EC692F0E89A08BDB024BCD1CA4894C228784CBDA2988C06
              8948EA014FEA3862FF23D1B4FDB46DA88E82210D007C4E37E0B440452D000000
              0049454E44AE426082}
          end>
      end
      item
        Name = 'Model\decrease_indent_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000DB49444154789C
              63601805A360B0019194FD4745530FFCA7051649397098A003446964390C1311
              02077ED02C04520F7C27EC80E4035E22A9FB3B68830F78129D1646C18083FF33
              8D597FAE508DFBB95225E6FF7F06466A6453A2B221087C5FAEECF06385EA959F
              2B54FF83F172E5586A6553067CE0EB3275A91FCB5596C12DC6E2004AB229CE6C
              F8FF3F03E38F652A853F96AB7C42B618C40789A3440145D9144736FCB95C3916
              DDD7A090008508033DC0CF8176C07F12A280A6E02B518970386743E20A221A64
              4352004DB2E12818544064B4519A32DA281D61000045723846E710B851000000
              0049454E44AE426082}
          end>
      end
      item
        Name = 'Model\delete_row_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000B349444154789C
              ED96310AC3300C4575214B3E465372B61CAAA16386D85932B636F40C9D541428
              74B193A14A4AD1036DB2F5912CF3010CE383E0FD3922E648C44A9146E71A2811
              899262F12502D1BD26802578082AF1BEDF04808DE0D02D40BC15058CCE359A22
              640527C413D408885745017DB5B8A03D025823160ECE6DCBCF9C790DC991DCAF
              0B78741D6F4572FFAF0371AF3710887A4501977A716F7E809656991F607344C3
              719E30697F44BFEF070CD89917D080D853848563960000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Model\increase_indent_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000DA49444154789C
              63601805A360B0019194FD4745530FFCA7051649397098A003446964390C1311
              02077ED02C04520F7C27EC80E4035E22A9FB3B68830F78129D164601DDC1FFFF
              0C8C3F57AAC4FC5CA11AF77FA6312B2DB229DE6CF873B972ECCF15AAFF41F8C7
              0AD52BDF972B3B605347B36CF813C90170872C5759F67599BA14B5B229DE6CF8
              FF3F03E38F652A853F96AB7C4273C4279038489EF26C4A4436FCBA4C5D0AE473
              F4D0008510033DC0D78172C07F22A38066E027D18970B866C3FF44174434CA86
              C4029A67C35130E04064B4519A32DA281D610000B0F23846D6EDB5CB00000000
              49454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_copy_lined_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000AA49444154789C
              63601805A300077058F6C5DB71E997274E4BBFFE270D7F79ECB4E48B2703A5C0
              096410C99643B0E3922F8FA8E080AFFF29C1A30E6018F151209A7A00861F8BA4
              1EF01C4807FC174DDDFF68801D7080F434E134EA80A5A351F0753411FE1FE9D9
              F00BD9ED019BB9EFA9E080255F3CC97104C872A5F2F3943B001DA01B482A66A0
              14888E3A2075E0A3E031F90E20A33D800E40AD1AF21CB1FF9168DA7E0F0C0347
              C1600100E0B5A6FB609A5C9F0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\40_Play'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000F549444154789C
              ED96A14E04410C86E74282B904872241E33120AFDDFD3BC9E9B1485E01CB2B20
              11A43D706B10BC003C00E63CF6E4A90B0812868485431210FCE2F64BAAE79B69
              A76D4A03033F206E77CDACD94F2C34AC8ADB4A0267A52B5B14015D071E278143
              A28055757B95C0457BDD8E3902D187843D4DA2054D40BFD3D2E5ABBC4B14B0AA
              8EA5064E534D238E40ACEBE3018E039E407CC48BBA9D97AE6CB3046A5FA498EB
              CC8E6902DAA7E44DC22EF34DDEE108C4E76B38161A38A10A88E7B2592990C0BC
              F17CF4E783BFF8FDADF14CFB86E2B8E73422A7B662708691D0C6B15317127056
              32212FA5B712D3BD7F3F7860637807FDC11098BE379FDE0000000049454E44AE
              426082}
          end>
      end
      item
        Name = 'Calc\41_Forward'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000A949444154789C
              ED8E410E82400003F76D90B0CFD2A3BFA03FD5349A18116507CA6DE73C99B694
              4E67C138D75B39D1DF0EAADE4994FA6D41B547A9DF1E545B94FAEC80B6A3D4E7
              07F43F4AFD7D07F43B4AFDFD07B41EA5FEB103FA8E52FFF8017D46A99F39A077
              94FAB9037A46A91F3D3068BA503F766078C5A2E386C6A2E386C6A2E386C6A2E3
              86C6A2E386C6A2E386C6A2E386C6A2E386C6A2E386C6A2E3669CEBB59CE8773A
              65C1035BD98AABE9866A210000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\42_AutoFit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000003E349444154789C
              ED555D6C145514DEAA511E4C0A2F4666EABD6D4D881A84906028311A90175F4C
              080A8D06832F12660A34FC7767DA6CA5A1A191B6F64E41EF225D66A61429F263
              53692862296016B67B671769772EB51413C2031035842A88B6D7DCDD9D32DDB6
              DB46DB9A2827B9D99F3939DF77CEF9BE3B1ECFA3F8EF04CBF082FD2BF9E1DFA7
              1C5E05FA872A34183F0AD077FC0B048C4B0E0115EA030A30DE9E3270059A790F
              C1935380FA5D6F96317B6A0800BD2E954072123F1481033326157C5B6E63A60A
              F5BEE26C93351706D9B725E17605E8775C245A977B1A1F9F34022A300A3850ED
              1B4DCCD228B334DB2E86C652AE832911A50A8C080769D9144A1040F626A2D1C3
              2D1B2F84F8541C517A9F33574C9AF8CAE71C6204511646765F744FCF3304D19F
              3999E3D2F9DE7F284A96F67271C4573AAB819DF928729320BA81FF1FD1EC4544
              B3EF7312FA8A53B7FFB6281560AC77755031A2F87212FBDFB5F0D812F7738268
              3ED1ECFE8EEAAEABBCFB4112C038E1F3F81E1B137C5B6E63A60275177B83A9D9
              FAAA54F105969D8CEF9E687498D0C2E8CA6BD14F62B303CB4F1795CF3D34284A
              15E8EF8F4940057AF9305F03E3BE17045E4D12B8C44576AE2C9A205063BF3552
              9DCEDACEA72D8DFED151DD75AF62FEE1F111F08966960AF5DF5CC0B75C96BAA9
              66EBF96EEB919A582FF3B151C76A69F6173C2F54D5F553D5EB470BC77C59A9C0
              D8E7EABCE3F3374FCC2BC9311F9280463FFF6C58D9E678BF305DBDEE9AEEA788
              46CF246DDA9E16BC38ABFE6515EA7F72006D71136B5E17DC4134DA17AA8CF594
              BDD0F0BB7B25A5B30EB0E675DF6D6EF3B53D91B6287746F5B5E916B25B2C6457
              A64D5480F1352FBE2BEF281FED0041F42ED1E865CE3EF871E7F5ED2F1E8C8307
              96B5B2D3C5A42F8CAF667AC611D24CBC5516305E2B7E3A77D4242FDCBF98172F
              79BE9EB597469C9B6D67FC724992385B16BDC17D1FAA8C3182EC8128A2396381
              CBB0F65959F03F90453F93441C18258D65F07D730266FE370E78AC2D706D1A7F
              9A20619FB7347AA4697DB03E2E3E445BC7D3BD2CE2A22478AF2CFA7F2D8481E9
              C3925468BEEBEC567FA7F50141B13BD66EFACA4805F90B279DF5521B93057F37
              3F6BB2F07B9C883C13AF1D92E27BA9F149051A3D253926DBB7F424ABCAFB7277
              BA9216A27516A25FA5B39E1305E2DE457150D1AFAC82816992807F9104FFF743
              9214687CC03B3F98B4554775ACCE3341210BD84C8CDFBF5D12F7AE96441CE1BF
              0B84CF160E26F19B29A17A9BEFBD3F5C7B65C14480AFCEC5997CE7C9090C3929
              626419C18ACB3F3AAAF74C50480296E360029625B06786736411C78689D142F6
              39A2D9171DD54F44C822B66401DF4B55BD2CF8B78C28C647F1BF8CBF005937D1
              531ADE54560000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\43_DataLoad'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000014D49444154789C
              636018BAE03FA358F2FE181006B1E96EBD68EAFE58D1D403FF21787FEC4038A0
              01C9010DA30E60188D027A03D1D144983A9A0DF7D3A320FA8FB3BCC71F0554AA
              274491CBFB94037DC43A00A4962AF584284A8573E0BF48DA813C420E00A941D6
              43594555FF9F4924E5C01A4428ECFF2B9A7C200897034452F6FB88A61EF883A4
              7E1343E82A66F21DC0C0C0201FBF9F4324F5C0117828A4ECFF269A7AD00ADD01
              C2A9074C45520F7C41123B299976868B811A402A7BB7B068EA811B08471C782D
              927260328C2F96B27FA248EA811748F277C4338E8A31501388251E5642B64434
              65FF3BA4B87E83EAB8436A54B51C06C452F65B40A20039912125D294FDDF406A
              18680944D0131A96044A73208291D550B3285D802872618356488D8C66394D7D
              259A72A09C1698606889A295FDB4C178EA06D181760003340A4452F777D0020F
              B704CB40150000CB9F184C00730BF40000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\44_DataPaste'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000018749444154789C
              636018054309382CFBE2EDB8F4CB13A7A55FFF63C75F1E3B2DF9E24933073881
              2CC06939043B2EF9F268183B60C9174F9BD96F705A6E3DEBF57FE7655F3C1868
              0978DD17FEC787A9669148DA3E6FD194034F44530FFC47C67C5E4B705ACEE7B5
              14452D143F16493D407AC2144D3DF0188B61FF8563B6637504C872901C363DA2
              A9FB494F17A2580D221F8F0C0788A51DF89F39F73A1883D87477C0F4DD8FFFC3
              40D6DCEBF47540D5F2DB70CBE9EE80E8C997FFFFF9FB0F6EF98E0B6FFE4BA41F
              A49E03C4F0C4AD47FBB9FFDF7FFD855B7EEACEC7FFB25987A89B08B3E65E875B
              D0B5E93E5CDCB4EAE4FF379F7EC1E5EEBEFCF65FBDF028F5734116920340411D
              D47B016C11C84218003904E4209A6443F1B403FF0F5D7F07B7ECE5C79FFFCFDC
              FD08E783A2001415342D07348B8EFE7FF1E1E77F74004A7B09D3AFD0A7200AEA
              BD8092DA410094FDE85A12766DBA0FB71C54F0109B55A9E600313C59922E0E10
              25130F49073CA69E03C8689088A41EF0A48E23F63F124DDB4FDB86EA2818D200
              00DC8B4D2EDC67BB330000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\45_ResultSave'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000014249444154789C
              63601805A3000B10493EE0259A7AE0B168EA81FFE462FE80554718C805A2145A
              0EC2BCEE0BC97784288596C31C0071C4EAE303EA005E721C214A650790EC0851
              0A2C164B3BF03F73EE753006B191E5E8E280FEAD0FFFC340D6DCEBF47540E2F4
              ABFFFFFDFB3F300EB0AA3DF5FFD3F73F70CBF75F7DF75F22FD207D1CA09A7FE4
              FFBD97DFE096DF7DF9EDBF4AFE110C756439400C4FA20261F1B403FFF75C7E0B
              B7FCCB8F3FFF6DEA4F637528590EC89A7B1D6E382881E14B74A0F807A5035C21
              45B103FEA159809EE8B03990620788A71DF8BFEBD21B9420B66D384D54A2A38A
              0344B12432101B9D0F524328B192ED00512CD90C3D4488C92D143940144B9C13
              4A74547780285AAA2794E868E2003102E502CD1D204A011E7500C3508A82C7D4
              77C0FE47443B4024F580274803352D174DDBEF41B4034601031D01008AC01932
              B42B351F0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\46_CopyResult'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000017149444154789C
              ED963F4AC44014C673087301CF61E18E85060BC5269D5D2CACEC3C8227B0B450
              12B77061C14A504810B113613D80902C8A95E8CE6437319B272F6BC23A4B8233
              C946917CF04226C5FB7E797F6014A551A31C2D9FD2F59645FBC4622016D42326
              D594B2229848D87C122D93BA1500302153BDEB27919E6B05D8BB1C4210018C22
              C8206A03D83EF7E16D14032A1CCF0940E7CA9BC666C787FEFBC41C9F07B741F5
              2DD0BB7E525A2CF1EEC53033586D33E8BD8C21D5712FFC06A71A4E1ADE82E168
              A500C22F9FE7410C1B673EAC580CAE1E3F32737CC76F3900A01AB6F85690A964
              8777416676E34570F2106667AC025683140238E22D2153C9F0EFAEDD08783D0D
              62D8EACCCE46E500C46249E9B105A970F27103F2B6A3720062B1640871183170
              F78BD6732E00A460256B03203F8C0640FD072DA0D2F781A5A3D70A004CAAC940
              A0F9E2FE7D79005E7C42D150CA4A6D008CDF6F81270F20711FE085B71A3908DB
              5577ECB599848DFE8A3E01F258D3D4E6421AE10000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\47_CopyImage'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000019149444154789C
              63601805A3605082D02B6C2229FB3B4553F63F134D3DF09F32BCFFA948EAFE0E
              909944DB2F92BABF83728B5131D811C40251AAF81CCD0129079E13EF80544C03
              B4CB8EFF8F98761D8CB54A8F93E508B21D1032F9DAFF6DB77EFEDF7DEF371883
              D8C193AFD1C701DA65C7512C477604A92141960322A75DC7B01C86C3A75EA7BD
              0322F038206CCAF5111005A2A907C0090E23114EA25322148562B9A46DFF2D8A
              0F80E35DB384CED9503866FB7F5E8F85FF79DD17FD178AD94E96E5643B403861
              D77F5ECF45FF79DD410E5808660BC7EFC2698950E4E6FF02C1EBFE8BA6ECA7DC
              0122497BFEF3792D45580EC52031901C4648C5EDFCCFE70171AC80FFCAFFA2C9
              FB287040F2FEFFFCBECB312C873BC26739580DC2B17BFFF3792D4155E3BDF4BF
              48C26E721CB0FFBF40C02A9C96C3307FC0AAFFA22907C0C1CDEFB702BB3ACFC5
              FF85627790E600819075042D8761905A509CE355E7B1F0BF60E466E21DC04BA4
              E5A4E2510730101D051E8B3E513D0A3C977C24DE01AE4B7D411AA86939AFDB12
              1FA21D300A4601031D0100E33430B358FBB4B00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Settings'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000018149444154789C
              63601805431188A7ECD5164D3DF01F190BA51FD2A29B034453F737A03B002446
              758BC4D3F72B88A4EEB3C77040CAFEAB180E48D97F155D1D482FC80CF22D4F39
              701F62F8810320C34018C4C6F43DCC1198EA406690EC08C1B4C37222A9FBEFE2
              B488549CB2FFA158E26125A21D209CBCDF816A964331C84C92424134F5C07E2A
              3A603F4996533B1448F63D210778745FFE3FE9C09BFF5B6EFC00E389FBDFFC77
              EFBC445D0788E28882BCA50FFEEFBEF71B2BCE59729FB22810079770FB1BB0E6
              73A8CF71590EC3B842029CAB52F64F144DDB6F83CFD7FFF16150B01372C084FD
              6F08A609B21DB0F9E60F820ED874E3C73076C0C4FD348E02B1C4C34A22A907F2
              45520F1CC1A61194C00839C0AD0347760427ECFD0D4457DBA238B22128ABE1B2
              3C6BF13DFA9484EE9D97C0410D4A13200C62E3F4392D4A42517A14C5A2035919
              090F74752C38D00D12744780B2A558EA7E1750392E927260372E8BB0AA23C7F2
              41D12825B5592E9272A09E815E40386DBFC680764C4601031501004DB578AB5A
              F69A9F0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Exit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000EC49444154789C
              ED963F6A024118C53F499D2BD85ACD7B8258E5028AB5D864CF2148B0B6F20CD6
              B9857D1AE709828D904D9F0344183190A05BB9B2BB03C93C78C514C3F7E3FB37
              63969454902747023E44861B9D6F9C1B5A5512999708FE6D4FBE570910EE7102
              B0D82508662D4F3E0BC85EC7E387C601046417E7F5B6D76BC70408023E054C1A
              2D819C9B09F8BA1A5160B5EB741E6B07B09FFBDD6EDF03FB42360E229F6A05F0
              E4F4D7C0DC036F0588A3C89773A66A0150895EF9A300C0E2C24B916AB40416BB
              0943EC3154EC45A4D8AB38C47E8CAC2A290130F2A774E3DCB00CC439F8161854
              0690F4EF740298AD9F0B8F1257C80000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_NewFolder'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000014349444154789C
              63601805A380CA402557855DAFD6384FB7C6F0846EADD11730AE313CA1576D98
              0B9263A025D0AFD297D6AB35BAA0576BF41F84DD7A3CC118C6D7AD313A0F5243
              439F1BA158FEE3D70F304677044D4242AFD6380F66090827CD4BFD0F032036B2
              9C4EAD610E4E839C17B8FF27849DE67B84A2EBD3AD353C09F379DA82CCFF3D3B
              FAE00E00B141628890303C4E91039CE7BBBD769AED248E120235469F61C18E0B
              C0A3A3C6E833650E58000A05B70DE43A40B7C6F023C50E7046C346AD66FFE917
              050B30B1D544BBFF744B84CED8A3E4BF51332414086543AD7A2D36AA3BC07981
              FB7FC7392E188E20B92072A6C001B09000458771ABF97FFD7A633006B141C18E
              D7E7D472002ECC402C701E75C082D128701F4D84FF47B3A1F3801644F3DD1E53
              DB72A705EE8F887680D302574F90066A5AEE3CDFCD8368078C82110700B0D348
              16DF56D9EE0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Undo'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000012549444154789C
              ED96BD4A03411485EF5AEB169BB98B9D0FE23B681BC145C9DE6B215868639936
              8D82163E812F10B135670212041B7D0C6B51AC32B2F8B3936A258BB3CD7C70EB
              7366CE991FA2482412893431742BAC28F212BB442EA190F02156593066B5EE6B
              5004135F1FDC6D18C5732D1ED00097934D2378F1C58D62142402A3E81BC1FBAF
              B0D80F16ECFFBB30914B8C4E470BAB16FB9A8BBD62B1A74D6314C746B05345B7
              943C2B8AC5BC5B8CD8C75C26DBDD19D01F2318F706F76B2D22C09B515C57056C
              1A167BCE821BBF3FDF313E65470F69B012A6E52C63C1052BE6FE4E50E863C807
              D33DDF444FED56F08BC8A8BDF48B49A1AFE2B49C65759C982F774487ED1E2316
              7BEBC5D8A7D0B0E2CC2BF44917068A4E5ED31A9754F175F29F8844E80F7C0226
              2B5720783401C10000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Normalize'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000018149444154789C
              ED97BD4EC33010C7DD474090B1EA428105060626A42A2ECACE004FD0EEBC126A
              2E6661E205A2760504230B0F808494203B0409E1EA5A05DCD20FD7360D434E3A
              259263DFEFF2BFB313422AFB6FB6D58907E8A50178DD58A2BB5C3360591DBD14
              8036CB7768C833742D08CF310005011484F443FEE9875963AD0027903731F018
              40845A933C0D005D4DD5EC5BF0B6E704C0EFA5BBA8A70F5C501047F39EC38045
              F608A2155C07A0C86A9419F0E76348369C65BF0C40D5F40742DC10296BD6DAEB
              004C5434F0FE37484F5C38C95E05C8D9F6E0E3AA2955BF8BCEBE70E1A7287899
              1E7B65870F383F61FBB7D363B8168EE1B5B83702B867E7A3AC1276F02BC86374
              9AB72FD3CD5970460044B3A2F1F52B45D937AAFC65000B3595B246815F4F14A6
              89F6F30074FA195B115B528130CB7E16806E45E3A64481BFE3268507107101D0
              5A71375BE9D8D501A036FD6C0BE08759C3BAA26D000296D58B0F092B4D4D0188
              2B4D6D004A31AF02E88E25F84B5FF8DFE175E2B45480CAC89A6D087892796EE9
              736D580000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Smooth'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000021449444154789C
              ED97CF6B134114C7272262EFEE4D6F5EBC786D6F75479B6A21FE03B6A292F4D0
              AB877A13A48297E2592F826636B5F5D0B414CC6C31C1B4B5885A5A53D1C0CC82
              45C1A364663799913C99FE8055648DB86915F60B0FF630F0FDBC79DF07B30825
              FAD7742C5BA99A3A30002B57015309004A46F0BF86F026C021A7A65E4FAEB6EA
              67891CC34464319199338EECB51F896BD8690C238054EC00FD65386C13397A61
              4A7A9848882A3B2F466201008014E5FAF9FDB5E6869D97EBBF338E1D6091B54E
              DF5E6EC180F3A3C16041B42F17FD2FD71703C82DF89E4DE43CCE8B554CC42CCE
              8B2BB18CA06F1A7A2E1583B5B071BA20D5C4521366DFEB7BE53A1CA75C355CAE
              C1F5F4F94E1AEA18205DF04F60225F85CD878BB2FDE49D9294A936F59AA7CC39
              97A91B0680725D4371000040EAEECBD6E6D063A9C2E6634F83AD12D3B063A6E8
              DEF9E91A1C71997EE1725DFD7300809459199B88ABFD0F8393D8690C64664425
              6C7CCE9170AB1A7CA05C0F6E5F35D750623AD3B1591480496A54922FCEF8F060
              5D998EC7CDEE53A6574C996FD4550047C2E842F069BEAEB63B369BF057865123
              98580AEA23737E235D105B4353F2CDF8B3009CB7CDCF2B1FA1C7CC9672BD6C72
              81E294150AE16E80C065EA1B657A7337D193B11A4601943D38EA327DC700EC85
              8C7AAA0F7553D62FD6B0C455AFCBF54657AEFC67254F322B7994E67642D8CD8A
              FCEFB0B295AF070A9008EDB3BE03EE9BA1EA199D5C690000000049454E44AE42
              6082}
          end>
      end
      item
        Name = 'Menu\Menu_Trim'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000020049444154789C
              ED56BF4F023118ADB88B722D260E0E0EFE8A7F8C09D1496202AD8618FD176EE1
              94BFC5515D94C857D0C14D1C60D0C15937631C34E0991E9C577A40A9DE11075F
              D284C04BFBBED7F77D05A17FFC7DB813E93C6C89253E47CFD78030C812C6DDCE
              026704BE23F1B32862019F84553283B9954C8713A10064BB0942F999BF29A6FC
              7536076B2ACDDA816542E125E0C139DA389EFCBD0084506AFF668A30684A221E
              E7F6CA96FF7BB2703583197FF8AE9CC27D721BA65194B0D40A195C78158EE850
              2448EFC0BA72C70EA6FC50CE08A67C13C509D29B7221261044A1886287DD6B79
              2CA1D361E6E06A9E30FE2EDDFB47BA505E4063813DC0013F9471032BA1534319
              EBE169B50B2814D550C6D605D6A049378E3990D44C3ADDA4FC3152BBB555CCAA
              254CF99354F9DBA0B740541F84923FE37CB594CAF315F3936D3781199408E32D
              35ED84425B045170427C0AED109FF15688AF03EE1CEE6F206D1A04D0DBB42FBF
              A72BFAF2B5B613BF720A0D2B77BDE4FFC3B1B6BD2036FCCA84EDA67C933E6F61
              5A5B0C09CCF395C0EA9EC76824BE560061FCB41BA2DB2122EBDD8A4F4CF9D108
              6070672440E26B0560C9522B77B934D4520A4553BE56404A0E1583A61C1C6FB3
              60E0844338025F2B4000537EA4F47DDDBB47B9CFA56A4CF97AD86EA26B6D7810
              79DF81131A44267CA3078881E385ADB38AC36C34E5FF4338F005B2CDA0DCAD83
              3DC00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_BatchJobs'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000012849444154789C
              ED97316BC2401886EF9778832EFD0F9D132543FB779A43D0BF70BA0A6DC40E1E
              A2885B041D04A74BDC12C12E49262737A114AE044C36A3F75DF5A0E68577FDDE
              877B93E33B844A5D904FB716A741E275420131EF04B147C306828AA70380E1B9
              691081013CD5F093A54287A66B31C34D983917108F5F1662D5DC2800186E0C0D
              CF215E977000A6189E590AC0AEF42D829D84604740DCAA0D44EF79A600803F62
              68780E511DC001886278E61280FDCB0AFCD197683F7DEA0348B5DF1D0435A7FA
              00527D1F7FC4E46DAD0F20535125770128AAE46E00E72A791C80BDCE0A7CD98F
              F09A958CDCEA37A441C4BB615DCB458464440A8672B6835CC5729B30B962B804
              403434DCBA16000495FD072B995D71E00F101BBF375420D270821DB96347A510
              FA05B85F4FDC798523E00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Benchmark'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000002AA49444154789C
              ED56CF6B134114DE7FC04A92197FC5568F2AEA7F20542FB5351651E8B9D6992D
              6A5BE9C1567B945AAC27AB1745111373A8059B92FA0B2CCC8B510C0ADA4B6D8A
              A016E2AD1E4C202DB465E4AD6E324D4C76368982D8070F96DD9DF9BEF7BEF7DE
              8C61ACDBBF6A848957948344270CE27F9D00FD056EFBFF41C063C61B2813DD84
              C333C24436270117597C47B9E8F2B4C7EA6B0EECED9CF2532E6E510E2B859117
              3913AB94C1D8E64EB1B326E09B4C718C30C8380217B948FB38B456054E389CB3
              2252363E34342D072229197C9B968F924B96E3F3C5F1943C7879BA281BC4849E
              8A23A70AF8FEFE84BC11FB269F7F5A2EEBD76141EEEE8D4BD2319523E13A135E
              26B6AB693F70E99D9CF8B0E8088E7E25FA45FA0261B9B1399427817274BCDCA6
              4D8070B8AB46EE06DC7B242C373405A5371096BB7AE38A1C705BBFD578BEDAAF
              89052DF0AB93F356E408EE69B92F87263E5B922935B18299758EDE841EB5E02A
              05B7BF350E2A85C962679D0930786A2F18887CAD0A1CFDC2C394DA9A8F75F4FF
              682FC0F62AA7B7FFF8A8AC6B0A960447C73D1419923A19C8D80B26E7964A1268
              687B6001A3D71D0E59847EF71FEEA19C9A993F42C07F62B4E47FD1649E0065E2
              BB2301CAC59C8E04C3D1798BC48EB631AB0E4AFD77EF8D22018359974598D2EA
              8272DEEFB60829175DF6029CEDD512681C7C9F27608AD38E043CEDB1FA4A0651
              A9734149FFB2D62042A35CDCB117EE39FF5A8ECF645D83476616E5DEBE845A80
              370D971790B47A18E1866EC0718D5AFDC48C6D35DC18E1D0AC4AB1AF2F214734
              E440C90A225FF59D82A3AEC0D79C0B0517129CED385EB1BD704EA0E333BE5B53
              70B9EB99E836AA311F8756550E6DC7B43311306A615B4EBEA0948911AC649D4B
              29611072ADB98E611BE1914A997882530DC7B635BA19CCE290A11CCE68B7DABA
              193FED07235450641DA02F3A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_NewMaterial'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000BD49444154789C
              63601805A3804460DC6AFE5FAFD6082B366E33FFCF406BA087C372181EFE0E30
              6EC31305AD748802E705EEFFF1E15107308C46C1B04E8411EBA30BD27667FDC7
              87416A68E680B8AD49EF093900A466C07C9F46CB508823C2F7340B8508127C4F
              93508823C1F7540F8508327C4FD5508823C3F7540B85080A7C4F955088A3C0F7
              14874204157C4F5128C451C1F7648742F0C6083D6A590EC3816BC3748876407D
              7D3D4BDC96E457540B812D492F4166921C0DA360440000FD98CD7D51B3881700
              00000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_EditTable'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C18000000DB49444154789C
              63601805A3000988A4EDF3164D39F04434F5C07F2AE1C722A9073C198805A2A9
              071E53D17228DEFF881407FCA7051E7A0ED87DEF375E6CD77C1E8C09A91B7580
              E8908D02D1814E84A23470C0D32006F7018B828F8DA24B9E0532FC7F16C0D04F
              7707B4B715FFFFB942F5FFFB2AC1FF3047FC676060A48B03DAA196C3F0BB7201
              882302193C68EE805B8727A0580EC3EF9B4516D32511D6B7946358FE63854A3D
              51694094068E2068394D13E172D50686215512EE1EF10E101D8E75C1D068948A
              A41EF0A4AE23F63F124DDB8FBDD81D05A380010200FE81D90002F6D4D8000000
              0049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_Help'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000019249444154789C
              63601805830E845E611349D9DF299AB2FF9952C585FFB6F3DFFF775AFA952C6C
              3BEFFD7FA5F2F3FF4553F73F1549DDDF01329BA0FD22A9FB3B44530FFC076190
              01E45A0EC33673DF83CD0261B0230801D194FDCF601A28B51C86E10E4839F09C
              B00352218A69E100101E750003A551E0BCF4EBFFBE933FFFDF7EF7F7FFEFBFFF
              FFFFFDF7FFFFC38F7FFFCFBFF8EBBFC70A3A44C1AA6BBFFEC3C0F7DFFFFFBFFF
              FE0FCEBFFCEAEF7FB7E5347440FEEEEF70CB400E8159567DE0C7FF3F50774C3C
              FD93760EE839F1F3FFCB2FFFFE3FFFFCEFBFF33254B96B6FFE821DB0E7FE6FFA
              E782E88DDFFE7FFD050982C5977FD1D70169DBBEFF7F0B4D07AFBEFEFB1FB4F6
              1BFD1C90B5E3FBFF2F509F83A2267EF377FA16440F3F42E2FDC5977FFFC3D763
              FA9CA60E085DF70D9E234AF7FEA07F511CBAEEDBFF030FFF8071089678A7B903
              FC567FFB3FEBFC2F304EC011F7347540CC464414341EFE31021DE044021E7580
              E8108B82FD4F69E68094034F06B6599E72A09DB88E492AC811FB9F823A159438
              026439C91D9351C04067000072EDB969F46BBC7B0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_About'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000021B49444154789C
              ED57CD4A1B51141EA8755951EFA50F507F28742155577D0911FA02E6DE889B16
              5149777D8176A3C5BDD83770A569728EA955111742A5D15850B7B6946AA02961
              92534E7444C7CC9D3B3A5311FCE040B8339CEFCB774ECE3D719CBB0C227AC071
              9B024E88A8FADF083B4772BD52614628FC241516735F7FBA85E22F973F9F9D65
              F89DF889D3302035E4A446BA1843EFB668F8FDD6A5330EA1E08B4CE55FDC9C39
              BDF950289C951AEA7E128E72C5A5AA5BBF727E1A50171A3E708E6B713F4AAD76
              488DD03C3952D7EB15FA5BAD915BABD393572B012290A4827CDBD8E7F6C8DF5C
              2AC89BC80F7F54C8C3C151C52C4243C179B9DD6ACD2F1AB60725439AFC58223F
              26E6770D02B82F70C68ABC53E36050CDBD60323FC6E7CC021A3DA1F2FDA102A4
              C1FA8B2560DB3DEC1FFD0929C1B90B592379470A9F8625F18209AD9AD017C639
              21D3F0C636D1B543C154A000C1D32C610142C392A9FEA5C41DD0B86372A06C9B
              68E3FBF17913AEEFFDB677406139D8010D27B689FC88D003C72601BBC90BC0A2
              A904D9A40508058B8626C44CE20E68980C766014BB9377A0D0132880D16CF188
              4B40E8286648057D52412D7E01969711833799B805088DD34EA485449B4BC1C3
              C7C35A296C10455C4818BC46D95CCD16D6E7A2AF649797D299B005A56928A835
              6C7F0B2DCE4DF178049E498D0BF63F35CC8AF4F273276E089E130AA6F84A3DFB
              33523EBDC0E01B4FB8C6B351EC8E9DF81E4E82F8078AF0453E531D0B74000000
              0049454E44AE426082}
          end>
      end
      item
        Name = 'Menu\Menu_SaveAs'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D4948445200000020000000200806000000737A7A
              F4000000097048597300000B1300000B1301009A9C180000012B49444154789C
              63601805A3000B10493EE0259A7AE0B168EA81FF30CCEFB7E23FAFFB429C1824
              0F51BBBF818152208A663908E3B31C8611EA297484289AE5A43BE0C07F91D4FD
              1D03EA00514A1C214A250790ED08512A3A0084878703F889CE86347280280518
              64E6D32006F70173C0C746D125CF0219FE3F0B60E8A7BB03DADB8AFFFF5CA1FA
              FF7D95E07F9823FE333030D2C501ED50CB61F85DB900C411810C1E3477403B9A
              E530FCBE5964315DA2A0BEA51CC3F21F2B54EAC94A0351932EFF7FF6FEC77F42
              E0E9BB1FFF23265EC2EA08A22DC7E60090C1C482276F7F6046C57255D26A4751
              3407900AB0950343DB014F298802AA382062E225A21C01B23C7CC225EA3B4094
              423CEA00066AB48A45C9C6FB1F91EC0091D4039E208DD4B05C346D3FFE8A6714
              300C30000095F4DD30E08232D40000000049454E44AE426082}
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
