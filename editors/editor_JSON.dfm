object frmJsonEditor: TfrmJsonEditor
  Left = 0
  Top = 0
  Caption = 'Vew/Edit structure as text'
  ClientHeight = 669
  ClientWidth = 795
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  TextHeight = 15
  object rzstsbr1: TRzStatusBar
    Left = 0
    Top = 650
    Width = 795
    Height = 19
    BorderInner = fsNone
    BorderOuter = fsNone
    BorderSides = [sdLeft, sdTop, sdRight, sdBottom]
    BorderWidth = 0
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 649
    ExplicitWidth = 791
  end
  object Editor: TSynEdit
    Left = 0
    Top = 29
    Width = 795
    Height = 621
    Align = alClient
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    Font.Quality = fqClearTypeNatural
    PopupMenu = pmMain
    TabOrder = 1
    UseCodeFolding = False
    Gutter.Font.Charset = DEFAULT_CHARSET
    Gutter.Font.Color = clWindowText
    Gutter.Font.Height = -11
    Gutter.Font.Name = 'Consolas'
    Gutter.Font.Style = []
    Gutter.Bands = <
      item
        Kind = gbkMarks
        Width = 13
      end
      item
        Kind = gbkLineNumbers
      end
      item
        Kind = gbkFold
      end
      item
        Kind = gbkTrackChanges
      end
      item
        Kind = gbkMargin
        Width = 3
      end>
    Highlighter = SynJSONSyn
    Lines.Strings = (
      'Editor')
    SelectedColor.Alpha = 0.400000005960464500
    ExplicitWidth = 791
    ExplicitHeight = 620
  end
  object MainToolBar: TRzToolbar
    Left = 0
    Top = 0
    Width = 795
    Height = 29
    BorderInner = fsNone
    BorderOuter = fsGroove
    BorderSides = [sdTop]
    BorderWidth = 0
    Color = 15987699
    TabOrder = 2
    ExplicitWidth = 791
    ToolbarControls = (
      btnSave)
    object btnSave: TRzBitBtn
      Left = 4
      Top = 2
      ModalResult = 1
      Align = alRight
      Caption = 'Save'
      TabOrder = 0
    end
  end
  object pmMain: TPopupMenu
    Left = 376
    Top = 296
  end
  object SynExporterHTML: TSynExporterHTML
    Color = clWindow
    DefaultFilter = 'HTML Documents (*.htm;*.html)|*.htm;*.html'
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -13
    Font.Name = 'Consolas'
    Font.Style = []
    Title = 'Untitled'
    UseBackground = False
    Left = 200
    Top = 528
  end
  object SynJSONSyn: TSynJSONSyn
    Left = 328
    Top = 512
  end
end
