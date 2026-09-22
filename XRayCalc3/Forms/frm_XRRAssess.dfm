object frmXRRAssess: TfrmXRRAssess
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'XRR quality'
  ClientHeight = 620
  ClientWidth = 1000
  Color = clBtnFace
  Constraints.MinHeight = 420
  Constraints.MinWidth = 760
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poMainFormCenter
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 994
    Height = 90
    Align = alTop
    BorderOuter = fsFlatRounded
    TabOrder = 0
    object lblSource: TLabel
      Left = 10
      Top = 8
      Width = 972
      Height = 15
      AutoSize = False
      Caption = 'Source'
      EllipsisPosition = epPathEllipsis
    end
    object lblDetector: TLabel
      Left = 10
      Top = 32
      Width = 98
      Height = 15
      Caption = 'Detector max, cps'
    end
    object edDetector: TEdit
      Left = 10
      Top = 50
      Width = 110
      Height = 23
      Hint = 'The detector'#39's linear count-rate limit; empty = unknown'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
    end
    object lblSample: TLabel
      Left = 130
      Top = 32
      Width = 99
      Height = 15
      Caption = 'Sample length, mm'
    end
    object edSample: TEdit
      Left = 130
      Top = 50
      Width = 90
      Height = 23
      Hint = 'The specimen'#39's length along the beam; empty = unknown'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 1
    end
    object lblBeam: TLabel
      Left = 230
      Top = 32
      Width = 86
      Height = 15
      Caption = 'Beam width, mm'
    end
    object edBeam: TEdit
      Left = 230
      Top = 50
      Width = 90
      Height = 23
      Hint = 'The incident beam'#39's width; empty = unknown'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 2
    end
    object lblResolution: TLabel
      Left = 330
      Top = 32
      Width = 84
      Height = 15
      Caption = 'Resolution, deg'
    end
    object edResolution: TEdit
      Left = 330
      Top = 50
      Width = 80
      Height = 23
      Hint = 'Theta FWHM the design is convolved with (the calculation settings'#39' value)'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      Text = '0.015'
    end
    object lblVisible: TLabel
      Left = 420
      Top = 32
      Width = 72
      Height = 15
      Caption = 'Visible factor'
    end
    object edVisible: TEdit
      Left = 420
      Top = 50
      Width = 70
      Height = 23
      Hint = 'An order is visible this many times above the background'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      Text = '3'
    end
    object lblMinPoints: TLabel
      Left = 500
      Top = 32
      Width = 82
      Height = 15
      Caption = 'Min pts / fringe'
    end
    object edMinPoints: TEdit
      Left = 500
      Top = 50
      Width = 70
      Height = 23
      Hint = 'The sampling check warns below this many points per Kiessig fringe'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 5
      Text = '3'
    end
    object chkStructure: TCheckBox
      Left = 590
      Top = 52
      Width = 230
      Height = 19
      Hint = 'Read the period, the thickness and the critical angle from the structure editor, and compare with its model'
      Caption = 'Use the current structure as the design'
      Checked = True
      ParentShowHint = False
      ShowHint = True
      State = cbChecked
      TabOrder = 6
    end
    object btnAssess: TRzBitBtn
      Left = 880
      Top = 48
      Width = 100
      Height = 27
      Anchors = [akTop, akRight]
      Caption = 'Assess'
      Default = True
      TabOrder = 7
      OnClick = btnAssessClick
      Margin = 4
      Spacing = 4
    end
  end
  object lvChecks: TRzListView
    AlignWithMargins = True
    Left = 3
    Top = 99
    Width = 994
    Height = 344
    Align = alClient
    Columns = <
      item
        Caption = 'Check'
        Width = 170
      end
      item
        Alignment = taCenter
        Caption = 'Verdict'
        Width = 70
      end
      item
        Alignment = taRightJustify
        Caption = 'Value'
        Width = 100
      end
      item
        Alignment = taRightJustify
        Caption = 'Threshold'
        Width = 100
      end
      item
        Caption = 'Why'
        Width = 530
      end>
    ReadOnly = True
    RowSelect = True
    TabOrder = 1
    ViewStyle = vsReport
    OnCustomDrawItem = lvChecksCustomDrawItem
  end
  object pnlBottom: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 449
    Width = 994
    Height = 168
    Align = alBottom
    BorderOuter = fsFlatRounded
    TabOrder = 2
    object mmSummary: TMemo
      AlignWithMargins = True
      Left = 4
      Top = 4
      Width = 986
      Height = 122
      Align = alClient
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -12
      Font.Name = 'Consolas'
      Font.Style = []
      ParentFont = False
      ReadOnly = True
      ScrollBars = ssVertical
      TabOrder = 0
      WordWrap = True
    end
    object pnlButtons: TRzPanel
      Left = 1
      Top = 129
      Width = 992
      Height = 38
      Align = alBottom
      BorderOuter = fsNone
      TabOrder = 1
      object btnCopy: TRzBitBtn
        Left = 6
        Top = 6
        Width = 150
        Height = 27
        Hint = 'Copy the text block to the clipboard, ready for the specimen'#39's record'
        Caption = 'Copy summary'
        ParentShowHint = False
        ShowHint = True
        TabOrder = 0
        OnClick = btnCopyClick
        Margin = 4
        Spacing = 4
      end
      object btnClose: TRzBitBtn
        Left = 886
        Top = 6
        Width = 100
        Height = 27
        Anchors = [akTop, akRight]
        Cancel = True
        ModalResult = 2
        Caption = 'Close'
        TabOrder = 1
        Margin = 4
        Spacing = 4
      end
    end
  end
end
