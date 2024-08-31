unit ApplicationMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Dialogs, ExtCtrls, Generics.Collections, Vcl.Imaging.pngimage,
  Winapi.ShellAPI, inifiles, Vcl.Imaging.jpeg, u_debug, ComObj, PsAPI,
  Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SyncObjs, System.Math, System.JSON,
  u_json, ConfigurationForm, Vcl.Menus, InfoBarForm, System.Generics.Collections,
  event, Vcl.StdCtrls;

type
  TForm1 = class(TForm)
    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure action_config(Sender: TObject);
    procedure action_terminate(Sender: TObject);
    procedure action_set_acce(Sender: TObject);

    procedure action_translator(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure FormCreate(Sender: TObject);
    procedure FormPaint(Sender: TObject);

  private
    node_at_cursor: t_node;

    gdraw_text: string;
    procedure node_click(Sender: TObject);
    procedure wndproc(var Msg: tmessage); override;
    procedure snap_top_windows;
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
  private
    FAltF4Key, FShowkeyid: Word;
    procedure hotkey(var Msg: tmsg); message WM_HOTKEY;
  public
    hoverLabel: TLabel;
    procedure ConfigureLayout;
  private
    FCurrentNode: t_node;

    procedure handle_animation_tick(Sender: TObject; lp: TPoint);
    function get_node_at_point(ScreenPoint: TPoint): t_node;
    procedure form_mouse_wheel(WheelMsg: TWMMouseWheel);
    procedure CleanupPopupMenu;

    procedure FreeDictionary;
    procedure action_hide_desk(Sender: TObject);
    procedure AdjustNodeSize(Node: t_node; Rate: Double);

  end;

var
  Form1: TForm1;
  tmp_json: TDictionary<string, TSettingItem>;
  cs: TCriticalSection;
  inOnce: integer = 0;

var
  FormPosition: TFormPositions;

implementation

{$R *.dfm}


// 计算和定位节点的逻辑

procedure TForm1.CalculateAndPositionNodes();
var
  Node: t_node;
  I: Integer;
  v: TSettingItem;
begin
  cs.Enter;
  try
    g_core.nodes.count := g_core.json.Settings.Count;

    if g_core.nodes.Nodes <> nil then
      for Node in g_core.nodes.Nodes do
      begin
        g_core.json.Settings.TryGetValue(Node.key, v);
        if not v.Is_path_valid then
          FreeAndNil(v.memory_image);
        FreeAndNil(Node);
      end;

    Form1.height := g_core.nodes.node_size + g_core.nodes.node_size div 2 + 130;

    setlength(g_core.nodes.Nodes, g_core.nodes.count);
    I := 0;
    for var Key in g_core.json.Settings.keys do
    begin
      var MValue := g_core.json.Settings.Items[Key];
      Node := t_node.Create(self);
      g_core.nodes.Nodes[I] := Node;
      Node.Width := g_core.nodes.node_size;
      Node.Height := g_core.nodes.node_size;

      if I = 0 then
        Node.Left := g_core.nodes.node_gap + exptend
      else

        Node.Left := g_core.nodes.Nodes[I - 1].Left + g_core.nodes.node_gap + Node.Width;

      with Node do
      begin
        id := I;
        Top := (Self.ClientHeight - g_core.nodes.node_size) div 2;
        Center := true;

        Transparent := true;
        Parent := self;
        file_path := MValue.FilePath;
        tool_tip := MValue.tool_tip;

        if MValue.Is_path_valid then
          Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + MValue.image_file_name)
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

    if g_core.nodes.count > 0 then
      Self.Width := g_core.nodes.Nodes[g_core.nodes.count - 1].Left + g_core.nodes.Nodes[g_core.nodes.count - 1].Width + g_core.nodes.node_gap + exptend;

  except

  end;
  cs.Leave;
end;

procedure TForm1.snap_top_windows();
var
  lp: TPoint;
  screenHeight: Integer;
  reducedRect: TRect;
begin
  if g_core.nodes.is_configuring then
    Exit;

  GetCursorPos(lp);
  screenHeight := Screen.WorkAreaHeight;

  // 检查光标是否在窗体范围内且当前没有在捕捉窗口
