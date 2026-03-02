object frmProjectPanel: TfrmProjectPanel
  Left = 0
  Top = 0
  Width = 239
  Height = 1085
  Align = alClient
  Color = 15987699
  ParentColor = False
  TabOrder = 0
  object tlbrFile: TRzToolbar
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 233
    Height = 29
    Images = vliProject
    TextOptions = ttoCustom
    BorderInner = fsNone
    BorderOuter = fsGroove
    BorderSides = [sdTop]
    BorderWidth = 0
    ParentShowHint = False
    ShowHint = True
    StyleName = 'Windows'
    TabOrder = 0
    ExplicitLeft = 5
    ExplicitTop = 5
    ExplicitWidth = 229
    ToolbarControls = (
      BtnNew
      BtnOpen
      btnReopenProject
      rzspcr2
      BtnSave
      RzSpacer1
      BtnPrint)
    object BtnNew: TRzToolButton
      Left = 7
      Top = 2
      DisabledIndex = 1
      ImageIndex = 0
    end
    object BtnOpen: TRzToolButton
      Left = 35
      Top = 2
      Width = 39
      DisabledIndex = 3
      ImageIndex = 1
      ToolStyle = tsDropDown
    end
    object btnReopenProject: TRzToolButton
      Left = 77
      Top = 2
      DisabledIndex = 23
      ImageIndex = 2
    end
    object rzspcr2: TRzSpacer
      Left = 105
      Top = 2
    end
    object BtnSave: TRzToolButton
      Left = 116
      Top = 2
      DisabledIndex = 5
      ImageIndex = 3
    end
    object RzSpacer1: TRzSpacer
      Left = 144
      Top = 2
    end
    object BtnPrint: TRzToolButton
      Left = 155
      Top = 2
      DisabledIndex = 7
      ImageIndex = 4
    end
  end
  object tlbrProject: TRzToolbar
    AlignWithMargins = True
    Left = 3
    Top = 38
    Width = 233
    Height = 29
    Hint = 'Delete item'
    Images = vliProject
    TextOptions = ttoCustom
    BorderInner = fsNone
    BorderOuter = fsGroove
    BorderSides = [sdTop]
    BorderWidth = 0
    ParentShowHint = False
    ShowHint = True
    StyleName = 'Windows'
    TabOrder = 1
    ExplicitLeft = 5
    ExplicitTop = 40
    ExplicitWidth = 229
    ToolbarControls = (
      btnAddModel
      BtnExport
      BtnCopy
      BtnPaste
      BtnEdit
      RzSpacer4
      btnAddExtension
      RzSpacer5
      BtnRecycle)
    object btnAddModel: TRzToolButton
      Left = 7
      Top = 2
      DisabledIndex = 9
      ImageIndex = 5
    end
    object BtnExport: TRzToolButton
      Left = 35
      Top = 2
      DisabledIndex = 11
      ImageIndex = 6
    end
    object BtnCopy: TRzToolButton
      Left = 63
      Top = 2
      Hint = 'Copy model to clipboard'
      DisabledIndex = 13
      ImageIndex = 7
    end
    object BtnPaste: TRzToolButton
      Left = 91
      Top = 2
      Hint = 'Paste model'
      DisabledIndex = 15
      ImageIndex = 8
    end
    object BtnEdit: TRzToolButton
      Left = 119
      Top = 2
      Hint = 'Properites'
      DisabledIndex = 17
      ImageIndex = 9
    end
    object RzSpacer4: TRzSpacer
      Left = 147
      Top = 2
    end
    object btnAddExtension: TRzToolButton
      Left = 158
      Top = 2
      Hint = 'Add extension'
      DisabledIndex = 19
      ImageIndex = 10
    end
    object RzSpacer5: TRzSpacer
      Left = 186
      Top = 2
    end
    object BtnRecycle: TRzToolButton
      Left = 197
      Top = 2
      Hint = 'Delete item'
      DisabledIndex = 21
      ImageIndex = 11
    end
  end
  object RzPanel5: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 1000
    Width = 233
    Height = 82
    Align = alBottom
    BorderOuter = fsFlatRounded
    FlatColor = clSkyBlue
    TabOrder = 2
    Color = 15987699
    ExplicitLeft = 5
    ExplicitTop = 998
    ExplicitWidth = 229
    object mmDescription: TRzMemo
      AlignWithMargins = True
      Left = 5
      Top = 5
      Width = 223
      Height = 72
      Align = alClient
      BevelInner = bvNone
      BevelOuter = bvNone
      BorderStyle = bsNone
      Color = clBtnFace
      ReadOnly = True
      TabOrder = 0
      StyleName = 'Windows'
      FrameHotColor = cl3DDkShadow
      FrameHotStyle = fsNone
      FrameVisible = True
      ReadOnlyColor = clBtnFace
    end
  end
  object vliProject: TVirtualImageList
    Images = <
      item
        CollectionIndex = 0
        CollectionName = 'Project\01_New'
        Name = '01_New'
      end
      item
        CollectionIndex = 1
        CollectionName = 'Project\02_OpenProject'
        Name = '02_OpenProject'
      end
      item
        CollectionIndex = 2
        CollectionName = 'Project\03_Reopen'
        Name = '03_Reopen'
      end
      item
        CollectionIndex = 3
        CollectionName = 'Project\04_Save'
        Name = '04_Save'
      end
      item
        CollectionIndex = 4
        CollectionName = 'Project\05_Print'
        Name = '05_Print'
      end
      item
        CollectionIndex = 5
        CollectionName = 'Project\06_AddModel'
        Name = '06_AddModel'
      end
      item
        CollectionIndex = 6
        CollectionName = 'Project\07_Export'
        Name = '07_Export'
      end
      item
        CollectionIndex = 7
        CollectionName = 'Project\08_Copy'
        Name = '08_Copy'
      end
      item
        CollectionIndex = 8
        CollectionName = 'Project\09_Paste'
        Name = '09_Paste'
      end
      item
        CollectionIndex = 9
        CollectionName = 'Project\10_Edit'
        Name = '10_Edit'
      end
      item
        CollectionIndex = 10
        CollectionName = 'Project\11_AddExtension'
        Name = '11_AddExtension'
      end
      item
        CollectionIndex = 11
        CollectionName = 'Project\12_DeleteExtension'
        Name = '12_DeleteExtension'
      end>
    Left = 120
    Top = 540
  end
  object pmProject: TPopupMenu
    OnPopup = pmProjectPopup
    Left = 32
    Top = 408
    object pmiEnabled: TMenuItem
      AutoCheck = True
      Caption = 'Enabled'
      ShortCut = 114
      OnClick = pmiEnabledClick
    end
    object pmiVisible: TMenuItem
      AutoCheck = True
      Caption = 'Visible'
      OnClick = pmiVisibleClick
    end
    object pmiLinked: TMenuItem
      AutoCheck = True
      Caption = 'Linked'
      OnClick = pmiLinkedClick
    end
    object pmiNorm: TMenuItem
      Caption = 'Normalize'
      object Auto1: TMenuItem
      end
      object Manual1: TMenuItem
      end
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Properties1: TMenuItem
    end
    object N5: TMenuItem
      Caption = '-'
    end
    object pmCopytoclipboard: TMenuItem
      Caption = 'Copy data'
    end
    object pmExporttofile: TMenuItem
      Caption = 'Export Data'
    end
  end
  object dlgOpenProject: TOpenDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project|*.xrcx'
    Title = 'Load project'
    Left = 168
    Top = 180
  end
  object dlgSaveProject: TSaveDialog
    DefaultExt = 'xrcx'
    Filter = 'X-Ray Calc project|*.xrcx'
    Options = [ofOverwritePrompt, ofHideReadOnly, ofEnableSizing]
    Title = 'Save project'
    Left = 168
    Top = 212
  end
  object dlgLoadData: TOpenDialog
    DefaultExt = 'dat'
    Filter = 'ASCII data|*.txt;*.csv;*.tet|Counter files|*.dat|All files|*.*'
    Title = 'Load curve from file'
    Left = 208
    Top = 176
  end
  object Zip: TAbZipper
    AutoSave = False
    DOSMode = False
    Left = 189
    Top = 299
  end
  object UnZip: TAbUnZipper
    Left = 169
    Top = 299
  end
end
