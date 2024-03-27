unit ApplicationMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, core_db,
  System.Hash, Generics.Collections, Vcl.StdCtrls, Vcl.Imaging.pngimage,
  inifiles, FileCtrl, Vcl.Imaging.jpeg, System.Win.TaskbarCore, ShlObj, ActiveX,
  u_debug, ComObj, System.Math, ConfigurationForm, Vcl.Menus, InfoBarForm,
  System.Generics.Collections, event, GDIPAPI, GDIPOBJ, GDIPUTIL;

type
  TForm1 = class(TForm)
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
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
    procedure CreateRoundRectRgn1(w, h: Integer);
    procedure CalculateAndPositionNodes;
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure move_windows(h: thandle);
    procedure Image111MouseLeave(Sender: TObject);
    procedure Image111MouseWheel(Sender: TObject; Shift: TShiftState;
      WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
    procedure loadInit;

  public
    procedure layout;
  end;

var
  Form1: TForm1;

implementation

{$R *.dfm}
procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word;
  Shift: TShiftState);
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
  var hashKeys1 := g_core.DatabaseManager.itemdb.GetKeys();
  g_core.NodeInformation.Count := hashKeys1.Count;

  if hashKeys1.Count = 0 then
  begin
    var sysdir: pchar;
    var SysTemDir: string;

    Getmem(sysdir, 100);
    try
      getsystemdirectory(sysdir, 100);
      SysTemDir := string(sysdir);
    finally
      Freemem(sysdir, 100);
    end;

    g_core.utils.fileMap.TryAdd(ExtractFilePath(ParamStr(0)) + 'img\flower.png', SysTemDir + '\notepad.exe');
    g_core.utils.fileMap.TryAdd(ExtractFilePath(ParamStr(0)) + 'img\smail.png', SysTemDir + '\calc.exe');
    g_core.utils.fileMap.TryAdd(ExtractFilePath(ParamStr(0)) + 'img\solid.png', SysTemDir + '\mspaint.exe');
    g_core.utils.fileMap.TryAdd(ExtractFilePath(ParamStr(0)) + 'img\11.png', SysTemDir + '\cmd.exe');
    g_core.utils.fileMap.TryAdd(ExtractFilePath(ParamStr(0)) + 'img\06.png', SysTemDir + '\mstsc.exe');

    g_core.utils.update_db;

    g_core.NodeInformation.Count := g_core.DatabaseManager.itemdb.GetKeys().Count;
    hashKeys1 := g_core.DatabaseManager.itemdb.GetKeys();
  end;

  if g_core.NodeInformation.NodesArray <> nil then
  begin
    for var I := 0 to Length(g_core.NodeInformation.NodesArray) - 1 do
    begin
      freeandnil(g_core.NodeInformation.NodesArray[I]);
    end;
  end;

  Form1.Left := g_core.DatabaseManager.cfgDb.GetInteger('left');
  Form1.top := g_core.DatabaseManager.cfgDb.GetInteger('top');
//  Form1.Width := g_core.NodeInformation.Count * g_core.NodeInformation.NodeSize + g_core.NodeInformation.Count * g_core.NodeInformation.NodeGap * 4   ;
//  + g_core.NodeInformation.Count * g_core.NodeInformation.NodeGap
//  + 20;   //20      g_core.NodeInformation.NodeGap

  Form1.height := g_core.utils.CalculateFormHeight(g_core.NodeInformation.NodeSize, Form1.height);

  setlength(g_core.NodeInformation.NodesArray, g_core.NodeInformation.Count);
  for var I := 0 to g_core.NodeInformation.Count - 1 do
  begin
    g_core.NodeInformation.NodesArray[I] := tnode.Create(self);
    g_core.NodeInformation.NodesArray[I].Width := g_core.NodeInformation.NodeSize;
    g_core.NodeInformation.NodesArray[I].Height := g_core.NodeInformation.NodeSize;

    if I = 0 then
      g_core.NodeInformation.NodesArray[I].Left := g_core.NodeInformation.NodeGap + 10 // g_core.NodeInformation.NodeGap
    else
    begin

      g_core.NodeInformation.NodesArray[I].Left := g_core.NodeInformation.NodesArray[I - 1].Left + g_core.NodeInformation.NodesArray[I - 1].Width + g_core.NodeInformation.NodeGap * 2 + 20;  //10延展一下   g_core.NodeInformation.NodeGap

    end;

    with g_core.NodeInformation.NodesArray[I] do
    begin
      var parent1 := self.GetClientRect();
      top := (parent1.height - g_core.NodeInformation.NodeSize) div 2;
      Parent := Form1;
      Width := g_core.NodeInformation.NodeSize;
      height := g_core.NodeInformation.NodeSize;
      Transparent := true;
      Center := true;
      nodePath := g_core.DatabaseManager.itemdb.GetString(hashKeys1[I], False);
      var t := g_core.DatabaseManager.itemdb.GetString(hashKeys1[I]);
      var fname := '';
      var fpath := '';
