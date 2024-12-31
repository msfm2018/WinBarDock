unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Winapi.ShellAPI, Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls,
  Vcl.ExtCtrls, Vcl.Buttons, utils, u_json, System.IniFiles, u_debug,
  Vcl.Imaging.pngimage, System.JSON, System.Generics.Collections, Vcl.Menus,
  winapi.UxTheme, ImgPanel, Vcl.Mask, System.Hash,
  System.ImageList, Vcl.ImgList;

type
  TCfgForm = class(TForm)
    ve1: TValueListEditor;
    Button1: TButton;
    imgEdit1: TLabeledEdit;
    text_edit: TLabeledEdit;
    tip: TLabeledEdit;
    filedit: TLabeledEdit;
    ComboBox1: TComboBox;
    ImgList: TImageList;
    Panel1: TPanel;
    ScrollBox1: TScrollBox;
    Panel2: TPanel;
    Button2: TButton;
    Panel3: TPanel;
    CheckBox1: TCheckBox;
    Button3: TButton;
    procedure Buttoaction_translator(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgEdit1DblClick(Sender: TObject);
    procedure ve1DblClick(Sender: TObject);
    procedure rbtxtClick(Sender: TObject);
    procedure rbimgClick(Sender: TObject);
    procedure fileditSubLabelDblClick(Sender: TObject);
    procedure FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure ScrollBox1MouseEnter(Sender: TObject);
    procedure ScrollBox1MouseLeave(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    file_map: TDictionary<string, string>;
    procedure AddFileInfoToJson(const Key, ImageFileName, FilePath, ToolTip: string);
    procedure ClearInputs;
    procedure show_aapp(Path, FileName: string);
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);

    procedure PanelDblClick(Sender: TObject);

  public
    FShadowAlpha: Byte; // 阴影透明度 (0-255)
    FShadowColor: TColor; // 阴影颜色
  end;

  TStartMenuApp = record
    Name: string;
    Path: string;
  end;

  TStartMenuApps = class
  public
    class function GetApps: TArray<TStartMenuApp>;
  end;

var
  xchange: Boolean = false;
  FRoundWindow: Boolean = true;
  FShadowForm: tform;

var
  Apps: TArray<TStartMenuApp>;
  App: TStartMenuApp;

implementation

{$R *.dfm}

uses
  core, System.UITypes;

function SaveAppIconAsPng(const FilePath: string): string;
var
  Icon: TIcon;
  Bitmap: TBitmap;
  Png: TPngImage;
begin
  Icon := TIcon.Create;
  Bitmap := TBitmap.Create;
  Png := TPngImage.Create;
  try
    // 获取应
    Icon.Handle := ExtractIcon(HInstance, PChar(FilePath), 0);
    // 将图标转换为位图
    Bitmap.Width := Icon.Width;
    Bitmap.Height := Icon.Height;
    Bitmap.Canvas.Draw(0, 0, Icon);

    // 将位图转换为 PNG
    Png.Assign(Bitmap);

    // 保存为 PNG 文件
    result := ExtractFilePath(ParamStr(0)) + 'img\' + ChangeFileExt(ExtractFileName(FilePath), '.png');
    Png.SaveToFile(result);

  finally
    Icon.Free;
    Bitmap.Free;
    Png.Free;
  end;
end;

procedure TCfgForm.PanelDblClick(Sender: TObject);
var
  key1, key2: string;
  Hash, imgpath: string;
begin
  key1 := SaveAppIconAsPng(TImgPanel(Sender).extendB);

  key2 := TImgPanel(Sender).extendb;

  if (key1 <> '') and (key2 <> '') then
  begin
    g_core.utils.CopyFileToFolder(key1, ExtractFilePath(ParamStr(0)) + 'img');

    Hash := THashMD5.GetHashString(ExtractFileName(key1));
    imgpath := key1;

    if file_map.TryAdd(Hash, Format('%s,%s,%s', [ExtractFileName(key1), imgpath, TImgPanel(Sender).extendA])) then
    begin
      AddFileInfoToJson(Hash, ExtractFileName(key1), key2, TImgPanel(Sender).extendA);

      ve1.InsertRow(ExtractFileName(key1), TImgPanel(Sender).extendA, True);
      ClearInputs;
    end;

        var p: timage;
      if not g_core.ImageCache.TryGetValue(ExtractFileName(key1), p) then
      begin
        p := TImage.Create(nil);
        p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(key1));
        g_core.ImageCache.Add(ExtractFileName(key1), p);

      end

  end;

end;

procedure TCfgForm.show_aapp(Path, FileName: string);
var
  Panel: TImgPanel;
  Image: TImage;
  Label1: TLabel;
  FileIcon: TIcon;
  FilePath: string;
