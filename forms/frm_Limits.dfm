object frmLimits: TfrmLimits
  Left = 0
  Top = 0
  Margins.Left = 6
  Margins.Top = 6
  Margins.Right = 6
  Margins.Bottom = 6
  Caption = 'Fitting Limits'
  ClientHeight = 952
  ClientWidth = 1138
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -24
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnAfterMonitorDpiChanged = FormAfterMonitorDpiChanged
  OnCreate = FormCreate
  PixelsPerInch = 192
  TextHeight = 32
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 1126
    Height = 846
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alClient
    BevelWidth = 2
    BorderOuter = fsFlatRounded
    TabOrder = 0
    Color = 15987699
    object Label13: TLabel
      Left = 38
      Top = 786
      Width = 39
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'DH'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -30
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object Label14: TLabel
      Left = 166
      Top = 786
      Width = 36
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Ds'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -30
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object Label15: TLabel
      Left = 294
      Top = 786
      Width = 37
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Dr'
      Font.Charset = GREEK_CHARSET
      Font.Color = clBlack
      Font.Height = -30
      Font.Name = 'Symbol'
      Font.Style = []
      ParentFont = False
    end
    object ListView: TRzListView
      AlignWithMargins = True
      Left = 10
      Top = 10
      Width = 1106
      Height = 732
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 100
      Align = alClient
      Columns = <
        item
          Caption = 'Layer'
          Width = 200
        end
        item
          Alignment = taCenter
          Caption = 'Hmin'
          Width = 140
        end
        item
          Alignment = taCenter
          Caption = 'Hmax'
          Width = 140
        end
        item
          Alignment = taCenter
          Caption = 'Smin'
          Width = 140
        end
        item
          Alignment = taCenter
          Caption = 'Smax'
          Width = 140
        end
        item
          Alignment = taCenter
          Caption = 'RMin'
          Width = 140
        end
        item
          Alignment = taCenter
          Caption = 'RMax'
          Width = 168
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
    end
    object edFdH: TEdit
      Left = 80
      Top = 784
      Width = 66
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 1
      Text = '0.25'
    end
    object edFdS: TEdit
      Left = 208
      Top = 784
      Width = 66
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 2
      Text = '0.25'
    end
    object edFdRho: TEdit
      Left = 336
      Top = 784
      Width = 66
      Height = 37
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Alignment = taRightJustify
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -24
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
      TabOrder = 3
      Text = '0.25'
    end
    object btnInit: TBitBtn
      Left = 432
      Top = 782
      Width = 150
      Height = 50
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Initialize'
      TabOrder = 4
      OnClick = btnInitClick
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 6
    Top = 864
    Width = 1126
    Height = 82
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alBottom
    BevelWidth = 2
    BorderOuter = fsFlatRounded
    TabOrder = 1
    Color = 15987699
    object btnSet: TRzBitBtn
      Left = 946
      Top = 16
      Width = 150
      Height = 50
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ModalResult = 1
      Caption = 'Set'
      TabOrder = 0
      Margin = 4
      Spacing = 8
    end
    object RzBitBtn2: TRzBitBtn
      Left = 10
      Top = 16
      Width = 150
      Height = 50
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ModalResult = 2
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = RzBitBtn2Click
      Margin = 4
      Spacing = 8
    end
  end
end
