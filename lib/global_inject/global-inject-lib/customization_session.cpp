#include "stdafx.h"
#include "customization_session.h"
#include "session_private_namespace.h"
#include "logger.h"

extern HINSTANCE g_hDllInst;

namespace
{
	typedef int (WINAPI* MESSAGEBOXW)(HWND, LPCWSTR, LPCWSTR, UINT);

	MESSAGEBOXW pOriginalMessageBoxW;

	int WINAPI MessageBoxWHook(HWND hWnd, LPCWSTR lpText, LPCWSTR lpCaption, UINT uType)
	{
		static int counter = 0;
		counter++;

		WCHAR newText[1025];
		wsprintf(newText, L"Global injection and hooking demo!\n\n%s", lpText);

		WCHAR newTitle[1025];
		wsprintf(newTitle, L"[%d] %s", counter, lpCaption);

		return pOriginalMessageBoxW(hWnd, newText, newTitle, uType);
	}

	MH_STATUS InitCustomizationHooks()
	{
		MH_STATUS status = MH_CreateHook(MessageBoxW, (void*)MessageBoxWHook, (void**)&pOriginalMessageBoxW);
		if (status == MH_OK) {
			status = MH_QueueEnableHook(MessageBoxW);
		}

		return status;
	}
}

bool CustomizationSession::Start(bool runningFromAPC, HANDLE sessionManagerProcess, HANDLE sessionMutex) noexcept
{
	auto instance = new (std::nothrow) CustomizationSession();
	if (!instance) {
		LOG(L"Allocation of CustomizationSession failed");
		return false;
	}

	if (!instance->StartAllocated(runningFromAPC, sessionManagerProcess, sessionMutex)) {
		delete instance;
		return false;
	}

	// Instance will free itself.
	return true;
}

bool CustomizationSession::StartAllocated(bool runningFromAPC, HANDLE sessionManagerProcess, HANDLE sessionMutex) noexcept
{
	// Create the session semaphore. This will block the library if another instance
	// (from another session manager process) is already injected and its customization session is active.
	WCHAR szSemaphoreName[sizeof("CustomizationSessionSemaphore-pid=1234567890")];
	swprintf_s(szSemaphoreName, L"CustomizationSessionSemaphore-pid=%u", GetCurrentProcessId());

	HRESULT hr = m_sessionSemaphore.create(1, 1, szSemaphoreName);
	if (FAILED(hr)) {
		LOG(L"Semaphore creation failed with error %08X", hr);
		return false;
	}

	m_sessionSemaphoreLock = m_sessionSemaphore.acquire();

	if (WaitForSingleObject(sessionManagerProcess, 0) != WAIT_TIMEOUT) {
		VERBOSE(L"Session manager process is no longer running");
		return false;
	}

	if (!InitSession(runningFromAPC, sessionManagerProcess)) {
		return false;
	}

	if (runningFromAPC) {
		// Create a new thread for us to allow the program's main thread to run.
		try {
			// Note: Before creating the thread, the CRT/STL bumps the
			// reference count of the module, something a plain CreateThread
			// doesn't do.
			std::thread thread(&CustomizationSession::RunAndDeleteThis, this,
				sessionManagerProcess, sessionMutex);
			thread.detach();
		}
		catch (const std::exception& e) {
			LOG(L"%S", e.what());
			UninitSession();
			return false;
		}
	}
	else {
		// No need to create a new thread, a dedicated thread was created for us
		// before injection.
		RunAndDeleteThis(sessionManagerProcess, sessionMutex);
	}

	return true;
}

bool CustomizationSession::InitSession(bool runningFromAPC, HANDLE sessionManagerProcess) noexcept
{
	MH_STATUS status = MH_Initialize();
	if (status != MH_OK) {
		LOG(L"MH_Initialize failed with %d", status);
		return false;
	}

	if (runningFromAPC) {
		// No other threads should be running, skip thread freeze.
		MH_SetThreadFreezeMethod(MH_FREEZE_METHOD_NONE_UNSAFE);
	}
	else {
		MH_SetThreadFreezeMethod(MH_FREEZE_METHOD_FAST_UNDOCUMENTED);
	}

	try {
		m_newProcessInjector.emplace(sessionManagerProcess);
	}
	catch (const std::exception& e) {
		LOG(L"InitSession failed: %S", e.what());
		m_newProcessInjector.reset();
		MH_Uninitialize();
		return false;
	}

	status = InitCustomizationHooks();
	if (status != MH_OK) {
		LOG(L"InitCustomizationHooks failed with %d", status);
	}

	status = MH_ApplyQueued();
	if (status != MH_OK) {
		LOG(L"MH_ApplyQueued failed with %d", status);
	}

	if (runningFromAPC) {
		MH_SetThreadFreezeMethod(MH_FREEZE_METHOD_FAST_UNDOCUMENTED);
	}

	return true;
}

