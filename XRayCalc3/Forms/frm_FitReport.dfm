object frmFitReport: TfrmFitReport
  Left = 0
  Top = 0
  BorderStyle = bsSizeable
  Caption = 'Fit report'
  ClientHeight = 800
  ClientWidth = 900
  Color = clBtnFace
  Constraints.MinHeight = 560
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
    Width = 894
    Height = 50
    Align = alTop
    BorderOuter = fsFlatRounded
    TabOrder = 0
    object lblSource: TLabel
      Left = 10
      Top = 7
      Width = 872
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Source'
      EllipsisPosition = epEndEllipsis
    end
    object lblFacts: TLabel
      Left = 10
      Top = 27
      Width = 872
      Height = 15
      Anchors = [akLeft, akTop, akRight]
      AutoSize = False
      Caption = 'Facts'
      EllipsisPosition = epEndEllipsis
    end
  end
  object grpOrders: TRzGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 59
    Width = 894
    Height = 192
    Align = alClient
    Caption = 'Bragg orders'
    TabOrder = 1
    object lvOrders: TRzListView
      AlignWithMargins = True
      Left = 4
      Top = 19
      Width = 886
      Height = 169
      Align = alClient
      Columns = <
        item
          Alignment = taRightJustify
          Caption = 'n'
          Width = 40
        end
        item
          Alignment = taRightJustify
          Caption = 'Angle meas (deg)'
          Width = 125
        end
        item
          Alignment = taRightJustify
          Caption = 'Angle calc (deg)'
          Width = 125
        end
        item
          Alignment = taRightJustify
          Caption = 'I meas'
          Width = 115
        end
        item
          Alignment = taRightJustify
          Caption = 'R calc'
          Width = 115
        end
        item
          Alignment = taRightJustify
          Caption = 'calc / meas'
          Width = 95
        end
        item
          Alignment = taCenter
          Caption = 'Visible'
          Width = 70
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object pnlMiddle: TRzPanel
    Left = 0
    Top = 254
    Width = 900
    Height = 150
    Align = alBottom
    BorderOuter = fsNone
    TabOrder = 2
    object grpEdge: TRzGroupBox
      AlignWithMargins = True
      Left = 3
      Top = 3
      Width = 470
      Height = 144
      Align = alLeft
      Caption = 'Critical edge'
      TabOrder = 0
      object lvEdge: TRzListView
        AlignWithMargins = True
        Left = 4
        Top = 19
        Width = 462
        Height = 121
        Align = alClient
        Columns = <
          item
            Alignment = taRightJustify
            Caption = 'Angle (deg)'
            Width = 110
          end
          item
            Alignment = taRightJustify
            Caption = 'I meas'
            Width = 115
          end
          item
            Alignment = taRightJustify
            Caption = 'R calc'
            Width = 115
          end
          item
            Alignment = taRightJustify
            Caption = 'calc / meas'
            Width = 95
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
    object grpFringes: TRzGroupBox
      AlignWithMargins = True
      Left = 479
      Top = 3
      Width = 418
      Height = 144
      Align = alClient
      Caption = 'Fringes between orders 1 and 2'
      TabOrder = 1
      object lvFringes: TRzListView
        AlignWithMargins = True
        Left = 4
        Top = 19
        Width = 410
        Height = 121
        Align = alClient
        Columns = <
          item
            Caption = 'Quantity'
            Width = 230
          end
          item
            Alignment = taRightJustify
            Caption = 'Value'
            Width = 150
          end>
        ReadOnly = True
        RowSelect = True
        TabOrder = 0
        ViewStyle = vsReport
      end
    end
  end
  object grpBands: TRzGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 407
    Width = 894
    Height = 200
    Align = alBottom
    Caption = 'Residual by band: log10(R calc / I meas)'
    TabOrder = 3
    object lvBands: TRzListView
      AlignWithMargins = True
      Left = 4
      Top = 19
      Width = 886
      Height = 177
      Align = alClient
      Columns = <
        item
          Alignment = taRightJustify
          Caption = 'From (deg)'
          Width = 110
        end
        item
          Alignment = taRightJustify
          Caption = 'To (deg)'
          Width = 110
        end
        item
          Alignment = taRightJustify
          Caption = 'n'
          Width = 60
        end
        item
          Alignment = taRightJustify
          Caption = 'Mean'
          Width = 110
        end
        item
          Alignment = taRightJustify
          Caption = 'RMS'
          Width = 110
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object grpNear: TRzGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 613
    Width = 894
    Height = 140
    Align = alBottom
    Caption = 'Parameters within 5 % of a bound'
    TabOrder = 4
    object lvNear: TRzListView
      AlignWithMargins = True
      Left = 4
      Top = 19
      Width = 886
      Height = 117
      Align = alClient
      Columns = <
        item
          Caption = 'Stack'
          Width = 140
        end
        item
          Caption = 'Layer'
          Width = 110
        end
        item
          Caption = 'Parameter'
          Width = 90
        end
        item
          Alignment = taRightJustify
          Caption = 'Value'
          Width = 95
        end
        item
          Alignment = taRightJustify
          Caption = 'Min'
          Width = 95
        end
        item
          Alignment = taRightJustify
          Caption = 'Max'
          Width = 95
        end
        item
          Alignment = taCenter
          Caption = 'Near'
          Width = 70
        end>
      ReadOnly = True
      RowSelect = True
      TabOrder = 0
      ViewStyle = vsReport
    end
  end
  object pnlButtons: TRzPanel
    Left = 0
    Top = 756
    Width = 900
    Height = 44
    Align = alBottom
    BorderOuter = fsNone
    TabOrder = 5
    object btnCopy: TRzBitBtn
      Left = 6
      Top = 8
      Width = 150
      Height = 27
      Hint = 'Copy every table of the report to the clipboard as text'
      Caption = 'Copy as text'
      ParentShowHint = False
      ShowHint = True
      TabOrder = 0
      OnClick = btnCopyClick
      Margin = 4
      Spacing = 4
    end
    object btnClose: TRzBitBtn
      Left = 792
      Top = 8
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
