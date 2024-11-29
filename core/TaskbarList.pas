unit TaskbarList;

interface

uses
  Windows;

function HideFromTaskbarAndAltTab(hwnd: thandle): boolean; stdcall; external './Project7.dll';

implementation

end.

