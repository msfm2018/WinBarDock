unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  Vcl.Imaging.pngimage, System.Generics.Collections, Vcl.Menus, Vcl.Mask,
  System.Hash, Vcl.Samples.Spin;

type
  TCfgForm = class(TForm)
    ValueListEditor1: TValueListEditor;
    Button1: TButton;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    Button2: TButton;
    Button3: TButton;
    Edit1: TSpinEdit;
    CheckBox1: TCheckBox;
    LabeledEdit3: TLabeledEdit;
    RadioGroup1: TRadioGroup;
    r1: TRadioButton;
    r2: TRadioButton;
    Label1: TLabel;
    b1: TColorBox;
    Label2: TLabel;
    b2: TColorBox;
    c1: TCheckBox;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure LabeledEdit1DblClick(Sender: TObject);
    procedure LabeledEdit2DblClick(Sender: TObject);
    procedure ValueListEditor1DblClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure r2Click(Sender: TObject);
    procedure r1Click(Sender: TObject);
  private
    procedure update_db;
  public
  end;

var
  OldNum: Integer = 0;
  OldValue: Integer = 0;

  reLayout: Boolean = false;
  reStore: Boolean = false;
  xchange: Boolean = false;

implementation

{$R *.dfm}

uses
  ApplicationMain, core, GDIPAPI, GDIPOBJ;

function text_outa(txt: string; x, y, fontsize: Integer; fontname: string;
  gc1, gc2: tcolor; b: Boolean): string;
var
  font: tgpfont;
  pt: tgppointf;
  stringformat: tgpstringformat;
  brush: tgpsolidbrush;
  Graphics: tgpgraphics;
  vPng: TPNGObject;
  red, green, blue: Byte; // 用于存储颜色分量的字节变量
  red2, green2, blue2: Byte; // 用于存储颜色分量的字节变量
  red1, green1, blue1: Byte;
begin

  // 将 TColor 转换为 RGB 分量
  red1 := GetRValue(ColorToRGB(gc1));
  green1 := GetGValue(ColorToRGB(gc1));
  blue1 := GetBValue(ColorToRGB(gc1));

  red2 := GetRValue(ColorToRGB(gc2));
  green2 := GetGValue(ColorToRGB(gc2));
  blue2 := GetBValue(ColorToRGB(gc2));

  vPng := TPNGObject.Create;

  vPng.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\template.png');

  Graphics := tgpgraphics.Create(vPng.canvas.handle);

  red := EnsureRange(red1, 0, 255);
  green := EnsureRange(green1, 0, 255);
  blue := EnsureRange(blue1, 0, 255);
  // 填充整个画布为红色背景
  Graphics.FillRectangle(tgpsolidbrush.Create(makecolor(255, red, green, blue)),
    0, 0, vPng.Width, vPng.Height);

  Graphics.setsmoothingmode(smoothingmodeantialias);
  Graphics.setinterpolationmode(interpolationmodehighqualitybicubic);

  font := tgpfont.Create(fontname, fontsize, FontStyleBold);

  red := EnsureRange(red2, 0, 255);
  green := EnsureRange(green2, 0, 255);
  blue := EnsureRange(blue2, 0, 255);

  if b then
    brush := tgpsolidbrush.Create(makecolor(255, red, green, blue))
  else
    brush := tgpsolidbrush.Create(makecolor(255, 255, 255, 255));

  stringformat := tgpstringformat.Create();
  pt := makepoint(x, y * 0.1 * 10);

  Graphics.drawstring(txt, length(txt), font, pt, stringformat, brush);

  var
  s := FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now);
  s := s.Replace('_', '');
  result := ExtractFilePath(ParamStr(0)) + 'img\' + s + '.png';
  vPng.SaveToFile(result);
  result := '.\img\' + s + '.png';

  vPng.free;
  Graphics.free;
  font.free;
  brush.free;
end;

procedure TCfgForm.update_db();
var
  Hash: string;
  v: string;
