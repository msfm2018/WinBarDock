unit core;

interface

uses
  shellapi, classes, winapi.windows, Graphics, SysUtils, messages,
  Vcl.Imaging.pngimage, System.IniFiles, Registry, forms, GDIPAPI, GDIPOBJ,
  Dwmapi, u_json, vcl.controls, ComObj, System.Generics.Collections, utils,
  ConfigurationForm, TlHelp32, Winapi.PsAPI, System.SyncObjs, vcl.ExtCtrls, math;

  const
  WM_MY_CUSTOM_MESSAGE = WM_USER + 1;
   WM_LBUTTON_MESSAGE = WM_USER + 1030;
type
  t_node = class(TImage)
  public
    key: string;
    id: Integer;
    tool_tip: string;
    file_path: string;

    original_size: TSize;
    center_point: TPoint;
  end;

  t_node_container = record
    count: Integer;
    Nodes: array of t_node;
    is_configuring: Boolean;
    node_size: Integer;
    node_gap: Integer;
  end;

  t_utils = record
  public
    procedure round_rect(w, h: Integer; hdl: thandle);

    procedure SetTaskbarAutoHide(autoHide: Boolean);

    procedure CopyFileToFolder(const SourceFile, DestinationFolder: string);

  public
    procedure launch_app(const Path: string);

    procedure auto_run;
    procedure init_background(img: TImage; obj: tform; src: string);
    function rate(a, b: double): Double;

  end;

  t_core_class = class
  public
    json: TMySettings;
    utils: t_utils;
    nodes: t_node_container;
  private
    object_map: TDictionary<string, TObject>;
  public
    function find_object_by_name(const Name_: string): TObject;
  end;

type
  TFormPosition = (fpTop, fpBottom); // 定义枚举类型，包含顶部和底部

  TFormPositions = set of TFormPosition; // 定义一个集合类型，表示可以包含顶部、底部或二者

type
  MSLLHOOKSTRUCT = record
    pt: TPoint;  // 鼠标位置
    mouseData: DWORD;  // 鼠标按钮状态等
    flags: DWORD;  // 标志
    time: DWORD;  // 事件时间
    dwExtraInfo: ULONG_PTR;  // 附加信息
  end;

  PMSLLHOOKSTRUCT = ^MSLLHOOKSTRUCT;  // 指向 MSLLHOOKSTRUCT 的指针

const
  visible_height = 19;       // 代表可见高度
  top_snap_distance = 40;   // 吸附距离
  exptend = 60;

procedure GetRunningApplications(AppList: TStringList);

function BringWindowToFront(const WindowTitle: string): boolean;

procedure BmpToPng(const Bmp: TBitmap; PngFileName: string);

function BmpToPngObj(const Bmp: TBitmap): TPNGImage;

function GetFontHeight(hdc: HDC): Integer;

procedure remove_json(Key: string);

procedure add_json(Key, image_file_name, FilePath, tool_tip: string; Is_path_valid: boolean; memory: TMemoryStream);

procedure SimulateCtrlEsc;

procedure EmptyRecycleBin;

procedure UpdateCoreSettingsFromTmpJson(const tmp_json: TDictionary<string, TSettingItem>; var core_settings: TDictionary<string, TSettingItem>; cs: TCriticalSection);

procedure SetWindowCornerPreference(hWnd: hWnd);

var
  g_core: t_core_class;
  original_task_list: TStringList;
  task_list: TStringList;
  app_path: string;

implementation

const
  SPI_SETDESKWALLPAPER = $0014;
  SPI_GETDESKWALLPAPER = $0073;
  SPI_GETDESKPATTERN = $0020;
  SPI_SETDESKPATTERN = $0015;
  SPI_SETWORKAREA = $002F;
  SPI_GETWORKAREA = $0030;

procedure UpdateCoreSettingsFromTmpJson(const tmp_json: TDictionary<string, TSettingItem>; var core_settings: TDictionary<string, TSettingItem>; cs: TCriticalSection);
var
  tmp_key: string;
  settingItem: TSettingItem;
  existingItem: TSettingItem;
  v: TSettingItem;