begin
  FilePath := Path;

  FileIcon := TIcon.Create;
  try
    FileIcon.Handle := ExtractIcon(HInstance, PChar(FilePath), 0);

    ScrollBox1.VertScrollBar.Visible := True;  // 启用垂直滚动条

    Panel := TImgPanel.Create(Scrollbox1);
    Panel.Parent := ScrollBox1;

    Panel.Align := alTop;
    Panel.Height := 60;  // 设置Panel的高度
    Panel.BevelOuter := bvNone; // 可选，移除边框
    Panel.ParentColor := False;
    Panel.StyleElements := [seClient];
    Panel.extendA := FileName;
    Panel.extendB := Path; //
    // 创建显示图标的Image控件
    Image := TImage.Create(Self);
    Image.Parent := Panel;
    Image.Picture.Icon := FileIcon;
    Image.Width := 32;   // 设置图标的大小
    Image.Height := 32;

    // 创建显示文本的Label控件
    Label1 := TLabel.Create(Self);
    Label1.Parent := Panel;
    Label1.Caption := FileName;
    Label1.AutoSize := True;

    Image.Left := 10; // (Panel.Width - Image.Width - Label1.Width - 10) div 2;  // 图标居中
    Image.Top := (Panel.Height - Image.Height) div 2;  // 图标垂直居中

    Label1.Left := Image.Left + Image.Width + 10;  // 图标和文本之间的间距
    Label1.Top := (Panel.Height - Label1.Height) div 2;  // 文本垂直居中

     // 设置鼠标事件处理程序
    Panel.OnMouseEnter := PanelMouseEnter;
    Panel.OnMouseLeave := PanelMouseLeave;
    Panel.ParentBackground := False;
    Panel.OnDblClick := PanelDblClick;
  finally
    FileIcon.Free;
  end;

end;

procedure TCfgForm.PanelMouseEnter(Sender: TObject);
begin
  (Sender as TImgPanel).color := $f5f5f5;

end;

procedure TCfgForm.PanelMouseLeave(Sender: TObject);
begin

  (Sender as TImgPanel).color := clBtnFace;

end;

procedure LoadIconFromDll(const extension: string; Image: TImage);
var
  hIcon1: HICON;
begin
  hIcon1 := GetFileIcon1(PChar(extension));

  if hIcon1 <> 0 then
  begin
    Image.Picture.Icon.Handle := hIcon1;

  end

end;

class function TStartMenuApps.GetApps: TArray<TStartMenuApp>;
var
  AppsJSON: string;
  JSONArray: TJSONArray;
  JSONValue: TJSONValue;
  App: TStartMenuApp;
  AppList: TArray<TStartMenuApp>;
  I: Integer;
begin
  // Call DLL function
  AppsJSON := string(GetStartMenuApps);

  // Parse JSON string
  JSONArray := TJSONObject.ParseJSONValue(AppsJSON) as TJSONArray;
  try
    SetLength(AppList, JSONArray.Count);
    for I := 0 to JSONArray.Count - 1 do
    begin
      JSONValue := JSONArray.Items[I];
      App.Name := JSONValue.GetValue<string>('name');
      App.Path := JSONValue.GetValue<string>('path');
      AppList[I] := App;
    end;
  finally
    JSONArray.Free;
  end;

  Result := AppList;
end;

procedure TCfgForm.Buttoaction_translator(Sender: TObject);
var
  key1, key2, Hash, imgpath: string;
  utf8Text, ansi_path: PAnsiChar;
begin
  if CheckBox1.Checked then
  begin
    key1 := Trim(imgEdit1.Text);
    key2 := Trim(filedit.Text);
    if (key1 <> '') and (key2 <> '') then
    begin
      g_core.utils.CopyFileToFolder(key1, ExtractFilePath(ParamStr(0)) + 'img');

      Hash := THashMD5.GetHashString(ExtractFileName(key1));
      imgpath := ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(key1);

      if file_map.TryAdd(Hash, Format('%s,%s,%s', [ExtractFileName(key1), imgpath, Trim(tip.Text)])) then
      begin
        AddFileInfoToJson(Hash, ExtractFileName(key1), key2, tip.Text);

        ve1.InsertRow(ExtractFileName(key1), Trim(tip.Text), True);
        ClearInputs;
      end;

      var p: timage;
      if not g_core.ImageCache.TryGetValue(ExtractFileName(key1), p) then
      begin
        p := TImage.Create(nil);
        p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(key1));
        g_core.ImageCache.Add(ExtractFileName(key1), p);

      end

    end;
  end
  else
  begin
    if (Trim(text_edit.Text) <> '') and (Trim(filedit.Text) <> '') then
    begin
      imgpath := ExtractFilePath(ParamStr(0)) + 'img\' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.png';

      utf8Text := PAnsiChar(UTF8Encode(Trim(text_edit.Text)));

      ansi_path := PAnsiChar(UTF8Encode(imgpath));
      if ComboBox1.Text = '图标样式1' then
        write_png_with_text(ansi_path, utf8Text, 2)
      else
        write_png_with_text(ansi_path, utf8Text, 1);

      key1 := ExtractFileName(imgpath);
      Hash := THashMD5.GetHashString(key1);

      if file_map.TryAdd(Hash, Format('%s,%s,%s', [key1, imgpath, Trim(tip.Text)])) then
      begin
        AddFileInfoToJson(Hash, key1, Trim(filedit.Text), tip.Text);
        ve1.InsertRow(key1, Trim(tip.Text), True);
        ClearInputs;
      end;

      var p: timage;
      if not g_core.ImageCache.TryGetValue(key1, p) then
      begin
        p := TImage.Create(nil);
        p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + key1);
        g_core.ImageCache.Add(key1, p);

      end

    end;
  end;