//  if not PtInRect(Self.BoundsRect, lp) then

  reducedRect := Rect(Self.BoundsRect.Left, Self.BoundsRect.Top, Self.BoundsRect.Right, Self.BoundsRect.Bottom - 64);

  if not PtInRect(reducedRect, lp) then
  begin

    inc(inOnce);
    if inOnce > 10000 then
      inOnce := 20;

    if (inOnce < 20) then
    begin
    // 计算和定位节点
      CalculateAndPositionNodes();

    // 窗体水平居中屏幕
      Left := Screen.Width div 2 - Width div 2;

    //顶部
      if Top < top_snap_distance then
      begin
        Top := -(Height - visible_height) + 50;

        Left := Screen.Width div 2 - Width div 2;
        restore_state();
        FormPosition := [fpTop];
        g_core.utils.SetTaskbarAutoHide(false);
      end
    //底部
      else if top + height > screenHeight then
      begin
        g_core.utils.SetTaskbarAutoHide(true);
        Top := screenHeight - Height + 130;
        Left := Screen.Width div 2 - Width div 2;
        FormPosition := [fpBottom]; // 设置位置为底部
      end
      //中间
      else
      begin
        FormPosition := [];

        g_core.utils.SetTaskbarAutoHide(false);              //隐藏任务栏
      end;

    end;
  end
  else
  begin

    if FormPosition = [] then
    begin

    end
    else if fpTop in FormPosition then
    begin
      if Top < top_snap_distance then
        Top := -56;
    end
    else if fpBottom in FormPosition then
    begin
      Top := screenHeight - Height + 80;
    end;

  end
end;

procedure tform1.FreeDictionary;
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
var
  menuItemClickHandlers: array[0..5] of t_menu_click_handler;
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

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  ShowWindow(Application.Handle, SW_HIDE);

  if pm = nil then
    pm := TPopupMenu.Create(self);
  menuItemClickHandlers[0] := action_translator;

  menuItemClickHandlers[1] := action_config;
  menuItemClickHandlers[2] := action_set_acce;
  menuItemClickHandlers[3] := action_terminate;

  menuItemClickHandlers[4] := action_hide_desk;
  setlength(menuItems, Length(menu_labels));

  for var I := 0 to High(menuItems) do
  begin
    menuItems[I] := TMenuItem.Create(self);
    menuItems[I].Caption := menu_labels[I];
    menuItems[I].OnClick := menuItemClickHandlers[I];
    pm.Items.Add(menuItems[I]);
  end;

  PopupMenu := pm;

  exclusion_app := g_core.json.Exclusion.Value;

  if FindAtom('ZWXhoaabbtKey') = 0 then
  begin
    FShowkeyid := GlobalAddAtom('ZWXhoaabbtKey');
    RegisterHotKey(Handle, FShowkeyid, MOD_CONTROL, $42);
  end;

end;

procedure TForm1.hotkey(var Msg: tmsg);
begin
  if (Msg.message = FShowkeyid) then
  begin

    var v := get_json_value('config', 'shortcut');

    ShellExecute(0, 'open', PChar(v), nil, nil, SW_SHOW);
  end;
end;

procedure TForm1.node_mouse_enter(Sender: TObject);
var
  Node: t_node;
begin
  Node := Sender as t_node;

  if not Assigned(hoverLabel) then
  begin
    hoverLabel := TLabel.Create(Self);
    hoverLabel.Parent := Parent;
    hoverLabel.Transparent := True;
    hoverLabel.Caption := Node.tool_tip;
    gdraw_text := Node.tool_tip;
    hoverLabel.Font.Size := 14;
    hoverLabel.Font.Color := clBlack;
  end;

  hoverLabel.Left := Node.Left + (Node.Width div 2) - (hoverLabel.Width div 2);
  hoverLabel.Top := Node.Top - hoverLabel.Height - 5;
  hoverLabel.Visible := True;

  inOnce := 0;
end;

procedure TForm1.node_mouse_leave(Sender: TObject);
begin
  hoverLabel.Visible := false;
  if hoverLabel <> nil then
    FreeAndNil(hoverLabel);
  restore_state;
  inOnce := 0;
end;

procedure TForm1.wndproc(var Msg: tmessage);
begin
  inherited;
  case Msg.Msg of
    WM_TIMER:
      begin
        snap_top_windows();
      end;
    WM_MOUSEWHEEL:
      form_mouse_wheel(TWMMouseWheel(Msg));
    WM_MOVE:
      begin

        FormPosition := [];

      end;
//      WM_ENTERSIZEMOVE:begin
//
//      end;
//      WM_EXITSIZEMOVE:begin