begin
  cs.Enter;
  try
    for tmp_key in core_settings.Keys do
    begin
      if core_settings.TryGetValue(tmp_key, v) then
        if not v.Is_path_valid then
        begin
          if not tmp_json.TryGetValue(tmp_key, settingItem) then
            core_settings.Remove(tmp_key);
        end;

    end;

    for tmp_key in tmp_json.Keys do
    begin
      settingItem := tmp_json[tmp_key];
      if not settingItem.Is_path_valid then
      begin
        if core_settings.TryGetValue(tmp_key, existingItem) then
        begin
//          // Update existing entry in core_settings
//          existingItem.memory_image := settingItem.memory_image;
//          existingItem.Is_path_valid := false;
//          existingItem.Path := settingItem.Path;
//          existingItem.Content := settingItem.Content;
        end
        else
        begin
          core_settings.Add(tmp_key, settingItem);
        end;
      end;
    end;
  finally
    cs.Leave;
  end;
end;

procedure SetWindowCornerPreference(hWnd: hWnd);
var
  cornerPreference: Integer;
begin
  cornerPreference := DWMWCP_ROUND;  // 设置为圆角

  // 调用 DwmSetWindowAttribute API 设置窗口的角落偏好
  if DwmSetWindowAttribute(hWnd, DWMWA_WINDOW_CORNER_PREFERENCE, @cornerPreference, SizeOf(cornerPreference)) <> S_OK then
  begin

  end;
end;

//清空回收站
procedure EmptyRecycleBin;
begin

  SHEmptyRecycleBin(0, nil, SHERB_NOCONFIRMATION or SHERB_NOPROGRESSUI or SHERB_NOSOUND);
end;

procedure SimulateCtrlEsc;
begin
  OpenStartOnMonitor();

end;

procedure t_utils.CopyFileToFolder(const SourceFile, DestinationFolder: string);
var
  DestinationFile: string;
begin
  DestinationFile := IncludeTrailingPathDelimiter(DestinationFolder) + ExtractFileName(SourceFile);

  if SourceFile <> DestinationFile then
  begin
    if not CopyFile(PChar(SourceFile), PChar(DestinationFile), False) then
    begin
      RaiseLastOSError;  // 抛出最后一个操作系统错误
    end;
  end;
end;

function GetFontHeight(hdc: hdc): Integer;
var
  tm: TTextMetric;
begin
  GetTextMetrics(hdc, tm);
  Result := tm.tmHeight;
end;

procedure BmpToPng(const Bmp: TBitmap; PngFileName: string);
var
  Png: TPNGImage;
  x, y: Integer;
  TransparentColor: TColor;
begin

  try
    Png := TPNGImage.Create;
    try
      Png.Assign(Bmp);
      Png.CreateAlpha;

      TransparentColor := Bmp.Canvas.Pixels[0, 0];

      for y := 0 to Bmp.Height - 1 do
      begin
        for x := 0 to Bmp.Width - 1 do
        begin
          if Bmp.Canvas.Pixels[x, y] = TransparentColor then
            Png.AlphaScanline[y][x] := 0  // 透明
          else
            Png.AlphaScanline[y][x] := 255;  // 不透明
        end;
      end;

      Png.SaveToFile(PngFileName);
    finally
      Png.Free;
    end;
  except

  end;
end;

function BmpToPngObj1(const Bmp: TBitmap): TPNGImage;
var
  Png: TPNGImage;
  x, y: Integer;
  TransparentColor: TColor;
begin

  try
    Png := TPNGImage.Create;
    try
      Png.Assign(Bmp);
      Png.CreateAlpha;

      TransparentColor := Bmp.Canvas.Pixels[0, 0];

      for y := 0 to Bmp.Height - 1 do
      begin
        for x := 0 to Bmp.Width - 1 do
        begin
          if Bmp.Canvas.Pixels[x, y] = TransparentColor then
            Png.AlphaScanline[y][x] := 0  // 透明
          else
            Png.AlphaScanline[y][x] := 255;  // 不透明
        end;
      end;

