object frmChartInfo: TfrmChartInfo
  Left = 0
  Top = 0
  Width = 1048
  Height = 600
  Margins.Left = 3
  Margins.Top = 3
  Margins.Right = 3
  Margins.Bottom = 3
  Align = alClient
  Color = 15987699
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  ParentFont = False
  TabOrder = 0
  object Chart: TChart
    AlignWithMargins = True
    Left = 5
    Top = 5
    Width = 1038
    Height = 540
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
    TabOrder = 0
    OnMouseDown = ChartMouseDown
    OnMouseMove = ChartMouseMove
    OnMouseUp = ChartMouseUp
    OnResize = ChartResize
    DefaultCanvas = 'TGDIPlusCanvas'
    OnZoom = ChartZoom
    ColorPaletteIndex = 13
    object btnStop: TRzBitBtn
      Left = 584
      Top = 41
      Width = 128
      Height = 40
      FrameColor = clRed
      ModalResult = 3
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
      Margin = 4
    end
  end
  object pnlInfo: TRzPanel
    Left = 0
    Top = 550
    Width = 1048
    Height = 50
    Align = alBottom
    BorderOuter = fsNone
    Color = 15987699
    TabOrder = 1
    DesignSize = (
      1048
      50)
    object RzStatusPane1: TRzStatusPane
      Left = 5
      Top = 4
      Width = 25
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 41
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Left = 892
      Top = 7
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
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
      Margin = 4
      Spacing = 4
    end
    object cbMinLimit: TRzComboBox
      Left = 973
      Top = 8
      Width = 66
      Height = 20
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Anchors = [akRight, akBottom]
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = [fsBold]
      ParentFont = False
      TabOrder = 1
      Text = '5E-7'
      OnChange = cbMinLimitChange
      Items.Strings = (
        '10E-4'
        '10E-5'
        '10E-6'
        '10E-7'
        '10E-8'
        '10E-9')
    end
  end
end
