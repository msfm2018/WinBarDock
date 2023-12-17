object CfgForm: TCfgForm
  Left = 0
  Top = 0
  Caption = #37197#32622'  '
  ClientHeight = 631
  ClientWidth = 894
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
  object Label1: TLabel
    Left = 440
    Top = 328
    Width = 36
    Height = 12
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 491
    Top = 552
    Width = 48
    Height = 12
    Caption = #32972#26223#39068#33394
    Visible = False
  end
  object ValueListEditor1: TValueListEditor
    Left = 0
    Top = 0
    Width = 894
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
    ColWidths = (
      285
      607)
  end
  object Button1: TButton
    Left = 795
    Top = 520
    Width = 91
    Height = 70
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
    Left = 73
    Top = 520
    Width = 560
    Height = 20
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 60
    EditLabel.Height = 20
    EditLabel.Caption = #33258#23450#20041#22270#29255
    Enabled = False
    LabelPosition = lpLeft
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Text = ''
    OnDblClick = LabeledEdit1DblClick
  end
  object LabeledEdit2: TLabeledEdit
    Left = 73
    Top = 570
    Width = 560
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
    Left = 141
    Top = 599
    Width = 124
    Height = 27
    Caption = #33258#23450#20041#22270#26631#22823#23567
    TabOrder = 4
    OnClick = Button2Click
  end
  object Button3: TButton
    Left = 356
    Top = 603
    Width = 117
    Height = 20
    Caption = #36824#21407#22270#29255#23610#23544
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -16
    Font.Name = #23435#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 5
    OnClick = Button3Click
  end
  object Edit1: TSpinEdit
    Left = 71
    Top = 602
    Width = 72
    Height = 21
    MaxValue = 168
    MinValue = 30
    TabOrder = 6
    Value = 36
  end
  object CheckBox1: TCheckBox
    Left = -32
    Top = 606
    Width = 97
    Height = 17
    Caption = #21435#32972#26223
    TabOrder = 7
    Visible = False
    OnClick = CheckBox1Click
  end
  object LabeledEdit3: TLabeledEdit
    Left = 73
    Top = 546
    Width = 192
    Height = 20
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 48
    EditLabel.Height = 20
    EditLabel.Caption = #25551#36848#25991#23383
    LabelPosition = lpLeft
    ParentShowHint = False
    ShowHint = True
    TabOrder = 8
    Text = ''
    OnDblClick = LabeledEdit2DblClick
  end
  object RadioGroup1: TRadioGroup
    Left = 677
    Top = 520
    Width = 99
    Height = 70
    TabOrder = 9
  end
  object r1: TRadioButton
    Left = 696
    Top = 529
    Width = 65
    Height = 17
    Caption = #33258#23450#20041#22270#29255
    TabOrder = 10
    OnClick = r1Click
  end
  object r2: TRadioButton
    Left = 696
    Top = 552
    Width = 65
    Height = 17
    Caption = #25551#36848#25991#23383
    Checked = True
    TabOrder = 11
    TabStop = True
    OnClick = r2Click
  end
  object b1: TColorBox
    Left = 389
    Top = 546
    Width = 90
    Height = 22
    DefaultColorColor = clWhite
    Selected = clYellow
    TabOrder = 12
  end
  object b2: TColorBox
    Left = 542
    Top = 546
    Width = 90
    Height = 22
    TabOrder = 13
  end
  object c1: TCheckBox
    Left = 271
    Top = 547
    Width = 74
    Height = 17
    Caption = #20351#29992#39068#33394
    Checked = True
    State = cbChecked
    TabOrder = 14
  end
end
