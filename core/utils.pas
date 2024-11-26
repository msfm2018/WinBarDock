unit utils;

interface

function SystemShutdown(reboot: Boolean): boolean; stdcall; external './dll/Project7.dll';

function OpenStartOnMonitor(): boolean; stdcall; external './dll/Project7.dll';

function SetCBTHook(h: THandle): boolean; stdcall; external './dll/Project7.dll';


procedure SetHook(h: THandle)     ; stdcall; external './dll/Project7.dll';
implementation

end.

