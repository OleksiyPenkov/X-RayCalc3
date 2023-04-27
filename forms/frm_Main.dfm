object frmMain: TfrmMain
  Left = 0
  Top = 0
  Caption = 'X-Ray Calc 2'
  ClientHeight = 861
  ClientWidth = 1511
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = mmMain
  WindowState = wsMaximized
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object Status: TRzStatusBar
    Left = 0
    Top = 842
    Width = 1511
    Height = 19
    BorderInner = fsNone
    BorderOuter = fsNone
    BorderSides = [sdLeft, sdTop, sdRight, sdBottom]
    BorderWidth = 0
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 841
    ExplicitWidth = 1507
    object spnTime: TRzStatusPane
      Left = 0
      Top = 0
      Height = 19
      Align = alLeft
      Caption = ''
      ExplicitLeft = 1354
      ExplicitHeight = 20
    end
    object spnFitTime: TRzStatusPane
      Left = 100
      Top = 0
      Width = 150
      Height = 19
      Align = alLeft
      Caption = ''
    end
  end
  object LeftSplitter: TRzSplitter
    Left = 0
    Top = 0
    Width = 1511
    Height = 842
    Position = 248
    Percent = 16
    UpperLeft.Color = 15987699
    LowerRight.Color = 15987699
    Align = alClient
    Color = 15987699
    TabOrder = 1
    ExplicitWidth = 1507
    ExplicitHeight = 841
    BarSize = (
      248
      0
      252
      842)
    UpperLeftControls = (
      RzPanel1)
    LowerRightControls = (
      pnlMain
      StructurePanel)
    object RzPanel1: TRzPanel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 242
      Height = 836
      Align = alClient
      BorderOuter = fsFlatRounded
      Color = 15987699
      TabOrder = 0
      object tlbrFile: TRzToolbar
        Left = 2
        Top = 2
        Width = 238
        Height = 29
        Images = ilProject
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
          BtnSave
          RzSpacer1
          BtnPrint)
        object BtnNew: TRzToolButton
          Left = 4
          Top = 2
          DisabledIndex = 1
          ImageIndex = 0
          Action = FileNew
        end
        object BtnOpen: TRzToolButton
          Left = 29
          Top = 2
          DisabledIndex = 3
          ImageIndex = 2
          Action = FileOpen
        end
        object BtnSave: TRzToolButton
          Left = 54
          Top = 2
          DisabledIndex = 5
          ImageIndex = 4
          Action = FileSave
        end
        object RzSpacer1: TRzSpacer
          Left = 79
          Top = 2
        end
        object BtnPrint: TRzToolButton
          Left = 87
          Top = 2
          DisabledIndex = 7
          ImageIndex = 6
          Action = FilePrint
        end
      end
      object RzPanel5: TRzPanel
        AlignWithMargins = True
        Left = 5
        Top = 749
        Width = 232
        Height = 82
        Align = alBottom
        BorderOuter = fsFlatRounded
        Color = 15987699
        FlatColor = clSkyBlue
        TabOrder = 1
        ExplicitTop = 748
        object mmDescription: TRzMemo
          AlignWithMargins = True
          Left = 5
          Top = 5
          Width = 222
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
        Left = 2
        Top = 31
        Width = 238
        Height = 29
        Hint = 'Delete item'
        Images = ilProject
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        ParentShowHint = False
        ShowHint = True
        StyleName = 'Windows'
        TabOrder = 2
        ExplicitLeft = 4
        ExplicitTop = 10
        ToolbarControls = (
          btnAddModel
          BtnExport
          BtnCopy
          BtnPaste
          BtnEdit
          RzSpacer4
          BtnWordWrap
          RzSpacer5
          BtnRecycle)
        object btnAddModel: TRzToolButton
          Left = 4
          Top = 2
          DisabledIndex = 9
          ImageIndex = 8
          Action = ModelCreate
        end
        object BtnExport: TRzToolButton
          Left = 29
          Top = 2
          DisabledIndex = 11
          ImageIndex = 10
          Action = actProjectItemDuplicate
        end
        object BtnCopy: TRzToolButton
          Left = 54
          Top = 2
          DisabledIndex = 13
          ImageIndex = 12
          Action = actModelCopy
        end
        object BtnPaste: TRzToolButton
          Left = 79
          Top = 2
          DisabledIndex = 15
          ImageIndex = 14
          Action = actModelPaste
        end
        object BtnEdit: TRzToolButton
          Left = 104
          Top = 2
          DisabledIndex = 17
          ImageIndex = 16
          Action = actItemProperites
        end
        object RzSpacer4: TRzSpacer
          Left = 129
          Top = 2
        end
        object BtnWordWrap: TRzToolButton
          Left = 137
          Top = 2
          DisabledIndex = 19
          ImageIndex = 18
          Action = ProjectItemExtension
        end
        object RzSpacer5: TRzSpacer
          Left = 162
          Top = 2
        end
        object BtnRecycle: TRzToolButton
          Left = 170
          Top = 2
          DisabledIndex = 21
          ImageIndex = 20
          Action = ProjectItemDelete
        end
      end
    end
    object pnlMain: TRzPanel
      AlignWithMargins = True
      Left = 356
      Top = 3
      Width = 903
      Height = 836
      Margins.Left = 0
      Margins.Right = 0
      Align = alClient
      BorderOuter = fsFlatRounded
      Color = 15987699
      TabOrder = 0
      object Pages: TRzPageControl
        Left = 2
        Top = 671
        Width = 899
        Height = 163
        Hint = ''
        ActivePage = tsFittingProgress
        Align = alBottom
        TabIndex = 3
        TabOrder = 0
        ExplicitTop = 670
        ExplicitWidth = 895
        FixedDimension = 21
        object tsThickness: TRzTabSheet
          Color = 15987699
          Caption = 'Thickness'
          object chThickness: TChart
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 889
            Height = 132
            Cursor = crCross
            Legend.TopPos = 0
            MarginRight = 0
            MarginUnits = muPixels
            Title.Text.Strings = (
              'TChart')
            Title.Visible = False
            View3D = False
            ZoomWheel = pmwNormal
            Align = alClient
            BevelOuter = bvNone
            Color = 15925239
            TabOrder = 0
            DefaultCanvas = 'TGDIPlusCanvas'
            ColorPaletteIndex = 13
          end
        end
        object tsRoughness: TRzTabSheet
          Color = 15987699
          Caption = 'Roughness'
          object chRoughness: TChart
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 889
            Height = 132
            Cursor = crCross
            Legend.TopPos = 0
            MarginRight = 0
            MarginUnits = muPixels
            Title.Text.Strings = (
              'TChart')
            Title.Visible = False
            View3D = False
            ZoomWheel = pmwNormal
            Align = alClient
            BevelOuter = bvNone
            Color = 16773087
            TabOrder = 0
            DefaultCanvas = 'TGDIPlusCanvas'
            ColorPaletteIndex = 13
          end
        end
        object tsDensity: TRzTabSheet
          Color = 15987699
          Caption = 'Density'
          object chDensity: TChart
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 889
            Height = 132
            Cursor = crCross
            Legend.TopPos = 0
            MarginRight = 0
            MarginUnits = muPixels
            Title.Text.Strings = (
              'TChart')
            Title.Visible = False
            View3D = False
            ZoomWheel = pmwNormal
            Align = alClient
            BevelOuter = bvNone
            Color = 16773087
            TabOrder = 0
            DefaultCanvas = 'TGDIPlusCanvas'
            ColorPaletteIndex = 13
          end
        end
        object tsFittingProgress: TRzTabSheet
          Color = 15987699
          Caption = 'Fitting Progress'
          ExplicitWidth = 891
          object chFittingProgress: TChart
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 889
            Height = 132
            Cursor = crCross
            Legend.TopPos = 0
            Legend.Visible = False
            MarginLeft = 5
            MarginRight = 5
            MarginUnits = muPixels
            Title.Text.Strings = (
              'TChart')
            Title.Visible = False
            LeftAxis.AxisValuesFormat = '#,##0'
            LeftAxis.LabelsExponent = True
            LeftAxis.Logarithmic = True
            LeftAxis.MaximumRound = True
            View3D = False
            ZoomWheel = pmwNormal
            Align = alClient
            BevelOuter = bvNone
            Color = 16771538
            TabOrder = 0
            ExplicitWidth = 885
            DefaultCanvas = 'TGDIPlusCanvas'
            ColorPaletteIndex = 13
            object Series1: TLineSeries
              HoverElement = [heCurrent]
              SeriesColor = 16744448
              Title = 'srFitProgress'
              Brush.BackColor = clDefault
              LinePen.Color = clRed
              LinePen.Width = 3
              Pointer.InflateMargins = True
              Pointer.Style = psRectangle
              Stairs = True
              XValues.Name = 'X'
              XValues.Order = loAscending
              YValues.Name = 'Y'
              YValues.Order = loNone
            end
          end
        end
      end
      object Chart: TChart
        AlignWithMargins = True
        Left = 5
        Top = 148
        Width = 893
        Height = 464
        Cursor = crCross
        Foot.Visible = False
        Legend.Brush.Color = clSilver
        Legend.Brush.BackColor = clSilver
        Legend.Brush.Gradient.Direction = gdTopBottom
        Legend.Brush.Gradient.EndColor = 2152289
        Legend.Brush.Gradient.MidColor = 7548915
        Legend.Brush.Gradient.StartColor = 10109259
        Legend.Color = 14210754
        Legend.Font.Height = -13
        Legend.Font.Style = [fsBold]
        Legend.Frame.Width = 2
        Legend.Frame.Visible = False
        Legend.LegendStyle = lsSeries
        Legend.ResizeChart = False
        Legend.Shadow.Color = 9211020
        Legend.ShapeStyle = fosRoundRectangle
        Legend.TextStyle = ltsPlain
        Legend.Title.Transparent = False
        Legend.TopPos = 3
        MarginBottom = 5
        MarginLeft = 5
        MarginRight = 5
        MarginTop = 5
        MarginUnits = muPixels
        PrintProportional = False
        SubFoot.Visible = False
        SubTitle.Visible = False
        Title.Alignment = taLeftJustify
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        DepthAxis.Automatic = False
        DepthAxis.AutomaticMaximum = False
        DepthAxis.AutomaticMinimum = False
        DepthAxis.Maximum = 0.439999999999999900
        DepthAxis.Minimum = -0.560000000000000300
        DepthTopAxis.Automatic = False
        DepthTopAxis.AutomaticMaximum = False
        DepthTopAxis.AutomaticMinimum = False
        DepthTopAxis.Maximum = 0.439999999999999900
        DepthTopAxis.Minimum = -0.560000000000000300
        LeftAxis.Axis.SmallSpace = 1
        LeftAxis.AxisValuesFormat = '00e-0'
        LeftAxis.LabelsExponent = True
        LeftAxis.LabelsFormat.Margins.Left = 0
        LeftAxis.LabelsFormat.Margins.Top = 0
        LeftAxis.LabelsFormat.Margins.Right = 0
        LeftAxis.LabelsFormat.Margins.Bottom = 0
        LeftAxis.LabelsFormat.Margins.Units = maPixels
        LeftAxis.Logarithmic = True
        LeftAxis.MaximumOffset = 10
        LeftAxis.RoundFirstLabel = False
        LeftAxis.Title.Caption = 'Reflectivity'
        LeftAxis.TitleSize = 15
        Pages.AutoScale = True
        RightAxis.Automatic = False
        RightAxis.AutomaticMaximum = False
        RightAxis.AutomaticMinimum = False
        View3D = False
        Zoom.Pen.Color = clRed
        Zoom.Pen.Mode = pmNotXor
        Align = alClient
        BevelOuter = bvLowered
        Color = clCream
        TabOrder = 1
        ExplicitWidth = 889
        ExplicitHeight = 463
        DefaultCanvas = 'TGDIPlusCanvas'
        PrintMargins = (
          5
          5
          5
          5)
        ColorPaletteIndex = -2
        ColorPalette = (
          255
          8404992
          32768
          16711680
          128
          8388608
          4210688
          16711935
          8421376
          8388736
          32896
          0)
      end
      object RzPanel3: TRzPanel
        AlignWithMargins = True
        Left = 5
        Top = 618
        Width = 893
        Height = 50
        Align = alBottom
        BorderOuter = fsFlatRounded
        Color = 15987699
        FlatColor = clSkyBlue
        TabOrder = 2
        ExplicitTop = 617
        ExplicitWidth = 889
        DesignSize = (
          893
          50)
        object RzStatusPane1: TRzStatusPane
          Left = 5
          Top = 4
          Width = 25
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = 'X'
        end
        object RzStatusPane2: TRzStatusPane
          Left = 5
          Top = 28
          Width = 25
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = 'Y'
        end
        object StatusY: TRzStatusPane
          Left = 33
          Top = 28
          Width = 64
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Caption = '0.00'
        end
        object StatusX: TRzStatusPane
          Left = 33
          Top = 4
          Width = 64
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Caption = '0.00'
        end
        object RzStatusPane3: TRzStatusPane
          Left = 103
          Top = 5
          Width = 46
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = 'Rmax'
        end
        object RzStatusPane4: TRzStatusPane
          Left = 104
          Top = 28
          Width = 44
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = 'Xmax'
        end
        object StatusMaxX: TRzStatusPane
          Left = 153
          Top = 28
          Width = 64
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Caption = '0.00'
        end
        object StatusRMax: TRzStatusPane
          Left = 153
          Top = 4
          Width = 64
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Caption = '0.00'
        end
        object RzStatusPane5: TRzStatusPane
          Left = 221
          Top = 4
          Width = 25
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = 'Ri'
        end
        object StatusD: TRzStatusPane
          Left = 252
          Top = 28
          Width = 89
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Caption = '0.00'
        end
        object RzStatusPane6: TRzStatusPane
          Left = 221
          Top = 28
          Width = 25
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = 'D'
        end
        object StatusRi: TRzStatusPane
          Left = 252
          Top = 4
          Width = 89
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Caption = '0.00'
        end
        object spChiSqr: TRzStatusPane
          Left = 392
          Top = 5
          Width = 89
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taCenter
          Caption = '0.00'
        end
        object RzStatusPane7: TRzStatusPane
          Left = 364
          Top = 5
          Width = 25
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taRightJustify
          Caption = #967'2'
        end
        object spChiBest: TRzStatusPane
          Left = 392
          Top = 27
          Width = 89
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'MS Sans Serif'
          Font.Style = [fsBold]
          ParentFont = False
          Alignment = taCenter
          Caption = '0.00'
        end
        object btnChartScale: TRzBitBtn
          Left = 750
          Top = 7
          Anchors = [akTop, akRight]
          Caption = 'Linear'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 0
          OnClick = btnChartScaleClick
          ExplicitLeft = 746
        end
        object cbMinLimit: TRzComboBox
          Left = 831
          Top = 8
          Width = 53
          Height = 24
          Anchors = [akRight, akBottom]
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -13
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          TabOrder = 1
          Text = '5e-7'
          Items.Strings = (
            '1e-5'
            '1e-6'
            '1e-7'
            '1e-8')
          ExplicitLeft = 827
        end
      end
      object pnl1: TPanel
        Left = 2
        Top = 31
        Width = 899
        Height = 114
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 3
        ExplicitWidth = 895
        object RzPanel6: TRzPanel
          AlignWithMargins = True
          Left = 459
          Top = 6
          Width = 437
          Height = 105
          Margins.Top = 6
          Align = alClient
          BorderOuter = fsFlatRounded
          Color = 15987699
          TabOrder = 0
          ExplicitWidth = 433
          object Label7: TLabel
            Left = 9
            Top = 11
            Width = 47
            Height = 13
            Caption = 'Itreations'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentFont = False
          end
          object Label8: TLabel
            Left = 9
            Top = 38
            Width = 50
            Height = 13
            Caption = 'Population'
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -11
            Font.Name = 'Tahoma'
            Font.Style = []
            ParentFont = False
          end
          object edFIter: TEdit
            Left = 62
            Top = 7
            Width = 43
            Height = 22
            Alignment = taRightJustify
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -12
            Font.Name = 'Tahoma'
            Font.Style = []
            NumbersOnly = True
            ParentFont = False
            TabOrder = 0
            Text = '50'
          end
          object edFPopulation: TEdit
            Left = 62
            Top = 34
            Width = 43
            Height = 22
            Alignment = taRightJustify
            Font.Charset = DEFAULT_CHARSET
            Font.Color = clBlack
            Font.Height = -12
            Font.Name = 'Tahoma'
            Font.Style = []
            NumbersOnly = True
            ParentFont = False
            TabOrder = 1
            Text = '50'
          end
          object RzGroupBox1: TRzGroupBox
            Left = 111
            Top = 0
            Width = 162
            Height = 100
            Caption = 'LFPSO'
            Color = 15987699
            TabOrder = 2
            object Label16: TLabel
              Left = 6
              Top = 19
              Width = 26
              Height = 13
              Caption = 'Vmax'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object Label13: TLabel
              Left = 6
              Top = 47
              Width = 23
              Height = 13
              Caption = 'k '#967'2 '
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object Label14: TLabel
              Left = 86
              Top = 46
              Width = 31
              Height = 13
              Caption = 'kVmax'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object Label15: TLabel
              Left = 6
              Top = 75
              Width = 19
              Height = 13
              Caption = 'Skip'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object Label17: TLabel
              Left = 81
              Top = 76
              Width = 31
              Height = 13
              Caption = 'RImax'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object cbLFPSOShake: TRzCheckBox
              Left = 98
              Top = 16
              Width = 54
              Height = 19
              Caption = 'Shake'
              Checked = True
              State = cbChecked
              TabOrder = 0
            end
            object edFVmax: TEdit
              Left = 38
              Top = 15
              Width = 35
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 1
              Text = '0.05'
            end
            object edLFPSOChiFactor: TEdit
              Left = 38
              Top = 43
              Width = 35
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 2
              Text = '1'
            end
            object edLFPSOkVmax: TEdit
              Left = 118
              Top = 42
              Width = 35
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 3
              Text = '1.4'
            end
            object edLFPSOSkip: TEdit
              Left = 38
              Top = 71
              Width = 35
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 4
              Text = '1'
            end
            object edLFPSORImax: TEdit
              Left = 118
              Top = 70
              Width = 35
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 5
              Text = '3'
            end
          end
        end
        object RzPanel7: TRzPanel
          Left = 0
          Top = 0
          Width = 456
          Height = 114
          Align = alLeft
          BorderOuter = fsNone
          Color = 15987699
          TabOrder = 1
          object RzPanel4: TRzPanel
            Left = 351
            Top = 6
            Width = 98
            Height = 108
            BorderOuter = fsFlatRounded
            Color = 15987699
            TabOrder = 0
            object Label5: TLabel
              Left = 9
              Top = 8
              Width = 82
              Height = 13
              Caption = 'Number of points'
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -11
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
            end
            object edN: TEdit
              Left = 41
              Top = 27
              Width = 48
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              NumbersOnly = True
              ParentFont = False
              TabOrder = 0
              Text = '2000'
            end
          end
          object rgPolarisation: TRzRadioGroup
            Left = 193
            Top = 0
            Width = 152
            Height = 42
            BorderOuter = fsFlatRounded
            Caption = 'Polarization'
            Color = 15987699
            Columns = 2
            ItemHeight = 17
            ItemIndex = 0
            Items.Strings = (
              's-type'
              'sp-type')
            SpaceEvenly = True
            TabOrder = 1
          end
          object pnlWaveParams: TRzPanel
            Left = 192
            Top = 47
            Width = 153
            Height = 67
            BorderOuter = fsFlatRounded
            Color = 15987699
            Enabled = False
            TabOrder = 2
            Transparent = True
            object Label9: TLabel
              Left = 8
              Top = 40
              Width = 16
              Height = 19
              Caption = 'l2'
              Enabled = False
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object Label10: TLabel
              Left = 7
              Top = 17
              Width = 16
              Height = 19
              Caption = 'l1'
              Enabled = False
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object Label11: TLabel
              Left = 83
              Top = 14
              Width = 8
              Height = 19
              Caption = 'q'
              Enabled = False
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object Label12: TLabel
              Left = 80
              Top = 41
              Width = 17
              Height = 19
              Caption = 'Dl'
              Enabled = False
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object edStartL: TEdit
              Left = 23
              Top = 13
              Width = 47
              Height = 22
              Alignment = taRightJustify
              Enabled = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 0
              Text = '1'
            end
            object edEndL: TEdit
              Left = 23
              Top = 39
              Width = 47
              Height = 22
              Alignment = taRightJustify
              Enabled = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 1
              Text = '10'
            end
            object edTheta: TEdit
              Left = 97
              Top = 13
              Width = 40
              Height = 22
              Alignment = taRightJustify
              Enabled = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 2
              Text = '85'
            end
            object edDL: TEdit
              Left = 97
              Top = 40
              Width = 40
              Height = 22
              Alignment = taRightJustify
              Enabled = False
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 3
              Text = '0'
            end
          end
          object pnlAngleParams: TRzPanel
            Left = 3
            Top = 47
            Width = 182
            Height = 67
            BorderOuter = fsFlatRounded
            Color = 15987699
            TabOrder = 3
            Transparent = True
            object Label1: TLabel
              Left = 3
              Top = 40
              Width = 16
              Height = 19
              Caption = 'q2'
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object Label2: TLabel
              Left = 3
              Top = 14
              Width = 16
              Height = 19
              Caption = 'q1'
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object Label3: TLabel
              Left = 80
              Top = 14
              Width = 8
              Height = 19
              Caption = 'l'
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object Label4: TLabel
              Left = 75
              Top = 40
              Width = 17
              Height = 19
              Caption = 'Dq'
              Font.Charset = GREEK_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
            end
            object edStartTeta: TEdit
              Left = 19
              Top = 13
              Width = 50
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 0
              Text = '0.01'
            end
            object edEndTeta: TEdit
              Left = 19
              Top = 40
              Width = 50
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 1
              Text = '10'
            end
            object edWidth: TEdit
              Left = 96
              Top = 39
              Width = 37
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 2
              Text = '0.015'
            end
            object edLambda: TEdit
              Left = 96
              Top = 13
              Width = 73
              Height = 22
              Alignment = taRightJustify
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -12
              Font.Name = 'Tahoma'
              Font.Style = []
              ParentFont = False
              TabOrder = 3
              Text = '1.54043'
            end
            object cb2Theta: TRzCheckBox
              Left = 139
              Top = 40
              Width = 39
              Height = 21
              Caption = '2q'
              Checked = True
              Font.Charset = DEFAULT_CHARSET
              Font.Color = clBlack
              Font.Height = -15
              Font.Name = 'Symbol'
              Font.Style = []
              ParentFont = False
              State = cbChecked
              TabOrder = 4
              Transparent = True
            end
          end
          object rgCalcMode: TRzRadioGroup
            Left = 3
            Top = 0
            Width = 182
            Height = 42
            BorderOuter = fsFlatRounded
            Caption = 'Mode'
            Color = 15987699
            Columns = 2
            ItemHeight = 17
            ItemIndex = 0
            Items.Strings = (
              'by angle'
              'by wave')
            SpaceEvenly = True
            TabOrder = 4
          end
        end
      end
      object ChartToolBar: TRzToolbar
        Left = 2
        Top = 2
        Width = 899
        Height = 29
        Images = ilCalc
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        StyleName = 'Windows'
        TabOrder = 4
        ExplicitWidth = 895
        ToolbarControls = (
          btnCalcRun
          BtnFastForward
          BtnExecute
          RzSpacer2
          BtnCancel
          rzspcr4
          btnResultSave
          btnBtnCopy
          rzspcr3
          btnDataLoad
          btnDataPaste)
        object btnDataLoad: TRzToolButton
          Left = 178
          Top = 2
          Action = DataLoad
          ParentShowHint = False
          ShowHint = True
        end
        object btnDataPaste: TRzToolButton
          Left = 203
          Top = 2
          Action = DataPaste
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr3: TRzSpacer
          Left = 170
          Top = 2
        end
        object btnCalcRun: TRzToolButton
          Left = 4
          Top = 2
          Action = CalcRun
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr4: TRzSpacer
          Left = 112
          Top = 2
        end
        object btnResultSave: TRzToolButton
          Left = 120
          Top = 2
          DisabledIndex = 35
          Action = ResultSave
          ParentShowHint = False
          ShowHint = True
        end
        object btnBtnCopy: TRzToolButton
          Left = 145
          Top = 2
          DisabledIndex = 37
          Action = ResultCopy
          ParentShowHint = False
          ShowHint = True
        end
        object RzSpacer2: TRzSpacer
          Left = 79
          Top = 2
        end
        object BtnExecute: TRzToolButton
          Left = 54
          Top = 2
          DisabledIndex = 41
          Action = actAutoFitting
        end
        object BtnFastForward: TRzToolButton
          Left = 29
          Top = 2
          DisabledIndex = 52
          ImageIndex = 51
          Action = CalcAll
        end
        object BtnCancel: TRzToolButton
          Left = 87
          Top = 2
          DisabledIndex = 54
          Action = CalcStop
        end
      end
    end
    object StructurePanel: TRzPanel
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 350
      Height = 836
      Align = alLeft
      BorderOuter = fsFlatRounded
      Color = 15987699
      TabOrder = 1
      object RzToolbar2: TRzToolbar
        Left = 2
        Top = 2
        Width = 346
        Height = 29
        Images = ilStructure
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        StyleName = 'Windows'
        TabOrder = 0
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
        object btnPeriodAdd: TRzToolButton
          Left = 4
          Top = 2
          Action = PeriodAdd
          ParentShowHint = False
          ShowHint = True
        end
        object btnPeriodInsert: TRzToolButton
          Left = 29
          Top = 2
          Action = PeriodInsert
          ParentShowHint = False
          ShowHint = True
        end
        object btnPeriodDelete: TRzToolButton
          Left = 54
          Top = 2
          Action = PeriodDelete
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr1: TRzSpacer
          Left = 79
          Top = 2
        end
        object btnLayerAdd: TRzToolButton
          Left = 87
          Top = 2
          Hint = 'Add Layer'
          Action = LayerAdd
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerInsert: TRzToolButton
          Left = 112
          Top = 2
          Hint = 'Insert Layer'
          Action = LayerInsert
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerPaste: TRzToolButton
          Left = 187
          Top = 2
          Hint = 'Paste layer'
          Action = LayerPaste
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerDelete: TRzToolButton
          Left = 220
          Top = 2
          Hint = 'Delete layer'
          Action = LayerDelete
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerCut: TRzToolButton
          Left = 162
          Top = 2
          Hint = 'Cut layer'
          Action = LayerCut
          ParentShowHint = False
          ShowHint = True
        end
        object RzSpacer3: TRzSpacer
          Left = 212
          Top = 2
        end
        object btnCopyLayer: TRzToolButton
          Left = 137
          Top = 2
          Action = actLayerCopy
        end
      end
      object RzPanel2: TRzPanel
        Left = 2
        Top = 31
        Width = 346
        Height = 41
        Align = alTop
        BorderOuter = fsNone
        Color = 15987699
        TabOrder = 1
        object Label6: TLabel
          Left = 6
          Top = 10
          Width = 49
          Height = 13
          Caption = 'Increment'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clBlack
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = []
          ParentFont = False
        end
        object cbIncrement: TRzComboBox
          Left = 61
          Top = 6
          Width = 52
          Height = 23
          TabOrder = 0
          Text = '0.1'
          OnChange = cbIncrementChange
          Items.Strings = (
            '10'
            '5'
            '1'
            '0.1'
            '0.01'
            '0.001')
          ItemIndex = 3
          Values.Strings = (
            '10'
            '5'
            '1'
            '0.25'
            '0.1'
            '0.01'
            '0.001')
        end
        object btnSetFitLimits: TBitBtn
          Left = 265
          Top = 5
          Width = 75
          Height = 25
          Caption = 'Limits'
          TabOrder = 1
          OnClick = btnSetFitLimitsClick
        end
      end
    end
  end
  object mmMain: TMainMenu
    Left = 472
    Top = 232
    object File1: TMenuItem
      Caption = 'File'
      object File2: TMenuItem
        Action = FileNew
      end
      object Openproject1: TMenuItem
        Action = FileOpen
      end
      object Reopen1: TMenuItem
        Caption = 'Reopen ...'
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
        Caption = 'Settings'
      end
      object Settings2: TMenuItem
        Caption = '-'
      end
      object Exit1: TMenuItem
        Action = FileClose
      end
    end
    object Project1: TMenuItem
      Caption = 'Project'
      object Add1: TMenuItem
        Caption = 'Add'
      end
    end
    object Project2: TMenuItem
      Caption = 'Structure'
    end
    object Calc1: TMenuItem
      Caption = 'Calc'
      object Calc3: TMenuItem
        Caption = 'Calc'
        ShortCut = 116
      end
      object Calcall1: TMenuItem
        Caption = 'Calc all'
        ShortCut = 123
      end
    end
    object Calc2: TMenuItem
      Caption = 'Help'
      object About1: TMenuItem
        Caption = 'About'
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
            CommandProperties.Width = 250
          end>
      end
      item
        Items = <
          item
            Caption = '&CheckBox1'
            CommandStyle = csControl
            CommandProperties.Width = 250
          end>
      end
      item
        Items = <
          item
            Caption = '&Edit1'
            CommandStyle = csControl
            CommandProperties.Width = 250
            CommandProperties.ContainedControl = edEndL
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
            CommandProperties.Width = -1
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
            Caption = '&Save'
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
            CommandProperties.Width = 250
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
                    CommandProperties.Width = -1
                    CommandProperties.Content.Strings = (
                      'Save project with the same file name')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -11
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
                    CommandProperties.Width = -1
                    CommandProperties.Content.Strings = (
                      'Select file name and location')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -11
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
                    Caption = '&Save plot as file ...'
                    CommandStyle = csMenu
                    ImageIndex = 14
                    CommandProperties.Width = -1
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -11
                    CommandProperties.Font.Name = 'Tahoma'
                    CommandProperties.Font.Style = []
                    CommandProperties.Height = 0
                  end
                  item
                    Action = FileCopyPlotBMP
                    Caption = '&Copy as BMP'
                    CommandStyle = csMenu
                    ImageIndex = 13
                    CommandProperties.Width = -1
                    CommandProperties.Content.Strings = (
                      'Copy plot to clipboard as bitmap')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -11
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
                    CommandProperties.Width = -1
                    CommandProperties.Content.Strings = (
                      'Copy plot to clipboard as Windows metafile')
                    CommandProperties.Font.Charset = DEFAULT_CHARSET
                    CommandProperties.Font.Color = clWindowText
                    CommandProperties.Font.Height = -11
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
                ShortCut = 123
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
            Caption = '&Save'
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
            CommandProperties.Width = 150
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
            Action = actShowLibrary
            Caption = '&Library'
            ImageIndex = 19
            CommandProperties.ButtonSize = bsLarge
          end>
      end>
    Left = 688
    Top = 200
    StyleName = 'Ribbon - Luna'
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
      Caption = 'Save'
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
      ShortCut = 123
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
    end
    object DataNormAuto: TAction
      Category = 'Data'
      Caption = 'Auto'
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
      Category = 'Materials'
      Caption = 'Save plot as file ...'
    end
    object FileCopyPlotBMP: TAction
      Category = 'Plot'
      Caption = 'Copy as BMP'
    end
    object FilePlotCopyWMF: TAction
      Category = 'Plot'
      Caption = 'Copy as WMF'
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
    end
    object HelpContent: TAction
      Category = 'Help'
      Caption = 'Help content'
      ImageIndex = 19
      ShortCut = 112
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
    object actShowLibrary: TAction
      Category = 'Materials'
      Caption = 'Show Library'
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
  end
  object ilProject: TImageList
    ColorDepth = cd32Bit
    Left = 64
    Top = 544
    Bitmap = {
      494C010116001800040010001000FFFFFFFF2100FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000006000000001002000000000000060
      000000000000000000000000000000000000000000000000000000000000E2EF
      F100E5E5E500E5E5E500E5E5E500E5E5E500E5E5E50000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000E5E5E500C0C0
      C0009999990080808000808080009999990099A8AC00C0C0C000CCCCCC00E2EF
      F10000000000000000000000000000000000000000000000000000000000C0C0
      C00099999900999999008080800099999900CCCCCC00C0C0C000CCCCCC000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CCCCCC00CCCC
      CC00CCCC9900CCCC9900CCCC990099999900808080006666660080808000B2B2
      B200E5E5E5000000000000000000000000000000000000000000CCCCCC00CCCC
      CC00C0C0C000C0C0C000C0C0C00099999900808080009999990080808000B2B2
      B200000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000E5E5E500FFFFCC00F2EA
      BF00F2EABF00CCCC9900ECC6D900FFCC9900F2EABF00F2EABF00808080006666
      660099999900E5E5E50000000000000000000000000000000000000000000000
      000000000000C0C0C000CCCCCC00C0C0C0000000000000000000808080009999
      9900999999000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000FFCC9900F2EABF00F2EA
      BF00CCCCCC00ECC6D90000990000CCCCCC00CCCCCC00CCCCCC00FFFFCC00B2B2
      B200646F7100CCCCCC00000000000000000000000000C0C0C000000000000000
      0000CCCCCC00CCCCCC0099999900CCCCCC00CCCCCC00CCCCCC0000000000B2B2
      B20099999900CCCCCC0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000FFCC9900FFCC9900E5E5
      E500ECC6D900ECC6D9000099000000990000009900000099000099CC9900F2EA
      BF0080808000B2B2B200E2EFF1000000000000000000C0C0C000C0C0C0000000
      0000CCCCCC00CCCCCC0099999900999999009999990099999900B2B2B2000000
      000080808000B2B2B20000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000E5E5E500FFCC9900E5E5E500E5E5
      E500ECC6D900C0C0C000009900000099000066CC6600CCFFCC0033CC3300FFCC
      990080808000B2B2B200E2EFF1000000000000000000C0C0C000000000000000
      0000CCCCCC00C0C0C0009999990099999900CCCCCC000000000099999900C0C0
      C00080808000B2B2B20000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F2EABF00F2EABF00FFFFFF00FFFF
      FF00CC999900ECC6D90099CC9900CCCC990033CC330099CC990099CC9900CCCC
      99009999990099999900E5E5E50000000000CCCCCC0000000000000000000000
      000099999900CCCCCC00B2B2B200C0C0C00099999900B2B2B200B2B2B200C0C0
      C000999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F2EABF00FFFFCC00FFFFFF00ECC6
      D900CC999900ECC6D90066993300FFFFFF0066CC66000099000000990000F2EA
      BF009999990099999900E5E5E50000000000CCCCCC000000000000000000CCCC
      CC0099999900CCCCCC009999990000000000CCCCCC0099999900999999000000
      0000999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F2EABF00FFFFFF00FFFFFF00ECC6
      D900ECC6D900ECC6D90099CC990000990000339933000099000000990000F2EA
      BF00CCCC990080808000E5E5E50000000000CCCCCC000000000000000000CCCC
      CC00CCCCCC00CCCCCC00B2B2B200999999009999990099999900999999000000
      0000C0C0C0008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFFCC00FFFFCC00FFFFCC00FFFF
      FF00FFFFFF00E2EFF100E5E5E50099CC990099CC990066CC660000990000FFFF
      CC00C0C0C00080808000CCCCCC0000000000CCCCCC0000000000000000000000
      0000000000000000000000000000B2B2B200B2B2B200CCCCCC00999999000000
      0000C0C0C00080808000CCCCCC00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFFCC00FFFFCC00FFFFCC00FFFF
      CC00E2EFF100E2EFF100E2EFF100FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFCC00646F7100CCCCCC0000000000CCCCCC0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F2EABF00F2EABF00F2EABF00E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E2EFF100F2EABF00FFFF
      CC00FFFFCC00646F7100CCCCCC000000000000000000CCCCCC00CCCCCC000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000E5E5E500E5E5E50099CC
      FF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00E2EFF10099CCFF00FFCC9900FFCC
      9900FFFFCC0080808000E5E5E50000000000000000000000000000000000CCCC
      CC000000000000000000000000000000000000000000CCCCCC00C0C0C000C0C0
      C000000000008080800000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000E2EF
      F10099CCFF0099CCFF0099CCFF00CCFFFF00CCFFFF0099CCFF00FFCC9900FFCC
      9900FFCC9900C0C0C000E2EFF100000000000000000000000000000000000000
      0000CCCCCC00CCCCCC00CCCCCC000000000000000000CCCCCC00C0C0C000C0C0
      C000C0C0C000C0C0C00000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000099CCFF0099CCFF0099CCFF00F2EABF00F2EA
      BF00E5E5E500E2EFF10000000000000000000000000000000000000000000000
      0000000000000000000000000000CCCCCC00CCCCCC00CCCCCC00000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000033333300000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000006666660099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000003333330066666600666666006666
      6600000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000009999990066666600666666006666
      6600000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000099999900CCCCCC009999
      9900666666006666660000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC009999
      9900666666006666660000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00CCCCCC00CCCCCC00CCCCCC00CCCCCC00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC000000000000000000000000000000
      0000000000009999990000000000000000000000000099999900CCCCCC00CCCC
      CC00999999009999990066666600666666000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00999999009999990066666600666666000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0099330000FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000099999900000000000000
      000000000000999999000000000000000000000000000000000099999900CCCC
      CC00CCCCCC009999990099999900999999006666660066666600000000000000
      000000000000000000000000000000000000000000000000000099999900CCCC
      CC00CCCCCC009999990099999900999999006666660066666600000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00CCCCCC00CCCCCC00FFFFFF00FFFFFF009933000099330000FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC0000000000000000009999990099999900000000000000
      000000000000999999000000000000000000000000000000000099999900E5E5
      E500CCCCCC00CCCCCC0099999900999999009999990099330000663300006633
      000000000000000000000000000000000000000000000000000099999900E5E5
      E500CCCCCC00CCCCCC0099999900999999009999990099999900666666006666
      6600000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF0099330000993300009933000099330000CC99
      6600FFFFFF00CC99660000000000000000000000000000000000999999000000
      000000000000000000000000000099999900999999009999990099999900CCCC
      CC00000000009999990000000000000000000000000000000000000000009999
      9900E5E5E500CCCCCC00CCCCCC00999999009933000099330000993300009933
      0000663300000000000000000000000000000000000000000000000000009999
      9900E5E5E500CCCCCC00CCCCCC00999999009999990099999900999999009999
      9900666666000000000000000000000000000000000000000000CC996600FFFF
      FF00CCCCCC00CCCCCC00FFFFFF00FFFFFF009933000099330000FFFFFF009933
      0000FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC0000000000000000009999990099999900000000009999
      9900000000009999990000000000000000000000000000000000000000009999
      9900FFFFFF00E5E5E500CCCCCC00993300009933000099330000993300009933
      0000993300006633000000000000000000000000000000000000000000009999
      9900FFFFFF00E5E5E500CCCCCC00999999009999990099999900999999009999
      9900999999006666660000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF0099330000FFFFFF009933
      0000FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000099999900000000009999
      9900000000009999990000000000000000000000000000000000000000000000
      000099999900FFFFFF0099330000CC6633009933000099330000993300009933
      0000993300009933000066330000000000000000000000000000000000000000
      000099999900FFFFFF0099999900CCCCCC009999990099999900999999009999
      9900999999009999990066666600000000000000000000000000CC996600FFFF
      FF00CCCCCC00CCCCCC00CCCCCC00FFFFFF00FFFFFF00FFFFFF00FFFFFF009933
      0000FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00000000000000000000000000000000009999
      9900000000009999990000000000000000000000000000000000000000000000
      00009999990099330000CC66330099330000CC66330099330000993300009933
      0000993300009933000099330000663300000000000000000000000000000000
      00009999990099999900CCCCCC0099999900CCCCCC0099999900999999009999
      9900999999009999990099999900666666000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF009933
      0000FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000009999
      9900000000009999990000000000000000000000000000000000000000000000
      0000000000009933000099330000CC66330099330000CC663300993300009933
      0000993300009933000099330000993300000000000000000000000000000000
      0000000000009999990099999900CCCCCC0099999900CCCCCC00999999009999
      9900999999009999990099999900999999000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF009933000099330000993300009933000099330000CC99
      6600FFFFFF00CC99660000000000000000000000000000000000999999000000
      000000000000000000009999990099999900999999009999990099999900CCCC
      CC00000000009999990000000000000000000000000000000000000000000000
      000000000000993300009933000099330000CC66330099330000CC6633009933
      0000993300009933000099330000999999000000000000000000000000000000
      000000000000999999009999990099999900CCCCCC0099999900CCCCCC009999
      9900999999009999990099999900999999000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      00000000000000000000993300009933000099330000CC66330099330000CC66
      3300993300009933000099999900999999000000000000000000000000000000
      00000000000000000000999999009999990099999900CCCCCC0099999900CCCC
      CC00999999009999990099999900999999000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000993300009933000099330000CC6633009933
      000099330000CCCCCC00CCCCCC00999999000000000000000000000000000000
      0000000000000000000000000000999999009999990099999900CCCCCC009999
      990099999900CCCCCC00CCCCCC00999999000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000009933000099330000993300009933
      0000E5E5E500E5E5E500CCCCCC00CCCCCC000000000000000000000000000000
      0000000000000000000000000000000000009999990099999900999999009999
      9900E5E5E500E5E5E500CCCCCC00CCCCCC000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC00006699000066990000669900006699000066
      9900006699000066990000669900000000000000000000000000000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000CC996600CC996600CC996600CC996600CC99
      6600CC996600CC996600CC996600CC9966000000000000000000000000000000
      0000000000000000000000000000999999009999990099999900999999009999
      9900999999009999990099999900999999000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000006699000066
      9900006699000066990000669900CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966000000000000000000999999009999
      9900999999009999990099999900999999000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000000000003399CC0099FFFF0099FF
      FF0099FFFF0099FFFF0099FFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000000000003399CC00CCFFFF0099FF
      FF0099FFFF0099FFFF0099FFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      00000000000000000000000000009999990000000000CC996600CC996600CC99
      6600CC996600CC9966003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900999999009999
      9900999999009999990099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000000000003399CC0099FFFF00CCFF
      FF0099FFFF0099FFFF0099FFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      00000000000000000000000000009999990000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000000000003399CC00CCFFFF0099FF
      FF00CCFFFF0099FFFF0099FFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      00000000000000000000000000009999990000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC003399CC003399CC003399CC00000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      990099999900999999009999990000000000000000003399CC0099FFFF00CCFF
      FF0099FFFF00CCFFFF0099FFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600CC996600CC996600CC9966000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      00009999990099999900999999009999990000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00CCFFFF000066990000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900CCCCCC00999999000000000000000000000000003399CC00CCFFFF0099FF
      FF00CCFFFF0099FFFF00CCFFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600E5E5E500CC996600000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      00009999990000000000999999000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00006699000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      990099999900000000000000000000000000000000003399CC0099FFFF00CCFF
      FF0099FFFF00CCFFFF0099FFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999000000000000000000000000000000
      00009999990099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC003399CC003399CC003399CC003399CC003399
      CC00000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      990000000000000000000000000000000000000000003399CC00CCFFFF0099FF
      FF00CCFFFF0099FFFF00CCFFFF00CC996600CC996600CC996600CC996600CC99
      6600CC9966000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00999999009999990099999900999999009999
      99009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      000000000000000000000000000000000000000000003399CC00CCFFFF00CCFF
      FF0099FFFF00CCFFFF0099FFFF00CCFFFF0099FFFF00CCFFFF0099FFFF0099FF
      FF00006699000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC996600CC996600CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900000000000000
      000000000000000000000000000000000000000000003399CC00CCFFFF00CCFF
      FF00CC6600009933000099330000993300009933000099330000CCFFFF0099FF
      FF00006699000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00999999009999990099999900999999009999990099999900CCCCCC00CCCC
      CC009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600E5E5E500CC99660000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900000000009999990000000000000000000000
      000000000000000000000000000000000000000000003399CC00CCFFFF00CCFF
      FF00CC660000FFFFFF00FF990000FF990000FF9900009933000099FFFF00CCFF
      FF00006699000000000000000000000000000000000099999900CCCCCC00CCCC
      CC0099999900FFFFFF00CCCCCC00CCCCCC00CCCCCC0099999900CCCCCC00CCCC
      CC009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC9966000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999000000000000000000000000000000
      00000000000000000000000000000000000000000000000000003399CC003399
      CC003399CC00CC660000FFFFFF00FF990000993300003399CC003399CC003399
      CC00000000000000000000000000000000000000000000000000999999009999
      99009999990099999900FFFFFF00CCCCCC009999990099999900999999009999
      99000000000000000000000000000000000000000000CC996600CC996600CC99
      6600CC996600CC996600CC996600000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000CC660000CC6600000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000CC996600CC996600CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC996600CC996600CC9966009999990099999900999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      000000000000000000000000000000000000CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300009933
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      990000000000000000000000000000000000CC996600FFFFFF00CC996600CC99
      6600CC996600CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300000000000000000000000000000000000000000000000000009999
      9900999999009999990099999900999999009999990099999900999999009999
      990099999900000000000000000000000000CC996600FFFFFF00CC996600FFFF
      FF00FFFFFF00CC996600FFFFFF00993300009933000099330000993300009933
      00009933000099330000FFFFFF00CC9966009999990000000000999999000000
      0000000000009999990000000000999999009999990099999900999999009999
      9900999999009999990000000000999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300009933
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      990000000000000000000000000000000000CC996600FFFFFF00CC996600FFFF
      FF00FFFFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000999999000000
      0000000000009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      000000000000000000000000000000000000CC996600FFFFFF00CC996600CC99
      6600CC996600CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CC996600CC996600CC996600CC99
      6600CC996600CC996600CC99660000000000000000003399CC00006699000066
      9900006699000066990000669900006699009999990099999900999999009999
      9900999999009999990099999900000000000000000099999900999999009999
      990099999900999999009999990099999900CC996600FFFFFF00CC996600CC99
      6600CC996600CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC99660000000000000000003399CC0099FFFF0099FF
      FF0099FFFF0099FFFF0099FFFF00006699009999990000000000000000000000
      0000000000000000000099999900000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC0099999900CC996600FFFFFF00CC996600FFFF
      FF00FFFFFF00CC996600FFFFFF00993300009933000099330000993300009933
      00009933000099330000FFFFFF00CC9966009999990000000000999999000000
      0000000000009999990000000000999999009999990099999900999999009999
      990099999900999999000000000099999900CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC99660000000000000000003399CC0099FFFF0099FF
      FF0099FFFF0099FFFF0099FFFF00006699009999990000000000000000000000
      0000000000000000000099999900000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC0099999900CC996600FFFFFF00CC996600FFFF
      FF00FFFFFF00CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000999999000000
      0000000000009999990000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC99660000000000000000003399CC0099FFFF0099FF
      FF0099FFFF0099FFFF0099FFFF00006699009999990000000000000000000000
      0000000000000000000099999900000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC0099999900CC996600FFFFFF00CC996600CC99
      6600CC996600CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC99660000000000000000003399CC0099FFFF0099FF
      FF0099FFFF0099FFFF0099FFFF00006699009999990000000000000000000000
      0000000000000000000099999900000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC0099999900CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00CC9966009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CC996600FFFFFF00FFFFFF00CC99
      6600CC996600CC996600CC99660000000000000000003399CC0099FFFF0099FF
      FF003399CC003399CC003399CC003399CC009999990000000000000000009999
      9900999999009999990099999900000000000000000099999900CCCCCC00CCCC
      CC0099999900999999009999990099999900CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC996600CC996600CC9966009999990000000000000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      990099999900999999009999990099999900CC996600FFFFFF00FFFFFF00CC99
      6600E5E5E500CC9966000000000000000000000000003399CC0099FFFF0099FF
      FF003399CC00CCFFFF0000669900000000009999990000000000000000009999
      9900E5E5E5009999990000000000000000000000000099999900CCCCCC00CCCC
      CC0099999900CCCCCC009999990000000000CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC996600CC996600CCCCCC00CCCCCC00CCCCCC00CCCCCC00CC99
      6600000000000000000000000000000000009999990000000000000000000000
      0000000000009999990099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      990000000000000000000000000000000000CC996600FFFFFF00FFFFFF00CC99
      6600CC996600000000000000000000000000000000003399CC0099FFFF0099FF
      FF003399CC000066990000000000000000009999990000000000000000009999
      9900999999000000000000000000000000000000000099999900CCCCCC00CCCC
      CC009999990099999900000000000000000000000000CC996600CC996600CC99
      6600CC9966000000000000000000CC996600CC996600CC996600CC9966000000
      0000000000000000000000000000000000000000000099999900999999009999
      9900999999000000000000000000999999009999990099999900999999000000
      000000000000000000000000000000000000CC996600CC996600CC996600CC99
      660000000000000000000000000000000000000000003399CC003399CC003399
      CC003399CC000000000000000000000000009999990099999900999999009999
      9900000000000000000000000000000000000000000099999900999999009999
      9900999999000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300009933000099330000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999000000000000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC00999999000000000000000000CC996600FFCC9900FFCC
      9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900CC99
      6600CC99660099330000000000000000000000000000B2B2B200CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00B2B2
      B200B2B2B2009999990000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000CC996600CC996600CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      660099330000CC9966009933000000000000B2B2B200B2B2B200B2B2B200B2B2
      B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2
      B20099999900B2B2B20099999900000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFCC9900FFCC
      9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC
      9900CC996600993300009933000000000000B2B2B20000000000CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00B2B2B2009999990099999900000000000000000099330000CC660000CC66
      000099330000E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFCC9900FFCC
      9900FFCC9900FFCC990000CC000000990000FFCC99000000FF000000CC00FFCC
      9900CC996600CC9966009933000000000000B2B2B20000000000CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00B2B2B20099999900CCCCCC00B2B2B20099999900CCCC
      CC00B2B2B200B2B2B20099999900000000000000000099330000CC660000CC66
      0000CC660000993300009933000099330000993300009933000099330000CC66
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00999999009999990099999900999999009999990099999900CCCC
      CC00CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600CC996600CC99660099330000B2B2B20000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B2B2B200B2B2B200B2B2B200999999000000000099330000CC660000CC66
      0000CC660000CC660000CC660000CC660000CC660000CC660000CC660000CC66
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFCC9900FFCC
      9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC
      9900CC996600CC996600CC99660099330000B2B2B20000000000CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00B2B2B200B2B2B200B2B2B200999999000000000099330000CC660000CC66
      0000993300009933000099330000993300009933000099330000993300009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC00999999009999990099999900999999009999990099999900999999009999
      9900CCCCCC00CCCCCC00999999000000000000000000CC996600CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600FFCC
      9900FFCC9900CC996600CC9966009933000000000000B2B2B200B2B2B200B2B2
      B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200CCCC
      CC00CCCCCC00B2B2B200B2B2B200999999000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC99
      6600FFCC9900FFCC9900CC996600993300000000000000000000B2B2B2000000
      000000000000000000000000000000000000000000000000000000000000B2B2
      B200CCCCCC00CCCCCC00B2B2B200999999000000000099330000CC6600009933
      0000FFFFFF00993300009933000099330000993300009933000099330000FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00999999009999990099999900999999009999990099999900FFFF
      FF0099999900CCCCCC009999990000000000000000000000000000000000CC99
      6600FFFFFF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFFFF00CC99
      6600CC996600CC9966009933000000000000000000000000000000000000B2B2
      B20000000000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC0000000000B2B2
      B200B2B2B200B2B2B20099999900000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC009999990000000000000000000000000000000000CC99
      6600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600000000000000000000000000000000000000000000000000B2B2
      B200000000000000000000000000000000000000000000000000000000000000
      0000B2B2B2000000000000000000000000000000000099330000E5E5E5009933
      0000FFFFFF00993300009933000099330000993300009933000099330000FFFF
      FF00993300009933000099330000000000000000000099999900E5E5E5009999
      9900FFFFFF00999999009999990099999900999999009999990099999900FFFF
      FF00999999009999990099999900000000000000000000000000000000000000
      0000CC996600FFFFFF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFF
      FF00CC9966000000000000000000000000000000000000000000000000000000
      0000B2B2B20000000000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC000000
      0000B2B2B2000000000000000000000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC0099999900000000000000000000000000000000000000
      0000CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000000000000000
      0000B2B2B2000000000000000000000000000000000000000000000000000000
      000000000000B2B2B20000000000000000000000000099330000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300009933000099330000000000000000000099999900999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      000000000000CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000000000000000
      000000000000B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2
      B200B2B2B200B2B2B20000000000000000000000000000000000000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000999999000000000000000000000000003399CC00006699000066
      9900006699000066990000669900006699000066990000669900006699000066
      990066CCCC000000000000000000000000000000000099999900999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900CCCCCC000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC003399CC0099FFFF0066CC
      FF0066CCFF0066CCFF0066CCFF0066CCFF0066CCFF0066CCFF0066CCFF003399
      CC00006699000000000000000000000000009999990099999900E5E5E500CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC003399CC0066CCFF0099FF
      FF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF00006699003399CC0000000000000000009999990099999900CCCCCC00E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00999999009999990000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC003399CC0066CCFF0099FF
      FF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF0066CCCC000066990000000000000000009999990099999900CCCCCC00E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00CCCCCC009999990000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC0066CCFF003399CC0099FF
      FF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF0099FFFF00006699003399CC000000000099999900CCCCCC0099999900E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00E5E5E5009999990099999900000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC0066CCFF0066CCCC0066CC
      CC0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF0099FFFF0066CCCC00006699000000000099999900CCCCCC00CCCCCC00CCCC
      CC00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00E5E5E500CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC0099FFFF0066CCFF003399
      CC00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF0099FF
      FF00CCFFFF00CCFFFF00006699000000000099999900E5E5E500CCCCCC009999
      9900E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500E5E5E500E5E5E50099999900000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC0099FFFF0099FFFF0066CC
      FF003399CC003399CC003399CC003399CC003399CC003399CC003399CC003399
      CC003399CC003399CC0066CCFF000000000099999900E5E5E500E5E5E500CCCC
      CC00999999009999990099999900999999009999990099999900999999009999
      99009999990099999900CCCCCC00000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC00CCFFFF0099FFFF0099FF
      FF0099FFFF0099FFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF000066
      99000000000000000000000000000000000099999900E5E5E500E5E5E500E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009999
      9900000000000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFFFF00CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC0000000000999999009999
      990099999900999999000000000000000000000000003399CC00CCFFFF00CCFF
      FF00CCFFFF00CCFFFF003399CC003399CC003399CC003399CC003399CC000000
      0000000000000000000000000000000000000000000099999900E5E5E500E5E5
      E500E5E5E500E5E5E50099999900999999009999990099999900999999000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600E5E5
      E500CC9966000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999000000
      00009999990000000000000000000000000000000000000000003399CC003399
      CC003399CC003399CC0000000000000000000000000000000000000000000000
      0000000000009933000099330000993300000000000000000000999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000009999990099999900999999000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600CC99
      6600000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099330000993300000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900999999000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC9966000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099330000000000000000
      0000000000009933000000000000993300000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000009999990000000000999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300009933
      0000993300000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      990099999900000000000000000000000000424D3E000000000000003E000000
      2800000040000000600000000100010000000000000300000000000000000000
      000000000000000000000000FFFFFF00E07FFFFF00000000C00FE01F00000000
      C007C00F000000008003F8C7000000008003B023000000008001901300000000
      0001B04300000000000170030000000000016113000000000001601300000000
      00017E110000000000017FF90000000000019FF9000000008001EF8B00000000
      E001F18300000000FE03FE3F00000000FFFFFFFFFFFFFFFF3FFF3FFFC003C003
      0FFF0FFFC003DFFB83FF83FFC003D0FB80FF80FFC003DFBBC03FC03FC003D33B
      C00FC00FC003DE0BE007E007C003D32BE003E003C003DFABF001F001C003D1EB
      F000F000C003DFEBF800F800C003DC0BF800F800C003DFFBFC00FC00C003DFFB
      FE00FE00C003C003FF00FF00FFFFFFFFFC01FC01FE00FE00FC01FC01FE00FEFE
      FC01FC01C000C0FEFC01FC01800080FEFC01FC01800080FE80018001800080FE
      8001BC01800080FE8001BC01800080F08003BC03800180F58007BC07800380F3
      800FBC0F80078007803FBFBF80078007803FBC3F80078007807FBD7F80078007
      80FFBCFFC00FC00F81FF81FFFCFFFCFFFFFFFFFFFFFFFFFF00000000FFDFFFDF
      00007FFEFFCFFFCF000043FEE007E00700005A02FFCFFFCF00005BFEFFDFFFDF
      000043FEFFFFFFFF00007FFE01800180000043FE01807D8000005A0201807D80
      00005BFE01807D80000043FE01807D8000007FFE0180618000007C0003816381
      000F780F07836783861F861F0F870F87FFFFFFFFFFFFFFFFC001C001C007C007
      8001800180038003800180010001000180018001000140018001800100014001
      8001800100007FF08001800100004000800180018000800080018001C000DFE0
      80018001E001E82180018001E007EFF780018001F007F41780018001F003F7FB
      80018001F803F803FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC003C003FFFFFFFF
      C003DFFB80078007C003D00B00070007C003DFFB00030003C003D00B00030003
      C003DFFB00010001C003D00B00010001C003DFFB00010001C003D00B00010001
      C003DFFB000F000FC003D043801F801FC007DFD7C3F8C3F8C00FDFCFFFFCFFFC
      C01FC01FFFBAFFBAFFFFFFFFFFC7FFC7}
  end
  object dlgOpenProject: TOpenDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project|*.xrcx'
    Title = 'Load project'
    Left = 336
    Top = 360
  end
  object Zip: TAbZipper
    AutoSave = False
    DOSMode = False
    Left = 402
    Top = 86
  end
  object UnZip: TAbUnZipper
    Left = 354
    Top = 86
  end
  object dlgSaveResult: TSaveDialog
    DefaultExt = 'dat'
    Filter = 'ASCII data|*.dat'
    Title = 'Save result to file'
    Left = 416
    Top = 408
  end
  object dlgLoadData: TOpenDialog
    DefaultExt = 'dat'
    Filter = 'ASCII data|*.txt;*.csv;*.tet|Counter files|*.dat|All files|*.*'
    Title = 'Load curve from file'
    Left = 416
    Top = 352
  end
  object dlgSaveProject: TSaveDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project|*.xrcx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Save project'
    Left = 336
    Top = 408
  end
  object dlgExport: TSaveDialog
    Filter = 
      'Bitmaps (*.bmp)|*.bmp|Enhanced Metafiles (*.emf)|*.emf|Metafiles' +
      ' (*.wmf)|*.wmf'
    Left = 480
    Top = 408
  end
  object pmProject: TPopupMenu
    OnPopup = pmProjectPopup
    Left = 128
    Top = 368
    object pmiNorm: TMenuItem
      Caption = 'Normalize'
      object Auto1: TMenuItem
        Action = DataNormAuto
      end
      object Manual1: TMenuItem
        Action = DataNormMan
      end
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
    object pmiEnabled: TMenuItem
      AutoCheck = True
      Caption = 'Enabled'
      ShortCut = 114
      OnClick = pmiEnabledClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Properties1: TMenuItem
      Caption = 'Properties'
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
    Left = 552
    Top = 465
  end
  object ilStructure: TImageList
    ColorDepth = cd32Bit
    Left = 128
    Top = 544
    Bitmap = {
      494C01013B004800040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      000000000000360000002800000040000000F0000000010020000000000000F0
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC00006699000066990000669900006699000066
      9900006699000066990000669900000000000000000000000000000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC000000000099999900000000000000000000000000CC996600CC996600CC99
      6600CC996600CC9966003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900999999009999
      9900999999009999990099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC003399CC003399CC003399CC00000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00CCFFFF000066990000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900CCCCCC009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00006699000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC003399CC003399CC003399CC003399CC003399
      CC00000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC0000000000999999009999
      99009999990099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999000000
      00009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC996600CC996600CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999009999
      99000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600E5E5E500CC99660000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900000000009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC9966000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000CC996600CC996600CC99
      6600CC996600CC996600CC996600000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900999999000000
      0000000000000000000000000000000000009999990099999900000000000000
      000000000000000000000000000000000000000000000000FF00000099000000
      99000000990000000000000000000000000000000000000000000000FF000000
      99000000990000009900000000000000000000000000B2B2B200808080008080
      8000808080000000000000000000000000000000000000000000B2B2B2008080
      8000808080008080800000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC009999
      99000000000000000000000000000000000099999900CCCCCC00999999000000
      000000000000000000000000000000000000000000000000FF000000CC000000
      CC000000CC00000099000000000000000000000000000000FF000000CC000000
      CC000000CC0000009900000000000000000000000000B2B2B200999999009999
      99009999990080808000000000000000000000000000B2B2B200999999009999
      9900999999008080800000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC009999990000000000000000000000000099999900CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000000000000000FF000000
      CC000000CC000000CC0000009900000000000000FF000000CC000000CC000000
      CC00000099000000000000000000000000000000000000000000B2B2B2009999
      990099999900999999008080800000000000B2B2B20099999900999999009999
      9900808080000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000000000000000000000000
      FF000000CC000000CC000000CC00000099000000CC000000CC000000CC000000
      990000000000000000000000000000000000000000000000000000000000B2B2
      B200999999009999990099999900808080009999990099999900999999008080
      8000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00999999000000000099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC009999990000000000000000000000000000000000000000000000
      00000000FF000000CC000000CC000000CC000000CC000000CC00000099000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B2B2B2009999990099999900999999009999990099999900808080000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC009999990099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000FF000000CC000000CC000000CC0000009900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000B2B2B20099999900999999009999990080808000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00999999000000000099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC009999990000000000000000000000000000000000000000000000
      00000000FF000000CC000000CC000000CC000000CC000000CC00000099000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B2B2B2009999990099999900999999009999990099999900808080000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000000000000000000000000
      FF000000CC000000CC000000CC00000099000000CC000000CC000000CC000000
      990000000000000000000000000000000000000000000000000000000000B2B2
      B200999999009999990099999900808080009999990099999900999999008080
      8000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC009999990000000000000000000000000099999900CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000000000000000FF000000
      CC000000CC000000CC0000009900000000000000FF000000CC000000CC000000
      CC00000099000000000000000000000000000000000000000000B2B2B2009999
      990099999900999999008080800000000000B2B2B20099999900999999009999
      9900808080000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFFFF00CC996600CC99
      6600CC996600CC99660000000000000000000000000099999900CCCCCC009999
      99000000000000000000000000000000000099999900CCCCCC00999999000000
      000000000000000000000000000000000000000000000000FF000000CC000000
      CC000000CC00000099000000000000000000000000000000FF000000CC000000
      CC000000CC0000009900000000000000000000000000B2B2B200999999009999
      99009999990080808000000000000000000000000000B2B2B200999999009999
      9900999999008080800000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600E5E5
      E500CC9966000000000000000000000000000000000099999900999999000000
      0000000000000000000000000000000000009999990099999900000000000000
      000000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF0000000000000000000000000000000000000000000000FF000000
      FF000000FF000000FF00000000000000000000000000B2B2B200B2B2B200B2B2
      B200B2B2B2000000000000000000000000000000000000000000B2B2B200B2B2
      B200B2B2B200B2B2B20000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600CC99
      6600000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC9966000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000D0D5BBF1717A3FF1717A3FF0D0D5BBF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      000000000000000000000000000000000000EEDDCD00EEDDCD00EEDDCD00EEDD
      CD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDD
      CD00EEDDCD00EEDDCD00EEDDCD00EEDDCD000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF1717A3FF8484F6FF5F5FEDFF1717A3FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0A0A8CFF6969F3FF4444E7FF0A0A8CFF000000000000
      000000000000000000000000000000000000EDDCCC00EDDDCC00EFDFCF00EDDD
      CD00F1E1D000F2E3D200F1E1D000F1E1D000F1E0D000F1E1D000F1E1D000F2E3
      D200F0E0D000EEDDCD00EDDDCD00EDDDCD000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000929292FF000000000000
      000000000000000000000D0D5BBF1717A3FF1717A3FF0D0D5BBF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      000000000000000000000000000000000000EDDCCC00ECDCCC00E2D0C100EDDD
      CD00DBC8B900CDB8AB00D5C1B600D6C3B600D5C1B300D5C2B500D4C1B500CDB8
      AB00D7C3B500E8D8C800ECDCCC00ECDCCC000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000929292FF000000000000
      00000000000000000000174F17BF2A8F29FF2A8F29FF174F17BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      000000000000000000000000000000000000ECDBCB00F0E0D000D4C0B100C9B1
      A300C7B0A100BDA69A00B5A09500AE989400C3B2B200AD969100B6A09600C3AC
      A000E5D1C100EEDCCB00F0E0CF00ECDBCB000000000099330000993300000000
      0000000000000000000000000000000000009933000099330000000000000000
      00000000000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF2A8F29FF87E087FF60CC60FF2A8F29FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF177516FF6CD76CFF45BD45FF177516FF000000000000
      000000000000000000000000000000000000EEDDCD00EBD9C900CEB8AC00C5AF
      A500B59D9500C3ACA200CBB6AA00B29C9800CCBCBC00B59C9700CCB7AB00CCB9
      AE00CDB9AE00CAB5AB00CEB8AB00F1DFCF000000000099330000CC6600009933
      00000000000000000000000000000000000099330000CC660000993300000000
      00000000000000000000000000000000000000000000929292FF000000000000
      00000000000000000000174F17BF2A8F29FF2A8F29FF174F17BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      000000000000000000000000000000000000F4E3D100DAC5B600CEBFBF00EDE8
      EB00ECE6E800ECE5E700EFE9EC00DFD6D700A58D8C00E6DEE000EDE8EB00E8E2
      E600EAE3E400F2E8E600CFBFBE00DDC7B6000000000099330000CC660000CC66
      00009933000000000000000000000000000099330000CC660000CC6600009933
      00000000000000000000000000000000000000000000929292FF000000000000
      00000000000000000000115B81BF1EA4E7FF1EA4E7FF115B81BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      000000000000000000000000000000000000F5E4D200D7C1B200C5B1AD00DACC
      C500D5C6BF00D5C6BE00D8C8BF00D4C4BB00BAA59D00D2C2BA00D7C8BF00DCCC
      C500CFBDB7009691A200B29E9C00DFC9B8000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      00009933000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF1EA4E7FF56FFFFFF23FFFFFF1EA4E7FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0E8EE0FF3CFFFFFF12FFFFFF0E8EE0FF000000000000
      000000000000000000000000000000000000F3E2D200D9C2B400D4B6A000E7C9
      BB00E4C7BA00DFC2B200DEBAA700E1BFAE00EACEC100E1C2B300DFBBAA00F3CF
      A50091858D00656C9300BF9B8200E1CCBE000000000099330000CC660000CC66
      0000CC660000CC660000993300000000000099330000CC660000CC660000CC66
      0000CC66000099330000000000000000000000000000929292FF000000000000
      00000000000000000000115B81BF1EA4E7FF1EA4E7FF115B81BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      000000000000000000000000000000000000F2E1D100D9C3B400E1C7AF00EDD4
      C800E0C4BF00F3D9DD00F4D8DB00F5D4D800F2D4D700E4C9C300F2D5C300D5B9
      A3005A699B00B59E9500ECCAA700D7C3B6000000000099330000CC660000CC66
      0000CC660000CC660000CC6600009933000099330000CC660000CC660000CC66
      0000CC660000CC6600009933000000000000552300BF9A3F00FF9A3F00FF5523
      00BF000000000000000000000000000000000000000001010A401717A3FF0101
      0A400000000001010A401717A3FF01010A40481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F3E0D000D9C3B400E0C5AC00F6DE
      C000F4DABC00DDC1B100DFC3C400DFBEBD00D2B19D00D9BDA200DFC3A300B99B
      8800937F8000F9DAB400E4C4A600D7C2B6000000000099330000CC660000CC66
      0000CC660000CC660000993300000000000099330000CC660000CC660000CC66
      0000CC6600009933000000000000000000009A3F00FFEAC83AFFDCA216FF9A3F
      00FF00000000000000000000000000000000000000001717A3FF3232DAFF1717
      A3FF01010A401717A3FF0202B1FF1717A3FF822700FFE3B823FFD18B09FF8227
      00FF000000000000000000000000000000000000000000000000A09281FFA092
      81FFA09281FFA09281FFA09281FFA09281FFF2E0D000DAC3B400DEC2AA00E6CB
      B100EFD6BA00FBE3C500ECD4BB00D6B9A000BC9A8000D1B09400D6B59900C19E
      8500DBB89700FFE7C000DEBFA200D7C2B6000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      000099330000000000000000000000000000552300BF9A3F00FF9A3F00FF5523
      00BF000000000000000000000000000000000000000001010A401717A3FF2B2B
      E6FF1717A3FF1616C3FF1717A3FF01010A40481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFFBA7758FF9D3F12FFF2DECAFFA09281FFF3E1D100DAC4B500DEC2AA00E7CC
      B200DEC3AB00E9D0B600FBE4C700D6B69B00D2B49400A0967100A1987300C2AD
      8B00D9B69A00EDCDAC00E1C3A500D8C3B7000000000099330000CC660000CC66
      00009933000000000000000000000000000099330000CC660000CC6600009933
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000001010A401717
      A3FF2828E4FF1717A3FF01010A40000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFF96360EFFCB7A3DFFAA562BFFA09281FFF6E6D800DAC5B800E0C5AD00F3DA
      BE00EFD4BA00F0D7BB00EDD3B800E2C4A700EBCEAE00A89B7E00AEAD8A00C6B5
      9400EFCDAC00E5C3A300E6C6A700D7C5BA000000000099330000CC6600009933
      00000000000000000000000000000000000099330000CC660000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001010A401717A3FF9D9D
      F7FF1717A3FF5454DEFF1717A3FF01010A400000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFF96360EFF96360EFFAB4C17FFA78168FFF6E6D900E1CCC100CBAF9C00EBD2
      B900EBD2B900EDD3BA00DEC3AC00CDB09A00FFF5DE00D2BCA6009D917B00D2BA
      A300E5C3A400D1AF9500CFB19A00E6D5CA000000000099330000993300000000
      0000000000000000000000000000000000009933000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000001717A3FFCCCCFCFF1717
      A3FF01010A401717A3FF6262D4FF1717A3FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFFF2DECAFFE5C7B2FF96360EFF883B19FFF1E0D300F2E1D500DFCBC000D3BE
      B200D4BFB400D7C1B500D8C3B800C5AB9E00EADACA00E4D3C200CAB49E00F7DF
      C500C7AC9900D1BBB100E1CEC200F5E4D8000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001010A401717A3FF0101
      0A400000000001010A401717A3FF01010A400000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFA092
      81FFA09281FFA09281FFA09281FFA09281FFF1E0D400F1E0D400F9E9DD00FAEB
      DF00F7E8DD00F8E9DD00FDEEE200F2E1D700BDA29500E2CFC000EDD8C300C7AC
      9D00DDCAC100FEF1E600F7E8DB00F0DFD3000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000F060160813708FF8137
      08FF5E4427FF6A6A6AFF6B6B6BFF646464FF797979FF6B6B6BFF626262FF5151
      51FF5E4427FF7C2600FF632602FF2D1001AF000000000000000A000000120000
      0008000000150000001600000016000000160000001600000016000000140000
      0000000000000000000F00000012000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      00000000000000000000000000000000000000000000833808FFB54F0CFFB64F
      0DFF5E4427FF676767FF7C2600FF7C2600FFA3A3A3FFA9A9A9FF8F8F8FFF6B6B
      6BFF5E4427FF7C2600FF7B2D02FF762A03FF2C1302A3723007E0581D00E16953
      44DCC8C9CAE5BCC0C0E49DA0A1E4838383E4707070E4606262E53C3A38E23B10
      00D53A1200C9662703E303000060000000000000000000000000000000000000
      0000040403523A3A33B1585652D4545250D553514DD53C3B34BC0808076B0000
      001B0000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0A0A8CFF6969F3FF4444E7FF0A0A8CFF000000000000
      000000000000000000000000000000000000000000008F3F09FFBA540EFFBB54
      0EFF5E4427FF626262FF7C2600FF7C2600FFB5B5B5FFC0C0C0FFA0A0A0FF7777
      77FF5E4427FF7C2600FF7B2E03FF762A03FFAA4A0AFFBD520DFFB14300FFAB82
      60FFCABFBAFF853634FFBC9482FFDDE5E8FFB4B4B4FFA0A3A5FF6F6B68FF7320
      00FF812800FF953803FF0500006C000000000000000000000000000000174544
      3CB9B8B5C3FF8683D2FF8684DDFF9896E3FF8987DBFF7B77C8FF9A95A5FF4E4D
      42CC0000004100000000000000000000000000000000787878FF000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      0000000000000000000000000000000000000000000092420BFFBF5910FFC05A
      10FF5E4427FF5C5C5CFF7C2600FF7C2600FFC5C5C5FFDADADAFFB7B7B7FF8585
      85FF5E4427FF7C2600FF7D3003FF772B03FFA74B0BFFBC560EFFB94B00FFA87E
      5CFFA1928DFF590000FFB58168FFF4FCFEFFC5C5C5FFACAFB0FF7D7A77FF6C1E
      00FF782600FF933804FF04000069000000000000000000000012858579DAA6A3
      DEFF3837E3FF5B5BF6FF8C8DFAFFA4A5FBFF9393FCFF6465FAFF3C3BE6FF7E7A
      C2FF7F7B6BEA00000040000000000000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      0000000000000000000000000000000000000000000096460CFFC46013FFC562
      14FF5E4427FF575757FF575757FF575757FFC9C9C9FFF3F3F3FFD0D0D0FF9595
      95FF5E4427FF7C2600FF7E3103FF792C04FFAB500CFFC15A0FFFC05200FF9B73
      50FF8E7E7AFF5C0000FFB5836CFFFFFFFFFFE0E2E3FFC4C8CBFF8C8A88FF6B1C
      00FF792500FF943B05FF04000069000000000000000044443CB2ACAAE4FF1B1A
      DDFF4142F1FF5656EDFF7272F3FF7C7CF3FF7575F3FF5A5AEDFF4848F3FF1D1E
      E7FF8682C3FF555247D20000001A0000000000000000787878FF787878FF7878
      78FF787878FF787878FF177516FF6CD76CFF45BD45FF177516FF000000000000
      00000000000000000000000000000000000000000000994E14FFCA6C21FFCB6E
      24FF91541DFF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E44
      27FF683510FF752C02FF883806FF7B2D04FFB05611FFC76416FFCA600CFF8E65
      3FFF7A7778FF683D3CFFB09C92FFF6FAFBFFEDF0F1FFD0D6D9FF949391FF6418
      00FF722300FF973D06FF040000690000000012120F6FC0BEC7FF2020C9FF1D1D
      D0FF5252CDFF7777C0FF4B4BE5FF5353F6FF4C4CE6FF7676BFFF5352CCFF2323
      D5FF1E1ECBFFA9A4B0FF0808066C0000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      000000000000000000000000000000000000000000009D571EFFBA682AFFC394
      6DFFC0916BFFBE8E68FFBB8B65FFB98760FFB5825AFFB48058FFB37E57FFB17D
      57FFB07C56FFAF7B56FFA2440EFF7C2E04FFB66321FFCC7024FFCB6B1AFFAE5C
      15FF9B571AFFA76424FFA75C1CFFA35311FFA35211FF9D4D0EFF954307FF8C34
      00FF903600FFAC4408FF04000069000000009D9B83E07776C0FF0000B5FF1111
      B8FF6C6CB5FFDBDBB1FF8383BDFF2C2CD9FF8080BEFFDADAB0FF6F6FB5FF1414
      BCFF0000B5FF7370C2FF43423ABF0000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      00000000000000000000000000000000000000000000A0612BFFC38551FFEBEB
      EBFFE7E7E7FFE2E2E2FFDDDDDDFFD9D9D9FFD4D4D4FFD0D0D0FFCBCBCBFFCACA
      CAFFCACACAFFCACACAFFA85B29FF7D3004FFBA6824FFC57C44FFCAA488FFCC9E
      7CFFCC9B76FFC99873FFC4926DFFBF8D67FFBD8B66FFBD8A65FFBE8B67FFC093
      73FFBB8059FFAE4204FF0400006900000000CFCCB4FF413FB5FF000091FF0A0A
      A4FF1111B2FF7C7BB4FFC3C3B3FFA4A4B4FFC1C1B3FF7B7BB4FF1212B3FF0C0C
      A8FF000092FF3F3DBAFF626058D70000000000000000787878FF787878FF7878
      78FF787878FF787878FF0E8EE0FF3CFFFFFF12FFFFFF0E8EE0FF000000000000
      00000000000000000000000000000000000000000000A46936FFC18758FFDCDC
      DCFFD8D8D8FFD4D4D4FFD1D1D1FFCECECEFFCACACAFFC7C7C7FFC3C3C3FFBFBF
      BFFFBCBCBCFFBABABAFFA55926FF7D3105FFBB6A25FFC48D65FFE7F6FFFFE0E9
      EFFFDBE4EBFFD7E0E6FFD2DBE2FFCED7DEFFCAD3DAFFC5CFD6FFC3CCD3FFC5D5
      DFFFBCB5B1FFA83D00FF0400006900000000BFBAABFF5857BEFF2827ACFF0E0E
      A4FF0000A5FF0101A2FFBCBCC7FFECECD1FFBDBDC8FF0302A3FF0000A7FF1010
      A6FF2828ADFF5E5DC6FF605F5BD60000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      00000000000000000000000000000000000000000000A87141FFCC9568FFFEFE
      FEFFFBFBFBFFF7F7F7FFF2F2F2FFEEEEEEFFE9E9E9FFE5E5E5FFE0E0E0FFDADA
      DAFFD7D7D7FFD1D1D1FFAA5D2BFF7E3105FFBF783AFFC8946CFFEEF1F4FFE8E8
      E8FFE3E3E3FFDFDFDFFFDADADAFFD7D7D7FFD2D2D2FFCECECEFFCACACAFFC8CE
      D1FFBCADA4FFA83E00FF0400006900000000A4A095FF8C8AC6FF6F6FE4FF2D2D
      C7FF1A1ABAFF9999D8FFFFFFFAFFE4E4EDFFFFFFFBFF9F9FD9FF2020BDFF3333
      C8FF7071E2FFA19FDBFF5F5D5AD700000000481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000000000000000000000114
      0294043D08FF01140294000000000000000000000000A9764AFFC79269FFE1E1
      E1FFE1E1E1FFE1E1E1FFE0E0E0FFDDDDDDFFD9D9D9FFD7D7D7FFD3D3D3FFCFCF
      CFFFCCCCCCFFC9C9C9FFA95C29FF7E3105FFC3854BFFCB9A75FFF1F2F4FFEFEF
      EFFFEDEDEDFFE9E9E9FFE4E4E4FFE0E0E0FFDCDCDCFFD8D8D8FFD3D3D3FFD2D8
      DBFFC4B4ACFFA93F00FF0400006900000000747067DB8481B1FF8181E3FF3636
      C1FF8F8FD4FFFFFFFFFFA9A9DFFF1A1AB8FFADADE4FFFFFFFFFF9696D6FF3D3D
      C2FF7C7CDEFFB0ADD4FF3E3D3AB400000000822700FFE3B823FFD18B09FF8227
      00FF00000000000000000000000000000000000000000000000000000000043D
      08FF10A916FF043D08FF000000000000000000000000AA784EFFCF9C73FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFCFCFCFFF8F8F8FFF4F4F4FFEFEF
      EFFFEBEBEBFFE6E6E6FFB0632EFF803205FFC68C56FFCC9E7AFFF0F2F4FFF0F0
      F0FFF0F0F0FFEFEFEFFFEEEEEEFFEAEAEAFFE6E6E6FFE1E1E1FFDDDDDDFFDCE2
      E5FFCCBCB4FFA93F00FF0400006900000000141413648D8896FF8E8ED7FF7474
      DAFF6C6CC7FF9797D4FF3B3CC1FF3B3BCAFF3F3EC3FF9A9AD6FF7272C9FF7575
      D9FF8989D6FFCAC8D0FF0303035200000000481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000001140294043D08FF043D
      08FF42BF43FF043D08FF043D08FF0114029400000000AA774BFFC7946AFFE1E1
      E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFDEDE
      DEFFDCDCDCFFD8D8D8FFAC602BFF7E3205FFCB915AFFCFA07CFFEFF1F3FFEFEF
      EFFFEFEFEFFFEFEFEFFFF0F0F0FFF0F0F0FFEEEEEEFFEBEBEBFFE7E7E7FFE6EC
      EFFFD4C4BCFFAB3F00FF0400006900000000000000003A3937A38E8AACFFA2A2
      E7FF8686DCFF5C5CC8FF6766D1FF6969D0FF6868D0FF5F5FC9FF8787DCFF8C8C
      D7FFB9B7DAFF4B4A46C000000002000000000000000000000000000000000000
      00000000000000000000000000000000000000000000043D08FF96E998FF8FE3
      90FF65D764FF45C747FF099D0EFF043D08FF00000000AA774BFFBA8258FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFE
      FEFFFEFEFEFFFAFAFAFFA95E2EFF742B03FFA46635F7BE8D6AFCFBFEFAFFF8F9
      F4FFF8F9F4FFF8F9F4FFF8F9F4FFF8F9F4FFF8F9F4FFF8F9F5FFF7F8F4FFF9FD
      FAFFE1D2C6FE9E3900FD030000660000000000000000000000095D5C58CD908B
      A9FFA2A1D9FFA7A7E5FFA1A1E3FF9D9EE1FFA0A1E2FFA4A4E2FF9C9BD4FFB0AD
      CDFF7D7B77DA0000001800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001140294043D08FF043D
      08FF88E089FF043D08FF043D08FF0114029400000000AA774BFFBA8258FF2814
      77FF281477FF281477FF281477FF281477FF281477FF281477FF281477FF2814
      77FF281477FF281477FFA95E2EFF742B03FF361001C4734938E9D3D2E6FFD2CE
      DFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEE0FFD4D2
      E6FFBEADB5FB4F1800DC020000630000000000000000000000000000000D3736
      359E837E8BF68F8CAEFF918FBAFF9392C1FF9390BCFF9694B5FFA19EA8F83A39
      36AD000000150000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000043D
      08FF8AE18CFF043D08FF00000000000000000000000043230CC1723323FF320C
      57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C
      57FF320C57FF320C57FF692412FF3D1601C1B57023FF7D433CFF1E0D87FF2913
      82FF291382FF291382FF291382FF291382FF291382FF291382FF291382FF2311
      89FF39186CFF973A00FE03000056000000000000000000000000000000000000
      0000161614676B6861D499948FFFA09A96FFA3A09BFF7B7A73D9121210720000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000114
      0294043D08FF0114029400000000000000000000000000000000000000000000
      0000000000001C9620E250DD57FF4FD754FF4FD152FF48CA4AFF3EC13DFF35B9
      33FF31B22EFF15AC0EFC02020225000000000000000000000000000000000000
      000000000000000000000000000000000000000000090000000A0000000A0000
      000A0000000A0000000800000009000000010000000000000000000000000000
      000000000000000000003F332800005F93000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000020000
      0008000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000179421E1EAFBEAFFFFF8FFFFFFFDF9FFF5F4ECFFEAE9E0FFE0E2
      D5FFDBDACFFFA7D49CFF071B066E000000000000000000000000000000000000
      00000000000000000000000000150503005B070604600202035F0303035F0808
      085F0605025F0503006300000026000000000000000000000000000000000000
      00000000000000000000005F9300E7FAFF00003A5D00003A5D00000000000000
      0000000000000000000000000000000000000000000000000003002600A60009
      0094000000420000000800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000201012708030066090300720802
      006D0801006E2DAB35EF92F8A5FFC7FEE2FF95FCA8FF85F68EFF68EF6CFF43E1
      42FF43D63CFF44CF37FF1A5E02D7000000250201012708030066090300720902
      007108020071060100642B1801AAE2AB49FFDFC59CF5797679F69A918AF6E2DC
      DCF6CFAE78F5D49E42FE201200A5000000340000000000000000000000000000
      00000000000000000000005F9300E7FAFF00D0F9FF0052CBFF00A13400000000
      0000000000000000000000000000000000000000000000000000008100E30098
      00FF003C00D80000007000000021000000000000000000000000000000000000
      00000000000000000000000000000000000031211189FDD4B1FFFFEBDBFFFFE2
      D3FFF3D7BEFF72E182FF6CEC85FFBDFCDBFF8DFBAEFF67FF82FF34F946FF02EA
      09FF00CC00FF03C100FF52AB11FF0500005C31211189FDD4B1FFFFEBDBFFFDE2
      D1FFFBDBCAFFFDDFD5FFE3BC8EFFDBAC5EFFECD3B2FFBEBBC2FFC3BAB8FFE9E5
      E9FFE3C499FFDBB369FFC58B5AFF040000695D534A003F3328003E3327003E33
      27003E332700B0ABA60000000000005F930052CBFF00E2943100FF9D0000A134
      000000000000B0ABA6003F3328005F544A000000000000000000007500D700B7
      00FF00AE00FF007200F4001E00BC0000005D0000000D00000000000000000000
      00000000000000000000000000000000000027190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFF8F5EFFF85E897FF72F094FF8DEC95FFBAFACEFF94FAB0FF67F77EFF4DF8
      63FF34F74AFF1FE127FF1BCE0EFF000D007A27190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFFFFAFEFFFFFAFFFFE7C8A8FFDAAC60FFDDB170FFEDD4B3FFEBD1AEFFE3C9
      A8FFDEAF69FFDCB974FFBC9370FF020000627369600000000000000000000000
      0000000000000000000000000000005F9300F4D7A500FFFAD100E2943100FF9D
      0000A13400000000000000000000736960000000000000000000007700D800B7
      00FF00B600FF00B600FF00AA00FF005100E6000500900000002C000000000000
      000000000000000000000000000000000000271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFF3ECE2FF80E892FF9EF8BEFF88E287FFB6F1BBFFA6EDA9FFA5EFA5FF81E2
      83FF4AED5FFF4AFF6BFF32E63EFF0C9B03F1271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFFFEFEFFFFFFDFFFFE3CFACFFDDB165FFE4D5BAFFE6DBC8FFE1D5C0FFE7DD
      CDFFE6CFAEFFDDB86FFFBD926DFF020000627368600000000000F1EAE300F1EA
      E400F1EAE400F1EAE400F9F6F40000000000D56B0300F4D7A500FFFAD100E294
      3100FF9D0000A134000000000000C5C1BE000000000000000000007700D800B6
      00FF00B100FF00B400FF00B600FF00B700FF008B00FE001F00BE0000006C0000
      002000000000000000000000000000000000281A0D7EEEE4D1FFF9FFFFFFFFF6
      F8FFF3EADFFF7DE993FFB1FDDBFFB3EABBFFE5EEE1FFFFFBFDFFFAFFEFFFE9F7
      DFFFA8EAA3FF77DC79FF98B471FF081B009D281A0D7EEEE4D1FFF9FFFFFFFFF6
      F6FFFFEDEDFFFFFFFFFFE6D2AFFFD2A662FFC8C2BEFFCAC7C6FFC3BFBEFFD1D0
      D3FFD4C8BBFFD3B16EFFBF936EFF02000062776D630000000000FFFEFB00FFFF
      FB00FFFFFB00FFFFFB00FFFFFB00FFFFFE0000000000D0690600F4D7A500FFFA
      D100E2943100FF9D0000A1340000000000000000000000000000007700D800B6
      00FF00B200FF00B200FF00B200FF00B500FF00B700FF00AA00FF007500F7000D
      00A4000000430000000E00000000000000002A1C0F7ED9D6C6FFE9E2EAFFFFE7
      EAFFF8E9E4FF70DF7AFF92F3ADFF6EEE8AFF85DC88FFCFE8C7FFDEF9D6FFEEFD
      E5FFD9F0CEFFBFE6BFFFF1BEB9FF010000502A1C0F7ED9D6C6FFE9E2EAFFFFE7
      E6FFFFECECFFFFF8FCFFE9CFA8FFD2AC74FFD4CDCAFFC7C6C7FFDFD9D6FFCECC
      D0FFDAD1C9FFD5B87EFFC6986FFF020000617C71660000000000FFF8EA00FFF8
      EC00FFF8EC00FFF8EC00FFF8EC00FFF9EC00FBF9F80000000000CC690800F4D7
      A500FFFAD100E29431000024F6000015C8000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B200FF00B400FF00B500FF00B000FF009B
      00FF004B00E10008009300000020000000002A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F1FFF3E9E0FFEFDFD0FFEDD8C9FFF9F0EEFFECF0E8FFC1DFB7FFC4EB
      BCFFB4DDA9FFF9FEFCFFF1CAC0FF0100005D2A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F0FFFFF2F7FFD7B79CFFD5AC6EFFE5CBA0FFE5CBA1FFE1C59BFFE4CA
      A0FFE5CB9EFFD4BB81FFC89C7DFF0200005D80756B0000000000FFF2DE00FFF3
      E000FFF3E000FFF3E000FFF3E000FFF3DF00F7F4F100EDE9E50000000000CD6C
      0C00F4D7A500000000000024F6000015C8000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B300FF00B200FF00B300FF00B500FF00B0
      00FF00B300FF004C00DB00000020000000002A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFBFFFFFFF1F6FFFFE6EBFFFFF9FBFFFFE7EAFFFFEAEEFFD1DE
      C2FFE8E1D3FFFFFFFFFFE9C4B6FF0200005D2A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFBFAFFFAEDEEFFF7DAD5FFF8ECE1FFF8DACFFFF8DCD2FFF8DB
      D0FFF9DBD1FFF7F5F1FFE7C3B7FF0200005C84786E0000000000FFEDD000FFEE
      D300FFEED300FFEED300FFEED300FFEED100F7F5F300FAF8F400FDFDFB000000
      0000CD6C0C000024F600FFCCFF00153ACF000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B300FF00B500FF00B600FF00B200FF008A
      00FA002600A5000100320000000000000000291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF1F1FFFEEAEAFFFEFAFAFFFEE4E3FFFFE8E8FFFFE9
      EEFFFFE6EAFFFFFFFFFFE8C3B5FF0200005D291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF3F3FFFFEDF0FFFFFDFFFFFFE6E9FFFFEBEDFFFFEA
      EDFFFFE8EAFFFFFFFFFFE9C4B7FF0200005C897D720000000000FFE7C300FFE9
      C700FFE9C700FFE9C700FFE9C700FFE8C400F9F8F800DFD6CE00E0D7CF00F2EF
      EB00000000000B32CD000013C500000000000000000000000000007700D800B6
      00FF00B100FF00B300FF00B500FF00B600FF00B100FF008900FA002500A40002
      0036000000000000000000000000000000002A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D2A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D8D81750000000000FFE0B000FFE2
      B400FFE4B700FFECBF00FFF0C300FFEFC000000000000000000000000000FEFB
      FA00FEFDFC000000000000000000D0CBC6000000000000000000007700D800B6
      00FF00B400FF00B600FF00B300FF008C00FB002500A400020035000000000000
      000000000000000000000000000000000000291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D9185780000000000FAF9F900FAFA
      FB0000000000483E360032281F0032271E0032261B0033271B00473C32000000
      0000FBF9F700FBF8F60000000000918578000000000000000000007400D700B7
      00FF00B200FF008900FA002500A5000200360000000000000000000000000000
      0000000000000000000000000000000000002E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF020000612E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF02000061978B7E0000000000000000000000
      0000000000006A615700FFFFFC00FEFAF400FEFAF400FFFFFC006A6157000000
      0000000000000000000000000000978B7E000000000000000000008400E8008F
      00FD002400A30002003500000000000000000000000000000000000000000000
      0000000000000000000000000000000000001C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003C1C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003CA09487009B8F82009A8D80009A8D
      80009D91830079706600FFE4E100FAD9D600FAD9D600FFE4E100797066009D91
      83009A8D80009A8D80009B8F8200A09487000000000000000005001A007B0003
      0040000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000000000000000000000000
      000000000000968B7E0000000000000000000000000000000000968B7E000000
      0000000000000000000000000000000000000000000000000001000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00100991B4FF0991B4FF000405300000000000000000001117600991B4FF0991
      B4FF000000100000000000000000000000000000000000000000000000060000
      00230000002100000020000000200000002000000020000000200000001F0000
      00240000001D0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000540000006B0000
      0069000000640000000B00000000000000000000000000000000000000000991
      B4FF57CCDEFF5BD7E6FF0991B4FF0991B4FF0991B4FF0C99BAFF20C9DEFF14B8
      D1FF0991B4FF00000000000000000000000000000000000000000000001FB0B0
      B0F1CCCCCCF9C3C3C3F8C3C3C3F8C7C7C7F8C1C1C1F8C5C5C5F8C4C4C4F8DCDC
      DCFB404040B10000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000011000D00C8098509FF07AD05FF03B1
      02FF0C9B0BFF003700EB0202024C000000000000000000000000000000000991
      B4FF80E3EFFF6EE0EDFF58D5E6FF51D8E7FF3ECEE1FF35D0E3FF28CCE1FF1DC7
      DEFF0991B4FF00000000000000000000000009090969383838B23B3B3BB6BCBC
      BCF6FCFCFCFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF4F4F4FFF5F5F5FFF7F7
      F7FF727272DA393939B23E3E3EB8020202380201012708030066090300720902
      0071080200710801007108020071080200710802007108020071080200710802
      007108020071080100710A030071000000360201012708030066090300720902
      0071080200710902007007010065051300BA09B215FF10C919FF41D549FF57DA
      5DFF16C41EFF11C71AFF004C01F60000003C0000000000000000000000000991
      B4FF88E5F0FF71DCE9FF4EC6DAFF58CADDFF51C9DCFF32BFD5FF2DC9DEFF20C1
      D8FF0991B4FF000000000000000000000000606060C3E7E7E7FFE4E4E4FF4848
      48FF3D3D3DFF414141FF414141FF404040FF404040FF3F3F3FFF424242FF2C2C
      2CFF777777FFF5F5F5FFF2F2F2FF1515158031211189FDD4B1FFFFEBDBFFFDE2
      D1FFFBDBCAFFFCDACAFFFCDBCBFFFCDBCAFFFCDACAFFFCDBCBFFFCDCCBFFFCDB
      CBFFFCDBCBFFFEE6D8FFF2B799FF0300006331211189FDD4B1FFFFEBDBFFFDE2
      D1FFFBDBCAFFFFE0D2FFE5C0B3FF188F1DFF0FCB2AFF04C31FFFB9EFC2FFFFFF
      FFFF18CB32FF14C72DFF0FB524FF000A0187000C0F500991B4FF0991B4FF4FC6
      DAFF6CD5E5FF74D5E3FF0991B4FF0991B4FF0991B4FF0991B4FF45C9DDFF27C2
      D9FF12A7C5FF0991B4FF0991B4FF00020220585858BBE0E0E0FFE3E3E3FFA2A2
      A1FF7A7D81FF818489FF818487FF818487FF828589FF82868AFF80878BFF7E82
      84FFC3C3C2FFE2E2E2FFEAEAEAFF1313137727190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFFFFAFEFFFFF3F7FFFFEBEFFFFFEDF1FFFFEDF1FFFFE9EDFFFFE9EDFFFFE8
      ECFFFFE8ECFFFFFFFFFFEBCCC1FF0200005D27190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFFFFAFEFFFFF7FFFFE4DCD6FF02A929FF33D456FFF2FFF3FFFEFEFEFFFFFF
      FFFFF9FFF9FF71E28AFF03C12DFF0019057E0991B4FF35BFD7FF45C7DCFF69DE
      EBFF62CCDEFF0991B4FF919191FF919191FF919191FF919191FF0991B4FF3FC2
      D8FF2CCCE1FF17B5D0FF10B0CBFF0991B4FF5C5C5CBBEEEEEEFFEBEBEBFFFAFC
      FCFFFFFAF2FFFAF0E3FFFBF3E9FFFBF3E8FFFBF1E5FFFBEDE0FFFBE8DBFFFFFB
      F7FFF4F5F6FFE9E9E9FFFAFAFAFF13131377271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFFFEFEFFFFFF6F6FFFFF2F2FFFFF3F3FFFEF7F7FFFDE6E6FFFDE9E9FFFEEB
      EBFFFFE6E6FFFFFFFFFFEBC7B9FF0200005D271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFFFEFEFFFFFFCFFFFE2D9D7FF029F2FFF1FD557FF84E2A2FFE6F8EBFFFFFF
      FFFF96E6B0FF44D971FF02C53DFF0010037E0991B4FF46D5E6FF53D8E9FF48C9
      DCFF0991B4FF919191FFFEFEFEFFFCFCFCFFF4F4F4FFDDDDDDFF919191FF0991
      B4FF2CC5DAFF29CCE1FF1DC7DEFF0991B4FF616161BDFEFEFEFFFEFFFFFFFEFC
      FBFFDA9B64FFC98846FFCB965DFFCB965CFFCB8F51FFCB7E40FFC85D1BFFE7A6
      86FFFFFFFFFFFEFEFFFFFFFFFFFF1414147A281A0D7EEEE4D1FFF9FFFFFFFFF6
      F6FFFFEDEDFFFFF9F9FFFFF2F2FFFEDADAFFFEE9E9FFFEE6E6FFFEEDEDFFFEF1
      F1FFFFE3E3FFFFFFFFFFEAC6B8FF0200005D281A0D7EEEE4D1FFF9FFFFFFFFF6
      F6FFFFEDEDFFFFFCFCFFFCEBF3FF51955FFF00C940FF00D140FF8BE8ADFFCEF5
      DCFF00CF4AFF00DC50FF1D9D39FF030000630991B4FF2BBCD4FF49D5E6FF39C0
      D7FF0991B4FF919191FFF7F7F7FFF7F7F7FFF0F0F0FFDDDDDDFF919191FF0991
      B4FF2ABCD4FF33CFE2FF14ACC9FF0991B4FF636363BFFFFFFFFFFFFFFFFFFFF6
      F2FFDA9260FFCB8B50FFD49558FFD79B60FFD59155FFD37E44FFD5662CFFE89F
      7CFFFFFFFFFFFFFFFFFFFFFFFFFF0D0D0D6E2A1C0F7ED9D6C6FFE9E2EAFFFFE7
      E6FFFFECECFFFFF3F3FFFFEAEAFFFEDADAFFFDEAEAFFFDEFEFFFFEE9E9FFFFED
      EDFFFFEEEEFFFFFFFFFFE8C4B6FF0200005D2A1C0F7ED9D6C6FFE9E2EAFFFFE7
      E6FFFFECECFFFFF3F3FFFFEFF1FFECCDD2FF42AB69FF00C44BFF00D356FF00D4
      56FF00CE51FF20C86EFFB9A88EFF0400005B000000000991B4FF2DBCD4FF33BF
      D5FF0991B4FF919191FFE1E1E1FFE9E9E9FFE2E2E2FFCFCFCFFF919191FF0991
      B4FF32BDD5FF1EABC7FF0991B4FF000000000D0D0D67DBDBDBF8FFFFFFFFFFF5
      EFFFDFA184FFD8A78DFFE3AE8BFFE1AB85FFE1A681FFE3A17DFFE69A76FFEBB1
      96FFFFFFFFFFFFFFFFFFCBCBCBF4000000172A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F0FFFFEBEBFFFFE1E1FFFFDCDCFFFFF1F1FFFEF9F9FFFEEEEEFFFFF6
      F6FFFFFAFAFFFFFFFFFFECC7B9FF0100005D2A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F0FFFFEBEBFFFFE1E0FFFFE5E8FFFEE5EDFF92B29DFF5DB47EFF5BBD
      82FF75AF8CFFE7E9ECFFFFCFC7FF0100005D00000000000202200991B4FF43D4
      E6FF0991B4FF919191FFAAAAAAFFC9C9C9FFC5C5C5FFA6A6A6FF919191FF0991
      B4FF55D8E9FF0991B4FF000000000000000000000000040404332C2D2E8CDED3
      CDFDF1C0ABFFF7CDBBFFF4CCBBFFF5CDBCFFF4CBB9FFF3C6B3FFF0BFAAFFEDC4
      B0FF96989ADD1414146A0202022A000000002A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFAFAFFFFF1F1FFFEE5E5FFFEF8F8FFFFE5E5FFFFE8E8FFFFE7
      E7FFFFE5E5FFFFFFFFFFE9C5B7FF0200005D2A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFAFAFFFFF1F1FFFEE5E4FFFFFDFEFFFFECF3FFFFE8F1FFFFE8
      F1FFFFEAF2FFFFFFFFFFE8C4B6FF0200005D00000000000C0F500991B4FF3AD1
      E3FF34C4D9FF0991B4FF919191FF919191FF919191FF919191FF0991B4FF54CB
      DEFF61DCEAFF0991B4FF0004053000000000000000000000000000000011BCBD
      BDF7F7F2EFFFF9EDE7FFF7ECE7FFF2EAE7FFECE4E1FFE5DDD9FFDFD8D5FFE4E2
      E1FF4A4A4AA9000000000000000000000000291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF1F1FFFEEAEAFFFEFAFAFFFEE4E4FFFFE8E8FFFFE7
      E7FFFFE5E5FFFFFFFFFFE8C3B5FF0200005D291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF1F1FFFEEAEAFFFEFAFAFFFFE4E4FFFFE9EAFFFFE9
      E9FFFFE6E6FFFFFFFFFFE8C3B5FF0200005D000000000991B4FF27CBE1FF32CF
      E2FF3DD3E5FF37C4D9FF0991B4FF0991B4FF0991B4FF0991B4FF71D7E6FF7CE2
      EEFF6BDEEBFF5CDAEAFF0991B4FF00000000000000000000000002020224CBCB
      CCF8FFFFFFFFFFFFFFFFFFFFFFFFFAFDFEFFF2F5F7FFECEFF1FFE5E8EAFFE7E9
      EAFF535353AF0000000000000000000000002A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D2A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D000000000991B4FF1DC0D8FF23C2
      D9FF0991B4FF40D3E5FF4CD7E7FF58D9E9FF66DDEBFF73E1EDFF76DDEAFF0991
      B4FF77E1EEFF5FD7E6FF0991B4FF00000000000000000000000002020227DFDF
      DFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFDFDFFF6F6F6FFEFEFEFFFE9E9E9FFE9E9
      E9FF535353B0000000000000000000000000291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D00000000000000100991B4FF0991
      B4FF000C0F500991B4FF0991B4FF4FD7E7FF5BDAEAFF0991B4FF0991B4FF000C
      0F500991B4FF0991B4FF000000100000000000000000000000000000000A2626
      268DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8F8F8FFF2F2F2FFEDED
      EDFF535353B00000000000000000000000002E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF020000612E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF020000610000000000000000000000000000
      000000000000000000000991B4FF46D4E6FF52D8E7FF0991B4FF000000000000
      0000000000000000000000000000000000000000000000000000000000000303
      032ECECECEF1D4D4D4F1D2D2D2F0D2D2D2F0D2D2D2F0D0D0D0F0CBCBCBEFDDDD
      DDF8555555B00000000000000000000000001C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003C1C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003C0000000000000000000000000000
      00000000000000000000034052AF0991B4FF0991B4FF00181F70000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      001211111159101010570F0F0F550F0F0F550F0F0F550F0F0F550E0E0E521C1C
      1C781818186F0000000000000000000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A0504032900000006000000060000000300000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000D0705044E2219197D0000
      0C6D2117308E30223D9A04001069572D25B50D0707493C2424911D16165C2721
      2165645454A019151555221C1966564644A8231275D734215FC8503873D72E24
      339230272272594A4C971812125774403ED00D0707493C2424911D16165C2721
      2165645454A019151555221C1966564644A8231275D734215FC8503873D72E24
      339230272272594A4C971812125774403ED00D0707493C2424911D16165C2721
      2165645454A019151555221C1966574645A8221274D534215EC6513875D52920
      2E8C2E25216F564B4D9418121255743F3ED00D0707493C2424911D16165C2721
      2165645454A019141554231C1A67554444A81D0E6ED5311E58C64E3771D6271F
      2D8F2C241F70574749951711115675403ED01B111161412828950504042B0A08
      083D483939880303022C1A151D7E4E3578D70C061C891A0E37A85735A1EF0201
      012C1C16165E2C25246B030303246B3738C91B111161412828950504042B0A08
      083D483939880303022C1A151D7E4E3578D70C061C891A0E37A85735A1EF0201
      012C1C16165E2C25246B030303246B3738C91B111161412828950504042B0A08
      083D483939880303022C1A151D7F4E3477D5100A1F881E1238A6543494F00605
      054E1E1817672720206F020202246D3A3AC91B111161412828950504042B0A08
      083D483939880303022B1A151C7E432C6CDA09031E9C140830B941267DEF0503
      03571D161682251E1F8A05030343613435CE01000019251616720101011B0303
      032B362B287B0101012F1D1140AD512DB1F00C090F5E17111970503673C60000
      0010120E0E4E231D1D6101000014663434C301000019251616720101011B0303
      032B362B287B0101012F1D1140AD512DB1F00C090F5E17111970513773C60000
      0009100C0C46231D1D6101000014663434C301000019251616720101011B0303
      032B362B287B0101012F1F1243AB432787EC00000EBA0A0812BB271B32F70000
      00AC0F0C0CA3131010B30000005D5C3232C101000019251616720101011B0303
      032B362B287B0101012E13073EB5422558F5322419C6383339CA362A4AEF1E1E
      1EA13A352FB83F2F14C3090700824A2629C726161673513333A7211818653127
      29805C455FC438293DA73D2C4BB2604D479F1C1716553B31307B564545961D19
      18574C3D3D8B574646961F17175D794242D626161673513333A7211818653127
      29805C455FC438293DA73D2C4BB2604D479F1B1616543028276F473B3887211A
      1C6656434AA25044438F1F17175D794242D726161673513333A7211818653127
      29805C455FC438293DA73B2A46A67B6856CE80765CF6898988F7807F7BF18986
      86F4929090FC7D7E7EFF231C1CB96E3C3CCD26161673513333A7211818653127
      29805C455FC4382A3DA32D1E3DB4B68F33F2FFD67EFFE0DBD2FF7D7C76FFFCF7
      F7FFFCECDAFFF6C467FF916D34EB4D272ED4020101212113136C000000050704
      106D483268C500002098080609561B15145500000000040303241C1716560000
      000008070733120F0F48000000005D2E2EBA020101212113136C000000050704
      106D483268C5000020980806095619151352000000000C09116B292232940000
      208A1A2473D1120F0F51000000005E2E2FBB020101212113136C000000050704
      106D483268C500002098050405425B4C46AE8C724ADE928673E3929397E87D7F
      80D9929396E4939393F304040461452323AA020101212113136C000000050704
      106D483268C50000219304030458AC873EEBFAC978FFEDE4DAFFC3BEBDFFEEEA
      EAFFF3E3CBFFF8C46CFF604920C92E1418B6130B0B543E28238F382442A64535
      46A66E536EC8392370C844353D9865514DA1221C1C5E44363684645050A01F19
      195A4E3E3E8D5A49499821181860794242D7130B0B543E28238F382442A64535
      46A66E536EC8392370C844353D985F514C9C251D1E6C4D4C7FE66F7FDFF6203B
      C1E01D48D1EC31386BCF261D1D6D7D4443D4130B0B543E28238F382442A64535
      46A66E536EC8392370C83D2F368C87736DD19A805BEDA27E51EF9D9281F28C8A
      89E99F917FEF8D9095F82B2121A7733F3ECE130B0B543E28238F382442A64535
      46A66E536EC83C2471C5382B3299B79049F4ECB65AFFF1CE95FFFCE0B2FFF3D8
      ABFFEBC585FFEEB85BFF836536E150292DD6110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B03030229342C2C740000000F0D0B0B3F2C23236B0000
      000E1410104C211B1B5E00000010653333C2110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B030302292E29286D000001193B3D65C87787C3DF0A19
      8FBF1328ABD11038C7EA0B0A1971593028AB110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B01000017786666C08D7D61E3987852E79A7950EB8472
      57DD9D7D53E78E8370F40A080876502A2AB4110B0B4E291A16790A05116F100B
      1571392E2E7C080412670201012CC0954CF8F3D294FFEDE9DBFFEBE4D1FFEAE3
      D2FFF1EBDAFFF6CD83FF664E22CF36191DBF0201012025161578160C2B981813
      166B463836860504042F100D0D4C463A3A860504042B1B1616583E31317E0404
      0429231D1D63312828730504042C6C3838C90201012025161578160C2B981813
      166B463836860504042F100D0D4C3E36357E060506383D4070D96370CEED0101
      95CA0C0EBBDB1E2388DE0F0B0E57673833BD0201012025161578160C2B981813
      166B463836860504042F0A08083C7E6A69C7958C85E7A4948AEAA08978EE8B75
      60E29F8771EB96836EF6120E0F895B3031BD0201012025161578160C2B981813
      166B463836860403032C0D0A0950B78E4AF9D7BE93FFC7C8CCFFCDCAC6FFCBC8
      C5FFD9D8D9FFDDBC84FF705629D6401E23C82214146C4C2F30A52F1C52B81C17
      15646250519E1713134D2C25256B5D4B4B9A1411114B332A2A74544444931310
      10493D32327E4A3D3D8A140F0F4D753F3FD22214146C4C2F30A52F1C52B81C17
      15646250519E1713134D2C25256B5C4B4A991512114D28222B8B3F3850BB191A
      5ACD181495EF3D33368A110D0C45774040D42214146C4C2F30A52F1C52B81C17
      15646250519E1713134D211D1D5D8A6968D5AE9794F6BFABA2F6BCA391F7A986
      5BF2B58C49F5AD8B3DFF211A189F683A3CC72214146C4C2F30A52F1C52B81C17
      15646250519E1513134B251D1D6CBE9953FFEED6ADFFDDDBD8FFE5DFD5FFE8E2
      D8FFE4E2DDFFECCF9AFF876A3AE14C252ACA2517156E41252DA0060014750000
      000F2F242471000000000201011E281E1E6A000000000504042D211919610000
      00000B08083C1611115100000000652E2EC62517156E41252DA0060014750000
      000F2F242471000000000201011E291F1F6B0000000004030326221B195F0A09
      0A48221A238C120E0D4900000000652E2EC62517156E41252DA0060014750000
      000F2F242471000000000000000E5C4241AF412C29AA5D443EBC75584CCE412E
      21A1684E36C1735739D40201013654292AB82517156E41252DA0060014750000
      000F2F242471000000000101011D775A36DE6A5633C8806B4BD6947D58E36252
      35C385714EDA977C4FE422180A91441F22B604030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A331E1E89190D
      0D642C18187F301C1C851A0D0D67412020A504030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A341E1E88140A
      0A5927171575311D1D851A0D0D67412020A504030228371F2696200F12782112
      126E3821218D1C0E0E6826141477331F1F87140A0A59211212702E1B1B811309
      0A58251516762B191A7C180C0C61432020A604030228371F2696200F12782112
      126E3821218D1C0E0E6825151576301C1D8A13090964201110782C1818871208
      08612312127C29171784150A0B65442121A60000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0101
      011A0000000F0000000C01000019000000000000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0100
      00190000000E0000000C01000019000000000000000000000000000000100100
      001600000008010000190000001300000008010000160000000E000000080100
      00170000000C0000000A01000018000000000000000000000000000000100100
      001600000008010000190000001300000004000000100000000A000000050000
      0011000000080000000600000012000000000000000000000000000000000000
      0000090909462426278D494C4EC76A6E72F06A6E72F0494C4EC72426278D0909
      0946000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000030100203B1E0D8F80411DCFCC6A34FFCF7038FF874720CF41220F8F0301
      0020000000000000000000000000000000000000000000000000000000000000
      0000000000000000000001000016080000341B00005B03000023000000000000
      0000000000000000000000000000000000000000000000000000010202202425
      268C7D8084EDBCBEC1FEE2E1E3FFF7F7F8FFF7F7F8FFE2E2E4FFBDC0C2FE7E81
      85ED2425268C0102022000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000010391D
      0D8FC25E29FFD1652AFFDA6F35FFDE7B41FFE38A4EFFE89A5EFFE69D61FFDE88
      4AFF4424108F000000100000000000000000010000161A000059000000130000
      000E0000000F0000000E0600002F47010094490200960A0000390000000F0000
      000A0000000A000000110600002D000000030000000001020220313234A3B2B5
      BAFBF9F9F9FFFDF3EFFFF6C7AEFFF08C41FFF59A41FFFDDAADFFFFF9EFFFF9F9
      F9FFB4B9BBFB313234A301020220000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000010773A1BCFC65A
      29FFD25F25FFD66729FFDA702FFFDF7936FFE4843DFFE98F45FFEF9C52FFF4B9
      78FFEEAB6BFF914E22CF00000010000000000E000043620500AF2C0000742700
      006C2900006F2900006F2601006C2501006C2101006425020068210000662E02
      0B8532010D8C2800006F6E0000B30200001B000000002425268CB2B5BAFBFDFA
      F9FFEB9884FFDB3A02FFE24E01FFFFFFFFFFFFFFFFFFF98900FFFE9A03FFFED2
      8DFFFEFDFAFFB4B8BBFB2425268C000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000371A0C8FC25B2EFFCE5A
      26FFD25F23FFD66729FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF994DFFF4A5
      55FFFAC17BFFEFAD6DFF4424108F00000000010000182701006E000000090000
      0002000000030000000300000002000000000000000000000000000000100503
      1D620100021F000000010100001800000000090909467C8084EDF9F9F9FFED9E
      84FFD52A02FFD93602FFE14901FFFFFFFFFFFFFFFFFFF68100FFFC9100FFFE9B
      04FFFED088FFF9F9F9FF7E8085ED090909460000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000002010020B85A2EFFCB5D2EFFCE57
      1DFFD15E22FFD56628FFDA6F2EFFFFFFFFFFFFFFFFFFE88C43FFED964AFFF19F
      51FFF5A656FFF5BB7AFFDF894BFF03010020010000162500006B000000030000
      00000000000000000000000000000000000000020D3A0006225E00082F6E0001
      0423000000000000000000000000000000002426278DBCBFC2FEFDF4EFFFDB3B
      01FFD62D02FFD73002FFDE4201FFE55401FFEB6400FFF17400FFF68200FFFA8C
      00FFFC9000FFFFF8EFFFBCBFC2FE2426278D0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000035190C8FC4663DFFCA531CFFCD56
      1CFFD05D21FFD46426FFD86C2DFFFFFFFFFFFFFFFFFFE5873FFFE98F45FFED96
      4BFFEF9B4EFFF09F54FFE79F64FF41220F8F010000172600006D000000060000
      000000000000000000000000000000020C390003164C00041951000736760000
      000500000000000000000000000000000000494C4EC7E2E2E4FFF7CEB8FFDD40
      01FFD83302FFD52A02FFDA3802FFFFFFFFFFFFFFFFFFF08C40FFF07000FFF378
      00FFF47B00FFFBD5ADFFE2E2E4FF494C4EC70000000000000000000000000041
      71EF004171EF000408400000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF00000000713519CFD07850FFCA5019FFCC54
      1BFFCF5A1FFFD36124FFD7692AFFFFFFFFFFFFFFFFFFE2803BFFE58740FFE88D
      44FFEA9046FFEA9147FFE99D61FF874720CF010000172600006D000000050000
      0000000000090101021E0000000900062D6C0000000D00000000000000090000
      0000000000000000000000000000000000006A6E72F0F7F7F8FFF2A776FFE568
      2EFFDB3D06FFD62D02FFD62D02FFFFFFFFFFFFFFFFFFEC8040FFE95E01FFEB65
      00FFEC6700FFF18E41FFF7F7F8FF6A6E72F000000000004171EF004A82FF004A
      82FF0B59A5F7004A82FF00132080000000000000000000000000000000000000
      000000000000000000000000000000000000B55F38FFD37C55FFCF612DFFCC55
      1CFFCE571DFFD15E22FFD46427FFFFFFFFFFFFFFFFFFDE7835FFE17E39FFE383
      3DFFE5853EFFE5863FFFE48D50FFD07139FF0000000B2400006A000000020000
      000B00041E5900072F6E00062866000723610000000000000000000000000000
      0000000000000000000000000000000000006A6E72F0F7F7F8FFF4AA73FFEB82
      45FFE67443FFDD4B1CFFD62F07FFD62E02FFFFFFFFFFFFFFFFFFE97940FFE451
      01FFE55401FFEB8041FFF7F7F8FF6A6E72F000000000004A82FF549BD5ED5EA2
      D9ED3585D8ED0B58B1F5004A82FF00000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF00000000B5603AFFD5825BFFD06533FFD165
      31FFD05F27FFCF5B21FFD26023FFFFFFFFFFFFFFFFFFDB7030FFDD7533FFDE79
      36FFDF7B37FFE07B37FFDF7E44FFCC6B35FF0A02013C2E010077000000000005
      195001030B3A00000007000F5F9C000829680000000000000000000000000000
      000000000000000000000000000000000000494C4EC7E2E2E4FFFBDCC2FFEE88
      41FFEA7C43FFE67446FFE36A44FFDE5634FFDB4A27FFFFFFFFFFFFFFFFFFE77A
      4FFFE25C26FFF6CFBFFFE2E2E4FF494C4EC700000000004171EF004A82FF004A
      82FF1B6CACF6004A82FF0017288F000000000000000000000000000000000000
      0000000000000000000000000000000000006E3219CFD98D6AFFD06433FFD165
      33FFD26733FFD36833FFFFFFFFFFFFFFFFFFFFFFFFFFD7692AFFD96D2DFFDA70
      2FFFDB7130FFDB7131FFDA7138FF80411DCF8C0100CE4101008C000000000007
      1D57020307330000000100052B6A00030F3F0000000000000000000000000000
      0000000000000000000000000000000000002426278DBDC0C2FEFEF9F3FFF28F
      3DFFED853FFFFFFFFFFFFFFFFFFFE46F46FFE36B49FFFFFFFFFFFFFFFFFFE992
      7CFFE36F52FFFDF6F4FFBEC0C3FE2426278D0000000000000000000000000041
      71EF004171EF00070C500000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000033180B8FD58E6EFFD16A3CFFD065
      33FFD16633FFD26733FFD36A34FFD56C35FFD66E36FFD76F35FFD87035FFD971
      36FFDA7236FFDA7337FFD36E35FF3C1E0D8F3D0100882B000072000000000006
      1B5402040C3D0000000000000002000000000000000000000000000000000000
      000000000000000000000000000000000000090909467F8186EDF9F9F9FFFACC
      9FFFF18E3BFFFBE6D7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDF7F4FFE36E
      4BFFF1B9A9FFF9F9F9FF7F8186ED090909460000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000002010020B86643FFDB8F6CFFD064
      33FFD06533FFD16633FFD26733FFFCF6F2FFFCF6F3FFD56D36FFD66E36FFD76F
      37FFD87037FFD87037FFC4632FFF030100200200001C21010066000000000006
      235F0102072F0000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000002425268CB5B9BCFBFEFC
      FAFFFACC9EFFF28F39FFF5B688FFFDF1EAFFFEF7F4FFED966BFFE77644FFF3BC
      A6FFFEFBFBFFB6B9BCFB2425268C000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000033180B8FCB8260FFD988
      62FFD06433FFD06533FFD16533FFFCF6F2FFFCF6F2FFD36934FFD46A35FFD46B
      35FFD56C37FFCA6532FF3A1D0D8F000000000000000524030976050317590002
      0E3D000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001020220313234A3B5B9
      BCFBF9F9F9FFFEF8F2FFFBDCBFFFF5AA6BFFF3A66DFFF9D7C1FFFEF7F3FFF9F9
      F9FFB6B9BCFB313234A301020220000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000106C3218CFCB82
      60FFDB8F6BFFD16A3CFFD06533FFD36F40FFD46F40FFD26733FFD26936FFD26C
      3FFFC76337FF773A1BCF000000100000000005000029570713B5080310540000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000010202202425
      268C7F8286EDBDC0C2FEE2E2E4FFF7F7F8FFF7F7F8FFE2E2E4FFBEC0C3FE7F81
      86ED2425268C0102022000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000103318
      0B8FB86642FFD48E6DFFD98C69FFD5815AFFD27B53FFD17A53FFC86F48FFBA5E
      33FF371A0C8F000000100000000000000000070000332D0000760000000A0000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000090909462426278D494C4EC76A6E72F06A6E72F0494C4EC72426278D0909
      0946000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000201002033180B8F6E3219CFB55F39FFB45E37FF713519CF35190C8F0201
      0020000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000183948C02B6581FF2B6581FF2B65
      81FF2B6581FF2B6581FF2B6581FF2B6581FF122B3AFF1C4661FF1C4661FF1D3F
      55FF1F2D36FF152D3CEF00000000000000000000000000000000000000000000
      0000000800400031009F006300DF199F19FF1B9F1BFF006300DF0031009F0008
      0040000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000003B7C99FF4FA2C5FF4FA2C5FF4FA2
      C5FF4FA2C5FF4FA2C5FF4FA2C5FF4FA2C5FF1C4860FF3186B4FF3186B4FF2852
      6AFFE99464FF284050FF0000000000000000000000000000000000000010003C
      00AF039F03FF29D829FF6FFA6FFF9EFF9EFFA5FFA5FF7EFC7EFF34DA34FF059F
      05FF003C00AF0000001000000000000000000000000000000000000000000000
      000000000037031D038D1B4F1BC6265F26D51C521CC905220599000100520000
      000D000000000000000000000000000000000000000000000000000000000000
      0000010000362412088D5A2F17C3733F20D562381FC72F1B0E99040100520000
      000D000000000000000000000000000000003F819EFF52A6CAFF52A6CAFF52A6
      CAFF52A6CAFF52A6CAFF52A6CAFF52A6CAFF507182FFBCBCBCFFBCBCBCFF2D61
      7CFFE99464FF2C4D63FF00000000000000000000000000000010005500CF00B8
      00FF02DE02FF3FE13FFF78E578FF92E792FF95E995FF80E780FF48E348FF08DE
      08FF00B600FF005500CF0000001000000000000000000000000000000006001F
      009845CF45FD7EF37EFFA9FFA9FFBDFFBDFFAEFFAEFF83F683FF4BD34BFF0431
      04B30000002B0000000000000000000000000000000000000000000000062911
      0597D46429FDE67331FFEA7832FFEE7C31FFF49347FFFCA75EFFF5A662FF462A
      17AF0000002A0000000000000000000000004486A2FF55ABCEFF55ABCEFF55AB
      CEFF55ABCEFF55ABCEFF55ABCEFF55ABCEFF5B7D8EFFDCDCDCFFBCBCBCFF3670
      8FFFDCDCDCFF32566DFF000000000000000000000000003C00AF00B700FF01D8
      01FF3DC73DFF61CA61FF6FD36FFF78D978FF7ADA7AFF73D573FF65CC65FF40C9
      40FF01D401FF00B200FF003C00AF000000000000000000000005003C00B84AE9
      4AFF6DD96DFF7AD67AFF88DF88FF90E690FF8BE28BFF7DD97DFF70D970FF50E8
      50FF0B5A0BD20000002A00000000000000000000000000000005471C0AB8E566
      29FFD76424FFD86826FFDC7B44FFE6A787FFE78D4FFFEC9343FFF8AB5BFFFFCD
      7DFF7C512ECF000000290000000000000000498AA5FF58B0D1FF58B0D1FF58B0
      D1FF58B0D1FF58B0D1FF58B0D1FF58B0D1FF61787EFFE2C1A6FFBCBCBCFF1A53
      4AFF0A5412FF29545AFF000000000000000000080040009A00FF00D800FF0A8F
      0AFF109210FF48BB48FF59C659FF61CB61FF62CB62FF45BA45FF52C152FF46B7
      46FF2AB52AFF00D000FF009700FF00080040000000000020008C2FDA2FFF47B7
      47FF51BD51FF63CC63FF6DD36DFF74D674FF73D673FF65CD65FF55BF55FF4AB7
      4AFF34DA34FF023102B60000000D000000000000000028130A8BDD612AFFCF59
      1DFFD26224FFD5601CFFE6B7A4FFF6FFFFFFEABCA5FFEA8A38FFF29F4FFFF8AD
      5AFFFFCC7DFF482B17B30000000C000000004E90A9FF5BB5D5FF5BB5D5FF5BB5
      D5FF5BB5D5FF5BB5D5FF5BB5D5FF5BB5D5FF638594FFE0E0E0FFBCBCBCFF134C
      3AFF129016FF04580BFF00070160000000000031009F00C500FF08BF08FF279F
      27FF9AD59AFF0C900CFF40B540FF49BB49FF139613FF35A635FF109310FF35AC
      35FF2AA32AFF08BA08FF00BC00FF0031009F000400470FAB0FF62CAE2CFF2A9F
      2AFF1F9E1FFF43BA43FF5AC65AFF5BC75BFF45BB45FF47BC47FF46B846FF36A9
      36FF2CAD2CFF14BC14FF000100520000000006030147B2542AF5CE541BFFCE58
      1DFFD26124FFD56320FFDD8D65FFEACEC2FFE4966BFFE8893BFFEE9A4DFFF19E
      50FFF7A959FFF5A561FF04010052000000005395AEFF5EBAD9FF5EBAD9FF5EBA
      D9FF5EBAD9FF5EBAD9FF5EBAD9FF5BB5D5FF5E7778FF638554FF1D7E29FF158B
      1EFF1AA920FF129516FF055909FF0010028F006100DF00D800FF0C990CFF0284
      02FFEAF7EAFFADDEADFF129212FF119311FF058905FFFFFFFFFF88CE88FF0589
      05FF1B961BFF0E990EFF00CA00FF006100DF004C00BB0EAE0EFF1A901AFF1D97
      1DFF9CD09CFF27A227FF26A926FF2EAC2EFF3AA43AFF2FA72FFF22A222FF2AA1
      2AFF1D911DFF12B712FF0021009D00000000592F1CBBC75C2CFFC94D12FFCD57
      1DFFD15E22FFD35F1EFFDD8E6BFFEAC8B8FFE18D5EFFE48032FFEA9046FFEB94
      49FFEC9447FFFBA45BFF311C0F9D00000000589BB1FF62C0DDFF62C0DDFF62C0
      DDFF62C0DDFF62C0DDFF62C0DDFF62C0DDFF256A3DFF50C764FF46D153FF31C7
      38FF21B526FF169F1AFF0C7E10FF013F06FF009600FF00DA00FF088008FF0786
      07FF65BD65FFE9E9E9FFEFEFEFFFADDEADFF65BD65FFEEEEEEFFD9D9D9FFC1E6
      C1FF088908FF068206FF00CA00FF009200FF009C00EC008D00FF0A790AFF0082
      00FF9DCF9DFFDAE2DAFF4BAB4BFF0E910EFF91C691FFD1DDD1FF219921FF0087
      00FF0E7E0EFF009400FF004A00CA00000000A66141ECD0693AFFCA5119FFCB52
      18FFCF5B1FFFD05412FFE3AB95FFF8FFFFFFE7B6A1FFDD6B1FFFE5873EFFE689
      41FFE6893FFFF4944BFF61381FC7000000005D9FB5FF65C5E1FF65C5E1FF65C5
      E1FF65C5E1FF65C5E1FF65C5E1FF317E6CFF81D797FF66D97DFF35B045FF1274
      1DFF1EAF25FF149718FF034408EF00010030069906FF88F489FF3EB43EFF20A1
      20FF0B8F0BFFC1E6C1FFE9E9E9FFE5E5E5FFEFEFEFFFEBEBEBFFE2E2E2FFEEEE
      EEFFEAF6EAFF139313FF7AEE7CFF059605FF28BD28FF39B639FF1A9C1AFF0990
      09FF0F8F0FFFD4DCD4FFFFECFFFFE6E8E6FFD9E3D9FFE5D6E5FFE1EAE1FF4FAC
      4FFF098F09FF3EC33FFF0F5E0FD900000000C3724EFFD16C3DFFD06330FFCD5A
      23FFCD561CFFCF5718FFD36833FFEFE2E1FFF4F7F8FFDF8D62FFDD6F27FFE17E
      3AFFE17E39FFEE8740FF743F21D70000000063A4B9FF68CBE5FF68CBE5FF68CB
      E5FF68CBE5FF68CBE5FF68CBE5FF428B5DFF7DD596FF267449FF4F746CFF2662
      51FF179D1EFF023308CF0000002000000000006100DFAAF8AAFF56C556FF39B1
      39FF29AB29FF058B05FF65BD65FFEAF7EAFFFFFFFFFFFEFEFEFFFEFEFEFFFFFF
      FFFFADDEADFF129512FF98F399FF006100DF57A758EB86E987FF3DCC3DFF30C8
      2FFF15BB15FF1FA61FFFA7D2A7FFF0F0F0FFFDFCFDFFFEFDFEFFFFFFFFFF82C3
      82FF22B321FF97FE98FF215021C500000000A66446EBD26E41FFCF622FFFD168
      35FFD1642FFFCF5B20FFCE500DFFD67446FFF3F0EFFFF0E6E7FFD97139FFDA6E
      2AFFDC7330FFE97936FF5A2E17C30000000068AABEFF6BD0E9FF6BD0E9FF6BD0
      E9FF6BD0E9FF6BD0E9FF6BD0E9FF4AA360FF348667FF6BD0E9FF78909BFF4986
      88FF1A5633FF0000001000000000000000000031009F95E396FF82E182FF4DB8
      4DFF41B541FF38B138FF1A9D1AFF098F09FF129312FFFFFFFFFFFFFFFFFF75C5
      75FF119211FF64D564FF82DE83FF0031009F1B551BB78CE48CFF50CA50FF3DC7
      3DFF36C936FF22C222FF0EAD0EFF079B07FFAAD7AAFFFFFFFFFF58B358FF18A9
      18FF59CD59FF8CF38DFF061E069100000000593524B6D2784FFFCF602EFFD066
      34FFD0642EFFD36C3FFFD26431FFCB4806FFE7BCACFFFAFFFFFFE09978FFD560
      1CFFD96F31FFE77737FF26130791000000006CAFC1FF6ED5EDFF6ED5EDFF6ED5
      EDFF6ED5EDFF6ED5EDFF6ED5EDFF3A9085FF6ED5EDFF6ED5EDFF6C8995FF76AE
      C7FF547E91FF000000000000000000000000000800402DA42DFFC1FCC1FF72CB
      72FF5ABD5AFF51BA51FF4BB84BFF48B748FF0B8F0BFFFFFFFFFF44AD44FF249F
      24FF6CCA6CFF99F399FF28A329FF000800400106013F70C272F48DE18EFF4FC6
      4EFF4BC84BFF43C843FF41CD41FF21BA21FF5AAD5AFF50B250FF26B126FF5ACD
      5AFF8CE18CFF6FDA70FF00000036000000000705043DB86D4BF3D56C3CFFCD5D
      29FFD06538FFF6E8E5FFF1D8D0FFE4AC95FFF5EFEEFFFBFFFFFFDF9675FFD464
      26FFDC7439FFDB7036FF010000350000000072B4C5FF72DAF0FF72DAF0FF72DA
      F0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF708A96FF80B5
      CEFF547E91FF00000000000000000000000000000000003C00AF76CB77FFC2FA
      C2FF81CF81FF6CC46CFF67C167FF64C164FF219D21FF159515FF3AAA3AFF79CF
      79FF98F098FF66CA67FF003C00AF00000000000000000C240C80ACF1ADFF88D8
      88FF5EC85EFF5ECB5EFF5BCC5BFF58CA58FF2CA82CFF47BD47FF6BCF6BFF8AD7
      8AFFA4FEA4FF0220029A0000000000000000000000002818117FDA8055FFD060
      2EFFCE6033FFEECABEFFFFFFFFFFFFFFFFFFFDFFFFFFEBC5BAFFD26632FFD56A
      32FFEA773CFF29110599000000000000000077B9CBFF75E0F6FF75E0F6FF75E0
      F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF738D97FF89BB
      D3FF547E91FF0000000000000000000000000000000000000010045904CF79CE
      79FFD3FCD3FFA9E9A9FF8ED58EFF82CB82FF83CB83FF88D488FF93E393FFADF6
      AFFF6ACA6AFF005400CF000000100000000000000000000000001E441EA7B6F3
      B6FFAAE5ABFF81CF81FF74CB74FF73CC73FF7AD17AFF88D288FFA5E3A5FFABFC
      ABFF113E12B70000000700000000000000000000000000000001492D21A7DB80
      57FFD46938FFCC5521FFD67952FFDC8B69FFD8805AFFCF5E29FFD56732FFE472
      3FFF461E0BB70000000700000000000000007DBFCFFF78E5FAFF78E5FAFF78E5
      FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF527586FF91C0
      D7FF547E91FF000000000000000000000000000000000000000000000010003C
      00AF31A531FFAAE5AAFFD0FBD1FFC1FAC2FFB8F8B8FFBFF8C0FF99E29AFF2CA4
      2CFF003C00AF0000001000000000000000000000000000000000000000000C25
      0C8377B278E9B1E7B2FFAFE4AFFFA9DEA9FFABE4ABFFA7E6A8FF6CB46DEC0721
      078C000000040000000000000000000000000000000000000000000000002A19
      1282A86444E8D2784FFFCF6434FFCD5D2BFFCE612EFFCE6C3EFFA85934EB2813
      0A8B000000040000000000000000000000004A6F78C083C4D3FF83C4D3FF83C4
      D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF6C8894FF4F78
      85E0152024800000000000000000000000000000000000000000000000000000
      0000000800400031009F006100DF229E22FF229E22FF006100DF0031009F0008
      0040000000000000000000000000000000000000000000000000000000000000
      0000020702411A4C1AAE64A764EB74C474FF5EA95EEC144C14B3000300490000
      0000000000000000000000000000000000000000000000000000000000000000
      000008050440513021AEA56345EBC4734FFFA55F3FEC512A19B3060301480000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000202021838533AA2129F
      1FFF139F1FFF38533AA202020218000000000000000000000000000000000000
      00000000000000000000010101200404053A0404053A01010223000000000000
      00000000000000000000000000000000000000000000000000230704006E0704
      006F090807700303034E0000001A040302510909086F0908086E0908086E0808
      066E0704006F0704006C0000001A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000009020202191616164C558958D683EE
      A8FF84F0ACFF558A59D61616164C020202180000000000000000000000000000
      0000020204330C0D41B20B1094F30004ABFF0000A7FF00008AF500003BB90303
      053B0000000000000000000000000000000000000000463513B7FFCF73FFF0BB
      5EFFFFFFF4FFC2C1C2FF554F4AE2CCC4BBFFFFFFFCFFFFF7EBFFFFFAF4FFFFF6
      E5FFF0BC5FFFFFCE73FF36270DA900000000000000000000000E4D261DA97E51
      3ACB674C49C36B5A5CC46B5757C46B5454C46B5555C4695455C46F4F46C4754B
      36C47F4E33CC200A087500000000000000000000000000000000000000000000
      00000000000000000000000000000505052638563AA7189322F60C9517FC64E0
      90FF64E493FF0C9518FC189322F638533AA20000000000000000000000000101
      0D551D22ACFD1722D6FF2227DCFF5659E5FF5759E3FF1F21D3FF0000C0FF0000
      92FF02020D62000000000000000000000000000000006E5322D1FFD082FFECBC
      6AFFFFFFEFFFB8B8B9FF685F58FFC0BBB7FFFFFAEEFFF8EADDFFF9ECE3FFFAEE
      DFFFECBD6BFFFFD082FF6C501CD400000000000000000805063FF99D58FFFFA6
      4DFFD6B1A6FFDCC9C9FFD9C7C5FFD9CDCEFFDACDCDFFD4CCD0FFEEB89EFFFF9F
      4AFFFF9825FFA84821E400000001000000000C7C93FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF228AA1FF119E1CFF81DF9CFF62D486FF1FC0
      58FF22C960FF65E494FF84F2ADFF139F20FF00000000000000000101032D2128
      B3FC1E2FE3FF5557E0FFF2F0F4FFE2DFF1FFE1DFF2FFFBFAF8FF6767D9FF0000
      C2FF000093FF02020438000000000000000000000000614A1FCAFAC873FFE7B3
      5AFFFFFAE9FFAEAEAEFF4C443FFFB6AFA9FFFFF3E7FFF0E1D4FFF0E3DAFFF5E8
      D9FFE8B45BFFFAC873FF5E471ACC00000000000000000705053DF49C5BFFFFA1
      52FFD5BEB6FFC25348FFE0998BFFE8EAE9FFE0D6D5FFD9D6DAFFE6A085FFFE8A
      3DFFFF962FFF934321D6000000010000000007788FFFA3E6FFFF50D0FFFF40CA
      FFFF41CAFFFF40CAFFFF44CBFFFF8EE2FFFF139E1BFF84DD99FF62D283FF1FB7
      51FF1FC259FF64E190FF84EEA9FF129F1FFF00000000000000000B0C49B03448
      E7FF373CDCFFFFFFF4FF6E6FDBFF0309C3FF0207BDFF6262D3FFFFFFFBFF494A
      C9FF0003BDFF00003FBF000000000000000000000000614B20CAF9C56DFFE5AF
      52FFF9F1E7FFD7D3D7FF89898EFFD0CBCBFFF6EDEBFFEDE4E2FFEDE6E7FFF2E9
      DFFFE6AF52FFF9C56DFF5E471BCC00000000000000000705053DF29B5CFFFFA5
      57FFEDD2C9FF6C6577FF6A6B7DFFCCC8D1FFFBECE3FFEEF5F7FFE79378FFFC7E
      31FFFF9F39FF93411FD60000000100000000087A91FF49A6BCFF53D1FFFF14BC
      FBFF13BBFBFF13BBFBFF16BBFBFF43CBFFFF46BA95FF159D27FF099818FF62D1
      83FF62D587FF0C9518FB189322F638533AA200000000000001182B33B5F3152D
      E7FFB1AFE5FFA7A7E4FF0000C4FF0004C0FF0000BAFF0000B0FF9898DEFFC5C5
      E7FF0000B8FF020496FB010101220000000000000000624C21CAF8C26AFFE4AA
      4AFFE7C183FFF4D7A6FFFFE3B3FFF4D6A7FFEBCEA0FFECCFA2FFEDD2A2FFE9C3
      85FFE4A94AFFF8C26AFF5F471BCC00000000000000000705053DF39C5DFFFFA6
      5AFFF2CFC5FFBCC3D3FFB5D1DFFF71B0DBFF5587C2FFF3EAE8FFF28161FFF96D
      21FFFFA541FF92401ED60000000100000000087A91FF229DBFFF89DCF8FF2CC7
      FEFF1BC1FDFF1DC1FDFF1EC1FDFF24C5FDFF37CBFFFF70DCFFFF58BC7CFF83DD
      99FF83E29DFF4D9F62F1141414490202021800000000030305364050DBFF011D
      E3FFC0BEE5FF8183DCFF4D50E4FF9191DFFF8D8CDEFF1316D6FF5F5FD6FFD9D7
      E9FF0002B3FF070BACFF0404053A0000000000000000614C22CAF7BF64FFE2A7
      46FFE2A53EFFE0A239FFE1A33AFFE1A33AFFE2A43BFFE2A43AFFE1A239FFE2A5
      3EFFE2A746FFF7BF64FF5E491DCC00000000000000000705053DF29D60FFFFB3
      68FFF89554FFE58850FFBAC0C6FF58D3FFFF0087FDFF516D9EFFFF782AFFFF8B
      32FFFFA444FF923F1ED60000000100000000087A91FF35C9FFFF4FA8B9FF5ED9
      FFFF24C7FDFF24C7FDFF24C8FDFF24C7FDFF20C6FDFF3DD0FFFF4ABE95FF139E
      1BFF129E1CFF4BAE7BFF1113154D0000000000000000030305354252DFFF112D
      ECFFAFAEDFFFC2C1E6FF7271E3FFCAC9E9FFC6C6E7FF2828DAFFA8A8E4FFBCBB
      E1FF0000B7FF0E14B0FF040405390000000000000000624D24CAF3B650FFE7B8
      69FFFFFEF9FFFFFDF2FFFFFBF1FFFFFFF5FFFFF9EFFFFFFDF2FFFFFDF3FFFFFD
      F8FFE7B869FFF3B650FF5F4A1FCC00000000000000000705053DF29758FFFCDD
      BAFFF6E3CEFFFFDEC1FF92AAB9FF7DDFEFFF4DD8FFFF009EF9FF6689A4FFFAD1
      B7FFFEBB75FF933C14D60000000100000000087A91FF40D1FFFF0D94BCFF90E3
      FBFF38D1FDFF2ACDFCFF2CCEFCFF2CCEFCFF2BCDFCFF33CFFCFF56D9FFFF7EE2
      FFFF82E3FFFFA4EFFFFF0F4E5CC70000000000000000000000162A32B9F1D5E1
      FFFFA8A7D7FFDBDBEAFF6D6DC9FFB6B6E1FFB0B0E1FF5353C3FFFCFCEFFF5756
      CEFF2327EBFF0E129EF90101011E0000000000000000634E25CAF2B246FFEEC2
      77FFE3E7EEFFCFCECAFFDAD7D2FFB9BAB9FFE4E1DCFFCCCBC8FFCCCCC9FFEEF2
      F8FFECC075FFF2B246FF5F4A21CC00000000000000000705053DF29554FFF9EC
      DAFFFCFFFFFFFFFFFFFFF7F4F9FF7EB3C6FF91F1F4FF4BEBFFFF00BBFBFF7AA6
      D3FFFFBB79FF963D13D60000000100000000087A91FF44D1FFFF19C3FBFF57AB
      BDFF68DFFFFF36D3FEFF35D2FEFF35D2FEFF35D2FEFF36D2FEFF37D2FEFF38D3
      FEFF37D2FEFF57DCFFFF71C4DCFF02060634000000000000000008084BA9F5F6
      FEFFEEEEF6FF9797CCFF8888CFFFC3C3E5FFBBBBE3FF6565CAFF7575C7FF4B4A
      E4FF494AFBFF000045B8000000000000000000000000644F28CAF0B041FFE9BA
      6AFFE8EAECFFD2CEC6FFE0DBD4FFD7D3CCFFE8E3DAFFD3CFC8FFD8D5CDFFF0F1
      F5FFE7B968FFF0B041FF604A23CC00000000000000000705053DF19656FFF8E6
      D1FFFDFFFFFFFFFDFDFFFFFFFDFFF4EAE9FF71AFC3FF94F6F8FF49FCFFFF00CE
      F1FFA5947AFFA1380BD50000000000000000087A91FF46D4FFFF25CDFFFF1299
      BAFFA6E6FAFF8AE4FEFF87E4FDFF88E4FDFF88E4FDFF88E4FDFF86E4FDFF85E5
      FFFF86E6FFFF8BE5FFFFBFF7FFFF0D4854C2000000000000000000000326393C
      C1F7FFFFFFFFFFFFFFFFCDCDF1FFB4B4D5FFB0B0D2FF8483E3FF8685F3FF7D80
      FFFF1719B1FE01010431000000000000000000000000634F2ACAF3AF3DFFEAB8
      64FFE2E5EAFFC7C2BBFFD8D4CDFFD4D0CAFFE6E0D7FFC6C1BAFFD2CEC7FFEBED
      F2FFE8B662FFF3AF3DFF604C25CC00000000000000000705043CF29657FFF6E4
      CFFFFDFFFFFFFFFAF7FFFFF6F2FFFFFBF3FFEDDDDAFF68ADC4FF93F6FCFF3CFD
      FFFF15E3F0FF5E2B27D40000000000000000087A91FF4BD6FFFF29CDFDFF2ACA
      F9FF09829BFF087A91FF087A91FF087A91FF087A91FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF096171E00000000000000000000000000101
      0C483F42BDF6E1E4FDFFFFFFFFFFB7B7D1FFA2A2CCFFC4C5FFFF9395FBFF2427
      B4FB01000D550000000000000000000000000000000066522CCAE1A136FFDDAC
      5CFFDEE0E4FFB8B5AFFFD7D3CDFFD6D0C8FFC1BEB9FFE2DDD5FFC1BEB8FFE9EB
      EFFFDAAA59FFE1A136FF624F27CC00000000000000000805053FF49D5CFFF5E6
      D3FFFFFFFFFFFFFCFAFFFFF8F5FFFFF2EEFFFFFEF5FFE6E0E2FF61B6D3FF98FA
      FFFF2FF8FFFF10B5D0F50606094A00000000087A91FF4ED8FFFF2CCEFEFF2FCF
      FEFF30D2FFFF2FD1FFFF33D3FFFF4BD9FFFF52DDFFFF52DDFFFF6AE4FFFF67BF
      D3FF000000090000000000000000000000000000000000000000000000000000
      0000010102260A0A47A4474AAFEB8487DFFF777ADDFF3A3CACED0B0B44AA0202
      042F0000000000000000000000000000000000000000755F36D2D7962CFFCE9D
      4CFFF4FBFFFFEBE9E5FFEDEBE8FFEDEBE8FFECEAE7FFEEECE8FFEBE9E5FFF5FB
      FFFFCE9D4BFFD7962CFF745D32D6000000000000000005030335ED8544FFF7DB
      BDFFFCECE5FFFDE8DCFFFDE3D7FFFCE2D4FFFCE4D7FFFFF0E2FFD7C3C3FF60B2
      C9FF96FBFFFF30FCFFFF10A4D6FF0000001317859AFF75E4FFFF35D1FEFF31D0
      FEFF2FD0FEFF36D1FEFF70E2FFFF1C8AA0FF087A91FF087A91FF087A91FF107E
      94FF000000080000000000000000000000000000000000000000000000000000
      0000000000000000000000000016030305350303053600000119000000000000
      00000000000000000000000000000000000000000000392C15A4EDC26EFFE4C1
      84FFE9DDC4FFE9DABEFFE8DABDFFE8DABEFFE9DABEFFE8DABDFFE9DABDFFE8DC
      C4FFE4C284FFEAC06EFE2B210E920000000000000000000000031907056A3114
      0F8D2B110F872C120E882C120E882C120E882C110E882B110E882E110E85210C
      0E89448FA8E43CDBF8FF0E426CCA00000008010E11572D94A9FF7DE7FFFF53DC
      FFFF52DCFFFF79E7FFFF2B94A9FF00090A440000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000D241E117E241E
      107E231A087E231B097E231B097E231B097E231B097E231B097E231B097E231A
      087E241E107E241D107D00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000070B146C093C6ED30100011B000000000000000001060836138297FF087A
      91FF087A91FF158398FF00080A41000000000000000000000000000000000000
      00000000000000000000000000000000000000000000818181FF818181FF8181
      81FF808080FF808080FF808080FF808080FF808080FF7E7E7EFF7E7E7EFF7E7E
      7EFF7E7E7EFF7E7E7EFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000009000000000000000000000000183948C02B6581FF2B6581FF2B65
      81FF2B6581FF2B6581FF2B6581FF2B6581FF122B3AFF1C4661FF1C4661FF1D3F
      55FF1F2D36FF152D3CEF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008E8E8EFFFDFDFDFFACBA
      D7FFF9F9F9FFF9F9F9FFF9F9F9FFF9F9F9FFF9F9F9FFF8F8F8FFF8F8F8FFF8F8
      F8FFFDFDFDFF8C8C8CFF00000000000000000E0D0D624A4B4BD14D5054D64C4E
      52D5525456D5515355D5515355D5515355D5515355D5515354D5545658D52C2D
      2DC5000000160000000000000000000000003B7C99FF4FA2C5FF4FA2C5FF4FA2
      C5FF4FA2C5FF4FA2C5FF4FA2C5FF4FA2C5FF1C4860FF3186B4FF3186B4FF2852
      6AFFE99464FF284050FF00000000000000000000000000000000000000001932
      419201050744000000000505053205050642020303300A13185E020405300000
      00000000000000000000000000000000000000000000989898FF949495FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FF969696FF00000000000000001C1D1D86E0D5C9FFD9D8DDFFDDD9
      DBFFF6E9DCFFF2E6DCFFF1E6DCFFF1E5DBFFF1E6DCFFF1E5DBFFFFF6EBFF8581
      7EF5000000160000000000000000000000003F819EFF52A6CAFF52A6CAFF52A6
      CAFF52A6CAFF52A6CAFF52A6CAFF52A6CAFF507182FFBCBCBCFFBCBCBCFF2D61
      7CFFE99464FF2C4D63FF000000000000000000000000000000021E3A489F46A3
      CFFF0C181E9D474747C1D7D8D8F7DEEAEFFF3180A8FF3693C2FF5589A3F60002
      03440000000000000000000000000000000000000000A1A1A1FFFAFAFAFFACBA
      D7FFEBEBEBFFEBEBEBFFEBEBEBFFEBEBEBFFEAEAEAFFE9E9E9FFE8E8E8FFE7E7
      E7FFF9F9F9FFA0A0A0FF00000000000000001B1C1D7ECBB6A3FFA49A98FFCBBF
      B8FFDEC5AEFFDBC4B0FFDAC4B0FFDAC3AFFFD9C3AFFFD8C1ADFFEAD1BBFF746C
      66EA000000160000000000000000000000004486A2FF55ABCEFF55ABCEFF55AB
      CEFF55ABCEFF55ABCEFF55ABCEFF55ABCEFF5B7D8EFFDCDCDCFFBCBCBCFF3670
      8FFFDCDCDCFF32566DFF0000000000000000000000001B313E9945A2CCFF4B9F
      C3FF8BA5B2FFD2CCCAFFFFFFFFFFD7DFE4FF327291FF3794C1FFA7A8A7FF0407
      08620000000300000002000000000000000000000000A9A9A9FFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFA7A7A7FF00000000000000001D1E1E7ED3C1AFFFCCC4C4FFCCC1
      BCFFE3CCB8FFDFCBB9FFDECAB9FFDDC9B8FFDDC9B8FFDCC8B6FFECD6C3FF7B74
      6DEA00000016000000000000000000000000498AA5FF58B0D1FF58B0D1FF58B0
      D1FF58B0D1FF58B0D1FF58B0D1FF58B0D1FF61787EFFE2C1A6FFBCBCBCFF3A73
      92FFDCDCDCFF365D73FF0000000000000000000000002F5873D04FA8CDFF4FA8
      CBFF8FA5B0FFC4BEBCFFFFFFFFFFD7E0E4FF397B9CFF429BC5FF92C9E5FF0306
      0759000000060000000C000000000000000000000000AEAEAEFFFBFBFBFFACBA
      D7FFF0F0F0FFF0F0F0FFF0F0F0FFF0F0F0FFEFEFEFFFEFEFEFFFEEEEEEFFECEC
      ECFFFAFAFAFFADADADFF00000000000000001F1F1F7ED6C3B1FFCAC2C1FFCDC3
      BEFFE5CFB9FFE0CCBAFFE0CBBAFFDFCBB9FFDFCBB9FFDECAB8FFEDD7C3FF7F78
      72EA000000160000000000000000000000004E90A9FF5BB5D5FF5BB5D5FF5BB5
      D5FF5BB5D5FF5BB5D5FF5BB5D5FF5BB5D5FF638594FFE0E0E0FFBCBCBCFF3D77
      96FFDCDCDCFF3C6478FF0000000000000000000000002B5067C553AFD3FF52AE
      D1FF94A7B1FFAEA8A5FFEEECEAFFDCE5E9FF3E82A1FF48A4CDFF96CAE2FF0608
      094D0000000000000000000000000000000000000000B4B4B4FFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFB3B3B3FF00000000000000001F20217ED9C6B5FFCBC3C2FFCFC4
      BFFFE6D0BAFFE2CEBCFFE1CDBBFFE1CDBBFFE1CDBBFFDFCBB9FFEFD9C5FF827C
      75EA000000160000000000000000000000005395AEFF5EBAD9FF5EBAD9FF5EBA
      D9FF5EBAD9FF5EBAD9FF5EBAD9FF5BB5D5FF677D83FFE2C1A6FFBCBCBCFF407C
      99FFDCDCDCFF426A7EFF0000000000000000000000002C5268C558B7D8FF56B5
      D6FF73A9C0FFA8A4A3FFEAE5E2FFDDE6EAFF4489A7FF57AED6FF5BB7E3FF0608
      093C0000000000000000000000000000000000000000B7B7B7FF949495FFACBA
      D7FFF4F4F4FFF5F5F5FFF5F5F5FFF4F4F4FFF4F4F4FFF3F3F3FFF2F2F2FFF1F1
      F1FFFBFBFBFFB7B7B7FF00000000000000002021217EDBC8B6FFD0C6C4FFD0C5
      C0FFE8D2BDFFE4D0BEFFE3CFBDFFE3CFBDFFE2CEBCFFE1CDBBFFEFD9C6FF857F
      78EA00000016000000000000000000000000589BB1FF62C0DDFF62C0DDFF62C0
      DDFF62C0DDFF62C0DDFF62C0DDFF62C0DDFF52798DFF739EB1FFBCBCBCFF4791
      B4FF4D829BFF3F5E6EEF0000000000000000000000002D5369C55DBDDDFF5EBD
      DCFF5AB3D4FF9DA3A8FFECE5E2FFDDE6E9FF4A8FAEFF5FBBE5FF1A2931830000
      00010000000000000000000000000000000000000000BABABAFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFB9B9B9FF00000000000000002121227EDECFC2FFAEB0B8FFD2C6
      C0FFE9D3BDFFE5D0BEFFE4D0BDFFE4CFBDFFE3CEBCFFE2CEBBFFF0DAC6FF877F
      7BEA000000160000000000000000000000005D9FB5FF65C5E1FF65C5E1FF65C5
      E1FF65C5E1FF65C5E1FF65C5E1FF65C5E1FF68B0CAFF5D8899FF7695A2FF59A2
      C4FF547E91FF010102200000000000000000000000002E546AC562C5E3FF63C4
      E1FF60B8D7FF9DA3A8FFEBE5E1FFDDE6EAFF5195B4FF65C3EFFF111517600000
      00000000000000000000000000000000000000000000BCBCBCFFFDFDFDFFACBA
      D7FFF8F8F8FFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6F6FFF5F5F5FFF4F4
      F4FFFCFCFCFFBCBCBCFF00000000000000002122227EDFCDBDFFC4BFC1FFD2C7
      C2FFEAD4BEFFE6D2C0FFE6D1BFFFE5D1BEFFE4D0BEFFE3CFBCFFF2DBC7FF8982
      7DEA0000001600000000000000000000000063A4B9FF68CBE5FF68CBE5FF68CB
      E5FF68CBE5FF68CBE5FF68CBE5FF68CBE5FF68CBE5FF67BAD1FF758F99FF629F
      BAFF547E91FF000000000000000000000000000000002E556AC566CCE9FF67CC
      E6FF63BDDBFF9EA2A8FFEBE4E0FFDFE7EBFF579BBAFF6FCBF5FF141A1C690000
      00000000000000000000000000000000000000000000BDBDBDFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFBDBDBDFF00000000000000002222237EE0CCBAFFCFC6C5FFD3C8
      C2FFEBD5BFFFE7D2C0FFE7D3C0FFE6D2BFFFE6D1BFFFE5D0BEFFF2DBC7FF8A83
      7EEA0000001600000000000000000000000068AABEFF6BD0E9FF6BD0E9FF6BD0
      E9FF6BD0E9FF6BD0E9FF6BD0E9FF6BD0E9FF6BD0E9FF6BD0E9FF78909BFF6CA6
      C1FF547E91FF000000000000000000000000000000002F566BC569D3EEFF6BD3
      EDFF66C2DEFF9BA0A4FFECE5E2FFE3EAEDFF5D9EBDFF77D2FCFF151A1D690000
      00000000000000000000000000000000000000000000BEBEBEFFFDFDFDFFACBA
      D7FFFAFAFAFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFF9F9F9FFF8F8F8FFF6F6
      F6FFFDFDFDFFBEBEBEFF00000000000000002222237EE0CDBBFFCEC5C4FFD3C8
      C2FFECD5C0FFE8D3C0FFE7D2C0FFE6D2BFFFE9D3C0FFEAD3C0FFF4DBC6FF948C
      85F0000000160000000000000000000000006CAFC1FF6ED5EDFF6ED5EDFF6ED5
      EDFF6ED5EDFF6ED5EDFF6ED5EDFF6ED5EDFF6ED5EDFF6ED5EDFF6C8995FF76AE
      C7FF547E91FF0000000000000000000000000000000030586DC56EDAF4FF70DB
      F2FF68C5E1FF9DA2A7FFDBD3CFFFBDCBD2FF63ACCCFF84DCFFFF151A1D690000
      00000000000000000000000000000000000000000000BFBFBFFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFBFBFBFFFCBCB
      CBFFDBDBDBFFA7A7A7EF00000000000000002223237EE1CEBCFFD3CBCAFFD3C8
      C2FFEDD6C1FFE9D4C2FFE8D3C1FFEDD6C2FFCABFB5FFA1A2A3FFDDD9D6FF7E7B
      76DB0000000600000000000000000000000072B4C5FF72DAF0FF72DAF0FF72DA
      F0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF708A96FF80B5
      CEFF547E91FF00000000000000000000000000000000325A6EC573E1F9FF74E0
      F6FF6DCFE9FFDADEE3FFEAE2DFFF79AAC0FF76C7EDFF8BE0FFFF161A1D690000
      00000000000000000000000000000000000000000000BFBFBFFF949495FFACBA
      D7FFFBFBFBFFFCFCFCFFFCFCFCFFFCFCFCFFFBFBFBFFFAFAFAFFCBCBCBFFE2E2
      E2FFA8A8A8EF0606063000000000000000002223247EDFCCB9FFB7AEADFFD5C9
      C3FFECD5BFFFE8D3C0FFE8D2C0FFECD4BFFFC6BCB4FFE3E7E9FFCACBCBF40101
      01350000000000000000000000000000000077B9CBFF75E0F6FF75E0F6FF75E0
      F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF738D97FF89BB
      D3FF547E91FF00000000000000000000000000000000335D6FC577EAFFFF73E8
      FCFF83DDF3FFFFFCFAFFAFC3CCFF61AFD2FF8ADCFFFF8FE6FFFF191F22700000
      00000000000000000000000000000000000000000000BFBFBFFFFFFFFFFFACBA
      D7FFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFAFAFAFFDBDBDBFFA8A8
      A8EF060606300000000000000000000000002222227EEEECE9FFBEC4CFFFE2E6
      EEFFFEFDFBFFFAFAF9FFF9F9F8FFFBFAF9FFF0F0EFFFB2B2B2EB030303430000
      0000000000000000000000000000000000007DBFCFFF78E5FAFF78E5FAFF78E5
      FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF527586FF91C0
      D7FF547E91FF00000000000000000000000000000000355F72C579EDFDFF7AD4
      EDFF9CCEE3FFA1CEE3FE6DADCBF068A2BDE05C8AA0CF4F6E7CBE060707380000
      00000000000000000000000000000000000000000000BFBFBFFFBFBFBFFFBFBF
      BFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFA8A8A8EF0606
      0630000000000000000000000000000000002222227ED1D1D1FFD2D6DCFFC8CB
      D0FFD7D7D8FFD6D7D7FFD5D6D6FFD7D8D8FFDADADBFB0C0C0C5F000000000000
      0000000000000000000000000000000000004A6F78C083C4D3FF83C4D3FF83C4
      D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF6C8894FF4F78
      85E01520248000000000000000000000000000000000386677C76FC8E2F45277
      8BC732505F9F192A337E0F131455030304270000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000001C0808
      08700E0E0E8E0E0E0E8F0E0E0E8E0E0E0E900C0B0C8600000031000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000005000000030000000000000000000000000000
      000000000000000000000000000000000000000000000000000014121267FFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCF8FCFF0404025D090A06483529
      2778050403290000000600000006000000030000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000534C44CD635E57D4635E59D5635F
      59D5635F59D56A645CD6100F0C90000000010000000000000000000000000000
      00000000000000000000000000000000000000000005180909674D3638A9F8F5
      F5FFF6F2F2FFF4EEEEFFF8F4F4FFFFFFFFFFD0CCD0F8220F14B7291614A41E11
      118542214FC72C161E942A131D9646201EAB0000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000D6CEC5FFFFFFFFFFFFFFFAFFFFFF
      F3FFFFF9EAFFFFFFFFFF262320AF000000000000000000000000000000000000
      00000000000000000000000000000000000000000010120808590D0B0B59FAF6
      F6FFF6F2F2FFF4EEEEFFF7F2F3FFFFEAFFFF70B578FC05A101F50D240EB90000
      0E851D132F9B2D203B9B04001069562D25B50000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C8C2B8FFFBF8F4FFF8F0E7FFF6EA
      DDFFF5E4D1FFFFF9EBFF1F1E1AA7000000000000000000000000000000000000
      0000000000000000000000000000000000000E080849301C1C83473C3C99F7F3
      F3FFF6F2F2FFF5EFEFFFF1EEEDFF91C295FF29B039FF00EC2AFF037229FA0B25
      1BC13127238C574749951811125674403ED00000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF6E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CEC7BEFFFFFFFFFFFFFFFDFFFFFC
      F4FFFFF3E7FFFFFFFBFF1C1A17A0000000000000000000000000000000030000
      0000000000000000000000000000000000001B101060301C1C83241E1E78F7F4
      F4FFF6F2F2FFF8F0F2FFEEE8E0FF00C42AFF00E265FF00E584FF00FB76FF00A6
      1CF41C14157027212166030302236B3738C90000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFBFAFFFBF7F0FFFAF2
      E9FFF7EDE0FF93846FFF00000000000000000000000000000000000000000610
      047000000010000000000000000000000000AEA597FDCEC7BFFDCDC7BEFDCFC8
      BFFED1CAC1FFD2CDC4FF4B453DCE0E0C0B7F0E0C0A880A090785000000100304
      03440000004800000000000000000000000001000019180D0D5F1B17176FF8F4
      F4FFF6F2F2FFF7EFF1FFF5F2EFFF7ADA8DFF2ECC62FF00FAB3FF168834E21C2D
      1795130F0F53211B1B5E01000014663434C30000000000000000000408400029
      48BF004B89FF000000000000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF000000001E54
      15FF14370ECF0001002000000000000000000000001400000014000000141211
      1064DFD8D0FFEAE4DDFFF7F0E7FFFFF5EAFFFFFDF1FFB9B0A4FF000000091C2F
      1AA80F4808F6000100590000000500000000261616734328289A514242A0F6F2
      F2FFF6F2F2FFF4EEEEFFF8F4F5FFFFFFFFFF84D896FE00C055F938462FAA100B
      0C424A3D3D8A594848971F17175D794242D6000000000017288F045B9DFF1B7A
      D7FB0861B1FF004B89FF004B89FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000093846FFFFAF2E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF000000001E54
      15FF196B15F71B4A13EF03080250000000000000000000000000000000000C0B
      0B4EF4F0E9FFFFFDF6FFFAF0E4FFF7E8D7FFFFF9E8FFA29B92F3000000081423
      139308980AFF186E13FF020701790000000002010120140B0B5A0D0C0C59F9F6
      F6FFF9F6F6FFF4EEEEFFF8F5F5FFFFFFFFFFBDC3BEEE0C09076A161111520000
      000008070733120F0F48000000005D2E2EBA00000000025490FF54ADE6FA62B1
      E7F52986E3F51969DFF5004B89FF00000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF000000000000000000000000000000000000
      000093846FFFFBF7F0FFFAF2E9FFF7EDE0FFF6E7D7FF93846FFF000000001E54
      15FF1E9F20ED1B6916F81E5415FF000000000000000000000000000000000B0B
      0A4FF7F3EFFFFFFFFFFFFDF5ECFFFAEEE0FFFFFEEFFFA29B92F3000000091625
      16931DC226FF13720FFD0003005E00000000130B0B543720208D584948A7FFFF
      FCFFF9F9F9FFFFF8F8FFFDF9F9FFFAF8F8FFFCF7FAFF4132359B5E494A9B1F1A
      1A5A4E3E3E8D5A49499821181860794242D700000000000E1870126397FF78B7
      E0FA126DB2FF004B89FF004B89FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000093846FFFFEFBFAFFFBF7F0FFFAF2E9FFF7EDE0FF93846FFF000000001E54
      15FF278224F61B4A13EF040C0360000000000000002400000035000000280A08
      067CEBE6DFFFEBE9E5FFFBF6F0FFFDF6EDFFF7F3EAFFACA397FF000000041C30
      1BAB10500CEE000000340000000000000000110B0B4E241514771512136AB7B5
      BEEBC4BCBAE68C8C8CD8A29F9FDECBC2C2E8696B6BC60D0A0A4B282020660000
      000D1410104C211B1B5E00000010653333C2000000000000000000040840013D
      69DF004B89FF000000000000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF000000001E54
      15FF14370ECF010300300000000000000000ADA395FFCDC6BDFFCCC5BCFFCEC6
      BCFFD1C9BEFFD2CBC1FF433E35CC0E0D0C691817166912111061000000000607
      0641010101230000000000000000000000000201012025161678160C2B981A14
      176D473837880604043114101051483939880403032D181313583E32327E0404
      0429231D1D63312828730504042C6C3838C90000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000815
      058000000010000000000000000000000000D1CBC3FFFFFFFFFFFFFDF4FFFFF7
      EAFFFCEBDAFFFFFFF4FF1A18159F000000000000000000000000000000000000
      0000000000000000000000000000000000002214146C4C2F30A52E1C52B81A15
      14615F4E4E9C1511114A282121665847479613101047332A2A73564545941310
      10493D32327E4A3D3D8A140F0F4D753F3FD20000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF6E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C8C2B8FFFBF9F6FFF9F2EAFFF7EC
      E0FFF5E5D4FFFFFAECFF211E1BA8000000000000000000000000000000000000
      0000000000000000000000000000000000002517156E41252DA0060014750000
      000F2F242471000000000201011E281E1E6A000000000504042D211919610000
      00000B08083C1611115100000000652E2EC60000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFBFAFFFBF7F0FFFAF2
      E9FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CDC6BBFFFFFFFFFFFFFFFEFFFFFD
      F6FFFFF9EEFFFFFFFDFF231F1BB1000000000000000000000000000000000000
      00000000000000000000000000000000000004030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A331E1E89190D
      0D642C18187F301C1C851A0D0D67412020A50000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000005D5750C567615CC567615DC56763
      5DC567635DC56A665FC5110F0E75000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0101
      011A0000000F0000000C01000019000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000001D12019F754D07FF634006FF1009008000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000686868FF686868FF676767FF676767FF666666FF656565FF656565FF6464
      64FF636363FF636363FF636363FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000008000000000000000000000000000000000000
      0000020100306B4506FF130B008F1D1000AF573402FF06030050000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000010000252F230A91090702630000000A00000000000000000000
      00000000000000000000000000000000000000000000246595FF246595FF2465
      95FF787878FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFEEEEEEFFF6F6F6FF727272FF000000000000000000000006000102440000
      024A070A0C805A5B5CD355565BD65A5C5ED5595B5DD5595A5DD5595B5DD5595A
      5DD55A5D5ED55B5C5DD60202025C000000000000000000000000000000000000
      000002010030613C05FF0603005000000000291700BF2E1B01BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000077D5204CE66460BBFC7831AE91711047F00000001000000000000
      00000000000000000000000000000000000000000000246595FF4C9DC1FF4E9F
      C4FF868686FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF818181FF00000000000000000304042F51A0CAFF51A4
      CCFF6696ACFFF0E3DCFFE0E2ECFFFFF5EBFFFCF2EAFFFBF2E9FFFBF2E9FFFAF1
      E9FFFFF7EEFFF3EBE5FF0404046D000000000000000000000000000000000000
      000000000000361F00DF4E3005EF06030050271600BF341D01BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000101011C955903DA00000004010000239E6514E000000029000000000000
      00000000000000000000000000000000000000000000246595FF4EA0C5FF50A3
      C6FF919191FFF2F2F2FF98A9CBFFE6E6E6FFE6E6E6FFE6E6E6FFE6E6E6FFE5E5
      E5FFE2E2E2FFF0F0F0FF8C8C8CFF0000000000000000040405336BB3D2FF6EC1
      DDFF85B3C2FFCBB7AAFFC7C2C6FFECD8C5FFE6D4C3FFE6D4C3FFE6D4C3FFE5D3
      C3FFEAD6C4FFE3D5C7FF040404690000000002010030130B008F130B008F0402
      00400000000004020040754507FFA46514FF7D4808FF10090080000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000865417CA1A1203870000001393570DDD02010044000000000000
      00000000000000000000000000000000000000000000296B99FF51A4C7FF52A7
      C9FF999999FFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF979797FF00000000000000000404053274B8D5FF68BB
      D9FF83B1C1FFE3D1C6FFD0CDD2FFECDAC9FFE8D8C9FFE8D8C9FFE8D8C9FFE7D7
      C8FFEBDACAFFE8DBCFFF05050569000000004F3203EF583702EF4A2902DF5932
      02FF221300AF00000010130B008FA4590EFF2E1900CF00000000000000000000
      000000000000000000000000000000000000000000000201003D150800890100
      00450000000005030138E38411FFA56411EC6C430BC90000000B000000000000
      000000000000000000000000000000000000000000002F729FFF53A9CAFF54AB
      CCFFA0A0A0FFF6F6F6FF98A9CBFFEEEEEEFFEEEEEEFFEEEEEEFFEDEDEDFFEBEB
      EBFFEAEAEAFFF3F3F3FF9E9E9EFF00000000000000000404053276BAD7FF6BC0
      DDFF88B7C5FFE5D2C7FFD0CDD1FFEDDBC9FFE9D9CAFFE9D9CAFFE9D8C9FFE8D8
      C9FFEBDACAFFEBDED2FF0506066900000000623D02FF1009008000000000180D
      009F91540AFF432602DF04020040492802EF462702DF00000000000000000000
      0000000000000000000000000000000000001C150672996910DC4A2F07A8B56A
      13E813070086000000002D160296DD7B17FF0100003700000000000000000000
      000000000000000000000000000000000000000000003477A4FF55ACCCFF56AF
      CFFFA6A6A6FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFA4A4A4FF00000000000000000404053278BCD8FF6DC3
      DEFF8DBCCBFFE0CDC2FFCECBCFFFEFDCCBFFEADACBFFEAD9CBFFE9D9CAFFE9D8
      CAFFEBDACAFFEEE0D5FF0606066900000000362101CF462A01EF040200400603
      00508F520AFFA55A0EFF683805FF231300BF462903FF0C0A0860000000000000
      000000000000000000000000000000000000A38027CC553807C0000000000403
      002EE18416FF311401B4000000318E440BE20703006400000000000000000000
      000000000000000000000000000000000000000000003C83ADFF57B0D0FF59B2
      D3FFA9A9A9FFF8F8F8FF98A9CBFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF2F2
      F2FFEFEFEFFFF6F6F6FFA7A7A7FF00000000000000000404053279BEDAFF70C7
      E2FF95C4D3FFD4C1B6FFC7C4C9FFF1DECDFFEBDACCFFEBDACCFFEADACBFFEAD9
      CAFFECDACAFFEFE2D6FF060606690000000002010030362000DF543001FF5A32
      02FF522F03EF462705BE271600BF462903FF625B51FF5B5B5BEF030303300000
      000000000000000000000000000000000000070604349C6815D7130800810100
      0034CA7911FDE17B0FFF5B2400D4250F03A341362CC300000010000000000000
      00000000000000000000000000000000000000000000428AB2FF59B4D4FF5BB6
      D7FFACACACFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFABABABFF0000000000000000040405327CC2DDFF73CB
      E4FF93C3D0FFEAD7CBFFD1CED3FFEFDCCBFFECDBCCFFEBDACBFFEBDACBFFEAD9
      CAFFECDBCAFFF0E3D6FF06060669000000000000000000000000040200400402
      004001000020000000000000000005050440595959EFA0A0A0FF565656EF0303
      033000000000000000000000000000000000000000000504022B754D12BBAD6C
      18EC332108940201002421160C71584C42D0A1A9B0FF1616168D000000060000
      000000000000000000000000000000000000000000004791B8FF5BB7D7FF5DBA
      D9FFADADADFFFBFBFBFF98A9CBFFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6
      F6FFF3F3F3FFF8F8F8FFADADADFF0000000000000000030405327DC4DFFF75CF
      E6FF95C6D4FFEAD7CBFFD1CED3FFEFDDCCFFECDBCCFFECDBCCFFEBDACBFFEDDC
      CDFFF0DECEFFF2E5D9FF0707076A000000000000000000000000000000000000
      00000000000000000000000000000000000003030330656565EF7A7A7AFF5A5A
      5AEF030303300000000000000000000000000000000000000000000000000000
      00060000000000000000000000000101011A7D7C7DD2ADADADFF1414148C0000
      000D00000000000000000000000000000000000000004F9AC0FF5EBBD9FF5FBD
      DCFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFB6B6
      B6FFB4B4B4FFBFBFBFFFADADADFF00000000000000000404053280C5DFFF78D3
      EAFF9ACDDAFFE1CEC2FFCECBD0FFF3E1CFFFEEDECEFFEEDECEFFEDDDCEFFE4D2
      C2FFE1CEBCFFF5E7DAFF07070769000000000000000000000000000000000000
      00000000000000000000000000000000000000000000090909507C7C7CFF7575
      75FF666666EF0909095000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000101011C999999F2B2B2B2FF2424
      249F0000000E00000000000000000000000000000000509DC1FF61BFDDFF62C1
      DEFFAFAFAFFFFCFCFCFF98A9CBFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFBCBC
      BCFFE9E9E9FFBABABAFF4343439F00000000000000000404053281C7E1FF7CD9
      F0FF9ACEDBFFD4BFB3FFC5C1C5FFEDD9C7FFE9D7C7FFECDAC9FFF0DCCAFFCDC5
      BDFFEAE9E8FFA4A2A2E400000022000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000191919807676
      76FF5A5A5AEF626262FF0D0D0D60000000000000000000000000000000000000
      0000000000000000000000000000000000000000000008080841A0A0A0FFA4A4
      A4FB2B2B2BA00000000F000000000000000000000000519EC2FF63C2E0FF898C
      8EFF787C7DFF717475FF696C6DFF696C6DFF626566FF626566FF626566FFE2E2
      E2FFBBBBBBFF4343439F0000000000000000000000000404053282CFE9FF7BBF
      CFFF929C9FFFB0B0B0FFA8ABAEFFB0B2B1FFB0B2B1FFA0A2A1FFD6D2D0FFFFF9
      F7FFA2A2A2E10000002800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000002626
      269F4B4B4BDF09090950565656EF0D0D0D600000000000000000000000000000
      00000000000000000000000000000000000000000000000000002222227C3535
      35B61E1E1E8D1E1E1E88000000120000000000000000529FC2FF65C6E2FF66A7
      BAFF696B6BFF717374FF878C8EFF8F9899FF757878FF696A6BFF959595FFAFAF
      AFFF799EAFFF00000000000000000000000000000000040505358FD9F3FF97DD
      EBFF949899FFA4A5A5FFBCC1C2FFC6CFD1FFA7ABABFF9CA0A1FFC4D4D5FFC7EA
      F2FF030608680000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0010404040CF0D0D0D60000000100D0D0D600000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000002A2A
      2A90000000330202023100000019000000000000000053A0C4FF67CAE6FF69CC
      E7FF6E6F6FFFADB2B4FFA3A9AAFFB8C2C4FFB0B5B6FF676868FF74E1F7FF76E3
      F8FF368BB5FF00000000000000000000000000000000000000141A272F83212E
      358730373BA4414343C3A4A8A9F9B3B8BAFD3E4041C72D3336A71E2D3387162A
      3388000000200000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000102E2E2EAF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000101
      011C070707590000000000000000000000000000000054A3C5FF54A3C5FF55A4
      C6FF517587FF577D8EFF697880FF6B7C83FF507586FF527888FF57A9CBFF4AA0
      C5FF4096BCFF0000000000000000000000000000000000000000000000000000
      00000000000000000000515353C7565857D80000000000000000000000000000
      000000000000000000000000000000000000020202221616165F1F1F1F712626
      267D2E2E2E8A2E2E2E89393939983A3A3A9A3A3A3A9A393939982E2E2E892E2E
      2E8A2626267D1F1F1F711414155A0101011A0000000000000000000000000000
      0000000000000000000000000022000000300000003100000026000000020000
      0000000000000000000000000000000000000000000000000000000000000000
      0000696969FF696969FF686868FF676767FF666666FF666666FF656565FF6464
      64FF646464FF636363FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000100000008000000000000000D040404284C4C4CA89292
      92E3939393E49F9FA0ED9D9D9EEC9D9D9EEC9D9D9EEC9D9D9EEC9F9FA0ED9393
      93E4919292E34E4F51A9302B1F8C4F4126AA0000000000000000000000000000
      00090000006F001600C3002901E8002501ED001F00ED001100DB000100A90000
      0055000000090000000000000000000000000000000000000000000000000000
      0000797979FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFF6F6F6FF747474FF00000000000000000000000000000000000000000000
      00000909094B545659D356585BD65C5E5ED55C5E5FD55D5E5FD55D5E5FD55D5E
      5FD55E6062D52B2C2DBB0000000F000000000000000000000000969696D8C4C4
      C5FFB9B6AEFFBBB6AFFFBBB6AFFFBBB6AFFFBBB6AFFFBAB5AEFFBAB5AEFFBAB7
      AFFFC6C9CDFFB3A88EFCAF8427FFAF8D49E70000000000000000000000200018
      00C4007706FF018A08FF018808FF008407FF007906FF006205FF003E02FF0015
      00F00000008A0000001100000000000000000000000000000000000000000000
      0000888888FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFF838383FF00000000000000000000000000000000000000000000
      000014141461DFD9D6FFD8DAE3FFFFF5EBFFFBF2EAFFFBF1E9FFFAF1E8FFF9F0
      E7FFFFFFF7FF787674E70000000D000000000000000000000000959595D6C6C6
      C6FFC1C1BEFFBDB9B4FFBDBAB6FFBEBBB6FFBEBAB5FFC2C1C0FFC2C1C0FFC3C4
      C4FFBEB8ABFFAA7E25FFD2A85AFF0605032B0000000000000019002800D904A0
      12FF02A90DFF019F0AFF009D07FF009B00FF009B00FF009E07FF018B09FF005A
      05FF002000FD00000088000000090000000000000000696969FF696969FF6262
      62FF939393FFF3F3F3FF98A9CBFFE7E7E7FFE7E7E7FFE7E7E7FFE6E6E6FFE3E3
      E3FFF0F0F0FF909090FF000000000000000000000000000000000000000E0000
      00070B0B0B6EEADDD2FFCCC8CCFFE7D2C0FFE4D2C1FFE3D1C0FFE3D1C0FFE1CF
      BEFFF6E2D0FF6B6662DD0000000E0000000000000000000000009A9A9AD6CCCC
      CCFFCACBCAFFC2C0BBFFC3C1BCFFC0BDB9FFBDBAB5FFB9B9B8FFB2B2B2FFB2B4
      B6FFB1A68DFFCA9E45FF1C170E560000000000000000001600B00AA523FF09AD
      1FFF05A014FF009C07FF0CA211FF9BDBA0FF7DD083FF009800FF00A006FF0196
      0AFF005E05FF001A00F3000000530000000000000000797979FFF7F7F7FF8E96
      AAFF9D9D9DFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFF999999FF0000000000000000000000000606063C6E7072E76D70
      77E78A8A8AF2E0D5CCFFCECBD0FFEAD8C7FFE7D7C9FFE7D7C8FFE6D6C8FFE5D5
      C6FFF8E7D6FF716B68DD0000000E0000000000000000000000009D9D9DD6D1D1
      D1FFCFCECEFFB4B0A6FFB5B0A6FFC9C8C5FFC3C4C4FFC2C2C2FFDADADBFFDADA
      DAFFBEC0C4FFA1A19DE100000000000000000002006C0B7F22FE11B636FF0BA6
      27FF09A41EFF009D0BFF23AE2EFFFFFFFFFFFFFFFFFF83D289FF009500FF00A1
      06FF018D09FF004E03FF000200A70000000400000000888888FF7C7C7DFF8E96
      AAFFA3A3A3FFF6F6F6FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEBEB
      EBFFF4F4F4FFA0A0A0FF0000000000000000000000000A0A0A49DDD5CFFFD9D9
      E2FFD8D2CBFFDAD0C8FFCFCCD0FFECDAC9FFE9D9CAFFE9D8CAFFE8D8C9FFE7D6
      C8FFF8E6D6FF736F6BDD0000000E000000000000000000000000A2A2A2D6D6D6
      D6FFD4D3D1FFD5D5D5FFD5D5D5FFD3D4D2FFC3C3C3FFDDDDDCFFE2E1E0FFE5E4
      E5FFDFDFDFFFCECECFFF0000000000000000033E09D515A83FFF12AF3DFF00A3
      24FF00A119FF009D0FFF009500FF42B94DFFF0F9F1FFFFFFFFFF6DCA74FF0094
      00FF009C08FF017808FF001900DA0000002300000000939393FFF3F3F3FF8E96
      AAFFA7A7A7FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFA6A6A6FF000000000000000000000000090A0A46DDCFC4FFCFCB
      CFFFCAC1B7FFD8CEC7FFCDCACEFFEEDCCBFFEADACBFFEAD9CBFFE9D9CAFFE8D8
      C9FFF8E6D6FF75716DDD0000000E000000000000000000000000A4A4A4D6DBDC
      DDFFBEB8B1FFC2BEB8FFC2BEB7FFC4C1BBFFCFCFD0FFD4D1CDFFD6D4CFFFDAD8
      D4FFE7E7E7FFD8D8D8FF00000000000000000D8426FF18B04BFF1FB34FFF5FC9
      7DFF66CA7EFF60C876FF5CC56DFF48BB50FFAFE3B6FFFFFFFFFFFFFFFFFF6AC8
      70FF009901FF009808FF003502ED00000031000000009D9D9DFFD9B08CFF8E96
      AAFFABABABFFFAFAFAFF98A9CBFFF6F6F6FFF6F6F6FFF4F4F4FFF3F3F3FFF2F2
      F2FFF7F7F7FFAAAAAAFF0000000000000000000000000A0A0A46E0D4CAFFCFCC
      D0FFD0C7BEFFCCC2BAFFC7C5C9FFF1DFCDFFECDCCDFFEBDBCCFFEBDBCCFFEADA
      CBFFF8E6D5FF777370DD0000000E000000000000000000000000A8A8A8D6DEDE
      DEFFDDDEDFFFBCB8AFFFBFBBB2FFBAB6ACFFD7D6D5FFD6D6D6FFECECECFFEBEB
      ECFFD2D2D2FFB7B7B7E200000000000000000F8E2CFF22B755FF5DC984FFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFF25AD2DFF00A300FF003D03ED0000003100000000A3A3A3FFF6F6F6FF8E96
      AAFFADADADFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFACACACFF0000000000000000000000000A0A0A46E4D8CEFFD0CD
      D1FFCEC5BCFFE1D7CFFFD1CED3FFF0DDCCFFEDDCCDFFECDCCDFFECDBCBFFEFDE
      CEFFFAE8D7FF787471DD0000000E000000000000000000000000AAAAAAD6E2E2
      E2FFDFDEDEFFBAB5ACFFBBB6ADFFD7D5D2FFE2E2E3FFDFDFDFFFD9D9D9FFDADA
      DAFFE1E1E1FFBEBEBEE40000000000000000078B23FE4FC679FF4FC679FF89D8
      A5FF9ADEB3FF98DDB0FF94DBA8FF7BD292FFC3EBCCFFFFFFFFFFFFFFFFFF82D2
      8AFF029B05FF00A608FF003902E90000002100000000A7A7A7FF7C7C7DFF8E96
      AAFFADADADFFFBFBFBFF98A9CBFFFAFAFAFFFAFAFAFFF8F8F8FFA5A5A5FFA5A5
      A5FFBFBFBFFFADADADFF0000000000000000000000000A0A0A46DED2C7FFCBC8
      CCFFD1C8BEFFDFD5CDFFD0CDD2FFF1DECDFFEDDDCDFFEDDCCCFFEEE0D4FFDBCD
      C1FFEDDAC8FF85827CE40000000B000000000000000000000000ADADADD6E8E6
      E5FFECE8E6FFEFECE9FFEFECE9FFEDE9E7FFECE8E5FFECE8E6FFEAE6E3FFEBE7
      E4FFE8E6E5FFC2C2C2E40000000000000000005001CD51C276FF7ED9A2FF05AB
      3DFF04A93BFF08AB3EFF00A62EFF4CC26CFFE8F7EBFFFFFFFFFF81D28EFF009A
      02FF00A10CFF019D0BFF001800C50000000200000000ABABABFFFAFAFAFF8E96
      AAFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFA5A5A5FFF2F2
      F2FFC9C9C9FF737373CF0000000000000000000000000A0A0A46D8CCC1FFC6C2
      C7FFD0C7BDFFE0D5CCFFD1CDD1FFF0DCC9FFEDDBCAFFEFDCCBFFE4D3C4FFB3B0
      AEFFEFECEAFF474747BC00000000000000000000000000000000B2B1AFD6C7D8
      E5FF9DC4E0FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FF9DC4
      E0FFC7D8E5FFC8C6C5E40000000000000000030E025B1AA43AFDAAE9C7FF70D2
      93FF0DAE43FF05A93BFF39BD67FFFFFFFFFFFFFFFFFF6BCC84FF009E14FF06A3
      1EFF08B01DFF027C0BFF0000006E0000000000000000ADADADFFD9B08CFF8E96
      AAFFAFAFAFFFFEFEFEFF98A9CBFFFEFEFEFFFEFEFEFFFCFCFCFFBBBBBBFFBDBD
      BDFF737373CF000000100000000000000000000000000A0A0A46EADDD3FFD2CE
      D3FFD2C9BFFFD7D9DCFFCFD5E2FFFFFFFDFFFFFFFEFFFFFFFDFFFBF9F8FFFCFD
      FDFF747576D70000001700000000000000000000000000000000B3B3B1D667AE
      E2FF0078DAFF007CDAFF007CDAFF007CDAFF007CDAFF007CDAFF007CDAFF007D
      E3FF6DB8EEFFD4D4D4E90000000000000000000000000231069B45C46CFFCBF3
      DEFF85D8A3FF22B654FF19B24DFF8BD9A7FF62CB86FF00A730FF11AB36FF10B2
      32FF0AA623FF001900C90000000A0000000000000000ADADADFFFBFBFBFF8E96
      AAFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFF7373
      73CF00000010000000000000000000000000000000000A0A0A46E7DBD0FFD1CD
      D1FFD2C9C0FFCED1D4FFCBCED4FFDADBDDFFCCCDCEFFCFD0D1FFE2E3E4FF4F4F
      4FB8000000140000000000000000000000000000000000000000B3B3B2D6A7CF
      ECFF68B9EEFF6DBCEEFF6DBCEEFF6DBCEEFF6DBCEEFF6DBCEEFF6DC1F7FF7B80
      82FF736E69FF1414146700000000000000000000000000000009004F01BF45C4
      6CFFBCEED4FFBBECCFFF83D7A2FF53C87CFF4AC576FF4CC879FF2AC15BFF10AE
      34FF002C02D800000021000000000000000000000000AFAFAFFF7C7C7DFF8E96
      AAFFB5AAA0FFB5AAA0FFB5AAA0FFB5AAA0FFA5A5A5FFB8B8B8FF737373CF0000
      000000000000000000000000000000000000000000000A0A0A46E7DBD0FFD0CD
      D2FFEBDAC9FFE3D3C3FFE6D5C5FFDCCCBDFFB8B4B1FFECECECFF525252C50000
      0000000000000000000000000000000000000000000000000000B7B7B7D9F3EF
      EDFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFFFFEF9FF605F
      5DFF0E0E0E650000000000000000000000000000000000000000000000070330
      06991B9936F35EC882FF84D7A2FF7ED7A0FF61CC88FF34B85FFF11892FF6001E
      03AC0000001800000000000000000000000000000000AFAFAFFFFEFEFEFF98A9
      CBFFFEFEFEFFFEFEFEFFFCFCFCFFFBFBFBFFBDBDBDFF737373CF000000100000
      000000000000000000000000000000000000000000000A0A0A46E0E0E1FFCAD1
      DFFFFFFFFEFFFEFDFCFFFEFDFCFFFBFAF9FFEEEEEDFF6B6B6BCD000000160000
      0000000000000000000000000000000000000000000000000000545454939C9C
      9CCF989898CC989898CC989898CC989898CC989898CC989898CCA7A7A7D10B0B
      0B62000000000000000000000000000000000000000000000000000000000000
      00000310025E005100C600971FFF069827FF038F20FF004905CF0006006F0000
      00000000000000000000000000000000000000000000AFAFAFFFAFAFAFFFAFAF
      AFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFF737373CF00000010000000000000
      000000000000000000000000000000000000000000000A0A0A46DADBDCFFCCD0
      D7FFDFE0E1FFDFDFE0FFDEDFDFFFE5E5E6FFA6A6A6E600000020000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000002200000039010000550100005E0101005D0101
      005D0101005D0101005700000011000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000005000000030000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000002030155032A01DD28271FB4F5EFE7FFEFE8DFFFEEE5DBFFEDE4
      D8FFF3ECE1FF766E64E80000000D000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000534C44CD635E57D4635E59D5635F
      59D5635F59D56A645CD6100F0C90000000010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000009007F108E1EFF004A01F11F1B18A2FFFFFFFFFFFAF1FFFCF0E4FFF9E8
      D6FFFFFFEFFF6D6762DD0000000E000000000000000000000000000000000004
      0840002948BF004B89FF000000000000000000000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000D6CFC5FFFFFFFFFFFFFFF8FFFFFD
      F1FFFFF9E8FFFFFFFFFF262320AF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000193516B260E36DFF07610EE71E1917A4FFFFFFFFFFFBF5FFFAF2E8FFF7E9
      DCFFFFFFF2FF6B665FDD0000000E0000000000000000000000000017288F045B
      9DFF1B7AD7FB0861B1FF004B89FF004B89FF0000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C9C2B9FFFBF6F1FFF8EFE5FFF6EA
      DDFFF5E4D1FFFFF9EBFF201E1BA8000000000000000000000000000000000000
      0000000000000000000000000000000000000000000A000000190000001C0000
      0019000000100A1C09AE0B5713F325221BB2FFFFFFFFFFFFFCFFFFFAF4FFFEF6
      EEFFFFFFFBFF7E766BF00000000B000000000000000000000000025490FF54AD
      E6FA62B1E7F52986E3F51969DFF5004B89FF00000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF93846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CEC7BEFFFFFFFFFFFFFFFEFFFFFD
      F7FFFFF8EDFFFFFFFFFF25221FAA000000000000000000000000000000000000
      000000000000000000000000000000000003797064E8918B83ED928C84EE928C
      84EE908782E8897F7BE6232A1AC7060605583733309533302D9533302D953331
      2E9534322F951B1A177A00000000000000000000000000000000000E18701263
      97FF78B7E0FA126DB2FF004B89FF004B89FF0000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000010300301B4A13EF00000000000000000000
      000000000000000000000000000000000000AEA597FDCEC7BFFDCDC7BEFDCCC5
      BDFDD3CCC3FDD4CDC5FA1915148C000000300202015C0E0C0A840D0C0A890D0C
      0A890E0C0B890E0D0B890705057600000008D5CFC6FFFFFFFFFFFFFFF6FFFFFC
      EFFFFFF7E5FFFFFFFFFF201C1BA2000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000004
      0840013D69DF004B89FF000000000000000000000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF040C03601B4A13EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF0000001400000014000000140000
      0014000000140000000C020B028A043200EB302F27BBFFFFFEFFFFFBF2FFFFF7
      EDFFFFF4E7FFFFFFF3FF7C756BE600000000C9C2B9FFFBF7F2FFF8F0E6FFF6EB
      DFFFF6E5D3FFFFFAECFF211E1BA8000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000091A068F206719FF149616FF1E5415FF0000000093846FFFFAF2
      E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF0000000000000000000000000000
      0000000000000218029F1CAC2DFF004601E9231F1DA6FFFFFFFFFFF6EDFFFAEE
      E1FFF7E5D3FFFFFDECFF65605AD500000000D4CDC3FFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFF6FFFFFFFFFF24211EAC000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000000000
      0000040C03601E5415FF51CF5AFF33CE39FF1E5415FF0000000093846FFFFBF7
      F0FFFAF2E9FFF7EDE0FFF4E7D7FF93846FFF0000000000000000000000000000
      00000000000010200D9462DA6DFF086210EB231D1AA7FFFFFFFFFFFEF9FFFDF5
      EDFFFAEDE0FFFFFFF6FF646059D500000000625B52D577726CDA77726CDA7772
      6CDA77726CDA7C7770DB12100D8F000000020000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000061004702A6522FF37BC3CFF1E5415FF0000000093846FFFFEFC
      FAFFFBF7F0FFFAF0E7FFF7EDE0FF93846FFF0000002400000035000000380000
      003800000035000000230A14099306430BE525221CB4FAF7F3FFF8F4EFFFF6F0
      EAFFF4EEE5FFF9F7EFFF716A60E600000000221E19A027241FAC282520AD2825
      20AD282521AD2C2822AE0907067B000000040000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF030802501B4A13EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFFADA395FFCDC6BCFFCCC5BBFFCCC4
      BAFFCCC3B9FFD5CCC3FF19151397000000250707074317161569161614691616
      146916161469171614690C0C0B5300000000D4CDC1FFFFFFFCFFFFFEF4FFFFFB
      F0FFFFF7E9FFFFFFFBFF26231FB0000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF000000000103003014370ECF00000000000000000000
      000000000000000000000000000000000000D1CCC3FFFFFFFDFFFFFAEFFFFFF6
      E9FFFFF0DEFFFFFFF8FF221F1DAA000000000000000000000000000000000000
      000000000000000000000000000000000000CAC3BBFFFCF7F1FFF9EFE3FFF7EB
      DCFFF6E4D1FFFFFAECFF211E1CA8000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C9C2B9FFFBF8F3FFF9F0E6FFF6EB
      DFFFF6E6D5FFFFFAEDFF211E1BA8000000000000000000000000000000000000
      000000000000000000000000000000000000CCC5BCFFFFFFFFFFFFFCF6FFFFF6
      EDFFFEF2E4FFFFFFF9FF211F1BA9000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CDC6BBFFFFFFFFFFFFFFFDFFFFFD
      F7FFFFFAF0FFFFFFFFFF231F1BB1000000000000000000000000000000000000
      000000000000000000000000000000000000BBB3A6FFE6E2DEFFE5E1DBFFE5DF
      D9FFE5DED6FFE9E6DEFF1C1A169F000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000005D5750C567615CC567635DC56763
      5DC567635DC56A665FC5110F0E75000000000000000000000000000000000000
      0000000000000000000000000000000000001F1D1A001D1B187E1E1B187E1E1C
      197E1E1C197E1F1D1A7E07060645000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000F00000000100010000000000800700000000000000000000
      000000000000000000000000FFFFFF00FFFFFC01FC010000C003FC01FC010000
      DFFBFC01FC010000D00BFC01FC010000DFFBFC01FC010000D00B800180010000
      DFFB8001BC010000D00B8001BC010000DFFB8003BC030000D00B8007BC070000
      DFFB800FBC0F0000D043803FBFBF0000DFD7803FBC3F0000DFCF807FBD7F0000
      C01F80FFBCFF0000FFFF81FF81FF0000FFFFFFFFFFFFFFFFFFFFFFFFFFFFC003
      FFFFFFFFFFFFC0039F3F87C387C3C0038F1F83838383C003870FC107C107C003
      8307E00FE00FC0038103F01FF01FC0038001F83FF83FC0038103F01FF01FC003
      8307E00FE00FC003870FC107C107C0038F1F83838383C0079F3F87C387C3C00F
      FFFFFFFFFFFFC01FFFFFFFFFFFFFFFFF000000000000FFFF000000000000FFFF
      000000000000FFFF0000000000009F3F0000000000008F1F000000000000870F
      0000000000008307000000000000810300000000000080010000000000008103
      0000000000008307000000000000870F0000000000008F1F0000000000009F3F
      000000000000FFFF000000000000FFFF00000000000000000000000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000}
  end
  object ilCalc: TImageList
    ColorDepth = cd32Bit
    Left = 200
    Top = 544
    Bitmap = {
      494C010143004800040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      0000000000003600000028000000400000001001000001002000000000000010
      0100000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC00999999000000000000000000CC996600FFCC9900FFCC
      9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900CC99
      6600CC99660099330000000000000000000000000000B2B2B200CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00B2B2
      B200B2B2B2009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000CC996600CC996600CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      660099330000CC9966009933000000000000B2B2B200B2B2B200B2B2B200B2B2
      B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2
      B20099999900B2B2B20099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFCC9900FFCC
      9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC
      9900CC996600993300009933000000000000B2B2B20000000000CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00B2B2B2009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFCC9900FFCC
      9900FFCC9900FFCC990000CC000000990000FFCC99000000FF000000CC00FFCC
      9900CC996600CC9966009933000000000000B2B2B20000000000CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00B2B2B20099999900CCCCCC00B2B2B20099999900CCCC
      CC00B2B2B200B2B2B20099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00999999009999990099999900999999009999990099999900CCCC
      CC00CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600CC996600CC99660099330000B2B2B20000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B2B2B200B2B2B200B2B2B200999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000CC996600FFFFFF00FFCC9900FFCC
      9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC9900FFCC
      9900CC996600CC996600CC99660099330000B2B2B20000000000CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00B2B2B200B2B2B200B2B2B200999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00999999009999990099999900999999009999990099999900999999009999
      9900CCCCCC00CCCCCC00999999000000000000000000CC996600CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600FFCC
      9900FFCC9900CC996600CC9966009933000000000000B2B2B200B2B2B200B2B2
      B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200CCCC
      CC00CCCCCC00B2B2B200B2B2B200999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC99
      6600FFCC9900FFCC9900CC996600993300000000000000000000B2B2B2000000
      000000000000000000000000000000000000000000000000000000000000B2B2
      B200CCCCCC00CCCCCC00B2B2B200999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC009999
      9900FFFFFF00999999009999990099999900999999009999990099999900FFFF
      FF0099999900CCCCCC009999990000000000000000000000000000000000CC99
      6600FFFFFF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFFFF00CC99
      6600CC996600CC9966009933000000000000000000000000000000000000B2B2
      B20000000000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC0000000000B2B2
      B200B2B2B200B2B2B20099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC009999990000000000000000000000000000000000CC99
      6600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00CC996600000000000000000000000000000000000000000000000000B2B2
      B200000000000000000000000000000000000000000000000000000000000000
      0000B2B2B2000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900E5E5E5009999
      9900FFFFFF00999999009999990099999900999999009999990099999900FFFF
      FF00999999009999990099999900000000000000000000000000000000000000
      0000CC996600FFFFFF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFF
      FF00CC9966000000000000000000000000000000000000000000000000000000
      0000B2B2B20000000000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC000000
      0000B2B2B2000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC0099999900000000000000000000000000000000000000
      0000CC996600FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000000000000000
      0000B2B2B2000000000000000000000000000000000000000000000000000000
      000000000000B2B2B20000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      000000000000CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000000000000000
      000000000000B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2B200B2B2
      B200B2B2B200B2B2B20000000000000000000000000000000000000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300009933000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000999999000000000000000000000000003399CC00006699000066
      9900006699000066990000669900006699000066990000669900006699000066
      990066CCCC000000000000000000000000000000000099999900999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900CCCCCC000000000000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC003399CC0099FFFF0066CC
      FF0066CCFF0066CCFF0066CCFF0066CCFF0066CCFF0066CCFF0066CCFF003399
      CC00006699000000000000000000000000009999990099999900E5E5E500CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999000000000000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC003399CC0066CCFF0099FF
      FF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF00006699003399CC0000000000000000009999990099999900CCCCCC00E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00999999009999990000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC003399CC0066CCFF0099FF
      FF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF0066CCCC000066990000000000000000009999990099999900CCCCCC00E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00CCCCCC009999990000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC0066CCFF003399CC0099FF
      FF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF0099FFFF00006699003399CC000000000099999900CCCCCC0099999900E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00E5E5E5009999990099999900000000000000000099330000CC660000CC66
      0000CC660000993300009933000099330000993300009933000099330000CC66
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC0066CCFF0066CCCC0066CC
      CC0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0099FFFF0066CC
      FF0099FFFF0066CCCC00006699000000000099999900CCCCCC00CCCCCC00CCCC
      CC00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500CCCC
      CC00E5E5E500CCCCCC0099999900000000000000000099330000CC660000CC66
      0000CC660000CC660000CC660000CC660000CC660000CC660000CC660000CC66
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC0099FFFF0066CCFF003399
      CC00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF0099FF
      FF00CCFFFF00CCFFFF00006699000000000099999900E5E5E500CCCCCC009999
      9900E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500E5E5E500E5E5E50099999900000000000000000099330000CC660000CC66
      0000993300009933000099330000993300009933000099330000993300009933
      0000CC660000CC66000099330000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000003399CC0099FFFF0099FFFF0066CC
      FF003399CC003399CC003399CC003399CC003399CC003399CC003399CC003399
      CC003399CC003399CC0066CCFF000000000099999900E5E5E500E5E5E500CCCC
      CC00999999009999990099999900999999009999990099999900999999009999
      99009999990099999900CCCCCC00000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000003399CC00CCFFFF0099FFFF0099FF
      FF0099FFFF0099FFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF00CCFFFF000066
      99000000000000000000000000000000000099999900E5E5E500E5E5E500E5E5
      E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009999
      9900000000000000000000000000000000000000000099330000CC6600009933
      0000FFFFFF00993300009933000099330000993300009933000099330000FFFF
      FF0099330000CC66000099330000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC0000000000999999009999
      990099999900999999000000000000000000000000003399CC00CCFFFF00CCFF
      FF00CCFFFF00CCFFFF003399CC003399CC003399CC003399CC003399CC000000
      0000000000000000000000000000000000000000000099999900E5E5E500E5E5
      E500E5E5E500E5E5E50099999900999999009999990099999900999999000000
      0000000000000000000000000000000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999000000
      00009999990000000000000000000000000000000000000000003399CC003399
      CC003399CC003399CC0000000000000000000000000000000000000000000000
      0000000000009933000099330000993300000000000000000000999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000009999990099999900999999000000000099330000E5E5E5009933
      0000FFFFFF00993300009933000099330000993300009933000099330000FFFF
      FF00993300009933000099330000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099330000993300000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900999999000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099330000000000000000
      0000000000009933000000000000993300000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000009999990000000000999999000000000099330000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300009933000099330000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000993300009933
      0000993300000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC00006699000066990000669900006699000066
      9900006699000066990000669900000000000000000000000000000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00000000009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC000000000099999900000000000000000000000000CC996600CC996600CC99
      6600CC996600CC9966003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900999999009999
      9900999999009999990099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC003399CC003399CC003399CC00000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999009999990099999900000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00CCFFFF000066990000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900CCCCCC009999990000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00006699000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC003399CC003399CC003399CC003399CC003399
      CC00000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000000000000999999000000
      0000CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC0000000000999999009999
      99009999990099999900000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFFFF00CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999000000
      00009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC996600CC996600CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600E5E5
      E500CC9966000000000000000000000000000000000000000000999999000000
      0000000000000000000000000000000000000000000000000000999999009999
      99000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600E5E5E500CC99660000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900000000009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600CC99
      6600000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC9966000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC9966000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000CC996600CC996600CC99
      6600CC996600CC996600CC996600000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC996600CC99
      6600CC996600CC99660000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900999999000000
      0000000000000000000000000000000000009999990099999900000000000000
      000000000000000000000000000000000000000000000000FF00000099000000
      99000000990000000000000000000000000000000000000000000000FF000000
      99000000990000009900000000000000000000000000B2B2B200808080008080
      8000808080000000000000000000000000000000000000000000B2B2B2008080
      8000808080008080800000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC009999
      99000000000000000000000000000000000099999900CCCCCC00999999000000
      000000000000000000000000000000000000000000000000FF000000CC000000
      CC000000CC00000099000000000000000000000000000000FF000000CC000000
      CC000000CC0000009900000000000000000000000000B2B2B200999999009999
      99009999990080808000000000000000000000000000B2B2B200999999009999
      9900999999008080800000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC009999990000000000000000000000000099999900CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000000000000000FF000000
      CC000000CC000000CC0000009900000000000000FF000000CC000000CC000000
      CC00000099000000000000000000000000000000000000000000B2B2B2009999
      990099999900999999008080800000000000B2B2B20099999900999999009999
      9900808080000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000000000000000000000000
      FF000000CC000000CC000000CC00000099000000CC000000CC000000CC000000
      990000000000000000000000000000000000000000000000000000000000B2B2
      B200999999009999990099999900808080009999990099999900999999008080
      8000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00999999000000000099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC009999990000000000000000000000000000000000000000000000
      00000000FF000000CC000000CC000000CC000000CC000000CC00000099000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B2B2B2009999990099999900999999009999990099999900808080000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC009999990099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000FF000000CC000000CC000000CC0000009900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000B2B2B20099999900999999009999990080808000000000000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00999999000000000099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC009999990000000000000000000000000000000000000000000000
      00000000FF000000CC000000CC000000CC000000CC000000CC00000099000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000B2B2B2009999990099999900999999009999990099999900808080000000
      0000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5
      E500FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000000000000000000000000
      FF000000CC000000CC000000CC00000099000000CC000000CC000000CC000000
      990000000000000000000000000000000000000000000000000000000000B2B2
      B200999999009999990099999900808080009999990099999900999999008080
      8000000000000000000000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF00FFFFFF00CC99660000000000000000000000000099999900CCCCCC00CCCC
      CC009999990000000000000000000000000099999900CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000000000000000FF000000
      CC000000CC000000CC0000009900000000000000FF000000CC000000CC000000
      CC00000099000000000000000000000000000000000000000000B2B2B2009999
      990099999900999999008080800000000000B2B2B20099999900999999009999
      9900808080000000000000000000000000000000000000000000CC996600FFFF
      FF00E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500FFFFFF00CC996600CC99
      6600CC996600CC99660000000000000000000000000099999900CCCCCC009999
      99000000000000000000000000000000000099999900CCCCCC00999999000000
      000000000000000000000000000000000000000000000000FF000000CC000000
      CC000000CC00000099000000000000000000000000000000FF000000CC000000
      CC000000CC0000009900000000000000000000000000B2B2B200999999009999
      99009999990080808000000000000000000000000000B2B2B200999999009999
      9900999999008080800000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600E5E5
      E500CC9966000000000000000000000000000000000099999900999999000000
      0000000000000000000000000000000000009999990099999900000000000000
      000000000000000000000000000000000000000000000000FF000000FF000000
      FF000000FF0000000000000000000000000000000000000000000000FF000000
      FF000000FF000000FF00000000000000000000000000B2B2B200B2B2B200B2B2
      B200B2B2B2000000000000000000000000000000000000000000B2B2B200B2B2
      B200B2B2B200B2B2B20000000000000000000000000000000000CC996600FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600CC99
      6600000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000CC996600CC99
      6600CC996600CC996600CC996600CC996600CC996600CC996600CC9966000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000D0D5BBF1717A3FF1717A3FF0D0D5BBF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      000000000000000000000000000000000000EEDDCD00EEDDCD00EEDDCD00EEDD
      CD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDDCD00EEDD
      CD00EEDDCD00EEDDCD00EEDDCD00EEDDCD000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF1717A3FF8484F6FF5F5FEDFF1717A3FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0A0A8CFF6969F3FF4444E7FF0A0A8CFF000000000000
      000000000000000000000000000000000000EDDCCC00EDDDCC00EFDFCF00EDDD
      CD00F1E1D000F2E3D200F1E1D000F1E1D000F1E0D000F1E1D000F1E1D000F2E3
      D200F0E0D000EEDDCD00EDDDCD00EDDDCD000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000929292FF000000000000
      000000000000000000000D0D5BBF1717A3FF1717A3FF0D0D5BBF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      000000000000000000000000000000000000EDDCCC00ECDCCC00E2D0C100EDDD
      CD00DBC8B900CDB8AB00D5C1B600D6C3B600D5C1B300D5C2B500D4C1B500CDB8
      AB00D7C3B500E8D8C800ECDCCC00ECDCCC000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000929292FF000000000000
      00000000000000000000174F17BF2A8F29FF2A8F29FF174F17BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      000000000000000000000000000000000000ECDBCB00F0E0D000D4C0B100C9B1
      A300C7B0A100BDA69A00B5A09500AE989400C3B2B200AD969100B6A09600C3AC
      A000E5D1C100EEDCCB00F0E0CF00ECDBCB000000000099330000993300000000
      0000000000000000000000000000000000009933000099330000000000000000
      00000000000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF2A8F29FF87E087FF60CC60FF2A8F29FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF177516FF6CD76CFF45BD45FF177516FF000000000000
      000000000000000000000000000000000000EEDDCD00EBD9C900CEB8AC00C5AF
      A500B59D9500C3ACA200CBB6AA00B29C9800CCBCBC00B59C9700CCB7AB00CCB9
      AE00CDB9AE00CAB5AB00CEB8AB00F1DFCF000000000099330000CC6600009933
      00000000000000000000000000000000000099330000CC660000993300000000
      00000000000000000000000000000000000000000000929292FF000000000000
      00000000000000000000174F17BF2A8F29FF2A8F29FF174F17BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      000000000000000000000000000000000000F4E3D100DAC5B600CEBFBF00EDE8
      EB00ECE6E800ECE5E700EFE9EC00DFD6D700A58D8C00E6DEE000EDE8EB00E8E2
      E600EAE3E400F2E8E600CFBFBE00DDC7B6000000000099330000CC660000CC66
      00009933000000000000000000000000000099330000CC660000CC6600009933
      00000000000000000000000000000000000000000000929292FF000000000000
      00000000000000000000115B81BF1EA4E7FF1EA4E7FF115B81BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      000000000000000000000000000000000000F5E4D200D7C1B200C5B1AD00DACC
      C500D5C6BF00D5C6BE00D8C8BF00D4C4BB00BAA59D00D2C2BA00D7C8BF00DCCC
      C500CFBDB7009691A200B29E9C00DFC9B8000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      00009933000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF1EA4E7FF56FFFFFF23FFFFFF1EA4E7FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0E8EE0FF3CFFFFFF12FFFFFF0E8EE0FF000000000000
      000000000000000000000000000000000000F3E2D200D9C2B400D4B6A000E7C9
      BB00E4C7BA00DFC2B200DEBAA700E1BFAE00EACEC100E1C2B300DFBBAA00F3CF
      A50091858D00656C9300BF9B8200E1CCBE000000000099330000CC660000CC66
      0000CC660000CC660000993300000000000099330000CC660000CC660000CC66
      0000CC66000099330000000000000000000000000000929292FF000000000000
      00000000000000000000115B81BF1EA4E7FF1EA4E7FF115B81BF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      000000000000000000000000000000000000F2E1D100D9C3B400E1C7AF00EDD4
      C800E0C4BF00F3D9DD00F4D8DB00F5D4D800F2D4D700E4C9C300F2D5C300D5B9
      A3005A699B00B59E9500ECCAA700D7C3B6000000000099330000CC660000CC66
      0000CC660000CC660000CC6600009933000099330000CC660000CC660000CC66
      0000CC660000CC6600009933000000000000552300BF9A3F00FF9A3F00FF5523
      00BF000000000000000000000000000000000000000001010A401717A3FF0101
      0A400000000001010A401717A3FF01010A40481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000F3E0D000D9C3B400E0C5AC00F6DE
      C000F4DABC00DDC1B100DFC3C400DFBEBD00D2B19D00D9BDA200DFC3A300B99B
      8800937F8000F9DAB400E4C4A600D7C2B6000000000099330000CC660000CC66
      0000CC660000CC660000993300000000000099330000CC660000CC660000CC66
      0000CC6600009933000000000000000000009A3F00FFEAC83AFFDCA216FF9A3F
      00FF00000000000000000000000000000000000000001717A3FF3232DAFF1717
      A3FF01010A401717A3FF0202B1FF1717A3FF822700FFE3B823FFD18B09FF8227
      00FF000000000000000000000000000000000000000000000000A09281FFA092
      81FFA09281FFA09281FFA09281FFA09281FFF2E0D000DAC3B400DEC2AA00E6CB
      B100EFD6BA00FBE3C500ECD4BB00D6B9A000BC9A8000D1B09400D6B59900C19E
      8500DBB89700FFE7C000DEBFA200D7C2B6000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      000099330000000000000000000000000000552300BF9A3F00FF9A3F00FF5523
      00BF000000000000000000000000000000000000000001010A401717A3FF2B2B
      E6FF1717A3FF1616C3FF1717A3FF01010A40481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFFBA7758FF9D3F12FFF2DECAFFA09281FFF3E1D100DAC4B500DEC2AA00E7CC
      B200DEC3AB00E9D0B600FBE4C700D6B69B00D2B49400A0967100A1987300C2AD
      8B00D9B69A00EDCDAC00E1C3A500D8C3B7000000000099330000CC660000CC66
      00009933000000000000000000000000000099330000CC660000CC6600009933
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000001010A401717
      A3FF2828E4FF1717A3FF01010A40000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFF96360EFFCB7A3DFFAA562BFFA09281FFF6E6D800DAC5B800E0C5AD00F3DA
      BE00EFD4BA00F0D7BB00EDD3B800E2C4A700EBCEAE00A89B7E00AEAD8A00C6B5
      9400EFCDAC00E5C3A300E6C6A700D7C5BA000000000099330000CC6600009933
      00000000000000000000000000000000000099330000CC660000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001010A401717A3FF9D9D
      F7FF1717A3FF5454DEFF1717A3FF01010A400000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFF96360EFF96360EFFAB4C17FFA78168FFF6E6D900E1CCC100CBAF9C00EBD2
      B900EBD2B900EDD3BA00DEC3AC00CDB09A00FFF5DE00D2BCA6009D917B00D2BA
      A300E5C3A400D1AF9500CFB19A00E6D5CA000000000099330000993300000000
      0000000000000000000000000000000000009933000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000001717A3FFCCCCFCFF1717
      A3FF01010A401717A3FF6262D4FF1717A3FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFFF2DECAFFE5C7B2FF96360EFF883B19FFF1E0D300F2E1D500DFCBC000D3BE
      B200D4BFB400D7C1B500D8C3B800C5AB9E00EADACA00E4D3C200CAB49E00F7DF
      C500C7AC9900D1BBB100E1CEC200F5E4D8000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001010A401717A3FF0101
      0A400000000001010A401717A3FF01010A400000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFA092
      81FFA09281FFA09281FFA09281FFA09281FFF1E0D400F1E0D400F9E9DD00FAEB
      DF00F7E8DD00F8E9DD00FDEEE200F2E1D700BDA29500E2CFC000EDD8C300C7AC
      9D00DDCAC100FEF1E600F7E8DB00F0DFD3000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000F060160813708FF8137
      08FF5E4427FF6A6A6AFF6B6B6BFF646464FF797979FF6B6B6BFF626262FF5151
      51FF5E4427FF7C2600FF632602FF2D1001AF000000000000000A000000120000
      0008000000150000001600000016000000160000001600000016000000140000
      0000000000000000000F00000012000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      00000000000000000000000000000000000000000000833808FFB54F0CFFB64F
      0DFF5E4427FF676767FF7C2600FF7C2600FFA3A3A3FFA9A9A9FF8F8F8FFF6B6B
      6BFF5E4427FF7C2600FF7B2D02FF762A03FF2C1302A3723007E0581D00E16953
      44DCC8C9CAE5BCC0C0E49DA0A1E4838383E4707070E4606262E53C3A38E23B10
      00D53A1200C9662703E303000060000000000000000000000000000000000000
      0000040403523A3A33B1585652D4545250D553514DD53C3B34BC0808076B0000
      001B0000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0A0A8CFF6969F3FF4444E7FF0A0A8CFF000000000000
      000000000000000000000000000000000000000000008F3F09FFBA540EFFBB54
      0EFF5E4427FF626262FF7C2600FF7C2600FFB5B5B5FFC0C0C0FFA0A0A0FF7777
      77FF5E4427FF7C2600FF7B2E03FF762A03FFAA4A0AFFBD520DFFB14300FFAB82
      60FFCABFBAFF853634FFBC9482FFDDE5E8FFB4B4B4FFA0A3A5FF6F6B68FF7320
      00FF812800FF953803FF0500006C000000000000000000000000000000174544
      3CB9B8B5C3FF8683D2FF8684DDFF9896E3FF8987DBFF7B77C8FF9A95A5FF4E4D
      42CC0000004100000000000000000000000000000000787878FF000000000000
      0000000000000000000005054EBF0A0A8CFF0A0A8CFF05054EBF000000000000
      0000000000000000000000000000000000000000000092420BFFBF5910FFC05A
      10FF5E4427FF5C5C5CFF7C2600FF7C2600FFC5C5C5FFDADADAFFB7B7B7FF8585
      85FF5E4427FF7C2600FF7D3003FF772B03FFA74B0BFFBC560EFFB94B00FFA87E
      5CFFA1928DFF590000FFB58168FFF4FCFEFFC5C5C5FFACAFB0FF7D7A77FF6C1E
      00FF782600FF933804FF04000069000000000000000000000012858579DAA6A3
      DEFF3837E3FF5B5BF6FF8C8DFAFFA4A5FBFF9393FCFF6465FAFF3C3BE6FF7E7A
      C2FF7F7B6BEA00000040000000000000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      0000000000000000000000000000000000000000000096460CFFC46013FFC562
      14FF5E4427FF575757FF575757FF575757FFC9C9C9FFF3F3F3FFD0D0D0FF9595
      95FF5E4427FF7C2600FF7E3103FF792C04FFAB500CFFC15A0FFFC05200FF9B73
      50FF8E7E7AFF5C0000FFB5836CFFFFFFFFFFE0E2E3FFC4C8CBFF8C8A88FF6B1C
      00FF792500FF943B05FF04000069000000000000000044443CB2ACAAE4FF1B1A
      DDFF4142F1FF5656EDFF7272F3FF7C7CF3FF7575F3FF5A5AEDFF4848F3FF1D1E
      E7FF8682C3FF555247D20000001A0000000000000000787878FF787878FF7878
      78FF787878FF787878FF177516FF6CD76CFF45BD45FF177516FF000000000000
      00000000000000000000000000000000000000000000994E14FFCA6C21FFCB6E
      24FF91541DFF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E44
      27FF683510FF752C02FF883806FF7B2D04FFB05611FFC76416FFCA600CFF8E65
      3FFF7A7778FF683D3CFFB09C92FFF6FAFBFFEDF0F1FFD0D6D9FF949391FF6418
      00FF722300FF973D06FF040000690000000012120F6FC0BEC7FF2020C9FF1D1D
      D0FF5252CDFF7777C0FF4B4BE5FF5353F6FF4C4CE6FF7676BFFF5352CCFF2323
      D5FF1E1ECBFFA9A4B0FF0808066C0000000000000000787878FF000000000000
      000000000000000000000D410CBF177516FF177516FF0D410CBF000000000000
      000000000000000000000000000000000000000000009D571EFFBA682AFFC394
      6DFFC0916BFFBE8E68FFBB8B65FFB98760FFB5825AFFB48058FFB37E57FFB17D
      57FFB07C56FFAF7B56FFA2440EFF7C2E04FFB66321FFCC7024FFCB6B1AFFAE5C
      15FF9B571AFFA76424FFA75C1CFFA35311FFA35211FF9D4D0EFF954307FF8C34
      00FF903600FFAC4408FF04000069000000009D9B83E07776C0FF0000B5FF1111
      B8FF6C6CB5FFDBDBB1FF8383BDFF2C2CD9FF8080BEFFDADAB0FF6F6FB5FF1414
      BCFF0000B5FF7370C2FF43423ABF0000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      00000000000000000000000000000000000000000000A0612BFFC38551FFEBEB
      EBFFE7E7E7FFE2E2E2FFDDDDDDFFD9D9D9FFD4D4D4FFD0D0D0FFCBCBCBFFCACA
      CAFFCACACAFFCACACAFFA85B29FF7D3004FFBA6824FFC57C44FFCAA488FFCC9E
      7CFFCC9B76FFC99873FFC4926DFFBF8D67FFBD8B66FFBD8A65FFBE8B67FFC093
      73FFBB8059FFAE4204FF0400006900000000CFCCB4FF413FB5FF000091FF0A0A
      A4FF1111B2FF7C7BB4FFC3C3B3FFA4A4B4FFC1C1B3FF7B7BB4FF1212B3FF0C0C
      A8FF000092FF3F3DBAFF626058D70000000000000000787878FF787878FF7878
      78FF787878FF787878FF0E8EE0FF3CFFFFFF12FFFFFF0E8EE0FF000000000000
      00000000000000000000000000000000000000000000A46936FFC18758FFDCDC
      DCFFD8D8D8FFD4D4D4FFD1D1D1FFCECECEFFCACACAFFC7C7C7FFC3C3C3FFBFBF
      BFFFBCBCBCFFBABABAFFA55926FF7D3105FFBB6A25FFC48D65FFE7F6FFFFE0E9
      EFFFDBE4EBFFD7E0E6FFD2DBE2FFCED7DEFFCAD3DAFFC5CFD6FFC3CCD3FFC5D5
      DFFFBCB5B1FFA83D00FF0400006900000000BFBAABFF5857BEFF2827ACFF0E0E
      A4FF0000A5FF0101A2FFBCBCC7FFECECD1FFBDBDC8FF0302A3FF0000A7FF1010
      A6FF2828ADFF5E5DC6FF605F5BD60000000000000000787878FF000000000000
      00000000000000000000084F7EBF0E8EE0FF0E8EE0FF084F7EBF000000000000
      00000000000000000000000000000000000000000000A87141FFCC9568FFFEFE
      FEFFFBFBFBFFF7F7F7FFF2F2F2FFEEEEEEFFE9E9E9FFE5E5E5FFE0E0E0FFDADA
      DAFFD7D7D7FFD1D1D1FFAA5D2BFF7E3105FFBF783AFFC8946CFFEEF1F4FFE8E8
      E8FFE3E3E3FFDFDFDFFFDADADAFFD7D7D7FFD2D2D2FFCECECEFFCACACAFFC8CE
      D1FFBCADA4FFA83E00FF0400006900000000A4A095FF8C8AC6FF6F6FE4FF2D2D
      C7FF1A1ABAFF9999D8FFFFFFFAFFE4E4EDFFFFFFFBFF9F9FD9FF2020BDFF3333
      C8FF7071E2FFA19FDBFF5F5D5AD700000000481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000000000000000000000114
      0294043D08FF01140294000000000000000000000000A9764AFFC79269FFE1E1
      E1FFE1E1E1FFE1E1E1FFE0E0E0FFDDDDDDFFD9D9D9FFD7D7D7FFD3D3D3FFCFCF
      CFFFCCCCCCFFC9C9C9FFA95C29FF7E3105FFC3854BFFCB9A75FFF1F2F4FFEFEF
      EFFFEDEDEDFFE9E9E9FFE4E4E4FFE0E0E0FFDCDCDCFFD8D8D8FFD3D3D3FFD2D8
      DBFFC4B4ACFFA93F00FF0400006900000000747067DB8481B1FF8181E3FF3636
      C1FF8F8FD4FFFFFFFFFFA9A9DFFF1A1AB8FFADADE4FFFFFFFFFF9696D6FF3D3D
      C2FF7C7CDEFFB0ADD4FF3E3D3AB400000000822700FFE3B823FFD18B09FF8227
      00FF00000000000000000000000000000000000000000000000000000000043D
      08FF10A916FF043D08FF000000000000000000000000AA784EFFCF9C73FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFCFCFCFFF8F8F8FFF4F4F4FFEFEF
      EFFFEBEBEBFFE6E6E6FFB0632EFF803205FFC68C56FFCC9E7AFFF0F2F4FFF0F0
      F0FFF0F0F0FFEFEFEFFFEEEEEEFFEAEAEAFFE6E6E6FFE1E1E1FFDDDDDDFFDCE2
      E5FFCCBCB4FFA93F00FF0400006900000000141413648D8896FF8E8ED7FF7474
      DAFF6C6CC7FF9797D4FF3B3CC1FF3B3BCAFF3F3EC3FF9A9AD6FF7272C9FF7575
      D9FF8989D6FFCAC8D0FF0303035200000000481600BF822700FF822700FF4816
      00BF000000000000000000000000000000000000000001140294043D08FF043D
      08FF42BF43FF043D08FF043D08FF0114029400000000AA774BFFC7946AFFE1E1
      E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFDEDE
      DEFFDCDCDCFFD8D8D8FFAC602BFF7E3205FFCB915AFFCFA07CFFEFF1F3FFEFEF
      EFFFEFEFEFFFEFEFEFFFF0F0F0FFF0F0F0FFEEEEEEFFEBEBEBFFE7E7E7FFE6EC
      EFFFD4C4BCFFAB3F00FF0400006900000000000000003A3937A38E8AACFFA2A2
      E7FF8686DCFF5C5CC8FF6766D1FF6969D0FF6868D0FF5F5FC9FF8787DCFF8C8C
      D7FFB9B7DAFF4B4A46C000000002000000000000000000000000000000000000
      00000000000000000000000000000000000000000000043D08FF96E998FF8FE3
      90FF65D764FF45C747FF099D0EFF043D08FF00000000AA774BFFBA8258FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFE
      FEFFFEFEFEFFFAFAFAFFA95E2EFF742B03FFA46635F7BE8D6AFCFBFEFAFFF8F9
      F4FFF8F9F4FFF8F9F4FFF8F9F4FFF8F9F4FFF8F9F4FFF8F9F5FFF7F8F4FFF9FD
      FAFFE1D2C6FE9E3900FD030000660000000000000000000000095D5C58CD908B
      A9FFA2A1D9FFA7A7E5FFA1A1E3FF9D9EE1FFA0A1E2FFA4A4E2FF9C9BD4FFB0AD
      CDFF7D7B77DA0000001800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001140294043D08FF043D
      08FF88E089FF043D08FF043D08FF0114029400000000AA774BFFBA8258FF2814
      77FF281477FF281477FF281477FF281477FF281477FF281477FF281477FF2814
      77FF281477FF281477FFA95E2EFF742B03FF361001C4734938E9D3D2E6FFD2CE
      DFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEDFFFD2CEE0FFD4D2
      E6FFBEADB5FB4F1800DC020000630000000000000000000000000000000D3736
      359E837E8BF68F8CAEFF918FBAFF9392C1FF9390BCFF9694B5FFA19EA8F83A39
      36AD000000150000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000043D
      08FF8AE18CFF043D08FF00000000000000000000000043230CC1723323FF320C
      57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C
      57FF320C57FF320C57FF692412FF3D1601C1B57023FF7D433CFF1E0D87FF2913
      82FF291382FF291382FF291382FF291382FF291382FF291382FF291382FF2311
      89FF39186CFF973A00FE03000056000000000000000000000000000000000000
      0000161614676B6861D499948FFFA09A96FFA3A09BFF7B7A73D9121210720000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000114
      0294043D08FF0114029400000000000000000000000000000000000000000000
      0000000000001C9620E250DD57FF4FD754FF4FD152FF48CA4AFF3EC13DFF35B9
      33FF31B22EFF15AC0EFC02020225000000000000000000000000000000000000
      000000000000000000000000000000000000000000090000000A0000000A0000
      000A0000000A0000000800000009000000010000000000000000000000000000
      000000000000000000003F332800005F93000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000020000
      0008000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000179421E1EAFBEAFFFFF8FFFFFFFDF9FFF5F4ECFFEAE9E0FFE0E2
      D5FFDBDACFFFA7D49CFF071B066E000000000000000000000000000000000000
      00000000000000000000000000150503005B070604600202035F0303035F0808
      085F0605025F0503006300000026000000000000000000000000000000000000
      00000000000000000000005F9300E7FAFF00003A5D00003A5D00000000000000
      0000000000000000000000000000000000000000000000000003002600A60009
      0094000000420000000800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000201012708030066090300720802
      006D0801006E2DAB35EF92F8A5FFC7FEE2FF95FCA8FF85F68EFF68EF6CFF43E1
      42FF43D63CFF44CF37FF1A5E02D7000000250201012708030066090300720902
      007108020071060100642B1801AAE2AB49FFDFC59CF5797679F69A918AF6E2DC
      DCF6CFAE78F5D49E42FE201200A5000000340000000000000000000000000000
      00000000000000000000005F9300E7FAFF00D0F9FF0052CBFF00A13400000000
      0000000000000000000000000000000000000000000000000000008100E30098
      00FF003C00D80000007000000021000000000000000000000000000000000000
      00000000000000000000000000000000000031211189FDD4B1FFFFEBDBFFFFE2
      D3FFF3D7BEFF72E182FF6CEC85FFBDFCDBFF8DFBAEFF67FF82FF34F946FF02EA
      09FF00CC00FF03C100FF52AB11FF0500005C31211189FDD4B1FFFFEBDBFFFDE2
      D1FFFBDBCAFFFDDFD5FFE3BC8EFFDBAC5EFFECD3B2FFBEBBC2FFC3BAB8FFE9E5
      E9FFE3C499FFDBB369FFC58B5AFF040000695D534A003F3328003E3327003E33
      27003E332700B0ABA60000000000005F930052CBFF00E2943100FF9D0000A134
      000000000000B0ABA6003F3328005F544A000000000000000000007500D700B7
      00FF00AE00FF007200F4001E00BC0000005D0000000D00000000000000000000
      00000000000000000000000000000000000027190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFF8F5EFFF85E897FF72F094FF8DEC95FFBAFACEFF94FAB0FF67F77EFF4DF8
      63FF34F74AFF1FE127FF1BCE0EFF000D007A27190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFFFFAFEFFFFFAFFFFE7C8A8FFDAAC60FFDDB170FFEDD4B3FFEBD1AEFFE3C9
      A8FFDEAF69FFDCB974FFBC9370FF020000627369600000000000000000000000
      0000000000000000000000000000005F9300F4D7A500FFFAD100E2943100FF9D
      0000A13400000000000000000000736960000000000000000000007700D800B7
      00FF00B600FF00B600FF00AA00FF005100E6000500900000002C000000000000
      000000000000000000000000000000000000271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFF3ECE2FF80E892FF9EF8BEFF88E287FFB6F1BBFFA6EDA9FFA5EFA5FF81E2
      83FF4AED5FFF4AFF6BFF32E63EFF0C9B03F1271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFFFEFEFFFFFFDFFFFE3CFACFFDDB165FFE4D5BAFFE6DBC8FFE1D5C0FFE7DD
      CDFFE6CFAEFFDDB86FFFBD926DFF020000627368600000000000F1EAE300F1EA
      E400F1EAE400F1EAE400F9F6F40000000000D56B0300F4D7A500FFFAD100E294
      3100FF9D0000A134000000000000C5C1BE000000000000000000007700D800B6
      00FF00B100FF00B400FF00B600FF00B700FF008B00FE001F00BE0000006C0000
      002000000000000000000000000000000000281A0D7EEEE4D1FFF9FFFFFFFFF6
      F8FFF3EADFFF7DE993FFB1FDDBFFB3EABBFFE5EEE1FFFFFBFDFFFAFFEFFFE9F7
      DFFFA8EAA3FF77DC79FF98B471FF081B009D281A0D7EEEE4D1FFF9FFFFFFFFF6
      F6FFFFEDEDFFFFFFFFFFE6D2AFFFD2A662FFC8C2BEFFCAC7C6FFC3BFBEFFD1D0
      D3FFD4C8BBFFD3B16EFFBF936EFF02000062776D630000000000FFFEFB00FFFF
      FB00FFFFFB00FFFFFB00FFFFFB00FFFFFE0000000000D0690600F4D7A500FFFA
      D100E2943100FF9D0000A1340000000000000000000000000000007700D800B6
      00FF00B200FF00B200FF00B200FF00B500FF00B700FF00AA00FF007500F7000D
      00A4000000430000000E00000000000000002A1C0F7ED9D6C6FFE9E2EAFFFFE7
      EAFFF8E9E4FF70DF7AFF92F3ADFF6EEE8AFF85DC88FFCFE8C7FFDEF9D6FFEEFD
      E5FFD9F0CEFFBFE6BFFFF1BEB9FF010000502A1C0F7ED9D6C6FFE9E2EAFFFFE7
      E6FFFFECECFFFFF8FCFFE9CFA8FFD2AC74FFD4CDCAFFC7C6C7FFDFD9D6FFCECC
      D0FFDAD1C9FFD5B87EFFC6986FFF020000617C71660000000000FFF8EA00FFF8
      EC00FFF8EC00FFF8EC00FFF8EC00FFF9EC00FBF9F80000000000CC690800F4D7
      A500FFFAD100E29431000024F6000015C8000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B200FF00B400FF00B500FF00B000FF009B
      00FF004B00E10008009300000020000000002A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F1FFF3E9E0FFEFDFD0FFEDD8C9FFF9F0EEFFECF0E8FFC1DFB7FFC4EB
      BCFFB4DDA9FFF9FEFCFFF1CAC0FF0100005D2A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F0FFFFF2F7FFD7B79CFFD5AC6EFFE5CBA0FFE5CBA1FFE1C59BFFE4CA
      A0FFE5CB9EFFD4BB81FFC89C7DFF0200005D80756B0000000000FFF2DE00FFF3
      E000FFF3E000FFF3E000FFF3E000FFF3DF00F7F4F100EDE9E50000000000CD6C
      0C00F4D7A500000000000024F6000015C8000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B300FF00B200FF00B300FF00B500FF00B0
      00FF00B300FF004C00DB00000020000000002A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFBFFFFFFF1F6FFFFE6EBFFFFF9FBFFFFE7EAFFFFEAEEFFD1DE
      C2FFE8E1D3FFFFFFFFFFE9C4B6FF0200005D2A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFBFAFFFAEDEEFFF7DAD5FFF8ECE1FFF8DACFFFF8DCD2FFF8DB
      D0FFF9DBD1FFF7F5F1FFE7C3B7FF0200005C84786E0000000000FFEDD000FFEE
      D300FFEED300FFEED300FFEED300FFEED100F7F5F300FAF8F400FDFDFB000000
      0000CD6C0C000024F600FFCCFF00153ACF000000000000000000007700D800B6
      00FF00B200FF00B300FF00B300FF00B300FF00B500FF00B600FF00B200FF008A
      00FA002600A5000100320000000000000000291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF1F1FFFEEAEAFFFEFAFAFFFEE4E3FFFFE8E8FFFFE9
      EEFFFFE6EAFFFFFFFFFFE8C3B5FF0200005D291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF3F3FFFFEDF0FFFFFDFFFFFFE6E9FFFFEBEDFFFFEA
      EDFFFFE8EAFFFFFFFFFFE9C4B7FF0200005C897D720000000000FFE7C300FFE9
      C700FFE9C700FFE9C700FFE9C700FFE8C400F9F8F800DFD6CE00E0D7CF00F2EF
      EB00000000000B32CD000013C500000000000000000000000000007700D800B6
      00FF00B100FF00B300FF00B500FF00B600FF00B100FF008900FA002500A40002
      0036000000000000000000000000000000002A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D2A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D8D81750000000000FFE0B000FFE2
      B400FFE4B700FFECBF00FFF0C300FFEFC000000000000000000000000000FEFB
      FA00FEFDFC000000000000000000D0CBC6000000000000000000007700D800B6
      00FF00B400FF00B600FF00B300FF008C00FB002500A400020035000000000000
      000000000000000000000000000000000000291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D9185780000000000FAF9F900FAFA
      FB0000000000483E360032281F0032271E0032261B0033271B00473C32000000
      0000FBF9F700FBF8F60000000000918578000000000000000000007400D700B7
      00FF00B200FF008900FA002500A5000200360000000000000000000000000000
      0000000000000000000000000000000000002E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF020000612E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF02000061978B7E0000000000000000000000
      0000000000006A615700FFFFFC00FEFAF400FEFAF400FFFFFC006A6157000000
      0000000000000000000000000000978B7E000000000000000000008400E8008F
      00FD002400A30002003500000000000000000000000000000000000000000000
      0000000000000000000000000000000000001C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003C1C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003CA09487009B8F82009A8D80009A8D
      80009D91830079706600FFE4E100FAD9D600FAD9D600FFE4E100797066009D91
      83009A8D80009A8D80009B8F8200A09487000000000000000005001A007B0003
      0040000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000000000000000000000000
      000000000000968B7E0000000000000000000000000000000000968B7E000000
      0000000000000000000000000000000000000000000000000001000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00100991B4FF0991B4FF000405300000000000000000001117600991B4FF0991
      B4FF000000100000000000000000000000000000000000000000000000060000
      00230000002100000020000000200000002000000020000000200000001F0000
      00240000001D0000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000540000006B0000
      0069000000640000000B00000000000000000000000000000000000000000991
      B4FF57CCDEFF5BD7E6FF0991B4FF0991B4FF0991B4FF0C99BAFF20C9DEFF14B8
      D1FF0991B4FF00000000000000000000000000000000000000000000001FB0B0
      B0F1CCCCCCF9C3C3C3F8C3C3C3F8C7C7C7F8C1C1C1F8C5C5C5F8C4C4C4F8DCDC
      DCFB404040B10000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000011000D00C8098509FF07AD05FF03B1
      02FF0C9B0BFF003700EB0202024C000000000000000000000000000000000991
      B4FF80E3EFFF6EE0EDFF58D5E6FF51D8E7FF3ECEE1FF35D0E3FF28CCE1FF1DC7
      DEFF0991B4FF00000000000000000000000009090969383838B23B3B3BB6BCBC
      BCF6FCFCFCFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF4F4F4FFF5F5F5FFF7F7
      F7FF727272DA393939B23E3E3EB8020202380201012708030066090300720902
      0071080200710801007108020071080200710802007108020071080200710802
      007108020071080100710A030071000000360201012708030066090300720902
      0071080200710902007007010065051300BA09B215FF10C919FF41D549FF57DA
      5DFF16C41EFF11C71AFF004C01F60000003C0000000000000000000000000991
      B4FF88E5F0FF71DCE9FF4EC6DAFF58CADDFF51C9DCFF32BFD5FF2DC9DEFF20C1
      D8FF0991B4FF000000000000000000000000606060C3E7E7E7FFE4E4E4FF4848
      48FF3D3D3DFF414141FF414141FF404040FF404040FF3F3F3FFF424242FF2C2C
      2CFF777777FFF5F5F5FFF2F2F2FF1515158031211189FDD4B1FFFFEBDBFFFDE2
      D1FFFBDBCAFFFCDACAFFFCDBCBFFFCDBCAFFFCDACAFFFCDBCBFFFCDCCBFFFCDB
      CBFFFCDBCBFFFEE6D8FFF2B799FF0300006331211189FDD4B1FFFFEBDBFFFDE2
      D1FFFBDBCAFFFFE0D2FFE5C0B3FF188F1DFF0FCB2AFF04C31FFFB9EFC2FFFFFF
      FFFF18CB32FF14C72DFF0FB524FF000A0187000C0F500991B4FF0991B4FF4FC6
      DAFF6CD5E5FF74D5E3FF0991B4FF0991B4FF0991B4FF0991B4FF45C9DDFF27C2
      D9FF12A7C5FF0991B4FF0991B4FF00020220585858BBE0E0E0FFE3E3E3FFA2A2
      A1FF7A7D81FF818489FF818487FF818487FF828589FF82868AFF80878BFF7E82
      84FFC3C3C2FFE2E2E2FFEAEAEAFF1313137727190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFFFFAFEFFFFF3F7FFFFEBEFFFFFEDF1FFFFEDF1FFFFE9EDFFFFE9EDFFFFE8
      ECFFFFE8ECFFFFFFFFFFEBCCC1FF0200005D27190D7EF7E8D9FFFFFFFFFFFFFF
      FFFFFFFAFEFFFFF7FFFFE4DCD6FF02A929FF33D456FFF2FFF3FFFEFEFEFFFFFF
      FFFFF9FFF9FF71E28AFF03C12DFF0019057E0991B4FF35BFD7FF45C7DCFF69DE
      EBFF62CCDEFF0991B4FF919191FF919191FF919191FF919191FF0991B4FF3FC2
      D8FF2CCCE1FF17B5D0FF10B0CBFF0991B4FF5C5C5CBBEEEEEEFFEBEBEBFFFAFC
      FCFFFFFAF2FFFAF0E3FFFBF3E9FFFBF3E8FFFBF1E5FFFBEDE0FFFBE8DBFFFFFB
      F7FFF4F5F6FFE9E9E9FFFAFAFAFF13131377271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFFFEFEFFFFFF6F6FFFFF2F2FFFFF3F3FFFEF7F7FFFDE6E6FFFDE9E9FFFEEB
      EBFFFFE6E6FFFFFFFFFFEBC7B9FF0200005D271A0D7EF7E1CFFFFFFFFFFFFFFF
      FFFFFFEFEFFFFFFCFFFFE2D9D7FF029F2FFF1FD557FF84E2A2FFE6F8EBFFFFFF
      FFFF96E6B0FF44D971FF02C53DFF0010037E0991B4FF46D5E6FF53D8E9FF48C9
      DCFF0991B4FF919191FFFEFEFEFFFCFCFCFFF4F4F4FFDDDDDDFF919191FF0991
      B4FF2CC5DAFF29CCE1FF1DC7DEFF0991B4FF616161BDFEFEFEFFFEFFFFFFFEFC
      FBFFDA9B64FFC98846FFCB965DFFCB965CFFCB8F51FFCB7E40FFC85D1BFFE7A6
      86FFFFFFFFFFFEFEFFFFFFFFFFFF1414147A281A0D7EEEE4D1FFF9FFFFFFFFF6
      F6FFFFEDEDFFFFF9F9FFFFF2F2FFFEDADAFFFEE9E9FFFEE6E6FFFEEDEDFFFEF1
      F1FFFFE3E3FFFFFFFFFFEAC6B8FF0200005D281A0D7EEEE4D1FFF9FFFFFFFFF6
      F6FFFFEDEDFFFFFCFCFFFCEBF3FF51955FFF00C940FF00D140FF8BE8ADFFCEF5
      DCFF00CF4AFF00DC50FF1D9D39FF030000630991B4FF2BBCD4FF49D5E6FF39C0
      D7FF0991B4FF919191FFF7F7F7FFF7F7F7FFF0F0F0FFDDDDDDFF919191FF0991
      B4FF2ABCD4FF33CFE2FF14ACC9FF0991B4FF636363BFFFFFFFFFFFFFFFFFFFF6
      F2FFDA9260FFCB8B50FFD49558FFD79B60FFD59155FFD37E44FFD5662CFFE89F
      7CFFFFFFFFFFFFFFFFFFFFFFFFFF0D0D0D6E2A1C0F7ED9D6C6FFE9E2EAFFFFE7
      E6FFFFECECFFFFF3F3FFFFEAEAFFFEDADAFFFDEAEAFFFDEFEFFFFEE9E9FFFFED
      EDFFFFEEEEFFFFFFFFFFE8C4B6FF0200005D2A1C0F7ED9D6C6FFE9E2EAFFFFE7
      E6FFFFECECFFFFF3F3FFFFEFF1FFECCDD2FF42AB69FF00C44BFF00D356FF00D4
      56FF00CE51FF20C86EFFB9A88EFF0400005B000000000991B4FF2DBCD4FF33BF
      D5FF0991B4FF919191FFE1E1E1FFE9E9E9FFE2E2E2FFCFCFCFFF919191FF0991
      B4FF32BDD5FF1EABC7FF0991B4FF000000000D0D0D67DBDBDBF8FFFFFFFFFFF5
      EFFFDFA184FFD8A78DFFE3AE8BFFE1AB85FFE1A681FFE3A17DFFE69A76FFEBB1
      96FFFFFFFFFFFFFFFFFFCBCBCBF4000000172A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F0FFFFEBEBFFFFE1E1FFFFDCDCFFFFF1F1FFFEF9F9FFFEEEEEFFFFF6
      F6FFFFFAFAFFFFFFFFFFECC7B9FF0100005D2A1E127EE0C3A5FFEED3D0FFFFF6
      F8FFFFF0F0FFFFEBEBFFFFE1E0FFFFE5E8FFFEE5EDFF92B29DFF5DB47EFF5BBD
      82FF75AF8CFFE7E9ECFFFFCFC7FF0100005D00000000000202200991B4FF43D4
      E6FF0991B4FF919191FFAAAAAAFFC9C9C9FFC5C5C5FFA6A6A6FF919191FF0991
      B4FF55D8E9FF0991B4FF000000000000000000000000040404332C2D2E8CDED3
      CDFDF1C0ABFFF7CDBBFFF4CCBBFFF5CDBCFFF4CBB9FFF3C6B3FFF0BFAAFFEDC4
      B0FF96989ADD1414146A0202022A000000002A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFAFAFFFFF1F1FFFEE5E5FFFEF8F8FFFFE5E5FFFFE8E8FFFFE7
      E7FFFFE5E5FFFFFFFFFFE9C5B7FF0200005D2A1D117EE2E3B1FFEFEBD7FFFFE2
      E6FFFFEDEDFFFFFAFAFFFFF1F1FFFEE5E4FFFFFDFEFFFFECF3FFFFE8F1FFFFE8
      F1FFFFEAF2FFFFFFFFFFE8C4B6FF0200005D00000000000C0F500991B4FF3AD1
      E3FF34C4D9FF0991B4FF919191FF919191FF919191FF919191FF0991B4FF54CB
      DEFF61DCEAFF0991B4FF0004053000000000000000000000000000000011BCBD
      BDF7F7F2EFFFF9EDE7FFF7ECE7FFF2EAE7FFECE4E1FFE5DDD9FFDFD8D5FFE4E2
      E1FF4A4A4AA9000000000000000000000000291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF1F1FFFEEAEAFFFEFAFAFFFEE4E4FFFFE8E8FFFFE7
      E7FFFFE5E5FFFFFFFFFFE8C3B5FF0200005D291E0F7EF2D4CBFFFADDEDFFFFE7
      E5FFFFEFEFFFFFFAFAFFFFF1F1FFFEEAEAFFFEFAFAFFFFE4E4FFFFE9EAFFFFE9
      E9FFFFE6E6FFFFFFFFFFE8C3B5FF0200005D000000000991B4FF27CBE1FF32CF
      E2FF3DD3E5FF37C4D9FF0991B4FF0991B4FF0991B4FF0991B4FF71D7E6FF7CE2
      EEFF6BDEEBFF5CDAEAFF0991B4FF00000000000000000000000002020224CBCB
      CCF8FFFFFFFFFFFFFFFFFFFFFFFFFAFDFEFFF2F5F7FFECEFF1FFE5E8EAFFE7E9
      EAFF535353AF0000000000000000000000002A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D2A1F107EE9D0CCFFF4D9EFFFFFED
      ECFFFFEFF1FFFFF5F7FFFFEAECFFFFDFE1FFFFF6F8FFFEF5F7FFFEECEEFFFFEE
      F1FFFFF5F7FFFFFFFFFFEBCABDFF0200005D000000000991B4FF1DC0D8FF23C2
      D9FF0991B4FF40D3E5FF4CD7E7FF58D9E9FF66DDEBFF73E1EDFF76DDEAFF0991
      B4FF77E1EEFF5FD7E6FF0991B4FF00000000000000000000000002020227DFDF
      DFFFFFFFFFFFFFFFFFFFFFFFFFFFFDFDFDFFF6F6F6FFEFEFEFFFE9E9E9FFE9E9
      E9FF535353B0000000000000000000000000291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D291E107EFADFC6FFFFF0F0FFFFFA
      F8FFFFF2EFFFFFEAE7FFFFE5E3FFFFE4E2FFFFEFECFFFEFBF8FFFEEBE9FFFDED
      EAFFFEF8F6FFFFF9F6FFEBC2B2FF0200005D00000000000000100991B4FF0991
      B4FF000C0F500991B4FF0991B4FF4FD7E7FF5BDAEAFF0991B4FF0991B4FF000C
      0F500991B4FF0991B4FF000000100000000000000000000000000000000A2626
      268DFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF8F8F8FFF2F2F2FFEDED
      EDFF535353B00000000000000000000000002E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF020000612E221584FAC583FFFFD099FFFFC1
      86FFFFB77BFFFFAE72FFFFA467FFFF995CFFFF8B4EFFFF7E41FFFF7437FFFF66
      29FFFF5E21FFFF6224FFE74B19FF020000610000000000000000000000000000
      000000000000000000000991B4FF46D4E6FF52D8E7FF0991B4FF000000000000
      0000000000000000000000000000000000000000000000000000000000000303
      032ECECECEF1D4D4D4F1D2D2D2F0D2D2D2F0D2D2D2F0D0D0D0F0CBCBCBEFDDDD
      DDF8555555B00000000000000000000000001C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003C1C150D67E0A558F6FABE73FFF9AF
      64FFF8A358FFF7974CFFF68A40FFF57C33FFF46F27FFF3621AFFF3550DFFF247
      00FFF13D00FFF13D00FFC72F00F90000003C0000000000000000000000000000
      00000000000000000000034052AF0991B4FF0991B4FF00181F70000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      001211111159101010570F0F0F550F0F0F550F0F0F550F0F0F550E0E0E521C1C
      1C781818186F0000000000000000000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000032210E7C5A3915A25434
      13A0523212A0512E10A04E2B0EA04C280CA04A250AA0492308A0471F07A0441C
      05A0421903A0441701A2250B0084000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A050403290000000600000006000000030000000000000003000000150804
      0A41281D206C160F0E5004010128180D0D553124247202020121090A063F392A
      297A0504032900000006000000060000000300000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB00000005210F0F75200F0F752515
      1678422829982112126E2917177B3F2525951E1110702A19178533201D8D1E10
      1078412050C92C161E952A131D9646201EAB000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000E0705044E2218197D0000
      0C6E2016308F2F213D9B0400106A562D25B5000000101F0F0F6F000000000000
      000C2B22226D000000000100001B261C1C6D0000000D0705044E2219197D0000
      0C6D2117308E30223D9A04001069572D25B50D0707493C2424911D16165C2721
      2165645454A019151555221C1966564644A8231275D734215FC8503873D72E24
      339230272272594A4C971812125774403ED00D0707493C2424911D16165C2721
      2165645454A019151555221C1966564644A8231275D734215FC8503873D72E24
      339230272272594A4C971812125774403ED00D0707493C2424911D16165C2721
      2165645454A019151555221C1966574645A8221274D534215EC6513875D52920
      2E8C2E25216F564B4D9418121255743F3ED00D0707493C2424911D16165C2721
      2165645454A019141554231C1A67554444A81D0E6ED5311E58C64E3771D6271F
      2D8F2C241F70574749951711115675403ED01B111161412828950504042B0A08
      083D483939880303022C1A151D7E4E3578D70C061C891A0E37A85735A1EF0201
      012C1C16165E2C25246B030303246B3738C91B111161412828950504042B0A08
      083D483939880303022C1A151D7E4E3578D70C061C891A0E37A85735A1EF0201
      012C1C16165E2C25246B030303246B3738C91B111161412828950504042B0A08
      083D483939880303022C1A151D7F4E3477D5100A1F881E1238A6543494F00605
      054E1E1817672720206F020202246D3A3AC91B111161412828950504042B0A08
      083D483939880303022B1A151C7E432C6CDA09031E9C140830B941267DEF0503
      03571D161682251E1F8A05030343613435CE01000019251616720101011B0303
      032B362B287B0101012F1D1140AD512DB1F00C090F5E17111970503673C60000
      0010120E0E4E231D1D6101000014663434C301000019251616720101011B0303
      032B362B287B0101012F1D1140AD512DB1F00C090F5E17111970513773C60000
      0009100C0C46231D1D6101000014663434C301000019251616720101011B0303
      032B362B287B0101012F1F1243AB432787EC00000EBA0A0812BB271B32F70000
      00AC0F0C0CA3131010B30000005D5C3232C101000019251616720101011B0303
      032B362B287B0101012E13073EB5422558F5322419C6383339CA362A4AEF1E1E
      1EA13A352FB83F2F14C3090700824A2629C726161673513333A7211818653127
      29805C455FC438293DA73D2C4BB2604D479F1C1716553B31307B564545961D19
      18574C3D3D8B574646961F17175D794242D626161673513333A7211818653127
      29805C455FC438293DA73D2C4BB2604D479F1B1616543028276F473B3887211A
      1C6656434AA25044438F1F17175D794242D726161673513333A7211818653127
      29805C455FC438293DA73B2A46A67B6856CE80765CF6898988F7807F7BF18986
      86F4929090FC7D7E7EFF231C1CB96E3C3CCD26161673513333A7211818653127
      29805C455FC4382A3DA32D1E3DB4B68F33F2FFD67EFFE0DBD2FF7D7C76FFFCF7
      F7FFFCECDAFFF6C467FF916D34EB4D272ED4020101212113136C000000050704
      106D483268C500002098080609561B15145500000000040303241C1716560000
      000008070733120F0F48000000005D2E2EBA020101212113136C000000050704
      106D483268C5000020980806095619151352000000000C09116B292232940000
      208A1A2473D1120F0F51000000005E2E2FBB020101212113136C000000050704
      106D483268C500002098050405425B4C46AE8C724ADE928673E3929397E87D7F
      80D9929396E4939393F304040461452323AA020101212113136C000000050704
      106D483268C50000219304030458AC873EEBFAC978FFEDE4DAFFC3BEBDFFEEEA
      EAFFF3E3CBFFF8C46CFF604920C92E1418B6130B0B543E28238F382442A64535
      46A66E536EC8392370C844353D9865514DA1221C1C5E44363684645050A01F19
      195A4E3E3E8D5A49499821181860794242D7130B0B543E28238F382442A64535
      46A66E536EC8392370C844353D985F514C9C251D1E6C4D4C7FE66F7FDFF6203B
      C1E01D48D1EC31386BCF261D1D6D7D4443D4130B0B543E28238F382442A64535
      46A66E536EC8392370C83D2F368C87736DD19A805BEDA27E51EF9D9281F28C8A
      89E99F917FEF8D9095F82B2121A7733F3ECE130B0B543E28238F382442A64535
      46A66E536EC83C2471C5382B3299B79049F4ECB65AFFF1CE95FFFCE0B2FFF3D8
      ABFFEBC585FFEEB85BFF836536E150292DD6110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B03030229342C2C740000000F0D0B0B3F2C23236B0000
      000E1410104C211B1B5E00000010653333C2110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B030302292E29286D000001193B3D65C87787C3DF0A19
      8FBF1328ABD11038C7EA0B0A1971593028AB110B0B4E291A16790A05116F100B
      1571392E2E7C0703126B01000017786666C08D7D61E3987852E79A7950EB8472
      57DD9D7D53E78E8370F40A080876502A2AB4110B0B4E291A16790A05116F100B
      1571392E2E7C080412670201012CC0954CF8F3D294FFEDE9DBFFEBE4D1FFEAE3
      D2FFF1EBDAFFF6CD83FF664E22CF36191DBF0201012025161578160C2B981813
      166B463836860504042F100D0D4C463A3A860504042B1B1616583E31317E0404
      0429231D1D63312828730504042C6C3838C90201012025161578160C2B981813
      166B463836860504042F100D0D4C3E36357E060506383D4070D96370CEED0101
      95CA0C0EBBDB1E2388DE0F0B0E57673833BD0201012025161578160C2B981813
      166B463836860504042F0A08083C7E6A69C7958C85E7A4948AEAA08978EE8B75
      60E29F8771EB96836EF6120E0F895B3031BD0201012025161578160C2B981813
      166B463836860403032C0D0A0950B78E4AF9D7BE93FFC7C8CCFFCDCAC6FFCBC8
      C5FFD9D8D9FFDDBC84FF705629D6401E23C82214146C4C2F30A52F1C52B81C17
      15646250519E1713134D2C25256B5D4B4B9A1411114B332A2A74544444931310
      10493D32327E4A3D3D8A140F0F4D753F3FD22214146C4C2F30A52F1C52B81C17
      15646250519E1713134D2C25256B5C4B4A991512114D28222B8B3F3850BB191A
      5ACD181495EF3D33368A110D0C45774040D42214146C4C2F30A52F1C52B81C17
      15646250519E1713134D211D1D5D8A6968D5AE9794F6BFABA2F6BCA391F7A986
      5BF2B58C49F5AD8B3DFF211A189F683A3CC72214146C4C2F30A52F1C52B81C17
      15646250519E1513134B251D1D6CBE9953FFEED6ADFFDDDBD8FFE5DFD5FFE8E2
      D8FFE4E2DDFFECCF9AFF876A3AE14C252ACA2517156E41252DA0060014750000
      000F2F242471000000000201011E281E1E6A000000000504042D211919610000
      00000B08083C1611115100000000652E2EC62517156E41252DA0060014750000
      000F2F242471000000000201011E291F1F6B0000000004030326221B195F0A09
      0A48221A238C120E0D4900000000652E2EC62517156E41252DA0060014750000
      000F2F242471000000000000000E5C4241AF412C29AA5D443EBC75584CCE412E
      21A1684E36C1735739D40201013654292AB82517156E41252DA0060014750000
      000F2F242471000000000101011D775A36DE6A5633C8806B4BD6947D58E36252
      35C385714EDA977C4FE422180A91441F22B604030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A331E1E89190D
      0D642C18187F301C1C851A0D0D67412020A504030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A341E1E88140A
      0A5927171575311D1D851A0D0D67412020A504030228371F2696200F12782112
      126E3821218D1C0E0E6826141477331F1F87140A0A59211212702E1B1B811309
      0A58251516762B191A7C180C0C61432020A604030228371F2696200F12782112
      126E3821218D1C0E0E6825151576301C1D8A13090964201110782C1818871208
      08612312127C29171784150A0B65442121A60000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0101
      011A0000000F0000000C01000019000000000000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0100
      00190000000E0000000C01000019000000000000000000000000000000100100
      001600000008010000190000001300000008010000160000000E000000080100
      00170000000C0000000A01000018000000000000000000000000000000100100
      001600000008010000190000001300000004000000100000000A000000050000
      0011000000080000000600000012000000000000000000000000000000000000
      0000090909462426278D494C4EC76A6E72F06A6E72F0494C4EC72426278D0909
      0946000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000030100203B1E0D8F80411DCFCC6A34FFCF7038FF874720CF41220F8F0301
      0020000000000000000000000000000000000000000000000000000000000000
      0000000000000000000001000016080000341B00005B03000023000000000000
      0000000000000000000000000000000000000000000000000000010202202425
      268C7D8084EDBCBEC1FEE2E1E3FFF7F7F8FFF7F7F8FFE2E2E4FFBDC0C2FE7E81
      85ED2425268C0102022000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000010391D
      0D8FC25E29FFD1652AFFDA6F35FFDE7B41FFE38A4EFFE89A5EFFE69D61FFDE88
      4AFF4424108F000000100000000000000000010000161A000059000000130000
      000E0000000F0000000E0600002F47010094490200960A0000390000000F0000
      000A0000000A000000110600002D000000030000000001020220313234A3B2B5
      BAFBF9F9F9FFFDF3EFFFF6C7AEFFF08C41FFF59A41FFFDDAADFFFFF9EFFFF9F9
      F9FFB4B9BBFB313234A301020220000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000010773A1BCFC65A
      29FFD25F25FFD66729FFDA702FFFDF7936FFE4843DFFE98F45FFEF9C52FFF4B9
      78FFEEAB6BFF914E22CF00000010000000000E000043620500AF2C0000742700
      006C2900006F2900006F2601006C2501006C2101006425020068210000662E02
      0B8532010D8C2800006F6E0000B30200001B000000002425268CB2B5BAFBFDFA
      F9FFEB9884FFDB3A02FFE24E01FFFFFFFFFFFFFFFFFFF98900FFFE9A03FFFED2
      8DFFFEFDFAFFB4B8BBFB2425268C000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000371A0C8FC25B2EFFCE5A
      26FFD25F23FFD66729FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF994DFFF4A5
      55FFFAC17BFFEFAD6DFF4424108F00000000010000182701006E000000090000
      0002000000030000000300000002000000000000000000000000000000100503
      1D620100021F000000010100001800000000090909467C8084EDF9F9F9FFED9E
      84FFD52A02FFD93602FFE14901FFFFFFFFFFFFFFFFFFF68100FFFC9100FFFE9B
      04FFFED088FFF9F9F9FF7E8085ED090909460000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000002010020B85A2EFFCB5D2EFFCE57
      1DFFD15E22FFD56628FFDA6F2EFFFFFFFFFFFFFFFFFFE88C43FFED964AFFF19F
      51FFF5A656FFF5BB7AFFDF894BFF03010020010000162500006B000000030000
      00000000000000000000000000000000000000020D3A0006225E00082F6E0001
      0423000000000000000000000000000000002426278DBCBFC2FEFDF4EFFFDB3B
      01FFD62D02FFD73002FFDE4201FFE55401FFEB6400FFF17400FFF68200FFFA8C
      00FFFC9000FFFFF8EFFFBCBFC2FE2426278D0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000035190C8FC4663DFFCA531CFFCD56
      1CFFD05D21FFD46426FFD86C2DFFFFFFFFFFFFFFFFFFE5873FFFE98F45FFED96
      4BFFEF9B4EFFF09F54FFE79F64FF41220F8F010000172600006D000000060000
      000000000000000000000000000000020C390003164C00041951000736760000
      000500000000000000000000000000000000494C4EC7E2E2E4FFF7CEB8FFDD40
      01FFD83302FFD52A02FFDA3802FFFFFFFFFFFFFFFFFFF08C40FFF07000FFF378
      00FFF47B00FFFBD5ADFFE2E2E4FF494C4EC70000000000000000000000000041
      71EF004171EF000408400000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF00000000713519CFD07850FFCA5019FFCC54
      1BFFCF5A1FFFD36124FFD7692AFFFFFFFFFFFFFFFFFFE2803BFFE58740FFE88D
      44FFEA9046FFEA9147FFE99D61FF874720CF010000172600006D000000050000
      0000000000090101021E0000000900062D6C0000000D00000000000000090000
      0000000000000000000000000000000000006A6E72F0F7F7F8FFF2A776FFE568
      2EFFDB3D06FFD62D02FFD62D02FFFFFFFFFFFFFFFFFFEC8040FFE95E01FFEB65
      00FFEC6700FFF18E41FFF7F7F8FF6A6E72F000000000004171EF004A82FF004A
      82FF0B59A5F7004A82FF00132080000000000000000000000000000000000000
      000000000000000000000000000000000000B55F38FFD37C55FFCF612DFFCC55
      1CFFCE571DFFD15E22FFD46427FFFFFFFFFFFFFFFFFFDE7835FFE17E39FFE383
      3DFFE5853EFFE5863FFFE48D50FFD07139FF0000000B2400006A000000020000
      000B00041E5900072F6E00062866000723610000000000000000000000000000
      0000000000000000000000000000000000006A6E72F0F7F7F8FFF4AA73FFEB82
      45FFE67443FFDD4B1CFFD62F07FFD62E02FFFFFFFFFFFFFFFFFFE97940FFE451
      01FFE55401FFEB8041FFF7F7F8FF6A6E72F000000000004A82FF549BD5ED5EA2
      D9ED3585D8ED0B58B1F5004A82FF00000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF00000000B5603AFFD5825BFFD06533FFD165
      31FFD05F27FFCF5B21FFD26023FFFFFFFFFFFFFFFFFFDB7030FFDD7533FFDE79
      36FFDF7B37FFE07B37FFDF7E44FFCC6B35FF0A02013C2E010077000000000005
      195001030B3A00000007000F5F9C000829680000000000000000000000000000
      000000000000000000000000000000000000494C4EC7E2E2E4FFFBDCC2FFEE88
      41FFEA7C43FFE67446FFE36A44FFDE5634FFDB4A27FFFFFFFFFFFFFFFFFFE77A
      4FFFE25C26FFF6CFBFFFE2E2E4FF494C4EC700000000004171EF004A82FF004A
      82FF1B6CACF6004A82FF0017288F000000000000000000000000000000000000
      0000000000000000000000000000000000006E3219CFD98D6AFFD06433FFD165
      33FFD26733FFD36833FFFFFFFFFFFFFFFFFFFFFFFFFFD7692AFFD96D2DFFDA70
      2FFFDB7130FFDB7131FFDA7138FF80411DCF8C0100CE4101008C000000000007
      1D57020307330000000100052B6A00030F3F0000000000000000000000000000
      0000000000000000000000000000000000002426278DBDC0C2FEFEF9F3FFF28F
      3DFFED853FFFFFFFFFFFFFFFFFFFE46F46FFE36B49FFFFFFFFFFFFFFFFFFE992
      7CFFE36F52FFFDF6F4FFBEC0C3FE2426278D0000000000000000000000000041
      71EF004171EF00070C500000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000033180B8FD58E6EFFD16A3CFFD065
      33FFD16633FFD26733FFD36A34FFD56C35FFD66E36FFD76F35FFD87035FFD971
      36FFDA7236FFDA7337FFD36E35FF3C1E0D8F3D0100882B000072000000000006
      1B5402040C3D0000000000000002000000000000000000000000000000000000
      000000000000000000000000000000000000090909467F8186EDF9F9F9FFFACC
      9FFFF18E3BFFFBE6D7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDF7F4FFE36E
      4BFFF1B9A9FFF9F9F9FF7F8186ED090909460000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000002010020B86643FFDB8F6CFFD064
      33FFD06533FFD16633FFD26733FFFCF6F2FFFCF6F3FFD56D36FFD66E36FFD76F
      37FFD87037FFD87037FFC4632FFF030100200200001C21010066000000000006
      235F0102072F0000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000002425268CB5B9BCFBFEFC
      FAFFFACC9EFFF28F39FFF5B688FFFDF1EAFFFEF7F4FFED966BFFE77644FFF3BC
      A6FFFEFBFBFFB6B9BCFB2425268C000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000033180B8FCB8260FFD988
      62FFD06433FFD06533FFD16533FFFCF6F2FFFCF6F2FFD36934FFD46A35FFD46B
      35FFD56C37FFCA6532FF3A1D0D8F000000000000000524030976050317590002
      0E3D000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000001020220313234A3B5B9
      BCFBF9F9F9FFFEF8F2FFFBDCBFFFF5AA6BFFF3A66DFFF9D7C1FFFEF7F3FFF9F9
      F9FFB6B9BCFB313234A301020220000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000106C3218CFCB82
      60FFDB8F6BFFD16A3CFFD06533FFD36F40FFD46F40FFD26733FFD26936FFD26C
      3FFFC76337FF773A1BCF000000100000000005000029570713B5080310540000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000010202202425
      268C7F8286EDBDC0C2FEE2E2E4FFF7F7F8FFF7F7F8FFE2E2E4FFBEC0C3FE7F81
      86ED2425268C0102022000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000103318
      0B8FB86642FFD48E6DFFD98C69FFD5815AFFD27B53FFD17A53FFC86F48FFBA5E
      33FF371A0C8F000000100000000000000000070000332D0000760000000A0000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000090909462426278D494C4EC76A6E72F06A6E72F0494C4EC72426278D0909
      0946000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000201002033180B8F6E3219CFB55F39FFB45E37FF713519CF35190C8F0201
      0020000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000183948C02B6581FF2B6581FF2B65
      81FF2B6581FF2B6581FF2B6581FF2B6581FF122B3AFF1C4661FF1C4661FF1D3F
      55FF1F2D36FF152D3CEF00000000000000000000000000000000000000000000
      0000000800400031009F006300DF199F19FF1B9F1BFF006300DF0031009F0008
      0040000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000003B7C99FF4FA2C5FF4FA2C5FF4FA2
      C5FF4FA2C5FF4FA2C5FF4FA2C5FF4FA2C5FF1C4860FF3186B4FF3186B4FF2852
      6AFFE99464FF284050FF0000000000000000000000000000000000000010003C
      00AF039F03FF29D829FF6FFA6FFF9EFF9EFFA5FFA5FF7EFC7EFF34DA34FF059F
      05FF003C00AF0000001000000000000000000000000000000000000000000000
      000000000037031D038D1B4F1BC6265F26D51C521CC905220599000100520000
      000D000000000000000000000000000000000000000000000000000000000000
      0000010000362412088D5A2F17C3733F20D562381FC72F1B0E99040100520000
      000D000000000000000000000000000000003F819EFF52A6CAFF52A6CAFF52A6
      CAFF52A6CAFF52A6CAFF52A6CAFF52A6CAFF507182FFBCBCBCFFBCBCBCFF2D61
      7CFFE99464FF2C4D63FF00000000000000000000000000000010005500CF00B8
      00FF02DE02FF3FE13FFF78E578FF92E792FF95E995FF80E780FF48E348FF08DE
      08FF00B600FF005500CF0000001000000000000000000000000000000006001F
      009845CF45FD7EF37EFFA9FFA9FFBDFFBDFFAEFFAEFF83F683FF4BD34BFF0431
      04B30000002B0000000000000000000000000000000000000000000000062911
      0597D46429FDE67331FFEA7832FFEE7C31FFF49347FFFCA75EFFF5A662FF462A
      17AF0000002A0000000000000000000000004486A2FF55ABCEFF55ABCEFF55AB
      CEFF55ABCEFF55ABCEFF55ABCEFF55ABCEFF5B7D8EFFDCDCDCFFBCBCBCFF3670
      8FFFDCDCDCFF32566DFF000000000000000000000000003C00AF00B700FF01D8
      01FF3DC73DFF61CA61FF6FD36FFF78D978FF7ADA7AFF73D573FF65CC65FF40C9
      40FF01D401FF00B200FF003C00AF000000000000000000000005003C00B84AE9
      4AFF6DD96DFF7AD67AFF88DF88FF90E690FF8BE28BFF7DD97DFF70D970FF50E8
      50FF0B5A0BD20000002A00000000000000000000000000000005471C0AB8E566
      29FFD76424FFD86826FFDC7B44FFE6A787FFE78D4FFFEC9343FFF8AB5BFFFFCD
      7DFF7C512ECF000000290000000000000000498AA5FF58B0D1FF58B0D1FF58B0
      D1FF58B0D1FF58B0D1FF58B0D1FF58B0D1FF61787EFFE2C1A6FFBCBCBCFF1A53
      4AFF0A5412FF29545AFF000000000000000000080040009A00FF00D800FF0A8F
      0AFF109210FF48BB48FF59C659FF61CB61FF62CB62FF45BA45FF52C152FF46B7
      46FF2AB52AFF00D000FF009700FF00080040000000000020008C2FDA2FFF47B7
      47FF51BD51FF63CC63FF6DD36DFF74D674FF73D673FF65CD65FF55BF55FF4AB7
      4AFF34DA34FF023102B60000000D000000000000000028130A8BDD612AFFCF59
      1DFFD26224FFD5601CFFE6B7A4FFF6FFFFFFEABCA5FFEA8A38FFF29F4FFFF8AD
      5AFFFFCC7DFF482B17B30000000C000000004E90A9FF5BB5D5FF5BB5D5FF5BB5
      D5FF5BB5D5FF5BB5D5FF5BB5D5FF5BB5D5FF638594FFE0E0E0FFBCBCBCFF134C
      3AFF129016FF04580BFF00070160000000000031009F00C500FF08BF08FF279F
      27FF9AD59AFF0C900CFF40B540FF49BB49FF139613FF35A635FF109310FF35AC
      35FF2AA32AFF08BA08FF00BC00FF0031009F000400470FAB0FF62CAE2CFF2A9F
      2AFF1F9E1FFF43BA43FF5AC65AFF5BC75BFF45BB45FF47BC47FF46B846FF36A9
      36FF2CAD2CFF14BC14FF000100520000000006030147B2542AF5CE541BFFCE58
      1DFFD26124FFD56320FFDD8D65FFEACEC2FFE4966BFFE8893BFFEE9A4DFFF19E
      50FFF7A959FFF5A561FF04010052000000005395AEFF5EBAD9FF5EBAD9FF5EBA
      D9FF5EBAD9FF5EBAD9FF5EBAD9FF5BB5D5FF5E7778FF638554FF1D7E29FF158B
      1EFF1AA920FF129516FF055909FF0010028F006100DF00D800FF0C990CFF0284
      02FFEAF7EAFFADDEADFF129212FF119311FF058905FFFFFFFFFF88CE88FF0589
      05FF1B961BFF0E990EFF00CA00FF006100DF004C00BB0EAE0EFF1A901AFF1D97
      1DFF9CD09CFF27A227FF26A926FF2EAC2EFF3AA43AFF2FA72FFF22A222FF2AA1
      2AFF1D911DFF12B712FF0021009D00000000592F1CBBC75C2CFFC94D12FFCD57
      1DFFD15E22FFD35F1EFFDD8E6BFFEAC8B8FFE18D5EFFE48032FFEA9046FFEB94
      49FFEC9447FFFBA45BFF311C0F9D00000000589BB1FF62C0DDFF62C0DDFF62C0
      DDFF62C0DDFF62C0DDFF62C0DDFF62C0DDFF256A3DFF50C764FF46D153FF31C7
      38FF21B526FF169F1AFF0C7E10FF013F06FF009600FF00DA00FF088008FF0786
      07FF65BD65FFE9E9E9FFEFEFEFFFADDEADFF65BD65FFEEEEEEFFD9D9D9FFC1E6
      C1FF088908FF068206FF00CA00FF009200FF009C00EC008D00FF0A790AFF0082
      00FF9DCF9DFFDAE2DAFF4BAB4BFF0E910EFF91C691FFD1DDD1FF219921FF0087
      00FF0E7E0EFF009400FF004A00CA00000000A66141ECD0693AFFCA5119FFCB52
      18FFCF5B1FFFD05412FFE3AB95FFF8FFFFFFE7B6A1FFDD6B1FFFE5873EFFE689
      41FFE6893FFFF4944BFF61381FC7000000005D9FB5FF65C5E1FF65C5E1FF65C5
      E1FF65C5E1FF65C5E1FF65C5E1FF317E6CFF81D797FF66D97DFF35B045FF1274
      1DFF1EAF25FF149718FF034408EF00010030069906FF88F489FF3EB43EFF20A1
      20FF0B8F0BFFC1E6C1FFE9E9E9FFE5E5E5FFEFEFEFFFEBEBEBFFE2E2E2FFEEEE
      EEFFEAF6EAFF139313FF7AEE7CFF059605FF28BD28FF39B639FF1A9C1AFF0990
      09FF0F8F0FFFD4DCD4FFFFECFFFFE6E8E6FFD9E3D9FFE5D6E5FFE1EAE1FF4FAC
      4FFF098F09FF3EC33FFF0F5E0FD900000000C3724EFFD16C3DFFD06330FFCD5A
      23FFCD561CFFCF5718FFD36833FFEFE2E1FFF4F7F8FFDF8D62FFDD6F27FFE17E
      3AFFE17E39FFEE8740FF743F21D70000000063A4B9FF68CBE5FF68CBE5FF68CB
      E5FF68CBE5FF68CBE5FF68CBE5FF428B5DFF7DD596FF267449FF4F746CFF2662
      51FF179D1EFF023308CF0000002000000000006100DFAAF8AAFF56C556FF39B1
      39FF29AB29FF058B05FF65BD65FFEAF7EAFFFFFFFFFFFEFEFEFFFEFEFEFFFFFF
      FFFFADDEADFF129512FF98F399FF006100DF57A758EB86E987FF3DCC3DFF30C8
      2FFF15BB15FF1FA61FFFA7D2A7FFF0F0F0FFFDFCFDFFFEFDFEFFFFFFFFFF82C3
      82FF22B321FF97FE98FF215021C500000000A66446EBD26E41FFCF622FFFD168
      35FFD1642FFFCF5B20FFCE500DFFD67446FFF3F0EFFFF0E6E7FFD97139FFDA6E
      2AFFDC7330FFE97936FF5A2E17C30000000068AABEFF6BD0E9FF6BD0E9FF6BD0
      E9FF6BD0E9FF6BD0E9FF6BD0E9FF4AA360FF348667FF6BD0E9FF78909BFF4986
      88FF1A5633FF0000001000000000000000000031009F95E396FF82E182FF4DB8
      4DFF41B541FF38B138FF1A9D1AFF098F09FF129312FFFFFFFFFFFFFFFFFF75C5
      75FF119211FF64D564FF82DE83FF0031009F1B551BB78CE48CFF50CA50FF3DC7
      3DFF36C936FF22C222FF0EAD0EFF079B07FFAAD7AAFFFFFFFFFF58B358FF18A9
      18FF59CD59FF8CF38DFF061E069100000000593524B6D2784FFFCF602EFFD066
      34FFD0642EFFD36C3FFFD26431FFCB4806FFE7BCACFFFAFFFFFFE09978FFD560
      1CFFD96F31FFE77737FF26130791000000006CAFC1FF6ED5EDFF6ED5EDFF6ED5
      EDFF6ED5EDFF6ED5EDFF6ED5EDFF3A9085FF6ED5EDFF6ED5EDFF6C8995FF76AE
      C7FF547E91FF000000000000000000000000000800402DA42DFFC1FCC1FF72CB
      72FF5ABD5AFF51BA51FF4BB84BFF48B748FF0B8F0BFFFFFFFFFF44AD44FF249F
      24FF6CCA6CFF99F399FF28A329FF000800400106013F70C272F48DE18EFF4FC6
      4EFF4BC84BFF43C843FF41CD41FF21BA21FF5AAD5AFF50B250FF26B126FF5ACD
      5AFF8CE18CFF6FDA70FF00000036000000000705043DB86D4BF3D56C3CFFCD5D
      29FFD06538FFF6E8E5FFF1D8D0FFE4AC95FFF5EFEEFFFBFFFFFFDF9675FFD464
      26FFDC7439FFDB7036FF010000350000000072B4C5FF72DAF0FF72DAF0FF72DA
      F0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF708A96FF80B5
      CEFF547E91FF00000000000000000000000000000000003C00AF76CB77FFC2FA
      C2FF81CF81FF6CC46CFF67C167FF64C164FF219D21FF159515FF3AAA3AFF79CF
      79FF98F098FF66CA67FF003C00AF00000000000000000C240C80ACF1ADFF88D8
      88FF5EC85EFF5ECB5EFF5BCC5BFF58CA58FF2CA82CFF47BD47FF6BCF6BFF8AD7
      8AFFA4FEA4FF0220029A0000000000000000000000002818117FDA8055FFD060
      2EFFCE6033FFEECABEFFFFFFFFFFFFFFFFFFFDFFFFFFEBC5BAFFD26632FFD56A
      32FFEA773CFF29110599000000000000000077B9CBFF75E0F6FF75E0F6FF75E0
      F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF738D97FF89BB
      D3FF547E91FF0000000000000000000000000000000000000010045904CF79CE
      79FFD3FCD3FFA9E9A9FF8ED58EFF82CB82FF83CB83FF88D488FF93E393FFADF6
      AFFF6ACA6AFF005400CF000000100000000000000000000000001E441EA7B6F3
      B6FFAAE5ABFF81CF81FF74CB74FF73CC73FF7AD17AFF88D288FFA5E3A5FFABFC
      ABFF113E12B70000000700000000000000000000000000000001492D21A7DB80
      57FFD46938FFCC5521FFD67952FFDC8B69FFD8805AFFCF5E29FFD56732FFE472
      3FFF461E0BB70000000700000000000000007DBFCFFF78E5FAFF78E5FAFF78E5
      FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF527586FF91C0
      D7FF547E91FF000000000000000000000000000000000000000000000010003C
      00AF31A531FFAAE5AAFFD0FBD1FFC1FAC2FFB8F8B8FFBFF8C0FF99E29AFF2CA4
      2CFF003C00AF0000001000000000000000000000000000000000000000000C25
      0C8377B278E9B1E7B2FFAFE4AFFFA9DEA9FFABE4ABFFA7E6A8FF6CB46DEC0721
      078C000000040000000000000000000000000000000000000000000000002A19
      1282A86444E8D2784FFFCF6434FFCD5D2BFFCE612EFFCE6C3EFFA85934EB2813
      0A8B000000040000000000000000000000004A6F78C083C4D3FF83C4D3FF83C4
      D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF6C8894FF4F78
      85E0152024800000000000000000000000000000000000000000000000000000
      0000000800400031009F006100DF229E22FF229E22FF006100DF0031009F0008
      0040000000000000000000000000000000000000000000000000000000000000
      0000020702411A4C1AAE64A764EB74C474FF5EA95EEC144C14B3000300490000
      0000000000000000000000000000000000000000000000000000000000000000
      000008050440513021AEA56345EBC4734FFFA55F3FEC512A19B3060301480000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000202021838533AA2129F
      1FFF139F1FFF38533AA202020218000000000000000000000000000000000000
      00000000000000000000010101200404053A0404053A01010223000000000000
      00000000000000000000000000000000000000000000000000230704006E0704
      006F090807700303034E0000001A040302510909086F0908086E0908086E0808
      066E0704006F0704006C0000001A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000009020202191616164C558958D683EE
      A8FF84F0ACFF558A59D61616164C020202180000000000000000000000000000
      0000020204330C0D41B20B1094F30004ABFF0000A7FF00008AF500003BB90303
      053B0000000000000000000000000000000000000000463513B7FFCF73FFF0BB
      5EFFFFFFF4FFC2C1C2FF554F4AE2CCC4BBFFFFFFFCFFFFF7EBFFFFFAF4FFFFF6
      E5FFF0BC5FFFFFCE73FF36270DA900000000000000000000000E4D261DA97E51
      3ACB674C49C36B5A5CC46B5757C46B5454C46B5555C4695455C46F4F46C4754B
      36C47F4E33CC200A087500000000000000000000000000000000000000000000
      00000000000000000000000000000505052638563AA7189322F60C9517FC64E0
      90FF64E493FF0C9518FC189322F638533AA20000000000000000000000000101
      0D551D22ACFD1722D6FF2227DCFF5659E5FF5759E3FF1F21D3FF0000C0FF0000
      92FF02020D62000000000000000000000000000000006E5322D1FFD082FFECBC
      6AFFFFFFEFFFB8B8B9FF685F58FFC0BBB7FFFFFAEEFFF8EADDFFF9ECE3FFFAEE
      DFFFECBD6BFFFFD082FF6C501CD400000000000000000805063FF99D58FFFFA6
      4DFFD6B1A6FFDCC9C9FFD9C7C5FFD9CDCEFFDACDCDFFD4CCD0FFEEB89EFFFF9F
      4AFFFF9825FFA84821E400000001000000000C7C93FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF228AA1FF119E1CFF81DF9CFF62D486FF1FC0
      58FF22C960FF65E494FF84F2ADFF139F20FF00000000000000000101032D2128
      B3FC1E2FE3FF5557E0FFF2F0F4FFE2DFF1FFE1DFF2FFFBFAF8FF6767D9FF0000
      C2FF000093FF02020438000000000000000000000000614A1FCAFAC873FFE7B3
      5AFFFFFAE9FFAEAEAEFF4C443FFFB6AFA9FFFFF3E7FFF0E1D4FFF0E3DAFFF5E8
      D9FFE8B45BFFFAC873FF5E471ACC00000000000000000705053DF49C5BFFFFA1
      52FFD5BEB6FFC25348FFE0998BFFE8EAE9FFE0D6D5FFD9D6DAFFE6A085FFFE8A
      3DFFFF962FFF934321D6000000010000000007788FFFA3E6FFFF50D0FFFF40CA
      FFFF41CAFFFF40CAFFFF44CBFFFF8EE2FFFF139E1BFF84DD99FF62D283FF1FB7
      51FF1FC259FF64E190FF84EEA9FF129F1FFF00000000000000000B0C49B03448
      E7FF373CDCFFFFFFF4FF6E6FDBFF0309C3FF0207BDFF6262D3FFFFFFFBFF494A
      C9FF0003BDFF00003FBF000000000000000000000000614B20CAF9C56DFFE5AF
      52FFF9F1E7FFD7D3D7FF89898EFFD0CBCBFFF6EDEBFFEDE4E2FFEDE6E7FFF2E9
      DFFFE6AF52FFF9C56DFF5E471BCC00000000000000000705053DF29B5CFFFFA5
      57FFEDD2C9FF6C6577FF6A6B7DFFCCC8D1FFFBECE3FFEEF5F7FFE79378FFFC7E
      31FFFF9F39FF93411FD60000000100000000087A91FF49A6BCFF53D1FFFF14BC
      FBFF13BBFBFF13BBFBFF16BBFBFF43CBFFFF46BA95FF159D27FF099818FF62D1
      83FF62D587FF0C9518FB189322F638533AA200000000000001182B33B5F3152D
      E7FFB1AFE5FFA7A7E4FF0000C4FF0004C0FF0000BAFF0000B0FF9898DEFFC5C5
      E7FF0000B8FF020496FB010101220000000000000000624C21CAF8C26AFFE4AA
      4AFFE7C183FFF4D7A6FFFFE3B3FFF4D6A7FFEBCEA0FFECCFA2FFEDD2A2FFE9C3
      85FFE4A94AFFF8C26AFF5F471BCC00000000000000000705053DF39C5DFFFFA6
      5AFFF2CFC5FFBCC3D3FFB5D1DFFF71B0DBFF5587C2FFF3EAE8FFF28161FFF96D
      21FFFFA541FF92401ED60000000100000000087A91FF229DBFFF89DCF8FF2CC7
      FEFF1BC1FDFF1DC1FDFF1EC1FDFF24C5FDFF37CBFFFF70DCFFFF58BC7CFF83DD
      99FF83E29DFF4D9F62F1141414490202021800000000030305364050DBFF011D
      E3FFC0BEE5FF8183DCFF4D50E4FF9191DFFF8D8CDEFF1316D6FF5F5FD6FFD9D7
      E9FF0002B3FF070BACFF0404053A0000000000000000614C22CAF7BF64FFE2A7
      46FFE2A53EFFE0A239FFE1A33AFFE1A33AFFE2A43BFFE2A43AFFE1A239FFE2A5
      3EFFE2A746FFF7BF64FF5E491DCC00000000000000000705053DF29D60FFFFB3
      68FFF89554FFE58850FFBAC0C6FF58D3FFFF0087FDFF516D9EFFFF782AFFFF8B
      32FFFFA444FF923F1ED60000000100000000087A91FF35C9FFFF4FA8B9FF5ED9
      FFFF24C7FDFF24C7FDFF24C8FDFF24C7FDFF20C6FDFF3DD0FFFF4ABE95FF139E
      1BFF129E1CFF4BAE7BFF1113154D0000000000000000030305354252DFFF112D
      ECFFAFAEDFFFC2C1E6FF7271E3FFCAC9E9FFC6C6E7FF2828DAFFA8A8E4FFBCBB
      E1FF0000B7FF0E14B0FF040405390000000000000000624D24CAF3B650FFE7B8
      69FFFFFEF9FFFFFDF2FFFFFBF1FFFFFFF5FFFFF9EFFFFFFDF2FFFFFDF3FFFFFD
      F8FFE7B869FFF3B650FF5F4A1FCC00000000000000000705053DF29758FFFCDD
      BAFFF6E3CEFFFFDEC1FF92AAB9FF7DDFEFFF4DD8FFFF009EF9FF6689A4FFFAD1
      B7FFFEBB75FF933C14D60000000100000000087A91FF40D1FFFF0D94BCFF90E3
      FBFF38D1FDFF2ACDFCFF2CCEFCFF2CCEFCFF2BCDFCFF33CFFCFF56D9FFFF7EE2
      FFFF82E3FFFFA4EFFFFF0F4E5CC70000000000000000000000162A32B9F1D5E1
      FFFFA8A7D7FFDBDBEAFF6D6DC9FFB6B6E1FFB0B0E1FF5353C3FFFCFCEFFF5756
      CEFF2327EBFF0E129EF90101011E0000000000000000634E25CAF2B246FFEEC2
      77FFE3E7EEFFCFCECAFFDAD7D2FFB9BAB9FFE4E1DCFFCCCBC8FFCCCCC9FFEEF2
      F8FFECC075FFF2B246FF5F4A21CC00000000000000000705053DF29554FFF9EC
      DAFFFCFFFFFFFFFFFFFFF7F4F9FF7EB3C6FF91F1F4FF4BEBFFFF00BBFBFF7AA6
      D3FFFFBB79FF963D13D60000000100000000087A91FF44D1FFFF19C3FBFF57AB
      BDFF68DFFFFF36D3FEFF35D2FEFF35D2FEFF35D2FEFF36D2FEFF37D2FEFF38D3
      FEFF37D2FEFF57DCFFFF71C4DCFF02060634000000000000000008084BA9F5F6
      FEFFEEEEF6FF9797CCFF8888CFFFC3C3E5FFBBBBE3FF6565CAFF7575C7FF4B4A
      E4FF494AFBFF000045B8000000000000000000000000644F28CAF0B041FFE9BA
      6AFFE8EAECFFD2CEC6FFE0DBD4FFD7D3CCFFE8E3DAFFD3CFC8FFD8D5CDFFF0F1
      F5FFE7B968FFF0B041FF604A23CC00000000000000000705053DF19656FFF8E6
      D1FFFDFFFFFFFFFDFDFFFFFFFDFFF4EAE9FF71AFC3FF94F6F8FF49FCFFFF00CE
      F1FFA5947AFFA1380BD50000000000000000087A91FF46D4FFFF25CDFFFF1299
      BAFFA6E6FAFF8AE4FEFF87E4FDFF88E4FDFF88E4FDFF88E4FDFF86E4FDFF85E5
      FFFF86E6FFFF8BE5FFFFBFF7FFFF0D4854C2000000000000000000000326393C
      C1F7FFFFFFFFFFFFFFFFCDCDF1FFB4B4D5FFB0B0D2FF8483E3FF8685F3FF7D80
      FFFF1719B1FE01010431000000000000000000000000634F2ACAF3AF3DFFEAB8
      64FFE2E5EAFFC7C2BBFFD8D4CDFFD4D0CAFFE6E0D7FFC6C1BAFFD2CEC7FFEBED
      F2FFE8B662FFF3AF3DFF604C25CC00000000000000000705043CF29657FFF6E4
      CFFFFDFFFFFFFFFAF7FFFFF6F2FFFFFBF3FFEDDDDAFF68ADC4FF93F6FCFF3CFD
      FFFF15E3F0FF5E2B27D40000000000000000087A91FF4BD6FFFF29CDFDFF2ACA
      F9FF09829BFF087A91FF087A91FF087A91FF087A91FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF096171E00000000000000000000000000101
      0C483F42BDF6E1E4FDFFFFFFFFFFB7B7D1FFA2A2CCFFC4C5FFFF9395FBFF2427
      B4FB01000D550000000000000000000000000000000066522CCAE1A136FFDDAC
      5CFFDEE0E4FFB8B5AFFFD7D3CDFFD6D0C8FFC1BEB9FFE2DDD5FFC1BEB8FFE9EB
      EFFFDAAA59FFE1A136FF624F27CC00000000000000000805053FF49D5CFFF5E6
      D3FFFFFFFFFFFFFCFAFFFFF8F5FFFFF2EEFFFFFEF5FFE6E0E2FF61B6D3FF98FA
      FFFF2FF8FFFF10B5D0F50606094A00000000087A91FF4ED8FFFF2CCEFEFF2FCF
      FEFF30D2FFFF2FD1FFFF33D3FFFF4BD9FFFF52DDFFFF52DDFFFF6AE4FFFF67BF
      D3FF000000090000000000000000000000000000000000000000000000000000
      0000010102260A0A47A4474AAFEB8487DFFF777ADDFF3A3CACED0B0B44AA0202
      042F0000000000000000000000000000000000000000755F36D2D7962CFFCE9D
      4CFFF4FBFFFFEBE9E5FFEDEBE8FFEDEBE8FFECEAE7FFEEECE8FFEBE9E5FFF5FB
      FFFFCE9D4BFFD7962CFF745D32D6000000000000000005030335ED8544FFF7DB
      BDFFFCECE5FFFDE8DCFFFDE3D7FFFCE2D4FFFCE4D7FFFFF0E2FFD7C3C3FF60B2
      C9FF96FBFFFF30FCFFFF10A4D6FF0000001317859AFF75E4FFFF35D1FEFF31D0
      FEFF2FD0FEFF36D1FEFF70E2FFFF1C8AA0FF087A91FF087A91FF087A91FF107E
      94FF000000080000000000000000000000000000000000000000000000000000
      0000000000000000000000000016030305350303053600000119000000000000
      00000000000000000000000000000000000000000000392C15A4EDC26EFFE4C1
      84FFE9DDC4FFE9DABEFFE8DABDFFE8DABEFFE9DABEFFE8DABDFFE9DABDFFE8DC
      C4FFE4C284FFEAC06EFE2B210E920000000000000000000000031907056A3114
      0F8D2B110F872C120E882C120E882C120E882C110E882B110E882E110E85210C
      0E89448FA8E43CDBF8FF0E426CCA00000008010E11572D94A9FF7DE7FFFF53DC
      FFFF52DCFFFF79E7FFFF2B94A9FF00090A440000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000D241E117E241E
      107E231A087E231B097E231B097E231B097E231B097E231B097E231B097E231A
      087E241E107E241D107D00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000070B146C093C6ED30100011B000000000000000001060836138297FF087A
      91FF087A91FF158398FF00080A41000000000000000000000000000000000000
      00000000000000000000000000000000000000000000818181FF818181FF8181
      81FF808080FF808080FF808080FF808080FF808080FF7E7E7EFF7E7E7EFF7E7E
      7EFF7E7E7EFF7E7E7EFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000009000000000000000000000000183948C02B6581FF2B6581FF2B65
      81FF2B6581FF2B6581FF2B6581FF2B6581FF122B3AFF1C4661FF1C4661FF1D3F
      55FF1F2D36FF152D3CEF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000008E8E8EFFFDFDFDFFACBA
      D7FFF9F9F9FFF9F9F9FFF9F9F9FFF9F9F9FFF9F9F9FFF8F8F8FFF8F8F8FFF8F8
      F8FFFDFDFDFF8C8C8CFF00000000000000000E0D0D624A4B4BD14D5054D64C4E
      52D5525456D5515355D5515355D5515355D5515355D5515354D5545658D52C2D
      2DC5000000160000000000000000000000003B7C99FF4FA2C5FF4FA2C5FF4FA2
      C5FF4FA2C5FF4FA2C5FF4FA2C5FF4FA2C5FF1C4860FF3186B4FF3186B4FF2852
      6AFFE99464FF284050FF00000000000000000000000000000000000000001932
      419201050744000000000505053205050642020303300A13185E020405300000
      00000000000000000000000000000000000000000000989898FF949495FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FF969696FF00000000000000001C1D1D86E0D5C9FFD9D8DDFFDDD9
      DBFFF6E9DCFFF2E6DCFFF1E6DCFFF1E5DBFFF1E6DCFFF1E5DBFFFFF6EBFF8581
      7EF5000000160000000000000000000000003F819EFF52A6CAFF52A6CAFF52A6
      CAFF52A6CAFF52A6CAFF52A6CAFF52A6CAFF507182FFBCBCBCFFBCBCBCFF2D61
      7CFFE99464FF2C4D63FF000000000000000000000000000000021E3A489F46A3
      CFFF0C181E9D474747C1D7D8D8F7DEEAEFFF3180A8FF3693C2FF5589A3F60002
      03440000000000000000000000000000000000000000A1A1A1FFFAFAFAFFACBA
      D7FFEBEBEBFFEBEBEBFFEBEBEBFFEBEBEBFFEAEAEAFFE9E9E9FFE8E8E8FFE7E7
      E7FFF9F9F9FFA0A0A0FF00000000000000001B1C1D7ECBB6A3FFA49A98FFCBBF
      B8FFDEC5AEFFDBC4B0FFDAC4B0FFDAC3AFFFD9C3AFFFD8C1ADFFEAD1BBFF746C
      66EA000000160000000000000000000000004486A2FF55ABCEFF55ABCEFF55AB
      CEFF55ABCEFF55ABCEFF55ABCEFF55ABCEFF5B7D8EFFDCDCDCFFBCBCBCFF3670
      8FFFDCDCDCFF32566DFF0000000000000000000000001B313E9945A2CCFF4B9F
      C3FF8BA5B2FFD2CCCAFFFFFFFFFFD7DFE4FF327291FF3794C1FFA7A8A7FF0407
      08620000000300000002000000000000000000000000A9A9A9FFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFA7A7A7FF00000000000000001D1E1E7ED3C1AFFFCCC4C4FFCCC1
      BCFFE3CCB8FFDFCBB9FFDECAB9FFDDC9B8FFDDC9B8FFDCC8B6FFECD6C3FF7B74
      6DEA00000016000000000000000000000000498AA5FF58B0D1FF58B0D1FF58B0
      D1FF58B0D1FF58B0D1FF58B0D1FF58B0D1FF61787EFFE2C1A6FFBCBCBCFF3A73
      92FFDCDCDCFF365D73FF0000000000000000000000002F5873D04FA8CDFF4FA8
      CBFF8FA5B0FFC4BEBCFFFFFFFFFFD7E0E4FF397B9CFF429BC5FF92C9E5FF0306
      0759000000060000000C000000000000000000000000AEAEAEFFFBFBFBFFACBA
      D7FFF0F0F0FFF0F0F0FFF0F0F0FFF0F0F0FFEFEFEFFFEFEFEFFFEEEEEEFFECEC
      ECFFFAFAFAFFADADADFF00000000000000001F1F1F7ED6C3B1FFCAC2C1FFCDC3
      BEFFE5CFB9FFE0CCBAFFE0CBBAFFDFCBB9FFDFCBB9FFDECAB8FFEDD7C3FF7F78
      72EA000000160000000000000000000000004E90A9FF5BB5D5FF5BB5D5FF5BB5
      D5FF5BB5D5FF5BB5D5FF5BB5D5FF5BB5D5FF638594FFE0E0E0FFBCBCBCFF3D77
      96FFDCDCDCFF3C6478FF0000000000000000000000002B5067C553AFD3FF52AE
      D1FF94A7B1FFAEA8A5FFEEECEAFFDCE5E9FF3E82A1FF48A4CDFF96CAE2FF0608
      094D0000000000000000000000000000000000000000B4B4B4FFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFB3B3B3FF00000000000000001F20217ED9C6B5FFCBC3C2FFCFC4
      BFFFE6D0BAFFE2CEBCFFE1CDBBFFE1CDBBFFE1CDBBFFDFCBB9FFEFD9C5FF827C
      75EA000000160000000000000000000000005395AEFF5EBAD9FF5EBAD9FF5EBA
      D9FF5EBAD9FF5EBAD9FF5EBAD9FF5BB5D5FF677D83FFE2C1A6FFBCBCBCFF407C
      99FFDCDCDCFF426A7EFF0000000000000000000000002C5268C558B7D8FF56B5
      D6FF73A9C0FFA8A4A3FFEAE5E2FFDDE6EAFF4489A7FF57AED6FF5BB7E3FF0608
      093C0000000000000000000000000000000000000000B7B7B7FF949495FFACBA
      D7FFF4F4F4FFF5F5F5FFF5F5F5FFF4F4F4FFF4F4F4FFF3F3F3FFF2F2F2FFF1F1
      F1FFFBFBFBFFB7B7B7FF00000000000000002021217EDBC8B6FFD0C6C4FFD0C5
      C0FFE8D2BDFFE4D0BEFFE3CFBDFFE3CFBDFFE2CEBCFFE1CDBBFFEFD9C6FF857F
      78EA00000016000000000000000000000000589BB1FF62C0DDFF62C0DDFF62C0
      DDFF62C0DDFF62C0DDFF62C0DDFF62C0DDFF52798DFF739EB1FFBCBCBCFF4791
      B4FF4D829BFF3F5E6EEF0000000000000000000000002D5369C55DBDDDFF5EBD
      DCFF5AB3D4FF9DA3A8FFECE5E2FFDDE6E9FF4A8FAEFF5FBBE5FF1A2931830000
      00010000000000000000000000000000000000000000BABABAFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFB9B9B9FF00000000000000002121227EDECFC2FFAEB0B8FFD2C6
      C0FFE9D3BDFFE5D0BEFFE4D0BDFFE4CFBDFFE3CEBCFFE2CEBBFFF0DAC6FF877F
      7BEA000000160000000000000000000000005D9FB5FF65C5E1FF65C5E1FF65C5
      E1FF65C5E1FF65C5E1FF65C5E1FF65C5E1FF68B0CAFF5D8899FF7695A2FF59A2
      C4FF547E91FF010102200000000000000000000000002E546AC562C5E3FF63C4
      E1FF60B8D7FF9DA3A8FFEBE5E1FFDDE6EAFF5195B4FF65C3EFFF111517600000
      00000000000000000000000000000000000000000000BCBCBCFFFDFDFDFFACBA
      D7FFF8F8F8FFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6F6FFF5F5F5FFF4F4
      F4FFFCFCFCFFBCBCBCFF00000000000000002122227EDFCDBDFFC4BFC1FFD2C7
      C2FFEAD4BEFFE6D2C0FFE6D1BFFFE5D1BEFFE4D0BEFFE3CFBCFFF2DBC7FF8982
      7DEA0000001600000000000000000000000063A4B9FF68CBE5FF68CBE5FF68CB
      E5FF68CBE5FF68CBE5FF68CBE5FF68CBE5FF68CBE5FF67BAD1FF758F99FF629F
      BAFF547E91FF000000000000000000000000000000002E556AC566CCE9FF67CC
      E6FF63BDDBFF9EA2A8FFEBE4E0FFDFE7EBFF579BBAFF6FCBF5FF141A1C690000
      00000000000000000000000000000000000000000000BDBDBDFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFBDBDBDFF00000000000000002222237EE0CCBAFFCFC6C5FFD3C8
      C2FFEBD5BFFFE7D2C0FFE7D3C0FFE6D2BFFFE6D1BFFFE5D0BEFFF2DBC7FF8A83
      7EEA0000001600000000000000000000000068AABEFF6BD0E9FF6BD0E9FF6BD0
      E9FF6BD0E9FF6BD0E9FF6BD0E9FF6BD0E9FF6BD0E9FF6BD0E9FF78909BFF6CA6
      C1FF547E91FF000000000000000000000000000000002F566BC569D3EEFF6BD3
      EDFF66C2DEFF9BA0A4FFECE5E2FFE3EAEDFF5D9EBDFF77D2FCFF151A1D690000
      00000000000000000000000000000000000000000000BEBEBEFFFDFDFDFFACBA
      D7FFFAFAFAFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFF9F9F9FFF8F8F8FFF6F6
      F6FFFDFDFDFFBEBEBEFF00000000000000002222237EE0CDBBFFCEC5C4FFD3C8
      C2FFECD5C0FFE8D3C0FFE7D2C0FFE6D2BFFFE9D3C0FFEAD3C0FFF4DBC6FF948C
      85F0000000160000000000000000000000006CAFC1FF6ED5EDFF6ED5EDFF6ED5
      EDFF6ED5EDFF6ED5EDFF6ED5EDFF6ED5EDFF6ED5EDFF6ED5EDFF6C8995FF76AE
      C7FF547E91FF0000000000000000000000000000000030586DC56EDAF4FF70DB
      F2FF68C5E1FF9DA2A7FFDBD3CFFFBDCBD2FF63ACCCFF84DCFFFF151A1D690000
      00000000000000000000000000000000000000000000BFBFBFFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFBFBFBFFFCBCB
      CBFFDBDBDBFFA7A7A7EF00000000000000002223237EE1CEBCFFD3CBCAFFD3C8
      C2FFEDD6C1FFE9D4C2FFE8D3C1FFEDD6C2FFCABFB5FFA1A2A3FFDDD9D6FF7E7B
      76DB0000000600000000000000000000000072B4C5FF72DAF0FF72DAF0FF72DA
      F0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF72DAF0FF708A96FF80B5
      CEFF547E91FF00000000000000000000000000000000325A6EC573E1F9FF74E0
      F6FF6DCFE9FFDADEE3FFEAE2DFFF79AAC0FF76C7EDFF8BE0FFFF161A1D690000
      00000000000000000000000000000000000000000000BFBFBFFF949495FFACBA
      D7FFFBFBFBFFFCFCFCFFFCFCFCFFFCFCFCFFFBFBFBFFFAFAFAFFCBCBCBFFE2E2
      E2FFA8A8A8EF0606063000000000000000002223247EDFCCB9FFB7AEADFFD5C9
      C3FFECD5BFFFE8D3C0FFE8D2C0FFECD4BFFFC6BCB4FFE3E7E9FFCACBCBF40101
      01350000000000000000000000000000000077B9CBFF75E0F6FF75E0F6FF75E0
      F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF75E0F6FF738D97FF89BB
      D3FF547E91FF00000000000000000000000000000000335D6FC577EAFFFF73E8
      FCFF83DDF3FFFFFCFAFFAFC3CCFF61AFD2FF8ADCFFFF8FE6FFFF191F22700000
      00000000000000000000000000000000000000000000BFBFBFFFFFFFFFFFACBA
      D7FFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFAFAFAFFDBDBDBFFA8A8
      A8EF060606300000000000000000000000002222227EEEECE9FFBEC4CFFFE2E6
      EEFFFEFDFBFFFAFAF9FFF9F9F8FFFBFAF9FFF0F0EFFFB2B2B2EB030303430000
      0000000000000000000000000000000000007DBFCFFF78E5FAFF78E5FAFF78E5
      FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF78E5FAFF527586FF91C0
      D7FF547E91FF00000000000000000000000000000000355F72C579EDFDFF7AD4
      EDFF9CCEE3FFA1CEE3FE6DADCBF068A2BDE05C8AA0CF4F6E7CBE060707380000
      00000000000000000000000000000000000000000000BFBFBFFFBFBFBFFFBFBF
      BFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFA8A8A8EF0606
      0630000000000000000000000000000000002222227ED1D1D1FFD2D6DCFFC8CB
      D0FFD7D7D8FFD6D7D7FFD5D6D6FFD7D8D8FFDADADBFB0C0C0C5F000000000000
      0000000000000000000000000000000000004A6F78C083C4D3FF83C4D3FF83C4
      D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF83C4D3FF6C8894FF4F78
      85E01520248000000000000000000000000000000000386677C76FC8E2F45277
      8BC732505F9F192A337E0F131455030304270000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000001C0808
      08700E0E0E8E0E0E0E8F0E0E0E8E0E0E0E900C0B0C8600000031000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000005000000030000000000000000000000000000
      000000000000000000000000000000000000000000000000000014121267FFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCF8FCFF0404025D090A06483529
      2778050403290000000600000006000000030000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000534C44CD635E57D4635E59D5635F
      59D5635F59D56A645CD6100F0C90000000010000000000000000000000000000
      00000000000000000000000000000000000000000005180909674D3638A9F8F5
      F5FFF6F2F2FFF4EEEEFFF8F4F4FFFFFFFFFFD0CCD0F8220F14B7291614A41E11
      118542214FC72C161E942A131D9646201EAB0000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000D6CEC5FFFFFFFFFFFFFFFAFFFFFF
      F3FFFFF9EAFFFFFFFFFF262320AF000000000000000000000000000000000000
      00000000000000000000000000000000000000000010120808590D0B0B59FAF6
      F6FFF6F2F2FFF4EEEEFFF7F2F3FFFFEAFFFF70B578FC05A101F50D240EB90000
      0E851D132F9B2D203B9B04001069562D25B50000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C8C2B8FFFBF8F4FFF8F0E7FFF6EA
      DDFFF5E4D1FFFFF9EBFF1F1E1AA7000000000000000000000000000000000000
      0000000000000000000000000000000000000E080849301C1C83473C3C99F7F3
      F3FFF6F2F2FFF5EFEFFFF1EEEDFF91C295FF29B039FF00EC2AFF037229FA0B25
      1BC13127238C574749951811125674403ED00000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF6E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CEC7BEFFFFFFFFFFFFFFFDFFFFFC
      F4FFFFF3E7FFFFFFFBFF1C1A17A0000000000000000000000000000000030000
      0000000000000000000000000000000000001B101060301C1C83241E1E78F7F4
      F4FFF6F2F2FFF8F0F2FFEEE8E0FF00C42AFF00E265FF00E584FF00FB76FF00A6
      1CF41C14157027212166030302236B3738C90000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFBFAFFFBF7F0FFFAF2
      E9FFF7EDE0FF93846FFF00000000000000000000000000000000000000000610
      047000000010000000000000000000000000AEA597FDCEC7BFFDCDC7BEFDCFC8
      BFFED1CAC1FFD2CDC4FF4B453DCE0E0C0B7F0E0C0A880A090785000000100304
      03440000004800000000000000000000000001000019180D0D5F1B17176FF8F4
      F4FFF6F2F2FFF7EFF1FFF5F2EFFF7ADA8DFF2ECC62FF00FAB3FF168834E21C2D
      1795130F0F53211B1B5E01000014663434C30000000000000000000408400029
      48BF004B89FF000000000000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF000000001E54
      15FF14370ECF0001002000000000000000000000001400000014000000141211
      1064DFD8D0FFEAE4DDFFF7F0E7FFFFF5EAFFFFFDF1FFB9B0A4FF000000091C2F
      1AA80F4808F6000100590000000500000000261616734328289A514242A0F6F2
      F2FFF6F2F2FFF4EEEEFFF8F4F5FFFFFFFFFF84D896FE00C055F938462FAA100B
      0C424A3D3D8A594848971F17175D794242D6000000000017288F045B9DFF1B7A
      D7FB0861B1FF004B89FF004B89FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000093846FFFFAF2E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF000000001E54
      15FF196B15F71B4A13EF03080250000000000000000000000000000000000C0B
      0B4EF4F0E9FFFFFDF6FFFAF0E4FFF7E8D7FFFFF9E8FFA29B92F3000000081423
      139308980AFF186E13FF020701790000000002010120140B0B5A0D0C0C59F9F6
      F6FFF9F6F6FFF4EEEEFFF8F5F5FFFFFFFFFFBDC3BEEE0C09076A161111520000
      000008070733120F0F48000000005D2E2EBA00000000025490FF54ADE6FA62B1
      E7F52986E3F51969DFF5004B89FF00000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF000000000000000000000000000000000000
      000093846FFFFBF7F0FFFAF2E9FFF7EDE0FFF6E7D7FF93846FFF000000001E54
      15FF1E9F20ED1B6916F81E5415FF000000000000000000000000000000000B0B
      0A4FF7F3EFFFFFFFFFFFFDF5ECFFFAEEE0FFFFFEEFFFA29B92F3000000091625
      16931DC226FF13720FFD0003005E00000000130B0B543720208D584948A7FFFF
      FCFFF9F9F9FFFFF8F8FFFDF9F9FFFAF8F8FFFCF7FAFF4132359B5E494A9B1F1A
      1A5A4E3E3E8D5A49499821181860794242D700000000000E1870126397FF78B7
      E0FA126DB2FF004B89FF004B89FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000093846FFFFEFBFAFFFBF7F0FFFAF2E9FFF7EDE0FF93846FFF000000001E54
      15FF278224F61B4A13EF040C0360000000000000002400000035000000280A08
      067CEBE6DFFFEBE9E5FFFBF6F0FFFDF6EDFFF7F3EAFFACA397FF000000041C30
      1BAB10500CEE000000340000000000000000110B0B4E241514771512136AB7B5
      BEEBC4BCBAE68C8C8CD8A29F9FDECBC2C2E8696B6BC60D0A0A4B282020660000
      000D1410104C211B1B5E00000010653333C2000000000000000000040840013D
      69DF004B89FF000000000000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF000000001E54
      15FF14370ECF010300300000000000000000ADA395FFCDC6BDFFCCC5BCFFCEC6
      BCFFD1C9BEFFD2CBC1FF433E35CC0E0D0C691817166912111061000000000607
      0641010101230000000000000000000000000201012025161678160C2B981A14
      176D473837880604043114101051483939880403032D181313583E32327E0404
      0429231D1D63312828730504042C6C3838C90000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000815
      058000000010000000000000000000000000D1CBC3FFFFFFFFFFFFFDF4FFFFF7
      EAFFFCEBDAFFFFFFF4FF1A18159F000000000000000000000000000000000000
      0000000000000000000000000000000000002214146C4C2F30A52E1C52B81A15
      14615F4E4E9C1511114A282121665847479613101047332A2A73564545941310
      10493D32327E4A3D3D8A140F0F4D753F3FD20000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF6E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C8C2B8FFFBF9F6FFF9F2EAFFF7EC
      E0FFF5E5D4FFFFFAECFF211E1BA8000000000000000000000000000000000000
      0000000000000000000000000000000000002517156E41252DA0060014750000
      000F2F242471000000000201011E281E1E6A000000000504042D211919610000
      00000B08083C1611115100000000652E2EC60000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFBFAFFFBF7F0FFFAF2
      E9FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CDC6BBFFFFFFFFFFFFFFFEFFFFFD
      F6FFFFF9EEFFFFFFFDFF231F1BB1000000000000000000000000000000000000
      00000000000000000000000000000000000004030228371F2696200F12782112
      126E3821218D1C0E0E68251414763520208B1B0D0D662816167A331E1E89190D
      0D642C18187F301C1C851A0D0D67412020A50000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000005D5750C567615CC567615DC56763
      5DC567635DC56A665FC5110F0E75000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000100100
      0016000000080100001900000013000000090101011A000000110000000A0101
      011A0000000F0000000C01000019000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000001D12019F754D07FF634006FF1009008000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000686868FF686868FF676767FF676767FF666666FF656565FF656565FF6464
      64FF636363FF636363FF636363FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000008000000000000000000000000000000000000
      0000020100306B4506FF130B008F1D1000AF573402FF06030050000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000010000252F230A91090702630000000A00000000000000000000
      00000000000000000000000000000000000000000000246595FF246595FF2465
      95FF787878FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFEEEEEEFFF6F6F6FF727272FF000000000000000000000006000102440000
      024A070A0C805A5B5CD355565BD65A5C5ED5595B5DD5595A5DD5595B5DD5595A
      5DD55A5D5ED55B5C5DD60202025C000000000000000000000000000000000000
      000002010030613C05FF0603005000000000291700BF2E1B01BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000077D5204CE66460BBFC7831AE91711047F00000001000000000000
      00000000000000000000000000000000000000000000246595FF4C9DC1FF4E9F
      C4FF868686FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF818181FF00000000000000000304042F51A0CAFF51A4
      CCFF6696ACFFF0E3DCFFE0E2ECFFFFF5EBFFFCF2EAFFFBF2E9FFFBF2E9FFFAF1
      E9FFFFF7EEFFF3EBE5FF0404046D000000000000000000000000000000000000
      000000000000361F00DF4E3005EF06030050271600BF341D01BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000101011C955903DA00000004010000239E6514E000000029000000000000
      00000000000000000000000000000000000000000000246595FF4EA0C5FF50A3
      C6FF919191FFF2F2F2FF98A9CBFFE6E6E6FFE6E6E6FFE6E6E6FFE6E6E6FFE5E5
      E5FFE2E2E2FFF0F0F0FF8C8C8CFF0000000000000000040405336BB3D2FF6EC1
      DDFF85B3C2FFCBB7AAFFC7C2C6FFECD8C5FFE6D4C3FFE6D4C3FFE6D4C3FFE5D3
      C3FFEAD6C4FFE3D5C7FF040404690000000002010030130B008F130B008F0402
      00400000000004020040754507FFA46514FF7D4808FF10090080000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000865417CA1A1203870000001393570DDD02010044000000000000
      00000000000000000000000000000000000000000000296B99FF51A4C7FF52A7
      C9FF999999FFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF979797FF00000000000000000404053274B8D5FF68BB
      D9FF83B1C1FFE3D1C6FFD0CDD2FFECDAC9FFE8D8C9FFE8D8C9FFE8D8C9FFE7D7
      C8FFEBDACAFFE8DBCFFF05050569000000004F3203EF583702EF4A2902DF5932
      02FF221300AF00000010130B008FA4590EFF2E1900CF00000000000000000000
      000000000000000000000000000000000000000000000201003D150800890100
      00450000000005030138E38411FFA56411EC6C430BC90000000B000000000000
      000000000000000000000000000000000000000000002F729FFF53A9CAFF54AB
      CCFFA0A0A0FFF6F6F6FF98A9CBFFEEEEEEFFEEEEEEFFEEEEEEFFEDEDEDFFEBEB
      EBFFEAEAEAFFF3F3F3FF9E9E9EFF00000000000000000404053276BAD7FF6BC0
      DDFF88B7C5FFE5D2C7FFD0CDD1FFEDDBC9FFE9D9CAFFE9D9CAFFE9D8C9FFE8D8
      C9FFEBDACAFFEBDED2FF0506066900000000623D02FF1009008000000000180D
      009F91540AFF432602DF04020040492802EF462702DF00000000000000000000
      0000000000000000000000000000000000001C150672996910DC4A2F07A8B56A
      13E813070086000000002D160296DD7B17FF0100003700000000000000000000
      000000000000000000000000000000000000000000003477A4FF55ACCCFF56AF
      CFFFA6A6A6FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFA4A4A4FF00000000000000000404053278BCD8FF6DC3
      DEFF8DBCCBFFE0CDC2FFCECBCFFFEFDCCBFFEADACBFFEAD9CBFFE9D9CAFFE9D8
      CAFFEBDACAFFEEE0D5FF0606066900000000362101CF462A01EF040200400603
      00508F520AFFA55A0EFF683805FF231300BF462903FF0C0A0860000000000000
      000000000000000000000000000000000000A38027CC553807C0000000000403
      002EE18416FF311401B4000000318E440BE20703006400000000000000000000
      000000000000000000000000000000000000000000003C83ADFF57B0D0FF59B2
      D3FFA9A9A9FFF8F8F8FF98A9CBFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF2F2
      F2FFEFEFEFFFF6F6F6FFA7A7A7FF00000000000000000404053279BEDAFF70C7
      E2FF95C4D3FFD4C1B6FFC7C4C9FFF1DECDFFEBDACCFFEBDACCFFEADACBFFEAD9
      CAFFECDACAFFEFE2D6FF060606690000000002010030362000DF543001FF5A32
      02FF522F03EF462705BE271600BF462903FF625B51FF5B5B5BEF030303300000
      000000000000000000000000000000000000070604349C6815D7130800810100
      0034CA7911FDE17B0FFF5B2400D4250F03A341362CC300000010000000000000
      00000000000000000000000000000000000000000000428AB2FF59B4D4FF5BB6
      D7FFACACACFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFABABABFF0000000000000000040405327CC2DDFF73CB
      E4FF93C3D0FFEAD7CBFFD1CED3FFEFDCCBFFECDBCCFFEBDACBFFEBDACBFFEAD9
      CAFFECDBCAFFF0E3D6FF06060669000000000000000000000000040200400402
      004001000020000000000000000005050440595959EFA0A0A0FF565656EF0303
      033000000000000000000000000000000000000000000504022B754D12BBAD6C
      18EC332108940201002421160C71584C42D0A1A9B0FF1616168D000000060000
      000000000000000000000000000000000000000000004791B8FF5BB7D7FF5DBA
      D9FFADADADFFFBFBFBFF98A9CBFFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6
      F6FFF3F3F3FFF8F8F8FFADADADFF0000000000000000030405327DC4DFFF75CF
      E6FF95C6D4FFEAD7CBFFD1CED3FFEFDDCCFFECDBCCFFECDBCCFFEBDACBFFEDDC
      CDFFF0DECEFFF2E5D9FF0707076A000000000000000000000000000000000000
      00000000000000000000000000000000000003030330656565EF7A7A7AFF5A5A
      5AEF030303300000000000000000000000000000000000000000000000000000
      00060000000000000000000000000101011A7D7C7DD2ADADADFF1414148C0000
      000D00000000000000000000000000000000000000004F9AC0FF5EBBD9FF5FBD
      DCFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFB6B6
      B6FFB4B4B4FFBFBFBFFFADADADFF00000000000000000404053280C5DFFF78D3
      EAFF9ACDDAFFE1CEC2FFCECBD0FFF3E1CFFFEEDECEFFEEDECEFFEDDDCEFFE4D2
      C2FFE1CEBCFFF5E7DAFF07070769000000000000000000000000000000000000
      00000000000000000000000000000000000000000000090909507C7C7CFF7575
      75FF666666EF0909095000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000101011C999999F2B2B2B2FF2424
      249F0000000E00000000000000000000000000000000509DC1FF61BFDDFF62C1
      DEFFAFAFAFFFFCFCFCFF98A9CBFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFBCBC
      BCFFE9E9E9FFBABABAFF4343439F00000000000000000404053281C7E1FF7CD9
      F0FF9ACEDBFFD4BFB3FFC5C1C5FFEDD9C7FFE9D7C7FFECDAC9FFF0DCCAFFCDC5
      BDFFEAE9E8FFA4A2A2E400000022000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000191919807676
      76FF5A5A5AEF626262FF0D0D0D60000000000000000000000000000000000000
      0000000000000000000000000000000000000000000008080841A0A0A0FFA4A4
      A4FB2B2B2BA00000000F000000000000000000000000519EC2FF63C2E0FF898C
      8EFF787C7DFF717475FF696C6DFF696C6DFF626566FF626566FF626566FFE2E2
      E2FFBBBBBBFF4343439F0000000000000000000000000404053282CFE9FF7BBF
      CFFF929C9FFFB0B0B0FFA8ABAEFFB0B2B1FFB0B2B1FFA0A2A1FFD6D2D0FFFFF9
      F7FFA2A2A2E10000002800000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000002626
      269F4B4B4BDF09090950565656EF0D0D0D600000000000000000000000000000
      00000000000000000000000000000000000000000000000000002222227C3535
      35B61E1E1E8D1E1E1E88000000120000000000000000529FC2FF65C6E2FF66A7
      BAFF696B6BFF717374FF878C8EFF8F9899FF757878FF696A6BFF959595FFAFAF
      AFFF799EAFFF00000000000000000000000000000000040505358FD9F3FF97DD
      EBFF949899FFA4A5A5FFBCC1C2FFC6CFD1FFA7ABABFF9CA0A1FFC4D4D5FFC7EA
      F2FF030608680000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0010404040CF0D0D0D60000000100D0D0D600000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000002A2A
      2A90000000330202023100000019000000000000000053A0C4FF67CAE6FF69CC
      E7FF6E6F6FFFADB2B4FFA3A9AAFFB8C2C4FFB0B5B6FF676868FF74E1F7FF76E3
      F8FF368BB5FF00000000000000000000000000000000000000141A272F83212E
      358730373BA4414343C3A4A8A9F9B3B8BAFD3E4041C72D3336A71E2D3387162A
      3388000000200000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000102E2E2EAF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000101
      011C070707590000000000000000000000000000000054A3C5FF54A3C5FF55A4
      C6FF517587FF577D8EFF697880FF6B7C83FF507586FF527888FF57A9CBFF4AA0
      C5FF4096BCFF0000000000000000000000000000000000000000000000000000
      00000000000000000000515353C7565857D80000000000000000000000000000
      000000000000000000000000000000000000020202221616165F1F1F1F712626
      267D2E2E2E8A2E2E2E89393939983A3A3A9A3A3A3A9A393939982E2E2E892E2E
      2E8A2626267D1F1F1F711414155A0101011A0000000000000000000000000000
      0000000000000000000000000022000000300000003100000026000000020000
      0000000000000000000000000000000000000000000000000000000000000000
      0000696969FF696969FF686868FF676767FF666666FF666666FF656565FF6464
      64FF646464FF636363FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000100000008000000000000000D040404284C4C4CA89292
      92E3939393E49F9FA0ED9D9D9EEC9D9D9EEC9D9D9EEC9D9D9EEC9F9FA0ED9393
      93E4919292E34E4F51A9302B1F8C4F4126AA0000000000000000000000000000
      00090000006F001600C3002901E8002501ED001F00ED001100DB000100A90000
      0055000000090000000000000000000000000000000000000000000000000000
      0000797979FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFF6F6F6FF747474FF00000000000000000000000000000000000000000000
      00000909094B545659D356585BD65C5E5ED55C5E5FD55D5E5FD55D5E5FD55D5E
      5FD55E6062D52B2C2DBB0000000F000000000000000000000000969696D8C4C4
      C5FFB9B6AEFFBBB6AFFFBBB6AFFFBBB6AFFFBBB6AFFFBAB5AEFFBAB5AEFFBAB7
      AFFFC6C9CDFFB3A88EFCAF8427FFAF8D49E70000000000000000000000200018
      00C4007706FF018A08FF018808FF008407FF007906FF006205FF003E02FF0015
      00F00000008A0000001100000000000000000000000000000000000000000000
      0000888888FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFF838383FF00000000000000000000000000000000000000000000
      000014141461DFD9D6FFD8DAE3FFFFF5EBFFFBF2EAFFFBF1E9FFFAF1E8FFF9F0
      E7FFFFFFF7FF787674E70000000D000000000000000000000000959595D6C6C6
      C6FFC1C1BEFFBDB9B4FFBDBAB6FFBEBBB6FFBEBAB5FFC2C1C0FFC2C1C0FFC3C4
      C4FFBEB8ABFFAA7E25FFD2A85AFF0605032B0000000000000019002800D904A0
      12FF02A90DFF019F0AFF009D07FF009B00FF009B00FF009E07FF018B09FF005A
      05FF002000FD00000088000000090000000000000000696969FF696969FF6262
      62FF939393FFF3F3F3FF98A9CBFFE7E7E7FFE7E7E7FFE7E7E7FFE6E6E6FFE3E3
      E3FFF0F0F0FF909090FF000000000000000000000000000000000000000E0000
      00070B0B0B6EEADDD2FFCCC8CCFFE7D2C0FFE4D2C1FFE3D1C0FFE3D1C0FFE1CF
      BEFFF6E2D0FF6B6662DD0000000E0000000000000000000000009A9A9AD6CCCC
      CCFFCACBCAFFC2C0BBFFC3C1BCFFC0BDB9FFBDBAB5FFB9B9B8FFB2B2B2FFB2B4
      B6FFB1A68DFFCA9E45FF1C170E560000000000000000001600B00AA523FF09AD
      1FFF05A014FF009C07FF0CA211FF9BDBA0FF7DD083FF009800FF00A006FF0196
      0AFF005E05FF001A00F3000000530000000000000000797979FFF7F7F7FF8E96
      AAFF9D9D9DFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFF999999FF0000000000000000000000000606063C6E7072E76D70
      77E78A8A8AF2E0D5CCFFCECBD0FFEAD8C7FFE7D7C9FFE7D7C8FFE6D6C8FFE5D5
      C6FFF8E7D6FF716B68DD0000000E0000000000000000000000009D9D9DD6D1D1
      D1FFCFCECEFFB4B0A6FFB5B0A6FFC9C8C5FFC3C4C4FFC2C2C2FFDADADBFFDADA
      DAFFBEC0C4FFA1A19DE100000000000000000002006C0B7F22FE11B636FF0BA6
      27FF09A41EFF009D0BFF23AE2EFFFFFFFFFFFFFFFFFF83D289FF009500FF00A1
      06FF018D09FF004E03FF000200A70000000400000000888888FF7C7C7DFF8E96
      AAFFA3A3A3FFF6F6F6FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEBEB
      EBFFF4F4F4FFA0A0A0FF0000000000000000000000000A0A0A49DDD5CFFFD9D9
      E2FFD8D2CBFFDAD0C8FFCFCCD0FFECDAC9FFE9D9CAFFE9D8CAFFE8D8C9FFE7D6
      C8FFF8E6D6FF736F6BDD0000000E000000000000000000000000A2A2A2D6D6D6
      D6FFD4D3D1FFD5D5D5FFD5D5D5FFD3D4D2FFC3C3C3FFDDDDDCFFE2E1E0FFE5E4
      E5FFDFDFDFFFCECECFFF0000000000000000033E09D515A83FFF12AF3DFF00A3
      24FF00A119FF009D0FFF009500FF42B94DFFF0F9F1FFFFFFFFFF6DCA74FF0094
      00FF009C08FF017808FF001900DA0000002300000000939393FFF3F3F3FF8E96
      AAFFA7A7A7FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFA6A6A6FF000000000000000000000000090A0A46DDCFC4FFCFCB
      CFFFCAC1B7FFD8CEC7FFCDCACEFFEEDCCBFFEADACBFFEAD9CBFFE9D9CAFFE8D8
      C9FFF8E6D6FF75716DDD0000000E000000000000000000000000A4A4A4D6DBDC
      DDFFBEB8B1FFC2BEB8FFC2BEB7FFC4C1BBFFCFCFD0FFD4D1CDFFD6D4CFFFDAD8
      D4FFE7E7E7FFD8D8D8FF00000000000000000D8426FF18B04BFF1FB34FFF5FC9
      7DFF66CA7EFF60C876FF5CC56DFF48BB50FFAFE3B6FFFFFFFFFFFFFFFFFF6AC8
      70FF009901FF009808FF003502ED00000031000000009D9D9DFFD9B08CFF8E96
      AAFFABABABFFFAFAFAFF98A9CBFFF6F6F6FFF6F6F6FFF4F4F4FFF3F3F3FFF2F2
      F2FFF7F7F7FFAAAAAAFF0000000000000000000000000A0A0A46E0D4CAFFCFCC
      D0FFD0C7BEFFCCC2BAFFC7C5C9FFF1DFCDFFECDCCDFFEBDBCCFFEBDBCCFFEADA
      CBFFF8E6D5FF777370DD0000000E000000000000000000000000A8A8A8D6DEDE
      DEFFDDDEDFFFBCB8AFFFBFBBB2FFBAB6ACFFD7D6D5FFD6D6D6FFECECECFFEBEB
      ECFFD2D2D2FFB7B7B7E200000000000000000F8E2CFF22B755FF5DC984FFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFF25AD2DFF00A300FF003D03ED0000003100000000A3A3A3FFF6F6F6FF8E96
      AAFFADADADFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFACACACFF0000000000000000000000000A0A0A46E4D8CEFFD0CD
      D1FFCEC5BCFFE1D7CFFFD1CED3FFF0DDCCFFEDDCCDFFECDCCDFFECDBCBFFEFDE
      CEFFFAE8D7FF787471DD0000000E000000000000000000000000AAAAAAD6E2E2
      E2FFDFDEDEFFBAB5ACFFBBB6ADFFD7D5D2FFE2E2E3FFDFDFDFFFD9D9D9FFDADA
      DAFFE1E1E1FFBEBEBEE40000000000000000078B23FE4FC679FF4FC679FF89D8
      A5FF9ADEB3FF98DDB0FF94DBA8FF7BD292FFC3EBCCFFFFFFFFFFFFFFFFFF82D2
      8AFF029B05FF00A608FF003902E90000002100000000A7A7A7FF7C7C7DFF8E96
      AAFFADADADFFFBFBFBFF98A9CBFFFAFAFAFFFAFAFAFFF8F8F8FFA5A5A5FFA5A5
      A5FFBFBFBFFFADADADFF0000000000000000000000000A0A0A46DED2C7FFCBC8
      CCFFD1C8BEFFDFD5CDFFD0CDD2FFF1DECDFFEDDDCDFFEDDCCCFFEEE0D4FFDBCD
      C1FFEDDAC8FF85827CE40000000B000000000000000000000000ADADADD6E8E6
      E5FFECE8E6FFEFECE9FFEFECE9FFEDE9E7FFECE8E5FFECE8E6FFEAE6E3FFEBE7
      E4FFE8E6E5FFC2C2C2E40000000000000000005001CD51C276FF7ED9A2FF05AB
      3DFF04A93BFF08AB3EFF00A62EFF4CC26CFFE8F7EBFFFFFFFFFF81D28EFF009A
      02FF00A10CFF019D0BFF001800C50000000200000000ABABABFFFAFAFAFF8E96
      AAFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFA5A5A5FFF2F2
      F2FFC9C9C9FF737373CF0000000000000000000000000A0A0A46D8CCC1FFC6C2
      C7FFD0C7BDFFE0D5CCFFD1CDD1FFF0DCC9FFEDDBCAFFEFDCCBFFE4D3C4FFB3B0
      AEFFEFECEAFF474747BC00000000000000000000000000000000B2B1AFD6C7D8
      E5FF9DC4E0FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FF9DC4
      E0FFC7D8E5FFC8C6C5E40000000000000000030E025B1AA43AFDAAE9C7FF70D2
      93FF0DAE43FF05A93BFF39BD67FFFFFFFFFFFFFFFFFF6BCC84FF009E14FF06A3
      1EFF08B01DFF027C0BFF0000006E0000000000000000ADADADFFD9B08CFF8E96
      AAFFAFAFAFFFFEFEFEFF98A9CBFFFEFEFEFFFEFEFEFFFCFCFCFFBBBBBBFFBDBD
      BDFF737373CF000000100000000000000000000000000A0A0A46EADDD3FFD2CE
      D3FFD2C9BFFFD7D9DCFFCFD5E2FFFFFFFDFFFFFFFEFFFFFFFDFFFBF9F8FFFCFD
      FDFF747576D70000001700000000000000000000000000000000B3B3B1D667AE
      E2FF0078DAFF007CDAFF007CDAFF007CDAFF007CDAFF007CDAFF007CDAFF007D
      E3FF6DB8EEFFD4D4D4E90000000000000000000000000231069B45C46CFFCBF3
      DEFF85D8A3FF22B654FF19B24DFF8BD9A7FF62CB86FF00A730FF11AB36FF10B2
      32FF0AA623FF001900C90000000A0000000000000000ADADADFFFBFBFBFF8E96
      AAFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFF7373
      73CF00000010000000000000000000000000000000000A0A0A46E7DBD0FFD1CD
      D1FFD2C9C0FFCED1D4FFCBCED4FFDADBDDFFCCCDCEFFCFD0D1FFE2E3E4FF4F4F
      4FB8000000140000000000000000000000000000000000000000B3B3B2D6A7CF
      ECFF68B9EEFF6DBCEEFF6DBCEEFF6DBCEEFF6DBCEEFF6DBCEEFF6DC1F7FF7B80
      82FF736E69FF1414146700000000000000000000000000000009004F01BF45C4
      6CFFBCEED4FFBBECCFFF83D7A2FF53C87CFF4AC576FF4CC879FF2AC15BFF10AE
      34FF002C02D800000021000000000000000000000000AFAFAFFF7C7C7DFF8E96
      AAFFB5AAA0FFB5AAA0FFB5AAA0FFB5AAA0FFA5A5A5FFB8B8B8FF737373CF0000
      000000000000000000000000000000000000000000000A0A0A46E7DBD0FFD0CD
      D2FFEBDAC9FFE3D3C3FFE6D5C5FFDCCCBDFFB8B4B1FFECECECFF525252C50000
      0000000000000000000000000000000000000000000000000000B7B7B7D9F3EF
      EDFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFFFFEF9FF605F
      5DFF0E0E0E650000000000000000000000000000000000000000000000070330
      06991B9936F35EC882FF84D7A2FF7ED7A0FF61CC88FF34B85FFF11892FF6001E
      03AC0000001800000000000000000000000000000000AFAFAFFFFEFEFEFF98A9
      CBFFFEFEFEFFFEFEFEFFFCFCFCFFFBFBFBFFBDBDBDFF737373CF000000100000
      000000000000000000000000000000000000000000000A0A0A46E0E0E1FFCAD1
      DFFFFFFFFEFFFEFDFCFFFEFDFCFFFBFAF9FFEEEEEDFF6B6B6BCD000000160000
      0000000000000000000000000000000000000000000000000000545454939C9C
      9CCF989898CC989898CC989898CC989898CC989898CC989898CCA7A7A7D10B0B
      0B62000000000000000000000000000000000000000000000000000000000000
      00000310025E005100C600971FFF069827FF038F20FF004905CF0006006F0000
      00000000000000000000000000000000000000000000AFAFAFFFAFAFAFFFAFAF
      AFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFF737373CF00000010000000000000
      000000000000000000000000000000000000000000000A0A0A46DADBDCFFCCD0
      D7FFDFE0E1FFDFDFE0FFDEDFDFFFE5E5E6FFA6A6A6E600000020000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000002200000039010000550100005E0101005D0101
      005D0101005D0101005700000011000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000005000000030000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000002030155032A01DD28271FB4F5EFE7FFEFE8DFFFEEE5DBFFEDE4
      D8FFF3ECE1FF766E64E80000000D000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000534C44CD635E57D4635E59D5635F
      59D5635F59D56A645CD6100F0C90000000010000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000009007F108E1EFF004A01F11F1B18A2FFFFFFFFFFFAF1FFFCF0E4FFF9E8
      D6FFFFFFEFFF6D6762DD0000000E000000000000000000000000000000000004
      0840002948BF004B89FF000000000000000000000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000D6CFC5FFFFFFFFFFFFFFF8FFFFFD
      F1FFFFF9E8FFFFFFFFFF262320AF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000193516B260E36DFF07610EE71E1917A4FFFFFFFFFFFBF5FFFAF2E8FFF7E9
      DCFFFFFFF2FF6B665FDD0000000E0000000000000000000000000017288F045B
      9DFF1B7AD7FB0861B1FF004B89FF004B89FF0000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C9C2B9FFFBF6F1FFF8EFE5FFF6EA
      DDFFF5E4D1FFFFF9EBFF201E1BA8000000000000000000000000000000000000
      0000000000000000000000000000000000000000000A000000190000001C0000
      0019000000100A1C09AE0B5713F325221BB2FFFFFFFFFFFFFCFFFFFAF4FFFEF6
      EEFFFFFFFBFF7E766BF00000000B000000000000000000000000025490FF54AD
      E6FA62B1E7F52986E3F51969DFF5004B89FF00000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF93846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CEC7BEFFFFFFFFFFFFFFFEFFFFFD
      F7FFFFF8EDFFFFFFFFFF25221FAA000000000000000000000000000000000000
      000000000000000000000000000000000003797064E8918B83ED928C84EE928C
      84EE908782E8897F7BE6232A1AC7060605583733309533302D9533302D953331
      2E9534322F951B1A177A00000000000000000000000000000000000E18701263
      97FF78B7E0FA126DB2FF004B89FF004B89FF0000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000010300301B4A13EF00000000000000000000
      000000000000000000000000000000000000AEA597FDCEC7BFFDCDC7BEFDCCC5
      BDFDD3CCC3FDD4CDC5FA1915148C000000300202015C0E0C0A840D0C0A890D0C
      0A890E0C0B890E0D0B890705057600000008D5CFC6FFFFFFFFFFFFFFF6FFFFFC
      EFFFFFF7E5FFFFFFFFFF201C1BA2000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000004
      0840013D69DF004B89FF000000000000000000000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF040C03601B4A13EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF0000001400000014000000140000
      0014000000140000000C020B028A043200EB302F27BBFFFFFEFFFFFBF2FFFFF7
      EDFFFFF4E7FFFFFFF3FF7C756BE600000000C9C2B9FFFBF7F2FFF8F0E6FFF6EB
      DFFFF6E5D3FFFFFAECFF211E1BA8000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000091A068F206719FF149616FF1E5415FF0000000093846FFFFAF2
      E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF0000000000000000000000000000
      0000000000000218029F1CAC2DFF004601E9231F1DA6FFFFFFFFFFF6EDFFFAEE
      E1FFF7E5D3FFFFFDECFF65605AD500000000D4CDC3FFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFF6FFFFFFFFFF24211EAC000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000000000
      0000040C03601E5415FF51CF5AFF33CE39FF1E5415FF0000000093846FFFFBF7
      F0FFFAF2E9FFF7EDE0FFF4E7D7FF93846FFF0000000000000000000000000000
      00000000000010200D9462DA6DFF086210EB231D1AA7FFFFFFFFFFFEF9FFFDF5
      EDFFFAEDE0FFFFFFF6FF646059D500000000625B52D577726CDA77726CDA7772
      6CDA77726CDA7C7770DB12100D8F000000020000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000061004702A6522FF37BC3CFF1E5415FF0000000093846FFFFEFC
      FAFFFBF7F0FFFAF0E7FFF7EDE0FF93846FFF0000002400000035000000380000
      003800000035000000230A14099306430BE525221CB4FAF7F3FFF8F4EFFFF6F0
      EAFFF4EEE5FFF9F7EFFF716A60E600000000221E19A027241FAC282520AD2825
      20AD282521AD2C2822AE0907067B000000040000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF030802501B4A13EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFFADA395FFCDC6BCFFCCC5BBFFCCC4
      BAFFCCC3B9FFD5CCC3FF19151397000000250707074317161569161614691616
      146916161469171614690C0C0B5300000000D4CDC1FFFFFFFCFFFFFEF4FFFFFB
      F0FFFFF7E9FFFFFFFBFF26231FB0000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF000000000103003014370ECF00000000000000000000
      000000000000000000000000000000000000D1CCC3FFFFFFFDFFFFFAEFFFFFF6
      E9FFFFF0DEFFFFFFF8FF221F1DAA000000000000000000000000000000000000
      000000000000000000000000000000000000CAC3BBFFFCF7F1FFF9EFE3FFF7EB
      DCFFF6E4D1FFFFFAECFF211E1CA8000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000C9C2B9FFFBF8F3FFF9F0E6FFF6EB
      DFFFF6E6D5FFFFFAEDFF211E1BA8000000000000000000000000000000000000
      000000000000000000000000000000000000CCC5BCFFFFFFFFFFFFFCF6FFFFF6
      EDFFFEF2E4FFFFFFF9FF211F1BA9000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000CDC6BBFFFFFFFFFFFFFFFDFFFFFD
      F7FFFFFAF0FFFFFFFFFF231F1BB1000000000000000000000000000000000000
      000000000000000000000000000000000000BBB3A6FFE6E2DEFFE5E1DBFFE5DF
      D9FFE5DED6FFE9E6DEFF1C1A169F000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000005D5750C567615CC567635DC56763
      5DC567635DC56A665FC5110F0E75000000000000000000000000000000000000
      0000000000000000000000000000000000001F1D1A001D1B187E1E1B187E1E1C
      197E1E1C197E1F1D1A7E07060645000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000100100000100010000000000800800000000000000000000
      000000000000000000000000FFFFFF00FFFFFFFFFFFF0000C001C007C0070000
      8001800380030000800100010001000080010001400100008001000140010000
      800100007FF00000800100004000000080018000800000008001C000DFE00000
      8001E001E82100008001E007EFF700008001F007F41700008001F003F7FB0000
      8001F803F8030000FFFFFFFFFFFF0000FFFFFFFFFFFFFFFFC003FFFFFFFFC001
      DFFB800780078001D00B000700078001DFFB000300038001D00B000300038001
      DFFB000100018001D00B000100018001DFFB000100018001D00B000100018001
      DFFB000F000F8001D043801F801F8001DFD7C3F8C3F88001DFCFFFFCFFFC8001
      C01FFFBAFFBA8001FFFFFFC7FFC7FFFFFFFFFC01FC01FFFFC003FC01FC01C003
      DFFBFC01FC01C003D00BFC01FC01C003DFFBFC01FC01C003D00B80018001C003
      DFFB8001BC01C003D00B8001BC01C003DFFB8003BC03C003D00B8007BC07C003
      DFFB800FBC0FC003D043803FBFBFC003DFD7803FBC3FC007DFCF807FBD7FC00F
      C01F80FFBCFFC01FFFFF81FF81FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC003
      FFFFFFFFFFFFC0039F3F87C387C3C0038F1F83838383C003870FC107C107C003
      8307E00FE00FC0038103F01FF01FC0038001F83FF83FC0038103F01FF01FC003
      8307E00FE00FC003870FC107C107C0038F1F83838383C0079F3F87C387C3C00F
      FFFFFFFFFFFFC01FFFFFFFFFFFFFFFFF000000000000FFFF000000000000FFFF
      000000000000FFFF0000000000009F3F0000000000008F1F000000000000870F
      0000000000008307000000000000810300000000000080010000000000008103
      0000000000008307000000000000870F0000000000008F1F0000000000009F3F
      000000000000FFFF000000000000FFFF00000000000000000000000000000000
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
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000}
  end
end
