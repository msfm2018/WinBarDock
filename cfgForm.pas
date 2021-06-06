unit cfgForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ComCtrls, Vcl.Grids, Vcl.ValEdit, Vcl.StdCtrls, Vcl.ExtCtrls, Vcl.Buttons,
  System.Generics.Collections, core, Vcl.Menus;

type
  Tmycfg = class(TForm)
    ValueListEditor1: TValueListEditor;
    Button1: TButton;
    LabeledEdit1: TLabeledEdit;
    LabeledEdit2: TLabeledEdit;
    BitBtn1: TBitBtn;
    BitBtn2: TBitBtn;
    procedure Button1Click(Sender: TObject);
    procedure BitBtn1Click(Sender: TObject);
    procedure BitBtn2Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormShow(Sender: TObject);
    procedure LabeledEdit1DblClick(Sender: TObject);
    procedure LabeledEdit2DblClick(Sender: TObject);
    procedure ValueListEditor1DblClick(Sender: TObject);
  private
    procedure update_db;
  public
  end;

var
  mycfg: Tmycfg;

implementation

{$R *.dfm}
uses
  tsForm;

procedure Tmycfg.BitBtn1Click(Sender: TObject);
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

procedure Tmycfg.BitBtn2Click(Sender: TObject);
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

procedure tmycfg.update_db();
begin
  g_core.db.filesDB.clean();
  for var i := 1 to ValueListEditor1.RowCount - 1 do
  begin

    var pp := trim(ValueListEditor1.Keys[i]);

    if (pp = '') or (trim(ValueListEditor1.Values[pp]) = '') then
      exit;

    g_core.db.filesDB.SetVarValue(pp, trim(ValueListEditor1.Values[pp]));

  end;
end;

procedure Tmycfg.Button1Click(Sender: TObject);
begin
  if (Trim(LabeledEdit1.Text) <> '') or (Trim(LabeledEdit2.Text) <> '') then
  begin

    ValueListEditor1.InsertRow(LabeledEdit1.Text, LabeledEdit2.Text, True);

  end;
  update_db();
  LabeledEdit1.Text := '';
  LabeledEdit2.Text := '';

end;

procedure Tmycfg.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  update_db();
  Form1.init;
  gg.app_cfging := False;
  FreeAndNil(mycfg);
end;

procedure Tmycfg.FormShow(Sender: TObject);
begin
  var vvvv := g_core.db.filesDB.GetKeys;
  for var i := 0 to vvvv.Count - 1 do
  begin
    ValueListEditor1.InsertRow(vvvv[i], g_core.db.filesDB.GetString(vvvv[i]), True);
  end;

end;

procedure Tmycfg.LabeledEdit1DblClick(Sender: TObject);
begin
  BitBtn1Click(Self);
end;

procedure Tmycfg.LabeledEdit2DblClick(Sender: TObject);
begin
  BitBtn2Click(Self);
end;

procedure Tmycfg.ValueListEditor1DblClick(Sender: TObject);
begin
  var pp := ValueListEditor1.Keys[ValueListEditor1.Row];
  if pp = '' then
    Exit;
  if MessageBox(Handle, '你确定要删除选项？', '信息提示', MB_OKCANCEL + MB_ICONQUESTION) = IDOK then
  begin
    var inx: Integer;
    if ValueListEditor1.FindRow(pp, inx) then
    begin
      ValueListEditor1.DeleteRow(inx);
      g_core.db.filesDB.DeleteValue(pp);
    end;
  end;

end;

end.

