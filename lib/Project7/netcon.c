#include <Windows.h>
#include <stdio.h>

#include <netlistmgr.h>
#pragma comment(lib, "Ole32.lib")


//该部分代码检查计算机是否连接到互联网，如果没有连接到互联网（isConnected == VARIANT_FALSE），但仍然连接到局域网或子网（通过 GetConnectivity 获取的连接状态），则将 connectedStatus 设置为 2，表示计算机连接到本地网络或子网，但没有连接到互联网。
//
//这个标志的设置可能用于后续的处理，表示网络连接处于“非互联网状态”（例如，仅仅是局域网或子网）。

__declspec(dllexport) int IsConnectedToInternet()
{
	int connectedStatus = 0;
	HRESULT hr = S_FALSE;

	hr = CoInitialize(NULL);
	if (SUCCEEDED(hr))
	{
		INetworkListManager* pNetworkListManager;
		hr = CoCreateInstance(&CLSID_NetworkListManager, NULL, CLSCTX_ALL, &IID_INetworkListManager, (void**)&pNetworkListManager);
		if (SUCCEEDED(hr))
		{
			NLM_CONNECTIVITY nlmConnectivity = NLM_CONNECTIVITY_DISCONNECTED;
			VARIANT_BOOL isConnected = VARIANT_FALSE;
			hr = pNetworkListManager->lpVtbl->get_IsConnectedToInternet(pNetworkListManager, &isConnected);
			if (SUCCEEDED(hr))
			{
				if (isConnected == VARIANT_TRUE)
					connectedStatus = 1;
				else
					connectedStatus = 0;
			}
			if (isConnected == VARIANT_FALSE && SUCCEEDED(pNetworkListManager->lpVtbl->GetConnectivity(pNetworkListManager, &nlmConnectivity)))
			{
				if (nlmConnectivity & (NLM_CONNECTIVITY_IPV4_LOCALNETWORK | NLM_CONNECTIVITY_IPV4_SUBNET | NLM_CONNECTIVITY_IPV6_LOCALNETWORK | NLM_CONNECTIVITY_IPV6_SUBNET))
				{
					connectedStatus = 2;
				}
			}
			pNetworkListManager->lpVtbl->Release(pNetworkListManager);
		}
		CoUninitialize();
	}
	return connectedStatus;
}


#define STATUS_SUCCESS (0x00000000)
typedef NTSTATUS(WINAPI* VnRtlGetVersionPtr)(PRTL_OSVERSIONINFOW);
inline BOOL VnGetOSVersion(PRTL_OSVERSIONINFOW lpRovi)
{
	HMODULE hMod = GetModuleHandleW(L"ntdll.dll");
	if (hMod != NULL)
	{
		VnRtlGetVersionPtr fxPtr = (VnRtlGetVersionPtr)GetProcAddress(
			hMod,
			"RtlGetVersion"
		);
		if (fxPtr != NULL)
		{
			lpRovi->dwOSVersionInfoSize = sizeof(RTL_OSVERSIONINFOW);
			if (STATUS_SUCCESS == fxPtr(lpRovi))
			{
				return TRUE;
			}
		}
	}
	return FALSE;
}

#define _LIBVALINET_HOOKING_OSVERSION_INVALID 0xffffffff
inline DWORD32 VnGetOSVersionAndUBR(PRTL_OSVERSIONINFOW lpRovi)
{
	if (!VnGetOSVersion(lpRovi))
	{
		return _LIBVALINET_HOOKING_OSVERSION_INVALID;
	}
	return 0;
}

RTL_OSVERSIONINFOW global_rovi;
__declspec(dllexport) inline BOOL IsWindows11()
{
	if (!global_rovi.dwMajorVersion)  VnGetOSVersionAndUBR(&global_rovi);
	if (global_rovi.dwBuildNumber >= 21996) return TRUE;
	return FALSE;
}