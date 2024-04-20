unit ApplicationMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Dialogs, ExtCtrls, core_db, Generics.Collections, Vcl.Imaging.pngimage,
  inifiles, Vcl.Imaging.jpeg, u_debug, ComObj, System.Math, ConfigurationForm,
  Vcl.Menus, InfoBarForm, System.Generics.Collections, event;

type
  TForm1 = class(TForm)
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure action_setClick(Sender: TObject);
    procedure action_terminateClick(Sender: TObject);
    procedure action_set_acceClick(Sender: TObject);
    procedure action_bootom_panelClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
  private
    FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure img_click(Sender: TObject);
    procedure wndproc(var Msg: tmessage); override;
    procedure snap_top_windows;
    procedure CleanupPopupMenu;
  private
    var
      img_bg1: timage;
      pm: TPopupMenu;
      menuItems: array of TMenuItem;
    procedure imgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure CreateRoundRectRgn1(w, h: Integer);
    procedure CalculateAndPositionNodes;
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure move_windows(h: thandle);
    procedure imgMouseLeave(Sender: TObject);
    procedure imgMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure loadInit;

  public
    procedure layout;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
end;
  // 处理定时器事件的函数

procedure TimerProc(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  Form1.snap_top_windows();
end;

// 计算和定位节点的逻辑
procedure TForm1.CalculateAndPositionNodes();
begin
  var hashKeys1 := g_core.dbmgr.itemdb.GetKeys();
  g_core.nodes.size := hashKeys1.Count;

  if g_core.nodes.nodes_array <> nil then
  begin
    for var Node in g_core.nodes.nodes_array do
      FreeAndNil(Node);
  end;

  Form1.height := g_core.nodes.node_size + g_core.nodes.node_size div 2 + 28;

  setlength(g_core.nodes.nodes_array, g_core.nodes.size);
  for var I := 0 to g_core.nodes.size - 1 do
  begin
    g_core.nodes.nodes_array[I] := tnode.Create(self);
    g_core.nodes.nodes_array[I].Width := g_core.nodes.node_size;
    g_core.nodes.nodes_array[I].Height := g_core.nodes.node_size;

    if I = 0 then
      g_core.nodes.nodes_array[I].Left := g_core.nodes.node_gap + 16
    else
    begin

      g_core.nodes.nodes_array[I].Left := g_core.nodes.nodes_array[I - 1].Left + g_core.nodes.nodes_array[I - 1].Width + g_core.nodes.node_gap * 2 + 20;  //10延展一下   g_core.nodes.node_gap

    end;

    with g_core.nodes.nodes_array[I] do
    begin

      top := (self.GetClientRect().height - g_core.nodes.node_size) div 2;
      Parent := Form1;
      Width := g_core.nodes.node_size;
      height := g_core.nodes.node_size;
      Transparent := true;
      Center := true;
      node_path := g_core.dbmgr.itemdb.GetString(hashKeys1[I], False);
      var t := g_core.dbmgr.itemdb.GetString(hashKeys1[I]);

      if t.Contains('.\img') then
        Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + ExtractFileName(t))
      else

        Picture.LoadFromFile(t);

      Stretch := true;

      OnMouseMove := imgMouseMove;
      OnMouseLeave := imgMouseLeave;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;
      OnMouseWheel := imgMouseWheel;

      node_left := g_core.nodes.nodes_array[I].Left;

      original_width := g_core.nodes.nodes_array[I].Width;
      original_height := g_core.nodes.nodes_array[I].height;
      center_x := g_core.nodes.nodes_array[I].Left + g_core.nodes.nodes_array[I].Width div 2;
      center_y := g_core.nodes.nodes_array[I].top + g_core.nodes.nodes_array[I].height div 2;

    end;
  end;

  Form1.Width := g_core.nodes.nodes_array[g_core.nodes.size - 1].Left + g_core.nodes.nodes_array[g_core.nodes.size - 1].Width + g_core.nodes.nodes_array[g_core.nodes.size - 1].Width div 2; // g_core.nodes.node_gap+20;

  freeandnil(hashKeys1);

end;

// 布局逻辑
procedure TForm1.layout();
begin
  g_core.nodes.Is_cfging := False;

  img_bg1.Parent := self;
  img_bg1.Align := alClient;
  img_bg1.Transparent := true;
  img_bg1.Stretch := true;

  img_bg1.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\bg.png');

  img_bg1.OnMouseDown := img_bgMouseDown;

  CalculateAndPositionNodes();

  var TotalMonitorWidth := 0;

  var PrimaryMonitorHeight := Screen.monitors[0].height;
  case Screen.monitorcount of
    1:
      TotalMonitorWidth := Screen.monitors[0].Width;

    // 2:
    // TotalMonitorWidth := Screen.monitors[0].Width + Screen.monitors[1].Width;
  else
    TotalMonitorWidth := Screen.monitors[0].Width;
  end;

  if Form1.Left > TotalMonitorWidth then
    Form1.Left := Screen.monitors[0].Width div 4;
  if Form1.top > PrimaryMonitorHeight then
    Form1.top := 0;

  g_core.utils.short_key := g_core.dbmgr.cfgDb.GetString('shortcut');

  restore_state();
  CreateRoundRectRgn1(Width, height);

  if Form1.Width > TotalMonitorWidth then
  begin

    g_core.nodes.node_size := g_core.dbmgr.cfgDb.GetInteger('ih');
    g_core.nodes.node_gap := Round(g_core.nodes.node_size div 4);

    CalculateAndPositionNodes();
  end

