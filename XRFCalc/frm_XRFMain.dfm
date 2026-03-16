object frmXRFMain: TfrmXRFMain
  Left = 0
  Top = 0
  Caption = 'XRFCalc - Universal Mirror Optimizer'
  ClientHeight = 600
  ClientWidth = 1000
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  PixelsPerInch = 96
  TextHeight = 15
  object splMain: TSplitter
    Left = 280
    Top = 0
    Width = 5
    Height = 600
  end
  object pnlSidebar: TPanel
    Left = 0
    Top = 0
    Width = 280
    Height = 600
    Align = alLeft
    BevelOuter = bvNone
    TabOrder = 0
    object sbConfig: TScrollBox
      Left = 0
      Top = 0
      Width = 280
      Height = 560
      Align = alClient
      BorderStyle = bsNone
      TabOrder = 0
    end
    object pnlButtons: TPanel
      Left = 0
      Top = 560
      Width = 280
      Height = 40
      Align = alBottom
      BevelOuter = bvNone
      TabOrder = 1
    end
  end
  object pnlCharts: TPanel
    Left = 285
    Top = 0
    Width = 715
    Height = 600
    Align = alClient
    BevelOuter = bvNone
    TabOrder = 1
  end
end