//      Png.SaveToFile(PngFileName);
    finally
//      Png.Free;
      result := Png;
    end;
  except

  end;
end;

function BmpToPngObj(const Bmp: TBitmap): TPNGImage;
var
  GdiBitmap: TGPBitmap;
  GdiGraphics: TGPGraphics;
  TransparentColor: TColor;
  x, y: Integer;
  MemoryStream: TMemoryStream;
  BmpStream: TStreamAdapter;
  PixelColor: TColor;
  Alpha: Byte;
  SurroundColorCount: Integer;
  R, G, B: Integer;
  NeighborX, NeighborY: Integer;
  NeighborColor: TColor;
//  png:TPNGImage;
begin
  // 禁用范围检查
  {$R-}
//   Png := TPNGImage.Create;
  // 创建 GDI+ Bitmap 对象
  MemoryStream := TMemoryStream.Create;
  try
    Bmp.SaveToStream(MemoryStream);
    MemoryStream.Position := 0;
    BmpStream := TStreamAdapter.Create(MemoryStream, soReference);
    GdiBitmap := TGPBitmap.Create(BmpStream, False);

    try
      // 创建 GDI+ Graphics 对象
      GdiGraphics := TGPGraphics.Create(GdiBitmap);
      try
        // 设置抗锯齿和插值模式
        GdiGraphics.SetSmoothingMode(SmoothingModeHighQuality);
        GdiGraphics.SetInterpolationMode(InterpolationModeHighQualityBicubic);

        // 获取透明色
        TransparentColor := Bmp.Canvas.Pixels[0, 0];

        // 创建新的 PNG 图像
        Result := TPNGImage.Create;
        Result.Assign(Bmp);
        Result.CreateAlpha;

        // 遍历位图的每个像素
        for y := 0 to Bmp.Height - 1 do
        begin
          for x := 0 to Bmp.Width - 1 do
          begin
            PixelColor := Bmp.Canvas.Pixels[x, y];
            if PixelColor = TransparentColor then
            begin
              Alpha := 0;
            end
            else
            begin
              // 检查周围像素的颜色
              R := 0;
              G := 0;
              B := 0;
              SurroundColorCount := 0;

              for NeighborY := Max(0, y - 1) to Min(Bmp.Height - 1, y + 1) do
              begin
                for NeighborX := Max(0, x - 1) to Min(Bmp.Width - 1, x + 1) do
                begin
                  if (NeighborX <> x) or (NeighborY <> y) then
                  begin
                    NeighborColor := Bmp.Canvas.Pixels[NeighborX, NeighborY];
                    if NeighborColor <> TransparentColor then
                    begin
                      R := R + Integer(GetRValue(NeighborColor));
                      G := G + Integer(GetGValue(NeighborColor));
                      B := B + Integer(GetBValue(NeighborColor));
                      Inc(SurroundColorCount);
                    end;
                  end;
                end;
              end;

              if SurroundColorCount > 0 then
              begin
                R := R div SurroundColorCount;
                G := G div SurroundColorCount;
                B := B div SurroundColorCount;
                PixelColor := RGB(R, G, B);
              end;

              Alpha := 255; // 默认不透明
            end;
            Result.AlphaScanline[y][x] := Alpha;
            Result.Pixels[x, y] := PixelColor;
          end;
        end;

      finally
//      result:=Png;
        GdiGraphics.Free;
      end;

    finally
      GdiBitmap.Free;
    end;

  finally
    MemoryStream.Free;
    // 恢复范围检查
    {$R+}
  end;
end;

function GetProcessIcon(PID: DWORD; ab: Boolean): TIcon;
var
  hProcess: THandle;
  hIcon1: HICON;
  hSnapshot: THandle;
  me32: MODULEENTRY32;
