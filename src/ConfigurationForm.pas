unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  u_json, System.IniFiles, u_debug, Vcl.Imaging.pngimage,
  System.Generics.Collections, Vcl.Menus, Vcl.Mask, System.Hash;

type
  TCfgForm = class(TForm)
    ve1: TValueListEditor;
    Button1: TButton;
    imgEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    text_edit: TLabeledEdit;
    RadioGroup1: TRadioGroup;
    rbimg: TRadioButton;
    rbtxt: TRadioButton;
    tip: TLabeledEdit;
    procedure Buttoaction_translator(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgEdit1DblClick(Sender: TObject);
    procedure LabeledEdit2DblClick(Sender: TObject);
    procedure ve1DblClick(Sender: TObject);
    procedure rbtxtClick(Sender: TObject);
    procedure rbimgClick(Sender: TObject);
  private
    file_map: TDictionary<string, string>;

  public
  end;

var
  xchange: Boolean = false;

implementation

{$R *.dfm}

uses
  ApplicationMain, core, GDIPAPI, GDIPOBJ, System.UITypes;

function GenerateTextImage(txt: string; y: Integer): string;
var
  vPng: TPngImage;
  font: TGPFont;
  sf: TGPStringFormat;
  whiteBrush: TGPSolidBrush;
  Graphics: TGPGraphics;
  textLength: Integer;
  middleX, middleY: Single;
begin

  vPng := TPngImage.Create;
  try
    vPng.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\template.png');

    Graphics := TGPGraphics.Create(vPng.Canvas.Handle);
    try
      Graphics.SetSmoothingMode(SmoothingModeHighQuality);
      Graphics.SetInterpolationMode(InterpolationModeHighQualityBicubic);
      Graphics.TranslateTransform(0, 0);
      sf := TGPStringFormat.Create();

      try
        Graphics.Clear(TAlphaColorRec.Black);

        whiteBrush := TGPSolidBrush.Create(MakeColor(255, 245, 245, 245)); // White

        try
          font := TGPFont.Create('黑体', 35);

          try
            textLength := Length(txt);
            middleX := vPng.Width / 2;
            middleY := y;

            case textLength of
              4:
                begin

                  Graphics.DrawString(txt[2] + txt[3], -1, font, MakePoint(0, middleY * 0.6), sf, whiteBrush);

                  Graphics.DrawString(txt[1], 1, font, MakePoint(middleX - 40, middleY - 60), sf, whiteBrush);

                  Graphics.DrawString(txt[4], 1, font, MakePoint(middleX - 40, middleY + 20), sf, whiteBrush);
                end;
              3:
                begin
                  Graphics.DrawString(txt[2], 1, font, MakePoint(middleX - 20, middleY), sf, whiteBrush);
                  Graphics.DrawString(txt[3], 1, font, MakePoint(middleX + 20, middleY), sf, whiteBrush);

                  Graphics.DrawString(txt[1], 1, font, MakePoint(middleX - 40, middleY - 40), sf, whiteBrush);
                end;
              2:
                begin

                  Graphics.DrawString(txt, -1, font, MakePoint(0, middleY * 0.6), sf, whiteBrush);
                end;
              1:
                begin
                  var font1 := TGPFont.Create('黑体', 40);
                  Graphics.DrawString(txt, -1, font1, MakePoint(middleX - 40, y * 0.65), sf, whiteBrush);
                  Graphics.DrawString(txt, 1, font1, MakePoint(middleX - 40, middleY * 0.6), sf, whiteBrush);
                  font1.Free;
                end
            else
              begin
                var font1 := TGPFont.Create('黑体', 20);
                Graphics.DrawString(txt, -1, font1, MakePoint(0, y * 0.6), sf, whiteBrush);
                Graphics.DrawString(txt, -1, font1, MakePoint(1, y * 0.65), sf, whiteBrush);
                font1.Free;
              end;
            end;

            Result := ExtractFilePath(ParamStr(0)) + 'img\' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.png';
            vPng.SaveToFile(Result);

          finally
            font.Free;
          end;
        finally
          whiteBrush.Free;
        end;
      finally
        sf.Free;
      end;

    finally
      Graphics.Free;
    end;
  finally
    vPng.Free;
  end;
end;

procedure TCfgForm.Buttoaction_translator(Sender: TObject);
var
  hdc1: hdc;
  hg, y: Integer;
  imgpath, key1, Hash: string;
  tmps: string;
begin
  tmps := LabeledEdit2.Text;
  LabeledEdit2.Text := tmps.Replace('=', '');
  //图片
  if rbimg.Checked then
  begin
    if (Trim(imgEdit1.Text) <> '') and (Trim(LabeledEdit2.Text) <> '') then
    begin

      g_core.utils.CopyFileToFolder(Trim(imgEdit1.Text), ExtractFilePath(ParamStr(0)) + 'img');

      key1 := ExtractFileName(Trim(imgEdit1.Text));

      Hash := THashMD5.GetHashString(key1);

      if file_map.TryAdd(Hash, key1 + ',' + Trim(LabeledEdit2.Text) + ',' + Trim(tip.text)) then
      begin
        add_json(Hash, key1, Trim(LabeledEdit2.Text), Trim(tip.text), True, nil);

        ve1.InsertRow(key1, Trim(tip.Text), True);
        imgEdit1.Text := '';
        text_edit.Text := '';
        LabeledEdit2.Text := '';
        tip.Text := '';
        xchange := True;
      end;
    end;
  end
  //文字
  else if rbtxt.Checked then
  begin
    if (Trim(LabeledEdit2.Text) <> '') and (Trim(text_edit.Text) <> '') then
    begin

      hdc1 := GetDC(text_edit.Handle);
      hg := GetFontHeight(hdc1);
      ReleaseDC(Handle, hdc1);
      y := Round((128 - hg) div 2);

      imgpath := GenerateTextImage(Trim(text_edit.Text), y);
      g_core.utils.CopyFileToFolder(Trim(imgpath), ExtractFilePath(ParamStr(0)) + 'img');

      key1 := ExtractFileName(Trim(imgpath));

      Hash := THashMD5.GetHashString(key1);

      if file_map.TryAdd(Hash, key1 + ',' + Trim(LabeledEdit2.Text) + ',' + Trim(tip.Text)) then
      begin
        add_json(Hash, key1, Trim(LabeledEdit2.Text), Trim(tip.text), True, nil);
        ve1.InsertRow(key1, Trim(tip.Text), True);
        imgEdit1.Text := '';
        text_edit.Text := '';
        LabeledEdit2.Text := '';
        tip.Text := '';
        xchange := True;
      end

    end

  end;

end;

procedure TCfgForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if xchange then
  begin
    Form1.ConfigureLayout;
  end;
  g_core.nodes.is_configuring := false;
  file_map.Free;
end;

procedure TCfgForm.FormShow(Sender: TObject);
var
  values: TArray<string>;
  v: TSettingItem;
  tmp_key: string;
begin
  Form1.Font.Name := Screen.Fonts.Text;
  Form1.Font.Size := 9;
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
  LabeledEdit2.Text := '';
end;

(* procedure TCfgForm.imgEdit1DblClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);

  try
    OpenDlg.Filter := '文件(*.png)|*.png';
    OpenDlg.DefaultExt := '*.png';

    if OpenDlg.Execute then
    begin
      imgEdit1.Text := OpenDlg.FileName;
    end;

  finally
    OpenDlg.Free;
  end;
end;

procedure TCfgForm.LabeledEdit2DblClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  try
    OpenDlg.Filter := '文件(*.EXE)|*.EXE';
    OpenDlg.DefaultExt := '*.EXE';

    if OpenDlg.Execute then
    begin
      LabeledEdit2.Text := OpenDlg.FileName;
    end;
  finally
    OpenDlg.Free;
  end;
end; *)

procedure TCfgForm.imgEdit1DblClick(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
begin
  OpenDlg := TFileOpenDialog.Create(nil);

  try
    if OpenDlg.Execute then
    begin
      imgEdit1.Text := OpenDlg.FileName;
    end;

  finally
    OpenDlg.Free;
  end;
end;

procedure TCfgForm.LabeledEdit2DblClick(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
begin
  OpenDlg := TFileOpenDialog.Create(nil);
  try
    if OpenDlg.Execute then
    begin
      LabeledEdit2.Text := OpenDlg.FileName;
    end;
  finally
    OpenDlg.Free;
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
        del_json_value('settings',Key);
      end;
    end;

  end;

end;

end.