end;

procedure TCfgForm.Button2Click(Sender: TObject);
begin
  Close;
end;

procedure TCfgForm.Button3Click(Sender: TObject);
begin
  if Panel2.Visible then
    Panel2.Visible := False
  else
    Panel2.Visible := True;
end;

procedure TCfgForm.AddFileInfoToJson(const Key, ImageFileName, FilePath, ToolTip: string);
begin
  add_json(Key, ImageFileName, FilePath, ToolTip, True, nil);
end;

procedure TCfgForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
  begin
    text_edit.Enabled := false;
    imgEdit1.Enabled := True;
  end
  else
  begin
    text_edit.Enabled := True;
    imgEdit1.Enabled := false;
  end;
end;

procedure TCfgForm.ClearInputs;
begin
  imgEdit1.Text := '';
  text_edit.Text := '';
  tip.Text := '';
  filedit.Text := '';
  xchange := True;
end;

procedure TCfgForm.fileditSubLabelDblClick(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
begin
  OpenDlg := TFileOpenDialog.Create(nil);
  try
    if OpenDlg.Execute then
    begin
      filedit.Text := OpenDlg.FileName;
    end;
  finally
    OpenDlg.Free;
  end;
end;

procedure TCfgForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin

  g_core.nodes.is_configuring := false;
  file_map.Free;
end;

procedure TCfgForm.FormMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
begin
  if WheelDelta < 0 then
    ScrollBox1.Perform(WM_VSCROLL, SB_LINEDOWN, 0)
  else
    ScrollBox1.Perform(WM_VSCROLL, SB_LINEUP, 0);
  if ActiveControl is TComboBox then
    if not TComboBox(ActiveControl).DroppedDown then
      Handled := True;
end;

procedure TCfgForm.FormShow(Sender: TObject);
var
  values: TArray<string>;
  v: TSettingItem;
  tmp_key: string;
begin
EnableNonClientDpiScaling(Handle);
  Apps := TStartMenuApps.GetApps;
  for App in Apps do

    show_aapp(App.Path, App.Name);
  filedit.Text := '';
  file_map := TDictionary<string, string>.Create;

  ve1.Strings.Clear;

  for tmp_key in g_core.json.Settings.keys do
  begin

    if g_core.json.Settings.TryGetValue(tmp_key, v) then
      if (v.Is_path_valid) then
      begin
        file_map.TryAdd(tmp_key, v.image_file_name + ',' + v.FilePath + ',' + v.tool_tip);

        ve1.InsertRow(v.image_file_name, v.tool_tip, True);

      end;
  end;

  xchange := false;

  text_edit.Text := '';
  tip.Text := '无';
  imgEdit1.Text := '';

  SetWindowCornerPreference(Handle);
end;

procedure TCfgForm.imgEdit1DblClick(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
begin
  SendToBack();
  OpenDlg := TFileOpenDialog.Create(nil);

  try
    if OpenDlg.Execute then
    begin
      filedit.Text := OpenDlg.FileName;
    end;

  finally
    OpenDlg.Free;
    BringToFront;
  end;
end;

procedure TCfgForm.rbimgClick(Sender: TObject);
begin
  text_edit.Enabled := false;
  imgEdit1.Enabled := True;

end;

procedure TCfgForm.rbtxtClick(Sender: TObject);
begin
  text_edit.Enabled := True;
  imgEdit1.Enabled := false;

end;

procedure TCfgForm.ScrollBox1MouseEnter(Sender: TObject);
begin
  Screen.Cursor := crHandPoint;
end;

procedure TCfgForm.ScrollBox1MouseLeave(Sender: TObject);
begin
  Screen.Cursor := crDefault;
end;

procedure TCfgForm.ve1DblClick(Sender: TObject);
var
  pp, key1, Hash: string;
  inx: Integer;
begin
  pp := ve1.Keys[ve1.Row];
  if pp = '' then
    Exit;

  key1 := pp;

  Hash := THashMD5.GetHashString(key1);

  for var Key in file_map.Keys do
  begin
    if Key = Hash then
    begin
      if ve1.FindRow(pp, inx) then
      begin
        ve1.DeleteRow(inx);
        file_map.Remove(Key);

        remove_json(Key);
        del_json_value('settings', Key);
      end;
    end;

  end;

end;

end.

