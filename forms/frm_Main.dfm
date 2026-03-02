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
      RzPanel1)
    LowerRightControls = (
      pnlMain
      FStructurePanel)
    object RzPanel1: TRzPanel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 239
      Height = 1085
      Align = alClient
      BorderOuter = fsFlatRounded
      TabOrder = 0
      Color = 15987699
      object tlbrFile: TRzToolbar
        AlignWithMargins = True
        Left = 5
        Top = 5
        Width = 229
        Height = 29
        Images = vliProject
        TextOptions = ttoCustom
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        ParentShowHint = False
        ShowHint = True
        StyleName = 'Windows'
        TabOrder = 0
        ToolbarControls = (
          BtnNew
          BtnOpen
          btnReopenProject
          rzspcr2
          BtnSave
          RzSpacer1
          BtnPrint)
        object BtnNew: TRzToolButton
          Left = 7
          Top = 2
          DisabledIndex = 1
          ImageIndex = 0
          Action = FileNew
        end
        object BtnOpen: TRzToolButton
          Left = 35
          Top = 2
          Width = 39
          DisabledIndex = 3
          DropDownMenu = pmRecentList
          ImageIndex = 1
          ToolStyle = tsDropDown
          Action = FileOpen
        end
        object BtnSave: TRzToolButton
          Left = 116
          Top = 2
          DisabledIndex = 5
          ImageIndex = 3
          Action = FileSave
        end
        object RzSpacer1: TRzSpacer
          Left = 144
          Top = 2
        end
        object BtnPrint: TRzToolButton
          Left = 155
          Top = 2
          DisabledIndex = 7
          ImageIndex = 4
          Action = FilePrint
        end
        object btnReopenProject: TRzToolButton
          Left = 77
          Top = 2
          DisabledIndex = 23
          ImageIndex = 2
          Action = actProjectReopen
        end
        object rzspcr2: TRzSpacer
          Left = 105
          Top = 2
        end
      end
      object RzPanel5: TRzPanel
        AlignWithMargins = True
        Left = 5
        Top = 998
        Width = 229
        Height = 82
        Align = alBottom
        BorderOuter = fsFlatRounded
        FlatColor = clSkyBlue
        TabOrder = 1
        Color = 15987699
        object mmDescription: TRzMemo
          AlignWithMargins = True
          Left = 5
          Top = 5
          Width = 219
          Height = 72
          Align = alClient
          BevelInner = bvNone
          BevelOuter = bvNone
          BorderStyle = bsNone
          Color = clBtnFace
          ReadOnly = True
          TabOrder = 0
          StyleName = 'Windows'
          FrameHotColor = cl3DDkShadow
          FrameHotStyle = fsNone
          FrameVisible = True
          ReadOnlyColor = clBtnFace
        end
      end
      object tlbrProject: TRzToolbar
        AlignWithMargins = True
        Left = 5
        Top = 40
        Width = 229
        Height = 29
        Hint = 'Delete item'
        Images = vliProject
        TextOptions = ttoCustom
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        ParentShowHint = False
        ShowHint = True
        StyleName = 'Windows'
        TabOrder = 2
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
        object btnAddModel: TRzToolButton
          Left = 7
          Top = 2
          DisabledIndex = 9
          ImageIndex = 5
          Action = ModelCreate
        end
        object BtnExport: TRzToolButton
          Left = 35
          Top = 2
          DisabledIndex = 11
          ImageIndex = 6
          Action = actProjectItemDuplicate
        end
        object BtnCopy: TRzToolButton
          Left = 63
          Top = 2
          Hint = 'Copy model to clipboard'
          DisabledIndex = 13
          ImageIndex = 7
          Action = actModelCopy
        end
        object BtnPaste: TRzToolButton
          Left = 91
          Top = 2
          Hint = 'Paste model'
          DisabledIndex = 15
          ImageIndex = 8
          Action = actModelPaste
        end
        object BtnEdit: TRzToolButton
          Left = 119
          Top = 2
          Hint = 'Properites'
          DisabledIndex = 17
          ImageIndex = 9
          Action = actItemProperites
        end
        object RzSpacer4: TRzSpacer
          Left = 147
          Top = 2
        end
        object btnAddExtension: TRzToolButton
          Left = 158
          Top = 2
          Hint = 'Add extension'
          DisabledIndex = 19
          ImageIndex = 10
          Action = ProjectItemExtension
        end
        object RzSpacer5: TRzSpacer
          Left = 186
          Top = 2
        end
        object BtnRecycle: TRzToolButton
          Left = 197
          Top = 2
          Hint = 'Delete item'
          DisabledIndex = 21
          ImageIndex = 11
          Action = ProjectItemDelete
        end
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
        Top = 776
        Width = 1363
        Height = 304
        Align = alBottom
        BorderOuter = fsFlatRounded
        FlatColor = clSkyBlue
        TabOrder = 0
        Color = 15987699
        inline FChartInfo: TfrmChartInfo
          Left = 2
          Top = 2
          Width = 1359
          Height = 55
          Align = alTop
          Color = 15987699
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentColor = False
          ParentFont = False
          TabOrder = 0
          ExplicitLeft = 2
          ExplicitTop = 2
          ExplicitWidth = 1359
          ExplicitHeight = 55
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
        inline FChartPages: TfrmChartPages
          AlignWithMargins = True
          Left = 5
          Top = 60
          Width = 1353
          Height = 239
          Align = alClient
          TabOrder = 1
          ExplicitLeft = 5
          ExplicitTop = 60
          ExplicitWidth = 1353
          ExplicitHeight = 239
          inherited Pages: TRzPageControl
            Width = 1353
            Height = 239
            ExplicitWidth = 1353
            ExplicitHeight = 239
            FixedDimension = 21
            inherited tsThickness: TRzTabSheet
              inherited chThickness: TChart
                Width = 1343
                Height = 208
              end
            end
            inherited tsProfile: TRzTabSheet
              inherited chProfile: TChart
                Width = 1343
                Height = 208
              end
            end
            inherited tsFittingProgress: TRzTabSheet
              ExplicitWidth = 1349
              ExplicitHeight = 214
              inherited chFittingProgress: TChart
                Width = 1343
                Height = 208
                ExplicitWidth = 1343
                ExplicitHeight = 208
                inherited btnCopyConvergence: TRzButton
                  Left = 1273
                  ExplicitLeft = 1273
                end
              end
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
            inherited edPolyOrder: TEdit
              Height = 21
              StyleElements = [seFont, seClient, seBorder]
              ExplicitHeight = 21
            end
            inherited cbTWChi: TComboBox
              StyleElements = [seFont, seClient, seBorder]
              ExplicitHeight = 21
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
        end
        object BtnFastForward: TRzToolButton
          Left = 35
          Top = 2
          Hint = 'Calculate all'
          ImageIndex = 1
          Action = CalcAll
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
          ImageIndex = 8
        end
      end
      object Chart: TChart
        AlignWithMargins = True
        Left = 5
        Top = 164
        Width = 1363
        Height = 606
        Cursor = crCross
        Legend.CheckBoxes = True
        Legend.LegendStyle = lsSeries
        Legend.ResizeChart = False
        MarginBottom = 1
        MarginLeft = 2
        MarginRight = 1
        MarginTop = 2
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        OnZoom = ChartZoom
        BottomAxis.Automatic = False
        BottomAxis.AutomaticMaximum = False
        BottomAxis.AutomaticMinimum = False
        BottomAxis.Maximum = 10.000000000000000000
        BottomAxis.Title.Caption = 'Angle'
        BottomAxis.Title.Font.Height = -16
        LeftAxis.Automatic = False
        LeftAxis.AutomaticMaximum = False
        LeftAxis.AutomaticMinimum = False
        LeftAxis.Logarithmic = True
        LeftAxis.Maximum = 1.000000000000000000
        LeftAxis.Minimum = 0.000000100000000000
        LeftAxis.Title.Caption = 'Reflectivity'
        LeftAxis.Title.Font.Height = -16
        View3D = False
        Align = alClient
        BevelOuter = bvNone
        Color = 16056319
        TabOrder = 3
        OnMouseMove = ChartMouseMove
        OnMouseUp = ChartMouseUp
        OnResize = ChartResize
        ExplicitLeft = 269
        ExplicitTop = 200
        ExplicitWidth = 400
        ExplicitHeight = 250
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
        object btnStop: TRzBitBtn
          Left = 584
          Top = 41
          Width = 128
          Height = 40
          FrameColor = clRed
          ModalResult = 3
          Action = CalcStop
          Caption = 'Stop'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clRed
          Font.Height = -19
          Font.Name = 'Segoe UI'
          Font.Style = [fsBold]
          ParentFont = False
          StyleName = 'Windows'
          TabOrder = 0
          ImageIndex = 46
          Images = ilIcons
          Margin = 4
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
    Left = 512
    Top = 368
    object File1: TMenuItem
      Caption = 'File'
      object File2: TMenuItem
        Action = FileNew
      end
      object Openproject1: TMenuItem
        Action = FileOpen
      end
      object miRecent: TMenuItem
        Caption = 'Recent projects'
      end
      object Openproject2: TMenuItem
        Action = FileSave
      end
      object Saveprojectas1: TMenuItem
        Action = FileSaveAs
      end
      object Saveprojectas2: TMenuItem
        Caption = '-'
      end
      object Settings1: TMenuItem
        Action = actSystemSettings
      end
      object Settings2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Action = actSystemExit
      end
    end
    object Project1: TMenuItem
      Caption = 'Project'
      object New1: TMenuItem
        Action = ModelCreate
        Caption = 'New model'
      end
      object Newextension1: TMenuItem
        Action = actProjectItemDuplicate
      end
      object Copymodel1: TMenuItem
        Action = actModelCopy
      end
      object PasteModel1: TMenuItem
        Action = actModelPaste
      end
      object N8: TMenuItem
        Caption = '-'
      end
      object NewFolder1: TMenuItem
        Action = ProjectAddFolder
      end
    end
    object Project2: TMenuItem
      Caption = 'Structure'
      Hint = 'Add Stack'
      ImageIndex = 1
      object Add1: TMenuItem
        Action = PeriodAdd
        Caption = 'Add Stack'
      end
      object Insert1: TMenuItem
        Action = PeriodInsert
        Caption = 'Insert Stack'
      end
      object Delete1: TMenuItem
        Action = PeriodDelete
        Caption = 'Delete Stack'
      end
      object N3: TMenuItem
        Caption = '-'
      end
      object Add2: TMenuItem
        Action = LayerAdd
        Caption = 'Add Layer'
      end
      object Insert2: TMenuItem
        Action = LayerInsert
        Caption = 'Insert Layer'
      end
      object Copy1: TMenuItem
        Action = actLayerCopy
        Caption = 'Copy Layer'
      end
      object Paste1: TMenuItem
        Action = LayerPaste
      end
      object N4: TMenuItem
        Caption = '-'
      end
      object actProjecEditModelText1: TMenuItem
        Action = actProjecEditModelText
      end
      object Copyasimage1: TMenuItem
        Action = actCopyStructureBitmap
      end
      object N9: TMenuItem
        Caption = '-'
      end
      object Cut1: TMenuItem
        Action = LayerCut
      end
      object Delete2: TMenuItem
        Action = LayerDelete
      end
      object N12: TMenuItem
        Caption = '-'
      end
      object N13: TMenuItem
        Caption = '-'
      end
      object Undo1: TMenuItem
        Action = acStructureUndo
      end
    end
    object Data1: TMenuItem
      Caption = 'Data'
      object Loadfromfile1: TMenuItem
        Action = DataLoad
        Caption = 'Load ...'
      end
      object Pastefromclipboard1: TMenuItem
        Action = DataPaste
      end
      object N6: TMenuItem
        Caption = '-'
      end
      object Normalize1: TMenuItem
        Action = DataNorm
        Caption = 'Normalize ...'
      end
      object NormalizeAuto1: TMenuItem
        Action = DataNormAuto
        Caption = 'Normalize (Auto)'
      end
      object Smooth1: TMenuItem
        Action = actDataSmooth
      end
      object rim1: TMenuItem
        Action = actDataTrim
      end
      object N7: TMenuItem
        Caption = '-'
      end
      object Copytoclipboad1: TMenuItem
        Action = DataCopyClpbrd
        Caption = 'Copy to clipboard'
      end
      object Exporttofile1: TMenuItem
        Caption = 'Export to file ...'
      end
    end
    object Calc1: TMenuItem
      Caption = 'Calc'
      object Calc3: TMenuItem
        Action = CalcRun
      end
      object Calcall1: TMenuItem
        Caption = 'Calc all'
        ShortCut = 123
      end
      object N10: TMenuItem
        Caption = '-'
      end
      object Fitting1: TMenuItem
        Action = actAutoFitting
      end
      object Calcbatchjobs1: TMenuItem
        Action = actCalcFitJobs
      end
      object N14: TMenuItem
        Caption = '-'
      end
      object Benchmark1: TMenuItem
        Action = actCalcBenchmark
      end
    end
    object Result1: TMenuItem
      Caption = 'Result'
      object Save1: TMenuItem
        Action = ResultSave
      end
      object Saveplotasfile1: TMenuItem
        Action = FilePlotToFile
      end
      object N2: TMenuItem
        Caption = '-'
      end
      object Copytoclipboard1: TMenuItem
        Action = ResultCopy
      end
      object CopyasBMP1: TMenuItem
        Action = FileCopyPlotBMP
      end
      object CopyasWMF1: TMenuItem
        Action = FilePlotCopyWMF
      end
    end
    object ools1: TMenuItem
      Caption = 'Tools'
      object ShowLibrary1: TMenuItem
        Action = actNewMaterial
        Caption = 'Create new material ...'
      end
      object EditHenketable1: TMenuItem
        Action = actEditHenke
      end
      object N11: TMenuItem
        Caption = '-'
      end
      object MaterialsLibrary1: TMenuItem
        Caption = 'Materials Library'
        Enabled = False
      end
    end
    object Calc2: TMenuItem
      Caption = 'Help'
      object UserManual1: TMenuItem
        Action = HelpContent
      end
      object N15: TMenuItem
        Caption = '-'
      end
      object About1: TMenuItem
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
                ImageIndex = 13
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
      OnExecute = FileNewExecute
    end
    object FileOpen: TAction
      Category = 'Project'
      Caption = 'Open project ...'
      ShortCut = 114
      OnExecute = FileOpenExecute
    end
    object FileSave: TAction
      Category = 'Project'
      Caption = 'Save project'
      ShortCut = 16467
      OnExecute = FileSaveExecute
    end
    object FilePrint: TAction
      Category = 'Project'
      Caption = 'Print'
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
  end
  object dlgOpenProject: TOpenDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project|*.xrcx'
    Title = 'Load project'
    Left = 168
    Top = 180
  end
  object Zip: TAbZipper
    AutoSave = False
    DOSMode = False
    Left = 189
    Top = 299
  end
  object UnZip: TAbUnZipper
    Left = 169
    Top = 299
  end
  object dlgSaveResult: TSaveDialog
    DefaultExt = 'dat'
    Filter = 'ASCII data|*.dat'
    Title = 'Save result to file'
    Left = 208
    Top = 204
  end
  object dlgLoadData: TOpenDialog
    DefaultExt = 'dat'
    Filter = 'ASCII data|*.txt;*.csv;*.tet|Counter files|*.dat|All files|*.*'
    Title = 'Load curve from file'
    Left = 208
    Top = 176
  end
  object dlgSaveProject: TSaveDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project|*.xrcx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Save project'
    Left = 168
    Top = 212
  end
  object dlgExport: TSaveDialog
    Filter = 
      'Bitmaps (*.bmp)|*.bmp|Enhanced Metafiles (*.emf)|*.emf|Metafiles' +
      ' (*.wmf)|*.wmf'
    Left = 240
    Top = 204
  end
  object pmProject: TPopupMenu
    OnPopup = pmProjectPopup
    Left = 32
    Top = 408
    object pmiEnabled: TMenuItem
      AutoCheck = True
      Caption = 'Enabled'
      ShortCut = 114
      OnClick = pmiEnabledClick
    end
    object pmiVisible: TMenuItem
      AutoCheck = True
      Caption = 'Visible'
      OnClick = pmiVisibleClick
    end
    object pmiLinked: TMenuItem
      AutoCheck = True
      Caption = 'Linked'
      OnClick = pmiLinkedClick
    end
    object pmiNorm: TMenuItem
      Caption = 'Normalize'
      object Auto1: TMenuItem
        Action = DataNormAuto
      end
      object Manual1: TMenuItem
        Action = DataNorm
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Properties1: TMenuItem
      Action = actItemProperites
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object pmCopytoclipboard: TMenuItem
      Action = DataCopyClpbrd
      Caption = 'Copy data'
    end
    object pmExporttofile: TMenuItem
      Action = DataExport
      Caption = 'Export Data'
    end
  end
  object dlgPrint: TPrintDialog
    Left = 276
    Top = 232
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
              6D0000000473424954080808087C086488000002C5494441545885ED98CF4FD3
              6018C7BF63ACACC860838D81FC103661D108599068A2980C13305E3C633CA98B
              C48BDED43FC118FD0344CD0C5E48F46044123390E101500222443607194C8491
              01DD6085305A967A2AD184626969E7619FD3FBE6799EF6D3F74DDEF7ED0B6490
              874628F0E4C5EB85E35565ACDC1744A978512C4E530FDADBAAE53EEB2FDE7D1C
              0A738740EFE018F76B69997BF8B46B4E8A47D6A17E9500E525165CBB72B14A8A
              A42A82807449D504016992AA0A020797545D103898645A0401F192691304C449
              662B2D61AB2845DFD0D77D730A8D7966A1982A82B68AD27D73BAFB8729A1585A
              A7580C1941B96404E59211944B46502E6913A4A91046BBEF80A642D06AB5821E
              AA09D254083BCCC66E3B32D589C6A633884C75C2406C9800C0E77119BD1D2DCE
              3FEB14DF8B7922531E90B924D89D14002D1C75350000475D0DD8C981DC80EFEE
              1C4110BACDF5C43600BBAA825B7414642E894AFBB13DE3A7EA6BB3005401C06C
              6072D1E771199BAF0FAC012A4D311D0BC190AF17956B325BCB9814E1E2FB8A8E
              E0161DC5FCC44B180C1C8A2BCB45D5982C569C749E7DF6E58DE5766C856A5774
              0483838F60AF35E3A848399E725BADB9E142736B4151C10745058BAB9BC132D2
              6E4F588605529AE70A0BBA303FBB24A97666722C70EE6AD7E3FF7A27F1795C46
              450523C11E54DAF6FF1F11A2A6FEF4891C7D895B51C1D8E20874844E52AD8ED0
              015ADC5454D071FE1E42D3AB88CC2F1CA82EFCE37B7CF453DFFB756AEDB2A2EB
              2069B0C2D1741FCB3F87105F1986C962FD674D7C258A69FFF88D4B6EEF5B40A5
              9DC45068079D488ACA5D5B8D46082D33C0F705477026BC98DDDDFF392CDB0E40
              91D9623C124FE427FDC1149364580EDBB1BA86C6DDD53B303E12D468347A2287
              CCDE5C4F6CF3FBB0AA783B5A9C3E8FCBC8B7277ADC7E2EF68A9BE871FBF923D6
              5EC72DC14B74A5F176B438F5645E57726BA3ADF556EF37A1BCDF100143F83B35
              E7710000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\02_OpenProject'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000021B494441545885EDD83F6FD3
              401CC6F1C7FFE21A1BA7B8342902A448202121C1D0A92FA16C881121046CBC8A
              281B23AF804AA83313121D10AA588009D68AA145AD5AA069EA9404D7BEB3CD50
              9FC85D86368953DFE0EF6629E77C1CC73FC701CACA8A4D0180D7AD7BDB5ED5A2
              A7BD38418A7637F8F4ACB9F670FAB4937400F0AA16BDD5986B9C65C1513F9C5F
              692DAF3E6DAE3D9AAA2C4B1D75816B9BF6DD9BB5FB2BADE5D56980C4F4711631
              E4DB970F36F30675BA81FEB8F9EE3ADB1E0B089C205DDBB4F361FD6F63EB606B
              707BE4537CDE95C0491BFB3BC82271821FBF7BB83063E5E181653BD73EBC7AB2
              0900BB7B079301DB7E8028D5B0B4781B1563E26365E9001A00F031249F87F6FA
              ED7B1BB5CBD533EDE9EA421D57EA5E5EB0A108A5871CF0F0E8188B776E60A176
              696A6F3A4A84902E7791C4698A4AC528CA335410529F03F6020A6FD629CAC3F5
              6BDF0789E81B0EA8A8F24C9D244D7AC7414438912A117067AFD37BFEE2FD3A0F
              54E401121AFB807027513579805404FEF91B61CE738B1309915800529AC232CD
              E24442248A78A0DF0F519F9F2D4E2414849407CA7405B319080C00659C8100F7
              096AC58984D80C04243DC56C06021990D044772FE6F383338FA8084C9244779D
              DC1FD0C68ECD4020032A9A6A3AF64C7122213603810C9842351C5B9E53CC6620
              90010D439E9BF0E00C0432A0AE69D2CC181AD394CD40207BECECF87DEDCBD78D
              53FF7E3B8F7EEE77153603CBCA64E81FE1B7C9FCDA3E62100000000049454E44
              AE426082}
          end>
      end
      item
        Name = 'Project\03_Reopen'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000028D494441545885ED983F4C13
              511CC7BF955763AF2DD7965E95415A5B930E464D4C5C5C1D5C19D4D145071707
              8D26353A991821121D5C8CC1011312A22484388009285323312191C6D0D6F6E8
              1FA44888D8DE95BE7285BAB41582B570F75A4AE033DDFDDECBF73EF7FEE4FE00
              4D8E0E007C4F7B8BBB2DF22FBAEEDDD01DDA6D895A908D27ED0E3BBCEE0E1C26
              7A04C251A41697FE5B7F72F77A5DA4EEF7BCAE1C6F1AC1D35E0F2CAD6670DC11
              78DD1D35EB8DA0EA14EB74BA1DD5EBC526C140288AB424632547118CC66BD61B
              C1A635985A5CAAACAFEDD437AE957AD1F4BB1800303CEE9F2D3619C3E3FE5960
              0F8CE081A0560E04B5B2FF0487FC090CF913CCF248ED2EDBE7C39724A6E2AB00
              004E9FC4A5F3C73567321BC160328D49310FDE2A80B70A9814F30826D39A7399
              088AA90CFAC662E078A152E378017D637188A98CA66CCD82595A40FFC41CDADA
              5D5BDADADA9DE89FF8812C2DA8CED72498A505740F04A0371FABDA476F3E8AEE
              81806A494D82BDA3117076270869A9DA8790167076277A4723AAAEA17A173F7F
              F715DF17286CFCDADF30831926330F0090A5340A39A9D29648CB7836388D3B97
              CF3446F0F695B35B6A0FDE7C034A824A4EC2E36BA7D4C657D87F4F12D61C086A
              A5E90509004463F3E4FDC7CF31B52126A3D1021441E97A2B4A374DA9B2FE6972
              3A03007276E5F74E33A3B1790294FE6EB1E2E68BA998E7A4DB0900D188187F79
              EB9C4B6B66D34F3133C14EDF88CB60349858E5956122D8E91B717116EE954370
              B4956B4A415960914D00E0EAA3F1399BCDA6A80D317006934310ECE597064AF3
              90B2F22033419BD55AF0784EB85804024038149A79FBF0620F8B2CA6DF2494E6
              110E856624BA7681552601805FCBCB04A218D312A4AC2A3FA5AC3CC86AE4F60C
              7F00736972B89074186C0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\04_Save'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C086488000001B24944415458856360180594
              014618637AF3DAC7E252E27FB029E2E51714606084283DFFE23A8F8888001339
              96FDFBFFEF1F030303C3EB576FFEF0BE635D97D310124D480F0B8C212E25FE47
              CF424F019BA2574FBFC0D962FF84181C1D8CC9711F0303030313030303C3A123
              E759340D147CA632AF59995D1B124E50C340000161413E7307339FA9CD6B56E2
              534753074E5FB00A8EB1010121012E428E1CB0108401428E1C70073230E077E4
              A070200303C29133DBD6AF45161F340E64608038D2C8C6C817D99183CA810C0C
              0C0C82C282ACA2E2A246303E0B3EC59482CC84308ACD187421880E880A411616
              26863F7FFE3130303030BC7BFB9161FFC1B36459C6CC0CA92E3F7CF84CB41EA2
              1C2824CE0567FB493B91E82CCAC0A08FE25107520A06BD037166929DE70E3228
              C94AD2C511F71E3F677037B2C72A87D3814AB2920C1EF664374C49023BF0145B
              833E8A471D482920BAB1F0F00B03AC63471520C74D9C3AA21D28CF43AE532803
              833E8A07BD0347D320A560D047F1A077E0681AA4140CFA281E7520A5009E065F
              3D7BC972E9E4A50730FEA37F2F657FFFFCF59F1E8EB8FFE405E3F77B3F1E23BB
              851EF68E0C00002ACD6E888D7852380000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\05_Print'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000025C494441545885ED98C16BD3
              501CC7BF495F98865965CE0DAD932E25CA50981571B20922D33FC1B33DC84E3D
              E6D27F60BD0C76F2D643EF9EC6AE56115C190A9B828233A42D4A15E745DBD9AC
              F4A5F1D28C62932669FBBA0CFA39FEF2E3F7FBF0F27BC94B8080C3B925AC659E
              7F936723944573B55826CAD3C7337D15D9C8E58B26233672F9A25B7FBE2FFB21
              3012EC979160BF74155C49AD9BBA5E8FB26AAEEBF5E84A6ADDEC9613F8153C7A
              502BAB99ECE4E4C49C41CD292B46298D166B1710B938CDA479F9C74FCC8ABF40
              082959B110E1F6FF542AEFD24A227924A8AC66B20B0BB79F08847414C97DD471
              459299087E2DA858BE71BA23DEA0143BBBEF9FA59544920780B3E1F0BC9D1C00
              1087F82070AA2D1002F194B804B466900F85CE31B3E811CB29309BE49EA46249
              523BE2811104EC8F56EC06CC276F0AF61B31502B6887AB20CF35D935F750DB55
              705C3040A93110A176AA077F312EB8D7759DC1B82462B7A0A16E0AA80FE8E03F
              468031AE81B824BAE67ADA245E0AF947F09475F237C971137841C71954D50254
              4D1B8A841C8B419625DB6BCE822DB9F9EB57F1E0FE5D2662AF5E6FE3C3A72F50
              35CD51D0F116CBB1181329BFBD1C57509625C8B204CE38C0DCE5092662EAA5F3
              88CC3CEA9A4300A06918BFFD147E91DF01E7FE5BA783E5C5B8E75CCB890040ED
              B0B6D5A0F4A6D3A9FA7F1E2EDEF22DE7874AB58ADA616D0B6809A6954432B596
              45F84CF88ED96C4EB5275F93A62360742CA38D06DDDBFB5C6E8F713CBF5FA956
              DE5A1F4DAE1CF7DFAD9E5666183368D19320EB196C27F0AFBA9160BFB8CEA05A
              2C93CD97DB2516CDB5D2F7C07C55F6CC3F11EF5EE0E8CD9B080000000049454E
              44AE426082}
          end>
      end
      item
        Name = 'Project\06_AddModel'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C08648800000298494441545885ED964F68D3
              501CC7BF4DD264CBBA99958D75ACA51A47513B15271E1CE8A1B09363475198A0
              2078187A133C49D1CBC0A3EC30F12038500F1EC6BA93AE8A9322559C766DC5B2
              AEDD749D23766B5D2BFB93A69E5A6BEDDA9836AE8C7E4EEFBDFC1EF9F0CB2FBF
              F7801ABB1C4D6670E3CEFDF44E8AE43374FDB20600889D1629454DB05C6A8215
              636CD2154A57096393AE50C6ABEA3358132C979A60B954BD202527C835BB0E93
              9E82494F65E739F70CC5F4743225636409F674D6159DAB49D57FE2AA17ACD560
              B9C812AC14DEC500DE7FF56133B5898DD406008021194829093DFC7174755800
              005A2D45FF57C1F96804135E27388E45BB812B18E3F9EEC5ABA01B67BBCF80A1
              19F69F0495D4A04493D0680021FE0573C2140EF3C6A2F1AD1C87568EC393E971
              B4A48C59AFEC5BC6265DA17EDBC9BD7284E5321F8DC0E17B0E8BB9B85C3E1F03
              73926F31B8FFC1A5A1B0AA6D66C2EBDC56AED76C43AFD956F0D9510B4FB471DC
              6340C53EE85D0C80E3D8D281DB70C8BCCF3A386AEFAB780DA629122081B7B333
              B0F2CD8A05DBF52D3A8A22AEA8D6073F2D88CACC72D8A36B6C55ADCD64FA5C86
              EDEA2D7FFDD9BC333B6628AD61779CC54A60C83FCFD9DCCC00BF3397BF9ECB86
              B8F54DB50CD2245D3AA804F1C49AA09A60B7C90A6135A678FF5254488AA234A2
              9A60578705B1F84FC5FBFD0B61EFF080DD91ADC16038428D3BDF842B21478020
              D886FA2623C1139E805F77C4C2FF958862B5F7CE1F482FC762E7804ADC3A4B70
              F5D1AD538666FDC313070E9AE5C4BF9EF930B79A485EBC7BFEE6140090EAEA01
              EEA72F160CA7AD2FA33F568FD5D3747323DB50F0EF598A0A49F767FF746465A5
              FFDE85DB9ECCBAEA19CC6570D4DEC7D0DA6B3A966DAAD3D26D00B0BEB5B91C4F
              AC09A2288D0C0FD81DF97B7E0130C85DF40D82C2C30000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Project\07_Export'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000019A4944415458856360180594
              01465C120D8BCF3C161513FC430F47BC7EF59EA521D644169B1C0B2E4DA26282
              7F74F5951468E62A2470F9E2BD07B8E498E8E1004AC0A8032905A30EA4148C3A
              905230281C28252322844B6EC01C78FBEE4B385B58988F0F97BA0173E0C6AD67
              19AE5C7F4250DD8046F18EDD9718B6EFBE8457CD80A7C1ABD79F306CD8729621
              A061BF0036F9017720030303C39D7B2F19FEFDFAB61F9B23078503A1C0E0DFAF
              AFF7BDAAB61A200BE26C6E110B7A266DA3D40824C028C0C2F07FBF6FE5B6C4CD
              ED5E1B18180657084201A30023E3FFF5BE555B13181806A5035101C5514C75F0
              9FE1E37F06C604581453ECC0923C2FB2F4614DBBFF193EFE616470D8D6E67501
              26346842F0FFFFFF1799D9B91DB635387E40161F14695059499C81999DDB6103
              9AE318180641086A6B4A3378BAEA33D8493062388E8161801DE8E1AAC7A0A329
              8357CD8039D0DFDB984155599CA0BA014B83C88EFBF0FECB175CEA06452679FC
              E8D51B5C7283C281F8C0A8032905A30EA4148C3A905280B32679FDEA3DCB958B
              F71FD0C311AF5F7D1CF036C1F00500F61D668A281B9C610000000049454E44AE
              426082}
          end>
      end
      item
        Name = 'Project\08_Copy'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C086488000001E6494441545885ED98BD4BC3
              4018C69F2B85524A912A22A8AD7170F38B0EA282A550EC1F20755097169B0E6E
              45C4E8E0A85D34BB22E8203AB8B95584A2434570D0C5CD8488223888D8A194D2
              B8B4D2968BB6C95924E4B7BD4FEEDE7B2EEF1DC91D012378418C128003001590
              F752C90356B90D1317C4202F88D14ACC0B62945F174759E42634F1667FFECCED
              720C6A7512EF86B95AA5F4B4BBB5ECAB56126BDB0A60F3566BC9917B592BE767
              2E7F3B163F8ED4EB765A63B7CB31E8EBEEE468CF000077B5A1AA92765E1017F6
              52C923005814769600E2ADEFF6534EE5E58DAA530D360B21C4A5AAD84CAC8A11
              0050013F8BBC0023830040087C20F0011AEB4627363D9D9CF652D37D3CCEA29E
              A1F4198CF9DF9B1AD0E32C626EE843CF50FA4A3CD051C04690BEA859A3EB0DB6
              12CBA0512C8346F9F7060D7D490E1F47D0D7DBF51D4F0542B8BABCA869D3B036
              13E24ED3BC548925E5D9BE129FF552BF4A0F2731E9C79F853299421853815003
              53699E74262B47C293FDFFBEC4E636F857E50580707082030C1AAC5FE82C4967
              B23260F612B702731BB43609CC5EE256606E83D62681D94BDC0ACC6DD0DA24D0
              38347DE6F2B74FAF6FBFDEA215DBD41EAD1CACA026A75DC5D2289FC2389686EA
              31347B4979B69F67AEE54A3C1D1CE7AA63239AA4BCFC696598F10553A299BE4A
              4F0C4B0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\09_Paste'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C086488000001F9494441545885ED98BF4B1B
              6118C73F6F10522F3D49235D8A86E0D2455AE9D049A19BB874CAA41402E61475
              3114EA35932E9A0EEDA9A0D04A41107171134AA72E3A1532D83FA088BF504328
              98344D3B782E2A462EB9E4DED306729FEDF9BECFFB3C5FDEF7BD17EE15B884A6
              1B31011100137696528965B76A4B13D78D179A6EC42E634D37625AD2E872A3B6
              B012BF7FEEDF5003FECE72938CED279152E56CEFD3CCEBF07565E8EDFB5DF0B5
              5FD7124F7FEC94AB99CB17D3CFE36BD19B7A9355B21AF077861F3D8C588D01B0
              5D1A9AA60869BA31B0944AAC020CEA1F4641B4DF9C56A9E6EE61C652B734582B
              42888069323D346144014C78E6465D70C9208010841184A1CCB971485506959E
              772571F3B745FEFCFD5753A3505045E9192FD10A9B13B6F37C3575B960E4D54B
              4241B5EAFC50502516ED75D2CAD9163FEE6863E6CDA0A386B5E26805EF12CFA0
              2C9E4159A42EEAF52F5B9C9966C51C9F4F10EDEB76DC43CAE0CF8363EE2BCA55
              1C505B00F89D3BBDD2F285824C0B3983FB0747A4F438CA3D3F000BAB5F01181B
              E80320FBEB94A9B995FF67707E72ACE278EB8316DB1C3BEAFE23F10CCAE21994
              C533284BE3181C4ECE7292C97292C9329C9C75ABAC7B7F751FA7C7ED931CD038
              5B7C5B780665F10CCA52D53553CD1BCA6D51F72B58F7062DB738972FA6F78E32
              6E3EF3D992CB17D377D9AF713807CE1171CD96AAB87D0000000049454E44AE42
              6082}
          end>
      end
      item
        Name = 'Project\10_Edit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C08648800000283494441545885ED96DF6B52
              6118C7BF47C5E5347346B526B651EA763123DD4D88370B938AA28B8DD64D41B0
              BAE93A88A82E5BD09FB0D885B0B0086275D38F5982615B108BAD706E9ACEC6D1
              79CED1992673A8A78B52B6C6F2D7F41CC2CFD5799FF73D2F1FDEE739E7798126
              FF3944E1E1E683872C97227F73FFC630010002AE454AD114AC95A6E08E31E170
              07589E30E170070A5EBC3FC1A660AD34056B85F782A27216B97D6B502B45502B
              45C5F1867B46D598342D25D7942568D2ECFAE7B89EF03EC5BC17E4650DCAA452
              4545825CD66059828D221389801C1D858A89C96707065EE51866883735C878E6
              31FEF42520DB83CEAE4E81D66CB6124AE5135ED4608C5EC634958679F002A626
              27719C0AE22091874CA1D0715E83D1B017AE9945E88D2700007D164B51329D4C
              2E719AE224E347C46387442AD914EFB358F00CB2B51C459DE74C30C9F8417EB5
              E1A8E108FA7B48F8BC1F8A73AEF7EE7C865AB11A9CCED586D6202B12004202F9
              1F7EC822E330187500008998407F0F89771E3768268536B93C3D3C72CB0570F0
              1F4C327E908147E8FE2357402226A0699D43AF7610BEE578B6106F688A0B69ED
              D66BB7CC8502511C3E76158754EA4DF186099692EBE8BD069158B665AE2182D5
              CA010D6875A17927E8453B8C6673C572409D4F70253407F2CB58D572409D0517
              3E3D47BB722FE2D1705572C08614FB83A4E8C5DBA9E04E88FDBECFB1C8A598DD
              FBBBF60913148D589E85B2BD03B3D31FD988F054D23FF32DBFDDFBB92C5B6C2D
              B577FC6DB87CD13A64D2AB6C974E6BC400108D5320693AB3E00D9FBC72D7E12A
              779FBA7D24ACA06564EC0D2DCEE6F2EBBA03390F93487D8FADFEBC73FD9EE373
              25FBD4ED04CF9C3B9B686B455448ACDFB6D95F3FAE769F5F4EF08E48EB883E31
              0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\11_AddExtension'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C08648800000251494441545885ED96CD6B13
              4118877FB69BDD1AB7BA2D8926A4F64368A8561015FC3A880404A1A537A54204
              0F050F859EFC03025EBDE650E9B120221EB411028535948292625B634CA2124D
              A24D1AB69BA6ED6E69924DF0D2481AB6A9364E73709EDBCEBCF3EEC3BCF33203
              5028140A8542A1D4E010003C9E78FEA3B7C7A6355AA692AFDF97988723B74F32
              00D0DB63D3861C57BB1BECB48357E2DB1800343556636FA860BD50C17AA182F5
              C21CE4CF824B5F30FFF313F2C53C72C51C00806BE6502A9670EDD4459CB5D91B
              23189793781D14210846582D826E4C60258899A81F772E0CC0C4B71D9C60544A
              C01BF1C1DEDD5133CE2C08300B029E2D4CE156DF8DDFE344CF605C4EC21BF6C1
              DE595BAE127B6707BC111F9482C200DB3B188D259929F15DEC5F0B7E50E6AD97
              CFF5717A7337BB1C0080E9B8A82B393317380E6CBF6648303AE91ABC74E6F453
              6BBB89FF5B4100486556147F287C9758897963CBC86E727F82B5DDC4334CD303
              62821CCB59EACD718C6F3513EB628E31EC102C97B49AEAF1CA92738CC1F2FFDE
              2439ADB00CA0ABFC5DDD0C7B35493907B11DCCE573CBF5E6585336246282CAE6
              D6444A96D4FDAE4FC992AA69A57162826EA7CB134AC482FB5D1F4AC4826EA7CB
              43B449D2D9ECF05C241CD79B9B8E8BBB9EBFD98F8BDFD2D9EC30003413F4C3E2
              CBD96CFFC095F7EBAAEAB099CCFACF181DB95545BDFFE4DEA300714100F0BF78
              93B05CEFF7C9EBABE70FB36C5BABF108AB17979225D5FF39B490CC6486CA7200
              C1BB588FD149D720C71AC678A3F1688B813D01005B857C7A4DD99034AD34EE76
              BA3CD56B7E01AD51D210C3957B2E0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Project\12_DeleteExtension'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C086488000002F1494441545885ED98CF4BDB
              6018C7BF69FBFA6E4D1B411BB3E2B40E7B183841582F0A83EE52102C5E2278DC
              61B083B0DB607FC26007AF1376295318DA4BA8739BE05618746314F4E0188C56
              CB0EA3357AD0FEC050DBECD0A6F617B6B38D96D10F049287E7259FBCEFF3BC09
              01BAFCE730DAC9F397AFD5EB14A9E6C5B3C70C0018AE5BA4115DC156E90AB60D
              692BB4AF7608D256685FF3EAF819EC0AB64A57B0553A5ED0D44C5228728AA13E
              1386FA4CA5EBB2EF8C4B33E5A40D739A129C72DEB8F05A4F3A7E893B5EB05B83
              ADD29460BB380987711C0C42CD64A0A6D300008665916318F44F4F8373B90000
              84987AAE5430138920EEF38123043CC701DA51466A63037B9284C18505D01E6A
              FE27C1CBD460BEC70886018C919FE87BB78CE1DBF60BF32D1C070B80F8E222C8
              FDA99297AE35988944207F5886D040AE1CC16EC7692868FEEA768F4C0683315D
              B799B8CF07C15E2547EB746E55CC31E2305805E12DA0E33E78120E8323A42246
              3C1E5051AC14A2145414413C9E8ADC01A7736CC7EB9D697B0DAA26236004D8F7
              9F71B7BC11288581E7C1F03CA82842F1FB0B615104C3F38599A21450140080D5
              66B3C0687CA25B0DFECE6700F49E0714058ADF5F12A273730000C666832ACB05
              E1A25CE999AC565EB725563399DA6051523D3A0263B315E40E0FEBCA010021E4
              D6F5BC8BD5E67F03E926C898CDB5C162436833A7CD644DE314C966B371FD0459
              B6BE1CCF176A6E6D0DCAEA2A54592E354E354A3229EB26D8EB7623757C5C7637
              057959AE6C08AD26651967DBDB15E393B29C462EB7A4DBBB9873B9B02749B094
              C5B29B9B155B8926AEACACD48C3F884677270281F5926034F6C714F8F42DD60E
              39030C06337B93C3E443C3D9C78065F88EE37CA5EA746B35915F11359548CC03
              EDF8EA6CC08FD9D907B4BFFFCDE0F8B8A399FC5838BC974FA51E8D49D217E00A
              0401E0BBDB3D6116845703A3A3F7AC3CCFD6CB49CA72FA201ADD4D2612F393C1
              604C8B5F89A0C68ED73B03429E5296E50821020064B3D984924CCAC8E5962602
              81F5EA317F01B3C0993DD10522510000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_layer'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000EC400000EC401952B0E1B000002AA4944415438CB
              8D926B48135014C78F339BDB5452441085C020DD942418D594D4345D293397A9
              2BB2122A1142C820E7843D63EAC6748FD68C26E59258A012D697B02F25154511
              514AE50B739B131F9B33B77CE0E96E56D6879A17FE1C0EDCFB3BE77FCE85DA06
              B9F8C26591F8625DA3B8FA4AA3B886E89250212E3F7D2EFF9440004AA512A452
              E93F05F71EF6E3D857070E4FD8F1F3B81D87C6EC38E698C68CBCC2DB69A92CD0
              6834FF073C79FE06FDC7BB8638E745B479D67199E4395CDE7D16332538A07FE0
              352EF8D670D2B58C23333E7C6FF3E2EC0AE2A1233CEB96004FDF7E44521CBFAD
              23BA5711A77D8824606E11FF012B25393820B7B8E24E7E89A09BCB17F4F875F4
              F8C99EA2F2B3BD0949C98DFBD8EC6D4101F5D73483D73BEE7E09C8BC11DB2DD6
              E1347646DBDEF43D94A0800162E1CFE3FD19730B4BBA995BB1F0F8D92BF4F856
              D1E1FE8EE3335EFC60DF1822D9823595C50C0E78F16EF077651799A6DDB7D1C1
              612EDFC24CDE0DCD4D4A103508FF925C2605B55A0D62B11840D4AC77B6775AE7
              4C9DD679BF3ABA7A9D26B3D5915A90F9329DB35FA0BD69312AB5378CCD5A93B1
              456732AA0CB78C357542514E7636A8542A006A388D1E42098D274ADC1E468D07
              801DB107E37AE3AA2217395C5E9FBF9BC09A89AD79EF7A60C52265AB9BDC6318
              0C0600994C1650934209E7EBAA21BD96DD573B598531F5B4A90359855D7EC012
              79E5F4ACE008F9241E924B5BB4A3341A3D4AAFD703C8E5F2805AD51A282EE503
              A48064676B34524E842C6415F02C7EC002A96E73AFE19073195D2457A8F59B80
              5FD354281420BC2A84BCCC3C88D9155B46E1848DE61CE33F9A722DE1B8D385C3
              F679FC649BC389D94562A1CDC9603022753ADD26402291042066B3194A79A500
              1448A245447028E15165B09D7E26844AAFA4501995A1E1919554465445626242
              B4BF831F6632047AA0FBDB450000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_period'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000C44944415478DA6364A01030C218F5F3D6FFFFF3E72FC39FBFFF18FE
              FCF9C3F01B44FFFB0364FF63F80B64FF068A81E496356431623560D405C3C205
              20D0E4CDE0C0C1C634FFFFEF7F0AE55B10727540D7FDFA0D74D59FDF0C3F7FFD
              65F80D64FF04B27FFFFE8B5004D45C202A29DC1F1C9DF5FBC4FA69ACD7EFBD05
              8B231B84D705134299FF272484FDE6E612FAFDE7F22186DF0FDE334CBFF5840B
              6400B12EE89716642D705416FF73F9F15B961BAFBE93E60258188022849D91C1
              81E430A04A2C9003002CEAE4674579C5850000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\add_row_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000B1300000B1301009A9C18000002C24944415438CB
              85926B48936114808FF7A111140BC992C04B5ED236256544ED336FE5BC0C5321
              CA1F5244AC8598D319DB5C5B5373176D5E42B42422523125A4FE9811E45A22CE
              D26A06815D202DB5B999BA8B324FEF661804EA81E785F3E33CE73D8703C2F232
              E0F3F9FF710594376B40ADD180542A05994CB62950D3D4AEBFF3B0477FB7A3D7
              4D3BE1FEA327FAB4ECBCF21314052A956A6BC1C0EB5174859360238F65C59DE2
              D1E48CBEF0B050A8ABABDB5AD03F388C8BF6559CB638F0CB9C158DD356341149
              D2C9ECAE43D151DB0B748671777733299AB1227EB620DA499E7C2AA79B111503
              CD4D8D502916815422DEA0522202855C061AB223B8FDA0179F933106F4067CF6
              CA80FD3A03EA0C4664B1335A02C303C3F9A58214694D3D4F74A3962756D4F224
              0A25AFB25AC32B2E17E571381C002F5F5A187913C0C38B051E9E2C6F6F5A0280
              67E87EEA40D3CE7CDA142B2DEBE9A26D05CD4B769CB558716A7E09CD36075628
              34D3E00A41E9D50DAE098470F6D239883ECF6C2EFE7401E965FE7354EAE94ED7
              521D6B88A665277E250B2293A25CDD60740BAAABAB3668A8D742667E36F8B17D
              EF1DEE0946CF029849E31474B8042652F56D7E05DF4FD9F017599A42DDB82EA8
              1049E8250221BDA44C48178AC4F4A2A28BF47D41213BFC22FC551EC77CE63867
              0A074873FCBD4A2436C41F4B888B24AFD6B6AE8FD0DAD9E7D48DBC730E8E8C3B
              5F0E8F3987C63E3A478D932B2919051A080066C0AEDD85118CC4AAF09838E5C1
              D83865446CBC3292714419181C2224E5347831F4C67D386B7F0FC9645F3FA4F4
              9CFCEEA03D7B2197CB8524F67148A2D8FF20795A6A0A70B95C2FF7212D585771
              CA6CC7C9592B8E7F5FC6390722959ED9C5888D81B6B63650ABD59B02FAB713EE
              8EAEC60BE4073F1DEB3F48CDCA7D1C1519B1FD255EAE908F5E576A3FC8945AA3
              4CA535CA0955B75A26229989DA7826C3635BC116E1435194D776823F20CCF855
              AC4B6A210000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_cut_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000B1300000B1301009A9C18000002934944415438CB
              63686868602006D7D6D632747676CA383838443200C1942953185A5B5B1988D2
              5C5F5F0FC66D6D6D138484848C2D2C2C0CCDCCCC245352521888D25C5555C530
              71E2C49ACCCCCC6D404DBDB9B9B91D4047082525253110D45C5D5DCDD0D4D4E4
              B860C182FFAB56ADFA9D9797B700A8995F535393A1ABAB8B81A11EA418A8B0A9
              BE16821B1B181A9B9A800680345731F4F7F7CB00357EDAB469D3FFB8B8B8F940
              CD7C1A1A1A60CDCDCDCD0C0C8DF5750CCDB5550C8D2D2D0C8D6D1D6CB555E50C
              4DE5F90CCDF5950C13FA7BA5766CDF7169EDDAB5FFDDDCDC7A809A796136B700
              D5835CC8D05D99CF103779BDB6D2C45BBB65EB4FBD914C9939C5242A5FC5BE68
              75614A71DB850D2B17FEF7F0F0E8056A6683D90CD30CF22643CAECCD26F2936F
              5F6750F46E64E0143711AA39F757A0E6E17F06D3D62B1CEAB18B7D620B0F0335
              0BA8A9A96168061B607BE2FF19DEE4E90740712B12D3A827DEF2F03FB366F216
              06262143FE882D8F18444D52D414E518BABBBB3134830D90CF995824D67FEE8E
              60FEDA15E24DB75F30C878B4810C63776C99265173F73F83B09CB99BBD25C384
              09133134830DD0515366609032B26590F5E904BAD49519A859C5A7D442A8E5F1
              7FD1B2036F8473D79DE4E2E1E5AE282D06873A8601BD3DDD0C9181DE0C7E6EB6
              0C815ECE0CB1F1A90C6AEDD74EF1B824B403CD12162E3D72974152D3C5C5C682
              A1A7A707D30010014CE3603F4EEF6D6588A85D2AC35A7DE61650330B83828BB2
              54CBD9078C8C8C9A01BEDEE040C46A000C7777B43078FA85B373D41D38275ABF
              6DBFC2BCF72F85DC128091CDC0084A584DE00486C700502817E66432702AE9AA
              2AE64E9A2868649F0CD4CCE5606FCFD0DEDE8E35B963A4FDF68E0E86CCC45806
              18484F4B03C6C004B83CBA0100BFAB6AA0B2B6CC6F0000000049454E44AE4260
              82}
          end>
      end
      item
        Name = 'Model\clipboard_paste_lined_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000B1300000B1301009A9C18000003584944415438CB
              8D925D4C536718C79FAB65D9152C667AB139759B149DD9D6B964975CEC6A178C
              38B3163492B1E0385541930AB494B650DAD3B2C9644EE78CC9D06034C32C652C
              B8288EB5B49CD1D3EF2FDA42914FA52D5F428C711FF9EF3D2D63B77B935F4EDE
              73F2FFE579FE39D466D493C168A286331AAAAF57935ADD4815151F5167272FB4
              E8B40962A7BCBC9C1A9BF474AABE85BE38D74D3C6F21BD5E4F46A391486BB451
              8756B5EDE7CBB5A6E15B1AFE3CAFEE55AB4F8FF4DB6F3FBB7F6FF0EF13AA3AC1
              D0CCDDBC7BFD043F78A9C27AB064DBAE23C73E23ABD54A068381A8A9D546BCE6
              F87B1BC9AF904B7F8BEF2E7F831B377AE1740C211418455FDF4D5CEBB98A58D4
              85F5AC8077642FD595941EA0EEEEEEC204CD7A49C0C9338176048675F8FEEAD7
              B0DBEDF8B1EF16FA7FB2E7B976BD07C1701C4F9F01C16068A65456222B2B2BA3
              AEAEAE82C0AAE5E433421BD692AD98F05FC1C070146E871B427219C2780663A9
              257826D770DFEDC362260BD1EB9F2F2E2EDE535353B32968E1E40FDC4664231A
              A47C57E0F4CF2028FA1198D9807F6AA5407A19CEF03C86D8B7D4A32738F0E67E
              EEF0E18F375768A9933F70E9F130D088E8E84588E35944FC2178D3ABF04E2CE5
              115339F82697996C0DC98575ECDF57AA52283E6182D6C20A69672BE645358223
              17B604E2E4EA5658C293CCC2C3EEF1B935EC2B95710A85429AC09A5F21F5AB16
              B3C219445C1731E88862CC25C037F5185E16F4E605D98280F5119F5D052B9253
              E60586420789210DA646EA210E9D83D3378D00EB409A400A8A5230998127C160
              B2D8F40A4AF6EEE594CA4D814DC7C9C7EF3621FDDB49B8EF5821841710F20531
              36B15C0832C612128B7941782A87375E7F8DAB542AD98FC456B0E954F2D82F67
              91BCC7C1D16FC268680E6149C0C69542FFF2FBF8A3BC2030B1883DBB77719595
              95D2049DACC4BA77C30327917634C03960C60F77448C3A05B8134B18893EFC8F
              C8025CF12C84D81C76BEF2325755552509BE249BF6F85B9E9E43F0F61EC2ED4B
              9F6392B5BC343B8DDC1320BBFE1732EB7F1678FC07569E020BB90DECD8B1FDD4
              1149D075FE02D57E7AF4B9575FA40FB6BF401FBE2DDB69E42DE648BB4E13E7CD
              A698A5A32D6631B56D3DAD16E95D7BBCA8A8E86875753591D9DC41671B9BA9EA
              582DD5720D243FF83EFDCFF3BC4AA5A27F00D5A775B3932971EB000000004945
              4E44AE426082}
          end>
      end
      item
        Name = 'Model\decrease_indent_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000EC400000EC401952B0E1B0000001974455874536F
              6674776172650041646F626520496D616765526561647971C9653C0000036849
              44415438CB8593CB6F1B5518C5BFA24212358D13627BDEE3387112AA92C44E6A
              4B91524868CD23AED486788442A075E2D671C64EE2D8E3F1631E9EB9761C7B12
              53C7A50F14104281050B58B260CBAA0B58C0BA7F0142424880BA40C3D8150516
              88C54FE7DE2B7DE79EC5F940D37450A522948A79284905D0DAC845D0DB284540
              1DA48EEE230D5AAD16944AA50E9AA601A8B20CC6D1DD85C37BC7DCC1FB1F70C6
              9D075CADF580DB6FDDE7AACD7BDC9E45F9F65DAED2BCCF152AF5C51BD7AF7706
              FF021A8787E0BD1098245CC3219C190A61164EBA8D2BE4A05C213BC5860649D6
              5257A8CF8EBD6AB3D97A2A950AE8BAFEC400E91AA4C4E24B09A1108EA7F34B9B
              99FCB5CD742E1CDB11C2B7B68570743B135EDF4A5B9A0DAFACC71783C1E02984
              F47F2638005F60F6023172FECA20E90AE22ECF55D2ED59C6D8E1658C712F62B4
              6BBE0DCEBAE7071CF86CFFD95EA8ED55A0627D7C601800E54A15F82D11A22BAF
              C389487F78791C8C9EC151107225C816244F4AD2235B393992C84A918428AFA5
              944AB258BB9D908C56E2EAD2320185920146E695A9879FAD7E67FEFC8579273E
              F868F512B5FB497D75DBE79BC2318A992068D68F538CDF3AFB9D24EDEFB73B03
              FD0E2C70FAD9E7083092336F3F3AF19BE64F5F9B8F7F68FE6E7E1534CD9369F3
              610C4C62887A6747D9DFD891743E9957795E54F87856E66382C46F882A7FF1E5
              0512DEB8E43D577BABFBCBC79FCE99E6E7AFFDF17D9EFDED9BB8FDD78FAFC12F
              5D3DA7E7099A1922287A0227E9098CA43A3889B6D2137D7D3627BCBB9E843336
              3B5C1E86DD1FA5E7CDECC2A96F01803A63EB653DE75E0C8A65239352CA42B2A0
              097CBE24C445558865156123A709B3731719A8D76B60180D08CC0561CC017E77
              1FACBC70DE07C7C71F01C77140B32E3749D1A3560A0F493363B4CBED1BB03BA7
              071CD8745757370E7A498542B91695EA47E5D92BABE24CF04D6929B2B19F46F5
              BDCDBCA6DFCCC84A34232937B3AAC245F9ED99691FE89A556555ED94091A8D06
              4C79BD67498A62473CA3ECE8D8183DE476B3184EB0ED378A669E62DD99F1F1F1
              AE6AB50AE57219104256132DB75D495F4B4A08F13915C54505C5B232BA25C828
              9A96D0DA6E11DD48E5D15A5A464B91B8E0F37A9F690FFEDD442BC1E4E4542F86
              E30C863DC1F91F389C18ED1919E96EEFC253034551E03DCBA47574F4FF58ABDC
              6C36FFB5CE7F02862E4C5D5425A2480000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\delete_row_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000B1300000B1301009A9C18000002E64944415438CB
              85526B489351187E6DDED6BC45EB871852685ECA52242B0D9D97598AA9581698
              2549517919E6361545DC167E5BBB88A29465498999824A597F8A4C509B5DA6D2
              442D02D11F9A3A4D2DE7E69CF3EDEC13FA11A42F3CE79CF7C7F39CF7F2406181
              10727272FE412EC8655250AA545056560662B1F8BF00694DBDFA61539BFA5153
              BBBAFED9261A5A5FA96313CF15447138A05028B61678DB3780D6D82030581017
              4C88E4C2B0E8F88E03DE5E505151B1B5C0EB9E8F68309951F7DB8413F3461C9E
              5AC1F935C4C8B8C4964307FDB717E8D568E90AF4E45B9D11F1FBDC3AEA497E22
              22E6F13E4F0F502AE42011958142A900E96D0A54322548A5529A2C128900EE36
              B6E33BD246A7BA1F3BFB06B1EB9316BB3543989A99DD9F9072218B525567094A
              C499A96753E1AAF07A54DCF9782FDE8DDCBFB30186BDA3373943C086E1B7D7E7
              48E9F88F399C9A9DC32583197F92A1E8968D58DBD886003B6CC373235B5D2EEF
              5EB0DDE37034329403B5F76A0104FC7C1AFC3C1EF004C5C98B84608DF9150B4E
              2CACE122996E43EBCB65A60D8B19C38FADF1EDF144B702B6C5C6DD2E23F47828
              004595D3289788A1444225CD2EE9E96D4C2EADE1D71923CE983605580C67C793
              391135ACFB4C64E7B9A3C37EA762B046514929FB96A0909D972F60DFE4175FFB
              F26D1CC7267538BD6444DD0AE22F22F6F4C51B64D9BB302378D12DCCA45D0660
              31D208D58E437C020F9A3B2CBD9A214B8F466BE9FEACDD20C0F7034398912D1C
              0C0C0913F90404DFF1F0F2A75C9D5DDD82A282B98418E7CA7285F4F474A8AEAE
              06E8FA3048F76C358F7E1D717A19D14CDEE1DCF8274E3B1D21EE742C70A3A320
              ED621A23F3D215484E4802A150089595959B6BB41A49BF6A2625AFE298CE80DA
              C9159C237D734E2534071E0E80BABA3A502A952097CB412693D16F8AA268322D
              A01E1CA52B20E643F239EA4C748ADC3329CFFDFD7CB777627691644024AF1A16
              CBAB46C48AAA1109417965EDA85FD0B1AAE0A0409B6D05B608EB9419DB09FC01
              95BBFA845468FE380000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\increase_indent_32_h'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000B1300000B1301009A9C18000003654944415438CB
              75934B6F1A6714868FEDA476D202E13630371CDB80E3A6B836B613354D9C4496
              B16AD23A05C64E7DC180822FC3180F30E01A188699015C88713051FF40B38914
              A9AABAAABA6E975DF53754EA2EA9AA5695AA6AFA412B2B51D5C5A3F73B8B73CE
              FB49EF01A95C06B95404452C808A54958A5041542511AA65116A1DE452571B55
              15DAED364892D4A58C7A411251C371EB6EE5F1E78CD27CC2C8C76D467A74CA94
              1AA78C586F31C5CF1E33F9A313A680345554173737C320A3C6F2BFC049F318DE
              999C1AB7100EBF19A7FD269CF21BED1D48FF251BE93760845F8F3060A4FFC225
              B3CF60305CA8542A20CBF23F0354450636959B8DED6542512E733FB6970E4412
              A950782719DAD84E86D6B6F742AB5B5C681569603DB6E89B9FEF5114E575071E
              EFCCB4951E0A1AF1C1A58BD6C1398BC3B584394682269C5E34E3D49D2E047D47
              67B2BE6732E8A17154839A2AC3A3460339A8D581E30F20CE66A0B864FCFA9E13
              C4818B06D8DA66217390776F65F29187FBB9482C2944A2C96C342E14B9FDD251
              625FAA273EBCFF310EA57474AAC607F8121B487D53BFF9F2C5F35B5AC107DF5E
              1DB63846C7AEBE69C5492F46503348BB986DF88CCE68BEA63359AE9D3B7F1E87
              74F04AEBA7E72B9AF64356FBEBFBE41FDAB38597DA01A6356FC0CF168A5A8867
              CBBBF14C9E8DF1076C249965C39CC0AEB169769DCBB2EFCFDE2620F5E07AFA69
              C2FEE2AB43F72F3F56AFFCA69586FFFC8E19D0EEB9E08B9E737D4E1B41B9309C
              F46038E1B1DA3BE01E8B0D81DE3ABD1E8385051FF4F6F6E10030F8641E7EFDF2
              A3BEDF0923ECA2BAF7B2FBED69F65016E299A210E53F153693396183CB0AAB89
              8CB0C6E584EB376ED2208A12C84A056A4775981DD32DF7F7C06D803E48A77808
              87C340D28E213B41BA104E9CA4DC043D38A93759BC7A93D5FB467FBF1D2A2807
              7C4189B105B5323E1710C66E7D509A0B6D286CA1525DDFCB290F7633E2F24E5A
              5CD915C4C54F62C9E9292F2832CA8054EA86099ACD26BC3B31A1B3E3846378C4
              493B5D6EEAF2D0B0C366C71D38413A08923A03D5F4E8E8687FAD56035555A113
              2850D1B41D211F8DF0874A186D5CE70405FD116D4E2B2BDB2985D9E295E0C37D
              2588D4B7BC294C4E4EF4AAAF26B1E3C0333EFE1666B3D398CDF61FACD82B5831
              CAE91C19E8DCC2D9005114E1E4A409EDD35374AAFF47FB4C5BADD66BE7FC3768
              B03E5D54B0AB820000000049454E44AE426082}
          end>
      end
      item
        Name = 'Model\clipboard_copy_lined_32'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000100000001008060000001FF3FF
              61000000097048597300000B1300000B1301009A9C180000032A4944415438CB
              8D93CB4F1B6714C53FA428444E782869528905EA1F5225BB41557749C49AAE91
              8A848002556DC00F8C6DF018D354A6915A552DDD55AD5AA9519B104842FC98A7
              6DC6EF610C180F31368F484979849C7EF3D1906D473A9AD5F9CD3973EF250303
              0324C8F35CA958405615B15E3650360C18C61AAA5B5B1045B16AB3D93EEAEEEE
              26737373C46EB71387C341C6C6C6988805989D9DE5D6CB6518C904DE027873FA
              96E9E8F8048DDD5D2C2C2C481D1D1D37FAFAFA88C7E3618077103248017C30C8
              A94513294945BCB083A7E94DAC68553C124BF8ED8F07A8D7EBF0FBFD2B4D4D4D
              C4E97492C9C9C973084BC0F36780A494C4523C85D5A48C5559804E6BC99288A4
              AAA0B2B9814824F2A0B3B3F383DEDE5EE2F3F9581D9620189CE1D27A0D693985
              C71450CA67B1A12938A575AC4AD6FBF0E804A7A76FB0F0D38FD91BD7AF7FD8DF
              DF4F5C2E17050C0E92D950885B1673883E798E475115A2566669E2A57D248A0D
              08A53D3C4B57F0CBAFBFA356DF83CBED7ED8DEDE4E42A110214314303333C345
              536B106302166349489AC1FE87B47600496F402C35B05ADEC5B25444ACD0C0FD
              1F7EAEB45CB15D66802F868688DFEFE3E45C857E55C5C315194A769DD64942D4
              F72151B354AA4328D621AFED21BB7D8C7BDF7EAFB7B55E696580E1E16132E5F5
              7289D5325451C122ADF0D71311F1952824E38099C5E20E9350A841AB1EE2EBC8
              77EF01232323C4ED7671CF141D8AA0E0CFE504A2720E7242A2DD779949C8D790
              C8BF403CB78D0C0584BFB94F012D6780D1D151E2723A3F51341D1BF93C84540E
              31B5C0D2C40B75664CE4CECCB18CC900FCDCBCDED6F25F828989096B121F077C
              5E33E4F398F3F39197D6145441463457433C6B22662953C5736D0B19F31001FE
              9EDE4A013CCF13368A9E9E1ED2DCDCDC7AE1E2C5E69BB76E7D9EA23B21C6442C
              A54C2CA72A584A6E322D2AEB50375EC335157C9FC05AC7F1F171B6A20E879D04
              A6A73FCBE40D6C1672D87905D45E9EE0C5C109B60F8E61EE1FE11FBA54D37CD8
              BC6CB3B59C03ACA37807A1ABFDE984E3ABB4D3FE65666AD2ADF92C793DE79AF6
              7BB5BB776EFF7DF5DAB5367A84E4FC2C2D050201D2D5D545FEC7D3446FE25238
              1C26FF02047F85E0D24A975A0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\40_Play'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000015F494441545885ED974F4E83
              4014877F25936EA49B4242203171296147F0329EC143F4109EC1CB48BAAB14BB
              6962025D50BA806EEC445CD5E0BF62786FC028DFEE85E1F1C130BF0160E08F33
              AA173777B3277B6ACABE640020CD33717B3D3B3FD6A27ED09E9AF2EAD2BDE8DC
              AAC6FD325AD76BAD278F1F3308521904A990053DD3E5F0F816D13CE434CE990D
              5440BC5B41BEF04728CB143BBA8DC0F22134F2FD7E82ED1D9C8C7504968FC958
              E76A09807991A890645FC54213082C1F8E6EB3F45312334213F00C974552690E
              7A860BCFA0C510FFB2FBC0F129B68DA14E76124A0C75B7D58D9A877C85F22906
              80649F22CEDB4DB172C1649F629145ADCF572AB8D84648CA94D44389A0AC24E2
              7C4596031408CA4A22DCCC513C972CFD58058B438945F6C02607300A168712E1
              66CEFE4DC82248899126C882D4186982BC93A89403FEC35F9D6A06412ABF5EF0
              5DCCA4BBAD081F97EB9E5CDE1CFABCFE40E7BC02E89D6DA49B75514300000000
              49454E44AE426082}
          end>
      end
      item
        Name = 'Calc\41_Forward'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000018B494441545885ED975B4EC2
              4014867F9A910753D40095940423FA6243BC84E0665C838B6011AEC1CD4878E2
              16138448424928828297C8047C41526C0C6DE70C35A6DFDB494F67BE9CB90321
              FF9C883DB8BE2D76F4789207250300E693C56EAE8A99EF98D93FEAF124BF3C31
              0E376E65E3AE516FDB6325200FD78482A28482A2B0F529AB1CEC6430FC1862FC
              39599B7BBC97C5D16E76193F3CB7D01CB53CF5E7B9825B0A432195472CAA7AFD
              D517BE86982D24B5ED24B58F03DF7390290C17DA19D2AA4EE9E3407891E41286
              544992559C4B18C8250C8AA61C906D336955972249BA0FA6551DE7DA2998E279
              F7FA15F28D7A7F5B4321952793947292C4A22A99A4BCA32EB23EC50D5204C7D3
              094ABD32F84CFC724E379B17F4DF2D54AC1A891C402CD87D3551B5EA944DD20D
              B10C3980A882D5411DDD8949D19403E10ACA9403042AC8E71C15AB86FE9B45E9
              E3C097209F73947A6557B76A513C0FF174B63939C047051F5F3AAE739B23EF6F
              909FFCF9575D28284A2828CACA2A36870356BA6FB40372593A04D97FC8C6F902
              91C4700864F731CC0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\42_AutoFit'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000049B494441545885D5986D4C5B
              5518C79F5361B4DCDEAE506A6130DB39650EB78C4C973974089BB849225E9860
              C1E860891F7C9909FA691FD42F6A34D1C4C4C46598A819421632A08B712F2C5B
              8722DAD0D51585515E2B053610DAD2176E2FD47BFD00CCBBBB8E9E7B6FF7C17F
              D2A4E779FEF7F497F3F439E7B40864A8EB74D5E124482A12F34C9489789E7AB9
              ED7D7E8CA1288A5528762858D69962B158F8B92439808492ACCF2F28DA81EBA7
              C341D6DE75E92B619C5528BE0000238B901B006E03544885EB6828C9D767E53C
              24E69941A7E37A6175EB517E6C91A2F201C0080000089956C6F201353A7DBD21
              672381EBF7CDDC580C04BC2784F12842B500001CC79DE18F6503121AEDB6A4E4
              146CBF676CC45658D3F6A5308E9681E6551C570B0080005E900D78E99B033BF5
              991B7271FDD3937F0503BE998F857186A22800580F1C6741168B9FE3B8338090
              89A6A82259806AADFE1D43B6518DEB1F1BE8EBDF5BD37E5E186711A20000141C
              67010040082D3708AFCC92BA9850AFDF86EB9D181D9C0D070335319308990100
              5885A29DAEA8B815E6786516BD82D693A58F676466619537BAC4C0E4D8B0ED99
              233F8E0A732BE5BDF34BCC712E849076252F1E90D0E8DE35E4185538DEF161D7
              846FD6F756ACDCADF2B26CB9AAAD0DADBE00A14FF879D1252648BCF2D2E110CC
              4D4FB63EF7FA7977AC3C42E81A07E0169E1C4A96B544140A1342C80F0080C4C0
              5D6E7CBE2A2F7F77A321DBB82E9EF70FDBCFC37337077715D75DF18BF90CA144
              953835457D18078E0E87FE09F90327E4C20188052449ACE6E873FC3654507DEA
              336948B70B1BD0DA546636E5E699E2F9BC3337227438F4912C2A9EB00149755A
              1599A68BDB549EB1A15F0B6B5ABF9787F59FB0BB38554D3E1ACF438743A05412
              B9D72FBFED8EE70D057C44D0EFEFDC57FBC38B6BF9B0BAD8DA54667EEC897D8D
              382B88A3E81203D7BA3BAFEC2A6F2C8EE7C52AB146A3AB4E141C00C040AFC311
              F27BCA71BC58802A227E7971E572DA3D339E91D770B7A0B8AB72F1BBD243CCC2
              42AACB6977C7F36A33F43A43B691BC5B7E6274F06FEFECCD37F61FB9E0C08103
              107992ACA58E8692FCAD3BF774E63CF8B026563EE0F386FA1DB60FF754367F2A
              665EC9376AA1343A7D7DE6C60762C2D1E120FB67CF2F17C4C201241050ADD16E
              8FF51320BAC480D3D675F54973CB9ADBC9DD9410C0E53BE286ADB172FD76DB40
              2438F5ACD4B91302A854693E30641B95C2B8CB69F778E7265F9173694808602A
              A1D9228C4D8C0C79A7A7C78F15BF7AD62E676ED980D6A632F3A62D799BF8B180
              6F6EC133E26A78DADCDE24777ED9A70349A6BFC43F65E87090EDEBE9EE2830B7
              1C933B374002563055ADD9BEFA3EBAC440AFADCB51606EC13AC670240BF0A7E6
              8AA339A6CDA6D571BFDD364007A74A6453F1240B50A5220E91DAF4FB000046FB
              7BC7E5766C2C4906B47E5BA44DD71B4C00CB1D3B3531F69EDC8E8D25C980C9CA
              FBEBB28C9B8D01DFDCC2947BF8F3BDE6D3271309B62AC9802A95AA32795D32D7
              D7D3DDB1BBB2F98E3F8612254980E78E1F349169BA47AE76597F67E899BA4443
              F12509302D43FB6670DE374F0726F727BA298492B451339148698459ACBAD770
              9274EEF841D3C5AF4BEF6959FF57FA172926AC105A6C5EF40000000049454E44
              AE426082}
          end>
      end
      item
        Name = 'Calc\43_DataLoad'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C08648800000226494441545885ED983F6813
              511C80BF984B633CCE246792460C5824B6A05285DA0CD24111A16E0E52FF5005
              0BAE59ECD4A564707471121C0A52717173E9D24110FC43D34421D43A1462A129
              36E662630DC68B71B0067A069ADCBDA419EE9BEEEEDDEFF7BE7B77EF7EEF0E6C
              6CF61607C093C4E555D5EBD1773BF93735F2DFCAAF27A6E76EB65FED2F1280EA
              F5E8037D87FA9A09D8DCFA199C498CCEDE999E1B6FABD936FB5A0D3828BBE5C1
              68E8CA4C6274B61D42462433419EFD2E39A02AD7E71FDFBE265AE81FB90DCD31
              3EF5426A59305F2C53A93919899D72F6B84C5D5F53BC492EEBB03D82A5B21E59
              D37E35157824DCCBE15EB56D6246248050C0C7D9D3C73BD6692BB43C493A4DD7
              0B0A7BCA6F3C3FB363FFD9D5B490BCC204450919B147D02AC204EFCD0FA1FA14
              000AC5120F2E2685E41526E8F729F8232701A8911195B6FB5F33B6A0556C41AB
              989EC50FDF1D23FB238CAAF400E05642F536B712E27EF23C0085EF158E7AD689
              C7563A2B188FADF0E8FD012A811124C9B9A34DF60691BD4174BD8ABCFE8AF890
              3939B0788B6F9D5842CB2E346CD3F52A5A7681BB834B56BAB02628BBAA4C0EA7
              287CFEBF6A6CAEA5991C4E21BBAA56BAB03E49645795B168062DF7A97E6C63F5
              2363D18C65391054EAFAFD252E6C2DF2F28B1B804BE134FDFE9288D4E26AF1B9
              C8570A950FF56D51981234AEFD8C3C5D6CFCD5676649664AB05D6BBF46747D25
              E97A410920972F3ADEA69677FDFDD64972F9A263AF1D6C6C00FE00D38E90B001
              C1794C0000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\44_DataPaste'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C086488000002B9494441545885ED98CF4BDB
              6018C7BF6F5348ABA98D25C3A0B6C4C1D845E6D8613761B7DD76F2B43128D50A
              DB415606B32B789D0EDC021E765818ECE0DC1FB0FB50761B78E8CE1E8ADA264E
              6AD08AFD11D2ECB03A8CB6B3CDFB5A04FD9EF23EEFF33ECF87E74DDE27BC048C
              944CAB71022800E000396D21F599556C6A4DA5D507C9B41A3F1E27D36A3C9951
              EFB2884D9A197F7E7AFC2DD4CB8FB65AA466EF286E4B7DEBE3FCCBD849CBF4EB
              779B802F7AD2961AFB956B15B3745859BF3FF575E2B4DDDFCC39D4CB8FC6066F
              28CDE6000059F7D071482499569F680BA92F0030997EFF1C20D1D3CBFE1773B3
              B0DBD4DE14B05311427A1D076FA667D5090070807B2CE2028C00018010C44010
              035ABC371ED51660CFF85BD738F8FD03CAD55A47892262083DE32F5CB6A31FB3
              E7AEF37594A5A1674F1F212286DAF68F8821C4271E7A49E56D8B6FDF1CC6FCAB
              494F093B95A70A7653D780B4BA5A8055C340D5305886640BF87B7919054D6319
              921D60D530E0374DF88A45A655640658D034F48922A4A121A655A4EEC507D92C
              EC46E538450100F8F27998ABABE0FAFBD13736D67DC0DCD212EADBDBE008014F
              08F86010030D380018501494D7D670542EC35C5981ED38F00D0F439999E93897
              A72D8E2612A8FBFD902409A22C23180E9FF10986C31065199224A1EEF7239A48
              7849E50D9013048C6432D04D13B665B5F4B32D0BBA69622493012708DD037441
              168B2D7DF462910A0EA0FC8A3941002F492DE77949A28203181C33D6FEFEBF67
              DBB25C5BEE54ABB4E1E901B95A0DB6656147D7B11708602F10C08EAEC3B62C38
              0707D48054E7E0D1C6064AF93CEA8280C1540ABC2C03F8DB550A9A864AA3AB1C
              DBBB0EC809026E2D2E9E01E065192373734C5A1E15E07995A1A9DCB1AED6FFE0
              45E81A9056D780B46AEB9869E70EE5A274E92B78E9019B6E71E9B0B2BE65ECB2
              BCE63B57A5C3CA7A37F35D1DFD01F221D1AB68EBE3C10000000049454E44AE42
              6082}
          end>
      end
      item
        Name = 'Calc\45_ResultSave'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C08648800000354494441545885CD98BF6F13
              6718C73F3E9FED73CEC4F1E0AB902AD54E17B003422289157508848DB6A80B12
              5309227F400754890D8905454C0C0C28031B481E18988992A5C5240B34F658BB
              53EB4BD43471CE3E3B17A70371719CF87EBD6EC2777D9FF7793EF73EEFF33EF7
              BEF0992B0030FF2CFF5D329978180AC92322CE42A188B2BBDB3445A136FEFEA7
              F0D38F3FDC029001342DF1F0EA379397441DEB9BDB6889615137D476EAA9F985
              FCEACF73371F4B00A22B37689D890D2149813138584151599532C6D21BDA924C
              2D1A415263A8D7BF1F846B71C0C6F2226DC3203E3B4773739B338961F6D67536
              9F3E61E4F65D02AA2AE45F12996C55CA0047562B98D418B97D97EDFC0B11F780
              206063E52DD1E99963C702AA4A74728A56A92812C23F6063799148F6A2AD4D38
              93C5587AE33704200068E955C299ACA39D7AE51AE66AC16F187F8056A58CAC7D
              E1CA369CC9D25CFBCD4F18C027A0DDDE3B4EE1F4287BEBBA9F506245E256CA78
              0E73C55F9A3D03B64A45C7E2E8554055691B3B5E43013E009BC50FAE8AE34820
              35E62BCD27926200652247ABB4E6799E27C0BD759D507AD47310F8D85D2CBDEA
              799E274073A540E4FC98E7201DB50DC3F31CCF291669FED1C929CF87B60C108A
              44147D73CBD1B8DD30316CEC8C46139DFDFE0ECE7E49FBF52BA4AFCF7903DC6D
              364D2D11B73534570BC897C7916DEC749CFFA8B7DA16718758DD729DE23D5D47
              4EA55D3BEE27AF5DC535A0DF83B657E1CC98A7AEE20AD0AA947D1F2FBD0A2635
              5A073FBA6EE40AB0B1F216653CE71BAA57E1549A7D9747CE8975926E291339D7
              C78D23E020D3DB5130A96116DDB53D47C041A7B7A3702AEDAA9A6D01F70D0349
              8D0D0CAA5B43D333D45DDC576C01CDD502CAC4E0570F3EB54CA762E90BB86F18
              587A9560521B2C599786AE5CA3BEBC686BD317B0BEBC48ECFA8D814375ABF3F1
              767BF158C056A988A4AAC2CF166E34343DC376FE65DFF1238056A54CE3DDAF9E
              6E6D220AA82AC3376FB1F57CE1D8F1FF1E8F5AA535760F5A507C76EE44E03A0A
              263562DFDE60EBF9024AF6C2A19F121920FAC7EF0AD9F32813B9FFB5289C20E3
              B3735895F2A1BB8B04D0F86AD40C67B2A706D72D39953EB4BD24803FFFDA58AB
              EDD44F0DAA57BFBC7B5FDDA8D61EC0C1233AC0FC42FE5EE7D9F5B4B551AD3D78
              74FF4EE5B4395CE95FE1170E607899C2A00000000049454E44AE426082}
          end>
      end
      item
        Name = 'Calc\46_CopyResult'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C0864880000023A494441545885EDD7CD4BDB
              601C07F06FACA834650A4E9DB6657D8917050F3DC80E82C3813D88F7B9DEBDE9
              45D47F6146DB3FA0EE2AA8BB791052BB5D7C191B584F1E3382F1050DEAC02A28
              2DD941AA559FA47DFAA469857E8F4F9EE4F7C9EF791E42802A0F5768C2C2B7EF
              6AB7DF9D6129727A7ED97AF9EFEA6276FCB38FE539C4ACFDD85174C66C6CEFEA
              EA89A6CFC59715DAFA7596BF91413CEFDEE2CBE8A7F7B4C87AD2E0D7F8AAEA75
              B7670040D7E1B6C007E01189F8B252EC72133BE8E96ACF0EF4877C03FD215F63
              6303F1255891C576D2B625CE0F0DB22240E011292EAE1C98CDAB1810B8478E8D
              0E79CD9015050280A7C31C69E901304AC0DB89E44ECA744E4BB3AB85346E1B30
              E0ED349DB3F6F3D73969BCE24B5C284420C741B71B6294D7D9C16A8A2D874493
              24C8F3F34FC63E249345DD6B4B07DBC261F82726009D7E6B5B02D42409B2281A
              5ECFA6D3385D5F07388E1AC90CCC2D9F96481091D9741AFB5353B89165380301
              F82727A99ECFB407F3F79683E7A125120080E0CC0C11D71B8BC1E172A1AEA9A9
              E81A2577301F179C9E466F34FA809445D11007DCEFC9B2029FE3DAC2613805E1
              093215891071B4A1069270B9E423B3D7D7CCB892807C300807CFBFC03D47BEE9
              EB63C601251C12A72020B4B4645AD82908E889C59860B994B40759BB4293AAFF
              16D780ACA901595303B2A6EA8105BF247F0F4E206DEE96A5F8EDDD5D86E3B843
              00909563A2A520706478D06AD743B6FEA40E23231FFD66735EE712AB4767F55B
              BFF7947217578FCF6CF9AB2C6BFE03316011C48F749D890000000049454E44AE
              426082}
          end>
      end
      item
        Name = 'Calc\47_CopyImage'
        SourceImages = <
          item
            Image.Data = {
              89504E470D0A1A0A0000000D49484452000000280000002808060000008CFEB8
              6D0000000473424954080808087C086488000001BE494441545885EDD8CF4A02
              411C07F06F220B4A91B1994A6EA260070F1EA227A85BE0BD7A815EA157287A82
              EA018AF062C7CC5BD6C5820E5D24DAD20A8B4DA825C1C4EDB0A429CDE6CCECAC
              41FBBD28FB9BDDFDECFC5B1170C3971152616BF7A0928C4FB7786F50D3EAF24B
              FD4D5B5F5B8EF35EAB27B9E3A26AD890A3939251797C3236B6F7541687C7D6A7
              22241A0E6235B31863413A02048068789209E9181060433A0A04E8918E03013A
              E450804017B9B9B37F67D56E6840C044AE6416142BA497543000C30E44428920
              5F3CB76C13181F0D906A44A05D492811249488659B5CE15423D5863AC483E4CF
              03850F71ED1D28D7818F36909281909FEE7CE13D78A501AF4DA0D132A1B47174
              8859B605E1C0940C8C4980CF0BCC4ED09F2F7C0E86FCF4F3EE7BB87BB0AA0397
              CFBC572187AB07FB71E960F7FBF96D1300301793786EC10EECC75575F3331D34
              71D952A353E341320149C35AD5014D6F237FD1C57D415991D473F0B739D78007
              C9195FCFB16CA9D11972DA500307591053B2641B52D83E4842D246E846FD1392
              36C2DF24BC48EA55BCC4F207465C02E61D5AC54EC705F2C605F2C605F286B80F
              966FEEBD878533D509C4B5FA20FC97FDFFCD275A07D22FED3A03570000000049
              454E44AE426082}
          end>
      end>
    Left = 326
    Top = 546
  end
  object vliProject: TVirtualImageList
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
      end>
    ImageCollection = ImageCollection
    Left = 27
    Top = 83
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
end
