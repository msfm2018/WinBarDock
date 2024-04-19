﻿unit ConfigurationForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Math,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  u_debug, Vcl.Imaging.pngimage, System.Generics.Collections, Vcl.Menus,
  Vcl.Mask, System.Hash, Vcl.Samples.Spin;

type
  TCfgForm = class(TForm)
    ve1: TValueListEditor;
    Button1: TButton;
    imgEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    LabeledEdit3: TLabeledEdit;
    RadioGroup1: TRadioGroup;
    rbimg: TRadioButton;
    rbtxt: TRadioButton;
    Label1: TLabel;
    b1: TColorBox;
    Label2: TLabel;
    b2: TColorBox;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure imgEdit1DblClick(Sender: TObject);
    procedure LabeledEdit2DblClick(Sender: TObject);
    procedure ve1DblClick(Sender: TObject);
    procedure rbtxtClick(Sender: TObject);
    procedure rbimgClick(Sender: TObject);
  private
    procedure update_db;
  public
  end;

var
  OldNum: Integer = 0;
  OldValue: Integer = 0;
  xchange: Boolean = false;

implementation

{$R *.dfm}

uses
  ApplicationMain, core, GDIPAPI, GDIPOBJ, System.UITypes;

function text_outa(txt: string; y, gc1, gc2: TColor): string;
var
  vPng: TPngImage;
  aclStartColor, aclEndColor: TAlphaColor;
  font: TGPFont;
  sf: TGPStringFormat;
  b2: TGPLinearGradientBrush;
  Graphics: TGPGraphics;
begin

  vPng := TPngImage.Create;
  vPng.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\template.png');

  Graphics := TGPGraphics.Create(vPng.Canvas.Handle);
  Graphics.SetSmoothingMode(SmoothingModeHighQuality);
  Graphics.TranslateTransform(0, 0);
  sf := TGPStringFormat.Create();

  aclStartColor := TAlphaColorF.Create(GetRValue(gc1), GetGValue(gc1), GetBValue(gc1)).ToAlphaColor;

  aclEndColor := TAlphaColorF.Create(GetRValue(gc2), GetGValue(gc2), GetBValue(gc2)).ToAlphaColor;

  b2 := TGPLinearGradientBrush.Create(MakePoint(0, 0), MakePoint(vPng.Width, vPng.Height), aclStartColor, aclEndColor);
  Graphics.FillRectangle(b2, 0, 0, vPng.Width, vPng.Height);

  var b3 := TGPLinearGradientBrush.Create(MakePoint(0, 0), MakePoint(vPng.Width, vPng.Height), aclLime, aclRed);

  font := TGPFont.Create('黑体', 40);
  Graphics.DrawString(txt, -1, font, MakePoint(0, y * 0.6), sf, b3);
  Graphics.DrawString(txt, -1, font, MakePoint(1, y * 0.65), sf, b3);

  Result := '.\img\' + FormatDateTime('yyyymmddhhnnsszzz', Now) + '.png';
  vPng.SaveToFile(Result);
  vPng.Free;
  Graphics.Free;
  font.Free;
  sf.free;
  b3.free;
  b2.free;
end;

procedure TCfgForm.update_db();
var
  Hash: string;
  v: string;
begin
  g_core.dbmgr.itemdb.clean();
  g_core.dbmgr.itemdb.clean(false);

  for var key in g_core.utils.fileMap.Keys do
  begin
    v := '';
    if g_core.utils.fileMap.TryGetValue(key, v) then
    begin

      Hash := THashMD5.GetHashString(key);
      // k v 存储在不同表中
      g_core.dbmgr.itemdb.SetVarValue(Hash, key);
      g_core.dbmgr.itemdb.SetVarValue(Hash, v, false);
    end;

  end;

end;

