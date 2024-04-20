unit core;

interface

uses
  shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils, UrlMon,
  Tlhelp32, messages, core_db, Registry, aclapi, AccCtrl, forms, vcl.controls,
  shlobj, ComObj, activex, System.Generics.Collections, System.Hash,
  ConfigurationForm, InfoBarForm, vcl.ExtCtrls, math;

type
  TNode = class(TImage)
  public
    node_path: string;
    node_left: Integer; // 每个节点靠左位置
    original_width, original_height: Integer;
    center_x, center_y: Integer;
  end;

  TNodes = record
    size: Integer;
    nodes_array: array of TNode;
    Is_cfging: Boolean;

    node_size: Integer;
    node_gap: Integer;
  end;

  TUtils = record
    FileMap: TDictionary<string, string>;
    short_key: string;

  public
    procedure UpdateDB;
    procedure LaunchApplication(const Path: string);
    function CalculateZoomFactor(const W: Double): Double;
    procedure AutoRun;
    function CalculateFormHeight(NodeSize, WindowHeight: Integer): Integer;
  end;

  TCoreClass = class
  public
    dbmgr: TGDB;
    utils: TUtils;
    nodes: TNodes;
  private
    map: TDictionary<string, TObject>;
  public
    function FindObjectByName(const Name_: string): TObject;
  end;

type
  TMenuClickHandler = procedure(Sender: TObject) of object;

const
  menu_name: array[0..4] of string = ('翻译', '应用', '设置', '热键', '退出');
  visible_height: Integer = 19;       // 代表可见高度
  top_snap_distance: Integer = 40;   // 吸附距离

var
  g_core: TCoreClass;

implementation

procedure TUtils.UpdateDB;
var
  Hash: string;
  Key, Value: string;
begin
  g_core.dbmgr.itemdb.Clean;
  g_core.dbmgr.itemdb.Clean(False);

  for Key in FileMap.Keys do
  begin
    Value := FileMap[Key];
    Hash := THashMD5.GetHashString(Key);

    g_core.dbmgr.itemdb.SetVarValue(Hash, Key);
    g_core.dbmgr.itemdb.SetVarValue(Hash, Value, False);
  end;
end;

procedure TUtils.AutoRun;
begin
  try
    var Reg := TRegistry.Create;
    try
      Reg.RootKey := HKEY_CURRENT_USER;
      if Reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', True) then
        Reg.WriteString('xtool', ExpandFileName(ParamStr(0)));
    finally
      Reg.Free;
    end;
  except
    // Handle exception if registry access fails
  end;
end;

function TUtils.CalculateFormHeight(NodeSize, WindowHeight: Integer): Integer;
begin
  Result := NodeSize + NodeSize div 2 + 20;
end;

function TUtils.CalculateZoomFactor(const W: Double): Double;
begin
  Result := (101.82 * 5 * W) / g_core.nodes.node_size;
end;

procedure TUtils.LaunchApplication(const Path: string);
begin
  if Path.Trim = '' then
    Exit;

  if Path.Contains('https') or Path.Contains('http') or Path.Contains('.html') or Path.Contains('.htm') then
    ShellExecute(Application.Handle, nil, PChar(Path), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(Path), nil, nil, SW_SHOW);
end;

function TCoreClass.FindObjectByName(const Name_: string): TObject;
begin
  if map.TryGetValue(Name_, Result) then
    Exit(Result)
  else
    Result := nil;
end;

initialization
  g_core := TCoreClass.Create;
     try
         g_core.nodes.node_size := g_core.dbmgr.cfgDb.GetInteger('ih');
     except
          g_core.nodes.node_size := 64;
     end;

  g_core.nodes.node_gap := Round(g_core.nodes.node_size / 4); // 4 根据 rate 最多增加宽度的一半

  g_core.dbmgr.cfgDb := TCfgDB.Create;
  g_core.dbmgr.itemdb := TItemsDb.Create;
  g_core.dbmgr.desktopdb := TdesktopDb.Create;
  g_core.utils.FileMap := TDictionary<string, string>.Create;

  g_core.map := TDictionary<string, TObject>.Create;
  g_core.map.AddOrSetValue('cfgForm', TCfgForm.Create(nil));
  g_core.map.AddOrSetValue('bottomForm', TbottomForm.Create(nil));

  g_core.utils.AutoRun;


finalization
  g_core.map.Free;
  g_core.utils.FileMap.Free;
  g_core.Free;

end.

