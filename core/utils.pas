unit utils;

interface

function SystemShutdown(reboot: Boolean): boolean; stdcall; external './dll/Project7.dll';

function OpenStartOnMonitor(): boolean; stdcall; external './dll/Project7.dll';

implementation

end.

