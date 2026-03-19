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
    UpperLeftControls = (
      FRunConfig)
    LowerRightControls = (
      PageControl1)
    inline FRunConfig: TfrmRunConfig
      Left = 0
      Top = 0
      Width = 300
      Height = 524
      Align = alClient
      TabOrder = 0
      ExplicitHeight = 524
      inherited PageControl: TRzPageControl
        Height = 524
        ExplicitHeight = 524
        FixedDimension = 21
        inherited tabTargets: TRzTabSheet
          Color = 15987699
          ExplicitHeight = 499
          inherited grpLines: TGroupBox
            Top = 175
            Height = 155
            Align = alClient
            ExplicitLeft = 10
            ExplicitTop = 3
            ExplicitWidth = 290
            inherited lvLines: TListView
              Left = 5
              Top = 20
              Width = 280
              Height = 104
              ExplicitLeft = 5
              ExplicitTop = 20
              ExplicitWidth = 280
              ExplicitHeight = 109
            end
            inherited pnlLineWeight: TPanel
              Left = 2
              Top = 127
              Width = 286
              StyleElements = [seFont, seClient, seBorder]
              ExplicitLeft = 2
              ExplicitTop = 132
              ExplicitWidth = 286
              inherited lblLineWeight: TLabel
                StyleElements = [seFont, seClient, seBorder]
              end
              inherited edtLineWeight: TEdit
                StyleElements = [seFont, seClient, seBorder]
              end
            end
          end
          inherited grpPool: TGroupBox
            Top = 3
            Height = 166
            ExplicitTop = 3
            ExplicitHeight = 166
            inherited clbPool: TCheckListBox
              Height = 141
              ItemHeight = 15
              StyleElements = [seFont, seClient, seBorder]
            end
          end
          inherited grpExcludedPairs: TGroupBox
            Top = 336
            Height = 160
            Align = alBottom
            ExplicitTop = 336
            ExplicitHeight = 160
            inherited clbExcludedPairs: TCheckListBox
              Height = 135
              ItemHeight = 15
              StyleElements = [seFont, seClient, seBorder]
            end
          end
        end
        inherited tabStructure: TRzTabSheet
          Color = 15987699
          ExplicitLeft = 1
          ExplicitTop = 22
          ExplicitWidth = 296
          ExplicitHeight = 475
          inherited lblDMin: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblDMax: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblGammaMin: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblGammaMax: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblNMin: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblNMax: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblSigma: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblDensityFactor: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblSubstrate: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited sedDMin: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedDMax: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedGammaMin: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedGammaMax: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedNMin: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedNMax: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited edtSigma: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtDensityFactor: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtSubstrate: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
        end
        inherited tabOptimizer: TRzTabSheet
          Color = 15987699
          ExplicitLeft = 1
          ExplicitTop = 22
          ExplicitWidth = 296
          ExplicitHeight = 475
          inherited lblPopulation: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblIterations: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblStagnation: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblW1: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblW2: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblTolerance: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblJammingMax: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblCheckpointEvery: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited sedPopulation: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedIterations: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedStagnation: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited edtW1: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtW2: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtTolerance: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited sedJammingMax: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited sedCheckpointEvery: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
        end
        inherited tabFitness: TRzTabSheet
          Color = 15987699
          ExplicitLeft = 1
          ExplicitTop = 22
          ExplicitWidth = 296
          ExplicitHeight = 475
          inherited lblWR: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblWFWHM: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblWPurity: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblRMinThreshold: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblDeltaTheta: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblThetaMin: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblPolarization: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblScanPoints: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited lblScanHalfRange: TLabel
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtWR: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtWFWHM: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtWPurity: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtRMinThreshold: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtDeltaTheta: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited edtThetaMin: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited cmbPolarization: TComboBox
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 23
          end
          inherited sedScanPoints: TSpinEdit
            Height = 24
            StyleElements = [seFont, seClient, seBorder]
            ExplicitHeight = 24
          end
          inherited edtScanHalfRange: TEdit
            StyleElements = [seFont, seClient, seBorder]
          end
          inherited grpHenke: TGroupBox
            inherited edtHenkePath: TEdit
              StyleElements = [seFont, seClient, seBorder]
            end
          end
        end
      end
    end
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
      object mnuTemplateFile: TMenuItem
        Caption = 'Template File...'
        OnClick = mnuTemplateFileClick
      end
      object mnuXRFLinesFile: TMenuItem
        Caption = 'XRF Lines File...'
        OnClick = mnuXRFLinesFileClick
      end
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
