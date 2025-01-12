unit ApplicationMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  Registry, Winapi.Dwmapi, core, Dialogs, ExtCtrls, Generics.Collections,
  Vcl.Imaging.pngimage, Winapi.ShellAPI, inifiles, Vcl.Imaging.jpeg, u_debug,
  ComObj, PsAPI, utils, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SyncObjs,
  System.Math, System.JSON, u_json, ConfigurationForm, Vcl.Menus, InfoBarForm,
  System.Generics.Collections, plug, TaskbarList, PopupMenuManager, event;

type
  TForm1 = class(TForm)
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);

  private
    node_at_cursor: t_node;

    gdraw_text: string;
    procedure node_click(Sender: TObject);
    procedure wndproc(var Msg: tmessage); override;

  private
    main_background: timage;

    pm: TPopupMenu;
    menuItems: array of TMenuItem;
    procedure node_mouse_enter(Sender: TObject);

    procedure node_mouse_move(Sender: TObject; Shift: TShiftState; X, Y: Integer);
    procedure node_mouse_leave(Sender: TObject);
    procedure CalculateAndPositionNodes();
    procedure img_bgMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure move_windows(h: thandle);

    procedure Initialize_form;

  public
    procedure ConfigureLayout;
  private
    procedure handle_ayout(Sender: TObject);
    procedure form_mouse_wheel(WheelMsg: TWMMouseWheel);
    procedure CleanupPopupMenu;

    procedure FreeDic;
    procedure AdjustNodeSize(Node: t_node; Rate: Double);

    procedure repos(screenHeight: integer);
    procedure nodeimgload;

  end;

const
  DWMWCP_DEFAULT = 0;
  DWMWCP_SQUARE = 1;
  DWMWCP_ROUND = 2;
  DWMWCP_CNTR_RADIUS = 3;

var
  Form1: TForm1;
  tmp_json: TDictionary<string, TSettingItem>;
  cs: TCriticalSection;
  label_top, label_left: integer;

var
  FormPosition: TFormPositions;
  hoverLabel: Boolean = false;

var
  hMouseHook: HHOOK;
  hwndMonitor: HWND;
  heventHook: THandle;
  inOnce: integer = 0;
  finish_layout: Boolean = false;
//  ImageCache: TDictionary<string, timage>;  // New cache dictionary

implementation

{$R *.dfm}

const
  kGetPreferredBrightnessRegKey = 'Software\Microsoft\Windows\CurrentVersion\Themes\Personalize';
  kGetPreferredBrightnessRegValue = 'AppsUseLightTheme';

procedure UpdateTheme(hWnd: hWnd);
var
  Reg: TRegistry;
  LightMode: DWORD;
  EnableDarkMode: BOOL;
begin
  Reg := TRegistry.Create(KEY_READ);
  try
    Reg.RootKey := HKEY_CURRENT_USER;
    if Reg.OpenKeyReadOnly(kGetPreferredBrightnessRegKey) then
    begin
      if Reg.ValueExists(kGetPreferredBrightnessRegValue) then
      begin
        LightMode := Reg.ReadInteger(kGetPreferredBrightnessRegValue);
        EnableDarkMode := LightMode = 0;
        DwmSetWindowAttribute(hWnd, DWMWA_USE_IMMERSIVE_DARK_MODE, @EnableDarkMode, SizeOf(EnableDarkMode));
      end;
    end;
  finally
    Reg.Free;
  end;
end;

procedure ScaleFormForDPI(Form: TForm; ScaleFactor: Double);
begin
  Form.SetBounds(Round(Form.Left * ScaleFactor), Round(Form.Top * ScaleFactor), Round(Form.Width * ScaleFactor), Round(Form.Height * ScaleFactor));
end;

procedure TForm1.nodeimgload();
var
  kys: TDictionary<string, TSettingItem>;