//      end;
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin

  Initialize_form();

  ConfigureLayout();
  SetTimer(Handle, 10, 10, nil);

  add_json('startx', 'Start Button.png', 'startx', '开始菜单', True, nil);
  add_json('recycle', 'recycle.png', 'recycle', '回收站', True, nil);

  if bottomForm = nil then
    bottomForm := TbottomForm.Create(self);

  bottomForm.top := 0;

  if g_core.json.Config.layout = 'left' then
  begin
    bottomForm.Left := -bottomForm.Width + 4;
  end
  else
    bottomForm.Left := Screen.WorkAreaWidth - bottomForm.Width;

  bottomForm.Height := Screen.WorkAreaHeight;
  bottomForm.show;
end;

function TForm1.get_node_at_point(ScreenPoint: TPoint): t_node;
var
  ClientPoint: TPoint;
  I: Integer;
  Node: t_node;
begin
  Result := nil;

  ClientPoint := ScreenToClient(ScreenPoint);

  for I := 0 to g_core.nodes.count - 1 do
  begin
    Node := g_core.nodes.Nodes[I];

    if PtInRect(Node.BoundsRect, ClientPoint) then
    begin
      Result := Node;
      Exit;
    end;
  end;
end;

//procedure TForm1.handle_animation_tick(Sender: TObject; lp: TPoint);
//var
//  NewFormWidth: Integer;
//  j: Integer;
//  Delta: Integer;
//  ExpDelta: Double;
//  rate: Double;
//begin
//  NewFormWidth := g_core.nodes.Nodes[g_core.nodes.count - 1].Left + g_core.nodes.Nodes[g_core.nodes.count - 1].Width + g_core.nodes.node_gap + exptend;
//  // 计算移动的增量
//  Delta := NewFormWidth - Width;
//
//  if node_at_cursor <> nil then
//  begin
//      // 调整 rate 的值以控制缓动效果的强度
//    rate := 0.03;  // 值越小，缓动越慢
//
//    // 使用指数函数计算 ExpDelta
//    ExpDelta := Delta * (1 - Exp(-rate));
//
//    // 调整窗口的大小和位置
//    SetBounds(Left - Round(ExpDelta) div 2, Top, Width + Round(ExpDelta), Height);
//
//    for j := 0 to g_core.nodes.count - 1 do
//    begin
//      var inner_node := g_core.nodes.Nodes[j];
//      if j = 0 then
//        inner_node.Left := g_core.nodes.node_gap + exptend
//      else
//        inner_node.Left := g_core.nodes.Nodes[j - 1].Left + g_core.nodes.Nodes[j - 1].Width + g_core.nodes.node_gap;
//    end;
//
//
//  end;
//end;

procedure TForm1.handle_animation_tick(Sender: TObject; lp: TPoint);
var
  NewFormWidth: Integer;
  j: Integer;
  Delta: Integer;
  ExpDelta: Double;
  rate: Double;
begin
  NewFormWidth := g_core.nodes.Nodes[g_core.nodes.count - 1].Left + g_core.nodes.Nodes[g_core.nodes.count - 1].Width + g_core.nodes.node_gap + exptend;
  // 计算移动的增量
  Delta := NewFormWidth - Width;

  if node_at_cursor <> nil then
  begin
    rate := 1;

    ExpDelta := Delta * rate;

    SetBounds(Left - Round(ExpDelta) div 2, Top, Width + Round(ExpDelta), Height);

    for j := 0 to g_core.nodes.count - 1 do
    begin
      var inner_node := g_core.nodes.Nodes[j];
      if j = 0 then
        inner_node.Left := g_core.nodes.node_gap + exptend
      else
        inner_node.Left := g_core.nodes.Nodes[j - 1].Left + g_core.nodes.Nodes[j - 1].Width + g_core.nodes.node_gap;
    end;
  end;
end;

procedure TForm1.AdjustNodeSize(Node: t_node; Rate: Double);
var
  NewWidth, NewHeight: Integer;
  SmoothRate: Double;
begin
  if Node = nil then
    exit;

  // 使用指数函数计算平滑的 Rate
//  SmoothRate := 1 - Exp(-1.6* Rate);
  SmoothRate := 1 - Power(2, -10 * Rate);
  NewWidth := Round(Node.Original_Size.cx * (1 + SmoothRate));
  NewHeight := Round(Node.Original_Size.cy * (1 + SmoothRate));

  Node.center_point.x := Node.Left + Node.Width div 2;
  Node.center_point.y := Node.Top + Node.Height div 2;

  // 设置当前节点的新尺寸和位置，保持中心点不变
  Node.SetBounds(Node.center_point.x - NewWidth div 2, Node.center_point.y - NewHeight div 2, NewWidth, NewHeight);
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
    if hoverLabel <> nil then
    begin
      hoverLabel.Left := Node.Left + (Node.Width div 2) - (hoverLabel.Width div 2);
      hoverLabel.Top := Node.Top - hoverLabel.Height - 5;
    end;

    GetCursorPos(lp);

