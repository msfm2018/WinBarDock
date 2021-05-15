object Form1: TForm1
  Left = 270
  Top = 15
  AlphaBlendValue = 180
  BorderStyle = bsNone
  ClientHeight = 119
  ClientWidth = 144
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.SheetOfGlass = True
  OldCreateOrder = False
  PopupMenu = PopupMenu1
  Position = poDesigned
  Scaled = False
  OnClose = FormClose
  OnDestroy = FormDestroy
  OnMouseDown = FormMouseDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  object img_bg: TImage
    Left = 0
    Top = 0
    Width = 144
    Height = 119
    Align = alClient
    Stretch = True
    Transparent = True
    OnMouseMove = img_bgMouseMove
    ExplicitLeft = 208
    ExplicitWidth = 976
    ExplicitHeight = 104
  end
  object PopupMenu1: TPopupMenu
    Left = 64
    Top = 16
    object N1: TMenuItem
      Caption = #35774#32622
      OnClick = N1Click
    end
    object N2: TMenuItem
      Caption = #24555#25463#24212#29992
      OnClick = N2Click
    end
    object exit1: TMenuItem
      Caption = 'exit'
      OnClick = exit1Click
    end
  end
  object Timer1: TTimer
    OnTimer = Timer1Timer
    Left = 104
    Top = 16
  end
end