begin
  Result := TIcon.Create;
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPMODULE, PID);
  if hSnapshot = INVALID_HANDLE_VALUE then
    Exit;

  try
    me32.dwSize := SizeOf(MODULEENTRY32);
    if Module32First(hSnapshot, me32) then
    begin
      hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, PID);
      if hProcess = 0 then
        Exit;

      try
        hIcon1 := ExtractIcon(hInstance, (me32.szExePath), 0);
        if ab then
          original_task_list.Add(me32.szExePath)
        else
          task_list.Add(me32.szExePath);

        if hIcon1 > 1 then
        begin
          Result.Handle := hIcon1;
        end;
      finally
        CloseHandle(hProcess);
      end;
    end;
  finally
    CloseHandle(hSnapshot);
  end;
end;

procedure ListProcessIcons(f: Boolean);
var
  hSnapshot: THandle;
  pe32: PROCESSENTRY32;
  Icon: TIcon;
begin
  hSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
  if hSnapshot = INVALID_HANDLE_VALUE then
    Exit;
  task_list.Clear;
  try
    pe32.dwSize := SizeOf(PROCESSENTRY32);
    if Process32First(hSnapshot, pe32) then
    begin
      repeat
        Icon := GetProcessIcon(pe32.th32ProcessID, f);
        try
          if not Icon.Empty then
          begin

          end;
        finally
          Icon.Free;
        end;
      until not Process32Next(hSnapshot, pe32);
    end;
  finally
    CloseHandle(hSnapshot);
  end;
end;

function IsMainWindowVisible(hWnd: hWnd): Boolean;
begin
  Result := IsWindowVisible(hWnd) and (GetWindowTextLength(hWnd) > 0);
end;

function GetProcessFileName(ProcessID: DWORD): string;
var
  hProcess: THandle;
  FileName: array[0..MAX_PATH] of Char;
begin
  Result := '';
  hProcess := OpenProcess(PROCESS_QUERY_INFORMATION or PROCESS_VM_READ, False, ProcessID);
  if hProcess <> 0 then
  try
    if GetModuleFileNameEx(hProcess, 0, FileName, MAX_PATH) > 0 then
      Result := FileName;
  finally
    CloseHandle(hProcess);
  end;
end;

function EnumWindowsProc(hWnd: hWnd; lParam: lParam): BOOL; stdcall;
var
  ProcessID: DWORD;
  ProcessName: string;
  WindowText: array[0..255] of Char;
  UniqueProcesses: TStringList;
begin
  ZeroMemory(@WindowText, SizeOf(WindowText));
  Result := True;
  if IsMainWindowVisible(hWnd) then
  begin
    GetWindowThreadProcessId(hWnd, ProcessID);
    ProcessName := GetProcessFileName(ProcessID);

    UniqueProcesses := TStringList(lParam);
    if UniqueProcesses.IndexOf(ExtractFileName(ProcessName)) = -1 then
    begin
      GetWindowText(hWnd, WindowText, 255);
      UniqueProcesses.Add(Format('%s,%s', [ProcessName, WindowText]));
    end;
  end;
end;

procedure GetRunningApplications(AppList: TStringList);
begin
  AppList.Clear;
  EnumWindows(@EnumWindowsProc, lParam(AppList));
end;

function BringWindowToFront(const WindowTitle: string): boolean;
var
  hWnd: thandle;
begin
  result := false;
  hWnd := FindWindow(nil, PChar(WindowTitle));

  if hWnd <> 0 then
  begin
    if IsIconic(hWnd) then
    begin
      ShowWindow(hWnd, SW_RESTORE);
    end;
    SetForegroundWindow(hWnd);
    Result := True;
  end;
end;

procedure t_utils.auto_run;
begin
  try
    var Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', True) then
        Reg.WriteString('winbaros', ExpandFileName(ParamStr(0)));
    finally
      Reg.Free;
    end;
  except

  end;
end;

procedure t_utils.SetTaskbarAutoHide(autoHide: Boolean);
var
  taskbar: hWnd;
  abd: APPBARDATA;
begin
  taskbar := FindWindow('Shell_TrayWnd', nil);
  if taskbar <> 0 then
  begin
    abd.cbSize := SizeOf(APPBARDATA);