begin

  kys := g_core.json.Settings;

  var keys := kys.keys;
  for var Key in keys do
  begin
    var MValue := kys.Items[Key];
    var p: timage;
    if not g_core.ImageCache.TryGetValue(MValue.image_file_name, p) then
    begin
      p := TImage.Create(nil);
      p.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + MValue.image_file_name);
      g_core.ImageCache.Add(MValue.image_file_name, p);

    end

  end;

end;



// 计算和定位节点的逻辑
            //重新设计 把图片预存到 内存中 不每次再文件中加载

procedure TForm1.CalculateAndPositionNodes();
var
  Node: t_node;
  I, NodeCount, NodeSize, NodeGap: Integer;
  v: TSettingItem;
  ClientCenterY: Integer;
  kys: TDictionary<string, TSettingItem>;
begin

  NodeSize := g_core.nodes.node_size;
  NodeGap := g_core.nodes.node_gap;
  NodeCount := g_core.json.Settings.Count;
  kys := g_core.json.Settings;

  ClientCenterY := (Self.ClientHeight - NodeSize) div 2;

  cs.Enter;
  try
    try

      g_core.nodes.count := NodeCount;

      if g_core.nodes.Nodes <> nil then
        for Node in g_core.nodes.Nodes do
        begin
          kys.TryGetValue(Node.key, v);
          if not v.Is_path_valid then
            FreeAndNil(v.memory_image);
          FreeAndNil(Node);
        end;

      Form1.height := NodeSize + NodeSize div 2 + 130;

      setlength(g_core.nodes.Nodes, NodeCount);
      I := 0;
      var keys := kys.keys;
      for var Key in keys do
      begin
        var MValue := kys.Items[Key];
        Node := t_node.Create(self);
        g_core.nodes.Nodes[I] := Node;
        Node.Width := NodeSize;
        Node.Height := NodeSize;

        if I = 0 then
          Node.Left := NodeGap + exptend
        else
          Node.Left := g_core.nodes.Nodes[I - 1].Left + NodeGap + Node.Width;

        with Node do
        begin

          id := I;
          Top := ClientCenterY;
          Center := true;

          Transparent := true;
          Parent := self;
          file_path := MValue.FilePath;
          tool_tip := MValue.tool_tip;

          if MValue.Is_path_valid then
          begin
            var p: timage;
            if not g_core.ImageCache.TryGetValue(MValue.image_file_name, p) then
            begin

              Node.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + MValue.image_file_name);

            end
            else
            begin

              Node.Picture.Assign(p.Picture);

            end;
          end
          else
          begin
            MValue.memory_image.Position := 0;
            Picture.LoadFromStream(MValue.memory_image);
          end;

          Stretch := true;
          OnMouseLeave := node_mouse_leave;
          OnMouseMove := node_mouse_move;
          OnMouseDown := FormMouseDown;
          OnClick := node_click;

          OnMouseEnter := node_mouse_enter;

          original_size.cx := g_core.nodes.Nodes[I].Width;
          original_size.cy := g_core.nodes.Nodes[I].height;
          center_point.x := g_core.nodes.Nodes[I].Left + g_core.nodes.Nodes[I].Width div 2;
          center_point.y := g_core.nodes.Nodes[I].top + g_core.nodes.Nodes[I].height div 2;

        end;
        Inc(I)
      end;

      if NodeCount > 0 then
        Self.Width := g_core.nodes.Nodes[NodeCount - 1].Left + g_core.nodes.Nodes[NodeCount - 1].Width + NodeGap + exptend;

    except

    end;
  finally
    cs.Leave;
  end;

end;

procedure TForm1.node_mouse_enter(Sender: TObject);
var
  Node: t_node;
begin
  Node := Sender as t_node;

  gdraw_text := Node.tool_tip;

  label_top := Node.Top - 65;
  label_left := Node.Left + (Node.Width div 2);

  hoverLabel := true;
  inOnce := 0;
end;

procedure TForm1.node_mouse_leave(Sender: TObject);
begin

  restore_state;
  inOnce := 0;