//                     Debug.Show(t);
      if t.Contains('.\img') then
      begin
//                 debug.Show('------------') ;

        fname := ExtractFileName(t);
        fpath := ExtractFilePath(ParamStr(0)) + 'img\' + fname;
        Picture.LoadFromFile(fpath);
//                      Debug.Show(fpath);
      end
      else

        Picture.LoadFromFile(t);

      Stretch := true;

      OnMouseMove := Image111MouseMove;
      OnMouseLeave := Image111MouseLeave;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;
            OnMouseWheel := Image111MouseWheel;

      nodeLeft := g_core.NodeInformation.NodesArray[I].Left;

      OriginalWidth := g_core.NodeInformation.NodesArray[I].Width;
      OriginalHeight := g_core.NodeInformation.NodesArray[I].height;
      CenterX := g_core.NodeInformation.NodesArray[I].Left + g_core.NodeInformation.NodesArray[I].Width div 2;
      CenterY := g_core.NodeInformation.NodesArray[I].top + g_core.NodeInformation.NodesArray[I].height div 2;

    end;
  end;

  Form1.Width := g_core.NodeInformation.NodesArray[g_core.NodeInformation.Count - 1].Left + g_core.NodeInformation.NodesArray[g_core.NodeInformation.Count - 1].Width + g_core.NodeInformation.NodesArray[g_core.NodeInformation.Count - 1].Width div 2; // g_core.NodeInformation.NodeGap+20;

  freeandnil(hashKeys1);

end;

// 布局逻辑
procedure TForm1.layout();
begin
  g_core.NodeInformation.IsConfiguring := False;

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

  g_core.utils.shortcutKey := g_core.DatabaseManager.cfgDb.GetString('shortcut');

  restore_state();
  CreateRoundRectRgn1(Width, height);

  if Form1.Width > TotalMonitorWidth then
  begin

    g_core.NodeInformation.NodeSize := g_core.DatabaseManager.cfgDb.GetInteger('ih');
    g_core.NodeInformation.NodeGap := Round(g_core.NodeInformation.NodeSize div 4);

    CalculateAndPositionNodes();
  end

end;

procedure TForm1.img_click(Sender: TObject);
begin
  g_core.utils.LaunchApplication(tnode(Sender).nodePath);
  EventDef.isLeftClick := False;

end;

procedure TForm1.action_terminateClick(Sender: TObject);
begin
  g_core.DatabaseManager.cfgDb.SetVarValue('left', Left);
  g_core.DatabaseManager.cfgDb.SetVarValue('top', top);
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
  if g_core.NodeInformation.IsConfiguring then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

    for I := 0 to g_core.NodeInformation.Count - 1 do
    begin

      g_core.NodeInformation.NodesArray[I].SetBounds(g_core.NodeInformation.NodesArray[I].CenterX - g_core.NodeInformation.NodesArray[I].OriginalWidth div 2, g_core.NodeInformation.NodesArray[I].CenterY - g_core.NodeInformation.NodesArray[I].OriginalHeight div 2, g_core.NodeInformation.NodesArray[I].OriginalWidth, g_core.NodeInformation.NodesArray[I].OriginalHeight);

    end;

    if top < g_core.NodeInformation.TopSnapDistance then
    begin
      top := -(height - g_core.NodeInformation.VisibleHeight) - 5;
      Left := Screen.Width div 2 - Width div 2;
      restore_state();
    end

  end
  else if top < g_core.NodeInformation.TopSnapDistance then
    top := 0;
end;

procedure TForm1.CreateRoundRectRgn1(w, h: Integer);
var
  Rgn: HRGN;
begin
  Rgn := CreateRoundRectRgn(0, 0, w, h, 10, 10);

  SetWindowRgn(Handle, Rgn, true);
end;
     procedure tform1.loadInit();
  var
  I: Integer;
  menuItemClickHandlers: array[0..4] of TMenuItemClickHandler;
