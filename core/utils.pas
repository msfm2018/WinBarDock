unit utils;

interface

const
  dllName = './Project7.dll';

function SystemShutdown(reboot: Boolean): boolean; stdcall; external dllName;

         //��ʼ��ť
function OpenStartOnMonitor(): boolean; stdcall; external dllName;

         //���ڹ���
function SetCBTHook(h: THandle): boolean; stdcall; external dllName;

function HideFromTaskbarAndAltTab(hwnd: thandle): boolean; stdcall; external dllName;

     //����Բ��png
procedure write_png_with_text(const filename: pansichar;const text:pansichar); stdcall; external dllName;

//procedure write_png_with_text(const filename: pansichar;const text:PWideChar); stdcall; external dllName;
//            void write_png_with_text(const char* filename, const wchar_t* text)
implementation

end.