end;
// 移动窗口逻辑

procedure TForm1.node_mouse_move(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  rate: double;
  a, b: integer;
  I: Integer;
  NewWidth, NewHeight: Integer;
  Rate11: double;
  Current_node: t_node;
  lp: tpoint;
begin
  if g_core.nodes.is_configuring then
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

    var Node := t_node(Sender);
    if hoverLabel then
    begin
      label_top := Node.Top - 35;
      label_left := Node.Left + (Node.Width div 4); //- (hoverLabel.Width div 2);
    end;

    GetCursorPos(lp);

    node_at_cursor := t_node(Sender);

    if g_core.json.Config.style = 'style-2' then
    begin

        // 调整当前节点
      Current_node := node_at_cursor;

//    var GC := (X mod (Current_node.original_size.cx * 2)) / (Current_node.original_size.cx * 2);
//
//  // 使用 Sin 函数生成 0-1-0 的变化率
//    var Rate11 := Sin(GC * Pi);


      if X > Current_node.original_size.cx div 2 then
      begin

        var NodeCenterX := Current_node.original_size.cx;
        var SymmetricX := Abs(X - NodeCenterX);
        var GC := (SymmetricX mod (Current_node.original_size.cx * 2)) / (Current_node.original_size.cx * 2);
        Rate11 := Sin(GC * Pi);
      end
      else
      begin
        var GC := (X mod (Current_node.original_size.cx * 2)) / (Current_node.original_size.cx * 2);

        Rate11 := Sin(GC * Pi);
      end;
//        Rate11  := 0.5 * (1 - Cos(Pi * Rate11));
      AdjustNodeSize(Current_node, Rate11);
    end
    else if g_core.json.Config.style = 'style-1' then
    begin

      for I := 0 to g_core.nodes.count - 1 do
      begin
        Current_node := g_core.nodes.Nodes[I];
//           if Node= Current_node then
//             Continue;


        a := Current_node.Left - ScreenToClient(lp).X + Current_node.Width div 2;
        b := Current_node.Top - ScreenToClient(lp).Y + Current_node.Height div 4;

        rate := g_core.utils.rate(a, b);
        rate := Min(Max(rate, 0.5), 1);
        if Node = Current_node then
          rate := rate - 0.1;

        NewWidth := Round(Current_node.original_size.cx * 2 * rate);
        NewHeight := Round(Current_node.original_size.cy * 2 * rate);

        var maxValue: Integer := 128;

        NewWidth := Min(NewWidth, maxValue);
        NewHeight := Min(NewHeight, maxValue);

        Current_node.center_point.x := Current_node.Left + Current_node.Width div 2;
        Current_node.center_point.y := Current_node.Top + Current_node.Height div 2;

        if top < top_snap_distance + 100 then
        begin

          Current_node.Width := Floor(Current_node.original_size.cx * 2 * rate);
          Current_node.height := Floor(Current_node.original_size.cx * 2 * rate);
          Current_node.Left := Current_node.Left - Floor((Current_node.Width - Current_node.original_size.cx) * rate) - 6;
        end
        else
        begin

      // 调整顶部位置而不改变底部位置
          var newTop := Current_node.Top - (NewHeight - Current_node.Height);

          Current_node.SetBounds(Current_node.center_point.x - NewWidth div 2, newTop, NewWidth, NewHeight);
        end;


//    中间往外凸显
//       Current_node.SetBounds(Current_node.center_x - NewWidth div 2, Current_node.center_y - NewHeight div 2, NewWidth, NewHeight);

      end;
    end;
    handle_ayout(Self);

  end;
end;

procedure TForm1.FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
begin
  if g_core.nodes.is_configuring then
    exit;
  if Button = mbleft then
  begin
    EventDef.isLeftClick := true;
    EventDef.Y := Y;
    EventDef.X := X;
  end;

end;

procedure TForm1.node_click(Sender: TObject);
begin
  if t_node(Sender).file_path = '' then
    Exit;
  if t_node(Sender).tool_tip = '开始菜单' then
  begin
//    if bottomForm.Caption = 'selfdefinestartmenu' then
      PostMessage(handle, WM_USER + 1031, 0, 0)
//    else
//      SimulateCtrlEsc();

  end
  else if t_node(Sender).tool_tip = '回收站' then
  begin

    if MessageDlg('Are you sure you want to empty the Recycle Bin?', mtConfirmation, [mbYes, mbNo], 0) = mrYes then
    begin
      EmptyRecycleBin();
      MessageDlg('The Recycle Bin has been emptied.', mtInformation, [mbOK], 0);
    end;
  end
  else if t_node(Sender).tool_tip = '' then
    g_core.utils.launch_app(t_node(Sender).file_path)
  else if not BringWindowToFront(t_node(Sender).tool_tip) then
    g_core.utils.launch_app(t_node(Sender).file_path)
  else
    g_core.utils.launch_app(t_node(Sender).file_path);

  EventDef.isLeftClick := False;

end;

procedure tform1.FreeDic;
var
  Key: string;
  SettingItem: TSettingItem;
begin
  for Key in tmp_json.Keys do
  begin
    SettingItem := tmp_json[Key];
    if not SettingItem.Is_path_valid and Assigned(SettingItem.memory_image) then
    begin
      SettingItem.memory_image.Free;
      SettingItem.memory_image := nil;
    end;
  end;
  tmp_json.Free;
end;

procedure tform1.Initialize_form();
begin
  Form1.Font.Name := Screen.Fonts.Text;
  Form1.Font.Size := 9;

  DoubleBuffered := True;
  BorderStyle := bsNone;

  tmp_json := TDictionary<string, TSettingItem>.Create;
  if main_background = nil then
    main_background := timage.Create(self);
  main_background.OnMouseDown := img_bgMouseDown;
  main_background.Width := Width;
  g_core.utils.init_background(main_background, self, 'bg.png');

  cs := TCriticalSection.Create;

  form1.left := g_core.json.Config.Left;
  Form1.top := g_core.json.Config.Top;

  RegisterHotKey(Handle, 119, MOD_CONTROL, Ord('B'));

end;

function MonitorFromWindow(Handle: hWnd; dwFlags: DWORD): HMONITOR; stdcall; external 'user32.dll' name 'MonitorFromWindow';

const
  // 定义MONITOR_DEFAULTTONEAREST常量
  MONITOR_DEFAULTTONEAREST = 2;
  MDT_EFFECTIVE_DPI = 0;

function GetDpiForMonitor(Monitor: HMONITOR; dpiType: DWORD; var dpiX: UINT; var dpiY: UINT): HRESULT; stdcall; external 'shcore.dll' name 'GetDpiForMonitor';

procedure TForm1.wndproc(var Msg: tmessage);
var
  lp: TPoint;
  reducedRect: TRect;
var
  Monitor: HMONITOR;
  DpiX, DpiY: UINT;
  ScaleFactor: Double;
  SuggestedRect: PRect;
begin
  inherited;
  case Msg.Msg of
    WM_HOTKEY:
      begin
        if Msg.WParam = 119 then
        begin
          var v := get_json_value('config', 'shortcut');

          ShellExecute(0, 'open', PChar(v), nil, nil, SW_SHOW);
        end;
      end;
    WM_LBUTTON_MESSAGE:
      begin
        ShellExecute(0, 'open', PChar('https://www.bing.com/search?q=%E6%97%A5%E5%8E%86'), nil, nil, SW_SHOWNORMAL);
      end;

    WM_defaultStart_MESSAGE:
      begin
      //尝试使用 flutter
        var param := ExtractFilePath(ParamStr(0)) + 'img\app';
        var exepath := ExtractFilePath(ParamStr(0)) + 'startx\flutter_application_1.exe';
//        g_core.utils.launch_app(exepath, param);


        var StartupInfo: TStartupInfo;
        var ProcessInfo: TProcessInformation;
        var FilePath: string;
        var Params: string;
        begin
          FilePath := exepath; // Path to your Flutter executable
          Params := param; // Parameters to pass

          FillChar(StartupInfo, SizeOf(StartupInfo), 0);
          StartupInfo.cb := SizeOf(StartupInfo);
          if CreateProcess(nil, PChar(FilePath + ' ' + Params), nil, nil, False, 0, nil, nil, StartupInfo, ProcessInfo) then
          begin
            CloseHandle(ProcessInfo.hProcess);
            CloseHandle(ProcessInfo.hThread);
          end
          else
          begin
            ShowMessage('Failed to start process');
          end;

        end;

      end;
    WM_MY_CUSTOM_MESSAGE:
      begin
        if finish_layout then
        begin
          finish_layout := False;

          reducedRect := Rect(form1.BoundsRect.Left, form1.BoundsRect.Top, form1.BoundsRect.Right, form1.BoundsRect.Bottom - 64);
          GetCursorPos(lp);
          if not PtInRect(reducedRect, lp) then
          begin
            repos(Screen.WorkAreaHeight);
          end;

          finish_layout := true;

        end;
      end;
      //深色 浅色
    WM_DWMCOLORIZATIONCOLORCHANGED:
      begin
        UpdateTheme(Handle);
      end;
    WM_DPICHANGED:
      begin
        OutputDebugString('WM_DPICHANGED');

         // 提取新的 DPI 信息
        DpiX := LOWORD(Msg.wParam);
        DpiY := HIWORD(Msg.wParam);

        // 计算缩放比例
        ScaleFactor := DpiX / 96.0;

        // 获取建议的窗口矩形并调整窗口
        SuggestedRect := PRect(Msg.lParam);
        SetWindowPos(Handle, 0, SuggestedRect.Left, SuggestedRect.Top, SuggestedRect.Right - SuggestedRect.Left, SuggestedRect.Bottom - SuggestedRect.Top, SWP_NOZORDER or SWP_NOACTIVATE);

        // 调整窗体的其他内容（控件、字体等）
        ScaleFormForDPI(Self, ScaleFactor);

      end;
    WM_MOUSEWHEEL:
      form_mouse_wheel(TWMMouseWheel(Msg));
    WM_MOVE:
      begin

        FormPosition := [];

      end;

  end;
end;

procedure TForm1.repos(screenHeight: integer);
begin
  if hoverLabel then
    hoverLabel := false;
    // 计算和定位节点
  form1.CalculateAndPositionNodes();

    // 窗体水平居中屏幕
  form1.Left := Screen.Width div 2 - form1.Width div 2;

    //顶部
  if form1.Top < top_snap_distance then
  begin
    form1.Top := -(form1.Height - visible_height) + 50;

    form1.Left := Screen.Width div 2 - form1.Width div 2;
    restore_state();
    FormPosition := [fpTop];
    g_core.utils.SetTaskbarAutoHide(false);
  end
    //底部
  else if form1.top + form1.height > screenHeight then
  begin
    g_core.utils.SetTaskbarAutoHide(true);
    form1.Top := screenHeight - form1.Height + 130;
    form1.Left := Screen.Width div 2 - form1.Width div 2;
    FormPosition := [fpBottom]; // 设置位置为底部
  end
      //中间
  else
  begin
    FormPosition := [];

    g_core.utils.SetTaskbarAutoHide(false);              //隐藏任务栏
  end;

end;

function LowLevelMouseProc(nCode: Integer; wParam: wParam; lParam: lParam): LRESULT; stdcall;
var
  lp: TPoint;
  reducedRect: TRect;
  mouseStruct: PMSLLHOOKSTRUCT;
  screenHeight: Integer;
  wheelDelta: integer;
begin
  if (nCode = HC_ACTION) then
  begin
    mouseStruct := PMSLLHOOKSTRUCT(lParam);
    if mouseStruct <> nil then
    begin
      if (wParam = WM_MOUSEMOVE) then
      begin

        lp := mouseStruct^.pt;

        screenHeight := Screen.WorkAreaHeight;

        reducedRect := Rect(form1.BoundsRect.Left, form1.BoundsRect.Top, form1.BoundsRect.Right, form1.BoundsRect.Bottom - 64);

        if PtInRect(reducedRect, lp) then
        begin

          form1.FormStyle := fsStayOnTop;
        end
        else
        begin

          form1.FormStyle := fsNormal;
        end;

        if not PtInRect(reducedRect, lp) then
        begin

          inc(inOnce);
          if inOnce > 10000 then
            inOnce := 20;

          if (inOnce < 20) then
          begin
            form1.repos(screenHeight);
          end;
        end
        else
        begin

          if FormPosition = [] then
          begin

          end
          else if fpTop in FormPosition then
          begin

            if form1.Top < top_snap_distance then
              form1.Top := -56;
          end
          else if fpBottom in FormPosition then
          begin

            form1.Top := screenHeight - form1.Height + 80;
          end;
        end;
      end

    end;
  end;

  Result := CallNextHookEx(hMouseHook, nCode, wParam, lParam);
end;

procedure WinEventProc(hook: THandle; event: DWORD; hwnd: hwnd; idObject, idChild: LONG; idEventThread, time: DWORD); stdcall;
var
  rc: TRect;
begin
  // 检查是否是我们想要的窗口和事件
  if (hwnd = hwndMonitor) and (idObject = OBJID_WINDOW) and (idChild = CHILDID_SELF) and (event = EVENT_OBJECT_LOCATIONCHANGE) then
  begin
    // 获取窗口的位置
    if GetWindowRect(hwndMonitor, rc) then
    begin
      // 输出窗口的位置
//      Debug.Show(Format('Window rect is (%d,%d)-(%d,%d)', [rc.Left, rc.Top, rc.Right, rc.Bottom]));

    end;
  end;
end;

procedure global_hook(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  HandleNewProcessesExport();
end;

procedure TForm1.FormShow(Sender: TObject);
var
  processId, threadId: DWORD;
var
  Monitor: HMONITOR;
  DpiX, DpiY: UINT;
  ScaleFactor: Double;
begin
  // 获取窗口所在的监视器
  Monitor := MonitorFromWindow(Handle, MONITOR_DEFAULTTONEAREST);

  // 获取 DPI
  GetDpiForMonitor(Monitor, MDT_EFFECTIVE_DPI, DpiX, DpiY);

  // 计算缩放比例
  ScaleFactor := DpiX / 96.0;

  // 调整窗体大小
  ScaleFormForDPI(Self, ScaleFactor);

  UpdateTheme(Handle);
  takeappico();

  load_plug();
  Initialize_form();

  HideFromTaskbarAndAltTab(Handle);

  nodeimgload();
  ConfigureLayout();

  add_json('startx', 'Start Button.png', 'startx', '开始菜单', True, nil);
  add_json('recycle', 'recycle.png', 'recycle', '回收站', True, nil);

  if bottomForm = nil then
    bottomForm := TbottomForm.Create(self);



// 设置窗体高度为屏幕高度的一半
  bottomForm.Height := Screen.WorkAreaHeight div 2;

// 将窗体顶部设置为屏幕高度的中间位置
  bottomForm.Top := (Screen.WorkAreaHeight - bottomForm.Height) div 2;

  if g_core.json.Config.layout = 'left' then
  begin
  // 将窗体放置在屏幕左侧
    bottomForm.Left := 0; // 或者根据需要调整为 `-bottomForm.Width + 4`
  end
  else
  begin
  // 默认设置为屏幕右侧
    bottomForm.Left := Screen.WorkAreaWidth - bottomForm.Width;
  end;

  bottomForm.show;

  hwndMonitor := Handle;
  hMouseHook := SetWindowsHookEx(WH_MOUSE_LL, @LowLevelMouseProc, 0, 0);

  finish_layout := true;
  //   监控 窗口创建   焦点
  SetCBTHook(Handle);

  //监控 窗口发生变化
  GetWindowThreadProcessId(hwndMonitor, processId);
  heventHook := SetWinEventHook(EVENT_OBJECT_LOCATIONCHANGE, EVENT_OBJECT_LOCATIONCHANGE, 0, @WinEventProc, processId, 0, WINEVENT_OUTOFCONTEXT);
  SetWindowCornerPreference(Handle);

  SetProcessDpiAwarenessContext(DPI_AWARENESS_CONTEXT_PER_MONITOR_AWARE_V2);

  dllmaincpp();

  SetTimer(Handle, 1101, 2000, @global_hook);

  InstallMouseHook();

end;

procedure TForm1.handle_ayout(Sender: TObject);
var
  NewFormWidth: Integer;
  j: Integer;
  Delta: Integer;
  ExpDelta: Double;
  rate: Double;
begin
  var count := g_core.nodes.count;
  var tnodes := g_core.nodes.Nodes;
  var node_gap := g_core.nodes.node_gap;
  NewFormWidth := tnodes[count - 1].Left + tnodes[count - 1].Width + node_gap + exptend;
  // 计算移动的增量
  Delta := NewFormWidth - Width;

  if node_at_cursor <> nil then
  begin
//    rate := 1;
//
//    ExpDelta := Delta * rate;

     // 调整 rate 的值以控制缓动效果的强度
    rate := 0.1;  // 值越小，缓动越慢

    // 使用指数函数计算 ExpDelta
    ExpDelta := Delta * (1 - Exp(-rate));

    SetBounds(Left - Round(ExpDelta) div 2, Top, Width + Round(ExpDelta), Height);

    for j := 0 to count - 1 do
    begin
      var inner_node := tnodes[j];
      if j = 0 then
        inner_node.Left := +exptend
      else
        inner_node.Left := tnodes[j - 1].Left + tnodes[j - 1].Width + node_gap;
    end;
  end;
end;

procedure TForm1.AdjustNodeSize(Node: t_node; Rate: Double);
var
  NewWidth, NewHeight: Integer;
begin
  if Node = nil then
    exit;
//        Rate := 0.5 * (1 - Cos(Pi * Rate));
  NewWidth := Round(Node.Original_Size.cx * (1 + Rate));
  NewHeight := Round(Node.Original_Size.cy * (1 + Rate));

  Node.center_point.x := Node.Left + Node.Width div 2;
  Node.center_point.y := Node.Top + Node.Height div 2;
//
//// 设置当前节点的新尺寸和位置，保持中心点不变
//  Node.SetBounds(Node.center_point.x - NewWidth div 2, Node.center_point.y - NewHeight div 2, NewWidth, NewHeight);


  if top < top_snap_distance + 100 then
  begin

    Node.Width := NewWidth; // Floor(Node.original_size.cx * 1 );
    Node.height := NewHeight; // Floor(Node.original_size.cx * 1 );
    Node.Left := Node.Left - Floor((Node.Width - Node.original_size.cx) * Rate) - 6; //:= Node.Left ;

  end
  else
  begin

      // 调整顶部位置而不改变底部位置
    var newTop := Node.Top - (NewHeight - Node.Height);

    Node.SetBounds(Node.center_point.x - NewWidth div 2, newTop, NewWidth, NewHeight);
  end;

end;

procedure TForm1.FormCreate(Sender: TObject);
begin
          //目的 前端窗口是不是它

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) or WS_EX_LAYERED);

  SetLayeredWindowAttributes(Handle, $000EADEE, 0, LWA_COLORKEY);