begin
  g_core.DatabaseManager.itemdb.clean();
  g_core.DatabaseManager.itemdb.clean(false);

  for var key in g_core.utils.fileMap.Keys do
  begin
    v := '';
    if g_core.utils.fileMap.TryGetValue(key, v) then
    begin

      Hash := THashMD5.GetHashString(key);
      // k v 存储在不同表中
      g_core.DatabaseManager.itemdb.SetVarValue(Hash, key);
      g_core.DatabaseManager.itemdb.SetVarValue(Hash, v, false);
    end;

  end;

end;

procedure TCfgForm.Button1Click(Sender: TObject);
begin
  if r1.Checked then
  begin
    if (Trim(LabeledEdit1.Text) <> '') and (Trim(LabeledEdit2.Text) <> '') then
    begin
      if g_core.utils.fileMap.TryAdd(Trim(LabeledEdit1.Text),
        Trim(LabeledEdit2.Text)) then
      begin
        if (Trim(LabeledEdit1.Text).Contains('http')) then
          ValueListEditor1.InsertRow((Trim(LabeledEdit1.Text)),
            Trim(LabeledEdit2.Text), True)
        else
          ValueListEditor1.InsertRow(ExtractFileName(Trim(LabeledEdit1.Text)),
            ExtractFileName(Trim(LabeledEdit2.Text)), True);
        LabeledEdit1.Text := '';
        LabeledEdit3.Text := '';
        LabeledEdit2.Text := '';
        xchange := True;
      end;
    end;
  end
  else if r2.Checked then
  begin
    if (Trim(LabeledEdit2.Text) <> '') and (Trim(LabeledEdit3.Text) <> '') then
    begin
      if c1.Checked then
      begin

        Label1.font.Size := 20;
        var
        wd := Label1.canvas.TextWidth(Trim(LabeledEdit3.Text));
        var
        hg := Label1.canvas.TextHeight(Trim(LabeledEdit3.Text));
        var
        x := Round((128 - wd) div 2) - 3;
        var
        y := Round((128 - hg) div 2) - 6;
        var
        imgpath := text_outa(Trim(LabeledEdit3.Text), x, y, 20, '微软雅黑',
          b1.Selected, b2.Selected, True);

        if g_core.utils.fileMap.TryAdd(imgpath, Trim(LabeledEdit2.Text)) then
        begin
          if (Trim(imgpath).Contains('http')) then
            ValueListEditor1.InsertRow((Trim(imgpath)),
              Trim(LabeledEdit2.Text), True)
          else
            ValueListEditor1.InsertRow(ExtractFileName(Trim(imgpath)),
              ExtractFileName(Trim(LabeledEdit2.Text)), True);
          LabeledEdit1.Text := '';
          LabeledEdit3.Text := '';
          LabeledEdit2.Text := '';
          xchange := True;
        end
        else
        begin
          ShowMessage('图片已使用')
        end;
      end
      else
      begin

        Label1.font.Size := 20;
        var
        wd := Label1.canvas.TextWidth(Trim(LabeledEdit3.Text));
        var
        hg := Label1.canvas.TextHeight(Trim(LabeledEdit3.Text));
        var
        x := Round((128 - wd) div 2) - 3;
        var
        y := Round((128 - hg) div 2) - 6;
        var
        imgpath := text_outa(Trim(LabeledEdit3.Text), x, y, 20, '微软雅黑',
          b1.Selected, b2.Selected, false);
        if g_core.utils.fileMap.TryAdd(imgpath, Trim(LabeledEdit2.Text)) then
        begin
          if (Trim(imgpath).Contains('http')) then
            ValueListEditor1.InsertRow((Trim(imgpath)),
              Trim(LabeledEdit2.Text), True)
          else
            ValueListEditor1.InsertRow(ExtractFileName(Trim(imgpath)),
              ExtractFileName(Trim(LabeledEdit2.Text)), True);
          LabeledEdit1.Text := '';
          LabeledEdit3.Text := '';
          LabeledEdit2.Text := '';
          xchange := True;
        end
        else
        begin
          ShowMessage('图片已使用')
        end;

      end;
    end;

  end;

end;

