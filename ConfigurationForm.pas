unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
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
  oldNum: Integer = 0;
  oldValue: Integer = 0;

var
  reLayout: Boolean = false;
  reStore: Boolean = false;
  xchange: Boolean = false;

implementation

{$R *.dfm}

uses
  ApplicationMain, core, GDIPAPI, GDIPOBJ;

function text_outa(txt: string; x, y, fontsize: integer; fontname: string): string;
var
  font: tgpfont;
  pt: tgppointf;
  stringformat: tgpstringformat;
  brush: tgpsolidbrush;
  graphics: tgpgraphics;
begin
  var vPng := TPNGObject.Create;

  vPng.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\template.png');
  graphics := tgpgraphics.create(vPng.canvas.handle);
  graphics.setsmoothingmode(smoothingmodeantialias);
  graphics.setinterpolationmode(interpolationmodehighqualitybicubic);
  //  　graphics.DrawImage(img, 0, 0, img.GetWidth, img.GetHeight);
  font := tgpfont.create(fontname, fontsize, FontStyleBold);
  brush := tgpsolidbrush.create(makecolor(180, 255, 255, 255));

  stringformat := tgpstringformat.create();
//              stringformat.SetAlignment(TStringAlignment.StringAlignmentCenter);
  pt := makepoint(x, y * 0.1 * 10);
  graphics.drawstring(txt, length(txt), font, pt, stringformat, brush);
  var s := FormatDateTime('yyyy_mm_dd_hh_nn_ss_zzz', Now);
  s := s.Replace('_', '');
  result := ExtractFilePath(ParamStr(0)) + 'img\' + s + '.png';
  vPng.SaveToFile(result);

  vPng.free;
  graphics.free;
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
      if g_core.utils.fileMap.TryAdd(Trim(LabeledEdit1.Text), Trim(LabeledEdit2.Text)) then
      begin
        if (Trim(LabeledEdit1.Text).Contains('http')) then
          ValueListEditor1.InsertRow((Trim(LabeledEdit1.Text)), Trim(LabeledEdit2.Text), True)
//            ValueListEditor1.InsertRow((Trim(LabeledEdit1.Text)), ExtractFileName(Trim(LabeledEdit2.Text)), True)
        else
          ValueListEditor1.InsertRow(ExtractFileName(Trim(LabeledEdit1.Text)), ExtractFileName(Trim(LabeledEdit2.Text)), True);
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

      label1.Font.Size := 20;
      var wd := Label1.Canvas.TextWidth(Trim(LabeledEdit3.Text));
      var hg := Label1.Canvas.TextHeight(Trim(LabeledEdit3.Text));
      var x := Round((128 - wd) div 2) - 3;
      var y := Round((128 - hg) div 2) - 6;
      var imgpath := text_outa(Trim(LabeledEdit3.Text), x, y, 20, '微软雅黑');

      if g_core.utils.fileMap.TryAdd(imgpath, Trim(LabeledEdit2.Text)) then
      begin
        if (Trim(imgpath).Contains('http')) then
          ValueListEditor1.InsertRow((Trim(imgpath)), Trim(LabeledEdit2.Text), True)
//            ValueListEditor1.InsertRow((Trim(imgpath)), ExtractFileName(Trim(LabeledEdit2.Text)), True)
        else
          ValueListEditor1.InsertRow(ExtractFileName(Trim(imgpath)), ExtractFileName(Trim(LabeledEdit2.Text)), True);
        LabeledEdit1.Text := '';
        LabeledEdit3.Text := '';
        LabeledEdit2.Text := '';
        xchange := true;
      end
      else
      begin
        ShowMessage('图片已使用')
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
  if (oldNum <> g_core.utils.fileMap.Count) or reLayout or (Edit1.Text <> oldValue.ToString) or xchange then
  begin

    update_db();
    Form1.layout;
  end;
  g_core.NodeInformation.IsConfiguring := false;

end;

procedure TCfgForm.FormShow(Sender: TObject);
var
  appPath, imgPath: string;
begin
  ValueListEditor1.Strings.Clear;
  var Keys := g_core.DatabaseManager.itemdb.GetKeys;
  for var i := 0 to Keys.Count - 1 do
  begin
    var key := Keys[i];
    var value := g_core.DatabaseManager.itemdb.GetString(key);
    var altValue := g_core.DatabaseManager.itemdb.GetString(key, false);
    g_core.utils.fileMap.TryAdd(value, altValue);
    imgPath := ExtractFileName(value);
    if altValue.Contains('http') then
      appPath := altValue
    else
      appPath := ExtractFileName(altValue);
    ValueListEditor1.InsertRow(imgPath, appPath, True);
  end;

  /// 后面关闭 数据是否变化作用
  oldNum := Keys.Count;
  oldValue := g_core.DatabaseManager.cfgDb.GetInteger('ih');
  Edit1.Text := oldValue.ToString;
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
  LabeledEdit1.Enabled := true;
end;

procedure TCfgForm.r2Click(Sender: TObject);
begin
  LabeledEdit3.Enabled := true;
  LabeledEdit1.Enabled := false;
end;

procedure TCfgForm.ValueListEditor1DblClick(Sender: TObject);
begin
  var pp := ValueListEditor1.Keys[ValueListEditor1.Row];
  if pp = '' then
    Exit;
  begin
    var inx: Integer;

    for var key in g_core.utils.fileMap.Keys do
    begin
      if ExtractFileName(key) = pp then
      begin
        if ValueListEditor1.FindRow(pp, inx) then
        begin
          ValueListEditor1.DeleteRow(inx);
          var key_ := HashName(pansichar(key)).ToString;
          g_core.utils.fileMap.Remove(key);
          g_core.DatabaseManager.itemdb.DeleteValue(key_);
          g_core.DatabaseManager.itemdb.DeleteValue(key_, false);
          xchange := true;
        end;
      end;

    end;

  end;

end;

end.

