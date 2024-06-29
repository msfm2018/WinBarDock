﻿unit ApplicationMain;

interface

uses
  Windows, Messages, SysUtils, Variants, Classes, Graphics, Controls, Forms,
  core, Dialogs, ExtCtrls, Generics.Collections, Vcl.Imaging.pngimage, TlHelp32,
  System.IOUtils, Winapi.ShellAPI, inifiles, Vcl.Imaging.jpeg, u_debug, ComObj,
  PsAPI, Winapi.GDIPAPI, Winapi.GDIPOBJ, System.SyncObjs, System.Hash,
  System.Math, System.JSON, u_json, ConfigurationForm, Vcl.Menus, Winapi.ActiveX,
  InfoBarForm, System.Generics.Collections, event, Vcl.StdCtrls,
  Vcl.VirtualImage;

type
  TForm1 = class(TForm)
    Timer1: TTimer;

    procedure FormMouseDown(Sender: TObject; Button: TMouseButton; Shift: TShiftState; X, Y: Integer);
    procedure FormShow(Sender: TObject);
    procedure FormDestroy(Sender: TObject);
    procedure action_config(Sender: TObject);
    procedure action_terminate(Sender: TObject);
    procedure action_set_acce(Sender: TObject);
    procedure action_bootom_panel(Sender: TObject);
    procedure action_translator(Sender: TObject);
    procedure FormKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure Timer1Timer(Sender: TObject);
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
    into_snap_windows: Boolean;
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
    procedure handle_animation_tick(Sender: TObject; lp: TPoint);
    function get_node_at_point(ScreenPoint: TPoint): t_node;
    procedure form_mouse_wheel(WheelMsg: TWMMouseWheel);
    procedure CleanupPopupMenu;

    procedure action_hide_task(Sender: TObject);
    procedure FreeDictionary;
    procedure action_hide_desk(Sender: TObject);

  end;

  TMyThread = class(TThread)
  private
    FOnUpdateUI: TThreadProcedure;
  protected
    procedure Execute; override;
    procedure UpdateUI;
  public
    constructor Create(OnUpdateUI: TThreadProcedure);
  end;

var
  Form1: TForm1;
  tmp_json: TDictionary<string, TSettingItem>;
  cs: TCriticalSection;

implementation

{$R *.dfm}

procedure sort_layout(hwnd: hwnd; uMsg, idEvent: UINT; dwTime: DWORD); stdcall;
begin
  Form1.snap_top_windows();
end;



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

    Form1.height := g_core.nodes.node_size + g_core.nodes.node_size div 2 + 100;

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

        original_width := g_core.nodes.Nodes[I].Width;
        original_height := g_core.nodes.Nodes[I].height;
        center_x := g_core.nodes.Nodes[I].Left + g_core.nodes.Nodes[I].Width div 2;
        center_y := g_core.nodes.Nodes[I].top + g_core.nodes.Nodes[I].height div 2;

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
  lp: tpoint;
begin

  if g_core.nodes.is_configuring then
    exit;

  GetCursorPos(lp);
  if not PtInRect(self.BoundsRect, lp) and not into_snap_windows then
  begin
    into_snap_windows := true;

    CalculateAndPositionNodes();

    Left := Screen.Width div 2 - Width div 2;

    if top < top_snap_distance then
    begin
      top := -(height - visible_height) - 5;
      Left := Screen.Width div 2 - Width div 2;
      restore_state();
    end;
    into_snap_windows := false;

  end
  else if top < top_snap_distance then
    top := 0;
end;

procedure TForm1.Timer1Timer(Sender: TObject);
var
  differences: TStringList;
  i: Integer;
  pIco: TIcon;
  bmpIco: TBitmap;
  IconIndex: Word;
  png: TPNGImage;
  SettingItem: TSettingItem;
  tmp_key: string;
  SettingsObj: TJSONObject;
  bcontinue: boolean;
