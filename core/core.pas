unit core;

interface

uses
  shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils, UrlMon,
  Tlhelp32, messages, core_db, Registry, aclapi, AccCtrl, forms, vcl.controls,
  shlobj, ComObj, activex, System.Generics.Collections, System.Hash,
  ConfigurationForm, InfoBarForm, vcl.ExtCtrls, math;

type

  // 叶节点
  TNode = class(timage)
  public
    nodePath: string;
    nodeLeft: integer; // 每个节点靠左位置
    OriginalWidth, OriginalHeight: integer;
    CenterX, CenterY: integer;
  end;

  TNodes = record
    Count: integer;
    NodesArray: array of TNode;
    IsConfiguring: Boolean;

    NodeSize: integer;
    NodeGap: integer;

  const
    VisibleHeight: integer = 9; // 代表可见高度
    TopSnapDistance: integer = 40; // 吸附距离
    // NodeGap = 30; // 间隔

  end;

  TUtils = record
    FileMap: TDictionary<string, string>;
    ShortcutKey: string;

  public
    procedure update_db;
    procedure LaunchApplication(path: string);
    // 比例因子
    function CalculateZoomFactor(w: double): double;
    procedure SetAutoRun(ok: Boolean);

    function CalculateFormHeight(NodeSize, windowHeight: integer): integer;
  end;

  TGblVar = class
  public
    DatabaseManager: tgdb;
    utils: TUtils;
    NodeInformation: TNodes;
  private
    ObjectMap: TDictionary<string, tobject>;
  public
    function FindObjectByName(name_: string): tobject;
  end;
 type
  TMenuItemClickHandler = procedure(Sender: TObject) of object;
  const   menuItemCaptions: array[0..4] of string = ('翻译', '应用', '设置', '热键', '退出');
var
  g_core: TGblVar;

implementation

procedure TUtils.update_db;
var
  hash: string;
  v: string;
begin
  g_core.DatabaseManager.itemdb.clean();
  g_core.DatabaseManager.itemdb.clean(false);

  for var key in fileMap.Keys do
  begin
    v := '';
    fileMap.TryGetValue(key, v);

    hash := THashMD5.GetHashString(key);
       //k v 存储在不同表中
    g_core.DatabaseManager.itemdb.SetVarValue(hash, key);
    g_core.DatabaseManager.itemdb.SetVarValue(hash, v, false);

  end;

end;

procedure TUtils.SetAutoRun(ok: Boolean);
begin
 var reg := TRegistry.create;
  try
    reg.RootKey := HKEY_CURRENT_USER;

    if reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', true) then
      reg.WriteString('xtool', ExpandFileName(paramstr(0)));

    reg.CloseKey;
  finally
    reg.Free;
  end;
end;

function TUtils.CalculateFormHeight(NodeSize, windowHeight: integer): integer;
begin
//  Result := math.Ceil(g_core.NodeInformation.NodeSize * NodeSize / 138) + g_core.DatabaseManager.cfgDb.GetInteger('ih');
      result:=NodeSize+NodeSize div 2 +20;
end;


function TUtils.CalculateZoomFactor(w: double): double;
begin
  // 计算比例因子
  Result := (101.82 * 5 * w) / g_core.NodeInformation.NodeSize;
end;

procedure TUtils.LaunchApplication(path: string);
begin
  if path.trim = '' then
    exit;
  if path.Contains('https') or path.Contains('http') or path.Contains('.html') or path.Contains('.htm') then
    winapi.shellapi.ShellExecute(application.Handle, nil, PChar(path), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(path), nil, nil, SW_SHOW);
end;

{ TGblVar }

function TGblVar.FindObjectByName(name_: string): tobject;
var
  vobj: tobject;
begin
  if g_core.ObjectMap.TryGetValue(name_, vobj) then
    Result := vobj
  else
    Result := nil;
end;

initialization

g_core := TGblVar.create;


g_core.NodeInformation.NodeSize := g_core.DatabaseManager.cfgDb.GetInteger('ih');
                     g_core.NodeInformation.NodeGap:=Round( g_core.NodeInformation.NodeSize div 4 ); //4根据 rate 最多增加宽度的一半
if g_core.DatabaseManager.cfgDb = nil then
  g_core.DatabaseManager.cfgDb := TCfgDB.create;

if g_core.DatabaseManager.itemdb = nil then
  g_core.DatabaseManager.itemdb := TItemsDb.create;

g_core.DatabaseManager.desktopdb := TdesktopDb.create;

g_core.utils.FileMap := TDictionary<string, string>.create;


g_core.ObjectMap := TDictionary<string, tobject>.create;
g_core.ObjectMap.AddOrSetValue('cfgForm', TCfgForm.create(nil));
g_core.ObjectMap.AddOrSetValue('bottomForm', TbottomForm.create(nil));

g_core.utils.SetAutoRun(true);

finalization

for var MyElem in g_core.ObjectMap.Values do
  FreeAndNil(MyElem);
g_core.ObjectMap.Free;

g_core.utils.FileMap.Free;

g_core.Free;

end.
