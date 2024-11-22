// TaskbarListDLL.c
#include <Windows.h>
#include <shobjidl.h>  // ITaskbarList


// Function to hide window from taskbar and Alt-Tab menu
__declspec(dllexport) BOOL HideFromTaskbarAndAltTab(HWND hwnd) {
    if (!hwnd) {
        return FALSE;
    }

    // Initialize COM library
    HRESULT hr = CoInitialize(NULL);
    if (FAILED(hr)) {
        return FALSE;
    }

    // Use ITaskbarList to remove the window from the taskbar
    ITaskbarList* pTaskList = NULL;
    hr = CoCreateInstance(&CLSID_TaskbarList, NULL, CLSCTX_INPROC_SERVER, &IID_ITaskbarList, (void**)&pTaskList);
     hr = pTaskList->HrInit();
    if (SUCCEEDED(hr) && pTaskList) {
        pTaskList->lpVtbl->DeleteTab(pTaskList, hwnd);
        pTaskList->lpVtbl->Release(pTaskList);
    }

    // Modify window styles to hide from Alt-Tab menu
    LONG_PTR exStyle = GetWindowLongPtr(hwnd, GWL_EXSTYLE);
    exStyle |= WS_EX_TOOLWINDOW;        // Add TOOLWINDOW style to hide from Alt-Tab
    exStyle &= ~WS_EX_APPWINDOW;        // Remove APPWINDOW style to prevent taskbar presence
    SetWindowLongPtr(hwnd, GWL_EXSTYLE, exStyle);

    // Refresh the window style by hiding and showing the window
    ShowWindow(hwnd, SW_HIDE);
    ShowWindow(hwnd, SW_SHOW);

    // Uninitialize COM library
    CoUninitialize();

    return TRUE;
}

// 该函数用于创建 ITaskbarList 接口的实例并返回它的指针
__declspec(dllexport) HRESULT CreateTaskbarList(ITaskbarList** ppTaskbarList)
{
    if (ppTaskbarList == NULL)
        return E_POINTER;

    // 初始化 COM 库
    HRESULT hr = CoInitialize(NULL);
    if (FAILED(hr))
        return hr;

    // 创建 ITaskbarList 实例
    hr = CoCreateInstance(&CLSID_TaskbarList, NULL, CLSCTX_INPROC_SERVER, &IID_ITaskbarList, (void**)ppTaskbarList);
    if (FAILED(hr)) {
        CoUninitialize();
    }
    return hr;
}

// 该函数用于释放 ITaskbarList 接口并反初始化 COM 库
__declspec(dllexport) void ReleaseTaskbarList(ITaskbarList* pTaskbarList)
{
    if (pTaskbarList) {
        pTaskbarList->lpVtbl->Release(pTaskbarList);
    }
    CoUninitialize();
}
