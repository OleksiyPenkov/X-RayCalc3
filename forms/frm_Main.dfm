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
    Position = 258
    Percent = 17
    UpperLeft.Color = 15987699
    LowerRight.Color = 15987699
    Align = alClient
    Color = 15987699
    TabOrder = 1
    ExplicitWidth = 1507
    ExplicitHeight = 841
    BarSize = (
      258
      0
      262
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
      Width = 252
      Height = 836
      Align = alClient
      BorderOuter = fsFlatRounded
      Color = 15987699
      TabOrder = 0
      object RzToolbar1: TRzToolbar
        Left = 2
        Top = 2
        Width = 248
        Height = 29
        Images = il_16
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        ParentShowHint = False
        ShowHint = True
        StyleName = 'Windows'
        TabOrder = 0
        ToolbarControls = (
          btnProjectAddFolder
          btnModelCreate
          btnModelProperites
          btnProjectItemCopy
          rzspcr2
          btnProjectItemDelete
          RzSpacer1
          BtnDown)
        object btnProjectAddFolder: TRzToolButton
          Left = 4
          Top = 2
          Action = ProjectAddFolder
          ParentShowHint = False
          ShowHint = True
        end
        object btnModelCreate: TRzToolButton
          Left = 29
          Top = 2
          Action = ModelCreate
          ParentShowHint = False
          ShowHint = True
        end
        object btnModelProperites: TRzToolButton
          Left = 54
          Top = 2
          Action = ModelProperites
          ParentShowHint = False
          ShowHint = True
        end
        object btnProjectItemCopy: TRzToolButton
          Left = 79
          Top = 2
          Action = ProjectItemCopy
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr2: TRzSpacer
          Left = 104
          Top = 2
        end
        object btnProjectItemDelete: TRzToolButton
          Left = 112
          Top = 2
          Action = ProjectItemDelete
          ParentShowHint = False
          ShowHint = True
        end
        object RzSpacer1: TRzSpacer
          Left = 137
          Top = 2
        end
        object BtnDown: TRzToolButton
          Left = 145
          Top = 2
          DisabledIndex = 39
          ImageIndex = 38
          Action = DataNorm
        end
      end
      object RzPanel5: TRzPanel
        AlignWithMargins = True
        Left = 5
        Top = 749
        Width = 242
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
          Width = 232
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
    end
    object pnlMain: TRzPanel
      AlignWithMargins = True
      Left = 356
      Top = 3
      Width = 893
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
        Width = 889
        Height = 163
        Hint = ''
        ActivePage = tsFittingProgress
        Align = alBottom
        TabIndex = 3
        TabOrder = 0
        ExplicitTop = 670
        ExplicitWidth = 885
        FixedDimension = 21
        object tsThickness: TRzTabSheet
          Color = 15987699
          Caption = 'Thickness'
          object chThickness: TChart
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 879
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
            Width = 879
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
            Width = 879
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
          ExplicitWidth = 881
          object chFittingProgress: TChart
            AlignWithMargins = True
            Left = 3
            Top = 3
            Width = 879
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
            ExplicitWidth = 875
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
        Width = 883
        Height = 464
        Cursor = crCross
        Foot.Visible = False
        Legend.Brush.Color = clSilver
        Legend.Brush.BackColor = clSilver
        Legend.Brush.Gradient.Direction = gdTopBottom
        Legend.Brush.Gradient.EndColor = 2152289
        Legend.Brush.Gradient.MidColor = 7548915
        Legend.Brush.Gradient.StartColor = 10109259
        Legend.CheckBoxes = True
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
        ExplicitWidth = 879
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
        Width = 883
        Height = 50
        Align = alBottom
        BorderOuter = fsFlatRounded
        Color = 15987699
        FlatColor = clSkyBlue
        TabOrder = 2
        ExplicitTop = 617
        ExplicitWidth = 879
        DesignSize = (
          883
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
          Left = 740
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
          ExplicitLeft = 736
        end
        object cbMinLimit: TRzComboBox
          Left = 821
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
          ExplicitLeft = 817
        end
      end
      object pnl1: TPanel
        Left = 2
        Top = 31
        Width = 889
        Height = 114
        Align = alTop
        BevelOuter = bvNone
        TabOrder = 3
        ExplicitWidth = 885
        object RzPanel6: TRzPanel
          AlignWithMargins = True
          Left = 459
          Top = 6
          Width = 427
          Height = 105
          Margins.Top = 6
          Align = alClient
          BorderOuter = fsFlatRounded
          Color = 15987699
          TabOrder = 0
          ExplicitWidth = 423
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
        Width = 889
        Height = 29
        Images = il_16
        BorderInner = fsNone
        BorderOuter = fsGroove
        BorderSides = [sdTop]
        BorderWidth = 0
        StyleName = 'Windows'
        TabOrder = 4
        ExplicitWidth = 885
        ToolbarControls = (
          btnCalcRun
          RzSpacer2
          BtnExecute
          rzspcr4
          btnResultSave
          btnBtnCopy
          rzspcr3
          btnDataLoad
          btnDataPaste)
        object btnDataLoad: TRzToolButton
          Left = 128
          Top = 2
          Action = DataLoad
          ParentShowHint = False
          ShowHint = True
        end
        object btnDataPaste: TRzToolButton
          Left = 153
          Top = 2
          Action = DataPaste
          ParentShowHint = False
          ShowHint = True
        end
        object rzspcr3: TRzSpacer
          Left = 120
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
          Left = 62
          Top = 2
        end
        object btnResultSave: TRzToolButton
          Left = 70
          Top = 2
          DisabledIndex = 35
          Action = ResultSave
          ParentShowHint = False
          ShowHint = True
        end
        object btnBtnCopy: TRzToolButton
          Left = 95
          Top = 2
          DisabledIndex = 37
          Action = ResultCopy
          ParentShowHint = False
          ShowHint = True
        end
        object RzSpacer2: TRzSpacer
          Left = 29
          Top = 2
        end
        object BtnExecute: TRzToolButton
          Left = 37
          Top = 2
          DisabledIndex = 41
          Action = actAutoFitting
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
        Images = il_16
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
          btnLayerCopy
          btnLayerPaste
          btnLayerDelete
          btnLayerCut)
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
        object btnLayerCopy: TRzToolButton
          Left = 137
          Top = 2
          Hint = 'Copy layer'
          Action = LayerCopy
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerPaste: TRzToolButton
          Left = 162
          Top = 2
          Hint = 'Paste layer'
          Action = LayerPaste
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerDelete: TRzToolButton
          Left = 187
          Top = 2
          Hint = 'Delete layer'
          Action = LayerDelete
          ParentShowHint = False
          ShowHint = True
        end
        object btnLayerCut: TRzToolButton
          Left = 212
          Top = 2
          Hint = 'Cut layer'
          Action = LayerCut
          ParentShowHint = False
          ShowHint = True
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
          Caption = 'Fit Limits'
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
                ImageIndex = 8
              end>
            Action = PeriodAdd
            Caption = '&Add'
            ImageIndex = 9
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Action = PeriodDelete
            Caption = '&Delete'
            ImageIndex = 10
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
                ImageIndex = 6
                ShortCut = 45
              end>
            Action = LayerAdd
            Caption = '&Add'
            ImageIndex = 5
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Caption = '-'
          end
          item
            Action = LayerDelete
            Caption = '&Delete'
            ImageIndex = 7
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
                ImageIndex = 0
              end
              item
                Action = FileOpen
                Caption = '&Open project ...'
                ImageIndex = 1
                ShortCut = 114
              end
              item
                Action = FileSave
                Caption = '&Save project'
                ImageIndex = 2
                ShortCut = 16467
              end
              item
                Action = FilePrint
                Caption = '&Print'
                ImageIndex = 3
              end
              item
                Action = FileClose
                Caption = '&Exit'
                ImageIndex = 4
              end>
            Caption = '&ActionClientItem0'
            KeyTip = 'F'
          end>
        AutoSize = False
      end
      item
        Items = <
          item
            Action = LayerCopy
            Caption = '&Copy'
            ImageIndex = 11
            ShortCut = 24643
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Action = LayerCut
            Caption = 'C&ut'
            ImageIndex = 12
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
                ImageIndex = 13
                ShortCut = 24662
              end>
            Action = LayerPaste
            Caption = '&Paste'
            ImageIndex = 13
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
            ImageIndex = 15
          end
          item
            Action = ModelProperites
            Caption = '&Properies'
            ImageIndex = 17
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
                ImageIndex = 11
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
                ImageIndex = 0
              end
              item
                Action = FileOpen
                Caption = '&Open project ...'
                ImageIndex = 1
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
                ImageIndex = 2
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
                ImageIndex = 3
              end
              item
                Caption = '-'
              end
              item
                Action = FileClose
                Caption = '&Exit'
                ImageIndex = 4
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
            ImageIndex = 15
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
            ImageIndex = 9
          end
          item
            Action = PeriodInsert
            Caption = '&Insert'
            ImageIndex = 8
          end
          item
            Action = PeriodDelete
            Caption = '&Delete'
            ImageIndex = 10
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = LayerInsert
                Caption = '&Insert'
                ImageIndex = 6
                ShortCut = 45
              end>
            Action = LayerAdd
            Caption = '&Add'
            ImageIndex = 5
            CommandProperties.ButtonSize = bsLarge
            CommandProperties.ButtonType = btSplit
          end
          item
            Caption = '-'
          end
          item
            Action = LayerCopy
            Caption = '&Copy'
            ImageIndex = 11
            ShortCut = 24643
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
            ImageIndex = 13
            ShortCut = 24662
            CommandProperties.ButtonType = btSplit
          end
          item
            Items = <
              item
                Action = LayerCut
                Caption = '&Cut'
                ImageIndex = 12
                ShortCut = 24664
              end>
            Action = LayerDelete
            Caption = '&Delete'
            ImageIndex = 7
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
                ImageIndex = 32
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
            ImageIndex = 27
            ShortCut = 118
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Action = CalcFitting
            Caption = '&Manual Fitting'
            ImageIndex = 17
            ShortCut = 117
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
                ImageIndex = 11
              end>
            Action = ResultSave
            Caption = '&Export'
            ImageIndex = 16
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
            ImageIndex = 15
          end
          item
            Action = ProjectAddFolder
            Caption = '&New Folder'
            ImageIndex = 1
          end
          item
            Action = ProjectItemExtension
            Caption = 'Ne&w extension'
            ImageIndex = 14
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
            Action = ModelProperites
            Caption = '&Properies'
            ImageIndex = 17
          end
          item
            Action = ProjectItemDelete
            Caption = '&Delete Item'
            ImageIndex = 16
          end>
      end
      item
        Items = <
          item
            Items = <
              item
                Action = DataPaste
                Caption = '&From clipboard'
                ImageIndex = 13
              end>
            Action = DataLoad
            Caption = '&Load'
            ImageIndex = 17
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
            ImageIndex = 0
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Caption = '-'
          end
          item
            Tag = 888
            Action = FileOpen
            Caption = '&Open'
            ImageIndex = 1
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
            ImageIndex = 2
            ShortCut = 16467
            CommandProperties.ButtonSize = bsLarge
          end
          item
            Caption = '-'
          end
          item
            Action = FileSaveAs
            Caption = 'S&ave as'
            ImageIndex = 2
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
    Images = il_16
    Left = 688
    Top = 200
    StyleName = 'Ribbon - Luna'
    object FileNew: TAction
      Category = 'Project'
      Caption = 'New project'
      ImageIndex = 0
      OnExecute = FileNewExecute
    end
    object FileOpen: TAction
      Category = 'Project'
      Caption = 'Open project ...'
      ImageIndex = 1
      ShortCut = 114
      OnExecute = FileOpenExecute
    end
    object FileSave: TAction
      Category = 'Project'
      Caption = 'Save project'
      ImageIndex = 2
      ShortCut = 16467
      OnExecute = FileSaveExecute
    end
    object FilePrint: TAction
      Category = 'Project'
      Caption = 'Print'
      ImageIndex = 3
      OnExecute = FilePrintExecute
    end
    object FileClose: TAction
      Category = 'Project'
      Caption = 'Exit'
      ImageIndex = 4
    end
    object LayerAdd: TAction
      Category = 'Layer'
      Caption = 'Add'
      ImageIndex = 5
      OnExecute = LayerAddExecute
    end
    object LayerInsert: TAction
      Category = 'Layer'
      Caption = 'Insert'
      ImageIndex = 6
      ShortCut = 45
      OnExecute = LayerInsertExecute
    end
    object LayerDelete: TAction
      Category = 'Layer'
      Caption = 'Delete'
      ImageIndex = 7
      ShortCut = 16430
      OnExecute = LayerDeleteExecute
    end
    object PeriodAdd: TAction
      Category = 'Period'
      Caption = 'Add'
      Hint = 'Add Stack'
      ImageIndex = 9
      OnExecute = PeriodAddExecute
    end
    object PeriodInsert: TAction
      Category = 'Period'
      Caption = 'Insert'
      Hint = 'Insert Stack'
      ImageIndex = 8
      OnExecute = PeriodInsertExecute
    end
    object PeriodDelete: TAction
      Category = 'Period'
      Caption = 'Delete'
      Hint = 'Delete stack'
      ImageIndex = 10
      OnExecute = PeriodDeleteExecute
    end
    object LayerCopy: TAction
      Category = 'Layer'
      Caption = 'Copy'
      ImageIndex = 11
      ShortCut = 24643
    end
    object LayerCut: TAction
      Category = 'Layer'
      Caption = 'Cut'
      ImageIndex = 12
      ShortCut = 24664
      OnExecute = LayerCutExecute
    end
    object LayerPaste: TAction
      Category = 'Layer'
      Caption = 'Paste'
      Hint = 'Paste & replace'
      ImageIndex = 13
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
      ImageIndex = 30
      ShortCut = 116
      OnExecute = CalcRunExecute
    end
    object ModelCreate: TAction
      Category = 'Project Item'
      Caption = 'New'
      Hint = 'Add project item'
      ImageIndex = 15
      OnExecute = ModelCreateExecute
    end
    object ModelProperites: TAction
      Category = 'Project Item'
      Caption = 'Properies'
      ImageIndex = 17
      OnExecute = ModelProperitesExecute
    end
    object DataLoad: TAction
      Category = 'Data'
      Caption = 'Load'
      ImageIndex = 17
      OnExecute = DataLoadExecute
    end
    object DataPaste: TAction
      Category = 'Data'
      Caption = 'From clipboard'
      ImageIndex = 13
      OnExecute = DataPasteExecute
    end
    object ResultSave: TAction
      Category = 'Result'
      Caption = 'Save'
      ImageIndex = 16
      OnExecute = ResultSaveExecute
    end
    object ResultCopy: TAction
      Category = 'Result'
      Caption = 'Copy to clipboard'
      ImageIndex = 11
      OnExecute = ResultCopyExecute
    end
    object FileSaveAs: TAction
      Category = 'Project'
      Caption = 'Save project As ...'
      ImageIndex = 2
      ShortCut = 113
      OnExecute = FileSaveAsExecute
    end
    object CalcTest: TAction
      Category = 'Calc'
      Caption = 'Test run'
    end
    object ProjectAddFolder: TAction
      Category = 'Project Item'
      Caption = 'New Folder'
      ImageIndex = 1
      OnExecute = ProjectAddFolderExecute
    end
    object CalcAll: TAction
      Category = 'Calc'
      Caption = 'Calc all models'
      ImageIndex = 32
      ShortCut = 123
    end
    object ProjectItemDelete: TAction
      Category = 'Project Item'
      Caption = 'Delete Item'
      ImageIndex = 16
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
      ImageIndex = 13
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
      ImageIndex = 14
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
    object CalcFitting: TAction
      Category = 'Calc'
      Caption = 'Manual Fitting'
      ImageIndex = 17
      ShortCut = 117
    end
    object actShowLibrary: TAction
      Category = 'Materials'
      Caption = 'Show Library'
    end
    object actAutoFitting: TAction
      Category = 'Calc'
      Caption = 'Auto Fitting'
      ImageIndex = 27
      ShortCut = 118
      OnExecute = actAutoFittingExecute
    end
  end
  object il_16: TImageList
    ColorDepth = cd32Bit
    Left = 80
    Top = 144
    Bitmap = {
      494C01012A003000040010001000FFFFFFFF2110FFFFFFFFFFFFFFFF424D3600
      000000000000360000002800000040000000B0000000010020000000000000B0
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000066CCCC0000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000066CCCC000099CC00000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000066CCCC000099CC000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000066CCCC0099FFFF000099CC0000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900E5E5E5009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000066CCCC000099CC000099CC000099CC0066FFFF000099CC00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099999900999999009999990099999900CCCCCC0099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000066CCCC0099FFFF0066FFFF0066FFFF0066FFFF0066FFFF000099CC000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099999900E5E5E500CCCCCC00CCCCCC00CCCCCC00CCCCCC00999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000066CCCC0099FFFF0066FFFF000099CC0066CCCC0066CCCC0066CC
      CC00000000000000000000000000000000000000000000000000000000000000
      00000000000099999900E5E5E500CCCCCC009999990099999900999999009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000066CCCC0099FFFF0066FFFF0066FFFF000099CC00000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900E5E5E500CCCCCC00CCCCCC0099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000066CCCC000099
      CC000099CC000099CC000099CC0099FFFF0066FFFF0066FFFF000099CC000000
      0000000000000000000000000000000000000000000000000000999999009999
      9900999999009999990099999900E5E5E500CCCCCC00CCCCCC00999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000066CCCC0099FF
      FF0099FFFF0066FFFF0066FFFF0066FFFF0066FFFF0066FFFF0066FFFF000099
      CC0000000000000000000000000000000000000000000000000099999900E5E5
      E500E5E5E500CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000066CC
      CC0099FFFF0099FFFF0066FFFF0066FFFF000099CC0066CCCC0066CCCC0066CC
      CC00000000000000000000000000000000000000000000000000000000009999
      9900E5E5E500E5E5E500CCCCCC00CCCCCC009999990099999900999999009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000000000066CC
      CC0099FFFF0099FFFF0099FFFF0066FFFF0066FFFF000099CC00000000000000
      0000000000000000000000000000000000000000000000000000000000009999
      9900E5E5E500E5E5E500E5E5E500CCCCCC00CCCCCC0099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000066CCCC0099FFFF0099FFFF0099FFFF0066FFFF0066FFFF000099CC000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099999900E5E5E500E5E5E500E5E5E500CCCCCC00CCCCCC00999999000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000066CCCC0099FFFF0099FFFF0099FFFF0066FFFF0066FFFF0066FFFF000099
      CC00000000000000000000000000000000000000000000000000000000000000
      000099999900E5E5E500E5E5E500E5E5E500CCCCCC00CCCCCC00CCCCCC009999
      9900000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000066CCCC0099FFFF0099FFFF0099FFFF0066FFFF0066FFFF0066FF
      FF000099CC000000000000000000000000000000000000000000000000000000
      00000000000099999900E5E5E500E5E5E500E5E5E500CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000066CCCC0066CCCC0066CCCC0066CCCC0066CCCC0066CCCC0066CC
      CC0066CCCC0066CCCC0000000000000000000000000000000000000000000000
      0000000000009999990099999900999999009999990099999900999999009999
      9900999999009999990000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC00006699000066990000669900006699000066
      9900006699000066990000669900000000000000000000000000000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000993300000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000099330000CC6600009933000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      00000000000099330000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      000099330000CC660000CC660000CC660000CC660000CC660000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00999999000000
      00000000000000000000000000000000000000000000CC996600CC996600CC99
      6600CC996600CC9966003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900999999009999
      9900999999009999990099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000009933
      0000CC660000CC660000CC660000CC660000CC660000CC660000CC6600009933
      0000000000000000000000000000000000000000000000000000000000009999
      9900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF0099FF
      FF0099FFFF0099FFFF0000669900000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC009999990000000000000000000000000099330000CC66
      0000CC660000CC660000CC660000CC660000CC660000CC660000CC660000CC66
      000099330000000000000000000000000000000000000000000099999900CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC003399CC003399CC003399CC00000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      990099999900999999009999990000000000000000000000000099330000CC66
      0000CC660000CC660000CC660000CC660000CC660000CC660000CC660000CC66
      000099330000000000000000000000000000000000000000000099999900CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00CCFFFF000066990000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900CCCCCC009999990000000000000000000000000000000000993300009933
      00009933000099330000CC660000CC660000CC66000099330000993300009933
      0000993300000000000000000000000000000000000000000000999999009999
      99009999990099999900CCCCCC00CCCCCC00CCCCCC0099999900999999009999
      99009999990000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC0099FFFF0099FFFF0099FFFF0099FFFF003399
      CC00006699000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      9900999999000000000000000000000000000000000000000000000000000000
      00000000000099330000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF003399CC003399CC003399CC003399CC003399CC003399
      CC00000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900999999009999
      9900000000000000000000000000000000000000000000000000000000000000
      00000000000099330000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099330000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC996600CC996600CC996600000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999009999990099999900000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099330000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600E5E5E500CC99660000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900000000009999990000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099330000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000CC996600FFFFFF00FFFF
      FF00FFFFFF00FFFFFF00CC996600CC9966000000000000000000000000000000
      0000000000000000000000000000000000000000000099999900000000000000
      0000000000000000000099999900999999000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009933000099330000993300009933000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000009999990099999900999999009999990099999900000000000000
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
      0000000000000000000000000000000000000000000000000000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300009933000099330000000000000000000000000000999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900000000009933000099330000993300009933
      0000000000000000000000000000993300009933000099330000993300000000
      0000000000000000000000000000000000009999990099999900999999009999
      9900000000000000000000000000999999009999990099999900999999000000
      0000000000000000000000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC00999999000000000099330000CC660000CC660000CC66
      000099330000000000000000000099330000CC660000CC660000CC6600009933
      00000000000000000000000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCCCC009999
      9900000000000000000000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC0099999900000000000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      0000993300000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500CC66000099330000E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500CCCCCC0099999900E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC009999990000000000000000000000000099330000CC66
      0000CC660000CC66000099330000000000000000000099330000CC660000CC66
      0000CC660000993300000000000000000000000000000000000099999900CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC009999990000000000000000000000000099330000CC660000CC66
      000099330000E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC0099999900E5E5E500E5E5E500E5E5E500E5E5E500E5E5E500E5E5E5009999
      9900CCCCCC00CCCCCC0099999900000000000000000000000000000000009933
      0000CC660000CC660000CC66000099330000000000000000000099330000CC66
      0000CC660000CC66000099330000000000000000000000000000000000009999
      9900CCCCCC00CCCCCC00CCCCCC0099999900000000000000000099999900CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000099330000CC660000CC66
      0000CC660000993300009933000099330000993300009933000099330000CC66
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00999999009999990099999900999999009999990099999900CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      000099330000CC660000CC660000CC6600009933000000000000000000009933
      0000CC660000CC660000CC660000993300000000000000000000000000000000
      000099999900CCCCCC00CCCCCC00CCCCCC009999990000000000000000009999
      9900CCCCCC00CCCCCC00CCCCCC00999999000000000099330000CC660000CC66
      0000CC660000CC660000CC660000CC660000CC660000CC660000CC660000CC66
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCCCC00CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000000000000000000000000
      000099330000CC660000CC660000CC6600009933000000000000000000009933
      0000CC660000CC660000CC660000993300000000000000000000000000000000
      000099999900CCCCCC00CCCCCC00CCCCCC009999990000000000000000009999
      9900CCCCCC00CCCCCC00CCCCCC00999999000000000099330000CC660000CC66
      0000993300009933000099330000993300009933000099330000993300009933
      0000CC660000CC66000099330000000000000000000099999900CCCCCC00CCCC
      CC00999999009999990099999900999999009999990099999900999999009999
      9900CCCCCC00CCCCCC0099999900000000000000000000000000000000009933
      0000CC660000CC660000CC66000099330000000000000000000099330000CC66
      0000CC660000CC66000099330000000000000000000000000000000000009999
      9900CCCCCC00CCCCCC00CCCCCC0099999900000000000000000099999900CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC009999990000000000000000000000000099330000CC66
      0000CC660000CC66000099330000000000000000000099330000CC660000CC66
      0000CC660000993300000000000000000000000000000000000099999900CCCC
      CC00CCCCCC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC009999990000000000000000000000000099330000CC6600009933
      0000FFFFFF00993300009933000099330000993300009933000099330000FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00999999009999990099999900999999009999990099999900FFFF
      FF0099999900CCCCCC0099999900000000000000000099330000CC660000CC66
      0000CC66000099330000000000000000000099330000CC660000CC660000CC66
      0000993300000000000000000000000000000000000099999900CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00999999000000000000000000000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC00999999000000000099330000CC660000CC660000CC66
      000099330000000000000000000099330000CC660000CC660000CC6600009933
      00000000000000000000000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC0099999900000000000000000099999900CCCCCC00CCCCCC00CCCCCC009999
      9900000000000000000000000000000000000000000099330000E5E5E5009933
      0000FFFFFF00993300009933000099330000993300009933000099330000FFFF
      FF00993300009933000099330000000000000000000099999900E5E5E5009999
      9900FFFFFF00999999009999990099999900999999009999990099999900FFFF
      FF00999999009999990099999900000000009933000099330000993300009933
      0000000000000000000000000000993300009933000099330000993300000000
      0000000000000000000000000000000000009999990099999900999999009999
      9900000000000000000000000000999999009999990099999900999999000000
      0000000000000000000000000000000000000000000099330000CC6600009933
      0000FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099330000CC66000099330000000000000000000099999900CCCCCC009999
      9900FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFFFF00FFFF
      FF0099999900CCCCCC0099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000099330000993300009933
      0000993300009933000099330000993300009933000099330000993300009933
      0000993300009933000099330000000000000000000099999900999999009999
      9900999999009999990099999900999999009999990099999900999999009999
      9900999999009999990099999900000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000040000002A0000
      0024000000080000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000027100360813708FF8137
      08FF5E4427FF6A6A6AFF6B6B6BFF646464FF797979FF6B6B6BFF626262FF5151
      51FF5E4427FF7C2600FF632602FF421702AF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000060012006500DF001B
      00A20002005C0000001C00000002000000000000000000000000000000000000
      00000000000000000000000000000000000000000000833808FFB54F0CFFB64F
      0DFF5E4427FF676767FF7C2600FF7C2600FFA3A3A3FFA9A9A9FF8F8F8FFF6B6B
      6BFF5E4427FF7C2600FF7B2D02FF762A03FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000C0014009C00FF0093
      00FB005900DD000800820000003E000000120000000100000000000000000000
      000000000000000000000000000000000000000000008F3F09FFBA540EFFBB54
      0EFF5E4427FF626262FF7C2600FF7C2600FFB5B5B5FFC0C0C0FFA0A0A0FF7777
      77FF5E4427FF7C2600FF7B2E03FF762A03FF0000000000000000000000000000
      0000993300009933000099330000993300009933000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000999999009999990099999900999999009999990000000000000000000000
      00000000000000000000000000000000000000000000000D001400A500FF00B1
      00FF00A500FE008500F4003A00C6000400720000002700000006000000000000
      0000000000000000000000000000000000000000000092420BFFBF5910FFC05A
      10FF5E4427FF5C5C5CFF7C2600FF7C2600FFC5C5C5FFDADADAFFB7B7B7FF8585
      85FF5E4427FF7C2600FF7D3003FF772B03FF0000000000000000000000000000
      000099330000CC660000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00AF00FF009E00FE006200E3001B00A200010047000000130000
      0002000000000000000000000000000000000000000096460CFFC46013FFC562
      14FF5E4427FF575757FF575757FF575757FFC9C9C9FFF3F3F3FFD0D0D0FF9595
      95FF5E4427FF7C2600FF7E3103FF792C04FF0000000000000000000000000000
      00000000000099330000CC660000CC660000CC660000CC660000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00999999000000
      00000000000000000000000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00B300FF00AC00FF008D00F8003A00C60006007E0000
      003A0000000900000000000000000000000000000000994E14FFCA6C21FFCB6E
      24FF91541DFF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E44
      27FF683510FF752C02FF883806FF7B2D04FF0000000000000000000000000000
      0000000000000000000099330000CC660000CC660000CC660000CC6600009933
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00B300FF00B300FF00B200FF00A000FE008400F40022
      00AF0001005D000000260000000600000000000000009D571EFFBA682AFFC394
      6DFFC0916BFFBE8E68FFBB8B65FFB98760FFB5825AFFB48058FFB37E57FFB17D
      57FFB07C56FFAF7B56FFA2440EFF7C2E04FF0000000000000000000000000000
      000000000000000000000000000099330000CC660000CC660000CC660000CC66
      0000993300000000000000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCC
      CC009999990000000000000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00B300FF00B300FF00B300FF00B300FF00A800FF0096
      00FB005F00E1001B00A1000100360000000200000000A0612BFFC38551FFEBEB
      EBFFE7E7E7FFE2E2E2FFDDDDDDFFD9D9D9FFD4D4D4FFD0D0D0FFCBCBCBFFCACA
      CAFFCACACAFFCACACAFFA85B29FF7D3004FF0000000000000000000000000000
      00000000000000000000000000000000000099330000CC660000CC660000CC66
      0000CC6600009933000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00B300FF00B300FF00B300FF00B300FF00B300FF00A9
      00FF009A00FF007700E80002003E0000000200000000A46936FFC18758FFDCDC
      DCFFD8D8D8FFD4D4D4FFD1D1D1FFCECECEFFCACACAFFC7C7C7FFC3C3C3FFBFBF
      BFFFBCBCBCFFBABABAFFA55926FF7D3105FF0000000000000000000000000000
      00000000000000000000000000000000000099330000CC660000CC660000CC66
      0000CC6600009933000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000099999900CCCCCC00CCCCCC00CCCC
      CC00CCCCCC0099999900000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00B300FF00B300FF00B300FF00B200FF00AC00FF0090
      00F6005300BD00150053000100080000000000000000A87141FFCC9568FFFEFE
      FEFFFBFBFBFFF7F7F7FFF2F2F2FFEEEEEEFFE9E9E9FFE5E5E5FFE0E0E0FFDADA
      DAFFD7D7D7FFD1D1D1FFAA5D2BFF7E3105FF0000000000000000000000000000
      000000000000000000000000000099330000CC660000CC660000CC660000CC66
      0000993300000000000000000000000000000000000000000000000000000000
      000000000000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCC
      CC009999990000000000000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00B300FF00B300FF00AC00FF009000F6005300BD0016
      00540003000E00000000000000000000000000000000A9764AFFC79269FFE1E1
      E1FFE1E1E1FFE1E1E1FFE0E0E0FFDDDDDDFFD9D9D9FFD7D7D7FFD3D3D3FFCFCF
      CFFFCCCCCCFFC9C9C9FFA95C29FF7E3105FF0000000000000000000000000000
      0000000000000000000099330000CC660000CC660000CC660000CC6600009933
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC009999
      99000000000000000000000000000000000000000000000D001400A700FF00B3
      00FF00B300FF00B300FF00AC00FF009000F6005300BD001600540003000E0000
      00000000000000000000000000000000000000000000AA784EFFCF9C73FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFCFCFCFFF8F8F8FFF4F4F4FFEFEF
      EFFFEBEBEBFFE6E6E6FFB0632EFF803205FF0000000000000000000000000000
      00000000000099330000CC660000CC660000CC660000CC660000993300000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC00999999000000
      00000000000000000000000000000000000000000000000D001400A500FF00B2
      00FF00AC00FF009000F6005300BD001600540003000E00000000000000000000
      00000000000000000000000000000000000000000000AA774BFFC7946AFFE1E1
      E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFDEDE
      DEFFDCDCDCFFD8D8D8FFAC602BFF7E3205FF0000000000000000000000000000
      000099330000CC660000CC660000CC660000CC66000099330000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000099999900CCCCCC00CCCCCC00CCCCCC00CCCCCC0099999900000000000000
      00000000000000000000000000000000000000000000000C0014009C00FF0090
      00F6005300BD001600540003000E000000000000000000000000000000000000
      00000000000000000000000000000000000000000000AA774BFFBA8258FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFE
      FEFFFEFEFEFFFAFAFAFFA95E2EFF742B03FF0000000000000000000000000000
      0000993300009933000099330000993300009933000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000999999009999990099999900999999009999990000000000000000000000
      00000000000000000000000000000000000000000000000A0012005200B40016
      00540003000E0000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000AA774BFFBA8258FF2814
      77FF281477FF281477FF281477FF281477FF281477FF281477FF281477FF2814
      77FF281477FF281477FFA95E2EFF742B03FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000010002000200090000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000582E0FC1723323FF320C
      57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C
      57FF320C57FF320C57FF692412FF511E02C10000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000008
      0A100991B4FF0991B4FF00181F300000000000000000002E3E600991B4FF0991
      B4FF00080A100000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF323232FF006599FFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000482323B3482323B34823
      23B3482323B3482323B3482323B3482323B3482323B3482323B3482323B34823
      23B3482323B3482323B3482323B3000000000000000000000000000000000991
      B4FF57CCDEFF5BD7E6FF0991B4FF0991B4FF0991B4FF0C99BAFF20C9DEFF14B8
      D1FF0991B4FF00000000000000000000000024242430BDBDBDFFCCCCCCFFCCCC
      CCFFCCCCCCFFCBCBCBFFCBCBCBFFCACACAFFC9C9C9FFC7C7C7FFC5C5C5FFC5C5
      C5FFC5C5C5FFC5C5C5FFC0C0C0FF24242430FFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF006599FFF0FBFFFF003265FF003265FFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000482323B30DB1DAFF0DB1
      DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1
      DAFF0DB1DAFF0DB1DAFF482323B3000000000000000000000000000000000991
      B4FF80E3EFFF6EE0EDFF58D5E6FF51D8E7FF3ECEE1FF35D0E3FF28CCE1FF1DC7
      DEFF0991B4FF000000000000000000000000464646EF747474FFE2E2E2FFFBFB
      FBFFFAFAFAFFF8F8F8FFF4F4F4FFF0F0F0FFEBEBEBFFE5E5E5FFDDDDDDFFDCDC
      DCFFDCDCDCFFD4D4D4FF838383FF464646EFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF006599FFF0FBFFFFCCFFFFFF65CCFFFF993200FFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF00000000482323B3FD001DFFFD00
      1DFFFD001DFFFD001DFFFD001DFFFD001DFFFD001DFFFD001DFFFD001DFFFD00
      1DFFFD001DFFFD001DFF482323B3000000000000000000000000000000000991
      B4FF88E5F0FF71DCE9FF4EC6DAFF58CADDFF51C9DCFF32BFD5FF2DC9DEFF20C1
      D8FF0991B4FF000000000000000000000000423F3EFF030202FF989797FFF3F3
      F3FFFAFAFAFFF8F8F8FFF4F4F4FFEFEFEFFFEAEAEAFFE5E5E5FFDDDDDDFFDCDC
      DCFFDCDCDCFFB5B5B5FF0A0909FF423F3EFF545454FF323232FF323232FF3232
      32FF323232FFB2B2B2FFFFFFFFFF006599FF65CCFFFFCC9932FFFF9900FF9932
      00FFFFFFFFFFB2B2B2FF323232FF545454FF00000000482323B3FD001DFF21BD
      E1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BD
      E1FF21BDE1FF21BDE1FF482323B300000000002633500991B4FF0991B4FF4FC6
      DAFF6CD5E5FF74D5E3FF0991B4FF0991B4FF0991B4FF0991B4FF45C9DDFF27C2
      D9FF12A7C5FF0991B4FF0991B4FF001015206C6562FF766963FF262323FF6767
      67FF777777FF767676FF757575FF747474FF727272FF6F6F6FFF6D6D6DFF6C6C
      6CFF686868FF474443FF766963FF6C6562FF656565FFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFF006599FFF0CAA6FFFFFFCCFFCC9932FFFF99
      00FF993200FFFFFFFFFFFFFFFFFF656565FF00000000482323B3FD001DFF2CC2
      E4FF2CC2E4FF2CC2E4FF2CC2E4FF2CC2E4FF2CC2E4FF2CC2E4FF2C0096FF2C00
      96FF2C0096FF2C0096FF482323B3000000000991B4FF35BFD7FF45C7DCFF69DE
      EBFF62CCDEFF0991B4FF919191FF919191FF919191FF919191FF0991B4FF3FC2
      D8FF2CCCE1FF17B5D0FF10B0CBFF0991B4FF6E6764FF8E7E77FF1C1817FF0604
      04FF060404FF060404FF060404FF060404FF060404FF060404FF060404FF0604
      04FF060404FF1C1817FF8E7E77FF6E6764FF656565FFFFFFFFFFEAEAEAFFEAEA
      EAFFEAEAEAFFEAEAEAFFF8F8F8FFFFFFFFFFCC6500FFF0CAA6FFFFFFCCFFCC99
      32FFFF9900FF993200FFFFFFFFFFC0C0C0FF00000000482323B3FD001DFF36C8
      E7FF36C8E7FF36C8E7FF2C0096FF2C0096FF2C0096FF2C0096FF36C8E7FF2C00
      96FF36C8E7FF36C8E7FF482323B3000000000991B4FF46D5E6FF53D8E9FF48C9
      DCFF0991B4FF919191FFFEFEFEFFFCFCFCFFF4F4F4FFDDDDDDFF919191FF0991
      B4FF2CC5DAFF29CCE1FF1DC7DEFF0991B4FF716A67FF93867EFF322A29FF291F
      21FF291F21FF291F21FF291F21FF291F21FF291F21FF291F21FF291F21FF291F
      21FF291F21FF322A29FF93867EFF716A67FF656565FFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFCC6500FFF0CAA6FFFFFF
      CCFFCC9932FFFF9900FF993200FFFFFFFFFF00000000482323B3FD001DFF40CE
      EBFF40CEEBFF2C0096FF40CEEBFF2C0096FF40CEEBFF40CEEBFF40CEEBFF2C00
      96FF40CEEBFF40CEEBFF482323B3000000000991B4FF2BBCD4FF49D5E6FF39C0
      D7FF0991B4FF919191FFF7F7F7FFF7F7F7FFF0F0F0FFDDDDDDFF919191FF0991
      B4FF2ABCD4FF33CFE2FF14ACC9FF0991B4FF766F6CFF9E918BFF24201FFF1C18
      19FF1C1819FF1C1819FF1C1819FF1C1819FF1C1819FF1C1819FF1C1819FF1C18
      19FF1C1819FF1B1717FF9E918BFF766F6CFF767676FFFFFFFFFFF8F8F8FFF8F8
      F8FFF8F8F8FFF8F8F8FFF8F8F8FFF8F8F8FFF8F8F8FFFFFFFFFFCC6500FFF0CA
      A6FFFFFFCCFFCC9932FF0032FFFF0000CCFF00000000482323B3FD001DFF2C00
      96FF2C0096FF4AD4EEFF4AD4EEFF2C0096FF4AD4EEFF4AD4EEFF4AD4EEFF4AD4
      EEFF4AD4EEFF4AD4EEFF482323B300000000000000000991B4FF2DBCD4FF33BF
      D5FF0991B4FF919191FFE1E1E1FFE9E9E9FFE2E2E2FFCFCFCFFF919191FF0991
      B4FF32BDD5FF1EABC7FF0991B4FF000000007D7775FFACA09CFF030202FF3934
      34FF393434FF393434FF393434FF393434FF393434FF393434FF393434FF3934
      34FF393434FF030202FFACA09CFF7D7775FF767676FFFFFFFFFFFFECCCFFFFEC
      CCFFFFECCCFFFFECCCFFFFECCCFFFFECCCFFF1F1F1FFEAEAEAFFFFFFFFFFCC65
      00FFF0CAA6FFFFFFFFFF0032FFFF0000CCFF00000000482323B3FD001DFF54DA
      F2FF2C0096FF54DAF2FF54DAF2FF2C0096FF54DAF2FF54DAF2FF54DAF2FF54DA
      F2FF54DAF2FF54DAF2FF482323B30000000000000000001015200991B4FF43D4
      E6FF0991B4FF919191FFAAAAAAFFC9C9C9FFC5C5C5FFA6A6A6FF919191FF0991
      B4FF55D8E9FF0991B4FF0000000000000000636261FF655F5EFF080707FF5856
      56FF585656FF585656FF585656FF585656FF585656FF585656FF585656FF5856
      56FF585656FF080707FF736D6BFF636261FF767676FFFFFFFFFFFFECCCFFFFEC
      CCFFFFECCCFFFFECCCFFFFECCCFFFFECCCFFF8F8F8FFF8F8F8FFFFFFFFFFFFFF
      FFFFCC6500FF0032FFFFFFCCFFFF0032CCFF00000000482323B3FD001DFF5EE0
      F5FF2C0096FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0
      F5FF5EE0F5FF5EE0F5FF482323B30000000000000000002633500991B4FF3AD1
      E3FF34C4D9FF0991B4FF919191FF919191FF919191FF919191FF0991B4FF54CB
      DEFF61DCEAFF0991B4FF00181F30000000000F0F0F3004040440000000400303
      04CF000000FF020202FF040303FF060404FF070505FF040303FF020202FF0000
      00FF010104CF00000040040404400F0F0F30808080FFFFFFFFFFFFECCCFFFFEC
      CCFFFFECCCFFFFECCCFFFFECCCFFFFECCCFFF8F8F8FFD7D7D7FFD7D7D7FFF1F1
      F1FFFFFFFFFF0032CCFF0000CCFFFFFFFFFF00000000482323B3FD001DFF69E5
      F8FF2C0096FF69E5F8FF69E5F8FF69E5F8FF69E5F8FF69E5F8FF69E5F8FF69E5
      F8FF69E5F8FF69E5F8FF482323B300000000000000000991B4FF27CBE1FF32CF
      E2FF3DD3E5FF37C4D9FF0991B4FF0991B4FF0991B4FF0991B4FF71D7E6FF7CE2
      EEFF6BDEEBFF5CDAEAFF0991B4FF000000000000000000000000000000000C0C
      14BF25202DFF18151DFF100D12FF0F0D12FF0F0C11FF0E0C10FF151217FF201A
      22FF0C0B11BF000000000000000000000000808080FFFFFFFFFFF0CAA6FFFFEC
      CCFFFFECCCFFFFECCCFFFFECCCFFFFECCCFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFCBCBCBFF00000000482323B373EBFCFF73EB
      FCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EB
      FCFF73EBFCFF73EBFCFF482323B300000000000000000991B4FF1DC0D8FF23C2
      D9FF0991B4FF40D3E5FF4CD7E7FF58D9E9FF66DDEBFF73E1EDFF76DDEAFF0991
      B4FF77E1EEFF5FD7E6FF0991B4FF000000000000000000000000000000000806
      0EBF26212EFF27222FFF27222EFF26202CFF251F2BFF241E29FF231E27FF211B
      24FF06060EBF000000000000000000000000868686FFFFFFFFFFF8F8F8FFF8F8
      F8FFFFFFFFFF414141FF282828FF282828FF282828FF282828FF383838FFFFFF
      FFFFF8F8F8FFF8F8F8FFFFFFFFFF868686FF00000000482323B37DF1FFFF7DF1
      FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1
      FFFF7DF1FFFF7DF1FFFF482323B3000000000000000000080A100991B4FF0991
      B4FF002633500991B4FF0991B4FF4FD7E7FF5BDAEAFF0991B4FF0991B4FF0026
      33500991B4FF0991B4FF00080A10000000000000000000000000000000000303
      0550171420FF27222FFF27222EFF26202CFF251F2BFF241E29FF231E27FF1411
      1BFF03030550000000000000000000000000868686FFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFF5E5E5EFFFFFFFFFFF8F8F8FFF8F8F8FFFFFFFFFF5E5E5EFFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFF868686FF00000000482323B3482323B34823
      23B3482323B3482323B3482323B3482323B3482323B3482323B3482323B34823
      23B3482323B3482323B3482323B3000000000000000000000000000000000000
      000000000000000000000991B4FF46D4E6FF52D8E7FF0991B4FF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006060B9F181521FF27222EFF26202CFF251F2BFF241E29FF16131DFF0606
      0B9F00000000000000000000000000000000969696FF969696FF868686FF8686
      86FF969696FF767676FFFFECCCFFFFCCCCFFFFCCCCFFFFECCCFF767676FF9696
      96FF868686FF868686FF969696FF969696FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000045F78AF0991B4FF0991B4FF00364870000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000003030765080811C813111CFF13111BFF08080FC8030307650000
      000000000000000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFF868686FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF868686FFFFFF
      FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF020202221616165F1F1F1F712626
      267D2E2E2E8A2E2E2E89393939983A3A3A9A3A3A3A9A393939982E2E2E892E2E
      2E8A2626267D1F1F1F711414155A0101011A0000000000000000000000000000
      0000030100203B1E0D8F80411DCFCC6A34FFCF7038FF874720CF41220F8F0301
      0020000000000000000000000000000000000000000000000000000000000000
      000000000000000000003F332800005F93000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000180C06206B35198F9E5025CFCC6A34FFCF7038FFA55727CF753E1B8F1B0E
      0620000000000000000000000000000000000000000D040404284C4C4CA89292
      92E3939393E49F9FA0ED9D9D9EEC9D9D9EEC9D9D9EEC9D9D9EEC9F9FA0ED9393
      93E4919292E34E4F51A9302B1F8C4F4126AA000000000000000000000010391D
      0D8FC25E29FFD1652AFFDA6F35FFDE7B41FFE38A4EFFE89A5EFFE69D61FFDE88
      4AFF4424108F0000001000000000000000000000000000000000000000000000
      00000000000000000000005F9300E7FAFF00003A5D00003A5D00000000000000
      00000000000000000000000000000000000000000000000000000B0603106733
      188FC25E29FFD1652AFFDA6F35FFDE7B41FFE38A4EFFE89A5EFFE69D61FFDE88
      4AFF7A411D8F0E07031000000000000000000000000000000000969696D8C4C4
      C5FFB9B6AEFFBBB6AFFFBBB6AFFFBBB6AFFFBBB6AFFFBAB5AEFFBAB5AEFFBAB7
      AFFFC6C9CDFFB3A88EFCAF8427FFAF8D49E70000000000000010773A1BCFC65A
      29FFD25F25FFD66729FFDA702FFFDF7936FFE4843DFFE98F45FFEF9C52FFF4B9
      78FFEEAB6BFF914E22CF00000010000000000000000000000000000000000000
      00000000000000000000005F9300E7FAFF00D0F9FF0052CBFF00A13400000000
      000000000000000000000000000000000000000000000B050310934721CFC65A
      29FFD25F25FFD66729FFDA702FFFDF7936FFE4843DFFE98F45FFEF9C52FFF4B9
      78FFEEAB6BFFB3602ACF0E070310000000000000000000000000959595D6C6C6
      C6FFC1C1BEFFBDB9B4FFBDBAB6FFBEBBB6FFBEBAB5FFC2C1C0FFC2C1C0FFC3C4
      C4FFBEB8ABFFAA7E25FFD2A85AFF0605032B00000000371A0C8FC25B2EFFCE5A
      26FFD25F23FFD66729FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF994DFFF4A5
      55FFFAC17BFFEFAD6DFF4424108F000000005D534A003F3328003E3327003E33
      27003E332700B0ABA60000000000005F930052CBFF00E2943100FF9D0000A134
      000000000000B0ABA6003F3328005F544A00000000006330168FC25B2EFFCE5A
      26FFD25F23FFD66729FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEF994DFFF4A5
      55FFFAC17BFFEFAD6DFF7A411D8F0000000000000000000000009A9A9AD6CCCC
      CCFFCACBCAFFC2C0BBFFC3C1BCFFC0BDB9FFBDBAB5FFB9B9B8FFB2B2B2FFB2B4
      B6FFB1A68DFFCA9E45FF1C170E560000000002010020B85A2EFFCB5D2EFFCE57
      1DFFD15E22FFD56628FFDA6F2EFFFFFFFFFFFFFFFFFFE88C43FFED964AFFF19F
      51FFF5A656FFF5BB7AFFDF894BFF030100207369600000000000000000000000
      0000000000000000000000000000005F9300F4D7A500FFFAD100E2943100FF9D
      0000A1340000000000000000000073696000160A0520B85A2EFFCB5D2EFFCE57
      1DFFD15E22FFD56628FFDA6F2EFFFFFFFFFFFFFFFFFFE88C43FFED964AFFF19F
      51FFF5A656FFF5BB7AFFDF894BFF1B0E062000000000000000009D9D9DD6D1D1
      D1FFCFCECEFFB4B0A6FFB5B0A6FFC9C8C5FFC3C4C4FFC2C2C2FFDADADBFFDADA
      DAFFBEC0C4FFA1A19DE1000000000000000035190C8FC4663DFFCA531CFFCD56
      1CFFD05D21FFD46426FFD86C2DFFFFFFFFFFFFFFFFFFE5873FFFE98F45FFED96
      4BFFEF9B4EFFF09F54FFE79F64FF41220F8F7368600000000000F1EAE300F1EA
      E400F1EAE400F1EAE400F9F6F40000000000D56B0300F4D7A500FFFAD100E294
      3100FF9D0000A134000000000000C5C1BE00602D158FC4663DFFCA531CFFCD56
      1CFFD05D21FFD46426FFD86C2DFFFFFFFFFFFFFFFFFFE5873FFFE98F45FFED96
      4BFFEF9B4EFFF09F54FFE79F64FF753E1B8F0000000000000000A2A2A2D6D6D6
      D6FFD4D3D1FFD5D5D5FFD5D5D5FFD3D4D2FFC3C3C3FFDDDDDCFFE2E1E0FFE5E4
      E5FFDFDFDFFFCECECFFF0000000000000000713519CFD07850FFCA5019FFCC54
      1BFFCF5A1FFFD36124FFD7692AFFFFFFFFFFFFFFFFFFE2803BFFE58740FFE88D
      44FFEA9046FFEA9147FFE99D61FF874720CF776D630000000000FFFEFB00FFFF
      FB00FFFFFB00FFFFFB00FFFFFB00FFFFFE0000000000D0690600F4D7A500FFFA
      D100E2943100FF9D0000A1340000000000008B411FCFD07850FFCA5019FFCC54
      1BFFCF5A1FFFD36124FFD7692AFFFFFFFFFFFFFFFFFFE2803BFFE58740FFE88D
      44FFEA9046FFEA9147FFE99D61FFA55727CF0000000000000000A4A4A4D6DBDC
      DDFFBEB8B1FFC2BEB8FFC2BEB7FFC4C1BBFFCFCFD0FFD4D1CDFFD6D4CFFFDAD8
      D4FFE7E7E7FFD8D8D8FF0000000000000000B55F38FFD37C55FFCF612DFFCC55
      1CFFCE571DFFD15E22FFD46427FFFFFFFFFFFFFFFFFFDE7835FFE17E39FFE383
      3DFFE5853EFFE5863FFFE48D50FFD07139FF7C71660000000000FFF8EA00FFF8
      EC00FFF8EC00FFF8EC00FFF8EC00FFF9EC00FBF9F80000000000CC690800F4D7
      A500FFFAD100E29431000024F6000015C800B55F38FFD37C55FFCF612DFFCC55
      1CFFCE571DFFD15E22FFD46427FFFFFFFFFFFFFFFFFFDE7835FFE17E39FFE383
      3DFFE5853EFFE5863FFFE48D50FFD07139FF0000000000000000A8A8A8D6DEDE
      DEFFDDDEDFFFBCB8AFFFBFBBB2FFBAB6ACFFD7D6D5FFD6D6D6FFECECECFFEBEB
      ECFFD2D2D2FFB7B7B7E20000000000000000B5603AFFD5825BFFD06533FFD165
      31FFD05F27FFCF5B21FFD26023FFFFFFFFFFFFFFFFFFDB7030FFDD7533FFDE79
      36FFDF7B37FFE07B37FFDF7E44FFCC6B35FF80756B0000000000FFF2DE00FFF3
      E000FFF3E000FFF3E000FFF3E000FFF3DF00F7F4F100EDE9E50000000000CD6C
      0C00F4D7A500000000000024F6000015C800B5603AFFD5825BFFD06533FFD165
      31FFD05F27FFCF5B21FFD26023FFFFFFFFFFFFFFFFFFDB7030FFDD7533FFDE79
      36FFDF7B37FFE07B37FFDF7E44FFCC6B35FF0000000000000000AAAAAAD6E2E2
      E2FFDFDEDEFFBAB5ACFFBBB6ADFFD7D5D2FFE2E2E3FFDFDFDFFFD9D9D9FFDADA
      DAFFE1E1E1FFBEBEBEE400000000000000006E3219CFD98D6AFFD06433FFD165
      33FFD26733FFD36833FFFFFFFFFFFFFFFFFFFFFFFFFFD7692AFFD96D2DFFDA70
      2FFFDB7130FFDB7131FFDA7138FF80411DCF84786E0000000000FFEDD000FFEE
      D300FFEED300FFEED300FFEED300FFEED100F7F5F300FAF8F400FDFDFB000000
      0000CD6C0C000024F600FFCCFF00153ACF00883F1ECFD98D6AFFD06433FFD165
      33FFD26733FFD36833FFFFFFFFFFFFFFFFFFFFFFFFFFD7692AFFD96D2DFFDA70
      2FFFDB7130FFDB7131FFDA7138FF9E5025CF0000000000000000ADADADD6E8E6
      E5FFECE8E6FFEFECE9FFEFECE9FFEDE9E7FFECE8E5FFECE8E6FFEAE6E3FFEBE7
      E4FFE8E6E5FFC2C2C2E4000000000000000033180B8FD58E6EFFD16A3CFFD065
      33FFD16633FFD26733FFD36A34FFD56C35FFD66E36FFD76F35FFD87035FFD971
      36FFDA7236FFDA7337FFD36E35FF3C1E0D8F897D720000000000FFE7C300FFE9
      C700FFE9C700FFE9C700FFE9C700FFE8C400F9F8F800DFD6CE00E0D7CF00F2EF
      EB00000000000B32CD000013C500000000005D2B148FD58E6EFFD16A3CFFD065
      33FFD16633FFD26733FFD36A34FFD56C35FFD66E36FFD76F35FFD87035FFD971
      36FFDA7236FFDA7337FFD36E35FF6C35198F0000000000000000B2B1AFD6C7D8
      E5FF9DC4E0FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FFA2C6E1FF9DC4
      E0FFC7D8E5FFC8C6C5E4000000000000000002010020B86643FFDB8F6CFFD064
      33FFD06533FFD16633FFD26733FFFCF6F2FFFCF6F3FFD56D36FFD66E36FFD76F
      37FFD87037FFD87037FFC4632FFF030100208D81750000000000FFE0B000FFE2
      B400FFE4B700FFECBF00FFF0C300FFEFC000000000000000000000000000FEFB
      FA00FEFDFC000000000000000000D0CBC600150A0520B86643FFDB8F6CFFD064
      33FFD06533FFD16633FFD26733FFFCF6F2FFFCF6F3FFD56D36FFD66E36FFD76F
      37FFD87037FFD87037FFC4632FFF180C06200000000000000000B3B3B1D667AE
      E2FF0078DAFF007CDAFF007CDAFF007CDAFF007CDAFF007CDAFF007CDAFF007D
      E3FF6DB8EEFFD4D4D4E900000000000000000000000033180B8FCB8260FFD988
      62FFD06433FFD06533FFD16533FFFCF6F2FFFCF6F2FFD36934FFD46A35FFD46B
      35FFD56C37FFCA6532FF3A1D0D8F000000009185780000000000FAF9F900FAFA
      FB0000000000483E360032281F0032271E0032261B0033271B00473C32000000
      0000FBF9F700FBF8F6000000000091857800000000005C2B148FCB8260FFD988
      62FFD06433FFD06533FFD16533FFFCF6F2FFFCF6F2FFD36934FFD46A35FFD46B
      35FFD56C37FFCA6532FF6733188F000000000000000000000000B3B3B2D6A7CF
      ECFF68B9EEFF6DBCEEFF6DBCEEFF6DBCEEFF6DBCEEFF6DBCEEFF6DC1F7FF7B80
      82FF736E69FF14141467000000000000000000000000000000106C3218CFCB82
      60FFDB8F6BFFD16A3CFFD06533FFD36F40FFD46F40FFD26733FFD26936FFD26C
      3FFFC76337FF773A1BCF0000001000000000978B7E0000000000000000000000
      0000000000006A615700FFFFFC00FEFAF400FEFAF400FFFFFC006A6157000000
      0000000000000000000000000000978B7E00000000000A050210853D1DCFCB82
      60FFDB8F6BFFD16A3CFFD06533FFD36F40FFD46F40FFD26733FFD26936FFD26C
      3FFFC76337FF934721CF0B060310000000000000000000000000B7B7B7D9F3EF
      EDFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFF9F1ECFFFFFEF9FF605F
      5DFF0E0E0E650000000000000000000000000000000000000000000000103318
      0B8FB86642FFD48E6DFFD98C69FFD5815AFFD27B53FFD17A53FFC86F48FFBA5E
      33FF371A0C8F000000100000000000000000A09487009B8F82009A8D80009A8D
      80009D91830079706600FFE4E100FAD9D600FAD9D600FFE4E100797066009D91
      83009A8D80009A8D80009B8F8200A094870000000000000000000A0502105C2B
      148FB86642FFD48E6DFFD98C69FFD5815AFFD27B53FFD17A53FFC86F48FFBA5E
      33FF6330168F0B05031000000000000000000000000000000000545454939C9C
      9CCF989898CC989898CC989898CC989898CC989898CC989898CCA7A7A7D10B0B
      0B62000000000000000000000000000000000000000000000000000000000000
      00000201002033180B8F6E3219CFB55F39FFB45E37FF713519CF35190C8F0201
      0020000000000000000000000000000000000000000000000000000000000000
      000000000000968B7E0000000000000000000000000000000000968B7E000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000150A05205D2B148F883F1ECFB55F39FFB45E37FF8B411FCF602D158F160A
      0520000000000000000000000000000000000000000000000000000000000000
      0000000000000000000011117ABF1717A3FF1717A3FF11117ABF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000080869BF0A0A8CFF0A0A8CFF080869BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000090909462426278D494C4EC76A6E72F06A6E72F0494C4EC72426278D0909
      09460000000000000000000000000000000000000000929292FF929292FF9292
      92FF929292FF929292FF1717A3FF8484F6FF5F5FEDFF1717A3FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0A0A8CFF6969F3FF4444E7FF0A0A8CFF000000000000
      00000000000000000000000000000000000000000000482323B3482323B34823
      23B3482323B3482323B3482323B3482323B3482323B3482323B3482323B34823
      23B3482323B3482323B3482323B3000000000000000000000000010202202425
      268C7D8084EDBCBEC1FEE2E1E3FFF7F7F8FFF7F7F8FFE2E2E4FFBDC0C2FE7E81
      85ED2425268C01020220000000000000000000000000929292FF000000000000
      0000000000000000000011117ABF1717A3FF1717A3FF11117ABF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000080869BF0A0A8CFF0A0A8CFF080869BF000000000000
      00000000000000000000000000000000000000000000482323B30DB1DAFF0DB1
      DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1DAFF0DB1
      DAFF0DB1DAFF0DB1DAFF482323B3000000000000000001020220313234A3B2B5
      BAFBF9F9F9FFFDF3EFFFF6C7AEFFF08C41FFF59A41FFFDDAADFFFFF9EFFFF9F9
      F9FFB4B9BBFB313234A3010202200000000000000000929292FF000000000000
      00000000000000000000206B1EBF2A8F29FF2A8F29FF206B1EBF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000115711BF177516FF177516FF115711BF000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFFFD00
      1DFFFD001DFFFD001DFFFD001DFFFD001DFFFD001DFFFD001DFFFD001DFFFD00
      1DFFFD001DFFFD001DFF482323B300000000000000002425268CB2B5BAFBFDFA
      F9FFEB9884FFDB3A02FFE24E01FFFFFFFFFFFFFFFFFFF98900FFFE9A03FFFED2
      8DFFFEFDFAFFB4B8BBFB2425268C0000000000000000929292FF929292FF9292
      92FF929292FF929292FF2A8F29FF87E087FF60CC60FF2A8F29FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF177516FF6CD76CFF45BD45FF177516FF000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFF21BD
      E1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BDE1FF21BD
      E1FF21BDE1FF21BDE1FF482323B300000000090909467C8084EDF9F9F9FFED9E
      84FFD52A02FFD93602FFE14901FFFFFFFFFFFFFFFFFFF68100FFFC9100FFFE9B
      04FFFED088FFF9F9F9FF7E8085ED0909094600000000929292FF000000000000
      00000000000000000000206B1EBF2A8F29FF2A8F29FF206B1EBF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      00000000000000000000115711BF177516FF177516FF115711BF000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFF2CC2
      E4FF2CC2E4FF2CC2E4FF2CC2E4FF2CC2E4FF2CC2E4FF2CC2E4FF2C0096FF2C00
      96FF2C0096FF2C0096FF482323B3000000002426278DBCBFC2FEFDF4EFFFDB3B
      01FFD62D02FFD73002FFDE4201FFE55401FFEB6400FFF17400FFF68200FFFA8C
      00FFFC9000FFFFF8EFFFBCBFC2FE2426278D00000000929292FF000000000000
      00000000000000000000177BADBF1EA4E7FF1EA4E7FF177BADBF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000B6AA7BF0E8EE0FF0E8EE0FF0B6AA7BF000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFF36C8
      E7FF36C8E7FF36C8E7FF2C0096FF2C0096FF2C0096FF2C0096FF36C8E7FF2C00
      96FF36C8E7FF36C8E7FF482323B300000000494C4EC7E2E2E4FFF7CEB8FFDD40
      01FFD83302FFD52A02FFDA3802FFFFFFFFFFFFFFFFFFF08C40FFF07000FFF378
      00FFF47B00FFFBD5ADFFE2E2E4FF494C4EC700000000929292FF929292FF9292
      92FF929292FF929292FF1EA4E7FF56FFFFFF23FFFFFF1EA4E7FF000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0E8EE0FF3CFFFFFF12FFFFFF0E8EE0FF000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFF40CE
      EBFF40CEEBFF2C0096FF40CEEBFF2C0096FF40CEEBFF40CEEBFF40CEEBFF2C00
      96FF40CEEBFF40CEEBFF482323B3000000006A6E72F0F7F7F8FFF2A776FFE568
      2EFFDB3D06FFD62D02FFD62D02FFFFFFFFFFFFFFFFFFEC8040FFE95E01FFEB65
      00FFEC6700FFF18E41FFF7F7F8FF6A6E72F000000000929292FF000000000000
      00000000000000000000177BADBF1EA4E7FF1EA4E7FF177BADBF000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000B6AA7BF0E8EE0FF0E8EE0FF0B6AA7BF000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFF2C00
      96FF2C0096FF4AD4EEFF4AD4EEFF2C0096FF4AD4EEFF4AD4EEFF4AD4EEFF4AD4
      EEFF4AD4EEFF4AD4EEFF482323B3000000006A6E72F0F7F7F8FFF4AA73FFEB82
      45FFE67443FFDD4B1CFFD62F07FFD62E02FFFFFFFFFFFFFFFFFFE97940FFE451
      01FFE55401FFEB8041FFF7F7F8FF6A6E72F0732F00BF9A3F00FF9A3F00FF732F
      00BF0000000000000000000000000000000000000000060629401717A3FF0606
      294000000000060629401717A3FF06062940611D00BF822700FF822700FF611D
      00BF000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000482323B3FD001DFF54DA
      F2FF2C0096FF54DAF2FF54DAF2FF2C0096FF54DAF2FF54DAF2FF54DAF2FF54DA
      F2FF54DAF2FF54DAF2FF482323B300000000494C4EC7E2E2E4FFFBDCC2FFEE88
      41FFEA7C43FFE67446FFE36A44FFDE5634FFDB4A27FFFFFFFFFFFFFFFFFFE77A
      4FFFE25C26FFF6CFBFFFE2E2E4FF494C4EC79A3F00FFEAC83AFFDCA216FF9A3F
      00FF00000000000000000000000000000000000000001717A3FF3232DAFF1717
      A3FF060629401717A3FF0202B1FF1717A3FF822700FFE3B823FFD18B09FF8227
      00FF000000000000000000000000000000000000000000000000A09281FFA092
      81FFA09281FFA09281FFA09281FFA09281FF00000000482323B3FD001DFF5EE0
      F5FF2C0096FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0F5FF5EE0
      F5FF5EE0F5FF5EE0F5FF482323B3000000002426278DBDC0C2FEFEF9F3FFF28F
      3DFFED853FFFFFFFFFFFFFFFFFFFE46F46FFE36B49FFFFFFFFFFFFFFFFFFE992
      7CFFE36F52FFFDF6F4FFBEC0C3FE2426278D732F00BF9A3F00FF9A3F00FF732F
      00BF0000000000000000000000000000000000000000060629401717A3FF2B2B
      E6FF1717A3FF1616C3FF1717A3FF06062940611D00BF822700FF822700FF611D
      00BF000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFFBA7758FF9D3F12FFF2DECAFFA09281FF00000000482323B3FD001DFF69E5
      F8FF2C0096FF69E5F8FF69E5F8FF69E5F8FF69E5F8FF69E5F8FF69E5F8FF69E5
      F8FF69E5F8FF69E5F8FF482323B300000000090909467F8186EDF9F9F9FFFACC
      9FFFF18E3BFFFBE6D7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFDF7F4FFE36E
      4BFFF1B9A9FFF9F9F9FF7F8186ED090909460000000000000000000000000000
      0000000000000000000000000000000000000000000000000000060629401717
      A3FF2828E4FF1717A3FF06062940000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFF96360EFFCB7A3DFFAA562BFFA09281FF00000000482323B373EBFCFF73EB
      FCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EBFCFF73EB
      FCFF73EBFCFF73EBFCFF482323B300000000000000002425268CB5B9BCFBFEFC
      FAFFFACC9EFFF28F39FFF5B688FFFDF1EAFFFEF7F4FFED966BFFE77644FFF3BC
      A6FFFEFBFBFFB6B9BCFB2425268C000000000000000000000000000000000000
      00000000000000000000000000000000000000000000060629401717A3FF9D9D
      F7FF1717A3FF5454DEFF1717A3FF060629400000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFF96360EFF96360EFFAB4C17FFA78168FF00000000482323B37DF1FFFF7DF1
      FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1FFFF7DF1
      FFFF7DF1FFFF7DF1FFFF482323B3000000000000000001020220313234A3B5B9
      BCFBF9F9F9FFFEF8F2FFFBDCBFFFF5AA6BFFF3A66DFFF9D7C1FFFEF7F3FFF9F9
      F9FFB6B9BCFB313234A301020220000000000000000000000000000000000000
      000000000000000000000000000000000000000000001717A3FFCCCCFCFF1717
      A3FF060629401717A3FF6262D4FF1717A3FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFF2DE
      CAFFF2DECAFFE5C7B2FF96360EFF883B19FF00000000482323B3482323B34823
      23B3482323B3482323B3482323B3482323B3482323B3482323B3482323B34823
      23B3482323B3482323B3482323B3000000000000000000000000010202202425
      268C7F8286EDBDC0C2FEE2E2E4FFF7F7F8FFF7F7F8FFE2E2E4FFBEC0C3FE7F81
      86ED2425268C0102022000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000060629401717A3FF0606
      294000000000060629401717A3FF060629400000000000000000000000000000
      0000000000000000000000000000000000000000000000000000A09281FFA092
      81FFA09281FFA09281FFA09281FFA09281FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000090909462426278D494C4EC76A6E72F06A6E72F0494C4EC72426278D0909
      0946000000000000000000000000000000000000000000000000000000000000
      0000000000002F1D019F754D07FF634006FF2012008000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000686868FF686868FF676767FF676767FF666666FF656565FF656565FF6464
      64FF636363FF636363FF636363FF000000000000000000000000000000000000
      0000000000000000002D0000001E0000001C0000003A0000003A0000003A0000
      003A0000003A0000003A0000000E000000000000000000000000000000000000
      00000000000000000000080869BF0A0A8CFF0A0A8CFF080869BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000C0600306B4506FF2214008F2B1700AF573402FF140A0050000000000000
      00000000000000000000000000000000000000000000246595FF246595FF2465
      95FF787878FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFEEEEEEFFF6F6F6FF727272FF000000000000000000000000000000000000
      0000000000050A1F087A1E5415FF93846FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFF93846FFF000000130000000000000000787878FF787878FF7878
      78FF787878FF787878FF0A0A8CFF6969F3FF4444E7FF0A0A8CFF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000C060030613C05FF140A005000000000361E00BF3D2402BF000000000000
      00000000000000000000000000000000000000000000246595FF4C9DC1FF4E9F
      C4FF868686FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF818181FF000000000000000000000000000000000000
      0002194411D80A891EFF1E5415FF93846FFFFBF4EDFFF8EFE5FFF7EADDFFF4E5
      D4FFF3E1CCFF93846FFF000000130000000000000000787878FF000000000000
      00000000000000000000080869BF0A0A8CFF0A0A8CFF080869BF000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000003D2300DF543305EF140A0050341D00BF452702BF000000000000
      00000000000000000000000000000000000000000000246595FF4EA0C5FF50A3
      C6FF919191FFF2F2F2FF98A9CBFFE6E6E6FFE6E6E6FFE6E6E6FFE6E6E6FFE5E5
      E5FFE2E2E2FFF0F0F0FF8C8C8CFF00000000000000000000000000000000030A
      022196B891FF3ED944FF1E5415FF93846FFFFCF8F4FFFBF4EDFFF8EFE5FFF7EA
      DDFFF4E5D4FF93846FFF000000130000000000000000787878FF000000000000
      00000000000000000000115711BF177516FF177516FF115711BF000000000000
      0000000000000000000000000000000000000C0600302214008F2214008F1009
      00400000000010090040754507FFA46514FF7D4808FF20120080000000000000
      00000000000000000000000000000000000000000000296B99FF51A4C7FF52A7
      C9FF999999FFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFF979797FF000000000000000E00000013000000130000
      001300000013347636FF1E5415FF93846FFFFFFEFCFFFCF8F4FFFBF4EDFFF8EF
      E5FFF7EADDFF93846FFF000000130000000000000000787878FF787878FF7878
      78FF787878FF787878FF177516FF6CD76CFF45BD45FF177516FF000000000000
      000000000000000000000000000000000000543603EF5E3A02EF552F02DF5932
      02FF311C00AF040200102214008FA4590EFF391F00CF00000000000000000000
      000000000000000000000000000000000000000000002F729FFF53A9CAFF54AB
      CCFFA0A0A0FFF6F6F6FF98A9CBFFEEEEEEFFEEEEEEFFEEEEEEFFEDEDEDFFEBEB
      EBFFEAEAEAFFF3F3F3FF9E9E9EFF0000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF706455FF1C4E13F393846FFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF000000050000000000000000787878FF000000000000
      00000000000000000000115711BF177516FF177516FF115711BF000000000000
      000000000000000000000000000000000000623D02FF20120080000000002715
      009F91540AFF4C2B02DF100900404E2A02EF512C02DF00000000000000000000
      000000000000000000000000000000000000000000003477A4FF55ACCCFF56AF
      CFFFA6A6A6FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFA4A4A4FF00000000FFFFFFFFF8EFE5FFF7EADDFFF4E5
      D4FFF3E1CCFFFFFFFFFF0000003A000000000000000000000000000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000B6AA7BF0E8EE0FF0E8EE0FF0B6AA7BF000000000000
      000000000000000000000000000000000000432901CF4A2C01EF10090040140A
      00508F520AFFA55A0EFF683805FF2F1A00BF462903FF1F1C1560000000000000
      000000000000000000000000000000000000000000003C83ADFF57B0D0FF59B2
      D3FFA9A9A9FFF8F8F8FF98A9CBFFF3F3F3FFF4F4F4FFF3F3F3FFF3F3F3FFF2F2
      F2FFEFEFEFFFF6F6F6FFA7A7A7FF00000000FFFFFFFFFBF4EDFFF8EFE5FFF7EA
      DDFFF4E5D4FFFFFFFFFF0000003A000000000000000000000000000000000000
      00000000000000000000000000000000000000000000787878FF787878FF7878
      78FF787878FF787878FF0E8EE0FF3CFFFFFF12FFFFFF0E8EE0FF000000000000
      0000000000000000000000000000000000000C0600303E2400DF543001FF5A32
      02FF573203EF5F3406BE341D00BF462903FF625B51FF626262EF121212300000
      00000000000000000000000000000000000000000000428AB2FF59B4D4FF5BB6
      D7FFACACACFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFD9B08CFFABABABFF00000000FFFFFFFFFCF8F4FFFBF4EDFFF8EF
      E5FFF7EADDFFFFFFFFFF0000003A000000000000000000000000000000000000
      00000000000000000000000000000000000000000000787878FF000000000000
      000000000000000000000B6AA7BF0E8EE0FF0E8EE0FF0B6AA7BF000000000000
      0000000000000000000000000000000000000000000000000000100900401009
      0040080400200000000000000000161411405F5F5FEFA0A0A0FF5C5C5CEF1212
      123000000000000000000000000000000000000000004791B8FF5BB7D7FF5DBA
      D9FFADADADFFFBFBFBFF98A9CBFFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6
      F6FFF3F3F3FFF8F8F8FFADADADFF00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF0000002D000000000000000000000000000000000000
      000000000000000000000000000000000000611D00BF822700FF822700FF611D
      00BF000000000000000000000000000000000000000000000000000000000223
      0594043D08FF0223059400000000000000000000000000000000000000000000
      000000000000000000000000000000000000121212306C6C6CEF7A7A7AFF6060
      60EF12121230000000000000000000000000000000004F9AC0FF5EBBD9FF5FBD
      DCFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFB6B6
      B6FFB4B4B4FFBFBFBFFFADADADFF000000000000002B0000003A0000003A0000
      003A0000003A0000003A0000003A000000000000000000000000000000000000
      000000000000000000000000000000000000822700FFE3B823FFD18B09FF8227
      00FF00000000000000000000000000000000000000000000000000000000043D
      08FF10A916FF043D08FF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000001E1E1E507C7C7CFF7575
      75FF6D6D6DEF1E1E1E50000000000000000000000000509DC1FF61BFDDFF62C1
      DEFFAFAFAFFFFCFCFCFF98A9CBFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFBCBC
      BCFFE9E9E9FFBABABAFF6D6D6D9F00000000FFFFFFFFFFFFFFFFFFFFFFFFFFFF
      FFFFFFFFFFFFFFFFFFFF0000003A000000000000000000000000000000000000
      000000000000000000000000000000000000611D00BF822700FF822700FF611D
      00BF000000000000000000000000000000000000000002230594043D08FF043D
      08FF42BF43FF043D08FF043D08FF022305940000000000000000000000000000
      0000000000000000000000000000000000000000000000000000323232807676
      76FF606060EF626262FF242424600000000000000000519EC2FF63C2E0FF898C
      8EFF787C7DFF717475FF696C6DFF696C6DFF626566FF626566FF626566FFE2E2
      E2FFBBBBBBFF6D6D6D9F0000000000000000FFFFFFFFFAF0E7FFF7EDE0FFF6E7
      D8FFF3E2D0FFFFFFFFFF0000003A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000043D08FF96E998FF8FE3
      90FF65D764FF45C747FF099D0EFF043D08FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000003D3D
      3D9F565656DF1E1E1E505C5C5CEF2424246000000000529FC2FF65C6E2FF66A7
      BAFF696B6BFF717374FF878C8EFF8F9899FF757878FF696A6BFF959595FFAFAF
      AFFF799EAFFF000000000000000000000000FFFFFFFFFBF6EFFFFAF0E7FFF7ED
      E0FFF6E7D8FFFFFFFFFF0000003A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000002230594043D08FF043D
      08FF88E089FF043D08FF043D08FF022305940000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000606
      0610505050CF2424246006060610242424600000000053A0C4FF67CAE6FF69CC
      E7FF6E6F6FFFADB2B4FFA3A9AAFFB8C2C4FFB0B5B6FF676868FF74E1F7FF76E3
      F8FF368BB5FF000000000000000000000000FFFFFFFFFEFBF7FFFBF6EFFFFAF0
      E7FFF7EDE0FFFFFFFFFF0000003A000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000000000000000000000000000043D
      08FF8AE18CFF043D08FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006060610434343AF00000000000000000000000054A3C5FF54A3C5FF55A4
      C6FF517587FF577D8EFF697880FF6B7C83FF507586FF527888FF57A9CBFF4AA0
      C5FF4096BCFF00000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF0000000E000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000223
      0594043D08FF0223059400000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000696969FF696969FF686868FF676767FF666666FF666666FF656565FF6464
      64FF646464FF636363FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000797979FFF7F7F7FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEEEE
      EEFFF6F6F6FF747474FF00000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000000013
      2140003761BF004B89FF000000000000000000000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF0000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000000000
      0000888888FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFF838383FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000000000000029498F045B
      9DFF1B7CDAFB0861B1FF004B89FF004B89FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000696969FF696969FF6262
      62FF939393FFF3F3F3FF98A9CBFFE7E7E7FFE7E7E7FFE7E7E7FFE6E6E6FFE3E3
      E3FFF0F0F0FF909090FF00000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000025490FF56B1
      EBFA66B8F1F52B8CEDF51A6DE9F5004B89FF00000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF0000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000000000000797979FFF7F7F7FF8E96
      AAFF9D9D9DFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFF999999FF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000002039701263
      97FF7ABBE5FA126DB2FF004B89FF004B89FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000888888FF7C7C7DFF8E96
      AAFFA3A3A3FFF6F6F6FF98A9CBFFEFEFEFFFEFEFEFFFEFEFEFFFEEEEEEFFEBEB
      EBFFF4F4F4FFA0A0A0FF00000000000000000000000000000000001321400037
      61BF004B89FF000000000000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF000000000000000000000000000000000013
      2140014679DF004B89FF000000000000000000000000AF9E7DFFAB9977FFA695
      72FFA38F6BFF9F8A66FF9A865FFF97815AFF0000000000000000000000000046
      7AEF00467AEF001321400000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000000000000939393FFF3F3F3FF8E96
      AAFFA7A7A7FF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFA6A6A6FF0000000000000000000000000029498F045B9DFF1B7C
      DAFB0861B1FF004B89FF004B89FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000467AEF004A82FF004A
      82FF0B5CABF7004A82FF00264180000000000000000000000000000000000000
      000000000000000000000000000000000000000000009D9D9DFFD9B08CFF8E96
      AAFFABABABFFFAFAFAFF98A9CBFFF6F6F6FFF6F6F6FFF4F4F4FFF3F3F3FFF2F2
      F2FFF7F7F7FFAAAAAAFF000000000000000000000000025490FF56B1EBFA66B8
      F1F52B8CEDF51A6DE9F5004B89FF00000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000000000000004A82FF5AA7E5ED65AE
      EAED398FE9ED0B5BB8F5004A82FF00000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000000000000A3A3A3FFF6F6F6FF8E96
      AAFFADADADFFD9B08CFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFD9B08CFFD9B0
      8CFFD9B08CFFACACACFF00000000000000000000000000203970126397FF7ABB
      E5FA126DB2FF004B89FF004B89FF000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000467AEF004A82FF004A
      82FF1C70B3F6004A82FF0029498F000000000000000000000000000000000000
      00000000000000000000000000000000000000000000A7A7A7FF7C7C7DFF8E96
      AAFFADADADFFFBFBFBFF98A9CBFFFAFAFAFFFAFAFAFFF8F8F8FFA5A5A5FFA5A5
      A5FFBFBFBFFFADADADFF00000000000000000000000000000000001321400146
      79DF004B89FF000000000000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000000000000046
      7AEF00467AEF001829500000000000000000AF9E7DFFAB9977FFA69572FFA38F
      6BFF9F8A66FF9A865FFF97815AFF0000000000000000ABABABFFFAFAFAFF8E96
      AAFFAFAFAFFF7C7C7DFF98A9CBFFD9B08CFFD9B08CFFD9B08CFFA5A5A5FFF2F2
      F2FFC9C9C9FF8E8E8ECF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000ADADADFFD9B08CFF8E96
      AAFFAFAFAFFFFEFEFEFF98A9CBFFFEFEFEFFFEFEFEFFFCFCFCFFBBBBBBFFBDBD
      BDFF8E8E8ECF0B0B0B1000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000000000000ADADADFFFBFBFBFF8E96
      AAFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFF8E8E
      8ECF0B0B0B100000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000AFAFAFFF7C7C7DFF8E96
      AAFFB5AAA0FFB5AAA0FFB5AAA0FFB5AAA0FFA5A5A5FFB8B8B8FF8E8E8ECF0000
      0000000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF000000000000000000000000000000000000000000000000AF9E7EFFAC9A
      7AFFAA9776FFA69372FFA4906DFFA08E69FF9E8A65FF9C8762FF98835DFF9680
      59FF0000000000000000000000000000000000000000AFAFAFFFFEFEFEFF98A9
      CBFFFEFEFEFFFEFEFEFFFCFCFCFFFBFBFBFFBDBDBDFF8E8E8ECF0B0B0B100000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000AFAFAFFFAFAFAFFFAFAF
      AFFFAFAFAFFFAFAFAFFFAFAFAFFFAFAFAFFF8E8E8ECF0B0B0B10000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000060F03301C4F14EF00000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000024242430BDBDBDFFCCCCCCFFCCCC
      CCFFCCCCCCFFCBCBCBFFCBCBCBFFCACACAFFC9C9C9FFC7C7C7FFC5C5C5FFC5C5
      C5FFC5C5C5FFC5C5C5FFC0C0C0FF242424300000000000000000000000000000
      000000000000000000000C1F07601C4F14EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000000000000000000000000000000000000464646EF747474FFE2E2E2FFFBFB
      FBFFFAFAFAFFF8F8F8FFF4F4F4FFF0F0F0FFEBEBEBFFE5E5E5FFDDDDDDFFDCDC
      DCFFDCDCDCFFD4D4D4FF838383FF464646EF0000000000000000000000000000
      00000000000010300B8F206719FF149616FF1E5415FF0000000093846FFFFAF2
      E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      000000000000000000000000000000000000423F3EFF030202FF989797FFF3F3
      F3FFFAFAFAFFF8F8F8FFF4F4F4FFEFEFEFFFEAEAEAFFE5E5E5FFDDDDDDFFDCDC
      DCFFDCDCDCFFB5B5B5FF0A0909FF423F3EFF0000000000000000000000000000
      00000C1F07601E5415FF51CF5AFF33CE39FF1E5415FF0000000093846FFFFBF7
      F0FFFAF2E9FFF7EDE0FFF4E7D7FF93846FFF93846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000006C6562FF766963FF262323FF6767
      67FF777777FF767676FF757575FF747474FF727272FF6F6F6FFF6D6D6DFF6C6C
      6CFF686868FF474443FF766963FF6C6562FF93846FFF93846FFF93846FFF9384
      6FFF93846FFF5F6E47FF2A6522FF37BC3CFF1E5415FF0000000093846FFFFEFC
      FAFFFBF7F0FFFAF0E7FFF7EDE0FF93846FFF93846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF6E7D7FF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000006E6764FF8E7E77FF1C1817FF0604
      04FF060404FF060404FF060404FF060404FF060404FF060404FF060404FF0604
      04FF060404FF1C1817FF8E7E77FF6E6764FF93846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF0A1A06501C4F14EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000060F03301C4F14EF00000000000000000000
      00000000000000000000000000000000000093846FFFFEFBFAFFFBF7F0FFFAF2
      E9FFF7EDE0FF93846FFF00000000000000000000000000000000000000000E24
      0A7002050110000000000000000000000000716A67FF93867EFF322A29FF291F
      21FF291F21FF291F21FF291F21FF291F21FF291F21FF291F21FF291F21FF291F
      21FF291F21FF322A29FF93867EFF716A67FF93846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000060F0330194411CF00000000000000000000
      00000000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF0C1F07601C4F14EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF000000001E54
      15FF194411CF040B03200000000000000000766F6CFF9E918BFF24201FFF1C18
      19FF1C1819FF1C1819FF1C1819FF1C1819FF1C1819FF1C1819FF1C1819FF1C18
      19FF1C1819FF1B1717FF9E918BFF766F6CFF93846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000010300B8F206719FF149616FF1E5415FF0000000093846FFFFAF2
      E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF0000000000000000000000000000
      000093846FFFFAF2E9FFF7EDE0FFF6E7D7FFF3E2CFFF93846FFF000000001E54
      15FF1A6E16F71C4F14EF0A1A0650000000007D7775FFACA09CFF030202FF3934
      34FF393434FF393434FF393434FF393434FF393434FF393434FF393434FF3934
      34FF393434FF030202FFACA09CFF7D7775FF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000C1F07601E5415FF51CF5AFF33CE39FF1E5415FF0000000093846FFFFBF7
      F0FFFAF2E9FFF7EDE0FFF4E7D7FF93846FFF0000000000000000000000000000
      000093846FFFFBF7F0FFFAF2E9FFF7EDE0FFF6E7D7FF93846FFF000000001E54
      15FF21AB23ED1C6C17F81E5415FF00000000636261FF655F5EFF080707FF5856
      56FF585656FF585656FF585656FF585656FF585656FF585656FF585656FF5856
      56FF585656FF080707FF736D6BFF636261FF0000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000E240A702A6522FF37BC3CFF1E5415FF0000000093846FFFFEFC
      FAFFFBF7F0FFFAF0E7FFF7EDE0FF93846FFF0000000000000000000000000000
      000093846FFFFEFBFAFFFBF7F0FFFAF2E9FFF7EDE0FF93846FFF000000001E54
      15FF298725F61C4F14EF0C1F0760000000000F0F0F3004040440000000400303
      04CF000000FF020202FF040303FF060404FF070505FF040303FF020202FF0000
      00FF010104CF00000040040404400F0F0F3093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF0A1A06501C4F14EF1E5415FF0000000093846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF93846FFF93846FFF93846FFF93846FFF000000001E54
      15FF194411CF060F033000000000000000000000000000000000000000000C0C
      14BF25202DFF18151DFF100D12FF0F0D12FF0F0C11FF0E0C10FF151217FF201A
      22FF0C0B11BF00000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF00000000060F0330194411CF00000000000000000000
      00000000000000000000000000000000000093846FFFFAF2E9FFF7EDE0FFF6E7
      D7FFF3E2CFFF93846FFF0000000000000000000000000000000000000000102B
      0B80020501100000000000000000000000000000000000000000000000000806
      0EBF26212EFF27222FFF27222EFF26202CFF251F2BFF241E29FF231E27FF211B
      24FF06060EBF00000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF4E7D7FF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFBF7F0FFFAF2E9FFF7ED
      E0FFF6E7D7FF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000303
      0550171420FF27222FFF27222EFF26202CFF251F2BFF241E29FF231E27FF1411
      1BFF0303055000000000000000000000000093846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFCFAFFFBF7F0FFFAF0
      E7FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFFFEFBFAFFFBF7F0FFFAF2
      E9FFF7EDE0FF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      000006060B9F181521FF27222EFF26202CFF251F2BFF241E29FF16131DFF0606
      0B9F0000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000093846FFF93846FFF93846FFF9384
      6FFF93846FFF93846FFF00000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000003030765080811C813111CFF13111BFF08080FC8030307650000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000818181FF818181FF8181
      81FF808080FF808080FF808080FF808080FF808080FF7E7E7EFF7E7E7EFF7E7E
      7EFF7E7E7EFF7E7E7EFF00000000000000000000000000000000000000000000
      00000000000000000000000000000000000000000000181818185A825DA2129F
      1FFF139F1FFF5A825DA218181818000000000000000027100360813708FF8137
      08FF5E4427FF6A6A6AFF6B6B6BFF646464FF797979FF6B6B6BFF626262FF5151
      51FF5E4427FF7C2600FF632602FF421702AF0000000000000000000000000000
      0000002000400050009F007200DF199F19FF1B9F1BFF007200DF0050009F0020
      004000000000000000000000000000000000000000008E8E8EFFFDFDFDFFACBA
      D7FFF9F9F9FFF9F9F9FFF9F9F9FFF9F9F9FFF9F9F9FFF8F8F8FFF8F8F8FFF8F8
      F8FFFDFDFDFF8C8C8CFF00000000000000000000000000000000000000000000
      000000000000000000000000000006080809191919194C4C4C4C65A369D683EE
      A8FF84F0ACFF65A56BD64C4C4C4C1818181800000000833808FFB54F0CFFB64F
      0DFF5E4427FF676767FF7C2600FF7C2600FFA3A3A3FFA9A9A9FF8F8F8FFF6B6B
      6BFF5E4427FF7C2600FF7B2D02FF762A03FF0000000000000000000800100059
      00AF039F03FF29D829FF6FFA6FFF9EFF9EFFA5FFA5FF7EFC7EFF34DA34FF059F
      05FF005900AF00080010000000000000000000000000989898FF949495FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FF969696FF00000000000000000000000000000000000000000000
      00000000000000000000000000002626262657845AA7189823F60C9717FC64E0
      90FF64E493FF0C9718FC189823F65A825DA2000000008F3F09FFBA540EFFBB54
      0EFF5E4427FF626262FF7C2600FF7C2600FFB5B5B5FFC0C0C0FFA0A0A0FF7777
      77FF5E4427FF7C2600FF7B2E03FF762A03FF0000000000080010006A00CF00B8
      00FF02DE02FF3FE13FFF78E578FF92E792FF95E995FF80E780FF48E348FF08DE
      08FF00B600FF006A00CF000800100000000000000000A1A1A1FFFAFAFAFFACBA
      D7FFEBEBEBFFEBEBEBFFEBEBEBFFEBEBEBFFEAEAEAFFE9E9E9FFE8E8E8FFE7E7
      E7FFF9F9F9FFA0A0A0FF00000000000000000C7C93FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF228AA1FF119E1CFF81DF9CFF62D486FF1FC0
      58FF22C960FF65E494FF84F2ADFF139F20FF0000000092420BFFBF5910FFC05A
      10FF5E4427FF5C5C5CFF7C2600FF7C2600FFC5C5C5FFDADADAFFB7B7B7FF8585
      85FF5E4427FF7C2600FF7D3003FF772B03FF00000000005900AF00B700FF01D8
      01FF3DC73DFF61CA61FF6FD36FFF78D978FF7ADA7AFF73D573FF65CC65FF40C9
      40FF01D401FF00B200FF005900AF0000000000000000A9A9A9FFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFA7A7A7FF000000000000000007788FFFA3E6FFFF50D0FFFF40CA
      FFFF41CAFFFF40CAFFFF44CBFFFF8EE2FFFF139E1BFF84DD99FF62D283FF1FB7
      51FF1FC259FF64E190FF84EEA9FF129F1FFF0000000096460CFFC46013FFC562
      14FF5E4427FF575757FF575757FF575757FFC9C9C9FFF3F3F3FFD0D0D0FF9595
      95FF5E4427FF7C2600FF7E3103FF792C04FF00200040009A00FF00D800FF0A8F
      0AFF109210FF48BB48FF59C659FF61CB61FF62CB62FF45BA45FF52C152FF46B7
      46FF2AB52AFF00D000FF009700FF0020004000000000AEAEAEFFFBFBFBFFACBA
      D7FFF0F0F0FFF0F0F0FFF0F0F0FFF0F0F0FFEFEFEFFFEFEFEFFFEEEEEEFFECEC
      ECFFFAFAFAFFADADADFF0000000000000000087A91FF49A6BCFF53D1FFFF14BC
      FBFF13BBFBFF13BBFBFF16BBFBFF43CBFFFF46BA95FF159D27FF099818FF62D1
      83FF62D587FF0C9618FB189823F65A825DA200000000994E14FFCA6C21FFCB6E
      24FF91541DFF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E4427FF5E44
      27FF683510FF752C02FF883806FF7B2D04FF0050009F00C500FF08BF08FF279F
      27FF9AD59AFF0C900CFF40B540FF49BB49FF139613FF35A635FF109310FF35AC
      35FF2AA32AFF08BA08FF00BC00FF0050009F00000000B4B4B4FFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFB3B3B3FF0000000000000000087A91FF229DBFFF89DCF8FF2CC7
      FEFF1BC1FDFF1DC1FDFF1EC1FDFF24C5FDFF37CBFFFF70DCFFFF58BC7CFF83DD
      99FF83E29DFF51A868F14949494918181818000000009D571EFFBA682AFFC394
      6DFFC0916BFFBE8E68FFBB8B65FFB98760FFB5825AFFB48058FFB37E57FFB17D
      57FFB07C56FFAF7B56FFA2440EFF7C2E04FF007000DF00D800FF0C990CFF0284
      02FFEAF7EAFFADDEADFF129212FF119311FF058905FFFFFFFFFF88CE88FF0589
      05FF1B961BFF0E990EFF00CA00FF007000DF00000000B7B7B7FF949495FFACBA
      D7FFF4F4F4FFF5F5F5FFF5F5F5FFF4F4F4FFF4F4F4FFF3F3F3FFF2F2F2FFF1F1
      F1FFFBFBFBFFB7B7B7FF0000000000000000087A91FF35C9FFFF4FA8B9FF5ED9
      FFFF24C7FDFF24C7FDFF24C8FDFF24C7FDFF20C6FDFF3DD0FFFF4ABE95FF139E
      1BFF129E1CFF4BAE7BFF3A42464D0000000000000000A0612BFFC38551FFEBEB
      EBFFE7E7E7FFE2E2E2FFDDDDDDFFD9D9D9FFD4D4D4FFD0D0D0FFCBCBCBFFCACA
      CAFFCACACAFFCACACAFFA85B29FF7D3004FF009600FF00DA00FF088008FF0786
      07FF65BD65FFE9E9E9FFEFEFEFFFADDEADFF65BD65FFEEEEEEFFD9D9D9FFC1E6
      C1FF088908FF068206FF00CA00FF009200FF00000000BABABAFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFB9B9B9FF0000000000000000087A91FF40D1FFFF0D94BCFF90E3
      FBFF38D1FDFF2ACDFCFF2CCEFCFF2CCEFCFF2BCDFCFF33CFFCFF56D9FFFF7EE2
      FFFF82E3FFFFA4EFFFFF146576C70000000000000000A46936FFC18758FFDCDC
      DCFFD8D8D8FFD4D4D4FFD1D1D1FFCECECEFFCACACAFFC7C7C7FFC3C3C3FFBFBF
      BFFFBCBCBCFFBABABAFFA55926FF7D3105FF069906FF88F489FF3EB43EFF20A1
      20FF0B8F0BFFC1E6C1FFE9E9E9FFE5E5E5FFEFEFEFFFEBEBEBFFE2E2E2FFEEEE
      EEFFEAF6EAFF139313FF7AEE7CFF059605FF00000000BCBCBCFFFDFDFDFFACBA
      D7FFF8F8F8FFF8F8F8FFF8F8F8FFF8F8F8FFF7F7F7FFF6F6F6FFF5F5F5FFF4F4
      F4FFFCFCFCFFBCBCBCFF0000000000000000087A91FF44D1FFFF19C3FBFF57AB
      BDFF68DFFFFF36D3FEFF35D2FEFF35D2FEFF35D2FEFF36D2FEFF37D2FEFF38D3
      FEFF37D2FEFF57DCFFFF71C4DCFF091F213400000000A87141FFCC9568FFFEFE
      FEFFFBFBFBFFF7F7F7FFF2F2F2FFEEEEEEFFE9E9E9FFE5E5E5FFE0E0E0FFDADA
      DAFFD7D7D7FFD1D1D1FFAA5D2BFF7E3105FF007000DFAAF8AAFF56C556FF39B1
      39FF29AB29FF058B05FF65BD65FFEAF7EAFFFFFFFFFFFEFEFEFFFEFEFEFFFFFF
      FFFFADDEADFF129512FF98F399FF007000DF00000000BDBDBDFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0
      A2FFE2C0A2FFBDBDBDFF0000000000000000087A91FF46D4FFFF25CDFFFF1299
      BAFFA6E6FAFF8AE4FEFF87E4FDFF88E4FDFF88E4FDFF88E4FDFF86E4FDFF85E5
      FFFF86E6FFFF8BE5FFFFBFF7FFFF125F70C200000000A9764AFFC79269FFE1E1
      E1FFE1E1E1FFE1E1E1FFE0E0E0FFDDDDDDFFD9D9D9FFD7D7D7FFD3D3D3FFCFCF
      CFFFCCCCCCFFC9C9C9FFA95C29FF7E3105FF0050009F95E396FF82E182FF4DB8
      4DFF41B541FF38B138FF1A9D1AFF098F09FF129312FFFFFFFFFFFFFFFFFF75C5
      75FF119211FF64D564FF82DE83FF0050009F00000000BEBEBEFFFDFDFDFFACBA
      D7FFFAFAFAFFFAFAFAFFFBFBFBFFFAFAFAFFFAFAFAFFF9F9F9FFF8F8F8FFF6F6
      F6FFFDFDFDFFBEBEBEFF0000000000000000087A91FF4BD6FFFF29CDFDFF2ACA
      F9FF09829BFF087A91FF087A91FF087A91FF087A91FF087A91FF087A91FF087A
      91FF087A91FF087A91FF087A91FF0B6E81E000000000AA784EFFCF9C73FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFCFCFCFFF8F8F8FFF4F4F4FFEFEF
      EFFFEBEBEBFFE6E6E6FFB0632EFF803205FF002000402DA42DFFC1FCC1FF72CB
      72FF5ABD5AFF51BA51FF4BB84BFF48B748FF0B8F0BFFFFFFFFFF44AD44FF249F
      24FF6CCA6CFF99F399FF28A329FF0020004000000000BFBFBFFFE2C0A2FFACBA
      D7FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFE2C0A2FFBFBFBFFFCBCB
      CBFFDBDBDBFFB2B2B2EF0000000000000000087A91FF4ED8FFFF2CCEFEFF2FCF
      FEFF30D2FFFF2FD1FFFF33D3FFFF4BD9FFFF52DDFFFF52DDFFFF6AE4FFFF67BF
      D3FF0005060900000000000000000000000000000000AA774BFFC7946AFFE1E1
      E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFE1E1E1FFDEDE
      DEFFDCDCDCFFD8D8D8FFAC602BFF7E3205FF00000000005900AF76CB77FFC2FA
      C2FF81CF81FF6CC46CFF67C167FF64C164FF219D21FF159515FF3AAA3AFF79CF
      79FF98F098FF66CA67FF005900AF0000000000000000BFBFBFFF949495FFACBA
      D7FFFBFBFBFFFCFCFCFFFCFCFCFFFCFCFCFFFBFBFBFFFAFAFAFFCBCBCBFFE2E2
      E2FFB3B3B3EF24242430000000000000000017859AFF75E4FFFF35D1FEFF31D0
      FEFF2FD0FEFF36D1FEFF70E2FFFF1C8AA0FF087A91FF087A91FF087A91FF107E
      94FF0105050800000000000000000000000000000000AA774BFFBA8258FFFEFE
      FEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFE
      FEFFFEFEFEFFFAFAFAFFA95E2EFF742B03FF0000000000080010056F05CF79CE
      79FFD3FCD3FFA9E9A9FF8ED58EFF82CB82FF83CB83FF88D488FF93E393FFADF6
      AFFF6ACA6AFF006800CF000800100000000000000000BFBFBFFFFFFFFFFFACBA
      D7FFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFEFEFEFFFAFAFAFFDBDBDBFFB3B3
      B3EF24242430000000000000000000000000032C33572D94A9FF7DE7FFFF53DC
      FFFF52DCFFFF79E7FFFF2B94A9FF022228440000000000000000000000000000
      00000000000000000000000000000000000000000000AA774BFFBA8258FF2814
      77FF281477FF281477FF281477FF281477FF281477FF281477FF281477FF2814
      77FF281477FF281477FFA95E2EFF742B03FF0000000000000000000800100059
      00AF31A531FFAAE5AAFFD0FBD1FFC1FAC2FFB8F8B8FFBFF8C0FF99E29AFF2CA4
      2CFF005900AF00080010000000000000000000000000BFBFBFFFBFBFBFFFBFBF
      BFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFBFBFBFFFB3B3B3EF2424
      2430000000000000000000000000000000000000000006212836138297FF087A
      91FF087A91FF158398FF03222941000000000000000000000000000000000000
      00000000000000000000000000000000000000000000582E0FC1723323FF320C
      57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C57FF320C
      57FF320C57FF320C57FF692412FF511E02C10000000000000000000000000000
      0000002000400050009F007000DF229E22FF229E22FF007000DF0050009F0020
      004000000000000000000000000000000000424D3E000000000000003E000000
      2800000040000000B00000000100010000000000800500000000000000000000
      000000000000000000000000FFFFFF00FBFFFBFF00000000F9FFF9FF00000000
      FCFFFCFF00000000FC7FFC7F00000000F03FF03F00000000F01FF01F00000000
      F80FF80F00000000F83FF83F00000000C01FC01F00000000C00FC00F00000000
      E00FE00F00000000E03FE03F00000000F01FF01F00000000F00FF00F00000000
      F807F80700000000F803F80300000000FC01FC01FFFFFFFFFC01FC01FEFFFEFF
      FC01FC01FC7FFC7FFC01FC01F83FF83FFC01FC01F01FF01F80018001E00FE00F
      8001BC01C007C0078001BC01C007C0078003BC03C007C0078007BC07F83FF83F
      800FBC0FF83FF83F803FBFBFF83FF83F803FBC3FF83FF83F807FBD7FF83FF83F
      80FFBCFFF83FF83F81FF81FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFC001C001
      0E1F0E1F80018001060F060F800180018307830780018001C183C18380018001
      E0C1E0C180018001F060F06080018001F060F06080018001E0C1E0C180018001
      C183C183800180018307830780018001060F060F800180010E1F0E1F80018001
      FFFFFFFF80018001FFFFFFFFFFFFFFFF87FF8000FFFFFFFF81FF8000FFFFFFFF
      807F8000F07FF07F803F8000F03FF03F800F8000F81FF81F80078000FC0FFC0F
      80018000FE07FE0780008000FF03FF0380008000FF03FF0380018000FE07FE07
      80078000FC0FFC0F801F8000F81FF81F807F8000F03FF03F81FF8000F07FF07F
      87FF8000FFFFFFFF9FFF8000FFFFFFFFFFFFE187FFFF00008001E00700000000
      8001E007000000008001E0070000000080010000000000008001000000000000
      8001000000000000800100000000000080018001000000008001800300000000
      800180010000000080018001E007000080018001E007000080018001E0070000
      8001FC3FF00F0000FFFFFC3FF81F0000000000000000F00F000000000000C003
      0000000000008001000000000000800100000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000080010000000000008001
      000000000000C003000000000000F00F00000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
      0000000000000000000000000000000000000000000000000000000000000000
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
    Left = 128
    Top = 368
    object pmiNorm: TMenuItem
      Caption = 'Normalize'
      object Auto1: TMenuItem
        Action = DataNormAuto
        OnClick = Auto1Click
      end
      object Manual1: TMenuItem
        Action = DataNormMan
        OnClick = Manual1Click
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
      OnClick = Properties1Click
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
end
