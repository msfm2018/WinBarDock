object mycfg: Tmycfg
  Left = 0
  Top = 0
  Caption = #36335#24452#37197#32622
  ClientHeight = 631
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = DEFAULT_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = 'Tahoma'
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  PixelsPerInch = 96
  TextHeight = 14
  object ValueListEditor1: TValueListEditor
    Left = 0
    Top = 0
    Width = 635
    Height = 514
    Align = alTop
    BorderStyle = bsNone
    Ctl3D = False
    DoubleBuffered = True
    Font.Charset = DEFAULT_CHARSET
    Font.Color = clWindowText
    Font.Height = -14
    Font.Name = 'Tahoma'
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goColSizing, goEditing, goThumbTracking]
    ParentCtl3D = False
    ParentDoubleBuffered = False
    ParentFont = False
    ScrollBars = ssVertical
    Strings.Strings = (
      '=')
    TabOrder = 0
    TitleCaptions.Strings = (
      #22270#29255#36335#24452
      #25991#20214#36335#24452)
    OnDblClick = ValueListEditor1DblClick
    ColWidths = (
      285
      348)
  end
  object Button1: TButton
    Left = 248
    Top = 593
    Width = 145
    Height = 37
    Caption = #28155#21152
    TabOrder = 1
    OnClick = Button1Click
  end
  object LabeledEdit1: TLabeledEdit
    Left = 88
    Top = 520
    Width = 458
    Height = 22
    EditLabel.Width = 79
    EditLabel.Height = 14
    EditLabel.Caption = #22270#29255#36335#24452'(png)'
    LabelPosition = lpLeft
    TabOrder = 2
    Text = ''
    OnDblClick = LabeledEdit1DblClick
  end
  object LabeledEdit2: TLabeledEdit
    Left = 88
    Top = 558
    Width = 458
    Height = 22
    EditLabel.Width = 48
    EditLabel.Height = 14
    EditLabel.Caption = #25991#20214#36335#24452
    LabelPosition = lpLeft
    TabOrder = 3
    Text = ''
    OnDblClick = LabeledEdit2DblClick
  end
  object BitBtn1: TBitBtn
    Left = 552
    Top = 519
    Width = 75
    Height = 24
    Caption = '...'
    TabOrder = 4
    OnClick = BitBtn1Click
  end
  object BitBtn2: TBitBtn
    Left = 552
    Top = 557
    Width = 75
    Height = 24
    Caption = '...'
    TabOrder = 5
    OnClick = BitBtn2Click
  end
end
