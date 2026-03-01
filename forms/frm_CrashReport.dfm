object frmCrashReport: TfrmCrashReport
  Left = 0
  Top = 0
  BorderStyle = bsDialog
  Caption = 'X-Ray Calc 3 - Unexpected Error'
  ClientHeight = 450
  ClientWidth = 600
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Segoe UI'
  Font.Style = []
  Position = poScreenCenter
  DesignSize = (
    600
    450)
  PixelsPerInch = 96
  TextHeight = 15
  object pnlTop: TPanel
    Left = 0
    Top = 0
    Width = 600
    Height = 65
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 0
    object lblTitle: TLabel
      Left = 16
      Top = 12
      Width = 250
      Height = 17
      Caption = 'An unexpected error has occurred'
      Font.Charset = DEFAULT_CHARSET
      Font.Color = clWindowText
      Font.Height = -13
      Font.Name = 'Segoe UI'
      Font.Style = [fsBold]
      ParentFont = False
    end
    object lblInfo: TLabel
      Left = 16
      Top = 38
      Width = 500
      Height = 15
      Caption =
        'The error details are shown below. Please copy and send this rep' +
        'ort to the developer.'
    end
  end
  object mmoReport: TMemo
    Left = 8
    Top = 73
    Width = 584
    Height = 330
    Anchors = [akLeft, akTop, akRight, akBottom]
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = 'Consolas'
    Font.Style = []
    ParentFont = False
    ReadOnly = True
    ScrollBars = ssBoth
    TabOrder = 1
    WordWrap = False
  end
  object pnlButtons: TPanel
    Left = 0
    Top = 409
    Width = 600
    Height = 41
    Align = alBottom
    BevelOuter = bvNone
    TabOrder = 2
    object btnCopy: TButton
      Left = 400
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Copy Report'
      TabOrder = 0
      OnClick = btnCopyClick
    end
    object btnClose: TButton
      Left = 500
      Top = 8
      Width = 90
      Height = 25
      Caption = 'Close'
      Default = True
      TabOrder = 1
      OnClick = btnCloseClick
    end
  end
end
