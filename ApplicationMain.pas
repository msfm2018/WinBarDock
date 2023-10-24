unit ApplicationMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Winapi.Dwmapi, Winapi.ShellAPI, Dialogs, Registry, ExtCtrls, core_db,
  System.Hash, Generics.Collections,
  Vcl.StdCtrls, Vcl.Imaging.pngimage, inifiles, FileCtrl, Vcl.Imaging.jpeg,
  System.Win.TaskbarCore, ShlObj, ActiveX, ComObj,
  u_debug, System.Math, ConfigurationForm, Vcl.Menus, InfoBarForm,
  System.Generics.Collections, event, GDIPAPI, GDIPOBJ, GDIPUTIL;

type
  TForm1 = class(TForm)
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton;
      Shift: TShiftState; X, Y: Integer);
    procedure Image111MouseMove(Sender: TObject; Shift: TShiftState;
      X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure action_setClick(Sender: TObject);
    procedure action_terminateClick(Sender: TObject);
    procedure action_set_acceClick(Sender: TObject);
    procedure action_bootom_panelClick(Sender: TObject);
    procedure N1Click(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure FormPaint(Sender: TObject);
  private
    FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
    procedure img_click(Sender: TObject);

    procedure snap_top_windows;
    procedure CleanupPopupMenu;
  private
  var
    pm: TPopupMenu;
    menuItems: array of TMenuItem;
    procedure CreateRoundRectRgn1(w, h: Integer);
    procedure CalculateAndPositionNodes;

  public

    procedure layout;
  end;

var
  Form1: TForm1;
  menuItemCaptions: array [0 .. 4] of string = (
    '翻译',
    '应用',
    '设置',
    '热键',
    '退出'
  );

implementation

{$R *.dfm}

type
  TMenuItemClickHandler = procedure(Sender: TObject) of object;

procedure TimerProc(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  Form1.snap_top_windows();
end;

procedure TForm1.CalculateAndPositionNodes();
begin
  g_core.NodeInformation.NodeSize := g_core.NodeInformation.nodeWidth;
  var
  hashKeys1 := g_core.DatabaseManager.itemdb.GetKeys();

  g_core.NodeInformation.Count := hashKeys1.Count;

  if g_core.NodeInformation.NodesArray <> nil then
  begin
    for var I := 0 to Length(g_core.NodeInformation.NodesArray) - 1 do
    begin
      freeandnil(g_core.NodeInformation.NodesArray[I]);
    end;
  end;

  setlength(g_core.NodeInformation.NodesArray, g_core.NodeInformation.Count);
  for var I := 0 to g_core.NodeInformation.Count - 1 do
  begin
    g_core.NodeInformation.NodesArray[I] := tnode.Create(self);

    if I = 0 then
      g_core.NodeInformation.NodesArray[I].Left :=
        g_core.utils.CalculateSnapWidth(g_core.NodeInformation.NodeSize) + 10
    else
    begin

      g_core.NodeInformation.NodesArray[I].Left :=
        g_core.NodeInformation.NodesArray[I - 1].Left +
        g_core.NodeInformation.NodesArray[I - 1].Width +
        g_core.utils.CalculateSnapWidth(g_core.NodeInformation.NodeSize);

    end;

    with g_core.NodeInformation.NodesArray[I] do
    begin

      top := g_core.NodeInformation.marginTop;
      Parent := Form1;
      Width := g_core.NodeInformation.NodeSize;
      height := g_core.NodeInformation.NodeSize;
      Transparent := true;
      Center := true;
      nodePath := g_core.DatabaseManager.itemdb.GetString(hashKeys1[I], False);
      var
      tmp := g_core.DatabaseManager.itemdb.GetString(hashKeys1[I]);
      Picture.LoadFromFile(tmp);

      Stretch := true;

      OnMouseMove := Image111MouseMove;
      OnMouseDown := FormMouseDown;
      OnClick := img_click;

      nodeLeft := g_core.NodeInformation.NodesArray[I].Left;
    end;
  end;
  freeandnil(hashKeys1);
  Form1.Left := g_core.DatabaseManager.cfgDb.GetInteger('left');
  Form1.top := g_core.DatabaseManager.cfgDb.GetInteger('top');
  Form1.Width := g_core.NodeInformation.Count * g_core.NodeInformation.NodeSize
    + g_core.NodeInformation.Count * g_core.utils.CalculateSnapWidth
    (g_core.NodeInformation.NodeSize) + 40;

  Form1.height := g_core.utils.CalculateFormHeight
    (g_core.NodeInformation.NodeSize, Form1.height);
end;

procedure TForm1.layout();
begin
  g_core.NodeInformation.NodeSize :=
    g_core.DatabaseManager.cfgDb.GetInteger('ih');

  g_core.NodeInformation.IsConfiguring := False;

  CalculateAndPositionNodes();

  var
  TotalMonitorWidth := 0;

  var
  PrimaryMonitorHeight := Screen.monitors[0].height;
  case Screen.monitorcount of
    1:
      TotalMonitorWidth := Screen.monitors[0].Width;

    2:
      TotalMonitorWidth := Screen.monitors[0].Width + Screen.monitors[1].Width;
  else
    TotalMonitorWidth := Screen.monitors[0].Width;
  end;

  if Form1.Left > TotalMonitorWidth then
    Form1.Left := Screen.monitors[0].Width div 4;
  if Form1.top > PrimaryMonitorHeight then
    Form1.top := 0;

  g_core.utils.shortcutKey := g_core.DatabaseManager.cfgDb.GetString
    ('shortcut');

  restore_state();
  CreateRoundRectRgn1(Width, height);

  if Form1.Width > TotalMonitorWidth then
  begin
    g_core.NodeInformation.nodeWidth := 36;
    g_core.NodeInformation.NodeHeight := 36;
    CalculateAndPositionNodes();
  end;
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

procedure TForm1.snap_top_windows();
var
  lp: tpoint;
  I: Integer;
begin
  KillTimer(Handle, 10);
  if g_core.NodeInformation.IsConfiguring then
  begin
    SetTimer(Handle, 10, 10, @TimerProc);
    exit;
  end;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) then
  begin

    for I := 0 to g_core.NodeInformation.Count - 1 do
    begin
      g_core.NodeInformation.NodesArray[I].Left :=
        g_core.NodeInformation.NodesArray[I].nodeLeft;
      g_core.NodeInformation.NodesArray[I].Width :=
        g_core.NodeInformation.NodeSize;
      g_core.NodeInformation.NodesArray[I].height :=
        g_core.NodeInformation.NodeSize;
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
  SetTimer(Handle, 10, 10, @TimerProc);
end;

procedure TForm1.CreateRoundRectRgn1(w, h: Integer);
var
  Rgn: HRGN;
begin
  Rgn := CreateRoundRectRgn(0, 0, w, h, 20, 20);

  SetWindowRgn(Handle, Rgn, true);
end;

procedure TForm1.FormShow(Sender: TObject);
var
  I: Integer;
  menuItemClickHandlers: array [0 .. 4] of TMenuItemClickHandler;

begin
  if not TOSVersion.Check(6, 2) then
    Application.Terminate;

  BorderStyle := bsNone;

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and
    (not WS_EX_APPWINDOW));
  ShowWindow(Application.Handle, SW_HIDE);
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);

  if FindAtom('xxyyzz_hotkey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('xxyyzz_hotkey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;

  SetTimer(Handle, 10, 10, @TimerProc);
  layout();

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

end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) and (g_core.utils.shortcutKey.Trim <> '') then
    g_core.utils.LaunchApplication(g_core.utils.shortcutKey);