procedure TCfgForm.Button1Click(Sender: TObject);
begin
  if rbimg.Checked then
  begin
    if (Trim(imgEdit1.Text) <> '') and (Trim(LabeledEdit2.Text) <> '') then
    begin
      if g_core.utils.fileMap.TryAdd(Trim(imgEdit1.Text), Trim(LabeledEdit2.Text)) then
      begin
        if (Trim(imgEdit1.Text).Contains('http')) then
          ve1.InsertRow((Trim(imgEdit1.Text)), Trim(LabeledEdit2.Text), True)
        else
          ve1.InsertRow(ExtractFileName(Trim(imgEdit1.Text)), ExtractFileName(Trim(LabeledEdit2.Text)), True);
        imgEdit1.Text := '';
        LabeledEdit3.Text := '';
        LabeledEdit2.Text := '';
        xchange := True;
      end;
    end;
  end
  else if rbtxt.Checked then
  begin
    if (Trim(LabeledEdit2.Text) <> '') and (Trim(LabeledEdit3.Text) <> '') then
    begin

      var hg := Label1.canvas.TextHeight(Trim(LabeledEdit3.Text));

      var y := Round((128 - hg) div 2);
      var imgpath := text_outa(Trim(LabeledEdit3.Text), y, b1.Selected, b2.Selected);

      if g_core.utils.fileMap.TryAdd(imgpath, Trim(LabeledEdit2.Text)) then
      begin
        if (Trim(imgpath).Contains('http')) then
          ve1.InsertRow((Trim(imgpath)), Trim(LabeledEdit2.Text), True)
        else
          ve1.InsertRow(ExtractFileName(Trim(imgpath)), ExtractFileName(Trim(LabeledEdit2.Text)), True);
        imgEdit1.Text := '';
        LabeledEdit3.Text := '';
        LabeledEdit2.Text := '';
        xchange := True;
      end

    end

  end;

end;

procedure TCfgForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (OldNum <> g_core.utils.fileMap.Count) or xchange then
  begin

    update_db();
    Form1.layout;
  end;
  g_core.nodes.Is_cfging := false;

end;

procedure TCfgForm.FormShow(Sender: TObject);
var
  appPath, imgpath: string;
begin
  ve1.Strings.Clear;
  var Keys := g_core.dbmgr.itemdb.GetKeys;
  for var i := 0 to Keys.Count - 1 do
  begin
    var key := Keys[i];
    var value := g_core.dbmgr.itemdb.GetString(key);
    var altValue := g_core.dbmgr.itemdb.GetString(key, false);
    g_core.utils.fileMap.TryAdd(value, altValue);
    imgpath := ExtractFileName(value);
    if altValue.Contains('http') then
      appPath := altValue
    else
      appPath := ExtractFileName(altValue);
    ve1.InsertRow(imgpath, appPath, True);
  end;

  /// 后面关闭 数据是否变化作用
  OldNum := Keys.Count;
  OldValue := g_core.dbmgr.cfgDb.GetInteger('ih');

  xchange := false;

end;

procedure TCfgForm.imgEdit1DblClick(Sender: TObject);
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
      imgEdit1.Text := FileName;
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

procedure TCfgForm.rbimgClick(Sender: TObject);
begin
  LabeledEdit3.Enabled := false;
  imgEdit1.Enabled := True;
end;

procedure TCfgForm.rbtxtClick(Sender: TObject);
begin
  LabeledEdit3.Enabled := True;
  imgEdit1.Enabled := false;
end;

procedure TCfgForm.ve1DblClick(Sender: TObject);
begin
  var pp := ve1.Keys[ve1.Row];
  if pp = '' then
    Exit;
  begin
    var inx: Integer;

    for var key in g_core.utils.fileMap.Keys do
    begin
      if ExtractFileName(key) = pp then
      begin
        if ve1.FindRow(pp, inx) then
        begin
          ve1.DeleteRow(inx);
          var key_ := HashName(pansichar(key)).ToString;
          g_core.utils.fileMap.Remove(key);
          g_core.dbmgr.itemdb.DeleteValue(key_);
          g_core.dbmgr.itemdb.DeleteValue(key_, false);
          xchange := True;
        end;
      end;

    end;

  end;

end;

end.

