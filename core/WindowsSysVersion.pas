unit WindowsSysVersion;

interface

uses
  windows  ;
{$IFDEF CONDITIONALEXPRESSIONS}
{$IF Defined(TOSVersionInfoEx)}
{$DEFINE TOSVERSIONINFOEX_DEFINED}
{$IFEND}
{$ENDIF}
{$IFNDEF TOSVERSIONINFOEX_DEFINED}
type
  POSVersionInfoEx = ^TOSVersionInfoEx;

  TOSVersionInfoEx = packed record
    dwOSVersionInfoSize: DWORD;
    dwMajorVersion: DWORD;
    dwMinorVersion: DWORD;
    dwBuildNumber: DWORD;
    dwPlatformId: DWORD;
    //szCSDVersion: array[0..127] of AnsiChar;   //delphi7
    szCSDVersion: array[0..127] of WideChar;    //delphi2010
    wServicePackMajor: Word;
    wServicePackMinor: Word;
    wSuiteMask: Word;
    wProductType: Byte;
    wReserved: Byte;
  end;
type
  TWinVer = (WinNone, Win95, Win98, WinMe, Win2000, WinServer2000, WinXp, WinXp64, WinServer2003,
  WinHomeServer, WinServer2003R2, WinVista, WinServer2008, WinServer2008R2, Win7,Win8,WinServer2012);

const
  VER_SERVER_NT = $80000000;
{$EXTERNALSYM VER_SERVER_NT}
  VER_WORKSTATION_NT = $40000000;
{$EXTERNALSYM VER_WORKSTATION_NT}
  VER_SUITE_SMALLBUSINESS = $00000001;
{$EXTERNALSYM VER_SUITE_SMALLBUSINESS}
  VER_SUITE_ENTERPRISE = $00000002;
{$EXTERNALSYM VER_SUITE_ENTERPRISE}
  VER_SUITE_BACKOFFICE = $00000004;
{$EXTERNALSYM VER_SUITE_BACKOFFICE}
  VER_SUITE_COMMUNICATIONS = $00000008;
{$EXTERNALSYM VER_SUITE_COMMUNICATIONS}
  VER_SUITE_TERMINAL = $00000010;
{$EXTERNALSYM VER_SUITE_TERMINAL}
  VER_SUITE_SMALLBUSINESS_RESTRICTED = $00000020;
{$EXTERNALSYM VER_SUITE_SMALLBUSINESS_RESTRICTED}
  VER_SUITE_EMBEDDEDNT = $00000040;
{$EXTERNALSYM VER_SUITE_EMBEDDEDNT}
  VER_SUITE_DATACENTER = $00000080;
{$EXTERNALSYM VER_SUITE_DATACENTER}
  VER_SUITE_SINGLEUSERTS = $00000100;
{$EXTERNALSYM VER_SUITE_SINGLEUSERTS}
  VER_SUITE_PERSONAL = $00000200;
{$EXTERNALSYM VER_SUITE_PERSONAL}
  VER_SUITE_BLADE = $00000400;
{$EXTERNALSYM VER_SUITE_BLADE}
  VER_SUITE_EMBEDDED_RESTRICTED = $00000800;
{$EXTERNALSYM VER_SUITE_EMBEDDED_RESTRICTED}
  VER_SUITE_SECURITY_APPLIANCE = $00001000;
{$EXTERNALSYM VER_SUITE_SECURITY_APPLIANCE}
  VER_SUITE_WH_SERVER = $00008000;
{$EXTERNALSYM VER_SUITE_WH_SERVER}
  PROCESSOR_ARCHITECTURE_AMD64 = 9;
{$EXTERNALSYM PROCESSOR_ARCHITECTURE_AMD64}
  SM_SERVERR2 = 89;
{$EXTERNALSYM SM_SERVERR2}
const
  VER_NT_WORKSTATION = $0000001;
{$EXTERNALSYM VER_NT_WORKSTATION}
  VER_NT_DOMAIN_CONTROLLER = $0000002;
{$EXTERNALSYM VER_NT_DOMAIN_CONTROLLER}
  VER_NT_SERVER = $0000003;
{$EXTERNALSYM VER_NT_SERVER}

{$ENDIF} // TOSVERSIONINFOEX_DEFINED

//取操作系统信息填充到结构
function GetOSVersionInfo(var Info: TOSVersionInfoEx): Boolean;
//windows系统类型 0表示取不到 1表示非服务器 2表示服务器
function GetWindowsSystemType: integer;
//取windows系统版本信息，主函数
function GetWindowsSystemVersion: Twinver;

implementation

