unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, core_db,
  Vcl.StdCtrls, Vcl.Imaging.pngimage, inifiles, FileCtrl, Vcl.Imaging.jpeg,
  u_debug, System.Math, cfg_form, Vcl.Menus, bottom_Form,
  system.Generics.Collections, event, GDIPAPI, GDIPOBJ, GDIPUTIL;

type
  TForm1 = class(TForm)
    img_bg: TImage;
    PopupMenu1: TPopupMenu;
    action_set: TMenuItem;
    action_terminate: TMenuItem;
    action_set_acce: TMenuItem;
    action_bootom_panel: TMenuItem;
    N1: TMenuItem;
    N2: TMenuItem;
    N3: TMenuItem;
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure action_setClick(Sender: TObject);
    procedure action_terminateClick(Sender: TObject);
    procedure action_set_acceClick(Sender: TObject);
    procedure action_bootom_panelClick(Sender: TObject);
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
  private
    FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure wndproc(var msg: tmessage); override;
    procedure img_click(Sender: TObject);
    procedure move_windows(h: thandle);
    procedure snap_top_windows;
    procedure Image111MouseLeave(Sender: TObject);

  public
    procedure layout;
  end;

var
  Form1: TForm1;
  localPath: string;

implementation

{$R *.dfm}

procedure tform1.layout();
begin
  g_core.nodes.nodeWidth := g_core.db.cfgDb.GetInteger('ih');
  g_core.nodes.nodeHeight := g_core.db.cfgDb.GetInteger('ih');
  g_core.nodes.isCfging := False;

  img_bg.Picture.LoadFromFile(localPath + 'img\bgx.png');

  var hashKeys1 := g_core.db.itemdb.GetKeys();

  g_core.nodes.nodeCount := hashKeys1.Count;

  ///首次加载软件
  if g_core.nodes.nodeCount = 0 then
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

    g_core.utils.fileMap.TryAdd(localPath + 'img\01.png', SysTemDir + '\notepad.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\02.png', SysTemDir + '\calc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\03.png', SysTemDir + '\mspaint.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\04.png', SysTemDir + '\cmd.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\05.png', SysTemDir + '\mstsc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\06.png', SysTemDir + '\mstsc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\07.png', SysTemDir + '\mstsc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\08.png', SysTemDir + '\mstsc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\09.png', SysTemDir + '\mstsc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\10.png', SysTemDir + '\mstsc.exe');
    g_core.utils.fileMap.TryAdd(localPath + 'img\11.png', SysTemDir + '\mstsc.exe');
    g_core.utils.update_db;

    g_core.nodes.nodeCount := g_core.db.itemdb.GetKeys().Count;
    hashKeys1 := g_core.db.itemdb.GetKeys();
  end;

  if g_core.nodes.diagnosticsNode <> nil then
  begin
    for var I := 0 to Length(g_core.nodes.diagnosticsNode) - 1 do
    begin
      freeandnil(g_core.nodes.diagnosticsNode[I]);
    end;
  end;

  setlength(g_core.nodes.diagnosticsNode, g_core.nodes.nodeCount);
  for var I := 0 to g_core.nodes.nodeCount - 1 do
  begin
    g_core.nodes.diagnosticsNode[I] := tnode.Create(self);

    g_core.nodes.diagnosticsNode[I].Name := 'image' + I.ToString;

    if I = 0 then
      g_core.nodes.diagnosticsNode[I].Left := I * g_core.nodes.nodeWidth + g_core.utils.get_snap(g_core.nodes.nodeWidth) + 10
    else
    begin

      g_core.nodes.diagnosticsNode[I].Left := g_core.nodes.diagnosticsNode[I - 1].Left + g_core.nodes.diagnosticsNode[I - 1].Width + g_core.utils.get_snap(g_core.nodes.nodeWidth);

    end;

    with g_core.nodes.diagnosticsNode[I] do
    begin
    //离父顶部高度
      top := g_core.nodes.marginTop;
      Parent := Form1;
      width := g_core.nodes.nodeWidth;
      height := g_core.nodes.nodeHeight;
      Transparent := true;
      Center := true;
      nodePath := g_core.db.itemdb.GetString(hashKeys1[i], false);

      var tmp := g_core.db.itemdb.GetString(hashKeys1[i]);
      Picture.LoadFromFile(tmp);

      Stretch := true;

      OnMouseMove := Image111MouseMove;
      OnMouseLeave := Image111MouseLeave;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;

      nodeLeft := g_core.nodes.diagnosticsNode[I].Left;
    end;

  end;

  form1.width := g_core.nodes.nodeCount * g_core.db.cfgDb.GetInteger('ih') + g_core.nodes.nodeCount * g_core.utils.get_snap(g_core.nodes.nodeWidth) + 20;
  form1.Left := g_core.db.cfgDb.GetInteger('left');
  form1.Top := g_core.db.cfgDb.GetInteger('top');

  form1.Height := g_core.utils.get_form_height(g_core.db.cfgDb.GetInteger('ih'));

  freeandnil(hashKeys1);
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  g_core.utils.shortcutKey := g_core.db.cfgdb.GetString('shortcut');

  restore_state();
end;

procedure TForm1.img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
    move_windows(handle);

end;

procedure TForm1.img_click(Sender: TObject);
begin
  g_core.utils.launcher(tnode(Sender).nodePath);
  EventDef.isLeftClick := false;

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

  if g_core.nodes.isCfging then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