//    node_at_cursor := get_node_at_point(lp);
    node_at_cursor := t_node(Sender);



//    另一种处理方式

        // 调整当前节点
    Current_node := node_at_cursor;
    FCurrentNode := node_at_cursor;
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

//    AdjustNodeSize(Current_node, Rate11);


  // 其他种类处理法师

    for I := 0 to g_core.nodes.count - 1 do
    begin
      Current_node := g_core.nodes.Nodes[I];
//           if Node= Current_node then
//             Continue;


      a := Current_node.Left - ScreenToClient(lp).X + Current_node.Width div 2;
      b := Current_node.Top - ScreenToClient(lp).Y + Current_node.Height div 4;

      rate := g_core.utils.rate(a, b);
      rate := Min(Max(rate, 0.5), 1);
          if Node= Current_node then
                  rate:=rate-0.1;

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

    handle_animation_tick(Self, lp);

  end;
end;

procedure TForm1.FormCreate(Sender: TObject);
begin

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

procedure TForm1.FormDestroy(Sender: TObject);
var
  v: TSettingItem;
  SettingsObj: TJSONObject;
begin
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
  FreeDictionary();

  cs.Free;
  KillTimer(Handle, 10);
  action_terminate(self);
  main_background.Free;

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

procedure TForm1.FormPaint(Sender: TObject);
var
  g: TGPGraphics;
  font: TGPFont;
begin
  if Assigned(hoverLabel) then
  begin

    g := TGPGraphics.Create(Canvas.Handle);
    try
      var sbRed := TGPSolidBrush.Create(aclWhite);
      var sbBlack := TGPSolidBrush.Create(aclBlack);
      font := TGPFont.Create('微软雅黑', 16, FontStyleRegular);
      try
        g.DrawString(gdraw_text, -1, font, MakePoint(hoverLabel.Left - 1, hoverLabel.top + 0.0), sbBlack);
        g.DrawString(gdraw_text, -1, font, MakePoint(hoverLabel.Left + 1, hoverLabel.top + 0.0), sbBlack);
        g.DrawString(gdraw_text, -1, font, MakePoint(hoverLabel.Left, hoverLabel.top + 0.0 - 1), sbBlack);
        g.DrawString(gdraw_text, -1, font, MakePoint(hoverLabel.Left, hoverLabel.top + 0.0 + 1), sbBlack);

        g.DrawString(gdraw_text, -1, font, MakePoint(hoverLabel.Left, hoverLabel.top + 0.0), sbRed);
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

  // 根据滚轮方向调整节点大小
  if WheelMsg.WheelDelta > 0 then
  begin

    var i1 := g_core.json.Config.nodesize;
    i1 := round(1.1 * i1);
    g_core.nodes.node_size := i1;
    set_nodesize_value(g_core.json, i1);
  end
  else
  begin
    var i1 := g_core.json.Config.nodesize;
    i1 := round(i1 * 0.9);
    g_core.nodes.node_size := i1;
    set_nodesize_value(g_core.json, i1);
  end;

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

procedure TForm1.action_translator(Sender: TObject);
begin
  g_core.utils.launch_app(g_core.json.Config.translator);
end;

procedure TForm1.action_config(Sender: TObject);
var
  vobj: TObject;
begin

  vobj := g_core.find_object_by_name('cfgForm');
  g_core.nodes.is_configuring := true;
  SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  TCfgForm(vobj).ShowModal;

end;

procedure TForm1.action_set_acce(Sender: TObject);
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

      cs.Enter;

      set_json_value('config', 'shortcut', FileName);

      cs.Leave;
    end;
  end;
  OpenDlg.Free;

end;

procedure TForm1.action_hide_desk(Sender: TObject);
begin
  if TMenuItem(Sender).Checked then
  begin
    TMenuItem(Sender).Checked := false;
    ShowDesktopIcons();
  end
  else
  begin
    TMenuItem(Sender).Checked := true;
    HideDesktopIcons()
  end;

end;

procedure TForm1.FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  if Key = VK_ESCAPE then
    Close;
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

procedure TForm1.node_click(Sender: TObject);
begin
  if t_node(Sender).file_path = '' then
    Exit;
  if t_node(Sender).tool_tip = '开始菜单' then
  begin
    SimulateCtrlEsc();
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

procedure TForm1.action_terminate(Sender: TObject);
begin

  set_json_value('config', 'left', left.ToString);
  set_json_value('config', 'top', top.ToString);
  Application.Terminate;
end;

end.

