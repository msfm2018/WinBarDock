object CfgForm: TCfgForm
  Left = 0
  Top = 0
  BorderStyle = bsNone
  ClientHeight = 569
  ClientWidth = 1097
  Color = clBtnFace
  Font.Charset = GB2312_CHARSET
  Font.Color = clWindowText
  Font.Height = -14
  Font.Name = #23435#20307
  Font.Style = []
  Position = poScreenCenter
  StyleElements = []
  OnClose = FormClose
  OnMouseDown = FormMouseDown
  OnMouseWheel = FormMouseWheel
  OnShow = FormShow
  TextHeight = 14
  object Panel1: TPanel
    Left = 257
    Top = 25
    Width = 840
    Height = 407
    Align = alClient
    Caption = 'Panel1'
    TabOrder = 0
    ExplicitLeft = 313
    ExplicitWidth = 849
    ExplicitHeight = 470
    object ListView1: TListView
      Left = 1
      Top = 1
      Width = 838
      Height = 405
      Align = alClient
      Columns = <>
      Font.Charset = GB2312_CHARSET
      Font.Color = clWindowText
      Font.Height = -19
      Font.Name = #24494#36719#38597#40657
      Font.Style = []
      RowSelect = True
      ParentFont = False
      TabOrder = 0
      ViewStyle = vsReport
      OnDblClick = ListView1DblClick
      OnResize = ListView1Resize
      ExplicitWidth = 877
      ExplicitHeight = 468
    end
  end
  object ScrollBox1: TScrollBox
    Left = 0
    Top = 25
    Width = 257
    Height = 407
    Align = alLeft
    BevelInner = bvNone
    BevelOuter = bvNone
    BorderStyle = bsNone
    TabOrder = 1
    OnMouseEnter = ScrollBox1MouseEnter
    OnMouseLeave = ScrollBox1MouseLeave
    ExplicitHeight = 470
  end
  object Panel2: TPanel
    Left = 0
    Top = 432
    Width = 1097
    Height = 137
    Align = alBottom
    BevelEdges = [beTop]
    TabOrder = 2
    Visible = False
    object ComboBox1: TComboBox
      Left = 628
      Top = 68
      Width = 145
      Height = 22
      TabOrder = 0
      Text = #22270#26631#26679#24335'1'
      Items.Strings = (
        #22270#26631#26679#24335'1'
        #22270#26631#26679#24335'2')
    end
    object filedit: TLabeledEdit
      Left = 81
      Top = 96
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
      TabOrder = 1
      Text = ''
      OnDblClick = imgEdit1DblClick
    end
    object imgEdit1: TLabeledEdit
      Left = 81
      Top = 8
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
      TabOrder = 2
      Text = ''
      OnDblClick = imgEdit1DblClick
    end
    object text_edit: TLabeledEdit
      Left = 81
      Top = 52
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
      TabOrder = 3
      Text = ''
    end
    object tip: TLabeledEdit
      Left = 368
      Top = 52
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
      TabOrder = 4
      Text = ''
      TextHint = #26080
    end
    object CheckBox1: TCheckBox
      Left = 628
      Top = 22
      Width = 97
      Height = 17
      Caption = #36873#25321#22270#26631
      TabOrder = 5
      OnClick = CheckBox1Click
    end
  end
  object Panel3: TPanel
    Left = 0
    Top = 0
    Width = 1097
    Height = 25
    Align = alTop
    BevelOuter = bvNone
    TabOrder = 3
    OnMouseDown = FormMouseDown
    ExplicitWidth = 1192
  end
  object Button3: TButton
    Left = 1025
    Top = 538
    Width = 64
    Height = 25
    Caption = #33258#23450#20041
    TabOrder = 4
    OnClick = Button3Click
  end
  object ImgList: TImageList
    Left = 256
    Top = 368
  end
end