begin
  Timer1.Enabled := False;
  TMyThread.Create(
    procedure
    begin
      Timer1.Interval := 2000;
      Timer1.Enabled := True;
    end);

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
  menuItemClickHandlers: array[0..6] of t_menu_click_handler;
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
  g_core.utils.init_background(main_background, self);

  cs := TCriticalSection.Create;
  into_snap_windows := false;

  form1.left := g_core.json.Config.Left;
  Form1.top := g_core.json.Config.Top;

  SetWindowLong(Handle, GWL_EXSTYLE, GetWindowLong(Handle, GWL_EXSTYLE) and (not WS_EX_APPWINDOW));
  SetWindowPos(Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  ShowWindow(Application.Handle, SW_HIDE);

  if pm = nil then
    pm := TPopupMenu.Create(self);
  menuItemClickHandlers[0] := action_translator;
  menuItemClickHandlers[1] := action_bootom_panel;
  menuItemClickHandlers[2] := action_config;
  menuItemClickHandlers[3] := action_set_acce;
  menuItemClickHandlers[4] := action_terminate;
  menuItemClickHandlers[5] := action_hide_task;
  menuItemClickHandlers[6] := action_hide_desk;
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


// 布局逻辑

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

end;

procedure TForm1.node_mouse_leave(Sender: TObject);
begin
  hoverLabel.Visible := false;
  if hoverLabel <> nil then
    FreeAndNil(hoverLabel)
end;

procedure TForm1.wndproc(var Msg: tmessage);
begin
  inherited;
  case Msg.Msg of
    WM_MOUSEWHEEL:
      form_mouse_wheel(TWMMouseWheel(Msg));
  end;
end;

procedure TForm1.FormShow(Sender: TObject);
begin

  Initialize_form();

  ConfigureLayout();
  SetTimer(Handle, 10, 10, @sort_layout);

//  action_bootom_panel(Self);

  add_json('startx', 'Start Button.png', 'startx', '开始菜单', True, nil);
  add_json('recycle', 'recycle.png', 'recycle', '回收站', True, nil);

  if bottomForm = nil then
    bottomForm := TbottomForm.Create(self);

  bottomForm.show;
  bottomForm.top := 0;
  bottomForm.Left := (Screen.WorkAreaWidth - bottomForm.Width) div 2;

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


// 移动窗口逻辑

procedure TForm1.node_mouse_move(Sender: TObject; Shift: TShiftState; X, Y: Integer);
var
  rate: double;
  a, b: integer;
  I: Integer;
  NewWidth, NewHeight: Integer;
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

    node_at_cursor := get_node_at_point(lp);

    for I := 0 to g_core.nodes.count - 1 do
    begin
      Current_node := g_core.nodes.Nodes[I];

      a := Current_node.Left - ScreenToClient(lp).X + Current_node.Width div 2;
      b := Current_node.Top - ScreenToClient(lp).Y + Current_node.Height div 4;

      rate := g_core.utils.rate(a, b);
      rate := Min(Max(rate, 0.5), 1);

      NewWidth := Round(Current_node.original_width * 2 * rate);
      NewHeight := Round(Current_node.original_height * 2 * rate);

      var maxValue: Integer := 128;

      NewWidth := Min(NewWidth, maxValue);
      NewHeight := Min(NewHeight, maxValue);

      Current_node.center_x := Current_node.Left + Current_node.Width div 2;
      Current_node.center_y := Current_node.Top + Current_node.Height div 2;

      Current_node.SetBounds(Current_node.center_x - NewWidth div 2, Current_node.center_y - NewHeight div 2, NewWidth, NewHeight);

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
  Timer1.Enabled := false;
  vobj := g_core.find_object_by_name('cfgForm');
  g_core.nodes.is_configuring := true;
  SetWindowPos(TCfgForm(vobj).Handle, HWND_TOPMOST, 0, 0, 0, 0, SWP_NOMOVE or SWP_NOSIZE);
  TCfgForm(vobj).ShowModal;

  Timer1.Enabled := true;
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

procedure TForm1.action_bootom_panel(Sender: TObject);
begin
//  if bottomForm = nil then
//    bottomForm := TbottomForm.Create(self);
//
//  bottomForm.show;
//  bottomForm.top := 0;
//  bottomForm.Left := (Screen.WorkAreaWidth - bottomForm.Width) div 2;


  if TMenuItem(Sender).Checked then
  begin
    TMenuItem(Sender).Checked := false;
    if bottomForm = nil then
      bottomForm := TbottomForm.Create(self);

    bottomForm.Visible := true;
    bottomForm.top := 0;
    bottomForm.Left := (Screen.WorkAreaWidth - bottomForm.Width) div 2;
  end
  else
  begin
    TMenuItem(Sender).Checked := true;
    if bottomForm = nil then
      bottomForm := TbottomForm.Create(self);

    bottomForm.Visible := false;
    bottomForm.top := 0;
    bottomForm.Left := (Screen.WorkAreaWidth - bottomForm.Width) div 2;
  end;

  restore_state();
end;

procedure TForm1.action_hide_task(Sender: TObject);
begin
  if TMenuItem(Sender).Checked then
  begin
    TMenuItem(Sender).Checked := false;
    g_core.utils.SetTaskbarAutoHide(false);
  end
  else
  begin
    TMenuItem(Sender).Checked := true;
    g_core.utils.SetTaskbarAutoHide(true);
  end;

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
    g_core.utils.launch_app(t_node(Sender).file_path)  else
    g_core.utils.launch_app(t_node(Sender).file_path);

  EventDef.isLeftClick := False;

end;

procedure TForm1.action_terminate(Sender: TObject);
begin

  set_json_value('config', 'left', left.ToString);
  set_json_value('config', 'top', top.ToString);
  Application.Terminate;
end;

{ TMyThread }

constructor TMyThread.Create(OnUpdateUI: TThreadProcedure);
begin
  inherited Create(True); // Create suspended
  FreeOnTerminate := True;
  FOnUpdateUI := OnUpdateUI;
  Resume; // Start the thread
end;

procedure TMyThread.Execute;
var
  differences: TStringList;
  i: Integer;
  pIco: TIcon;
  bmpIco: TBitmap;
  IconIndex: Word;
  png: TPNGImage;
  SettingItem: TSettingItem;
  tmp_key: string;
  SettingsObj: TJSONObject;
  bcontinue: Boolean;
begin
  bcontinue := False;
  try
    differences := TStringList.Create;
    try
      // This method should not directly interact with the UI
      GetRunningApplications(differences);

      cs.Enter;
      try
        tmp_json.Clear;
        for i := 0 to differences.Count - 1 do
        begin
          var arr := differences[i].Split([',']);
          IconIndex := 0;

          if g_core.json.Config.debug = 'true' then
            Debug.Show(ExtractFileName(arr[0]) + '----' + arr[1]);

          if exclusion_app.Contains(ExtractFileName(arr[0])) then
            Continue;

          for var Key in g_core.json.Settings.Keys do
          begin
            var Value := g_core.json.Settings.Items[Key];
            if Value.Is_path_valid and (Value.FilePath = arr[0]) then
            begin
              bcontinue := True;
              Break;
            end;
          end;

          if bcontinue then
          begin
            bcontinue := False;
            Continue;
          end;

          tmp_key := THashMD5.GetHashString(ExtractFileName(arr[0]));

          if tmp_json.ContainsKey(tmp_key) then
            Continue;

          var up := ChangeFileExt(ExtractFileName(arr[0]), '').ToUpper;
          var img_path := get_json_value('icons', up);

          if img_path = '' then
          begin
            pIco := TIcon.Create;
            try
              pIco.Handle := ExtractAssociatedIcon(Application.Handle, PChar(arr[0]), IconIndex);
              if pIco.Handle > 0 then
              begin
                bmpIco := TBitmap.Create;
                try
                  bmpIco.PixelFormat := pf32bit;
                  bmpIco.Height := pIco.Height;
                  bmpIco.Width := pIco.Width;
                  bmpIco.Canvas.Draw(0, 0, pIco);

                  SettingItem.memory_image := TMemoryStream.Create;
                  try
                    png := BmpToPngObj(bmpIco);
                    png.SaveToStream(SettingItem.memory_image);

                    SettingItem.Is_path_valid := False;
                    SettingItem.FilePath := arr[0];
                    SettingItem.tool_tip := arr[1];

                    tmp_json.AddOrSetValue(tmp_key, SettingItem);
                  except
                    SettingItem.memory_image.Free;
                    raise; // Re-raise the exception after cleaning up
                  end;
                finally
                  bmpIco.Free;
                  png.Free;
                end;
              end;
            finally
              pIco.Free;
            end;
          end
          else
          begin
            SettingItem.memory_image := TMemoryStream.Create;
            SettingItem.memory_image.LoadFromFile(app_path + 'img\tmp\' + img_path);
            SettingItem.Is_path_valid := False;
            SettingItem.FilePath := arr[0];
            SettingItem.tool_tip := arr[1];

            tmp_json.AddOrSetValue(tmp_key, SettingItem);
          end;
        end;

        UpdateCoreSettingsFromTmpJson(tmp_json, g_core.json.Settings, cs);
      finally
        cs.Leave;
      end;
    finally
      differences.Free;
    end;
  except
    // Handle exceptions here if needed
  end;

  // Update the UI, if necessary
  Synchronize(UpdateUI);
end;

procedure TMyThread.UpdateUI;
begin
  if Assigned(FOnUpdateUI) then
    FOnUpdateUI();
end;

end.