end;

procedure TForm1.CleanupPopupMenu;
var
  menuItem: TMenuItem;
begin
  for menuItem in menuItems do
    menuItem.Free;
  pm.Free;
end;

procedure RemoveMouseHook;
begin
  if hMouseHook <> 0 then
  begin
    UnhookWindowsHookEx(hMouseHook);
    hMouseHook := 0;
  end;
  if heventHook <> 0 then
  begin

    UnhookWinEvent(heventHook);
    heventHook := 0;
  end;

end;

procedure TForm1.FormDestroy(Sender: TObject);
var
  v: TSettingItem;
  SettingsObj: TJSONObject;
begin

  RemoveMouseHook();
  UninstallMouseHook();

  SettingsObj := g_jsonobj.GetValue('settings') as TJSONObject;
  if SettingsObj = nil then
    Exit;

  for var KeyValuePair in g_core.json.Settings do
  begin
    if (SettingsObj.GetValue(KeyValuePair.key) = nil) then
    begin
      if (KeyValuePair.Value.Is_path_valid) then
        add_or_update(SettingsObj, KeyValuePair.key, KeyValuePair.Value.image_file_name, KeyValuePair.Value.FilePath, KeyValuePair.Value.tool_tip);
    end;

  end;

  if g_core.nodes.Nodes <> nil then
    for var Node in g_core.nodes.Nodes do
    begin

      FreeAndNil(Node);
    end;

  try
    SaveJSONToFile(ExtractFilePath(ParamStr(0)) + 'cfg.json', g_jsonobj);
  except
    on E: Exception do
    begin
      ShowMessage('Error saving JSON file: ' + E.Message);
    end;
  end;

  CleanupPopupMenu();
  FreeDic();

  cs.Free;
  set_json_value('config', 'left', left.ToString);
  set_json_value('config', 'top', top.ToString);
  main_background.Free;
  UnregisterHotKey(Handle, 119);
