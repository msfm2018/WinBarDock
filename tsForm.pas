unit tsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, CoreDB,
  Vcl.StdCtrls, Vcl.Imaging.pngimage, inifiles, FileCtrl, Vcl.Imaging.jpeg, u_debug,
  System.Math, cfgForm, Vcl.Menus,bottomForm;

type
  TForm1 = class(TForm)
    img_bg: TImage;
    PopupMenu1: TPopupMenu;
    N1: TMenuItem;
    exit1: TMenuItem;
    Timer1: TTimer;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure img_bgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
    procedure exit1Click(Sender: TObject);
    procedure Timer1Timer(Sender: TObject);
    procedure N2Click(Sender: TObject);
    procedure N3Click(Sender: TObject);
  private
    FAltF4Key, FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure img_click(Sender: TObject);
    procedure move_windows(h: thandle);
    procedure snap_top_windows;
    procedure imagelllmouseLeave(sender: tobject);
    procedure ApplicationIdle(Sender: TObject; var Done: Boolean);
  public
    procedure init;

  end;

var
  Form1: TForm1;
  btns_count: integer;
  app_cfging: Boolean;
  Shortcut_key: string;

implementation

{$R *.dfm}

const
  VisHeight: Integer = 9; // 露头高度
  top_snap_gap: Integer = 40; // 吸附距离


  img_width = 64;
  img_height = 64;
  img_gap = 30;
  zoom_factor = 101.82 * 3; // sqrt(img_width*img_width+ img_height*img_height)=101.8...
//        zoom_factor=50.91*3;

var
  h: HDC;
  a, b, rate: Real;
  img_arr_position: array of integer;
  img_arr: array of timage;

var
//鼠标左键已点击
  mouse_left_clicking: Boolean = false;

//  执行中
  launcher_ing: Boolean = false;
  previous_y: Integer = 0;
  previous_x: Integer = 0;
  final_width: Integer;

procedure to_launcher(n: string);
begin
  if launcher_ing then
    exit;
  launcher_ing := true;
  if n.Contains('https') or n.Contains('http') or n.Contains('.html') or n.Contains('.htm') then
    Winapi.ShellAPI.ShellExecute(application.Handle, nil, PChar(n), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(n), nil, nil, SW_SHOW);

  launcher_ing := false;
end;

procedure tform1.init();
var
  I: Integer;
begin
  app_cfging := False;
  // ctrl+b   定义快捷键
  if FindAtom('xxyyzz_hot') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hot');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;

  img_bg.Picture.LoadFromFile(ExtractFilePath(Paramstr(0)) + 'img\bg.png');

  var list_str := g_core.db.filesDB.GetKeys;

  btns_count := list_str.Count;

  setlength(img_arr_position, btns_count);

  if img_arr <> nil then
  begin
    for I := 0 to Length(img_arr) - 1 do
    begin
      freeandnil(img_arr[I]);
    end;
  end;

  setlength(img_arr, btns_count);
  for I := 0 to btns_count - 1 do
  begin
    img_arr[I] := timage.Create(self);

    img_arr[I].Name := 'image' + I.ToString;

    if I = 0 then
      img_arr[I].Left := I * img_width + img_gap
    else
    begin

      img_arr[I].Left := img_arr[I - 1].Left + img_arr[I - 1].Width + img_gap;

    end;

    img_arr[I].top := 22;
    img_arr[I].width := img_width;
    img_arr[I].height := img_height;
    img_arr[I].Transparent := true;
    img_arr[I].Center := true;
    img_arr[I].Hint := g_core.db.filesDB.GetString(list_str[I]);
    img_arr[I].Picture.LoadFromFile(list_str[I]);
    img_arr[I].Stretch := true;
    img_arr[I].Parent := Form1;
    img_arr[I].OnMouseMove := Image111MouseMove;
    img_arr[I].OnMouseLeave := imagelllmouseLeave;
    img_arr[I].OnMouseDown := FormMouseDown;
    img_arr[I].OnClick := img_click;
    img_arr_position[I] := img_arr[I].Left;
  end;

  h := GetDC(0);
  BorderStyle := bsNone;

  form1.width := btns_count * img_width + btns_count * img_gap + img_width;
  final_width := form1.Width;
  FreeAndNil(list_str);
end;

procedure TForm1.img_bgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if app_cfging then
    exit;
  move_windows(handle);

end;

procedure TForm1.img_click(Sender: TObject);
begin
  launcher_ing := false;
  var arr_exe := timage(Sender).Hint.Split([',']);
  for var I := 0 to high(arr_exe) do
    to_launcher(arr_exe[I]);

  mouse_left_clicking := false;
end;

procedure TForm1.exit1Click(Sender: TObject);
begin
  Application.Terminate;
end;

procedure tform1.snap_top_windows();
var
  lp: tpoint;
  I: Integer;
begin

  if app_cfging then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

//    复原按钮原始尺寸
    for I := 0 to btns_count - 1 do
    begin
      img_arr[I].Left := img_arr_position[I];
      img_arr[I].Width := img_width;
      img_arr[I].height := img_height;
    end;

