object CfgForm: TCfgForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  ClientHeight = 670
  ClientWidth = 1192
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = #23435#20307
  Font.Style = []
  Position = poScreenCenter
  StyleElements = []
  OnClose = FormClose
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  TextHeight = 14
  object Panel1: TPanel
    Left = 313
    Top = 17
    Width = 879
    Height = 478
    Align = alClient
    Caption = 'Panel1'
    TabOrder = 0
    ExplicitLeft = 345
    ExplicitWidth = 847
    object ve1: TValueListEditor
      Left = 1
      Top = 1
      Width = 877
      Height = 476
      Hint = #21452#20987#21024#38500
      Align = alClient
      BorderStyle = bsNone
      Ctl3D = False
      DisplayOptions = []
      DoubleBuffered = True
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -14
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
      ExplicitWidth = 845
      ColWidths = (
        285
        678)
    end
  end
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 17
    Width = 313
    Height = 478
    Align = alLeft
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 1
    OnMouseEnter = ScrollBox1MouseEnter
    OnMouseLeave = ScrollBox1MouseLeave
  end
  object Panel2: TPanel
    Left = 0
    Top = 495
    Width = 1192
    Height = 175
    Align = alBottom
    BevelEdges = [beTop]
    TabOrder = 2
    Visible = False
    object Button1: TButton
      Left = 926
      Top = 40
      Width = 91
      Height = 83
      Caption = #28155#21152
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -32
      Font.Name = #23435#20307
      Font.Style = []
      ParentFont = False
      TabOrder = 0
      OnClick = Buttoaction_translator
    end
    object ComboBox1: TComboBox
      Left = 81
      Top = 13
      Width = 145
      Height = 22
      TabOrder = 1
      Text = #22270#26631#26679#24335'1'
      Items.Strings = (
        #22270#26631#26679#24335'1'
        #22270#26631#26679#24335'2')
    end
    object filedit: TLabeledEdit
      Left = 81
      Top = 129
      Width = 936
      Height = 38
      Hint = #21452#20987#28155#21152
      EditLabel.Width = 56
      EditLabel.Height = 38
      EditLabel.Caption = #25991#20214#36335#24452
      EditLabel.OnDblClick = fileditSubLabelDblClick
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = 30
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
    object imgEdit1: TLabeledEdit
      Left = 81
      Top = 41
      Width = 541
      Height = 38
      Hint = #21452#20987#28155#21152
      EditLabel.Width = 56
      EditLabel.Height = 38
      EditLabel.Caption = #36873#25321#22270#26631
      Enabled = False
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = 30
      Font.Name = #23435#20307
      Font.Style = []
      LabelPosition = lpLeft
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 3
      Text = ''
      OnDblClick = imgEdit1DblClick
    end
    object text_edit: TLabeledEdit
      Left = 81
      Top = 85
      Width = 208
      Height = 38
      Hint = #21452#20987#28155#21152
      EditLabel.Width = 56
      EditLabel.Height = 38
      EditLabel.Caption = #29983#25104#22270#26631
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = 30
      Font.Name = #23435#20307
      Font.Style = []
      LabelPosition = lpLeft
      MaxLength = 16
      ParentFont = False
      ParentShowHint = False
      ShowHint = True
      TabOrder = 4
      Text = ''
    end
    object tip: TLabeledEdit
      Left = 368
      Top = 85
      Width = 254
      Height = 38
      EditLabel.Width = 56
      EditLabel.Height = 38
      EditLabel.Caption = #25552#31034#25991#23383
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = 30
      Font.Name = #23435#20307
      Font.Style = []
      LabelPosition = lpLeft
      ParentFont = False
      TabOrder = 5
      Text = ''
      TextHint = #26080
    end
    object CheckBox1: TCheckBox
      Left = 664
      Top = 70
      Width = 97
      Height = 17
      Caption = #36873#25321#22270#26631
      TabOrder = 6
      OnClick = CheckBox1Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 1192
    Height = 17
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    object Button2: TButton
      Left = 1129
      Top = -3
      Width = 67
      Height = 23
      Caption = 'X'
      TabOrder = 0
      OnClick = Button2Click
    end
  end
  object Button3: TButton
    Left = 1111
    Top = 639
    Width = 75
    Height = 25
    Caption = #33258#23450#20041
    TabOrder = 4
    OnClick = Button3Click
  end
  object ImgList: TImageList
    Left = 440
    Top = 320
  end
end
