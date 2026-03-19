object frmXRFCalcMain: TfrmXRFCalcMain
  Left = 0
  Top = 0
  Caption = 'XRFCalc'
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
    Height = 56
    ButtonHeight = 54
    ButtonWidth = 91
    Images = ToolBarImages
    ParentShowHint = False
    ShowCaptions = True
    ShowHint = True
    TabOrder = 0
    object btnOpen: TToolButton
      Left = 0
      Top = 0
      Hint = 'Open .xrfx file'
      Caption = 'Open'
      ImageIndex = 0
      OnClick = btnOpenClick
    end
    object tbSep0: TToolButton
      Left = 91
      Top = 0
      Width = 8
      Style = tbsSeparator
    end
    object btnExportStructure: TToolButton
      Left = 99
      Top = 0
      Hint = 'Export best structure to JSON'
      Caption = 'Export Structure'
      ImageIndex = 1
      OnClick = btnExportStructureClick
    end
    object btnCopyData: TToolButton
      Left = 190
      Top = 0
      Hint = 'Copy curve data to clipboard'
      Caption = 'Copy Data'
      ImageIndex = 2
      OnClick = btnCopyDataClick
    end
    object btnSaveImage: TToolButton
      Left = 281
      Top = 0
      Hint = 'Save chart as image'
      Caption = 'Save Image'
      ImageIndex = 3
      OnClick = btnSaveImageClick
    end
    object tbSep1: TToolButton
      Left = 372
      Top = 0
      Width = 8
      Style = tbsSeparator
    end
    object btnNewRun: TToolButton
      Left = 380
      Top = 0
      Hint = 'Configure and start a new optimization run'
      Caption = 'New Run'
      ImageIndex = 4
      OnClick = btnNewRunClick
    end
    object tbSep2: TToolButton
      Left = 471
      Top = 0
      Width = 8
      Style = tbsSeparator
    end
    object btnStop: TToolButton
      Left = 479
      Top = 0
      Hint = 'Cancel the running optimization'
      Caption = 'Stop'
      ImageIndex = 5
      Visible = False
      OnClick = btnStopClick
    end
  end
  object MainSplitter: TRzSplitter
    Left = 0
    Top = 56
    Width = 1000
    Height = 524
    Position = 300
    Percent = 30
    UpperLeft.Color = 15987699
    LowerRight.Color = 15987699
    Align = alClient
    Color = 15987699
    TabOrder = 1
    BarSize = (
      300
      0
      304
      524)
    UpperLeftControls = ()
    LowerRightControls = (
      PageControl1)
    object PageControl1: TRzPageControl
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 690
      Height = 518
      Hint = ''
      ActivePage = tabCurves
      Align = alClient
      TabIndex = 0
      TabOrder = 0
      FixedDimension = 21
      object tabCurves: TRzTabSheet
        Color = 15987699
        Caption = 'Curves'
      end
      object tabInfo: TRzTabSheet
        Color = 15987699
        Caption = 'Info'
      end
      object tabProgress: TRzTabSheet
        Color = 15987699
        Caption = 'Progress'
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
    TabOrder = 2
    object spStatus: TRzStatusPane
      Left = 0
      Top = 0
      Width = 1000
      Align = alClient
      AutoSize = True
      Caption = ''
      ExplicitWidth = 40
    end
  end
  object MainMenu1: TMainMenu
    Left = 456
    Top = 280
    object mnuFile: TMenuItem
      Caption = '&File'
      object mnuOpen: TMenuItem
        Caption = '&Open...'
        ShortCut = 16463
        OnClick = mnuOpenClick
      end
      object mnuSave: TMenuItem
        Caption = '&Save'
        ShortCut = 16467
        OnClick = mnuSaveClick
      end
      object mnuSaveAs: TMenuItem
        Caption = 'Save &As...'
        ShortCut = 49235
        OnClick = mnuSaveAsClick
      end
      object mnuSaveConfig: TMenuItem
        Caption = 'Save Config...'
        OnClick = mnuSaveConfigClick
      end
      object mnuFileSep1: TMenuItem
        Caption = '-'
      end
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
    object mnuHelp: TMenuItem
      Caption = '&Help'
      object mnuHelpContents: TMenuItem
        Caption = '&Contents'
        ShortCut = 112
        OnClick = mnuHelpContentsClick
      end
    end
  end
  object ToolBarImages: TImageList
    Height = 32
    Width = 32
    Left = 504
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
  object dlgOpen: TOpenDialog
    DefaultExt = 'xrfx'
    Filter = 'XRFX package|*.xrfx'
    Title = 'Open XRF Results'
    Left = 552
    Top = 328
  end
end
