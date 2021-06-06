unit tsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, CoreDB,
  Vcl.StdCtrls, Vcl.Imaging.pngimage, inifiles, FileCtrl, Vcl.Imaging.jpeg,
  u_debug, System.Math, cfgForm, Vcl.Menus, bottomForm;

type
  TForm1 = class(TForm)
    img_bg: TImage;
    PopupMenu1: TPopupMenu;
    action_set: TMenuItem;
    action_terminate: TMenuItem;
    Timer1: TTimer;
    action_set_acce: TMenuItem;
    action_bootom_panel: TMenuItem;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure action_setClick(Sender: TObject);
    procedure action_terminateClick(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure action_set_acceClick(Sender: TObject);
    procedure action_bootom_panelClick(Sender: TObject);
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
  private
    FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure img_click(Sender: TObject);
    procedure move_windows(h: thandle);
    procedure snap_top_windows;
  public
    procedure init;
  end;

  tevent_define = record
    left_click: Boolean;
    y: Integer;
    x: Integer;
  end;

  tgg = record
    img_arr_count: integer;
    img_arr_position: array of integer;
    img_arr: array of timage;
    a, b, rate: Real;
    app_cfging: Boolean;
    shortcut_key: string;
    const
      top_parent = 22;
      VisHeight: Integer = 9; // 露头高度
      top_snap_gap: Integer = 40; // 吸附距离

      img_width = 64;
      img_height = 64;
      img_gap = 30;
      zoom_factor = 101.82 * 3; // sqrt(img_width*img_width+ img_height*img_height)=101.8...
  end;

var
  Form1: TForm1;
  event_def: tevent_define;
  gg: tgg;

implementation

{$R *.dfm}

procedure to_launcher(n: string);
begin
  if n.trim = '' then
    exit;
  if n.Contains('https') or n.Contains('http') or n.Contains('.html') or n.Contains('.htm') then
    Winapi.ShellAPI.ShellExecute(application.Handle, nil, PChar(n), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(n), nil, nil, SW_SHOW);

end;

procedure tform1.init();
var
  I: Integer;
begin
  gg.app_cfging := False;

  if FindAtom('xxyyzz_hot') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hot');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);       // ctrl+b   定义快捷键
  end;

  img_bg.Picture.LoadFromFile(ExtractFilePath(Paramstr(0)) + 'img\bg.png');

  var keys := g_core.db.filesDB.GetKeys;

  gg.img_arr_count := keys.Count;

  setlength(gg.img_arr_position, gg.img_arr_count);

  if gg.img_arr <> nil then
  begin
    for I := 0 to Length(gg.img_arr) - 1 do
    begin
      freeandnil(gg.img_arr[I]);
    end;
  end;

  setlength(gg.img_arr, gg.img_arr_count);
  for I := 0 to gg.img_arr_count - 1 do
  begin
    gg.img_arr[I] := timage.Create(self);

    gg.img_arr[I].Name := 'image' + I.ToString;

    if I = 0 then
      gg.img_arr[I].Left := I * gg.img_width + gg.img_gap
    else
    begin

      gg.img_arr[I].Left := gg.img_arr[I - 1].Left + gg.img_arr[I - 1].Width + gg.img_gap;

    end;
    with gg.img_arr[I] do
    begin
    //离父顶部高度
      top := gg.top_parent;
      Parent := Form1;
      width := gg.img_width;
      height := gg.img_height;
      Transparent := true;
      Center := true;
      //借用 hint 存取信息 懒得扩展
      Hint := g_core.db.filesDB.GetString(keys[I]);
      Picture.LoadFromFile(keys[I]);
      Stretch := true;

      OnMouseMove := Image111MouseMove;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;

      gg.img_arr_position[I] := gg.img_arr[I].Left;
    end;
  end;

  BorderStyle := bsNone;

  form1.width := gg.img_arr_count * gg.img_width + gg.img_arr_count * gg.img_gap + gg.img_width;
  form1.Left := g_core.db.syspara.GetInteger('left');
  form1.Top := g_core.db.syspara.GetInteger('top');
  FreeAndNil(keys);

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  gg.Shortcut_key := g_core.db.syspara.GetString('shortcut');
end;

procedure TForm1.img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
    move_windows(handle);

end;

procedure TForm1.img_click(Sender: TObject);
begin
  to_launcher(timage(Sender).Hint);
  event_def.left_click := false;

end;

procedure TForm1.action_terminateClick(Sender: TObject);
begin
  g_core.db.syspara.SetVarValue('left', Left);
  g_core.db.syspara.SetVarValue('top', Top);
  Application.Terminate;
end;

procedure tform1.snap_top_windows();
var
  lp: tpoint;
  I: Integer;
begin

  if gg.app_cfging then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

//    复原按钮原始尺寸
    for I := 0 to gg.img_arr_count - 1 do
    begin
      gg.img_arr[I].Left := gg.img_arr_position[I];
      gg.img_arr[I].Width := gg.img_width;
      gg.img_arr[I].height := gg.img_height;
    end;

//    吸附桌面顶端
    if Top < gg.top_snap_gap then
    begin
      Top := -(Height - gg.VisHeight) - 5;
      Left := Screen.Width div 2 - Width div 2;
    end;

  end
  else if Top < gg.top_snap_gap then
    Top := 0;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  timer1.Interval := 10;
  snap_top_windows();
end;

procedure TForm1.FormShow(Sender: TObject);
begin
 if not TOSVersion.Check(6, 2) then // Windows 8
    Application.Terminate;
  init();

  if bottomFrm = nil then
    bottomFrm := TbottomFrm.Create(self);
  bottomFrm.Show;
  bottomFrm.Top := Screen.WorkAreaHeight - bottomFrm.height;
  bottomFrm.Left := ((Screen.WorkAreaWidth - bottomFrm.Width) div 2);

  with event_def do
  begin
    Y := 0;
    X := 0;
    left_click := False;
  end;
end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (gg.Shortcut_key.Trim <> '') then
    to_launcher(gg.Shortcut_key);

end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if gg.app_cfging then
    Exit;

  if (event_def.left_click) then
  begin

    if (X <> event_def.x) or (Y <> event_def.y) then
    begin
      event_def.x := X;
      event_def.y := Y;
      move_windows(Handle);

    end
    else
      TImage(Sender).OnClick(self);

  end
  else
  begin
    var lp: tpoint;
    var I: Integer;
    GetCursorPos(lp);

    for I := 0 to gg.img_arr_count - 1 do
    begin

      var next_Compent := Form1.FindComponent('image' + inttostr(I + 1));
      if next_Compent <> nil then
        TImage(next_Compent).Left := gg.img_arr_position[I + 1] + ceil((gg.img_arr[I].Width - gg.img_width) * gg.rate);

      var next_Compent2 := Form1.FindComponent('image' + inttostr(I + 2));
      if next_Compent2 <> nil then
        TImage(next_Compent2).Left := gg.img_arr_position[I + 2] + ceil((gg.img_arr[I + 1].Width - gg.img_width) * gg.rate * 0.5);

      var pre_Compent := Form1.FindComponent('image' + inttostr(I - 1));
      if pre_Compent <> nil then
        TImage(pre_Compent).Left := gg.img_arr_position[I - 1] - ceil((gg.img_arr[I].Width - gg.img_width) * gg.rate);

      var pre_Compent2 := Form1.FindComponent('image' + inttostr(I - 2));
      if pre_Compent2 <> nil then
        TImage(pre_Compent2).Left := gg.img_arr_position[I - 2] - ceil((gg.img_arr[I - 1].Width - gg.img_width) * gg.rate * 0.5);

      gg.a := gg.img_arr[I].Left - ScreenToClient(lp).X + gg.img_arr[I].Width / 2;
      gg.b := ScreenToClient(lp).Y - gg.img_arr[I].Top - gg.img_arr[I].Height / 2;

      gg.rate := 1 - sqrt(gg.a * gg.a + gg.b * gg.b) / gg.zoom_factor;

      if (gg.rate < 0.5) then
        gg.rate := 0.5;

      if (gg.rate > 1) then
        gg.rate := 1;

      gg.img_arr[I].Width := ceil(gg.img_width * 2 * gg.rate);
      gg.img_arr[I].Height := ceil(gg.img_width * 2 * gg.rate);

    end;

  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnregisterHotKey(Handle, FShowkeyid);
  GlobalDeleteAtom(FShowkeyid);

end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if gg.app_cfging then
    exit;

  event_def.left_click := true;
  event_def.y := Y;
  event_def.x := X;

end;

procedure tform1.move_windows(h: thandle);
begin

  ReleaseCapture;
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);

end;

procedure TForm1.action_setClick(Sender: TObject);
begin
  if mycfg = nil then
    mycfg := Tmycfg.Create(self);
  mycfg.Show;
  gg.app_cfging := true;
  SetWindowPos(mycfg.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TForm1.action_set_acceClick(Sender: TObject);
begin
  var cc := inputbox('ctrl+b 快捷键', '快捷键应用程序完整路径', '');
  if cc.trim <> '' then
  begin
    gg.Shortcut_key := cc;
    g_core.db.syspara.SetVarValue('shortcut', gg.Shortcut_key.Trim);
  end;
end;

procedure TForm1.action_bootom_panelClick(Sender: TObject);
begin
  if bottomFrm = nil then
    bottomFrm := TbottomFrm.Create(self);
  bottomFrm.Show;
  bottomFrm.Top := Screen.WorkAreaHeight - bottomFrm.height;
  bottomFrm.Left := ((Screen.WorkAreaWidth - bottomFrm.Width) div 2)
end;

end.