end;

procedure TForm1.FormPaint(Sender: TObject);
var
  g: TGPGraphics;
  font: TGPFont;
begin
  if (hoverLabel) then
  begin
    g := TGPGraphics.Create(Canvas.Handle);
    try
      var sbRed := TGPSolidBrush.Create(aclWhite);
      var sbBlack := TGPSolidBrush.Create(aclBlack);
      font := TGPFont.Create('微软雅黑', 16, FontStyleRegular);
      try

        g.DrawString(gdraw_text, -1, font, MakePoint(label_left - 1, label_top + 0.0), sbBlack);
        g.DrawString(gdraw_text, -1, font, MakePoint(label_left + 1, label_top + 0.0), sbBlack);
        g.DrawString(gdraw_text, -1, font, MakePoint(label_left, label_top + 0.0 - 1), sbBlack);
        g.DrawString(gdraw_text, -1, font, MakePoint(label_left, label_top + 0.0 + 1), sbBlack);

        g.DrawString(gdraw_text, -1, font, MakePoint(label_left, label_top + 0.0), sbRed);
      finally
        font.Free;
        sbRed.Free;
        sbBlack.Free;
      end;
    finally
      g.Free;
    end;
  end;

end;

procedure TForm1.form_mouse_wheel(WheelMsg: TWMMouseWheel);
begin
  if g_core.nodes.is_configuring then
    Exit;
  var i1 := g_core.json.Config.nodesize;

  if WheelMsg.WheelDelta > 0 then
    i1 := round(1.1 * i1)
  else
    i1 := round(i1 * 0.9);
  g_core.nodes.node_size := i1;
  set_nodesize_value(g_core.json, i1);
  ConfigureLayout();

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

procedure TForm1.ConfigureLayout();
begin
  g_core.nodes.is_configuring := False;

  CalculateAndPositionNodes();
  var PrimaryMonitorHeight := Screen.monitors[0].height;

  if Form1.top > PrimaryMonitorHeight then
    Form1.top := 0;

  restore_state();

end;

end.