end;

procedure TForm1.img_click(Sender: TObject);
begin
  g_core.utils.launch_app(tnode(Sender).node_path);
  EventDef.isLeftClick := False;

end;

procedure TForm1.action_terminateClick(Sender: TObject);
begin
  g_core.dbmgr.cfgDb.SetVarValue('left', Left);
  g_core.dbmgr.cfgDb.SetVarValue('top', top);
  Application.Terminate;
end;

procedure TForm1.wndproc(var Msg: tmessage);
begin
  inherited;
  case Msg.Msg of
    WM_MOUSEMOVE, WM_MOUSEACTIVATE, WM_MOUSEHOVER:
      begin
        KillTimer(Handle, 10);
        SetTimer(Handle, 10, 10, @TimerProc);
      end;
    WM_MOUSELEAVE:
      begin
        TThread.CreateAnonymousThread(
          procedure
          begin
            Sleep(1000);
            KillTimer(Handle, 10);
          end).Start;

      end;
  end;
end;

procedure TForm1.snap_top_windows();
var
  lp: tpoint;
  I: Integer;
begin
  if g_core.nodes.Is_cfging then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

    for I := 0 to g_core.nodes.size - 1 do
    begin

      g_core.nodes.nodes_array[I].SetBounds(g_core.nodes.nodes_array[I].center_x - g_core.nodes.nodes_array[I].original_width div 2, g_core.nodes.nodes_array[I].center_y - g_core.nodes.nodes_array[I].original_height div 2, g_core.nodes.nodes_array[I].original_width, g_core.nodes.nodes_array[I].original_height);

    end;

    if top < top_snap_distance then
    begin
      top := -(height - visible_height) - 5;
      Left := Screen.Width div 2 - Width div 2;
      restore_state();
    end

  end
  else if top < top_snap_distance then
    top := 0;
end;

procedure TForm1.CreateRoundRectRgn1(w, h: Integer);
var
  Rgn: HRGN;
begin
  Rgn := CreateRoundRectRgn(0, 0, w, h, 8, 8);

  SetWindowRgn(Handle, Rgn, true);
end;

procedure tform1.loadInit();
var
  I: Integer;
  menuItemClickHandlers: array[0..4] of TMenuClickHandler;
