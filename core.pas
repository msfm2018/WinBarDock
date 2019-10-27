unit core;

interface

uses shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils,
  UrlMon, Tlhelp32, messages, CoreDB, Registry, aclapi,
  AccCtrl, forms,
  vcl.controls, shlobj, ComObj, activex, u_debug, WindowsSysVersion,
  System.Generics.Collections;

type

  TGblVar = record
    db: tgdb;
  end;

var
  g_core: TGblVar;

implementation

// { thumbnailT }
// function IsWOW64: BOOL;
// begin
// result := FALSE;
// if GetProcAddress(GetModuleHandle(kernel32), 'IsWow64Process') <> nil then
// IsWow64Process(GetCurrentProcess, result);
// end;

procedure SetAutoRun(ok: Boolean);
var
  reg: TRegistry; // 首先定义一个TRegistry类型的变量Reg
begin
  reg := TRegistry.create;
  try // 创建一个新键
    reg.RootKey := HKEY_CURRENT_USER; // 将根键设置为HKEY_LOCAL_MACHINE

    if reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', true) then
      reg.WriteString('xtool', ExpandFileName(paramstr(0)));

    reg.CloseKey; // 关闭键
  finally
    reg.Free;
  end;
end;

initialization

SetAutoRun(true);

finalization

end.