procedure TCfgForm.Button2Click(Sender: TObject);
begin
  g_core.NodeInformation.NodeSize := strtoint(Edit1.Text);
  g_core.DatabaseManager.cfgDb.SetVarValue('ih', StrToIntDef(Edit1.Text, 118));
  close();
end;

procedure TCfgForm.Button3Click(Sender: TObject);
begin
  // 初始化数据
  g_core.DatabaseManager.cfgDb.SetVarValue('ih', 80);
  reLayout := True;
  // Close();
end;

procedure TCfgForm.CheckBox1Click(Sender: TObject);
var
  v: Integer;
begin
  if not CheckBox1.Visible then
    v := 1
  else
    v := 0;
  g_core.DatabaseManager.cfgDb.SetVarValue('bgVisible', v);
end;

procedure TCfgForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (OldNum <> g_core.utils.fileMap.Count) or reLayout or
    (Edit1.Text <> OldValue.ToString) or xchange then
  begin

    update_db();
    Form1.layout;
  end;
  g_core.NodeInformation.IsConfiguring := false;

end;

procedure TCfgForm.FormShow(Sender: TObject);
var
  appPath, imgpath: string;
begin
  ValueListEditor1.Strings.Clear;
  var
  Keys := g_core.DatabaseManager.itemdb.GetKeys;
  for var i := 0 to Keys.Count - 1 do
  begin
    var
    key := Keys[i];
    var
    value := g_core.DatabaseManager.itemdb.GetString(key);
    var
    altValue := g_core.DatabaseManager.itemdb.GetString(key, false);
    g_core.utils.fileMap.TryAdd(value, altValue);
    imgpath := ExtractFileName(value);
    if altValue.Contains('http') then
      appPath := altValue
    else
      appPath := ExtractFileName(altValue);
    ValueListEditor1.InsertRow(imgpath, appPath, True);
  end;

  /// 后面关闭 数据是否变化作用
  OldNum := Keys.Count;
  OldValue := g_core.DatabaseManager.cfgDb.GetInteger('ih');
  Edit1.Text := OldValue.ToString;
  reLayout := false;

  if g_core.DatabaseManager.cfgDb.GetInteger('bgVisible') = 1 then
    CheckBox1.Checked := True
  else
    CheckBox1.Checked := false;

  xchange := false;

end;

procedure TCfgForm.LabeledEdit1DblClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  with OpenDlg do
  begin
    Filter := '文件(*.png)|*.png';
    DefaultExt := '*.png';

    if Execute then
    begin
      LabeledEdit1.Text := FileName;
    end;
  end;
  OpenDlg.free;
end;

procedure TCfgForm.LabeledEdit2DblClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  with OpenDlg do
  begin
    Filter := '文件(*.EXE)|*.EXE';
    DefaultExt := '*.EXE';

    if Execute then
    begin
      LabeledEdit2.Text := FileName;
    end;
  end;
end;

procedure TCfgForm.r1Click(Sender: TObject);
begin
  LabeledEdit3.Enabled := false;
  LabeledEdit1.Enabled := True;
end;

procedure TCfgForm.r2Click(Sender: TObject);
begin
  LabeledEdit3.Enabled := True;
  LabeledEdit1.Enabled := false;
end;

procedure TCfgForm.ValueListEditor1DblClick(Sender: TObject);
begin
  var
  pp := ValueListEditor1.Keys[ValueListEditor1.Row];
  if pp = '' then
    Exit;
  begin
    var
      inx: Integer;

    for var key in g_core.utils.fileMap.Keys do
    begin
      if ExtractFileName(key) = pp then
      begin
        if ValueListEditor1.FindRow(pp, inx) then
        begin
          ValueListEditor1.DeleteRow(inx);
          var
          key_ := HashName(pansichar(key)).ToString;
          g_core.utils.fileMap.Remove(key);
          g_core.DatabaseManager.itemdb.DeleteValue(key_);
          g_core.DatabaseManager.itemdb.DeleteValue(key_, false);
          xchange := True;
        end;
      end;

    end;

  end;

end;

end.
