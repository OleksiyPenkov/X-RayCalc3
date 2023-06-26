object frmNewMaterial: TfrmNewMaterial
  Left = 0
  Top = 0
  BorderStyle = bsToolWindow
  Caption = 'New Material'
  ClientHeight = 366
  ClientWidth = 284
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -11
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poMainFormCenter
  OnCreate = FormCreate
  TextHeight = 13
  object RzGroupBox1: TRzGroupBox
    AlignWithMargins = True
    Left = 3
    Top = 3
    Width = 278
    Height = 360
    Align = alClient
    Color = 15987699
    TabOrder = 0
    ExplicitLeft = 0
    ExplicitTop = 0
    ExplicitWidth = 295
    ExplicitHeight = 361
    object Label3: TLabel
      Left = 115
      Top = 55
      Width = 100
      Height = 13
      Caption = 'Number of elements:'
    end
    object Label2: TLabel
      Left = 121
      Top = 27
      Width = 72
      Height = 13
      Caption = 'Density, g/cm3'
    end
    object Label1: TLabel
      Left = 8
      Top = 27
      Width = 27
      Height = 13
      Caption = 'Name'
    end
    object StringGrid1: TStringGrid
      Left = 8
      Top = 79
      Width = 265
      Height = 240
      ColCount = 2
      DefaultColWidth = 120
      DefaultRowHeight = 20
      FixedCols = 0
      RowCount = 2
      Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRangeSelect, goEditing]
      TabOrder = 0
    end
    object bntSave: TButton
      Left = 100
      Top = 331
      Width = 75
      Height = 25
      Caption = 'Save'
      TabOrder = 1
      OnClick = bntSaveClick
    end
    object SpinEdit1: TSpinEdit
      Left = 224
      Top = 51
      Width = 49
      Height = 22
      MaxValue = 10
      MinValue = 1
      TabOrder = 2
      Value = 1
      OnChange = SpinEdit1Change
    end
    object Edit1: TEdit
      Left = 41
      Top = 24
      Width = 74
      Height = 21
      TabOrder = 3
    end
    object Edit2: TEdit
      Left = 202
      Top = 24
      Width = 71
      Height = 21
      TabOrder = 4
    end
    object btnClear: TButton
      Left = 8
      Top = 331
      Width = 75
      Height = 25
      Caption = 'Clear'
      TabOrder = 5
      OnClick = btnClearClick
    end
    object btnClose: TButton
      Left = 200
      Top = 331
      Width = 75
      Height = 25
      Caption = 'Close'
      ModalResult = 8
      TabOrder = 6
    end
  end
  object PopupMenu1: TPopupMenu
    Left = 104
    Top = 272
    object Inserttothetable1: TMenuItem
      Caption = 'Insert to the table'
      ShortCut = 13
      OnClick = lbFilesDblClick
    end
    object N1: TMenuItem
      Caption = '-'
    end
    object Deletefile1: TMenuItem
      Caption = 'Delete file'
    end
  end
end