//    吸附桌面顶端
    if Top < top_snap_gap then
    begin
      Top := -(Height - VisHeight) - 5;
      Left := Screen.Width div 2 - Width div 2;
    end;

  end
  else if Top < top_snap_gap then
    Top := 0;

  if not DwmCompositionEnabled then
  begin
    begin
      AlphaBlend := true;

      self.Parent.Perform(WM_ERASEBKGND, h, 0);
      BitBlt(Form1.Canvas.Handle, 0, 0, ClientWidth, ClientHeight, h, self.Left, self.Top, SRCCOPY);
    end;
  end;
  inherited
end;

procedure TForm1.Timer1Timer(Sender: TObject);
begin
  timer1.Interval := 10;
  snap_top_windows();
end;

procedure TForm1.FormShow(Sender: TObject);
begin
  init();
  form1.Left := g_core.db.syspara.GetInteger('left');
  form1.Top := g_core.db.syspara.GetInteger('top');

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  Shortcut_key := g_core.db.syspara.GetString('shortcut');

  Application.OnIdle := ApplicationIdle;

  if   bottomFrm=nil then
        bottomFrm:= TbottomFrm.Create(self);
    bottomFrm.Show;
    bottomFrm.Top:=Screen.WorkAreaHeight-bottomFrm.height;
    bottomFrm.Left:=((Screen.WorkAreaWidth-bottomFrm.Width) div 2)
end;

procedure TForm1.ApplicationIdle(Sender: TObject; var Done: Boolean);
begin
      g_core.db.syspara.SetVarValue('left', Left);
  g_core.db.syspara.SetVarValue('top', Top);
//  debug.Show('ApplicationIdle');
end;
procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (Shortcut_key.Trim <> '') then
  begin
    launcher_ing := false;
    to_launcher(Shortcut_key);

  end;
end;

procedure tform1.imagelllmouseLeave(sender: tobject);
begin

end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  aName: string;
begin
  if app_cfging then
    Exit;

//    点击事件
  if (ssleft in Shift) and (mouse_left_clicking) then
  begin

    if (X <> previous_x) or (Y <> previous_y) then
    begin
      previous_x := X;
      previous_y := Y;
      move_windows(Handle);
    end
    else
    begin
      TImage(Sender).OnClick(self);
    end;
  end
  else
  begin
//  移动事件
    var lp: tpoint;
    var I: Integer;
    GetCursorPos(lp);

    for I := 0 to btns_count - 1 do
    begin
//      if I = 0 then
//        img_arr[0].Left := img_arr_position[0] - ceil((img_arr[0].Width - img_width) * rate)
//      else
      begin
        var next_Compent := Form1.FindComponent('image' + inttostr(I + 1));
        if next_Compent <> nil then
          TImage(next_Compent).Left := img_arr_position[I + 1] + ceil((img_arr[I].Width - img_width) * rate);

        var next_Compent2 := Form1.FindComponent('image' + inttostr(I + 2));
        if next_Compent2 <> nil then
          TImage(next_Compent2).Left := img_arr_position[I + 2] + ceil((img_arr[I + 1].Width - img_width) * rate * 0.5);

        var pre_Compent := Form1.FindComponent('image' + inttostr(I - 1));
        if pre_Compent <> nil then
          TImage(pre_Compent).Left := img_arr_position[I - 1] - ceil((img_arr[I].Width - img_width) * rate);

        var pre_Compent2 := Form1.FindComponent('image' + inttostr(I - 2));
        if pre_Compent2 <> nil then
          TImage(pre_Compent2).Left := img_arr_position[I - 2] - ceil((img_arr[I - 1].Width - img_width) * rate * 0.5);

      end;

      a := img_arr[I].Left - ScreenToClient(lp).X + img_arr[I].Width / 2;
      b := ScreenToClient(lp).Y - img_arr[I].Top - img_arr[I].Height / 2;

      rate := 1 - sqrt(a * a + b * b) / zoom_factor;

      if (rate < 0.5) then
        rate := 0.5;

      if (rate > 1) then
        rate := 1;

      img_arr[I].Width := ceil(img_width * 2 * rate);
      img_arr[I].Height := ceil(img_width * 2 * rate);

    end;

  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnregisterHotKey(Handle, FShowkeyid);
  GlobalDeleteAtom(FShowkeyid);

  ReleaseDC(0, h);
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if app_cfging then
    exit;

  mouse_left_clicking := true;
  previous_y := Y;
  previous_x := X;

end;

procedure tform1.move_windows(h: thandle);
begin

  ReleaseCapture;
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);

end;

procedure TForm1.N1Click(Sender: TObject);
begin
  if mycfg = nil then
    mycfg := Tmycfg.Create(self);
  mycfg.Show;
  app_cfging := true;
  SetWindowPos(mycfg.Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TForm1.N2Click(Sender: TObject);
begin
  var cc := inputbox('ctrl+b 快捷键', '快捷键应用程序完整路径', '');
  if cc.trim <> '' then
  begin
    Shortcut_key := cc;
    g_core.db.syspara.SetVarValue('shortcut', Shortcut_key.Trim);
  end;
end;

procedure TForm1.N3Click(Sender: TObject);
begin
    if   bottomFrm=nil then
        bottomFrm:= TbottomFrm.Create(self);
    bottomFrm.Show;
    bottomFrm.Top:=Screen.WorkAreaHeight-bottomFrm.height;
    bottomFrm.Left:=((Screen.WorkAreaWidth-bottomFrm.Width) div 2)
end;

end.

