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

// �ú������ڴ��� ITaskbarList �ӿڵ�ʵ������������ָ��
__declspec(dllexport) HRESULT CreateTaskbarList(ITaskbarList** ppTaskbarList)
{
    if (ppTaskbarList == NULL)
        return E_POINTER;

    // ��ʼ�� COM ��
    HRESULT hr = CoInitialize(NULL);
    if (FAILED(hr))
        return hr;

    // ���� ITaskbarList ʵ��
    hr = CoCreateInstance(&CLSID_TaskbarList, NULL, CLSCTX_INPROC_SERVER, &IID_ITaskbarList, (void**)ppTaskbarList);
    if (FAILED(hr)) {
        CoUninitialize();
    }
    return hr;
}

// �ú��������ͷ� ITaskbarList �ӿڲ�����ʼ�� COM ��
__declspec(dllexport) void ReleaseTaskbarList(ITaskbarList* pTaskbarList)
{
    if (pTaskbarList) {
        pTaskbarList->lpVtbl->Release(pTaskbarList);
    }
    CoUninitialize();
}
