unit main;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, core_db,
  Vcl.StdCtrls, Vcl.Imaging.pngimage, inifiles, FileCtrl, Vcl.Imaging.jpeg,
  u_debug, System.Math, cfg_form, Vcl.Menus, bottom_Form,
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
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure N1Click(Sender: TObject);
  private
    FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure wndproc(var Msg: tmessage); override;
    procedure img_click(Sender: TObject);
    procedure move_windows(h: thandle);
    procedure snap_top_windows;
    procedure Image111MouseLeave(Sender: TObject);

  public
    img_bg1: timage;
    procedure layout;
    procedure draw_setClick(Sender: TObject);
  end;

var
  Form1: TForm1;
  localPath: string;

implementation

{$R *.dfm}

function StartHook(): Bool; stdcall; external 'brush.dll';
//

function StopHook: Bool; stdcall; external 'brush.dll';

procedure TForm1.layout();
begin
  g_core.nodes.nodeWidth := g_core.db.cfgDb.GetInteger('ih');
  g_core.nodes.nodeHeight := g_core.db.cfgDb.GetInteger('ih');
  g_core.nodes.isCfging := False;

  img_bg1.Parent := Self;
  img_bg1.Align := alClient;
  img_bg1.Transparent := true;
  img_bg1.Stretch := true;

// if  g_core.db.cfgDb.GetInteger('bgVisible')=0 then begin
  img_bg1.Picture.LoadFromFile(localPath + 'img\bgx.png');
// end;
  img_bg1.OnMouseDown := img_bgMouseDown;
  var hashKeys1 := g_core.db.itemdb.GetKeys();

  g_core.nodes.nodeCount := hashKeys1.Count;

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

      top := g_core.nodes.marginTop;
      Parent := Form1;
      Width := g_core.nodes.nodeWidth;
      height := g_core.nodes.nodeHeight;
      Transparent := true;
      Center := true;
      nodePath := g_core.db.itemdb.GetString(hashKeys1[I], False);

      var tmp := g_core.db.itemdb.GetString(hashKeys1[I]);
      Picture.LoadFromFile(tmp);

      Stretch := true;

      OnMouseMove := Image111MouseMove;
      OnMouseLeave := Image111MouseLeave;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;

      nodeLeft := g_core.nodes.diagnosticsNode[I].Left;
    end;

  end;
  var testWidth := 0;
  var testTop := 0;
  testTop := Screen.monitors[0].height;
  case Screen.monitorcount of
    1:
      begin
        testWidth := Screen.monitors[0].Width;

      end;
    2:
      begin
        testWidth := Screen.monitors[0].Width + Screen.monitors[1].Width;
      end
  else
    begin
      testWidth := Screen.monitors[0].Width;
    end;
  end;
  Form1.Width := g_core.nodes.nodeCount * g_core.db.cfgDb.GetInteger('ih') + g_core.nodes.nodeCount * g_core.utils.get_snap(g_core.nodes.nodeWidth) + 20;

  Form1.Left := g_core.db.cfgDb.GetInteger('left');
  Form1.top := g_core.db.cfgDb.GetInteger('top');

  if Form1.Left > testWidth then
    Form1.Left := Screen.monitors[0].Width div 4;
  if Form1.top > testTop then
    Form1.top := 0;

  Form1.height := g_core.utils.get_form_height(g_core.db.cfgDb.GetInteger('ih'));

  freeandnil(hashKeys1);
  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  g_core.utils.shortcutKey := g_core.db.cfgDb.GetString('shortcut');

  restore_state();
end;

procedure TForm1.img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if (Button = mbLeft) then
    move_windows(Handle);

end;

procedure TForm1.img_click(Sender: TObject);
begin
  g_core.utils.launcher(tnode(Sender).nodePath);
  EventDef.isLeftClick := False;

end;

procedure TForm1.action_terminateClick(Sender: TObject);
begin
  g_core.db.cfgDb.SetVarValue('left', Left);
  g_core.db.cfgDb.SetVarValue('top', top);
  Application.Terminate;
end;

procedure TForm1.snap_top_windows();
var
  lp: tpoint;
  I: Integer;
begin

  if g_core.nodes.isCfging then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

    for I := 0 to g_core.nodes.nodeCount - 1 do
    begin
      g_core.nodes.diagnosticsNode[I].Left := g_core.nodes.diagnosticsNode[I].nodeLeft;
      g_core.nodes.diagnosticsNode[I].Width := g_core.nodes.nodeWidth;
      g_core.nodes.diagnosticsNode[I].height := g_core.nodes.nodeHeight;
    end;

    if top < g_core.nodes.topSnapGap then
    begin
      top := -(height - g_core.nodes.VisHeight) - 5;
      Left := Screen.Width div 2 - Width div 2;
      restore_state();
    end;

  end
  else if top < g_core.nodes.topSnapGap then
    top := 0;
