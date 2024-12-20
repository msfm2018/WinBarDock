unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  utils, u_json, System.IniFiles, u_debug, Vcl.Imaging.pngimage,
  System.Generics.Collections, Vcl.Menus, Vcl.Mask, System.Hash;

type
  TCfgForm = class(TForm)
    ve1: TValueListEditor;
    Button1: TButton;
    imgEdit1: TLabeledEdit;
    text_edit: TLabeledEdit;
    RadioGroup1: TRadioGroup;
    rbimg: TRadioButton;
    rbtxt: TRadioButton;
    tip: TLabeledEdit;
    filedit: TLabeledEdit;
    ComboBox1: TComboBox;
    procedure Buttoaction_translator(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgEdit1DblClick(Sender: TObject);
    procedure ve1DblClick(Sender: TObject);
    procedure rbtxtClick(Sender: TObject);
    procedure rbimgClick(Sender: TObject);
    procedure fileditSubLabelDblClick(Sender: TObject);
  private
    file_map: TDictionary<string, string>;
    procedure AddFileInfoToJson(const Key, ImageFileName, FilePath, ToolTip: string);
    procedure ClearInputs;

  public
  end;

var
  xchange: Boolean = false;

implementation

{$R *.dfm}

uses
  ApplicationMain, core, GDIPAPI, GDIPOBJ, System.UITypes;

procedure TCfgForm.Buttoaction_translator(Sender: TObject);
var
  key1, key2, Hash, imgpath: string;
  utf8Text, ansi_path: PAnsiChar;
begin
  if rbimg.Checked then
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
    end;
  end
  else if rbtxt.Checked then
  begin
    if (Trim(text_edit.Text) <> '') and (Trim(filedit.Text) <> '') then
    begin
      imgpath := ExtractFilePath(ParamStr(0)) + 'img\' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.png';

      utf8Text := PAnsiChar(UTF8Encode(Trim(text_edit.Text)));

      ansi_path := PAnsiChar(UTF8Encode(imgpath));
      if ComboBox1.Text = '样式1' then
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
    end;
  end;

end;

procedure TCfgForm.AddFileInfoToJson(const Key, ImageFileName, FilePath, ToolTip: string);
begin
  add_json(Key, ImageFileName, FilePath, ToolTip, True, nil);
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

procedure TCfgForm.FormShow(Sender: TObject);
var
  values: TArray<string>;
  v: TSettingItem;
  tmp_key: string;
begin
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