void CustomizationSession::RunAndDeleteThis(HANDLE sessionManagerProcess, HANDLE sessionMutex) noexcept
{
	m_sessionManagerProcess.reset(sessionManagerProcess);

	if (sessionMutex) {
		m_sessionMutex.reset(sessionMutex);
	}

	// Prevent the system from displaying the critical-error-handler message box.
	// A message box like this was appearing while trying to load a dll in a
	// process with the ProcessSignaturePolicy mitigation, and it looked like this:
	// https://stackoverflow.com/q/38367847
	DWORD dwOldMode;
	SetThreadErrorMode(SEM_FAILCRITICALERRORS, &dwOldMode);

	Run();

	SetThreadErrorMode(dwOldMode, nullptr);

	delete this;
}

void CustomizationSession::Run() noexcept
{
	DWORD waitResult = WaitForSingleObject(m_sessionManagerProcess.get(), INFINITE);
	if (waitResult != WAIT_OBJECT_0) {
		LOG(L"WaitForSingleObject returned %u, last error %u", waitResult, GetLastError());
	}

	VERBOSE(L"Uninitializing and freeing library");

	UninitSession();
}

void CustomizationSession::UninitSession() noexcept
{
	MH_STATUS status = MH_Uninitialize();
	if (status != MH_OK) {
		LOG(L"MH_Uninitialize failed with status %d", status);
	}

	m_newProcessInjector.reset();
}



