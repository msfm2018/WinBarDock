object CfgForm: TCfgForm
  Left = 0
  Top = 0
  Caption = #37197#32622'  '
  ClientHeight = 631
  ClientWidth = 894
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = #23435#20307
  Font.Style = []
  Position = poScreenCenter
  OnClose = FormClose
  OnShow = FormShow
  TextHeight = 14
  object Label1: TLabel
    Left = 440
    Top = 328
    Width = 42
    Height = 14
    Caption = 'Label1'
  end
  object Label2: TLabel
    Left = 292
    Top = 552
    Width = 84
    Height = 14
    Caption = #32972#26223#28176#21464#39068#33394
  end
  object ve1: TValueListEditor
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
    OnDblClick = ve1DblClick
    ColWidths = (
      285
      607)
  end
  object Button1: TButton
    Left = 795
    Top = 527
    Width = 91
    Height = 70
    Caption = #28155#21152
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -32
    Font.Name = #40657#20307
    Font.Style = []
    ParentFont = False
    TabOrder = 1
    OnClick = Button1Click
  end
  object imgEdit1: TLabeledEdit
    Left = 81
    Top = 520
    Width = 541
    Height = 22
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 70
    EditLabel.Height = 22
    EditLabel.Caption = #33258#23450#20041#22270#29255
    Enabled = False
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -14
    Font.Name = #23435#20307
    Font.Style = []
    LabelPosition = lpLeft
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 2
    Text = ''
    OnDblClick = imgEdit1DblClick
  end
  object LabeledEdit2: TLabeledEdit
    Left = 73
    Top = 586
    Width = 560
    Height = 22
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 56
    EditLabel.Height = 22
    EditLabel.Caption = #25991#20214#36335#24452
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -14
    Font.Name = #23435#20307
    Font.Style = []
    LabelPosition = lpLeft
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 3
    Text = ''
    OnDblClick = LabeledEdit2DblClick
  end
  object LabeledEdit3: TLabeledEdit
    Left = 73
    Top = 553
    Width = 112
    Height = 22
    Hint = #21452#20987#28155#21152
    EditLabel.Width = 56
    EditLabel.Height = 22
    EditLabel.Caption = #25551#36848#25991#23383
    Font.Charset = GB2312_CHARSET
    Font.Color = clWindowText
    Font.Height = -14
    Font.Name = #23435#20307
    Font.Style = []
    LabelPosition = lpLeft
    MaxLength = 2
    ParentFont = False
    ParentShowHint = False
    ShowHint = True
    TabOrder = 4
    Text = ''
    OnDblClick = LabeledEdit2DblClick
  end
  object RadioGroup1: TRadioGroup
    Left = 649
    Top = 529
    Width = 112
    Height = 70
    TabOrder = 5
  end
  object rbimg: TRadioButton
    Left = 656
    Top = 545
    Width = 105
    Height = 17
    Caption = #33258#23450#20041#22270#29255
    TabOrder = 6
    OnClick = rbimgClick
  end
  object rbtxt: TRadioButton
    Left = 656
    Top = 568
    Width = 97
    Height = 17
    Caption = #25551#36848#25991#23383
    Checked = True
    TabOrder = 7
    TabStop = True
    OnClick = rbtxtClick
  end
  object b1: TColorBox
    Left = 495
    Top = 546
    Width = 90
    Height = 22
    DefaultColorColor = clWhite
    Selected = clYellow
    TabOrder = 8
  end
  object b2: TColorBox
    Left = 386
    Top = 546
    Width = 90
    Height = 22
    Selected = clAqua
    TabOrder = 9
  end
end
