unit core;

interface

uses shellapi, Wininet, classes, winapi.windows, Graphics, SysUtils,
  UrlMon, Tlhelp32, messages, CoreDB, Registry, aclapi,
  AccCtrl, forms,
  vcl.controls, shlobj, ComObj, activex,  WindowsSysVersion,
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
  reg: TRegistry; // ���ȶ���һ��TRegistry���͵ı���Reg
begin
  reg := TRegistry.create;
  try // ����һ���¼�
    reg.RootKey := HKEY_CURRENT_USER; // ����������ΪHKEY_LOCAL_MACHINE

    if reg.OpenKey('SOFTWARE\Microsoft\Windows\CurrentVersion\Run', true) then
      reg.WriteString('xtool', ExpandFileName(paramstr(0)));

    reg.CloseKey; // �رռ�
  finally
    reg.Free;
  end;
end;

initialization

SetAutoRun(true);

finalization

end.
