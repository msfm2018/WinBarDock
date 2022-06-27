object Form1: TForm1
  Left = 270
  Top = 15
  AlphaBlendValue = 180
  BorderStyle = bsNone
  ClientHeight = 118
  ClientWidth = 250
  Color = clBtnFace
  DoubleBuffered = True
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  GlassFrame.Enabled = True
  GlassFrame.SheetOfGlass = True
  PopupMenu = PopupMenu1
  Position = poDesigned
  Scaled = False
  OnDestroy = FormDestroy
  OnMouseDown = FormMouseDown
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 12
  object img_bg: TImage
    Left = 0
    Top = 0
    Width = 250
    Height = 118
    Align = alClient
    Stretch = True
    Transparent = True
    OnMouseDown = img_bgMouseDown
    ExplicitWidth = 267
    ExplicitHeight = 193
  end
  object PopupMenu1: TPopupMenu
    Left = 64
    Top = 16
    object action_set: TMenuItem
      Caption = #35774#32622
      OnClick = action_setClick
    end
    object action_bootom_panel: TMenuItem
      Caption = #24212#29992
      OnClick = action_bootom_panelClick
    end
    object action_set_acce: TMenuItem
      Caption = #28909#38190
      OnClick = action_set_acceClick
    end
    object action_terminate: TMenuItem
      Caption = #36864#20986#24212#29992
      OnClick = action_terminateClick
    end
  end
end
