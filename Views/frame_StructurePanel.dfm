object frmStructurePanel: TfrmStructurePanel
  Left = 0
  Top = 0
  Width = 700
  Height = 1552
  Margins.Left = 6
  Margins.Top = 6
  Margins.Right = 6
  Margins.Bottom = 6
  Align = alClient
  Color = 15987699
  TabOrder = 0
  object tlbStructure: TRzToolbar
    AlignWithMargins = True
    Left = 6
    Top = 6
    Width = 688
    Height = 54
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    RowHeight = 50
    ButtonWidth = 50
    ButtonHeight = 50
    TextOptions = ttoCustom
    BevelWidth = 2
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
      Left = 10
      Top = 2
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 0
      ParentShowHint = False
      ShowHint = True
    end
    object btnPeriodInsert: TRzToolButton
      Left = 66
      Top = 2
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 2
      ParentShowHint = False
      ShowHint = True
    end
    object btnPeriodDelete: TRzToolButton
      Left = 122
      Top = 2
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 6
      ParentShowHint = False
      ShowHint = True
    end
    object rzspcr1: TRzSpacer
      Left = 178
      Top = 2
      Width = 16
      Height = 50
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
    end
    object btnLayerAdd: TRzToolButton
      Left = 200
      Top = 2
      Hint = 'Add Layer'
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 1
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerInsert: TRzToolButton
      Left = 256
      Top = 2
      Hint = 'Insert Layer'
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 5
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerPaste: TRzToolButton
      Left = 424
      Top = 2
      Hint = 'Paste layer'
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 4
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerDelete: TRzToolButton
      Left = 502
      Top = 2
      Hint = 'Delete layer'
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 7
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerCut: TRzToolButton
      Left = 368
      Top = 2
      Hint = 'Cut layer'
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 3
      ParentShowHint = False
      ShowHint = True
    end
    object RzSpacer3: TRzSpacer
      Left = 480
      Top = 2
      Width = 16
      Height = 50
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
    end
    object btnCopyLayer: TRzToolButton
      Left = 312
      Top = 2
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      ImageIndex = 8
      ParentShowHint = False
      ShowHint = True
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 6
    Top = 72
    Width = 688
    Height = 82
    Margins.Left = 6
    Margins.Top = 6
    Margins.Right = 6
    Margins.Bottom = 6
    Align = alTop
    BevelWidth = 2
    BorderOuter = fsNone
    TabOrder = 1
    Color = 15987699
    object Label6: TLabel
      Left = 12
      Top = 20
      Width = 99
      Height = 27
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Increment'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clBlack
      Font.Height = -22
      Font.Name = 'Tahoma'
      Font.Style = []
      ParentFont = False
    end
    object cbIncrement: TRzComboBox
      Left = 122
      Top = 12
      Width = 104
      Height = 40
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      TabOrder = 0
      Text = '0.1'
      OnChange = cbIncrementChange
      Items.Strings = (
        '10'
        '5'
        '1'
        '0.25'
        '0.1'
        '0.01')
      ItemIndex = 4
      Values.Strings = (
        '10'
        '5'
        '1'
        '0.25'
        '0.1'
        '0.01')
    end
    object btnSetFitLimits: TBitBtn
      Left = 530
      Top = 10
      Width = 150
      Height = 50
      Margins.Left = 6
      Margins.Top = 6
      Margins.Right = 6
      Margins.Bottom = 6
      Caption = 'Limits'
      TabOrder = 1
      OnClick = btnSetFitLimitsClick
    end
  end
end
