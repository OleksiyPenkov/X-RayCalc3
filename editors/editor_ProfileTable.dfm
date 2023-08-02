object edtrProfileTable: TedtrProfileTable
  Left = 0
  Top = 0
  Caption = 'Table Editor'
  ClientHeight = 498
  ClientWidth = 871
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnShow = FormShow
  TextHeight = 15
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 454
    Width = 865
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 453
    ExplicitWidth = 861
    DesignSize = (
      865
      41)
    object btnOK: TRzBitBtn
      Left = 787
      Top = 10
      Width = 66
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 0
      TabStop = False
      Kind = bkOK
      ExplicitLeft = 783
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
    Width = 865
    Height = 445
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    ExplicitWidth = 861
    ExplicitHeight = 444
    object Label1: TLabel
      Left = 9
      Top = 10
      Width = 32
      Height = 15
      Caption = 'Name'
    end
    object edTitle: TEdit
      Left = 55
      Top = 7
      Width = 123
      Height = 23
      TabOrder = 0
      Text = 'Gradient'
    end
    object Grid: TRzStringGrid
      Left = 9
      Top = 36
      Width = 248
      Height = 403
      ColCount = 2
      DefaultColWidth = 70
      DefaultColAlignment = taCenter
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing, goFixedRowDefAlign]
      TabOrder = 1
    end
    object Chart: TChart
      Left = 263
      Top = 7
      Width = 594
      Height = 432
      Cursor = crCross
      Legend.Visible = False
      Title.Text.Strings = (
        'TChart')
      Title.Visible = False
      View3D = False
      TabOrder = 2
      DefaultCanvas = 'TGDIPlusCanvas'
      ColorPaletteIndex = 13
      object Series1: TLineSeries
        HoverElement = [heCurrent]
        Brush.BackColor = clDefault
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
