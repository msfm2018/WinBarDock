unit core;

interface

uses
  shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils, UrlMon,
  Tlhelp32, messages, core_db, Registry, aclapi, AccCtrl, forms, vcl.controls,
  shlobj, ComObj, activex, System.Generics.Collections, System.Hash, u_debug,
  ConfigurationForm, InfoBarForm, vcl.ExtCtrls, math;

type

  // 叶节点
  TNode = class(timage)
  public
    nodePath: string;
    nodeLeft: integer; // 每个节点靠左位置
  end;

  TNodes = record
    Count: integer;
    NodesArray: array of TNode;
    IsConfiguring: Boolean;

    NodeSize: integer;

  const
    MarginTop = 10;
    VisibleHeight: integer = 9; // 代表可见高度
    TopSnapDistance: integer = 40; // 吸附距离

    NodeGap = 30; // 间隔
  end;

  TUtils = record
    FileMap: TDictionary<string, string>;
    ShortcutKey: string;
  private

  public
    procedure LaunchApplication(path: string);
    // 比例因子
    procedure SetAutoRun(ok: Boolean);

    function CalculateFormHeight(NodeSize, windowHeight: integer): integer;
  end;

  TGblVar = class
  public
    DatabaseManager: tgdb;
    utils: TUtils;
    NodeInformation: TNodes;
  private
    FormObjectDictionary: TDictionary<string, tobject>;
  public
    function FindObjectByName(name_: string): tobject;
  end;

var
  g_core: TGblVar;

implementation

procedure TUtils.SetAutoRun(ok: Boolean);
var
  reg: TRegistry;
begin
  reg := TRegistry.create;
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
  Result := math.Ceil(g_core.NodeInformation.NodeSize * NodeSize / 138) +
    g_core.DatabaseManager.cfgDb.GetInteger('ih');

end;

procedure TUtils.LaunchApplication(path: string);
begin
  if path.trim = '' then
    exit;
  if path.Contains('https') or path.Contains('http') or path.Contains('.html')
    or path.Contains('.htm') then
    winapi.shellapi.ShellExecute(application.Handle, nil, PChar(path), nil, nil,
      SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(path), nil, nil, SW_SHOW);
end;

{ TGblVar }

function TGblVar.FindObjectByName(name_: string): tobject;
var
  vobj: tobject;
begin
  if g_core.FormObjectDictionary.TryGetValue(name_, vobj) then
    Result := vobj
  else
    Result := nil;
end;

initialization

g_core := TGblVar.create;
g_core.NodeInformation.NodeSize := 72;

if g_core.DatabaseManager.cfgDb = nil then
  g_core.DatabaseManager.cfgDb := TCfgDB.create;

if g_core.DatabaseManager.itemdb = nil then
  g_core.DatabaseManager.itemdb := TItemsDb.create;

g_core.DatabaseManager.desktopdb := TdesktopDb.create;

g_core.utils.FileMap := TDictionary<string, string>.create;

// 初始化数据

g_core.NodeInformation.NodeSize :=
  g_core.DatabaseManager.cfgDb.GetInteger('ih');

g_core.FormObjectDictionary := TDictionary<string, tobject>.create;
g_core.FormObjectDictionary.AddOrSetValue('cfgForm', TCfgForm.create(nil));
g_core.FormObjectDictionary.AddOrSetValue('bottomForm',
  TbottomForm.create(nil));

g_core.utils.SetAutoRun(true);

finalization

for var MyElem in g_core.FormObjectDictionary.Values do
  FreeAndNil(MyElem);
g_core.FormObjectDictionary.Free;

g_core.utils.FileMap.Free;

g_core.Free;

end.