end;

procedure TimerProc(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  Form1.snap_top_windows();
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

procedure TForm1.FormShow(Sender: TObject);
begin
  img_bg1 := TImage.Create(nil);
  if not TOSVersion.Check(6, 2) then
    Application.Terminate;
  BorderStyle := bsNone;

  if FindAtom('xxyyzz_hotkey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hotkey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;
  localPath := ExtractFilePath(ParamStr(0));

  SetTimer(Handle, 10, 10, @TimerProc);
  layout();

  var pm: TPopupMenu;
  var m0, mi, m1, m2, m3, m4: TMenuItem;
  begin
    pm := TPopupMenu.Create(self);
    mi := TMenuItem.Create(self);
    mi.Caption := '翻译';
    mi.OnClick := N1Click;

    pm.Items.Add(mi);

    m0 := TMenuItem.Create(self);
    m0.Caption := '画图';
    m0.OnClick := draw_setClick;
    pm.Items.Add(m0);

    m1 := TMenuItem.Create(self);
    m1.Caption := '设置';
    m1.OnClick := action_setClick;
    pm.Items.Add(m1);
    m2 := TMenuItem.Create(self);
    m2.Caption := '应用';
    m2.OnClick := action_bootom_panelClick;
    pm.Items.Add(m2);
    m3 := TMenuItem.Create(self);
    m3.Caption := '热键';
    pm.Items.Add(m3);
    m3.OnClick := action_set_acceClick;

    m4 := TMenuItem.Create(self);
    m4.Caption := '退出';
    pm.Items.Add(m4);
    m4.OnClick := action_terminateClick;
    form1.PopupMenu := pm;
  end;
end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (g_core.utils.shortcutKey.Trim <> '') then
    g_core.utils.launcher(g_core.utils.shortcutKey);

end;

procedure TForm1.Image111MouseLeave(Sender: TObject);
begin

end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  a, b, rate: Real;
begin
  if g_core.nodes.isCfging then
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
      TImage(Sender).OnClick(self);

  end
  else
  begin

    var lp: tpoint;
    var I: Integer;
    GetCursorPos(lp);

    for I := 0 to g_core.nodes.nodeCount - 1 do
    begin

      a := g_core.nodes.diagnosticsNode[I].Left - ScreenToClient(lp).X + g_core.nodes.diagnosticsNode[I].Width / 2;
      b := g_core.nodes.diagnosticsNode[I].top - ScreenToClient(lp).Y + g_core.nodes.diagnosticsNode[I].height / 4;

      rate := 1 - sqrt(a * a + b * b) / g_core.utils.get_zoom_factor(g_core.nodes.nodeWidth);

      if (rate <= 0.5) then
        rate := 0.5
      else if (rate >= 1) then
        rate := 1;

      if I = g_core.nodes.nodeCount then
      begin
        g_core.nodes.diagnosticsNode[I].Width := Floor(g_core.nodes.nodeWidth * 1.8 * rate);
        g_core.nodes.diagnosticsNode[I].height := Floor(g_core.nodes.nodeWidth * 1.8 * rate);
      end
      else
      begin

        g_core.nodes.diagnosticsNode[I].Width := Floor(g_core.nodes.nodeWidth * 1.4 * rate);
        g_core.nodes.diagnosticsNode[I].height := Floor(g_core.nodes.nodeWidth * 1.4 * rate);
        g_core.nodes.diagnosticsNode[I].Left := g_core.nodes.diagnosticsNode[I].nodeLeft - Floor((g_core.nodes.diagnosticsNode[I].Width - g_core.nodes.nodeWidth) * rate) - 6;
      end;

    end;
  end;
end;

procedure TForm1.FormDestroy(Sender: TObject);
begin
  img_bg1.Free;
  UnregisterHotKey(Handle, FShowkeyid);
  GlobalDeleteAtom(FShowkeyid);
  KillTimer(Handle, 10);
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if g_core.nodes.isCfging then
    exit;

  EventDef.isLeftClick := true;
  EventDef.Y := Y;
  EventDef.X := X;

end;

procedure TForm1.move_windows(h: thandle);
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
  vobj := g_core.find('cfgForm');
  TCfgForm(vobj).Show;

  g_core.nodes.isCfging := true;
  SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
end;

procedure TForm1.draw_setClick(Sender: TObject);
begin
  StartHook();
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

  TbottomForm(vobj).top := Screen.WorkAreaHeight - TbottomForm(vobj).height;
  TbottomForm(vobj).Width := Screen.WorkAreaWidth - 10;
  TbottomForm(vobj).Left := ((Screen.WorkAreaWidth - TbottomForm(vobj).Width) div 2);

  restore_state();
end;

end.

