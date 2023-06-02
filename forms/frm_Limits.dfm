object frmLimits: TfrmLimits
  Left = 0
  Top = 0
  Caption = 'Fitting Limits'
  ClientHeight = 478
  ClientWidth = 567
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 15
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 561
    Height = 425
    Align = alClient
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitWidth = 569
    ExplicitHeight = 426
    object Label13: TLabel
      Left = 19
      Top = 393
      Width = 20
      Height = 19
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
      Height = 19
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
      Height = 19
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
      Width = 555
      Height = 369
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
      Items.ItemData = {}
      ReadOnly = True
      ShowWorkAreas = True
      TabOrder = 0
      ViewStyle = vsReport
      FillLastColumn = False
      OnClick = ListViewClick
      ExplicitWidth = 559
    end
    object edFdH: TEdit
      Left = 40
      Top = 392
      Width = 33
      Height = 22
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
      Height = 22
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
      Height = 22
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
      Caption = 'Initialize'
      TabOrder = 4
      OnClick = btnInitClick
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 434
    Width = 561
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    object RzBitBtn1: TRzBitBtn
      Left = 476
      Top = 8
      ModalResult = 1
      Caption = 'Set'
      TabOrder = 0
    end
    object RzBitBtn2: TRzBitBtn
      Left = 5
      Top = 8
      ModalResult = 2
      Caption = 'Cancel'
      TabOrder = 1
      OnClick = RzBitBtn2Click
    end
  end
end