begin
if img_bg1=nil then

  img_bg1 := timage.Create(nil);
  if not TOSVersion.Check(6, 2) then
    Application.Terminate;

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  if FindAtom('xxyyzz_hotkey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hotkey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;
       killtimer(Handle,10);
  SetTimer(Handle, 10, 10, @TimerProc);

  layout();

  BorderStyle := bsNone;

  CreateRoundRectRgn1(Width + 1, height + 1);
       if pm=nil then

  pm := TPopupMenu.Create(self);
  menuItemClickHandlers[0] := N1Click;
  menuItemClickHandlers[1] := action_bootom_panelClick;
  menuItemClickHandlers[2] := action_setClick;
  menuItemClickHandlers[3] := action_set_acceClick;
  menuItemClickHandlers[4] := action_terminateClick;

  setlength(menuItems, Length(menuItemCaptions));

  for I := 0 to High(menuItems) do
  begin
    menuItems[I] := TMenuItem.Create(self);
    menuItems[I].Caption := menuItemCaptions[I];
    menuItems[I].OnClick := menuItemClickHandlers[I];
    pm.Items.Add(menuItems[I]);
  end;

  PopupMenu := pm;
  form1.OnMouseWheel:=Image111MouseWheel;

     end;
procedure TForm1.FormShow(Sender: TObject);

begin
 loadInit();
end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (g_core.utils.shortcutKey.Trim <> '') then
    g_core.utils.LaunchApplication(g_core.utils.shortcutKey);

end;

// 处理鼠标离开事件
procedure TForm1.Image111MouseLeave(Sender: TObject);
begin

end;

// 移动窗口逻辑
procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  a, rate: double;
  b: double;
  I: Integer;
var
  Distance, ZoomFactor: double;
  NewWidth, NewHeight, NewLeft, NewTop: Integer;
begin
  if g_core.NodeInformation.IsConfiguring then
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
    for I := 0 to g_core.NodeInformation.Count - 1 do
    begin
      a := g_core.NodeInformation.NodesArray[I].Left - ScreenToClient(lp).X + g_core.NodeInformation.NodesArray[I].Width / 2;
      b := g_core.NodeInformation.NodesArray[I].top - ScreenToClient(lp).Y + g_core.NodeInformation.NodesArray[I].height / 4;
      rate := Exp(-sqrt(a * a + b * b) / g_core.utils.CalculateZoomFactor(g_core.NodeInformation.NodeSize));
      rate := Min(Max(rate, 0.5), 1);

      // 根据ZoomFactor来调整按钮的宽度和高度    *1.8

      NewWidth := Round(g_core.NodeInformation.NodesArray[I].OriginalWidth * 2 * rate);
      NewHeight := Round(g_core.NodeInformation.NodesArray[I].OriginalHeight * 2 * rate);

      var maxValue: Integer := 138;
        // 限制按钮的最大宽度和高度
      NewWidth := Min(NewWidth, maxValue);
      NewHeight := Min(NewHeight, maxValue);

//      // 计算按钮的新位置，使其保持在中心点
//      NewLeft := g_core.NodeInformation.NodesArray[I].CenterX - NewWidth div 2;
//      NewTop := g_core.NodeInformation.NodesArray[I].CenterY - NewHeight div 2;
//
//      g_core.NodeInformation.NodesArray[I].SetBounds(NewLeft, NewTop, NewWidth, NewHeight);




      g_core.NodeInformation.NodesArray[I].CenterX := g_core.NodeInformation.NodesArray[I].Left + g_core.NodeInformation.NodesArray[I].Width div 2;
      g_core.NodeInformation.NodesArray[I].CenterY := g_core.NodeInformation.NodesArray[I].Top + g_core.NodeInformation.NodesArray[I].Height div 2;
      g_core.NodeInformation.NodesArray[I].SetBounds(
        g_core.NodeInformation.NodesArray[I].CenterX - NewWidth div 2,
        g_core.NodeInformation.NodesArray[I].CenterY - NewHeight div 2,
        NewWidth, NewHeight);

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
  if g_core.NodeInformation.IsConfiguring then
    exit;

  EventDef.isLeftClick := true;
  EventDef.Y := Y;
  EventDef.X := X;

end;

procedure TForm1.Image111MouseWheel(Sender: TObject; Shift: TShiftState; WheelDelta: Integer; MousePos: TPoint; var Handled: Boolean);
var
  I: Integer;
  NewWidth, NewHeight: Integer;
begin
  if g_core.NodeInformation.IsConfiguring then
    Exit;

  Handled := True;

  // 根据滚轮方向调整节点大小
  if WheelDelta > 0 then
  begin
   var i1:=  g_core.DatabaseManager.cfgDb.GetInteger('ih');
             i1:=round(1.1*i1);
              g_core.NodeInformation.NodeSize := i1;
   g_core.DatabaseManager.cfgDb.SetVarValue('ih',  i1);
  end
  else
  begin
   var i1:=  g_core.DatabaseManager.cfgDb.GetInteger('ih');
   i1:= round(i1*0.9);
    g_core.NodeInformation.NodeSize := i1;
   g_core.DatabaseManager.cfgDb.SetVarValue('ih',  i1);
  end;

  loadInit();

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
  g_core.utils.LaunchApplication('https://fanyi.baidu.com/');
end;

procedure TForm1.action_setClick(Sender: TObject);
var
  vobj: TObject;
begin
  vobj := g_core.FindObjectByName('cfgForm');
  TCfgForm(vobj).Show;

  g_core.NodeInformation.IsConfiguring := true;
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
      g_core.utils.shortcutKey := filename;
      g_core.DatabaseManager.cfgDb.SetVarValue('shortcut', g_core.utils.shortcutKey.Trim);
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