//#include "stdafx.h"
//#include "customization_session.h"
//#include "session_private_namespace.h"
//#include "logger.h"
//#include "./log.cpp"
//#include <Windows.h>
//#include <roapi.h>
//#include <winstring.h>
//#include <winrt/Windows.UI.Xaml.h>
//#include <wchar.h> 
//using namespace winrt::Windows::UI::Xaml;
//
//extern HINSTANCE g_hDllInst;
//
//namespace
//{
//	using RoGetActivationFactory_t = decltype(&RoGetActivationFactory);
//	RoGetActivationFactory_t origRoGetActivationFactory;
//	static bool ignoreHooking = false;
//	// Hook for RoGetActivationFactory
//	HRESULT RoGetActivationFactoryHook(HSTRING activatableClassId, REFIID iid, void** factory)
//	{
//		//if (!ignoreHooking && _wcsicmp(WindowsGetStringRawBuffer(activatableClassId, NULL), L"Windows.UI.Xaml.Application") == 0)
//			if (!ignoreHooking && _wcsicmp(WindowsGetStringRawBuffer(activatableClassId, NULL), L"Windows.UI.Xaml.Controls.Button") == 0)
//			
//		{
//			ignoreHooking = true;
//			try
//			{
//				Application::Current().RequestedTheme(ApplicationTheme::Dark);
//			}
//			catch (...) {}
//			ignoreHooking = false;
//		}
//
//		return origRoGetActivationFactory(activatableClassId, iid, factory);
//	}
//
//
//	HWND g_hTrayInputIndicator;
//
//	using DeferWindowPos_t = decltype(&DeferWindowPos);
//	DeferWindowPos_t DeferWindowPos_Original;
//	HDWP WINAPI DeferWindowPos_Hook(HDWP hWinPosInfo,
//		HWND hWnd,
//		HWND hWndInsertAfter,
//		int x,
//		int y,
//		int cx,
//		int cy,
//		UINT uFlags) {
//		if (!g_hTrayInputIndicator) {
//			WCHAR szClassName[32];
//			GetClassName(hWnd, szClassName, ARRAYSIZE(szClassName));
//			if (_wcsicmp(szClassName, L"TrayInputIndicatorWClass") == 0) {
//				g_hTrayInputIndicator = hWnd;
//			}
//		}
//
//		if (g_hTrayInputIndicator && hWnd == g_hTrayInputIndicator && cy < 32) {
//			cy = 32;
//		}
//
//		return DeferWindowPos_Original(hWinPosInfo, hWnd, hWndInsertAfter, x, y, cx,
//			cy, uFlags);
//	}
//
//	using CreateWindowExW_t = decltype(&CreateWindowExW);
//	CreateWindowExW_t CreateWindowExW_Orig;
//	HWND WINAPI CreateWindowExW_Hook(DWORD dwExStyle, LPCWSTR lpClassName, LPCWSTR lpWindowName,
//		DWORD dwStyle, int X, int Y, int nWidth, int nHeight, HWND hWndParent, HMENU hMenu, HINSTANCE hInstance, LPVOID lpParam) {
//
//		HWND hWnd = CreateWindowExW_Orig(
//			dwExStyle, lpClassName, lpWindowName,
//			dwStyle, 10, Y, nWidth, nHeight, hWndParent,
//			hMenu, hInstance, lpParam
//		);
//
//		if ((((ULONG_PTR)lpClassName & ~(ULONG_PTR)0xffff) != 0))
//		{
//			VERBOSE(L":::::::::::::::::::::::lpClassName ---------%s----------------------------------------", lpClassName);
//		}
//		
//	/*	HWND hWnd = CreateWindowExW_Orig(dwExStyle, lpClassName, lpWindowName, dwStyle, X, Y, nWidth, nHeight, hWndParent, hMenu, hInstance, lpParam);
//		if ((((ULONG_PTR)lpClassName & ~(ULONG_PTR)0xffff) != 0) && !wcscmp(lpClassName, L"ControlCenterButton"))
//		{
//			BYTE* lpDisplayCCButton = (BYTE*)(GetWindowLongPtrW(hWnd, 0) + 120);
//			*lpDisplayCCButton = FALSE;
//		}*/
//
//
//
//		return hWnd;
//	}
//
//
//	MH_STATUS InitCustomizationHooks()
//	{
//		// Hook RoGetActivationFactory
//	/*	HMODULE winrtModule = GetModuleHandle(L"api-ms-win-core-winrt-l1-1-0.dll");
//		void* roAc = (void*)GetProcAddress(winrtModule, "RoGetActivationFactory");
//		MH_STATUS 	status = MH_CreateHook(
//			roAc,
//			(void*)RoGetActivationFactoryHook,
//			(void**)&origRoGetActivationFactory
//		);
//		status = MH_QueueEnableHook(roAc);
//		if (status != MH_OK) {
//			LOG(L"MH_QueueEnableHook failed for RoGetActivationFactory");
//			return status;
//		}
//
//		 	status = MH_CreateHook(
//			DeferWindowPos,
//			(void*)DeferWindowPos_Hook,
//			(void**)&DeferWindowPos_Original
//		);
//		status = MH_QueueEnableHook(DeferWindowPos);*/
//
//
//		MH_STATUS status = MH_CreateHook(
//			CreateWindowExW,
//			(void*)CreateWindowExW_Hook,
//			(void**)&CreateWindowExW_Orig
//		);
//		status = MH_QueueEnableHook(CreateWindowExW);
//
//	
//
//
//		return status;
//	}
//
//}
//
//bool CustomizationSession::Start(bool runningFromAPC, HANDLE sessionManagerProcess, HANDLE sessionMutex) noexcept
//{
//	VERBOSE(L"Running -------------------------------------------------");
//
//	auto instance = new (std::nothrow) CustomizationSession();
//	if (!instance) {
//		LOG(L"Allocation of CustomizationSession failed");
//		return false;
//	}
//
//	if (!instance->StartAllocated(runningFromAPC, sessionManagerProcess, sessionMutex)) {
//		delete instance;
//		return false;
//	}
//
//	// Instance will free itself.
//	return true;
//}
//
//bool CustomizationSession::StartAllocated(bool runningFromAPC, HANDLE sessionManagerProcess, HANDLE sessionMutex) noexcept
//{
//	// Create the session semaphore. This will block the library if another instance
//	// (from another session manager process) is already injected and its customization session is active.
//	WCHAR szSemaphoreName[sizeof("CustomizationSessionSemaphore-pid=1234567890")];
//	swprintf_s(szSemaphoreName, L"CustomizationSessionSemaphore-pid=%u", GetCurrentProcessId());
//
//	HRESULT hr = m_sessionSemaphore.create(1, 1, szSemaphoreName);
//	if (FAILED(hr)) {
//		LOG(L"Semaphore creation failed with error %08X", hr);
//		return false;
//	}
//
//	m_sessionSemaphoreLock = m_sessionSemaphore.acquire();
//
//	if (WaitForSingleObject(sessionManagerProcess, 0) != WAIT_TIMEOUT) {
//		VERBOSE(L"Session manager process is no longer running");
//		return false;
//	}
//
//	if (!InitSession(runningFromAPC, sessionManagerProcess)) {
//		return false;
//	}
//
//	if (runningFromAPC) {
//		// Create a new thread for us to allow the program's main thread to run.
//		try {
//			// Note: Before creating the thread, the CRT/STL bumps the
//			// reference count of the module, something a plain CreateThread
//			// doesn't do.
//			std::thread thread(&CustomizationSession::RunAndDeleteThis, this,
//				sessionManagerProcess, sessionMutex);
//			thread.detach();
//		}
//		catch (const std::exception& e) {
//			LOG(L"%S", e.what());
//			UninitSession();
//			return false;
//		}
//	}
//	else {
//		// No need to create a new thread, a dedicated thread was created for us
//		// before injection.
//		RunAndDeleteThis(sessionManagerProcess, sessionMutex);
//	}
//
//	return true;
//}
//
//bool CustomizationSession::InitSession(bool runningFromAPC, HANDLE sessionManagerProcess) noexcept
//{
//	MH_STATUS status = MH_Initialize();
//	if (status != MH_OK) {
//		LOG(L"MH_Initialize failed with %d", status);
//		return false;
//	}
//
//	if (runningFromAPC) {
//		// No other threads should be running, skip thread freeze.
//		MH_SetThreadFreezeMethod(MH_FREEZE_METHOD_NONE_UNSAFE);
//	}
//	else {
//		MH_SetThreadFreezeMethod(MH_FREEZE_METHOD_FAST_UNDOCUMENTED);
//	}
//
//	try {
//		m_newProcessInjector.emplace(sessionManagerProcess);
//	}
//	catch (const std::exception& e) {
//		LOG(L"InitSession failed: %S", e.what());
//		m_newProcessInjector.reset();
//		MH_Uninitialize();
//		return false;
//	}
//
//	status = InitCustomizationHooks();
//	if (status != MH_OK) {
//		LOG(L"InitCustomizationHooks failed with %d", status);
//	}
//
//	status = MH_ApplyQueued();
//	if (status != MH_OK) {
//		LOG(L"MH_ApplyQueued failed with %d", status);
//	}
//
//	if (runningFromAPC) {
//		MH_SetThreadFreezeMethod(MH_FREEZE_METHOD_FAST_UNDOCUMENTED);
//	}
//
//	return true;
//}
//
//void CustomizationSession::RunAndDeleteThis(HANDLE sessionManagerProcess, HANDLE sessionMutex) noexcept
//{
//	m_sessionManagerProcess.reset(sessionManagerProcess);
//
//	if (sessionMutex) {
//		m_sessionMutex.reset(sessionMutex);
//	}
//
//	// Prevent the system from displaying the critical-error-handler message box.
//	// A message box like this was appearing while trying to load a dll in a
//	// process with the ProcessSignaturePolicy mitigation, and it looked like this:
//	// https://stackoverflow.com/q/38367847
//	DWORD dwOldMode;
//	SetThreadErrorMode(SEM_FAILCRITICALERRORS, &dwOldMode);
//
//	Run();
//
//	SetThreadErrorMode(dwOldMode, nullptr);
//
//	delete this;
//}
//
//void CustomizationSession::Run() noexcept
//{
//	DWORD waitResult = WaitForSingleObject(m_sessionManagerProcess.get(), INFINITE);
//	if (waitResult != WAIT_OBJECT_0) {
//		LOG(L"WaitForSingleObject returned %u, last error %u", waitResult, GetLastError());
//	}
//
//	VERBOSE(L"Uninitializing and freeing library");
//
//	UninitSession();
//}
//
//void CustomizationSession::UninitSession() noexcept
//{
//	MH_STATUS status = MH_Uninitialize();
//	if (status != MH_OK) {
//		LOG(L"MH_Uninitialize failed with status %d", status);
//	}
//
//	m_newProcessInjector.reset();
//}
//