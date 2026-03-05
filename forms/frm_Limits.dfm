object frmLimits: TfrmLimits
  Left = 0
  Top = 0
  Margins.Left = 3
  Margins.Top = 3
  Margins.Right = 3
  Margins.Bottom = 3
  BorderStyle = bsDialog
  Caption = 'Fitting Limits'
  ClientHeight = 476
  ClientWidth = 569
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnCreate = FormCreate
  PixelsPerInch = 96
  TextHeight = 16
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 563
    Height = 423
    Margins.Left = 3
    Margins.Top = 3
    Margins.Right = 3
    Margins.Bottom = 3
    Align = alClient
    BevelWidth = 1
    BorderOuter = fsFlatRounded
    TabOrder = 0
    Color = 15987699
    object Label13: TLabel
      Left = 19
      Top = 393
      Width = 20
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'DH'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object Label14: TLabel
      Left = 83
      Top = 393
      Width = 18
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Ds'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object Label15: TLabel
      Left = 147
      Top = 393
      Width = 18
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Dr'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -15
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object ListView: TRzListView
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 553
      Height = 366
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 50
      Align = alClient
      Columns = <
        item
          Caption = 'Layer'
          Width = 100
        end
        item
          Alignment = taCenter
          Caption = 'Hmin'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Hmax'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Smin'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'Smax'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'RMin'
          Width = 70
        end
        item
          Alignment = taCenter
          Caption = 'RMax'
          Width = 84
        end>
      ColumnClick = False
      GridLines = True
      GroupView = True
      ReadOnly = True
      ShowWorkAreas = True
      TabOrder = 0
      ViewStyle = vsReport
      FillLastColumn = False
      OnClick = ListViewClick
      OnCustomDrawSubItem = ListViewCustomDrawSubItem
    end
    object edFdH: TEdit
      Left = 40
      Top = 392
      Width = 33
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = '0.25'
    end
    object edFdS: TEdit
      Left = 104
      Top = 392
      Width = 33
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = '0.25'
    end
    object edFdRho: TEdit
      Left = 168
      Top = 392
      Width = 33
      Height = 18
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -12
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Text = '0.25'
    end
    object btnInit: TBitBtn
      Left = 216
      Top = 391
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Initialize'
      TabOrder = 4
      Hint = 'Generate limits from current values using DH/DS/DRho percentages'
      ShowHint = True
      OnClick = btnInitClick
    end
    object btnNarrow: TBitBtn
      Left = 296
      Top = 391
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Narrow'
      TabOrder = 5
      Hint = 'Shrink limits toward fitted values by 50%'
      ShowHint = True
      OnClick = btnNarrowClick
    end
    object btnWiden: TBitBtn
      Left = 376
      Top = 391
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Widen'
      TabOrder = 6
      Hint = 'Expand limits where fitted value is at a boundary'
      ShowHint = True
      OnClick = btnWidenClick
    end
    object btnFix: TBitBtn
      Left = 456
      Top = 391
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Fix'
      TabOrder = 7
      Hint = 'Auto-fix all errors and warnings'
      ShowHint = True
      OnClick = btnFixClick
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 432
    Width = 563
    Height = 41
    Margins.Left = 3
    Margins.Top = 3
    Margins.Right = 3
    Margins.Bottom = 3
    Align = alBottom
    BevelWidth = 1
    BorderOuter = fsFlatRounded
    TabOrder = 1
    Color = 15987699
    object btnSet: TRzBitBtn
      Left = 473
      Top = 8
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      Caption = 'Set'
      TabOrder = 0
      OnClick = btnSetClick
      Margin = 4
      Spacing = 4
    end
    object RzBitBtn2: TRzBitBtn
      Left = 5
      Top = 8
      Width = 75
      Height = 25
      Margins.Left = 3
      Margins.Top = 3
      Margins.Right = 3
      Margins.Bottom = 3
      ModalResult = 2
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = RzBitBtn2Click
      Margin = 4
      Spacing = 4
    end
  end
end
