unit TaskbarList;

interface

uses
  Windows;

//type
//  ITaskbarList = interface(IUnknown)
//    ['{56FDF345-FD6D-11D0-9D12-00A0C91D4D9F}']
//    procedure HrInit; stdcall;
//    procedure AddTab(hwnd: HWND); stdcall;
//    procedure DeleteTab(hwnd: HWND); stdcall;
//    procedure ActivateTab(hwnd: HWND); stdcall;
//    procedure SetActiveAlt(hwnd: HWND); stdcall;
//  end;
//
//function CreateTaskbarList(out pTaskbarList: ITaskbarList): HRESULT; stdcall; external './dll/Project7.dll';
//
//procedure ReleaseTaskbarList(pTaskbarList: ITaskbarList); stdcall; external './dll/Project7.dll';

function HideFromTaskbarAndAltTab(hwnd: thandle): boolean; stdcall; external './dll/Project7.dll';

implementation

end.

