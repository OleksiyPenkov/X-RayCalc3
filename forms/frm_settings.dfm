object frmSettings: TfrmSettings
  Left = 0
  Top = 0
  HelpContext = 144
  BorderStyle = bsDialog
  Caption = 'Settings'
  ClientHeight = 431
  ClientWidth = 613
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnShow = FormShow
  TextHeight = 13
  object pcSetPages: TPageControl
    AlignWithMargins = True
    Left = 159
    Top = 3
    Width = 451
    Height = 384
    ActivePage = tsGraphics
    Align = alClient
    TabOrder = 1
    object tsPaths: TTabSheet
      HelpContext = 143
      Caption = 'tsPaths'
      TabVisible = False
      object lbl1: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'FIles and Paths'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 86
      end
    end
    object tsBehavour: TTabSheet
      Caption = 'tsBehavior'
      ImageIndex = 5
      TabVisible = False
      object Panel3: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 362
        Margins.Bottom = 9
        Align = alClient
        BevelOuter = bvNone
        ShowCaption = False
        TabOrder = 0
        object Label6: TLabel
          AlignWithMargins = True
          Left = 3
          Top = 3
          Width = 431
          Height = 13
          Align = alTop
          Caption = 'Behavior'
          Font.Charset = DEFAULT_CHARSET
          Font.Color = clWindowText
          Font.Height = -11
          Font.Name = 'Tahoma'
          Font.Style = [fsBold]
          ParentFont = False
          Transparent = True
          ExplicitWidth = 50
        end
        object chkCheckForUpdates: TCheckBox
          AlignWithMargins = True
          Left = 9
          Top = 45
          Width = 425
          Height = 17
          Margins.Left = 9
          Align = alTop
          Caption = 'Automatically check for updates'
          Color = clBtnFace
          ParentColor = False
          TabOrder = 0
          ExplicitTop = 22
        end
        object btnRegisterExtensions: TButton
          Left = 9
          Top = 320
          Width = 416
          Height = 25
          Caption = 'Register file associations (xrcx)'
          TabOrder = 1
          OnClick = btnRegisterExtensionsClick
        end
        object chkAutoClacOpen: TCheckBox
          AlignWithMargins = True
          Left = 9
          Top = 22
          Width = 425
          Height = 17
          Margins.Left = 9
          Align = alTop
          Caption = 'Automatically calculate when file is open'
          Color = clBtnFace
          ParentColor = False
          TabOrder = 2
        end
      end
    end
    object tsInterface: TTabSheet
      Caption = 'tsInterface'
      ImageIndex = 3
      TabVisible = False
      object Label3: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Interface settings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 102
      end
    end
    object tsCalc: TTabSheet
      Caption = 'Calc'
      ImageIndex = 3
      TabVisible = False
      object lbl2: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Calc settings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 72
      end
      object pnlCores: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 24
        Width = 437
        Height = 35
        Margins.Top = 5
        Align = alTop
        TabOrder = 0
        ExplicitTop = 22
        object Label1: TLabel
          Left = 8
          Top = 11
          Width = 137
          Height = 13
          Caption = 'Number od CPU cores to use'
        end
        object cbbCPUCores: TComboBox
          Left = 184
          Top = 8
          Width = 145
          Height = 21
          TabOrder = 0
          Text = 'All'
          Items.Strings = (
            'Auto'
            '2'
            '4'
            '8'
            '12'
            '16'
            '32'
            '64')
        end
      end
    end
    object tsGraphics: TTabSheet
      Caption = 'tsGraphics'
      ImageIndex = 4
      TabVisible = False
      object lbl3: TLabel
        AlignWithMargins = True
        Left = 3
        Top = 3
        Width = 437
        Height = 13
        Align = alTop
        Caption = 'Graphics settings'
        Font.Charset = DEFAULT_CHARSET
        Font.Color = clWindowText
        Font.Height = -11
        Font.Name = 'Tahoma'
        Font.Style = [fsBold]
        ParentFont = False
        Transparent = True
        ExplicitWidth = 98
      end
      object Panel1: TPanel
        AlignWithMargins = True
        Left = 3
        Top = 24
        Width = 437
        Height = 35
        Margins.Top = 5
        Align = alTop
        TabOrder = 0
        ExplicitLeft = 6
        ExplicitTop = 32
        object Label2: TLabel
          Left = 8
          Top = 11
          Width = 83
          Height = 13
          Caption = 'Default line width'
        end
        object seLineWidth: TSpinEdit
          Left = 98
          Top = 6
          Width = 90
          Height = 22
          MaxValue = 10
          MinValue = 1
          TabOrder = 0
          Value = 2
        end
      end
    end
  end
  object pnButtons: TPanel
    Left = 0
    Top = 390
    Width = 613
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    Caption = 'pnButtons'
    ShowCaption = False
    TabOrder = 2
    ExplicitTop = 389
    ExplicitWidth = 609
    DesignSize = (
      613
      41)
    object btnOk: TButton
      Left = 437
      Top = 10
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Caption = '&Save'
      Default = True
      ModalResult = 1
      TabOrder = 0
      OnClick = SaveSettingsClick
      ExplicitLeft = 433
    end
    object btnCancel: TButton
      Left = 518
      Top = 10
      Width = 75
      Height = 25
      Anchors = [akTop, akRight]
      Cancel = True
      Caption = '&Cancel'
      ModalResult = 2
      TabOrder = 1
      ExplicitLeft = 514
    end
    object btnHelp: TButton
      Left = 12
      Top = 10
      Width = 75
      Height = 25
      Caption = 'Help'
      TabOrder = 2
      OnClick = ShowHelpClick
    end
  end
  object tvSections: TTreeView
    AlignWithMargins = True
    Left = 3
    Top = 5
    Width = 150
    Height = 381
    Margins.Top = 5
    Margins.Bottom = 4
    Align = alLeft
    HideSelection = False
    Indent = 19
    RowSelect = True
    TabOrder = 0
    OnChange = tvSectionsChange
    Items.NodeData = {
      03050000003C0000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF000000
      0000000000010F50006100740068007300200061006E0064002000460069006C
      00650073002E0000000000000000000000FFFFFFFFFFFFFFFF00000000000000
      000000000001084200650068006100760069006F007200300000000000000000
      000000FFFFFFFFFFFFFFFF000000000000000000000000010949006E00740065
      0072006600610063006500260000000000000000000000FFFFFFFFFFFFFFFF00
      00000000000000000000000104430061006C0063002E00000000000000000000
      00FFFFFFFFFFFFFFFF0000000000000000000000000108470072006100700068
      00690063007300}
    ExplicitHeight = 380
  end
  object dlgColors: TColorDialog
    Left = 32
    Top = 176
  end
end
