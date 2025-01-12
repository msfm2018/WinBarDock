unit InfoBarForm;

interface

uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants,
  System.Classes, Vcl.Graphics, Vcl.Controls, Vcl.Forms, Vcl.Dialogs,
  Vcl.ExtCtrls, Winapi.ShellAPI, Vcl.ComCtrls, ActiveX, shlobj, u_json, ImgPanel,
  ImgButton, System.JSON, u_debug, comobj, Vcl.ImgList, Vcl.Menus,
  System.ImageList, utils, Vcl.StdCtrls;

type
  TbottomForm = class(TForm)
    ImgList: TImageList;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    ScrollBox1: TScrollBox;
    procedure FormShow(Sender: TObject);

    procedure LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  private
    into_snap_windows: Boolean;

    procedure snap_top_windows;

    procedure show_aapp(Path, FileName: string);
    procedure PanelMouseEnter(Sender: TObject);
    procedure PanelMouseLeave(Sender: TObject);
    procedure PanelDblClick(Sender: TObject);

  end;

var
  bottomForm: TbottomForm;
  closebtn: TImgButton;
  resetbtn: TImgButton;
   oldcolor:tcolor;
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

procedure TbottomForm.show_aapp(Path, FileName: string);
var
  Panel: TImgPanel;
  Image: TImage;
begin
  try
    ScrollBox1.VertScrollBar.Visible := True; // 启用垂直滚动条

    Panel := TImgPanel.Create(Scrollbox1);
    Panel.Parent := ScrollBox1;
    Panel.Align := alTop; // 设置为垂直排列
    Panel.Height := 60;   // 每个 Panel 的高度
    Panel.BevelOuter := bvNone;
    Panel.ParentColor := False;
    Panel.StyleElements := [seClient];
    Panel.extendA := FileName;
    Panel.extendB := Path;
//    Panel.Name := FileName;
      oldcolor:=Panel.Color;
    // 创建显示图标的 Image 控件
    Image := TImage.Create(Panel);
    Image.Parent := Panel;
    Image.Picture.LoadFromFile(Path);
    Image.Width := 46;  // 设置图标宽度
    Image.Height := 46; // 设置图标高度
    Image.Stretch := True;
    Image.Name := FileName;
    Image.Cursor := crHandPoint;

    // 图标垂直和水平居中
    Image.Left := (Panel.Width - Image.Width) div 2;
    Image.Top := (Panel.Height - Image.Height) div 2;

    // 绑定事件
    Image.OnClick := PanelDblClick;
    Panel.OnMouseEnter := PanelMouseEnter;
    Panel.OnMouseLeave := PanelMouseLeave;
    Panel.OnClick := PanelDblClick;
  finally

  end;
end;

procedure TbottomForm.PanelDblClick(Sender: TObject);
var
  Identifier: string;
var
  OpenDlg: TFileOpenDialog;
var
  vobj: TObject;
begin
  if Sender is timage then
    Identifier := string(StrPas(PChar(timage(Sender).name)));
  if Sender is TImgPanel then
    Identifier := string(StrPas(PChar(TImgPanel(Sender).name)));

  try
    if Identifier = '关机' then
    begin
      SystemShutdown(false);
    end
    else if Identifier = '重启' then
    begin
      SystemShutdown(true);
    end
    else if Identifier = '翻译' then
      g_core.utils.launch_app(g_core.json.Config.translator)
    else if Identifier = '快捷' then
    begin

      OpenDlg := TFileOpenDialog.Create(nil);

      if OpenDlg.Execute then
        set_json_value('config', 'shortcut', OpenDlg.FileName);

      OpenDlg.Free;

    end
    else if Identifier = '配置' then
    begin
      vobj := g_core.find_object_by_name('cfgForm');
      g_core.nodes.is_configuring := true;
      SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
      TCfgForm(vobj).Show;
    end
    else if Identifier = '退出' then
      Application.Terminate;
  finally
    StrDispose(PChar(TImgPanel(Sender).Tag)); // 释放字符串内存
  end;

//    g_core.json.Config.style := 'style-2';   g_core.json.Config.style := 'style-1';
end;

procedure TbottomForm.PanelMouseEnter(Sender: TObject);
begin
  (Sender as TImgPanel).color := $f5f5f5;

end;

procedure TbottomForm.PanelMouseLeave(Sender: TObject);
begin

  (Sender as TImgPanel).color :=oldcolor;

end;

procedure TbottomForm.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  KillTimer(Handle, 10);
end;

procedure TbottomForm.FormShow(Sender: TObject);
var
  MainFormCenter: TPoint;
begin
//决定了 要不要调用 hook start
  caption := 'selfdefinestartmenu';

  Width := 60;
  DoubleBuffered := true;
  g_core.utils.round_rect(width, height, Handle);
  into_snap_windows := false;
  SetTimer(Handle, 10, 100, @sort_layout);
  DragAcceptFiles(Handle, True);

  SetWindowCornerPreference(Handle);
  ScrollBox1.VertScrollBar.Visible := True; // 启用垂直滚动条
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/close_hover.png', '关机');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/reset_hover.png', '重启');

  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-esc-40.png', '退出');

  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-shortcuts-48.png', '快捷');

  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/cfg.png', '配置');
  show_aapp(ExtractFilePath(ParamStr(0)) + '/imgapp/icons8-translation-64.png', '翻译');

  ScrollBox1.Height := 60 * 6;
             // 计算主窗体中心点
  MainFormCenter.X := (Width - ScrollBox1.Width) div 2;
  MainFormCenter.Y := (height - ScrollBox1.Height) div 2;

  // 设置窗体位置到主窗体中心
  ScrollBox1.Left := MainFormCenter.X;
  ScrollBox1.Top := MainFormCenter.Y;




end;

procedure TbottomForm.LVexeinfoMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  ReleaseCapture;
  SendMessage(handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
end;

end.


// if CheckBox1.Checked then
//  begin
//
//    set_json_value('config', 'definestart', 'true');
//
//    Caption := 'selfdefinestartmenu';
//
//  end
//  else
//  begin
//    set_json_value('config', 'definestart', 'false');
//    Caption := 'toolform';
//  end;

