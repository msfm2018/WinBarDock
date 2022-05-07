unit core;

interface

uses
  shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils, UrlMon,
  Tlhelp32, messages, CoreDB, Registry, aclapi, AccCtrl, forms, vcl.controls,
  shlobj, ComObj, activex, WindowsSysVersion, System.Generics.Collections,
  u_debug, cfgForm, bottomForm, Vcl.ExtCtrls;

type
  timage_ext = class(timage)
  public
    appPath: string;
  end;

  TMainWindow = record
    itemCount: integer;
    itemPosition: array of integer;
    items: array of timage_ext;
    a, b, rate: Real;
    app_cfging: Boolean;
    shortcut_key: string;
    const
      marginTop = 22;
      visHeight: Integer = 9; // 露头高度
      top_snap_gap: Integer = 40; // 吸附距离

      itemWidth = 64;
      itemHeight = 64;
      itemGap = 30;      //间隔
      zoom_factor = 101.82 * 5; // sqrt(img_width*img_width+ img_height*img_height)=101.8...
  end;

  TUtils = class
    class procedure to_launcher(n: string); static;

  end;

  TGblVar = class
  public
    db: tgdb;
    formObject: TDictionary<string, TObject>;
    utils: TUtils;
    mainWindow: TMainWindow;
  end;

var
  g_core: TGblVar;

implementation

procedure SetAutoRun(ok: Boolean);
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




{ TUtils }

class procedure TUtils.to_launcher(n: string);
begin
  if n.trim = '' then
    exit;
  if n.Contains('https') or n.Contains('http') or n.Contains('.html') or n.Contains('.htm') then
    Winapi.ShellAPI.ShellExecute(application.Handle, nil, PChar(n), nil, nil, SW_SHOWNORMAL)
  else
    ShellExecute(0, 'open', PChar(n), nil, nil, SW_SHOW);
end;

initialization
  g_core := TGblVar.Create;
  if g_core.db.cfgDb = nil then
    g_core.db.cfgDb := TCfgDB.Create;

  if g_core.db.itemdb = nil then
    g_core.db.itemdb := TItemsDb.Create;

  g_core.formObject := TDictionary<string, TObject>.create;
  g_core.formObject.AddOrSetValue('cfgForm', Tmycfg.Create(nil));
  g_core.formObject.AddOrSetValue('bottomForm', TbottomFrm.Create(nil));

  SetAutoRun(true);


finalization
  for var MyElem in g_core.formObject.Values do
  begin
    FreeAndNil(MyElem)
  end;
  g_core.formObject.Free;

  g_core.Free;

end.

