object frmUncertMain: TfrmUncertMain
  Left = 0
  Top = 0
  Caption = 'XRCUncert'
  ClientHeight = 640
  ClientWidth = 1100
  Color = clBtnFace
  Constraints.MinHeight = 400
  Constraints.MinWidth = 760
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  KeyPreview = True
  Position = poScreenCenter
  OnCloseQuery = FormCloseQuery
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  OnKeyDown = FormKeyDown
  PixelsPerInch = 96
  TextHeight = 15
  object splMain: TSplitter
    Left = 546
    Top = 68
    Width = 4
    Height = 470
    ExplicitLeft = 540
    ExplicitTop = 62
    ExplicitHeight = 482
  end
  object pnlTop: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 1094
    Height = 62
    Align = alTop
    BorderOuter = fsFlatRounded
    TabOrder = 0
    object lblModel: TLabel
      Left = 308
      Top = 14
      Width = 213
      Height = 15
      Caption = 'Open a fitted project, or drop it here.'
    end
    object lblProgress: TLabel
      Left = 10
      Top = 40
      Width = 3
      Height = 15
    end
    object btnOpen: TButton
      Left = 8
      Top = 8
      Width = 92
      Height = 26
      Caption = 'Open...'
      TabOrder = 0
      OnClick = btnOpenClick
    end
    object btnRun: TButton
      Left = 106
      Top = 8
      Width = 92
      Height = 26
      Caption = 'Run'
      Enabled = False
      TabOrder = 1
      OnClick = btnRunClick
    end
    object btnStop: TButton
      Left = 204
      Top = 8
      Width = 92
      Height = 26
      Caption = 'Stop'
      Enabled = False
      TabOrder = 2
      OnClick = btnStopClick
    end
  end
  object pnlBottom: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 541
    Width = 1094
    Height = 96
    Align = alBottom
    BorderOuter = fsFlatRounded
    TabOrder = 1
    object memWarnings: TMemo
      AlignWithMargins = True
      Left = 8
      Top = 6
      Width = 698
      Height = 84
      Margins.Left = 6
      Margins.Top = 4
      Margins.Right = 6
      Margins.Bottom = 4
      Align = alClient
      BorderStyle = bsNone
      ParentColor = True
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
    end
    object pnlButtons: TRzPanel
      AlignWithMargins = True
      Left = 709
      Top = 5
      Width = 380
      Height = 86
      Align = alRight
      BorderOuter = fsNone
      TabOrder = 1
      object lblDigits: TLabel
        Left = 4
        Top = 28
        Width = 103
        Height = 15
        Caption = 'Digits in the error:'
      end
      object cbDigits: TComboBox
        Left = 116
        Top = 24
        Width = 48
        Height = 23
        Style = csDropDownList
        ItemIndex = 1
        TabOrder = 4
        Text = '2'
        OnChange = cbDigitsChange
        Items.Strings = (
          '1'
          '2'
          '3'
          '4')
      end
      object btnDetails: TButton
        Left = 4
        Top = 55
        Width = 88
        Height = 26
        Caption = 'Details...'
        Enabled = False
        TabOrder = 0
        OnClick = btnDetailsClick
      end
      object btnCopy: TButton
        Left = 98
        Top = 55
        Width = 88
        Height = 26
        Caption = 'Copy table'
        Enabled = False
        TabOrder = 1
        OnClick = btnCopyClick
      end
      object btnExport: TButton
        Left = 192
        Top = 55
        Width = 88
        Height = 26
        Caption = 'Export...'
        Enabled = False
        TabOrder = 2
        OnClick = btnExportClick
      end
      object btnHelp: TButton
        Left = 286
        Top = 55
        Width = 88
        Height = 26
        Caption = 'Help'
        TabOrder = 3
        OnClick = btnHelpClick
      end
    end
  end
  object lvParams: TRzListView
    AlignWithMargins = True
    Left = 3
    Top = 71
    Width = 540
    Height = 464
    Align = alLeft
    Columns = <
      item
        Caption = 'Parameter'
        Width = 170
      end
      item
        Alignment = taRightJustify
        Caption = 'Value'
        Width = 70
      end
      item
        Caption = #177
        Width = 90
      end
      item
        Alignment = taRightJustify
        Caption = 'Known'
        Width = 60
      end
      item
        Caption = #177
        Width = 50
      end
      item
        Caption = 'Note'
        Width = 90
      end>
    GridLines = True
    GroupView = True
    HideSelection = False
    ReadOnly = True
    RowSelect = True
    TabOrder = 2
    ViewStyle = vsReport
    OnClick = lvParamsClick
  end
  object edCell: TEdit
    Left = 400
    Top = 300
    Width = 60
    Height = 23
    TabOrder = 4
    Visible = False
    OnExit = edCellExit
    OnKeyDown = edCellKeyDown
    OnKeyPress = edCellKeyPress
  end
  object pcCharts: TPageControl
    AlignWithMargins = True
    Left = 553
    Top = 71
    Width = 544
    Height = 464
    ActivePage = tsCurve
    Align = alClient
    TabOrder = 3
    object tsCurve: TTabSheet
      Caption = 'Curve'
      object chCurve: TChart
        AlignWithMargins = True
        Cursor = crCross
        Left = 3
        Top = 3
        Width = 530
        Height = 428
        Legend.Alignment = laBottom
        Legend.LegendStyle = lsSeries
        Title.Visible = False
        BottomAxis.Title.Caption = 'Angle, deg'
        LeftAxis.Logarithmic = True
        LeftAxis.Title.Caption = 'Reflectivity'
        View3D = False
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        TabOrder = 0
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
        object serMeasured: TPointSeries
          SeriesColor = clGray
          Title = 'Measured'
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object serLow: TLineSeries
          SeriesColor = 16744448
          Title = 'Error range (68 %)'
          Brush.BackColor = clDefault
          LinePen.Color = 16744448
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object serHigh: TLineSeries
          SeriesColor = 16744448
          ShowInLegend = False
          Title = '84 %'
          Brush.BackColor = clDefault
          LinePen.Color = 16744448
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object serMedian: TLineSeries
          SeriesColor = clRed
          Title = 'Model'
          Brush.BackColor = clDefault
          LinePen.Color = clRed
          LinePen.Width = 2
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
      end
    end
    object tsDepth: TTabSheet
      Caption = 'Depth'
      ImageIndex = 1
      object cbDepth: TComboBox
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 530
        Height = 23
        Align = alTop
        Style = csDropDownList
        TabOrder = 0
        OnChange = cbDepthChange
      end
      object chDepth: TChart
        AlignWithMargins = True
        Cursor = crCross
        Left = 3
        Top = 32
        Width = 530
        Height = 399
        Legend.Alignment = laBottom
        Legend.LegendStyle = lsSeries
        Title.Visible = False
        BottomAxis.Title.Caption = 'Period number'
        View3D = False
        Align = alClient
        BevelOuter = bvNone
        Color = clWhite
        TabOrder = 1
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
        object serDepthLow: TLineSeries
          SeriesColor = 16744448
          Title = 'Error range (68 %)'
          Brush.BackColor = clDefault
          LinePen.Color = 16744448
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object serDepthHigh: TLineSeries
          SeriesColor = 16744448
          ShowInLegend = False
          Title = '84 %'
          Brush.BackColor = clDefault
          LinePen.Color = 16744448
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
        object serDepthMedian: TLineSeries
          SeriesColor = clRed
          Title = 'Value'
          Brush.BackColor = clDefault
          LinePen.Color = clRed
          LinePen.Width = 2
          Pointer.InflateMargins = True
          Pointer.Style = psRectangle
          Pointer.Visible = True
          XValues.Name = 'X'
          XValues.Order = loAscending
          YValues.Name = 'Y'
          YValues.Order = loNone
        end
      end
    end
  end
  object dlgOpen: TOpenDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project (*.xrcx)|*.xrcx|All files (*.*)|*.*'
    Options = [ofHideReadOnly, ofFileMustExist, ofEnableSizing]
    Left = 624
    Top = 16
  end
  object dlgExport: TSaveDialog
    DefaultExt = 'csv'
    Filter = 'Comma-separated values (*.csv)|*.csv'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Left = 696
    Top = 16
  end
end