{
                                     OSVersionInfoEx.wProductType 类型说明

代码                                                    值                             说明
---------------------------------------------------------------------------------------------------------------------------------------
VER_NT_DOMAIN_CONTROLLER     0x0000002               装的是个域服务器系统（win2000server,2003server,2008server）
VER_NT_SERVER                            0x0000003                装的是服务器系统（win2000server,2003server,2008server）
VER_NT_WORKSTATION                 0x0000001               非服务器版本（Vista, XP Professional, XP Home Edition, 2000）
}
//取操作系统类型 0未取到或出错 1表示非服务器  2表示服务器

function GetWindowsSystemType: integer;
var
  info: TOSVersionInfoEx;
begin
  result := 0;
  if (GetOSVersionInfo(info) = false) then exit;
  case info.wProductType of
    VER_NT_WORKSTATION:
      begin
        Result := 1; //非服务器
      end;
    VER_NT_SERVER:
      begin
        Result := 2; //服务器版
      end;
    VER_NT_DOMAIN_CONTROLLER:
      begin
        Result := 2; //域服务器
      end;
  end;
end;


//系统                                              版本号                   其它条件
//-------------------------------------------------------------------------------------------------------
//windows 8                                  6 2     OSVERSIONINFOEX.wProductType = VER_NT_WORKSTATION
//Windows 7                          6 1    OSVERSIONINFOEX.wProductType == VER_NT_WORKSTATION
//Windows Server 2008 R2            6 1                 OSVERSIONINFOEX.wProductType != VER_NT_WORKSTATION
//Windows Server 2008                 6 0                   OSVERSIONINFOEX.wProductType != VER_NT_WORKSTATION
//Windows Vista                            6 0                        OSVERSIONINFOEX.wProductType == VER_NT_WORKSTATION
//Windows Server 2003 R2            5 2                   GetSystemMetrics(SM_SERVERR2) != 0
//Windows Home Server                5 2                   OSVERSIONINFOEX.wSuiteMask == VER_SUITE_WH_SERVER
//Windows Server 2003                 5 2                   GetSystemMetrics(SM_SERVERR2) == 0
//Windows XP x64 Edition              5 2                   (OSVERSIONINFOEX.wProductType == VER_NT_WORKSTATION) && (SYSTEM_INFO.wProcessorArchitecture==PROCESSOR_ARCHITECTURE_AMD64)
//Windows XP                                5 1
//Windows 2000                            5 0
//Windows Me                                4.9
//Windows 98                                4.1
//Windows 95                                4.0
//取windows系统版本信息

function GetWindowsSystemVersion: Twinver;
var
  info: TOSVersionInfoEx;
  sysInfo: Tsysteminfo;
begin
  Result := WinNone;
  windows.GetSystemInfo(sysInfo); //系统信息
  try
    if (GetOSVersionInfo(info) = false) then exit;
    case info.dwMajorVersion of //主版本
      4:
        begin
          case info.dwMinorVersion of //次版本
            0: Result := Win95;
            1: Result := Win98;
            9: Result := WinMe;
          end;
        end;
      5: begin
          case info.dwMinorVersion of
            0:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := Win2000 else Result := WinServer2000;
              end;
            1: Result := WinXp;
            2:
              begin
                if ((info.wProductType = VER_NT_WORKSTATION) and (sysinfo.wProcessorArchitecture = PROCESSOR_ARCHITECTURE_AMD64)) then //PROCESSOR_ARCHITECTURE_AMD64
                  Result := WinXp64;
                  //SM_SERVERR2
                if GetSystemMetrics(SM_SERVERR2) = 0 then
                  Result := WinServer2003
                else
                  Result := WinServer2003R2;
                if info.wSuiteMask = VER_SUITE_WH_SERVER then
                  Result := WinHomeServer;
              end;
          end;
        end;
      6: begin
          case info.dwMinorVersion of
            0:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := WinVista else Result := WinServer2008;
              end;
            1:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := Win7 else Result := WinServer2008R2;
              end;
            2:
              begin
                if info.wProductType = VER_NT_WORKSTATION then
                  Result := Win8 else Result := WinServer2012;
              end;
          end;
        end;
    end;
  except
    exit;
  end;
end;

function GetOSVersionInfo(var Info: TOSVersionInfoEx): Boolean;
begin
  FillChar(Info, SizeOf(TOSVersionInfoEx), 0);
  Info.dwOSVersionInfoSize := SizeOf(TOSVersionInfoEx);
  Result := GetVersionEx(TOSVersionInfo(Addr(Info)^));
  if (not Result) then
    Info.dwOSVersionInfoSize := 0;
end;
end.