//    复原按钮原始尺寸
    for I := 0 to g_core.nodes.nodeCount - 1 do
    begin
      g_core.nodes.diagnosticsNode[I].Left := g_core.nodes.diagnosticsNode[I].nodeLeft;
      g_core.nodes.diagnosticsNode[I].Width := g_core.nodes.nodeWidth;
      g_core.nodes.diagnosticsNode[I].height := g_core.nodes.nodeHeight;
    end;

//    吸附桌面顶端
    if Top < g_core.nodes.topSnapGap then
    begin
      Top := -(Height - g_core.nodes.VisHeight) - 5;
      Left := Screen.Width div 2 - Width div 2;
      restore_state();
    end;

  end
  else if Top < g_core.nodes.topSnapGap then
    Top := 0;
end;

procedure TimerProc(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  form1.snap_top_windows();
end;

procedure TForm1.wndproc(var msg: tmessage);
begin
  inherited;
  case msg.Msg of
    WM_MOUSEMOVE, WM_MOUSEACTIVATE, WM_MOUSEHOVER:
      begin
        KillTimer(Handle, 10);
        SetTimer(handle, 10, 10, @TimerProc);
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

procedure TForm1.FormShow(Sender: TObject);
begin
  if not TOSVersion.Check(6, 2) then // Windows 8
    Application.Terminate;
  BorderStyle := bsNone;
    ///定义热键
  if FindAtom('xxyyzz_hotkey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hotkey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);       // ctrl+b   定义快捷键
  end;
  localPath := ExtractFilePath(ParamStr(0));
  ///检测顶部吸附
  SetTimer(handle, 10, 10, @TimerProc);
  layout();

end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (g_core.utils.shortcutKey.Trim <> '') then
    g_core.utils.launcher(g_core.utils.shortcutKey);

end;

procedure TForm1.Image111MouseLeave(Sender: TObject);
begin
  //
end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  a, b, rate: Real;
begin
  if g_core.nodes.isCfging then
    Exit;

  if (EventDef.isLeftClick) then
  begin

    if (X <> EventDef.x) or (Y <> EventDef.y) then
    begin
      EventDef.x := X;
      EventDef.y := Y;
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

    for I := 0 to g_core.nodes.nodeCount - 1 do
    begin

      a := g_core.nodes.diagnosticsNode[I].Left - ScreenToClient(lp).X + g_core.nodes.diagnosticsNode[I].Width / 2;
      b := g_core.nodes.diagnosticsNode[I].Top - ScreenToClient(lp).Y + g_core.nodes.diagnosticsNode[I].Height / 4;

      rate := 1 - sqrt(a * a + b * b) / g_core.utils.get_zoom_factor(g_core.nodes.nodeWidth);

      if (rate <= 0.5) then
        rate := 0.5
      else if (rate >= 1) then
        rate := 1;

      if I = g_core.nodes.nodeCount then
      begin
        g_core.nodes.diagnosticsNode[I].Width := Floor(g_core.nodes.nodeWidth * 1.8 * rate);
        g_core.nodes.diagnosticsNode[I].Height := Floor(g_core.nodes.nodeWidth * 1.8 * rate);
      end
      else
      begin

        g_core.nodes.diagnosticsNode[I].Width := Floor(g_core.nodes.nodeWidth * 1.4 * rate);
        g_core.nodes.diagnosticsNode[I].Height := Floor(g_core.nodes.nodeWidth * 1.4 * rate);
        g_core.nodes.diagnosticsNode[I].Left := g_core.nodes.diagnosticsNode[I].nodeLeft - Floor((g_core.nodes.diagnosticsNode[I].Width - g_core.nodes.nodeWidth) * rate) - 6;
      end;

    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  UnregisterHotKey(Handle, FShowkeyid);
  GlobalDeleteAtom(FShowkeyid);
  KillTimer(Handle, 10);
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if g_core.nodes.isCfging then
    exit;

  EventDef.isLeftClick := true;
  EventDef.y := Y;
  EventDef.x := X;

end;

procedure tform1.move_windows(h: thandle);
begin

  ReleaseCapture;
  SendMessage(h, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);

end;

procedure TForm1.N1Click(Sender: TObject);
begin
 g_core.utils.launcher('https://fanyi.baidu.com/');
end;

procedure TForm1.action_setClick(Sender: TObject);
var
  vobj: TObject;
begin
    vobj:=    g_core.find('cfgForm')    ;
  TCfgForm(vobj).Show;

  g_core.nodes.isCfging := true;
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
      g_core.utils.shortcutKey := FileName;
      g_core.db.cfgDb.SetVarValue('shortcut', g_core.utils.shortcutKey.Trim);
    end;
  end;
  OpenDlg.free;

end;

procedure TForm1.action_bootom_panelClick(Sender: TObject);
var
  vobj: TObject;
begin

  vobj := g_core.find('bottomForm');
  TbottomForm(vobj).Show;

  TbottomForm(vobj).Top := Screen.WorkAreaHeight - TbottomForm(vobj).height;
  TbottomForm(vobj).Width := Screen.WorkAreaWidth - 10;
  TbottomForm(vobj).Left := ((Screen.WorkAreaWidth - TbottomForm(vobj).Width) div 2);

  restore_state();
end;

end.

