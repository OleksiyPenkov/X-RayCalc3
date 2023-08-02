object edtrProfileTable: TedtrProfileTable
  Left = 0
  Top = 0
  Caption = 'Table Editor'
  ClientHeight = 678
  ClientWidth = 977
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 634
    Width = 971
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 453
    ExplicitWidth = 861
    DesignSize = (
      971
      41)
    object btnOK: TRzBitBtn
      Left = 889
      Top = 10
      Width = 66
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 0
      TabStop = False
      Kind = bkOK
      ExplicitLeft = 779
    end
    object btnCancel: TRzBitBtn
      Left = 9
      Top = 10
      Width = 72
      Alignment = taRightJustify
      TabOrder = 1
      TabStop = False
      Kind = bkCancel
    end
  end
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 971
    Height = 46
    Align = alTop
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
  end
  object RzPageControl1: TRzPageControl
    Left = 0
    Top = 52
    Width = 977
    Height = 579
    Hint = ''
    ActivePage = tsThickness
    Align = alClient
    TabIndex = 0
    TabOrder = 2
    ExplicitLeft = 120
    ExplicitTop = 88
    ExplicitWidth = 300
    ExplicitHeight = 150
    FixedDimension = 21
    object tsThickness: TRzTabSheet
      Caption = 'Thickness'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdThikness: TRzStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 248
        Height = 548
        Align = alLeft
        ColCount = 2
        DefaultColWidth = 70
        DefaultColAlignment = taCenter
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goFixedRowDefAlign]
        TabOrder = 0
        ExplicitLeft = 9
        ExplicitTop = 36
        ExplicitHeight = 403
      end
      object chrtThickness: TChart
        AlignWithMargins = True
        Left = 257
        Top = 3
        Width = 713
        Height = 548
        Cursor = crCross
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        View3D = False
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 263
        ExplicitTop = 7
        ExplicitWidth = 594
        ExplicitHeight = 432
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
    end
    object tsRoughness: TRzTabSheet
      Caption = 'tsRoughness'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdRoughness: TRzStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 248
        Height = 548
        Align = alLeft
        ColCount = 2
        DefaultColWidth = 70
        DefaultColAlignment = taCenter
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goFixedRowDefAlign]
        TabOrder = 0
        ExplicitLeft = 11
        ExplicitTop = 6
      end
      object chrtRougness: TChart
        AlignWithMargins = True
        Left = 257
        Top = 3
        Width = 713
        Height = 548
        Cursor = crCross
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        View3D = False
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 260
        ExplicitTop = 6
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
    end
    object tsDensity: TRzTabSheet
      Caption = 'tsDensity'
      ExplicitLeft = 0
      ExplicitTop = 0
      ExplicitWidth = 0
      ExplicitHeight = 0
      object grdDensity: TRzStringGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 248
        Height = 548
        Align = alLeft
        ColCount = 2
        DefaultColWidth = 70
        DefaultColAlignment = taCenter
        FixedCols = 0
        RowCount = 2
        Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goFixedRowDefAlign]
        TabOrder = 0
        ExplicitLeft = 11
        ExplicitTop = 6
      end
      object chrtDensity: TChart
        AlignWithMargins = True
        Left = 257
        Top = 3
        Width = 713
        Height = 548
        Cursor = crCross
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        View3D = False
        Align = alClient
        TabOrder = 1
        ExplicitLeft = 260
        ExplicitTop = 6
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
    end
  end
end