begin
  if img_bg1 = nil then
    img_bg1 := timage.Create(nil);
  if not TOSVersion.Check(6, 2) then
    Application.Terminate;

  Form1.Left := g_core.dbmgr.cfgDb.GetInteger('left');
  Form1.top := g_core.dbmgr.cfgDb.GetInteger('top');

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  if FindAtom('xxyyzz_hotkey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hotkey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;
  killtimer(Handle, 10);
  SetTimer(Handle, 10, 10, @TimerProc);

  layout();

  BorderStyle := bsNone;

  CreateRoundRectRgn1(Width + 1, height + 1);

  if pm = nil then
    pm := TPopupMenu.Create(self);
  menuItemClickHandlers[0] := N1Click;
  menuItemClickHandlers[1] := action_bootom_panelClick;
  menuItemClickHandlers[2] := action_setClick;
  menuItemClickHandlers[3] := action_set_acceClick;
  menuItemClickHandlers[4] := action_terminateClick;

  setlength(menuItems, Length(menu_name));

  for I := 0 to High(menuItems) do
  begin
    menuItems[I] := TMenuItem.Create(self);
    menuItems[I].Caption := menu_name[I];
    menuItems[I].OnClick := menuItemClickHandlers[I];
    pm.Items.Add(menuItems[I]);
  end;

  PopupMenu := pm;
  form1.OnMouseWheel := imgMouseWheel;

end;

procedure TForm1.FormShow(Sender: TObject);
begin
  loadInit();
end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (g_core.utils.short_key.Trim <> '') then
    g_core.utils.launch_app(g_core.utils.short_key);

end;

// 处理鼠标离开事件
procedure TForm1.imgMouseLeave(Sender: TObject);
begin

end;

// 移动窗口逻辑
procedure TForm1.imgMouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  a, rate: double;
  b: double;
  I: Integer;
var
  Distance, ZoomFactor: double;
  NewWidth, NewHeight, NewLeft, NewTop: Integer;
begin
  if g_core.nodes.Is_cfging then
    exit;
  if (EventDef.isLeftClick) then
  begin
    if (X <> EventDef.X) or (Y <> EventDef.Y) then
    begin
      EventDef.X := X;
      EventDef.Y := Y;
      move_windows(Handle);
    end
    else
      timage(Sender).OnClick(self);
  end
  else
  begin
    var lp: tpoint;
    GetCursorPos(lp);
    for I := 0 to g_core.nodes.size - 1 do
    begin
      a := g_core.nodes.nodes_array[I].Left - ScreenToClient(lp).X + g_core.nodes.nodes_array[I].Width / 2;
      b := g_core.nodes.nodes_array[I].top - ScreenToClient(lp).Y + g_core.nodes.nodes_array[I].height / 4;
      rate := Exp(-sqrt(a * a + b * b) / (103.82 * 5));
      rate := Min(Max(rate, 0.5), 1);

      NewWidth := Round(g_core.nodes.nodes_array[I].original_width * 2 * rate);
      NewHeight := Round(g_core.nodes.nodes_array[I].original_height * 2 * rate);

      var maxValue: Integer := 128;
        // 限制按钮的最大宽度和高度
      NewWidth := Min(NewWidth, maxValue);
      NewHeight := Min(NewHeight, maxValue);

      // 计算按钮的新位置，使其保持在中心点


      g_core.nodes.nodes_array[I].center_x := g_core.nodes.nodes_array[I].Left + g_core.nodes.nodes_array[I].Width div 2;
      g_core.nodes.nodes_array[I].center_y := g_core.nodes.nodes_array[I].Top + g_core.nodes.nodes_array[I].Height div 2;
      g_core.nodes.nodes_array[I].SetBounds(g_core.nodes.nodes_array[I].center_x - NewWidth div 2, g_core.nodes.nodes_array[I].center_y - NewHeight div 2, NewWidth, NewHeight);

    end;

  end;
end;

procedure TForm1.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  CleanupPopupMenu();
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnregisterHotKey(Handle, FShowkeyid);
  GlobalDeleteAtom(FShowkeyid);
  KillTimer(Handle, 10);
  action_terminateClick(self);
  img_bg1.Free;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if g_core.nodes.Is_cfging then
    exit;

  EventDef.isLeftClick := true;
  EventDef.Y := Y;
  EventDef.X := X;

end;

procedure TForm1.imgMouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  I: Integer;
  NewWidth, NewHeight: Integer;
begin
  if g_core.nodes.Is_cfging then
    Exit;

  Handled := True;

  // 根据滚轮方向调整节点大小
  if WheelDelta > 0 then
  begin
    var i1 := g_core.dbmgr.cfgDb.GetInteger('ih');
    i1 := round(1.1 * i1);
    g_core.nodes.node_size := i1;
    g_core.dbmgr.cfgDb.SetVarValue('ih', i1);
  end
  else
  begin
    var i1 := g_core.dbmgr.cfgDb.GetInteger('ih');
    i1 := round(i1 * 0.9);
    g_core.nodes.node_size := i1;
    g_core.dbmgr.cfgDb.SetVarValue('ih', i1);
  end;

  layout();

end;

procedure TForm1.img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
    move_windows(Handle);

end;

procedure TForm1.move_windows(h: thandle);
begin

  ReleaseCapture;
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);

end;

procedure TForm1.N1Click(Sender: TObject);
begin
  g_core.utils.launch_app('https://fanyi.baidu.com/');
end;

procedure TForm1.action_setClick(Sender: TObject);
var
  vobj: TObject;
begin
  vobj := g_core.FindObjectByName('cfgForm');
  TCfgForm(vobj).Show;

  g_core.nodes.Is_cfging := true;
  SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TForm1.action_set_acceClick(Sender: TObject);
var
  OpenDlg: TOpenDialog;
begin
  OpenDlg := TOpenDialog.Create(nil);
  with OpenDlg do
  begin
    Filter := 'ctrl+b 热键(*.exe)|*.exe';
    DefaultExt := '*.exe';

    if Execute then
    begin
      g_core.utils.short_key := filename;
      g_core.dbmgr.cfgDb.SetVarValue('shortcut', g_core.utils.short_key.Trim);
    end;
  end;
  OpenDlg.Free;

end;

procedure TForm1.action_bootom_panelClick(Sender: TObject);
var
  vobj: TObject;
begin

  vobj := g_core.FindObjectByName('bottomForm');
  TbottomForm(vobj).Show;

  TbottomForm(vobj).top := Screen.WorkAreaHeight - TbottomForm(vobj).height;
  TbottomForm(vobj).Width := Screen.WorkAreaWidth - 10;
  TbottomForm(vobj).Left := ((Screen.WorkAreaWidth - TbottomForm(vobj).Width) div 2);

  restore_state();
end;

procedure TForm1.CleanupPopupMenu;
var
  menuItem: TMenuItem;
begin
  for menuItem in menuItems do
    menuItem.Free;
  pm.Free;
end;

end.

