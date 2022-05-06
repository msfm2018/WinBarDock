unit tsForm;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, CoreDB,
  Vcl.StdCtrls, Vcl.Imaging.pngimage, inifiles, FileCtrl, Vcl.Imaging.jpeg,
  u_debug, System.Math, cfgForm, Vcl.Menus, bottomForm,
  system.Generics.Collections, event;

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


var
  Form1: TForm1;
  eventDef: TEventDefine;

implementation

{$R *.dfm}

procedure tform1.init();
begin

 g_core.app.app_cfging := False;

  if FindAtom('xxyyzz_hotkey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hotkey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);       // ctrl+b   定义快捷键
  end;

  img_bg.Picture.LoadFromFile(ExtractFilePath(Paramstr(0)) + 'img\bg.png');

  var hashKeys1 := g_core.db.itemdb.GetKeys();

  g_core.app.itemCount := hashKeys1.Count;

  setlength(g_core.app.itemPosition, g_core.app.itemCount);

  if g_core.app.items <> nil then
  begin
    for var I := 0 to Length(g_core.app.items) - 1 do
    begin
      freeandnil(g_core.app.items[I]);
    end;
  end;

  setlength(g_core.app.items, g_core.app.itemCount);
  for var I := 0 to g_core.app.itemCount - 1 do
  begin
    g_core.app.items[I] := timage_ext.Create(self);

    g_core.app.items[I].Name := 'image' + I.ToString;

    if I = 0 then
      g_core.app.items[I].Left := I * g_core.app.itemWidth + g_core.app.itemGap
    else
    begin

      g_core.app.items[I].Left := g_core.app.items[I - 1].Left + g_core.app.items[I - 1].Width + g_core.app.itemGap;

    end;
    with g_core.app.items[I] do
    begin
    //离父顶部高度
      top := g_core.app.marginTop;
      Parent := Form1;
      width := g_core.app.itemWidth;
      height := g_core.app.itemHeight;
      Transparent := true;
      Center := true;
      appPath := g_core.db.itemdb.GetString(hashKeys1[i], false);

      var tmp := g_core.db.itemdb.GetString(hashKeys1[i]);
      Picture.LoadFromFile(tmp);

      Stretch := true;

      OnMouseMove := Image111MouseMove;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;

      g_core.app.itemPosition[I] := g_core.app.items[I].Left;
    end;
  end;

  BorderStyle := bsNone;

  form1.width := g_core.app.itemCount * g_core.app.itemWidth + g_core.app.itemCount * g_core.app.itemGap + g_core.app.itemWidth;
  form1.Left := g_core.db.cfgDb.GetInteger('left');
  form1.Top := g_core.db.cfgDb.GetInteger('top');

  freeandnil(hashKeys1);
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  g_core.app.Shortcut_key := g_core.db.cfgdb.GetString('shortcut');
end;

procedure TForm1.img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
    move_windows(handle);

end;

procedure TForm1.img_click(Sender: TObject);
begin
 g_core.utils.to_launcher(timage_ext(Sender).appPath);
  eventDef.isLeftClick := false;

end;

procedure TForm1.action_terminateClick(Sender: TObject);
begin
  g_core.db.cfgDb.SetVarValue('left', Left);
  g_core.db.cfgDb.SetVarValue('top', Top);
  Application.Terminate;
end;

procedure tform1.snap_top_windows();
var
  lp: tpoint;
  I: Integer;
begin

  if g_core.app.app_cfging then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

//    复原按钮原始尺寸
    for I := 0 to g_core.app.itemCount - 1 do
    begin
      g_core.app.items[I].Left := g_core.app.itemPosition[I];
      g_core.app.items[I].Width := g_core.app.itemWidth;
      g_core.app.items[I].height := g_core.app.itemHeight;
    end;

//    吸附桌面顶端
    if Top < g_core.app.top_snap_gap then
    begin
      Top := -(Height - g_core.app.VisHeight) - 5;
      Left := Screen.Width div 2 - Width div 2;
    end;

  end
  else if Top < g_core.app.top_snap_gap then
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

  var vobj: TObject;
  g_core.formObject.TryGetValue('bottomForm', vobj);
  TbottomFrm(vobj).Show;

  TbottomFrm(vobj).Top := Screen.WorkAreaHeight - TbottomFrm(vobj).height;
  TbottomFrm(vobj).Left := ((Screen.WorkAreaWidth - TbottomFrm(vobj).Width) div 2);

  with eventDef do
  begin
    Y := 0;
    X := 0;
    isLeftClick := False;
  end;
end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (g_core.app.Shortcut_key.Trim <> '') then
   g_core.utils.to_launcher(g_core.app.Shortcut_key);

end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
begin
  if g_core.app.app_cfging then
    Exit;

  if (eventDef.isLeftClick) then
  begin

    if (X <> eventDef.x) or (Y <> eventDef.y) then
    begin
      eventDef.x := X;
      eventDef.y := Y;
      move_windows(Handle);

    end
    else
      TImage(Sender).OnClick(self);

  end
  else
  begin
  //以下谁数学好给优化下 告知一下啊
    var lp: tpoint;
    var I: Integer;
    GetCursorPos(lp);

    for I := 0 to g_core.app.itemCount - 1 do
    begin

      var imga := FindComponent('image' + (I + 1).ToString);
      if imga <> nil then
        TImage(imga).Left := g_core.app.itemPosition[I + 1] + Floor((g_core.app.items[I].Width - g_core.app.itemWidth) * g_core.app.rate);

      var imgb := FindComponent('image' + (I + 2).ToString);
      if imgb <> nil then
        TImage(imgb).Left := g_core.app.itemPosition[I + 2] + Floor((g_core.app.items[I + 1].Width - g_core.app.itemWidth) * g_core.app.rate * 0.5);

      var imgc := FindComponent('image' + (I - 1).ToString);
      if imgc <> nil then
        TImage(imgc).Left := g_core.app.itemPosition[I - 1] - Floor((g_core.app.items[I].Width - g_core.app.itemWidth) * g_core.app.rate);

      var imgd := FindComponent('image' + (I - 2).ToString);
      if imgd <> nil then
        TImage(imgd).Left := g_core.app.itemPosition[I - 2] - Floor((g_core.app.items[I - 1].Width - g_core.app.itemWidth) * g_core.app.rate * 0.5);

      g_core.app.a := g_core.app.items[I].Left - ScreenToClient(lp).X + g_core.app.items[I].Width / 2;
      g_core.app.b := ScreenToClient(lp).Y - g_core.app.items[I].Top - g_core.app.items[I].Height / 2;

      g_core.app.rate := 1 - sqrt(g_core.app.a * g_core.app.a + g_core.app.b * g_core.app.b) / g_core.app.zoom_factor;
//
//
//


      if (g_core.app.rate < 0.5) then
        g_core.app.rate := 0.5
      else
      if (g_core.app.rate > 1) then
        g_core.app.rate := 1;

//      g_core.app.items[I].Width := ceil(g_core.app.itemWidth * 2 * g_core.app.rate);
//      g_core.app.items[I].Height := ceil(g_core.app.itemWidth * 2 * g_core.app.rate);
                     g_core.app.items[I].Left:=g_core.app.itemPosition[I] - Floor((g_core.app.items[I].Width - g_core.app.itemWidth) * g_core.app.rate);
           g_core.app.items[I].Width := Floor(g_core.app.itemWidth * 1.8 * g_core.app.rate);
      g_core.app.items[I].Height := Floor(g_core.app.itemWidth * 1.8 * g_core.app.rate);

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
  if g_core.app.app_cfging then
    exit;

  eventDef.isLeftClick := true;
  eventDef.y := Y;
  eventDef.x := X;

end;

procedure tform1.move_windows(h: thandle);
begin

  ReleaseCapture;
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);

end;

procedure TForm1.action_setClick(Sender: TObject);
var
  vobj: TObject;
begin

  g_core.formObject.TryGetValue('cfgForm', vobj);
  Tmycfg(vobj).Show;

  g_core.app.app_cfging := true;
  SetWindowPos(Tmycfg(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TForm1.action_set_acceClick(Sender: TObject);
begin
  var cc := inputbox('ctrl+b 快捷键', '快捷键应用程序完整路径', '');
  if cc.trim <> '' then
  begin
    g_core.app.Shortcut_key := cc;
    g_core.db.cfgDb.SetVarValue('shortcut', g_core.app.Shortcut_key.Trim);
  end;
end;

procedure TForm1.action_bootom_panelClick(Sender: TObject);
var
  vobj: TObject;
begin

  g_core.formObject.TryGetValue('bottomForm', vobj);
  TbottomFrm(vobj).Show;
  TbottomFrm(vobj).Top := Screen.WorkAreaHeight - TbottomFrm(vobj).height;
  TbottomFrm(vobj).Left := ((Screen.WorkAreaWidth - TbottomFrm(vobj).Width) div 2);

end;

end.

