#include <windows.h>
#include <objbase.h>
#include<ShObjIdl.h>

#include <initguid.h>
#include <Windows.h>
#include <windowsx.h>
#include <Shlwapi.h>
#pragma comment(lib, "Shlwapi.lib")
#include <TlHelp32.h>
#include <Psapi.h>
#pragma comment(lib, "Psapi.lib")
#include <roapi.h>
#include <winstring.h>
#pragma comment(lib, "ntdll.lib")

// GUID 定义
DEFINE_GUID(IID_IServiceProvider, 0x6d5140c1, 0x7436, 0x11ce, 0x80, 0x34, 0x00, 0xaa, 0x00, 0x60, 0x09, 0xfa);


DEFINE_GUID(CLSID_ImmersiveShell, 0xc2f03a33, 0x21f5, 0x47fa, 0xb4, 0xbb, 0x15, 0x63, 0x62, 0xa2, 0xf2, 0x39);


DEFINE_GUID(SID_IImmersiveMonitorService, 0x47094e3a, 0x0cf2, 0x430f, 0x80, 0x6f, 0xcf, 0x9e, 0x4f, 0x0f, 0x12, 0xdd);
DEFINE_GUID(IID_IImmersiveMonitorService, 0x4d4c1e64, 0xe410, 0x4faa, 0xba, 0xfa, 0x59, 0xca, 0x06, 0x9b, 0xfe, 0xc2);


typedef interface IImmersiveMonitorService IImmersiveMonitorService;
typedef struct IImmersiveMonitorServiceVtbl
{
    HRESULT(STDMETHODCALLTYPE* QueryInterface)(IImmersiveMonitorService* This, REFIID riid, void** ppvObject);
    ULONG(STDMETHODCALLTYPE* AddRef)(IImmersiveMonitorService* This);
    ULONG(STDMETHODCALLTYPE* Release)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* GetCount)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* GetConnectedCount)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* GetAt)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* GetFromHandle)(IImmersiveMonitorService* This, HMONITOR hMonitor, _COM_Outptr_ IUnknown** ppvObject);
    HRESULT(STDMETHODCALLTYPE* GetFromIdentity)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* GetImmersiveProxyMonitor)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* QueryService)(IImmersiveMonitorService* This, HMONITOR hMonitor, GUID*, GUID*, void** ppvObject);
    HRESULT(STDMETHODCALLTYPE* QueryServiceByIdentity)(IImmersiveMonitorService* This);
    HRESULT(STDMETHODCALLTYPE* QueryServiceFromWindow)(IImmersiveMonitorService* This, HWND hWnd, GUID* a3, GUID* a4, void** ppvObject);
    HRESULT(STDMETHODCALLTYPE* QueryServiceFromPoint)(IImmersiveMonitorService* This, POINT pt, GUID* a3, GUID* a4, void** ppvObject);
} IImmersiveMonitorServiceVtbl;

interface IImmersiveMonitorService
{
    CONST_VTBL struct IImmersiveMonitorServiceVtbl* lpVtbl;
};

DEFINE_GUID(SID_ImmersiveLauncher, 0x6f86e01c, 0xc649, 0x4d61, 0xbe, 0x23, 0xf1, 0x32, 0x2d, 0xde, 0xca, 0x9d);
DEFINE_GUID(IID_IImmersiveLauncher10RS, 0xd8d60399, 0xa0f1, 0xf987, 0x55, 0x51, 0x32, 0x1f, 0xd1, 0xb4, 0x98, 0x64);
typedef interface IImmersiveLauncher10RS IImmersiveLauncher10RS;


typedef struct IImmersiveLauncher10RSVtbl
{
    BEGIN_INTERFACE

        HRESULT(STDMETHODCALLTYPE* QueryInterface)(IImmersiveLauncher10RS* This, REFIID riid, void** ppvObject);
    ULONG(STDMETHODCALLTYPE* AddRef)(IImmersiveLauncher10RS* This);
    ULONG(STDMETHODCALLTYPE* Release)(IImmersiveLauncher10RS* This);
    HRESULT(STDMETHODCALLTYPE* ShowStartView)(IImmersiveLauncher10RS* This, int method, int flags);
    HRESULT(STDMETHODCALLTYPE* Dismiss)(IImmersiveLauncher10RS* This);
    HRESULT(STDMETHODCALLTYPE* method5)(IImmersiveLauncher10RS* This);
    HRESULT(STDMETHODCALLTYPE* method6)(IImmersiveLauncher10RS* This);
    HRESULT(STDMETHODCALLTYPE* IsVisible)(IImmersiveLauncher10RS* This, BOOL* ret);
    HRESULT(STDMETHODCALLTYPE* method8)(IImmersiveLauncher10RS* This);
    HRESULT(STDMETHODCALLTYPE* method9)(IImmersiveLauncher10RS* This);
    HRESULT(STDMETHODCALLTYPE* ConnectToMonitor)(IImmersiveLauncher10RS* This, IUnknown* monitor);
    HRESULT(STDMETHODCALLTYPE* GetMonitor)(IImmersiveLauncher10RS* This, IUnknown** monitor);

    END_INTERFACE
} IImmersiveLauncher10RSVtbl;

interface IImmersiveLauncher10RS
{
    CONST_VTBL struct IImmersiveLauncher10RSVtbl* lpVtbl;
};


__declspec(dllexport) void OpenStartOnMonitor()
{
    HMONITOR monitor = MonitorFromWindow(NULL, MONITOR_DEFAULTTOPRIMARY);
    HRESULT hr = CoInitialize(NULL);


    IUnknown* pImmersiveShell = NULL;
    hr = CoCreateInstance(
        &CLSID_ImmersiveShell,
        NULL,
        CLSCTX_NO_CODE_DOWNLOAD | CLSCTX_LOCAL_SERVER,
        &IID_IServiceProvider,
        (void**)&pImmersiveShell
    );

    if (SUCCEEDED(hr))
    {
        IImmersiveMonitorService* pMonitorService = NULL;
        //hr = ((IServiceProvider*)pImmersiveShell)->QueryService(
        hr = IUnknown_QueryService(
            pImmersiveShell,
            &SID_IImmersiveMonitorService,
            &IID_IImmersiveMonitorService,
            (void**)&pMonitorService
        );
        if (pMonitorService) {
            // 执行其他操作
            IUnknown* pMonitor = NULL;
            pMonitorService->lpVtbl->GetFromHandle(
                pMonitorService,
                monitor,
                &pMonitor
            );


            IImmersiveLauncher10RS* pLauncher = NULL;

            IUnknown_QueryService(
                pImmersiveShell,
                &SID_ImmersiveLauncher,
                &IID_IImmersiveLauncher10RS,
                &pLauncher  // 正确
            );
            if (pLauncher)
            {
                BOOL bIsVisible = FALSE;
                pLauncher->lpVtbl->IsVisible(pLauncher, &bIsVisible);
                if (SUCCEEDED(hr))
                {
                    if (!bIsVisible)
                    {
                        if (pMonitor)
                        {
                            pLauncher->lpVtbl->ConnectToMonitor(pLauncher, pMonitor);
                        }
                        pLauncher->lpVtbl->ShowStartView(pLauncher, 11, 0);
                    }
                    else
                    {
                        pLauncher->lpVtbl->Dismiss(pLauncher);
                    }
                }
                pLauncher->lpVtbl->Release(pLauncher);
            }
        }
        // 释放 pImmersiveShell
        pImmersiveShell->lpVtbl->Release(pImmersiveShell);
    }

    CoUninitialize();
}

