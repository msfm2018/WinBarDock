unit cfg_form;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  System.Generics.Collections, Vcl.Menus, Vcl.Mask, System.Hash,
  Vcl.Samples.Spin;

type
  TCfgForm = class(TForm)
    ValueListEditor1: TValueListEditor;
    Button1: TButton;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    Button2: TButton;
    Button3: TButton;
    Edit1: TSpinEdit;
    procedure Button1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure LabeledEdit1DblClick(Sender: TObject);
    procedure LabeledEdit2DblClick(Sender: TObject);
    procedure ValueListEditor1DblClick(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
  private
    procedure update_db;
  public
  end;

var
//  fileMap: TDictionary<string, string>;
  oldNum: Integer = 0;
  oldValue: Integer = 0;

var
  reLayout: Boolean = false;
  reStore:Boolean=false;

implementation

{$R *.dfm}
uses
  main, core;

procedure TCfgForm.update_db();
var
  hash: string;
  v: string;
begin
  g_core.db.itemdb.clean();
  g_core.db.itemdb.clean(false);

  for var key in  g_core.utils.fileMap.Keys do
  begin
    v := '';
     g_core.utils.fileMap.TryGetValue(key, v);

    hash := THashMD5.GetHashString(key);
       //k v 存储在不同表中
    g_core.db.itemdb.SetVarValue(hash, key);
    g_core.db.itemdb.SetVarValue(hash, v, false);

  end;



end;

procedure TCfgForm.Button1Click(Sender: TObject);
begin
  if (Trim(LabeledEdit1.Text) <> '') and (Trim(LabeledEdit2.Text) <> '') then
  begin
     g_core.utils.fileMap.TryAdd(Trim(LabeledEdit1.Text), Trim(LabeledEdit2.Text));
    ValueListEditor1.InsertRow(ExtractFileName(Trim(LabeledEdit1.Text)), ExtractFileName(Trim(LabeledEdit2.Text)), True);
    LabeledEdit1.Text := '';
    LabeledEdit2.Text := '';
  end;

end;

procedure TCfgForm.Button2Click(Sender: TObject);
begin
  g_core.nodes.nodeWidth := strtoint(edit1.text);
  g_core.nodes.nodeHeight := strtoint(edit1.text);
  g_core.db.cfgDb.SetVarValue('ih', StrToIntDef(edit1.Text, 118));
end;

procedure TCfgForm.Button3Click(Sender: TObject);
begin
    //初始化数据
  g_core.db.cfgDb.SetVarValue('ih', 64);      
  reLayout := true;
//  Close();
end;

procedure TCfgForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  if (oldNum <>  g_core.utils.fileMap.Count) or reLayout or (edit1.Text <> oldValue.ToString) then
  begin

    update_db();
    Form1.layout;
  end;
  g_core.nodes.isCfging := False;
//  fileMap.Clear;
//  fileMap.Free;

end;

procedure TCfgForm.FormShow(Sender: TObject);
begin
//  fileMap := TDictionary<string, string>.create;
  ValueListEditor1.Strings.Clear;
  var vvvv := g_core.db.itemdb.GetKeys;
  for var i := 0 to vvvv.Count - 1 do
  begin
    var a := g_core.db.itemdb.GetString(vvvv[i]);
    var b := g_core.db.itemdb.GetString(vvvv[i], false);
     g_core.utils.fileMap.TryAdd(a, b);
    var imgPath := ExtractFilename(a);
    var appPath := ExtractFilename(b);
    ValueListEditor1.InsertRow(imgPath, appPath, True);
  end;

  /// 后面关闭 数据是否变化作用
  oldNum := vvvv.Count;
  oldValue := g_core.db.cfgDb.GetInteger('ih');
  Edit1.Text := oldValue.ToString;
  reLayout := false;
end;

procedure TCfgForm.LabeledEdit1DblClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  with OpenDlg do
  begin
    Filter := '协议文件(*.png)|*.png';
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
    Filter := '协议文件(*.EXE)|*.EXE';
    DefaultExt := '*.EXE';

    if Execute then
    begin
      LabeledEdit2.Text := FileName;
    end;
  end;
end;

procedure TCfgForm.ValueListEditor1DblClick(Sender: TObject);
begin
  var pp := ValueListEditor1.Keys[ValueListEditor1.Row];
  if pp = '' then
    Exit;
  if MessageBox(Handle, '你确定要删除选项？', '信息提示', MB_OKCANCEL + MB_ICONQUESTION) = IDOK then
  begin
    var inx: Integer;

    for var key in  g_core.utils.fileMap.Keys do
    begin
      if ExtractFileName(key) = pp then
      begin
        if ValueListEditor1.FindRow(pp, inx) then
        begin
          ValueListEditor1.DeleteRow(inx);
          var key_ := HashName(pansichar(key)).ToString;
           g_core.utils.fileMap.Remove(key);
          g_core.db.itemdb.DeleteValue(key_);
          g_core.db.itemdb.DeleteValue(key_, false);

        end;
      end;

    end;

  end;

end;
initialization
//  fileMap := TDictionary<string, string>.create;

  finalization
//  fileMap.free;
end.

