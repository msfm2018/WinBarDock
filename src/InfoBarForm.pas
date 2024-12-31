unit InfoBarForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Winapi.ShellAPI, Vcl.ComCtrls, ActiveX, shlobj, u_json,
  ImgButton, System.JSON, u_debug, comobj, Vcl.ImgList, Vcl.Menus,
  System.ImageList, utils, Vcl.StdCtrls;

type
  TbottomForm = class(TForm)
    ImgList: TImageList;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    Panel2: TPanel;
    Button3: TButton;
    Button4: TButton;
    Button5: TButton;
    Button6: TButton;
    Button7: TButton;
    Button8: TButton;
    CheckBox1: TCheckBox;
    procedure FormShow(Sender: TObject);

    procedure LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure Button6Click(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure Button3Click(Sender: TObject);
    procedure CheckBox1Click(Sender: TObject);
  private
    into_snap_windows: Boolean;

 

    procedure snap_top_windows;
    procedure closebtnClick(Sender: TObject);
    procedure resetbtnClick(Sender: TObject);

  end;

var
  bottomForm: TbottomForm;
  closebtn: TImgButton;
  resetbtn: TImgButton;

implementation

{$R *.dfm}

uses
  core, ConfigurationForm;

procedure sort_layout(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  bottomForm.snap_top_windows();
end;

procedure TbottomForm.snap_top_windows();
var
  lp: tpoint;
begin
  if g_core.nodes.is_configuring then
    exit;

  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) and not into_snap_windows then
  begin
    into_snap_windows := true;

    if g_core.json.Config.layout = 'left' then
    begin
      bottomForm.Left := -bottomForm.Width + 4;
    end
    else
    begin

      if left < Screen.WorkAreaWidth - bottomForm.Width then
      begin
        top := 0;
        Left := Screen.WorkAreaWidth - bottomForm.Width + 40;

      end;
    end;

    into_snap_windows := false;

  end
  else if g_core.json.Config.layout = 'left' then
  begin
    bottomForm.Left := 0;
  end
  else
    Left := Screen.WorkAreaWidth - bottomForm.Width
end;

procedure TbottomForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  KillTimer(Handle, 10);
end;

procedure TbottomForm.FormShow(Sender: TObject);
begin
  g_core.utils.round_rect(width, height, Handle);
  into_snap_windows := false;
  SetTimer(Handle, 10, 100, @sort_layout);
  DragAcceptFiles(Handle, True);

  SetWindowCornerPreference(Handle);

  closebtn := TImgButton.Create(self);
  closebtn.Parent := Panel2;

  closebtn.SetBounds(40, Panel2.Height - 40, 32, 32);
  closebtn.Image.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/close_hover.png');
  closebtn.Image1.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/close.png');
  closebtn.OnClick := closebtnClick;
  closebtn.Cursor := crHandpoint;

  resetbtn := TImgButton.Create(self);
  resetbtn.Parent := Panel2;
  resetbtn.SetBounds(0, Panel2.Height - 40, 32, 32);
  resetbtn.Image.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/reset_hover.png');
  resetbtn.Image1.LoadFromFile(ExtractFilePath(ParamStr(0)) + '/imgapp/reset.png');
  resetbtn.OnClick := resetbtnClick;
  resetbtn.Cursor := crHandpoint
end;

procedure TbottomForm.resetbtnClick(Sender: TObject);
begin
  SystemShutdown(True);
end;

procedure TbottomForm.closebtnClick(Sender: TObject);
begin
  SystemShutdown(false);
end;

procedure TbottomForm.LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
end;

procedure TbottomForm.Button3Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure TbottomForm.Button4Click(Sender: TObject);
begin
  g_core.json.Config.style := 'style-2';
end;

procedure TbottomForm.Button5Click(Sender: TObject);
begin
  g_core.json.Config.style := 'style-1';
end;

procedure TbottomForm.Button6Click(Sender: TObject);
begin
  g_core.utils.launch_app(g_core.json.Config.translator);
end;

procedure TbottomForm.Button7Click(Sender: TObject);
var
  vobj: TObject;
begin

  vobj := g_core.find_object_by_name('cfgForm');
  g_core.nodes.is_configuring := true;
  SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  TCfgForm(vobj).Show;
//    TCfgForm(vobj).ShowModal;
end;

procedure TbottomForm.Button8Click(Sender: TObject);
var
  OpenDlg: TFileOpenDialog;
begin
  OpenDlg := TFileOpenDialog.Create(nil);

  if OpenDlg.Execute then
    set_json_value('config', 'shortcut', OpenDlg.FileName);

  OpenDlg.Free;

end;

procedure TbottomForm.CheckBox1Click(Sender: TObject);
begin
  if CheckBox1.Checked then
  begin

    set_json_value('config', 'definestart', 'true');

    Caption := 'selfdefinestartmenu';

  end
  else
  begin
    set_json_value('config', 'definestart', 'false');
    Caption := 'toolform';
  end;
end;

end.

