object edtrProfileTable: TedtrProfileTable
  Left = 0
  Top = 0
  Caption = 'Table Editor'
  ClientHeight = 678
  ClientWidth = 977
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  OnCreate = FormCreate
  OnShow = FormShow
  TextHeight = 15
  object RzPanel2: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 634
    Width = 971
    Height = 41
    Align = alBottom
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 0
    ExplicitTop = 633
    ExplicitWidth = 967
    DesignSize = (
      971
      41)
    object btnOK: TRzBitBtn
      Left = 885
      Top = 10
      Width = 66
      Alignment = taRightJustify
      Anchors = [akTop, akRight]
      TabOrder = 0
      TabStop = False
      Kind = bkOK
      ExplicitLeft = 881
    end
    object btnCancel: TRzBitBtn
      Left = 9
      Top = 10
      Width = 72
      Alignment = taRightJustify
      TabOrder = 1
      TabStop = False
      Kind = bkCancel
    end
  end
  object RzPanel1: TRzPanel
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 971
    Height = 46
    Align = alTop
    BorderOuter = fsFlatRounded
    Color = 15987699
    TabOrder = 1
    ExplicitWidth = 967
    object btnSave: TRzBitBtn
      Left = 113
      Top = 10
      Caption = 'Save'
      TabOrder = 0
      OnClick = btnSaveClick
    end
    object btnCopy: TRzBitBtn
      Left = 9
      Top = 10
      Caption = 'Copy'
      TabOrder = 1
      OnClick = btnCopyClick
    end
  end
  object Pages: TRzPageControl
    Left = 0
    Top = 52
    Width = 977
    Height = 579
    Hint = ''
    ActivePage = tsThickness
    Align = alClient
    TabIndex = 0
    TabOrder = 2
    ExplicitWidth = 973
    ExplicitHeight = 578
    FixedDimension = 21
    object tsThickness: TRzTabSheet
      Caption = 'Thickness'
      ExplicitWidth = 969
      ExplicitHeight = 553
      object chrtThickness: TChart
        AlignWithMargins = True
        Left = 334
        Top = 3
        Width = 636
        Height = 548
        Cursor = crCross
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        LeftAxis.MaximumOffset = 20
        LeftAxis.MinimumOffset = 20
        View3D = False
        Align = alClient
        TabOrder = 0
        ExplicitLeft = 257
        ExplicitWidth = 709
        ExplicitHeight = 547
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
      object grdThickness: TXRCGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Height = 548
        Align = alLeft
        TabOrder = 1
        AutoFit = False
        Text = #9#9#9#9
        ExplicitLeft = 80
        ExplicitTop = 136
        ExplicitHeight = 125
      end
    end
    object tsRoughness: TRzTabSheet
      Caption = 'Roughness'
      object chrtRougness: TChart
        AlignWithMargins = True
        Left = 334
        Top = 3
        Width = 636
        Height = 548
        Cursor = crCross
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        LeftAxis.MaximumOffset = 20
        LeftAxis.MinimumOffset = 20
        View3D = False
        Align = alClient
        TabOrder = 0
        ExplicitLeft = 257
        ExplicitWidth = 713
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
      object grdRoughness: TXRCGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Height = 548
        Align = alLeft
        TabOrder = 1
        AutoFit = False
        Text = #9#9#9#9
        ExplicitLeft = 11
        ExplicitTop = 6
      end
    end
    object tsDensity: TRzTabSheet
      Caption = 'Density'
      object chrtDensity: TChart
        AlignWithMargins = True
        Left = 334
        Top = 3
        Width = 636
        Height = 548
        Cursor = crCross
        Title.Text.Strings = (
          'TChart')
        Title.Visible = False
        LeftAxis.MaximumOffset = 20
        LeftAxis.MinimumOffset = 20
        View3D = False
        Align = alClient
        TabOrder = 0
        ExplicitLeft = 257
        ExplicitWidth = 713
        DefaultCanvas = 'TGDIPlusCanvas'
        ColorPaletteIndex = 13
      end
      object grdDensity: TXRCGrid
        AlignWithMargins = True
        Left = 3
        Top = 3
        Height = 548
        Align = alLeft
        TabOrder = 1
        AutoFit = False
        Text = #9#9#9#9
        ExplicitLeft = 11
        ExplicitTop = 6
      end
    end
  end
  object dlgSaveResult: TSaveDialog
    DefaultExt = 'dat'
    Filter = 'ASCII data|*.dat|ASCII Text|*.txt'
    Title = 'Save result to file'
    Left = 416
    Top = 408
  end
end
