unit utils;

interface

const
  dllName = './Project7.dll';
  mousehook = './Project3.dll';
  injectName = './global-inject.dll';

function SystemShutdown(reboot: Boolean): boolean; stdcall; external dllName;

         //开始按钮
function OpenStartOnMonitor(): boolean; stdcall; external dllName;

         //窗口钩子
function SetCBTHook(h: THandle): boolean; stdcall; external dllName;

function HideFromTaskbarAndAltTab(hwnd: thandle): boolean; stdcall; external dllName;

     //生成圆形png
procedure write_png_with_text(const filename: pansichar; const text: pansichar;cmode:integer); stdcall; external dllName;



  //    server for system time
function dllmaincpp(): Integer; stdcall; external injectName;

function HandleNewProcessesExport(): Integer; stdcall; external injectName;

procedure InstallMouseHook(); stdcall; external mousehook;

procedure UninstallMouseHook(); stdcall; external mousehook;

implementation

end.

