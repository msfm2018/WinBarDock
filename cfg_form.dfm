object CfgForm: TCfgForm
  Left = 0
  Top = 0
  Caption = #37197#32622'  '
  ClientHeight = 631
  ClientWidth = 635
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -12
  Font.Name = #23435#20307
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 12
  object ValueListEditor1: TValueListEditor
    Left = 0
    Top = 0
    Width = 635
    Height = 514
    Hint = #21452#20987#21024#38500
    Align = alTop
    BorderStyle = bsNone
    Ctl3D = False
    DoubleBuffered = True
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -12
    Font.Name = #23435#20307
    Font.Style = []
    Options = [goFixedVertLine, goFixedHorzLine, goVertLine, goHorzLine, goRowSizing, goColSizing, goRowSelect, goThumbTracking]
    ParentCtl3D = False
    ParentDoubleBuffered = False
    ParentFont = False
    ParentShowHint = False
    ScrollBars = ssVertical
    ShowHint = True
    Strings.Strings = (
      '=')
    TabOrder = 0
    TitleCaptions.Strings = (
      #22270#29255#36335#24452
      #25991#20214#36335#24452)
    OnDblClick = ValueListEditor1DblClick
    ExplicitWidth = 631
    ColWidths = (
      285
      348)
  end
  object Button1: TButton
    Left = 546
    Top = 520
    Width = 86
    Height = 44
    Caption = #28155#21152
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -24
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object LabeledEdit1: TLabeledEdit
    Left = 88
    Top = 520
    Width = 458
    Height = 20
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 78
    EditLabel.Height = 20
    EditLabel.Caption = #22270#29255#36335#24452'(png)'
    LabelPosition = lpLeft
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Text = ''
    OnDblClick = LabeledEdit1DblClick
  end
  object LabeledEdit2: TLabeledEdit
    Left = 88
    Top = 544
    Width = 458
    Height = 20
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 48
    EditLabel.Height = 20
    EditLabel.Caption = #25991#20214#36335#24452
    LabelPosition = lpLeft
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    Text = ''
    OnDblClick = LabeledEdit2DblClick
  end
  object Button2: TButton
    Left = 534
    Top = 570
    Width = 98
    Height = 21
    Caption = #22270#26631#22823#23567#35774#23450
    TabOrder = 4
    Visible = False
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 535
    Top = 598
    Width = 97
    Height = 20
    Caption = #22270#26631#21021#22987#21270
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    Visible = False
    OnClick = Button3Click
  end
  object Edit1: TSpinEdit
    Left = 456
    Top = 570
    Width = 72
    Height = 21
    MaxValue = 168
    MinValue = 30
    TabOrder = 6
    Value = 64
    Visible = False
  end
  object CheckBox1: TCheckBox
    Left = 8
    Top = 572
    Width = 97
    Height = 17
    Caption = #21435#32972#26223
    TabOrder = 7
    Visible = False
    OnClick = CheckBox1Click
  end
end
