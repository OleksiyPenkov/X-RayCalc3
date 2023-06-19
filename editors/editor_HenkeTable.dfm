object edtrHenkeTable: TedtrHenkeTable
  Left = 0
  Top = 0
  Caption = 'Edit Henke table'
  ClientHeight = 562
  ClientWidth = 864
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object rzpnl1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 326
    Height = 537
    Align = alLeft
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitHeight = 536
    object Label1: TLabel
      Left = 11
      Top = 10
      Width = 43
      Height = 15
      Caption = 'Material'
    end
    object Label7: TLabel
      Left = 179
      Top = 42
      Width = 56
      Height = 16
      Caption = #961' (g/cm'#179')'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object Label6: TLabel
      Left = 11
      Top = 42
      Width = 44
      Height = 16
      Caption = 'N (a.u.)'
      Font.Charset = ANSI_CHARSET
      Font.Color = clBlack
      Font.Height = -13
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object edMaterial: TRzButtonEdit
      Left = 66
      Top = 7
      Width = 140
      Height = 23
      Text = ''
      TabOrder = 0
      AltBtnNumGlyphs = 1
      ButtonNumGlyphs = 1
      OnButtonClick = edMaterialButtonClick
    end
    object edRo: TJvCalcEdit
      Left = 241
      Top = 40
      Width = 75
      Height = 23
      ButtonFlat = True
      TabOrder = 1
      DecimalPlacesAlwaysShown = False
    end
    object edN: TJvCalcEdit
      Left = 61
      Top = 40
      Width = 100
      Height = 23
      ButtonFlat = True
      TabOrder = 2
      DecimalPlacesAlwaysShown = False
    end
    object FGrid: TRzStringGrid
      AlignWithMargins = True
      Left = 5
      Top = 82
      Width = 316
      Height = 450
      Margins.Top = 80
      Align = alClient
      ColCount = 4
      DefaultColWidth = 70
      FixedCols = 0
      RowCount = 1
      FixedRows = 0
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goFixedRowDefAlign]
      TabOrder = 3
      OnSetEditText = FGridSetEditText
      ExplicitHeight = 449
    end
    object btnSave: TRzBitBtn
      Left = 241
      Top = 5
      Caption = 'Save'
      TabOrder = 4
      OnClick = btnSaveClick
    end
  end
  object rzstsbr1: TRzStatusBar
    Left = 0
    Top = 543
    Width = 864
    Height = 19
    BorderInner = fsNone
    BorderOuter = fsNone
    BorderSides = [sdLeft, sdTop, sdRight, sdBottom]
    BorderWidth = 0
    Color = 15987699
    TabOrder = 1
    ExplicitTop = 542
    ExplicitWidth = 860
  end
  object rzpnl2: TRzPanel
    AlignWithMargins = True
    Left = 335
    Top = 3
    Width = 526
    Height = 537
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 2
    ExplicitWidth = 522
    ExplicitHeight = 536
    object Chart: TChart
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 516
      Height = 527
      Cursor = crCross
      Title.Text.Strings = (
        'TChart')
      Title.Visible = False
      View3D = False
      Align = alClient
      Color = clWhite
      TabOrder = 0
      ExplicitWidth = 512
      ExplicitHeight = 526
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
      object SeriesF1: TLineSeries
        HoverElement = [heCurrent]
        Legend.Text = 'f1'
        LegendTitle = 'f1'
        Brush.BackColor = clDefault
        LinePen.Width = 2
        Pointer.InflateMargins = True
        Pointer.Style = psRectangle
        XValues.Name = 'X'
        XValues.Order = loAscending
        YValues.Name = 'Y'
        YValues.Order = loNone
      end
      object SeriesF2: TLineSeries
        HoverElement = [heCurrent]
        Legend.Text = 'f2'
        LegendTitle = 'f2'
        SeriesColor = clRed
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
  end
end