//    abd.hWnd := taskbar;
    if autoHide then
      abd.lParam := ABS_AUTOHIDE
    else
      abd.lParam := ABS_ALWAYSONTOP;

    SHAppBarMessage(ABM_SETSTATE, abd);
  end;
end;

procedure t_utils.init_background(img: TImage; obj: tform; src: string);
begin
  img.Parent := obj;
  img.Align := alClient;
  img.Transparent := true;
  img.Stretch := true;
//  img.Anchors:=[akleft,akright];

  img.Picture.LoadFromFile(ExtractFilePath(ParamStr(0)) + 'img\' + src);
end;

procedure t_utils.round_rect(w, h: Integer; hdl: thandle);
var
  Rgn: HRGN;
begin
  Rgn := CreateRoundRectRgn(0, 0, w, h, 8, 8);
  SetWindowRgn(hdl, Rgn, true);
end;

procedure t_utils.launch_app(const Path: string);
begin
  if Path.Trim = '' then
    Exit;

  if Path.Contains('https') or Path.Contains('http') or Path.Contains('.html') or Path.Contains('.htm') then
    ShellExecute(Application.Handle, nil, PChar(Path), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(Path), nil, nil, SW_SHOW);
end;

function t_utils.rate(a, b: double): Double;
begin
  result := Exp(-sqrt(a * a + b * b) / (63.82 * 5));
end;

function t_core_class.find_object_by_name(const Name_: string): TObject;
begin
  if object_map.TryGetValue(Name_, Result) then
    Exit(Result)
  else
    Result := nil;
end;
       // 添加数据的过程

procedure add_json(Key, image_file_name, FilePath, tool_tip: string; Is_path_valid: boolean; memory: TMemoryStream);
var
  SettingItem: TSettingItem;
begin
  SettingItem.image_file_name := image_file_name;
  SettingItem.FilePath := FilePath;
  SettingItem.tool_tip := tool_tip;
  SettingItem.Is_path_valid := Is_path_valid;
  SettingItem.memory_image := memory;

  g_core.json.Settings.AddOrSetValue(Key, SettingItem);
end;

procedure remove_json(Key: string);
var
  SettingItem: TSettingItem;
begin
  if g_core.json.Settings.ContainsKey(Key) then
  begin
    SettingItem := g_core.json.Settings[Key];
    if not SettingItem.Is_path_valid then
    begin
      if Assigned(SettingItem.memory_image) then
      begin
        SettingItem.memory_image.Free;
        SettingItem.memory_image := nil;
      end;
    end;
    g_core.json.Settings.Remove(Key);
  end;

end;
 //function TForm1.get_node_at_point(ScreenPoint: TPoint): t_node;
//var
//  ClientPoint: TPoint;
//  I: Integer;
//  Node: t_node;
//begin
//  Result := nil;
//
//  ClientPoint := ScreenToClient(ScreenPoint);
//
//  for I := 0 to g_core.nodes.count - 1 do
//  begin
//    Node := g_core.nodes.Nodes[I];
//
//    if PtInRect(Node.BoundsRect, ClientPoint) then
//    begin
//      Result := Node;
//      Exit;
//    end;
//  end;
//end;

initialization
  g_core := t_core_class.Create;
  app_path := ExtractFilePath(ParamStr(0));
  g_jsonobj := load_json_from_file(app_path + 'cfg.json');

  parse_json(g_jsonobj, g_core.json);

  g_core.object_map := TDictionary<string, TObject>.Create;
  g_core.object_map.AddOrSetValue('cfgForm', TCfgForm.Create(nil));

  g_core.utils.auto_run;
  original_task_list := TStringList.Create;
  task_list := TStringList.Create;

  try
    g_core.nodes.node_size := g_core.json.Config.nodesize;
  except
    g_core.nodes.node_size := 64;
  end;
  g_core.nodes.node_gap := Round(g_core.nodes.node_size / 40);


finalization
  g_core.object_map.Free;

  g_core.Free;
  original_task_list.free;
  task_list.free;

  g_jsonobj.Free;
  g_core.json.Settings.Free;

end.