end;

procedure TForm1.Image111MouseMove(Sender: TObject; Shift: TShiftState;
  X, Y: Integer);
var
  a, rate: double;
  b: double;
  I: Integer;
begin
  if g_core.NodeInformation.IsConfiguring then
    exit;
  if (EventDef.isLeftClick) then
  begin
    if (X <> EventDef.X) or (Y <> EventDef.Y) then
    begin
      EventDef.X := X;
      EventDef.Y := Y;

    end
    else
      timage(Sender).OnClick(self);
  end
  else
  begin
    var
      lp: tpoint;
    GetCursorPos(lp);
    for I := 0 to g_core.NodeInformation.Count - 1 do
    begin
      a := g_core.NodeInformation.NodesArray[I].Left - ScreenToClient(lp).X +
        g_core.NodeInformation.NodesArray[I].Width / 2;
      b := g_core.NodeInformation.NodesArray[I].top - ScreenToClient(lp).Y +
        g_core.NodeInformation.NodesArray[I].height / 4;
      // rate := 1 - sqrt(a * a + b * b) / g_core.utils.get_zoom_factor(g_core.NodeInformation.nodeWH);
      // rate := Min(Max(rate, 0.5), 1);
      rate := Exp(-sqrt(a * a + b * b) / g_core.utils.CalculateZoomFactor
        (g_core.NodeInformation.NodeSize));
      rate := Min(Max(rate, 0.5), 1);

      // a := Abs(g_core.NodeInformation.diagnosticsNode[i].Left - ScreenToClient(lp).X);
      // rate := 1 / (1 + Exp(-a / (g_core.NodeInformation.nodeWidth * 2)));
      // rate := Min(Max(rate, 0.5), 1);

      g_core.NodeInformation.NodesArray[I].Width :=
        Floor(g_core.NodeInformation.NodeSize * 1.4 * rate);
      g_core.NodeInformation.NodesArray[I].height :=
        Floor(g_core.NodeInformation.NodeSize * 1.4 * rate);

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
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton;
  Shift: TShiftState; X, Y: Integer);
begin
  if g_core.NodeInformation.IsConfiguring then
    exit;

  EventDef.isLeftClick := true;
  EventDef.Y := Y;
  EventDef.X := X;
  ReleaseCapture;
  SendMessage(Handle, WM_SYSCOMMAND, SC_MOVE + HTCaption, 0);
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
  SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0,
    SWP_NOMOVE or SWP_NOSIZE);
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
      g_core.DatabaseManager.cfgDb.SetVarValue('shortcut',
        g_core.utils.shortcutKey.Trim);
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
  TbottomForm(vobj).Left :=
    ((Screen.WorkAreaWidth - TbottomForm(vobj).Width) div 2);

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

procedure TForm1.FormPaint(Sender: TObject);
var
  Image: TGPImage;
  Graphics: TGPGraphics;
  WidthRatio, HeightRatio, Ratio: Single;
begin
  Image := TGPImage.Create(ExtractFilePath(ParamStr(0)) + 'img\bg.png');
  Graphics := TGPGraphics.Create(Canvas.Handle);

  try
    WidthRatio := ClientWidth / Image.GetWidth;
    HeightRatio := ClientHeight / Image.GetHeight;
    Ratio := Min(WidthRatio, HeightRatio);
    // Graphics.DrawImage(Image, 0, 0, Image.GetWidth * Ratio, Image.GetHeight);
    Graphics.DrawImage(Image, 0, 0, Image.GetWidth * Ratio, height);
  finally
    Image.Free;
    Graphics.Free;
  end;
end;

end.
