object frmStructurePanel: TfrmStructurePanel
  Left = 0
  Top = 0
  Width = 350
  Height = 776
  Align = alClient
  Color = 15987699
  ParentColor = False
  TabOrder = 0
  object tlbStructure: TRzToolbar
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 344
    Height = 104
    RowHeight = 25
    ButtonWidth = 25
    ButtonHeight = 25
    TextOptions = ttoCustom
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
      Left = 7
      Top = 2
      ImageIndex = 0
      ParentShowHint = False
      ShowHint = True
    end
    object btnPeriodInsert: TRzToolButton
      Left = 60
      Top = 2
      ImageIndex = 2
      ParentShowHint = False
      ShowHint = True
    end
    object btnPeriodDelete: TRzToolButton
      Left = 113
      Top = 2
      ImageIndex = 6
      ParentShowHint = False
      ShowHint = True
    end
    object rzspcr1: TRzSpacer
      Left = 166
      Top = 15
    end
    object btnLayerAdd: TRzToolButton
      Left = 177
      Top = 2
      Hint = 'Add Layer'
      ImageIndex = 1
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerInsert: TRzToolButton
      Left = 230
      Top = 2
      Hint = 'Insert Layer'
      ImageIndex = 5
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerPaste: TRzToolButton
      Left = 60
      Top = 52
      Hint = 'Paste layer'
      ImageIndex = 4
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerDelete: TRzToolButton
      Left = 124
      Top = 52
      Hint = 'Delete layer'
      ImageIndex = 7
      ParentShowHint = False
      ShowHint = True
    end
    object btnLayerCut: TRzToolButton
      Left = 7
      Top = 52
      Hint = 'Cut layer'
      ImageIndex = 3
      ParentShowHint = False
      ShowHint = True
    end
    object RzSpacer3: TRzSpacer
      Left = 113
      Top = 65
    end
    object btnCopyLayer: TRzToolButton
      Left = 283
      Top = 2
      ImageIndex = 8
      ParentShowHint = False
      ShowHint = True
    end
  end
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 113
    Width = 344
    Height = 41
    Align = alTop
    BorderOuter = fsNone
    TabOrder = 1
    Color = 15987699
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
      Left = 265
      Top = 5
      Width = 75
      Height = 25
      Caption = 'Limits'
      TabOrder = 1
      OnClick = btnSetFitLimitsClick
    end
  end
end
