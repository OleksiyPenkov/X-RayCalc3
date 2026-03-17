object frmXRFViewMain: TfrmXRFViewMain
  Left = 0
  Top = 0
  Caption = 'XRFView'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Menu = MainMenu1
  Position = poScreenCenter
  OnClose = FormClose
  OnCreate = FormCreate
  OnDestroy = FormDestroy
  TextHeight = 15
  object ToolBar1: TToolBar
    Left = 0
    Top = 0
    Width = 1000
    Height = 29
    Images = ToolBarImages
    TabOrder = 0
    object btnRefresh: TToolButton
      Left = 0
      Top = 0
      Caption = 'Refresh'
      OnClick = btnRefreshClick
    end
    object btnExportStructure: TToolButton
      Left = 23
      Top = 0
      Caption = 'Export Structure'
      OnClick = btnExportStructureClick
    end
    object btnCopyData: TToolButton
      Left = 46
      Top = 0
      Caption = 'Copy Data'
      OnClick = btnCopyDataClick
    end
    object btnSaveImage: TToolButton
      Left = 69
      Top = 0
      Caption = 'Save Image'
      OnClick = btnSaveImageClick
    end
  end
  object MainSplitter: TRzSplitter
    Left = 0
    Top = 29
    Width = 1000
    Height = 551
    Position = 300
    Percent = 30
    UpperLeft.Color = clBtnFace
    LowerRight.Color = clBtnFace
    Align = alClient
    TabOrder = 1
    BarSize = (
      300
      0
      304
      551)
    UpperLeftControls = (
      ShellSplitter)
    LowerRightControls = (
      PageControl1)
    object ShellSplitter: TRzSplitter
      Left = 0
      Top = 0
      Width = 300
      Height = 551
      Orientation = orVertical
      Position = 220
      Percent = 40
      UsePercent = True
      UpperLeft.Color = clBtnFace
      LowerRight.Color = clBtnFace
      Align = alClient
      TabOrder = 0
      BarSize = (
        0
        220
        300
        224)
      UpperLeftControls = (
        JamShellBreadCrumbBar1
        ShellTree)
      LowerRightControls = (
        ShellList)
      object JamShellBreadCrumbBar1: TJamShellBreadCrumbBar
        Left = 0
        Top = 0
        Width = 300
        Height = 26
        Align = alTop
        ShellLink = JamShellLink1
      end
      object ShellTree: TJamShellTree
        Left = 0
        Top = 26
        Width = 300
        Height = 194
        Align = alClient
        ShellLink = JamShellLink1
      end
      object ShellList: TJamShellList
        Left = 0
        Top = 224
        Width = 300
        Height = 327
        Align = alClient
        ShellLink = JamShellLink1
        Filter = '*.xrfx'
        MultiSelect = True
        ReadOnly = True
        ViewStyle = vsReport
        OnSelectItem = ShellListSelectItem
      end
    end
    object PageControl1: TPageControl
      Left = 0
      Top = 0
      Width = 696
      Height = 551
      ActivePage = tabStructure
      Align = alClient
      TabOrder = 0
      object tabStructure: TTabSheet
        Caption = 'Structure'
      end
      object tabCurves: TTabSheet
        Caption = 'Curves'
        ImageIndex = 1
      end
      object tabInfo: TTabSheet
        Caption = 'Info'
        ImageIndex = 2
      end
      object tabProgress: TTabSheet
        Caption = 'Progress'
        ImageIndex = 3
      end
      object tabCompare: TTabSheet
        Caption = 'Compare'
        ImageIndex = 4
        TabVisible = False
      end
    end
  end
  object StatusBar: TRzStatusBar
    Left = 0
    Top = 580
    Width = 1000
    Height = 20
    BorderInner = fsNone
    BorderOuter = fsNone
    BorderSides = [sdLeft, sdTop, sdRight, sdBottom]
    BorderWidth = 0
    object spStatus: TRzStatusPane
      Left = 0
      Top = 0
      Width = 1000
      Height = 20
      Align = alClient
      AutoSize = True
      Caption = ''
    end
  end
  object MainMenu1: TMainMenu
    Left = 456
    Top = 280
    object mnuFile: TMenuItem
      Caption = '&File'
      object mnuExit: TMenuItem
        Caption = 'E&xit'
        OnClick = mnuExitClick
      end
    end
    object mnuView: TMenuItem
      Caption = '&View'
    end
    object mnuTools: TMenuItem
      Caption = '&Tools'
      object mnuRegisterExt: TMenuItem
        Caption = 'Register .xrfx extension'
        OnClick = mnuRegisterExtClick
      end
    end
  end
  object ToolBarImages: TImageList
    Left = 504
    Top = 280
  end
  object JamShellLink1: TJamShellLink
    Left = 552
    Top = 280
  end
  object dlgSave: TSaveDialog
    Left = 456
    Top = 328
  end
  object dlgSaveImage: TSavePictureDialog
    Left = 504
    Top = 328
  end
end
